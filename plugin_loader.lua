--- A simple plugin loading and runner system.

local exp = require "cc.expect"
local expect = exp.expect
local field = exp.field

local logging = require "logging"
local plugins_folder = require "file_helper":instanced("plugins") --[[@as file_helper]]
local thready = require "thready"

local plugin_context = logging.create_context("Plugin")

---@class Plugin
---@field name string The name of the plugin.
---@field description string A description of the plugin.
---@field author string The author of the plugin.
---@field version string The version of the plugin. Might I recommend semver?
---@field init fun()? A function to run when the plugin is first loaded. Threads spawned here will not start until the main loop is started.
---@field run fun()? If your plugin requires a main loop, implement it here and it will be run alongside everything else.
---@field teardown fun()? A function to run when the plugin is unloaded. Use this to clean up or save state.

---@class plugin_thready : thready
---@field spawn fun(func:fun(), ...:any):integer Spawn a new thread for the plugin.
---@field listen fun(event_name:string, func:fun(event:string, ...:any)):integer Spawn a listener for the plugin.
---@field interval fun(interval:number, func:fun(...:any)):integer Spawn an interval for the plugin.

---@class plugin_context_loader : plugin_loader
---@field request fun(name:string):any Request data from the plugin loader.
---@field request_wait fun(name:string, timeout:number?):any Request data from the plugin loader, waiting for it to be available for a maximum of `timeout` seconds.

---@class plugin_loader
---@field plugins string[] A table of plugin names.
---@field loaded table<string, Plugin> A table of loaded plugins.
---@field unloaded table<string, Plugin> A table of unloaded plugins.
---@field running boolean Whether the plugin system is currently running.
local plugin_loader = {
  running = false,
  plugins = {},
  loaded = {},
  unloaded = {},
}

---@type table<string, any>
local exposed_data = {}

--- Generate a custom thready instance for a plugin.
---@param set_name string The name of the set to create.
---@return plugin_thready
local function make_thready(set_name)
  local thready_instance = setmetatable(
    {
      spawn = function(func, ...)
        plugin_context.debug("Spawning thread for", set_name)
        return thready.spawn(set_name, func, ...)
      end,
      listen = function(event_name, func)
        plugin_context.debug("Spawning listener for", event_name, "in", set_name)
        return thready.listen(set_name, event_name, func)
      end,
      interval = function(interval, func, ...)
        local args = table.pack(...)
        plugin_context.debug("Spawning interval for", interval, "in", set_name)
        return thready.spawn(set_name, function()
          while true do
            func(table.unpack(args, 1, args.n))
            os.sleep(interval)
          end
        end)
      end
    },
    {__index = thready}
  )
  ---@cast thready_instance plugin_thready

  return thready_instance
end

--- Register a plugin with the plugin loader.
---@param plugin Plugin The plugin to register.
function plugin_loader.register(plugin)
  expect(1, plugin, "table")
  field(plugin, "name", "string")
  field(plugin, "description", "string")
  field(plugin, "author", "string")
  field(plugin, "version", "string")
  field(plugin, "init", "function", "nil")
  field(plugin, "run", "function", "nil")
  field(plugin, "teardown", "function", "nil")
  --

  if plugin_loader.unloaded[plugin.name] then
    error(("Plugin %s is already registered (unloaded)."):format(plugin.name), 2)
  end
  if plugin_loader.loaded[plugin.name] then
    error(("Plugin %s is already registered (loaded)."):format(plugin.name), 2)
  end

  plugin_loader.unloaded[plugin.name] = plugin
  plugin_context.debug("Registered plugin", plugin.name)
end

--- Deregister a plugin from the plugin loader.
---@param name string The name of the plugin to unregister.
function plugin_loader.deregister(name)
  expect(1, name, "string")
  --

  if plugin_loader.unloaded[name] then
    plugin_loader.unloaded[name] = nil
    plugin_context.debug("Deregistered plugin", name)
    return
  end

  plugin_loader.unload(name)
  plugin_loader.unloaded[name] = nil
  plugin_loader.loaded[name] = nil
  plugin_context.debug("Unloaded and deregistered plugin", name)
end

--- Load a plugin. This is mostly handled internally, but you can use it to load a plugin that was previously unloaded.
---@param name string The name of the plugin to load.
function plugin_loader.load(name)
  expect(1, name, "string")
  --

  if plugin_loader.loaded[name] then
    error(("Plugin %s is already loaded."):format(name), 2)
  end

  local plugin = plugin_loader.unloaded[name]
  if not plugin then
    error(("Plugin %s is not registered."):format(name), 2)
  end

  if plugin.init then
    plugin.init()
  end

  plugin_loader.loaded[name] = plugin
  plugin_loader.unloaded[name] = nil
end

--- Unload a plugin.
---@param name string The name of the plugin to unload.
function plugin_loader.unload(name)
  expect(1, name, "string")
  --

  local plugin = plugin_loader.loaded[name]
  if not plugin then
    error(("Plugin %s is not loaded."):format(name), 2)
  end

  if plugin.teardown then
    plugin.teardown()
  end

  ---@fixme This needs to also clear any currently running threads spawned by the plugin.

  plugin_loader.unloaded[name] = plugin
  plugin_loader.loaded[name] = nil
end

--- Force-kill a plugin. This will unload it and remove it from the registry.
---@param name string The name of the plugin to kill.
function plugin_loader.kill(name)
  expect(1, name, "string")
  --

  ---@fixme This needs to also clear any currently running threads spawned by the plugin.
  ---@fixme This should use a manual kill system instead of using deregister.

  plugin_loader.deregister(name)
end

--- Run the plugin system. This loads all plugins and runs their main loops. If something goes wrong, or the loader was ordered to stop, it will safely unload all plugins.
--- ## Usage
--- ```lua
--- plugin_loader.run(
---   your_main_loop,
---   other_main_loop,
---   ...
--- )
---@param ... function The main loop(s) of the program.
function plugin_loader.run(...)
  if plugin_loader.running then
    error("Plugin system is already running.", 2)
  end

  plugin_loader.running = true

  -- Start the main loop.
  plugin_context.debug("Starting main loop.")
  thready.parallelAll(
    function()
      sleep(0.25) -- ensure that the main loop is started first

      plugin_context.debug("Begin load.")
      local load_names = {}
      for name in pairs(plugin_loader.unloaded) do
        load_names[#load_names + 1] = name
      end

      -- And then we can actually load them.
      plugin_context.debug("Generating loaders.")
      local loaders = {}
      for _, name in ipairs(load_names) do
        table.insert(loaders, function()
          local ok, err = pcall(plugin_loader.load, name)

          if ok then
            -- Plugin load OK
            plugin_context.debug("Loaded plugin", name)
          else
            -- Plugin load failed
            plugin_context.error("Failed to load plugin", name, ":", err)
          end
        end)
      end

      plugin_context.info("Loading", #loaders, "plugin(s) in parallel.")
      parallel.waitForAll(table.unpack(loaders))

      -- Start all of the main loops.
      local main_loop_ids = {}
      plugin_context.debug("Starting plugin run loops.")
      for name, plugin in pairs(plugin_loader.loaded) do
        if plugin.run then
          plugin_context.debug("Starting main loop for", name)
          table.insert(main_loop_ids, thready.spawn(name, plugin.run))
        end
      end

      -- Wait for the stop event, or for the main loop to stop.
      plugin_context.debug("Waiting for stop event.")
      while plugin_loader.running do
        os.pullEvent()
      end
      plugin_context.debug("Stop event received.")

      -- Stop all main loops.
      plugin_context.debug("Stopping all main loops.")
      for _, id in ipairs(main_loop_ids) do
        thready.kill(id)
      end

      -- Unload all plugins.
      plugin_context.debug("Unloading all plugins.")
      for name in pairs(plugin_loader.loaded) do
        local ok, err = pcall(plugin_loader.unload, name)

        if ok then
          -- Plugin unload OK
          plugin_loader.unloaded[name] = plugin_loader.loaded[name]
          plugin_loader.loaded[name] = nil
          plugin_context.debug("Unloaded plugin", name)
        else
          -- Plugin unload failed
          plugin_context.error("Failed to unload plugin", name, ":", err)

          -- Kill the plugin.
          plugin_loader.kill(name)
          plugin_context.debug("Killed plugin", name)

          -- Remove it from the loaded table, and do not keep it in unloaded either.
          plugin_loader.loaded[name] = nil
          plugin_loader.unloaded[name] = nil
        end
      end

      -- Shut down thready.
      plugin_context.debug("Shutting down thready.")
      thready.running = false
      os.queueEvent("goodbye")
    end,
    ...
  )
  plugin_context.debug("Main loop stopped.")
end

--- Stop the plugin system. This will safely unload all plugins and stop the main loop.
function plugin_loader.stop()
  if not plugin_loader.running then
    error("Plugin system is not running.", 2)
  end

  plugin_loader.running = false
  os.queueEvent("stop-plugins")
end

--- Searches the `plugins` directory for plugins and registers them.
function plugin_loader.register_all()
  local files = plugins_folder:is_directory() and plugins_folder:list() or {}

  local failures = 0
  local successes = 0

  for _, file in ipairs(files) do
    if not plugins_folder:is_directory(file) then
      plugin_context.debug("Registering plugin file", file)
      local data = plugins_folder:get_all(file)

      if data then
        local env = {}
        env.loader = setmetatable({
          request = function() error("Cannot request data from the loader outside init/run/teardown methods.", 2) end,
        }, {__index = plugin_loader})

        -- Inject fake thready and logger objects.
        env.thready = setmetatable({}, {
          __index = function()
            error("Thready is not yet initialized, it will be available in your init/run/teardown methods.", 2)
          end
        })
        env.logger = setmetatable({}, {
          __index = function()
            error("Logger is not yet initialized, it will be available in your init/run/teardown methods.", 2)
          end
        })

        setmetatable(env, {__index = _ENV})

        -- Compile the file.
        local func, err = load(
          data,
          "@" .. fs.combine(plugins_folder.working_directory, file),
          "t",
          env
        )

        -- Check compilation errors.
        if func then
          -- Run the file.
          local _ok, plugin_data = pcall(func)

          -- Check if the file errored.
          if _ok then
            -- Check if the file returned anything.
            if type(plugin_data) == "table" then
              -- Ensure the plugin is enabled.
              if not plugin_data.disabled then
                -- Attempt to register the plugin.
                local __ok, err = pcall(plugin_loader.register, plugin_data)

                if __ok then
                  successes = successes + 1

                  -- Good! Store the plugin in the unloaded table.
                  plugin_loader.unloaded[plugin_data.name] = plugin_data

                  -- Now we can properly inject thready into its environment.
                  env.thready = make_thready(plugin_data.name)
                  -- And the same for the logger.
                  env.logger = logging.create_context(plugin_data.name)
                  -- And again for the plugin loader request system.
                  env.loader = setmetatable({
                    request = function(name)
                      if not exposed_data[name] then
                        error("No data exposed by name " .. name, 2)
                      end

                      plugin_context.info(plugin_data.name, "requested data key", name)
                      return exposed_data[name]
                    end,
                    request_wait = function(name, timeout)
                      plugin_context.info(plugin_data.name, "waiting for data key", name)
                      local timer = os.startTimer(timeout or 5)
                      while not exposed_data[name] do
                        local event, param = os.pullEvent()

                        if event == "timer" and param == timer then
                          if timeout then
                            plugin_context.error(plugin_data.name, ": Timed out waiting for data field", name)
                            return nil
                          end
                          plugin_context.warn(plugin_data.name, ": Infinite yield possible waiting for data field", name)
                        end
                      end
                      plugin_context.info(plugin_data.name, "received data key", name)

                      return exposed_data[name]
                    end,
                  }, {__index = plugin_loader})
                else
                  plugin_context.error("Failed to register plugin", file, ":", err)
                  failures = failures + 1
                end
              else
                plugin_context.info("Skipping disabled plugin", plugin_data.name)
              end
            else
              plugin_context.error("Failed to register plugin", file, ":", "Nothing returned by file.")
              failures = failures + 1
            end
          else
            plugin_context.error("Failed to register plugin", file, ":", plugin_data)
            failures = failures + 1
          end
        else
          plugin_context.error("Failed to register plugin", file, ":", err)
          failures = failures + 1
        end
      else
        plugin_context.warn("Failed to register plugin", file, ":", "No data returned.")
        failures = failures + 1
      end
    else
      plugin_context.debug("Skipping directory", file)
    end
  end

  plugin_context.info("Registered", successes, "plugin(s) with", failures, "failure(s).")
end

--- Expose data to plugins, by name. Plugins must request this data by name (and requests will be logged).
---@param name string The name of the data to expose.
---@param data any The data to expose.
function plugin_loader.expose(name, data)
  expect(1, name, "string")
  --

  if exposed_data[name] then
    plugin_context.warn("Overwriting exposed data", name)
  end

  exposed_data[name] = data
  plugin_context.debug("Exposed data", name)

  os.queueEvent("plugin-data-expose", name, data)
end

return plugin_loader
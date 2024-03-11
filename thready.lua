--- "Thread" (coroutine) handling system that allows different systems to run their main loops in separate threads.

local logging = require "logging"
local thread_context = logging.create_context("Thready")

---@class thread_data
---@field thread thread The coroutine thread.
---@field id integer The ID of the thread.
---@field set_name string The name of the set that owns the thread.
---@field event_filter string|nil The event filter for the thread.
---@field status thread_status The status of the thread.
---@field alive boolean Whether the thread is alive or not.

---@class listener_data
---@field event string The event to listen for.
---@field callback fun(event:string, ...:any) The callback to run when the event is received.
---@field id integer The ID of the listener.
---@field set_name string The name of the set that owns the listener.

---@alias thread_status "running"|"suspended"|"dead"|"new"

---@class thready
---@field coroutines table<string, thread_data[]> A table of coroutines for each set.
---@field listeners listener_data[] A table of listeners for each event.
---@field stop_on_error boolean Whether to stop the entire system on error.
---@field kill_all_owned_on_error boolean Whether to kill all threads for a set on error.
---@field running boolean Whether the system is currently running.
local thready = {
  coroutines = {},
  listeners = {},
  stop_on_error = false,
  kill_all_owned_on_error = true,
  running = false
}

local used_ids = {}
--- Generate a unique ID for a thread.
local function gen_unique_id()
  local id = math.random(1, 2^31 - 1)

  while used_ids[id] do
    id = math.random(1, 2^31 - 1)
  end

  used_ids[id] = true
  return id
end

--- Check if a coroutine has errored and handle it.
--- @param coro_data thread_data The coroutine data to check.
---@return boolean kill_all Whether to kill all threads for the set.
local function check_errored(coro_data)
  if not coro_data.alive then
    if thready.stop_on_error then
      thready.running = false
      error(("%s thread %d errored: %s"):format(coro_data.set_name, coro_data.id, coro_data.event_filter), 0)
    end

    if thready.kill_all_owned_on_error then
      thread_context.error("%s thread %d errored: %s", coro_data.set_name, coro_data.id, coro_data.event_filter)
      return true
    else
      thread_context.warn("Ignoring error in %s thread %d: %s", coro_data.set_name, coro_data.id, coro_data.event_filter)
    end
  end

  return false
end

local function remove_thread(set_name, id)
  local coros = thready.coroutines[set_name]
  if not coros then return end

  for i = 1, #coros do
    if coros[i].id == id then
      table.remove(coros, i)
      used_ids[id] = nil
      break
    end
  end
end

--- Run a single step of all coroutines in the system given an event.
---@param event_name string The name of the event to run.
---@param ... any The arguments of the event.
local function run(event_name, ...)
  local to_remove = {}
  local to_kill = {}

  for set_name, coros in pairs(thready.coroutines) do
    for i = 1, #coros do
      local coro = coros[i]

      if coro.status == "suspended" then
        -- Resume the coroutine, but ONLY if:
        -- 1. The event filter is nil (no filter)
        -- 2. The event filter is not nil, but the event matches the filter.
        -- 3. The event is a `terminate` event.
        if not coro.event_filter or coro.event_filter == event_name or event_name == "terminate" then
          coro.alive, coro.event_filter = coroutine.resume(coro.thread, event_name, ...)
        end

        -- Check if errored
        if check_errored(coro) then
          to_kill[set_name] = true
          break -- stop executing this set's coroutines
        end

        -- If the coroutine is dead, mark it for removal.
        if coro.status == "dead" then
          to_remove[coro.id] = set_name
        end
      elseif coro.status == "new" then
        -- Initialize by running once.
        coro.alive, coro.event_filter = coroutine.resume(coro.thread)

        -- Check if errored
        if check_errored(coro) then
          to_kill[set_name] = true
          break -- stop executing this set's coroutines
        end

        -- If the coroutine is dead, mark it for removal.
        if coro.status == "dead" then
          to_remove[coro.id] = set_name
        end
      elseif coro.status == "dead" then
        -- Remove dead coroutines.
        to_remove[coro.id] = set_name

        -- Check if errored
        if check_errored(coro) then
          to_kill[set_name] = true
          break -- stop executing this set's coroutines
        end
      end
    end
  end

  -- Remove dead coroutines.
  for id, set_name in pairs(to_remove) do
    remove_thread(set_name, id)
  end

  -- Remove all threads for sets that errored.
  for set_name in pairs(to_kill) do
    thready.kill_all(set_name)
  end
end

--- Run the main loop of the thread system. Recommend using this with `parallel`.
---@see thready.parallel
function thready.main_loop()
  while thready.running do
    local event_data = table.pack(os.pullEvent())

    -- spawn listeners
    for _, listener in ipairs(thready.listeners) do
      if listener.event == event_data[1] then
        thready.spawn(listener.set_name, listener.callback)
      end
    end

    run(table.unpack(event_data, 1, event_data.n))
  end
end

--- Start the thread system in parallel with other functions. This is a shorthand to `parallel.waitForAny(thready.main_loop, ...)`.
--- ## Usage
--- ```lua
--- thready.parallel(
---   your_main_loop,
---   other_main_loop,
---   ...
--- )
--- ```
---@param ... function The main loop(s) of the program.
function thready.parallel(...)
  if thready.running then
    error("Thread system is already running.", 2)
  end

  local args = {...}

  for i, fun in ipairs(args) do
    expect(i, fun, "function")
  end

  parallel.waitForAny(thready.main_loop, ...)
end

--- Spawn a new thread for a given set.
---@param set_name string The name of the set to spawn the thread in.
---@param thread_fun fun() The function to run in the thread.
---@return integer id The ID of the spawned thread.
function thready.spawn(set_name, thread_fun)
  expect(1, set_name, "string")
  expect(2, thread_fun, "function")
  --

  local id = gen_unique_id()
  local thread = coroutine.create(thread_fun)

  ---@type thread_data
  local coro_data = {
    thread = thread,
    id = id,
    set_name = set_name,
    event_filter = nil,
    status = "new",
    alive = true
  }

  if not thready.coroutines[set_name] then
    thready.coroutines[set_name] = {}
  end

  table.insert(thready.coroutines[set_name], coro_data)
  return id
end

--- Add a listener for a given event.
---@param event string The event to listen for.
---@param callback fun(event:string, ...:any) The callback to run when the event is received.
function thready.listen(set_name, event, callback)
  expect(1, event, "string")
  expect(2, callback, "function")
  --

  table.insert(thready.listeners, {
    event = event,
    set_name = set_name,
    callback = callback,
    id = gen_unique_id()
  })
end

--- Remove a listener by its ID. This will not stop any currently running listeners.
---@param id integer The ID of the listener to remove.
function thready.remove_listener(id)
  expect(1, id, "number")
  --

  for i = 1, #thready.listeners do
    if thready.listeners[i].id == id then
      table.remove(thready.listeners, i)
      return
    end
  end
end

--- Kill a thread.
---@param id integer The ID of the thread to kill.
function thready.kill(id)
  expect(1, id, "number")
  --

  for set_name, coros in pairs(thready.coroutines) do
    for i = 1, #coros do
      if coros[i].id == id then
        remove_thread(set_name, id)
        return
      end
    end
  end
end

--- Kill all threads for a given set.
---@param set_name string The name of the set to kill all threads for.
function thready.kill_all(set_name)
  expect(1, set_name, "string")
  --

  local coros = thready.coroutines[set_name]

  -- If no coroutines exist, return.
  if not coros then
    return
  end

  -- Clear the used IDs
  for i = 1, #coros do
    used_ids[coros[i].id] = nil
  end

  -- Remove the coroutines
  thready.coroutines[set_name] = nil
end

--- Clear the entire thread system.
function thready.clear()
  thready.coroutines = {}
  used_ids = {}
end

return thready
--- Simple ComputerCraft Thread Implementation

local expect = require("cc.expect").expect
local log = require("minilogger").new("thread")


---@class _thread
---@field id integer The ID of the thread.
---@field status "running"|"suspended"|"dead"|"normal" The status of the thread.
---@field yielded string? The last event the thread has requested.
---@field coroutine thread The coroutine of the thread. 
---@field elevate_errors boolean Whether to elevate errors to the parent thread.
---@field after_f function? The function to run after the thread has finished.
---@field after_args table The arguments to pass to the function after the thread has finished.
---@field on_error_f function? The function to run after the thread has errored.
---@field on_error_args table The arguments to pass to the function after the thread has errored.
---@field paused boolean Whether the thread is paused.
---@field creator table Short information about the creator of the thread.
local _thread = {
  _THREAD_BASE = true
}
local _thread_mt = { __index = _thread }

---@type table<integer, _thread> ID->Thread
local threads = {}

local last_id = 0

local running = false
local ticking = false

--#region Internal Functions

local function check_base(self)
  if rawget(self, "_THREAD_BASE") then
    error("Use ':' to call this method", 3)
  end
end



local function new_id()
  last_id = last_id + 1
  return last_id
end


--- Tick all threads. This function handles events properly.
--- This also culls dead threads after done ticking.
---@private
---@param event string The event to tick with.
---@param ... any The event arguments.
function _thread._tick(event, ...)
  if ticking then
    error("Cannot tick while already ticking", 2)
  end
  ticking = true

  ---@type _thread[]
  local threads_no_updates = {}
  local n_threads = 0
  for _, thread in pairs(threads) do
    n_threads = n_threads + 1
    threads_no_updates[n_threads] = thread
  end

  for i = 1, n_threads do
    local thread = threads_no_updates[i]

    -- Base check: Is the thread still alive?
    if thread.status == "suspended" and not thread.paused then
      -- Next check:
      -- 1. If last yielded is nil, pass event.
      -- 2. If last yielded is not nil, only pass on the following 2 conditions:
      --    a. The event is the same as the last yielded.
      --    b. The event is "terminate".
      if thread.yielded == nil or thread.yielded == event or event == "terminate" then
        thread:resume(event, ...)
      end
    end
  end

  _thread._cull()
  ticking = false
end



--- Cull all dead threads.
---@private
function _thread._cull()
  local to_remove = {}

  for id, thread in pairs(threads) do
    if thread.status == "dead" then
      table.insert(to_remove, id)

      if thread.after_f then
        log.debug("Queueing after function for thread", id)
        _thread.new(thread.after_f, table.unpack(thread.after_args, 1, thread.after_args.n))
      end
    end
  end

  if to_remove[1] then
    log.debugf("Culling thread%s %s", to_remove[2] and "s" or "", table.concat(to_remove, ","))
    for _, id in ipairs(to_remove) do
      threads[id] = nil
    end
  end
end



--- Create a new thread object.
---@param fn function The function to run in the thread.
---@param ... any The arguments to pass to the function.
---@return _thread thread The new thread object, without initializing it.
function _thread._create(fn, ...)
  expect(1, fn, "function")
  if type(fn) == "table" then
    error("Use the thread base class to create a new thread", 2)
  end

  return {
    id = new_id(),
    status = "suspended",
    yielded = nil,
    coroutine = coroutine.create(fn),
    elevate_errors = true,
    after_args = {},
    on_error_args = {},
    paused = false
  }
end

--#endregion

--#region Public Functions

--- Create a new thread.
---@param fn function The function to run in the thread.
---@param ... any The arguments to pass to the function.
---@return _thread thread The new thread.
function _thread.new(fn, ...)
  expect(1, fn, "function")
  if type(fn) == "table" then
    error("Use the thread base class to create a new thread", 2)
  end

  local creator = debug.getinfo(2, "Sl")

  local thread = _thread._create(fn, ...)
  thread.creator = creator
  threads[thread.id] = thread
  log.debugf("Created new thread %d from %s:%d", thread.id, creator.short_src, creator.currentline)

  -- Initialize the thread
  ---@type boolean
  local alive;
  alive, thread.yielded = coroutine.resume(thread.coroutine, ...)
  thread.status = coroutine.status(thread.coroutine)

  if not alive then
    error(("Thread init failed: %s"):format(thread.yielded), 2)
  end

  if thread.status == "dead" then
    log.debug("Thread is already dead")
  end
  return setmetatable(thread, _thread_mt)
end



--- Creates a new thread, but immediately disables the error elevation.
---@param fn function The function to run in the thread.
---@param ... any The arguments to pass to the function.
---@return _thread thread The new thread.
function _thread.silent(fn, ...)
  expect(1, fn, "function")
  if type(fn) == "table" then
    error("Use the thread base class to create a new thread", 2)
  end

  local creator = debug.getinfo(2, "Sl")
  local thread = _thread._create(fn, ...)
  thread.elevate_errors = false
  thread.creator = creator
  threads[thread.id] = thread
  log.debugf("Created new thread %d from %s:%d", thread.id, creator.short_src, creator.currentline)

  -- Initialize the thread
  ---@type boolean
  local alive;
  alive, thread.yielded = coroutine.resume(thread.coroutine, ...)
  thread.status = coroutine.status(thread.coroutine)

  if not alive then
    -- No elevate errors, so we just log it here instead.
    log.error(("Thread init failed: %s"):format(thread.yielded), 2)
  end

  log.debug("Created new thread", thread.id)
  if thread.status == "dead" then
    log.debug("Thread is already dead")
  end

  return thread
end



--- Run the thread manager. This function must be called in order to run threads in the background.
---@param ... function Equivalent to creating new threads with the given functions.
function _thread.run(...)
  if running then
    error("Cannot run while already running", 2)
  end
  running = true
  log.debug("Running thread manager")

  local new_threads = table.pack(...)
  for i = 1, new_threads.n do
    expect(i, new_threads[i], "function")
    _thread.new(new_threads[i])
  end

  while running do
    local event_data = table.pack(os.pullEvent())

    _thread._tick(table.unpack(event_data, 1, event_data.n))
  end

  log.debug("Thread manager stopped")
end



--- Stop the thread manager. Completes the current tick and then stops the thread manager.
function _thread.stop()
  running = false
end



--- Kill the thread.
---@param self _thread The thread to kill.
function _thread:kill()
  expect(1, self, "table")
  check_base(self)

  self.status = "dead"
end



--- Resume the thread with the given event.
--- THIS DOES NOT DO ANY EVENT CHECKING, WILL ALWAYS RESUME THE THREAD WITH THE GIVEN EVENT.
---@param self _thread The thread to resume.
---@param event string The event to resume the thread with.
---@param ... any The event arguments.
---@return boolean ok False if the thread errored.
---@return string? err The error message if the thread errored.
function _thread:resume(event, ...)
  expect(1, self, "table")
  expect(2, event, "string")
  check_base(self)

  if self.status == "dead" then
    return false, "Thread is dead"
  end
  if self.status == "running" then
    error("WHAT THE FUCK IS GOING ON", 2)
  end

  local alive, yielded = coroutine.resume(self.coroutine, event, ...)
  self.yielded = yielded
  self.status = coroutine.status(self.coroutine)

  if not alive then
    if self.elevate_errors then
      local traceback = debug.traceback(self.coroutine, ("Thread id %d: %s\nthread created: %s:%d"):format(self.id, yielded, self.creator.short_src, self.creator.currentline))
      error(traceback, 0)
    end

    if self.on_error_f then
      log.debugf("Thread id %d running on-error", self.id)
      _thread.new(self.on_error_f, yielded, table.unpack(self.on_error_args, 1, self.on_error_args.n))
    end

    return false, yielded
  end

  return true
end



--- Pause or unpause the thread.
---
--- **Note: Pausing the thread only pauses it in the main loop. You can still resume it manually with `thread:resume(...)`.**
---@param self _thread The thread to pause/unpause.
---@param pause boolean Whether to pause or unpause the thread.
function _thread:pause(pause)
  expect(1, self, "table")
  expect(2, pause, "boolean")
  check_base(self)

  self.paused = pause
end



--- Set the function to run after the thread has finished.
---@param self _thread The thread to set the function for.
---@param f function The function to run after the thread has finished.
---@param ... any The arguments to pass to the function.
---@return self self The thread itself, for chaining.
function _thread:after(f, ...)
  expect(1, self, "table")
  expect(2, f, "function")
  check_base(self)

  self.after_f = f
  self.after_args = table.pack(...)

  return self
end



--- Runs this method in the background upon an error. Disables error elevation.
---@param self _thread The thread to set the function for.
---@param f function The function to run after the thread has errored.
---@param ... any The arguments to pass to the function. These are passed *after* the error string.
---@return self self The thread itself, for chaining.
function _thread:on_error(f, ...)
  expect(1, self, "table")
  expect(2, f, "function")
  check_base(self)

  self.elevate_errors = false
  self.on_error_f = f
  self.on_error_args = table.pack(...)

  return self
end

--#endregion

return _thread
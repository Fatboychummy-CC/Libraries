--- Locks to help you lock out resources, and await unlocking.

---@generic T
---@class FIFOQueue<T>: {queue: T[]}
local function FIFOQueue()
  local queue = {queue = {}}

  function queue.push(value)
    table.insert(queue.queue, value)
  end

  function queue.push_first(value)
    table.insert(queue.queue, 1, value)
  end

  function queue.pop()
    return table.remove(queue.queue, 1)
  end

  function queue.is_empty()
    return #queue.queue == 0
  end

  return queue
end

---@class Lock
---@field waiting FIFOQueue<string> The queue of tasks waiting for the lock to be unlocked. This is a queue of events to queue to resume the waiting task.
---@field locked boolean Whether the lock is currently locked.
local lock = {}
lock.__index = lock



local last_id = 0
--- Generates an ID for a lock.
---@return string
local function generate_id()
  last_id = last_id + 1
  return "lock_" .. tostring(last_id)
end


--- Create a new lock.
---@return Lock
function lock.new()
  return setmetatable({
    waiting = FIFOQueue(),
    locked = false,
  }, lock)
end



--- Lock the lock. If the lock is already locked, fails.
---@return boolean locked Whether the lock was successfully locked.
function lock:lock()
  if self.locked then
    return false
  end

  self.locked = true
  return true
end



--- Lock the lock. If the lock is already locked, waits in the queue until it is unlocked.
--- This function should be preferred over polling `lock:lock()` until it returns `true`.
function lock:await_lock()
  if self.locked then
    local event = generate_id()
    self.waiting.push(event)
    os.pullEvent(event)
  end

  self.locked = true
end



--- Lock the lock. Inserts the new ID at the front of the queue.
--- This method is rude to other tasks, but useful for things that require priority.
function lock:await_lock_priority()
  if self.locked then
    local event = generate_id()
    self.waiting.push_first(event)
    os.pullEvent(event)
  end

  self.locked = true
end



--- Unlock the lock.
function lock:unlock()
  self.locked = false

  if not self.waiting.is_empty() then
    local event = self.waiting.pop()
    os.queueEvent(event)
  end
end



return lock
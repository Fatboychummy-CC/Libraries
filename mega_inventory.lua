--- Mega inventory: Combines multiple inventories into a single one, for ease of use.

local expect = require "cc.expect".expect


local new_parallelism_handler = require "parallelism_handler"


---@class InventoryReference
---@field inventory Inventory The inventory.
---@field name string The name of the inventory.

---@class MegaInventory
---@field inventories InventoryReference[] The inventories to combine.
---@field last_list table<integer, item> The last list of items in the inventory. Slots above the first inventory's size are the second inventory, and so on...
local mega_inventory = {}

local mega_inventory_mt = {}
mega_inventory_mt.__index = mega_inventory



--- Sum up values in the input table.
---@param values number[] The values to sum up.
---@return number sum The sum of the values.
local function sum(values)
  local sum = 0
  for _, value in ipairs(values) do
    sum = sum + value
  end
  return sum
end



--- Create a new mega inventory.
---@param ... Inventory The inventories to combine.
---@return MegaInventory mega_inventory The new mega inventory.
function mega_inventory.new(...)
  local inventories = {...}
  local inventory_references = {}
  for i, inventory in ipairs(inventories) do
    expect(i, inventory, "table")

    table.insert(inventory_references, {
      inventory = inventory,
      name = peripheral.getName(inventory),
    })
  end

  return setmetatable({
    inventories = inventory_references,
  }, mega_inventory_mt)
end



--- Get sizes of all inventories, in the order of `self.inventories`.
---@return integer[] sizes The sizes of the inventories.
---@overload fun(ph: ParallelismHandler): nil Internal use only.
function mega_inventory:sizes(ph)
  local no_execute = ph ~= nil
  ph = ph or new_parallelism_handler()

  for _, inventory_reference in ipairs(self.inventories) do
    ph:add_task(inventory_reference.inventory.size)
  end

  if no_execute then
    return
  end

  return ph:execute()
end



--- Get the inventory size.
---@return integer size The size of the inventory.
function mega_inventory:size()
  return sum(self:sizes())
end



--- List all items in the inventory.
---@return table<integer, item> items The items in the inventory.
function mega_inventory:list()
  local list_handler = new_parallelism_handler()
  local size_handler = new_parallelism_handler()

  local sizes, lists;
  self:sizes(size_handler)
  for _, inventory_reference in ipairs(self.inventories) do
    list_handler:add_task(inventory_reference.inventory.list)
  end

  parallel.waitForAll(
    function()
      sizes = size_handler:execute()
    end,
    function()
      lists = list_handler:execute()
    end
  )
  local items = {}

  for i, item_list in ipairs(lists) do
    local slot_offset = 0
    for j = 1, i - 1 do
      slot_offset = slot_offset + sizes[j]
    end

    for slot, item in pairs(item_list) do
      items[slot + slot_offset] = item
    end
  end

  self.last_list = items
  return items
end



--- Get item detail of an item in a given mega slot.
--- 
--- Note that this method is not cached, and will always fetch the item detail from the peripheral.
---@param slot integer The slot to get the item detail of.
---@param sizes integer[]? The sizes of the inventories. Mainly used internally, but can be used to optimize get_item_detail calls.
---@return item? item The item in the slot, or nil if the slot is empty.
function mega_inventory:get_item_detail(slot, sizes)
  expect(1, slot, "number")
  expect(2, sizes, "table", "nil")

  local inv_ref, slot = self:calc_inv_via_slot(slot, sizes)
  return inv_ref.inventory.getItemDetail(slot)
end



--- Calculate the inventory and actual slot of a slot in the mega inventory.
---@param slot integer The slot to calculate the inventory and slot of.
---@param sizes integer[]? The sizes of the inventories. Used internally when pushing many items, to avoid recalculating sizes multiple times.
---@return InventoryReference inventory_ref The inventory the slot is in.
---@return integer slot The slot within that inventory.
function mega_inventory:calc_inv_via_slot(slot, sizes)
  expect(1, slot, "number")

  sizes = sizes or self:sizes()
  local slot_offset = 0
  for i, size in ipairs(sizes) do
    if slot > slot_offset and slot <= slot_offset + size then
      return self.inventories[i], slot - slot_offset
    end
    slot_offset = slot_offset + size
  end

  error("Slot out of range", 2)
end



--- Push items from this mega inventory to a named inventory.
---@param name string The name of the inventory to push to.
---@param item_name string The name of the item to push.
---@param count integer The maximum number of items to push.
---@param result_slot integer? The slot to push to. If not provided, the first available slot is used.
---@return integer pushed The number of items pushed.
function mega_inventory:push_items(name, item_name, count, result_slot)
  expect(1, name, "string")
  expect(2, item_name, "string")
  expect(3, count, "number")
  expect(4, result_slot, "number", "nil")

  local items = self.last_list
  if not items then
    items = self:list()
  end

  local ph = new_parallelism_handler()
  local should_push = 0
  local sizes = self:sizes()

  for slot, item in pairs(items) do
    if item.name == item_name then
      local inventory_ref, inv_slot = self:calc_inv_via_slot(slot, sizes)
      ph:add_task(inventory_ref.inventory.pushItems, name, inv_slot, count - should_push, result_slot)
      should_push = should_push + math.min(item.count, count - should_push)

      if should_push >= count then
        break
      end
    end
  end

  -- Invalidate the last list, since we have altered the inventory.
  self.last_list = nil

  return sum(ph:execute()) -- The actual amounts pushed are returned by the peripheral calls.
end



--- Push items to other spots in the mega inventory.
---@param from_slot integer The slot to push from.
---@param to_slot integer The slot to push to.
---@param count integer? The maximum number of items to push. If not provided, all items are pushed.
---@param sizes integer[]? The sizes of the inventories. Used internally when pushing many items, to avoid recalculating sizes multiple times.
---@return integer pushed The number of items pushed.
function mega_inventory:push_items_internal(from_slot, to_slot, count, sizes)
  expect(1, from_slot, "number")
  expect(2, to_slot, "number")
  expect(3, count, "number", "nil")
  expect(4, sizes, "table", "nil")

  local from_inv_ref, from_slot = self:calc_inv_via_slot(from_slot, sizes)
  local to_inv_ref, to_slot = self:calc_inv_via_slot(to_slot, sizes)

  return from_inv_ref.inventory.pushItems(to_inv_ref.name, from_slot, count, to_slot)
end


--- Push a list of items from this mega inventory to a named inventory.
---@param name string The name of the inventory to push to.
---@param items table<string, true> The items to push.
---@param count integer The maximum number of items to push.
---@return integer pushed The number of items pushed.
function mega_inventory:batch_push_items(name, items, count)
  expect(1, name, "string")
  expect(2, items, "table")
  for k in pairs(items) do
    if type(k) ~= "string" then
      error(("Bad argument #2: Table has key of type '%s', expected only 'string'"):format(type(k)), 2)
    end
  end
  expect(3, count, "number")

  if not self.last_list then
    self:list()
  end

  local ph = new_parallelism_handler()
  local should_push = 0
  local sizes = self:sizes()

  for slot, item in pairs(self.last_list) do
    if items[item.name] then
      local inventory_ref, inv_slot = self:calc_inv_via_slot(slot, sizes)
      ph:add_task(inventory_ref.inventory.pushItems, name, inv_slot, count - should_push)
      should_push = should_push + math.min(item.count, count - should_push)

      if should_push >= count then
        break
      end
    end
  end

  -- Invalidate the last list, since we have altered the inventory.
  self.last_list = nil

  return sum(ph:execute()) -- The actual amounts pushed are returned by the peripheral calls.
end



--- Pull items from a named inventory to this mega inventory.
---@param name string The name of the inventory to pull from.
---@param item_name string The name of the item to pull.
---@param count integer The maximum number of items to pull.
---@return integer pulled The number of items pulled.
function mega_inventory:pull_items(name, item_name, count)
  expect(1, name, "string")
  expect(2, item_name, "string")
  expect(3, count, "number")

  --- List of items in the other inventory.
  local other_inventory = peripheral.call(name, "list") --[[@as table<integer, item>]]
  local ph = new_parallelism_handler()

  local actual_moved = 0
  local should_move = 0

  -- Attempt to pull to each inventory in the mega inventory.
  for _, inventory_ref in ipairs(self.inventories) do
    local pullItemsRef = inventory_ref.inventory.pullItems
    for slot, item in pairs(other_inventory) do
      if item.name == item_name then
        ph:add_task(pullItemsRef, name, slot, count - should_move)
        should_move = should_move + math.min(item.count, count - should_move)

        if should_move >= count then
          break
        end
      end
    end

    actual_moved = actual_moved + sum(ph:execute())

    if actual_moved >= count then
      break
    end
    should_move = actual_moved

    other_inventory = peripheral.call(name, "list") --[[@as table<integer, item>]]
    if not next(other_inventory) then
      break
    end
  end

  -- Invalidate the last list, since we have altered the inventory.
  self.last_list = nil

  return actual_moved
end



--- Pull *all* items from a named inventory to this mega inventory.
---@param name string The name of the inventory to pull from.
---@return integer pulled The number of items pulled.
function mega_inventory:pull_all_items(name)
  expect(1, name, "string")

  --- List of items in the other inventory.
  local other_inventory = peripheral.call(name, "list") --[[@as table<integer, item>]]
  local ph = new_parallelism_handler()

  local actual_moved = 0

  -- Attempt to pull to each inventory in the mega inventory.
  for _, inventory_ref in ipairs(self.inventories) do
    local pullItemsRef = inventory_ref.inventory.pullItems
    for slot, item in pairs(other_inventory) do
      ph:add_task(pullItemsRef, name, slot, item.count)
    end

    actual_moved = actual_moved + sum(ph:execute())
    other_inventory = peripheral.call(name, "list") --[[@as table<integer, item>]]
    if not next(other_inventory) then
      break
    end
  end

  -- Invalidate the last list, since we have altered the inventory.
  self.last_list = nil

  return actual_moved
end



--- Count the given items in the inventory.
---@param item_name string The name of the item to count.
---@return integer count The number of items in the inventory.
function mega_inventory:count(item_name)
  expect(1, item_name, "string")

  if not self.last_list then
    self:list()
  end

  local count = 0
  for _, item in pairs(self.last_list) do
    if item.name == item_name then
      count = count + item.count
    end
  end

  return count
end



--- Defragment the inventory.
function mega_inventory:defragment()
  local list = self:list()
  local sizes = self:sizes()
  local item_limit_cache = {} ---@type table<string, integer>
  local parallelism_handler = new_parallelism_handler()

  -- Determine which slots have items.
  local slots_with_items = {} ---@type integer[]
  for slot in pairs(list) do
    table.insert(slots_with_items, slot)
  end
  table.sort(slots_with_items)


  -- Go through each slot, and get the item data.
  -- We will likely end up sending out more `getItemDetail` calls than necessary, but this should be fine.
  for i, slot in ipairs(slots_with_items) do
    parallelism_handler:add_task(function()
      if not item_limit_cache[list[slot].name] then
        local data = self:get_item_detail(slot, sizes)

        if data then
          item_limit_cache[data.name] = data.maxCount
        end
      end
    end)
  end

  parallelism_handler:execute()

  local len = #slots_with_items
  local current = 1
  while current < len do
    local list_entry = list[slots_with_items[current]]
    local cache_entry = item_limit_cache[list_entry.name]

    if list_entry.count < cache_entry then
      for search_index = len, current + 1, -1 do
        local other_list_entry = list[slots_with_items[search_index]]

        if other_list_entry.name == list_entry.name then
          local to_move = math.min(cache_entry - list_entry.count, other_list_entry.count)
          local from_slot, to_slot = slots_with_items[search_index], slots_with_items[current]
          parallelism_handler:add_task(function()
            self:push_items_internal(from_slot, to_slot, to_move, sizes)
          end)
          list_entry.count = list_entry.count + to_move
          other_list_entry.count = other_list_entry.count - to_move

          if other_list_entry.count == 0 then
            table.remove(slots_with_items, search_index)
            len = len - 1
          end

          if list_entry.count >= cache_entry then
            break
          end
        end
      end
    end

    current = current + 1
  end

  parallelism_handler:execute()
end



--- Add an inventory to the mega inventory.
---@param inventory Inventory The inventory to add.
---@return MegaInventory self The mega inventory.
function mega_inventory:add_inventory(inventory)
  expect(1, inventory, "table")

  table.insert(self.inventories, {
    inventory = inventory,
    name = peripheral.getName(inventory),
  })
  return self
end



--- Remove an inventory from the mega inventory.
---@param inventory_name string The inventory to remove.
---@return MegaInventory self The mega inventory.
function mega_inventory:remove_inventory(inventory_name)
  expect(1, inventory_name, "string")

  for i, inventory_reference in ipairs(self.inventories) do
    if inventory_reference.name == inventory_name then
      table.remove(self.inventories, i)
      break
    end
  end

  self.last_list = nil

  return self
end




return mega_inventory
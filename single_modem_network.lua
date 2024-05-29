--- Implements peripheral.find and etc, but for a single modem instead of all
--- attached modems.

---@class SingleModemNetwork
local smn = {}

---@type Modem? The modem to use.
local modem

--- Set the modem to use.
---@param modem_side computerSide The side of the modem to use.
function smn.set_modem(modem_side)
  local tmp = peripheral.wrap(modem_side) --[[@as Modem?]]
  if not tmp then
    error(("No modem found on side '%s'."):format(modem_side), 2)
  end

  if tmp.isWireless() then
    error("Modem cannot be wireless.", 2)
  end

  modem = tmp
end

--- Get the name of the modem in use.
---@return string? name The name of the modem.
function smn.get_modem()
  return modem and peripheral.getName(modem)
end

--- Find a peripheral on the network.
---@param type string The type of peripheral to find.
---@param filter_func nil|fun(name: string, wrapped: table?): boolean? A function to filter the peripherals.
---@return wrappedPeripheral? ... The found peripherals. 
function smn.find(type, filter_func)
  if not modem then
    error("No modem set.", 2)
  end

  filter_func = filter_func or function() return true end

  local names = modem.getNamesRemote()

  local found = {}

  for _, name in ipairs(names) do
    if modem.hasTypeRemote(name, type) and filter_func(name, smn.wrap(name)) then
      table.insert(found, peripheral.wrap(name))
    end
  end

  return table.unpack(found)
end

--- Wrap a peripheral on the network.
---@param name string The name of the peripheral to wrap.
---@return wrappedPeripheral? peripheral The wrapped peripheral.
function smn.wrap(name)
  if not modem then
    error("No modem set.", 2)
  end

  if not modem.isPresentRemote(name) then
    return nil -- so peripheral.wrap doesn't wrap something from another network.
  end

  return peripheral.wrap(name)
end

--- Call a method on a peripheral on the network.
---@param name string The name of the peripheral to call.
---@param method string The method to call.
---@param ... any The arguments to pass to the method.
---@return any? ... The return values of the method.
function smn.call(name, method, ...)
  if not modem then
    error("No modem set.", 2)
  end

  return modem.callRemote(name, method, ...)
end

--- Get the methods of a peripheral on the network.
---@param name string The name of the peripheral to get the methods of.
---@return string[] methods The methods of the peripheral.
function smn.getMethods(name)
  if not modem then
    error("No modem set.", 2)
  end

  return modem.getMethodsRemote(name)
end

--- Get the names of the peripherals on the network.
---@return string[] names The names of the peripherals.
function smn.getNames()
  if not modem then
    error("No modem set.", 2)
  end

  return modem.getNamesRemote()
end

--- Check if a peripheral is present on the network.
---@param name string The name of the peripheral to check for.
---@return boolean present Whether the peripheral is present.
function smn.isPresent(name)
  if not modem then
    error("No modem set.", 2)
  end

  return modem.isPresentRemote(name)
end

--- Get the type of a peripheral on the network.
---@param name string The name of the peripheral to get the type of.
---@return string? ... The types of the peripheral.
function smn.getType(name)
  if not modem then
    error("No modem set.", 2)
  end

  return modem.getTypeRemote(name)
end

--- Check if a peripheral has a type on the network.
---@param name string The name of the peripheral to check the type of.
---@param type string The type to check for.
---@return boolean hasType Whether the peripheral has the type.
function smn.hasType(name, type)
  if not modem then
    error("No modem set.", 2)
  end

  return modem.hasTypeRemote(name, type)
end

--- Open a channel on the modem.
---@param channel number The channel to open.
function smn.open(channel)
  if not modem then
    error("No modem set.", 2)
  end

  modem.open(channel)
end

--- Close a channel on the modem.
---@param channel number The channel to close.
function smn.close(channel)
  if not modem then
    error("No modem set.", 2)
  end

  modem.close(channel)
end

--- Close all channels on the modem.
function smn.closeAll()
  if not modem then
    error("No modem set.", 2)
  end

  modem.closeAll()
end

--- Check if a channel is open on the modem.
---@param channel number The channel to check.
---@return boolean isOpen Whether the channel is open.
function smn.isOpen(channel)
  if not modem then
    error("No modem set.", 2)
  end

  return modem.isOpen(channel)
end

--- Check if the modem is wireless. NOTE: This module can only be used on wired
--- modems, so this should always return false.
---@return boolean isWireless Whether the modem is wireless.
function smn.isWireless()
  if not modem then
    error("No modem set.", 2)
  end

  return modem.isWireless()
end

--- Transmit a message on the modem.
---@param channel number The channel to transmit on.
---@param replyChannel number The channel to reply on.
---@param message any The message to transmit
function smn.transmit(channel, replyChannel, message)
  if not modem then
    error("No modem set.", 2)
  end

  modem.transmit(channel, replyChannel, message)
end

--- Get the local name.
---@return string name The local name.
function smn.getNameLocal()
  if not modem then
    error("No modem set.", 2)
  end

  return modem.getNameLocal()
end

return smn

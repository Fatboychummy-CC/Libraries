local expect = require "cc.expect".expect

local comms = {}
local last_ref = 0

--- Create a new "namespace" for communications.
---@param name string The name of the namespace.
---@param ... integer The channels to listen on.
---@return namespace namespace The communication namespace.
function comms.namespace(name, ...)
  expect(1, name, "string")
  ---@class namespace
  local namespace = {}
  local mt = {__index = namespace}

  local args = table.pack(...)
  if args.n == 0 then
    error("Expected at least one channel.")
  end
  for i = 1, args.n do
    expect(i + 1, args[i], "number")
  end

  local channels = args

  local identifier = math.random(0, 2^31 - 2)
  local modem ---@type Modem?
  local modem_id ---@type string?

  --- Create a new packet of data for transmission.
  ---@param payload any The data to send.
  ---@param response_ref integer? A unique ID for this packet.
  ---@param identifier_ref integer? Used for responses. 
  ---@return packet packet The packet to be sent.
  ---@nodiscard I mean, unless you want to create it and immediately get rid of it...?
  function namespace.new_packet(payload, response_ref, identifier_ref)
    expect(1, payload, "table")
    expect(2, response_ref, "number", "nil")
    expect(3, identifier_ref, "number", "nil")

    last_ref = last_ref + 1 
    return setmetatable({
      protocol = name,
      ref = last_ref,
      identifier = identifier,
      payload = payload,
      packet_response_ref = response_ref,
      packet_response_identifier = identifier_ref,
      fat_comms = true
    }, mt) --[[@as packet]]
  end

  --- Create a new packet that acts as a response to a packet.
  ---@param packet packet The packet to respond to.
  ---@param payload any The payload to respond with.
  ---@return packet response The response packet.
  ---@nodiscard I mean, unless you want to create it and immediately get rid of it...?
  function namespace.new_response(packet, payload)
    expect(1, packet, "table")

    return setmetatable(namespace.new_packet(payload, packet.ref, packet.identifier), mt) --[[@as packet]]
  end

  --- Send a packet.
  ---@param packet packet The packet to send.
  ---@param channel integer The channel to send on.
  function namespace.send_packet(packet, channel)
    expect(1, packet, "table")
    expect(2, channel, "number")

    if not modem then
      error("Modem is not set.", 2)
    end

    modem.transmit(channel, channel, packet)
  end

  --- Set the modem to use with the communication system.
  ---@param _modem Modem|string The modem to use.
  function namespace.set_modem(_modem)
    expect(1, _modem, "table", "string")

    if type(_modem) == "string" then
      _modem = peripheral.wrap(_modem) --[[@as Modem]]
    end
    if type(_modem.transmit) ~= "function" then
      error("Bad argument #1 to set_modem: Expected Modem peripheral or name.", 2)
    end

    -- Close channels on previous modem if we are switching modems.
    if modem then
      for i = 1, channels.n do
        modem.close(channels[i])
      end
    end

    -- Set the new modem.
    modem = _modem
    modem_id = peripheral.getName(modem)

    -- Open channels on the new modem.
    for i = 1, channels.n do
      modem.open(channels[i])
    end
  end

  local function check_channels(v)
    for i = 1, channels.n do
      if channels[i] == v then
        return true
      end
    end

    return false
  end

  --- Receive a packet and return it.
  ---@return packet packet The packet received.
  function namespace.receive()
    while true do
      local _, _modem_id, channel, _, data = os.pullEvent("modem_message")
      if _modem_id == modem_id and check_channels(channel) and type(data) == "table" and data.fat_comms and data.protocol == name then
        return data --[[@as packet]]
      end
    end
  end

  function namespace.set_channels(...)
    local args = table.pack(...)
    if args.n == 0 then
      error("Expected at least one channel.")
    end
    for i = 1, args.n do
      expect(i, args[i], "number")
    end
    
    if modem then
      for i = 1, channels.n do
        modem.close(channels[i])
      end
      for i = 1, args.n do
        modem.open(args[i])
      end
    end
      
    channels = args
  end

  --- Returns the name of the modem.
  ---@return string? modem_id The modem's name.
  function namespace.get_modem_name()
    return modem_id
  end

  return namespace
end

return comms
---@meta

---@class packet
---@field protocol string Similar to the rednet system, these packets can be differentiated via a protocol string.
---@field payload any The packet payload.
---@field ref integer The reference ID of the packet, unique.
---@field identifier integer The computer identifier. Randomly generated.
---@field packet_response_ref integer? The packet ID being responded to.
---@field packet_response_identifier integer? The identifier of the packet being responded to.
---@field fat_comms true Something to separate these communications from other communications
--[[
    Raw Socket Example
    Demonstrates raw socket creation for custom protocol implementation
    Note: Requires root/administrator privileges
]]

local rsocket = require("rmp.rsocket")

print("=== Raw Socket Example ===")
print("Note: This example requires root/administrator privileges\n")

-- Create raw socket
local sock = rsocket.new("raw")
if not sock then
    print("Failed to create raw socket")
    print("Try running with sudo/administrator privileges")
    os.exit(1)
end

print("Protocol: " .. sock:getprotocol())
print("Raw socket created successfully!")

print("\nRaw sockets allow you to:")
print("  - Send/receive IP packets with custom headers")
print("  - Implement custom network protocols")
print("  - Perform low-level network analysis")
print("  - Create network security tools")

print("\nExample: Sending a raw IP packet (simplified)")

-- Custom IP packet structure (example - not a complete implementation)
local function create_custom_packet()
    -- IP Header fields (simplified)
    local version_ihl = 0x45  -- IPv4, 20 byte header
    local tos = 0
    local total_length = 40   -- 20 byte IP header + 20 byte payload
    local identification = 12345
    local flags_offset = 0
    local ttl = 64
    local protocol = 253      -- Reserved for testing
    local checksum = 0        -- Should be calculated
    local src_ip = {127, 0, 0, 1}
    local dst_ip = {127, 0, 0, 1}
    
    local packet = string.char(version_ihl, tos)
    packet = packet .. string.char(math.floor(total_length / 256), total_length % 256)
    packet = packet .. string.char(math.floor(identification / 256), identification % 256)
    packet = packet .. string.char(math.floor(flags_offset / 256), flags_offset % 256)
    packet = packet .. string.char(ttl, protocol)
    packet = packet .. string.char(0, 0)  -- Checksum placeholder
    packet = packet .. string.char(src_ip[1], src_ip[2], src_ip[3], src_ip[4])
    packet = packet .. string.char(dst_ip[1], dst_ip[2], dst_ip[3], dst_ip[4])
    packet = packet .. "Custom protocol data!"
    
    return packet
end

local packet = create_custom_packet()
print("\nCreated custom packet (" .. #packet .. " bytes)")

-- Note: Sending raw packets requires proper IP header construction
-- This is just a demonstration of the API
local sent, err = sock:sendto(packet, "127.0.0.1", 0)
if sent then
    print("Sent " .. sent .. " bytes")
else
    print("Send failed: " .. (err or "unknown"))
end

sock:close()

print("\n=== Raw Socket Example Complete ===")
print("\nFor production use:")
print("  - Implement proper checksum calculation")
print("  - Handle IP fragmentation")
print("  - Follow protocol specifications")
print("  - Consider security implications")

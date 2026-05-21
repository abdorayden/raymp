--[[
    UDP Client Example
    Demonstrates UDP datagram client (connectionless)
]]

local rsocket = require("rmp.rsocket")

print("=== UDP Client Example ===")
print("Connecting to UDP server at 127.0.0.1:9090...\n")

-- Create UDP socket
local client = rsocket.new("udp")
assert(client, "Failed to create UDP socket")

print("Protocol: " .. client:getprotocol())
print("\nType messages to send (empty line to quit):")

-- Communication loop
while true do
    io.write("> ")
    local msg = io.read()
    
    if msg == "" then
        break
    end
    
    -- Send datagram to server
    local sent, err = client:sendto(msg, "127.0.0.1", 9090)
    if not sent then
        print("Send failed: " .. (err or "unknown"))
        break
    end
    
    -- Receive response
    local data, ip, port = client:recvfrom(1024)
    if not data then
        print("Receive failed: " .. (ip or "unknown"))
        break
    end
    
    print("From [" .. ip .. ":" .. port .. "]: " .. data)
end

client:close()
print("\nDisconnected")

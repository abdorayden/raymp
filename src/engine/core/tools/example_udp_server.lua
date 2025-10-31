--[[
    UDP Server Example
    Demonstrates UDP datagram server (connectionless)
]]

local rsocket = require("rmp.rsocket")

print("=== UDP Server Example ===")
print("Starting UDP server on port 9090...\n")

-- Create UDP socket
local server = rsocket.new("udp")
assert(server, "Failed to create UDP socket")

print("Protocol: " .. server:getprotocol())

-- Bind to address
local ok, err = server:bind("0.0.0.0", 9090)
if not ok then
    print("Bind failed: " .. err)
    os.exit(1)
end

print("UDP server listening on 0.0.0.0:9090")
print("Waiting for datagrams...\n")

-- Receive and respond to datagrams
while true do
    -- Receive datagram from any client
    local data, ip, port = server:recvfrom(1024)
    if data then
        print("[" .. ip .. ":" .. port .. "] Received: " .. data)
        
        -- Send response back to sender
        local response = "Echo: " .. data
        local sent, err = server:sendto(response, ip, port)
        if sent then
            print("[" .. ip .. ":" .. port .. "] Sent: " .. response)
        else
            print("[" .. ip .. ":" .. port .. "] Send failed: " .. (err or "unknown"))
        end
    else
        print("Receive failed: " .. (ip or "unknown"))
    end
end

server:close()

--[[
    UDP Broadcast Example
    Demonstrates UDP broadcast for local network discovery
]]

local rsocket = require("rmp.rsocket")

print("=== UDP Broadcast Example ===")
print("Broadcasting on port 9999...\n")

-- Create UDP socket
local broadcaster = rsocket.new("udp")
assert(broadcaster, "Failed to create UDP socket")

-- Enable broadcast
local ok, err = broadcaster:setbroadcast(true)
if not ok then
    print("Failed to enable broadcast: " .. (err or "unknown"))
    os.exit(1)
end

print("Protocol: " .. broadcaster:getprotocol())
print("Broadcast enabled!")

-- Create listener socket
local listener = rsocket.new("udp")
assert(listener, "Failed to create listener socket")

ok, err = listener:bind("0.0.0.0", 9999)
if not ok then
    print("Bind failed: " .. err)
    listener:close()
    broadcaster:close()
    os.exit(1)
end

listener:setnonblock(true)

print("Listening on 0.0.0.0:9999")
print("\nSending broadcasts every 2 seconds...")
print("Press Ctrl+C to stop\n")

local count = 0

-- Broadcast loop
while true do
    count = count + 1
    local msg = "Broadcast #" .. count .. " at " .. os.date("%H:%M:%S")
    
    -- Send broadcast
    local sent, err = broadcaster:sendto(msg, "255.255.255.255", 9999)
    if sent then
        print("[SENT] " .. msg)
    else
        print("[ERROR] Broadcast failed: " .. (err or "unknown"))
    end
    
    -- Check for responses (non-blocking)
    local data, ip, port = listener:recvfrom(1024)
    if data then
        print("[RECV] From " .. ip .. ":" .. port .. " - " .. data)
    end
    
    -- Wait 2 seconds
    local start = os.time()
    while os.time() - start < 2 do
        -- Check for responses while waiting
        data, ip, port = listener:recvfrom(1024)
        if data then
            print("[RECV] From " .. ip .. ":" .. port .. " - " .. data)
        end
    end
end

broadcaster:close()
listener:close()

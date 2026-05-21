--[[
    Non-blocking Socket Example
    Demonstrates non-blocking I/O with multiple connections
]]

local rsocket = require("rmp.rsocket")

print("=== Non-blocking Socket Example ===")
print("Starting non-blocking TCP server on port 8888...\n")

-- Create server socket
local server = rsocket.new("tcp")
assert(server, "Failed to create server socket")

-- Bind and listen
assert(server:bind("0.0.0.0", 8888))
assert(server:listen(10))

-- Set non-blocking mode
assert(server:setnonblock(true))

print("Server listening on 0.0.0.0:8888 (non-blocking)")
print("Protocol: " .. server:getprotocol())
print("Waiting for connections...\n")

-- Track active client connections
local clients = {}
local client_count = 0

print("Press Ctrl+C to stop\n")

-- Main event loop
while true do
    -- Try to accept new connections (non-blocking)
    local client, ip, port = server:accept()
    if client then
        client_count = client_count + 1
        local client_id = client_count
        
        -- Set client to non-blocking
        client:setnonblock(true)
        client:setnodelay(true)
        
        clients[client_id] = {
            socket = client,
            ip = ip,
            port = port,
            buffer = ""
        }
        
        print("[Client #" .. client_id .. "] Connected from " .. ip .. ":" .. port)
        
        -- Send welcome message
        client:send("Welcome! You are client #" .. client_id .. "\n")
    end
    
    -- Process data from all connected clients
    for client_id, info in pairs(clients) do
        local data, err = info.socket:recv(1024)
        if data then
            print("[Client #" .. client_id .. "] Received: " .. data)
            
            -- Echo back to sender
            info.socket:send("[Echo] " .. data)
            
            -- Broadcast to all other clients
            for other_id, other_info in pairs(clients) do
                if other_id ~= client_id then
                    other_info.socket:send("[Client #" .. client_id .. "] " .. data)
                end
            end
        elseif err and err:find("closed") then
            -- Client disconnected
            print("[Client #" .. client_id .. "] Disconnected")
            info.socket:close()
            clients[client_id] = nil
        end
        -- If no data and no error, just means no data available (non-blocking)
    end
    
    -- Small sleep to prevent busy-waiting
    -- In production, use select/poll/epoll for better efficiency
    local sleep_start = os.clock()
    while os.clock() - sleep_start < 0.01 do end  -- 10ms sleep
end

-- Cleanup
for _, info in pairs(clients) do
    info.socket:close()
end
server:close()

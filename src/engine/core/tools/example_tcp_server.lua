--[[
    TCP Server Example
    Demonstrates TCP server with multiple clients handling
]]

local rsocket = require("rmp.rsocket")

print("=== TCP Server Example ===")
print("Starting TCP server on port 8080...\n")

-- Create TCP socket (default protocol)
local server = rsocket.new("tcp")
assert(server, "Failed to create TCP socket")

-- Bind to address
local ok, err = server:bind("0.0.0.0", 8080)
if not ok then
    print("Bind failed: " .. err)
    os.exit(1)
end

-- Listen for connections
ok, err = server:listen(5)
if not ok then
    print("Listen failed: " .. err)
    os.exit(1)
end

-- Enable TCP_NODELAY for better performance
server:setnodelay(true)

print("TCP server listening on 0.0.0.0:8080")
print("Waiting for connections...\n")

-- Accept and handle connections
while true do
    local client, ip, port = server:accept()
    if client then
        print("[" .. ip .. ":" .. port .. "] Connected")
        
        -- Enable TCP_NODELAY on client connection
        client:setnodelay(true)
        
        -- Handle client communication
        while true do
            local data, err = client:recv(1024)
            if not data then
                print("[" .. ip .. ":" .. port .. "] Disconnected: " .. (err or "unknown"))
                break
            end
            
            print("[" .. ip .. ":" .. port .. "] Received: " .. data)
            
            -- Echo back with timestamp
            local response = os.date("%H:%M:%S") .. " > " .. data
            local sent = client:send(response)
            if not sent then
                print("[" .. ip .. ":" .. port .. "] Send failed")
                break
            end
        end
        
        client:close()
    end
end

server:close()

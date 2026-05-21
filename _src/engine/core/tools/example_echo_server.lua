--[[
    Simple RSocket Echo Server Example
    Works on Windows, Linux, and macOS
]]

local rsocket = require("rmp.rsocket")

print("Starting echo server on port 8080...")

-- Create and setup server
local server = rsocket.new()
assert(server:bind("0.0.0.0", 8080))
assert(server:listen(10))

print("Echo server listening on 0.0.0.0:8080")
print("Press Ctrl+C to stop\n")

-- Simple blocking accept loop
while true do
    local client, ip, port = server:accept()
    if client then
        print("Client connected from " .. ip .. ":" .. port)
        
        -- Echo loop
        while true do
            local data, err = client:recv()
            if not data then
                print("Client disconnected: " .. (err or "unknown"))
                break
            end
            
            print("Received: " .. data)
            
            local sent = client:send(data)
            if not sent then
                print("Send failed")
                break
            end
        end
        
        client:close()
    end
end

server:close()

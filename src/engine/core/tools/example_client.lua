--[[
    Simple RSocket Client Example
    Works on Windows, Linux, and macOS
]]

local rsocket = require("rmp.rsocket")

-- Create client socket
local client = rsocket.new()

-- Connect to server
print("Connecting to 127.0.0.1:8080...")
local ok, err = client:connect("127.0.0.1", 8080)
if not ok then
    print("Connection failed: " .. err)
    os.exit(1)
end

print("Connected! Type messages to send (empty line to quit)")

-- Simple send/receive loop
while true do
    io.write("> ")
    local msg = io.read()
    
    if msg == "" then
        break
    end
    
    -- Send message
    local sent = client:send(msg)
    if not sent then
        print("Send failed")
        break
    end
    
    -- Receive echo
    local data, err = client:recv()
    if not data then
        print("Receive failed: " .. err)
        break
    end
    
    print("Echo: " .. data)
end

client:close()
print("Disconnected")

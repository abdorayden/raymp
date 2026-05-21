--[[
    TCP Client Example
    Demonstrates TCP client connection and communication
]]

local rsocket = require("rmp.rsocket")

print("=== TCP Client Example ===")
print("Connecting to TCP server at 127.0.0.1:8080...\n")

-- Create TCP socket
local client = rsocket.new("tcp")
assert(client, "Failed to create TCP socket")

-- Connect to server
local ok, err = client:connect("127.0.0.1", 8080)
if not ok then
    print("Connection failed: " .. err)
    os.exit(1)
end

print("Connected successfully!")
print("Protocol: " .. client:getprotocol())

-- Enable TCP_NODELAY
client:setnodelay(true)

print("\nType messages to send (empty line to quit):")

-- Communication loop
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
    
    -- Receive response
    local data, err = client:recv(1024)
    if not data then
        print("Receive failed: " .. (err or "unknown"))
        break
    end
    
    print("Server: " .. data)
end

client:close()
print("\nDisconnected")

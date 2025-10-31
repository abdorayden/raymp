--[[
    ICMP Ping Example
    Demonstrates ICMP echo request (basic ping functionality)
    Note: May require root/administrator privileges on some systems
]]

local rsocket = require("rmp.rsocket")

print("=== ICMP Ping Example ===")
print("Note: This example may require root/administrator privileges\n")

-- Create ICMP socket
local sock = rsocket.new("icmp")
if not sock then
    print("Failed to create ICMP socket")
    print("Try running with sudo/administrator privileges")
    os.exit(1)
end

print("Protocol: " .. sock:getprotocol())

-- Set non-blocking mode
sock:setnonblock(true)

-- ICMP Echo Request structure
-- Type: 8, Code: 0, Checksum: calculated, ID: random, Sequence: counter
local function create_icmp_echo(seq)
    local type = 8  -- Echo Request
    local code = 0
    local id = 12345
    local data = "Ping from Lua!"
    
    -- Build ICMP packet (simplified - checksum calculation omitted for brevity)
    local packet = string.char(type, code, 0, 0)  -- Type, Code, Checksum (temp)
    packet = packet .. string.char(math.floor(id / 256), id % 256)
    packet = packet .. string.char(math.floor(seq / 256), seq % 256)
    packet = packet .. data
    
    return packet
end

local target = "8.8.8.8"  -- Google DNS
print("Pinging " .. target .. "...\n")

for i = 1, 4 do
    local packet = create_icmp_echo(i)
    local start_time = os.clock()
    
    -- Send ICMP Echo Request
    local sent, err = sock:sendto(packet, target, 0)
    if not sent then
        print("Ping #" .. i .. " failed: " .. (err or "unknown"))
    else
        print("Ping #" .. i .. " sent to " .. target)
        
        -- Try to receive response (simplified)
        local timeout = 1.0  -- 1 second timeout
        local deadline = os.clock() + timeout
        local received = false
        
        while os.clock() < deadline do
            local data, ip, port = sock:recvfrom(1024)
            if data then
                local rtt = (os.clock() - start_time) * 1000
                print("  Reply from " .. ip .. " time=" .. string.format("%.2f", rtt) .. "ms")
                received = true
                break
            end
        end
        
        if not received then
            print("  Request timed out")
        end
    end
    
    -- Wait 1 second before next ping
    if i < 4 then
        local wait_start = os.time()
        while os.time() - wait_start < 1 do end
    end
end

sock:close()
print("\nPing complete")

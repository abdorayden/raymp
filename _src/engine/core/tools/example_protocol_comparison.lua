--[[
    Protocol Comparison Example
    Demonstrates differences between TCP, UDP, ICMP, and RAW protocols
]]

local rsocket = require("rmp.rsocket")

print("=== RSocket Protocol Comparison ===\n")

-- Test each protocol
local protocols = {"tcp", "udp", "icmp", "raw"}

for _, proto in ipairs(protocols) do
    print("Protocol: " .. proto:upper())
    print(string.rep("-", 50))
    
    local sock = rsocket.new(proto)
    if sock then
        print("✓ Socket created successfully")
        print("  Type: " .. sock:getprotocol())
        
        -- Test protocol-specific features
        if proto == "tcp" then
            print("  Features:")
            print("    - Connection-oriented (reliable)")
            print("    - Stream-based communication")
            print("    - Ordered delivery")
            print("    - Flow control")
            print("  Methods: connect, bind, listen, accept, send, recv")
            print("  Options: setnodelay (TCP_NODELAY)")
            
            -- Demonstrate bind capability
            local ok, err = sock:bind("127.0.0.1", 0)  -- Port 0 = auto-assign
            if ok then
                print("  ✓ Can bind to address")
            end
            
        elseif proto == "udp" then
            print("  Features:")
            print("    - Connectionless (unreliable)")
            print("    - Datagram-based communication")
            print("    - No guaranteed delivery/ordering")
            print("    - Lower overhead than TCP")
            print("  Methods: sendto, recvfrom")
            print("  Options: setbroadcast (SO_BROADCAST)")
            
            -- Demonstrate broadcast capability
            local ok, err = sock:setbroadcast(true)
            if ok then
                print("  ✓ Broadcast enabled")
            end
            
        elseif proto == "icmp" then
            print("  Features:")
            print("    - Network diagnostic protocol")
            print("    - Used by ping, traceroute")
            print("    - Raw packet access")
            print("    - Requires elevated privileges")
            print("  Methods: sendto, recvfrom")
            print("  Use cases: Network monitoring, diagnostics")
            
        elseif proto == "raw" then
            print("  Features:")
            print("    - Complete control over IP packets")
            print("    - Custom protocol implementation")
            print("    - Network analysis tools")
            print("    - Requires elevated privileges")
            print("  Methods: sendto, recvfrom")
            print("  Use cases: Protocol development, security tools")
        end
        
        sock:close()
        print("  ✓ Socket closed\n")
    else
        print("✗ Failed to create socket")
        print("  (May require elevated privileges)\n")
    end
end

print(string.rep("=", 50))
print("\nQuick Reference:")
print("\n1. TCP (Transmission Control Protocol)")
print("   Use when: You need reliable, ordered delivery")
print("   Examples: HTTP, FTP, SSH, databases")
print("\n2. UDP (User Datagram Protocol)")
print("   Use when: Speed > reliability, or for broadcasts")
print("   Examples: DNS, streaming, gaming, VoIP")
print("\n3. ICMP (Internet Control Message Protocol)")
print("   Use when: Network diagnostics and control")
print("   Examples: ping, traceroute, network monitoring")
print("\n4. RAW")
print("   Use when: Implementing custom protocols")
print("   Examples: Network tools, security applications")
print("\n" .. string.rep("=", 50))

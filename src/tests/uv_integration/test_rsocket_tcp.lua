-- Integration test: TCP echo using rmp.rsocket (loopback only)
local ok_socket, rsocket = pcall(require, "rmp.rsocket")

if not ok_socket then
    print("=== Skipping rsocket TCP tests: rmp.rsocket not available ===")
    os.exit(0)
end

local test_count = 0
local pass_count = 0

local function test(name, fn)
    test_count = test_count + 1
    io.write("Test " .. name .. ": ")
    local ok, err = pcall(fn)
    if ok then
        pass_count = pass_count + 1
        print("PASS")
    else
        print("FAIL - " .. err)
    end
end

local function assert_equal(actual, expected, msg)
    msg = msg or "Values should be equal"
    if actual ~= expected then
        error(msg .. " (got: " .. tostring(actual) .. ", expected: " .. tostring(expected) .. ")")
    end
end

local function assert_true(condition, msg)
    msg = msg or "Condition should be true"
    if not condition then
        error(msg)
    end
end

print("=== Running RSocket TCP Integration Tests ===\n")

test("TCP echo on loopback", function()
    local port = 31099
    local server, err = rsocket.new("tcp")
    if not server then
        error(err)
    end

    local ok_bind, err_bind = server:bind("127.0.0.1", port)
    if not ok_bind then
        print("SKIP - bind failed on port " .. port .. ": " .. tostring(err_bind))
        return
    end

    local ok_listen, err_listen = server:listen(1)
    if not ok_listen then
        error(err_listen)
    end

    local client, err_client = rsocket.new("tcp")
    assert_true(client ~= nil, err_client)

    local ok_connect, err_connect = client:connect("127.0.0.1", port)
    assert_true(ok_connect ~= nil, err_connect)

    local peer, ip, p = server:accept()
    assert_true(peer ~= nil, "accept failed")
    assert_equal(ip, "127.0.0.1")
    assert_true(type(p) == "number")

    local sent, err_send = client:send("ping")
    assert_true(sent ~= nil, err_send)

    local msg, err_recv = peer:recv(4)
    assert_true(msg ~= nil, err_recv)
    assert_equal(msg, "ping")

    local sent2, err_send2 = peer:send("pong")
    assert_true(sent2 ~= nil, err_send2)

    local msg2, err_recv2 = client:recv(4)
    assert_true(msg2 ~= nil, err_recv2)
    assert_equal(msg2, "pong")

    client:close()
    peer:close()
    server:close()
end)

print("\n=== RSocket TCP Integration Tests: " .. pass_count .. "/" .. test_count .. " passed ===")

-- Integration tests for Promise scheduler with libuv
local Promise = require("rmp.promises")
if type(Promise.writeFile) ~= "function" or type(Promise.readFile) ~= "function" then
    local ok_local, local_mod = pcall(dofile, "../promises.lua")
    if ok_local and type(local_mod) == "table" then
        Promise = local_mod
    end
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

local function assert_true(condition, msg)
    msg = msg or "Condition should be true"
    if not condition then
        error(msg)
    end
end

local function assert_equal(actual, expected, msg)
    msg = msg or "Values should be equal"
    if actual ~= expected then
        error(msg .. " (got: " .. tostring(actual) .. ", expected: " .. tostring(expected) .. ")")
    end
end

print("=== Running Promise Scheduler Tests ===\n")

test("Promise.timeout resolves", function()
    local resolved = false
    Promise.timeout(10):tthen(function()
        resolved = true
    end)
    Promise.run()
    assert_true(resolved, "timeout did not resolve")
end)

test("Promise.sleep alias", function()
    local resolved = false
    Promise.sleep(5):tthen(function()
        resolved = true
    end)
    Promise.run()
    assert_true(resolved, "sleep did not resolve")
end)

test("Promise.readFile + Promise.writeFile", function()
    local tmp = os.tmpname()
    local data = "promise_io"
    local out = nil

    Promise.writeFile(tmp, data)
        :tthen(function(bytes)
            assert_equal(bytes, #data)
            return Promise.readFile(tmp)
        end)
        :tthen(function(read_data)
            out = read_data
        end)

    Promise.run()
    os.remove(tmp)

    assert_equal(out, data)
end)

test("Promise.spawn exit status", function()
    local result = nil
    Promise.spawn("sh", {"-c", "exit 3"})
        :tthen(function(res)
            result = res
        end)
    Promise.run()
    assert_true(type(result) == "table")
    assert_equal(result.status, 3)
end)

test("Promise.tcpConnect works", function()
    local ok_socket, rsocket = pcall(require, "rmp.rsocket")
    if not ok_socket then
        print("SKIP - rmp.rsocket not available")
        return
    end

    local server, err = rsocket.new("tcp")
    if not server then
        error(err)
    end

    local port = 31109
    local ok_bind, err_bind = server:bind("127.0.0.1", port)
    if not ok_bind then
        print("SKIP - bind failed on port " .. port .. ": " .. tostring(err_bind))
        return
    end

    local ok_listen, err_listen = server:listen(1)
    if not ok_listen then
        error(err_listen)
    end

    Promise.tcpConnect("127.0.0.1", port)
        :tthen(function(client)
            local peer = server:accept()
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

    Promise.run()
end)

print("\n=== Promise Scheduler Tests: " .. pass_count .. "/" .. test_count .. " passed ===")

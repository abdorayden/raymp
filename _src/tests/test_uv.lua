-- Unit tests for the libuv bindings
local ok_uv, uv = pcall(require, "rmp.uv")

if not ok_uv then
    print("=== Skipping libuv binding tests: rmp.uv not available ===")
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

print("=== Running libuv Binding Tests ===\n")

-- Timer test

test("uv.timer_start fires", function()
    local fired = false
    uv.timer_start(10, function()
        fired = true
    end)
    uv.run("default")
    assert_true(fired, "timer did not fire")
end)

-- FS write/read test

test("uv.fs_writefile + uv.fs_readfile", function()
    local tmp = os.tmpname()
    local data = "hello_uv"
    local wrote = false
    local read = false

    uv.fs_writefile(tmp, data, function(err, bytes)
        assert_equal(err, nil)
        assert_equal(bytes, #data)
        wrote = true
        uv.fs_readfile(tmp, function(err2, out)
            assert_equal(err2, nil)
            assert_equal(out, data)
            read = true
        end)
    end)

    uv.run("default")
    os.remove(tmp)

    assert_true(wrote, "write callback not called")
    assert_true(read, "read callback not called")
end)

-- Process spawn test (POSIX)

test("uv.spawn exit status", function()
    local done = false
    uv.spawn("sh", {"-c", "exit 0"}, function(err, status, signal)
        assert_equal(err, nil)
        assert_equal(status, 0)
        assert_equal(signal, 0)
        done = true
    end)
    uv.run("default")
    assert_true(done, "spawn callback not called")
end)

print("\n=== libuv Binding Tests: " .. pass_count .. "/" .. test_count .. " passed ===")

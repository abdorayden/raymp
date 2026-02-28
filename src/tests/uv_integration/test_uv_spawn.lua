-- Integration test: spawn binaries via libuv
local ok_uv, uv = pcall(require, "rmp.uv")

if not ok_uv then
    print("=== Skipping libuv spawn tests: rmp.uv not available ===")
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

print("=== Running libuv Spawn Integration Tests ===\n")

test("spawn success exit code", function()
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

test("spawn non-zero exit code", function()
    local done = false
    uv.spawn("sh", {"-c", "exit 7"}, function(err, status, signal)
        assert_equal(err, nil)
        assert_equal(status, 7)
        assert_equal(signal, 0)
        done = true
    end)
    uv.run("default")
    assert_true(done, "spawn callback not called")
end)

print("\n=== libuv Spawn Integration Tests: " .. pass_count .. "/" .. test_count .. " passed ===")

-- Integration tests for Promise scheduler with libuv
local Promise = require("rmp.promises")

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

print("=== Running Promise Scheduler Tests ===\n")

test("Promise.timeout resolves", function()
    local resolved = false
    Promise.timeout(10):tthen(function()
        resolved = true
    end)
    Promise.run()
    assert_true(resolved, "timeout did not resolve")
end)

print("\n=== Promise Scheduler Tests: " .. pass_count .. "/" .. test_count .. " passed ===")

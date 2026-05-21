-- Integration tests for the Future library
local Future = require("rmp.future")
local test_count = 0
local pass_count = 0

local function test(name, fn)
    test_count = test_count + 1
    io.write("Integration Test " .. name .. ": ")
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

print("=== Running Future Library Integration Tests ===\n")

-- Integration test 1: Complex chaining with multiple delayed futures
test("Complex chaining with multiple delays", function()
    local executor = Future.FutureExecutor.new()
    
    local complex_chain = Future.delay(50, 1)
        :athen(function(x)
            return Future.delay(50, x + 1)  -- Return another future
        end)
        :athen(function(x)
            return x * 2
        end)
        :athen(function(x)
            return Future.delay(50, x + 10)
        end)
        :athen(function(x)
            return x / 2
        end)
    
    executor:spawn(complex_chain)
    local _, results = executor:run_until_complete()
    
    -- (1+1)*2 = 4, (4+10)/2 = 7
    assert_equal(results[1].result, 7)
end)

-- Integration test 2: Nested :athen with error handling
test("Nested :athen with error handling", function()
    local executor = Future.FutureExecutor.new()
    
    local nested_with_error = Future.value(10)
        :athen(function(x)
            if x > 5 then
                return Future.error("value too large")
            end
            return x * 2
        end)
        :catch(function(err)
            return "caught: " .. err
        end)
        :athen(function(x)
            return x .. " and processed"
        end)
    
    executor:spawn(nested_with_error)
    local _, results = executor:run_until_complete()
    
    assert_equal(results[1].result, "caught: value too large and processed")
end)

-- Integration test 3: Race vs All comparison
test("Race vs All comparison", function()
    local executor = Future.FutureExecutor.new()
    
    -- Race: fastest future wins
    local race_future = Future.race({
        Future.delay(100, "slow"),
        Future.delay(10, "fast"),
        Future.delay(50, "medium")
    })
    
    -- All: all futures must complete
    local all_future = Future.all({
        Future.delay(100, "slow"),
        Future.delay(10, "fast"),
        Future.delay(50, "medium")
    })
    
    executor:spawn(race_future)
    executor:spawn(all_future)
    local _, results = executor:run_until_complete()
    
    -- Race result should be "fast"
    assert_equal(results[1].result, "fast")  -- or results[2] depending on spawn order
    
    -- Find the race result and all result
    local race_result, all_result = nil, nil
    
    for _, res in ipairs(results) do
        local temp_status, temp_val = res.future:poll()
        -- Identify based on the type of future by checking the result structure
        if type(res.result) == "string" and #results == 2 then
            -- This is a simplification - in practice, we'd need a better way to identify
            -- But we know the race returns a string and all returns an array
            if type(res.result) == "string" then
                race_result = res.result
            end
        end
    end
    
    -- Simplified check: we know race should return "fast"
    -- Results are stored in the order they complete, not spawn order
    if results[1].result == "fast" then
        race_result = results[1].result
        all_result = results[2].result
    else
        race_result = results[2].result
        all_result = results[1].result
    end
    
    assert_equal(race_result, "fast")
    assert_equal(#all_result, 3)  -- all should return array of 3 values
    assert_equal(all_result[1], "slow")
    assert_equal(all_result[2], "fast") 
    assert_equal(all_result[3], "medium")
end)

-- Integration test 4: Multiple spawn and concurrent execution
test("Multiple spawn and concurrent execution", function()
    local executor = Future.FutureExecutor.new()
    
    -- Create multiple futures with different delays
    local futures = {}
    for i = 1, 5 do
        local f = Future.delay(i * 50, "task_" .. i)  -- Different delays
        table.insert(futures, f)
    end
    
    -- Spawn all futures
    for _, f in ipairs(futures) do
        executor:spawn(f)
    end
    
    local success, results = executor:run_until_complete()
    assert_true(success)
    
    -- Should have 5 results
    assert_equal(#results, 5)
    
    -- Check that all tasks completed with correct values
    local completed_tasks = {}
    for _, res in ipairs(results) do
        table.insert(completed_tasks, res.result)
    end
    
    -- Sort for comparison (results may be in completion order)
    table.sort(completed_tasks)
    for i, task in ipairs(completed_tasks) do
        assert_equal(task, "task_" .. i)
    end
end)

-- Integration test 5: Complex error handling scenario
test("Complex error handling scenario", function()
    local executor = Future.FutureExecutor.new()
    
    local complex_error_handling = Future.value(1)
        :athen(function(x)
            return x + 1
        end)
        :athen(function(x)
            if x == 2 then
                return Future.error("simulated error")
            end
            return "unexpected"
        end)
        :catch(function(err)
            return "handled: " .. err
        end)
        :athen(function(x)
            return Future.delay(10, x .. " - processed")
        end)
    
    executor:spawn(complex_error_handling)
    local _, results = executor:run_until_complete()
    
    assert_equal(results[1].result, "handled: simulated error - processed")
end)

-- Integration test 6: Finally in complex scenarios
test("Finally in complex scenarios", function()
    local executor = Future.FutureExecutor.new()
    local finally_called = false
    local finally_value = nil
    
    local complex_with_finally = Future.delay(20, "initial")
        :athen(function(val)
            return val .. " processed"
        end)
        :finally(function()
            finally_called = true
            finally_value = "cleanup done"
        end)
    
    executor:spawn(complex_with_finally)
    local _, results = executor:run_until_complete()
    
    assert_true(finally_called)
    assert_equal(results[1].result, "initial processed")
end)

-- Integration test 7: Any vs AllSettled comparison
test("Any vs AllSettled comparison", function()
    local executor = Future.FutureExecutor.new()
    
    -- Any: returns first successful
    local any_future = Future.any({
        Future.error("error1"),
        Future.delay(20, "success"),
        Future.error("error2")
    })
    
    -- AllSettled: returns all results regardless of success/failure
    local all_settled_future = Future.allSettled({
        Future.error("error1"),
        Future.value("success"),
        Future.error("error2")
    })
    
    executor:spawn(any_future)
    executor:spawn(all_settled_future)
    local _, results = executor:run_until_complete()
    
    -- Identify results (order may vary)
    local any_result, all_settled_result = nil, nil
    for _, res in ipairs(results) do
        if type(res.result) ~= "table" or (type(res.result) == "table" and res.result[1] and res.result[1].status) then
            -- This is AllSettled result (contains status objects)
            all_settled_result = res.result
        else
            -- This is Any result (single value)
            any_result = res.result
        end
    end
    
    assert_equal(any_result, "success")
    
    -- Check AllSettled results
    assert_equal(#all_settled_result, 3)
    assert_equal(all_settled_result[1].status, "rejected")
    assert_equal(all_settled_result[1].reason, "error1")
    assert_equal(all_settled_result[2].status, "fulfilled")
    assert_equal(all_settled_result[2].value, "success")
    assert_equal(all_settled_result[3].status, "rejected")
    assert_equal(all_settled_result[3].reason, "error2")
end)

-- Integration test 8: Deferred future with complex chaining
test("Deferred future with complex chaining", function()
    local executor = Future.FutureExecutor.new()
    
    local deferred, resolve, reject = Future.newDeferred()
    
    local complex_deferred = deferred
        :athen(function(val)
            return val .. " step1"
        end)
        :athen(function(val)
            return Future.delay(10, val .. " step2")
        end)
        :athen(function(val)
            return val .. " final"
        end)
        :catch(function(err)
            return "error: " .. err
        end)
    
    -- Resolve after a small delay to simulate async operation
    local timer = Future.delay(5, "initial_value")
    timer:athen(function()
        resolve("resolved_value")
    end)
    
    executor:spawn(complex_deferred)
    executor:spawn(timer)
    local _, results = executor:run_until_complete()
    
    -- Find the complex_deferred result
    local final_result = nil
    for _, res in ipairs(results) do
        if res.result and string.find(res.result, "final") then
            final_result = res.result
            break
        end
    end
    
    assert_equal(final_result, "resolved_value step1 step2 final")
end)

print("\n=== Integration Test Results ===")
print("Passed: " .. pass_count .. "/" .. test_count)

if pass_count == test_count then
    print("All integration tests passed! ✓")
else
    print("Some integration tests failed! ✗")
    os.exit(1)
end
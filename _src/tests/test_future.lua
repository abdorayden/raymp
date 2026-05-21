-- Unit tests for the Future library
local Future = require("rmp.future")
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

local function assert_false(condition, msg)
    msg = msg or "Condition should be false"
    if condition then
        error(msg)
    end
end

print("=== Running Future Library Unit Tests ===\n")

-- Test ValueFuture
test("ValueFuture creation and polling", function()
    local future = Future.value("test_value")
    local status, value = future:poll()
    assert_equal(status, Future.READY)
    assert_equal(value, "test_value")
    assert_true(future:is_ready())
end)

-- Test ErrorFuture
test("ErrorFuture creation and polling", function()
    local future = Future.error("test_error")
    local status, error_msg = future:poll()
    assert_equal(status, Future.ERROR)
    assert_equal(error_msg, "test_error")
end)

-- Test TimerFuture
test("TimerFuture creation and polling", function()
    local future = Future.delay(10, "delayed_value")  -- 10ms delay
    local status, _ = future:poll()
    assert_equal(status, Future.PENDING)
    
    -- Wait for the timer to complete
    local start = os.clock()
    while os.clock() - start < 0.1 do  -- Wait up to 100ms
        local status, value = future:poll()
        if status == Future.READY then
            assert_equal(value, "delayed_value")
            return  -- Test passed
        end
    end
    
    error("TimerFuture did not resolve in time")
end)

-- Test FutureExecutor
test("FutureExecutor basic functionality", function()
    local executor = Future.FutureExecutor.new()
    local future = Future.value("exec_test")
    executor:spawn(future)
    
    local success, results = executor:run_until_complete()
    assert_true(success)
    assert_equal(#results, 1)
    assert_equal(results[1].status, Future.READY)
    assert_equal(results[1].result, "exec_test")
end)

-- Test :athen chaining
test(":athen chaining with ValueFuture", function()
    local executor = Future.FutureExecutor.new()
    
    local chained = Future.value(5)
        :athen(function(x)
            return x * 2
        end)
        :athen(function(x)
            return x + 10
        end)
    
    executor:spawn(chained)
    local _, results = executor:run_until_complete()
    
    assert_equal(results[1].result, 20)  -- (5 * 2) + 10 = 20
end)

-- Test :catch error handling
test(":catch error handling", function()
    local executor = Future.FutureExecutor.new()
    
    local error_handled = Future.error("original_error")
        :athen(function(x)
            return "should_not_execute"
        end)
        :catch(function(err)
            return "handled: " .. err
        end)
    
    executor:spawn(error_handled)
    local _, results = executor:run_until_complete()
    
    assert_equal(results[1].result, "handled: original_error")
end)

-- Test AllFuture
test("AllFuture with multiple futures", function()
    local executor = Future.FutureExecutor.new()
    
    local all_future = Future.all({
        Future.value("first"),
        Future.delay(50, "second"),
        Future.value("third")
    })
    
    executor:spawn(all_future)
    local _, results = executor:run_until_complete()
    
    assert_equal(#results[1].result, 3)
    assert_equal(results[1].result[1], "first")
    assert_equal(results[1].result[2], "second")
    assert_equal(results[1].result[3], "third")
end)

-- Test RaceFuture
test("RaceFuture with multiple futures", function()
    local executor = Future.FutureExecutor.new()
    
    local race_future = Future.race({
        Future.delay(100, "slow"),
        Future.delay(10, "fast"),
        Future.value("instant")
    })
    
    executor:spawn(race_future)
    local _, results = executor:run_until_complete()
    
    -- Should return the first completed future (instant)
    assert_equal(results[1].result, "instant")
end)

-- Test error propagation in AllFuture
test("AllFuture error propagation", function()
    local executor = Future.FutureExecutor.new()
    
    local all_future = Future.all({
        Future.value("first"),
        Future.error("error_occurred"),
        Future.value("third")
    })
    
    executor:spawn(all_future)
    local success, results = executor:run_until_complete()
    
    -- AllFuture should fail if any future fails
    assert_equal(results[1].status, Future.ERROR)
end)

-- Test the finally method
test(":finally method", function()
    local executor = Future.FutureExecutor.new()
    local finally_called = false
    
    local future_with_finally = Future.value("test")
        :finally(function()
            finally_called = true
        end)
    
    executor:spawn(future_with_finally)
    local _, results = executor:run_until_complete()
    
    assert_true(finally_called, "Finally callback should be called")
    assert_equal(results[1].result, "test")
end)

-- Test AnyFuture
test("AnyFuture functionality", function()
    local executor = Future.FutureExecutor.new()
    
    local any_future = Future.any({
        Future.error("error1"),
        Future.delay(10, "success"),
        Future.error("error2")
    })
    
    executor:spawn(any_future)
    local _, results = executor:run_until_complete()
    
    -- Should return the first successful future
    assert_equal(results[1].result, "success")
end)

-- Test AllSettledFuture
test("AllSettledFuture functionality", function()
    local executor = Future.FutureExecutor.new()
    
    local all_settled_future = Future.allSettled({
        Future.value("success1"),
        Future.error("error_occurred"),
        Future.value("success2")
    })
    
    executor:spawn(all_settled_future)
    local _, results = executor:run_until_complete()
    
    local result_table = results[1].result
    assert_equal(#result_table, 3)
    assert_equal(result_table[1].status, "fulfilled")
    assert_equal(result_table[1].value, "success1")
    assert_equal(result_table[2].status, "rejected")
    assert_equal(result_table[2].reason, "error_occurred")
    assert_equal(result_table[3].status, "fulfilled")
    assert_equal(result_table[3].value, "success2")
end)

-- Test DeferredFuture
test("DeferredFuture functionality", function()
    local executor = Future.FutureExecutor.new()
    
    local deferred, resolve, reject = Future.newDeferred()
    
    -- Resolve the deferred future
    resolve("deferred_value")
    
    executor:spawn(deferred)
    local _, results = executor:run_until_complete()
    
    assert_equal(results[1].result, "deferred_value")
end)

print("\n=== Test Results ===")
print("Passed: " .. pass_count .. "/" .. test_count)

if pass_count == test_count then
    print("All tests passed! ✓")
else
    print("Some tests failed! ✗")
    os.exit(1)
end
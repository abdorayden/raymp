-- Advanced features example for the Future library
local Future = require("rmp.future")

print("=== Advanced Features Example ===")

-- Demonstrate 'finally' functionality
local executor = Future.FutureExecutor.new()

local future_with_finally = Future.delay(500, "Success")
    :tthen(function(value)
        print("Processing value:", value)
        return value .. " processed"
    end)

executor:spawn(future_with_finally)
local _, results = executor:run_until_complete()

print("Result with finally:", results[1].result)
print()


-- Demonstrate 'any' functionality
print("--- Any Future Example ---")
local any_executor = Future.FutureExecutor.new()

local any_future = Future.any({
    Future.delay(1000, "Slow"),
    Future.error("Fast error 1"),
    Future.error("Fast error 2")
})

any_executor:spawn(any_future)
local success, results_any = any_executor:run_until_complete()

if success then
    print("Any result:", results_any[1].result)
else
    print("Any failed:", results_any)
end
print()


-- Demonstrate 'allSettled' functionality
print("--- AllSettled Future Example ---")
local all_settled_executor = Future.FutureExecutor.new()

local all_settled_future = Future.allSettled({
    Future.delay(500, "Success 1"),
    Future.error("Error in future 2"),
    Future.value("Success 3")
})

all_settled_executor:spawn(all_settled_future)
local _, results_settled = all_settled_executor:run_until_complete()

for i, result in ipairs(results_settled[1].result) do
    if result.status == "fulfilled" then
        print("Future " .. i .. " fulfilled with value:", result.value)
    else
        print("Future " .. i .. " rejected with reason:", result.reason)
    end
end
print()


-- Demonstrate deferred future
print("--- Deferred Future Example ---")
local deferred_executor = Future.FutureExecutor.new()

local deferred_future, resolve, reject = Future.newDeferred()

local deferred_chain = deferred_future
    :tthen(function(value)
        print("Deferred resolved with:", value)
        return "Processed: " .. value
    end)
    :catch(function(err)
        print("Deferred rejected with:", err)
        return "Error handled: " .. err
    end)

deferred_executor:spawn(deferred_chain)

-- Resolve the deferred future after a short delay
local timer = Future.delay(300, "Ready")
timer:tthen(function()
    resolve("Deferred value")
end)

deferred_executor:spawn(timer)
local _, deferred_results = deferred_executor:run_until_complete()

-- print("Deferred final result:", deferred_results[1].result)
print()


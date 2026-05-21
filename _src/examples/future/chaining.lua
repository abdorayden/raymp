-- Chaining example for the Future library
local Future = require("rmp.future")

print("=== Chaining Example ===")

local executor = Future.FutureExecutor.new()

local chained_future = Future.delay(500, 10)
    :tthen(function(val)
        print("Step 1 (after 500ms):", val)
        return Future.delay(500, val * 2) -- Return a new future
    end)
    :tthen(function(val)
        print("Step 2 (after 1000ms):", val)
        return val + 5
    end)

executor:spawn(chained_future)
local _, results = executor:run_until_complete()

print("Final result of chain:", results[1].result)
print()


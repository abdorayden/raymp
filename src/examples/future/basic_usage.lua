-- Basic usage example for the Future library
local Future = require("rmp.future")

print("=== Basic Usage Example ===")

local executor = Future.FutureExecutor.new()

-- Create a future that will be ready with the value "Hello" after 2 seconds.
local my_future = Future.delay(1000, "Hello")

-- Chain another operation to be executed when the first future is ready.
local then_future = my_future:tthen(function(value)
    print(value .. ", World!")
    return value .. ", World!"
end)

executor:spawn(then_future)
local _, results = executor:run_until_complete()

print("Final result:", results[1].result)
print()


-- Error handling example for the Future library
local Future = require("rmp.future")

print("=== Error Handling Example ===")

local executor = Future.FutureExecutor.new()

local error_future = Future.error("Something went wrong!")

local catch_future = error_future:tthen(function(value)
    print("This will not be printed.")
    return "Success"
end):catch(function(err)
    print("Caught an error: " .. err)
    return "Recovered"
end)

executor:spawn(catch_future)
local _, results = executor:run_until_complete()

print("Final result:", results[1].result)
print()


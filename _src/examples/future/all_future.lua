-- AllFuture example for the Future library
local Future = require("rmp.future")

print("=== All Future Example ===")

local executor = Future.FutureExecutor.new()

local all_future = Future.all({
    Future.delay(1000, "First"),
    Future.delay(500, "Second"),
    Future.value("Third")
})

executor:spawn(all_future)
local _, results = executor:run_until_complete()

-- The results table preserves the order of the input futures.
for i, res in ipairs(results[1].result) do
    print("AllFuture Result " .. i .. ":", res)
end
print()
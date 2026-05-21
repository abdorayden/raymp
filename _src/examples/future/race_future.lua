-- RaceFuture example for the Future library
local Future = require("rmp.future")

print("=== Race Future Example ===")

local executor = Future.FutureExecutor.new()

local race_future = Future.race({
    Future.delay(2000, "Too slow"),
    Future.delay(500, "I am the winner!"),
    Future.delay(1000, "Also too slow")
})

executor:spawn(race_future)
local _, results = executor:run_until_complete()

print("Race winner:", results[1].result)
print()
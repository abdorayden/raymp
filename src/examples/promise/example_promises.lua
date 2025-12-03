-- To run this example, you would typically execute the main application file
-- that loads and runs this script, for example, by calling `lua main.lua`
-- from your terminal, assuming `main.lua` is properly configured to run
-- the promises example. Since the execution context may vary, this example
-- focuses on demonstrating the promise functionalities rather than on a specific
-- execution command.

local Promise = require("rmp.promises")

-- A mock function to simulate an asynchronous operation
local function mockAsyncTask(name, delay, shouldReject, value)
    print(string.format("[Task %s] Starting...", name))
    return Promise.new(function(resolve, reject)
        Promise.timeout(delay):tthen(function()
            if shouldReject then
                print(string.format("[Task %s] Rejected after %dms.", name, delay))
                reject(string.format("Error in %s", name))
            else
                print(string.format("[Task %s] Resolved after %dms.", name, delay))
                resolve(value or string.format("Success from %s", name))
            end
        end)
    end)
end

-- Example 1: Basic Promise with .then, .catch, and .finally
local function runBasicExample()
    print("\n--- Running Basic Example ---")
    return mockAsyncTask("Basic", 1000, false, "Hello, Promises!")
        :tthen(function(result)
            print("Success:", result)
            return "Returned from .then"
        end)
        :tthen(function(result)
            print("Chained .then:", result)
        end)
        :catch(function(err)
            print("Error:", err)
        end)
        :finally(function()
            print("Finally block executed.")
        end)
end

-- Example 2: Promise.all - waiting for all promises to resolve
local function runAllExample()
    print("\n--- Running Promise.all Example ---")
    local promises = {
        mockAsyncTask("All-1", 500, false),
        mockAsyncTask("All-2", 1500, false),
        mockAsyncTask("All-3", 1000, false)
    }

    return Promise.all(promises)
        :tthen(function(results)
            print("Promise.all success! Results:")
            for i, res in ipairs(results) do
                print(string.format("  [%d]: %s", i, res))
            end
        end)
        :catch(function(err)
            print("Promise.all rejected!", err)
        end)
end

-- Example 3: Promise.race - getting the result of the first settled promise
local function runRaceExample()
    print("\n--- Running Promise.race Example ---")
    local promises = {
        mockAsyncTask("Race-1", 1000, false),
        mockAsyncTask("Race-2", 500, false),
        mockAsyncTask("Race-3", 1500, false)
    }

    return Promise.race(promises)
        :tthen(function(winner)
            print("Promise.race success! Winner:", winner)
        end)
        :catch(function(err)
            print("Promise.race rejected!", err)
        end)
end

-- Example 4: Async/Await pattern
local asyncTask = Promise.async(function()
    print("\n--- Running Async/Await Example ---")

    print("Await Start: Waiting for task 'Async-1'...")
    local result1 = Promise.await(mockAsyncTask("Async-1", 1000, false))
    print("Await Success: 'Async-1' returned:", result1)

    print("Await Start: Waiting for task 'Async-2'...")
    local result2 = Promise.await(mockAsyncTask("Async-2", 1000, false, "Custom Value"))
    print("Await Success: 'Async-2' returned:", result2)

    return "All async tasks complete!"
end)

-- Main execution
local main = Promise.async(function()
    Promise.await(runBasicExample())
    Promise.await(runAllExample())
    Promise.await(runRaceExample())

    local finalResult = Promise.await(asyncTask())
    print(finalResult)
end)

main():tthen(function()
    print("\nAll examples finished.")
end)

-- Start the promise event loop
Promise.run()

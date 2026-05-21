-- A very basic example of a promise
local Promise = require("rmp.promises")

print("=== Basic Promise Example ===")

-- This function simulates an async operation that might succeed or fail
local function simpleAsyncTask(shouldSucceed)
    return Promise.new(function(resolve, reject)
        print("Starting simple async task...")
        -- Simulate a delay
        Promise.timeout(1000):tthen(function()
            if shouldSucceed then
                -- If the operation is successful, resolve the promise
                print("Async task succeeded!")
                resolve("Here is the successful result.")
            else
                -- If the operation fails, reject the promise
                print("Async task failed!")
                reject("Something went wrong.")
            end
        end)
    end)
end

-- Example 1: A promise that resolves successfully
print("\n--- Running a successful promise ---")
local successPromise = simpleAsyncTask(true)

successPromise:tthen(function(result)
    -- This block runs when the promise is resolved
    print("Success handler received:", result)
end):catch(function(err)
    -- This block runs if the promise is rejected
    print("Error handler received:", err)
end)

-- Example 2: A promise that fails (is rejected)
print("\n--- Running a failing promise ---")
local failurePromise = simpleAsyncTask(false)

failurePromise:tthen(function(result)
    print("Success handler received:", result)
end):catch(function(err)
    print("Error handler received:", err)
end)

-- Example 3: Chaining promises
print("\n--- Running a chained promise ---")
simpleAsyncTask(true)
    :tthen(function(result1)
        print("First promise succeeded with:", result1)
        -- Start another async task after the first one completes
        return simpleAsyncTask(true)
    end)
    :tthen(function(result2)
        print("Second promise succeeded with:", result2)
        print("Chaining complete!")
    end)
    :catch(function(err)
        print("A promise in the chain failed:", err)
    end)


-- The Promise.run() function starts the event loop that manages the promises.
-- Without this, the async operations would never complete.
print("\nStarting promise event loop...")
Promise.run()
print("Promise event loop finished.")

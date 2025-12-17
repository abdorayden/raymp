-- An example of a real-world async operation: reading files using Promises.
local Promise = require("rmp.promises")
local os = require("os")

print("=== Async File Reader Example ===")

---
-- Reads a file asynchronously and returns a promise.
-- To better simulate a real-world scenario, this function introduces a
-- random delay. This makes the non-blocking, concurrent execution visible,
-- as different file reads will complete in a different order than they were started.
--
-- @param filename (string) The name of the file to read.
-- @return (Promise) A promise that resolves with the file content or rejects with an error.
---
local function readFileAsync(filename)
    -- Simulate variable I/O latency to make concurrency obvious
    local simulatedDelay = math.random(20, 100)
    print(string.format("[Task %s] Starting to read file... (simulated latency: %dms)", filename, simulatedDelay))

    return Promise.new(function(resolve, reject)
        -- Yield control to the promise scheduler for the simulated duration.
        Promise.timeout(simulatedDelay):tthen(function()
            -- The actual file I/O is blocking, but it runs after the async delay.
            local file, err = io.open(filename, "r")
            if not file then
                print(string.format("[Task %s] Failed to open file.", filename))
                return reject(string.format("Error opening %s: %s", filename, err))
            end

            local content = file:read("*a")
            file:close()
            print(string.format("[Task %s] Successfully read file.", filename))
            resolve(content)
        end)
    end)
end

-- Main execution logic wrapped in an async function
local main = Promise.async(function()
    -- Seeding the random number generator to ensure different output on each run
    math.randomseed(os.time())

    -- print("\n--- 1. Reading a single file successfully ---")
    -- local content1 = Promise.await(readFileAsync("test_file_1.txt"))
    -- print("File 1 Content:\n" .. content1)

    -- print("\n--- 2. Attempting to read a file that does not exist ---")
    -- -- We use a pcall-like approach to catch the expected error
    -- local status, err = pcall(function()
    --     Promise.await(readFileAsync("non_existent_file.txt"))
    -- end)
    -- if not status then
    --     print("Caught expected error: " .. tostring(err))
    -- end

    print("\n--- 3. Reading multiple files concurrently with Promise.all ---")
    print("Starting both reads at the same time. Notice how they can finish in any order.")
    local filesToRead = { "test_file_1.txt", "test_file_2.txt",
        "example_async_file_reader.lua", "example_async_oop.lua"
    }

    local promises = {}
    -- Correctly create a list of promises
    for _, filename in ipairs(filesToRead) do
        table.insert(promises, readFileAsync(filename))
    end

    local allContents = Promise.await(Promise.all(promises))
    print("\nAll files read successfully!")
    for i, content in ipairs(allContents) do
        print(string.format('\n--- Content of %s ---\n%s', filesToRead[i], content))
    end

    print("\n--- All file operations completed. ---")
end)

main():tthen(function()
    print("\nMain async function finished successfully.")
end):catch(function(err)
    print("\nAn unexpected error occurred in main: " .. tostring(err))
end):finally(function()
    -- Clean up the temporary files
    -- print("\nCleaning up temporary files...")
    -- os.remove("test_file_1.txt")
    -- os.remove("test_file_2.txt")
    -- print("Cleanup complete.")
end)

-- Start the promise event loop to run all the async tasks
Promise.run()

print("\nEvent loop has finished.")

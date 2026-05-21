-- Advanced examples of simulated non-blocking tasks using Promises
local Promise = require("rmp.promises")
local os = require("os")

print("=== Advanced Async Operations Example ===")

---
-- Simulates fetching a URL asynchronously.
-- @param url (string) The URL to "fetch".
-- @return (Promise) A promise that resolves with the fetched content.
---
local function fetchURLAsync(url)
    local simulatedLatency = math.random(50, 200)
    print(string.format("[Network] Fetching %s (will take %dms)...", url, simulatedLatency))
    return Promise.new(function(resolve)
        Promise.timeout(simulatedLatency):tthen(function()
            local fakeContent = string.format('{"url": "%s", "data": "some dummy content"}', url)
            print(string.format("[Network] Finished fetching %s.", url))
            resolve(fakeContent)
        end)
    end)
end

---
-- Lists the contents of a directory asynchronously.
-- Note: This uses `io.popen('ls -F ...')`, which is not truly non-blocking.
-- We simulate the async behavior with a timeout, as with other examples.
-- The '-F' flag helps distinguish directories (e.g., "subdir/") from files.
-- @param path (string) The directory path to list.
-- @return (Promise) A promise that resolves with a table of contents or rejects on error.
---
local function listDirectoryAsync(path)
    local simulatedLatency = math.random(20, 80)
    print(string.format("[FS] Listing dir '%s' (latency: %dms)...", path, simulatedLatency))
    return Promise.new(function(resolve, reject)
        Promise.timeout(simulatedLatency):tthen(function()
            -- Using `ls -F` to easily identify directories (they end with '/')
            local f = io.popen("ls -F '" .. path .. "'")
            if not f then
                return reject("Failed to execute 'ls' command for path: " .. path)
            end

            local contents = {}
            for line in f:lines() do
                table.insert(contents, line)
            end
            f:close()
            resolve(contents)
        end)
    end)
end

---
-- Recursively scans a directory structure asynchronously.
-- This is a powerful example of composing promises.
-- @param path (string) The root directory path to start scanning from.
-- @return (Promise) A promise that resolves with a flat list of all found files and directories.
-- ---
function scanDirectoryRecursiveAsync(path)
    return Promise.async(function()
        -- First, get the contents of the current directory
        local items = Promise.await(listDirectoryAsync(path))
        local allResults = { path } -- Add the current path to the results

        local subDirPromises = {}
        for _, item in ipairs(items) do
            local fullItemPath = path .. "/" .. item
            -- Check if the item is a directory by looking for the trailing '/' from `ls -F`
            if item:sub(-1) == "/" then
                -- It's a directory, so we start another recursive scan.
                -- We DON'T await here. We collect all the promises and run them concurrently.
                local cleanPath = fullItemPath:sub(1, -2) -- Remove trailing '/'
                print(string.format("[Scanner] Found subdirectory '%s', queueing for recursive scan.", cleanPath))
                table.insert(subDirPromises, scanDirectoryRecursiveAsync(cleanPath))
            else
                -- It's a file, just add it to the results
                table.insert(allResults, fullItemPath)
            end
        end

        -- If we found any subdirectories, wait for all of their scans to complete
        if #subDirPromises > 0 then
            print(string.format("[Scanner] Waiting for %d subdirectory scan(s) to complete...", #subDirPromises))
            local subDirResults = Promise.await(Promise.all(subDirPromises))
            -- The results from Promise.all will be a table of tables, so we flatten them
            for _, resultGroup in ipairs(subDirResults) do
                for _, singleResult in ipairs(resultGroup) do
                    table.insert(allResults, singleResult)
                end
            end
        end

        return allResults
    end)()
end

-- Main execution logic
local main = Promise.async(function()
    math.randomseed(os.time())

    print("\n--- 1. Simulating Concurrent Network Requests ---")
    local urls = { "http://api.example.com/data", "http://api.google.com/info" }
    local networkPromises = {}
    for _, url in ipairs(urls) do
        table.insert(networkPromises, fetchURLAsync(url))
    end
    local responses = Promise.await(Promise.all(networkPromises))
    print("\nAll network requests finished:")
    for i, res in ipairs(responses) do
        print(string.format("  Response %d: %s", i, res))
    end


    print("\n--- 2. Simple Asynchronous Directory Listing ---")
    local currentDirItems = Promise.await(listDirectoryAsync("."))
    print("\nContents of current directory ('.'):")
    for _, item in ipairs(currentDirItems) do
        io.write("  " .. item)
    end
    print("\n")


    print("\n--- 3. Advanced Recursive Directory Scan ---")
    print("Starting scan of 'temp_scan_dir'. Note the interleaved log messages showing concurrency.")
    local allFiles = Promise.await(scanDirectoryRecursiveAsync("temp_scan_dir"))
    print("\nRecursive scan complete! All found paths:")
    for _, path in ipairs(allFiles) do
        print("  - " .. path)
    end

    print("\n--- All advanced examples completed. ---")
end)

main():tthen(function()
    print("\nMain async function finished successfully.")
end):catch(function(err)
    print("\nAn unexpected error occurred in main: " .. tostring(err))
end):finally(function()
    -- Clean up the temporary directory
    -- print("\nCleaning up temporary directory structure...")
    -- os.execute("rm -rf temp_scan_dir")
    -- print("Cleanup complete.")
end)

-- Start the promise event loop
Promise.run()
print("\nEvent loop has finished.")

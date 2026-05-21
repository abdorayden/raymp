-- Example demonstrating async functions inside classes using the Promise library
local Promise = require("rmp.promises")
local OOP = require("rmp.oop")

print("=== Async Functions in OOP Example ===")

-- A mock function to simulate an asynchronous operation
local function mockAsyncTask(name, delay, shouldReject, value)
    print(string.format("[Async Task %s] Starting...", name))
    return Promise.new(function(resolve, reject)
        Promise.timeout(delay):tthen(function()
            if shouldReject then
                print(string.format("[Async Task %s] Rejected after %dms.", name, delay))
                reject(string.format("Error in %s", name))
            else
                print(string.format("[Async Task %s] Resolved after %dms with value: %s", name, delay,
                    tostring(value or "default")))
                resolve(value or string.format("Success from %s", name))
            end
        end)
    end)
end

-- Example 1: Class with async methods
local DataService = OOP.class("DataService")
do
    function DataService:constructor()
        self.data = {}
    end

    -- Regular synchronous method
    function DataService:syncMethod()
        return "Sync result: Current data count is " .. #self.data
    end

    -- Async method using Promise:tthen
    function DataService:asyncFetchUserData(userId)
        print("Starting async fetch for user: " .. userId)
        return mockAsyncTask("FetchUser-" .. userId, 800, false,
                { id = userId, name = "User " .. userId, email = "user" .. userId .. "@example.com" })
            :tthen(function(userData)
                print("Received user data: " .. userData.name)
                table.insert(self.data, userData)
                return userData
            end)
            :catch(function(err)
                print("Error fetching user data: " .. err)
                return nil
            end)
    end

    -- Another async method
    function DataService:asyncSaveData(data)
        print("Starting async save for data with id: " .. (data.id or "unknown"))
        return mockAsyncTask("SaveData-" .. (data.id or "unknown"), 500, false, "Saved successfully")
            :tthen(function(result)
                print("Data saved: " .. result)
                return result
            end)
            :catch(function(err)
                print("Error saving data: " .. err)
                return nil
            end)
    end

    -- Complex async method that chains multiple async operations
    function DataService:asyncProcessUser(userId)
        print("Processing user: " .. userId)
        return self:asyncFetchUserData(userId)
            :tthen(function(userData)
                if userData then
                    return self:asyncSaveData(userData)
                        :tthen(function(saveResult)
                            print("User " .. userId .. " processed successfully")
                            return { user = userData, saveResult = saveResult }
                        end)
                else
                    print("Could not process user " .. userId .. ", fetch failed")
                    return nil
                end
            end)
            :catch(function(err)
                print("Error processing user " .. userId .. ": " .. err)
                return nil
            end)
    end
end

-- Example 2: Using async/await pattern inside class methods
local APIService = OOP.class("APIService")
do
    function APIService:constructor(baseURL)
        self.baseURL = baseURL or "http://api.example.com"
        self.sessionToken = nil
    end

    -- Async method using the async/await pattern
    function APIService:login(username, password)
        return Promise.async(function()
            print("Attempting to login user: " .. username)

            -- Simulate async API call to get token
            local authResult = Promise.await(mockAsyncTask("Login-" .. username, 1000, false,
                { token = "token_" .. username, userId = 123 }))

            if authResult and authResult.token then
                self.sessionToken = authResult.token
                print("Login successful for user: " .. username .. ", token: " .. self.sessionToken)
                return authResult
            else
                print("Login failed for user: " .. username)
                return nil
            end
        end)()
    end

    -- Another async method using async/await
    function APIService:fetchData(endpoint)
        return Promise.async(function()
            if not self.sessionToken then
                error("No session token available. Please login first.")
            end

            print("Fetching data from: " .. endpoint .. " using token: " .. self.sessionToken)

            -- Simulate async API call
            local result = Promise.await(mockAsyncTask("Fetch-" .. endpoint, 700, false,
                { endpoint = endpoint, data = "some important data", timestamp = os.time() }))

            return result
        end)()
    end
end

-- Example 3: Async methods in a regular function table (not using OOP)
local AsyncUtils = {}

-- FIX: Async function should not take 'self' as first parameter when used as standalone function
function AsyncUtils.processListAsync(items, delayPerItem)
    return Promise.async(function()
        delayPerItem = delayPerItem or 300
        local results = {}

        print("Processing " .. #items .. " items asynchronously")

        for i, item in ipairs(items) do
            print("Processing item " .. i .. ": " .. tostring(item))
            local result = Promise.await(mockAsyncTask("ProcessItem-" .. i, delayPerItem, false,
                "Processed: " .. tostring(item)))
            table.insert(results, result)
        end

        print("All items processed")
        return results
    end)()
end

-- FIX: Another async utility function without self parameter
function AsyncUtils.delayedOperation(operationName, delay)
    return Promise.async(function()
        print("Starting delayed operation: " .. operationName)
        -- Wait for the specified delay
        Promise.await(Promise.timeout(delay))
        print("Completed delayed operation: " .. operationName)
        return "Completed: " .. operationName
    end)()
end

-- Main execution to demonstrate all async OOP patterns
local main = Promise.async(function()
    print("\n--- Test 1: DataService with Promises ---")
    local dataService = DataService.new()

    local result1 = Promise.await(dataService:asyncProcessUser("001"))
    if result1 and result1.user then
        print("Process result 1: " .. result1.user.name)
    else
        print("Process result 1: nil")
    end

    local result2 = Promise.await(dataService:asyncProcessUser("002"))
    if result2 and result2.user then
        print("Process result 2: " .. result2.user.name)
    else
        print("Process result 2: nil")
    end

    print("\nSync method result: " .. dataService:syncMethod())

    print("\n--- Test 2: APIService with async/await ---")
    local apiService = APIService.new("https://api.example.com")

    local auth = Promise.await(apiService:login("john_doe", "password123"))
    if auth then
        local userData = Promise.await(apiService:fetchData("/users/123"))
        print("Fetched user data: " .. userData.endpoint)
    end

    print("\n--- Test 3: Async functions in table ---")
    -- FIX: Call without passing self parameter
    local listResults = Promise.await(AsyncUtils.processListAsync({ "item1", "item2", "item3" }, 400))
    for i, result in ipairs(listResults) do
        print("List result " .. i .. ": " .. result)
    end

    -- FIX: Call without passing self parameter
    local delayedResult = Promise.await(AsyncUtils.delayedOperation("Database Backup", 1200))
    print("Delayed operation result: " .. delayedResult)

    print("\n--- All async OOP examples completed successfully! ---")
end)

-- Run the main async function
main():tthen(function()
    print("\nAll async operations finished.")
end):catch(function(err)
    print("\nError in main: " .. tostring(err))
end)

-- Start the promise event loop
Promise.run()

-- Simple examples of async functions in classes and function tables
local Promise = require("rmp.promises")
local OOP = require("rmp.oop")

local async = Promise.async
local await = Promise.await

print("=== Simple Async OOP Patterns ===")

-- A helper function to simulate async operations
local function delay(ms, result)
    return Promise.new(function(resolve)
        Promise.timeout(ms):tthen(function()
            resolve(result or "Operation completed")
        end)
    end)
end

-- Pattern 1: Using Promise chains directly in class methods
local APIClient = OOP.class("APIClient")
do
    function APIClient:constructor(baseURL)
        self.baseURL = baseURL or "http://localhost"
        self.isConnected = false
    end

    -- Async method using Promise chain
    function APIClient:connectAsync()
        print("Connecting to: " .. self.baseURL)
        return delay(500, true)
            :tthen(function(result)
                self.isConnected = result
                print("Connected to API")
                return "Connection successful"
            end)
            :catch(function(err)
                print("Connection failed: " .. tostring(err))
                return nil
            end)
    end

    function APIClient:getUserAsync(userId)
        if not self.isConnected then
            return Promise.reject("Client not connected")
        end

        print("Fetching user: " .. userId)
        return delay(800, { id = userId, name = "User " .. userId, email = "user" .. userId .. "@example.com" })
            :tthen(function(userData)
                print("Received user data for: " .. userData.name)
                return userData
            end)
    end
end

-- Pattern 2: Using async/await pattern by wrapping method in Promise.async
local DatabaseService = OOP.class("DatabaseService")
do
    function DatabaseService:constructor(name)
        self.name = name
        self.isConnected = false
    end

    -- Async method using async/await syntax
    function DatabaseService:initializeAsync()
        return async(function()
            print("Initializing database: " .. self.name)
            -- Simulate async connection setup
            local connectionResult = await(delay(600, { status = "connected", db = self.name }))

            self.isConnected = connectionResult.status == "connected"
            print("Database " .. self.name .. " initialized")

            -- Simulate async schema setup
            local schemaResult = await(delay(400, "Schema created"))
            print(schemaResult)

            return { db = self.name, connected = self.isConnected, schema = schemaResult }
        end)()
    end

    function DatabaseService:queryAsync(sql)
        return async(function()
            if not self.isConnected then
                error("Database not connected")
            end

            print("Executing query: " .. sql)
            -- Simulate async query execution
            local result = await(delay(1000, { rows = 5, columns = { "id", "name", "email" } }))
            print("Query completed with " .. result.rows .. " rows")

            return result
        end)()
    end
end

-- Pattern 3: Async functions in a regular table (not using OOP)
local AsyncHelpers = {}

-- FIX: Don't include 'self' parameter in standalone async functions
function AsyncHelpers.fetchMultiple(urls)
    return async(function()
        local results = {}
        for i, url in ipairs(urls) do
            print("Fetching: " .. url)
            -- Simulate async fetch operation
            local data = await(delay(300, { url = url, content = "Data from " .. url, index = i }))
            table.insert(results, data)
        end
        return results
    end)()
end

function AsyncHelpers.processWithDelay(data, delayMs)
    return async(function()
        print("Processing data with " .. delayMs .. "ms delay")
        -- Wait for the delay
        await(delay(delayMs))
        print("Processing completed for: " .. tostring(data))
        return "Processed: " .. tostring(data)
    end)()
end

-- Example usage
local main = async(function()
    print("--- Example 1: APIClient with Promise chains ---")
    local client = APIClient.new("https://api.example.com")

    local connectResult = await(client:connectAsync())
    print("Connect result: " .. tostring(connectResult))

    local user = await(client:getUserAsync("123"))
    if user then
        print("User name: " .. user.name)
    end

    print("\n--- Example 2: DatabaseService with async/await ---")
    local db = DatabaseService.new("MyAppDB")

    local initResult = await(db:initializeAsync())
    print("Init result: " .. initResult.db .. " connected: " .. tostring(initResult.connected))

    local queryResult = await(db:queryAsync("SELECT * FROM users"))
    print("Query result: " .. queryResult.rows .. " rows returned")

    print("\n--- Example 3: Async functions in table ---")
    local urls = { "https://api1.com", "https://api2.com", "https://api3.com" }
    -- FIX: Call without self parameter
    local results = await(AsyncHelpers.fetchMultiple(urls))

    for i, result in ipairs(results) do
        print("Result " .. i .. ": " .. result.content)
    end

    -- FIX: Call without self parameter
    local processData = await(AsyncHelpers.processWithDelay("Important Data", 700))
    print("Process result: " .. processData)

    print("\n--- All async OOP patterns working! ---")
end)

main():tthen(function()
    print("\nAsync OOP example completed successfully.")
end):catch(function(err)
    print("\nError in main: " .. tostring(err))
end)

-- Run the event loop
Promise.run()

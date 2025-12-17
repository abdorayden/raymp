-- An example of how to integrate the promise scheduler into an existing main loop.
-- This example has been updated to use the modern promise API.
local Promise = require("rmp.promises")
local os = require("os")

print("=== Manual Event Loop Integration Example ===")
print("This part shows how to call the promise runner manually from your own loop.")

---
-- This example demonstrates how to drive the promise event loop manually
-- within your own application's main loop (e.g., a game loop), instead of
-- using the blocking `Promise.run()` call.
--
-- The key function is `Promise.runner()`, which processes any pending
-- promise events for the current time slice and then returns, allowing
-- your loop to continue.
---

-- A mock async task to demonstrate with
local function mockAsyncTask(name, delay)
    print(string.format("[Task %s] Scheduled to resolve in %dms.", name, delay))
    return Promise.new(function(resolve)
        Promise.timeout(delay):tthen(function()
            print(string.format(">>> [Task %s] Resolved! <<<", name))
            resolve("Success from " .. name)
        end)
    end)
end


-- 1. Schedule some async tasks and get their promises
print("Scheduling two async tasks before starting the main loop...")
local p1 = mockAsyncTask("ShortTask", 1000)
local p2 = mockAsyncTask("LongTask", 3000)

-- 2. Your Application's Main Loop
print("\nStarting main application loop...\n")

local frame = 0
local quit = false

-- Use Promise.all to set the quit flag when all tasks are done.
Promise.all({p1, p2}):tthen(function()
    print("\nMain loop will exit because all promises have resolved.")
    quit = true
end)


local startTime = os.clock()

-- This loop simulates a game or application running.
while not quit do
    frame = frame + 1
    local elapsedTime = (os.clock() - startTime) * 1000

    -- Your application's logic would go here
    print(string.format("Main Loop Frame: %d (Elapsed: %.0fms)", frame, elapsedTime))

    -- -----------------------------------------------------------------------
    -- Here is the crucial part: manually step the promise event loop.
    -- `Promise.runner()` will process any immediately pending promise events
    -- without blocking.
    -- -----------------------------------------------------------------------
    Promise.runner()

    -- A hard limit to prevent an infinite loop in this example in case of issues
    if frame >= 500 then
        print("\nMain loop reached frame limit. Exiting.")
        quit = true
    end

    -- Simulate work being done in the main loop (e.g., to achieve ~10 FPS)
    if not quit then
        -- Busy-wait for 100ms. In a real application, you'd yield to the OS
        -- or use a non-blocking sleep.
        local target = os.clock() + 0.1
        while os.clock() < target do end
    end
end

print("\nApplication loop finished.")
print("Note how the 'Task Resolved' messages appeared as the main loop was running.")


------------------------------------------------------------------------------------------
print("\n\n=== Custom Scheduler Integration Example ===")
print("This part shows how to use Promise.setScheduler() with your own event loop.")

-- A simple event loop implementation
local MyEventLoop = { tasks = {} }
function MyEventLoop:schedule(ms, fn)
    print(string.format("[MyEventLoop] Scheduling task to run in %dms", ms))
    local t = os.clock() + (ms / 1000)
    table.insert(self.tasks, { time = t, cb = fn })
end

function MyEventLoop:run()
    -- Set the promise scheduler to our custom one
    local oldScheduler = Promise.getScheduler()
    Promise.setScheduler(function(ms, fn) self:schedule(ms, fn) end)
    print("\nCustom scheduler has been set.")

    -- Schedule async tasks. They will now use MyEventLoop's scheduler.
    mockAsyncTask("TaskA", 500)
    mockAsyncTask("TaskB", 1200)

    print("Starting MyEventLoop:run()...")
    while #self.tasks > 0 do
        local now = os.clock()
        local executed_on_this_tick = false
        for i = #self.tasks, 1, -1 do
            if now >= self.tasks[i].time then
                local task = table.remove(self.tasks, i)
                -- In a robust loop, you might wrap this in pcall
                task.cb()
                executed_on_this_tick = true
            end
        end

        -- In a real event loop, we would sleep if no tasks were executed
        if not executed_on_this_tick and #self.tasks > 0 then
            local target = os.clock() + 0.01
            while os.clock() < target do end
        end
    end
    print("MyEventLoop:run() finished.")

    -- Restore default scheduler
    Promise.setScheduler(oldScheduler)
    print("Default scheduler has been restored.")
end

-- Run the custom loop example
MyEventLoop:run()

print("\nCustom scheduler example finished.")
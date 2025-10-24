-- /*********************************************************************************************/
-- /*  Copyright (c) 2025 Ray Den 								*/
-- /*  												*/
-- /*  Permission is hereby granted, free of charge, to any person obtaining a copy 		*/
-- /*  of this software and associated documentation files (the "Software"), to deal 		*/
-- /*  in the Software without restriction, including without limitation the rights 		*/
-- /*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 		*/
-- /*  copies of the Software, and to permit persons to whom the Software is 			*/
-- /*  furnished to do so, subject to the following conditions: 				*/
-- /*  												*/
-- /*  The above copyright notice and this permission notice shall be included in 		*/
-- /*  all copies or substantial portions of the Software. 					*/
-- /*  												*/
-- /*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 		*/
-- /*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		*/
-- /*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 		*/
-- /*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 			*/
-- /*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 		*/
-- /*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 		*/
-- /*  THE SOFTWARE. 										*/
-- /*  												*/
-- /*********************************************************************************************/
--
--
--- `future.lua` - A Futures and Promises Library for Lua ---
--
-- This library provides a powerful and flexible implementation of the Futures/Promises pattern for managing asynchronous operations in Lua. It allows you to write cleaner, more maintainable, and non-blocking code when dealing with tasks that take time to complete, such as timers, I/O operations, or any long-running computation.
--
-- **Core Concepts:**
--
-- A **Future** is an object that represents the eventual result of an asynchronous operation. A Future can be in one of three states:
-- - **PENDING**: The operation is still in progress.
-- - **READY**: The operation has completed successfully, and the result is available.
-- - **ERROR**: The operation failed, and an error is available.
--
-- You can chain operations on Futures using the `:athen()` and `:catch()` methods, which are inspired by JavaScript Promises.
--
-- **Library Components:**
--
-- - **`Future`**: The base class for all future types. It provides the core interface (`:poll()`, `:is_ready()`, `:athen()`, `:catch()`).
-- - **`ValueFuture`**: A future that is immediately resolved with a given value.
-- - **`ErrorFuture`**: A future that is immediately rejected with a given error.
-- - **`TimerFuture`**: A future that resolves with a value after a specified delay in milliseconds.
-- - **`ThenFuture`**: A special future used internally by `:athen()` and `:catch()` to chain operations.
-- - **`AllFuture`**: A future that resolves when all futures in a given list have resolved. The result is a table of all the individual results.
-- - **`RaceFuture`**: A future that resolves or rejects as soon as one of the futures in a given list resolves or rejects.
-- - **`FutureExecutor`**: A simple executor to run one or more futures until they complete.
--
-- **Static Helper Functions:**
--
-- For convenience, the library provides several static methods on the `Future` object:
-- - `Future.value(value)`: Creates a new `ValueFuture`.
-- - `Future.error(err)`: Creates a new `ErrorFuture`.
-- - `Future.delay(ms, value)`: Creates a new `TimerFuture`.
-- - `Future.all(futures)`: Creates a new `AllFuture`.
-- - `Future.race(futures)`: Creates a new `RaceFuture`.
--
-- --- EXAMPLES ---
--
-- **1. Basic Usage with a Timer:**
--
-- local Future = require("rmp.future")
--
-- local executor = Future.FutureExecutor.new()
--
-- -- Create a future that will be ready with the value "Hello" after 2 seconds.
-- local my_future = Future.delay(2000, "Hello")
--
-- -- Chain another operation to be executed when the first future is ready.
-- local then_future = my_future:athen(function(value)
--     print(value .. ", World!")
--     return value .. ", World!"
-- end)
--
-- executor:spawn(then_future)
-- executor:run_until_complete()
--
-- -- The output will be: "Hello, World!" after a 2-second delay.
--
--
-- **2. Handling Errors with `:catch()`:**
--
-- local executor = Future.FutureExecutor.new()
--
-- local error_future = Future.error("Something went wrong!")
--
-- local catch_future = error_future:athen(function(value)
--     print("This will not be printed.")
--     return "Success"
-- end):catch(function(err)
--     print("Caught an error: " .. err)
--     return "Recovered"
-- end)
--
-- executor:spawn(catch_future)
-- local _, results = executor:run_until_complete()
--
-- print("Final result:", results[1].result)
--
-- -- Output:
-- -- Caught an error: Something went wrong!
-- -- Final result: Recovered
--
--
-- **3. Chaining Multiple Futures:**
--
-- local executor = Future.FutureExecutor.new()
--
-- local chained_future = Future.delay(1000, 10)
--     :athen(function(val)
--         print("Step 1:", val)
--         return Future.delay(1000, val * 2) -- Return a new future
--     end)
--     :athen(function(val)
--         print("Step 2:", val)
--         return val + 5
--     end)
--
-- executor:spawn(chained_future)
-- local _, results = executor:run_until_complete()
--
-- print("Final result of chain:", results[1].result)
--
-- -- Output:
-- -- (after 1s) Step 1: 10
-- -- (after 2s) Step 2: 20
-- -- Final result of chain: 25
--
--
-- **4. Using `Future.all()`:**
--
-- local executor = Future.FutureExecutor.new()
--
-- local all_future = Future.all({
--     Future.delay(1500, "First"),
--     Future.delay(1000, "Second"),
--     Future.value("Third")
-- })
--
-- executor:spawn(all_future)
-- local _, results = executor:run_until_complete()
--
-- -- The results table preserves the order of the input futures.
-- for i, res in ipairs(results[1].result) do
--     print("AllFuture Result " .. i .. ":", res)
-- end
--
-- -- Output (after ~1.5 seconds):
-- -- AllFuture Result 1: First
-- -- AllFuture Result 2: Second
-- -- AllFuture Result 3: Third
--
--
-- **5. Using `Future.race()`:**
--
-- local executor = Future.FutureExecutor.new()
--
-- local race_future = Future.race({
--     Future.delay(2000, "Too slow"),
--     Future.delay(500, "I am the winner!"),
--     Future.delay(1000, "Also too slow")
-- })
--
-- executor:spawn(race_future)
-- local _, results = executor:run_until_complete()
--
-- print("Race winner:", results[1].result)
--
-- -- Output (after ~0.5 seconds):
-- -- Race winner: I am the winner!

-- this is an Futures concept implemented in lua

local OOP = require("rmp.oop")


local IFuture = OOP.interface("IFuture", "poll")


-- base class
local Future = OOP.class("Future", nil, IFuture)
do
    Future.PENDING = "pending"
    Future.READY = "ready"
    Future.ERROR = "error"

    -- poll method is not implemented by default

    function Future:constructor()
        -- base future is abstract
        self._status = Future.PENDING
    end

    function Future:is_ready()
        local status, _ = self:poll()
        return status == Future.READY
    end

    function Future:athen(on_fulfilled, on_rejected)
        return ThenFuture.new(self, on_fulfilled, on_rejected)
    end

    function Future:catch(on_rejected)
        return self:athen(nil, on_rejected)
    end
end

local ValueFuture = OOP.class("ValueFuture", Future)
do
    function ValueFuture:constructor(value)
        self:super("constructor")
        self._value = value
        self._status = Future.READY
    end

    function ValueFuture:poll()
        return self._status, self._value
    end
end

local ErrorFuture = OOP.class("ErrorFuture", Future)
do
    function ErrorFuture:constructor(error)
        self:super("constructor")
        self._error = error
        self._status = Future.ERROR
    end

    function ErrorFuture:poll()
        return self._status, self._error
    end
end

local TimerFuture = OOP.class("TimerFuture", Future)
do
    function TimerFuture:constructor(delay_ms, value)
        self:super("constructor")
        self._delay_ms = delay_ms
        self._value = value
        self._start_time = os.clock()
        self._status = Future.PENDING
    end

    function TimerFuture:poll()
        if self._status ~= Future.PENDING then
            return self._status, self._value
        end

        local elapsed = (os.clock() - self._start_time) * 1000
        if elapsed >= self._delay_ms then
            self._status = Future.READY
            return Future.READY, self._value
        else
            return Future.PENDING
        end
    end
end

ThenFuture = OOP.class("ThenFuture", Future)

function ThenFuture:constructor(future, on_fulfilled, on_rejected)
    self:super("constructor")
    self._future = future
    self._on_fulfilled = on_fulfilled
    self._on_rejected = on_rejected
    self._result = nil
    self._status = Future.PENDING
    self._processed = false
    self._nested_future = nil
end

function ThenFuture:poll()
    if self._status ~= Future.PENDING then
        return self._status, self._result
    end

    if self._nested_future then
        local nested_status, nested_value = self._nested_future:poll()
        if nested_status == Future.READY then
            self._result = nested_value
            self._status = Future.READY
            return self._status, self._result
        elseif nested_status == Future.ERROR then
            self._result = nested_value
            self._status = Future.ERROR
            return self._status, self._result
        else
            return Future.PENDING
        end
    end

    if not self._processed then
        local status, value = self._future:poll()

        if status == Future.READY and self._on_fulfilled then
            local success, result = pcall(self._on_fulfilled, value)
            if success then
                if type(result) == "table" and getmetatable(result) and result.poll then
                    self._nested_future = result
                    return Future.PENDING
                else
                    self._result = result
                    self._status = Future.READY
                    self._processed = true
                    return Future.READY, self._result
                end
            else
                self._result = result
                self._status = Future.ERROR
                self._processed = true
                return Future.ERROR, self._result
            end
        elseif status == Future.ERROR and self._on_rejected then
            local success, result = pcall(self._on_rejected, value)
            if success then
                self._result = result
                self._status = Future.READY
                self._processed = true
                return Future.READY, self._result
            else
                self._result = result
                self._status = Future.ERROR
                self._processed = true
                return Future.ERROR, self._result
            end
        elseif status ~= Future.PENDING then
            self._result = value
            self._status = status
            self._processed = true
            return status, value
        end
    end

    return Future.PENDING
end

local AllFuture = OOP.class("AllFuture", Future)
do
    function AllFuture:constructor(futures)
        self:super("constructor")
        self._futures = futures
        self._results = {}
        self._completed_count = 0
        self._error = nil
    end

    function AllFuture:poll()
        if self._error then
            return Future.ERROR, self._error
        end

        if self._completed_count == #self._futures then
            return Future.READY, self._results
        end

        for i, future in ipairs(self._futures) do
            if not self._results[i] then
                local status, value = future:poll()
                if status == Future.READY then
                    self._results[i] = value
                    self._completed_count = self._completed_count + 1
                elseif status == Future.ERROR then
                    self._error = value
                    return Future.ERROR, value
                end
            end
        end

        if self._completed_count == #self._futures then
            return Future.READY, self._results
        else
            return Future.PENDING
        end
    end
end

local RaceFuture = OOP.class("RaceFuture", Future)
do
    function RaceFuture:constructor(futures)
        self:super("constructor")
        self._futures = futures
        self._result = nil
        self._status = Future.PENDING
    end

    function RaceFuture:poll()
        if self._status ~= Future.PENDING then
            return self._status, self._result
        end

        for _, future in ipairs(self._futures) do
            local status, value = future:poll()
            if status ~= Future.PENDING then
                self._status = status
                self._result = value
                return status, value
            end
        end
        return Future.PENDING
    end
end

-- Future Executor
local FutureExecutor = OOP.class("FutureExecutor")
do
    function FutureExecutor:constructor()
        self._futures = {}
        self._completed_futures = {}
    end

    function FutureExecutor:spawn(future)
        if not future:instanceOf(Future) then
            error("Can only spawn Future objects")
        end

        if not future:implements(IFuture) then
            error("Future must implement IFuture interface")
        end

        local future_info = {
            future = future,
            completed = false,
            result = nil,
            status = nil
        }

        table.insert(self._futures, future_info)
        return future
    end

    function FutureExecutor:run_until_complete(timeout_ms)
        self._coroutine = coroutine.create(function()
            local start_time = os.clock()
            local iterations = 0
            local max_iterations = 10000

            while #self._futures > 0 and iterations < max_iterations do
                iterations = iterations + 1

                if timeout_ms then
                    local elapsed = (os.clock() - start_time) * 1000
                    if elapsed >= timeout_ms then
                        return false, "timeout"
                    end
                end

                local made_progress = false

                for i = #self._futures, 1, -1 do
                    local future_info = self._futures[i]

                    if not future_info.completed then
                        local status, result = future_info.future:poll()

                        if status ~= Future.PENDING then
                            future_info.completed = true
                            future_info.status = status
                            future_info.result = result
                            made_progress = true

                            table.insert(self._completed_futures, future_info)
                            table.remove(self._futures, i)
                        end
                    end
                end

                if not made_progress then
                    local small_delay = 0.001
                    local end_time = os.clock() + small_delay
                    while os.clock() < end_time do
                        -- for small delay
                    end
                end
            end

            if iterations >= max_iterations then
                return false, "max iterations reached"
            end

            return true, self:get_results()
        end)

        self._running = true
        local success, result1, result2 = coroutine.resume(self._coroutine)
        self._running = false

        if not success then
            error("Executor coroutine error: " .. tostring(result1))
        end

        return result1, result2
    end

    function FutureExecutor:get_results()
        local results = {}
        for i, future_info in ipairs(self._completed_futures) do
            results[i] = {
                future = future_info.future,
                status = future_info.status,
                result = future_info.result
            }
        end
        return results
    end

    function FutureExecutor:has_pending()
        return #self._futures > 0
    end
end

function Future.value(value)
    return ValueFuture.new(value)
end

function Future.error(err)
    return ErrorFuture.new(err)
end

function Future.delay(ms, value)
    return TimerFuture.new(ms, value)
end

function Future.all(futures)
    return AllFuture.new(futures)
end

function Future.race(futures)
    return RaceFuture.new(futures)
end

-- Export the module
return {
    -- Interfaces
    IFuture = IFuture,

    -- Base class
    Future = Future,

    -- Concrete implementations
    ValueFuture = ValueFuture,
    ErrorFuture = ErrorFuture,
    TimerFuture = TimerFuture,
    ThenFuture = ThenFuture,
    AllFuture = AllFuture,
    RaceFuture = RaceFuture,

    -- Executor
    FutureExecutor = FutureExecutor,

    -- States
    PENDING = Future.PENDING,
    READY = Future.READY,
    ERROR = Future.ERROR,

    -- Static methods
    value = Future.value,
    error = Future.error,
    delay = Future.delay,
    all = Future.all,
    race = Future.race
}

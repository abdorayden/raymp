-- /*********************************************************************************************/
-- /*  Copyright (c) 2025-2026 Ray Den 								*/
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
-- You can chain operations on Futures using the `:tthen()` and `:catch()` methods, which are inspired by JavaScript Promises.
--
-- **Library Components:**
--
-- - **`Future`**: The base class for all future types. It provides the core interface (`:poll()`, `:is_ready()`, `:tthen()`, `:catch()`).
-- - **`ValueFuture`**: A future that is immediately resolved with a given value.
-- - **`ErrorFuture`**: A future that is immediately rejected with a given error.
-- - **`TimerFuture`**: A future that resolves with a value after a specified delay in milliseconds.
-- - **`ThenFuture`**: A special future used internally by `:tthen()` and `:catch()` to chain operations.
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
-- local then_future = my_future:tthen(function(value)
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
-- local catch_future = error_future:tthen(function(value)
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
--     :tthen(function(val)
--         print("Step 1:", val)
--         return Future.delay(1000, val * 2) -- Return a new future
--     end)
--     :tthen(function(val)
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

-- Conditionally require Promise for interoperability
local Promise = nil
local ok, promise_module = pcall(require, "promises")
if ok then
    Promise = promise_module
end

--- @module 'rmp.future'
local F = {}

F.IFuture = OOP.interface("IFuture", "poll")

F.PENDING = "pending"
F.READY = "ready"
F.ERROR = "error"



-- base class
---@class Future
F.Future = OOP.class("Future", nil, F.IFuture)
do
    -- poll method is not implemented by default

    function F.Future:constructor()
        -- base future is abstract
        self._status = F.PENDING
    end

    ---@return boolean
    function F.Future:is_ready()
        -- local status, _ = self:poll()
        return self._status == F.READY
    end

    ---@param on_fulfilled? function
    ---@param on_rejected function
    ---@return table
    function F.Future:tthen(on_fulfilled, on_rejected)
        ---@diagnostic disable-next-line: undefined-field
        return F.ThenFuture.new(self, on_fulfilled, on_rejected)
    end

    ---@param on_rejected function
    ---@return table
    function F.Future:catch(on_rejected)
        return self:tthen(nil, on_rejected)
    end
end

---@class ThenFuture
F.ThenFuture = OOP.class("ThenFuture", F.Future)
do
    function F.ThenFuture:constructor(future, on_fulfilled, on_rejected)
        ---@diagnostic disable-next-line: undefined-field
        self:super("constructor")
        self._future = future
        self._on_fulfilled = on_fulfilled
        self._on_rejected = on_rejected
        self._result = nil
        self._status = F.PENDING
        self._processed = false
        self._nested_future = nil
    end

    function F.ThenFuture:poll()
        if self._status ~= F.PENDING then
            return self._status, self._result
        end

        if self._nested_future then
            local nested_status, nested_value = self._nested_future:poll()
            if nested_status == F.READY then
                self._result = nested_value
                self._status = F.READY
                return self._status, self._result
            elseif nested_status == F.ERROR then
                self._result = nested_value
                self._status = F.ERROR
                return self._status, self._result
            else
                return F.PENDING
            end
        end

        if not self._processed then
            local status, value = self._future:poll()

            if status == F.READY and self._on_fulfilled then
                local success, result = pcall(self._on_fulfilled, value)
                if success then
                    if type(result) == "table" and getmetatable(result) and result.poll then
                        self._nested_future = result
                        return F.PENDING
                    else
                        self._result = result
                        self._status = F.READY
                        self._processed = true
                        return F.READY, self._result
                    end
                else
                    self._result = result
                    self._status = F.ERROR
                    self._processed = true
                    return F.ERROR, self._result
                end
            elseif status == F.ERROR and self._on_rejected then
                local success, result = pcall(self._on_rejected, value)
                if success then
                    self._result = result
                    self._status = F.READY
                    self._processed = true
                    return F.READY, self._result
                else
                    self._result = result
                    self._status = F.ERROR
                    self._processed = true
                    return F.ERROR, self._result
                end
            elseif status ~= F.PENDING then
                self._result = value
                self._status = status
                self._processed = true
                return status, value
            end
        end

        return F.PENDING
    end
end
F.ValueFuture = OOP.class("ValueFuture", F.Future)
do
    function F.ValueFuture:constructor(value)
        self:super("constructor")
        self._value = value
        self._status = F.READY
    end

    function F.ValueFuture:poll()
        return self._status, self._value
    end
end

F.ErrorFuture = OOP.class("ErrorFuture", F.Future)
do
    function F.ErrorFuture:constructor(error)
        self:super("constructor")
        self._error = error
        self._status = F.ERROR
    end

    function F.ErrorFuture:poll()
        return self._status, self._error
    end
end

F.TimerFuture = OOP.class("TimerFuture", F.Future)
do
    function F.TimerFuture:constructor(delay_ms, value)
        self:super("constructor")
        self._delay_ms = delay_ms
        self._value = value
        self._start_time = os.clock()
        self._status = F.PENDING
    end

    function F.TimerFuture:poll()
        if self._status ~= F.PENDING then
            return self._status, self._value
        end

        local elapsed = (os.clock() - self._start_time) * 1000
        if elapsed >= self._delay_ms then
            self._status = F.READY
            return F.READY, self._value
        else
            return F.PENDING
        end
    end
end

-- New Future implementations
F.AnyFuture = OOP.class("AnyFuture", F.Future)
do
    function F.AnyFuture:constructor(futures)
        self:super("constructor")
        self._futures = futures
        self._errors = {}
        self._rejected_count = 0
        self._result = nil
        self._status = F.PENDING
    end

    function F.AnyFuture:poll()
        if self._status ~= F.PENDING then
            return self._status, self._result
        end

        for i, future in ipairs(self._futures) do
            local status, value = future:poll()
            if status == F.READY then
                self._result = value
                self._status = F.READY
                return self._status, self._result
            elseif status == F.ERROR then
                if not self._errors[i] then
                    self._errors[i] = value
                    self._rejected_count = self._rejected_count + 1

                    if self._rejected_count == #self._futures then
                        self._result = "AggregateError: All promises were rejected"
                        self._status = F.ERROR
                        return self._status, self._result
                    end
                end
            end
        end

        return F.PENDING
    end
end

F.AllSettledFuture = OOP.class("AllSettledFuture", F.Future)
do
    function F.AllSettledFuture:constructor(futures)
        self:super("constructor")
        self._futures = futures
        self._results = {}
        self._completed_count = 0
    end

    function F.AllSettledFuture:poll()
        if self._completed_count == #self._futures then
            return F.READY, self._results
        end

        for i, future in ipairs(self._futures) do
            if not self._results[i] then
                local status, value = future:poll()
                if status == F.READY then
                    self._results[i] = { status = "fulfilled", value = value }
                    self._completed_count = self._completed_count + 1
                elseif status == F.ERROR then
                    self._results[i] = { status = "rejected", reason = value }
                    self._completed_count = self._completed_count + 1
                end
            end
        end

        if self._completed_count == #self._futures then
            return F.READY, self._results
        else
            return F.PENDING
        end
    end
end

function F.newDeferred()
    return F.Future.newDeferred()
end

-- Promise-like functions for Future
function F.Future.newDeferred()
    local DeferredFuture = OOP.class("DeferredFuture", F.Future)
    do
        function DeferredFuture:constructor()
            self:super("constructor")
            self._value = nil
            self._error = nil
            self._resolver = function(value)
                if self._status == F.PENDING then
                    self._value = value
                    self._status = F.READY
                end
            end
            self._rejector = function(error)
                if self._status == F.PENDING then
                    self._error = error
                    self._status = F.ERROR
                end
            end
        end

        function DeferredFuture:resolve(value)
            self._resolver(value)
        end

        function DeferredFuture:reject(error)
            self._rejector(error)
        end

        function DeferredFuture:poll()
            return self._status, self._value or self._error
        end
    end

    local future = DeferredFuture.new()
    return future, future._resolver, future._rejector
end

if Promise then
    -- Convert a Promise to a Future
    function F.Future.fromPromise(promise)
        local PromiseFuture = OOP.class("PromiseFuture", F.Future)
        do
            function PromiseFuture:constructor(promise)
                self:super("constructor")
                self._promise = promise
            end

            function PromiseFuture:poll()
                if self._promise.state == Promise.State.Fulfilled then
                    return F.READY, self._promise.value
                elseif self._promise.state == Promise.State.Rejected then
                    return F.ERROR, self._promise.reason
                else
                    return F.PENDING
                end
            end
        end

        return PromiseFuture.new(promise)
    end
end

-- Static methods for the new futures
function F.Future.any(futures)
    return F.AnyFuture.new(futures)
end

function F.Future.allSettled(futures)
    return F.AllSettledFuture.new(futures)
end

function F.any(futs)
    return F.Future.any(futs)
end

function F.allSettled(futs)
    return F.Future.allSettled(futs)
end

F.AllFuture = OOP.class("AllFuture", F.Future)
do
    function F.AllFuture:constructor(futures)
        self:super("constructor")
        self._futures = futures
        self._results = {}
        self._completed_count = 0
        self._error = nil
    end

    function F.AllFuture:poll()
        if self._error then
            return F.ERROR, self._error
        end

        if self._completed_count == #self._futures then
            return F.READY, self._results
        end

        for i, future in ipairs(self._futures) do
            if not self._results[i] then
                local status, value = future:poll()
                if status == F.READY then
                    self._results[i] = value
                    self._completed_count = self._completed_count + 1
                elseif status == F.ERROR then
                    self._error = value
                    return F.ERROR, value
                end
            end
        end

        if self._completed_count == #self._futures then
            return F.READY, self._results
        else
            return F.PENDING
        end
    end
end

F.RaceFuture = OOP.class("RaceFuture", F.Future)
do
    function F.RaceFuture:constructor(futures)
        self:super("constructor")
        self._futures = futures
        self._result = nil
        self._status = F.PENDING
    end

    function F.RaceFuture:poll()
        if self._status ~= F.PENDING then
            return self._status, self._result
        end

        for _, future in ipairs(self._futures) do
            local status, value = future:poll()
            if status ~= F.PENDING then
                self._status = status
                self._result = value
                return status, value
            end
        end
        return F.PENDING
    end
end

-- Future Executor
F.FutureExecutor = OOP.class("FutureExecutor")
do
    function F.FutureExecutor:constructor()
        self._futures = {}
        self._completed_futures = {}
    end

    function F.FutureExecutor:spawn(future)
        if not future:instanceOf(F.Future) then
            error("Can only spawn Future objects")
        end

        if not future:implements(F.IFuture) then
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

    function F.FutureExecutor:run_until_complete(timeout_ms)
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

                        if status ~= F.PENDING then
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

    function F.FutureExecutor:get_results()
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

    function F.FutureExecutor:has_pending()
        return #self._futures > 0
    end
end

function F.Future.value(value)
    return F.ValueFuture.new(value)
end

function F.Future.error(err)
    return F.ErrorFuture.new(err)
end

function F.Future.delay(ms, value)
    return F.TimerFuture.new(ms, value)
end

function F.Future.all(futures)
    return F.AllFuture.new(futures)
end

function F.Future.race(futures)
    return F.RaceFuture.new(futures)
end

function F.value(value)
    return F.Future.value(value)
end

function F.error(err)
    return F.Future.error(err)
end

function F.race(futs)
    return F.Future.race(futs)
end

function F.all(futs)
    return F.Future.all(futs)
end

function F.delay(ms, val)
    return F.Future.delay(ms, val)
end

return F

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
-- this is an js Promises implemented in lua
-- the goal of this is simplify run plugins asyc
--
-- Resources:
-- 	- https://javascript.info/promise-basics
--	- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise

local tasks = {}

local function schedule(ms, fn)
    local t = os.clock() + (ms / 1000)
    table.insert(tasks, { time = t, cb = fn })
end

local Promise = {}
Promise.__index = Promise

Promise.State = {
    Pending = "pending",
    Fulfilled = "fulfilled",
    Rejected = "rejected"
}


function Promise.new(executor)
    local self = setmetatable({}, Promise)
    self.state = Promise.State.Pending
    self.value = nil
    self.reason = nil
    self.fulfilledCallbacks = {}
    self.rejectedCallbacks = {}

    local function resolve(value)
        if self.state == Promise.State.Pending then
            self.state = Promise.State.Fulfilled
            self.value = value
            for _, callback in ipairs(self.fulfilledCallbacks) do
                callback(value)
            end
        end
    end

    local function reject(reason)
        if self.state == Promise.State.Pending then
            self.state = Promise.State.Rejected
            self.reason = reason
            for _, callback in ipairs(self.rejectedCallbacks) do
                callback(reason)
            end
        end
    end

    local success, err = pcall(function()
        executor(resolve, reject)
    end)

    if not success then
        reject(err)
    end

    return self
end

function Promise.timeout(ms)
    return Promise.new(function(resolve)
        schedule(ms, resolve)
    end)
end

function Promise:tthen(onFulfilled, onRejected)
    local nextPromise = Promise.new(function(resolve, reject)
        local function handleCallback(callback, value, isRejection)
            if type(callback) == "function" then
                local success, result = pcall(callback, value)
                if success then
                    if type(result) == "table" and getmetatable(result) == Promise then
                        result:tthen(resolve, reject)
                    else
                        resolve(result)
                    end
                else
                    reject(result)
                end
            else
                if isRejection then
                    reject(value)
                else
                    resolve(value)
                end
            end
        end

        local function handleFulfilled(value)
            handleCallback(onFulfilled, value, false)
        end

        local function handleRejected(reason)
            handleCallback(onRejected, reason, true)
        end

        if self.state == Promise.State.Fulfilled then
            schedule(0, function() handleFulfilled(self.value) end)
        elseif self.state == Promise.State.Rejected then
            schedule(0, function() handleRejected(self.reason) end)
        else
            table.insert(self.fulfilledCallbacks, handleFulfilled)
            table.insert(self.rejectedCallbacks, handleRejected)
        end
    end)

    return nextPromise
end

function Promise:catch(onRejected)
    return self:tthen(nil, onRejected)
end

function Promise:finally(onFinally)
    return self:tthen(
        function(value)
            if type(onFinally) == 'function' then
                return Promise.resolve(onFinally()):tthen(function()
                    return value
                end)
            else
                return value
            end
        end,
        function(reason)
            if type(onFinally) == 'function' then
                return Promise.resolve(onFinally()):tthen(function()
                    return Promise.reject(reason)
                end)
            else
                return Promise.reject(reason)
            end
        end
    )
end

function Promise.resolve(value)
    if type(value) == "table" and getmetatable(value) == Promise then
        return value
    else
        return Promise.new(function(resolve)
            resolve(value)
        end)
    end
end

function Promise.reject(reason)
    return Promise.new(function(_, reject)
        reject(reason)
    end)
end

function Promise.all(promises)
    return Promise.new(function(resolve, reject)
        local results = {}
        local completed = 0
        local total = #promises

        if total == 0 then
            resolve({})
            return
        end

        for i, p in ipairs(promises) do
            Promise.resolve(p):tthen(
                function(value)
                    results[i] = value
                    completed = completed + 1
                    if completed == total then
                        resolve(results)
                    end
                end,
                reject
            )
        end
    end)
end

function Promise.race(promises)
    return Promise.new(function(resolve, reject)
        for _, p in ipairs(promises) do
            Promise.resolve(p):tthen(resolve, reject)
        end
    end)
end

function Promise.async(generator)
    return function(...)
        local args = { ... }
        return Promise.new(function(resolve, reject)
            local co = coroutine.create(generator)

            local function step(...)
                local results = { ... }
                local success, value = coroutine.resume(co, table.unpack(results))

                if not success then
                    reject(value)
                    return
                end

                if coroutine.status(co) == "dead" then
                    resolve(value)
                    return
                end

                if type(value) == "table" and getmetatable(value) == Promise then
                    value:tthen(
                        function(...) step(...) end,
                        function(err) reject(err) end
                    )
                else
                    step(value)
                end
            end

            step(table.unpack(args))
        end)
    end
end

function Promise.await(promise)
    if type(promise) == "table" and getmetatable(promise) == Promise then
        return coroutine.yield(promise)
    else
        return promise
    end
end

function Promise.runner()
    local now = os.clock()
    local executed = false
    for i = #tasks, 1, -1 do
        if now >= tasks[i].time then
            local cb = tasks[i].cb
            table.remove(tasks, i)
            local success, err = pcall(cb)
            if not success then
                print("Error in scheduled task: " .. tostring(err))
            end
            executed = true
        end
    end
    return executed
end

function Promise.run()
    local ok, err = pcall(function()
        while #tasks > 0 do
            local executed = Promise.runner()
            if not executed then
                local minTime = math.huge
                for _, task in ipairs(tasks) do
                    minTime = math.min(minTime, task.time)
                end
                local waitTime = math.max(0, minTime - os.clock())
                if waitTime > 0 and waitTime < 0.1 then
                    local target = os.clock() + waitTime
                    while os.clock() < target do end
                end
            end
        end
    end)

    if not ok then
        if tostring(err):match("interrupted") then
            print("\n [PROMISE] execution interrupted by user CTRL+C")
        else
            print(err)
        end
    end
end

return Promise

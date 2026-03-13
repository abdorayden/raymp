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
-- this is an js Promises implemented in lua
-- the goal of this is simplify run plugins asyc
--
-- TODO: use uv lib as backend
--
-- Resources:
-- 	- https://javascript.info/promise-basics
--	- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise

-- TODO: handle my own event loop
-- use socket and system implementations from uv it self

local tasks = {}
local schedule_impl
local uv = nil
local using_uv = false
local rsocket = nil

local function default_schedule(ms, fn)
    local t = os.clock() + (ms / 1000)
    table.insert(tasks, { time = t, cb = fn })
end

local function uv_schedule(ms, fn)
    local handle
    handle = uv and uv.timer_start(ms, function()
        for i = #tasks, 1, -1 do
            if tasks[i] == handle then
                table.remove(tasks, i)
                break
            end
        end
        fn()
    end)

    if handle then
        table.insert(tasks, handle)
    end
end

local function select_default_scheduler()
    if uv then
        using_uv = true
        schedule_impl = uv_schedule
    else
        using_uv = false
        schedule_impl = default_schedule
    end
end

local ok_uv, uv_mod = pcall(require, "rmp.uv")
if ok_uv then
    uv = uv_mod
end

local ok_socket, rsocket_mod = pcall(require, "rmp.rsocket")
if ok_socket then
    rsocket = rsocket_mod
end

select_default_scheduler()


--- @module 'rmp.promises'
local Promise = {}
Promise.__index = Promise

function Promise.schedule(ms, fn)
    schedule_impl(ms, fn)
end

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
        Promise.schedule(ms, resolve)
    end)
end

function Promise.sleep(ms)
    return Promise.timeout(ms)
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
            Promise.schedule(0, function() handleFulfilled(self.value) end)
        elseif self.state == Promise.State.Rejected then
            Promise.schedule(0, function() handleRejected(self.reason) end)
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

function Promise.readFile(path)
    return Promise.new(function(resolve, reject)
        if uv then
            uv.fs_readfile(path, function(err, data)
                if err then
                    reject(err)
                else
                    resolve(data)
                end
            end)
        else
            local f, err = io.open(path, "rb")
            if not f then
                reject(err)
                return
            end
            local data = f:read("*a")
            f:close()
            resolve(data or "")
        end
    end)
end

function Promise.writeFile(path, data)
    return Promise.new(function(resolve, reject)
        if uv then
            uv.fs_writefile(path, data, function(err, bytes)
                if err then
                    reject(err)
                else
                    resolve(bytes)
                end
            end)
        else
            local f, err = io.open(path, "wb")
            if not f then
                reject(err)
                return
            end
            f:write(data)
            f:close()
            resolve(#tostring(data))
        end
    end)
end

local function shell_quote(arg)
    if arg == "" then
        return "''"
    end
    if not arg:find("[^%w%-%._/:]") then
        return arg
    end
    return "'" .. arg:gsub("'", "'\\''") .. "'"
end

function Promise.spawn(file, args_or_opts)
    return Promise.new(function(resolve, reject)
        if uv then
            local opts = nil
            if type(args_or_opts) == "table" then
                if args_or_opts.args or args_or_opts.on_stdout or args_or_opts.on_stderr or args_or_opts.capture then
                    opts = args_or_opts
                else
                    opts = { args = args_or_opts }
                end
            end

            if opts then
                uv.spawn(file, opts, function(err, status, signal, stdout, stderr)
                    if err then
                        reject(err)
                    else
                        resolve({ status = status, signal = signal, stdout = stdout, stderr = stderr })
                    end
                end)
            else
                uv.spawn(file, function(err, status, signal, stdout, stderr)
                    if err then
                        reject(err)
                    else
                        resolve({ status = status, signal = signal, stdout = stdout, stderr = stderr })
                    end
                end)
            end
        else
            local cmd = shell_quote(file)
            local args = args_or_opts
            if type(args_or_opts) == "table" and (args_or_opts.args or args_or_opts.on_stdout or args_or_opts.on_stderr or args_or_opts.capture) then
                args = args_or_opts.args
            end
            if type(args) == "table" then
                for _, a in ipairs(args) do
                    cmd = cmd .. " " .. shell_quote(tostring(a))
                end
            end
            local ok, why, code = os.execute(cmd)
            if ok == nil then
                reject(why or "spawn failed")
            else
                local status = code or 0
                resolve({ status = status, signal = 0, stdout = nil, stderr = nil })
            end
        end
    end)
end

function Promise.tcpConnect(host, port)
    return Promise.new(function(resolve, reject)
        if not rsocket then
            reject("rmp.rsocket not available")
            return
        end
        local sock, err = rsocket.new("tcp")
        if not sock then
            reject(err)
            return
        end
        local ok, err2 = sock:connect(host, port)
        if not ok then
            sock:close()
            reject(err2)
            return
        end
        resolve(sock)
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
    if using_uv and uv then
        local active = uv.run("nowait")
        return active ~= 0
    else
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
end

function Promise.run()
    local ok, err = pcall(function()
        if using_uv and uv then
            uv.run("default")
        else
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

function Promise.setScheduler(new_scheduler)
    if new_scheduler == nil then
        select_default_scheduler()
    elseif type(new_scheduler) == "function" then
        using_uv = false
        schedule_impl = new_scheduler
    else
        error("scheduler must be a function or nil")
    end
end

function Promise.getScheduler()
    return schedule_impl
end

return Promise

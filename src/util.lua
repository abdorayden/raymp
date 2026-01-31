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

-- UTIL module is a part of raymp engine modules

--- @module 'rmp.util'
UTIL = {}

local OOP = require("rmp.oop")

UTIL.QueueAndStackable = OOP.interface(
    "QueueAndStackable",
    "push", "pop",
    "peek", "isEmpty"
)

UTIL.Map = OOP.interface(
    "Map", "clear", "containsKey",
    "containsValue", "entrySet",
    "get", "isEmpty", "keySet",
    "put", "putAll", "remove",
    "size", "values"
)

UTIL.HashMap = OOP.class("HashMap", nil, UTIL.Map)
do
    function UTIL.HashMap:constructor()
        self.data = {}
        self.size = 0
        return self
    end

    function UTIL.HashMap:clear()
        self.data = {}
        self.size = 0
    end

    function UTIL.HashMap:containsKey(key)
        return self.data[key] ~= nil
    end

    function UTIL.HashMap:containsValue(value)
        for _, v in pairs(self.data) do
            if v == value then
                return true
            end
        end
        return false
    end

    function UTIL.HashMap:entrySet()
        local entries = {}
        for key, value in pairs(self.data) do
            table.insert(entries, { key = key, value = value })
        end
        return entries
    end

    function UTIL.HashMap:get(key)
        return self.data[key]
    end

    function UTIL.HashMap:isEmpty()
        return self.size == 0
    end

    function UTIL.HashMap:keySet()
        local keys = {}
        for key in pairs(self.data) do
            table.insert(keys, key)
        end
        return keys
    end

    function UTIL.HashMap:put(key, value)
        if not key or not value then
            return false, nil
        end
        local oldValue = self.data[key]
        self.data[key] = value
        if oldValue == nil then
            self.size = self.size + 1
        end
        return true, oldValue
    end

    function UTIL.HashMap:putAll(map)
        for _, entry in ipairs(map:entrySet()) do
            self:put(entry.key, entry.value)
        end
    end

    function UTIL.HashMap:remove(key)
        local value = self.data[key]
        if value ~= nil then
            self.data[key] = nil
            self.size = self.size - 1
        end
        return value
    end

    function UTIL.HashMap:size()
        return self.size
    end

    function UTIL.HashMap:values()
        local values = {}
        for _, value in pairs(self.data) do
            table.insert(values, value)
        end
        return values
    end
end

UTIL.Queue = OOP.class("Queue", nil, UTIL.QueueAndStackable)
do
    function UTIL.Queue:constructor(staticSize)
        self.staticSize = staticSize
        self.static = staticSize ~= nil
        self.queue = {}
        self.readIndex = 0  -- Points to the next item to read
        self.writeIndex = 0 -- Points to the next position to write
        return self
    end

    function UTIL.Queue:clear()
        self.queue = {}
        self.readIndex = 0  -- Points to the next item to read
        self.writeIndex = 0 -- Points to the next position to write
    end

    function UTIL.Queue:push(data)
        if self.static then
            if self.writeIndex < self.staticSize then
                self.writeIndex = self.writeIndex + 1
                self.queue[self.writeIndex] = data
            end
        else
            self.writeIndex = self.writeIndex + 1
            self.queue[self.writeIndex] = data
        end
        return self
    end

    function UTIL.Queue:pop()
        if self.readIndex < self.writeIndex then
            self.readIndex = self.readIndex + 1
            return self.queue[self.readIndex]
        end
        return nil
    end

    function UTIL.Queue:peek()
        if self.readIndex < self.writeIndex then
            return self.queue[self.readIndex + 1]
        end
        return nil
    end

    function UTIL.Queue:isEmpty()
        return self.readIndex >= self.writeIndex
    end
end

UTIL.Stack = OOP.class("Stack", nil, UTIL.StackAndStackable)
do
    function UTIL.Stack:constructor(staticSize)
        self.staticSize = staticSize
        self.static = staticSize ~= nil
        self.stack = {}
        self.top = 0 -- Points to the top element (0 means empty)
        return self
    end

    function UTIL.Stack:push(data)
        if self.static then
            if self.top < self.staticSize then
                self.top = self.top + 1
                self.stack[self.top] = data
            end
        else
            self.top = self.top + 1
            self.stack[self.top] = data
        end
        return self
    end

    function UTIL.Stack:pop()
        if self.top > 0 then
            local data = self.stack[self.top]
            self.stack[self.top] = nil -- Optional: free memory
            self.top = self.top - 1
            return data
        end
        return nil
    end

    function UTIL.Stack:peek()
        if self.top > 0 then
            return self.stack[self.top]
        end
        return nil
    end

    function UTIL.Stack:isEmpty()
        return self.top == 0
    end

    function UTIL.Stack:size()
        return self.top
    end
end

return UTIL

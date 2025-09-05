UTIL = {}

local OOP = require("rmp.oop")

UTIL.QueueAndStackable = OOP.interface("QueueAndStackable" , "push" , "pop" , "peek" , "isEmpty")

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
		self.top = 0  -- Points to the top element (0 means empty)
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
			self.stack[self.top] = nil  -- Optional: free memory
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

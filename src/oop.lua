-- Copyright (C) by rayden at 27/08/2025
-- Fixed: multi-level inheritance 'super' resolution to avoid stack overflow
--
-- this is an java oop syntax implemented in lua
-- the goal is make the code more readable to define interfaces and class so the programmer and even me i can understand that 
-- this is an interface and what's the methods that i shoul implements
--
-- Example:
-- 	I)- Inheritance:
-- 		I)- Definition
-- 			local Animal = OOP.class("Animal")

-- 			function Animal:constructor(name)
-- 			    self.name = name
-- 			end

-- 			function Animal:speak()
-- 			    return "Some generic animal sound"
-- 			end

-- 			function Animal:getName()
-- 			    return self.name
-- 			end

-- 			local Dog = OOP.class("Dog", Animal)

-- 			function Dog:constructor(name, breed)
-- 			    self:super("constructor", name)
-- 			    self.breed = breed
-- 			end

-- 			function Dog:speak()
-- 			    return "Woof!"
-- 			end

-- 			function Dog:getBreed()
-- 			    return self.breed
-- 			end
--
-- 		II)- Usage :
-- 			local dog = Dog.new("Buddy", "Golden Retriever")
-- 			print(dog:getName())    -- Output: Buddy (inherited from Animal)
-- 			print(dog:speak())      -- Output: Woof! (overridden)
-- 			print(dog:getBreed())   -- Output: Golden Retriever (Dog-specific)
-- 			print("Is Animal:", dog:instanceOf(Animal)) -- Output: true
-- 			print("Is Dog:", dog:instanceOf(Dog))       -- Output: true
--	II)- extends + implements
--		I)- Definition:
--			// define interfaces
-- 			local Drawable = OOP.interface("Drawable", "draw", "getDimensions")
-- 			local Resizable = OOP.interface("Resizable", "resize", "getScale")
--			// define class
-- 			local Shape = OOP.class("Shape")
-- 			function Shape:constructor(x, y)
-- 			    self.x = x or 0
-- 			    self.y = y or 0
-- 			end
-- 			function Shape:move(newX, newY)
-- 			    self.x = newX
-- 			    self.y = newY
-- 			    print(string.format("Moved to (%d, %d)", newX, newY))
-- 			end
-- 			function Shape:getPosition()
-- 			    return {x = self.x, y = self.y}
-- 			end

-- 			local Circle = OOP.class("Circle", Shape, Drawable, Resizable)

-- 			function Circle:constructor(x, y, radius)
-- 			    self:super("constructor", x, y)
-- 			    self.radius = radius or 1
-- 			    self.scale = 1
-- 			end

-- 			function Circle:draw()
-- 			    print(string.format("Drawing circle at (%d, %d) with radius: %.2f", 
-- 			        self.x, self.y, self.radius * self.scale))
-- 			end

-- 			function Circle:getDimensions()
-- 			    return {
-- 			        type = "circle",
-- 			        radius = self.radius * self.scale,
-- 			        x = self.x,
-- 			        y = self.y
-- 			    }
-- 			end

-- 			function Circle:resize(factor)
-- 			    self.scale = factor
-- 			    print("Circle resized by factor: " .. factor)
-- 			end

-- 			function Circle:getScale()
-- 			    return self.scale
-- 			end

-- 			function Circle:move(newX, newY)
-- 			    print("Moving circle...")
-- 			    self:super("move", newX, newY)
-- 			end

-- 		II)- Usage:
-- 			local circle = Circle.new(10, 20, 5)

-- 			-- Inherited methods from Shape
-- 			circle:move(15, 25) -- Output: Moving circle... Moved to (15, 25)
-- 			local pos = circle:getPosition()
-- 			print("Position:", pos.x, pos.y) -- Output: Position: 15 25

-- 			-- Interface methods
-- 			circle:draw() -- Output: Drawing circle at (15, 25) with radius: 5.00
-- 			circle:resize(2.0) -- Output: Circle resized by factor: 2.0

-- 			-- Type checking
-- 			print("Is Shape:", circle:instanceOf(Shape)) -- Output: true
-- 			print("Is Circle:", circle:instanceOf(Circle)) -- Output: true
-- 			print("Implements Drawable:", circle:implements(Drawable)) -- Output: true
-- 			print("Implements Resizable:", circle:implements(Resizable)) -- Output: true
--
-- 	III)- Multi-level Inheritance:
--		
--		I)- Definition:
--			local Vehicle = OOP.class("Vehicle")
--			
--			function Vehicle:constructor(make, model)
--			    self.make = make
--			    self.model = model
--			    self.speed = 0
--			end
--			
--			function Vehicle:start()
--			    print("Vehicle started")
--			end
--			
--			function Vehicle:stop()
--			    self.speed = 0
--			    print("Vehicle stopped")
--			end
--			
--			-- Car extends Vehicle
--			local Car = OOP.class("Car", Vehicle)
--			
--			function Car:constructor(make, model, doors)
--			    self:super("constructor", make, model)
--			    self.doors = doors
--			end
--			
--			function Car:accelerate(amount)
--			    self.speed = self.speed + amount
--			    print(string.format("Car accelerated to %d km/h", self.speed))
--			end
--			
--			-- SportsCar extends Car
--			local SportsCar = OOP.class("SportsCar", Car)
--			
--			function SportsCar:constructor(make, model, doors, turbo)
--			    self:super("constructor", make, model, doors)
--			    self.turbo = turbo or false
--			end
--			
--			function SportsCar:activateTurbo()
--			    self.turbo = true
--			    print("Turbo activated!")
--			end
--			
--			function SportsCar:accelerate(amount)
--			    local boost = self.turbo and amount * 2 or amount
--			    self:super("accelerate", boost)
--			end
--		
--		II)- Usage:
--			local sportsCar = SportsCar.new("Ferrari", "488", 2, true)
--			
--			sportsCar:start() // Output: Vehicle started (from Vehicle)
--			sportsCar:activateTurbo() // Output: Turbo activated! (SportsCar specific)
--			sportsCar:accelerate(50) // Output: Car accelerated to 100 km/h (with turbo boost)
--			
--			print("Make:", sportsCar.make) // Output: Ferrari (from Vehicle)
--			print("Doors:", sportsCar.doors) // Output: 2 (from Car)
--			print("Turbo:", sportsCar.turbo) // Output: true (from SportsCar)
--			
--			print("Is Vehicle:", sportsCar:instanceOf(Vehicle)) // Output: true
--			print("Is Car:", sportsCar:instanceOf(Car)) // Output: true
--			print("Is SportsCar:", sportsCar:instanceOf(SportsCar)) // Output: true
--
--	VI)- Abstract Base Class Pattern:
--
--		I)- Definition:
--			local AbstractDatabase = OOP.class("AbstractDatabase")
--			
--			function AbstractDatabase:constructor(connectionString)
--			    self.connectionString = connectionString
--			    self.connected = false
--			end
--			
--			-- Abstract method (should be overridden)
--			function AbstractDatabase:connect()
--			    error("Abstract method 'connect' must be implemented")
--			end
--			
--			function AbstractDatabase:query(sql)
--			    error("Abstract method 'query' must be implemented")
--			end
--			
--			function AbstractDatabase:close()
--			    error("Abstract method 'close' must be implemented")
--			end
--			
--			-- Concrete implementation
--			local MySQLDatabase = OOP.class("MySQLDatabase", AbstractDatabase)
--			
--			function MySQLDatabase:constructor(connectionString)
--			    self:super("constructor", connectionString)
--			end
--			
--			function MySQLDatabase:connect()
--			    print("Connecting to MySQL: " .. self.connectionString)
--			    self.connected = true
--			    return true
--			end
--			
--			function MySQLDatabase:query(sql)
--			    if not self.connected then
--			        error("Not connected to database")
--			    end
--			    print("Executing MySQL query: " .. sql)
--			    return {result = "MySQL result"}
--			end
--			
--			function MySQLDatabase:close()
--			    print("Closing MySQL connection")
--			    self.connected = false
--			end
--		
--		II)- Usage:
--			local db = MySQLDatabase.new("mysql://localhost:3306/mydb")
--			db:connect()
--			local result = db:query("SELECT * FROM users")
--			db:close()

local OOP = {}

function OOP.interface(name, ...)
	local methods = {...}
	local interface = {
		name = name,
		methods = methods,
		__type = "interface"
	}

	function interface:validateImplementation(class, className)
		local missingMethods = {}

		for _, method in ipairs(self.methods) do
			if type(class[method]) ~= "function" then
				table.insert(missingMethods, method)
			end
		end

		if #missingMethods > 0 then
			error(string.format("Class '%s' must implement interface '%s'. Missing methods: %s",
			className, self.name, table.concat(missingMethods, ", ")))
		end
	end

	return interface
end

function OOP.class(name, superClass, ...)
	local interfaces = {...}
	local class = {
		__name = name,
		__super = superClass,
		__interfaces = interfaces,
		__type = "class"
	}

	if superClass then
		setmetatable(class, {__index = superClass})
	end

	class.__index = class

	local function find_class_by_function(startClass, func)
		local c = startClass
		while c do
			for k, v in pairs(c) do
				if type(v) == "function" and v == func then
					return c
				end
			end
			c = c.__super
		end
		return nil
	end

	function class.new(...)
		local self = setmetatable({}, class)

		for _, interface in ipairs(interfaces) do
			interface:validateImplementation(class, name)
		end

		if self.constructor then
			self:constructor(...)
		end

		return self
	end

	function class:implements(interface)
		for _, iface in ipairs(self.__interfaces) do
			if iface == interface then
				return true
			end
		end

		if self.__super and self.__super.implements then
			return self.__super:implements(interface)
		end

		return false
	end

	function class:instanceOf(targetClass)
		local currentClass = getmetatable(self).__index
		if currentClass == targetClass then
			return true
		end
		local parent = currentClass.__super
		while parent do
			if parent == targetClass then
				return true
			end
			parent = parent.__super
		end

		return false
	end

	-- robust 'super' implementation: detect the class whose method called 'super',
	-- then call the next superclass *above* that class that actually implements the requested method.
	function class:super(methodName, ...)
		local instanceClass = getmetatable(self).__index

		local callerFunc
		if debug and debug.getinfo then
			local info = debug.getinfo(2, "f")
			callerFunc = info and info.func
		end

		local callerClass
		if callerFunc then
			callerClass = find_class_by_function(instanceClass, callerFunc)
		end

		-- if we couldn't find the caller class by looking for the function,
		-- fallback to finding the class that defines 'methodName' first (closest to instance),
		-- and treat that as the caller class. This makes calling super("constructor") work when
		-- constructors are defined at different levels.
		if not callerClass then
			local c = instanceClass
			while c do
				if type(c[methodName]) == "function" then
					callerClass = c
					break
				end
				c = c.__super
			end
		end

		if not callerClass then
			error("Method '" .. methodName .. "' not found in inheritance chain")
		end

		local parent = callerClass.__super
		while parent do
			if type(parent[methodName]) == "function" then
				return parent[methodName](self, ...)
			end
			parent = parent.__super
		end

		error("No superclass implements method '" .. methodName .. "' above caller class")
	end

	return class
end

return OOP

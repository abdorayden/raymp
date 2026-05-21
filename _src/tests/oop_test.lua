local oop = require("rmp.oop")

local Foo = oop.class("Foo")
do
    function Foo:constructor(f)
        self.f = f
    end

    function Foo:getF()
        return self.f
    end

    function Foo:__add(f1)
        return Foo(self.f .. " " .. f1:getF())
    end
end

local foo1 = Foo("hey")
local foo2 = Foo("foo")
local foo3 = Foo("bar")

print(foo1:getF())
print(foo2:getF())

-- local f3 = foo1 + foo2
-- print(f3:getF())

print((foo1 + foo2 + foo3):getF())

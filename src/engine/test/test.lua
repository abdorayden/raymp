mm = require("mod")
mm.add(10,20)
mm.sub(30,20)
mm.mul(10,20)
mm.div(30,20)
mm.has_sin = true
mm.sin(a)

-- local objects = {}
-- 
-- all_new_objects = {}
-- 
-- function create_object(object_name)
-- 	-- objects[object_name] = {}
-- 	_G[object_name] = {}
-- 	all_new_objects[1] = _G[object_name]
-- end
-- 
-- co = coroutine.create(function()
-- 	i = 0
--     while true do
-- 	    i = i+1
--       coroutine.yield(i)
--     end
--   end)
-- 
-- --_ , i = coroutine.resume(co)
-- --_ , x = coroutine.resume(co)
-- print(coroutine.resume(co))
-- print(coroutine.resume(co))
-- print(coroutine.resume(co))

--create_object("abdo")
--
----objects["abdo"][1] = function(a,b)
----	return a + b
----end
--abdo[1] = function(a,b)
--	return a + b
--end
---- abdo = objects["abdo"][1]
--
--print(abdo[1](6,6))
--print(all_new_objects[1][1](99,1))

--t = {
--	[5] = 1
--}
--
----t[1] = 1
--print(t[5])


-- local io = require("io")
-- 
-- io.write("hello\n")
-- 
-- 
-- function add(a,b)
-- 	return a + b
-- end
-- 
-- local obj = {["add"] = add , [2] = 5}
-- 
-- obj["hello"] = "world"
-- print(obj["hello"])
-- 

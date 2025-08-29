local Promise = require("./promises")

-- -- Example 1: Basic promise chain
-- local function asyncOperation(value, delay)
-- 	return Promise.new(function(resolve, reject)
-- 		print("Starting operation with:", value)
-- 		-- Simulate async operation
-- 		local timer = os.time()
-- 		while os.time() - timer < delay do
-- 			-- Wait
-- 		end
-- 		if math.random() > 0.2 then
-- 			resolve(value * 2)
-- 		else
-- 			reject("Operation failed!")
-- 		end
-- 	end)
-- end

-- asyncOperation(5, 1)
-- :then_(function(result)
-- 	print("First result:", result)
-- 	return asyncOperation(result + 10, 1)
-- end)
-- :then_(function(result)
-- 	print("Second result:", result)
-- 	return "Final: " .. tostring(result)
-- end)
-- :catch(function(error)
-- 	print("Error caught:", error)
-- 	return "Recovered from error"
-- end)
-- :then_(function(finalResult)
-- 	print("Final result:", finalResult)
-- end)

-- Example 2: Using coroutines for async/await style
-- local async = Promise.async

-- local asyncFunction = async(function(x)
--     print("Async function started with:", x)
    
--     -- Await promises using coroutine.yield
--     local result1 = Promise.await(asyncOperation(x, 1))
--     print("After first await:", result1)
    
--     local result2 = Promise.await(asyncOperation(result1 + 5, 1))
--     print("After second await:", result2)
    
--     return result2 * 2
-- end)

-- -- Execute the async function

local countAsync = Promise.async(function(start , limit)
	for i = start, limit do
		local total = (limit - start)
		local percent = math.floor((i / total ) * 100)
		local bar = "[" .. string.rep("=", math.floor(percent / total)) .. string.rep(" ", 5 - math.floor(percent / total)) .. "]"
		io.write("\r" .. bar .. " " .. percent .. "% (" .. i .. "/" .. total .. ")")
		io.flush()
		Promise.await(Promise.timeout(500))
	end
	return "\nCounter finished!"
end)

-- Run two counters in parallel
countAsync(0 , 5):then_(print):catch(print)
-- countAsync(10 , 20):then_(print):catch(print)

Promise.run()

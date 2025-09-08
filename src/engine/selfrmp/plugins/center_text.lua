local api = require("rmp.rmp")

local plug = api.plug
local VirtualTerminal = api.VirtualTerminal

-- local inc = api.enum(true)

lx = 1

-- tested plug function wrapper for plugins
-- you don't have to think about yield or another loop
-- just accept boundries and return virtual terminal object
return function(x,y,xx,yy)
	local vt = VirtualTerminal.new()
	do
		local x = x + lx
		lx = lx + 1
		vt:writeText((xx-x)/2 + lx - 2 , (yy-y)/2 + y , "test" , nil , nil , api.TextStyle.Bold)
		inc = api.enum()
	end
	return vt
end

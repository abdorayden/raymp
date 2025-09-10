local api = require("rmp.rmp")

local plug = api.plug
local VirtualTerminal = api.VirtualTerminal

local bgcolors = {
	api.BGColors.Brights.Red,
	api.BGColors.Brights.White,
	api.BGColors.Brights.Blue,
}

-- tested plug function wrapper for plugins
-- you don't have to think about yield or another loop
-- just accept boundries and return virtual terminal object
return function(x,y,xx,yy)
	local vt = VirtualTerminal.new()
	do
		vt:writeText((xx-x)/2 + x - 2 , (yy-y)/2 + y , "test" , nil , bgcolors[math.random(1 , #bgcolors)] , api.TextStyle.Bold)
	end
	return vt
end

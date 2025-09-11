local api = require("rmp.rmp")

local plug = api.plug
local VirtualTerminal = api.VirtualTerminal
local Frame = api.Frame

local bgcolors = {
	api.BGColors.Brights.Red,
	api.BGColors.Brights.White,
	api.BGColors.Brights.Blue,
}

local lx = 0
local ly = 0

-- tested plug function wrapper for plugins
-- you don't have to think about yield or another loop
-- just accept boundries and return virtual terminal object
return function(x,y,xx,yy)
	local vt = Frame.new()
	do
		x = lx + x
		y = ly + y
		vt:addEventListener(api.KEY_L , function()
			lx = lx + 1
		end)
		vt:addEventListener(api.KEY_J , function()
			ly = ly + 1
		end)
		vt:addEventListener(api.KEY_K , function()
			ly = ly - 1
		end)
		vt:addEventListener(api.KEY_H , function()
			lx = lx - 1
		end)
		vt:writeText((xx-x)/2 + x - 2 , (yy-y)/2 + y , "test" , nil , bgcolors[math.random(1 , #bgcolors)] , api.TextStyle.Bold)
	end
	return vt
end

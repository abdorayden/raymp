local api = require("rmp.rmp")

local plug = api.plug
local VirtualTerminal = api.VirtualTerminal
local Frame = api.Frame

local bgcolors = {
	api.BGColors.Brights.Red,
	api.BGColors.Brights.White,
	api.BGColors.Brights.Blue,
}

local label = "center text"

-- tested plug function wrapper for plugins
-- you don't have to think about yield or another loop
-- just accept boundries and return virtual terminal object
return function(x,y,xx,yy)
	local vt = Frame.new()
	do
		vt:addEventListener(api.EventType.TransformDataGet, function(data)
			if data and type(data) == "string" then
				label = data
			end
		end)

		vt:writeText((xx-x)/2 + x - 2 , (yy-y)/2 + y , label , nil , bgcolors[math.random(1 , #bgcolors)] , api.TextStyle.Bold)
	end
	return vt
end

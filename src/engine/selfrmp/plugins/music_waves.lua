local api = require("rmp.rmp")

local plug = api.plug

local cols = 8
local values = {}
local bgcolors = {
	api.BGColors.Brights.Red,
	api.BGColors.Brights.White,
	api.BGColors.Brights.White,
	api.BGColors.Brights.White,
	api.BGColors.Brights.White,
	api.BGColors.Brights.White,
	api.BGColors.Brights.White
}


return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local wrec = math.floor(w / cols)
	for i = 1, cols do
		values[i] = math.random(3, h - 3)
	end

	local vt = api.VirtualTerminal.new()

	for i = 1, cols do
		local waveHeight = (h - 10) / 2
		local timeOffset = os.clock() * 2
		local phaseShift = i * 0.5

		values[i] = waveHeight * math.sin(timeOffset + phaseShift) + (h / 2)

		values[i] = math.max(5, math.min(h - 5, values[i]))

		local colorIndex = (i + math.floor(timeOffset)) % #bgcolors + 1
		local bgcolor = bgcolors[colorIndex]

		vt:merge(api.Draw:rectangle(
		math.floor(x + wrec * (i - 1) + 1),
		math.floor(y + h - values[i]),
		math.floor(wrec - 2),
		math.floor(values[i]),
		bgcolor
		))
	end

	return vt
end

local api = require("rmp.rmp")

local vt = api.VirtualTerminal.new()
local time = 0

local bgcolors = {
	api.BGColors.Brights.Red,
	api.BGColors.Brights.White,
	api.BGColors.Brights.Blue,
	api.BGColors.Brights.Green,
	api.BGColors.Brights.Yellow
}

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)

	local palette = {}
	for i = 0, 255 do
		palette[i] = bgcolors[math.random(1,#bgcolors)]
	end

	time = time + 0.05

	for i = x, xx - 1, 2 do  
		for j = y, yy - 2, 2 do
			local value = math.sin((i - x) / 8 + time)
			value = value + math.sin((j - y) / 8 + time)
			value = value + math.sin((i - x + j - y) / 16 + time)
			value = value + math.sin(math.sqrt((i - x) * (i - x) + (j - y) * (j - y)) / 8 + time)

			value = (value + 4) * 32
			value = math.floor(value % 256)

			local color = palette[value]

			vt:merge(api.Draw:rectangle(i, j, 2, 2, color))
		end
	end

	return vt
end

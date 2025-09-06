-- it's broken
local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local time = 0

	local palette = {}
	for i = 0, 255 do
		local r = math.floor(math.sin(i * 0.0245 + 0) * 127 + 128)
		local g = math.floor(math.sin(i * 0.0245 + 2) * 127 + 128)
		local b = math.floor(math.sin(i * 0.0245 + 4) * 127 + 128)
		palette[i] = api.BGColors.Brights.Red  
	end

	while true do
		local vt = api.VirtualTerminal.new()
		time = time + 0.05

		for i = x, xx, 2 do  
			for j = y, yy, 2 do
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

		coroutine.yield(vt)

		local delay = 0.1
		local start = os.clock()
		while os.clock() - start < delay do end
	end
end)

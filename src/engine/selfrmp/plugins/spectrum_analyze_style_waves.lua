local api = require("rmp.rmp")

local bands = 16  
local values = {}
local peaks = {}  
local init = false

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local peakFalloff = 0.92  
	local vt = api.VirtualTerminal.new()
	local dynamicBands = math.max(8, math.min(24, math.floor(w / 6)))
	local bandWidth = math.floor(w / dynamicBands)

	if not initialized or #values ~= dynamicBands then
		values = {}
		peaks = {}  
		for i = 1,dynamicBands do
			values[i] = h / 2
			peaks[i] = 0
		end
		initialized = true
	end

	for i = 1, dynamicBands do
		values[i] = values[i] * 0.7 + math.random(5, h - 5) * 0.3

		if values[i] > peaks[i] then
			peaks[i] = values[i]
		else
			peaks[i] = peaks[i] * peakFalloff
		end

		local barHeight = values[i]

		local color
		if barHeight > h * 0.8 then
			color = api.BGColors.Brights.Red
		elseif barHeight > h * 0.6 then
			color = api.BGColors.Brights.Yellow
		elseif barHeight > h * 0.4 then
			color = api.BGColors.Brights.Green
		else
			color = api.BGColors.Brights.Blue
		end

		vt:merge(api.Draw:rectangle(
		x + bandWidth * (i - 1) + 1,
		y + h - barHeight,
		bandWidth - 2,
		barHeight,
		color
		))

		if peaks[i] > barHeight + 2 then
			vt:merge(api.Draw:rectangle(
			x + bandWidth * (i - 1),
			y + h - peaks[i] - 1,
			bandWidth,
			1,
			api.BGColors.Brights.White
			))
		end
	end


	local delay = 0.1
	local start = os.clock()
	while os.clock() - start < delay do end
	return vt
end

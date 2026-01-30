--	works but so slow
--	TODO: create plugins bindings in C
local api = require("rmp.rmp")

local time = 0

-- FIXME: slow as fuck , i do a lot of iterations here this is a 2^n LOL joking idk

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local heartbeatPattern = {0.2, 0.5, 0.7, 0.9, 0.7, 0.5, 0.2, 0.1, 0.2, 0.3, 0.2}
	local dataPoints = {}
	local maxDataPoints = w - 2
	local beatInterval = 1.5

	for i = 1, maxDataPoints do
		dataPoints[i] = 0.2
	end

	local vt = api.VirtualTerminal.new()
	time = time + 0.1

	for i = x, xx do
		for j = y, yy do
			vt:merge(api.Draw:rectangle(i, j, 1, 1, api.BGColors.NoBrights.Black))
		end
	end

	table.remove(dataPoints, 1)

	if time % beatInterval < 0.1 then
		dataPoints[maxDataPoints] = heartbeatPattern[1]
	elseif time % beatInterval < 0.1 + #heartbeatPattern * 0.05 then
		local beatProgress = (time % beatInterval - 0.1) / 0.05
		local patternIndex = math.min(#heartbeatPattern, math.floor(beatProgress) + 1)
		dataPoints[maxDataPoints] = heartbeatPattern[patternIndex]
	else
		dataPoints[maxDataPoints] = 0.2
	end

	for i = 1, #dataPoints do
		local value = dataPoints[i]
		local pointX = x + i - 1
		local pointY = y + math.floor((1 - value) * h)

		if pointX >= x and pointX < xx and pointY >= y and pointY < yy then
			vt:merge(api.Draw:rectangle(
			pointX, pointY,
			1, 1,
			api.BGColors.Brights.Red
			))
		end
	end


	-- local delay = 0.1
	-- local start = os.clock()
	-- while os.clock() - start < delay do end
	return vt
end

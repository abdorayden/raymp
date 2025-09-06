-- i mean it's oky (broke)
local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local points = {}
	local pointCount = 40
	local time = 0

	for i = 1, pointCount do
		points[i] = {
			x = x + (i - 1) * (w / pointCount),
			y = y + h / 2,
			value = 0
		}
	end

	local bgc = {
		api.BGColors.Brights.Red,
		api.BGColors.Brights.Green,
		api.BGColors.Brights.Blue,
		api.BGColors.Brights.Yellow,
		api.BGColors.Brights.Magenta,
		api.BGColors.Brights.Cyan
	}

	while true do
		local vt = api.VirtualTerminal.new()
		time = time + 0.1

		for i, point in ipairs(points) do
			local wave1 = math.sin(time + i * 0.2) * 0.4
			local wave2 = math.sin(time * 1.7 + i * 0.3) * 0.3
			local wave3 = math.sin(time * 0.5 + i * 0.4) * 0.3

			point.value = (wave1 + wave2 + wave3) * (h / 2)
			point.y = y + h / 2 + point.value
		end

		for i = 1, pointCount - 1 do
			local p1 = points[i]
			local p2 = points[i + 1]

			vt:merge(api.Draw:line(
			math.floor(p1.x), math.floor(p1.y),
			math.floor(p2.x), math.floor(p2.y),
			api.BGColors.Brights.Cyan
			))

			vt:merge(api.Draw:rectangle(
			math.floor(p1.x) - 1, math.floor(p1.y) - 1,
			3, 3,
			api.BGColors.Brights.Blue
			))
		end

		local lastPoint = points[pointCount]
		vt:merge(api.Draw:rectangle(
		math.floor(lastPoint.x) - 1, math.floor(lastPoint.y) - 1,
		3, 3,
		api.BGColors.Brights.Blue
		))

		for i = 1, 10 do
			local barHeight = math.random(5, h / 3) * (0.7 + 0.3 * math.sin(time * 2 + i))
			local barWidth = math.floor(w / 12)
			local barX = x + (i - 1) * barWidth + barWidth / 4

			vt:merge(api.Draw:rectangle(
			barX, yy - barHeight,
			barWidth / 2, barHeight,
			bgc[math.random(1, 4)]
			))
		end

		coroutine.yield(vt)

		local delay = 0.07
		local start = os.clock()
		while os.clock() - start < delay do end
	end
end)

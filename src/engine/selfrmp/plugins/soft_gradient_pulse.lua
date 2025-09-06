local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local time = 0
	local colors = {
		api.BGColors.NoBrights.Blue,
		api.BGColors.NoBrights.Magenta,
		api.BGColors.NoBrights.Cyan
	}

	while true do
		local vt = api.VirtualTerminal.new()
		time = time + 0.03

		local pulse = (math.sin(time) + 1) / 2

		local colorIndex = math.floor(pulse * (#colors - 1)) + 1
		local nextIndex = colorIndex < #colors and colorIndex + 1 or 1
		local currentColor = colors[colorIndex]

		for i = 0, h - 1 do
			local lineY = y + i
			local intensity = (i / h) * pulse

			vt:merge(api.Draw:rectangle(
			x, lineY, w, 1, currentColor
			))
		end

		local centerX, centerY = x + w/2, y + h/2
		local radius = 3 + pulse * (math.min(w, h)/3 - 3)

		for angle = 0, math.pi * 2, 0.2 do
			local pointX = centerX + math.cos(angle) * radius
			local pointY = centerY + math.sin(angle) * radius

			vt:merge(api.Draw:rectangle(
			math.floor(pointX), math.floor(pointY),
			1, 1,
			api.BGColors.Brights.White
			))
		end

		coroutine.yield(vt)

		local delay = 0.07
		local start = os.clock()
		while os.clock() - start < delay do end
	end
end)

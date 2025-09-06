-- i love this animation

local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local centerX, centerY = x + w/2, y + h/2
	local maxRadius = math.min(w, h) / 2 - 2
	local time = 0

	while true do
		local vt = api.VirtualTerminal.new()
		time = time + 0.05

		vt:merge(api.Draw:rectangle(x, y, w, h, api.BGColors.NoBrights.Black))

		local pulse = (math.sin(time) + 1) / 2  
		local radius = 3 + pulse * (maxRadius - 3)

		for angle = 0, math.pi * 2, 0.1 do
			local pointX = centerX + math.cos(angle) * radius
			local pointY = centerY + math.sin(angle) * radius

			vt:merge(api.Draw:rectangle(
			math.floor(pointX), math.floor(pointY),
			1, 1,
			api.BGColors.Brights.Cyan
			))
		end

		vt:merge(api.Draw:rectangle(
		math.floor(centerX), math.floor(centerY),
		1, 1,
		api.BGColors.Brights.White
		))

		coroutine.yield(vt)

		-- local delay = 0.08
		-- local start = os.clock()
		-- while os.clock() - start < delay do end
	end
end)

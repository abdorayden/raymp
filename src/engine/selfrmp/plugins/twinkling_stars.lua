local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local stars = {}

	for i = 1, 40 do
		stars[i] = {
			x = math.random(x, xx),
			y = math.random(y, yy),
			brightness = math.random(),
			speed = math.random(5, 20) / 100
		}
	end

	while true do
		local vt = api.VirtualTerminal.new()

		vt:merge(api.Draw:rectangle(x, y, w, h, api.BGColors.NoBrights.Blue))

		for i, star in ipairs(stars) do
			star.brightness = star.brightness + star.speed
			if star.brightness > 1 then
				star.brightness = 0
			end

			if star.brightness > 0.3 then
				local intensity = math.floor(star.brightness * 255)
				vt:merge(api.Draw:rectangle(
				math.floor(star.x), math.floor(star.y),
				1, 1,
				api.BGColors.Brights.White
				))
			end
		end

		local moonX, moonY = x + w/4, y + h/4
		local moonRadius = 3

		for angle = 0, math.pi * 2, 0.15 do
			local pointX = moonX + math.cos(angle) * moonRadius
			local pointY = moonY + math.sin(angle) * moonRadius

			vt:merge(api.Draw:rectangle(
			math.floor(pointX), math.floor(pointY),
			1, 1,
			api.BGColors.Brights.White
			))
		end

		coroutine.yield(vt)

		local delay = 0.12
		local start = os.clock()
		while os.clock() - start < delay do end
	end
end)

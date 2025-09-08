local api = require("rmp.rmp")

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local raindrops = {}

	for i = 1, 30 do
		raindrops[i] = {
			x = math.random(x, xx),
			y = math.random(y, yy),
			speed = math.random(10, 25) / 10,
			length = math.random(2, 5)
		}
	end

	local vt = api.VirtualTerminal.new()

	vt:merge(api.Draw:rectangle(x, y, w, h, api.BGColors.NoBrights.Blue))

	for i, drop in ipairs(raindrops) do
		drop.y = drop.y + drop.speed

		if drop.y > yy then
			drop.y = y
			drop.x = math.random(x, xx)
		end

		for j = 0, drop.length - 1 do
			if drop.y - j >= y then
				vt:merge(api.Draw:rectangle(
				math.floor(drop.x), math.floor(drop.y - j),
				1, 1,
				api.BGColors.Brights.White
				))
			end
		end
	end


	-- local delay = 0.09
	-- local start = os.clock()
	-- while os.clock() - start < delay do end
	return vt
end

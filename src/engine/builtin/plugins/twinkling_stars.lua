local api = require("rmp.rmp")

local stars = {}

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local vt = api.VirtualTerminal.new()

	if #stars == 0 then
		for i = 1, 40 do
			stars[i] = {
				x = math.random(x, xx),
				y = math.random(y, yy),
				brightness = math.random(),
				speed = math.random(5, 20) / 100
			}
		end
	end

	vt:merge(api.Draw:rectangle(x, y, w, h, api.BGColors.NoBrights.Blue))

	for i, star in ipairs(stars) do
		star.brightness = star.brightness + star.speed

		if star.brightness > 1 then
			star.x = math.random(x, xx)
			star.y = math.random(y, yy)
			star.brightness = 0
			star.speed = math.random(5, 20) / 100
		end

		if star.brightness > 0.3 and 
			star.x >= x and star.x <= xx and 
			star.y >= y and star.y <= yy then
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

		if pointX >= x and pointX <= xx and pointY >= y and pointY <= yy then
			vt:merge(api.Draw:rectangle(
			math.floor(pointX), math.floor(pointY),
			1, 1,
			api.BGColors.Brights.White
			))
		end
	end

	return vt
end

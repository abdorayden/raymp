local api = require("rmp.rmp")

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local bubbles = {}

	for i = 1, 15 do
		bubbles[i] = {
			x = math.random(x, xx),
			y = math.random(y, yy),
			size = math.random(1, 3),
			speed = math.random(5, 15) / 50,
			sway = math.random(-5, 5) / 20
		}
	end
	local vt = api.VirtualTerminal.new()

	vt:merge(api.Draw:rectangle(x, y, w, h, api.BGColors.NoBrights.Blue))

	for i, b in ipairs(bubbles) do
		b.y = b.y - b.speed
		b.x = b.x + b.sway

		if b.y < y then
			b.y = yy
			b.x = math.random(x, xx)
		end

		if b.x < x then b.x = x end
		if b.x > xx then b.x = xx end

		vt:merge(api.Draw:rectangle(
		math.floor(b.x), math.floor(b.y),
		b.size, b.size,
		api.BGColors.Brights.White
		))
	end


	local delay = 0.1
	local start = os.clock()
	while os.clock() - start < delay do end
	return vt
end

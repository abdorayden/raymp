local api = require("rmp.rmp")

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local particles = {}
	local particleCount = 50
	local vt = api.VirtualTerminal.new()

	for i = 1, particleCount do
		particles[i] = {
			x = math.random(x, xx),
			y = math.random(y, yy),
			speed = math.random(1, 3),
			size = math.random(1, 3),
			color = api.BGColors.Brights.Blue
		}
	end

	for i, p in ipairs(particles) do
		p.x = p.x + p.speed
		if p.x > xx then p.x = x end

		local waveHeight = math.sin(p.x * 0.1) * (h / 3)
		p.y = (y + yy) / 2 + waveHeight

		vt:merge(api.Draw:rectangle(
		math.floor(p.x), math.floor(p.y),
		p.size, p.size,
		p.color
		))
	end
	return vt
end

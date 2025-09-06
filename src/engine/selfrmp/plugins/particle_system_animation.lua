-- work but it cross the line (broke)
local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local particles = {}
	local particleCount = 100

	for i = 1, particleCount do
		particles[i] = {
			x = math.random(x, xx),
			y = math.random(y, yy),
			vx = math.random(-20, 20) / 10,
			vy = math.random(-20, 20) / 10,
			life = math.random(50, 200),
			color = api.BGColors.Brights.Blue,
			size = math.random(1, 3)
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

		for i, p in ipairs(particles) do
			p.x = p.x + p.vx
			p.y = p.y + p.vy

			if p.x < x or p.x > xx then p.vx = -p.vx end
			if p.y < y or p.y > yy then p.vy = -p.vy end

			p.life = p.life - 1

			if p.life <= 0 then
				p.x = math.random(x, xx)
				p.y = math.random(y, yy)
				p.vx = math.random(-20, 20) / 10
				p.vy = math.random(-20, 20) / 10
				p.life = math.random(50, 200)
				p.color = bgc[math.random(1, 6)]
			end

			vt:merge(api.Draw:rectangle(
			math.floor(p.x), math.floor(p.y),
			p.size, p.size,
			p.color
			))
		end

		coroutine.yield(vt)

		local delay = 0.05
		local start = os.clock()
		while os.clock() - start < delay do end
	end
end)

local api = require("rmp.rmp")

local particleCount = 100
local bgc = {
	api.BGColors.Brights.Red,
	api.BGColors.Brights.White
}

local vt = api.VirtualTerminal.new()

return function(x, y, xx, yy)
	local particles = {}
	local h, w = (yy - y)-1, (xx - x)-1

	for i = 1, particleCount do
		particles[i] = {
			x = math.random(x, xx),
			y = math.random(y, yy),
			vx = math.random(-20, 20) / 10,
			vy = math.random(-20, 20) / 10,
			life = math.random(50, 200),
			color = bgc[math.random(1, 2)],
			size = math.random(1, 3)
		}
	end


	for i, p in ipairs(particles) do
		p.x = p.x + p.vx
		p.y = p.y + p.vy

		if p.x < x then 
			p.x = x
			p.vx = -p.vx
		elseif p.x + p.size > xx then
			p.x = xx - p.size
			p.vx = -p.vx
		end

		if p.y < y then
			p.y = y
			p.vy = -p.vy
		elseif p.y + p.size > yy then
			p.y = yy - p.size
			p.vy = -p.vy
		end

		p.life = p.life - 1

		if p.life <= 0 then
			p.x = math.random(x, xx)
			p.y = math.random(y, yy)
			p.vx = math.random(-20, 20) / 10
			p.vy = math.random(-20, 20) / 10
			p.life = math.random(50, 200)
			p.color = bgc[math.random(1, 2)]
		end

		vt:merge(api.Draw:rectangle(
		math.floor(p.x), math.floor(p.y),
		p.size, p.size,
		p.color
		))
	end


	-- local delay = 0.05
	-- local start = os.clock()
	-- while os.clock() - start < delay do end
	return vt
end

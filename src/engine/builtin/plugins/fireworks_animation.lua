local api = require("rmp.rmp")

local bgc = {
	api.BGColors.Brights.Red,
	api.BGColors.Brights.Green,
	api.BGColors.Brights.Blue,
	api.BGColors.Brights.Yellow,
	api.BGColors.Brights.Magenta,
	api.BGColors.Brights.Cyan
}

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local fireworks = {}
	local maxFireworks = 5

	local vt = api.VirtualTerminal.new()
	local time = os.clock()

	vt:merge(api.Draw:rectangle(x, y, w, h, api.BGColors.NoBrights.Blue))

	for i = 1, 30 do
		local starX = math.random(x, xx)
		local starY = math.random(y, yy)
		vt:merge(api.Draw:rectangle(starX, starY, 1, 1, api.BGColors.Brights.White))
	end

	if #fireworks < maxFireworks and math.random() < 0.05 then
		local firework = {
			x = math.random(x + 5, xx - 5),
			y = yy,  
			vy = -math.random(15, 25) / 10,
			vx = math.random(-5, 5) / 10,
			state = "rising",  
			particles = {},
			color = bgc[math.random(1, 6)],
			explosionSize = math.random(5, 15)
		}
		table.insert(fireworks, firework)
	end

	for i = #fireworks, 1, -1 do
		local f = fireworks[i]

		if f.state == "rising" then
			vt:merge(api.Draw:rectangle(f.x, f.y, 1, 1, api.BGColors.Brights.White))

			f.x = f.x + f.vx
			f.y = f.y + f.vy
			f.vy = f.vy + 0.1  

			if f.vy >= 0 then
				f.state = "exploding"
				for j = 1, f.explosionSize * 4 do
					local angle = math.random() * math.pi * 2
					local speed = math.random(5, 15) / 10
					table.insert(f.particles, {
						x = f.x,
						y = f.y,
						vx = math.cos(angle) * speed,
						vy = math.sin(angle) * speed,
						life = math.random(20, 40)
					})
				end
			end
		elseif f.state == "exploding" or f.state == "fading" then
			for j = #f.particles, 1, -1 do
				local p = f.particles[j]
				p.x = p.x + p.vx
				p.y = p.y + p.vy
				p.vy = p.vy + 0.05  
				p.life = p.life - 1

				if p.life > 0 and p.x >= x and p.x <= xx and p.y >= y and p.y <= yy then
					local intensity = math.min(1, p.life / 20)
					vt:merge(api.Draw:rectangle(
					math.floor(p.x), math.floor(p.y),
					1, 1, f.color
					))
				else
					table.remove(f.particles, j)
				end
			end

			if #f.particles == 0 then
				table.remove(fireworks, i)
			end
		end
	end


	local delay = 0.05
	local start = os.clock()
	while os.clock() - start < delay do end
	return vt
end

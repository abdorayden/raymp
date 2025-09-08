-- it's broken 2


local api = require("rmp.rmp")

local wavePoints = 36
local waves = {}

return function(x, y, xx, yy)
	local centerX = ((xx - x) / 2)+x
	local centerY = ((yy - y) / 2)+y
	local maxRadius = math.min(xx - centerX, yy - centerY) - 2

	for i = 1, 3 do
		waves[i] = {
			radius = maxRadius * 0.3,
			speed = 0.5 + i * 0.2,
			amplitude = 10 + i * 5,
			phase = math.pi * 2 * i / 3
		}
	end

	local vt = api.VirtualTerminal.new()
	local time = os.clock()

	for i = 0, wavePoints - 1 do
		local angle = (i / wavePoints) * math.pi * 2
		local totalOffset = 0

		for _, wave in ipairs(waves) do
			totalOffset = totalOffset + math.sin(angle * 3 + time * wave.speed + wave.phase) * wave.amplitude
			radius = wave.radius + totalOffset
		end

		local pointX = centerX + math.cos(angle) * radius
		local pointY = centerY + math.sin(angle) * radius

		vt:merge(api.Draw:rectangle(
		math.floor(pointX), math.floor(pointY),
		2, 2,
		api.BGColors.Brights.Cyan
		))

		local angle1 = (i / wavePoints) * math.pi * 2
		local angle2 = ((i + 1) / wavePoints) * math.pi * 2

		local totalOffset1 = 0
		local totalOffset2 = 0

		for _, wave in ipairs(waves) do
			totalOffset1 = totalOffset1 + math.sin(angle1 * 3 + time * wave.speed + wave.phase) * wave.amplitude
			totalOffset2 = totalOffset2 + math.sin(angle2 * 3 + time * wave.speed + wave.phase) * wave.amplitude
			radius1 = wave.radius + totalOffset1
			radius2 = wave.radius + totalOffset2
		end


		local x1 = centerX + math.cos(angle1) * radius1
		local y1 = centerY + math.sin(angle1) * radius1
		local x2 = centerX + math.cos(angle2) * radius2
		local y2 = centerY + math.sin(angle2) * radius2

		vt:merge(api.Draw:line(
		math.floor(x1), math.floor(y1),
		math.floor(x2), math.floor(y2),
		api.BGColors.Brights.Blue
		))
	end

	return vt
end

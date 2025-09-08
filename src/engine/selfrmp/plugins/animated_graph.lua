-- broken
local api = require("rmp.rmp")

local plug = api.plug

local time = 0
local graphPoints = 40
local waveforms = {}
local gridSize = 10

waveforms[1] = {color = api.BGColors.Brights.Cyan, amplitude = 0.4, frequency = 0.8, offset = 0}
waveforms[2] = {color = api.BGColors.Brights.Magenta, amplitude = 0.3, frequency = 1.2, offset = math.pi/2}
waveforms[3] = {color = api.BGColors.Brights.Green, amplitude = 0.2, frequency = 1.6, offset = math.pi}

return function(x, y, xx, yy)

	local h, w = (yy - y), (xx - x)
	local vt = api.VirtualTerminal.new()
	time = time + 0.05

	for i = x, xx, gridSize do
		vt:merge(api.Draw:line(
		i, y, i, yy,
		api.BGColors.NoBrights.DarkGray
		))
	end
	for i = y, yy, gridSize do
		vt:merge(api.Draw:line(
		x, i, xx, i,
		api.BGColors.NoBrights.DarkGray
		))
	end

	local centerY = y + h/2
	vt:merge(api.Draw:line(x, centerY, xx, centerY, api.BGColors.Brights.White))
	vt:merge(api.Draw:line(x + w/2, y, x + w/2, yy, api.BGColors.Brights.White))

	for waveIndex, wave in ipairs(waveforms) do
		local prevX, prevY = nil, nil

		for i = 1, graphPoints do
			local pointX = x + (i-1) * (w / graphPoints)
			local value = 0
			value = value + math.sin(time * wave.frequency + i * 0.1 + wave.offset) * wave.amplitude
			value = value + math.sin(time * wave.frequency * 0.5 + i * 0.05) * wave.amplitude * 0.3

			local pointY = centerY - value * (h/2 - 2)

			vt:merge(api.Draw:rectangle(
			math.floor(pointX), math.floor(pointY),
			2, 2,
			wave.color
			))

			if prevX then
				vt:merge(api.Draw:line(
				math.floor(prevX), math.floor(prevY),
				math.floor(pointX), math.floor(pointY),
				wave.color
				))
			end

			prevX, prevY = pointX, pointY
		end
	end

	for i = 1, 15 do
		local particleX = x + ((time * 5 + i * 20) % w)
		local waveIndex = (i % #waveforms) + 1
		local wave = waveforms[waveIndex]

		local value = math.sin(time * wave.frequency + particleX * 0.05 + wave.offset) * wave.amplitude
		local particleY = centerY - value * (h/2 - 2)

		vt:merge(api.Draw:rectangle(
		math.floor(particleX), math.floor(particleY),
		1, 1,
		api.BGColors.Brights.White
		))
	end

	vt:writeText(x + 2, y + 1, "Waveform Graph", api.FGColors.Brights.White, api.BGColors.NoBrights.Black)
	vt:writeText(x + 2, y + 2, "Time: " .. string.format("%.1f", time), api.FGColors.Brights.White, api.BGColors.NoBrights.Black)
	return vt
end

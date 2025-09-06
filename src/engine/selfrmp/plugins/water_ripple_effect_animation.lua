local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)

	local buffer1 = {}
	local buffer2 = {}

	for i = 1, w do
		buffer1[i] = {}
		buffer2[i] = {}
		for j = 1, h do
			buffer1[i][j] = 0
			buffer2[i][j] = 0
		end
	end

	buffer1[math.floor(w/2)][math.floor(h/2)] = 10
	buffer1[math.floor(w/4)][math.floor(h/4)] = 8
	buffer1[math.floor(3*w/4)][math.floor(3*h/4)] = 8

	while true do
		local vt = api.VirtualTerminal.new()

		for i = 2, w-1 do
			for j = 2, h-1 do
				buffer2[i][j] = ((buffer1[i-1][j] + buffer1[i+1][j] + 
				buffer1[i][j-1] + buffer1[i][j+1]) / 2) - buffer2[i][j]
				buffer2[i][j] = buffer2[i][j] * 0.99

				if buffer2[i][j] > 0.5 then
					local intensity = math.min(255, math.floor(buffer2[i][j] * 25))
					local color = api.BGColors.Brights.Blue  
					vt:merge(api.Draw:rectangle(x + i, y + j, 1, 1, color))
				end
			end
		end

		buffer1, buffer2 = buffer2, buffer1

		coroutine.yield(vt)

		local delay = 0.05
		local start = os.clock()
		while os.clock() - start < delay do end
	end
end)

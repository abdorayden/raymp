local api = require("rmp.rmp")

local A, B, C = 0.0, 0.0, 0.0  -- Rotation angles for the cube

return function(x, y, xx, yy)
	local h, w = (yy - y), (xx - x)
	local distanceFromCam = 100     -- Distance from the camera to the cube
	local horizontalOffset = 0      -- Horizontal offset for projection
	local K1 = h                   -- Projection constant
	local incrementSpeed = 0.07     -- Rotation speed

	-- Create buffers
	local zBuffer = {}  -- Z-buffer for depth calculations
	local buffer = {}   -- Buffer for storing ASCII characters
	local backgroundASCIICode = ' ' -- ASCII character for the background

	-- Initialize buffers
	for i = 1, w * h do
		zBuffer[i] = 0
		buffer[i] = backgroundASCIICode
	end

	-- Calculate X coordinate after projection
	local function calculateX(i, j, k)
		return j * math.sin(A) * math.sin(B) * math.cos(C) - k * math.cos(A) * math.sin(B) * math.cos(C) +
		j * math.cos(A) * math.sin(C) + k * math.sin(A) * math.sin(C) + i * math.cos(B) * math.cos(C)
	end

	-- Calculate Y coordinate after projection
	local function calculateY(i, j, k)
		return j * math.cos(A) * math.cos(C) + k * math.sin(A) * math.cos(C) -
		j * math.sin(A) * math.sin(B) * math.sin(C) + k * math.cos(A) * math.sin(B) * math.sin(C) -
		i * math.cos(B) * math.sin(C)
	end

	-- Calculate Z coordinate after projection
	local function calculateZ(i, j, k)
		return k * math.cos(A) * math.cos(B) - j * math.sin(A) * math.cos(B) + i * math.sin(B)
	end

	-- Calculate and render a surface of the cube
	local function calculateForSurface(cubeX, cubeY, cubeZ, ch)
		local x_val = calculateX(cubeX, cubeY, cubeZ)
		local y_val = calculateY(cubeX, cubeY, cubeZ)
		local z_val = calculateZ(cubeX, cubeY, cubeZ) + distanceFromCam

		if z_val == 0 then
			z_val = 1e-6  -- Avoid division by zero
		end

		local ooz = 1 / z_val

		local xp = math.floor(w / 2 + horizontalOffset + K1 * ooz * x_val * 2)
		local yp = math.floor(h / 2 + K1 * ooz * y_val)

		local idx = xp + yp * w
		if idx >= 1 and idx <= w * h then
			if ooz > zBuffer[idx] then
				zBuffer[idx] = ooz
				buffer[idx] = ch
			end
		end
	end
	local vt = api.VirtualTerminal.new()

	-- Clear the buffers
	for i = 1, w * h do
		zBuffer[i] = 0
		buffer[i] = backgroundASCIICode
	end

	-- Rotate the cube
	A = A + incrementSpeed
	B = B + incrementSpeed
	C = C + 0.01

	-- Render the cubes
	for cubeX = -20, 20, 0.5 do
		for cubeY = -20, 20, 0.5 do
			calculateForSurface(cubeX, cubeY, -20, '@')
			calculateForSurface(20, cubeY, cubeX, '$')
			calculateForSurface(-20, cubeY, -cubeX, '~')
			calculateForSurface(-cubeX, cubeY, 20, '#')
			calculateForSurface(cubeX, -20, -cubeY, ';')
			calculateForSurface(cubeX, 20, cubeY, '+')
		end
	end

	-- Draw the ASCII art to the virtual terminal
	for row = 1, h do
		local line = ""
		for col = 1, w do
			local idx = col + (row - 1) * w
			line = line .. (buffer[idx] or backgroundASCIICode)
		end
		vt:writeText(x, y + row - 1, line, api.FGColors.Brights.Red, api.BGColors.NoBrights.Black)
	end

	return vt
end

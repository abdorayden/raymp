local api = require("rmp.rmp")

local Window = api.Window

-- return function(sound_cfg)
-- this function accept 4 params
return api.quickRoutine(function(x , y , xx , yy)
	-- local vt = api.VirtualTerminal.new()
	-- vt:writeText((xx - x)/2,(yy-y)/2 , "plugin" , nil,nil,nil)
	-- while true do
        	-- coroutine.yield(vt)
	-- end

	local x = x + 1 
	local y = y+1 
	local xx = xx+16 
	local yy = yy+4

	local h , w = (yy-y) , (xx-x)
	local rmpmp3 = "Rmp_Mp3"
	-- local  rh , rw = 1 , #rmpmp3
	local  rh , rw = h/4 , w/4
	local dx , dy = 1 , 1
	local ux , uy = x+1,y

	local bgcolor = api.BGColors.NoBrights.Black
	local fgcolor = api.FGColors.NoBrights.Blue

	while true do
		h , w = (yy-y) , (xx-x)
		ux = ux + dx
		uy = uy + dy
		if ux + rw > w or ux < x then dx = -dx end
		if uy + rh > h or uy < y then dy = -dy end

		local window = Window.new(10):createWindow(
			nil , 
			rw, 
			rh, 
			ux , 
			uy , 
			fgcolor  , 
			bgcolor ,
			api.BoxDrawing.LightBorder , function(rx,ry,rxx,ryy)
				-- local f = api.Frame.new()
				-- 	f:add(
				-- 		api.VirtualTerminal.new():writeText(tonumber(rx + (rxx - rx)/2 - 2) 
				-- 			, tonumber(ry + (ryy - ry)/2) 
				-- 			, "test"
				-- 			, api.FGColors.NoBrights.Black
				-- 			,api.BGColors.Brights.Cyan
				-- 			,api.TextStyle.Bold)
				-- 		-- api.Text.new(
				-- 		-- rmpmp3 , 
				-- 		-- api.TextStyle.Bold , 
				-- 		-- api.FGColors.Brights.Blue , 
				-- 		-- api.BGColors.Brights.Black)
				-- 		-- :setPosition(tonumber((rxx - rx)/2) , tonumber((ryy - ry)/2))
				-- 		-- :asVTerm()
				-- 	)
				-- return f
			end)

		-- window:merge(function(rx,ry,rxx,ryy)
		-- 	local f = api.VirtualTerminal.new(w,h)

		-- 	-- NOTE: the bug he can't merge text to the terminal
		-- 	f:merge(
		-- 		api.Text.new(
		-- 			rmpmp3 , 
		-- 			nil , 
		-- 			api.FGColors.Brights.Blue , 
		-- 			api.BGColors.Brights.Black)
		-- 		:setPosition(tonumber((w/4 - ux)/2) , tonumber((h/4 - uy)/2))
		-- 		:asVTerm()
		-- 	)
		-- 	return f
		-- end)

        	coroutine.yield(window)
	end
end)

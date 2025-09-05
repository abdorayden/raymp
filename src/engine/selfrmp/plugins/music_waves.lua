local api = require("rmp")

main = function(x , y , xx , yy)
	h , w = api.Terminal:getSize()
	local cols = 6
	local wrec = math.floor(w/cols)
	local values = {}
	local bgcolors = {
		api.BGBRed,
		api.BGBMagenta,
		api.BGBCyan,
		api.BGRed,
		api.BGGreen,
		api.BGYellow,
		api.BGBlue,
		api.BGMagenta,
		api.BGCyan,
		api.BGWhite
	}
	local quite = false
	-- local bgcolor = bgcolors[math.random(1 , #bgcolors)]
	local bgcolor = api.BGBRed
	local co = api.quickRoutine(function()
		api.Terminal:hideCursor()
		while true and not quite do
			for i = 1 , cols do
				-- values[i] = math.random(5 , h - 5)
				values[i] = math.random(5 , h - 5)
			end
			api.Window:createWindow(
			api.Text:new("Status" , api.Bold , api.BGGreen):getColoredText(),
			w, h, 1, 1,
			api.FGRed,
			nil,
			api.BoxDrawing.LightBorder,
			function(x,y,xx,yy)
				for i = 1 , cols do
					-- bgcolor = bgcolors[math.random(1 , #bgcolors)]
					bgcolor = api.BGBRed
					api.Draw:rectangle(wrec*(i - 1) + 2*(math.floor(math.sqrt(i)) - 1),h - values[i],wrec - 3,values[i],bgcolor)
				end
			end
			)
			-- must be yielding to jump to other loop between main loop and other function loop
			coroutine.yield()
		end
		api.Terminal:showCursor()
	end)
	api.Terminal:rawMode(true)
	os.execute("stty -icanon -echo < /dev/tty")  -- Unix/Linux
	while not quite do
		coroutine.resume(co)
		-- TODO: add non-blocking to stdin
		-- TODO: make a strong controle to input in linux and windows in raymp
		local key = api.Terminal:handleKey()
		if key == api.KEY_Q or key == api.KEY_SHIFT_Q then
			api.Terminal:clearWindow()
			quite = true
			break
		end
		api.sleep(api.Duration:fromMilsec(200))
	end
	api.Terminal:rawMode(false)
	api.Terminal:showCursor()
end

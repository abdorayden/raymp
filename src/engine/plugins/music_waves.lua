local api = require("../core/rmp")

main = function()
	h , w = api.Terminal:GetSize()
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
	local bgcolor = bgcolors[math.random(1 , #bgcolors)]
	local co = api.QuickRoutine(function()
		api.Terminal:HideCursor()
		while true and not quite do
			for i = 1 , cols do
				values[i] = math.random(5 , h - 5)
			end
			api.Window:CreateWindow(
			api.Text:New("Status" , api.Bold , api.BGGreen):GetColoredText(),
			w, h, 1, 1,
			api.FGRed,
			nil,
			function(x,y,xx,yy)
				for i = 1 , cols do
					bgcolor = bgcolors[math.random(1 , #bgcolors)]
					api.Draw:Rect(wrec*(i - 1) + 2*(math.floor(math.sqrt(i)) - 1),h - values[i],wrec - 3,values[i],bgcolor)
				end
			end
			)
			-- coroutine.yield()
			os.execute("sleep 0.2")
		end
		api.Terminal:ShowCursor()
	end)
	api.Terminal:RawMode(true)
	os.execute("stty -icanon -echo < /dev/tty")  -- Unix/Linux
	while not quite do
		coroutine.resume(co)
		-- TODO: add non-blocking to stdin
		-- TODO: make a strong controle to input in linux and windows in raymp
		local key = api.Terminal:HandleKey()
		if key == api.KEY_Q or key == api.KEY_SHIFT_Q then
			api.Terminal:ClearWindow()
			quite = true
			break
		end
	end
	api.Terminal:RawMode(false)
end

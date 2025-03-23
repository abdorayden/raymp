local api = require("../core/core_lua")
--
--
--	Copyright 2024 by rayden
--		 
--
--		 this script contain structure of default script for engine
--
--

-- add lib rmp for lua to controle api sound functions
-- and make it easy to controle operating system apis 

function main()
	api.Terminal:ClearWindow()
	api.Terminal:HideCursor()
	w , h = api.Terminal:GetSize()
	isplaying = false
	xp = 1
	yp = 1
	while true do
		w , h = api.Terminal:GetSize()
		api.Terminal:RawMode(true)
		api.Window:CreateWindow(
		api.Text:New("Status" , api.Bold , api.BGGreen):GetColoredText(),
		h,
		w,
		1,
		1,
		api.FGRed,
		nil,
		function(x,y,xx,yy)
			if x + xp < xx then
				api.Terminal:MoveTo(math.floor(xx/2) + xp , math.floor(yy/2) + yp)
			end
			if isplaying then
				io.write(api.Text:New("playing" , nil , api.BGGreen):GetColoredText())
			else
				io.write(api.Text:New("stoping" , nil , api.BGRed):GetColoredText())
			end
		end
		)
		local key = api.Terminal:HandleKey()
		if key == api.KEY_A then
			api.Popup:Error("you pressed key a ,, whyyy !! <press any key to remove popup>")
			key = api.Terminal:HandleKey()
		elseif key == api.KEY_CTRL_A then
			api.Popup:Message("you pressed key ctrl-a ,, whyyy !!<press any key to remove popup>")
			key = api.Terminal:HandleKey()
		elseif key == api.KEY_UP then
			api.Popup:Info("im heeereee UP<press any key to remove popup>")
			key = api.Terminal:HandleKey()
		elseif key == api.KEY_J then
			yp = yp + 1
		elseif key == api.KEY_K then
			yp = yp - 1
		elseif key == api.KEY_H then
			xp = xp - 1
		elseif key == api.KEY_L then
			xp = xp + 1

		elseif key == api.KEY_SPACE then
			if isplaying then
				isplaying = false
			else
				isplaying = true
			end
		elseif key == api.KEY_Q or key == api.KEY_SHIFT_Q then
			print("q")
			break
		end
		io.flush()
	end
	api.Terminal:ShowCursor()
	api.Terminal:RawMode(false)
end

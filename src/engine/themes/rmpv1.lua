-- rmp framework
local api = require("../core/rmp")
--
--	Copyright 2024 by rayden
--		 
--
--		 this is UI Style of old rmp version
--
--

-- NOTE: the theme script should accept callback of the plug to render on the window
-- 		if the plugin run on background it should run directly without pass in it to the main function
-- NOTE: the song should handled in master.lua (the engine that i should write it in C) and read the configuration key from init.lua
-- TODO: add the way to reconfigure the plugin and the theme in init.lua


-- NOTE: the callBackPlug should accept 
-- 	x: the start position x for the window
-- 	y: the start position y for the window
-- 	dx: the end position x for the window
-- 	dy: the end position y for the window

function main(callBackPlug)
	local h , w = api.Terminal:GetSize() 

	api.Terminal:HideCursor()
	api.Terminal:ClearWindow()

	local window = api.Window:New(api.BoxDrawing.HeavyBorder)

	local key = api.Terminal.HandleKey()
	while true do
		h , w = api.Terminal:GetSize() 
		window:CreateWindow(
		nil,
		w , h, 1 , 1 ,
		nil , nil, 
		function(x,y,dx,dy)
			local tha_plug_window = api.Window:New(api.BoxDrawing.HeavyBorder)
			tha_plug_window:CreateWindow(
				nil,
				w/2,h/2,w/4,h/8,nil,nil,nil
			)

			local configSong = api.Window:New(api.BoxDrawing.HeavyBorder)
			configSong :CreateWindow(
				nil,
				w/8,h/4,w/8,h/2,nil,nil,nil
			)
		end)

		if key == api.KEY_Q then
			break
		end

		key = api.Terminal:HandleKey()
		api.sleep(100)
	end

	api.Terminal:CloseKey();
	api.Terminal:ShowCursor()
end

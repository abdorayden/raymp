-- rmp framework
local api = require("rmp")

-- create configuration lua handler
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

function main(configuration_object)

	-- TODO: load configuration file
	-- TODO: handle songs in engine

	local h , w = api.Terminal:GetSize() 

	api.Terminal:HideCursor()
	api.Terminal:ClearWindow()

	local key = api.Terminal.HandleKey()
	while true do
		h , w = api.Terminal:GetSize() 
		key = api.Terminal:HandleKey()
		api.Window:CreateWindow(
			nil
			, w 
			, h
			, 1 
			, 1 
			, api.FGBGreen 
			, nil
			, api.BoxDrawing.HeavyBorder
			, function(x,y,dx,dy)
				-- TODO: pass plugins to the callback function
				api.Window:CreateWindow(
					api.Text:New("intern" , api.FGRed , api.SlowBlink):GetColoredText(),
					w/2,h/2,w/4,h/8,nil,nil,api.BoxDrawing.HeavyBorder,nil
				)
				api.Window:CreateWindow(
					api.Text:New("keys" , api.FGRed , api.SlowBlink):GetColoredText(),
					w/4,h/4,w/10,(h-2 - h/4),nil,nil,api.BoxDrawing.HeavyBorder,nil
				)
		end)

		if key == api.KEY_Q then
			break
		end

		api.sleep(500)
	end

	api.Terminal:CloseKey();
	api.Terminal:ShowCursor()
end

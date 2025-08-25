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

	local h , w = api.Terminal:getSize() 

	api.Terminal:hideCursor()
	api.Terminal:clearWindow()

	local key = api.Terminal.handleKey()
	while true do
		h , w = api.Terminal:getSize() 
		key = api.Terminal:handleKey()
		api.Window:windowId(0):createWindow(
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
				local one = api.Window:windowId(1)
				one:createWindow(
					api.Text:new("intern" , api.FGRed , api.SlowBlink):getColoredText(),
					w/2,h/2,w/4,h/8,nil,nil,api.BoxDrawing.HeavyBorder,function(x,y,xx,yy)
						api.Terminal:moveTo(x , y)
						io.write(one:getId())
					end
				)
				local two = api.Window:windowId(2)
				two:createWindow(
					api.Text:new("keys" , api.FGRed , api.SlowBlink):getColoredText(),
					w/4,h/4,w/10,(h-2 - h/4),nil,nil,api.BoxDrawing.HeavyBorder,function(x,y,xx,yy)
						api.Terminal:moveTo(x , y)
						io.write(two:getId())
					end
				)
		end)

		if key == api.KEY_Q then
			break
		end

		io.flush()

		api.sleep(500)
	end

	api.Terminal:closeKey();
	api.Terminal:showCursor()
end

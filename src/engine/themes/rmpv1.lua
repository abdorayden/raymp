-- rmp framework
local api = require("rmp")

local Window = api.Window
local Terminal = api.Terminal
local Text = api.Text
local sleep = api.sleep

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

	-- local duration = api.Duration.new(1000)
	-- print(duration:fromMilsec())

	-- local text = api.Text.new("Hello")
	-- io.write(text:getColoredText())


	-- VTERM

	local h , w = Terminal:getSize()

	-- Initialize
	local vterm = RMP.VirtualTerminal.new(w,h)

	-- Draw something
	local x = 5
	local y = 3
	while Terminal:handleKey() ~= api.KEY_Q do
		vterm:writeText(x + 5, y + 3, "Hello Virtual Terminal!", api.FGRed, nil, api.Bold)
		vterm:drawBox(x, y, 30, 10, api.BoxDrawing.HeavyBorder, api.FGBlue, api.BGBlack)

		-- Update and re-render only when needed
		vterm:writeText(x + 5, y + 3, "This is updated!", api.FGGreen)
		vterm:render()
		vterm:clear()
		if x + 30 <= w then
			x = x + 1
		elseif y + 10 <= h then
			y = y + 1
		else
			x = 5
		end
		sleep(60)
	end


	-- TODO: load configuration file
	-- TODO: handle songs in engine

	-- local h , w = Terminal:getSize() 

	-- Terminal:hideCursor()
	-- Terminal:clearWindow()

	-- local x = 0
	-- local y = h/2
	-- local key = Terminal.handleKey()
	-- while true do
	-- 	Terminal:clearWindow()
	-- 	h , w = Terminal:getSize() 


	-- 	key = Terminal:handleKey()
	-- 	Window:windowId(0):createWindow(
	-- 		nil
	-- 		, w 
	-- 		, h
	-- 		, 1 
	-- 		, 1 
	-- 		, api.FGBGreen 
	-- 		, nil
	-- 		, api.BoxDrawing.HeavyBorder
	-- 		, function(x,y,dx,dy)
	-- 			-- TODO: pass plugins to the callback function
	-- 			local one = Window:windowId(1)
	-- 			one:createWindow(
	-- 				Text:new("intern" , api.FGRed , api.SlowBlink):getColoredText(),
	-- 				w/2,h/2,w/4,h/8,nil,nil,api.BoxDrawing.HeavyBorder,function(x,y,xx,yy)
	-- 					api.Terminal:moveTo(x , y)
	-- 					io.write(one:getId())
	-- 				end
	-- 			)
	-- 			local two = Window:windowId(2)
	-- 			two:createWindow(
	-- 				Text:new("keys" , api.FGRed , api.SlowBlink):getColoredText(),
	-- 				w/4,h/4,w/10,(h-2 - h/4),nil,nil,api.BoxDrawing.HeavyBorder,function(x,y,xx,yy)
	-- 					Terminal:moveTo(x , y)
	-- 					io.write(two:getId())
	-- 				end
	-- 			)
	-- 	end)

	-- 	if key == api.KEY_Q then
	-- 		break
	-- 	end

	-- 	io.flush()

	-- 	sleep(200)
	-- end

	-- Terminal:closeKey();
	-- Terminal:showCursor()
end

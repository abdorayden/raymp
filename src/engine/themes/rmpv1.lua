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
	local otherVterm = RMP.VirtualTerminal.new(w,h)
	local votherVterm = RMP.VirtualTerminal.new(w/2,5)

	-- Draw something
	local x = 5
	local y = 3

	local ox = 61
	local oy = 27


	votherVterm:writeText(1, 1, "This is other!", api.FGCyan)
	Terminal:hideCursor()
	
	local sec = 0
	local s= 0
	local key = api.Terminal:handleKey()

	local warn = false

	while key ~= api.KEY_Q do
		key = api.Terminal:handleKey()
		local window = api.Window.new(1):createWindow(api.Text.new("[ rayden ]" , nil , api.FGYellow , api.BGBlack), 50 , 20 , 25 , 10 ,
		-- local window = api.Window.new(1):createWindow("rayden", 40 , 20 , 40 , 10 ,
			api.FGRed , nil , nil , function(x , y , xx , yy)
				local vterm = RMP.VirtualTerminal.new()
				-- vterm:moveCursor(x + 1 , y + 1)
				local lable = "creating window"
				vterm:writeText(math.floor(xx - x - #lable/2), yy - y - 1 ,lable , nil , api.BGCyan , nil)
				return vterm
			end
		)

		vterm:merge(window)

		if sec < 2*1000 then
			vterm:merge(api.Popup:message("test" , 1 , api.BUTTOM_RIGHT))
			sec = sec + 50
		end


		if key == api.KEY_W then
			warn = true
		end

		if warn then
			if s < 2*1000 then
				vterm:merge(api.Popup:warning("waring you already pressed W key wich mean u need warning popup :))" , 1))
				s = s + 50
			else
				s = 0
				warn = false
			end
		end

		-- window:render()
		-- window:clear()
		-- otherVterm:drawBox("otherVterm" , ox, oy, 30, 10, api.BoxDrawing.LightBorder, api.FGRed, api.BGBlack)
		-- vterm:writeText(x + 5, y + 3, "Hello Virtual Terminal!", api.FGRed, nil, api.Bold)
		-- vterm:drawBox("vterm" , x, y, 30, 10, api.BoxDrawing.HeavyBorder, api.FGBlue, api.BGBlack)

		-- -- Update and re-render only when needed
		-- vterm:writeText(x + 5, y + 3, "This is updated!", api.FGGreen)
		-- vterm:merge(otherVterm , 0 , 0)
		-- vterm:merge(window)
		-- vterm:merge(votherVterm , math.floor(w/2) , 2) -- i got it
		vterm:render()
		vterm:clear()
		-- otherVterm:clear()
		-- votherVterm:clear()


		if key == api.KEY_J then
			oy = oy + 1
		elseif key == api.KEY_L then
			ox = ox + 1
		elseif key == api.KEY_K then
			oy = oy - 1
		elseif key == api.KEY_H then
			ox = ox - 1

		end
		if x + 30 <= w then
			x = x + 1
		elseif y + 10 <= h then
			y = y + 1
		else
			x = 5
		end
		sleep(50)
	end
	api.Terminal:showCursor()
	Terminal:closeKey();

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

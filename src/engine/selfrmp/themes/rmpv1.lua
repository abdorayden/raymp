-- rmp framework
local api = require("rmp.rmp")
local OOP = require("rmp.oop")
local Promise = require("rmp.promises")

local Window = api.Window
local Terminal = api.Terminal
local Text = api.Text
local Frame = api.Frame
local Notify = api.Notify

local Theme = OOP.class("Theme")
do 
	function Theme:constructor(id , cfgPlug)
		self.id = id
		self.cfgPlug = cfgPlug
	end

	function Theme:getPlugFromId()
		if not self.id or self.cfgPlug then
			return nil
		end

		return function(x , y , xx , yy)
			local success, win = coroutine.resume(self.cfgPlug[self.id] , x , y, xx , yy)
			if success and win then
				return win
			end
			return nil
		end
	end

end

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

-- TODO: should handle plugins from init.lua file 


return function (plugs)

	local h , w = Terminal:getSize()

	-- the main frame
	local mainFrame = api.Frame.new()

	-- setting FPS
	mainFrame:setFps(40)

	-- hide cursor on
	Terminal:hideCursor()

	-- read input
	local key = api.Terminal:handleKey()

	-- load hooked plugins
	local changeKeySecondeWindow = plugs:getSwitchKey(2)
	local currentPlugSecondWindow , err = plugs:getNextPlug(2)
	if err then
		currentPlugSecondWindow = function()end
	end

	local changeKeyStatusWindow = plugs:getSwitchKey(3)
	local currentPlugStatusWindow , err = plugs:getNextPlug(3)
	if err then
		currentPlugStatusWindow = function()end
	end

	while key ~= api.KEY_Q do
		-- render
		mainFrame:run(key)
		-- update
		key = api.Terminal:handleKey()
		h , w = Terminal:getSize()

		-- handle configurations keymap
		if changeKeySecondeWindow and key == changeKeySecondeWindow then
			currentPlugSecondWindow = plugs:getNextPlug(2)
		end

		if changeKeyStatusWindow and key == changeKeyStatusWindow then
			currentPlugStatusWindow = plugs:getNextPlug(3)
		end

		do -- later
			-- id 0 means global window or entire window width and height
			-- local success, win = coroutine.resume(cfgObj[1], 2 , 3 , w/2-1 , h/2-1)
			-- if success and win then
			-- mainFrame:add(win)
			-- end

			-- local s, text = coroutine.resume(TEXTPlug)
			-- if s and text then
			-- 	mainFrame:add(text)
			-- end
			-- local su, ap = coroutine.resume(AnotherPlug)
			-- if su and ap then
			-- 	mainFrame:add(ap)
			-- end
		end

		-- init component
		local window = Window.new(1):createWindow(nil, w , h , 1 , 2 , nil , nil , api.BoxDrawing.HeavyBorder , function(x,y,xx,yy)

			local lw = xx-x
			local lh = yy-y

			local x = math.floor(lw/8)
			local y = math.floor(lh/8) + 2
			local w = math.floor(lw - (lw/4))
			local h = math.floor(lh - (lh/2))

			local secondWindow = Window.new(2)
				-- TODO: add checks for the type of the title
				:createWindow(
					Text.new("[ rmp ]" 
						, nil 
						, api.FGColors.Brights.Red
						, api.BGColors.NoBrights.Black)
					, w
					, h
					, x
					, y
					, nil 
					, nil 
					, nil
					-- inject plug directly here and implemens Plug class to simplify all of this
					, function(xxx,yyy,xxxx,yyyy)
						if type(currentPlugSecondWindow) == "function" then
							mainFrame:add(currentPlugSecondWindow(xxx,yyy,xxxx,yyyy) , xxx , yyy)
						end
						return nil
					end
			)

			local statusWindow = Window.new(3):createWindow(
				nil,
				lw/4,
				lh/2 - lh/8 - 1,
				2,
				lh/8 + lh - (lh/2) + 2 , nil , nil , nil , function(ox , oy , oxx , oyy)
					if type(currentPlugStatusWindow) == "function" then
						mainFrame:add(currentPlugStatusWindow(ox,oy,oxx,oyy))
					end
					return nil

				end)

			mainFrame:add(statusWindow)
			mainFrame:add(secondWindow)

			return nil
		end)

		mainFrame:resize(w,h)


		-- adding component to the main frame
		mainFrame:add(window)

	end

	-- clean
	api.Terminal:showCursor()
	Terminal:closeKey();

	-- TODO: handle songs in engine
end

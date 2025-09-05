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


-- NOTE: idea
local PlugState = {

}

local PlugManager = function(callback)
	return api.quickRoutine(function() 
		while true do
			coroutine.yield(callback())
		end
	end)
end

local AnotherPlug = PlugManager(function()
 	local vt = api.VirtualTerminal.new()
	vt:writeText(20,5, "testtttt" , api.FGColors.Brights.White , api.BGColors.NoBrights.Blue , api.TextStyle.SlowBlink)
	return vt

end)

local TEXTPlug = PlugManager(function()
	local x = 2
 	local vt = api.VirtualTerminal.new()
	vt:writeText(x,5, "another plug" , api.FGColors.NoBrights.White , api.BGColors.NoBrights.Red , api.TextStyle.Italic)
	x = x + 1
	return vt

end)

return function (cfgObj)

	local h , w = Terminal:getSize()

	-- the main frame
	local mainFrame = api.Frame.new()

	-- setting FPS
	mainFrame:setFps(70)

	-- hide cursor on
	Terminal:hideCursor()

	-- read input
	local key = api.Terminal:handleKey()

	while key ~= api.KEY_Q do

		-- update
		key = api.Terminal:handleKey()
		h , w = Terminal:getSize()

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

			local secondWindow = Window.new(2)
				-- TODO: add checks for the type of the title
				:createWindow(
					Text.new("[ rmp ]" 
						, nil 
						, api.FGColors.Brights.Red
						, api.BGColors.NoBrights.Black)
					, math.floor(lw - (lw/4))
					, math.floor(lh - (lh/2))
					, math.floor(lw/8)
					, math.floor(lh/8)
					, nil 
					, nil 
					, nil
					-- inject plug directly here and implemens Plug class to simplify all of this
					, function(xxx,yyy,xxxx,yyyy)
						-- mainFrame:add(api.VirtualTerminal.new():writeText(xxx + 78 , yyy + 13 , "Hello"))
						if cfgObj[2] then
							local success, win = coroutine.resume(cfgObj[2] , xxx , yyy , xxxx , yyyy)
							if success and win then
								mainFrame:add(win)
							else
								mainFrame:add(api.VirtualTerminal.new():writeText(xxx + 2 , yyy + 2 , "Hello"))
								Notify.new(2 , 70 , "plug error"):error()
							end
						end
						return nil
					end
			)

			mainFrame:add(secondWindow)

			return nil
		end)

		-- adding component to the main frame
		mainFrame:add(window)

		-- render
		mainFrame:run()
	end

	-- clean
	api.Terminal:showCursor()
	Terminal:closeKey();

	-- TODO: handle songs in engine
end

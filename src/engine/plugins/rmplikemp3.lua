local api = require("rmp")

-- return function(sound_cfg)
-- this function accept 4 params
function main(x , y , xx , yy)
	-- TODO: handle the sound from rmp api using sound_cfg param
	local h , w = api.Terminal:getSize() 
	local rmpmp3 = "Rmp_Mp3"
	-- local  rh , rw = 1 , #rmpmp3
	local  rh , rw = h/4 , w/4
	local dx , dy = 2 , 1

	local ux , uy = 1,1

	local bgcolors = {
		api.BGBBlack,
		api.BGBRed,
		api.BGBGreen,
		api.BGBYellow,
		api.BGBBlue,
		api.BGBMagenta,
		api.BGBCyan,
		api.BGBWhite,
		api.BGBlack,
		api.BGRed,
		api.BGGreen,
		api.BGYellow,
		api.BGBlue,
		api.BGMagenta,
		api.BGCyan,
		api.BGWhite
	}
	local fgcolors = {
		api.FGBlack,
		api.FGRed,
		api.FGGreen,
		api.FGYellow,
		api.FGBlue,
		api.FGMagenta,
		api.FGCyan,
		api.FGWhite,
		api.FGBBlack,
		api.FGBRed,
		api.FGBGreen,
		api.FGBYellow,
		api.FGBBlue,
		api.FGBMagenta,
		api.FGBCyan,
		api.FGBWhite
	}
	local bgcolor = bgcolors[math.random(1 , #bgcolors)]
	local fgcolor = fgcolors[math.random(1 , #fgcolors)]

	api.Terminal:hideCursor()
	while true do
		h , w = api.Terminal:getSize() 
		api.Terminal:clearWindow()
		ux = ux + dx
		uy = uy + dy
		if ux + rw > w or ux < 2 then
			dx = -dx
			bgcolor = bgcolors[math.random(1 , #bgcolors)]
			fgcolor = fgcolors[math.random(1 , #fgcolors)]
		end
		if uy + rh > h or uy < 2 then
			dy = -dy
			bgcolor = bgcolors[math.random(1 , #bgcolors)]
			fgcolor = fgcolors[math.random(1 , #fgcolors)]
		end
		api.Window:createWindow(
		"[ " .. api.Text:new("RMP" , api.Bold , bgcolor):getColoredText() .. " ]",
		w , h, 1 , 1 ,
		fgcolor , nil , api.BoxDrawing.HeavyBorder, function (x,y,xx,yy)
			api.Terminal:moveRight(ux)
			api.Terminal:moveDown(uy)

			api.Window:createWindow(nil , w / 4 , h / 4 , ux , uy , fgcolor  , bgcolor ,api.BoxDrawing.HeavyBorder, function(rx,ry,rxx,ryy)
				api.Terminal:moveRight(math.floor((rxx - rx)/2) - 4)
				api.Terminal:moveDown(math.floor((ryy - ry)/2) - 1)
				-- api.Terminal:MoveTo(math.floor(rxx/2) + rx,math.floor(ryy/2) + ry)
				io.write(api.Text:new(rmpmp3 , nil , fgcolor):getColoredText())
				io.flush()
			end)
		end
		)

		if api.Terminal:handleKey() == api.KEY_Q then
			break
		end
		api.sleep(60)
	end
	api.Terminal:showCursor()
	api.Terminal:closeKey()
end

local api = require("../core/core_lua")


function main()
	local h , w = api.Terminal:GetSize() 
	local rmpmp3 = "Rmp_Mp3"
	-- local  rh , rw = 1 , #rmpmp3
	local  rh , rw = h/4 , w/4
	local dx , dy = 2 , 1

	local ux , uy = 1,1

	local colors = {
		api.BGBBlack,
		api.BGBRed,
		api.BGBGreen,
		api.BGBYellow,
		api.BGBBlue,
		api.BGBMagenta,
		api.BGBCyan,
		api.BGBWhite
	}
	local color = colors[math.random(1 , #colors)]

	api.Terminal:HideCursor()
	while true do
		h , w = api.Terminal:GetSize() 
		api.Terminal:ClearWindow()
		ux = ux + dx
		uy = uy + dy
		if ux + rw > w or ux < 2 then
			dx = -dx
			color = colors[math.random(1 , #colors)]
		end
		if uy + rh > h or uy < 2 then
			dy = -dy
			color = colors[math.random(1 , #colors)]
		end
		api.Window:CreateWindow(
		"[ " .. api.Text:New("RMP" , api.Bold , api.BGRed):GetColoredText() .. " ]",
		w , h, 1 , 1 ,
		api.FGGreen , nil, function (x,y,xx,yy)
			api.Terminal:MoveRight(ux)
			api.Terminal:MoveDown(uy)

			api.Window:CreateWindow(nil , w / 4 , h / 4 , ux , uy , api.FGBlue , color , function(rx,ry,rxx,ryy)
				api.Terminal:MoveRight(math.floor((rxx - rx)/2) - 3)
				api.Terminal:MoveDown(math.floor((ryy - ry)/2))
				-- api.Terminal:MoveTo(math.floor(rxx/2) + rx,math.floor(ryy/2) + ry)
				io.write(api.Text:New(rmpmp3 , nil , nil):GetColoredText())
				io.flush()
			end)
		end
		)
		os.execute("sleep 0.05")
	end
	api.Terminal:ShowCursor()
end

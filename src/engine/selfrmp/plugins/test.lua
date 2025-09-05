local api = require("rmp")


function main()
	local h , w = api.Terminal:GetSize()
	api.Terminal:HideCursor()

	while true do
		h , w = api.Terminal:GetSize()
		api.Terminal:ClearWindow()

		api.Window:CreateWindow(nil , w , h , 1 , 1 , nil , nil , api.BoxDrawing.HeavyBorder ,function(x , y , xx , yy)
			-- api.Popup:Error("ST")
			api.Window:CreateWindow("test" , w/2 , h/2 , 2 , 2 , nil , nil , api.BoxDrawing.LightBorder,nil)
		end)
		if api.Terminal:HandleKey() == api.KEY_Q then
			break
		end

		io.flush()
		api.sleep(500)
	end

	api.Terminal:ShowCursor()
	api.Terminal:CloseKey()
end

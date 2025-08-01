-- TODO : require core_lua
function main()
	 text = api.Text:New("100% <3" , api.Bold..api.SlowBlink, api.FGRed)
	api.Terminal:ClearWindow()
	 api.Window:CreateWindow("[ " .. text:GetColoredText() .. " ]" , 102 , 17 , 5 , 10  , api.BGRed , nil , function(x,y)
	 	-- p = api.Text:New("Hi im RayDen welcome to my engine UI" , api.Bold , api.BGBBlue)
	 	-- p:SetPosition(x + 1 , y+2)
	 	-- print(p:GetColoredText())
	 	api.Window:CreateWindow(
			"[ " .. api.Text:New(
				"Yahya 9asssss7aaa" , 
				api.Underline .. api.Italic , 
				api.BGBlue
			):GetColoredText() .." ]" , 
			49 , 
			10 , 
			7 , 
			13 , 
			api.FGBBlue , 
			api.BGRed , 
			function(x,y)
				for i = 14 , 21 do
					api.Terminal:MoveTo(6 + 48 , i)
					io.write(api.song_char_2)
				end
				api.Terminal:MoveTo(6 + 15 , 17)
	 			print(
					api.Text:New(
						"2025-03-16 16:06:11" , 
						api.Bold, 
						api.BGBlue
					):GetColoredText()
				)
			end
		)
	 	api.Window:CreateWindow(
			"[ " .. api.Text:New(
				"Sarra , hind , Nouha , Nada , wafaa" , 
				api.Underline .. api.Italic , 
				api.BGBRed
			):GetColoredText()  .." ]" , 
			49 , 
			10 , 
			56 , 
			13 , 
			api.FGBBlue , 
			api.BGRed  , 
			function(x,y)
				for i = 14 , 21 do
				 	api.Terminal:MoveTo(6 + 50 , i)
				 	io.write(api.song_char_2)
				end

				api.Terminal:MoveTo(6 + 65 , 17)
	 			print(
					api.Text:New(
						"2025-03-16 16:06:11" , 
						api.Bold, 
						api.BGBlue
					):GetColoredText()
				)
			end
		)
		api.Terminal:MoveTo(0,0)
	 end)
end

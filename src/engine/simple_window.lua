local api = require("core/core_lua")
local os  = require("os")

--function main(waves)
------ function main()
------ 	-- -- NOTE: Text works so fine
------ 	-- io.write(text:GetColoredText())
------ 
------ 	--api.Window:CreateWindow("[ " .. text:GetColoredText() .. " ]" , 50 , 25 , 5 , 10  , nil , api.BGBBlue , nil)
------ 	-- api.Popup:Info("<3")
------ 	
------ 	-- test window
------ 	text = api.Text:New("100% <3" , api.Bold..api.SlowBlink, api.FGRed)
------ 	rows , cols = lua_core.Terminal:GetSize()
------ 	api.Terminal:ClearWindow()
------ 	api.Window:CreateWindow("[ " .. text:GetColoredText() .. " ]" , 
------ 		math.floor(cols / 2) , 
------ 		math.floor(rows / 2) , 
------ 		math.floor(cols/4) , 
------ 		math.floor(rows/4) ,
------ 		api.BGRed , nil , function(lu,ld, ru , rd)
------ 		-- p = api.Text:New("Hi im RayDen welcome to my engine UI" , api.Bold , api.BGBBlue)
------ 		-- p:SetPosition(x + 1 , y+2)
------ 		-- print(p:GetColoredText())
------ 		-----  api.Window:CreateWindow(
------ 		-----  "[ " .. api.Text:New(
------ 		-----  "Yahya 9asssss7aaa" , 
------ 		-----  api.Underline .. api.Italic , 
------ 		-----  api.BGBlue
------ 		-----  ):GetColoredText() .." ]" , 
------ 		-----  math.floor(cols / 2) , 
------ 		-----  math.floor(rows / 2) , 
------ 		-----  math.floor(cols/4) , 
------ 		-----  math.floor(rows/4) ,
------ 		-----  api.FGBBlue , 
------ 		-----  api.BGRed , 
------ 		-----  function(x,y)
------ 		-----  	for i = 14 , 21 do
------ 		-----  		api.Terminal:MoveTo(6 + 48 , i)
------ 		-----  		io.write(api.song_char_2)
------ 		-----  	end
------ 		-----  	api.Terminal:MoveTo(6 + 15 , 17)
------ 		-----  	print(
------ 		-----  	api.Text:New(
------ 		-----  	"2025-03-16 16:06:11" , 
------ 		-----  	api.Bold, 
------ 		-----  	api.BGBlue
------ 		-----  	):GetColoredText()
------ 		-----  	)
------ 		-----  end
------ 		-----  )
------ 		-----  api.Window:CreateWindow(
------ 		-----  "[ " .. api.Text:New(
------ 		-----  "poo" , 
------ 		-----  api.Underline .. api.Italic , 
------ 		-----  api.BGBRed
------ 		-----  ):GetColoredText()  .." ]" , 
------ 		-----  49 , 
------ 		-----  10 , 
------ 		-----  56 , 
------ 		-----  13 , 
------ 		-----  api.FGBBlue , 
------ 		-----  api.BGRed  , 
------ 		-----  function(x,y)
------ 		-----  	for i = 14 , 21 do
------ 		-----  		api.Terminal:MoveTo(6 + 50 , i)
------ 		-----  		io.write(api.song_char_2)
------ 		-----  	end
------ 
------ 		-----  	api.Terminal:MoveTo(6 + 65 , 17)
------ 		-----  	print(
------ 		-----  	api.Text:New(
------ 		-----  	"2025-03-16 16:06:11" , 
------ 		-----  	api.Bold, 
------ 		-----  	api.BGBlue
------ 		-----  	):GetColoredText()
------ 		-----  	)
------ 		-----  end
------ 		-----  )
------ 		-----  api.Terminal:MoveTo(0,0)
------ 
------ 	io.flush()
------ 	end)
------ 
------ 	os.execute("sleep 3")
------ 
------ 	-- test popups
------ 	api.Terminal:HideCursor()
------ 	api.Terminal:ClearWindow()
------ 	api.Popup:Info(api.Text:New("infoooo"  , nil , api.BGMagenta):GetColoredText())
------ 	io.flush()
------ 	os.execute("sleep 3")
------ 	api.Terminal:ClearWindow()
------ 	api.Popup:Message(api.Text:New("infoooo"  , nil , api.BGMagenta):GetColoredText())
------ 	io.flush()
------ 	os.execute("sleep 3")
------ 	api.Terminal:ClearWindow()
------ 	api.Popup:Error(api.Text:New("infoooo"  , nil , api.BGMagenta):GetColoredText())
------ 	io.flush()
------ 	os.execute("sleep 3")
------ 	api.Terminal:ClearWindow()
------ 	api.Popup:Warning(api.Text:New("infoooo"  , nil , api.BGMagenta):GetColoredText())
------ 	io.flush()
------ 	api.Terminal:ShowCursor()
------ 	-- api.Window:CreateWindow(text , 50 , 25 , 60 , 30  , api.BGYellow , api.BGBlue)
------ 
------ 	-- api.Terminal:HideCursor()
------ 	-- for i = 0 , 5 do
------ 	--  	api.Terminal:MoveDown(1)
------ 	--  	api.Terminal:MoveRight(1)
------ 	-- end
------ 	-- print("Hello World");
------ 	-- os.execute("sleep 5")
------ 	-- api.Terminal:ShowCursor()
------ 
------ 	-- api.HandleKey('a')
------ 	-- api.Terminal:HideCursor()
------ 	----- while true do
------ 	----- 	api.Terminal:RawMode(true)
------ 	----- 	local c = io.read(1)
------ 	----- 	if api.Terminal:HandleKey(c) == api.KEY_Q then
------ 	----- 		api.Terminal:RawMode(false)
------ 	----- 		break
------ 	----- 	elseif api.Terminal:HandleKey(c) == api.KEY_A then
------ 	----- 		print("a is pressed")
------ 	----- 	elseif api.Terminal:HandleKey(c) == api.KEY_CTRL_A then
------ 	----- 		print("ctrl-a is pressed")
------ 	----- 	elseif api.Terminal:HandleKey(c) == api.KEY_ESCAPE then
------ 	----- 		print("escape is pressed")
------ 	----- 	elseif api.Terminal:HandleKey(c) == api.KEY_UP then
------ 	----- 		print("key-up is pressed")
------ 	----- 	end
------ 	----- end
------ 	-- os.execute("stty raw -echo")  -- Enable raw mode (Linux/macOS)
------ 	-- 
------ 	-- print("Press keys (ESC to exit)...")
------ 	-- 
------ 	-- while true do
------ 	--     local key = io.read(1)  -- Read one character
------ 	-- 
------ 	--     if key == "\27" then  -- Escape key (ASCII 27)
------ 	--         local next1 = io.read(1)  -- Read next character
------ 	--         if next1 == "[" then  -- Arrow keys start with ESC [
------ 	--             local next2 = io.read(1)
------ 	--             if next2 == "A" then
------ 	--                 print("Up Arrow detected")
------ 	--             elseif next2 == "B" then
------ 	--                 print("Down Arrow detected")
------ 	--             elseif next2 == "C" then
------ 	--                 print("Right Arrow detected")
------ 	--             elseif next2 == "D" then
------ 	--                 print("Left Arrow detected")
------ 	--             end
------ 	--         else
------ 	--             print("ESC Key detected. Exiting...")
------ 	--             break
------ 	--         end
------ 	--     else
------ 	--         print("Key pressed:", key)
------ 	--     end
------ 	-- end
------ 	-- 
------ 	-- os.execute("stty sane")  -- Restore terminal settings
------ 	-- api.Terminal:ShowCursor()
------ end

---  function main()
---  -- 	-- Options is implemented
---   	choice = api.Options:AddOption({"one" , "two" , "three"}):SetColorFocus(api.FGBCyan):SetSymblFocus(api.DoubleUnderline .. api.Bold):FocusPos(1):SetMark("(X)" , "( )")
---   	choice:Log(20 , 5)
---   	-- os.execute("sleep 2")
---  	--- api.Terminal:ClearWindow()
---   	choice:Next()
---   	choice:Log(20 , 8)
---   	-- os.execute("sleep 2")
---  	-- api.Terminal:ClearWindow()
---   	choice:Next()
---   	choice:Log(20 , 11)
---   	-- os.execute("sleep 2")
---  	-- api.Terminal:ClearWindow()
---   	choice:Next()
---   	choice:Log(20 , 14)
---   	-- -- os.execute("sleep 3")
---   	-- choice:Prev()
---   	-- choice:Log()
---   	-- -- os.execute("sleep 3")
---   
---   	-- print("selected options is : " .. choice:GetSelected())
---   	-- os.execute("sleep 2")
---  	-- api.Terminal:ClearWindow()
---   	choice:Next()
---   	choice:Log(20 , 17)
---   end

-- function main()
-- 	choice = api.Options:AddOption({
--     "Option 1", "Option 2", "Option 3", "Option 4", "Option 5",
--     "Option 6", "Option 7", "Option 8", "Option 9", "Option 10"
-- }):SetColorFocus(api.FGBCyan):SetSymblFocus(api.DoubleUnderline .. api.Bold):FocusPos(6)
-- 
-- local menu = lua_core.Scroller:New(3,choice)
-- 
-- menu.options:Log()  -- Print first 3 options
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:PrevLine() -- Move selection
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:NextLine() -- Move selection
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:NextLine()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:NextLine()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:NextLine()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:PrevLine()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:PrevLine()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:PrevLine()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:PrevLine()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:PrevContent()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:PrevContent()
-- 
-- menu.options:Log()  -- Updated selection
-- os.execute("sleep 3")
-- api.Terminal:ClearWindow()
-- menu:PrevContent()
-- 
-- 
-- 
-- print("debug :: " .. menu.options.pos)
-- print("selected options is : " .. menu.options:GetSelected())
-- -- menu.options:Next() -- Scroll down
-- -- menu.options:Log()
-- end

-- function main()
	-- -- local x = 1
	-- -- api.Terminal:ClearWindow()
	-- -- api.Terminal:HideCursor()
	-- -- while true do
	-- -- 	api.Terminal:MoveTo(50 , 25)
	-- -- 	if x == #api.BraillePattern then
	-- -- 		x = 1
	-- -- 	end
	-- -- 	io.write(api.BraillePattern[x])
	-- -- 	x = x + 1
	-- -- end
	-- -- api.Terminal:ShowCursor()
	-- api.Popup:Warning("erroooooorr lmok csidicbnshfvbjsdfhvbsdbcshbdvchjbsdfjvhbdsjfhvbkjsdhkbfvkjhsdbfvkjhsdbfvjhsdfbcskidkjbnsjhbdfvfjhsbfncsjdnbcvhjsbdfvjhbsdfkjvhkbsdkjfhkvbgjkdsfhkbvjksdhkbfvjkshdkbfvjksdhfbvlskdfjhbvcniasjdbhfvjhsbedrffilgvjhbfwnesilrhjbigjskdankbfvjklhasebrdjffvhebrdjfhbnvv")

	--api.Draw:Rect(30 , 5 , 50 , 25 , api.BGRed)
		
	--- api.Terminal:ClearWindow()
	--- api.Terminal:HideCursor()
	--- rows , cols = lua_core.Terminal:GetSize()
	--- api.Window:CreateWindow("[ " .. api.Text:New("Marouaa" , api.SlowBlink  ,api.BGRed):GetColoredText() .. " ]", cols / 2 , rows / 2 , cols/4 , rows/4 , api.FGRed , nil , function(x , y , xx , yy)
	--- 	-- api.Terminal:MoveTo(x , y)
	--- 	api.Terminal:MoveTo(math.floor(cols/4) ,math.floor(rows/4))
	--- 	local t = api.Text:New("Hello From rayden music player" , api.Italic .. api.Bold .. api.Underline , api.FGBMagenta)
	--- 	api.Terminal:MoveRight(1)
	--- 	api.Terminal:MoveDown(1)
	--- 	io.write(t:GetColoredText())
	--- end)
	--- os.execute("sleep 5")
	--- api.Terminal:ShowCursor()
	-- api.Draw:Rect(20 , 10 , 50 , 25 , api.BGCyan)
	--- api.Draw:Column(20 , 4 , 30 , api.BGRed)
-- end
function main()
	api.Terminal:ClearWindow()
	api.Terminal:HideCursor()
	w , h = api.Terminal:GetSize()
	isplaying = false
	xp = 1
	yp = 1
	while true do
		w , h = api.Terminal:GetSize()
		api.Terminal:RawMode(true)
		api.Window:CreateWindow(
		api.Text:New("Status" , api.Bold , api.BGGreen):GetColoredText(),
		h,
		w,
		1,
		1,
		api.FGRed,
		nil,
		function(x,y,xx,yy)
			if x + xp < xx then
				api.Terminal:MoveTo(math.floor(xx/2) + xp , math.floor(yy/2) + yp)
			end
			if isplaying then
				io.write(api.Text:New("playing" , nil , api.BGGreen):GetColoredText())
			else
				io.write(api.Text:New("stoping" , nil , api.BGRed):GetColoredText())
			end
		end
		)
		local key = api.Terminal:HandleKey()
		if key == api.KEY_A then
			api.Popup:Error("you pressed key a ,, whyyy !! <press any key to remove popup>")
			key = api.Terminal:HandleKey()
		elseif key == api.KEY_CTRL_A then
			api.Popup:Message("you pressed key ctrl-a ,, whyyy !!<press any key to remove popup>")
			key = api.Terminal:HandleKey()
		elseif key == api.KEY_UP then
			api.Popup:Info("im heeereee UP<press any key to remove popup>")
			key = api.Terminal:HandleKey()
		elseif key == api.KEY_J then
			yp = yp + 1
		elseif key == api.KEY_K then
			yp = yp - 1
		elseif key == api.KEY_H then
			xp = xp - 1
		elseif key == api.KEY_L then
			xp = xp + 1
			
		elseif key == api.KEY_SPACE then
			if isplaying then
				isplaying = false
			else
				isplaying = true
			end
		elseif key == api.KEY_Q or key == api.KEY_SHIFT_Q then
			print("q")
			break
		end
		io.flush()
	end
	api.Terminal:ShowCursor()
	api.Terminal:RawMode(false)
end

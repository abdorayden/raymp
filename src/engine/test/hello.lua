-- local function CTRL_KEY(key)	
-- 	return ((key) and 0x1f)
-- end
-- print(CTRL_KEY(string.char(72)))
-- local function draw_box(title , x, y, width, height, border_color , bg_color)
-- 
-- 	moveto(x, y)
-- 	-- Calculate title position (Lua 5.1+ compatible)
-- 	local title_len = #title
-- 	local padding = math.floor((width - title_len - 2) / 2) -- Fix division
-- 
-- 	io.write(lua_core.Text:New(TL , nil , border_color):GetColoredText() .. string.rep(lua_core.Text:New(H , nil , border_color):GetColoredText(),padding).. title .. string.rep(lua_core.Text:New(H , nil , border_color):GetColoredText(), width - title_len - padding- 2) ..  lua_core.Text:New(TR , nil , border_color):GetColoredText())
-- 
-- 	for i = 1, height - 2 do
-- 		moveto(x, y + i)
-- 		io.write(lua_core.Text:New(V , nil , border_color):GetColoredText() .. string.rep(lua_core.Text:New(" " , nil , bg_color):GetColoredText(), width - 2) .. lua_core.Text:New(V , nil , border_color):GetColoredText())
-- 	end
-- 
-- 	moveto(x, y + height - 1)
-- 	io.write(lua_core.Text:New(BL , nil , border_color):GetColoredText() .. string.rep(lua_core.Text:New(H , nil , border_color):GetColoredText(), width - 2) .. lua_core.Text:New(BR , nil , border_color):GetColoredText())
-- end
-- 
-- function draw_box(x, y, width, height, title, color)
--     -- ANSI escape codes
--     local ESC = string.char(27)
--     local RESET = ESC .. "[0m"        -- Reset color
--     local SET_COLOR = ESC .. "[" .. color .. "m" -- Set text color
-- 
--     -- Box drawing characters
--     local TL = "┌"  -- Top-left corner
--     local TR = "┐"  -- Top-right corner
--     local BL = "└"  -- Bottom-left corner
--     local BR = "┘"  -- Bottom-right corner
--     local H  = "─"  -- Horizontal line
--     local V  = "│"  -- Vertical line
-- 
--     -- Move cursor to (row, col)
--     local function move_cursor(row, col)
--         io.write(ESC .. "[" .. row .. ";" .. col .. "H")
--     end
-- 
--     -- Calculate title position (Lua 5.1+ compatible)
--     local title_len = #title
--     local padding = math.floor((width - title_len - 2) / 2) -- Fix division
-- 
--     -- Draw top border with title
--     move_cursor(y, x)
--     -- io.write(SET_COLOR .. TL .. string.rep(H, padding) .. " " .. title .. " " .. string.rep(H, width - title_len - padding - 4) .. TR)
--     io.write(SET_COLOR .. TL .. string.rep(H, padding) .. title .. string.rep(H, width - title_len - padding - 2) .. TR)
-- 
-- 
--     -- Draw side borders
--     for i = 1, height - 2 do
--         move_cursor(y + i, x)
--         io.write(V .. string.rep(" ", width - 2) .. V)
--     end
-- 
--     -- Draw bottom border
--     move_cursor(y + height - 1, x)
--     io.write(BL .. string.rep(H, width - 2) .. BR .. RESET)
-- end
-- 
-- -- Example usage
-- draw_box(10, 5, 30, 10, " My Box Title iiii ", "34") -- Blue box with a title

--- t = {1,2,3,4,5,6,7}
--- 
--- for i = 1 , #t do
--- 	print(t[i])
--- end
-- function clean_text(s)
--     -- Remove ANSI escape codes (alternative approach)
--     s = s:gsub("\27%[[^m]*m", "")
-- 
--     -- Remove the leading symbol and spaces (match everything before the first letter)
--     s = s:gsub("^[^%w]+%s*", "")
-- 
--     return s
-- end
-- 
-- -- Example usage
-- local s = "\27[31mHello, World!\27[0m"
-- local cleaned = clean_text(s)
-- print(cleaned)  -- Output: Hello, World!



-- function draw_triangle(height, pos_x, pos_y, char)
--     char = char or "*"  -- Default character if none is provided
--     for y = 0, height - 1 do
--         local spaces = height - y - 1  -- Leading spaces
--         local stars = 2 * y + 1  -- Number of characters per row
-- 
--         -- Move cursor to correct position
--         io.write(string.format("\27[%d;%dH", pos_y + y, pos_x + spaces))
-- 
--         -- Draw the row
--         io.write(string.rep(char, stars), "\n")
--     end
-- end
-- 
-- -- Example usage:
-- os.execute("clear")  -- Clear screen for better visualization
-- draw_triangle(10, 20, 5, "*")  -- Triangle with height 10 at (x=20, y=5)

-- Scroller = {}
-- Scroller.__index = Scroller
-- 
-- function Scroller:AddArray(h , data_array)
-- 	-- height
-- 	self.h = h
-- 	-- the data
-- 	self.data = data_array
-- 	self.cur = 0
-- 	self.option = false
-- 	return self
-- end
-- 
-- function Scroller:AddOption(h , option_obj)
-- 	-- height
-- 	self.h = h
-- 	-- the data
-- 	self.data = option_obj
-- 	self.cur = 0
-- 	self.option = true
-- 	return self
-- end
-- 
-- function Scroller:GetSlice()
-- 	local local_data = {}
-- 	local last = math.min(self.h, #self.data)
-- 
-- 	for i = 1, last do
-- 		local_data[i] = self.data[i + self.cur]
-- 	end
-- 	return local_data
-- end
-- 
-- function Scroller:NextLine()
-- 	if self.cur + self.h < #self.data then
-- 		self.cur = self.cur + 1
-- 	end
-- end
-- 
-- function Scroller:PrevLine()
-- 	if self.cur > 0 then
-- 		self.cur = self.cur - 1
-- 	end
-- end
-- 
-- function Scroller:NextContent()
--     local max_start = math.max(0, #self.data - self.h)
--     self.cur = math.min(self.cur + self.h, max_start)
-- end
-- 
-- function Scroller:PrevContent()
--     self.cur = math.max(self.cur - self.h, 0)
-- end
-- 
-- 
-- Options = setmetatable({}, { __index = Scroller }) -- Inherit from Scroller
-- Options.__index = Options
-- 
-- function Options:New(h, options)
--     local obj = setmetatable({}, self)
--     obj:Add(h, options) -- Use Scroller's Add method
--     obj.color = Default
--     obj.symbl = ""
--     obj.pos = 1
--     return obj
-- end
-- 
-- function Options:SetColorFocus(color)
--     self.color = color
--     return self
-- end
-- 
-- function Options:SetSymblFocus(symbl)
--     self.symbl = symbl
--     return self
-- end
-- 
-- function Options:FocusPos(position)
--     self.pos = position or 1
--     local visible_options = self:GetSlice()
--     
--     -- Ensure position is within the visible range
--     if self.pos > #visible_options then
--         self.pos = #visible_options
--     end
-- 
--     local text = visible_options[self.pos]
--     visible_options[self.pos] = Text:New(text, self.symbl, self.color):GetColoredText()
--     return self
-- end
-- 
-- function Options:Next()
--     local visible_options = self:GetSlice()
--     
--     -- Reset previous selection
--     visible_options[self.pos] = cleanTextLocal(visible_options[self.pos])
-- 
--     -- Move selection within the visible area
--     if self.pos < #visible_options then
--         self.pos = self.pos + 1
--     else
--         -- If we reach the last item in the slice, scroll down
--         self:NextLine()
--         self.pos = 1
--     end
-- 
--     self:FocusPos(self.pos)
--     return self
-- end
-- 
-- function Options:Prev()
--     local visible_options = self:GetSlice()
--     
--     -- Reset previous selection
--     visible_options[self.pos] = cleanTextLocal(visible_options[self.pos])
-- 
--     -- Move selection within the visible area
--     if self.pos > 1 then
--         self.pos = self.pos - 1
--     else
--         -- If we reach the first item in the slice, scroll up
--         self:PrevLine()
--         self.pos = #visible_options
--     end
-- 
--     self:FocusPos(self.pos)
--     return self
-- end
-- 
-- function Options:GetSelected()
--     local visible_options = self:GetSlice()
--     return cleanTextLocal(visible_options[self.pos])
-- end
-- 
-- function Options:GetOptions()
--     return self:GetSlice() -- Only return the visible options
-- end
-- 
-- function Options:Log()
--     for _, option in ipairs(self:GetSlice()) do
--         print(option)
--     end
-- end
-- 
-- local menu = Options:New(3, {
--     "Option 1", "Option 2", "Option 3", "Option 4", "Option 5",
--     "Option 6", "Option 7", "Option 8", "Option 9", "Option 10"
-- })
-- 
-- menu:Log()  -- Display first 3 options
-- menu:Next() -- Move selection
-- menu:Log()  -- Display updated selection
-- menu:Next() -- Scroll to the next set
-- menu:Log()
------ local function isWindows()
------     return package.config:sub(1,1) == "\\"
------ end
------ 
------ local function setRawMode(enable)
------     if isWindows() then
------         os.execute("chcp 65001 > nul") -- Set UTF-8 for proper character support
------         if enable then
------             os.execute("mode con:cols=80 lines=25") -- Ensure correct terminal mode
------         end
------     else
------         if enable then
------             os.execute("stty -echo raw") -- Enable raw mode (no enter needed)
------         else
------             os.execute("stty echo cooked") -- Restore normal input mode
------         end
------     end
------ end
------ 
------ local function CTRL_KEY(key)	
------ 	return string.byte(key) and 0x1f
------ end
------ 
------ local function readKey()
------     setRawMode(true)
------     local key
------ 
------     if isWindows() then
------ 	    -- fix the windows version
------         os.execute("for /f \"delims=\" %A in ('xcopy /w /l /d nul nul 2^>nul') do @set /p key=") 
------         key = io.read(1) -- Windows workaround (slow)
------     else
------         key = io.read(1) -- Read one character (no Enter needed)
------ 
------         if key == "\27" then -- Handle escape sequences (arrow keys)
------             local seq = io.read(2)
------             if seq == "[A" then key = "UP"
------             elseif seq == "[B" then key = "DOWN"
------             elseif seq == "[C" then key = "RIGHT"
------             elseif seq == "[D" then key = "LEFT"
------             else key = "ESC" end
------         elseif key == "\127" then key = "BACKSPACE"
------         elseif key == " " then key = "SPACE"
------         elseif key == "\n" then key = "ENTER"
------         elseif key == "\t" then key = "TAB"
------ 	elseif key == "\1" then key = "CTRL+A"  
------ 	elseif key == "\2" then key = "CTRL+B"  
------ 	elseif key == "\5" then key = "CTRL+E"  
------ 	elseif key == "\6" then key = "CTRL+F"  
------ 	elseif key == "\7" then key = "CTRL+G"  
------ 	elseif key == "\8" then key = "CTRL+H"
------ 			
------ 	elseif key == "\9" then key = "CTRL+I"  
------ 	elseif key == "\10" then key= "CTRL+J"  
------ 	elseif key == "\11" then key= "CTRL+K"  
------ 	elseif key == "\12" then key= "CTRL+L"
------ 			
------ 	elseif key == "\13" then key= "CTRL+M"  
------ 	elseif key == "\14" then key= "CTRL+N"  
------ 	elseif key == "\15" then key= "CTRL+O"  
------ 	elseif key == "\16" then key= "CTRL+P"
------ 			
------ 	elseif key == "\17" then key= "CTRL+Q"  
------ 	elseif key == "\18" then key= "CTRL+R"  
------ 	elseif key == "\19" then key= "CTRL+S"  
------ 	elseif key == "\20" then key= "CTRL+T"
------ 			
------ 	elseif key == "\21" then key= "CTRL+U"  
------ 	elseif key == "\22" then key= "CTRL+V"  
------ 	elseif key == "\23" then key= "CTRL+W"  
------ 	elseif key == "\24" then key= "CTRL+X"
------ 			
------ 	elseif key == "\25" then key= "CTRL+Y"  
------ 	elseif key == "\26" then key= "CTRL+Z"
------ 
------ 
------         elseif key == "\4" then key = "CTRL+D"
------         elseif key == "\3" then
------             key = "CTRL+C"
------             setRawMode(false)
------             os.exit()
------         end
------     end
------ 
------     setRawMode(false)
------     return key
------ end
------ 
------ -- Usage
------ print("Press any key (Ctrl+C to exit):")
------ while true do
------     local key = readKey()
------     if key then print("Key:" ..  key) end
------ end
local function isWindows()
    return package.config:sub(1,1) == "\\"
end

local function setRawMode(enable)
    if isWindows() then
        os.execute("chcp 65001 > nul") -- Ensure UTF-8 encoding for Windows
    else
        if enable then
            os.execute("stty -echo raw") -- Enable raw mode (no Enter needed)
        else
            os.execute("stty echo cooked") -- Restore normal mode
        end
    end
end

local function readKey()
    setRawMode(true)
    local key = io.read(1) -- Read one character

    -- ASCII mappings for Ctrl keys
    local ctrlKeys = {
        ["\1"] = "CTRL+A", ["\2"] = "CTRL+B", ["\3"] = "CTRL+C", ["\4"] = "CTRL+D",
        ["\5"] = "CTRL+E", ["\6"] = "CTRL+F", ["\7"] = "CTRL+G", ["\8"] = "CTRL+H",
        ["\9"] = "CTRL+I", ["\10"] = "CTRL+J", ["\11"] = "CTRL+K", ["\12"] = "CTRL+L",
        ["\13"] = "CTRL+M", ["\14"] = "CTRL+N", ["\15"] = "CTRL+O", ["\16"] = "CTRL+P",
        ["\17"] = "CTRL+Q", ["\18"] = "CTRL+R", ["\19"] = "CTRL+S", ["\20"] = "CTRL+T",
        ["\21"] = "CTRL+U", ["\22"] = "CTRL+V", ["\23"] = "CTRL+W", ["\24"] = "CTRL+X",
        ["\25"] = "CTRL+Y", ["\26"] = "CTRL+Z"
    }

    -- Check for special Ctrl combinations
    if key == "-" then
        key = "CTRL+-"
    elseif key == "=" or key == "+" then
        key = "CTRL++"
    elseif ctrlKeys[key] then
        key = ctrlKeys[key]
        if key == "CTRL+C" then
            setRawMode(false)
            os.exit() -- Exit program on Ctrl+C
        end
    end

    setRawMode(false)
    return key
end

-- Run the key detection loop
print("Press any key (Ctrl+C to exit):")
while true do
    local key = readKey()
    if key then print("Detected Key:", key) end
end

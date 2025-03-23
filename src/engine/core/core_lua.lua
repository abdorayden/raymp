-- 
--	core_lua.lua 
--

-- module core_lua
lua_core = {}

local io = require("io")

-- os detection
function lua_core.GetOs()
	-- stolen from https://stackoverflow.com/questions/295052/how-can-i-determine-the-os-of-the-system-from-within-a-lua-script
	local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
	if BinaryFormat == "dll" then
		return "Windows"
	elseif BinaryFormat == "so" then
		return "Linux"
	elseif BinaryFormat == "dylib" then
		return "MacOS"
	end
end

global_count_enum = -1

local function enum(reset)
	reset = reset or false

	if reset then
		global_count_enum = -1
	end
	global_count_enum = global_count_enum + 1
	return global_count_enum
end


-- check ansi escape code : https://en.wikipedia.org/wiki/ANSI_escape_code

-- line style
lua_core.Strike		= "\27[9m"
lua_core.Hide		= "\27[8m"
lua_core.SlowBlink 	= "\27[5m"
lua_core.OverUnderline 	= "\27[53m"
lua_core.Underline 	= "\27[4m"
lua_core.DoubleUnderline= "\27[21m"
lua_core.Italic	   	= "\27[3m"
lua_core.Bold	   	= "\27[1m"
lua_core.Regular   	= "\27[0m"

-- colors

-- ForeGround 
lua_core.FGBlack	= "\27[30m"
lua_core.FGRed	 	= "\27[31m" 
lua_core.FGGreen	= "\27[32m"
lua_core.FGYellow	= "\27[33m"
lua_core.FGBlue	 	= "\27[34m"
lua_core.FGMagenta 	= "\27[35m"
lua_core.FGCyan	 	= "\27[36m"
lua_core.FGWhite	= "\27[37m"

-- ForeGround bright
lua_core.FGBBlack	= "\27[90m"
lua_core.FGBRed	 	= "\27[91m" 
lua_core.FGBGreen	= "\27[92m"
lua_core.FGBYellow	= "\27[93m"
lua_core.FGBBlue	= "\27[94m"
lua_core.FGBMagenta 	= "\27[95m"
lua_core.FGBCyan	= "\27[96m"
lua_core.FGBWhite	= "\27[97m"

-- BackGround 
lua_core.BGBlack	= "\27[40m"
lua_core.BGRed	 	= "\27[41m" 
lua_core.BGGreen	= "\27[42m"
lua_core.BGYellow	= "\27[43m"
lua_core.BGBlue	 	= "\27[44m"
lua_core.BGMagenta 	= "\27[45m"
lua_core.BGCyan	 	= "\27[46m"
lua_core.BGWhite	= "\27[47m"

-- BackGround bright
lua_core.BGBBlack	= "\27[100m"
lua_core.BGBRed	 	= "\27[101m" 
lua_core.BGBGreen	= "\27[102m"
lua_core.BGBYellow	= "\27[103m"
lua_core.BGBBlue 	= "\27[104m"
lua_core.BGBMagenta 	= "\27[105m"
lua_core.BGBCyan	= "\27[106m"
lua_core.BGBWhite	= "\27[107m"

-- Imojis
lua_core.File_pos 	= "➯"
lua_core.Pause_start 	= "⏯"
lua_core.Next 		= "⏵"
lua_core.Prev		= "⏴"
lua_core.Ext		= "⏻"
lua_core.Rep 		= "⭯"
lua_core.Pause   	= "⏸"
lua_core.Volume_max	= "🔊"
lua_core.Volume_mute	= "🔇"
lua_core.Volume_low	= "🔈"
lua_core.Volume_med	= "🔉"

lua_core.Single_loop	= "🔂"
lua_core.Playlist_loop	= "🔁"
lua_core.Ones		= "ONES"
lua_core.Shufle		= "🔀"

lua_core.Snow		="❆"
lua_core.Stars		= "✨"

lua_core.Search_emo	="🔎"

lua_core.Song_char_1	="💕"
lua_core.Song_char_2	= "💞"
lua_core.Song_char_3	= "🎵"
lua_core.Song_char_4	= "🎶"
lua_core.Song_char_5	= "💖"

lua_core.Bar_1		= "❚"
lua_core.Bar_2		= "❙"
lua_core.Bar_3		= "❘"

lua_core.Bar_l_to_r_12_5_per	= "▏"
lua_core.Bar_l_to_r_25_per 	= "▎"
lua_core.Bar_l_to_r_37_5_per 	= "▍"
lua_core.Bar_l_to_r_50_per 	= "▌"
lua_core.Bar_l_to_r_62_5_per 	= "▋"
lua_core.Bar_l_to_r_75_per 	= "▊"
lua_core.Bar_l_to_r_87_5_per 	= "▉"

lua_core.Bar_b_to_u_12_5_per	 	= "▇"
lua_core.Bar_b_to_u_25_per 	 	= "▆"
lua_core.Bar_b_to_u_37_5_per 	 	= "▅"
lua_core.Bar_b_to_u_50_per 	 	= "▄"
lua_core.Bar_b_to_u_62_5_per 	 	= "▃"
lua_core.Bar_b_to_u_75_per 	 	= "▂"
lua_core.Bar_b_to_u_87_5_per 	 	= "▁"

lua_core.Bar_Shading_20_per =  " " 
lua_core.Bar_Shading_40_per =  "░" 
lua_core.Bar_Shading_60_per =  "▒" 
lua_core.Bar_Shading_80_per =  "▓" 

lua_core.Bar_100_per 	= "█"

-- lua_core.CheckMark 	= "✔"
-- lua_core.Error 		= "✗"

lua_core.IError 	= "❌"
lua_core.IWarning 	= "⚠️"
lua_core.IMessage 	= "💬"
lua_core.IInfo 		= "ℹ️"

lua_core.BoxDrawing = {
    "─", "│", "┌", "┐", "└", "┘", "├", "┤", "┬", "┴", "┼",
    "═", "║", "╔", "╗", "╚", "╝", "╠", "╣", "╦", "╩", "╬",
    "╭", "╮", "╰", "╯"
}

-- for animation
lua_core.BraillePattern = {
    "⠁", "⠃", "⠇", "⠏", "⠟", "⠿", "⣿", "⡿",
    "⣟", "⣯", "⣷", "⣾", "⣿"
}

lua_core.FG = "38"
lua_core.BG = "48"

function lua_core.ColorFromHex(hex , fg_or_bg)
	fb = fg_or_bg or "38"
	local r , g , b = tonumber(hex:sub(1,2) , 16) , tonumber(hex:sub(3,4) , 16) , tonumber(hex:sub(5,6) , 16)
	return string.format("\27[%s;2;%d;%d;%dm" , fb , r , g , b)
end

lua_core.Default = "\27[0m"

-- TODO: for a moment
local function moveto(x,y)
	io.write("\27["..y..";"..x.."H");
end

lua_core.Text = {}
lua_core.Text.__index = Text

-- constructor
function lua_core.Text:New(text , style , color)
	self.text = text or ""
	self.color = color or lua_core.Default
	self.style = style or lua_core.Default
	self.start_pos = 1
	return self
end

-- method Position in lua used to controle position of the text 
function lua_core.Text:SetPosition(x,y)
	moveto(x , y)
end

-- ColoredText accept text and color and return colored text
function lua_core.Text:GetColoredText()
	return self.style..self.color..self.text..lua_core.Default
end

function lua_core.Text:GetText()
	return self.text
end

function lua_core.Text:FixTextToBox(w)
	local text = string.sub(self.text , self.start_pos , math.floor(w) - 7 + self.start_pos)
	self.start_pos = self.start_pos + math.floor(w) - 6
	return text
end

-- EXPLORER 		= enum(true)
-- STYLES 			= enum()
-- SEEK_RIGHT 		= enum()
-- SEEK_LEFT 		= enum()
-- VOLUME_UP 		= enum()
-- VOLUME_DOWN 		= enum()
-- STATUS 			= enum()
-- PAUSE 			= enum()
-- RESUME 			= enum()
-- SONG_NEXT 		= enum()
-- SONG_PREV 		= enum()
-- PAUSE_RESUME 		= PAUSE | RESUME
-- 
-- CURSOR_MOVE_UP		= enum()
-- CURSOR_MOVE_DOWN 	= enum()
-- 
-- FUZZING_SEARCH 		= enum()
-- DOWNLOAD_OVER_INTERNET 	= enum()
-- SETTINGS 		= enum()
-- manage alboms

-- TODO: package.loadlib (libname, funcname) <= check this package 
------ from C
lua_core.KEY_CTRL_A 	= enum(true)
lua_core.KEY_CTRL_B 	= enum()
lua_core.KEY_CTRL_C 	= enum()      
lua_core.KEY_CTRL_D 	= enum()      
lua_core.KEY_CTRL_E 	= enum()      
lua_core.KEY_CTRL_F 	= enum()      
lua_core.KEY_CTRL_N 	= enum()      
lua_core.KEY_CTRL_O 	= enum()      
lua_core.KEY_CTRL_P 	= enum()      
lua_core.KEY_CTRL_Q 	= enum()      
lua_core.KEY_CTRL_R 	= enum()      
lua_core.KEY_CTRL_Y 	= enum()      
lua_core.KEY_CTRL_G 	= enum() 
lua_core.KEY_CTRL_H 	= enum() 
lua_core.KEY_CTRL_I 	= enum() 
lua_core.KEY_CTRL_K 	= enum() 
lua_core.KEY_CTRL_L 	= enum() 
lua_core.KEY_CTRL_S 	= enum() 
lua_core.KEY_CTRL_T 	= enum() 
lua_core.KEY_CTRL_U 	= enum() 
lua_core.KEY_CTRL_V 	= enum() 
lua_core.KEY_CTRL_W 	= enum() 
lua_core.KEY_CTRL_X 	= enum() 
lua_core.KEY_CTRL_Z 	= enum() 
lua_core.KEY_ENTER 	= enum()
lua_core.KEY_SPACE 	= enum()
lua_core.KEY_ESCAPE 	= enum()
lua_core.KEY_UP 	= enum()
lua_core.KEY_DOWN 	= enum() 
lua_core.KEY_LEFT 	= enum()
lua_core.KEY_RIGHT 	= enum()
lua_core.KEY_TAB 	= enum()	 

lua_core.KEY_A = "a"
lua_core.KEY_B = "b"
lua_core.KEY_C = "c"
lua_core.KEY_D = "d"
lua_core.KEY_E = "e"
lua_core.KEY_F = "f"
lua_core.KEY_M = "m"
lua_core.KEY_N = "n"
lua_core.KEY_O = "o"
lua_core.KEY_P = "p"
lua_core.KEY_Q = "q"
lua_core.KEY_R = "r"
lua_core.KEY_Y = "y"
lua_core.KEY_G = "g"
lua_core.KEY_H = "h"
lua_core.KEY_I = "i"
lua_core.KEY_J = "j"
lua_core.KEY_K = "k"
lua_core.KEY_L = "l"
lua_core.KEY_S = "s"
lua_core.KEY_T = "t"
lua_core.KEY_U = "u"
lua_core.KEY_V = "v"
lua_core.KEY_W = "w"
lua_core.KEY_X = "x"
lua_core.KEY_Z = "z"

lua_core.KEY_PLUS 	= "+"
lua_core.KEY_MINUS 	= "-"
lua_core.KEY_GT 	= ">"
lua_core.KEY_LT 	= "<"

lua_core.KEY_SHIFT_A = "A"
lua_core.KEY_SHIFT_B = "B"
lua_core.KEY_SHIFT_C = "C"
lua_core.KEY_SHIFT_D = "D"
lua_core.KEY_SHIFT_E = "E"
lua_core.KEY_SHIFT_F = "F"
lua_core.KEY_SHIFT_M = "M"
lua_core.KEY_SHIFT_N = "N"
lua_core.KEY_SHIFT_O = "O"
lua_core.KEY_SHIFT_P = "P"
lua_core.KEY_SHIFT_Q = "Q"
lua_core.KEY_SHIFT_R = "R"
lua_core.KEY_SHIFT_Y = "Y"
lua_core.KEY_SHIFT_G = "G"
lua_core.KEY_SHIFT_H = "H"
lua_core.KEY_SHIFT_I = "I"
lua_core.KEY_SHIFT_J = "J"
lua_core.KEY_SHIFT_K = "K"
lua_core.KEY_SHIFT_L = "L"
lua_core.KEY_SHIFT_S = "S"
lua_core.KEY_SHIFT_T = "T"
lua_core.KEY_SHIFT_U = "U"
lua_core.KEY_SHIFT_V = "V"
lua_core.KEY_SHIFT_W = "W"
lua_core.KEY_SHIFT_X = "X"
lua_core.KEY_SHIFT_Z = "Z"
lua_core.KEY_0 = "0"
lua_core.KEY_1 = "1"
lua_core.KEY_2 = "2"
lua_core.KEY_3 = "3"
lua_core.KEY_4 = "4"
lua_core.KEY_5 = "5"
lua_core.KEY_6 = "6"
lua_core.KEY_7 = "7"
lua_core.KEY_8 = "8"
lua_core.KEY_9 = "9"
lua_core.KEY_HASHTAG 		= "#"
lua_core.KEY_DOLAR 		= "$"
lua_core.KEY_PERSANT 		= "%"
lua_core.KEY_STAR 		= "*"
lua_core.KEY_DOT 		= "."
lua_core.KEY_UNDERS 		= "_"
lua_core.KEY_SEMICOL 		= ";"
lua_core.KEY_QUISTION_MARK 	= "?"
lua_core.KEY_AT 		= "@"
lua_core.KEY_OPCURB 		= "{"
lua_core.KEY_CLCURB 		= "}"
lua_core.KEY_BACK_SLASH 	= "\\"
lua_core.KEY_BACKTICK 		= "`"
lua_core.KEY_OPEN_BRAKET 	= "("
lua_core.KEY_CLOSED_BRAKET 	= ")"
lua_core.KEY_BAR 		= "|"
lua_core.KEY_DBL_QUOTE 		= "\""
lua_core.KEY_SINGLE_QOUTE 	= "'"

---------



-- TODO: handle border style
STYLE_ONE_BORDER = enum(true)
STYLE_TWO_BORDER = enum()

DEFAULT_BORDER = STYLE_ONE_BORDER

function lua_core.SetBorder(border)
	if border ~= STYLE_ONE_BORDER or border ~= STYLE_TWO_BORDER then
		DEFAULT_BORDER = STYLE_ONE_BORDER
	else
		DEFAULT_BORDER = border
	end
end

if DEFAULT_BORDER == STYLE_ONE_BORDER then
	TL = "┌"  -- Top-left corner
	TR = "┐"  -- Top-right corner
	BL = "└"  -- Bottom-left corner
	BR = "┘"  -- Bottom-right corner
	H  = "─"  -- Horizontal line
	V  = "│"  -- Vertical line

elseif DEFAULT_BORDER == STYLE_TWO_BORDER then 
	TL  = "╔"  -- Top-left corner
	TR  = "╗"  -- Top-right corner
	BL  = "╚"  -- Bottom-left corner
	BR  = "╝"  -- Bottom-right corner
	H   = "═"  -- Horizontal line
	V   = "║"  -- Vertical line
	BTR = "╠" -- Between-Right
	BTU = "╩" -- Between-Up
	BTD = "╦" -- Between-Down
	BTL = "╣" -- Between-Left
end

local function strip_ansi(text)
	if text == nil then 
		return nil
	end
	return text:gsub("\27%[[%d;]+m", "")
end

local function remove_new_lines_from_str(text)
	if text ~= nil then 
		return string.gsub(text, "[\r\n]", "")
	end
	return nil
end

local function cleanTextLocal(text)
	if text ~= nil then 
		return text:gsub("\27%[[^m]*m", ""):gsub("^[^%w]+%s*", "")
	end
	return nil
end

local function draw_box(title , x, y, width, height, border_color , bg_color)

	local tha_box = ""
	moveto(x, y)
	local title_len = #strip_ansi(title) 
	local padding = math.floor((width - title_len - 2) / 2)

	tha_box = tha_box .. lua_core.Text:New(TL , nil , border_color):GetColoredText() .. string.rep(lua_core.Text:New(H , nil , border_color):GetColoredText(),padding).. title .. string.rep(lua_core.Text:New(H , nil , border_color):GetColoredText(), width - title_len - padding- 2) ..  lua_core.Text:New(TR , nil , border_color):GetColoredText()
	io.write(tha_box)
	io.flush()
	tha_box = ""

	for i = 1, height - 2 do
		moveto(x, y + i)
		tha_box = tha_box .. lua_core.Text:New(V , nil , border_color):GetColoredText() .. string.rep(lua_core.Text:New(" " , nil , bg_color):GetColoredText(), width - 2) .. lua_core.Text:New(V , nil , border_color):GetColoredText()
		io.write(tha_box)
		io.flush()
		tha_box = ""
	end

	moveto(x, y + height - 1)
	tha_box = tha_box .. lua_core.Text:New(BL , nil , border_color):GetColoredText() .. string.rep(lua_core.Text:New(H , nil , border_color):GetColoredText(), width - 2) .. lua_core.Text:New(BR , nil , border_color):GetColoredText()
	io.write(tha_box)
	io.flush()
	tha_box = ""
end

lua_core.Window = {}
lua_core.Window.__index = Window

-- callback function accept 4 agrs 
function lua_core.Window:CreateWindow(title , width , height , x , y , border_color , background_color , callback)
	if title == nil then
		title = ""
	end
	draw_box(title , math.floor(x),math.floor(y),math.floor(width),math.floor(height) , border_color , background_color)

	moveto(x , y)

	if callback ~= nil then
		callback(x , y , x + width , y + height)
	end
end

-- TODO: Handle Terminal  class
lua_core.Terminal = {}
lua_core.Terminal.__index = Terminal

function lua_core.Terminal:ClearWindow()
	io.write("\27[2J")
end
function lua_core.Terminal:MoveTo(x , y)
	if x < 1 then
		x = 1
	elseif y < 1 then
		y = 1
	end
	moveto(x,y)
end
function lua_core.Terminal:MoveUp(x)
	if x < 1 or x == nil then
		x = 1
	end
	io.write("\27[" .. x .. "A");
end
function lua_core.Terminal:MoveDown(x)
	if x < 1  or x == nil then
		x = 1
	end
	io.write("\27[" .. x .. "B");
end
function lua_core.Terminal:MoveLeft(x)
	if x < 1  or x == nil then
		x = 1
	end
	io.write("\27[" .. x .. "D");
end
function lua_core.Terminal:MoveRight(x)
	if x < 1  or x == nil then
		x = 1
	end
	io.write("\27[" .. x .. "C");
end
function lua_core.Terminal:HideCursor()
	io.write("\27[?25l");
end
function lua_core.Terminal:ShowCursor()
	io.write("\27[?25h");
end
function lua_core.Terminal:RawMode(enable)
	if lua_core.GetOs() == "Windows" then
		if enable then
			os.execute("mode con: cols=9999 lines=9999")
		else
			os.execute("mode con: cols=80 lines=25")
		end
	else
		if enable then
			os.execute("stty raw -echo")
		else
			os.execute("stty -raw echo")
		end
	end
end

function lua_core.Terminal:GetSize()
	if lua_core.GetOs() == "Linux" then
		local handle = io.popen("stty size")
		local result = handle:read("*a")
		handle:close()
		local rows, cols = result:match("(%d+)%s+(%d+)")
		return tonumber(rows) , tonumber(cols)
	else
		local handle = io.popen("mode con")
		local result = handle:read("*a")
		handle:close()
		local cols, rows = result:match("Columns:(%d+).*Lines:(%d+)")
		return tonumber(rows) , tonumber(cols)
	end

	return nil , nil
end

-- TODO: make sure that function works on windows
function lua_core.Terminal:HandleKey()
	local char = io.read(1)
        if char == "\27" then -- Handle escape sequences (arrow chars)
            local seq = io.read(2)
            if seq == "[A" then return lua_core.KEY_UP
            elseif seq == "[B" then return lua_core.KEY_DOWN
            elseif seq == "[C" then return lua_core.KEY_RIGHT
            elseif seq == "[D" then return lua_core.KEY_LEFT
            else return lua_core.KEY_ESCAPE
	    end
	elseif char == "\1" then
		return lua_core.KEY_CTRL_A
	elseif char == "\2" then
		return lua_core.KEY_CTRL_B
        elseif key == "\3" then 
		return lua_core.KEY_CTRL_C
        elseif key == "\4" then 
		return lua_core.KEY_CTRL_D
	elseif char == "\5" then
		return lua_core.KEY_CTRL_E
	elseif char == "\6" then 
		return lua_core.KEY_CTRL_F
	elseif char == "\7" then 
		return lua_core.KEY_CTRL_G
	elseif char == "\8" then 
		return lua_core.KEY_CTRL_H
	elseif char == "\9" then 
		return lua_core.KEY_CTRL_I
	elseif char == "\10" then 
		return lua_core.KEY_CTRL_J
	elseif char == "\11" then 
		return lua_core.KEY_CTRL_K
	elseif char == "\12" then 
		return lua_core.KEY_CTRL_L
	elseif char == "\13" then 
		return lua_core.KEY_CTRL_M
	elseif char == "\14" then 
		return lua_core.KEY_CTRL_N
	elseif char == "\15" then 
		return lua_core.KEY_CTRL_O
	elseif char == "\16" then 
		return lua_core.KEY_CTRL_P
	elseif char == "\17" then 
		return lua_core.KEY_CTRL_Q
	elseif char == "\18" then 
		return lua_core.KEY_CTRL_R
	elseif char == "\19" then 
		return lua_core.KEY_CTRL_S
	elseif char == "\20" then 
		return lua_core.KEY_CTRL_T
	elseif char == "\21" then 
		return lua_core.KEY_CTRL_U
	elseif char == "\22" then 
		return lua_core.KEY_CTRL_V
	elseif char == "\23" then 
		return lua_core.KEY_CTRL_W
	elseif char == "\24" then 
		return lua_core.KEY_CTRL_X
	elseif char == "\25" then 
		return lua_core.KEY_CTRL_Y
	elseif char == "\26" then 
		return lua_core.KEY_CTRL_Z

        elseif key == "\n" then
		return lua_core.KEY_ENTER
        elseif key == "\t" then
		return lua_core.KEY_TAB
	elseif char == ' ' then 
		return lua_core.KEY_SPACE
	else return char
	end
	-- os.execute("stty sane")  -- Reset terminal
end

-- TODO: add focus mode
-- TODO: handle Input 
-- TODO: handle Loading  
lua_core.Options = {}
lua_core.Options.__index = Options

-- options : array of options 
function lua_core.Options:AddOption(options)
	self.options = options
	self.color = lua_core.Default
	self.symbl = "" 
	self.pos = 1

	self.mark = false
	self.marked_table = {}
	self.selected = ""
	self.unselected = ""
	return self
end

function lua_core.Options:SetMark(selected , unselected)
	self.selected = selected
	self.unselected = unselected 
	for i = 1 , #self.options do
		self.marked_table[i] = false
	end
	self.mark = true
	return self
end

function lua_core.Options:SetColorFocus(color)
	self.color = color
	return self
end

function lua_core.Options:SetSymblFocus(symbl)
	self.symbl = symbl 
	return self
end

function lua_core.Options:SetOptions(options)
	self.options = options
	return self
end

function lua_core.Options:GetOptions()
	return self.options
end

-- default position
function lua_core.Options:FocusPos(position)
	self.pos = position or 1
	text = self.options[self.pos]
	self.options[self.pos] = lua_core.Text:New(text , self.symbl , self.color):GetColoredText()
	return self
end

function lua_core.Options:Next()
	text = self.options[self.pos]
	self.options[self.pos] = cleanTextLocal(text)
	if self.pos == #self.options then
		self.pos = 1
	else
		self.pos = self.pos + 1
	end
	self:FocusPos(self.pos)
	return self
end

function lua_core.Options:Prev()
	text = self.options[self.pos]
	self.options[self.pos] = cleanTextLocal(text)
	if self.pos == 1 then
		self.pos = #self.options
	else
		self.pos = self.pos - 1
	end
	self:FocusPos(self.pos)
	return self
end

function lua_core.Options:GetSelected()
	self.marked_table[self.pos] = true
	return cleanTextLocal(self.options[self.pos])
end

function lua_core.Options:GetOptions()
	return self.options
end

-- Log method will print the options to standerd out put
function lua_core.Options:Log(x , y)
	lua_core.Terminal:MoveTo(x,y)
	for i = 1 , #self.options do
		if self.marked_table[i] then
			io.write(self.selected)
		else
			io.write(self.unselected)
		end
		io.write(self.options[i])
		lua_core.Terminal:MoveTo(x,y + i)
	end
end

-- handle Layout

-- TODO: handle Drawing rectangle (not window)
lua_core.Draw = {}
lua_core.Draw.__index = Draw

function lua_core.Draw:Rect(x,y,width,height,color)
	moveto(x, y)

	io.write(lua_core.Text:New(" " , nil , color):GetColoredText()  .. string.rep(lua_core.Text:New(" " , nil , color):GetColoredText(), width - 2) ..  lua_core.Text:New(" " , nil , color):GetColoredText())

	for i = 1, height - 2 do
		moveto(x, y + i)
		io.write(lua_core.Text:New(" " , nil , color):GetColoredText() .. string.rep(lua_core.Text:New(" " , nil , color):GetColoredText(), width - 2) .. lua_core.Text:New(" " , nil , color):GetColoredText())
	end

	moveto(x, y + height - 1)
	io.write(lua_core.Text:New(" " , nil , color):GetColoredText() .. string.rep(lua_core.Text:New(" " , nil , color):GetColoredText(), width - 2) .. lua_core.Text:New(" " , nil , color):GetColoredText())
	-- TODO: flush output
	-- TODO: write by buffer
end

function lua_core.Draw:Circle(px, py, r , color)
	for y = -r, r do
		lua_core.Terminal:MoveTo(px , py + y + r)
		for x = -r, r do
			if x * x + y * y <= r * r then
				io.write(lua_core.Text:New("  " , nil ,color):GetColoredText())
			else
				io.write("  ")
			end
		end
	end
end

function lua_core.Draw:Triangle(height, pos_x, pos_y, color)
	char = lua_core.Text:New(" " , nil , color):GetColoredText()
	for y = 0, height - 1 do
		local spaces = height - y - 1
		local stars = 2 * y + 1

		lua_core.Terminal:MoveTo(pos_x + spaces , pos_y + y)
		io.write(string.rep(char, stars), "\n")
	end
end

function lua_core.Draw:Line(x , y, width , color)
	lua_core.Terminal:MoveTo(x,y)
	for i = 0  , width do
		io.write(lua_core.Text:New(" " , nil , color):GetColoredText())
	end
end

function lua_core.Draw:Column(x, y , height , color)
	lua_core.Terminal:MoveTo(x,y)
	for i = 0  , height do
		io.write(lua_core.Text:New(" " , nil , color):GetColoredText())
		lua_core.Terminal:MoveDown(1)
		lua_core.Terminal:MoveLeft(1)
	end
end

-- TODO: handle Bar  

lua_core.Popup = {}
lua_core.Popup.__index = Popup

lua_core.MESSAGE = enum(true)
lua_core.INFO = enum()
lua_core.ERROR = enum()
lua_core.WARNING = enum()

-- TODO: add emojis for each status
function lua_core.Popup:Run(message , title , status , border_color , bg_color)
	rows , cols = lua_core.Terminal:GetSize()
	lua_core.Window:CreateWindow(
		title , 
		cols / 2 , 
		rows / 2 , 
		cols/4 , 
		rows/4 ,
		border_color , 
		bg_color , 
		function(x, y , xx , yy)
			-- TODO: handle emojis here
			local t = lua_core.Text:New(remove_new_lines_from_str(message) , nil , nil)
			lua_core.Terminal:MoveTo(math.floor(cols/4) ,math.floor(rows/4))
			lua_core.Terminal:MoveDown(1)
			lua_core.Terminal:MoveRight(2)
			for i = 1 , math.floor(yy - y) - 2 do
				io.write(t:FixTextToBox(xx - x + 2))
				lua_core.Terminal:MoveTo(math.floor(cols/4) + 2,math.floor(rows/4) + i)
				lua_core.Terminal:MoveDown(1)
			end
		end
	)
end

function lua_core.Popup:Error(message)
	lua_core.Popup:Run(
		message , 
		"[ " .. lua_core.Text:New(
			"ERROR" , 
			lua_core.Bold , 
			lua_core.BGBRed
		):GetColoredText() .. " ]", 
		lua_core.ERROR , 
		lua_core.FGRed , 
		nil
	)
end

function lua_core.Popup:Info(message)
	lua_core.Popup:Run(
		message ,
		"[ " .. lua_core.Text:New(
			"INFO" , 
			lua_core.Bold , 
			lua_core.BGBGreen
		):GetColoredText()  .. " ]", 
		lua_core.INFO , 
		lua_core.FGGreen , 
		nil
	)
end

function lua_core.Popup:Message(message)
	lua_core.Popup:Run(
		message ,  
		"[ " .. lua_core.Text:New(
			"Message" , 
			lua_core.Bold , 
			lua_core.BGBBlue
		):GetColoredText()   .. " ]", 
		lua_core.MESSAGE , 
		lua_core.FGBlue , 
		nil
	)
end

function lua_core.Popup:Warning(message)
	lua_core.Popup:Run(
	message ,  
	"[ " .. lua_core.Text:New(
	"Warning" , 
	lua_core.Bold , 
	lua_core.BGBYellow
	):GetColoredText()   .. " ]", 
	lua_core.WARNING , 
	lua_core.FGYellow , 
	nil
	)
end

-- Scroller class
lua_core.Scroller = {}
lua_core.Scroller.__index = lua_core.Scroller

function lua_core.Scroller:New(h, optObj)
	local obj = setmetatable({}, self)
	obj.h = h
	obj.data = optObj:GetOptions()
	obj.cur = 0
	obj.options = optObj:SetOptions(obj:GetSlice())
	return obj
end

function lua_core.Scroller:GetSlice()
	local local_data = {}
	local last = math.min(self.h, #self.data)

	for i = 1, last do
		local_data[i] = self.data[i + self.cur]
	end
	return local_data
end

function lua_core.Scroller:NextLine()
	if self.cur + self.h < #self.data then
		if self.options.pos < self.h then
			self.options:Next()
		else
			self.cur = self.cur + 1
			self.options:SetOptions(self:GetSlice())
	 		self.options:FocusPos(self.h)
		end
	else
		self.options:Next()
	end
end

function lua_core.Scroller:PrevLine()
	if self.cur > 0 then
		if self.options.pos > 1 then
			self.options:Prev()
		else
			self.cur = self.cur - 1
			self.options:SetOptions(self:GetSlice())
			self.options:FocusPos(1)
		end
	else
		self.options:Prev()
	end
end
function lua_core.Scroller:NextContent()
	local max_start = math.max(0, #self.data - self.h)
	self.cur = math.min(self.cur + self.h, max_start)
	self.options:SetOptions(self:GetSlice())
	self.options:FocusPos(1)
end

function lua_core.Scroller:PrevContent()
	self.cur = math.max(self.cur - self.h, 0)
	self.options:SetOptions(self:GetSlice())
	self.options:FocusPos(1)
end

-- TODO: bind miniaudio
-- TODO: write master.lua for managing lua plugins using lua coroutines

return lua_core

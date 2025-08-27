-- Copyright (c) 2024 Ray Den
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- This Lua module (rmp.lua) provides a comprehensive terminal-based UI framework 
-- with audio playback capabilities. 
-- It's designed to create rich terminal applications with features like:

--
--  RMP api v1.0.0
--
--  NOTE: this api works with lua version 5.4
--
-- I- Core Features
-- 
--     1- Terminal UI Framework:
-- 
--         - Window management with borders and titles
-- 
--         - Text styling with ANSI color codes and formatting
-- 
--         - Popup dialogs (error, info, warning, message)
-- 
--         - Drawing primitives (rectangles, circles, triangles, lines)
-- 
--         - Scrolling content views
-- 
--         - Interactive option menus
-- 
--     2- Audio Playback:
-- 
--         - Audio file loading and playback control
-- 
--         - Volume, speed, and position control
-- 
--         - Playback status monitoring
-- 
--         - Playlist management with different loop modes
-- 
--     3- Cross-Platform Support:
-- 
--         - OS detection (Windows, Linux, MacOS)
-- 
--         - Terminal size detection
-- 
--         - Cursor control
-- 
--         - Keyboard input handling
-- 
-- II- Key Components
-- 
--     1- Text Styling:
-- 
--         - Extensive ANSI escape code support for colors (foreground/background, normal/bright)
-- 
--         - Text styles (bold, italic, underline, etc.)
-- 
--         - Unicode symbols and emojis for UI elements
-- 
--     2- UI Elements:
-- 
--         - Window: Creates bordered terminal windows
-- 
--         - Popup: Pre-styled dialog boxes
-- 
--         - Options: Interactive menu system
-- 
--         - Scroller: Content scrolling mechanism
-- 
--         - Draw: Primitive drawing functions
-- 
--     3- Audio System:
-- 
--         - Sound class for audio file management
-- 
--         - Playback control (play/pause/stop)
-- 
--         - Playlist navigation (next/previous)
-- 
--         - Volume and playback position control
-- 
--         - Metadata access
-- 
--     4- Utility Functions:
-- 
--         - Terminal manipulation (cursor control, clearing)
-- 
--         - Keyboard input handling
-- 
--         - OS detection
-- 
--         - Color conversion (hex to ANSI)
--

-- module core_lua
RMP = {}

-- require library's
-- TODO: add directory handling
local io = require("io")
local keyboard = require("keyboard")
local rmpaudio = require("rmpaudio")
local sleep = require("sleep")
local platform = require("platform")
local directory = require("directory")
local window = require("window")

-- handle enumuration in lua using coroutine yield
global_count_enum = -1
local function enum(reset)
	reset = reset or false

	if reset then
		global_count_enum = -1
	end
	global_count_enum = global_count_enum + 1
	return global_count_enum
end

do	-- os detection
	RMP.LINUX  = enum(true)
	RMP.WINDOWS  = enum()
	RMP.MAC  = enum()
	RMP.UNKOW  = enum()

	function RMP.getOs() -- it will return enum value
		return platform.platform() 
	end
end

RMP.quickRoutine = function(func)
	return coroutine.create(func)
end

-- check ansi escape code : https://en.wikipedia.org/wiki/ANSI_escape_code
-- line style
RMP.Strike		= "\27[9m"
RMP.Hide		= "\27[8m"
RMP.SlowBlink 		= "\27[5m"
RMP.OverUnderline 	= "\27[53m"
RMP.Underline 		= "\27[4m"
RMP.DoubleUnderline	= "\27[21m"
RMP.Italic	   	= "\27[3m"
RMP.Bold	   	= "\27[1m"
RMP.Regular   		= "\27[0m"

-- colors
-- TODO: handle colors using ColorFromHex
-- ForeGround 
RMP.FGBlack		= "\27[30m"
RMP.FGRed	 	= "\27[31m" 
RMP.FGGreen		= "\27[32m"
RMP.FGYellow		= "\27[33m"
RMP.FGBlue	 	= "\27[34m"
RMP.FGMagenta 		= "\27[35m"
RMP.FGCyan	 	= "\27[36m"
RMP.FGWhite		= "\27[37m"

-- ForeGround bright
RMP.FGBBlack		= "\27[90m"
RMP.FGBRed	 	= "\27[91m" 
RMP.FGBGreen		= "\27[92m"
RMP.FGBYellow		= "\27[93m"
RMP.FGBBlue		= "\27[94m"
RMP.FGBMagenta 		= "\27[95m"
RMP.FGBCyan		= "\27[96m"
RMP.FGBWhite		= "\27[97m"

-- BackGround 
RMP.BGBlack		= "\27[40m"
RMP.BGRed	 	= "\27[41m" 
RMP.BGGreen		= "\27[42m"
RMP.BGYellow		= "\27[43m"
RMP.BGBlue	 	= "\27[44m"
RMP.BGMagenta 		= "\27[45m"
RMP.BGCyan	 	= "\27[46m"
RMP.BGWhite		= "\27[47m"

-- BackGround bright
RMP.BGBBlack		= "\27[100m"
RMP.BGBRed	 	= "\27[101m" 
RMP.BGBGreen		= "\27[102m"
RMP.BGBYellow		= "\27[103m"
RMP.BGBBlue 		= "\27[104m"
RMP.BGBMagenta 		= "\27[105m"
RMP.BGBCyan		= "\27[106m"
RMP.BGBWhite		= "\27[107m"

-- Imojis
RMP.File_pos 	= "➯"
RMP.Pause_start 	= "⏯"
RMP.Next 		= "⏵"
RMP.Prev		= "⏴"
RMP.Ext		= "⏻"
RMP.Rep 		= "⭯"
RMP.Pause   	= "⏸"
RMP.Volume_max	= "🔊"
RMP.Volume_mute	= "🔇"
RMP.Volume_low	= "🔈"
RMP.Volume_med	= "🔉"

RMP.Single_loop	= "🔂"
RMP.Playlist_loop	= "🔁"
RMP.Ones		= "ONES"
RMP.Shufle		= "🔀"

RMP.Snow		="❆"
RMP.Stars		= "✨"

RMP.Search_emo	="🔎"

RMP.Song_char_1	="💕"
RMP.Song_char_2	= "💞"
RMP.Song_char_3	= "🎵"
RMP.Song_char_4	= "🎶"
RMP.Song_char_5	= "💖"

RMP.Bar_1		= "❚"
RMP.Bar_2		= "❙"
RMP.Bar_3		= "❘"

RMP.Bar_l_to_r_12_5_per	= "▏"
RMP.Bar_l_to_r_25_per 	= "▎"
RMP.Bar_l_to_r_37_5_per = "▍"
RMP.Bar_l_to_r_50_per 	= "▌"
RMP.Bar_l_to_r_62_5_per = "▋"
RMP.Bar_l_to_r_75_per 	= "▊"
RMP.Bar_l_to_r_87_5_per = "▉"

RMP.Bar_b_to_u_12_5_per	 	= "▇"
RMP.Bar_b_to_u_25_per 	 	= "▆"
RMP.Bar_b_to_u_37_5_per 	= "▅"
RMP.Bar_b_to_u_50_per 	 	= "▄"
RMP.Bar_b_to_u_62_5_per 	= "▃"
RMP.Bar_b_to_u_75_per 	 	= "▂"
RMP.Bar_b_to_u_87_5_per 	= "▁"

RMP.Bar_Shading_00_per =  " " 
RMP.Bar_Shading_25_per =  "░" 
RMP.Bar_Shading_50_per =  "▒" 
RMP.Bar_Shading_75_per =  "▓" 

RMP.Bar_100_per 	= "█"

-- RMP.CheckMark 	= "✔"
-- RMP.Error 		= "✗"

RMP.IError 	= "❌"
RMP.IWarning 	= "⚠️"
RMP.IMessage 	= "💬"
RMP.IInfo 		= "ℹ️"

-- TODO: create table class to create tables

-- TODO: handle this border table later to let plugin developers change the border

RMP.BoxDrawing = {
	LightBorder  = {
		-- Light border set (single-line)
		"─",  -- Light horizontal line (U+2500)
		"│",  -- Light vertical line (U+2502)
		"┌",  -- Light down and right corner (U+250C)
		"┐",  -- Light down and left corner (U+2510)
		"└",  -- Light up and right corner (U+2514)
		"┘",  -- Light up and left corner (U+2518)
		"├",  -- Light vertical and right tee (U+251C)
		"┤",  -- Light vertical and left tee (U+2524)
		"┬",  -- Light down and horizontal tee (U+252C)
		"┴",  -- Light up and horizontal tee (U+2534)
		"┼",  -- Light vertical and horizontal cross (U+253C)
	},
	HeavyBorder = {
		-- Heavy border set (double-line)
		"═",  -- Heavy horizontal line (U+2550)
		"║",  -- Heavy vertical line (U+2551)
		"╔",  -- Heavy down and right corner (U+2554)
		"╗",  -- Heavy down and left corner (U+2557)
		"╚",  -- Heavy up and right corner (U+255A)
		"╝",  -- Heavy up and left corner (U+255D)
		"╠",  -- Heavy vertical and right tee (U+2560)
		"╣",  -- Heavy vertical and left tee (U+2563)
		"╦",  -- Heavy down and horizontal tee (U+2566)
		"╩",  -- Heavy up and horizontal tee (U+2569)
		"╬",  -- Heavy vertical and horizontal cross (U+256C)
	}
}
	-- -- Rounded corners (light)
	-- "╭",  -- Light arc down and right (U+256D)
	-- "╮",  -- Light arc down and left (U+256E)
	-- "╰",  -- Light arc up and right (U+2570)
	-- "╯",   -- Light arc up and left (U+256F)

	-- -- Double-line borders (mix of light and heavy)
	-- "╓",  -- Double right/down (U+2553)
	-- "╖",  -- Double down/left (U+2556)

	-- "╙",  -- Double up/right (U+2559)
	-- "╜",  -- Double up/left (U+255C)
	-- "╫",  -- Double vertical/single horizontal cross (U+256B)
	-- "╪",  -- Single vertical/double horizontal cross (U+256A)

	-- -- Dashed and dotted lines
	-- "┄",  -- Triple-dashed horizontal (U+2504)
	-- "┅",  -- Heavy triple-dashed horizontal (U+2505)
	-- "┆",  -- Triple-dashed vertical (U+2506)
	-- "┇",  -- Heavy triple-dashed vertical (U+2507)
	-- "┈",  -- Quadruple-dashed horizontal (U+2508)
	-- "┉",  -- Heavy quadruple-dashed horizontal (U+2509)
	-- "┊",  -- Quadruple-dashed vertical (U+250A)
	-- "┋",  -- Heavy quadruple-dashed vertical (U+250B)

	-- -- Less common but useful
	-- "╒",  -- Down single/right double (U+2552)
	-- "╕",  -- Down single/left double (U+2555)

	-- "╘",  -- Up single/right double (U+2558)
	-- "╛",  -- Up single/left double (U+255B)
	-- "╞",  -- Vertical single/right double (U+255E)

	-- "╡",  -- Vertical single/left double (U+2561)
	-- "╥",  -- Down heavy/horizontal single (U+2565)

	-- "╨",  -- Up heavy/horizontal single (U+2568)

-- TODO: create class Animation for handling diffrent animation
-- for animation
RMP.BraillePattern = {
    "⠁", "⠃", "⠇", "⠏", "⠟", "⠿", "⣿", "⡿",
    "⣟", "⣯", "⣷", "⣾", "⣿"
}

do 	-- color from hex
	RMP.FG = "38"
	RMP.BG = "48"

	function RMP.colorFromHex(hex , fg_or_bg)
		fb = fg_or_bg or "38"
		local r , g , b = tonumber(hex:sub(1,2) , 16) , tonumber(hex:sub(3,4) , 16) , tonumber(hex:sub(5,6) , 16)
		return string.format("\27[%s;2;%d;%d;%dm" , fb , r , g , b)
	end
end

RMP.Default = "\27[0m"

-- TODO: for a moment
local function moveto(x,y , ret)
	local ret = ret or false
	if ret then
		return "\27["..y..";"..x.."H"
	else
		io.write("\27["..y..";"..x.."H")
	end
end

RMP.Duration = {}
RMP.Duration.__index = Duration
do
	function RMP.Duration:fromSec(sec)
		return sec * 1000
	end

	function RMP.Duration:fromMilsec(sec)
		return sec
	end

end

function RMP.sleep(time)
	sleep.sleep(time)
end

-- Text class used to work with texts
RMP.Text = {}
RMP.Text.__index = Text
do	-- text
	-- constructor
	function RMP.Text:new(text , style , color)
		self.text = text or ""
		self.color = color or RMP.Default
		self.style = style or RMP.Default
		self.start_pos = 1
		return self
	end

	-- method Position in lua used to controle position of the text 
	function RMP.Text:setPosition(x,y)
		moveto(x , y)
	end

	-- ColoredText accept text and color and return colored text
	function RMP.Text:getColoredText()
		return self.style..self.color..self.text..RMP.Default
	end

	function RMP.Text:getText()
		return self.text
	end

	function RMP.Text:fixTextToBox(w)
		local text = string.sub(self.text , self.start_pos , math.floor(w) - 7 + self.start_pos)
		self.start_pos = self.start_pos + math.floor(w) - 6
		return text
	end
end

-- the enumeration value returns from HandleKey input
RMP.KEY_CTRL_A = enum(true) 
RMP.KEY_CTRL_B = enum() 
RMP.KEY_CTRL_C = enum() 
RMP.KEY_CTRL_D = enum() 
RMP.KEY_CTRL_E = enum()
RMP.KEY_CTRL_F = enum() 
RMP.KEY_CTRL_G = enum() 
RMP.KEY_CTRL_H = enum() 
RMP.KEY_CTRL_K = enum() 
RMP.KEY_CTRL_L = enum() 
RMP.KEY_CTRL_M = enum() 
RMP.KEY_CTRL_N = enum() 
RMP.KEY_CTRL_O = enum()
RMP.KEY_CTRL_P = enum() 
RMP.KEY_CTRL_Q = enum() 
RMP.KEY_CTRL_R = enum() 
RMP.KEY_CTRL_S = enum() 
RMP.KEY_CTRL_T = enum()
RMP.KEY_CTRL_U = enum() 
RMP.KEY_CTRL_V = enum() 
RMP.KEY_CTRL_W = enum() 
RMP.KEY_CTRL_X = enum() 
RMP.KEY_CTRL_Y = enum()
RMP.KEY_CTRL_Z = enum()
RMP.KEY_ENTER = enum() 
RMP.KEY_SPACE = enum() 
RMP.KEY_ESCAPE = enum() 
RMP.KEY_UP = enum() 
RMP.KEY_DOWN = enum()
RMP.KEY_LEFT = enum() 
RMP.KEY_RIGHT = enum() 
RMP.KEY_TAB = enum()
RMP.KEY_A = enum() 
RMP.KEY_B = enum() 
RMP.KEY_C = enum() 
RMP.KEY_D = enum() 
RMP.KEY_E = enum() 
RMP.KEY_F = enum() 
RMP.KEY_G = enum() 
RMP.KEY_H = enum()
RMP.KEY_I = enum() 
RMP.KEY_J = enum() 
RMP.KEY_K = enum() 
RMP.KEY_L = enum() 
RMP.KEY_M = enum() 
RMP.KEY_N = enum() 
RMP.KEY_O = enum() 
RMP.KEY_P = enum()
RMP.KEY_Q = enum() 
RMP.KEY_R = enum() 
RMP.KEY_S = enum() 
RMP.KEY_T = enum() 
RMP.KEY_U = enum() 
RMP.KEY_V = enum() 
RMP.KEY_W = enum() 
RMP.KEY_X = enum()
RMP.KEY_Y = enum() 
RMP.KEY_Z = enum()
RMP.KEY_SHIFT_A = enum() 
RMP.KEY_SHIFT_B = enum() 
RMP.KEY_SHIFT_C = enum() 
RMP.KEY_SHIFT_D = enum() 
RMP.KEY_SHIFT_E = enum()
RMP.KEY_SHIFT_F = enum() 
RMP.KEY_SHIFT_G = enum() 
RMP.KEY_SHIFT_H = enum() 
RMP.KEY_SHIFT_I = enum() 
RMP.KEY_SHIFT_J = enum()
RMP.KEY_SHIFT_K = enum() 
RMP.KEY_SHIFT_L = enum() 
RMP.KEY_SHIFT_M = enum() 
RMP.KEY_SHIFT_N = enum() 
RMP.KEY_SHIFT_O = enum()
RMP.KEY_SHIFT_P = enum() 
RMP.KEY_SHIFT_Q = enum() 
RMP.KEY_SHIFT_R = enum() 
RMP.KEY_SHIFT_S = enum() 
RMP.KEY_SHIFT_T = enum()
RMP.KEY_SHIFT_U = enum() 
RMP.KEY_SHIFT_V = enum() 
RMP.KEY_SHIFT_W = enum() 
RMP.KEY_SHIFT_X = enum() 
RMP.KEY_SHIFT_Y = enum()
RMP.KEY_SHIFT_Z = enum()
RMP.KEY_0 = enum() 
RMP.KEY_1 = enum() 
RMP.KEY_2 = enum() 
RMP.KEY_3 = enum() 
RMP.KEY_4 = enum() 
RMP.KEY_5 = enum()
RMP.KEY_6 = enum() 
RMP.KEY_7 = enum() 
RMP.KEY_8 = enum() 
RMP.KEY_9 = enum()
RMP.KEY_PLUS = enum() 
RMP.KEY_MINUS = enum() 
RMP.KEY_GT = enum() 
RMP.KEY_LT = enum() 
RMP.KEY_HASHTAG = enum()
RMP.KEY_DOLAR = enum() 
RMP.KEY_PERSANT = enum() 
RMP.KEY_STAR = enum() 
RMP.KEY_DOT = enum() 
RMP.KEY_UNDERS = enum()
RMP.KEY_SEMICOL = enum() 
RMP.KEY_QUISTION_MARK = enum() 
RMP.KEY_AT = enum() 
RMP.KEY_OPCURB = enum()
RMP.KEY_CLCURB = enum() 
RMP.KEY_BACK_SLASH = enum() 
RMP.KEY_BACKTICK = enum() 
RMP.KEY_OPEN_BRAKET = enum()
RMP.KEY_CLOSED_BRAKET = enum() 
RMP.KEY_BAR = enum() 
RMP.KEY_DBL_QUOTE = enum() 
RMP.KEY_SINGLE_QOUTE = enum()
RMP.NONE = enum()

do	-- local functions
	function strip_ansi(text)
		if text == nil then 
			return nil
		end
		return text:gsub("\27%[[%d;]+m", "")
	end

	function remove_new_lines_from_str(text)
		if text ~= nil then 
			return string.gsub(text, "[\r\n]", "")
		end
		return nil
	end

	function cleanTextLocal(text)
		if text ~= nil then 
			return text:gsub("\27%[[^m]*m", ""):gsub("^[^%w]+%s*", "")
		end
		return nil
	end

	function draw_box(border_style , title , x, y, width, height, border_color , bg_color)
		local tha_box = ""

		if border_style == nil or type(border_style) ~= 'table' or border_style[1] == nil then
			TL = RMP.BoxDrawing.LightBorder[3] -- "┌" Top-left corner
			TR = RMP.BoxDrawing.LightBorder[4] -- "┐" Top-right corner
			BL = RMP.BoxDrawing.LightBorder[5] -- "└" Bottom-left corner
			BR = RMP.BoxDrawing.LightBorder[6] -- "┘" Bottom-right corner
			H  = RMP.BoxDrawing.LightBorder[1] -- "─" Horizontal line
			V  = RMP.BoxDrawing.LightBorder[2] -- "│" Vertical line
		else
			TL = border_style[3] -- "┌" Top-left corner
			TR = border_style[4] -- "┐" Top-right corner
			BL = border_style[5] -- "└" Bottom-left corner
			BR = border_style[6] -- "┘" Bottom-right corner
			H  = border_style[1] -- "─" Horizontal line
			V  = border_style[2] -- "│" Vertical line
		end

		tha_box  = tha_box .. moveto(x, y , true)
		local title_len = #strip_ansi(title) 
		local padding = math.floor((width - title_len - 2) / 2)

		tha_box = tha_box .. RMP.Text:new(TL , nil , border_color):getColoredText() .. string.rep(RMP.Text:new(H , nil , border_color):getColoredText(),padding).. title .. string.rep(RMP.Text:new(H , nil , border_color):getColoredText(), width - title_len - padding- 2) ..  RMP.Text:new(TR , nil , border_color):getColoredText()

		for i = 1, height - 2 do
			tha_box  = tha_box .. moveto(x, y + i, true)
			tha_box = tha_box .. RMP.Text:new(V , nil , border_color):getColoredText() .. string.rep(RMP.Text:new(" " , nil , bg_color):getColoredText(), width - 2) .. RMP.Text:new(V , nil , border_color):getColoredText()
		end

		tha_box  = tha_box .. moveto(x, y + height - 1, true)
		tha_box = tha_box .. RMP.Text:new(BL , nil , border_color):getColoredText() .. string.rep(RMP.Text:new(H , nil , border_color):getColoredText(), width - 2) .. RMP.Text:new(BR , nil , border_color):getColoredText()
		io.write(tha_box)
		io.flush()
		tha_box = ""
	end
end

RMP.Window = {}
RMP.Window.__index = Window
do 	-- creating window
	-- callback function accept 4 agrs 

	function RMP.Window:windowId(id)
		self.id = id
		return self
	end

	function RMP.Window:getId()
		return self.id
	end

	function RMP.Window:createWindow(title , width , height , x , y , border_color , background_color , border_style , callback)
		local title = title or ""

		draw_box(border_style 
			, title 
			, math.floor(x)
			,math.floor(y)
			,math.floor(width)
			,math.floor(height) 
			, border_color 
			, background_color
		)

		moveto(x + 1 , y + 1)

		if callback ~= nil and type(callback) == "function" then
			callback(x , y , x + width , y + height)
		end
	end
end

-- TODO: use  virtual terminal for more performence
-- TODO: should integrate VirtualTerminal to all components (Window , Terminal , Text , ...)
-- Virtual Terminal Buffer
RMP.VirtualTerminal = {}
RMP.VirtualTerminal.__index = RMP.VirtualTerminal

function RMP.VirtualTerminal:new(width, height)
	local obj = setmetatable({}, self)
	local h , w = window.get_size()
	obj.width = width or w
	obj.height = height or h
	obj.buffer = {}
	obj.dirty = false
	obj.cursor = {x = 1, y = 1}
	obj:clear()
	return obj
end

function RMP.VirtualTerminal:clear()
	for y = 1, self.height do
		self.buffer[y] = self.buffer[y] or {}
		for x = 1, self.width do
			self.buffer[y][x] = {char = " ", fg = nil, bg = nil, style = nil}
		end
	end
	self.dirty = true
end

function RMP.VirtualTerminal:ensureBuffer(y, x)
	y = math.max(1, math.min(y, self.height))
	x = math.max(1, math.min(x, self.width))
	if not self.buffer[y] then
		self.buffer[y] = {}
	end
	if not self.buffer[y][x] then
		self.buffer[y][x] = {char = " ", fg = nil, bg = nil, style = nil}
	end
end

function RMP.VirtualTerminal:setChar(x, y, char, fg, bg, style)
	if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
		self:ensureBuffer(y, x)
		self.buffer[y][x] = {
			char = char or " ",
			fg = fg,
			bg = bg,
			style = style
		}
		self.dirty = true
	end
end

function RMP.VirtualTerminal:writeText(x, y, text, fg, bg, style)
	for i = 1, #text do
		local char = text:sub(i, i)
		self:setChar(x + i - 1, y, char, fg, bg, style)
	end
	self.dirty = true
end

function RMP.VirtualTerminal:drawBox(x, y, width, height, border_style, fg, bg)
	if border_style == nil or type(border_style) ~= 'table' or border_style[1] == nil then
		TL = RMP.BoxDrawing.LightBorder[3] -- "┌" Top-left corner
		TR = RMP.BoxDrawing.LightBorder[4] -- "┐" Top-right corner
		BL = RMP.BoxDrawing.LightBorder[5] -- "└" Bottom-left corner
		BR = RMP.BoxDrawing.LightBorder[6] -- "┘" Bottom-right corner
		H  = RMP.BoxDrawing.LightBorder[1] -- "─" Horizontal line
		V  = RMP.BoxDrawing.LightBorder[2] -- "│" Vertical line
	else
		TL = border_style[3] -- "┌" Top-left corner
		TR = border_style[4] -- "┐" Top-right corner
		BL = border_style[5] -- "└" Bottom-left corner
		BR = border_style[6] -- "┘" Bottom-right corner
		H  = border_style[1] -- "─" Horizontal line
		V  = border_style[2] -- "│" Vertical line
	end

	local end_x = math.min(x + width - 1, self.width)
	local end_y = math.min(y + height - 1, self.height)

	self:setChar(x, y, TL, fg, bg)
	self:setChar(end_x, y, TR, fg, bg)
	self:setChar(x, end_y, BL, fg, bg)
	self:setChar(end_x, end_y, BR, fg, bg)

	for i = x + 1, end_x - 1 do
		self:setChar(i, y, H, fg, bg)
		self:setChar(i, end_y, H, fg, bg)
	end

	for i = y + 1, end_y - 1 do
		self:setChar(x, i, V, fg, bg)
		self:setChar(end_x, i, V, fg, bg)
	end

	for i = y + 1, end_y - 1 do
		for j = x + 1, end_x - 1 do
			self:setChar(j, i, " ", nil, bg)
		end
	end

	self.dirty = true
end

-- i stole this method from chat-gpt lol whatever
function RMP.VirtualTerminal:render()
	if not self.dirty then return end

	-- i added this line , because render method will executed in every loop
	self.height , self.width = window.get_size()

	local output = {}

	table.insert(output, "\27[2J\27[H")

	for y = 1, self.height do
		local line = {}
		local current_fg, current_bg, current_style = nil, nil, nil

		for x = 1, self.width do
			self:ensureBuffer(y, x)
			local cell = self.buffer[y][x]

			local needs_reset = false
			if (current_style and not cell.style) or (current_style ~= cell.style) then
				needs_reset = true
			end
			if (current_fg and not cell.fg) or (current_fg ~= cell.fg) then
				needs_reset = true
			end
			if (current_bg and not cell.bg) or (current_bg ~= cell.bg) then
				needs_reset = true
			end

			if needs_reset then
				table.insert(line, RMP.Default)
				current_style, current_fg, current_bg = nil, nil, nil
			end

			if cell.style and cell.style ~= current_style then
				table.insert(line, cell.style)
				current_style = cell.style
			end

			if cell.fg and cell.fg ~= current_fg then
				table.insert(line, cell.fg)
				current_fg = cell.fg
			end

			if cell.bg and cell.bg ~= current_bg then
				table.insert(line, cell.bg)
				current_bg = cell.bg
			end

			table.insert(line, cell.char)
		end

		if current_style or current_fg or current_bg then
			table.insert(line, RMP.Default)
		end

		table.insert(output, table.concat(line))
	end

	table.insert(output, moveto(self.cursor.x, self.cursor.y, true))

	io.write(table.concat(output, "\n"))
	io.flush()
	self.dirty = false
end

function RMP.VirtualTerminal:moveCursor(x, y)
	self.cursor.x = math.max(1, math.min(x, self.width))
	self.cursor.y = math.max(1, math.min(y, self.height))
end

function RMP.VirtualTerminal:getSize()
	return self.width, self.height
end

function RMP.VirtualTerminal:resize(width, height)
	self.width = width
	self.height = height
	self:clear()
end
-- TODO: Handle Terminal  class
-- NOTE: Terminal class uses ansii escape code i need to create shared library to handle terminal for each platform
RMP.Terminal = {}
RMP.Terminal.__index = Terminal
do	-- Terminal

	function RMP.Terminal:clearWindow()
		io.write("\27[2J")
	end
	function RMP.Terminal:moveTo(x , y)
		if x < 1 then
			x = 1
		elseif y < 1 then
			y = 1
		end
		moveto(x,y)
	end
	function RMP.Terminal:moveUp(x)
		if x < 1 or x == nil then
			x = 1
		end
		io.write("\27[" .. x .. "A");
	end
	function RMP.Terminal:moveDown(x)
		if x == nil or x < 1 then
			x = 1
		end
		io.write("\27[" .. x .. "B");
	end
	function RMP.Terminal:moveLeft(x)
		if x < 1  or x == nil then
			x = 1
		end
		io.write("\27[" .. x .. "D");
	end
	function RMP.Terminal:moveRight(x)
		if x < 1  or x == nil then
			x = 1
		end
		io.write("\27[" .. x .. "C");
	end
	function RMP.Terminal:hideCursor()
		io.write("\27[?25l");
	end
	function RMP.Terminal:showCursor()
		io.write("\27[?25h");
	end
	function RMP.Terminal:rawMode(enable)
		window.raw_mode(enable)
	end

	function RMP.Terminal:getSize() -- h,w
		return window.get_size()
	end

	-- TODO: make sure that function works on windows
	-- TODO: add this two function to Input class to add more operations to make it easy
	function RMP.Terminal:handleKey()
		return keyboard.get()
	end

	function RMP.Terminal:closeKey()
		return keyboard.close()
	end
end

-- TODO: handle Input 
-- TODO: handle Tables 
-- TODO: handle Panel
-- TODO: handle Loading  
RMP.Options = {}
RMP.Options.__index = Options
do	-- Options
	-- options : array of options 
	function RMP.Options:addOption(options)
		self.options = options
		self.color = RMP.Default
		self.symbl = "" 
		self.pos = 1

		self.counter = false
		self.mark = false
		self.marked_table = {}
		self.selected = ""
		self.unselected = ""
		return self
	end

	function RMP.Options:setCounter(value)
		self.counter  = value
		return self
	end

	function RMP.Options:setMark(selected , unselected)
		self.selected = selected
		self.unselected = unselected 
		for i = 1 , #self.options do
			self.marked_table[i] = false
		end
		self.mark = true
		return self
	end

	function RMP.Options:setColorFocus(color)
		self.color = color
		return self
	end

	function RMP.Options:setSymblFocus(symbl)
		self.symbl = symbl 
		return self
	end

	function RMP.Options:setOptions(options)
		self.options = options
		return self
	end

	function RMP.Options:getOptions()
		return self.options
	end

	-- default position
	function RMP.Options:focusPos(position)
		self.pos = position or 1
		text = self.options[self.pos]
		self.options[self.pos] = RMP.Text:new(text , self.symbl , self.color):getColoredText()
		return self
	end

	function RMP.Options:next()
		text = self.options[self.pos]
		self.options[self.pos] = cleanTextLocal(text)
		if self.pos == #self.options then
			self.pos = 1
		else
			self.pos = self.pos + 1
		end
		self:focusPos(self.pos)
		return self
	end

	function RMP.Options:first()
		self.pos = 1
		self:focusPos(self.pos)
		return self
	end

	function RMP.Options:last()
		self.pos = #self.options
		self:focusPos(self.pos)
		return self
	end

	function RMP.Options:prev()
		text = self.options[self.pos]
		self.options[self.pos] = cleanTextLocal(text)
		if self.pos == 1 then
			self.pos = #self.options
		else
			self.pos = self.pos - 1
		end
		self:focusPos(self.pos)
		return self
	end

	function RMP.Options:getSelected()
		self.marked_table[self.pos] = not self.marked_table[self.pos]
		return cleanTextLocal(self.options[self.pos])
	end

	function RMP.Options:getOptions()
		return self.options
	end

	-- Log method will print the options to standerd output
	function RMP.Options:log(x , y)
		RMP.Terminal:moveTo(x,y)
		for i = 1 , #self.options do
			if self.marked_table[i] then
				io.write(self.selected)
			else
				io.write(self.unselected)
			end
			io.write(self.options[i])
			RMP.Terminal:moveTo(x,y + i)
		end
	end
end

-- TODO: handle Layout
RMP.Draw = {}
RMP.Draw.__index = Draw
do	-- Draw
	function RMP.Draw:rectangle(x,y,width,height,color)
		local x = math.floor(x)
		local y = math.floor(y)
		local width = math.floor(width)
		local height = math.floor(height)
		local tha_box = ""
		tha_box  = tha_box .. moveto(x, y , true)

		tha_box  = tha_box .. RMP.Text:new(" " , nil , color):getColoredText()  .. string.rep(RMP.Text:new(" " , nil , color):getColoredText(), width - 2) ..  RMP.Text:new(" " , nil , color):getColoredText()

		for i = 1, height - 2 do
			tha_box  = tha_box .. moveto(x, y + i , true)
			tha_box  = tha_box .. RMP.Text:new(" " , nil , color):getColoredText() .. string.rep(RMP.Text:new(" " , nil , color):getColoredText(), width - 2) .. RMP.Text:new(" " , nil , color):getColoredText()
		end

		tha_box  = tha_box .. moveto(x, y + height - 1 , true)
		tha_box  = tha_box .. RMP.Text:new(" " , nil , color):getColoredText() .. string.rep(RMP.Text:new(" " , nil , color):getColoredText(), width - 2) .. RMP.Text:new(" " , nil , color):getColoredText()
		io.write(tha_box)
		io.flush()
		tha_box = ""
		-- TODO: flush output
		-- TODO: write by buffer
	end

	function RMP.Draw:circle(px, py, r , color)
		for y = -r, r do
			RMP.Terminal:moveTo(px , py + y + r)
			for x = -r, r do
				if x * x + y * y <= r * r then
					io.write(RMP.Text:new("  " , nil ,color):getColoredText())
				else
					io.write("  ")
				end
			end
		end
	end

	function RMP.Draw:triangle(height, pos_x, pos_y, color)
		char = RMP.Text:new(" " , nil , color):getColoredText()
		for y = 0, height - 1 do
			local spaces = height - y - 1
			local stars = 2 * y + 1

			RMP.Terminal:moveTo(pos_x + spaces , pos_y + y)
			io.write(string.rep(char, stars), "\n")
		end
	end

	-- TODO: add thick
	function RMP.Draw:line(x , y, width , color) -- thick from 0.0 to 1.0
		RMP.Terminal:moveTo(x,y)
		for i = 0  , width do
			io.write(RMP.Text:new(" " , nil , color):getColoredText())
		end
	end

	function RMP.Draw:column(x, y , height , color)
		RMP.Terminal:moveTo(x,y)
		for i = 0  , height do
			io.write(RMP.Text:new(" " , nil , color):getColoredText())
			RMP.Terminal:moveDown(1)
			RMP.Terminal:moveLeft(1)
		end
	end
end
-- TODO: handle Bar  
RMP.Popup = {}
RMP.Popup.__index = Popup
do	-- Popups
	RMP.MESSAGE = enum(true)
	RMP.INFO = enum()
	RMP.ERROR = enum()
	RMP.WARNING = enum()

	-- Position Layout
	RMP.CENTER 	= enum(true)
	RMP.TOP_LEFT 	= enum()
	RMP.TOP_RIGHT 	= enum()
	RMP.BUTTOM_LEFT 	= enum()
	RMP.BUTTOM_RIGHT 	= enum()

	-- TODO: add emojis for each status
	function RMP.Popup:run(message , title , status , border_color , bg_color , poslayout)
		rows , cols = RMP.Terminal:getSize()
		local poslayout = poslayout or RMP.CENTER
		local x , y = nil , nil
		if poslayout == RMP.TOP_LEFT then
			x , y = 2,2
		elseif poslayout == RMP.TOP_RIGHT then
			x , y = cols - (cols/4) -  2,2
		elseif poslayout == RMP.BUTTOM_LEFT then
			x , y = 2,rows - (rows/4) -  2
		elseif poslayout == RMP.BUTTOM_RIGHT then
			x , y = cols - (cols/4) -  2,rows - (rows/4) -  2
		else
			x , y = (cols / 2) - (cols/8) , (rows / 2) - (rows/8)
		end
		
		RMP.Window:createWindow(
		title , 
		-- 		cols / 2 , 
		-- 		rows / 2 , 
		cols/4 , 
		rows/4 ,
		x,
		y,
		border_color , 
		bg_color , 
		RMP.BoxDrawing.LightBorder , 
		function(x, y , xx , yy)
			-- TODO: handle emojis here
			-- TODO: fix message inside box
			local t = RMP.Text:new(remove_new_lines_from_str(message) , nil , nil)
			io.write(t:getText())
			io.flush()
		end)
	end

	function RMP.Popup:error(message , delay , poslayout)
		local delay = delay or 3	-- 3 seconds
		local poslayout = poslayout or RMP.CENTER
		RMP.Popup:run(
			message , 
			"[ " .. RMP.Text:new(
			"ERROR" , 
			RMP.Bold , 
			RMP.BGBRed
			):getColoredText() .. " ]", 
			RMP.ERROR , 
			RMP.FGRed , 
			nil,
			poslayout
		)
		RMP.sleep(RMP.Duration:fromSec(delay))
	end

	function RMP.Popup:info(message , delay , poslayout)
		local delay = delay or 3	-- 3 seconds
		local poslayout = poslayout or RMP.CENTER
		RMP.Popup:run(
			message ,
			"[ " .. RMP.Text:new(
			"INFO" , 
			RMP.Bold , 
			RMP.BGBGreen
			):getColoredText()  .. " ]", 
			RMP.INFO , 
			RMP.FGGreen , 
			nil,
			poslayout
		)
		RMP.sleep(RMP.Duration:fromSec(delay))
	end

	function RMP.Popup:message(message , delay , poslayout)
		local delay = delay or 3	-- 3 seconds
		local poslayout = poslayout or RMP.CENTER
		RMP.Popup:run(
			message ,  
			"[ " .. RMP.Text:new(
			"Message" , 
			RMP.Bold , 
			RMP.BGBBlue
			):getColoredText()   .. " ]", 
			RMP.MESSAGE , 
			RMP.FGBlue , 
			nil,
			poslayout
		)
		RMP.sleep(RMP.Duration:fromSec(delay))
	end

	function RMP.Popup:warning(message , delay , poslayout)
		local delay = delay or 3	-- 3 seconds
		local poslayout = poslayout or RMP.CENTER
		RMP.Popup:run(
			message ,  
			"[ " .. RMP.Text:new(
			"Warning" , 
			RMP.Bold , 
			RMP.BGBYellow
			):getColoredText()   .. " ]", 
			RMP.WARNING , 
			RMP.FGYellow , 
			nil,
			poslayout
		)
		RMP.sleep(RMP.Duration:fromSec(delay))
	end
end

-- Scroller class
RMP.Scroller = {}
RMP.Scroller.__index = RMP.Scroller
do	-- Scroller
	function RMP.Scroller:new(h, optObj)
		local obj = setmetatable({}, self)
		obj.h = h
		obj.data = optObj:getOptions()
		obj.cur = 0
		obj.options = optObj:setOptions(obj:getSlice())
		return obj
	end

	function RMP.Scroller:getSlice()
		local local_data = {}
		local last = math.min(self.h, #self.data)

		for i = 1, last do
			local_data[i] = self.data[i + self.cur]
		end
		return local_data
	end

	function RMP.Scroller:nextLine()
		if self.cur + self.h < #self.data then
			if self.options.pos < self.h then
				self.options:next()
			else
				self.cur = self.cur + 1
				self.options:setOptions(self:getSlice())
				self.options:focusPos(self.h)
			end
		else
			self.options:next()
		end
	end

	function RMP.Scroller:prevLine()
		if self.cur > 0 then
			if self.options.pos > 1 then
				self.options:prev()
			else
				self.cur = self.cur - 1
				self.options:setOptions(self:getSlice())
				self.options:focusPos(1)
			end
		else
			self.options:prev()
		end
	end
	function RMP.Scroller:nextContent()
		local max_start = math.max(0, #self.data - self.h)
		self.cur = math.min(self.cur + self.h, max_start)
		self.options:setOptions(self:getSlice())
		self.options:focusPos(1)
	end

	function RMP.Scroller:prevContent()
		self.cur = math.max(self.cur - self.h, 0)
		self.options:setOptions(self:getSlice())
		self.options:focusPos(1)
	end
end

-- TODO: bind miniaudio
-- TODO: handle the class Sound
-- TODO: handle Albome class : albome manager
RMP.Sound = {}
RMP.Sound.__index = RMP.Sound

do 	-- Sound

	RMP.PLAYLIST_LOOP 	= enum(true)
	RMP.SINGLE_LOOP 	= enum()
	RMP.ONES 		= enum()

	function RMP.Sound:new(array_sounds)
		self.sound_name = array_sounds or nil
		if type(array_sounds) == "table" then
			self.sound_name = array_sounds
		elseif type(array_sounds) == "string" then
			self.sound_name = {array_sounds}
		else
			self.sound_name = nil
		end
		self.curr = 1
		self.vol = 50
		self.is_played_before = false
		self.is_loaded = false
		self.status = RMP.ONES
		rmpaudio.Init()
		if self.sound_name ~= nil then
			local ok , err = pcall(rmpaudio.Load , self.sound_name[self.curr])
			if not ok then
				RMP.Popup:error("cannot load the sound " .. err)
				return self
			end
			self.is_loaded = true
		end
		return self
	end

	function RMP.Sound:add(sounds)
		if type(sounds) == "string" then
			if self.sound_name == nil then
				self.sound_name = {}
			end
			table.insert(self.sound_name,sounds)
		else 
			RMP.Popup:error("cannot add this sound the type is not string")
			return self
		end

		return self
	end

	function RMP.Sound:setStatus(status)
		if type(status) == "number" and status <= RMP.ONES or status >= RMP.PLAYLIST_LOOP then
			self.status = status
		end
		return self
	end

	function RMP.Sound:getStatus()
		return self.status
	end

	-- function RMP.Sound:loadSoundDirectly(sounds_file)
	-- 	rmpaudio.Load(sounds_file)
	-- 	return self
	-- end

	-- function RMP.Sound:load()
	-- 	rmpaudio.Load(self.sound_name[self.curr])
	-- 	return self
	-- end

	function RMP.Sound:play()
		if not self.is_played_before then
			local ok , err = pcall(rmpaudio.Play)
			if not ok then
				RMP.Popup:error(err)
				return self
			end
			self.is_played_before = true
		end
		return self
	end

	function RMP.Sound:next()
		if self.curr < #self.sound_name  then
			self.curr = self.curr + 1
		else
			self.curr = 1
		end
		return self
	end

	function RMP.Sound:prev()
		if self.curr > 1  then
			self.curr = self.curr - 1
		else
			self.curr = #self.sound_name
		end
		return self
	end

	-- NOTE: this method is broken
	function RMP.Sound:playForEver()
		return rmpaudio.PlayUntilFinished()
	end

	function RMP.Sound:isValid()
		return rmpaudio.IsValid()
	end

	function RMP.Sound:getAudioDeviceInformation()
		return rmpaudio.GetAudioDeviceInformation()
	end

	function RMP.Sound:setSpeed(speed)
		rmpaudio.SetSpeed(speed)
		return self
	end

	function RMP.Sound:pause()
		rmpaudio.Pause()
		return self
	end

	function RMP.Sound:resume()
		rmpaudio.Resume()
		return self
	end

	function RMP.Sound:stop()
		rmpaudio.Stop()
		return self
	end

	-- in persent
	function RMP.Sound:setVolume(volume)
		if volume > 100 then
			rmpaudio.SetVolume(1)
		elseif volume < 0 then
			rmpaudio.SetVolume(0.5)
		else
			rmpaudio.SetVolume(volume / 100)
		end
		return self
	end

	-- in minute
	function RMP.Sound:seek(pos)
		rmpaudio.Seek(pos)
		return self
	end

	function RMP.Sound:getPosition()
		return rmpaudio.GetPosition()
	end

	function RMP.Sound:isPlaying()
		return rmpaudio.IsPlaying()
	end

	function RMP.Sound:getDuration()
		return rmpaudio.GetDuration()
	end

	function RMP.Sound:getMetaData()
		return rmpaudio.GetMetaData()
	end

	-- in persent
	function RMP.Sound:getVolume()
		return rmpaudio.GetVolume()*100
	end

	function RMP.Sound:cleanUp()
		rmpaudio.Clean()
	end

end

RMP.Path = {}
RMP.Path.__index = RMP.Path
do	-- Path
	function RMP.Path:new(path)
		self.path = path or self:getCurrentPath()
	end

	function RMP.Path:getCurrentPath()
		return directory.get_current_path()
	end

	function RMP.Path:getHomePath()
		return directory.home_path()
	end

	function RMP.Path:listDir()
		-- this method return table of tables contains two value 
		-- first one is boolean indecates if it is file or dir (true -> file else dir)
		-- second one is string name of the file or dir
		return directory.list_dir(self.path)	-- may return nil
	end

	function RMP.Path:makeDir(dir_name)
		local full_dir = nil
		if string.sub(self.path , -1) == "/" then
			full_dir = self.path..dir_name
		else
			full_dir = self.path.."/"..dir_name
		end
		return directory.mkdir(full_dir , 
			nil	-- mode default 0o755
		)
	end

	function RMP.Path:removeDir(dir_name)
		local full_dir = nil
		if string.sub(self.path , -1) == "/" then
			full_dir = self.path..dir_name
		else
			full_dir = self.path.."/"..dir_name
		end
		return directory.rmdir(full_dir)
	end

	function RMP.Path:find(pattern , is_find_file) -- boolean
		-- if file or dir is founded it returns true so you can access it directly
		local lst = self:listDir()
		if not lst then
			return false
		end

		for _ , info in ipairs(lst) do
			if is_find_file then
				if info.is_file and pattern == info.name then
					return true
				end
			else
				if not info.is_file and pattern == info.name then
					return true
				end
			end
		end
		return false
	end

	function RMP.Path:findRecursive(pattern, is_file_pattern, max_depth) -- return Table {path , name , is_file}
		max_depth = max_depth or -1
		local results = {}
		local match_func

		if type(pattern) == "function" then
			match_func = pattern
		else
			match_func = function(name) return name == pattern end
		end

		local search_recursive = function(current_path, current_depth)
			if max_depth >= 0 and current_depth > max_depth then
				return
			end

			local temp_path = RMP.Path:new(current_path)
			local lst = temp_path:listDir()
			if not lst then
				return
			end

			for _, info in ipairs(lst) do
				local full_path
				if string.sub(current_path, -1) == "/" then
					full_path = current_path .. info.name
				else
					full_path = current_path .. "/" .. info.name
				end

				local should_check = (is_file_pattern == nil) or
				(is_file_pattern and info.is_file) or
				(not is_file_pattern and not info.is_file)

				if should_check and match_func(info.name, info.is_file, full_path) then
					table.insert(results, {
						path = full_path,
						name = info.name,
						is_file = info.is_file
					})
				end

				if not info.is_file then
					search_recursive(full_path, current_depth + 1)
				end
			end
		end

		search_recursive(self.path, 0)
		return results
	end

end

-- TODO: write master.lua for managing lua plugins using lua coroutines
-- TODO: make init.lua contains confguration like add plugins and configure keys

-- TODO: introduce configuration system to manage lua configuration file 
RMP.Config = {}
RMP.Config.__index = RMP.Config

do 	-- Config
	function RMP.Config:load()
		local path
		-- self.cfg = require(".init")
		return self
	end

	function RMP.Config:integratePlugUsingId(id)
		-- TODO: handle multiple plugins in same window , and check the input key to change between them
		-- search key id in table and return the callback function 
	end
end

return RMP

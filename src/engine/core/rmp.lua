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

function RMP.GetKeyStr(key)
	if key == RMP.KEY_CTRL_A then
		print("KEY_CTRL_A ")
	elseif key == RMP.KEY_CTRL_B then
		print("KEY_CTRL_B ")
	elseif key == RMP.KEY_CTRL_C then

		print("KEY_CTRL_C ")
	elseif key == RMP.KEY_CTRL_D then

		print("KEY_CTRL_D ")
	elseif key == RMP.KEY_CTRL_E then

		print("KEY_CTRL_E")
	elseif key == RMP.KEY_CTRL_F then

		print("KEY_CTRL_F ")
	elseif key == RMP.KEY_CTRL_G then

		print("KEY_CTRL_G ")
	elseif key == RMP.KEY_CTRL_H then

		print("KEY_CTRL_H ")
	elseif key == RMP.KEY_CTRL_K then

		print("KEY_CTRL_K ")
	elseif key == RMP.KEY_CTRL_L then

		print("KEY_CTRL_L ")
	elseif key == RMP.KEY_CTRL_M then

		print("KEY_CTRL_M ")
	elseif key == RMP.KEY_CTRL_N then

		print("KEY_CTRL_N ")
	elseif key == RMP.KEY_CTRL_O then

		print("KEY_CTRL_O")
	elseif key == RMP.KEY_CTRL_P then

		print("KEY_CTRL_P ")
	elseif key == RMP.KEY_CTRL_Q then

		print("KEY_CTRL_Q ")
	elseif key == RMP.KEY_CTRL_R then

		print("KEY_CTRL_R ")
	elseif key == RMP.KEY_CTRL_S then

		print("KEY_CTRL_S ")
	elseif key == RMP.KEY_CTRL_T then

		print("KEY_CTRL_T")
	elseif key == RMP.KEY_CTRL_U then

		print("KEY_CTRL_U ")
	elseif key == RMP.KEY_CTRL_V then

		print("KEY_CTRL_V ")
	elseif key == RMP.KEY_CTRL_W then

		print("KEY_CTRL_W ")
	elseif key == RMP.KEY_CTRL_X then

		print("KEY_CTRL_X ")
	elseif key == RMP.KEY_CTRL_Y then

		print("KEY_CTRL_Y")
	elseif key == RMP.KEY_CTRL_Z then

		print("KEY_CTRL_Z")
	elseif key == RMP.KEY_ENTER then

		print("KEY_ENTER ")
	elseif key == RMP.KEY_SPACE then

		print("KEY_SPACE ")
	elseif key == RMP.KEY_ESCAPE then

		print("KEY_ESCAPE ")
	elseif key == RMP.KEY_UP then

		print("KEY_UP ")
	elseif key == RMP.KEY_DOWN then

		print("KEY_DOWN")
	elseif key == RMP.KEY_LEFT then

		print("KEY_LEFT ")
	elseif key == RMP.KEY_RIGHT then

		print("KEY_RIGHT ")
	elseif key == RMP.KEY_TAB then

		print("KEY_TAB")
	elseif key == RMP.KEY_A then

		print("KEY_A ")
	elseif key == RMP.KEY_B then

		print("KEY_B ")
	elseif key == RMP.KEY_C then

		print("KEY_C ")
	elseif key == RMP.KEY_D then

		print("KEY_D ")
	elseif key == RMP.KEY_E then

		print("KEY_E ")
	elseif key == RMP.KEY_F then

		print("KEY_F ")
	elseif key == RMP.KEY_G then

		print("KEY_G ")
	elseif key == RMP.KEY_H then

		print("KEY_H")
	elseif key == RMP.KEY_I then

		print("KEY_I ")
	elseif key == RMP.KEY_J then

		print("KEY_J ")
	elseif key == RMP.KEY_K then

		print("KEY_K ")
	elseif key == RMP.KEY_L then

		print("KEY_L ")
	elseif key == RMP.KEY_M then

		print("KEY_M ")
	elseif key == RMP.KEY_N then

		print("KEY_N ")
	elseif key == RMP.KEY_O then

		print("KEY_O ")
	elseif key == RMP.KEY_P then

		print("KEY_P")
	elseif key == RMP.KEY_Q then

		print("KEY_Q ")
	elseif key == RMP.KEY_R then

		print("KEY_R ")
	elseif key == RMP.KEY_S then

		print("KEY_S ")
	elseif key == RMP.KEY_T then

		print("KEY_T ")
	elseif key == RMP.KEY_U then

		print("KEY_U ")
	elseif key == RMP.KEY_V then

		print("KEY_V ")
	elseif key == RMP.KEY_W then

		print("KEY_W ")
	elseif key == RMP.KEY_X then

		print("KEY_X")
	elseif key == RMP.KEY_Y then

		print("KEY_Y ")
	elseif key == RMP.KEY_Z then

		print("KEY_Z")
	elseif key == RMP.KEY_SHIFT_A then

		print("KEY_SHIFT_A ")
	elseif key == RMP.KEY_SHIFT_B then

		print("KEY_SHIFT_B ")
	elseif key == RMP.KEY_SHIFT_C then

		print("KEY_SHIFT_C ")
	elseif key == RMP.KEY_SHIFT_D then

		print("KEY_SHIFT_D ")
	elseif key == RMP.KEY_SHIFT_E then

		print("KEY_SHIFT_E")
	elseif key == RMP.KEY_SHIFT_F then

		print("KEY_SHIFT_F ")
	elseif key == RMP.KEY_SHIFT_G then

		print("KEY_SHIFT_G ")
	elseif key == RMP.KEY_SHIFT_H then

		print("KEY_SHIFT_H ")
	elseif key == RMP.KEY_SHIFT_I then

		print("KEY_SHIFT_I ")
	elseif key == RMP.KEY_SHIFT_J then

		print("KEY_SHIFT_J")
	elseif key == RMP.KEY_SHIFT_K then

		print("KEY_SHIFT_K ")
	elseif key == RMP.KEY_SHIFT_L then

		print("KEY_SHIFT_L ")
	elseif key == RMP.KEY_SHIFT_M then

		print("KEY_SHIFT_M ")
	elseif key == RMP.KEY_SHIFT_N then

		print("KEY_SHIFT_N ")
	elseif key == RMP.KEY_SHIFT_O then

		print("KEY_SHIFT_O")
	elseif key == RMP.KEY_SHIFT_P then

		print("KEY_SHIFT_P ")
	elseif key == RMP.KEY_SHIFT_Q then

		print("KEY_SHIFT_Q ")
	elseif key == RMP.KEY_SHIFT_R then

		print("KEY_SHIFT_R ")
	elseif key == RMP.KEY_SHIFT_S then

		print("KEY_SHIFT_S ")
	elseif key == RMP.KEY_SHIFT_T then

		print("KEY_SHIFT_T")
	elseif key == RMP.KEY_SHIFT_U then

		print("KEY_SHIFT_U ")
	elseif key == RMP.KEY_SHIFT_V then

		print("KEY_SHIFT_V ")
	elseif key == RMP.KEY_SHIFT_W then

		print("KEY_SHIFT_W ")
	elseif key == RMP.KEY_SHIFT_X then

		print("KEY_SHIFT_X ")
	elseif key == RMP.KEY_SHIFT_Y then

		print("KEY_SHIFT_Y")
	elseif key == RMP.KEY_SHIFT_Z then

		print("KEY_SHIFT_Z")
	elseif key == RMP.KEY_0 then

		print("KEY_0 ")
	elseif key == RMP.KEY_1 then

		print("KEY_1 ")
	elseif key == RMP.KEY_2 then

		print("KEY_2 ")
	elseif key == RMP.KEY_3 then

		print("KEY_3 ")
	elseif key == RMP.KEY_4 then

		print("KEY_4 ")
	elseif key == RMP.KEY_5 then

		print("KEY_5")
	elseif key == RMP.KEY_6 then

		print("KEY_6 ")
	elseif key == RMP.KEY_7 then

		print("KEY_7 ")
	elseif key == RMP.KEY_8 then

		print("KEY_8 ")
	elseif key == RMP.KEY_9 then

		print("KEY_9")
	elseif key == RMP.KEY_PLUS then

		print("KEY_PLUS ")
	elseif key == RMP.KEY_MINUS then

		print("KEY_MINUS ")
	elseif key == RMP.KEY_GT then

		print("KEY_GT ")
	elseif key == RMP.KEY_LT then

		print("KEY_LT ")
	elseif key == RMP.KEY_HASHTAG then

		print("KEY_HASHTAG")
	elseif key == RMP.KEY_DOLAR then

		print("KEY_DOLAR ")
	elseif key == RMP.KEY_PERSANT then

		print("KEY_PERSANT ")
	elseif key == RMP.KEY_STAR then

		print("KEY_STAR ")
	elseif key == RMP.KEY_DOT then
		print("KEY_DOT ")
	elseif key == RMP.KEY_UNDERS then
		print("KEY_UNDERS")
	elseif key == RMP.KEY_SEMICOL then
		print("KEY_SEMICOL ")
	elseif key == RMP.KEY_QUISTION_MARK then
		print("KEY_QUISTION_MARK ")
	elseif key == RMP.KEY_AT then
		print("KEY_AT ")
	elseif key == RMP.KEY_OPCURB then
		print("KEY_OPCURB")
	elseif key == RMP.KEY_CLCURB then
		print("KEY_CLCURB ")
	elseif key == RMP.KEY_BACK_SLASH then
		print("KEY_BACK_SLASH ")
	elseif key == RMP.KEY_BACKTICK then
		print("KEY_BACKTICK ")
	elseif key == RMP.KEY_OPEN_BRAKET then
		print("KEY_OPEN_BRAKET")
	elseif key == RMP.KEY_CLOSED_BRAKET then
		print("KEY_CLOSED_BRAKET ")
	elseif key == RMP.KEY_BAR then

		print("KEY_BAR ")
	elseif key == RMP.KEY_DBL_QUOTE then

		print("KEY_DBL_QUOTE ")
	elseif key == RMP.KEY_SINGLE_QOUTE then

		print("KEY_SINGLE_QOUTE")
	elseif key == RMP.NONE then
		print("NONE")
	else
		print("this is not key")
	end
end

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

	function draw_box(border , title , x, y, width, height, border_color , bg_color)
		local tha_box = ""

		if border == nil then
			TL = RMP.BoxDrawing.LightBorder[3] -- "┌" Top-left corner
			TR = RMP.BoxDrawing.LightBorder[4] -- "┐" Top-right corner
			BL = RMP.BoxDrawing.LightBorder[5] -- "└" Bottom-left corner
			BR = RMP.BoxDrawing.LightBorder[6] -- "┘" Bottom-right corner
			H  = RMP.BoxDrawing.LightBorder[1] -- "─" Horizontal line
			V  = RMP.BoxDrawing.LightBorder[2] -- "│" Vertical line
		else
			TL = border[3] -- "┌" Top-left corner
			TR = border[4] -- "┐" Top-right corner
			BL = border[5] -- "└" Bottom-left corner
			BR = border[6] -- "┘" Bottom-right corner
			H  = border[1] -- "─" Horizontal line
			V  = border[2] -- "│" Vertical line
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
	function RMP.Window:createWindow(title , width , height , x , y , border_color , background_color , border , callback)
		if title == nil then
			title = ""
		end

		local title = title or ""

		draw_box(border 
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
		if x < 1  or x == nil then
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
		if RMP.getOs() == RMP.WINDOWS then
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

	function RMP.Terminal:getSize()
		if RMP.getOs() == RMP.LINUX then
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
	function RMP.Draw:line(x , y, width , color)
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
			x , y = cols / 2 , rows / 2
		end
		RMP.Window:createWindow(
		title , 
		-- 		cols / 2 , 
		-- 		rows / 2 , 
		x,
		y,
		cols/4 , 
		rows/4 ,
		border_color , 
		bg_color , 
		function(x, y , xx , yy)
			-- TODO: handle emojis here
			local t = RMP.Text:new(remove_new_lines_from_str(message) , nil , nil)
			RMP.Terminal:moveTo(math.floor(cols/4) ,math.floor(rows/4))
			RMP.Terminal:moveDown(1)
			RMP.Terminal:moveRight(2)
			for i = 1 , math.floor(yy - y) - 2 do
				io.write(t:fixTextToBox(xx - x + 2))
				io.flush()
				RMP.Terminal:moveTo(math.floor(cols/4) + 2,math.floor(rows/4) + i)
				RMP.Terminal:moveDown(1)
			end
		end
		)
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

-- TODO: write master.lua for managing lua plugins using lua coroutines
-- TODO: make init.lua contains confguration like add plugins and configure keys

-- TODO: introduce configuration system to manage lua configuration file 


return RMP


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
local keyboard = require("rmp.keyboard")
local rmpaudio = require("rmp.rmpaudio")
local sleep = require("rmp.sleep")
local platform = require("rmp.platform")
local directory = require("rmp.directory")
local window = require("rmp.window")

-- require rmp utility
local OOP = require("rmp.oop")
local Promise = require("rmp.promises")
local Util = require("rmp.util")

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
	RMP.PlatformType = {
		LINUX  = enum(true),
		WINDOWS  = enum(),
		MAC  = enum(),
		UNKOW  = enum()
	}

	function RMP.getOs() -- it will return enum value
		return platform.platform() 
	end
end

RMP.quickRoutine = function(func)
	return coroutine.create(func)
end

-- check ansi escape code : https://en.wikipedia.org/wiki/ANSI_escape_code
-- line style
RMP.TextStyle = {
	Strike			= "\27[9m",
	Hide			= "\27[8m",
	SlowBlink 		= "\27[5m",
	OverUnderline 		= "\27[53m",
	Underline 		= "\27[4m",
	DoubleUnderline		= "\27[21m",
	Italic	   		= "\27[3m",
	Bold	   		= "\27[1m",
	RapidBlink      	= "\27[6m",
	Faint           	= "\27[2m",
	Reverse         	= "\27[7m",
	Framed          	= "\27[51m",
	Encircled       	= "\27[52m",
	Overline        	= "\27[55m",
	ProportionalSpacing 	= "\27[26m",
	Superscript     	= "\27[73m",
	Subscript       	= "\27[74m",
	Regular   		= "\27[0m"
}

-- colors
-- TODO: handle colors using ColorFromHex
-- ForeGround 
RMP.FGColors = {
	NoBrights = {
		Black		= "\27[30m",
		Red	 	= "\27[31m",
		Green		= "\27[32m",
		Yellow		= "\27[33m",
		Blue	 	= "\27[34m",
		Magenta 	= "\27[35m",
		Cyan	 	= "\27[36m",
		White		= "\27[37m"
	},
	Brights = {
		-- ForeGround bright
		Black		= "\27[90m",
		Red	 	= "\27[91m",
		Green		= "\27[92m",
		Yellow		= "\27[93m",
		Blue		= "\27[94m",
		Magenta 	= "\27[95m",
		Cyan		= "\27[96m",
		White		= "\27[97m"
	}
}

-- BackGround 
RMP.BGColors = {
	NoBrights = {
		Black		= "\27[40m",
		Red	 	= "\27[41m" ,
		Green		= "\27[42m",
		Yellow		= "\27[43m",
		Blue	 	= "\27[44m",
		Magenta 	= "\27[45m",
		Cyan	 	= "\27[46m",
		White		= "\27[47m"
	},
	Brights = {
		-- BackGround bright
		Black		= "\27[100m",
		Red	 	= "\27[101m" ,
		Green		= "\27[102m",
		Yellow		= "\27[103m",
		Blue 		= "\27[104m",
		Magenta 	= "\27[105m",
		Cyan		= "\27[106m",
		White		= "\27[107m"
	}
}
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
RMP.IInfo 	= "ℹ️"

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
	},
	RoundedCorners = {
		"─",  -- Light horizontal line (U+2500)
		"│",  -- Light vertical line (U+2502)
		"╭",  -- Light down and right corner (U+250C)
		"╮",  -- Light down and left corner (U+2510)
		"╰",  -- Light up and right corner (U+2514)
		"╯",  -- Light up and left corner (U+2518)
		"├",  -- Light vertical and right tee (U+251C)
		"┤",  -- Light vertical and left tee (U+2524)
		"┬",  -- Light down and horizontal tee (U+252C)
		"┴",  -- Light up and horizontal tee (U+2534)
		"┼",  -- Light vertical and horizontal cross (U+253C)
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

RMP.Duration = OOP.class("Duration")
do
	function RMP.Duration:constructor(time)
		self.time = time or 1
		return self
	end
	function RMP.Duration:fromSec()
		return self.time * 1000
	end

	function RMP.Duration:fromMilsec()
		return self.time
	end
end

function RMP.sleep(time)
	sleep.sleep(time)
end

-- Text class used to work with texts
RMP.Text = OOP.class("Text")
do	-- text
	-- constructor
	-- TODO: fix the error
	function RMP.Text:constructor(text , style , fg , bg)
		self.vterm = RMP.VirtualTerminal.new()
		self.text = text or ""
		self.fg = fg or RMP.Default
		self.bg = bg or RMP.Default
		self.style = style or RMP.Default
		self.x = 1
		self.y = 1
		return self
	end

	-- method Position in lua used to controle position of the text 
	function RMP.Text:setPosition(x,y)
		self.x = tonumber(x or 1)
		self.y = tonumber(y or 1)
		return self
	end

	function RMP.Text:asVTerm()
		self.vterm:writeText(self.x , self.y , self.text , self.fg , self.bg , self,style)
		return self.vterm
	end

	-- ColoredText accept text and color and return colored text
	function RMP.Text:getColoredText()
		return self.style..self.bg..self.fg..self.text..RMP.Default
	end

	function RMP.Text:getText()
		return self.text
	end

	function RMP.Text:getStyle()
		return self.style
	end

	function RMP.Text:getFGColor()
		return self.fg
	end

	function RMP.Text:getBGColor()
		return self.bg
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

		tha_box = tha_box 
			.. RMP.Text:new(TL , nil , border_color):getColoredText() 
			.. string.rep(RMP.Text:new(H , nil , border_color):getColoredText(),padding)
			.. title 
			.. string.rep(RMP.Text:new(H , nil , border_color):getColoredText(), width - title_len - padding- 2) 
			..  RMP.Text:new(TR , nil , border_color):getColoredText()

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

RMP.Window = OOP.class("Window")
do 	-- creating window
	-- callback function accept 4 agrs 

	function RMP.Window:constructor(id)
		self.id = id or nil
		return self
	end

	function RMP.Window:setId(id)
		self.id = id
	end

	function RMP.Window:getId()
		return self.id
	end

	function RMP.Window:createWindow(title , width , height , x , y , border_color , background_color , border_style , callback)
		local vterm = RMP.VirtualTerminal.new()

		if not width and not height and not x and not y then
			return 
		end

		vterm:drawBox(title , math.floor(x) , math.floor(y) , math.floor(width) , math.floor(height) , border_style , border_color , background_color)

		-- marked as deprecated
		if callback ~= nil and type(callback) == "function" then
			local lvt = callback(math.floor(x + 1) , math.floor(y + 1) , math.floor(x + width - 1) , math.floor(y + height - 1))
			if lvt ~= nil then
				vterm:merge() -- handle async
			end
		end

		return vterm
	end
end

-- all components should return VirtualTerminal obj
-- TODO: rewrite all VirtualTermminal methods to a native functions
RMP.VirtualTerminal = OOP.class("VirtualTerminal")
do	-- VirtualTerminal
	function RMP.VirtualTerminal:constructor(width, height) -- constructor
		local h , w = window.get_size()
		self.width = width or w or 80
		self.height = height or h or 24
		self.width  = math.floor(self.width)
		self.height = math.floor(self.height)
		self.buffer = {}
		self.dirty = false
		self.cursor = {x = 1, y = 1}
		self:clear()
		return self
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

		local x = x or self.cursor.x
		local y = y or self.cursor.y
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

		if not text then
			return 
		end

		local x = math.floor(x or self.cursor.x)
		local y = math.floor(y or self.cursor.y)

		for i = 1, #text do
			local char = text:sub(i, i)
			self:setChar(x + i - 1, y, char, fg, bg, style)
		end
		self.dirty = true

		return self
	end

	function RMP.VirtualTerminal:drawBox(title, x, y, width, height, border_style, fg, bg)

		local x = math.floor(x or 1)
		local y = math.floor(y or 1)

		local width  = math.floor(width or 80)
		local height = math.floor(height or 24)

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
			self:setChar(i, y, H, fg, bg)      -- Top border
			self:setChar(i, end_y, H, fg, bg)  -- Bottom border
		end

		for i = y + 1, end_y - 1 do
			self:setChar(x, i, V, fg, bg)      -- Left border
			self:setChar(end_x, i, V, fg, bg)  -- Right border
		end

		if title and title ~= "" and title:instanceOf(RMP.Text) then
			-- TODO: fix bug , the title applied only when we put bg color to the title
			self:writeText(math.floor((x*1.5 + ((width - x)/2)) - #(title:getText())/2) , y , title:getText() , title:getFGColor() , title:getBGColor() , title:getStyle()) 
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

	function RMP.VirtualTerminal:moveUp(y)
		local y = y or 1
		self:moveCursor(self.cursor.x , math.max(1,self.cursor.y - y))
	end

	function RMP.VirtualTerminal:moveDown(y)
		local y = y or 1
		self:moveCursor(self.cursor.x ,math.min(y + self.cursor.y, self.width))
	end

	function RMP.VirtualTerminal:moveRight(x)
		local x = x or 1
		self:moveCursor(math.min(x + self.cursor.x, self.width), self.cursor.y)
	end

	function RMP.VirtualTerminal:moveLeft(x)
		local x = x or 1
		self:moveCursor(math.max(1,self.cursor.x - x),self.cursor.y)
	end

	function RMP.VirtualTerminal:getSize()
		return self.width, self.height
	end

	function RMP.VirtualTerminal:resize(width, height)
		self.width = width
		self.height = height
		self:clear()
	end

	-- these methods are used to merge two virtual terminal 
	-- if there is no way to pass vterm object to function parameters 
	-- so you can merge the other virtual terminal to the main object
	function RMP.VirtualTerminal:merge(thatTerm, offsetX, offsetY)

		if thatTerm == nil or not thatTerm:instanceOf(RMP.VirtualTerminal) then
			return
		end

		offsetX = offsetX or 0
		offsetY = offsetY or 0

		for y = 1, thatTerm.height do
			local source_row = thatTerm.buffer[y]
			if source_row then
				for x = 1, thatTerm.width do
					local source_cell = source_row[x]
					if source_cell then
						local target_x = x + offsetX
						local target_y = y + offsetY

						if target_x >= 1 and target_x <= self.width and target_y >= 1 and target_y <= self.height then
							if source_cell.char ~= " " or source_cell.fg or source_cell.bg or source_cell.style then
								self:setChar(target_x, target_y, source_cell.char, source_cell.fg, source_cell.bg, source_cell.style)
							end
						end
					end
				end
			end
		end
		self.dirty = true
	end

	function RMP.VirtualTerminal:mergeAll(thoseTerms)
		for i = 1 , #thoseTerms do
			self:merge(thoseTerms[i].thatTerm,thoseTerms[i].offsetX,thoseTerms[i].offsetY)
		end
		self.dirty = true
	end

	function RMP.VirtualTerminal:copy()
		local copy = RMP.VirtualTerminal.new(self.width, self.height)
		for y = 1, self.height do
			copy.buffer[y] = {}
			for x = 1, self.width do
				if self.buffer[y] and self.buffer[y][x] then
					copy.buffer[y][x] = {
						char = self.buffer[y][x].char,
						fg = self.buffer[y][x].fg,
						bg = self.buffer[y][x].bg,
						style = self.buffer[y][x].style
					}
				else
					copy.buffer[y][x] = {char = " ", fg = nil, bg = nil, style = nil}
				end
			end
		end
		return copy
	end

end

-- TODO: Handle Terminal  class
-- NOTE: Terminal class uses ansii escape code i need to create shared library to handle terminal for each platform
RMP.Terminal = OOP.class("Terminal")
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
		local h , w = window.get_size()
		h = tonumber(h) or 24
		w = tonumber(w) or 80
		return h, w
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

-- NOTE: untested
RMP.Options = OOP.class("Options")
do	-- Options
	-- options : array of options 
	function RMP.Options:constructor(options) -- constructor
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
		self.options[self.pos] = RMP.Text.new(text , self.symbl , self.color):getColoredText()
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
	function RMP.Options:parse()
		local forRet = {} -- this tables contains parsed
		for i = 1 , #self.options do
			local text = ""
			if self.marked_table[i] then
				text = text .. self.selected .. " "
			else
				text = text .. self.unselected .. " "
			end
			text = text .. self.options[i]
			table.insert(text , forRet)
		end
		return forRet
	end
end

-- TODO: handle Layout
RMP.Draw = OOP.class("Draw")
do	-- Draw
	function RMP.Draw:rectangle(x,y,width,height,color)

		local x = x or 0
		local x = math.floor(x)

		local y = y or 0
		local y = math.floor(y)

		if not width or not height then
			return
		end

		local width = math.floor(width)
		local height = math.floor(height)

		local vterm = RMP.VirtualTerminal.new()
		vterm:moveCursor(x,y)

		for i = y , height + y do
			for j = x , width + x do
				vterm:setChar(j , i , " " , nil , color , nil)
			end
		end

		return vterm
	end

	function RMP.Draw:circle(centerX, centerY, r, color)
		r = math.floor(r or 5)
		if r <= 0 then return nil end

		local vterm = RMP.VirtualTerminal.new()
		for y = -r, r do
			for x = -r, r do
				if x * x + y * y <= r * r then
					local term_x = x + r + 1
					local term_y = y + r + 1
					vterm:setChar(term_x, term_y, " ", nil, color, nil)
				end
			end
		end
		return vterm
	end

	function RMP.Draw:triangle(height, pos_x, pos_y, color)
		local vterm = RMP.VirtualTerminal.new()
		char = RMP.Text.new(" " , nil , nil):getColoredText()
		for y = 0, height - 1 do
			local spaces = height - y - 1
			local stars = 2 * y + 1

			-- vterm:moveCursor(pos_x + spaces , pos_y + y)
			vterm:setChar(pos_x + spaces , pos_y + y , string.rep(char, stars), nil , color , nil)
		end
		return vterm
	end

	-- TODO: add thick
	function RMP.Draw:line(x , y, width , color) -- thick from 0.0 to 1.0
		local vterm = RMP.VirtualTerminal.new()
		vterm:moveCursor(x,y)
		for i = x  , width + x do
			vterm:setChar(i , y , " " , nil , color , nil)
		end

		return vterm
	end

	function RMP.Draw:column(x, y , height , color)
		local vterm = RMP.VirtualTerminal.new()
		for i = y  , height + y do
			vterm:setChar(x , i , " " , nil , color , nil)
		end
		return vterm
	end
end

-- Position Layout
RMP.PopupPosition = {
	CENTER 		= enum(true),
	TOP_LEFT 	= enum(),
	TOP_RIGHT 	= enum(),
	BUTTOM_LEFT 	= enum(),
	BUTTOM_RIGHT 	= enum()
}

-- TODO: handle Bar  
-- TODO: handle timeout async for popups
RMP.Popup = OOP.class("Popup")
do	-- Popups
	-- TODO: add emojis for each status
	function RMP.Popup:run(message , title , border_color , bg_color , poslayout)
		rows , cols = RMP.Terminal:getSize()
		local poslayout = poslayout or RMP.PopupPosition.CENTER
		local x , y = nil , nil
		if poslayout == RMP.PopupPosition.TOP_LEFT then
			x , y = 2,2
		elseif poslayout == RMP.PopupPosition.TOP_RIGHT then
			x , y = cols - (cols/4) -  2,2
		elseif poslayout == RMP.PopupPosition.BUTTOM_LEFT then
			x , y = 2,rows - (rows/4) -  2
		elseif poslayout == RMP.PopupPosition.BUTTOM_RIGHT then
			x , y = cols - (cols/4) -  2,rows - (rows/4) -  2
		else
			x , y = (cols / 2) - (cols/8) , (rows / 2) - (rows/8)
		end
		
		return RMP.Window.new(99):createWindow(
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
			local vterm = RMP.VirtualTerminal.new()
			vterm:moveCursor(x + 1 , y + 1)
			local text = remove_new_lines_from_str(message)

			local spl = 1
			local remider = 0
			if #text > (xx - x - 1) then
				if spl == math.floor((xx-x-1)/#text) then
					spl = math.floor(#text/(xx-x-1)) + 1
				else
					spl = math.floor(#text/(xx-x-1))
				end
				remider = #text%(xx-x)
			end

			for i=0 , math.min(spl , yy-y - 4) do
				vterm:writeText(x + 1 , y + 1 + i , string.sub(text , (xx-x-1)*i+1 , (xx-x - 1)*(i+1) - 1) , nil , nil , nil)
			end
			return vterm
		end)
	end
end

RMP.Notify = OOP.class("Notify" , RMP.Popup)
do
	function RMP.Notify:constructor(
		time,		-- the time will live on the Frame , should be ms
		fps,		-- the fps time
		message		-- the message
	)
		self.message = message or ""
		self.time = time
		self.counter = 0
		self.fps = fps
	end

	function RMP.Notify:setMessage(message)
		self.message = message or ""
	end

	function RMP.Notify:reset()
		self.counter = 0
	end

	function RMP.Notify:error(poslayout)
		local poslayout = poslayout or RMP.PopupPosition.CENTER

		if self.counter < math.floor(self.fps*self.time/(self.fps/10)) then
			self.counter = self.counter + 1
			return self:super( 
				"run" ,
					self.message, 
					RMP.Text.new(
						"[ " .. "ERROR" .. " ]", 
						RMP.TextStyle.Bold , 
						RMP.FGColors.NoBrights.White,
						RMP.BGColors.NoBrights.BGRed
					), 
					RMP.FGColors.NoBrights.Red , 
					nil,
					poslayout
			)
		end
	end

	function RMP.Notify:info(poslayout)
		local poslayout = poslayout or RMP.PopupPosition.CENTER

		if self.counter < self.time then
			self.counter = self.counter + self.delta
			return self:super(
				"run",
					self.message ,
					RMP.Text.new(
						"[ " .. "INFO" .. " ]" , 
						RMP.TextStyle.Bold , 
						RMP.FGColors.NoBrights.White , 
						RMP.BGColors.NoBrights.Green
					), 
					RMP.FGColors.NoBrights.Green , 
					nil,
					poslayout
			)
		end
	end

	function RMP.Notify:message(poslayout)
		local poslayout = poslayout or RMP.PopupPosition.CENTER

		if self.counter < self.time then
			self.counter = self.counter + self.delta
			return self:super(
				"run",
					self.message ,  
					RMP.Text.new(
						"[ " .. "Message" .. " ]" , 
						RMP.TextStyle.Bold , 
						RMP.FGColors.NoBrights.White,
						RMP.BGColors.NoBrights.Blue
					), 
					RMP.FGColors.NoBrights.Blue , 
					nil,
					poslayout
			)
		end
	end

	function RMP.Notify:warning(poslayout)
		local poslayout = poslayout or RMP.PopupPosition.CENTER

		if self.counter < self.time then
			self.counter = self.counter + self.delta
			return self:super(
				"run",
					self.message ,  
					RMP.Text.new(
						"[ " .. "Warning" .. " ]" , 
						RMP.TextStyle.Bold , 
						RMP.FGColors.NoBrights.White,
						RMP.BGColors.NoBrights.Yellow
					), 
					RMP.FGColors.NoBrights.Yellow , 
					nil,
					poslayout

			)
		end
	end
end

-- Scroller class
-- Assosiative relation with Options class
RMP.Scroller = OOP.class("Scroller")
do	-- Scroller
	function RMP.Scroller:constructor(h, optObj)
		self.h = h
		self.data = optself:getOptions()
		self.cur = 0
		self.options = optself:setOptions(self:getSlice())
		return self
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

RMP.PLAYLIST_LOOP 	= enum(true)
RMP.SINGLE_LOOP 	= enum()
RMP.ONES 		= enum()

RMP.Sound = OOP.class("Sound")
do 	-- Sound
	function RMP.Sound:constructor(array_sounds)
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

RMP.Path = OOP.class("Path")
do	-- Path
	function RMP.Path:constructor(path)
		self.path = path or self:getCurrentPath()
	end

	function RMP.Path:setPath(path)
		self.path = path
	end

	function RMP.Path:getPath()
		return self.path
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
RMP.Config = OOP.class("Config")
do 	-- Config

	-- TODO: if load configuration failed we should run the default themes and plugins
	-- TODO: check windows version
	function RMP.Config:constructor(confPath)
		self.cfgObj = nil
		self.isValidFile = false
		self.isError = nil

		self.currentPath = RMP.Path.new()
		self.homePath = RMP.Path.new(self.currentPath:getHomePath())

		if not self.homePath:find(".rmp" , false) then
			self.isError = ".rmp directory not found in home dir"
			return
		end

		self.configurationPath = RMP.Path.new(self.homePath:getPath().."/.rmp/")

		if not self.configurationPath:find("init.lua" , true) then
			self.isError = "init.lua not found in .rmp dir"
			return
		end

		self.initPath = RMP.Path.new(self.configurationPath:getPath().."/init.lua") -- this path should be required
		self.isValidFile = true

		return self
	end

	function RMP.Config:load() -- (boolean , Error)
		if not self.isValidFile then
			return false , self.isError
		end

		if not self.cfgObj then
			local ok , res = pcall(function()
				return dofile(self.initPath:getPath())
			end)

			if not ok then -- not okay :`(
				self.isError = "failed to load init.lua configuration file: " .. tostring(res)
				return false , self.isError
			end

			if type(res) ~= "table" then
				self.isError = "init.lua file must return a table , check documentation"
				return false , self.isError
			end
			self. cfgObj = res
		end
		return true , nil
	end

	function RMP.Config:isValidConfig()
		return self.isValidFile and self.cfgObj ~= nil
	end

	function RMP.Config:getInitFileAsObject()
		if self.cfgObj and type(self.cfgObj) == "table" then
			return self.cfgObj
		end
		return nil
	end

	function RMP.Config:getThemesAsObject()
		if self.cfgObj and self.cfgObj.theme and type(self.cfgObj.theme) == "string" then
			return self.cfgObj.theme
		end
		return nil
	end

	function RMP.Config:getSoundKeyMaps()
		if self.cfgObj and self.cfgObj.soundMap and type(self.cfgObj.soundMap) == "table" then
			return self.cfgObj.soundMap
		end
		-- redefine keymaps if not found on configuration file
		return {}
	end

	function RMP.Config:getAllPlugins()
		if not self.cfgObj or not self.cfgObj.plugins or type(self.cfgObj.plugins) ~= "table" then
			return {}
		end
		return self.cfgObj.plugins
	end

	function RMP.Config:getPluginFromThemeWindowId(id)

		if not self.cfgObj or not self.cfgObj.plugins or type(self.cfgObj.plugins) ~= "table" then
			return nil
		end

		local id = id or 0

		for _ , obj in ipairs(self.cfgObj.plugins) do
			if obj.themeWindowId and obj.isActivated and obj.name then
				if id == obj.themeWindowId then
					local ok , res = pcall(function() 
						local pluginPath = RMP.Path.new(self.initPath:getPath().."/plugins/"..obj.name.."/")
						if not pluginPath:find(obj.name..".lua" , true) then
							return nil
						end
						return dofile(pluginPath:getPath()..onj.name..".lua")
					end)

					if ok and res then
						return res , nil
					else
						return nil , "Warning: Failed to load plugin '" .. obj.name .. "': " .. tostring(res)
					end
				end
			end
		end

		return nil
		-- TODO: handle multiple plugins in same window , and check the input key to change between them
		-- search key id in table and return the callback function 
	end

	function RMP.Config:getLoadError()
		return self.isError
	end
end

-- TODO: create Frame class
-- /////////////////////////////////////////////////////
-- Hight Level API
-- /////////////////////////////////////////////////////

RMP.Frame = OOP.class("Frame" , RMP.VirtualTerminal)
do
	function RMP.Frame:constructor(width , heigth)
		self:super("constructor", width , heigth)
		self.fps = 30
	end

	function RMP.Frame:setFps(fps)
		self.fps = fps
	end

	function RMP.Frame:getFps()
		return self.fps
	end

	function RMP.Frame:getDeltaTime()
		return 1/self.fps -- second
	end

	function RMP.Frame:positionedFrame(x , y)
		local x = x or 1
		local y = y or 1
		self:super("moveCursor" , x , y)
	end

	function RMP.Frame:add(component)
		self:super("merge" , component)
	end

	function RMP.Frame:run()
		self:super("render")
		self:super("clear")
		RMP.sleep(math.floor(RMP.Duration.new(self:getDeltaTime()):fromSec()))
	end
end

-- you don't have to think about yield or another loop
-- just accept boundries and return virtual terminal object
function RMP.plug(callback)
	return RMP.quickRoutine(function(x,y,xx,yy) 
		while true do
			coroutine.yield(callback(x,y,xx,yy))
		end
	end)
end

-- TODO: create ComponentManager
RMP.Plug = OOP.class("Plug")
do
	function RMP.Plug:constructor()
		io.write("Plug not implemented")
	end
end

return RMP

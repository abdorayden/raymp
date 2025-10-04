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

RMP = {}

local io = require("io")
local keyboard = require("rmp.keyboard")
local rmpaudio = require("rmp.rmpaudio")
local sleep = require("rmp.sleep")
local platform = require("rmp.platform")
local directory = require("rmp.directory")
local window = require("rmp.window")
local vt_rmp = require("rmp.virtualterminalrmp")

-- require rmp utility
local OOP = require("rmp.oop")
-- TODO: make some functions async
local Promise = require("rmp.promises")
local Util = require("rmp.util")

local HashMap = Util.HashMap
local Queue = Util.Queue

local global_count_enum = -1
function RMP.enum(reset, value, start)
    reset = reset or false
    value = value or 1
    start = start or -1

    if reset then
        global_count_enum = start
    end
    global_count_enum = global_count_enum + value
    return global_count_enum
end

do -- os detection
    RMP.PlatformType = {
        LINUX   = RMP.enum(true),
        WINDOWS = RMP.enum(),
        MAC     = RMP.enum(),
        UNKOW   = RMP.enum()
    }

    function RMP.getOs() -- it will return enum value
        return platform.platform()
    end
end

RMP.quickRoutine        = function(func)
    return coroutine.create(func)
end

-- check ansi escape code : https://en.wikipedia.org/wiki/ANSI_escape_code
-- line style
RMP.TextStyle           = {
    Strike              = "\27[9m",
    Hide                = "\27[8m",
    SlowBlink           = "\27[5m",
    OverUnderline       = "\27[53m",
    Underline           = "\27[4m",
    DoubleUnderline     = "\27[21m",
    Italic              = "\27[3m",
    Bold                = "\27[1m",
    RapidBlink          = "\27[6m",
    Faint               = "\27[2m",
    Reverse             = "\27[7m",
    Framed              = "\27[51m",
    Encircled           = "\27[52m",
    Overline            = "\27[55m",
    ProportionalSpacing = "\27[26m",
    Superscript         = "\27[73m",
    Subscript           = "\27[74m",
    Regular             = "\27[0m"
}

-- colors
-- TODO: handle colors using ColorFromHex
-- ForeGround
RMP.FGColors            = {
    NoBrights = {
        Black   = "\27[30m",
        Red     = "\27[31m",
        Green   = "\27[32m",
        Yellow  = "\27[33m",
        Blue    = "\27[34m",
        Magenta = "\27[35m",
        Cyan    = "\27[36m",
        White   = "\27[37m"
    },
    Brights = {
        -- ForeGround bright
        Black   = "\27[90m",
        Red     = "\27[91m",
        Green   = "\27[92m",
        Yellow  = "\27[93m",
        Blue    = "\27[94m",
        Magenta = "\27[95m",
        Cyan    = "\27[96m",
        White   = "\27[97m"
    }
}

-- BackGround
RMP.BGColors            = {
    NoBrights = {
        Black   = "\27[40m",
        Red     = "\27[41m",
        Green   = "\27[42m",
        Yellow  = "\27[43m",
        Blue    = "\27[44m",
        Magenta = "\27[45m",
        Cyan    = "\27[46m",
        White   = "\27[47m"
    },
    Brights = {
        -- BackGround bright
        Black   = "\27[100m",
        Red     = "\27[101m",
        Green   = "\27[102m",
        Yellow  = "\27[103m",
        Blue    = "\27[104m",
        Magenta = "\27[105m",
        Cyan    = "\27[106m",
        White   = "\27[107m"
    }
}
-- Imojis
RMP.File_pos            = "➯"
RMP.Pause_start         = "⏯"
RMP.Next                = "⏵"
RMP.Prev                = "⏴"
RMP.Ext                 = "⏻"
RMP.Rep                 = "⭯"
RMP.Pause               = "⏸"
RMP.Volume_max          = "🔊"
RMP.Volume_mute         = "🔇"
RMP.Volume_low          = "🔈"
RMP.Volume_med          = "🔉"

RMP.Single_loop         = "🔂"
RMP.Playlist_loop       = "🔁"
RMP.Ones                = "ONES"
RMP.Shufle              = "🔀"

RMP.Snow                = "❆"
RMP.Stars               = "✨"

RMP.Search_emo          = "🔎"

RMP.Song_char_1         = "💕"
RMP.Song_char_2         = "💞"
RMP.Song_char_3         = "🎵"
RMP.Song_char_4         = "🎶"
RMP.Song_char_5         = "💖"

RMP.Bar_1               = "❚"
RMP.Bar_2               = "❙"
RMP.Bar_3               = "❘"

RMP.Bar_l_to_r_12_5_per = "▏"
RMP.Bar_l_to_r_25_per   = "▎"
RMP.Bar_l_to_r_37_5_per = "▍"
RMP.Bar_l_to_r_50_per   = "▌"
RMP.Bar_l_to_r_62_5_per = "▋"
RMP.Bar_l_to_r_75_per   = "▊"
RMP.Bar_l_to_r_87_5_per = "▉"

RMP.Bar_b_to_u_12_5_per = "▇"
RMP.Bar_b_to_u_25_per   = "▆"
RMP.Bar_b_to_u_37_5_per = "▅"
RMP.Bar_b_to_u_50_per   = "▄"
RMP.Bar_b_to_u_62_5_per = "▃"
RMP.Bar_b_to_u_75_per   = "▂"
RMP.Bar_b_to_u_87_5_per = "▁"

RMP.Bar_Shading_00_per  = " "
RMP.Bar_Shading_25_per  = "░"
RMP.Bar_Shading_50_per  = "▒"
RMP.Bar_Shading_75_per  = "▓"

RMP.Bar_100_per         = "█"

-- RMP.CheckMark 	= "✔"
-- RMP.Error 		= "✗"

RMP.IError              = "❌"
RMP.IWarning            = "⚠️"
RMP.IMessage            = "💬"
RMP.IInfo               = "ℹ️"

-- TODO: create table class to create tables
RMP.Table               = OOP.class("Table")
do
    -- advanced table class
    function RMP.Table:constructor(data)
        self.data = data or {}
        return self
    end

    function RMP.Table:addRow(row)
        table.insert(self.data, row)
        return self
    end

    function RMP.Table:getRow(index)
        return self.data[index]
    end

    function RMP.Table:getData()
        return self.data
    end

    function RMP.Table:removeRow(index)
        table.remove(self.data, index)
        return self
    end

    function RMP.Table:clear()
        self.data = {}
        return self
    end

    function RMP.Table:size()
        return #self.data
    end
end

-- TODO: handle this border table later to let plugin developers change the border

RMP.BoxDrawing = {
    -- TODO: api.BoxDrawing.NoBorder
    LightBorder = {
        -- Light border set (single-line)
        "─", -- Light horizontal line (U+2500)
        "│", -- Light vertical line (U+2502)
        "┌", -- Light down and right corner (U+250C)
        "┐", -- Light down and left corner (U+2510)
        "└", -- Light up and right corner (U+2514)
        "┘", -- Light up and left corner (U+2518)
        "├", -- Light vertical and right tee (U+251C)
        "┤", -- Light vertical and left tee (U+2524)
        "┬", -- Light down and horizontal tee (U+252C)
        "┴", -- Light up and horizontal tee (U+2534)
        "┼", -- Light vertical and horizontal cross (U+253C)
    },
    HeavyBorder = {
        -- Heavy border set (double-line)
        "═", -- Heavy horizontal line (U+2550)
        "║", -- Heavy vertical line (U+2551)
        "╔", -- Heavy down and right corner (U+2554)
        "╗", -- Heavy down and left corner (U+2557)
        "╚", -- Heavy up and right corner (U+255A)
        "╝", -- Heavy up and left corner (U+255D)
        "╠", -- Heavy vertical and right tee (U+2560)
        "╣", -- Heavy vertical and left tee (U+2563)
        "╦", -- Heavy down and horizontal tee (U+2566)
        "╩", -- Heavy up and horizontal tee (U+2569)
        "╬", -- Heavy vertical and horizontal cross (U+256C)
    },
    RoundedCorners = {
        "─", -- Light horizontal line (U+2500)
        "│", -- Light vertical line (U+2502)
        "╭", -- Light down and right corner (U+250C)
        "╮", -- Light down and left corner (U+2510)
        "╰", -- Light up and right corner (U+2514)
        "╯", -- Light up and left corner (U+2518)
        "├", -- Light vertical and right tee (U+251C)
        "┤", -- Light vertical and left tee (U+2524)
        "┬", -- Light down and horizontal tee (U+252C)
        "┴", -- Light up and horizontal tee (U+2534)
        "┼", -- Light vertical and horizontal cross (U+253C)
    },
    RoundedBorder = RMP.BoxDrawing.RoundedCorners
}

-- TODO: create class Animation for handling diffrent animation
-- for animation
RMP.BraillePattern = {
    "⠁", "⠃", "⠇", "⠏", "⠟", "⠿", "⣿", "⡿",
    "⣟", "⣯", "⣷", "⣾", "⣿"
}

do -- color from hex
    RMP.FG = "38"
    RMP.BG = "48"

    function RMP.colorFromHex(hex, fg_or_bg)
        local fb = fg_or_bg or "38"
        local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
        return string.format("\27[%s;2;%d;%d;%dm", fb, r, g, b)
    end
end

RMP.Default = "\27[0m"

-- TODO: for a moment
local function moveto(x, y, ret)
    ret = ret or false
    if ret then
        return "\27[" .. y .. ";" .. x .. "H"
    else
        io.write("\27[" .. y .. ";" .. x .. "H")
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
do -- text
    -- constructor
    -- TODO: fix the error
    function RMP.Text:constructor(text, style, fg, bg)
        self.vterm = RMP.VirtualTerminal.new()
        self.text = text or ""
        self.fg = fg or RMP.Default
        self.bg = bg or RMP.Default
        self.style = style or RMP.Default
        self.x = 1
        self.y = 1
        return self
    end

    -- -- method Position in lua used to controle position of the text
    function RMP.Text:setPosition(x, y)
        self.x = tonumber(x or 1)
        self.y = tonumber(y or 1)
        return self
    end

    function RMP.Text:asVTerm()
        self.vterm:writeText(self.x, self.y, self.text, self.fg, self.bg, self.style)
        return self.vterm
    end

    -- ColoredText accept text and color and return colored text
    function RMP.Text:getColoredText()
        return self.style .. self.bg .. self.fg .. self.text .. RMP.Default
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

-- the RMP.enumeration value returns from HandleKey input
-- TODO: api.KEY_ALT_A, api.KEY_ALT_B, ...  Alt combinations
RMP.KEY_CTRL_A        = RMP.enum(true)
RMP.KEY_CTRL_B        = RMP.enum()
RMP.KEY_CTRL_C        = RMP.enum()
RMP.KEY_CTRL_D        = RMP.enum()
RMP.KEY_CTRL_E        = RMP.enum()
RMP.KEY_CTRL_F        = RMP.enum()
RMP.KEY_CTRL_G        = RMP.enum()
RMP.KEY_CTRL_H        = RMP.enum()
RMP.KEY_CTRL_K        = RMP.enum()
RMP.KEY_CTRL_L        = RMP.enum()
RMP.KEY_CTRL_M        = RMP.enum()
RMP.KEY_CTRL_N        = RMP.enum()
RMP.KEY_CTRL_O        = RMP.enum()
RMP.KEY_CTRL_P        = RMP.enum()
RMP.KEY_CTRL_Q        = RMP.enum()
RMP.KEY_CTRL_R        = RMP.enum()
RMP.KEY_CTRL_S        = RMP.enum()
RMP.KEY_CTRL_T        = RMP.enum()
RMP.KEY_CTRL_U        = RMP.enum()
RMP.KEY_CTRL_V        = RMP.enum()
RMP.KEY_CTRL_W        = RMP.enum()
RMP.KEY_CTRL_X        = RMP.enum()
RMP.KEY_CTRL_Y        = RMP.enum()
RMP.KEY_CTRL_Z        = RMP.enum()
RMP.KEY_ENTER         = RMP.enum()
RMP.KEY_SPACE         = RMP.enum()
RMP.KEY_ESCAPE        = RMP.enum()
RMP.KEY_UP            = RMP.enum()
RMP.KEY_DOWN          = RMP.enum()
RMP.KEY_LEFT          = RMP.enum()
RMP.KEY_RIGHT         = RMP.enum()
RMP.KEY_TAB           = RMP.enum()
RMP.KEY_DELETE        = RMP.enum()
RMP.KEY_HOME          = RMP.enum()
RMP.KEY_END           = RMP.enum()
RMP.KEY_BACKSPACE     = RMP.enum()

RMP.KEY_A             = RMP.enum()
RMP.KEY_B             = RMP.enum()
RMP.KEY_C             = RMP.enum()
RMP.KEY_D             = RMP.enum()
RMP.KEY_E             = RMP.enum()
RMP.KEY_F             = RMP.enum()
RMP.KEY_G             = RMP.enum()
RMP.KEY_H             = RMP.enum()
RMP.KEY_I             = RMP.enum()
RMP.KEY_J             = RMP.enum()
RMP.KEY_K             = RMP.enum()
RMP.KEY_L             = RMP.enum()
RMP.KEY_M             = RMP.enum()
RMP.KEY_N             = RMP.enum()
RMP.KEY_O             = RMP.enum()
RMP.KEY_P             = RMP.enum()
RMP.KEY_Q             = RMP.enum()
RMP.KEY_R             = RMP.enum()
RMP.KEY_S             = RMP.enum()
RMP.KEY_T             = RMP.enum()
RMP.KEY_U             = RMP.enum()
RMP.KEY_V             = RMP.enum()
RMP.KEY_W             = RMP.enum()
RMP.KEY_X             = RMP.enum()
RMP.KEY_Y             = RMP.enum()
RMP.KEY_Z             = RMP.enum()
RMP.KEY_SHIFT_A       = RMP.enum()
RMP.KEY_SHIFT_B       = RMP.enum()
RMP.KEY_SHIFT_C       = RMP.enum()
RMP.KEY_SHIFT_D       = RMP.enum()
RMP.KEY_SHIFT_E       = RMP.enum()
RMP.KEY_SHIFT_F       = RMP.enum()
RMP.KEY_SHIFT_G       = RMP.enum()
RMP.KEY_SHIFT_H       = RMP.enum()
RMP.KEY_SHIFT_I       = RMP.enum()
RMP.KEY_SHIFT_J       = RMP.enum()
RMP.KEY_SHIFT_K       = RMP.enum()
RMP.KEY_SHIFT_L       = RMP.enum()
RMP.KEY_SHIFT_M       = RMP.enum()
RMP.KEY_SHIFT_N       = RMP.enum()
RMP.KEY_SHIFT_O       = RMP.enum()
RMP.KEY_SHIFT_P       = RMP.enum()
RMP.KEY_SHIFT_Q       = RMP.enum()
RMP.KEY_SHIFT_R       = RMP.enum()
RMP.KEY_SHIFT_S       = RMP.enum()
RMP.KEY_SHIFT_T       = RMP.enum()
RMP.KEY_SHIFT_U       = RMP.enum()
RMP.KEY_SHIFT_V       = RMP.enum()
RMP.KEY_SHIFT_W       = RMP.enum()
RMP.KEY_SHIFT_X       = RMP.enum()
RMP.KEY_SHIFT_Y       = RMP.enum()
RMP.KEY_SHIFT_Z       = RMP.enum()
RMP.KEY_0             = RMP.enum()
RMP.KEY_1             = RMP.enum()
RMP.KEY_2             = RMP.enum()
RMP.KEY_3             = RMP.enum()
RMP.KEY_4             = RMP.enum()
RMP.KEY_5             = RMP.enum()
RMP.KEY_6             = RMP.enum()
RMP.KEY_7             = RMP.enum()
RMP.KEY_8             = RMP.enum()
RMP.KEY_9             = RMP.enum()
RMP.KEY_PLUS          = RMP.enum()
RMP.KEY_MINUS         = RMP.enum()
RMP.KEY_GT            = RMP.enum()
RMP.KEY_LT            = RMP.enum()
RMP.KEY_HASHTAG       = RMP.enum()
RMP.KEY_DOLAR         = RMP.enum()
RMP.KEY_PERSANT       = RMP.enum()
RMP.KEY_STAR          = RMP.enum()
RMP.KEY_DOT           = RMP.enum()
RMP.KEY_UNDERS        = RMP.enum()
RMP.KEY_SEMICOL       = RMP.enum()
RMP.KEY_QUISTION_MARK = RMP.enum()
RMP.KEY_AT            = RMP.enum()
RMP.KEY_OPCURB        = RMP.enum()
RMP.KEY_CLCURB        = RMP.enum()
RMP.KEY_BACK_SLASH    = RMP.enum()
RMP.KEY_BACKTICK      = RMP.enum()
RMP.KEY_OPEN_BRAKET   = RMP.enum()
RMP.KEY_CLOSED_BRAKET = RMP.enum()
RMP.KEY_BAR           = RMP.enum()
RMP.KEY_DBL_QUOTE     = RMP.enum()
RMP.KEY_SINGLE_QOUTE  = RMP.enum()
RMP.KEY_SLASH         = RMP.enum()
RMP.KEY_COLON         = RMP.enum()
RMP.KEY_COMMA         = RMP.enum()
RMP.NONE              = RMP.enum()

RMP.Window            = OOP.class("Window")
do -- creating window
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

    function RMP.Window:createWindow(title, width, height, x, y, border_color, background_color, border_style, callback)
        local vterm = RMP.VirtualTerminal.new()

        if not width and not height and not x and not y then
            return
        end

        vterm:drawBox(title, math.floor(x), math.floor(y), math.floor(width), math.floor(height), border_style,
            border_color, background_color)

        if callback ~= nil and type(callback) == "function" then
            local lvt = callback(math.floor(x + 1), math.floor(y + 1), math.floor(x + width - 1),
                math.floor(y + height - 1))
            if lvt ~= nil then
                vterm:merge(lvt) -- handle async
            end
        end

        return vterm
    end
end

-- TODO: create Mouse class

RMP.Mouse = OOP.class("Mouse")
do
    function RMP.Mouse:constructor(x, y, button, action)
        self.x = x or 0
        self.y = y or 0
        self.button = button or nil
        self.action = action or nil
        return self
    end

    function RMP.Mouse:getX()
        return self.x
    end

    function RMP.Mouse:getY()
        return self.y
    end

    function RMP.Mouse:getButton()
        return self.button
    end

    function RMP.Mouse:getAction()
        return self.action
    end
end


-- TODO: create Menu class

RMP.Menu = OOP.class("Menu")
do
    function RMP.Menu:constructor(title, options)
        self.title = title or "Menu"
        self.options = options or {}
        self.selected_index = 1
        return self
    end

    function RMP.Menu:addOption(option)
        table.insert(self.options, option)
        return self
    end

    function RMP.Menu:removeOption(index)
        table.remove(self.options, index)
        return self
    end

    function RMP.Menu:getOptions()
        return self.options
    end

    function RMP.Menu:getTitle()
        return self.title
    end

    function RMP.Menu:setSelectedIndex(index)
        if index >= 1 and index <= #self.options then
            self.selected_index = index
        end
        return self
    end

    function RMP.Menu:getSelectedIndex()
        return self.selected_index
    end

    function RMP.Menu:getSelectedOption()
        return self.options[self.selected_index]
    end
end

-- TODO: create MenuItems class

RMP.MenuItem = OOP.class("MenuItem")
do
    function RMP.MenuItem:constructor(label, action)
        self.label = label or "Item"
        self.action = action or function() end
        return self
    end

    function RMP.MenuItem:getLabel()
        return self.label
    end

    function RMP.MenuItem:setLabel(label)
        self.label = label
        return self
    end

    function RMP.MenuItem:getAction()
        return self.action
    end

    function RMP.MenuItem:setAction(action)
        if type(action) == "function" then
            self.action = action
        end
        return self
    end

    function RMP.MenuItem:execute()
        if type(self.action) == "function" then
            self.action()
        end
        return self
    end
end

-- EventType used to define the type of event
-- each plugin can add event listener for a specific event type
-- and when the event is triggered the callback function is called
RMP.EventType = {
    -- TODO: add event special for audio engine , for better controle
    Keyboard = RMP.enum(true), -- this Keyboard event's for actions

    -- Input Event lazem tkon kayn condition to add the Event each time we called a plugin wich means ida makanch kayen had event
    -- nkmlo fl events lokhrin and that't it
    -- also this Input Event should used it in Input class Only so when we initialize the Input and start read from user we add this event to the EventListener
    Focuse = RMP.enum(), -- Input event disbale listinnig other Events because the user is writing something
    Mouse = RMP.enum(),  -- mouse event
    -- transform data event is the way to handle data transformation between two plugins
    -- TODO: factor Get and Put
    -- Transform = {
    --	Get = RMP.enum(),
    --	Put = RMP.enum()
    -- }
    TransformDataGet = RMP.enum(), -- Get data event is used to get data from another plugin
    TransformDataPut = RMP.enum(), -- Put data event is used to put data to another plugin
    -- sound
    Sound = RMP.enum(),            -- plugins can add event for sound
    -- the callback function accept sound object so they can add or get informations like freqs , so they can create visualization
    Engine = RMP.enum(),           -- Engine Event to apply a commands on the engine
    Configuration = RMP.enum()     -- get access to the configurations also save a new configuration
}

local Event = OOP.interface("Event",
    -- @param key : RMP.EventType value
    -- @callback : function to call when the event is triggered
    -- @return : self
    "addEventListener"
)

-- EventListener class used to handle events
-- each plugin should have his own EventListener object
-- so when the plugin is initialized it create his own EventListener object
-- and add event listener for the events he want to listen to
-- when the event is triggered the callback function is called
RMP.EventListener = OOP.class("EventListener", nil, Event)
do
    function RMP.EventListener:constructor()
        self.events = HashMap.new()
        self.events:put(RMP.EventType.Keyboard, Queue.new())
        self.events:put(RMP.EventType.Mouse, Queue.new())
        self.events:put(RMP.EventType.Focuse, Queue.new())

        self.events:put(RMP.EventType.TransformDataGet, Queue.new())
        self.events:put(RMP.EventType.TransformDataPut, Queue.new())

        self.events:put(RMP.EventType.Sound, Queue.new())

        return self
    end

    -- Override method
    -- @param key : RMP.EventType value
    -- @callback : function to call when the event is triggered
    -- @return : self
    function RMP.EventListener:addEventListener(event, callback)
        if event == nil then
            return nil
        end

        local thatQueue = self.events:get(event)
        if thatQueue ~= nil then
            thatQueue:push(callback)
            self.events:put(event, thatQueue)
        end

        return self
    end

    function RMP.EventListener:onSound(callback)
        return self:addEventListener(RMP.EventType.Sound, callback)
    end

    function RMP.EventListener:onKeyboard(callback)
        return self:addEventListener(RMP.EventType.Keyboard, callback)
    end

    function RMP.EventListener:onMouse(callback)
        return self:addEventListener(RMP.EventType.Mouse, callback)
    end

    function RMP.EventListener:onFocuse(callback)
        return self:addEventListener(RMP.EventType.Focuse, callback)
    end

    -- @param key : RMP.EventType value
    -- @return : self
    -- rename it to handleEvent
    -- TODO: add sound
    function RMP.EventListener:handleEvent(key, mouse, sound)
        -- TODO: make sure that processTransformDataEvents is working fine with complicated cases
        local put_queue = self.events:get(RMP.EventType.TransformDataPut)
        local get_queue = self.events:get(RMP.EventType.TransformDataGet)

        while not put_queue:isEmpty() and not get_queue:isEmpty() do
            local put_callback = put_queue:pop()
            local get_callback = get_queue:pop()

            if put_callback and type(put_callback) == 'function' and
                get_callback and type(get_callback) == 'function' then
                local data = put_callback()
                get_callback(data)
            end
        end

        local sound_queue = self.events:get(RMP.EventType.Sound)
        while not sound_queue:isEmpty() do
            local tha_callback = sound_queue:pop()
            if tha_callback and type(tha_callback) == 'function' then
                tha_callback(sound)
            end
        end

        if key then
            if not self.events:get(RMP.EventType.Focuse):isEmpty() then
                while not self.events:get(RMP.EventType.Focuse):isEmpty() do
                    local callback = self.events:get(RMP.EventType.Focuse):pop()
                    if callback and type(callback) == 'function' then
                        callback(key)
                    end
                end
            else
                while not self.events:get(RMP.EventType.Keyboard):isEmpty() do
                    local callback = self.events:get(RMP.EventType.Keyboard):pop()
                    if callback and type(callback) == 'function' then
                        callback(key)
                    end
                end
            end
            return self
        end

        if mouse then
            while not self.events:get(RMP.EventType.Mouse):isEmpty() do
                local callback = self.events:get(RMP.EventType.Mouse):pop()
                if callback and type(callback) == 'function' then
                    callback(mouse)
                end
            end
            return self
        end

        return nil
    end

    function RMP.EventListener:getEvent()
        return self.events
    end
end

-- all components should return VirtualTerminal obj
-- VirtualTerminal class used to create a virtual terminal
-- each plugin should have his own VirtualTerminal object
-- so when the plugin is initialized it create his own VirtualTerminal object
-- and draw on it
RMP.VirtualTerminal = OOP.class("VirtualTerminal", RMP.EventListener)
do                                                          -- VirtualTerminal
    function RMP.VirtualTerminal:constructor(width, height) -- constructor
        self:super("constructor")
        local h, w = window.get_size()

        self.realWidth = width or w
        self.realHeight = height or h

        self.native_vt_rmp = vt_rmp.init(self.realWidth, self.realHeight)
        self.cursor = { x = 1, y = 1 }
        self:clear()
        return self
    end

    function RMP.VirtualTerminal:clear()
        -- self.events:clear()
        vt_rmp.clear(self.native_vt_rmp)
    end

    function RMP.VirtualTerminal:setChar(x, y, char, fg, bg, style)
        x = x or self.cursor.x
        y = y or self.cursor.y
        vt_rmp.setchar(self.native_vt_rmp, x, y, char, fg, bg, style)
        return self
    end

    function RMP.VirtualTerminal:writeTextClipped(x, y, text, width, fg, bg, style)
        if not text then
            return
        end
        x = math.floor(x or self.cursor.x)
        y = math.floor(y or self.cursor.y)
        vt_rmp.writetext_clipped(self.native_vt_rmp, x, y, text, width, fg, bg, style)
        return self
    end

    function RMP.VirtualTerminal:writeText(x, y, text, fg, bg, style)
        if not text then
            return
        end
        x = math.floor(x or self.cursor.x)
        y = math.floor(y or self.cursor.y)
        vt_rmp.writetext(self.native_vt_rmp, x, y, text, fg, bg, style)
        return self
    end

    function RMP.VirtualTerminal:drawBox(title, x, y, width, height, border_style, fg, bg)
        x = math.floor(x or 1)
        y = math.floor(y or 1)
        width = math.floor(width or 80)
        height = math.floor(height or 24)

        if border_style == nil or type(border_style) ~= 'table' or border_style[1] == nil then
            TL = RMP.BoxDrawing.LightBorder[3] -- "┌" Top-left corner
            TR = RMP.BoxDrawing.LightBorder[4] -- "┐" Top-right corner
            BL = RMP.BoxDrawing.LightBorder[5] -- "└" Bottom-left corner
            BR = RMP.BoxDrawing.LightBorder[6] -- "┘" Bottom-right corner
            H  = RMP.BoxDrawing.LightBorder[1] -- "─" Horizontal line
            V  = RMP.BoxDrawing.LightBorder[2] -- "│" Vertical line
        else
            TL = border_style[3]               -- "┌" Top-left corner
            TR = border_style[4]               -- "┐" Top-right corner
            BL = border_style[5]               -- "└" Bottom-left corner
            BR = border_style[6]               -- "┘" Bottom-right corner
            H  = border_style[1]               -- "─" Horizontal line
            V  = border_style[2]               -- "│" Vertical line
        end

        local end_x = math.min(x + width - 1, self.realWidth)
        local end_y = math.min(y + height - 1, self.realHeight)


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

        if title and title ~= "" and title:instanceOf(RMP.Text) then
            local title_text = title:getText()
            local available_width = width - 2
            if #title_text > available_width then
                title_text = title_text:sub(1, available_width)
            end
            local title_x = x + 1 + math.floor((available_width - #title_text) / 2)
            local title_y = y
            self:writeText(title_x, title_y, title_text, title:getFGColor(), title:getBGColor(), title:getStyle())
        end

        self.dirty = true
    end

    function RMP.VirtualTerminal:render()
        vt_rmp.render(self.native_vt_rmp)
    end

    function RMP.VirtualTerminal:moveCursor(x, y)
        vt_rmp.movecursor(self.native_vt_rmp, x, y)
    end

    function RMP.VirtualTerminal:moveUp(y)
        vt_rmp.moveup(self.native_vt_rmp, y or 1)
    end

    function RMP.VirtualTerminal:moveDown(y)
        vt_rmp.movedown(self.native_vt_rmp, y or 1)
    end

    function RMP.VirtualTerminal:moveRight(x)
        vt_rmp.moveright(self.native_vt_rmp, x or 1)
    end

    function RMP.VirtualTerminal:moveLeft(x)
        vt_rmp.moveleft(self.native_vt_rmp, x or 1)
    end

    function RMP.VirtualTerminal:getSize()
        return vt_rmp.getsize(self.native_vt_rmp)
    end

    function RMP.VirtualTerminal:resize(width, height)
        if width ~= w or height ~= h then
            vt_rmp.resize(self.native_vt_rmp, width, height)
        end
    end

    function RMP.VirtualTerminal:getVT()
        return self.native_vt_rmp
    end

    -- these methods are used to merge two virtual terminal
    -- if there is no way to pass vterm object to function parameters
    -- so you can merge the other virtual terminal to the main object
    function RMP.VirtualTerminal:merge(thatTerm, offsetX, offsetY)
        if thatTerm and thatTerm:instanceOf(RMP.VirtualTerminal) then
            vt_rmp.merge(self.native_vt_rmp, thatTerm:getVT(), offsetX or 0, offsetY or 0)

            local event = thatTerm:getEvent()
            if event:instanceOf(HashMap) then
                local myevent = self:getEvent()

                while not event:get(RMP.EventType.Focuse):isEmpty() do
                    myevent:get(RMP.EventType.Focuse):push(event:get(RMP.EventType.Focuse):pop())
                end

                while not event:get(RMP.EventType.Keyboard):isEmpty() do
                    myevent:get(RMP.EventType.Keyboard):push(event:get(RMP.EventType.Keyboard):pop())
                end

                while not event:get(RMP.EventType.Mouse):isEmpty() do
                    myevent:get(RMP.EventType.Mouse):push(event:get(RMP.EventType.Mouse):pop())
                end

                while not event:get(RMP.EventType.TransformDataPut):isEmpty() do
                    myevent:get(RMP.EventType.TransformDataPut):push(event:get(RMP.EventType.TransformDataPut):pop())
                end

                while not event:get(RMP.EventType.TransformDataGet):isEmpty() do
                    myevent:get(RMP.EventType.TransformDataGet):push(event:get(RMP.EventType.TransformDataGet):pop())
                end

                while not event:get(RMP.EventType.Sound):isEmpty() do
                    myevent:get(RMP.EventType.Sound):push(event:get(RMP.EventType.Sound):pop())
                end
            end
        end
    end

    function RMP.VirtualTerminal:mergeAll(thoseTerms)
        for i = 1, #thoseTerms do
            self:merge(thoseTerms[i].thatTerm, thoseTerms[i].offsetX, thoseTerms[i].offsetY)
        end
    end

    function RMP.VirtualTerminal:copy()
        local copy = RMP.VirtualTerminal.new()
        copy.native_vt_rmp = vt_rmp.copy(self.native_vt_rmp)
        return copy
    end
end

-- NOTE: Terminal class uses ansii escape code i need to create shared library to handle terminal for each platform
-- Terminal class used to handle terminal operations
RMP.Terminal = OOP.class("Terminal")
do -- Terminal
    function RMP.Terminal:clearWindow()
        io.write("\27[2J")
    end

    function RMP.Terminal:moveTo(x, y)
        if x < 1 then
            x = 1
        elseif y < 1 then
            y = 1
        end
        moveto(x, y)
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
        if x < 1 or x == nil then
            x = 1
        end
        io.write("\27[" .. x .. "D");
    end

    function RMP.Terminal:moveRight(x)
        if x < 1 or x == nil then
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
        local h, w = window.get_size()
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

-- Input class used to handle user input
RMP.Input = OOP.class("Input")
do
    function RMP.Input:constructor(label, x, y, width, defaultText, cancelKey)
        self.label = label or ""
        self.x = math.max(1, tonumber(x) or 1)
        self.y = math.max(1, tonumber(y) or 1)
        self.width = math.max(1, tonumber(width) or 10)
        self.text = tostring(defaultText or "")
        self.cursor_pos = #self.text + 1
        self.cancelKey = cancelKey or RMP.KEY_ESCAPE
        self.vterm = RMP.VirtualTerminal.new()
        self.active = false
        self.submitted = false
        self.scroll_offset = 0
        self.max_visible_chars = self.width - #self.label - 3
    end

    function RMP.Input:setCancelKey(key)
        self.cancelKey = key
    end

    function RMP.Input:adjustScroll()
        local visible_width = self.max_visible_chars
        if visible_width <= 0 then
            return
        end

        if self.cursor_pos - self.scroll_offset > visible_width then
            self.scroll_offset = self.cursor_pos - visible_width
        elseif self.cursor_pos <= self.scroll_offset then
            self.scroll_offset = math.max(0, self.cursor_pos - 1)
        end
    end

    function RMP.Input:keyToChar(key)
        local keyMap = {
            [RMP.KEY_A] = "a",
            [RMP.KEY_B] = "b",
            [RMP.KEY_C] = "c",
            [RMP.KEY_D] = "d",
            [RMP.KEY_E] = "e",
            [RMP.KEY_F] = "f",
            [RMP.KEY_G] = "g",
            [RMP.KEY_H] = "h",
            [RMP.KEY_I] = "i",
            [RMP.KEY_J] = "j",
            [RMP.KEY_K] = "k",
            [RMP.KEY_L] = "l",
            [RMP.KEY_M] = "m",
            [RMP.KEY_N] = "n",
            [RMP.KEY_O] = "o",
            [RMP.KEY_P] = "p",
            [RMP.KEY_Q] = "q",
            [RMP.KEY_R] = "r",
            [RMP.KEY_S] = "s",
            [RMP.KEY_T] = "t",
            [RMP.KEY_U] = "u",
            [RMP.KEY_V] = "v",
            [RMP.KEY_W] = "w",
            [RMP.KEY_X] = "x",
            [RMP.KEY_Y] = "y",
            [RMP.KEY_Z] = "z",
            [RMP.KEY_0] = "0",
            [RMP.KEY_1] = "1",
            [RMP.KEY_2] = "2",
            [RMP.KEY_3] = "3",
            [RMP.KEY_4] = "4",
            [RMP.KEY_5] = "5",
            [RMP.KEY_6] = "6",
            [RMP.KEY_7] = "7",
            [RMP.KEY_8] = "8",
            [RMP.KEY_9] = "9",
            [RMP.KEY_SPACE] = " ",
            [RMP.KEY_DOT] = ".",
            [RMP.KEY_MINUS] = "-",
            [RMP.KEY_UNDERS] = "_",
            [RMP.KEY_PLUS] = "+",
            [RMP.KEY_STAR] = "*",
            [RMP.KEY_SLASH] = "/",
            [RMP.KEY_BACK_SLASH] = "\\",
            [RMP.KEY_OPEN_BRAKET] = "[",
            [RMP.KEY_CLOSED_BRAKET] = "]",
            [RMP.KEY_OPCURB] = "{",
            [RMP.KEY_CLCURB] = "}",
            [RMP.KEY_BAR] = "|",
            [RMP.KEY_SEMICOL] = ";",
            [RMP.KEY_DBL_QUOTE] = "\"",
            [RMP.KEY_SINGLE_QOUTE] = "'",
            [RMP.KEY_BACKTICK] = "`",
            [RMP.KEY_HASHTAG] = "#",
            [RMP.KEY_DOLAR] = "$",
            [RMP.KEY_PERSANT] = "%",
            [RMP.KEY_AT] = "@",
            [RMP.KEY_GT] = ">",
            [RMP.KEY_LT] = "<",
            [RMP.KEY_QUISTION_MARK] = "?",
            [RMP.KEY_COLON] = ":",
            [RMP.KEY_COMMA] = ","
        }

        local shiftMap = {
            [RMP.KEY_SHIFT_A] = "A",
            [RMP.KEY_SHIFT_B] = "B",
            [RMP.KEY_SHIFT_C] = "C",
            [RMP.KEY_SHIFT_D] = "D",
            [RMP.KEY_SHIFT_E] = "E",
            [RMP.KEY_SHIFT_F] = "F",
            [RMP.KEY_SHIFT_G] = "G",
            [RMP.KEY_SHIFT_H] = "H",
            [RMP.KEY_SHIFT_I] = "I",
            [RMP.KEY_SHIFT_J] = "J",
            [RMP.KEY_SHIFT_K] = "K",
            [RMP.KEY_SHIFT_L] = "L",
            [RMP.KEY_SHIFT_M] = "M",
            [RMP.KEY_SHIFT_N] = "N",
            [RMP.KEY_SHIFT_O] = "O",
            [RMP.KEY_SHIFT_P] = "P",
            [RMP.KEY_SHIFT_Q] = "Q",
            [RMP.KEY_SHIFT_R] = "R",
            [RMP.KEY_SHIFT_S] = "S",
            [RMP.KEY_SHIFT_T] = "T",
            [RMP.KEY_SHIFT_U] = "U",
            [RMP.KEY_SHIFT_V] = "V",
            [RMP.KEY_SHIFT_W] = "W",
            [RMP.KEY_SHIFT_X] = "X",
            [RMP.KEY_SHIFT_Y] = "Y",
            [RMP.KEY_SHIFT_Z] = "Z"
        }

        return shiftMap[key] or keyMap[key]
    end

    function RMP.Input:handleKey(key)
        if key == RMP.KEY_ENTER then
            self.submitted = true
            self.active = false
        elseif key == self.cancelKey then
            self.text = ""
            self.cursor_pos = 1
            self.scroll_offset = 0
            self.active = false
        elseif key == RMP.KEY_BACKSPACE then
            if self.cursor_pos > 1 and #self.text > 0 then
                self.text = self.text:sub(1, self.cursor_pos - 2) .. self.text:sub(self.cursor_pos)
                self.cursor_pos = self.cursor_pos - 1
                self:adjustScroll()
            end
        elseif key == RMP.KEY_DELETE then
            if self.cursor_pos <= #self.text then
                self.text = self.text:sub(1, self.cursor_pos - 1) .. self.text:sub(self.cursor_pos + 1)
                self:adjustScroll()
            end
        elseif key == RMP.KEY_LEFT then
            if self.cursor_pos > 1 then
                self.cursor_pos = self.cursor_pos - 1
                self:adjustScroll()
            end
        elseif key == RMP.KEY_RIGHT then
            if self.cursor_pos <= #self.text then
                self.cursor_pos = self.cursor_pos + 1
                self:adjustScroll()
            end
        elseif key == RMP.KEY_HOME then
            self.cursor_pos = 1
            self.scroll_offset = 0
        elseif key == RMP.KEY_END then
            self.cursor_pos = #self.text + 1
            self:adjustScroll()
        else
            local char = self:keyToChar(key)
            if char and #self.text < self.max_visible_chars then
                self.text = self.text:sub(1, self.cursor_pos - 1) .. char .. self.text:sub(self.cursor_pos)
                self.cursor_pos = self.cursor_pos + 1
                self:adjustScroll()
            end
        end
    end

    function RMP.Input:render()
        self.vterm:clear()
        self.vterm:writeText(self.x, self.y, self.label, RMP.FGColors.Brights.White, RMP.BGColors.NoBrights.Blue)

        local visible_width = self.max_visible_chars
        local displayText = self.text
        if visible_width > 0 and #displayText > visible_width then
            displayText = displayText:sub(self.scroll_offset + 1, self.scroll_offset + visible_width)
        end
        displayText = displayText .. string.rep(" ", math.max(0, visible_width - #displayText))

        self.vterm:writeText(self.x + #self.label, self.y, displayText, RMP.FGColors.Brights.White,
            RMP.BGColors.NoBrights.Blue)
        if self.active then
            local cursor_screen_pos = self.cursor_pos - self.scroll_offset
            if cursor_screen_pos > 0 and cursor_screen_pos <= visible_width then
                self.vterm:writeText(
                    self.x + #self.label + cursor_screen_pos - 1, self.y,
                    "_",
                    RMP.FGColors.Brights.Yellow,
                    RMP.BGColors.NoBrights.Blue
                )
            end
        end
    end

    function RMP.Input:start()
        self.active = true
        self.submitted = false
        self:render()
    end

    function RMP.Input:stop()
        self.active = false
        self.submitted = false
        self:render()
    end

    function RMP.Input:processKey(key)
        if not self.active then
            return false
        end

        local should_handle = false

        if (key >= RMP.KEY_A and key <= RMP.KEY_Z) or
            (key >= RMP.KEY_SHIFT_A and key <= RMP.KEY_SHIFT_Z) or
            (key >= RMP.KEY_0 and key <= RMP.KEY_9) then
            should_handle = true
        end

        local specialKeys = {
            RMP.KEY_SPACE, RMP.KEY_DOT, RMP.KEY_MINUS, RMP.KEY_UNDERS,
            RMP.KEY_PLUS, RMP.KEY_STAR, RMP.KEY_SLASH, RMP.KEY_BACK_SLASH,
            RMP.KEY_OPEN_BRAKET, RMP.KEY_CLOSED_BRAKET, RMP.KEY_OPCURB,
            RMP.KEY_CLCURB, RMP.KEY_BAR, RMP.KEY_SEMICOL, RMP.KEY_DBL_QUOTE,
            RMP.KEY_SINGLE_QOUTE, RMP.KEY_BACKTICK, RMP.KEY_HASHTAG,
            RMP.KEY_DOLAR, RMP.KEY_PERSANT, RMP.KEY_AT, RMP.KEY_GT, RMP.KEY_LT,
            RMP.KEY_QUISTION_MARK, RMP.KEY_COLON, RMP.KEY_COMMA
        }

        for _, special_key in ipairs(specialKeys) do
            if key == special_key then
                should_handle = true
                break
            end
        end

        if key == RMP.KEY_BACKSPACE or key == RMP.KEY_DELETE or
            key == RMP.KEY_LEFT or key == RMP.KEY_RIGHT or
            key == RMP.KEY_HOME or key == RMP.KEY_END or
            key == RMP.KEY_ENTER or key == self.cancelKey then
            should_handle = true
        end

        if should_handle then
            self:handleKey(key)
            self:render()
            return true
        end

        return false
    end

    function RMP.Input:getVterm()
        return self.vterm
    end

    function RMP.Input:clearText()
        self.text = ""
        self.cursor_pos = 1
        self.scroll_offset = 0
        self:render()
    end

    function RMP.Input:getText()
        return self.text
    end

    function RMP.Input:setText(newText)
        self.text = newText or ""
        self.cursor_pos = #self.text + 1
        self.scroll_offset = 0
        self:adjustScroll()
        self:render()
    end

    function RMP.Input:setCursorPos(pos)
        pos = tonumber(pos) or 1
        self.cursor_pos = math.max(1, math.min(#self.text + 1, pos))
        self:adjustScroll()
        self:render()
    end

    function RMP.Input:getCursorPos()
        return self.cursor_pos
    end

    function RMP.Input:reset()
        self.active = false
        self.submitted = false
        self.text = ""
        self.cursor_pos = 1
        self.scroll_offset = 0
        self:render()
    end

    function RMP.Input:isActive()
        return self.active
    end

    function RMP.Input:wasSubmitted()
        return self.submitted
    end
end

-- Simple High-Level Input API for RMP Framework
-- simpleinput component - handles everything internally
-- usage:
-- local input = RMP.SimpleInput:new({x=1, y=1, width=20, label="Name: ", placeholder="Enter your name", maxLength=50})
-- input:render(vterm)
-- input:focus() -- to activate input
-- input:blur() -- to deactivate input
-- local value = input:getValue() -- to get the current value
-- input:setValue("New Value") -- to set a new value
-- input:clear() -- to clear the input
-- if input:isActive() then ... end -- to check if input is active
-- if input:hasError() then ... end -- to check if there is an error
-- local error_msg = input:getError() -- to get the error message
RMP.SimpleInput = OOP.class("SimpleInput")
do
    function RMP.SimpleInput:constructor(options)
        options = options or {}

        self.x = options.x or 1
        self.y = options.y or 1
        self.width = options.width or 20
        self.label = options.label or ""
        self.placeholder = options.placeholder or ""
        self.value = options.value or ""
        self.maxLength = options.maxLength or 100

        -- function(text) -> bool, error_msg
        self.validator = options.validator or nil

        self.cursor_pos = #self.value + 1
        self.active = false
        self.error_message = ""
        self.show_error = false

        self.fg_normal = options.fg_normal or RMP.FGColors.NoBrights.White
        self.bg_normal = options.bg_normal or RMP.BGColors.NoBrights.Black
        self.fg_active = options.fg_active or RMP.FGColors.Brights.Cyan
        self.bg_active = options.bg_active or RMP.BGColors.NoBrights.Blue
        self.fg_error = options.fg_error or RMP.FGColors.Brights.Red

        return self
    end

    function RMP.SimpleInput:render(vterm)
        if self.active then
            vterm:addEventListener(RMP.EventType.Focuse, function(key)
                self:_handleKey(key)
            end)
        end


        self:_renderField(vterm)

        return self
    end

    function RMP.SimpleInput:focus()
        self.active = true
        self.show_error = false
        return self
    end

    function RMP.SimpleInput:blur()
        self.active = false
        return self
    end

    function RMP.SimpleInput:getValue()
        return self.value
    end

    function RMP.SimpleInput:setValue(value)
        self.value = tostring(value or "")
        self.cursor_pos = #self.value + 1
        return self
    end

    function RMP.SimpleInput:clear()
        self.value = ""
        self.cursor_pos = 1
        self.show_error = false
        return self
    end

    function RMP.SimpleInput:isActive()
        return self.active
    end

    function RMP.SimpleInput:hasError()
        return self.show_error
    end

    function RMP.SimpleInput:getError()
        return self.error_message
    end

    function RMP.SimpleInput:_handleKey(key)
        if key == RMP.KEY_ENTER then
            self:_submit()
        elseif key == RMP.KEY_ESCAPE then
            self:blur()
        elseif key == RMP.KEY_BACKSPACE then
            self:_backspace()
        elseif key == RMP.KEY_DELETE then
            self:_delete()
        elseif key == RMP.KEY_LEFT then
            self:_moveCursorLeft()
        elseif key == RMP.KEY_RIGHT then
            self:_moveCursorRight()
        elseif key == RMP.KEY_HOME then
            self.cursor_pos = 1
        elseif key == RMP.KEY_END then
            self.cursor_pos = #self.value + 1
        else
            local char = self:_keyToChar(key)
            if char and #self.value < self.maxLength then
                self:_insertChar(char)
            end
        end
    end

    function RMP.SimpleInput:_submit()
        if self.validator then
            local valid, error_msg = self.validator(self.value)
            if not valid then
                self.error_message = error_msg or "Invalid input"
                self.show_error = true
                return false
            end
        end

        self.show_error = false
        self:blur()
        return true
    end

    function RMP.SimpleInput:_insertChar(char)
        self.value = self.value:sub(1, self.cursor_pos - 1) .. char .. self.value:sub(self.cursor_pos)
        self.cursor_pos = self.cursor_pos + 1
        self.show_error = false
    end

    function RMP.SimpleInput:_backspace()
        if self.cursor_pos > 1 then
            self.value = self.value:sub(1, self.cursor_pos - 2) .. self.value:sub(self.cursor_pos)
            self.cursor_pos = self.cursor_pos - 1
            self.show_error = false
        end
    end

    function RMP.SimpleInput:_delete()
        if self.cursor_pos <= #self.value then
            self.value = self.value:sub(1, self.cursor_pos - 1) .. self.value:sub(self.cursor_pos + 1)
            self.show_error = false
        end
    end

    function RMP.SimpleInput:_moveCursorLeft()
        if self.cursor_pos > 1 then
            self.cursor_pos = self.cursor_pos - 1
        end
    end

    function RMP.SimpleInput:_moveCursorRight()
        if self.cursor_pos <= #self.value then
            self.cursor_pos = self.cursor_pos + 1
        end
    end

    function RMP.SimpleInput:_keyToChar(key)
        local keyMap = {
            [RMP.KEY_A] = "a",
            [RMP.KEY_B] = "b",
            [RMP.KEY_C] = "c",
            [RMP.KEY_D] = "d",
            [RMP.KEY_E] = "e",
            [RMP.KEY_F] = "f",
            [RMP.KEY_G] = "g",
            [RMP.KEY_H] = "h",
            [RMP.KEY_I] = "i",
            [RMP.KEY_J] = "j",
            [RMP.KEY_K] = "k",
            [RMP.KEY_L] = "l",
            [RMP.KEY_M] = "m",
            [RMP.KEY_N] = "n",
            [RMP.KEY_O] = "o",
            [RMP.KEY_P] = "p",
            [RMP.KEY_Q] = "q",
            [RMP.KEY_R] = "r",
            [RMP.KEY_S] = "s",
            [RMP.KEY_T] = "t",
            [RMP.KEY_U] = "u",
            [RMP.KEY_V] = "v",
            [RMP.KEY_W] = "w",
            [RMP.KEY_X] = "x",
            [RMP.KEY_Y] = "y",
            [RMP.KEY_Z] = "z",
            [RMP.KEY_0] = "0",
            [RMP.KEY_1] = "1",
            [RMP.KEY_2] = "2",
            [RMP.KEY_3] = "3",
            [RMP.KEY_4] = "4",
            [RMP.KEY_5] = "5",
            [RMP.KEY_6] = "6",
            [RMP.KEY_7] = "7",
            [RMP.KEY_8] = "8",
            [RMP.KEY_9] = "9",
            [RMP.KEY_SPACE] = " ",
            [RMP.KEY_DOT] = ".",
            [RMP.KEY_MINUS] = "-"
        }

        local shiftMap = {
            [RMP.KEY_SHIFT_A] = "A",
            [RMP.KEY_SHIFT_B] = "B",
            [RMP.KEY_SHIFT_C] = "C",
            [RMP.KEY_SHIFT_D] = "D",
            [RMP.KEY_SHIFT_E] = "E",
            [RMP.KEY_SHIFT_F] = "F",
            [RMP.KEY_SHIFT_G] = "G",
            [RMP.KEY_SHIFT_H] = "H",
            [RMP.KEY_SHIFT_I] = "I",
            [RMP.KEY_SHIFT_J] = "J",
            [RMP.KEY_SHIFT_K] = "K",
            [RMP.KEY_SHIFT_L] = "L",
            [RMP.KEY_SHIFT_M] = "M",
            [RMP.KEY_SHIFT_N] = "N",
            [RMP.KEY_SHIFT_O] = "O",
            [RMP.KEY_SHIFT_P] = "P",
            [RMP.KEY_SHIFT_Q] = "Q",
            [RMP.KEY_SHIFT_R] = "R",
            [RMP.KEY_SHIFT_S] = "S",
            [RMP.KEY_SHIFT_T] = "T",
            [RMP.KEY_SHIFT_U] = "U",
            [RMP.KEY_SHIFT_V] = "V",
            [RMP.KEY_SHIFT_W] = "W",
            [RMP.KEY_SHIFT_X] = "X",
            [RMP.KEY_SHIFT_Y] = "Y",
            [RMP.KEY_SHIFT_Z] = "Z"
        }

        return shiftMap[key] or keyMap[key]
    end

    function RMP.SimpleInput:_renderField(vterm)
        if self.label ~= "" then
            vterm:writeText(self.x, self.y, self.label, self.fg_normal, self.bg_normal)
        end


        local fg = self.active and self.fg_active or self.fg_normal
        local bg = self.active and self.bg_active or self.bg_normal

        if self.show_error then
            fg = self.fg_error
        end


        local display_value = self.value
        if display_value == "" and not self.active and self.placeholder ~= "" then
            display_value = self.placeholder
            fg = RMP.FGColors.NoBrights.White
        end


        local field_content = display_value .. string.rep(" ", math.max(0, self.width - #display_value))
        local field_x = self.x + #self.label

        vterm:writeText(field_x, self.y, field_content, fg, bg)


        if self.active then
            local cursor_x = field_x + self.cursor_pos - 1
            vterm:writeText(cursor_x, self.y, "_", RMP.FGColors.Brights.Yellow, bg)
        end


        if self.show_error and self.error_message ~= "" then
            vterm:writeText(self.x, self.y + 1, self.error_message, self.fg_error, self.bg_normal)
        end
    end
end

function RMP.input(options)
    options = options or {}
    local message = options.message or "Enter value:"
    local default = options.default or ""
    local validator = options.validator

    -- This would be implemented as a blocking dialog
    -- For now, return a simple input component
    return RMP.SimpleInput.new({
        label = message,
        value = default,
        validator = validator,
        width = options.width or 30
    })
end

-- TODO: handle Tables
-- TODO: handle Animation  [loading bar , spinner , progress bar ]
RMP.Options = OOP.class("Options")
do
    function RMP.Options:constructor(options)
        self.options = options or {}
        self.color = RMP.Default
        self.symbl = ""
        self.pos = 1

        self.counter = false
        self.mark = false
        self.marked_table = {}
        self.selected = ""
        self.unselected = ""
        -- init marked table
        for i = 1, #self.options do
            self.marked_table[i] = false
        end
        return self
    end

    function RMP.Options:setCounter(value)
        self.counter = value
        return self
    end

    function RMP.Options:setMark(selected, unselected)
        self.selected = selected or ""
        self.unselected = unselected or ""
        self.mark = true
        -- ensure marked_table matches length
        self.marked_table = {}
        for i = 1, #self.options do
            self.marked_table[i] = false
        end
        return self
    end

    function RMP.Options:setColorFocus(color)
        self.color = color or RMP.Default
        return self
    end

    function RMP.Options:setSymblFocus(symbl)
        self.symbl = symbl or ""
        return self
    end

    function RMP.Options:setOptions(options)
        self.options = options or {}
        -- clamp pos
        if #self.options == 0 then
            self.pos = 1
        else
            if self.pos < 1 then self.pos = 1 end
            if self.pos > #self.options then self.pos = #self.options end
        end
        -- reset marks
        self.marked_table = {}
        for i = 1, #self.options do
            self.marked_table[i] = false
        end
        return self
    end

    function RMP.Options:getOptions()
        return self.options or {}
    end

    -- set visible focus position (absolute index in options array)
    function RMP.Options:focusPos(position)
        local p = tonumber(position) or 1
        if p < 1 then p = 1 end
        if p > #self.options and #self.options > 0 then p = #self.options end
        self.pos = p
        return self
    end

    function RMP.Options:next(block)
        block = block or false
        if #self.options == 0 then return self end
        if self.pos == #self.options then
            if block then
                self.pos = #self.options
            else
                self.pos = 1
            end
        else
            self.pos = self.pos + 1
        end
        return self
    end

    function RMP.Options:first()
        self.pos = 1
        return self
    end

    function RMP.Options:last()
        self.pos = math.max(1, #self.options)
        return self
    end

    function RMP.Options:prev(block)
        block = block or false
        if #self.options == 0 then return self end
        if self.pos == 1 then
            if block then
                self.pos = 1
            else
                self.pos = #self.options
            end
        else
            self.pos = self.pos - 1
        end
        return self
    end

    function RMP.Options:getSelected()
        if #self.options == 0 then return nil end
        self.marked_table[self.pos] = not self.marked_table[self.pos]
        -- i think i delete this helper function
        -- TODO: implement cleanTextLocal
        return cleanTextLocal(self.options[self.pos])
    end

    -- Returns a table of strings suitable for rendering.
    -- It DOES NOT modify self.options in-place.
    -- inside RMP.Options (replace existing parse)
    function RMP.Options:parse()
        local forRet = {}
        for i = 1, #self.options do
            local raw = tostring(self.options[i] or "")
            local marked = (self.marked_table and self.marked_table[i]) and true or false

            -- prefix (mark/unmark) shown before the item text (kept plain)
            local prefix = ""
            if self.mark then
                prefix = (marked and (self.selected or "") or (self.unselected or "")) .. " "
            end

            -- Set style/fg/bg only for focused item; other items keep nil so caller can use defaults
            local item = {
                text   = prefix .. raw,
                marked = marked,
                fg     = nil,
                bg     = nil,
                style  = nil
            }
            if i == self.pos then
                item.fg = self.color or nil
                item.style = self.symbl or nil
            end

            table.insert(forRet, item)
        end
        return forRet
    end
end

RMP.Draw = OOP.class("Draw")
do -- Draw
    function RMP.Draw:rectangle(x, y, width, height, color)
        x = x or 0
        x = math.floor(x)

        y = y or 0
        y = math.floor(y)

        if not width or not height then
            return
        end

        width = math.floor(width)
        height = math.floor(height)

        local vterm = RMP.VirtualTerminal.new()
        vterm:moveCursor(x, y)

        for i = y, height + y do
            for j = x, width + x do
                vterm:setChar(j, i, " ", nil, color, nil)
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
        local char = RMP.Text.new(" ", nil, nil):getColoredText()
        for y = 0, height - 1 do
            local spaces = height - y - 1
            local stars = 2 * y + 1

            vterm:setChar(pos_x + spaces, pos_y + y, string.rep(char, stars), nil, color, nil)
        end
        return vterm
    end

    function RMP.Draw:line(x, y, width, color)
        local vterm = RMP.VirtualTerminal.new()
        vterm:moveCursor(x, y)
        for i = x, width + x do
            vterm:setChar(i, y, " ", nil, color, nil)
        end

        return vterm
    end

    function RMP.Draw:column(x, y, height, color)
        local vterm = RMP.VirtualTerminal.new()
        for i = y, height + y do
            vterm:setChar(x, i, " ", nil, color, nil)
        end
        return vterm
    end
end

-- Position Layout
RMP.PopupPosition = {
    CENTER       = RMP.enum(true),
    TOP_LEFT     = RMP.enum(),
    TOP_RIGHT    = RMP.enum(),
    BUTTOM_LEFT  = RMP.enum(),
    BUTTOM_RIGHT = RMP.enum()
}

-- TODO: handle timeout async for popups
RMP.Popup = OOP.class("Popup")
do -- Popups
    function RMP.Popup:run(message, title, border_color, bg_color, poslayout)
        local rows, cols = RMP.Terminal:getSize()
        poslayout = poslayout or RMP.PopupPosition.CENTER
        local x, y = nil, nil
        if poslayout == RMP.PopupPosition.TOP_LEFT then
            x, y = 2, 2
        elseif poslayout == RMP.PopupPosition.TOP_RIGHT then
            x, y = cols - (cols / 4) - 2, 2
        elseif poslayout == RMP.PopupPosition.BUTTOM_LEFT then
            x, y = 2, rows - (rows / 4) - 2
        elseif poslayout == RMP.PopupPosition.BUTTOM_RIGHT then
            x, y = cols - (cols / 4) - 2, rows - (rows / 4) - 2
        else
            x, y = (cols / 2) - (cols / 8), (rows / 2) - (rows / 8)
        end

        return RMP.Window.new(99):createWindow(
            title,
            -- 		cols / 2 ,
            -- 		rows / 2 ,
            cols / 4,
            rows / 4,
            x,
            y,
            border_color,
            bg_color,
            RMP.BoxDrawing.LightBorder,
            function(lx, ly, xx, yy)
                -- TODO: fix message inside box
                local vterm = RMP.VirtualTerminal.new()
                vterm:moveCursor(lx + 1, ly + 1)
                -- i think i delete this helper function
                -- TODO: implement cleanTextLocal
                local text = remove_new_lines_from_str(message)

                local spl = 1
                local remider = 0
                if #text > (xx - lx - 1) then
                    if spl == math.floor((xx - lx - 1) / #text) then
                        spl = math.floor(#text / (xx - lx - 1)) + 1
                    else
                        spl = math.floor(#text / (xx - lx - 1))
                    end
                    remider = #text % (xx - lx)
                end

                for i = 0, math.min(spl, yy - ly - 4) do
                    vterm:writeText(lx + 1, ly + 1 + i,
                        string.sub(text, (xx - lx - 1) * i + 1, (xx - lx - 1) * (i + 1) - 1),
                        nil, nil, nil)
                end
                return vterm
            end)
    end
end

RMP.Notify = OOP.class("Notify", RMP.Popup)
do
    function RMP.Notify:constructor(
        time,   -- the time will live on the Frame , should be ms
        fps,    -- the fps time
        message -- the message
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
        self.counter = RMP.enum(true)
    end

    function RMP.Notify:error(poslayout)
        poslayout = poslayout or RMP.PopupPosition.CENTER

        if self.counter < math.floor(self.fps * self.time / (self.fps / 10)) then
            self.counter = RMP.enum()
            return self:super(
                "run",
                self.message,
                RMP.Text.new(
                    "[ " .. "ERROR" .. " ]",
                    RMP.TextStyle.Bold,
                    RMP.FGColors.NoBrights.White,
                    RMP.BGColors.NoBrights.BGRed
                ),
                RMP.FGColors.NoBrights.Red,
                nil,
                poslayout
            )
        end
    end

    function RMP.Notify:info(poslayout)
        poslayout = poslayout or RMP.PopupPosition.CENTER

        if self.counter < self.time then
            self.counter = self.counter + self.delta
            return self:super(
                "run",
                self.message,
                RMP.Text.new(
                    "[ " .. "INFO" .. " ]",
                    RMP.TextStyle.Bold,
                    RMP.FGColors.NoBrights.White,
                    RMP.BGColors.NoBrights.Green
                ),
                RMP.FGColors.NoBrights.Green,
                nil,
                poslayout
            )
        end
    end

    function RMP.Notify:message(poslayout)
        poslayout = poslayout or RMP.PopupPosition.CENTER

        if self.counter < self.time then
            self.counter = self.counter + self.delta
            return self:super(
                "run",
                self.message,
                RMP.Text.new(
                    "[ " .. "Message" .. " ]",
                    RMP.TextStyle.Bold,
                    RMP.FGColors.NoBrights.White,
                    RMP.BGColors.NoBrights.Blue
                ),
                RMP.FGColors.NoBrights.Blue,
                nil,
                poslayout
            )
        end
    end

    function RMP.Notify:warning(poslayout)
        poslayout = poslayout or RMP.PopupPosition.CENTER

        if self.counter < self.time then
            self.counter = self.counter + self.delta
            return self:super(
                "run",
                self.message,
                RMP.Text.new(
                    "[ " .. "Warning" .. " ]",
                    RMP.TextStyle.Bold,
                    RMP.FGColors.NoBrights.White,
                    RMP.BGColors.NoBrights.Yellow
                ),
                RMP.FGColors.NoBrights.Yellow,
                nil,
                poslayout

            )
        end
    end
end

RMP.Scroller = OOP.class("Scroller")
do
    function RMP.Scroller:constructor(visible_height, options_obj)
        self.visible_height = math.max(1, tonumber(visible_height) or 10)
        self.options = options_obj or RMP.Options.new({})
        self.scroll_offset = 0


        local data = self.options:getOptions() or {}
        if #data > 0 then
            if not self.options.pos or self.options.pos < 1 then
                self.options.pos = 1
            elseif self.options.pos > #data then
                self.options.pos = #data
            end
        else
            self.options.pos = 1
        end

        self:_adjustScrollOffset()
        return self
    end

    function RMP.Scroller:setOptionsObj(options_obj)
        self.options = options_obj or RMP.Options.new({})
        local data = self.options:getOptions() or {}

        if #data > 0 then
            if not self.options.pos or self.options.pos < 1 then
                self.options.pos = 1
            elseif self.options.pos > #data then
                self.options.pos = #data
            end
        else
            self.options.pos = 1
        end

        self:_adjustScrollOffset()
        return self
    end

    function RMP.Scroller:setHeight(visible_height)
        self.visible_height = math.max(1, tonumber(visible_height) or 10)
        self:_adjustScrollOffset()
        return self
    end

    function RMP.Scroller:_adjustScrollOffset()
        local data = self.options:getOptions() or {}
        local total_items = #data

        if total_items == 0 then
            self.scroll_offset = 0
            return
        end

        if self.options.pos < 1 then
            self.options.pos = 1
        elseif self.options.pos > total_items then
            self.options.pos = total_items
        end


        local cursor_pos = self.options.pos


        if cursor_pos <= self.scroll_offset then
            self.scroll_offset = math.max(0, cursor_pos - 1)
        end


        if cursor_pos > self.scroll_offset + self.visible_height then
            self.scroll_offset = cursor_pos - self.visible_height
        end


        local max_scroll = math.max(0, total_items - self.visible_height)
        self.scroll_offset = math.min(self.scroll_offset, max_scroll)
    end

    function RMP.Scroller:getVisible()
        local parsed_data = self.options:parse() or {}
        local total_items = #parsed_data

        if total_items == 0 then
            return {}, 0, 0
        end


        self:_adjustScrollOffset()


        local start_index = self.scroll_offset + 1
        local end_index = math.min(self.scroll_offset + self.visible_height, total_items)


        local visible_items = {}
        for i = start_index, end_index do
            local item = parsed_data[i]
            if item then
                item.absolute_index = i
                table.insert(visible_items, item)
            end
        end


        local focus_index = self.options.pos - self.scroll_offset

        return visible_items, start_index, focus_index
    end

    function RMP.Scroller:nextLine()
        local data = self.options:getOptions() or {}
        local total_items = #data

        if total_items == 0 then return self end

        if self.options.pos < total_items then
            self.options.pos = self.options.pos + 1
            self:_adjustScrollOffset()
        end

        return self
    end

    function RMP.Scroller:prevLine()
        local data = self.options:getOptions() or {}

        if #data == 0 then return self end

        if self.options.pos > 1 then
            self.options.pos = self.options.pos - 1
            self:_adjustScrollOffset()
        end

        return self
    end

    function RMP.Scroller:nextContent()
        local data = self.options:getOptions() or {}
        local total_items = #data

        if total_items == 0 then return self end

        local target_pos = math.min(total_items, self.options.pos + self.visible_height)
        self.options:focusPos(target_pos)
        self:_adjustScrollOffset()

        return self
    end

    function RMP.Scroller:prevContent()
        local data = self.options:getOptions() or {}

        if #data == 0 then return self end

        local target_pos = math.max(1, self.options.pos - self.visible_height)
        self.options:focusPos(target_pos)
        self:_adjustScrollOffset()

        return self
    end

    function RMP.Scroller:toStart()
        local data = self.options:getOptions() or {}

        if #data > 0 then
            self.options:first()
            self:_adjustScrollOffset()
        end

        return self
    end

    function RMP.Scroller:toEnd()
        local data = self.options:getOptions() or {}

        if #data > 0 then
            self.options:last()
            self:_adjustScrollOffset()
        end

        return self
    end

    function RMP.Scroller:resetToStart()
        self.scroll_offset = 0
        self.options:first()
        self:_adjustScrollOffset()
        return self
    end

    function RMP.Scroller:getCursorPosition()
        return self.options.pos
    end

    function RMP.Scroller:getScrollOffset()
        return self.scroll_offset
    end

    function RMP.Scroller:getTotalItems()
        local data = self.options:getOptions() or {}
        return #data
    end

    function RMP.Scroller:canScrollUp()
        return self.scroll_offset > 0
    end

    function RMP.Scroller:canScrollDown()
        local data = self.options:getOptions() or {}
        return self.scroll_offset + self.visible_height < #data
    end

    function RMP.Scroller:getScrollProgress()
        local data = self.options:getOptions() or {}
        local total_items = #data

        if total_items <= self.visible_height then
            return 1.0
        end

        local max_scroll = total_items - self.visible_height
        return self.scroll_offset / max_scroll
    end
end

RMP.PlaybackMode = {
    ONCE          = RMP.enum(true),
    LOOP_SINGLE   = RMP.enum(),
    LOOP_PLAYLIST = RMP.enum(),
    SHUFFLE       = RMP.enum()
}

RMP.State = {
    STOPPED = RMP.enum(true),
    PLAYING = RMP.enum(),
    PAUSED  = RMP.enum(),
    LOADING = RMP.enum(),
    ERROR   = RMP.enum()
}

RMP.Sound = OOP.class("Sound")
do
    function RMP.Sound:constructor(files)
        self.playlist               = {}
        self.current_index          = 1
        self.playback_mode          = RMP.PlaybackMode.ONCE

        self.state                  = RMP.State.STOPPED
        self.volume                 = 0.75
        self.speed                  = 1.0
        self.is_initialized         = false
        self.last_error             = nil

        self.visualization_enabled  = false
        self.visualization_callback = nil
        self.freq_bins              = 64
        self.freq_data              = {}
        self.metadata_cache         = {}

        -- init audio system (Init returns boolean, maybe error; handle both)
        local ok, a, b              = pcall(rmpaudio.Init)
        if not ok then
            self.last_error = "rmpaudio initialization error: " .. tostring(a)
            self.state = RMP.State.ERROR
            return self
        end
        if a == false then
            self.last_error = "rmpaudio initialization failed: " .. tostring(b or "unknown")
            self.state = RMP.State.ERROR
            return self
        end

        self.is_initialized = true

        if files then
            self:setPlaylist(files)
        end

        -- seed random for shuffle
        math.randomseed(os.time() % 2 ^ 31)

        return self
    end

    function RMP.Sound:getState()
        return self.state
    end

    --------------------------------------------------------------------
    -- Playlist management
    --------------------------------------------------------------------
    function RMP.Sound:setPlaylist(files)
        self.playlist, self.metadata_cache = {}, {}
        if type(files) == "string" then
            table.insert(self.playlist, files)
        elseif type(files) == "table" then
            for _, f in ipairs(files) do
                if type(f) == "string" then table.insert(self.playlist, f) end
            end
        end
        if #self.playlist > 0 then
            self.current_index = 1
            local ok, err = self:_loadCurrentTrack()
            if not ok then
                self.last_error = err
                self.state = RMP.State.ERROR
            end
        end
        return self
    end

    function RMP.Sound:getLastError()
        if self.state == RMP.State.ERROR and self.last_error ~= nil then
            return self.last_error
        end
        return nil
    end

    function RMP.Sound:addTrack(file)
        if type(file) == "string" then table.insert(self.playlist, file) end
        return self
    end

    function RMP.Sound:removeTrack(index)
        if index > 0 and index <= #self.playlist then
            table.remove(self.playlist, index)
            if self.current_index > index then
                self.current_index = self.current_index - 1
            elseif self.current_index == index then
                if self.current_index > #self.playlist then
                    self.current_index = #self.playlist
                end
                if #self.playlist > 0 then
                    local ok, err = self:_loadCurrentTrack()
                    if not ok then self.last_error = err end
                end
            end
        end
        return self
    end

    function RMP.Sound:getPlaylist() return self.playlist end

    function RMP.Sound:getCurrentIndex() return self.current_index end

    function RMP.Sound:getCurrentTrack()
        if self.current_index > 0 and self.current_index <= #self.playlist then
            return self.playlist[self.current_index]
        end
        return nil
    end

    function RMP.Sound:setPlayBackMode(mode)
        self.playback_mode = mode
    end

    function RMP.Sound:getPlayBackMode()
        return self.playback_mode
    end

    --------------------------------------------------------------------
    -- Internal loader
    --------------------------------------------------------------------
    function RMP.Sound:_loadCurrentTrack()
        if not self.is_initialized then return false, "Audio not initialized" end
        local track = self:getCurrentTrack()
        if not track then return false, "No track to load" end

        -- rmpaudio.load returns (true) or (false, err)
        local pcall_ok, first, second = pcall(rmpaudio.Load, track)
        if not pcall_ok then
            return false, "Load pcall failed: " .. tostring(first)
        end
        if first == false then
            return false, tostring(second or "load failed")
        end

        pcall(rmpaudio.SetVolume, self.volume)
        pcall(rmpaudio.SetSpeed, self.speed)

        if self.playback_mode == RMP.PlaybackMode.LOOP_SINGLE then
            pcall(rmpaudio.SetLoop, true)
        else
            pcall(rmpaudio.SetLoop, false)
        end

        local ok_meta, meta = pcall(rmpaudio.GetMetadata)
        if ok_meta and type(meta) == "table" then
            self.metadata_cache[self.current_index] = meta
        end

        self.state = RMP.State.STOPPED
        return true
    end

    --------------------------------------------------------------------
    -- Playback control (each handles both pcall errors and boolean+error returns)
    --------------------------------------------------------------------
    function RMP.Sound:play()
        if not self.is_initialized then
            self.last_error = "Audio not initialized"
            return false, self.last_error
        end
        if #self.playlist == 0 then
            self.last_error = "No tracks in playlist"
            return false, self.last_error
        end

        local pcall_ok, returned, err = pcall(rmpaudio.Play)
        if not pcall_ok then
            self.last_error = "Play pcall error: " .. tostring(returned)
            self.state = RMP.State.ERROR
            return false, self.last_error
        end
        if returned == false then
            self.last_error = tostring(err or "play failed")
            self.state = RMP.State.ERROR
            return false, self.last_error
        end

        self.state = RMP.State.PLAYING
        return true
    end

    function RMP.Sound:pause()
        if not self.is_initialized then return false, "Audio not initialized" end
        local ok, ret = pcall(rmpaudio.Pause)
        if not ok then
            self.last_error = "Pause pcall error: " .. tostring(ret)
            return false, self.last_error
        end
        if ret == false then
            self.last_error = "Pause failed"
            return false, self.last_error
        end
        self.state = RMP.State.PAUSED
        return true
    end

    function RMP.Sound:resume()
        if not self.is_initialized then return false, "Audio not initialized" end
        local ok, ret = pcall(rmpaudio.Resume)
        if not ok then
            self.last_error = "Resume pcall error: " .. tostring(ret)
            return false, self.last_error
        end
        if ret == false then
            self.last_error = "Resume failed"
            return false, self.last_error
        end
        self.state = RMP.State.PLAYING
        return true
    end

    function RMP.Sound:stop()
        if not self.is_initialized then return false, "Audio not initialized" end
        local ok, ret = pcall(rmpaudio.Stop)
        if not ok then
            self.last_error = "Stop pcall error: " .. tostring(ret)
            return false, self.last_error
        end
        if ret == false then
            self.last_error = "Stop failed"
            return false, self.last_error
        end
        self.state = RMP.State.STOPPED
        return true
    end

    function RMP.Sound:seek(seconds)
        if not self.is_initialized then
            return false, "Audio not initialized"
        end

        local sec = tonumber(seconds) or 0
        if sec < 0 then sec = 0 end

        local duration = self:getLength()
        if sec > duration then
            sec = duration
        end

        local ok, ret, err = pcall(rmpaudio.Seek, sec)
        if not ok then
            self.last_error = "Seek pcall error: " .. tostring(ret)
            return false, self.last_error
        end
        if ret == false then
            self.last_error = tostring(err or "Seek failed")
            return false, self.last_error
        end

        return true
    end

    --------------------------------------------------------------------
    -- Volume / speed
    --------------------------------------------------------------------
    function RMP.Sound:setVolume(v)
        v = math.max(0, math.min(1, tonumber(v) or 0))
        local ok, ret = pcall(rmpaudio.SetVolume, v)
        if not ok or ret == false then
            self.last_error = "SetVolume failed: " .. tostring(ret)
            return false, self.last_error
        end
        self.volume = v
        return true
    end

    function RMP.Sound:getVolume()
        local ok, vol = pcall(rmpaudio.GetVolume)
        if not ok then
            return self.volume
        end
        return vol or self.volume
    end

    function RMP.Sound:getSpeed()
        return self.speed
    end

    function RMP.Sound:setSpeed(s)
        s = tonumber(s) or 1.0
        local ok, ret = pcall(rmpaudio.SetSpeed, s)
        if not ok or ret == false then
            self.last_error = "SetSpeed failed: " .. tostring(ret)
            return false, self.last_error
        end
        self.speed = s
        return true
    end

    --------------------------------------------------------------------
    -- Position / length (now properly in seconds)
    --------------------------------------------------------------------
    function RMP.Sound:getPosition()
        local ok, pos = pcall(rmpaudio.GetPosition)
        if not ok then
            self.last_error = "GetPosition pcall error: " .. tostring(pos)
            return 0
        end
        return tonumber(pos) or 0
    end

    function RMP.Sound:getLength()
        local ok, len = pcall(rmpaudio.GetDuration)
        if not ok then
            self.last_error = "GetDuration pcall error: " .. tostring(len)
            return 0
        end
        return tonumber(len) or 0
    end

    --------------------------------------------------------------------
    -- Loop flag (file-level loop)
    --------------------------------------------------------------------
    function RMP.Sound:setLoop(flag)
        local ok, ret = pcall(rmpaudio.SetLoop, flag and true or false)
        if not ok or ret == false then
            self.last_error = "SetLoop failed"
            return false, self.last_error
        end
        return true
    end

    function RMP.Sound:getLoop()
        local ok, ret = pcall(rmpaudio.GetLoop)
        if not ok then return false end
        return not not ret
    end

    --------------------------------------------------------------------
    -- FIXME: Visualization functions didn't works
    --------------------------------------------------------------------
    function RMP.Sound:setVisualizationCallback(fn)
        if type(fn) ~= "function" then
            return false, "callback must be function"
        end
        local ok, a, b = pcall(rmpaudio.SetVisualizationCallback, fn)
        if not ok then
            self.last_error = "SetVisualizationCallback pcall error: " .. tostring(a)
            return false, self.last_error
        end
        if a == false then
            self.last_error = tostring(b or "SetVisualizationCallback failed")
            return false, self.last_error
        end
        self.visualization_callback = fn
        return true
    end

    function RMP.Sound:enableVisualization(bins)
        bins = tonumber(bins) or self.freq_bins
        local ok, a, b = pcall(rmpaudio.EnableVisualization, bins)
        if not ok then
            self.last_error = "EnableVisualization pcall error: " .. tostring(a)
            return false, self.last_error
        end
        if a == false then
            self.last_error = tostring(b or "EnableVisualization failed")
            return false, self.last_error
        end
        self.visualization_enabled = true
        self.freq_bins = bins
        return true
    end

    function RMP.Sound:disableVisualization()
        local ok, a = pcall(rmpaudio.DisableVisualization)
        if not ok or a == false then
            self.last_error = "DisableVisualization failed"
            return false, self.last_error
        end
        self.visualization_enabled = false
        self.visualization_callback = nil
        return true
    end

    function RMP.Sound:getFrequencyData()
        local ok, data = pcall(rmpaudio.GetFrequencyData)
        if not ok then
            return nil
        end
        return data
    end

    --------------------------------------------------------------------
    -- Info / helper
    --------------------------------------------------------------------
    function RMP.Sound:isPlaying()
        local ok, v = pcall(rmpaudio.IsPlaying)
        if not ok then return false end
        return not not v
    end

    function RMP.Sound:isFinished()
        local ok, v = pcall(rmpaudio.IsFinished)
        if not ok then return false end
        return not not v
    end

    function RMP.Sound:getMetadata()
        local ok, meta = pcall(rmpaudio.GetMetadata)
        if not ok then return nil end
        return meta
    end

    --------------------------------------------------------------------
    -- Track navigation: prev/next, plus an 'update' to auto-advance
    --------------------------------------------------------------------
    function RMP.Sound:nextTrack()
        if #self.playlist == 0 then return false, "empty playlist" end
        if self.playback_mode == RMP.PlaybackMode.SHUFFLE and #self.playlist > 1 then
            local nextidx = math.random(1, #self.playlist)
            while nextidx == self.current_index do nextidx = math.random(1, #self.playlist) end
            self.current_index = nextidx
        else
            self.current_index = self.current_index + 1
            if self.current_index > #self.playlist then
                self.current_index = 1
            end
        end
        local ok, err = self:_loadCurrentTrack()
        if not ok then return false, err end
        return self:play()
    end

    function RMP.Sound:prevTrack()
        if #self.playlist == 0 then return false, "empty playlist" end
        self.current_index = self.current_index - 1
        if self.current_index < 1 then self.current_index = #self.playlist end
        local ok, err = self:_loadCurrentTrack()
        if not ok then return false, err end
        return self:play()
    end

    -- event loop required
    function RMP.Sound:update()
        if not self.is_initialized then return end

        if self.visualization_enabled and type(self.visualization_callback) == "function" then
            local freq = self:getFrequencyData()
            if type(freq) == "table" then
                pcall(self.visualization_callback, freq)
            end
        end

        local finished = self:isFinished()
        if finished then
            if self.playback_mode == RMP.PlaybackMode.LOOP_SINGLE then
                self:seek(0)
                self:play()
            elseif self.playback_mode == RMP.PlaybackMode.LOOP_PLAYLIST then
                self.current_index = self.current_index + 1
                if self.current_index > #self.playlist then self.current_index = 1 end
                local ok, err = self:_loadCurrentTrack()
                if not ok then
                    self.last_error = err
                    self.state = RMP.State.ERROR
                    return
                end
                self:play()
            elseif self.playback_mode == RMP.PlaybackMode.SHUFFLE then
                if #self.playlist > 1 then
                    local nextidx = math.random(1, #self.playlist)
                    while nextidx == self.current_index do nextidx = math.random(1, #self.playlist) end
                    self.current_index = nextidx
                end
                local ok, err = self:_loadCurrentTrack()
                if not ok then
                    self.last_error = err
                    self.state = RMP.State.ERROR
                    return
                end
                self:play()
            else
                self.state = RMP.State.STOPPED
            end
        end
    end

    function RMP.Sound:getProgress()
        local pos = self:getPosition()
        local dur = self:getLength()
        if dur > 0 then
            return pos / dur
        end
        return 0
    end

    function RMP.Sound:getTimeRemaining()
        return self:getLength() - self:getPosition()
    end

    function RMP.Sound:formatTime(seconds)
        seconds = math.floor(seconds or 0)
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format("%02d:%02d", mins, secs)
    end

    function RMP.Sound:getFormattedPosition()
        return self:formatTime(self:getPosition())
    end

    function RMP.Sound:getFormattedDuration()
        return self:formatTime(self:getLength())
    end

    function RMP.Sound:getFormattedTimeRemaining()
        return self:formatTime(self:getTimeRemaining())
    end

    function RMP.Sound:cleanup()
        if self.visualization_enabled then
            self:disableVisualization()
        end
        local ok, ret = pcall(rmpaudio.Cleanup)
        self.is_initialized = false
        return ok and ret
    end
end

RMP.Path = OOP.class("Path")
do -- Path
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
        return directory.list_dir(self.path) -- may return nil
    end

    function RMP.Path:makeDir(dir_name)
        local full_dir = nil
        if string.sub(self.path, -1) == "/" then
            full_dir = self.path .. dir_name
        else
            full_dir = self.path .. "/" .. dir_name
        end
        return directory.mkdir(full_dir,
            nil -- mode default 0o755
        )
    end

    function RMP.Path:removeDir(dir_name)
        local full_dir = nil
        if string.sub(self.path, -1) == "/" then
            full_dir = self.path .. dir_name
        else
            full_dir = self.path .. "/" .. dir_name
        end
        return directory.rmdir(full_dir)
    end

    function RMP.Path:find(pattern, is_find_file) -- boolean
        -- if file or dir is founded it returns true so you can access it directly
        local lst = self:listDir()
        if not lst then
            return false
        end

        for _, info in ipairs(lst) do
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

        search_recursive = function(current_path, current_depth)
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

-- Updated RMP.Config class with cross-platform support
RMP.Config = OOP.class("Config")
do -- Config
    -- Cross-platform path separator detection
    local function getPathSeparator()
        local os_type = RMP.getOs()
        if os_type == RMP.PlatformType.WINDOWS then
            return "\\"
        else
            return "/"
        end
    end

    -- Cross-platform path joining that works with your C directory module
    local function joinPath(...)
        local parts = { ... }
        local sep = getPathSeparator()
        local result = parts[1] or ""

        for i = 2, #parts do
            if parts[i] and parts[i] ~= "" then
                local part = tostring(parts[i])
                -- Remove leading separator from part if present
                if part:sub(1, 1) == "/" or part:sub(1, 1) == "\\" then
                    part = part:sub(2)
                end
                -- Ensure separator between parts
                if result:sub(-1) == "/" or result:sub(-1) == "\\" then
                    result = result .. part
                else
                    result = result .. sep .. part
                end
            end
        end

        return result
    end

    -- Get cross-platform config directory name
    local function getConfigDirName()
        local os_type = RMP.getOs()
        if os_type == RMP.PlatformType.WINDOWS then
            return ".rmp" -- or could use "RMP" for Windows
        else
            return ".rmp"
        end
    end

    function RMP.Config:constructor(confPath)
        self.cfgObj = nil
        self.isValidFile = false
        self.isError = nil
        self.os_type = RMP.getOs()
        self.path_sep = getPathSeparator()

        self.currentPath = RMP.Path.new()
        self.homePath = RMP.Path.new(self.currentPath:getHomePath())

        -- Cross-platform config directory
        local configDirName = getConfigDirName()

        if not self.homePath:find(configDirName, false) then
            self.isError = configDirName .. " directory not found in home dir"
            return
        end

        -- Use cross-platform path joining
        local configPath = joinPath(self.homePath:getPath(), configDirName)
        self.configurationPath = RMP.Path.new(configPath)

        if not self.configurationPath:find("init.lua", true) then
            self.isError = "init.lua not found in " .. configDirName .. " dir"
            return
        end

        -- Cross-platform path for init.lua
        local initPath = joinPath(configPath, "init.lua")
        self.initPath = RMP.Path.new(initPath)
        self.isValidFile = true

        return self
    end

    function RMP.Config:load() -- (boolean , Error)
        if not self.isValidFile then
            return false, self.isError
        end

        if not self.cfgObj then
            local ok, res = pcall(function()
                return dofile(self.initPath:getPath())
            end)

            if not ok then
                self.isError = "failed to load init.lua configuration file: " .. tostring(res)
                return false, self.isError
            end

            if type(res) ~= "table" then
                self.isError = "init.lua file must return a table, check documentation"
                return false, self.isError
            end
            self.cfgObj = res
        end
        return true, nil
    end

    -- Cross-platform theme path resolution
    function RMP.Config:getThemePath(themeName)
        if not themeName or type(themeName) ~= "string" then
            return nil
        end

        local configPath = self.configurationPath:getPath()
        return joinPath(configPath, "themes", themeName .. ".lua")
    end

    -- Cross-platform plugin path resolution
    function RMP.Config:getPluginPath(pluginName)
        if not pluginName or type(pluginName) ~= "string" then
            return nil
        end

        local configPath = self.configurationPath:getPath()
        -- Try single file first
        local singleFile = joinPath(configPath, "plugins", pluginName .. ".lua")
        -- Try folder with init.lua
        local folderInit = joinPath(configPath, "plugins", pluginName, "init.lua")

        return singleFile, folderInit
    end

    -- Helper method to get installation paths
    function RMP.Config:getInstallationPaths()
        local paths = {}

        if self.os_type == RMP.PlatformType.WINDOWS then
            -- Windows installation paths
            table.insert(paths, joinPath("C:", "Program Files", "RMP"))
            table.insert(paths, joinPath("C:", "Program Files (x86)", "RMP"))
            -- User local installation
            local appdata = os.getenv("APPDATA")
            if appdata then
                table.insert(paths, joinPath(appdata, "RMP"))
            end
        elseif self.os_type == RMP.PlatformType.LINUX then
            -- Linux installation paths
            table.insert(paths, "/usr/local/share/rmp")
            table.insert(paths, "/usr/share/rmp")
            table.insert(paths, joinPath(self.homePath:getPath(), ".local", "share", "rmp"))
        elseif self.os_type == RMP.PlatformType.MAC then
            -- macOS installation paths
            table.insert(paths, "/usr/local/share/rmp")
            table.insert(paths, "/Applications/RMP.app/Contents/Resources")
            table.insert(paths, joinPath(self.homePath:getPath(), "Library", "Application Support", "RMP"))
        end

        return paths
    end

    function RMP.Config:isValidConfig()
        return self.isValidFile
    end

    function RMP.Config:getInitFileAsObject()
        if self.cfgObj and type(self.cfgObj) == "table" then
            return self.cfgObj
        end
        return nil
    end

    function RMP.Config:getThemesAsObject()
        if self.cfgObj and self.cfgObj.template and type(self.cfgObj.template) == "string" then
            return self.cfgObj.template
        end
        return nil
    end

    function RMP.Config:getSoundKeyMaps()
        if self.cfgObj and self.cfgObj.soundMap and type(self.cfgObj.soundMap) == "table" then
            return self.cfgObj.soundMap
        end
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

        id = id or 0

        for _, obj in ipairs(self.cfgObj.plugins) do
            if obj.themeWindowId and obj.isActivated and obj.name then
                if id == obj.themeWindowId then
                    local singleFile, folderInit = self:getPluginPath(obj.name)

                    local ok, res = pcall(function()
                        -- Try single file first
                        local file = io.open(singleFile, "r")
                        if file then
                            file:close()
                            return dofile(singleFile)
                        end

                        -- Try folder with init.lua
                        file = io.open(folderInit, "r")
                        if file then
                            file:close()
                            return dofile(folderInit)
                        end

                        return nil
                    end)

                    if ok and res then
                        return res, nil
                    else
                        return nil, "Warning: Failed to load plugin '" .. obj.name .. "': " .. tostring(res)
                    end
                end
            end
        end

        return nil
    end

    function RMP.Config:getLoadError()
        return self.isError
    end

    -- Helper method for cross-platform path operations
    function RMP.Config:joinPath(...)
        return joinPath(...)
    end

    function RMP.Config:getPathSeparator()
        return self.path_sep
    end
end

-- /////////////////////////////////////////////////////
-- Hight Level API
-- /////////////////////////////////////////////////////

RMP.Frame = OOP.class("Frame", RMP.VirtualTerminal)
do
    function RMP.Frame:constructor(width, heigth)
        self:super("constructor", width, heigth)
        self.fps = 30
    end

    function RMP.Frame:setFps(fps)
        self.fps = fps
    end

    function RMP.Frame:getFps()
        return self.fps
    end

    function RMP.Frame:getDeltaTime()
        return 1 / self.fps -- second
    end

    function RMP.Frame:positionedFrame(x, y)
        x = x or 1
        y = y or 1
        self:super("moveCursor", x, y)
    end

    function RMP.Frame:add(component)
        self:super("merge", component)
    end

    function RMP.Frame:addEventListener(key, callback)
        self:super("addEventListener", key, callback)
    end

    function RMP.Frame:run(key, mouse, sound)
        self:super("handleEvent", key, mouse, sound)
        self:super("render")
        self:super("clear")
        RMP.sleep(math.floor(RMP.Duration.new(self:getDeltaTime()):fromSec()))
    end
end

-- TODO: add class Code to manage code highlighting for the text

return RMP

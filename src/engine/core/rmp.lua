-- Copyright (c) 2024-2026 Ray Den
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

---
-- # RMP Framework Documentation
--
-- This Lua module (rmp.lua) provides a comprehensive terminal-based UI framework
-- with audio playback capabilities.
-- It's designed to create rich terminal applications with features like:
--
-- ## Framework Overview
--
-- **RMP api v1.0.0**
--
-- **Note:** This API works with Lua version 5.4
--
-- ## Core Feature Categories
--
-- | Category              | Subcategory           | Feature    | Description                                                            |
-- |-----------------------|-----------------------|------------|------------------------------------------------------------------------|
-- | Terminal UI Framework | Window Management     | Window     | Creates bordered terminal windows with titles and customizable styling |
-- | Text Styling          |                       | Text       | Text styling with ANSI color codes, formatting, and Unicode symbols    |
-- | UI Elements           |                       | Popup      | Pre-styled dialog boxes (error, info, warning, message)                |
-- | Drawing               |                       | Draw       | Drawing primitives (rectangles, circles, triangles, lines)             |
-- | Content Management    |                       | Scroller   | Content scrolling mechanism for large datasets                         |
-- | Navigation            |                       | Options    | Interactive menu system with selection capabilities                    |
-- | Audio Playback        | File Management       | Sound      | Audio file loading and playback control                                |
-- | Control               |                       | Playback   | Volume, speed, and position control                                    |
-- | Monitoring            |                       | Status     | Playback status monitoring and metadata access                         |
-- | Playlist              |                       | Management | Playlist management with different loop modes                          |
-- | Cross-Platform Support| Environment Detection | Platform   | OS detection (Windows, Linux, macOS)                                   |
-- | Terminal              |                       | Utilities  | Terminal size detection, cursor control, keyboard input handling       |
-- |-----------------------|-----------------------|------------|------------------------------------------------------------------------|
--
-- ## Key Component Classes
--
-- | Component           | Purpose                    | Main Methods                                    |
-- |---------------------|----------------------------|-------------------------------------------------|
-- | RMP.Window          | Terminal window management | createWindow(), setId(), getId()                |
-- | RMP.Text            | Text styling and formatting| setPosition(), render(), getColoredText()       |
-- | RMP.VirtualTerminal | Virtual terminal buffer    | writeText(), setChar(), render(), merge()       |
-- | RMP.Frame           | Main application frame     | run(), add(), addMany()                         |
-- | RMP.Sound           | Audio playback system      | play(), pause(), stop(), setVolume(), addTrack()|
-- | RMP.Popup           | Modal dialog boxes         | run()                                           |
-- | RMP.Options         | Interactive option menus   | setOptions(), next(), prev(), getSelected()     |
-- | RMP.Scroller        | Content scrolling          | nextLine(), prevLine(), getVisible()            |
-- | RMP.Draw            | Drawing primitives         | rectangle(), circle(), triangle(), line()       |
-- | RMP.Input           | Text input handling        | handleKey(), render(), getText()                |
-- | RMP.Path            | File system operations     | listDir(), makeDir(), removeDir()               |
-- | RMP.Socket          | Network communication      | connect(), send(), recv()                       |
-- | RMP.Config          | Configuration management   | load(), getThemesAsObject()                     |
-- | RMP.Table           | Data tables                | setDataAt(), render()                           |
-- | RMP.Code            | Syntax highlighting        | highlight(), setSyntax()                        |
-- | RMP.StatusBar       | Status bar components      | addComponent(), render()                        |
-- | RMP.Menu            | Menu systems               | addOption(), getSelectedOption()                |
-- | RMP.LoadingSpinner  | Progress indicators        | nextFrame(), setPattern()                       |
-- | RMP.Mouse           | Mouse event handling       | getX(), getY()                                  |
-- | RMP.Notify          | Notification system        | error(), info(), message()                      |
-- | RMP.EventListener   | Event handling             | addEventListener(), handleEvent()               |
-- | RMP.SimpleInput     | High-level input           | render(), focus(), getValue()                   |
-- |---------------------|----------------------------|-------------------------------------------------|
--
-- ## Supported Platforms and Keyboard Keys
--
-- | Platform | Enum Value               | Description             |
-- |----------|--------------------------|-------------------------|
-- | Linux    | RMP.PlatformType.LINUX   | Linux operating systems |
-- | Windows  | RMP.PlatformType.WINDOWS | Microsoft Windows       |
-- | macOS    | RMP.PlatformType.MAC     | Apple macOS             |
-- | Unknown  | RMP.PlatformType.UNKNOWN | Other/unknown platform  |
-- |----------|--------------------------|-------------------------|
--
-- ## Keyboard Keys Mapping
--
-- | Key Category  | Enum                                                  | Description                     |
-- |---------------|-------------------------------------------------------|---------------------------------|
-- | Control Keys  | RMP.KEY_CTRL_A - RMP.KEY_CTRL_Z                       | Ctrl + letter combinations      |
-- | Alt Keys      | RMP.KEY_ALT_A - RMP.KEY_ALT_Z                         | Alt + letter combinations       |
-- | Special Keys  | RMP.KEY_ENTER, RMP.KEY_SPACE, RMP.KEY_ESCAPE          | Enter, space, escape keys       |
-- | Arrow Keys    | RMP.KEY_UP, RMP.KEY_DOWN, RMP.KEY_LEFT, RMP.KEY_RIGHT | Directional arrow keys          |
-- | Function Keys | RMP.KEY_F1 - RMP.KEY_F12                              | Function keys F1 through F12    |
-- | Digits        | RMP.KEY_0 - RMP.KEY_9                                 | Number keys 0 through 9         |
-- | Alphabet      | RMP.KEY_A - RMP.KEY_Z                                 | Lowercase letter keys           |
-- | Shift Keys    | RMP.KEY_SHIFT_A - RMP.KEY_SHIFT_Z                     | Uppercase/shifted letter keys   |
-- | Special Chars | RMP.KEY_PLUS, RMP.KEY_MINUS, RMP.KEY_GT, etc.         | Various special character keys  |
-- |---------------|-------------------------------------------------------|---------------------------------|
--
-- ## Color Support
--
-- | Color Type | Brightness | Colors Available                                      |
-- |------------|------------|-------------------------------------------------------|
-- | Foreground | Non-Bright | Black, Red, Green, Yellow, Blue, Magenta, Cyan, White |
-- | Foreground | Bright     | Black, Red, Green, Yellow, Blue, Magenta, Cyan, White |
-- | Background | Non-Bright | Black, Red, Green, Yellow, Blue, Magenta, Cyan, White |
-- | Background | Bright     | Black, Red, Green, Yellow, Blue, Magenta, Cyan, White |
-- |------------|------------|-------------------------------------------------------|
--
-- ## Text Styling Options
--
-- | Style            | Description                           | Enum Value                    |
-- |------------------|---------------------------------------|-------------------------------|
-- | Strike           | Strikethrough text                    | RMP.TextStyle.Strike          |
-- | Hide             | Hidden/invisible text                 | RMP.TextStyle.Hide            |
-- | Underline        | Single underline                      | RMP.TextStyle.Underline       |
-- | Double Underline | Double underline                      | RMP.TextStyle.DoubleUnderline |
-- | Bold             | Bold text                             | RMP.TextStyle.Bold            |
-- | Italic           | Italic text                           | RMP.TextStyle.Italic          |
-- | Reverse          | Reversed background/foreground colors | RMP.TextStyle.Reverse         |
-- | Overline         | Overline text                         | RMP.TextStyle.Overline        |
-- | Regular          | Reset to normal text                  | RMP.TextStyle.Regular         |
-- |------------------|---------------------------------------|-------------------------------|
--
-- ## Border Styles
--
-- | Style Name     | Type                       | Description |
-- |----------------|----------------------------|------------------------------------|
-- | NoBorder       | No borders                 | No visual borders                  |
-- | LightBorder    | Single-line                | Thin, single-line borders          |
-- | HeavyBorder    | Double-line                | Thick, double-line borders         |
-- | RoundedCorners | Light with rounded corners | Light borders with rounded corners |
-- |----------------|----------------------------|------------------------------------|
--
-- ## Animation Patterns
--
-- | Category     | Pattern Name                     | Description                         |
-- |--------------|----------------------------------|-------------------------------------|
-- | Spinners     | Spinner, BraillePattern          | Various spinning animation patterns |
-- | Dots         | Dots, Dots2, Dots3               | Dot-based animations                |
-- | Lines        | Line                             | Simple line rotation                |
-- | Arrows       | Arrow                            | Arrow rotation patterns             |
-- | Clocks       | Clock, Moon                      | Time-based animations               |
-- | Blocks       | Block, GrowingBar                | Block-based animations              |
-- | Shapes       | SquareCorners, Triangle          | Geometric shape animations          |
-- | Weather      | Weather, Fire, WaterFlow         | Nature-themed animations            |
-- | Tech         | Binary, Signal, Download, Upload | Technology-themed patterns          |
-- | Faces        | Happy, Thinking, Sleeping        | Emotion-based animations            |
-- | Animals      | Cat, Dog, Bird, Fish             | Animal-themed animations            |
-- | Food         | Coffee, Cooking, Eating          | Food-themed animations              |
-- | Vehicles     | Car, Plane, Rocket               | Vehicle-themed patterns             |
-- | Music        | Music, Dance, Painting           | Creative arts patterns              |
-- | Sports       | Ball, Chess, Dice                | Sports and games patterns           |
-- | Time         | Hourglass, Calendar              | Time-related animations             |
-- | Hearts       | Hearts, Stars, Geometric         | Symbol and geometric patterns       |
-- | Tools        | Tools, Writing, Science          | Working tool patterns               |
-- | Fantasy      | Magic, Dragon, Unicorn           | Fantasy-themed animations           |
-- | Professional | Loading, Progress, Working       | Business-themed patterns            |
-- |--------------|----------------------------------|-------------------------------------|
--
-- ## Audio Playback Modes
--
-- | Mode          | Enum                           | Description                 |
-- |---------------|--------------------------------|-----------------------------|
-- | Once          | RMP.PlaybackMode.ONCE          | Play once, then stop        |
-- | Loop Single   | RMP.PlaybackMode.LOOP_SINGLE   | Loop the current track      |
-- | Loop Playlist | RMP.PlaybackMode.LOOP_PLAYLIST | Loop the entire playlist    |
-- | Shuffle       | RMP.PlaybackMode.SHUFFLE       | Play tracks in random order |
-- |---------------|--------------------------------|-----------------------------|
--
-- ## Audio States
--
-- | State   | Enum              | Description                    |
-- |---------|-------------------|--------------------------------|
-- | Stopped | RMP.State.STOPPED | Audio is stopped               |
-- | Playing | RMP.State.PLAYING | Audio is currently playing     |
-- | Paused  | RMP.State.PAUSED  | Audio is paused                |
-- | Loading | RMP.State.LOADING | Audio file is loading          |
-- | Error   | RMP.State.ERROR   | Error occurred during playback |
-- |---------|-------------------|--------------------------------|
--
-- ## Popup Positioning
--
-- | Position     | Enum                           | Description            |
-- |--------------|--------------------------------|------------------------|
-- | Center       | RMP.PopupPosition.CENTER       | Center of the terminal |
-- | Top Left     | RMP.PopupPosition.TOP_LEFT     | Top-left corner        |
-- | Top Right    | RMP.PopupPosition.TOP_RIGHT    | Top-right corner       |
-- | Bottom Left  | RMP.PopupPosition.BUTTOM_LEFT  | Bottom-left corner     |
-- | Bottom Right | RMP.PopupPosition.BUTTOM_RIGHT | Bottom-right corner    |
-- |--------------|--------------------------------|------------------------|
--
-- ## Socket Protocol Support
--
-- | Protocol | Enum   | Description                       |
-- |----------|--------|-----------------------------------|
-- | TCP      | "tcp"  | Transmission Control Protocol     |
-- | UDP      | "udp"  | User Datagram Protocol            |
-- | ICMP     | "icmp" | Internet Control Message Protocol |
-- | Raw      | "raw"  | Raw socket access                 |
-- |----------|--------|-----------------------------------|
--
-- ## Status Bar Alignment Options
--
-- | Alignment | Enum                         | Description             |
-- |-----------|------------------------------|-------------------------|
-- | Left      | RMP.StatusBarPosition.LEFT   | Left-aligned content    |
-- | Right     | RMP.StatusBarPosition.RIGHT  | Right-aligned content   |
-- | Center    | RMP.StatusBarPosition.CENTER | Center-aligned content  |
-- |-----------|------------------------------|-------------------------|
--
-- ## Code Syntax Highlighting Support
--
-- | Language | Enum                  | Keywords Highlighted                |
-- |----------|-----------------------|-------------------------------------|
-- | Lua      | RMP.CodeSyntax.LUA    | Lua keywords, comments, literals    |
-- | C        | RMP.CodeSyntax.C      | C keywords, comments, data types    |
-- | Python   | RMP.CodeSyntax.PYTHON | Python keywords, comments, literals |
-- |----------|-----------------------|-------------------------------------|
--
-- ## Event Types
--
-- | Event Category     | Enum                           | Description              |
-- |--------------------|--------------------------------|--------------------------|
-- | Keyboard           | RMP.EventType.Keyboard         | Keyboard input events    |
-- | Mouse              | RMP.EventType.Mouse            | Mouse input events       |
-- | Focus              | RMP.EventType.Focuse           | Focus/unfocus events     |
-- | Transform Data Get | RMP.EventType.TransformDataGet | Data retrieval events    |
-- | Transform Data Put | RMP.EventType.TransformDataPut | Data insertion events    |
-- | Sound              | RMP.EventType.Sound            | Audio-related events     |
-- | Configuration      | RMP.EventType.Configuration    | Configuration events     |
-- | Template           | RMP.EventType.Template         | Framework template events|
-- |--------------------|--------------------------------|--------------------------|
--
-- ## Emoji/Symbol Icons
--
-- | Icon Type           | Variable                                                        | Symbol              |
-- |---------------------|-----------------------------------------------------------------|---------------------|
-- | Music               | RMP.Pause_start                                                 | ⏯                   |
-- | Navigation          | RMP.Next, RMP.Prev                                              | ⏵, ⏴                |
-- | Playback            | RMP.Pause                                                       | ⏸                   |
-- | Volume              | RMP.Volume_max, RMP.Volume_mute, RMP.Volume_low, RMP.Volume_med | 🔊, 🔇, 🔈, 🔉      |
-- | Loops               | RMP.Single_loop, RMP.Playlist_loop                              | 🔂, 🔁              |
-- | Weather             | RMP.Snow, RMP.Stars                                             | ❆, ✨               |
-- | UI Elements         | RMP.Search_emo                                                  | 🔎                  |
-- | Song Characters     | RMP.Song_char_1-5                                               | 💕, 💞, 🎵, 🎶, 💖  |
-- | Progress Bars       | RMP.Bar_1, RMP.Bar_2, RMP.Bar_3                                 | ❚, ❙, ❘             |
-- | Progress Fill       | RMP.Bar_100_per                                                 | █                   |
-- | Progress Shading    | RMP.Bar_Shading_00_per-75_per                                   | (space), ░, ▒, ▓    |
-- | Progress Indicators | RMP.Bar_l_to_r_12_5_per-87_5_per                                | ▏, ▎, ▍, ▌, ▋, ▊, ▉ |
-- | Progress Height     | RMP.Bar_b_to_u_12_5_per-87_5_per                                | ▇, ▆, ▅, ▄, ▃, ▂, ▁ |
-- | Error/Warning       | RMP.IError, RMP.IWarning, RMP.IMessage, RMP.IInfo               | ❌, ⚠️, 💬, ℹ️      |
-- |---------------------|-----------------------------------------------------------------|---------------------|

-- TODO: add re to syntax Code class for better code highlighting
-- TODO: make some functions async
-- TODO: Notify
-- TODO: Popup
-- TODO: Menu
-- TODO: handle ssl/tls to a socket
-- TODO: handle Mouse

--- @module 'rmp.rmp'
RMP                       = {}

local io                  = require("io")
local utf8                = require("utf8")

local keyboard            = require("rmp.keyboard")
local rmpaudio            = require("rmp.rmpaudio")
local sleep               = require("rmp.sleep")
local platform            = require("rmp.platform")
local directory           = require("rmp.directory")
local window              = require("rmp.window")
local vt_rmp              = require("rmp.virtualterminalrmp")
local rsocket             = require("rmp.rsocket")

-- require rmp utility
local OOP                 = require("rmp.oop")
local Promise             = require("rmp.promises")
local FutureLib           = require("rmp.future")
local Util                = require("rmp.util")
local Effects             = require("rmp.effects")

local BaseEffect          = Effects.BaseEffect
local Easing              = Effects.Easing
local extractRGB          = Effects.extractRGB
local createHexFromRGB    = Effects.createHexFromRGB
local normalizeColorToHex = Effects.normalizeColorToHex

--- @alias HashMap table
local HashMap             = Util.HashMap
local Queue               = Util.Queue

--- @type integer
local global_count_enum   = -1

--- @param reset boolean | nil
--- @param value integer | nil
--- @param start integer | nil
--- @return integer
function RMP.enum(reset, value, start)
    local reset = reset or false
    --- @type integer
    local value = value or 1
    local start = start or -1

    if reset then
        global_count_enum = start
    end
    global_count_enum = global_count_enum + value
    return global_count_enum
end

do -- os detection
    --- @enum PlatformType
    RMP.PlatformType = {
        LINUX   = RMP.enum(true),
        WINDOWS = RMP.enum(),
        MAC     = RMP.enum(),
        UNKNOWN = RMP.enum()
    }

    --- @return PlatformType
    function RMP.getOs() -- it will return enum value
        return platform.platform()
    end
end

-- check ansi escape code : https://en.wikipedia.org/wiki/ANSI_escape_code
-- line style
--- @enum TextStyle
RMP.TextStyle = {
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

--- @type string
RMP.FG        = "38"
--- @type string
RMP.BG        = "48"

--- colorFromHex({ 255, 255, 255 })
--- colorFromHex({ r = 255, g = 255, b = 255 })
--- colorFromHex(0xffffff)
--- colorFromHex("#ffffff")
--- colorFromHex("ffffff")
--- @param hex string|table|number
--- @param fg_or_bg string|nil
--- @return string|nil
function RMP.colorFromHex(hex, fg_or_bg)
    local fb = fg_or_bg or RMP.FG
    if type(hex) == "string" then
        if hex:sub(1, 1) == "#" then
            hex = hex:sub(2)
        end
        local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
        return string.format("\27[%s;2;%d;%d;%dm", fb, r, g, b)
    elseif type(hex) == "number" then
        local r = math.floor(hex / 65536) % 256
        local g = math.floor(hex / 256) % 256
        local b = hex % 256
        return string.format("\27[%s;2;%d;%d;%dm", fb, r, g, b)
    elseif type(hex) == "table" and #hex == 3 then
        return string.format("\27[%s;2;%d;%d;%dm", fb, hex.r or hex[1] or 0, hex.g or hex[2] or 0,
            hex.b or hex[3] or 0
        )
    end
    return nil
end

--- colorFromHex(addHexColors("#ff00ff" , "#001818"))
--- @param hex1 string
--- @param hex2 string
--- @return string
function RMP.addHexColors(hex1, hex2)
    local r = math.min(tonumber(hex1:sub(2, 3), 16) + tonumber(hex2:sub(2, 3), 16), 255)
    local g = math.min(tonumber(hex1:sub(4, 5), 16) + tonumber(hex2:sub(4, 5), 16), 255)
    local b = math.min(tonumber(hex1:sub(6, 7), 16) + tonumber(hex2:sub(6, 7), 16), 255)
    return string.format("#%02x%02x%02x", r, g, b)
end

--- colorFromHsv(360 , 100 , 100 , FG)
--- h: 0-360 degrees
--- s: 0-100 percentage
--- v: 0-100 percentage
--- Returns: "#rrggbb" color
---
--- https://fr.wikipedia.org/wiki/Teinte_saturation_lumi%C3%A8re
---
--- the formula is :
---
---     step1: normalize our hsv values
---         h : 0 -> 360 => h%360 : 0 -> 360
---         s : 0 -> 100 => s/100 : 0 -> 1
---         v : 0 -> 100 => v/100 : 0 -> 1
---
---     step2: calculate c , x , m
---         c = (normalized_v) * (normalized_s)
---         x = c * (1 - |(((normalized_h) / 60) mod 2) - 1|)
---         m = (normalized_v) - c
---
---     step3: check our hue to choose our temporary r1 , g2 , b3 values
--          if hue < 60 then        r1, g1, b1 = c, x, 0
--          elseif hue < 120 then   r1, g1, b1 = x, c, 0
--          elseif hue < 180 then   r1, g1, b1 = 0, c, x
--          elseif hue < 240 then   r1, g1, b1 = 0, x, c
--          elseif hue < 300 then   r1, g1, b1 = x, 0, c
--          else                    r1, g1, b1 = c, 0, x
--
--      step4: calculate our rgb values and make sure that the values between 0 to 255
--          r = max(0, min(255, floor((r1 + m) * 255 + 0.5)))
--          g = max(0, min(255, floor((g1 + m) * 255 + 0.5)))
--          b = max(0, min(255, floor((b1 + m) * 255 + 0.5)))
---
--- NOTE: go to `To RGB` title to find converting formula
--- https://en.wikipedia.org/wiki/HSL_and_HSV
---
--- @param h number
--- @param s number
--- @param v number
--- @param fg_or_bg string
--- @return string|nil
function RMP.colorFromHsv(h, s, v, fg_or_bg)
    local h_deg = h % 360
    local s_norm = s / 100
    local v_norm = v / 100

    local c = v_norm * s_norm
    local x = c * (1 - math.abs((h_deg / 60) % 2 - 1))
    local m = v_norm - c

    local r1, g1, b1

    -- 360/6 => 0 to 6 from wikipedia formula
    if h_deg < 60 then
        r1, g1, b1 = c, x, 0
    elseif h_deg < 120 then
        r1, g1, b1 = x, c, 0
    elseif h_deg < 180 then
        r1, g1, b1 = 0, c, x
    elseif h_deg < 240 then
        r1, g1, b1 = 0, x, c
    elseif h_deg < 300 then
        r1, g1, b1 = x, 0, c
    else
        r1, g1, b1 = c, 0, x
    end

    local r = math.max(0, math.min(255, math.floor((r1 + m) * 255 + 0.5)))
    local g = math.max(0, math.min(255, math.floor((g1 + m) * 255 + 0.5)))
    local b = math.max(0, math.min(255, math.floor((b1 + m) * 255 + 0.5)))

    return RMP.colorFromHex(string.format("#%02x%02x%02x", r, g, b), fg_or_bg)
end

-- ForeGround
--- @enum FGColors
RMP.FGColors            = {
    --- @type table
    NoBrights = {
        Black   = RMP.colorFromHex("#000000", RMP.FG), --- "\27[30m"
        Red     = RMP.colorFromHex("#ff0000", RMP.FG), --- "\27[31m"
        Green   = RMP.colorFromHex("#00ff00", RMP.FG), --- "\27[32m"
        Yellow  = RMP.colorFromHex("#ffff00", RMP.FG), --- "\27[33m"
        Blue    = RMP.colorFromHex("#0000ff", RMP.FG), --- "\27[34m"
        Magenta = RMP.colorFromHex("#ff00ff", RMP.FG), --- "\27[35m"
        Cyan    = RMP.colorFromHex("#00ffff", RMP.FG), --- "\27[36m"
        White   = RMP.colorFromHex("#ffffff", RMP.FG)  --- "\27[37m"
    },
    --- @type table
    Brights = {
        -- ForeGround bright
        Black   = RMP.colorFromHex("#808080", RMP.FG), --- "\27[90m"
        Red     = RMP.colorFromHex("#FF5555", RMP.FG), --- "\27[91m"
        Green   = RMP.colorFromHex("#32cd32", RMP.FG), --- "\27[92m"
        Yellow  = RMP.colorFromHex("#ffeb3b", RMP.FG), --- "\27[93m"
        Blue    = RMP.colorFromHex("#1e90ff", RMP.FG), --- "\27[94m"
        Magenta = RMP.colorFromHex("#ff77ff", RMP.FG), --- "\27[95m"
        Cyan    = RMP.colorFromHex("#7fffd4", RMP.FG), --- "\27[96m"
        White   = RMP.colorFromHex("#f4f4f4", RMP.FG)  --- "\27[97m"
    }
}

-- BackGround
--- @enum BGColors
RMP.BGColors            = {
    --- @type table
    NoBrights = {
        Black   = RMP.colorFromHex("#000000", RMP.BG), --- "\27[40m"
        Red     = RMP.colorFromHex("#ff0000", RMP.BG), --- "\27[41m"
        Green   = RMP.colorFromHex("#00ff00", RMP.BG), --- "\27[42m"
        Yellow  = RMP.colorFromHex("#ffff00", RMP.BG), --- "\27[43m"
        Blue    = RMP.colorFromHex("#0000ff", RMP.BG), --- "\27[44m"
        Magenta = RMP.colorFromHex("#ff00ff", RMP.BG), --- "\27[45m"
        Cyan    = RMP.colorFromHex("#00ffff", RMP.BG), --- "\27[46m"
        White   = RMP.colorFromHex("#ffffff", RMP.BG)  --- "\27[47m"
    },
    --- @type table
    Brights = {
        -- BackGround bright
        Black   = RMP.colorFromHex("#808080", RMP.BG), --- "\27[100m"
        Red     = RMP.colorFromHex("#FF5555", RMP.BG), --- "\27[101m"
        Green   = RMP.colorFromHex("#32cd32", RMP.BG), --- "\27[102m"
        Yellow  = RMP.colorFromHex("#ffeb3b", RMP.BG), --- "\27[103m"
        Blue    = RMP.colorFromHex("#1e90ff", RMP.BG), --- "\27[104m"
        Magenta = RMP.colorFromHex("#ff77ff", RMP.BG), --- "\27[105m"
        Cyan    = RMP.colorFromHex("#7fffd4", RMP.BG), --- "\27[106m"
        White   = RMP.colorFromHex("#f4f4f4", RMP.BG)  --- "\27[107m"
    }
}

RMP.Default             = "\27[0m"

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

-- RMP.CheckMark           = "✔"
-- RMP.Error               = "✗"

RMP.IError              = "❌"
RMP.IWarning            = "⚠️"
RMP.IMessage            = "💬"
RMP.IInfo               = "ℹ️"

--- @interface Renderable
RMP.Renderable          = OOP.interface("Renderable",
    -- @return : virtual terminal frame
    "render")

-- TODO: handle this border table later to let plugin developers change the border
--- @enum BoxDrawing
RMP.BoxDrawing          = {
    --- @type table
    NoBorder = {
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
    },
    --- @type table
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
    --- @type table
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
    --- @type table
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
}

-- Animation patterns
--- @enum AnimationPatterns
RMP.AnimationPatterns   = {
    --- @enum BraillePattern
    BraillePattern = {
        "⠁", "⠃", "⠇", "⠏", "⠟", "⠿", "⣿", "⡿",
        "⣟", "⣯", "⣷", "⣾", "⣿"
    },

    --- @enum Spinner
    Spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    --- @enum Dots
    Dots = { "⠁", "⠂", "⠄", "⡀", "⢀", "⠠", "⠐", "⠈" },
    --- @enum Line
    Line = { "-", "\\", "|", "/" },
    --- @enum Arrow
    Arrow = { "←", "↖", "↑", "↗", "→", "↘", "↓", "↙" },
    --- @enum BouncingBall
    BouncingBall = { "⠁", "⠂", "⠄", "⡀", "⢀", "⠠", "⠐", "⠈" },
    --- @enum Clock
    Clock = { "🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚", "🕛" },
    --- @enum Moon
    Moon = { "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘" },
    --- @enum Block
    Block = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█", "▇", "▆", "▅", "▄", "▃", "▂" },
    --- @enum Circle
    Circle = { "◐", "◓", "◑", "◒" },
    --- @enum SquareCorners
    SquareCorners = { "◰", "◳", "◲", "◱" },
    --- @enum Dots2
    Dots2 = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
    --- @enum Dots3
    Dots3 = { "⠋", "⠙", "⠚", "⠞", "⠖", "⠦", "⠴", "⠲", "⠳", "⠓" },
    --- @enum BoxBounce
    BoxBounce = { "▖", "▘", "▝", "▗" },
    --- @enum Triangle
    Triangle = { "◢", "◣", "◤", "◥" },
    --- @enum GrowingBar
    GrowingBar = { "▁", "▃", "▄", "▅", "▆", "▇", "█" },

    -- NEW ANIMATION PATTERNS:

    -- Braille Variations
    --- @enum BrailleClockwise
    BrailleClockwise = {
        "⠁", "⠃", "⠇", "⠏", "⠟", "⠯", "⠾", "⣾",
        "⣷", "⣯", "⣟", "⣏", "⡋", "⠍", "⠎", "⠞"
    },
    --- @enum BrailleCounterClockwise
    BrailleCounterClockwise = {
        "⠁", "⠂", "⠄", "⠈", "⠐", "⠠", "⠡", "⠢",
        "⠤", "⠦", "⠶", "⠞", "⠎", "⠍", "⡋", "⣏"
    },
    --- @enum BrailleDotSpin
    BrailleDotSpin = {
        "⠁", "⠂", "⠄", "⠈", "⠐", "⠠", "⡀", "⢀",
        "⢈", "⢐", "⢠", "⡠", "⠤", "⠢", "⠡", "⠠"
    },
    --- @enum BrailleSpiral
    BrailleSpiral = {
        "⠁", "⠃", "⠋", "⠛", "⠟", "⠿", "⡿", "⣿",
        "⣻", "⣹", "⣸", "⣴", "⣲", "⣱", "⣰", "⣮"
    },

    -- Weather & Nature
    --- @enum Weather
    Weather = { "☀️", "⛅", "☁️", "🌧️", "⛈️", "🌦️" },
    --- @enum GrowingPlant
    GrowingPlant = { "🌱", "🌿", "🪴", "🌲", "🌳" },
    --- @enum WaterFlow
    WaterFlow = { "💧", "🌊", "💦", "🌀", "🌫️" },
    --- @enum Fire
    Fire = { "🔥", "🌪️", "💥", "✨", "🌟" },

    -- Technology & Loading
    --- @enum Binary
    Binary = { "0", "1", "0", "1", "0", "1" },
    --- @enum Signal
    Signal = { "📶", "📶", "📶", "📶", "📶", " " },
    --- @enum Download
    Download = { "📥", "⏬", "⬇️", "🔽", "📥" },
    --- @enum Upload
    Upload = { "📤", "⏫", "⬆️", "🔼", "📤" },

    -- Faces & Emotions
    --- @enum Happy
    Happy = { "😊", "😄", "😃", "😀", "😁", "😆" },
    --- @enum Thinking
    Thinking = { "🤔", "💭", "🧠", "💡", "🌟" },
    --- @enum Sleeping
    Sleeping = { "😴", "💤", "😪", "🌙", "🛌" },

    -- Animals & Creatures
    --- @enum Cat
    Cat = { "😺", "😸", "😹", "😻", "😼", "😽" },
    --- @enum Dog
    Dog = { "🐶", "🐕", "🦮", "🐩", "🐕‍🦺" },
    --- @enum Bird
    Bird = { "🐦", "🦅", "🦆", "🦉", "🐧" },
    --- @enum Fish
    Fish = { "🐠", "🐟", "🐡", "🦈", "🐋" },

    -- Food & Drink
    --- @enum Coffee
    Coffee = { "☕", "🌱", "🔥", "💧", "☕" },
    --- @enum Cooking
    Cooking = { "🍳", "🥘", "🍲", "🥣", "🍜" },
    --- @enum Eating
    Eating = { "🍎", "🍕", "🍦", "🍩", "🍰" },

    -- Vehicles & Travel
    --- @enum Car
    Car = { "🚗", "🚙", "🚐", "🚛", "🚒" },
    --- @enum Plane
    Plane = { "✈️", "🛫", "🛬", "🛩️", "💺" },
    --- @enum Rocket
    Rocket = { "🚀", "🛸", "👽", "🌟", "🌕" },

    -- Music & Arts
    --- @enum Music
    Music = { "🎵", "🎶", "🎼", "🎹", "🎷", "🎺" },
    --- @enum Dance
    Dance = { "💃", "🕺", "👯", "🎭", "🎪" },
    --- @enum Painting
    Painting = { "🎨", "🖼️", "🖌️", "👨‍🎨", "🖍️" },

    -- Sports & Games
    --- @enum Ball
    Ball = { "⚽", "🏀", "🏈", "⚾", "🎾", "🏐" },
    --- @enum Chess
    Chess = { "♟️", "♜", "♞", "♝", "♛", "♚" },
    --- @enum Dice
    Dice = { "⚀", "⚁", "⚂", "⚃", "⚄", "⚅" },

    -- Time & Calendar
    --- @enum Hourglass
    Hourglass = { "⏳", "⌛", "⏰", "🕰️", "📅" },
    --- @enum Calendar
    Calendar = { "📅", "📆", "🗓️", "⏱️", "⌚" },

    -- Shapes & Symbols
    --- @enum Hearts
    Hearts = { "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎" },
    --- @enum Stars
    Stars = { "⭐", "🌟", "✨", "💫", "🌠" },
    --- @enum Geometric
    Geometric = { "⬜", "⬛", "🔴", "🟢", "🔵", "🟡", "🟣" },

    -- Tools & Objects
    --- @enum Tools
    Tools = { "🛠️", "🔧", "🔨", "⚒️", "🪚", "⛏️" },
    --- @enum Writing
    Writing = { "📝", "✏️", "🖊️", "🖋️", "📄", "📖" },
    --- @enum Science
    Science = { "🔬", "🧪", "⚗️", "🧫", "🦠", "🧬" },

    -- Advanced Braille Patterns
    --- @enum BrailleWave
    BrailleWave = {
        "⠁", "⠃", "⠇", "⠏", "⠟", "⠿", "⡿", "⣿",
        "⣻", "⣹", "⣸", "⣴", "⣲", "⣱", "⣰", "⣮"
    },
    --- @enum BraillePulse
    BraillePulse = {
        "⠁", "⠉", "⠍", "⠝", "⠟", "⠿", "⡿", "⣿",
        "⡿", "⠿", "⠟", "⠝", "⠍", "⠉", "⠁", "⠀"
    },
    --- @enum BrailleExpand
    BrailleExpand = {
        "⠁", "⠃", "⠋", "⠛", "⠟", "⠿", "⡿", "⣿",
        "⣿", "⡿", "⠿", "⠟", "⠛", "⠋", "⠃", "⠁"
    },

    -- Minimalist
    --- @enum MinimalDot
    MinimalDot = { ".", "..", "...", "....", ".....", "......" },
    --- @enum MinimalBar
    MinimalBar = { "[    ]", "[=   ]", "[==  ]", "[=== ]", "[====]" },
    --- @enum MinimalSpin
    MinimalSpin = { "|", "/", "-", "\\" },

    -- Retro & Pixel
    --- @enum PixelMan
    PixelMan = { "ᕕ( ᐛ )ᕗ", "ᕕ( ◕3◕ )ᕗ", "ᕕ( ◔3◔ )ᕗ", "ᕕ( ◕‿◕ )ᕗ" },
    --- @enum RetroGame
    RetroGame = { "▰", "▱", "◼", "◻", "■", "□" },
    --- @enum Arcade
    Arcade = { "🕹️", "👾", "🤖", "🎮", "💾", "📺" },

    -- Fantasy & Magic
    --- @enum Magic
    Magic = { "🔮", "✨", "🌟", "💫", "🪄", "🧙" },
    --- @enum Dragon
    Dragon = { "🐲", "🔥", "🌪️", "💨", "⚡" },
    --- @enum Unicorn
    Unicorn = { "🦄", "🌈", "🌟", "✨", "💫" },

    -- Professional
    --- @enum Loading
    Loading = { "⏳", "⌛", "⏰", "🕐", "🕑", "🕒" },
    --- @enum Progress
    Progress = { "▱▱▱", "▰▱▱", "▰▰▱", "▰▰▰" },
    --- @enum Working
    Working = { "💼", "📊", "📈", "📉", "📋" }
}

--- @class rmp.rmp.LoadingSpinner
RMP.LoadingSpinner      = OOP.class("LoadingSpinner", nil, RMP.Renderable)
do
    --- @param x integer
    --- @param y integer
    --- @param fg FGColors
    --- @param bg BGColors
    --- @param vterm rmp.rmp.VirtualTerminal
    --- @return self
    function RMP.LoadingSpinner:constructor(x, y, fg, bg, vterm)
        self.x = x or 2
        self.y = y or 2
        self.fg = fg or RMP.FGColors.Brights.White
        self.bg = bg or RMP.BGColors.NoBrights.Black
        --- @diagnostic disable-next-line
        self.vterm = vterm or RMP.VirtualTerminal.new()
        self.frameIndex = 1
        self.pattern = RMP.AnimationPatterns.Spinner
        self.prefix = ""
        self.suffix = ""
        return self
    end

    --- @generic T
    --- @param patternName T
    --- @return self
    function RMP.LoadingSpinner:setPattern(patternName)
        self.pattern = patternName
        self.frameIndex = 1
        return self
    end

    --- @param prefix string
    --- @param suffix string
    --- @return self
    function RMP.LoadingSpinner:setText(prefix, suffix)
        self.prefix = prefix or ""
        self.suffix = suffix or ""
        return self
    end

    --- @param fg FGColors
    --- @param bg BGColors
    --- @return self
    function RMP.LoadingSpinner:setColors(fg, bg)
        self.fg = fg or self.fg
        self.bg = bg or self.bg
        return self
    end

    --- @return self
    function RMP.LoadingSpinner:nextFrame()
        local char = self.pattern[self.frameIndex]
        local text = self.prefix .. char .. self.suffix

        self.vterm:writeText(self.x, self.y, text, self.fg, self.bg)

        self.frameIndex = (self.frameIndex % #self.pattern) + 1
        return self
    end

    --- @return self
    function RMP.LoadingSpinner:reset()
        self.frameIndex = 1
        return self
    end

    --- @overload fun() : rmp.rmp.VirtualTerminal
    function RMP.LoadingSpinner:render()
        return self.vterm
    end

    --- @return table
    function RMP.LoadingSpinner:getPatterns()
        return self.pattern
    end
end

-- TODO: for a moment
--- @deprecated
local function moveto(x, y, ret)
    local ret = ret or false
    if ret then
        return "\27[" .. y .. ";" .. x .. "H"
    else
        io.write("\27[" .. y .. ";" .. x .. "H")
    end
end

--- @deprecated
--- @class rmp.rmp.Duration
RMP.Duration = OOP.class("Duration")
do
    --- @param time integer
    --- @return self
    function RMP.Duration:constructor(time)
        --- @type integer
        self.time = time or 1
        return self
    end

    --- @return integer
    function RMP.Duration:fromSec()
        return self.time * 1000
    end

    --- @return integer
    function RMP.Duration:fromMilsec()
        return self.time
    end
end

--- @param time integer
function RMP.sleep(time)
    sleep.sleep(time)
end

-- Text class used to work with texts
--- @class rmp.rmp.Text
RMP.Text = OOP.class("Text", nil, RMP.Renderable)
do -- text
    -- constructor
    --- @param text string
    --- @param style TextStyle
    --- @param fg FGColors
    --- @param bg BGColors
    --- @param vterm VirtualTerminal
    --- @return self
    function RMP.Text:constructor(text, style, fg, bg, vterm)
        --- @diagnostic disable-next-line
        self.vterm = vterm or RMP.VirtualTerminal.new()
        self.text = text or ""
        self.fg = fg or RMP.Default
        self.bg = bg or RMP.Default
        self.style = style or RMP.Default
        self.x = 1
        self.y = 1
        return self
    end

    -- -- method Position in lua used to controle position of the text
    --- @param x integer
    --- @param y integer
    --- @return self
    function RMP.Text:setPosition(x, y)
        self.x = tonumber(x or 1)
        self.y = tonumber(y or 1)
        return self
    end

    --- @deprecated
    function RMP.Text:asVTerm()
        self.vterm:writeText(self.x, self.y, self.text, self.fg, self.bg, self.style)
        return self.vterm
    end

    --- @return VirtualTerminal
    function RMP.Text:render()
        --- @diagnostic disable-next-line
        return self:asVTerm()
    end

    -- ColoredText accept text and color and return colored text
    --- @return string
    function RMP.Text:getColoredText()
        return self.style .. self.bg .. self.fg .. self.text .. RMP.Default
    end

    --- @return string
    function RMP.Text:getText()
        return self.text
    end

    --- @param text string
    --- @return self
    function RMP.Text:setText(text)
        self.text = text
        return self
    end

    --- @return TextStyle
    function RMP.Text:getStyle()
        return self.style
    end

    --- @param style TextStyle
    --- @return self
    function RMP.Text:setStyle(style)
        self.style = style
        return self
    end

    --- @return FGColors
    function RMP.Text:getFGColor()
        return self.fg
    end

    --- @param fg FGColors
    --- @return self
    function RMP.Text:setFGColor(fg)
        self.fg = fg
        return self
    end

    --- @return BGColors
    function RMP.Text:getBGColor()
        return self.bg
    end

    --- @param bg BGColors
    --- @return self
    function RMP.Text:setBGColor(bg)
        self.bg = bg
        return self
    end
end

--- TODO: handle multiple char input for action:
--- Example: <C-a>s => do something when user press Ctrl + a and then s
RMP.KeyMap     = HashMap()

-- the RMP.enumeration value returns from HandleKey input
RMP.KEY_CTRL_A = RMP.enum(true); RMP.KeyMap:put("<C-a>", RMP.KEY_CTRL_A)
RMP.KEY_CTRL_B = RMP.enum(); RMP.KeyMap:put("<C-b>", RMP.KEY_CTRL_B)
RMP.KEY_CTRL_C = RMP.enum(); RMP.KeyMap:put("<C-c>", RMP.KEY_CTRL_C)
RMP.KEY_CTRL_D = RMP.enum(); RMP.KeyMap:put("<C-d>", RMP.KEY_CTRL_D)
RMP.KEY_CTRL_E = RMP.enum(); RMP.KeyMap:put("<C-e>", RMP.KEY_CTRL_E)
RMP.KEY_CTRL_F = RMP.enum(); RMP.KeyMap:put("<C-f>", RMP.KEY_CTRL_F)
RMP.KEY_CTRL_G = RMP.enum(); RMP.KeyMap:put("<C-g>", RMP.KEY_CTRL_G)
RMP.KEY_CTRL_H = RMP.enum(); RMP.KeyMap:put("<C-h>", RMP.KEY_CTRL_H)
RMP.KEY_CTRL_K = RMP.enum(); RMP.KeyMap:put("<C-k>", RMP.KEY_CTRL_K)
RMP.KEY_CTRL_L = RMP.enum(); RMP.KeyMap:put("<C-l>", RMP.KEY_CTRL_L)
RMP.KEY_CTRL_M = RMP.enum(); RMP.KeyMap:put("<C-m>", RMP.KEY_CTRL_M)
RMP.KEY_CTRL_N = RMP.enum(); RMP.KeyMap:put("<C-n>", RMP.KEY_CTRL_N)
RMP.KEY_CTRL_O = RMP.enum(); RMP.KeyMap:put("<C-o>", RMP.KEY_CTRL_O)
RMP.KEY_CTRL_P = RMP.enum(); RMP.KeyMap:put("<C-p>", RMP.KEY_CTRL_P)
RMP.KEY_CTRL_Q = RMP.enum(); RMP.KeyMap:put("<C-q>", RMP.KEY_CTRL_Q)
RMP.KEY_CTRL_R = RMP.enum(); RMP.KeyMap:put("<C-r>", RMP.KEY_CTRL_R)
RMP.KEY_CTRL_S = RMP.enum(); RMP.KeyMap:put("<C-s>", RMP.KEY_CTRL_S)
RMP.KEY_CTRL_T = RMP.enum(); RMP.KeyMap:put("<C-t>", RMP.KEY_CTRL_T)
RMP.KEY_CTRL_U = RMP.enum(); RMP.KeyMap:put("<C-u>", RMP.KEY_CTRL_U)
RMP.KEY_CTRL_V = RMP.enum(); RMP.KeyMap:put("<C-v>", RMP.KEY_CTRL_V)
RMP.KEY_CTRL_W = RMP.enum(); RMP.KeyMap:put("<C-w>", RMP.KEY_CTRL_W)
RMP.KEY_CTRL_X = RMP.enum(); RMP.KeyMap:put("<C-x>", RMP.KEY_CTRL_X)
RMP.KEY_CTRL_Y = RMP.enum(); RMP.KeyMap:put("<C-y>", RMP.KEY_CTRL_Y)
RMP.KEY_CTRL_Z = RMP.enum(); RMP.KeyMap:put("<C-z>", RMP.KEY_CTRL_Z)

RMP.KEY_ALT_A = RMP.enum(); RMP.KeyMap:put("<A-a>", RMP.KEY_ALT_A)
RMP.KEY_ALT_B = RMP.enum(); RMP.KeyMap:put("<A-b>", RMP.KEY_ALT_B)
RMP.KEY_ALT_C = RMP.enum(); RMP.KeyMap:put("<A-c>", RMP.KEY_ALT_C)
RMP.KEY_ALT_D = RMP.enum(); RMP.KeyMap:put("<A-d>", RMP.KEY_ALT_D)
RMP.KEY_ALT_E = RMP.enum(); RMP.KeyMap:put("<A-e>", RMP.KEY_ALT_E)
RMP.KEY_ALT_F = RMP.enum(); RMP.KeyMap:put("<A-f>", RMP.KEY_ALT_F)
RMP.KEY_ALT_G = RMP.enum(); RMP.KeyMap:put("<A-g>", RMP.KEY_ALT_G)
RMP.KEY_ALT_H = RMP.enum(); RMP.KeyMap:put("<A-h>", RMP.KEY_ALT_H)
RMP.KEY_ALT_I = RMP.enum(); RMP.KeyMap:put("<A-i>", RMP.KEY_ALT_I)
RMP.KEY_ALT_J = RMP.enum(); RMP.KeyMap:put("<A-j>", RMP.KEY_ALT_J)
RMP.KEY_ALT_K = RMP.enum(); RMP.KeyMap:put("<A-k>", RMP.KEY_ALT_K)
RMP.KEY_ALT_L = RMP.enum(); RMP.KeyMap:put("<A-l>", RMP.KEY_ALT_L)
RMP.KEY_ALT_M = RMP.enum(); RMP.KeyMap:put("<A-m>", RMP.KEY_ALT_M)
RMP.KEY_ALT_N = RMP.enum(); RMP.KeyMap:put("<A-n>", RMP.KEY_ALT_N)
RMP.KEY_ALT_O = RMP.enum(); RMP.KeyMap:put("<A-o>", RMP.KEY_ALT_O)
RMP.KEY_ALT_P = RMP.enum(); RMP.KeyMap:put("<A-p>", RMP.KEY_ALT_P)
RMP.KEY_ALT_Q = RMP.enum(); RMP.KeyMap:put("<A-q>", RMP.KEY_ALT_Q)
RMP.KEY_ALT_R = RMP.enum(); RMP.KeyMap:put("<A-r>", RMP.KEY_ALT_R)
RMP.KEY_ALT_S = RMP.enum(); RMP.KeyMap:put("<A-s>", RMP.KEY_ALT_S)
RMP.KEY_ALT_T = RMP.enum(); RMP.KeyMap:put("<A-t>", RMP.KEY_ALT_T)
RMP.KEY_ALT_U = RMP.enum(); RMP.KeyMap:put("<A-u>", RMP.KEY_ALT_U)
RMP.KEY_ALT_V = RMP.enum(); RMP.KeyMap:put("<A-v>", RMP.KEY_ALT_V)
RMP.KEY_ALT_W = RMP.enum(); RMP.KeyMap:put("<A-w>", RMP.KEY_ALT_W)
RMP.KEY_ALT_X = RMP.enum(); RMP.KeyMap:put("<A-x>", RMP.KEY_ALT_X)
RMP.KEY_ALT_Y = RMP.enum(); RMP.KeyMap:put("<A-y>", RMP.KEY_ALT_Y)
RMP.KEY_ALT_Z = RMP.enum(); RMP.KeyMap:put("<A-z>", RMP.KEY_ALT_Z)

RMP.KEY_ENTER = RMP.enum(); RMP.KeyMap:put("<Enter>", RMP.KEY_ENTER)
RMP.KEY_SPACE = RMP.enum(); RMP.KeyMap:put("<Space>", RMP.KEY_SPACE)
RMP.KEY_ESCAPE = RMP.enum(); RMP.KeyMap:put("<Escape>", RMP.KEY_ESCAPE)
RMP.KEY_UP = RMP.enum(); RMP.KeyMap:put("<Up>", RMP.KEY_UP)
RMP.KEY_DOWN = RMP.enum(); RMP.KeyMap:put("<Down>", RMP.KEY_DOWN)
RMP.KEY_LEFT = RMP.enum(); RMP.KeyMap:put("<Left>", RMP.KEY_LEFT)
RMP.KEY_RIGHT = RMP.enum(); RMP.KeyMap:put("<Right>", RMP.KEY_RIGHT)
RMP.KEY_TAB = RMP.enum(); RMP.KeyMap:put("<Tab>", RMP.KEY_TAB)
RMP.KEY_DELETE = RMP.enum(); RMP.KeyMap:put("<Delete>", RMP.KEY_DELETE)
RMP.KEY_HOME = RMP.enum(); RMP.KeyMap:put("<Home>", RMP.KEY_HOME)
RMP.KEY_END = RMP.enum(); RMP.KeyMap:put("<End>", RMP.KEY_END)
RMP.KEY_BACKSPACE = RMP.enum(); RMP.KeyMap:put("<Backspace>", RMP.KEY_BACKSPACE)

RMP.KEY_F1 = RMP.enum(); RMP.KeyMap:put("<F1>", RMP.KEY_F1)
RMP.KEY_F2 = RMP.enum(); RMP.KeyMap:put("<F2>", RMP.KEY_F2)
RMP.KEY_F3 = RMP.enum(); RMP.KeyMap:put("<F3>", RMP.KEY_F3)
RMP.KEY_F4 = RMP.enum(); RMP.KeyMap:put("<F4>", RMP.KEY_F4)
RMP.KEY_F5 = RMP.enum(); RMP.KeyMap:put("<F5>", RMP.KEY_F5)
RMP.KEY_F6 = RMP.enum(); RMP.KeyMap:put("<F6>", RMP.KEY_F6)
RMP.KEY_F7 = RMP.enum(); RMP.KeyMap:put("<F7>", RMP.KEY_F7)
RMP.KEY_F8 = RMP.enum(); RMP.KeyMap:put("<F8>", RMP.KEY_F8)
RMP.KEY_F9 = RMP.enum(); RMP.KeyMap:put("<F9>", RMP.KEY_F9)
RMP.KEY_F10 = RMP.enum(); RMP.KeyMap:put("<F10>", RMP.KEY_F10)
RMP.KEY_F11 = RMP.enum(); RMP.KeyMap:put("<F11>", RMP.KEY_F11)
RMP.KEY_F12 = RMP.enum(); RMP.KeyMap:put("<F12>", RMP.KEY_F12)

RMP.KEY_A = RMP.enum(); RMP.KeyMap:put("a", RMP.KEY_A)
RMP.KEY_B = RMP.enum(); RMP.KeyMap:put("b", RMP.KEY_B)
RMP.KEY_C = RMP.enum(); RMP.KeyMap:put("c", RMP.KEY_C)
RMP.KEY_D = RMP.enum(); RMP.KeyMap:put("d", RMP.KEY_D)
RMP.KEY_E = RMP.enum(); RMP.KeyMap:put("e", RMP.KEY_E)
RMP.KEY_F = RMP.enum(); RMP.KeyMap:put("f", RMP.KEY_F)
RMP.KEY_G = RMP.enum(); RMP.KeyMap:put("g", RMP.KEY_G)
RMP.KEY_H = RMP.enum(); RMP.KeyMap:put("h", RMP.KEY_H)
RMP.KEY_I = RMP.enum(); RMP.KeyMap:put("i", RMP.KEY_I)
RMP.KEY_J = RMP.enum(); RMP.KeyMap:put("j", RMP.KEY_J)
RMP.KEY_K = RMP.enum(); RMP.KeyMap:put("k", RMP.KEY_K)
RMP.KEY_L = RMP.enum(); RMP.KeyMap:put("l", RMP.KEY_L)
RMP.KEY_M = RMP.enum(); RMP.KeyMap:put("m", RMP.KEY_M)
RMP.KEY_N = RMP.enum(); RMP.KeyMap:put("n", RMP.KEY_N)
RMP.KEY_O = RMP.enum(); RMP.KeyMap:put("o", RMP.KEY_O)
RMP.KEY_P = RMP.enum(); RMP.KeyMap:put("p", RMP.KEY_P)
RMP.KEY_Q = RMP.enum(); RMP.KeyMap:put("q", RMP.KEY_Q)
RMP.KEY_R = RMP.enum(); RMP.KeyMap:put("r", RMP.KEY_R)
RMP.KEY_S = RMP.enum(); RMP.KeyMap:put("s", RMP.KEY_S)
RMP.KEY_T = RMP.enum(); RMP.KeyMap:put("t", RMP.KEY_T)
RMP.KEY_U = RMP.enum(); RMP.KeyMap:put("u", RMP.KEY_U)
RMP.KEY_V = RMP.enum(); RMP.KeyMap:put("v", RMP.KEY_V)
RMP.KEY_W = RMP.enum(); RMP.KeyMap:put("w", RMP.KEY_W)
RMP.KEY_X = RMP.enum(); RMP.KeyMap:put("x", RMP.KEY_X)
RMP.KEY_Y = RMP.enum(); RMP.KeyMap:put("y", RMP.KEY_Y)
RMP.KEY_Z = RMP.enum(); RMP.KeyMap:put("z", RMP.KEY_Z)

RMP.KEY_SHIFT_A = RMP.enum(); RMP.KeyMap:put("A", RMP.KEY_SHIFT_A)
RMP.KEY_SHIFT_B = RMP.enum(); RMP.KeyMap:put("B", RMP.KEY_SHIFT_B)
RMP.KEY_SHIFT_C = RMP.enum(); RMP.KeyMap:put("C", RMP.KEY_SHIFT_C)
RMP.KEY_SHIFT_D = RMP.enum(); RMP.KeyMap:put("D", RMP.KEY_SHIFT_D)
RMP.KEY_SHIFT_E = RMP.enum(); RMP.KeyMap:put("E", RMP.KEY_SHIFT_E)
RMP.KEY_SHIFT_F = RMP.enum(); RMP.KeyMap:put("F", RMP.KEY_SHIFT_F)
RMP.KEY_SHIFT_G = RMP.enum(); RMP.KeyMap:put("G", RMP.KEY_SHIFT_G)
RMP.KEY_SHIFT_H = RMP.enum(); RMP.KeyMap:put("H", RMP.KEY_SHIFT_H)
RMP.KEY_SHIFT_I = RMP.enum(); RMP.KeyMap:put("I", RMP.KEY_SHIFT_I)
RMP.KEY_SHIFT_J = RMP.enum(); RMP.KeyMap:put("J", RMP.KEY_SHIFT_J)
RMP.KEY_SHIFT_K = RMP.enum(); RMP.KeyMap:put("K", RMP.KEY_SHIFT_K)
RMP.KEY_SHIFT_L = RMP.enum(); RMP.KeyMap:put("L", RMP.KEY_SHIFT_L)
RMP.KEY_SHIFT_M = RMP.enum(); RMP.KeyMap:put("M", RMP.KEY_SHIFT_M)
RMP.KEY_SHIFT_N = RMP.enum(); RMP.KeyMap:put("N", RMP.KEY_SHIFT_N)
RMP.KEY_SHIFT_O = RMP.enum(); RMP.KeyMap:put("O", RMP.KEY_SHIFT_O)
RMP.KEY_SHIFT_P = RMP.enum(); RMP.KeyMap:put("P", RMP.KEY_SHIFT_P)
RMP.KEY_SHIFT_Q = RMP.enum(); RMP.KeyMap:put("Q", RMP.KEY_SHIFT_Q)
RMP.KEY_SHIFT_R = RMP.enum(); RMP.KeyMap:put("R", RMP.KEY_SHIFT_R)
RMP.KEY_SHIFT_S = RMP.enum(); RMP.KeyMap:put("S", RMP.KEY_SHIFT_S)
RMP.KEY_SHIFT_T = RMP.enum(); RMP.KeyMap:put("T", RMP.KEY_SHIFT_T)
RMP.KEY_SHIFT_U = RMP.enum(); RMP.KeyMap:put("U", RMP.KEY_SHIFT_U)
RMP.KEY_SHIFT_V = RMP.enum(); RMP.KeyMap:put("V", RMP.KEY_SHIFT_V)
RMP.KEY_SHIFT_W = RMP.enum(); RMP.KeyMap:put("W", RMP.KEY_SHIFT_W)
RMP.KEY_SHIFT_X = RMP.enum(); RMP.KeyMap:put("X", RMP.KEY_SHIFT_X)
RMP.KEY_SHIFT_Y = RMP.enum(); RMP.KeyMap:put("Y", RMP.KEY_SHIFT_Y)
RMP.KEY_SHIFT_Z = RMP.enum(); RMP.KeyMap:put("Z", RMP.KEY_SHIFT_Z)

RMP.KEY_0 = RMP.enum(); RMP.KeyMap:put("0", RMP.KEY_0)
RMP.KEY_1 = RMP.enum(); RMP.KeyMap:put("1", RMP.KEY_1)
RMP.KEY_2 = RMP.enum(); RMP.KeyMap:put("2", RMP.KEY_2)
RMP.KEY_3 = RMP.enum(); RMP.KeyMap:put("3", RMP.KEY_3)
RMP.KEY_4 = RMP.enum(); RMP.KeyMap:put("4", RMP.KEY_4)
RMP.KEY_5 = RMP.enum(); RMP.KeyMap:put("5", RMP.KEY_5)
RMP.KEY_6 = RMP.enum(); RMP.KeyMap:put("6", RMP.KEY_6)
RMP.KEY_7 = RMP.enum(); RMP.KeyMap:put("7", RMP.KEY_7)
RMP.KEY_8 = RMP.enum(); RMP.KeyMap:put("8", RMP.KEY_8)
RMP.KEY_9 = RMP.enum(); RMP.KeyMap:put("9", RMP.KEY_9)

RMP.KEY_PLUS = RMP.enum(); RMP.KeyMap:put("+", RMP.KEY_PLUS)
RMP.KEY_MINUS = RMP.enum(); RMP.KeyMap:put("-", RMP.KEY_MINUS)
RMP.KEY_GT = RMP.enum(); RMP.KeyMap:put(">", RMP.KEY_GT)
RMP.KEY_LT = RMP.enum(); RMP.KeyMap:put("<", RMP.KEY_LT)
RMP.KEY_HASHTAG = RMP.enum(); RMP.KeyMap:put("#", RMP.KEY_HASHTAG)
RMP.KEY_DOLAR = RMP.enum(); RMP.KeyMap:put("$", RMP.KEY_DOLAR)
RMP.KEY_PERSANT = RMP.enum(); RMP.KeyMap:put("%", RMP.KEY_PERSANT)
RMP.KEY_STAR = RMP.enum(); RMP.KeyMap:put("*", RMP.KEY_STAR)
RMP.KEY_DOT = RMP.enum(); RMP.KeyMap:put(".", RMP.KEY_DOT)
RMP.KEY_UNDERS = RMP.enum(); RMP.KeyMap:put("_", RMP.KEY_UNDERS)
RMP.KEY_SEMICOL = RMP.enum(); RMP.KeyMap:put(";", RMP.KEY_SEMICOL)
RMP.KEY_QUISTION_MARK = RMP.enum(); RMP.KeyMap:put("?", RMP.KEY_QUISTION_MARK)
RMP.KEY_AT = RMP.enum(); RMP.KeyMap:put("@", RMP.KEY_AT)
RMP.KEY_OPEN_CURLY_BRACKET = RMP.enum(); RMP.KeyMap:put("{", RMP.KEY_OPEN_CURLY_BRACKET)
RMP.KEY_CLOSED_CURLY_BRACKET = RMP.enum(); RMP.KeyMap:put("}", RMP.KEY_CLOSED_CURLY_BRACKET)
RMP.KEY_BACK_SLASH = RMP.enum(); RMP.KeyMap:put("\\", RMP.KEY_BACK_SLASH)
RMP.KEY_BACKTICK = RMP.enum(); RMP.KeyMap:put("`", RMP.KEY_BACKTICK)
RMP.KEY_OPEN_BRAKET = RMP.enum(); RMP.KeyMap:put("[", RMP.KEY_OPEN_BRAKET)
RMP.KEY_CLOSED_BRAKET = RMP.enum(); RMP.KeyMap:put("]", RMP.KEY_CLOSED_BRAKET)
RMP.KEY_BAR = RMP.enum(); RMP.KeyMap:put("|", RMP.KEY_BAR)
RMP.KEY_DBL_QUOTE = RMP.enum(); RMP.KeyMap:put('"', RMP.KEY_DBL_QUOTE)
RMP.KEY_SINGLE_QUOTE = RMP.enum(); RMP.KeyMap:put("'", RMP.KEY_SINGLE_QUOTE)
RMP.KEY_SLASH = RMP.enum(); RMP.KeyMap:put("/", RMP.KEY_SLASH)
RMP.KEY_COLON = RMP.enum(); RMP.KeyMap:put(":", RMP.KEY_COLON)
RMP.KEY_COMMA = RMP.enum(); RMP.KeyMap:put(",", RMP.KEY_COMMA)
RMP.KEY_OPEN_PAERN = RMP.enum(); RMP.KeyMap:put("(", RMP.KEY_OPEN_PAERN)
RMP.KEY_CLOSED_PAREN = RMP.enum(); RMP.KeyMap:put(")", RMP.KEY_CLOSED_PAREN)
RMP.KEY_EQUAL = RMP.enum(); RMP.KeyMap:put("=", RMP.KEY_EQUAL)
RMP.NONE = RMP.enum(); RMP.KeyMap:put("<None>", RMP.NONE)

--- TODO: !
--- TODO: &
--- TODO: ^

--- @class rmp.rmp.Window
RMP.Window = OOP.class("Window")
do -- creating window
    -- callback function accept 4 agrs

    --- @generic T
    --- @param id T
    --- @param vterm VirtualTerminal
    --- @return self
    function RMP.Window:constructor(id, vterm)
        self.id = id
        --- @diagnostic disable-next-line
        self.vterm = vterm or RMP.VirtualTerminal.new()
        return self
    end

    --- @generic T
    --- @param id T
    --- @return self
    function RMP.Window:setId(id)
        self.id = id
        return self
    end

    --- @generic T
    --- @return T
    function RMP.Window:getId()
        return self.id
    end

    --- @generic T
    --- @param title Text | string
    --- @param width integer
    --- @param height integer
    --- @param x integer
    --- @param y integer
    --- @param border_color FGColors
    --- @param background_color BGColors
    --- @param border_style T
    --- @param callback function
    --- @return VirtualTerminal | nil
    function RMP.Window:createWindow(
        title
        , width
        , height
        , x
        , y
        , border_color
        , background_color
        , border_style
        , callback)
        local vterm = self.vterm

        if not width and not height and not x and not y then
            return nil
        end

        vterm:drawBox(title, math.floor(x), math.floor(y), math.floor(width), math.floor(height), border_style,
            border_color, background_color)

        if callback ~= nil and type(callback) == "function" then
            local lvt = callback(math.floor(x + 1), math.floor(y + 1), math.floor(x + width - 1),
                math.floor(y + height - 1))
            if lvt ~= nil then
                vterm:merge(lvt, true) -- handle async
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

-- EventType used to define the type of event
-- each plugin can add event listener for a specific event type
-- and when the event is triggered the callback function is called
-- TODO: rename it to TunnelType
--- @enum EventType
RMP.EventType = {
    -- TODO: add event special for audio engine , for better controle
    --- @type integer
    Keyboard = RMP.enum(true), -- this Keyboard event's for actions

    -- Input Event lazem tkon kayn condition to add the Event each time we called a plugin wich means ida makanch kayen had event
    -- nkmlo fl events lokhrin and that't it
    -- also this Input Event should used it in Input class Only so when we initialize the Input and start read from user we add this event to the EventListener
    --- @type integer
    Focuse = RMP.enum(), -- Input event disbale listinnig other Events because the user is writing something
    --- @type integer
    Mouse = RMP.enum(),  -- mouse event
    -- transform data event is the way to handle data transformation between two plugins
    -- TODO: factor Get and Put
    -- Transform = {
    --	Get = RMP.enum(),
    --	Put = RMP.enum()
    -- }
    --- @type integer
    TransformDataGet = RMP.enum(), -- Get data event is used to get data from another plugin
    --- @type integer
    TransformDataPut = RMP.enum(), -- Put data event is used to put data to another plugin
    -- sound
    --- @type integer
    Sound = RMP.enum(), -- plugins can add event for sound
    -- the callback function accept sound object so they can add or get informations like freqs , so they can create visualization
    --- @type integer
    Configuration = RMP.enum(), -- get access to the configurations also save a new configuration (cfg for plugins)
    --- @type integer
    Template = RMP.enum(),      -- Template Event to apply changes to the template
    -- TODO: add data freq table tunnel to access it
    --- @type integer
    DataFreq = RMP.enum(),
    -- TODO: add on exit event
    --- @type integer
    Exit = RMP.enum()
}

--- @interface Event
local Event = OOP.interface("Event",
    "addEventListener"
)

-- EventListener class used to handle events
-- each plugin should have his own EventListener object
-- so when the plugin is initialized it create his own EventListener object
-- and add event listener for the events he want to listen to
-- when the event is triggered the callback function is called
--- @class rmp.rmp.EventListener
RMP.EventListener = OOP.class("EventListener", nil, Event)
do
    --- @return self
    function RMP.EventListener:constructor()
        self.events = HashMap.new()
        self.events:put(RMP.EventType.Keyboard, Queue.new())
        self.events:put(RMP.EventType.Mouse, Queue.new())
        self.events:put(RMP.EventType.Focuse, Queue.new())

        self.events:put(RMP.EventType.TransformDataGet, Queue.new())
        self.events:put(RMP.EventType.TransformDataPut, Queue.new())

        self.events:put(RMP.EventType.Sound, Queue.new())

        self.events:put(RMP.EventType.Configuration, Queue.new())

        self.events:put(RMP.EventType.Template, Queue.new())

        -- callback : fun(data)
        self.events:put(RMP.EventType.DataFreq, Queue.new())

        self.events:put(RMP.EventType.Exit, Queue.new())

        return self
    end

    --- @overload fun(p1 : integer , p2 : function ) : EventListener | nil
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

    function RMP.EventListener:useTunnel(event, callback)
        return self:addEventListener(event, callback)
    end

    function RMP.EventListener:onExit(callback)
        self:addEventListener(RMP.EventType.Exit, callback)
    end

    function RMP.EventListener:onDataGet(callback)
        self:useTunnel(RMP.EventType.TransformDataGet, callback)
    end

    function RMP.EventListener:onDataPut(callback)
        self:useTunnel(RMP.EventType.TransformDataPut, callback)
    end

    function RMP.EventListener:onDataFreq(callback)
        --- @diagnostic disable-next-line
        return self:addEventListener(RMP.EventType.DataFreq, callback)
    end

    --- @param callback function
    function RMP.EventListener:onSound(callback)
        --- @diagnostic disable-next-line
        return self:addEventListener(RMP.EventType.Sound, callback)
    end

    --- @param callback function
    function RMP.EventListener:onKeyboard(callback)
        --- @diagnostic disable-next-line
        return self:addEventListener(RMP.EventType.Keyboard, callback)
    end

    --- @param callback function
    function RMP.EventListener:onMouse(callback)
        --- @diagnostic disable-next-line
        return self:addEventListener(RMP.EventType.Mouse, callback)
    end

    --- @param callback function
    function RMP.EventListener:onFocuse(callback)
        --- @diagnostic disable-next-line
        return self:addEventListener(RMP.EventType.Focuse, callback)
    end

    --- @param callback function
    function RMP.EventListener:onConfiguration(callback)
        --- @diagnostic disable-next-line
        return self:addEventListener(RMP.EventType.Configuration, callback)
    end

    --- @param callback function
    function RMP.EventListener:onTemplate(callback)
        --- @diagnostic disable-next-line
        return self:addEventListener(RMP.EventType.Template, callback)
    end

    --- @param key integer
    --- @param mouse nil
    --- @param sound Sound
    --- @param config HashMap
    --- @param template table
    --- @return self | nil
    function RMP.EventListener:handleEvent(key, mouse, sound, config, template, frame, datafreq, exit)
        local _template = self.events:get(RMP.EventType.Template)
        while not _template:isEmpty() do
            local template_callback = _template:pop()
            if template_callback and type(template_callback) == 'function' then
                template_callback(template)
            end
        end

        if exit then
            local ext = self.events:get(RMP.EventType.Exit)
            while not ext:isEmpty() do
                local extCallback = ext:pop()
                if extCallback and type(extCallback) == 'function' then
                    extCallback()
                end
            end
        end

        local dataFreqQueue = self.events:get(RMP.EventType.DataFreq)
        while not dataFreqQueue:isEmpty() do
            local dataFreqCallback = dataFreqQueue:pop()
            if dataFreqCallback and type(dataFreqCallback) == 'function' then
                dataFreqCallback(datafreq)
            end
        end

        local cfgs_queue = self.events:get(RMP.EventType.Configuration)
        while not cfgs_queue:isEmpty() do
            local cfg_callback = cfgs_queue:pop()
            if cfg_callback and type(cfg_callback) == 'function' then
                cfg_callback(config)
            end
        end

        local put_queue = self.events:get(RMP.EventType.TransformDataPut)
        local get_queue = self.events:get(RMP.EventType.TransformDataGet)

        while not put_queue:isEmpty() do
            local put_callback = put_queue:pop()
            local store_get_queue = Queue.new()

            while not get_queue:isEmpty() do
                local get_callback = get_queue:pop()
                --- @diagnostic disable-next-line
                if put_callback and type(put_callback) == 'function' and
                    get_callback and type(get_callback) == 'function' then
                    local data = put_callback()
                    get_callback(data)
                end
                store_get_queue:push(get_callback)
            end
            get_queue = store_get_queue
        end

        local sound_queue = self.events:get(RMP.EventType.Sound)
        while not sound_queue:isEmpty() do
            local tha_callback = sound_queue:pop()
            if tha_callback and type(tha_callback) == 'function' then
                tha_callback(sound)
            end
        end

        if not key then
            local kq = self.events:get(RMP.EventType.Keyboard)
            while not kq:isEmpty() do
                kq:pop()
            end
            local fq = self.events:get(RMP.EventType.Focuse)
            while not fq:isEmpty() do
                fq:pop()
            end
        end

        if not mouse then
            local mq = self.events:get(RMP.EventType.Mouse)
            while not mq:isEmpty() do
                mq:pop()
            end
        end

        --- @diagnostic disable-next-line
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

        --- @diagnostic disable-next-line
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

    --- @return HashMap
    function RMP.EventListener:getEvent()
        return self.events
    end
end

-- all components should return VirtualTerminal obj
-- VirtualTerminal class used to create a virtual terminal
-- each plugin should have his own VirtualTerminal object
-- so when the plugin is initialized it create his own VirtualTerminal object
-- and draw on it
--- @class rmp.rmp.VirtualTerminal
RMP.VirtualTerminal = OOP.class("VirtualTerminal", RMP.EventListener, RMP.Renderable)
do -- VirtualTerminal
    --- @param width integer
    --- @param height integer
    --- @return  self
    function RMP.VirtualTerminal:constructor(width, height) -- constructor
        -- super method is coming from the class it self
        -- and it used to access the methods from mother class
        --- @diagnostic disable-next-line
        self:super("constructor")

        self.h, self.w = window.get_size()

        self.realWidth = width or self.w
        self.realHeight = height or self.h

        self.native_vt_rmp = vt_rmp.init(self.realWidth, self.realHeight)

        self.cursor = { x = 1, y = 1 }

        -- NOTE: style attr used for effects class
        -- TODO: ak 3aref ;)
        self.style = nil

        self:clear()

        if false then
            local file, _ = io.open("/home/rayden/prog/github/raymp_test", "a")
            if file then
                file:write("initialized\n")
            end
        end

        return self
    end

    ---get cursor
    ---@return table
    function RMP.VirtualTerminal:getCursor()
        return self.cursor
    end

    function RMP.VirtualTerminal:clear()
        -- self.events:clear()
        vt_rmp.clear(self.native_vt_rmp)
    end

    --- @param x integer | nil
    --- @param y integer | nil
    --- @param char string | nil
    --- @param fg FGColors | nil
    --- @param bg BGColors | nil
    --- @param style TextStyle | nil
    --- @return self
    function RMP.VirtualTerminal:setChar(x, y, char, fg, bg, style)
        x = x or self.cursor.x
        y = y or self.cursor.y
        vt_rmp.setchar(self.native_vt_rmp, x, y, char, fg, bg, style)
        return self
    end

    --- @param x integer
    --- @param y integer
    --- @param text string
    --- @param width integer
    --- @param fg FGColors | nil
    --- @param bg BGColors | nil
    --- @param style TextStyle | nil
    --- @return VirtualTerminal | nil
    function RMP.VirtualTerminal:writeTextClipped(x, y, text, width, fg, bg, style)
        if not text then
            return nil
        end
        x = math.floor(x or self.cursor.x)
        y = math.floor(y or self.cursor.y)
        vt_rmp.writetext_clipped(self.native_vt_rmp, x, y, text, width, fg, bg, style)
        return self
    end

    --- @param x integer
    --- @param y integer
    --- @param text string | nil
    --- @param fg FGColors | nil | string
    --- @param bg BGColors | nil | string
    --- @param style TextStyle | nil
    --- @return VirtualTerminal | nil
    function RMP.VirtualTerminal:writeText(x, y, text, fg, bg, style)
        if not text then
            return nil
        end
        x = math.floor(x or self.cursor.x)
        y = math.floor(y or self.cursor.y)
        vt_rmp.writetext(self.native_vt_rmp, x, y, text, fg, bg, style)
        return self
    end

    if true then
        --- @param title string | Text | nil
        --- @param x integer
        --- @param y integer
        --- @param width integer
        --- @param height integer
        --- @param border_style BoxDrawing
        --- @param fg FGColors | nil | string
        --- @param bg BGColors | nil | string
        function RMP.VirtualTerminal:drawBox(title, x, y, width, height, border_style, fg, bg)
            x                 = math.floor(x or 1)
            y                 = math.floor(y or 1)
            width             = math.floor(width or 80)
            height            = math.floor(height or 24)
            local isTextClass = false
            local Tfg         = nil
            local Tbg         = nil
            local Tstyl       = nil
            local titleText   = ""
            --- @diagnostic disable-next-line
            if title and type(title) == "table" and title:instanceOf(RMP.Text) then
                Tfg = title:getFGColor()
                Tbg = title:getBGColor()
                Tstyl = title:getStyle()
                titleText = title:getText()
                isTextClass = true
            elseif title and type(title) == "string" then
                title = title
            else
                title = ""
            end
            if isTextClass then
                vt_rmp.draw_box(self.native_vt_rmp, "", x, y, width, height, border_style, fg, bg)
                self:writeText(math.floor(x + (width / 2) - (#titleText / 2)), y, titleText, Tfg, Tbg, Tstyl)
            else
                vt_rmp.draw_box(self.native_vt_rmp, title, x, y, width, height, border_style, fg, bg)
            end
        end
    else
        --- NOTE: disabled lua implementation just in case
        --- @param title string | Text
        --- @param x integer
        --- @param y integer
        --- @param width integer
        --- @param height integer
        --- @param border_style BoxDrawing
        --- @param fg FGColors | nil | string
        --- @param bg BGColors | nil | string
        function RMP.VirtualTerminal:drawBox(title, x, y, width, height, border_style, fg, bg)
            x        = math.floor(x or 1)
            y        = math.floor(y or 1)
            width    = math.floor(width or 80)
            height   = math.floor(height or 24)

            local TL = nil
            local TR = nil
            local BL = nil
            local BR = nil
            local H  = nil
            local V  = nil

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

            self:writeText(x, y, TL .. string.rep(H, end_x - x - 1) .. TR, fg, bg)
            self:writeText(x, end_y, BL .. string.rep(H, end_x - x - 1) .. BR, fg, bg)
            for i = y + 1, end_y - 1 do
                self:writeText(x, i, V, fg, bg)
                self:writeText(end_x, i, V, fg, bg)
            end
            for i = y + 1, end_y - 1 do
                self:writeText(x + 1, i, string.rep(" ", end_x - x - 1), nil, bg)
            end

            --- @type string
            local title_text = ""
            local title_fg = nil
            local title_bg = nil
            local title_style = nil
            --- @diagnostic disable-next-line
            if title and type(title) == "table" and title:instanceOf(RMP.Text) then
                --- @diagnostic disable-next-line
                title_text = title:getText()
                title_fg = title:getFGColor()
                title_bg = title:getBGColor()
                title_style = title:getStyle()
            elseif title and type(title) == "string" then
                title_text = title
            end
            local available_width = width - 2
            if #title_text > available_width then
                title_text = title_text:sub(1, available_width)
            end
            local title_x = x + 1 + math.floor((available_width - #title_text) / 2)
            local title_y = y
            --- @diagnostic disable-next-line
            self:writeText(title_x, title_y, title_text, title_fg, title_bg, title_style)

            self.dirty = true
        end
    end
    function RMP.VirtualTerminal:render()
        vt_rmp.render(self.native_vt_rmp)
    end

    --- @param x integer
    --- @param y integer
    function RMP.VirtualTerminal:moveCursor(x, y)
        --- @diagnostic disable-next-line
        if x and y then
            self.cursor.x = math.tointeger(math.floor(x))
            self.cursor.y = math.tointeger(math.floor(y))
            vt_rmp.movecursor(self.native_vt_rmp, math.tointeger(math.floor(x)), math.tointeger(math.floor(y)))
        end
    end

    --- @param y integer
    function RMP.VirtualTerminal:moveUp(y)
        vt_rmp.moveup(self.native_vt_rmp, y or 1)
    end

    --- @param y integer
    function RMP.VirtualTerminal:moveDown(y)
        vt_rmp.movedown(self.native_vt_rmp, y or 1)
    end

    --- @param x integer
    function RMP.VirtualTerminal:moveRight(x)
        vt_rmp.moveright(self.native_vt_rmp, x or 1)
    end

    --- @param x integer
    function RMP.VirtualTerminal:moveLeft(x)
        vt_rmp.moveleft(self.native_vt_rmp, x or 1)
    end

    --- @return integer integer
    function RMP.VirtualTerminal:getSize()
        return vt_rmp.getsize(self.native_vt_rmp)
    end

    --- @param width integer
    --- @param height integer
    function RMP.VirtualTerminal:resize(width, height)
        if width ~= self.w or height ~= self.h then
            vt_rmp.resize(self.native_vt_rmp, width, height)
        end
    end

    --- @return VirtualTerminal
    function RMP.VirtualTerminal:getVT()
        return self.native_vt_rmp
    end

    ---  vt + vt1
    --- similare to  vt:merge(vt1)
    --- local _ = vt + vt1
    --- similare to local _ = vt:merge(vt1)
    --- @param thatTerm VirtualTerminal
    --- @return self
    function RMP.VirtualTerminal:__add(thatTerm)
        -- NOTE: if u want to distroy the terminal just use meger method
        return self:merge(thatTerm)
    end

    -- these methods are used to merge two virtual terminal
    -- if there is no way to pass vterm object to function parameters
    -- so you can merge the other virtual terminal to the main object
    --- @param thatTerm VirtualTerminal
    --- @param distroy boolean | nil
    --- @param offsetX integer | nil
    --- @param offsetY integer | nil
    --- @return self
    function RMP.VirtualTerminal:merge(thatTerm, distroy, offsetX, offsetY)
        if thatTerm == nil then
            return self
        end
        --- @diagnostic disable-next-line
        if thatTerm:instanceOf(RMP.VirtualTerminal) then
            vt_rmp.merge(self.native_vt_rmp, thatTerm:getVT(), offsetX or 0, offsetY or 0)

            --- @diagnostic disable-next-line
            local event = thatTerm:getEvent()
            if event:instanceOf(HashMap) then
                --- @diagnostic disable-next-line
                local myevent = self:getEvent()

                while not event:get(RMP.EventType.Exit):isEmpty() do
                    myevent:get(RMP.EventType.Exit):push(event:get(RMP.EventType.Exit):pop())
                end

                while not event:get(RMP.EventType.DataFreq):isEmpty() do
                    myevent:get(RMP.EventType.DataFreq):push(event:get(RMP.EventType.DataFreq):pop())
                end

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

                while not event:get(RMP.EventType.Configuration):isEmpty() do
                    myevent:get(RMP.EventType.Configuration):push(event:get(RMP.EventType.Configuration):pop())
                end

                while not event:get(RMP.EventType.Template):isEmpty() do
                    myevent:get(RMP.EventType.Template):push(event:get(RMP.EventType.Template):pop())
                end
            end
        else
            --- @diagnostic disable-next-line
            if thatTerm:implements(RMP.Renderable) then
                local vterm = thatTerm:render()
                --- @diagnostic disable-next-line
                if vterm and vterm:instanceOf(RMP.VirtualTerminal) then
                    vt_rmp.merge(self.native_vt_rmp, vterm:getVT(), offsetX or 0, offsetY or 0)
                end
            end
        end
        if distroy then
            thatTerm:distroy()
        end
        return self
    end

    --- @param thoseTerms table
    --- @param distroy boolean
    function RMP.VirtualTerminal:mergeAll(thoseTerms, distroy)
        for i = 1, #thoseTerms do
            self:merge(thoseTerms[i].thatTerm, distroy, thoseTerms[i].offsetX, thoseTerms[i].offsetY)
        end
        return self
    end

    function RMP.VirtualTerminal:copy()
        --- @diagnostic disable-next-line
        local copy = RMP.VirtualTerminal.new()
        vt_rmp.distroy(copy.native_vt_rmp)
        copy.native_vt_rmp = vt_rmp.copy(self.native_vt_rmp)
        return copy
    end

    function RMP.VirtualTerminal:distroy()
        vt_rmp.distroy(self.native_vt_rmp)
    end
end

--- Override the print function to write to the virtual terminal instead of the console
---@param ... any
---@return VirtualTerminal
print = function(...)
    local args = { ... }
    local text = ""
    for _, arg in ipairs(args) do
        text = text .. tostring(arg) .. " "
    end
    return RMP.VirtualTerminal():write(text)
end

RMP.VirtualTerminalEffect = OOP.class("VirtualTerminalEffect", RMP.VirtualTerminal)
do
    function RMP.VirtualTerminalEffect.constructor(self, width, height)
        --- @diagnostic disable-next-line
        self:super("constructor", width, height)
    end
end


-- NOTE: Terminal class uses ansii escape code i need to create shared library to handle terminal for each platform
-- Terminal class used to handle terminal operations

--- @class rmp.rmp.Terminal
RMP.Terminal = OOP.class("Terminal")
do -- Terminal
    function RMP.Terminal:clearWindow()
        io.write("\27[2J")
    end

    --- @deprecated
    function RMP.Terminal:moveTo(x, y)
        if x < 1 then
            x = 1
        elseif y < 1 then
            y = 1
        end
        moveto(x, y)
    end

    --- @deprecated
    function RMP.Terminal:moveUp(x)
        if x < 1 or x == nil then
            x = 1
        end
        io.write("\27[" .. x .. "A");
    end

    --- @deprecated
    function RMP.Terminal:moveDown(x)
        if x == nil or x < 1 then
            x = 1
        end
        io.write("\27[" .. x .. "B");
    end

    --- @deprecated
    function RMP.Terminal:moveLeft(x)
        if x < 1 or x == nil then
            x = 1
        end
        io.write("\27[" .. x .. "D");
    end

    --- @deprecated
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

    --- @param enable boolean
    function RMP.Terminal:rawMode(enable)
        window.raw_mode(enable)
    end

    --- @return integer, integer
    function RMP.Terminal:getSize() -- h,w
        local h, w = window.get_size()
        h = tonumber(h) or 24
        w = tonumber(w) or 80
        return h, w
    end

    -- TODO: make sure that function works on windows
    -- TODO: add this two function to Input class to add more operations to make it easy
    --- @return any
    function RMP.Terminal:handleKey()
        return keyboard.get()
    end

    --- @return any
    function RMP.Terminal:closeKey()
        return keyboard.close()
    end
end

-- Input class used to handle user input
--- @class rmp.rmp.Input
RMP.Input = OOP.class("Input", nil, RMP.Renderable)
do
    --- @param label string
    --- @param x integer
    --- @param y integer
    --- @param width number
    --- @param defaultText string
    --- @param cancelKey integer
    function RMP.Input:constructor(label, x, y, width, defaultText, cancelKey, fg, bg, vterm)
        self.label = label or ""
        self.x = math.max(1, tonumber(x) or 1)
        self.y = math.max(1, tonumber(y) or 1)
        --- @type number
        self.width = math.max(1, tonumber(width) or 10)
        self.text = tostring(defaultText or "")
        --- @type integer
        self.cursor_pos = #self.text + 1
        self.cancelKey = cancelKey or RMP.KEY_ESCAPE
        --- @diagnostic disable-next-line
        self.vterm = vterm or RMP.VirtualTerminal.new()
        self.active = false
        self.submitted = false
        --- @type number
        self.scroll_offset = 0
        --- @type number
        self.max_visible_chars = self.width - #self.label - 3

        self.fg = fg
        self.bg = bg
    end

    --- @param key integer
    function RMP.Input:setCancelKey(key)
        self.cancelKey = key
    end

    --- @return boolean
    function RMP.Input:adjustScroll()
        local visible_width = self.max_visible_chars
        if visible_width <= 0 then
            return false
        end

        if self.cursor_pos - self.scroll_offset > visible_width then
            --- @cast visible_width number
            self.scroll_offset = self.cursor_pos - visible_width
        elseif self.cursor_pos <= self.scroll_offset then
            self.scroll_offset = math.max(0, self.cursor_pos - 1)
        end
        return true
    end

    --- @param key integer
    --- @return string
    function RMP.Input:keyToChar(key)
        --- TODO: use KeyMap instead
        local keyMap = {
            [RMP.KEY_A]                    = "a",
            [RMP.KEY_B]                    = "b",
            [RMP.KEY_C]                    = "c",
            [RMP.KEY_D]                    = "d",
            [RMP.KEY_E]                    = "e",
            [RMP.KEY_F]                    = "f",
            [RMP.KEY_G]                    = "g",
            [RMP.KEY_H]                    = "h",
            [RMP.KEY_I]                    = "i",
            [RMP.KEY_J]                    = "j",
            [RMP.KEY_K]                    = "k",
            [RMP.KEY_L]                    = "l",
            [RMP.KEY_M]                    = "m",
            [RMP.KEY_N]                    = "n",
            [RMP.KEY_O]                    = "o",
            [RMP.KEY_P]                    = "p",
            [RMP.KEY_Q]                    = "q",
            [RMP.KEY_R]                    = "r",
            [RMP.KEY_S]                    = "s",
            [RMP.KEY_T]                    = "t",
            [RMP.KEY_U]                    = "u",
            [RMP.KEY_V]                    = "v",
            [RMP.KEY_W]                    = "w",
            [RMP.KEY_X]                    = "x",
            [RMP.KEY_Y]                    = "y",
            [RMP.KEY_Z]                    = "z",
            [RMP.KEY_0]                    = "0",
            [RMP.KEY_1]                    = "1",
            [RMP.KEY_2]                    = "2",
            [RMP.KEY_3]                    = "3",
            [RMP.KEY_4]                    = "4",
            [RMP.KEY_5]                    = "5",
            [RMP.KEY_6]                    = "6",
            [RMP.KEY_7]                    = "7",
            [RMP.KEY_8]                    = "8",
            [RMP.KEY_9]                    = "9",
            [RMP.KEY_SPACE]                = " ",
            [RMP.KEY_DOT]                  = ".",
            [RMP.KEY_MINUS]                = "-",
            [RMP.KEY_UNDERS]               = "_",
            [RMP.KEY_PLUS]                 = "+",
            [RMP.KEY_STAR]                 = "*",
            [RMP.KEY_SLASH]                = "/",
            [RMP.KEY_BACK_SLASH]           = "\\",
            [RMP.KEY_OPEN_BRAKET]          = "[",
            [RMP.KEY_CLOSED_BRAKET]        = "]",
            [RMP.KEY_OPEN_CURLY_BRACKET]   = "{",
            [RMP.KEY_CLOSED_CURLY_BRACKET] = "}",
            [RMP.KEY_BAR]                  = "|",
            [RMP.KEY_SEMICOL]              = ";",
            [RMP.KEY_DBL_QUOTE]            = "\"",
            [RMP.KEY_SINGLE_QUOTE]         = "'",
            [RMP.KEY_BACKTICK]             = "`",
            [RMP.KEY_HASHTAG]              = "#",
            [RMP.KEY_DOLAR]                = "$",
            [RMP.KEY_PERSANT]              = "%",
            [RMP.KEY_AT]                   = "@",
            [RMP.KEY_GT]                   = ">",
            [RMP.KEY_LT]                   = "<",
            [RMP.KEY_QUISTION_MARK]        = "?",
            [RMP.KEY_COLON]                = ":",
            [RMP.KEY_COMMA]                = ",",
            [RMP.KEY_OPEN_PAERN]           = "(",
            [RMP.KEY_CLOSED_PAREN]         = ")",
            [RMP.KEY_EQUAL]                = "=",
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

    --- @param key integer
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

    --- @overload fun()
    function RMP.Input:render()
        self.vterm:clear()
        self.vterm:writeText(self.x, self.y, self.label, self.fg, self.bg)

        local visible_width = self.max_visible_chars

        local displayText = self.text
        if visible_width > 0 and #displayText > visible_width then
            --- @cast visible_width integer
            displayText = displayText:sub(self.scroll_offset + 1, self.scroll_offset + visible_width)
        end
        --- @diagnostic disable-next-line
        displayText = displayText .. string.rep(" ", math.max(0, visible_width - #displayText))

        self.vterm:writeText(self.x + #self.label, self.y, displayText, self.fg, self.bg)
        --- @diagnostic disable-next-line
        if self.active then
            local cursor_screen_pos = self.cursor_pos - self.scroll_offset
            if cursor_screen_pos > 0 and cursor_screen_pos <= visible_width then
                self.vterm:writeText(
                    self.x + #self.label + cursor_screen_pos - 1, self.y,
                    "_", self.fg, self.bg
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
        --- @diagnostic disable-next-line
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
            RMP.KEY_OPEN_BRAKET, RMP.KEY_CLOSED_BRAKET, RMP.KEY_OPEN_CURLY_BRACKET,
            RMP.KEY_CLOSED_CURLY_BRACKET, RMP.KEY_BAR, RMP.KEY_SEMICOL, RMP.KEY_DBL_QUOTE,
            RMP.KEY_SINGLE_QUOTE, RMP.KEY_BACKTICK, RMP.KEY_HASHTAG,
            RMP.KEY_DOLAR, RMP.KEY_PERSANT, RMP.KEY_AT, RMP.KEY_GT, RMP.KEY_LT,
            RMP.KEY_QUISTION_MARK, RMP.KEY_COLON, RMP.KEY_COMMA, RMP.KEY_OPEN_PAERN,
            RMP.KEY_CLOSED_PAREN, RMP.KEY_EQUAL,
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

    --- @return integer
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

    --- @return boolean
    function RMP.Input:isActive()
        return self.active
    end

    --- @return boolean
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
--- @class rmp.rmp.SimpleInput
RMP.SimpleInput = OOP.class("SimpleInput")
do
    --- @param options table
    --- @return self
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
        self.chr = options.chr or RMP.Bar_100_per

        return self
    end

    function RMP.SimpleInput:render(vterm)
        --- @diagnostic disable-next-line
        if self.active then
            vterm:addEventListener(RMP.EventType.Focuse, function(key)
                self:_handleKey(key)
            end)
        end
        self:_renderField(vterm)

        return self
    end

    --- @return self
    function RMP.SimpleInput:focus()
        self.active = true
        self.show_error = false
        return self
    end

    --- @return self
    function RMP.SimpleInput:blur()
        self.active = false
        return self
    end

    --- @return string
    function RMP.SimpleInput:getValue()
        return self.value
    end

    --- @param value string
    --- @return self
    function RMP.SimpleInput:setValue(value)
        self.value = tostring(value or "")
        self.cursor_pos = #self.value + 1
        return self
    end

    --- @return self
    function RMP.SimpleInput:clear()
        self.value = ""
        self.cursor_pos = 1
        self.show_error = false
        return self
    end

    --- @return boolean
    function RMP.SimpleInput:isActive()
        return self.active
    end

    --- @return boolean
    function RMP.SimpleInput:hasError()
        return self.show_error
    end

    --- @return string
    function RMP.SimpleInput:getError()
        return self.error_message
    end

    --- @private
    --- @param key integer
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

    --- @private
    --- @return boolean
    function RMP.SimpleInput:_submit()
        --- @diagnostic disable-next-line
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

    --- @private
    --- @param char string
    function RMP.SimpleInput:_insertChar(char)
        self.value = self.value:sub(1, self.cursor_pos - 1) .. char .. self.value:sub(self.cursor_pos)
        self.cursor_pos = self.cursor_pos + 1
        self.show_error = false
    end

    --- @private
    function RMP.SimpleInput:_backspace()
        if self.cursor_pos > 1 then
            self.value = self.value:sub(1, self.cursor_pos - 2) .. self.value:sub(self.cursor_pos)
            self.cursor_pos = self.cursor_pos - 1
            self.show_error = false
        end
    end

    --- @private
    function RMP.SimpleInput:_delete()
        if self.cursor_pos <= #self.value then
            self.value = self.value:sub(1, self.cursor_pos - 1) .. self.value:sub(self.cursor_pos + 1)
            self.show_error = false
        end
    end

    --- @private
    function RMP.SimpleInput:_moveCursorLeft()
        if self.cursor_pos > 1 then
            self.cursor_pos = self.cursor_pos - 1
        end
    end

    --- @private
    function RMP.SimpleInput:_moveCursorRight()
        if self.cursor_pos <= #self.value then
            self.cursor_pos = self.cursor_pos + 1
        end
    end

    --- @private
    --- @param key integer
    --- @return string
    function RMP.SimpleInput:_keyToChar(key)
        --- TODO: use KeyMap instead
        local keyMap = {
            [RMP.KEY_A]                    = "a",
            [RMP.KEY_B]                    = "b",
            [RMP.KEY_C]                    = "c",
            [RMP.KEY_D]                    = "d",
            [RMP.KEY_E]                    = "e",
            [RMP.KEY_F]                    = "f",
            [RMP.KEY_G]                    = "g",
            [RMP.KEY_H]                    = "h",
            [RMP.KEY_I]                    = "i",
            [RMP.KEY_J]                    = "j",
            [RMP.KEY_K]                    = "k",
            [RMP.KEY_L]                    = "l",
            [RMP.KEY_M]                    = "m",
            [RMP.KEY_N]                    = "n",
            [RMP.KEY_O]                    = "o",
            [RMP.KEY_P]                    = "p",
            [RMP.KEY_Q]                    = "q",
            [RMP.KEY_R]                    = "r",
            [RMP.KEY_S]                    = "s",
            [RMP.KEY_T]                    = "t",
            [RMP.KEY_U]                    = "u",
            [RMP.KEY_V]                    = "v",
            [RMP.KEY_W]                    = "w",
            [RMP.KEY_X]                    = "x",
            [RMP.KEY_Y]                    = "y",
            [RMP.KEY_Z]                    = "z",
            [RMP.KEY_0]                    = "0",
            [RMP.KEY_1]                    = "1",
            [RMP.KEY_2]                    = "2",
            [RMP.KEY_3]                    = "3",
            [RMP.KEY_4]                    = "4",
            [RMP.KEY_5]                    = "5",
            [RMP.KEY_6]                    = "6",
            [RMP.KEY_7]                    = "7",
            [RMP.KEY_8]                    = "8",
            [RMP.KEY_9]                    = "9",
            [RMP.KEY_SPACE]                = " ",
            [RMP.KEY_DOT]                  = ".",
            [RMP.KEY_MINUS]                = "-",
            [RMP.KEY_UNDERS]               = "_",
            [RMP.KEY_PLUS]                 = "+",
            [RMP.KEY_STAR]                 = "*",
            [RMP.KEY_SLASH]                = "/",
            [RMP.KEY_BACK_SLASH]           = "\\",
            [RMP.KEY_OPEN_BRAKET]          = "[",
            [RMP.KEY_CLOSED_BRAKET]        = "]",
            [RMP.KEY_OPEN_CURLY_BRACKET]   = "{",
            [RMP.KEY_CLOSED_CURLY_BRACKET] = "}",
            [RMP.KEY_BAR]                  = "|",
            [RMP.KEY_SEMICOL]              = ";",
            [RMP.KEY_DBL_QUOTE]            = "\"",
            [RMP.KEY_SINGLE_QUOTE]         = "'",
            [RMP.KEY_BACKTICK]             = "`",
            [RMP.KEY_HASHTAG]              = "#",
            [RMP.KEY_DOLAR]                = "$",
            [RMP.KEY_PERSANT]              = "%",
            [RMP.KEY_AT]                   = "@",
            [RMP.KEY_GT]                   = ">",
            [RMP.KEY_LT]                   = "<",
            [RMP.KEY_QUISTION_MARK]        = "?",
            [RMP.KEY_COLON]                = ":",
            [RMP.KEY_COMMA]                = ",",
            [RMP.KEY_OPEN_PAERN]           = "(",
            [RMP.KEY_CLOSED_PAREN]         = ")",
            [RMP.KEY_EQUAL]                = "=",
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
        local vterm = vterm or RMP.VirtualTerminal()
        --- @diagnostic disable-next-line
        if self.label ~= "" then
            vterm:writeText(self.x, self.y, self.label, self.fg_normal, self.bg_normal)
        end


        local fg = self.active and self.fg_active or self.fg_normal
        local bg = self.active and self.bg_active or self.bg_normal

        --- @diagnostic disable-next-line
        if self.show_error then
            fg = self.fg_error
        end


        local display_value = self.value
        --- @diagnostic disable-next-line
        if display_value == "" and not self.active and self.placeholder ~= "" then
            display_value = self.placeholder
            fg = RMP.FGColors.NoBrights.White
        end


        local field_content = display_value .. string.rep(" ", math.max(0, self.width - #display_value))
        local field_x = self.x + #self.label

        vterm:writeText(field_x, self.y, field_content, fg, bg)


        --- @diagnostic disable-next-line
        if self.active then
            local cursor_x = field_x + self.cursor_pos - 1
            vterm:writeText(cursor_x, self.y, self.chr, self.fg_normal, bg)
        end


        --- @diagnostic disable-next-line
        if self.show_error and self.error_message ~= "" then
            vterm:writeText(self.x, self.y + 1, self.error_message, self.fg_error, self.bg_normal)
        end
    end
end

--- @param options table
function RMP.input(options)
    options = options or {}
    local message = options.message or "Enter value:"
    local default = options.default or ""
    local validator = options.validator

    -- This would be implemented as a blocking dialog
    -- For now, return a simple input component
    --- @diagnostic disable-next-line
    return RMP.SimpleInput.new({
        label = message,
        value = default,
        validator = validator,
        width = options.width or 30
    })
end

-- TODO: handle Tables
-- TODO: handle Animation  [loading bar , spinner , progress bar ]
--- @class rmp.rmp.Options
RMP.Options = OOP.class("Options")
do
    --- @param options table
    --- @return self
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

    --- @param value boolean
    --- @return self
    function RMP.Options:setCounter(value)
        self.counter = value
        return self
    end

    --- @param selected string
    --- @param unselected string
    --- @return self
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

    --- @param color BGColors
    --- @return self
    function RMP.Options:setColorFocus(color)
        self.color = color or RMP.Default
        return self
    end

    --- @param symbl string
    --- @return self
    function RMP.Options:setSymblFocus(symbl)
        self.symbl = symbl or ""
        return self
    end

    --- @param options table
    --- @return self
    function RMP.Options:setOptions(options)
        self.options = options or {}
        -- clamp pos
        if #self.options == 0 then
            self.pos = 1
        else
            --- @diagnostic disable-next-line
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

    --- @return table
    function RMP.Options:getOptions()
        return self.options or {}
    end

    -- set visible focus position (absolute index in options array)
    --- @param position integer
    --- @return self
    function RMP.Options:focusPos(position)
        local p = tonumber(position) or 1
        if p < 1 then p = 1 end
        if p > #self.options and #self.options > 0 then p = #self.options end
        --- @cast p integer
        self.pos = p
        return self
    end

    --- @param block boolean
    --- @return self
    function RMP.Options:next(block)
        block = block or false
        if #self.options == 0 then return self end
        if self.pos == #self.options then
            --- @diagnostic disable-next-line
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

    --- @return self
    function RMP.Options:first()
        self.pos = 1
        return self
    end

    --- @return self
    function RMP.Options:last()
        self.pos = math.max(1, #self.options)
        return self
    end

    --- @param block boolean
    --- @return self
    function RMP.Options:prev(block)
        block = block or false
        if #self.options == 0 then return self end
        --- @diagnostic disable-next-line
        if self.pos == 1 then
            --- @diagnostic disable-next-line
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

    --- @return string | nil
    function RMP.Options:getSelected()
        if #self.options == 0 then return nil end
        self.marked_table[self.pos] = not self.marked_table[self.pos]
        -- i think i delete this helper function
        -- TODO: implement cleanTextLocal
        -- return cleanTextLocal(self.options[self.pos])
        --
        return self.options[self.pos]
    end

    -- Returns a table of strings suitable for rendering.
    -- It DOES NOT modify self.options in-place.
    -- inside RMP.Options (replace existing parse)
    --- @return table
    function RMP.Options:parse()
        local forRet = {}
        for i = 1, #self.options do
            local raw = tostring(self.options[i] or "")
            local marked = (self.marked_table and self.marked_table[i]) and true or false

            -- prefix (mark/unmark) shown before the item text (kept plain)
            local prefix = ""
            --- @diagnostic disable-next-line
            if self.mark then
                if marked then prefix = self.selected .. " " else prefix = self.unselected .. " " end
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

--- TODO: implement Draw class in C native code for better performance
--- enhanced draw class using unicode block characters for better resolution
--- uses half-block characters (▀▄█) and quarter-block characters for sub-pixel rendering
--- @class rmp.rmp.Draw
RMP.Draw = OOP.class("Draw")
do -- Draw
    local BLOCK_CHARS  = {
        FULL                = RMP.Bar_100_per, -- "█",
        LOWER_HALF          = RMP.Bar_b_to_u_50_per, -- "▄",
        LEFT_HALF           = RMP.Bar_l_to_r_50_per, -- "▌",

        UPPER_HALF          = "▀", -- TODO: add this block to the api constant
        RIGHT_HALF          = "▐", -- TODO: add this block to the api constant

        UPPER_LEFT          = "▘", -- TODO: add this block to the api constant
        UPPER_RIGHT         = "▝", -- TODO: add this block to the api constant
        LOWER_LEFT          = "▖", -- TODO: add this block to the api constant
        LOWER_RIGHT         = "▗", -- TODO: add this block to the api constant

        LEFT_ONE_EIGHTH     = RMP.Bar_l_to_r_12_5_per, --  "▏",
        LEFT_ONE_QUARTER    = RMP.Bar_l_to_r_25_per, --  "▎",
        LEFT_THREE_EIGHTHS  = RMP.Bar_l_to_r_37_5_per, -- "▍",
        LEFT_FIVE_EIGHTHS   = RMP.Bar_l_to_r_62_5_per, -- "▋",
        LEFT_THREE_QUARTERS = RMP.Bar_l_to_r_75_per, -- "▊",
        LEFT_SEVEN_EIGHTHS  = RMP.Bar_l_to_r_87_5_per, -- "▉",

        LIGHT_SHADE         = RMP.Bar_Shading_25_per, -- "░",
        MEDIUM_SHADE        = RMP.Bar_Shading_50_per, -- "▒",
        DARK_SHADE          = RMP.Bar_Shading_75_per, -- "▓",
    }

    -- braille patterns for high-resolution plotting (8 dots per character)
    -- braille unicode range: u+2800 to u+28ff
    local BRAILLE_BASE = 0x2800

    -- Braille dot positions (standard Braille layout):
    -- 1 4
    -- 2 5
    -- 3 6
    -- 7 8
    local BRAILLE_DOTS = {
        [1] = 0x01,
        [2] = 0x02,
        [3] = 0x04,
        [4] = 0x08,
        [5] = 0x10,
        [6] = 0x20,
        [7] = 0x40,
        [8] = 0x80
    }

    function RMP.Draw:constructor(boolTable)
        self.boolTable = boolTable or {}
        return self
    end

    --- Create a Braille character from dot pattern
    --- @param dots table<integer, boolean> -- dot positions 1-8
    --- @return string
    local function createBrailleChar(dots)
        local value = BRAILLE_BASE
        for i = 1, 8 do
            if dots[i] then
                value = value + BRAILLE_DOTS[i]
            end
        end
        return utf8.char(value)
    end

    ---  Set a pixel in a Braille canvas
    --- @param canvas table -- 2D array of braille dot states
    --- @param x number
    --- @param y number
    local function setBraillePixel(canvas, x, y)
        local char_x = math.floor(x / 2)
        local char_y = math.floor(y / 4)
        local dot_x = x % 2
        local dot_y = y % 4

        canvas[char_y] = canvas[char_y] or {}
        canvas[char_y][char_x] = canvas[char_y][char_x] or {}

        -- Map to Braille dot position
        local dot_index = dot_x * 4 + dot_y + 1
        if dot_index <= 8 then
            canvas[char_y][char_x][dot_index] = true
        end
    end

    --- Helper: Render Braille canvas to VirtualTerminal
    --- @param canvas table
    --- @param vterm VirtualTerminal
    --- @param offset_x integer
    --- @param offset_y integer
    --- @param fg_color? FGColors
    --- @param bg_color? BGColors
    local function renderBrailleCanvas(canvas, vterm, offset_x, offset_y, fg_color, bg_color)
        for char_y, row in pairs(canvas) do
            for char_x, dots in pairs(row) do
                local braille = createBrailleChar(dots)
                vterm:setChar(
                    offset_x + char_x,
                    offset_y + char_y,
                    braille,
                    fg_color,
                    bg_color,
                    nil
                )
            end
        end
    end

    --- Draw a filled rectangle using full block characters
    --- @param x integer
    --- @param y integer
    --- @param width integer
    --- @param height integer
    --- @param color BGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal | nil
    function RMP.Draw:rectangle(x, y, width, height, color, vterm)
        x = math.floor(x or 0)
        y = math.floor(y or 0)
        if not width or not height or width <= 0 or height <= 0 then
            return nil
        end
        width = math.floor(width)
        height = math.floor(height)

        vterm = vterm or RMP.VirtualTerminal()
        vterm:drawBox(nil, x, y, width, height, RMP.BoxDrawing.NoBorder, nil, color)
        return vterm
    end

    --- Draw a high-resolution circle using Braille characters
    --- @param centerX integer
    --- @param centerY integer
    --- @param r integer
    --- @param color FGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal | nil
    function RMP.Draw:circle(centerX, centerY, r, color, vterm)
        r = math.floor(r or 5)
        if r <= 0 then return nil end

        centerX = math.floor(centerX or 0)
        centerY = math.floor(centerY or 0)
        vterm = vterm or RMP.VirtualTerminal()

        -- Use Braille for high-resolution circle
        -- Each character cell is 2x4 pixels in Braille
        local canvas = {}
        local scale = 2 -- Scaling factor for better resolution

        -- Midpoint circle algorithm with sub-pixel precision
        local r_scaled = r * scale
        local cx_scaled = centerX * 2
        local cy_scaled = centerY * 4

        -- Draw filled circle using scanline algorithm
        for y = -r_scaled, r_scaled do
            local half_width = math.sqrt(r_scaled * r_scaled - y * y)
            for x = -half_width, half_width do
                local px = cx_scaled + math.floor(x)
                local py = cy_scaled + math.floor(y)
                setBraillePixel(canvas, px, py)
            end
        end

        renderBrailleCanvas(canvas, vterm, 0, 0, color, nil)
        return vterm
    end

    --- Draw a high-resolution filled circle (alternative using half-blocks)
    --- @param centerX integer
    --- @param centerY integer
    --- @param r integer
    --- @param color BGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal | nil
    function RMP.Draw:circleFilled(centerX, centerY, r, color, vterm)
        r = math.floor(r or 5)
        if r <= 0 then return nil end

        centerX = math.floor(centerX or 0)
        centerY = math.floor(centerY or 0)
        vterm = vterm or RMP.VirtualTerminal()

        -- Use half-block characters for vertical sub-pixel precision
        local r_doubled = r * 2 -- Since we have 2 vertical pixels per cell

        for row = 0, r * 2 do
            local y_top = row - r
            local y_bottom = row - r + 0.5

            -- Calculate horizontal extent at these y positions
            local x_extent_top = 0
            local x_extent_bottom = 0

            if y_top * y_top < r * r then
                x_extent_top = math.sqrt(r * r - y_top * y_top)
            end
            if y_bottom * y_bottom < r * r then
                x_extent_bottom = math.sqrt(r * r - y_bottom * y_bottom)
            end

            local x_extent = math.max(x_extent_top, x_extent_bottom)

            for col = -math.ceil(x_extent), math.ceil(x_extent) do
                local x = col
                local dist_top_sq = x * x + y_top * y_top
                local dist_bottom_sq = x * x + y_bottom * y_bottom

                local top_filled = dist_top_sq <= r * r
                local bottom_filled = dist_bottom_sq <= r * r

                --- @type string|nil
                local char = " "
                if top_filled and bottom_filled then
                    char = BLOCK_CHARS.FULL
                elseif top_filled then
                    char = BLOCK_CHARS.UPPER_HALF
                elseif bottom_filled then
                    char = BLOCK_CHARS.LOWER_HALF
                else
                    char = nil -- Don't draw
                end

                if char then
                    vterm:setChar(
                        centerX + col,
                        centerY + math.floor(row / 2),
                        char,
                        color,
                        nil,
                        nil
                    )
                end
            end
        end

        return vterm
    end

    --- Draw a high-resolution triangle using Braille characters
    --- @param height integer
    --- @param pos_x integer
    --- @param pos_y integer
    --- @param color FGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    function RMP.Draw:triangle(height, pos_x, pos_y, color, vterm)
        vterm = vterm or RMP.VirtualTerminal()
        height = math.floor(height)
        if height <= 0 then return vterm end

        local canvas = {}
        local scale = 2

        -- Draw filled triangle with Braille sub-pixels
        for y = 0, height * 4 do
            local progress = y / (height * 4)
            local half_width = progress * height * 2

            for x = -half_width, half_width do
                local px = (pos_x * 2) + math.floor(x)
                local py = (pos_y * 4) + y
                setBraillePixel(canvas, px, py)
            end
        end

        renderBrailleCanvas(canvas, vterm, 0, 0, color, nil)
        return vterm
    end

    --- Draw a filled triangle using half-block characters
    --- @param height integer
    --- @param pos_x integer
    --- @param pos_y integer
    --- @param color BGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    function RMP.Draw:triangleFilled(height, pos_x, pos_y, color, vterm)
        vterm = vterm or RMP.VirtualTerminal()
        height = math.floor(height)
        if height <= 0 then return vterm end

        -- Use half-blocks for better vertical resolution
        for row = 0, height * 2 do
            local y_top = row / 2
            local y_bottom = (row + 1) / 2

            local width_top = (y_top / height) * height
            local width_bottom = (y_bottom / height) * height

            for col = 0, math.ceil(math.max(width_top, width_bottom) * 2) do
                local x = col / 2 - math.max(width_top, width_bottom)

                local in_top = math.abs(x) <= width_top
                local in_bottom = math.abs(x) <= width_bottom

                --- @type string|nil
                local char = " "
                if in_top and in_bottom then
                    char = BLOCK_CHARS.FULL
                elseif in_top then
                    char = BLOCK_CHARS.UPPER_HALF
                elseif in_bottom then
                    char = BLOCK_CHARS.LOWER_HALF
                else
                    char = nil
                end

                if char then
                    vterm:setChar(
                        pos_x + col - math.ceil(math.max(width_top, width_bottom)),
                        pos_y + math.floor(row / 2),
                        char,
                        color,
                        nil,
                        nil
                    )
                end
            end
        end

        return vterm
    end

    --- Draw a line (horizontal is already optimal)
    --- @param x integer
    --- @param y integer
    --- @param width integer
    --- @param color BGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    function RMP.Draw:line(x, y, width, color, vterm)
        vterm = vterm or RMP.VirtualTerminal()
        if not width or width <= 0 then return vterm end

        x = math.floor(x)
        y = math.floor(y)
        width = math.floor(width)

        for i = x, x + width - 1 do
            vterm:setChar(i, y, " ", nil, color, nil)
        end

        return vterm
    end

    --- Draw a diagonal line using Braille characters
    --- @param x1 integer
    --- @param y1 integer
    --- @param x2 integer
    --- @param y2 integer
    --- @param color FGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    function RMP.Draw:lineDiagonal(x1, y1, x2, y2, color, vterm)
        vterm = vterm or RMP.VirtualTerminal()

        local canvas = {}

        -- Bresenham's line algorithm adapted for Braille
        x1, y1 = x1 * 2, y1 * 4
        x2, y2 = x2 * 2, y2 * 4

        local dx = math.abs(x2 - x1)
        local dy = math.abs(y2 - y1)
        local sx = x1 < x2 and 1 or -1
        local sy = y1 < y2 and 1 or -1
        local err = dx - dy

        while true do
            setBraillePixel(canvas, x1, y1)

            if x1 == x2 and y1 == y2 then break end

            local e2 = 2 * err
            if e2 > -dy then
                err = err - dy
                x1 = x1 + sx
            end
            if e2 < dx then
                err = err + dx
                y1 = y1 + sy
            end
        end

        renderBrailleCanvas(canvas, vterm, 0, 0, color, nil)
        return vterm
    end

    --- Draw a column (vertical line is already optimal)
    --- @param x integer
    --- @param y integer
    --- @param height integer
    --- @param color BGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    function RMP.Draw:column(x, y, height, color, vterm)
        vterm = vterm or RMP.VirtualTerminal()
        if not height or height <= 0 then return vterm end

        x = math.floor(x)
        y = math.floor(y)
        height = math.floor(height)

        for i = y, y + height - 1 do
            vterm:setChar(x, i, " ", nil, color, nil)
        end

        return vterm
    end

    --- Draw an ellipse using Braille characters
    --- @param centerX integer
    --- @param centerY integer
    --- @param radiusX integer
    --- @param radiusY integer
    --- @param color FGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    function RMP.Draw:ellipse(centerX, centerY, radiusX, radiusY, color, vterm)
        vterm = vterm or RMP.VirtualTerminal()
        radiusX = math.floor(radiusX or 5)
        radiusY = math.floor(radiusY or 3)
        if radiusX <= 0 or radiusY <= 0 then return vterm end

        local canvas = {}

        -- Scale for Braille resolution
        centerX = centerX * 2
        centerY = centerY * 4
        radiusX = radiusX * 2
        radiusY = radiusY * 4

        -- Filled ellipse
        for y = -radiusY, radiusY do
            local half_width = radiusX * math.sqrt(1 - (y * y) / (radiusY * radiusY))
            for x = -half_width, half_width do
                setBraillePixel(canvas, centerX + math.floor(x), centerY + y)
            end
        end

        renderBrailleCanvas(canvas, vterm, 0, 0, color, nil)
        return vterm
    end

    --- Draw a polygon using Braille characters
    --- @param points table<table<integer, integer>> -- {{x1, y1}, {x2, y2}, ...}
    --- @param color FGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    function RMP.Draw:polygon(points, color, vterm)
        vterm = vterm or RMP.VirtualTerminal()
        if not points or #points < 3 then return vterm end

        local canvas = {}

        -- Draw edges
        for i = 1, #points do
            local p1 = points[i]
            local p2 = points[i % #points + 1]

            local x1, y1 = p1[1] * 2, p1[2] * 4
            local x2, y2 = p2[1] * 2, p2[2] * 4

            -- Bresenham's line
            local dx = math.abs(x2 - x1)
            local dy = math.abs(y2 - y1)
            local sx = x1 < x2 and 1 or -1
            local sy = y1 < y2 and 1 or -1
            local err = dx - dy

            while true do
                setBraillePixel(canvas, x1, y1)
                if x1 == x2 and y1 == y2 then break end

                local e2 = 2 * err
                if e2 > -dy then
                    err = err - dy
                    x1 = x1 + sx
                end
                if e2 < dx then
                    err = err + dx
                    y1 = y1 + sy
                end
            end
        end

        renderBrailleCanvas(canvas, vterm, 0, 0, color, nil)
        return vterm
    end

    --- Draw a rounded rectangle using mixed characters
    --- @param x integer
    --- @param y integer
    --- @param width integer
    --- @param height integer
    --- @param radius integer
    --- @param color BGColors
    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    function RMP.Draw:roundedRectangle(x, y, width, height, radius, color, vterm)
        vterm = vterm or RMP.VirtualTerminal()
        x = math.floor(x)
        y = math.floor(y)
        width = math.floor(width)
        height = math.floor(height)
        radius = math.floor(radius or 2)

        if width <= 0 or height <= 0 then return vterm end

        -- Draw main rectangle body
        for i = y + radius, y + height - radius - 1 do
            for j = x, x + width - 1 do
                vterm:setChar(j, i, " ", nil, color, nil)
            end
        end

        -- Draw top and bottom strips
        for i = y, y + radius - 1 do
            for j = x + radius, x + width - radius - 1 do
                vterm:setChar(j, i, " ", nil, color, nil)
            end
        end

        for i = y + height - radius, y + height - 1 do
            for j = x + radius, x + width - radius - 1 do
                vterm:setChar(j, i, " ", nil, color, nil)
            end
        end

        -- Draw corners (simplified - could use Braille for smoother curves)
        local corners = {
            { x + radius,             y + radius },              -- top-left
            { x + width - radius - 1, y + radius },              -- top-right
            { x + radius,             y + height - radius - 1 }, -- bottom-left
            { x + width - radius - 1, y + height - radius - 1 }  -- bottom-right
        }

        for _, corner in ipairs(corners) do
            for dy = -radius, radius do
                for dx = -radius, radius do
                    if dx * dx + dy * dy <= radius * radius then
                        vterm:setChar(corner[1] + dx, corner[2] + dy, " ", nil, color, nil)
                    end
                end
            end
        end

        return vterm
    end
end

--- @class rmp.rmp.Scroller
RMP.Scroller = OOP.class("Scroller")
do
    --- @param visible_height number
    --- @param options_obj Options
    --- @return self
    function RMP.Scroller:constructor(visible_height, options_obj)
        self.visible_height = math.max(1, tonumber(visible_height) or 10)
        --- @diagnostic disable-next-line
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

    --- @param options_obj Options
    --- @return self
    function RMP.Scroller:setOptionsObj(options_obj)
        --- @diagnostic disable-next-line
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

    --- @param visible_height number
    --- @return self
    function RMP.Scroller:setHeight(visible_height)
        self.visible_height = math.max(1, tonumber(visible_height) or 10)
        self:_adjustScrollOffset()
        return self
    end

    --- @private
    --- @return nil
    function RMP.Scroller:_adjustScrollOffset()
        local data = self.options:getOptions() or {}
        local total_items = #data

        if total_items == 0 then
            self.scroll_offset = 0
            return nil
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

    --- @return table
    --- @return integer
    --- @return integer
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

    --- @return self
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

    --- @return self
    function RMP.Scroller:prevLine()
        local data = self.options:getOptions() or {}

        if #data == 0 then return self end

        if self.options.pos > 1 then
            self.options.pos = self.options.pos - 1
            self:_adjustScrollOffset()
        end

        return self
    end

    --- @return self
    function RMP.Scroller:nextContent()
        local data = self.options:getOptions() or {}
        local total_items = #data

        if total_items == 0 then return self end

        local target_pos = math.min(total_items, self.options.pos + self.visible_height)
        self.options:focusPos(target_pos)
        self:_adjustScrollOffset()

        return self
    end

    --- @return self
    function RMP.Scroller:prevContent()
        local data = self.options:getOptions() or {}

        if #data == 0 then return self end

        local target_pos = math.max(1, self.options.pos - self.visible_height)
        self.options:focusPos(target_pos)
        self:_adjustScrollOffset()

        return self
    end

    --- @return self
    function RMP.Scroller:toStart()
        local data = self.options:getOptions() or {}

        if #data > 0 then
            self.options:first()
            self:_adjustScrollOffset()
        end

        return self
    end

    --- @return self
    function RMP.Scroller:toEnd()
        local data = self.options:getOptions() or {}

        if #data > 0 then
            self.options:last()
            self:_adjustScrollOffset()
        end

        return self
    end

    --- @return self
    function RMP.Scroller:resetToStart()
        self.scroll_offset = 0
        self.options:first()
        self:_adjustScrollOffset()
        return self
    end

    --- @return integer
    function RMP.Scroller:getCursorPosition()
        return self.options.pos
    end

    --- @return integer
    function RMP.Scroller:getScrollOffset()
        return self.scroll_offset
    end

    --- @return integer
    function RMP.Scroller:getTotalItems()
        local data = self.options:getOptions() or {}
        return #data
    end

    --- @return boolean
    function RMP.Scroller:canScrollUp()
        return self.scroll_offset > 0
    end

    --- @return boolean
    function RMP.Scroller:canScrollDown()
        local data = self.options:getOptions() or {}
        return self.scroll_offset + self.visible_height < #data
    end

    --- @return number
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

--- @enum PlaybackMode
RMP.PlaybackMode = {
    ONCE          = RMP.enum(true),
    LOOP_SINGLE   = RMP.enum(),
    LOOP_PLAYLIST = RMP.enum(),
    SHUFFLE       = RMP.enum()
}

--- @enum State
RMP.State = {
    STOPPED = RMP.enum(true),
    PLAYING = RMP.enum(),
    PAUSED  = RMP.enum(),
    LOADING = RMP.enum(),
    ERROR   = RMP.enum()
}

--- @class rmp.rmp.Sound
RMP.Sound = OOP.class("Sound")
do
    --- @param files table | string
    --- @return self
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

        self.is_recording_enabled   = false

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

    ---@param filePath string
    ---@param sampleRate number | nil
    ---@param channels number | nil
    ---@return boolean
    function RMP.Sound:enableRecording(filePath, sampleRate, channels)
        if self.state == RMP.State.ERROR and self.last_error ~= nil then
            -- indecates that there's an error
            return false
        end
        if not filePath then
            self.state = RMP.State.ERROR
            self.last_error = "ERROR: file path of the Recording method is required"
            return false
        end

        sampleRate = sampleRate or 44100
        channels = channels or 2
        local ok, err = pcall(rmpaudio.EnableRecord, filePath, sampleRate, channels)
        if not ok and err then
            self.state = RMP.State.ERROR
            self.last_error = "ERROR: " .. err
            return false
        end
        return true
    end

    ---@return boolean
    function RMP.Sound:disableRecording()
        if self.state == RMP.State.ERROR and self.last_error ~= nil then
            -- indecates that there's an error
            return false
        end
        local ok, err = pcall(rmpaudio.DisableRecord)
        if not ok and err then
            self.state = RMP.State.ERROR
            self.last_error = "ERROR: " .. err
            return false
        end

        return true
    end

    --- @return integer|nil
    function RMP.Sound:getState()
        return self.state
    end

    --------------------------------------------------------------------
    -- Playlist management
    --------------------------------------------------------------------
    --- @param files string | table
    --- @return self
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

    --- @return string|nil
    function RMP.Sound:getLastError()
        if self.state == RMP.State.ERROR and self.last_error ~= nil then
            return self.last_error
        end
        return nil
    end

    --- @param file string
    --- @return self
    function RMP.Sound:addTrack(file)
        if type(file) == "string" then table.insert(self.playlist, file) end
        return self
    end

    --- @param index integer
    --- @return self
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

    --- @return table
    function RMP.Sound:getPlaylist() return self.playlist end

    --- @return integer
    function RMP.Sound:getCurrentIndex() return self.current_index end

    --- @return string | nil
    function RMP.Sound:getCurrentTrack()
        if self.current_index > 0 and self.current_index <= #self.playlist then
            return self.playlist[self.current_index]
        end
        return nil
    end

    --- @param mode PlaybackMode
    function RMP.Sound:setPlayBackMode(mode)
        self.playback_mode = mode
    end

    --- @return integer|PlaybackMode
    function RMP.Sound:getPlayBackMode()
        return self.playback_mode
    end

    --------------------------------------------------------------------
    -- Internal loader
    --------------------------------------------------------------------
    --- @private
    --- @return boolean
    --- @return string | nil
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
        return true, nil
    end

    --------------------------------------------------------------------
    -- Playback control (each handles both pcall errors and boolean+error returns)
    --------------------------------------------------------------------
    --- @return boolean
    --- @return string | nil
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
        return true, nil
    end

    --- @return boolean
    --- @return string | nil
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
        return true, nil
    end

    --- @return boolean
    --- @return string | nil
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
        return true, nil
    end

    --- @return boolean
    --- @return string | nil
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
        return true, nil
    end

    --- @param seconds number
    --- @return boolean
    --- @return string | nil
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

        return true, nil
    end

    --------------------------------------------------------------------
    -- Volume / speed
    --------------------------------------------------------------------
    --- @param v number
    --- @return boolean
    --- @return string | nil
    function RMP.Sound:setVolume(v)
        v = math.max(0, math.min(1, tonumber(v) or 0))
        local ok, ret = pcall(rmpaudio.SetVolume, v)
        if not ok or ret == false then
            self.last_error = "SetVolume failed: " .. tostring(ret)
            return false, self.last_error
        end
        self.volume = v
        return true, nil
    end

    --- @return number
    function RMP.Sound:getVolume()
        local ok, vol = pcall(rmpaudio.GetVolume)
        if not ok then
            return self.volume
        end
        return vol or self.volume
    end

    --- @return number
    function RMP.Sound:getSpeed()
        return self.speed
    end

    --- @param s number
    --- @return boolean
    --- @return string | nil
    function RMP.Sound:setSpeed(s)
        s = tonumber(s) or 1.0
        local ok, ret = pcall(rmpaudio.SetSpeed, s)
        if not ok or ret == false then
            self.last_error = "SetSpeed failed: " .. tostring(ret)
            return false, self.last_error
        end
        self.speed = s
        return true, nil
    end

    --------------------------------------------------------------------
    -- Position / length (now properly in seconds)
    --------------------------------------------------------------------
    --- @return integer
    function RMP.Sound:getPosition()
        local ok, pos = pcall(rmpaudio.GetPosition)
        if not ok then
            self.last_error = "GetPosition pcall error: " .. tostring(pos)
            return 0
        end
        return tonumber(pos) or 0
    end

    --- @return integer
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
    --- @param flag boolean
    --- @return boolean
    --- @return string | nil
    function RMP.Sound:setLoop(flag)
        local ok, ret = pcall(rmpaudio.SetLoop, flag and true or false)
        if not ok or ret == false then
            self.last_error = "SetLoop failed"
            return false, self.last_error
        end
        return true, nil
    end

    --- @return boolean
    function RMP.Sound:getLoop()
        local ok, ret = pcall(rmpaudio.GetLoop)
        if not ok then return false end
        return not not ret
    end

    function RMP.Sound:setVisualizationCallback(fn)
        if type(fn) ~= "function" then
            return false, "callback must be function"
        end
        -- local ok, a, b = pcall(rmpaudio.SetVisualizationCallback, fn)
        local ok, err = rmpaudio.SetVisualizationCallback(fn)
        if not ok then
            self.last_error = "SetVisualizationCallback pcall error: " .. tostring(err)
            return false, self.last_error
        end
        -- if a == false then
        --     self.last_error = tostring(b or "SetVisualizationCallback failed")
        --     return false, self.last_error
        -- end
        self.visualization_callback = fn
        return true
    end

    function RMP.Sound:enableVisualization(bins)
        bins = tonumber(bins) or self.freq_bins
        -- local ok, a, b = pcall(rmpaudio.EnableVisualization, bins)
        local success, err = rmpaudio.EnableVisualization(bins)
        if not success then
            self.last_error = "EnableVisualization pcall error: " .. tostring(err)
            return false, self.last_error
        end
        -- if a == false then
        --     self.last_error = tostring(b or "EnableVisualization failed")
        --     return false, self.last_error
        -- end
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
    --- @return boolean
    function RMP.Sound:isPlaying()
        local ok, v = pcall(rmpaudio.IsPlaying)
        if not ok then return false end
        return not not v
    end

    --- @return boolean
    function RMP.Sound:isFinished()
        local ok, v = pcall(rmpaudio.IsFinished)
        if not ok then return false end
        return not not v
    end

    --- @return nil | table
    function RMP.Sound:getMetadata()
        local ok, meta = pcall(rmpaudio.GetMetadata)
        if not ok then return nil end
        return meta
    end

    --------------------------------------------------------------------
    -- Track navigation: prev/next, plus an 'update' to auto-advance
    --------------------------------------------------------------------
    --- @return boolean
    --- @return string | nil
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
        return self:play(), nil
    end

    --- @return boolean
    --- @return string | nil
    function RMP.Sound:prevTrack()
        if #self.playlist == 0 then return false, "empty playlist" end
        self.current_index = self.current_index - 1
        if self.current_index < 1 then self.current_index = #self.playlist end
        local ok, err = self:_loadCurrentTrack()
        if not ok then return false, err end
        return self:play(), nil
    end

    --- event loop required
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

    --- @return number
    function RMP.Sound:getProgress()
        local pos = self:getPosition()
        local dur = self:getLength()
        if dur > 0 then
            return pos / dur
        end
        return 0
    end

    --- @return integer
    function RMP.Sound:getTimeRemaining()
        return self:getLength() - self:getPosition()
    end

    --- @param seconds integer
    --- @return string
    function RMP.Sound:formatTime(seconds)
        seconds = math.floor(seconds or 0)
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        return string.format("%02d:%02d", mins, secs)
    end

    --- @return string
    function RMP.Sound:getFormattedPosition()
        return self:formatTime(self:getPosition())
    end

    --- @return string
    function RMP.Sound:getFormattedDuration()
        return self:formatTime(self:getLength())
    end

    --- @return string
    function RMP.Sound:getFormattedTimeRemaining()
        return self:formatTime(self:getTimeRemaining())
    end

    --- @return boolean
    function RMP.Sound:cleanup()
        if self.visualization_enabled then
            self:disableVisualization()
        end
        local ok, ret = pcall(rmpaudio.Cleanup)
        self.is_initialized = false
        return ok and ret
    end
end

--- @class rmp.rmp.Path
RMP.Path = OOP.class("Path")
do -- Path
    --- @return string
    function RMP.Path.getPathSeparator()
        local os_type = RMP.getOs()
        if os_type == RMP.PlatformType.WINDOWS then
            return "\\"
        else
            return "/"
        end
    end

    --- @param ... unknown
    --- @return string
    function RMP.Path.joinPath(...)
        local parts = { ... }
        local sep = RMP.Path.getPathSeparator()
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

    --- @param path string
    function RMP.Path:constructor(path)
        self.path = path or self:getCurrentPath()
    end

    -- local path = Path()
    -- local other_path = path + "foo"
    -- other_path:getPath()
    function RMP.Path:__add(p)
        return RMP.Path(RMP.Path.joinPath(self:getPath(), p))
    end

    --- @param path string
    function RMP.Path:setPath(path)
        self.path = path
    end

    --- @return string
    function RMP.Path:getPath()
        return self.path
    end

    --- @return any
    function RMP.Path:getCurrentPath()
        return directory.get_current_path()
    end

    --- @return any
    function RMP.Path:getHomePath()
        return directory.home_path()
    end

    -- TODO: create listDirAsync
    --- @return any
    function RMP.Path:listDir()
        -- this method return table of tables contains two value
        -- first one is boolean indecates if it is file or dir (true -> file else dir)
        -- second one is string name of the file or dir
        return directory.list_dir(self.path) -- may return nil
    end

    -- TODO: add exists file
    -- TODO: add more functionality to Path class

    --- @return boolean
    function RMP.Path:exists()
        return self:listDir() ~= nil
    end

    --- @param dir_name string
    --- @return any
    function RMP.Path:makeDir(dir_name)
        dir_name = dir_name or ""
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

    --- @param dir_name string
    --- @return any
    function RMP.Path:removeDir(dir_name)
        local full_dir = nil
        if string.sub(self.path, -1) == "/" then
            full_dir = self.path .. dir_name
        else
            full_dir = self.path .. "/" .. dir_name
        end
        return directory.rmdir(full_dir)
    end

    --- @param pattern string
    --- @param is_find_file boolean
    --- @return boolean
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

    --- @param pattern string
    --- @param is_file_pattern boolean
    --- @param max_depth integer
    --- @return table
    function RMP.Path:findRecursive(pattern, is_file_pattern, max_depth) -- return Table {path , name , is_file}
        max_depth = max_depth or -1
        local results = {}
        local match_func

        if type(pattern) == "function" then
            match_func = pattern
        else
            match_func = function(name) return name == pattern end
        end

        ---@diagnostic disable-next-line: lowercase-global
        function search_recursive(current_path, current_depth)
            if max_depth >= 0 and current_depth > max_depth then
                return
            end

            --- @diagnostic disable-next-line
            local temp_path = RMP.Path.new(current_path)
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

                --- @diagnostic disable-next-line
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

-- TODO: create wrapper for native socket library implementation
-- TODO: make sure that every socket method works async
-- TODO: handle SSL/TLS sockets

--- @class rmp.rmp.Socket
RMP.Socket = OOP.class("Socket")
do
    --- @param host string  | nil
    --- @param port integer  | nil
    --- @return self
    function RMP.Socket:constructor(host, port)
        self.host = host or "localhost"
        self.port = port or 8080
        self.socket = rsocket.new()
        return self
    end

    --- @return boolean | nil , string | nil
    function RMP.Socket:connect()
        return self.socket:connect(self.host, self.port)
    end

    --- @return boolean | nil , string | nil
    function RMP.Socket:bind()
        return self.socket:bind(self.host, self.port)
    end

    --- @return boolean | nil , string | nil
    function RMP.Socket:listen(backlog)
        backlog = backlog or 5
        return self.socket:listen(backlog)
    end

    -- returns another socket objetc
    --- @return string | integer | nil , string | nil
    function RMP.Socket:accept()
        return self.socket:accept()
    end

    --- @return integer | nil , string | nil
    function RMP.Socket:send(data)
        return self.socket:send(data)
    end

    --- @return string | nil , string | nil
    function RMP.Socket:recv(size)
        return self.socket:recv(size)
    end

    --- @return boolean
    function RMP.Socket:close()
        return self.socket:close()
    end

    --- @return boolean | nil , string | nil
    function RMP.Socket:setnonblock(non_blocking)
        return self.socket:setnonblock(non_blocking)
    end

    --- @return boolean | nil , string | nil
    function RMP.Socket:setnodelay(no_delay)
        return self.socket:setnodelay(no_delay)
    end

    --- @return boolean | nil , string | nil
    function RMP.Socket:setbroadcast(istrue)
        return self.socket:setbroadcast(istrue)
    end

    --- @return string
    function RMP.Socket:getprotocol()
        return self.socket:getprotocol()
    end

    --- @return integer | nil , string | nil
    function RMP.Socket:sendto(packet, host, port)
        -- TODO: check if the packet is instance of Packet
        if packet:instanceOf(RMP.Packet) then
            packet = packet:getReadableSocketByte()
        end
        return self.socket:sendto(packet, host, port)
    end

    --- @return string | nil , string | nil , integer | string | nil
    function RMP.Socket:recvfrom(size)
        return self.socket:recvfrom(size)
    end
end

--- @class rmp.rmp.Packet
RMP.Packet = OOP.class("Packet")
do
    function RMP.Packet:constructor()
        return self
    end

    function RMP.Packet:getReadableSocketByte()
    end
end

--- @class rmp.rmp.TCPSocket
RMP.TCPSocket = OOP.class("TCPSocket", RMP.Socket)
do
    function RMP.TCPSocket:constructor(host, port)
        --- @diagnostic disable-next-line
        self:super("constructor", host, port)
        self.port = port
        return self
    end
end

-- TODO: make sure that the socket native library support UDP sockets
--- @class rmp.rmp.UDPSocket
RMP.UDPSocket = OOP.class("UDPSocket", RMP.Socket)
do
    function RMP.UDPSocket:constructor(host, port)
        --- @diagnostic disable-next-line
        self:super("constructor", host, port)
        self.port = port
        return self
    end
end

--- @class rmp.rmp.FTPClient
RMP.FTPClient = OOP.class("FTPClient", RMP.TCPSocket)
do
    function RMP.FTPClient:constructor()
        return self
    end
end

--- @class rmp.rmp.HTTPServer
RMP.HTTPServer = OOP.class("HTTPServer", RMP.TCPSocket)
do
    function RMP.HTTPServer:constructor(port)
        self.port = port or 8080
        return self
    end
end

--- @class rmp.rmp.HTTPClient
RMP.HTTPClient = OOP.class("HTTPClient", RMP.TCPSocket)
do
    function RMP.HTTPClient:constructor()
        return self
    end
end

-- /////////////////////////////////////////////////////
-- Hight Level API Components
-- /////////////////////////////////////////////////////

--- @class rmp.rmp.Frame
RMP.Frame = OOP.class("Frame", RMP.VirtualTerminal)
do
    --- @param width integer
    --- @param height integer
    --- @return self
    function RMP.Frame:constructor(width, height)
        --- @diagnostic disable-next-line
        self:super("constructor", width, height)
        self.fps = 30
        self.lastTime = 0
        self.currentTime = 0
        self.deltaTime = 0
        self.frameCount = 0
        self.fpsTimer = 0
        self.actualFps = 0
        return self
    end

    function RMP.Frame:initMainFrame()
        RMP.Terminal:clearWindow()
        RMP.Terminal:hideCursor()
        io.flush()
    end

    function RMP.Frame:cleanupMainFrame()
        RMP.Terminal:closeKey()
        RMP.Terminal:showCursor()
        RMP.Terminal:clearWindow()
        io.flush()
    end

    --- @param fps integer
    function RMP.Frame:setFps(fps)
        self.fps = fps
    end

    --- @return integer
    function RMP.Frame:getFps()
        return self.actualFps
    end

    --- @return number
    function RMP.Frame:getDeltaTime()
        return self.deltaTime
    end

    --- @param x integer
    --- @param y integer
    function RMP.Frame:positionedFrame(x, y)
        x = x or 1
        y = y or 1
        --- @diagnostic disable-next-line
        self:super("moveCursor", x, y)
    end

    --- @param component VirtualTerminal | Frame
    --- @param distroy boolean
    --- @return self
    function RMP.Frame:add(component, distroy)
        --- @diagnostic disable-next-line
        self:super("merge", component, distroy)
        return self
    end

    --- @param components table
    --- @param distroy boolean
    --- @return self
    function RMP.Frame:addMany(components, distroy)
        --- @diagnostic disable-next-line
        self:super("mergeAll", components, distroy)
        return self
    end

    --- @overload fun(key : integer , callback : function)
    function RMP.Frame:addEventListener(key, callback)
        --- @diagnostic disable-next-line
        self:super("addEventListener", key, callback)
    end

    --- @param key integer
    --- @param mouse any
    --- @param sound rmp.rmp.Sound
    --- @param config table
    --- @param template table
    --- @param datafreq any
    --- @param exit boolean
    function RMP.Frame:run(key, mouse, sound, config, template, datafreq, exit)
        self.lastTime = self.currentTime
        self.currentTime = os.clock()

        if self.lastTime > 0 then
            self.deltaTime = self.currentTime - self.lastTime
        else
            self.deltaTime = 0
        end

        self.frameCount = self.frameCount + 1
        self.fpsTimer = self.fpsTimer + self.deltaTime

        if self.fpsTimer >= 1.0 then
            self.actualFps = math.floor(self.frameCount / self.fpsTimer)
            self.frameCount = 0
            self.fpsTimer = 0
        end

        --- @diagnostic disable-next-line
        self:super("handleEvent", key, mouse, sound, config, template, datafreq, exit)
        --- @diagnostic disable-next-line
        self:super("render")
        --- @diagnostic disable-next-line
        self:super("clear")

        local targetFrameTime = 1.0 / self.fps
        local sleepTime = math.max(0, targetFrameTime - self.deltaTime)
        --- @diagnostic disable-next-line
        RMP.sleep(math.floor(sleepTime * 1000))
    end
end

---comment
---@param callback function(callback : Frame) : boolean
function RMP.runApp(callback)
    --TODO: im writing just an example of the function architecture, but the function is not finished yet
    local frame = RMP.Frame()

    local quit = false

    while not quit do
        quit = callback(frame)

        -- add additional informations
        frame:run()
    end
end

return RMP

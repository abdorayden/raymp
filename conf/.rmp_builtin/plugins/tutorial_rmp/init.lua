local api = require("rmp.rmp")

local tutorial = [[
#   Welcome To RayMp
# What is RayMp ?
**RMP (Ray Music Player)** is a high-performance, extensible framework built in C with Lua scripting for creating sophisticated terminal user interfaces. Originally conceived as a music player, RMP has evolved into a comprehensive platform for terminal-based applications, featuring:

it's easy and simple to use for simple users and CS nerds
all you need is following this tutorial

- 🎵 **Advanced Music Player** - Multi-format audio support
- 📱 **Rich TUI Framework** - Create complex terminal interfaces with ease
- 🎮 **Game Development Platform** - Build 2D games directly in the terminal
- 🔧 **Extensible Plugin System** - Modular architecture for unlimited customization
- 🎨 **Dynamic Theming Engine** - Hot-swappable themes with Lua scripting
- ⚡ **High Performance** - Native C engine with Lua binding for optimal speed

# What's the difference between RMP and RayMp?
- **RayMp** is a software platform that renders templates and plugins with user configurations for a better audio experience using the **RMP** framework
- **RMP** is a framework with multiple classes and functions that uses C as a backend for better performance. It is used to create templates and plugins for the RayMp software and is also powerful for creating TUI applications in Lua

# How it works ?
- The **RayMp** engine creates a **Frame** (mother virtual-terminal) that connects all **VirtualTerminals** components and their **Events** together
- Plugins return a **VirtualTerminal** object with changes applied for each frame and their own **Event** listeners. The engine adds the **VirtualTerminal** plugin to it and applies it to the main screen
- All these classes are located in the **RMP framework**, which will be installed by default when you install the RayMp software

# Configuration structure:
- The **RayMp** engine ships a builtin configuration that is **always applied first** on every startup (and on every **restart_engine**). Your **~/.rmp** directory **(~ => HOME DIR)** is then layered on top, so you only override what you want to change:
- **init.lua** - Configuration of the engine, sound keymaps, the rendered template, and plugin configurations
- **templates** - Directory of templates that we created or downloaded. The file name (without extension) is what you put in **raymp.engine.template**
- **plugins** - Directory of plugins that we created or downloaded. Each plugin is a subdirectory (e.g. **my-plugin-rmp/** containing an **init.lua**); you register that directory name in the configuration file

# How to configure my music player ?
- Open the **~/.rmp/init.lua** configuration file in your text editor. **init.lua** populates the engine configuration table **raymp.engine** (no `return` needed). The engine pre-seeds defaults, so you only override what you want:
    **template** - Template name for rendering ("name" loads **~/.rmp/templates/<name>.lua**, falling back to the builtin templates like "tutorial"), or an inline table of windows
    **settings** - Engine settings that are loaded when RayMp starts
        **fps** - Engine FPS rendered
        **help_key** - Engine has its own help window configured with this field
        **volume** - The default volume the engine starts with
        **speed** - The default speed the engine starts with
        **mode** - The default mode the engine starts with
        **restart_engine** - Key used to restart the whole engine
        **exit** - Key used to exit from the software
        **messages_key** - Key that toggles the logged messages/errors overlay
        **theme** - Default theme name ["default", "darkandwhite", "desert", "elflord"]; nil disables theming
        **inc_volume** - The default increment for volume that the engine uses
        **inc_speed** - The default increment for speed that the engine uses
        **inc_seek** - The default increment for seek that the engine uses
    **soundMap** - Sound key maps that the engine handles for managing audio
        **pause_sound** - Configured key to pause the sound
        **resume_sound** - Configured key to resume the sound
        **next_sound** - Configured key to go to the next sound
        **prev_sound** - Configured key to go to the previous sound
        **vol_up** - Configured key to increase the volume
        **vol_down** - Configured key to decrease the volume
        **seek_left** - Configured key to seek left in the sound
        **seek_right** - Configured key to seek right in the sound
        **speed_up** - Configured key to increase the playback speed
        **speed_down** - Configured key to decrease the playback speed
        **change_playback_mode** - Configured key to change the playback mode of the sound
    **builtin** - Enable / disable the builtin components (help, notify, themes, theme_manager) and the builtin window plugins (tutorial_rmp, helper_keys_tutorial, matrix_digital_rain_effect). A missing flag defaults to ENABLED; `raymp.engine.builtin = false` disables everything
    **plugins** - Plugins is a table of plugins that are wrapped in tables
        **themeWindowId** - The ID of the window in the template that is used to integrate plugins for a specific window in the template **(OPTIONAL)**. If the field is nil or not selected, the plugin is a global plugin over the whole screen
        **isActivated** - Boolean field: true to use the plugin, false to ignore it
        **names** - Table field that accepts multiple plugins
            Why? : A window can use multiple plugins (for example, animations and more), so we can apply more than 1 plugin to the same window
        **switchPluginKey** - This plugin is optional and used for switching multiple plugins in a window
- You can also use the shorthand proxy — `raymp.engine.fps = 30` is the same as `raymp.engine.settings.fps = 30`.
- Returning a table is still supported: `return { template = "my_template", settings = {...}, ... }` and it will be merged onto the engine config.
```lua
-- Example configuration (~/.rmp/init.lua)
raymp.engine.template = "my_template" -- or an inline table; falls back to builtin "tutorial"

raymp.engine.fps = 60
raymp.engine.help_key = api.KEY_H
raymp.engine.volume = 0.5                 -- 0 to 1
raymp.engine.speed = 1.0                  -- 0.01 to 3.0
raymp.engine.mode = api.PlaybackMode.ONES -- playback modes
raymp.engine.restart_engine = api.KEY_CTRL_R
raymp.engine.exit = api.KEY_Q

-- inc or dec
raymp.engine.inc_speed = 0.1
raymp.engine.inc_volume = 0.1
raymp.engine.inc_seek = 5

raymp.engine.soundMap.pause_sound = api.KEY_SPACE
raymp.engine.soundMap.resume_sound = api.KEY_SPACE
raymp.engine.soundMap.next_sound = api.KEY_N
raymp.engine.soundMap.prev_sound = api.KEY_P
raymp.engine.soundMap.vol_up = api.KEY_PLUS
raymp.engine.soundMap.vol_down = api.KEY_MINUS
raymp.engine.soundMap.seek_left = api.KEY_LEFT
raymp.engine.soundMap.seek_right = api.KEY_RIGHT
raymp.engine.soundMap.speed_up = api.KEY_UP
raymp.engine.soundMap.speed_down = api.KEY_DOWN
raymp.engine.soundMap.change_playback_mode = api.KEY_TAB

-- enable / disable the builtin components and window plugins
raymp.engine.builtin = {
    help = true,
    notify = true,
    themes = true,
    theme_manager = true,
    plugins = {
        tutorial_rmp = true,
        helper_keys_tutorial = true,
        matrix_digital_rain_effect = true,
    },
}

raymp.engine.plugins = {
    {
        themeWindowId = "tutorial-window",
        isActivated = true,
        names = {
            "tutorial_rmp"
        }
    },
}
```
# How to create my own template ?
- To create your own template, you have to put your init.lua template file in the **~/.rmp/templates** directory. Choose your template name **(for example foo.lua)**
- **foo.lua** populates **raymp.engine.template** with a table of components/windows (returning the table is also accepted and merged)
- Component fields:
        **id** - The window ID
        **type** - The type of component ["Window" , "Text"]
        **title** - Window type field that contains a string value or component of type "Text"
        **width** - Window field that specifies the window width
        **height** - Window field that specifies the window height
        **x** - Window field that specifies the window x position
        **y** - Window field that specifies the window y position
        **border** - Border style of the window
        **backgroundColor** - Background color of the window
        **foregroundColor** - Foreground color of the window (border color)
        **style** - Text type component field to specify text style

        **dynamic** - Text type component field of type callback function that accepts the window context and returns a string. Used to update the text dynamically (like updating a clock each frame)
        **condition** - Window type component field of type callback function that accepts the window context and returns a boolean. Used as a condition to display the window or not

```lua
-- Example template code
raymp.engine.template = {
    {
        id = "main_window",
        type = "Window",
        title = "My Custom Window",
        -- x , y , width , height : can evaluate string operations
        -- and use w and h as window width and height
        x = 1,
        y = 1,
        width = "w/2",
        height = 20,
        border = "Single",
        backgroundColor = api.BGColors.Black,
        foregroundColor = api.FGColors.White
    },
    {
        id = "text_display",
        type = "Text",
        x = 2,
        y = 2,
        width = 48,
        height = 18,
        style = api.TextStyle.Normal
    }
}
```
# How to create my own plugin ?
- Put your plugin module in **~/.rmp/plugins/<name>/init.lua** (any name) — `~/.rmp/plugins/` is added to the Lua require path, so the module resolves as **require("<name>")**
- Register it in the **plugins** configuration section of **~/.rmp/init.lua** and pick its activation/switch keys there
- Plugins are Lua files that return a callback function. The callback runs every frame
- Plugins have direct access to the global **raymp** and its engine configuration (**raymp.engine.fps**, ...) — you don't need a frame parameter. Window-attached plugins use `return function(x, y, xx, yy)`; global plugins use `return function()`
- You need to initialize a VirtualTerminal object inside the returned callback function (Why? : The engine uses optimizations, which means after it adds all the components, it cleans their memories to avoid memory leaks)
- Use global variables as plugin state and the return function as update functionality for each frame
- plugins can be configured in **init.lua** configuration file , you can put string name of the plugin or u can put table the first index is the plugin name and second index is table with configuration field so u can load those configurations and work with them

# Code Examples
Here are some code examples to help you get started with plugins creation:

```lua
-- Example plugin code
-- require rmp framework
local api = require("rmp.rmp")

-- x , y , xx , yy : are optional
-- u need them if you integrate plugin to specific window
-- otherwise you can get
-- width and height of the window by rmp framework
return function(x, y, xx, yy)
    local w = xx - x - 1
    local h = yy - y - 1
    local vterm = api.VirtualTerminal.new()

    vterm:writeText(x + 1, y + 1, "Hello from my plugin!")

    -- the global raymp is always available:
    --   raymp:writeText(...)
    --   -- and the engine configuration:
    --   raymp.engine.settings.fps
    --   raymp.engine.fps

    return vterm
end
```

# learn rmp framework API:
- all those chapters is for programmers
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

all those components are implement interfaces **Renderable** with one method **render** this method returns a VirtualTerminal instance
that means all those components returns thier own VirtualTerminal with thier own modifications and merge them to the VirtualTerminal instance mother

- check https://rayden-six.vercel.app/raymp/framework
# Copyright :
Copyright (c) 2024-2026 Ray Den

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

local move_down = 0
local animation_start_time = os.time()
local animation_duration = 3

local t = (function()
    local lines = {}
    local currentLine = ""
    local inCodeBlock = false
    local codeBlockContent = ""

    for line in tutorial:gmatch("([^\n]*)\n?") do
        if line:match("^```") then
            if not inCodeBlock then
                if currentLine ~= "" then
                    table.insert(lines, currentLine)
                    currentLine = ""
                end
                inCodeBlock = true
                table.insert(lines, "```START_CODE_BLOCK```")
            else
                inCodeBlock = false
                table.insert(lines, "```END_CODE_BLOCK```")
                currentLine = ""
            end
        else
            if inCodeBlock then
                table.insert(lines, "CODE:" .. line)
            else
                table.insert(lines, line)
            end
        end
    end

    if currentLine ~= "" and not inCodeBlock then
        table.insert(lines, currentLine)
    end

    return lines
end)()

local function wrapLine(line, maxWidth)
    if #line <= maxWidth then
        return { line }
    end

    local wrappedLines = {}
    local currentPos = 1

    while currentPos <= #line do
        local endPos = currentPos + maxWidth - 1

        if endPos >= #line then
            table.insert(wrappedLines, line:sub(currentPos))
            break
        else
            local breakPos = endPos

            for i = endPos, currentPos, -1 do
                if line:sub(i, i) == " " then
                    breakPos = i
                    break
                end
            end

            if breakPos == endPos and line:sub(breakPos, breakPos) ~= " " then
                breakPos = endPos
            end

            table.insert(wrappedLines, line:sub(currentPos, breakPos - 1))
            currentPos = breakPos + 1

            while currentPos <= #line and line:sub(currentPos, currentPos) == " " do
                currentPos = currentPos + 1
            end
        end
    end

    return wrappedLines
end

local function parseFormattedText(text, defaultFgColor, defaultBgColor, defaultStyle)
    local result = {}
    local pos = 1
    local currentText = ""

    while pos <= #text do
        local startBold, endBold = text:find("%*%*", pos)

        if startBold then
            if startBold > pos then
                currentText = currentText .. text:sub(pos, startBold - 1)
            end

            local closeStart = endBold + 1
            local closeBoldStart, closeBoldEnd = text:find("%*%*", closeStart)

            if closeBoldStart then
                if currentText ~= "" then
                    table.insert(result,
                        { text = currentText, fg = defaultFgColor, bg = defaultBgColor, style = defaultStyle })
                    currentText = ""
                end

                table.insert(result, {
                    text = text:sub(endBold + 1, closeBoldStart - 1),
                    fg = defaultFgColor,
                    bg = defaultBgColor,
                    style = api.TextStyle.Bold
                })
                pos = closeBoldEnd + 1
            else
                currentText = currentText .. text:sub(startBold, endBold)
                pos = endBold + 1
            end
        else
            currentText = currentText .. text:sub(pos)
            pos = #text + 1
        end
    end

    if currentText ~= "" then
        table.insert(result, { text = currentText, fg = defaultFgColor, bg = defaultBgColor, style = defaultStyle })
    end

    return result
end

local theme = nil

-- shared colors
-- BackGround = "#0f1419",
-- BorderColor = "#e6e1cf",
-- TitleBackGround = "#0f1419",
-- TitleText = "#e6e1cf",
-- PrimaryContent = "#b8cc52",
-- SecondaryContent = "#59c2ff",
-- AccentElements = "#f07178",
-- Highlight = "#ffb454",
-- MutedElements = "#d2a6ff"
local function extColor(variant_text, fg)
    if type(theme) == "table" and theme[variant_text] ~= nil then
        return api.colorFromHex(theme[variant_text], fg and api.FG or api.BG)
    end
    return nil
end

local function syntaxHighlightLua(codeLine)
    local tokens = {}
    local pos = 1
    local currentText = ""

    local keywords = {
        "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
        "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
        "true", "until", "while", "require", "local"
    }

    local keywordSet = {}
    for _, kw in ipairs(keywords) do
        keywordSet[kw] = true
    end

    while pos <= #codeLine do
        local char = codeLine:sub(pos, pos)

        if char == '"' or char == "'" then
            if currentText ~= "" then
                table.insert(tokens,
                    { text = currentText, color = extColor("PrimaryContent", true) or api.FGColors.Brights.White, style = nil })
                currentText = ""
            end

            local startQuote = char
            local inEscape = false
            local stringStart = pos
            pos = pos + 1

            while pos <= #codeLine do
                char = codeLine:sub(pos, pos)
                if inEscape then
                    inEscape = false
                elseif char == startQuote then
                    break
                elseif char == "\\" then
                    inEscape = true
                end
                pos = pos + 1
            end

            local stringText = codeLine:sub(stringStart, pos - 1)
            table.insert(tokens,
                { text = stringText, color = extColor("SecondaryContent", true) or api.FGColors.Brights.Green, style = nil })
        elseif char == "-" and codeLine:sub(pos + 1, pos + 1) == "-" then
            if currentText ~= "" then
                table.insert(tokens,
                    { text = currentText, color = extColor("PrimaryContent", true) or api.FGColors.Brights.White, style = nil })
                currentText = ""
            end

            local commentStart = pos
            while pos <= #codeLine and codeLine:sub(pos, pos) ~= "\n" do
                pos = pos + 1
            end

            local commentText = codeLine:sub(commentStart, pos - 1)
            table.insert(tokens,
                {
                    text = commentText,
                    color = extColor("MutedElements", true) or api.FGColors.Brights.Blue,
                    style = api
                        .TextStyle.Italic
                })
        elseif char:match("[%d]") then
            if currentText ~= "" then
                table.insert(tokens,
                    { text = currentText, color = extColor("PrimaryContent", true) or api.FGColors.Brights.White, style = nil })
                currentText = ""
            end

            local numberStart = pos
            pos = pos + 1
            while pos <= #codeLine do
                local nextChar = codeLine:sub(pos, pos)
                if not nextChar:match("[%d%.xXa-fA-F]") then
                    break
                end
                pos = pos + 1
            end

            local numberText = codeLine:sub(numberStart, pos - 1)
            table.insert(tokens,
                { text = numberText, color = extColor("AccentElements", true) or api.FGColors.Brights.Magenta, style = nil })
        elseif char:match("[%a_]") then
            if currentText ~= "" then
                table.insert(tokens,
                    { text = currentText, color = extColor("PrimaryContent", true) or api.FGColors.Brights.White, style = nil })
                currentText = ""
            end

            local identStart = pos
            pos = pos + 1
            while pos <= #codeLine do
                local nextChar = codeLine:sub(pos, pos)
                if not nextChar:match("[%w_]") then
                    break
                end
                pos = pos + 1
            end

            local identText = codeLine:sub(identStart, pos - 1)
            if keywordSet[identText] then
                table.insert(tokens,
                    {
                        text = identText,
                        color = extColor("Highlight", true) or api.FGColors.Brights.Yellow,
                        style = api
                            .TextStyle.Bold
                    })
            else
                table.insert(tokens,
                    { text = identText, color = extColor("PrimaryContent", true) or api.FGColors.Brights.White, style = nil })
            end
        else
            currentText = currentText .. char
            pos = pos + 1
        end
    end

    if currentText ~= "" then
        table.insert(tokens,
            { text = currentText, color = extColor("PrimaryContent", true) or api.FGColors.Brights.White, style = nil })
    end

    return tokens
end

return function(x, y, xx, yy)
    local w = xx - x - 1
    local h = yy - y - 1

    -- listen every frame: TransformDataGet callbacks are one-shot (drained by the
    -- engine each run), re-registering keeps the shared theme in sync when the
    -- user switches themes at runtime through the theme manager plugin
    raymp:addEventListener(api.EventType.TransformDataGet, function(data)
        if data and data.theme then
            theme = data.theme
        end
    end)

    -- resolved once per frame, shared by every writeText/writeTextClipped below
    local background_color = extColor("BackGround", false)

    local current_time = os.time()
    local elapsed_time = current_time - animation_start_time

    if elapsed_time < animation_duration then
        local animation_text = "Welcome to RayMp!"
        local centered_x = x + math.floor((w - #animation_text) / 2)
        local centered_y = y + math.floor(h / 2)

        local animation_phase = (current_time * 2) % 4
        local color
        if animation_phase < 1 then
            color = extColor("Highlight", true) or api.FGColors.Brights.Red
        elseif animation_phase < 2 then
            color = extColor("AccentElements", true) or api.FGColors.Brights.Yellow
        elseif animation_phase < 3 then
            color = extColor("PrimaryContent", true) or api.FGColors.Brights.Green
        else
            color = extColor("SecondaryContent", true) or api.FGColors.Brights.Cyan
        end

        raymp:writeText(centered_x, centered_y, animation_text, color, background_color,
            api.TextStyle.Bold)

        local progress_text = ""
        for i = 1, animation_duration do
            if i <= elapsed_time then
                progress_text = progress_text .. "●"
            else
                progress_text = progress_text .. "○"
            end
        end
        local progress_x = x + math.floor((w - #progress_text) / 2)
        raymp:writeText(progress_x, centered_y + 2, progress_text, extColor("PrimaryContent", true) or
            api.FGColors.Brights.White, background_color)

        return
    end

    raymp:onKeyboard(function(key)
        if key == api.KEY_J or key == api.KEY_DOWN then
            move_down = move_down + 1
        elseif key == api.KEY_K or key == api.KEY_UP then
            move_down = math.max(0, move_down - 1)
        end
    end)

    raymp:addEventListener(api.EventType.TransformDataPut, function()
        return {
            UP = "k/key-up",
            DOWN = "j/key-down",
        }
    end)

    local totalLines = 0
    for _, originalLine in ipairs(t) do
        if originalLine == "```START_CODE_BLOCK```" or originalLine == "```END_CODE_BLOCK```" or originalLine:match("^CODE:") then
            totalLines = totalLines + 1
        else
            local wrappedLines = wrapLine(originalLine, w)
            totalLines = totalLines + #wrappedLines
        end
    end

    move_down = math.min(move_down, math.max(0, totalLines - h))

    local displayLineNumber = 1
    for _, originalLine in ipairs(t) do
        local wrappedLines = {}

        if originalLine == "```START_CODE_BLOCK```" or originalLine == "```END_CODE_BLOCK```" then
            table.insert(wrappedLines, originalLine)
        elseif originalLine:match("^CODE:") then
            local codeContent = originalLine:sub(6)
            table.insert(wrappedLines, codeContent)
        else
            wrappedLines = wrapLine(originalLine, w)
        end

        for _, line in ipairs(wrappedLines) do
            if displayLineNumber > move_down then
                if (displayLineNumber - move_down) <= h then
                    local displayY = y + (displayLineNumber - move_down - 1)

                    if line == "```START_CODE_BLOCK```" then
                    elseif line == "```END_CODE_BLOCK```" then
                    elseif originalLine:match("^CODE:") then
                        local codeContent = originalLine:sub(6)
                        local xPos = x + 1
                        local tokens = syntaxHighlightLua(codeContent)
                        for _, token in ipairs(tokens) do
                            raymp:writeTextClipped(xPos, displayY, token.text, w - (xPos - x - 1), token.color,
                                background_color, token.style)
                            xPos = xPos + #token.text
                        end
                    elseif line:match("^%s*#") then
                        local formattedParts = parseFormattedText(line,
                            extColor("Highlight", true) or api.FGColors.Brights.Yellow, background_color,
                            api.TextStyle.Bold)
                        local xPos = x + 1
                        for _, part in ipairs(formattedParts) do
                            raymp:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg,
                                background_color,
                                part.style)
                            xPos = xPos + #part.text
                        end
                    elseif line:match("^%s*$") then
                        -- empty lines
                        -- skip empty lines or handle as needed
                    elseif line:match("^%s*-") then
                        local bullet_text = line:match("^%s*-%s*(.*)")
                        if bullet_text then
                            raymp:writeTextClipped(x + 1, displayY, "-", w,
                                extColor("AccentElements", true) or api.FGColors.Brights.Red,
                                background_color)

                            local formattedParts = parseFormattedText(" " .. bullet_text,
                                extColor("PrimaryContent", true) or api.FGColors.Brights.White,
                                background_color,
                                nil)
                            local xPos = x + 2
                            for _, part in ipairs(formattedParts) do
                                raymp:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg,
                                    background_color,
                                    part.style)
                                xPos = xPos + #part.text
                            end
                        else
                            local formattedParts = parseFormattedText(line,
                                extColor("PrimaryContent", true) or api.FGColors.Brights.White,
                                background_color, nil)
                            local xPos = x + 1
                            for _, part in ipairs(formattedParts) do
                                raymp:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg,
                                    background_color,
                                    part.style)
                                xPos = xPos + #part.text
                            end
                        end
                    else
                        local formattedParts = parseFormattedText(line,
                            extColor("PrimaryContent", true) or api.FGColors.Brights.White, background_color,
                            nil)
                        local xPos = x + 1
                        for _, part in ipairs(formattedParts) do
                            raymp:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg,
                                background_color,
                                part.style)
                            xPos = xPos + #part.text
                        end
                    end
                end
            end
            displayLineNumber = displayLineNumber + 1
        end
    end
end

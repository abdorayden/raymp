local api = require("rmp.rmp")
local tutorial = [[
# Welcome To RayMp
## what is RayMp ?
**RMP (Ray Music Player)** is a high-performance, extensible framework built in C with Lua scripting for creating sophisticated terminal user interfaces. Originally conceived as a music player, RMP has evolved into a comprehensive platform for terminal-based applications, featuring:

- 🎵 **Advanced Music Player** - Multi-format audio support
- 📱 **Rich TUI Framework** - Create complex terminal interfaces with ease
- 🎮 **Game Development Platform** - Build 2D games directly in the terminal
- 🔧 **Extensible Plugin System** - Modular architecture for unlimited customization
- 🎨 **Dynamic Theming Engine** - Hot-swappable themes with Lua scripting
- ⚡ **High Performance** - Native C engine with Lua binding for optimal speed

## what's the diffrent between rmp and raymp:
- **raymp** is software platform that render templates and plugins with user configurations for better audio experience that use **rmp** framework
- **rmp** is framework with multiple classes and functions that use C as backend for better experience used to creates templates and plugins for raymp software also is powerfull for creating TUI applications in lua

## how it works ?
- **raymp** engine creates **Frame** (mother virtual-terminal) that used to connect all **VirtualTerminals** component and thier **Events** together
the plugins return **VirtualTerminal** object with changes that applied for each frame and thier own **Event** listeners the engine add the **VirtualTerminal** plugin to it and apply it to the main screen
all those classes are located in **rmp framework** that will be installed by default when you install raymp software

## configuration structure:
- **raymp** engine check **~/.rmp** directory **~ => HOME DIR** arch of .rmp dir is :
- **init.lua** - is configurations of the engine and sound keymaps and the rendrened templates and plugin configurations
- **themes**   - is directory of templates that we created or downloaded from plugin manager the directory contains names of templates that we choosed on init.lua configuration file
- **plugins**  - is directory of plugins that we created or downloaded from plugin manager the directory contains directorys of plugins that we load them and configure into configuration file
## how to configure my music player ?
- first thing open ~/.rmp directory in your text editor
- open **init.lua** configuration file ,**init.lua** return table with multiple keys
    **settings** is engine settings that load them when raymp start
        **fps** - engine fps rendrened
        **help_key** - engine has it's own help window configured with this field
        **volume** - the default volume the engine starts with
        **speed** - the default speed the engine starts with
        **mode** - the default mode the engine starts with
        **restart_engine** - key that used to restart the whole engine
        **exit** - key that used to exit from the software
        **inc_volume** - the default inc for volume that engine used
        **inc_speed** - the default inc for speed that engine used
        **inc_seek** - the default inc for seek that engine used

    **soundMap** is sound key maps that engine handled for managing audios
        **pause_sound** - configured key for pause the sound
        **resume_sound** - configured key for resume the sound
        **next_sound** - configured key for go to next the sound
        **prev_sound** - configured key for go to prev the sound
        **vol_up** - configured key for volume up the sound
        **vol_down** - configured key for volume down the sound
        **seek_left** - configured key for seek left the sound
        **seek_right** - configured key for seek right the sound
        **speed_up** - configured key for speed up the sound
        **speed_down** - configured key for speed down the sound
        **change_playback_mode** - configured key for changing playback mode the sound
    **template** - template name for rendring
    **plugins** - plugins is table of plugins that wrapped in tables
        **themeWindowId** - the id of the window in template that used for integrate plugins for specific window in template **OPTIONAL** if the field is nil value or not selected the plugin can access the whole window
        **isActivated** - boolean field true use the plugin false ignore it
        **names** - is table field that accept multiple plugins
            why?? : window can use multiple plugins for example animations and more so we can apply more than 1 plugin to the same window
        **switchPluginKey** - this plugin is optional used for switching multiple plugins in window
    },
## how to create my own template    ?
- to create your own template you have to put you init lua template file in **~/.rmp.themes** directory choose your template name **(for example foo.lua)**
- **foo.lua** is return table with multiple tables that represent component or window for each table
- component field :
        **id** - the window id
        **type** - the type of component ["Window" , "Text"]
        **title** - is window type field contains string value or component of type "Text"
        **width** - is window field that used to spesify the window width
        **height** - is window field that used to spesify the window height
        **x** - is window field that used to spesify the window x position
        **y** - is window field that used to spesify the window y position
        **border** - border style of the window
        **backgroundColor** - background color of the window
        **foregroundColor** - foreground color of the window (border color)
        **style** - is Text type component field to spesify text style

        **dynamic** - Text type component field of type callback function that accept the window context and return string used to update the text dynamicly like update clock each frame
        **condition** - Window type component field of type callback function that accept the window context and return boolean used as condition to display the window or not

## how to create my own plugin      ?
- plugins are configured in **plugins** configuration section
- plugins is lua file that return a callback function with 4 params if the plugin are integrated to a specific window otherwise u can ignore them
- the return function of plugins returns VirtualTerminal object after you apply you configurations and add event listeners to it
- you need to initialize the VirtualTerminal object inside the returned callback function (why ?? : the engine use optimizations that means after he add all the components he clean thier memories to avoid memory junks)
- use global variables as plugin state the return function as update functionality for each frame
]]

local move_down = 0

local t = (function()
    local forRet = {}
    local line = ""
    for cha in tutorial:gmatch(".") do
        if cha == "\n" then
            table.insert(forRet, line)
            line = ""
        else
            line = line .. cha
        end
    end
    if line ~= "" then
        table.insert(forRet, line)
    end
    return forRet
end)()

-- function to wrap long lines based on width
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

-- function to parse and format bold text (**text**)
local function parseBoldText(text, defaultFgColor, defaultBgColor, defaultStyle)
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

                table.insert(result,
                    {
                        text = text:sub(endBold + 1, closeBoldStart - 1),
                        fg = defaultFgColor,
                        bg = defaultBgColor,
                        style =
                            api.TextStyle.Bold
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

return function(x, y, xx, yy)
    local w = xx - x - 1
    local h = yy - y - 1
    local vterm = api.VirtualTerminal.new()

    vterm:onKeyboard(function(key)
        if key == api.KEY_J or key == api.KEY_DOWN then
            move_down = move_down + 1
        elseif key == api.KEY_K or key == api.KEY_UP then
            move_down = math.max(0, move_down - 1) -- Prevent negative scrolling
        end
    end)

    vterm:addEventListener(api.EventType.TransformDataPut, function()
        return {
            UP = "k/key-up",
            DOWN = "j/key-down",
        }
    end)

    local totalLines = 0
    for _, originalLine in ipairs(t) do
        local wrappedLines = wrapLine(originalLine, w)
        totalLines = totalLines + #wrappedLines
    end

    move_down = math.min(move_down, math.max(0, totalLines - h))

    local lineIndex = 1
    local displayLineNumber = 1
    for _, originalLine in ipairs(t) do
        local wrappedLines = wrapLine(originalLine, w)

        for _, line in ipairs(wrappedLines) do
            if displayLineNumber > move_down then
                if (displayLineNumber - move_down) <= h then
                    local displayY = y + (displayLineNumber - move_down - 1)

                    if line:match("^%s*#") then
                        local formattedParts = parseBoldText(line, api.FGColors.Brights.Yellow, nil, api.TextStyle.Bold)
                        local xPos = x + 1
                        for _, part in ipairs(formattedParts) do
                            vterm:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg, part.bg,
                                part.style)
                            xPos = xPos + #part.text
                        end
                    elseif line:match("^%s*$") then
                        -- empty lines
                        -- skip empty lines or handle as needed
                    elseif line:match("^%s*-") then
                        local bullet_text = line:match("^%s*-%s*(.*)")
                        if bullet_text then
                            vterm:writeTextClipped(x + 1, displayY, "-", w, api.FGColors.Brights.Red)

                            local formattedParts = parseBoldText(" " .. bullet_text, api.FGColors.Brights.White, nil, nil)
                            local xPos = x + 2
                            for _, part in ipairs(formattedParts) do
                                vterm:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg, part.bg,
                                    part.style)
                                xPos = xPos + #part.text
                            end
                        else
                            local formattedParts = parseBoldText(line, api.FGColors.Brights.White, nil, nil)
                            local xPos = x + 1
                            for _, part in ipairs(formattedParts) do
                                vterm:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg, part.bg,
                                    part.style)
                                xPos = xPos + #part.text
                            end
                        end
                    else
                        local formattedParts = parseBoldText(line, api.FGColors.Brights.White, nil, nil)
                        local xPos = x + 1
                        for _, part in ipairs(formattedParts) do
                            vterm:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg, part.bg,
                                part.style)
                            xPos = xPos + #part.text
                        end
                    end
                end
            end
            displayLineNumber = displayLineNumber + 1
        end
    end
    return vterm
end

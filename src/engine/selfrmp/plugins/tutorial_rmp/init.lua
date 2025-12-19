local api = require("rmp.rmp")

local tutorial = [[
# Welcome To RayMp
## What is RayMp ?
**RMP (Ray Music Player)** is a high-performance, extensible framework built in C with Lua scripting for creating sophisticated terminal user interfaces. Originally conceived as a music player, RMP has evolved into a comprehensive platform for terminal-based applications, featuring:

- 🎵 **Advanced Music Player** - Multi-format audio support
- 📱 **Rich TUI Framework** - Create complex terminal interfaces with ease
- 🎮 **Game Development Platform** - Build 2D games directly in the terminal
- 🔧 **Extensible Plugin System** - Modular architecture for unlimited customization
- 🎨 **Dynamic Theming Engine** - Hot-swappable themes with Lua scripting
- ⚡ **High Performance** - Native C engine with Lua binding for optimal speed

## What's the difference between RMP and RayMp?
- **RayMp** is a software platform that renders templates and plugins with user configurations for a better audio experience using the **RMP** framework
- **RMP** is a framework with multiple classes and functions that uses C as a backend for better performance. It is used to create templates and plugins for the RayMp software and is also powerful for creating TUI applications in Lua

## How it works ?
- The **RayMp** engine creates a **Frame** (mother virtual-terminal) that connects all **VirtualTerminals** components and their **Events** together
- Plugins return a **VirtualTerminal** object with changes applied for each frame and their own **Event** listeners. The engine adds the **VirtualTerminal** plugin to it and applies it to the main screen
- All these classes are located in the **RMP framework**, which will be installed by default when you install the RayMp software

## Configuration structure:
- The **RayMp** engine checks the **~/.rmp** directory **(~ => HOME DIR)**. The structure of the .rmp directory is:
- **init.lua** - Configuration of the engine, sound keymaps, rendered templates, and plugin configurations
- **themes**   - Directory of templates that we created or downloaded from the plugin manager. The directory contains names of templates that we choose in the init.lua configuration file
- **plugins**  - Directory of plugins that we created or downloaded from the plugin manager. The directory contains subdirectories of plugins that we load and configure into the configuration file

## How to configure my music player ?
- First, open the ~/.rmp directory in your text editor
- Open the **init.lua** configuration file. **init.lua** returns a table with multiple keys:
    **settings** - Engine settings that are loaded when RayMp starts
        **fps** - Engine FPS rendered
        **help_key** - Engine has its own help window configured with this field
        **volume** - The default volume the engine starts with
        **speed** - The default speed the engine starts with
        **mode** - The default mode the engine starts with
        **restart_engine** - Key used to restart the whole engine
        **exit** - Key used to exit from the software
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
    **template** - Template name for rendering
    **plugins** - Plugins is a table of plugins that are wrapped in tables
        **themeWindowId** - The ID of the window in the template that is used to integrate plugins for a specific window in the template **(OPTIONAL)**. If the field is nil or not selected, the plugin can access the whole window
        **isActivated** - Boolean field: true to use the plugin, false to ignore it
        **names** - Table field that accepts multiple plugins
            Why? : A window can use multiple plugins (for example, animations and more), so we can apply more than 1 plugin to the same window
        **switchPluginKey** - This plugin is optional and used for switching multiple plugins in a window
    }
```lua
return {
    settings = {
        fps = 60,
        help_key = api.KEY_H,
        volume = 0.5,                 -- 0 to 1
        speed = 1.0,                  -- 0.25 to 4.0
        mode = api.PlaybackMode.ONES, -- playback modes
        restart_engine = api.KEY_CTRL_R,
        exit = api.KEY_Q,

        -- inc or dec
        inc_speed = 0.1,
        inc_volume = 0.1,
        inc_seek = 5
    },
    soundMap = {
        pause_sound = api.KEY_SPACE,
        resume_sound = api.KEY_SPACE,
        next_sound = api.KEY_N,
        prev_sound = api.KEY_P,
        vol_up = api.KEY_PLUS,
        vol_down = api.KEY_MINUS,
        seek_left = api.KEY_LEFT,
        seek_right = api.KEY_RIGHT,
        speed_up = api.KEY_UP,
        speed_down = api.KEY_DOWN,
        change_playback_mode = api.KEY_TAB
    },

    template = current_template,
    plugins = {
            {
                themewindowid = "tutorial-window",
                isactivated = true,
                names = {
                    "tutorial_rmp"
                }
            },
            {
                themewindowid = "helper-window",
                isactivated = true,
                names = {
                    "helper_keys_tutorial"
                }
            },
    }
}
```
## How to create my own template ?
- To create your own template, you have to put your init.lua template file in the **~/.rmp.themes** directory. Choose your template name **(for example foo.lua)**
- **foo.lua** returns a table with multiple tables that represent components or windows for each table
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
return {
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
## How to create my own plugin ?
- Plugins are configured in the **plugins** configuration section
- Plugins are Lua files that return a callback function with 4 parameters if the plugin is integrated into a specific window; otherwise, you can ignore them
- The return function of plugins returns a VirtualTerminal object after you apply your configurations and add event listeners to it
- You need to initialize the VirtualTerminal object inside the returned callback function (Why? : The engine uses optimizations, which means after it adds all the components, it cleans their memories to avoid memory leaks)
- Use global variables as plugin state and the return function as update functionality for each frame

## Code Examples
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

    return vterm
end
```

]]

local move_down = 0

-- Process tutorial text to handle code blocks and other formatting
local t = (function()
    local lines = {}
    local currentLine = ""
    local inCodeBlock = false
    local codeBlockContent = ""

    -- Split the tutorial into lines first
    for line in tutorial:gmatch("([^\n]*)\n?") do
        if line:match("^```") then
            if not inCodeBlock then
                -- Starting a code block
                if currentLine ~= "" then
                    table.insert(lines, currentLine)
                    currentLine = ""
                end
                inCodeBlock = true
                -- Add a marker for the start of the code block
                table.insert(lines, "```START_CODE_BLOCK```")
            else
                -- Ending a code block
                inCodeBlock = false
                -- Add a marker for the end of the code block
                table.insert(lines, "```END_CODE_BLOCK```")
                currentLine = ""
            end
        else
            if inCodeBlock then
                -- Inside a code block, add the line as code
                table.insert(lines, "CODE:" .. line)
            else
                -- Outside a code block, add the line normally
                table.insert(lines, line)
            end
        end
    end

    -- Add the last line if it doesn't end with \n
    if currentLine ~= "" and not inCodeBlock then
        table.insert(lines, currentLine)
    end

    return lines
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

-- function to parse and format bold text (**text**) - only handles inline formatting
local function parseFormattedText(text, defaultFgColor, defaultBgColor, defaultStyle)
    local result = {}
    local pos = 1
    local currentText = ""

    while pos <= #text do
        local startBold, endBold = text:find("%*%*", pos)

        if startBold then
            -- Add text before bold marker
            if startBold > pos then
                currentText = currentText .. text:sub(pos, startBold - 1)
            end

            -- Find the closing bold marker
            local closeStart = endBold + 1
            local closeBoldStart, closeBoldEnd = text:find("%*%*", closeStart)

            if closeBoldStart then
                -- Add the bold segment
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
                -- No closing marker found, treat opening markers as regular text
                currentText = currentText .. text:sub(startBold, endBold)
                pos = endBold + 1
            end
        else
            -- No more bold markers, add the rest of the text
            currentText = currentText .. text:sub(pos)
            pos = #text + 1
        end
    end

    -- Add any remaining text
    if currentText ~= "" then
        table.insert(result, { text = currentText, fg = defaultFgColor, bg = defaultBgColor, style = defaultStyle })
    end

    return result
end

-- Function to perform syntax highlighting on Lua code
local function syntaxHighlightLua(codeLine)
    local tokens = {}
    local pos = 1
    local currentText = ""

    -- Lua keywords
    local keywords = {
        "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
        "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
        "true", "until", "while", "require", "local"
    }

    -- Create a set of keywords for faster lookup
    local keywordSet = {}
    for _, kw in ipairs(keywords) do
        keywordSet[kw] = true
    end

    while pos <= #codeLine do
        local char = codeLine:sub(pos, pos)

        -- Check for string literals
        if char == '"' or char == "'" then
            -- Add any accumulated text before the string
            if currentText ~= "" then
                table.insert(tokens, { text = currentText, color = api.FGColors.Brights.White, style = nil })
                currentText = ""
            end

            -- Find the end of the string
            local startQuote = char
            local inEscape = false
            local stringStart = pos
            pos = pos + 1 -- Move past the opening quote

            while pos <= #codeLine do
                char = codeLine:sub(pos, pos)
                if inEscape then
                    inEscape = false
                elseif char == startQuote then
                    break -- Found the closing quote
                elseif char == "\\" then
                    inEscape = true
                end
                pos = pos + 1
            end

            -- Add the string token
            local stringText = codeLine:sub(stringStart, pos - 1)
            table.insert(tokens, { text = stringText, color = api.FGColors.Brights.Green, style = nil })
            -- Check for comments
        elseif char == "-" and codeLine:sub(pos + 1, pos + 1) == "-" then
            -- Add any accumulated text before the comment
            if currentText ~= "" then
                table.insert(tokens, { text = currentText, color = api.FGColors.Brights.White, style = nil })
                currentText = ""
            end

            -- Find the end of the line for single-line comment
            local commentStart = pos
            while pos <= #codeLine and codeLine:sub(pos, pos) ~= "\n" do
                pos = pos + 1
            end

            -- Add the comment token
            local commentText = codeLine:sub(commentStart, pos - 1)
            table.insert(tokens, { text = commentText, color = api.FGColors.Brights.Blue, style = api.TextStyle.Italic })
            -- Check for numbers
        elseif char:match("[%d]") then
            -- Add any accumulated text before the number
            if currentText ~= "" then
                table.insert(tokens, { text = currentText, color = api.FGColors.Brights.White, style = nil })
                currentText = ""
            end

            -- Find the end of the number
            local numberStart = pos
            pos = pos + 1
            while pos <= #codeLine do
                local nextChar = codeLine:sub(pos, pos)
                if not nextChar:match("[%d%.xXa-fA-F]") then
                    break
                end
                pos = pos + 1
            end

            -- Add the number token
            local numberText = codeLine:sub(numberStart, pos - 1)
            table.insert(tokens, { text = numberText, color = api.FGColors.Brights.Magenta, style = nil })
            -- Check for identifiers and keywords
        elseif char:match("[%a_]") then
            -- Add any accumulated text before the identifier
            if currentText ~= "" then
                table.insert(tokens, { text = currentText, color = api.FGColors.Brights.White, style = nil })
                currentText = ""
            end

            -- Find the end of the identifier
            local identStart = pos
            pos = pos + 1
            while pos <= #codeLine do
                local nextChar = codeLine:sub(pos, pos)
                if not nextChar:match("[%w_]") then
                    break
                end
                pos = pos + 1
            end

            -- Check if it's a keyword
            local identText = codeLine:sub(identStart, pos - 1)
            if keywordSet[identText] then
                table.insert(tokens,
                    { text = identText, color = api.FGColors.Brights.Yellow, style = api.TextStyle.Bold })
            else
                table.insert(tokens, { text = identText, color = api.FGColors.Brights.White, style = nil })
            end
        else
            -- Regular character
            currentText = currentText .. char
            pos = pos + 1
        end
    end

    -- Add any remaining text
    if currentText ~= "" then
        table.insert(tokens, { text = currentText, color = api.FGColors.Brights.White, style = nil })
    end

    return tokens
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
                            vterm:writeTextClipped(xPos, displayY, token.text, w - (xPos - x - 1), token.color,
                                nil, token.style)
                            xPos = xPos + #token.text
                        end
                    elseif line:match("^%s*#") then
                        local formattedParts = parseFormattedText(line, api.FGColors.Brights.Yellow, nil,
                            api.TextStyle.Bold)
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

                            local formattedParts = parseFormattedText(" " .. bullet_text, api.FGColors.Brights.White, nil,
                                nil)
                            local xPos = x + 2
                            for _, part in ipairs(formattedParts) do
                                vterm:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg, part.bg,
                                    part.style)
                                xPos = xPos + #part.text
                            end
                        else
                            local formattedParts = parseFormattedText(line, api.FGColors.Brights.White, nil, nil)
                            local xPos = x + 1
                            for _, part in ipairs(formattedParts) do
                                vterm:writeTextClipped(xPos, displayY, part.text, w - (xPos - x - 1), part.fg, part.bg,
                                    part.style)
                                xPos = xPos + #part.text
                            end
                        end
                    else
                        local formattedParts = parseFormattedText(line, api.FGColors.Brights.White, nil, nil)
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

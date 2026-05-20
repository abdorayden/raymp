# 🎵 RMP - Ray Media Platform

<p align="center">
  <img src="./assets/logo.jpg" width="300" height="300" alt="RMP Logo"/>
</p>

<p align="center">
  <strong>A High-Performance Lua Framework for Terminal Applications</strong>
</p>

<p align="center">
  <a href="#installation">🚀 Quick Start</a> •
  <a href="#demo">🎬 Demos</a> •
  <a href="#usage-examples">📖 Examples</a> •
  <a href="#api-reference">📚 API Docs</a> •
  <a href="#contributing">🤝 Contribute</a>
</p>

<p align="center">
  🎵 Music Player | 🎨 Custom Themes | 🔌 Plugin System | 🎮 2D Games | 📱 TUI Applications
</p>

[![GitHub](https://img.shields.io/badge/license-MIT-blue.svg)](LICENCE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)](README.md)
[![Language](https://img.shields.io/badge/language-C%20%7C%20Lua-orange)](README.md)

---

## ✨ What is RMP?

**RMP (Ray Music Player)** is a high-performance, extensible framework built in C with Lua scripting for creating sophisticated terminal user interfaces. Originally conceived as a music player, RMP has evolved into a comprehensive platform for terminal-based applications, featuring:

- 🎵 **Advanced Music Player** - Multi-format audio support with real-time visualization
- 📱 **Rich TUI Framework** - Create complex terminal interfaces with ease  
- 🎮 **Game Development Platform** - Build 2D games directly in the terminal
- 🔧 **Extensible Plugin System** - Modular architecture for unlimited customization
- 🎨 **Dynamic Theming Engine** - Hot-swappable themes with Lua scripting
- ⚡ **High Performance** - Native C engine with Lua binding for optimal speed

**Key Statistics:**
- 🔢 **140K+ lines of code** across C, Lua, and documentation
- 🏗️ **Modular Architecture** with separate engine and scripting layers
- 🌐 **Cross-Platform** support for Linux, macOS, and Windows
- 📦 **Self-Contained** - Ships with embedded Lua 5.4.4 engine

## 🚀 Key Features

### 🎨 **Advanced Theme System**
- **Hot-swappable themes** - Change entire UI appearance without restart
- **Lua-powered templates** - Full programmatic control over interface design
- **Dynamic content** - Real-time updates and interactive elements
- **Cross-platform rendering** - Consistent appearance across all platforms
- **Unicode support** - Rich visual elements with box drawing characters

### 🔌 **Robust Plugin Architecture**
- **Event-driven system** - React to user input, system events, and custom triggers
- **Isolated plugin contexts** - Plugins run in separate environments for stability
- **Inter-plugin communication** - Share data and events between plugins
- **Background services** - Run plugins independently of UI
- **Hot-reload support** - Update plugins without restarting application

### 🎵 **Professional Music Player**
- **Multi-format support** - MP3, WAV, FLAC, and more audio formats
- **Intelligent file browser** - Navigate music libraries with search and filtering
- **Advanced playback** - Queue management, shuffle, repeat, crossfade
- **Real-time controls** - Volume, seeking, speed, and equalizer controls
- **Audio visualization** - Waveform and spectrum analysis displays

### 🎮 **Game Development Platform**
- **Virtual terminal engine** - Advanced text-based graphics rendering
- **Input management** - Comprehensive keyboard and mouse handling
- **Animation framework** - Smooth animations with customizable frame rates
- **Collision detection** - Built-in physics utilities for game development
- **State management** - Efficient game state and scene management

### ⚡ **High-Performance Engine**
- **Native C core** - Optimized performance for complex terminal applications
- **Lua integration** - Seamless C-Lua binding with minimal overhead
- **Memory efficient** - Smart resource management and garbage collection
- **Asynchronous operations** - Non-blocking I/O for responsive interfaces

## 🎬 Demo

### 3D Cube Renderer
Experience real-time 3D graphics rendered entirely in terminal characters.

<video width="100%" controls>
  <source src="https://github.com/abdorayden/raymp/raw/refs/heads/master/assets/demo1_3dcube.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

### Digital Clock Widget
Animated digital clock with customizable themes and timezone support.

<video width="100%" controls>
  <source src="https://github.com/abdorayden/raymp/raw/refs/heads/master/assets/demo1_clock.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

## 🏗️ Architecture Overview

RMP follows a layered architecture designed for performance and extensibility:

```
┌─────────────────────────────────────────┐
│           Lua Application Layer         │
├─────────────────────────────────────────┤
│  Themes │ Plugins │ Templates │ Config  │
├─────────────────────────────────────────┤
│          RMP Framework (Lua)            │
├─────────────────────────────────────────┤
│           C Engine Core                 │
├─────────────────────────────────────────┤
│  Terminal │ Audio │ Input │ VirtualTerm │
└─────────────────────────────────────────┘
```

**Components:**
- **C Engine Core** - High-performance native operations
- **RMP Framework** - Lua-based application framework  
- **Plugin System** - Modular functionality extensions
- **Theme Engine** - Dynamic UI and layout management


## 📦 Installation

### Prerequisites

**Required Dependencies:**
```bash
# Debian/Ubuntu
sudo apt-get install gcc build-essential

# macOS (with Homebrew)
brew install gcc

# Windows (MSYS2/MinGW)
choco install gcc
# Install MinGW-w64 using chocolaty package manager
```

**Note:** RMP ships with an embedded Lua 5.4.4 engine - no external Lua installation required!

### Build from Source

#### Unix like build
```bash
git clone https://github.com/abdorayden/raymp.git
cd raymp/install
./install.sh compile -v && sudo ./install.sh install -v
cd ..
./rmp
```

#### Windows Build
```batch
git clone https://github.com/abdorayden/raymp.git
cd raymp\install
install.bat compile
install.bat install
cd ..
rmp.exe
```

### Verifying Installation

Test your installation with the built-in demos:
```bash
# Start the music player (default)
./rmp

# Check version and help
./rmp --version
./rmp --help
```

## ⚡ Quick Start

### 1. **Launch Default rmp templates**
```bash
./rmp
```
Navigate with arrow keys, press `Space` to play/pause, `Q` to quit.

### 2. **Create Your First TUI App with rmp framework only**
```lua
-- hello_world.lua
-- NOTE: rmp framework installed by rmp engine
local api = require("rmp.rmp")

local frame = api.Frame.new()
frame:setFps(60)

local window = api.Window.new(1):createWindow(
    "Hello RMP!", 40, 10, 5, 5, nil, nil, nil,
    function(x, y, w, h)
        return api.Text.new("Welcome to RMP Framework!", 
                           x+2, y+2, api.FGColors.Brights.Green)
    end
)

while true do
    frame:add(window)
    local key = api.Terminal:handleKey()
    if key == api.KEY_Q then break end
    frame:run(key)
end
```

### 3. **Load a Custom Theme**
```bash
cat ~/.rmp/init.lua # config file
# this is the place where u configure your rmp audio player
# the (themes/templates) are located in ~/.rmp/themes/ folder
# you can download or create you own template and add it to this path 
# and load it in init.lua config file
```

### 4. **Load a plugins**
```bash
cat ~/.rmp/init.lua # config file
# this is the place where u configure your rmp audio player
# the (plugins) are located in ~/.rmp/plugins/ folder
# you can download or create you own plugin and add it to this path 
# and load it in init.lua config file
```

## 🎯 Usage Examples

### 🎵 **Music Player (Default Mode)**
The default configuration provides a full-featured music player:
```lua
-- Default mode - just run ./rmp
-- Features included:
-- • File browser with music library scanning
-- • Playback controls (play, pause, seek, volume)
-- • Playlist management
-- • Audio format detection
-- • Keyboard shortcuts for all functions
```

### 📱 **Custom TUI Application**

```lua
-- multi_window_app.lua
local api = require("rmp.rmp")

-- Create application frame
local frame = api.Frame.new()
frame:setFps(60)

-- Main window with dynamic content
local mainWindow = api.Window.new(1):createWindow(
    "Multi-Window Demo", "w-4", "h-8", 2, 2, 
    api.BoxDrawing.LightBorder, api.BGColors.NoBrights.Black, nil,
    function(x, y, w, h)
        local vterm = api.VirtualTerminal.new()
        vterm:writeText(x+1, y+1, "Main Content Area", api.FGColors.Brights.White)
        vterm:writeText(x+1, y+3, "Press TAB to switch panels", api.FGColors.NoBrights.Yellow)
        return vterm
    end
)

-- Status bar
local statusWindow = api.Window.new(2):createWindow(
    nil, "w-2", 3, 1, "h-3",
    api.BoxDrawing.NoBorder, api.BGColors.NoBrights.Blue, nil,
    function(x, y, w, h)
        local vterm = api.VirtualTerminal.new()
        vterm:writeText(x+1, y+1, "Status: Ready", api.FGColors.Brights.White)
        return vterm
    end
)


-- Event loop
while true do
    frame:add(mainWindow)
    frame:add(statusWindow)
    local key = api.Terminal:handleKey()
    if key == api.KEY_Q then break end
    frame:run(key)
end
```

### 🎮 **2D Game Development**
```lua
-- simple_game.lua
local api = require("rmp.rmp")

local gameState = {
    playerX = 10, playerY = 5,
    enemies = {{x=20, y=8}, {x=30, y=12}},
    score = 0
}

local frame = api.Frame.new()
frame:setFps(30)  -- 30 FPS for smooth gameplay

local gameWindow = api.Window.new(1):createWindow(
    "RMP Game Engine Demo", 60, 20, 5, 2,
    api.BoxDrawing.DoubleBorder, api.BGColors.NoBrights.Black, nil,
    function(x, y, w, h)
        local vterm = api.VirtualTerminal.new()
        
        -- Draw player
        vterm:writeText(x + gameState.playerX, y + gameState.playerY, 
                       "@", api.FGColors.Brights.Green)
        
        -- Draw enemies
        for _, enemy in ipairs(gameState.enemies) do
            vterm:writeText(x + enemy.x, y + enemy.y, 
                           "X", api.FGColors.Brights.Red)
        end
        
        -- Draw HUD
        vterm:writeText(x+1, y+1, "Score: " .. gameState.score, 
                       api.FGColors.Brights.Yellow)
        
        return vterm
    end
)

-- Game input handling
gameWindow:addEventListener(api.EventType.Keyboard, function(key)
    if key == api.KEY_W then
        gameState.playerY = math.max(1, gameState.playerY - 1)
    elseif key == api.KEY_S then
        gameState.playerY = math.min(18, gameState.playerY + 1)
    elseif key == api.KEY_A then
        gameState.playerX = math.max(1, gameState.playerX - 1)
    elseif key == api.KEY_D then
        gameState.playerX = math.min(58, gameState.playerX + 1)
    end
end)


-- Game loop
while true do
    local key = api.Terminal:handleKey()
    if key == api.KEY_Q then break end
    
    frame:add(gameWindow)
    -- Update game state here (enemy movement, collision detection, etc.)
    
    frame:run(key)
end
```
## 🎨 (Theme/Template) Development

RMP's (theme/Template) system allows complete customization of the user interface through Lua templates.

### Creating a Custom (Theme/Template)
```lua
-- themes/cyberpunk_theme.lua
-- Cyberpunk-inspired theme with neon colors and futuristic elements
-- the template lua file are returned a table with tables that has a different id's and types 

local api = require("rmp.rmp")

return {
    -- main window with a children
    {
        id = 1,
        type = "Window",
        title = {
            type = "Text",
            value = "▋█▊ RMP CYBERPUNK ▊█▋",
            foregroundColor = api.FGColors.Brights.Magenta,
            backgroundColor = api.BGColors.NoBrights.Black,
            style = api.TextStyle.Bold
        },
        width = "w",
        height = "h", 
        x = 1,
        y = 1,
        border = api.BoxDrawing.DoubleBorder,
        backgroundColor = api.BGColors.NoBrights.Black,
        children = {
            -- Header with animated elements
            {
                id = 2,
                type = "Window",
                title = {
                    type = "Text",
                    value = "",
                    dynamic = function(ctx)
                        -- ctx table for the self object
                        local time = os.date("%H:%M:%S")
                        return "⚡ NEURAL INTERFACE ACTIVE ⚡ " .. time
                    end,
                    foregroundColor = api.FGColors.Brights.Cyan,
                    backgroundColor = api.BGColors.NoBrights.Magenta,
                    style = api.TextStyle.Bold,
                },
                width = "w - 2",
                height = 4,
                x = 2,
                y = 2,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Magenta
            },
            
            -- Main content area
            {
                id = 3,
                type = "Window", 
                title = {
                    type = "Text",
                    value = "◢█◣ MAIN MATRIX ◤█◥",
                    foregroundColor = api.FGColors.Brights.Green,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = "w - 4",
                height = "h - 12",
                x = 3,
                y = 7,
                border = api.BoxDrawing.HeavyBorder,
                backgroundColor = api.BGColors.NoBrights.Black
            },
            
            -- Status/info panel
            {
                id = 4,
                type = "Window",
                title = {
                    type = "Text", 
                    value = function()
                        return "⚠ SYSTEM STATUS: ONLINE ⚠"
                    end,
                    foregroundColor = api.FGColors.Brights.Yellow,
                    backgroundColor = api.BGColors.NoBrights.Red,
                    style = api.TextStyle.Bold,
                    dynamic = true
                },
                width = "w - 2",
                height = 4,
                x = 2,
                y = "h - 5",
                border = api.BoxDrawing.NoBorder,
                backgroundColor = api.BGColors.NoBrights.Red
            }
        }
    }
}
```

## 🔌 Plugin Development

RMP's plugin system enables modular functionality through isolated Lua contexts.

### Creating a Basic Plugin
```lua
-- plugins/system_monitor.lua
-- Real-time system monitoring plugin
-- the plugin lua file are returned function that accept 4 params and return VirtualTerminal object

local api = require("rmp.rmp")

-- params:
--  x,y : left top corner position (x position and y position)
--  xx,yy : right bottom corner position
-- return: 
--      VirtualTerminal
local vterm = api.VirtualTerminal.new()
return function(x, y, xx, yy)
    local w = xx - x - 1
    local h = yy - y - 1

    -- Plugin state
    local updateInterval = 1.0  -- seconds
    local lastUpdate = 0
    local systemData = {}
    
    -- Update system information
    local function updateSystemInfo()
        local currentTime = os.time()
        if currentTime - lastUpdate >= updateInterval then
            -- Get system info (simplified example)
            systemData = {
                time = os.date("%Y-%m-%d %H:%M:%S"),
                memory = "Memory: 4.2GB / 8.0GB",
                cpu = "CPU: 15.3%",
                processes = "Processes: 156"
            }
            lastUpdate = currentTime
        end
    end
    
    -- Render plugin content
    local function render()
        vterm:clear()
        updateSystemInfo()
        
        -- Header
        vterm:writeText(x, y, "═══ SYSTEM MONITOR ═══", 
                       api.FGColors.Brights.Cyan)
        
        -- System information
        local line = y + 2
        for key, value in pairs(systemData) do
            vterm:writeText(x, line, value, api.FGColors.NoBrights.White)
            line = line + 1
        end
        
        -- Instructions
        vterm:writeText(x, yy - 2, "Press 'R' to refresh", 
                       api.FGColors.NoBrights.Yellow)
    end
    
    -- Event handlers
    vterm:onKeyboard(function(key)
        if key == api.KEY_R then
            lastUpdate = 0  -- Force refresh
            render()
        end
    end)
    
    -- Initial render
    render()
    
    return vterm
end
```

### Plugin Registration and Configuration
```lua
-- In your theme or main configuration
-- ~/.rmp/init.lua
return {
    -- the default configuration of the sound
    settings = {
        fps = 60,
        volume = 0.5,           -- 0 to 1
        speed = 1.0,            -- 0.25 to 4.0
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
    template = "<your template lua file name without extension>",
    -- plugins
    plugins = {        
        {
            -- if this attr is not nil or exists , the runner ignore activate
            themeWindowId = 2, -- the window id that the plugin injected in
            isActivated = true,-- isActivated (true activated by default otherwise is not)
            activate = api.KEY_E, -- toggle key for activation plugin
            switchPluginKey = api.KEY_I, -- switch key for multiple plugins that integrated on the same window id
            names = { -- plugins
                -- examples
                "matrix_digital_rain_effect",
                "music_waves",
                "text_editor",
                "tellme_yourname",
                "digital_clock_with_effects",
                "3d_cube",
                "filebrowser"
            }

        },
        {
            themeWindowId = 3,
            isActivated = true,
            activate = api.KEY_E,
            names = {
                "center_text"
            }
        },
        {
            isActivated = false,
            activate = api.KEY_O,
            names = {
                "other plugins"
            }
        }
    }
}

```

## 🎮 Game Development Guide

RMP provides a complete framework for developing 2D games in the terminal.

### Game Engine Features
- **Frame-based rendering** with customizable FPS (1-120 FPS)
- **Event-driven input system** supporting all keyboard keys
- **Animation systems** for smooth character and object movement
- **State management** for complex game scenes
- **Audio integration** for sound effects and background music

## 🌍 Cross-Platform Support

RMP is designed for maximum compatibility across operating systems and terminal environments.

### Supported Platforms
- ✅ **Linux** (Debian, Ubuntu, Arch, CentOS, Fedora)
- ✅ **macOS** (Intel and Apple Silicon M1/M2)
- ✅ **Windows** (MinGW, MSYS2, WSL, Cygwin)
- ✅ **FreeBSD** and other Unix-like systems

### Terminal Compatibility
- ✅ **Modern terminals** (Alacritty, Kitty, iTerm2, Windows Terminal)
- ✅ **Traditional terminals** (xterm, GNOME Terminal, Konsole)

### Platform-Specific Features
```c
// Platform detection in C engine
#ifdef _WIN32
    #define PLATFORM_WINDOWS
    #define PATH_SEPARATOR "\\"
#elif defined(__APPLE__)
    #define PLATFORM_MACOS
    #define PATH_SEPARATOR "/"
#elif defined(__linux__)
    #define PLATFORM_LINUX
    #define PATH_SEPARATOR "/"
#endif
```

## 📚 Comprehensive API Reference

### Core Framework Classes

#### `api.Frame`
Main application frame and event loop management.
hight level class for rendering the frame
```lua
local frame = api.Frame.new()
frame:setFps(60)                    -- Set target FPS (1-120)
frame:add(frame)                    -- Add VirtualTerminal or Frame to it
frame:run(keyEvent)                 -- Process single frame
```

#### `api.Window`
Window management and layout system.
```lua
local window = api.Window.new(id)
window:createWindow(title, width, height, x, y, border, bgColor, fgColor, contentFunction)
window:setTitle(title)              -- Update window title
window:resize(w, h)                 -- Resize window
window:move(x, y)                   -- Move window position
```

#### `api.Terminal`
Low-level terminal control and input handling.
```lua
api.Terminal:clear()                -- Clear entire screen
api.Terminal:setCursor(x, y)        -- Move cursor position
api.Terminal:hideCursor()           -- Hide cursor
api.Terminal:showCursor()           -- Show cursor
local key = api.Terminal:handleKey() -- Get pressed key (non-blocking)
api.Terminal:getSize()              -- Get terminal dimensions
```

#### `api.VirtualTerminal`
Advanced text rendering and virtual screen buffer.
```lua
local vterm = api.VirtualTerminal.new()
vterm:writeText(x, y, text, color)  -- Write colored text
vterm:drawBox(x, y, w, h, border, color)   -- Draw bordered box
vterm:clear()                       -- Clear virtual buffer
vterm:addEventListener(EventType, callback)       -- Add event handler
```

#### `api.Text`
Rich text rendering with styles and colors.
```lua
local text = api.Text.new(content, x, y, fgColor, bgColor, style)
text:getText()         -- Update text content
text:getPosition()     -- Move text position
text:getColor()        -- Change text colors
text:getStyle()        -- Apply text style
```

### Audio System

#### `api.Audio`
Audio playback and control for music and sound effects.
```lua
api.Audio:load(filename)            -- Load audio file
api.Audio:play()                    -- Start playback
api.Audio:pause()                   -- Pause playback
api.Audio:stop()                    -- Stop playback
api.Audio:setVolume(level)          -- Set volume (0.0-1.0)
api.Audio:seek(position)            -- Seek to position in seconds
api.Audio:getPosition()             -- Get current playback position
api.Audio:getDuration()             -- Get total track duration
```

### Color Constants

#### Foreground Colors
```lua
-- Bright colors
api.FGColors.Brights.Black
api.FGColors.Brights.Red
api.FGColors.Brights.Green
api.FGColors.Brights.Yellow
api.FGColors.Brights.Blue
api.FGColors.Brights.Magenta
api.FGColors.Brights.Cyan
api.FGColors.Brights.White

-- Normal colors  
api.FGColors.NoBrights.Black
api.FGColors.NoBrights.Red
-- ... (similar pattern)
```

#### Background Colors
```lua
-- Background colors (similar structure)
api.BGColors.Brights.Black
api.BGColors.NoBrights.Red
-- ... etc
```

#### Colors From Hex

```lua
api.colorFromHex("ff0000" , api.FG) -- forground color
api.colorFromHex("ff0000" , api.BG) -- background color
```

### Text Styles and Drawing

#### Text Styles
```lua
api.TextStyle.Normal                -- Normal text
api.TextStyle.Bold                  -- Bold text
api.TextStyle.Italic                -- Italic text
api.TextStyle.Underline             -- Underlined text
api.TextStyle.Strikethrough         -- Strikethrough text
```

#### Box Drawing Characters
```lua
api.BoxDrawing.NoBorder             -- No border
api.BoxDrawing.LightBorder          -- Light single line border
api.BoxDrawing.HeavyBorder          -- Heavy single line border  
api.BoxDrawing.RoundedBorder        -- Rounded corner border
```

### Input Handling

#### Key Constants
```lua
-- Letter keys
api.KEY_A, api.KEY_B, ..., api.KEY_Z

-- Number keys
api.KEY_0, api.KEY_1, ..., api.KEY_9

-- Special keys
api.KEY_SPACE                       -- Space bar
api.KEY_ENTER                       -- Enter/Return
api.KEY_TAB                         -- Tab
api.KEY_ESC                         -- Escape
api.KEY_BACKSPACE                   -- Backspace
api.KEY_DELETE                      -- Delete

-- Arrow keys
api.KEY_UP                          -- Up arrow
api.KEY_DOWN                        -- Down arrow 
api.KEY_LEFT                        -- Left arrow
api.KEY_RIGHT                       -- Right arrow

-- Modifier keys
api.KEY_CTRL_A, api.KEY_CTRL_B, ... -- Ctrl combinations
```

### check the docs from [RMP Framework](https://rayden-six.vercel.app/raymp/framework)

## 🐛 Troubleshooting

### Common Issues

#### **Build Errors**
```bash
# Error: Permission denied during install
# Solution: Use sudo for system installation
sudo ./install.sh install -v

# Error: gcc not found
# Solution: Install build tools
sudo apt-get install build-essential gcc
```

## 🤝 Contributing

We welcome contributions from developers of all skill levels! Here's how to get involved:

### Code Style Guidelines
- **C Code**: Follow Linux kernel coding style
- **Lua Code**: Use 4-space indentation, descriptive variable names
- **Comments**: Document complex algorithms and public APIs
- **Testing**: Add tests for new features when possible

### Contribution Areas
- 🎨 **Theme Development** - Create new visual themes
- 🔌 **Plugin Development** - Build plugins for new functionality  
- 🎮 **Game Development** - Create example games and demos
- 📚 **Documentation** - Improve guides and API documentation
- 🐛 **Bug Fixes** - Fix issues and improve stability
- ⚡ **Performance** - Optimize engine and framework code

### Submitting Changes
1. **Create descriptive commits**
   ```bash
   git commit -m "feat: add cyberpunk theme with animations"
   git commit -m "fix: resolve memory leak in audio engine" 
   git commit -m "docs: improve plugin development guide"
   ```

2. **Test thoroughly**
   ```bash
   # Run existing tests
   ./rmp --run-tests
   
   # Test on multiple platforms if possible
   # Test with different terminal emulators
   ```

3. **Submit pull request**
   - Describe changes clearly
   - Link to related issues
   - Include screenshots/videos for visual changes

### Reporting Issues
Please use GitHub Issues for bug reports and feature requests:
- **Bug reports**: Include system info, steps to reproduce, expected vs actual behavior
- **Feature requests**: Describe use case, proposed solution, and alternatives considered

For more details, see our [Contributing Guide](CONTRIBUTIONS.md).

## 📄 License

see the [LICENCE](LICENCE) file for details.

## 🙏 Acknowledgments

RMP is built on the shoulders of amazing open-source projects:

- **[Lua 5.4.4](https://www.lua.org/)** - Embedded scripting language
- **[Miniaudio](https://github.com/mackron/miniaudio)** - Cross-platform audio library
- **GCC/Clang** - C compiler toolchains
- **Terminal emulator developers** - For advancing terminal capabilities

Special thanks to the terminal application community for inspiration and feedback.

## 🚀 What's Next?

### Upcoming Features (Roadmap)
- 🖱️ **Mouse Support** - Full mouse interaction support
- 🌐 **Network Support** - TCP/UDP networking for multiplayer games
- 🎨 **Advanced Graphics** - Improved rendering with better Unicode support
- 🔌 **Plugin Marketplace** - Online repository for themes and plugins
- 📊 **Performance Profiler** - Built-in performance analysis tools

### Getting Involved
- ⭐ **Star the repository** to show support
- 🐛 **Report bugs** to help improve stability
- 💡 **Suggest features** for future development
- 🤝 **Contribute code** to help build the future of terminal applications

---

<p align="center">
  <strong>🎵 Start creating amazing terminal applications with RMP today! 🎵</strong>
</p>

<p align="center">
  <a href="#installation">🚀 Quick Start</a> •
  <a href="#usage-examples">📖 Examples</a> •
  <a href="#api-reference">📚 API Docs</a> •
  <a href="#contributing">🤝 Contribute</a> •
  <a href="https://github.com/abdorayden/raymp">⭐ GitHub</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Made%20with-❤️%20and%20C-red.svg" alt="Made with love and C"/>
</p>

---

# Replace lua with rdn

---

## Memory Safety Review (2026-02-16)

This report summarizes a targeted review of memory leaks and unbounded growth risks in the RMP engine and selected plugins/templates.

**Findings (Most Severe First)**
1. Unbounded growth of keyboard/mouse event queues when no input arrives. A new keyboard callback is enqueued every frame in `RMPManager.lua`, and queues are only drained when input exists. This can grow without bound during idle periods. Affected files: `src/engine/RMPManager.lua`, `src/engine/core/rmp.lua`.
2. Same queue growth pattern in plugins (example: tutorial). The tutorial plugin registers a keyboard handler each frame, and those callbacks are merged into the main frame. If no input arrives, callbacks accumulate. Affected file: `src/engine/builtin/plugins/tutorial_rmp/init.lua`.
3. Native VT leak in `VirtualTerminal:copy`. `RMP.VirtualTerminal:copy()` allocates a native buffer in the constructor, then overwrites `native_vt_rmp` with a new native copy without freeing the original. Affected file: `src/engine/core/rmp.lua`.
4. Potential cache growth in `TemplateParser.compiledExpressions`. Cache keys include context values and can grow without bound if context values vary frequently. Affected file: `src/engine/RMPManager.lua`.

**Things That Look OK**
1. `VirtualTerminal` buffers are freed in C via `vt_rmp.distroy`, and merge paths destroy temporary VTs when `distroy=true`.
2. `TemplateParser` window/plugin caches are bounded by the number of windows.

**Suggested Fix Directions**
1. Event queue growth: store persistent listener lists and iterate without popping for keyboard/mouse events, or clear those queues each frame before re-registering handlers.
2. `VirtualTerminal:copy` leak: avoid allocating a native buffer before replacing `native_vt_rmp`, or add a native-copy constructor path.

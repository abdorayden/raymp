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

### 3. **Load a Custom Template**
Templates are the window layouts. Users' templates are Lua files in
`~/.rmp/templates/<name>.lua` (if a template name is not found there it falls back
to the builtin templates). Select one by naming it in `~/.rmp/init.lua`:
```bash
mkdir -p ~/.rmp/templates
nano ~/.rmp/init.lua
```
```lua
-- ~/.rmp/init.lua
raymp.engine.template = "my_layout"   -- loads ~/.rmp/templates/my_layout.lua
```
You can also assign an inline table directly (see the Theme/Template section).

### 4. **Add Your Own Plugin**
Dropping a plugin module under `~/.rmp/plugins/` makes it available by name, then
you register it (and pick its activation/switch keys) through
`raymp.engine.plugins`:
```bash
mkdir -p ~/.rmp/plugins
nano ~/.rmp/init.lua
```
```lua
-- ~/.rmp/init.lua
raymp.engine.plugins = {
  {
    themeWindowId = "main",       -- Window.id from the template to inject into
    isActivated = true,
    names = { "my-plugin-rmp" },  -- module: ~/.rmp/plugins/my-plugin-rmp/init.lua
  },
}
```
See the Plugin Development section for the full `plugins` group format.

## 🎯 Usage Examples

### 🎵 **Music Player (Default Mode)**
Running `./rmp` with no `~/.rmp/init.lua` loads the builtin defaults
(`src/engine/builtin/init.lua`): the `"tutorial"` template with the
`tutorial_rmp`, `helper_keys_tutorial` and `matrix_digital_rain_effect` window
plugins, notification popups, all builtin themes, and the full playback keymap
below. The builtin config is **always loaded first** — a `~/.rmp/init.lua` only
overrides the values you want to change (vim/emacs style), so you can rebind keys
while keeping all the builtin plugins.

Builtin keymap (rebind any of these, see the Keymap Reference below):

| Key | Action |
|---|---|
| `Space` | Play / Pause |
| `N` / `P` | Next / Previous track |
| `+` / `-` | Volume up / down |
| `→` / `←` | Seek forward / backward |
| `↑` / `↓` | Speed up / down |
| `Tab` | Cycle playback mode |
| `H` | Help overlay |
| `M` | Logged messages / errors |
| `Ctrl+R` | Restart engine (reload config) |
| `Q` | Quit |

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
Templates are configuration files too: they populate `raymp.engine.template`
directly (returning the table is also merged for backward compatibility).
```lua
-- themes/cyberpunk_theme.lua
-- Cyberpunk-inspired theme with neon colors and futuristic elements

local api = require("rmp.rmp")

raymp.engine.template = {
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
Plugins are Lua modules returning a **callback that runs every frame**. The global
`raymp` (and its engine config, `raymp.engine`) is always available, so you
don't need a frame parameter. Window-attached plugins use
`return function(x, y, xx, yy)`; global plugins use `return function()`.
```lua
-- plugins/system_monitor.lua
-- Real-time system monitoring plugin

local api = require("rmp.rmp")

-- params:
--  x,y : left top corner position (x position and y position)
--  xx,yy : right bottom corner position
-- the global raymp is available: raymp:writeText(...),
-- raymp.engine.fps, raymp.engine.settings.volume, ...
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
Configuration files populate the global frame config — `raymp.engine` — directly
instead of returning a table. `raymp.engine.fps = 30` is shorthand for
`raymp.engine.settings.fps = 30`. Returning a table still works (it is merged
onto the engine config).
```lua
-- ~/.rmp/init.lua
-- the default configuration of the sound
raymp.engine.template = "my_template"

raymp.engine.settings.fps = 60
raymp.engine.volume = 0.5           -- 0 to 1
raymp.engine.speed = 1.0            -- 0.25 to 4.0
raymp.engine.mode = api.PlaybackMode.ONES -- playback modes
raymp.engine.restart_engine = api.KEY_CTRL_R
raymp.engine.exit = api.KEY_Q

-- inc or dec
raymp.engine.inc_speed = 0.1
raymp.engine.inc_volume = 0.1
raymp.engine.inc_seek = 5

-- sound keymaps
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

-- plugins
raymp.engine.plugins = {        
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
```

### Adding Your Own Plugins
1. Create `~/.rmp/plugins/<name>/init.lua` (any name), returning either
   `function(x, y, xx, yy)` (window-attached) or `function()` (global).
   `~/.rmp/plugins/` (5 levels deep) is added to the Lua require path, so the
   module resolves as `require("<name>")`.
2. Register it in `~/.rmp/init.lua`, appending or replacing the plugin groups:
   ```lua
   raymp.engine.plugins = {
     {
       themeWindowId = "main",       -- "main" matches Window.id in your template
       isActivated = true,           -- true = active on boot
       activate = api.KEY_E,         -- toggle the whole group on/off at runtime
       switchPluginKey = api.KEY_I,  -- cycle between plugins in this group
       priority = 0,                 -- lower loads first
       names = { "my-plugin-rmp" },  -- your module name (extension excluded)
     },
   }
   ```
3. A group without `themeWindowId` is a *global* plugin (drawn full-frame).

> ⚠️ Every frame the plugin is re-invoked with the window's inner rect
> `(x, y, xx, yy)`; keep your draw/state logic idempotent. Only window-attached
> plugins participate in hot-reload.

### ⚙️ Builtin Configuration Model
The builtin configuration is applied **first** on every startup (and on every
`restart_engine`), then `~/.rmp/init.lua` is layered on top. Builtin components
ship **enabled** and can be toggled through `raymp.engine.builtin`:

```lua
-- ~/.rmp/init.lua
raymp.engine.builtin = false                 -- master switch: disable ALL builtins

-- per-feature toggles (a missing flag defaults to ENABLED, so partial overrides are safe)
raymp.engine.builtin.help          = false   -- disable the help overlay (default H)
raymp.engine.builtin.notify        = true    -- notification popups
raymp.engine.builtin.themes        = false   -- disable the builtin theme plugins
raymp.engine.builtin.theme_manager = true    -- theme auto-selector plugin

-- disable individual builtin window plugins (used by the default template)
raymp.engine.builtin.plugins = {
    tutorial_rmp               = false,
    helper_keys_tutorial       = true,
    matrix_digital_rain_effect = true,
}
```

Setting `raymp.engine.builtin = false` (or any single flag/plugin to `false`)
gracefully skips the corresponding work in the engine; missing flags keep their
default of **enabled**.

### 🎹 Keymap Reference (change keys & templates)
The builtin defaults define every key. Override any of them — or disable one by
setting it to `nil` — in `~/.rmp/init.lua`:

```lua
-- ~/.rmp/init.lua
-- which template to render: "name" (user template, else builtin), or an inline table
raymp.engine.template = "tutorial"

-- playback / engine settings
raymp.engine.settings.fps     = 60      -- frames per second
raymp.engine.settings.volume  = 0.5     -- 0.0 - 1.0
raymp.engine.settings.speed   = 1.0     -- 0.01 - 3.0
raymp.engine.settings.mode    = api.PlaybackMode.ONES
raymp.engine.settings.freq_bins = 32    -- spectrum bands for visualization
raymp.engine.settings.theme   = "desert" -- "default"|"darkandwhite"|"desert"|"elflord"; nil disables
raymp.engine.settings.notify  = true    -- show notification popups

-- engine-level keys (nil disables that action)
raymp.engine.settings.exit          = api.KEY_Q
raymp.engine.settings.restart_engine = api.KEY_CTRL_R   -- reload config
raymp.engine.settings.help_key      = api.KEY_H          -- help overlay
raymp.engine.settings.messages_key  = api.KEY_M          -- message log
-- raymp.engine.settings.reload_key  = api.KEY_CTRL_R    -- plugin hot-reload (FEAT-1)

-- step sizes (how much the +/- keys change things)
raymp.engine.settings.inc_volume = 0.1
raymp.engine.settings.inc_speed  = 0.1
raymp.engine.settings.inc_seek   = 5    -- seconds

-- sound control keymap (all overrideable)
raymp.engine.soundMap.pause_sound  = api.KEY_SPACE
raymp.engine.soundMap.resume_sound = api.KEY_SPACE
raymp.engine.soundMap.next_sound   = api.KEY_N
raymp.engine.soundMap.prev_sound   = api.KEY_P
raymp.engine.soundMap.vol_up       = api.KEY_PLUS
raymp.engine.soundMap.vol_down     = api.KEY_MINUS
raymp.engine.soundMap.seek_left    = api.KEY_LEFT
raymp.engine.soundMap.seek_right   = api.KEY_RIGHT
raymp.engine.soundMap.speed_up     = api.KEY_UP
raymp.engine.soundMap.speed_down   = api.KEY_DOWN
raymp.engine.soundMap.change_playback_mode = api.KEY_TAB
```

**Template keys/shortcuts:** `raymp.engine.template` accepts (1) a string —
loaded from `~/.rmp/templates/<name>.lua`, falling back to the builtin templates
(e.g. the shipped `"tutorial"`, `"3_simple"`); or (2) an inline window table. Inside
the template, every window has an `id`; plugin groups bind to it via
`themeWindowId`. The `raymp.engine.fps = 60` shorthand writes
`raymp.engine.settings.fps = 60` — anything outside
`{template, settings, soundMap, plugins, builtin}` proxies into `settings`.

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

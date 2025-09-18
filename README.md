# 🎵 RMP - Ray Media Platform

<p align="center">
  <img src="./assets/logo.jpg" width="300" height="300" alt="RMP Logo"/>
</p>

<p align="center">
  <strong>A Powerful Lua Framework for Terminal Applications</strong>
</p>

<p align="center">
  🎵 Music Player | 🎨 Custom Themes | 🔌 Plugin System | 🎮 2D Games | 📱 TUI Applications
</p>

---

## ✨ What is RMP?

**RMP (Ray Music Player)** is more than just a music player—it's a comprehensive Lua framework for creating stunning terminal user interfaces. Born from the need for a beautiful, extensible music player, RMP has evolved into a powerful platform that enables developers to create:

- 🎵 **Custom Music Players** with beautiful themes
- 📱 **TUI Applications** with rich interfaces  
- 🎮 **Simple 2D Games** running directly in the terminal
- 🔧 **System Tools** with interactive interfaces
- 🎨 **Visual Applications** with cross-platform support

## 🚀 Key Features

### 🎨 **Theme System**
- **Hot-swappable themes** - Change the entire look without restarting
- **Lua-powered theming** - Full programmatic control over UI
- **Cross-platform compatibility** - Works on Linux, macOS, and Windows
- **Rich visual elements** - Unicode box drawing, colors, and animations

### 🔌 **Plugin Architecture**
- **Modular design** - Each feature as a separate plugin
- **Event-driven system** - React to user input and system events  
- **Easy integration** - Drop-in plugin support
- **Background services** - Run plugins independently

### 🎵 **Out-of-the-Box Music Player**
- **Multiple audio formats** - MP3, WAV, FLAC support
- **File explorer** - Navigate and play music intuitively
- **Playlist management** - Queue, shuffle, repeat
- **Real-time controls** - Volume, seeking, speed control

### 🎮 **Game Development Ready**
- **Virtual terminal** - Advanced text-based graphics
- **Input handling** - Keyboard and mouse support
- **Frame management** - Smooth animations and updates
- **Collision detection** - Built-in game utilities

## Demo
### check asstets file

## 📦 Installation

### Prerequisites
```bash
# Debian/Ubuntu
sudo apt-get install gcc lua5.4 liblua5.4-dev

# macOS (with Homebrew)
brew install gcc lua

# Windows (with MSYS2)
pacman -S gcc lua lua-devel
```

### Build from Source
```bash
git clone https://github.com/abdorayden/raymp.git
cd raymp
cd install/
# if posix 
./install.sh compile -v && ./install.sh install -v
cd ..
./rmp
```

### Quick Start
```bash
# Run the music player
./rmp
```

## 🎯 Usage Examples

### 🎵 Music Player (Default)
```lua
local rmp = require("rmp")

-- The default theme provides a full-featured music player
-- Just run: ./rmp
```

### 📱 Custom TUI Application
```lua
local api = require("rmp.rmp")
local Window = api.Window
local Terminal = api.Terminal
local Frame = api.Frame

-- Create a simple hello world app
local frame = Frame.new()
frame:setFps(60)

local window = Window.new(1):createWindow(
    "Hello RMP!", 40, 10, 5, 5, nil, nil, nil,
    function(x, y, w, h)
        -- Your app logic here
        return api.Text.new("Welcome to RMP Framework!", 
                           x+2, y+2, api.FGColors.Brights.Green)
    end
)

frame:add(window)
while true do
    local key = Terminal:handleKey()
    if key == api.KEY_Q then break end
    frame:run(key)
end
```

## 🎨 Theme Development

### Creating a Custom Theme
```lua
-- themes/my_theme.lua
local api = require("rmp.rmp")

return function(pluginManager)
    local frame = api.Frame.new()
    frame:setFps(60)
    
    -- Create your layout
    local mainWindow = api.Window.new(1):createWindow(
        "🎵 My Music Player",
        80, 24, 1, 1,
        nil, nil, api.BoxDrawing.DoubleBorder,
        function(x, y, w, h)
            -- Your theme logic
            return createMusicInterface(x, y, w, h)
        end
    )
    
    -- Handle events
    frame:addEventListener(api.KEY_SPACE, function()
        -- Toggle play/pause
        -- api.Audio:toggle()
    end)
    
    -- Main loop
    while true do
        local key = api.Terminal:handleKey()
        if key == api.KEY_Q then break end
        frame:run(key)
    end
end
```

### Theme Configuration
```lua
-- .rmp/init.lua
return {
    theme = "my_theme.lua",
    soundMap = {
        pause_sound = api.KEY_SPACE,
        next_sound = api.KEY_N,
        prev_sound = api.KEY_P,
        vol_up = api.KEY_PLUS,
        vol_down = api.KEY_MINUS,
    },
    plugins = {
        {
            themeWindowId = 1,
            isActivated = true,
            activate = api.KEY_E,
            name = "file_explorer",
        }
    }
}
```

## 🔌 Plugin Development

### Creating a Plugin
```lua
-- plugins/my_plugin.lua
local api = require("rmp.rmp")

return function(x, y, w, h)
    local vterm = api.VirtualTerminal.new()
    local content = {}
    
    -- Plugin logic
    vterm:writeText(x,y ,"Plugin Content", api.FGColors.Brights.Blue)
    
    -- Handle plugin-specific events
    vterm:addEventListener(api.KEY_SPACE , function()
        -- do something
    end)
    
    return vterm
end
```

### Plugin Registration
```lua
-- In your theme or config
plugins = {
    {
        themeWindowId = 2,  -- Window ID to attach to
        isActivated = true,
        activate = api.KEY_TAB,  -- Key to switch plugins
        name = "my_plugin",
    }
}
```

## 🎮 Game Development Features

### Virtual Terminal System
- **Cross-platform character width detection** (including CJK characters)
- **Advanced text rendering** with UTF-8 support
- **Box drawing characters** for creating interfaces
- **Color management** with 16-color and 256-color support

### Input System
- **Real-time key detection**
- **Non-blocking input handling**
- **Special key support** (arrows, function keys, etc.)
- **Mouse support** (coming soon)

### Graphics Capabilities
- **Text-based sprites**
- **Animation systems**
- **Collision detection**
- **Screen buffer management**

## 🌍 Cross-Platform Support

RMP works seamlessly across platforms:

- ✅ **Linux** (Debian, Ubuntu, Arch, etc.)
- ✅ **macOS** (Intel and Apple Silicon)
- ✅ **Windows** (MinGW, MSYS2, WSL)

## 📚 API Reference

### Core Components
- **`api.Frame`** - Main application frame and event loop
- **`api.Window`** - Window management and layouts
- **`api.Terminal`** - Terminal control and input handling
- **`api.Text`** - Text rendering with colors and styles
- **`api.Audio`** - Audio playback and control

### Utilities
- **`api.Config`** - Configuration management
- **`api.BGColors api.FGColors`** - Color constants and utilities
- **`api.BoxDrawing`** - Unicode box drawing characters
- **`api.Keys`** - Key code constants

## 🤝 Contributing

We welcome contributions! Check out our [Contributing Guide](CONTRIBUTING.md).

### Development Setup
```bash
git clone https://github.com/abdorayden/raymp.git
cd raymp
```

## 📄 License

read LICENCE file.

## 🙏 Acknowledgments

- **Miniaudio** - Audio library
- **Lua** - Scripting language
- **Community contributors** - Making RMP better

---

<p align="center">
  <strong>🎵 Start creating amazing terminal applications with RMP today! 🎵</strong>
</p>

<p align="center">
  <a href="#installation">Get Started</a> •
  <a href="#usage-examples">Examples</a> •
  <a href="#api-reference">API Docs</a> •
  <a href="#contributing">Contribute</a>
</p>

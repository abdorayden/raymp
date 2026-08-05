

# 🎵 RMP - Ray Media Platform

<p align="center">
  <img src="./assets/logo.jpg" width="300" height="300" alt="RMP Logo"/>
</p>

<p align="center">
  <strong>Un framework de Lua de alto rendimiento para aplicaciones de terminal</strong>
</p>

<p align="center">
  <a href="#installation">🚀 Inicio Rápido</a> •
  <a href="#demo">🎬 Demos</a> •
  <a href="#usage-examples">📖 Ejemplos</a> •
  <a href="#api-reference">📚 Documentación de la API</a> •
  <a href="#contributing">🤝 Contribuir</a>
</p>

<p align="center">
  🎵 Reproductor de Música | 🎨 Temas Personalizados | 🔌 Sistema de Plugins | 🎮 Juegos 2D | 📱 Aplicaciones TUI
</p>

[![GitHub](https://img.shields.io/badge/license-MIT-blue.svg)](LICENCE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)](README.md)
[![Language](https://img.shields.io/badge/language-C%20%7C%20Lua-orange)](README.md)

---

## ✨ ¿Qué es RMP?

**RMP (Ray Music Player)** es un framework de alto rendimiento y extensible, construido en C con scripting en Lua, para crear interfaces de usuario de terminal sofisticadas. Originalmente concebido como un reproductor de música, RMP ha evolucionado hacia una plataforma integral para aplicaciones basadas en terminal, que incluye:

- 🎵 **Reproductor de Música Avanzado** - Soporte para audio multiformato con visualización en tiempo real
- 📱 **Framework TUI Rich** - Crea interfaces de terminal complejas con facilidad  
- 🎮 **Plataforma de Desarrollo de Juegos** - Construye juegos 2D directamente en la terminal
- 🔧 **Sistema de Plugins Extensible** - Arquitectura modular para personalización ilimitada
- 🎨 **Motor de Temas Dinámicos** - Temas intercambiables en caliente con scripting en Lua
- ⚡ **Alto Rendimiento** - Motor nativo en C con enlaces a Lua para velocidad óptima

**Estadísticas Clave:**
- 🔢 **Más de 140K líneas de código** en C, Lua y documentación
- 🏗️ **Arquitectura Modular** con capas de motor y scripting separadas
- 🌐 **Multiplataforma** con soporte para Linux, macOS y Windows
- 📦 **Autónomo** - Se entrega con el motor Lua 5.4.4 integrado

## 🚀 Características Principales

### 🎨 **Sistema de Temas Avanzado**
- **Temas intercambiables en caliente** - Cambia la apariencia completa de la IU sin reiniciar
- **Plantillas impulsadas por Lua** - Control programático completo sobre el diseño de la interfaz
- **Contenido dinámico** - Actualizaciones en tiempo real y elementos interactivos
- **Renderizado multiplataforma** - Apariencia consistente en todas las plataformas
- **Soporte Unicode** - Elementos visuales enriquecidos con caracteres de dibujo de cuadros

### 🔌 **Arquitectura de Plugins Robusta**
- **Sistema orientado a eventos** - Reacciona a la entrada del usuario, eventos del sistema y desencadenantes personalizados
- **Contextos de plugins aislados** - Los plugins se ejecutan en entornos separados para garantizar estabilidad
- **Comunicación entre plugins** - Comparte datos y eventos entre plugins
- **Servicios en segundo plano** - Ejecuta plugins de forma independiente de la IU
- **Soporte para recarga en caliente** - Actualiza plugins sin reiniciar la aplicación

### 🎵 **Reproductor de Música Profesional**
- **Soporte multiformato** - MP3, WAV, FLAC y más formatos de audio
- **Explorador de archivos inteligente** - Navega por bibliotecas de música con búsqueda y filtrado
- **Reproducción avanzada** - Gestión de cola, aleatorio, repetir, crossfade
- **Controles en tiempo real** - Volumen, búsqueda, velocidad y ecualizador
- **Visualización de audio** - Pantallas de análisis de forma de onda y espectro

### 🎮 **Plataforma de Desarrollo de Juegos**
- **Motor de terminal virtual** - Renderizado avanzado de gráficos basados en texto
- **Gestión de entrada** - Manejo integral de teclado y mouse
- **Framework de animación** - Animaciones suaves con tasas de fotogramas personalizables
- **Detección de colisiones** - Utilidades de física integradas para desarrollo de juegos
- **Gestión de estados** - Gestión eficiente de estados y escenas del juego

### ⚡ **Motor de Alto Rendimiento**
- **Núcleo nativo en C** - Rendimiento optimizado para aplicaciones de terminal complejas
- **Integración con Lua** - Enlace C-Lua fluido con mínimo sobrecarga
- **Eficiencia en memoria** - Gestión inteligente de recursos y recolección de basura
- **Operaciones asíncronas** - E/S no bloqueante para interfaces receptivas

## 🎬 Demo

### Renderizador de Cubo 3D
Experimenta gráficos 3D en tiempo real renderizados completamente con caracteres de terminal.

<video width="100%" controls>
  <source src="https://github.com/abdorayden/raymp/raw/refs/heads/master/assets/demo1_3dcube.mp4" type="video/mp4">
  Tu navegador no soporta la etiqueta de video.
</video>

### Widget de Reloj Digital
Reloj digital animado con temas personalizables y soporte de zonas horarias.

<video width="100%" controls>
  <source src="https://github.com/abdorayden/raymp/raw/refs/heads/master/assets/demo1_clock.mp4" type="video/mp4">
  Tu navegador no soporta la etiqueta de video.
</video>

## 🏗️ Visión General de la Arquitectura

RMP sigue una arquitectura en capas diseñada para el rendimiento y la extensibilidad:

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

**Componentes:**
- **C Engine Core** - Operaciones nativas de alto rendimiento
- **RMP Framework** - Framework de aplicación basado en Lua  
- **Plugin System** - Extensiones de funcionalidad modulares
- **Theme Engine** - Gestión dinámica de IU y diseño


## 📦 Instalación

### Prerrequisitos

**Dependencias Requeridas:**
```bash
# Debian/Ubuntu
sudo apt-get install gcc build-essential

# macOS (con Homebrew)
brew install gcc

# Windows (MSYS2/MinGW)
choco install gcc
# Instala MinGW-w64 usando el gestor de paquetes chocolaty
```

**Nota:** ¡RMP se entrega con un motor Lua 5.4.4 integrado! No se requiere instalación externa de Lua.

### Compilación desde Código Fuente

#### Construcción tipo Unix
```bash
git clone https://github.com/abdorayden/raymp.git
cd raymp/install
./install.sh compile -v && sudo ./install.sh install -v
cd ..
./rmp
```

#### Construcción para Windows
```batch
git clone https://github.com/abdorayden/raymp.git
cd raymp\install
install.bat compile
install.bat install
cd ..
rmp.exe
```

### Verificación de la Instalación

Prueba tu instalación con las demos integradas:
```bash
# Iniciar el reproductor de música (predeterminado)
./rmp

# Verificar versión y ayuda
./rmp --version
./rmp --help
```

## ⚡ Inicio Rápido

### 1. **Iniciar plantillas predeterminadas de rmp**
```bash
./rmp
```
Navega con las teclas de flecha, presiona `Espacio` para reproducir/pausar, `Q` para salir.

### 2. **Crea tu primera aplicación TUI usando solo el framework de rmp**
```lua
-- hello_world.lua
-- NOTA: el framework de rmp se instala mediante el motor de rmp
local api = require("rmp.rmp")

local frame = api.Frame.new()
frame:setFps(60)

local window = api.Window.new(1):createWindow(
    "¡Hola RMP!", 40, 10, 5, 5, nil, nil, nil,
    function(x, y, w, h)
        return api.Text.new("¡Bienvenido al Framework RMP!", 
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

### 3. **Cargar un Tema Personalizado**
```bash
cat ~/.rmp/init.lua # archivo de configuración
# este es el lugar donde configuras tu reproductor de audio de rmp
# las (plantillas/temas) se encuentran en la carpeta ~/.rmp/themes/
# puedes descargar o crear tu propia plantilla y agregarla a esta ruta 
# y cargarla en el archivo de configuración init.lua
```

### 4. **Cargar un plugin**
```bash
cat ~/.rmp/init.lua # archivo de configuración
# este es el lugar donde configuras tu reproductor de audio de rmp
# los (plugins) se encuentran en la carpeta ~/.rmp/plugins/
# puedes descargar o crear tu propio plugin y agregarlo a esta ruta 
# y cargarlo en el archivo de configuración init.lua
```

## 🎯 Ejemplos de Uso

### 🎵 **Reproductor de Música (Modo Predeterminado)**
La configuración predeterminada proporciona un reproductor de música completo:
```lua
-- Modo predeterminado: solo ejecuta ./rmp
-- Características incluidas:
-- • Explorador de archivos con escaneo de biblioteca musical
-- • Controles de reproducción (reproducir, pausar, buscar, volumen)
-- • Gestión de listas de reproducción
-- • Detección de formatos de audio
-- • Atajos de teclado para todas las funciones
```

### 📱 **Aplicación TUI Personalizada**

```lua
-- multi_window_app.lua
local api = require("rmp.rmp")

-- Crear marco de aplicación
local frame = api.Frame.new()
frame:setFps(60)

-- Ventana principal con contenido dinámico
local mainWindow = api.Window.new(1):createWindow(
    "Demo Multi-Ventana", "w-4", "h-8", 2, 2, 
    api.BoxDrawing.LightBorder, api.BGColors.NoBrights.Black, nil,
    function(x, y, w, h)
        local vterm = api.VirtualTerminal.new()
        vterm:writeText(x+1, y+1, "Área de Contenido Principal", api.FGColors.Brights.White)
        vterm:writeText(x+1, y+3, "Presiona TAB para cambiar paneles", api.FGColors.NoBrights.Yellow)
        return vterm
    end
)

-- Barra de estado
local statusWindow = api.Window.new(2):createWindow(
    nil, "w-2", 3, 1, "h-3",
    api.BoxDrawing.NoBorder, api.BGColors.NoBrights.Blue, nil,
    function(x, y, w, h)
        local vterm = api.VirtualTerminal.new()
        vterm:writeText(x+1, y+1, "Estado: Listo", api.FGColors.Brights.White)
        return vterm
    end
)


-- Bucle de eventos
while true do
    frame:add(mainWindow)
    frame:add(statusWindow)
    local key = api.Terminal:handleKey()
    if key == api.KEY_Q then break end
    frame:run(key)
end
```

### 🎮 **Desarrollo de Juegos 2D**
```lua
-- simple_game.lua
local api = require("rmp.rmp")

local gameState = {
    playerX = 10, playerY = 5,
    enemies = {{x=20, y=8}, {x=30, y=12}},
    score = 0
}

local frame = api.Frame.new()
frame:setFps(30)  -- 30 FPS para jugabilidad fluida

local gameWindow = api.Window.new(1):createWindow(
    "Demo Motor de Juegos RMP", 60, 20, 5, 2,
    api.BoxDrawing.DoubleBorder, api.BGColors.NoBrights.Black, nil,
    function(x, y, w, h)
        local vterm = api.VirtualTerminal.new()
        
        -- Dibujar jugador
        vterm:writeText(x + gameState.playerX, y + gameState.playerY, 
                       "@", api.FGColors.Brights.Green)
        
        -- Dibujar enemigos
        for _, enemy in ipairs(gameState.enemies) do
            vterm:writeText(x + enemy.x, y + enemy.y, 
                           "X", api.FGColors.Brights.Red)
        end
        
        -- Dibujar HUD
        vterm:writeText(x+1, y+1, "Puntuación: " .. gameState.score, 
                       api.FGColors.Brights.Yellow)
        
        return vterm
    end
)

-- Manejo de entrada del juego
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


-- Bucle del juego
while true do
    local key = api.Terminal:handleKey()
    if key == api.KEY_Q then break end
    
    frame:add(gameWindow)
    -- Actualizar estado del juego aquí (movimiento de enemigos, detección de colisiones, etc.)
    
    frame:run(key)
end
```
## 🎨 Desarrollo de (Temas/Plantillas)

El sistema de (temas/Plantillas) de RMP permite personalización completa de la interfaz de usuario a través de plantillas Lua.

### Creando un (Tema/Plantilla) Personalizado
```lua
-- themes/cyberpunk_theme.lua
-- Tema inspirado en Cyberpunk con colores neón y elementos futuristas
-- el archivo lua de la plantilla devuelve una tabla con tablas que tienen diferentes ids y tipos 

local api = require("rmp.rmp")

return {
    -- ventana principal con hijos
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
            -- Encabezado con elementos animados
            {
                id = 2,
                type = "Window",
                title = {
                    type = "Text",
                    value = "",
                    dynamic = function(ctx)
                        -- ctx tabla para el objeto self
                        local time = os.date("%H:%M:%S")
                        return "⚡ INTERFAZ NEURAL ACTIVA ⚡ " .. time
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
            
            -- Área de contenido principal
            {
                id = 3,
                type = "Window", 
                title = {
                    type = "Text",
                    value = "◢█◣ MATRIZ PRINCIPAL ◤█◥",
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
            
            -- Panel de estado/ información
            {
                id = 4,
                type = "Window",
                title = {
                    type = "Text", 
                    value = function()
                        return "⚠ ESTADO DEL SISTEMA: EN LÍNEA ⚠"
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

## 🔌 Desarrollo de Plugins

El sistema de plugins de RMP habilita funcionalidad modular a través de contextos Lua aislados.

### Creando un Plugin Básico
```lua
-- plugins/system_monitor.lua
-- Plugin de monitoreo de sistema en tiempo real
-- el archivo lua del plugin devuelve una función que acepta 4 parámetros y devuelve un objeto VirtualTerminal

local api = require("rmp.rmp")

-- parámetros:
--  x,y: posición de la esquina superior izquierda (posición x e posición y)
--  xx,yy: posición de la esquina inferior derecha
-- retorno: 
--      VirtualTerminal
local vterm = api.VirtualTerminal.new()
return function(x, y, xx, yy)
    local w = xx - x - 1
    local h = yy - y - 1

    -- Estado del plugin
    local updateInterval = 1.0  -- segundos
    local lastUpdate = 0
    local systemData = {}
    
    -- Actualizar información del sistema
    local function updateSystemInfo()
        local currentTime = os.time()
        if currentTime - lastUpdate >= updateInterval then
            -- Obtener info del sistema (ejemplo simplificado)
            systemData = {
                time = os.date("%Y-%m-%d %H:%M:%S"),
                memory = "Memoria: 4.2GB / 8.0GB",
                cpu = "CPU: 15.3%",
                processes = "Procesos: 156"
            }
            lastUpdate = currentTime
        end
    end
    
    -- Renderizar contenido del plugin
    local function render()
        vterm:clear()
        updateSystemInfo()
        
        -- Encabezado
        vterm:writeText(x, y, "═══ MONITOR DEL SISTEMA ═══", 
                       api.FGColors.Brights.Cyan)
        
        -- Información del sistema
        local line = y + 2
        for key, value in pairs(systemData) do
            vterm:writeText(x, line, value, api.FGColors.NoBrights.White)
            line = line + 1
        end
        
        -- Instrucciones
        vterm:writeText(x, yy - 2, "Presiona 'R' para actualizar", 
                       api.FGColors.NoBrights.Yellow)
    end
    
    -- Manejadores de eventos
    vterm:onKeyboard(function(key)
        if key == api.KEY_R then
            lastUpdate = 0  -- Forzar actualización
            render()
        end
    end)
    
    -- Renderizado inicial
    render()
    
    return vterm
end
```

### Registro y Configuración de Plugins
```lua
-- En tu tema o configuración principal
-- ~/.rmp/init.lua
return {
    -- la configuración predeterminada del sonido
    settings = {
        fps = 60,
        volume = 0.5,           -- 0 a 1
        speed = 1.0,            -- 0.25 a 4.0
        mode = api.PlaybackMode.ONES, -- modos de reproducción
        restart_engine = api.KEY_CTRL_R,
        exit = api.KEY_Q,

        -- inc o dec
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
    template = "<nombre de tu archivo lua de plantilla sin extensión>",
    -- plugins
    plugins = {        
        {
            -- si este atributo no es nil o existe, el ejecutor ignora activar
            themeWindowId = 2, -- el id de la ventana en la que se inyecta el plugin
            isActivated = true,-- isActivated (true activado por defecto, de lo contrario no)
            activate = api.KEY_E, -- tecla de alternancia para activar el plugin
            switchPluginKey = api.KEY_I, -- tecla para cambiar entre múltiples plugins integrados en el mismo id de ventana
            names = { -- plugins
                -- ejemplos
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

## 🎮 Guía de Desarrollo de Juegos

RMP proporciona un framework completo para desarrollar juegos 2D en la terminal.

### Características del Motor de Juegos
- **Renderizado basado en fotogramas** con FPS personalizable (1-120 FPS)
- **Sistema de entrada orientado a eventos** que soporta todas las teclas del teclado
- **Sistemas de animación** para movimiento suave de personajes y objetos
- **Gestión de estados** para escenas de juego complejas
- **Integración de audio** para efectos de sonido y música de fondo

## 🌍 Soporte Multiplataforma

RMP está diseñado para máxima compatibilidad entre sistemas operativos y entornos de terminal.

### Plataformas Soportadas
- ✅ **Linux** (Debian, Ubuntu, Arch, CentOS, Fedora)
- ✅ **macOS** (Intel y Apple Silicon M1/M2)
- ✅ **Windows** (MinGW, MSYS2, WSL, Cygwin)
- ✅ **FreeBSD** y otros sistemas tipo Unix

### Compatibilidad con Terminales
- ✅ **Terminales modernas** (Alacritty, Kitty, iTerm2, Windows Terminal)
- ✅ **Terminales tradicionales** (xterm, GNOME Terminal, Konsole)

### Características Específicas de la Plataforma
```c
// Detección de plataforma en el motor C
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

## 📚 Referencia Completa de la API

### Clases del Framework Principal

#### `api.Frame`
Gestión principal del marco de aplicación y ciclo de eventos.
Clase de alto nivel para renderizar el marco
```lua
local frame = api.Frame.new()
frame:setFps(60)                    -- Establecer FPS objetivo (1-120)
frame:add(frame)                    -- Agregar VirtualTerminal o Frame a él
frame:run(keyEvent)                 -- Procesar un solo fotograma
```

#### `api.Window`
Sistema de gestión y diseño de ventanas.
```lua
local window = api.Window.new(id)
window:createWindow(title, width, height, x, y, border, bgColor, fgColor, contentFunction)
window:setTitle(title)              -- Actualizar título de la ventana
window:resize(w, h)                 -- Redimensionar ventana
window:move(x, y)                   -- Mover posición de la ventana
```

#### `api.Terminal`
Control de terminal de bajo nivel y manejo de entrada.
```lua
api.Terminal:clear()                -- Limpiar toda la pantalla
api.Terminal:setCursor(x, y)        -- Mover posición del cursor
api.Terminal:hideCursor()           -- Ocultar cursor
api.Terminal:showCursor()           -- Mostrar cursor
local key = api.Terminal:handleKey() -- Obtener tecla presionada (no bloqueante)
api.Terminal:getSize()              -- Obtener dimensiones de la terminal
```

#### `api.VirtualTerminal`
Renderizado de texto avanzado y búfer de pantalla virtual.
```lua
local vterm = api.VirtualTerminal.new()
vterm:writeText(x, y, text, color)  -- Escribir texto coloreado
vterm:drawBox(x, y, w, h, border, color)   -- Dibujar caja con borde
vterm:clear()                       -- Limpiar búfer virtual
vterm:addEventListener(EventType, callback)       -- Agregar manejador de eventos
```

#### `api.Text`
Renderizado de texto enriquecido con estilos y colores.
```lua
local text = api.Text.new(content, x, y, fgColor, bgColor, style)
text:getText()         -- Actualizar contenido del texto
text:getPosition()     -- Mover posición del texto
text:getColor()        -- Cambiar colores del texto
text:getStyle()        -- Aplicar estilo de texto
```

### Sistema de Audio

#### `api.Audio`
Reproducción y control de audio para música y efectos de sonido.
```lua
api.Audio:load(filename)            -- Cargar archivo de audio
api.Audio:play()                    -- Iniciar reproducción
api.Audio:pause()                   -- Pausar reproducción
api.Audio:stop()                    -- Detener reproducción
api.Audio:setVolume(level)          -- Establecer volumen (0.0-1.0)
api.Audio:seek(position)            -- Buscar a posición en segundos
api.Audio:getPosition()             -- Obtener posición de reproducción actual
api.Audio:getDuration()             -- Obtener duración total de la pista
```

### Constantes de Color

#### Colores de Primer Plano
```lua
-- Colores brillantes
api.FGColors.Brights.Black
api.FGColors.Brights.Red
api.FGColors.Brights.Green
api.FGColors.Brights.Yellow
api.FGColors.Brights.Blue
api.FGColors.Brights.Magenta
api.FGColors.Brights.Cyan
api.FGColors.Brights.White

-- Colores normales  
api.FGColors.NoBrights.Black
api.FGColors.NoBrights.Red
-- ... (patrón similar)
```

#### Colores de Fondo
```lua
-- Colores de fondo (estructura similar)
api.BGColors.Brights.Black
api.BGColors.NoBrights.Red
-- ... etc
```

#### Colores desde Hex

```lua
api.colorFromHex("ff0000" , api.FG) -- color de primer plano
api.colorFromHex("ff0000" , api.BG) -- color de fondo
```

### Estilos de Texto y Dibujo

#### Estilos de Texto
```lua
api.TextStyle.Normal                -- Texto normal
api.TextStyle.Bold                  -- Texto en negrita
api.TextStyle.Italic                -- Texto en cursiva
api.TextStyle.Underline             -- Texto subrayado
api.TextStyle.Strikethrough         -- Texto tachado
```

#### Caracteres de Dibujo de Cuadros
```lua
api.BoxDrawing.NoBorder             -- Sin borde
api.BoxDrawing.LightBorder          -- Borde sencillo ligero
api.BoxDrawing.HeavyBorder          -- Borde sencillo pesado  
api.BoxDrawing.RoundedBorder        -- Borde con esquinas redondeadas
```

### Manejo de Entrada

#### Constantes de Teclas
```lua
-- Teclas de letras
api.KEY_A, api.KEY_B, ..., api.KEY_Z

-- Teclas numéricas
api.KEY_0, api.KEY_1, ..., api.KEY_9

-- Teclas especiales
api.KEY_SPACE                       -- Barra espaciadora
api.KEY_ENTER                       -- Enter/Retorno
api.KEY_TAB                         -- Tabulación
api.KEY_ESC                         -- Escape
api.KEY_BACKSPACE                   -- Retroceso
api.KEY_DELETE                      -- Eliminar

-- Teclas de flecha
api.KEY_UP                          -- Flecha arriba
api.KEY_DOWN                        -- Flecha abajo 
api.KEY_LEFT                        -- Flecha izquierda
api.KEY_RIGHT                       -- Flecha derecha

-- Teclas modificadoras
api.KEY_CTRL_A, api.KEY_CTRL_B, ... -- Combinaciones con Ctrl
```

### revisa la documentación en [Framework RMP](https://rayden-six.vercel.app/raymp/framework)

## 🐛 Solución de Problemas

### Problemas Comunes

#### **Errores de Compilación**
```bash
# Error: Permiso denegado durante la instalación
# Solución: Usa sudo para la instalación del sistema
sudo ./install.sh install -v

# Error: gcc no encontrado
# Solución: Instala las herramientas de compilación
sudo apt-get install build-essential gcc
```

## 🤝 Contribuir

¡Damos la bienvenida a contribuciones de desarrolladores de todos los niveles! Aquí tienes cómo involucrarte:

### Directrices de Estilo de Código
- **Código C**: Sigue el estilo de codificación del núcleo de Linux
- **Código Lua**: Usa indentación de 4 espacios, nombres de variables descriptivos
- **Comentarios**: Documenta algoritmos complejos y APIs públicas
- **Pruebas**: Agrega pruebas para nuevas funciones cuando sea posible

### Áreas de Contribución
- 🎨 **Desarrollo de Temas** - Crea nuevos temas visuales
- 🔌 **Desarrollo de Plugins** - Construye plugins para nueva funcionalidad  
- 🎮 **Desarrollo de Juegos** - Crea juegos de ejemplo y demos
- 📚 **Documentación** - Mejora guías y documentación de la API
- 🐛 **Corrección de Errores** - Arregla problemas y mejora la estabilidad
- ⚡ **Rendimiento** - Optimiza código del motor y framework

### Envío de Cambios
1. **Crear commits descriptivos**
   ```bash
   git commit -m "feat: agregar tema cyberpunk con animaciones"
   git commit -m "fix: resolver fuga de memoria en el motor de audio" 
   git commit -m "docs: mejorar guía de desarrollo de plugins"
   ```

2. **Probar exhaustivamente**
   ```bash
   # Ejecutar pruebas existentes
   ./rmp --run-tests
   
   # Probar en múltiples plataformas si es posible
   # Probar con diferentes emuladores de terminal
   ```

3. **Enviar solicitud de extracción (pull request)**
   - Describe los cambios claramente
   - Enlaza a problemas relacionados
   - Incluye capturas de pantalla/videos para cambios visuales

### Reporte de Problemas
Por favor usa GitHub Issues para reportes de errores y solicitudes de funciones:
- **Reportes de errores**: Incluye información del sistema, pasos para reproducir, comportamiento esperado vs. real
- **Solicitudes de funciones**: Describe el caso de uso, solución propuesta y alternativas consideradas

Para más detalles, consulta nuestra [Guía de Contribución](CONTRIBUTIONS.md).

## 📄 Licencia

Consulta el archivo [LICENCIA](LICENCE) para más detalles.

## 🙏 Agradecimientos

RMP se construye sobre los hombros de increíbles proyectos de código abierto:

- **[Lua 5.4.4](https://www.lua.org/)** - Lenguaje de scripting integrado
- **[Miniaudio](https://github.com/mackron/miniaudio)** - Biblioteca de audio multiplataforma
- **GCC/Clang** - Cadenas de herramientas de compilador C
- **Desarrolladores de emuladores de terminal** - Por avanzar las capacidades de la terminal

Agradecimiento especial a la comunidad de aplicaciones de terminal por la inspiración y retroalimentación.

## 🚀 ¿Qué sigue?

### Características Próximas (Hoja de Ruta)
- 🖱️ **Soporte de Mouse** - Soporte completo de interacción con mouse
- 🌐 **Soporte de Red** - Networking TCP/UDP para juegos multijugador
- 🎨 **Gráficos Avanzados** - Renderizado mejorado con mejor soporte Unicode
- 🔌 **Mercado de Plugins** - Repositorio en línea para temas y plugins
- 📊 **Perfilador de Rendimiento** - Herramientas integradas de análisis de rendimiento

### Involucrarse
- ⭐ **Marcar con estrella el repositorio** para mostrar apoyo
- 🐛 **Reportar errores** para ayudar a mejorar la estabilidad
- 💡 **Sugerir funciones** para desarrollo futuro
- 🤝 **Contribuir código** para ayudar a construir el futuro de las aplicaciones de terminal

---

<p align="center">
  <strong>🎵 ¡Comienza a crear increíbles aplicaciones de terminal con RMP hoy mismo! 🎵</strong>
</p>

<p align="center">
  <a href="#installation">🚀 Inicio Rápido</a> •
  <a href="#usage-examples">📖 Ejemplos</a> •
  <a href="#api-reference">📚 Documentación de la API</a> •
  <a href="#contributing">🤝 Contribuir</a> •
  <a href="https://github.com/abdorayden/raymp">⭐ GitHub</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Made%20with-❤️%20y%20C-red.svg" alt="Hecho con amor y C"/>
</p>

---

## Revisión de Seguridad de Memoria (2026-02-16)

Este informe resume una revisión dirigida de fugas de memoria y riesgos de crecimiento ilimitado en el motor de RMP y en plugins/plantillas seleccionados.

**Hallazgos (del más grave al menos grave)**
1. Crecimiento ilimitado de las colas de eventos de teclado/mouse cuando no llega entrada. Un nuevo callback de teclado se encola en cada fotograma en `RMPManager.lua`, y las colas solo se vacían cuando existe entrada. Esto puede crecer sin límite durante períodos de inactividad. Archivos afectados: `src/engine/RMPManager.lua`, `src/engine/core/rmp.lua`.
2. Mismo patrón de crecimiento de cola en plugins (ejemplo: tutorial). El plugin de tutorial registra un controlador de teclado en cada fotograma, y esos callbacks se fusionan en el marco principal. Si no llega entrada, los callbacks se acumulan. Archivo afectado: `src/engine/builtin/plugins/tutorial_rmp/init.lua`.
3. Fuga de VT nativa en `VirtualTerminal:copy`. `RMP.VirtualTerminal:copy()` asigna un búfer nativo en el constructor, luego sobrescribe `native_vt_rmp` con una nueva copia nativa sin liberar la original. Archivo afectado: `src/engine/core/rmp.lua`.
4. Posible crecimiento de caché en `TemplateParser.compiledExpressions`. Las claves de caché incluyen valores de contexto y pueden crecer sin límite si los valores de contexto varían frecuentemente. Archivo afectado: `src/engine/RMPManager.lua`.

**Cosas que parecen estar bien**
1. Los búferes de `VirtualTerminal` se liberan en C mediante `vt_rmp.distroy`, y las rutas de fusión destruyen VTs temporales cuando `distroy=true`.
2. Las cachés de ventana/plugin de `TemplateParser` están acotadas por la cantidad de ventanas.

**Direcciones de corrección sugeridas**
1. Crecimiento de cola de eventos: almacena listas de listeners persistentes e itera sin eliminarlos para eventos de teclado/mouse, o limpia esas colas en cada fotograma antes de volver a registrar los controladores.
2. Fuga en `VirtualTerminal:copy`: evita asignar un búfer nativo antes de reemplazar `native_vt_rmp`, o agrega una ruta de constructor de copia nativa.

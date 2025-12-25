-- /*********************************************************************************************/
-- /*  Copyright (c) 2025 Ray Den 								*/
-- /*  												*/
-- /*  Permission is hereby granted, free of charge, to any person obtaining a copy 		*/
-- /*  of this software and associated documentation files (the "Software"), to deal 		*/
-- /*  in the Software without restriction, including without limitation the rights 		*/
-- /*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 		*/
-- /*  copies of the Software, and to permit persons to whom the Software is 			*/
-- /*  furnished to do so, subject to the following conditions: 				*/
-- /*  												*/
-- /*  The above copyright notice and this permission notice shall be included in 		*/
-- /*  all copies or substantial portions of the Software. 					*/
-- /*  												*/
-- /*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 		*/
-- /*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		*/
-- /*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 		*/
-- /*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 			*/
-- /*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 		*/
-- /*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 		*/
-- /*  THE SOFTWARE. 										*/
-- /*  												*/
-- /*********************************************************************************************/

-- Complete RMP engine with error handling, plugin management, template parsing and layout engine
-- Enhanced version of rmpv1 with better structure and modularity

-- TODO: rewrite all engine to C for better performance and lower memory usage
-- NOTE: plugins should create VirtualTerminal inside returned function
-- BUG:  program stops if lua access nil obj or something (add system logs)
-- BUG:  bg color title not working properly in window (drawBox)

local api = require("rmp.rmp")
local utils = require("rmp.util")
local OOP = require("rmp.oop")

local mainFrame = api.Frame.new()

local joinPath = api.Path.joinPath

local io = require("io")
local os = require("os")

local HashMap = utils.HashMap
local Queue = utils.Queue

local got_error = false
local the_error_message = ""

-- Function to color specific keywords in a string
local function coloredKeywordInString(str, keyword, color)
    local pattern = "%f[%w_]" .. keyword .. "%f[%W]"
    return str:gsub(pattern, color .. keyword .. api.Default)
end

-- Function to color Lua code keywords
local function coloredLuaCode(str)
    if type(str) ~= "string" then
        return str
    end

    local keywords = {
        "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
        "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
        "true", "until", "while"
    }

    for _, keyword in ipairs(keywords) do
        str = coloredKeywordInString(str, keyword, api.FGColors.Brights.Green)
    end

    return str
end

-- Plugin Manager class
local PlugManager = OOP.class("PlugManager")
do
    function PlugManager:constructor(cfgObj)
        self.cfgObj = cfgObj
        self.pluginStates = {}
    end

    function PlugManager:getNextPlug(id)
        local currentPlug = self.cfgObj:get(id)
        if not currentPlug then
            return function() end, "No plugins for window " .. tostring(id)
        end

        if currentPlug[2]:isEmpty() then
            return function() end, "No plugins available"
        end

        local forRet = currentPlug[2]:pop()
        currentPlug[2]:push(forRet)

        self.pluginStates[id] = {
            current = forRet,
            lastSwitched = os.time()
        }

        return forRet, nil
    end

    function PlugManager:getSwitchKey(id)
        local currentPlug = self.cfgObj:get(id)
        if not currentPlug then
            return nil
        end
        return currentPlug[1]
    end

    function PlugManager:getPluginState(id)
        return self.pluginStates[id]
    end
end

-- Component types
local ComponentType = {
    Window = "Window",
    Text = "Text"
}

-- Component class to represent a single component
local Component = OOP.class("Component")
do
    function Component:constructor(comp)
        -- it can be nil
        self.x = comp.x
        self.y = comp.y
        self.width = comp.width
        self.height = comp.height
        self.foregroundColor = comp.foregroundColor
        self.backgroundColor = comp.backgroundColor
        self.type = comp.type
        self.title = comp.title

        self.children = comp.children

        if self.children and type(self.children) == "table" then
            -- work with children
            return self
        end

        if type(self.title) == "string" then
            return self
        elseif type(self.title) == "table" and self.title:instanceOf(api.Text) then
            return self
        end

        if self.type == ComponentType.Window then
            -- handle functions (dynamic, condition)
            return self
        elseif self.type == ComponentType.Text then
            -- handle functions (dynamic, condition)
            return self
        else
            -- unreachable
            return self
        end
    end
end

-- Components manager class for all components in the application
local Components = OOP.class("Components")
do
    function Components:constructor(templeArray)
        self.templeArray = templeArray
        -- Use a hash map to store components by id
        -- key id
        -- value Component
        self.components = HashMap.new()
        self:_fillHashMap()
    end

    function Components:toArray()
        return self.templeArray
    end

    function Components:save()
        -- Move from HashMap to templeArray
        -- after the modifications that applied on the hash map we have to save it back to templeArray
        return self
    end

    function Components:_fillHashMap()
        for _, component in ipairs(self.templeArray) do
            if component.id then
                self.components:put(component.id, Component.new(component))
            end
        end
    end

    -- @param id: string - unique identifier for the component
    -- @param component: table - the component data
    function Components:createComponent(id, component)
        if id and component then
            self.components:put(id, Component.new(component))
        end
    end

    -- @param id: string - unique identifier for the component
    -- @return: table or nil - the component data or nil if not found
    function Components:getComponent(id)
        if id and self.components:get(id) then
            return self.components:get(id)
        end
        return nil
    end

    function Components:updateComponent(id, newComponent)
        if id and self.components:get(id) then
            -- Assuming Component has a set method or we update fields directly
            local comp = self.components:get(id)
            for k, v in pairs(newComponent) do
                comp[k] = v
            end
        end
    end

    function Components:removeComponent(id)
        if id and self.components:get(id) then
            self.components:remove(id) -- Using HashMap's remove method instead of direct assignment
        end
    end
end

-- Logging functions
local function logerror(err)
    the_error_message = the_error_message .. "RMP Error: " .. tostring(err)
    got_error = true
    -- io.write(api.BGColors.Brights.Red ..
    --     api.FGColors.Brights.Yellow .. "RMP Error:" .. api.Default .. " " .. tostring(err) .. "\n")
end

local function lognote(note)
    the_error_message = the_error_message .. "RMP Note: " .. tostring(note)
    got_error = true
    -- io.write(api.BGColors.Brights.Blue ..
    --     api.FGColors.Brights.White .. "RMP Note:" .. api.Default .. " " .. tostring(note) .. "\n")
end

local function logwarn(warn)
    the_error_message = the_error_message .. "RMP Warning: " .. tostring(warn)
    got_error = true
    -- io.write(api.BGColors.Brights.Yellow ..
    --     api.FGColors.Brights.Black .. "RMP Warning:" .. api.Default .. " " .. tostring(warn) .. "\n")
end

-- Template parser with layout engine
local TemplateParser = OOP.class("TemplateParser")
do
    function TemplateParser:constructor(template, plugManager)
        self.template = template
        self.plugManager = plugManager
        self.windowCache = {}
        self.pluginCache = {}
        self.lastTerminalSize = { w = 0, h = 0 }
    end

    function TemplateParser:evaluateExpression(expr, context)
        if type(expr) == "number" then
            return math.floor(expr)
        end

        if type(expr) ~= "string" then
            return 1
        end

        local evaluated = expr
        for key, value in pairs(context) do
            evaluated = evaluated:gsub(key, tostring(value))
        end

        evaluated = evaluated:gsub("math%.floor", "math.floor")
        evaluated = evaluated:gsub("math%.ceil", "math.ceil")

        local func = load("return " .. evaluated)
        if func then
            local ok, result = pcall(func)
            if ok and type(result) == "number" then
                return math.floor(result)
            end
        end

        return 1
    end

    function TemplateParser:createContext()
        local h, w = api.Terminal:getSize()
        return {
            w = w,
            h = h,
            lw = w - 1,
            lh = h - 1
        }
    end

    -- Dynamic and condition are really useful, so I'm gonna look for more useful callbacks
    function TemplateParser:parseText(textConfig, context)
        if not textConfig or textConfig.type ~= "Text" then
            return nil
        end

        local value = textConfig.value or ""

        if textConfig.dynamic and type(textConfig.dynamic) == "function" then
            local dynamicValue = textConfig.dynamic(context)
            if type(dynamicValue) == 'string' then
                value = dynamicValue
            elseif type(dynamicValue) == 'table' then
                if dynamicValue.value then
                    value = tostring(dynamicValue.value)
                elseif dynamicValue.style then
                    textConfig.style = dynamicValue.style
                elseif dynamicValue.foregroundColor then
                    textConfig.foregroundColor = dynamicValue.foregroundColor
                elseif dynamicValue.backgroundColor then
                    textConfig.backgroundColor = dynamicValue.backgroundColor
                end
            end
        end

        return api.Text.new(
            value,
            textConfig.style,
            textConfig.foregroundColor,
            textConfig.backgroundColor
        )
    end

    function TemplateParser:createWindow(windowConfig, context, mainFrame)
        if not windowConfig or windowConfig.type ~= "Window" then
            return nil
        end

        if windowConfig.condition and type(windowConfig.condition) == "function" then
            if not windowConfig.condition(context) then
                return nil
            end
        end

        local width = self:evaluateExpression(windowConfig.width, context)
        local height = self:evaluateExpression(windowConfig.height, context)
        local x = self:evaluateExpression(windowConfig.x, context)
        local y = self:evaluateExpression(windowConfig.y, context)

        local title = nil
        if windowConfig.title then
            title = self:parseText(windowConfig.title, context)
        end

        local currentPlugin = self.pluginCache[windowConfig.id]
        if not currentPlugin and windowConfig.id and self.plugManager then
            -- plugin is table with {name , configuration}
            local plugin, err = self.plugManager:getNextPlug(windowConfig.id)
            if plugin and not err then
                currentPlugin = plugin
                self.pluginCache[windowConfig.id] = plugin
            end
        end

        local callback = function(innerX, innerY, innerXX, innerYY)
            local childVterm = api.VirtualTerminal.new()

            if currentPlugin and type(currentPlugin) == "function" then
                local pluginResult = currentPlugin(innerX, innerY, innerXX, innerYY)
                if pluginResult then
                    childVterm:merge(pluginResult, true)
                end
            end

            if windowConfig.children then
                for _, childConfig in ipairs(windowConfig.children) do
                    local childWindow = self:createWindow(childConfig, context, mainFrame)
                    if childWindow then
                        childVterm:merge(childWindow, true)
                    end
                end
            end

            if windowConfig.content and type(windowConfig.content) == "function" then
                local contentResult = windowConfig.content(innerX, innerY, innerXX, innerYY, context)
                if contentResult then
                    childVterm:merge(contentResult, true)
                end
            end

            return childVterm
        end

        local window = api.Window.new(windowConfig.id):createWindow(
            title,
            width,
            height,
            x,
            y,
            windowConfig.foregroundColor,
            windowConfig.backgroundColor,
            windowConfig.border,
            callback
        )

        return window
    end

    function TemplateParser:getTemplate()
        return self.template
    end

    function TemplateParser:parseTemplate(template)
        if not template then
            if not self.template or type(self.template) ~= "table" then
                return {}
            end
        end

        self.template = template

        local context = self:createContext()
        local windows = {}

        for _, windowConfig in ipairs(self.template) do
            if windowConfig.type == "Window" then
                local window = self:createWindow(windowConfig, context, nil)
                if window then
                    table.insert(windows, window)
                end
            end
        end

        -- FIXME: add script execution in the context of the template
        -- TODO: pass class components to the script function
        -- TODO: came back
        if type(self.template.script) == "function" then
            -- the context here should be an instance of Components class
            -- and the script should called every frame to update the components data
            -- also the script should return the updated components data
            local success, err = pcall(self.template.script, context)
            if not success then
                logwarn("Error executing script in template: " .. tostring(err))
            end
        end

        return windows, context
    end

    function TemplateParser:getPluginSwitchKeys()
        local switchKeys = {}
        if not self.plugManager then
            return switchKeys
        end

        local function collectKeys(config)
            if config.id then
                local key = self.plugManager:getSwitchKey(config.id)
                if key then
                    switchKeys[config.id] = key
                end
            end
            if config.children then
                for _, child in ipairs(config.children) do
                    collectKeys(child)
                end
            end
        end

        for _, windowConfig in ipairs(self.template) do
            collectKeys(windowConfig)
        end

        return switchKeys
    end

    function TemplateParser:updatePlugin(windowId)
        if self.plugManager then
            local plugin, err = self.plugManager:getNextPlug(windowId)
            if plugin and not err then
                self.pluginCache[windowId] = plugin
            end
        end
    end

    function TemplateParser:wasTerminalResized()
        local h, w = api.Terminal:getSize()
        if w ~= self.lastTerminalSize.w or h ~= self.lastTerminalSize.h then
            self.lastTerminalSize.w = w
            self.lastTerminalSize.h = h
            return true
        end
        return false
    end
end

-- Key to character mapping using a lookup table for efficiency
local keyToCharMap = {
    [api.KEY_RIGHT] = "<right>",
    [api.KEY_LEFT] = "<left>",
    [api.KEY_UP] = "<up>",
    [api.KEY_DOWN] = "<down>",
    [api.KEY_SPACE] = "<space>",
    [api.KEY_TAB] = "<tab>",
    [api.KEY_ALT_A] = "<A-a>",
    [api.KEY_ALT_B] = "<A-b>",
    [api.KEY_ALT_C] = "<A-c>",
    [api.KEY_ALT_D] = "<A-d>",
    [api.KEY_ALT_E] = "<A-e>",
    [api.KEY_ALT_F] = "<A-f>",
    [api.KEY_ALT_G] = "<A-g>",
    [api.KEY_ALT_H] = "<A-h>",
    [api.KEY_ALT_K] = "<A-k>",
    [api.KEY_ALT_L] = "<A-l>",
    [api.KEY_ALT_M] = "<A-m>",
    [api.KEY_ALT_N] = "<A-n>",
    [api.KEY_ALT_O] = "<A-o>",
    [api.KEY_ALT_P] = "<A-p>",
    [api.KEY_ALT_Q] = "<A-q>",
    [api.KEY_ALT_R] = "<A-r>",
    [api.KEY_ALT_S] = "<A-s>",
    [api.KEY_ALT_T] = "<A-t>",
    [api.KEY_ALT_U] = "<A-u>",
    [api.KEY_ALT_V] = "<A-v>",
    [api.KEY_ALT_W] = "<A-w>",
    [api.KEY_ALT_X] = "<A-x>",
    [api.KEY_ALT_Y] = "<A-y>",
    [api.KEY_ALT_Z] = "<A-z>",
    [api.KEY_CTRL_A] = "<C-a>",
    [api.KEY_CTRL_B] = "<C-b>",
    [api.KEY_CTRL_C] = "<C-c>",
    [api.KEY_CTRL_D] = "<C-d>",
    [api.KEY_CTRL_E] = "<C-e>",
    [api.KEY_CTRL_F] = "<C-f>",
    [api.KEY_CTRL_G] = "<C-g>",
    [api.KEY_CTRL_H] = "<C-h>",
    [api.KEY_CTRL_K] = "<C-k>",
    [api.KEY_CTRL_L] = "<C-l>",
    [api.KEY_CTRL_M] = "<C-m>",
    [api.KEY_CTRL_N] = "<C-n>",
    [api.KEY_CTRL_O] = "<C-o>",
    [api.KEY_CTRL_P] = "<C-p>",
    [api.KEY_CTRL_Q] = "<C-q>",
    [api.KEY_CTRL_R] = "<C-r>",
    [api.KEY_CTRL_S] = "<C-s>",
    [api.KEY_CTRL_T] = "<C-t>",
    [api.KEY_CTRL_U] = "<C-u>",
    [api.KEY_CTRL_V] = "<C-v>",
    [api.KEY_CTRL_W] = "<C-w>",
    [api.KEY_CTRL_X] = "<C-x>",
    [api.KEY_CTRL_Y] = "<C-y>",
    [api.KEY_CTRL_Z] = "<C-z>"
}

local function engine_render_help(frame, w, h, settings, soundCfg)
    local function ktc(k)
        local mapped = keyToCharMap[k]
        if mapped then
            return mapped
        else
            return api.Input.new():keyToChar(k)
        end
    end

    local helpText = {
        "RMP Help:",
        "-------------",
        "General Controls:",
        "  " .. ktc(settings.help_key) .. " : Show Help",
        "  " .. ktc(settings.exit) .. " : Quit Application",
        "",
        "Sound Controls:",
        "  " .. ktc(soundCfg.pause_sound) .. ": Pause",
        "  " .. ktc(soundCfg.resume_sound) .. ": Resume",
        "  " .. ktc(soundCfg.next_sound) .. ": Next Track",
        "  " .. ktc(soundCfg.prev_sound) .. ": Previous Track",
        "  " .. ktc(soundCfg.vol_up) .. ": Volume Up",
        "  " .. ktc(soundCfg.vol_down) .. ": Volume Down",
        "  " .. ktc(soundCfg.seek_left) .. ": Seek Backward",
        "  " .. ktc(soundCfg.seek_right) .. ": Seek Forward",
        "  " .. ktc(soundCfg.speed_up) .. ": Speed Up",
        "  " .. ktc(soundCfg.speed_down) .. ": Slow Down",
        "  " .. ktc(soundCfg.change_playback_mode) .. ": Change Playback Mode",
        "",
        "Plugin Controls:",
        "  [Plugin Switch Keys]: Switch Plugins in Windows (if configured)",
    }

    -- Calculate dimensions for the help box
    local maxTextWidth = 0
    for _, line in ipairs(helpText) do
        if #line > maxTextWidth then
            maxTextWidth = #line
        end
    end

    -- Add some padding
    local boxWidth = maxTextWidth + 4
    local boxHeight = #helpText + 4 -- +2 for top/bottom padding, +2 more for visual padding
    local boxX = math.floor((w - boxWidth) / 2)
    local boxY = math.floor((h - boxHeight) / 2)

    -- Create a box using the VirtualTerminal's drawBox method
    frame:drawBox(
        api.Text.new("Help", api.TextStyle.Bold, api.FGColors.Brights.White, api.BGColors.NoBrights.Black),
        boxX, boxY, boxWidth, boxHeight,
        api.BoxDrawing.LightBorder,
        api.FGColors.Brights.White,  -- border color
        api.BGColors.NoBrights.Black -- background color
    )

    -- Draw the help text inside the box
    for i, line in ipairs(helpText) do
        local textX = boxX + 2     -- Add padding from the left border
        local textY = boxY + 1 + i -- Add padding from the top border
        frame:writeText(textX, textY, line, api.FGColors.Brights.White, api.BGColors.NoBrights.Black)
    end
end

local function setupPlugins(configObj, is_userconfig)
    local plugs = HashMap.new()
    local plugins = configObj.plugins
    local otherPlugs = Queue.new() -- this is for global plugins not attached to any window
    local plugins_configurations = HashMap.new()

    if not plugins or type(plugins) ~= "table" then
        logerror("Invalid plugins configuration.")
        lognote("plugins should be a table of plugin configurations.")
        lognote("Example plugins configuration:")
        lognote(coloredLuaCode("return {"))
        lognote(coloredLuaCode("    	..."))
        lognote(coloredLuaCode("	plugins = {"))
        lognote(coloredLuaCode("	    {"))
        lognote(coloredLuaCode("	        themeWindowId = 'main',"))
        lognote(coloredLuaCode("	        switchPluginKey = api.KEY_TAB,"))
        lognote(coloredLuaCode("	        names = {'plugin1', 'plugin2'},"))
        lognote(coloredLuaCode("	        isActivated = true,"))
        lognote(coloredLuaCode("	    },"))
        lognote(coloredLuaCode("	    {"))
        lognote(coloredLuaCode("	        names = {'globalPlugin'},"))
        lognote(coloredLuaCode("	        isActivated = true,"))
        lognote(coloredLuaCode("	    },"))
        lognote(coloredLuaCode("	}"))
        lognote(coloredLuaCode("}"))
        return nil, nil
    end

    for _, plug in ipairs(plugins) do
        if plug.themeWindowId and plug.isActivated and plug.names then
            local pq = Queue.new()

            for _, name in ipairs(plug.names) do
                local pluginOk, pluginModule

                if is_userconfig then
                    local homePath = api.Path.new():getHomePath()
                    local singleFile, folderInit
                    if type(name) == "string" then
                        singleFile = joinPath(homePath, ".rmp", "plugins", name .. ".lua")
                        folderInit = joinPath(homePath, ".rmp", "plugins", name, "init.lua")
                        plugins_configurations:put(name, nil)
                    elseif type(name) == "table" then
                        singleFile = joinPath(homePath, ".rmp", "plugins", name[1] .. ".lua")
                        folderInit = joinPath(homePath, ".rmp", "plugins", name[1], "init.lua")
                        plugins_configurations:put(name[1], name[2])
                    end

                    pluginOk, pluginModule = pcall(dofile, singleFile)
                    if not pluginOk then
                        pluginOk, pluginModule = pcall(dofile, folderInit)
                    end
                else
                    if type(name) == "string" then
                        pluginOk, pluginModule = pcall(require, "rmp.selfrmp.plugins." .. name) -- try to load from default selfrmp plugins
                        plugins_configurations:put(name, nil)
                    elseif type(name) == "table" then
                        pluginOk, pluginModule = pcall(require, "rmp.selfrmp.plugins." .. name[1]) -- try to load from default selfrmp plugins
                        plugins_configurations:put(name[1], name[2])
                    end
                end

                if pluginOk and pluginModule then
                    pq:push(pluginModule)
                else
                    if type(name) == "string" then
                        logwarn("Could not load plugin '" .. name .. "': " .. tostring(pluginModule) .. "\n")
                    elseif type(name) == "table" then
                        logwarn("Could not load plugin '" .. name[1] .. "': " .. tostring(pluginModule) .. "\n")
                    end
                    -- os.exit(1)
                end
            end

            if not pq:isEmpty() then
                plugs:put(plug.themeWindowId, { plug.switchPluginKey, pq })
            end
        elseif plug.isActivated and plug.names and plug.themeWindowId == nil then
            for _, name in ipairs(plug.names) do
                local pluginOk, pluginModule
                if is_userconfig then
                    local homePath = api.Path.new():getHomePath()
                    local singleFile, folderInit
                    if type(name) == "string" then
                        singleFile = joinPath(homePath, ".rmp", "plugins", name .. ".lua")
                        folderInit = joinPath(homePath, ".rmp", "plugins", name, "init.lua")
                        plugins_configurations:put(name, nil)
                    elseif type(name) == "table" then
                        -- first index is plugin name the second is configuration
                        singleFile = joinPath(homePath, ".rmp", "plugins", name[1] .. ".lua")
                        folderInit = joinPath(homePath, ".rmp", "plugins", name[1], "init.lua")
                        plugins_configurations:put(name[1], name[2])
                    end

                    pluginOk, pluginModule = pcall(dofile, singleFile)
                    if not pluginOk then
                        pluginOk, pluginModule = pcall(dofile, folderInit)
                    end
                else
                    if type(name) == "string" then
                        pluginOk, pluginModule = pcall(require, "rmp.selfrmp.plugins." .. name) -- try to load from default selfrmp plugins
                        plugins_configurations:put(name, nil)
                    elseif type(name) == "table" then
                        pluginOk, pluginModule = pcall(require, "rmp.selfrmp.plugins." .. name[1]) -- try to load from default selfrmp plugins
                        plugins_configurations:put(name[1], name[2])
                    end
                end
                if pluginOk and pluginModule then
                    otherPlugs:push(pluginModule)
                else
                    if type(name) == "string" then
                        logwarn("Could not load global plugin '" .. name .. "': " .. tostring(pluginModule) .. "\n")
                    elseif type(name) == "table" then
                        logwarn("Could not load global plugin '" .. name[1] .. "': " .. tostring(pluginModule) .. "\n")
                    end
                    -- os.exit(1)
                end
            end
        end
    end

    return PlugManager.new(plugs), otherPlugs, plugins_configurations
end

local function runRMPApplication(plugManager, template, settings, otherPlugs, soundCfg, plugs_cfgs, configObj,
                                 is_userconfig)
    got_error = false
    the_error_message = ""
    local h, w = api.Terminal:getSize()
    mainFrame:clear()

    -- check the settings first and then the keymap
    local sound = api.Sound.new() -- empty playlist

    local inc_speed = nil
    local inc_volume = nil
    local inc_seek = nil
    local valid_restart = false
    local help_fn = nil
    local exit = nil

    if settings then
        if settings.fps and type(settings.fps) == "number" and settings.fps > 0 and settings.fps <= 120 then
            mainFrame:setFps(settings.fps)
        else
            -- default engine fps
            settings.fps = 60
            mainFrame:setFps(settings.fps)
        end

        if settings.restart_engine and type(settings.restart_engine) == "number" then
            valid_restart = true
        else
            settings.restart_engine = api.KEY_CTRL_R
        end

        if settings.volume and type(settings.volume) == "number" and settings.volume >= 0 and settings.volume <= 1 then
            sound:setVolume(settings.volume)
        else
            settings.volume = 0.5
            sound:setVolume(0.5)
        end

        if settings.speed and type(settings.speed) == "number" and settings.speed > 0.0 and settings.speed <= 3.0 then
            sound:setSpeed(settings.speed)
        else
            settings.speed = 1.0
            sound:setSpeed(1.0)
        end

        if settings.mode and type(settings.mode) == "number" and settings.mode >= 0 and settings.mode <= 3 then
            sound:setPlayBackMode(settings.mode)
        else
            settings.mode = 0
            sound:setPlayBackMode(0)
        end

        if settings.help_key and type(settings.help_key) == "number" then
            help_fn = settings.help_key
        else
            -- NOTE: if help key is not configured it will be disabled so no default
            -- TODO: create help plugin
            help_fn = nil
        end

        if settings.inc_speed and type(settings.inc_speed) == "number" and settings.inc_speed > 0 and settings.inc_speed <= 50 then
            inc_speed = settings.inc_speed
        else
            settings.inc_speed = 0.1
            inc_speed = 0.1
        end

        if settings.inc_seek and type(settings.inc_seek) == "number" and settings.inc_seek > 0 and settings.inc_seek <= 30 then
            inc_seek = settings.inc_seek
        else
            settings.inc_seek = 5
            inc_seek = 5
        end

        if settings.inc_volume and type(settings.inc_volume) == "number" and settings.inc_volume > 0 and settings.inc_volume <= 1 then
            inc_volume = settings.inc_volume
        else
            settings.inc_volume = 0.1
            inc_volume = 0.1
        end

        if settings.exit and type(settings.exit) == "number" then
            exit = settings.exit
        else
            settings.exit = api.KEY_Q
            exit = api.KEY_Q
        end
    else
        inc_speed = 0.1
        inc_volume = 0.1
        inc_seek = 5
        exit = api.KEY_Q
    end

    mainFrame:initMainFrame()

    local parser = TemplateParser.new(template, plugManager)
    local switchKeys = parser:getPluginSwitchKeys()
    local quit = false
    local oq = otherPlugs
    local restart = false
    local render_help = false

    local template_copy = parser:getTemplate()

    while not quit do
        if plugs_cfgs then
            local c = plugs_cfgs:get("all")
            if c and type(c) == "table" then
                configObj = c
            end
        end

        -- Only call setupPlugins once per loop, not twice as in original
        local currentPlugManager, currentOtherPlugs, currentPlugsCfgs = setupPlugins(configObj, is_userconfig)

        mainFrame:clear()
        key = api.Terminal:handleKey()

        if parser:wasTerminalResized() then
            h, w = api.Terminal:getSize()
            mainFrame:resize(w, h)
        end

        for windowId, switchKey in pairs(switchKeys) do
            mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)
                if inputKey == switchKey then
                    parser:updatePlugin(windowId)
                end
            end)
        end

        -- Handle the exit key from configuration
        mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)
            if inputKey == exit then
                quit = true
            end
        end)

        mainFrame:addEventListener(api.EventType.Keyboard, function(key)
            if valid_restart then
                if key == settings.restart_engine then
                    restart = true
                end
            end
        end)

        mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)
            -- in case you configured pause and resume with same key
            if soundCfg.pause_sound ~= soundCfg.resume_sound then
                if inputKey == soundCfg.pause_sound then
                    if sound:isPlaying() then
                        sound:pause()
                    end
                end
                if inputKey == soundCfg.resume_sound then
                    if not sound:isPlaying() then
                        sound:play()
                        sound:resume()
                    end
                end
            else
                if inputKey == soundCfg.resume_sound then
                    if not sound:isPlaying() then
                        sound:play()
                        sound:resume()
                    else
                        sound:pause()
                    end
                end
            end
            if inputKey == soundCfg.next_sound then
                local ok, err = sound:nextTrack()
                if not ok then
                    -- log the error with popup
                end
            end
            if inputKey == soundCfg.prev_sound then
                local ok, err = sound:prevTrack()
                if not ok then
                    -- log the error with popup
                end
            end
            if inputKey == soundCfg.vol_up then
                local currVol = sound:getVolume()
                if currVol < 1 then
                    if currVol + inc_volume >= 1 then
                        sound:setVolume(1)
                    else
                        sound:setVolume(currVol + inc_volume)
                    end
                end
            end
            if inputKey == soundCfg.vol_down then
                local currVol = sound:getVolume()
                if currVol > 0 then
                    if currVol - inc_volume <= 0 then
                        sound:setVolume(0)
                    else
                        sound:setVolume(currVol - inc_volume)
                    end
                end
            end
            if inputKey == soundCfg.seek_left then
                if sound:isPlaying() then
                    local currPos = math.floor(sound:getPosition())
                    if currPos > 0 then
                        if currPos - inc_seek <= 0 then
                            sound:seek(0)
                        else
                            sound:seek(currPos - inc_seek)
                        end
                    end
                end
            end
            if inputKey == soundCfg.seek_right then
                if sound:isPlaying() then
                    local currPos = math.floor(sound:getPosition())
                    local len = math.floor(sound:getLength())
                    if currPos < len then
                        if currPos + inc_seek >= len then
                            sound:seek(len - 1) -- i know i know don't ask any question
                        else
                            sound:seek(currPos + inc_seek)
                        end
                    end
                end
            end
            if inputKey == soundCfg.speed_up then
                local currSpeed = sound:getSpeed() + inc_speed
                if currSpeed < 3.0 then
                    sound:setSpeed(currSpeed)
                else
                    sound:setSpeed(3.0)
                end
            end
            if inputKey == soundCfg.speed_down then
                local currSpeed = sound:getSpeed() - inc_speed
                if currSpeed > 0.0 then
                    sound:setSpeed(currSpeed)
                else
                    sound:setSpeed(0.1)
                end
            end

            if inputKey == soundCfg.change_playback_mode then
                sound:setPlayBackMode((sound:getPlayBackMode() + 1) % 4) -- hard code the length of mode whatever
            end
        end)

        sound:update()

        -- To work with the same table
        local windows, _ = parser:parseTemplate(template_copy)

        for _, window in ipairs(windows) do
            mainFrame:add(window, true)
        end

        local qq = Queue.new()

        while oq and not oq:isEmpty() do
            local plug = oq:pop()
            if plug then
                if type(plug) == "function" then
                    mainFrame:add(plug(), true)
                    qq:push(plug)
                elseif type(plug) == "table" then
                    -- TODO: other plugins are configured , add their configurations to Config event

                    mainFrame:add(plug[1](), true)
                    qq:push(plug)
                end
            end
        end
        oq = qq

        ---
        -- TODO: add other plugins that are not integrated to specific window id template to event
        -- TODO: rayden was here

        if currentPlugsCfgs then
            -- TODO: add settings and soundCfg keys to plugins values table configurations

            currentPlugsCfgs:put("soundCfg", soundCfg)
            currentPlugsCfgs:put("settings", settings)
            currentPlugsCfgs:put("all", configObj)
        end
        ---

        if render_help then
            engine_render_help(mainFrame, w, h, settings, soundCfg)
        end

        if help_fn and key == help_fn then
            render_help = not render_help
        end

        mainFrame:run(
            key,
            nil, -- TODO: add mouse support later
            sound,
            currentPlugsCfgs,
            -- windows is just table of windows tables
            template_copy
        )

        if restart then
            break
        end
    end

    sound:cleanup()
    mainFrame:cleanupMainFrame()
    return restart
end


local function loadConfiguration()
    local config = api.Config.new()

    if config:isValidConfig() then
        local ok, err = config:load()
        if not ok then
            logerror("loading user configuration: " .. err)
            return nil, nil, nil
        end

        local cfgObj = config:getInitFileAsObject()
        local themeName = cfgObj.template -- config:getThemesAsObject() or "default"

        if not themeName or type(themeName) ~= "string" then
            logerror("Invalid theme name in configuration.")
            logerror("template should be required on the configuration.")
            lognote("Example template:")
            lognote(coloredLuaCode("	return {"))
            lognote(coloredLuaCode("	    ..."))
            lognote(coloredLuaCode("	    template = 'your_theme_name',"))
            lognote(coloredLuaCode("	    ..."))
            lognote(coloredLuaCode("	}"))
            return nil, nil, nil
        end

        local templateOk, template = pcall(dofile,
            joinPath(config.homePath:getPath(), ".rmp", "themes", themeName .. ".lua"))
        if not templateOk then
            logerror("loading user template: Not found or " .. template)
            logerror("template should be a lua file that returns a table.")
            lognote("Example template:")
            lognote(coloredLuaCode("	return {"))
            lognote(coloredLuaCode("	    {"))
            lognote(coloredLuaCode("	        type = 'Window',"))
            lognote(coloredLuaCode("	        id = 'main',"))
            lognote(coloredLuaCode("	        width = 'w',"))
            lognote(coloredLuaCode("	        height = 'h',"))
            lognote(coloredLuaCode("	        x = 0,"))
            lognote(coloredLuaCode("	        y = 0,"))
            lognote(coloredLuaCode("	        border = true,"))
            lognote(coloredLuaCode("	        title = {"))
            lognote(coloredLuaCode("	            type = 'Text',"))
            lognote(coloredLuaCode("	            value = 'My RMP Theme',"))
            lognote(coloredLuaCode("	            style = 'bold',"))
            lognote(coloredLuaCode("	            foregroundColor = 'yellow',"))
            lognote(coloredLuaCode("	            backgroundColor = 'blue',"))
            lognote(coloredLuaCode("	        },"))
            lognote(coloredLuaCode("	        children = {"))
            lognote(coloredLuaCode("	            ..."))
            lognote(coloredLuaCode("	        },"))
            lognote(coloredLuaCode("	    },"))
            lognote(coloredLuaCode("	    ..."))
            lognote(coloredLuaCode("	}"))
            return nil, nil, nil
        end

        return cfgObj, template, true -- true means user config
    else
        local defaultConfig = require("rmp.selfrmp.init")
        local templateOk, template = pcall(require, "rmp.selfrmp.themes." .. defaultConfig.template)

        if not templateOk then
            logerror("Error loading default template: " .. template)
            return nil
        end

        return defaultConfig, template, false -- false means default config
    end
end

-- Main Entry Point
local function main()
    -- Load configuration
    local restart = true
    while restart do
        local ok, error = pcall(function()
            restart = false -- Reset restart flag

            local configObj, template, is_userconfig = loadConfiguration()
            if not configObj or not template then
                logerror("Failed to load configuration. Exiting.")
                -- TODO: assuming default path windows and linux
                lognote("check your configuration file or try to reset it by deleting ~/.rmp/config.lua")
                lognote("see the errors above for more details.")
                -- os.exit(1)
            end

            local soundCfg = configObj.soundMap

            if soundCfg == nil then --- use the default
                soundCfg = {
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
                }
            elseif #soundCfg < 10 then --- check for every key if it's not exists set the default key
                if soundCfg.pause_sound == nil or type(soundCfg.pause_sound) ~= "number" then
                    soundCfg.pause_sound = api.KEY_SPACE
                end
                if soundCfg.change_playback_mode == nil or type(soundCfg.change_playback_mode) ~= "number" then
                    soundCfg.change_playback_mode = api.KEY_TAB
                end
                if soundCfg.resume_sound == nil or type(soundCfg.resume_sound) ~= "number" then
                    soundCfg.resume_sound = api.KEY_SPACE
                end
                if soundCfg.next_sound == nil or type(soundCfg.next_sound) ~= "number" then
                    soundCfg.next_sound = api.KEY_N
                end
                if soundCfg.prev_sound == nil or type(soundCfg.prev_sound) ~= "number" then
                    soundCfg.prev_sound = api.KEY_P
                end
                if soundCfg.vol_up == nil or type(soundCfg.vol_up) ~= "number" then
                    soundCfg.vol_up = api.KEY_PLUS
                end
                if soundCfg.vol_down == nil or type(soundCfg.vol_down) ~= "number" then
                    soundCfg.vol_down = api.KEY_MINUS
                end
                if soundCfg.seek_left == nil or type(soundCfg.seek_left) ~= "number" then
                    soundCfg.seek_left = api.KEY_LEFT
                end
                if soundCfg.seek_right == nil or type(soundCfg.seek_right) ~= "number" then
                    soundCfg.seek_right = api.KEY_RIGHT
                end
                if soundCfg.speed_up == nil or type(soundCfg.speed_up) ~= "number" then
                    soundCfg.speed_up = api.KEY_UP
                end
                if soundCfg.speed_down == nil or type(soundCfg.speed_down) ~= "number" then
                    soundCfg.speed_down = api.KEY_DOWN
                end
            end

            local plugManager, otherPlugs, plugs_cfgs = setupPlugins(configObj, is_userconfig)

            if not plugManager and not otherPlugs then
                logerror("Failed to setup plugins. Exiting.")
                lognote("check your plugins configuration.")
                lognote("see the errors above for more details.")
                -- os.exit(1)
            end

            -- Run the application and check if restart is needed
            restart = runRMPApplication(
                plugManager,
                template,
                configObj.settings,
                otherPlugs,
                soundCfg,
                plugs_cfgs,
                configObj,
                is_userconfig
            )
        end)
        if not ok then
            key = api.Terminal:handleKey()
            mainFrame:clear()
            restart = true
            mainFrame:drawBox(
                api.Text.new("Error", api.TextStyle.Bold, api.FGColors.Brights.Red, api.BGColors.NoBrights.Black),
                2, 2, 76, 10,
                api.BoxDrawing.LightBorder,
                api.FGColors.Brights.Red,
                api.BGColors.NoBrights.Black
            )
            mainFrame:writeText(4, 4, "An error occurred: " .. tostring(error), api.FGColors.Brights.Red,
                api.BGColors.NoBrights.Black)
            if the_error_message ~= "" then
                mainFrame:writeText(4, 5, "An error occurred: " .. the_error_message, api.FGColors.Brights.Red,
                    api.BGColors.NoBrights.Black)
            end
            mainFrame:writeText(4, 6, "press Q to quit ... ", api.FGColors.Brights.Red,
                api.BGColors.NoBrights.Black)
            mainFrame:onKeyboard(function(key)
                if key == api.KEY_Q then
                    restart = false
                end
            end)
            mainFrame:run(key, nil, nil, nil, nil)
            if not restart then
                break
            end
        end
    end
    if not restart then
        lognote("Exiting application...")
        os.exit(0)
    end
    key:closeKey()
end

local function safeMain()
    local ok, err = pcall(main)
    if not ok then
        api.Terminal:showCursor()
        api.Terminal:rawMode(false)
        logerror(tostring(err))
        lognote("check the error above for more details.")
        -- os.exit(1)
    end
end

-- Start the application
safeMain()

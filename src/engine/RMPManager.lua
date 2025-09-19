--	RMPManager.lua is part of the RAP (Ray Audio Player) project.
--	Copyright (c) 2025-2026 Ray (rayden)
--	License: see LICENSE for details.
--
--
-- complete rmp engine with error handling , plugin management , template parsing and layout engine
-- enhanced version of rmpv1 with better structure and modularity
-- TODO: rewrote all engine to C for better performance and lower memory usage

local api = require("rmp.rmp")
local utils = require("rmp.util")
local OOP = require("rmp.oop")

local io = require("io")
local os = require("os")

local HashMap = utils.HashMap
local Queue = utils.Queue

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

-- template parser with layout engine
local TemplateParser = OOP.class("TemplateParser")
do
	function TemplateParser:constructor(template, plugManager)
		self.template = template
		self.plugManager = plugManager
		self.windowCache = {}
		self.pluginCache = {}
		self.lastTerminalSize = {w = 0, h = 0}
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

	--TODO: add more usefull callbacks to a text and window parser later
	-- dynamic and condition is really useful , so im gonna looking for more usefull callbacks
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
					childVterm:merge(pluginResult)
				end
			end

			if windowConfig.children then
				for _, childConfig in ipairs(windowConfig.children) do
					local childWindow = self:createWindow(childConfig, context, mainFrame)
					if childWindow then
						childVterm:merge(childWindow)
					end
				end
			end

			if windowConfig.content and type(windowConfig.content) == "function" then
				local contentResult = windowConfig.content(innerX, innerY, innerXX, innerYY, context)
				if contentResult then
					childVterm:merge(contentResult)
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

	function TemplateParser:parseTemplate()
		if not self.template or type(self.template) ~= "table" then
			return {}
		end

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

local function runRMPApplication(plugManager, template, settings , otherPlugs)
	local h, w = api.Terminal:getSize()
	local mainFrame = api.Frame.new()

	if settings then
		if settings.fps and type(settings.fps) == "number" and settings.fps > 0 and settings.fps <= 120 then
			mainFrame:setFps(settings.fps)
		end
	end

	api.Terminal:hideCursor()


	local parser = TemplateParser.new(template, plugManager)
	local switchKeys = parser:getPluginSwitchKeys()
	local quit = false
	local oq = otherPlugs

	while not quit do
		local key = api.Terminal:handleKey()

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

		mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)
			if inputKey == api.KEY_Q or inputKey == api.KEY_CTRL_C then
				quit = true
			end
		end)

		-- sound controls (if settings provided)
		if settings and settings.soundMap then
			local soundMap = settings.soundMap
			mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)
				-- this would integrate with your rmp.sound class
				-- add event listeners for sound controls , play , pause , stop , next , previous
				-- it's like internal plugin inside engine to manage the sound
				-- find a better way to handle this
			end)
		end

		local windows, context = parser:parseTemplate()

		for _, window in ipairs(windows) do
			mainFrame:add(window)
		end

		local qq = Queue.new()

		while not oq:isEmpty() do
			local plug = oq:pop()
			if plug and type(plug) == "function" then
				mainFrame:add(plug())
				qq:push(plug)
			end
		end
		oq = qq

		mainFrame:run(
			key, 
			nil -- add mouse support later
		)
	end

	api.Terminal:showCursor()
	api.Terminal:rawMode(false)
	api.Terminal:closeKey()
end

local function logerror(err)
	io.write(api.BGColors.Brights.Red .. api.FGColors.Brights.Yellow .. "RMP Error:"  .. api.Default .. " " ..  tostring(err) .. "\n")
end

local function lognote(note)
	io.write(api.BGColors.Brights.Blue .. api.FGColors.Brights.White .. "RMP Note:"  .. api.Default .. " " ..  tostring(note) .. "\n")
end

local function logwarn(warn)
	io.write(api.BGColors.Brights.Yellow .. api.FGColors.Brights.Black .. "RMP Warning:"  .. api.Default .. " " ..  tostring(warn) .. "\n")
end

local function coloredKeywordInString(str, keyword, color)
	local pattern = "%f[%w_]" .. keyword .. "%f[%W]"
	return str:gsub(pattern, color .. keyword .. api.Default)
end

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

local function loadConfiguration()
	local config = api.Config.new()

	if config:isValidConfig() then
		local ok, err = config:load()
		if not ok then
			logerror("loading user configuration: " .. err)
			return nil , nil , nil
		end

		local cfgObj = config:getInitFileAsObject()
		local themeName = cfgObj.template-- config:getThemesAsObject() or "default"

		if not themeName or type(themeName) ~= "string" then
			logerror("Invalid theme name in configuration.")
			logerror("template should be required on the configuration.")
			lognote("Example template:")
			lognote(coloredLuaCode("	return {"))
			lognote(coloredLuaCode("	    ..."))
			lognote(coloredLuaCode("	    template = 'your_theme_name',"))
			lognote(coloredLuaCode("	    ..."))
			lognote(coloredLuaCode("	}"))
			return nil , nil , nil
		end

		local templateOk, template = pcall(dofile , config.homePath:getPath() .. "/.rmp/themes/" .. themeName .. ".lua")
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
			return nil , nil , nil
		end

		return cfgObj, template , true -- true means user config
	else
		local defaultConfig = require("rmp.selfrmp.init")
		local templateOk, template = pcall(require, "rmp.selfrmp.themes." .. defaultConfig.template)

		if not templateOk then
			logerror("Error loading default template: " .. template)
			return nil
		end

		return defaultConfig, template , false -- false means default config
	end
end

local function setupPlugins(configObj , is_userconfig)
	local plugs = HashMap.new()
	local plugins = configObj.plugins
	local otherPlugs = Queue.new() -- this is for global plugins not attached to any window
	local currentPath = api.Path.new():getHomePath()


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
		return nil , nil
	end


	for _, plug in ipairs(plugins) do
		if plug.themeWindowId and plug.isActivated and plug.names then
			local pq = Queue.new()

			for _, name in ipairs(plug.names) do
				local pluginOk, pluginModule

				if is_userconfig then
					pluginOk, pluginModule = pcall(dofile , api.Path.new():getHomePath() .. "/.rmp/plugins/" .. name .. ".lua") -- try to load single file first
					if not pluginOk then
						pluginOk, pluginModule = pcall(dofile , currentPath .. "/.rmp/plugins/" .. name .. "/init.lua") -- try to load init.lua in folder
					end
				else
					pluginOk, pluginModule = pcall(require, "rmp.selfrmp.plugins." .. name) -- try to load from default selfrmp plugins
				end

				if pluginOk and pluginModule then
					pq:push(pluginModule)
				else
					logwarn("Could not load plugin '" .. name .. "' make sure that default plugin are installed: " .. tostring(pluginModule) .. "\n")
					os.exit(1)
				end
			end

			if not pq:isEmpty() then
				plugs:put(plug.themeWindowId, {plug.switchPluginKey, pq})
			end
		elseif plug.isActivated and plug.names and plug.themeWindowId == nil  then
			for _, name in ipairs(plug.names) do
				local pluginOk, pluginModule
				if is_userconfig then
					pluginOk, pluginModule = pcall(dofile , currentPath .. "/.rmp/plugins/" .. name .. ".lua") -- try to load single file first
					if not pluginOk then
						pluginOk, pluginModule = pcall(dofile , configObj.homePath:getPath() .. "/.rmp/plugins/" .. name .. "/init.lua") -- try to load init.lua in folder
					end
				else
					pluginOk, pluginModule = pcall(require, "rmp.selfrmp.plugins." .. name) -- try to load from default selfrmp plugins
				end
				if pluginOk and pluginModule then
					otherPlugs:push(pluginModule)
				else
					logwarn("Could not load global plugin '" .. name .. "': " .. tostring(pluginModule) .. "\n")
					os.exit(1)
				end
			end

		end
	end

	return PlugManager.new(plugs) , otherPlugs 
end

-- Main Entry Point
local function main()
	-- Load configuration
	local configObj, template , is_userconfig = loadConfiguration()
	if not configObj or not template then
		logerror("Failed to load configuration. Exiting.")
		-- TODO: assuming default path windows and linux
		lognote("check your configuration file or try to reset it by deleting ~/.rmp/config.lua") 
		lognote("see the errors above for more details.")
		os.exit(1)
	end

	local plugManager , otherPlugs  = setupPlugins(configObj , is_userconfig)

	if not plugManager and not otherPlugs then
		logerror("Failed to setup plugins. Exiting.")
		lognote("check your plugins configuration.")
		lognote("see the errors above for more details.")
		os.exit(1)
	end

	local parser = TemplateParser.new(template, plugManager)
	-- You could add template validation here if needed

	runRMPApplication(plugManager, template, configObj.settings , otherPlugs)
end

local function safeMain()
	local ok, err = pcall(main)
	if not ok then
		api.Terminal:showCursor()
		api.Terminal:rawMode(false)
		logerror(tostring(err))
		lognote("check the error above for more details.")
		os.exit(1)
	end
end

-- Start the application
safeMain()

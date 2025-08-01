-- Lua master for managing lua plugins
-- TODO: make the configuration and the api global in intsallation
local api = require("rmp")
local cfg = require("init") -- Make sure this path is correct

-- Plugin manager table
local PluginManager = {
	active_plugins = {},
	plugin_callbacks = {},
	running = true
}

-- Initialize plugin system
function PluginManager:init()
	-- Clear any existing plugins
	self.active_plugins = {}
	self.plugin_callbacks = {}

	-- Load all configured plugins
	for _, plug in ipairs(cfg.plugins) do
		self:load_plugin(plug)
	end
end

-- Load a single plugin
function PluginManager:load_plugin(plug)
	local ok, plugin = pcall(require, plug.path)
	if not ok then
		api.Popup:Error("Failed to load plugin "..plug.path..": "..plugin)
		return false
	end

	-- Store plugin with its configuration
	self.active_plugins[plug.path] = {
		config = plug,
		instance = plugin,
		is_active = plug.isactivate or false,
		coroutine = nil,
		blocking = plug.blocking or false
	}

	return true
end

-- Activate a plugin
function PluginManager:activate_plugin(path)
	if self.active_plugins[path] then
		self.active_plugins[path].is_active = true
		return true
	end
	return false
end

-- Deactivate a plugin
function PluginManager:deactivate_plugin(path)
	if self.active_plugins[path] then
		self.active_plugins[path].is_active = false
		return true
	end
	return false
end

-- Toggle a plugin's active state
function PluginManager:toggle_plugin(path)
	if self.active_plugins[path] then
		self.active_plugins[path].is_active = not self.active_plugins[path].is_active
		return true
	end
	return false
end

-- Main loop that runs active plugins
function PluginManager:run()
	api.Terminal:RawMode(true)
	api.Terminal:HideCursor()
	api.Terminal:ClearWindow()
	
	w , h = api.Terminal:GetSize()
	api.Window:CreateWindow( api.Text:New("Engine" , api.Bold , api.BGGreen):GetColoredText(), h, w, 1, 1, api.FGRed, nil, nil)
 	while self.running do
		w , h = api.Terminal:GetSize()
		-- Check for plugin activation keys
 		local key = api.Terminal:HandleKey()
-- 		-- TODO: match the key with the configuration plugin key
		for path, plugin in pairs(self.active_plugins) do
			if key == api.KEY_Q or key == api.KEY_SHIFT_Q then
				-- print(api.GetKeyStr(key))
				self.running = false
				break
			end
			if key == plugin.config.activate then
				self:toggle_plugin(path)
				api.Popup:Message(plugin.config.path.." "..
				(plugin.is_active and "activated" or "deactivated"))
				api.Terminal:ClearWindow()
			end
		end

		-- Run active plugins
		for path, plugin in pairs(self.active_plugins) do
			if plugin.is_active then
				if not plugin.coroutine or coroutine.status(plugin.coroutine) == "dead" then
					-- Create new coroutine if none exists or previous finished
					plugin.coroutine = coroutine.create(function()
						local ok, err = pcall(plugin.instance, cfg.sound_cfg)
						if not ok then
							api.Popup:Error("Plugin "..path.." error: "..err)
							plugin.is_active = false
						end
					end)
				end

				-- Resume the coroutine
				if coroutine.status(plugin.coroutine) ~= "dead" then
					local success, msg = coroutine.resume(plugin.coroutine)
					if not success then
						api.Popup:Error("Plugin "..path.." crashed: "..msg)
						plugin.is_active = false
					end
				end
			end
		end

		-- Small delay to prevent CPU overuse
		-- TODO: handle sleep function
		-- os.execute("sleep 0.02")
		api.Terminal:CloseKey()
 	end
 	api.Terminal:RawMode(false)
 	api.Terminal:ShowCursor()
end

-- Initialize and run the plugin manager
function main()
	PluginManager:init()
	PluginManager:run()
end

-- return {
--     main = main,
--     PluginManager = PluginManager
-- }
-------------------------------------------------------\

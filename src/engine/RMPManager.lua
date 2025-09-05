-- this will manage the themes and plugins 

-- move this file to rmp lua share files

local api = require("rmp.rmp")

local Config = api.Config

print("im the manager")

-- let's start with theme
local config = Config.new()

if not config:isValidConfig() then
	-- no configuration file
	-- so here we gonna load the default config
	local config = require("rmp.selfrmp.init")
	local theme = require("rmp.selfrmp.themes."..config.theme)

	local plugins = config.plugins

	local valid_plugs = {}

	for _ , plug in ipairs(plugins) do
		if plug.themeWindowId and plug.isActivated then
			valid_plugs[plug.themeWindowId] = require("rmp.selfrmp.plugins."..plug.name)
		end
	end

	theme(valid_plugs)
end

-- this will manage the themes and plugins 

-- move this file to rmp lua share files

local api = require("rmp.rmp")
local utils = require("rmp.util")
local OOP = require("rmp.oop")

local HashMap = utils.HashMap
local Queue = utils.Queue

local Config = api.Config

-- let's start with theme
local config = Config.new()

local PlugManager = OOP.class("PlugManager")
do
	function PlugManager:constructor(cfgObj)
		self.cfgObj = cfgObj
	end

	function PlugManager:getNextPlug(id) -- plug , err
		local currentPlug = self.cfgObj:get(id)
		if not currentPlug then
			return nil , "there's no plugins hooked to this window id or this window doesn't exists"
		end

		local forRet = currentPlug[2]:pop()
		currentPlug[2]:push(forRet)
		return forRet , nil
		
	end

	function PlugManager:getSwitchKey(id)
		local currentPlug = self.cfgObj:get(id)
		if not currentPlug then
			return nil , "there's no plugins hooked to this window id or this window doesn't exists"
		end
		return  currentPlug[1]
	end
end

if not config:isValidConfig() then
	-- no configuration file
	-- so here we gonna load the default config
	local config = require("rmp.selfrmp.init")
	local theme = require("rmp.selfrmp.themes."..config.theme)
	local plugins = config.plugins

	local plugs = HashMap.new()

	-- HashMap [
	-- 	id1 => { switch_key , Queue[
	-- 	     	plug1,
	-- 	     	plug2
	-- 		]
	-- 	},
	-- 	id2 => { switch_key , Queue[
	-- 	     	plug1,
	-- 	     	plug2
	-- 		]
	-- 	},
	--
	-- ]
	--

	for _ , plug in ipairs(plugins) do
		if plug.themeWindowId and plug.isActivated then
			local pq = Queue.new()
			for _,name in ipairs(plug.names) do
				pq:push(require("rmp.selfrmp.plugins."..name))
			end
			-- valid_plugs[#valid_plugs + 1] = plug.switchPluginKey
			-- table.insert(valid_plugs[plug.themeWindowId] , plug.switchPluginKey)
			plugs:put(plug.themeWindowId , {plug.switchPluginKey , pq})
		end
	end

	theme(PlugManager.new(plugs))
end

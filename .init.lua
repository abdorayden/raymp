
-- TODO: import core_lua.lua

-- this file will stored into the home use by default so u can change the configuration directly 
-- TODO: add comments to document how to configure the init file
-- return {
-- 	-- NOTE: this number index is tabs
-- 	-- TODO: make index of tabs inctremented
-- 	[api.enum(true) + 1] = {
-- 		name = "tab1",
-- 		[1] = {
-- 			-- TODO: if Display is nil will display automaticly
-- 			-- TODO: title of this window or plugin handled by the plugin it self
-- 			-- NOTE: for example this is Explorer
-- 			[api.Display] = api.KEY_E,
-- 			[api.PluginPath] = "path plugin",
-- 			-- TODO: api.BLOCKED => like explorer
-- 			-- TODO: api.UNBLOCKED => like music in backgroud , styles and stuff like that
-- 			[api.STATUS] = api.BLOCKED or api.UNBLOCKED,
-- 			[api.INITCALLBACK] = function() 
-- 				return 1
-- 			end
-- 		}
-- 	},
-- 	[api.enum() + 1] = {
-- 		-- other tab
-- 	},
-- 
-- 	-- configuration of sound the last index
-- 	[api.enum() + 1] = {
-- 		-- -- TODO: if Display is nil will display automaticly
-- 		-- [api.Display] = nil,
-- 		-- [api.PluginPath] = "path plugin",
-- 		-- -- TODO: api.BLOCKED => like explorer
-- 		-- -- TODO: api.UNBLOCKED => like music in backgroud , styles and stuff like that
-- 		-- [api.STATUS] = api.BLOCKED ,
-- 		[api.SONG] = function() 
-- 			-- TODO: handle song separetly
-- 			-- TODO: move sound in lua file
-- 			return {
-- 				-- TODO: handled by master.lua script
-- 				[api.PAUSE] = api.KEY_SPACE,
-- 				[api.RESUME] = api.KEY_R,
-- 				[api.VOLUMEADD] = api.KEY_PLUS,
-- 				[api.VOLUMESUB] = api.KEY_MINUS,
-- 			}
-- 		end
-- 	}
-- }

return {
	-- the default configuration of the sound
	sound_cfg = {
		pause = api.KEY_SPACE,
		resume = api.KEY_SPACE,
		next = api.KEY_N,
		prev = api.KEY_P,
		vol_up = api.KEY_PLUS,
		vol_down = api.KEY_MINUS,
		seek_left = api.KEY_LEFT,
		seek_right = api.KEY_RIGHT,
		speed_up = api.KEY_UP,
		speed_down = api.KEY_DOWN,
	},
	theme = "theme.lua",
	-- plugins
	plugins = {
		{
			isactivate = false,
			activate = api.KEY_E,
			-- TODO: get the plugin from HOMEDIR
			path = "rmplikemp3",
		},
-- 		{
-- 			isactivate = false,
-- 			activate = api.KEY_E,
-- 			path = "...",
-- 		}
	}
}

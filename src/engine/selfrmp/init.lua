local api = require("rmp.rmp")

-- arch is .rmp folder contains : 
-- 	init.lua file <configuration file>
-- 	plugins folder that has plugin arch
-- 	themes folder that has theme arch

return {
	-- the default configuration of the sound
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
	},
	-- theme = api.Theme.new("theme.lua" , 1 , api.Plugin.new())
	theme = "rmpv1" ,
	-- plugins
	plugins = {	-- this is global plugins you may run in background or in window globaly
			{
				themeWindowId = 2, -- if this attr is not nil or exists , the runner ignore activate
				isActivated = true,
				activate = api.KEY_E,
				name = "music_waves" -- this name should be the same directory and same lua file
				-- name = "plasma_wave_effect" -- this name should be the same directory and same lua file
			},
	-- 		{
	-- 			isactivate = false,
	-- 			activate = api.KEY_E,
	-- 			path = "...",
	-- 		}
	}
}

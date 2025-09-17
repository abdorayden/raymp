local api = require("rmp.rmp")

-- arch is .rmp folder contains : 
-- 	init.lua file <configuration file>
-- 	plugins folder that has plugin arch
-- 	themes folder that has theme arch

return {
	-- the default configuration of the sound
	settings = {
		fps = 60,
		volume = 50, -- 0 to 100
		speed = 1.0, -- 0.25 to 4.0
		repeat_mode = false, -- true or false
		random_mode = false, -- true or false
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
	},
	-- theme = api.Theme.new("theme.lua" , 1 , api.Plugin.new())
	-- template = "template_rmpv1" ,
	-- template = "3_simple" ,
	-- template = "cyberpunk_neon",
	-- template = "music_player_template",
	template = "4_windows_ui",
	-- plugins
	plugins = {	-- this is global plugins you may run in background or in window globaly
			{
				themeWindowId = 2, -- if this attr is not nil or exists , the runner ignore activate
				isActivated = true,
				activate = api.KEY_E,
				-- this name should be the same directory and same lua file
				-- plugins/plug_name.lua or plugins/plug_name/init.lua
				switchPluginKey = api.KEY_I,
				names = {
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
				themeWindowId = 3, -- if this attr is not nil or exists , the runner ignore activate
				isActivated = true,
				activate = api.KEY_E,
				-- switchPluginKey = api.KEY_I,
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

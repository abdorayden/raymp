local api = require(rmp)

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

local api = require("rmp.rmp")

-- Builtin default configuration (used when no ~/.rmp/init.lua exists).
--
-- Configuration files populate the global frame config directly (mainFrame.engine)
-- instead of returning a table. The engine pre-seeds the structure with an empty
-- shell and the builtin configuration below applies the stock defaults.
--
-- Both styles are equivalent:
--     mainFrame.engine.settings.fps = 60
--     mainFrame.engine.fps = 60
--
-- Helpful to get you started: 'tutorial' template renders a full RMP tour.

mainFrame.engine.template = "tutorial"

local settings = mainFrame.engine.settings
settings.fps = 60
settings.help_key = api.KEY_H          -- nil to disable help default ui
settings.volume = 0.5                  -- 0 to 1
settings.speed = 1.0                   -- 0.01 to 3.0
settings.mode = api.PlaybackMode.ONES  -- playback modes
settings.restart_engine = api.KEY_CTRL_R
settings.exit = api.KEY_Q
settings.messages_key = api.KEY_M      -- show logged messages/errors
settings.notify = true                 -- whether to show notifications
settings.theme = "default"             -- default theme [default , darkandwhite , desert , elflord] , nil to disable theme
settings.freq_bins = 32

-- inc or dec
settings.inc_speed = 0.1
settings.inc_volume = 0.1
settings.inc_seek = 5

-- sound keymaps configurations
local soundMap = mainFrame.engine.soundMap
soundMap.pause_sound = api.KEY_SPACE
soundMap.resume_sound = api.KEY_SPACE
soundMap.next_sound = api.KEY_N
soundMap.prev_sound = api.KEY_P
soundMap.vol_up = api.KEY_PLUS
soundMap.vol_down = api.KEY_MINUS
soundMap.seek_left = api.KEY_LEFT
soundMap.seek_right = api.KEY_RIGHT
soundMap.speed_up = api.KEY_UP
soundMap.speed_down = api.KEY_DOWN
soundMap.change_playback_mode = api.KEY_TAB

-- plugins
mainFrame.engine.plugins = {
    {
        themeWindowId = "tutorial-window",
        isActivated = true,
        names = {
            "tutorial_rmp"
        }
    },
    {
        themeWindowId = "helper-window",
        isActivated = true,
        names = {
            "helper_keys_tutorial"
        }
    },
    {
        themeWindowId = "animation-window",
        isActivated = true,
        names = {
            "matrix_digital_rain_effect",
        }
    },
}
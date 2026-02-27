local api = require("rmp.rmp")

-- TODO: in case trying to integrate multiple plugins in one theme window, we can use the same themeWindowId for those plugins, and set the activate key for only one of them, and the others will be activated together with it, but they will not be activated if the themeWindowId is activated by other plugin, so we can have more flexible control over the plugins activation
-- {
--     themeWindowId = 2, -- if this attr is not nil or exists , the runner ignore activate
--     isActivated = true,
--     activate = api.KEY_E,
--     -- this name should be the same directory and same lua file
--     -- plugins/plug_name.lua or plugins/plug_name/init.lua
--     switchPluginKey = api.KEY_I,
--     names = {
--         "matrix_digital_rain_effect",
--         "music_waves",
--         "text_editor",
--         -- "tellme_yourname",
--         "tellme_yournamev2",
--         "digital_clock_with_effects",
--         "3d_cube",
--         "filebrowser"
--     }
--
-- },
--
-- TODO: add dev-rmp plugin to simplify the repeated code in the plugins and themes development by providing some utility functions and a template for the plugins and themes development
-- TODO: add plugin manager as default builtin plugin
-- TODO: make sure that the builtin plugins are handling the themes

return {
    -- the default configuration of the sound
    -- settings the engine configurations
    settings = {
        fps = 60,
        help_key = api.KEY_H,         -- nil to disable help default ui
        volume = 0.5,                 -- 0 to 1
        speed = 1.0,                  -- 0.25 to 4.0
        mode = api.PlaybackMode.ONES, -- playback modes
        restart_engine = api.KEY_CTRL_R,
        exit = api.KEY_Q,
        messages_key = api.KEY_M, -- show logged messages/errors
        notify = true,            -- whether to show notifications
        theme = nil,              -- default theme [default , darkandwhite , desert , elflord] , nil to disable theme

        -- inc or dec
        inc_speed = 0.1,
        inc_volume = 0.1,
        inc_seek = 5
    },
    -- sound keymaps configurations
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
        change_playback_mode = api.KEY_TAB
    },
    -- template
    template = "tutorial",
    -- plugins
    plugins = {
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
                "digital_clock_with_effects",
            }
        },
    }
}

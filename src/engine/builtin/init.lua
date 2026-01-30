local api = require("rmp.rmp")

return {
    -- the default configuration of the sound
    -- settings the engine configurations
    settings = {
        fps = 60,
        help_key = api.KEY_H,
        volume = 0.5,                 -- 0 to 1
        speed = 1.0,                  -- 0.25 to 4.0
        mode = api.PlaybackMode.ONES, -- playback modes
        restart_engine = api.KEY_CTRL_R,
        exit = api.KEY_Q,

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

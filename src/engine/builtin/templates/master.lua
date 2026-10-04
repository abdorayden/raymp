local api = require("rmp.rmp")

-- master builtin template (the default layout).
--
-- One single window that takes the whole screen. Everything inside it comes
-- from the plugin attached to the "main-window" slot — by default
-- builtin-now-playing-rmp, which renders the current song, the playback mode
-- and the audio controls.
--
-- Like every template it is a mutation-style configuration module: the window
-- list goes to raymp.engine.template (returning the table is accepted too).

raymp.engine.template = {
    {
        id = "master",
        type = "Window",
        title = {
            type = "Text",
            value = "🎵 RayMp",
            foregroundColor = api.FGColors.Brights.Cyan,
            backgroundColor = api.Default,
            style = api.TextStyle.Bold,
            dynamic = function(_) -- _context
                return "[ RMP - " .. os.date("%H:%M:%S") .. " ]"
            end
        },
        width = "w",
        height = "h",
        x = 1,
        y = 1,
        border = api.BoxDrawing.RoundedCorners,
        backgroundColor = api.Default
    }
}

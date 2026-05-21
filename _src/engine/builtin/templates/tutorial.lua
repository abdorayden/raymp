local api = require("rmp.rmp")

tutorial_window_width = "w*0.7"
for_restore = ""

local temp = {
    {
        id = "animation-window",
        type = "Window",
        title = nil,
        width = "w*0.3 + 1",
        height = "h/2",
        x = "w - w*0.3 + 1",
        y = "h/2 + 1",
        border = api.BoxDrawing.RoundedCorners,
        backgroundColor = api.Default,
        condition = function(context)
            if context.w < 80 then
                for_restore = tutorial_window_width
                tutorial_window_width = "w"
                context.w = 113
                -- return false
            else
                tutorial_window_width = for_restore
                for_restore = ""
                return true
            end
        end
    },
    {
        id = "helper-window",
        type = "Window",
        title = nil,
        width = "w*0.3 + 1",
        height = "h/2",
        x = "w - w*0.3 + 1",
        y = 1,
        border = api.BoxDrawing.RoundedCorners,
        backgroundColor = api.Default,
        condition = function(context)
            if context.w < 80 then
                for_restore = tutorial_window_width
                tutorial_window_width = "w"
                context.w = 113
                -- return false
            else
                tutorial_window_width = for_restore
                for_restore = ""
                return true
            end
        end
    },
    {
        id = "tutorial-window",
        type = "Window",
        title = {
            type = "Text",
            value = "🎵 NOW PLAYING",
            foregroundColor = api.FGColors.Brights.Cyan,
            backgroundColor = api.Default,
            style = api.TextStyle.Bold,
            dynamic = function(context)
                return "[ RMP - " .. os.date("%H:%M:%S") .. " ]"
            end
        },
        width = tutorial_window_width,
        -- width = "w",
        height = "h",
        x = 1,
        y = 1,
        border = api.BoxDrawing.RoundedCorners,
        backgroundColor = api.Default
    }
}

return temp

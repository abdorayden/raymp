--	Copyright 2024-2026 by rayden
--		
--
--		 this is UI Style of old rmp version , with better performance

local api = require("rmp.rmp")

return {
    {
        id = 1,
        type = "Window",
        title = nil,
        width = "w",
        height = "h",
        x = 1,
        y = 1,
        border = api.BoxDrawing.HeavyBorder,
        children = {
            {
                id = 2,
                type = "Window",
                title = {
                    type = "Text",
                    value = "[ Main Content ]",
                    foregroundColor = api.FGColors.Brights.Cyan,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold,
                    dynamic = function(context)
                        return "[ RMP - " .. os.date("%H:%M:%S") .. " ]"
                    end
                },
                width = "w - w/4",
                height = "h/2",
                x = "w/8+2",
                y = "h/8",
                border = api.BoxDrawing.LightBorder
            },
            {
                id = 3,
                type = "Window",
                title = nil,
                width = "w/4",
                height = "h*2/8",
                x = 2,
                y = "h/8 + h - (h/2) + 2",
                border = api.BoxDrawing.RoundedCorners,
                condition = function(context)
                    return context.w > 100
                end
            }
        }
    }
}

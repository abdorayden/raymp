--
--	Cyberpunk Neon RMP Template
--	Glowing futuristic vibe
--

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
        border = api.BoxDrawing.DoubleBorder,
        backgroundColor = api.BGColors.NoBrights.Black,
        children = {
            -- Glowing Header
            {
                id = 3,
                type = "Window",
                title = {
                    type = "Text",
                    value = "╔═ CYBERPUNK RMP ═╗",
                    foregroundColor = api.FGColors.Brights.Magenta,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold,
                    dynamic = function(context)
                        return "╔═ CYBERPUNK " .. os.date("%H:%M:%S") .. " ═╗"
                    end
                },
                width = "w - 2",
                height = 3,
                x = 2,
                y = 2,
                border = api.BoxDrawing.NoBorder,
                backgroundColor = api.BGColors.NoBrights.Black
            },
            
            -- Main Matrix Panel
            {
                id = 2,
                type = "Window",
                title = {
                    type = "Text",
                    value = "MATRIX CONSOLE",
                    foregroundColor = api.FGColors.Brights.Green,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = "w*2/3 - 3",
                height = "h - 8",
                x = 2,
                y = 6,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black
            },
            
            -- Side Terminal
            {
                id = 4,
                type = "Window",
                title = {
                    type = "Text",
                    value = "DATA STREAM",
                    foregroundColor = api.FGColors.Brights.Cyan,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = "w/3 - 1",
                height = "h - 8",
                x = "w*2/3 + 1",
                y = 6,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black
            },
            
            -- Neon Status Bar
            {
                id = 5,
                type = "Window",
                title = {
                    type = "Text",
                    value = "SYSTEM ACTIVE",
                    foregroundColor = api.FGColors.Brights.Blue,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold,
                    dynamic = function(context)
                        return "〄 SYSTEM: " .. (math.random() > 0.1 and "ACTIVE" or "WARNING")
                    end
                },
                width = "w - 2",
                height = 3,
                x = 2,
                y = "h - 3",
                border = api.BoxDrawing.NoBorder,
                backgroundColor = api.BGColors.NoBrights.Black
            },
            
            -- HUD Element 1
            {
                id = 6,
                type = "Window",
                title = {
                    type = "Text",
                    value = "CPU",
                    foregroundColor = api.FGColors.Brights.Yellow,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = 15,
                height = 4,
                x = "w - 17",
                y = 6,
                border = api.BoxDrawing.RoundedCorners,
                backgroundColor = api.BGColors.NoBrights.Black
            },
            
            -- HUD Element 2
            {
                id = 7,
                type = "Window",
                title = {
                    type = "Text",
                    value = "RAM",
                    foregroundColor = api.FGColors.Brights.Red,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = 15,
                height = 4,
                x = "w - 17",
                y = 11,
                border = api.BoxDrawing.RoundedCorners,
                backgroundColor = api.BGColors.NoBrights.Black
            },
            
            -- Network Indicator
            {
                id = 8,
                type = "Window",
                title = nil,
                width = 8,
                height = 3,
                x = 4,
                y = "h - 7",
                border = api.BoxDrawing.RoundedCorners,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 9,
                        type = "Text",
                        value = "📶 ONLINE",
                        x = 2,
                        y = 1,
                        foregroundColor = api.FGColors.Brights.Green,
                        style = api.TextStyle.Bold
                    }
                }
            },
            
            -- Command Prompt
            {
                id = 10,
                type = "Window",
                title = {
                    type = "Text",
                    value = "TERMINAL",
                    foregroundColor = api.FGColors.Brights.White,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = "w - 20",
                height = 5,
                x = 15,
                y = "h - 8",
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black
            }
        }
    }
}

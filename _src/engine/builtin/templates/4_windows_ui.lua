--
--	Clean 4-Window RMP Template
--	Simple layout with string-only dynamic callbacks
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
        border = api.BoxDrawing.LightBorder,
        backgroundColor = api.BGColors.NoBrights.Black,
        children = {
            -- Header Window
            {
                id = 3,
                type = "Window",
                title = {
                    type = "Text",
                    value = "RMP DASHBOARD",
                    foregroundColor = api.FGColors.Brights.Cyan,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold,
                    dynamic = function(context)
                        return "RMP - " .. os.date("%H:%M:%S")
                    end
                },
                width = "w - 2",
                height = 3,
                x = 2,
                y = 2,
                border = api.BoxDrawing.NoBorder,
                backgroundColor = api.BGColors.NoBrights.Blue
            },
            
            -- Main Content Window
            {
                id = 2,
                type = "Window",
                title = {
                    type = "Text",
                    value = "MAIN CONTENT",
                    foregroundColor = api.FGColors.Brights.Green,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold,
                    dynamic = function(context)
                        return "CONTENT - " .. (context.page or "Home")
                    end
                },
                width = "w - 4",
                height = "h - 12",
                x = 2,
                y = 6,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black
            },
            
            -- Sidebar Window
            {
                id = 4,
                type = "Window",
                title = {
                    type = "Text",
                    value = "STATUS",
                    foregroundColor = api.FGColors.Brights.Yellow,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold,
                    dynamic = function(context)
                        return "STATUS: " .. (math.random() > 0.3 and "ONLINE" or "OFFLINE")
                    end
                },
                width = 20,
                height = "h - 12",
                x = "w - 22",
                y = 6,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 5,
                        type = "Text",
                        value = "Users: 0",
                        x = 2,
                        y = 2,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Normal,
                        dynamic = function(context)
                            return "Users: " .. math.random(1, 100)
                        end
                    },
                    {
                        id = 6,
                        type = "Text",
                        value = "CPU: 0%",
                        x = 2,
                        y = 3,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Normal,
                        dynamic = function(context)
                            return "CPU: " .. math.random(1, 100) .. "%"
                        end
                    },
                    {
                        id = 7,
                        type = "Text",
                        value = "Memory: 0MB",
                        x = 2,
                        y = 4,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Normal,
                        dynamic = function(context)
                            return "Memory: " .. math.random(100, 2000) .. "MB"
                        end
                    }
                }
            },
            
            -- Footer/Status Window
            {
                id = 8,
                type = "Window",
                title = {
                    type = "Text",
                    value = "READY",
                    foregroundColor = api.FGColors.Brights.White,
                    backgroundColor = api.BGColors.NoBrights.Green,
                    style = api.TextStyle.Bold,
                    dynamic = function(context)
                        return "READY - Press F1 for help"
                    end
                },
                width = "w - 2",
                height = 3,
                x = 2,
                y = "h - 3",
                border = api.BoxDrawing.NoBorder,
                backgroundColor = api.BGColors.NoBrights.Black
            }
        }
    }
}

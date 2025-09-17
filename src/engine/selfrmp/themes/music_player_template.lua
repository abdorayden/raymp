--
--	rmp music player template
--	professional audio interface with visualizations
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
        border = api.BoxDrawing.RoundedCorners,
        backgroundColor = api.BGColors.NoBrights.Black,
        children = {
            -- Album Art Display
            {
                id = 2,
                type = "Window",
                title = {
                    type = "Text",
                    value = "🎵 NOW PLAYING",
                    foregroundColor = api.FGColors.Brights.Magenta,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = 30,
                height = 15,
                x = "w/2 - 15",
                y = 3,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 3,
                        type = "Text",
                        value = "╔══════════════╗",
                        x = 8,
                        y = 5,
                        foregroundColor = api.FGColors.Brights.Blue,
                        style = api.TextStyle.Bold
                    },
                    {
                        id = 4,
                        type = "Text",
                        value = "║   MUSIC ICON  ║",
                        x = 8,
                        y = 6,
                        foregroundColor = api.FGColors.Brights.Cyan,
                        style = api.TextStyle.Bold
                    },
                    {
                        id = 5,
                        type = "Text",
                        value = "╚══════════════╝",
                        x = 8,
                        y = 7,
                        foregroundColor = api.FGColors.Brights.Blue,
                        style = api.TextStyle.Bold
                    }
                }
            },

            -- Track Info Panel
            {
                id = 6,
                type = "Window",
                title = {
                    type = "Text",
                    value = "TRACK INFO",
                    foregroundColor = api.FGColors.Brights.Green,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = "w - 10",
                height = 6,
                x = 5,
                y = 19,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 7,
                        type = "Text",
                        value = "Artist: Unknown Artist",
                        x = 2,
                        y = 1,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Bold,
                        dynamic = function(context)
                            return "Artist: " .. (context.current_artist or "Unknown Artist")
                        end
                    },
                    {
                        id = 8,
                        type = "Text",
                        value = "Title: Unknown Track",
                        x = 2,
                        y = 2,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Bold,
                        dynamic = function(context)
                            return "Title: " .. (context.current_title or "Unknown Track")
                        end
                    },
                    {
                        id = 9,
                        type = "Text",
                        value = "Album: Unknown Album",
                        x = 2,
                        y = 3,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Normal,
                        dynamic = function(context)
                            return "Album: " .. (context.current_album or "Unknown Album")
                        end
                    }
                }
            },

            -- Progress Bar
            {
                id = 10,
                type = "Window",
                title = nil,
                width = "w - 10",
                height = 3,
                x = 5,
                y = 26,
                border = api.BoxDrawing.NoBorder,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 11,
                        type = "Text",
                        value = "[" .. string.rep(" ", 40) .. "]",
                        x = 2,
                        y = 1,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Bold
                    },
                    {
                        id = 12,
                        type = "Text",
                        value = "0:00 / 0:00",
                        x = "w - 15",
                        y = 1,
                        foregroundColor = api.FGColors.Brights.Yellow,
                        style = api.TextStyle.Bold,
                        dynamic = function(context)
                            return (context.current_time or "0:00") .. " / " .. (context.total_time or "0:00")
                        end
                    }
                }
            },

            -- Control Buttons
            {
                id = 13,
                type = "Window",
                title = nil,
                width = "w - 10",
                height = 5,
                x = 5,
                y = 30,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 14,
                        type = "Text",
                        value = "⏮️  ◀️  ⏸️  ▶️  ⏭️",
                        x = "w/2 - 10",
                        y = 2,
                        foregroundColor = api.FGColors.Brights.Cyan,
                        style = api.TextStyle.Bold
                    },
                    {
                        id = 15,
                        type = "Text",
                        value = "Prev   Play/Pause   Next",
                        x = "w/2 - 10",
                        y = 3,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Normal
                    }
                }
            },

            -- Volume Control
            {
                id = 16,
                type = "Window",
                title = {
                    type = "Text",
                    value = "VOLUME",
                    foregroundColor = api.FGColors.Brights.Green,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = 20,
                height = 4,
                x = "w - 25",
                y = 3,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 17,
                        type = "Text",
                        value = "🔊 " .. string.rep("█", 10),
                        x = 2,
                        y = 1,
                        foregroundColor = api.FGColors.Brights.Green,
                        style = api.TextStyle.Bold,
                        dynamic = function(context)
                            local vol = context.volume or 70
                            local bars = math.floor(vol / 10)
                            return "🔊 " .. string.rep("█", bars) .. string.rep("░", 10 - bars)
                        end
                    }
                }
            },

            -- Playlist/Queue
            {
                id = 18,
                type = "Window",
                title = {
                    type = "Text",
                    value = "PLAYLIST",
                    foregroundColor = api.FGColors.Brights.Yellow,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = "w - 10",
                height = 8,
                x = 5,
                y = 36,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 19,
                        type = "Text",
                        value = "1. Song One - Artist One",
                        x = 2,
                        y = 1,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Normal
                    },
                    {
                        id = 20,
                        type = "Text",
                        value = "2. Song Two - Artist Two",
                        x = 2,
                        y = 2,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Normal
                    },
                    {
                        id = 21,
                        type = "Text",
                        value = "3. Song Three - Artist Three",
                        x = 2,
                        y = 3,
                        foregroundColor = api.FGColors.Brights.White,
                        style = api.TextStyle.Normal
                    }
                }
            },

            -- Visualizer/Equalizer
            {
                id = 22,
                type = "Window",
                title = {
                    type = "Text",
                    value = "VISUALIZER",
                    foregroundColor = api.FGColors.Brights.Blue,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold
                },
                width = 25,
                height = 8,
                x = 5,
                y = 3,
                border = api.BoxDrawing.LightBorder,
                backgroundColor = api.BGColors.NoBrights.Black,
                children = {
                    {
                        id = 23,
                        type = "Text",
                        value = "█   ███  ████  ███  █",
                        x = 2,
                        y = 3,
                        foregroundColor = api.FGColors.Brights.Cyan,
                        style = api.TextStyle.Bold,
                        dynamic = function(context)
                            -- Simple random visualizer bars
                            local bars = {}
                            for i = 1, 8 do
                                local height = math.random(1, 5)
                                bars[i] = string.rep("█", height)
                            end
                            return table.unpack(table.concat(bars, " "))
                        end
                    }
                }
            },

            -- Status Bar
            {
                id = 24,
                type = "Window",
                title = {
                    type = "Text",
                    value = "STOPPED",
                    foregroundColor = api.FGColors.Brights.Red,
                    backgroundColor = api.BGColors.NoBrights.Black,
                    style = api.TextStyle.Bold,
                    dynamic = function(context)
                        local status = context.player_status or "STOPPED"
                        local color = status == "PLAYING" and api.FGColors.Brights.Green 
                                    or status == "PAUSED" and api.FGColors.Brights.Yellow 
                                    or api.FGColors.Brights.Red
                        -- return {value = status, foregroundColor = color, backgroundColor = api.BGColors.NoBrights.Black}
			return status
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

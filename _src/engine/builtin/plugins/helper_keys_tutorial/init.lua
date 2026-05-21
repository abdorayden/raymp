local api = require("rmp.rmp")

local helps = nil

return function(frame, x, y, xx, yy)
    frame:addEventListener(api.EventType.TransformDataGet, function(data)
        if type(data) == "table" then
            helps = data
        end
    end)

    frame:writeText(x, y, "Keys:", api.FGColors.Brights.Red, nil, api.TextStyle.Bold)

    if helps and helps.UP then
        frame:writeText(x + 1, y + 1, helps.UP)
        frame:writeText(x + 3, y + 2, "to scrolle the window UP")
    end
    if helps and helps.DOWN then
        frame:writeText(x + 1, y + 3, helps.DOWN)
        frame:writeText(x + 1, y + 4, "to scrolle the window DOWN")
    end
end

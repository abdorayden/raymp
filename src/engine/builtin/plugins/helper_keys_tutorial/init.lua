local api = require("rmp.rmp")

local helps = nil
return function(x, y, xx, yy)
    local vt = api.VirtualTerminal.new()
    vt:addEventListener(api.EventType.TransformDataGet, function(data)
        if type(data) == "table" then
            helps = data
        end
    end)

    vt:writeText(x, y, "Keys:", api.FGColors.Brights.Red, nil, api.TextStyle.Bold)

    if helps and helps.UP then
        vt:writeText(x + 1, y + 1, helps.UP)
        vt:writeText(x + 3, y + 2, "to scrolle the window UP")
    end
    if helps and helps.DOWN then
        vt:writeText(x + 1, y + 3, helps.DOWN)
        vt:writeText(x + 1, y + 4, "to scrolle the window DOWN")
    end
    return vt
end

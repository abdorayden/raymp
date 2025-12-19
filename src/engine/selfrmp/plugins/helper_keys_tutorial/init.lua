local api = require("rmp.rmp")

local helps = nil
return function(x, y, xx, yy)
    local vt = api.VirtualTerminal.new()
    vt:addEventListener(api.EventType.TransformDataGet, function(data)
        if type(data) == "table" then
            helps = data
        end
    end)

    if helps and helps.UP then
        vt:writeText(x + 1, y + 1, helps.UP)
    end
    if helps and helps.DOWN then
        vt:writeText(x + 1, y + 3, helps.DOWN)
    end
    return vt
end

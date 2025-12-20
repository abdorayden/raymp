local api = require("rmp.rmp")

local bgc = {
    api.BGColors.Brights.Yellow,
    api.BGColors.Brights.Black,
    api.BGColors.Brights.Yellow,
    api.BGColors.Brights.Black,
    api.BGColors.Brights.Yellow,
    api.BGColors.Brights.Black
}

return function(x, y, xx, yy)
    local h, w = (yy - y - 1), (xx - x - 1)
    local centerX, centerY = x + w / 2, y + h / 2

    local vt = api.VirtualTerminal.new()
    local time = os.date("%H:%M:%S")
    local timeWidth = #time

    for i = 0, h - 1 do
        local intensity = math.floor(255 * (i / h))
        api.Draw:rectangle(x, y + i, w, 1, api.BGColors.NoBrights.Black, vt)
    end

    local timeX = centerX - timeWidth / 2
    local timeY = centerY

    api.Draw:rectangle(timeX - 2, timeY - 1, timeWidth + 4, 2, api.BGColors.NoBrights.Blue, vt)

    if math.floor(os.clock() * 2) % 2 == 0 then
        time = os.date("%H:%M:%S")
    else
        time = os.date("%H %M %S")
    end

    vt:writeText(timeX, timeY, time, api.FGColors.Brights.White, api.BGColors.NoBrights.Blue, api.TextStyle.Bold)

    for i = 1, 10 do
        local angle = os.clock() + i * 0.6
        local radius = 5 + math.sin(os.clock() + i) * 3
        local partX = centerX + math.cos(angle) * radius
        local partY = centerY + math.sin(angle) * radius

        api.Draw:rectangle(
            math.floor(partX), math.floor(partY),
            1, 1,
            bgc[math.random(1, 4)],
            vt
        )
    end

    return vt
end

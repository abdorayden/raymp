local api = require("rmp.rmp")

local chars = { "$", "?", "!", "#", "&", "A", "B", "C", "1", "2", "3", "0" }
local streams = {}
local theme = nil

return function(x, y, xx, yy)
    local h, w = (yy - y), (xx - x)
    local cols = math.floor(w / 2)

    theme = raymp:getTheme()

    for i = 1, cols do
        if not streams[i] then
            streams[i] = {
                position = math.random(-20, 0),
                speed = math.random(5, 15) / 10,
                length = math.random(5, 20),
                chars = {}
            }

            for j = 1, streams[i].length do
                streams[i].chars[j] = chars[math.random(1, #chars)]
            end
        end

        local stream = streams[i]
        stream.position = stream.position + stream.speed

        if stream.position - stream.length > h then
            stream.position = math.random(-20, 0)
            stream.speed = math.random(5, 15) / 10
            stream.length = math.random(5, 20)

            for j = 1, stream.length do
                stream.chars[j] = chars[math.random(1, #chars)]
            end
        end

        for j = 1, stream.length do
            local charY = math.floor(stream.position - j + 0.5)
            if charY >= 1 and charY <= h then
                local color
                if j == 1 then
                    color = theme and api.colorFromHex(theme.MutedElements) or api.BGColors.Brights.White
                elseif j == 2 then
                    color = theme and api.colorFromHex(theme.Highlight) or api.BGColors.Brights.Green
                else
                    color = theme and api.colorFromHex(theme.AccentElements) or api.FGColors.NoBrights.Green
                end

                raymp:writeText(
                    x + (i - 1) * 2,
                    y + charY - 1,
                    stream.chars[j],
                    color,
                    theme and api.colorFromHex(theme.BackGround, api.BG) or
                    api.BGColors.NoBrights.Black
                )
            end
        end
    end
end

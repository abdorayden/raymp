-- broke window col at thet right

local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
    local h, w = (yy - y), (xx - x)
    local cols = math.floor(w / 2)  
    local streams = {}
    local chars = { "░", "▒", "▓", "█", "A", "B", "C", "1", "2", "3", "0" }
    
    for i = 1, cols do
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
    
    while true do
        local vt = api.VirtualTerminal.new()
        
        for i = 1, cols do
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
                local charY = stream.position - j
                if charY >= 0 and charY < h then
                    local color
                    if j == 1 then
                        color = api.BGColors.Brights.White
                    elseif j == 2 then
                        color = api.BGColors.Brights.Green
                    else
                        local intensity = math.floor(255 * (1 - j/stream.length))
                        color = api.FGColors.NoBrights.Green  
                    end
                    
		    vt:merge(
		    	api.VirtualTerminal.new():writeText(
                         	x + i * 2, y + charY,
                    		stream.chars[j],
				color,
				api.BGColors.NoBrights.Black
			)
		    )
                end
            end
        end
        
        coroutine.yield(vt)
        
    end
end)

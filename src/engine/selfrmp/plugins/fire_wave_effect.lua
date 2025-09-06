local api = require("rmp.rmp")

return api.quickRoutine(function(x, y, xx, yy)
    local h, w = (yy - y), (xx - x)
    local cols = math.floor(w / 3)  
    local wrec = math.floor(w / cols)
    local fire = {}  
    
    for i = 1, cols do
        fire[i] = {}
        for j = 1, h do
            fire[i][j] = 0
        end
        fire[i][h] = 100
    end
    
    while true do
        local vt = api.VirtualTerminal.new()
        
        for i = 2, cols - 1 do
            for j = 2, h - 1 do
                fire[i][j] = (fire[i-1][j+1] + fire[i][j+1] + fire[i+1][j+1]) / 3
                fire[i][j] = fire[i][j] * (0.9 + math.random() * 0.2)
                fire[i][j] = math.max(0, math.min(100, fire[i][j]))
            end
        end
        
        if math.random() < 0.3 then
            local sparkCol = math.random(2, cols - 1)
            fire[sparkCol][h] = 100
        end
        
        for i = 1, cols do
            for j = 1, h do
                if fire[i][j] > 10 then
                    local color
                    if fire[i][j] > 80 then
                        color = api.BGColors.Brights.White
                    elseif fire[i][j] > 60 then
                        color = api.BGColors.Brights.Yellow
                    elseif fire[i][j] > 40 then
                        color = api.BGColors.Brights.Red
                    else
                        color = api.BGColors.NoBrights.Red
                    end
                    
                    vt:merge(api.Draw:rectangle(
                        x + wrec * (i - 1),
                        y + j,
                        wrec,
                        1,
                        color
                    ))
                end
            end
        end
        
        coroutine.yield(vt)
        
        local delay = 0.08
        local start = os.clock()
        while os.clock() - start < delay do end
    end
end)

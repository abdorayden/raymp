local api = require("rmp.rmp")

local theme = {
    def = {
        BackGround = "#000000",
        BorderColor = "#ffffff",
        TitleBackGround = "#000000",
        TitleText = "#ffffff",
        PrimaryContent = "#ffffff",
        SecondaryContent = "#ffffff",
        AccentElements = "#ffffff",
        Highlight = "#ffffff",
        MutedElements = "#ffffff"
    }
}

local THEME_NAME = "black_and_white"
local doApply = false

return function()
    doApply = raymp.engine.theme == THEME_NAME
    raymp:onTemplate(function(template)
        if template then
            if doApply then
                raymp:applyTheme(template, theme, "def")
            end
        end
    end)

    raymp:addEventListener(api.EventType.TransformDataGet, function(data)
        if data and data.ThemeManagerObj then
            data.ThemeManagerObj:addMyTheme(THEME_NAME, theme)
        end
    end)
end

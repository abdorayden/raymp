local api = require("rmp.rmp")

-- Builtin-like Vim colorscheme: desert (approximation)

local THEME_NAME = "desert"
local doApply = false

local theme = {
    def = {
        BackGround = "#2b2b2b",
        BorderColor = "#e0e0e0",
        TitleBackGround = "#2b2b2b",
        TitleText = "#e0e0e0",
        PrimaryContent = "#c0a000",
        SecondaryContent = "#87afd7",
        AccentElements = "#d75f5f",
        Highlight = "#ffaf5f",
        MutedElements = "#a8a8a8"
    }
}

return function()
    doApply = raymp.engine.settings.theme == THEME_NAME
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

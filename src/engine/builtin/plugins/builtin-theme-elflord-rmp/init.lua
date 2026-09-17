local api = require("rmp.rmp")

-- Builtin-like Vim colorscheme: elflord (approximation)

local theme = {
    def = {
        BackGround = "#1c1c1c",
        BorderColor = "#d0d0d0",
        TitleBackGround = "#1c1c1c",
        TitleText = "#d0d0d0",
        PrimaryContent = "#87af5f",
        SecondaryContent = "#5f87af",
        AccentElements = "#d75f5f",
        Highlight = "#d7af5f",
        MutedElements = "#808080"
    }
}

local THEME_NAME = "elflord"
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

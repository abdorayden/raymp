local api = require("rmp.rmp")

-- Builtin-like Vim colorscheme: default (approximation)

local THEME_NAME = "default"
local doApply = false

local theme = {
    def = {
        BackGround = "#000000",
        BorderColor = "#c0c0c0",
        TitleBackGround = "#000000",
        TitleText = "#c0c0c0",
        PrimaryContent = "#00ff00",
        SecondaryContent = "#00afff",
        AccentElements = "#ff0000",
        Highlight = "#ffff00",
        MutedElements = "#808080"
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

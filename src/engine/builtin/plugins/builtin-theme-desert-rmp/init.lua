local api = require("rmp.rmp")

-- Builtin-like Vim colorscheme: desert (approximation)

local THEME_NAME = "desert"
local doApply = false

local theme = {
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

local function apply(tha_template)
    for _, component in ipairs(tha_template) do
        if component.title then
            if type(component.title) == "string" then
                local val = component.title
                component.title = {
                    value = val,
                    foregroundColor = api.colorFromHex(theme.TitleText, api.FG),
                    backgroundColor = api.colorFromHex(theme.TitleBackGround, api.BG),
                }
            elseif type(component.title) == "table" then
                component.title.foregroundColor = api.colorFromHex(theme.TitleText, api.FG)
                component.title.backgroundColor = api.colorFromHex(theme.TitleBackGround, api.BG)
            else
                component.table = nil
            end
        end
        component.foregroundColor = api.colorFromHex(theme.BorderColor, api.FG)
        component.backgroundColor = api.colorFromHex(theme.BackGround, api.BG)
        if component.children then
            apply(component.children)
        end
    end
end

local vt = api.VirtualTerminal.new(1, 1)
return function()
    vt:onConfiguration(function(cfg)
        local settings = cfg:get("settings")
        if settings and settings.theme and settings.theme == THEME_NAME then
            doApply = true
        else
            doApply = false
        end
    end)
    vt:onTemplate(function(template)
        if template then
            if doApply then
                apply(template)
            end
        end
    end)

    vt:addEventListener(api.EventType.TransformDataGet, function(data)
        if data and data.ThemeManagerObj then
            data.ThemeManagerObj:addMyTheme(THEME_NAME, theme)
        end
    end)


    return vt
end

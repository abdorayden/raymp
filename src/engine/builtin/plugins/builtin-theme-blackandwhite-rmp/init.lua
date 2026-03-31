local api = require("rmp.rmp")

local theme = {
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

local THEME_NAME = "black_and_white"
local doApply = false

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
        if cfg then
            local settings = cfg:get("settings")
            if settings and settings.theme and settings.theme == THEME_NAME then
                doApply = true
            else
                doApply = false
            end
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

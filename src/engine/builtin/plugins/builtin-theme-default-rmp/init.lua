local api = require("rmp.rmp")

-- Builtin-like Vim colorscheme: default (approximation)

local theme = {
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
    vt:onTemplate(function(template)
        if template then
            apply(template)
        end
    end)

    vt:addEventListener(api.EventType.TransformDataPut, function()
        return { theme = theme }
    end)

    return vt
end

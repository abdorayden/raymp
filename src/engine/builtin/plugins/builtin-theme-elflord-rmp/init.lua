local api = require("rmp.rmp")

-- Builtin-like Vim colorscheme: elflord (approximation)

local theme = {
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

return function()
    local vt = api.VirtualTerminal.new(1, 1)

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

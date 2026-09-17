local api = require("rmp.rmp")

local theme = nil

return function(x, y, xx, yy)
    theme = raymp:getTheme()

    raymp:writeText(x, y, "Keys:",
        theme and api.colorFromHex(theme.Highlight) or api.FGColors.Brights.Red,
        theme and api.colorFromHex(theme.BackGround, api.BG) or api.FGColors.Brights.Black,
        api.TextStyle.Bold)

    raymp:writeText(x + 1, y + 1, "K",
        theme and api.colorFromHex(theme.PrimaryContent) or api.FGColors.Brights.Red,
        theme and api.colorFromHex(theme.BackGround, api.BG) or api.FGColors.Brights.Black
    )
    raymp:writeText(x + 3, y + 2, "to scrolle the window UP",
        theme and api.colorFromHex(theme.SecondaryContent) or api.FGColors.Brights.Red,
        theme and api.colorFromHex(theme.BackGround, api.BG) or api.FGColors.Brights.Black
    )

    raymp:writeText(x + 1, y + 3, "J",
        theme and api.colorFromHex(theme.PrimaryContent) or api.FGColors.Brights.Red,
        theme and api.colorFromHex(theme.BackGround, api.BG) or api.FGColors.Brights.Black
    )
    raymp:writeText(x + 1, y + 4, "to scrolle the window DOWN",
        theme and api.colorFromHex(theme.SecondaryContent) or api.FGColors.Brights.Red,
        theme and api.colorFromHex(theme.BackGround, api.BG) or api.FGColors.Brights.Black
    )
end

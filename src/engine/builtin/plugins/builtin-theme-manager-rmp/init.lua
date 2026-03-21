local api = require("rmp.rmp")
local OOP = require("rmp.oop")
local util = require("rmp.util")

local VirtualTerminal = api.VirtualTerminal
local HashMap = util.HashMap

local ThemeManager = OOP.class("ThemeManager")
do
    function ThemeManager:constructor()
        --- {
        ---     themeName : {table colors}
        --- }
        self.themesName = HashMap()
        self.selectedTheme = ""
    end

    function ThemeManager:getThemesName()
        return self.themesName
    end

    function ThemeManager:getSelectedTheme()
        if self.selectedTheme and self.selectedTheme ~= "" then
            return self.themesName:get(self.selectedTheme)
        else
            return nil
        end
    end

    function ThemeManager:selectTheme(themeName)
        self.selectedTheme = themeName
    end

    function ThemeManager:addMyTheme(name, myTheme)
        if name and myTheme then
            self.themesName:put(name, myTheme)
        end
    end

    function ThemeManager:getAllThemesNames()
        return self.themesName:keySet()
    end
end

local themeManager = ThemeManager()
local vt = VirtualTerminal(1, 1)


return function()
    vt:onConfiguration(function(cfg)
        if cfg then
            local settings = cfg:get("settings")
            if settings and settings.theme then
                themeManager:selectTheme(settings.theme)
            end
        end
    end)

    vt:onDataPut(function()
        return {
            ThemeManagerObj = themeManager,
            theme = themeManager:getSelectedTheme()
        }
    end)
    return vt
end

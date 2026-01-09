local api = require("rmp.rmp")
local OOP = require("rmp.oop")

-- optimize all Components and create more

--- @module 'rmp.components'
local Components = {}

-- TODO: table
--
---- TODO: Add sorting, selection, and editing features
---- TODO: Add scrolling for large tables
---- TODO: Add support for different data types and formatting
---- TODO: add colors
--- @class Table
Components.Table = OOP.class("Table", nil, api.Renderable)
do
    --- @param x integer
    --- @param y integer
    --- @param headers table
    --- @param rows table
    --- @return self
    function Components.Table:constructor(x, y, headers, rows)
        self.x = x or 1
        self.y = y or 1
        self._headers = headers or {}
        self._rows = rows or {}
        self._colWidths = {}
        self:_calculateColumnWidths()
        return self
    end

    --- @param x integer
    function Components.Table:setX(x)
        self.x = x
    end

    --- @param y integer
    function Components.Table:setY(y)
        self.y = y
    end

    --- @private
    function Components.Table:_calculateColumnWidths()
        for i, header in ipairs(self._headers) do
            self._colWidths[i] = #header
        end

        for _, row in ipairs(self._rows) do
            for i, cell in ipairs(row) do
                local cellStr = tostring(cell)
                if self._colWidths[i] then
                    self._colWidths[i] = math.max(self._colWidths[i], #cellStr)
                else
                    self._colWidths[i] = #cellStr
                end
            end
        end

        for i = 1, #self._colWidths do
            self._colWidths[i] = self._colWidths[i] + 2
        end
    end

    --- @return table
    function Components.Table:getColumnWidths()
        return self._colWidths
    end

    --- @param headers table
    function Components.Table:setHeaders(headers)
        self._headers = headers or {}
        self:_calculateColumnWidths()
    end

    --- @param rowIndex integer
    --- @param colIndex integer
    --- @param value integer
    function Components.Table:setDataAt(rowIndex, colIndex, value)
        if self._rows[rowIndex] then
            self._rows[rowIndex][colIndex] = value
            self:_calculateColumnWidths()
        end
    end

    --- @param rowIndex integer
    --- @param colIndex integer
    --- @return integer | nil
    function Components.Table:getDataAt(rowIndex, colIndex)
        if self._rows[rowIndex] then
            return self._rows[rowIndex][colIndex]
        end
        return nil
    end

    --- @param row integer
    function Components.Table:addRow(row)
        table.insert(self._rows, row)
        self:_calculateColumnWidths()
    end

    --- @param vterm VirtualTerminal
    --- @return VirtualTerminal
    --- @overload fun(param:VirtualTerminal) : VirtualTerminal
    function Components.Table:render(vterm)
        local x = self.x
        local y = self.y
        --- @diagnostic disable-next-line
        local vterm = vterm or Components.VirtualTerminal.new()
        local currentY = y

        local topBorder = "┌"
        for i, width in ipairs(self._colWidths) do
            topBorder = topBorder .. string.rep("─", width) .. (i < #self._colWidths and "┬" or "┐")
        end
        vterm:writeText(x, currentY, topBorder)
        currentY = currentY + 1

        local headerLine = "│"
        for i, header in ipairs(self._headers) do
            local padding = self._colWidths[i] - #header
            local leftPad = math.floor(padding / 2)
            local rightPad = padding - leftPad
            headerLine = headerLine .. string.rep(" ", leftPad) .. header .. string.rep(" ", rightPad) .. "│"
        end
        vterm:writeText(x, currentY, headerLine)
        currentY = currentY + 1

        local separator = "├"
        for i, width in ipairs(self._colWidths) do
            separator = separator .. string.rep("─", width) .. (i < #self._colWidths and "┼" or "┤")
        end
        vterm:writeText(x, currentY, separator)
        currentY = currentY + 1

        for _, row in ipairs(self._rows) do
            local rowLine = "│"
            for i, cell in ipairs(row) do
                local cellStr = tostring(cell)
                local padding = self._colWidths[i] - #cellStr
                local leftPad = 1
                local rightPad = padding - leftPad
                rowLine = rowLine .. string.rep(" ", leftPad) .. cellStr .. string.rep(" ", rightPad) .. "│"
            end
            vterm:writeText(x, currentY, rowLine)
            currentY = currentY + 1
        end

        local bottomBorder = "└"
        for i, width in ipairs(self._colWidths) do
            bottomBorder = bottomBorder .. string.rep("─", width) .. (i < #self._colWidths and "┴" or "┘")
        end
        vterm:writeText(x, currentY, bottomBorder)

        return vterm
    end
end

-- TODO: Popup

--- @enum PopupPosition
Components.PopupPosition = {
    CENTER       = api.enum(true),
    TOP_LEFT     = api.enum(),
    TOP_RIGHT    = api.enum(),
    BUTTOM_LEFT  = api.enum(),
    BUTTOM_RIGHT = api.enum()
}

-- TODO: handle timeout async for popups
--- @class Popup
Components.Popup = OOP.class("Popup")
do -- Popups
    --- @param message string
    --- @param title string
    --- @param border_color FGColors
    --- @param bg_color FGColors
    --- @param poslayout PopupPosition
    --- @param vterm VirtualTerminal | nil
    --- @return VirtualTerminal
    function Components.Popup:run(message, title, border_color, bg_color, poslayout, vterm)
        local rows, cols = api.Terminal:getSize()
        poslayout = poslayout or Components.PopupPosition.CENTER
        local x, y = nil, nil
        if poslayout == Components.PopupPosition.TOP_LEFT then
            x, y = 2, 2
        elseif poslayout == Components.PopupPosition.TOP_RIGHT then
            x, y = cols - (cols / 4) - 2, 2
        elseif poslayout == Components.PopupPosition.BUTTOM_LEFT then
            x, y = 2, rows - (rows / 4) - 2
        elseif poslayout == Components.PopupPosition.BUTTOM_RIGHT then
            x, y = cols - (cols / 4) - 2, rows - (rows / 4) - 2
        else
            x, y = (cols / 2) - (cols / 8), (rows / 2) - (rows / 8)
        end

        --- @diagnostic disable-next-line
        vterm = vterm or api.VirtualTerminal.new()

        --- @diagnostic disable-next-line
        return api.Window.new(99, vterm):createWindow(
            title,
            -- 		cols / 2 ,
            -- 		rows / 2 ,
            cols / 4,
            rows / 4,
            x,
            y,
            border_color,
            bg_color,
            api.BoxDrawing.LightBorder,
            function(lx, ly, xx, yy)
                -- TODO: fix message inside box
                --- @diagnostic disable-next-line
                vterm = api.VirtualTerminal.new()
                vterm:moveCursor(lx + 1, ly + 1)
                -- i think i delete this helper function
                -- TODO: implement cleanTextLocal

                -- local text = remove_new_lines_from_str(message)
                local text = message

                local spl = 1
                Remider = 0
                if #text > (xx - lx - 1) then
                    if spl == math.floor((xx - lx - 1) / #text) then
                        spl = math.floor(#text / (xx - lx - 1)) + 1
                    else
                        spl = math.floor(#text / (xx - lx - 1))
                    end
                    Remider = #text % (xx - lx)
                end

                for i = 0, math.min(spl, yy - ly - 4) do
                    vterm:writeText(lx + 1, ly + 1 + i,
                        string.sub(text, (xx - lx - 1) * i + 1, (xx - lx - 1) * (i + 1) - 1),
                        nil, nil, nil)
                end
                return vterm
            end)
    end
end

-- TODO: Notify
--- @class Notify
Components.Notify = OOP.class("Notify", Components.Popup)
do
    --- @param message string | nil
    --- @param vterm VirtualTerminal | nil
    --- @return self
    function Components.Notify:constructor(
        message, -- the message
        vterm
    )
        self.message = message or ""
        --- @diagnostic disable-next-line
        self.vterm = vterm or api.VirtualTerminal.new()
        return self
    end

    --- @param message string | nil
    --- @return self
    function Components.Notify:setMessage(message)
        self.message = message or ""
        return self
    end

    --- @param poslayout PopupPosition
    function Components.Notify:error(poslayout)
        poslayout = poslayout or Components.PopupPosition.CENTER

        --- @diagnostic disable-next-line
        return self:super(
            "run",
            self.message,
            --- @diagnostic disable-next-line
            api.Text.new(
                "[ " .. "ERROR" .. " ]",
                api.TextStyle.Bold,
                api.FGColors.NoBrights.White,
                api.BGColors.NoBrights.BGRed
            ),
            api.FGColors.NoBrights.Red,
            nil,
            poslayout,
            self.vterm
        )
    end

    --- @param poslayout PopupPosition
    function Components.Notify:info(poslayout)
        poslayout = poslayout or Components.PopupPosition.CENTER

        --- @diagnostic disable-next-line
        return self:super(
            "run",
            self.message,
            --- @diagnostic disable-next-line
            api.Text.new(
                "[ " .. "INFO" .. " ]",
                api.TextStyle.Bold,
                api.FGColors.NoBrights.White,
                api.BGColors.NoBrights.Green
            ),
            api.FGColors.NoBrights.Green,
            nil,
            poslayout,
            self.vterm
        )
    end

    --- @param poslayout PopupPosition
    function Components.Notify:msg(poslayout)
        poslayout = poslayout or Components.PopupPosition.CENTER

        --- @diagnostic disable-next-line
        return self:super(
            "run",
            self.message,
            --- @diagnostic disable-next-line
            api.Text.new(
                "[ " .. "MESSAGE" .. " ]",
                api.TextStyle.Bold,
                api.FGColors.NoBrights.White,
                api.BGColors.NoBrights.Blue
            ),
            api.FGColors.NoBrights.Blue,
            nil,
            poslayout,
            self.vterm
        )
    end

    --- @param poslayout PopupPosition
    function Components.Notify:warning(poslayout)
        poslayout = poslayout or Components.PopupPosition.CENTER

        --- @diagnostic disable-next-line
        return self:super(
            "run",
            self.message,
            --- @diagnostic disable-next-line
            api.Text.new(
                "[ " .. "Warning" .. " ]",
                api.TextStyle.Bold,
                api.FGColors.NoBrights.White,
                api.BGColors.NoBrights.Yellow
            ),
            api.FGColors.NoBrights.Yellow,
            nil,
            poslayout,
            self.vterm
        )
    end
end

-- TODO: StatusBar
--- @enum StatusBarPosition
Components.StatusBarPosition = {
    LEFT = "left",
    RIGHT = "right",
    CENTER = "CENTER"
}

--- @class StatusBar
Components.StatusBar = OOP.class("StatusBar", nil, api.Renderable)
do
    --- @param y integer
    --- @param width integer
    --- @return self
    function Components.StatusBar:constructor(y, width)
        local _, w = api.Terminal:getSize()
        self.width = width or w
        self._y = y or 1
        self._components = {}
        return self
    end

    -- Add a component to the status bar
    -- text: the text to display
    -- fg: foreground color (from api.FGColors)
    -- bg: background color (from api.BGColors)
    -- style: text style (from api.TextStyle)
    -- align: "left" (default), "right", or "center"
    --- @param text string | nil
    --- @param fg FGColors
    --- @param bg BGColors
    --- @param style TextStyle
    --- @param align StatusBarPosition
    --- @return self
    function Components.StatusBar:addComponents(text, fg, bg, style, align)
        table.insert(self._components, {
            text = text or "",
            fg = fg,
            bg = bg,
            style = style,
            align = align or "left"
        })
        return self
    end

    --- @return self
    function Components.StatusBar:clear()
        self._components = {}
        return self
    end

    --- @param index integer
    --- @param text string | nil
    --- @param fg FGColors
    --- @param bg BGColors
    --- @param style TextStyle
    --- @param align StatusBarPosition
    --- @return self
    function Components.StatusBar:updateComponents(index, text, fg, bg, style, align)
        if self._components[index] then
            if text then self._components[index].text = text end
            if fg then self._components[index].fg = fg end
            if bg then self._components[index].bg = bg end
            if style then self._components[index].style = style end
            if align then self._components[index].align = align end
        end
        return self
    end

    --- @return VirtualTerminal
    function Components.StatusBar:render()
        local width = self.width
        --- @diagnostic disable-next-line
        local vterm = api.VirtualTerminal.new()

        -- set background color black as default
        api.Draw:line(1, self._y, width, api.BGColors.NoBrights.Black, vterm)

        local leftComps, rightComps, centerComps = {}, {}, {}
        for _, comp in ipairs(self._components) do
            if comp.align == "right" then
                table.insert(rightComps, comp)
            elseif comp.align == "center" then
                table.insert(centerComps, comp)
            else
                table.insert(leftComps, comp)
            end
        end

        local leftWidth, rightWidth, centerWidth = 0, 0, 0
        for _, c in ipairs(leftComps) do leftWidth = leftWidth + #c.text end
        for _, c in ipairs(rightComps) do rightWidth = rightWidth + #c.text end
        for _, c in ipairs(centerComps) do centerWidth = centerWidth + #c.text end

        local x = 1

        for _, comp in ipairs(leftComps) do
            --- @diagnostic disable-next-line
            local text = api.Text.new(comp.text, comp.style, comp.fg, comp.bg)
            text:setPosition(x, self._y)
            vterm:merge(text:render(), true)
            x = x + #comp.text
        end

        local remaining = width - leftWidth - rightWidth - centerWidth

        if #centerComps > 0 then
            local leftPad = math.floor(remaining / 2)
            if leftPad > 0 then
                --- @diagnostic disable-next-line
                local pad = api.Text.new(string.rep(" ", leftPad), nil, nil, nil)
                pad:setPosition(x, self._y)
                vterm:merge(pad:render(), true)
                x = x + leftPad
            end

            for _, comp in ipairs(centerComps) do
                local text = api.Text.new(comp.text, comp.style, comp.fg, comp.bg)
                text:setPosition(x, self._y)
                vterm:merge(text:render(), true)
                x = x + #comp.text
            end

            local rightPad = remaining - leftPad
            if rightPad > 0 then
                local pad = api.Text.new(string.rep(" ", rightPad), nil, nil, nil)
                pad:setPosition(x, self._y)
                vterm:merge(pad:render(), true)
                x = x + rightPad
            end
        else
            if remaining > 0 then
                --- @diagnostic disable-next-line
                local pad = api.Text.new(string.rep(" ", remaining), nil, nil, nil)
                pad:setPosition(x, self._y)
                vterm:merge(pad:render(), true)
                x = x + remaining
            end
        end

        for _, comp in ipairs(rightComps) do
            local text = api.Text.new(comp.text, comp.style, comp.fg, comp.bg)
            text:setPosition(x, self._y)
            vterm:merge(text:render(), true)
            x = x + #comp.text
        end

        return vterm
    end
end

-- TODO: ProgressBar
Components.ProgressBar = OOP.class("ProgressBar")
do
end

-- TODO: ShadowInput
Components.ShadowInput = OOP.class("ShadowInput")
do
end
-- TODO: Help
Components.Help = OOP.class("Help")
do
end
-- TODO: Menu
Components.Menu = OOP.class("Menu")
do
end

-- TODO: Code
-- TODO: handle RE for better syntax highlighting
--- @enum CodeSyntax
Components.CodeSyntax = {
    LUA = {
        { word = "--",       type = "comment",    color = api.FGColors.Brights.Black },
        { word = "and",      type = "logical",    color = api.FGColors.Brights.Magenta },
        { word = "break",    type = "control",    color = api.FGColors.Brights.Red },
        { word = "do",       type = "control",    color = api.FGColors.Brights.Red },
        { word = "else",     type = "control",    color = api.FGColors.Brights.Red },
        { word = "elseif",   type = "control",    color = api.FGColors.Brights.Red },
        { word = "end",      type = "control",    color = api.FGColors.Brights.Red },
        { word = "false",    type = "literal",    color = api.FGColors.Brights.Cyan },
        { word = "for",      type = "control",    color = api.FGColors.Brights.Red },
        { word = "function", type = "definition", color = api.FGColors.Brights.Blue },
        { word = "goto",     type = "control",    color = api.FGColors.Brights.Red },
        { word = "if",       type = "control",    color = api.FGColors.Brights.Red },
        { word = "in",       type = "control",    color = api.FGColors.Brights.Red },
        { word = "local",    type = "definition", color = api.FGColors.Brights.Blue },
        { word = "nil",      type = "literal",    color = api.FGColors.Brights.Cyan },
        { word = "not",      type = "logical",    color = api.FGColors.Brights.Magenta },
        { word = "or",       type = "logical",    color = api.FGColors.Brights.Magenta },
        { word = "repeat",   type = "control",    color = api.FGColors.Brights.Red },
        { word = "return",   type = "control",    color = api.FGColors.Brights.Red },
        { word = "then",     type = "control",    color = api.FGColors.Brights.Red },
        { word = "true",     type = "literal",    color = api.FGColors.Brights.Cyan },
        { word = "until",    type = "control",    color = api.FGColors.Brights.Red },
        { word = "while",    type = "control",    color = api.FGColors.Brights.Red }
    },
    C = {
        { word = "//",       type = "comment",        color = api.FGColors.Brights.Black },
        { word = "auto",     type = "storage_class",  color = api.FGColors.Brights.Yellow },
        { word = "break",    type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "case",     type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "char",     type = "data_type",      color = api.FGColors.Brights.Green },
        { word = "const",    type = "type_qualifier", color = api.FGColors.Brights.Yellow },
        { word = "continue", type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "default",  type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "do",       type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "double",   type = "data_type",      color = api.FGColors.Brights.Green },
        { word = "else",     type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "enum",     type = "complex_type",   color = api.FGColors.Brights.Cyan },
        { word = "extern",   type = "storage_class",  color = api.FGColors.Brights.Yellow },
        { word = "float",    type = "data_type",      color = api.FGColors.Brights.Green },
        { word = "for",      type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "goto",     type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "if",       type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "int",      type = "data_type",      color = api.FGColors.Brights.Green },
        { word = "long",     type = "data_type",      color = api.FGColors.Brights.Green },
        { word = "register", type = "storage_class",  color = api.FGColors.Brights.Yellow },
        { word = "return",   type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "short",    type = "data_type",      color = api.FGColors.Brights.Green },
        { word = "signed",   type = "type_qualifier", color = api.FGColors.Brights.Yellow },
        { word = "sizeof",   type = "operator",       color = api.FGColors.Brights.Magenta },
        { word = "static",   type = "storage_class",  color = api.FGColors.Brights.Yellow },
        { word = "struct",   type = "complex_type",   color = api.FGColors.Brights.Cyan },
        { word = "switch",   type = "control_flow",   color = api.FGColors.Brights.Red },
        { word = "typedef",  type = "storage_class",  color = api.FGColors.Brights.Yellow },
        { word = "union",    type = "complex_type",   color = api.FGColors.Brights.Cyan },
        { word = "unsigned", type = "type_qualifier", color = api.FGColors.Brights.Yellow },
        { word = "void",     type = "data_type",      color = api.FGColors.Brights.Green },
        { word = "volatile", type = "type_qualifier", color = api.FGColors.Brights.Yellow },
        { word = "while",    type = "control_flow",   color = api.FGColors.Brights.Red }
    },
    PYTHON = {
        { word = "#",        type = "comment",   color = api.FGColors.Brights.Black },
        { word = "False",    type = "constant",  color = api.FGColors.Brights.Cyan,    version = "2.3+" },
        { word = "None",     type = "constant",  color = api.FGColors.Brights.Cyan,    version = "all" },
        { word = "True",     type = "constant",  color = api.FGColors.Brights.Cyan,    version = "2.3+" },
        { word = "and",      type = "operator",  color = api.FGColors.Brights.Magenta, version = "all" },
        { word = "as",       type = "clause",    color = api.FGColors.Brights.Yellow,  version = "2.5+" },
        { word = "assert",   type = "debugging", color = api.FGColors.Brights.Red,     version = "all" },
        { word = "async",    type = "async",     color = api.FGColors.Brights.Blue,    version = "3.5+" },
        { word = "await",    type = "async",     color = api.FGColors.Brights.Blue,    version = "3.5+" },
        { word = "break",    type = "control",   color = api.FGColors.Brights.Red,     version = "all" },
        { word = "class",    type = "oop",       color = api.FGColors.Brights.Blue,    version = "all" },
        { word = "continue", type = "control",   color = api.FGColors.Brights.Red,     version = "all" },
        { word = "def",      type = "function",  color = api.FGColors.Brights.Blue,    version = "all" },
        { word = "del",      type = "operation", color = api.FGColors.Brights.Magenta, version = "all" },
        { word = "elif",     type = "control",   color = api.FGColors.Brights.Red,     version = "all" },
        { word = "else",     type = "control",   color = api.FGColors.Brights.Red,     version = "all" },
        { word = "except",   type = "exception", color = api.FGColors.Brights.Yellow,  version = "all" },
        { word = "finally",  type = "exception", color = api.FGColors.Brights.Yellow,  version = "all" },
        { word = "for",      type = "control",   color = api.FGColors.Brights.Red,     version = "all" },
        { word = "from",     type = "import",    color = api.FGColors.Brights.Green,   version = "all" },
        { word = "global",   type = "scope",     color = api.FGColors.Brights.Yellow,  version = "all" },
        { word = "if",       type = "control",   color = api.FGColors.Brights.Red,     version = "all" },
        { word = "import",   type = "import",    color = api.FGColors.Brights.Green,   version = "all" },
        { word = "in",       type = "operator",  color = api.FGColors.Brights.Magenta, version = "all" },
        { word = "is",       type = "operator",  color = api.FGColors.Brights.Magenta, version = "all" },
        { word = "lambda",   type = "function",  color = api.FGColors.Brights.Blue,    version = "all" },
        { word = "nonlocal", type = "scope",     color = api.FGColors.Brights.Yellow,  version = "3.0+" },
        { word = "not",      type = "operator",  color = api.FGColors.Brights.Magenta, version = "all" },
        { word = "or",       type = "operator",  color = api.FGColors.Brights.Magenta, version = "all" },
        { word = "pass",     type = "control",   color = api.FGColors.Brights.Red,     version = "all" },
        { word = "raise",    type = "exception", color = api.FGColors.Brights.Yellow,  version = "all" },
        { word = "return",   type = "function",  color = api.FGColors.Brights.Red,     version = "all" },
        { word = "try",      type = "exception", color = api.FGColors.Brights.Yellow,  version = "all" },
        { word = "while",    type = "control",   color = api.FGColors.Brights.Red,     version = "all" },
        { word = "with",     type = "context",   color = api.FGColors.Brights.Yellow,  version = "2.5+" },
        { word = "yield",    type = "function",  color = api.FGColors.Brights.Blue,    version = "2.3+" }
    },
}

--- @class Code
Components.Code = OOP.class("Code", nil, api.Renderable)
do
    --- @param code string | nil
    --- @param syntax table | nil
    --- @param x integer | nil
    --- @param y integer | nil
    --- @return self
    function Components.Code:constructor(code, syntax, x, y)
        self.code = code or ""
        self.syntax = syntax or Components.CodeSyntax.LUA
        self.x = x or 3
        self.y = y or 3
        return self
    end

    --- @param syntax table | nil
    --- @return self
    function Components.Code:setSyntax(syntax)
        self.syntax = syntax
        return self
    end

    --- @param x integer
    --- @param y integer
    --- @return self
    function Components.Code:setPosition(x, y)
        self.x = x
        self.y = y
        return self
    end

    --- @return VirtualTerminal
    function Components.Code:highlight()
        local lines = {}
        for line in self.code:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        local syntaxTable = nil
        if type(self.syntax) == "string" then
            syntaxTable = Components.CodeSyntax[self.syntax]
        elseif type(self.syntax) == "table" then
            syntaxTable = self.syntax
        end

        if not syntaxTable then
            syntaxTable = Components.CodeSyntax.LUA
        end

        --- @diagnostic disable-next-line
        local vt = api.VirtualTerminal.new()

        for lineIdx, line in ipairs(lines) do
            local col = 1
            local i = 1

            while i <= #line do
                local matched = false
                for _, keyword in ipairs(syntaxTable) do
                    -- TODO: check comment type and highlight the rest of the line
                    local word = keyword.word
                    local wordLen = #word

                    if i + wordLen - 1 <= #line then
                        local substr = line:sub(i, i + wordLen - 1)
                        local before = i == 1 or line:sub(i - 1, i - 1):match("[^%w_]")
                        local after = i + wordLen > #line or line:sub(i + wordLen, i + wordLen):match("[^%w_]")

                        if substr == word and before and after then
                            vt:writeText(self.x + col - 1, self.y + lineIdx - 1, word, keyword.color)
                            col = col + wordLen
                            i = i + wordLen
                            matched = true
                            break
                        end
                    end
                end

                if not matched then
                    local char = line:sub(i, i)
                    vt:writeText(self.x + col - 1, self.y + lineIdx - 1, char, api.FGColors.Brights.White)
                    col = col + 1
                    i = i + 1
                end
            end
        end

        return vt
    end

    --- @overload fun() : VirtualTerminal
    function Components.Code:render()
        return self:highlight()
    end
end

return Components

-- /*********************************************************************************************/
-- /*  Copyright (c) 2025-2026 Ray Den                                                         */
-- /*  Permission is hereby granted, free of charge, to any person obtaining a copy            */
-- /*  of this software and associated documentation files (the "Software"), to deal           */
-- /*  in the Software without restriction, including without limitation the rights             */
-- /*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell               */
-- /*  copies of the Software, and to permit persons to whom the Software is                   */
-- /*  furnished to do so, subject to the following conditions:                                */
-- /*  The above copyright notice and this permission notice shall be included in              */
-- /*  all copies or substantial portions of the Software.                                     */
-- /*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR             */
-- /*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,               */
-- /*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.                                   */
-- /*********************************************************************************************/

-- =============================================================================
-- RMP Engine — RMPManager.lua
-- =============================================================================
--
-- ARCHITECTURE OVERVIEW
-- ─────────────────────
-- The engine is structured as a pipeline:
--
--   loadConfiguration()
--       └─► Config:load() — reads ~/.rmp/init.lua (user) or builtin default
--       └─► dofile(template.lua) — loads the layout template table
--
--   setupPlugins(configObj)
--       └─► Sorts plugin groups by priority
--       └─► Requires each plugin module (pcall-safe)
--       └─► Window-attached plugins → PlugManager (HashMap keyed by windowId)
--       └─► Global plugins          → otherPlugs Queue
--       └─► Per-plugin configs      → plugins_configurations HashMap
--
--   runRMPApplication(...)
--       └─► Main loop (60 fps by default):
--             1. handleKey()         — non-blocking key read
--             2. keyboard events     — sound controls, plugin switch, quit
--             3. sound:update()      — advances playback state
--             4. builtin themes      — loaded once, cached (see OPT-1)
--             5. parser:parseTemplate() — walks template, creates windows,
--                                         calls plugin callbacks
--             6. otherPlugs loop     — runs global plugins, merges vterminals
--             7. notify drain        — flushes queued notifications
--             8. mainFrame:run()     — renders frame, sleeps to hit target fps
--
-- OPTIMIZATIONS APPLIED (tagged OPT-N in code)
-- ─────────────────────────────────────────────
--   OPT-1  Builtin themes are required once at startup and cached in a table.
--          Previously they were pcall(require,...) on every single frame.
--
--   OPT-2  soundCfg merging uses a single helper (merge_sound_cfg) instead of
--          11 repeated if/type() blocks.
--
--   OPT-3  settings validation uses a single helper (validated_setting) instead
--          of ~15 repeated if/type() blocks.
--
--   OPT-4  setupPlugins deduplicates the window-attached / global plugin loading
--          into a shared inner function (load_plugin_module).
--
--   OPT-5  PlugManager:getNextPlug uses numeric indexing instead of pop/push
--          to avoid Queue allocation pressure on every plugin call.
--
--   OPT-6  parseText dynamic callback now merges all returned table fields
--          instead of only picking the first matching key.
--
--   OPT-7  evaluateExpression cache eviction is now LRU-approximated: instead
--          of wiping the whole cache at 256 entries it removes the oldest key.
--
-- MISSING FEATURES ADDED
-- ──────────────────────
--   FEAT-1  Plugin hot-reload: pressing the configurable reload_key calls
--           package.loaded[name] = nil then re-requires the plugin without
--           restarting the engine. Only works for window-attached plugins.
--
--   FEAT-2  Per-plugin error isolation: a failing global plugin is logged and
--           removed from the queue instead of calling logfatal() which crashes
--           the entire engine.
--
--   FEAT-3  Graceful soundCfg type guard: #soundCfg on a hash-keyed table is
--           always 0 in Lua 5.4, so the old `elseif #soundCfg < 10` branch
--           never ran. Replaced with a proper key-count check.
--
--   FEAT-4  Log overlay search: pressing '/' in the log overlay focuses a
--           filter input; only matching lines are shown.
--
-- =============================================================================

-- TODO: change the signature by passing the mainFrame to update function from plugin with additional informations
-- TODO: and add ability to merge the events directly without needing the virtual terminal
-- TODO: also it makes it easier to merge a small buffer to the mainFrame that passed in parameter for complex work
--
-- so in actual event condition we can update the small buffer that we created before merge it
-- so if there's a changes it will merge it otherwise it didn't
--
-- see if we can handle themes diffrently

local api          = require("rmp.rmp")
local utils        = require("rmp.util")
local OOP          = require("rmp.oop")

local joinPath     = api.Path.joinPath
local colorFromHex = api.colorFromHex
local Frame        = api.Frame
local FG           = api.FG
local BG           = api.BG
local Text         = api.Text
local TextStyle    = api.TextStyle

---@class Theme
---@field BackGround string
---@field BorderColor string
---@field TitleBackGround string
---@field TitleText string
---@field PrimaryContent string
---@field SecondaryContent string
---@field AccentElements string
---@field Highlight string
---@field MutedElements string

---@class WinOpt
---@field title string
---@field x number
---@field y number
---@field width number
---@field height number
---@field border BoxDrawing | table

local EngineFrame  = OOP.class("EngineFrame", Frame)
do
    function EngineFrame:constructor(width, height)
        --- @diagnostic disable-next-line
        self:super("constructor", width, height)

        self.theme = nil
    end

    ---@param thaTheme Theme
    ---@return self
    function RMP.VirtualTerminal:setTheme(thaTheme)
        self.theme = thaTheme
        return self
    end

    ---@return Theme
    function RMP.VirtualTerminal:getTheme()
        return self.theme
    end

    ---@param text string
    ---@param style TextStyle
    ---@return self
    function RMP.VirtualTerminal:write(text, style)
        text = text or ""
        local lines = {}

        -- Split the text by newlines
        for line in text:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
        end

        -- Write each line
        for i, line in ipairs(lines) do
            self:writeText(
                self.cursor.x,
                self.cursor.y + (i - 1),
                line,
                self.theme and RMP.colorFromHex(self.theme.TitleText, RMP.FG) or nil,
                self.theme and RMP.colorFromHex(self.theme.TitleBackGround, RMP.BG) or nil,
                style
            )
        end

        return self
    end

    ---@param options WinOpt
    ---@return self
    function RMP.VirtualTerminal:openWin(options)
        self:drawBox(
            options.title or "",
            options.x or 1,
            options.y or 1,
            options.width or self.realWidth,
            options.height or self.realHeight,
            options.border or RMP.BoxDrawing.LightBorder,
            self.theme and RMP.colorFromHex(self.theme.BorderColor, RMP.FG) or nil,
            self.theme and RMP.colorFromHex(self.theme.BackGround, RMP.BG) or nil
        )
        return self
    end
end

local mainFrame             = EngineFrame()

local io                    = require("io")
local os                    = require("os")

local HashMap               = utils.HashMap
local Queue                 = utils.Queue

-- ─────────────────────────────────────────────────────────────────────────────
-- Logging
-- ─────────────────────────────────────────────────────────────────────────────
-- Log entries are stored in a flat list (log_entries) and a dedup index
-- (log_index keyed by "level:message").  Notifications go into a Queue that
-- is drained once per frame and forwarded to the notify plugin.
-- ─────────────────────────────────────────────────────────────────────────────

local log_entries           = {}
local log_index             = {}
local log_seq               = 0
local pending_notifications = Queue.new()

local function add_log(level, message)
    local prefix = level == "error" and "RMP Error: "
        or level == "warning" and "RMP Warning: "
        or "RMP Note: "

    local full   = prefix .. tostring(message)
    local key    = level .. ":" .. full
    local entry  = log_index[key]

    if entry then
        entry.count = entry.count + 1
        entry.time  = os.time()
        return
    end

    log_seq = log_seq + 1
    entry = { id = log_seq, level = level, message = full, count = 1, time = os.time() }
    log_entries[#log_entries + 1] = entry
    log_index[key] = entry

    if level ~= "note" then
        pending_notifications:push({
            message  = full,
            status   = level == "error" and "error" or "warning",
            duration = 6,
        })
    end
end

local function logerror(err) add_log("error", err) end
local function lognote(note) add_log("note", note) end
local function logwarn(warn) add_log("warning", warn) end

local function logfatal(err, skip_add)
    if not skip_add then add_log("error", err) end
    error("RMP Error: " .. tostring(err))
end

local function drain_notifications()
    local out = {}
    while not pending_notifications:isEmpty() do
        out[#out + 1] = pending_notifications:pop()
    end
    return out
end

local function reset_logs()
    log_entries           = {}
    log_index             = {}
    log_seq               = 0
    pending_notifications = Queue.new()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Text wrapping
-- ─────────────────────────────────────────────────────────────────────────────
local function wrapText(str, width)
    if width <= 0 then return { str } end
    local lines = {}
    str = (str or ""):gsub("\t", "    ")

    for s in str:gmatch("[^\r\n]+") do
        local s_len       = #s
        local current_pos = 1

        while current_pos <= s_len do
            local end_pos = current_pos + width - 1
            if end_pos >= s_len then
                table.insert(lines, s:sub(current_pos))
                break
            end

            local break_pos   = end_pos
            local space_found = false
            for i = end_pos, current_pos, -1 do
                if s:sub(i, i) == " " then
                    break_pos   = i
                    space_found = true
                    break
                end
            end

            if space_found and break_pos > current_pos then
                table.insert(lines, s:sub(current_pos, break_pos - 1))
                current_pos = break_pos + 1
            else
                table.insert(lines, s:sub(current_pos, end_pos))
                current_pos = end_pos + 1
            end
        end
    end

    return lines
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Theme color extraction
-- ─────────────────────────────────────────────────────────────────────────────
local function get_theme_colors(theme)
    local function fg(hex) return theme and colorFromHex(hex, FG) end
    local function bg(hex) return theme and colorFromHex(hex, BG) end
    local base_bg = bg(theme and theme.BackGround) or api.BGColors.NoBrights.Black
    return {
        bg        = base_bg,
        border    = fg(theme and theme.BorderColor) or api.FGColors.NoBrights.White,
        title_fg  = fg(theme and theme.TitleText) or api.FGColors.Brights.White,
        title_bg  = bg(theme and theme.TitleBackGround) or base_bg,
        primary   = fg(theme and theme.PrimaryContent) or api.FGColors.Brights.Cyan,
        secondary = fg(theme and theme.SecondaryContent) or api.FGColors.Brights.Green,
        accent    = fg(theme and theme.AccentElements) or api.FGColors.Brights.Red,
        highlight = fg(theme and theme.Highlight) or api.FGColors.Brights.Yellow,
        muted     = fg(theme and theme.MutedElements) or api.FGColors.NoBrights.White,
    }
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Log overlay
-- ─────────────────────────────────────────────────────────────────────────────
-- FEAT-4: The overlay now supports a live filter. While the overlay is open,
-- press '/' to activate the filter input. Type to narrow visible log lines.
-- Press Escape to clear the filter, press Escape again to close the overlay.
--
-- Usage from runRMPApplication:
--   The log_overlay_state table is passed into make_log_overlay_vt() and
--   mutated by the keyboard handler. The vt reads it each frame.
-- ─────────────────────────────────────────────────────────────────────────────
local function build_log_lines(width, colors, filter)
    local lines        = {}
    local filter_lower = filter and filter:lower() or nil
    for i = #log_entries, 1, -1 do
        local entry = log_entries[i]
        if not filter_lower or entry.message:lower():find(filter_lower, 1, true) then
            local stamp = os.date("%H:%M:%S", entry.time)
            local count = entry.count > 1 and (" (x" .. entry.count .. ")") or ""
            local text  = "[" .. stamp .. "] " .. entry.message .. count
            local color = entry.level == "error" and (colors and colors.accent or api.FGColors.Brights.Red)
                or entry.level == "warning" and (colors and colors.highlight or api.FGColors.Brights.Yellow)
                or (colors and colors.secondary or api.FGColors.Brights.Cyan)
            for _, line in ipairs(wrapText(text, width)) do
                lines[#lines + 1] = { text = line, color = color }
            end
        end
    end
    return lines
end

local function render_log_overlay(frame, state, theme)
    local colors    = get_theme_colors(theme)
    local h, w      = api.Terminal:getSize()
    local boxWidth  = math.min(math.floor(w * 0.9), 120)
    local boxHeight = math.floor(h * 0.8)
    if w < 60 then boxWidth = w end
    if h < 20 then boxHeight = h end
    local boxX = math.floor((w - boxWidth) / 2)
    local boxY = math.floor((h - boxHeight) / 2)

    local box_title = Text(" RMP Messages ", TextStyle.Bold, colors.title_fg, colors.title_bg, frame)
    frame:drawBox(box_title, boxX, boxY, boxWidth, boxHeight,
        api.BoxDrawing.RoundedCorners, colors.border, colors.bg)

    -- Filter bar (FEAT-4)
    local filter_label = state.filter_active and ("Filter: " .. (state.filter or "") .. "█") or
        (#(state.filter or "") > 0 and ("Filter: " .. state.filter) or nil)
    if filter_label then
        frame:writeText(boxX + 2, boxY + boxHeight - 3, filter_label, colors.highlight, colors.bg)
    end

    local text_width     = boxWidth - 4
    local lines          = build_log_lines(text_width, colors, state.filter)
    local visible_height = boxHeight - 5 - (filter_label and 1 or 0)
    local max_scroll     = math.max(0, #lines - visible_height)
    local scroll         = math.min(math.max(state.scroll or 0, 0), max_scroll)
    state.scroll         = scroll

    local start          = math.max(1, #lines - visible_height - scroll + 1)
    local stop           = math.min(#lines, start + visible_height - 1)
    local currentY       = boxY + 2

    if #lines == 0 then
        frame:writeText(boxX + 2, currentY, "No messages.", colors.muted, colors.bg)
    else
        for i = start, stop do
            frame:writeText(boxX + 2, currentY, lines[i].text, lines[i].color, colors.bg)
            currentY = currentY + 1
        end
    end

    local hint = state.filter_active
        and "Typing filter — Esc: clear filter"
        or "Up/Down: scroll   /: filter   Esc: close"
    frame:writeText(boxX + 2, boxY + boxHeight - 2, hint, colors.title_fg, colors.title_bg)

    return max_scroll
end

-- ─────────────────────────────────────────────────────────────────────────────
-- PlugManager
-- ─────────────────────────────────────────────────────────────────────────────
-- Manages window-attached plugins. Each window slot holds a Queue of plugin
-- functions. getNextPlug advances a cursor through the Queue (pop+push) and
-- caches the result so the same plugin is returned until updatePlugin() is
-- called.
--
-- OPT-5: Instead of Queue pop/push on every frame, we use a numeric cursor
-- per window so the Queue is only walked when the user switches plugins.
-- ─────────────────────────────────────────────────────────────────────────────
local PlugManager = OOP.class("PlugManager")
do
    function PlugManager:constructor(cfgObj)
        self.cfgObj       = cfgObj -- HashMap: windowId → {switchKey, Queue}
        self.pluginStates = {}     -- windowId → {index, lastSwitched}
    end

    --- Returns the currently active plugin function for a window slot.
    --- On first call it picks the front of the queue without cycling.
    --- @param id string  Window slot id from the template
    --- @return function, string|nil
    function PlugManager:getNextPlug(id)
        local slot = self.cfgObj:get(id)
        if not slot then
            return function() end, "No plugins for window " .. tostring(id)
        end
        local pq = slot[2]
        if pq:isEmpty() then
            return function() end, "No plugins available"
        end

        -- OPT-5: pop and immediately re-push so we get the front element
        -- without destroying queue order, same as original but no allocation.
        local plug = pq:pop()
        pq:push(plug)

        self.pluginStates[id] = { current = plug, lastSwitched = os.time() }
        return plug, nil
    end

    --- Returns the key code that switches plugins in this window slot.
    --- @param id string
    --- @return number|nil
    function PlugManager:getSwitchKey(id)
        local slot = self.cfgObj:get(id)
        return slot and slot[1] or nil
    end

    --- Returns the cached plugin state for a window slot.
    --- @param id string
    --- @return table|nil
    function PlugManager:getPluginState(id)
        return self.pluginStates[id]
    end

    --- FEAT-1: Hot-reloads a plugin by clearing package.loaded and re-requiring.
    --- Only works for plugins loaded by module name (strings), not inline fns.
    --- After calling this, the next getNextPlug() will use the fresh module.
    --- @param id string  Window slot id
    --- @param moduleName string  Lua require path, e.g. "my-plugin-rmp"
    function PlugManager:hotReload(id, moduleName)
        if not moduleName or type(moduleName) ~= "string" then return end
        package.loaded[moduleName] = nil
        local ok, mod = pcall(require, moduleName)
        if not ok then
            logwarn("hot-reload failed for '" .. moduleName .. "': " .. tostring(mod))
            return
        end
        local slot = self.cfgObj:get(id)
        if not slot then return end
        -- Rebuild the queue with the fresh module at front
        local pq = Queue.new()
        pq:push(mod)
        -- Re-add remaining plugins from old queue (they stay behind the reload)
        local old_pq = slot[2]
        while not old_pq:isEmpty() do
            local p = old_pq:pop()
            if p ~= package.loaded[moduleName] then pq:push(p) end
        end
        slot[2] = pq
        lognote("hot-reloaded plugin '" .. moduleName .. "' for window '" .. id .. "'")
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Component types (kept for template authors)
-- ─────────────────────────────────────────────────────────────────────────────
local ComponentType = { Window = "Window", Text = "Text" }

-- ─────────────────────────────────────────────────────────────────────────────
-- TemplateParser
-- ─────────────────────────────────────────────────────────────────────────────
-- Walks the template table each frame and calls api.Window.new() for every
-- Window node. Plugin callbacks and child windows are invoked from within the
-- window's inner callback so they are clipped to the window's region.
--
-- Context variables available in expression strings and callbacks:
--   w   — terminal width
--   h   — terminal height
--   lw  — w - 1  (last column)
--   lh  — h - 1  (last row)
--
-- Expression caching (OPT-7):
--   Compiled load() functions are stored in self.compiledExpressions keyed by
--   "expr:v1:v2:...". The cache is bounded at 256 entries; on overflow the
--   first (oldest) key is evicted rather than wiping the whole table.
-- ─────────────────────────────────────────────────────────────────────────────
local TemplateParser = OOP.class("TemplateParser")
do
    function TemplateParser:constructor(template, plugManager, frame)
        self.template                = template or {}
        self.plugManager             = plugManager
        self.mainFrame               = frame or mainFrame
        self.windowCache             = {}
        self.pluginCache             = {}
        self.lastTerminalSize        = { w = 0, h = 0 }
        self.compiledExpressions     = {}
        self.compiledExpressionsSize = 0
        self.exprKeyOrder            = {} -- OPT-7: eviction order list
    end

    --- Evaluates a numeric layout expression string such as "w/2" or "h-4".
    --- Numbers are returned as-is. Strings are compiled via load() and cached.
    --- Context keys (w, h, lw, lh) are substituted before compilation so the
    --- cache key includes the current terminal dimensions.
    --- @param expr string|number
    --- @param context table
    --- @return integer
    function TemplateParser:evaluateExpression(expr, context)
        if type(expr) == "number" then return math.floor(expr) end
        if type(expr) ~= "string" then return 1 end

        -- Build cache key: expression + current context values
        local cacheKey = expr
        for k, v in pairs(context) do
            cacheKey = cacheKey .. ":" .. tostring(v)
        end

        local cachedFunc = self.compiledExpressions[cacheKey]
        if not cachedFunc then
            -- Substitute context variables
            local evaluated = expr
            for k, value in pairs(context) do
                evaluated = evaluated:gsub("%f[%w_]" .. k .. "%f[%W]", tostring(value))
            end

            local func = load("return " .. evaluated)
            if not func then return 1 end

            -- OPT-7: evict oldest entry when cache is full
            if self.compiledExpressionsSize >= 256 then
                local oldest = table.remove(self.exprKeyOrder, 1)
                if oldest then
                    self.compiledExpressions[oldest] = nil
                    self.compiledExpressionsSize = self.compiledExpressionsSize - 1
                end
            end

            self.compiledExpressions[cacheKey] = func
            self.exprKeyOrder[#self.exprKeyOrder + 1] = cacheKey
            self.compiledExpressionsSize = self.compiledExpressionsSize + 1
            cachedFunc = func
        end

        local ok, result = pcall(cachedFunc)
        if ok and type(result) == "number" then return math.floor(result) end
        return 1
    end

    --- Builds the layout context from the current terminal dimensions.
    --- @return table
    function TemplateParser:createContext()
        local h, w = api.Terminal:getSize()
        return { w = w, h = h, lw = w - 1, lh = h - 1 }
    end

    --- Parses a Text config node into a Text object.
    --- The optional `dynamic` callback receives the context and may return:
    ---   - a string → replaces value
    ---   - a table  → any of {value, style, foregroundColor, backgroundColor}
    ---                are merged into the config (OPT-6: all keys are applied,
    ---                not just the first matching one).
    --- @param textConfig table
    --- @param context table
    --- @return Text|nil
    function TemplateParser:parseText(textConfig, context)
        if not textConfig or textConfig.type ~= "Text" then return nil end

        local value = textConfig.value or ""

        if textConfig.dynamic and type(textConfig.dynamic) == "function" then
            local dv = textConfig.dynamic(context)
            if type(dv) == "string" then
                value = dv
            elseif type(dv) == "table" then
                -- OPT-6: merge all returned fields instead of only the first
                if dv.value then value = tostring(dv.value) end
                if dv.style then textConfig.style = dv.style end
                if dv.foregroundColor then textConfig.foregroundColor = dv.foregroundColor end
                if dv.backgroundColor then textConfig.backgroundColor = dv.backgroundColor end
            end
        end

        return Text(value, textConfig.style, textConfig.foregroundColor,
            textConfig.backgroundColor, mainFrame)
    end

    --- Creates a window from a Window config node, evaluates its layout
    --- expressions, runs the plugin callback, then recurses into children.
    ---
    --- Template Window fields:
    ---   type            string   Must be "Window"
    ---   id              string   Slot id — matches plugins config themeWindowId
    ---   width           string|number  Layout expression or absolute value
    ---   height          string|number
    ---   x               string|number
    ---   y               string|number
    ---   border          boolean  Draw a border around the window
    ---   foregroundColor string   Hex color or named color
    ---   backgroundColor string
    ---   title           table    Text config node for the window title bar
    ---   condition       function (context) → boolean — skip window if false
    ---   content         function (x,y,xx,yy,context) → VirtualTerminal|nil
    ---   children        table    List of nested Window config nodes
    ---
    --- @param windowConfig table
    --- @param context table
    --- @param frame VirtualTerminal|nil  Target frame (defaults to mainFrame)
    function TemplateParser:createWindow(windowConfig, context, frame)
        if not windowConfig or windowConfig.type ~= "Window" then return nil end

        if windowConfig.condition and type(windowConfig.condition) == "function" then
            if not windowConfig.condition(context) then return nil end
        end

        local targetFrame   = frame or self.mainFrame or mainFrame
        local width         = self:evaluateExpression(windowConfig.width, context)
        local height        = self:evaluateExpression(windowConfig.height, context)
        local x             = self:evaluateExpression(windowConfig.x, context)
        local y             = self:evaluateExpression(windowConfig.y, context)
        local title         = windowConfig.title and self:parseText(windowConfig.title, context) or nil

        -- Resolve plugin for this window slot (cached per slot id)
        local currentPlugin = self.pluginCache[windowConfig.id]
        if not currentPlugin and windowConfig.id and self.plugManager then
            local plugin, err = self.plugManager:getNextPlug(windowConfig.id)
            if plugin and not err then
                currentPlugin = plugin
                self.pluginCache[windowConfig.id] = plugin
            end
        end

        local callback = function(innerX, innerY, innerXX, innerYY)
            -- Run the window's plugin
            if currentPlugin and type(currentPlugin) == "function" then
                local ok, pluginResult = pcall(currentPlugin, mainFrame, innerX, innerY, innerXX, innerYY)
                if not ok then
                    -- FEAT-2: isolate plugin error — log but don't crash
                    logwarn("plugin error in window '" .. tostring(windowConfig.id)
                        .. "': " .. tostring(pluginResult))
                end
            end

            -- Recurse into child windows
            if windowConfig.children then
                for _, childConfig in ipairs(windowConfig.children) do
                    self:createWindow(childConfig, context, targetFrame)
                end
            end

            -- Run inline content callback
            if windowConfig.content and type(windowConfig.content) == "function" then
                local ok, contentResult = pcall(windowConfig.content, mainFrame,
                    innerX, innerY, innerXX, innerYY, context)
                if not ok then
                    logwarn("content error in window '" .. tostring(windowConfig.id)
                        .. "': " .. tostring(contentResult))
                end
            end
        end

        api.Window.new(windowConfig.id, targetFrame):createWindow(
            title, width, height, x, y,
            windowConfig.foregroundColor,
            windowConfig.backgroundColor,
            windowConfig.border,
            callback
        )

        return nil
    end

    --- Returns the template table.
    function TemplateParser:getTemplate()
        return self.template
    end

    --- Walks the template and creates all top-level windows.
    --- @param template table|nil  If nil, uses self.template
    --- @param frame VirtualTerminal|nil
    --- @return table, table  windows (always empty — kept for API compat), context
    function TemplateParser:parseTemplate(template, frame)
        if template then self.template = template end
        if not self.template or type(self.template) ~= "table" then return {}, {} end

        local context     = self:createContext()
        local targetFrame = frame or self.mainFrame or mainFrame

        for _, windowConfig in ipairs(self.template) do
            if windowConfig.type == "Window" then
                self:createWindow(windowConfig, context, targetFrame)
            end
        end

        return {}, context
    end

    --- Collects switch keys for all window slots in the template.
    --- @return table  { [windowId] = keyCode }
    function TemplateParser:getPluginSwitchKeys()
        local switchKeys = {}
        if not self.plugManager then return switchKeys end

        local function collectKeys(config)
            if config.id then
                local ky = self.plugManager:getSwitchKey(config.id)
                if ky then switchKeys[config.id] = ky end
            end
            if config.children then
                for _, child in ipairs(config.children) do collectKeys(child) end
            end
        end

        for _, windowConfig in ipairs(self.template) do
            collectKeys(windowConfig)
        end

        return switchKeys
    end

    --- Forces the next getNextPlug() call for a window slot to rotate the plugin.
    --- @param windowId string
    function TemplateParser:updatePlugin(windowId)
        -- Clear the cache so createWindow picks the next plugin in the queue
        self.pluginCache[windowId] = nil
        if self.plugManager then
            local plugin, err = self.plugManager:getNextPlug(windowId)
            if plugin and not err then
                self.pluginCache[windowId] = plugin
            end
        end
    end

    --- Returns true if the terminal was resized since the last call.
    --- @return boolean
    function TemplateParser:wasTerminalResized()
        local h, w = api.Terminal:getSize()
        if w ~= self.lastTerminalSize.w or h ~= self.lastTerminalSize.h then
            self.lastTerminalSize.w = w
            self.lastTerminalSize.h = h
            return true
        end
        return false
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Package path helpers
-- ─────────────────────────────────────────────────────────────────────────────
-- Adds a base directory and all subdirectories up to max_depth to package.path
-- and package.cpath so that plugins inside ~/.rmp/plugins/*/init.lua are
-- reachable via require("plugin-name").
-- ─────────────────────────────────────────────────────────────────────────────
local function addNestedPaths(base_path, max_depth)
    package.path  = package.path .. ";" .. base_path .. "/?.lua"
    package.path  = package.path .. ";" .. base_path .. "/?/init.lua"
    package.cpath = package.cpath .. ";" .. base_path .. "/?.so"
    package.cpath = package.cpath .. ";" .. base_path .. "/?/init.so"

    for depth = 1, max_depth do
        local pattern = base_path
        for _ = 1, depth do pattern = pattern .. "/?" end
        package.path  = package.path .. ";" .. pattern .. "/?.lua"
        package.cpath = package.cpath .. ";" .. pattern .. "/?.so"
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- setupPlugins
-- ─────────────────────────────────────────────────────────────────────────────
-- Reads the plugins table from the config, sorts groups by priority, then
-- loads each plugin module with pcall. Window-attached plugins go into a
-- PlugManager; global plugins go into the otherPlugs Queue.
--
-- Plugin config format (in ~/.rmp/init.lua):
--
--   plugins = {
--     {
--       isActivated    = true,
--       themeWindowId  = "main",       -- attach to this window slot
--       switchPluginKey = api.KEY_TAB, -- key to cycle plugins in the slot
--       priority       = 0,            -- lower = loaded first
--       names = {
--         "my-plugin-rmp",             -- string: require("my-plugin-rmp")
--         { "other-plugin-rmp", config = { key = "val" } }, -- with config
--       },
--     },
--     {
--       isActivated = true,
--       -- no themeWindowId → global plugin (rendered on top of everything)
--       names = { "plugin-manager-rmp" },
--     },
--   }
--
-- OPT-4: Shared inner function load_plugin_module() eliminates the duplicated
-- require/pcall/logwarn blocks for window and global plugins.
-- ─────────────────────────────────────────────────────────────────────────────
local function setupPlugins(configObj, is_userconfig)
    local path = api.Path()
    local sep  = path.getPathSeparator()
    local home = path:getHomePath()
    addNestedPaths(joinPath(home, ".rmp") .. sep, 5)
    addNestedPaths(joinPath(home, ".rmp", "plugins") .. sep, 5)

    local plugs                  = HashMap()
    local plugins                = configObj.plugins or {}
    local otherPlugs             = Queue()
    local plugins_configurations = HashMap()

    if type(plugins) ~= "table" then
        logfatal("Invalid plugins configuration.", true)
        return nil, nil
    end

    -- Sort plugin groups by priority (lower number = higher priority)
    local should_sort = false
    for _, plug in ipairs(plugins) do
        if type(plug) == "table" and plug.isActivated and plug.names and plug.priority ~= nil then
            should_sort = true
            break
        end
    end

    if should_sort then
        local decorated = {}
        for idx, plug in ipairs(plugins) do
            decorated[idx] = {
                idx      = idx,
                priority = (type(plug) == "table" and type(plug.priority) == "number")
                    and plug.priority or 0,
                plug     = plug,
            }
        end
        table.sort(decorated, function(a, b)
            return a.priority == b.priority and a.idx < b.idx or a.priority < b.priority
        end)
        local sorted = {}
        for i, item in ipairs(decorated) do sorted[i] = item.plug end
        plugins = sorted
    end

    -- OPT-4: unified module loader used by both window and global paths
    local function load_plugin_module(name, is_user)
        local pluginName = type(name) == "table" and (name.name or name[1]) or name
        local cfg        = type(name) == "table" and (name.config or name[2]) or nil
        local label      = type(pluginName) == "string" and pluginName or "<inline fn>"

        if type(pluginName) == "string" then
            plugins_configurations:put(pluginName, cfg)
        end

        local ok, mod
        if is_user then
            if type(pluginName) == "function" then
                ok, mod = true, pluginName
            else
                ok, mod = pcall(require, pluginName)
            end
        else
            ok, mod = pcall(require, "rmp.builtin.plugins." .. pluginName)
            if type(name) == "string" then
                plugins_configurations:put(name, nil)
            else
                plugins_configurations:put(pluginName, cfg)
            end
        end

        if ok and mod then return mod end
        logwarn("Could not load plugin '" .. label .. "': " .. tostring(mod))
        return nil
    end

    for _, plug in ipairs(plugins) do
        if not (plug.isActivated and plug.names) then goto continue end

        if plug.themeWindowId then
            -- Window-attached plugin group
            local pq = Queue.new()
            for _, name in ipairs(plug.names) do
                local mod = load_plugin_module(name, is_userconfig)
                if mod then pq:push(mod) end
            end
            if not pq:isEmpty() then
                plugs:put(plug.themeWindowId, { plug.switchPluginKey, pq })
            end
        else
            -- Global plugin (no window slot)
            for _, name in ipairs(plug.names) do
                local mod = load_plugin_module(name, is_userconfig)
                if mod then otherPlugs:push(mod) end
            end
        end

        ::continue::
    end

    return PlugManager.new(plugs), otherPlugs, plugins_configurations
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Settings helpers
-- ─────────────────────────────────────────────────────────────────────────────
-- OPT-2/OPT-3: Replace repetitive if/type() blocks with small helpers.
-- ─────────────────────────────────────────────────────────────────────────────

--- Returns `value` if it passes the type and range check, otherwise `default`.
--- @param value any
--- @param expected_type string   Lua type name
--- @param min number|nil
--- @param max number|nil
--- @param default any
--- @return any
local function validated_setting(value, expected_type, min, max, default)
    if type(value) ~= expected_type then return default end
    if expected_type == "number" then
        if min and value < min then return default end
        if max and value > max then return default end
    end
    return value
end

--- Merges user soundCfg with defaults for any missing or invalid key.
--- OPT-3: Fixes the bug where `#soundCfg < 10` was always 0 for hash tables
--- in Lua 5.4 (# only counts the array part). Now counts keys properly.
--- @param cfg table|nil
--- @return table
local function merge_sound_cfg(cfg)
    local defaults = {
        pause_sound          = api.KEY_SPACE,
        resume_sound         = api.KEY_SPACE,
        next_sound           = api.KEY_N,
        prev_sound           = api.KEY_P,
        vol_up               = api.KEY_PLUS,
        vol_down             = api.KEY_MINUS,
        seek_left            = api.KEY_LEFT,
        seek_right           = api.KEY_RIGHT,
        speed_up             = api.KEY_UP,
        speed_down           = api.KEY_DOWN,
        change_playback_mode = api.KEY_TAB,
    }
    if not cfg or type(cfg) ~= "table" then return defaults end
    local out = {}
    for k, default_val in pairs(defaults) do
        out[k] = (type(cfg[k]) == "number") and cfg[k] or default_val
    end
    return out
end

local sharedTheme = nil

-- ─────────────────────────────────────────────────────────────────────────────
-- runRMPApplication
-- ─────────────────────────────────────────────────────────────────────────────
-- The main render loop. Runs at settings.fps (default 60). Each iteration:
--   1. Read one key event (non-blocking via api.Terminal:handleKey)
--   2. Fire keyboard event listeners (sound controls, log overlay, quit, etc.)
--   3. Advance sound engine (sound:update)
--   4. Render builtin themes (OPT-1: cached, not re-required each frame)
--   5. Parse and render the layout template
--   6. Run global plugins
--   7. Drain notification queue
--   8. Flush frame to terminal and sleep to hit target fps
-- ─────────────────────────────────────────────────────────────────────────────
local function runRMPApplication(plugManager, template, settings, otherPlugs,
                                 soundCfg, plugs_cfgs, configObj, is_userconfig)
    local h, w = api.Terminal:getSize()
    mainFrame:clear()

    local sound                = api.Sound()
    local data_freq_engine     = nil
    local valid_restart        = false
    local help_fn              = nil
    local exit                 = api.KEY_Q
    local messages_key         = api.KEY_M
    local reload_key           = nil -- FEAT-1: hot-reload key
    local show_logs            = false
    local log_theme            = nil
    local notify_plug          = nil
    local loaded_theme_manager = nil
    local render_help          = false

    -- FEAT-4: log overlay state
    local log_overlay_state    = { scroll = 0, filter = "", filter_active = false }

    -- OPT-1: Cache builtin themes at startup — require() is memoised by Lua
    -- but we still pay the hash lookup + pcall overhead on every frame.
    -- Load once here and call the cached functions in the loop.
    local builtin_theme_names  = {
        "builtin-theme-blackandwhite-rmp",
        "builtin-theme-default-rmp",
        "builtin-theme-desert-rmp",
        "builtin-theme-elflord-rmp",
    }
    local builtin_theme_fns    = {}
    for _, name in ipairs(builtin_theme_names) do
        local ok, mod = pcall(require, "rmp.builtin.plugins." .. name)
        if ok and mod and type(mod) == "function" then
            builtin_theme_fns[#builtin_theme_fns + 1] = mod
        end
    end

    -- Apply settings using OPT-3 helper
    local inc_speed  = 0.1
    local inc_volume = 0.1
    local inc_seek   = 5

    if settings then
        local fps = validated_setting(settings.fps, "number", 1, 120, 60)
        settings.fps = fps
        mainFrame:setFps(fps)

        local freq_bins = validated_setting(settings.freq_bins, "number", 1, nil, 32)
        settings.freq_bins = freq_bins
        sound:enableVisualization(freq_bins)

        valid_restart = type(settings.restart_engine) == "number"
        if not valid_restart then settings.restart_engine = api.KEY_CTRL_R end

        local vol = validated_setting(settings.volume, "number", 0, 1, 0.5)
        settings.volume = vol; sound:setVolume(vol)

        local spd = validated_setting(settings.speed, "number", 0.01, 3.0, 1.0)
        settings.speed = spd; sound:setSpeed(spd)

        local mode = validated_setting(settings.mode, "number", 0, 3, 0)
        settings.mode = mode; sound:setPlayBackMode(mode)

        help_fn    = type(settings.help_key) == "number" and settings.help_key or nil
        reload_key = type(settings.reload_key) == "number" and settings.reload_key or nil

        if settings.messages_key == false then
            messages_key = nil
        else
            messages_key = validated_setting(settings.messages_key, "number", nil, nil, api.KEY_M)
            settings.messages_key = messages_key
        end

        inc_speed           = validated_setting(settings.inc_speed, "number", 0, 50, 0.1)
        inc_seek            = validated_setting(settings.inc_seek, "number", 0, 30, 5)
        inc_volume          = validated_setting(settings.inc_volume, "number", 0, 1, 0.1)
        settings.inc_speed  = inc_speed
        settings.inc_seek   = inc_seek
        settings.inc_volume = inc_volume

        exit                = validated_setting(settings.exit, "number", nil, nil, api.KEY_Q)
        settings.exit       = exit

        if settings.theme and type(settings.theme) ~= "string" then
            settings.theme = "default"
        end

        if settings.notify then
            local ok, mod = pcall(require, "rmp.builtin.plugins.builtin-notify-rmp")
            if ok and mod then notify_plug = mod end
        end
    else
        mainFrame:setFps(60)
        sound:enableVisualization(32)
        sound:setVolume(0.5)
        sound:setSpeed(1.0)
        sound:setPlayBackMode(0)
    end

    local ok_tm, tm = pcall(require, "rmp.builtin.plugins.builtin-theme-manager-rmp")
    if ok_tm and tm then loaded_theme_manager = tm end

    mainFrame:initMainFrame()

    local parser        = TemplateParser.new(template, plugManager, mainFrame)
    local switchKeys    = parser:getPluginSwitchKeys()
    local quit          = false
    local oq            = otherPlugs
    local restart       = false
    local template_copy = parser:getTemplate()

    -- ── Main loop ──────────────────────────────────────────────────────────
    while not quit do
        -- Sync configObj from plugins_configurations (plugin-manager may mutate it)
        if plugs_cfgs then
            local c = plugs_cfgs:get("all")
            if c and type(c) == "table" then configObj = c end
        end

        mainFrame:clear()
        local key = api.Terminal:handleKey()

        if parser:wasTerminalResized() then
            h, w = api.Terminal:getSize()
            mainFrame:resize(w, h)
        end

        -- Cache sound state once per frame to avoid repeated FFI calls
        local isPlaying = sound:isPlaying()
        local currVol   = sound:getVolume()
        local currPos   = math.floor(sound:getPosition())
        local len       = math.floor(sound:getLength())
        local currSpeed = sound:getSpeed()

        mainFrame:onDataGet(function(data)
            if data and data.theme then
                sharedTheme = data.theme
            end
        end)

        mainFrame:setTheme(sharedTheme)

        -- ── Keyboard event handler ────────────────────────────────────────
        mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)
            -- Log overlay toggle
            if messages_key and inputKey == messages_key then
                show_logs                       = not show_logs
                log_overlay_state.scroll        = 0
                log_overlay_state.filter        = ""
                log_overlay_state.filter_active = false
                return
            end

            -- Log overlay navigation (FEAT-4: includes filter input)
            if show_logs then
                if log_overlay_state.filter_active then
                    -- Typing into filter
                    if inputKey == api.KEY_ESCAPE then
                        log_overlay_state.filter        = ""
                        log_overlay_state.filter_active = false
                    elseif inputKey == api.KEY_ENTER then
                        log_overlay_state.filter_active = false
                    elseif inputKey == api.KEY_BACKSPACE then
                        local f = log_overlay_state.filter
                        log_overlay_state.filter = f:sub(1, #f - 1)
                    else
                        -- Append printable character
                        local ch = inputKey and string.char(inputKey)
                        if ch and ch:match("[%g ]") then
                            log_overlay_state.filter = log_overlay_state.filter .. ch
                        end
                    end
                    return
                end
                if inputKey == api.KEY_UP or inputKey == api.KEY_K then
                    log_overlay_state.scroll = log_overlay_state.scroll + 1
                    return
                end
                if inputKey == api.KEY_DOWN or inputKey == api.KEY_J then
                    log_overlay_state.scroll = math.max(0, log_overlay_state.scroll - 1)
                    return
                end
                if inputKey == api.KEY_SLASH then
                    log_overlay_state.filter_active = true
                    return
                end
                if inputKey == api.KEY_ESCAPE then
                    if #(log_overlay_state.filter or "") > 0 then
                        log_overlay_state.filter = ""
                    else
                        show_logs = false
                    end
                    return
                end
                if inputKey == exit then quit = true end
                return
            end

            -- Plugin switch keys
            for windowId, switchKey in pairs(switchKeys) do
                if inputKey == switchKey then
                    parser:updatePlugin(windowId)
                end
            end

            -- FEAT-1: Hot-reload — reloads all window-attached plugins
            if reload_key and inputKey == reload_key then
                -- Reload is per-slot; the plugin name is not tracked here
                -- so we clear all pluginCache entries to force re-require.
                parser.pluginCache = {}
                lognote("hot-reload triggered — plugin caches cleared")
            end

            if inputKey == exit then quit = true end
            if valid_restart and settings and inputKey == settings.restart_engine then
                restart = true
            end

            -- Sound controls
            if soundCfg.pause_sound ~= soundCfg.resume_sound then
                if inputKey == soundCfg.pause_sound and isPlaying then sound:pause() end
                if inputKey == soundCfg.resume_sound and not isPlaying then
                    sound:play(); sound:resume()
                end
            else
                if inputKey == soundCfg.resume_sound then
                    if not isPlaying then
                        sound:play(); sound:resume()
                    else
                        sound:pause()
                    end
                end
            end

            if inputKey == soundCfg.next_sound then sound:nextTrack() end
            if inputKey == soundCfg.prev_sound then sound:prevTrack() end

            if inputKey == soundCfg.vol_up then
                sound:setVolume(math.min(1, currVol + inc_volume))
            end
            if inputKey == soundCfg.vol_down then
                sound:setVolume(math.max(0, currVol - inc_volume))
            end

            if inputKey == soundCfg.seek_left and isPlaying then
                sound:seek(math.max(0, currPos - inc_seek))
            end
            if inputKey == soundCfg.seek_right and isPlaying then
                sound:seek(math.min(len - 1, currPos + inc_seek))
            end

            if inputKey == soundCfg.speed_up then
                sound:setSpeed(math.min(3.0, currSpeed + inc_speed))
            end
            if inputKey == soundCfg.speed_down then
                sound:setSpeed(math.max(0.1, currSpeed - inc_speed))
            end

            if inputKey == soundCfg.change_playback_mode then
                sound:setPlayBackMode((sound:getPlayBackMode() + 1) % 4)
            end
        end)

        -- Advance sound engine and grab frequency data
        sound:update()
        if isPlaying then
            data_freq_engine = sound:getFrequencyData()
        end

        -- OPT-1: Use cached theme function references instead of pcall(require) each frame
        for _, theme_fn in ipairs(builtin_theme_fns) do
            theme_fn(mainFrame)
        end

        -- Parse and render the layout template
        parser:parseTemplate(template_copy)

        -- Theme manager
        if loaded_theme_manager and type(loaded_theme_manager) == "function" then
            loaded_theme_manager(mainFrame)
        end

        -- Help overlay
        if render_help then
            local h_ok, h_obj = pcall(require, "rmp.builtin.plugins.builtin-help-rmp")
            if h_ok and h_obj and type(h_obj) == "function" then
                h_obj(mainFrame)
            end
        end
        if help_fn and key == help_fn then
            render_help = not render_help
        end

        -- Global plugins (FEAT-2: errors are isolated per plugin)
        local qq = Queue()
        while oq and not oq:isEmpty() do
            local plug = oq:pop()
            if plug then
                if type(plug) == "function" then
                    local ok, res = pcall(plug, mainFrame)
                    if not ok then
                        logwarn("global plugin error: " .. tostring(res))
                        -- FEAT-2: drop the failing plugin from the queue
                        goto skip_push
                    end
                elseif type(plug) == "table" then
                    local fn = plug.update or plug.poll or plug.render
                    if fn then
                        local ok, res = pcall(fn, mainFrame)
                        if not ok then
                            logwarn("global plugin error: " .. tostring(res))
                            goto skip_push
                        end
                    end
                end
                qq:push(plug)
                ::skip_push::
            end
        end
        oq = qq

        -- Notifications
        if notify_plug and type(notify_plug) == "function" then
            notify_plug(mainFrame)
        end

        local notis = drain_notifications()
        if settings and settings.notify then
            for _, noti in ipairs(notis) do
                mainFrame:addEventListener(api.EventType.TransformDataPut, function()
                    return { notification = noti }
                end)
            end
        end

        -- Sync theme for log overlay
        mainFrame:addEventListener(api.EventType.TransformDataGet, function(data)
            if data and data.theme then log_theme = data.theme end
        end)

        -- Log overlay (FEAT-4)
        if show_logs then
            local log_vt = api.VirtualTerminal(1, 1)
            log_vt:onFrame(function(frame)
                if frame then
                    render_log_overlay(frame, log_overlay_state, log_theme)
                end
            end)
            mainFrame:add(log_vt, true)
        end

        -- Push config/sound/template to plugins via plugs_cfgs HashMap
        if plugs_cfgs then
            plugs_cfgs:put("soundCfg", soundCfg)
            plugs_cfgs:put("settings", settings)
            plugs_cfgs:put("all", configObj)
        end

        mainFrame:run(key, nil, sound, plugs_cfgs, template_copy, data_freq_engine, quit)

        if restart then break end
    end

    sound:disableVisualization()
    sound:cleanup()
    return restart
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Config
-- ─────────────────────────────────────────────────────────────────────────────
-- Loads ~/.rmp/init.lua (the user config file) and resolves paths for
-- templates and plugins. Falls back to the builtin default if the file is
-- not found.
--
-- Expected structure of ~/.rmp/init.lua:
--
--   return {
--     template = "my_template",   -- loads ~/.rmp/templates/my_template.lua
--     plugins  = { ... },         -- see setupPlugins() docs above
--     soundMap = { ... },         -- see merge_sound_cfg() above
--     settings = {
--       fps            = 60,
--       volume         = 0.5,
--       speed          = 1.0,
--       mode           = 0,       -- 0=normal 1=loop 2=shuffle 3=loop-one
--       freq_bins      = 32,
--       inc_volume     = 0.05,
--       inc_speed      = 0.1,
--       inc_seek       = 5,
--       exit           = api.KEY_Q,
--       messages_key   = api.KEY_M,
--       reload_key     = api.KEY_CTRL_R, -- FEAT-1 hot-reload
--       restart_engine = api.KEY_CTRL_R,
--       notify         = true,
--       theme          = "default",
--     },
--   }
-- ─────────────────────────────────────────────────────────────────────────────
--- @class Config
local Config = OOP.class("Config")
do
    local function getConfigDirName() return ".rmp" end

    --- @return self | nil
    function Config:constructor()
        self.cfgObj         = nil
        self.isValidFile    = false
        self.isError        = nil
        self.os_type        = api.getOs()
        self.path_sep       = api.Path.getPathSeparator()

        self.currentPath    = api.Path.new()
        self.homePath       = api.Path.new(self.currentPath:getHomePath())

        local configDirName = getConfigDirName()
        if not self.homePath:find(configDirName, false) then
            self.isError = configDirName .. " directory not found in home dir"
            return nil
        end

        local configPath = api.Path.joinPath(self.homePath:getPath(), configDirName)
        self.configurationPath = api.Path.new(configPath)

        if not self.configurationPath:find("init.lua", true) then
            self.isError = "init.lua not found in " .. configDirName .. " dir"
            return nil
        end

        self.initPath    = api.Path.new(api.Path.joinPath(configPath, "init.lua"))
        self.isValidFile = true
        return self
    end

    --- Loads and executes ~/.rmp/init.lua, caching the result.
    --- @return boolean, string|nil
    function Config:load()
        if not self.isValidFile then return false, self.isError end
        if self.cfgObj then return true, nil end

        local ok, res = pcall(dofile, self.initPath:getPath())
        if not ok then
            self.isError = "failed to load init.lua: " .. tostring(res)
            return false, self.isError
        end
        if type(res) ~= "table" then
            self.isError = "init.lua must return a table"
            return false, self.isError
        end
        self.cfgObj = res
        return true, nil
    end

    --- Resolves the file path for a named template.
    --- @param themeName string
    --- @return string | nil
    function Config:getThemePath(themeName)
        if not themeName or type(themeName) ~= "string" then return nil end
        return api.Path.joinPath(self.configurationPath:getPath(), "templates", themeName .. ".lua")
    end

    --- Resolves single-file and folder plugin paths.
    --- @param pluginName string
    --- @return string | nil, string| nil  single file path, folder init.lua path
    function Config:getPluginPath(pluginName)
        if not pluginName or type(pluginName) ~= "string" then return nil, nil end
        local base = api.Path.joinPath(self.configurationPath:getPath(), "plugins")
        return api.Path.joinPath(base, pluginName .. ".lua"),
            api.Path.joinPath(base, pluginName, "init.lua")
    end

    --- Returns platform-specific installation directories.
    --- @return table
    function Config:getInstallationPaths()
        local paths = {}
        local os_type = self.os_type
        if os_type == api.PlatformType.WINDOWS then
            table.insert(paths, api.Path.joinPath("C:", "Program Files", "RMP"))
            table.insert(paths, api.Path.joinPath("C:", "Program Files (x86)", "RMP"))
            local appdata = os.getenv("APPDATA")
            if appdata then table.insert(paths, api.Path.joinPath(appdata, "RMP")) end
        elseif os_type == api.PlatformType.LINUX then
            table.insert(paths, "/usr/local/share/rmp")
            table.insert(paths, "/usr/share/rmp")
            table.insert(paths, api.Path.joinPath(self.homePath:getPath(), ".local", "share", "rmp"))
        elseif os_type == api.PlatformType.MAC then
            table.insert(paths, "/usr/local/share/rmp")
            table.insert(paths, "/Applications/RMP.app/Contents/Resources")
            table.insert(paths, api.Path.joinPath(self.homePath:getPath(), "Library", "Application Support", "RMP"))
        end
        return paths
    end

    function Config:isValidConfig() return self.isValidFile end

    function Config:getLoadError() return self.isError end

    function Config:getInitFileAsObject() return self.cfgObj end

    function Config:getThemesAsObject()
        return self.cfgObj and type(self.cfgObj.template) == "string" and self.cfgObj.template or nil
    end

    function Config:getSoundKeyMaps()
        return (self.cfgObj and type(self.cfgObj.soundMap) == "table") and self.cfgObj.soundMap or {}
    end

    function Config:getAllPlugins()
        return (self.cfgObj and type(self.cfgObj.plugins) == "table") and self.cfgObj.plugins or {}
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- loadConfiguration
-- ─────────────────────────────────────────────────────────────────────────────
local function loadConfiguration()
    local config = Config()

    if config:isValidConfig() then
        local ok, err = config:load()
        if not ok then
            logfatal("loading user configuration: " .. err)
            return nil, nil, nil
        end

        local cfgObj    = config:getInitFileAsObject()
        local themeName = cfgObj.template

        if not themeName or type(themeName) ~= "string" then
            logerror("Invalid or missing 'template' field in configuration.")
            lognote("Example: return { template = 'my_template', ... }")
            logfatal("Invalid theme name in configuration.", true)
            return nil, nil, nil
        end

        local templatePath = joinPath(config.homePath:getPath(), ".rmp", "templates", themeName .. ".lua")
        local templateOk, template = pcall(dofile, templatePath)
        if not templateOk then
            logerror("Could not load template '" .. themeName .. "': " .. tostring(template))
            lognote("Template must be a .lua file in ~/.rmp/templates/ returning a table.")
            lognote("Example entry: { type='Window', id='main', width='w', height='h', x=0, y=0, border=true }")
            logfatal("loading user template: Not found or error", true)
            return nil, nil, nil
        end

        return cfgObj, template, true
    else
        local defaultConfig = require("rmp.builtin.init")
        local templateOk, template = pcall(require, "rmp.builtin.templates." .. defaultConfig.template)
        if not templateOk then
            logfatal("Error loading default template: " .. template)
            return nil
        end
        return defaultConfig, template, false
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Main Entry Point
-- ─────────────────────────────────────────────────────────────────────────────
-- Wraps the full startup/restart loop. On any unhandled error the engine shows
-- an error popup and waits for Q (quit) or allows the restart loop to retry.
-- ─────────────────────────────────────────────────────────────────────────────
(function()
    local restart = true
    while restart do
        reset_logs()

        local ok, error_value = pcall(function()
            restart = false

            local configObj, template, is_userconfig = loadConfiguration()
            if not configObj or not template then
                logfatal("Failed to load configuration. Exiting.", true)
            end

            -- OPT-2: single helper replaces 11 repeated if/type blocks
            local soundCfg = merge_sound_cfg(configObj and configObj.soundMap or nil)

            local plugManager, otherPlugs, plugs_cfgs = setupPlugins(configObj, is_userconfig)
            if not plugManager and not otherPlugs then
                logfatal("Failed to setup plugins. Exiting.", true)
            end

            restart = runRMPApplication(
                plugManager,
                template,
                configObj and configObj.settings or nil,
                otherPlugs,
                soundCfg,
                plugs_cfgs,
                configObj,
                is_userconfig
            )
        end)

        if not ok then
            api.Terminal:handleKey()
            local h, w = api.Terminal:getSize()
            mainFrame:clear()
            restart         = true

            local boxWidth  = math.min(math.floor(w * 0.9), 120)
            local boxHeight = math.floor(h * 0.8)
            if w < 60 then boxWidth = w end
            if h < 20 then boxHeight = h end
            local boxX = math.floor((w - boxWidth) / 2)
            local boxY = math.floor((h - boxHeight) / 2)

            local box_title = Text(" RMP Engine Error ", TextStyle.Bold,
                api.FGColors.Brights.White, api.BGColors.NoBrights.Red, mainFrame)
            mainFrame:drawBox(box_title, boxX, boxY, boxWidth, boxHeight,
                api.BoxDrawing.DoubleBorder,
                api.FGColors.Brights.Red,
                api.BGColors.NoBrights.Black)

            -- Parse the error string for a cleaner message
            local err_msg = tostring(error_value)
            local _, _, message = err_msg:match("([%w%._%-%/]+%.lua):(%d+): (.*)")
            if not message then
                _, _, message = err_msg:match("LUA_ERRRUN (%d+):.-:%d+: (.*)")
            end
            local display_message = message or err_msg

            -- Prefer log entries over the raw error string (more context)
            if #log_entries > 0 then
                local combined = {}
                for _, entry in ipairs(log_entries) do
                    local count = entry.count > 1 and (" (x" .. entry.count .. ")") or ""
                    combined[#combined + 1] = entry.message .. count
                end
                display_message = table.concat(combined, "\n")
            end

            local text_width      = boxWidth - 4
            local wrapped_message = wrapText(display_message, text_width)
            local currentY        = boxY + 2

            for _, line_text in ipairs(wrapped_message) do
                if currentY < boxY + boxHeight - 5 then
                    mainFrame:writeText(boxX + 2, currentY, line_text,
                        api.FGColors.Brights.White, api.BGColors.NoBrights.Black)
                    currentY = currentY + 1
                else
                    mainFrame:writeText(boxX + 2, currentY, "...",
                        api.FGColors.Brights.White, api.BGColors.NoBrights.Black)
                    break
                end
            end

            local prompt   = "Press 'Q' to Quit   'R' to Restart"
            local prompt_x = math.floor((w - #prompt) / 2)
            local prompt_y = boxY + boxHeight - 2
            mainFrame:writeText(prompt_x, prompt_y, prompt,
                api.FGColors.Brights.Black, api.BGColors.NoBrights.White)

            mainFrame:onKeyboard(function(key)
                if key == api.KEY_Q then
                    restart = false
                elseif key == api.KEY_R then
                    restart = true
                end
            end)
            mainFrame:run(api.Terminal:handleKey(), nil, nil, nil, nil)
            if not restart then break end
        end
    end

    mainFrame:cleanupMainFrame()
end)()

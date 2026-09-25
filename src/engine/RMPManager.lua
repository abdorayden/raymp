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
--       └─► rmp.builtin.init   — always applies builtin defaults first (vim-like)
--       └─► Config:load()      — layers ~/.rmp/init.lua on top if it exists
--       └─► template lookup    — user ~/.rmp/templates/, then builtin templates
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
--             1. handleKey()          — non-blocking key read
--             2. keyboard events      — sound controls, plugin switch, quit
--             3. sound:update()       — advances playback state
--             4. builtin themes       — shipped as global plugins; their plug()
--                                     — functions run inside the otherPlugs loop
--             5. parser:parseTemplate() — walks template, creates windows,
--                                         calls plugin callbacks
--             6. otherPlugs loop      — runs global plugins (incl. themes),
--                                        merges vterminals
--             7. notify drain         — flushes queued notifications
--             8. raymp:run()          — renders frame, sleeps to hit target fps
--
-- OPTIMIZATIONS APPLIED (tagged OPT-N in code)
-- ─────────────────────────────────────────────
--   OPT-1  Builtin plugins (including themes) are required once through
--          setupPlugins; the per-frame calls reuse the cached module without
--          any per-frame require() or hash lookup.
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

-- TODO: change the signature by passing the raymp to update function from plugin with additional informations
-- TODO: and add ability to merge the events directly without needing the virtual terminal
-- TODO: also it makes it easier to merge a small buffer to the raymp that passed in parameter for complex work
--
-- so in actual event condition we can update the small buffer that we created before merge it
-- so if there's a changes it will merge it otherwise it didn't
--
-- see if we can handle themes diffrently

local api            = require("rmp.rmp")
local utils          = require("rmp.util")
local OOP            = require("rmp.oop")

-- Engine-level modal input state (raymp:input). Declared early so the
-- EngineFrame:input() method below can capture these locals.
local pending_inputs = utils.Queue.new()
local current_input  = nil

local joinPath       = api.Path.joinPath
local colorFromHex   = api.colorFromHex
local Frame          = api.Frame
local FG             = api.FG
local BG             = api.BG
local Text           = api.Text
local TextStyle      = api.TextStyle

-- ─────────────────────────────────────────────────────────────────────────────
-- Engine configuration (raymp.engine)
-- ─────────────────────────────────────────────────────────────────────────────
-- The engine config lives on the global frame as raymp.engine. Config
-- files (~/.rmp/init.lua, builtin defaults) populate it directly instead of
-- returning a table. Two styles are equivalent:
--
--     raymp.engine.settings.fps = 30   -- canonical subtables
--     raymp.engine.fps = 30            -- shorthand proxy => settings.fps
--
-- Canonical keys:
--   engine.template  string    template name to render
--   engine.settings  table     engine/UI settings (fps, volume, keys, ...)
--   engine.soundMap  table     playback keybindings
--   engine.plugins   table     plugin groups
--   engine.builtin   table|false  builtin enable/disable toggles (see below)
--
-- Builtin configuration model (nvim-style):
--   The builtin defaults are ALWAYS applied first. A ~/.rmp/init.lua is then
--   layered on top, so you keep the defaults and only override what you want.
--   Builtin components ship enabled but can be toggled globally:
--
--     raymp.engine.builtin = false                  -- disable all builtins
--     raymp.engine.builtin.help          = true     -- help overlay (H)
--     raymp.engine.builtin.notify        = true     -- notification popups
--     raymp.engine.builtin.themes        = true     -- builtin theme list
--     raymp.engine.builtin.theme_manager = true     -- theme auto-selector
--     raymp.engine.builtin.plugins = {              -- builtin window plugins
--         tutorial_rmp               = true,
--         helper_keys_tutorial       = true,
--         matrix_digital_rain_effect = true,
--         builtin-theme-default-rmp  = true,        -- themes are real plugins too
--         -- builtin-theme-manager-rmp, builtin-theme-desert-rmp, ...
--     }
-- ─────────────────────────────────────────────────────────────────────────────
local ENGINE_KEYS    = { template = true, settings = true, soundMap = true, plugins = true, builtin = true }

local engine_proxy   = {
    __index = function(t, k)
        if ENGINE_KEYS[k] then return rawget(t, k) end
        local v = rawget(t, k)
        if v ~= nil then return v end
        local s = rawget(t, "settings")
        return s and s[k] or nil
    end,
    __newindex = function(t, k, v)
        if ENGINE_KEYS[k] then
            rawset(t, k, v)
        else
            local s = rawget(t, "settings")
            if s then s[k] = v else rawset(t, k, v) end
        end
    end,
}

--- Builds a fresh, empty engine config shell. The real defaults are applied
--- by the builtin configuration (src/engine/builtin/init.lua), then a user
--- config is layered on top. The proxy makes `engine.fps = 30` equivalent to
--- `engine.settings.fps = 30`.
--- @return table
local function build_engine_shell()
    local engine = {
        template     = nil,
        settings     = {},
        soundMap     = {},
        plugins      = {},
        builtin      = {
            help          = true,
            notify        = true,
            themes        = true,
            theme_manager = true,
            plugins       = {
                tutorial_rmp                        = true,
                helper_keys_tutorial                = true,
                matrix_digital_rain_effect          = true,
                ["builtin-theme-manager-rmp"]       = true,
                ["builtin-theme-default-rmp"]       = true,
                ["builtin-theme-blackandwhite-rmp"] = true,
                ["builtin-theme-desert-rmp"]        = true,
                ["builtin-theme-elflord-rmp"]       = true,
            },
        },
        --- the message passed in params just for additional infotmation
        --- you can ignore it and use your own box
        notification = {
            box = function(message)
                local _, term_w = api.Terminal:getSize()
                local box_width = math.min(term_w - 2, math.max(12, #message + 4))
                local box_height = 3
                local box_x = math.max(1, term_w - box_width)
                local box_y = 1
                return {
                    x      = box_x,
                    y      = box_y,
                    width  = box_width,
                    height = box_height,
                    border = api.BoxDrawing.RoundedCorners
                }
            end,
            stacked = true
        }

    }
    return setmetatable(engine, engine_proxy)
end

--- Returns whether a builtin component is enabled by the user config.
--- The builtin table defaults every flag to true when the field is missing,
--- so partial overrides (e.g. `engine.builtin.plugins = { x = false }`) work.
--- @param engine table
--- @param group string|nil   "plugins" for window plugins, nil for flat flags
--- @param name string        flag name within the group
--- @return boolean
local function builtin_enabled(engine, group, name)
    local builtin = engine and engine.builtin
    if builtin == false then return false end
    if type(builtin) ~= "table" then return true end
    local flags = group and builtin[group] or builtin
    if type(flags) ~= "table" then return flags ~= false end
    return flags[name] ~= false
end

--- Re-seeds raymp.engine with an empty shell. Must be called before each
--- configuration load so restarts never inherit state from a previous cycle.
local function resetEngine()
    raymp.engine = build_engine_shell()
end

--- Merges a legacy returned-table config on top of the engine config. Keeps
--- prototype-compatibility: `return { template=..., settings={...}, ... }`.
--- @param engine table
--- @param tbl table|nil
--- @return table
local function merge_into_engine(engine, tbl)
    if type(tbl) ~= "table" then return engine end
    if tbl.template ~= nil then engine.template = tbl.template end
    if type(tbl.settings) == "table" then
        for k, v in pairs(tbl.settings) do engine.settings[k] = v end
    end
    if type(tbl.soundMap) == "table" then
        for k, v in pairs(tbl.soundMap) do engine.soundMap[k] = v end
    end
    if type(tbl.plugins) == "table" then engine.plugins = tbl.plugins end
    return engine
end

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

local TemplateBuilder = OOP.class("TemplateBuilder")
do
    -- local tpl = api.Template.new()
    --
    -- tpl:window("animation-window")          -- id required, auto-validated
    --     :title("🎵 NOW PLAYING")            -- plain string → auto-wrapped Text node
    --     :titleBg(api.BGColors.NoBrights.Magenta)  -- idempotent with :title("")
    --     :pos("w - w*0.3 + 1", "h/2 + 1")        -- x,y shorthand
    --     :size("w*0.3 + 1", "h/2")               -- width,height shorthand
    --     :border(api.BoxDrawing.RoundedCorners)
    --     :condition(function(context) return context.w >= 80 end)
    --
    -- tpl:window("tutorial-window")
    --     :title(function(ctx) return "[ RMP ] " .. os.date("%H:%M:%S") end)  -- dynamic
    --     :text({ value = "...", fg = api.FGColors.Brights.Cyan })             -- explicit Text opts
    --     :pos(1, 1):size("w", "h")
    --     :content(function(innerX, innerY, innerXX, innerYY, context)
    --         -- same signature the TemplateParser passes today
    --     end)
    --
    -- return tpl:build()   -- returns array-of-windows (USER template style)
    -- -- or  tpl:apply()   -- mutates raymp.engine.template + returns nil (BUILTIN style)
    function TemplateBuilder:constructor()

    end

    -- here where the method returns a table that can be parsed with the engine
    -- this class is used for new API template also a backward compatible
    -- it's recommended but it's fine to not update the old generated template
    function TemplateBuilder:build()

    end
end

local EngineFrame = OOP.class("EngineFrame", Frame)
do
    function EngineFrame:constructor(width, height)
        --- @diagnostic disable-next-line
        self:super("constructor", width, height)

        self.theme            = nil
        self.engine           = build_engine_shell()

        -- TODO: implement template_builder
        -- raymp.engine.template = rayden.template_builder:window():x():children():...:build()
        self.template_builder = TemplateBuilder()
    end

    --- raymp:plug({
    ---     name = "foo"
    --- })
    ---@param obj table
    function EngineFrame:plug(obj)
        table.insert(self.engine.plugins, {
            priority = obj.priority,
            themeWindowId = obj.windowId,
            isActivated = obj.activated or true,
            switchPluginKey = obj.switchKey, -- not recommended i added just for backward compatibility
            names = (function()
                if type(obj.name) == "string" then
                    return { obj.name }
                elseif type(obj.name) == "table" then
                    return obj.name
                end
            end)()
        })
    end

    -- TODO: update my configurations and plugins that i uploaded on github
    -- TODO: make buildin plugins more customizable

    -- TODO: add notify
    function EngineFrame:notify(message, conf)
        local status = "info"
        local duration = 3
        if conf then
            status = conf.status or "info"
            duration = conf.duration or 3
        end
        self:addEventListener(api.EventType.TransformDataPut, function()
            return {
                notification = {
                    message = message,
                    -- status = "info",
                    -- status = "error",
                    -- status = "warning",
                    -- status = "message",
                    status = status,
                    duration = duration
                }
            }
        end)
    end

    --- Queue a modal text-input prompt from a plugin. One prompt is active at a
    --- time (FIFO); while active it grabs all keys so engine/plugin keymaps are
    --- suppressed. conf uses the rmp.rmp.SimpleInput option names plus callbacks:
    ---   {
    ---     label = "Search: ", x = nil, y = nil, width = 30,
    ---     default = "", placeholder = "...", maxLength = 100,
    ---     validator = function(v) return true, "err" end,
    ---     on_submit = function(value) ... end,
    ---     on_cancel = function() ... end,
    ---   }
    --- Esc cancels, Enter submits (if the validator passes).
    --- @param conf table
    --- @return table|nil handle with isActive()/getValue()/cancel()
    function EngineFrame:input(conf)
        if type(conf) ~= "table" then
            return nil
        end
        pending_inputs:push(conf)
        return {
            isActive = function()
                return current_input ~= nil and current_input.conf == conf
                    and current_input.simple:isActive()
            end,
            getValue = function()
                if current_input and current_input.conf == conf then
                    return current_input.simple:getValue()
                end
                return tostring(conf.value or conf.default or "")
            end,
            cancel = function()
                conf.cancelled = true
                if current_input and current_input.conf == conf then
                    current_input.simple:blur()
                    current_input = nil
                end
            end,
        }
    end

    --- template component
    --- theme table
    --- variant
    function EngineFrame:applyTheme(tha_template, th, variant)
        for _, component in ipairs(tha_template) do
            if component.title then
                if type(component.title) == "string" then
                    local val = component.title
                    component.title = {
                        value = val,
                        foregroundColor = api.colorFromHex(th[variant].TitleText, api.FG),
                        backgroundColor = api.colorFromHex(th[variant].TitleBackGround, api.BG),
                    }
                elseif type(component.title) == "table" then
                    component.title.foregroundColor = api.colorFromHex(th[variant].TitleText, api.FG)
                    component.title.backgroundColor = api.colorFromHex(th[variant].TitleBackGround, api.BG)
                else
                    component.table = nil
                end
            end
            component.foregroundColor = api.colorFromHex(th[variant].BorderColor, api.FG)
            component.backgroundColor = api.colorFromHex(th[variant].BackGround, api.BG)
            if component.children then
                self:applyTheme(component.children, th, variant)
            end
        end
    end

    ---@param thaTheme Theme
    ---@return self
    function EngineFrame:setTheme(thaTheme)
        self.theme = thaTheme
        return self
    end

    ---@return Theme
    function EngineFrame:getTheme()
        return self.theme
    end

    -- TODO: make it easy to change to other theme colors without require them from the shared data

    ---@param text string
    ---@param style TextStyle
    ---@return self
    function EngineFrame:write(text, style)
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
    function EngineFrame:openWin(options)
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

    -- add input handling by the engine to avoid any mistakes of memory allocations
end

raymp                       = EngineFrame()

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
-- Engine-level input (raymp:input)
-- ─────────────────────────────────────────────────────────────────────────────
-- Plugins queue modal text-input prompts through EngineFrame:input(); the main
-- loop drains the queue (FIFO, one active at a time) and, while a prompt is
-- active, grabs all keys so engine/plugin keymaps and sound controls don't fire
-- on typing characters. Built on rmp.rmp.SimpleInput (focus/_handleKey).
-- (pending_inputs / current_input are declared at the top of the file so the
-- EngineFrame:input() method and these helpers share the same cells.)
-- ─────────────────────────────────────────────────────────────────────────────

local function reset_inputs()
    pending_inputs = Queue.new()
    current_input  = nil
end

--- Maps an RMP key enum (api.KEY_A, api.KEY_COLON, ...) to its printable
--- character. RMP keys are enum integers, not ASCII, so string.char() would be
--- wrong (e.g. api.KEY_A is the 72nd enum value). Reuses the class method
--- SimpleInput._keyToChar whose implicit `self` parameter is unused.
--- @param inputKey integer
--- @return string|nil
local function key_to_char(inputKey)
    if not (api.SimpleInput and inputKey ~= nil) then return nil end
    local ok, ch = pcall(api.SimpleInput._keyToChar, api.SimpleInput, inputKey)
    if ok then return ch end
    return nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Plugin runtime error quarantine
-- ─────────────────────────────────────────────────────────────────────────────
-- Runtime plugin errors are isolated instead of taking down the engine: the
-- failing plugin is logged with its module name and disabled so it cannot
-- re-trigger the error every frame (the "glitching red window" scenario).
-- name_by_fn maps a loaded plugin function back to its module name (populated
-- by setupPlugins); disabled holds names that must no longer run until the
-- engine restarts.
-- ─────────────────────────────────────────────────────────────────────────────

local plugin_registry = { name_by_fn = {}, disabled = {} }

--- Extracts a plugin module name from an error message such as
--- ".../plugins/my-plugin-rmp/init.lua:42: attempt to index a nil value".
--- @param err any
--- @return string|nil
local function plugin_name_from_error(err)
    local s = tostring(err)
    return s:match("plugins[/\\]([%w%-_]+)[/\\]") or s:match("plugins[/\\]([%w%-_]+)%.lua")
end

--- Logs a plugin runtime error and quarantines the responsible plugin.
--- @param context string  what was happening (e.g. "template rendering")
--- @param err any
local function log_plugin_error(context, err)
    local name = plugin_name_from_error(err)
    logwarn(context .. " error: " .. tostring(err)
        .. (name and (" [plugin: " .. name .. " disabled]") or ""))
    if name then plugin_registry.disabled[name] = true end
end

--- Pops the next non-cancelled prompt from the queue and focuses it. Default
--- x/y center the field at the bottom of the frame.
--- @param frame rmp.rmp.Frame
local function activate_next_input(frame)
    while not pending_inputs:isEmpty() do
        local conf = pending_inputs:pop()
        if not conf.cancelled then
            if not conf.x or not conf.y then
                local w, h = frame:getSize()
                local field_w = #(conf.label or "") + (conf.width or 30)
                if not conf.x then
                    conf.x = math.max(1, math.floor((w - field_w) / 2))
                end
                if not conf.y then
                    conf.y = math.max(1, h - 2)
                end
            end
            local opts = {}
            for _, k in ipairs({
                "x", "y", "width", "label", "placeholder", "maxLength",
                "validator", "fg_normal", "bg_normal", "fg_active",
                "bg_active", "fg_error", "chr",
            }) do
                if conf[k] ~= nil then opts[k] = conf[k] end
            end
            opts.value = conf.default or conf.value or ""
            local inp = api.SimpleInput.new(opts)
            inp:focus()
            current_input = {
                conf     = conf,
                simple   = inp,
                last_key = nil,
            }
            break
        end
    end
end

--- Feeds one key into the active prompt. When the prompt closes (blur) it
--- dispatches on_submit (Enter, valid) or on_cancel (Escape). Callbacks are
--- pcall-guarded. Returns true when the key was consumed by the modal prompt.
--- @param key integer
--- @return boolean
local function feed_input(key)
    local sess = current_input
    if not sess or not sess.simple:isActive() or key == nil then
        return false
    end

    sess.last_key = key
    sess.simple:_handleKey(key)

    if not sess.simple:isActive() then
        local conf = sess.conf
        if not conf.cancelled then
            local callback = sess.last_key == api.KEY_ENTER and conf.on_submit
                or conf.on_cancel
            if type(callback) == "function" then
                local ok, res = pcall(callback, sess.simple:getValue())
                if not ok then
                    logwarn("input callback error: " .. tostring(res))
                end
            end
        end
        current_input = nil
    end
    return true
end

--- Draws the active prompt on top of the frame and flushes the frame's
--- keyboard/focus event queues so plugin listeners can't consume typing keys
--- (listeners are re-registered per frame, so flushing keeps them from firing).
--- @param frame rmp.rmp.Frame
local function render_input(frame)
    local sess = current_input
    if not sess or not sess.simple:isActive() then
        return
    end
    sess.simple:_renderField(frame)
    local kq = frame.events:get(api.EventType.Keyboard)
    while kq and not kq:isEmpty() do kq:pop() end
    local fq = frame.events:get(api.EventType.Focuse)
    while fq and not fq:isEmpty() do fq:pop() end
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
        or "Up/Down or K/J: scroll   /: filter   Esc: close"
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
    function TemplateParser:constructor(template, plugManager, frame, registry)
        self.template                = template or {}
        self.plugManager             = plugManager
        self.mainFrame               = frame or raymp
        self.plugRegistry            = registry
        self.windowCache             = {}
        self.pluginCache             = {}
        self.lastTerminalSize        = { w = 0, h = 0 }
        self.compiledExpressions     = {}
        self.compiledExpressionsSize = 0
        self.exprKeyOrder            = {} -- OPT-7: eviction order list
    end

    --- Returns the active (enabled) plugin for a window slot, rotating past any
    --- plugin that was disabled after a runtime error. Returns nil when the slot
    --- has no usable plugin.
    --- @param id string
    --- @return function|nil
    function TemplateParser:nextEnabledPlugin(id)
        if not id or not self.plugManager then return nil end

        -- Drop a cached plugin that was disabled at runtime
        if self.pluginCache[id] and self:_disabled(self.pluginCache[id]) then
            self.pluginCache[id] = nil
        end
        if self.pluginCache[id] then return self.pluginCache[id] end

        -- Rotate past disabled plugins (each getNextPlug call advances the slot)
        for _ = 1, 32 do
            local plugin, err = self.plugManager:getNextPlug(id)
            if plugin and not err and not self:_disabled(plugin) then
                self.pluginCache[id] = plugin
                return plugin
            end
        end
        return nil
    end

    --- True when the plugin function was disabled after a runtime error.
    --- @param fn function
    --- @return boolean
    function TemplateParser:_disabled(fn)
        return fn and self.plugRegistry and type(fn) == "function"
            and self.plugRegistry.disabled[self.plugRegistry.name_by_fn[fn]] == true
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
            textConfig.backgroundColor, raymp)
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
    --- @param frame VirtualTerminal|nil  Target frame (defaults to raymp)
    function TemplateParser:createWindow(windowConfig, context, frame)
        if not windowConfig or windowConfig.type ~= "Window" then return nil end

        if windowConfig.condition and type(windowConfig.condition) == "function" then
            if not windowConfig.condition(context) then return nil end
        end

        local targetFrame   = frame or self.mainFrame or raymp
        local width         = self:evaluateExpression(windowConfig.width, context)
        local height        = self:evaluateExpression(windowConfig.height, context)
        local x             = self:evaluateExpression(windowConfig.x, context)
        local y             = self:evaluateExpression(windowConfig.y, context)
        local title         = windowConfig.title and self:parseText(windowConfig.title, context) or nil

        -- Resolve plugin for this window slot (cached per slot id), skipping
        -- any plugin disabled after a runtime error.
        local currentPlugin = self:nextEnabledPlugin(windowConfig.id)

        local callback      = function(innerX, innerY, innerXX, innerYY)
            -- Run the window's plugin
            if currentPlugin and type(currentPlugin) == "function" then
                local ok, pluginResult = pcall(currentPlugin, innerX, innerY, innerXX, innerYY)
                if not ok then
                    -- Quarantine: disable the failing plugin and clear the cache
                    -- so it cannot re-trigger the same error every frame.
                    local pname = self.plugRegistry
                        and self.plugRegistry.name_by_fn[currentPlugin]
                        or nil
                    if pname then
                        self.plugRegistry.disabled[pname] = true
                        logwarn("window plugin '" .. pname
                            .. "' disabled after runtime error: " .. tostring(pluginResult))
                    else
                        logwarn("plugin error in window '" .. tostring(windowConfig.id)
                            .. "': " .. tostring(pluginResult))
                    end
                    self.pluginCache[windowConfig.id] = nil
                elseif ok and pluginResult and type(pluginResult) == "table" then
                    raymp:add(pluginResult)
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
                local ok, contentResult = pcall(windowConfig.content, raymp,
                    innerX, innerY, innerXX, innerYY, context)
                if not ok then
                    logwarn("content error in window '" .. tostring(windowConfig.id)
                        .. "': " .. tostring(contentResult))
                elseif ok and contentResult and type(contentResult) == "table" then
                    raymp:add(contentResult)
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
        local targetFrame = frame or self.mainFrame or raymp

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
-- Any builtin plugin name appearing in a group can be turned off with
-- raymp.engine.builtin.plugins.<name> = false (see builtin_enabled).
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
                -- User-space plugin first; fall back to the builtin list so
                -- default configs (e.g. matrix_digital_rain_effect) still resolve
                ok, mod = pcall(require, pluginName)
                if not ok then
                    ok, mod = pcall(require, "rmp.builtin.plugins." .. pluginName)
                end
            end
        else
            ok, mod = pcall(require, "rmp.builtin.plugins." .. pluginName)
            if type(name) == "string" then
                plugins_configurations:put(name, nil)
            else
                plugins_configurations:put(pluginName, cfg)
            end
        end

        if ok and mod then
            if type(pluginName) == "string" then
                plugin_registry.name_by_fn[mod] = pluginName
            end
            return mod
        end
        logwarn("Could not load plugin '" .. label .. "': " .. tostring(mod))
        return nil
    end

    -- Builtin window plugins ship enabled but can be turned off via
    -- raymp.engine.builtin.plugins.<name> = false
    local function builtin_plugin_skipped(name)
        local pluginName = (type(name) == "table") and (name.name or name[1]) or name
        if type(pluginName) ~= "string" then return false end
        return not builtin_enabled(configObj, "plugins", pluginName)
    end

    for _, plug in ipairs(plugins) do
        if not (plug.isActivated and plug.names) then goto continue end

        if plug.themeWindowId then
            -- Window-attached plugin group
            local pq = Queue.new()
            for _, name in ipairs(plug.names) do
                if not builtin_plugin_skipped(name) then
                    local mod = load_plugin_module(name, is_userconfig)
                    if mod then pq:push(mod) end
                end
            end
            if not pq:isEmpty() then
                plugs:put(plug.themeWindowId, { plug.switchPluginKey, pq })
            end
        else
            -- Global plugin (no window slot)
            for _, name in ipairs(plug.names) do
                if not builtin_plugin_skipped(name) then
                    local mod = load_plugin_module(name, is_userconfig)
                    if mod then otherPlugs:push(mod) end
                end
            end
        end

        ::continue::
    end

    -- Builtin themes ship enabled and are loaded through the plugin manager
    -- exactly like the other builtin plugins, so they share the same lifecycle
    -- (module required once, plug() called every frame from otherPlugs). They
    -- are gated by the flat engine.builtin.themes / engine.builtin.theme_manager
    -- switches and can also be toggled individually via
    -- engine.builtin.plugins.<name> = false.
    local builtin_theme_plugins = {
        "builtin-theme-manager-rmp", -- theme auto-selector (selects settings.theme)
        "builtin-theme-default-rmp", -- vim-like colorschemes
        "builtin-theme-blackandwhite-rmp",
        "builtin-theme-desert-rmp",
        "builtin-theme-elflord-rmp",
    }
    local builtin_theme_group = {
        ["builtin-theme-manager-rmp"]       = "theme_manager",
        ["builtin-theme-default-rmp"]       = "themes",
        ["builtin-theme-blackandwhite-rmp"] = "themes",
        ["builtin-theme-desert-rmp"]        = "themes",
        ["builtin-theme-elflord-rmp"]       = "themes",
    }
    for _, name in ipairs(builtin_theme_plugins) do
        local group = builtin_theme_group[name]
        if group and builtin_enabled(configObj, nil, group) and not builtin_plugin_skipped(name) then
            local mod = load_plugin_module(name, false)
            if mod then otherPlugs:push(mod) end
        end
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
    raymp:clear()

    -- Expose the merged sound mapping back onto the engine config so plugins
    -- can read the full keymap directly from raymp.engine.soundMap
    if configObj and soundCfg then
        configObj.soundMap = soundCfg
    end

    local sound             = api.Sound()
    local data_freq_engine  = nil
    local valid_restart     = false
    local help_fn           = nil
    local exit              = api.KEY_Q
    local messages_key      = api.KEY_M
    local reload_key        = nil -- FEAT-1: hot-reload key
    local show_logs         = false
    local log_theme         = nil
    local notify_plug       = nil
    local render_help       = false

    -- FEAT-4: log overlay state
    local log_overlay_state = { scroll = 0, filter = "", filter_active = false }

    -- While the log overlay is open it owns the keyboard exclusively: the main
    -- loop runs this handler instead of dispatching to the frame's listeners,
    -- so plugin hotkeys (playback, theme, etc.) never collide with overlay
    -- navigation. Preserves the legacy keys: K/J scroll, / filter, Esc close.
    local function overlay_handle_key(inputKey)
        if messages_key and inputKey == messages_key then
            show_logs                       = false
            log_overlay_state.scroll        = 0
            log_overlay_state.filter        = ""
            log_overlay_state.filter_active = false
            return
        end
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
                -- Append printable character (RMP keys are enum ints, not ASCII)
                local ch = key_to_char(inputKey)
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
    end

    -- Apply settings using OPT-3 helper
    local inc_speed  = 0.1
    local inc_volume = 0.1
    local inc_seek   = 5

    if settings then
        local fps = validated_setting(settings.fps, "number", 1, 120, 60)
        settings.fps = fps
        raymp:setFps(fps)

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

        help_fn    = (builtin_enabled(configObj, nil, "help")
            and type(settings.help_key) == "number") and settings.help_key or nil
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

        -- Sync the active theme name so the builtin theme-manager (and theme
        -- plugins that still read engine.theme) auto-select settings.theme.
        -- settings.theme stays the single source of truth; engine.theme is a
        -- legacy alias the theme-manager resolves into the selected colors.
        if type(settings.theme) == "string" then
            raymp.engine.theme = settings.theme
        end

        if settings.notify and builtin_enabled(configObj, nil, "notify") then
            local ok, mod = pcall(require, "rmp.builtin.plugins.builtin-notify-rmp")
            if ok and mod then notify_plug = mod end
        end
    else
        raymp:setFps(60)
        sound:enableVisualization(32)
        sound:setVolume(0.5)
        sound:setSpeed(1.0)
        sound:setPlayBackMode(0)
    end

    raymp:initMainFrame()

    local parser        = TemplateParser.new(template, plugManager, raymp, plugin_registry)
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

        raymp:clear()
        -- raymp.cursor.x = 1
        -- raymp.cursor.y = 1

        local key = api.Terminal:handleKey()

        if parser:wasTerminalResized() then
            h, w = api.Terminal:getSize()
            raymp:resize(w, h)
        end

        -- Engine-level modal input (raymp:input): activate the next queued
        -- prompt, then feed the key. While active, the engine key handler
        -- below is skipped so typing never drives playback/log/quit keys.
        if not current_input then
            activate_next_input(raymp)
        end
        local input_modal = current_input ~= nil and current_input.simple:isActive()
        if input_modal and feed_input(key) then
            key = nil
        end

        -- Log overlay exclusivity: while it is open the overlay owns every key.
        -- Consuming the key (nil) makes handleEvent drain the Focuse/Keyboard
        -- queues, so plugin listeners and the engine's sound/switch bindings
        -- never see overlay navigation keys.
        if show_logs and not input_modal then
            overlay_handle_key(key)
            key = nil
        end

        -- Cache sound state once per frame to avoid repeated FFI calls
        local isPlaying = sound:isPlaying()
        local currVol   = sound:getVolume()
        local currPos   = math.floor(sound:getPosition())
        local len       = math.floor(sound:getLength())
        local currSpeed = sound:getSpeed()

        raymp:onDataGet(function(data)
            if data and data.theme then
                sharedTheme = data.theme.def or data.theme
            end
        end)

        raymp:setTheme(sharedTheme)

        -- ── Keyboard event handler ────────────────────────────────────────
        -- Skipped while a modal raymp:input prompt is active (it grabs keys)
        if not input_modal then
            raymp:addEventListener(api.EventType.Keyboard, function(inputKey)
                -- Log overlay toggle (opening; closing is handled by
                -- overlay_handle_key in the main loop while it is open)
                if messages_key and inputKey == messages_key then
                    show_logs                       = true
                    log_overlay_state.scroll        = 0
                    log_overlay_state.filter        = ""
                    log_overlay_state.filter_active = false
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
                    -- TODO: rayden was here
                    soundCfg.mode = sound:getPlayBackMode()
                end
            end)
        end

        -- Advance sound engine and grab frequency data
        sound:update()
        if isPlaying then
            data_freq_engine = sound:getFrequencyData()
        end

        -- Parse and render the layout template (plugin callbacks are isolated so a
        -- dynamic/condition/content error can't take down the engine loop)
        local ok_tpl, tpl_err = pcall(parser.parseTemplate, parser, template_copy)
        if not ok_tpl then
            log_plugin_error("template rendering", tpl_err)
        end

        -- Help overlay
        if render_help and builtin_enabled(configObj, nil, "help") then
            local h_ok, h_obj = pcall(require, "rmp.builtin.plugins.builtin-help-rmp")
            if h_ok and h_obj and type(h_obj) == "function" then
                local ok_help, help_err = pcall(h_obj)
                if not ok_help then log_plugin_error("help overlay", help_err) end
            end
        end
        if help_fn and key == help_fn then
            render_help = not render_help
        end

        -- Global plugins (FEAT-2: errors are isolated per plugin; now with
        -- quarantine — the failing plugin is disabled so it can't re-error)
        local qq = Queue()
        while oq and not oq:isEmpty() do
            local plug = oq:pop()
            if plug then
                local pname = (type(plug) == "function")
                    and plugin_registry.name_by_fn[plug] or nil
                if pname and plugin_registry.disabled[pname] then
                    -- previously disabled after a runtime error
                    goto skip_push
                end
                if type(plug) == "function" then
                    local ok, res = pcall(plug)
                    if not ok then
                        if pname then plugin_registry.disabled[pname] = true end
                        logwarn((pname and ("global plugin '" .. pname
                                .. "' disabled after runtime error: ") or "global plugin error: ")
                            .. tostring(res))
                        -- drop the failing plugin from the queue
                        goto skip_push
                    elseif ok and res then
                        raymp:add(res)
                    end
                elseif type(plug) == "table" then
                    local fn = plug.update or plug.poll or plug.render
                    if fn then
                        local ok, res = pcall(fn, raymp)
                        if not ok then
                            if pname then plugin_registry.disabled[pname] = true end
                            logwarn((pname and ("global plugin '" .. pname
                                    .. "' disabled after runtime error: ") or "global plugin error: ")
                                .. tostring(res))
                            goto skip_push
                        elseif ok and res then
                            raymp:add(res)
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
            local ok_notify, notif_err = pcall(notify_plug)
            if not ok_notify then log_plugin_error("notification", notif_err) end
        end

        local notis = drain_notifications()
        if settings and settings.notify and builtin_enabled(configObj, nil, "notify") then
            for _, noti in ipairs(notis) do
                raymp:addEventListener(api.EventType.TransformDataPut, function()
                    return { notification = noti }
                end)
            end
        end

        -- Sync theme for log overlay
        raymp:addEventListener(api.EventType.TransformDataGet, function(data)
            if data and data.theme then log_theme = data.theme end
        end)

        -- Log overlay (FEAT-4)
        if show_logs then
            local log_vt = api.VirtualTerminal(1, 1)
            if raymp then
                render_log_overlay(raymp, log_overlay_state, log_theme)
            end
            raymp:add(log_vt, true)
        end

        -- Push config/sound/template to plugins via plugs_cfgs HashMap
        if plugs_cfgs then
            plugs_cfgs:put("soundCfg", soundCfg)
            plugs_cfgs:put("settings", settings)
            plugs_cfgs:put("all", configObj)
        end

        -- Draw the modal input prompt on top and flush key queues before the
        -- frame is flushed/rendered, so plugin listeners never see typing keys.
        render_input(raymp)

        -- Flush the frame to the terminal. Plugin listeners (keyboard/focus/mouse)
        -- run inside here through handleEvent without their own protection, so
        -- the whole dispatch is isolated: a plugin error is logged + quarantined
        -- instead of crashing the engine loop into the red error window.
        local ok_run, run_err = pcall(raymp.run, raymp, key, nil, sound,
            plugs_cfgs, template_copy, data_freq_engine, quit)
        if not ok_run then
            log_plugin_error("plugin listener", run_err)
        end

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
-- templates and plugins. Always runs AFTER the builtin defaults, so the user
-- file only needs to override what it wants to change.
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
    --- The file may either populate raymp.engine directly (new style,
    --- e.g. `raymp.engine.fps = 30`) or return a table (legacy style,
    --- which is merged on top of the engine config).
    --- @return boolean, string|nil
    function Config:load()
        if not self.isValidFile then return false, self.isError end
        if self.cfgObj then return true, nil end

        local ok, res = pcall(dofile, self.initPath:getPath())
        if not ok then
            self.isError = "failed to load init.lua: " .. tostring(res)
            return false, self.isError
        end
        if type(res) == "table" then
            merge_into_engine(raymp.engine, res)
        end
        self.cfgObj = raymp.engine
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
-- nvim-style loading:
--   1. The builtin defaults are ALWAYS applied to raymp.engine first, so
--      the shipped settings, keymap, template and builtin plugins are always
--      present.
--   2. If ~/.rmp/init.lua exists it is layered on top — user changes override
--      the defaults but everything else keeps working.
--   3. Builtin components ship enabled; toggles live on raymp.engine.builtin
--      (see builtin_enabled / the engine config docs above).
-- ─────────────────────────────────────────────────────────────────────────────
local function loadConfiguration()
    -- Start from a clean engine config on every (re)load
    resetEngine()

    -- 1) Always apply builtin defaults first. The builtin config mutates
    --    raymp.engine directly, so require()'s module cache must be
    --    cleared before each (re)load — otherwise a restart (restart_engine)
    --    skips re-applying the defaults to the fresh engine shell.
    package.loaded["rmp.builtin.init"] = nil
    local ok_builtin, defaultConfig = pcall(require, "rmp.builtin.init")
    if not ok_builtin then
        logfatal("Error loading builtin configuration: " .. tostring(defaultConfig))
        return nil, nil, nil
    end
    if type(defaultConfig) == "table" then
        merge_into_engine(raymp.engine, defaultConfig)
    end

    -- 2) Layer the user configuration on top (if it exists)
    local config = Config()
    local is_userconfig = config:isValidConfig()
    if is_userconfig then
        local ok, err = config:load()
        if not ok then
            logfatal("loading user configuration: " .. err)
            return nil, nil, nil
        end
    end

    local cfgObj = raymp.engine

    -- 3) Resolve the template:
    --    a) the template may be provided as an inline table
    --    b) a named template: look in ~/.rmp/templates/ first, then builtin
    local template = cfgObj.template
    if type(template) == "table" then
        return cfgObj, template, is_userconfig
    end

    if type(template) ~= "string" then
        logerror("Invalid or missing 'template' field in configuration.")
        lognote("Example: raymp.engine.template = 'tutorial'")
        logfatal("Invalid template name in configuration.", true)
        return nil, nil, nil
    end

    if is_userconfig then
        local userTemplatePath = joinPath(config.homePath:getPath(), ".rmp", "templates", template .. ".lua")
        local okUser, userTemplateOpen = pcall(dofile, userTemplatePath)
        -- User templates may be mutation-style (setting raymp.engine.template)
        -- or return the window table directly — accept either convention.
        if okUser and (type(userTemplateOpen) == "table" or type(cfgObj.template) == "table") then
            return cfgObj, userTemplateOpen or cfgObj.template, true
        end
    end

    -- Builtin templates are mutation-style modules (they set
    -- raymp.engine.template inline), so bust the cache to re-run them
    -- on restarts the same way the builtin init is re-run above.
    local builtin_template_module = "rmp.builtin.templates." .. template
    package.loaded[builtin_template_module] = nil
    local okBuiltinTemplate, builtinTemplate = pcall(require, builtin_template_module)
    if okBuiltinTemplate and type(builtinTemplate) == "table" then
        return cfgObj, builtinTemplate, is_userconfig
    end
    -- Builtin templates are mutation-style: they set raymp.engine.template
    -- to the window table instead of returning it.
    if okBuiltinTemplate and type(cfgObj.template) == "table" then
        return cfgObj, cfgObj.template, is_userconfig
    end

    logerror("Template '" .. tostring(template) .. "' not found in ~/.rmp/templates/ nor in the builtin templates.")
    lognote("Example entry: { type='Window', id='main', width='w', height='h', x=0, y=0, border=true }")
    logfatal("loading template: Not found or error", true)
    return nil, nil, nil
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
        reset_inputs()
        plugin_registry.disabled = {} -- restart re-enables quarantined plugins

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
            raymp:clear()
            restart         = true

            local boxWidth  = math.min(math.floor(w * 0.9), 120)
            local boxHeight = math.floor(h * 0.8)
            if w < 60 then boxWidth = w end
            if h < 20 then boxHeight = h end
            local boxX = math.floor((w - boxWidth) / 2)
            local boxY = math.floor((h - boxHeight) / 2)

            local box_title = Text(" RMP Engine Error ", TextStyle.Bold,
                api.FGColors.Brights.White, api.BGColors.NoBrights.Red, raymp)
            raymp:drawBox(box_title, boxX, boxY, boxWidth, boxHeight,
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
                    raymp:writeText(boxX + 2, currentY, line_text,
                        api.FGColors.Brights.White, api.BGColors.NoBrights.Black)
                    currentY = currentY + 1
                else
                    raymp:writeText(boxX + 2, currentY, "...",
                        api.FGColors.Brights.White, api.BGColors.NoBrights.Black)
                    break
                end
            end

            local prompt   = "Press 'Q' to Quit   'R' to Restart"
            local prompt_x = math.floor((w - #prompt) / 2)
            local prompt_y = boxY + boxHeight - 2
            raymp:writeText(prompt_x, prompt_y, prompt,
                api.FGColors.Brights.Black, api.BGColors.NoBrights.White)

            -- Quarantine stale listeners: a plugin that caused the fatal error must not
            -- re-trigger while the user reads the message (the old "glitching"
            -- window came from exactly that recursive re-entry).
            local err_kq = raymp.events:get(api.EventType.Keyboard)
            while err_kq and not err_kq:isEmpty() do err_kq:pop() end
            local err_fq = raymp.events:get(api.EventType.Focuse)
            while err_fq and not err_fq:isEmpty() do err_fq:pop() end

            raymp:onKeyboard(function(key)
                if key == api.KEY_Q then
                    restart = false
                elseif key == api.KEY_R then
                    restart = true
                end
            end)
            pcall(raymp.run, raymp, api.Terminal:handleKey(), nil, nil, nil, nil)
            if not restart then break end
        end
    end

    raymp:cleanupMainFrame()
end)()

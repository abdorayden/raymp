local api = require("rmp.rmp")

local Path = api.Path

local path = Path()

if raymp.nplayer == nil then
    raymp.nplayer = {}
end

local loaded = false
local songs =  {}

if raymp.nplayer.def_path ~= nil and raymp.nplayer.def_path ~= "defualt" then
    path:setPath(raymp.nplayer.def_path)
    loaded = true
elseif raymp.nplayer.def_path == "default" then
    path:setPath(path.joinPath(path:getHomePath(),"Music"))
    loaded = true
end


-- listDir() returns an array of { is_file = boolean, name = string } entries,
-- or nil plus an error message when the directory cannot be opened
if loaded then
    local entries, _ = path:listDir()
    if entries then
        for _, entry in ipairs(entries) do
            if entry.is_file then
                table.insert(songs, path.joinPath(path:getPath(),entry.name))
            end
        end
    end
end

-- builtin-now-playing-rmp
--
-- The audio panel of the default layout: it shows the current song, the
-- playback state, the playback mode, the progress/volume bars and (optionally)
-- the frequency spectrum. It is a window plugin, so the engine hands it the
-- inner rectangle of the window it is attached to:
--
--     raymp.engine.plugins = {
--         { themeWindowId = "main-window", isActivated = true,
--           names = { "builtin-now-playing-rmp" } },
--     }
--
-- The plugin owns its configuration: every value below is optional and read
-- from the engine, so it works even when the builtin configuration file sets
-- nothing at all. Missing values fall back to the defaults declared here.
--
--     raymp.engine.audio_panel = {
--         spectrum     = true,   -- frequency bars under the panels
--         spectrum_rows = 6,     -- height of the spectrum in rows
--         spectrum_gain = 2.5,   -- amplitude multiplier of the raw freq data
--         progress     = true,   -- progress bar with the elapsed/total time
--         volume       = true,   -- volume bar with the speed
--         details      = true,   -- track index / playlist size line
--         empty_text   = "no track loaded",  -- shown when the playlist is empty
--     }
--
-- Values are re-read every frame, so changing them at runtime (from another
-- plugin or through a config reload) takes effect immediately.

local DEFAULTS = {
    spectrum      = true,
    spectrum_rows = 6,
    spectrum_gain = 2.5,
    progress      = true,
    volume        = true,
    details       = true,
    empty_text    = "no track loaded",
}

-- Playback mode labels, indexed by RMP.PlaybackMode values
local MODE_LABELS = {
    [api.PlaybackMode.ONCE]          = "ONCE",
    [api.PlaybackMode.LOOP_SINGLE]   = "REPEAT ONE",
    [api.PlaybackMode.LOOP_PLAYLIST] = "REPEAT ALL",
    [api.PlaybackMode.SHUFFLE]       = "SHUFFLE",
}

-- Playback state labels, indexed by RMP.State values
local STATE_LABELS = {
    [api.State.STOPPED] = "■ STOPPED",
    [api.State.PLAYING] = "▶ PLAYING",
    [api.State.PAUSED]  = "‖ PAUSED",
    [api.State.LOADING] = "… LOADING",
    [api.State.ERROR]   = "✖ ERROR",
}

local BAR_LEVELS = { " ", "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

-- ── Engine data ──────────────────────────────────────────────────────────────
-- The listeners are registered once, when the module is required: registering
-- them inside the render callback would pile up a new listener every frame.

local sound    = nil
local freqData = nil

raymp:onSound(function(rmpSound)
    rmpSound:setPlaylist(songs)
    sound = rmpSound
end)

raymp:onDataFreq(function(data)
    freqData = data
end)

-- ── Helpers ──────────────────────────────────────────────────────────────────

--- Reads one optional plugin value from the engine configuration.
local function option(name)
    local conf = raymp.engine["builtin-now-playing-rmp"] or raymp.engine.audio_panel
    if type(conf) ~= "table" then return DEFAULTS[name] end

    local value = conf[name]
    if value == nil then return DEFAULTS[name] end

    if type(DEFAULTS[name]) == "number" and type(value) ~= "number" then
        return DEFAULTS[name]
    end
    if type(DEFAULTS[name]) == "boolean" then return value and true or false end
    if type(DEFAULTS[name]) == "string" and type(value) ~= "string" then
        return DEFAULTS[name]
    end

    return value
end

--- Number of terminal columns a utf8 string occupies.
local function display_width(text)
    local width = 0
    for _ in tostring(text):gmatch("[\1-\127\194-\244][\128-\191]*") do
        width = width + 1
    end
    return width
end

--- Repeats a character n times.
local function repeat_char(char, count)
    if count <= 0 then return "" end
    return string.rep(char, count)
end

--- Turns a track path into a readable title ("/music/song.mp3" → "song").
local function track_title(track)
    if type(track) ~= "string" or track == "" then return nil end
    local name = track:match("([^/\\]+)[/\\]*$") or track
    name = name:gsub("%.[^.]+$", "")
    if name == "" then return track end
    return name
end

--- Seconds → "m:ss" (or "h:mm:ss" for long tracks).
local function format_time(seconds)
    seconds = math.floor(math.max(0, tonumber(seconds) or 0))
    local minutes = math.floor(seconds / 60)
    if minutes >= 60 then
        return string.format("%d:%02d:%02d", math.floor(minutes / 60), minutes % 60, seconds % 60)
    end
    return string.format("%d:%02d", minutes, seconds % 60)
end

--- Theme aware colors with builtin fallbacks.
local function palette()
    local theme = raymp:getTheme()
    if type(theme) == "table" then
        return {
            bg       = api.colorFromHex(theme.BackGround, api.BG),
            border   = api.colorFromHex(theme.BorderColor, api.FG) or api.FGColors.Brights.White,
            primary  = api.colorFromHex(theme.PrimaryContent, api.FG) or api.FGColors.Brights.Green,
            secondary = api.colorFromHex(theme.SecondaryContent, api.FG) or api.FGColors.Brights.Cyan,
            accent   = api.colorFromHex(theme.AccentElements, api.FG) or api.FGColors.Brights.Red,
            highlight = api.colorFromHex(theme.Highlight, api.FG) or api.FGColors.Brights.Yellow,
            muted    = api.colorFromHex(theme.MutedElements, api.FG) or api.FGColors.NoBrights.White,
        }
    end
    return {
        bg        = api.BGColors.NoBrights.Black,
        border    = api.FGColors.Brights.White,
        primary   = api.FGColors.Brights.Green,
        secondary = api.FGColors.Brights.Cyan,
        accent    = api.FGColors.Brights.Red,
        highlight = api.FGColors.Brights.Yellow,
        muted     = api.FGColors.NoBrights.White,
    }
end

local function draw_centered(y, x, width, text, fg, bg, style)
    local offset = math.max(0, math.floor((width - display_width(text)) / 2))
    raymp:writeTextClipped(x + offset, y, text, width - offset, fg, bg, style)
end

local function draw_right(y, x, width, text, fg, bg, style)
    local offset = math.max(0, width - display_width(text))
    raymp:writeTextClipped(x + offset, y, text, width - offset, fg, bg, style)
end

--- Draws "[████░░░░]" and returns the number of columns it used.
local function draw_bar(y, x, width, ratio, colors)
    ratio = math.max(0, math.min(1, tonumber(ratio) or 0))
    local filled = math.floor(width * ratio)
    local bar    = repeat_char("█", filled) .. repeat_char("░", width - filled)

    raymp:writeTextClipped(x, y, "[" .. bar .. "]", width, colors.primary, colors.bg)
    return filled
end

--- Draws the frequency bars in the given rows (bottom aligned).
local function draw_spectrum(y, x, width, rows, gain, colors)
    if type(freqData) ~= "table" or #freqData == 0 or width < 24 or rows < 2 then return end

    local bins    = #freqData
    local columns = math.min(width, 64)

    for column = 1, columns do
        local bin    = math.floor(((column - 1) / columns) * bins) + 1
        local sample = tonumber(freqData[bin]) or 0
        local level  = math.max(0, math.min(1, sample * gain))
        local height = math.ceil(level * rows)

        for row = 1, rows do
            local cellLevel = rows - row + 1
            if cellLevel <= height then
                local fg = (height >= rows) and colors.accent or colors.secondary
                -- the topmost cell of a bar is partial, the ones below are solid
                local block = (cellLevel == height)
                    and BAR_LEVELS[math.max(1, math.ceil((cellLevel / rows) * #BAR_LEVELS))]
                    or BAR_LEVELS[#BAR_LEVELS]
                raymp:writeTextClipped(x + column - 1, y + row - 1, block, 1, fg, colors.bg)
            end
        end
    end
end

-- ── Plugin ───────────────────────────────────────────────────────────────────

return function(x, y, xx, yy)
    local w = xx - x + 1
    local h = yy - y + 1
    if w < 10 or h < 4 then return end

    local colors   = palette()
    local showSpectrum = option("spectrum")
    local showProgress = option("progress")
    local showVolume   = option("volume")
    local showDetails  = option("details")

    local title    = ""
    local state    = api.State.STOPPED
    local mode     = api.PlaybackMode.ONCE
    local index    = 0
    local total    = 0
    local position = 0
    local length   = 0
    local volume   = 0
    local speed    = 1

    if sound then
        local okState = pcall(function()
            state    = sound:getState() or api.State.STOPPED
            mode     = sound:getPlayBackMode() or api.PlaybackMode.ONCE
            position = sound:getPosition() or 0
            length   = sound:getLength() or 0
            volume   = sound:getVolume() or 0
            speed    = sound:getSpeed() or 1
            index    = sound:getCurrentIndex() or 0
            total    = #(sound:getPlaylist() or {})
            title    = track_title(sound:getCurrentTrack()) or ""
        end)
        if not okState then
            title = ""
        end
    end

    w = w - 2

    if title == "" then title = option("empty_text") end

    local row = y

    -- Header: playback state on the left, playback mode on the right
    raymp:writeTextClipped(x, row, STATE_LABELS[state] or STATE_LABELS[api.State.STOPPED],
        w, colors.highlight, colors.bg, api.TextStyle.Bold)
    draw_right(row, x, w, MODE_LABELS[mode] or MODE_LABELS[api.PlaybackMode.ONCE],
        colors.accent, colors.bg, api.TextStyle.Bold)
    row = row + 2

    -- Current song
    if row < y + h then
        draw_centered(row, x, w, title, colors.primary, colors.bg, api.TextStyle.Bold)
        row = row + 1
    end

    -- Track index / playlist size
    if showDetails and total > 0 and row < y + h then
        draw_centered(row, x, w, string.format("%d / %d", index, total), colors.muted, colors.bg)
        row = row + 1
    end

    row = row + 1

    -- Progress bar with the elapsed / total time
    local remaining = h - (row - y) - 1
    if showProgress and remaining >= 2 then
        local timeText = format_time(position) .. " / " .. format_time(length)
        local barWidth = w - display_width(timeText) - 3
        if barWidth >= 8 then
            local ratio = (length > 0) and (position / length) or 0
            draw_bar(row, x, barWidth, ratio, colors)
            draw_right(row, x, w, timeText, colors.muted, colors.bg)
            row = row + 2
        end
    end

    -- Volume bar and playback speed
    remaining = h - (row - y)
    if showVolume and remaining >= 2 then
        local volumeText = string.format("%3d%%", math.floor((volume or 0) * 100))
        local speedText  = string.format("%.2fx", tonumber(speed) or 1)
        local barWidth   = w - display_width(volumeText) - display_width(speedText) - 6
        if barWidth >= 6 then
            raymp:writeTextClipped(x, row, "VOL", 3, colors.muted, colors.bg)
            draw_bar(row, x + 4, barWidth, volume, colors)
            draw_right(row, x, w, volumeText .. " " .. speedText, colors.muted, colors.bg)
            row = row + 2
        end
    end

    -- Frequency spectrum, bottom aligned
    remaining = h - (row - y)
    if showSpectrum and remaining >= 2 then
        local spectrumRows = math.min(tonumber(option("spectrum_rows")) or 6, remaining)
        local gain         = tonumber(option("spectrum_gain")) or 2.5
        draw_spectrum(y + h - spectrumRows, x, w, spectrumRows, gain, colors)
    end
end

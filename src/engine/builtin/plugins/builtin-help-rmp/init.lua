local api = require("rmp.rmp")

-- Key to character mapping using a lookup table for efficiency
local keyToCharMap = {
    [api.KEY_RIGHT] = "<right>",
    [api.KEY_LEFT] = "<left>",
    [api.KEY_UP] = "<up>",
    [api.KEY_DOWN] = "<down>",
    [api.KEY_SPACE] = "<space>",
    [api.KEY_TAB] = "<tab>",
    [api.KEY_ALT_A] = "<A-a>",
    [api.KEY_ALT_B] = "<A-b>",
    [api.KEY_ALT_C] = "<A-c>",
    [api.KEY_ALT_D] = "<A-d>",
    [api.KEY_ALT_E] = "<A-e>",
    [api.KEY_ALT_F] = "<A-f>",
    [api.KEY_ALT_G] = "<A-g>",
    [api.KEY_ALT_H] = "<A-h>",
    [api.KEY_ALT_K] = "<A-k>",
    [api.KEY_ALT_L] = "<A-l>",
    [api.KEY_ALT_M] = "<A-m>",
    [api.KEY_ALT_N] = "<A-n>",
    [api.KEY_ALT_O] = "<A-o>",
    [api.KEY_ALT_P] = "<A-p>",
    [api.KEY_ALT_Q] = "<A-q>",
    [api.KEY_ALT_R] = "<A-r>",
    [api.KEY_ALT_S] = "<A-s>",
    [api.KEY_ALT_T] = "<A-t>",
    [api.KEY_ALT_U] = "<A-u>",
    [api.KEY_ALT_V] = "<A-v>",
    [api.KEY_ALT_W] = "<A-w>",
    [api.KEY_ALT_X] = "<A-x>",
    [api.KEY_ALT_Y] = "<A-y>",
    [api.KEY_ALT_Z] = "<A-z>",
    [api.KEY_CTRL_A] = "<C-a>",
    [api.KEY_CTRL_B] = "<C-b>",
    [api.KEY_CTRL_C] = "<C-c>",
    [api.KEY_CTRL_D] = "<C-d>",
    [api.KEY_CTRL_E] = "<C-e>",
    [api.KEY_CTRL_F] = "<C-f>",
    [api.KEY_CTRL_G] = "<C-g>",
    [api.KEY_CTRL_H] = "<C-h>",
    [api.KEY_CTRL_K] = "<C-k>",
    [api.KEY_CTRL_L] = "<C-l>",
    [api.KEY_CTRL_M] = "<C-m>",
    [api.KEY_CTRL_N] = "<C-n>",
    [api.KEY_CTRL_O] = "<C-o>",
    [api.KEY_CTRL_P] = "<C-p>",
    [api.KEY_CTRL_Q] = "<C-q>",
    [api.KEY_CTRL_R] = "<C-r>",
    [api.KEY_CTRL_S] = "<C-s>",
    [api.KEY_CTRL_T] = "<C-t>",
    [api.KEY_CTRL_U] = "<C-u>",
    [api.KEY_CTRL_V] = "<C-v>",
    [api.KEY_CTRL_W] = "<C-w>",
    [api.KEY_CTRL_X] = "<C-x>",
    [api.KEY_CTRL_Y] = "<C-y>",
    [api.KEY_CTRL_Z] = "<C-z>"
}

-- Pre-create a combined map that includes both the predefined mappings and fallback function
local function createKeyToCharFunction()
    local input = api.Input.new()
    return function(k)
        local mapped = keyToCharMap[k]
        if mapped then
            return mapped
        else
            return input:keyToChar(k)
        end
    end
end

local function engine_render_help(frame, w, h, settings, soundCfg)
    local ktc = createKeyToCharFunction()

    local helpText = {
        "RMP Help:",
        "-------------",
        "General Controls:",
        "  " .. ktc(settings.help_key) .. " : Show Help",
        "  " .. ktc(settings.exit) .. " : Quit Application",
        "",
        "Sound Controls:",
        "  " .. ktc(soundCfg.pause_sound) .. ": Pause",
        "  " .. ktc(soundCfg.resume_sound) .. ": Resume",
        "  " .. ktc(soundCfg.next_sound) .. ": Next Track",
        "  " .. ktc(soundCfg.prev_sound) .. ": Previous Track",
        "  " .. ktc(soundCfg.vol_up) .. ": Volume Up",
        "  " .. ktc(soundCfg.vol_down) .. ": Volume Down",
        "  " .. ktc(soundCfg.seek_left) .. ": Seek Backward",
        "  " .. ktc(soundCfg.seek_right) .. ": Seek Forward",
        "  " .. ktc(soundCfg.speed_up) .. ": Speed Up",
        "  " .. ktc(soundCfg.speed_down) .. ": Slow Down",
        "  " .. ktc(soundCfg.change_playback_mode) .. ": Change Playback Mode",
        "",
        "Plugin Controls:",
        "  [Plugin Switch Keys]: Switch Plugins in Windows (if configured)",
    }

    -- Calculate dimensions for the help box
    local maxTextWidth = 0
    for _, line in ipairs(helpText) do
        if #line > maxTextWidth then
            maxTextWidth = #line
        end
    end

    -- Add some padding
    local boxWidth = maxTextWidth + 4
    local boxHeight = #helpText + 4 -- +2 for top/bottom padding, +2 more for visual padding
    local boxX = math.floor((w - boxWidth) / 2)
    local boxY = math.floor((h - boxHeight) / 2)

    -- Create a box using the VirtualTerminal's drawBox method
    frame:drawBox(
        api.Text.new("Help", api.TextStyle.Bold, api.FGColors.Brights.White, api.BGColors.NoBrights.Black),
        boxX, boxY, boxWidth, boxHeight,
        api.BoxDrawing.LightBorder,
        api.FGColors.Brights.White,  -- border color
        api.BGColors.NoBrights.Black -- background color
    )

    -- Draw the help text inside the box
    for i, line in ipairs(helpText) do
        local textX = boxX + 2     -- Add padding from the left border
        local textY = boxY + 1 + i -- Add padding from the top border
        frame:writeText(textX, textY, line, api.FGColors.Brights.White, api.BGColors.NoBrights.Black)
    end
end
local settings = nil
local soundCfg = nil
local vt       = api.VirtualTerminal(1, 1)
return function()
    local h, w = api.Terminal:getSize()

    vt:onConfiguration(function(cfg)
        if cfg and type(cfg) == "table" and not cfg:isEmpty() then
            settings = cfg:get("settings")
            soundCfg = cfg:get("soundCfg")
        end
    end)
    if settings and soundCfg then
        vt:onFrame(function(frame)
            if frame then
                engine_render_help(frame, w, h, settings, soundCfg)
            end
        end)
    end
    return vt
end

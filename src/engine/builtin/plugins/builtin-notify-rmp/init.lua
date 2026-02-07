-- this plugin is a builtin plugin for notifications
--
-- set to default builtin plugin
-- also create a default builtin theme
-- and then create a profitional one
-- add to settings configurations notify property make it table so user can configure it

--- NOTE: to sent a signal to this plugin to show a notification
--- they must add Put event with data like { notification = { message = "your message", status = "info|error|warning|message", duration = 5 } }
--- example:
--- vt:addEventListener(api.EventType.TransformDataPut, function()
---     return {
---     notification = {
---         message = "This is a test notification",
---         status = "info",
---         duration = 5
---         }
---     }
--- end)

local api = require("rmp.rmp")
local util = require("rmp.util")

local VirtualTerminal = api.VirtualTerminal
local Queue = util.Queue
local colorFromHex = api.colorFromHex
local FG = api.FG
local BG = api.BG

local notificationQueue = Queue()

local active_notifications = {}

local DEFAULT_DURATION = 4
local MAX_WIDTH = 60
local tha_theme = nil

local function get_theme_colors()
    local bg = tha_theme and colorFromHex(tha_theme.BackGround, BG) or api.BGColors.NoBrights.Black
    local border = tha_theme and colorFromHex(tha_theme.BorderColor, FG) or api.FGColors.NoBrights.White
    local title_fg = tha_theme and colorFromHex(tha_theme.TitleText, FG) or api.FGColors.Brights.White
    local title_bg = tha_theme and colorFromHex(tha_theme.TitleBackGround, BG) or bg
    local primary = tha_theme and colorFromHex(tha_theme.PrimaryContent, FG) or api.FGColors.Brights.Cyan
    local secondary = tha_theme and colorFromHex(tha_theme.SecondaryContent, FG) or api.FGColors.Brights.Green
    local accent = tha_theme and colorFromHex(tha_theme.AccentElements, FG) or api.FGColors.Brights.Red
    local highlight = tha_theme and colorFromHex(tha_theme.Highlight, FG) or api.FGColors.Brights.Yellow
    return {
        bg = bg,
        border = border,
        title_fg = title_fg,
        title_bg = title_bg,
        primary = primary,
        secondary = secondary,
        accent = accent,
        highlight = highlight
    }
end

-- Utility Functions
local function add_notification(message, status, duration_sec)
    table.insert(active_notifications, {
        message = message or "",
        status = status or "message",
        time = os.time(),
        duration = duration_sec or DEFAULT_DURATION
    })
end

local function clip_text(text, max_width)
    local t = text or ""
    if #t <= max_width then
        return t
    end
    if max_width <= 3 then
        return t:sub(1, max_width)
    end
    return t:sub(1, max_width - 3) .. "..."
end

local function render_notifications(vt)
    local term_h, term_w = api.Terminal:getSize()
    local colors = get_theme_colors()
    local y_offset = 1
    for _, noti in ipairs(active_notifications) do
        local fg
        if noti.status == "error" then
            fg = colors.accent
        elseif noti.status == "warning" then
            fg = colors.highlight
        elseif noti.status == "info" then
            fg = colors.primary
        else
            fg = colors.secondary
        end
        local message = clip_text(noti.message, math.max(4, math.min(MAX_WIDTH, term_w - 6)))
        local box_width = math.min(term_w - 2, math.max(12, #message + 4))
        local box_height = 3
        local box_x = math.max(1, term_w - box_width)
        local box_y = y_offset
        if box_y + box_height - 1 > term_h then
            break
        end

        local title = "[" .. string.upper(noti.status) .. "]"
        vt:drawBox(title, box_x, box_y, box_width, box_height, api.BoxDrawing.RoundedCorners, fg, colors.bg)
        vt:writeText(box_x + 2, box_y + 1, message, fg, colors.bg)
        y_offset = y_offset + box_height + 1
    end
end

local function prune_old_notifications()
    local now = os.time()
    local kept = {}
    for _, noti in ipairs(active_notifications) do
        if noti.duration and (now - noti.time) <= noti.duration then
            table.insert(kept, noti)
        end
    end
    active_notifications = kept
end

-- NOTE: The following lines are for testing purposes. You can remove them in production.
if false then
    notificationQueue:push({ message = "Welcome to RMP!", status = "info", duration = 5 })
    notificationQueue:push({
        message = "test error",
        status =
        "error",
        duration = 10
    })
    notificationQueue:push({ message = "Welcome to RMP!", status = "warning", duration = 15 })
    notificationQueue:push({ message = "test error", status = "message", duration = 15 })
end

return function()
    local vt = VirtualTerminal()

    vt:addEventListener(api.EventType.TransformDataGet, function(data)
        if data and data.theme then
            tha_theme = data.theme
        end
    end)

    --- TODO: add event handling so plugins can sent notifications data so this plugin must handle the rendering
    --- the plugins must sent data like message, status (info, error, warning) and duration
    vt:addEventListener(api.EventType.TransformDataGet, function(data)
        if data and data.notification then
            notificationQueue:push(data.notification)
        end
    end)

    while not notificationQueue:isEmpty() do
        local noti = notificationQueue:pop()
        add_notification(noti.message, noti.status, noti.duration)
    end
    prune_old_notifications()
    render_notifications(vt)
    --
    --- TODO: create a beautiful popup with diffrent status and add animations to it like noice in nvim

    return vt
end

local api = require("rmp.rmp")
local OOP = require("rmp.oop")
local Util = require("rmp.util")

local colorFromHex = api.colorFromHex

-- TODO: later
local components = require("rmp.components")

-- how about css styles on TUI applications huh ...
--
-- rmp classes b detais
-- components baynin swale7 khfaf

--- @module 'rmp.effects'
local Effects = {}

local Easing = OOP.class("Easing")
do
    function Easing.linear(t) return t end

    function Easing.easeInQuad(t) return t * t end

    function Easing.easeOutQuad(t) return t * (2 - t) end

    function Easing.easeInOutQuad(t)
        return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
    end

    function Easing.easeInCubic(t) return t * t * t end

    function Easing.easeOutCubic(t)
        --- @diagnostic disable-next-line
        return math.pow(t - 1, 3) + 1
    end

    function Easing.easeInOutCubic(t)
        return t < 0.5 and 4 * t * t * t or (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
    end

    function Easing.easeOutCirc(t)
        --- @diagnostic disable-next-line
        return math.sqrt(1 - math.pow(t - 1, 2))
    end

    function Easing.easeOutQuint(t)
        --- @diagnostic disable-next-line
        return 1 - math.pow(1 - t, 5)
    end
end


-- Helper function to extract RGB from color value
local function extractRGB(color)
    if not color then return 0, 0, 0 end
    -- Handle if color is already a table with r,g,b
    if type(color) == "table" then
        return color.r or color[1] or 0,
            color.g or color[2] or 0,
            color.b or color[3] or 0
    end
    -- Handle if color is a hex string
    if type(color) == "string" then
        local hex = color:match("#?(%x+)")
        if hex and #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            return r or 0, g or 0, b or 0
        end
    end
    -- Handle if color is a number (packed RGB)
    if type(color) == "number" then
        local r = math.floor(color / 65536) % 256
        local g = math.floor(color / 256) % 256
        local b = color % 256
        return r, g, b
    end
    -- Handle if color is userdata or has a special format
    -- Try to convert to string and parse hex if possible
    local success, result = pcall(tostring, color)
    if success and result then
        local hex = result:match("#?(%x+)")
        if hex and #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            return r or 0, g or 0, b or 0
        end
    end
    return 0, 0, 0
end

-- Helper function to create hex string from RGB
local function createHexFromRGB(r, g, b)
    return string.format("#%02x%02x%02x",
        math.floor(r) % 256,
        math.floor(g) % 256,
        math.floor(b) % 256)
end

-- Helper function to normalize color input to hex string
--- comment
--- @param color any
--- @return any
local function normalizeColorToHex(color)
    if type(color) == "string" and color:match("^#%x%x%x%x%x%x$") then
        return color
    end
    local r, g, b = Effects.extractRGB(color)
    return createHexFromRGB(r, g, b)
end

-- TODO: Parse a simple CSS like that applied without calling the methods directly
Effects.BaseEffect = OOP.class("BaseEffect")
do
    function Effects.BaseEffect:constructor(vterm_obj, method_name, params_config)
        self.vterm = vterm_obj
        self.method_name = method_name
        self.forrendering = vterm_obj[method_name]
        self.params_config = params_config
        self.original_params = {}
        self.current_params = {}

        -- deep copy params
        for i, v in ipairs(params_config.values) do
            self.original_params[i] = v
            self.current_params[i] = v
        end

        -- track which params can be animated
        self.animatable_indices = params_config.animatable or {}
        self.color_index = params_config.color_index
        self.color_mode = params_config.color_as and api.FG or api.BG

        -- animation state
        self.animation_state = {
            progress = 0,
            frame_count = 0,
            is_complete = false,
            fade_alpha = 1,

            start_values = {},
            target_values = {},

            start_r = 0,
            start_g = 0,
            start_b = 0,
            target_r = 0,
            target_g = 0,
            target_b = 0,
            current_r = 0,
            current_g = 0,
            current_b = 0,
            current_color_hex = "#000000",
        }

        -- initialize color tracking - try to normalize to hex string
        if self.color_index then
            local color_param = self.current_params[self.color_index]
            local init_color_hex = "#000000"

            if type(color_param) == "string" then
                init_color_hex = normalizecolortohex(color_param)
            elseif type(color_param) == "number" then
                init_color_hex = normalizecolortohex(color_param)
            end

            local r, g, b = extractRGB(init_color_hex)

            self.animation_state.start_r = r
            self.animation_state.start_g = g
            self.animation_state.start_b = b
            self.animation_state.target_r = r
            self.animation_state.target_g = g
            self.animation_state.target_b = b
            self.animation_state.current_r = r
            self.animation_state.current_g = g
            self.animation_state.current_b = b
            self.animation_state.current_color_hex = init_color_hex
            self.animation_state.color = init_color_hex
        end

        self.animation_state.x = self.original_params[2] or 1
        self.animation_state.y = self.original_params[3] or 1
        self.animation_state.width = self.original_params[4] or 10
        self.animation_state.height = self.original_params[5] or 5

        -- animation queue
        self.effects_queue = {}
        self.queue_head = 1
        self.queue_tail = 0
        self.current_effect = nil
    end

    --- Animate a parameter to a target value
    function Effects.BaseEffect:animateTo(param_index, target_value)
        local is_animatable = false
        for _, idx in ipairs(self.animatable_indices) do
            if idx == param_index then
                is_animatable = true
                break
            end
        end
        if not is_animatable then
            error("Parameter at index " .. param_index .. " is not animatable")
        end
        -- Only animate numeric values
        local start_val = self.current_params[param_index]
        if type(start_val) ~= "number" then
            error("Parameter at index " .. param_index .. " is not numeric")
        end
        table.insert(self.effects_queue, {
            type = "animateTo",
            param_index = param_index,
            start_value = start_val,
            target_value = target_value,
            duration = 60,
            easing = Easing.linear,
            delay = 0
        })
        return self
    end

    --- Animate position (x, y) to target coordinates
    function Effects.BaseEffect:moveTo(target_x, target_y)
        local x_index, y_index
        for _, idx in ipairs(self.animatable_indices) do
            if idx == 2 then x_index = idx end
            if idx == 3 then y_index = idx end
        end
        if not x_index or not y_index then
            error("Position (x, y) is not animatable for this effect")
        end
        local start_x = self.current_params[2]
        local start_y = self.current_params[3]
        table.insert(self.effects_queue, {
            type = "moveTo",
            start_x = start_x,
            start_y = start_y,
            target_x = target_x,
            target_y = target_y,
            duration = 60,
            easing = Easing.linear,
            delay = 0
        })
        return self
    end

    --- Transition color
    function Effects.BaseEffect:colorTo(target_color)
        if not self.color_index then
            error("This effect does not have a color parameter")
        end
        local target_hex = normalizeColorToHex(target_color)
        local sr, sg, sb = extractRGB(self.animation_state.current_color_hex)
        local tr, tg, tb = extractRGB(target_hex)
        table.insert(self.effects_queue, {
            type = "colorTo",
            target_color = target_hex,
            start_r = sr,
            start_g = sg,
            start_b = sb,
            target_r = tr,
            target_g = tg,
            target_b = tb,
            duration = 60,
            easing = Easing.linear,
            delay = 0
        })
        return self
    end

    --- Intro animation (grow from top-left)
    function Effects.BaseEffect:intro()
        table.insert(self.effects_queue, {
            type = "intro",
            duration = 30,
            easing = Easing.easeOutCubic,
            delay = 0
        })
        return self
    end

    --- Slide in from left
    function Effects.BaseEffect:leftToRight()
        table.insert(self.effects_queue, {
            type = "leftToRight",
            duration = 30,
            easing = Easing.easeOutQuad,
            delay = 0
        })
        return self
    end

    --- Slide in from right
    function Effects.BaseEffect:rightToLeft()
        table.insert(self.effects_queue, {
            type = "rightToLeft",
            duration = 30,
            easing = Easing.easeOutQuad,
            delay = 0
        })
        return self
    end

    --- Slide in from top
    function Effects.BaseEffect:topToBottom()
        table.insert(self.effects_queue, {
            type = "topToBottom",
            duration = 30,
            easing = Easing.easeOutQuad,
            delay = 0
        })
        return self
    end

    --- Slide in from bottom
    function Effects.BaseEffect:bottomToTop()
        table.insert(self.effects_queue, {
            type = "bottomToTop",
            duration = 30,
            easing = Easing.easeOutQuad,
            delay = 0
        })
        return self
    end

    --- Fade in animation
    function Effects.BaseEffect:fadeIn()
        table.insert(self.effects_queue, {
            type = "fadeIn",
            duration = 30,
            easing = Easing.easeOutQuad,
            delay = 0
        })
        return self
    end

    --- Fade out animation
    function Effects.BaseEffect:fadeOut()
        table.insert(self.effects_queue, {
            type = "fadeOut",
            duration = 30,
            easing = Easing.easeInQuad,
            delay = 0
        })
        return self
    end

    --- Scale up animation
    function Effects.BaseEffect:scaleUp()
        table.insert(self.effects_queue, {
            type = "scaleUp",
            duration = 30,
            easing = Easing.easeOutCubic,
            delay = 0
        })
        return self
    end

    --- Scale down animation
    function Effects.BaseEffect:scaleDown()
        table.insert(self.effects_queue, {
            type = "scaleDown",
            duration = 30,
            easing = Easing.easeInCubic,
            delay = 0
        })
        return self
    end

    --- Slide in from direction
    function Effects.BaseEffect:slideIn(direction)
        direction = direction or "left"
        table.insert(self.effects_queue, {
            type = "slideIn",
            direction = direction,
            duration = 30,
            easing = Easing.easeOutCubic,
            delay = 0
        })
        return self
    end

    --- Slide out to direction
    function Effects.BaseEffect:slideOut(direction)
        direction = direction or "right"
        table.insert(self.effects_queue, {
            type = "slideOut",
            direction = direction,
            duration = 30,
            easing = Easing.easeInCubic,
            delay = 0
        })
        return self
    end

    --- Add a delay before next animation
    function Effects.BaseEffect:delay(frames)
        table.insert(self.effects_queue, {
            type = "delay",
            duration = frames,
            delay = 0
        })
        return self
    end

    --- Mark animation for looping
    function Effects.BaseEffect:loop()
        table.insert(self.effects_queue, {
            type = "loop",
            delay = 0
        })
        return self
    end

    --- Set animation duration
    function Effects.BaseEffect:duration(frames)
        if #self.effects_queue > 0 then
            self.effects_queue[#self.effects_queue].duration = frames
        end
        return self
    end

    --- Set animation delay
    function Effects.BaseEffect:delay(frames)
        if #self.effects_queue > 0 then
            self.effects_queue[#self.effects_queue].delay = frames
        end
        return self
    end

    --- Set easing function
    function Effects.BaseEffect:easing(easing_func)
        if #self.effects_queue > 0 then
            self.effects_queue[#self.effects_queue].easing = easing_func
        end
        return self
    end

    --- Update animation state
    function Effects.BaseEffect:update()
        if not self.current_effect and #self.effects_queue > 0 then
            self.current_effect = table.remove(self.effects_queue, 1)
            self:initializeEffect(self.current_effect)
        end
        local effect = self.current_effect
        if not effect then return end
        if effect.type == "delay" then
            self.animation_state.frame_count = self.animation_state.frame_count + 1
            if self.animation_state.frame_count >= effect.duration then
                self.animation_state.is_complete = true
            end
            return
        end
        if effect.type == "loop" then
            self.animation_state.is_complete = false
            return
        end
        self.animation_state.frame_count = self.animation_state.frame_count + 1
        local raw_progress = math.min(self.animation_state.frame_count / effect.duration, 1)
        local easing_func = effect.easing or Easing.linear
        self.animation_state.progress = easing_func(raw_progress)
        if effect.type == "fadeIn" then
            self.animation_state.fade_alpha = self.animation_state.progress
        elseif effect.type == "fadeOut" then
            self.animation_state.fade_alpha = 1 - self.animation_state.progress
        end
        self.animation_state.x = self.animation_state.start_x +
            (self.animation_state.target_x - self.animation_state.start_x) * self.animation_state.progress
        self.animation_state.y = self.animation_state.start_y +
            (self.animation_state.target_y - self.animation_state.start_y) * self.animation_state.progress
        self.animation_state.width = self.animation_state.start_width +
            (self.animation_state.target_width - self.animation_state.start_width) * self.animation_state.progress
        self.animation_state.height = self.animation_state.start_height +
            (self.animation_state.target_height - self.animation_state.start_height) * self.animation_state.progress
        if effect.type == "colorTo" then
            self.animation_state.current_r = self.animation_state.start_r +
                (self.animation_state.target_r - self.animation_state.start_r) * self.animation_state.progress
            self.animation_state.current_g = self.animation_state.start_g +
                (self.animation_state.target_g - self.animation_state.start_g) * self.animation_state.progress
            self.animation_state.current_b = self.animation_state.start_b +
                (self.animation_state.target_b - self.animation_state.start_b) * self.animation_state.progress
            self.animation_state.current_color_hex = createHexFromRGB(
                self.animation_state.current_r,
                self.animation_state.current_g,
                self.animation_state.current_b
            )
        end
        if raw_progress >= 1 then
            self.animation_state.is_complete = true
            if effect.type == "colorTo" then
                self.animation_state.current_color_hex = effect.target_color
            elseif effect.type == "fadeIn" then
                self.animation_state.fade_alpha = 1
            elseif effect.type == "fadeOut" then
                self.animation_state.fade_alpha = 0
            end
            self.current_effect = nil
        end
    end

    function Effects.BaseEffect:initializeEffect(effect)
        self.animation_state.progress = 0
        self.animation_state.frame_count = 0
        self.animation_state.is_complete = false
        self.animation_state.start_x = self.animation_state.x or self.current_params[2] or 0
        self.animation_state.start_y = self.animation_state.y or self.current_params[3] or 0
        self.animation_state.start_width = self.animation_state.width or self.current_params[4] or 10
        self.animation_state.start_height = self.animation_state.height or self.current_params[5] or 5
        self.animation_state.target_x = self.animation_state.start_x
        self.animation_state.target_y = self.animation_state.start_y
        self.animation_state.target_width = self.animation_state.start_width
        self.animation_state.target_height = self.animation_state.start_height
        if effect.type == "colorTo" then
            local sr, sg, sb = extractRGB(self.animation_state.current_color_hex)
            local tr, tg, tb = extractRGB(effect.target_color)
            self.animation_state.start_r, self.animation_state.start_g, self.animation_state.start_b = sr, sg, sb
            self.animation_state.target_r, self.animation_state.target_g, self.animation_state.target_b = tr, tg, tb
        end
        local orig_x = self.original_params[2] or 1
        local orig_y = self.original_params[3] or 1
        local orig_w = self.original_params[4] or 10
        local orig_h = self.original_params[5] or 5
        if effect.type == "leftToRight" then
            self.animation_state.start_width = 0
            self.animation_state.target_width = orig_w
        elseif effect.type == "rightToLeft" then
            self.animation_state.start_width = 0
            self.animation_state.start_x = orig_x + orig_w
            self.animation_state.target_width = orig_w
            self.animation_state.target_x = orig_x
        elseif effect.type == "topToBottom" then
            self.animation_state.start_height = 0
            self.animation_state.target_height = orig_h
        elseif effect.type == "bottomToTop" then
            self.animation_state.start_height = 0
            self.animation_state.start_y = orig_y + orig_h
            self.animation_state.target_height = orig_h
            self.animation_state.target_y = orig_y
        elseif effect.type == "intro" then
            self.animation_state.start_width = 0
            self.animation_state.start_height = 0
            self.animation_state.target_width = orig_w
            self.animation_state.target_height = orig_h
        elseif effect.type == "fadeIn" then
            self.animation_state.start_width = orig_w
            self.animation_state.start_height = orig_h
            self.animation_state.target_width = orig_w
            self.animation_state.target_height = orig_h
            self.animation_state.fade_alpha = 0
        elseif effect.type == "fadeOut" then
            self.animation_state.start_width = orig_w
            self.animation_state.start_height = orig_h
            self.animation_state.target_width = orig_w
            self.animation_state.target_height = orig_h
            self.animation_state.fade_alpha = 1
        elseif effect.type == "scaleUp" then
            self.animation_state.start_width = 0
            self.animation_state.start_height = 0
            self.animation_state.target_width = orig_w
            self.animation_state.target_height = orig_h
        elseif effect.type == "scaleDown" then
            self.animation_state.target_width = 0
            self.animation_state.target_height = 0
        elseif effect.type == "moveTo" then
            self.animation_state.target_x = effect.target_x
            self.animation_state.target_y = effect.target_y
        elseif effect.type == "slideIn" then
            local h, w = 24, 80
            if self.vterm then
                h, w = self.vterm:getSize()
            end
            if effect.direction == "left" then
                self.animation_state.start_x = -orig_w
            elseif effect.direction == "right" then
                self.animation_state.start_x = w
            elseif effect.direction == "top" then
                self.animation_state.start_y = -orig_h
            elseif effect.direction == "bottom" then
                self.animation_state.start_y = h
            end
            self.animation_state.target_x = orig_x
            self.animation_state.target_y = orig_y
        elseif effect.type == "slideOut" then
            local h, w = 24, 80
            if self.vterm then
                h, w = self.vterm:getSize()
            end
            self.animation_state.start_x = self.animation_state.x or orig_x
            self.animation_state.start_y = self.animation_state.y or orig_y
            if effect.direction == "left" then
                self.animation_state.target_x = -orig_w
            elseif effect.direction == "right" then
                self.animation_state.target_x = w + 1
            elseif effect.direction == "top" then
                self.animation_state.target_y = -orig_h
            elseif effect.direction == "bottom" then
                self.animation_state.target_y = h
            else
                self.animation_state.target_x = w
            end
        end
    end

    --- Render the VirtualTerminal with current animated parameters
    function Effects.BaseEffect:render()
        self:update()
        local x = math.floor(self.animation_state.x or self.current_params[2] or 1)
        local y = math.floor(self.animation_state.y or self.current_params[3] or 1)
        local w = math.floor(self.animation_state.width or self.current_params[4] or 10)
        local h = math.floor(self.animation_state.height or self.current_params[5] or 5)
        local color = self.animation_state.current_color_hex
        if self.animation_state.fade_alpha and self.animation_state.fade_alpha < 1 then
            local r, g, b = extractRGB(color)
            color = createHexFromRGB(r * self.animation_state.fade_alpha, g * self.animation_state.fade_alpha,
                b * self.animation_state.fade_alpha)
        end
        if self.forRendering and w > 0 and h > 0 then
            self.current_params[2] = x
            self.current_params[3] = y
            self.current_params[4] = w
            self.current_params[5] = h
            if self.color_index then
                self.current_params[self.color_index] = colorFromHex(color, self.color_mode)
            end
            return self.forRendering(self.vterm, table.unpack(self.current_params))
        end
        return nil
    end

    --- Reset animation
    function Effects.BaseEffect:reset()
        self.effects_queue = {}
        self.current_effect = nil
        self.animation_state.frame_count = 0
        self.animation_state.is_complete = false
        self.animation_state.fade_alpha = 1
        for i, v in ipairs(self.original_params) do
            self.current_params[i] = v
        end
        self.animation_state.x = self.original_params[2] or 1
        self.animation_state.y = self.original_params[3] or 1
        self.animation_state.width = self.original_params[4] or 10
        self.animation_state.height = self.original_params[5] or 5
        if self.color_index then
            local color_param = self.original_params[self.color_index]
            local init_color_hex = "#000000"
            if type(color_param) == "string" then
                init_color_hex = normalizeColorToHex(color_param)
            elseif type(color_param) == "number" then
                init_color_hex = normalizeColorToHex(color_param)
            end
            local r, g, b = extractRGB(init_color_hex)
            self.animation_state.start_r = r
            self.animation_state.start_g = g
            self.animation_state.start_b = b
            self.animation_state.target_r = r
            self.animation_state.target_g = g
            self.animation_state.target_b = b
            self.animation_state.current_r = r
            self.animation_state.current_g = g
            self.animation_state.current_b = b
            self.animation_state.current_color_hex = init_color_hex
            self.animation_state.color = init_color_hex
        end
        return self
    end

    --- Example :
    --- I- initialize the VirtualTerminal and attach it to the effect class
    -- local vt_box1 = VirtualTerminal(30, 10)
    -- local effect_box1 = BaseEffect(vt_box1, "drawBox", {
    --     values = { "Box 1"
    --              , 1
    --              , 1
    --              , 28
    --              , 8
    --              , BoxDrawing.LightBorder
    --              , colorFromHex("#ff0000", FG), colorFromHex("#000000", BG) },
    --     animatable = { 6, 7, 8 }, -- fg, bg colors can animate
    --     color_index = 6
    -- })
    --
    -- II- apply the effects
    --
    -- effect_box1
    --     :colorTo("#ff00ff")
    --     :duration(60)
    --     :easing(VTGenericEffect.Easing.easeInOutCubic)
    --     :colorTo("#00ffff")
    --     :duration(60)
    --     :easing(VTGenericEffect.Easing.easeInOutCubic)
    --     :colorTo("#ff0000")
    --     :duration(60)
    --     :easing(VTGenericEffect.Easing.easeInOutCubic)
    --
    -- III- update it each frame
    -- effect_box1:update()
    --
    -- IIII- in case u want to restart the effect all over again
    -- if effect_box1.current_effect == nil and #effect_box1.effects_queue == 0 then
    --     effect_box1:reset()
    --     setup1()
    -- end
    --
    -- IIIII- get the animated value and attach it to the draw methods of VirtualTerminal
    --
    -- local c1 = effect_box1.animation_state.current_color_hex
    -- vt_box1:drawBox("1: Red→Cyan→Red", 1, 1, 28, 8, BoxDrawing.LightBorder,
    --     colorFromHex(c1, FG), colorFromHex("#000000", BG))
    -- vt_box1:writeText(3, 4, "Color: " .. c1, colorFromHex(c1, FG))
    -- canvas:merge(vt_box1, false, 2, 4)
    --
end

Effects.DrawEffect = OOP.class("DrawEffect", Effects.BaseEffect)
do
    function Effects.DrawEffect:constructor(vterm, effect_config)
        self:super(vterm, effect_config)
    end

    -- TODO: add some functionality for Draw class
end

Effects.Easing = Easing
Effects.extractRGB = extractRGB
Effects.createHexFromRGB = createHexFromRGB
Effects.normalizeColorToHex = normalizeColorToHex

return Effects

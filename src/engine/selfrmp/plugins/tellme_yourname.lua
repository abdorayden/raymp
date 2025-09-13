

local api = require("rmp.rmp")
local OOP = require("rmp.oop")

local Input = api.Input
local VirtualTerminal = api.VirtualTerminal
local Terminal = api.Terminal
local label = "What is your name: "


-- Improved Input Class for RMP Framework
-- Easy-to-use text input with advanced features

local InputField = OOP.class("InputField")
do
	function InputField:constructor(config)
		-- Simple configuration with sensible defaults
		config = config or {}

		self.prompt = config.prompt or ""
		self.x = config.x or 1
		self.y = config.y or 1
		self.width = config.width or 30
		self.placeholder = config.placeholder or "Type here..."
		self.default = config.default or ""
		self.mask = config.mask  -- for password fields (e.g., "*")
		self.maxLength = config.maxLength or (self.width - #self.prompt - 4)
		self.validator = config.validator  -- function to validate input
		self.onSubmit = config.onSubmit  -- callback when submitted
		self.onChange = config.onChange  -- callback on each change

		-- Colors
		self.colors = {
			prompt = config.promptColor or api.FGColors.Brights.Cyan,
			text = config.textColor or api.FGColors.Brights.White,
			placeholder = config.placeholderColor or api.FGColors.NoBrights.White,
			border = config.borderColor or api.FGColors.NoBrights.White,
			error = api.FGColors.Brights.Red,
			bg = config.bgColor or api.BGColors.NoBrights.Black
		}

		-- Internal state
		self.text = self.default
		self.cursorPos = #self.text + 1
		self.scrollOffset = 0
		self.active = false
		self.error = nil
		self.history = {}  -- for undo/redo
		self.historyIndex = 0

		self.vterm = api.VirtualTerminal.new()
		self:setupEventHandlers()
	end

	function InputField:setupEventHandlers()
		-- Character input
		for i = api.KEY_A, api.KEY_Z do
			self.vterm:addEventListener(i, function() self:handleCharInput(i) end)
		end
		for i = api.KEY_SHIFT_A, api.KEY_SHIFT_Z do
			self.vterm:addEventListener(i, function() self:handleCharInput(i) end)
		end
		for i = api.KEY_0, api.KEY_9 do
			self.vterm:addEventListener(i, function() self:handleCharInput(i) end)
		end

		-- Special characters
		local specialKeys = {
			api.KEY_SPACE, api.KEY_DOT, api.KEY_MINUS, api.KEY_COMMA,
			api.KEY_SEMICOL, api.KEY_SLASH, api.KEY_AT
		}
		for _, key in ipairs(specialKeys) do
			self.vterm:addEventListener(key, function() self:handleCharInput(key) end)
		end

		-- Control keys
		self.vterm:addEventListener(api.KEY_ENTER, function() self:submit() end)
		self.vterm:addEventListener(api.KEY_ESCAPE, function() self:cancel() end)
		self.vterm:addEventListener(api.KEY_BACKSPACE, function() self:backspace() end)
		self.vterm:addEventListener(api.KEY_DELETE, function() self:delete() end)
		self.vterm:addEventListener(api.KEY_LEFT, function() self:moveCursor(-1) end)
		self.vterm:addEventListener(api.KEY_RIGHT, function() self:moveCursor(1) end)
		self.vterm:addEventListener(api.KEY_HOME, function() self:home() end)
		self.vterm:addEventListener(api.KEY_END, function() self:endKey() end)
		self.vterm:addEventListener(api.KEY_CTRL_Z, function() self:undo() end)
		self.vterm:addEventListener(api.KEY_CTRL_Y, function() self:redo() end)
		self.vterm:addEventListener(api.KEY_CTRL_A, function() self:selectAll() end)
	end

	function InputField:handleCharInput(key)
		if not self.active then return end

		local char = self:keyToChar(key)
		if char and #self.text < self.maxLength then
			self:saveHistory()
			self.text = self.text:sub(1, self.cursorPos - 1) .. char .. self.text:sub(self.cursorPos)
			self.cursorPos = self.cursorPos + 1
			self:adjustScroll()

			if self.onChange then
				self.onChange(self.text)
			end

			self:render()
		end
	end

	function InputField:keyToChar(key)
		local keyMap = {
			-- Lowercase letters
			[api.KEY_A] = "a", [api.KEY_B] = "b", [api.KEY_C] = "c", [api.KEY_D] = "d",
			[api.KEY_E] = "e", [api.KEY_F] = "f", [api.KEY_G] = "g", [api.KEY_H] = "h",
			[api.KEY_I] = "i", [api.KEY_J] = "j", [api.KEY_K] = "k", [api.KEY_L] = "l",
			[api.KEY_M] = "m", [api.KEY_N] = "n", [api.KEY_O] = "o", [api.KEY_P] = "p",
			[api.KEY_Q] = "q", [api.KEY_R] = "r", [api.KEY_S] = "s", [api.KEY_T] = "t",
			[api.KEY_U] = "u", [api.KEY_V] = "v", [api.KEY_W] = "w", [api.KEY_X] = "x",
			[api.KEY_Y] = "y", [api.KEY_Z] = "z",
			-- Uppercase letters
			[api.KEY_SHIFT_A] = "A", [api.KEY_SHIFT_B] = "B", [api.KEY_SHIFT_C] = "C",
			[api.KEY_SHIFT_D] = "D", [api.KEY_SHIFT_E] = "E", [api.KEY_SHIFT_F] = "F",
			[api.KEY_SHIFT_G] = "G", [api.KEY_SHIFT_H] = "H", [api.KEY_SHIFT_I] = "I",
			[api.KEY_SHIFT_J] = "J", [api.KEY_SHIFT_K] = "K", [api.KEY_SHIFT_L] = "L",
			[api.KEY_SHIFT_M] = "M", [api.KEY_SHIFT_N] = "N", [api.KEY_SHIFT_O] = "O",
			[api.KEY_SHIFT_P] = "P", [api.KEY_SHIFT_Q] = "Q", [api.KEY_SHIFT_R] = "R",
			[api.KEY_SHIFT_S] = "S", [api.KEY_SHIFT_T] = "T", [api.KEY_SHIFT_U] = "U",
			[api.KEY_SHIFT_V] = "V", [api.KEY_SHIFT_W] = "W", [api.KEY_SHIFT_X] = "X",
			[api.KEY_SHIFT_Y] = "Y", [api.KEY_SHIFT_Z] = "Z",
			-- Numbers
			[api.KEY_0] = "0", [api.KEY_1] = "1", [api.KEY_2] = "2", [api.KEY_3] = "3",
			[api.KEY_4] = "4", [api.KEY_5] = "5", [api.KEY_6] = "6", [api.KEY_7] = "7",
			[api.KEY_8] = "8", [api.KEY_9] = "9",
			-- Special characters
			[api.KEY_SPACE] = " ", [api.KEY_DOT] = ".", [api.KEY_MINUS] = "-",
			[api.KEY_COMMA] = ",", [api.KEY_SEMICOL] = ";", [api.KEY_SLASH] = "/",
			[api.KEY_AT] = "@"
		}
		return keyMap[key]
	end

	function InputField:backspace()
		if not self.active or self.cursorPos <= 1 then return end

		self:saveHistory()
		self.text = self.text:sub(1, self.cursorPos - 2) .. self.text:sub(self.cursorPos)
		self.cursorPos = self.cursorPos - 1
		self:adjustScroll()
		if self.onChange then self.onChange(self.text) end
		self:render()
	end

	function InputField:delete()
		if not self.active or self.cursorPos > #self.text then return end

		self:saveHistory()
		self.text = self.text:sub(1, self.cursorPos - 1) .. self.text:sub(self.cursorPos + 1)
		if self.onChange then self.onChange(self.text) end
		self:render()
	end

	function InputField:moveCursor(delta)
		if not self.active then return end

		self.cursorPos = math.max(1, math.min(#self.text + 1, self.cursorPos + delta))
		self:adjustScroll()
		self:render()
	end

	function InputField:home()
		if not self.active then return end
		self.cursorPos = 1
		self.scrollOffset = 0
		self:render()
	end

	function InputField:endKey()
		if not self.active then return end
		self.cursorPos = #self.text + 1
		self:adjustScroll()
		self:render()
	end

	function InputField:saveHistory()
		-- Save current state for undo
		table.insert(self.history, self.historyIndex + 1, self.text)
		self.historyIndex = self.historyIndex + 1
		-- Remove any redo states
		for i = self.historyIndex + 1, #self.history do
			self.history[i] = nil
		end
	end

	function InputField:undo()
		if not self.active or self.historyIndex <= 0 then return end
		self.historyIndex = self.historyIndex - 1
		self.text = self.history[self.historyIndex] or ""
		self.cursorPos = #self.text + 1
		self:render()
	end

	function InputField:redo()
		if not self.active or self.historyIndex >= #self.history then return end
		self.historyIndex = self.historyIndex + 1
		self.text = self.history[self.historyIndex]
		self.cursorPos = #self.text + 1
		self:render()
	end

	function InputField:selectAll()
		-- This would need selection support - simplified for now
		self.cursorPos = #self.text + 1
		self:render()
	end

	function InputField:adjustScroll()
		local visibleWidth = self.width - #self.prompt - 4

		if self.cursorPos - self.scrollOffset > visibleWidth then
			self.scrollOffset = self.cursorPos - visibleWidth
		elseif self.cursorPos <= self.scrollOffset then
			self.scrollOffset = math.max(0, self.cursorPos - 1)
		end
	end

	function InputField:submit()
		if not self.active then return end

		-- Validate input
		if self.validator then
			local isValid, errorMsg = self.validator(self.text)
			if not isValid then
				self.error = errorMsg or "Invalid input"
				self:render()
				return
			end
		end

		self.active = false
		self.error = nil

		if self.onSubmit then
			self.onSubmit(self.text)
		end

		self:render()
	end

	function InputField:cancel()
		if not self.active then return end

		self.active = false
		self.text = self.default
		self.cursorPos = #self.text + 1
		self.scrollOffset = 0
		self.error = nil
		self:render()
	end

	function InputField:activate()
		self.active = true
		self.cursorPos = #self.text + 1
		self:adjustScroll()
		self:render()
	end

	function InputField:deactivate()
		self.active = false
		self:render()
	end

	function InputField:render()
		self.vterm:clear()

		-- Draw border
		local borderStyle = self.active and api.BoxDrawing.HeavyBorder or api.BoxDrawing.LightBorder
		local borderColor = self.error and self.colors.error or self.colors.border

		self.vterm:drawBox(
		api.Text.new(self.prompt, nil, self.colors.prompt),
		self.x, self.y, self.width, 3,
		borderStyle, borderColor, self.colors.bg
		)

		-- Calculate visible text
		local displayText = self.text
		if self.mask then
			displayText = string.rep(self.mask, #displayText)
		end

		local visibleWidth = self.width - 4
		local visibleText = displayText:sub(self.scrollOffset + 1, self.scrollOffset + visibleWidth)

		-- Show placeholder if empty and not active
		if #self.text == 0 and not self.active then
			visibleText = self.placeholder:sub(1, visibleWidth)
			self.vterm:writeText(
			self.x + 2, self.y + 1,
			visibleText,
			self.colors.placeholder, self.colors.bg
			)
		else
			self.vterm:writeText(
			self.x + 2, self.y + 1,
			visibleText,
			self.colors.text, self.colors.bg
			)
		end

		-- Draw cursor if active
		if self.active then
			local cursorScreenPos = self.cursorPos - self.scrollOffset
			if cursorScreenPos > 0 and cursorScreenPos <= visibleWidth then
				self.vterm:writeText(
				self.x + 1 + cursorScreenPos, self.y + 1,
				"│",
				api.FGColors.Brights.White, self.colors.bg,
				api.TextStyle.SlowBlink
				)
			end
		end

		-- Show error message if any
		if self.error then
			self.vterm:writeText(
			self.x + 2, self.y + 3,
			self.error:sub(1, self.width - 4),
			self.colors.error
			)
		end
	end

	function InputField:getText()
		return self.text
	end

	function InputField:setText(text)
		self.text = text or ""
		self.cursorPos = #self.text + 1
		self:adjustScroll()
		self:render()
	end

	function InputField:clear()
		self.text = ""
		self.cursorPos = 1
		self.scrollOffset = 0
		self.error = nil
		self.history = {}
		self.historyIndex = 0
		self:render()
	end

	function InputField:getVirtualTerminal()
		return self.vterm
	end
end


-- Main function that creates the interface
return function(x, y, xx, yy)
	local vterm = VirtualTerminal.new()

	-- Create a static input instance (persistent between frames)
	if not _G.rmp_input_instance then
		_G.rmp_input_instance = Input.new(label, x + 1, yy - 2, xx - x - 2, "", api.KEY_ESCAPE)
		_G.rmp_input_instance:start()
	end

	local input = _G.rmp_input_instance

	-- Merge the input's virtual terminal
	vterm:merge(input:getVterm())

	-- Display the result if text was submitted
	if input:wasSubmitted() and input:getText() ~= "" then
		vterm:writeText(x + 1, y + 1, "You entered: " .. input:getText(), api.FGColors.Brights.White, api.BGColors.NoBrights.Blue)
	end

	-- Add instructions
	vterm:writeText(x + 1, y + 3, "Press ENTER to submit, ESC to cancel", api.FGColors.NoBrights.Yellow)

	return vterm
end

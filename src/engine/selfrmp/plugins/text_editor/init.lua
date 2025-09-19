-- Text Editor Plugin for RMP Framework (Fixed Event Handling)
-- Properly separates Insert mode and Command mode input handling

local api = require("rmp.rmp")

-- Editor state
local editor_state = {
	lines = {""},
	cursor_x = 1,
	cursor_y = 1,
	scroll_x = 0,
	scroll_y = 0,
	filename = "",
	modified = false,
	mode = "normal", -- "normal", "insert", or "command"
	status_message = "",
	status_time = 0
}

-- Colors
local colors = {
	normal = api.FGColors.NoBrights.White,
	cursor = api.FGColors.Brights.Yellow,
	line_numbers = api.FGColors.NoBrights.White,
	status = api.FGColors.Brights.Cyan,
	status_bg = api.BGColors.NoBrights.Blue,
	modified = api.FGColors.Brights.Red,
	command_bg = api.BGColors.NoBrights.Green
}

-- Create command input using SimpleInput
local command_input = api.SimpleInput.new({
	label = ":",
	placeholder = "Enter command (save, open filename, quit)",
	width = 40,
	maxLength = 100,
	fg_normal = api.FGColors.Brights.White,
	bg_normal = api.BGColors.NoBrights.Green,
	fg_active = api.FGColors.Brights.Yellow,
	bg_active = api.BGColors.NoBrights.Green,
	validator = function(text)
		if text == "" then
			return false, "Command cannot be empty"
		end
		local cmd = text:lower()
		if cmd == "save" or cmd == "quit" or cmd == "q" or cmd:match("^open%s+.+") then
			return true
		end
		return false, "Unknown command. Try: save, open <filename>, quit"
	end
})

-- Helper functions
local function set_status(message)
	editor_state.status_message = message
	editor_state.status_time = os.time()
end

local function clear_status_if_old()
	if os.time() - editor_state.status_time > 3 then
		editor_state.status_message = ""
	end
end

local function clamp_cursor()
	if editor_state.cursor_y < 1 then
		editor_state.cursor_y = 1
	elseif editor_state.cursor_y > #editor_state.lines then
		editor_state.cursor_y = #editor_state.lines
	end

	local line = editor_state.lines[editor_state.cursor_y] or ""
	local max_x = editor_state.mode == "insert" and #line + 1 or math.max(1, #line)

	if editor_state.cursor_x < 1 then
		editor_state.cursor_x = 1
	elseif editor_state.cursor_x > max_x then
		editor_state.cursor_x = max_x
	end
end

local function adjust_scroll(view_width, view_height)
	if editor_state.cursor_y <= editor_state.scroll_y then
		editor_state.scroll_y = math.max(0, editor_state.cursor_y - 1)
	elseif editor_state.cursor_y > editor_state.scroll_y + view_height then
		editor_state.scroll_y = editor_state.cursor_y - view_height
	end

	if editor_state.cursor_x <= editor_state.scroll_x then
		editor_state.scroll_x = math.max(0, editor_state.cursor_x - 1)
	elseif editor_state.cursor_x > editor_state.scroll_x + view_width then
		editor_state.scroll_x = editor_state.cursor_x - view_width
	end
end

local function insert_char(char)
	local line = editor_state.lines[editor_state.cursor_y]
	editor_state.lines[editor_state.cursor_y] = 
	line:sub(1, editor_state.cursor_x - 1) .. char .. line:sub(editor_state.cursor_x)
	editor_state.cursor_x = editor_state.cursor_x + 1
	editor_state.modified = true
end

local function delete_char()
	local line = editor_state.lines[editor_state.cursor_y]
	if editor_state.cursor_x > 1 then
		editor_state.lines[editor_state.cursor_y] = 
		line:sub(1, editor_state.cursor_x - 2) .. line:sub(editor_state.cursor_x)
		editor_state.cursor_x = editor_state.cursor_x - 1
		editor_state.modified = true
	elseif editor_state.cursor_y > 1 then
		local prev_line = editor_state.lines[editor_state.cursor_y - 1]
		editor_state.cursor_x = #prev_line + 1
		editor_state.lines[editor_state.cursor_y - 1] = prev_line .. line
		table.remove(editor_state.lines, editor_state.cursor_y)
		editor_state.cursor_y = editor_state.cursor_y - 1
		editor_state.modified = true
	end
end

local function insert_newline()
	local line = editor_state.lines[editor_state.cursor_y]
	local before_cursor = line:sub(1, editor_state.cursor_x - 1)
	local after_cursor = line:sub(editor_state.cursor_x)

	editor_state.lines[editor_state.cursor_y] = before_cursor
	table.insert(editor_state.lines, editor_state.cursor_y + 1, after_cursor)

	editor_state.cursor_y = editor_state.cursor_y + 1
	editor_state.cursor_x = 1
	editor_state.modified = true
end

local function load_file(filename)
	local file = io.open(filename, "r")
	if file then
		editor_state.lines = {}
		for line in file:lines() do
			table.insert(editor_state.lines, line)
		end
		file:close()

		if #editor_state.lines == 0 then
			editor_state.lines = {""}
		end

		editor_state.filename = filename
		editor_state.modified = false
		editor_state.cursor_x = 1
		editor_state.cursor_y = 1
		editor_state.scroll_x = 0
		editor_state.scroll_y = 0
		set_status("Loaded: " .. filename)
		return true
	else
		set_status("Could not open: " .. filename)
		return false
	end
end

local function save_file(filename)
	filename = filename or editor_state.filename
	if filename == "" then
		set_status("No filename specified")
		return false
	end

	local file = io.open(filename, "w")
	if file then
		for i, line in ipairs(editor_state.lines) do
			file:write(line)
			if i < #editor_state.lines then
				file:write("\n")
			end
		end
		file:close()

		editor_state.filename = filename
		editor_state.modified = false
		set_status("Saved: " .. filename)
		return true
	else
		set_status("Could not save: " .. filename)
		return false
	end
end

local function execute_command(cmd_text)
	local cmd = cmd_text:lower():gsub("^%s*(.-)%s*$", "%1")

	if cmd == "save" then
		if editor_state.filename == "" then
			set_status("No filename set. Use 'open <filename>' first")
		else
			save_file()
		end
	elseif cmd == "quit" or cmd == "q" then
		if editor_state.modified then
			set_status("File modified. Save first or use 'quit!' to force quit")
		else
			set_status("Goodbye!")
		end
	elseif cmd:match("^open%s+(.+)") then
		local filename = cmd:match("^open%s+(.+)") -- can't read uper case input
		load_file(filename)
	else
		set_status("Unknown command: " .. cmd)
	end
end

local function key_to_char(key)
	local keyMap = {
		[api.KEY_A] = "a", [api.KEY_B] = "b", [api.KEY_C] = "c", [api.KEY_D] = "d",
		[api.KEY_E] = "e", [api.KEY_F] = "f", [api.KEY_G] = "g", [api.KEY_H] = "h",
		[api.KEY_I] = "i", [api.KEY_J] = "j", [api.KEY_K] = "k", [api.KEY_L] = "l",
		[api.KEY_M] = "m", [api.KEY_N] = "n", [api.KEY_O] = "o", [api.KEY_P] = "p",
		[api.KEY_Q] = "q", [api.KEY_R] = "r", [api.KEY_S] = "s", [api.KEY_T] = "t",
		[api.KEY_U] = "u", [api.KEY_V] = "v", [api.KEY_W] = "w", [api.KEY_X] = "x",
		[api.KEY_Y] = "y", [api.KEY_Z] = "z",
		[api.KEY_0] = "0", [api.KEY_1] = "1", [api.KEY_2] = "2", [api.KEY_3] = "3",
		[api.KEY_4] = "4", [api.KEY_5] = "5", [api.KEY_6] = "6", [api.KEY_7] = "7",
		[api.KEY_8] = "8", [api.KEY_9] = "9",
		[api.KEY_SPACE] = " ", [api.KEY_DOT] = ".", [api.KEY_MINUS] = "-",
		[api.KEY_PLUS] = "+", [api.KEY_STAR] = "*", [api.KEY_SLASH] = "/",
		[api.KEY_BACK_SLASH] = "\\", [api.KEY_SEMICOL] = ";", [api.KEY_DBL_QUOTE] = '"',
		[api.KEY_SINGLE_QOUTE] = "'", [api.KEY_OPEN_BRAKET] = "[", [api.KEY_CLOSED_BRAKET] = "]",
		[api.KEY_OPCURB] = "{", [api.KEY_CLCURB] = "}", [api.KEY_BAR] = "|",
		[api.KEY_GT] = ">", [api.KEY_LT] = "<", [api.KEY_HASHTAG] = "#",
		[api.KEY_AT] = "@", [api.KEY_PERSANT] = "%", [api.KEY_DOLAR] = "$" -- no support for ^ and !
	}

	local shiftMap = {
		[api.KEY_SHIFT_A] = "A", [api.KEY_SHIFT_B] = "B", [api.KEY_SHIFT_C] = "C",
		[api.KEY_SHIFT_D] = "D", [api.KEY_SHIFT_E] = "E", [api.KEY_SHIFT_F] = "F",
		[api.KEY_SHIFT_G] = "G", [api.KEY_SHIFT_H] = "H", [api.KEY_SHIFT_I] = "I",
		[api.KEY_SHIFT_J] = "J", [api.KEY_SHIFT_K] = "K", [api.KEY_SHIFT_L] = "L",
		[api.KEY_SHIFT_M] = "M", [api.KEY_SHIFT_N] = "N", [api.KEY_SHIFT_O] = "O",
		[api.KEY_SHIFT_P] = "P", [api.KEY_SHIFT_Q] = "Q", [api.KEY_SHIFT_R] = "R",
		[api.KEY_SHIFT_S] = "S", [api.KEY_SHIFT_T] = "T", [api.KEY_SHIFT_U] = "U",
		[api.KEY_SHIFT_V] = "V", [api.KEY_SHIFT_W] = "W", [api.KEY_SHIFT_X] = "X",
		[api.KEY_SHIFT_Y] = "Y", [api.KEY_SHIFT_Z] = "Z"
	}

	return shiftMap[key] or keyMap[key]
end

-- FIXME: (!) didn't works
-- Main plugin function
return function(x, y, xx, yy)
	local vterm = api.VirtualTerminal.new()

	local view_width = xx - x - 5
	local view_height = yy - y - 3

	clear_status_if_old()

	-- Position command input at bottom
	command_input.x = x
	command_input.y = yy - 1
	command_input.width = xx - x - 2

	-- CRITICAL: Event handling separation based on mode
	if editor_state.mode == "command" then
		-- Command mode: Only handle SimpleInput and ESC
		command_input:render(vterm)

		vterm:addEventListener(api.EventType.Keyboard, function(key)
			if key == api.KEY_ESCAPE then
				command_input:blur()
				editor_state.mode = "normal"
				set_status("Command cancelled")
			end
		end)

		-- Check command completion
		if not command_input:isActive() and command_input:getValue() ~= "" then
			local cmd = command_input:getValue()
			execute_command(cmd)
			command_input:clear()
			editor_state.mode = "normal"
		elseif not command_input:isActive() then
			editor_state.mode = "normal"
		end

	elseif editor_state.mode == "insert" then
		-- Insert mode: Handle text input with Input events
		vterm:addEventListener(api.EventType.Focuse, function(key)
			if key == api.KEY_ESCAPE then
				editor_state.mode = "normal"
				set_status("")
			elseif key == api.KEY_ENTER then
				insert_newline()
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_BACKSPACE then
				delete_char()
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_LEFT then
				editor_state.cursor_x = editor_state.cursor_x - 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_RIGHT then
				editor_state.cursor_x = editor_state.cursor_x + 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_UP then
				editor_state.cursor_y = editor_state.cursor_y - 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_DOWN then
				editor_state.cursor_y = editor_state.cursor_y + 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			else
				local char = key_to_char(key)
				if char then
					insert_char(char)
					clamp_cursor()
					adjust_scroll(view_width, view_height)
				end
			end
		end)

	else
		-- Normal mode: Navigation with Keyboard events
		vterm:addEventListener(api.EventType.Keyboard, function(key)
			if key == api.KEY_CTRL_K then
				editor_state.mode = "insert"
				set_status("-- INSERT --")
			elseif key == api.KEY_SEMICOL then -- : key for command mode
				editor_state.mode = "command"
				command_input:focus()
				set_status("-- COMMAND --")
			elseif key == api.KEY_H or key == api.KEY_LEFT then
				editor_state.cursor_x = editor_state.cursor_x - 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_L or key == api.KEY_RIGHT then
				editor_state.cursor_x = editor_state.cursor_x + 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_J or key == api.KEY_DOWN then
				editor_state.cursor_y = editor_state.cursor_y + 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_K or key == api.KEY_UP then
				editor_state.cursor_y = editor_state.cursor_y - 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_G then
				editor_state.cursor_y = 1
				editor_state.cursor_x = 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			elseif key == api.KEY_SHIFT_G then
				editor_state.cursor_y = #editor_state.lines
				editor_state.cursor_x = #editor_state.lines[editor_state.cursor_y] or 1
				clamp_cursor()
				adjust_scroll(view_width, view_height)
			end
		end)
	end

	-- Render line numbers
	for i = 1, view_height do
		local line_num = editor_state.scroll_y + i
		if line_num <= #editor_state.lines then
			local num_str = string.format("%3d ", line_num)
			local color = line_num == editor_state.cursor_y and colors.cursor or colors.line_numbers
			vterm:writeText(x, y + i - 1, num_str, color, api.BGColors.NoBrights.Black)
		else
			vterm:writeText(x, y + i - 1, "    ", colors.line_numbers, api.BGColors.NoBrights.Black)
		end
	end

	-- Render text content
	for i = 1, view_height do
		local line_idx = editor_state.scroll_y + i
		if line_idx <= #editor_state.lines then
			local line = editor_state.lines[line_idx]
			local visible_part = line:sub(editor_state.scroll_x + 1, editor_state.scroll_x + view_width)

			visible_part = visible_part .. string.rep(" ", math.max(0, view_width - #visible_part))

			vterm:writeText(x + 4, y + i - 1, visible_part, colors.normal, api.BGColors.NoBrights.Black)

			-- Render cursor if on this line and not in command mode
			if editor_state.mode ~= "command" and line_idx == editor_state.cursor_y and 
				editor_state.cursor_x > editor_state.scroll_x and 
				editor_state.cursor_x <= editor_state.scroll_x + view_width then
				local cursor_screen_x = x + 4 + (editor_state.cursor_x - editor_state.scroll_x - 1)
				local cursor_char = editor_state.mode == "insert" and "|" or "_"
				vterm:writeText(cursor_screen_x, y + i - 1, cursor_char, colors.cursor, api.BGColors.NoBrights.Black)
			end
		else
			vterm:writeText(x + 4, y + i - 1, string.rep(" ", view_width), colors.normal, api.BGColors.NoBrights.Black)
		end
	end

	-- Render status line
	local status_y = yy - 2
	local mode_indicator = editor_state.mode == "insert" and "INSERT" or 
	editor_state.mode == "command" and "COMMAND" or "NORMAL"
	local modified_indicator = editor_state.modified and "[+] " or ""
	local filename_display = editor_state.filename ~= "" and editor_state.filename or "[No Name]"
	local position_info = string.format("L%d,C%d", editor_state.cursor_y, editor_state.cursor_x)

	local left_status = string.format("%s %s%s", mode_indicator, modified_indicator, filename_display)
	local right_status = position_info

	vterm:writeText(x, status_y, string.rep(" ", xx - x), colors.status, colors.status_bg)
	vterm:writeText(x, status_y, left_status, colors.status, colors.status_bg)
	vterm:writeText(xx - #right_status, status_y, right_status, colors.status, colors.status_bg)

	if editor_state.status_message ~= "" then
		local msg_x = x + math.floor((xx - x - #editor_state.status_message) / 2)
		vterm:writeText(msg_x, status_y, editor_state.status_message, colors.status, colors.status_bg)
	end

	-- Show help on first run
	if editor_state.cursor_y == 1 and editor_state.cursor_x == 1 and not editor_state.modified and 
		editor_state.filename == "" and editor_state.mode == "normal" then
		local help_lines = {
			"RMP Text Editor (Fixed Event Handling)",
			"",
			"Normal Mode: (Keyboard Events)",
			"  CTRL-K - Insert mode    h/j/k/l - Move cursor",
			"  g - Go to top      G - Go to bottom",  
			"  : - Command mode",
			"",
			"Insert Mode: (Input Events)",
			"  ESC - Normal mode  Arrow keys - Move",
			"  Enter - New line   Backspace - Delete",
			"",
			"Command Mode: (SimpleInput)",
			"  :save - Save file    :open <file> - Open file",
			"  :quit - Quit editor  ESC - Cancel",
			"",
			"Press 'i' to start editing or ':' for commands!"
		}

		for i, help_line in ipairs(help_lines) do
			if i <= view_height then
				vterm:writeText(x + 4, y + i - 1, help_line, colors.normal, api.BGColors.NoBrights.Black)
			end
		end
	end

	return vterm
end













----	this file is part of RMP Software
----	
---- Text Editor Plugin for RMP Software
---- A simple but functional text editor with basic editing features
---- FIXME: Add file dialog, search functionality, copy/paste, etc. use SimpleInput class here
---- Author: RayDen
---- Version: 1.0
---- License: check LICENSE file in repository

--local api = require("rmp.rmp")

--local editor_state = {
--	lines = {""},
--	cursor_x = 1,
--	cursor_y = 1,
--	scroll_x = 0,
--	scroll_y = 0,
--	filename = "",
--	modified = false,
--	mode = "normal", -- "normal" or "insert"
--	status_message = "",
--	status_time = 0,
--	search_query = "",
--	search_active = false
--}


--local colors = {
--	normal = api.FGColors.NoBrights.White,
--	cursor = api.FGColors.Brights.Yellow,
--	line_numbers = api.FGColors.NoBrights.White,
--	status = api.FGColors.Brights.Cyan,
--	status_bg = api.BGColors.NoBrights.Blue,
--	modified = api.FGColors.Brights.Red,
--	search_bg = api.BGColors.NoBrights.Yellow
--}


--local function set_status(message)
--	editor_state.status_message = message
--	editor_state.status_time = os.time()
--end

--local function clear_status_if_old()
--	if os.time() - editor_state.status_time > 3 then
--		editor_state.status_message = ""
--	end
--end

--local function clamp_cursor()

--	if editor_state.cursor_y < 1 then
--		editor_state.cursor_y = 1
--	elseif editor_state.cursor_y > #editor_state.lines then
--		editor_state.cursor_y = #editor_state.lines
--	end

--	local line = editor_state.lines[editor_state.cursor_y] or ""
--	local max_x = editor_state.mode == "insert" and #line + 1 or math.max(1, #line)

--	if editor_state.cursor_x < 1 then
--		editor_state.cursor_x = 1
--	elseif editor_state.cursor_x > max_x then
--		editor_state.cursor_x = max_x
--	end
--end

--local function adjust_scroll(view_width, view_height)

--	if editor_state.cursor_y <= editor_state.scroll_y then
--		editor_state.scroll_y = math.max(0, editor_state.cursor_y - 1)
--	elseif editor_state.cursor_y > editor_state.scroll_y + view_height then
--		editor_state.scroll_y = editor_state.cursor_y - view_height
--	end


--	if editor_state.cursor_x <= editor_state.scroll_x then
--		editor_state.scroll_x = math.max(0, editor_state.cursor_x - 1)
--	elseif editor_state.cursor_x > editor_state.scroll_x + view_width then
--		editor_state.scroll_x = editor_state.cursor_x - view_width
--	end
--end

--local function insert_char(char)
--	local line = editor_state.lines[editor_state.cursor_y]
--	editor_state.lines[editor_state.cursor_y] = 
--	line:sub(1, editor_state.cursor_x - 1) .. char .. line:sub(editor_state.cursor_x)
--	editor_state.cursor_x = editor_state.cursor_x + 1
--	editor_state.modified = true
--end

--local function delete_char()
--	local line = editor_state.lines[editor_state.cursor_y]
--	if editor_state.cursor_x > 1 then
--		editor_state.lines[editor_state.cursor_y] = 
--		line:sub(1, editor_state.cursor_x - 2) .. line:sub(editor_state.cursor_x)
--		editor_state.cursor_x = editor_state.cursor_x - 1
--		editor_state.modified = true
--	elseif editor_state.cursor_y > 1 then

--		local prev_line = editor_state.lines[editor_state.cursor_y - 1]
--		editor_state.cursor_x = #prev_line + 1
--		editor_state.lines[editor_state.cursor_y - 1] = prev_line .. line
--		table.remove(editor_state.lines, editor_state.cursor_y)
--		editor_state.cursor_y = editor_state.cursor_y - 1
--		editor_state.modified = true
--	end
--end

--local function insert_newline()
--	local line = editor_state.lines[editor_state.cursor_y]
--	local before_cursor = line:sub(1, editor_state.cursor_x - 1)
--	local after_cursor = line:sub(editor_state.cursor_x)

--	editor_state.lines[editor_state.cursor_y] = before_cursor
--	table.insert(editor_state.lines, editor_state.cursor_y + 1, after_cursor)

--	editor_state.cursor_y = editor_state.cursor_y + 1
--	editor_state.cursor_x = 1
--	editor_state.modified = true
--end

--local function load_file(filename)
--	local file = io.open(filename, "r")
--	if file then
--		editor_state.lines = {}
--		for line in file:lines() do
--			table.insert(editor_state.lines, line)
--		end
--		file:close()

--		if #editor_state.lines == 0 then
--			editor_state.lines = {""}
--		end

--		editor_state.filename = filename
--		editor_state.modified = false
--		editor_state.cursor_x = 1
--		editor_state.cursor_y = 1
--		editor_state.scroll_x = 0
--		editor_state.scroll_y = 0
--		set_status("Loaded: " .. filename)
--		return true
--	else
--		set_status("Could not open: " .. filename)
--		return false
--	end
--end

--local function save_file(filename)
--	filename = filename or editor_state.filename
--	if filename == "" then
--		set_status("No filename specified")
--		return false
--	end

--	local file = io.open(filename, "w")
--	if file then
--		for i, line in ipairs(editor_state.lines) do
--			file:write(line)
--			if i < #editor_state.lines then
--				file:write("\n")
--			end
--		end
--		file:close()

--		editor_state.filename = filename
--		editor_state.modified = false
--		set_status("Saved: " .. filename)
--		return true
--	else
--		set_status("Could not save: " .. filename)
--		return false
--	end
--end

--local function key_to_char(key)
--	local keyMap = {
--		[api.KEY_A] = "a", [api.KEY_B] = "b", [api.KEY_C] = "c", [api.KEY_D] = "d",
--		[api.KEY_E] = "e", [api.KEY_F] = "f", [api.KEY_G] = "g", [api.KEY_H] = "h",
--		[api.KEY_I] = "i", [api.KEY_J] = "j", [api.KEY_K] = "k", [api.KEY_L] = "l",
--		[api.KEY_M] = "m", [api.KEY_N] = "n", [api.KEY_O] = "o", [api.KEY_P] = "p",
--		[api.KEY_Q] = "q", [api.KEY_R] = "r", [api.KEY_S] = "s", [api.KEY_T] = "t",
--		[api.KEY_U] = "u", [api.KEY_V] = "v", [api.KEY_W] = "w", [api.KEY_X] = "x",
--		[api.KEY_Y] = "y", [api.KEY_Z] = "z",
--		[api.KEY_0] = "0", [api.KEY_1] = "1", [api.KEY_2] = "2", [api.KEY_3] = "3",
--		[api.KEY_4] = "4", [api.KEY_5] = "5", [api.KEY_6] = "6", [api.KEY_7] = "7",
--		[api.KEY_8] = "8", [api.KEY_9] = "9",
--		[api.KEY_SPACE] = " ", [api.KEY_DOT] = ".", [api.KEY_MINUS] = "-",
--		[api.KEY_PLUS] = "+", [api.KEY_STAR] = "*", [api.KEY_SLASH] = "/",
--		[api.KEY_BACK_SLASH] = "\\", [api.KEY_SEMICOL] = ";", [api.KEY_DBL_QUOTE] = '"',
--		[api.KEY_SINGLE_QOUTE] = "'", [api.KEY_OPEN_BRAKET] = "[", [api.KEY_CLOSED_BRAKET] = "]",
--		[api.KEY_OPCURB] = "{", [api.KEY_CLCURB] = "}", [api.KEY_BAR] = "|",
--		[api.KEY_GT] = ">", [api.KEY_LT] = "<", [api.KEY_HASHTAG] = "#",
--		[api.KEY_AT] = "@", [api.KEY_PERSANT] = "%", [api.KEY_DOLAR] = "$"
--	}

--	local shiftMap = {
--		[api.KEY_SHIFT_A] = "A", [api.KEY_SHIFT_B] = "B", [api.KEY_SHIFT_C] = "C",
--		[api.KEY_SHIFT_D] = "D", [api.KEY_SHIFT_E] = "E", [api.KEY_SHIFT_F] = "F",
--		[api.KEY_SHIFT_G] = "G", [api.KEY_SHIFT_H] = "H", [api.KEY_SHIFT_I] = "I",
--		[api.KEY_SHIFT_J] = "J", [api.KEY_SHIFT_K] = "K", [api.KEY_SHIFT_L] = "L",
--		[api.KEY_SHIFT_M] = "M", [api.KEY_SHIFT_N] = "N", [api.KEY_SHIFT_O] = "O",
--		[api.KEY_SHIFT_P] = "P", [api.KEY_SHIFT_Q] = "Q", [api.KEY_SHIFT_R] = "R",
--		[api.KEY_SHIFT_S] = "S", [api.KEY_SHIFT_T] = "T", [api.KEY_SHIFT_U] = "U",
--		[api.KEY_SHIFT_V] = "V", [api.KEY_SHIFT_W] = "W", [api.KEY_SHIFT_X] = "X",
--		[api.KEY_SHIFT_Y] = "Y", [api.KEY_SHIFT_Z] = "Z"
--	}

--	return shiftMap[key] or keyMap[key]
--end


--return function(x, y, xx, yy)
--	local vterm = api.VirtualTerminal.new()


--	local view_width = xx - x - 5  
--	local view_height = yy - y - 2 

--	clear_status_if_old()

--	vterm:addEventListener(api.EventType.Keyboard, function(key)
--		if editor_state.mode == "normal" then
--			if key == api.KEY_I then
--				editor_state.mode = "insert"
--				set_status("-- INSERT --")
--			elseif key == api.KEY_H or key == api.KEY_LEFT then
--				editor_state.cursor_x = editor_state.cursor_x - 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_L or key == api.KEY_RIGHT then
--				editor_state.cursor_x = editor_state.cursor_x + 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_J or key == api.KEY_DOWN then
--				editor_state.cursor_y = editor_state.cursor_y + 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_K or key == api.KEY_UP then
--				editor_state.cursor_y = editor_state.cursor_y - 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_G then
--				editor_state.cursor_y = 1
--				editor_state.cursor_x = 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_SHIFT_G then
--				editor_state.cursor_y = #editor_state.lines
--				editor_state.cursor_x = #editor_state.lines[editor_state.cursor_y] or 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_CTRL_S then
--				save_file()
--			elseif key == api.KEY_CTRL_O then

--				load_file("test.txt")
--			end
--		elseif editor_state.mode == "insert" then

--			if key == api.KEY_ESCAPE then
--				editor_state.mode = "normal"
--				set_status("")
--			elseif key == api.KEY_ENTER then
--				insert_newline()
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_BACKSPACE then
--				delete_char()
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_LEFT then
--				editor_state.cursor_x = editor_state.cursor_x - 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_RIGHT then
--				editor_state.cursor_x = editor_state.cursor_x + 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_UP then
--				editor_state.cursor_y = editor_state.cursor_y - 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			elseif key == api.KEY_DOWN then
--				editor_state.cursor_y = editor_state.cursor_y + 1
--				clamp_cursor()
--				adjust_scroll(view_width, view_height)
--			else
--				local char = key_to_char(key)
--				if char then
--					insert_char(char)
--					clamp_cursor()
--					adjust_scroll(view_width, view_height)
--				end
--			end
--		end
--	end)


--	for i = 1, view_height do
--		local line_num = editor_state.scroll_y + i
--		if line_num <= #editor_state.lines then
--			local num_str = string.format("%3d ", line_num)
--			local color = line_num == editor_state.cursor_y and colors.cursor or colors.line_numbers
--			vterm:writeText(x, y + i - 1, num_str, color, api.BGColors.NoBrights.Black)
--		else
--			vterm:writeText(x, y + i - 1, "    ", colors.line_numbers, api.BGColors.NoBrights.Black)
--		end
--	end


--	for i = 1, view_height do
--		local line_idx = editor_state.scroll_y + i
--		if line_idx <= #editor_state.lines then
--			local line = editor_state.lines[line_idx]
--			local visible_part = line:sub(editor_state.scroll_x + 1, editor_state.scroll_x + view_width)


--			visible_part = visible_part .. string.rep(" ", math.max(0, view_width - #visible_part))

--			vterm:writeText(x + 4, y + i - 1, visible_part, colors.normal, api.BGColors.NoBrights.Black)


--			if line_idx == editor_state.cursor_y and 
--				editor_state.cursor_x > editor_state.scroll_x and 
--				editor_state.cursor_x <= editor_state.scroll_x + view_width then
--				local cursor_screen_x = x + 4 + (editor_state.cursor_x - editor_state.scroll_x - 1)
--				local cursor_char = editor_state.mode == "insert" and "|" or "_"
--				vterm:writeText(cursor_screen_x, y + i - 1, cursor_char, colors.cursor, api.BGColors.NoBrights.Black)
--			end
--		else

--			vterm:writeText(x + 4, y + i - 1, string.rep(" ", view_width), colors.normal, api.BGColors.NoBrights.Black)
--		end
--	end


--	local status_y = yy - 1
--	local mode_indicator = editor_state.mode == "insert" and "INSERT" or "NORMAL"
--	local modified_indicator = editor_state.modified and "[+] " or ""
--	local filename_display = editor_state.filename ~= "" and editor_state.filename or "[No Name]"
--	local position_info = string.format("L%d,C%d", editor_state.cursor_y, editor_state.cursor_x)

--	local left_status = string.format("%s %s%s", mode_indicator, modified_indicator, filename_display)
--	local right_status = position_info


--	vterm:writeText(x, status_y, string.rep(" ", xx - x), colors.status, colors.status_bg)


--	vterm:writeText(x, status_y, left_status, colors.status, colors.status_bg)
--	vterm:writeText(xx - #right_status, status_y, right_status, colors.status, colors.status_bg)


--	if editor_state.status_message ~= "" then
--		local msg_x = x + math.floor((xx - x - #editor_state.status_message) / 2)
--		vterm:writeText(msg_x, status_y, editor_state.status_message, colors.status, colors.status_bg)
--	end


--	if editor_state.cursor_y == 1 and editor_state.cursor_x == 1 and not editor_state.modified and editor_state.filename == "" then
--		local help_lines = {
--			"RMP Text Editor",
--			"",
--			"Normal Mode:",
--			"  i - Insert mode    h/j/k/l - Move cursor",
--			"  g - Go to top      G - Go to bottom",
--			"  Ctrl+S - Save     Ctrl+O - Open test.txt",
--			"",
--			"Insert Mode:",
--			"  ESC - Normal mode  Arrow keys - Move",
--			"  Enter - New line   Backspace - Delete",
--			"",
--			"Press 'i' to start editing!"
--		}

--		for i, help_line in ipairs(help_lines) do
--			if i <= view_height then
--				vterm:writeText(x + 4, y + i - 1, help_line, colors.normal, api.BGColors.NoBrights.Black)
--			end
--		end
--	end

--	return vterm
--end

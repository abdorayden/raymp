-- FEATURES: delete , set mark , copy , move , search
-- without using Scroller component shit (because it's broken)

local api = require("rmp.rmp")

local current_path = api.Path.new():getCurrentPath()
local entries = {}
local cursor_pos = 1
local scroll_offset = 0
local color_header = api.FGColors.Brights.Green
local color_dir = api.FGColors.Brights.Yellow
local color_file = api.FGColors.NoBrights.White
local color_cursor = api.FGColors.Brights.Cyan
local color_help = api.FGColors.Brights.Magenta
local style_cursor = api.TextStyle.Bold
local bg_normal = api.BGColors.NoBrights.Black
local show_help = false
local vterm = api.VirtualTerminal.new()

return function(x, y, xx, yy)
	vterm:clear()
	local available_height = (yy - y) - 2 

	local function adjust_scroll()

		if cursor_pos <= scroll_offset then
			scroll_offset = math.max(0, cursor_pos - 1)
		elseif cursor_pos > scroll_offset + available_height then
			scroll_offset = cursor_pos - available_height
		end
		scroll_offset = math.min(scroll_offset, math.max(0, #entries - available_height))
	end

	local function load_directory()
		local path_obj = api.Path.new(current_path)
		entries = path_obj:listDir() or {}

		table.sort(entries, function(a, b)
			if a.is_file ~= b.is_file then
				return not a.is_file 
			end
			return a.name < b.name
		end)

		if cursor_pos > #entries then
			cursor_pos = math.max(1, #entries)
		end

		if cursor_pos < 1 then
			cursor_pos = 1
		end
		adjust_scroll()
	end


	local function render()

		for i = y, yy - 1 do
			vterm:writeText(x + 1, i, string.rep(" ", xx - x - 2), color_file, bg_normal)
		end


		local path_display = current_path
		local max_path_width = xx - x - 8  
		if #path_display > max_path_width then
			path_display = "..." .. string.sub(path_display, -(max_path_width - 3))
		end
		vterm:writeText(x + 1, y, "Path: " .. path_display, color_header, bg_normal, api.TextStyle.Bold)


		for i = 1, available_height do
			local entry_index = scroll_offset + i
			local line_y = y + i

			if entry_index <= #entries then
				local entry = entries[entry_index]
				local prefix = entry.is_file and "[F] " or "[D] "
				local display_name = prefix .. entry.name


				local max_name_width = xx - x - 3
				if #display_name > max_name_width then
					display_name = string.sub(display_name, 1, max_name_width - 3) .. "..."
				end


				local fg_color = entry.is_file and color_file or color_dir
				local bg_color = bg_normal
				local text_style = nil


				if entry_index == cursor_pos then
					fg_color = color_cursor
					text_style = style_cursor
				end

				vterm:writeText(x + 1, line_y, display_name, fg_color, bg_color, text_style)
			end
		end

		if show_help then
			local help_text = "[J/K] Move  [Enter] Open  [H] Parent  [R] Refresh  [Q] Quit"
			local help_max_width = xx - x - 2
			if #help_text > help_max_width then
				help_text = string.sub(help_text, 1, help_max_width - 3) .. "..."
			end
			vterm:writeText(x + 1, yy - 1, help_text, color_help, bg_normal)
		end

		if #entries > available_height then
			local scroll_info = string.format("press ? to help | (%d/%d)", cursor_pos, #entries)
			vterm:writeText(xx - #scroll_info - 1, y, scroll_info, color_help, bg_normal)
		end
	end

	local function move_cursor_down()
		if cursor_pos < #entries then
			cursor_pos = cursor_pos + 1
			adjust_scroll()
			render()
		end
	end

	local function move_cursor_up()
		if cursor_pos > 1 then
			cursor_pos = cursor_pos - 1
			adjust_scroll()
			render()
		end
	end

	local function enter_selection()
		if #entries == 0 or cursor_pos < 1 or cursor_pos > #entries then
			return
		end

		local selected = entries[cursor_pos]
		local new_path

		if string.sub(current_path, -1) == "/" then
			new_path = current_path .. selected.name
		else
			new_path = current_path .. "/" .. selected.name
		end

		if not selected.is_file then
			current_path = new_path
			cursor_pos = 1
			scroll_offset = 0
			load_directory()
			render()
		else
			vterm:writeText(x + 1, yy - 2, "Selected: " .. selected.name, api.FGColors.Brights.White, api.BGColors.NoBrights.Green)
		end
	end

	local function go_to_parent()
		local parent = current_path:match("(.+)/[^/]+/?$")
		if parent and parent ~= "" then
			current_path = parent
			cursor_pos = 1
			scroll_offset = 0
			load_directory()
			render()
		end
	end

	local function refresh_directory()
		load_directory()
		render()
	end


	vterm:addEventListener(api.EventType.Keyboard , function(key) 
		if key == api.KEY_QUISTION_MARK then
			show_help = not show_help
		elseif key == api.KEY_J or key == api.KEY_DOWN then
			move_cursor_down()
		elseif key == api.KEY_K or key == api.KEY_UP then
			move_cursor_up()
		elseif key == api.KEY_ENTER then
			enter_selection()
		elseif key == api.KEY_H then
			go_to_parent()
		elseif key == api.KEY_R then
			refresh_directory()
		elseif key == api.KEY_N then
			cursor_pos = math.min(#entries, cursor_pos + available_height)
			adjust_scroll()
			render()
		elseif key == api.KEY_P then
			cursor_pos = math.max(1, cursor_pos - available_height)
			adjust_scroll()
			render()
		elseif key == api.KEY_G then
			cursor_pos = 1
			adjust_scroll()
			render()
		elseif key == api.KEY_SHIFT_G then
			cursor_pos = math.max(1, #entries)
			adjust_scroll()
			render()
		end
	end)

	load_directory()
	render()

	return vterm
end

-- -- Advanced File Browser Plugin for RMP Framework
-- -- Features: marking, file type colors, search, hidden files, better styling

-- local api = require("rmp.rmp")

-- local current_path = api.Path.new():getCurrentPath()
-- local entries = {}
-- local cursor_pos = 1
-- local scroll_offset = 0
-- local marked_files = {} -- table to track marked files by full path
-- local search_mode = false
-- local search_query = ""
-- local show_hidden = false

-- -- Enhanced color scheme - no yellow, using blue/purple/cyan theme
-- local colors = {
-- 	header = api.FGColors.Brights.Cyan,
-- 	dir = api.FGColors.Brights.Blue,
-- 	file = api.FGColors.NoBrights.White,
-- 	cursor = api.FGColors.Brights.Magenta,
-- 	marked = api.TextStyle.Underline,
-- 	help = api.FGColors.Brights.White,
-- 	search = api.FGColors.Brights.Cyan,
-- 	error = api.FGColors.Brights.Red,
-- 	executable = api.FGColors.Brights.Green,
-- 	archive = api.FGColors.NoBrights.Magenta,
-- 	image = api.FGColors.NoBrights.Cyan,
-- 	text = api.FGColors.NoBrights.White,
-- 	hidden = api.FGColors.NoBrights.Cyan,
-- }

-- local bg_normal = api.BGColors.NoBrights.Black
-- local bg_cursor = api.BGColors.NoBrights.Blue

-- return function(x, y, xx, yy)
-- 	local vterm = api.VirtualTerminal.new()
-- 	local available_height = (yy - y) - 3 -- Reserve space for header, search, and help

-- 	local function get_file_type_color(entry)
-- 		if not entry.is_file then
-- 			return entry.name:sub(1, 1) == "." and colors.hidden or colors.dir
-- 		end

-- 		local ext = entry.name:match("%.([^%.]+)$")
-- 		if not ext then
-- 			return entry.name:sub(1, 1) == "." and colors.hidden or colors.file
-- 		end

-- 		ext = ext:lower()

-- 		-- Executable files
-- 		if ext:match("^(exe|bat|sh|cmd|bin)$") then
-- 			return colors.executable
-- 		end

-- 		-- Archive files
-- 		if ext:match("^(zip|rar|tar|gz|7z|bz2|xz)$") then
-- 			return colors.archive
-- 		end

-- 		-- Image files
-- 		if ext:match("^(jpg|jpeg|png|gif|bmp|svg|webp|ico)$") then
-- 			return colors.image
-- 		end

-- 		-- Text/code files
-- 		if ext:match("^(txt|md|lua|py|js|html|css|json|xml|yaml|toml|conf|cfg)$") then
-- 			return colors.text
-- 		end

-- 		-- Hidden files
-- 		if entry.name:sub(1, 1) == "." then
-- 			return colors.hidden
-- 		end

-- 		return colors.file
-- 	end

-- 	local function is_hidden(name)
-- 		return name:sub(1, 1) == "."
-- 	end

-- 	local function matches_search(entry)
-- 		if search_query == "" then
-- 			return true
-- 		end
-- 		return entry.name:lower():find(search_query:lower(), 1, true) ~= nil
-- 	end

-- 	local function get_current_entries()
-- 		local result = {}
-- 		for _, entry in ipairs(entries) do
-- 			if (show_hidden or not is_hidden(entry.name)) and matches_search(entry) then
-- 				table.insert(result, entry)
-- 			end
-- 		end
-- 		return result
-- 	end

-- 	local function get_file_path(entry)
-- 		if string.sub(current_path, -1) == "/" then
-- 			return current_path .. entry.name
-- 		else
-- 			return current_path .. "/" .. entry.name
-- 		end
-- 	end

-- 	local function is_marked(entry)
-- 		return marked_files[get_file_path(entry)] == true
-- 	end

-- 	local function adjust_scroll()
-- 		local current_entries = get_current_entries()
-- 		local total = #current_entries

-- 		if total == 0 then
-- 			scroll_offset = 0
-- 			cursor_pos = 1
-- 			return
-- 		end

-- 		if cursor_pos > total then
-- 			cursor_pos = total
-- 		end

-- 		if cursor_pos < 1 then
-- 			cursor_pos = 1
-- 		end

-- 		if cursor_pos <= scroll_offset then
-- 			scroll_offset = math.max(0, cursor_pos - 1)
-- 		elseif cursor_pos > scroll_offset + available_height then
-- 			scroll_offset = cursor_pos - available_height
-- 		end
-- 		scroll_offset = math.min(scroll_offset, math.max(0, total - available_height))
-- 	end

-- 	local function load_directory()
-- 		local path_obj = api.Path.new(current_path)
-- 		entries = path_obj:listDir() or {}

-- 		-- Sort: directories first, then files, both alphabetically
-- 		table.sort(entries, function(a, b)
-- 			if a.is_file ~= b.is_file then
-- 				return not a.is_file 
-- 			end
-- 			return a.name:lower() < b.name:lower()
-- 		end)

-- 		cursor_pos = 1
-- 		scroll_offset = 0
-- 		search_mode = false
-- 		search_query = ""
-- 		adjust_scroll()
-- 	end

-- 	local function render()
-- 		-- Clear area
-- 		for i = y, yy - 1 do
-- 			vterm:writeText(x + 1, i, string.rep(" ", xx - x - 2), colors.file, bg_normal)
-- 		end

-- 		-- Header with path
-- 		local path_display = current_path
-- 		local max_path_width = xx - x - 20
-- 		if #path_display > max_path_width then
-- 			path_display = "..." .. string.sub(path_display, -(max_path_width - 3))
-- 		end
-- 		vterm:writeText(x + 1, y, "Path: " .. path_display, colors.header, bg_normal, api.TextStyle.Bold)

-- 		-- Show current mode and stats
-- 		local status = ""
-- 		if search_mode then
-- 			status = "Search: " .. search_query .. " | "
-- 		end
-- 		status = status .. (show_hidden and "Hidden: ON | " or "")
-- 		local marked_count = 0
-- 		for _ in pairs(marked_files) do marked_count = marked_count + 1 end
-- 		if marked_count > 0 then
-- 			status = status .. "Marked: " .. marked_count .. " | "
-- 		end

-- 		if status ~= "" then
-- 			vterm:writeText(xx - #status - 1, y, status:sub(1, -3), colors.search, bg_normal)
-- 		end

-- 		-- File listing
-- 		local current_entries = get_current_entries()
-- 		for i = 1, available_height do
-- 			local entry_index = scroll_offset + i
-- 			local line_y = y + 1 + i

-- 			if entry_index <= #current_entries then
-- 				local entry = current_entries[entry_index]
-- 				local prefix = entry.is_file and " " or "/"
-- 				local mark = is_marked(entry) and "✓" or " "
-- 				local display_name = mark .. " " .. entry.name .. prefix

-- 				-- Truncate if too long
-- 				local max_name_width = xx - x - 3
-- 				if #display_name > max_name_width then
-- 					display_name = string.sub(display_name, 1, max_name_width - 3) .. "..."
-- 				end

-- 				-- Choose colors and style
-- 				local fg_color = get_file_type_color(entry)
-- 				local bg_color = bg_normal
-- 				local text_style = nil

-- 				-- Highlight cursor position
-- 				if entry_index == cursor_pos then
-- 					fg_color = colors.cursor
-- 					bg_color = bg_cursor
-- 					text_style = api.TextStyle.Bold
-- 					display_name = "→" .. display_name:sub(2)
-- 				end

-- 				-- Override color for marked items
-- 				if is_marked(entry) and entry_index ~= cursor_pos then
-- 					fg_color = colors.marked
-- 				end

-- 				vterm:writeText(x + 1, line_y, display_name, fg_color, bg_color, text_style)
-- 			end
-- 		end

-- 		-- Show scroll indicator
-- 		if #current_entries > available_height then
-- 			local scroll_info = string.format("(%d/%d)", cursor_pos, #current_entries)
-- 			vterm:writeText(xx - #scroll_info - 1, y + 1, scroll_info, colors.help, bg_normal)
-- 		end

-- 		-- Help text
-- 		local help_line1 = "[J/K] Move [Enter] Open [Space] Mark [H] Parent [R] Refresh"
-- 		local help_line2 = "[/] Search [.] Hidden [C] Copy [D] Delete [ESC] Exit Search"

-- 		vterm:writeText(x + 1, yy - 2, help_line1, colors.help, bg_normal)
-- 		vterm:writeText(x + 1, yy - 1, help_line2, colors.help, bg_normal)
-- 	end

-- 	local function move_cursor_down()
-- 		local current_entries = get_current_entries()
-- 		if cursor_pos < #current_entries then
-- 			cursor_pos = cursor_pos + 1
-- 			adjust_scroll()
-- 			render()
-- 		end
-- 	end

-- 	local function move_cursor_up()
-- 		if cursor_pos > 1 then
-- 			cursor_pos = cursor_pos - 1
-- 			adjust_scroll()
-- 			render()
-- 		end
-- 	end

-- 	local function toggle_mark()
-- 		local current_entries = get_current_entries()
-- 		if cursor_pos > 0 and cursor_pos <= #current_entries then
-- 			local entry = current_entries[cursor_pos]
-- 			local file_path = get_file_path(entry)
-- 			marked_files[file_path] = not marked_files[file_path]
-- 			render()
-- 		end
-- 	end

-- 	local function enter_selection()
-- 		local current_entries = get_current_entries()
-- 		if #current_entries == 0 or cursor_pos < 1 or cursor_pos > #current_entries then
-- 			return
-- 		end

-- 		local selected = current_entries[cursor_pos]
-- 		local new_path = get_file_path(selected)

-- 		if not selected.is_file then
-- 			current_path = new_path
-- 			cursor_pos = 1
-- 			scroll_offset = 0
-- 			load_directory()
-- 			render()
-- 		else
-- 			-- Show file selection feedback
-- 			local feedback = "Selected: " .. selected.name .. " (" .. new_path .. ")"
-- 			local max_feedback = xx - x - 2
-- 			if #feedback > max_feedback then
-- 				feedback = feedback:sub(1, max_feedback - 3) .. "..."
-- 			end
-- 			vterm:writeText(x + 1, yy - 2, feedback, api.FGColors.Brights.White, api.BGColors.NoBrights.Green)
-- 		end
-- 	end

-- 	local function go_to_parent()
-- 		local parent = current_path:match("(.+)/[^/]+/?$")
-- 		if parent and parent ~= "" then
-- 			current_path = parent
-- 			cursor_pos = 1
-- 			scroll_offset = 0
-- 			load_directory()
-- 			render()
-- 		end
-- 	end

-- 	local function refresh_directory()
-- 		load_directory()
-- 		render()
-- 	end

-- 	local function toggle_hidden()
-- 		show_hidden = not show_hidden
-- 		adjust_scroll()
-- 		render()
-- 	end

-- 	local function start_search()
-- 		search_mode = true
-- 		search_query = ""
-- 		cursor_pos = 1
-- 		adjust_scroll()
-- 		render()
-- 	end

-- 	local function exit_search()
-- 		search_mode = false
-- 		search_query = ""
-- 		cursor_pos = 1
-- 		adjust_scroll()
-- 		render()
-- 	end

-- 	local function delete_marked()
-- 		local count = 0
-- 		for path, marked in pairs(marked_files) do
-- 			if marked then
-- 				count = count + 1
-- 			end
-- 		end

-- 		if count > 0 then
-- 			local message = "Delete " .. count .. " marked files? This cannot be undone!"
-- 			vterm:writeText(x + 1, yy - 1, message, colors.error, bg_normal, api.TextStyle.Bold)
-- 			-- In a real implementation, you'd wait for confirmation here
-- 		else
-- 			vterm:writeText(x + 1, yy - 1, "No files marked for deletion", colors.error, bg_normal)
-- 		end
-- 	end

-- 	local function copy_marked()
-- 		local count = 0
-- 		for path, marked in pairs(marked_files) do
-- 			if marked then
-- 				count = count + 1
-- 			end
-- 		end

-- 		if count > 0 then
-- 			vterm:writeText(x + 1, yy - 1, count .. " files copied to clipboard", colors.help, api.BGColors.NoBrights.Green)
-- 		else
-- 			vterm:writeText(x + 1, yy - 1, "No files marked for copying", colors.error, bg_normal)
-- 		end
-- 	end

-- 	-- Event listeners
-- 	vterm:addEventListener(api.KEY_J, move_cursor_down)
-- 	vterm:addEventListener(api.KEY_DOWN, move_cursor_down)
-- 	vterm:addEventListener(api.KEY_K, move_cursor_up)
-- 	vterm:addEventListener(api.KEY_UP, move_cursor_up)
-- 	vterm:addEventListener(api.KEY_SPACE, toggle_mark)
-- 	vterm:addEventListener(api.KEY_ENTER, enter_selection)
-- 	vterm:addEventListener(api.KEY_H, go_to_parent)
-- 	vterm:addEventListener(api.KEY_R, refresh_directory)
-- 	vterm:addEventListener(api.KEY_DOT, toggle_hidden)
-- 	vterm:addEventListener(api.KEY_C, copy_marked)
-- 	vterm:addEventListener(api.KEY_D, delete_marked)

-- 	-- Page navigation
-- 	vterm:addEventListener(api.KEY_N, function()
-- 		local current_entries = get_current_entries()
-- 		cursor_pos = math.min(#current_entries, cursor_pos + available_height)
-- 		adjust_scroll()
-- 		render()
-- 	end)

-- 	vterm:addEventListener(api.KEY_P, function()
-- 		cursor_pos = math.max(1, cursor_pos - available_height)
-- 		adjust_scroll()
-- 		render()
-- 	end)

-- 	-- Go to start/end
-- 	vterm:addEventListener(api.KEY_G, function()
-- 		cursor_pos = 1
-- 		adjust_scroll()
-- 		render()
-- 	end)

-- 	vterm:addEventListener(api.KEY_SHIFT_G, function()
-- 		local current_entries = get_current_entries()
-- 		cursor_pos = math.max(1, #current_entries)
-- 		adjust_scroll()
-- 		render()
-- 	end)

-- 	-- Search functionality (simplified - in real implementation you'd capture input)
-- 	vterm:addEventListener(api.KEY_SEMICOL, start_search) -- Using ';' for search since '/' might not work
-- 	vterm:addEventListener(api.KEY_ESCAPE, exit_search)

-- 	-- Initialize
-- 	load_directory()
-- 	render()

-- 	return vterm
-- end












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

return function(x, y, xx, yy)
	local vterm = api.VirtualTerminal.new()
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


	vterm:addEventListener(api.KEY_QUISTION_MARK , function() 
		show_help = not show_help
	end)
	vterm:addEventListener(api.KEY_J, move_cursor_down)
	vterm:addEventListener(api.KEY_DOWN, move_cursor_down)
	vterm:addEventListener(api.KEY_K, move_cursor_up)
	vterm:addEventListener(api.KEY_UP, move_cursor_up)
	vterm:addEventListener(api.KEY_ENTER, enter_selection)
	vterm:addEventListener(api.KEY_H, go_to_parent)
	vterm:addEventListener(api.KEY_R, refresh_directory)

	vterm:addEventListener(api.KEY_N, function()
		cursor_pos = math.min(#entries, cursor_pos + available_height)
		adjust_scroll()
		render()
	end)

	vterm:addEventListener(api.KEY_P, function()
		cursor_pos = math.max(1, cursor_pos - available_height)
		adjust_scroll()
		render()
	end)


	vterm:addEventListener(api.KEY_G, function()
		cursor_pos = 1
		adjust_scroll()
		render()
	end)

	vterm:addEventListener(api.KEY_SHIFT_G, function()
		cursor_pos = math.max(1, #entries)
		adjust_scroll()
		render()
	end)


	load_directory()
	render()

	return vterm
end

local api = require("rmp.rmp")

local browser_state = {
	current_path = api.Path.new():getCurrentPath(),
	entries = {},
	filtered_entries = {},
	cursor_pos = 1,
	scroll_offset = 0,
	search_active = false,
	search_query = "",
	show_help = false,
	show_hidden = false,
	sort_mode = "name", -- "name", "type", "size", "date"
	sort_ascending = true,
	marked_files = {}, -- for multi-selection
	clipboard = {}, -- for copy/cut operations
	clipboard_mode = "copy", -- "copy" or "cut"
	status_message = "",
	status_time = 0
}

local colors = {
	header = api.FGColors.Brights.Green,
	dir = api.FGColors.Brights.Yellow,
	file = api.FGColors.NoBrights.White,
	cursor = api.FGColors.Brights.Cyan,
	help = api.FGColors.Brights.Magenta,
	search = api.FGColors.Brights.White,
	search_bg = api.BGColors.NoBrights.Blue,
	marked = api.FGColors.Brights.Green,
	status = api.FGColors.Brights.Yellow,
	error = api.FGColors.Brights.Red,
	success = api.FGColors.Brights.Green
}

local search_input = api.SimpleInput.new({
	label = "Search: ",
	placeholder = "Type to search files...",
	width = 30,
	maxLength = 100,
	fg_normal = colors.search,
	bg_normal = colors.search_bg,
	fg_active = api.FGColors.Brights.Yellow,
	bg_active = colors.search_bg
})

local function set_status(message, is_error)
	browser_state.status_message = message
	browser_state.status_time = os.time()
end

local function clear_status_if_old()
	if os.time() - browser_state.status_time > 3 then
		browser_state.status_message = ""
	end
end

local function is_hidden_file(name)
	return name:match("^%.")
end

local function matches_search(name)
	if browser_state.search_query == "" then
		return true
	end
	return name:lower():find(browser_state.search_query:lower(), 1, true) ~= nil
end

local function sort_entries(entries)
	table.sort(entries, function(a, b)
		if a.is_file ~= b.is_file then
			return not a.is_file
		end

		local comp_result
		if browser_state.sort_mode == "name" then
			comp_result = a.name:lower() < b.name:lower()
		elseif browser_state.sort_mode == "type" then
			local ext_a = (a.name:match("%.([^%.]+)$") or ""):lower()
			local ext_b = (b.name:match("%.([^%.]+)$") or ""):lower()

			if ext_a ~= ext_b then
				comp_result = ext_a < ext_b
			else
				comp_result = a.name:lower() < b.name:lower()
			end
		else
			comp_result = a.name:lower() < b.name:lower()
		end

		if browser_state.sort_ascending then
			return comp_result
		else
			return not comp_result
		end
	end)
end

local function filter_entries()
	browser_state.filtered_entries = {}
	for _, entry in ipairs(browser_state.entries) do
		if matches_search(entry.name) then
			table.insert(browser_state.filtered_entries, entry)
		end
	end
end

local function load_directory()
	local path_obj = api.Path.new(browser_state.current_path)
	local raw_entries = path_obj:listDir() or {}

	browser_state.entries = {}
	for _, entry in ipairs(raw_entries) do
		local should_include = true

		if not browser_state.show_hidden and is_hidden_file(entry.name) then
			should_include = false
		end

		if should_include then
			table.insert(browser_state.entries, entry)
		end
	end

	sort_entries(browser_state.entries)

	filter_entries()

	if browser_state.cursor_pos > #browser_state.filtered_entries then
		browser_state.cursor_pos = math.max(1, #browser_state.filtered_entries)
	end
	if browser_state.cursor_pos < 1 then
		browser_state.cursor_pos = 1
	end
end


local function adjust_scroll(available_height)
	if browser_state.cursor_pos <= browser_state.scroll_offset then
		browser_state.scroll_offset = math.max(0, browser_state.cursor_pos - 1)
	elseif browser_state.cursor_pos > browser_state.scroll_offset + available_height then
		browser_state.scroll_offset = browser_state.cursor_pos - available_height
	end
	browser_state.scroll_offset = math.min(browser_state.scroll_offset, 
	math.max(0, #browser_state.filtered_entries - available_height))
end

local function get_file_icon(entry)
	if not entry.is_file then
		return "📁 "
	end

	local ext = entry.name:match("%.([^%.]+)$")
	if not ext then return "📄 " end

	ext = ext:lower()
	if ext == "lua" then return "🌙 "
	elseif ext == "txt" then return "📝 "
	elseif ext == "md" then return "📖 "
	elseif ext:match("^(jpg|jpeg|png|gif|bmp)$") then return "🖼️ "
	elseif ext:match("^(mp3|wav|ogg|flac)$") then return "🎵 "
	elseif ext:match("^(mp4|avi|mkv|mov)$") then return "🎬 "
	elseif ext:match("^(zip|rar|7z|tar|gz)$") then return "📦 "
	else return "📄 "
	end
end

local function toggle_mark_current()
	if #browser_state.filtered_entries == 0 then return end

	local current_entry = browser_state.filtered_entries[browser_state.cursor_pos]
	if not current_entry then return end

	local file_path = browser_state.current_path .. "/" .. current_entry.name
	if browser_state.marked_files[file_path] then
		browser_state.marked_files[file_path] = nil
		set_status("Unmarked: " .. current_entry.name)
	else
		browser_state.marked_files[file_path] = current_entry
		set_status("Marked: " .. current_entry.name)
	end
end

local function get_marked_count()
	local count = 0
	for _ in pairs(browser_state.marked_files) do
		count = count + 1
	end
	return count
end

local function move_cursor_down(available_height)
	if browser_state.cursor_pos < #browser_state.filtered_entries then
		browser_state.cursor_pos = browser_state.cursor_pos + 1
		adjust_scroll(available_height)
	end
end

local function move_cursor_up(available_height)
	if browser_state.cursor_pos > 1 then
		browser_state.cursor_pos = browser_state.cursor_pos - 1
		adjust_scroll(available_height)
	end
end

local function enter_selection()
	if #browser_state.filtered_entries == 0 or browser_state.cursor_pos < 1 or 
		browser_state.cursor_pos > #browser_state.filtered_entries then
		return
	end

	local selected = browser_state.filtered_entries[browser_state.cursor_pos]
	local new_path

	if string.sub(browser_state.current_path, -1) == "/" then
		new_path = browser_state.current_path .. selected.name
	else
		new_path = browser_state.current_path .. "/" .. selected.name
	end

	if not selected.is_file then
		browser_state.current_path = new_path
		browser_state.cursor_pos = 1
		browser_state.scroll_offset = 0
		browser_state.marked_files = {}
		load_directory()
		set_status("Entered directory: " .. selected.name)
	else
		set_status("Selected file: " .. selected.name)
	end
end

local function go_to_parent()
	local parent = browser_state.current_path:match("(.+)/[^/]+/?$")
	if parent and parent ~= "" then
		browser_state.current_path = parent
		browser_state.cursor_pos = 1
		browser_state.scroll_offset = 0
		browser_state.marked_files = {}
		load_directory()
		set_status("Moved to parent directory")
	end
end

local function toggle_search()
	browser_state.search_active = not browser_state.search_active
	if browser_state.search_active then
		search_input:focus()
		set_status("Search mode activated - type to search")
	else
		search_input:blur()
		search_input:clear()
		browser_state.search_query = ""
		filter_entries()
		set_status("Search mode deactivated")
	end
end

local function update_search()
	browser_state.search_query = search_input:getValue()
	filter_entries()
	browser_state.cursor_pos = 1
	browser_state.scroll_offset = 0
end

return function(x, y, xx, yy)
	local vterm = api.VirtualTerminal.new()
	local available_height = (yy - y) - 4

	clear_status_if_old()

	vterm:addEventListener(api.EventType.Keyboard, function(key)
		if browser_state.search_active then
			if key == api.KEY_ESCAPE then
				toggle_search()
			end
			return
		end

		if key == api.KEY_SLASH then
			toggle_search()
		elseif key == api.KEY_QUISTION_MARK then
			browser_state.show_help = not browser_state.show_help
		elseif key == api.KEY_J or key == api.KEY_DOWN then
			move_cursor_down(available_height)
		elseif key == api.KEY_K or key == api.KEY_UP then
			move_cursor_up(available_height)
		elseif key == api.KEY_ENTER then
			if not browser_state.search_active then
				enter_selection()
			else
				-- TODO: handle enter in search mode to select first result if it's a file or enter directory if it's a folder
			end
		elseif key == api.KEY_H then
			go_to_parent()
		elseif key == api.KEY_R then
			load_directory()
			set_status("Directory refreshed")
		elseif key == api.KEY_G then
			browser_state.cursor_pos = 1
			adjust_scroll(available_height)
		elseif key == api.KEY_SHIFT_G then
			browser_state.cursor_pos = math.max(1, #browser_state.filtered_entries)
			adjust_scroll(available_height)
		elseif key == api.KEY_N then
			browser_state.cursor_pos = math.min(#browser_state.filtered_entries, 
			browser_state.cursor_pos + available_height)
			adjust_scroll(available_height)
		elseif key == api.KEY_P then
			browser_state.cursor_pos = math.max(1, 
			browser_state.cursor_pos - available_height)
			adjust_scroll(available_height)
		elseif key == api.KEY_SPACE then
			toggle_mark_current()
		elseif key == api.KEY_DOT then
			browser_state.show_hidden = not browser_state.show_hidden
			load_directory()
			set_status(browser_state.show_hidden and "Showing hidden files" or "Hiding hidden files")
		elseif key == api.KEY_S then
			if browser_state.sort_mode == "name" then
				browser_state.sort_mode = "type"
			else
				browser_state.sort_mode = "name"
			end
			load_directory()
			set_status("Sort by: " .. browser_state.sort_mode)
		elseif key == api.KEY_T then
			browser_state.sort_ascending = not browser_state.sort_ascending
			load_directory()
			set_status("Sort order: " .. (browser_state.sort_ascending and "ascending" or "descending"))
		end
	end)

	if browser_state.search_active then
		search_input.x = x + 1
		search_input.y = y + 1
		search_input:render(vterm)

		local old_query = browser_state.search_query
		update_search()
		if old_query ~= browser_state.search_query then
			-- search query changed, update results
		end
	end

	local path_display = browser_state.current_path
	local header_y = browser_state.search_active and y + 2 or y + 1
	local max_path_width = xx - x - 20
	if #path_display > max_path_width then
		path_display = "..." .. string.sub(path_display, -(max_path_width - 3))
	end

	vterm:writeText(x + 1, header_y, "📁 " .. path_display, colors.header, 
	api.BGColors.NoBrights.Black, api.TextStyle.Bold)

	local info_text = string.format("(%d files", #browser_state.filtered_entries)
	if #browser_state.entries ~= #browser_state.filtered_entries then
		info_text = info_text .. "/" .. #browser_state.entries .. " shown"
	end
	local marked_count = get_marked_count()
	if marked_count > 0 then
		info_text = info_text .. ", " .. marked_count .. " marked"
	end
	info_text = info_text .. ")"

	vterm:writeText(xx - #info_text - 1, header_y, info_text, colors.help, 
	api.BGColors.NoBrights.Black)

	local list_start_y = header_y + 1
	for i = 1, available_height do
		local entry_index = browser_state.scroll_offset + i
		local line_y = list_start_y + i - 1

		if entry_index <= #browser_state.filtered_entries then
			local entry = browser_state.filtered_entries[entry_index]
			local icon = get_file_icon(entry)
			local display_name = icon .. entry.name

			local max_name_width = xx - x - 3
			if #display_name > max_name_width then
				display_name = string.sub(display_name, 1, max_name_width - 3) .. "..."
			end

			local fg_color = entry.is_file and colors.file or colors.dir
			local bg_color = api.BGColors.NoBrights.Black
			local text_style = nil

			local file_path = browser_state.current_path .. "/" .. entry.name
			local is_marked = browser_state.marked_files[file_path] ~= nil

			if entry_index == browser_state.cursor_pos then
				fg_color = colors.cursor
				text_style = api.TextStyle.Bold
			elseif is_marked then
				fg_color = colors.marked
				text_style = api.TextStyle.Bold
			end

			vterm:writeText(x + 1, line_y, display_name, fg_color, bg_color, text_style)
		end
	end

	if browser_state.show_help then
		local help_lines = {
			"[/] Search  [J/K] Move  [Enter] Open  [H] Parent  [Space] Mark",
			"[R] Refresh  [.] Hidden  [S] Sort  [T] Order  [Q] Quit  [?] Help"
		}
		for i, help_text in ipairs(help_lines) do
			vterm:writeText(x + 1, yy - 2 + i, help_text, colors.help, 
			api.BGColors.NoBrights.Black)
		end
	end

	if browser_state.status_message ~= "" then
		vterm:writeText(x + 1, yy - 1, browser_state.status_message, colors.status, 
		api.BGColors.NoBrights.Black)
	end

	if #browser_state.filtered_entries > available_height then
		local scroll_info = string.format("(%d/%d)", browser_state.cursor_pos, 
		#browser_state.filtered_entries)
		vterm:writeText(xx - #scroll_info - 1, yy - 1, scroll_info, colors.help, 
		api.BGColors.NoBrights.Black)
	end

	if #browser_state.entries == 0 then
		load_directory()
	end

	return vterm
end

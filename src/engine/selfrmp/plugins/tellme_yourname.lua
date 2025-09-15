-- RMP Framework Plugin: Tell Me Your Name (Fixed)

local api = require("rmp.rmp")

local PLUGIN_NAME = "Tell Me Your Name"
local INPUT_LABEL = "What is your name: "
local SUCCESS_COLOR = api.FGColors.Brights.Green
local ERROR_COLOR = api.FGColors.Brights.Red
local INFO_COLOR = api.FGColors.Brights.Cyan
local DEFAULT_BG = api.BGColors.NoBrights.Black

local plugin_state = {
	input_instance = nil,
	last_submission = "",
	submission_time = 0,
	show_result = false,
	result_message = "",
	initialized = false,
	input_active = false
}

local function safe_string(str)
	return tostring(str or "")
end

local function validate_name(name)
	name = safe_string(name):gsub("^%s*(.-)%s*$", "%1")

	if #name == 0 then
		return false, "Name cannot be empty"
	end

	if #name < 2 then
		return false, "Name must be at least 2 characters long"
	end

	if #name > 50 then
		return false, "Name cannot be longer than 50 characters"
	end

	if not name:match("^[%a%s%-%']+$") then
		return false, "Name can only contain letters, spaces, hyphens, and apostrophes"
	end

	return true
end

local function create_input_instance(x, y, width)
	local safe_x = math.max(1, tonumber(x) or 1)
	local safe_y = math.max(1, tonumber(y) or 1)
	local safe_width = math.max(20, tonumber(width) or 30)

	local input = api.Input.new(
	INPUT_LABEL,
	safe_x,
	safe_y,
	safe_width,
	"", 
	api.KEY_ESCAPE 
	)

	if input then
		return input
	else
		error("Failed to create Input instance")
	end
end

local function handle_submission(input)
	if not input then return end

	local text = safe_string(input:getText())
	local is_valid, error_msg = validate_name(text)

	if is_valid then
		plugin_state.last_submission = text
		plugin_state.show_result = true
		plugin_state.result_message = "Hello, " .. text .. "! Nice to meet you!"
		plugin_state.submission_time = os.time()

		
		input:clearText()
		input:stop()
		plugin_state.input_active = false
	else
		plugin_state.show_result = true
		plugin_state.result_message = "Error: " .. (error_msg or "Invalid name")
		plugin_state.submission_time = os.time()
	end
end

local function render_ui(vterm, x, y, xx, yy)
	if not vterm then return end

	local safe_x = math.max(1, tonumber(x) or 1)
	local safe_y = math.max(1, tonumber(y) or 1)
	local safe_xx = math.max(safe_x + 10, tonumber(xx) or safe_x + 40)
	local safe_yy = math.max(safe_y + 5, tonumber(yy) or safe_y + 10)

	
	vterm:writeText(
	safe_x, safe_y,
	PLUGIN_NAME,
	INFO_COLOR, DEFAULT_BG
	)

	
	local instructions = {
		"Enter your name below:",
		"• Use ENTER to submit",
		"• Use ESC to cancel/clear", 
		"• Use TAB to activate input",
		"• Use arrow keys to navigate",
		"• Name must be 2-50 characters"
	}

	for i, instruction in ipairs(instructions) do
		vterm:writeText(
		safe_x, safe_y + 1 + i,
		instruction,
		api.FGColors.NoBrights.White, DEFAULT_BG
		)
	end

	
	local status_text = plugin_state.input_active and "Input Active - Type your name" or "Press TAB to activate input"
	local status_color = plugin_state.input_active and SUCCESS_COLOR or api.FGColors.NoBrights.Yellow
	vterm:writeText(
	safe_x, safe_yy - 4,
	status_text,
	status_color, DEFAULT_BG
	)

	
	if plugin_state.show_result and plugin_state.result_message ~= "" then
		local color = plugin_state.result_message:match("^Error:") and ERROR_COLOR or SUCCESS_COLOR
		local result_y = safe_yy - 3

		vterm:writeText(
		safe_x, result_y,
		plugin_state.result_message,
		color, DEFAULT_BG
		)

		
		if os.time() - plugin_state.submission_time > 5 then
			plugin_state.show_result = false
			plugin_state.result_message = ""
		end
	end
end


return function(x, y, xx, yy)
	
	local safe_x = math.max(1, tonumber(x) or 1)
	local safe_y = math.max(1, tonumber(y) or 1)
	local safe_xx = math.max(safe_x + 10, tonumber(xx) or safe_x + 40)
	local safe_yy = math.max(safe_y + 5, tonumber(yy) or safe_y + 10)

	
	local vterm = api.VirtualTerminal.new()
	if not vterm then
		error("Failed to create VirtualTerminal")
	end

	
	if not plugin_state.input_instance then
		local input_y = safe_yy - 2
		local input_width = safe_xx - safe_x - 2

		plugin_state.input_instance = create_input_instance(
		safe_x, input_y, input_width
		)
		plugin_state.initialized = true
	end

	local input = plugin_state.input_instance

	
	vterm:addEventListener(api.EventType.Keyboard, function(key) 
		if key == api.KEY_TAB then
			plugin_state.input_active = not plugin_state.input_active

			if plugin_state.input_active then
				input:start()
			else
				input:stop()
			end
		end
	end)

	
	if plugin_state.input_active then
		vterm:addEventListener(api.EventType.Input, function(key)
			if input and input:isActive() then
				
				local handled = input:processKey(key)

				
				if input:wasSubmitted() then
					handle_submission(input)
					input.submitted = false 
				end

				
				if not input:isActive() and key == api.KEY_ESCAPE then
					plugin_state.input_active = false
				end
			end
		end)

		
		vterm:addEventListener(api.EventType.Keyboard, function(key)
			if plugin_state.input_active and input and input:isActive() then
				if key == api.KEY_ENTER then
					input:processKey(key)
					if input:wasSubmitted() then
						handle_submission(input)
						input.submitted = false
					end
				elseif key == api.KEY_ESCAPE then
					input:processKey(key) 
					plugin_state.input_active = false
				end
			end
		end)
	end

	
	if input and plugin_state.input_active then
		local input_vterm = input:getVterm()
		if input_vterm then
			vterm:merge(input_vterm)
		end
	end
	
	render_ui(vterm, safe_x, safe_y, safe_xx, safe_yy)

	return vterm
end

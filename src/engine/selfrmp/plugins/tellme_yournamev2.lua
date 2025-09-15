-- Super Simple Tell Me Your Name Plugin
-- Using the new high-level API

local api = require("rmp.rmp")

-- Create the input field once
local name_input = api.SimpleInput.new({
	label = "Your name: ",
	placeholder = "Enter your name here...",
	width = 25,
	maxLength = 50,
	validator = function(text)
		if #text < 2 then
			return false, "Name must be at least 2 characters"
		end
		if not text:match("^[%a%s%-%']+$") then
			return false, "Only letters, spaces, hyphens and apostrophes allowed"
		end
		return true
	end
})

local last_name = ""
local show_greeting = false
local greeting_time = 0

return function(x, y, xx, yy)
	local vterm = api.VirtualTerminal.new()

	-- Title
	vterm:writeText(x + 1, y + 1, "Tell Me Your Name Plugin", 
	api.FGColors.Brights.Cyan, api.BGColors.NoBrights.Black)

	-- Instructions  
	vterm:writeText(x + 1, y + 3, "Press TAB to start typing, ENTER to submit, ESC to cancel",
	api.FGColors.NoBrights.White, api.BGColors.NoBrights.Black)

	-- Position the input field
	name_input.x = x + 1
	name_input.y = y + 5

	-- Handle TAB key to activate input
	vterm:addEventListener(api.EventType.Keyboard, function(key)
		if key == api.KEY_TAB and not name_input:isActive() then
			name_input:focus()
		end
	end)

	-- Render the input field (handles everything automatically)
	name_input:render(vterm)

	-- Check if input was submitted
	if not name_input:isActive() and name_input:getValue() ~= last_name then
		last_name = name_input:getValue()
		if last_name ~= "" then
			show_greeting = true
			greeting_time = os.time()
		end
	end

	-- Show greeting
	if show_greeting and last_name ~= "" then
		vterm:writeText(x + 1, y + 7, "Hello, " .. last_name .. "! Nice to meet you!",
		api.FGColors.Brights.Green, api.BGColors.NoBrights.Black)

		-- Hide greeting after 5 seconds
		if os.time() - greeting_time > 5 then
			show_greeting = false
			name_input:clear()
			last_name = ""
		end
	end

	return vterm
end

-- Function to enable raw mode
function enable_raw_mode()
    os.execute("stty -icanon -echo") -- Disable line buffering and echo
end

-- Function to disable raw mode (restore terminal)
function disable_raw_mode()
    os.execute("stty sane") -- Reset terminal settings
end

-- Enable raw mode
enable_raw_mode()

local lib , err = package.loadlib("./keyboard.so" , "key_lib")

if not lib then
	print("ERROR lib is not loaded")
	print(err)
else
	print("lib loaded successfully")
	print("Raw mode enabled. Press 'q' to exit.")
	local init = lib()

	while true do
	    local char = io.read(1) -- Read single character
	    local input = init.handle_keys(string.byte(char))
	    if input == 24 then -- a
		    print("a pressed")
		    break
	    elseif input == 25 then
		    print("b pressed")
	    elseif input == 0 then
		    print("ctrl-a")
	    end
	    
	end
end


-- Restore terminal settings
disable_raw_mode()
print("\nRaw mode disabled.")

local keyboard = require("keyboard")

os.execute("stty -raw echo")
while true do
	local k = keyboard.get()
	if k == 34 then
		print("u pressed a")
	elseif k == 0 then -- ctrl-a
		print("u pressed ctrl-a")
	elseif k == 35 then -- b
		break
	end
end

os.execute("stty raw -echo")

keyboard.close()

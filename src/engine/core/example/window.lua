api = require("core_lua")
-- function window(title)
-- 	return {
-- 		""
-- 	}
-- end

-- TODO: window size method is already implemented
-- TODO: cursor position handled in lua script
-- @return void
function main(
		-- window_width , 
		-- window_height,
		-- x_position,
		-- y_position
		-- TODO: waves
	)
	-- check if the file is main UI or plugin
	-- window expected size 6
	-- 	title
	-- 	height
	-- 	width
	-- 	vect(x,y)
	--	Text | Style | Options | Input | Log
	--	routine { this routine might be event or something else
	main_window = api.CreateWindowV(
		"rayden",
		50,
		50,
		api.Vector2(0,0)
	)

	-- TODO: InserToObject 
	main_window = api.InsetToObject(main_window , function()
		return 
	end
	)
end


-- TODO: recreate albome plug in new api version
local api = require("rmp")

return function(cfg_sound)
	api.Terminal:HideCursor()
	local w , h = api.Terminal:GetSize()
	api.Window:CreateWindow("test" , h , w  , 1 , 1 , api.FGMagenta , nil , nil)
end

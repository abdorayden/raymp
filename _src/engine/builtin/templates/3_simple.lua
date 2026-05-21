--
--	simple 3-window rmp template
--	clean and functional starter layout
--

local api = require("rmp.rmp")

return {
	{
		id = 1,
		type = "Window",
		title = nil,
		width = "w",
		height = "h",
		x = 1,
		y = 1,
		border = api.BoxDrawing.LightBorder,
		backgroundColor = api.BGColors.NoBrights.Black,
		children = {
			-- Header Window
			{
				id = 3,
				type = "Window",
				title = {
					type = "Text",
					value = "RMP TERMINAL",
					foregroundColor = api.FGColors.Brights.Cyan,
					backgroundColor = api.BGColors.NoBrights.Black,
					style = api.TextStyle.Bold
				},
				width = "w - 2",
				height = 3,
				x = 2,
				y = 2,
				border = api.BoxDrawing.NoBorder,
				backgroundColor = api.BGColors.NoBrights.Blue
			},

			-- Main Content Window
			{
				id = 2,
				type = "Window",
				title = {
					type = "Text",
					value = "MAIN PANEL",
					foregroundColor = api.FGColors.Brights.Green,
					backgroundColor = api.BGColors.NoBrights.Black,
					style = api.TextStyle.Bold
				},
				width = "w - 4",
				height = "h - 10",
				x = 2,
				y = 6,
				border = api.BoxDrawing.LightBorder,
				backgroundColor = api.BGColors.NoBrights.Black
			},

			-- Status Bar Window
			{
				id = 4,
				type = "Window",
				title = {
					type = "Text",
					value = "READY",
					foregroundColor = api.FGColors.Brights.White,
					backgroundColor = api.BGColors.NoBrights.Green,
					style = api.TextStyle.Bold,
					dynamic = function(context)
						return "STATUS: ONLINE"
					end
				},
				width = "w - 2",
				height = 3,
				x = 2,
				y = "h - 3",
				border = api.BoxDrawing.NoBorder,
				backgroundColor = api.BGColors.NoBrights.Black
			}
		}
	}
}

local api = require("../core/rmp")

function main()
	 local song = api.Sound:New({"./Eminem - Mockingbird [Official Music Video].mp3"})
	 song:Play()
	 os.execute("sleep 5")
	 -- local ok , status = coroutine.resume(coroutine.create(function()
	 -- 	os.execute("sleep 5")
	 -- 	song:Play()
	 -- 	while song:IsPlaying() do
	 -- 		api.Popup:Info("is playing")
	 -- 		os.execute("sleep 5")
	 -- 		coroutine.yield()
	 -- 	end
	 -- end))
	 -- if not ok then
	 -- 	api.Popup:Error("could not run song")
	 -- end

	 -- while true do
	 -- 	print("song is playing")
	 -- 	os.execute("sleep 1")
	 -- end
 	 song:CleanUp()
end

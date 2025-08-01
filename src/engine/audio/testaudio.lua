local miniaudio = require("rmpaudio")

-- Initialize miniaudio
miniaudio.Init()
-- current time ...        255.89750566893
-- the duration is : 257.95918367347



-- current time ...        257.95918367347
-- the duration is : 257.95918367347

-- Load a song
miniaudio.Load("Eminem - Mockingbird [Official Music Video].mp3")

miniaudio.SetSpeed(0.5)
-- miniaudio.Seek(230)
miniaudio.SetVolume(0.6)

local function coo()
	miniaudio.Play()
	while miniaudio.IsPlaying() do
		coroutine.yield()
	end
end

coroutine.resume(coroutine.create(coo))

-- Rest of your code continues executing
print("Audio is playing in the background...")
print("the duration is : " .. miniaudio.GetDuration())
 
 -- Simulate other tasks
while not miniaudio.IsAtTheEnd() do
-- while AtTheEnd() ~= true do
    print("current time ...", miniaudio.GetPosition())
    os.execute("sleep 1")  -- Simulate some work
end

-- Clean up
miniaudio.Clean()

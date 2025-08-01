-- local curses = require("curses")
-- 
-- -- Initialize curses
-- local ok, err = pcall(function()
--     curses.initscr()
--     curses.cbreak()
--     -- curses.noecho()
--     curses.curs_set(0)
-- end)
-- 
-- if not ok then
--     print("Error initializing curses: " .. err)
--     return
-- end
-- 
-- local height, width = curses.stdscr:getmaxyx()
-- local x, y = width / 2, height / 2
-- 
-- -- Show instructions
-- curses.stdscr:mvaddstr(y, x, "Move with arrow keys, press 'q' to exit")
-- curses.stdscr:refresh()
-- 
-- while true do
--     local key = curses.stdscr:getch()
-- 
--     -- Print key codes for debugging
--     print("Key Pressed:", key)
-- 
--     -- Check for 'q' to exit
--     if key == string.byte('q') then break end
-- 
--     -- Handle arrow keys
--     if key == curses.KEY_UP then y = y - 1 end
--     if key == curses.KEY_DOWN then y = y + 1 end
--     if key == curses.KEY_LEFT then x = x - 1 end
--     if key == curses.KEY_RIGHT then x = x + 1 end
-- 
--     -- Ensure cursor stays within bounds
--     y = math.max(0, math.min(y, height - 1))
--     x = math.max(0, math.min(x, width - 1))
-- 
--     -- Clear the screen and draw the new cursor position
--     curses.stdscr:clear()
--     curses.stdscr:mvaddstr(y, x, "@")
--     curses.stdscr:refresh()
-- 
--     -- Small delay to avoid excessive CPU usage
--     os.execute("sleep 0.1")
-- end
-- 
-- -- End curses session
-- curses.endwin()

local io = require("io")

ONE	=	"═"
TWO	=	"║"

THREE	=	"╔"

FOUR	=	"╚"
FIVE	=	"╗"

SIX	=	"╝"

SEVEN	=	"╠"
EIT	=	"╩"
NINE	=	"╦"
TEN	=	"╣"


local function drawbox(x , y , h , w)
	io.write("\27["..y..";"..x.."H");
	for i = 0 , h do
		for j = 0 , w do
			if i == 0 and j == 0 then
				io.write(THREE);
			elseif i == 0 and j == w then
				io.write(FIVE)
			elseif i == h and j == 0 then
				io.write(FOUR)
			elseif i == h and j == w then
				io.write(SIX)
			elseif (i == 0 and (j > 0 and j < w)) or (i == h and (j > 0 and j < w)) then
				io.write(ONE)
			elseif (j == 0 and (i > 0 and i < h)) or (j == w and (i > 0 and i < h)) then
				io.write(TWO)
			else
				io.write(" ")
			end
		end
		io.write("\n")
		for k = 1 , x - 1 do
			io.write("\27[1C")
		end
	end
end

io.write("\27[2J")

drawbox(34,12,25,50)
local x = 34 + (50 % 20)
local y = 12
io.write("\27["..y..";"..x.."H");
io.write("[Hello World]")

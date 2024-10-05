-- 
--	core_lua.lua 
--
--
--

-- module lua
lua_core = {}


-- creating objects
-- this object contains all new objects that created using create_object function
all_new_objects = {}

-- you can create global 

for_yield = coroutine.create(
	function()
		i = 0
		while true do
			i = i + 1
			coroutine.yield(i)
		end

	end
)

function lua_core.create_object(object_name)
	_ , index = coroutine.resume(for_yield)
	_G[object_name] = {}
	all_new_objects[index] = _G[object_name]
end

function get_last_index()
	_ , last = coroutine.resume(for_yield)
	return last - 1
end

--


global_count_enum = -1

local function enum(reset)
	reset = reset or false

	if reset then
		global_count_enum = -1
	end
	global_count_enum = global_count_enum + 1
	return global_count_enum
end

NONE = -1000

EXPLORER = enum(true)
STYLES = enum()
SEEK_RIGHT = enum()
SEEK_LEFT = enum()
VOLUME_UP = enum()
VOLUME_DOWN = enum()
STATUS = enum()
PAUSE = enum()
RESUME = enum()
SONG_NEXT = enum()
SONG_PREV = enum()
PAUSE_RESUME = PAUSE | RESUME

CURSOR_MOVE_UP	= enum()
CURSOR_MOVE_DOWN = enum()

FUZZING_SEARCH = enum()
DOWNLOAD_OVER_INTERNET = enum()
SETTINGS = enum()
-- manage alboms

KEY_A = enum(true)  
KEY_B = enum()     
KEY_C = enum()     
KEY_D = enum()     
KEY_E = enum()     
KEY_F = enum()     
KEY_M = enum()     
KEY_N = enum()     
KEY_O = enum()     
KEY_P = enum()     
KEY_Q = enum()     
KEY_R = enum()     
KEY_Y = enum()     
KEY_G = enum()
KEY_H = enum()
KEY_I = enum()
KEY_J = enum()
KEY_K = enum()
KEY_L = enum()
KEY_S = enum()
KEY_T = enum()
KEY_U = enum()
KEY_V = enum()
KEY_W = enum()
KEY_X = enum()
KEY_Z = enum()

KEY_SPACE 	= enum()
KEY_ESCAPE 	= enum()
KEY_UP 		= enum()
KEY_DOWN 	= enum()
KEY_LEFT 	= enum()
KEY_RIGHT 	= enum()

KEY_PLUS 	= enum()
KEY_MINUS 	= enum()
KEY_GT	 	= enum() -- ">"
KEY_LT 		= enum() -- "<"
KEY_TAB		= enum()

SHIFT_A = enum()  
SHIFT_B = enum()   
SHIFT_C = enum()   
SHIFT_D = enum()   
SHIFT_E = enum()   
SHIFT_F = enum()   
SHIFT_M = enum()   
SHIFT_N = enum()   
SHIFT_O = enum()   
SHIFT_P = enum()   
SHIFT_Q = enum()   
SHIFT_R = enum()   
SHIFT_Y = enum()   
SHIFT_G = enum()
SHIFT_H = enum()
SHIFT_I = enum()
SHIFT_J = enum()
SHIFT_K = enum()
SHIFT_L = enum()
SHIFT_S = enum()
SHIFT_T = enum()
SHIFT_U = enum()
SHIFT_V = enum()
SHIFT_W = enum()
SHIFT_X = enum()
SHIFT_Z = enum()

-- default rmp keys
KEYS = {}
 --
 -- 	setkey(KEY_SPACE,PAUSE_RESUME)
 -- 	setkey(KEY_GT,SONG_NEXT)
 -- 	setkey(KEY_LT,SONG_PREV)
 -- 	setkey(KEY_TAB,STATUS)
 -- 	setkey(KEY_RIGHT,SEEK_RIGHT)
 -- 	setkey(KEY_LEFT,SEEK_LEFT)
 -- 	setkey(KEY_E,EXPLORER)
 -- 	setkey(KEY_J,CURSOR_MOVE_DOWN)
 -- 	setkey(KEY_K,CURSOR_MOVE_UP)
 -- 	setkey(KEY_DOWN,CURSOR_MOVE_DOWN)
 -- 	setkey(KEY_UP,CURSOR_MOVE_UP)

function lua_core.setkey(key , value)
	if key >= KEY_A and key <= SHIFT_Z and value >= EXPLORER and value <= SETTINGS then
		KEYS[key] = value
		return true
	else
		return false
	end
end

-- border style

STYLE_ONE_BORDER = enum(true)
STYLE_TWO_BORDER = enum()

DEFAULT_BORDER = STYLE_ONE_BORDER

function lua_core.set_border(border)
	if border ~= STYLE_ONE_BORDER or border ~= STYLE_TWO_BORDER then
		DEFAULT_BORDER = STYLE_ONE_BORDER
	else
		DEFAULT_BORDER = border
	end
end

if DEFAULT_BORDER == STYLE_ONE_BORDER then
	ONE 	= "─"
	TWO 	= "│"
	THREE 	= "└"
	FOUR 	= "┌"
	FIVE 	= "┐"
	SIX 	= "┘"
	SEVEN	= ""
	EIT	= ""
	NINE	= ""
	TEN	= ""
elseif DEFAULT_BORDER == STYLE_TWO_BORDER then 
	ONE	=	"═"
	TWO	=	"║"
	THREE	=	"╚"
	FOUR	=	"╔"
	FIVE	=	"╗"
	SIX	=	"╝"

	SEVEN	=	"╠"
	EIT	=	"╩"
	NINE	=	"╦"
	TEN	=	"╣"
end

-- os detection
function lua_core.get_os()
	-- stolen from https://stackoverflow.com/questions/295052/how-can-i-determine-the-os-of-the-system-from-within-a-lua-script
	local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
	if BinaryFormat == "dll" then
		return "Windows"
	elseif BinaryFormat == "so" then
		return "Linux"
	elseif BinaryFormat == "dylib" then
		return "MacOS"
	end
end

return lua_core

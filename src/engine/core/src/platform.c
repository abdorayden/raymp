#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "simply.h"

enum {
	LINUX,
	WINDOWS,
	MAC,
	UNKOWN
};

ALWAYS_INT lua_platform(STATE){
#ifdef 	_WIN32
	lua_pushinteger(L, WINDOWS);
#elif	__linux__
	lua_pushinteger(L, LINUX);
#elif	__APPLE__
	lua_pushinteger(L, MAC);
#else
	lua_pushinteger(L, UNKOWN);
#endif
	return 1;
}

static const luaL_Reg lib[] = {
    {"platform", lua_platform},
    {NULL, NULL}
};

int luaopen_rmp_platform(STATE)
{
    luaL_newlib(L, lib);
    return 1;
}

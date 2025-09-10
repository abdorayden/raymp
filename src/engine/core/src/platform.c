#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

enum {
	LINUX,
	WINDOWS,
	MAC,
	UNKOWN
};

static int lua_platform(lua_State* L){
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

int luaopen_rmp_platform(lua_State *L)
{
    luaL_newlib(L, lib);
    return 1;
}

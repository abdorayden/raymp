// TODO: implements virtual terminal

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stdlib.h>
#include <string.h>

typedef struct {
	char ch;
	char style[16];
	char fg[16];
	char bg[16];
}Cell;

static int lua_init(lua_State* L) {
	return 1;
}

static const luaL_Reg lib[] = {
    {"init", lua_init},
    {NULL, NULL}
};

int luaopen_rmp_virtualterminalrmp(lua_State *L)
{
    luaL_newlib(L, lib);
    return 1;
}

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "simply.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

static void platform_sleep(int milliseconds)
{
    #ifdef _WIN32
    Sleep(milliseconds);
    #else
    usleep(milliseconds * 1000);
    #endif
}

ALWAYS_INT lua_sleep(STATE)
{
    int milliseconds = luaL_checkinteger(L, 1);
    platform_sleep(milliseconds);
    return 0;
}

static const luaL_Reg lib[] = {
    {"sleep", lua_sleep},
    {NULL, NULL}
};

int luaopen_rmp_sleep(STATE)
{
    luaL_newlib(L, lib);
    return 1;
}

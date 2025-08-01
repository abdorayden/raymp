#include <lua5.4/lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>

int lua_hello(lua_State *L) {
    lua_pushstring(L, "Hello from C!");
    return 1;
}

int lua_add(lua_State *L) {
    int a = luaL_checkinteger(L, 1);
    int b = luaL_checkinteger(L, 2);
    lua_pushinteger(L, a + b);
    return 1;
}

int lua_subtract(lua_State *L) {
    int a = luaL_checkinteger(L, 1);
    int b = luaL_checkinteger(L, 2);
    lua_pushinteger(L, a - b);
    return 1;
}

// Export functions for Lua
int luaopen_mylib(lua_State *L) {
    lua_newtable(L);
    lua_pushcfunction(L, lua_hello);
    lua_setfield(L, -2, "hello");

    lua_pushcfunction(L, lua_add);
    lua_setfield(L, -2, "add");

    lua_pushcfunction(L, lua_subtract);
    lua_setfield(L, -2, "subtract");

    return 1;
}

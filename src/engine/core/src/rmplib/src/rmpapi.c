#include "../include/rmp.h"
#include <string.h>
#include <stdlib.h>

// Global registry for shared data
static const char* RMP_SHARED_DATA_REGISTRY = "rmp_shared_data";

// Lua wrapper for virtual terminal garbage collection
static int lua_vt_gc_wrapper(lua_State* L) {
    VirtualTerminal** vt_ud = (VirtualTerminal**)luaL_checkudata(L, 1, "RMP.VirtualTerminal");
    if (*vt_ud) {
        rmp_vt_destroy(*vt_ud);
        *vt_ud = NULL;
    }
    return 0;
}

// Main RMP API implementation
// This file can be used to implement any global functions or initialization
// that needs to be done for the entire RMP library

// For now, this is just a placeholder that includes all the modules

// Lua integration functions
int rmp_lua_init(lua_State* L) {
    // Initialize all RMP modules
    // This function can be called to register all C functions with Lua
    return rmp_lua_register_functions(L);
}

int rmp_lua_register_functions(lua_State* L) {
    // Register all RMP C functions with Lua
    // This would typically involve luaL_setfuncs or luaL_register calls

    // For now, we'll just return success
    return 0;
}

// Function to get a virtual terminal pointer from Lua userdata
VirtualTerminal* rmp_get_vt_from_lua(lua_State* L, int index) {
    VirtualTerminal** vt_ud = (VirtualTerminal**)luaL_checkudata(L, index, "RMP.VirtualTerminal");
    if (vt_ud) {
        return *vt_ud;
    }
    return NULL;
}

// Function to push a virtual terminal pointer to Lua as userdata
int rmp_push_vt_to_lua(lua_State* L, VirtualTerminal* vt) {
    if (!vt) {
        lua_pushnil(L);
        return 1;
    }

    // Create userdata to hold the virtual terminal pointer
    VirtualTerminal** vt_ud = (VirtualTerminal**)lua_newuserdata(L, sizeof(VirtualTerminal*));
    *vt_ud = vt;

    // Set the metatable
    luaL_getmetatable(L, "RMP.VirtualTerminal");
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1); // Remove the nil

        // Create the metatable if it doesn't exist
        luaL_newmetatable(L, "RMP.VirtualTerminal");

        // Set up basic metamethods
        lua_pushstring(L, "__gc");
        lua_pushcfunction(L, lua_vt_gc_wrapper); // This will be handled by the actual destroy function
        lua_settable(L, -3);

        lua_pushstring(L, "__index");
        lua_pushvalue(L, -2);
        lua_settable(L, -3);
    }
    lua_setmetatable(L, -2);

    return 1;
}

// Function to share data between C and Lua
int rmp_share_data(lua_State* L, const char* key, void* data, size_t size) {
    if (!L || !key || !data) {
        return 0;
    }

    // Create a registry entry for shared data
    lua_getfield(L, LUA_REGISTRYINDEX, RMP_SHARED_DATA_REGISTRY);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1); // Remove nil
        lua_newtable(L); // Create new table
        lua_setfield(L, LUA_REGISTRYINDEX, RMP_SHARED_DATA_REGISTRY); // Store in registry
        lua_getfield(L, LUA_REGISTRYINDEX, RMP_SHARED_DATA_REGISTRY); // Get it back
    }

    // Create a copy of the data to store
    void* stored_data = malloc(size);
    if (!stored_data) {
        lua_pop(L, 1); // Remove the table
        return 0;
    }

    memcpy(stored_data, data, size);

    // Store the data in the table with the given key
    lua_pushlightuserdata(L, stored_data);
    lua_setfield(L, -2, key);

    lua_pop(L, 1); // Remove the table
    return 1;
}

// Function to get shared data between C and Lua
void* rmp_get_shared_data(lua_State* L, const char* key) {
    if (!L || !key) {
        return NULL;
    }

    // Get the shared data registry
    lua_getfield(L, LUA_REGISTRYINDEX, RMP_SHARED_DATA_REGISTRY);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1); // Remove nil
        return NULL;
    }

    // Get the data with the given key
    lua_getfield(L, -1, key);
    void* data = NULL;

    if (!lua_isnil(L, -1)) {
        data = lua_touserdata(L, -1);
    }

    lua_pop(L, 2); // Remove the value and the table
    return data;
}
// All the actual functionality is in the individual module files

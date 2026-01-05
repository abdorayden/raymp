#ifndef RMP_H_
#define RMP_H_

// Main RMP API header 

#include "rmp_directory.h"
#include "rmp_keyboard.h"
#include "rmp_platform.h"
#include "rmp_audio.h"
#include "rmp_socket.h"
#include "rmp_sleep.h"
#include "rmp_virtualterminal.h"
#include "rmp_window.h"

// #include "lua.h"
#include "../../../../lua/include/lua.h"
// #include "lauxlib.h"
#include "../../../../lua/include/lauxlib.h"
// #include "lualib.h"
#include "../../../../lua/include/lualib.h"

int rmp_lua_init(lua_State* L);

int rmp_lua_register_functions(lua_State* L);

VirtualTerminal* rmp_get_vt_from_lua(lua_State* L, int index);

int rmp_push_vt_to_lua(lua_State* L, VirtualTerminal* vt);

int rmp_share_data(lua_State* L, const char* key, void* data, size_t size);

void* rmp_get_shared_data(lua_State* L, const char* key);

#endif // RMP_H_

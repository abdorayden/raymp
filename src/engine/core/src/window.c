// standerd libc 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

// lua lib
#include <lua5.4/lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>

#ifndef _WIN32

// posix stuff
#include <sys/ioctl.h>
#include <unistd.h>

typedef struct winsize Size;

bool GetTermSize(lua_State* state){
	Size w;
	if(ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == -1){
		lua_pushnil(state);
		lua_pushnil(state);
		return false;
	}
	lua_pushinteger(state , w.ws_row);
	lua_pushinteger(state , w.ws_col);
	return true;
}

#else

// windows stuff
#include <windows.h>

typedef struct { 
	unsigned short int ws_row;
	unsigned short int ws_col;
}Size;

bool GetTermSize(lua_State* state){
	HWND hWnd = GetForegroundWindow();
	if(!hWnd){
		goto exit;
	}
	RECT rect;
	if (GetClientRect(hWnd, &rect)) {
		lua_pushinteger(state , rect.right);
		lua_pushinteger(state , rect.bottom);
		return true;
	} else {
		goto exit;
	}
	exit :{
		lua_pushnil(state);
		lua_pushnil(state);
		return false;
	}
}

#endif

// Table used to load handle_keys funtion and used in lua_core api
bool RMPCoreWindowdLib(lua_State *L) {
	lua_newtable(L);
	lua_pushcfunction(L, GetTermSize);
	lua_setfield(L, -2, "GetTermSize");
	return true;
}

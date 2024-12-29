// for testing lua scripts

// download lua source from offcial web site https://www.lua.org
// curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
//tar zxf lua-5.4.7.tar.gz
//cd lua-5.4.7
//make all test
// -I/path/to/lua_folder/src -L/path/to/lua_folder/src -l:liblua.a -lm


// or you can download it using
// sudo apt install liblua-<lua version>-dev
// and link it using -llua<lua version>
// to find lua headers use :
// find /usr/include -type f -name lua*
// or try :
// locate lua.h

#include <lua5.4/lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>
#include <stdio.h>

int main(void){

	lua_State *luafile;
	luafile = luaL_newstate();
	luaL_openlibs(luafile);
	if(luaL_loadfile(luafile, "./lua-plug/main.lua")){
		fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));
	}

	if (lua_pcall(luafile, 0, 0, 0) != LUA_OK)
		fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

	lua_getglobal(luafile , "setup");
	// 0 : params , 1 : for return
	if (lua_pcall(luafile, 0, 1, 0) != LUA_OK)
		fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

	//if(!lua_isnumber(luafile , -1))	fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

	//int abdo = lua_tointeger(luafile, -1);
		//lua_pop(luafile , 1);
		//printf("this for abdo %d\n" , abdo);

		//lua_getglobal(luafile , "add");
		//lua_pushnumber(luafile , 7);
		//lua_pushnumber(luafile , 3);
		//// 0 : params , 1 : for return
		//if (lua_pcall(luafile, 2, 1, 0) != LUA_OK)
		//	fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

		//if(!lua_isnumber(luafile , -1))	fprintf(stderr , "ERROR: could not load lua file script because of : %s" , lua_tostring(luafile, -1));

		//int add = lua_tointeger(luafile, -1);
		//lua_pop(luafile , 1);
		//printf("this for add %d\n" , add);


	lua_close(luafile);
	 //here the C file will print Hello World 
	 //main.lua contains :
	 //	print("Hello World")

	return 0;
}

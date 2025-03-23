#include "engine.h"
#include <stdio.h>

// TODO: check code
RMPEngine RMPEngineInit(const char* filename)
{
	RMPEngine rmp_engine = {0};
	// init luafile object
	lua_State *luafile = luaL_newstate();
	luaL_openlibs(luafile);

	if(filename == NULL){
		__rmp__is__error  = RMP_ERROR_ENGINE_FILENAME_NULL;
		printf("%d : RMPEngineError : filename is NULL" , __LINE__);
		goto forret;
	}
	// Load filename
	if(luaL_loadfile(luafile , filename) != LUA_OK){
		__rmp__is__error  = RMP_ERROR_LOAD_LUA_FILE;
		printf("%d : RMPEngineError : load lua file {%s}" , __LINE__ , lua_tostring(luafile , -1));
		goto forret;
		// if is_error the engine will run the default lua script
	}

forret:{

	       rmp_engine.luafile = luafile;
	       rmp_engine.filename = strdup(filename);
	       rmp_engine.status = __rmp__is__error;
	       return rmp_engine;
       }
}

RMPEngineError RMPEngineRun(RMPEngine entry)
{
	static int script_count = 0;

	if (lua_pcall(entry.luafile, 0, 0, 0) != LUA_OK){
		printf("%d : RMPEngineError : calling the file {%s}" , __LINE__ , lua_tostring(entry.luafile , -1));
		return RMP_ERROR_CALLING_MAIN_FUNCTION;
	}
	// TODO: push main parameter (waves)
	lua_getglobal(entry.luafile , "main");
	if (lua_pcall(entry.luafile, 0, 0, 0) != LUA_OK){
		printf("%d : RMPEngineError : run main function  {%s}" , __LINE__ , lua_tostring(entry.luafile , -1));
		return RMP_ERROR_CALLING_MAIN_FUNCTION;
	}

	//lua_pop(entry.luafile , 1);
	if(script_count < MAX_SCRIPTS)
		script_count++;
	return RMP_FINE;
}

void RMPEngineClose(RMPEngine* rmp_engine)
{
	lua_close(rmp_engine->luafile);
	RMP_FREE((void*)rmp_engine->filename);
}

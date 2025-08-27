#include "runner.h"
#include <stdio.h>
#include <string.h>

RMPRunner RMPRunnerInit(const char* filename)
{
	RMPRunner rmp_engine = {0};
	lua_State *luafile = luaL_newstate();
	luaL_openlibs(luafile);

	if(filename == NULL){
		__rmp__is__error  = RMP_ERROR_ENGINE_FILENAME_NULL;
		error = (error == NULL) ? strdup("filename is NULL") : error;
		goto forret;
	}
	if(luaL_loadfile(luafile , filename) != LUA_OK){
		__rmp__is__error  = RMP_ERROR_LOAD_LUA_FILE;
		printf("ERROR : %s\n",lua_tostring(luafile , -1));
		error = (error == NULL) ? strdup(lua_tostring(luafile , -1)) : error;
		goto forret;
	}

forret:{

	       rmp_engine.luafile = luafile;
	       rmp_engine.filename = strdup(filename);
	       rmp_engine.status = __rmp__is__error;
	       return rmp_engine;
       }
}

RMPRunnerError RMPRunnerRun(RMPRunner entry){
	if(error != NULL){
		return __rmp__is__error;
	}
	static int script_count = 0;
	if (lua_pcall(entry.luafile, 0, 0, 0) != LUA_OK){
		error = (error == NULL) ? strdup(lua_tostring(entry.luafile , -1)) : error;
		printf("ERROR : %s\n",lua_tostring(entry.luafile , -1));
		return RMP_ERROR_CALLING_MAIN_FUNCTION;
	}
	// TODO: push main parameter (waves)
	lua_getglobal(entry.luafile , "main");
	if (lua_pcall(entry.luafile, 0, 0, 0) != LUA_OK){
		error = (error == NULL) ? strdup(lua_tostring(entry.luafile , -1)) : error;
		printf("ERROR : %s\n",lua_tostring(entry.luafile , -1));
		return RMP_ERROR_CALLING_MAIN_FUNCTION;
	}

	if(script_count < MAX_SCRIPTS)
		script_count++;
	return RMP_FINE;
}

void RMPRunnerClose(RMPRunner* rmp_engine)
{
	lua_close(rmp_engine->luafile);
	RMP_FREE((void*)rmp_engine->filename);
	if(error != NULL){
		RMP_FREE(error);
		error = NULL;
	}
}

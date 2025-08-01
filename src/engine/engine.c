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



//#include "engine.h"
//#include <stdio.h>
//#include <unistd.h> // For usleep
//
//RMPEngine RMPEngineInit(const char* filename) {
//    RMPEngine engine = {0};
//    
//    if (!filename) {
//        fprintf(stderr, "Error: NULL filename\n");
//        engine.status = RMP_ERR;
//        return engine;
//    }
//
//    engine.L = luaL_newstate();
//    if (!engine.L) {
//        fprintf(stderr, "Error: Failed to create Lua state\n");
//        engine.status = RMP_ERR;
//        return engine;
//    }
//
//    luaL_openlibs(engine.L);
//    
//    // Load the main script
//    if (luaL_loadfile(engine.L, filename) != LUA_OK) {
//        fprintf(stderr, "Error loading %s: %s\n", filename, lua_tostring(engine.L, -1));
//        lua_close(engine.L);
//        engine.status = RMP_ERR;
//        return engine;
//    }
//
//    engine.filename = strdup(filename);
//    engine.status = RMP_OK;
//    engine.is_running = 1;
//    return engine;
//}
//
//RMPEngineError RMPEngineRun(RMPEngine engine) {
//    if (!engine.L || engine.status != RMP_OK) {
//        return RMP_ERROR_ENTRY_NULL;
//    }
//
//    // Call main() for initialization
//    lua_getglobal(engine.L, "main");
//    if (lua_pcall(engine.L, 0, 1, 0) != LUA_OK) {
//        fprintf(stderr, "Error in main(): %s\n", lua_tostring(engine.L, -1));
//        return RMP_ERROR_CALLING_MAIN_FUNCTION;
//    }
//
//    // Main loop
//    while (1) {
//        lua_getglobal(engine.L, "update");
//        if (!lua_isfunction(engine.L, -1)) {
//            lua_pop(engine.L, 1);
//            break;
//        }
//
//        int nres;
//        int res = lua_resume(engine.L, NULL, 0, &nres);
//        
//        if (res == LUA_YIELD) {
//            // Successful yield
//            if (nres > 0 && lua_isstring(engine.L, -1)) {
//                const char* msg = lua_tostring(engine.L, -1);
//                if (strcmp(msg, "quit") == 0) {
//                    lua_pop(engine.L, 1);
//                    break;
//                }
//            }
//            if (nres > 0) lua_pop(engine.L, nres);
//            usleep(16666); // ~60fps
//        }
//        else if (res != LUA_OK) {
//            fprintf(stderr, "Error in update: %s\n", lua_tostring(engine.L, -1));
//            lua_pop(engine.L, 1);
//            return RMP_ERROR_COROUTINE;
//        }
//        else {
//            // Update finished
//            if (nres > 0) lua_pop(engine.L, nres);
//            break;
//        }
//    }
//
//    // Call cleanup
//    lua_getglobal(engine.L, "cleanup");
//    if (lua_pcall(engine.L, 0, 0, 0) != LUA_OK) {
//        fprintf(stderr, "Error in cleanup(): %s\n", lua_tostring(engine.L, -1));
//    }
//
//    return RMP_FINE;
//}
//
//void RMPEngineClose(RMPEngine* engine) {
//    if (engine && engine->L) {
//        lua_close(engine->L);
//        engine->L = NULL;
//    }
//    if (engine && engine->filename) {
//        RMP_FREE((void*)engine->filename);
//        engine->filename = NULL;
//    }
//    engine->is_running = 0;
//}

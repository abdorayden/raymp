/*
 *	engine.h is header only library 
 *	contain functions to access and load and run scripts in main program
 *
 *						 ________________
 *		 _____________			|		 |
 *		|             |			| downloader.lua |
 *		|   ENGINE    | <-------------  | example.lua	 |
 *		|_____________|			| test.lua	 |
 *		      |				|________________|
 *		      |
 *		      |
 *		      |
 *		 ________________
 *		|		 |
 *		| Main Program   |
 *		|________________|
 *
 * */

#ifndef RMP_ENGINE
#define RMP_ENGINE

#ifndef RMP_MALLOC
	#define RMP_MALLOC	malloc
#endif

#ifndef RMP_REALLOC
	#define RMP_REALLOC	realloc
#endif

#ifndef RMP_FREE
	#define RMP_FREE	free
#endif

#ifndef RMP_UINT64
	#define RMP_UINT64 unsigned long long 	
#endif

#ifndef RMP_INT64
	#define RMP_INT64	long 
#endif

#ifndef RMP_UINT32
	#define RMP_UINT64 	unsigned int 	
#endif

#ifndef RMP_INT32
	#define RMP_INT64	int
#endif

#ifndef RMP_UINT16
	#define RMP_UINT64 	unsigned short 	
#endif

#ifndef RMP_INT16
	#define RMP_INT64	short
#endif

#ifndef RMP_UINT8
	#define RMP_UINT64 	unsigned char
#endif

#ifndef RMP_INT8
	#define RMP_INT64	char
#endif

// RMP API
#ifdef _WIN32
	#define RMP_DLL_IMPORT  __declspec(dllimport)
	#define RMP_DLL_EXPORT  __declspec(dllexport)
	#define RMP_DLL_PRIVATE static
#else
	#if defined(__GNUC__) && __GNUC__ >= 4
	    	#define RMP_DLL_IMPORT  __attribute__((visibility("default")))
	    	#define RMP_DLL_EXPORT  __attribute__((visibility("default")))
	    	#define RMP_DLL_PRIVATE __attribute__((visibility("hidden")))
	#else
	    	#define RMP_DLL_IMPORT
	    	#define RMP_DLL_EXPORT
	    	#define RMP_DLL_PRIVATE static
	#endif
#endif

#ifndef RMP_API
    #if defined(RMP_DLL)
        #ifdef RMP_ENGINE_IMPLEMENTATION
            #define RMP_API  RMP_DLL_EXPORT
        #else
            #define RMP_API  RMP_DLL_IMPORT
        #endif
    #else
        #define RMP_API extern
    #endif
#endif
// end RMP API

#define DEFAULT_RMP_SCRIPT	"lua-plug/main.lua"

//#define CORE_IMPLEMENTATION
//#include "./core.h"

typedef struct {
	lua_State * luafile;
	const char* filename;
}RMPEngine;

// @param filename script to load
RMP_API RMPEngine RMPEngineInit(const char*);

//@param void* point to the UI structure
RMP_API void RMPEngineLoadUI(void*);

RMP_API void RMPEngineClose(RMPEngine*);

#endif // RMP_ENGINE


#ifdef  RMP_ENGINE_IMPLEMENTATION

RMPEngine RMPEngineInit(const char* filename)
{
	RMPEngine rmp_engine = {0};
	// init luafile object
	lua_State *luafile = luaL_newstate();
	luaL_openlibs(luafile);
	// Load filename
	if(luaL_loadfile(luafile , filename) != LUA_OK || filename == NULL){
		is_error = engine_load_file_e;
		// if is_error the engine will run the default lua script
		if(luaL_loadfile(luafile , DEFAULT_RMP_SCRIPT) != LUA_OK){
			is_error = engine_failed;
			return ;
			//if is_error the engine will quit 
			// because the default script not found
		}

	}
	// calling the global main script
	// to enable calling the functions 
	if (lua_pcall(luafile, 0, 0, 0) != LUA_OK){
		is_error = engine_load_code;
		return ;
	}
	rmp_engine.luafile = luafile;
	rmp_engine.filename = filename;
	return rmp_engine;
}

//void RMPEngineLoadUI(void* ui)
//{
//	// after getting number of boxes from lua script
//#define BOX_COUNT	// number of boxes 
//	(UI*) ui;
//	ui->boxes = malloc(sizeof(Box)*);
//	// controle boxes using box_index from UI structure
//}

void RMPEngineClose(RMPEngine* rmp_engine)
{
	lua_close(rmp_engine->luafile);
}
#endif//RMP_ENGINE_IMPLEMENTATION

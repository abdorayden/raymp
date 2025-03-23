/*
 *	engine.h is header only library 
 *	contain functions to access and load and run scripts in main program
 *
 *						 ________________
 *		 _____________			|		 |
 *		|             |  parsing input	| downloader.lua |
 *		|   ENGINE    | <-------------  | example.lua	 |
 *		|_____________|			| test.lua	 |
 *		      |				|________________|
 *		      |
 *		      |
 *		      |
 *		 ______________
 *		|	       |
 *		| Main Program |
 *		|______________|
 *
 * */

#ifndef RMP_ENGINE
#define RMP_ENGINE

#ifndef LIST_INCLUDED
#include "../third_party/raylist.h"
#endif

// lua header files
// must be installed
//#include <lua5.4/lua.h>
//#include <lua5.4/lauxlib.h>
//#include <lua5.4/lualib.h>
#ifndef _WIN32
#include <lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>
#else
#include "./lua/include/lua.h"
// #include "./lua/include/lauxlib.h"
#include "./lua/include/lualib.h"
#endif

// TODO: handle miniaudio
// TODO: handle lua files

#define RMP_MALLOC	RLALLOC
#define RMP_REALLOC	RLREALLOC
#define RMP_FREE	RLFREE

typedef enum{
	RMP_ERROR_ENGINE_FILENAME_NULL,
	RMP_ERROR_LOAD_LUA_FILE,
	RMP_ERROR_CALLING_MAIN_FUNCTION,
	RMP_ERROR_ENTRY_NULL,
	RMP_FINE
}RMPEngineError;

static RMPEngineError __rmp__is__error = FINE;

typedef enum {
	ERR,
	OK
}RMPEngineStatus;

typedef struct {
	lua_State* luafile;
	const char* filename;
	RMPEngineStatus status;
}RMPEngine;

#define MAX_SCRIPTS	10

// @param filename script to load
RMPEngine RMPEngineInit(const char*);

//@param RMPEngine structure to handle and parse lua script
RMPEngineError  RMPEngineRun(RMPEngine);

void RMPEngineClose(RMPEngine*);

#endif // RMP_ENGINE


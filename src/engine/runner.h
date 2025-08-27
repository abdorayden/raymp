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

#ifndef RMP_RUNNER
#define RMP_RUNNER

// lua header files
// must be installed
//#include <lua5.4/lua.h>
//#include <lua5.4/lauxlib.h>
//#include <lua5.4/lualib.h>
#ifndef _WIN32
#include "./lua/include/lualib.h"
#include "./lua/include/lua.h"
#include "./lua/include/lauxlib.h"
/* #include <lua5.4/lauxlib.h> */
#else
#include "./lua/include/lua.h"
// #include "./lua/include/lauxlib.h"
#include "./lua/include/lualib.h"
#endif

// TODO: handle miniaudio
// TODO: handle lua files

#if !defined(RMP_MALLOC) || !defined(RMP_REALLOC) || !defined(RMP_FREE)
#include <stdlib.h>
#define RMP_MALLOC	malloc
#define RMP_REALLOC	realloc
#define RMP_FREE	free
#endif

typedef enum{
	RMP_ERROR_ENGINE_FILENAME_NULL,
	RMP_ERROR_LOAD_LUA_FILE,
	RMP_ERROR_CALLING_MAIN_FUNCTION,
	RMP_ERROR_ENTRY_NULL,
	RMP_FINE
}RMPRunnerError;

static RMPRunnerError __rmp__is__error = RMP_FINE;
static char* error = NULL;

typedef enum {
	ERR,
	OK
}RMPRunnerStatus;

typedef struct {
	lua_State* luafile;
	const char* filename;
	RMPRunnerStatus status;
}RMPRunner;

#define MAX_SCRIPTS	10

// @param filename script to load
RMPRunner RMPRunnerInit(const char*);

//@param RMPRunner structure to handle and parse lua script
RMPRunnerError  RMPRunnerRun(RMPRunner);

void RMPRunnerClose(RMPRunner*);

#endif // RMP_RUNNER

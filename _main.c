/****************************************************************************************/
/*  RMP - Ray's Music Player 								                            */
/*  											                                        */
/*  Copyright (c) 2025-2026 Ray Den 								                            */
/*  											                                        */
/*  Permission is hereby granted, free of charge, to any person obtaining a copy 	    */
/*  of this software and associated documentation files (the "Software"), to deal 	    */
/*  in the Software without restriction, including without limitation the rights 	    */
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 		    */
/*  copies of the Software, and to permit persons to whom the Software is 		        */
/*  furnished to do so, subject to the following conditions: 				            */
/*  											                                        */
/*  The above copyright notice and this permission notice shall be included in 		    */
/*  all copies or substantial portions of the Software. 				                */
/*  											                                        */
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 		    */
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		    */
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 	    */
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 		        */
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 	    */
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 		    */
/*  THE SOFTWARE. 									                                    */
/*  											                                        */
/****************************************************************************************/

// RMP Audio Engine - Multi-device support
// Powered by Lua scripting
// Elegant C implementation

#include "./src/engine/lua/include/lua.h"
#include "./src/engine/lua/include/lauxlib.h"
#include "./src/engine/lua/include/lualib.h"

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#define RMP_NAME "Ray's Music Player"
#define RMP_VERSION "1.0.0"
#define RMP_ENGINE_TAG "[RMP]"

void rmp_print_usage(char* progname)
{
	printf("RMP - %s v%s\n", RMP_NAME, RMP_VERSION);
	printf("Usage: %s [COMMAND] [OPTIONS]\n", progname);
	printf("\nCommands:\n");
	printf("  help        		Display this help message\n");
	/* printf("  init 		       	Create plugin architecture directory with development environment\n"); */
	/* printf("  test	        	Create empty window to test your plugin\n"); */
	printf("\nOptions:\n");
	printf("  --help 	, -h    Display this help message\n");
	printf("  --version 	, -v    Display RMP Version\n");
}

char* rmp_shift_args(int argc, char** argv)
{
	if(argc <= 1) {
		return NULL;
	}

	static int rmp_index = 0;

	if(rmp_index >= argc) {
		return NULL;
	}

	return argv[rmp_index++];
}

int main(int argc, char** argv)
{
    // skip program name
	rmp_shift_args(argc, argv);

	for(int i = 1; i < argc; i++){
		if(
				strcmp(argv[i], "--help") == 0 ||
				strcmp(argv[i], "-h") == 0 ||
				strcmp(argv[i], "/?") == 0 ||
				strcmp(argv[i], "-help") == 0 ||
				strcmp(argv[i], "/help") == 0 ||
				strcmp(argv[i], "help") == 0
		  ){
			rmp_print_usage(argv[0]);
			return 0;
		}
	}

	// Parse command from arguments
	char* rmp_command = rmp_shift_args(argc - 1, argv);
	if(rmp_command != NULL) {
		if(strcmp(rmp_command, "help") == 0) {
			rmp_print_usage(argv[0]);
			return 0;
		}
		/* else if(strcmp(rmp_command, "init") == 0) { */
		/* 	printf("RMP Init command called\n"); */
		/* } else if(strcmp(rmp_command, "test") == 0) { */
		/* 	printf("RMP Test command called\n"); */
		/* } */
	}

	lua_State *RMP_LUA_STATE = luaL_newstate();
	if (RMP_LUA_STATE == NULL) {
		fprintf(stderr, "%s Failed to create RMP Lua Engine state.\n", RMP_ENGINE_TAG);
		return 1;
	}

	luaL_openlibs(RMP_LUA_STATE);

	if (luaL_dostring(RMP_LUA_STATE, "require('rmp.RMPManager')") != LUA_OK){
		fprintf(stderr, "%s Cannot execute RMP Engine Lua code: %s\n", RMP_ENGINE_TAG, lua_tostring(RMP_LUA_STATE, -1));
		lua_pop(RMP_LUA_STATE, 1);
	    lua_close(RMP_LUA_STATE);
        return 1;
	}

	lua_close(RMP_LUA_STATE);
	return 0;
}

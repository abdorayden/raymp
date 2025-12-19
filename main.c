/****************************************************************************************/
/*  Copyright (c) 2025 Ray Den 								*/
/*  											*/ 
/*  Permission is hereby granted, free of charge, to any person obtaining a copy 	*/
/*  of this software and associated documentation files (the "Software"), to deal 	*/
/*  in the Software without restriction, including without limitation the rights 	*/
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 		*/
/*  copies of the Software, and to permit persons to whom the Software is 		*/
/*  furnished to do so, subject to the following conditions: 				*/
/*  											*/ 
/*  The above copyright notice and this permission notice shall be included in 		*/
/*  all copies or substantial portions of the Software. 				*/
/*  											*/ 
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 		*/
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		*/
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 	*/
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 		*/
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 	*/
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 		*/
/*  THE SOFTWARE. 									*/
/*  											*/ 
/****************************************************************************************/

// make audio choose multi devices headphones and more ...

// gcc is all you need :)

// untested and buggable code below
// this is a new implementation of the RMP engine in C using Lua API

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

void print_help(char* progname)
{
	printf("Usage: %s [COMMAND] [OPTIONS]\n", progname);
	printf("Command:\n");
	printf("  help        		Show this help message\n");
	/* printf("  init 		       	create plugin architecture directory , with evirement developement\n"); */
	/* printf("  test	        	create empty window , used to test your plugin \n"); */
	printf("Options:\n");
	printf("  --help 	, -h    Show this help message\n");
	printf("  --version 	, -v    Show RMP Version\n");
}

char* shift_args(int argc , char** argv)
{
	if(argc <= 1) {
		return NULL;
	}

	static int index = 0;

	if(index >= argc) {
		return NULL;
	}

	return argv[index++];
}

// TODO: rewrite RMPManger engine in C
int main(int argc , char** argv)
{

	char* program = shift_args(argc , argv);
	if(program == NULL) {
		// unreachable
	}

	for(int i = 0 ; i < argc ; i++){
		if(
				strcmp(argv[i] , "--help") == 0 || 
				strcmp(argv[i] , "-h") == 0 ||
				strcmp(argv[i] , "/?") == 0 ||
				strcmp(argv[i] , "-help") == 0 ||
				strcmp(argv[i] , "/help") == 0 ||
				strcmp(argv[i] , "help") == 0
		  ){
			print_help(argv[0]);
			return 0;
		}
	}

	char* command = shift_args(argc - 1 , argv);
	if(command != NULL) {
		if(strcmp(command , "help") == 0) {
			print_help(argv[0]);
			return 0;
		} 
		/* else if(strcmp(command , "init") == 0) { */
		/* 	printf("Init command called\n"); */
		/* } else if(strcmp(command , "test") == 0) { */
		/* 	printf("Test command called\n"); */
		/* } */
	}

	lua_State *L = luaL_newstate();
	if (L == NULL) {
		fprintf(stderr, "[RMP] failed creating Engine Lua state.\n");
		return 1;
	}

	luaL_openlibs(L);

	if (luaL_dostring(L , "require('rmp.RMPManager')") != LUA_OK){
		fprintf(stderr, "[RMP] cannot execute Engine Lua code: %s\n", lua_tostring(L, -1));
		lua_pop(L, 1);
	    lua_close(L);
        return 1;
	}
	lua_close(L);
	return 0;
}

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
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "simply.h"

enum {
	LINUX,
	WINDOWS,
	MAC,
	UNKOWN
};

ALWAYS_INT lua_platform(STATE){
#ifdef 	_WIN32
	lua_pushinteger(L, WINDOWS);
#elif	__linux__
	lua_pushinteger(L, LINUX);
#elif	__APPLE__
	lua_pushinteger(L, MAC);
#else
	lua_pushinteger(L, UNKOWN);
#endif
	return 1;
}

static const luaL_Reg lib[] = {
    {"platform", lua_platform},
    {NULL, NULL}
};

int luaopen_rmp_platform(STATE)
{
    luaL_newlib(L, lib);
    return 1;
}

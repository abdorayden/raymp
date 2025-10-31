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

/*
 * 	this file is part of core engine 
 * 	keyboard_lua.c - Cross-platform keyboard input library for Lua
 * 	Supports Windows, Linux, and macOS with non-blocking input
 */
#include <stdbool.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "simply.h"

typedef enum {
    MOUSE_LEFT_PRESS,MOUSE_RIGHT_PRESS,
    MOUSE_MIDDLE_PRESS,MOUSE_RELEASE, 
    MOUSE_LEFT_DRAG, MOUSE_MIDDLE_DRAG, 
    MOUSE_RIGHT_DRAG, MOUSE_SCROLL_UP, 
    MOUSE_SCROLL_DOWN
}MouseActions;

#if defined(_WIN32) || defined(_WIN64)
// Windows implementation
#include <windows.h>
#else

#endif

static const luaL_Reg keyboard_lib[] = {
	{NULL, NULL}
};

int luaopen_rmp_keyboard(STATE) {
	luaL_newlib(L, keyboard_lib);
	return 1;
}

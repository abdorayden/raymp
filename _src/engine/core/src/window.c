/****************************************************************************************/
/*  Copyright (c) 2025-2026 Ray Den 								*/
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
//
// standard libc
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "simply.h"

// lua
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#ifndef _WIN32
// POSIX
#include <sys/ioctl.h>
#include <unistd.h>
#include <termios.h>   // for struct winsize on some platforms

static struct termios orig_termios;
ALWAYS_INT raw_mode_enabled = 0;

ALWAYS_INT lua_raw_mode(STATE) {
	int enable = lua_toboolean(L, 1);

	if (enable && !raw_mode_enabled) {
		struct termios raw;

		if (tcgetattr(STDIN_FILENO, &orig_termios) == -1) {
			lua_pushboolean(L, 0);
			return 1;
		}

		raw = orig_termios;
		raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
		raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
		raw.c_cflag |= (CS8);
		raw.c_oflag &= ~(OPOST);
		raw.c_cc[VMIN] = 1;
		raw.c_cc[VTIME] = 0;

		if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == -1) {
			lua_pushboolean(L, 0);
			return 1;
		}

		raw_mode_enabled = 1;
	}
	else if (!enable && raw_mode_enabled) {
		tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios);
		raw_mode_enabled = 0;
	}

	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_get_size(STATE) {
	struct winsize w;
	if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == -1) {
		lua_pushnil(L);
		lua_pushnil(L);
		return 2;
	}
	lua_pushinteger(L, (lua_Integer)w.ws_row);
	lua_pushinteger(L, (lua_Integer)w.ws_col);
	return 2;
}

#else
// Windows
#include <windows.h>

static CONSOLE_SCREEN_BUFFER_INFO orig_csbi;
static DWORD orig_mode;
ALWAYS_INT raw_mode_enabled = 0;

ALWAYS_INT lua_raw_mode(STATE) {
	int enable = lua_toboolean(L, 1);
	HANDLE hIn = GetStdHandle(STD_INPUT_HANDLE);
	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);

	if (enable && !raw_mode_enabled) {
		GetConsoleMode(hIn, &orig_mode);
		SetConsoleMode(hIn, orig_mode & ~(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT));

		GetConsoleScreenBufferInfo(hOut, &orig_csbi);
		COORD size = {9999, 9999};
		SetConsoleScreenBufferSize(hOut, size);

		raw_mode_enabled = 1;
	}
	else if (!enable && raw_mode_enabled) {
		SetConsoleMode(hIn, orig_mode);
		SetConsoleScreenBufferSize(hOut, orig_csbi.dwSize);
		raw_mode_enabled = 0;
	}

	lua_pushboolean(L, 1);
	return 1;
}


ALWAYS_INT lua_get_size(STATE) {
	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
	if (hOut == INVALID_HANDLE_VALUE || hOut == NULL) {
		lua_pushnil(L);
		lua_pushnil(L);
		return 2;
	}

	CONSOLE_SCREEN_BUFFER_INFO csbi;
	if (!GetConsoleScreenBufferInfo(hOut, &csbi)) {
		lua_pushnil(L);
		lua_pushnil(L);
		return 2;
	}

	SHORT rows = (SHORT)(csbi.srWindow.Bottom - csbi.srWindow.Top + 1);
	SHORT cols = (SHORT)(csbi.srWindow.Right  - csbi.srWindow.Left + 1);

	lua_pushinteger(L, (lua_Integer)rows);
	lua_pushinteger(L, (lua_Integer)cols);
	return 2;
}
#endif

static const luaL_Reg lib[] = {
	{"get_size", lua_get_size},
	{"raw_mode", lua_raw_mode},

	{NULL, NULL}
};

// Module entry point: require("window")
int luaopen_rmp_window(STATE) {
	luaL_newlib(L, lib);
	return 1;
}

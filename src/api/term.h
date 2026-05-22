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

#ifndef TERM_H
#define TERM_H

#include <stdbool.h>
#include "../third_party/rdn/rdn_native.h"

#ifndef _WIN32
// POSIX
#include <sys/ioctl.h>
#include <unistd.h>
#include <termios.h>   // for struct winsize on some platforms

static struct termios orig_termios;
static int raw_mode_enabled = 0;


static bool initialized = false;

#else
// Windows
#include <windows.h>

static CONSOLE_SCREEN_BUFFER_INFO orig_csbi;
static DWORD orig_mode;
ALWAYS_INT raw_mode_enabled = 0;

// for restore the terminal
static bool initialized = false;
static HANDLE hStdin;
static DWORD oldMode;
#endif

bool rmp_to_raw_mode(RDNApi* api);
bool rmp_get_term_size(RDNApi* api);
bool init_terminal(RDNApi* api);
bool restore_terminal(RDNApi* api);
bool rmp_term_clear(RDNApi* api);
bool rmp_term_hide_cursor(RDNApi* api);
bool rmp_term_show_cursor(RDNApi* api);
#endif // !TERM_H

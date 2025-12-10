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

#ifndef VIRTUALTERMINALRMP_C
#define VIRTUALTERMINALRMP_C

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "luaconf.h"

#include "simply.h"

#ifdef _WIN32
    #define PLATFORM_WINDOWS
    #include <windows.h>
    #include <io.h>
    #include <fcntl.h>
#elif defined(__unix__) || defined(__unix) || (defined(__APPLE__) && defined(__MACH__))
    #define PLATFORM_UNIX
    #define _XOPEN_SOURCE
#endif

#include <wchar.h>
#include <locale.h>

#ifndef PLATFORM_WINDOWS
    #include <uchar.h>   // optional for char32_t, not strictly required on Unix
#endif

// Cross-platform wcwidth implementation
// i added a simple wcwidth implementation for windows
// on unix we can just use the system wcwidth
// for more cross platform handling
#ifdef PLATFORM_WINDOWS
    ALWAYS_INT wcwidth_impl(wchar_t wc) {
        if (wc == 0) return 0;
        if (wc < 32 || wc == 127) return 0; 
        if (wc < 127) return 1; 
        
        if ((wc >= 0x1100 && wc <= 0x115F) ||  // Hangul Jamo
            (wc >= 0x2E80 && wc <= 0x2EFF) ||  // CJK Radicals Supplement
            (wc >= 0x2F00 && wc <= 0x2FDF) ||  // Kangxi Radicals
            (wc >= 0x3000 && wc <= 0x303F) ||  // CJK Symbols and Punctuation
            (wc >= 0x3040 && wc <= 0x309F) ||  // Hiragana
            (wc >= 0x30A0 && wc <= 0x30FF) ||  // Katakana
            (wc >= 0x3100 && wc <= 0x312F) ||  // Bopomofo
            (wc >= 0x3130 && wc <= 0x318F) ||  // Hangul Compatibility Jamo
            (wc >= 0x3190 && wc <= 0x319F) ||  // Kanbun
            (wc >= 0x31A0 && wc <= 0x31BF) ||  // Bopomofo Extended
            (wc >= 0x31C0 && wc <= 0x31EF) ||  // CJK Strokes
            (wc >= 0x31F0 && wc <= 0x31FF) ||  // Katakana Phonetic Extensions
            (wc >= 0x3200 && wc <= 0x32FF) ||  // Enclosed CJK Letters and Months
            (wc >= 0x3300 && wc <= 0x33FF) ||  // CJK Compatibility
            (wc >= 0x3400 && wc <= 0x4DBF) ||  // CJK Unified Ideographs Extension A
            (wc >= 0x4E00 && wc <= 0x9FFF) ||  // CJK Unified Ideographs
            (wc >= 0xA000 && wc <= 0xA48F) ||  // Yi Syllables
            (wc >= 0xA490 && wc <= 0xA4CF) ||  // Yi Radicals
            (wc >= 0xAC00 && wc <= 0xD7AF) ||  // Hangul Syllables
            (wc >= 0xF900 && wc <= 0xFAFF) ||  // CJK Compatibility Ideographs
            (wc >= 0xFE10 && wc <= 0xFE1F) ||  // Vertical Forms
            (wc >= 0xFE30 && wc <= 0xFE4F) ||  // CJK Compatibility Forms
            (wc >= 0xFE50 && wc <= 0xFE6F) ||  // Small Form Variants
            (wc >= 0xFF00 && wc <= 0xFFEF)) {  // Halfwidth and Fullwidth Forms
            return 2;
        }
        
        return 1;
    }
    #define wcwidth wcwidth_impl
#else
    int wcwidth(wchar_t);
#endif

#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define CH_UTF8_SIZE    64*2
#define CH_STRYLE_AND_COLOR_SIZE    64

typedef struct {
	char ch[CH_UTF8_SIZE];
	char style[CH_STRYLE_AND_COLOR_SIZE];
	char fg[CH_STRYLE_AND_COLOR_SIZE];
	char bg[CH_STRYLE_AND_COLOR_SIZE];
}Cell;

typedef struct {
	unsigned short width;
	unsigned short height;
	unsigned short cursor_x;
	unsigned short cursor_y;
	bool is_dirty;
	Cell* buffer;

}VirtualTerminal;

#define VT_MT "RMP.VirtualTerminal"

static Cell* get_cell(VirtualTerminal* vt, unsigned short x, unsigned short y) {
	// x and y is unsigned short so i don't have to worry about negative value 
	// but whatever im gonna keep this condition
	if (x < 1 || x > vt->width || y < 1 || y > vt->height) {
		return NULL;
	}
	return &(vt->buffer[(y-1) * vt->width + (x-1)]);
}


static void init_locale() {
#ifdef PLATFORM_WINDOWS
    setlocale(LC_CTYPE, ".UTF8");
    if (setlocale(LC_CTYPE, NULL) == NULL) {
        setlocale(LC_CTYPE, "");
    }
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
#else
    setlocale(LC_CTYPE, "");
#endif
}

ALWAYS_INT lua_init(STATE) {
	int width = luaL_optinteger(L , 1 , 150);
	int height = luaL_optinteger(L , 2 , 1);

	if (width <= 0 || height <= 0) {
		lua_pushnil(L);
		lua_pushstring(L, "Invalid dimensions: width and height must be positive");
		return 2;
	}

	if (width > SIZE_MAX / height / sizeof(Cell)) {
		lua_pushnil(L);
		lua_pushstring(L, "Dimensions too large: potential overflow");
		return 2;
	}

	init_locale();

	size_t vt_size = sizeof(VirtualTerminal);
	VirtualTerminal* vt = (VirtualTerminal*)lua_newuserdata(L , vt_size);
	if (!vt) {
		lua_pushnil(L);
		lua_pushstring(L, "Failed to create virtual terminal userdata");
		return 2;
	}

	vt->width = width;
	vt->height = height;
	vt->cursor_x = 1;
	vt->cursor_y = 1;
	vt->is_dirty = true;

	size_t buffer_vt_size = width*height*sizeof(Cell);
	vt->buffer = (Cell*)malloc(buffer_vt_size);
	if (vt->buffer == NULL) {
		lua_pushnil(L);
		lua_pushstring(L, "Failed to allocate memory for virtual terminal buffer");
		return 2;
	}

	luaL_getmetatable(L, VT_MT);
	lua_setmetatable(L, -2);

	for (int i = 0; i < width * height; i++) {
		strcpy(vt->buffer[i].ch, " ");
		strcpy(vt->buffer[i].fg, "");
		strcpy(vt->buffer[i].bg, "");
		strcpy(vt->buffer[i].style, "");
	}
	return 1;
}

ALWAYS_INT lua_distroy(STATE){
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	free(vt->buffer);
	vt->buffer = NULL;
	return 0;
}

ALWAYS_INT vt_lua_gc(STATE) {
    return lua_distroy(L);
}

ALWAYS_INT lua_clear(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);

	if (!vt || !vt->buffer) {
		return 0;
	}

	size_t total_size = vt->width * vt->height;

	for (size_t i = 0; i < total_size; i++) {
		Cell* cell = &vt->buffer[i];
		cell->ch[0] = ' ';
		cell->ch[1] = '\0';
		cell->fg[0] = '\0';
		cell->bg[0] = '\0';
		cell->style[0] = '\0';
	}
	vt->is_dirty = true;
	return 0;
}

#ifdef PLATFORM_WINDOWS
    #ifndef MB_CUR_MAX
        #define MB_CUR_MAX 4
    #endif
#endif

static const char* next_utf8_char_info(const char* str, int* byte_len, int* disp_width) {
	if (!str || !*str) {
		if (byte_len) *byte_len = 0;
		if (disp_width) *disp_width = 0;
		return str;
	}

	mbstate_t st;
	memset(&st, 0, sizeof(st));
	wchar_t wc;
	size_t ret = mbrtowc(&wc, str, MB_CUR_MAX, &st);
	if (ret == (size_t)-1 || ret == (size_t)-2) {
		if (byte_len) *byte_len = 1;
		if (disp_width) *disp_width = 1;
		return str;
	}

	if (byte_len) *byte_len = (int)ret;
	int w = wcwidth(wc);
	if (w < 0) w = 0;
	if (disp_width) *disp_width = w;
	return str;
}

ALWAYS_INT lua_setchar(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int x = luaL_checkinteger(L, 2);
	int y = luaL_checkinteger(L, 3);
	const char* ch = luaL_optstring(L, 4, " ");
	const char* fg = luaL_optstring(L, 5, "");
	const char* bg = luaL_optstring(L, 6, "");
	const char* style = luaL_optstring(L, 7, "");
	Cell* cell = get_cell(vt, x, y);
	if (cell) {
		strncpy(cell->ch, ch, CH_UTF8_SIZE - 1);
		cell->ch[CH_UTF8_SIZE - 1] = '\0';
		strncpy(cell->fg, fg, sizeof(cell->fg) - 1);
		cell->fg[sizeof(cell->fg)-1] = '\0';
		strncpy(cell->bg, bg, sizeof(cell->bg) - 1);
		cell->bg[sizeof(cell->bg)-1] = '\0';
		strncpy(cell->style, style, sizeof(cell->style) - 1);
		cell->style[sizeof(cell->style)-1] = '\0';
		vt->is_dirty = true;
	}
	return 0;
}


ALWAYS_INT lua_writetext_clipped(STATE) {
    VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    size_t text_len;
    const char* text = luaL_checklstring(L, 4, &text_len);
    int max_cols = luaL_checkinteger(L, 5);
    const char* fg = luaL_optstring(L, 6, "");
    const char* bg = luaL_optstring(L, 7, "");
    const char* style = luaL_optstring(L, 8, "");

    int start_x = x;
    int current_x = x;
    const char* ptr = text;
    const char* end = text + text_len;

    while (ptr < end && current_x <= vt->width && (current_x - start_x) < max_cols) {
        int byte_len = 0, disp_width = 0;
        next_utf8_char_info(ptr, &byte_len, &disp_width);
        if (byte_len <= 0) break;
        if (ptr + byte_len > end) byte_len = (int)(end - ptr);

        if (disp_width == 0) {
            int base_x = current_x - 1;
            while (base_x >= start_x) {
                Cell* base = get_cell(vt, base_x, y);
                if (!base) { base_x--; continue; }
                if (base->ch[0] == '\0') { base_x--; continue; } 
                size_t existing = strlen(base->ch);
                int can_copy = CH_UTF8_SIZE - 1 - (int)existing;
                if (can_copy > 0) {
                    int to_copy = (byte_len < can_copy) ? byte_len : can_copy;
                    memcpy(base->ch + existing, ptr, to_copy);
                    base->ch[existing + to_copy] = '\0';
                }
                if (fg && fg[0]) { strncpy(base->fg, fg, sizeof(base->fg)-1); base->fg[sizeof(base->fg)-1] = '\0'; }
                if (bg && bg[0]) { strncpy(base->bg, bg, sizeof(base->bg)-1); base->bg[sizeof(base->bg)-1] = '\0'; }
                if (style && style[0]) { strncpy(base->style, style, sizeof(base->style)-1); base->style[sizeof(base->style)-1] = '\0'; }
                break;
            }
            ptr += byte_len;
            continue;
        }

        int consumed = current_x - start_x;
        if (consumed + disp_width > max_cols) {
            break;
        }

        if (current_x > vt->width) break;
        Cell* cell = get_cell(vt, current_x, y);
        if (cell) {
            int to_copy = (byte_len < CH_UTF8_SIZE - 1) ? byte_len : (CH_UTF8_SIZE - 1);
            memcpy(cell->ch, ptr, to_copy);
            cell->ch[to_copy] = '\0';
            strncpy(cell->fg, fg, sizeof(cell->fg)-1); cell->fg[sizeof(cell->fg)-1] = '\0';
            strncpy(cell->bg, bg, sizeof(cell->bg)-1); cell->bg[sizeof(cell->bg)-1] = '\0';
            strncpy(cell->style, style, sizeof(cell->style)-1); cell->style[sizeof(cell->style)-1] = '\0';

            if (disp_width > 1) {
                for (int k = 1; k < disp_width; ++k) {
                    Cell* cont = get_cell(vt, current_x + k, y);
                    if (!cont) break;
                    cont->ch[0] = '\0';
                    strncpy(cont->fg, fg, sizeof(cont->fg)-1); cont->fg[sizeof(cont->fg)-1] = '\0';
                    strncpy(cont->bg, bg, sizeof(cont->bg)-1); cont->bg[sizeof(cont->bg)-1] = '\0';
                    strncpy(cont->style, style, sizeof(cont->style)-1); cont->style[sizeof(cont->style)-1] = '\0';
                }
            }
        }

        current_x += (disp_width > 0) ? disp_width : 1;
        ptr += byte_len;
    }

    while ((current_x - start_x) < max_cols && current_x <= vt->width) {
        Cell* c = get_cell(vt, current_x, y);
        if (c) {
            strcpy(c->ch, " ");
            c->fg[0] = '\0';
            c->bg[0] = '\0';
            c->style[0] = '\0';
        }
        current_x++;
    }

    vt->is_dirty = true;
    int cols_written = current_x - start_x;
    lua_pushinteger(L, cols_written);
    return 1;
}

ALWAYS_INT lua_writetext(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int x = luaL_checkinteger(L, 2);
	int y = luaL_checkinteger(L, 3);
	size_t text_len;
	const char* text = luaL_checklstring(L, 4, &text_len);
	const char* fg = luaL_optstring(L, 5, "");
	const char* bg = luaL_optstring(L, 6, "");
	const char* style = luaL_optstring(L, 7, "");
	int current_x = x;
	const char* ptr = text;
	const char* end = text + text_len;

	while (ptr < end) {
		int byte_len = 0;
		int disp_width = 0;
		next_utf8_char_info(ptr, &byte_len, &disp_width);
		if (byte_len <= 0) break;
		if (ptr + byte_len > end) byte_len = (int)(end - ptr);

		if (disp_width == 0) {
			int base_x = current_x - 1;
			while (base_x >= x) {
				Cell* base = get_cell(vt, base_x, y);
				if (!base) break;
				if (base->ch[0] == '\0' || (base->ch[0] == ' ' && base_x == x)) {
					base_x--;
					continue;
				}
				size_t existing = strlen(base->ch);
				int can_copy = (CH_UTF8_SIZE - 1) - (int)existing;
				if (can_copy > 0) {
					int to_copy = (byte_len < can_copy) ? byte_len : can_copy;
					memcpy(base->ch + existing, ptr, to_copy);
					base->ch[existing + to_copy] = '\0';
				}
				if (fg && fg[0]) {
					strncpy(base->fg, fg, sizeof(base->fg)-1);
					base->fg[sizeof(base->fg)-1] = '\0';
				}
				if (bg && bg[0]) {
					strncpy(base->bg, bg, sizeof(base->bg)-1);
					base->bg[sizeof(base->bg)-1] = '\0';
				}
				if (style && style[0]) {
					strncpy(base->style, style, sizeof(base->style)-1);
					base->style[sizeof(base->style)-1] = '\0';
				}
				break;
			}
			if (base_x < x) {
				Cell* cell = get_cell(vt, current_x, y);
				if (cell) {
					int to_copy = (byte_len < CH_UTF8_SIZE - 1) ? byte_len : (CH_UTF8_SIZE - 1);
					memcpy(cell->ch, ptr, to_copy);
					cell->ch[to_copy] = '\0';
					strncpy(cell->fg, fg, sizeof(cell->fg)-1);
					cell->fg[sizeof(cell->fg)-1] = '\0';
					strncpy(cell->bg, bg, sizeof(cell->bg)-1);
					cell->bg[sizeof(cell->bg)-1] = '\0';
					strncpy(cell->style, style, sizeof(cell->style)-1);
					cell->style[sizeof(cell->style)-1] = '\0';
				}
				current_x += 1;
			}
			ptr += byte_len;
			continue;
		}

		if (current_x > vt->width) break;
		Cell* cell = get_cell(vt, current_x, y);
		if (cell) {
			int to_copy = (byte_len < CH_UTF8_SIZE - 1) ? byte_len : (CH_UTF8_SIZE - 1);
			memcpy(cell->ch, ptr, to_copy);
			cell->ch[to_copy] = '\0';
			strncpy(cell->fg, fg, sizeof(cell->fg)-1);
			cell->fg[sizeof(cell->fg)-1] = '\0';
			strncpy(cell->bg, bg, sizeof(cell->bg)-1);
			cell->bg[sizeof(cell->bg)-1] = '\0';
			strncpy(cell->style, style, sizeof(cell->style)-1);
			cell->style[sizeof(cell->style)-1] = '\0';
			if (disp_width > 1) {
				for (int k = 1; k < disp_width; ++k) {
					Cell* cont = get_cell(vt, current_x + k, y);
					if (!cont) break;
					cont->ch[0] = '\0';
					strncpy(cont->fg, fg, sizeof(cont->fg)-1);
					cont->fg[sizeof(cont->fg)-1] = '\0';
					strncpy(cont->bg, bg, sizeof(cont->bg)-1);
					cont->bg[sizeof(cont->bg)-1] = '\0';
					strncpy(cont->style, style, sizeof(cont->style)-1);
					cont->style[sizeof(cont->style)-1] = '\0';
				}
			}
		}

		current_x += (disp_width > 0) ? disp_width : 1;
		ptr += byte_len;
	}

	vt->is_dirty = true;
	return 0;
}

ALWAYS_INT lua_merge(STATE) {
	VirtualTerminal* dest_vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	VirtualTerminal* src_vt = (VirtualTerminal*)luaL_checkudata(L, 2, VT_MT);
	int offset_x = luaL_optinteger(L, 3, 0);
	int offset_y = luaL_optinteger(L, 4, 0);

	if (!dest_vt || !dest_vt->buffer || !src_vt || !src_vt->buffer) {
		return 0;
	}

	int start_src_y = 1;
	int end_src_y = src_vt->height;
	int start_src_x = 1;
	int end_src_x = src_vt->width;

	int start_dest_y = 1 + offset_y;
	int end_dest_y = src_vt->height + offset_y;
	int start_dest_x = 1 + offset_x;
	int end_dest_x = src_vt->width + offset_x;

	if (start_dest_y < 1) start_src_y = 1 - offset_y;
	if (end_dest_y > dest_vt->height) end_src_y = dest_vt->height - offset_y;
	if (start_dest_x < 1) start_src_x = 1 - offset_x;
	if (end_dest_x > dest_vt->width) end_src_x = dest_vt->width - offset_x;

	if (start_src_y > end_src_y || start_src_x > end_src_x) {
		dest_vt->is_dirty = true;
		return 0;
	}

	for (int src_y = start_src_y; src_y <= end_src_y && src_y <= src_vt->height; src_y++) {
		for (int src_x = start_src_x; src_x <= end_src_x && src_x <= src_vt->width; src_x++) {
			int dest_x = src_x + offset_x;
			int dest_y = src_y + offset_y;

			if (dest_x >= 1 && dest_x <= dest_vt->width && dest_y >= 1 && dest_y <= dest_vt->height) {
				Cell* src_cell = get_cell(src_vt, src_x, src_y);
				Cell* dest_cell = get_cell(dest_vt, dest_x, dest_y);

				if (src_cell && dest_cell) {
					if (strcmp(src_cell->ch, " ") != 0 ||
							src_cell->fg[0] != '\0' ||
							src_cell->bg[0] != '\0' ||
							src_cell->style[0] != '\0') {
						memcpy(dest_cell, src_cell, sizeof(Cell));
					}
				}
			}
		}
	}

	dest_vt->is_dirty = true;
	return 0;
}

ALWAYS_INT lua_render(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	if (!vt->is_dirty || !vt->buffer) {
		return 0;
	}

	luaL_Buffer B;
	luaL_buffinit(L, &B);
	char sequence_buf[128];
	char current_fg[16] = "";
	char current_bg[16] = "";
	char current_style[8] = "";
	int saved_cursor_x = vt->cursor_x;
	int saved_cursor_y = vt->cursor_y;

	for (int y = 1; y <= vt->height; y++) {
		snprintf(sequence_buf, sizeof(sequence_buf), "\x1b[%d;%dH", y, 1);
		luaL_addstring(&B, sequence_buf);
		luaL_addstring(&B, "\x1b[0m");
		current_style[0] = '\0';
		current_fg[0] = '\0';
		current_bg[0] = '\0';

		for (int x = 1; x <= vt->width; x++) {
			Cell* cell = get_cell(vt, x, y);

			if (!cell || cell->ch[0] == '\0') {
				continue;
			}

			int style_changed = strcmp(cell->style, current_style) != 0;
			int fg_changed = strcmp(cell->fg, current_fg) != 0;
			int bg_changed = strcmp(cell->bg, current_bg) != 0;
			if (style_changed || fg_changed || bg_changed) {
				luaL_addstring(&B, "\x1b[0m");
				strncpy(current_style, cell->style, sizeof(current_style) - 1);
				current_style[sizeof(current_style) - 1] = '\0';
				strncpy(current_fg, cell->fg, sizeof(current_fg) - 1);
				current_fg[sizeof(current_fg) - 1] = '\0';
				strncpy(current_bg, cell->bg, sizeof(current_bg) - 1);
				current_bg[sizeof(current_bg) - 1] = '\0';
				if (current_style[0] != '\0') luaL_addstring(&B, current_style);
				if (current_fg[0] != '\0') luaL_addstring(&B, current_fg);
				if (current_bg[0] != '\0') luaL_addstring(&B, current_bg);
			}
			luaL_addstring(&B, cell->ch);
		}
	}
	snprintf(sequence_buf, sizeof(sequence_buf), "\x1b[%d;%dH", saved_cursor_y, saved_cursor_x);
	luaL_addstring(&B, sequence_buf);
	luaL_pushresult(&B);
	const char* output = lua_tostring(L, -1);
	size_t output_len = lua_rawlen(L, -1);

#ifdef PLATFORM_WINDOWS
	HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	if (hConsole != INVALID_HANDLE_VALUE) {
		DWORD written;
		WriteConsoleA(hConsole, output, (DWORD)output_len, &written, NULL);
	} else {
		fwrite(output, sizeof(char), output_len, stdout);
	}
#else
	fwrite(output, sizeof(char), output_len, stdout);
#endif
	fflush(stdout);
	vt->is_dirty = false;
	return 0;
}

ALWAYS_INT lua_movecursor(STATE){
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int x = luaL_checkinteger(L, 2);
	int y = luaL_checkinteger(L, 3);
	vt->cursor_x = (x < 1) ? 1 : (x > vt->width) ? vt->width : x;
	vt->cursor_y = (y < 1) ? 1 : (y > vt->height) ? vt->height : y;
	return 0;
}

ALWAYS_INT lua_getsize(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	lua_pushinteger(L, vt->width);
	lua_pushinteger(L, vt->height);
	return 2;
}

ALWAYS_INT lua_resize(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int new_width = luaL_checkinteger(L, 2);
	int new_height = luaL_checkinteger(L, 3);

	if (new_width <= 0 || new_height <= 0) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Invalid dimensions: width and height must be positive");
		return 2;
	}

	if (new_width > SIZE_MAX / new_height / sizeof(Cell)) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Dimensions too large: potential overflow");
		return 2;
	}

	size_t new_buffer_size = new_width * new_height * sizeof(Cell);
	Cell* new_buffer = (Cell*)malloc(new_buffer_size);
	if (new_buffer == NULL) {
		lua_pushboolean(L, 0);
		lua_pushstring(L, "Failed to allocate memory for resized buffer");
		return 2;
	}

	for (int i = 0; i < new_width * new_height; i++) {
		strcpy(new_buffer[i].ch, " ");
		strcpy(new_buffer[i].fg, "");
		strcpy(new_buffer[i].bg, "");
		strcpy(new_buffer[i].style, "");
	}

	int copy_width = (new_width < vt->width) ? new_width : vt->width;
	int copy_height = (new_height < vt->height) ? new_height : vt->height;
	for (int y = 0; y < copy_height; y++) {
		for (int x = 0; x < copy_width; x++) {
			Cell* old_cell = &vt->buffer[y * vt->width + x];
			Cell* new_cell = &new_buffer[y * new_width + x];
			memcpy(new_cell, old_cell, sizeof(Cell));
		}
	}

	free(vt->buffer);
	vt->buffer = new_buffer;
	vt->width = new_width;
	vt->height = new_height;

	if (vt->cursor_x > new_width) vt->cursor_x = new_width;
	if (vt->cursor_y > new_height) vt->cursor_y = new_height;

	vt->is_dirty = true;
	lua_pushboolean(L, 1);
	return 1;
}

ALWAYS_INT lua_moveup(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int steps = luaL_optinteger(L, 2, 1);
	vt->cursor_y = (vt->cursor_y - steps < 1) ? 1 : vt->cursor_y - steps;
	return 0;
}

ALWAYS_INT lua_movedown(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int steps = luaL_optinteger(L, 2, 1);
	vt->cursor_y = (vt->cursor_y + steps > vt->height) ? vt->height : vt->cursor_y + steps;
	return 0;
}

ALWAYS_INT lua_moveleft(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int steps = luaL_optinteger(L, 2, 1);
	vt->cursor_x = (vt->cursor_x - steps < 1) ? 1 : vt->cursor_x - steps;
	return 0;
}

ALWAYS_INT lua_moveright(STATE) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int steps = luaL_optinteger(L, 2, 1);
	vt->cursor_x = (vt->cursor_x + steps > vt->width) ? vt->width : vt->cursor_x + steps;
	return 0;
}

ALWAYS_INT vt_lua_copy(STATE) {
	VirtualTerminal* src_vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);

	if (!src_vt || !src_vt->buffer) {
		lua_pushnil(L);
		lua_pushstring(L, "Invalid source virtual terminal");
		return 2;
	}

	if (src_vt->width > SIZE_MAX / src_vt->height / sizeof(Cell)) {
		lua_pushnil(L);
		lua_pushstring(L, "Source virtual terminal too large: potential overflow");
		return 2;
	}

	size_t buffer_size = src_vt->width * src_vt->height * sizeof(Cell);
	VirtualTerminal* dest_vt = (VirtualTerminal*)lua_newuserdata(L, sizeof(VirtualTerminal));
	if (!dest_vt) {
		lua_pushnil(L);
		lua_pushstring(L, "Failed to create destination virtual terminal");
		return 2;
	}

	dest_vt->width = src_vt->width;
	dest_vt->height = src_vt->height;
	dest_vt->cursor_x = src_vt->cursor_x;
	dest_vt->cursor_y = src_vt->cursor_y;
	dest_vt->is_dirty = 1;

	dest_vt->buffer = (Cell*)malloc(buffer_size);
	if (dest_vt->buffer == NULL) {
		lua_pushnil(L);
		lua_pushstring(L, "Failed to allocate memory for copied buffer");
		return 2;
	}

	memcpy(dest_vt->buffer, src_vt->buffer, buffer_size);

	luaL_getmetatable(L, VT_MT);
	lua_setmetatable(L, -2);
	return 1;
}

static const luaL_Reg lib[] = {
	{"init", lua_init},
	{"clear", lua_clear},
	{"setchar", lua_setchar},
	{"writetext", lua_writetext},
	{"writetext_clipped", lua_writetext_clipped},
	{"merge", lua_merge},
	{"render", lua_render},

	{"movecursor" , lua_movecursor},
	{"getsize" , lua_getsize},
	{"resize" , lua_resize},
	{"moveup" , lua_moveup},
	{"movedown" , lua_movedown},
	{"moveleft" , lua_moveleft},
	{"moveright" , lua_moveright},
	{"copy" , vt_lua_copy},
	{"distroy" , lua_distroy},
	{NULL, NULL}
};

static const struct luaL_Reg vt_metamethods [] = {
	{"__gc", vt_lua_gc},
	{NULL, NULL}
};

int luaopen_rmp_virtualterminalrmp(STATE)
{
	luaL_newmetatable(L, VT_MT);
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
	luaL_setfuncs(L, vt_metamethods, 0);
	luaL_newlib(L, lib);
	return 1;
}

#endif // VIRTUALTERMINALRMP_C

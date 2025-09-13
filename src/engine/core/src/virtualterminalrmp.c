#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "luaconf.h"

#define _XOPEN_SOURCE	   /* See feature_test_macros(7) */
#include <wchar.h>
#include <locale.h>
#include <uchar.h>   // optional for char32_t, not strictly required

// wcwidth is not in standard C library, but is widely available on Unix-like systems
// on Windows you may need to provide your own implementation or use a library
// Here we just declare it; link with -lwcwidth if available, or provide your own
// TODO: implement a simple wcwidth on Windows if needed
int wcwidth(wchar_t);

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


static int lua_init(lua_State* L) {
	int width = luaL_optinteger(L , 1 , 150);
	int height = luaL_optinteger(L , 2 , 1);

	setlocale(LC_CTYPE, "");

	size_t vt_size = sizeof(VirtualTerminal);
	VirtualTerminal* vt = (VirtualTerminal*)lua_newuserdata(L , vt_size);
	vt->width = width;
	vt->height = height;
	vt->cursor_x = 1;
	vt->cursor_y = 1;
	vt->is_dirty = true;

	size_t buffer_vt_size = width*height*sizeof(Cell);
	vt->buffer = (Cell*)malloc(buffer_vt_size);

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

static int vt_lua_gc(lua_State *L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	free(vt->buffer);
	vt->buffer = NULL;
	return 0;
}

static int lua_clear(lua_State *L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	for (int i = 0; i < vt->width * vt->height; i++) {
		strcpy(vt->buffer[i].ch, " ");
		strcpy(vt->buffer[i].fg, "");
		strcpy(vt->buffer[i].bg, "");
		strcpy(vt->buffer[i].style, "");
	}
	vt->is_dirty = true;
	return 0;
}

// returns pointer into str (same pointer), and outputs byte length (via *byte_len) and display width (via *disp_width)
// returns pointer as before. sets *byte_len and *disp_width (display columns, 0/1/2)
static const char* next_utf8_char_info(const char* str, int* byte_len, int* disp_width) {
	if (!str || !*str) {
		if (byte_len) *byte_len = 0;
		if (disp_width) *disp_width = 0;
		return str;
	}

	// Use mbrtowc to decode one multibyte character into a wide char
	mbstate_t st;
	memset(&st, 0, sizeof(st));
	wchar_t wc;
	size_t ret = mbrtowc(&wc, str, MB_CUR_MAX, &st);
	if (ret == (size_t)-1 || ret == (size_t)-2) {
		// invalid/partial sequence -> treat first byte as a single printable char
		if (byte_len) *byte_len = 1;
		if (disp_width) *disp_width = 1;
		return str;
	}

	if (byte_len) *byte_len = (int)ret;
	int w = wcwidth(wc);
	if (w < 0) w = 0; // control / combining char can be 0
	if (disp_width) *disp_width = w;
	return str;
}

static int lua_setchar(lua_State *L) {
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


// write up to max_cols display columns, return number of columns written
static int lua_writetext_clipped(lua_State *L) {
    VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    size_t text_len;
    const char* text = luaL_checklstring(L, 4, &text_len);
    int max_cols = luaL_checkinteger(L, 5); // max display columns to write
    const char* fg = luaL_optstring(L, 6, "");
    const char* bg = luaL_optstring(L, 7, "");
    const char* style = luaL_optstring(L, 8, "");

    int start_x = x;
    int current_x = x;
    const char* ptr = text;
    const char* end = text + text_len;

    // ensure locale has been set (call setlocale in lua_init)
    while (ptr < end && current_x <= vt->width && (current_x - start_x) < max_cols) {
        int byte_len = 0, disp_width = 0;
        next_utf8_char_info(ptr, &byte_len, &disp_width);
        if (byte_len <= 0) break;
        if (ptr + byte_len > end) byte_len = (int)(end - ptr);

        // zero-width (combining/VS/ZWJ) -> append to previous base cell if it exists inside the clip
        if (disp_width == 0) {
            int base_x = current_x - 1;
            while (base_x >= start_x) {
                Cell* base = get_cell(vt, base_x, y);
                if (!base) { base_x--; continue; }
                if (base->ch[0] == '\0') { base_x--; continue; } // continuation cell
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
            // if no base found, skip the zero-width as it can't be rendered alone in clip
            ptr += byte_len;
            continue;
        }

        // check if glyph would fit fully inside max_cols
        int consumed = current_x - start_x;
        if (consumed + disp_width > max_cols) {
            break; // don't draw partial glyph
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
                    cont->ch[0] = '\0'; // continuation marker
                    strncpy(cont->fg, fg, sizeof(cont->fg)-1); cont->fg[sizeof(cont->fg)-1] = '\0';
                    strncpy(cont->bg, bg, sizeof(cont->bg)-1); cont->bg[sizeof(cont->bg)-1] = '\0';
                    strncpy(cont->style, style, sizeof(cont->style)-1); cont->style[sizeof(cont->style)-1] = '\0';
                }
            }
        }

        current_x += (disp_width > 0) ? disp_width : 1;
        ptr += byte_len;
    }

    // clear remaining columns in the clipped region so leftover content doesn't show
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

static int lua_writetext(lua_State *L) {
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

		// If the character has display width 0 (combining mark, VS, ZWJ...)
		// append it to the previous base cell if possible.
		if (disp_width == 0) {
			int base_x = current_x - 1;
			// find the last non-continuation cell to append to
			while (base_x >= x) {
				Cell* base = get_cell(vt, base_x, y);
				if (!base) break;
				// if base->ch is continuation marker ('\0') then step left
				if (base->ch[0] == '\0' || (base->ch[0] == ' ' && base_x == x)) {
					base_x--;
					continue;
				}
				// append bytes to this base cell
				size_t existing = strlen(base->ch);
				int can_copy = (CH_UTF8_SIZE - 1) - (int)existing;
				if (can_copy > 0) {
					int to_copy = (byte_len < can_copy) ? byte_len : can_copy;
					memcpy(base->ch + existing, ptr, to_copy);
					base->ch[existing + to_copy] = '\0';
				}
				// also copy style/fg/bg if present (preserve existing)
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
			// if no base found, as a fallback write the bytes to current cell and treat as width 1
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

		// Normal printable char with display width >= 1
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
			// mark continuation columns if glyph occupies more than one column
			if (disp_width > 1) {
				for (int k = 1; k < disp_width; ++k) {
					Cell* cont = get_cell(vt, current_x + k, y);
					if (!cont) break;
					cont->ch[0] = '\0'; // mark as continuation
							    // copy style/fg/bg so render applies the same styling across columns
					strncpy(cont->fg, fg, sizeof(cont->fg)-1);
					cont->fg[sizeof(cont->fg)-1] = '\0';
					strncpy(cont->bg, bg, sizeof(cont->bg)-1);
					cont->bg[sizeof(cont->bg)-1] = '\0';
					strncpy(cont->style, style, sizeof(cont->style)-1);
					cont->style[sizeof(cont->style)-1] = '\0';
				}
			}
		}

		// advance by reported display width (at least 1)
		current_x += (disp_width > 0) ? disp_width : 1;
		ptr += byte_len;
	}

	vt->is_dirty = true;
	return 0;
}

static int lua_merge(lua_State *L) {
	VirtualTerminal* dest_vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	VirtualTerminal* src_vt = (VirtualTerminal*)luaL_checkudata(L, 2, VT_MT);
	int offset_x = luaL_optinteger(L, 3, 0);
	int offset_y = luaL_optinteger(L, 4, 0);

	for (int src_y = 1; src_y <= src_vt->height; src_y++) {
		for (int src_x = 1; src_x <= src_vt->width; src_x++) {
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

static int lua_render(lua_State *L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	if (!vt->is_dirty) {
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

			// skip continuation cells (they were marked by empty ch)
			if (cell->ch[0] == '\0') {
				// but still we must advance the terminal column by zero bytes (we rely on the wide glyph printed earlier to occupy the columns)
				continue;
			}

			int style_changed = strcmp(cell->style, current_style) != 0;
			int fg_changed = strcmp(cell->fg, current_fg) != 0;
			int bg_changed = strcmp(cell->bg, current_bg) != 0;
			if (style_changed || fg_changed || bg_changed) {
				luaL_addstring(&B, "\x1b[0m");
				strcpy(current_style, cell->style);
				strcpy(current_fg, cell->fg);
				strcpy(current_bg, cell->bg);
				if (current_style[0] != '\0') luaL_addstring(&B, current_style);
				if (current_fg[0] != '\0') luaL_addstring(&B, current_fg);
				if (current_bg[0] != '\0') luaL_addstring(&B, current_bg);
			}
			// if the cell contains a single space, that's fine; otherwise add the glyph bytes
			luaL_addstring(&B, cell->ch);
		}
	}
	snprintf(sequence_buf, sizeof(sequence_buf), "\x1b[%d;%dH", saved_cursor_y, saved_cursor_x);
	luaL_addstring(&B, sequence_buf);
	luaL_pushresult(&B);
	const char* output = lua_tostring(L, -1);
	fwrite(output, sizeof(char), lua_rawlen(L, -1), stdout);
	fflush(stdout);
	vt->is_dirty = false;
	return 0;
}

static int lua_movecursor(lua_State* L){
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int x = luaL_checkinteger(L, 2);
	int y = luaL_checkinteger(L, 3);
	vt->cursor_x = (x < 1) ? 1 : (x > vt->width) ? vt->width : x;
	vt->cursor_y = (y < 1) ? 1 : (y > vt->height) ? vt->height : y;
	return 0;
}

static int lua_getsize(lua_State* L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	lua_pushinteger(L, vt->width);
	lua_pushinteger(L, vt->height);
	return 2;
}

static int lua_resize(lua_State* L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int new_width = luaL_checkinteger(L, 2);
	int new_height = luaL_checkinteger(L, 3);
	size_t new_buffer_size = new_width * new_height * sizeof(Cell);
	Cell* new_buffer = (Cell*)malloc(new_buffer_size);
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
	return 0;
}

// cursor movement helpers
static int lua_moveup(lua_State* L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int steps = luaL_optinteger(L, 2, 1);
	vt->cursor_y = (vt->cursor_y - steps < 1) ? 1 : vt->cursor_y - steps;
	return 0;
}

static int lua_movedown(lua_State* L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int steps = luaL_optinteger(L, 2, 1);
	vt->cursor_y = (vt->cursor_y + steps > vt->height) ? vt->height : vt->cursor_y + steps;
	return 0;
}

static int lua_moveleft(lua_State* L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int steps = luaL_optinteger(L, 2, 1);
	vt->cursor_x = (vt->cursor_x - steps < 1) ? 1 : vt->cursor_x - steps;
	return 0;
}

static int lua_moveright(lua_State* L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int steps = luaL_optinteger(L, 2, 1);
	vt->cursor_x = (vt->cursor_x + steps > vt->width) ? vt->width : vt->cursor_x + steps;
	return 0;
}

static int vt_lua_copy(lua_State* L) {
	VirtualTerminal* src_vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	VirtualTerminal* dest_vt = (VirtualTerminal*)lua_newuserdata(L, sizeof(VirtualTerminal));
	dest_vt->width = src_vt->width;
	dest_vt->height = src_vt->height;
	dest_vt->cursor_x = src_vt->cursor_x;
	dest_vt->cursor_y = src_vt->cursor_y;
	dest_vt->is_dirty = 1;
	size_t buffer_size = src_vt->width * src_vt->height * sizeof(Cell);
	dest_vt->buffer = (Cell*)malloc(buffer_size);
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
	{NULL, NULL}
};

static const struct luaL_Reg vt_metamethods [] = {
	{"__gc", vt_lua_gc},
	{NULL, NULL}
};

int luaopen_rmp_virtualterminalrmp(lua_State *L)
{
	luaL_newmetatable(L, VT_MT);
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
	luaL_setfuncs(L, vt_metamethods, 0);
	luaL_newlib(L, lib);
	return 1;
}

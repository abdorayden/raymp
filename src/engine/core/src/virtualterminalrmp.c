#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "luaconf.h"

#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define CH_UTF8_SIZE	8

#define CH_STRYLE_AND_COLOR_SIZE	16

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

static const char* next_utf8_char(const char* str, int* char_len) {
	if (!str || !*str) {
		if (char_len) *char_len = 0;
		return str;
	}
	unsigned char c = (unsigned char)*str;
	int len = 1;
	if (c >= 0xF0) {
		len = 4;
	} else if (c >= 0xE0) {
		len = 3;
	} else if (c >= 0xC0) {
		len = 2;
	}
	if (char_len) *char_len = len;
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
		int char_len = 1;
		ptr = next_utf8_char(ptr , &char_len);
		if (ptr + char_len > end) {
			char_len = end - ptr;
		}
		Cell* cell = get_cell(vt, current_x, y);
		if (cell) {
			strncpy(cell->ch, ptr, char_len);
			cell->ch[char_len] = '\0';
			strncpy(cell->fg, fg, sizeof(cell->fg) - 1);
			cell->fg[sizeof(cell->fg)-1] = '\0';
			strncpy(cell->bg, bg, sizeof(cell->bg) - 1);
			cell->bg[sizeof(cell->bg)-1] = '\0';
			strncpy(cell->style, style, sizeof(cell->style) - 1);
			cell->style[sizeof(cell->style)-1] = '\0';
		}
		ptr += char_len;
		current_x++;
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

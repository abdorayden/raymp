#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

typedef struct {
	char ch;
	char style[16];
	char fg[16];
	char bg[16];
}Cell;

typedef struct {
	unsigned short width;
	unsigned short height;
	unsigned short cursor_x;
	unsigned short cursor_y;
	bool is_dirty;
	Cell* buffer;

}VirtualTerminal;

static Cell* get_cell(VirtualTerminal* vt, unsigned short x, unsigned short y) {
	// x and y is unsigned short so i don't have to worry about negative value 
	// but whatever im gonna keep this condition
	if (x < 1 || x > vt->width || y < 1 || y > vt->height) {
		return NULL;
	}
	return &(vt->buffer[(y-1) * vt->width + (x-1)]);
}


static int lua_init(lua_State* L) {
	int width = luaL_optinteger(L , 1 , 80);
	int height = luaL_optinteger(L , 2 , 24);

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
		vt->buffer[i].ch = ' ';
		strcpy(vt->buffer[i].fg, "");
		strcpy(vt->buffer[i].bg, "");
		strcpy(vt->buffer[i].style, "");
	}
	return 1;
}

// collect some shit (lua collector)
static int lua_gc(lua_State *L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	free(vt->buffer);
	vt->buffer = NULL;
	return 0;
}

static int lua_clear(lua_State *L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	for (int i = 0; i < vt->width * vt->height; i++) {
		vt->buffer[i].ch = ' ';
		strcpy(vt->buffer[i].fg, "");
		strcpy(vt->buffer[i].bg, "");
		strcpy(vt->buffer[i].style, "");
	}
	vt->is_dirty = true;
	return 0;
}

// setChar(x, y, char, fg, bg, style)
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
		cell->ch = ch[0];
		strncpy(cell->fg, fg, sizeof(cell->fg) - 1);
		strncpy(cell->bg, bg, sizeof(cell->bg) - 1);
		strncpy(cell->style, style, sizeof(cell->style) - 1);
		cell->fg[sizeof(cell->fg)-1] = '\0';
		cell->bg[sizeof(cell->bg)-1] = '\0';
		cell->style[sizeof(cell->style)-1] = '\0';
		vt->is_dirty = true;
	}
	return 0;
}

// writeText(x, y, text, fg, bg, style)
static int lua_writetext(lua_State *L) {
	VirtualTerminal* vt = (VirtualTerminal*)luaL_checkudata(L, 1, VT_MT);
	int x = luaL_checkinteger(L, 2);
	int y = luaL_checkinteger(L, 3);
	size_t text_len;
	const char* text = luaL_checklstring(L, 4, &text_len);
	const char* fg = luaL_optstring(L, 5, "");
	const char* bg = luaL_optstring(L, 6, "");
	const char* style = luaL_optstring(L, 7, "");

	for (int i = 0; i < text_len; i++) {
		int current_x = x + i;
		Cell* cell = get_cell(vt, current_x, y);
		if (cell) {
			cell->ch = text[i];
			strncpy(cell->fg, fg, sizeof(cell->fg) - 1);
			strncpy(cell->bg, bg, sizeof(cell->bg) - 1);
			strncpy(cell->style, style, sizeof(cell->style) - 1);
			cell->fg[sizeof(cell->fg)-1] = '\0';
			cell->bg[sizeof(cell->bg)-1] = '\0';
			cell->style[sizeof(cell->style)-1] = '\0';
		}
	}
	vt->is_dirty = true;
	return 0;
}

// merge(other_vt, offsetX, offsetY)
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
					if (src_cell->ch != ' ' || src_cell->fg[0] != '\0' || src_cell->bg[0] != '\0' || src_cell->style[0] != '\0') {
						memcpy(dest_cell, src_cell, sizeof(vt_cell));
					}
				}
			}
		}
	}
	dest_vt->is_dirty = true;
	return 0;
}

// render() - The most complex but most important function
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
	luaL_addstring(&B, "\x1b[2J\x1b[H");
	for (int y = 1; y <= vt->height; y++) {
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
			luaL_addchar(&B, cell->ch);
		}
		luaL_addstring(&B, "\x1b[0m\n");
		current_style[0] = '\0';
		current_fg[0] = '\0';
		current_bg[0] = '\0';
	}
	snprintf(sequence_buf, sizeof(sequence_buf), "\x1b[%d;%dH", vt->cursor_y, vt->cursor_x);
	luaL_addstring(&B, sequence_buf);
	luaL_pushresult(&B);
	const char* output = lua_tostring(L, -1);
	fwrite(output, sizeof(char), lua_strlen(L, -1), stdout);
	fflush(stdout);
	vt->is_dirty = false;
	return 0;
}

// TODO: conntinue implemets the rest of methodos

static const luaL_Reg lib[] = {
	{"init", lua_init},
	{"clear", lua_clear},
	{"setchar", lua_setchar},
	{"writetext", lua_writetext},
	{"merge", lua_merge},
	{"render", lua_render},
	{NULL, NULL}
};

static const struct luaL_Reg vt_metamethods [] = {
    {"__gc", lua_gc},
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

// stranded libraries
#include <stdint.h>
#include <stdio.h>
#include <wchar.h>
#include <locale.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include "../include/rmp_virtualterminal.h"

// local fb = fg_or_bg or "38"
// if hex:sub(1, 1) == "#" then
//     hex = hex:sub(2)
// end
// local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
// return string.format("\27[%s;2;%d;%d;%dm", fb, r, g, b)
// TODO: implement color_from_hex later
char* color_from_hex(const char* hex , bool is_bg) {

    if (!hex) return NULL;
    if (strlen(hex) < 7) return NULL;

    if(*hex == '#') hex++; // ignore tha hash
}

#ifdef _WIN32
    #define PLATFORM_WINDOWS
    #include <windows.h>
    #include <io.h>
    #include <fcntl.h>
#elif defined(__unix__) || defined(__unix) || (defined(__APPLE__) && defined(__MACH__))
    #define PLATFORM_UNIX
    #define _XOPEN_SOURCE
#endif

#ifndef PLATFORM_WINDOWS
    #include <uchar.h>   // optional for char32_t, not strictly required on Unix
#endif

#define CH_UTF8_SIZE    64*2
#define CH_STRYLE_AND_COLOR_SIZE    64

typedef struct {
	char ch[CH_UTF8_SIZE];
	char style[CH_STRYLE_AND_COLOR_SIZE];
	char fg[CH_STRYLE_AND_COLOR_SIZE];
	char bg[CH_STRYLE_AND_COLOR_SIZE];
}Cell;

struct VirtualTerminal {
	unsigned short width;
	unsigned short height;
	unsigned short cursor_x;
	unsigned short cursor_y;
	bool is_dirty;
	Cell* buffer;
};

// Cross-platform wcwidth implementation
// i added a simple wcwidth implementation for windows
// on unix we can just use the system wcwidth
// for more cross platform handling
#ifdef PLATFORM_WINDOWS
    static int wcwidth_impl(wchar_t wc) {
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

VirtualTerminal* rmp_vt_init(int width, int height) {
	if (width <= 0 || height <= 0) {
		return NULL;
	}

	if ((size_t)width > SIZE_MAX / height / sizeof(Cell)) {
		return NULL;
	}

	init_locale();

	VirtualTerminal* vt = (VirtualTerminal*)malloc(sizeof(VirtualTerminal));
	if (!vt) {
		return NULL;
	}

	vt->width = width;
	vt->height = height;
	vt->cursor_x = 1;
	vt->cursor_y = 1;
	vt->is_dirty = true;

	size_t buffer_vt_size = width*height*sizeof(Cell);
	vt->buffer = (Cell*)malloc(buffer_vt_size);
	if (vt->buffer == NULL) {
		free(vt);
		return NULL;
	}

	for (int i = 0; i < width * height; i++) {
		strcpy(vt->buffer[i].ch, " ");
		strcpy(vt->buffer[i].fg, "");
		strcpy(vt->buffer[i].bg, "");
		strcpy(vt->buffer[i].style, "");
	}
	return vt;
}

void rmp_vt_destroy(VirtualTerminal* vt) {
	if (vt) {
		if (vt->buffer) {
			free(vt->buffer);
		}
		free(vt);
	}
}

void rmp_vt_clear(VirtualTerminal* vt) {
	if (!vt || !vt->buffer) {
		return;
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
}

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

void rmp_vt_setchar(VirtualTerminal* vt, int x, int y, const char* ch, const char* fg, const char* bg, const char* style) {
	if (!vt || !vt->buffer) return;
	
	Cell* cell = get_cell(vt, x, y);
	if (cell) {
		strncpy(cell->ch, ch ? ch : " ", CH_UTF8_SIZE - 1);
		cell->ch[CH_UTF8_SIZE - 1] = '\0';
		strncpy(cell->fg, fg ? fg : "", sizeof(cell->fg) - 1);
		cell->fg[sizeof(cell->fg)-1] = '\0';
		strncpy(cell->bg, bg ? bg : "", sizeof(cell->bg) - 1);
		cell->bg[sizeof(cell->bg)-1] = '\0';
		strncpy(cell->style, style ? style : "", sizeof(cell->style) - 1);
		cell->style[sizeof(cell->style)-1] = '\0';
		vt->is_dirty = true;
	}
}

void rmp_vt_draw_box(VirtualTerminal* vt, const char* title, int x, int y, int width, int height,
                     const char* h_line, const char* v_line, const char* tl_corner,
                     const char* tr_corner, const char* bl_corner, const char* br_corner,
                     const char* fg, const char* bg) {
    if (!vt || !vt->buffer) return;
    
    h_line = h_line ? h_line : "─";
    v_line = v_line ? v_line : "│";
    tl_corner = tl_corner ? tl_corner : "┌";
    tr_corner = tr_corner ? tr_corner : "┐";
    bl_corner = bl_corner ? bl_corner : "└";
    br_corner = br_corner ? br_corner : "┘";
    fg = fg ? fg : "";
    bg = bg ? bg : "";

    if (width < 1 || height < 1 || x < 1 || y < 1) {
        return;
    }

    int right = x + width - 1;
    int bottom = y + height - 1;

    if (right > vt->width || bottom > vt->height) {
        return;
    }

    for (int i = x; i <= right; i++) {
        Cell* top_cell = get_cell(vt, i, y);
        if (top_cell) {
            if (i == x) {
                strcpy(top_cell->ch, tl_corner);
            } else if (i == right) {
                strcpy(top_cell->ch, tr_corner);
            } else {
                strcpy(top_cell->ch, h_line);
            }
            strcpy(top_cell->fg, fg);
            strcpy(top_cell->bg, bg);
            strcpy(top_cell->style, "");
        }

        if (height > 1) {
            Cell* bottom_cell = get_cell(vt, i, bottom);
            if (bottom_cell) {
                if (i == x) {
                    strcpy(bottom_cell->ch, bl_corner);
                } else if (i == right) {
                    strcpy(bottom_cell->ch, br_corner);
                } else {
                    strcpy(bottom_cell->ch, h_line);
                }
                strcpy(bottom_cell->fg, fg);
                strcpy(bottom_cell->bg, bg);
                strcpy(bottom_cell->style, "");
            }
        }
    }

    for (int j = y; j <= bottom; j++) {
        Cell* left_cell = get_cell(vt, x, j);
        if (left_cell) {
            if (j == y) {
            } else if (j == bottom) {
            } else {
                strcpy(left_cell->ch, v_line);
            }
            strcpy(left_cell->fg, fg);
            strcpy(left_cell->bg, bg);
            strcpy(left_cell->style, "");
        }

        if (width > 1) {
            Cell* right_cell = get_cell(vt, right, j);
            if (right_cell) {
                if (j == y) {
                } else if (j == bottom) {
                } else {
                    strcpy(right_cell->ch, v_line);
                }
                strcpy(right_cell->fg, fg);
                strcpy(right_cell->bg, bg);
                strcpy(right_cell->style, "");
            }
        }
    }

    if (title && strlen(title) > 0 && width > 2) {
        size_t title_len = strlen(title);
        int title_max_width = width - 2;
        if ((int)title_len > title_max_width) {
            title_len = title_max_width;
        }

        const char* title_ptr = title;
        int title_x = x + 1;

        while (title_ptr < title + title_len && title_x < right) {
            int byte_len = 0, disp_width = 0;
            const char* next_char = next_utf8_char_info(title_ptr, &byte_len, &disp_width);

            if (byte_len <= 0) break;
            if (title_ptr + byte_len > title + title_len) break;

            if (title_x + disp_width > x + width) break;

            Cell* title_cell = get_cell(vt, title_x, y);
            if (title_cell) {
                int copy_len = (byte_len < CH_UTF8_SIZE - 1) ? byte_len : (CH_UTF8_SIZE - 1);
                memcpy(title_cell->ch, title_ptr, copy_len);
                title_cell->ch[copy_len] = '\0';
                strcpy(title_cell->fg, fg);
                strcpy(title_cell->bg, bg);
                strcpy(title_cell->style, "");

                if (disp_width > 1) {
                    for (int k = 1; k < disp_width; k++) {
                        Cell* cont_cell = get_cell(vt, title_x + k, y);
                        if (cont_cell) {
                            cont_cell->ch[0] = '\0';
                            strcpy(cont_cell->fg, fg);
                            strcpy(cont_cell->bg, bg);
                            strcpy(cont_cell->style, "");
                        }
                    }
                }
            }

            title_ptr += byte_len;
            title_x += (disp_width > 0) ? disp_width : 1;
        }
    }

    vt->is_dirty = true;
}

int rmp_vt_writetext_clipped(VirtualTerminal* vt, int x, int y, const char* text, int max_cols, const char* fg, const char* bg, const char* style) {
    if (!vt || !vt->buffer || !text) return 0;
    
    int start_x = x;
    int current_x = x;
    const char* ptr = text;
    size_t text_len = strlen(text);
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
    return cols_written;
}

void rmp_vt_writetext(VirtualTerminal* vt, int x, int y, const char* text, const char* fg, const char* bg, const char* style) {
	if (!vt || !vt->buffer || !text) return;
	
	int x_pos = x;
	size_t text_len = strlen(text);
	const char* ptr = text;
	const char* end = text + text_len;

	while (ptr < end) {
		int byte_len = 0;
		int disp_width = 0;
		next_utf8_char_info(ptr, &byte_len, &disp_width);
		if (byte_len <= 0) break;
		if (ptr + byte_len > end) byte_len = (int)(end - ptr);

		if (disp_width == 0) {
			int base_x = x_pos - 1;
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
				Cell* cell = get_cell(vt, x_pos, y);
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
				x_pos += 1;
			}
			ptr += byte_len;
			continue;
		}

		if (x_pos > vt->width) break;
		Cell* cell = get_cell(vt, x_pos, y);
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
					Cell* cont = get_cell(vt, x_pos + k, y);
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

		x_pos += (disp_width > 0) ? disp_width : 1;
		ptr += byte_len;
	}

	vt->is_dirty = true;
}

void rmp_vt_merge(VirtualTerminal* dest, VirtualTerminal* src, int offset_x, int offset_y) {
	if (!dest || !dest->buffer || !src || !src->buffer) {
		return;
	}

	int start_src_y = 1;
	int end_src_y = src->height;
	int start_src_x = 1;
	int end_src_x = src->width;

	int start_dest_y = 1 + offset_y;
	int end_dest_y = src->height + offset_y;
	int start_dest_x = 1 + offset_x;
	int end_dest_x = src->width + offset_x;

	if (start_dest_y < 1) start_src_y = 1 - offset_y;
	if (end_dest_y > dest->height) end_src_y = dest->height - offset_y;
	if (start_dest_x < 1) start_src_x = 1 - offset_x;
	if (end_dest_x > dest->width) end_src_x = dest->width - offset_x;

	if (start_src_y > end_src_y || start_src_x > end_src_x) {
		dest->is_dirty = true;
		return;
	}

	for (int src_y = start_src_y; src_y <= end_src_y && src_y <= src->height; src_y++) {
		for (int src_x = start_src_x; src_x <= end_src_x && src_x <= src->width; src_x++) {
			int dest_x = src_x + offset_x;
			int dest_y = src_y + offset_y;

			if (dest_x >= 1 && dest_x <= dest->width && dest_y >= 1 && dest_y <= dest->height) {
				Cell* src_cell = get_cell(src, src_x, src_y);
				Cell* dest_cell = get_cell(dest, dest_x, dest_y);

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

	dest->is_dirty = true;
}

void rmp_vt_render(VirtualTerminal* vt) {
	if (!vt->is_dirty || !vt->buffer) {
		return;
	}

	char sequence_buf[128];
	char current_fg[CH_STRYLE_AND_COLOR_SIZE] = "";
	char current_bg[CH_STRYLE_AND_COLOR_SIZE] = "";
	char current_style[CH_STRYLE_AND_COLOR_SIZE] = "";
	int saved_cursor_x = vt->cursor_x;
	int saved_cursor_y = vt->cursor_y;

	for (int y = 1; y <= vt->height; y++) {
		snprintf(sequence_buf, sizeof(sequence_buf), "\x1b[%d;%dH", y, 1);
		fputs(sequence_buf, stdout);
		fputs("\x1b[0m", stdout);
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
				fputs("\x1b[0m", stdout);
				strncpy(current_style, cell->style, sizeof(current_style) - 1);
				current_style[sizeof(current_style) - 1] = '\0';
				strncpy(current_fg, cell->fg, sizeof(current_fg) - 1);
				current_fg[sizeof(current_fg) - 1] = '\0';
				strncpy(current_bg, cell->bg, sizeof(current_bg) - 1);
				current_bg[sizeof(current_bg) - 1] = '\0';
				// Apply combined color/style sequence to avoid issues with multiple separate codes
				if (current_style[0] != '\0') fputs(current_style, stdout);
				if (current_fg[0] != '\0') fputs(current_fg, stdout);
				if (current_bg[0] != '\0') fputs(current_bg, stdout);
			}
			fputs(cell->ch, stdout);
		}
	}
	snprintf(sequence_buf, sizeof(sequence_buf), "\x1b[%d;%dH", saved_cursor_y, saved_cursor_x);
	fputs(sequence_buf, stdout);
	fflush(stdout);
	vt->is_dirty = false;
}

void rmp_vt_movecursor(VirtualTerminal* vt, int x, int y) {
	if (!vt) return;
	vt->cursor_x = (x < 1) ? 1 : (x > vt->width) ? vt->width : x;
	vt->cursor_y = (y < 1) ? 1 : (y > vt->height) ? vt->height : y;
}

void rmp_vt_getsize(VirtualTerminal* vt, int* width, int* height) {
	if (!vt || !width || !height) return;
	*width = vt->width;
	*height = vt->height;
}

bool rmp_vt_resize(VirtualTerminal* vt, int new_width, int new_height) {
	if (!vt || new_width <= 0 || new_height <= 0) {
		return false;
	}

	if ((size_t)new_width > SIZE_MAX / new_height / sizeof(Cell)) {
		return false;
	}

	size_t new_buffer_size = new_width * new_height * sizeof(Cell);
	Cell* new_buffer = (Cell*)malloc(new_buffer_size);
	if (new_buffer == NULL) {
		return false;
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
	return true;
}

void rmp_vt_moveup(VirtualTerminal* vt, int steps) {
	if (!vt) return;
	vt->cursor_y = (vt->cursor_y - steps < 1) ? 1 : vt->cursor_y - steps;
}

void rmp_vt_movedown(VirtualTerminal* vt, int steps) {
	if (!vt) return;
	vt->cursor_y = (vt->cursor_y + steps > vt->height) ? vt->height : vt->cursor_y + steps;
}

void rmp_vt_moveleft(VirtualTerminal* vt, int steps) {
	if (!vt) return;
	vt->cursor_x = (vt->cursor_x - steps < 1) ? 1 : vt->cursor_x - steps;
}

void rmp_vt_moveright(VirtualTerminal* vt, int steps) {
	if (!vt) return;
	vt->cursor_x = (vt->cursor_x + steps > vt->width) ? vt->width : vt->cursor_x + steps;
}

VirtualTerminal* rmp_vt_copy(VirtualTerminal* src) {
	if (!src || !src->buffer) {
		return NULL;
	}

	if (src->width > SIZE_MAX / src->height / sizeof(Cell)) {
		return NULL;
	}

	size_t buffer_size = src->width * src->height * sizeof(Cell);
	VirtualTerminal* dest = (VirtualTerminal*)malloc(sizeof(VirtualTerminal));
	if (!dest) {
		return NULL;
	}

	dest->width = src->width;
	dest->height = src->height;
	dest->cursor_x = src->cursor_x;
	dest->cursor_y = src->cursor_y;
	dest->is_dirty = 1;

	dest->buffer = (Cell*)malloc(buffer_size);
	if (dest->buffer == NULL) {
		free(dest);
		return NULL;
	}

	memcpy(dest->buffer, src->buffer, buffer_size);

	return dest;
}

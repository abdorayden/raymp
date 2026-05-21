/*
*   Copyright (c) 2024-2026 Ray Den
*   
*   Permission is hereby granted, free of charge, to any person obtaining a copy
*   of this software and associated documentation files (the "Software"), to deal
*   in the Software without restriction, including without limitation the rights
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*   copies of the Software, and to permit persons to whom the Software is
*   furnished to do so, subject to the following conditions:
*   
*   The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
*   
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*   THE SOFTWARE.
* */

#include "vt.h"
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

static Cell *get_cell(VirtualTerminal *vt, unsigned short x, unsigned short y) {
    // x and y is unsigned short so i don't have to worry about negative value
    // but whatever im gonna keep this condition
    if (x < 1 || x > vt->width || y < 1 || y > vt->height) {
        return NULL;
    }
    return &(vt->buffer[(y - 1) * vt->width + (x - 1)]);
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

// ⣯ :  by python3 btw
//  0b11100010
//  0b10100011
//  0b10101111
// expected : 3
static int decode_utf8_char(const char *str, int *byte_len) {
    unsigned char byte = (unsigned char)str[0];

    if (byte == 0) {
        *byte_len = 0;
        return 0;
    }
    // tiny ifs that returns -1 is incompleted utf

    if ((byte & 0x80) == 0) { // ASCII: 0xxxxxxx
        *byte_len = 1;
        return byte;
    } else if ((byte & 0xE0) == 0xC0) { // 2-byte: 110xxxxx 10xxxxxx
        if ((unsigned char)str[1] == 0) {
            *byte_len = 1;
            return -1;
        }
        *byte_len = 2;
        int code = (((byte & 0x1F) << 6) | ((unsigned char)str[1] & 0x3F));
        if (code < 0x80)
            return -1;
        return code;
    } else if ((byte & 0xF0) == 0xE0) { // 3-byte: 1110xxxx 10xxxxxx 10xxxxxx
        if ((unsigned char)str[1] == 0 || (unsigned char)str[2] == 0) {
            *byte_len = 1;
            return -1;
        }
        *byte_len = 3;
        int code = (((byte & 0x0F) << 12) | (((unsigned char)str[1] & 0x3F) << 6) |
                ((unsigned char)str[2] & 0x3F));
        if (code < 0x800)
            return -1;
        if (code >= 0xD800 && code <= 0xDFFF)
            return -1;
        return code;
    } else if ((byte & 0xF8) ==
            0xF0) { // 4-byte: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        if ((unsigned char)str[1] == 0 || (unsigned char)str[2] == 0 ||
                (unsigned char)str[3] == 0) {
            *byte_len = 1;
            return -1;
        }
        *byte_len = 4;
        int code = (((byte & 0x07) << 18) | (((unsigned char)str[1] & 0x3F) << 12) |
                (((unsigned char)str[2] & 0x3F) << 6) |
                ((unsigned char)str[3] & 0x3F));
        if (code < 0x10000)
            return -1;
        if (code > 0x10FFFF)
            return -1;
        return code;
    } else {
        *byte_len = 1;
        return -1;
    }
}

static const char *next_utf8_char_info(const char *str, int *byte_len,
        int *disp_width) {
    if (!str || !*str) {
        if (byte_len)
            *byte_len = 0;
        if (disp_width)
            *disp_width = 0;
        return str;
    }

    int decoded_char = decode_utf8_char(str, byte_len);
    if (decoded_char < 0) {
        if (byte_len)
            *byte_len = 1; // On error, advance by 1
        if (disp_width)
            *disp_width = 1;
        return str + 1;
    }

    char32_t ucs = (char32_t)decoded_char;
    int w = unicode_width(ucs);

    if (w < 0)
        w = 0;
    if (byte_len)
        *byte_len = *byte_len;
    if (disp_width)
        *disp_width = w;
    return str + *byte_len;
}

bool rmp_vt_init(RDNApi *api) {
    long width;
    long height;
    bool res = api->to_integer(api, -1, &height);
    res &= api->to_integer(api, -2, &width);
    if (!res) {
        api->push_null(api);
        api->push_string(api, "error with input value");
        return true;
    }

    if (width <= 0 || height <= 0) {
        api->push_null(api);
        api->push_string(api,
                "Invalid dimensions: width and height must be positive");
        return true;
    }

    if (width > USHRT_MAX || height > USHRT_MAX) {
        api->push_null(api);
        api->push_string(api,
                "Invalid dimensions: width and height must be <= 65535");
        return true;
    }

    if ((size_t)width > SIZE_MAX / height / sizeof(Cell)) {
        api->push_null(api);
        api->push_string(api, "Dimensions too large: potential overflow");
        return true;
    }

    init_locale();

    size_t vt_size = sizeof(VirtualTerminal);
    VirtualTerminal *vt = (VirtualTerminal *)malloc(vt_size);
    if (!vt) {
        api->push_null(api);
        api->push_string(api, "Failed to create virtual terminal userdata");
        return true;
    }

    vt->width = width;
    vt->height = height;
    vt->cursor_x = 1;
    vt->cursor_y = 1;
    vt->is_dirty = true;

    size_t buffer_vt_size = width * height * sizeof(Cell);
    vt->buffer = (Cell *)malloc(buffer_vt_size);
    if (vt->buffer == NULL) {
        api->push_null(api);
        api->push_string(api,
                "Failed to allocate memory for virtual terminal buffer");
        return 2;
    }

    for (int i = 0; i < width * height; i++) {
        strcpy(vt->buffer[i].ch, " ");
        strcpy(vt->buffer[i].fg, "");
        strcpy(vt->buffer[i].bg, "");
        strcpy(vt->buffer[i].style, "");
    }

    api->push_string(api, (char *)(void *)vt);
    api->push_null(api);
    return true;
}

bool rmp_vt_distroy(RDNApi *api) {
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -1);
    free(vt->buffer);
    vt->buffer = NULL;
    return 0;
}

bool rmp_vt_clear(RDNApi *api) {
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -1);

    if (!vt || !vt->buffer) {
        return api->push_boolean(api, false);
        return true;
    }

    size_t total_size = vt->width * vt->height;

    for (size_t i = 0; i < total_size; i++) {
        Cell *cell = &vt->buffer[i];
        cell->ch[0] = ' ';
        cell->ch[1] = '\0';
        cell->fg[0] = '\0';
        cell->bg[0] = '\0';
        cell->style[0] = '\0';
    }
    vt->is_dirty = true;
    return api->push_boolean(api, true);
    return true;
}

bool rmp_vt_setchar(RDNApi *api) {
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -7);
    if (!vt || !vt->buffer) {
        return api->push_boolean(api, false);
        return true;
    }

    long x;
    long y;

    bool res = api->to_integer(api, -6, &x);
    res &= api->to_integer(api, -5, &y);
    if (!res) {
        x = y = 1;
    }
    const char *ch = api->to_string(api, -4);
    const char *fg = api->to_string(api, -3);
    const char *bg = api->to_string(api, -2);
    const char *style = api->to_string(api, -1);

    Cell *cell = get_cell(vt, x, y);
    if (cell) {
        strncpy(cell->ch, ch == NULL ? " " : ch, CH_UTF8_SIZE - 1);
        cell->ch[CH_UTF8_SIZE - 1] = '\0';
        strncpy(cell->fg, fg == NULL ? "" : fg, sizeof(cell->fg) - 1);
        cell->fg[sizeof(cell->fg) - 1] = '\0';
        strncpy(cell->bg, bg == NULL ? "" : bg, sizeof(cell->bg) - 1);
        cell->bg[sizeof(cell->bg) - 1] = '\0';
        strncpy(cell->style, style == NULL ? "" : style, sizeof(cell->style) - 1);
        cell->style[sizeof(cell->style) - 1] = '\0';
        vt->is_dirty = true;
    }
    return api->push_boolean(api, true);
    return true;
}

bool rmp_vt_writetext(RDNApi *api) {
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -7);

    long x;
    long y;

    bool res = api->to_integer(api, -6, &x);
    res &= api->to_integer(api, -5, &y);
    const char *text = api->to_string(api, -4);
    size_t text_len;
    if (text == NULL) {
        text = " ";
        text_len = 1;
    } else {
        text_len = strlen(text);
    }
    const char *fg = api->to_string(api, -3);
    const char *bg = api->to_string(api, -2);
    const char *style = api->to_string(api, -1);

    int current_x = x;
    const char *ptr = text;
    const char *end = text + text_len;

    while (ptr < end) {
        int byte_len = 0;
        int disp_width = 0;
        const char *next_char = next_utf8_char_info(ptr, &byte_len, &disp_width);
        if (byte_len <= 0)
            break;
        if (ptr + byte_len > end)
            byte_len = (int)(end - ptr);

        if (disp_width == 0) {
            int base_x = current_x - 1;
            while (base_x >= x) {
                Cell *base = get_cell(vt, base_x, y);
                if (!base)
                    break;
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
                    strncpy(base->fg, fg, sizeof(base->fg) - 1);
                    base->fg[sizeof(base->fg) - 1] = '\0';
                }
                if (bg && bg[0]) {
                    strncpy(base->bg, bg, sizeof(base->bg) - 1);
                    base->bg[sizeof(base->bg) - 1] = '\0';
                }
                if (style && style[0]) {
                    strncpy(base->style, style, sizeof(base->style) - 1);
                    base->style[sizeof(base->style) - 1] = '\0';
                }
                break;
            }
            if (base_x < x) {
                Cell *cell = get_cell(vt, current_x, y);
                if (cell) {
                    int to_copy =
                        (byte_len < CH_UTF8_SIZE - 1) ? byte_len : (CH_UTF8_SIZE - 1);
                    memcpy(cell->ch, ptr, to_copy);
                    cell->ch[to_copy] = '\0';
                    strncpy(cell->fg, fg, sizeof(cell->fg) - 1);
                    cell->fg[sizeof(cell->fg) - 1] = '\0';
                    strncpy(cell->bg, bg, sizeof(cell->bg) - 1);
                    cell->bg[sizeof(cell->bg) - 1] = '\0';
                    strncpy(cell->style, style, sizeof(cell->style) - 1);
                    cell->style[sizeof(cell->style) - 1] = '\0';
                }
                current_x += 1;
            }
            ptr = next_char;
            continue;
        }

        if (current_x > vt->width)
            break;
        Cell *cell = get_cell(vt, current_x, y);
        if (cell) {
            int to_copy =
                (byte_len < CH_UTF8_SIZE - 1) ? byte_len : (CH_UTF8_SIZE - 1);
            memcpy(cell->ch, ptr, to_copy);
            cell->ch[to_copy] = '\0';
            strncpy(cell->fg, fg, sizeof(cell->fg) - 1);
            cell->fg[sizeof(cell->fg) - 1] = '\0';
            strncpy(cell->bg, bg, sizeof(cell->bg) - 1);
            cell->bg[sizeof(cell->bg) - 1] = '\0';
            strncpy(cell->style, style, sizeof(cell->style) - 1);
            cell->style[sizeof(cell->style) - 1] = '\0';
            if (disp_width > 1) {
                for (int k = 1; k < disp_width; ++k) {
                    Cell *cont = get_cell(vt, current_x + k, y);
                    if (!cont)
                        break;
                    cont->ch[0] = '\0';
                    strncpy(cont->fg, fg, sizeof(cont->fg) - 1);
                    cont->fg[sizeof(cont->fg) - 1] = '\0';
                    strncpy(cont->bg, bg, sizeof(cont->bg) - 1);
                    cont->bg[sizeof(cont->bg) - 1] = '\0';
                    strncpy(cont->style, style, sizeof(cont->style) - 1);
                    cont->style[sizeof(cont->style) - 1] = '\0';
                }
            }
        }

        current_x += (disp_width > 0) ? disp_width : 1;
        ptr = next_char;
    }

    vt->is_dirty = true;
    return true;
}

bool rmp_vt_open_win(RDNApi *api) {
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -9);

    long x;
    long y;
    long width;
    long height;
    BorderStyle border;

    const char *title = api->to_string(api, -8);
    size_t title_len;
    if (title == NULL) {
        title = " ";
        title_len = 1;
    } else {
        title_len = strlen(title);
    }

    bool res = api->to_integer(api, -7, &x);
    res &= api->to_integer(api, -6, &y);
    res &= api->to_integer(api, -5, &width);
    res &= api->to_integer(api, -4, &height);
    res &= api->to_integer(api, -3, (long *)&border);

    if (border > RoundedCorners || border < NoBorder) {
        border = NoBorder;
    }

    const char *h_line = Border[border][0];
    const char *v_line = Border[border][1];
    const char *tl_corner = Border[border][2];
    const char *tr_corner = Border[border][3];
    const char *bl_corner = Border[border][4];
    const char *br_corner = Border[border][5];
    bool use_default = true;

    const char *fg = api->to_string(api, -2);
    const char *bg = api->to_string(api, -1);
    fg = fg == NULL ? "" : fg;
    bg = bg == NULL ? "" : bg;

    if (width < 1 || height < 1 || x < 1 || y < 1) {
        api->push_boolean(api , false);
        return true;
    }

    int end_x = (x + width - 1 > vt->width) ? vt->width : x + width - 1;
    int end_y = (y + height - 1 > vt->height) ? vt->height : y + height - 1;

    for (int i = x; i <= end_x; i++) {
        Cell *top_cell = get_cell(vt, i, y);
        if (top_cell) {
            if (i == x) {
                strncpy(top_cell->ch, tl_corner, sizeof(top_cell->ch) - 1);
                top_cell->ch[sizeof(top_cell->ch) - 1] = '\0';
            } else if (i == end_x) {
                strncpy(top_cell->ch, tr_corner, sizeof(top_cell->ch) - 1);
                top_cell->ch[sizeof(top_cell->ch) - 1] = '\0';
            } else {
                strncpy(top_cell->ch, h_line, sizeof(top_cell->ch) - 1);
                top_cell->ch[sizeof(top_cell->ch) - 1] = '\0';
            }
            strncpy(top_cell->fg, fg, sizeof(top_cell->fg) - 1);
            top_cell->fg[sizeof(top_cell->fg) - 1] = '\0';
            strncpy(top_cell->bg, bg, sizeof(top_cell->bg) - 1);
            top_cell->bg[sizeof(top_cell->bg) - 1] = '\0';
            top_cell->style[0] = '\0';
        }
    }

    if (height > 1) {
        for (int i = x; i <= end_x; i++) {
            Cell *bottom_cell = get_cell(vt, i, end_y);
            if (bottom_cell) {
                if (i == x) {
                    strncpy(bottom_cell->ch, bl_corner, sizeof(bottom_cell->ch) - 1);
                    bottom_cell->ch[sizeof(bottom_cell->ch) - 1] = '\0';
                } else if (i == end_x) {
                    strncpy(bottom_cell->ch, br_corner, sizeof(bottom_cell->ch) - 1);
                    bottom_cell->ch[sizeof(bottom_cell->ch) - 1] = '\0';
                } else {
                    strncpy(bottom_cell->ch, h_line, sizeof(bottom_cell->ch) - 1);
                    bottom_cell->ch[sizeof(bottom_cell->ch) - 1] = '\0';
                }
                strncpy(bottom_cell->fg, fg, sizeof(bottom_cell->fg) - 1);
                bottom_cell->fg[sizeof(bottom_cell->fg) - 1] = '\0';
                strncpy(bottom_cell->bg, bg, sizeof(bottom_cell->bg) - 1);
                bottom_cell->bg[sizeof(bottom_cell->bg) - 1] = '\0';
                bottom_cell->style[0] = '\0';
            }
        }
    }

    for (int j = y + 1; j < end_y; j++) {
        Cell *left_cell = get_cell(vt, x, j);
        if (left_cell) {
            strncpy(left_cell->ch, v_line, sizeof(left_cell->ch) - 1);
            left_cell->ch[sizeof(left_cell->ch) - 1] = '\0';
            strncpy(left_cell->fg, fg, sizeof(left_cell->fg) - 1);
            left_cell->fg[sizeof(left_cell->fg) - 1] = '\0';
            strncpy(left_cell->bg, bg, sizeof(left_cell->bg) - 1);
            left_cell->bg[sizeof(left_cell->bg) - 1] = '\0';
            left_cell->style[0] = '\0';
        }

        if (width > 1) {
            Cell *right_cell = get_cell(vt, end_x, j);
            if (right_cell) {
                strncpy(right_cell->ch, v_line, sizeof(right_cell->ch) - 1);
                right_cell->ch[sizeof(right_cell->ch) - 1] = '\0';
                strncpy(right_cell->fg, fg, sizeof(right_cell->fg) - 1);
                right_cell->fg[sizeof(right_cell->fg) - 1] = '\0';
                strncpy(right_cell->bg, bg, sizeof(right_cell->bg) - 1);
                right_cell->bg[sizeof(right_cell->bg) - 1] = '\0';
                right_cell->style[0] = '\0';
            }
        }
    }

    for (int i = y + 1; i < end_y; i++) {
        for (int j = x + 1; j < end_x; j++) {
            Cell *interior_cell = get_cell(vt, j, i);
            if (interior_cell) {
                interior_cell->ch[0] = ' ';
                interior_cell->ch[1] = '\0';
                interior_cell->fg[0] = '\0';
                strncpy(interior_cell->bg, bg, sizeof(interior_cell->bg) - 1);
                interior_cell->bg[sizeof(interior_cell->bg) - 1] = '\0';
                interior_cell->style[0] = '\0';
            }
        }
    }

    if (title_len > 0 && width > 2) {
        int available_width = width - 2;
        if ((int)title_len > available_width) {
            title_len = available_width;
        }

        int title_x = x + 1 + (available_width - (int)title_len) / 2;

        for (int i = 0; i < (int)title_len && title_x + i < end_x; i++) {
            Cell *title_cell = get_cell(vt, title_x + i, y);
            if (title_cell) {
                title_cell->ch[0] = title[i];
                title_cell->ch[1] = '\0';
                strncpy(title_cell->fg, fg, sizeof(title_cell->fg) - 1);
                title_cell->fg[sizeof(title_cell->fg) - 1] = '\0';
                strncpy(title_cell->bg, bg, sizeof(title_cell->bg) - 1);
                title_cell->bg[sizeof(title_cell->bg) - 1] = '\0';
                title_cell->style[0] = '\0';
            }
        }
    }

    vt->is_dirty = true;
    api->push_boolean(api , true);
    return true;
}

bool rmp_vt_merge(RDNApi *api) {
    VirtualTerminal *dest_vt = (VirtualTerminal *)(void *)api->to_string(api, -4);
    VirtualTerminal *src_vt = (VirtualTerminal *)(void *)api->to_string(api, -3);
    bool res = true;
    long offset_x;
    long offset_y;
    res = api->to_integer(api, -2, &offset_x);
    res = api->to_integer(api, -1, &offset_y);
    if (!dest_vt || !dest_vt->buffer || !src_vt || !src_vt->buffer || !res) {
        api->push_boolean(api , false);
        return true;
    }

    int start_src_y = 1;
    int end_src_y = src_vt->height;
    int start_src_x = 1;
    int end_src_x = src_vt->width;

    int start_dest_y = 1 + offset_y;
    int end_dest_y = src_vt->height + offset_y;
    int start_dest_x = 1 + offset_x;
    int end_dest_x = src_vt->width + offset_x;

    if (start_dest_y < 1)
        start_src_y = 1 - offset_y;
    if (end_dest_y > dest_vt->height)
        end_src_y = dest_vt->height - offset_y;
    if (start_dest_x < 1)
        start_src_x = 1 - offset_x;
    if (end_dest_x > dest_vt->width)
        end_src_x = dest_vt->width - offset_x;

    if (start_src_y > end_src_y || start_src_x > end_src_x) {
        dest_vt->is_dirty = true;
        api->push_boolean(api , false);
        return true;
    }

    for (int src_y = start_src_y; src_y <= end_src_y && src_y <= src_vt->height;
            src_y++) {
        for (int src_x = start_src_x; src_x <= end_src_x && src_x <= src_vt->width;
                src_x++) {
            int dest_x = src_x + offset_x;
            int dest_y = src_y + offset_y;

            if (dest_x >= 1 && dest_x <= dest_vt->width && dest_y >= 1 &&
                    dest_y <= dest_vt->height) {
                Cell *src_cell = get_cell(src_vt, src_x, src_y);
                Cell *dest_cell = get_cell(dest_vt, dest_x, dest_y);

                if (src_cell && dest_cell) {
                    if (strcmp(src_cell->ch, " ") != 0 || src_cell->fg[0] != '\0' ||
                            src_cell->bg[0] != '\0' || src_cell->style[0] != '\0') {
                        memcpy(dest_cell, src_cell, sizeof(Cell));
                    }
                }
            }
        }
    }

    dest_vt->is_dirty = true;
    api->push_boolean(api , true);
    return true;
}

bool rmp_vt_render(RDNApi *api) {
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -1);
    if (!vt->is_dirty) {
        api->push_boolean(api , false);
        api->push_string(api, "the VirtualTerminal is not modified");
        return true;
    }
    if (!vt->buffer) {
        api->push_boolean(api , false);
        api->push_string(api, "buffer is not allocated or it's NULL value");
        return true;
    }

    RLList(char *) sb = {0};

    char sequence_buf[128];
    char current_fg[CH_STRYLE_AND_COLOR_SIZE] = "";
    char current_bg[CH_STRYLE_AND_COLOR_SIZE] = "";
    char current_style[CH_STRYLE_AND_COLOR_SIZE] = "";
    int saved_cursor_x = vt->cursor_x;
    int saved_cursor_y = vt->cursor_y;

    for (int y = 1; y <= vt->height; y++) {
        snprintf(sequence_buf, sizeof(sequence_buf), "\x1b[%d;%dH", y, 1);
        ray_append(&sb, sequence_buf);
        ray_append(&sb, "\x1b[0m");
        current_style[0] = '\0';
        current_fg[0] = '\0';
        current_bg[0] = '\0';
        for (int x = 1; x <= vt->width; x++) {
            Cell *cell = get_cell(vt, x, y);

            if (!cell || cell->ch[0] == '\0') {
                continue;
            }

            int style_changed = strcmp(cell->style, current_style) != 0;
            int fg_changed = strcmp(cell->fg, current_fg) != 0;
            int bg_changed = strcmp(cell->bg, current_bg) != 0;
            if (style_changed || fg_changed || bg_changed) {
                ray_append(&sb, "\x1b[0m");
                strncpy(current_style, cell->style, sizeof(current_style) - 1);
                current_style[sizeof(current_style) - 1] = '\0';
                strncpy(current_fg, cell->fg, sizeof(current_fg) - 1);
                current_fg[sizeof(current_fg) - 1] = '\0';
                strncpy(current_bg, cell->bg, sizeof(current_bg) - 1);
                current_bg[sizeof(current_bg) - 1] = '\0';

                // Apply combined color/style sequence
                if (current_style[0] != '\0')
                    ray_append(&sb, current_style);
                if (current_fg[0] != '\0')
                    ray_append(&sb, current_fg);
                if (current_bg[0] != '\0')
                    ray_append(&sb, current_bg);
            }
            ray_append(&sb, cell->ch);
        }
    }

    // Restore cursor position
    snprintf(sequence_buf, sizeof(sequence_buf), "\x1b[%d;%dH", saved_cursor_y,
            saved_cursor_x);
    ray_append(&sb, sequence_buf);

    // Check if buffer allocation failed during building
    if (!sb.items) {
        api->push_boolean(api , false);
        api->push_string(api, "Buffer allocation failed during rendering");
        return true;
    }
    // Write the output
#ifdef PLATFORM_WINDOWS
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hConsole != INVALID_HANDLE_VALUE) {
        DWORD written;
        WriteConsoleA(hConsole, sb.data, (DWORD)sb.size, &written, NULL);
    } else {
        fwrite(sb.data, sizeof(char), sb.size, stdout);
    }
#else
    fwrite(sb.items, sizeof(char), sb.count, stdout);
#endif

    fflush(stdout);
    vt->is_dirty = false;

    // Clean up
    ray_clear(&sb);
    api->push_boolean(api , true);
    api->push_null(api);
    return true;
}

bool rmp_vt_movecursor(RDNApi* api)
{
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -3);
    long x;
    long y;
    api->to_integer(api , -2 , &x);
    api->to_integer(api , -1 , &y);
    vt->cursor_x = (x < 1) ? 1 : (x > vt->width) ? vt->width : x;
    vt->cursor_y = (y < 1) ? 1 : (y > vt->height) ? vt->height : y;
    return true;
}

bool rmp_vt_getsize(RDNApi* api)
{
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -1);
    api->push_integer(api , vt->width);
    api->push_integer(api , vt->height);
    return true;
}

bool rmp_vt_resize(RDNApi* api)
{
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -3);
    long new_width;
    long new_height;
    api->to_integer(api , -2 , &new_width);
    api->to_integer(api , -1 , &new_height);

    if (new_width <= 0 || new_height <= 0) {
        api->push_boolean(api, false);
        api->push_string(api, "Invalid dimensions: width and height must be positive");
        return true;
    }
    if (new_width > USHRT_MAX || new_height > USHRT_MAX) {
        api->push_boolean(api, false);
        api->push_string(api, "Invalid dimensions: width and height must be <= 65535");
        return true;
    }

    if ((size_t)new_width > SIZE_MAX / new_height / sizeof(Cell)) {
        api->push_boolean(api, false);
        api->push_string(api, "Dimensions too large: potential overflow");
        return true;
    }

    size_t new_buffer_size = new_width * new_height * sizeof(Cell);
    Cell* new_buffer = (Cell*)malloc(new_buffer_size);
    if (new_buffer == NULL) {
        api->push_boolean(api, false);
        api->push_string(api, "Failed to allocate memory for resized buffer");
        return true;
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

    api->push_boolean(api, true);
    api->push_null(api);
    return true;
}

bool rmp_vt_moveup(RDNApi* api)
{
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -2);
    long steps;
    bool res = api->to_integer(api , -1 , &steps);
    if (!res) steps = 1;
    vt->cursor_y = (vt->cursor_y - steps < 1) ? 1 : vt->cursor_y - steps;
    return true;
}

bool rmp_vt_movedown(RDNApi* api)
{
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -2);
    long steps;
    bool res = api->to_integer(api , -1 , &steps);
    if (!res) steps = 1;
    vt->cursor_y = (vt->cursor_y + steps > vt->height) ? vt->height : vt->cursor_y + steps;
    return true;
}

bool rmp_vt_moveleft(RDNApi* api)
{
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -2);
    long steps;
    bool res = api->to_integer(api , -1 , &steps);
    if (!res) steps = 1;
    vt->cursor_x = (vt->cursor_x - steps < 1) ? 1 : vt->cursor_x - steps;
    return true;
}

bool rmp_vt_moveright(RDNApi* api)
{
    VirtualTerminal *vt = (VirtualTerminal *)(void *)api->to_string(api, -2);
    long steps;
    bool res = api->to_integer(api , -1 , &steps);
    if (!res) steps = 1;
    vt->cursor_x = (vt->cursor_x + steps > vt->width) ? vt->width : vt->cursor_x + steps;
    return true;
}

bool rmp_vt_copy(RDNApi* api)
{
    VirtualTerminal *src_vt = (VirtualTerminal *)(void *)api->to_string(api, -1);

    if (!src_vt || !src_vt->buffer) {
        api->push_null(api);
        api->push_string(api, "Invalid source virtual terminal");
        return true;
    }

    if (src_vt->width > SIZE_MAX / src_vt->height / sizeof(Cell)) {
        api->push_null(api);
        api->push_string(api, "Source virtual terminal too large: potential overflow");
        return true;
    }

    size_t buffer_size = src_vt->width * src_vt->height * sizeof(Cell);

    size_t vt_size = sizeof(VirtualTerminal);
    VirtualTerminal *dest_vt = (VirtualTerminal *)malloc(vt_size);
    if (!dest_vt) {
        api->push_null(api);
        api->push_string(api, "Failed to create destination virtual terminal");
        return true;
    }

    dest_vt->width = src_vt->width;
    dest_vt->height = src_vt->height;
    dest_vt->cursor_x = src_vt->cursor_x;
    dest_vt->cursor_y = src_vt->cursor_y;
    dest_vt->is_dirty = 1;
    dest_vt->buffer = (Cell*)malloc(buffer_size);

    if (dest_vt->buffer == NULL) {
        api->push_null(api);
        api->push_string(api, "Failed to allocate memory for copied buffer");
        return true;
    }

    memcpy(dest_vt->buffer, src_vt->buffer, buffer_size);

    api->push_string(api , (char*)(void*)dest_vt);
    api->push_null(api);

    return true;
}

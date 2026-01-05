#ifndef RMP_VIRTUALTERMINAL_H_
#define RMP_VIRTUALTERMINAL_H_

#include <stdbool.h>

// Virtual Terminal API functions
// TODO: add macros for styles and default colors also add function that accept hex and return the color


/**
 * Get color from Hex
 * char* my_window_color = color_from_hex("#ff0000")
 * @param width: terminal width in characters
 * @param height: terminal height in characters
 * @return: pointer to new virtual terminal, or NULL on failure
 */
char* color_from_hex(const char* , bool);

#define RMP_BOLD
#define RMP_ITALIC

typedef struct VirtualTerminal VirtualTerminal;

/**
 * Initialize a virtual terminal
 * @param width: terminal width in characters
 * @param height: terminal height in characters
 * @return: pointer to new virtual terminal, or NULL on failure
 */
VirtualTerminal* rmp_vt_init(int width, int height);

/**
 * Destroy a virtual terminal and free its memory
 * @param vt: virtual terminal to destroy
 */
void rmp_vt_destroy(VirtualTerminal* vt);

/**
 * Clear the virtual terminal
 * @param vt: virtual terminal to clear
 */
void rmp_vt_clear(VirtualTerminal* vt);

/**
 * Set a character at a specific position
 * @param vt: virtual terminal
 * @param x: x coordinate (1-based)
 * @param y: y coordinate (1-based)
 * @param ch: character to set
 * @param fg: foreground color (ANSI code string)
 * @param bg: background color (ANSI code string)
 * @param style: style (ANSI code string)
 */
void rmp_vt_setchar(VirtualTerminal* vt, int x, int y, const char* ch, const char* fg, const char* bg, const char* style);

/**
 * Draw a box with optional title
 * @param vt: virtual terminal
 * @param title: title for the box
 * @param x: x coordinate of top-left corner (1-based)
 * @param y: y coordinate of top-left corner (1-based)
 * @param width: width of the box
 * @param height: height of the box
 * @param h_line: horizontal line character
 * @param v_line: vertical line character
 * @param tl_corner: top-left corner character
 * @param tr_corner: top-right corner character
 * @param bl_corner: bottom-left corner character
 * @param br_corner: bottom-right corner character
 * @param fg: foreground color
 * @param bg: background color
 */
void rmp_vt_draw_box(VirtualTerminal* vt, const char* title, int x, int y, int width, int height,
                     const char* h_line, const char* v_line, const char* tl_corner,
                     const char* tr_corner, const char* bl_corner, const char* br_corner,
                     const char* fg, const char* bg);

/**
 * Write text with clipping
 * @param vt: virtual terminal
 * @param x: x coordinate (1-based)
 * @param y: y coordinate (1-based)
 * @param text: text to write
 * @param max_cols: maximum number of columns to write
 * @param fg: foreground color
 * @param bg: background color
 * @param style: style
 * @return: number of columns written
 */
int rmp_vt_writetext_clipped(VirtualTerminal* vt, int x, int y, const char* text, int max_cols, const char* fg, const char* bg, const char* style);

/**
 * Write text without clipping
 * @param vt: virtual terminal
 * @param x: x coordinate (1-based)
 * @param y: y coordinate (1-based)
 * @param text: text to write
 * @param fg: foreground color
 * @param bg: background color
 * @param style: style
 */
void rmp_vt_writetext(VirtualTerminal* vt, int x, int y, const char* text, const char* fg, const char* bg, const char* style);

/**
 * Merge one virtual terminal into another
 * @param dest: destination virtual terminal
 * @param src: source virtual terminal
 * @param offset_x: x offset for merging
 * @param offset_y: y offset for merging
 */
void rmp_vt_merge(VirtualTerminal* dest, VirtualTerminal* src, int offset_x, int offset_y);

/**
 * Render the virtual terminal to stdout
 * @param vt: virtual terminal to render
 */
void rmp_vt_render(VirtualTerminal* vt);

/**
 * Move the cursor to a specific position
 * @param vt: virtual terminal
 * @param x: x coordinate (1-based)
 * @param y: y coordinate (1-based)
 */
void rmp_vt_movecursor(VirtualTerminal* vt, int x, int y);

/**
 * Get the size of the virtual terminal
 * @param vt: virtual terminal
 * @param[out] width: pointer to store width
 * @param[out] height: pointer to store height
 */
void rmp_vt_getsize(VirtualTerminal* vt, int* width, int* height);

/**
 * Resize the virtual terminal
 * @param vt: virtual terminal
 * @param new_width: new width
 * @param new_height: new height
 * @return: true on success, false on failure
 */
bool rmp_vt_resize(VirtualTerminal* vt, int new_width, int new_height);

/**
 * Move cursor up
 * @param vt: virtual terminal
 * @param steps: number of steps to move
 */
void rmp_vt_moveup(VirtualTerminal* vt, int steps);

/**
 * Move cursor down
 * @param vt: virtual terminal
 * @param steps: number of steps to move
 */
void rmp_vt_movedown(VirtualTerminal* vt, int steps);

/**
 * Move cursor left
 * @param vt: virtual terminal
 * @param steps: number of steps to move
 */
void rmp_vt_moveleft(VirtualTerminal* vt, int steps);

/**
 * Move cursor right
 * @param vt: virtual terminal
 * @param steps: number of steps to move
 */
void rmp_vt_moveright(VirtualTerminal* vt, int steps);

/**
 * Copy a virtual terminal
 * @param src: source virtual terminal
 * @return: pointer to new copy, or NULL on failure
 */
VirtualTerminal* rmp_vt_copy(VirtualTerminal* src);

#endif // RMP_VIRTUALTERMINAL_H_

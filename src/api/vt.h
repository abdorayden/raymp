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

#ifndef VIRTUALTERMINALRMP_C
#define VIRTUALTERMINALRMP_C

#include "../third_party/rdn/rdn_native.h"
#include "../third_party/rdn/stack.h"

// reffrences:
//  - utf-8 article : https://en.wikipedia.org/wiki/UTF-8
//  - https://www.youtube.com/watch?v=MijmeoH9LT4
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
    #include <uchar.h>   // for char32_t
#endif

// Cross-platform wcwidth implementation
// i added a simple wcwidth implementation for windows
// on unix we can just use the system wcwidth
// for more cross platform handling
#ifdef PLATFORM_WINDOWS
    // Define a function that works with char32_t for proper Unicode handling
    int unicode_width(char32_t ucs) {
        if (ucs == 0) return 0;
        if (ucs < 32 || ucs == 127) return 0;
        if (ucs < 127) return 1;

        if ((ucs >= 0x1100 && ucs <= 0x115F) ||  // Hangul Jamo
            (ucs >= 0x2800 && ucs <= 0x28FF) ||  // Braille Patterns
            (ucs >= 0x2E80 && ucs <= 0x2EFF) ||  // CJK Radicals Supplement
            (ucs >= 0x2F00 && ucs <= 0x2FDF) ||  // Kangxi Radicals
            (ucs >= 0x3000 && ucs <= 0x303F) ||  // CJK Symbols and Punctuation
            (ucs >= 0x3040 && ucs <= 0x309F) ||  // Hiragana
            (ucs >= 0x30A0 && ucs <= 0x30FF) ||  // Katakana
            (ucs >= 0x3100 && ucs <= 0x312F) ||  // Bopomofo
            (ucs >= 0x3130 && ucs <= 0x318F) ||  // Hangul Compatibility Jamo
            (ucs >= 0x3190 && ucs <= 0x319F) ||  // Kanbun
            (ucs >= 0x31A0 && ucs <= 0x31BF) ||  // Bopomofo Extended
            (ucs >= 0x31C0 && ucs <= 0x31EF) ||  // CJK Strokes
            (ucs >= 0x31F0 && ucs <= 0x31FF) ||  // Katakana Phonetic Extensions
            (ucs >= 0x3200 && ucs <= 0x32FF) ||  // Enclosed CJK Letters and Months
            (ucs >= 0x3300 && ucs <= 0x33FF) ||  // CJK Compatibility
            (ucs >= 0x3400 && ucs <= 0x4DBF) ||  // CJK Unified Ideographs Extension A
            (ucs >= 0x4E00 && ucs <= 0x9FFF) ||  // CJK Unified Ideographs
            (ucs >= 0xA000 && ucs <= 0xA48F) ||  // Yi Syllables
            (ucs >= 0xA490 && ucs <= 0xA4CF) ||  // Yi Radicals
            (ucs >= 0xAC00 && ucs <= 0xD7AF) ||  // Hangul Syllables
            (ucs >= 0xF900 && ucs <= 0xFAFF) ||  // CJK Compatibility Ideographs
            (ucs >= 0xFE10 && ucs <= 0xFE1F) ||  // Vertical Forms
            (ucs >= 0xFE30 && ucs <= 0xFE4F) ||  // CJK Compatibility Forms
            (ucs >= 0xFE50 && ucs <= 0xFE6F) ||  // Small Form Variants
            (ucs >= 0xFF00 && ucs <= 0xFFEF)) {  // Halfwidth and Fullwidth Forms
            return 2;
        }

        return 1;
    }
#else
    int wcwidth(wchar_t);
    // on unix, we can use system wcwidth
    inline int unicode_width(char32_t ucs) {
        // cast to wchar_t for system wcwidth function
        // this should work for most cases since unicode codepoints <= 0x10ffff
        return wcwidth((wchar_t)(ucs <= WCHAR_MAX ? ucs : '?'));
    }
#endif

#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <limits.h>

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

#ifdef PLATFORM_WINDOWS
    #ifndef MB_CUR_MAX
        #define MB_CUR_MAX 4
    #endif
#endif

    // NoBorder = {
    //     " ",
    //     " ",
    //     " ",
    //     " ",
    //     " ",
    //     " ",
    //     " ",
    //     " ",
    //     " ",
    //     " ",
    //     " ",
    // },
    // --- @type table
    // LightBorder = {
    //     -- Light border set (single-line)
    //     "─", -- Light horizontal line (U+2500)
    //     "│", -- Light vertical line (U+2502)
    //     "┌", -- Light down and right corner (U+250C)
    //     "┐", -- Light down and left corner (U+2510)
    //     "└", -- Light up and right corner (U+2514)
    //     "┘", -- Light up and left corner (U+2518)
    //     "├", -- Light vertical and right tee (U+251C)
    //     "┤", -- Light vertical and left tee (U+2524)
    //     "┬", -- Light down and horizontal tee (U+252C)
    //     "┴", -- Light up and horizontal tee (U+2534)
    //     "┼", -- Light vertical and horizontal cross (U+253C)
    // },
    // --- @type table
    // HeavyBorder = {
    //     -- Heavy border set (double-line)
    //     "═", -- Heavy horizontal line (U+2550)
    //     "║", -- Heavy vertical line (U+2551)
    //     "╔", -- Heavy down and right corner (U+2554)
    //     "╗", -- Heavy down and left corner (U+2557)
    //     "╚", -- Heavy up and right corner (U+255A)
    //     "╝", -- Heavy up and left corner (U+255D)
    //     "╠", -- Heavy vertical and right tee (U+2560)
    //     "╣", -- Heavy vertical and left tee (U+2563)
    //     "╦", -- Heavy down and horizontal tee (U+2566)
    //     "╩", -- Heavy up and horizontal tee (U+2569)
    //     "╬", -- Heavy vertical and horizontal cross (U+256C)
    // },
    // --- @type table
    // RoundedCorners = {
    //     "─", -- Light horizontal line (U+2500)
    //     "│", -- Light vertical line (U+2502)
    //     "╭", -- Light down and right corner (U+250C)
    //     "╮", -- Light down and left corner (U+2510)
    //     "╰", -- Light up and right corner (U+2514)
    //     "╯", -- Light up and left corner (U+2518)
    //     "├", -- Light vertical and right tee (U+251C)
    //     "┤", -- Light vertical and left tee (U+2524)
    //     "┬", -- Light down and horizontal tee (U+252C)
    //     "┴", -- Light up and horizontal tee (U+2534)
    //     "┼", -- Light vertical and horizontal cross (U+253C)
    // },

typedef enum {
    NoBorder,
    LightBorder,
    HeavyBorder,
    RoundedCorners,
    __border_count
} BorderStyle;

// TODO: introduce unwrup for lists to push all the elements into the stack
typedef char byte ;

static const char* Border[__border_count][16] = {
    [NoBorder] = { 
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
        " ",
    },
    [LightBorder] = {
         "─", // Light horizontal line (U+2500)
         "│", // Light vertical line (U+2502)
         "┌", // Light down and right corner (U+250C)
         "┐", // Light down and left corner (U+2510)
         "└", // Light up and right corner (U+2514)
         "┘", // Light up and left corner (U+2518)
         "├", // Light vertical and right tee (U+251C)
         "┤", // Light vertical and left tee (U+2524)
         "┬", // Light down and horizontal tee (U+252C)
         "┴", // Light up and horizontal tee (U+2534)
         "┼", // Light vertical and horizontal cross (U+253C)
    },
    [HeavyBorder] = {
         "═", // Heavy horizontal line (U+2550)
         "║", // Heavy vertical line (U+2551)
         "╔", // Heavy down and right corner (U+2554)
         "╗", // Heavy down and left corner (U+2557)
         "╚", // Heavy up and right corner (U+255A)
         "╝", // Heavy up and left corner (U+255D)
         "╠", // Heavy vertical and right tee (U+2560)
         "╣", // Heavy vertical and left tee (U+2563)
         "╦", // Heavy down and horizontal tee (U+2566)
         "╩", // Heavy up and horizontal tee (U+2569)
         "╬", // Heavy vertical and horizontal cross (U+256C)
    },
    [RoundedCorners] = {
         "─", // Light horizontal line (U+2500)
         "│", // Light vertical line (U+2502)
         "╭", // Light down and right corner (U+250C)
         "╮", // Light down and left corner (U+2510)
         "╰", // Light up and right corner (U+2514)
         "╯", // Light up and left corner (U+2518)
         "├", // Light vertical and right tee (U+251C)
         "┤", // Light vertical and left tee (U+2524)
         "┬", // Light down and horizontal tee (U+252C)
         "┴", // Light up and horizontal tee (U+2534)
         "┼", // Light vertical and horizontal cross (U+253C)
    }
};

// TODO: manage all params as list to called like this 
// (x y w h "hello") my-func

// 300 200 rmp_vt_init
bool rmp_vt_init(RDNApi* api);
bool rmp_vt_distroy(RDNApi* api);
bool rmp_vt_clear(RDNApi* api);
bool rmp_vt_setchar(RDNApi* api);
bool rmp_vt_writetext(RDNApi* api);
bool rmp_vt_open_win(RDNApi* api);
bool rmp_vt_merge(RDNApi* api);
bool rmp_vt_render(RDNApi* api);
bool rmp_vt_movecursor(RDNApi* api);
bool rmp_vt_getsize(RDNApi* api);
bool rmp_vt_resize(RDNApi* api);
bool rmp_vt_moveup(RDNApi* api);
bool rmp_vt_movedown(RDNApi* api);
bool rmp_vt_moveleft(RDNApi* api);
bool rmp_vt_moveright(RDNApi* api);
bool rmp_vt_copy(RDNApi* api);


#endif // VIRTUALTERMINALRMP_C

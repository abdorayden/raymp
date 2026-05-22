/****************************************************************************************/
/*  Copyright (c) 2025-2026 Ray Den                                                     */
/*                                                                                      */
/*  Permission is hereby granted, free of charge, to any person obtaining a copy        */
/*  of this software and associated documentation files (the "Software"), to deal       */
/*  in the Software without restriction, including without limitation the rights        */
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell           */
/*  copies of the Software, and to permit persons to whom the Software is               */
/*  furnished to do so, subject to the following conditions:                            */
/*                                                                                      */
/*  The above copyright notice and this permission notice shall be included in          */
/*  all copies or substantial portions of the Software.                                 */
/*                                                                                      */
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR           */
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,             */
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE          */
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER               */
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,        */
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN            */
/*  THE SOFTWARE.                                                                        */
/****************************************************************************************/

#include "color.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

bool rmp_color(RDNApi *api) {
    const char *hex = api->to_string(api, -1);
    long type;
    if (!api->to_integer(api, -2, &type)) {
        api->pop(api, 2);
        api->push_string(api, "");
        return true;
    }

    long r = 0, g = 0, b = 0;

    if (hex) {
        if (hex[0] == '#') {
            hex++;
        }

        size_t len = strlen(hex);
        if (len >= 6) {
            char component[3] = {0};
            component[0] = hex[0]; component[1] = hex[1];
            r = strtol(component, NULL, 16);
            component[0] = hex[2]; component[1] = hex[3];
            g = strtol(component, NULL, 16);
            component[0] = hex[4]; component[1] = hex[5];
            b = strtol(component, NULL, 16);
        } else if (len >= 3) {
            char component[3] = {0};
            component[0] = hex[0]; component[1] = hex[0];
            r = strtol(component, NULL, 16);
            component[0] = hex[1]; component[1] = hex[1];
            g = strtol(component, NULL, 16);
            component[0] = hex[2]; component[1] = hex[2];
            b = strtol(component, NULL, 16);
        }
    }

    api->pop(api, 2);

    char ansi_code[32];
    if (type == 0) {
        snprintf(ansi_code, sizeof(ansi_code), "\x1b[38;2;%ld;%ld;%ldm", r, g, b);
    } else {
        snprintf(ansi_code, sizeof(ansi_code), "\x1b[48;2;%ld;%ld;%ldm", r, g, b);
    }

    api->push_string(api, ansi_code);
    return true;
}

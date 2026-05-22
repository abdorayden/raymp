#include "keyboard.h"

#include <stdbool.h>

#if defined(_WIN32)
#include <windows.h>

static bool keyboard_initialized = false;
static HANDLE keyboard_h_stdin;
static DWORD keyboard_old_mode;

static void init_console(void) {
    if (!keyboard_initialized) {
        keyboard_h_stdin = GetStdHandle(STD_INPUT_HANDLE);
        GetConsoleMode(keyboard_h_stdin, &keyboard_old_mode);
        SetConsoleMode(keyboard_h_stdin, ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT);
        keyboard_initialized = true;
    }
}

static void restore_console(void) {
    if (keyboard_initialized) {
        SetConsoleMode(keyboard_h_stdin, keyboard_old_mode);
        keyboard_initialized = false;
    }
}

static RMPKey handle_keys(void) {
    INPUT_RECORD ir_in_buf;
    DWORD count = 0;

    init_console();

    if (!PeekConsoleInput(keyboard_h_stdin, &ir_in_buf, 1, &count) || count == 0) {
        return KEY_NONE;
    }

    ReadConsoleInput(keyboard_h_stdin, &ir_in_buf, 1, &count);
    if (ir_in_buf.EventType == KEY_EVENT && ir_in_buf.Event.KeyEvent.bKeyDown) {
        KEY_EVENT_RECORD key_event = ir_in_buf.Event.KeyEvent;
        char ch = key_event.uChar.AsciiChar;
        DWORD ctrl_state = key_event.dwControlKeyState;
        WORD vk = key_event.wVirtualKeyCode;

        if (ctrl_state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) {
            if (ch >= 1 && ch <= 26) {
                return (RMPKey)(KEY_CTRL_A + (ch - 1));
            }
        }

        if (ctrl_state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) {
            if (ch >= 'a' && ch <= 'z') {
                return (RMPKey)(KEY_ALT_A + (ch - 'a'));
            }
            if (ch >= 'A' && ch <= 'Z') {
                return (RMPKey)(KEY_ALT_A + (ch - 'A'));
            }
        }

        if (ch >= 32 && ch <= 126) {
            if (ch >= 'a' && ch <= 'z') return (RMPKey)(KEY_A + (ch - 'a'));
            if (ch >= 'A' && ch <= 'Z') return (RMPKey)(KEY_SHIFT_A + (ch - 'A'));
            if (ch >= '0' && ch <= '9') return (RMPKey)(KEY_0 + (ch - '0'));

            switch (ch) {
                case '#': return KEY_HASHTAG;
                case '$': return KEY_DOLAR;
                case '%': return KEY_PERSANT;
                case '*': return KEY_STAR;
                case '+': return KEY_PLUS;
                case '-': return KEY_MINUS;
                case '.': return KEY_DOT;
                case ';': return KEY_SEMICOL;
                case '<': return KEY_LT;
                case '>': return KEY_GT;
                case '?': return KEY_QUISTION_MARK;
                case '@': return KEY_AT;
                case '[': return KEY_OPCURB;
                case '\\': return KEY_BACK_SLASH;
                case ']': return KEY_CLCURB;
                case '_': return KEY_UNDERS;
                case '`': return KEY_BACKTICK;
                case '{': return KEY_OPEN_BRAKET;
                case '|': return KEY_BAR;
                case '}': return KEY_CLOSED_BRAKET;
                case '"': return KEY_DBL_QUOTE;
                case '\'': return KEY_SINGLE_QOUTE;
                case ' ': return KEY_SPACE;
                case '/': return KEY_SLASH;
                case ':': return KEY_COLON;
                case ',': return KEY_COMMA;
                case '(': return KEY_OPPAERN;
                case ')': return KEY_CLPAREN;
                case '=': return KEY_EQUAL;
            }
        }

        switch (vk) {
            case VK_ESCAPE: return KEY_ESCAPE;
            case VK_TAB: return KEY_TAB;
            case VK_DELETE: return KEY_DELETE;
            case VK_HOME: return KEY_HOME;
            case VK_END: return KEY_END;
            case VK_BACK: return KEY_BACKSPACE;
            case VK_RETURN: return KEY_ENTER;
            case VK_LEFT: return KEY_LEFT;
            case VK_UP: return KEY_UP;
            case VK_RIGHT: return KEY_RIGHT;
            case VK_DOWN: return KEY_DOWN;
            case VK_F1: return KEY_F1;
            case VK_F2: return KEY_F2;
            case VK_F3: return KEY_F3;
            case VK_F4: return KEY_F4;
            case VK_F5: return KEY_F5;
            case VK_F6: return KEY_F6;
            case VK_F7: return KEY_F7;
            case VK_F8: return KEY_F8;
            case VK_F9: return KEY_F9;
            case VK_F10: return KEY_F10;
            case VK_F11: return KEY_F11;
            case VK_F12: return KEY_F12;
        }
    }

    return KEY_NONE;
}

#else

#include <stdlib.h>
#include <termios.h>
#include <unistd.h>

static struct termios keyboard_orig_termios;
static bool keyboard_initialized = false;

static void keyboard_init_terminal(void) {
    if (!keyboard_initialized) {
        struct termios new_termios;
        tcgetattr(STDIN_FILENO, &keyboard_orig_termios);
        new_termios = keyboard_orig_termios;
        new_termios.c_lflag &= ~(ICANON | ECHO);
        new_termios.c_cc[VMIN] = 0;
        new_termios.c_cc[VTIME] = 0;
        tcsetattr(STDIN_FILENO, TCSANOW, &new_termios);
        keyboard_initialized = true;
    }
}

static void keyboard_restore_terminal(void) {
    if (keyboard_initialized) {
        tcsetattr(STDIN_FILENO, TCSANOW, &keyboard_orig_termios);
        keyboard_initialized = false;
    }
}

#define CTRL_KEY(k) ((k) & 0x1f)

static RMPKey handle_keys(void) {
    char c = 0;
    int bytes = 0;

    keyboard_init_terminal();
    bytes = (int)read(STDIN_FILENO, &c, 1);
    if (bytes <= 0) {
        return KEY_NONE;
    }

    switch (c) {
        case CTRL_KEY('a'): return KEY_CTRL_A;
        case CTRL_KEY('b'): return KEY_CTRL_B;
        case CTRL_KEY('c'): return KEY_CTRL_C;
        case CTRL_KEY('d'): return KEY_CTRL_D;
        case CTRL_KEY('e'): return KEY_CTRL_E;
        case CTRL_KEY('f'): return KEY_CTRL_F;
        case CTRL_KEY('g'): return KEY_CTRL_G;
        case CTRL_KEY('h'): return KEY_CTRL_H;
        case CTRL_KEY('k'): return KEY_CTRL_K;
        case CTRL_KEY('l'): return KEY_CTRL_L;
        case CTRL_KEY('n'): return KEY_CTRL_N;
        case CTRL_KEY('o'): return KEY_CTRL_O;
        case CTRL_KEY('p'): return KEY_CTRL_P;
        case CTRL_KEY('q'): return KEY_CTRL_Q;
        case CTRL_KEY('r'): return KEY_CTRL_R;
        case CTRL_KEY('s'): return KEY_CTRL_S;
        case CTRL_KEY('t'): return KEY_CTRL_T;
        case CTRL_KEY('u'): return KEY_CTRL_U;
        case CTRL_KEY('v'): return KEY_CTRL_V;
        case CTRL_KEY('w'): return KEY_CTRL_W;
        case CTRL_KEY('x'): return KEY_CTRL_X;
        case CTRL_KEY('y'): return KEY_CTRL_Y;
        case CTRL_KEY('z'): return KEY_CTRL_Z;
        case '\t': return KEY_TAB;
        case '\n':
        case '\r': return KEY_ENTER;
        case ' ': return KEY_SPACE;
        case 127: return KEY_BACKSPACE;
        case '0': return KEY_0;
        case '1': return KEY_1;
        case '2': return KEY_2;
        case '3': return KEY_3;
        case '4': return KEY_4;
        case '5': return KEY_5;
        case '6': return KEY_6;
        case '7': return KEY_7;
        case '8': return KEY_8;
        case '9': return KEY_9;
        case 'a': return KEY_A;
        case 'b': return KEY_B;
        case 'c': return KEY_C;
        case 'd': return KEY_D;
        case 'e': return KEY_E;
        case 'f': return KEY_F;
        case 'g': return KEY_G;
        case 'h': return KEY_H;
        case 'i': return KEY_I;
        case 'j': return KEY_J;
        case 'k': return KEY_K;
        case 'l': return KEY_L;
        case 'm': return KEY_M;
        case 'n': return KEY_N;
        case 'o': return KEY_O;
        case 'p': return KEY_P;
        case 'q': return KEY_Q;
        case 'r': return KEY_R;
        case 's': return KEY_S;
        case 't': return KEY_T;
        case 'u': return KEY_U;
        case 'v': return KEY_V;
        case 'w': return KEY_W;
        case 'x': return KEY_X;
        case 'y': return KEY_Y;
        case 'z': return KEY_Z;
        case 'A': return KEY_SHIFT_A;
        case 'B': return KEY_SHIFT_B;
        case 'C': return KEY_SHIFT_C;
        case 'D': return KEY_SHIFT_D;
        case 'E': return KEY_SHIFT_E;
        case 'F': return KEY_SHIFT_F;
        case 'G': return KEY_SHIFT_G;
        case 'H': return KEY_SHIFT_H;
        case 'I': return KEY_SHIFT_I;
        case 'J': return KEY_SHIFT_J;
        case 'K': return KEY_SHIFT_K;
        case 'L': return KEY_SHIFT_L;
        case 'M': return KEY_SHIFT_M;
        case 'N': return KEY_SHIFT_N;
        case 'O': return KEY_SHIFT_O;
        case 'P': return KEY_SHIFT_P;
        case 'Q': return KEY_SHIFT_Q;
        case 'R': return KEY_SHIFT_R;
        case 'S': return KEY_SHIFT_S;
        case 'T': return KEY_SHIFT_T;
        case 'U': return KEY_SHIFT_U;
        case 'V': return KEY_SHIFT_V;
        case 'W': return KEY_SHIFT_W;
        case 'X': return KEY_SHIFT_X;
        case 'Y': return KEY_SHIFT_Y;
        case 'Z': return KEY_SHIFT_Z;
        case '#': return KEY_HASHTAG;
        case '$': return KEY_DOLAR;
        case '%': return KEY_PERSANT;
        case '*': return KEY_STAR;
        case '+': return KEY_PLUS;
        case '-': return KEY_MINUS;
        case '.': return KEY_DOT;
        case ';': return KEY_SEMICOL;
        case '<': return KEY_LT;
        case '>': return KEY_GT;
        case '?': return KEY_QUISTION_MARK;
        case '@': return KEY_AT;
        case '[': return KEY_OPCURB;
        case '\\': return KEY_BACK_SLASH;
        case ']': return KEY_CLCURB;
        case '_': return KEY_UNDERS;
        case '`': return KEY_BACKTICK;
        case '{': return KEY_OPEN_BRAKET;
        case '|': return KEY_BAR;
        case '}': return KEY_CLOSED_BRAKET;
        case '"': return KEY_DBL_QUOTE;
        case '\'': return KEY_SINGLE_QOUTE;
        case '/': return KEY_SLASH;
        case ':': return KEY_COLON;
        case ',': return KEY_COMMA;
        case '(': return KEY_OPPAERN;
        case ')': return KEY_CLPAREN;
        case '=': return KEY_EQUAL;
        case '\033': {
            char seq[4];

            if (read(STDIN_FILENO, &seq[0], 1) != 1) return KEY_ESCAPE;
            if (seq[0] >= 'a' && seq[0] <= 'z') return (RMPKey)(KEY_ALT_A + (seq[0] - 'a'));
            if (seq[0] >= 'A' && seq[0] <= 'Z') return (RMPKey)(KEY_ALT_A + (seq[0] - 'A'));

            if (seq[0] == '[') {
                if (read(STDIN_FILENO, &seq[1], 1) != 1) return KEY_NONE;
                if (seq[1] >= '0' && seq[1] <= '9') {
                    if (read(STDIN_FILENO, &seq[2], 1) != 1) return KEY_NONE;
                    if (seq[2] == '~') {
                        switch (seq[1]) {
                            case '1': return KEY_HOME;
                            case '3': return KEY_DELETE;
                            case '4': return KEY_END;
                            case '7': return KEY_HOME;
                            case '8': return KEY_END;
                        }
                    } else if (seq[2] >= '0' && seq[2] <= '9') {
                        if (read(STDIN_FILENO, &seq[3], 1) == 1 && seq[3] == '~') {
                            char num_str[3] = {seq[1], seq[2], '\0'};
                            int code = atoi(num_str);
                            switch (code) {
                                case 11: return KEY_F1;
                                case 12: return KEY_F2;
                                case 13: return KEY_F3;
                                case 14: return KEY_F4;
                                case 15: return KEY_F5;
                                case 17: return KEY_F6;
                                case 18: return KEY_F7;
                                case 19: return KEY_F8;
                                case 20: return KEY_F9;
                                case 21: return KEY_F10;
                                case 23: return KEY_F11;
                                case 24: return KEY_F12;
                            }
                        }
                    }
                } else {
                    switch (seq[1]) {
                        case 'A': return KEY_UP;
                        case 'B': return KEY_DOWN;
                        case 'C': return KEY_RIGHT;
                        case 'D': return KEY_LEFT;
                        case 'H': return KEY_HOME;
                        case 'F': return KEY_END;
                    }
                }
            } else if (seq[0] == 'O') {
                if (read(STDIN_FILENO, &seq[1], 1) == 1) {
                    switch (seq[1]) {
                        case 'F': return KEY_END;
                        case 'H': return KEY_HOME;
                        case 'P': return KEY_F1;
                        case 'Q': return KEY_F2;
                        case 'R': return KEY_F3;
                        case 'S': return KEY_F4;
                    }
                }
            }

            return KEY_ESCAPE;
        }
        default:
            return KEY_NONE;
    }
}

#endif

bool rmp_get_key(RDNApi *api) {
    api->push_integer(api, (long)handle_keys());
    return true;
}

bool rmp_close_key(RDNApi *api) {
    (void)api;
#if defined(_WIN32)
    restore_console();
#else
    keyboard_restore_terminal();
#endif
    api->push_boolean(api, true);
    return true;
}

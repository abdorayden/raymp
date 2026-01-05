#include <stdbool.h>
#include "../include/rmp_keyboard.h"

// Key enumeration (complete version)
typedef enum {
	// Control keys
	KEY_CTRL_A, KEY_CTRL_B, KEY_CTRL_C, KEY_CTRL_D, KEY_CTRL_E,
	KEY_CTRL_F, KEY_CTRL_G, KEY_CTRL_H ,
	KEY_CTRL_K, KEY_CTRL_L, KEY_CTRL_M, KEY_CTRL_N, KEY_CTRL_O,
	KEY_CTRL_P, KEY_CTRL_Q, KEY_CTRL_R, KEY_CTRL_S, KEY_CTRL_T,
	KEY_CTRL_U, KEY_CTRL_V, KEY_CTRL_W, KEY_CTRL_X, KEY_CTRL_Y,
	KEY_CTRL_Z,

	// Alt keys
	KEY_ALT_A, KEY_ALT_B, KEY_ALT_C, KEY_ALT_D, KEY_ALT_E,
	KEY_ALT_F, KEY_ALT_G, KEY_ALT_H, KEY_ALT_I, KEY_ALT_J,
	KEY_ALT_K, KEY_ALT_L, KEY_ALT_M, KEY_ALT_N, KEY_ALT_O,
	KEY_ALT_P, KEY_ALT_Q, KEY_ALT_R, KEY_ALT_S, KEY_ALT_T,
	KEY_ALT_U, KEY_ALT_V, KEY_ALT_W, KEY_ALT_X, KEY_ALT_Y,
	KEY_ALT_Z,

	// Special keys
	KEY_ENTER, KEY_SPACE, KEY_ESCAPE, KEY_UP, KEY_DOWN,
	KEY_LEFT, KEY_RIGHT, KEY_TAB, KEY_DELETE, KEY_HOME,KEY_END,KEY_BACKSPACE,

	// Function keys
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6,
	KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,

	// Alphabet keys (lowercase)
	KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G, KEY_H,
	KEY_I, KEY_J, KEY_K, KEY_L, KEY_M, KEY_N, KEY_O, KEY_P,
	KEY_Q, KEY_R, KEY_S, KEY_T, KEY_U, KEY_V, KEY_W, KEY_X,
	KEY_Y, KEY_Z,

	// Alphabet keys (uppercase/shifted)
	KEY_SHIFT_A, KEY_SHIFT_B, KEY_SHIFT_C, KEY_SHIFT_D, KEY_SHIFT_E,
	KEY_SHIFT_F, KEY_SHIFT_G, KEY_SHIFT_H, KEY_SHIFT_I, KEY_SHIFT_J,
	KEY_SHIFT_K, KEY_SHIFT_L, KEY_SHIFT_M, KEY_SHIFT_N, KEY_SHIFT_O,
	KEY_SHIFT_P, KEY_SHIFT_Q, KEY_SHIFT_R, KEY_SHIFT_S, KEY_SHIFT_T,
	KEY_SHIFT_U, KEY_SHIFT_V, KEY_SHIFT_W, KEY_SHIFT_X, KEY_SHIFT_Y,
	KEY_SHIFT_Z,

	// Number keys
	KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5,
	KEY_6, KEY_7, KEY_8, KEY_9,

	// Symbol keys
	KEY_PLUS, KEY_MINUS, KEY_GT, KEY_LT, KEY_HASHTAG,
	KEY_DOLAR, KEY_PERSANT, KEY_STAR, KEY_DOT, KEY_UNDERS,
	KEY_SEMICOL, KEY_QUISTION_MARK, KEY_AT, KEY_OPCURB,
	KEY_CLCURB, KEY_BACK_SLASH, KEY_BACKTICK, KEY_OPEN_BRAKET,
	KEY_CLOSED_BRAKET, KEY_BAR, KEY_DBL_QUOTE, KEY_SINGLE_QOUTE,KEY_SLASH, KEY_COLON,KEY_COMMA,
    KEY_OPPAERN , KEY_CLPAREN , KEY_EQUAL,
    NONE
} Keys;

#if defined(_WIN32)
// Windows implementation
#include <windows.h>

static bool initialized = false;
static HANDLE hStdin;
static DWORD oldMode;

static void init_console() {
	if (!initialized) {
		hStdin = GetStdHandle(STD_INPUT_HANDLE);
		GetConsoleMode(hStdin, &oldMode);
		SetConsoleMode(hStdin, ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT);
		initialized = true;
	}
}

static void restore_console() {
	if (initialized) {
		SetConsoleMode(hStdin, oldMode);
		initialized = false;
	}
}

static Keys handle_keys() {
	init_console();

	INPUT_RECORD irInBuf;
	DWORD cNumRead;

	// Non-blocking check
	if (!PeekConsoleInput(hStdin, &irInBuf, 1, &cNumRead) || cNumRead == 0) {
		return NONE;
	}

	ReadConsoleInput(hStdin, &irInBuf, 1, &cNumRead);

	if (irInBuf.EventType == KEY_EVENT && irInBuf.Event.KeyEvent.bKeyDown) {
		KEY_EVENT_RECORD keyEvent = irInBuf.Event.KeyEvent;
		char ch = keyEvent.uChar.AsciiChar;
		DWORD ctrlState = keyEvent.dwControlKeyState;
		WORD vk = keyEvent.wVirtualKeyCode;

		// Handle Ctrl+key combinations
		if (ctrlState & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) {
			if (ch >= 1 && ch <= 26) return KEY_CTRL_A + (ch - 1);
		}

		// Handle Alt+key combinations
		if (ctrlState & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED)) {
			if (ch >= 'a' && ch <= 'z') return KEY_ALT_A + (ch - 'a');
			if (ch >= 'A' && ch <= 'Z') return KEY_ALT_A + (ch - 'A');
		}

		// Handle regular keys
		if (ch >= 32 && ch <= 126) {
			if (ch >= 'a' && ch <= 'z') return KEY_A + (ch - 'a');
			if (ch >= 'A' && ch <= 'Z') return KEY_SHIFT_A + (ch - 'A');
			if (ch >= '0' && ch <= '9') return KEY_0 + (ch - '0');

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

		// Handle special keys
		switch (vk) {
			case VK_ESCAPE: return KEY_ESCAPE;
			case VK_TAB: return KEY_TAB;
			case VK_DELETE : return KEY_DELETE;
			case VK_HOME : return KEY_HOME;
			case VK_END : return KEY_END;
			case VK_BACK : return KEY_BACKSPACE;
			case VK_RETURN: return KEY_ENTER;
			case VK_LEFT: return KEY_LEFT;
			case VK_UP: return KEY_UP;
			case VK_RIGHT: return KEY_RIGHT;
			case VK_DOWN: return KEY_DOWN;

			// Function keys
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

	return NONE;
}

#else
// POSIX implementation (Linux/macOS)
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>

static struct termios orig_termios;
static bool initialized = false;

static void init_terminal() {
	if (!initialized) {
		tcgetattr(STDIN_FILENO, &orig_termios);
		struct termios new_termios = orig_termios;
		new_termios.c_lflag &= ~(ICANON | ECHO);
		new_termios.c_cc[VMIN] = 0;
		new_termios.c_cc[VTIME] = 0;
		tcsetattr(STDIN_FILENO, TCSANOW, &new_termios);
		initialized = true;
	}
}

static void restore_terminal() {
	if (initialized) {
		tcsetattr(STDIN_FILENO, TCSANOW, &orig_termios);
		initialized = false;
	}
}

#define CTRL_KEY(k) ((k) & 0x1f)

/*
 *  Handles F1-F12, Alt+key, and other special keys for POSIX systems
 *  by parsing terminal escape sequences.
 */
static Keys handle_keys() {
	init_terminal();

	char c;
	int bytes = read(STDIN_FILENO, &c, 1);
	if (bytes <= 0) return NONE;

	switch (c) {
		// Control keys
		case CTRL_KEY('a') : return KEY_CTRL_A;
		case CTRL_KEY('b') : return KEY_CTRL_B;
		case CTRL_KEY('c') : return KEY_CTRL_C;
		case CTRL_KEY('d') : return KEY_CTRL_D;
		case CTRL_KEY('e') : return KEY_CTRL_E;
		case CTRL_KEY('f') : return KEY_CTRL_F;
		case CTRL_KEY('g') : return KEY_CTRL_G;
		case CTRL_KEY('h') : return KEY_CTRL_H;
		case CTRL_KEY('k') : return KEY_CTRL_K;
		case CTRL_KEY('l') : return KEY_CTRL_L;
		case CTRL_KEY('n') : return KEY_CTRL_N;
		case CTRL_KEY('o') : return KEY_CTRL_O;
		case CTRL_KEY('p') : return KEY_CTRL_P;
		case CTRL_KEY('q') : return KEY_CTRL_Q;
		case CTRL_KEY('r') : return KEY_CTRL_R;
		case CTRL_KEY('s') : return KEY_CTRL_S;
		case CTRL_KEY('t') : return KEY_CTRL_T;
		case CTRL_KEY('u') : return KEY_CTRL_U;
		case CTRL_KEY('v') : return KEY_CTRL_V;
		case CTRL_KEY('w') : return KEY_CTRL_W;
		case CTRL_KEY('x') : return KEY_CTRL_X;
		case CTRL_KEY('y') : return KEY_CTRL_Y;
		case CTRL_KEY('z') : return KEY_CTRL_Z;

				     // Special keys
		case '\t': return KEY_TAB;
		case '\n': return KEY_ENTER;
		case '\r': return KEY_ENTER; // Also carriage return
		case ' ': return KEY_SPACE;
		case 127: return KEY_BACKSPACE;

			  // Numbers
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

			  // Lowercase letters
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

			  // Uppercase letters
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

			  // Symbols
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
			   // Arrow keys (escape sequences) and special keys
		case '\033': {
				     char seq[4];
                     if (read(STDIN_FILENO, &seq[0], 1) != 1) return KEY_ESCAPE;

                     // Alt+key combinations (Alt sends ESC + the key)
                     if (seq[0] >= 'a' && seq[0] <= 'z') {
                         return KEY_ALT_A + (seq[0] - 'a');
                     }
                     if (seq[0] >= 'A' && seq[0] <= 'Z') {
                         return KEY_ALT_A + (seq[0] - 'A');
                     }

                     if (seq[0] == '[') {
                         if (read(STDIN_FILENO, &seq[1], 1) != 1) return NONE;
                         if (seq[1] >= '0' && seq[1] <= '9') {
                             if (read(STDIN_FILENO, &seq[2], 1) != 1) return NONE;
                             if (seq[2] == '~') { // E.g. [3~ for Delete
                                 switch (seq[1]) {
                                     case '1': return KEY_HOME;
                                     case '3': return KEY_DELETE;
                                     case '4': return KEY_END;
                                     case '7': return KEY_HOME;
                                     case '8': return KEY_END;
                                 }
                             } else if (seq[2] >= '0' && seq[2] <= '9') {
                                if (read(STDIN_FILENO, &seq[3], 1) == 1 && seq[3] == '~') { // E.g. [11~ for F1
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
                            switch(seq[1]) {
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

		default: return NONE;
	}
}
#endif

bool rmp_keyboard_init(void) {
	// Initialization is handled internally in handle_keys
	return true;
}

rmp_key_t rmp_get_key(void) {
	Keys key = handle_keys();
	// Map internal keys to public API keys
	switch (key) {
		case KEY_CTRL_A: return RMP_KEY_CTRL_A;
		case KEY_CTRL_B: return RMP_KEY_CTRL_B;
		case KEY_CTRL_C: return RMP_KEY_CTRL_C;
		case KEY_CTRL_D: return RMP_KEY_CTRL_D;
		case KEY_CTRL_E: return RMP_KEY_CTRL_E;
		case KEY_CTRL_F: return RMP_KEY_CTRL_F;
		case KEY_CTRL_G: return RMP_KEY_CTRL_G;
		case KEY_CTRL_H: return RMP_KEY_CTRL_H;
		case KEY_CTRL_K: return RMP_KEY_CTRL_K;
		case KEY_CTRL_L: return RMP_KEY_CTRL_L;
		case KEY_CTRL_M: return RMP_KEY_CTRL_M;
		case KEY_CTRL_N: return RMP_KEY_CTRL_N;
		case KEY_CTRL_O: return RMP_KEY_CTRL_O;
		case KEY_CTRL_P: return RMP_KEY_CTRL_P;
		case KEY_CTRL_Q: return RMP_KEY_CTRL_Q;
		case KEY_CTRL_R: return RMP_KEY_CTRL_R;
		case KEY_CTRL_S: return RMP_KEY_CTRL_S;
		case KEY_CTRL_T: return RMP_KEY_CTRL_T;
		case KEY_CTRL_U: return RMP_KEY_CTRL_U;
		case KEY_CTRL_V: return RMP_KEY_CTRL_V;
		case KEY_CTRL_W: return RMP_KEY_CTRL_W;
		case KEY_CTRL_X: return RMP_KEY_CTRL_X;
		case KEY_CTRL_Y: return RMP_KEY_CTRL_Y;
		case KEY_CTRL_Z: return RMP_KEY_CTRL_Z;
		
		case KEY_ALT_A: return RMP_KEY_ALT_A;
		case KEY_ALT_B: return RMP_KEY_ALT_B;
		case KEY_ALT_C: return RMP_KEY_ALT_C;
		case KEY_ALT_D: return RMP_KEY_ALT_D;
		case KEY_ALT_E: return RMP_KEY_ALT_E;
		case KEY_ALT_F: return RMP_KEY_ALT_F;
		case KEY_ALT_G: return RMP_KEY_ALT_G;
		case KEY_ALT_H: return RMP_KEY_ALT_H;
		case KEY_ALT_I: return RMP_KEY_ALT_I;
		case KEY_ALT_J: return RMP_KEY_ALT_J;
		case KEY_ALT_K: return RMP_KEY_ALT_K;
		case KEY_ALT_L: return RMP_KEY_ALT_L;
		case KEY_ALT_M: return RMP_KEY_ALT_M;
		case KEY_ALT_N: return RMP_KEY_ALT_N;
		case KEY_ALT_O: return RMP_KEY_ALT_O;
		case KEY_ALT_P: return RMP_KEY_ALT_P;
		case KEY_ALT_Q: return RMP_KEY_ALT_Q;
		case KEY_ALT_R: return RMP_KEY_ALT_R;
		case KEY_ALT_S: return RMP_KEY_ALT_S;
		case KEY_ALT_T: return RMP_KEY_ALT_T;
		case KEY_ALT_U: return RMP_KEY_ALT_U;
		case KEY_ALT_V: return RMP_KEY_ALT_V;
		case KEY_ALT_W: return RMP_KEY_ALT_W;
		case KEY_ALT_X: return RMP_KEY_ALT_X;
		case KEY_ALT_Y: return RMP_KEY_ALT_Y;
		case KEY_ALT_Z: return RMP_KEY_ALT_Z;
		
		case KEY_ENTER: return RMP_KEY_ENTER;
		case KEY_SPACE: return RMP_KEY_SPACE;
		case KEY_ESCAPE: return RMP_KEY_ESCAPE;
		case KEY_UP: return RMP_KEY_UP;
		case KEY_DOWN: return RMP_KEY_DOWN;
		case KEY_LEFT: return RMP_KEY_LEFT;
		case KEY_RIGHT: return RMP_KEY_RIGHT;
		case KEY_TAB: return RMP_KEY_TAB;
		case KEY_DELETE: return RMP_KEY_DELETE;
		case KEY_HOME: return RMP_KEY_HOME;
		case KEY_END: return RMP_KEY_END;
		case KEY_BACKSPACE: return RMP_KEY_BACKSPACE;
		
		case KEY_F1: return RMP_KEY_F1;
		case KEY_F2: return RMP_KEY_F2;
		case KEY_F3: return RMP_KEY_F3;
		case KEY_F4: return RMP_KEY_F4;
		case KEY_F5: return RMP_KEY_F5;
		case KEY_F6: return RMP_KEY_F6;
		case KEY_F7: return RMP_KEY_F7;
		case KEY_F8: return RMP_KEY_F8;
		case KEY_F9: return RMP_KEY_F9;
		case KEY_F10: return RMP_KEY_F10;
		case KEY_F11: return RMP_KEY_F11;
		case KEY_F12: return RMP_KEY_F12;
		
		case KEY_A: return RMP_KEY_A;
		case KEY_B: return RMP_KEY_B;
		case KEY_C: return RMP_KEY_C;
		case KEY_D: return RMP_KEY_D;
		case KEY_E: return RMP_KEY_E;
		case KEY_F: return RMP_KEY_F;
		case KEY_G: return RMP_KEY_G;
		case KEY_H: return RMP_KEY_H;
		case KEY_I: return RMP_KEY_I;
		case KEY_J: return RMP_KEY_J;
		case KEY_K: return RMP_KEY_K;
		case KEY_L: return RMP_KEY_L;
		case KEY_M: return RMP_KEY_M;
		case KEY_N: return RMP_KEY_N;
		case KEY_O: return RMP_KEY_O;
		case KEY_P: return RMP_KEY_P;
		case KEY_Q: return RMP_KEY_Q;
		case KEY_R: return RMP_KEY_R;
		case KEY_S: return RMP_KEY_S;
		case KEY_T: return RMP_KEY_T;
		case KEY_U: return RMP_KEY_U;
		case KEY_V: return RMP_KEY_V;
		case KEY_W: return RMP_KEY_W;
		case KEY_X: return RMP_KEY_X;
		case KEY_Y: return RMP_KEY_Y;
		case KEY_Z: return RMP_KEY_Z;
		
		case KEY_SHIFT_A: return RMP_KEY_SHIFT_A;
		case KEY_SHIFT_B: return RMP_KEY_SHIFT_B;
		case KEY_SHIFT_C: return RMP_KEY_SHIFT_C;
		case KEY_SHIFT_D: return RMP_KEY_SHIFT_D;
		case KEY_SHIFT_E: return RMP_KEY_SHIFT_E;
		case KEY_SHIFT_F: return RMP_KEY_SHIFT_F;
		case KEY_SHIFT_G: return RMP_KEY_SHIFT_G;
		case KEY_SHIFT_H: return RMP_KEY_SHIFT_H;
		case KEY_SHIFT_I: return RMP_KEY_SHIFT_I;
		case KEY_SHIFT_J: return RMP_KEY_SHIFT_J;
		case KEY_SHIFT_K: return RMP_KEY_SHIFT_K;
		case KEY_SHIFT_L: return RMP_KEY_SHIFT_L;
		case KEY_SHIFT_M: return RMP_KEY_SHIFT_M;
		case KEY_SHIFT_N: return RMP_KEY_SHIFT_N;
		case KEY_SHIFT_O: return RMP_KEY_SHIFT_O;
		case KEY_SHIFT_P: return RMP_KEY_SHIFT_P;
		case KEY_SHIFT_Q: return RMP_KEY_SHIFT_Q;
		case KEY_SHIFT_R: return RMP_KEY_SHIFT_R;
		case KEY_SHIFT_S: return RMP_KEY_SHIFT_S;
		case KEY_SHIFT_T: return RMP_KEY_SHIFT_T;
		case KEY_SHIFT_U: return RMP_KEY_SHIFT_U;
		case KEY_SHIFT_V: return RMP_KEY_SHIFT_V;
		case KEY_SHIFT_W: return RMP_KEY_SHIFT_W;
		case KEY_SHIFT_X: return RMP_KEY_SHIFT_X;
		case KEY_SHIFT_Y: return RMP_KEY_SHIFT_Y;
		case KEY_SHIFT_Z: return RMP_KEY_SHIFT_Z;
		
		case KEY_0: return RMP_KEY_0;
		case KEY_1: return RMP_KEY_1;
		case KEY_2: return RMP_KEY_2;
		case KEY_3: return RMP_KEY_3;
		case KEY_4: return RMP_KEY_4;
		case KEY_5: return RMP_KEY_5;
		case KEY_6: return RMP_KEY_6;
		case KEY_7: return RMP_KEY_7;
		case KEY_8: return RMP_KEY_8;
		case KEY_9: return RMP_KEY_9;
		
		case KEY_PLUS: return RMP_KEY_PLUS;
		case KEY_MINUS: return RMP_KEY_MINUS;
		case KEY_GT: return RMP_KEY_GT;
		case KEY_LT: return RMP_KEY_LT;
		case KEY_HASHTAG: return RMP_KEY_HASHTAG;
		case KEY_DOLAR: return RMP_KEY_DOLAR;
		case KEY_PERSANT: return RMP_KEY_PERSANT;
		case KEY_STAR: return RMP_KEY_STAR;
		case KEY_DOT: return RMP_KEY_DOT;
		case KEY_UNDERS: return RMP_KEY_UNDERS;
		case KEY_SEMICOL: return RMP_KEY_SEMICOL;
		case KEY_QUISTION_MARK: return RMP_KEY_QUISTION_MARK;
		case KEY_AT: return RMP_KEY_AT;
		case KEY_OPCURB: return RMP_KEY_OPCURB;
		case KEY_CLCURB: return RMP_KEY_CLCURB;
		case KEY_BACK_SLASH: return RMP_KEY_BACK_SLASH;
		case KEY_BACKTICK: return RMP_KEY_BACKTICK;
		case KEY_OPEN_BRAKET: return RMP_KEY_OPEN_BRAKET;
		case KEY_CLOSED_BRAKET: return RMP_KEY_CLOSED_BRAKET;
		case KEY_BAR: return RMP_KEY_BAR;
		case KEY_DBL_QUOTE: return RMP_KEY_DBL_QUOTE;
		case KEY_SINGLE_QOUTE: return RMP_KEY_SINGLE_QOUTE;
		case KEY_SLASH: return RMP_KEY_SLASH;
		case KEY_COLON: return RMP_KEY_COLON;
		case KEY_COMMA: return RMP_KEY_COMMA;
		case KEY_OPPAERN: return RMP_KEY_OPPAERN;
		case KEY_CLPAREN: return RMP_KEY_CLPAREN;
		case KEY_EQUAL: return RMP_KEY_EQUAL;
		default: return RMP_KEY_NONE;
	}
}

void rmp_keyboard_close(void) {
#if defined(_WIN32)
	restore_console();
#else
	restore_terminal();
#endif
}
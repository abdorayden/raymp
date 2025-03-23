/*
 *	keyboard.c file is part of RMP engine 
 *	and the licence is under licence repo
 *
 * */

// standerd libc 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// lua lib
#include <lua5.4/lua.h>
#include <lua5.4/lauxlib.h>
#include <lua5.4/lualib.h>


// Linux/macOS:
//	gcc -shared -o mylib.so -fPIC mylib.c
// Windows (MinGW):
//	gcc -shared -o mylib.dll -fPIC mylib.c


// Keys enumeration to map which key is pressed
typedef enum {
	KEY_CTRL_A,
	KEY_CTRL_B,
	KEY_CTRL_C,      
	KEY_CTRL_D,      
	KEY_CTRL_E,      
	KEY_CTRL_F,      
	KEY_CTRL_N,      
	KEY_CTRL_O,      
	KEY_CTRL_P,      
	KEY_CTRL_Q,      
	KEY_CTRL_R,      
	KEY_CTRL_Y,      
	KEY_CTRL_G, 
	KEY_CTRL_H, 
	KEY_CTRL_I, 
	KEY_CTRL_K, 
	KEY_CTRL_L, 
	KEY_CTRL_S, 
	KEY_CTRL_T, 
	KEY_CTRL_U, 
	KEY_CTRL_V, 
	KEY_CTRL_W, 
	KEY_CTRL_X, 
	KEY_CTRL_Z, 

	KEY_A,
	KEY_B,
	KEY_C,      
	KEY_D,      
	KEY_E,      
	KEY_F,      
	KEY_M,      
	KEY_N,      
	KEY_O,      
	KEY_P,      
	KEY_Q,      
	KEY_R,      
	KEY_Y,      
	KEY_G, 
	KEY_H, 
	KEY_I, 
	KEY_J, 
	KEY_K, 
	KEY_L, 
	KEY_S, 
	KEY_T, 
	KEY_U, 
	KEY_V, 
	KEY_W, 
	KEY_X, 
	KEY_Z, 

	KEY_ENTER,
	KEY_SPACE,
	KEY_ESCAPE,
	KEY_UP,
	KEY_DOWN, 
	KEY_LEFT,
	KEY_RIGHT,

	KEY_PLUS, 
	KEY_MINUS,
	KEY_GT,
	KEY_LT, 
	KEY_TAB,	 

	KEY_SHIFT_A,   
	KEY_SHIFT_B,   
	KEY_SHIFT_C,   
	KEY_SHIFT_D,   
	KEY_SHIFT_E,   
	KEY_SHIFT_F,   
	KEY_SHIFT_M,   
	KEY_SHIFT_N,   
	KEY_SHIFT_O,   
	KEY_SHIFT_P,   
	KEY_SHIFT_Q,   
	KEY_SHIFT_R,   
	KEY_SHIFT_Y,   
	KEY_SHIFT_G,
	KEY_SHIFT_H,
	KEY_SHIFT_I,
	KEY_SHIFT_J,
	KEY_SHIFT_K,
	KEY_SHIFT_L,
	KEY_SHIFT_S,
	KEY_SHIFT_T,
	KEY_SHIFT_U,
	KEY_SHIFT_V,
	KEY_SHIFT_W,
	KEY_SHIFT_X,
	KEY_SHIFT_Z,
	KEY_0, 
	KEY_1,
	KEY_2,
	KEY_3,
	KEY_4,
	KEY_5,
	KEY_6,
	KEY_7,
	KEY_8,
	KEY_9,
	KEY_HASHTAG,
	KEY_DOLAR,
	KEY_PERSANT,
	KEY_STAR,
	KEY_DOT,
	KEY_UNDERS,
	KEY_SEMICOL,
	KEY_QUISTION_MARK,
	KEY_AT,
	KEY_OPCURB,
	KEY_BACK_SLASH,
	KEY_CLCURB,
	KEY_BACKTICK,
	KEY_OPEN_BRAKET,
	KEY_BAR,
	KEY_CLOSED_BRAKET,
	KEY_DBL_QUOTE,
	KEY_SINGLE_QOUTE,
	NONE
}Keys;

#if !defined(_WIN32)

// posix stuff

#include <sys/ioctl.h>
#include <termios.h>
#include <ctype.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>

typedef struct termios Term;

static inline void input_mode_disable(Term* saved_tattr){
  	tcsetattr(STDIN_FILENO, TCSANOW, saved_tattr);
}

static inline void input_mode_enable(Term* tattr) {
    tcgetattr(STDIN_FILENO, tattr);
    tattr->c_lflag &= ~(ICANON | ECHO); 
    tattr->c_cc[VMIN] = 1;
    tattr->c_cc[VTIME] = 0;             
    tcsetattr(STDIN_FILENO, TCSANOW, tattr);
}

static inline void input_mode_reset(Term* tattr) {
    tcgetattr(STDIN_FILENO, tattr);
    tattr->c_lflag |= (ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, tattr);
}


#define CTRL_KEY(key)	((key) & 0x1f)

int handle_keys(lua_State* state) {
    	char c = (char)luaL_checkinteger(state, 1);
	Keys for_ret;
	switch (c){
		case CTRL_KEY('a') : for_ret = KEY_CTRL_A;break;
		case CTRL_KEY('b') : for_ret = KEY_CTRL_B;break;
		case CTRL_KEY('c') : for_ret = KEY_CTRL_C;break;
		case CTRL_KEY('d') : for_ret = KEY_CTRL_D;break;
		case CTRL_KEY('e') : for_ret = KEY_CTRL_E;break;
		case CTRL_KEY('f') : for_ret = KEY_CTRL_F;break;
		case CTRL_KEY('g') : for_ret = KEY_CTRL_G;break;
		case CTRL_KEY('h') : for_ret = KEY_CTRL_H;break;
		case CTRL_KEY('k') : for_ret = KEY_CTRL_K;break;
		case CTRL_KEY('l') : for_ret = KEY_CTRL_L;break;
		case CTRL_KEY('n') : for_ret = KEY_CTRL_N;break;
		case CTRL_KEY('o') : for_ret = KEY_CTRL_O;break;
		case CTRL_KEY('p') : for_ret = KEY_CTRL_P;break;
		case CTRL_KEY('q') : for_ret = KEY_CTRL_Q;break;
		case CTRL_KEY('r') : for_ret = KEY_CTRL_R;break;
		case CTRL_KEY('s') : for_ret = KEY_CTRL_S;break;
		case CTRL_KEY('t') : for_ret = KEY_CTRL_T;break;
		case CTRL_KEY('u') : for_ret = KEY_CTRL_U;break;
		case CTRL_KEY('v') : for_ret = KEY_CTRL_V;break;
		case CTRL_KEY('w') : for_ret = KEY_CTRL_W;break;
		case CTRL_KEY('x') : for_ret = KEY_CTRL_X;break;
		case CTRL_KEY('y') : for_ret = KEY_CTRL_Y;break;
		case CTRL_KEY('z') : for_ret = KEY_CTRL_Z;break;

		case  9  : for_ret = KEY_TAB;break;
		case  10 : for_ret = KEY_ENTER;break; 
		case '0' : for_ret = KEY_0;break; 
		case '1' : for_ret = KEY_1;break;
		case '2' : for_ret = KEY_2;break;
		case '3' : for_ret = KEY_3;break;
		case '4' : for_ret = KEY_4;break;
		case '5' : for_ret = KEY_5;break;
		case '6' : for_ret = KEY_6;break;
		case '7' : for_ret = KEY_7;break;
		case '8' : for_ret = KEY_8;break;
		case '9' : for_ret = KEY_9;break;
		case 'a' : for_ret = KEY_A;break;
		case 'b' : for_ret = KEY_B;break;
		case 'c' : for_ret = KEY_C;break;
		case 'd' : for_ret = KEY_D;break;
		case 'e' : for_ret = KEY_E;break;
		case 'f' : for_ret = KEY_F;break;
		case 'g' : for_ret = KEY_G;break;
		case 'h' : for_ret = KEY_H;break;
		case 'i' : for_ret = KEY_I;break;
		case 'j' : for_ret = KEY_J;break;
		case 'k' : for_ret = KEY_K;break;
		case 'l' : for_ret = KEY_L;break;
		case 'm' : for_ret = KEY_M;break;
		case 'n' : for_ret = KEY_N;break;
		case 'o' : for_ret = KEY_O;break;
		case 'p' : for_ret = KEY_P;break;
		case 'q' : for_ret = KEY_Q;break;
		case 'r' : for_ret = KEY_R;break;
		case 's' : for_ret = KEY_S;break;
		case 't' : for_ret = KEY_T;break;
		case 'u' : for_ret = KEY_U;break;
		case 'v' : for_ret = KEY_V;break;
		case 'w' : for_ret = KEY_W;break;
		case 'x' : for_ret = KEY_X;break;
		case 'y' : for_ret = KEY_Y;break;
		case 'z' : for_ret = KEY_Z;break;
		case 'A' : for_ret = KEY_SHIFT_A;break; 
		case 'B' : for_ret = KEY_SHIFT_B;break;
		case 'C' : for_ret = KEY_SHIFT_C;break;
		case 'D' : for_ret = KEY_SHIFT_D;break;
		case 'E' : for_ret = KEY_SHIFT_E;break;
		case 'F' : for_ret = KEY_SHIFT_F;break;
		case 'G' : for_ret = KEY_SHIFT_G;break;
		case 'H' : for_ret = KEY_SHIFT_H;break;
		case 'I' : for_ret = KEY_SHIFT_I;break;
		case 'J' : for_ret = KEY_SHIFT_J;break;
		case 'K' : for_ret = KEY_SHIFT_K;break;
		case 'L' : for_ret = KEY_SHIFT_L;break;
		case 'M' : for_ret = KEY_SHIFT_M;break;
		case 'N' : for_ret = KEY_SHIFT_N;break;
		case 'O' : for_ret = KEY_SHIFT_O;break;
		case 'P' : for_ret = KEY_SHIFT_P;break;
		case 'Q' : for_ret = KEY_SHIFT_Q;break;
		case 'R' : for_ret = KEY_SHIFT_R;break;
		case 'S' : for_ret = KEY_SHIFT_S;break;
		case 'T' : for_ret = KEY_SHIFT_T;break;
		case 'U' : for_ret = KEY_SHIFT_U;break;
		case 'V' : for_ret = KEY_SHIFT_V;break;
		case 'W' : for_ret = KEY_SHIFT_W;break;
		case 'X' : for_ret = KEY_SHIFT_X;break;
		case 'Y' : for_ret = KEY_SHIFT_Y;break;
		case 'Z' : for_ret = KEY_SHIFT_Z;break;
		case '#' : for_ret = KEY_HASHTAG;break;
		case '$' : for_ret = KEY_DOLAR;break;
		case '%' : for_ret = KEY_PERSANT;break;
		case '*' : for_ret = KEY_STAR;break;
		case '+' : for_ret = KEY_PLUS;break;
		case '-' : for_ret = KEY_MINUS;break;
		case '.' : for_ret = KEY_DOT;break;
		case ';' : for_ret = KEY_SEMICOL;break;
		case '<' : for_ret = KEY_LT;break; 
		case '>' : for_ret = KEY_GT;break;
		case '?' : for_ret = KEY_QUISTION_MARK;break;
		case '@' : for_ret = KEY_AT;break;
		case '[' : for_ret = KEY_OPCURB;break;
		case '\\': for_ret = KEY_BACK_SLASH;break;
		case ']' : for_ret = KEY_CLCURB;break; 
		case '_' : for_ret = KEY_UNDERS;break;
		case '`' : for_ret = KEY_BACKTICK;break;
		case '{' : for_ret = KEY_OPEN_BRAKET;break;
		case '|' : for_ret = KEY_BAR;break;
		case '}' : for_ret = KEY_CLOSED_BRAKET;break;
		case '"' : for_ret = KEY_DBL_QUOTE;break;
		case '\'': for_ret = KEY_SINGLE_QOUTE;break;
		case ' ' : for_ret = KEY_SPACE;break;

		case '\033' :{
			char seq[3];break;
			read(STDIN_FILENO , &seq[0] , 1);break; 
			if(seq[0] != '['){
				for_ret = KEY_ESCAPE;break;
			}else{
				read(STDIN_FILENO , &seq[1] , 1);break;
				switch(seq[1]){
			        	case 'A' : for_ret = KEY_UP;break;
			        	case 'B' : for_ret = KEY_DOWN;break;
			        	case 'C' : for_ret = KEY_RIGHT;break;
					case 'D' : for_ret = KEY_LEFT ;break;
				}
			}
		}break;break;
		default : for_ret = NONE;
	}
	lua_pushinteger(state , for_ret);
	return 1;
}


#else
#ifdef KEYBOARDLL_EXPORTS /*  define ADD_EXPORTS *only* when building the DLL. */
  #define KEYBOARDLL_API __declspec(dllexport)
#else
  #define KEYBOARDLL_API __declspec(dllimport)
#endif

/* Define calling convention in one place, for convenience. */
#define CALL __cdecl

KEYBOARDLL_API int CALL handle_keys(lua_State* state) {

#include <windows.h>

int CALL handle_keys(lua_State* state) {
	Keys for_ret;
	HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
	DWORD fdwMode = ENABLE_WINDOW_INPUT | ENABLE_MOUSE_INPUT;
	SetConsoleMode(hStdin, fdwMode);

	INPUT_RECORD irInBuf[128];
	DWORD cNumRead;
	ReadConsoleInput(hStdin, irInBuf, 128, &cNumRead);
	for (DWORD i = 0; i < cNumRead; i++) {
		if (irInBuf[i].EventType == KEY_EVENT) {
			KEY_EVENT_RECORD keyEvent = irInBuf[i].Event.KeyEvent;
			if (keyEvent.bKeyDown) {
				char ch = keyEvent.uChar.AsciiChar;
                    		DWORD ctrlState = keyEvent.dwControlKeyState;
				if(ctrlState & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)){
                        		if (ch >= 1 && ch <= 26) {
                        		    switch('A' + ch - 1) {
						case 'A' : for_ret = KEY_CTRL_A;break;
						case 'B' : for_ret = KEY_CTRL_B;break;
						case 'C' : for_ret = KEY_CTRL_C;break;
						case 'D' : for_ret = KEY_CTRL_D;break;
						case 'E' : for_ret = KEY_CTRL_E;break;
						case 'F' : for_ret = KEY_CTRL_F;break;
						case 'G' : for_ret = KEY_CTRL_G;break;
						case 'H' : for_ret = KEY_CTRL_H;break;
						case 'I' : for_ret = KEY_CTRL_I;break;
						case 'K' : for_ret = KEY_CTRL_K;break;
						case 'L' : for_ret = KEY_CTRL_L;break;
						case 'N' : for_ret = KEY_CTRL_N;break;
						case 'O' : for_ret = KEY_CTRL_O;break;
						case 'P' : for_ret = KEY_CTRL_P;break;
						case 'Q' : for_ret = KEY_CTRL_Q;break;
						case 'R' : for_ret = KEY_CTRL_R;break;
						case 'S' : for_ret = KEY_CTRL_S;break;
						case 'T' : for_ret = KEY_CTRL_T;break;
						case 'U' : for_ret = KEY_CTRL_U;break;
						case 'V' : for_ret = KEY_CTRL_V;break;
						case 'W' : for_ret = KEY_CTRL_W;break;
						case 'X' : for_ret = KEY_CTRL_X;break;
						case 'Y' : for_ret = KEY_CTRL_Y;break;
						case 'Z' : for_ret = KEY_CTRL_Z;break;

					    }
                        		} 
				}else{
					if (ch >= 32 && ch <= 126) {
						if(ch == 0x61)		for_ret = KEY_A; 
						else if(ch == 0x62)	for_ret = KEY_B;
						else if(ch == 0x63)	for_ret = KEY_C;
						else if(ch == 0x64)	for_ret = KEY_D;
						else if(ch == 0x65)	for_ret = KEY_E;
						else if(ch == 0x66)	for_ret = KEY_F;
						else if(ch == 0x67)	for_ret = KEY_G;
						else if(ch == 0x68)	for_ret = KEY_H;
						else if(ch == 0x69)	for_ret = KEY_I;
						else if(ch == 0x6A)	for_ret = KEY_J;
						else if(ch == 0x6B)	for_ret = KEY_K;
						else if(ch == 0x6C)	for_ret = KEY_L;
						else if(ch == 0x6D)	for_ret = KEY_M;
						else if(ch == 0x6E)	for_ret = KEY_N;
						else if(ch == 0x6F)	for_ret = KEY_O;
						else if(ch == 0x70)	for_ret = KEY_P;
						else if(ch == 0x71)	for_ret = KEY_Q;
						else if(ch == 0x72)	for_ret = KEY_R;
						else if(ch == 0x73)	for_ret = KEY_S;
						else if(ch == 0x74)	for_ret = KEY_T;
						else if(ch == 0x75)	for_ret = KEY_U;
						else if(ch == 0x76)	for_ret = KEY_V;
						else if(ch == 0x77)	for_ret = KEY_W;
						else if(ch == 0x78)	for_ret = KEY_X;
						else if(ch == 0x79)	for_ret = KEY_Y;
						else if(ch == 0x7A)	for_ret = KEY_Z;
						else if(ch == '#' ) for_ret = KEY_HASHTAG;
						else if(ch == '$' ) for_ret = KEY_DOLAR;
						else if(ch == '%' ) for_ret = KEY_PERSANT;
						else if(ch == '*' ) for_ret = KEY_STAR;
						else if(ch == '+' ) for_ret = KEY_PLUS;
						else if(ch == '-' ) for_ret = KEY_MINUS;
						else if(ch == '.' ) for_ret = KEY_DOT;
						else if(ch == ';' ) for_ret = KEY_SEMICOL;
						else if(ch == '<' ) for_ret = KEY_LT; 
						else if(ch == '>' ) for_ret = KEY_GT;
						else if(ch == '?' ) for_ret = KEY_QUISTION_MARK;
						else if(ch == '@' ) for_ret = KEY_AT;
						else if(ch == '[' ) for_ret = KEY_OPCURB;
						else if(ch == '\\') for_ret = KEY_BACK_SLASH;
						else if(ch == ']' ) for_ret = KEY_CLCURB; 
						else if(ch == '_' ) for_ret = KEY_UNDERS;
						else if(ch == '`' ) for_ret = KEY_BACKTICK;
						else if(ch == '{' ) for_ret = KEY_OPEN_BRAKET;
						else if(ch == '|' ) for_ret = KEY_BAR;
						else if(ch == '}' ) for_ret = KEY_CLOSED_BRAKET;
						else if(ch == '"' ) for_ret = KEY_DBL_QUOTE;
						else if(ch == '\'') for_ret = KEY_SINGLE_QOUTE;
						else if(ch == ' ' ) for_ret = KEY_SPACE;
					}
					if (keyEvent.wVirtualKeyCode == VK_ESCAPE) 	for_ret = KEY_ESCAPE;
					else if(keyEvent.wVirtualKeyCode == VK_TAB) 	for_ret = KEY_TAB;
					else if(keyEvent.wVirtualKeyCode == VK_RETURN) 	for_ret = KEY_ENTER;
					else if(keyEvent.wVirtualKeyCode == VK_LEFT) 	for_ret = KEY_LEFT;
					else if(keyEvent.wVirtualKeyCode == VK_UP)	for_ret = KEY_UP;
					else if(keyEvent.wVirtualKeyCode == VK_RIGHT)	for_ret = KEY_RIGHT;
					else if(keyEvent.wVirtualKeyCode == VK_DOWN)	for_ret = KEY_DOWN;
					else if(keyEvent.wVirtualKeyCode == 0x30) 	for_ret = KEY_0;
					else if(keyEvent.wVirtualKeyCode == 0x31) 	for_ret = KEY_1;
					else if(keyEvent.wVirtualKeyCode == 0x32)	for_ret = KEY_2;
					else if(keyEvent.wVirtualKeyCode == 0x33)	for_ret = KEY_3;
					else if(keyEvent.wVirtualKeyCode == 0x34)	for_ret = KEY_4;
					else if(keyEvent.wVirtualKeyCode == 0x35)	for_ret = KEY_5;
					else if(keyEvent.wVirtualKeyCode == 0x36)	for_ret = KEY_6;
					else if(keyEvent.wVirtualKeyCode == 0x37)	for_ret = KEY_7;
					else if(keyEvent.wVirtualKeyCode == 0x38)	for_ret = KEY_8;
					else if(keyEvent.wVirtualKeyCode == 0x39)	for_ret = KEY_9;
					else if(keyEvent.wVirtualKeyCode == 0x41) 	for_ret = KEY_SHIFT_A;
					else if(keyEvent.wVirtualKeyCode == 0x42) 	for_ret = KEY_SHIFT_B;
					else if(keyEvent.wVirtualKeyCode == 0x43) 	for_ret = KEY_SHIFT_C;
					else if(keyEvent.wVirtualKeyCode == 0x44) 	for_ret = KEY_SHIFT_D;
					else if(keyEvent.wVirtualKeyCode == 0x45) 	for_ret = KEY_SHIFT_E;
					else if(keyEvent.wVirtualKeyCode == 0x46) 	for_ret = KEY_SHIFT_F;
					else if(keyEvent.wVirtualKeyCode == 0x47) 	for_ret = KEY_SHIFT_G;
					else if(keyEvent.wVirtualKeyCode == 0x48) 	for_ret = KEY_SHIFT_H;
					else if(keyEvent.wVirtualKeyCode == 0x49) 	for_ret = KEY_SHIFT_I;
					else if(keyEvent.wVirtualKeyCode == 0x4A) 	for_ret = KEY_SHIFT_J;
					else if(keyEvent.wVirtualKeyCode == 0x4B) 	for_ret = KEY_SHIFT_K;
					else if(keyEvent.wVirtualKeyCode == 0x4C) 	for_ret = KEY_SHIFT_L;
					else if(keyEvent.wVirtualKeyCode == 0x4D) 	for_ret = KEY_SHIFT_M;
					else if(keyEvent.wVirtualKeyCode == 0x4E) 	for_ret = KEY_SHIFT_N;
					else if(keyEvent.wVirtualKeyCode == 0x4F) 	for_ret = KEY_SHIFT_O;
					else if(keyEvent.wVirtualKeyCode == 0x50) 	for_ret = KEY_SHIFT_P;
					else if(keyEvent.wVirtualKeyCode == 0x51) 	for_ret = KEY_SHIFT_Q;
					else if(keyEvent.wVirtualKeyCode == 0x52) 	for_ret = KEY_SHIFT_R;
					else if(keyEvent.wVirtualKeyCode == 0x53) 	for_ret = KEY_SHIFT_S;
					else if(keyEvent.wVirtualKeyCode == 0x54) 	for_ret = KEY_SHIFT_T;
					else if(keyEvent.wVirtualKeyCode == 0x55) 	for_ret = KEY_SHIFT_U;
					else if(keyEvent.wVirtualKeyCode == 0x56) 	for_ret = KEY_SHIFT_V;
					else if(keyEvent.wVirtualKeyCode == 0x57) 	for_ret = KEY_SHIFT_W;
					else if(keyEvent.wVirtualKeyCode == 0x58) 	for_ret = KEY_SHIFT_X;
					else if(keyEvent.wVirtualKeyCode == 0x59) 	for_ret = KEY_SHIFT_Y;
					else if(keyEvent.wVirtualKeyCode == 0x5A) 	for_ret = KEY_SHIFT_Z;
				}

			}
		}
	}
	lua_pushinteger(state , for_ret);
	return 1;
}

#endif

// Table used to load handle_keys funtion and used in lua_core api
int RMPCoreKeyboardLib(lua_State *L) {
	lua_newtable(L);
	lua_pushcfunction(L, handle_keys);
	lua_setfield(L, -2, "HandleKeys");
	return 1;
}


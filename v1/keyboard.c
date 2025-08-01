#include <stdio.h>
#include "keyboard.h"

Keys handle_keys(void)
{
#ifdef _WIN32
	(void)c;
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
						case 'A' : return KEY_CTRL_A;
						case 'B' : return KEY_CTRL_B;
						case 'C' : return KEY_CTRL_C;
						case 'D' : return KEY_CTRL_D;
						case 'E' : return KEY_CTRL_E;
						case 'F' : return KEY_CTRL_F;
						case 'G' : return KEY_CTRL_G;
						case 'H' : return KEY_CTRL_H;
						case 'I' : return KEY_CTRL_I;
						case 'K' : return KEY_CTRL_K;
						case 'L' : return KEY_CTRL_L;
						case 'N' : return KEY_CTRL_N;
						case 'O' : return KEY_CTRL_O;
						case 'P' : return KEY_CTRL_P;
						case 'Q' : return KEY_CTRL_Q;
						case 'R' : return KEY_CTRL_R;
						case 'S' : return KEY_CTRL_S;
						case 'T' : return KEY_CTRL_T;
						case 'U' : return KEY_CTRL_U;
						case 'V' : return KEY_CTRL_V;
						case 'W' : return KEY_CTRL_W;
						case 'X' : return KEY_CTRL_X;
						case 'Y' : return KEY_CTRL_Y;
						case 'Z' : return KEY_CTRL_Z;

					    }
                        		} 
				}else{
					if (ch >= 32 && ch <= 126) {
						if(ch == 0x61)		return KEY_A; 
						else if(ch == 0x62)	return KEY_B;
						else if(ch == 0x63)	return KEY_C;
						else if(ch == 0x64)	return KEY_D;
						else if(ch == 0x65)	return KEY_E;
						else if(ch == 0x66)	return KEY_F;
						else if(ch == 0x67)	return KEY_G;
						else if(ch == 0x68)	return KEY_H;
						else if(ch == 0x69)	return KEY_I;
						else if(ch == 0x6A)	return KEY_J;
						else if(ch == 0x6B)	return KEY_K;
						else if(ch == 0x6C)	return KEY_L;
						else if(ch == 0x6D)	return KEY_M;
						else if(ch == 0x6E)	return KEY_N;
						else if(ch == 0x6F)	return KEY_O;
						else if(ch == 0x70)	return KEY_P;
						else if(ch == 0x71)	return KEY_Q;
						else if(ch == 0x72)	return KEY_R;
						else if(ch == 0x73)	return KEY_S;
						else if(ch == 0x74)	return KEY_T;
						else if(ch == 0x75)	return KEY_U;
						else if(ch == 0x76)	return KEY_V;
						else if(ch == 0x77)	return KEY_W;
						else if(ch == 0x78)	return KEY_X;
						else if(ch == 0x79)	return KEY_Y;
						else if(ch == 0x7A)	return KEY_Z;
						else if(ch == '#' ) return KEY_HASHTAG;
						else if(ch == '$' ) return KEY_DOLAR;
						else if(ch == '%' ) return KEY_PERSANT;
						else if(ch == '*' ) return KEY_STAR;
						else if(ch == '+' ) return KEY_PLUS;
						else if(ch == '-' ) return KEY_MINUS;
						else if(ch == '.' ) return KEY_DOT;
						else if(ch == ';' ) return KEY_SEMICOL;
						else if(ch == '<' ) return KEY_LT; 
						else if(ch == '>' ) return KEY_GT;
						else if(ch == '?' ) return KEY_QUISTION_MARK;
						else if(ch == '@' ) return KEY_AT;
						else if(ch == '[' ) return KEY_OPCURB;
						else if(ch == '\\') return KEY_BACK_SLASH;
						else if(ch == ']' ) return KEY_CLCURB; 
						else if(ch == '_' ) return KEY_UNDERS;
						else if(ch == '`' ) return KEY_BACKTICK;
						else if(ch == '{' ) return KEY_OPEN_BRAKET;
						else if(ch == '|' ) return KEY_BAR;
						else if(ch == '}' ) return KEY_CLOSED_BRAKET;
						else if(ch == '"' ) return KEY_DBL_QUOTE;
						else if(ch == '\'') return KEY_SINGLE_QOUTE;
						else if(ch == ' ' ) return KEY_SPACE;
					}
					if (keyEvent.wVirtualKeyCode == VK_ESCAPE) 	return KEY_ESCAPE;
					else if(keyEvent.wVirtualKeyCode == VK_TAB) 	return KEY_TAB;
					else if(keyEvent.wVirtualKeyCode == VK_RETURN) 	return KEY_ENTER;
					else if(keyEvent.wVirtualKeyCode == VK_LEFT) 	return KEY_LEFT;
					else if(keyEvent.wVirtualKeyCode == VK_UP)	return KEY_UP;
					else if(keyEvent.wVirtualKeyCode == VK_RIGHT)	return KEY_RIGHT;
					else if(keyEvent.wVirtualKeyCode == VK_DOWN)	return KEY_DOWN;
					else if(keyEvent.wVirtualKeyCode == 0x30) 	return KEY_0;
					else if(keyEvent.wVirtualKeyCode == 0x31) 	return KEY_1;
					else if(keyEvent.wVirtualKeyCode == 0x32)	return KEY_2;
					else if(keyEvent.wVirtualKeyCode == 0x33)	return KEY_3;
					else if(keyEvent.wVirtualKeyCode == 0x34)	return KEY_4;
					else if(keyEvent.wVirtualKeyCode == 0x35)	return KEY_5;
					else if(keyEvent.wVirtualKeyCode == 0x36)	return KEY_6;
					else if(keyEvent.wVirtualKeyCode == 0x37)	return KEY_7;
					else if(keyEvent.wVirtualKeyCode == 0x38)	return KEY_8;
					else if(keyEvent.wVirtualKeyCode == 0x39)	return KEY_9;
					else if(keyEvent.wVirtualKeyCode == 0x41) 	return KEY_SHIFT_A;
					else if(keyEvent.wVirtualKeyCode == 0x42) 	return KEY_SHIFT_B;
					else if(keyEvent.wVirtualKeyCode == 0x43) 	return KEY_SHIFT_C;
					else if(keyEvent.wVirtualKeyCode == 0x44) 	return KEY_SHIFT_D;
					else if(keyEvent.wVirtualKeyCode == 0x45) 	return KEY_SHIFT_E;
					else if(keyEvent.wVirtualKeyCode == 0x46) 	return KEY_SHIFT_F;
					else if(keyEvent.wVirtualKeyCode == 0x47) 	return KEY_SHIFT_G;
					else if(keyEvent.wVirtualKeyCode == 0x48) 	return KEY_SHIFT_H;
					else if(keyEvent.wVirtualKeyCode == 0x49) 	return KEY_SHIFT_I;
					else if(keyEvent.wVirtualKeyCode == 0x4A) 	return KEY_SHIFT_J;
					else if(keyEvent.wVirtualKeyCode == 0x4B) 	return KEY_SHIFT_K;
					else if(keyEvent.wVirtualKeyCode == 0x4C) 	return KEY_SHIFT_L;
					else if(keyEvent.wVirtualKeyCode == 0x4D) 	return KEY_SHIFT_M;
					else if(keyEvent.wVirtualKeyCode == 0x4E) 	return KEY_SHIFT_N;
					else if(keyEvent.wVirtualKeyCode == 0x4F) 	return KEY_SHIFT_O;
					else if(keyEvent.wVirtualKeyCode == 0x50) 	return KEY_SHIFT_P;
					else if(keyEvent.wVirtualKeyCode == 0x51) 	return KEY_SHIFT_Q;
					else if(keyEvent.wVirtualKeyCode == 0x52) 	return KEY_SHIFT_R;
					else if(keyEvent.wVirtualKeyCode == 0x53) 	return KEY_SHIFT_S;
					else if(keyEvent.wVirtualKeyCode == 0x54) 	return KEY_SHIFT_T;
					else if(keyEvent.wVirtualKeyCode == 0x55) 	return KEY_SHIFT_U;
					else if(keyEvent.wVirtualKeyCode == 0x56) 	return KEY_SHIFT_V;
					else if(keyEvent.wVirtualKeyCode == 0x57) 	return KEY_SHIFT_W;
					else if(keyEvent.wVirtualKeyCode == 0x58) 	return KEY_SHIFT_X;
					else if(keyEvent.wVirtualKeyCode == 0x59) 	return KEY_SHIFT_Y;
					else if(keyEvent.wVirtualKeyCode == 0x5A) 	return KEY_SHIFT_Z;
				}

			}
		}
	}
	return NONE;
#else
	char c ; 
	read(STDIN_FILENO , &c , 1); 
	switch (c){
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

		case  9  : return KEY_TAB;
		case  10 : return KEY_ENTER; 
		case '0' : return KEY_0; 
		case '1' : return KEY_1;
		case '2' : return KEY_2;
		case '3' : return KEY_3;
		case '4' : return KEY_4;
		case '5' : return KEY_5;
		case '6' : return KEY_6;
		case '7' : return KEY_7;
		case '8' : return KEY_8;
		case '9' : return KEY_9;
		case 'a' : return KEY_A;
		case 'b' : return KEY_B;
		case 'c' : return KEY_C;
		case 'd' : return KEY_D;
		case 'e' : return KEY_E;
		case 'f' : return KEY_F;
		case 'g' : return KEY_G;
		case 'h' : return KEY_H;
		case 'i' : return KEY_I;
		case 'j' : return KEY_J;
		case 'k' : return KEY_K;
		case 'l' : return KEY_L;
		case 'm' : return KEY_M;
		case 'n' : return KEY_N;
		case 'o' : return KEY_O;
		case 'p' : return KEY_P;
		case 'q' : return KEY_Q;
		case 'r' : return KEY_R;
		case 's' : return KEY_S;
		case 't' : return KEY_T;
		case 'u' : return KEY_U;
		case 'v' : return KEY_V;
		case 'w' : return KEY_W;
		case 'x' : return KEY_X;
		case 'y' : return KEY_Y;
		case 'z' : return KEY_Z;
		case 'A' : return KEY_SHIFT_A; 
		case 'B' : return KEY_SHIFT_B;
		case 'C' : return KEY_SHIFT_C;
		case 'D' : return KEY_SHIFT_D;
		case 'E' : return KEY_SHIFT_E;
		case 'F' : return KEY_SHIFT_F;
		case 'G' : return KEY_SHIFT_G;
		case 'H' : return KEY_SHIFT_H;
		case 'I' : return KEY_SHIFT_I;
		case 'J' : return KEY_SHIFT_J;
		case 'K' : return KEY_SHIFT_K;
		case 'L' : return KEY_SHIFT_L;
		case 'M' : return KEY_SHIFT_M;
		case 'N' : return KEY_SHIFT_N;
		case 'O' : return KEY_SHIFT_O;
		case 'P' : return KEY_SHIFT_P;
		case 'Q' : return KEY_SHIFT_Q;
		case 'R' : return KEY_SHIFT_R;
		case 'S' : return KEY_SHIFT_S;
		case 'T' : return KEY_SHIFT_T;
		case 'U' : return KEY_SHIFT_U;
		case 'V' : return KEY_SHIFT_V;
		case 'W' : return KEY_SHIFT_W;
		case 'X' : return KEY_SHIFT_X;
		case 'Y' : return KEY_SHIFT_Y;
		case 'Z' : return KEY_SHIFT_Z;
		case '#' : return KEY_HASHTAG;
		case '$' : return KEY_DOLAR;
		case '%' : return KEY_PERSANT;
		case '*' : return KEY_STAR;
		case '+' : return KEY_PLUS;
		case '-' : return KEY_MINUS;
		case '.' : return KEY_DOT;
		case ';' : return KEY_SEMICOL;
		case '<' : return KEY_LT; 
		case '>' : return KEY_GT;
		case '?' : return KEY_QUISTION_MARK;
		case '@' : return KEY_AT;
		case '[' : return KEY_OPCURB;
		case '\\': return KEY_BACK_SLASH;
		case ']' : return KEY_CLCURB; 
		case '_' : return KEY_UNDERS;
		case '`' : return KEY_BACKTICK;
		case '{' : return KEY_OPEN_BRAKET;
		case '|' : return KEY_BAR;
		case '}' : return KEY_CLOSED_BRAKET;
		case '"' : return KEY_DBL_QUOTE;
		case '\'': return KEY_SINGLE_QOUTE;
		case ' ' : return KEY_SPACE;

		case '\033' :{
			char seq[3];
			read(STDIN_FILENO , &seq[0] , 1); 
			if(seq[0] != '['){
				return KEY_ESCAPE;
			}else{
				read(STDIN_FILENO , &seq[1] , 1);
				switch(seq[1]){
			        	case 'A' : return KEY_UP;
			        	case 'B' : return KEY_DOWN;
			        	case 'C' : return KEY_RIGHT;
					case 'D' : return KEY_LEFT ;
				}
			}
		}break;
		default : return NONE;
	}
	return NONE;
#endif
}

int main(void)
{
	Keys k = handle_keys();
	if( k == KEY_C)
		printf("u pressed C");
	return 0;
}

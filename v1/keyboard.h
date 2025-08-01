#ifndef KEY_H_
#define KEY_H_

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

#ifdef _WIN32
#include <windows.h>
#else
#include <sys/ioctl.h>
#include <ctype.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>

typedef struct termios Term;

//inline void input_mode_disable(Term* saved_tattr){
//  	tcsetattr(STDIN_FILENO, TCSANOW, saved_tattr);
//}
//
//inline void input_mode_enable(Term* tattr) {
//    tcgetattr(STDIN_FILENO, tattr);
//    tattr->c_lflag &= ~(ICANON | ECHO); 
//    tattr->c_cc[VMIN] = 1;
//    tattr->c_cc[VTIME] = 0;             
//    tcsetattr(STDIN_FILENO, TCSANOW, tattr);
//}
//
//inline void input_mode_reset(Term* tattr) {
//    tcgetattr(STDIN_FILENO, tattr);
//    tattr->c_lflag |= (ICANON | ECHO);
//    tcsetattr(STDIN_FILENO, TCSANOW, tattr);
//}

#define CTRL_KEY(key)	((key) & 0x1f)

#endif


// NOTE: in windows c prarmeter will be ignored 
// in linux u need to pass input character
Keys handle_keys(void);

#endif

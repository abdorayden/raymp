#ifndef UI_H_
#define UI_H_

typedef struct {
	unsigned short int width;
	unsigned short int height;
}Size;

typedef struct {
	int x;
	int y;
}Vector2;

#if !defined(_WIN32)

#include <termios.h>

static Size get_term_size(){
	struct winsize w;
	ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
	return (Size){
		.width  = ws_col,
		.height = ws_row
	};
}

#else
// windows
#endif

typedef struct {
	/*
	 *<--->	|------------| 
	 * col-	|            | 
	 * pos	|	     | 
	 *	|------------|
	 * */
	unsigned short box_col_pos_left_size; 
	/*
	 *      |------------| <--->
	 *      |            |  col-
	 *      |	     |  pos 
	 *	|------------|
	 * */
	unsigned short box_col_pos_right_size; 

	/*
	 *	   | size |
	 * 	|------------|
	 *      |            |
	 *      |	     |
	 *      |------------|
	 */
	unsigned short box_row_pos_size_top;
	/*
	 *      |------------|
	 *      |            |
	 *      | 	     |
	 *      |------------|
	 * 	   | size | 
	 * */
	unsigned short box_row_pos_size_buttom;
}Box;

typedef struct {
	// window title 
	// Example : 
	// 	----[Title]----- ...
	const char* const 	title;
	// title position
	// Example :
	// 	< position > ----[Title]----
	// 	it can handle it using percent
	// 	or compare with window_h
	//
	// 	default option is : default
	const char* const 	title_position;

	const char* const 	border_char_style;

	bool 			window_number_enable;
	unsigned int 		window_number;
	Vector2			window_number_position;

	bool 			cursor_enable;
	const char* const 	cursor_char_style;
	Vector2			default_cursor_position;


	// color
	char* 			window_color;
	char* 			title_color ;
	char* 			border_color;
	char* 			window_number_color;

	// size
	Box 			box;

	// function to this window
	void (*Window_Do_Work)(Box);

}Window;

typedef struct {

}UI;

#endif //UI_H_

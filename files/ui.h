#ifndef UI_H_
#define UI_H_

// Screen 

typedef struct winsize Size;

#ifndef clearscreen
#	define clearscreen()	fputs("\033[2J",stdout)
#endif

// cursor 
#ifndef move_cursor
#define move_cursor(col , row)	\
	printf("\033[%d;%dH" , row, col);
#endif

#define move_up	\
	printf("\033[1A");

#define move_down	\
	printf("\033[1B");

#define hide_cursor() 	printf("\033[?25l");
#define show_cursor()	printf("\033[?25h");

// Lines
#define Underline 	"\033[4;37m" 	//Underline
#define Italic		"\033[3;37m" 	//Italic
#define Bold		"\033[1;37m" 	//Bold
#define Regular		"\033[0;37m" 	//regular

// colors
#define Black		"\033[0;30m" 	//Black
#define Red		"\033[0;31m" 	//Red
#define Green		"\033[0;32m" 	//Green
#define Yellow		"\033[0;33m" 	//Yello
#define Blue		"\033[0;34m" 	//Blue
#define Magenta		"\033[0;35m" 	//Magenta
#define Cyan		"\033[0;36m" 	//Cyan
#define White		"\033[0;37m" 	//White
#define Default		White		// Default (white)

#ifndef BOOL_USED
typedef enum{
	false,
	true = !false,
}bool;
#endif // BOOL_USED

typedef struct {
	/*
	 *<--->	|------------| <--->
	 * col-	|            |  col-
	 * pos	|	     |  pos 
	 *	|------------|
	 *
	 * */
	unsigned short box_col_pos_size; 
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
	 *
	 * 	   | size | 
	 * */
	unsigned short box_row_pos_size_buttom;

	unsigned short cursor_position_col;
	unsigned short cursor_position_row;
	bool show_albom;

}UI;

UI   UI_Window_Init(void);
void UI_Window_Update(UI* ui);
void UI_Window_Final(void);

#endif //UI_H_

#ifdef UI_C_

static void input_mode_enable(void);
static void input_mode_reset(void);
static void input_mode_disable(void);
static Size get_term_size(void);
static unsigned short calc_box_col_pos_size(Size term_size);
static unsigned short calc_box_row_pos_size_top(Size term_size);
static unsigned short calc_box_row_pos_size_buttom(Size term_size);

UI UI_Window_Init(){
	UI ui;
	clearscreen();
	hide_cursor();

	ui.box_col_pos_size 		= calc_box_col_pos_size(get_term_size());
	ui.box_row_pos_size_top 	= calc_box_row_pos_size_top(get_term_size());
	ui.box_row_pos_size_buttom 	= calc_box_row_pos_size_buttom(get_term_size());
	ui.cursor_position_col 		= 0;
	ui.cursor_position_row 		= 0;
	ui.show_albom 			= false;
	return ui;
}

void UI_Window_Update(UI* ui)
{
	ui->box_col_pos_size 		= calc_box_col_pos_size(get_term_size()),
	ui->box_row_pos_size_top 	= calc_box_row_pos_size_top(get_term_size()),
	ui->box_row_pos_size_buttom 	= calc_box_row_pos_size_buttom(get_term_size());
	ui->cursor_position_col 	= 0,
	ui->cursor_position_row 	= 0,
	ui->show_albom 			= false
}

void UI_Window_Final(void)
{
	show_cursor();
	input_mode_disable();
	clearscreen();
}

static void input_mode_disable(void){
  	tcsetattr(STDIN_FILENO, TCSANOW, &saved_tattr);
}

static void input_mode_enable() {
    struct termios tattr;
    tcgetattr(STDIN_FILENO, &tattr);
    tattr.c_lflag &= ~(ICANON | ECHO); 
    tattr.c_cc[VMIN] = 1;
    tattr.c_cc[VTIME] = 0;             
    tcsetattr(STDIN_FILENO, TCSANOW, &tattr);
}

static void input_mode_reset() {
    struct termios tattr;
    tcgetattr(STDIN_FILENO, &tattr);
    tattr.c_lflag |= (ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &tattr);
}

static Size get_term_size(){
	Size w;
	ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
	return w;
}

static unsigned short calc_box_col_pos_size(Size term_size)
{
	unsigned short p;
	p = (term_size.ws_col)/2;
	if(p < (term_size.ws_col - p)){
		p = (term_size.ws_col - p);
	}
	return (p / 4);
}

static unsigned short calc_box_row_pos_size_top(Size term_size)
{
	return (term_size.ws_row / 12);
}

static unsigned short calc_box_row_pos_size_buttom(Size term_size)
{
	return (term_size.ws_row / 3);
}

#endif

#ifndef UI_H_
#define UI_H_

// Screen 
typedef struct winsize Size;

#ifndef clearscreen
#	define clearscreen()	fputs("\033[2J",stdout)
#endif

// cursor 
#ifndef move_cursor
#define move_cursor(x , y)	\
	printf("\033[%d;%dH" , y, x);
#endif

#define move_up	\
	printf("\033[1A");

#define move_down	\
	printf("\033[1B");

#define hide_cursor() 	printf("\033[?25l");
#define show_cursor()	printf("\033[?25h");

// font style
#define one	"═"
#define two	"║"
#define three   "╦"
#define four	"╗"
#define five	"╔"

#define six	"╩"
#define seven	"╠"

#define eit	"╝"
#define nine	"╚"
#define ten	"╣"


// characters
// get them from : https://symbl.cc/en/unicode-table/#geometric-shapes

#define file_pos	"➯"
#define pause_start	"⏯"
#define next	"⏵"
#define prev	"⏴"
#define ext	"⏻"
#define repeate "⭯"

#define snow	"❆"
#define stars	"✨"

// Lines
#define Underline 	"\033[4;37m" 	//Underline
#define Italic		"\033[3;37m" 	//Italic
#define Bold		"\033[1;37m" 	//Bold
#define Regular		"\033[0m" 	//regular

// colors
#define Black		"\033[0;30m" 	//Black
#define Red		"\033[0;31m" 	//Red
#define Green		"\033[0;32m" 	//Green
#define Yellow		"\033[0;33m" 	//Yello
#define Blue		"\033[1;34m" 	//Blue
#define Magenta		"\033[0;35m" 	//Magenta
#define Cyan		"\033[0;36m" 	//Cyan
#define White		Regular 	//White
#define Default		White		// Default (white)

typedef struct termios Term;

typedef struct {
	/*
	 *<--->	|------------| 
	 * col-	|            | 
	 * pos	|	     | 
	 *	|------------|
	 *
	 * */
	unsigned short box_col_pos_left_size; 
	/*
	 *      |------------| <--->
	 *      |            |  col-
	 *      |	     |  pos 
	 *	|------------|
	 *
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
	 *
	 * 	   | size | 
	 * */
	unsigned short box_row_pos_size_buttom;

	unsigned short cursor_position_col;
	unsigned short cursor_position_row;
	bool explorer;
	bool show_albom;
	int (*Flush)(void);

}UI;

// even file explorer
typedef void(*Function_Style)(UI ui);

UI   UI_Window_Init(Term*);
void UI_Window_Update(UI* ui , bool enable_explorer);
void UI_Window_Final(Term*);
void DrawBox(UI ui , Function_Style call_back_function_style);

void Explorer(UI* ui ,char* path , int index);
void Default_Style(UI ui);
void Error_Box(char*);

#endif //UI_H_

#ifdef UI_C_

int idx;
Directoy __dirs[200];
//#include <termios.h>
//#include <sys/ioctl.h>
//#include <unistd.h>
//#include <stdbool.h>
//#include <stdlib.h>
//#include <time.h>

//#define DIR_ON
//
//#include "rdirectorys.h"
//#include "error.h"

static void 		input_mode_enable(Term* tattr);
static void 		input_mode_reset(Term* tattr);
static void 		input_mode_disable(Term* saved_tattr);
static Size 		get_term_size(void);
static unsigned short 	calc_box_col_pos_right_size(Size term_size);
static unsigned short 	calc_box_col_pos_left_size(Size term_size);
static unsigned short 	calc_box_row_pos_size_top(Size term_size);
static unsigned short 	calc_box_row_pos_size_buttom(Size term_size);
static int 		flush_file(void);	
static void		main_box(Size term_size);
static void 		print_keys(UI ui , Size size);

UI UI_Window_Init(Term* term){
	UI ui;
	clearscreen();
	input_mode_enable(term);
	hide_cursor();
	main_box(get_term_size());
	ui.box_col_pos_left_size 	= calc_box_col_pos_left_size(get_term_size());
	ui.box_col_pos_right_size	= calc_box_col_pos_right_size(get_term_size());
	ui.box_row_pos_size_top 	= calc_box_row_pos_size_top(get_term_size());
	ui.box_row_pos_size_buttom 	= calc_box_row_pos_size_buttom(get_term_size()) + 2;
	ui.cursor_position_col 		= ui.box_col_pos_left_size + 1;
	ui.cursor_position_row 		= ui.box_row_pos_size_top + 1;
	ui.explorer			= false;
	ui.show_albom 			= false;
	ui.Flush			= flush_file;
	//print_keys(ui , get_term_size());
	return ui;
}

void UI_Window_Update(UI* ui, bool enable_explorer)
{
	clearscreen();
	main_box(get_term_size());
	ui->box_col_pos_left_size 	= calc_box_col_pos_left_size(get_term_size());
	ui->box_col_pos_right_size	= calc_box_col_pos_right_size(get_term_size());
	ui->box_row_pos_size_top 	= calc_box_row_pos_size_top(get_term_size());
	ui->box_row_pos_size_buttom 	= calc_box_row_pos_size_buttom(get_term_size());
	ui->cursor_position_col 	= ui->box_col_pos_left_size + 1;
	ui->cursor_position_row 	= ui->box_row_pos_size_top + 1;
	ui->explorer			= enable_explorer;
	ui->show_albom 			= false;
	//print_keys(*ui , get_term_size());
}

void UI_Window_Final(Term* saved_tattr)
{
	if(saved_tattr != NULL)
		input_mode_disable(saved_tattr);
	input_mode_reset(saved_tattr);
	show_cursor();
	clearscreen();
}

void DrawBox(UI ui , Function_Style call_back_function_style)
{
	// TODO: handle function style
	(void) call_back_function_style;
	int i = 1;
	for(int row = ui.box_row_pos_size_top ; row <= ui.box_row_pos_size_buttom ; row++){
		move_cursor(ui.box_col_pos_left_size , ui.box_row_pos_size_top + i++);
		for(int col = ui.box_col_pos_left_size ; col <= ui.box_col_pos_right_size ; col++){
			if(
					row == ui.box_row_pos_size_top && 
					col == ui.box_col_pos_left_size
			)		
				printf("%s" , five);
			else if(
					row == ui.box_row_pos_size_top && 
					col == ui.box_col_pos_right_size
			)	
				printf("%s" , four);
			else if(
				row == ui.box_row_pos_size_buttom && col == ui.box_col_pos_left_size
			)
				printf("%s", nine);
			else if(
				row == ui.box_row_pos_size_buttom && col == ui.box_col_pos_right_size
			)
				printf("%s" ,eit);
			else if(
					(
					 	row == ui.box_row_pos_size_top && 
							(
							 	col < ui.box_col_pos_right_size || 
					 			col > ui.box_col_pos_left_size
					 		)
					) || 
					(
					 	row == ui.box_row_pos_size_buttom &&
							(
						 		col < ui.box_col_pos_right_size || 
					 			col > ui.box_col_pos_left_size
							)
					 )
			)
				printf("%s" , one);
			else if(
				(row < ui.box_row_pos_size_buttom && row > ui.box_row_pos_size_top) && 
				(col == ui.box_col_pos_right_size || col == ui.box_col_pos_left_size)
			)
				printf("%s" , two);
			else 	printf(" ");
		}
	}
	if(ui.explorer){
		move_cursor(ui.box_col_pos_left_size + ((ui.box_col_pos_right_size - ui.box_col_pos_left_size) / 4) , ui.box_row_pos_size_top + 1);
		printf("Explorer");
	}
}

void Default_Style(UI ui)
{
	// this function will printing the style in the box 
	// you can add your own function 
	(void)ui;
}

void Error_Box(char* error)
{
	Size size = get_term_size(); 
	int i = 1;
	for(int row = ((size.ws_row/2) - size.ws_row/4) ; row <= ((size.ws_row/2) + size.ws_row/4) ; row++){
		move_cursor((size.ws_col/2)-(size.ws_col/4), ((size.ws_row/2) - size.ws_row/4) + i++);
		for(int col = (size.ws_col/2)-(size.ws_col/4) ; col <= ((size.ws_col/2)+(size.ws_col/4)) ; col++){
			if(row == ((size.ws_row/2) - size.ws_row/4) && col == (size.ws_col/2)-(size.ws_col/4))	printf("%s" , five);
			else if(row == ((size.ws_row/2) - size.ws_row/4) && col == ((size.ws_col/2)+(size.ws_col/4)))	printf("%s" , four);
			else if(row == ((size.ws_row/2) + size.ws_row/4) && col == (size.ws_col/2)-(size.ws_col/4)) 	printf("%s" , nine);
			else if(row == ((size.ws_row/2) + size.ws_row/4) && col == ((size.ws_col/2)+(size.ws_col/4)))	printf("%s" ,eit);
			else if((row == ((size.ws_row/2) - size.ws_row/4) && (col < ((size.ws_col/2)+(size.ws_col/4)) || col > (size.ws_col/2)-(size.ws_col/4))) || (row == ((size.ws_row/2) + size.ws_row/4) && (col < ((size.ws_col/2)+(size.ws_col/4)) || col > (size.ws_col/2)-(size.ws_col/4))))
				printf("%s" , one);
			else if((row < ((size.ws_row/2) + size.ws_row/4) && row > ((size.ws_row/2) - size.ws_row/4)) && (col == (size.ws_col/2)-(size.ws_col/4) || col == ((size.ws_col/2)+(size.ws_col/4))))	printf("%s" , two);
			else 	printf(" ");
		}
	}
	move_cursor((size.ws_col/2)-(size.ws_col/4)+1 ,((size.ws_row/2) - size.ws_row/4) + 2);
	printf("%s%sError%s%s : %s", Bold , Red ,Regular, Default , error);
	exit(1);
}

void Explorer(UI* ui ,char* path , int index)
{
	Init_Dir();
	List_Dir(path);
	if(is_error != success){
		Error_Box(GetError(is_error));
		exit(1);
	}
	int i = 2;
	move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + 1);
	for(int row = 0 ; !__dirs[index].the_last &&  row < ((idx < (ui->box_row_pos_size_buttom - ui->box_row_pos_size_top)) ? idx : (ui->box_row_pos_size_buttom - ui->box_row_pos_size_top - 1)) ; row++)
	{
		move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + i++);
		if(ui->box_row_pos_size_top + (row + 1) == ui->cursor_position_row)
			printf("%s %d - %s%s%s%s\t:%zu\t:%s\n",file_pos ,__dirs[index].file_idx,__dirs[index].is_dir ? Blue : Default ,__dirs[index].filename , Default , Regular, __dirs[index].file_size , __dirs[index].is_dir ? "(dir)" : "(file)");
		else
			printf("   %d - %s%s%s%s\t:%zu\t:%s\n",__dirs[index].file_idx,__dirs[index].is_dir ? Blue : Default ,__dirs[index].filename , Default , Regular, __dirs[index].file_size , __dirs[index].is_dir ? "(dir)" : "(file)");
		index++;
	}
	move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + 1);
	i = 2;
}

static void input_mode_disable(Term* saved_tattr){
  	tcsetattr(STDIN_FILENO, TCSANOW, saved_tattr);
}

static void input_mode_enable(Term* tattr) {
    tcgetattr(STDIN_FILENO, tattr);
    tattr->c_lflag &= ~(ICANON | ECHO); 
    tattr->c_cc[VMIN] = 1;
    tattr->c_cc[VTIME] = 0;             
    tcsetattr(STDIN_FILENO, TCSANOW, tattr);
}

static void input_mode_reset(Term* tattr) {
    tcgetattr(STDIN_FILENO, tattr);
    tattr->c_lflag |= (ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, tattr);
}

static Size get_term_size(){
	Size w;
	ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
	return w;
}

static unsigned short calc_box_col_pos_left_size(Size term_size)
{
	unsigned short p;
	p = (term_size.ws_col)/2;
	if(p < (term_size.ws_col - p)){
		p = (term_size.ws_col - p);
	}
	return (p / 4);
}
static unsigned short calc_box_col_pos_right_size(Size term_size)
{
	return (term_size.ws_col - calc_box_col_pos_left_size(term_size));
}

static unsigned short calc_box_row_pos_size_top(Size term_size)
{
	return (term_size.ws_row / 8);
}

static unsigned short calc_box_row_pos_size_buttom(Size term_size)
{
	return (term_size.ws_row / 2);
}
static int flush_file()
{
	return fflush(stdout);
}

static void main_box(Size term_size)
{
	int i = 1;
	for(int row = 1 ; row < term_size.ws_row ; row++){
		move_cursor(1, i++);
		for(int col = 1 ; col < term_size.ws_col ; col++){
			if(row == 1 && col == 1)								printf("%s" , five);
			else if(row == 1 && col == (term_size.ws_col - 1))						printf("%s" , four);
			else if(row == (term_size.ws_row - 1) && col == 1)    					printf("%s" , nine);
			else if(row == (term_size.ws_row - 1) && col == (term_size.ws_col - 1))				printf("%s" ,eit);
			else if((row == 1 && (col < (term_size.ws_col - 1) || col > 1)) || (row == (term_size.ws_row - 1) && (col < (term_size.ws_col - 1) || col > 1)))
				printf("%s" , one);
			else if((row < (term_size.ws_row - 1) && row > 1) && (col == 1 || col == (term_size.ws_col - 1)))	printf("%s" , two);
			else 	printf(" ");
		}
	}

}
static void print_keys(UI ui , Size size)
{
	int i = 0;
	for(int row = (ui.box_row_pos_size_buttom + 3) ; row < (size.ws_row - 2) ; row++){
		move_cursor( 4 , (ui.box_row_pos_size_buttom + 3) + i++);
		for(int col = 4 ; col < (size.ws_col / 4) ; col++){
			if(row == (ui.box_row_pos_size_buttom + 3) && col == 4)		
				printf("%s" , five);
			else if(row == (ui.box_row_pos_size_buttom + 3) && col == (size.ws_col / 4) -1)	
				printf("%s" , four);
			else if(row == (size.ws_row - 3) && col == 4)    	
				printf("%s" , nine);
			else if(row == (size.ws_row - 3) && col == (size.ws_col / 4) - 1)				
				printf("%s" ,eit);
			else if((row == (ui.box_row_pos_size_buttom + 3) && (col < (size.ws_col / 4) || col > 3)) || 
					(row == (size.ws_row - 3) && (col < (size.ws_col / 4) || col > 4)))
				printf("%s" , one);
			else if(
					(row < (size.ws_row - 3) && row > ui.box_row_pos_size_buttom + 3) && 
					(col == 4 || col == (size.ws_col / 4) - 1))	
				printf("%s" , two);
			else 	printf(" ");
		}
	}
}

#endif


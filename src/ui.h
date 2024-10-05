/*
 *				Copyright (c) 2024 Ray Den
 *		
 *		Permission is hereby granted, free of charge, to any person obtaining a copy
 *		of this software and associated documentation files (the "Software"), to deal
 *		in the Software without restriction, including without limitation the rights
 *		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *		copies of the Software, and to permit persons to whom the Software is
 *		furnished to do so, subject to the following conditions:
 *		
 *		The above copyright notice and this permission notice shall be included in
 *		all copies or substantial portions of the Software.
 *		
 *		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *		THE SOFTWARE.
 */
////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @file ui.h
 * @brief Header file for the UI module
 * @author Ray Den
 * @copyright 2024 Ray Den
 * @license check LICENCE file
 */

#ifndef UI_H_
#define UI_H_

// Screen 
typedef struct winsize Size;

// CODES :
// 	clear screen : "\033[2J"
//	move cursor x,y : "\033[<number>;<number>H"
//	move cursor up by number : "\033[<number>A"
//	move cursor down by number : "\033[<number>B"
//	move cursor right by number : "\033[<number>C"
//	move cursor left by number : "\033[<number>D"
//	hide cursor : "\033[?25l"
//	show cursor : "\033[?25h"
//

// clear screen pragma will print "\033[2J" code to standard output
// this code will clean buffer of stdout stream

#ifndef clearscreen
#	define clearscreen()	fputs("\033[2J",stdout)
#endif

// move cursor pragma will print "\033[<number>;<number>H" code to standard output
// this code will move cursor to x , y  number in terminal size 
#ifndef move_cursor
#define move_cursor(x , y)	\
	printf("\033[%d;%dH" , y, x);
#endif

/////// read codes at line 42

#define move_up	\
	printf("\033[1A");

#define move_down	\
	printf("\033[1B");

#define move_right	\
	printf("\033[1C");

#define move_left	\
	printf("\033[1D");

#define hide_cursor() 	printf("\033[?25l");
#define show_cursor()	printf("\033[?25h");

////////

// emojis code used for styles 
#define song_char_1	"💕"
#define song_char_2	"💞"
#define song_char_3	"🎵"
#define song_char_4	"🎶"
#define song_char_5	"💖"

#define bar_1		"❚"
#define bar_2		"❙"
#define bar_3		"❘"

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
#define rep "⭯"
#define pause   "⏸"
#define volume_max	"🔊"
#define volume_mute	"🔇"
#define volume_low	"🔈"
#define volume_med	"🔉"

#define single_loop	"🔂"
#define	playlist_loop	"🔁"
#define ones		"ONES"
#define shufle		"🔀"

#define _snow	"❆"
#define _stars	"✨"

#define search_emo	"🔎"

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

// stles
typedef enum{
	rmp,
	stars
}Style;

#define do_style(name_style , ui)	name_style##_t ((ui))

// terminal to get window size 
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

	// keys box map
	struct{
		unsigned short box_keys_col_pos_left_size;
		unsigned short box_keys_col_pos_right_size;
		unsigned short box_keys_row_pos_top_size;
		unsigned short box_keys_row_pos_bottom_size;
	}Keys;

	unsigned short cursor_position_col;
	unsigned short cursor_position_row;
	bool help;
	bool explorer;
	bool directory_directly;
	//bool show_albom;
	bool fav_albome;
	int (*Flush)(void);

	// styles
	Style style;

	// audio icons
	float volume;
	bool is_pause;
	float cursor;
	float total_length;
	Status status;
}UI;

/**
 * @brief Initializes the UI window
 * @param term A pointer to a Term struct
 * @return A UI struct representing the initialized window
 */
UI   UI_Window_Init(Term*);

/**
 * @brief Updates the UI window
 * @param ui A pointer to a UI struct
 */
void UI_Window_Update(UI* ui);

/**
 * @brief Finalizes the UI window
 * @param saved_tattr A pointer to a Term struct
 */
void UI_Window_Final(Term*);

/**
 * @brief Draws a box on the UI window
 * @param ui A pointer to a UI struct
 */
void DrawBox(UI ui);

// favorite albome

/**
 * @brief Initializes the favorite album
 */
void init_fav_albome(void);

/**
 * @brief Adds a song to the favorite album
 * @param song_path The path to the song file
 * @param quit A pointer to a boolean indicating whether to quit
 */
void add_song_to_fav_albome(char* song_path , bool* quit);

/**
 * @brief Loads the favorite album
 * @param ui A pointer to a UI struct
 * @param index The index of the file
 */
void load_fav_albome(UI* ui , int index);

/*
* @brief log any error or not or message
* @param char* log message 
* @param Log {_ERROR , NOTE , MESSAGE} type of log
* @param bool* pointing to quit memory variable to quit if the error 
*
*/ 
void Error_Box(char* , Log , bool*);

/*
 * @brief list file and directory's
 * @param ui A pointer to a UI struct
 * @param path the path we are listing
 * @param index the index of the cursor position
 * */
void Explorer(UI* ui ,char* path , int index);

/*
 * @brief print informations like is audio playing total time status and volume
 * @param ui A pointer to a UI struct
 * @param size terminal size 
 * */
void print_keys(UI* ui , Size size);

/*
 * @brief function to get terminal size
 * @return return a struct Size contains window information
 * */
Size get_term_size(void);

// styles
void rmp_t(UI);
void stars_t(UI);

#endif //UI_H_

#ifdef UI_C_

extern int idx;
extern Directoy __dirs[200];

static void 		input_mode_enable(Term* tattr);
static void 		input_mode_reset(Term* tattr);
static void 		input_mode_disable(Term* saved_tattr);
static unsigned short 	calc_box_col_pos_right_size(Size term_size);
static unsigned short 	calc_box_col_pos_left_size(Size term_size);
static unsigned short 	calc_box_row_pos_size_top(Size term_size);
static unsigned short 	calc_box_row_pos_size_buttom(Size term_size);
static int 		flush_file(void);	
static void		main_box(Size term_size);

// TODO: handle this 

//static char* get_albome_dir();
static bool in(char* , FILE*);
static void del(char*);
static int countlines(char *filename);
static char* fix_ui_box_border(UI ui , char* filename , size_t size_of_str_length_filename);
static void helpkeys(UI ui);

UI UI_Window_Init(Term* term){
	UI ui;
	clearscreen();
	input_mode_enable(term);
	hide_cursor();
	ui.box_col_pos_left_size 	= calc_box_col_pos_left_size(get_term_size());
	ui.box_col_pos_right_size	= calc_box_col_pos_right_size(get_term_size());
	ui.box_row_pos_size_top 	= calc_box_row_pos_size_top(get_term_size());
	ui.box_row_pos_size_buttom 	= calc_box_row_pos_size_buttom(get_term_size()) + 2;

	ui.Keys.box_keys_col_pos_left_size = 4;
	ui.Keys.box_keys_col_pos_right_size = (get_term_size().ws_col / 3);
	ui.Keys.box_keys_row_pos_top_size = (ui.box_row_pos_size_buttom + 2);
	ui.Keys.box_keys_row_pos_bottom_size = (get_term_size().ws_row - 2);

	ui.cursor_position_col 		= ui.box_col_pos_left_size + 1;
	ui.cursor_position_row 		= ui.box_row_pos_size_top + 1;
	ui.help				= false;
	ui.explorer			= false;
	ui.directory_directly		= false;
	ui.fav_albome 			= false;
	ui.cursor			= 0;
	ui.style 			= rmp;
	ui.Flush			= flush_file;
	main_box(get_term_size());
	DrawBox(ui);
	do_style(rmp, ui);
	ui.Flush();
	return ui;
}

void UI_Window_Update(UI* ui)
{
	ui->box_col_pos_left_size 	= calc_box_col_pos_left_size(get_term_size());
	ui->box_col_pos_right_size	= calc_box_col_pos_right_size(get_term_size());
	ui->box_row_pos_size_top 	= calc_box_row_pos_size_top(get_term_size());
	ui->box_row_pos_size_buttom 	= calc_box_row_pos_size_buttom(get_term_size());

	ui->Keys.box_keys_col_pos_left_size = 4;
	ui->Keys.box_keys_row_pos_top_size = (ui->box_row_pos_size_buttom + 2);
	ui->Keys.box_keys_row_pos_bottom_size = (get_term_size().ws_row - 2);

	clearscreen();
	main_box(get_term_size());
	DrawBox(*ui);
	if(!ui->explorer){
		if(ui->style == 0)
			do_style(rmp, *ui);
		else
			do_style(stars, *ui);
	}
	if(ui->help){
		helpkeys(*ui);
	}
	if(!ui->help)
		print_keys(ui , get_term_size());
}

void UI_Window_Final(Term* saved_tattr)
{
	if(saved_tattr != NULL)
		input_mode_disable(saved_tattr);
	input_mode_reset(saved_tattr);
	show_cursor();
	clearscreen();
}

void rmp_t(UI ui)
{
	size_t banner_size_x = 49;
	size_t banner_size_y = 6;
	int x = ((ui.box_col_pos_right_size - ui.box_col_pos_left_size) / 2) - (banner_size_x / 2);
	int y = ((ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 1) / 2) - (banner_size_y / 4);
	move_cursor(ui.box_col_pos_left_size + x, ui.box_row_pos_size_top + y++);
	printf("██████╗  █████╗ ██╗   ██╗     ███╗   ███╗██████╗ ");
	move_cursor(ui.box_col_pos_left_size + x, ui.box_row_pos_size_top + y++);
	printf("██╔══██╗██╔══██╗╚██╗ ██╔╝     ████╗ ████║██╔══██╗");
	move_cursor(ui.box_col_pos_left_size + x, ui.box_row_pos_size_top + y++);
	printf("██████╔╝███████║ ╚████╔╝█████╗██╔████╔██║██████╔╝");
	move_cursor(ui.box_col_pos_left_size + x, ui.box_row_pos_size_top + y++);
	printf("██╔══██╗██╔══██║  ╚██╔╝ ╚════╝██║╚██╔╝██║██╔═══╝ ");
	move_cursor(ui.box_col_pos_left_size + x, ui.box_row_pos_size_top + y++);
	printf("██║  ██║██║  ██║   ██║        ██║ ╚═╝ ██║██║     ");
	move_cursor(ui.box_col_pos_left_size + x, ui.box_row_pos_size_top + y++);
	printf("╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝        ╚═╝     ╚═╝╚═╝     ");
}

void stars_t(UI ui)
{
#define MAX_STARS	50
	srand(time(NULL));
	int _rands[MAX_STARS];
	for(int i = 0 ; i < MAX_STARS ; i += 2){
		_rands[i] = (rand()%(ui.box_col_pos_right_size - ui.box_col_pos_left_size - 1)) + ui.box_col_pos_left_size + 1;
		_rands[i + 1] = (rand()%(ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 1)) + ui.box_row_pos_size_top + 2;
	}
	for(int i = 0 ; i < MAX_STARS ; i += 4){
		move_cursor(_rands[i] , _rands[i + 1]);
		printf("%s",_stars);
		move_cursor(_rands[i + 2] , _rands[i + 3]);
		printf("%s",song_char_5);
	}
}

void DrawBox(UI ui)
{
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
		printf("[%sExplorer%s]" , Green , Regular);
	}else{
		move_cursor(ui.box_col_pos_left_size + ((ui.box_col_pos_right_size - ui.box_col_pos_left_size) / 4) , ui.box_row_pos_size_top + 1);
		printf("[%sStyles%s]" , Green , Regular);
	}
}



#define DEFAULT_DIR	".rmp"
char ALBOME_DIR[40];
char PATH[50];

void init_fav_albome(void)
{
	sprintf(ALBOME_DIR , "/home/%s/%s" , getlogin() , DEFAULT_DIR);
	if((is_error = mkdir(ALBOME_DIR , 0755)) < 0){
		is_error = errno ; 
		return;
	}

	sprintf(PATH , "%s/favorite" , ALBOME_DIR);
	FILE* file = fopen(PATH , "a");
	if(file == NULL){	
		is_error = failed_init_fav_albome;
		return;
	}
	fclose(file);
}

void add_song_to_fav_albome(char* song_path , bool* quit)
{
	FILE* file = fopen(PATH , "a+");
	if(file == NULL){
		is_error = errno;
		return ;
	}
	sprintf(song_path , "%s\n" , song_path);
	if(!in(song_path , file)){
		if(fputs(song_path, file) == EOF)
		       return ;
	}
	fclose(file);
	Error_Box("ADDED" , MESSAGE , NULL);
}

#define FAV_SONGS	100 // max songs
char fav_albome[FAV_SONGS][257];

void load_fav_albome(UI* ui , int index)
{
	int lines = countlines(PATH);
	if(lines > 99)	return;
	FILE* file = fopen(PATH , "r");
	if(file == NULL){
		is_error = failed_to_load_fav_albome;
		return ;
	}

	for(int i = 0 ; i < lines ; i++){
		fgets(fav_albome[i] , 256 , file);
	}

	move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + 1);
	int max_row = ((lines < (ui->box_row_pos_size_buttom - ui->box_row_pos_size_top)) ? lines : (ui->box_row_pos_size_buttom - ui->box_row_pos_size_top - 1));
	for(int row = 0 ; *fav_albome[index] != '\0' &&  row < max_row ; row++)
	{
		move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + row + 2);
		if(ui->box_row_pos_size_top + (row + 1) == ui->cursor_position_row)
			printf("%s - %s\n",file_pos ,fix_ui_box_border(*ui , strrchr(fav_albome[index] , '/') , 0));
		else
			printf("   - %s\n",fix_ui_box_border(*ui , strrchr(fav_albome[index], '/') ,0));
		index++;
	}
	move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + 1);
}

static void helpkeys(UI ui)
{
	clearscreen();
	int i = 2;
	move_cursor(2,i++);
	printf("%s?%s : to show this help page" , Green , Regular);
	move_cursor(2,i++);
	printf("%sq%s : to quit" , Green , Regular);
	move_cursor(2,i++);
	printf("%su%s : to update UI" , Green , Regular);
	move_cursor(2,i++);
	printf("%se%s : to open file Explorer" , Green , Regular);
	move_cursor(2,i++);
	printf("%sSPACE%s : pause and play song" , Green , Regular);
	move_cursor(2,i++);
	printf("%s+%s : to increase the volume" , Green , Regular);
	move_cursor(2,i++);
	printf("%s-%s : to reduce volume" , Green , Regular);
	move_cursor(2,i++);
	printf("%sj/[ARROW KEY DOWN]%s : to move cursor down" , Green , Regular);
	move_cursor(2,i++);
	printf("%sk/[ARROW KEY UP]%s : to move cursor up" , Green , Regular);
	move_cursor(2,i++);
	printf("%s>%s : change to next song" , Green , Regular);
	move_cursor(2,i++);
	printf("%s<%s : change to prev song" , Green , Regular);
	move_cursor(2,i++);
	printf("%si%s : change window style" , Green , Regular);
	move_cursor(2,i++);
	printf("%sTAB%s : change status [single-loop , playlist-loop , ones]" , Green , Regular);
	move_cursor(2,i++);
	printf("%s.%s : change directory to '..' " , Green , Regular);

}

static bool in(char* path, FILE* fav_albome)
{
	char temp[256];
	while(fav_albome != NULL && !feof(fav_albome)){
       		fgets(temp, 256, fav_albome);
		if(strcmp(path , temp) == 0)	return true;
	}
	return false;
}

static void del(char*)
{

}

static int countlines(char *filename)
{
	FILE *fp = fopen(filename,"r");
	int ch=0;
	int lines=0;
	
	if (fp == NULL)
		return 0;
	
	lines++;
	while ((ch = fgetc(fp)) != EOF){
	        if (ch == '\n')
		lines++;
	}
	fclose(fp);
	return lines;
}

void Error_Box(char* error , Log log , bool* quit)
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
	int x = 2;
	size_t size_ = (((size.ws_col/2)+(size.ws_col/4)) - ((size.ws_col/2)-(size.ws_col/4)));
	size_t error_size = strlen(error);
	move_cursor((size.ws_col/2)-(size.ws_col/4)+1 ,((size.ws_row/2) - size.ws_row/4) + x++);
	if(log == _ERROR){
		printf("%s%sError%s%s : ", Bold , Red ,Regular, Default);
		if(quit != NULL)
			*quit = true;
	}else if( log == NOTE){
		printf("%s%sNote%s%s : ", Bold , Blue ,Regular, Default);
	}else{
		printf("%s%sMessage%s%s : ", Bold , Green ,Regular, Default);
	}
	if(error_size > size_){
		while(*error != '\0'){
			for(int i = 0 ; i < size_ ; i++){
				printf("%c" , *error);
				error++;
			}
			error_size -= size_;
			move_cursor((size.ws_col/2)-(size.ws_col/4)+1 ,((size.ws_row/2) - size.ws_row/4) + x++);
		}
	}else{
		printf("%s" , error);
	}
	fflush(stdout);
	sleep(2);
}

void Explorer(UI* ui ,char* path , int index)
{
	Init_Dir();
	List_Dir(path);
	move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + 1);
	int max_row = ((idx < (ui->box_row_pos_size_buttom - ui->box_row_pos_size_top)) ? idx : (ui->box_row_pos_size_buttom - ui->box_row_pos_size_top - 1));
	for(int row = 0 ; *__dirs[index].filename != '\0' &&  row < max_row ; row++)
	{
		move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + row + 2);
		if(ui->box_row_pos_size_top + (row + 1) == ui->cursor_position_row)
			printf("%s %.2d -%c-%s- %s%s%s%s%s\n",file_pos ,__dirs[index].file_idx,  __dirs[index].is_dir ? 'd' : 'f', handle_size(__dirs[index].file_size),Green,__dirs[index].is_dir ? Blue : "" ,fix_ui_box_border(*ui , strrchr(__dirs[index].filename , '/') , strlen(handle_size(__dirs[index].file_size))) , Default , Regular);
		else
			printf("  %.2d -%c-%s- %s%s%s%s\n",__dirs[index].file_idx , __dirs[index].is_dir ? 'd' : 'f', handle_size(__dirs[index].file_size),__dirs[index].is_dir ? Blue : Default ,fix_ui_box_border(*ui , strrchr(__dirs[index].filename, '/') ,strlen(handle_size(__dirs[index].file_size))), Default , Regular);
		index++;
	}
	move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + 1);
}

static char* fix_ui_box_border(UI ui , char* filename_to_copy , size_t size_of_str_length_filename)
{
	size_t file_to_copy_size = strlen(filename_to_copy) + 1;
#ifndef ONES_FILE
#define ONES_FILE
	char* filename = malloc(file_to_copy_size);
#endif

#ifdef ONES_FILE
	filename = realloc(filename, file_to_copy_size);
#endif
        strcpy(filename, filename_to_copy);
	int compare = (ui.box_col_pos_right_size - ui.box_col_pos_left_size - 11 - size_of_str_length_filename);
	if(file_to_copy_size > compare)
	{
		for(int i = 1 ; i < 4 ; i++){
			filename[compare - i] = '.';
		}
		filename[compare] = '\0';
	}
	return filename;
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

Size get_term_size(){
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

void print_keys(UI* ui , Size size)
{
	int i = 0;
	for(int row = ui->Keys.box_keys_row_pos_top_size ; row < ui->Keys.box_keys_row_pos_bottom_size ; row++){
		move_cursor( ui->Keys.box_keys_col_pos_left_size , ui->Keys.box_keys_row_pos_top_size + i++);
		for(int col = ui->Keys.box_keys_col_pos_left_size ; col < ui->Keys.box_keys_col_pos_right_size ; col++){
			if(row == (ui->Keys.box_keys_row_pos_top_size) && col == ui->Keys.box_keys_col_pos_left_size)		
				printf("%s" , five);
			else if(row == (ui->Keys.box_keys_row_pos_top_size) && col == (ui->Keys.box_keys_col_pos_right_size) - 1)	
				printf("%s" , four);
			else if(row == (ui->Keys.box_keys_row_pos_bottom_size - 1) && col == ui->Keys.box_keys_col_pos_left_size)    	
				printf("%s" , nine);
			else if(row == (ui->Keys.box_keys_row_pos_bottom_size - 1) && col == (ui->Keys.box_keys_col_pos_right_size) - 1)				
				printf("%s" ,eit);
			else if(
					(row == (ui->Keys.box_keys_row_pos_top_size) && (col < (ui->Keys.box_keys_col_pos_left_size) || col > ui->Keys.box_keys_col_pos_left_size - 1)) 
					|| 
					(row == (ui->Keys.box_keys_row_pos_bottom_size - 1) && (col < (ui->Keys.box_keys_col_pos_right_size) || col > ui->Keys.box_keys_col_pos_left_size - 1)))
				printf("%s" , one);
			else if(
					(row < (ui->Keys.box_keys_row_pos_bottom_size) && row > ui->Keys.box_keys_row_pos_top_size) && 
					(col == ui->Keys.box_keys_col_pos_left_size || col == (ui->Keys.box_keys_col_pos_right_size) - 1))	
				printf("%s" , two);
			else 	printf(" ");
		}
	}
	if((ui->Keys.box_keys_col_pos_right_size - ui->Keys.box_keys_col_pos_left_size - 1) <= 27){
		ui->Keys.box_keys_col_pos_right_size += 1;
	}
	int move = 1;
	move_cursor(ui->Keys.box_keys_col_pos_left_size + 1, ui->Keys.box_keys_row_pos_top_size + move++);
	if(ui->is_pause)
		printf("Audio Status %s  : [%sPLAYING%s]" , next ,Green ,Regular);
	else
		printf("Audio Status %s  : [%sPaused%s]" , pause ,Red ,Regular);

	move_cursor(ui->Keys.box_keys_col_pos_left_size  + 1,ui->Keys.box_keys_row_pos_top_size + move++);
	if((int)ui->volume == 100)
		printf("Volume       %s : %d %c" , volume_max , (int)ui->volume , 37);
	else if ((int)ui->volume >= 50)
		printf("Volume       %s : %d %c" , volume_med , (int)ui->volume , 37);
	else if ((int)ui->volume < 50 && (int)ui->volume > 0)
		printf("Volume       %s : %d %c" , volume_low , (int)ui->volume , 37);
	else
		printf("Volume       %s : %d %c" , volume_mute , (int)ui->volume , 37);

	move_cursor(ui->Keys.box_keys_col_pos_left_size + 1 , ui->Keys.box_keys_row_pos_top_size + move++);
	printf("Total Time      : %d %c" , (int)ui->total_length , 's');

	move_cursor(ui->Keys.box_keys_col_pos_left_size + 1 , ui->Keys.box_keys_row_pos_top_size + move++);
	printf("Cursor Position : %d %c" , (int)ui->cursor , 's');

	move_cursor(ui->Keys.box_keys_col_pos_left_size + 1 , ui->Keys.box_keys_row_pos_top_size + move++);
	if(ui->status == PLAYLIST_LOOP)
		printf("Status %s " , playlist_loop);
	else if(ui->status == SINGLE_LOOP)
		printf("Status %s " , single_loop);
	else
		printf("Status %s " , ones);
	ui->Flush();
}
#endif


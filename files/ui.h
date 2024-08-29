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

#define song_char_1	"♩"
#define song_char_2	"♪"
#define song_char_3	"♫"
#define song_char_4	"♬"

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

typedef enum{
	rmp,
	stars
}Style;

#define do_style(name_style , ui)	name_style##_t ((ui))

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
	bool explorer;
	bool show_albom;
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

// even file explorer
typedef void(*Function_Style)(UI ui);

UI   UI_Window_Init(Term*);
void UI_Window_Update(UI* ui);
void UI_Window_Final(Term*);
void DrawBox(UI ui);

void Error_Box(char* , Log , bool*);
void Explorer(UI* ui ,char* path , int index);
void print_keys(UI* ui , Size size);
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
	ui.explorer			= false;
	ui.show_albom 			= false;
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

		//ui->Keys.box_keys_row_pos_top_size--;
		//ui->box_row_pos_size_top--;
		//ui->box_row_pos_size_buttom--;


	ui->box_col_pos_left_size 	= calc_box_col_pos_left_size(get_term_size());
	ui->box_col_pos_right_size	= calc_box_col_pos_right_size(get_term_size());
	ui->box_row_pos_size_top 	= calc_box_row_pos_size_top(get_term_size());
	ui->box_row_pos_size_buttom 	= calc_box_row_pos_size_buttom(get_term_size());

	ui->Keys.box_keys_col_pos_left_size = 4;
	ui->Keys.box_keys_row_pos_top_size = (ui->box_row_pos_size_buttom + 2);
	ui->Keys.box_keys_row_pos_bottom_size = (get_term_size().ws_row - 2);

	ui->show_albom 			= false;
	clearscreen();
	main_box(get_term_size());
	DrawBox(*ui);
	if(!ui->explorer){
		if(ui->style == 0)
			do_style(rmp, *ui);
		else
			do_style(stars, *ui);
	}
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
		printf("%s",_snow);
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
	sleep(4);
}

static char* fix_ui_box_border(UI ui , char* filename , size_t size_of_str_length_filename);

void Explorer(UI* ui ,char* path , int index)
{
	Init_Dir();
	List_Dir(path);
	int local_idx = idx;
	move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + 1);
	int max_row = ((idx < (ui->box_row_pos_size_buttom - ui->box_row_pos_size_top)) ? idx : (ui->box_row_pos_size_buttom - ui->box_row_pos_size_top - 1));
	for(int row = 0 ; *__dirs[index].filename != '\0' &&  row < max_row ; row++)
	{
		move_cursor(ui->box_col_pos_left_size + 1 , ui->box_row_pos_size_top + row + 2);
		if(ui->box_row_pos_size_top + (row + 1) == ui->cursor_position_row)
			printf("%s %.2d -%c-%s- %s%s%s%s\n",file_pos ,__dirs[index].file_idx , __dirs[index].is_dir ? 'd' : 'f', handle_size(__dirs[index].file_size),__dirs[index].is_dir ? Blue : Default ,fix_ui_box_border(*ui , strrchr(__dirs[index].filename , '/') , strlen(handle_size(__dirs[index].file_size))) , Default , Regular);
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


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
//#include <termios.h>
//#include <sys/ioctl.h>
//#include <unistd.h>


#define DIR_ON
#define UI_C_
#define MINIAUDIO_IMPLEMENTATION
#define AUDIO_C_
#define DR_MP3_IMPLEMENTATION
#define DR_FLAC_IMPLEMENTATION
#define DR_WAV_IMPLEMENTATION

#include "./files/rdirectorys.h"
#include "./files/third_party/dr_mp3.h"
#include "./files/third_party/dr_flac.h"
#include "./files/third_party/dr_wav.h"
#include "./files/third_party/miniaudio.h"
#include "./files/audio.h"
#include "./files/ui.h"

// TODO: create file explorer
// TODO: handle songs
// TODO: handle keys
// TODO: UI  
// TODO: pause , run , next , volume
// TODO: search over internet


int main(void)
{

	//Size w;
	//ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);
	//printf("col = %u\nrows = %u" , w.ws_col , w.ws_row);

	// list files and directorys

	//List_Dir(".");
	//Dump_files();

	//Error err = 0;
	//if((err = InitAudioDevice()) != init_success){
	//	fprintf(stderr , "ERROR : %s" , get_err(err));
	//	return 1;
	//}
	//Sound sound ; 
	//if(( err = LoadSound("/home/rayden/Music/Eminem - Mockingbird [Official Music Video].mp3" , &sound)) != 0){
	//	fprintf(stderr , "ERROR : %s" , get_err(err));
	//	return 1;
	//}
	//SetSoundVolume(sound , 0.4f);
	//PlaySound(sound);
	//while(true){
	//	if(!IsSoundPlaying(sound)){
	//		sleep(15);
	//	}
	//}
	//CloseAudioDevice();

	//struct termios* term = NULL;
	UI ui = UI_Window_Init();
	//printf("ui.box_col_pos_left_size = %d\n" ,ui.box_col_pos_left_size );
	//printf("ui.box_col_pos_right_size = %d\n",ui.box_col_pos_right_size);
	//printf("ui.box_row_pos_size_top = %d\n",ui.box_row_pos_size_top);
	//printf("ui.box_row_pos_size_buttom = %d\n",ui.box_row_pos_size_buttom);
	//printf("ui.cursor_position_col = %d\n",ui.cursor_position_col);
	//printf("ui.cursor_position_row = %d\n",ui.cursor_position_row);
	//printf("ui.show_albom = %d",ui.show_albom);
	move_cursor(ui.box_col_pos_left_size , ui.box_row_pos_size_top);
	printf("*");
	move_cursor(ui.box_col_pos_left_size , ui.box_row_pos_size_buttom);
	printf("*");
	move_cursor(ui.box_col_pos_right_size , ui.box_row_pos_size_top);
	printf("*");
	move_cursor(ui.box_col_pos_right_size , ui.box_row_pos_size_buttom);
	printf("*");
	ui.flush();
	sleep(50);
	UI_Window_Final(NULL);
	return 0;
}

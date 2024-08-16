#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
//#include <termios.h>
//#include <sys/ioctl.h>
//#include <unistd.h>

//#define DIR_ON
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



	bool quit = false;
	Term term;
	int index = 0;
	UI ui = UI_Window_Init(&term);
	char ch;
	while(!quit)
	{
		if(ui.explorer){
			DrawBox(ui , NULL);
			Explorer(&ui , NULL , index);
			//Dump_files();
		}
		else
			DrawBox(ui ,NULL);
		ch = getchar();
		/*
		 *	keys : 
		 *		q : for quit
		 *		u : update ui (im gonna handle it later)
		 *		e : open file explorer
		 *		f : add song to favorit
		 *		p : pause and play
		 *		+ : increase the volume
		 *		j : move cursor down
		 *		k : move cursor up
		 *		- : reduce volume
		 *		n : next
		 *		N : prev
		 *		i : change style window or switch to style window (file explorer enabled)
		 *		a : open favorit songs
		 *		s : search songs on locale device
		 *		S : for search on internet
		 *		? : show help list
		 * */ 
		switch(ch){
			case 10 : {
				printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nDebug : ui.cursor_position_row = %d\nidx = %d\n(ui.box_row_pos_size_buttom - ui.box_row_pos_size_top) = %di\n index = %d" , ui.cursor_position_row, idx ,(ui.box_row_pos_size_buttom - ui.box_row_pos_size_top) , index);
			}break;
			case 'f':{
				Error_Box(" f key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'j':{
				if(idx < (ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 1)){
					if(ui.explorer && (ui.cursor_position_row < (idx + ui.box_row_pos_size_top)))
						ui.cursor_position_row += 1;
				}else if(idx > (ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 1)){
					if(ui.cursor_position_row == (ui.box_row_pos_size_buttom - 1) && 
							((ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 1) < idx)){
						ui.cursor_position_row = ui.box_row_pos_size_top + 1;
						if((index + (ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 1)) <= idx){
							index += (ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 2);
							idx -= (ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 2);
						}
						else{
							index += (idx - index);
						}
						continue;
					}
					if(ui.explorer && (ui.cursor_position_row < (idx - index + ui.box_row_pos_size_top)/*(ui.box_row_pos_size_buttom - 1)*/)){
							ui.cursor_position_row += 1;
					}
				}
			}break;
			case 'k' : {
				if((idx < (ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 1)) || (idx > (ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 1))){
					if((ui.cursor_position_row == (ui.box_row_pos_size_top + 1)) && (index > 0)){
						ui.cursor_position_row = ui.box_row_pos_size_buttom - 1;
						index -= (ui.box_row_pos_size_buttom - ui.box_row_pos_size_top - 2);
					}
					if(ui.explorer && (ui.cursor_position_row > (ui.box_row_pos_size_top + 1))){
						ui.cursor_position_row -= 1;
					}
				}
			}break;
			case 'p':{
				Error_Box(" p key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case '+':{
				Error_Box(" + key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case '-':{
				Error_Box(" - key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'n':{
				Error_Box(" n key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'N':{
				Error_Box(" N key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'i':{
				Error_Box(" i key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'a':{
				Error_Box(" a key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 's':{
				Error_Box(" s key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'S':{
				Error_Box(" S key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case '?':{
				Error_Box(" ? key is not implemented \n exiting");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'u' : {
				UI_Window_Update(&ui , ui.explorer);
			}break;
			case 'e' : {
				if(ui.explorer)
					ui.explorer = false;
				else
					ui.explorer = true;
				//DrawBox(ui , NULL);
				//Explorer(&ui , NULL);
				//Dump_files();
			}break;
			case 'q' : {
				quit = true;
			}
		}
		ui.Flush();
	}
	UI_Window_Final(&term);
	return 0;
}


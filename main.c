#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <dirent.h>
#include <sys/types.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <time.h>

#define DIR_ON
#define UI_C_
#define MINIAUDIO_IMPLEMENTATION
#define AUDIO_C_

#include "./files/error.h"
#include "./files/rdirectorys.h"
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
#if 1
	bool quit = false;
	Term term;
	MP_Audio audio = MP_Init_Audio();
	int index = 0;
	UI ui = UI_Window_Init(&term);
	char ch;
	char current_directory[256];
	current_directory[0] = '.';
	while(!quit)
	{
		if(ui.explorer){
			DrawBox(ui , NULL);
			Explorer(&ui , current_directory , index);
			//Dump_files();
		}
		else
			DrawBox(ui ,NULL);
		ch = getchar();
		/*
		 *	keys : 
		 *		q     : for quit
		 *		u     : update ui (im gonna handle it later)
		 *		e     : open file explorer
		 *		f     : add song to favorit
		 *		SPACE : pause and play
		 *		+     : increase the volume
		 *		j     : move cursor down
		 *		k     : move cursor up
		 *		-     : reduce volume
		 *		n     : next
		 *		N     : prev
		 *		i     : change style window or switch to style window (file explorer enabled)
		 *		a     : open favorit songs
		 *		s     : search songs on locale device
		 *		S     : for search on internet
		 *		?     : show help list
		 * */ 
		switch(ch){
			case 10 : {
				//printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nDebug : file = %s\nidx = %d" , __dirs[index + ui.cursor_position_row - ui.box_row_pos_size_top - 1].filename , idx);
				if(ui.explorer){
					if(__dirs[index + ui.cursor_position_row - ui.box_row_pos_size_top - 1].is_dir)
					{
						printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nDebug : current_directory = %s\n" , current_directory);
						current_directory[0] = '\0';
						strcpy(current_directory , __dirs[index + ui.cursor_position_row - ui.box_row_pos_size_top - 1].filename) ;
						index = 0;
					}else
					{
						MP_Update_Audio(&audio , __dirs[index + ui.cursor_position_row - ui.box_row_pos_size_top - 1].filename);
						PlayMusic(&audio);
					}
				}
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
			case 32 :{
				if(audio.is_audio_playing)
					StopMusic(&audio);
				else
				        PlayMusic(&audio);
			}break;
			case '+':{
				if(audio.volume <= 1)
					audio.volume += 0.1;
				SetVolume(&audio);
			}break;
			case '-':{
				if(audio.volume >= 0)
					audio.volume -= 0.1;
				SetVolume(&audio);
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
			}break;
			case 'q' : {
				quit = true;
			}
		}
		ui.Flush();
	}
	UI_Window_Final(&term);
	MP_Final_Audio(&audio);
	return 0;
#else
	Init_Dir();
	List_Dir("./.");
	Dump_files();
#endif
}


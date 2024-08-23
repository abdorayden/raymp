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
#include <pthread.h>

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

void* audio_always_update(void*);

int main(void)
{
	bool quit = false;
	Term term;
	MP_Audio audio = MP_Init_Audio();
	int index = 0;
	UI ui = UI_Window_Init(&term);
	char ch;
	bool ones = true;
	char current_directory[256];

	while(!quit)
	{
		ui.volume = audio.volume * 100;
		ui.is_pause = audio.is_audio_playing;
		ui.cursor = audio.cursor;
		ui.total_length = audio.song_length;
		ui.repeate = true; // by default
		UI_Window_Update(&ui);

		if(getcwd(current_directory , 256) == NULL){
			Error_Box(GetError(errno));
		}
		if(ui.explorer){
			DrawBox(ui , NULL);
			Explorer(&ui , current_directory , index);
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
				if(ui.explorer){
					if(__dirs[index + ui.cursor_position_row - ui.box_row_pos_size_top - 1].is_dir)
					{
						if(chdir(__dirs[index + ui.cursor_position_row - ui.box_row_pos_size_top - 1].filename) < 0){
							Error_Box(GetError(errno));
						}
						index = 0;
						ui.cursor_position_row = ui.box_row_pos_size_top + 1;
					}else
					{
						MP_Update_Audio(&audio , __dirs[index + ui.cursor_position_row - ui.box_row_pos_size_top - 1].filename);
						PlayMusic(&audio);
						if(ones){
							pthread_t thread;
							if( pthread_create(&thread , NULL , audio_always_update , (void*)&audio ) != 0)
							{
								Error_Box("failed to create thread !");
							}
							(void)thread;
							ones = !ones;
						}
					}
				}
			}break;
			case '\033' :{
				getchar();
				switch(getchar()){
					// up
					case 'A' : {
						//printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n test up");
					}break;
					// down
					case 'B' : {
						//printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n test down");
					}break;
					// right
					case 'C' : {
						if(audio.cursor < audio.song_length)
							audio.cursor += audio.seek_time;
						SeekPosition(&audio);
						MP_Update_Audio(&audio , NULL);
					}break;
					// left
					case 'D' : {
						if(audio.cursor > 0)
							audio.cursor -= audio.seek_time;
						SeekPosition(&audio);
						MP_Update_Audio(&audio , NULL);
					}break;
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
					audio.volume += 0.01;
				SetVolume(&audio);
			}break;
			case '-':{
				if(audio.volume >= 0)
					audio.volume -= 0.01;
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
				UI_Window_Update(&ui);
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
}

void* audio_always_update(void* param)
{
	MP_Audio* audio = (MP_Audio*)param;
	while(true)
	{
		if(audio->cursor == audio->song_length){
			PlayMusic(audio);
			audio->cursor = 0;
		}
		audio->cursor++;
		sleep(1);
	}
}

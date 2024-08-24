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

typedef struct {
	MP_Audio audio;
	UI	 ui;
	int _index ;
	char current_directory[256];
}Main;

void* main_always_update(void*);
void cursor_move_position_down(Main*);
void cursor_move_position_up(Main*);


int main(void)
{
	bool quit = false;
	Term term;
	Main _main;
	_main.audio = MP_Init_Audio();
	//int index = 0;
	_main.ui = UI_Window_Init(&term);
	_main._index = 0;
	char ch;
	bool _ones = true;
	//char current_directory[256];

	while(!quit)
	{
		_main.ui.Flush();
		_main.ui.volume = _main.audio.volume * 100;
		_main.ui.is_pause = _main.audio.is_audio_playing;
		//_main.ui.cursor = _main.audio.cursor;
		_main.ui.total_length = _main.audio.song_length;
		_main.ui.status = _main.audio.status;
		//_main.ui.repeate = true; // by default
		UI_Window_Update(&_main.ui);
		if(_ones){
			pthread_t thread;
			if( pthread_create(&thread , NULL , main_always_update , (void*)&_main) != 0)
			{
				Error_Box("failed to create thread !");
			}
			(void)thread;
			_ones = !_ones;
		}
		if(getcwd(_main.current_directory , 256) == NULL){
			Error_Box(GetError(errno));
		}
		if(_main.ui.explorer){
			DrawBox(_main.ui , NULL);
			Explorer(&_main.ui , _main.current_directory , _main._index);
		}
		else
			DrawBox(_main.ui ,NULL);
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
		 *		>     : next
		 *		<     : prev
		 *		i     : change style window or switch to style window (file explorer enabled)
		 *		a     : open favorit songs
		 *		s     : search songs on locale device
		 *		S     : for search on internet
		 *		?     : show help list
		 *		TAB 9 : change status
		 * */ 
		switch(ch){
			case 10 : {
				if(_main.ui.explorer){
					if(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].is_dir)
					{
						if(chdir(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].filename) < 0){
							Error_Box(GetError(errno));
						}
						_main._index = 0;
						_main.ui.cursor_position_row = _main.ui.box_row_pos_size_top + 1;
					}else
					{
						MP_Update_Audio(&_main.audio , __dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].filename);
						PlayMusic(&_main.audio);
					}
				}
			}break;
			case 9 :{
				if(_main.audio.status == 3){
					_main.audio.status = 0;
				}else{
					_main.audio.status++;
				}
			}break;
			case '\033' :{
				getchar();
				switch(getchar()){
					// up
					case 'A' : {
						cursor_move_position_up(&_main);
					}break;
					// down
					case 'B' : {
						cursor_move_position_down(&_main);
					}break;
					// right
					case 'C' : {
						if(_main.audio.cursor < _main.audio.song_length){
							_main.audio.cursor += _main.audio.seek_time;
							SeekPosition(&_main.audio);
						}
						MP_Update_Audio(&_main.audio , NULL);
						UI_Window_Update(&_main.ui);
					}break;
					// left
					case 'D' : {
						if(_main.audio.cursor > 0)
							_main.audio.cursor -= _main.audio.seek_time;
						SeekPosition(&_main.audio);
						MP_Update_Audio(&_main.audio , NULL);
					}break;
				}
			}break;
			case 'f':{
				Error_Box(" f key is not implemented ");
				_main.ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'j':{
				cursor_move_position_down(&_main);
			}break;
			case 'k' : {
				cursor_move_position_up(&_main);
			}break;
			case 32 :{
				if(_main.audio.is_audio_playing)
					StopMusic(&_main.audio);
				else
				        PlayMusic(&_main.audio);
			}break;
			case '>':{
				if(_main.ui.cursor_position_row < _main.ui.box_row_pos_size_buttom){
					cursor_move_position_down(&_main);
					MP_Update_Audio(&_main.audio , __dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].filename);
					PlayMusic(&_main.audio);
				}

			}break;
			case '<':{
				if(_main.ui.cursor_position_row > (_main.ui.box_row_pos_size_top)){
					cursor_move_position_up(&_main);
					MP_Update_Audio(&_main.audio , __dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].filename);
					PlayMusic(&_main.audio);
				}
			}break;
			case '+':{
				if(_main.audio.volume <= 1)
					_main.audio.volume += 0.01;
				SetVolume(&_main.audio);
			}break;
			case '-':{
				if(_main.audio.volume >= 0)
					_main.audio.volume -= 0.01;
				SetVolume(&_main.audio);
			}break;
			case 'n':{
				Error_Box(" n key is not implemented ");
				_main.ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'N':{
				Error_Box(" N key is not implemented ");
				_main.ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'i':{
				Error_Box(" i key is not implemented ");
				_main.ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'a':{
				Error_Box(" a key is not implemented ");
				_main.ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 's':{
				Error_Box(" s key is not implemented ");
				_main.ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'S':{
				Error_Box(" S key is not implemented ");
				_main.ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case '?':{
				Error_Box(" ? key is not implemented \n exiting");
				_main.ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'u' : {
				UI_Window_Update(&_main.ui);
			}break;
			case 'e' : {
				if(_main.ui.explorer)
					_main.ui.explorer = false;
				else
					_main.ui.explorer = true;
			}break;
			case 'q' : {
				quit = true;
			}
		}
		_main.ui.Flush();
	}
	UI_Window_Final(&term);
	MP_Final_Audio(&_main.audio);
	return 0;
}

int random_music(void){
	srand(time(NULL));
	return rand()%(idx - 1);
}

void* main_always_update(void* param)
{
	Main* _main = (Main*)param;
	while(true)
	{
		if(MusicAtEnd()){
			if(_main->ui.status == SINGLE_LOOP){
				//PlayMusic(&_main->audio);
				_main->audio.cursor = 0;
				//MP_Update_Audio(&_main->audio , NULL);
				MP_Update_Audio(&_main->audio , __dirs[_main->_index + _main->ui.cursor_position_row - _main->ui.box_row_pos_size_top - 1].filename);
				PlayMusic(&_main->audio);
			}else if(_main->ui.status == PLAYLIST_LOOP){
				cursor_move_position_down(_main);
				MP_Update_Audio(&_main->audio , __dirs[_main->_index + _main->ui.cursor_position_row - _main->ui.box_row_pos_size_top - 1].filename);
				PlayMusic(&_main->audio);
			// TODO: fix shuffle bug
			}else if(_main->ui.status == SHUFFLE){
				_main->_index = random_music();
				cursor_move_position_down(_main);
				MP_Update_Audio(&_main->audio , __dirs[_main->_index + _main->ui.cursor_position_row - _main->ui.box_row_pos_size_top - 1].filename);
				PlayMusic(&_main->audio);
			}
		}
		UpdateCursor(&(_main->audio));
		_main->ui.cursor = _main->audio.cursor;
		//print_keys(_main->ui , get_term_size());
		UI_Window_Update(&_main->ui);
		if(_main->ui.explorer){
			DrawBox(_main->ui , NULL);
			Explorer(&_main->ui , _main->current_directory , _main->_index);
		}
		else
			DrawBox(_main->ui ,NULL);
		//move_cursor(5 , (_main->ui.box_row_pos_size_buttom + 3) + 4);
		//printf("Cursor Position : %d %c" , (int)_main->audio.cursor , 's');
		_main->ui.Flush();
		sleep(1);
	}
}

void cursor_move_position_down(Main* _main)
{
	if(idx < (_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 1)){
		if(_main->ui.explorer && (_main->ui.cursor_position_row < (idx + _main->ui.box_row_pos_size_top)))
			_main->ui.cursor_position_row += 1;
	}else if(idx > (_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 1)){
		if(_main->ui.cursor_position_row == (_main->ui.box_row_pos_size_buttom - 1) && 
				((_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 1) < idx)){
			_main->ui.cursor_position_row = _main->ui.box_row_pos_size_top + 1;
			if((_main->_index + (_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 1)) <= idx){
				_main->_index += (_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 2);
				idx -= (_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 2);
			}
			else{
				_main->_index += (idx - _main->_index);
			}
			//continue;
			return ;
		}
		if(_main->ui.explorer && (_main->ui.cursor_position_row < (idx - _main->_index + _main->ui.box_row_pos_size_top))){
				_main->ui.cursor_position_row += 1;
		}
	}
}

void cursor_move_position_up(Main* _main)
{
	if((idx < (_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 1)) || (idx > (_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 1))){
		if((_main->ui.cursor_position_row == (_main->ui.box_row_pos_size_top + 1)) && (_main->_index > 0)){
			_main->ui.cursor_position_row = _main->ui.box_row_pos_size_buttom - 1;
			_main->_index -= (_main->ui.box_row_pos_size_buttom - _main->ui.box_row_pos_size_top - 2);
		}
		if(_main->ui.explorer && (_main->ui.cursor_position_row > (_main->ui.box_row_pos_size_top + 1))){
			_main->ui.cursor_position_row -= 1;
		}
	}
}

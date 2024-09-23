#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <errno.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <time.h>
#include <pthread.h>

#define DIR_ON
#define UI_C_
#define MINIAUDIO_IMPLEMENTATION
#define AUDIO_C_

#include "./src/third_party/miniaudio.h"
#include "./src/log.h"
#include "./src/rdirectorys.h"
#include "./src/audio.h"
#include "./src/ui.h"

// TODO: add favorite albom and let user create new alboms
// TODO: search song on local device
// TODO: search over internet

/**
 * Main structure to hold audio, UI, and other relevant data.
 */
typedef struct {
	MP_Audio audio;
	UI	 ui;
	int _index ;
	char current_directory[256];
	Term term;
}Main;

/**
 * Updates the UI and audio state in a separate thread.
 * 
 * @param param A pointer to the Main structure.
 * @return NULL
 */
void* main_always_update(void*);

/**
 * Moves the cursor position down in the UI.
 * 
 * @param _main A pointer to the Main structure.
 */
void cursor_move_position_down(Main*);

/**
 * Moves the cursor position up in the UI.
 * 
 * @param _main A pointer to the Main structure.
 */
void cursor_move_position_up(Main*);

/**
 * Main function to initialize and run the music player.
 */
int main(void)
{
	bool quit = false;
	Term term;
	Main _main;
	_main.audio = MP_Init_Audio();
	_main.ui = UI_Window_Init(&_main.term);
	_main._index = 0;
	char ch;
	bool _ones = true;

	while(!quit)
	{
		_main.ui.Flush();
		_main.ui.volume = _main.audio.volume * 100;
		_main.ui.is_pause = _main.audio.is_audio_playing;
		UpdateCursor(&_main.audio);
		_main.ui.cursor = _main.audio.cursor;
		_main.ui.total_length = _main.audio.song_length;
		_main.ui.status = _main.audio.status;
		UI_Window_Update(&_main.ui);
		if(_ones){
			pthread_t thread;
			if( pthread_create(&thread , NULL , main_always_update , (void*)&_main) != 0)
			{
				is_error = thread_failed;
			}
			(void)thread;
			_ones = !_ones;
		}
		if(getcwd(_main.current_directory , 256) == NULL){
			is_error = errno ;
		}

		if(_main.ui.explorer && !_main.ui.help){
			Explorer(&_main.ui , _main.current_directory , _main._index);
		}

		ch = getchar();
		/*
		 *	keys : 
		 *		q     : for quit
		 *		u     : update ui (im gonna handle it later)
		 *		e     : open file explorer
		 *
		 *		d     : for moving to directory directly (NOT IMPLEMENTED) 
		 *		f     : add song to favorit
		 *		a     : open favorit albome
		 *		?     : show help list
		 *
		 *		SPACE : pause and play
		 *		+     : increase the volume
		 *		j     : move cursor down
		 *		k     : move cursor up
		 *		-     : reduce volume
		 *		>     : next
		 *		<     : prev
		 *		i     : change style window or switch to style window (file explorer enabled)
		 *		s     : search songs on locale device
		 *		S     : for search on internet
		 *		TAB 9 : change status
		 * */ 
		switch(ch){
			case 10 : {
				if(_main.ui.explorer){
					if(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].is_dir)
					{
						if(chdir(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].filename) < 0){
							is_error = errno;
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
				if(_main.audio.status == 2){
					_main.audio.status = 0;
				}else{
					_main.audio.status++;
				}
			}break;
			case '.' : {
			       _main.current_directory[strlen(_main.current_directory) - strlen(strrchr(_main.current_directory, '/')) + 1] = '\0';
				if(chdir(_main.current_directory) < 0){
					is_error = errno;
				}
				_main._index = 0;
				_main.ui.cursor_position_row = _main.ui.box_row_pos_size_top + 1;
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
						if(_main.audio.cursor < _main.audio.song_length)
							_main.audio.cursor += _main.audio.seek_time;
						SeekPosition(&_main.audio);
						MP_Update_Audio(&_main.audio , NULL);
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
				init_fav_albome();
				if(!__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].is_dir){
					add_song_to_fav_albome(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].filename , &quit);
				}
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
					if(_main.ui.explorer){
						do{
							cursor_move_position_down(&_main);
						}while(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].is_dir);
					}else{
						do{
							_main._index++;
						}while(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].is_dir);
					}
					MP_Update_Audio(&_main.audio , __dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].filename);
					PlayMusic(&_main.audio);
				}

			}break;
			case '<':{
				if(_main.ui.cursor_position_row > (_main.ui.box_row_pos_size_top)){
					if(_main.ui.explorer){
						do{
							cursor_move_position_up(&_main);
						}while(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].is_dir);
					}else{
						do{
							_main._index--;
						}while(__dirs[_main._index + _main.ui.cursor_position_row - _main.ui.box_row_pos_size_top - 1].is_dir);
					}
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
			case 'i':{
				if(_main.ui.style == 1)
					_main.ui.style = 0;
				else
					_main.ui.style++;
			}break;
			case 'a':{
				is_error = a_not_implemented;
			}break;
			case 's':{
				is_error = s_not_implemented;
			}break;
			case 'S':{
				is_error = S_not_implemented;
			}break;
			case '?':{
				if(_main.ui.help)
					_main.ui.help = false;
				else
					_main.ui.help = true;
			}break;
			case 'u' : {
				UI_Window_Update(&_main.ui);
			}break;
			case 'e' : {
				if(_main.ui.explorer){
					_main.ui.explorer = false;
				}else{
					_main.ui.explorer = true;
				}
			}break;
			case 'q' : {
				quit = true;
			}
		}
		_main.ui.Flush();
	}
	UI_Window_Final(&_main.term);
	MP_Final_Audio();
	return 0;
}

void* main_always_update(void* param)
{
	Main* _main = (Main*)param;
	while(true)
	{
		if(MusicAtEnd()){
			if(_main->ui.status == SINGLE_LOOP){
				_main->audio.cursor = 0;
				MP_Update_Audio(&_main->audio , __dirs[_main->_index + _main->ui.cursor_position_row - _main->ui.box_row_pos_size_top - 1].filename);
				PlayMusic(&_main->audio);
			}else if(_main->ui.status == PLAYLIST_LOOP){
				if(_main->ui.explorer){
					do{
						cursor_move_position_down(_main);
					}while(__dirs[_main->_index + _main->ui.cursor_position_row - _main->ui.box_row_pos_size_top - 1].is_dir);
				}else{
					do{
						_main->_index++;
					}while(__dirs[_main->_index + _main->ui.cursor_position_row - _main->ui.box_row_pos_size_top - 1].is_dir);
				}
				MP_Update_Audio(&_main->audio , __dirs[_main->_index + _main->ui.cursor_position_row - _main->ui.box_row_pos_size_top - 1].filename);
				PlayMusic(&_main->audio);
			}		
		}
		if(_main->ui.is_pause){
			UpdateCursor(&_main->audio);
			_main->ui.cursor = _main->audio.cursor;
		}
		UI_Window_Update(&_main->ui);
		if(_main->ui.explorer && !_main->ui.help){
			Explorer(&_main->ui , _main->current_directory , _main->_index);
		}
		if(is_error){
			Error_Box(GetError(is_error) , MESSAGE , NULL);
			is_error = 0;
		}
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

#ifndef  ERROR_H_
#define  ERROR_H_

//#include <stdbool.h>
//#include <string.h>

typedef enum{
	success = 0,
	// directory list failed
	list_dirs_f,
	f_not_implemented,
	p_not_implemented,
	plus_not_implemented,
	minus_not_implemented,
	n_not_implemented,
	N_not_implemented,
	i_not_implemented,
	a_not_implemented,
	s_not_implemented,
	S_not_implemented,
	quastion_not_implemented,
	// for audio
	init_audio_engine,
	init_audio_sound_from_file,
	get_cursor_pcm_frames,
	get_length_audio



}error_e;
char* GetError(error_e e);
error_e is_error = success;

#endif //ERROR_H_

char* GetError(error_e e){
	switch(e){
		case success : return NULL;
		case list_dirs_f : return "Could not list directory";
		case f_not_implemented : return "f key is not implemented";
		case p_not_implemented : return "p key is not implemented";
		case plus_not_implemented : return "+ key is not implemented";
		case minus_not_implemented : return "- key is not implemented";
		case n_not_implemented : return "n key is not implemented";
		case N_not_implemented : return "N key is not implemented";
		case i_not_implemented : return "i key is not implemented";
		case a_not_implemented : return "a key is not implemented";
		case s_not_implemented : return "s key is not implemented";
		case S_not_implemented : return "S key is not implemented";
		case quastion_not_implemented : return "? key is not implemented";
		case init_audio_engine : return "Failed to init engine";
		case init_audio_sound_from_file : return "Failed to init sound from file (is not song)";
		case get_cursor_pcm_frames : return "Failed to get cursor position";
		case get_length_audio : return "Failed to get song length";
		default : return strerror(is_error);
	}
}


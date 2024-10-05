#ifndef  ERROR_H_
#define  ERROR_H_

typedef enum{
	success = 0,
	// directory list failed
	list_dirs_f,
	f_not_implemented,
	p_not_implemented,
	plus_not_implemented,
	minus_not_implemented,
	i_not_implemented,
	a_not_implemented,
	s_not_implemented,
	S_not_implemented,
	quastion_not_implemented,
	// for audio
	init_audio_engine,
	init_audio_sound_from_file,
	get_cursor_pcm_frames,
	get_length_audio,
	// thread
	thread_failed,
	// favorite albome
	failed_init_fav_albome,
	failed_to_load_fav_albome,
	// engines
	engine_load_file_e,
	engine_failed,
	engine_load_code

}error_e;

typedef enum{
	_ERROR,
	NOTE ,
	MESSAGE
}Log;

char* GetError(error_e e);
extern void Error_Box(char* , Log , bool*);
error_e is_error = success;

#endif //ERROR_H_

char* GetError(error_e e){
	switch(e){
		case success : return NULL;
		case list_dirs_f : return "Could not list directory";
		case thread_failed : return "failed to create thread !";
		case failed_to_load_fav_albome : return "failed to load favorite albome";
		case failed_init_fav_albome : return "failed to init favorite albome";
		case f_not_implemented : return "f key is not implemented";
		case p_not_implemented : return "p key is not implemented";
		case plus_not_implemented : return "+ key is not implemented";
		case minus_not_implemented : return "- key is not implemented";
		case i_not_implemented : return "i key is not implemented";
		case a_not_implemented : return "a key is not implemented";
		case s_not_implemented : return "s key is not implemented";
		case S_not_implemented : return "S key is not implemented";
		case quastion_not_implemented : return "? key is not implemented";
		case init_audio_engine : return "Failed to init engine";
		case init_audio_sound_from_file : return "Failed to init sound from file (is not song)";
		case get_cursor_pcm_frames : return "Failed to get cursor position";
		case get_length_audio : return "Failed to get song length";
		case engine_load_file_e : return "Failed Engine to load file extension <run default script>";
		case engine_failed : return "Failed Engine <critical>";
		case engine_load_code : return "Failed to load lua code <access value nil>";
		default : return strerror(is_error);
	}
}


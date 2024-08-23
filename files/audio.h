#ifndef AUDIO_H_
#define AUDIO_H_

//#include <stdlib.h>
//#include "./error.h"
//#include "./ui.h"
//#include "./third_party/miniaudio.h"

#define MP_Engine	ma_engine
#define MP_Sound	ma_sound
#define MP_MALLOC	malloc
#define MP_FREE		free
#define MP_UINT64	unsigned long long

MP_Engine engine;	// engine from miniaudio
MP_Sound sound;	// sound from miniaudio

typedef struct {
	float volume;		// volume from 0.0 to 1.0 | 0.5 default
	float seek_time;		// time to move 
				// seek_time edited by user to change position
	float cursor;	// getting cursor position 
				// will updated every minute 
	float song_length;	// this contain total music length
	bool is_audio_playing ; // true if audio playing else false
}MP_Audio;

extern MP_Audio MP_Init_Audio(void);
extern void MP_Update_Audio(MP_Audio* ,char*);
extern void MP_Final_Audio(MP_Audio*);

void PlayMusic		(MP_Audio* audio);
void StopMusic		(MP_Audio* audio);
void SetVolume		(MP_Audio* audio);
void SeekPosition	(MP_Audio* audio);

#endif // AUDIO_H_

#ifdef AUDIO_C_

MP_Audio MP_Init_Audio()
{
	MP_Audio audio;
	if((ma_engine_init(NULL , &engine)) != MA_SUCCESS){
		is_error = init_audio_engine;
		Error_Box(GetError(is_error));
	}
	audio.volume = 0.5;
	audio.seek_time = 5; // five minute seek
	audio.is_audio_playing = false;
	return audio;
}

void MP_Update_Audio(MP_Audio* audio,char* filename)
{
	if(filename != NULL){
		ma_sound_uninit(&sound);
		if(ma_sound_init_from_file(&engine , filename , 0 , NULL , NULL , &sound) != MA_SUCCESS)
		{
			is_error = init_audio_sound_from_file;
			Error_Box(GetError(is_error));
			ma_engine_uninit(&engine);
		}
		if(audio->is_audio_playing)
			StopMusic(audio);
	}
	SetVolume(audio);
	ma_sound_get_length_in_seconds(&sound, &(audio->song_length));
	ma_sound_get_cursor_in_seconds(&sound , &(audio->cursor));
}
void MP_Final_Audio(MP_Audio* audio)
{
	ma_sound_uninit(&sound);
	ma_engine_uninit(&engine);
}

void PlayMusic(MP_Audio* audio)
{
	if(!audio->is_audio_playing){
		audio->is_audio_playing = true;
		ma_sound_start(&sound);
	}
}
void StopMusic(MP_Audio* audio)
{
	if(audio->is_audio_playing){
		audio->is_audio_playing = false;
		ma_sound_stop(&sound);
	}
}
void SetVolume(MP_Audio* audio)
{
	ma_sound_set_volume(&sound, audio->volume);
}
void SeekPosition(MP_Audio* audio)
{
	ma_sound_seek_to_pcm_frame(&sound, (MP_UINT64)(audio->seek_time * engine.sampleRate));
}
#endif // AUDIO_C_

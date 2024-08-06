#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <unistd.h>


#define DIR_ON
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

// TODO: create file explorer
// TODO: handle songs
// TODO: handle keys
// TODO: UI  
// TODO: pause , run , next , volume
// TODO: search over internet


int main(void)
{
	// TODO: testing

	printf("Hello World");
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

	return 0;
}

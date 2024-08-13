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

//#include "./files/rdirectorys.h"
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
	bool explorer = false;
	Term term;
	UI ui = UI_Window_Init(&term);
	char ch;
	while(!quit)
	{
		if(explorer){
			DrawBox(ui , NULL);
			Explorer(&ui , NULL);
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
			case 'f':{
				Error_Box(" f key is not implemented ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'j':{
				Error_Box(" j key is not implemented , check if explorer is true ");
				ui.Flush();
				sleep(3);
				quit = true;
			}break;
			case 'k' : {
				Error_Box(" k key is not implemented , check if explorer is true");
				ui.Flush();
				sleep(3);
				quit = true;
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
				UI_Window_Update(&ui , explorer);
			}break;
			case 'e' : {
				if(explorer)
					explorer = false;
				else
					explorer = true;
				ui.explorer = explorer;
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

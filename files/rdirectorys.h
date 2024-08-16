#ifndef RDIR_H_
#define RDIR_H_

typedef int 		Err	;
typedef struct dirent 	Dirent	;

#define MAX_FILE 10

#ifndef BOOL_ON
#include <stdbool.h>
#else
typedef enum{
	false = 0,
	true = !false,
}bool;
#endif

typedef enum {
	B ,
	KB,
	MB,
	GB,
	TB
}Block;
// this linked list contains file information  
typedef struct directory {
	char 	filename[256]	; 	// file name max length 256
	size_t 	file_size	; 	// file size
	int 	file_idx	; 	// file index 
	bool 	is_dir		;	// true if it's directory
	bool	the_last	;
}Directoy;

int idx = 1;
Directoy __dirs[200];

void Init_Dir(void);
void List_Dir(const char*);
void Dump_files(void);

#endif //RDIR_H_

#ifdef    DIR_ON
#define   DIR_ON

#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/types.h>
#include <errno.h>
#include <string.h>

#include "error.h"

char fmt[100];

static size_t get_file_size(char* filename);
static char* handle_size(size_t byte_size);

void Init_Dir(void)
{
	idx = 1;
	strcpy(__dirs[0].filename , "..");
	__dirs[0].file_size = 0;
	__dirs[0].file_idx = 0;
	__dirs[0].is_dir = true;
	__dirs[0].the_last = false;
}

void List_Dir(const char* dirname){
	if(dirname == NULL)	return;
        DIR *dir = opendir(dirname);
	if(dir == NULL){
		is_error = errno;
		return ;
	}
	errno = 0;
	Dirent* rdir= readdir(dir);
	while(rdir != NULL){
		if (strcmp(rdir->d_name, ".") == 0 || strcmp(rdir->d_name, "..") == 0 || strcmp(rdir->d_name, ".git") == 0) {
			rdir = readdir(dir);
			continue;
		}
		switch(rdir->d_type){
			case DT_REG : {
                		sprintf(__dirs[idx].filename, "%s/%s", dirname, rdir->d_name);
				__dirs[idx].file_size = get_file_size(rdir->d_name);
				__dirs[idx].is_dir = false;
				__dirs[idx].file_idx = idx;
			}break;
			case DT_DIR : {
                		sprintf(__dirs[idx].filename,"%s/%s", dirname, rdir->d_name);
				__dirs[idx].file_size = 0;
				__dirs[idx].is_dir = true;
				__dirs[idx].file_idx = idx;
			}
		}
		idx++;
		rdir = readdir(dir);
	}

	if(errno != 0){
		if(dir)	
			closedir(dir);

		return;
	}
	closedir(dir);
	__dirs[idx].the_last = true;
	return;
}

void Dump_files(void){
	for(int e = 0 ; e < idx ; e++){
		printf("%d - %s\t:%zu\t:%s\n" ,__dirs[e].file_idx ,__dirs[e].filename , __dirs[e].file_size , __dirs[e].is_dir ? "(dir)" : "(file)");
	}
}

static size_t get_file_size(char* filename){
	size_t size = -1;
	FILE* filep;
	if((filep = fopen(filename , "r")) == NULL){
		return size;
	}
        fseek(filep, 0, SEEK_END);
	size = ftell(filep);
        rewind(filep);
	fclose(filep);
	return size;
}	

static char* handle_size(size_t byte_size){
	Block block = B;
	while((byte_size / 1024) != 0){		
		byte_size /= 1024;
		block++;
	};
	switch(block){
		case B :{
			sprintf(fmt , "%zu B" , byte_size);
		}break;
		case KB :{
			sprintf(fmt , "%zu KB" , byte_size);
		}break;
		case MB :{
			sprintf(fmt , "%zu MB" , byte_size);
		}break;
		case GB :{
			sprintf(fmt , "%zu GB" , byte_size);
		}break;
		case TB :{
			sprintf(fmt , "%zu TB" , byte_size);
		}break;
	}
	return fmt;
}

#endif // DIR_ON

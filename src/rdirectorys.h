/*
 *	RMP (Ray Music Player) , rdirectorys.h part of raymp repo
 *	this file handle listing directory's , type of attr and size
 * */

#ifndef RDIR_H_
#define RDIR_H_

#include "config/list.h"

typedef struct dirent 	RMPDirent;

#define MAX_FILE 10

typedef enum {
	B ,
	KB,
	MB,
	GB,
	TB
}Block;

typedef struct directory {
	char 	filename[256]	; 	// file name max length 256
	size_t 	file_size	; 	// file size
	bool 	is_dir		;	// true if it's directory
}Directoy;

void InitDir(RLList);
void ListDir(const char*,RLList);

#endif //RDIR_H_

#ifdef    DIR_ON

char fmt[100];
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
	if(byte_size == 0)	return "0 B";
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

static bool is_file_extension(const char *fileName, const char *ext)
{
    bool result = false;
    const char *fileExt;

    if ((fileExt = strrchr(fileName, '.')) != NULL)
    {
        if (strcmp(fileExt, ext) == 0) result = true;
    }

    return result;
}

void InitDir(RLList list)
{
	RLSetObject(DIRECTORY);
	list.List_Clear();
}

void ListDir(const char* dirname , RLList list){
	RLSetObject(DIRECTORY);
	if(dirname == NULL)	return;
        DIR *dir = opendir(dirname);
	if(dir == NULL){
		is_error = errno;
		return ;
	}
	errno = 0;
	RMPDirent* rdir= readdir(dir);
	Directoy dirs = {0};
	RLCopyObject(sizeof(Directoy));
	while(rdir != NULL){
#ifdef _WIN32

                sprintf(dirs.filename, "%s/%s", dirname, rdir->d_name);
		dirs.file_size = get_file_size(rdir->d_name);
		DWORD result = GetFileAttributes(rdir->d_name);
		if(result == INVALID_FILE_ATTRIBUTES || !(result & FILE_ATTRIBUTE_DIRECTORY))
		{
			dirs.is_dir = false;
		}else{
			dirs.is_dir = true;
		}
#else
		switch(rdir->d_type){
			case DT_REG : {
                		sprintf(dirs.filename, "%s/%s", dirname, rdir->d_name);
				dirs.file_size = get_file_size(rdir->d_name);
				dirs.is_dir = false;
			}break;
			case DT_DIR : {
                		sprintf(dirs.filename,"%s/%s", dirname, rdir->d_name);
				dirs.file_size = 0;
				dirs.is_dir = true;
			}
		}
#endif
		list.List_Append(RL_VOIDPTR , (void*)&dirs);
		rdir = readdir(dir);
	}
	RLDisableCopyObject();

	if(errno != 0){
		if(dir)	
			closedir(dir);

		return;
	}
	closedir(dir);
	return;
}

#endif // DIR_ON

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

typedef struct directory {
	char 	filename[256]	; 	// file name max length 256
	size_t 	file_size	; 	// file size
	int 	file_idx	; 	// file index 
	bool 	is_dir		;	// true if it's directory
	bool	the_last	;
}Directoy;

#define MAX_LEN_DIRS	200

int idx;
Directoy __dirs[MAX_LEN_DIRS];

void Init_Dir(void);
void List_Dir(const char*);
// used for debuging
void Dump_files(void);
char* handle_size(size_t byte_size);


#endif //RDIR_H_

#ifdef    DIR_ON
#define   DIR_ON

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
char* handle_size(size_t byte_size){
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

	

void Init_Dir(void)
{
	for(int i = 0 ; i < MAX_LEN_DIRS ; i++)
	{
		__dirs[i].filename[0] = '\0';
	}
	memset(__dirs , 0 , MAX_LEN_DIRS * sizeof(Directoy));
	idx = 0;
	//strcpy(__dirs[0].filename , "./..");
	//__dirs[0].file_size = 0;
	//__dirs[0].file_idx = 0;
	//__dirs[0].is_dir = true;
	//__dirs[0].the_last = false;
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
		switch(rdir->d_type){
			case DT_REG : {
                		sprintf(__dirs[idx].filename, "%s/%s", dirname, rdir->d_name);
				__dirs[idx].file_size = get_file_size(rdir->d_name);
				__dirs[idx].is_dir = false;
				__dirs[idx].file_idx = idx;
			}break;
			case DT_DIR : {
				if(
					strcmp(rdir->d_name, ".") == 0  		//|| 
					//strcmp(rdir->d_name, "..") == 0 		

				)
				{
					rdir = readdir(dir);
					continue;
				}
                		sprintf(__dirs[idx].filename,"%s/%s", dirname, rdir->d_name);
				__dirs[idx].file_size = 0;
				__dirs[idx].is_dir = true;
				__dirs[idx].file_idx = idx;
			}
		}
		++idx;
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

void Dump_files(void)
{
	for(int i = 0 ; i < idx ; i++)
	{
		printf("\n%s" , __dirs[i].filename);
	}
}

#endif // DIR_ON

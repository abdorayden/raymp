// TODO: fix the api


#include "flags.h"
#include <stdio.h>

#define LIST_C
#include "src/third_party/raylist.h"

static RLList list;

bool is_flag_set_it(const char* const flag , int argc , char** argv){
	for(int i = 0 ; i < argc ; i++){
		if(strcmp(flag , argv[i]) == 0)	return true;
	}
	return false;
}

void flag_load(char** args , char** msg){
	RLCopyObject(sizeof(Flag));
	for(;*args || *msg ; args++ , msg++){
		Flag flag = {.flag = *args , .msg = *msg };
		list.Append(RL_VOIDPTR , (void*)&flag);
	}
	RLDisableCopyObject();
}

void print_help(char* filename){
	if(list.Len() == 0){
		fprintf(stderr , "No flags are loaded or initialized");
		return ;
	}

	printf("%s -h\n" , filename);
	RLForEach(result , list){
		Flag flag = *(Flag*)result.GetData();
		printf("   - %s : %s\n" ,  flag.flag, flag.msg);
	}
}

void flag_error(char* filename , const char* const error_msg){
	fprintf(stderr , "[ERROR] %s" , error_msg);
	print_help(filename);
}

bool check_flag(char* flag){
	if(list.Len() == 0){
		return false;
	}
	RLForEach(result , list){
		if(strcmp(((Flag*)result.GetData())->flag , flag) == 0){
			return true;
		}
	}
	return false;
}

bool check_all(int argc , char** argv){
	for(int i = 1 ; i < argc ; i++){
		if(!check_flag(argv[i])){
			return false;
		}
	}
	return true;
}

void flag_clean(void){
	list.Clear();
}


















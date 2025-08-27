#ifndef FLAGS_H_
#define FLAGS_H_

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

typedef struct {
	char* flag;
	char* msg;
}Flag;

bool is_flag_set_it(const char* const flag , int argc , char** argv);
void flag_load(char** args , char** msg);
void flag_error(char* filename , const char* const error_msg);
bool check_flag(char* flag);
bool check_all(int argc , char** argv);
void flag_clean(void);

// len(args) == len(msg)
void print_help(char* filename);

#endif //FLAGS_H_

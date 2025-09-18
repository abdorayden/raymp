#include <runner.h>
#include "lua.h"
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

void print_help(char* progname)
{
	printf("Usage: %s [COMMAND] [OPTIONS]\n", progname);
	printf("Command:\n");
	printf("  help        		Show this help message\n");
	printf("  init 		       	create plugin architecture directory , with evirement developement\n");
	printf("  test	        	create empty window , used to test your plugin \n");
	printf("Options:\n");
	printf("  --help 	, -h    Show this help message\n");
	printf("  --version 	, -v    Show RMP Version\n");
}

char* shift_args(int argc , char** argv)
{
	if(argc <= 1) {
		return NULL;
	}

	static int index = 0;

	if(index >= argc) {
		return NULL;
	}

	return argv[index++];
}

// TODO: rewrite RMPManger engine in C
int main(int argc , char** argv)
{

	// no arguments mean run the program
	char* program = shift_args(argc , argv);
	if(program == NULL) {
		// unreachable
	}

	for(int i = 0 ; i < argc ; i++){
		if(
				strcmp(argv[i] , "--help") == 0 || 
				strcmp(argv[i] , "-h") == 0 ||
				strcmp(argv[i] , "/?") == 0 ||
				strcmp(argv[i] , "-help") == 0 ||
				strcmp(argv[i] , "/help") == 0 ||
				strcmp(argv[i] , "help") == 0
		  ){
			print_help(argv[0]);
			return 0;
		}
	}

	char* command = shift_args(argc - 1 , argv);
	if(command != NULL) {
		if(strcmp(command , "help") == 0) {
			print_help(argv[0]);
			return 0;
		} else if(strcmp(command , "init") == 0) {
			printf("Init command called\n");
		} else if(strcmp(command , "test") == 0) {
			printf("Test command called\n");
		}
	}


	// for test
	/* RMPRunner engine = RMPRunnerInit("./src/engine/plugins/music_waves.lua"); */
	/* RMPRunner engine = RMPRunnerInit("plugins/main.lua"); */
	/* RMPRunner engine = RMPRunnerInit("./src/engine/selfrmp/themes/rmpv1.lua"); */
	/* RMPRunner engine = RMPRunnerInit("./src/engine/plugins/rmplikemp3.lua"); */
	/* RMPRunner engine = RMPRunnerInit("plugins/test.lua"); */

	RMPRunner engine = RMPRunnerInit("./src/engine/RMPManager.lua");
	RMPRunnerError status = RMPRunnerRun(engine);
	if(status != RMP_FINE)
	{
		fprintf(stderr , "[LOG] error %s" , error);
	}
	RMPRunnerClose(&engine);
}

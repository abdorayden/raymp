#include <runner.h>
#include "lua.h"
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include "flags.h"

char* flags[] = {
	"--test" , "--load" , NULL
};

char* msgs[] = {
	"test plugin or theme" , "load lua file" , NULL
};

int main(int argc , char** argv)
{

	// API is not working
	/* flag_load(flags , msgs); */

	/* if(!check_all(argc , argv)){ */
	/* 	flag_error(argv[0] , "did you set unknown flag ?"); */
	/* } */

	/* flag_clean(); */

	/* if(is_flag_set_it("--help" , argc , argv)){ */
	/* 	print_help(argv[0] , flags , msgs); */
	/* } */

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

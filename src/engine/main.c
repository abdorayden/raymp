#include "./engine.h"
#include <lua5.4/lua.h>

int main(void)
{
	/* RMPEngine engine = RMPEngineInit("plugins/music_waves.lua"); */
	/* RMPEngine engine = RMPEngineInit("plugins/main.lua"); */
	/* RMPEngine engine = RMPEngineInit("themes/rmpv1.lua"); */
	RMPEngine engine = RMPEngineInit("plugins/rmplikemp3.lua");
	/* RMPEngine engine = RMPEngineInit("plugins/test.lua"); */

	RMPEngineError status = RMPEngineRun(engine);
	if(status != RMP_FINE)
	{
		fprintf(stderr , "[LOG] error %s" , error);
	}
	RMPEngineClose(&engine);
}

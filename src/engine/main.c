#include "./engine.h"

int main(void)
{

	/* RMPEngine engine = RMPEngineInit("plugins/music_waves.lua"); */
	/* RMPEngine engine = RMPEngineInit("plugins/main.lua"); */
	RMPEngine engine = RMPEngineInit("themes/rmpv1.lua");

	RMPEngineError status = RMPEngineRun(engine);
	if(status != RMP_FINE)
	{
		fprintf(stderr , "error");
	}
	RMPEngineClose(&engine);
}

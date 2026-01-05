#include "../include/rmp_sleep.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

void rmp_sleep(int milliseconds)
{
#ifdef _WIN32
    Sleep(milliseconds);
#else
    usleep(milliseconds * 1000);
#endif
}
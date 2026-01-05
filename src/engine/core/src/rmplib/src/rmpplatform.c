#include "../include/rmp_platform.h"

rmp_platform_t rmp_get_platform(void) {
#ifdef 	_WIN32
	return RMP_PLATFORM_WINDOWS;
#elif	__linux__
	return RMP_PLATFORM_LINUX;
#elif	__APPLE__
	return RMP_PLATFORM_MAC;
#else
	return RMP_PLATFORM_UNKNOWN;
#endif
}
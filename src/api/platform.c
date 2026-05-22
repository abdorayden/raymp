#include "platform.h"

bool rmp_platform(RDNApi *api) {
#ifdef _WIN32
    api->push_integer(api, RMP_PLATFORM_WINDOWS);
#elif __linux__
    api->push_integer(api, RMP_PLATFORM_LINUX);
#elif __APPLE__
    api->push_integer(api, RMP_PLATFORM_MAC);
#else
    api->push_integer(api, RMP_PLATFORM_UNKNOWN);
#endif

    return true;
}

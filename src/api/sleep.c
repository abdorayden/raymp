#ifndef _WIN32
#define _DEFAULT_SOURCE
#endif

#include "sleep.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <sys/select.h>
#endif

static void rmp_platform_sleep(long milliseconds) {
#ifdef _WIN32
    Sleep((DWORD)milliseconds);
#else
    struct timeval tv;
    tv.tv_sec = milliseconds / 1000;
    tv.tv_usec = (milliseconds % 1000) * 1000;
    select(0, NULL, NULL, NULL, &tv);
#endif
}

bool rmp_sleep(RDNApi *api) {
    long milliseconds = 0;
    double milliseconds_number = 0;

    if (api->to_integer(api, -1, &milliseconds)) {
        api->pop(api, 1);
    } else if (api->to_number(api, -1, &milliseconds_number)) {
        api->pop(api, 1);
        milliseconds = (long)milliseconds_number;
    } else {
        return api->raise_error(api, "rmp_sleep expects a numeric milliseconds value");
    }

    if (milliseconds < 0) {
        return api->raise_error(api, "rmp_sleep expects a non-negative value");
    }

    rmp_platform_sleep(milliseconds);
    api->push_boolean(api, true);
    return true;
}

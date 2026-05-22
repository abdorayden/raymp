#ifndef RMP_PLATFORM_H
#define RMP_PLATFORM_H

#include "../third_party/rdn/rdn_native.h"

enum {
    RMP_PLATFORM_LINUX,
    RMP_PLATFORM_WINDOWS,
    RMP_PLATFORM_MAC,
    RMP_PLATFORM_UNKNOWN
};

bool rmp_platform(RDNApi *api);

#endif

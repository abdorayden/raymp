#ifndef RMP_PLATFORM_H_
#define RMP_PLATFORM_H_

// Platform API functions

typedef enum {
    RMP_PLATFORM_LINUX,
    RMP_PLATFORM_WINDOWS,
    RMP_PLATFORM_MAC,
    RMP_PLATFORM_UNKNOWN
} rmp_platform_t;

/**
 * Get the current platform
 * @return: platform identifier
 */
rmp_platform_t rmp_get_platform(void);

#endif // RMP_PLATFORM_H_
#include "directory.h"

#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef _WIN32
#include <dirent.h>
#include <pwd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#define RMP_GETCWD getcwd
#else
#include <direct.h>
#include <windows.h>
#define RMP_GETCWD _getcwd
#define mkdir(path, mode) _mkdir(path)
#define rmdir(path) _rmdir(path)
#endif

static bool push_entry(RDNApi *api, const char *name, bool is_file) {
    if (!api->push_list(api)) {
        return false;
    }
    if (!api->push_string(api, name)) {
        return false;
    }
    if (!api->list_append(api, -2, -1) || !api->pop(api, 1)) {
        return false;
    }
    if (!api->push_boolean(api, is_file)) {
        return false;
    }
    if (!api->list_append(api, -2, -1) || !api->pop(api, 1)) {
        return false;
    }
    return true;
}

bool rmp_get_current_path(RDNApi *api) {
    char current_path[1024];

    if (RMP_GETCWD(current_path, sizeof(current_path)) == NULL) {
        api->push_null(api);
        return true;
    }

    api->push_string(api, current_path);
    return true;
}

bool rmp_home_path(RDNApi *api) {
    const char *home_path = NULL;

#ifdef _WIN32
    home_path = getenv("USERPROFILE");
    if (home_path == NULL) {
        const char *home_drive = getenv("HOMEDRIVE");
        const char *home_suffix = getenv("HOMEPATH");
        char *joined = NULL;
        size_t length = 0;

        if (home_drive != NULL && home_suffix != NULL) {
            length = strlen(home_drive) + strlen(home_suffix) + 1;
            joined = malloc(length);
            if (joined == NULL) {
                return api->raise_error(api, "failed to allocate home path");
            }
            memcpy(joined, home_drive, strlen(home_drive));
            strcpy(joined + strlen(home_drive), home_suffix);
            api->push_string(api, joined);
            free(joined);
            return true;
        }
    }
#else
    home_path = getenv("HOME");
    if (home_path == NULL) {
        struct passwd *pwd = getpwuid(getuid());
        if (pwd != NULL) {
            home_path = pwd->pw_dir;
        }
    }
#endif

    if (home_path == NULL) {
        api->push_null(api);
        return true;
    }

    api->push_string(api, home_path);
    return true;
}

bool rmp_list_dir(RDNApi *api) {
    const char *dir_path = api->to_string(api, -1);
    char *dir_path_copy = NULL;

    if (dir_path == NULL) {
        return api->raise_error(api, "rmp_list_dir expects a string path");
    }

    dir_path_copy = copy_string(dir_path);
    if (dir_path_copy == NULL) {
        return api->raise_error(api, "failed to allocate directory path");
    }

    api->pop(api, 1);

    if (!api->push_list(api)) {
        free(dir_path_copy);
        return false;
    }

#ifdef _WIN32
    WIN32_FIND_DATAA find_data;
    HANDLE handle = INVALID_HANDLE_VALUE;
    char search_path[MAX_PATH];
    char full_path[MAX_PATH];

    snprintf(search_path, sizeof(search_path), "%s\\*", dir_path_copy);
    handle = FindFirstFileA(search_path, &find_data);
    if (handle == INVALID_HANDLE_VALUE) {
        api->pop(api, 1);
        api->push_null(api);
        api->push_string(api, "cannot open directory");
        return true;
    }

    do {
        DWORD attrs = 0;
        bool is_file = false;

        if (strcmp(find_data.cFileName, ".") == 0 || strcmp(find_data.cFileName, "..") == 0) {
            continue;
        }

        snprintf(full_path, sizeof(full_path), "%s\\%s", dir_path_copy, find_data.cFileName);
        attrs = GetFileAttributesA(full_path);
        is_file = attrs != INVALID_FILE_ATTRIBUTES && !(attrs & FILE_ATTRIBUTE_DIRECTORY);

        if (!push_entry(api, find_data.cFileName, is_file)) {
            FindClose(handle);
            free(dir_path_copy);
            return false;
        }
        if (!api->list_append(api, -2, -1) || !api->pop(api, 1)) {
            FindClose(handle);
            free(dir_path_copy);
            return false;
        }
    } while (FindNextFileA(handle, &find_data) != 0);

    FindClose(handle);
#else
    DIR *dir = opendir(dir_path_copy);
    struct dirent *entry = NULL;
    char full_path[1024];

    if (dir == NULL) {
        api->pop(api, 1);
        api->push_null(api);
        api->push_string(api, "cannot open directory");
        return true;
    }

    while ((entry = readdir(dir)) != NULL) {
        bool is_file = true;

        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

#ifdef DT_DIR
        if (entry->d_type == DT_DIR) {
            is_file = false;
        } else if (entry->d_type == DT_UNKNOWN) {
#endif
            struct stat st;
            snprintf(full_path, sizeof(full_path), "%s/%s", dir_path_copy, entry->d_name);
            if (stat(full_path, &st) == 0) {
                is_file = S_ISREG(st.st_mode);
            }
#ifdef DT_DIR
        }
#endif

        if (!push_entry(api, entry->d_name, is_file)) {
            closedir(dir);
            free(dir_path_copy);
            return false;
        }
        if (!api->list_append(api, -2, -1) || !api->pop(api, 1)) {
            closedir(dir);
            free(dir_path_copy);
            return false;
        }
    }

    closedir(dir);
#endif

    api->push_null(api);
    free(dir_path_copy);
    return true;
}

bool rmp_mkdir(RDNApi *api) {
    const char *dir_path = api->to_string(api, -2);
    long mode = 0755;
    char *dir_path_copy = NULL;

    if (dir_path == NULL) {
        return api->raise_error(api, "rmp_mkdir expects a string path");
    }

    api->to_integer(api, -1, &mode);
    dir_path_copy = copy_string(dir_path);
    if (dir_path_copy == NULL) {
        return api->raise_error(api, "failed to allocate mkdir path");
    }
    api->pop(api, 2);

    if (mkdir(dir_path_copy, (int)mode) == 0) {
        free(dir_path_copy);
        api->push_boolean(api, true);
        api->push_null(api);
        return true;
    }

    free(dir_path_copy);
    api->push_boolean(api, false);
    api->push_string(api, strerror(errno));
    return true;
}

bool rmp_rmdir(RDNApi *api) {
    const char *dir_path = api->to_string(api, -1);
    char *dir_path_copy = NULL;

    if (dir_path == NULL) {
        return api->raise_error(api, "rmp_rmdir expects a string path");
    }

    dir_path_copy = copy_string(dir_path);
    if (dir_path_copy == NULL) {
        return api->raise_error(api, "failed to allocate rmdir path");
    }
    api->pop(api, 1);

    if (rmdir(dir_path_copy) == 0) {
        free(dir_path_copy);
        api->push_boolean(api, true);
        api->push_null(api);
        return true;
    }

    free(dir_path_copy);
    api->push_boolean(api, false);
    api->push_string(api, strerror(errno));
    return true;
}

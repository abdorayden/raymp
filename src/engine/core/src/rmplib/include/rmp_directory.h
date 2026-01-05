#ifndef RMP_DIRECTORY_H_
#define RMP_DIRECTORY_H_

#include <stdbool.h>

// Directory API functions

/**
 * Get the current working directory path
 * @return: allocated string containing the current path, or NULL on error
 */
char* rmp_get_current_path(void);

/**
 * Get the user's home directory path
 * @return: allocated string containing the home path, or NULL on error
 */
char* rmp_home_path(void);

/**
 * List directory contents
 * @param dir_path: path to the directory to list
 * @param[out] count: number of entries returned
 * @return: array of structures containing file info, or NULL on error
 */
typedef struct {
    bool is_file;
    char* name;
} rmp_dir_entry_t;

rmp_dir_entry_t* rmp_list_dir(const char* dir_path, int* count);

/**
 * Create a directory
 * @param dir_path: path of directory to create
 * @param mode: permissions (POSIX) or ignored (Windows)
 * @return: true on success, false on failure
 */
bool rmp_mkdir(const char* dir_path, int mode);

/**
 * Remove a directory
 * @param dir_path: path of directory to remove
 * @return: true on success, false on failure
 */
bool rmp_rmdir(const char* dir_path);

/**
 * Free the memory allocated by rmp_list_dir
 * @param entries: array returned by rmp_list_dir
 * @param count: number of entries in the array
 */
void rmp_free_dir_entries(rmp_dir_entry_t* entries, int count);

#endif // RMP_DIRECTORY_H_
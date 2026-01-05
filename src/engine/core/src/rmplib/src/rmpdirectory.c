#include <stdlib.h> // getenv
#include <errno.h>
#include <string.h>

#include "../include/rmp_directory.h"

#ifndef _WIN32
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <unistd.h>
#include <pwd.h> // if home is not set
#define rmp_api_cwd getcwd
#else
#include <windows.h>
#include <direct.h>
#include <tchar.h>
#define rmp_api_cwd _getcwd
#define mkdir(path , mode) _mkdir(path)
#endif

char* rmp_get_current_path(void) {
#define SIZE	1024
	char current_path[SIZE];
	if(rmp_api_cwd(current_path , SIZE) == NULL){
		return NULL;
	}else{
		char* result = malloc(strlen(current_path) + 1);
		if (result) {
			strcpy(result, current_path);
		}
		return result;
	}
#undef SIZE
}

char* rmp_home_path(void) {
#ifdef 	_WIN32
	char* home_path = getenv("USERPROFILE");
	if(home_path != NULL){
		char* result = malloc(strlen(home_path) + 1);
		if (result) {
			strcpy(result, home_path);
		}
		return result;
	}else{	// USERPROFILE is not set
		char* home_drive = getenv("HOMEDRIVE");
		char* home_path_suffix = getenv("HOMEPATH");
		if (home_drive != NULL && home_path_suffix != NULL) {
			home_path = malloc(strlen(home_drive) + strlen(home_path_suffix) + 1);
			strcpy(home_path, home_drive);
			strcat(home_path, home_path_suffix);
			char* result = malloc(strlen(home_path) + 1);
			if (result) {
				strcpy(result, home_path);
			}
			free(home_path); // Free temporary allocation
			return result;
		}else{
			return NULL;
		}
	}
#else
	char* home_path = getenv("HOME");

	if(home_path != NULL){
		char* result = malloc(strlen(home_path) + 1);
		if (result) {
			strcpy(result, home_path);
		}
		return result;
	}else{	// HOME is not set
		struct passwd* pwd = getpwuid(getuid());
		if(pwd != NULL){
			home_path = pwd->pw_dir;
			char* result = malloc(strlen(home_path) + 1);
			if (result) {
				strcpy(result, home_path);
			}
			return result;
		}else{
			return NULL;
		}
	}
#endif
}

rmp_dir_entry_t* rmp_list_dir(const char* dir_path, int* count) {
	if (!dir_path || !count) {
		return NULL;
	}

	*count = 0;

#ifdef 	_WIN32
	WIN32_FIND_DATA findFileData;
	HANDLE hFind;
	char searchPath[MAX_PATH];
	char fullPath[MAX_PATH];
	DWORD fileAttributes;

	snprintf(searchPath, sizeof(searchPath), "%s\\*", dir_path);
	hFind = FindFirstFile(searchPath, &findFileData);
	if (hFind == INVALID_HANDLE_VALUE) {
		return NULL;
	}

	// Count entries first
	int temp_count = 0;
	do {
		if (strcmp(findFileData.cFileName, ".") != 0 && strcmp(findFileData.cFileName, "..") != 0) {
			temp_count++;
		}
	} while(FindNextFile(hFind, &findFileData) != 0);

	// Reset and read again
	FindClose(hFind);
	hFind = FindFirstFile(searchPath, &findFileData);
	if (hFind == INVALID_HANDLE_VALUE) {
		return NULL;
	}

	rmp_dir_entry_t* entries = malloc(temp_count * sizeof(rmp_dir_entry_t));
	if (!entries) {
		FindClose(hFind);
		return NULL;
	}

	int idx = 0;
	do {
		if (strcmp(findFileData.cFileName, ".") == 0 || strcmp(findFileData.cFileName, "..") == 0) {
			continue;
		}
		snprintf(fullPath, sizeof(fullPath), "%s\\%s", dir_path, findFileData.cFileName);

		fileAttributes = GetFileAttributes(fullPath);
		BOOL is_file = (fileAttributes != INVALID_FILE_ATTRIBUTES) && !(fileAttributes & FILE_ATTRIBUTE_DIRECTORY);

		entries[idx].is_file = is_file;
		entries[idx].name = malloc(strlen(findFileData.cFileName) + 1);
		if (entries[idx].name) {
			strcpy(entries[idx].name, findFileData.cFileName);
		}
		idx++;

	} while(FindNextFile(hFind, &findFileData) != 0);

	FindClose(hFind);

	if (GetLastError() != ERROR_NO_MORE_FILES) {
		// Clean up on error
		rmp_free_dir_entries(entries, idx);
		return NULL;
	}

	*count = idx;
	return entries;

#else

	DIR *dir;
	struct dirent *entry;
	char fullPath[1024];

	dir = opendir(dir_path);
	if (dir == NULL) {
		return NULL;
	}

	// Count entries first
	int temp_count = 0;
	while ((entry = readdir(dir)) != NULL) {
		if (strcmp(entry->d_name, ".") != 0 && strcmp(entry->d_name, "..") != 0) {
			temp_count++;
		}
	}

	// Reset and read again
	rewinddir(dir);

	rmp_dir_entry_t* entries = malloc(temp_count * sizeof(rmp_dir_entry_t));
	if (!entries) {
		closedir(dir);
		return NULL;
	}

	int idx = 0;
	while ((entry = readdir(dir)) != NULL) {
		if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
			continue;
		}
		snprintf(fullPath, sizeof(fullPath), "%s/%s", dir_path, entry->d_name);

		int is_file = entry->d_type == DT_DIR ? 0 : 1;

		entries[idx].is_file = is_file;
		entries[idx].name = malloc(strlen(entry->d_name) + 1);
		if (entries[idx].name) {
			strcpy(entries[idx].name, entry->d_name);
		}
		idx++;
	}

	closedir(dir);

	*count = idx;
	return entries;

#endif
}

bool rmp_mkdir(const char* dir_path, int mode) {
	if (!dir_path) {
		return false;
	}

#ifndef _WIN32
	// Use provided mode or default
	int actual_mode = (mode != 0) ? mode : 0755;
	int res = mkdir(dir_path, actual_mode);
#else
	// On Windows, mode is ignored
	int res = mkdir(dir_path);
#endif

	return res == 0;
}

bool rmp_rmdir(const char* dir_path) {
	if (!dir_path) {
		return false;
	}

#ifdef 	_WIN32
	if(_rmdir(dir_path) != 0){
		return false;
	}
	return true;
#else
	if(rmdir(dir_path) != 0){
		return false;
	}
	return true;
#endif
}

void rmp_free_dir_entries(rmp_dir_entry_t* entries, int count) {
	if (!entries) {
		return;
	}

	for (int i = 0; i < count; i++) {
		if (entries[i].name) {
			free(entries[i].name);
		}
	}

	free(entries);
}
#include <stdlib.h> // getenv
#include <errno.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

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

static int lua_get_current_path(lua_State* L){
#define SIZE	1024
	char current_path[SIZE];
	if(rmp_api_cwd(current_path , SIZE) == NULL){
		lua_pushnil(L);
	}else{
		lua_pushstring(L , current_path);
	}
#undef SIZE
	return 1;
}

static int lua_home_path(lua_State* L){
#ifdef 	_WIN32
	char* home_path = getenv("USERPROFILE");
	if(home_path != NULL){
		lua_pushstring(L , home_path);
	}else{	// USERPROFILE is not set
		char* home_drive = getenv("HOMEDRIVE");
		char* home_path_suffix = getenv("HOMEPATH");
		if (home_drive != NULL && home_path_suffix != NULL) {
			home_path = malloc(strlenn(home_drive) + strlen(home_path_suffix) + 1);
			strcpy(home_path, home_drive);
			strcat(home_path, home_path_suffix);
			lua_pushstring(L , home_path);
		}else{
			lua_pushnil(L);
			lua_pushstring(L , "cannot get home path");
		}
	}
#else
	char* home_path = getenv("HOME");

	if(home_path != NULL){
		lua_pushstring(L , home_path);
	}else{	// HOME is not set
		struct passwd* pwd = getpwuid(getuid());
		if(pwd != NULL){
			home_path = pwd->pw_dir;
			lua_pushstring(L , home_path);
		}else{
			lua_pushnil(L);
			lua_pushstring(L , "cannot get home path");
		}
	}
#endif
	return 1;
}

static int lua_list_dir(lua_State* L){

	const char* const dir_path = luaL_checkstring(L , 1);

	lua_newtable(L);
	int idx = 1;

#ifdef 	_WIN32
	WIN32_FIND_DATA findFileData;
	HANDLE hFind;
	char searchPath[MAX_PATH];
	char fullPath[MAX_PATH];
	DWORD fileAttributes;

	snprintf(searchPath, sizeof(searchPath), "%s\\*", dir_path);
	hFind = FindFirstFile(searchPath, &findFileData);
	if (hFind == INVALID_HANDLE_VALUE) {
		lua_pushnil(L);
		lua_pushstring(L, "Cannot open directory");
		return 2; }

	do{
		if (strcmp(findFileData.cFileName, ".") == 0 || strcmp(findFileData.cFileName, "..") == 0) {
			continue;
		}
		snprintf(fullPath, sizeof(fullPath), "%s\\%s", dir_path, findFileData.cFileName);

		fileAttributes = GetFileAttributes(fullPath);
		BOOL is_file = (fileAttributes != INVALID_FILE_ATTRIBUTES) && !(fileAttributes & FILE_ATTRIBUTE_DIRECTORY);

		lua_newtable(L);
		lua_pushstring(L, "is_file");
		lua_pushboolean(L, is_file);
		lua_settable(L, -3);

		lua_pushstring(L, "name");
		lua_pushstring(L, findFileData.cFileName);
		lua_settable(L, -3);

		lua_rawseti(L, -2, idx++);

	}while(FindNextFile(hFind, &findFileData) != 0);

	FindClose(hFind);

	if (GetLastError() != ERROR_NO_MORE_FILES) {
		lua_pushnil(L);
		lua_pushstring(L, "Error reading directory contents");
		return 2;
	}

#else

	DIR *dir;
	struct dirent *entry;
	char fullPath[1024];


	dir = opendir(dir_path);
	if (dir == NULL) {
		lua_pushnil(L);
		lua_pushfstring(L, "Cannot open directory: %s", dir_path);
		return 2;
	}

	while ((entry = readdir(dir)) != NULL) {
		if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
			continue;
		}
		snprintf(fullPath, sizeof(fullPath), "%s/%s", dir_path, entry->d_name);

		int is_file = entry->d_type == DT_DIR ? 0 : 1;

		lua_newtable(L);

		lua_pushstring(L, "is_file");
		lua_pushboolean(L, is_file);
		lua_settable(L, -3);

		lua_pushstring(L, "name");
		lua_pushstring(L, entry->d_name);
		lua_settable(L, -3);

		lua_rawseti(L, -2, idx++);
	}

	closedir(dir);

#endif
	return 1;
}

static int lua_mkdir(lua_State* L){

	const char* const dir_path = luaL_checkstring(L , 1);

	int mode = 0755; // default：rwxr-xr-x
	if (lua_gettop(L) >= 2 && lua_isnumber(L, 2)) {
		mode = lua_tointeger(L, 2);
	}

	int res;

	res = mkdir(dir_path , mode);

	if(res == 0){
		lua_pushboolean(L , 1);
		return 1;
	}else{
		lua_pushboolean(L , 0);
		const char* why;
#ifdef 	_WIN32
		switch (errno) {
			case EEXIST: why = "Directory already exists"; break;
			case ENOENT: why = "Path not found"; break;
			case EACCES: why = "Permission denied"; break;
			default: why = "Unknown error"; break;
		}
#else
		switch (errno) {
			case EEXIST: why = "Directory already exists"; break;
			case ENOENT: why = "Path not found"; break;
			case EACCES: why = "Permission denied"; break;
			case ENAMETOOLONG: why = "Path too long"; break;
			case ENOTDIR: why = "A component of path is not a directory"; break;
			case EROFS: why = "Read-only filesystem"; break;
			default: why = "Unknown error"; break;
		}
#endif
		lua_pushstring(L, why);
		return 2;
	}
}

static int lua_rmdir(lua_State* L){
	const char* const dir_path = luaL_checkstring(L , 1);

#ifdef 	_WIN32
	if(!_rmdir(dir_path) != 0){
		lua_pushboolean(L , 0);
		switch (errno) {
			case EACCES: 
				lua_pushstring(L, "Directory is not empty or access denied");
				break;
			case ENOENT: 
				lua_pushstring(L, "Directory does not exist or path is invalid");
				break;
			case ENOTEMPTY: 
				lua_pushstring(L, "Directory is not empty");
				break;
			case EINVAL: 
				lua_pushstring(L, "Invalid path name");
				break;
			default: 
				lua_pushstring(L, "Unknown error occurred");
				break;
		}
		return 2;

	}
	lua_pushboolean(L , 1);
#else
	if(rmdir(dir_path) != 0){
		lua_pushboolean(L , 0);
		switch(errno){
			// get it from man page
			// man 2 rmdir
			case EACCES : lua_pushstring(L , " Write  access  to the directory containing pathname was not allowed, or one of the directories in the path prefix of pathname did not allow search permission.  (See also path_resolution(7).)"); break;
			case EBUSY : lua_pushstring(L , "  pathname is currently in use by the system or some process that prevents its removal.  On Linux, this means pathname is currently used as a mount point or is the root directory of the calling process."); break;
			case EFAULT : lua_pushstring(L , " pathname points outside your accessible address space."); break;
			case EINVAL : lua_pushstring(L , " pathname has .  as last component."); break;
			case ELOOP : lua_pushstring(L , "  Too many symbolic links were encountered in resolving pathname."); break;
			case ENAMETOOLONG : lua_pushstring(L , " pathname was too long."); break;
			case ENOENT : lua_pushstring(L , " A directory component in pathname does not exist or is a dangling symbolic link."); break;
			case ENOMEM : lua_pushstring(L , " Insufficient kernel memory was available."); break;
			case ENOTDIR : lua_pushstring(L , " pathname, or a component used as a directory in pathname, is not, in fact, a directory."); break;
			case ENOTEMPTY : lua_pushstring(L , " pathname contains  entries  other than . and .. ; or, pathname has ..  as its final component.  POSIX.1 also allows EEXIST for this condition."); break;
			case EPERM : lua_pushstring(L , "  The directory containing pathname has the sticky bit (S_ISVTX) set and the process's effective user ID is neither the user ID of	the  file to be deleted nor that of the directory containing it, and the process is not privileged (Linux: does not have the CAP_FOWNER capability)."); break;
			case EROFS : lua_pushstring(L , "  pathname refers to a directory on a read-only filesystem."); break;
		}
		return 2;
	}
	lua_pushboolean(L , 1);
#endif
	return 1;
}

static const luaL_Reg lib[] = {
	{"get_current_path", lua_get_current_path},
	{"home_path", lua_home_path},
	{"list_dir", lua_list_dir},
	{"mkdir", lua_mkdir},
	{"rmdir", lua_rmdir},
	{NULL, NULL}
};

int luaopen_rmp_directory(lua_State *L)
{
	luaL_newlib(L, lib);
	return 1;
}

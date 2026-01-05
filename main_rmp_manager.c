/****************************************************************************************/
/*  RMP - Ray's Music Player 								                            */
/*  											                                        */
/*  Copyright (c) 2025 Ray Den 								                            */
/*  											                                        */
/*  Permission is hereby granted, free of charge, to any person obtaining a copy 	    */
/*  of this software and associated documentation files (the "Software"), to deal 	    */
/*  in the Software without restriction, including without limitation the rights 	    */
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 		    */
/*  copies of the Software, and to permit persons to whom the Software is 		        */
/*  furnished to do so, subject to the following conditions: 				            */
/*  											                                        */
/*  The above copyright notice and this permission notice shall be included in 		    */
/*  all copies or substantial portions of the Software. 				                */
/*  											                                        */
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 		    */
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		    */
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 	    */
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 		        */
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 	    */
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 		    */
/*  THE SOFTWARE. 									                                    */
/*  											                                        */
/****************************************************************************************/

// RMP Audio Engine - Multi-device support
// Powered by native C implementation with Lua plugin support
// Elegant C implementation

/****************************************************************************************/
/*  RMP - Ray's Music Player 								                            */
/****************************************************************************************/

#include "rmp_manager.h"
#include "./src/engine/lua/include/lua.h"
#include "./src/engine/lua/include/lauxlib.h"
#include "./src/engine/lua/include/lualib.h"
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>

#define RMP_NAME "Ray's Music Player"
#define RMP_VERSION "1.0.0"
#define RMP_ENGINE_TAG "[RMP]"

void rmp_print_usage(char* progname)
{
	printf("RMP - %s v%s\n", RMP_NAME, RMP_VERSION);
	printf("Usage: %s [COMMAND] [OPTIONS]\n", progname);
	printf("\nCommands:\n");
	printf("  help        		Display this help message\n");
	printf("\nOptions:\n");
	printf("  --help 	, -h    Display this help message\n");
	printf("  --version 	, -v    Display RMP Version\n");
}

char* rmp_shift_args(int argc, char** argv)
{
	if(argc <= 1) {
		return NULL;
	}

	static int rmp_index = 0;

	if(rmp_index >= argc) {
		return NULL;
	}

	return argv[rmp_index++];
}

int rmp_engine_main(lua_State* L)
{
	if (!L) {
		fprintf(stderr, "%s Lua state not initialized\n", RMP_ENGINE_TAG);
		return 1;
	}

	bool restart = true;

	while (restart) {
		restart = false;

		// Load configuration
		int template_ref = LUA_NOREF;
		size_t template_count = 0;
		bool is_userconfig = false;

		int config_ref = load_configuration(L, &template_ref, &template_count, &is_userconfig);

		if (config_ref == LUA_NOREF || config_ref == LUA_REFNIL ||
		    template_ref == LUA_NOREF || template_ref == LUA_REFNIL) {
			rmp_log_error("Failed to load configuration. Exiting.");
			rmp_log_note("check your configuration file or try to reset it by deleting ~/.rmp/config.lua");
			rmp_log_note("see the errors above for more details.");
			return 1;
		}

		// Expand template array from Lua table
		int* template_refs = NULL;
		if (template_count > 0) {
			template_refs = malloc(template_count * sizeof(int));

			lua_rawgeti(L, LUA_REGISTRYINDEX, template_ref);
			if (lua_istable(L, -1)) {
				for (size_t i = 0; i < template_count; i++) {
					lua_rawgeti(L, -1, i + 1);
					template_refs[i] = luaL_ref(L, LUA_REGISTRYINDEX);
				}
			}
			lua_pop(L, 1);
		}

		// Setup sound configuration
		int sound_cfg_ref = LUA_NOREF;

		lua_rawgeti(L, LUA_REGISTRYINDEX, config_ref);
		if (lua_istable(L, -1)) {
			lua_getfield(L, -1, "soundMap");
			if (lua_istable(L, -1)) {
				sound_cfg_ref = luaL_ref(L, LUA_REGISTRYINDEX);
			} else {
				lua_pop(L, 1);
			}
		}
		lua_pop(L, 1);

		// Setup plugins
		Queue* other_plugs = NULL;
		HashMap* plugs_cfgs = NULL;
		int plug_manager_ref = setup_plugins(L, config_ref, is_userconfig, &other_plugs, &plugs_cfgs);

		// Note: In C we don't have PlugManager as object yet, need to convert
		// For now, we'll skip plugin manager and just run the app

		// Get settings
		int settings_ref = LUA_NOREF;
		lua_rawgeti(L, LUA_REGISTRYINDEX, config_ref);
		if (lua_istable(L, -1)) {
			lua_getfield(L, -1, "settings");
			if (lua_istable(L, -1)) {
				settings_ref = luaL_ref(L, LUA_REGISTRYINDEX);
			} else {
				lua_pop(L, 1);
			}
		}
		lua_pop(L, 1);

		// Run the application
		restart = run_rmp_application(
			L,
			NULL, // plug_manager - TODO: implement
			template_refs,
			template_count,
			settings_ref,
			other_plugs,
			sound_cfg_ref,
			plugs_cfgs,
			config_ref,
			is_userconfig
		);

		// Cleanup
		if (other_plugs) {
			queue_free(other_plugs);
		}
		if (plugs_cfgs) {
			hashmap_free(plugs_cfgs);
		}
		if (template_refs) {
			for (size_t i = 0; i < template_count; i++) {
				luaL_unref(L, LUA_REGISTRYINDEX, template_refs[i]);
			}
			free(template_refs);
		}
		if (template_ref != LUA_NOREF && template_ref != LUA_REFNIL) {
			luaL_unref(L, LUA_REGISTRYINDEX, template_ref);
		}
		if (config_ref != LUA_NOREF && config_ref != LUA_REFNIL) {
			luaL_unref(L, LUA_REGISTRYINDEX, config_ref);
		}
		if (settings_ref != LUA_NOREF && settings_ref != LUA_REFNIL) {
			luaL_unref(L, LUA_REGISTRYINDEX, settings_ref);
		}
		if (sound_cfg_ref != LUA_NOREF && sound_cfg_ref != LUA_REFNIL) {
			luaL_unref(L, LUA_REGISTRYINDEX, sound_cfg_ref);
		}
	}

	return 0;
}

int main(int argc, char** argv)
{
	// skip program name
	rmp_shift_args(argc, argv);

	for(int i = 1; i < argc; i++){
		if(
				strcmp(argv[i], "--help") == 0 ||
				strcmp(argv[i], "-h") == 0 ||
				strcmp(argv[i], "/?") == 0 ||
				strcmp(argv[i], "-help") == 0 ||
				strcmp(argv[i], "/help") == 0 ||
				strcmp(argv[i], "help") == 0
		  ){
			rmp_print_usage(argv[0]);
			return 0;
		}
		
		if(strcmp(argv[i], "--version") == 0 || strcmp(argv[i], "-v") == 0) {
			printf("RMP v%s\n", RMP_VERSION);
			return 0;
		}
	}

	// Parse command from arguments
	char* rmp_command = rmp_shift_args(argc - 1, argv);
	if(rmp_command != NULL) {
		if(strcmp(rmp_command, "help") == 0) {
			rmp_print_usage(argv[0]);
			return 0;
		}
	}

	// Initialize Lua state for plugin support
	lua_State *RMP_LUA_STATE = luaL_newstate();
	if (RMP_LUA_STATE == NULL) {
		fprintf(stderr, "%s Failed to create RMP Lua Engine state.\n", RMP_ENGINE_TAG);
		return 1;
	}

	luaL_openlibs(RMP_LUA_STATE);

	// Set up Lua package path to find RMP modules
	const char* package_path = "./src/?.lua;./src/engine/core/?.lua;./src/engine/selfrmp/?.lua;./src/engine/?.lua;./?.lua;";
	lua_getglobal(RMP_LUA_STATE, "package");
	lua_getfield(RMP_LUA_STATE, -1, "path");
	const char* current_path = lua_tostring(RMP_LUA_STATE, -1);
	char new_path[1024];
	snprintf(new_path, sizeof(new_path), "%s;%s", current_path, package_path);
	lua_pop(RMP_LUA_STATE, 1);
	lua_pushstring(RMP_LUA_STATE, new_path);
	lua_setfield(RMP_LUA_STATE, -2, "path");
	lua_pop(RMP_LUA_STATE, 1);

	// Load the RMP Lua API module
	if (luaL_dostring(RMP_LUA_STATE, "api = require('rmp.rmp')") != LUA_OK) {
		fprintf(stderr, "%s Failed to load RMP Lua API: %s\n", RMP_ENGINE_TAG, lua_tostring(RMP_LUA_STATE, -1));
		lua_pop(RMP_LUA_STATE, 1);
		lua_close(RMP_LUA_STATE);
		return 1;
	}

	// Verify that api is properly loaded
	lua_getglobal(RMP_LUA_STATE, "api");
	if (!lua_istable(RMP_LUA_STATE, -1)) {
		fprintf(stderr, "%s API module not loaded properly\n", RMP_ENGINE_TAG);
		lua_pop(RMP_LUA_STATE, 1);
		lua_close(RMP_LUA_STATE);
		return 1;
	}
	lua_pop(RMP_LUA_STATE, 1);

	// Load utility modules
	if (luaL_dostring(RMP_LUA_STATE, "utils = require('rmp.util')") != LUA_OK) {
		fprintf(stderr, "%s Failed to load RMP utilities: %s\n", RMP_ENGINE_TAG, lua_tostring(RMP_LUA_STATE, -1));
		lua_pop(RMP_LUA_STATE, 1);
		lua_close(RMP_LUA_STATE);
		return 1;
	}

	if (luaL_dostring(RMP_LUA_STATE, "OOP = require('rmp.oop')") != LUA_OK) {
		fprintf(stderr, "%s Failed to load RMP OOP: %s\n", RMP_ENGINE_TAG, lua_tostring(RMP_LUA_STATE, -1));
		lua_pop(RMP_LUA_STATE, 1);
		lua_close(RMP_LUA_STATE);
		return 1;
	}

	// Initialize mainFrame global - check if api.Frame exists first
	if (luaL_dostring(RMP_LUA_STATE,
		"if api and api.Frame and api.Frame.new then "
		"  mainFrame = api.Frame.new() "
		"else "
		"  error('api.Frame.new is not available') "
		"end") != LUA_OK) {
		fprintf(stderr, "%s Failed to initialize mainFrame: %s\n", RMP_ENGINE_TAG, lua_tostring(RMP_LUA_STATE, -1));
		lua_pop(RMP_LUA_STATE, 1);
		lua_close(RMP_LUA_STATE);
		return 1;
	}

	// Load io and os modules needed by the engine
	if (luaL_dostring(RMP_LUA_STATE, "io = require('io'); os = require('os')") != LUA_OK) {
		fprintf(stderr, "%s Failed to load io/os modules: %s\n", RMP_ENGINE_TAG, lua_tostring(RMP_LUA_STATE, -1));
		lua_pop(RMP_LUA_STATE, 1);
		lua_close(RMP_LUA_STATE);
		return 1;
	}

	// Run the main engine in C
	int result = rmp_engine_main(RMP_LUA_STATE);

	// Final cleanup
	if (RMP_LUA_STATE) {
		lua_getglobal(RMP_LUA_STATE, "mainFrame");
		if (lua_istable(RMP_LUA_STATE, -1)) {
			lua_getfield(RMP_LUA_STATE, -1, "cleanupMainFrame");
			if (lua_isfunction(RMP_LUA_STATE, -1)) {
				lua_pushvalue(RMP_LUA_STATE, -2);
				if (lua_pcall(RMP_LUA_STATE, 1, 0, 0) != LUA_OK) {
					fprintf(stderr, "%s Error in cleanupMainFrame: %s\n", RMP_ENGINE_TAG, lua_tostring(RMP_LUA_STATE, -1));
					lua_pop(RMP_LUA_STATE, 1); // Remove error message
				}
			} else {
				lua_pop(RMP_LUA_STATE, 1); // Remove the non-function value
			}
		}
		lua_pop(RMP_LUA_STATE, 1); // Remove mainFrame table
	}

	lua_close(RMP_LUA_STATE);
	return result;
}

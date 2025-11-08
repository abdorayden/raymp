/****************************************************************************************/
/*  Copyright (c) 2025 Ray Den 								*/
/*  											*/ 
/*  Permission is hereby granted, free of charge, to any person obtaining a copy 	*/
/*  of this software and associated documentation files (the "Software"), to deal 	*/
/*  in the Software without restriction, including without limitation the rights 	*/
/*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 		*/
/*  copies of the Software, and to permit persons to whom the Software is 		*/
/*  furnished to do so, subject to the following conditions: 				*/
/*  											*/ 
/*  The above copyright notice and this permission notice shall be included in 		*/
/*  all copies or substantial portions of the Software. 				*/
/*  											*/ 
/*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 		*/
/*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 		*/
/*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 	*/
/*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 		*/
/*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 	*/
/*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 		*/
/*  THE SOFTWARE. 									*/
/*  											*/ 
/****************************************************************************************/

// make audio choose multi devices headphones and more ...

// gcc is all you need :)

// untested and buggable code below
// this is a new implementation of the RMP engine in C using Lua API
#if 0
// rmp_engine.c - RMP Engine implemented in C using Lua API
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>
#ifdef _WIN32
    #define PATH_SEP "\\"
#else
    #define PATH_SEP "/"
#endif
typedef struct {
    lua_State *L;
    int plugManager_ref;
    int template_ref;
    int settings_ref;
    int otherPlugs_ref;
    int soundCfg_ref;
    bool quit;
    bool restart;
} RMPEngine;
// Helper function to detect path separator
static const char* detect_path_separator(lua_State *L) {
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.directory");
    lua_call(L, 1, 1);
    lua_getfield(L, -1, "get_current_path");
    lua_call(L, 0, 1);
    if (!lua_isnil(L, -1)) {
        const char *path = lua_tostring(L, -1);
        if (path && strstr(path, "\\")) {
            lua_pop(L, 2);
            return "\\";
        }
    }
    lua_pop(L, 2);
    return "/";
}
// Helper function to join paths
static void join_path(char *result, size_t size, int argc, ...) {
    va_list args;
    va_start(args, argc);
    result[0] = '\0';
    const char *sep = PATH_SEP;
    for (int i = 0; i < argc; i++) {
        const char *part = va_arg(args, const char*);
        if (part && part[0]) {
            if (i > 0 && result[strlen(result)-1] != '/' && result[strlen(result)-1] != '\\') {
                strncat(result, sep, size - strlen(result) - 1);
            }
            // Skip leading separator in part
            if (part[0] == '/' || part[0] == '\\') {
                part++;
            }
            strncat(result, part, size - strlen(result) - 1);
        }
    }
    va_end(args);
}
// Create PlugManager instance
static int create_plug_manager(lua_State *L, int cfgObj_ref) {
    // Create PlugManager instance
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.oop");
    lua_call(L, 1, 1);
    lua_getfield(L, -1, "class");
    lua_pushstring(L, "PlugManager");
    lua_call(L, 1, 1);
    // Store class and create new instance
    lua_getfield(L, -1, "new");
    lua_rawgeti(L, LUA_REGISTRYINDEX, cfgObj_ref);
    lua_call(L, 1, 1);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pop(L, 2); // pop oop module and class
    return ref;
}
// Create TemplateParser instance
static int create_template_parser(lua_State *L, int template_ref, int plugManager_ref) {
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.oop");
    lua_call(L, 1, 1);
    lua_getfield(L, -1, "class");
    lua_pushstring(L, "TemplateParser");
    lua_call(L, 1, 1);
    lua_getfield(L, -1, "new");
    lua_rawgeti(L, LUA_REGISTRYINDEX, template_ref);
    lua_rawgeti(L, LUA_REGISTRYINDEX, plugManager_ref);
    lua_call(L, 2, 1);
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pop(L, 2);
    return ref;
}
// Log functions
static void log_error(lua_State *L, const char *err) {
    lua_getglobal(L, "io");
    lua_getfield(L, -1, "write");
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.rmp");
    lua_call(L, 1, 1);
    // Build colored error string
    lua_getfield(L, -1, "BGColors");
    lua_getfield(L, -1, "Brights");
    lua_getfield(L, -1, "Red");
    lua_getfield(L, -4, "FGColors");
    lua_getfield(L, -1, "Brights");
    lua_getfield(L, -1, "Yellow");
    lua_pushstring(L, "RMP Error:");
    lua_getfield(L, -8, "Default");
    lua_pushstring(L, " ");
    lua_pushstring(L, err);
    lua_pushstring(L, "\n");
    lua_concat(L, 8);
    lua_call(L, 1, 0);
    lua_pop(L, 5);
}
static void log_note(lua_State *L, const char *note) {
    lua_getglobal(L, "io");
    lua_getfield(L, -1, "write");
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.rmp");
    lua_call(L, 1, 1);
    lua_getfield(L, -1, "BGColors");
    lua_getfield(L, -1, "Brights");
    lua_getfield(L, -1, "Blue");
    lua_getfield(L, -4, "FGColors");
    lua_getfield(L, -1, "Brights");
    lua_getfield(L, -1, "White");
    lua_pushstring(L, "RMP Note:");
    lua_getfield(L, -8, "Default");
    lua_pushstring(L, " ");
    lua_pushstring(L, note);
    lua_pushstring(L, "\n");
    lua_concat(L, 8);
    lua_call(L, 1, 0);
    lua_pop(L, 5);
}
// Load configuration
static bool load_configuration(RMPEngine *engine) {
    lua_State *L = engine->L;
    // Get api.Config.new()
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.rmp");
    lua_call(L, 1, 1);
    lua_getfield(L, -1, "Config");
    lua_getfield(L, -1, "new");
    lua_call(L, 0, 1);
    int config_idx = lua_gettop(L);
    // Check if valid config
    lua_getfield(L, config_idx, "isValidConfig");
    lua_pushvalue(L, config_idx);
    lua_call(L, 1, 1);
    bool is_valid = lua_toboolean(L, -1);
    lua_pop(L, 1);
    if (is_valid) {
        // Load user config
        lua_getfield(L, config_idx, "load");
        lua_pushvalue(L, config_idx);
        lua_call(L, 1, 2);
  
        bool ok = lua_toboolean(L, -2);
        if (!ok) {
            const char *err = lua_tostring(L, -1);
            char msg[256];
            snprintf(msg, sizeof(msg), "loading user configuration: %s", err);
            log_error(L, msg);
            lua_pop(L, 4);
            return false;
        }
        lua_pop(L, 2);
  
        // Get config object
        lua_getfield(L, config_idx, "getInitFileAsObject");
        lua_pushvalue(L, config_idx);
        lua_call(L, 1, 1);
        int cfgObj_ref = luaL_ref(L, LUA_REGISTRYINDEX);
  
        // Get template name
        lua_rawgeti(L, LUA_REGISTRYINDEX, cfgObj_ref);
        lua_getfield(L, -1, "template");
        const char *themeName = lua_tostring(L, -1);
  
        if (!themeName) {
            log_error(L, "Invalid theme name in configuration");
            lua_pop(L, 4);
            return false;
        }
  
        // Load template file
        lua_getfield(L, config_idx, "homePath");
        lua_getfield(L, -1, "getPath");
        lua_pushvalue(L, -2);
        lua_call(L, 1, 1);
        const char *homePath = lua_tostring(L, -1);
  
        char templatePath[512];
        snprintf(templatePath, sizeof(templatePath), "%s%s.rmp%sthemes%s%s.lua",
                 homePath, PATH_SEP, PATH_SEP, PATH_SEP, themeName);
  
        if (luaL_dofile(L, templatePath) != 0) {
            const char *err = lua_tostring(L, -1);
            char msg[256];
            snprintf(msg, sizeof(msg), "loading user template: %s", err);
            log_error(L, msg);
            lua_pop(L, 6);
            return false;
        }
  
        engine->template_ref = luaL_ref(L, LUA_REGISTRYINDEX);
        engine->settings_ref = cfgObj_ref;
  
        lua_pop(L, 5);
        return true;
  
    } else {
        // Load default config
        lua_getglobal(L, "require");
        lua_pushstring(L, "rmp.selfrmp.init");
        lua_call(L, 1, 1);
        engine->settings_ref = luaL_ref(L, LUA_REGISTRYINDEX);
  
        lua_rawgeti(L, LUA_REGISTRYINDEX, engine->settings_ref);
        lua_getfield(L, -1, "template");
        const char *templateName = lua_tostring(L, -1);
  
        char requirePath[256];
        snprintf(requirePath, sizeof(requirePath), "rmp.selfrmp.themes.%s", templateName);
  
        lua_getglobal(L, "require");
        lua_pushstring(L, requirePath);
        lua_call(L, 1, 1);
        engine->template_ref = luaL_ref(L, LUA_REGISTRYINDEX);
  
        lua_pop(L, 4);
        return true;
    }
}
// Setup plugins
static bool setup_plugins(RMPEngine *engine, bool is_userconfig) {
    lua_State *L = engine->L;
    // Get plugins from config
    lua_rawgeti(L, LUA_REGISTRYINDEX, engine->settings_ref);
    lua_getfield(L, -1, "plugins");
    if (!lua_istable(L, -1)) {
        log_error(L, "Invalid plugins configuration");
        lua_pop(L, 2);
        return false;
    }
    // Create HashMap for plugs
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.util");
    lua_call(L, 1, 1);
    lua_getfield(L, -1, "HashMap");
    lua_getfield(L, -1, "new");
    lua_call(L, 0, 1);
    int plugs_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    // Create Queue for otherPlugs
    lua_getfield(L, -1, "Queue");
    lua_getfield(L, -1, "new");
    lua_call(L, 0, 1);
    engine->otherPlugs_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    // Iterate through plugins
    int plugins_idx = lua_gettop(L) - 1;
    lua_pushnil(L);
    while (lua_next(L, plugins_idx) != 0) {
        if (lua_istable(L, -1)) {
            lua_getfield(L, -1, "themeWindowId");
            const char *windowId = lua_tostring(L, -1);
            lua_pop(L, 1);
      
            lua_getfield(L, -1, "isActivated");
            bool isActivated = lua_toboolean(L, -1);
            lua_pop(L, 1);
      
            if (isActivated) {
                lua_getfield(L, -1, "names");
                if (lua_istable(L, -1)) {
                    // Create Queue for this window's plugins
                    lua_getfield(L, -4, "Queue");
                    lua_getfield(L, -1, "new");
                    lua_call(L, 0, 1);
                    int pq_idx = lua_gettop(L);
              
                    // Load each plugin
                    lua_pushnil(L);
                    while (lua_next(L, -4) != 0) {
                        const char *name = lua_tostring(L, -1);
                        if (name) {
                            // Load plugin (simplified - would need full path logic)
                            lua_getglobal(L, "require");
                            char requirePath[256];
                            snprintf(requirePath, sizeof(requirePath), 
                                    is_userconfig ? "%s" : "rmp.selfrmp.plugins.%s", name);
                            lua_pushstring(L, requirePath);
                      
                            if (lua_pcall(L, 1, 1, 0) == 0) {
                                // Push to queue
                                lua_getfield(L, pq_idx, "push");
                                lua_pushvalue(L, pq_idx);
                                lua_pushvalue(L, -3);
                                lua_call(L, 2, 0);
                                lua_pop(L, 1);
                            } else {
                                lua_pop(L, 1);
                            }
                        }
                        lua_pop(L, 1);
                    }
              
                    if (windowId) {
                        // Store in HashMap
                        lua_rawgeti(L, LUA_REGISTRYINDEX, plugs_ref);
                        lua_getfield(L, -1, "put");
                        lua_pushvalue(L, -2);
                        lua_pushstring(L, windowId);
                  
                        // Create table {switchKey, queue}
                        lua_newtable(L);
                        lua_getfield(L, -8, "switchPluginKey");
                        lua_rawseti(L, -2, 1);
                        lua_pushvalue(L, pq_idx);
                        lua_rawseti(L, -2, 2);
                  
                        lua_call(L, 3, 0);
                        lua_pop(L, 1);
                    } else {
                        // Add to otherPlugs
                        // (simplified)
                    }
              
                    lua_pop(L, 2);
                }
                lua_pop(L, 1);
            }
        }
        lua_pop(L, 1);
    }
    // Create PlugManager
    engine->plugManager_ref = create_plug_manager(L, plugs_ref);
    lua_pop(L, 3);
    return true;
}
// Main run loop
static bool run_rmp_application(RMPEngine *engine) {
    lua_State *L = engine->L;
    // Get terminal size
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.rmp");
    lua_call(L, 1, 1);
    int api_idx = lua_gettop(L);
    lua_getfield(L, api_idx, "Terminal");
    lua_getfield(L, -1, "getSize");
    lua_call(L, 0, 2);
    int h = lua_tointeger(L, -2);
    int w = lua_tointeger(L, -1);
    lua_pop(L, 2);
    // Create Frame
    lua_getfield(L, api_idx, "Frame");
    lua_getfield(L, -1, "new");
    lua_call(L, 0, 1);
    int frame_idx = lua_gettop(L);
    // Hide cursor
    lua_getfield(L, api_idx, "Terminal");
    lua_getfield(L, -1, "hideCursor");
    lua_call(L, 0, 0);
    // Create Sound object
    lua_getfield(L, api_idx, "Sound");
    lua_getfield(L, -1, "new");
    lua_call(L, 0, 1);
    int sound_idx = lua_gettop(L);
    // Setup FPS if configured
    lua_rawgeti(L, LUA_REGISTRYINDEX, engine->settings_ref);
    lua_getfield(L, -1, "settings");
    if (!lua_isnil(L, -1)) {
        lua_getfield(L, -1, "fps");
        if (lua_isnumber(L, -1)) {
            int fps = lua_tointeger(L, -1);
            if (fps > 0 && fps <= 120) {
                lua_getfield(L, frame_idx, "setFps");
                lua_pushvalue(L, frame_idx);
                lua_pushinteger(L, fps);
                lua_call(L, 2, 0);
            }
        }
        lua_pop(L, 1);
    }
    lua_pop(L, 2);
    // Create TemplateParser
    int parser_ref = create_template_parser(L, engine->template_ref, engine->plugManager_ref);
    lua_rawgeti(L, LUA_REGISTRYINDEX, parser_ref);
    int parser_idx = lua_gettop(L);
    // Main loop
    engine->quit = false;
    engine->restart = false;
    while (!engine->quit) {
        // Handle keyboard input
        lua_getfield(L, api_idx, "Terminal");
        lua_getfield(L, -1, "handleKey");
        lua_call(L, 0, 1);
        int key = lua_tointeger(L, -1);
  
        // Check for terminal resize
        lua_getfield(L, parser_idx, "wasTerminalResized");
        lua_pushvalue(L, parser_idx);
        lua_call(L, 1, 1);
        if (lua_toboolean(L, -1)) {
            lua_getfield(L, api_idx, "Terminal");
            lua_getfield(L, -1, "getSize");
            lua_call(L, 0, 2);
            h = lua_tointeger(L, -2);
            w = lua_tointeger(L, -1);
      
            lua_getfield(L, frame_idx, "resize");
            lua_pushvalue(L, frame_idx);
            lua_pushinteger(L, w);
            lua_pushinteger(L, h);
            lua_call(L, 3, 0);
            lua_pop(L, 2);
        }
        lua_pop(L, 2);
  
        // Parse template and get windows
        lua_getfield(L, parser_idx, "parseTemplate");
        lua_pushvalue(L, parser_idx);
        lua_call(L, 1, 2);
  
        // Add windows to frame
        lua_pushnil(L);
        while (lua_next(L, -3) != 0) {
            lua_getfield(L, frame_idx, "add");
            lua_pushvalue(L, frame_idx);
            lua_pushvalue(L, -3);
            lua_call(L, 2, 0);
            lua_pop(L, 1);
        }
  
        // Update sound
        lua_getfield(L, sound_idx, "update");
        lua_pushvalue(L, sound_idx);
        lua_call(L, 1, 0);
  
        // Run frame
        lua_getfield(L, frame_idx, "run");
        lua_pushvalue(L, frame_idx);
        lua_pushinteger(L, key);
        lua_pushnil(L); // mouse
        lua_pushvalue(L, sound_idx);
        lua_call(L, 4, 0);
  
        lua_pop(L, 3); // pop windows, context, key
  
        if (engine->restart) {
            break;
        }
    }
    // Cleanup
    lua_getfield(L, sound_idx, "cleanup");
    lua_pushvalue(L, sound_idx);
    lua_call(L, 1, 0);
    lua_getfield(L, api_idx, "Terminal");
    lua_getfield(L, -1, "showCursor");
    lua_call(L, 0, 0);
    lua_getfield(L, -1, "rawMode");
    lua_pushboolean(L, false);
    lua_call(L, 1, 0);
    lua_getfield(L, -1, "closeKey");
    lua_call(L, 0, 0);
    lua_pop(L, lua_gettop(L));
    return engine->restart;
}
// Main entry point
int rmp_engine_run(lua_State *L) {
    RMPEngine engine = {0};
    engine.L = L;
    // Load required modules
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.rmp");
    lua_call(L, 1, 1);
    lua_setglobal(L, "api");
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.util");
    lua_call(L, 1, 1);
    lua_setglobal(L, "utils");
    lua_getglobal(L, "require");
    lua_pushstring(L, "rmp.oop");
    lua_call(L, 1, 1);
    lua_setglobal(L, "OOP");
    bool restart = false;
    do {
        // Load configuration
        if (!load_configuration(&engine)) {
            log_error(L, "Failed to load configuration. Exiting.");
            log_note(L, "check your configuration file or try to reset it by deleting ~/.rmp/config.lua");
            return 1;
        }
  
        // Determine if user config or default
        lua_rawgeti(L, LUA_REGISTRYINDEX, engine.settings_ref);
        lua_getfield(L, -1, "__is_user_config");
        bool is_userconfig = lua_toboolean(L, -1);
        lua_pop(L, 2);
  
        // Setup plugins
        if (!setup_plugins(&engine, is_userconfig)) {
            log_error(L, "Failed to setup plugins. Exiting.");
            return 1;
        }
  
        // Setup sound config
        lua_rawgeti(L, LUA_REGISTRYINDEX, engine.settings_ref);
        lua_getfield(L, -1, "soundMap");
        if (lua_isnil(L, -1)) {
            // Create default sound config
            lua_pop(L, 1);
            lua_newtable(L);
      
            // Set default keys (simplified)
            lua_getglobal(L, "api");
            lua_getfield(L, -1, "KEY_SPACE");
            lua_setfield(L, -3, "pause_sound");
            lua_getfield(L, -1, "KEY_SPACE");
            lua_setfield(L, -3, "resume_sound");
            // ... more default keys
            lua_pop(L, 1);
        }
        engine.soundCfg_ref = luaL_ref(L, LUA_REGISTRYINDEX);
        lua_pop(L, 1);
  
        // Run application
        restart = run_rmp_application(&engine);
  
        // Clean up references
        if (engine.plugManager_ref) {
            luaL_unref(L, LUA_REGISTRYINDEX, engine.plugManager_ref);
            engine.plugManager_ref = 0;
        }
        if (engine.template_ref) {
            luaL_unref(L, LUA_REGISTRYINDEX, engine.template_ref);
            engine.template_ref = 0;
        }
        if (engine.settings_ref) {
            luaL_unref(L, LUA_REGISTRYINDEX, engine.settings_ref);
            engine.settings_ref = 0;
        }
        if (engine.otherPlugs_ref) {
            luaL_unref(L, LUA_REGISTRYINDEX, engine.otherPlugs_ref);
            engine.otherPlugs_ref = 0;
        }
        if (engine.soundCfg_ref) {
            luaL_unref(L, LUA_REGISTRYINDEX, engine.soundCfg_ref);
            engine.soundCfg_ref = 0;
        }
  
    } while (restart);
    return 0;
}
// Integration with main.c
int main(int argc, char** argv) {
    // ... existing argument parsing code ...
    lua_State *L = luaL_newstate();
    if (L == NULL) {
        fprintf(stderr, "[RMP] failed creating Engine Lua state.\n");
        return 1;
    }
    luaL_openlibs(L);
    // Run the C engine instead of Lua string
    int result = rmp_engine_run(L);
    lua_close(L);
    return result;
}
#endif







#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

// #define ONE_FILE

void print_help(char* progname)
{
	printf("Usage: %s [COMMAND] [OPTIONS]\n", progname);
	printf("Command:\n");
	printf("  help        		Show this help message\n");
	/* printf("  init 		       	create plugin architecture directory , with evirement developement\n"); */
	/* printf("  test	        	create empty window , used to test your plugin \n"); */
	printf("Options:\n");
	printf("  --help 	, -h    Show this help message\n");
	printf("  --version 	, -v    Show RMP Version\n");
}

char* shift_args(int argc , char** argv)
{
	if(argc <= 1) {
		return NULL;
	}

	static int index = 0;

	if(index >= argc) {
		return NULL;
	}

	return argv[index++];
}

#ifndef ONE_FILE
#include <runner.h>
#endif

#ifdef ONE_FILE

// litteraly embed RMPManager lua code to the static buffer 
// whatever i don't care because im gonna rewrite this engine to actual C code using lua API to access rmp framework
static const char *const engine = 
"local api = require(\"rmp.rmp\")\n"
"local utils = require(\"rmp.util\")\n"
"local OOP = require(\"rmp.oop\")\n"
"\n"
"local io = require(\"io\")\n"
"local os = require(\"os\")\n"
"\n"
"local HashMap = utils.HashMap\n"
"local Queue = utils.Queue\n"
"\n"
"local function detectPathSeparator()\n"
"	local currentPath = require(\"rmp.directory\").get_current_path()\n"
"	if currentPath and currentPath:find(\"\\\\\") then\n"
"		return \"\\\\\"\n"
"	else\n"
"		return \"/\"\n"
"	end\n"
"end\n"
"\n"
"local PATH_SEP = detectPathSeparator()\n"
"\n"
"local function joinPath(...)\n"
"	local parts = {...}\n"
"	if #parts == 0 then return \"\" end\n"
"\n"
"	local result = tostring(parts[1] or \"\")\n"
"	for i = 2, #parts do\n"
"		local part = tostring(parts[i] or \"\")\n"
"		if part ~= \"\" then\n"
"			-- Remove leading separator from part\n"
"			if part:sub(1, 1) == \"/\" or part:sub(1, 1) == \"\\\\\" then\n"
"				part = part:sub(2)\n"
"			end\n"
"			-- Add separator if needed\n"
"			if result:sub(-1) ~= PATH_SEP and result ~= \"\" then\n"
"				result = result .. PATH_SEP\n"
"			end\n"
"			result = result .. part\n"
"		end\n"
"	end\n"
"	return result\n"
"end\n"
"\n"
"local PlugManager = OOP.class(\"PlugManager\")\n"
"do\n"
"	function PlugManager:constructor(cfgObj)\n"
"		self.cfgObj = cfgObj\n"
"		self.pluginStates = {}\n"
"	end\n"
"\n"
"	function PlugManager:getNextPlug(id)\n"
"		local currentPlug = self.cfgObj:get(id)\n"
"		if not currentPlug then\n"
"			return function() end, \"No plugins for window \" .. tostring(id)\n"
"		end\n"
"\n"
"		if currentPlug[2]:isEmpty() then\n"
"			return function() end, \"No plugins available\"\n"
"		end\n"
"\n"
"		local forRet = currentPlug[2]:pop()\n"
"		currentPlug[2]:push(forRet)\n"
"\n"
"		self.pluginStates[id] = {\n"
"			current = forRet,\n"
"			lastSwitched = os.time()\n"
"		}\n"
"\n"
"		return forRet, nil\n"
"	end\n"
"\n"
"	function PlugManager:getSwitchKey(id)\n"
"		local currentPlug = self.cfgObj:get(id)\n"
"		if not currentPlug then\n"
"			return nil\n"
"		end\n"
"		return currentPlug[1]\n"
"	end\n"
"\n"
"	function PlugManager:getPluginState(id)\n"
"		return self.pluginStates[id]\n"
"	end\n"
"end\n"
"\n"
"-- template parser with layout engine\n"
"local TemplateParser = OOP.class(\"TemplateParser\")\n"
"do\n"
"	function TemplateParser:constructor(template, plugManager)\n"
"		self.template = template\n"
"		self.plugManager = plugManager\n"
"		self.windowCache = {}\n"
"		self.pluginCache = {}\n"
"		self.lastTerminalSize = {w = 0, h = 0}\n"
"	end\n"
"\n"
"	function TemplateParser:evaluateExpression(expr, context)\n"
"		if type(expr) == \"number\" then\n"
"			return math.floor(expr)\n"
"		end\n"
"\n"
"		if type(expr) ~= \"string\" then\n"
"			return 1\n"
"		end\n"
"\n"
"		local evaluated = expr\n"
"		for key, value in pairs(context) do\n"
"			evaluated = evaluated:gsub(key, tostring(value))\n"
"		end\n"
"\n"
"		evaluated = evaluated:gsub(\"math%%.floor\", \"math.floor\")\n"
"		evaluated = evaluated:gsub(\"math%%.ceil\", \"math.ceil\")\n"
"\n"
"		local func = load(\"return \" .. evaluated)\n"
"		if func then\n"
"			local ok, result = pcall(func)\n"
"			if ok and type(result) == \"number\" then\n"
"				return math.floor(result)\n"
"			end\n"
"		end\n"
"\n"
"		return 1\n"
"	end\n"
"\n"
"	function TemplateParser:createContext()\n"
"		local h, w = api.Terminal:getSize()\n"
"		return {\n"
"			w = w,\n"
"			h = h,\n"
"			lw = w - 1,\n"
"			lh = h - 1\n"
"		}\n"
"	end\n"
"\n"
"	--TODO: add more usefull callbacks to a text and window parser later\n"
"	-- dynamic and condition is really useful , so im gonna looking for more usefull callbacks\n"
"	function TemplateParser:parseText(textConfig, context)\n"
"		if not textConfig or textConfig.type ~= \"Text\" then\n"
"			return nil\n"
"		end\n"
"\n"
"		local value = textConfig.value or \"\"\n"
"\n"
"		if textConfig.dynamic and type(textConfig.dynamic) == \"function\" then\n"
"			local dynamicValue = textConfig.dynamic(context)\n"
"			if type(dynamicValue) == 'string' then\n"
"				value = dynamicValue\n"
"			elseif type(dynamicValue) == 'table' then\n"
"				if dynamicValue.value then\n"
"					value = tostring(dynamicValue.value)\n"
"				elseif dynamicValue.style then\n"
"					textConfig.style = dynamicValue.style\n"
"				elseif dynamicValue.foregroundColor then\n"
"					textConfig.foregroundColor = dynamicValue.foregroundColor\n"
"				elseif dynamicValue.backgroundColor then\n"
"					textConfig.backgroundColor = dynamicValue.backgroundColor\n"
"				end\n"
"			end\n"
"		end\n"
"\n"
"		return api.Text.new(\n"
"		value,\n"
"		textConfig.style,\n"
"		textConfig.foregroundColor,\n"
"		textConfig.backgroundColor\n"
"		)\n"
"	end\n"
"\n"
"	function TemplateParser:createWindow(windowConfig, context, mainFrame)\n"
"		if not windowConfig or windowConfig.type ~= \"Window\" then\n"
"			return nil\n"
"		end\n"
"\n"
"		if windowConfig.condition and type(windowConfig.condition) == \"function\" then\n"
"			if not windowConfig.condition(context) then\n"
"				return nil\n"
"			end\n"
"		end\n"
"\n"
"		local width = self:evaluateExpression(windowConfig.width, context)\n"
"		local height = self:evaluateExpression(windowConfig.height, context)\n"
"		local x = self:evaluateExpression(windowConfig.x, context)\n"
"		local y = self:evaluateExpression(windowConfig.y, context)\n"
"\n"
"		local title = nil\n"
"		if windowConfig.title then\n"
"			title = self:parseText(windowConfig.title, context)\n"
"		end\n"
"\n"
"		local currentPlugin = self.pluginCache[windowConfig.id]\n"
"		if not currentPlugin and windowConfig.id and self.plugManager then\n"
"			local plugin, err = self.plugManager:getNextPlug(windowConfig.id)\n"
"			if plugin and not err then\n"
"				currentPlugin = plugin\n"
"				self.pluginCache[windowConfig.id] = plugin\n"
"			end\n"
"		end\n"
"\n"
"		local callback = function(innerX, innerY, innerXX, innerYY)\n"
"			local childVterm = api.VirtualTerminal.new()\n"
"\n"
"			if currentPlugin and type(currentPlugin) == \"function\" then\n"
"				local pluginResult = currentPlugin(innerX, innerY, innerXX, innerYY)\n"
"				if pluginResult then\n"
"					childVterm:merge(pluginResult)\n"
"				end\n"
"			end\n"
"\n"
"			if windowConfig.children then\n"
"				for _, childConfig in ipairs(windowConfig.children) do\n"
"					local childWindow = self:createWindow(childConfig, context, mainFrame)\n"
"					if childWindow then\n"
"						childVterm:merge(childWindow)\n"
"					end\n"
"				end\n"
"			end\n"
"\n"
"			if windowConfig.content and type(windowConfig.content) == \"function\" then\n"
"				local contentResult = windowConfig.content(innerX, innerY, innerXX, innerYY, context)\n"
"				if contentResult then\n"
"					childVterm:merge(contentResult)\n"
"				end\n"
"			end\n"
"\n"
"			return childVterm\n"
"		end\n"
"\n"
"		local window = api.Window.new(windowConfig.id):createWindow(\n"
"		title,\n"
"		width,\n"
"		height,\n"
"		x,\n"
"		y,\n"
"		windowConfig.foregroundColor,\n"
"		windowConfig.backgroundColor,\n"
"		windowConfig.border,\n"
"		callback\n"
"		)\n"
"\n"
"		return window\n"
"	end\n"
"\n"
"	function TemplateParser:parseTemplate()\n"
"		if not self.template or type(self.template) ~= \"table\" then\n"
"			return {}\n"
"		end\n"
"\n"
"		local context = self:createContext()\n"
"		local windows = {}\n"
"\n"
"		for _, windowConfig in ipairs(self.template) do\n"
"			if windowConfig.type == \"Window\" then\n"
"				local window = self:createWindow(windowConfig, context, nil)\n"
"				if window then\n"
"					table.insert(windows, window)\n"
"				end\n"
"			end\n"
"		end\n"
"\n"
"		return windows, context\n"
"	end\n"
"\n"
"	function TemplateParser:getPluginSwitchKeys()\n"
"		local switchKeys = {}\n"
"		if not self.plugManager then\n"
"			return switchKeys\n"
"		end\n"
"\n"
"		local function collectKeys(config)\n"
"			if config.id then\n"
"				local key = self.plugManager:getSwitchKey(config.id)\n"
"				if key then\n"
"					switchKeys[config.id] = key\n"
"				end\n"
"			end\n"
"			if config.children then\n"
"				for _, child in ipairs(config.children) do\n"
"					collectKeys(child)\n"
"				end\n"
"			end\n"
"		end\n"
"\n"
"		for _, windowConfig in ipairs(self.template) do\n"
"			collectKeys(windowConfig)\n"
"		end\n"
"\n"
"		return switchKeys\n"
"	end\n"
"\n"
"	function TemplateParser:updatePlugin(windowId)\n"
"		if self.plugManager then\n"
"			local plugin, err = self.plugManager:getNextPlug(windowId)\n"
"			if plugin and not err then\n"
"				self.pluginCache[windowId] = plugin\n"
"			end\n"
"		end\n"
"	end\n"
"\n"
"	function TemplateParser:wasTerminalResized()\n"
"		local h, w = api.Terminal:getSize()\n"
"		if w ~= self.lastTerminalSize.w or h ~= self.lastTerminalSize.h then\n"
"			self.lastTerminalSize.w = w\n"
"			self.lastTerminalSize.h = h\n"
"			return true\n"
"		end\n"
"		return false\n"
"	end\n"
"end\n"
"\n"
"local function runRMPApplication(plugManager, template, settings , otherPlugs , soundCfg)\n"
"	local h, w = api.Terminal:getSize()\n"
"	local mainFrame = api.Frame.new()\n"
"\n"
"	-- check the settings first and then the keymap\n"
"	local sound = api.Sound.new()	-- empty playlist\n"
"\n"
"	local inc_speed = nil\n"
"	local inc_volume = nil\n"
"	local inc_seek = nil\n"
"	local valid_restart = false\n"
"	local exit = nil\n"
"\n"
"	-- TODO: handle the mode playback from configuration\n"
"	if settings then\n"
"		if settings.fps and type(settings.fps) == \"number\" and settings.fps > 0 and settings.fps <= 120 then\n"
"			mainFrame:setFps(settings.fps)\n"
"		end\n"
"\n"
"		if settings.restart_engine and type(settings.restart_engine) == \"number\" then\n"
"			valid_restart = true\n"
"		end\n"
"\n"
"		if settings.volume and type(settings.volume) == \"number\" and settings.volume >= 0 and settings.volume <= 100 then\n"
"			sound:setVolume(settings.volume)\n"
"		else\n"
"			sound:setVolume(0.5)\n"
"		end\n"
"\n"
"		if settings.speed and type(settings.speed) == \"number\" and settings.speed > 0.0 and settings.speed <= 3.0 then\n"
"			sound:setSpeed(settings.speed)\n"
"		else\n"
"			sound:setSpeed(1.0)\n"
"		end\n"
"\n"
"		-- if settings.mode and type(settings.mode) == \"number\" then\n"
"		-- 	sound:setPlayBackMode(settings.mode)\n"
"		-- end\n"
"\n"
"		if settings.mode and type(settings.mode) == \"number\" and settings.mode >= 0 and settings.mode <= 3 then\n"
"			sound:setPlayBackMode(settings.mode)\n"
"		else\n"
"			sound:setPlayBackMode(0)\n"
"		end\n"
"\n"
"		if settings.inc_speed and type(settings.inc_speed) == \"number\" and settings.inc_speed > 0 and settings.inc_speed <= 50 then\n"
"			inc_speed = settings.inc_speed\n"
"		else\n"
"			inc_speed = 0.1\n"
"		end\n"
"\n"
"		if settings.inc_seek and type(settings.inc_seek) == \"number\" and settings.inc_seek > 0 and settings.inc_seek <= 30 then\n"
"			inc_seek = settings.inc_seek\n"
"		else\n"
"			inc_seek = 5\n"
"		end\n"
"\n"
"		if settings.inc_volume and type(settings.inc_volume) == \"number\" and settings.inc_volume > 0 and settings.inc_volume <= 50 then\n"
"			inc_volume = settings.inc_volume\n"
"		else\n"
"			inc_volume = 10\n"
"		end\n"
"\n"
"		if settings.exit and type(settings.exit) == \"number\" then\n"
"			exit = settings.exit\n"
"		else\n"
"			exit = api.KEY_Q\n"
"		end\n"
"\n"
"	else\n"
"		inc_speed = 0.1\n"
"		inc_volume = 0.1\n"
"		inc_seek = 5\n"
"		exit = api.KEY_Q\n"
"	end\n"
"\n"
"	api.Terminal:hideCursor()\n"
"\n"
"	local parser = TemplateParser.new(template, plugManager)\n"
"	local switchKeys = parser:getPluginSwitchKeys()\n"
"	local quit = false\n"
"	local oq = otherPlugs\n"
"	local restart = false\n"
"\n"
"	while not quit do\n"
"		local key = api.Terminal:handleKey()\n"
"\n"
"		if parser:wasTerminalResized() then\n"
"			h, w = api.Terminal:getSize()\n"
"			mainFrame:resize(w, h)\n"
"		end\n"
"\n"
"		for windowId, switchKey in pairs(switchKeys) do\n"
"			mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)\n"
"				if inputKey == switchKey then\n"
"					parser:updatePlugin(windowId)\n"
"				end\n"
"			end)\n"
"		end\n"
"\n"
"		-- TODO: handle the exit key from configuration\n"
"		mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)\n"
"			if inputKey == exit then\n"
"				quit = true\n"
"			end\n"
"		end)\n"
"\n"
"		mainFrame:addEventListener(api.EventType.Keyboard , function(key)\n"
"			if valid_restart then\n"
"				if key == settings.restart_engine then\n"
"					restart = true\n"
"				end\n"
"			end\n"
"		end)\n"
"\n"
"		mainFrame:addEventListener(api.EventType.Keyboard, function(inputKey)\n"
"\n"
"			-- in case u configured pause and resume with same key\n"
"			if soundCfg.pause_sound ~= soundCfg.resume_sound then\n"
"				if inputKey == soundCfg.pause_sound then\n"
"					if sound:isPlaying() then\n"
"						sound:pause()\n"
"					end\n"
"				end\n"
"				if inputKey == soundCfg.resume_sound then\n"
"					if not sound:isPlaying() then\n"
"						sound:play()\n"
"						sound:resume()\n"
"					end\n"
"				end\n"
"			else\n"
"				if inputKey == soundCfg.resume_sound then\n"
"					if not sound:isPlaying() then\n"
"						sound:play()\n"
"						sound:resume()\n"
"					else\n"
"						sound:pause()\n"
"					end\n"
"				end\n"
"			end\n"
"			if inputKey == soundCfg.next_sound then\n"
"				local ok , err = sound:nextTrack()\n"
"				if not ok then\n"
"					-- log the error with popup\n"
"				end\n"
"			end\n"
"			if inputKey == soundCfg.prev_sound then\n"
"				local ok , err = sound:prevTrack()\n"
"				if not ok then\n"
"					-- log the error with popup\n"
"				end\n"
"			end\n"
"			if inputKey == soundCfg.vol_up then\n"
"				local currVol = sound:getVolume()\n"
"				if currVol < 1 then\n"
"					if currVol + inc_volume >= 1 then\n"
"						sound:setVolume(1)\n"
"					else\n"
"						sound:setVolume(currVol + inc_volume)\n"
"					end\n"
"				end\n"
"			end\n"
"			if inputKey == soundCfg.vol_down then\n"
"				local currVol = sound:getVolume()\n"
"				if currVol > 0 then\n"
"					if currVol - inc_volume <= 0 then\n"
"						sound:setVolume(0)\n"
"					else\n"
"						sound:setVolume(currVol - inc_volume)\n"
"					end\n"
"				end\n"
"			end\n"
"			if inputKey == soundCfg.seek_left then\n"
"				if sound:isPlaying() then\n"
"					local currPos = math.floor(sound:getPosition())\n"
"					if currPos > 0 then\n"
"						if currPos - inc_seek <= 0 then\n"
"							sound:seek(0)\n"
"						else\n"
"							sound:seek(currPos - inc_seek)\n"
"						end\n"
"					end\n"
"				end\n"
"			end\n"
"			if inputKey == soundCfg.seek_right then\n"
"				if sound:isPlaying() then\n"
"					local currPos = math.floor(sound:getPosition())\n"
"					local len = math.floor(sound:getLength())\n"
"					if currPos < len then\n"
"						if currPos + inc_seek >= len then\n"
"							sound:seek(len - 1) -- i know i know don't ask any quesion\n"
"						else\n"
"							sound:seek(currPos + inc_seek)\n"
"						end\n"
"					end\n"
"				end\n"
"			end\n"
"			if inputKey == soundCfg.speed_up then\n"
"				local currSpeed = sound:getSpeed() + inc_speed\n"
"				if currSpeed < 3.0 then\n"
"					sound:setSpeed(currSpeed)\n"
"				else\n"
"					sound:setSpeed(3.0)\n"
"				end\n"
"			end\n"
"			if inputKey == soundCfg.speed_down then\n"
"				local currSpeed = sound:getSpeed() - inc_speed\n"
"				if currSpeed > 0.0 then\n"
"					sound:setSpeed(currSpeed)\n"
"				else\n"
"					sound:setSpeed(0.1)\n"
"				end\n"
"			end\n"
"\n"
"			if inputKey == soundCfg.change_playback_mode then\n"
"				sound:setPlayBackMode((sound:getPlayBackMode() + 1) % 4) -- hard code the length of mode whatever\n"
"			end\n"
"		end)\n"
"\n"
"		sound:update()\n"
"\n"
"		local windows, context = parser:parseTemplate()\n"
"\n"
"		for _, window in ipairs(windows) do\n"
"			mainFrame:add(window)\n"
"		end\n"
"\n"
"		local qq = Queue.new()\n"
"\n"
"		while not oq:isEmpty() do\n"
"			local plug = oq:pop()\n"
"			if plug and type(plug) == \"function\" then\n"
"				mainFrame:add(plug())\n"
"				qq:push(plug)\n"
"			end\n"
"		end\n"
"		oq = qq\n"
"\n"
"		mainFrame:run(\n"
"			key, \n"
"			nil, -- add mouse support later\n"
"			sound\n"
"		)\n"
"\n"
"		if restart then\n"
"			break\n"
"		end\n"
"	end\n"
"\n"
"	sound:cleanup()\n"
"\n"
"	api.Terminal:showCursor()\n"
"	api.Terminal:rawMode(false)\n"
"	api.Terminal:closeKey()\n"
"	return restart\n"
"end\n"
"\n"
"local function logerror(err)\n"
"	io.write(api.BGColors.Brights.Red .. api.FGColors.Brights.Yellow .. \"RMP Error:\"  .. api.Default .. \" \" ..  tostring(err) .. \"\\n\")\n"
"end\n"
"\n"
"local function lognote(note)\n"
"	io.write(api.BGColors.Brights.Blue .. api.FGColors.Brights.White .. \"RMP Note:\"  .. api.Default .. \" \" ..  tostring(note) .. \"\\n\")\n"
"end\n"
"\n"
"local function logwarn(warn)\n"
"	io.write(api.BGColors.Brights.Yellow .. api.FGColors.Brights.Black .. \"RMP Warning:\"  .. api.Default .. \" \" ..  tostring(warn) .. \"\\n\")\n"
"end\n"
"\n"
"local function coloredKeywordInString(str, keyword, color)\n"
"	local pattern = \"%f[%w_]\" .. keyword .. \"%f[%W]\"\n"
"	return str:gsub(pattern, color .. keyword .. api.Default)\n"
"end\n"
"\n"
"local function coloredLuaCode(str)\n"
"	if type(str) ~= \"string\" then\n"
"		return str\n"
"	end\n"
"\n"
"	local keywords = {\n"
"		\"and\", \"break\", \"do\", \"else\", \"elseif\", \"end\", \"false\", \"for\", \"function\",\n"
"		\"if\", \"in\", \"local\", \"nil\", \"not\", \"or\", \"repeat\", \"return\", \"then\",\n"
"		\"true\", \"until\", \"while\"\n"
"	}\n"
"\n"
"	for _, keyword in ipairs(keywords) do\n"
"		str = coloredKeywordInString(str, keyword, api.FGColors.Brights.Green)\n"
"	end\n"
"\n"
"	return str\n"
"end\n"
"\n"
"local function loadConfiguration()\n"
"	local config = api.Config.new()\n"
"\n"
"	if config:isValidConfig() then\n"
"		local ok, err = config:load()\n"
"		if not ok then\n"
"			logerror(\"loading user configuration: \" .. err)\n"
"			return nil , nil , nil\n"
"		end\n"
"\n"
"		local cfgObj = config:getInitFileAsObject()\n"
"		local themeName = cfgObj.template-- config:getThemesAsObject() or \"default\"\n"
"\n"
"		if not themeName or type(themeName) ~= \"string\" then\n"
"			logerror(\"Invalid theme name in configuration.\")\n"
"			logerror(\"template should be required on the configuration.\")\n"
"			lognote(\"Example template:\")\n"
"			lognote(coloredLuaCode(\"	return {\"))\n"
"			lognote(coloredLuaCode(\"	    ...\"))\n"
"			lognote(coloredLuaCode(\"	    template = 'your_theme_name',\"))\n"
"			lognote(coloredLuaCode(\"	    ...\"))\n"
"			lognote(coloredLuaCode(\"	}\"))\n"
"			return nil , nil , nil\n"
"		end\n"
"\n"
"		local templateOk, template = pcall(dofile , joinPath(config.homePath:getPath(), \".rmp\", \"themes\", themeName .. \".lua\"))\n"
"		if not templateOk then\n"
"			logerror(\"loading user template: Not found or \" .. template)\n"
"			logerror(\"template should be a lua file that returns a table.\")\n"
"			lognote(\"Example template:\")\n"
"			lognote(coloredLuaCode(\"	return {\"))\n"
"			lognote(coloredLuaCode(\"	    {\"))\n"
"			lognote(coloredLuaCode(\"	        type = 'Window',\"))\n"
"			lognote(coloredLuaCode(\"	        id = 'main',\"))\n"
"			lognote(coloredLuaCode(\"	        width = 'w',\"))\n"
"			lognote(coloredLuaCode(\"	        height = 'h',\"))\n"
"			lognote(coloredLuaCode(\"	        x = 0,\"))\n"
"			lognote(coloredLuaCode(\"	        y = 0,\"))\n"
"			lognote(coloredLuaCode(\"	        border = true,\"))\n"
"			lognote(coloredLuaCode(\"	        title = {\"))\n"
"			lognote(coloredLuaCode(\"	            type = 'Text',\"))\n"
"			lognote(coloredLuaCode(\"	            value = 'My RMP Theme',\"))\n"
"			lognote(coloredLuaCode(\"	            style = 'bold',\"))\n"
"			lognote(coloredLuaCode(\"	            foregroundColor = 'yellow',\"))\n"
"			lognote(coloredLuaCode(\"	            backgroundColor = 'blue',\"))\n"
"			lognote(coloredLuaCode(\"	        },\"))\n"
"			lognote(coloredLuaCode(\"	        children = {\"))\n"
"			lognote(coloredLuaCode(\"	            ...\"))\n"
"			lognote(coloredLuaCode(\"	        },\"))\n"
"			lognote(coloredLuaCode(\"	    },\"))\n"
"			lognote(coloredLuaCode(\"	    ...\"))\n"
"			lognote(coloredLuaCode(\"	}\"))\n"
"			return nil , nil , nil\n"
"		end\n"
"\n"
"		return cfgObj, template , true -- true means user config\n"
"	else\n"
"		local defaultConfig = require(\"rmp.selfrmp.init\")\n"
"		local templateOk, template = pcall(require, \"rmp.selfrmp.themes.\" .. defaultConfig.template)\n"
"\n"
"		if not templateOk then\n"
"			logerror(\"Error loading default template: \" .. template)\n"
"			return nil\n"
"		end\n"
"\n"
"		return defaultConfig, template , false -- false means default config\n"
"	end\n"
"end\n"
"\n"
"local function setupPlugins(configObj , is_userconfig)\n"
"	local plugs = HashMap.new()\n"
"	local plugins = configObj.plugins\n"
"	local otherPlugs = Queue.new() -- this is for global plugins not attached to any window\n"
"	local currentPath = api.Path.new():getHomePath()\n"
"\n"
"\n"
"	if not plugins or type(plugins) ~= \"table\" then\n"
"		logerror(\"Invalid plugins configuration.\")\n"
"		lognote(\"plugins should be a table of plugin configurations.\")\n"
"		lognote(\"Example plugins configuration:\")\n"
"		lognote(coloredLuaCode(\"return {\"))\n"
"		lognote(coloredLuaCode(\"    	...\"))\n"
"		lognote(coloredLuaCode(\"	plugins = {\"))\n"
"		lognote(coloredLuaCode(\"	    {\"))\n"
"		lognote(coloredLuaCode(\"	        themeWindowId = 'main',\"))\n"
"		lognote(coloredLuaCode(\"	        switchPluginKey = api.KEY_TAB,\"))\n"
"		lognote(coloredLuaCode(\"	        names = {'plugin1', 'plugin2'},\"))\n"
"		lognote(coloredLuaCode(\"	        isActivated = true,\"))\n"
"		lognote(coloredLuaCode(\"	    },\"))\n"
"		lognote(coloredLuaCode(\"	    {\"))\n"
"		lognote(coloredLuaCode(\"	        names = {'globalPlugin'},\"))\n"
"		lognote(coloredLuaCode(\"	        isActivated = true,\"))\n"
"		lognote(coloredLuaCode(\"	    },\"))\n"
"		lognote(coloredLuaCode(\"	}\"))	\n"
"		lognote(coloredLuaCode(\"}\"))	\n"
"		return nil , nil\n"
"	end\n"
"\n"
"\n"
"	for _, plug in ipairs(plugins) do\n"
"		if plug.themeWindowId and plug.isActivated and plug.names then\n"
"			local pq = Queue.new()\n"
"\n"
"			for _, name in ipairs(plug.names) do\n"
"				local pluginOk, pluginModule\n"
"\n"
"				if is_userconfig then\n"
"					local homePath = api.Path.new():getHomePath()\n"
"					local singleFile = joinPath(homePath, \".rmp\", \"plugins\", name .. \".lua\")\n"
"					local folderInit = joinPath(homePath, \".rmp\", \"plugins\", name, \"init.lua\")\n"
"\n"
"					pluginOk, pluginModule = pcall(dofile, singleFile)\n"
"					if not pluginOk then\n"
"						pluginOk, pluginModule = pcall(dofile, folderInit)\n"
"					end\n"
"				else\n"
"					pluginOk, pluginModule = pcall(require, \"rmp.selfrmp.plugins.\" .. name) -- try to load from default selfrmp plugins\n"
"				end\n"
"\n"
"				if pluginOk and pluginModule then\n"
"					pq:push(pluginModule)\n"
"				else\n"
"					logwarn(\"Could not load plugin '\" .. name .. \"' make sure that default plugin are installed: \" .. tostring(pluginModule) .. \"\\n\")\n"
"					os.exit(1)\n"
"				end\n"
"			end\n"
"\n"
"			if not pq:isEmpty() then\n"
"				plugs:put(plug.themeWindowId, {plug.switchPluginKey, pq})\n"
"			end\n"
"		elseif plug.isActivated and plug.names and plug.themeWindowId == nil  then\n"
"			for _, name in ipairs(plug.names) do\n"
"				local pluginOk, pluginModule\n"
"				if is_userconfig then\n"
"					local homePath = api.Path.new():getHomePath()\n"
"					local singleFile = joinPath(homePath, \".rmp\", \"plugins\", name .. \".lua\")\n"
"					local folderInit = joinPath(homePath, \".rmp\", \"plugins\", name, \"init.lua\")\n"
"\n"
"					pluginOk, pluginModule = pcall(dofile, singleFile)\n"
"					if not pluginOk then\n"
"						pluginOk, pluginModule = pcall(dofile, folderInit)\n"
"					end\n"
"				else\n"
"					pluginOk, pluginModule = pcall(require, \"rmp.selfrmp.plugins.\" .. name) -- try to load from default selfrmp plugins\n"
"				end\n"
"				if pluginOk and pluginModule then\n"
"					otherPlugs:push(pluginModule)\n"
"				else\n"
"					logwarn(\"Could not load global plugin '\" .. name .. \"': \" .. tostring(pluginModule) .. \"\\n\")\n"
"					os.exit(1)\n"
"				end\n"
"			end\n"
"\n"
"		end\n"
"	end\n"
"\n"
"	return PlugManager.new(plugs) , otherPlugs \n"
"end\n"
"\n"
"-- Main Entry Point\n"
"local function main()\n"
"	-- Load configuration\n"
"\n"
"	::here::\n"
"\n"
"	local configObj, template , is_userconfig = loadConfiguration()\n"
"	if not configObj or not template then\n"
"		logerror(\"Failed to load configuration. Exiting.\")\n"
"		-- TODO: assuming default path windows and linux\n"
"		lognote(\"check your configuration file or try to reset it by deleting ~/.rmp/config.lua\") \n"
"		lognote(\"see the errors above for more details.\")\n"
"		os.exit(1)\n"
"	end\n"
"\n"
"	local soundCfg = configObj.soundMap\n"
"\n"
"	if soundCfg == nil then	--- use the default\n"
"		soundCfg = {\n"
"			pause_sound = api.KEY_SPACE,\n"
"			resume_sound = api.KEY_SPACE,\n"
"			next_sound = api.KEY_N,\n"
"			prev_sound = api.KEY_P,\n"
"			vol_up = api.KEY_PLUS,\n"
"			vol_down = api.KEY_MINUS,\n"
"			seek_left = api.KEY_LEFT,\n"
"			seek_right = api.KEY_RIGHT,\n"
"			speed_up = api.KEY_UP,\n"
"			speed_down = api.KEY_DOWN,\n"
"			change_playback_mode = api.KEY_TAB\n"
"		}\n"
"	elseif #soundCfg < 10 then	--- check for every key if it's not exists set the default key\n"
"		if soundCfg.pause_sound == nil or type(soundCfg.pause_sound) ~= \"number\" then\n"
"			soundCfg.pause_sound = api.KEY_SPACE\n"
"		end\n"
"		if soundCfg.change_playback_mode == nil or type(soundCfg.change_playback_mode) ~= \"number\" then\n"
"			soundCfg.pause_sound = api.KEY_TAB\n"
"		end\n"
"		if soundCfg.resume_sound == nil or type(soundCfg.resume_sound) ~= \"number\" then\n"
"			soundCfg.resume_sound = api.KEY_SPACE\n"
"		end\n"
"		if soundCfg.next_sound == nil or type(soundCfg.next_sound) ~= \"number\" then\n"
"			soundCfg.next_sound = api.KEY_N\n"
"		end\n"
"		if soundCfg.prev_sound == nil or type(soundCfg.prev_sound) ~= \"number\" then\n"
"			soundCfg.prev_sound = api.KEY_P\n"
"		end\n"
"		if soundCfg.vol_up == nil or type(soundCfg.vol_up) ~= \"number\" then\n"
"			soundCfg.vol_up = api.KEY_PLUS\n"
"		end\n"
"		if soundCfg.vol_down == nil or type(soundCfg.vol_down) ~= \"number\" then\n"
"			soundCfg.vol_down = api.KEY_MINUS\n"
"		end\n"
"		if soundCfg.seek_left == nil or type(soundCfg.seek_left) ~= \"number\" then\n"
"			soundCfg.seek_left = api.KEY_LEFT\n"
"		end\n"
"		if soundCfg.seek_right == nil or type(soundCfg.seek_right) ~= \"number\" then\n"
"			soundCfg.seek_right = api.KEY_RIGHT\n"
"		end\n"
"		if soundCfg.speed_up == nil or type(soundCfg.speed_up) ~= \"number\" then\n"
"			soundCfg.speed_up = api.KEY_UP\n"
"		end\n"
"		if soundCfg.speed_down == nil or type(soundCfg.speed_down) ~= \"number\" then\n"
"			soundCfg.speed_down = api.KEY_DOWN\n"
"		end\n"
"		\n"
"	end\n"
"\n"
"	local plugManager , otherPlugs  = setupPlugins(configObj , is_userconfig)\n"
"\n"
"	if not plugManager and not otherPlugs then\n"
"		logerror(\"Failed to setup plugins. Exiting.\")\n"
"		lognote(\"check your plugins configuration.\")\n"
"		lognote(\"see the errors above for more details.\")\n"
"		os.exit(1)\n"
"	end\n"
"\n"
"	local parser = TemplateParser.new(template, plugManager)\n"
"	-- You could add template validation here if needed\n"
"\n"
"	if runRMPApplication(plugManager, template, configObj.settings , otherPlugs , soundCfg) then\n"
"		goto here\n"
"	end\n"
"end\n"
"\n"
"local function safeMain()\n"
"	local ok, err = pcall(main)\n"
"	if not ok then\n"
"		api.Terminal:showCursor()\n"
"		api.Terminal:rawMode(false)\n"
"		logerror(tostring(err))\n"
"		lognote(\"check the error above for more details.\")\n"
"		os.exit(1)\n"
"	end\n"
"\n"
"end\n"
"\n"
"-- Start the application\n"
"safeMain()\n";

#endif

// TODO: rewrite RMPManger engine in C
int main(int argc , char** argv)
{

	// no arguments mean run the program
	char* program = shift_args(argc , argv);
	if(program == NULL) {
		// unreachable
	}

	for(int i = 0 ; i < argc ; i++){
		if(
				strcmp(argv[i] , "--help") == 0 || 
				strcmp(argv[i] , "-h") == 0 ||
				strcmp(argv[i] , "/?") == 0 ||
				strcmp(argv[i] , "-help") == 0 ||
				strcmp(argv[i] , "/help") == 0 ||
				strcmp(argv[i] , "help") == 0
		  ){
			print_help(argv[0]);
			return 0;
		}
	}

	char* command = shift_args(argc - 1 , argv);
	if(command != NULL) {
		if(strcmp(command , "help") == 0) {
			print_help(argv[0]);
			return 0;
		} 
		/* else if(strcmp(command , "init") == 0) { */
		/* 	printf("Init command called\n"); */
		/* } else if(strcmp(command , "test") == 0) { */
		/* 	printf("Test command called\n"); */
		/* } */
	}

#ifdef ONE_FILE
	lua_State *L = luaL_newstate();
	if (L == NULL) {
		fprintf(stderr, "[RMP] failed creating Engine Lua state.\n");
		return 1;
	}

	luaL_openlibs(L);

	if (luaL_dostring(L , engine) != LUA_OK){
		fprintf(stderr, "[RMP] cannot execute Engine Lua code: %s\n", lua_tostring(L, -1));
		lua_pop(L, 1);
	}

	lua_close(L);
#else
	RMPRunner engine = RMPRunnerInit("./src/engine/RMPManager.lua");
	RMPRunnerError status = RMPRunnerRun(engine);
	if(status != RMP_FINE)
	{
		fprintf(stderr , "[LOG] error %s" , error);
	}
	RMPRunnerClose(&engine);
#endif
	return 0;
}

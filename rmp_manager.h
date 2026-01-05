/****************************************************************************************/
/*  RMP Manager - Header                                                                */
/*  Copyright (c) 2025 Ray Den                                                          */
/****************************************************************************************/

#ifndef RMP_MANAGER_H
#define RMP_MANAGER_H

#include <stdbool.h>
#include <stddef.h>

// Forward declaration of lua_State
struct lua_State;
typedef struct lua_State lua_State;

// Global error message accumulator
extern char error_message[4096];

// Forward declarations
typedef struct Component Component;
typedef struct Components Components;
typedef struct PlugManager PlugManager;
typedef struct TemplateParser TemplateParser;
typedef struct HashMap HashMap;
typedef struct Queue Queue;

// Component types
typedef enum {
    COMPONENT_WINDOW,
    COMPONENT_TEXT
} ComponentType;

// Component structure
typedef struct Component {
    int x;
    int y;
    int width;
    int height;
    void* foregroundColor;
    void* backgroundColor;
    ComponentType type;
    void* title;
    void** children;
    size_t children_count;
    char* id;
} Component;

// Components manager
typedef struct Components {
    void** temple_array;
    size_t temple_array_count;
    HashMap* components;
} Components;

// Plugin state
typedef struct PluginState {
    void* current;
    long last_switched;
} PluginState;

// Plugin manager
typedef struct PlugManager {
    HashMap* cfg_obj;
    HashMap* plugin_states;
} PlugManager;

// Template parser context
typedef struct ParserContext {
    int w;
    int h;
    int lw;
    int lh;
} ParserContext;

// Template parser
typedef struct TemplateParser {
    int* template_refs;
    size_t template_count;
    PlugManager* plug_manager;
    HashMap* window_cache;
    HashMap* plugin_cache;
    struct {
        int w;
        int h;
    } last_terminal_size;
} TemplateParser;

// Function pointers for callbacks
typedef void* (*PluginFunc)(int, int, int, int);
typedef void* (*DynamicFunc)(ParserContext*);
typedef bool (*ConditionFunc)(ParserContext*);
typedef void* (*ContentFunc)(int, int, int, int, ParserContext*);

// Component functions
Component* component_new(lua_State* L , int comp_ref);
void component_free(Component* comp);

// Components manager functions
Components* components_new(lua_State* L , int* temple_refs, size_t count);
void components_free(Components* comps);
void components_fill_hashmap(lua_State* L , Components* comps);
Component* components_get(Components* comps, const char* id);
void components_create(Components* comps, const char* id, Component* comp);
void components_update(Components* comps, const char* id, Component* new_comp);
void components_remove(Components* comps, const char* id);

// Plugin manager functions
PlugManager* plug_manager_new(HashMap* cfg_obj);
void plug_manager_free(PlugManager* pm);
int plug_manager_get_next(lua_State* L , PlugManager* pm, const char* id, char** error);
int plug_manager_get_switch_key(PlugManager* pm, const char* id);
PluginState* plug_manager_get_state(PlugManager* pm, const char* id);

// Template parser functions
TemplateParser* template_parser_new(int* template_refs, size_t count, PlugManager* pm);
void template_parser_free(TemplateParser* tp);
int template_parser_evaluate_expr(lua_State* L , TemplateParser* tp, const char* expr, ParserContext* ctx);
ParserContext template_parser_create_context(lua_State* L, TemplateParser* tp);
int template_parser_parse_text(lua_State* L , TemplateParser* tp, int text_ref, ParserContext* ctx);
int template_parser_create_window(lua_State* L , TemplateParser* tp, int window_ref, ParserContext* ctx);
int* template_parser_parse_template(lua_State* L, TemplateParser* tp, size_t* out_count);
HashMap* template_parser_get_switch_keys(lua_State* L, TemplateParser* tp);
void template_parser_update_plugin(lua_State* L, TemplateParser* tp, const char* window_id);
bool template_parser_was_resized(lua_State* L, TemplateParser* tp);

// Utility functions
void rmp_log_error(const char* err);
void rmp_log_note(const char* note);
void rmp_log_warn(const char* warn);

// Lua state management
void rmp_set_lua_state(lua_State* L);
lua_State* rmp_get_lua_state(void);

// Main engine functions
int setup_plugins(lua_State* L, int config_ref, bool is_userconfig, Queue** other_plugs, HashMap** plugs_cfgs);
bool run_rmp_application(
    lua_State* L,
    PlugManager* plug_manager,
    int* template_refs,
    size_t template_count,
    int settings_ref,
    Queue* other_plugs,
    int sound_cfg_ref,
    HashMap* plugs_cfgs,
    int config_ref,
    bool is_userconfig
);
int load_configuration(lua_State* L, int* out_template_ref, size_t* out_template_count, bool* out_is_userconfig);

// HashMap and Queue utilities
HashMap* hashmap_new(void);
void hashmap_free(HashMap* map);
void hashmap_put(HashMap* map, const char* key, void* value);
void* hashmap_get(HashMap* map, const char* key);
void hashmap_remove(HashMap* map, const char* key);

Queue* queue_new(void);
void queue_free(Queue* queue);
void queue_push(Queue* queue, void* value);
void* queue_pop(Queue* queue);
bool queue_is_empty(Queue* queue);

#endif // RMP_MANAGER_H

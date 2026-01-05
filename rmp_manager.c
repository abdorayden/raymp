/****************************************************************************************/
/*  RMP Manager - Implementation                                                        */
/*  Copyright (c) 2025 Ray Den                                                          */
/****************************************************************************************/

#include "rmp_manager.h"
#include "./src/engine/lua/include/lua.h"
#include "./src/engine/lua/include/lauxlib.h"
#include "./src/engine/lua/include/lualib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

char error_message[4096] = "";

// Logging functions
void rmp_log_error(const char* err) {
    char err_str[512];
    snprintf(err_str, sizeof(err_str), "RMP Error: %s\n", err);
    if (strstr(error_message, err_str) == NULL) {
        strncat(error_message, err_str, sizeof(error_message) - strlen(error_message) - 1);
    }
    fprintf(stderr, "%s", err_str);
}

void rmp_log_note(const char* note) {
    char note_str[512];
    snprintf(note_str, sizeof(note_str), "RMP Note: %s\n", note);
    if (strstr(error_message, note_str) == NULL) {
        strncat(error_message, note_str, sizeof(error_message) - strlen(error_message) - 1);
    }
    fprintf(stderr, "%s", note_str);
}

void rmp_log_warn(const char* warn) {
    char warn_str[512];
    snprintf(warn_str, sizeof(warn_str), "RMP Warning: %s\n", warn);
    if (strstr(error_message, warn_str) == NULL) {
        strncat(error_message, warn_str, sizeof(error_message) - strlen(error_message) - 1);
    }
    fprintf(stderr, "%s", warn_str);
}

// ============================================================================
// HashMap Implementation
// ============================================================================

#define HASHMAP_SIZE 128

typedef struct HashMapNode {
    char* key;
    void* value;
    struct HashMapNode* next;
} HashMapNode;

struct HashMap {
    HashMapNode* buckets[HASHMAP_SIZE];
};

static unsigned int hash_string(const char* str) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++)) {
        hash = ((hash << 5) + hash) + c;
    }
    return hash % HASHMAP_SIZE;
}

HashMap* hashmap_new(void) {
    HashMap* map = calloc(1, sizeof(HashMap));
    return map;
}

void hashmap_free(HashMap* map) {
    if (!map) return;
    for (int i = 0; i < HASHMAP_SIZE; i++) {
        HashMapNode* node = map->buckets[i];
        while (node) {
            HashMapNode* next = node->next;
            free(node->key);
            free(node);
            node = next;
        }
    }
    free(map);
}

void hashmap_put(HashMap* map, const char* key, void* value) {
    if (!map || !key) return;
    
    unsigned int idx = hash_string(key);
    HashMapNode* node = map->buckets[idx];
    
    while (node) {
        if (strcmp(node->key, key) == 0) {
            node->value = value;
            return;
        }
        node = node->next;
    }
    
    HashMapNode* new_node = malloc(sizeof(HashMapNode));
    new_node->key = strdup(key);
    new_node->value = value;
    new_node->next = map->buckets[idx];
    map->buckets[idx] = new_node;
}

void* hashmap_get(HashMap* map, const char* key) {
    if (!map || !key) return NULL;
    
    unsigned int idx = hash_string(key);
    HashMapNode* node = map->buckets[idx];
    
    while (node) {
        if (strcmp(node->key, key) == 0) {
            return node->value;
        }
        node = node->next;
    }
    return NULL;
}

void hashmap_remove(HashMap* map, const char* key) {
    if (!map || !key) return;
    
    unsigned int idx = hash_string(key);
    HashMapNode* node = map->buckets[idx];
    HashMapNode* prev = NULL;
    
    while (node) {
        if (strcmp(node->key, key) == 0) {
            if (prev) {
                prev->next = node->next;
            } else {
                map->buckets[idx] = node->next;
            }
            free(node->key);
            free(node);
            return;
        }
        prev = node;
        node = node->next;
    }
}

// ============================================================================
// Queue Implementation
// ============================================================================

typedef struct QueueNode {
    void* value;
    struct QueueNode* next;
} QueueNode;

struct Queue {
    QueueNode* head;
    QueueNode* tail;
    size_t size;
};

Queue* queue_new(void) {
    Queue* q = calloc(1, sizeof(Queue));
    return q;
}

void queue_free(Queue* queue) {
    if (!queue) return;
    QueueNode* node = queue->head;
    while (node) {
        QueueNode* next = node->next;
        free(node);
        node = next;
    }
    free(queue);
}

void queue_push(Queue* queue, void* value) {
    if (!queue) return;
    
    QueueNode* node = malloc(sizeof(QueueNode));
    node->value = value;
    node->next = NULL;
    
    if (queue->tail) {
        queue->tail->next = node;
    } else {
        queue->head = node;
    }
    queue->tail = node;
    queue->size++;
}

void* queue_pop(Queue* queue) {
    if (!queue || !queue->head) return NULL;
    
    QueueNode* node = queue->head;
    void* value = node->value;
    queue->head = node->next;
    
    if (!queue->head) {
        queue->tail = NULL;
    }
    
    free(node);
    queue->size--;
    return value;
}

bool queue_is_empty(Queue* queue) {
    return !queue || queue->size == 0;
}

// ============================================================================
// Lua Helper Functions
// ============================================================================

static void lua_get_terminal_size(lua_State* L, int* h, int* w) {
    if (!L) {
        *h = 24;
        *w = 80;
        return;
    }

    lua_getglobal(L, "api");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        *h = 24;
        *w = 80;
        return;
    }

    lua_getfield(L, -1, "Terminal");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 2);
        *h = 24;
        *w = 80;
        return;
    }

    lua_getfield(L, -1, "getSize");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 3);
        *h = 24;
        *w = 80;
        return;
    }

    if (lua_pcall(L, 0, 2, 0) == LUA_OK) {
        *h = lua_tointeger(L, -2);
        *w = lua_tointeger(L, -1);
        lua_pop(L, 4);
    } else {
        lua_pop(L, 4);
        *h = 24;
        *w = 80;
    }
}

static int lua_handle_key(lua_State* L) {
    if (!L) return 0;

    lua_getglobal(L, "api");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return 0;
    }

    lua_getfield(L, -1, "Terminal");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 2);
        return 0;
    }

    lua_getfield(L, -1, "handleKey");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 3);
        return 0;
    }

    if (lua_pcall(L, 0, 1, 0) == LUA_OK) {
        int key = lua_tointeger(L, -1);
        lua_pop(L, 3);
        return key;
    }
    
    lua_pop(L, 3);
    return 0;
}

static void lua_main_frame_clear(lua_State* L) {
    if (!L) return;

    lua_getglobal(L, "mainFrame");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "clear");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    
    if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_main_frame_resize(lua_State* L, int w, int h) {
    if (!L) return;

    lua_getglobal(L, "mainFrame");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "resize");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    lua_pushinteger(L, w);
    lua_pushinteger(L, h);
    
    if (lua_pcall(L, 3, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_main_frame_add(lua_State* L, int window_ref, bool merge) {
    if (!L || window_ref == LUA_NOREF || window_ref == LUA_REFNIL) return;

    lua_getglobal(L, "mainFrame");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "add");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    lua_rawgeti(L, LUA_REGISTRYINDEX, window_ref);
    lua_pushboolean(L, merge);
    
    if (lua_pcall(L, 3, 0, 0) != LUA_OK) {
        fprintf(stderr, "Error adding window to mainFrame: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_main_frame_run(lua_State* L, int key, int sound_ref, HashMap* plugs_cfgs, int template_ref) {
    if (!L) return;

    lua_getglobal(L, "mainFrame");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "run");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    lua_pushinteger(L, key);
    lua_pushnil(L);
    
    if (sound_ref != LUA_NOREF && sound_ref != LUA_REFNIL) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, sound_ref);
    } else {
        lua_pushnil(L);
    }
    
    lua_pushlightuserdata(L, plugs_cfgs);
    
    if (template_ref != LUA_NOREF && template_ref != LUA_REFNIL) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, template_ref);
    } else {
        lua_pushnil(L);
    }
    
    if (lua_pcall(L, 6, 0, 0) != LUA_OK) {
        fprintf(stderr, "Error in mainFrame:run: %s\n", lua_tostring(L, -1));
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_main_frame_init(lua_State* L) {
    if (!L) return;

    lua_getglobal(L, "mainFrame");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "initMainFrame");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    
    if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_main_frame_set_fps(lua_State* L, int fps) {
    if (!L) return;

    lua_getglobal(L, "mainFrame");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "setFps");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    lua_pushinteger(L, fps);
    
    if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static int lua_create_sound(lua_State* L) {
    if (!L) return LUA_NOREF;

    lua_getglobal(L, "api");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return LUA_NOREF;
    }
    
    lua_getfield(L, -1, "Sound");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 2);
        return LUA_NOREF;
    }
    
    lua_getfield(L, -1, "new");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 3);
        return LUA_NOREF;
    }
    
    if (lua_pcall(L, 0, 1, 0) == LUA_OK) {
        int ref = luaL_ref(L, LUA_REGISTRYINDEX);
        lua_pop(L, 2);
        return ref;
    }
    
    lua_pop(L, 3);
    return LUA_NOREF;
}

static void lua_sound_set_volume(lua_State* L, int sound_ref, float volume) {
    if (!L || sound_ref == LUA_NOREF || sound_ref == LUA_REFNIL) return;

    lua_rawgeti(L, LUA_REGISTRYINDEX, sound_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "setVolume");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    lua_pushnumber(L, volume);
    
    if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_sound_update(lua_State* L, int sound_ref) {
    if (!L || sound_ref == LUA_NOREF || sound_ref == LUA_REFNIL) return;

    lua_rawgeti(L, LUA_REGISTRYINDEX, sound_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "update");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    
    if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_sound_cleanup(lua_State* L, int sound_ref) {
    if (!L || sound_ref == LUA_NOREF || sound_ref == LUA_REFNIL) return;

    lua_rawgeti(L, LUA_REGISTRYINDEX, sound_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    lua_getfield(L, -1, "cleanup");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return;
    }
    
    lua_pushvalue(L, -2);
    
    if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
    
    luaL_unref(L, LUA_REGISTRYINDEX, sound_ref);
}

// ============================================================================
// Component Implementation
// ============================================================================

Component* component_new(lua_State* L, int comp_ref) {
    if (!L || comp_ref == LUA_NOREF || comp_ref == LUA_REFNIL) return NULL;

    Component* comp = calloc(1, sizeof(Component));
    
    lua_rawgeti(L, LUA_REGISTRYINDEX, comp_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        free(comp);
        return NULL;
    }
    
    lua_getfield(L, -1, "x");
    if (lua_isnumber(L, -1)) {
        comp->x = lua_tointeger(L, -1);
    }
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "y");
    if (lua_isnumber(L, -1)) {
        comp->y = lua_tointeger(L, -1);
    }
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "width");
    if (lua_isnumber(L, -1)) {
        comp->width = lua_tointeger(L, -1);
    }
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "height");
    if (lua_isnumber(L, -1)) {
        comp->height = lua_tointeger(L, -1);
    }
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "id");
    if (lua_isstring(L, -1)) {
        comp->id = strdup(lua_tostring(L, -1));
    }
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "type");
    const char* type = lua_tostring(L, -1);
    if (type && strcmp(type, "Window") == 0) {
        comp->type = COMPONENT_WINDOW;
    } else {
        comp->type = COMPONENT_TEXT;
    }
    lua_pop(L, 2);
    
    return comp;
}

void component_free(Component* comp) {
    if (!comp) return;
    if (comp->id) free(comp->id);
    if (comp->children) free(comp->children);
    free(comp);
}

// ============================================================================
// Components Manager Implementation
// ============================================================================

Components* components_new(lua_State* L, int* temple_refs, size_t count) {
    Components* comps = malloc(sizeof(Components));
    comps->temple_array = (void**)temple_refs;
    comps->temple_array_count = count;
    comps->components = hashmap_new();
    components_fill_hashmap(L, comps);
    return comps;
}

void components_free(Components* comps) {
    if (!comps) return;
    hashmap_free(comps->components);
    free(comps);
}

void components_fill_hashmap(lua_State* L, Components* comps) {
    if (!comps || !L) return;
    
    for (size_t i = 0; i < comps->temple_array_count; i++) {
        int ref = ((int*)comps->temple_array)[i];
        Component* comp = component_new(L, ref);
        if (comp && comp->id) {
            hashmap_put(comps->components, comp->id, comp);
        }
    }
}

Component* components_get(Components* comps, const char* id) {
    if (!comps || !id) return NULL;
    return (Component*)hashmap_get(comps->components, id);
}

void components_create(Components* comps, const char* id, Component* comp) {
    if (!comps || !id || !comp) return;
    hashmap_put(comps->components, id, comp);
}

void components_update(Components* comps, const char* id, Component* new_comp) {
    if (!comps || !id) return;
    Component* comp = components_get(comps, id);
    if (comp && new_comp) {
        comp->x = new_comp->x;
        comp->y = new_comp->y;
        comp->width = new_comp->width;
        comp->height = new_comp->height;
    }
}

void components_remove(Components* comps, const char* id) {
    if (!comps || !id) return;
    Component* comp = components_get(comps, id);
    if (comp) {
        hashmap_remove(comps->components, id);
        component_free(comp);
    }
}

// ============================================================================
// Plugin Manager Implementation
// ============================================================================

PlugManager* plug_manager_new(HashMap* cfg_obj) {
    PlugManager* pm = malloc(sizeof(PlugManager));
    pm->cfg_obj = cfg_obj;
    pm->plugin_states = hashmap_new();
    return pm;
}

void plug_manager_free(PlugManager* pm) {
    if (!pm) return;
    hashmap_free(pm->plugin_states);
    free(pm);
}

int plug_manager_get_next(lua_State* L, PlugManager* pm, const char* id, char** error) {
    if (!pm || !id || !L) {
        if (error) *error = "Invalid parameters";
        return LUA_NOREF;
    }
    
    int* plug_data = (int*)hashmap_get(pm->cfg_obj, id);
    if (!plug_data) {
        if (error) {
            static char err_buf[256];
            snprintf(err_buf, sizeof(err_buf), "No plugins for window %s", id);
            *error = err_buf;
        }
        return LUA_NOREF;
    }
    
    int queue_ref = plug_data[1];
    
    lua_rawgeti(L, LUA_REGISTRYINDEX, queue_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        if (error) *error = "Invalid queue";
        return LUA_NOREF;
    }
    
    lua_getfield(L, -1, "pop");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        if (error) *error = "Invalid queue methods";
        return LUA_NOREF;
    }
    
    lua_pushvalue(L, -2);
    
    if (lua_pcall(L, 1, 1, 0) != LUA_OK) {
        lua_pop(L, 2);
        if (error) *error = "Queue pop failed";
        return LUA_NOREF;
    }
    
    int plugin_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    
    lua_getfield(L, -1, "push");
    lua_pushvalue(L, -2);
    lua_rawgeti(L, LUA_REGISTRYINDEX, plugin_ref);
    lua_pcall(L, 2, 0, 0);
    
    lua_pop(L, 1);
    
    if (error) *error = NULL;
    return plugin_ref;
}

int plug_manager_get_switch_key(PlugManager* pm, const char* id) {
    if (!pm || !id) return LUA_NOREF;
    
    int* plug_data = (int*)hashmap_get(pm->cfg_obj, id);
    if (!plug_data) return LUA_NOREF;
    
    return plug_data[0];
}

PluginState* plug_manager_get_state(PlugManager* pm, const char* id) {
    if (!pm || !id) return NULL;
    return (PluginState*)hashmap_get(pm->plugin_states, id);
}

// ============================================================================
// Template Parser Implementation
// ============================================================================

TemplateParser* template_parser_new(int* template_refs, size_t count, PlugManager* pm) {
    TemplateParser* tp = malloc(sizeof(TemplateParser));
    tp->template_refs = template_refs;
    tp->template_count = count;
    tp->plug_manager = pm;
    tp->window_cache = hashmap_new();
    tp->plugin_cache = hashmap_new();
    tp->last_terminal_size.w = 0;
    tp->last_terminal_size.h = 0;
    return tp;
}

void template_parser_free(TemplateParser* tp) {
    if (!tp) return;
    hashmap_free(tp->window_cache);
    hashmap_free(tp->plugin_cache);
    if (tp->template_refs) free(tp->template_refs);
    free(tp);
}

int template_parser_evaluate_expr(lua_State* L, TemplateParser* tp, const char* expr, ParserContext* ctx) {
    if (!expr || !ctx || !L) return 1;
    
    char lua_expr[512];
    snprintf(lua_expr, sizeof(lua_expr), 
        "local w, h, lw, lh = %d, %d, %d, %d; return math.floor(%s)",
        ctx->w, ctx->h, ctx->lw, ctx->lh, expr);
    
    if (luaL_dostring(L, lua_expr) == LUA_OK) {
        int result = lua_tointeger(L, -1);
        lua_pop(L, 1);
        return result;
    }
    
    lua_pop(L, 1);
    return 1;
}

ParserContext template_parser_create_context(lua_State* L, TemplateParser* tp) {
    ParserContext ctx;
    lua_get_terminal_size(L, &ctx.h, &ctx.w);
    ctx.lw = ctx.w - 1;
    ctx.lh = ctx.h - 1;
    return ctx;
}

int template_parser_parse_text(lua_State* L, TemplateParser* tp, int text_ref, ParserContext* ctx) {
    if (!L || text_ref == LUA_NOREF || text_ref == LUA_REFNIL) return LUA_NOREF;
    
    lua_getglobal(L, "api");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return LUA_NOREF;
    }
    
    lua_getfield(L, -1, "Text");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 2);
        return LUA_NOREF;
    }
    
    lua_getfield(L, -1, "new");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 3);
        return LUA_NOREF;
    }
    
    lua_rawgeti(L, LUA_REGISTRYINDEX, text_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 4);
        return LUA_NOREF;
    }
    
    lua_getfield(L, -1, "value");
    lua_getfield(L, -2, "style");
    lua_getfield(L, -3, "foregroundColor");
    lua_getfield(L, -4, "backgroundColor");
    
    if (lua_pcall(L, 4, 1, 0) == LUA_OK) {
        int result = luaL_ref(L, LUA_REGISTRYINDEX);
        lua_pop(L, 4);
        return result;
    }
    
    lua_pop(L, 4);
    return LUA_NOREF;
}

// CRITICAL FIX: Create window with proper plugin execution
int template_parser_create_window(lua_State* L, TemplateParser* tp, int window_ref, ParserContext* ctx) {
    if (!L || window_ref == LUA_NOREF || window_ref == LUA_REFNIL) return LUA_NOREF;
    
    lua_rawgeti(L, LUA_REGISTRYINDEX, window_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return LUA_NOREF;
    }
    
    // Get window ID first - this is crucial for plugin lookup
    lua_getfield(L, -1, "id");
    const char* window_id = NULL;
    if (lua_isstring(L, -1)) {
        window_id = lua_tostring(L, -1);
    }
    lua_pop(L, 1);
    
    // Evaluate dimensions
    lua_getfield(L, -1, "width");
    const char* width_expr = lua_tostring(L, -1);
    int width = template_parser_evaluate_expr(L, tp, width_expr, ctx);
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "height");
    const char* height_expr = lua_tostring(L, -1);
    int height = template_parser_evaluate_expr(L, tp, height_expr, ctx);
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "x");
    const char* x_expr = lua_tostring(L, -1);
    int x = template_parser_evaluate_expr(L, tp, x_expr, ctx);
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "y");
    const char* y_expr = lua_tostring(L, -1);
    int y = template_parser_evaluate_expr(L, tp, y_expr, ctx);
    lua_pop(L, 1);
    
    // CRITICAL: Get or create plugin for this window
    int plugin_ref = LUA_NOREF;
    if (window_id && tp->plug_manager) {
        // Check cache first
        plugin_ref = (int)(intptr_t)hashmap_get(tp->plugin_cache, window_id);
        
        // If not cached, get from plugin manager
        if (plugin_ref == 0 || plugin_ref == LUA_NOREF) {
            char* error = NULL;
            plugin_ref = plug_manager_get_next(L, tp->plug_manager, window_id, &error);
            if (plugin_ref != LUA_NOREF && !error) {
                hashmap_put(tp->plugin_cache, window_id, (void*)(intptr_t)plugin_ref);
            }
        }
    }
    
    // Get title if exists
    lua_getfield(L, -1, "title");
    int title_ref = LUA_NOREF;
    if (lua_istable(L, -1)) {
        lua_pushvalue(L, -1);
        title_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    lua_pop(L, 1);
    
    // Get other window properties
    lua_getfield(L, -1, "border");
    bool border = lua_toboolean(L, -1);
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "foregroundColor");
    lua_pushvalue(L, -1);
    int fg_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "backgroundColor");
    lua_pushvalue(L, -1);
    int bg_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pop(L, 1);
    
    // Create the window using Lua API
    lua_getglobal(L, "api");
    lua_getfield(L, -1, "Window");
    lua_getfield(L, -1, "new");
    
    if (window_id) {
        lua_pushstring(L, window_id);
    } else {
        lua_pushnil(L);
    }
    
    if (lua_pcall(L, 1, 1, 0) != LUA_OK) {
        fprintf(stderr, "Failed to create window: %s\n", lua_tostring(L, -1));
        lua_pop(L, 4);
        return LUA_NOREF;
    }
    
    // Now we have the window object on stack
    // Call createWindow method
    lua_getfield(L, -1, "createWindow");
    lua_pushvalue(L, -2); // Push window object as self
    
    // Push title
    if (title_ref != LUA_NOREF) {
        int parsed_title = template_parser_parse_text(L, tp, title_ref, ctx);
        if (parsed_title != LUA_NOREF) {
            lua_rawgeti(L, LUA_REGISTRYINDEX, parsed_title);
            luaL_unref(L, LUA_REGISTRYINDEX, parsed_title);
        } else {
            lua_pushnil(L);
        }
        luaL_unref(L, LUA_REGISTRYINDEX, title_ref);
    } else {
        lua_pushnil(L);
    }
    
    // Push dimensions
    lua_pushinteger(L, width);
    lua_pushinteger(L, height);
    lua_pushinteger(L, x);
    lua_pushinteger(L, y);
    
    // Push colors
    if (fg_ref != LUA_NOREF) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, fg_ref);
        luaL_unref(L, LUA_REGISTRYINDEX, fg_ref);
    } else {
        lua_pushnil(L);
    }
    
    if (bg_ref != LUA_NOREF) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, bg_ref);
        luaL_unref(L, LUA_REGISTRYINDEX, bg_ref);
    } else {
        lua_pushnil(L);
    }
    
    lua_pushboolean(L, border);
    
    // CRITICAL: Create callback that executes plugin
    // Push a Lua function that will be called to render window content
    lua_pushstring(L, 
        "return function(innerX, innerY, innerXX, innerYY)\n"
        "    local childVterm = api.VirtualTerminal.new()\n"
        "    return childVterm\n"
        "end"
    );
    
    if (luaL_dostring(L, lua_tostring(L, -1)) == LUA_OK) {
        // Function is on stack, but we need to inject plugin call
        if (plugin_ref != LUA_NOREF && plugin_ref != 0) {
            // Create wrapper that calls plugin
            lua_rawgeti(L, LUA_REGISTRYINDEX, plugin_ref);
            
            // Create closure that captures plugin
            const char* wrapper = 
                "local plugin = ...\n"
                "return function(innerX, innerY, innerXX, innerYY)\n"
                "    local childVterm = api.VirtualTerminal.new()\n"
                "    if plugin and type(plugin) == 'function' then\n"
                "        local pluginResult = plugin(innerX, innerY, innerXX, innerYY)\n"
                "        if pluginResult then\n"
                "            childVterm:merge(pluginResult, true)\n"
                "        end\n"
                "    end\n"
                "    return childVterm\n"
                "end";
            
            if (luaL_loadstring(L, wrapper) == LUA_OK) {
                lua_pushvalue(L, -2); // Push plugin ref
                if (lua_pcall(L, 1, 1, 0) == LUA_OK) {
                    // Now we have the wrapper function
                    lua_remove(L, -2); // Remove plugin ref
                    lua_remove(L, -2); // Remove original callback string
                }
            }
        }
    } else {
        lua_pop(L, 1);
        lua_pushnil(L); // Fallback to nil callback
    }
    
    // Call createWindow with all parameters
    if (lua_pcall(L, 11, 1, 0) != LUA_OK) {
        fprintf(stderr, "Failed to call createWindow: %s\n", lua_tostring(L, -1));
        lua_pop(L, 4);
        return LUA_NOREF;
    }
    
    // Store result
    int result = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pop(L, 3); // Pop api, Window, and window_ref from original stack
    
    return result;
}

int* template_parser_parse_template(lua_State* L, TemplateParser* tp, size_t* out_count) {
    if (!tp || !L) {
        *out_count = 0;
        return NULL;
    }

    if (!tp->template_refs || tp->template_count == 0) {
        *out_count = 0;
        return NULL;
    }

    ParserContext ctx = template_parser_create_context(L, tp);

    int* windows = calloc(tp->template_count, sizeof(int));
    size_t window_count = 0;

    // CRITICAL FIX: Actually create windows with plugin execution
    for (size_t i = 0; i < tp->template_count; i++) {
        int window_ref = tp->template_refs[i];
        
        // Check if this is a Window type
        lua_rawgeti(L, LUA_REGISTRYINDEX, window_ref);
        if (lua_istable(L, -1)) {
            lua_getfield(L, -1, "type");
            const char* type = lua_tostring(L, -1);
            lua_pop(L, 1);
            
            if (type && strcmp(type, "Window") == 0) {
                int window = template_parser_create_window(L, tp, window_ref, &ctx);
                if (window != LUA_NOREF && window != LUA_REFNIL) {
                    windows[window_count++] = window;
                }
            }
        }
        lua_pop(L, 1);
    }

    *out_count = window_count;
    return windows;
}

HashMap* template_parser_get_switch_keys(lua_State* L, TemplateParser* tp) {
    if (!tp || !tp->plug_manager || !L) return NULL;
    
    HashMap* switch_keys = hashmap_new();
    
    for (size_t i = 0; i < tp->template_count; i++) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, tp->template_refs[i]);
        if (lua_istable(L, -1)) {
            lua_getfield(L, -1, "id");
            
            if (lua_isstring(L, -1)) {
                const char* id = lua_tostring(L, -1);
                int key = plug_manager_get_switch_key(tp->plug_manager, id);
                if (key != LUA_NOREF && key != LUA_REFNIL) {
                    hashmap_put(switch_keys, id, (void*)(intptr_t)key);
                }
            }
            lua_pop(L, 1);
        }
        lua_pop(L, 1);
    }
    
    return switch_keys;
}

void template_parser_update_plugin(lua_State* L, TemplateParser* tp, const char* window_id) {
    if (!tp || !tp->plug_manager || !window_id) return;
    
    char* error = NULL;
    int plugin = plug_manager_get_next(L, tp->plug_manager, window_id, &error);
    if (plugin != LUA_NOREF && plugin != LUA_REFNIL && !error) {
        hashmap_put(tp->plugin_cache, window_id, (void*)(intptr_t)plugin);
    }
}

bool template_parser_was_resized(lua_State* L, TemplateParser* tp) {
    if (!tp) return false;

    int h, w;
    lua_get_terminal_size(L, &h, &w);

    if (w != tp->last_terminal_size.w || h != tp->last_terminal_size.h) {
        tp->last_terminal_size.w = w;
        tp->last_terminal_size.h = h;
        return true;
    }
    return false;
}

// ============================================================================
// Main Engine Functions - FIXED
// ============================================================================

int setup_plugins(lua_State* L, int config_ref, bool is_userconfig, Queue** other_plugs, HashMap** plugs_cfgs) {
    if (!L || config_ref == LUA_NOREF || config_ref == LUA_REFNIL) return LUA_NOREF;

    HashMap* plugs = hashmap_new();
    *other_plugs = queue_new();
    *plugs_cfgs = hashmap_new();

    lua_rawgeti(L, LUA_REGISTRYINDEX, config_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        rmp_log_error("Invalid config object");
        return LUA_NOREF;
    }

    lua_getfield(L, -1, "plugins");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 2);
        rmp_log_error("Invalid plugins configuration.");
        return LUA_NOREF;
    }

    size_t plugin_count = lua_rawlen(L, -1);

    for (size_t i = 1; i <= plugin_count; i++) {
        lua_rawgeti(L, -1, i);

        if (!lua_istable(L, -1)) {
            lua_pop(L, 1);
            continue;
        }

        lua_getfield(L, -1, "isActivated");
        bool is_activated = lua_toboolean(L, -1);
        lua_pop(L, 1);

        if (!is_activated) {
            lua_pop(L, 1);
            continue;
        }

        lua_getfield(L, -1, "themeWindowId");
        const char* window_id = NULL;
        if (lua_isstring(L, -1)) {
            window_id = strdup(lua_tostring(L, -1));
        }
        lua_pop(L, 1);

        // Get switch key - store the actual integer value, not a ref
        lua_getfield(L, -1, "switchPluginKey");
        int switch_key = 0;
        if (lua_isnumber(L, -1)) {
            switch_key = lua_tointeger(L, -1);
        }
        lua_pop(L, 1);

        // Get plugin names
        lua_getfield(L, -1, "names");
        if (lua_istable(L, -1)) {
            size_t name_count = lua_rawlen(L, -1);
            
            if (window_id) {
                // Plugin attached to a window
                // Create queue for this window's plugins
                lua_getglobal(L, "utils");
                lua_getfield(L, -1, "Queue");
                lua_getfield(L, -1, "new");
                
                if (lua_pcall(L, 0, 1, 0) == LUA_OK) {
                    int queue_ref = luaL_ref(L, LUA_REGISTRYINDEX);
                    lua_pop(L, 2); // Pop utils and Queue
                    
                    // Load each plugin and add to queue
                    for (size_t j = 1; j <= name_count; j++) {
                        lua_rawgeti(L, -1, j);
                        
                        const char* plugin_name = NULL;
                        int* plugin_config = NULL;
                        
                        // Check if it's a string or table {name, config}
                        if (lua_isstring(L, -1)) {
                            plugin_name = lua_tostring(L, -1);
                        } else if (lua_istable(L, -1)) {
                            lua_rawgeti(L, -1, 1);
                            if (lua_isstring(L, -1)) {
                                plugin_name = lua_tostring(L, -1);
                            }
                            lua_pop(L, 1);
                            
                            lua_rawgeti(L, -1, 2);
                            if (lua_istable(L, -1)) {
                                int cfg_ref = luaL_ref(L, LUA_REGISTRYINDEX);
                                plugin_config = malloc(sizeof(int));
                                *plugin_config = cfg_ref;
                            } else {
                                lua_pop(L, 1);
                            }
                        }
                        
                        if (plugin_name) {
                            // Try to load plugin
                            char require_str[1024];
                            if (is_userconfig) {
                                snprintf(require_str, sizeof(require_str),
                                    "local hp = api.Path.new():getHomePath(); "
                                    "local ok, plug = pcall(dofile, hp .. '/.rmp/plugins/%s.lua'); "
                                    "if not ok then ok, plug = pcall(dofile, hp .. '/.rmp/plugins/%s/init.lua') end; "
                                    "if ok and plug then return plug else return nil end",
                                    plugin_name, plugin_name);
                            } else {
                                snprintf(require_str, sizeof(require_str),
                                    "local ok, plug = pcall(require, 'rmp.selfrmp.plugins.%s'); "
                                    "if ok and plug then return plug else return nil end",
                                    plugin_name);
                            }
                            
                            if (luaL_dostring(L, require_str) == LUA_OK && !lua_isnil(L, -1)) {
                                int plugin_func_ref = luaL_ref(L, LUA_REGISTRYINDEX);
                                
                                // Add to queue
                                lua_rawgeti(L, LUA_REGISTRYINDEX, queue_ref);
                                lua_getfield(L, -1, "push");
                                lua_pushvalue(L, -2);
                                lua_rawgeti(L, LUA_REGISTRYINDEX, plugin_func_ref);
                                
                                if (lua_pcall(L, 2, 0, 0) != LUA_OK) {
                                    fprintf(stderr, "Error pushing plugin to queue: %s\n", lua_tostring(L, -1));
                                    lua_pop(L, 1);
                                }
                                lua_pop(L, 1); // Pop queue
                                
                                hashmap_put(*plugs_cfgs, strdup(plugin_name), plugin_config);
                                printf("[RMP] Loaded plugin: %s for window: %s\n", plugin_name, window_id);
                            } else {
                                if (!lua_isnil(L, -1)) {
                                    fprintf(stderr, "Failed to load plugin %s: %s\n", plugin_name, lua_tostring(L, -1));
                                }
                                lua_pop(L, 1);
                                rmp_log_warn("Could not load plugin");
                            }
                        }
                        lua_pop(L, 1); // Pop name element
                    }
                    
                    // Store switch key and queue for this window
                    int* plug_data = malloc(2 * sizeof(int));
                    plug_data[0] = switch_key;
                    plug_data[1] = queue_ref;
                    hashmap_put(plugs, strdup(window_id), plug_data);
                }
            } else {
                // Global plugin (no window ID)
                for (size_t j = 1; j <= name_count; j++) {
                    lua_rawgeti(L, -1, j);
                    
                    const char* plugin_name = NULL;
                    int* plugin_config = NULL;
                    
                    if (lua_isstring(L, -1)) {
                        plugin_name = lua_tostring(L, -1);
                    } else if (lua_istable(L, -1)) {
                        lua_rawgeti(L, -1, 1);
                        if (lua_isstring(L, -1)) {
                            plugin_name = lua_tostring(L, -1);
                        }
                        lua_pop(L, 1);
                        
                        lua_rawgeti(L, -1, 2);
                        if (lua_istable(L, -1)) {
                            int cfg_ref = luaL_ref(L, LUA_REGISTRYINDEX);
                            plugin_config = malloc(sizeof(int));
                            *plugin_config = cfg_ref;
                        } else {
                            lua_pop(L, 1);
                        }
                    }
                    
                    if (plugin_name) {
                        char require_str[1024];
                        if (is_userconfig) {
                            snprintf(require_str, sizeof(require_str),
                                "local hp = api.Path.new():getHomePath(); "
                                "local ok, plug = pcall(dofile, hp .. '/.rmp/plugins/%s.lua'); "
                                "if not ok then ok, plug = pcall(dofile, hp .. '/.rmp/plugins/%s/init.lua') end; "
                                "if ok and plug then return plug else return nil end",
                                plugin_name, plugin_name);
                        } else {
                            snprintf(require_str, sizeof(require_str),
                                "local ok, plug = pcall(require, 'rmp.selfrmp.plugins.%s'); "
                                "if ok and plug then return plug else return nil end",
                                plugin_name);
                        }
                        
                        if (luaL_dostring(L, require_str) == LUA_OK && !lua_isnil(L, -1)) {
                            int plugin_func_ref = luaL_ref(L, LUA_REGISTRYINDEX);
                            queue_push(*other_plugs, (void*)(intptr_t)plugin_func_ref);
                            hashmap_put(*plugs_cfgs, strdup(plugin_name), plugin_config);
                            printf("[RMP] Loaded global plugin: %s\n", plugin_name);
                        } else {
                            if (!lua_isnil(L, -1)) {
                                fprintf(stderr, "Failed to load global plugin %s: %s\n", plugin_name, lua_tostring(L, -1));
                            }
                            lua_pop(L, 1);
                        }
                    }
                    lua_pop(L, 1); // Pop name element
                }
            }
        }
        lua_pop(L, 1); // Pop names table
        
        lua_pop(L, 1); // Pop plugin config
        if (window_id) free((void*)window_id);
    }

    lua_pop(L, 2); // Pop plugins and config tables

    // Create PlugManager and return its ref
    PlugManager* pm = plug_manager_new(plugs);
    lua_pushlightuserdata(L, pm);
    int pm_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    
    return pm_ref;
}

// Helper function to render help screen
static void engine_render_help(lua_State* L, int w, int h, int settings_ref, int sound_cfg_ref) {
    if (!L) return;
    
    // Get keys from settings and sound config
    int help_key = 0, exit_key = 0;
    int pause_key = 0, resume_key = 0, next_key = 0, prev_key = 0;
    int vol_up = 0, vol_down = 0, seek_left = 0, seek_right = 0;
    int speed_up = 0, speed_down = 0, change_mode = 0;
    
    // Get settings keys
    if (settings_ref != LUA_NOREF && settings_ref != LUA_REFNIL) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, settings_ref);
        if (lua_istable(L, -1)) {
            lua_getfield(L, -1, "help_key");
            if (lua_isnumber(L, -1)) help_key = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "exit");
            if (lua_isnumber(L, -1)) exit_key = lua_tointeger(L, -1);
            lua_pop(L, 1);
        }
        lua_pop(L, 1);
    }
    
    // Get sound config keys
    if (sound_cfg_ref != LUA_NOREF && sound_cfg_ref != LUA_REFNIL) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, sound_cfg_ref);
        if (lua_istable(L, -1)) {
            lua_getfield(L, -1, "pause_sound");
            if (lua_isnumber(L, -1)) pause_key = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "resume_sound");
            if (lua_isnumber(L, -1)) resume_key = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "next_sound");
            if (lua_isnumber(L, -1)) next_key = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "prev_sound");
            if (lua_isnumber(L, -1)) prev_key = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "vol_up");
            if (lua_isnumber(L, -1)) vol_up = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "vol_down");
            if (lua_isnumber(L, -1)) vol_down = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "seek_left");
            if (lua_isnumber(L, -1)) seek_left = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "seek_right");
            if (lua_isnumber(L, -1)) seek_right = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "speed_up");
            if (lua_isnumber(L, -1)) speed_up = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "speed_down");
            if (lua_isnumber(L, -1)) speed_down = lua_tointeger(L, -1);
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "change_playback_mode");
            if (lua_isnumber(L, -1)) change_mode = lua_tointeger(L, -1);
            lua_pop(L, 1);
        }
        lua_pop(L, 1);
    }
    
    // Get mainFrame
    lua_getglobal(L, "mainFrame");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return;
    }
    
    // Create help text using Lua script
    const char* help_script = 
        "local mainFrame, w, h, help_key, exit_key, pause_key, resume_key, next_key, prev_key, vol_up, vol_down, seek_left, seek_right, speed_up, speed_down, change_mode = ...\n"
        "local api = require('rmp.rmp')\n"
        "local function ktc(k)\n"
        "    if k == 0 then return 'N/A' end\n"
        "    local keyMap = {\n"
        "        [api.KEY_RIGHT] = '<right>',\n"
        "        [api.KEY_LEFT] = '<left>',\n"
        "        [api.KEY_UP] = '<up>',\n"
        "        [api.KEY_DOWN] = '<down>',\n"
        "        [api.KEY_SPACE] = '<space>',\n"
        "        [api.KEY_TAB] = '<tab>',\n"
        "        [api.KEY_PLUS] = '<plus>',\n"
        "        [api.KEY_MINUS] = '<minus>',\n"
        "        [api.KEY_Q] = 'q',\n"
        "        [api.KEY_N] = 'n',\n"
        "        [api.KEY_P] = 'p',\n"
        "    }\n"
        "    return keyMap[k] or api.Input.new():keyToChar(k)\n"
        "end\n"
        "local helpText = {\n"
        "    'RMP Help:',\n"
        "    '-------------',\n"
        "    'General Controls:',\n"
        "    '  ' .. ktc(help_key) .. ' : Show Help',\n"
        "    '  ' .. ktc(exit_key) .. ' : Quit Application',\n"
        "    '',\n"
        "    'Sound Controls:',\n"
        "    '  ' .. ktc(pause_key) .. ': Pause',\n"
        "    '  ' .. ktc(resume_key) .. ': Resume',\n"
        "    '  ' .. ktc(next_key) .. ': Next Track',\n"
        "    '  ' .. ktc(prev_key) .. ': Previous Track',\n"
        "    '  ' .. ktc(vol_up) .. ': Volume Up',\n"
        "    '  ' .. ktc(vol_down) .. ': Volume Down',\n"
        "    '  ' .. ktc(seek_left) .. ': Seek Backward',\n"
        "    '  ' .. ktc(seek_right) .. ': Seek Forward',\n"
        "    '  ' .. ktc(speed_up) .. ': Speed Up',\n"
        "    '  ' .. ktc(speed_down) .. ': Slow Down',\n"
        "    '  ' .. ktc(change_mode) .. ': Change Playback Mode',\n"
        "    '',\n"
        "    'Plugin Controls:',\n"
        "    '  [Plugin Switch Keys]: Switch Plugins in Windows',\n"
        "}\n"
        "local maxTextWidth = 0\n"
        "for _, line in ipairs(helpText) do\n"
        "    if #line > maxTextWidth then maxTextWidth = #line end\n"
        "end\n"
        "local boxWidth = maxTextWidth + 4\n"
        "local boxHeight = #helpText + 4\n"
        "local boxX = math.floor((w - boxWidth) / 2)\n"
        "local boxY = math.floor((h - boxHeight) / 2)\n"
        "mainFrame:drawBox(\n"
        "    api.Text.new('Help', api.TextStyle.Bold, api.FGColors.Brights.White, api.BGColors.NoBrights.Black),\n"
        "    boxX, boxY, boxWidth, boxHeight,\n"
        "    api.BoxDrawing.LightBorder,\n"
        "    api.FGColors.Brights.White,\n"
        "    api.BGColors.NoBrights.Black\n"
        ")\n"
        "for i, line in ipairs(helpText) do\n"
        "    local textX = boxX + 2\n"
        "    local textY = boxY + 1 + i\n"
        "    mainFrame:writeText(textX, textY, line, api.FGColors.Brights.White, api.BGColors.NoBrights.Black)\n"
        "end\n";
    
    // Execute help rendering
    if (luaL_loadstring(L, help_script) == LUA_OK) {
        lua_pushvalue(L, -2); // mainFrame
        lua_pushinteger(L, w);
        lua_pushinteger(L, h);
        lua_pushinteger(L, help_key);
        lua_pushinteger(L, exit_key);
        lua_pushinteger(L, pause_key);
        lua_pushinteger(L, resume_key);
        lua_pushinteger(L, next_key);
        lua_pushinteger(L, prev_key);
        lua_pushinteger(L, vol_up);
        lua_pushinteger(L, vol_down);
        lua_pushinteger(L, seek_left);
        lua_pushinteger(L, seek_right);
        lua_pushinteger(L, speed_up);
        lua_pushinteger(L, speed_down);
        lua_pushinteger(L, change_mode);
        
        if (lua_pcall(L, 16, 0, 0) != LUA_OK) {
            fprintf(stderr, "Error rendering help: %s\n", lua_tostring(L, -1));
            lua_pop(L, 1);
        }
    }
    
    lua_pop(L, 1); // Pop mainFrame
}

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
) {
    if (!L) return false;

    error_message[0] = '\0';

    int h, w;
    lua_get_terminal_size(L, &h, &w);

    lua_main_frame_clear(L);

    int sound_ref = lua_create_sound(L);

    int fps = 60;
    float volume = 0.5f;
    float speed = 1.0f;
    int mode = 0;
    float inc_speed = 0.1f;
    float inc_volume = 0.1f;
    int inc_seek = 5;
    int help_key = 0;
    int exit_key = 0;
    int restart_key = 0;
    bool valid_restart = false;

    if (settings_ref != LUA_NOREF && settings_ref != LUA_REFNIL) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, settings_ref);

        if (lua_istable(L, -1)) {
            lua_getfield(L, -1, "fps");
            if (lua_isnumber(L, -1)) {
                fps = lua_tointeger(L, -1);
                if (fps <= 0 || fps > 120) fps = 60;
            }
            lua_pop(L, 1);

            lua_getfield(L, -1, "volume");
            if (lua_isnumber(L, -1)) {
                volume = lua_tonumber(L, -1);
                if (volume < 0 || volume > 1) volume = 0.5f;
            }
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "speed");
            if (lua_isnumber(L, -1)) {
                speed = lua_tonumber(L, -1);
                if (speed <= 0 || speed > 3.0f) speed = 1.0f;
            }
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "mode");
            if (lua_isnumber(L, -1)) {
                mode = lua_tointeger(L, -1);
                if (mode < 0 || mode > 3) mode = 0;
            }
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "inc_speed");
            if (lua_isnumber(L, -1)) {
                inc_speed = lua_tonumber(L, -1);
                if (inc_speed <= 0 || inc_speed > 50) inc_speed = 0.1f;
            }
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "inc_volume");
            if (lua_isnumber(L, -1)) {
                inc_volume = lua_tonumber(L, -1);
                if (inc_volume <= 0 || inc_volume > 1) inc_volume = 0.1f;
            }
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "inc_seek");
            if (lua_isnumber(L, -1)) {
                inc_seek = lua_tointeger(L, -1);
                if (inc_seek <= 0 || inc_seek > 30) inc_seek = 5;
            }
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "help_key");
            if (lua_isnumber(L, -1)) {
                help_key = lua_tointeger(L, -1);
            }
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "exit");
            if (lua_isnumber(L, -1)) {
                exit_key = lua_tointeger(L, -1);
            }
            lua_pop(L, 1);
            
            lua_getfield(L, -1, "restart_engine");
            if (lua_isnumber(L, -1)) {
                restart_key = lua_tointeger(L, -1);
                valid_restart = true;
            }
            lua_pop(L, 1);
        }

        lua_pop(L, 1);
    }

    lua_main_frame_set_fps(L, fps);
    lua_sound_set_volume(L, sound_ref, volume);
    lua_main_frame_init(L);

    // CRITICAL FIX: Create TemplateParser with PlugManager
    TemplateParser* parser = template_parser_new(template_refs, template_count, plug_manager);
    HashMap* switch_keys = template_parser_get_switch_keys(L, parser);

    bool quit = false;
    bool restart = false;
    bool render_help = false;

    while (!quit) {
        lua_main_frame_clear(L);
        int key = lua_handle_key(L);

        if (template_parser_was_resized(L, parser)) {
            lua_get_terminal_size(L, &h, &w);
            lua_main_frame_resize(L, w, h);
        }

        // Handle plugin switching
        if (switch_keys) {
            // Iterate through switch keys and check if pressed
            for (int i = 0; i < HASHMAP_SIZE; i++) {
                // This is a simplified check - in real implementation you'd iterate properly
                // For now, just handle the key events through Lua event system
            }
        }

        // Handle exit key
        if (exit_key != 0 && key == exit_key) {
            quit = true;
        }
        
        // Handle restart key
        if (valid_restart && restart_key != 0 && key == restart_key) {
            restart = true;
            quit = true;
        }
        
        // Handle help key toggle
        if (help_key != 0 && key == help_key) {
            render_help = !render_help;
        }

        lua_sound_update(L, sound_ref);

        // CRITICAL FIX: Parse template and get windows
        size_t window_count = 0;
        int* windows = template_parser_parse_template(L, parser, &window_count);

        // CRITICAL FIX: Add each window to mainFrame
        for (size_t i = 0; i < window_count; i++) {
            lua_main_frame_add(L, windows[i], true);
        }
        
        // Render help overlay if enabled
        if (render_help) {
            engine_render_help(L, w, h, settings_ref, sound_cfg_ref);
        }

        lua_main_frame_run(L, key, sound_ref, plugs_cfgs, config_ref);

        if (restart) {
            break;
        }

        // Cleanup window refs
        if (windows) {
            for (size_t i = 0; i < window_count; i++) {
                luaL_unref(L, LUA_REGISTRYINDEX, windows[i]);
            }
            free(windows);
        }
    }

    lua_sound_cleanup(L, sound_ref);
    template_parser_free(parser);
    hashmap_free(switch_keys);

    return restart;
}

int load_configuration(lua_State* L, int* out_template_ref, size_t* out_template_count, bool* out_is_userconfig) {
    if (!L) {
        *out_template_ref = LUA_NOREF;
        *out_template_count = 0;
        *out_is_userconfig = false;
        return LUA_NOREF;
    }

    const char* load_config_code = 
        "local api = require('rmp.rmp')\n"
        "local config = api.Config.new()\n"
        "if config:isValidConfig() then\n"
        "    local ok, err = config:load()\n"
        "    if not ok then\n"
        "        return nil, nil, false, 'loading user configuration: ' .. tostring(err)\n"
        "    end\n"
        "    local cfgObj = config:getInitFileAsObject()\n"
        "    local themeName = cfgObj.template\n"
        "    if not themeName or type(themeName) ~= 'string' then\n"
        "        return nil, nil, false, 'Invalid theme name in configuration'\n"
        "    end\n"
        "    local homePath = config.homePath:getPath()\n"
        "    local templatePath = homePath .. '/.rmp/templates/' .. themeName .. '.lua'\n"
        "    local templateOk, template = pcall(dofile, templatePath)\n"
        "    if not templateOk then\n"
        "        return nil, nil, false, 'loading user template: Not found or ' .. tostring(template)\n"
        "    end\n"
        "    return cfgObj, template, true, nil\n"
        "else\n"
        "    local defaultConfig = require('rmp.selfrmp.init')\n"
        "    local templateOk, template = pcall(require, 'rmp.selfrmp.templates.' .. defaultConfig.template)\n"
        "    if not templateOk then\n"
        "        return nil, nil, false, 'Error loading default template: ' .. tostring(template)\n"
        "    end\n"
        "    return defaultConfig, template, false, nil\n"
        "end";
    
    if (luaL_dostring(L, load_config_code) != LUA_OK) {
        const char* err = lua_tostring(L, -1);
        fprintf(stderr, "Error in load_configuration: %s\n", err);
        lua_pop(L, 1);
        *out_template_ref = LUA_NOREF;
        *out_template_count = 0;
        *out_is_userconfig = false;
        return LUA_NOREF;
    }
    
    const char* error = NULL;
    if (lua_isstring(L, -1)) {
        error = lua_tostring(L, -1);
    }
    
    if (error) {
        fprintf(stderr, "Configuration error: %s\n", error);
        rmp_log_error(error);
        lua_pop(L, 4);
        *out_template_ref = LUA_NOREF;
        *out_template_count = 0;
        *out_is_userconfig = false;
        return LUA_NOREF;
    }
    
    bool is_userconfig = lua_toboolean(L, -2);
    
    int template_ref = LUA_NOREF;
    size_t count = 0;
    
    if (lua_istable(L, -3)) {
        count = lua_rawlen(L, -3);
        lua_pushvalue(L, -3);
        template_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    }
    
    lua_pushvalue(L, -4);
    int cfg_obj_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    
    lua_pop(L, 4);
    
    *out_template_ref = template_ref;
    *out_template_count = count;
    *out_is_userconfig = is_userconfig;
    
    return cfg_obj_ref;
}

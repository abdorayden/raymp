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

static void lua_get_terminal_size(lua_State* L , int* h, int* w) {
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

static void lua_main_frame_resize(lua_State* L , int w, int h) {
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

static void lua_main_frame_add(lua_State*L , int window_ref, bool merge) {
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
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_main_frame_run(lua_State*L , int key, int sound_ref, HashMap* plugs_cfgs, int template_ref) {
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
        lua_pop(L, 1);
    }
    lua_pop(L, 1);
}

static void lua_main_frame_init(lua_State*L) {
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

static void lua_main_frame_set_fps(lua_State*L , int fps) {
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

static int lua_create_sound(lua_State*L) {
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

static void lua_sound_set_volume(lua_State*L , int sound_ref, float volume) {
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

static void lua_sound_update(lua_State*L , int sound_ref) {
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

static void lua_sound_cleanup(lua_State*L , int sound_ref) {
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

Component* component_new(lua_State*L , int comp_ref) {
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

Components* components_new(lua_State*L , int* temple_refs, size_t count) {
    Components* comps = malloc(sizeof(Components));
    comps->temple_array = (void**)temple_refs;
    comps->temple_array_count = count;
    comps->components = hashmap_new();
    components_fill_hashmap(L,comps);
    return comps;
}

void components_free(Components* comps) {
    if (!comps) return;
    hashmap_free(comps->components);
    free(comps);
}

void components_fill_hashmap(lua_State*L , Components* comps) {
    if (!comps || !L) return;
    
    for (size_t i = 0; i < comps->temple_array_count; i++) {
        int ref = ((int*)comps->temple_array)[i];
        Component* comp = component_new(L , ref);
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

int plug_manager_get_next(lua_State*L , PlugManager* pm, const char* id, char** error) {
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
    
    // plug_data[0] is switch key ref, plug_data[1] is queue ref
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
    
    // Push back
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

int template_parser_evaluate_expr(lua_State*L , TemplateParser* tp, const char* expr, ParserContext* ctx) {
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

int template_parser_parse_text(lua_State*L , TemplateParser* tp, int text_ref, ParserContext* ctx) {
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

int template_parser_create_window(lua_State*L , TemplateParser* tp, int window_ref, ParserContext* ctx) {
    if (!L || window_ref == LUA_NOREF || window_ref == LUA_REFNIL) return LUA_NOREF;
    
    lua_rawgeti(L, LUA_REGISTRYINDEX, window_ref);
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return LUA_NOREF;
    }
    
    lua_getfield(L, -1, "width");
    const char* width_expr = lua_tostring(L, -1);
    int width = template_parser_evaluate_expr(L , tp, width_expr, ctx);
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "height");
    const char* height_expr = lua_tostring(L, -1);
    int height = template_parser_evaluate_expr(L , tp, height_expr, ctx);
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "x");
    const char* x_expr = lua_tostring(L, -1);
    int x = template_parser_evaluate_expr(L , tp, x_expr, ctx);
    lua_pop(L, 1);
    
    lua_getfield(L, -1, "y");
    const char* y_expr = lua_tostring(L, -1);
    int y = template_parser_evaluate_expr(L , tp, y_expr, ctx);
    lua_pop(L, 1);
    
    lua_getglobal(L, "api");
    lua_getfield(L, -1, "Window");
    lua_getfield(L, -1, "new");
    
    lua_pushvalue(L, -4);
    lua_getfield(L, -1, "id");
    
    if (lua_pcall(L, 1, 1, 0) != LUA_OK) {
        lua_pop(L, 4);
        return LUA_NOREF;
    }
    
    int result = luaL_ref(L, LUA_REGISTRYINDEX);
    lua_pop(L, 3);
    
    return result;
}

int* template_parser_parse_template(lua_State*L , TemplateParser* tp, size_t* out_count) {
    if (!tp || !L) {
        *out_count = 0;
        return NULL;
    }

    if (!tp->template_refs) {
        *out_count = 0;
        return NULL;
    }

    ParserContext ctx = template_parser_create_context(L, tp);

    int* windows = calloc(tp->template_count, sizeof(int));
    size_t window_count = 0;

    for (size_t i = 0; i < tp->template_count; i++) {
        int window = template_parser_create_window(L , tp, tp->template_refs[i], &ctx);
        if (window != LUA_NOREF && window != LUA_REFNIL) {
            windows[window_count++] = window;
        }
    }

    *out_count = window_count;
    return windows;
}

HashMap* template_parser_get_switch_keys(lua_State*L , TemplateParser* tp) {
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

void template_parser_update_plugin(lua_State* L , TemplateParser* tp, const char* window_id) {
    if (!tp || !tp->plug_manager || !window_id) return;
    
    char* error = NULL;
    int plugin = plug_manager_get_next(L,tp->plug_manager, window_id, &error);
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
// Main Engine Functions
// ============================================================================

int setup_plugins(lua_State*L , int config_ref, bool is_userconfig, Queue** other_plugs, HashMap** plugs_cfgs) {
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

    // Save the config table by copying it to the top of the stack
    lua_pushvalue(L, -1); // Duplicate the config table

    lua_getfield(L, -2, "plugins"); // Get plugins from the original config table (at -2)

    if (!lua_istable(L, -1)) {
        lua_pop(L, 3); // Remove plugins table, duplicated config, and original config
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

        // Process plugin data here if needed
        lua_pop(L, 1); // Remove the plugin table

        if (window_id) free((void*)window_id);
    }

    // Clean up: remove plugins table and the original config table
    lua_pop(L, 2); // Remove plugins table and original config table
    // The duplicated config table is still on top of the stack

    int config_obj_ref = luaL_ref(L, LUA_REGISTRYINDEX);
    return config_obj_ref;
}

bool run_rmp_application(lua_State*L ,  PlugManager* plug_manager, int* template_refs, size_t template_count, int settings_ref, Queue* other_plugs, int sound_cfg_ref, HashMap* plugs_cfgs, int config_ref, bool is_userconfig) {
    if (!L) return false;

    error_message[0] = '\0';

    int h, w;
    lua_get_terminal_size(L, &h, &w);

    lua_main_frame_clear(L);

    int sound_ref = lua_create_sound(L);

    int fps = 60;
    float volume = 0.5f;

    if (settings_ref != LUA_NOREF && settings_ref != LUA_REFNIL) {
        lua_rawgeti(L, LUA_REGISTRYINDEX, settings_ref);

        if (lua_istable(L, -1)) {
            lua_getfield(L, -1, "fps");
            if (lua_isnumber(L, -1)) {
                fps = lua_tointeger(L, -1);
            }
            lua_pop(L, 1);

            lua_getfield(L, -1, "volume");
            if (lua_isnumber(L, -1)) {
                volume = lua_tonumber(L, -1);
            }
            lua_pop(L, 1);
        }

        lua_pop(L, 1);
    }

    lua_main_frame_set_fps(L, fps);
    lua_sound_set_volume(L, sound_ref, volume);
    lua_main_frame_init(L);

    TemplateParser* parser = template_parser_new(template_refs, template_count, plug_manager);
    HashMap* switch_keys = template_parser_get_switch_keys(L, parser);

    bool quit = false;
    bool restart = false;

    while (!quit) {
        lua_main_frame_clear(L);
        int key = lua_handle_key(L);

        if (template_parser_was_resized(L, parser)) {
            lua_get_terminal_size(L, &h, &w);
            lua_main_frame_resize(L, w, h);
        }

        lua_sound_update(L, sound_ref);

        size_t window_count = 0;
        int* windows = template_parser_parse_template(L, parser, &window_count);

        for (size_t i = 0; i < window_count; i++) {
            lua_main_frame_add(L, windows[i], true);
        }

        lua_main_frame_run(L, key, sound_ref, plugs_cfgs, config_ref);

        if (restart) {
            break;
        }

        free(windows);
    }

    lua_sound_cleanup(L, sound_ref);
    template_parser_free(parser);
    hashmap_free(switch_keys);

    return restart;
}

int load_configuration(lua_State*L , int* out_template_ref, size_t* out_template_count, bool* out_is_userconfig) {
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

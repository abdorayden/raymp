#include "command.h"
#include "third_party/rdn/rdn_native.h"
#include <stddef.h>

RMPCommands rmp_commands = {0};
RMPKeybinds rmp_keybinds = {0};

static bool cmd_exists(char* command_name , char** out_function) {
    for (size_t x = 0; x < rmp_commands.count; ++x) {
        if (strcmp(rmp_commands.items[x].command_name, command_name) == 0) {
            if (out_function != NULL) {
                *out_function = rmp_commands.items[x].function_name;
            }
            return true;
        }
    }
    return false;
}

bool reg_cmd(char* command_name , char* function_name){
    if (!cmd_exists(command_name , NULL)){
        ray_append(&rmp_commands, ((RMPCommand){
                    .command_name = copy_string(command_name),
                    .function_name = copy_string(function_name)
                    }));
        return true;
    }
    return false;
}

bool reg_cmd_native(RDNApi* api) {
    char* identifier_name = (char*)api->to_identifier(api , -1);
    if(identifier_name == NULL) {
        api->push_string(api ,"command: function name is not an identifier");
        api->pop(api , 2);
        return true;
    }

    char* command_name = (char*)api->to_string(api , -2);
    if(command_name == NULL) {
        api->push_string(api ,"command: command name is not a string");
        api->pop(api , 2);
        return true;
    }

    bool ok = reg_cmd(command_name, identifier_name);

    if (!ok) {
        api->push_string(api ,"command name already exists");
        api->pop(api , 2);
        return true;
    }

    api->pop(api , 2);
    api->push_null(api);
    return true;
}

bool eval_cmd_native(RDNApi* api) {
    char* command_name = (char*)api->to_string(api , -1);
    if(command_name == NULL) {
        api->pop(api , 1);
        api->push_string(api ,"eval-cmd: command name must be a string");
        return true;
    }

    char* function_name = NULL;
    if (!cmd_exists(command_name, &function_name)) {
        api->pop(api , 1);
        api->push_string(api ,"eval-cmd: command not found");
        return true;
    }

    NativeCallState* state = (NativeCallState*)api->userdata;
    Funcs_t* entry = find_func_entry(state->funcs, function_name);
    if (!entry) {
        api->pop(api , 1);
        api->push_string(api ,"eval-cmd: function not found for command");
        return true;
    }

    api->pop(api , 1);

    if (!execute_named_entry(state->stack, state->vars, state->funcs, entry, "command", command_name)) {
        return api->raise_error(api , "eval-cmd: execution failed");
    }

    return true;
}

bool rmp_map_key_native(RDNApi* api) {
    char* command_name = (char*)api->to_string(api , -1);
    if (command_name == NULL) {
        api->pop(api , 2);
        api->push_boolean(api , false);
        return true;
    }

    long key_code;
    if (!api->to_integer(api , -2 , &key_code)) {
        api->pop(api , 2);
        api->push_boolean(api , false);
        return true;
    }

    for (size_t i = 0; i < rmp_keybinds.count; ++i) {
        if (rmp_keybinds.items[i].key == (RMPKey)key_code) {
            free(rmp_keybinds.items[i].command_name);
            rmp_keybinds.items[i].command_name = copy_string(command_name);
            api->pop(api , 2);
            api->push_boolean(api , true);
            return true;
        }
    }

    RMPKeybind kb = {
        .key = (RMPKey)key_code,
        .command_name = copy_string(command_name)
    };
    ray_append(&rmp_keybinds, kb);

    api->pop(api , 2);
    api->push_boolean(api , true);
    return true;
}

bool rmp_unmap_key_native(RDNApi* api) {
    long key_code;
    if (!api->to_integer(api , -1 , &key_code)) {
        api->pop(api , 1);
        api->push_boolean(api , false);
        return true;
    }

    for (size_t i = 0; i < rmp_keybinds.count; ++i) {
        if (rmp_keybinds.items[i].key == (RMPKey)key_code) {
            free(rmp_keybinds.items[i].command_name);
            if (i < rmp_keybinds.count - 1) {
                rmp_keybinds.items[i] = rmp_keybinds.items[rmp_keybinds.count - 1];
            }
            rmp_keybinds.count--;
            break;
        }
    }

    api->pop(api , 1);
    api->push_boolean(api , true);
    return true;
}

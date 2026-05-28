#include "command.h"
#include "third_party/rdn/rdn_native.h"
#include <stddef.h>

RMPCommands rmp_commands = {0};

static bool cmd_exists(char* command_name , char* value) {
    for (size_t x = 0; x < rmp_commands.count; ++x) {
        if (strcmp(rmp_commands.items[x].command_name, command_name) == 0) {
            if (value != NULL) {
                value = rmp_commands.items[x].function_name;
            }
            return true;
        }
    }
    return false;
}

bool reg_cmd(char* command_name , char* function_name){
    if (!cmd_exists(command_name , NULL)){
        ray_append(&rmp_commands, ((RMPCommand){
                    .command_name = command_name,
                    .function_name = function_name
                    }));
        return true;
    }
    return false;
}

bool reg_cmd_native(RDNApi* api) {
    char* command_name = (char*)api->to_string(api , -1);
    if(command_name == NULL) {
        api->push_string(api ,"command name are not a string type");
        api->pop(api , 2);
        return true;
    }

    char* identifier_name = (char*)api->to_identifier(api , -2);

    bool ok = reg_cmd(command_name, identifier_name);

    if (!ok) {
        api->push_string(api ,"command name are already exists");
        api->pop(api , 2);
        return true;
    }

    api->pop(api , 2);
    api->push_null(api);
    return true;
}

// this must be a private and not part of the api
bool eval_cmd_native(RDNApi* api) {
    char* command_name = (char*)api->to_string(api , -1);
    if(command_name == NULL) {
        api->push_string(api ,"command name are not a string type");
        api->pop(api , 2);
        return true;
    }
    char* val;
    for(size_t i = 0 ; i < rmp_commands.count ; ++i) {
        if (cmd_exists(rmp_commands.items[i].command_name , val)) {

        }
    }
    return true;
}

#ifndef COMMAND_RMP_H_
#define COMMAND_RMP_H_

#include "engine.h"
#include "api/keyboard.h"
#include "third_party/rdn/rdn_native.h"
#include "third_party/rdn/stack.h"
#include <string.h>

typedef struct {
    RMPKey key;
    char* command_name;
} RMPKeybind;

typedef RLList(RMPKeybind) RMPKeybinds;

extern RMPKeybinds rmp_keybinds;

bool reg_cmd_native(RDNApi* api);
bool eval_cmd_native(RDNApi* api);
bool rmp_map_key_native(RDNApi* api);
bool rmp_unmap_key_native(RDNApi* api);

#endif

#ifndef RMPENGINE_H_
#define RMPENGINE_H_
#include "api/vt.h"
#include "third_party/rdn/stack.h"
#include "third_party/rdn/src.h"

// TODO: check how VirtualTerminal is used in vt.h to make functionalities of it use the engine frame for more memory optimisation



// TODO: create a special api for working with engine and rename all folders that contains api in their names 
// the engine api will works with one single virtual terminal

// typedef enum {
//     engine_EXIT,
//     engine_START,
// } EventsType;

typedef struct {
    char* command_name;
    char* function_name;
}RMPCommand;

typedef RLList(RMPCommand) RMPCommands;

extern RMPCommands rmp_commands;

#endif // !RMPENGINE_H_


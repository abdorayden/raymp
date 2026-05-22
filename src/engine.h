#include "api/vt.h"
#include "third_party/rdn/stack.h"
#ifndef RMPENGINE_H_
#include "./third_party/rdn/src.h"

// TODO: check how VirtualTerminal is used in vt.h to make functionalities of it use the engine frame for more memory optimisation

typedef enum {
    // handle this two commands and add more later
    engine_EXIT,
    engine_START,
} EventsType;
 
typedef struct {
    char* command_name;
    char* function_name;
}RMPCommand;

typedef RLList(RMPCommand) RMPCommands;
typedef RLList(VirtualTerminal) VTS;

typedef struct{
    RDNState    state;
    Vars        vars;
    Funcs       funcs;
    size_t      fps;
    RMPCommands commands;
    VTS vts;
}RMPEngine;


RMPEngine rmp_engine_init(RDNState , Vars , Funcs );
void      rmp_engine_run(RMPEngine);
void      rmp_engine_clear(RMPEngine);

#endif // !RMPENGINE_H_


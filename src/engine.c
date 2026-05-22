#include "engine.h"
#include "third_party/rdn/rdn_native.h"

static bool engine_store_vt(RDNApi* api) {
    return true;
}

static bool engine_register_command(RDNApi* api) {
    return true;
}

static bool engine_del_command(RDNApi* api) {
    return true;
}

RMPEngine rmp_engine_init(RDNState state , Vars vars , Funcs funcs)
{
    RMPEngine engine = {0};
    engine.funcs = funcs;
    engine.vars = vars;
    engine.state = state;
    engine.fps = 30;
    engine.commands = (RMPCommands){0};
    engine.vts = (VTS){0};
    return engine;
}


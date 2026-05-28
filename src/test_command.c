#include "command.h"
#include "third_party/rdn/src.h"
#include "third_party/rdn/stack.h"
#include <stdio.h>

int main(void)
{
    RDNState stack = {0}; 
    Vars vars = {0};
    Funcs funcs = {0};

    ray_append(&funcs, create_native_func_entry("rmp-reg-command-native", reg_cmd_native, NULL));
    
    evaluate_file(&stack, &vars, &funcs, "./command.rdn");
    evaluate_file(&stack, &vars, &funcs, "./test_command.rdn");

    char buffer[36];
    sprintf(buffer, "\"count is %zu\" print" , rmp_commands.count);
    evaluate_source(&stack, &vars, &funcs, buffer);

    return 0;
}

#include "third_party/rdn/src.c"
#include "command.c"

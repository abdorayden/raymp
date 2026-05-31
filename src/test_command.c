#include "command.h"
#include "third_party/rdn/src.h"
#include "third_party/rdn/stack.h"
#include <stdio.h>
#include <string.h>

int main(void)
{
    RDNState stack = {0};
    Vars vars = {0};
    Funcs funcs = {0};

    ray_append(&funcs, create_native_func_entry("rmp-reg-command-native", reg_cmd_native, NULL));
    ray_append(&funcs, create_native_func_entry("rmp-eval-cmd-native", eval_cmd_native, NULL));
    ray_append(&funcs, create_native_func_entry("rmp-map-key-native", rmp_map_key_native, NULL));
    ray_append(&funcs, create_native_func_entry("rmp-unmap-key-native", rmp_unmap_key_native, NULL));

    printf("=== Test 1: register and evaluate command ===\n");
    evaluate_file(&stack, &vars, &funcs, "./command.rdn");
    evaluate_file(&stack, &vars, &funcs, "./test_command.rdn");

    printf("commands registered: %zu\n", rmp_commands.count);
    printf("evaluating command 'pfoo'... ");

    char buffer[256];
    sprintf(buffer, "\"pfoo\" rmp-eval-cmd-native call");
    evaluate_source(&stack, &vars, &funcs, buffer);
    printf(" ok\n");

    printf("=== Test 2: keybinding ===\n");
    sprintf(buffer, "1 \"pfoo\" rmp-map-key-native call");
    evaluate_source(&stack, &vars, &funcs, buffer);
    printf("keybinds count: %zu\n", rmp_keybinds.count);
    if (rmp_keybinds.count > 0)
        printf("  key %d -> cmd \"%s\"\n", rmp_keybinds.items[0].key, rmp_keybinds.items[0].command_name);

    sprintf(buffer, "1 rmp-unmap-key-native call");
    evaluate_source(&stack, &vars, &funcs, buffer);
    printf("after unmap: %zu\n", rmp_keybinds.count);

    while (stack.count > 0) {
        free_value(ray_pop(&stack));
    }

    printf("=== All tests passed ===\n");

    free_stack_values(&stack);
    for (size_t i = 0; i < rmp_keybinds.count; ++i) free(rmp_keybinds.items[i].command_name);
    free(rmp_keybinds.items);
    for (size_t i = 0; i < rmp_commands.count; ++i) {
        free(rmp_commands.items[i].command_name);
        free(rmp_commands.items[i].function_name);
    }
    free(rmp_commands.items);
    free_vars(&vars);
    free_funcs(&funcs);
    return 0;
}

#include "third_party/rdn/src.c"
#include "command.c"

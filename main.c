#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "./src/third_party/rdn/src.h"
#include "./src/api/directory.h"
#include "./src/api/platform.h"
#include "./src/api/sleep.h"
#include "./src/api/term.h"
#include "./src/api/vt.h"
#include "./src/api/keyboard.h"
#include "./src/api/color.h"

#include "./src/command.h"

#define RMP_NAME "Ray Media Platform"
#define RMP_VERSION "0.1.0"

static bool register_native(Funcs *funcs, const char *name, RDNNativeFunction fn) {
    return funcs_define_native(funcs, name, fn, NULL);
}

static bool register_native_api(Funcs *funcs) {
    return
        register_native(funcs, "rmp_vt_init_native", rmp_vt_init) &&
        register_native(funcs, "rmp_vt_distroy_native", rmp_vt_distroy) &&
        register_native(funcs, "rmp_vt_clear_native", rmp_vt_clear) &&
        register_native(funcs, "rmp_vt_setchar_native", rmp_vt_setchar) &&
        register_native(funcs, "rmp_vt_writetext_native", rmp_vt_writetext) &&
        register_native(funcs, "rmp_vt_open_win_native", rmp_vt_open_win) &&
        register_native(funcs, "rmp_vt_merge_native", rmp_vt_merge) &&
        register_native(funcs, "rmp_vt_render_native", rmp_vt_render) &&
        register_native(funcs, "rmp_vt_movecursor_native", rmp_vt_movecursor) &&
        register_native(funcs, "rmp_vt_getsize_native", rmp_vt_getsize) &&
        register_native(funcs, "rmp_vt_resize_native", rmp_vt_resize) &&
        register_native(funcs, "rmp_vt_moveup_native", rmp_vt_moveup) &&
        register_native(funcs, "rmp_vt_movedown_native", rmp_vt_movedown) &&
        register_native(funcs, "rmp_vt_moveleft_native", rmp_vt_moveleft) &&
        register_native(funcs, "rmp_vt_copy_native", rmp_vt_copy) &&
        register_native(funcs, "rmp_vt_moveright_native", rmp_vt_moveright) &&
        register_native(funcs, "rmp_to_raw_mode_native", rmp_to_raw_mode) &&
        register_native(funcs, "rmp_get_term_size_native", rmp_get_term_size) &&
        register_native(funcs, "rmp_init_terminal_native", init_terminal) &&
        register_native(funcs, "rmp_restore_terminal_native", restore_terminal) &&
        register_native(funcs, "rmp_term_clear_native", rmp_term_clear) &&
        register_native(funcs, "rmp_term_hide_cursor_native", rmp_term_hide_cursor) &&
        register_native(funcs, "rmp_term_show_cursor_native", rmp_term_show_cursor) &&
        register_native(funcs, "rmp_platform_native", rmp_platform) &&
        register_native(funcs, "rmp_sleep_native", rmp_sleep) &&
        register_native(funcs, "rmp_get_current_path_native", rmp_get_current_path) &&
        register_native(funcs, "rmp_home_path_native", rmp_home_path) &&
        register_native(funcs, "rmp_list_dir_native", rmp_list_dir) &&
        register_native(funcs, "rmp_mkdir_native", rmp_mkdir) &&
        register_native(funcs, "rmp_rmdir_native", rmp_rmdir) &&
        register_native(funcs, "rmp_get_key_native", rmp_get_key) &&
        register_native(funcs, "rmp_close_key_native", rmp_close_key) &&
        register_native(funcs, "rmp_color_native", rmp_color) &&
        register_native(funcs, "rmp-eval-cmd-native", eval_cmd_native) &&
        register_native(funcs, "rmp-map-key-native", rmp_map_key_native) &&
        register_native(funcs, "rmp-unmap-key-native", rmp_unmap_key_native) &&
        register_native(funcs, "rmp-reg-command-native", reg_cmd_native);
}

static char *dup_env(const char *name) {
    const char *value = getenv(name);
    if (value == NULL || value[0] == '\0') {
        return NULL;
    }
    return copy_string(value);
}

static char *join_owned(char *base, const char *path) {
    char *joined = join_paths(base, path);
    free(base);
    return joined;
}

static bool source_if_exists(RDNState *stack, Vars *vars, Funcs *funcs, const char *path) {
    if (!path_is_readable_file(path)) {
        return true;
    }
    return evaluate_file(stack, vars, funcs, path);
}

static bool bootstrap_runtime(RDNState *stack, Vars *vars, Funcs *funcs) {
    char *home = NULL;
    char *xdg_config = NULL;
    char *config_dir = NULL;
    char *config_dir_alt = NULL;
    char *config_init = NULL;
    char *config_init_alt = NULL;
    char *legacy_init = NULL;
    bool loaded_user_init = false;

    if (!reset_search_paths()) {
        fprintf(stderr, "failed to initialize search paths\n");
        return false;
    }

    if (
            !push_search_path(&g_script_search_paths, "src/api_high_layer") ||
            !push_search_path(&g_script_search_paths, "src/builtin")
            ) {
        fprintf(stderr, "failed to register bundled script paths\n");
        return false;
    }

    apply_host_environment(vars);

    if (!register_native_api(funcs)) {
        fprintf(stderr, "failed to register native api\n");
        return false;
    }

    if (!evaluate_file(stack, vars, funcs, "src/api_high_layer/api.rdn")) {
        return false;
    }

    // if (!source_if_exists(stack, vars, funcs, "src/builtin/first.rdn")) {
    //     return false;
    // }
    
    if (!source_if_exists(stack, vars, funcs, "src/command.rdn")) {
        return false;
    }

    if (!source_if_exists(stack, vars, funcs, "src/api_high_layer/colors.rdn")) {
        return false;
    }

    if (!source_if_exists(stack, vars, funcs, "src/first.rdn")) {
        return false;
    }

    if (!source_if_exists(stack, vars, funcs, "src/themes.rdn")) {
        return false;
    }

    if (!source_if_exists(stack, vars, funcs, "src/ui.rdn")) {
        return false;
    }

    if (!source_if_exists(stack, vars, funcs, "src/first_ui.rdn")) {
        return false;
    }

    home = dup_env("HOME");
    xdg_config = dup_env("XDG_CONFIG_HOME");
    if (xdg_config != NULL) {
        config_dir = join_paths(xdg_config, "raymp");
        config_dir_alt = join_paths(xdg_config, "rayden");
    } else if (home != NULL) {
        config_dir = join_paths(home, ".config/raymp");
        config_dir_alt = join_paths(home, ".config/rayden");
    }

    if (config_dir != NULL) {
        if (!push_search_path(&g_script_search_paths, config_dir)) {
            free(home);
            free(config_dir);
            free(config_dir_alt);
            return false;
        }
        config_init = join_paths(config_dir, "init.rdn");
    }

    if (config_dir_alt != NULL) {
        if (!push_search_path(&g_script_search_paths, config_dir_alt)) {
            free(home);
            free(config_dir);
            free(config_dir_alt);
            free(config_init);
            return false;
        }
        config_init_alt = join_paths(config_dir_alt, "init.rdn");
    }

    if (home != NULL) {
        legacy_init = join_paths(home, ".rmp/init.rdn");
    }

    if (config_init != NULL && !source_if_exists(stack, vars, funcs, config_init)) {
        free(home);
        free(config_dir);
        free(config_dir_alt);
        free(config_init);
        free(config_init_alt);
        free(legacy_init);
        return false;
    } else if (config_init != NULL && path_is_readable_file(config_init)) {
        loaded_user_init = true;
    }

    if (!loaded_user_init && config_init_alt != NULL && !source_if_exists(stack, vars, funcs, config_init_alt)) {
        free(home);
        free(config_dir);
        free(config_dir_alt);
        free(config_init);
        free(config_init_alt);
        free(legacy_init);
        return false;
    } else if (!loaded_user_init && config_init_alt != NULL && path_is_readable_file(config_init_alt)) {
        loaded_user_init = true;
    }

    if (legacy_init != NULL && !source_if_exists(stack, vars, funcs, legacy_init)) {
        free(home);
        free(config_dir);
        free(config_dir_alt);
        free(config_init);
        free(config_init_alt);
        free(legacy_init);
        return false;
    } else if (!loaded_user_init && legacy_init != NULL && path_is_readable_file(legacy_init)) {
        loaded_user_init = true;
    }

    if (!loaded_user_init && !source_if_exists(stack, vars, funcs, "src/builtin/init.rdn")) {
        free(home);
        free(config_dir);
        free(config_dir_alt);
        free(config_init);
        free(config_init_alt);
        free(legacy_init);
        return false;
    }

    // TODO: for cleaning
    if (!source_if_exists(stack, vars, funcs, "src/clean.rdn")) {
        return false;
    }

    free(home);
    free(config_dir);
    free(config_dir_alt);
    free(config_init);
    free(config_init_alt);
    free(legacy_init);
    return true;
}

static void print_usage(const char *progname) {
    printf("%s v%s\n", RMP_NAME, RMP_VERSION);
    printf("Usage: %s [script.rdn] [args...]\n", progname);
    printf("If no script is provided, bundled api and user init files are loaded.\n");
}

int main(int argc, char **argv) {
    const char *entry_path = NULL;
    RDNState stack = {0};
    Vars vars = {0};
    Funcs funcs = {0};
    int exit_code = EXIT_FAILURE;

    if (argc > 1 &&
        (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "help") == 0)) {
        print_usage(argv[0]);
        return EXIT_SUCCESS;
    }

    if (argc > 1 &&
        (strcmp(argv[1], "--version") == 0 || strcmp(argv[1], "-v") == 0)) {
        printf("%s\n", RMP_VERSION);
        return EXIT_SUCCESS;
    }

    // handle configuration file and evaluate it
    if (!bootstrap_runtime(&stack, &vars, &funcs)) {
        goto cleanup;
    }

    if (argc > 1) {
        entry_path = argv[1];
        apply_argv(&vars, entry_path, argc, argv);
        if (!evaluate_file(&stack, &vars, &funcs, entry_path)) {
            goto cleanup;
        }
    }

    if (stack.count != 0) {
        fprintf(stderr, "unexpected values left on stack: %zu\n", stack.count);
        goto cleanup;
    }

    exit_code = EXIT_SUCCESS;

cleanup:
    free_stack_values(&stack);
    free_vars(&vars);
    free_funcs(&funcs);
    free_search_path_stack(&g_script_search_paths);
    free_search_path_stack(&g_native_search_paths);
    while (g_load_path_stack.count > 0) {
        pop_load_path();
    }
    return exit_code;
}

#include "./src/third_party/rdn/src.c"
#include "./src/api/vt.c"
#include "./src/api/term.c"
#include "./src/api/platform.c"
#include "./src/api/sleep.c"
#include "./src/api/directory.c"
#include "./src/api/keyboard.c"
#include "./src/api/color.c"
#include "./src/command.c"

#include <stdio.h>

#include "./src/third_party/rdn/src.h"
#include "./src/api/vt.h"
#include "src/third_party/rdn/stack.h"

int main(void)
{
    RDNState stack = {0};
    Vars vars = {0};
    Funcs funcs = {0};

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_init_native", 
                rmp_vt_init, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_distroy_native",
                rmp_vt_distroy, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_clear_native",
                rmp_vt_clear, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_setchar_native",
                rmp_vt_setchar, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_writetext_native",
                rmp_vt_writetext, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_open_win_native",
                rmp_vt_open_win, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_merge_native",
                rmp_vt_merge, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_render_native",
                rmp_vt_render, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_movecursor_native",
                rmp_vt_movecursor, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_getsize_native",
                rmp_vt_getsize, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_resize_native",
                rmp_vt_resize, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_moveup_native",
                rmp_vt_moveup, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_movedown_native",
                rmp_vt_movedown, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_moveleft_native",
                rmp_vt_moveleft, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_moveright_native",
                rmp_vt_moveright, 
                NULL
                )
            );

    ray_append(
            &funcs, 
            create_native_func_entry(
                "rmp_vt_copy_native",
                rmp_vt_copy, 
                NULL
                )
            );

    return 0;
}

#include "./src/third_party/rdn/src.c"
#include "./src/api/vt.c"

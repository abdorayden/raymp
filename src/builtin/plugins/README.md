# Builtin Plugins

This directory contains bundled Raden examples that run when raymp does not
find a user config at:

- `~/.config/raymp/init.rdn`
- `~/.rmp/init.rdn`

Current files:

- `example_ui.rdn`: minimal UI, event, and command example built on the native C engine

## What The Example Shows

- plugin files register behavior only
- builtin init owns frame setup and `rmp_run_loop`
- fixed lifecycle events with `rmp_on_init`, `rmp_on_key`, `rmp_on_render`
- generic named events with `rmp_on` and `rmp_emit_event`
- custom commands with `rmp_register_command`
- queued built-in draw commands with `rmp_cmd_draw_box` and `rmp_cmd_write_text`
- persistent plugin UI state rendered every frame

## Recommended Flow

1. Run `raymp` without a user config.
2. Inspect `src/builtin/init.rdn`.
3. Inspect `src/builtin/plugins/example_ui.rdn`.
4. Keep plugin files focused on commands, events, and rendering.
5. Keep engine bootstrap in `init.rdn` or in the native host, not inside plugin files.

# libuv Integration Tests

These tests exercise more involved scenarios using the libuv bindings and related runtime helpers.

## Test Files

1. **test_uv_spawn.lua** - Run external binaries and validate exit codes.
2. **test_uv_fs_multi.lua** - Concurrently write/read multiple files using libuv FS APIs.
3. **test_rsocket_tcp.lua** - Basic TCP echo test using `rmp.rsocket` on loopback.

## Running Tests

```bash
lua tests/uv_integration/test_uv_spawn.lua
lua tests/uv_integration/test_uv_fs_multi.lua
lua tests/uv_integration/test_rsocket_tcp.lua
```

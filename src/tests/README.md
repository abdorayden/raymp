# Future Library Tests

This directory contains unit and integration tests for the Future library and async/runtime helpers.

## Test Files:

1. **test_future.lua** - Unit tests for individual Future components and methods
2. **test_future_integration.lua** - Integration tests for complex scenarios and interactions
3. **test_uv.lua** - Unit tests for the libuv Lua bindings (`rmp.uv`)
4. **test_promises_uv.lua** - Integration tests for Promise scheduler (libuv or fallback)
5. **uv_integration/** - More involved integration tests (libuv + sockets)

## Running Tests:

To run the unit tests:
```bash
lua tests/test_future.lua
```

To run the integration tests:
```bash
lua tests/test_future_integration.lua
```

To run the libuv binding tests:
```bash
lua tests/test_uv.lua
```

To run the Promise scheduler tests:
```bash
lua tests/test_promises_uv.lua
```

To run the more involved integration tests:
```bash
lua tests/uv_integration/test_uv_spawn.lua
lua tests/uv_integration/test_uv_fs_multi.lua
lua tests/uv_integration/test_rsocket_tcp.lua
```

## Test Coverage:

The tests cover:
- Basic future types (ValueFuture, ErrorFuture, TimerFuture)
- Future chaining with `:athen()` method
- Error handling with `:catch()` method
- Composite futures (AllFuture, RaceFuture, AnyFuture, AllSettledFuture)
- Future executor functionality
- Deferred futures
- Finally method
- Libuv timer/fs/spawn bindings
- Promise scheduler integration with libuv

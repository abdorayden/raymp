# Future Library Tests

This directory contains unit and integration tests for the Future library and async/runtime helpers.

## Test Files:

1. **test_future.lua** - Unit tests for individual Future components and methods
2. **test_future_integration.lua** - Integration tests for complex scenarios and interactions
3. **test_uv.lua** - Unit tests for the libuv Lua bindings (`rmp.uv`)
4. **test_promises_uv.lua** - Integration tests for Promise scheduler (libuv or fallback)

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

# Future Library Tests

This directory contains unit and integration tests for the Future library.

## Test Files:

1. **test_future.lua** - Unit tests for individual Future components and methods
2. **test_future_integration.lua** - Integration tests for complex scenarios and interactions

## Running Tests:

To run the unit tests:
```bash
lua tests/test_future.lua
```

To run the integration tests:
```bash
lua tests/test_future_integration.lua
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
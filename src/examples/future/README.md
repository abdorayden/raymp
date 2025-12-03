# Future Library Examples

This directory contains various examples demonstrating the usage of the Future library.

## Examples:

1. **basic_usage.lua** - Basic example showing how to create and chain futures
2. **error_handling.lua** - Demonstrates error handling with the `:catch()` method
3. **chaining.lua** - Shows how to chain multiple futures together 
4. **all_future.lua** - Example of the `Future.all()` method that waits for all futures to complete
5. **race_future.lua** - Example of the `Future.race()` method that returns the first completed future
6. **advanced_features.lua** - Demonstrates advanced features like `finally`, `any`, `allSettled`, and deferred futures

## Running Examples:

To run an example, use:
```bash
lua examples/future/basic_usage.lua
```

Make sure the library dependencies are available in your Lua path.
#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

TESTS=(
  "test_uv.lua"
  "test_promises_uv.lua"
  "uv_integration/test_uv_spawn.lua"
  "uv_integration/test_uv_fs_multi.lua"
  "uv_integration/test_rsocket_tcp.lua"
)

pass_count=0
fail_count=0
skip_count=0

for test in "${TESTS[@]}"; do
  echo "=== Running $test ==="
  output=$(lua "$test" 2>&1) || {
    echo "$output"
    fail_count=$((fail_count + 1))
    echo "=== FAIL: $test ==="
    echo
    continue
  }

  echo "$output"
  if echo "$output" | rg -q "Skipping|SKIP"; then
    skip_count=$((skip_count + 1))
    echo "=== SKIP: $test ==="
  else
    pass_count=$((pass_count + 1))
    echo "=== PASS: $test ==="
  fi
  echo

done

echo "Summary: PASS=$pass_count SKIP=$skip_count FAIL=$fail_count"

if [ "$fail_count" -ne 0 ]; then
  exit 1
fi

if [ "$skip_count" -ne 0 ]; then
  echo "Some tests were skipped. Ensure rmp.uv and rmp.rsocket are installed."
  exit 2
fi

echo "All tests are working so good."

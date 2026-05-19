#!/usr/bin/env bash
set -euo pipefail
# Run all linters across project
echo "Running cppcheck..."
cppcheck --enable=all src/ 2>&1 | head -n 5 || echo "Install cppcheck"
echo "Running ruff..."
ruff check . 2>&1 | head -n 5 || echo "Install ruff"

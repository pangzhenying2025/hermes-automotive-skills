#!/usr/bin/env bash
set -euo pipefail
# Generate unified code coverage report
echo "Code Coverage Report"
lcov --capture --directory . --output-file coverage.info 2>/dev/null || echo "Run: sudo apt install lcov"

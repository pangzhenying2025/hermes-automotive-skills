#!/usr/bin/env bash
set -euo pipefail
# Generate API documentation
echo "Generating documentation..."
doxygen Doxyfile 2>/dev/null || echo "Install doxygen"
echo "Output: docs/html/index.html"

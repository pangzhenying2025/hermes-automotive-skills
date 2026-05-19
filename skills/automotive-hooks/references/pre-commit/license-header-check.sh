#!/usr/bin/env bash
# ==============================================================================
# Hook: license-header-check.sh
# Type: pre-commit
# Purpose: Verify that all source files contain the required license header.
#          Checks C, C++, Python, Java, TypeScript, and YAML files.
# ==============================================================================

set -euo pipefail

# Configuration
HOOK_NAME="license-header-check"
EXIT_CODE=0

# License header patterns to match (first line or within first 10 lines)
# Adjust these patterns to match your organization's license header
LICENSE_PATTERNS=(
    "Copyright"
    "SPDX-License-Identifier"
    "Licensed under"
    "All rights reserved"
)

# File extensions to check
EXTENSIONS_C=("*.c" "*.h" "*.cpp" "*.hpp" "*.cc" "*.hh")
EXTENSIONS_JAVA=("*.java")
EXTENSIONS_PYTHON=("*.py")
EXTENSIONS_TS=("*.ts" "*.tsx")
EXTENSIONS_YAML=("*.yaml" "*.yml")

# Files/directories to exclude
EXCLUDE_DIRS=("node_modules" "build" "dist" ".git" "__pycache__" "venv"
              "target" "generated" "third_party" "vendor")
EXCLUDE_FILES=("__init__.py" "setup.py" "conftest.py")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Build exclude arguments for find
build_exclude_args() {
    local args=""
    for dir in "${EXCLUDE_DIRS[@]}"; do
        args="$args -path '*/${dir}/*' -prune -o"
    done
    echo "$args"
}

# Check if a file contains a license header
check_license_header() {
    local file="$1"
    local filename
    filename=$(basename "$file")

    # Skip excluded files
    for excluded in "${EXCLUDE_FILES[@]}"; do
        if [[ "$filename" == "$excluded" ]]; then
            return 0
        fi
    done

    # Skip empty files
    if [[ ! -s "$file" ]]; then
        return 0
    fi

    # Read first 15 lines of the file
    local header
    header=$(head -n 15 "$file" 2>/dev/null || true)

    # Check if any license pattern exists in the header
    for pattern in "${LICENSE_PATTERNS[@]}"; do
        if echo "$header" | grep -qi "$pattern" 2>/dev/null; then
            return 0
        fi
    done

    # No license header found
    return 1
}

# Get staged files (or all files if not in git context)
get_files_to_check() {
    local extensions=("$@")

    if git rev-parse --is-inside-work-tree &>/dev/null; then
        # In git repo: check staged files only
        for ext in "${extensions[@]}"; do
            git diff --cached --name-only --diff-filter=ACM -- "$ext" 2>/dev/null || true
        done
    else
        # Not in git repo: check all matching files
        for ext in "${extensions[@]}"; do
            find . -name "$ext" -not -path "*/node_modules/*" \
                   -not -path "*/build/*" -not -path "*/.git/*" \
                   -not -path "*/generated/*" -not -path "*/third_party/*" \
                   2>/dev/null || true
        done
    fi
}

# Main check function
run_check() {
    local all_extensions=()
    all_extensions+=("${EXTENSIONS_C[@]}")
    all_extensions+=("${EXTENSIONS_JAVA[@]}")
    all_extensions+=("${EXTENSIONS_PYTHON[@]}")
    all_extensions+=("${EXTENSIONS_TS[@]}")

    local files_checked=0
    local files_missing=0
    local missing_files=()

    echo -e "${YELLOW}[$HOOK_NAME] Checking license headers...${NC}"

    # Get files to check
    local files
    files=$(get_files_to_check "${all_extensions[@]}" | sort -u)

    if [[ -z "$files" ]]; then
        echo -e "${GREEN}[$HOOK_NAME] No source files to check.${NC}"
        return 0
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        files_checked=$((files_checked + 1))

        if ! check_license_header "$file"; then
            files_missing=$((files_missing + 1))
            missing_files+=("$file")
        fi
    done <<< "$files"

    # Report results
    if [[ $files_missing -gt 0 ]]; then
        echo -e "${RED}[$HOOK_NAME] FAILED: $files_missing file(s) missing license header:${NC}"
        for f in "${missing_files[@]}"; do
            echo -e "${RED}  - $f${NC}"
        done
        echo ""
        echo -e "${YELLOW}Expected one of these patterns in the first 15 lines:${NC}"
        for pattern in "${LICENSE_PATTERNS[@]}"; do
            echo -e "${YELLOW}  - $pattern${NC}"
        done
        echo ""
        echo -e "${YELLOW}Example C/C++ header:${NC}"
        echo "  /* Copyright (c) $(date +%Y) Your Organization"
        echo "   * SPDX-License-Identifier: MIT"
        echo "   */"
        echo ""
        echo -e "${YELLOW}Example Python header:${NC}"
        echo "  # Copyright (c) $(date +%Y) Your Organization"
        echo "  # SPDX-License-Identifier: MIT"
        echo ""
        return 1
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: $files_checked file(s) checked, all have license headers.${NC}"
        return 0
    fi
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE

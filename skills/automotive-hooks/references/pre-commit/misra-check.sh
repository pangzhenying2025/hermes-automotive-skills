#!/usr/bin/env bash
set -euo pipefail

################################################################################
# MISRA Compliance Checker Hook
################################################################################
# Purpose: Validate C/C++ code against MISRA coding standards
# Checks:
#   - Runs cppcheck with MISRA addon if available
#   - Falls back to grep-based pattern matching for common violations
#   - Detects: goto usage, dynamic memory in safety code, missing braces,
#     implicit conversions, and other MISRA-C:2012 violations
# Exit codes:
#   0 - Clean, no violations
#   1 - MISRA violations found
################################################################################

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Track violations
violations_found=0

echo -e "${YELLOW}Running MISRA compliance check...${NC}"

# Get staged C/C++ files
mapfile -t staged_files < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(c|cpp|cc|cxx|h|hpp|hxx)$' || true)

if [ ${#staged_files[@]} -eq 0 ]; then
    echo -e "${GREEN}No C/C++ files staged, skipping MISRA check${NC}"
    exit 0
fi

echo "Checking ${#staged_files[@]} C/C++ file(s)..."

################################################################################
# Function: Run cppcheck with MISRA addon
################################################################################
run_cppcheck_misra() {
    local file="$1"

    if command -v cppcheck &> /dev/null; then
        # Check if MISRA addon is available
        local misra_addon=""
        if [ -f "/usr/share/cppcheck/addons/misra.py" ]; then
            misra_addon="--addon=/usr/share/cppcheck/addons/misra.py"
        elif [ -f "$HOME/.local/share/cppcheck/addons/misra.py" ]; then
            misra_addon="--addon=$HOME/.local/share/cppcheck/addons/misra.py"
        fi

        if [ -n "$misra_addon" ]; then
            echo "  Running cppcheck with MISRA addon on $file..."
            if ! cppcheck --quiet --enable=all $misra_addon "$file" 2>&1 | grep -v "^$"; then
                violations_found=1
            fi
        else
            echo "  Running cppcheck (basic) on $file..."
            if ! cppcheck --quiet --enable=warning,style,performance,portability "$file" 2>&1 | grep -v "^$"; then
                violations_found=1
            fi
        fi
        return 0
    fi
    return 1
}

################################################################################
# Function: Grep-based MISRA violation checks
################################################################################
run_grep_checks() {
    local file="$1"
    local file_violations=0

    # MISRA Rule 15.1: Avoid goto statement
    if grep -n "goto " "$file" 2>/dev/null; then
        echo -e "${RED}MISRA 15.1 violation in $file: 'goto' statement found${NC}"
        file_violations=1
    fi

    # MISRA Rule 21.3: Avoid dynamic memory allocation in safety-critical code
    if grep -nE "\b(malloc|calloc|realloc|free)\s*\(" "$file" 2>/dev/null; then
        echo -e "${RED}MISRA 21.3 violation in $file: Dynamic memory allocation found${NC}"
        file_violations=1
    fi

    # MISRA Rule 15.6: All if/else/for/while must have braces (simplified check)
    # Check for single-line if/for/while without braces
    if grep -nE '^\s*(if|for|while)\s*\([^)]+\)\s*[^{].*[^;]\s*$' "$file" 2>/dev/null | grep -v '//'; then
        echo -e "${YELLOW}Warning in $file: Potential missing braces (MISRA 15.6)${NC}"
        # Don't fail on this, just warn
    fi

    # MISRA Rule 10.1/10.3: Check for potential implicit conversions (simplified)
    if grep -nE '\(\s*(unsigned\s+)?int\s*\)' "$file" 2>/dev/null | head -5; then
        echo -e "${YELLOW}Warning in $file: Explicit type cast found, verify implicit conversion safety${NC}"
    fi

    # MISRA Rule 17.5: No more than 2 levels of pointer indirection
    if grep -nE '\*\s*\*\s*\*' "$file" 2>/dev/null; then
        echo -e "${RED}MISRA 17.5 violation in $file: More than 2 levels of pointer indirection${NC}"
        file_violations=1
    fi

    # MISRA Rule 8.9: Check for global variables (simplified - just warn)
    if grep -nE '^(extern\s+)?[a-zA-Z_][a-zA-Z0-9_]*\s+[a-zA-Z_][a-zA-Z0-9_]*\s*(=|;)' "$file" 2>/dev/null | head -3; then
        echo -e "${YELLOW}Info: Global variables detected in $file, verify MISRA 8.9 compliance${NC}"
    fi

    # Check for prohibited function usage in headers
    if [[ "$file" =~ \.(h|hpp|hxx)$ ]]; then
        if grep -nE '\b(printf|sprintf|strcpy|strcat|gets)\s*\(' "$file" 2>/dev/null; then
            echo -e "${RED}MISRA 21.6/21.11 violation in $file: Prohibited standard library function${NC}"
            file_violations=1
        fi
    fi

    return $file_violations
}

################################################################################
# Main check logic
################################################################################
cppcheck_available=false
if command -v cppcheck &> /dev/null; then
    cppcheck_available=true
    echo -e "${GREEN}cppcheck found, using for analysis${NC}"
else
    echo -e "${YELLOW}cppcheck not found, using grep-based fallback checks${NC}"
fi

for file in "${staged_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    echo ""
    echo "Checking: $file"

    if [ "$cppcheck_available" = true ]; then
        if ! run_cppcheck_misra "$file"; then
            # cppcheck failed, fallback to grep
            run_grep_checks "$file" || violations_found=1
        fi
    else
        run_grep_checks "$file" || violations_found=1
    fi
done

################################################################################
# Summary
################################################################################
echo ""
echo "========================================"
if [ $violations_found -eq 0 ]; then
    echo -e "${GREEN}MISRA check PASSED${NC}"
    echo "All C/C++ files comply with checked MISRA rules"
    exit 0
else
    echo -e "${RED}MISRA check FAILED${NC}"
    echo "MISRA violations detected. Please fix the issues above."
    echo ""
    echo "To bypass this check (NOT RECOMMENDED for safety-critical code):"
    echo "  git commit --no-verify"
    exit 1
fi

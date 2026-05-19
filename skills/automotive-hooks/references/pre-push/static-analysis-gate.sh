#!/usr/bin/env bash
# ==============================================================================
# Hook: static-analysis-gate.sh
# Type: pre-push
# Purpose: Ensure static analysis (MISRA/cppcheck/lint) passes before push.
#          Checks for existing analysis reports or runs analysis tools.
# ==============================================================================

set -euo pipefail

HOOK_NAME="static-analysis-gate"
EXIT_CODE=0

# Analysis report locations
REPORT_PATHS=(
    "build/cppcheck-report.xml"
    "build/misra-report.xml"
    "build/static-analysis.xml"
    "build/reports/cppcheck.xml"
    ".scannerwork/report-task.txt"
)

# Configuration
MAX_ERRORS=0        # Zero errors allowed
MAX_WARNINGS=10     # Warnings threshold
CPPCHECK_SUPPRESS=("missingIncludeSystem" "unusedFunction" "unmatchedSuppression")

# Source directories to analyze
SOURCE_DIRS=("src" "lib" "include")
EXCLUDE_DIRS=("build" "test" "third_party" "generated" "vendor")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check available tools
has_cppcheck() { command -v cppcheck &>/dev/null; }
has_clang_tidy() { command -v clang-tidy &>/dev/null; }
has_pylint() { command -v pylint &>/dev/null; }
has_eslint() { command -v eslint &>/dev/null || command -v npx &>/dev/null; }

# Run cppcheck analysis
run_cppcheck() {
    local src_dirs=()
    for dir in "${SOURCE_DIRS[@]}"; do
        [[ -d "$dir" ]] && src_dirs+=("$dir")
    done

    if [[ ${#src_dirs[@]} -eq 0 ]]; then
        echo -e "${YELLOW}  No source directories found for cppcheck.${NC}"
        return 0
    fi

    local suppress_args=""
    for sup in "${CPPCHECK_SUPPRESS[@]}"; do
        suppress_args="$suppress_args --suppress=$sup"
    done

    local exclude_args=""
    for dir in "${EXCLUDE_DIRS[@]}"; do
        [[ -d "$dir" ]] && exclude_args="$exclude_args -i$dir"
    done

    echo -e "${CYAN}  Running cppcheck on: ${src_dirs[*]}${NC}"

    local output_file
    output_file=$(mktemp /tmp/cppcheck-XXXXXX.xml)

    # Run cppcheck
    # shellcheck disable=SC2086
    cppcheck \
        --enable=all \
        --std=c11 \
        --std=c++14 \
        --xml \
        --xml-version=2 \
        $suppress_args \
        $exclude_args \
        --output-file="$output_file" \
        "${src_dirs[@]}" 2>/dev/null || true

    # Parse results
    local error_count=0
    local warning_count=0
    local style_count=0

    if [[ -f "$output_file" ]]; then
        error_count=$(grep -c 'severity="error"' "$output_file" 2>/dev/null || echo 0)
        warning_count=$(grep -c 'severity="warning"' "$output_file" 2>/dev/null || echo 0)
        style_count=$(grep -c 'severity="style"' "$output_file" 2>/dev/null || echo 0)

        # Copy to build directory for archiving
        mkdir -p build
        cp "$output_file" build/cppcheck-report.xml
    fi

    rm -f "$output_file"

    echo "  Results: $error_count errors, $warning_count warnings, $style_count style issues"

    # Check thresholds
    if [[ $error_count -gt $MAX_ERRORS ]]; then
        echo -e "${RED}  cppcheck found $error_count error(s) (max: $MAX_ERRORS)${NC}"

        # Show first few errors
        if [[ -f "build/cppcheck-report.xml" ]]; then
            echo -e "${RED}  First errors:${NC}"
            grep 'severity="error"' build/cppcheck-report.xml | head -5 | while IFS= read -r line; do
                local file msg
                file=$(echo "$line" | grep -oP 'file="[^"]*"' | head -1 | sed 's/file="//;s/"//')
                msg=$(echo "$line" | grep -oP 'msg="[^"]*"' | head -1 | sed 's/msg="//;s/"//')
                echo -e "${RED}    $file: $msg${NC}"
            done
        fi
        return 1
    fi

    if [[ $warning_count -gt $MAX_WARNINGS ]]; then
        echo -e "${YELLOW}  cppcheck found $warning_count warning(s) (max: $MAX_WARNINGS)${NC}"
        return 1
    fi

    return 0
}

# Run Python linting
run_python_lint() {
    local py_files
    py_files=$(find . -name "*.py" -not -path "*/venv/*" -not -path "*/.git/*" \
                      -not -path "*/build/*" -not -path "*/node_modules/*" 2>/dev/null | head -50)

    if [[ -z "$py_files" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Running pylint on Python files...${NC}"

    local error_count=0
    local total_files=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        total_files=$((total_files + 1))

        local output
        output=$(pylint --errors-only "$file" 2>/dev/null || true)
        if [[ -n "$output" ]]; then
            local file_errors
            file_errors=$(echo "$output" | grep -c "^E:" 2>/dev/null || echo 0)
            error_count=$((error_count + file_errors))
        fi
    done <<< "$py_files"

    echo "  Checked $total_files Python files, found $error_count errors"

    if [[ $error_count -gt $MAX_ERRORS ]]; then
        echo -e "${RED}  pylint found $error_count error(s)${NC}"
        return 1
    fi
    return 0
}

# Check for existing analysis report
check_existing_report() {
    for path in "${REPORT_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# Parse existing cppcheck XML report
parse_existing_report() {
    local report="$1"
    local error_count=0
    local warning_count=0

    if echo "$report" | grep -qE "\.xml$"; then
        error_count=$(grep -c 'severity="error"' "$report" 2>/dev/null || echo 0)
        warning_count=$(grep -c 'severity="warning"' "$report" 2>/dev/null || echo 0)
    fi

    echo "ERRORS:$error_count"
    echo "WARNINGS:$warning_count"
}

# Main check
run_check() {
    echo -e "${YELLOW}[$HOOK_NAME] Checking static analysis results...${NC}"

    local any_failed=false

    # Check for existing reports first
    local existing_report
    if existing_report=$(check_existing_report); then
        echo -e "${CYAN}[$HOOK_NAME] Found existing report: $existing_report${NC}"

        local report_data
        report_data=$(parse_existing_report "$existing_report")

        local errors=0 warnings=0
        while IFS= read -r metric; do
            case "$metric" in
                ERRORS:*) errors="${metric#ERRORS:}" ;;
                WARNINGS:*) warnings="${metric#WARNINGS:}" ;;
            esac
        done <<< "$report_data"

        echo "  Report contains: $errors errors, $warnings warnings"

        if [[ $errors -gt $MAX_ERRORS ]]; then
            echo -e "${RED}  Static analysis has $errors error(s) (max: $MAX_ERRORS)${NC}"
            any_failed=true
        fi
    else
        echo -e "${CYAN}[$HOOK_NAME] No existing report found, running analysis...${NC}"

        # Run cppcheck if available and C/C++ sources exist
        if has_cppcheck; then
            if ! run_cppcheck; then
                any_failed=true
            fi
        fi

        # Run pylint if available and Python sources exist
        if has_pylint; then
            if ! run_python_lint; then
                any_failed=true
            fi
        fi

        # If no tools available, warn but don't block
        if ! has_cppcheck && ! has_pylint && ! has_clang_tidy; then
            echo -e "${YELLOW}  No static analysis tools found.${NC}"
            echo -e "${YELLOW}  Install cppcheck, pylint, or clang-tidy for analysis.${NC}"
            echo -e "${YELLOW}  Allowing push (tool installation recommended).${NC}"
            return 0
        fi
    fi

    echo ""
    if [[ "$any_failed" == "true" ]]; then
        echo -e "${RED}[$HOOK_NAME] FAILED: Static analysis issues must be resolved.${NC}"
        return 1
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: Static analysis checks passed.${NC}"
        return 0
    fi
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE

#!/usr/bin/env bash
# ==============================================================================
# Hook: todo-ticket-check.sh
# Type: pre-commit
# Purpose: Ensure all TODO/FIXME/HACK comments reference a ticket ID.
#          Enforces the rule: no TODO without a Jira/issue tracker reference.
# ==============================================================================

set -euo pipefail

HOOK_NAME="todo-ticket-check"
EXIT_CODE=0

# Ticket pattern to match (adjust for your issue tracker)
# Examples: ECUBE-1234, JIRA-567, GH-89, #1234
TICKET_PATTERN='(ECUBE-[0-9]+|JIRA-[0-9]+|GH-[0-9]+|#[0-9]+|ISSUE-[0-9]+)'

# Keywords that require ticket references
TODO_KEYWORDS=("TODO" "FIXME" "HACK" "XXX" "WORKAROUND" "TEMP")

# File extensions to check
CHECK_EXTENSIONS=("c" "h" "cpp" "hpp" "cc" "hh" "java" "py" "ts" "tsx"
                  "js" "jsx" "go" "rs" "rb" "sh" "bash" "yaml" "yml"
                  "xml" "cmake" "proto")

# Directories to exclude
EXCLUDE_DIRS=("node_modules" "build" "dist" ".git" "__pycache__"
              "venv" "target" "generated" "third_party" "vendor")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Build grep pattern for TODO keywords
build_keyword_pattern() {
    local pattern=""
    for keyword in "${TODO_KEYWORDS[@]}"; do
        if [[ -n "$pattern" ]]; then
            pattern="$pattern|$keyword"
        else
            pattern="$keyword"
        fi
    done
    echo "($pattern)"
}

# Check if a line has a TODO keyword without a ticket reference
check_line_for_todo() {
    local line="$1"
    local keyword_pattern
    keyword_pattern=$(build_keyword_pattern)

    # Check if line contains a TODO keyword (case-insensitive)
    if echo "$line" | grep -iE "$keyword_pattern" &>/dev/null; then
        # Check if it also contains a ticket reference
        if echo "$line" | grep -iE "$TICKET_PATTERN" &>/dev/null; then
            return 0  # Has ticket reference - OK
        else
            return 1  # Missing ticket reference - FAIL
        fi
    fi

    return 0  # No TODO keyword found - OK
}

# Get staged files to check
get_staged_files() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true
    else
        # Not in git context - check all files
        for ext in "${CHECK_EXTENSIONS[@]}"; do
            find . -name "*.$ext" -not -path "*/node_modules/*" \
                   -not -path "*/build/*" -not -path "*/.git/*" \
                   -not -path "*/generated/*" 2>/dev/null || true
        done
    fi
}

# Check if file extension is in our check list
should_check_file() {
    local file="$1"
    local ext="${file##*.}"

    for check_ext in "${CHECK_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$check_ext" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if file is in an excluded directory
is_excluded() {
    local file="$1"
    for dir in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$file" == *"/$dir/"* ]] || [[ "$file" == "$dir/"* ]]; then
            return 0
        fi
    done
    return 1
}

# Main check
run_check() {
    local files_checked=0
    local violations_found=0
    local violations=()
    local keyword_pattern
    keyword_pattern=$(build_keyword_pattern)

    echo -e "${YELLOW}[$HOOK_NAME] Checking TODO/FIXME comments for ticket references...${NC}"

    local files
    files=$(get_staged_files | sort -u)

    if [[ -z "$files" ]]; then
        echo -e "${GREEN}[$HOOK_NAME] No files to check.${NC}"
        return 0
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        # Skip excluded directories
        if is_excluded "$file"; then
            continue
        fi

        # Skip non-matching extensions
        if ! should_check_file "$file"; then
            continue
        fi

        files_checked=$((files_checked + 1))

        # Check each line for TODO without ticket
        local line_number=0
        while IFS= read -r line; do
            line_number=$((line_number + 1))

            # Quick pre-filter: skip lines without keywords
            if ! echo "$line" | grep -iqE "$keyword_pattern" 2>/dev/null; then
                continue
            fi

            if ! check_line_for_todo "$line"; then
                violations_found=$((violations_found + 1))
                # Trim leading whitespace for display
                local trimmed_line
                trimmed_line=$(echo "$line" | sed 's/^[[:space:]]*//')
                violations+=("${file}:${line_number}: ${trimmed_line}")
            fi
        done < "$file"
    done <<< "$files"

    # Report results
    if [[ $violations_found -gt 0 ]]; then
        echo -e "${RED}[$HOOK_NAME] FAILED: $violations_found TODO/FIXME comment(s) without ticket reference:${NC}"
        echo ""
        for violation in "${violations[@]}"; do
            echo -e "${RED}  $violation${NC}"
        done
        echo ""
        echo -e "${YELLOW}Every TODO/FIXME/HACK/XXX comment must include a ticket reference.${NC}"
        echo -e "${YELLOW}Accepted patterns: ${TICKET_PATTERN}${NC}"
        echo ""
        echo -e "${CYAN}Examples:${NC}"
        echo "  // TODO(ECUBE-1234): Implement retry logic"
        echo "  # FIXME(JIRA-567): Handle edge case for empty list"
        echo "  /* HACK(GH-89): Temporary workaround for API bug */"
        echo ""
        return 1
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: $files_checked file(s) checked, all TODOs have ticket references.${NC}"
        return 0
    fi
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE

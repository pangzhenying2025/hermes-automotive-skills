#!/usr/bin/env bash
# ==============================================================================
# Hook: documentation-check.sh
# Type: pre-merge
# Purpose: Verify that documentation is updated when code changes affect
#          public APIs, configuration, or architecture. Ensures docs stay
#          in sync with the codebase.
# ==============================================================================

set -euo pipefail

HOOK_NAME="documentation-check"
EXIT_CODE=0

# Configuration
BASE_BRANCH="${BASE_BRANCH:-main}"
DOC_DIRS=("docs" "doc" "documentation" "wiki")
README_FILES=("README.md" "CHANGELOG.md" "MIGRATION.md")

# Code patterns that require documentation updates
API_PATTERNS=("include/*.h" "include/*.hpp" "src/api/*" "api/*" "*.proto"
              "*openapi*.yaml" "*openapi*.yml" "*swagger*")
CONFIG_PATTERNS=("*config*.yaml" "*config*.yml" "*.conf" "*.properties"
                 "*param*.yaml" "*settings*")
ARCH_PATTERNS=("CMakeLists.txt" "Makefile" "docker-compose*" "Dockerfile*"
               "*.cmake" "pom.xml" "build.gradle*")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Track findings
ISSUES=()
WARNINGS=()

# Get changed files compared to base
get_changed_files() {
    git diff --name-only "$BASE_BRANCH"...HEAD 2>/dev/null || \
    git diff --name-only "$BASE_BRANCH" HEAD 2>/dev/null || \
    echo ""
}

# Check if any documentation files were changed
has_doc_changes() {
    local changed_files="$1"

    # Check doc directories
    for dir in "${DOC_DIRS[@]}"; do
        if echo "$changed_files" | grep -q "^${dir}/"; then
            return 0
        fi
    done

    # Check readme files
    for file in "${README_FILES[@]}"; do
        if echo "$changed_files" | grep -qi "$file"; then
            return 0
        fi
    done

    # Check inline documentation (Doxygen comments)
    # If source files changed, check if comment blocks were updated
    return 1
}

# Check if API files were changed
has_api_changes() {
    local changed_files="$1"

    for pattern in "${API_PATTERNS[@]}"; do
        if echo "$changed_files" | grep -qE "$pattern"; then
            return 0
        fi
    done
    return 1
}

# Check if config files were changed
has_config_changes() {
    local changed_files="$1"

    for pattern in "${CONFIG_PATTERNS[@]}"; do
        if echo "$changed_files" | grep -qiE "$pattern"; then
            return 0
        fi
    done
    return 1
}

# Check if architecture files were changed
has_arch_changes() {
    local changed_files="$1"

    for pattern in "${ARCH_PATTERNS[@]}"; do
        if echo "$changed_files" | grep -qE "$pattern"; then
            return 0
        fi
    done
    return 1
}

# Check CHANGELOG update
check_changelog() {
    local changed_files="$1"

    # Count non-doc source changes
    local source_changes
    source_changes=$(echo "$changed_files" | grep -vE "^(docs/|doc/|test/|tests/|\.)" | wc -l)

    if [[ $source_changes -gt 5 ]]; then
        if ! echo "$changed_files" | grep -qi "changelog"; then
            WARNINGS+=("CHANGELOG not updated (${source_changes} source files changed)")
        fi
    fi
}

# Check for new public functions without documentation
check_new_functions_documented() {
    local changed_files="$1"

    local source_files
    source_files=$(echo "$changed_files" | grep -E "\.(c|cpp|h|hpp|java|py|ts)$" || true)

    if [[ -z "$source_files" ]]; then
        return 0
    fi

    local undocumented_count=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        # Get added lines that look like function declarations
        local new_functions
        new_functions=$(git diff "$BASE_BRANCH"...HEAD -- "$file" 2>/dev/null | \
                        grep "^+" | grep -E "(public|export|def |function |void |int |float |bool |char |auto )\s*\w+\s*\(" | \
                        grep -v "^+++" | grep -v "test_\|Test\|mock\|Mock" || true)

        if [[ -z "$new_functions" ]]; then
            continue
        fi

        # Check if new functions have documentation comments above them
        while IFS= read -r func_line; do
            [[ -z "$func_line" ]] && continue
            local func_name
            func_name=$(echo "$func_line" | grep -oE "\w+\s*\(" | head -1 | sed 's/\s*($//')

            # Simple check: look for doc comment patterns near the function
            local has_docs=false
            local context
            context=$(git diff "$BASE_BRANCH"...HEAD -- "$file" 2>/dev/null | \
                      grep -B5 "$func_name" | head -10 || true)

            if echo "$context" | grep -qE "(\/\*\*|\*\/|@brief|@param|///|#\s+|\"\"\"|\@doc)"; then
                has_docs=true
            fi

            if [[ "$has_docs" == "false" ]]; then
                undocumented_count=$((undocumented_count + 1))
                if [[ $undocumented_count -le 5 ]]; then
                    WARNINGS+=("New function '$func_name' in $file may lack documentation")
                fi
            fi
        done <<< "$new_functions"
    done <<< "$source_files"

    if [[ $undocumented_count -gt 5 ]]; then
        WARNINGS+=("... and $((undocumented_count - 5)) more undocumented functions")
    fi
}

# Check commit messages for documentation references
check_commit_messages() {
    local commits
    commits=$(git log "$BASE_BRANCH"...HEAD --oneline 2>/dev/null || echo "")

    if [[ -z "$commits" ]]; then
        return 0
    fi

    # Check if any commit mentions docs update
    if echo "$commits" | grep -qiE "(doc|readme|changelog|migration|breaking)"; then
        return 0  # Documentation was mentioned in commits
    fi

    return 1
}

# Main check
run_check() {
    echo -e "${YELLOW}[$HOOK_NAME] Checking documentation completeness...${NC}"

    # Verify base branch
    if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
        echo -e "${YELLOW}  Base branch '$BASE_BRANCH' not found. Skipping.${NC}"
        return 0
    fi

    local changed_files
    changed_files=$(get_changed_files)

    if [[ -z "$changed_files" ]]; then
        echo -e "${GREEN}[$HOOK_NAME] No changes to check.${NC}"
        return 0
    fi

    local docs_updated=false
    if has_doc_changes "$changed_files"; then
        docs_updated=true
    fi

    # Check API changes require doc updates
    if has_api_changes "$changed_files"; then
        echo -e "${CYAN}  API changes detected.${NC}"
        if [[ "$docs_updated" == "false" ]]; then
            ISSUES+=("API files changed but no documentation updated.")
            ISSUES+=("  Update API documentation (OpenAPI spec, README, or inline docs).")
        fi
    fi

    # Check config changes
    if has_config_changes "$changed_files"; then
        echo -e "${CYAN}  Configuration changes detected.${NC}"
        if [[ "$docs_updated" == "false" ]]; then
            WARNINGS+=("Configuration files changed. Consider updating deployment/setup docs.")
        fi
    fi

    # Check architecture changes
    if has_arch_changes "$changed_files"; then
        echo -e "${CYAN}  Build/architecture changes detected.${NC}"
        if [[ "$docs_updated" == "false" ]]; then
            WARNINGS+=("Build/architecture files changed. Consider updating build/setup docs.")
        fi
    fi

    # Check CHANGELOG
    check_changelog "$changed_files"

    # Check new functions are documented
    check_new_functions_documented "$changed_files"

    echo ""

    # Report warnings (non-blocking)
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}  Documentation warnings:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo -e "${YELLOW}    - $warning${NC}"
        done
        echo ""
    fi

    # Report issues (blocking for API changes)
    if [[ ${#ISSUES[@]} -gt 0 ]]; then
        echo -e "${RED}  Documentation issues:${NC}"
        for issue in "${ISSUES[@]}"; do
            echo -e "${RED}    - $issue${NC}"
        done
        echo ""
        echo -e "${RED}[$HOOK_NAME] FAILED: Documentation must be updated for API changes.${NC}"
        return 1
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[$HOOK_NAME] PASSED with warnings. Consider updating documentation.${NC}"
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: Documentation checks complete.${NC}"
    fi
    return 0
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE

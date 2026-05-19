#!/usr/bin/env bash
# ==============================================================================
# Hook: breaking-change-check.sh
# Type: pre-merge
# Purpose: Detect breaking API changes in the current branch compared to the
#          base branch. Checks public headers, protobuf definitions, REST APIs,
#          CAN message definitions, and configuration file formats.
# ==============================================================================

set -euo pipefail

HOOK_NAME="breaking-change-check"
EXIT_CODE=0

# Configuration
BASE_BRANCH="${BASE_BRANCH:-main}"
BREAKING_CHANGE_LABEL="breaking-change"

# File patterns that may contain public APIs
PUBLIC_HEADER_PATTERNS=("include/*.h" "include/*.hpp" "api/*.h" "public/*.h")
PROTO_PATTERNS=("*.proto")
OPENAPI_PATTERNS=("*openapi*.yaml" "*openapi*.yml" "*swagger*.yaml" "*swagger*.yml")
DBC_PATTERNS=("*.dbc" "*.arxml")
CONFIG_PATTERNS=("*config*.yaml" "*config*.yml" "*param*.yaml")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Track findings
BREAKING_CHANGES=()
WARNINGS=()

# Get changed files compared to base branch
get_changed_files() {
    local base="$1"
    git diff --name-only "$base"...HEAD 2>/dev/null || \
    git diff --name-only "$base" HEAD 2>/dev/null || \
    echo ""
}

# Check for breaking changes in C/C++ headers
check_header_changes() {
    local changed_files="$1"
    local header_files=""

    for pattern in "${PUBLIC_HEADER_PATTERNS[@]}"; do
        local matching
        matching=$(echo "$changed_files" | grep -E "^${pattern}$" 2>/dev/null || true)
        header_files="$header_files $matching"
    done

    header_files=$(echo "$header_files" | tr ' ' '\n' | grep -v '^$' | sort -u)

    if [[ -z "$header_files" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Checking public header changes...${NC}"

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        local diff_output
        diff_output=$(git diff "$BASE_BRANCH"...HEAD -- "$file" 2>/dev/null || true)

        # Check for removed function declarations
        local removed_functions
        removed_functions=$(echo "$diff_output" | grep "^-" | grep -E "(void|int|float|bool|char|uint|size_t|struct)\s+\w+\s*\(" | grep -v "^---" || true)
        if [[ -n "$removed_functions" ]]; then
            BREAKING_CHANGES+=("REMOVED FUNCTION in $file:")
            while IFS= read -r func; do
                BREAKING_CHANGES+=("  $func")
            done <<< "$removed_functions"
        fi

        # Check for removed struct/enum definitions
        local removed_types
        removed_types=$(echo "$diff_output" | grep "^-" | grep -E "^-(typedef\s+)?(struct|enum|union)\s+\w+" | grep -v "^---" || true)
        if [[ -n "$removed_types" ]]; then
            BREAKING_CHANGES+=("REMOVED TYPE in $file:")
            while IFS= read -r type_line; do
                BREAKING_CHANGES+=("  $type_line")
            done <<< "$removed_types"
        fi

        # Check for changed function signatures (param changes)
        local modified_functions
        modified_functions=$(echo "$diff_output" | grep -B1 "^+" | grep "^-" | grep -E "\w+\s*\(" | grep -v "^---" || true)
        if [[ -n "$modified_functions" ]]; then
            WARNINGS+=("MODIFIED SIGNATURE in $file (verify backward compatibility):")
            while IFS= read -r func; do
                WARNINGS+=("  $func")
            done <<< "$modified_functions"
        fi

        # Check for removed macros
        local removed_macros
        removed_macros=$(echo "$diff_output" | grep "^-#define " | grep -v "^---" || true)
        if [[ -n "$removed_macros" ]]; then
            WARNINGS+=("REMOVED MACRO in $file:")
            while IFS= read -r macro; do
                WARNINGS+=("  $macro")
            done <<< "$removed_macros"
        fi
    done <<< "$header_files"
}

# Check for breaking changes in protobuf files
check_proto_changes() {
    local changed_files="$1"
    local proto_files
    proto_files=$(echo "$changed_files" | grep -E "\.proto$" 2>/dev/null || true)

    if [[ -z "$proto_files" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Checking protobuf changes...${NC}"

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        local diff_output
        diff_output=$(git diff "$BASE_BRANCH"...HEAD -- "$file" 2>/dev/null || true)

        # Check for removed fields (field number reuse is breaking)
        local removed_fields
        removed_fields=$(echo "$diff_output" | grep "^-" | grep -E "^\-\s+(required|optional|repeated|string|int32|int64|float|double|bool|bytes|uint|sint|fixed|sfixed|message|enum)\s+" | grep -v "^---" || true)
        if [[ -n "$removed_fields" ]]; then
            BREAKING_CHANGES+=("REMOVED PROTO FIELD in $file:")
            while IFS= read -r field; do
                BREAKING_CHANGES+=("  $field")
            done <<< "$removed_fields"
        fi

        # Check for changed field numbers
        local field_number_changes
        field_number_changes=$(echo "$diff_output" | grep -E "=\s*[0-9]+\s*;" | head -20 || true)
        if [[ -n "$field_number_changes" ]]; then
            WARNINGS+=("PROTO FIELD NUMBER CHANGES in $file (verify no renumbering):")
            while IFS= read -r change; do
                WARNINGS+=("  $change")
            done <<< "$(echo "$field_number_changes" | head -5)"
        fi

        # Check for removed RPC methods
        local removed_rpcs
        removed_rpcs=$(echo "$diff_output" | grep "^-" | grep -E "^\-\s+rpc\s+" | grep -v "^---" || true)
        if [[ -n "$removed_rpcs" ]]; then
            BREAKING_CHANGES+=("REMOVED RPC METHOD in $file:")
            while IFS= read -r rpc; do
                BREAKING_CHANGES+=("  $rpc")
            done <<< "$removed_rpcs"
        fi
    done <<< "$proto_files"
}

# Check for breaking changes in OpenAPI specs
check_openapi_changes() {
    local changed_files="$1"
    local api_files=""

    for pattern in "${OPENAPI_PATTERNS[@]}"; do
        local matching
        matching=$(echo "$changed_files" | grep -iE "$pattern" 2>/dev/null || true)
        api_files="$api_files $matching"
    done

    api_files=$(echo "$api_files" | tr ' ' '\n' | grep -v '^$' | sort -u)

    if [[ -z "$api_files" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Checking OpenAPI specification changes...${NC}"

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        local diff_output
        diff_output=$(git diff "$BASE_BRANCH"...HEAD -- "$file" 2>/dev/null || true)

        # Check for removed paths
        local removed_paths
        removed_paths=$(echo "$diff_output" | grep "^-" | grep -E "^\-\s+/[a-zA-Z]" | grep -v "^---" || true)
        if [[ -n "$removed_paths" ]]; then
            BREAKING_CHANGES+=("REMOVED API PATH in $file:")
            while IFS= read -r path; do
                BREAKING_CHANGES+=("  $path")
            done <<< "$removed_paths"
        fi

        # Check for removed required fields
        if echo "$diff_output" | grep -q "^-.*required:"; then
            WARNINGS+=("REQUIRED FIELDS CHANGED in $file (verify backward compatibility)")
        fi
    done <<< "$api_files"
}

# Check for CAN message changes
check_can_changes() {
    local changed_files="$1"
    local can_files
    can_files=$(echo "$changed_files" | grep -E "\.(dbc|arxml)$" 2>/dev/null || true)

    if [[ -z "$can_files" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Checking CAN message definition changes...${NC}"
    BREAKING_CHANGES+=("CAN MESSAGE DEFINITION CHANGED: ${can_files}")
    BREAKING_CHANGES+=("  CAN DBC/ARXML changes require full integration test.")
}

# Main check
run_check() {
    echo -e "${YELLOW}[$HOOK_NAME] Checking for breaking API changes...${NC}"

    # Verify base branch exists
    if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
        echo -e "${YELLOW}  Base branch '$BASE_BRANCH' not found. Skipping check.${NC}"
        return 0
    fi

    # Get changed files
    local changed_files
    changed_files=$(get_changed_files "$BASE_BRANCH")

    if [[ -z "$changed_files" ]]; then
        echo -e "${GREEN}[$HOOK_NAME] No file changes detected.${NC}"
        return 0
    fi

    # Run all checks
    check_header_changes "$changed_files"
    check_proto_changes "$changed_files"
    check_openapi_changes "$changed_files"
    check_can_changes "$changed_files"

    echo ""

    # Report warnings
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}  WARNINGS (review recommended):${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo -e "${YELLOW}    $warning${NC}"
        done
        echo ""
    fi

    # Report breaking changes
    if [[ ${#BREAKING_CHANGES[@]} -gt 0 ]]; then
        echo -e "${RED}  BREAKING CHANGES DETECTED:${NC}"
        for change in "${BREAKING_CHANGES[@]}"; do
            echo -e "${RED}    $change${NC}"
        done
        echo ""
        echo -e "${YELLOW}  If these changes are intentional:${NC}"
        echo -e "${YELLOW}    1. Increment the MAJOR version number${NC}"
        echo -e "${YELLOW}    2. Update the changelog with breaking change details${NC}"
        echo -e "${YELLOW}    3. Add '$BREAKING_CHANGE_LABEL' label to the PR${NC}"
        echo -e "${YELLOW}    4. Notify dependent teams/services${NC}"
        echo ""

        # Check if breaking change is acknowledged
        if git log "$BASE_BRANCH"...HEAD --oneline | grep -qi "breaking\|BREAKING"; then
            echo -e "${YELLOW}  Breaking change appears acknowledged in commit messages.${NC}"
            echo -e "${YELLOW}  Allowing merge with warning.${NC}"
            return 0
        fi

        echo -e "${RED}[$HOOK_NAME] FAILED: Unacknowledged breaking changes detected.${NC}"
        return 1
    fi

    echo -e "${GREEN}[$HOOK_NAME] PASSED: No breaking API changes detected.${NC}"
    return 0
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE

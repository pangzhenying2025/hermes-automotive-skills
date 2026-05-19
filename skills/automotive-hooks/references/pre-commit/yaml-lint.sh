#!/usr/bin/env bash
# ==============================================================================
# Hook: yaml-lint.sh
# Type: pre-commit
# Purpose: Validate YAML file syntax and formatting for staged files.
#          Checks for valid syntax, consistent indentation, and common issues.
# ==============================================================================

set -euo pipefail

HOOK_NAME="yaml-lint"
EXIT_CODE=0

# Configuration
MAX_LINE_LENGTH=200
INDENT_SPACES=2
ALLOW_DUPLICATE_KEYS=false

# Directories to exclude
EXCLUDE_DIRS=("node_modules" "build" "dist" ".git" "venv"
              "target" "generated" "third_party" "vendor"
              ".terraform" ".github/actions")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if yamllint is available
check_yamllint() {
    if command -v yamllint &>/dev/null; then
        echo "yamllint"
        return 0
    fi
    return 1
}

# Check if python with yaml module is available
check_python_yaml() {
    if command -v python3 &>/dev/null; then
        if python3 -c "import yaml" 2>/dev/null; then
            echo "python3"
            return 0
        fi
    fi
    if command -v python &>/dev/null; then
        if python -c "import yaml" 2>/dev/null; then
            echo "python"
            return 0
        fi
    fi
    return 1
}

# Validate YAML syntax using Python
validate_yaml_python() {
    local file="$1"
    local python_cmd="$2"

    $python_cmd -c "
import yaml
import sys

try:
    with open('$file', 'r') as f:
        docs = list(yaml.safe_load_all(f))
    sys.exit(0)
except yaml.YAMLError as e:
    print(f'YAML syntax error: {e}', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'Error reading file: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1
}

# Validate YAML using yamllint
validate_yaml_yamllint() {
    local file="$1"

    # Create temporary yamllint config
    local config_file
    config_file=$(mktemp /tmp/yamllint-config-XXXXXX.yaml)

    cat > "$config_file" << 'YAMLCONFIG'
extends: default
rules:
  line-length:
    max: 200
    allow-non-breakable-inline-mappings: true
  indentation:
    spaces: 2
    indent-sequences: true
  truthy:
    check-keys: false
  comments:
    min-spaces-from-content: 1
  document-start: disable
  empty-lines:
    max: 2
  new-line-at-end-of-file: enable
YAMLCONFIG

    local output
    output=$(yamllint -c "$config_file" "$file" 2>&1) || {
        rm -f "$config_file"
        echo "$output"
        return 1
    }
    rm -f "$config_file"

    if [[ -n "$output" ]]; then
        echo "$output"
        # Check if only warnings (no errors)
        if echo "$output" | grep -q "error"; then
            return 1
        fi
    fi
    return 0
}

# Basic YAML checks without external tools
validate_yaml_basic() {
    local file="$1"
    local errors=()
    local line_number=0

    while IFS= read -r line; do
        line_number=$((line_number + 1))

        # Check for tabs (YAML should use spaces)
        if echo "$line" | grep -P "^\t" &>/dev/null; then
            errors+=("Line $line_number: Tab character used for indentation (use spaces)")
        fi

        # Check for trailing whitespace
        if echo "$line" | grep -E "\s+$" &>/dev/null; then
            errors+=("Line $line_number: Trailing whitespace")
        fi

        # Check line length
        local length=${#line}
        if [[ $length -gt $MAX_LINE_LENGTH ]]; then
            errors+=("Line $line_number: Line too long ($length > $MAX_LINE_LENGTH)")
        fi

        # Check for common YAML mistakes
        # Duplicate colon without space
        if echo "$line" | grep -E "^[^#]*[^ ]:.[^ ]" &>/dev/null; then
            # Allow URLs and timestamps
            if ! echo "$line" | grep -E "(http|https|ftp|[0-9]{2}:[0-9]{2})" &>/dev/null; then
                errors+=("Line $line_number: Missing space after colon")
            fi
        fi

    done < "$file"

    if [[ ${#errors[@]} -gt 0 ]]; then
        for error in "${errors[@]}"; do
            echo "  $error"
        done
        return 1
    fi
    return 0
}

# Check if file is in excluded directory
is_excluded() {
    local file="$1"
    for dir in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$file" == *"/$dir/"* ]] || [[ "$file" == "$dir/"* ]]; then
            return 0
        fi
    done
    return 1
}

# Get staged YAML files
get_yaml_files() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git diff --cached --name-only --diff-filter=ACM -- "*.yaml" "*.yml" 2>/dev/null || true
    else
        find . \( -name "*.yaml" -o -name "*.yml" \) \
               -not -path "*/node_modules/*" \
               -not -path "*/build/*" \
               -not -path "*/.git/*" 2>/dev/null || true
    fi
}

# Main check
run_check() {
    local files_checked=0
    local files_failed=0
    local failed_files=()
    local validator=""

    echo -e "${YELLOW}[$HOOK_NAME] Validating YAML files...${NC}"

    # Determine validation tool
    if validator=$(check_yamllint 2>/dev/null); then
        echo -e "${CYAN}[$HOOK_NAME] Using yamllint for validation${NC}"
    elif validator=$(check_python_yaml 2>/dev/null); then
        echo -e "${CYAN}[$HOOK_NAME] Using Python YAML parser for validation${NC}"
    else
        echo -e "${CYAN}[$HOOK_NAME] Using basic validation (install yamllint for better checks)${NC}"
        validator="basic"
    fi

    # Get files to check
    local files
    files=$(get_yaml_files | sort -u)

    if [[ -z "$files" ]]; then
        echo -e "${GREEN}[$HOOK_NAME] No YAML files to check.${NC}"
        return 0
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        if is_excluded "$file"; then
            continue
        fi

        files_checked=$((files_checked + 1))
        local output=""
        local failed=false

        case "$validator" in
            yamllint)
                if ! output=$(validate_yaml_yamllint "$file" 2>&1); then
                    failed=true
                fi
                ;;
            python3|python)
                if ! output=$(validate_yaml_python "$file" "$validator" 2>&1); then
                    failed=true
                fi
                ;;
            basic)
                if ! output=$(validate_yaml_basic "$file" 2>&1); then
                    failed=true
                fi
                ;;
        esac

        if [[ "$failed" == "true" ]]; then
            files_failed=$((files_failed + 1))
            failed_files+=("$file")
            echo -e "${RED}  FAIL: $file${NC}"
            if [[ -n "$output" ]]; then
                echo "$output" | sed 's/^/    /'
            fi
        fi
    done <<< "$files"

    # Report results
    if [[ $files_failed -gt 0 ]]; then
        echo ""
        echo -e "${RED}[$HOOK_NAME] FAILED: $files_failed of $files_checked YAML file(s) have issues.${NC}"
        return 1
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: $files_checked YAML file(s) validated successfully.${NC}"
        return 0
    fi
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE

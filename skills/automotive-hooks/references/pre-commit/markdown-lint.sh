#!/usr/bin/env bash
# ==============================================================================
# Hook: markdown-lint.sh
# Type: pre-commit
# Purpose: Check Markdown files for formatting and style issues.
#          Verifies headings, links, line length, and consistent formatting.
# ==============================================================================

set -euo pipefail

HOOK_NAME="markdown-lint"
EXIT_CODE=0

# Configuration
MAX_LINE_LENGTH=120
MAX_HEADING_LENGTH=80
ALLOW_TRAILING_SPACES=false
REQUIRE_BLANK_LINE_BEFORE_HEADING=true
CHECK_LINK_SYNTAX=true

# Exclude directories
EXCLUDE_DIRS=("node_modules" "build" "dist" ".git" "venv"
              "target" "generated" "third_party" "vendor")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if markdownlint-cli is available
has_markdownlint() {
    command -v markdownlint &>/dev/null || command -v markdownlint-cli2 &>/dev/null
}

# Validate using markdownlint-cli
validate_markdownlint() {
    local file="$1"
    local config_file
    config_file=$(mktemp /tmp/mdlint-config-XXXXXX.json)

    cat > "$config_file" << 'MDCONFIG'
{
  "default": true,
  "MD013": { "line_length": 120 },
  "MD033": false,
  "MD041": false,
  "MD024": { "allow_different_nesting": true },
  "MD034": false
}
MDCONFIG

    local output
    if command -v markdownlint &>/dev/null; then
        output=$(markdownlint --config "$config_file" "$file" 2>&1) || {
            rm -f "$config_file"
            echo "$output"
            return 1
        }
    fi

    rm -f "$config_file"
    if [[ -n "$output" ]]; then
        echo "$output"
        return 1
    fi
    return 0
}

# Basic markdown checks without external tools
validate_markdown_basic() {
    local file="$1"
    local errors=()
    local warnings=()
    local line_number=0
    local prev_line=""
    local in_code_block=false
    local heading_levels=()
    local has_h1=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        line_number=$((line_number + 1))

        # Track code block state (skip checks inside code blocks)
        if [[ "$line" =~ ^\`\`\` ]]; then
            if [[ "$in_code_block" == "true" ]]; then
                in_code_block=false
            else
                in_code_block=true
            fi
            prev_line="$line"
            continue
        fi

        if [[ "$in_code_block" == "true" ]]; then
            prev_line="$line"
            continue
        fi

        # Check: Trailing whitespace (except deliberate line breaks)
        if [[ "$ALLOW_TRAILING_SPACES" == "false" ]]; then
            if echo "$line" | grep -E " +$" &>/dev/null; then
                # Allow exactly 2 trailing spaces (MD line break)
                local trailing
                trailing=$(echo "$line" | grep -oE " +$" | wc -c)
                if [[ $trailing -ne 3 ]]; then  # 2 spaces + newline
                    warnings+=("Line $line_number: Trailing whitespace")
                fi
            fi
        fi

        # Check: Line length (skip URLs and tables)
        local length=${#line}
        if [[ $length -gt $MAX_LINE_LENGTH ]]; then
            # Skip lines with URLs
            if ! echo "$line" | grep -qE "(https?://|ftp://)" ; then
                # Skip table lines
                if ! echo "$line" | grep -qE "^\|" ; then
                    warnings+=("Line $line_number: Line too long ($length > $MAX_LINE_LENGTH)")
                fi
            fi
        fi

        # Check: Heading format
        if [[ "$line" =~ ^(#{1,6})\ (.+) ]]; then
            local heading_prefix="${BASH_REMATCH[1]}"
            local heading_text="${BASH_REMATCH[2]}"
            local heading_level=${#heading_prefix}

            # Track headings
            heading_levels+=("$heading_level")
            if [[ $heading_level -eq 1 ]]; then
                has_h1=true
            fi

            # Check heading length
            if [[ ${#heading_text} -gt $MAX_HEADING_LENGTH ]]; then
                warnings+=("Line $line_number: Heading too long (${#heading_text} > $MAX_HEADING_LENGTH)")
            fi

            # Check blank line before heading (except first line)
            if [[ "$REQUIRE_BLANK_LINE_BEFORE_HEADING" == "true" ]] && \
               [[ $line_number -gt 1 ]] && [[ -n "$prev_line" ]]; then
                errors+=("Line $line_number: Missing blank line before heading")
            fi

            # Check: No trailing hash
            if echo "$heading_text" | grep -qE "#\s*$" ; then
                warnings+=("Line $line_number: Trailing hash in heading")
            fi
        fi

        # Check: Heading without space after hash
        if echo "$line" | grep -qE "^#{1,6}[^# ]" ; then
            errors+=("Line $line_number: Missing space after heading hash marks")
        fi

        # Check: Bare URLs (should be linked)
        if [[ "$CHECK_LINK_SYNTAX" == "true" ]]; then
            if echo "$line" | grep -qE "(?<!\(|<)https?://[^\s\)>]+" 2>/dev/null; then
                # Skip if already in markdown link syntax [text](url) or <url>
                if ! echo "$line" | grep -qE "\[.*\]\(https?://" && \
                   ! echo "$line" | grep -qE "<https?://" ; then
                    warnings+=("Line $line_number: Bare URL (consider using markdown link syntax)")
                fi
            fi
        fi

        # Check: Multiple blank lines
        if [[ -z "$line" ]] && [[ -z "$prev_line" ]] && [[ $line_number -gt 2 ]]; then
            warnings+=("Line $line_number: Multiple consecutive blank lines")
        fi

        # Check: Tab indentation
        if echo "$line" | grep -qP "^\t" ; then
            warnings+=("Line $line_number: Tab used for indentation (use spaces)")
        fi

        prev_line="$line"
    done < "$file"

    # Check: File should end with newline
    if [[ -s "$file" ]]; then
        local last_char
        last_char=$(tail -c 1 "$file" | xxd -p)
        if [[ "$last_char" != "0a" ]] && [[ -n "$last_char" ]]; then
            warnings+=("File does not end with a newline")
        fi
    fi

    # Output results
    local has_issues=false
    if [[ ${#errors[@]} -gt 0 ]]; then
        for error in "${errors[@]}"; do
            echo "  ERROR: $error"
        done
        has_issues=true
    fi
    if [[ ${#warnings[@]} -gt 0 ]]; then
        for warning in "${warnings[@]}"; do
            echo "  WARN:  $warning"
        done
        has_issues=true
    fi

    if [[ "$has_issues" == "true" ]]; then
        return 1
    fi
    return 0
}

# Check if file is excluded
is_excluded() {
    local file="$1"
    for dir in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$file" == *"/$dir/"* ]] || [[ "$file" == "$dir/"* ]]; then
            return 0
        fi
    done
    return 1
}

# Get staged markdown files
get_markdown_files() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git diff --cached --name-only --diff-filter=ACM -- "*.md" "*.markdown" 2>/dev/null || true
    else
        find . \( -name "*.md" -o -name "*.markdown" \) \
               -not -path "*/.git/*" \
               -not -path "*/node_modules/*" \
               -not -path "*/build/*" 2>/dev/null || true
    fi
}

# Main check
run_check() {
    local files_checked=0
    local files_with_issues=0

    echo -e "${YELLOW}[$HOOK_NAME] Checking Markdown formatting...${NC}"

    local use_markdownlint=false
    if has_markdownlint; then
        echo -e "${CYAN}[$HOOK_NAME] Using markdownlint for validation${NC}"
        use_markdownlint=true
    else
        echo -e "${CYAN}[$HOOK_NAME] Using built-in checks (install markdownlint-cli for more)${NC}"
    fi

    local files
    files=$(get_markdown_files | sort -u)

    if [[ -z "$files" ]]; then
        echo -e "${GREEN}[$HOOK_NAME] No Markdown files to check.${NC}"
        return 0
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue
        is_excluded "$file" && continue

        files_checked=$((files_checked + 1))
        local output=""

        if [[ "$use_markdownlint" == "true" ]]; then
            if ! output=$(validate_markdownlint "$file" 2>&1); then
                files_with_issues=$((files_with_issues + 1))
                echo -e "${RED}  ISSUES: $file${NC}"
                echo "$output" | sed 's/^/    /'
            fi
        else
            if ! output=$(validate_markdown_basic "$file" 2>&1); then
                files_with_issues=$((files_with_issues + 1))
                echo -e "${YELLOW}  ISSUES: $file${NC}"
                echo "$output" | sed 's/^/    /'
            fi
        fi
    done <<< "$files"

    if [[ $files_with_issues -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}[$HOOK_NAME] WARNING: $files_with_issues of $files_checked file(s) have formatting issues.${NC}"
        # Markdown lint is a warning, not a blocker
        return 0
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: $files_checked Markdown file(s) checked.${NC}"
        return 0
    fi
}

# Execute
run_check
exit $EXIT_CODE

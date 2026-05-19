#!/usr/bin/env bash
# ==============================================================================
# Hook: file-size-check.sh
# Type: pre-commit
# Purpose: Prevent oversized files from being committed. Enforces maximum
#          file sizes for source code and binaries to keep the repository
#          manageable and catch accidental large file additions.
# ==============================================================================

set -euo pipefail

HOOK_NAME="file-size-check"
EXIT_CODE=0

# Configuration: Maximum file sizes in bytes
MAX_SOURCE_FILE_KB=500       # Source code files
MAX_CONFIG_FILE_KB=100       # Configuration files
MAX_BINARY_FILE_KB=5120      # Binary files (5 MB)
MAX_ANY_FILE_KB=10240        # Absolute maximum (10 MB)
MAX_SOURCE_LINES=500         # Maximum source lines per file

# File type classifications
SOURCE_EXTENSIONS=("c" "h" "cpp" "hpp" "cc" "hh" "java" "py" "ts" "tsx"
                   "js" "jsx" "go" "rs" "rb" "swift" "kt" "scala")
CONFIG_EXTENSIONS=("yaml" "yml" "json" "toml" "ini" "cfg" "conf" "xml"
                   "properties")
BINARY_EXTENSIONS=("bin" "elf" "hex" "o" "so" "dll" "lib" "a" "exe"
                   "zip" "tar" "gz" "bz2" "xz" "jar" "war" "ear"
                   "png" "jpg" "jpeg" "gif" "bmp" "ico" "svg"
                   "pdf" "doc" "docx" "xls" "xlsx")

# Known large files to exempt (by path pattern)
EXEMPT_PATTERNS=(
    "*.pb.go"           # Generated protobuf
    "*.generated.*"     # Generated code
    "package-lock.json" # NPM lock file
    "yarn.lock"         # Yarn lock file
    "Cargo.lock"        # Rust lock file
    "go.sum"            # Go checksum
    "*.min.js"          # Minified JavaScript
    "*.min.css"         # Minified CSS
)

# Directories to exclude
EXCLUDE_DIRS=("node_modules" "build" "dist" ".git" "venv"
              "target" "generated" "third_party" "vendor")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Convert KB to human-readable
human_size() {
    local size_kb=$1
    if [[ $size_kb -ge 1024 ]]; then
        echo "$((size_kb / 1024)) MB"
    else
        echo "${size_kb} KB"
    fi
}

# Get file extension
get_extension() {
    local file="$1"
    echo "${file##*.}" | tr '[:upper:]' '[:lower:]'
}

# Check if extension is in a list
in_extension_list() {
    local ext="$1"
    shift
    local list=("$@")
    for check_ext in "${list[@]}"; do
        if [[ "$ext" == "$check_ext" ]]; then
            return 0
        fi
    done
    return 1
}

# Check if file matches an exempt pattern
is_exempt() {
    local file="$1"
    local basename
    basename=$(basename "$file")
    for pattern in "${EXEMPT_PATTERNS[@]}"; do
        # shellcheck disable=SC2254
        case "$basename" in
            $pattern) return 0 ;;
        esac
    done
    return 1
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

# Get maximum allowed size for a file type
get_max_size_kb() {
    local file="$1"
    local ext
    ext=$(get_extension "$file")

    if in_extension_list "$ext" "${SOURCE_EXTENSIONS[@]}"; then
        echo $MAX_SOURCE_FILE_KB
    elif in_extension_list "$ext" "${CONFIG_EXTENSIONS[@]}"; then
        echo $MAX_CONFIG_FILE_KB
    elif in_extension_list "$ext" "${BINARY_EXTENSIONS[@]}"; then
        echo $MAX_BINARY_FILE_KB
    else
        echo $MAX_ANY_FILE_KB
    fi
}

# Count lines in a source file
count_source_lines() {
    local file="$1"
    # Count non-empty, non-comment lines
    wc -l < "$file" 2>/dev/null || echo 0
}

# Get staged files
get_staged_files() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true
    else
        find . -type f -not -path "*/.git/*" -not -path "*/node_modules/*" \
               -not -path "*/build/*" 2>/dev/null || true
    fi
}

# Main check
run_check() {
    local files_checked=0
    local size_violations=0
    local line_violations=0
    local size_issues=()
    local line_issues=()

    echo -e "${YELLOW}[$HOOK_NAME] Checking file sizes...${NC}"

    local files
    files=$(get_staged_files | sort -u)

    if [[ -z "$files" ]]; then
        echo -e "${GREEN}[$HOOK_NAME] No files to check.${NC}"
        return 0
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue
        is_excluded "$file" && continue
        is_exempt "$file" && continue

        files_checked=$((files_checked + 1))

        # Check file size
        local file_size_bytes
        file_size_bytes=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
        local file_size_kb=$((file_size_bytes / 1024))
        local max_size_kb
        max_size_kb=$(get_max_size_kb "$file")

        if [[ $file_size_kb -gt $max_size_kb ]]; then
            size_violations=$((size_violations + 1))
            size_issues+=("$file: $(human_size $file_size_kb) (max: $(human_size $max_size_kb))")
        fi

        # Check source file line count
        local ext
        ext=$(get_extension "$file")
        if in_extension_list "$ext" "${SOURCE_EXTENSIONS[@]}"; then
            local line_count
            line_count=$(count_source_lines "$file")
            if [[ $line_count -gt $MAX_SOURCE_LINES ]]; then
                line_violations=$((line_violations + 1))
                line_issues+=("$file: $line_count lines (max: $MAX_SOURCE_LINES)")
            fi
        fi
    done <<< "$files"

    # Report size violations (blocking)
    if [[ $size_violations -gt 0 ]]; then
        echo -e "${RED}[$HOOK_NAME] FAILED: $size_violations file(s) exceed size limits:${NC}"
        for issue in "${size_issues[@]}"; do
            echo -e "${RED}  - $issue${NC}"
        done
        echo ""
        echo -e "${YELLOW}Consider:${NC}"
        echo "  - Use Git LFS for large binary files"
        echo "  - Split large source files into smaller modules"
        echo "  - Compress data files before committing"
        echo "  - Add to .gitignore if not needed in version control"
        EXIT_CODE=1
    fi

    # Report line count violations (warning)
    if [[ $line_violations -gt 0 ]]; then
        echo -e "${YELLOW}[$HOOK_NAME] WARNING: $line_violations source file(s) exceed line limit:${NC}"
        for issue in "${line_issues[@]}"; do
            echo -e "${YELLOW}  - $issue${NC}"
        done
        echo -e "${CYAN}  Consider splitting into smaller modules.${NC}"
    fi

    if [[ $size_violations -eq 0 ]] && [[ $line_violations -eq 0 ]]; then
        echo -e "${GREEN}[$HOOK_NAME] PASSED: $files_checked file(s) checked, all within limits.${NC}"
    elif [[ $size_violations -eq 0 ]]; then
        echo -e "${GREEN}[$HOOK_NAME] PASSED (with warnings): Size checks OK for $files_checked files.${NC}"
    fi

    return $EXIT_CODE
}

# Execute
run_check
exit $EXIT_CODE

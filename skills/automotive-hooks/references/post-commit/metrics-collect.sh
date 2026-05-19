#!/usr/bin/env bash
# ==============================================================================
# Hook: metrics-collect.sh
# Type: post-commit
# Purpose: Collect and record commit metrics for engineering analytics.
#          Tracks code churn, file changes, commit frequency, and complexity.
# ==============================================================================

set -euo pipefail

HOOK_NAME="metrics-collect"

# Configuration
METRICS_DIR="${METRICS_DIR:-.metrics}"
METRICS_FILE="$METRICS_DIR/commit-metrics.jsonl"
MAX_METRICS_FILE_SIZE_KB=10240  # 10 MB, rotate after this

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure metrics directory exists
ensure_metrics_dir() {
    mkdir -p "$METRICS_DIR"

    # Add to .gitignore if not already there
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "^\.metrics/" .gitignore 2>/dev/null; then
            echo ".metrics/" >> .gitignore
        fi
    fi
}

# Get current commit info
get_commit_info() {
    local format="$1"
    git log -1 --format="$format" 2>/dev/null || echo ""
}

# Count files by type in the diff
count_files_by_type() {
    local diff_stat
    diff_stat=$(git diff --name-only HEAD~1..HEAD 2>/dev/null || echo "")

    local c_files=0 py_files=0 java_files=0 ts_files=0 other_files=0
    local test_files=0 doc_files=0 config_files=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        local ext="${file##*.}"

        case "$ext" in
            c|h|cpp|hpp|cc|hh) c_files=$((c_files + 1)) ;;
            py) py_files=$((py_files + 1)) ;;
            java) java_files=$((java_files + 1)) ;;
            ts|tsx|js|jsx) ts_files=$((ts_files + 1)) ;;
            md|txt|rst|adoc) doc_files=$((doc_files + 1)) ;;
            yaml|yml|json|toml|xml|ini|conf) config_files=$((config_files + 1)) ;;
            *) other_files=$((other_files + 1)) ;;
        esac

        # Count test files
        if echo "$file" | grep -qiE "(test|spec|_test\.|\.test\.)"; then
            test_files=$((test_files + 1))
        fi
    done <<< "$diff_stat"

    echo "\"c_cpp\": $c_files, \"python\": $py_files, \"java\": $java_files,"
    echo "\"typescript\": $ts_files, \"docs\": $doc_files, \"config\": $config_files,"
    echo "\"test\": $test_files, \"other\": $other_files"
}

# Calculate code churn (lines added/removed)
get_code_churn() {
    local stat
    stat=$(git diff --shortstat HEAD~1..HEAD 2>/dev/null || echo "")

    local files_changed=0 insertions=0 deletions=0

    if [[ -n "$stat" ]]; then
        files_changed=$(echo "$stat" | grep -oE "[0-9]+ file" | grep -oE "[0-9]+" || echo 0)
        insertions=$(echo "$stat" | grep -oE "[0-9]+ insertion" | grep -oE "[0-9]+" || echo 0)
        deletions=$(echo "$stat" | grep -oE "[0-9]+ deletion" | grep -oE "[0-9]+" || echo 0)
    fi

    echo "\"files_changed\": $files_changed, \"insertions\": $insertions, \"deletions\": $deletions"
}

# Classify commit type from message
classify_commit() {
    local message="$1"

    if echo "$message" | grep -qiE "^feat(\(|:)"; then echo "feature"
    elif echo "$message" | grep -qiE "^fix(\(|:)"; then echo "bugfix"
    elif echo "$message" | grep -qiE "^refactor(\(|:)"; then echo "refactor"
    elif echo "$message" | grep -qiE "^test(\(|:)"; then echo "test"
    elif echo "$message" | grep -qiE "^doc(\(|:)"; then echo "docs"
    elif echo "$message" | grep -qiE "^chore(\(|:)"; then echo "chore"
    elif echo "$message" | grep -qiE "^ci(\(|:)"; then echo "ci"
    elif echo "$message" | grep -qiE "^perf(\(|:)"; then echo "perf"
    elif echo "$message" | grep -qiE "^style(\(|:)"; then echo "style"
    else echo "other"
    fi
}

# Extract scope from conventional commit
extract_scope() {
    local message="$1"
    local scope
    scope=$(echo "$message" | grep -oE "^\w+\(([^)]+)\)" | grep -oE "\([^)]+\)" | tr -d '()' || echo "")
    echo "${scope:-none}"
}

# Check if this is a merge commit
is_merge_commit() {
    local parents
    parents=$(git log -1 --format="%P" 2>/dev/null | wc -w)
    [[ $parents -gt 1 ]]
}

# Rotate metrics file if too large
rotate_metrics_file() {
    if [[ -f "$METRICS_FILE" ]]; then
        local size_kb
        size_kb=$(du -k "$METRICS_FILE" 2>/dev/null | cut -f1 || echo 0)
        if [[ $size_kb -gt $MAX_METRICS_FILE_SIZE_KB ]]; then
            local archive_name="${METRICS_FILE}.$(date +%Y%m%d%H%M%S).bak"
            mv "$METRICS_FILE" "$archive_name"
            # Keep only last 5 archives
            ls -t "${METRICS_FILE}".*.bak 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
        fi
    fi
}

# Collect and write metrics
collect_metrics() {
    local commit_hash
    commit_hash=$(get_commit_info "%H")
    local short_hash
    short_hash=$(get_commit_info "%h")
    local author
    author=$(get_commit_info "%an")
    local author_email
    author_email=$(get_commit_info "%ae")
    local timestamp
    timestamp=$(get_commit_info "%aI")
    local message
    message=$(get_commit_info "%s")
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    local commit_type
    commit_type=$(classify_commit "$message")
    local scope
    scope=$(extract_scope "$message")
    local is_merge="false"
    is_merge_commit && is_merge="true"

    local churn
    churn=$(get_code_churn)
    local file_types
    file_types=$(count_files_by_type)

    # Build JSON record (one line per commit)
    local record
    record=$(cat << EOF
{"timestamp": "$timestamp", "commit": "$short_hash", "author": "$author", "email": "$author_email", "branch": "$branch", "type": "$commit_type", "scope": "$scope", "is_merge": $is_merge, "churn": {$churn}, "files_by_type": {$file_types}, "message": "$(echo "$message" | sed 's/"/\\"/g' | head -c 200)"}
EOF
)

    # Write to metrics file
    echo "$record" >> "$METRICS_FILE"
}

# Main
run_collect() {
    # Run silently in background to not slow down commits
    ensure_metrics_dir
    rotate_metrics_file
    collect_metrics

    echo -e "${GREEN}[$HOOK_NAME] Metrics recorded.${NC}"
}

# Execute (non-blocking - errors should not prevent commit)
run_collect 2>/dev/null || true

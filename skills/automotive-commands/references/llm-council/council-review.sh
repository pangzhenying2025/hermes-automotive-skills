#!/usr/bin/env bash
#
# council-review.sh - Multi-model code review using LLM Council
#
# Usage:
#   council-review.sh <file-or-diff> [OPTIONS]
#
# Options:
#   --language=LANG     Programming language (auto-detected if not specified)
#   --focus=AREAS       Comma-separated focus areas (safety,performance,style)
#   --context=FILE      Additional context file
#   --output=DIR        Output directory for review artifacts
#   --pr=NUMBER         GitHub PR number to review
#   --commit=SHA        Git commit SHA to review
#   --verbose           Enable verbose output
#
# Examples:
#   council-review.sh src/battery/bms.cpp --language=cpp --focus=safety,misra
#   council-review.sh --pr=123 --focus=security
#   council-review.sh --commit=abc123
#
# Environment:
#   ANTHROPIC_API_KEY       Required: Anthropic API key
#   AZURE_OPENAI_API_KEY    Required: Azure OpenAI API key
#   AZURE_OPENAI_ENDPOINT   Required: Azure OpenAI endpoint URL
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
FILE_PATH=""
LANGUAGE=""
FOCUS_AREAS="correctness,safety,performance,maintainability"
CONTEXT_FILE=""
OUTPUT_DIR="${LLM_COUNCIL_OUTPUT:-/tmp/llm-council-review}"
PR_NUMBER=""
COMMIT_SHA=""
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
    cat << 'EOF'
LLM Council Code Review - Multi-Model Review System

Usage:
    council-review.sh <file-or-diff> [OPTIONS]
    council-review.sh --pr=NUMBER [OPTIONS]
    council-review.sh --commit=SHA [OPTIONS]

Options:
    --language=LANG     Programming language (cpp, python, java, etc.)
    --focus=AREAS       Comma-separated focus areas
    --context=FILE      Additional context file (JSON)
    --output=DIR        Output directory for artifacts
    --pr=NUMBER         GitHub PR number to review
    --commit=SHA        Git commit SHA to review
    --verbose           Enable verbose output
    --help              Show this help message

Focus Areas:
    correctness         Logic errors, bugs, edge cases
    safety              ISO 26262, ASIL compliance, functional safety
    security            Vulnerabilities, input validation, crypto
    performance         Efficiency, memory usage, real-time constraints
    maintainability     Code quality, readability, documentation
    misra               MISRA C/C++ compliance
    autosar             AUTOSAR coding guidelines
    style               Code style and formatting

Examples:
    # Review a single file with safety focus
    council-review.sh src/bms/cell_monitor.cpp --focus=safety,misra

    # Review a GitHub PR
    council-review.sh --pr=456 --focus=security,performance

    # Review specific commit changes
    council-review.sh --commit=abc123def --language=cpp

Environment:
    ANTHROPIC_API_KEY       Anthropic API key (required)
    AZURE_OPENAI_API_KEY    Azure OpenAI API key (required)
    AZURE_OPENAI_ENDPOINT   Azure OpenAI endpoint (required)
    GITHUB_TOKEN            GitHub token (for PR reviews)

EOF
    exit 0
}

# Detect language from file extension
detect_language() {
    local file="$1"
    local ext="${file##*.}"

    case "$ext" in
        c)      echo "c" ;;
        cpp|cc|cxx|hpp|h)
                echo "cpp" ;;
        py)     echo "python" ;;
        java)   echo "java" ;;
        ts|tsx) echo "typescript" ;;
        js|jsx) echo "javascript" ;;
        rs)     echo "rust" ;;
        go)     echo "go" ;;
        yaml|yml)
                echo "yaml" ;;
        xml|arxml)
                echo "xml" ;;
        *)      echo "unknown" ;;
    esac
}

# Validate environment
validate_environment() {
    local missing=()

    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && missing+=("ANTHROPIC_API_KEY")
    [[ -z "${AZURE_OPENAI_API_KEY:-}" ]] && missing+=("AZURE_OPENAI_API_KEY")
    [[ -z "${AZURE_OPENAI_ENDPOINT:-}" ]] && missing+=("AZURE_OPENAI_ENDPOINT")

    if [[ -n "$PR_NUMBER" && -z "${GITHUB_TOKEN:-}" ]]; then
        missing+=("GITHUB_TOKEN (required for PR reviews)")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing[@]}"; do
            log_error "  - $var"
        done
        exit 1
    fi
}

# Get PR diff from GitHub
get_pr_diff() {
    local pr_num="$1"
    local repo="${GITHUB_REPOSITORY:-}"

    if [[ -z "$repo" ]]; then
        # Try to detect from git remote
        repo=$(git remote get-url origin 2>/dev/null | sed -E 's|.*github.com[:/](.+)\.git|\1|' || echo "")
    fi

    if [[ -z "$repo" ]]; then
        log_error "Cannot determine repository. Set GITHUB_REPOSITORY or run in a git repo."
        exit 1
    fi

    log_info "Fetching PR #${pr_num} from ${repo}..."

    gh pr diff "$pr_num" --repo "$repo" 2>/dev/null || {
        log_error "Failed to fetch PR diff. Ensure gh CLI is installed and authenticated."
        exit 1
    }
}

# Get commit diff
get_commit_diff() {
    local sha="$1"

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        log_error "Not in a git repository"
        exit 1
    fi

    log_info "Fetching diff for commit ${sha}..."
    git show --no-notes --format= "$sha" 2>/dev/null || {
        log_error "Failed to get commit diff for: $sha"
        exit 1
    }
}

# Read file content
get_file_content() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        exit 1
    fi

    cat "$file"
}

# Create context JSON for review
create_review_context() {
    local code="$1"
    local lang="$2"
    local focus="$3"
    local extra_context="$4"
    local context_json

    # Split focus areas into array
    IFS=',' read -ra focus_array <<< "$focus"

    context_json=$(cat << EOF
{
    "code": $(echo "$code" | jq -Rs .),
    "language": "$lang",
    "focus_areas": $(printf '%s\n' "${focus_array[@]}" | jq -R . | jq -s .),
    "review_type": "code_review",
    "automotive_context": {
        "safety_critical": $(echo "$focus" | grep -q "safety\|misra\|asil" && echo "true" || echo "false"),
        "real_time_constraints": $(echo "$focus" | grep -q "performance" && echo "true" || echo "false"),
        "security_sensitive": $(echo "$focus" | grep -q "security" && echo "true" || echo "false")
    }
}
EOF
)

    # Merge with extra context if provided
    if [[ -n "$extra_context" && -f "$extra_context" ]]; then
        context_json=$(echo "$context_json" | jq --slurpfile extra "$extra_context" '. * $extra[0]')
    fi

    echo "$context_json"
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --language=*)
                LANGUAGE="${1#*=}"
                ;;
            --focus=*)
                FOCUS_AREAS="${1#*=}"
                ;;
            --context=*)
                CONTEXT_FILE="${1#*=}"
                ;;
            --output=*)
                OUTPUT_DIR="${1#*=}"
                ;;
            --pr=*)
                PR_NUMBER="${1#*=}"
                ;;
            --commit=*)
                COMMIT_SHA="${1#*=}"
                ;;
            --verbose)
                VERBOSE=true
                ;;
            --help|-h)
                usage
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                if [[ -z "$FILE_PATH" ]]; then
                    FILE_PATH="$1"
                else
                    log_error "Multiple files not supported. Use --pr or --commit for multi-file review."
                    exit 1
                fi
                ;;
        esac
        shift
    done

    # Validate we have something to review
    if [[ -z "$FILE_PATH" && -z "$PR_NUMBER" && -z "$COMMIT_SHA" ]]; then
        log_error "Must specify a file, --pr=NUMBER, or --commit=SHA"
        usage
    fi
}

# Main execution
main() {
    parse_args "$@"

    echo ""
    echo "============================================"
    echo "   LLM Council Code Review"
    echo "============================================"
    echo ""

    validate_environment

    # Get the code to review
    local code=""
    local source_desc=""

    if [[ -n "$PR_NUMBER" ]]; then
        code=$(get_pr_diff "$PR_NUMBER")
        source_desc="PR #${PR_NUMBER}"
        [[ -z "$LANGUAGE" ]] && LANGUAGE="diff"
    elif [[ -n "$COMMIT_SHA" ]]; then
        code=$(get_commit_diff "$COMMIT_SHA")
        source_desc="Commit ${COMMIT_SHA:0:8}"
        [[ -z "$LANGUAGE" ]] && LANGUAGE="diff"
    else
        code=$(get_file_content "$FILE_PATH")
        source_desc="File: ${FILE_PATH}"
        [[ -z "$LANGUAGE" ]] && LANGUAGE=$(detect_language "$FILE_PATH")
    fi

    if [[ -z "$code" ]]; then
        log_error "No code to review"
        exit 1
    fi

    log_info "Reviewing: ${source_desc}"
    log_info "Language: ${LANGUAGE}"
    log_info "Focus Areas: ${FOCUS_AREAS}"

    # Create context JSON
    local context_file="${OUTPUT_DIR}/review-context.json"
    mkdir -p "$OUTPUT_DIR"

    create_review_context "$code" "$LANGUAGE" "$FOCUS_AREAS" "$CONTEXT_FILE" > "$context_file"

    if [[ "$VERBOSE" == true ]]; then
        log_info "Context file: ${context_file}"
    fi

    # Build topic for debate
    local topic="Code Review: ${source_desc} - Focus on ${FOCUS_AREAS}"

    # Execute council debate
    log_info "Starting multi-model code review..."
    echo ""

    local cmd="python3 ${PROJECT_ROOT}/tools/llm_council.py"
    cmd+=" \"${topic}\""
    cmd+=" --task-type=code_review"
    cmd+=" --rounds=2"
    cmd+=" --context=\"${context_file}\""
    cmd+=" --output=\"${OUTPUT_DIR}\""

    if [[ "$VERBOSE" == true ]]; then
        cmd+=" --verbose"
    fi

    eval "$cmd"
    local exit_code=$?

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "Code review completed"
        log_info "Review artifacts: ${OUTPUT_DIR}"

        # Show summary if synthesis exists
        local synthesis="${OUTPUT_DIR}/consensus/SYNTHESIS.md"
        if [[ -f "$synthesis" ]]; then
            echo ""
            echo "============================================"
            echo "   Review Summary"
            echo "============================================"
            cat "$synthesis"
        fi
    else
        log_error "Code review failed"
    fi

    return $exit_code
}

main "$@"

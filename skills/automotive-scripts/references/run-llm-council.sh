#!/usr/bin/env bash
# Trigger LLM Council review for code changes
# Supports multiple review modes and output formats

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Default values
MODE="review"
TARGET=""
OUTPUT="console"
CONFIG_FILE="${PROJECT_ROOT}/agents/core/llm-council.yaml"

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Trigger LLM Council review for automotive code changes.

OPTIONS:
    -m, --mode MODE         Review mode: review, debate, decide (default: review)
    -t, --target TARGET     Target file/directory to review
    -o, --output FORMAT     Output format: console, json, markdown (default: console)
    -c, --config FILE       Council config file (default: agents/core/llm-council.yaml)
    -h, --help              Show this help message

MODES:
    review      Quick safety and standards review
    debate      Multi-model debate on approach
    decide      Consensus decision on critical changes

EXAMPLES:
    # Review current changes
    $(basename "$0") -m review

    # Review specific file
    $(basename "$0") -m review -t src/battery/soc_estimator.py

    # Debate on architecture decision
    $(basename "$0") -m debate -t docs/adr/battery-management.md

    # Generate JSON report
    $(basename "$0") -m review -o json > report.json

EOF
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                MODE="$2"
                shift 2
                ;;
            -t|--target)
                TARGET="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Validate environment
validate_env() {
    log_info "Validating environment..."

    # Check Python
    if ! command -v python3 >/dev/null 2>&1; then
        log_error "Python 3 not found"
        exit 1
    fi

    # Check council script
    if [[ ! -f "${PROJECT_ROOT}/tools/llm_council.py" ]]; then
        log_error "LLM Council tool not found: tools/llm_council.py"
        exit 1
    fi

    # Check config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Council config not found: $CONFIG_FILE"
        exit 1
    fi

    # Check API keys
    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        log_warning "ANTHROPIC_API_KEY not set, council may fail"
    fi

    log_success "Environment validated"
}

# Get changed files
get_changed_files() {
    local files=()

    if [[ -n "$TARGET" ]]; then
        # Use specified target
        if [[ -f "$TARGET" ]]; then
            files=("$TARGET")
        elif [[ -d "$TARGET" ]]; then
            mapfile -t files < <(find "$TARGET" -type f \( -name "*.py" -o -name "*.yaml" -o -name "*.md" \))
        else
            log_error "Target not found: $TARGET"
            exit 1
        fi
    else
        # Get git changes
        if git rev-parse --git-dir >/dev/null 2>&1; then
            mapfile -t files < <(git diff --name-only --diff-filter=ACMR HEAD)
            if [[ ${#files[@]} -eq 0 ]]; then
                mapfile -t files < <(git diff --name-only --cached)
            fi
        fi

        if [[ ${#files[@]} -eq 0 ]]; then
            log_warning "No changes detected, reviewing entire project"
            TARGET="${PROJECT_ROOT}"
            mapfile -t files < <(find "$TARGET" -type f \( -name "*.py" -o -name "*.yaml" \))
        fi
    fi

    echo "${files[@]}"
}

# Run council review
run_review() {
    log_info "Running LLM Council review (mode: $MODE)..."

    cd "$PROJECT_ROOT" || exit 1

    local files
    files=($(get_changed_files))

    if [[ ${#files[@]} -eq 0 ]]; then
        log_warning "No files to review"
        return 0
    fi

    log_info "Reviewing ${#files[@]} file(s)"

    # Build command
    local cmd="python3 tools/llm_council.py"
    cmd+=" --mode $MODE"
    cmd+=" --config $CONFIG_FILE"
    cmd+=" --output $OUTPUT"

    # Add files
    for file in "${files[@]}"; do
        cmd+=" --file $file"
    done

    # Execute
    log_info "Executing: $cmd"
    eval "$cmd"

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        log_success "Council review completed successfully"
    else
        log_error "Council review failed with code $exit_code"
        exit $exit_code
    fi
}

# Run council debate
run_debate() {
    log_info "Running LLM Council debate..."

    cd "$PROJECT_ROOT" || exit 1

    local topic="$TARGET"
    if [[ -z "$topic" ]]; then
        log_error "Debate requires --target to specify topic/file"
        exit 1
    fi

    python3 tools/llm_council.py \
        --mode debate \
        --config "$CONFIG_FILE" \
        --output "$OUTPUT" \
        --topic "$topic"

    log_success "Council debate completed"
}

# Run council decision
run_decide() {
    log_info "Running LLM Council decision..."

    cd "$PROJECT_ROOT" || exit 1

    local question="$TARGET"
    if [[ -z "$question" ]]; then
        log_error "Decision requires --target to specify question/issue"
        exit 1
    fi

    python3 tools/llm_council.py \
        --mode decide \
        --config "$CONFIG_FILE" \
        --output "$OUTPUT" \
        --question "$question"

    log_success "Council decision completed"
}

# Main
main() {
    parse_args "$@"
    validate_env

    case "$MODE" in
        review)
            run_review
            ;;
        debate)
            run_debate
            ;;
        decide)
            run_decide
            ;;
        *)
            log_error "Invalid mode: $MODE"
            usage
            ;;
    esac
}

main "$@"

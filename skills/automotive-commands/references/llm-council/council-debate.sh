#!/usr/bin/env bash
#
# council-debate.sh - Trigger multi-model debate for engineering decisions
#
# Usage:
#   council-debate.sh "<topic>" [--rounds=N] [--type=TYPE] [--context=FILE]
#
# Options:
#   --rounds=N       Number of debate rounds (1-5, default: based on type)
#   --type=TYPE      Task type: code_optimization, architecture_design,
#                    bug_diagnosis, api_design, refactoring, security_review,
#                    performance_tuning, safety_critical, general
#   --context=FILE   JSON file with additional context
#   --output=DIR     Output directory for artifacts
#   --verbose        Enable verbose output
#   --dry-run        Show what would be executed without running
#
# Examples:
#   council-debate.sh "Optimize battery voltage sampling for 10ms cycle"
#   council-debate.sh "Design REST API for telemetry" --type=api_design --rounds=3
#   council-debate.sh "Review CAN protocol stack" --context=can-context.json
#
# Environment:
#   ANTHROPIC_API_KEY       Required: Anthropic API key
#   AZURE_OPENAI_API_KEY    Required: Azure OpenAI API key
#   AZURE_OPENAI_ENDPOINT   Required: Azure OpenAI endpoint URL
#   LLM_COUNCIL_OUTPUT      Optional: Default output directory
#

set -euo pipefail

# Script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
ROUNDS=""
TASK_TYPE="general"
CONTEXT_FILE=""
OUTPUT_DIR="${LLM_COUNCIL_OUTPUT:-/tmp/llm-council}"
VERBOSE=false
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Usage message
usage() {
    cat << 'EOF'
LLM Council Debate - Multi-Model Consensus System

Usage:
    council-debate.sh "<topic>" [OPTIONS]

Options:
    --rounds=N          Number of debate rounds (1-5)
    --type=TYPE         Task type for routing optimization
    --context=FILE      JSON file with additional context
    --output=DIR        Output directory for artifacts
    --verbose           Enable verbose output
    --dry-run           Show what would be executed
    --help              Show this help message

Task Types:
    code_optimization   Performance optimization tasks (2 rounds default)
    architecture_design Architecture decisions (4 rounds default)
    bug_diagnosis       Bug investigation (2 rounds default)
    api_design          API design review (3 rounds default)
    refactoring         Code refactoring (3 rounds default)
    security_review     Security assessment (4 rounds default)
    performance_tuning  Performance analysis (3 rounds default)
    safety_critical     Safety-critical review (5 rounds default)
    general             General questions (3 rounds default)

Examples:
    # Simple debate
    council-debate.sh "Best approach for BMS state estimation"

    # Architecture decision
    council-debate.sh "Microservices vs monolith for telemetry service" \
        --type=architecture_design --rounds=4

    # With context file
    council-debate.sh "Review thermal management algorithm" \
        --context=/path/to/thermal-context.json

Environment Variables:
    ANTHROPIC_API_KEY       Anthropic API key (required)
    AZURE_OPENAI_API_KEY    Azure OpenAI API key (required)
    AZURE_OPENAI_ENDPOINT   Azure OpenAI endpoint (required)
    LLM_COUNCIL_OUTPUT      Default output directory

EOF
    exit 0
}

# Validate environment
validate_environment() {
    local missing_vars=()

    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        missing_vars+=("ANTHROPIC_API_KEY")
    fi

    if [[ -z "${AZURE_OPENAI_API_KEY:-}" ]]; then
        missing_vars+=("AZURE_OPENAI_API_KEY")
    fi

    if [[ -z "${AZURE_OPENAI_ENDPOINT:-}" ]]; then
        missing_vars+=("AZURE_OPENAI_ENDPOINT")
    fi

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            log_error "  - $var"
        done
        log_error ""
        log_error "Please set these variables before running the council."
        exit 1
    fi
}

# Validate task type
validate_task_type() {
    local task_type="$1"
    local valid_types=(
        "code_optimization"
        "architecture_design"
        "bug_diagnosis"
        "api_design"
        "refactoring"
        "security_review"
        "performance_tuning"
        "safety_critical"
        "code_review"
        "general"
    )

    for valid in "${valid_types[@]}"; do
        if [[ "$task_type" == "$valid" ]]; then
            return 0
        fi
    done

    log_error "Invalid task type: $task_type"
    log_error "Valid types: ${valid_types[*]}"
    exit 1
}

# Parse command line arguments
parse_args() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    # First argument is the topic
    TOPIC="$1"
    shift

    # Parse remaining options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --rounds=*)
                ROUNDS="${1#*=}"
                if ! [[ "$ROUNDS" =~ ^[1-5]$ ]]; then
                    log_error "Rounds must be between 1 and 5"
                    exit 1
                fi
                ;;
            --type=*)
                TASK_TYPE="${1#*=}"
                validate_task_type "$TASK_TYPE"
                ;;
            --context=*)
                CONTEXT_FILE="${1#*=}"
                if [[ ! -f "$CONTEXT_FILE" ]]; then
                    log_error "Context file not found: $CONTEXT_FILE"
                    exit 1
                fi
                ;;
            --output=*)
                OUTPUT_DIR="${1#*=}"
                ;;
            --verbose)
                VERBOSE=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --help|-h)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
        shift
    done
}

# Build Python command
build_command() {
    local cmd="python3 ${PROJECT_ROOT}/tools/llm_council.py"

    # Add topic (quoted)
    cmd+=" \"${TOPIC}\""

    # Add task type
    cmd+=" --task-type=${TASK_TYPE}"

    # Add rounds if specified
    if [[ -n "$ROUNDS" ]]; then
        cmd+=" --rounds=${ROUNDS}"
    fi

    # Add context file if specified
    if [[ -n "$CONTEXT_FILE" ]]; then
        cmd+=" --context=\"${CONTEXT_FILE}\""
    fi

    # Add output directory
    cmd+=" --output=\"${OUTPUT_DIR}\""

    # Add verbose flag
    if [[ "$VERBOSE" == true ]]; then
        cmd+=" --verbose"
    fi

    echo "$cmd"
}

# Main execution
main() {
    parse_args "$@"

    # Show banner
    echo ""
    echo "======================================"
    echo "   LLM Council - Multi-Model Debate"
    echo "======================================"
    echo ""

    # Validate environment
    validate_environment

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Build command
    local cmd
    cmd=$(build_command)

    log_info "Topic: ${TOPIC}"
    log_info "Task Type: ${TASK_TYPE}"
    log_info "Rounds: ${ROUNDS:-auto}"
    log_info "Output: ${OUTPUT_DIR}"

    if [[ -n "$CONTEXT_FILE" ]]; then
        log_info "Context: ${CONTEXT_FILE}"
    fi

    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "DRY RUN - Would execute:"
        echo "$cmd"
        exit 0
    fi

    if [[ "$VERBOSE" == true ]]; then
        log_info "Executing: $cmd"
    fi

    # Execute the Python script
    log_info "Starting council debate..."
    echo ""

    # Use eval to properly handle quoted arguments
    eval "$cmd"

    local exit_code=$?

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "Council debate completed successfully"
        log_info "Artifacts saved to: ${OUTPUT_DIR}"
    else
        log_error "Council debate failed with exit code: $exit_code"
    fi

    return $exit_code
}

# Run main
main "$@"

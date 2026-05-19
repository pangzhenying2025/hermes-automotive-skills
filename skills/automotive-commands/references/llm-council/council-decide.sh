#!/usr/bin/env bash
#
# council-decide.sh - Architecture and design decisions via LLM Council
#
# Usage:
#   council-decide.sh "<decision-topic>" [OPTIONS]
#
# Options:
#   --requirements=FILE  Requirements file (JSON or Markdown)
#   --constraints=FILE   Constraints file (JSON or Markdown)
#   --options=LIST       Comma-separated list of options to consider
#   --rounds=N           Number of debate rounds (default: 4)
#   --output=DIR         Output directory for decision artifacts
#   --template=NAME      Decision template (architecture, api, migration, safety)
#   --verbose            Enable verbose output
#
# Examples:
#   council-decide.sh "Microservices vs monolith for telemetry backend"
#   council-decide.sh "Battery state estimation algorithm" \
#       --requirements=reqs.json --options="Kalman,EKF,UKF,Neural"
#   council-decide.sh "CAN to Ethernet migration strategy" --template=migration
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
DECISION_TOPIC=""
REQUIREMENTS_FILE=""
CONSTRAINTS_FILE=""
OPTIONS_LIST=""
ROUNDS=4
OUTPUT_DIR="${LLM_COUNCIL_OUTPUT:-/tmp/llm-council-decision}"
TEMPLATE=""
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
LLM Council Architecture Decision - Multi-Model Consensus System

Usage:
    council-decide.sh "<decision-topic>" [OPTIONS]

Options:
    --requirements=FILE  Requirements file (JSON or Markdown)
    --constraints=FILE   Constraints file (JSON or Markdown)
    --options=LIST       Comma-separated options to evaluate
    --rounds=N           Debate rounds (default: 4)
    --output=DIR         Output directory for artifacts
    --template=NAME      Decision template
    --verbose            Enable verbose output
    --help               Show this help message

Templates:
    architecture         System/software architecture decisions
    api                  API design decisions
    migration            Technology migration decisions
    safety               Safety-critical design decisions
    performance          Performance optimization decisions
    security             Security architecture decisions

Examples:
    # Basic architecture decision
    council-decide.sh "Monolith vs microservices for BMS cloud backend"

    # Decision with requirements and constraints
    council-decide.sh "State estimation algorithm selection" \
        --requirements=reqs.md \
        --constraints=constraints.json \
        --options="Kalman,EKF,UKF,MHE,Neural"

    # Migration decision
    council-decide.sh "CAN FD to Automotive Ethernet migration" \
        --template=migration \
        --rounds=5

    # Safety-critical decision
    council-decide.sh "ASIL-D compliant watchdog architecture" \
        --template=safety \
        --requirements=safety-reqs.json

Environment:
    ANTHROPIC_API_KEY       Anthropic API key (required)
    AZURE_OPENAI_API_KEY    Azure OpenAI API key (required)
    AZURE_OPENAI_ENDPOINT   Azure OpenAI endpoint (required)

EOF
    exit 0
}

# Validate environment
validate_environment() {
    local missing=()

    [[ -z "${ANTHROPIC_API_KEY:-}" ]] && missing+=("ANTHROPIC_API_KEY")
    [[ -z "${AZURE_OPENAI_API_KEY:-}" ]] && missing+=("AZURE_OPENAI_API_KEY")
    [[ -z "${AZURE_OPENAI_ENDPOINT:-}" ]] && missing+=("AZURE_OPENAI_ENDPOINT")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing[@]}"; do
            log_error "  - $var"
        done
        exit 1
    fi
}

# Read file content (supports JSON and Markdown)
read_file_content() {
    local file="$1"
    local content=""

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        exit 1
    fi

    content=$(cat "$file")

    # If it's markdown, try to extract structured data
    if [[ "$file" == *.md ]]; then
        # Convert bullet points to JSON array for processing
        echo "$content"
    else
        # Assume JSON
        echo "$content"
    fi
}

# Get template context
get_template_context() {
    local template="$1"

    case "$template" in
        architecture)
            cat << 'EOF'
{
    "evaluation_criteria": [
        "Scalability and modularity",
        "Maintainability and testability",
        "Performance and resource efficiency",
        "Integration complexity",
        "Long-term evolution path",
        "Team expertise alignment"
    ],
    "automotive_considerations": [
        "AUTOSAR compatibility",
        "Real-time constraints",
        "Safety isolation requirements",
        "OTA update strategy"
    ]
}
EOF
            ;;
        api)
            cat << 'EOF'
{
    "evaluation_criteria": [
        "Developer ergonomics",
        "Versioning strategy",
        "Error handling consistency",
        "Documentation completeness",
        "Security patterns",
        "Performance characteristics"
    ],
    "automotive_considerations": [
        "Vehicle-to-cloud latency",
        "Offline operation support",
        "Rate limiting for embedded clients",
        "Authentication for ECU clients"
    ]
}
EOF
            ;;
        migration)
            cat << 'EOF'
{
    "evaluation_criteria": [
        "Migration complexity and risk",
        "Rollback capability",
        "Parallel operation period",
        "Data migration strategy",
        "Training requirements",
        "Total cost of ownership"
    ],
    "automotive_considerations": [
        "Production vehicle impact",
        "Recall risk assessment",
        "Regulatory re-certification",
        "Supply chain dependencies"
    ]
}
EOF
            ;;
        safety)
            cat << 'EOF'
{
    "evaluation_criteria": [
        "ASIL compliance level",
        "Fault tolerance mechanisms",
        "Diagnostic coverage",
        "Independence of execution",
        "Freedom from interference",
        "Systematic capability"
    ],
    "automotive_considerations": [
        "ISO 26262 Part 6 requirements",
        "Hardware-software interface",
        "Safety mechanisms verification",
        "Tool qualification requirements"
    ],
    "mandatory_analysis": [
        "FMEA - Failure Mode and Effects Analysis",
        "FTA - Fault Tree Analysis",
        "DFA - Dependent Failure Analysis"
    ]
}
EOF
            ;;
        performance)
            cat << 'EOF'
{
    "evaluation_criteria": [
        "Worst-case execution time",
        "Memory footprint",
        "CPU utilization",
        "Response latency",
        "Throughput capacity",
        "Power consumption"
    ],
    "automotive_considerations": [
        "Real-time deadline guarantees",
        "Multi-core utilization",
        "Cache efficiency",
        "Interrupt latency",
        "DMA usage patterns"
    ]
}
EOF
            ;;
        security)
            cat << 'EOF'
{
    "evaluation_criteria": [
        "Attack surface minimization",
        "Defense in depth layers",
        "Cryptographic strength",
        "Key management complexity",
        "Incident response capability",
        "Audit trail completeness"
    ],
    "automotive_considerations": [
        "ISO 21434 compliance",
        "UN R155/R156 requirements",
        "SecOC implementation",
        "HSM integration",
        "OTA security"
    ]
}
EOF
            ;;
        *)
            echo "{}"
            ;;
    esac
}

# Create decision context
create_decision_context() {
    local topic="$1"
    local requirements="$2"
    local constraints="$3"
    local options="$4"
    local template="$5"

    local context_json
    local template_context

    # Get template context
    template_context=$(get_template_context "$template")

    # Build options array
    local options_json="[]"
    if [[ -n "$options" ]]; then
        options_json=$(echo "$options" | tr ',' '\n' | jq -R . | jq -s .)
    fi

    # Build requirements
    local requirements_json="{}"
    if [[ -n "$requirements" && -f "$requirements" ]]; then
        if [[ "$requirements" == *.json ]]; then
            requirements_json=$(cat "$requirements")
        else
            requirements_json=$(cat "$requirements" | jq -Rs '{content: .}')
        fi
    fi

    # Build constraints
    local constraints_json="{}"
    if [[ -n "$constraints" && -f "$constraints" ]]; then
        if [[ "$constraints" == *.json ]]; then
            constraints_json=$(cat "$constraints")
        else
            constraints_json=$(cat "$constraints" | jq -Rs '{content: .}')
        fi
    fi

    # Combine everything
    cat << EOF
{
    "decision_topic": $(echo "$topic" | jq -Rs .),
    "decision_type": "architecture_design",
    "template": "$template",
    "options_to_evaluate": $options_json,
    "requirements": $requirements_json,
    "constraints": $constraints_json,
    "template_context": $template_context,
    "output_expectations": {
        "recommendation": "Clear recommendation with rationale",
        "comparison_matrix": "Option comparison on all criteria",
        "risk_assessment": "Risks and mitigations for recommended option",
        "implementation_roadmap": "High-level implementation steps",
        "decision_record": "ADR-format decision record"
    }
}
EOF
}

# Parse arguments
parse_args() {
    if [[ $# -lt 1 ]]; then
        usage
    fi

    # First argument is the decision topic
    DECISION_TOPIC="$1"
    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --requirements=*)
                REQUIREMENTS_FILE="${1#*=}"
                ;;
            --constraints=*)
                CONSTRAINTS_FILE="${1#*=}"
                ;;
            --options=*)
                OPTIONS_LIST="${1#*=}"
                ;;
            --rounds=*)
                ROUNDS="${1#*=}"
                if ! [[ "$ROUNDS" =~ ^[1-5]$ ]]; then
                    log_error "Rounds must be between 1 and 5"
                    exit 1
                fi
                ;;
            --output=*)
                OUTPUT_DIR="${1#*=}"
                ;;
            --template=*)
                TEMPLATE="${1#*=}"
                ;;
            --verbose)
                VERBOSE=true
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

# Main execution
main() {
    parse_args "$@"

    echo ""
    echo "============================================"
    echo "   LLM Council Architecture Decision"
    echo "============================================"
    echo ""

    validate_environment

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    log_info "Decision Topic: ${DECISION_TOPIC}"
    log_info "Rounds: ${ROUNDS}"
    [[ -n "$TEMPLATE" ]] && log_info "Template: ${TEMPLATE}"
    [[ -n "$OPTIONS_LIST" ]] && log_info "Options: ${OPTIONS_LIST}"
    [[ -n "$REQUIREMENTS_FILE" ]] && log_info "Requirements: ${REQUIREMENTS_FILE}"
    [[ -n "$CONSTRAINTS_FILE" ]] && log_info "Constraints: ${CONSTRAINTS_FILE}"

    # Create context JSON
    local context_file="${OUTPUT_DIR}/decision-context.json"

    create_decision_context \
        "$DECISION_TOPIC" \
        "$REQUIREMENTS_FILE" \
        "$CONSTRAINTS_FILE" \
        "$OPTIONS_LIST" \
        "$TEMPLATE" > "$context_file"

    if [[ "$VERBOSE" == true ]]; then
        log_info "Context file: ${context_file}"
        echo ""
        cat "$context_file" | jq .
        echo ""
    fi

    # Execute council debate
    log_info "Starting multi-model architecture debate..."
    echo ""

    local cmd="python3 ${PROJECT_ROOT}/tools/llm_council.py"
    cmd+=" \"Architecture Decision: ${DECISION_TOPIC}\""
    cmd+=" --task-type=architecture_design"
    cmd+=" --rounds=${ROUNDS}"
    cmd+=" --context=\"${context_file}\""
    cmd+=" --output=\"${OUTPUT_DIR}\""

    if [[ "$VERBOSE" == true ]]; then
        cmd+=" --verbose"
    fi

    eval "$cmd"
    local exit_code=$?

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "Architecture decision completed"
        log_info "Decision artifacts: ${OUTPUT_DIR}"

        # Generate ADR if synthesis exists
        local synthesis="${OUTPUT_DIR}/consensus/SYNTHESIS.md"
        if [[ -f "$synthesis" ]]; then
            generate_adr "$synthesis"
        fi
    else
        log_error "Architecture decision failed"
    fi

    return $exit_code
}

# Generate Architecture Decision Record
generate_adr() {
    local synthesis_file="$1"
    local adr_file="${OUTPUT_DIR}/ADR-$(date +%Y%m%d)-decision.md"

    log_info "Generating Architecture Decision Record..."

    cat << EOF > "$adr_file"
# Architecture Decision Record

**Date**: $(date +%Y-%m-%d)
**Status**: Proposed
**Decision**: ${DECISION_TOPIC}

## Context

This decision was made using the LLM Council multi-model debate system,
combining perspectives from Claude Opus 4.6 and GPT-5.4.

EOF

    # Append synthesis
    echo "## Council Synthesis" >> "$adr_file"
    echo "" >> "$adr_file"
    cat "$synthesis_file" >> "$adr_file"

    cat << EOF >> "$adr_file"

## Decision Metadata

- **Council Rounds**: ${ROUNDS}
- **Template Used**: ${TEMPLATE:-none}
- **Generated**: $(date -Iseconds)
- **Artifacts**: ${OUTPUT_DIR}

---
*This ADR was generated by the LLM Council decision system.*
EOF

    log_success "ADR generated: ${adr_file}"
}

main "$@"

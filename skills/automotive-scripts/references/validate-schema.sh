#!/usr/bin/env bash
#
# Schema validation wrapper for automotive-claude-code-agents
# Runs Python validator with fallback to basic grep-based validation
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON_VALIDATOR="${SCRIPT_DIR}/validate-schema.py"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print with color
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Basic grep-based validation (fallback)
basic_validate_skills() {
    local skills_dir="${ROOT_DIR}/skills"
    local total=0
    local valid=0
    local invalid=0

    echo "Running basic validation on skills..."

    if [[ ! -d "${skills_dir}" ]]; then
        print_error "Skills directory not found: ${skills_dir}"
        return 1
    fi

    while IFS= read -r -d '' yaml_file; do
        ((total++))
        local missing_fields=()

        # Check required fields
        grep -q "^name:" "${yaml_file}" || missing_fields+=("name")
        grep -q "^description:" "${yaml_file}" || missing_fields+=("description")
        grep -q "^instructions:" "${yaml_file}" || missing_fields+=("instructions")

        if [[ ${#missing_fields[@]} -eq 0 ]]; then
            ((valid++))
        else
            ((invalid++))
            print_error "${yaml_file}"
            for field in "${missing_fields[@]}"; do
                echo "    Missing: ${field}"
            done
        fi
    done < <(find "${skills_dir}" -name "*.yaml" -o -name "*.yml" -print0)

    echo ""
    echo "=========================================="
    echo "SKILLS VALIDATION SUMMARY (Basic)"
    echo "=========================================="
    echo "Total:   ${total}"
    echo "Valid:   ${valid}"
    echo "Invalid: ${invalid}"
    echo "=========================================="

    [[ ${invalid} -eq 0 ]]
}

# Basic grep-based validation for agents (fallback)
basic_validate_agents() {
    local agents_dir="${ROOT_DIR}/agents"
    local total=0
    local valid=0
    local invalid=0

    echo "Running basic validation on agents..."

    if [[ ! -d "${agents_dir}" ]]; then
        print_error "Agents directory not found: ${agents_dir}"
        return 1
    fi

    while IFS= read -r -d '' yaml_file; do
        ((total++))
        local missing_fields=()

        # Check required fields
        grep -q "^name:" "${yaml_file}" || missing_fields+=("name")
        grep -q "^description:" "${yaml_file}" || missing_fields+=("description")
        grep -q "^role:" "${yaml_file}" || missing_fields+=("role")
        grep -q "^capabilities:" "${yaml_file}" || missing_fields+=("capabilities")

        if [[ ${#missing_fields[@]} -eq 0 ]]; then
            ((valid++))
        else
            ((invalid++))
            print_error "${yaml_file}"
            for field in "${missing_fields[@]}"; do
                echo "    Missing: ${field}"
            done
        fi
    done < <(find "${agents_dir}" -name "*.yaml" -o -name "*.yml" -print0)

    echo ""
    echo "=========================================="
    echo "AGENTS VALIDATION SUMMARY (Basic)"
    echo "=========================================="
    echo "Total:   ${total}"
    echo "Valid:   ${valid}"
    echo "Invalid: ${invalid}"
    echo "=========================================="

    [[ ${invalid} -eq 0 ]]
}

# Main validation logic
main() {
    local use_python=true
    local python_cmd=""

    # Check if Python is available
    if command -v python3 &> /dev/null; then
        python_cmd="python3"
    elif command -v python &> /dev/null; then
        python_cmd="python"
    else
        print_warning "Python not found, falling back to basic validation"
        use_python=false
    fi

    # Check if Python validator exists
    if [[ ! -f "${PYTHON_VALIDATOR}" ]]; then
        print_warning "Python validator not found, falling back to basic validation"
        use_python=false
    fi

    # Run appropriate validator
    if [[ "${use_python}" == "true" ]]; then
        print_success "Using Python validator"
        if ${python_cmd} "${PYTHON_VALIDATOR}" "$@"; then
            print_success "Validation passed"
            return 0
        else
            print_error "Validation failed"
            return 1
        fi
    else
        print_warning "Using basic grep-based validation"
        local skills_valid=true
        local agents_valid=true

        basic_validate_skills || skills_valid=false
        echo ""
        basic_validate_agents || agents_valid=false

        if [[ "${skills_valid}" == "true" ]] && [[ "${agents_valid}" == "true" ]]; then
            print_success "Validation passed"
            return 0
        else
            print_error "Validation failed"
            return 1
        fi
    fi
}

# Run main
main "$@"

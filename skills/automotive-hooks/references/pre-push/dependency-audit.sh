#!/usr/bin/env bash
# ==============================================================================
# Hook: dependency-audit.sh
# Type: pre-push
# Purpose: Check for known vulnerabilities in project dependencies before push.
#          Supports npm, pip, Maven, and Cargo ecosystems.
# ==============================================================================

set -euo pipefail

HOOK_NAME="dependency-audit"
EXIT_CODE=0

# Severity thresholds
BLOCK_ON_CRITICAL=true
BLOCK_ON_HIGH=true
BLOCK_ON_MEDIUM=false
BLOCK_ON_LOW=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Track results
TOTAL_CRITICAL=0
TOTAL_HIGH=0
TOTAL_MEDIUM=0
TOTAL_LOW=0
ECOSYSTEMS_CHECKED=0

# Audit npm dependencies
audit_npm() {
    if [[ ! -f "package.json" ]]; then
        return 0
    fi
    if ! command -v npm &>/dev/null; then
        echo -e "${YELLOW}  npm not found, skipping JavaScript audit.${NC}"
        return 0
    fi

    echo -e "${CYAN}  Auditing npm dependencies...${NC}"
    ECOSYSTEMS_CHECKED=$((ECOSYSTEMS_CHECKED + 1))

    local output
    output=$(npm audit --json 2>/dev/null || true)

    if [[ -z "$output" ]] || [[ "$output" == "{}" ]]; then
        echo -e "${GREEN}  npm: No vulnerabilities found.${NC}"
        return 0
    fi

    # Parse JSON output
    if command -v python3 &>/dev/null; then
        local counts
        counts=$(echo "$output" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    meta = data.get('metadata', {}).get('vulnerabilities', {})
    print(f\"CRITICAL:{meta.get('critical', 0)}\")
    print(f\"HIGH:{meta.get('high', 0)}\")
    print(f\"MODERATE:{meta.get('moderate', 0)}\")
    print(f\"LOW:{meta.get('low', 0)}\")
except:
    print('CRITICAL:0')
    print('HIGH:0')
    print('MODERATE:0')
    print('LOW:0')
" 2>/dev/null)

        while IFS= read -r line; do
            case "$line" in
                CRITICAL:*) TOTAL_CRITICAL=$((TOTAL_CRITICAL + ${line#CRITICAL:})) ;;
                HIGH:*) TOTAL_HIGH=$((TOTAL_HIGH + ${line#HIGH:})) ;;
                MODERATE:*) TOTAL_MEDIUM=$((TOTAL_MEDIUM + ${line#MODERATE:})) ;;
                LOW:*) TOTAL_LOW=$((TOTAL_LOW + ${line#LOW:})) ;;
            esac
        done <<< "$counts"
    else
        # Fallback: grep-based counting
        local crit high med low
        crit=$(echo "$output" | grep -c '"severity":"critical"' 2>/dev/null || echo 0)
        high=$(echo "$output" | grep -c '"severity":"high"' 2>/dev/null || echo 0)
        med=$(echo "$output" | grep -c '"severity":"moderate"' 2>/dev/null || echo 0)
        low=$(echo "$output" | grep -c '"severity":"low"' 2>/dev/null || echo 0)
        TOTAL_CRITICAL=$((TOTAL_CRITICAL + crit))
        TOTAL_HIGH=$((TOTAL_HIGH + high))
        TOTAL_MEDIUM=$((TOTAL_MEDIUM + med))
        TOTAL_LOW=$((TOTAL_LOW + low))
    fi

    echo "  npm: Critical=$TOTAL_CRITICAL, High=$TOTAL_HIGH, Medium=$TOTAL_MEDIUM, Low=$TOTAL_LOW"
}

# Audit Python dependencies
audit_pip() {
    if [[ ! -f "requirements.txt" ]] && [[ ! -f "setup.py" ]] && \
       [[ ! -f "pyproject.toml" ]] && [[ ! -f "Pipfile.lock" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Auditing Python dependencies...${NC}"
    ECOSYSTEMS_CHECKED=$((ECOSYSTEMS_CHECKED + 1))

    # Try pip-audit first
    if command -v pip-audit &>/dev/null; then
        local output
        output=$(pip-audit --format json 2>/dev/null || true)

        if [[ -n "$output" ]] && [[ "$output" != "[]" ]]; then
            if command -v python3 &>/dev/null; then
                local counts
                counts=$(echo "$output" | python3 -c "
import json, sys
try:
    vulns = json.load(sys.stdin)
    critical = sum(1 for v in vulns if 'CRITICAL' in str(v.get('fix_versions','')).upper())
    high = sum(1 for v in vulns if 'HIGH' in str(v).upper())
    print(f'VULNS:{len(vulns)}')
except:
    print('VULNS:0')
" 2>/dev/null)
                local vuln_count
                vuln_count=$(echo "$counts" | grep "VULNS:" | cut -d: -f2)
                TOTAL_HIGH=$((TOTAL_HIGH + vuln_count))
                echo "  pip-audit: Found $vuln_count vulnerable package(s)"
            fi
        else
            echo -e "${GREEN}  pip-audit: No vulnerabilities found.${NC}"
        fi
        return 0
    fi

    # Try safety as fallback
    if command -v safety &>/dev/null; then
        local output
        output=$(safety check --json 2>/dev/null || true)
        if [[ -n "$output" ]] && [[ "$output" != "[]" ]]; then
            local vuln_count
            vuln_count=$(echo "$output" | grep -c '"vulnerability"' 2>/dev/null || echo 0)
            TOTAL_HIGH=$((TOTAL_HIGH + vuln_count))
            echo "  safety: Found $vuln_count vulnerable package(s)"
        else
            echo -e "${GREEN}  safety: No vulnerabilities found.${NC}"
        fi
        return 0
    fi

    echo -e "${YELLOW}  No Python audit tool found (install pip-audit or safety).${NC}"
}

# Audit Maven/Java dependencies
audit_maven() {
    if [[ ! -f "pom.xml" ]]; then
        return 0
    fi

    echo -e "${CYAN}  Auditing Maven dependencies...${NC}"
    ECOSYSTEMS_CHECKED=$((ECOSYSTEMS_CHECKED + 1))

    # Check for OWASP Dependency-Check report
    local report_paths=(
        "target/dependency-check-report.json"
        "target/dependency-check-report.xml"
        "build/reports/dependency-check-report.json"
    )

    for report in "${report_paths[@]}"; do
        if [[ -f "$report" ]]; then
            echo -e "${CYAN}  Found existing dependency-check report: $report${NC}"

            if command -v python3 &>/dev/null && [[ "$report" == *.json ]]; then
                local counts
                counts=$(python3 -c "
import json
with open('$report') as f:
    data = json.load(f)
deps = data.get('dependencies', [])
critical = sum(1 for d in deps for v in d.get('vulnerabilities', []) if v.get('severity', '').upper() == 'CRITICAL')
high = sum(1 for d in deps for v in d.get('vulnerabilities', []) if v.get('severity', '').upper() == 'HIGH')
medium = sum(1 for d in deps for v in d.get('vulnerabilities', []) if v.get('severity', '').upper() == 'MEDIUM')
print(f'CRITICAL:{critical}')
print(f'HIGH:{high}')
print(f'MEDIUM:{medium}')
" 2>/dev/null)

                while IFS= read -r line; do
                    case "$line" in
                        CRITICAL:*) TOTAL_CRITICAL=$((TOTAL_CRITICAL + ${line#CRITICAL:})) ;;
                        HIGH:*) TOTAL_HIGH=$((TOTAL_HIGH + ${line#HIGH:})) ;;
                        MEDIUM:*) TOTAL_MEDIUM=$((TOTAL_MEDIUM + ${line#MEDIUM:})) ;;
                    esac
                done <<< "$counts"
            fi
            return 0
        fi
    done

    echo -e "${YELLOW}  No dependency-check report found. Run: mvn dependency-check:check${NC}"
}

# Audit Cargo/Rust dependencies
audit_cargo() {
    if [[ ! -f "Cargo.toml" ]]; then
        return 0
    fi
    if ! command -v cargo &>/dev/null; then
        return 0
    fi

    echo -e "${CYAN}  Auditing Cargo dependencies...${NC}"
    ECOSYSTEMS_CHECKED=$((ECOSYSTEMS_CHECKED + 1))

    if command -v cargo-audit &>/dev/null; then
        local output
        output=$(cargo audit --json 2>/dev/null || true)
        if [[ -n "$output" ]]; then
            local vuln_count
            vuln_count=$(echo "$output" | grep -c '"id":' 2>/dev/null || echo 0)
            TOTAL_HIGH=$((TOTAL_HIGH + vuln_count))
            echo "  cargo-audit: Found $vuln_count advisory(ies)"
        fi
    else
        echo -e "${YELLOW}  cargo-audit not installed. Run: cargo install cargo-audit${NC}"
    fi
}

# Main check
run_check() {
    echo -e "${YELLOW}[$HOOK_NAME] Auditing dependencies for known vulnerabilities...${NC}"

    # Run all applicable audits
    audit_npm
    audit_pip
    audit_maven
    audit_cargo

    echo ""

    if [[ $ECOSYSTEMS_CHECKED -eq 0 ]]; then
        echo -e "${YELLOW}[$HOOK_NAME] No dependency manifests found to audit.${NC}"
        return 0
    fi

    # Summary
    echo -e "${CYAN}  Summary: Critical=$TOTAL_CRITICAL, High=$TOTAL_HIGH, Medium=$TOTAL_MEDIUM, Low=$TOTAL_LOW${NC}"
    echo ""

    # Check against thresholds
    local should_block=false

    if [[ "$BLOCK_ON_CRITICAL" == "true" ]] && [[ $TOTAL_CRITICAL -gt 0 ]]; then
        echo -e "${RED}  BLOCKED: $TOTAL_CRITICAL critical vulnerability(ies) found.${NC}"
        should_block=true
    fi

    if [[ "$BLOCK_ON_HIGH" == "true" ]] && [[ $TOTAL_HIGH -gt 0 ]]; then
        echo -e "${RED}  BLOCKED: $TOTAL_HIGH high severity vulnerability(ies) found.${NC}"
        should_block=true
    fi

    if [[ "$BLOCK_ON_MEDIUM" == "true" ]] && [[ $TOTAL_MEDIUM -gt 0 ]]; then
        echo -e "${YELLOW}  WARNING: $TOTAL_MEDIUM medium severity vulnerability(ies) found.${NC}"
    fi

    if [[ "$should_block" == "true" ]]; then
        echo ""
        echo -e "${RED}[$HOOK_NAME] FAILED: Vulnerable dependencies must be updated.${NC}"
        echo -e "${YELLOW}  Run the appropriate audit command for details:${NC}"
        echo -e "${YELLOW}    npm:    npm audit${NC}"
        echo -e "${YELLOW}    pip:    pip-audit${NC}"
        echo -e "${YELLOW}    maven:  mvn dependency-check:check${NC}"
        echo -e "${YELLOW}    cargo:  cargo audit${NC}"
        return 1
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: No blocking vulnerabilities found.${NC}"
        return 0
    fi
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE

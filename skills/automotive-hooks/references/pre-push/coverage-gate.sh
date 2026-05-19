#!/usr/bin/env bash
# ==============================================================================
# Hook: coverage-gate.sh
# Type: pre-push
# Purpose: Enforce minimum code coverage thresholds before allowing push.
#          Reads coverage reports and blocks push if below configured limits.
# ==============================================================================

set -euo pipefail

HOOK_NAME="coverage-gate"
EXIT_CODE=0

# Coverage thresholds (percentage)
MIN_LINE_COVERAGE=80
MIN_BRANCH_COVERAGE=70
MIN_FUNCTION_COVERAGE=90
MIN_NEW_CODE_COVERAGE=80

# Coverage report locations (searched in order)
COVERAGE_REPORT_PATHS=(
    "build/coverage/coverage.xml"
    "coverage/coverage.xml"
    "build/coverage.xml"
    "target/site/jacoco/jacoco.xml"
    "coverage/lcov.info"
    "build/reports/jacoco/test/jacocoTestReport.xml"
    "htmlcov/coverage.xml"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse Cobertura XML coverage report
parse_cobertura_xml() {
    local report="$1"

    if command -v python3 &>/dev/null; then
        python3 << PYEOF
import xml.etree.ElementTree as ET
import sys

try:
    tree = ET.parse("$report")
    root = tree.getroot()

    line_rate = float(root.get("line-rate", 0)) * 100
    branch_rate = float(root.get("branch-rate", 0)) * 100

    # Count functions
    func_total = 0
    func_covered = 0
    for package in root.findall(".//package"):
        for cls in package.findall(".//class"):
            for method in cls.findall(".//method"):
                func_total += 1
                lines = method.findall(".//line")
                if any(int(l.get("hits", 0)) > 0 for l in lines):
                    func_covered += 1

    func_rate = (func_covered / func_total * 100) if func_total > 0 else 100

    print(f"LINE:{line_rate:.1f}")
    print(f"BRANCH:{branch_rate:.1f}")
    print(f"FUNCTION:{func_rate:.1f}")
except Exception as e:
    print(f"ERROR:{e}", file=sys.stderr)
    sys.exit(1)
PYEOF
    else
        # Fallback: grep-based parsing
        local line_rate
        line_rate=$(grep -oP 'line-rate="[0-9.]+"' "$report" | head -1 | grep -oP '[0-9.]+')
        local branch_rate
        branch_rate=$(grep -oP 'branch-rate="[0-9.]+"' "$report" | head -1 | grep -oP '[0-9.]+')

        if [[ -n "$line_rate" ]]; then
            local line_pct
            line_pct=$(echo "$line_rate * 100" | bc 2>/dev/null || echo "0")
            echo "LINE:${line_pct}"
        fi
        if [[ -n "$branch_rate" ]]; then
            local branch_pct
            branch_pct=$(echo "$branch_rate * 100" | bc 2>/dev/null || echo "0")
            echo "BRANCH:${branch_pct}"
        fi
        echo "FUNCTION:0"
    fi
}

# Parse JaCoCo XML coverage report
parse_jacoco_xml() {
    local report="$1"

    if command -v python3 &>/dev/null; then
        python3 << PYEOF
import xml.etree.ElementTree as ET

tree = ET.parse("$report")
root = tree.getroot()

metrics = {}
for counter in root.findall("counter"):
    ctype = counter.get("type")
    missed = int(counter.get("missed", 0))
    covered = int(counter.get("covered", 0))
    total = missed + covered
    rate = (covered / total * 100) if total > 0 else 100
    metrics[ctype] = rate

print(f"LINE:{metrics.get('LINE', 0):.1f}")
print(f"BRANCH:{metrics.get('BRANCH', 0):.1f}")
print(f"FUNCTION:{metrics.get('METHOD', 0):.1f}")
PYEOF
    fi
}

# Parse LCOV info file
parse_lcov_info() {
    local report="$1"
    local lines_found=0
    local lines_hit=0
    local branches_found=0
    local branches_hit=0
    local functions_found=0
    local functions_hit=0

    while IFS= read -r line; do
        case "$line" in
            LF:*) lines_found=$((lines_found + ${line#LF:})) ;;
            LH:*) lines_hit=$((lines_hit + ${line#LH:})) ;;
            BRF:*) branches_found=$((branches_found + ${line#BRF:})) ;;
            BRH:*) branches_hit=$((branches_hit + ${line#BRH:})) ;;
            FNF:*) functions_found=$((functions_found + ${line#FNF:})) ;;
            FNH:*) functions_hit=$((functions_hit + ${line#FNH:})) ;;
        esac
    done < "$report"

    local line_pct=0 branch_pct=0 func_pct=0
    [[ $lines_found -gt 0 ]] && line_pct=$((lines_hit * 100 / lines_found))
    [[ $branches_found -gt 0 ]] && branch_pct=$((branches_hit * 100 / branches_found))
    [[ $functions_found -gt 0 ]] && func_pct=$((functions_hit * 100 / functions_found))

    echo "LINE:${line_pct}"
    echo "BRANCH:${branch_pct}"
    echo "FUNCTION:${func_pct}"
}

# Find coverage report
find_coverage_report() {
    for path in "${COVERAGE_REPORT_PATHS[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# Determine report type and parse
parse_coverage() {
    local report="$1"

    case "$report" in
        *.xml)
            if grep -q "jacoco" "$report" 2>/dev/null; then
                parse_jacoco_xml "$report"
            else
                parse_cobertura_xml "$report"
            fi
            ;;
        *.info)
            parse_lcov_info "$report"
            ;;
        *)
            echo -e "${RED}Unknown coverage report format: $report${NC}" >&2
            return 1
            ;;
    esac
}

# Compare coverage against threshold
check_threshold() {
    local metric_name="$1"
    local actual="$2"
    local threshold="$3"

    # Handle floating point comparison
    local actual_int
    actual_int=$(echo "$actual" | cut -d. -f1)
    [[ -z "$actual_int" ]] && actual_int=0

    if [[ $actual_int -lt $threshold ]]; then
        echo -e "${RED}  FAIL: $metric_name coverage: ${actual}% (minimum: ${threshold}%)${NC}"
        return 1
    else
        echo -e "${GREEN}  PASS: $metric_name coverage: ${actual}% (minimum: ${threshold}%)${NC}"
        return 0
    fi
}

# Main check
run_check() {
    echo -e "${YELLOW}[$HOOK_NAME] Checking code coverage thresholds...${NC}"

    # Find coverage report
    local report
    if ! report=$(find_coverage_report); then
        echo -e "${YELLOW}[$HOOK_NAME] WARNING: No coverage report found.${NC}"
        echo -e "${CYAN}  Searched locations:${NC}"
        for path in "${COVERAGE_REPORT_PATHS[@]}"; do
            echo -e "${CYAN}    - $path${NC}"
        done
        echo -e "${YELLOW}  Run tests with coverage enabled first.${NC}"
        echo -e "${YELLOW}  Allowing push (coverage report generation recommended).${NC}"
        return 0
    fi

    echo -e "${CYAN}[$HOOK_NAME] Using coverage report: $report${NC}"

    # Parse coverage data
    local coverage_data
    coverage_data=$(parse_coverage "$report")

    if [[ -z "$coverage_data" ]]; then
        echo -e "${YELLOW}[$HOOK_NAME] WARNING: Could not parse coverage report.${NC}"
        return 0
    fi

    # Extract metrics
    local line_cov=0 branch_cov=0 func_cov=0
    while IFS= read -r metric; do
        case "$metric" in
            LINE:*) line_cov="${metric#LINE:}" ;;
            BRANCH:*) branch_cov="${metric#BRANCH:}" ;;
            FUNCTION:*) func_cov="${metric#FUNCTION:}" ;;
        esac
    done <<< "$coverage_data"

    echo ""
    local failed=false

    check_threshold "Line" "$line_cov" "$MIN_LINE_COVERAGE" || failed=true
    check_threshold "Branch" "$branch_cov" "$MIN_BRANCH_COVERAGE" || failed=true
    check_threshold "Function" "$func_cov" "$MIN_FUNCTION_COVERAGE" || failed=true

    echo ""

    if [[ "$failed" == "true" ]]; then
        echo -e "${RED}[$HOOK_NAME] FAILED: Coverage below required thresholds.${NC}"
        echo -e "${YELLOW}  Increase test coverage before pushing.${NC}"
        return 1
    else
        echo -e "${GREEN}[$HOOK_NAME] PASSED: All coverage thresholds met.${NC}"
        return 0
    fi
}

# Execute
if ! run_check; then
    EXIT_CODE=1
fi

exit $EXIT_CODE

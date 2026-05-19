#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# EOL Plan — Generate End-of-Life planning for automotive software
# ============================================================================
# Usage: eol-plan.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -p, --product    Product name
#   -d, --date       Planned EOL date (YYYY-MM-DD)
#   -s, --support    Extended support period in months (default: 24)
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

VERBOSE=false
PRODUCT="BMS_Controller_v2"
EOL_DATE="2027-12-31"
SUPPORT_MONTHS=24

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -p|--product) PRODUCT="$2"; shift 2 ;;
        -d|--date) EOL_DATE="$2"; shift 2 ;;
        -s|--support) SUPPORT_MONTHS="$2"; shift 2 ;;
        *) shift ;;
    esac
done

generate_eol_plan() {
    info "Generating EOL plan for $PRODUCT..."
    info "  Last sale date: $EOL_DATE"
    info "  Security updates until: +${SUPPORT_MONTHS} months"
    info "  Migration path: BMS_Controller_v3"
    info "  Affected deployments: 1,200 vehicles"
}

generate_plan() {
    local plan="./eol-plan.json"
    cat > "$plan" <<EOF
{
    "eol_plan": {
        "product": "${PRODUCT}",
        "eol_date": "${EOL_DATE}",
        "extended_support_months": ${SUPPORT_MONTHS},
        "milestones": [
            {"date": "$(date +%Y-%m-%d)", "action": "EOL announced"},
            {"date": "${EOL_DATE}", "action": "Last sale/production"},
            {"date": "${EOL_DATE}+12m", "action": "Last feature update"},
            {"date": "${EOL_DATE}+${SUPPORT_MONTHS}m", "action": "Last security update"}
        ],
        "migration_path": "BMS_Controller_v3",
        "affected_units": 1200,
        "timestamp": "$(date -Iseconds)"
    }
}
EOF
    info "EOL plan written to: $plan"
}

main() {
    info "Starting EOL planning..."
    generate_eol_plan
    generate_plan
    info "EOL planning complete"
}

main

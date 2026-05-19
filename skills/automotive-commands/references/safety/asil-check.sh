#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# ASIL Check — Verify ASIL classification and decomposition
# ============================================================================
# Usage: asil-check.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -s, --severity   Severity level (S0|S1|S2|S3)
#   -e, --exposure   Exposure level (E0|E1|E2|E3|E4)
#   -c, --control    Controllability (C0|C1|C2|C3)
#   --decompose      Check ASIL decomposition validity
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
SEVERITY="S3"
EXPOSURE="E4"
CONTROLLABILITY="C3"
DECOMPOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -s, --severity   S0|S1|S2|S3"
            echo "  -e, --exposure   E0|E1|E2|E3|E4"
            echo "  -c, --control    C0|C1|C2|C3"
            echo "  --decompose      Check decomposition"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -s|--severity) SEVERITY="$2"; shift 2 ;;
        -e|--exposure) EXPOSURE="$2"; shift 2 ;;
        -c|--control) CONTROLLABILITY="$2"; shift 2 ;;
        --decompose) DECOMPOSE=true; shift ;;
        *) shift ;;
    esac
done

determine_asil() {
    local s="${SEVERITY:1}" e="${EXPOSURE:1}" c="${CONTROLLABILITY:1}"
    local asil="QM"

    if (( s == 0 || e == 0 || c == 0 )); then
        asil="QM"
    elif (( s == 1 && e <= 2 )); then
        asil="QM"
    elif (( s == 1 && e == 3 && c <= 2 )); then
        asil="QM"
    elif (( s == 1 && e == 3 && c == 3 )); then
        asil="A"
    elif (( s == 1 && e == 4 && c <= 1 )); then
        asil="QM"
    elif (( s == 1 && e == 4 && c == 2 )); then
        asil="A"
    elif (( s == 1 && e == 4 && c == 3 )); then
        asil="B"
    elif (( s == 2 && e <= 2 && c <= 2 )); then
        asil="QM"
    elif (( s == 2 && e >= 3 && c >= 2 )); then
        asil="B"
    elif (( s == 3 && e >= 3 && c >= 2 )); then
        asil="C"
    fi
    if (( s == 3 && e == 4 && c == 3 )); then
        asil="D"
    fi

    info "ASIL Classification: $asil"
    info "  Severity: $SEVERITY, Exposure: $EXPOSURE, Controllability: $CONTROLLABILITY"
    echo "$asil"
}

check_decomposition() {
    if ! $DECOMPOSE; then return; fi
    info "Checking ASIL decomposition options..."
    info "  ASIL D -> ASIL D(D) or ASIL C(D) + ASIL A(D)"
    info "  ASIL D -> ASIL B(D) + ASIL B(D)"
    info "  ASIL C -> ASIL B(C) + ASIL A(C)"
    info "  ASIL B -> ASIL A(B) + ASIL A(B)"
    warn "  Decomposition requires independence between elements (ISO 26262-9)"
}

generate_report() {
    local asil="$1"
    local report="./asil-check.json"
    cat > "$report" <<EOF
{
    "asil_check": {
        "severity": "${SEVERITY}",
        "exposure": "${EXPOSURE}",
        "controllability": "${CONTROLLABILITY}",
        "asil_level": "${asil}",
        "standard": "ISO 26262-3",
        "decomposition_checked": ${DECOMPOSE},
        "checked_at": "$(date -Iseconds)"
    }
}
EOF
    info "Report written to: $report"
}

main() {
    info "Starting ASIL classification check..."
    local asil
    asil=$(determine_asil | tail -1)
    check_decomposition
    generate_report "$asil"
    info "ASIL check complete"
}

main

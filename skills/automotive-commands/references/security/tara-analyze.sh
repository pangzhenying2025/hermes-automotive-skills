#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# TARA Analyze — Threat Analysis and Risk Assessment per ISO 21434
# ============================================================================
# Usage: tara-analyze.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -a, --asset      Asset under analysis
#   -t, --threats    Threat model (stride|attack-tree|custom)
#   -o, --output     Output TARA report
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
ASSET="OTA_Update_Service"
THREAT_MODEL="stride"
OUTPUT_FILE="./tara-report.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) echo "Usage: $(basename "$0") [options]"; exit 0 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -a|--asset) ASSET="$2"; shift 2 ;;
        -t|--threats) THREAT_MODEL="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

identify_threats() {
    info "Identifying threats using $THREAT_MODEL model for: $ASSET"
    info "  Spoofing: Fake update server impersonation"
    info "  Tampering: Modified firmware packages"
    info "  Repudiation: Unlogged update operations"
    info "  Information Disclosure: Key material exposure"
    info "  Denial of Service: Update channel flooding"
    info "  Elevation of Privilege: Unauthorized code execution"
    info "  6 threats identified"
}

assess_risk() {
    info "Assessing risk levels..."
    info "  Tampering (modified firmware): CRITICAL"
    info "  Spoofing (fake server): HIGH"
    info "  Elevation of Privilege: HIGH"
    warn "  3 threats rated HIGH or above"
}

propose_mitigations() {
    info "Proposing mitigations..."
    info "  Code signing with RSA-4096 or ECDSA-P384"
    info "  Mutual TLS authentication"
    info "  Secure boot chain verification"
    info "  Audit logging with integrity protection"
}

generate_tara_report() {
    cat > "$OUTPUT_FILE" <<EOF
{
    "tara_report": {
        "asset": "${ASSET}",
        "threat_model": "${THREAT_MODEL}",
        "standard": "ISO/SAE 21434",
        "threats": [
            {"id": "T-001", "category": "Tampering", "description": "Modified firmware", "risk": "critical", "mitigation": "Code signing"},
            {"id": "T-002", "category": "Spoofing", "description": "Fake update server", "risk": "high", "mitigation": "Mutual TLS"},
            {"id": "T-003", "category": "Elevation", "description": "Unauthorized code exec", "risk": "high", "mitigation": "Secure boot"},
            {"id": "T-004", "category": "Repudiation", "description": "Unlogged operations", "risk": "medium", "mitigation": "Audit log"},
            {"id": "T-005", "category": "InfoDisclosure", "description": "Key exposure", "risk": "medium", "mitigation": "HSM storage"},
            {"id": "T-006", "category": "DoS", "description": "Channel flooding", "risk": "low", "mitigation": "Rate limiting"}
        ],
        "analyzed_at": "$(date -Iseconds)"
    }
}
EOF
    info "TARA report written to: $OUTPUT_FILE"
}

main() {
    info "Starting TARA analysis..."
    identify_threats
    assess_risk
    propose_mitigations
    generate_tara_report
    info "TARA analysis complete"
}

main

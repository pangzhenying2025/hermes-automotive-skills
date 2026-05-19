#!/usr/bin/env bash
# cert-check.sh - Check X.509 certificate validity, expiration, and chain
# For automotive PKI (V2X, OTA, ISO 15118 charging certificates)

set -euo pipefail

# Default values
CERT_FILE=""
CHECK_TYPE="local"
HOSTNAME=""
PORT=443
WARN_DAYS=30

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -c CERT_FILE [OPTIONS]

Check X.509 certificate validity, expiration, and chain.

Options:
    -c, --cert FILE           Certificate file (PEM/DER)
    -t, --type TYPE           Check type: local, remote (default: local)
    -H, --host HOSTNAME       Remote hostname (for type=remote)
    -p, --port PORT           Remote port (default: 443)
    -w, --warn-days DAYS      Warn if expiring within N days (default: 30)
    -h, --help                Show this help message

Examples:
    # Check local certificate file
    $0 -c device-cert.pem

    # Check remote TLS certificate
    $0 -t remote -H ota.example.com -p 8443

    # Check ISO 15118 charging certificate
    $0 -c iso15118-contract.pem -w 14

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cert) CERT_FILE="$2"; shift 2 ;;
        -t|--type) CHECK_TYPE="$2"; shift 2 ;;
        -H|--host) HOSTNAME="$2"; shift 2 ;;
        -p|--port) PORT="$2"; shift 2 ;;
        -w|--warn-days) WARN_DAYS="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: openssl not installed${NC}"
    exit 1
fi

echo -e "${BLUE}=== Certificate Checker ===${NC}"
echo ""

case "$CHECK_TYPE" in
    local)
        if [[ -z "$CERT_FILE" ]]; then
            echo -e "${RED}Error: Certificate file required for local check${NC}"
            usage
        fi

        if [[ ! -f "$CERT_FILE" ]]; then
            echo -e "${RED}Error: Certificate file not found: $CERT_FILE${NC}"
            exit 1
        fi

        echo "Certificate: $CERT_FILE"
        echo ""

        # Extract certificate details
        echo -e "${YELLOW}[Subject]${NC}"
        openssl x509 -in "$CERT_FILE" -noout -subject
        echo ""

        echo -e "${YELLOW}[Issuer]${NC}"
        openssl x509 -in "$CERT_FILE" -noout -issuer
        echo ""

        echo -e "${YELLOW}[Validity]${NC}"
        NOT_BEFORE=$(openssl x509 -in "$CERT_FILE" -noout -startdate | cut -d= -f2)
        NOT_AFTER=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
        echo "  Not Before: $NOT_BEFORE"
        echo "  Not After:  $NOT_AFTER"

        # Check expiration
        EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$NOT_AFTER" +%s 2>/dev/null)
        NOW_EPOCH=$(date +%s)
        DAYS_REMAINING=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

        echo ""
        if [[ $DAYS_REMAINING -lt 0 ]]; then
            echo -e "${RED}✗ Certificate EXPIRED ($DAYS_REMAINING days ago)${NC}"
        elif [[ $DAYS_REMAINING -lt $WARN_DAYS ]]; then
            echo -e "${YELLOW}⚠ Certificate expires soon ($DAYS_REMAINING days remaining)${NC}"
        else
            echo -e "${GREEN}✓ Certificate valid ($DAYS_REMAINING days remaining)${NC}"
        fi

        echo ""
        echo -e "${YELLOW}[Extensions]${NC}"
        openssl x509 -in "$CERT_FILE" -noout -ext keyUsage,extendedKeyUsage,subjectAltName 2>/dev/null || echo "  No extensions"

        echo ""
        echo -e "${YELLOW}[Fingerprints]${NC}"
        SHA256_FP=$(openssl x509 -in "$CERT_FILE" -noout -fingerprint -sha256 | cut -d= -f2)
        echo "  SHA256: $SHA256_FP"
        ;;

    remote)
        if [[ -z "$HOSTNAME" ]]; then
            echo -e "${RED}Error: Hostname required for remote check${NC}"
            usage
        fi

        echo "Checking: $HOSTNAME:$PORT"
        echo ""

        # Retrieve remote certificate
        REMOTE_CERT=$(echo | openssl s_client -servername "$HOSTNAME" -connect "$HOSTNAME:$PORT" 2>/dev/null | openssl x509 2>/dev/null)

        if [[ -z "$REMOTE_CERT" ]]; then
            echo -e "${RED}✗ Failed to retrieve certificate from $HOSTNAME:$PORT${NC}"
            exit 1
        fi

        # Save to temp file
        TEMP_CERT=$(mktemp)
        echo "$REMOTE_CERT" > "$TEMP_CERT"

        echo -e "${YELLOW}[Subject]${NC}"
        echo "$REMOTE_CERT" | openssl x509 -noout -subject

        echo ""
        echo -e "${YELLOW}[Validity]${NC}"
        NOT_AFTER=$(echo "$REMOTE_CERT" | openssl x509 -noout -enddate | cut -d= -f2)
        echo "  Not After: $NOT_AFTER"

        EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$NOT_AFTER" +%s 2>/dev/null)
        NOW_EPOCH=$(date +%s)
        DAYS_REMAINING=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

        echo ""
        if [[ $DAYS_REMAINING -lt 0 ]]; then
            echo -e "${RED}✗ Certificate EXPIRED${NC}"
        elif [[ $DAYS_REMAINING -lt $WARN_DAYS ]]; then
            echo -e "${YELLOW}⚠ Certificate expires in $DAYS_REMAINING days${NC}"
        else
            echo -e "${GREEN}✓ Certificate valid for $DAYS_REMAINING days${NC}"
        fi

        # Verify chain
        echo ""
        echo -e "${YELLOW}[Chain Verification]${NC}"
        if echo | openssl s_client -servername "$HOSTNAME" -connect "$HOSTNAME:$PORT" 2>/dev/null | grep -q "Verify return code: 0"; then
            echo -e "${GREEN}✓ Certificate chain valid${NC}"
        else
            echo -e "${RED}✗ Certificate chain verification failed${NC}"
        fi

        rm -f "$TEMP_CERT"
        ;;
esac

echo ""

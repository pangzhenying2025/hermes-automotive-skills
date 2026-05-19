#!/usr/bin/env bash
# iso15118-check.sh - Validate ISO 15118 certificate chain for Plug & Charge
# Checks V2G Root CA, CPO Sub-CA, and EVSE/EMAID leaf certificates

set -euo pipefail

# Default values
CERT_TYPE="vehicle"
CERT_FILE=""
CA_BUNDLE=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -t TYPE -c CERT_FILE [OPTIONS]

Validate ISO 15118 certificate chain for Plug & Charge authentication.

Required:
    -t, --type TYPE           Certificate type: vehicle, charger (default: vehicle)
    -c, --cert FILE           Certificate file (PEM format)

Options:
    --ca-bundle FILE          CA bundle for chain validation
    -h, --help                Show this help message

Certificate Types:
    vehicle  - Contract certificate (EMAID) issued to vehicle
    charger  - EVSE/SECC certificate issued to charge point

ISO 15118 Certificate Hierarchy:
    V2G Root CA (Hubject, Gireve, etc.)
      └─ CPO Sub-CA
           └─ EVSE Leaf Certificate (for charger)
      └─ OEM Sub-CA
           └─ Contract Certificate (for vehicle)

Examples:
    # Validate vehicle contract certificate
    $0 -t vehicle -c contract-cert.pem

    # Validate charger certificate with custom CA bundle
    $0 -t charger -c evse-cert.pem --ca-bundle v2g-ca-bundle.pem

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type) CERT_TYPE="$2"; shift 2 ;;
        -c|--cert) CERT_FILE="$2"; shift 2 ;;
        --ca-bundle) CA_BUNDLE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$CERT_FILE" ]]; then
    echo -e "${RED}Error: Certificate file is required${NC}"
    usage
fi

if [[ ! -f "$CERT_FILE" ]]; then
    echo -e "${RED}Error: Certificate file not found: $CERT_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}=== ISO 15118 Certificate Validator ===${NC}"
echo "Certificate Type: $CERT_TYPE"
echo "Certificate File: $CERT_FILE"
echo ""

# Parse certificate details
echo -e "${YELLOW}[Certificate Details]${NC}"
openssl x509 -in "$CERT_FILE" -noout -subject -issuer -dates
echo ""

# Extract subject CN
SUBJECT_CN=$(openssl x509 -in "$CERT_FILE" -noout -subject | sed 's/.*CN = //')
echo "Subject CN: $SUBJECT_CN"
echo ""

# Check certificate validity
NOT_BEFORE=$(openssl x509 -in "$CERT_FILE" -noout -startdate | cut -d= -f2)
NOT_AFTER=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)

EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$NOT_AFTER" +%s 2>/dev/null)
NOW_EPOCH=$(date +%s)
DAYS_REMAINING=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

echo -e "${YELLOW}[Validity Period]${NC}"
echo "  Not Before: $NOT_BEFORE"
echo "  Not After:  $NOT_AFTER"

if [[ $DAYS_REMAINING -lt 0 ]]; then
    echo -e "  ${RED}✗ Certificate EXPIRED${NC}"
elif [[ $DAYS_REMAINING -lt 30 ]]; then
    echo -e "  ${YELLOW}⚠ Certificate expires in $DAYS_REMAINING days${NC}"
else
    echo -e "  ${GREEN}✓ Certificate valid for $DAYS_REMAINING days${NC}"
fi
echo ""

# Check extended key usage
echo -e "${YELLOW}[Extended Key Usage]${NC}"
EKU=$(openssl x509 -in "$CERT_FILE" -noout -ext extendedKeyUsage 2>/dev/null)

if [[ -n "$EKU" ]]; then
    echo "$EKU"

    case "$CERT_TYPE" in
        vehicle)
            if echo "$EKU" | grep -q "1.3.6.1.4.1.63415.1.1"; then
                echo -e "${GREEN}✓ Contains ISO 15118 Contract Certificate OID${NC}"
            else
                echo -e "${YELLOW}⚠ Missing Contract Certificate OID (1.3.6.1.4.1.63415.1.1)${NC}"
            fi
            ;;
        charger)
            if echo "$EKU" | grep -q "1.3.6.1.4.1.63415.1.2"; then
                echo -e "${GREEN}✓ Contains ISO 15118 SECC Certificate OID${NC}"
            else
                echo -e "${YELLOW}⚠ Missing SECC Certificate OID (1.3.6.1.4.1.63415.1.2)${NC}"
            fi
            ;;
    esac
else
    echo -e "${YELLOW}⚠ No Extended Key Usage extension found${NC}"
fi
echo ""

# Certificate chain validation
if [[ -n "$CA_BUNDLE" ]]; then
    if [[ ! -f "$CA_BUNDLE" ]]; then
        echo -e "${RED}Error: CA bundle not found: $CA_BUNDLE${NC}"
    else
        echo -e "${YELLOW}[Chain Validation]${NC}"
        if openssl verify -CAfile "$CA_BUNDLE" "$CERT_FILE" 2>/dev/null; then
            echo -e "${GREEN}✓ Certificate chain valid${NC}"
        else
            echo -e "${RED}✗ Certificate chain validation failed${NC}"
        fi
        echo ""
    fi
else
    echo -e "${YELLOW}[Chain Validation]${NC}"
    echo "Provide --ca-bundle to validate certificate chain"
    echo ""
fi

# Public key information
echo -e "${YELLOW}[Public Key]${NC}"
openssl x509 -in "$CERT_FILE" -noout -pubkey | openssl rsa -pubin -text -noout 2>/dev/null | grep "Public-Key:"
echo ""

# Signature algorithm
echo -e "${YELLOW}[Signature Algorithm]${NC}"
SIG_ALG=$(openssl x509 -in "$CERT_FILE" -noout -text | grep "Signature Algorithm" | head -n1)
echo "$SIG_ALG"

if echo "$SIG_ALG" | grep -q "sha256"; then
    echo -e "${GREEN}✓ Using SHA-256 (recommended)${NC}"
elif echo "$SIG_ALG" | grep -q "sha1"; then
    echo -e "${RED}✗ Using SHA-1 (deprecated, not allowed)${NC}"
fi
echo ""

# Check Subject Alternative Name for EMAID
if [[ "$CERT_TYPE" == "vehicle" ]]; then
    echo -e "${YELLOW}[EMAID (e-Mobility Account ID)]${NC}"
    SAN=$(openssl x509 -in "$CERT_FILE" -noout -ext subjectAltName 2>/dev/null)

    if [[ -n "$SAN" ]]; then
        echo "$SAN"

        # EMAID format: CC-OOO-XXXXXXXXX-Y (e.g., DE-ABC-000123456-7)
        if echo "$SAN" | grep -qE "[A-Z]{2}-[A-Z0-9]{3}-[0-9]{9}-[0-9]"; then
            echo -e "${GREEN}✓ Valid EMAID format found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ No Subject Alternative Name (EMAID expected)${NC}"
    fi
    echo ""
fi

echo -e "${BLUE}ISO 15118-2 / ISO 15118-20 Reference${NC}"
echo ""
echo -e "${YELLOW}PKI Requirements:${NC}"
echo "  • Certificate validity: ≤3 years"
echo "  • Key length: RSA ≥2048 bits or ECC ≥256 bits"
echo "  • Hash algorithm: SHA-256 or better"
echo "  • Chain depth: ≤4 levels"
echo "  • CRL/OCSP: Must be available for revocation checking"

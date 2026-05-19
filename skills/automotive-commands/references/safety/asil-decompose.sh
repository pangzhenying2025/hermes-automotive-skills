#!/usr/bin/env bash
# asil-decompose.sh - Calculate ASIL decomposition options per ISO 26262-9
# ASIL decomposition allows splitting requirements into redundant elements

set -euo pipefail

# Default values
INPUT_ASIL=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -a ASIL_LEVEL

Calculate valid ASIL decomposition options per ISO 26262-9 clause 5.

Required:
    -a, --asil LEVEL          Input ASIL level (B, C, or D)

Options:
    -h, --help                Show this help message

Examples:
    # Find decomposition options for ASIL D
    $0 -a D

    # Find decomposition options for ASIL C
    $0 -a C

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--asil) INPUT_ASIL="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$INPUT_ASIL" ]]; then
    echo -e "${RED}Error: ASIL level is required${NC}"
    usage
fi

# Validate ASIL level
if [[ ! "$INPUT_ASIL" =~ ^[BCD]$ ]]; then
    echo -e "${RED}Error: Invalid ASIL level. Must be B, C, or D${NC}"
    echo "Note: ASIL A cannot be decomposed (already lowest level)"
    exit 1
fi

echo -e "${BLUE}=== ASIL Decomposition Calculator ===${NC}"
echo "Input ASIL: $INPUT_ASIL"
echo ""

case "$INPUT_ASIL" in
    B)
        echo -e "${GREEN}Valid decomposition options for ASIL B:${NC}"
        echo ""
        echo "Option 1: ASIL B(B) = ASIL B + ASIL B"
        echo "  - Two independent elements, each at ASIL B"
        echo "  - Both must fail for system hazard"
        echo ""
        echo "Option 2: ASIL B(A,A) = ASIL A + ASIL A"
        echo "  - Two independent elements, each at ASIL A"
        echo "  - Both must fail for system hazard"
        echo "  - Most common for ASIL B decomposition"
        ;;

    C)
        echo -e "${GREEN}Valid decomposition options for ASIL C:${NC}"
        echo ""
        echo "Option 1: ASIL C(C) = ASIL C + ASIL C"
        echo "  - Two independent elements, each at ASIL C"
        echo ""
        echo "Option 2: ASIL C(B,B) = ASIL B + ASIL B"
        echo "  - Two independent elements, each at ASIL B"
        echo "  - Most common for ASIL C decomposition"
        echo ""
        echo "Option 3: ASIL C(A,B) = ASIL A + ASIL B"
        echo "  - Two independent elements at different ASIL levels"
        echo "  - Useful when one element has lower criticality"
        echo ""
        echo "Option 4: ASIL C(A,A,A) = ASIL A + ASIL A + ASIL A"
        echo "  - Three independent elements, each at ASIL A"
        echo "  - 2-out-of-3 voting architecture"
        ;;

    D)
        echo -e "${GREEN}Valid decomposition options for ASIL D:${NC}"
        echo ""
        echo "Option 1: ASIL D(D) = ASIL D + ASIL D"
        echo "  - Two independent elements, each at ASIL D"
        echo "  - Highest redundancy level"
        echo ""
        echo "Option 2: ASIL D(C,C) = ASIL C + ASIL C"
        echo "  - Two independent elements, each at ASIL C"
        echo "  - Common for critical systems"
        echo ""
        echo "Option 3: ASIL D(B,C) = ASIL B + ASIL C"
        echo "  - Two independent elements at different ASIL levels"
        echo ""
        echo "Option 4: ASIL D(B,B,B) = ASIL B + ASIL B + ASIL B"
        echo "  - Three independent elements, each at ASIL B"
        echo "  - 2-out-of-3 voting"
        echo ""
        echo "Option 5: ASIL D(A,C) = ASIL A + ASIL C"
        echo "  - Two elements with large ASIL difference"
        echo "  - Less common, requires strong justification"
        ;;
esac

echo ""
echo -e "${YELLOW}Requirements for ASIL Decomposition:${NC}"
echo "  1. Elements must be sufficiently independent"
echo "  2. Independence verified through DFA (Dependent Failure Analysis)"
echo "  3. Both elements must fail for system-level hazard"
echo "  4. Common cause failures must be addressed"
echo "  5. Freedom from interference demonstrated (ASIL C/D)"
echo ""
echo -e "${BLUE}ISO 26262-9:2018 Clause 5 Reference${NC}"

#!/usr/bin/env bash
# hara-template.sh - Generate HARA (Hazard Analysis and Risk Assessment) worksheet
# Compliant with ISO 26262-3 for automotive functional safety

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
OUTPUT_FORMAT="markdown"
OUTPUT_FILE="HARA_worksheet.md"
ITEM_NAME=""
ASIL_TARGET=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -i ITEM_NAME [OPTIONS]

Generate HARA worksheet template with severity/exposure/controllability ratings.

Required:
    -i, --item NAME           Item under analysis (e.g., "Brake Control")

Options:
    -f, --format FORMAT       Output format: markdown, csv, xlsx (default: markdown)
    -o, --output FILE         Output file (default: HARA_worksheet.md)
    -a, --asil LEVEL          Target ASIL level (A, B, C, D)
    -h, --help                Show this help message

Examples:
    # Generate markdown template for brake system
    $0 -i "Electronic Brake Control" -a D

    # Generate CSV for Excel import
    $0 -i "Battery Management System" -f csv -o bms_hara.csv

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--item) ITEM_NAME="$2"; shift 2 ;;
        -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -a|--asil) ASIL_TARGET="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$ITEM_NAME" ]]; then
    echo -e "${RED}Error: Item name is required${NC}"
    usage
fi

echo -e "${BLUE}=== HARA Worksheet Generator ===${NC}"
echo "Item: $ITEM_NAME"
echo "Format: $OUTPUT_FORMAT"
echo ""

case "$OUTPUT_FORMAT" in
    markdown)
        cat > "$OUTPUT_FILE" <<EOF
# HARA Worksheet - $ITEM_NAME

**ISO 26262-3 Compliance**
$(date +"%Y-%m-%d")

## ASIL Determination

| Hazard ID | Hazardous Event | Severity | Exposure | Controllability | ASIL |
|-----------|-----------------|----------|----------|-----------------|------|
| H-001     |                 |          |          |                 |      |
| H-002     |                 |          |          |                 |      |
| H-003     |                 |          |          |                 |      |

## Rating Scales

### Severity (S)
- **S0**: No injuries
- **S1**: Light and moderate injuries
- **S2**: Severe and life-threatening injuries (survival probable)
- **S3**: Life-threatening injuries (survival uncertain), fatal injuries

### Exposure (E)
- **E0**: Incredibly unlikely
- **E1**: Very low probability
- **E2**: Low probability
- **E3**: Medium probability
- **E4**: High probability

### Controllability (C)
- **C0**: Controllable in general
- **C1**: Simply controllable
- **C2**: Normally controllable
- **C3**: Difficult to control or uncontrollable

### ASIL Classification
| S  | E  | C  | ASIL |
|----|----|----|------|
| S3 | E4 | C3 | D    |
| S3 | E4 | C2 | D    |
| S3 | E3 | C3 | D    |
| S2 | E4 | C3 | C    |
| S1 | E4 | C3 | B    |

$(if [[ -n "$ASIL_TARGET" ]]; then echo -e "\n**Target ASIL: $ASIL_TARGET**"; fi)

## Safety Goals

| Safety Goal ID | Description | ASIL | Safe State |
|----------------|-------------|------|------------|
| SG-001         |             |      |            |

EOF
        echo -e "${GREEN}✓ Markdown HARA template created: $OUTPUT_FILE${NC}"
        ;;

    csv)
        cat > "$OUTPUT_FILE" <<EOF
Hazard ID,Hazardous Event,Severity,Exposure,Controllability,ASIL,Safety Goal,Safe State
H-001,,,,,,,
H-002,,,,,,,
H-003,,,,,,,
EOF
        echo -e "${GREEN}✓ CSV HARA template created: $OUTPUT_FILE${NC}"
        ;;

    *)
        echo -e "${RED}Error: Unsupported format: $OUTPUT_FORMAT${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Identify hazardous events"
echo "  2. Rate S/E/C parameters"
echo "  3. Determine ASIL levels"
echo "  4. Define safety goals for ASIL B/C/D"

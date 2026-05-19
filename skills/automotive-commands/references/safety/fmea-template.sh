#!/usr/bin/env bash
# fmea-template.sh - Generate FMEA (Failure Mode and Effects Analysis) worksheet
# Supports DFMEA (Design) and PFMEA (Process) per AIAG-VDA methodology

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
FMEA_TYPE="design"
OUTPUT_FORMAT="markdown"
OUTPUT_FILE="FMEA_worksheet.md"
COMPONENT=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -c COMPONENT [OPTIONS]

Generate FMEA worksheet with columns for RPN calculation.

Required:
    -c, --component NAME      Component under analysis

Options:
    -t, --type TYPE           FMEA type: design, process (default: design)
    -f, --format FORMAT       Output format: markdown, csv (default: markdown)
    -o, --output FILE         Output file (default: FMEA_worksheet.md)
    -h, --help                Show this help message

Examples:
    # Design FMEA for ECU
    $0 -c "Battery Management ECU" -t design

    # Process FMEA for manufacturing
    $0 -c "Battery Pack Assembly" -t process -f csv

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--component) COMPONENT="$2"; shift 2 ;;
        -t|--type) FMEA_TYPE="$2"; shift 2 ;;
        -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$COMPONENT" ]]; then
    echo -e "${RED}Error: Component name is required${NC}"
    usage
fi

echo -e "${BLUE}=== FMEA Worksheet Generator ===${NC}"
echo "Component: $COMPONENT"
echo "Type: $(echo $FMEA_TYPE | tr '[:lower:]' '[:upper:]')FMEA"
echo ""

case "$OUTPUT_FORMAT" in
    markdown)
        cat > "$OUTPUT_FILE" <<EOF
# $(echo $FMEA_TYPE | tr '[:lower:]' '[:upper:]')FMEA - $COMPONENT

**AIAG-VDA Methodology**
$(date +"%Y-%m-%d")

## FMEA Team
- **FMEA Lead**:
- **Design Engineers**:
- **Quality Engineers**:
- **Manufacturing Engineers**:

## Failure Mode Analysis

| Item | Function | Failure Mode | Effects | S | Causes | O | Controls | D | RPN | Actions | Resp. | Status |
|------|----------|--------------|---------|---|--------|---|----------|---|-----|---------|-------|--------|
|      |          |              |         |   |        |   |          |   |     |         |       |        |

## Rating Scales

### Severity (S): 1-10
- **1-2**: Minor - No noticeable effect
- **3-4**: Low - Slight customer dissatisfaction
- **5-6**: Moderate - Customer dissatisfaction
- **7-8**: High - Safety issue with warning
- **9-10**: Very High - Safety issue without warning

### Occurrence (O): 1-10
- **1**: Remote - <0.01% failure rate
- **2-3**: Low - 0.01-0.1% failure rate
- **4-6**: Moderate - 0.1-1% failure rate
- **7-8**: High - 1-10% failure rate
- **9-10**: Very High - >10% failure rate

### Detection (D): 1-10
- **1-2**: Very High - Almost certain detection
- **3-4**: High - High detection capability
- **5-6**: Moderate - Moderate detection capability
- **7-8**: Low - Low detection capability
- **9-10**: Very Low - No detection capability

### Risk Priority Number (RPN)
\`\`\`
RPN = Severity × Occurrence × Detection
\`\`\`

**Action Required**:
- RPN > 100: Immediate action required
- RPN 40-100: Action recommended
- RPN < 40: Monitor

## Action Plan

| FMEA ID | Action | Responsibility | Target Date | Status | New RPN |
|---------|--------|----------------|-------------|--------|---------|
|         |        |                |             |        |         |

EOF
        echo -e "${GREEN}✓ Markdown FMEA template created: $OUTPUT_FILE${NC}"
        ;;

    csv)
        cat > "$OUTPUT_FILE" <<EOF
Item,Function,Failure Mode,Effects,Severity,Causes,Occurrence,Controls,Detection,RPN,Actions,Responsibility,Status
,,,,,,,,,,,
EOF
        echo -e "${GREEN}✓ CSV FMEA template created: $OUTPUT_FILE${NC}"
        ;;
esac

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Assemble cross-functional FMEA team"
echo "  2. Identify all failure modes"
echo "  3. Rate S/O/D for each failure mode"
echo "  4. Calculate RPN and prioritize actions"
echo "  5. Implement corrective actions for high RPN items"

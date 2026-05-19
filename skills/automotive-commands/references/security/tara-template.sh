#!/usr/bin/env bash
# tara-template.sh - Generate TARA (Threat Analysis and Risk Assessment) template
# Compliant with ISO/SAE 21434 for automotive cybersecurity

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
OUTPUT_FORMAT="markdown"
OUTPUT_FILE="TARA_worksheet.md"
ASSET=""
CAL_TARGET=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -a ASSET [OPTIONS]

Generate TARA worksheet template per ISO 21434 cybersecurity.

Required:
    -a, --asset NAME          Asset under analysis (e.g., "Vehicle Gateway")

Options:
    -f, --format FORMAT       Output format: markdown, csv (default: markdown)
    -o, --output FILE         Output file (default: TARA_worksheet.md)
    -c, --cal LEVEL           Target CAL (Cybersecurity Assurance Level)
    -h, --help                Show this help message

Examples:
    # Generate TARA for TCU
    $0 -a "Telematics Control Unit" -c CAL3

    # Generate CSV template
    $0 -a "Battery Management System" -f csv

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--asset) ASSET="$2"; shift 2 ;;
        -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -c|--cal) CAL_TARGET="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$ASSET" ]]; then
    echo -e "${RED}Error: Asset name is required${NC}"
    usage
fi

echo -e "${BLUE}=== TARA Worksheet Generator ===${NC}"
echo "Asset: $ASSET"
echo ""

case "$OUTPUT_FORMAT" in
    markdown)
        cat > "$OUTPUT_FILE" <<EOF
# TARA - $ASSET

**ISO/SAE 21434:2021 Compliance**
$(date +"%Y-%m-%d")

## Asset Identification

| Asset ID | Asset Name | Cybersecurity Property | Impact |
|----------|------------|------------------------|--------|
| A-001    | $ASSET     | Confidentiality        |        |
| A-002    | $ASSET     | Integrity              |        |
| A-003    | $ASSET     | Availability           |        |

### Cybersecurity Properties
- **Confidentiality**: Unauthorized disclosure of information
- **Integrity**: Unauthorized modification of data/system
- **Availability**: Denial of service or resource

## Threat Scenarios

| Threat ID | Threat Scenario | Attack Path | Impact | Feasibility | Risk | CAL |
|-----------|-----------------|-------------|--------|-------------|------|-----|
| T-001     |                 |             |        |             |      |     |
| T-002     |                 |             |        |             |      |     |
| T-003     |                 |             |        |             |      |     |

## STRIDE Analysis

| Category | Threat | Attack Vector |
|----------|--------|---------------|
| **S**poofing | | |
| **T**ampering | | |
| **R**epudiation | | |
| **I**nformation Disclosure | | |
| **D**enial of Service | | |
| **E**levation of Privilege | | |

## Impact Rating (ISO 21434 Table 7)

| Level | Severity | Description |
|-------|----------|-------------|
| Severe | 4 | Safety impact, multiple vehicles, long duration |
| Major | 3 | Significant financial/operational/privacy impact |
| Moderate | 2 | Limited financial/operational impact |
| Negligible | 1 | Minimal impact |

## Attack Feasibility Rating (ISO 21434 Table 10)

| Level | Rating | Description |
|-------|--------|-------------|
| Very High | 4 | Elapsed time < 1 day, basic equipment, layperson |
| High | 3 | Elapsed time < 1 week, moderate equipment, proficient |
| Medium | 2 | Elapsed time < 1 month, bespoke equipment, expert |
| Low | 1 | Elapsed time > 1 month, specialized equipment, multiple experts |

## Risk Determination

\`\`\`
Risk = Impact × Attack Feasibility
\`\`\`

| Impact | Feasibility | Risk Level | CAL Required |
|--------|-------------|------------|--------------|
| 4 | 4 | Very High | CAL 4 |
| 3-4 | 3 | High | CAL 3 |
| 2-3 | 2 | Medium | CAL 2 |
| 1 | 1 | Low | CAL 1 |

$(if [[ -n "$CAL_TARGET" ]]; then echo -e "\n**Target CAL: $CAL_TARGET**"; fi)

## Cybersecurity Goals

| Goal ID | Description | CAL | Mitigation Strategy |
|---------|-------------|-----|---------------------|
| CG-001  |             |     |                     |

## Treatment Options

- [x] Avoid risk - redesign to eliminate threat
- [x] Reduce risk - implement countermeasures
- [ ] Share risk - distribute across components
- [ ] Retain risk - accept residual risk with justification

EOF
        echo -e "${GREEN}✓ Markdown TARA template created: $OUTPUT_FILE${NC}"
        ;;

    csv)
        cat > "$OUTPUT_FILE" <<EOF
Threat ID,Threat Scenario,Attack Path,Impact,Feasibility,Risk Level,CAL,Cybersecurity Goal,Mitigation
T-001,,,,,,,
T-002,,,,,,,
T-003,,,,,,,
EOF
        echo -e "${GREEN}✓ CSV TARA template created: $OUTPUT_FILE${NC}"
        ;;
esac

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Identify all assets and their cybersecurity properties"
echo "  2. Brainstorm threat scenarios using STRIDE"
echo "  3. Rate impact and attack feasibility"
echo "  4. Determine CAL for each threat"
echo "  5. Define cybersecurity goals and mitigations"

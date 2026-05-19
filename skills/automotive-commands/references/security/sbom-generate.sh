#!/usr/bin/env bash
# sbom-generate.sh - Generate Software Bill of Materials (SBOM)
# Supports CycloneDX and SPDX formats using syft or cyclonedx-cli

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
TARGET_DIR="."
OUTPUT_FORMAT="cyclonedx-json"
OUTPUT_FILE="sbom.json"
TOOL="syft"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Generate Software Bill of Materials for compliance and supply chain security.

Options:
    -d, --directory DIR       Target directory (default: .)
    -f, --format FORMAT       Format: cyclonedx-json, cyclonedx-xml, spdx-json (default: cyclonedx-json)
    -o, --output FILE         Output file (default: sbom.json)
    -t, --tool TOOL           Tool: syft, cyclonedx (default: syft)
    -h, --help                Show this help message

Examples:
    # Generate CycloneDX SBOM for current project
    $0

    # Generate SPDX SBOM
    $0 -f spdx-json -o sbom-spdx.json

    # Scan Docker image
    $0 -d docker:myapp:latest -f cyclonedx-json

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory) TARGET_DIR="$2"; shift 2 ;;
        -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -t|--tool) TOOL="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== SBOM Generator ===${NC}"
echo "Target: $TARGET_DIR"
echo "Format: $OUTPUT_FORMAT"
echo "Tool: $TOOL"
echo ""

case "$TOOL" in
    syft)
        if ! command -v syft &> /dev/null; then
            echo -e "${RED}Error: syft not installed${NC}"
            echo ""
            echo "Install syft:"
            echo "  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh"
            exit 1
        fi

        echo "Generating SBOM with syft..."

        case "$OUTPUT_FORMAT" in
            cyclonedx-json)
                syft "$TARGET_DIR" -o cyclonedx-json > "$OUTPUT_FILE"
                ;;
            cyclonedx-xml)
                syft "$TARGET_DIR" -o cyclonedx-xml > "$OUTPUT_FILE"
                ;;
            spdx-json)
                syft "$TARGET_DIR" -o spdx-json > "$OUTPUT_FILE"
                ;;
            *)
                echo -e "${RED}Error: Unsupported format: $OUTPUT_FORMAT${NC}"
                exit 1
                ;;
        esac
        ;;

    cyclonedx)
        if ! command -v cyclonedx &> /dev/null; then
            echo -e "${RED}Error: cyclonedx-cli not installed${NC}"
            echo ""
            echo "Install cyclonedx-cli:"
            echo "  npm install -g @cyclonedx/cyclonedx-npm"
            exit 1
        fi

        echo "Generating SBOM with cyclonedx-cli..."

        if [[ -f "$TARGET_DIR/package.json" ]]; then
            cd "$TARGET_DIR"
            cyclonedx-npm --output-file "../$OUTPUT_FILE"
        else
            echo -e "${RED}Error: cyclonedx requires package.json${NC}"
            exit 1
        fi
        ;;

    *)
        echo -e "${RED}Error: Unknown tool: $TOOL${NC}"
        exit 1
        ;;
esac

if [[ -f "$OUTPUT_FILE" ]]; then
    echo -e "${GREEN}✓ SBOM generated: $OUTPUT_FILE${NC}"
    echo ""

    # Count components
    if command -v jq &> /dev/null && [[ "$OUTPUT_FORMAT" =~ json ]]; then
        COMPONENT_COUNT=$(jq '.components | length' "$OUTPUT_FILE" 2>/dev/null || echo "unknown")
        echo "Components cataloged: $COMPONENT_COUNT"
    fi

    echo ""
    echo -e "${YELLOW}SBOM Use Cases:${NC}"
    echo "  - Supply chain risk management"
    echo "  - License compliance verification"
    echo "  - Vulnerability tracking"
    echo "  - Regulatory compliance (EU Cyber Resilience Act)"
else
    echo -e "${RED}✗ SBOM generation failed${NC}"
    exit 1
fi

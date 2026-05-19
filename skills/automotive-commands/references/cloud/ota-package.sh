#!/usr/bin/env bash
# ota-package.sh - Package OTA (Over-The-Air) update with delta generation and signing
# Supports full and differential updates with cryptographic signing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
UPDATE_TYPE="full"
SOURCE_VERSION=""
TARGET_VERSION=""
SOURCE_IMAGE=""
TARGET_IMAGE=""
OUTPUT_FILE="ota-update.pkg"
SIGNING_KEY=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -t TYPE -s SOURCE -T TARGET [OPTIONS]

Package OTA update with optional delta compression and cryptographic signing.

Required:
    -t, --type TYPE           Update type: full, delta (default: full)
    -T, --target FILE         Target image/firmware file

Delta update only:
    -s, --source FILE         Source (current) image for delta generation
    -v, --source-version VER  Source version string
    -V, --target-version VER  Target version string

Options:
    -o, --output FILE         Output package file (default: ota-update.pkg)
    -k, --key FILE            Private key for signing (PEM format)
    -h, --help                Show this help message

Examples:
    # Create full update package
    $0 -t full -T firmware-v2.0.bin -V 2.0.0 -k signing-key.pem

    # Create delta update
    $0 -t delta -s firmware-v1.0.bin -T firmware-v2.0.bin -v 1.0.0 -V 2.0.0

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type) UPDATE_TYPE="$2"; shift 2 ;;
        -s|--source) SOURCE_IMAGE="$2"; shift 2 ;;
        -T|--target) TARGET_IMAGE="$2"; shift 2 ;;
        -v|--source-version) SOURCE_VERSION="$2"; shift 2 ;;
        -V|--target-version) TARGET_VERSION="$2"; shift 2 ;;
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -k|--key) SIGNING_KEY="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$TARGET_IMAGE" ]]; then
    echo -e "${RED}Error: Target image is required${NC}"
    usage
fi

if [[ ! -f "$TARGET_IMAGE" ]]; then
    echo -e "${RED}Error: Target image not found: $TARGET_IMAGE${NC}"
    exit 1
fi

echo -e "${BLUE}=== OTA Update Packager ===${NC}"
echo "Update type: $UPDATE_TYPE"
echo "Target image: $TARGET_IMAGE"
echo ""

WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

case "$UPDATE_TYPE" in
    full)
        echo "Creating full update package..."

        # Copy firmware
        cp "$TARGET_IMAGE" "$WORK_DIR/firmware.bin"

        TARGET_SIZE=$(stat -f%z "$TARGET_IMAGE" 2>/dev/null || stat -c%s "$TARGET_IMAGE")
        TARGET_SHA256=$(sha256sum "$TARGET_IMAGE" | cut -d' ' -f1)

        echo "  Size: $TARGET_SIZE bytes"
        echo "  SHA256: $TARGET_SHA256"
        echo ""

        # Create manifest
        cat > "$WORK_DIR/manifest.json" <<EOF
{
  "updateType": "full",
  "targetVersion": "${TARGET_VERSION:-unknown}",
  "firmware": {
    "file": "firmware.bin",
    "size": $TARGET_SIZE,
    "sha256": "$TARGET_SHA256"
  },
  "createdAt": "$(date -Iseconds)",
  "minimumBatteryLevel": 30,
  "estimatedInstallTime": 180
}
EOF
        ;;

    delta)
        if [[ -z "$SOURCE_IMAGE" ]]; then
            echo -e "${RED}Error: Source image required for delta update${NC}"
            usage
        fi

        if [[ ! -f "$SOURCE_IMAGE" ]]; then
            echo -e "${RED}Error: Source image not found: $SOURCE_IMAGE${NC}"
            exit 1
        fi

        echo "Creating delta update package..."
        echo "  Source: $SOURCE_IMAGE"
        echo "  Target: $TARGET_IMAGE"
        echo ""

        # Check for delta tools
        if command -v bsdiff &> /dev/null; then
            DELTA_TOOL="bsdiff"
            DELTA_FILE="firmware.bsdiff"
            echo "Using bsdiff for delta generation..."
            bsdiff "$SOURCE_IMAGE" "$TARGET_IMAGE" "$WORK_DIR/$DELTA_FILE"
        elif command -v xdelta3 &> /dev/null; then
            DELTA_TOOL="xdelta3"
            DELTA_FILE="firmware.xdelta3"
            echo "Using xdelta3 for delta generation..."
            xdelta3 -e -s "$SOURCE_IMAGE" "$TARGET_IMAGE" "$WORK_DIR/$DELTA_FILE"
        else
            echo -e "${YELLOW}Warning: No delta tool found (bsdiff or xdelta3)${NC}"
            echo "Falling back to full update..."
            cp "$TARGET_IMAGE" "$WORK_DIR/firmware.bin"
            DELTA_FILE="firmware.bin"
            DELTA_TOOL="none"
        fi

        SOURCE_SIZE=$(stat -f%z "$SOURCE_IMAGE" 2>/dev/null || stat -c%s "$SOURCE_IMAGE")
        TARGET_SIZE=$(stat -f%z "$TARGET_IMAGE" 2>/dev/null || stat -c%s "$TARGET_IMAGE")
        DELTA_SIZE=$(stat -f%z "$WORK_DIR/$DELTA_FILE" 2>/dev/null || stat -c%s "$WORK_DIR/$DELTA_FILE")

        COMPRESSION_RATIO=$(echo "scale=1; 100 - ($DELTA_SIZE * 100 / $TARGET_SIZE)" | bc)

        echo "  Source size: $SOURCE_SIZE bytes"
        echo "  Target size: $TARGET_SIZE bytes"
        echo "  Delta size: $DELTA_SIZE bytes (${COMPRESSION_RATIO}% reduction)"
        echo ""

        SOURCE_SHA256=$(sha256sum "$SOURCE_IMAGE" | cut -d' ' -f1)
        TARGET_SHA256=$(sha256sum "$TARGET_IMAGE" | cut -d' ' -f1)
        DELTA_SHA256=$(sha256sum "$WORK_DIR/$DELTA_FILE" | cut -d' ' -f1)

        # Create manifest
        cat > "$WORK_DIR/manifest.json" <<EOF
{
  "updateType": "delta",
  "sourceVersion": "${SOURCE_VERSION:-unknown}",
  "targetVersion": "${TARGET_VERSION:-unknown}",
  "source": {
    "sha256": "$SOURCE_SHA256",
    "size": $SOURCE_SIZE
  },
  "target": {
    "sha256": "$TARGET_SHA256",
    "size": $TARGET_SIZE
  },
  "delta": {
    "file": "$DELTA_FILE",
    "tool": "$DELTA_TOOL",
    "sha256": "$DELTA_SHA256",
    "size": $DELTA_SIZE
  },
  "createdAt": "$(date -Iseconds)",
  "minimumBatteryLevel": 30,
  "estimatedInstallTime": 180
}
EOF
        ;;

    *)
        echo -e "${RED}Error: Invalid update type: $UPDATE_TYPE${NC}"
        exit 1
        ;;
esac

# Sign manifest
if [[ -n "$SIGNING_KEY" ]]; then
    if [[ ! -f "$SIGNING_KEY" ]]; then
        echo -e "${RED}Error: Signing key not found: $SIGNING_KEY${NC}"
        exit 1
    fi

    echo "Signing package..."
    openssl dgst -sha256 -sign "$SIGNING_KEY" -out "$WORK_DIR/manifest.sig" "$WORK_DIR/manifest.json"
    echo -e "${GREEN}✓ Package signed${NC}"
    echo ""
fi

# Create package archive
echo "Creating package archive..."
cd "$WORK_DIR"
tar czf "../$OUTPUT_FILE" ./*
cd - > /dev/null

PACKAGE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE")

echo -e "${GREEN}✓ OTA package created: $OUTPUT_FILE${NC}"
echo "  Package size: $PACKAGE_SIZE bytes"
echo ""

# Display manifest
echo -e "${YELLOW}[Package Manifest]${NC}"
cat "$WORK_DIR/manifest.json"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Upload package to OTA server/CDN"
echo "  2. Create OTA campaign in fleet management"
echo "  3. Define rollout strategy (phased/immediate)"
echo "  4. Monitor installation progress and rollback if needed"

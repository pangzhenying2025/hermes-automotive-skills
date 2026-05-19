#!/usr/bin/env bash
# fleet-status.sh - Query fleet device status from cloud backend
# Supports AWS IoT Core, Azure IoT Hub fleet queries

set -euo pipefail

# Default values
PLATFORM="azure"
QUERY_TYPE="summary"
OUTPUT_FORMAT="table"
FILTER=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Query fleet device status from cloud IoT platform.

Options:
    -p, --platform NAME       Platform: aws, azure (default: azure)
    -q, --query TYPE          Query: summary, online, offline, firmware (default: summary)
    -f, --format FORMAT       Output: table, json, csv (default: table)
    --filter EXPR             Filter expression (platform-specific)
    -h, --help                Show this help message

Query Types:
    summary   - Fleet overview (total, online, offline)
    online    - List online devices
    offline   - List offline devices
    firmware  - Firmware version distribution

Examples:
    # Fleet summary
    $0 -q summary

    # List offline devices
    $0 -q offline -f json

    # Azure IoT Hub firmware query
    $0 -p azure -q firmware

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform) PLATFORM="$2"; shift 2 ;;
        -q|--query) QUERY_TYPE="$2"; shift 2 ;;
        -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
        --filter) FILTER="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== Fleet Status Query ===${NC}"
echo "Platform: $PLATFORM"
echo "Query: $QUERY_TYPE"
echo ""

case "$PLATFORM" in
    azure)
        if ! command -v az &> /dev/null; then
            echo -e "${RED}Error: Azure CLI not installed${NC}"
            exit 1
        fi

        IOT_HUB_NAME="${AZURE_IOT_HUB:-}"
        if [[ -z "$IOT_HUB_NAME" ]]; then
            echo -e "${YELLOW}Enter IoT Hub name:${NC}"
            read -r IOT_HUB_NAME
        fi

        case "$QUERY_TYPE" in
            summary)
                echo "Fleet Summary for $IOT_HUB_NAME:"
                echo ""

                TOTAL=$(az iot hub device-identity list --hub-name "$IOT_HUB_NAME" --query "length(@)" -o tsv 2>/dev/null || echo "0")
                ONLINE=$(az iot hub device-identity list --hub-name "$IOT_HUB_NAME" --query "length([?connectionState=='Connected'])" -o tsv 2>/dev/null || echo "0")
                OFFLINE=$((TOTAL - ONLINE))

                echo "  Total devices:   $TOTAL"
                echo "  Online:          $ONLINE"
                echo "  Offline:         $OFFLINE"
                echo "  Online rate:     $(echo "scale=1; $ONLINE * 100 / $TOTAL" | bc 2>/dev/null || echo 0)%"
                ;;

            online)
                echo "Online Devices:"
                echo ""
                az iot hub device-identity list \
                    --hub-name "$IOT_HUB_NAME" \
                    --query "[?connectionState=='Connected'].{DeviceId:deviceId,LastActivity:lastActivityTime}" \
                    -o table
                ;;

            offline)
                echo "Offline Devices:"
                echo ""
                az iot hub device-identity list \
                    --hub-name "$IOT_HUB_NAME" \
                    --query "[?connectionState=='Disconnected'].{DeviceId:deviceId,LastActivity:lastActivityTime}" \
                    -o table
                ;;

            firmware)
                echo "Firmware Version Distribution:"
                echo ""
                az iot hub query \
                    --hub-name "$IOT_HUB_NAME" \
                    --query-command "SELECT properties.reported.firmware.version as version, COUNT() as count FROM devices GROUP BY properties.reported.firmware.version" \
                    -o table 2>/dev/null || echo "No firmware version data available"
                ;;
        esac
        ;;

    aws)
        if ! command -v aws &> /dev/null; then
            echo -e "${RED}Error: AWS CLI not installed${NC}"
            exit 1
        fi

        case "$QUERY_TYPE" in
            summary)
                echo "Fleet Summary (AWS IoT Core):"
                echo ""

                # Count total things
                TOTAL=$(aws iot list-things --query "length(things)" --output text 2>/dev/null || echo "0")
                echo "  Total things: $TOTAL"

                # Connected status requires Fleet Indexing
                if aws iot describe-index --index-name "AWS_Things" &>/dev/null; then
                    ONLINE=$(aws iot search-index --index-name "AWS_Things" --query-string "connectivity.connected:true" --query "length(things)" --output text 2>/dev/null || echo "unknown")
                    echo "  Online: $ONLINE"
                else
                    echo -e "  ${YELLOW}Enable Fleet Indexing for connection status${NC}"
                fi
                ;;

            online)
                aws iot search-index \
                    --index-name "AWS_Things" \
                    --query-string "connectivity.connected:true" \
                    --query "things[].{ThingName:thingName,Connected:connectivity.timestamp}" \
                    --output table 2>/dev/null || \
                    echo "Enable Fleet Indexing: aws iot update-indexing-configuration"
                ;;

            firmware)
                aws iot search-index \
                    --index-name "AWS_Things" \
                    --query-string "*" \
                    --query "things[].{Thing:thingName,Version:shadow.reported.firmware.version}" \
                    --output table 2>/dev/null || echo "No shadow data available"
                ;;
        esac
        ;;
esac

echo ""

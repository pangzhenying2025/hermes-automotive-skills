#!/usr/bin/env bash
# digital-twin-sync.sh - Sync vehicle data to digital twin platform
# Supports Azure Digital Twins, AWS IoT TwinMaker

set -euo pipefail

# Default values
PLATFORM="azure"
TWIN_ID=""
TELEMETRY_FILE=""
SYNC_MODE="update"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -p PLATFORM -i TWIN_ID [OPTIONS]

Sync vehicle data to digital twin platform.

Required:
    -p, --platform NAME       Platform: azure, aws (default: azure)
    -i, --id TWIN_ID          Digital twin identifier (VIN, device ID)

Options:
    -t, --telemetry FILE      JSON file with telemetry data
    -m, --mode MODE           Sync mode: update, replace (default: update)
    -h, --help                Show this help message

Telemetry file format (JSON):
{
  "battery": {"soc": 85.5, "voltage": 400.2, "current": 125.3},
  "location": {"lat": 37.4220, "lon": -122.0840},
  "odometer": 45230.5,
  "timestamp": "2025-03-19T10:30:00Z"
}

Examples:
    # Update twin with telemetry data
    $0 -p azure -i VIN123456789 -t telemetry.json

    # Full replacement sync
    $0 -p azure -i VIN123456789 -t state.json -m replace

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform) PLATFORM="$2"; shift 2 ;;
        -i|--id) TWIN_ID="$2"; shift 2 ;;
        -t|--telemetry) TELEMETRY_FILE="$2"; shift 2 ;;
        -m|--mode) SYNC_MODE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$TWIN_ID" ]]; then
    echo -e "${RED}Error: Twin ID is required${NC}"
    usage
fi

echo -e "${BLUE}=== Digital Twin Sync ===${NC}"
echo "Platform: $PLATFORM"
echo "Twin ID: $TWIN_ID"
echo "Mode: $SYNC_MODE"
echo ""

case "$PLATFORM" in
    azure)
        if ! command -v az &> /dev/null; then
            echo -e "${RED}Error: Azure CLI not installed${NC}"
            exit 1
        fi

        # Check Azure Digital Twins extension
        if ! az extension show -n azure-iot &>/dev/null; then
            echo "Installing Azure IoT extension..."
            az extension add --name azure-iot
        fi

        ADT_INSTANCE="${AZURE_DT_INSTANCE:-}"
        if [[ -z "$ADT_INSTANCE" ]]; then
            echo -e "${YELLOW}Enter Azure Digital Twins instance name:${NC}"
            read -r ADT_INSTANCE
        fi

        if [[ -n "$TELEMETRY_FILE" ]]; then
            if [[ ! -f "$TELEMETRY_FILE" ]]; then
                echo -e "${RED}Error: Telemetry file not found: $TELEMETRY_FILE${NC}"
                exit 1
            fi

            echo "Syncing telemetry to twin: $TWIN_ID"

            case "$SYNC_MODE" in
                update)
                    # Patch update (merge)
                    az dt twin update \
                        --dt-name "$ADT_INSTANCE" \
                        --twin-id "$TWIN_ID" \
                        --json-patch "$(cat $TELEMETRY_FILE)" \
                        2>/dev/null || echo "Update failed - check twin exists"
                    ;;
                replace)
                    # Full replacement
                    az dt twin update \
                        --dt-name "$ADT_INSTANCE" \
                        --twin-id "$TWIN_ID" \
                        --twin "$(cat $TELEMETRY_FILE)" \
                        2>/dev/null || echo "Replace failed - check twin exists"
                    ;;
            esac

            echo -e "${GREEN}✓ Twin updated${NC}"
        else
            # Query current twin state
            echo "Querying digital twin state..."
            az dt twin show \
                --dt-name "$ADT_INSTANCE" \
                --twin-id "$TWIN_ID" \
                --query "{Model:\$metadata.\$model, Properties: @}" \
                -o json 2>/dev/null || echo "Twin not found"
        fi

        # Show telemetry history
        echo ""
        echo -e "${YELLOW}Recent telemetry:${NC}"
        az dt twin telemetry show \
            --dt-name "$ADT_INSTANCE" \
            --twin-id "$TWIN_ID" \
            --query "[-5:]" \
            -o table 2>/dev/null || echo "No telemetry history"
        ;;

    aws)
        if ! command -v aws &> /dev/null; then
            echo -e "${RED}Error: AWS CLI not installed${NC}"
            exit 1
        fi

        WORKSPACE_ID="${AWS_TWINMAKER_WORKSPACE:-}"
        if [[ -z "$WORKSPACE_ID" ]]; then
            echo -e "${YELLOW}Enter TwinMaker workspace ID:${NC}"
            read -r WORKSPACE_ID
        fi

        ENTITY_ID="$TWIN_ID"

        if [[ -n "$TELEMETRY_FILE" ]]; then
            echo "Syncing to AWS IoT TwinMaker entity: $ENTITY_ID"

            # Parse telemetry and update entity properties
            PROPERTIES=$(cat "$TELEMETRY_FILE" | jq -c '.battery')

            aws iottwinmaker update-entity \
                --workspace-id "$WORKSPACE_ID" \
                --entity-id "$ENTITY_ID" \
                --property-updates "$PROPERTIES" \
                2>/dev/null || echo "Update failed"

            echo -e "${GREEN}✓ Entity updated${NC}"
        else
            # Get entity
            aws iottwinmaker get-entity \
                --workspace-id "$WORKSPACE_ID" \
                --entity-id "$ENTITY_ID" \
                --output json 2>/dev/null || echo "Entity not found"
        fi
        ;;

    *)
        echo -e "${RED}Error: Unsupported platform: $PLATFORM${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}Digital Twin Use Cases:${NC}"
echo "  • Remote diagnostics and monitoring"
echo "  • Predictive maintenance simulation"
echo "  • Fleet analytics and benchmarking"
echo "  • What-if scenario testing"
echo "  • Historical playback and analysis"

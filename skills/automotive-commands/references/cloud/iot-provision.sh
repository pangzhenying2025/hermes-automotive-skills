#!/usr/bin/env bash
# iot-provision.sh - Provision IoT device for AWS IoT Core or Azure IoT Hub
# Generates certificates and registers device in cloud platform

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
PLATFORM="azure"
DEVICE_ID=""
THING_NAME=""
OUTPUT_DIR="./iot-credentials"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 -p PLATFORM -d DEVICE_ID [OPTIONS]

Provision IoT device on cloud platform.

Required:
    -p, --platform NAME       Platform: aws, azure (default: azure)
    -d, --device-id ID        Device identifier (VIN, serial number)

Options:
    -o, --output DIR          Credentials output directory (default: ./iot-credentials)
    -h, --help                Show this help message

Prerequisites:
    AWS:   aws-cli configured with credentials
    Azure: azure-cli logged in (az login)

Examples:
    # Provision device on Azure IoT Hub
    $0 -p azure -d VIN123456789

    # Provision AWS IoT thing
    $0 -p aws -d vehicle-001

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform) PLATFORM="$2"; shift 2 ;;
        -d|--device-id) DEVICE_ID="$2"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

if [[ -z "$DEVICE_ID" ]]; then
    echo -e "${RED}Error: Device ID is required${NC}"
    usage
fi

echo -e "${BLUE}=== IoT Device Provisioning ===${NC}"
echo "Platform: $PLATFORM"
echo "Device ID: $DEVICE_ID"
echo ""

mkdir -p "$OUTPUT_DIR"

case "$PLATFORM" in
    azure)
        if ! command -v az &> /dev/null; then
            echo -e "${RED}Error: Azure CLI not installed${NC}"
            echo "Install: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
            exit 1
        fi

        echo "Provisioning on Azure IoT Hub..."
        echo ""

        # Get IoT Hub name from environment or prompt
        IOT_HUB_NAME="${AZURE_IOT_HUB:-}"
        if [[ -z "$IOT_HUB_NAME" ]]; then
            echo -e "${YELLOW}Enter IoT Hub name:${NC}"
            read -r IOT_HUB_NAME
        fi

        echo "Creating device: $DEVICE_ID in hub: $IOT_HUB_NAME"

        # Create device
        az iot hub device-identity create \
            --device-id "$DEVICE_ID" \
            --hub-name "$IOT_HUB_NAME" \
            --edge-enabled false \
            2>/dev/null || echo "Device may already exist"

        # Get connection string
        CONNECTION_STRING=$(az iot hub device-identity connection-string show \
            --device-id "$DEVICE_ID" \
            --hub-name "$IOT_HUB_NAME" \
            --query connectionString -o tsv)

        # Save credentials
        cat > "$OUTPUT_DIR/device-config.json" <<EOF
{
  "platform": "azure",
  "deviceId": "$DEVICE_ID",
  "iotHubName": "$IOT_HUB_NAME",
  "connectionString": "$CONNECTION_STRING",
  "provisionedAt": "$(date -Iseconds)"
}
EOF

        echo -e "${GREEN}✓ Device provisioned successfully${NC}"
        echo ""
        echo "Configuration saved to: $OUTPUT_DIR/device-config.json"
        echo ""
        echo -e "${YELLOW}Connection details:${NC}"
        echo "  IoT Hub: $IOT_HUB_NAME.azure-devices.net"
        echo "  Device ID: $DEVICE_ID"
        ;;

    aws)
        if ! command -v aws &> /dev/null; then
            echo -e "${RED}Error: AWS CLI not installed${NC}"
            echo "Install: https://aws.amazon.com/cli/"
            exit 1
        fi

        echo "Provisioning on AWS IoT Core..."
        echo ""

        THING_NAME="$DEVICE_ID"

        # Create thing
        aws iot create-thing --thing-name "$THING_NAME" 2>/dev/null || echo "Thing may already exist"

        # Create certificate and keys
        CERT_OUTPUT=$(aws iot create-keys-and-certificate \
            --set-as-active \
            --certificate-pem-outfile "$OUTPUT_DIR/device-cert.pem" \
            --public-key-outfile "$OUTPUT_DIR/device-public.key" \
            --private-key-outfile "$OUTPUT_DIR/device-private.key" \
            --output json)

        CERT_ARN=$(echo "$CERT_OUTPUT" | jq -r '.certificateArn')
        CERT_ID=$(echo "$CERT_OUTPUT" | jq -r '.certificateId')

        # Attach policy (assumes policy "VehiclePolicy" exists)
        POLICY_NAME="${AWS_IOT_POLICY:-VehiclePolicy}"
        aws iot attach-policy --policy-name "$POLICY_NAME" --target "$CERT_ARN" 2>/dev/null || \
            echo "Create policy: aws iot create-policy --policy-name $POLICY_NAME --policy-document file://policy.json"

        # Attach certificate to thing
        aws iot attach-thing-principal --thing-name "$THING_NAME" --principal "$CERT_ARN"

        # Get endpoint
        IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --query endpointAddress -o text)

        # Download root CA
        curl -s https://www.amazontrust.com/repository/AmazonRootCA1.pem -o "$OUTPUT_DIR/root-CA.pem"

        # Save config
        cat > "$OUTPUT_DIR/device-config.json" <<EOF
{
  "platform": "aws",
  "thingName": "$THING_NAME",
  "certificateId": "$CERT_ID",
  "iotEndpoint": "$IOT_ENDPOINT",
  "certificateArn": "$CERT_ARN",
  "provisionedAt": "$(date -Iseconds)"
}
EOF

        echo -e "${GREEN}✓ Thing provisioned successfully${NC}"
        echo ""
        echo "Certificates and keys saved to: $OUTPUT_DIR/"
        echo ""
        echo -e "${YELLOW}Connection details:${NC}"
        echo "  Endpoint: $IOT_ENDPOINT"
        echo "  Thing name: $THING_NAME"
        echo "  Certificate: $OUTPUT_DIR/device-cert.pem"
        echo "  Private key: $OUTPUT_DIR/device-private.key"
        ;;

    *)
        echo -e "${RED}Error: Unsupported platform: $PLATFORM${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Copy credentials to vehicle/device"
echo "  2. Configure IoT client SDK"
echo "  3. Test connection with ping/telemetry"
echo "  4. Set up device twin/shadow"

#!/usr/bin/env bash
# ocpp-test.sh - Test OCPP (Open Charge Point Protocol) communication
# Supports OCPP 1.6J and OCPP 2.0.1 over WebSocket

set -euo pipefail

# Default values
OCPP_VERSION="1.6"
CHARGE_POINT_ID="CP001"
CENTRAL_SYSTEM_URL="ws://localhost:8080/ocpp"
TEST_SCENARIO="authorize"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Test OCPP charge point communication with central system.

Options:
    -v, --version VER         OCPP version: 1.6, 2.0.1 (default: 1.6)
    -i, --id CPID             Charge point identifier (default: CP001)
    -u, --url URL             Central system WebSocket URL
    -t, --test SCENARIO       Test scenario (see below)
    -h, --help                Show this help message

Test Scenarios (OCPP 1.6):
    authorize       - Test ID tag authorization
    start-txn       - Start charging transaction
    stop-txn        - Stop charging transaction
    heartbeat       - Send heartbeat message
    status          - Report charge point status
    meter-values    - Send meter values during charging

Examples:
    # Test authorization
    $0 -t authorize

    # Start transaction
    $0 -t start-txn -i CP001 -u ws://charger.example.com/ocpp

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version) OCPP_VERSION="$2"; shift 2 ;;
        -i|--id) CHARGE_POINT_ID="$2"; shift 2 ;;
        -u|--url) CENTRAL_SYSTEM_URL="$2"; shift 2 ;;
        -t|--test) TEST_SCENARIO="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== OCPP Test Client ===${NC}"
echo "OCPP Version: $OCPP_VERSION"
echo "Charge Point ID: $CHARGE_POINT_ID"
echo "Central System: $CENTRAL_SYSTEM_URL"
echo "Test Scenario: $TEST_SCENARIO"
echo ""

# Check for WebSocket client
if ! command -v websocat &> /dev/null && ! command -v wscat &> /dev/null; then
    echo -e "${YELLOW}Warning: No WebSocket client found${NC}"
    echo "Install websocat: cargo install websocat"
    echo "Or wscat: npm install -g wscat"
    echo ""
fi

# Generate OCPP messages
case "$TEST_SCENARIO" in
    authorize)
        echo "Testing ID tag authorization..."

        MESSAGE=$(cat <<EOF
[2, "$(uuidgen)", "Authorize", {"idTag": "RFID12345678"}]
EOF
)

        echo -e "${YELLOW}[Request]${NC}"
        echo "$MESSAGE" | jq '.'
        echo ""

        echo -e "${GREEN}Expected response:${NC}"
        cat <<EOF
[3, "<message-id>", {
  "idTagInfo": {
    "status": "Accepted",
    "expiryDate": "2025-12-31T23:59:59Z"
  }
}]
EOF
        ;;

    start-txn)
        echo "Starting charging transaction..."

        MESSAGE=$(cat <<EOF
[2, "$(uuidgen)", "StartTransaction", {
  "connectorId": 1,
  "idTag": "RFID12345678",
  "meterStart": 0,
  "timestamp": "$(date -Iseconds)"
}]
EOF
)

        echo -e "${YELLOW}[Request]${NC}"
        echo "$MESSAGE" | jq '.'
        echo ""

        echo -e "${GREEN}Expected response:${NC}"
        cat <<EOF
[3, "<message-id>", {
  "idTagInfo": {
    "status": "Accepted"
  },
  "transactionId": 12345
}]
EOF
        ;;

    stop-txn)
        echo "Stopping charging transaction..."

        TXN_ID=12345
        METER_STOP=15000  # Wh

        MESSAGE=$(cat <<EOF
[2, "$(uuidgen)", "StopTransaction", {
  "transactionId": $TXN_ID,
  "meterStop": $METER_STOP,
  "timestamp": "$(date -Iseconds)",
  "reason": "Local"
}]
EOF
)

        echo -e "${YELLOW}[Request]${NC}"
        echo "$MESSAGE" | jq '.'
        echo ""

        echo -e "${GREEN}Expected response:${NC}"
        cat <<EOF
[3, "<message-id>", {
  "idTagInfo": {
    "status": "Accepted"
  }
}]
EOF
        ;;

    heartbeat)
        echo "Sending heartbeat..."

        MESSAGE=$(cat <<EOF
[2, "$(uuidgen)", "Heartbeat", {}]
EOF
)

        echo -e "${YELLOW}[Request]${NC}"
        echo "$MESSAGE" | jq '.'
        echo ""

        echo -e "${GREEN}Expected response:${NC}"
        cat <<EOF
[3, "<message-id>", {
  "currentTime": "$(date -Iseconds)"
}]
EOF
        ;;

    status)
        echo "Reporting charge point status..."

        MESSAGE=$(cat <<EOF
[2, "$(uuidgen)", "StatusNotification", {
  "connectorId": 1,
  "errorCode": "NoError",
  "status": "Available",
  "timestamp": "$(date -Iseconds)"
}]
EOF
)

        echo -e "${YELLOW}[Request]${NC}"
        echo "$MESSAGE" | jq '.'
        echo ""

        echo -e "${GREEN}Expected response:${NC}"
        cat <<EOF
[3, "<message-id>", {}]
EOF
        ;;

    meter-values)
        echo "Sending meter values..."

        MESSAGE=$(cat <<EOF
[2, "$(uuidgen)", "MeterValues", {
  "connectorId": 1,
  "transactionId": 12345,
  "meterValue": [
    {
      "timestamp": "$(date -Iseconds)",
      "sampledValue": [
        {
          "value": "7200",
          "context": "Sample.Periodic",
          "measurand": "Energy.Active.Import.Register",
          "unit": "Wh"
        },
        {
          "value": "22.5",
          "context": "Sample.Periodic",
          "measurand": "Power.Active.Import",
          "unit": "kW"
        },
        {
          "value": "230.5",
          "context": "Sample.Periodic",
          "measurand": "Voltage",
          "phase": "L1",
          "unit": "V"
        }
      ]
    }
  ]
}]
EOF
)

        echo -e "${YELLOW}[Request]${NC}"
        echo "$MESSAGE" | jq '.'
        echo ""

        echo -e "${GREEN}Expected response:${NC}"
        cat <<EOF
[3, "<message-id>", {}]
EOF
        ;;

    *)
        echo -e "${RED}Error: Unknown test scenario: $TEST_SCENARIO${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}To send this message:${NC}"
echo "  echo '$MESSAGE' | websocat $CENTRAL_SYSTEM_URL/$CHARGE_POINT_ID"
echo ""
echo -e "${BLUE}OCPP $OCPP_VERSION Specification Reference${NC}"

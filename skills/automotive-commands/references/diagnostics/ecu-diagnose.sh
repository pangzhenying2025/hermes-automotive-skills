#!/usr/bin/env bash
#
# ecu-diagnose - ECU diagnostic command
#
# Perform ECU diagnostics including DTC reading, DID queries, and session management
#
# Usage:
#   ecu-diagnose [OPTIONS] <command>
#
# Commands:
#   dtc                       Read diagnostic trouble codes
#   clear-dtc                 Clear all DTCs
#   read-did <did>            Read data by identifier
#   write-did <did> <value>   Write data by identifier
#   info                      Read ECU identification
#   session <type>            Change diagnostic session
#   scan                      Comprehensive diagnostic scan
#
# Options:
#   -e, --ecu <address>       Target ECU address (hex)
#   -i, --interface <type>    Interface type: can, doip (default: can)
#   -c, --channel <channel>   CAN channel or DoIP IP
#   -o, --odx <path>          ODX database path
#   -f, --format <format>     Output format: text, json (default: text)
#   -s, --simulate            Simulation mode
#   -h, --help                Show this help message
#
# Examples:
#   ecu-diagnose -e 0x10 -i can dtc
#   ecu-diagnose -e 0x10 read-did 0xF190
#   ecu-diagnose --odx database.odx-d scan
#   ecu-diagnose -f json info

set -euo pipefail

# Default values
ECU_ADDRESS="0x10"
INTERFACE="can"
CHANNEL="can0"
ODX_PATH=""
FORMAT="text"
SIMULATE=false
COMMAND=""
COMMAND_ARGS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ADAPTERS_DIR="${PROJECT_ROOT}/tools/adapters/diagnostics"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

show_help() {
    sed -n '/^#/,/^$/p' "$0" | sed 's/^# \?//' | head -n -1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--ecu)
                ECU_ADDRESS="$2"
                shift 2
                ;;
            -i|--interface)
                INTERFACE="$2"
                shift 2
                ;;
            -c|--channel)
                CHANNEL="$2"
                shift 2
                ;;
            -o|--odx)
                ODX_PATH="$2"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -s|--simulate)
                SIMULATE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$COMMAND" ]]; then
                    COMMAND="$1"
                else
                    COMMAND_ARGS+=("$1")
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$COMMAND" ]]; then
        log_error "Command required"
        show_help
        exit 1
    fi
}

execute_diagnostic() {
    local python_script="${ADAPTERS_DIR}/diagnostic_cli.py"

    cat > "$python_script" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import json

sys.path.insert(0, os.path.dirname(__file__))

from python_uds_adapter import PythonUdsAdapter
from odxtools_adapter import OdxToolsAdapter

def format_output(data, output_format):
    if output_format == 'json':
        print(json.dumps(data, indent=2))
    else:
        # Text format
        if isinstance(data, dict):
            for key, value in data.items():
                print(f"{key}: {value}")
        elif isinstance(data, list):
            for item in data:
                print(f"  - {item}")
        else:
            print(data)

def read_dtcs(adapter, odx_adapter, output_format):
    print("[INFO] Reading DTCs...")
    dtcs = adapter.read_dtc_by_status_mask()

    result = []
    for dtc in dtcs:
        dtc_info = {
            'code': dtc['dtc_hex'],
            'status': dtc['status'],
            'confirmed': dtc['confirmed'],
            'pending': dtc['pending']
        }

        # Get description from ODX if available
        if odx_adapter:
            info = odx_adapter.get_dtc_info(dtc['dtc'])
            if info:
                dtc_info['description'] = info.long_name
                dtc_info['severity'] = info.severity

        result.append(dtc_info)

    if output_format == 'text':
        print(f"\n{'='*60}")
        print(f"Diagnostic Trouble Codes ({len(result)} found)")
        print(f"{'='*60}")
        for dtc in result:
            print(f"\nDTC: {dtc['code']}")
            if 'description' in dtc:
                print(f"  Description: {dtc['description']}")
            print(f"  Status: 0x{dtc['status']:02X}")
            print(f"  Confirmed: {dtc['confirmed']}")
            print(f"  Pending: {dtc['pending']}")
            if 'severity' in dtc:
                print(f"  Severity: {dtc['severity']}")
    else:
        format_output(result, output_format)

def clear_dtcs(adapter):
    print("[INFO] Clearing DTCs...")
    adapter.clear_dtc()
    print("[SUCCESS] DTCs cleared")

def read_did(adapter, odx_adapter, did_str, output_format):
    did = int(did_str, 16) if did_str.startswith('0x') else int(did_str)

    print(f"[INFO] Reading DID {did_str}...")
    data = adapter.read_data_by_identifier(did)

    result = {
        'did': f"0x{did:04X}",
        'raw_data': data.hex()
    }

    # Get metadata and apply scaling from ODX
    if odx_adapter:
        info = odx_adapter.get_did_info(did)
        if info:
            result['name'] = info.long_name
            result['data_type'] = info.data_type

            if info.data_type == 'ascii':
                result['value'] = data.decode('ascii', errors='ignore')
            else:
                scaled_value = odx_adapter.apply_scaling(data, did)
                result['value'] = scaled_value
                if info.unit:
                    result['unit'] = info.unit
    else:
        # No ODX, try to decode as ASCII if printable
        try:
            result['value'] = data.decode('ascii')
        except:
            result['value'] = int.from_bytes(data, 'big')

    if output_format == 'text':
        print(f"\nDID: {result['did']}")
        if 'name' in result:
            print(f"  Name: {result['name']}")
        print(f"  Value: {result['value']}")
        if 'unit' in result:
            print(f"  Unit: {result['unit']}")
        print(f"  Raw: {result['raw_data']}")
    else:
        format_output(result, output_format)

def read_ecu_info(adapter, output_format):
    print("[INFO] Reading ECU information...")

    info = {}
    did_map = {
        0xF190: 'VIN',
        0xF191: 'HW_Version',
        0xF195: 'SW_Version',
        0xF18C: 'Serial_Number'
    }

    for did, name in did_map.items():
        try:
            data = adapter.read_data_by_identifier(did)
            info[name] = data.decode('ascii', errors='ignore').strip()
        except:
            info[name] = 'N/A'

    if output_format == 'text':
        print(f"\n{'='*60}")
        print("ECU Information")
        print(f"{'='*60}")
        for key, value in info.items():
            print(f"{key}: {value}")
    else:
        format_output(info, output_format)

def main():
    config = json.loads(sys.argv[1])

    # Initialize UDS adapter
    ecu_addr = int(config['ecu_address'], 16)
    transport_config = {
        'type': config['interface'],
        'channel': config['channel'],
        'bitrate': 500000,
        'rx_id': ecu_addr + 0x08,
        'tx_id': ecu_addr
    }

    adapter = PythonUdsAdapter(transport_config, simulation_mode=config['simulate'])

    # Initialize ODX adapter if path provided
    odx_adapter = None
    if config.get('odx_path'):
        odx_adapter = OdxToolsAdapter(config['odx_path'], simulation_mode=config['simulate'])

    # Execute command
    command = config['command']
    args = config.get('args', [])
    output_format = config['format']

    if command == 'dtc':
        read_dtcs(adapter, odx_adapter, output_format)
    elif command == 'clear-dtc':
        clear_dtcs(adapter)
    elif command == 'read-did':
        if not args:
            print("[ERROR] DID required for read-did command")
            sys.exit(1)
        read_did(adapter, odx_adapter, args[0], output_format)
    elif command == 'info':
        read_ecu_info(adapter, output_format)
    elif command == 'session':
        session_type = int(args[0], 16) if args and args[0].startswith('0x') else 1
        adapter.diagnostic_session_control(session_type)
        print(f"[SUCCESS] Session changed to 0x{session_type:02X}")
    elif command == 'scan':
        print("[INFO] Performing comprehensive diagnostic scan...")
        read_ecu_info(adapter, output_format)
        read_dtcs(adapter, odx_adapter, output_format)
    else:
        print(f"[ERROR] Unknown command: {command}")
        sys.exit(1)

if __name__ == '__main__':
    main()
EOF

    chmod +x "$python_script"

    local config_json=$(cat <<EOF
{
    "ecu_address": "$ECU_ADDRESS",
    "interface": "$INTERFACE",
    "channel": "$CHANNEL",
    "odx_path": "$ODX_PATH",
    "command": "$COMMAND",
    "args": $(printf '%s\n' "${COMMAND_ARGS[@]}" | jq -R . | jq -s .),
    "format": "$FORMAT",
    "simulate": $SIMULATE
}
EOF
    )

    python3 "$python_script" "$config_json"
}

main() {
    parse_args "$@"

    log_info "ECU Diagnostics"
    log_info "==============="

    execute_diagnostic

    log_success "Diagnostic operation completed"
}

main "$@"

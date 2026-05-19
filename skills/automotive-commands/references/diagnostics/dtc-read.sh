#!/usr/bin/env bash
#
# dtc-read - Read diagnostic trouble codes
#
# Convenience wrapper for reading and analyzing DTCs
#
# Usage:
#   dtc-read [OPTIONS]
#
# Options:
#   -e, --ecu <address>       Target ECU address (hex) (default: 0x10)
#   -i, --interface <type>    Interface type: can, doip, obd (default: can)
#   -c, --channel <channel>   CAN channel, DoIP IP, or OBD port (default: can0)
#   -o, --odx <path>          ODX database for DTC descriptions
#   -f, --format <format>     Output format: text, json, csv (default: text)
#   -a, --all-ecus            Read DTCs from all ECUs on network
#   -p, --pending             Show only pending DTCs
#   -m, --confirmed           Show only confirmed DTCs
#   -s, --snapshot            Include freeze frame snapshots
#   --clear                   Clear DTCs after reading
#   -h, --help                Show this help message
#
# Examples:
#   dtc-read                                    # Read DTCs from default ECU
#   dtc-read -e 0x10 -o database.odx-d         # With ODX descriptions
#   dtc-read -i obd -c /dev/ttyUSB0            # OBD-II mode
#   dtc-read -f json -s > dtc_report.json      # JSON with snapshots
#   dtc-read --all-ecus                        # Scan all ECUs

set -euo pipefail

# Default values
ECU_ADDRESS="0x10"
INTERFACE="can"
CHANNEL="can0"
ODX_PATH=""
FORMAT="text"
ALL_ECUS=false
PENDING_ONLY=false
CONFIRMED_ONLY=false
SNAPSHOT=false
CLEAR_DTCS=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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
            -a|--all-ecus)
                ALL_ECUS=true
                shift
                ;;
            -p|--pending)
                PENDING_ONLY=true
                shift
                ;;
            -m|--confirmed)
                CONFIRMED_ONLY=true
                shift
                ;;
            -s|--snapshot)
                SNAPSHOT=true
                shift
                ;;
            --clear)
                CLEAR_DTCS=true
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
                log_error "Unexpected argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

read_uds_dtcs() {
    local python_script="${ADAPTERS_DIR}/dtc_reader.py"

    cat > "$python_script" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import json
import csv
from datetime import datetime

sys.path.insert(0, os.path.dirname(__file__))

from python_uds_adapter import PythonUdsAdapter
from odxtools_adapter import OdxToolsAdapter

def read_dtcs(config):
    # Initialize adapters
    ecu_addr = int(config['ecu_address'], 16)
    transport_config = {
        'type': config['interface'],
        'channel': config['channel'],
        'rx_id': ecu_addr + 0x08,
        'tx_id': ecu_addr
    }

    adapter = PythonUdsAdapter(transport_config, simulation_mode=False)

    odx_adapter = None
    if config.get('odx_path'):
        odx_adapter = OdxToolsAdapter(config['odx_path'], simulation_mode=False)

    # Read DTCs
    print("[INFO] Reading DTCs...", file=sys.stderr)
    dtcs = adapter.read_dtc_by_status_mask()

    # Filter DTCs
    if config['pending_only']:
        dtcs = [dtc for dtc in dtcs if dtc['pending']]
    if config['confirmed_only']:
        dtcs = [dtc for dtc in dtcs if dtc['confirmed']]

    # Enrich with ODX data
    enriched_dtcs = []
    for dtc in dtcs:
        dtc_info = {
            'ecu_address': config['ecu_address'],
            'code': dtc['dtc_hex'],
            'status': dtc['status'],
            'test_failed': dtc['test_failed'],
            'pending': dtc['pending'],
            'confirmed': dtc['confirmed'],
            'timestamp': datetime.now().isoformat()
        }

        if odx_adapter:
            info = odx_adapter.get_dtc_info(dtc['dtc'])
            if info:
                dtc_info['description'] = info.long_name
                dtc_info['severity'] = info.severity
                dtc_info['possible_causes'] = info.possible_causes
                dtc_info['remedies'] = info.remedies

        # Read snapshot if requested
        if config['snapshot']:
            # TODO: Implement snapshot reading (0x19 0x04)
            dtc_info['snapshot'] = {}

        enriched_dtcs.append(dtc_info)

    return enriched_dtcs

def format_text(dtcs):
    if not dtcs:
        print("No DTCs found")
        return

    print(f"\n{'='*80}")
    print(f"Diagnostic Trouble Code Report")
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*80}")
    print(f"\nTotal DTCs: {len(dtcs)}")

    for idx, dtc in enumerate(dtcs, 1):
        print(f"\n{'-'*80}")
        print(f"DTC #{idx}: {dtc['code']}")
        print(f"{'-'*80}")

        if 'description' in dtc:
            print(f"Description: {dtc['description']}")
        if 'severity' in dtc:
            print(f"Severity: {dtc['severity']}")

        print(f"Status: 0x{dtc['status']:02X}")
        print(f"  Test Failed: {dtc['test_failed']}")
        print(f"  Pending: {dtc['pending']}")
        print(f"  Confirmed: {dtc['confirmed']}")

        if 'possible_causes' in dtc and dtc['possible_causes']:
            print(f"\nPossible Causes:")
            for cause in dtc['possible_causes']:
                print(f"  - {cause}")

        if 'remedies' in dtc and dtc['remedies']:
            print(f"\nRecommended Actions:")
            for remedy in dtc['remedies']:
                print(f"  - {remedy}")

def format_json(dtcs):
    print(json.dumps({
        'timestamp': datetime.now().isoformat(),
        'dtc_count': len(dtcs),
        'dtcs': dtcs
    }, indent=2))

def format_csv(dtcs):
    if not dtcs:
        return

    fieldnames = ['code', 'description', 'severity', 'status', 'test_failed', 'pending', 'confirmed', 'timestamp']
    writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames, extrasaction='ignore')

    writer.writeheader()
    for dtc in dtcs:
        writer.writerow(dtc)

def main():
    config = json.loads(sys.argv[1])

    dtcs = read_dtcs(config)

    print(f"[SUCCESS] Read {len(dtcs)} DTCs", file=sys.stderr)

    # Format output
    output_format = config['format']
    if output_format == 'json':
        format_json(dtcs)
    elif output_format == 'csv':
        format_csv(dtcs)
    else:
        format_text(dtcs)

    # Clear DTCs if requested
    if config['clear_dtcs'] and dtcs:
        print("\n[INFO] Clearing DTCs...", file=sys.stderr)
        ecu_addr = int(config['ecu_address'], 16)
        transport_config = {
            'type': config['interface'],
            'channel': config['channel'],
            'rx_id': ecu_addr + 0x08,
            'tx_id': ecu_addr
        }
        adapter = PythonUdsAdapter(transport_config, simulation_mode=False)
        adapter.clear_dtc()
        print("[SUCCESS] DTCs cleared", file=sys.stderr)

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
    "format": "$FORMAT",
    "pending_only": $PENDING_ONLY,
    "confirmed_only": $CONFIRMED_ONLY,
    "snapshot": $SNAPSHOT,
    "clear_dtcs": $CLEAR_DTCS
}
EOF
    )

    python3 "$python_script" "$config_json"
}

read_obd_dtcs() {
    local python_script="${ADAPTERS_DIR}/dtc_reader_obd.py"

    cat > "$python_script" << 'EOF'
#!/usr/bin/env python3
import sys
import os
import json
from datetime import datetime

sys.path.insert(0, os.path.dirname(__file__))

from obd_ii_adapter import ObdIIAdapter

def main():
    config = json.loads(sys.argv[1])

    adapter = ObdIIAdapter(port=config['channel'] if config['channel'] != 'can0' else None, simulation_mode=False)

    print("[INFO] Reading OBD-II DTCs...", file=sys.stderr)
    dtcs = adapter.read_dtcs()

    print(f"[SUCCESS] Read {len(dtcs)} emission DTCs", file=sys.stderr)

    if config['format'] == 'json':
        print(json.dumps({
            'timestamp': datetime.now().isoformat(),
            'dtc_count': len(dtcs),
            'dtcs': [{'code': dtc.code, 'description': dtc.description, 'category': dtc.category} for dtc in dtcs]
        }, indent=2))
    else:
        print(f"\n{'='*80}")
        print("OBD-II Emission DTCs")
        print(f"{'='*80}")
        print(f"\nTotal DTCs: {len(dtcs)}")

        for idx, dtc in enumerate(dtcs, 1):
            print(f"\n{idx}. {dtc.code} ({dtc.category})")
            print(f"   {dtc.description}")

    if config['clear_dtcs'] and dtcs:
        print("\n[INFO] Clearing DTCs...", file=sys.stderr)
        adapter.clear_dtcs()
        print("[SUCCESS] DTCs cleared", file=sys.stderr)

    adapter.close()

if __name__ == '__main__':
    main()
EOF

    chmod +x "$python_script"

    local config_json=$(cat <<EOF
{
    "channel": "$CHANNEL",
    "format": "$FORMAT",
    "clear_dtcs": $CLEAR_DTCS
}
EOF
    )

    python3 "$python_script" "$config_json"
}

main() {
    parse_args "$@"

    log_info "DTC Reader"
    log_info "=========="

    if [[ "$INTERFACE" == "obd" ]]; then
        read_obd_dtcs
    else
        read_uds_dtcs
    fi
}

main "$@"

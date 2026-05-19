#!/bin/bash

# DLT Logging Command
# CLI interface for DLT logging operations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_usage() {
    cat <<EOF
DLT Logging Command

Usage: dlt-log.sh <command> [options]

Commands:
    init <app_id> <context_id>          Initialize DLT adapter
    send <level> <message> [kwargs]     Send log message
    parse <file>                        Parse DLT log file
    filter <file> [options]             Filter DLT logs
    export <file> <format> [output]     Export logs (csv/json)
    stats <file>                        Show log file statistics
    monitor <file>                      Monitor DLT file in real-time
    daemon start|stop|status            Control DLT daemon

Options:
    --app-id APP                Application ID (4 chars)
    --context-id CTX            Context ID (4 chars)
    --ecu-id ECU                ECU ID (4 chars)
    --log-file FILE             DLT log file path
    --daemon-host HOST          DLT daemon host
    --daemon-port PORT          DLT daemon port
    --level LEVEL               Log level (fatal/error/warn/info/debug/verbose)
    --min-level LEVEL           Minimum log level for filtering
    --text SEARCH               Text search in messages
    --limit N                   Limit number of entries

Examples:
    # Initialize and send message
    dlt-log.sh init ADAS CTRL
    dlt-log.sh send info "System started"

    # Send with structured data
    dlt-log.sh send error "Sensor timeout" sensor_id=5 error_code=0x1234

    # Parse and view logs
    dlt-log.sh parse /var/log/dlt/adas.dlt

    # Filter errors only
    dlt-log.sh filter /var/log/dlt/adas.dlt --min-level error

    # Export to CSV
    dlt-log.sh export /var/log/dlt/adas.dlt csv /tmp/logs.csv

    # Show statistics
    dlt-log.sh stats /var/log/dlt/adas.dlt

    # Monitor in real-time
    dlt-log.sh monitor /var/log/dlt/adas.dlt

EOF
}

# Python helper for DLT operations
run_python() {
    python3 <<EOF
import sys
sys.path.insert(0, '$PROJECT_ROOT')

$1
EOF
}

cmd_init() {
    local app_id="${1:-ADAS}"
    local context_id="${2:-CTRL}"
    local ecu_id="${3:-ECU1}"
    local log_file="${4:-/tmp/dlt_${app_id}_${context_id}.dlt}"

    echo -e "${BLUE}Initializing DLT adapter...${NC}"
    echo "  App ID: $app_id"
    echo "  Context ID: $context_id"
    echo "  ECU ID: $ecu_id"
    echo "  Log file: $log_file"

    run_python "
from tools.adapters.logging import DLTAdapter

dlt = DLTAdapter(
    app_id='$app_id',
    context_id='$context_id',
    ecu_id='$ecu_id',
    use_network=False,
    log_file='$log_file'
)

dlt.log_info('DLT adapter initialized')
dlt.close()

print('DLT adapter initialized successfully')
print(f'Log file: $log_file')
"
}

cmd_send() {
    local level="$1"
    local message="$2"
    shift 2
    local kwargs="$*"

    local app_id="${DLT_APP_ID:-TEST}"
    local context_id="${DLT_CONTEXT_ID:-LOG}"
    local log_file="${DLT_LOG_FILE:-/tmp/dlt_${app_id}_${context_id}.dlt}"

    echo -e "${BLUE}Sending DLT message...${NC}"
    echo "  Level: $level"
    echo "  Message: $message"
    [ -n "$kwargs" ] && echo "  Data: $kwargs"

    # Build kwargs dict
    local kwargs_dict=""
    if [ -n "$kwargs" ]; then
        for kv in $kwargs; do
            IFS='=' read -r key value <<< "$kv"
            if [ -n "$kwargs_dict" ]; then
                kwargs_dict="${kwargs_dict}, "
            fi
            kwargs_dict="${kwargs_dict}${key}='${value}'"
        done
    fi

    run_python "
from tools.adapters.logging import DLTAdapter

dlt = DLTAdapter(
    app_id='$app_id',
    context_id='$context_id',
    use_network=False,
    log_file='$log_file'
)

dlt.log_${level}('$message'${kwargs_dict:+, $kwargs_dict})
dlt.close()

print('Message sent successfully')
"
}

cmd_parse() {
    local file="$1"
    local limit="${2:-100}"

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        exit 1
    fi

    echo -e "${BLUE}Parsing DLT file: $file${NC}"

    run_python "
from tools.adapters.logging import DLTViewerAdapter

viewer = DLTViewerAdapter('$file')
viewer.print_entries(limit=$limit)
"
}

cmd_filter() {
    local file="$1"
    shift

    local app_ids=""
    local context_ids=""
    local min_level=""
    local text_search=""
    local limit="100"

    while [ $# -gt 0 ]; do
        case "$1" in
            --app-id)
                app_ids="$2"
                shift 2
                ;;
            --context-id)
                context_ids="$2"
                shift 2
                ;;
            --min-level)
                min_level="$2"
                shift 2
                ;;
            --text)
                text_search="$2"
                shift 2
                ;;
            --limit)
                limit="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        exit 1
    fi

    echo -e "${BLUE}Filtering DLT file: $file${NC}"
    [ -n "$app_ids" ] && echo "  App IDs: $app_ids"
    [ -n "$context_ids" ] && echo "  Context IDs: $context_ids"
    [ -n "$min_level" ] && echo "  Min level: $min_level"
    [ -n "$text_search" ] && echo "  Text search: $text_search"

    run_python "
from tools.adapters.logging import DLTViewerAdapter, DLTFilter, DLTLogLevel

viewer = DLTViewerAdapter('$file')

# Build filter
filter_kwargs = {}
${app_ids:+filter_kwargs['app_ids'] = ['$app_ids']}
${context_ids:+filter_kwargs['context_ids'] = ['$context_ids']}
${min_level:+filter_kwargs['min_level'] = DLTLogLevel.${min_level^^}}
${text_search:+filter_kwargs['text_search'] = '$text_search'}

dlt_filter = DLTFilter(**filter_kwargs)
viewer.print_entries(filter_obj=dlt_filter, limit=$limit)
"
}

cmd_export() {
    local file="$1"
    local format="$2"
    local output="${3:-/tmp/dlt_export.${format}}"

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        exit 1
    fi

    echo -e "${BLUE}Exporting DLT file to $format...${NC}"
    echo "  Input: $file"
    echo "  Output: $output"

    run_python "
from tools.adapters.logging import DLTViewerAdapter

viewer = DLTViewerAdapter('$file')

if '$format' == 'csv':
    viewer.export_csv('$output')
elif '$format' == 'json':
    viewer.export_json('$output', pretty=True)
else:
    print('Error: Unknown format: $format')
    exit(1)

print('Export completed: $output')
"

    echo -e "${GREEN}Export completed: $output${NC}"
}

cmd_stats() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        exit 1
    fi

    echo -e "${BLUE}Analyzing DLT file: $file${NC}"

    run_python "
from tools.adapters.logging import DLTViewerAdapter
import json

viewer = DLTViewerAdapter('$file')
stats = viewer.get_statistics()

print(json.dumps(stats, indent=2))
"
}

cmd_monitor() {
    local file="$1"
    local min_level="${2:-INFO}"

    echo -e "${BLUE}Monitoring DLT file: $file${NC}"
    echo "  Min level: $min_level"
    echo "  Press Ctrl+C to stop"
    echo ""

    run_python "
from tools.adapters.logging import DLTParser, DLTFilter, DLTLogLevel
import time
from pathlib import Path

file_path = '$file'
min_level = DLTLogLevel.${min_level^^}

parser = DLTParser(file_path)
last_size = 0

try:
    while True:
        if Path(file_path).exists():
            current_size = Path(file_path).stat().st_size

            if current_size > last_size:
                # New data available
                entries = list(parser.parse())
                for entry in entries:
                    if entry.log_level <= min_level:
                        print(entry)

                last_size = current_size

        time.sleep(0.1)
except KeyboardInterrupt:
    print('\nMonitoring stopped')
"
}

cmd_daemon() {
    local action="$1"

    case "$action" in
        start)
            echo -e "${BLUE}Starting DLT daemon...${NC}"
            if command -v dlt-daemon &> /dev/null; then
                sudo systemctl start dlt-daemon
                echo -e "${GREEN}DLT daemon started${NC}"
            else
                echo -e "${YELLOW}DLT daemon not installed${NC}"
                echo "Install with: sudo apt-get install dlt-daemon"
            fi
            ;;
        stop)
            echo -e "${BLUE}Stopping DLT daemon...${NC}"
            sudo systemctl stop dlt-daemon
            echo -e "${GREEN}DLT daemon stopped${NC}"
            ;;
        status)
            echo -e "${BLUE}DLT daemon status:${NC}"
            systemctl status dlt-daemon || echo -e "${YELLOW}DLT daemon not installed${NC}"
            ;;
        *)
            echo -e "${RED}Unknown daemon action: $action${NC}"
            echo "Use: start|stop|status"
            exit 1
            ;;
    esac
}

# Main
if [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

command="$1"
shift

case "$command" in
    init)
        cmd_init "$@"
        ;;
    send)
        cmd_send "$@"
        ;;
    parse)
        cmd_parse "$@"
        ;;
    filter)
        cmd_filter "$@"
        ;;
    export)
        cmd_export "$@"
        ;;
    stats)
        cmd_stats "$@"
        ;;
    monitor)
        cmd_monitor "$@"
        ;;
    daemon)
        cmd_daemon "$@"
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $command${NC}"
        print_usage
        exit 1
        ;;
esac

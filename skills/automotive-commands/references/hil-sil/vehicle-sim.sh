#!/bin/bash
# Vehicle Simulation Command
# Launch vehicle-in-the-loop simulation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Launch vehicle-in-the-loop (VIL) simulation.

OPTIONS:
    -s, --simulator SIMULATOR  Simulator platform (carla, gazebo, carmaker, vigrade)
    -v, --vehicle MODEL        Vehicle model file
    -w, --world WORLD          World/scenario file
    -r, --record               Enable sensor data recording
    -t, --real-time-factor F   Real-time factor (default: 1.0)
    -e, --ecus ECUS            ECUs to integrate (comma-separated)
    -h, --help                 Show this help message

EXAMPLES:
    # CARLA urban ADAS testing
    $(basename "$0") --simulator carla --vehicle models/sedan_adas.json --world scenarios/urban_intersection.xosc --record

    # Gazebo EV battery testing
    $(basename "$0") --simulator gazebo --vehicle models/ev_sedan.sdf --world worlds/highway.world --ecus bms,inverter,gateway

    # IPG CarMaker parking simulation
    $(basename "$0") --simulator carmaker --vehicle models/luxury_sedan_4wd.xml --world scenarios/parking_garage_l4.scn

EOF
    exit 1
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
SIMULATOR=""
VEHICLE_MODEL=""
WORLD_FILE=""
RECORD=false
REAL_TIME_FACTOR=1.0
ECUS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--simulator)
            SIMULATOR="$2"
            shift 2
            ;;
        -v|--vehicle)
            VEHICLE_MODEL="$2"
            shift 2
            ;;
        -w|--world)
            WORLD_FILE="$2"
            shift 2
            ;;
        -r|--record)
            RECORD=true
            shift
            ;;
        -t|--real-time-factor)
            REAL_TIME_FACTOR="$2"
            shift 2
            ;;
        -e|--ecus)
            ECUS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$SIMULATOR" ]; then
    log_error "Simulator not specified"
    usage
fi

if [ -z "$VEHICLE_MODEL" ]; then
    log_error "Vehicle model not specified"
    usage
fi

if [ -z "$WORLD_FILE" ]; then
    log_error "World/scenario file not specified"
    usage
fi

log_info "Vehicle Simulation - Simulator: $SIMULATOR"

# Initialize simulator
log_info "Initializing $SIMULATOR simulator..."
python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${SIMULATOR}_adapter.py" --init

if [ $? -ne 0 ]; then
    log_error "Simulator initialization failed"
    exit 1
fi

# Load world/scenario
log_info "Loading world: $WORLD_FILE"
python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${SIMULATOR}_adapter.py" --load-world "$WORLD_FILE"

if [ $? -ne 0 ]; then
    log_error "World loading failed"
    exit 1
fi

# Load vehicle model
log_info "Loading vehicle model: $VEHICLE_MODEL"
python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${SIMULATOR}_adapter.py" --load-vehicle "$VEHICLE_MODEL"

if [ $? -ne 0 ]; then
    log_error "Vehicle model loading failed"
    exit 1
fi

# Initialize ROS 2 if needed
if [ "$SIMULATOR" = "gazebo" ] || [ "$SIMULATOR" = "carla" ]; then
    log_info "Initializing ROS 2 bridge..."
    source /opt/ros/humble/setup.bash 2>/dev/null || log_warn "ROS 2 not found, skipping bridge"
fi

# Start simulation
log_info "Starting simulation (real-time factor: $REAL_TIME_FACTOR)..."
python3 "$PROJECT_ROOT/tools/adapters/hil_sil/${SIMULATOR}_adapter.py" \
    --start --real-time-factor "$REAL_TIME_FACTOR" &

SIM_PID=$!

sleep 3

if ! kill -0 $SIM_PID 2>/dev/null; then
    log_error "Simulation failed to start"
    exit 1
fi

log_info "Simulation running (PID: $SIM_PID)"

# Start sensor data recording
if [ "$RECORD" = true ]; then
    log_info "Starting sensor data recording..."

    if [ "$SIMULATOR" = "gazebo" ] || [ "$SIMULATOR" = "carla" ]; then
        ros2 bag record -a -o "vil_sensor_data_$(date +%Y%m%d_%H%M%S)" &
        RECORD_PID=$!
        log_info "Recording to ROS 2 bag (PID: $RECORD_PID)"
    fi
fi

# Connect ECUs if specified
if [ -n "$ECUS" ]; then
    log_info "Connecting ECUs: $ECUS"
    python3 "$PROJECT_ROOT/tools/adapters/hil_sil/vil_bridge.py" --connect-ecus "$ECUS" &
    BRIDGE_PID=$!
    log_info "ECU bridge running (PID: $BRIDGE_PID)"
fi

log_info "Simulation started successfully"
log_info "Press Ctrl+C to stop simulation"

# Wait for user interrupt
trap "log_info 'Stopping simulation...'" INT TERM

wait $SIM_PID

# Cleanup
log_info "Cleaning up..."

if [ -n "$RECORD_PID" ]; then
    kill $RECORD_PID 2>/dev/null || true
fi

if [ -n "$BRIDGE_PID" ]; then
    kill $BRIDGE_PID 2>/dev/null || true
fi

log_info "Vehicle simulation complete"

exit 0

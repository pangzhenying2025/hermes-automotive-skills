#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Gazebo Automotive — Configure Gazebo for automotive simulation scenarios
# ============================================================================
# Usage: gazebo-automotive.sh [options]
# Options:
#   -h, --help       Show help
#   -v, --verbose    Verbose output
#   -w, --world      World file to load
#   -m, --model      Vehicle model (sedan|suv|truck)
#   --headless       Run without GUI
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

VERBOSE=false
WORLD_FILE=""
VEHICLE_MODEL="sedan"
HEADLESS=false
OUTPUT_DIR="./gazebo-config"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $(basename "$0") [options]"
            echo "  -w, --world      World file to load"
            echo "  -m, --model      Vehicle model (sedan|suv|truck)"
            echo "  --headless       Run without GUI"
            exit 0
            ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -w|--world) WORLD_FILE="$2"; shift 2 ;;
        -m|--model) VEHICLE_MODEL="$2"; shift 2 ;;
        --headless) HEADLESS=true; shift ;;
        *) shift ;;
    esac
done

check_gazebo_installation() {
    info "Checking Gazebo installation..."
    if command -v gz &>/dev/null; then
        info "Gazebo found: $(gz sim --version 2>&1 | head -1 || echo 'version unknown')"
    elif command -v gazebo &>/dev/null; then
        info "Gazebo Classic found"
    else
        warn "Gazebo not found in PATH (config generation only)"
    fi
}

get_vehicle_params() {
    local mass_kg wheelbase_m track_m
    case "$VEHICLE_MODEL" in
        sedan)  mass_kg=1800; wheelbase_m="2.85"; track_m="1.55" ;;
        suv)    mass_kg=2200; wheelbase_m="2.95"; track_m="1.65" ;;
        truck)  mass_kg=3500; wheelbase_m="3.40"; track_m="1.80" ;;
        *) error "Invalid vehicle model: $VEHICLE_MODEL"; return 1 ;;
    esac
    info "Vehicle: $VEHICLE_MODEL (mass=${mass_kg}kg, wheelbase=${wheelbase_m}m)"
}

generate_world_config() {
    mkdir -p "$OUTPUT_DIR"
    local world_file="$OUTPUT_DIR/automotive_world.sdf"
    info "Generating Gazebo world file..."

    cat > "$world_file" <<EOF
<?xml version="1.0" ?>
<sdf version="1.8">
  <world name="automotive_test">
    <physics type="ode">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
    </physics>
    <gravity>0 0 -9.81</gravity>
    <scene>
      <ambient>0.5 0.5 0.5 1</ambient>
      <background>0.7 0.8 0.9 1</background>
      <shadows>true</shadows>
    </scene>
    <model name="ground_plane">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry><plane><normal>0 0 1</normal><size>500 500</size></plane></geometry>
        </collision>
        <visual name="visual">
          <geometry><plane><normal>0 0 1</normal><size>500 500</size></plane></geometry>
        </visual>
      </link>
    </model>
    <!-- Vehicle model: ${VEHICLE_MODEL} -->
    <!-- Generated: $(date -Iseconds) -->
  </world>
</sdf>
EOF
    info "World file written to: $world_file"
}

generate_launch_command() {
    info "Gazebo launch command:"
    local cmd="gz sim"
    [[ -n "$WORLD_FILE" ]] && cmd="$cmd --file $WORLD_FILE"
    $HEADLESS && cmd="$cmd --headless-rendering"
    $VERBOSE && cmd="$cmd --verbose"
    info "  $cmd"
}

main() {
    info "Starting Gazebo automotive simulation setup..."
    check_gazebo_installation
    get_vehicle_params
    generate_world_config
    generate_launch_command
    info "Gazebo setup complete for model: $VEHICLE_MODEL"
}

main

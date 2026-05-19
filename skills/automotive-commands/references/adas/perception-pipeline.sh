#!/bin/bash
# ADAS Perception Pipeline Setup and Execution
# Usage: ./perception-pipeline.sh [simulator|vehicle] [config_file]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configuration
MODE="${1:-simulator}"
CONFIG_FILE="${2:-$PROJECT_ROOT/examples/configs/perception_default.yaml}"
VENV_PATH="$PROJECT_ROOT/.venv"

echo "=========================================="
echo "ADAS Perception Pipeline"
echo "=========================================="
echo "Mode: $MODE"
echo "Config: $CONFIG_FILE"
echo ""

# Activate virtual environment
if [ -d "$VENV_PATH" ]; then
    source "$VENV_PATH/bin/activate"
    echo "Virtual environment activated"
else
    echo "Warning: Virtual environment not found at $VENV_PATH"
fi

# Check dependencies
check_dependencies() {
    echo "Checking dependencies..."
    python3 -c "import cv2, numpy, torch" 2>/dev/null || {
        echo "Error: Missing dependencies. Install with:"
        echo "  pip install opencv-python numpy torch"
        exit 1
    }

    if [ "$MODE" == "simulator" ]; then
        python3 -c "import carla" 2>/dev/null || {
            echo "Error: CARLA Python API not found"
            echo "  Install from: https://github.com/carla-simulator/carla"
            exit 1
        }
    fi

    echo "Dependencies OK"
}

# Start CARLA simulator (if needed)
start_carla() {
    if [ "$MODE" == "simulator" ]; then
        echo "Checking CARLA server..."
        if ! nc -z localhost 2000 2>/dev/null; then
            echo "CARLA server not running. Start with:"
            echo "  cd /path/to/CARLA && ./CarlaUE4.sh"
            exit 1
        fi
        echo "CARLA server is running"
    fi
}

# Run perception pipeline
run_perception() {
    echo ""
    echo "Starting perception pipeline..."

    export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"

    python3 <<EOF
import sys
sys.path.insert(0, '$PROJECT_ROOT')

from tools.adapters.hil_sil.carla_adapter import CARLAAdapter, ScenarioConfig, SensorType
import carla
import numpy as np
import time

def main():
    print("Initializing perception pipeline...")

    # Connect to CARLA
    adapter = CARLAAdapter(host='localhost', port=2000)
    if not adapter.connect():
        print("Failed to connect to CARLA")
        return 1

    # Load scenario
    scenario = ScenarioConfig(
        map_name='Town01',
        weather='ClearNoon',
        num_vehicles=30,
        num_pedestrians=20
    )

    if not adapter.load_scenario(scenario):
        print("Failed to load scenario")
        adapter.cleanup()
        return 1

    # Attach sensors
    print("Attaching sensors...")

    # Front camera
    adapter.attach_sensor(
        SensorType.RGB_CAMERA,
        'front_camera',
        transform=carla.Transform(carla.Location(x=0.8, z=1.7)),
        attributes={
            'image_size_x': '1920',
            'image_size_y': '1080',
            'fov': '110'
        }
    )

    # Front LiDAR
    adapter.attach_sensor(
        SensorType.LIDAR,
        'front_lidar',
        transform=carla.Transform(carla.Location(x=0.0, z=2.5)),
        attributes={
            'channels': '64',
            'range': '100',
            'points_per_second': '1000000'
        }
    )

    # Front radar
    adapter.attach_sensor(
        SensorType.RADAR,
        'front_radar',
        transform=carla.Transform(carla.Location(x=2.0, z=1.0)),
        attributes={
            'horizontal_fov': '30',
            'vertical_fov': '30',
            'range': '100'
        }
    )

    print("Sensors attached")
    print("")
    print("Running perception pipeline (Ctrl+C to stop)...")
    print("-" * 80)

    try:
        frame = 0
        while frame < 500:  # Run for 500 frames
            # Get vehicle state
            state = adapter.get_vehicle_state()

            # Simple control: maintain 30 km/h
            target_speed = 30.0 / 3.6
            throttle = 0.5 if state.speed_mps < target_speed else 0.0
            adapter.apply_control(throttle=throttle, steer=0.0)

            # Get sensor data
            camera_data = adapter.get_sensor_data('front_camera', timeout=0.1)
            lidar_data = adapter.get_sensor_data('front_lidar', timeout=0.1)
            radar_data = adapter.get_sensor_data('front_radar', timeout=0.1)

            # Print status
            if frame % 10 == 0:
                print(f"Frame {frame:4d} | "
                      f"Speed: {state.speed_kmh:5.1f} km/h | "
                      f"Pos: ({state.location[0]:6.1f}, {state.location[1]:6.1f}) | "
                      f"Camera: {'OK' if camera_data else 'N/A'} | "
                      f"LiDAR: {'OK' if lidar_data else 'N/A'} | "
                      f"Radar: {'OK' if radar_data else 'N/A'}")

            # Tick simulation
            adapter.tick(dt=0.05)
            frame += 1

    except KeyboardInterrupt:
        print("\nInterrupted by user")

    finally:
        adapter.cleanup()
        print("Pipeline stopped")

    return 0

if __name__ == '__main__':
    exit(main())
EOF
}

# Main execution
main() {
    check_dependencies
    start_carla
    run_perception
}

main

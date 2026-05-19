---
name: automotive-hil-sil
description: >
  CAN bus communication testing and validation for automotive networks Covers 9 topics across hil-sil domain. Includes 9 skill files covering .
tags: [automotive, automotive-hil-sil]
---

# Automotive Hil Sil

9 skill files covering hil-sil domain for automotive software engineering.


## Instructions

### can-bus-testing

execution:
- commands:
  - python3 tests/can_testing/test_runner.py --interface {{can_interface}} --test
    {{test_type}} --dbc {{dbc_file}}
  description: Execute CAN bus tests
setup:
- commands:
  - sudo ip link set {{can_interface}} type can bitrate {{bitrate}}
  - sudo ip link set up {{can_interface}}
  description: Configure CAN interface
validation:
- commands:
  - candump {{can_interface}} -n 100 > can_dump.log
  - python3 tests/can_testing/validator.py --log can_dump.log
  description: Validate CAN communication

### carla-integration

cleanup:
- commands:
  - python3 tools/adapters/hil_sil/carla_adapter.py --cleanup
  description: Destroy actors
execution:
- commands:
  - python3 tools/adapters/hil_sil/carla_adapter.py --start-simulation
  description: Start simulation
- commands:
  - python3 scenario_runner.py --openscenario {{scenario}} --host {{carla_host}} --port
    {{carla_port}}
  conditions:
  - '{{scenario}} != null'
  description: Run scenario
- commands:
  - ros2 bag record /carla/ego_vehicle/camera/rgb /carla/ego_vehicle/lidar /carla/ego_vehicle/radar
    /carla/ego_vehicle/gnss /carla/ego_vehicle/imu
  description: Record sensor data
- commands:
  - ros2 topic echo /carla/ego_vehicle/vehicle_status
  description: Monitor vehicle telemetry
setup:
- commands:
  - python3 tools/adapters/hil_sil/carla_adapter.py --connect {{carla_host}}:{{carla_port}}
  description: Connect to CARLA server
- commands:
  - python3 tools/adapters/hil_sil/carla_adapter.py --load-town {{town}} --weather
    {{weather}}
  description: Load town and set weather
- commands:
  - python3 tools/adapters/hil_sil/carla_adapter.py --spawn-ego {{ego_vehicle}}
  description: Spawn ego vehicle
- commands:
  - python3 tools/adapters/hil_sil/carla_adapter.py --attach-sensors {{sensors}}
  description: Attach sensors to ego vehicle
- commands:
  - python3 tools/adapters/hil_sil/carla_adapter.py --traffic-manager {{traffic_manager}}
  description: Configure traffic manager
- commands:
  - source /opt/ros/humble/setup.bash
  - ros2 launch carla_ros_bridge carla_ros_bridge.launch.py
  description: Initialize ROS 2 bridge
validation:
- commands:
  - python3 tools/analysis/carla_collision_analyzer.py --data carla_logs/
  description: Analyze collision events
- commands:
  - python3 tools/analysis/sensor_coverage_analyzer.py --sensors {{sensors}}
  description: Evaluate sensor coverage
- commands:
  - python3 tools/reporting/carla_report_generator.py --output carla_report.html
  description: Generate simulation report

### fault-injection

execution:
- commands:
  - python3 tests/fault_injection/baseline_recorder.py --ecu {{target_ecu}}
  description: Start baseline recording
- commands:
  - python3 tools/adapters/hil_sil/fault_injector.py --inject --point {{injection_point}}
  description: Inject fault at specified point
- commands:
  - python3 tests/fault_injection/safety_monitor.py --ecu {{target_ecu}}
  conditions:
  - '{{safety_monitoring}} == true'
  description: Monitor system response
- commands:
  - python3 tests/fault_injection/response_recorder.py --output fault_response.log
  description: Record fault response
setup:
- commands:
  - python3 tools/adapters/hil_sil/fault_injector.py --init --target {{target_ecu}}
  description: Initialize fault injection framework
- commands:
  - python3 tools/adapters/hil_sil/fault_injector.py --configure --fault-type {{fault_type}}
    --parameters {{fault_parameters}}
  description: Configure fault scenario
- commands:
  - python3 tools/adapters/hil_sil/fault_injector.py --load-oracle {{test_oracle}}
  description: Load test oracle
validation:
- commands:
  - python3 tools/analysis/oracle_validator.py --response fault_response.log --oracle
    {{test_oracle}}
  description: Compare against test oracle
- commands:
  - python3 tools/analysis/safety_mechanism_analyzer.py --data fault_response.log
  description: Analyze safety mechanisms
- commands:
  - python3 tools/reporting/fmea_report_generator.py --output fmea_report.html
  description: Generate FMEA report

### gazebo-integration

execution:
- commands:
  - 'ros2 topic pub /model/ego_vehicle/cmd_vel geometry_msgs/Twist ''{linear: {x:
    2.0}}'''
  description: Control vehicle via ROS 2
- commands:
  - ros2 topic list | grep /sensors
  - ros2 topic echo /sensors/lidar/points
  description: Monitor sensor topics
- commands:
  - ros2 bag record -a -o gazebo_simulation
  description: Record simulation data
setup:
- commands:
  - source /opt/ros/humble/setup.bash
  description: Source ROS 2 environment
- commands:
  - gz sim {{world_file}} -r
  description: Launch Gazebo with world file
- commands:
  - ros2 run gazebo_ros spawn_entity.py -file {{robot_model}} -entity ego_vehicle
  description: Spawn robot model
- commands:
  - ros2 run ros_gz_bridge parameter_bridge /model/ego_vehicle/cmd_vel@geometry_msgs/msg/Twist@gz.msgs.Twist
  conditions:
  - '{{ros2_bridge}} == true'
  description: Start ROS 2 bridge
- commands:
  - python3 tools/adapters/hil_sil/gazebo_adapter.py --set-physics {{physics_engine}}
  description: Configure physics engine
validation:
- commands:
  - ros2 run tf2_tools view_frames
  description: Check TF tree
- commands:
  - rviz2 -d config/gazebo_visualization.rviz
  description: Visualize in RViz

### hil-setup

setup:
- commands:
  - python3 tools/adapters/hil_sil/{{platform}}_adapter.py --check-connection
  - python3 tools/adapters/hil_sil/{{platform}}_adapter.py --configure {{interface_config}}
  description: Configure HIL platform connection
- commands:
  - python3 tools/adapters/hil_sil/{{platform}}_adapter.py --load-ecu {{ecu_type}}
  description: Load ECU software to HIL platform
- commands:
  - sudo ip link set can0 type can bitrate 500000
  - sudo ip link set can0 up
  - cansend can0 123#DEADBEEF
  description: Initialize CAN/FlexRay/LIN interfaces
- commands:
  - python3 tools/adapters/hil_sil/{{platform}}_adapter.py --configure-io {{interface_config}}
  description: Configure I/O channels and signal routing
- commands:
  - python3 tools/adapters/hil_sil/{{platform}}_adapter.py --load-scenario {{test_scenario}}
  description: Load test scenario and stimulation profiles
validation:
- commands:
  - python3 tools/adapters/hil_sil/{{platform}}_adapter.py --validate
  description: Verify HIL platform readiness
- commands:
  - python3 tests/hil/loopback_test.py --platform {{platform}}
  description: Run loopback tests on all interfaces
- commands:
  - python3 tests/hil/signal_integrity_test.py
  description: Check signal integrity and timing

### sensor-simulation

execution:
- commands:
  - python3 tools/adapters/hil_sil/sensor_simulator.py --start --output {{output_format}}
  description: Start sensor data stream
- commands:
  - python3 tools/adapters/hil_sil/noise_injector.py --apply {{noise_model}}
  conditions:
  - '{{noise_model}} != null'
  description: Apply noise model
- commands:
  - ros2 topic pub /sensors/{{sensor_type}}/data sensor_msgs/{{sensor_type}}
  conditions:
  - '{{output_format}} == ''ros2'''
  description: Publish to ROS 2
setup_camera:
- commands:
  - python3 tools/adapters/hil_sil/sensor_simulator.py --type camera --config {{sensor_config}}
  description: Configure camera sensor
- commands:
  - python3 tools/adapters/hil_sil/camera_simulator.py --resolution {{sensor_config.resolution}}
    --fps {{sensor_config.fps}} --fov {{sensor_config.fov}}
  description: Set image parameters
setup_lidar:
- commands:
  - python3 tools/adapters/hil_sil/sensor_simulator.py --type lidar --config {{sensor_config}}
  description: Configure LiDAR sensor
- commands:
  - python3 tools/adapters/hil_sil/lidar_simulator.py --channels {{sensor_config.channels}}
    --range {{sensor_config.range}} --points-per-second {{sensor_config.points_per_second}}
  description: Initialize point cloud generation
setup_radar:
- commands:
  - python3 tools/adapters/hil_sil/sensor_simulator.py --type radar --config {{sensor_config}}
  description: Configure radar sensor parameters
- commands:
  - python3 tools/adapters/hil_sil/radar_simulator.py --range {{sensor_config.range}}
    --fov {{sensor_config.fov}} --resolution {{sensor_config.resolution}}
  description: Set radar detection parameters
setup_ultrasonic:
- commands:
  - python3 tools/adapters/hil_sil/sensor_simulator.py --type ultrasonic --config
    {{sensor_config}}
  description: Configure ultrasonic array
- commands:
  - python3 tools/adapters/hil_sil/ultrasonic_simulator.py --range {{sensor_config.range}}
    --beam-width {{sensor_config.beam_width}}
  description: Set ultrasonic detection cone
validation:
- commands:
  - python3 tools/visualization/sensor_visualizer.py --sensor {{sensor_type}}
  description: Visualize sensor output
- commands:
  - python3 tools/analysis/sensor_accuracy_validator.py --ground-truth ground_truth.json
  description: Validate sensor accuracy

### sil-test

analysis:
- commands:
  - gcov {{ecu_software}}
  - lcov --capture --directory . --output-file coverage.info
  - genhtml coverage.info --output-directory coverage_html
  conditions:
  - '{{coverage_analysis}} == true'
  description: Generate code coverage report
- commands:
  - python3 tools/analysis/trace_analyzer.py --input sil_traces.log
  description: Analyze execution traces
- commands:
  - python3 tools/reporting/sil_report_generator.py --results results/
  description: Generate test report
cleanup:
- commands:
  - python3 tools/adapters/hil_sil/{{simulation_mode}}_adapter.py --stop
  description: Stop virtual ECU
- commands:
  - sudo ip link set down vcan0
  - sudo ip link delete vcan0
  - sudo ip link set down vcan1
  - sudo ip link delete vcan1
  description: Remove virtual network interfaces
execution:
- commands:
  - python3 tests/sil/test_runner.py --suite {{test_suite}}
  description: Load test scenarios
- commands:
  - pytest tests/sil/functional/ -v --cov={{ecu_software}}
  description: Execute functional tests
- commands:
  - pytest tests/sil/regression/ -v --junitxml=results/sil_regression.xml
  description: Run regression tests
- commands:
  - python3 tests/sil/fault_injection.py --target {{ecu_software}}
  conditions:
  - '{{fault_injection}} == true'
  description: Perform fault injection tests
setup:
- commands:
  - python3 tools/adapters/hil_sil/qemu_adapter.py --create-vm {{architecture}}
  - python3 tools/adapters/hil_sil/qemu_adapter.py --load-binary {{ecu_software}}
  description: Create virtual ECU environment
- commands:
  - sudo modprobe vcan
  - sudo ip link add dev vcan0 type vcan
  - sudo ip link set up vcan0
  - sudo ip link add dev vcan1 type vcan
  - sudo ip link set up vcan1
  description: Configure virtual CAN network
- commands:
  - python3 tools/adapters/hil_sil/{{simulation_mode}}_adapter.py --start {{ecu_software}}
  description: Start virtual ECU simulation
- commands:
  - python3 tools/adapters/hil_sil/network_simulator.py --configure {{network_config}}
  description: Initialize network stack and routing

### test-automation

[{'description': 'Execute automated test suite', 'commands': ['python3 tests/automation/test_runner.py --suite {{test_suite}} --platform {{platform}}']}]

### vil-test

cleanup:
- commands:
  - python3 tools/adapters/hil_sil/{{simulator}}_adapter.py --stop
  description: Stop simulation
- commands:
  - tar -czf vil_sensor_data_$(date +%Y%m%d_%H%M%S).tar.gz vil_sensor_data/
  description: Archive sensor data
execution:
- commands:
  - python3 tools/adapters/hil_sil/{{simulator}}_adapter.py --start --real-time-factor
    {{real_time_factor}}
  description: Start vehicle simulation
- commands:
  - ros2 bag record -a -o vil_sensor_data
  conditions:
  - '{{data_recording}} == true'
  description: Run sensor data collection
- commands:
  - python3 tests/vil/scenario_executor.py --scenario {{scenario_file}}
  description: Execute scenario-based tests
- commands:
  - python3 tests/vil/ecu_monitor.py --ecus {{ecu_integration}}
  description: Monitor ECU responses
setup:
- commands:
  - python3 tools/adapters/hil_sil/{{simulator}}_adapter.py --init
  - python3 tools/adapters/hil_sil/{{simulator}}_adapter.py --load-vehicle {{vehicle_model}}
  description: Initialize vehicle simulator
- commands:
  - python3 tools/adapters/hil_sil/sensor_simulator.py --configure {{sensor_suite}}
  description: Configure sensor suite
- commands:
  - python3 tools/adapters/hil_sil/{{simulator}}_adapter.py --load-scenario {{scenario_file}}
  description: Load driving scenario
- commands:
  - python3 tools/adapters/hil_sil/vil_bridge.py --connect-ecus {{ecu_integration}}
  description: Setup ECU integration bridges
- commands:
  - source /opt/ros/humble/setup.bash
  - ros2 launch vil_simulation vil_bridge.launch.py
  description: Initialize ROS 2 communication stack
validation:
- commands:
  - python3 tools/analysis/sensor_fusion_validator.py --data vil_sensor_data
  description: Analyze sensor fusion accuracy
- commands:
  - python3 tools/analysis/dynamics_validator.py --reference {{vehicle_model}}
  description: Validate vehicle dynamics behavior
- commands:
  - python3 tests/vil/decision_quality_checker.py --results vil_results/
  description: Check ECU decision quality
- commands:
  - python3 tools/reporting/vil_report_generator.py --output vil_report.html
  description: Generate VIL test report

### HIL/SIL/VIL Testing Guide

Comprehensive guide for Hardware-in-the-Loop, Software-in-the-Loop, and Vehicle-in-the-Loop testing in automotive embedded systems.

## Table of Contents

1. [Introduction](#introduction)
2. [Testing Levels](#testing-levels)
3. [Platform Setup](#platform-setup)
4. [Test Execution](#test-execution)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

## Introduction

This guide covers the complete HIL/SIL/VIL testing workflow for automotive ECUs and ADAS systems.

### When to Use Each Testing Level

**HIL (Hardware-in-the-Loop):**
- Final validation before production
- Hardware-specific testing (EMC, temperature)
- Real-time performance validation
- Integration with physical sensors/actuators

**SIL (Software-in-the-Loop):**
- Early-stage software validation
- Regression testing in CI/CD
- Code coverage analysis
- Fault injection scenarios

**VIL (Vehicle-in-the-Loop):**
- ADAS/AD algorithm validation
- Sensor fusion testing
- Complex scenario simulation
- Virtual test drives

## Testing Levels

### HIL Testing Workflow

```mermaid
graph LR
    A[ECU Specification] --> B[HIL Setup]
    B --> C[Load ECU Model]
    C --> D[Configure Interfaces]
    D --> E[Execute Tests]
    E --> F[Analyze Results]
    F --> G[Report]
```

**Setup:**
```bash
# 1. Configure HIL platform
./commands/hil-sil/hil-setup.sh \
  --platform dspace-scalexio \
  --ecu bms \
  --config config/bms_interfaces.json

# 2. Validate setup
./commands/hil-sil/hil-setup.sh --validate
```

**Execution:**
```python
from tools.adapters.hil_sil import ScalexioAdapter

# Initialize HIL platform
adapter = ScalexioAdapter(config)
adapter.connect()
adapter.load_ecu_model('models/bms.sdf', 'bms')
adapter.configure_interfaces(interface_config)
adapter.start_simulation()

# Run test scenarios
for scenario in test_scenarios:
    adapter.load_scenario(scenario)
    results = execute_test(adapter)
    analyze_results(results)

adapter.stop_simulation()
adapter.disconnect()
```

### SIL Testing Workflow

**Setup:**
```bash
# 1. Build ECU software
make clean && make

# 2. Run SIL tests with coverage
./commands/hil-sil/sil-test.sh \
  --binary build/bms_application.elf \
  --arch arm-cortex-m4 \
  --mode qemu \
  --tests tests/sil/bms_comprehensive.yaml \
  --coverage \
  --output results/sil/
```

**CI/CD Integration:**
```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - report

build_ecu:
  stage: build
  script:
    - make clean && make
  artifacts:
    paths:
      - build/

sil_test:
  stage: test
  dependencies:
    - build_ecu
  script:
    - ./commands/hil-sil/sil-test.sh --binary build/*.elf --arch arm-cortex-m4 --tests tests/sil/ --coverage
  artifacts:
    reports:
      junit: results/sil/test_results.xml
      coverage_report:
        coverage_format: cobertura
        path: results/sil/coverage.xml
    paths:
      - results/sil/

test_report:
  stage: report
  dependencies:
    - sil_test
  script:
    - python3 tools/reporting/sil_report_generator.py --results results/sil/ --output report.html
  artifacts:
    paths:
      - report.html
```

### VIL Testing Workflow

**CARLA Scenario:**
```bash
# 1. Start CARLA server
./CarlaUE4.sh -quality-level=Low -RenderOffScreen

# 2. Run VIL simulation
./commands/hil-sil/vehicle-sim.sh \
  --simulator carla \
  --vehicle models/sedan_adas.json \
  --world scenarios/urban_intersection.xosc \
  --record \
  --ecus adas-ecu,gateway

# 3. Analyze recorded data
ros2 bag play vil_sensor_data_20260319_120000/ --topics /sensors/lidar/points /sensors/camera/image
```

**Gazebo Scenario:**
```bash
# 1. Launch Gazebo with ROS 2
source /opt/ros/humble/setup.bash
./commands/hil-sil/vehicle-sim.sh \
  --simulator gazebo \
  --vehicle models/ev_sedan.sdf \
  --world worlds/highway.world \
  --ecus bms,inverter

# 2. Monitor in RViz
rviz2 -d config/gazebo_visualization.rviz
```

## Platform Setup

### dSPACE SCALEXIO

**Hardware Configuration:**
```json
{
  "platform_type": "DS6001",
  "processor_boards": ["DS6001"],
  "io_boards": ["DS2655"],
  "network_interfaces": {
    "can_channels": [0, 1, 2],
    "flexray_channels": [0],
    "analog_inputs": 32,
    "digital_io": 64
  }
}
```

**Python API:**
```python
from tools.adapters.hil_sil import ScalexioAdapter
from tools.adapters.hil_sil.scalexio_adapter import ScalexioConfig

config = ScalexioConfig(
    host='192.168.1.100',
    port=2036,
    platform_type='DS6001',
    processor_boards=['DS6001'],
    io_boards=['DS2655'],
    network_interfaces={}
)

adapter = ScalexioAdapter(config)
adapter.connect()
adapter.configure_interfaces(interface_config)
adapter.load_ecu_model('models/bms.sdf', 'bms')
```

### NI PXI/VeriStand

**Module Configuration:**
```python
from tools.adapters.hil_sil import NIPXIAdapter
from tools.adapters.hil_sil.ni_pxi_adapter import NIPXIConfig

config = NIPXIConfig(
    chassis_address='PXI1',
    controller_type='PXIe-8880',
    veristand_project='projects/bms_test.nivsproj',
    fpga_bitfiles=['fpga/bms_io.lvbitx'],
    modules=[
        {'slot': 2, 'type': 'PXIe-6368'},  # Analog I/O
        {'slot': 3, 'type': 'PXIe-8135'},  # FPGA
        {'slot': 4, 'type': 'PXI-8513'}    # CAN
    ]
}

adapter = NIPXIAdapter(config)
adapter.connect()
adapter.load_veristand_project(config.veristand_project)
adapter.program_fpga('fpga/bms_io.lvbitx', slot=3)
```

### QEMU Virtual ECU

**Architecture Support:**
```bash
# ARM Cortex-M4
./commands/hil-sil/sil-test.sh --binary firmware.elf --arch arm-cortex-m4 --mode qemu

# ARM Cortex-A53
./commands/hil-sil/sil-test.sh --binary firmware.elf --arch arm-cortex-a53 --mode qemu

# PowerPC e200
./commands/hil-sil/sil-test.sh --binary firmware.elf --arch powerpc-e200 --mode qemu
```

**GDB Debugging:**
```bash
# Start QEMU with GDB server
python3 tools/adapters/hil_sil/qemu_adapter.py --start --debug

# Connect GDB
gdb firmware.elf -ex 'target remote localhost:1234'
(gdb) break main
(gdb) continue
```

## Test Execution

### Test Automation Framework

**Test Suite Definition:**
```yaml
# tests/sil/bms_comprehensive.yaml
name: BMS Comprehensive Test Suite
version: 1.0.0

test_cases:
  - name: Battery Voltage Monitoring
    description: Validate cell voltage measurements
    steps:
      - set_voltage: {cell: 1, value: 3.7}
      - wait: 100ms
      - assert: {signal: "battery.cell1_voltage", value: 3.7, tolerance: 0.01}

  - name: Over-Voltage Protection
    description: Test OVP triggering
    steps:
      - set_voltage: {cell: 1, value: 4.3}
      - wait: 200ms
      - assert: {signal: "battery.ovp_active", value: true}
      - assert: {signal: "battery.contactor_open", value: true}

  - name: CAN Communication
    description: Validate CAN message transmission
    steps:
      - send_can: {id: 0x123, data: [0x01, 0x02, 0x03]}
      - wait: 50ms
      - expect_can: {id: 0x456, data: [0xAA, 0xBB]}
```

**Execution:**
```bash
python3 tests/automation/test_runner.py \
  --suite tests/sil/bms_comprehensive.yaml \
  --platform sil \
  --output results/ \
  --parallel 4
```

### Fault Injection

**Scenario Definition:**
```yaml
# tests/fault_injection/bms_can_loss.yaml
name: BMS CAN Communication Loss
fault_type: communication-loss
target_ecu: bms
injection_point:
  component: can_controller
  signal: CAN1
  time: 5.0  # seconds
  duration: 2.0  # seconds
expected_behavior:
  - signal: bms.can_error_flag
    value: true
    within: 100ms
  - signal: bms.safe_state_active
    value: true
    within: 500ms
```

**Execution:**
```bash
python3 tools/adapters/hil_sil/fault_injector.py \
  --scenario tests/fault_injection/bms_can_loss.yaml \
  --platform hil \
  --output results/fault_injection/
```

## Best Practices

### Test Design

1. **Test Independence:** Each test should be independently runnable
2. **Determinism:** Use fixed seeds for random number generators
3. **Coverage:** Aim for >80% code coverage on safety-critical code
4. **Traceability:** Link tests to requirements
5. **Documentation:** Document test objectives and expected results

### Code Coverage

```bash
# Compile with coverage flags
CFLAGS="-fprofile-arcs -ftest-coverage" make

# Run SIL tests
./commands/hil-sil/sil-test.sh --coverage

# Generate reports
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
firefox coverage_html/index.html
```

### Performance Optimization

**Parallel Execution:**
```bash
# Run tests in parallel (4 workers)
pytest tests/sil/ -n 4 --dist loadscope
```

**Caching:**
```python
# Cache compiled QEMU VMs
import hashlib

vm_hash = hashlib.sha256(binary_content).hexdigest()
cache_path = f"cache/vm_{vm_hash}.qcow2"

if os.path.exists(cache_path):
    qemu_adapter.load_cached_vm(cache_path)
else:
    qemu_adapter.create_vm()
    qemu_adapter.save_cache(cache_path)
```

### Safety & Compliance

**ISO 26262 Testing:**
```yaml
# tests/safety/iso26262_asil_d.yaml
safety_level: ASIL-D
requirements:
  - id: REQ-BMS-001
    description: Over-voltage protection shall trigger within 100ms
    test_cases: [ovp_timing_test, ovp_fault_injection]
    coverage: 100%

  - id: REQ-BMS-002
    description: Safe state shall open contactors
    test_cases: [safe_state_test, contactor_test]
    coverage: 100%
```

## Troubleshooting

### Common Issues

**Problem:** QEMU VM fails to boot
```bash
# Solution: Check binary format
file firmware.elf
# Expected: ELF 32-bit LSB executable, ARM, EABI5

# Check QEMU command
qemu-system-arm -M virt -cpu cortex-m4 -kernel firmware.elf -nographic -S -s
```

**Problem:** CAN interface not found
```bash
# Solution: Load vcan module
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Verify
ip link show vcan0
```

**Problem:** CARLA connection timeout
```bash
# Solution: Check CARLA server status
ps aux | grep CarlaUE4

# Restart CARLA server
./CarlaUE4.sh -quality-level=Low -RenderOffScreen -carla-rpc-port=2000

# Test connection
python3 -c "import carla; client = carla.Client('localhost', 2000); print(client.get_server_version())"
```

### Debugging Tips

**Enable Verbose Logging:**
```bash
export LOG_LEVEL=DEBUG
./commands/hil-sil/sil-test.sh --binary firmware.elf --arch arm-cortex-m4
```

**Save Execution Traces:**
```bash
# QEMU with execution trace
qemu-system-arm -d exec,cpu -D qemu_trace.log -kernel firmware.elf
```

**Network Traffic Analysis:**
```bash
# Capture CAN traffic
candump -L vcan0 > can_trace.log

# Analyze with can-utils
cansniffer vcan0
```

## Additional Resources

- **Skills:** `/skills/hil-sil/` - 75+ testing skills
- **Adapters:** `/tools/adapters/hil_sil/` - Platform adapters
- **Agents:** `/agents/testing/` - Specialist agents
- **Commands:** `/commands/hil-sil/` - Command-line tools
- **Examples:** `/examples/hil_sil/` - Example scenarios
- **Documentation:** `HIL_SIL_IMPLEMENTATION_SUMMARY.md`

## Support

For issues and questions:
1. Check troubleshooting section
2. Review example scenarios
3. Consult adapter source code
4. Contact test automation team

# Automotive Examples & Tutorials

Complete example projects demonstrating automotive software development with the Claude Code Agents platform.

## Overview

This directory contains production-ready examples across different automotive domains:

| Example | Domain | Complexity | Lines of Code | Key Technologies |
|---------|--------|------------|---------------|------------------|
| [BMS ECU](#bms-ecu) | Battery Management | High | 1500+ | AUTOSAR, C, Kalman Filter |
| [ADAS Perception](#adas-perception) | Autonomous Driving | High | 2000+ | YOLO, PointNet++, Python |
| [Battery Thermal](#battery-thermal) | Thermal Simulation | Medium | 800+ | PyBaMM, Physics-based |
| [CANoe Migration](#tool-migration) | Tool Migration | Low | - | Python-CAN, SocketCAN |

## Quick Start

```bash
# Clone repository
git clone https://github.com/your-org/automotive-claude-code-agents.git
cd automotive-claude-code-agents/examples

# Choose an example
cd ecu-bms

# Follow the README
cat README.md
```

## 1. BMS ECU Example

**Path**: `ecu-bms/`

### What You'll Learn
- AUTOSAR Classic architecture
- ISO 26262 safety requirements
- Real-time embedded C development
- Kalman filter implementation
- CAN communication
- Hardware abstraction

### Key Features
- ✓ 96-cell voltage monitoring
- ✓ Extended Kalman Filter for SOC
- ✓ Thermal management
- ✓ Safety state machine (ASIL-C)
- ✓ Complete build system
- ✓ 95% test coverage

### Quick Build

```bash
cd ecu-bms
make clean all test

# Output:
# - build/bms_ecu.elf (ARM binary)
# - build/test_runner (unit tests)
# - build/coverage_html/index.html (coverage report)
```

### Hardware Support
- STM32F407 (recommended)
- Any Cortex-M4 MCU
- Native x86 build for testing

**[Full Documentation →](ecu-bms/README.md)**

---

## 2. ADAS Perception Pipeline

**Path**: `adas-perception/`

### What You'll Learn
- Multi-sensor fusion (camera + LiDAR)
- Deep learning for perception
- Object detection and tracking
- CARLA simulator integration
- Real-time optimization

### Key Features
- ✓ YOLO v8 object detection
- ✓ PointNet++ point cloud segmentation
- ✓ Late fusion architecture
- ✓ Multi-object tracking (Kalman)
- ✓ 22 FPS on Jetson AGX Orin
- ✓ KITTI benchmark tested

### Quick Start

```bash
cd adas-perception

# Install dependencies
pip install -r requirements.txt

# Download models
./scripts/download_models.sh

# Run with sample data
python src/main.py \
    --input-video data/sample_video.mp4 \
    --output results/ \
    --visualize
```

### Performance

| Component | Latency | FPS |
|-----------|---------|-----|
| Camera (YOLO) | 15ms | 66 |
| LiDAR (PointNet++) | 25ms | 40 |
| Full Pipeline | 45ms | 22 |

**[Full Documentation →](adas-perception/README.md)**

---

## 3. Battery Thermal Simulation

**Path**: `battery-thermal/`

### What You'll Learn
- Electrochemical-thermal modeling
- PyBaMM framework
- Active cooling design
- Thermal runaway analysis
- Physics-based simulation

### Key Features
- ✓ Single cell thermal model
- ✓ Multi-cell pack with 3D heat transfer
- ✓ Active cooling (PID control)
- ✓ Drive cycle simulation
- ✓ Validated against experimental data

### Quick Start

```bash
cd battery-thermal

# Install PyBaMM
pip install pybamm

# Run simulation
python src/single_cell_thermal.py --chemistry LFP --current 1C

# Multi-cell pack
python src/pack_thermal.py --cells 96 --cooling liquid
```

### Output

- Temperature distribution over time
- Heat generation analysis
- Cooling system requirements
- Safety margin calculations

**[Full Documentation →](battery-thermal/README.md)**

---

## 4. Tool Migration Guides

**Path**: `tool-migration/`

### CANoe to SavvyCAN

**Save €15,000 per license** by migrating to open-source tools.

#### What's Covered
- Feature comparison
- Step-by-step migration
- CAPL to Python conversion
- Hardware alternatives
- Automated testing migration

#### Example Migration

**Before (CANoe CAPL)**:
```capl
on timer heartbeatTimer {
  message BMS_Heartbeat msg;
  msg.Status = 0x01;
  output(msg);
  setTimer(heartbeatTimer, 100);
}
```

**After (Python + python-can)**:
```python
import can

bus = can.Bus('can0', bustype='socketcan')
while True:
    msg = can.Message(id=0x100, data=[0x01])
    bus.send(msg)
    time.sleep(0.1)
```

**[Full Guide →](tool-migration/canoe-to-savvycan/README.md)**

### Other Migrations (Coming Soon)

- **Simulink → OpenModelica**: Model-based development
- **INCA → OpenXCP**: Calibration and measurement
- **CANalyzer → Wireshark**: Protocol analysis

---

## Example Comparison Matrix

### By Learning Objective

| Want to Learn... | Example | Difficulty |
|------------------|---------|------------|
| Embedded C | BMS ECU | ⭐⭐⭐ |
| AUTOSAR | BMS ECU | ⭐⭐⭐ |
| Deep Learning | ADAS Perception | ⭐⭐⭐ |
| Python | ADAS Perception, Battery Thermal | ⭐⭐ |
| CAN Communication | BMS ECU, Tool Migration | ⭐⭐ |
| Physics Simulation | Battery Thermal | ⭐⭐ |
| Tool Migration | CANoe to SavvyCAN | ⭐ |

### By Time Commitment

| Duration | Examples |
|----------|----------|
| 1-2 hours | Tool Migration guide |
| Half day | Battery Thermal single cell |
| 1-2 days | ADAS Perception basics |
| 1 week | BMS ECU complete |

### By Hardware Requirements

| Hardware | Examples |
|----------|----------|
| None (simulation) | All examples |
| CAN adapter ($30) | BMS ECU, Tool Migration |
| GPU (NVIDIA) | ADAS Perception |
| MCU Dev Board ($50) | BMS ECU (optional) |

---

## Prerequisites

### Common Dependencies

```bash
# Python
sudo apt-get install python3.9 python3-pip

# C/C++ Build Tools
sudo apt-get install build-essential cmake

# Git
sudo apt-get install git

# Optional: ARM Toolchain
sudo apt-get install gcc-arm-none-eabi
```

### Python Packages

```bash
# Core
pip install numpy scipy matplotlib

# Deep Learning
pip install torch torchvision ultralytics

# Battery Simulation
pip install pybamm

# CAN Communication
pip install python-can
```

---

## Testing the Examples

Each example includes comprehensive tests:

```bash
# BMS ECU
cd ecu-bms
make test                    # Unit tests
make hil-test                # Hardware-in-the-loop (requires hardware)

# ADAS Perception
cd adas-perception
pytest tests/                # All tests
pytest tests/test_camera.py  # Specific module

# Battery Thermal
cd battery-thermal
pytest tests/test_thermal_model.py
```

---

## Contributing

Want to add a new example? See our [contribution guide](../CONTRIBUTING.md).

### Example Submission Checklist

- [ ] README with clear learning objectives
- [ ] Complete, working code (no placeholders)
- [ ] Requirements file with pinned versions
- [ ] Unit tests (>80% coverage)
- [ ] Sample data or simulator integration
- [ ] Performance metrics documented
- [ ] Hardware requirements specified

---

## Troubleshooting

### Common Issues

**1. Build Errors (BMS ECU)**

```bash
# Missing ARM toolchain
sudo apt-get install gcc-arm-none-eabi binutils-arm-none-eabi

# Missing libraries
sudo apt-get install libusb-1.0-0-dev
```

**2. GPU Issues (ADAS Perception)**

```bash
# Check CUDA installation
nvidia-smi

# Install CUDA (if missing)
# Follow: https://developer.nvidia.com/cuda-downloads
```

**3. PyBaMM Installation (Battery Thermal)**

```bash
# Install system dependencies first
sudo apt-get install build-essential cmake gfortran libopenblas-dev

# Then install PyBaMM
pip install pybamm
```

**4. CAN Interface (Tool Migration)**

```bash
# Load kernel modules
sudo modprobe can can_raw vcan

# Create virtual interface
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

---

## Learning Path

### Beginner (No automotive experience)

1. Start with **Tool Migration** (understand CAN communication)
2. Try **Battery Thermal** (Python-based, good introduction)
3. Explore **ADAS Perception** (modern ML techniques)

### Intermediate (Some automotive knowledge)

1. **BMS ECU** (complete embedded project)
2. **ADAS Perception** (sensor fusion)
3. Combine multiple examples into a larger system

### Advanced (Automotive professional)

1. Extend **BMS ECU** with your own features
2. Optimize **ADAS Perception** for your hardware
3. Create a new example and contribute back

---

## Resources

### Automotive Standards
- **ISO 26262**: Functional Safety
- **AUTOSAR**: Software Architecture
- **ISO 15765**: CAN Transport Protocol
- **ISO 14229**: Unified Diagnostic Services (UDS)

### Tools & Frameworks
- **PyBaMM**: Battery modeling
- **CARLA**: Autonomous driving simulator
- **SavvyCAN**: CAN bus analysis
- **python-can**: CAN interface

### Tutorials
- [AUTOSAR Tutorial](https://www.youtube.com/watch?v=...)
- [Kalman Filter Explained](https://www.kalmanfilter.net/)
- [YOLO Object Detection](https://ultralytics.com/yolov8)

---

## Support & Community

- **GitHub Issues**: [Report bugs](https://github.com/your-org/automotive-agents/issues)
- **Discussions**: [Ask questions](https://github.com/your-org/automotive-agents/discussions)
- **Discord**: [Join community](https://discord.gg/...)
- **Office Hours**: Every Friday 3-4 PM UTC (Zoom link in Discord)

---

## License

All examples are licensed under MIT License unless otherwise specified.

See individual example directories for specific licenses.

---

## Acknowledgments

These examples were developed with contributions from:
- Automotive industry professionals
- Academic researchers
- Open-source community members

Special thanks to:
- PyBaMM developers
- CARLA team
- Ultralytics (YOLO)
- Linux SocketCAN maintainers

---

## Next Steps

1. **Choose an example** that matches your interests
2. **Follow the README** in that directory
3. **Complete the tutorial** step-by-step
4. **Modify and experiment** with the code
5. **Share your results** in GitHub Discussions

Happy learning! 🚗⚡

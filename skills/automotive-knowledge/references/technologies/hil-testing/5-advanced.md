# HIL Testing - Advanced Topics

## Virtual HIL (vHIL)

Virtual HIL eliminates dedicated hardware by running both ECU software and plant model on the same PC.

**Architecture**:
```
Standard PC (Windows/Linux)
├── Virtual ECU (Docker container, VM, or QEMU)
│   └── Production ECU software (cross-compiled for x86)
├── Plant Model (Simulink, C++ compiled for host)
└── Virtual I/O Bridge (software CAN, UDP sockets)
```

**Benefits**:
- Cost: €0 hardware (use existing PCs)
- Scalability: Spin up 100 vHIL instances for parallel testing
- CI/CD: Integrate into Jenkins, GitLab CI

**Limitations**:
- No real ECU hardware (misses HW-dependent bugs)
- Timing less accurate (soft real-time)
- Cannot test electrical characteristics (EMC, voltage drops)

**Tools**:
- Dymola Silver (FMI-based co-simulation)
- QEMU (ARM emulation for ECU code)
- Vector VT System (vHIL for AUTOSAR)

## Cloud-Based HIL

Deploy HIL rigs in cloud data center, access remotely.

**Use Cases**:
- Remote teams (test from home, different time zones)
- Resource sharing (expensive HIL rig shared across sites)
- Elastic scaling (spin up 50 rigs for release testing, shut down after)

**Implementation**:
```
Cloud (AWS, Azure, GCP)
├── HIL Rig (physical hardware in rack, remote-controlled)
│   ├── dSPACE SCALEXIO
│   └── ECU under test
├── VPN Gateway (secure access)
└── Remote Desktop (ControlDesk, automation scripts)

Engineer (Home Office)
└── VPN → RDP → Control HIL rig
```

**Challenges**:
- Network latency (affects interactive debugging)
- Physical access (flash ECU, change wiring)
- Security (protect ECU IP over network)

**Providers**:
- dSPACE Synect (cloud HIL orchestration)
- MathWorks SimulationManager (cloud-based Simulink execution)

## HIL in CI/CD Pipeline

Automate HIL testing on every code commit.

**Workflow**:
```
Developer commits code
    ↓
GitLab CI triggers pipeline
    ↓
Build ECU software (compile, link)
    ↓
Flash ECU via automated flasher (e.g., Segger J-Link script)
    ↓
Execute HIL test suite (AutomationDesk Python API)
    ↓
Collect results (JUnit XML, coverage report)
    ↓
Publish to dashboard (Grafana, Jenkins)
    ↓
Notify developer (pass/fail email, Slack)
```

**GitLab CI Config**:
```yaml
stages:
  - build
  - flash
  - test
  - report

build_ecu:
  stage: build
  script:
    - make clean
    - make release
  artifacts:
    paths:
      - build/ecu_firmware.hex

flash_ecu:
  stage: flash
  script:
    - jlink_flash.sh build/ecu_firmware.hex
  dependencies:
    - build_ecu

run_hil_tests:
  stage: test
  script:
    - python3 hil_automation/run_all_tests.py
  artifacts:
    reports:
      junit: test_results.xml

generate_report:
  stage: report
  script:
    - python3 generate_report.py
  artifacts:
    paths:
      - reports/hil_test_report.html
```

## Model Fidelity vs. Real-Time Tradeoffs

High-fidelity models may not run in real-time.

**Example: Tire Model**:
- Simple (fast): Linear slip-force relationship → 10 μs execution
- Medium (accurate): Magic Formula (empirical) → 100 μs
- High (research): FTire (detailed carcass model) → 10 ms (too slow!)

**Solution: Multi-Fidelity Approach**:
- Use high-fidelity offline (MIL, calibration)
- Use medium-fidelity in HIL (Magic Formula, real-time capable)
- Validate medium-fidelity against high-fidelity offline

**Code Generation Optimization**:
```matlab
% Simulink model optimization for real-time

% Use lookup tables instead of equations
% Replace:  y = a*x^3 + b*x^2 + c*x + d
% With:     y = lookup_table(x)  (pre-computed)

% Enable fixed-point arithmetic (faster than floating-point)
set_param(block, 'OutputDataType', 'fixdt(1,16,10)');

% Inline functions (reduce function call overhead)
set_param(block, 'InlineParameters', 'on');

% Enable compiler optimizations
set_param(model, 'OptimizationLevel', 'Maximum');
```

## Multi-ECU Co-Simulation

Test multiple ECUs together on same HIL rig.

**Scenario**: Powertrain + Body ECUs
```
HIL Simulator
├── Engine Model → CAN → Engine ECU (Real HW)
└── Vehicle Model → CAN → Body ECU (Real HW)
                        ↓
                  CAN bus interconnect
                  (both ECUs exchange messages)
```

**Challenges**:
- Increased I/O count (2x ECUs = 2x sensors/actuators)
- Synchronization (both ECUs must run in lockstep)
- Debugging (which ECU caused failure?)

**Best Practices**:
- Use central CAN logging (Vector CANalyzer records all traffic)
- Time-stamp all signals (correlate events)
- Test ECUs independently first, then integrate

**Tools**:
- dSPACE SYNECT (orchestrate multi-ECU HIL)
- ETAS LABCAR (large-scale multi-ECU)

## ADAS Sensor HIL (Camera/Radar Injection)

Test ADAS ECUs with virtual sensor data.

**Camera Injection**:
```
Synthetic Scene Generator (Unity, UE4, CARLA)
    ↓ Render 60 FPS video
Video Injector (dSPACE VSI, CAETEC VIDIS)
    ↓ GMSL2 or CSI-2 video stream
ADAS ECU Camera Input
```

**Radar Injection**:
```
Radar Target Simulator (Konrad Technologies, Keysight)
    ↓ RF signal (77 GHz)
ADAS ECU Radar Input
```

**Challenges**:
- High bandwidth (4K camera = 12 Gbps)
- Latency (camera processing delay)
- Cost (camera injector €100k+, radar injector €500k+)

**Alternative: Replay Recorded Data**:
```
Recorded camera frames (from vehicle test)
    ↓ Stored in ROS bag, MDF4
Playback in HIL
    ↓ Inject frame-by-frame
ADAS ECU processes
```

## Next Steps

Explore cutting-edge topics:
- Digital twin integration (HIL ↔ cloud twin)
- AI-driven test generation (ML generates edge-case scenarios)
- 5G-connected HIL (test V2X with real network)

## References

- dSPACE SYNECT Cloud Platform Documentation
- CARLA Simulator (open-source ADAS simulation)
- ISO 26262-6:2018 Clause 11: Integration and Verification

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Senior HIL engineers, researchers

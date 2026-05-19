# Complete Repository Guide

**Navigate the automotive-claude-code-agents repository like a pro**

---

## 📁 Repository Organization

### Directory Structure

```
automotive-claude-code-agents/
├── skills/                    # 80+ automotive skills
├── agents/                    # 22 specialized agents
├── docs/                      # Deliverable documents
├── README.md                  # Main overview
├── QUICK_START_EXAMPLES.md    # Top use cases
├── FINAL_STATISTICS.md        # Metrics
└── This file
```

---

## 🎯 Finding the Right Content

### By Your Role

**Embedded Software Engineer?**
→ `skills/automotive-ecu-systems/`
→ `skills/automotive-powertrain-chassis/`
→ Agents: `vehicle-systems-engineer`, `powertrain-control-engineer`

**ADAS Developer?**
→ `skills/automotive-adas/`
→ `skills/automotive-ai-ecu/`
→ Agents: `adas-perception-engineer`, `edge-ai-engineer`

**Safety Engineer?**
→ `skills/automotive-safety/`
→ Agents: `safety-engineer`, `safety-assessor`

**Security Engineer?**
→ `skills/automotive-cybersecurity/`
→ Agents: `automotive-security-architect`, `penetration-tester`

**System Architect?**
→ `skills/automotive-hpc/`
→ `skills/automotive-zonal/`
→ `skills/automotive-sdv/`
→ Agents: `hpc-platform-architect`, `zonal-architect`, `sdv-platform-engineer`

---

## 📚 All Skills Reference

### ADAS (7 skills)
1. `sensor-fusion-perception.md` - Multi-sensor Kalman filters
2. `camera-processing-vision.md` - YOLO, lane detection
3. `radar-lidar-processing.md` - Point cloud, SLAM
4. `path-planning-control.md` - A*, RRT, MPC
5. `adas-features-implementation.md` - ACC, LKA, AEB
6. `hd-maps-localization.md` - Lanelet2, GPS/IMU fusion
7. `autosar-adas-integration.md` - AUTOSAR for ADAS

### AI-ECU (5 skills)
1. `edge-ai-deployment.md` - NPU deployment, quantization
2. `neural-processing-units.md` - Qualcomm, NXP, Renesas
3. `camera-vision-ai.md` - Object detection pipelines
4. `driver-monitoring-systems.md` - DMS, gaze tracking
5. `voice-nlu-automotive.md` - Wake word, ASR, NLU

### Cybersecurity (6 skills)
1. `iso-21434-compliance.md` - TARA, cybersecurity lifecycle
2. `secure-boot-chain.md` - HAB, anti-rollback
3. `vehicle-pki-crypto.md` - IEEE 1609.2, HSM
4. `intrusion-detection-prevention.md` - CAN IDS, SIEM
5. `penetration-testing-automotive.md` - CAN fuzzing, exploits
6. `secure-software-development.md` - MISRA, static analysis

### Diagnostics (8 skills)
1. `uds-iso14229-protocol.md` - Complete UDS client
2. `obd-ii-standards.md` - OBD-II scanner
3. `dtc-management.md` - Fault codes
4. `doip-ethernet-diagnostics.md` - DoIP over Ethernet
5. `odx-diagnostic-databases.md` - ODX parser
6. `flash-reprogramming.md` - ECU flash programmer
7. `diagnostic-tooling.md` - CANoe, python-can
8. `README.md` - Quick reference

### Functional Safety (7 skills)
1. `iso-26262-overview.md` - Standard overview
2. `hazard-analysis-risk-assessment.md` - HARA methodology
3. `safety-mechanisms-patterns.md` - Redundancy, watchdogs
4. `fmea-fta-analysis.md` - Failure analysis
5. `software-safety-requirements.md` - ASIL-D software
6. `safety-verification-validation.md` - V&V, HIL testing
7. `README.md` - Quick reference

### HPC (5 skills)
1. `hypervisor-virtualization.md` - QNX, ACRN, Xen
2. `autosar-adaptive.md` - Adaptive Platform R22-11
3. `vehicle-compute-platforms.md` - NVIDIA, Qualcomm, NXP
4. `containerization-orchestration.md` - Docker, K3s
5. `safety-certification-hpc.md` - ISO 26262 for HPC

### ML/Analytics (7 skills)
1. `anomaly-detection.md` - Isolation Forest, LSTM
2. `predictive-maintenance.md` - Battery SOH, tire wear
3. `time-series-forecasting.md` - Prophet, ARIMA
4. `fleet-analytics.md` - Dashboards, KPIs
5. `driver-behavior-analysis.md` - Safety scoring
6. `energy-optimization.md` - Route optimization, DQN
7. `README.md` - Quick reference

### Powertrain/Chassis (7 skills)
1. `ecm-engine-control.md` - Fuel injection, emissions
2. `tcm-transmission-control.md` - Shift strategies
3. `esc-stability-control.md` - Yaw control, TCS
4. `eps-steering-systems.md` - Assist torque, FOC
5. `abs-brake-systems.md` - Wheel slip, ABS
6. `suspension-control.md` - Active damping
7. `vehicle-dynamics-integration.md` - Torque vectoring

### SDV Platform (6 skills)
1. `ota-update-systems.md` - Uptane, A/B partitioning
2. `vehicle-app-stores.md` - App platform, sandbox
3. `cloud-vehicle-integration.md` - MQTT, AWS IoT
4. `digital-twin-vehicles.md` - Simulation, sync
5. `containerized-vehicle-apps.md` - containerd, K3s
6. `vehicle-middleware-platforms.md` - VSS, VISS, Kuksa

### V2X (6 skills)
1. `v2x-protocols-standards.md` - DSRC vs C-V2X, SAE J2735
2. `v2v-safety-applications.md` - EEBL, FCW, platooning
3. `v2i-infrastructure.md` - RSU, SPaT, MAP
4. `v2x-security-certificates.md` - IEEE 1609.2, SCMS
5. `cv2x-5g-integration.md` - 5G NR, network slicing
6. `v2x-testing-simulation.md` - CARLA, SUMO, NS-3

### Vehicle ECUs (9 skills)
1. `vcu-vehicle-control.md` - Torque arbitration, drive modes
2. `vgu-gateway-architecture.md` - Network routing, firewall
3. `tcu-telematics-connectivity.md` - 4G/5G, GPS, eCall
4. `bcm-body-control.md` - Lighting, keyless entry
5. `ivi-infotainment-systems.md` - Android Auto, navigation
6. `bms-battery-management.md` - SOC/SOH, cell balancing
7. `pdu-power-distribution.md` - DC/DC, load shedding
8. `domain-controller-integration.md` - Chassis, powertrain domains
9. Plus supporting skills

### Zonal Architecture (6 skills)
1. `zonal-architecture-design.md` - Zone placement, topology
2. `automotive-ethernet.md` - TSN, AVB, 100BASE-T1
3. `service-oriented-communication.md` - SOME/IP, DDS
4. `zone-controller-development.md` - Firmware, I/O handling
5. `network-security-zonal.md` - MACsec, IPsec, firewall
6. `README.md` - Quick reference

---

## 🤖 All Agents Reference

### ADAS Domain
- `adas-perception-engineer` - Sensor fusion, object tracking
- `autonomous-systems-architect` - L3-L5 autonomy

### AI-ECU Domain
- `edge-ai-engineer` - NPU deployment, quantization
- `vision-ai-specialist` - Camera pipelines, perception

### Cybersecurity Domain
- `automotive-security-architect` - ISO 21434, TARA
- `penetration-tester` - Ethical hacking, CAN fuzzing

### Diagnostics Domain
- `diagnostic-tester` - Test automation, EOL testing

### Functional Safety Domain
- `safety-engineer` - HARA, FMEA, safety concepts
- `safety-assessor` - Independent assessment, audits

### HPC Domain
- `hpc-platform-architect` - Hypervisor selection, partitioning
- `autosar-adaptive-developer` - ara::com implementation

### ML/Analytics Domain
- `predictive-maintenance-engineer` - Failure prediction models
- `fleet-analytics-specialist` - Dashboards, KPIs

### Powertrain/Chassis Domain
- `powertrain-control-engineer` - ECM/TCM development
- `chassis-systems-engineer` - ESC/ABS/EPS algorithms

### SDV Platform Domain
- `sdv-platform-engineer` - OTA, containerization
- `vehicle-cloud-architect` - Cloud integration, digital twins

### V2X Domain
- `v2x-system-engineer` - DSRC/C-V2X, RSU deployment
- (Security handled by cybersecurity agents)

### Vehicle Systems Domain
- `vehicle-systems-engineer` - VCU/VGU/TCU/BCM
- `ev-systems-specialist` - BMS, charging, high-voltage

### Zonal Architecture Domain
- `zonal-architect` - E/E architecture design
- `ethernet-network-engineer` - TSN configuration, QoS

---

## 📖 Deliverable Documents

27 comprehensive summary documents:

- **ADAS_DELIVERABLES.md** - L0-L5 reference architectures
- **AI_ECU_DELIVERABLES.md** - Edge AI deployment guide
- **CYBERSECURITY_DELIVERABLES.md** - ISO 21434 compliance
- **FUNCTIONAL_SAFETY_DELIVERABLES.md** - ISO 26262 guide
- **HPC_DELIVERABLES.md** - Central compute platforms
- **ML_ANALYTICS_DELIVERABLES.md** - Predictive analytics
- **POWERTRAIN_CHASSIS_DELIVERABLES.md** - Control systems
- **SDV_DELIVERABLES.md** - Software-defined vehicles
- **V2X_DELIVERABLES.md** - Vehicle communication
- **VEHICLE_SYSTEMS_DELIVERABLES.md** - ECU development
- **ZONAL_DELIVERABLES.md** - Next-gen E/E architecture
- Plus 16 more domain-specific docs

---

## 🔍 Search Tips

**Finding Skills by Technology:**
- CAN/LIN: Check diagnostics, protocols, vehicle-systems
- Ethernet: Zonal, V2X, diagnostics (DoIP)
- AI/ML: AI-ECU, ML/Analytics, ADAS (perception)
- AUTOSAR: HPC (Adaptive), vehicle-systems (Classic)
- Safety: Functional-safety, cybersecurity
- Cloud: SDV, ML/Analytics

**Finding Skills by Standard:**
- ISO 26262: `automotive-safety/`
- ISO 21434: `automotive-cybersecurity/`
- SAE J2735: `automotive-v2x/`
- ISO 14229 (UDS): `automotive-diagnostics/`
- IEEE 1609.2: `automotive-v2x/v2x-security-certificates`

---

## 💡 Learning Paths

### Path 1: Embedded Automotive Developer
1. Start: `automotive-protocols/README`
2. Then: `automotive-ecu-systems/bcm-body-control`
3. Then: `automotive-diagnostics/uds-iso14229-protocol`
4. Advanced: `automotive-safety/iso-26262-overview`

### Path 2: ADAS Engineer
1. Start: `automotive-adas/camera-processing-vision`
2. Then: `automotive-adas/sensor-fusion-perception`
3. Then: `automotive-ai-ecu/edge-ai-deployment`
4. Advanced: `automotive-adas/path-planning-control`

### Path 3: System Architect
1. Start: `automotive-zonal/zonal-architecture-design`
2. Then: `automotive-hpc/hypervisor-virtualization`
3. Then: `automotive-sdv/ota-update-systems`
4. Advanced: `automotive-safety/fmea-fta-analysis`

---

## 🎯 Quick Reference Tables

### By Development Phase

| Phase | Relevant Skills |
|-------|----------------|
| Requirements | safety/hara, v2x/protocols |
| Architecture | zonal/design, hpc/platforms |
| Design | adas/planning, ecu-systems/vcu |
| Implementation | All domain skills |
| Testing | diagnostics/*, safety/v&v |
| Integration | zonal/soa, hpc/autosar |
| Validation | adas/features, safety/fmea |

### By ASIL Level

| ASIL | Focus Areas |
|------|-------------|
| QM | ecu-systems/ivi, sdv/app-stores |
| ASIL-A | ecu-systems/bcm, v2x/v2i |
| ASIL-B | adas/lka, ai-ecu/dms |
| ASIL-C | powertrain/esc, adas/aeb |
| ASIL-D | safety/*, powertrain/eps, adas/planning |

---

This guide helps you navigate the 80+ skills and 22 agents. Start with Quick Start Examples for hands-on learning!

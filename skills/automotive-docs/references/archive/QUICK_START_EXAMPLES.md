# Quick Start Examples

**Top 10 real-world use cases with complete code**

---

## 1. Build L2 ADAS Perception System

**Goal**: Camera + Radar fusion for lane keeping and adaptive cruise control

```bash
claude "Using adas-perception-engineer agent and these skills:
- automotive-adas/sensor-fusion-perception
- automotive-adas/camera-processing-vision
- automotive-adas/radar-lidar-processing

Create a production-ready sensor fusion system with:
1. Camera lane detection (Hough transform + YOLO)
2. 77 GHz radar object tracking (Kalman filter)
3. Sensor fusion (early fusion with time sync)
4. ROS 2 integration for HIL testing
"
```

**What You Get**:
- Complete C++ sensor fusion pipeline
- Python YOLO inference code
- Kalman filter implementation
- ROS2 nodes and launch files
- Performance benchmarks (30 FPS, <50ms latency)

**Time Saved**: 3-4 weeks → 3-5 days

---

## 2. Implement ISO 26262 ASIL-D Safety

**Goal**: Complete HARA and safety concept for brake-by-wire system

```bash
claude "Using safety-engineer agent and these skills:
- automotive-safety/hazard-analysis-risk-assessment
- automotive-safety/fmea-fta-analysis
- automotive-safety/safety-mechanisms-patterns

Perform HARA for brake-by-wire system and create:
1. Hazard identification for all driving scenarios
2. ASIL determination (S/E/C classification)
3. FMEA with 99% diagnostic coverage
4. Safety mechanisms (dual redundancy, watchdogs)
"
```

**What You Get**:
- HARA worksheet with 15+ hazardous events
- ASIL assignments (mostly ASIL-D)
- Complete FMEA spreadsheet
- C code for safety mechanisms
- Fault tree analysis

**Time Saved**: 2-3 weeks → 2-3 days

---

## 3. Design Zonal E/E Architecture

**Goal**: Migrate from domain to zonal architecture (6 zones)

```bash
claude "Using zonal-architect agent and these skills:
- automotive-zonal/zonal-architecture-design
- automotive-zonal/automotive-ethernet
- automotive-zonal/service-oriented-communication

Design 6-zone architecture for electric SUV:
1. Zone controller placement (minimize cable length)
2. Ethernet TSN backbone (star topology)
3. SOME/IP service definitions
4. Cable harness reduction analysis
"
```

**What You Get**:
- Zone placement diagram with 6 controllers
- Ethernet switch configuration (TSN, VLAN, QoS)
- SOME/IP Franca IDL service definitions
- Cable reduction report (30% savings, $110/vehicle)
- Migration roadmap (3 phases, 18-36 months)

**Time Saved**: 4-6 weeks → 1-2 weeks

---

## 4. Deploy YOLO to Automotive NPU

**Goal**: Optimize YOLOv5 for Qualcomm NPU 5000 with INT8

```bash
claude "Using edge-ai-engineer agent and these skills:
- automotive-ai-ecu/edge-ai-deployment
- automotive-ai-ecu/neural-processing-units
- automotive-ai-ecu/camera-vision-ai

Deploy YOLOv5 object detection to Qualcomm NPU:
1. Convert PyTorch → ONNX → SNPE
2. INT8 quantization with calibration dataset
3. Multi-camera batching (4 cameras)
4. Power management (DVFS)
"
```

**What You Get**:
- Complete conversion pipeline (Python scripts)
- Quantization calibration code
- SNPE deployment configuration
- C++ inference engine with batching
- Benchmarks (45 FPS, 18ms latency, 4.5W power)

**Time Saved**: 2-3 weeks → 3-5 days

---

## 5. Build Secure OTA Update System

**Goal**: Uptane-compliant OTA with A/B partitioning

```bash
claude "Using sdv-platform-engineer agent and these skills:
- automotive-sdv/ota-update-systems
- automotive-cybersecurity/secure-boot-chain

Create secure OTA update system:
1. Uptane client (Python)
2. A/B partition bootloader (U-Boot)
3. Differential updates (bsdiff)
4. Rollback protection
5. Secure boot integration
"
```

**What You Get**:
- Uptane client (400+ lines Python)
- U-Boot partition switching config
- Delta update generation script
- Secure boot chain (RSA-2048)
- Rollback counter implementation

**Time Saved**: 3-4 weeks → 1 week

---

## 6. Implement UDS Diagnostic Services

**Goal**: Complete UDS client with security access

```bash
claude "Using automotive-diagnostics/uds-iso14229-protocol,
create UDS diagnostic client:

1. Session control (0x10)
2. Security access with seed-key (0x27)
3. Read DTC (0x19)
4. Read/Write data by ID (0x22/0x2E)
5. Routine control (0x31)
6. Flash programming (0x34-0x37)
"
```

**What You Get**:
- Complete UDS client (Python, 600+ lines)
- ISO-TP transport layer
- Security access seed-key algorithm
- DTC decoder (P/C/B/U codes)
- Flash programmer with Intel HEX parser

**Time Saved**: 2-3 weeks → 1-2 days

---

## 7. Create V2X Platooning System

**Goal**: C-V2X platooning with <0.5s headway

```bash
claude "Using v2x-system-engineer agent and these skills:
- automotive-v2x/v2v-safety-applications
- automotive-v2x/v2x-protocols-standards
- automotive-v2x/v2x-security-certificates

Implement C-V2X truck platooning:
1. BSM broadcaster (10 Hz, SAE J2735)
2. CACC controller (string-stable)
3. IEEE 1609.2 secure messaging
4. Safety fallback (leader lost → increase gap)
"
```

**What You Get**:
- SAE J2735 ASN.1 encoder/decoder
- CACC algorithm (C code)
- IEEE 1609.2 message signing
- Safety FSM with fallback modes
- Fuel savings calculator (10-15% reduction)

**Time Saved**: 3-4 weeks → 1 week

---

## 8. Develop BMS with SOC Estimation

**Goal**: Battery management for EV with Kalman filter SOC

```bash
claude "Using ev-systems-specialist agent and these skills:
- automotive-ecu-systems/bms-battery-management
- automotive-ml/predictive-maintenance

Create BMS for 400V lithium-ion pack:
1. Cell voltage monitoring (LTC6811 AFE)
2. SOC estimation (Coulomb counting + EKF fusion)
3. SOH estimation (capacity fade tracking)
4. Cell balancing (passive, resistor-based)
5. ISO 26262 ASIL-D safety
"
```

**What You Get**:
- LTC6811 SPI driver (C code)
- Extended Kalman Filter for SOC (C)
- SOH estimator with aging model
- Cell balancing algorithm
- Safety mechanisms (dual redundancy, plausibility checks)

**Time Saved**: 2-3 weeks → 4-6 days

---

## 9. Configure TSN Ethernet Network

**Goal**: Time-Sensitive Networking for zonal architecture

```bash
claude "Using ethernet-network-engineer agent and these skills:
- automotive-zonal/automotive-ethernet
- automotive-zonal/service-oriented-communication

Configure Ethernet TSN network:
1. 802.1Qbv Time-Aware Shaper (1ms cycle)
2. 802.1AS gPTP time sync (<500ns accuracy)
3. VLAN segmentation (6 security domains)
4. QoS with 8 priority levels
5. NXP SJA1110 switch configuration
"
```

**What You Get**:
- TSN schedule configuration (YAML)
- gPTP domain configuration
- VLAN table with priority mapping
- Switch register configuration (C code)
- Latency budget analysis (<5ms p99)

**Time Saved**: 2-3 weeks → 3-5 days

---

## 10. Build Fleet Analytics Dashboard

**Goal**: Real-time fleet monitoring with predictive maintenance

```bash
claude "Using fleet-analytics-specialist agent and these skills:
- automotive-ml/fleet-analytics
- automotive-ml/predictive-maintenance
- automotive-sdv/cloud-vehicle-integration

Create fleet analytics platform:
1. MQTT telemetry ingestion (AWS IoT Core)
2. Kafka stream processing
3. LightGBM predictive models (battery SOH, tire wear)
4. Streamlit dashboard (13 KPIs)
5. Automated alerts
"
```

**What You Get**:
- MQTT telemetry client (Python)
- Kafka consumer for stream processing
- LightGBM models with 90%+ accuracy
- Streamlit dashboard (production-ready)
- Grafana integration configs

**Time Saved**: 3-4 weeks → 1 week

---

## 🎯 Common Workflow Patterns

### Pattern 1: Research → Design → Implement

```bash
# Step 1: Research with agent
claude "Use autonomous-systems-architect to research L4 autonomy architecture"

# Step 2: Design with specific skills
claude "Using automotive-adas/path-planning-control, design hybrid A* planner"

# Step 3: Implement with code generation
claude "Generate production C++ code for hybrid A* with ROS 2 integration"
```

### Pattern 2: Standard Compliance

```bash
# ISO 26262 compliance
claude "Using safety-engineer agent, create safety case for AEB system
compliant with ISO 26262 ASIL-C requirements"

# ISO 21434 compliance
claude "Using automotive-security-architect, perform TARA for TCU
according to ISO 21434 Annex G"
```

### Pattern 3: Hardware Integration

```bash
# NPU deployment
claude "Using edge-ai-engineer, deploy model to NXP i.MX 8M Plus eIQ
with TFLite delegate and INT8 quantization"

# MCU firmware
claude "Using vehicle-systems-engineer, create VCU firmware for
NXP S32K344 with AUTOSAR MCAL integration"
```

---

## 💡 Tips for Success

1. **Be Specific**: Include hardware platforms, standards, performance targets
2. **Combine Skills**: Use multiple skills for complex tasks
3. **Use Agents**: Agents provide expert workflows and best practices
4. **Iterate**: Start simple, then add complexity
5. **Reference Examples**: Point to deliverable docs for more context

---

## 🚀 Next Steps

After completing quick start examples:

1. Read [COMPLETE_REPOSITORY_GUIDE.md](COMPLETE_REPOSITORY_GUIDE.md) for full navigation
2. Explore domain-specific deliverables for deep dives
3. Check [FINAL_STATISTICS.md](FINAL_STATISTICS.md) for comprehensive metrics
4. Contribute your own use cases and improvements!

---

**Happy building! Each example saves 70-90% development time.** ⚡

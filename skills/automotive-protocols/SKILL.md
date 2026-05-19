---
name: automotive-protocols
description: >
  Expert skill in BroadR-Reach automotive Ethernet physical layer (100BASE-T1) for cost-effective high-speed networking over single twisted pair. Covers 8 topics across automotive-protocols domain.
tags: [automotive, automotive-protocols]
---

# Automotive Protocols

8 skill files covering automotive-protocols domain.

## Applicable Standards

- AEC-Q100 (Automotive component qualification)
- ANSI/TIA/EIA-644-A (LVDS Standard)
- ASPICE Level 3
- AUTOSAR 4.4
- AUTOSAR LIN Driver
- Automotive EMC compliance
- BroadR-Reach specification
- FPD-Link (Flat Panel Display Link)
- IEEE 1722 AVTP (Audio Video Transport Protocol)
- IEEE 802.1 AVB (Audio Video Bridging)
- IEEE 802.1 TSN (Time-Sensitive Networking)
- IEEE 802.3bw (100BASE-T1)
- ISO 14230 (KWP2000 over MOST)
- ISO 17458 (FlexRay Communications System)
- ISO 17987 (LIN Specification)
- ISO 26262 (Functional Safety)
- ISO 26262 ASIL-D (Functional Safety)
- LIN 2.2A specification
- MIPI CSI-2 (Camera Serial Interface)
- MOST Cooperation standard
- MOST Specification Rev. 3.0
- MOST150 (150 Mbps)
- OPEN Alliance TC1 specification
- OPEN Alliance TC8 specification
- OpenLDI (Open LVDS Display Interface)
- PSI5 Specification v2.3
- SAE J2602
- SAE J2716 (SENT Specification)
- SOME/IP (Scalable service-Oriented MiddlewarE)

## Instructions

## BroadR-Reach Protocol

## Core Competencies

Expert in BroadR-Reach physical layer for automotive Ethernet over single twisted pair.

### Physical Layer Characteristics
- Single unshielded twisted pair (UTP)
- 100 Mbps full-duplex bidirectional
- Cable length up to 15 meters (50 feet)
- Voltage range: -2V to +2V differential
- PAM3 (3-level Pulse Amplitude Modulation) encoding
- Frequency: 33.33 MHz fundamental

### Cable Requirements
- Unshielded twisted pair (UTP)
- AWG 24-26 gauge typical
- Impedance: 100 ohms ±15%
- Capacitance: <60 pF/m
- Low crosstalk for bundled cables
- Automotive temperature range (-40°C to +125°C)

### PHY Features
- Auto-negotiation (ANEG)
- Link partner detection
- Cable diagnostics (TDR - Time Domain Reflectometry)
- Sleep/wake functionality
- EMI/EMC compliance for automotive
- Power over Data Line (PoDL) support

### Connector Types
- FAKRA coaxial connector (legacy)
- USCAR connector
- Rosenberger HFM connector
- Amphenol Mini50 connector
- Automotive-grade shielding

## Design Approach

1. Physical Layer Design
   - Select appropriate cable type
   - Plan cable routing (avoid EMI sources)
   - Calculate maximum cable length
   - Choose connectors and terminations

2. PHY Configuration
   - Configure auto-negotiation
   - Set master/slave mode
   - Enable cable diagnostics
   - Configure sleep/wake behavior

3. EMC/EMI Mitigation
   - Proper grounding strategy
   - Common-mode choke selection
   - Cable shielding and routing
   - Ferrite bead placement

4. Validation and Testing
   - Eye diagram analysis
   - TDR cable verification
   - EMC compliance testing
   - Temperature stress testing

## Implementation Examples

### PHY Initialization
```c
// BroadR-Reach PHY configuration
typedef struct {
    uint8_t phyAddress;        // MDIO address (0-31)
    bool masterMode;           // Master/slave mode
    bool autoNegEnable;        // Auto-negotiation
    bool sleepEnable;          // Sleep mode support
    uint8_t ledMode;           // LED indicator config
} BRR_PhyConfig_t;

void BRR_InitPhy(const BRR_PhyConfig_t* config) {
    // Software reset
    BRR_MdioWrite(config->phyAddress, PHY_BASIC_CONTROL, PHY_RESET);

    // Wait for reset complete
    while (BRR_MdioRead(config->phyAddress, PHY_BASIC_CONTROL) & PHY_RESET);

    // Configure basic control register
    uint16_t bcr = 0;
    if (config->autoNegEnable) {
        bcr |= PHY_AUTONEG_ENABLE | PHY_RESTART_AUTONEG;
    }
    bcr |= PHY_FULL_DUPLEX | PHY_SPEED_100M;

    BRR_MdioWrite(config->phyAddress, PHY_BASIC_CONTROL, bcr);

    // Configure master/slave mode
    uint16_t msCfg = BRR_MdioRead(
        config->phyAddress,
        PHY_MASTER_SLAVE_CONTROL
    );

    if (config->masterMode) {
        msCfg |= PHY_MASTER_MODE;
    } else {
        msCfg &= ~PHY_MASTER_MODE;
    }

    BRR_MdioWrite(config->phyAddress, PHY_MASTER_SLAVE_CONTROL, msCfg);

    // Configure sleep mode
    if (config->sleepEnable) {
        uint16_t sleepReg = BRR_MdioRead(
            config->phyAddress,
            PHY_SLEEP_CONTROL
        );
        sleepReg |= PHY_SLEEP_ENABLE;
        BRR_MdioWrite(config->phyAddress, PHY_SLEEP_CONTROL, sleepReg);
    }

    // Configure LED indicators
    BRR_MdioWrite(config->phyAddress, PHY_LED_CONTROL, config->ledMode);
}
```

### Link Status Monitoring
```c
// Monitor link status and cable health
typedef struct {
    bool linkUp;
    bool masterMode;
    uint16_t linkSpeed;        // Mbps
    bool fullDuplex;
    uint16_t cableLength;      // Estimated meters
    bool cableFault;
} BRR_LinkStatus_t;

BRR_LinkStatus_t BRR_GetLinkStatus(uint8_t phyAddress) {
    BRR_LinkStatus_t status = {0};

    // Read basic status register
    uint16_t bsr = BRR_MdioRead(phyAddress, PHY_BASIC_STATUS);

    status.linkUp = (bsr & PHY_LINK_STATUS) != 0;

    if (status.linkUp) {
        // Read master/slave status
        uint16_t msStatus = BRR_MdioRead(
            phyAddress,
            PHY_MASTER_SLAVE_STATUS
        );
        status.masterMode = (msStatus & PHY_MASTER_STATUS) != 0;

        // Link speed is always 100 Mbps for BroadR-Reach
        status.linkSpeed = 100;
        status.fullDuplex = true;

        // Estimate cable length via TDR
        status.cableLength = BRR_EstimateCableLength(phyAddress);

        // Check for cable faults
        status.cableFault = BRR_CheckCableFault(phyAddress);
    }

    return status;
}
```

### Cable Diagnostics (TDR)
```c
// Time Domain Reflectometry for cable diagnostics
typedef enum {
    CABLE_OK,
    CABLE_OPEN,
    CABLE_SHORT,
    CABLE_CROSSTALK,
    CABLE_IMPEDANCE_MISMATCH
} BRR_CableFault_t;

BRR_CableFault_t BRR_RunCableDiagnostics(uint8_t phyAddress) {
    // Trigger TDR test
    uint16_t tdrCtrl = BRR_MdioRead(phyAddress, PHY_TDR_CONTROL);
    tdrCtrl |= PHY_TDR_START;
    BRR_MdioWrite(phyAddress, PHY_TDR_CONTROL, tdrCtrl);

    // Wait for completion (typically <1ms)
    uint32_t timeout = 1000;  // 1ms timeout
    while (timeout--) {
        tdrCtrl = BRR_MdioRead(phyAddress, PHY_TDR_CONTROL);
        if (!(tdrCtrl & PHY_TDR_START)) {
            break;
        }
        DelayUs(1);
    }

    // Read TDR result
    uint16_t tdrResult = BRR_MdioRead(phyAddress, PHY_TDR_RESULT);

    // Parse fault type
    uint8_t faultType = (tdrResult >> 12) & 0x0F;

    switch (faultType) {
        case 0x0: return CABLE_OK;
        case 0x1: return CABLE_OPEN;
        case 0x2: return CABLE_SHORT;
        case 0x3: return CABLE_CROSSTALK;
        case 0x4: return CABLE_IMPEDANCE_MISMATCH;
        default:  return CABLE_OK;
    }
}

uint16_t BRR_EstimateCableLength(uint8_t phyAddress) {
    // Read TDR distance measurement
    uint16_t tdrDistance = BRR_MdioRead(phyAddress, PHY_TDR_DISTANCE);

    // Convert to meters (formula vendor-specific)
    // Typical: distance_m = (tdr_value * 0.1)
    uint16_t lengthMeters = (tdrDistance * 10) / 100;

    return lengthMeters;
}
```

### Sleep/Wake Functionality
```c
// Enter sleep mode for power saving
void BRR_EnterSleepMode(uint8_t phyAddress) {
    // Send sleep request
    uint16_t sleepCtrl = BRR_MdioRead(phyAddress, PHY_SLEEP_CONTROL);
    sleepCtrl |= PHY_SLEEP_REQUEST;
    BRR_MdioWrite(phyAddress, PHY_SLEEP_CONTROL, sleepCtrl);

    // Wait for sleep acknowledge
    uint32_t timeout = 10000;  // 10ms
    while (timeout--) {
        sleepCtrl = BRR_MdioRead(phyAddress, PHY_SLEEP_CONTROL);
        if (sleepCtrl & PHY_SLEEP_ACK) {
            break;
        }
        DelayUs(1);
    }

    LogInfo("PHY entered sleep mode");
}

// Wake from sleep mode
void BRR_WakeFromSleep(uint8_t phyAddress) {
    // Method 1: Send wake pulse on MDC line
    BRR_SendWakePulse();

    // Method 2: Toggle PHY_WAKE pin (if available)
    // GPIO_SetPin(PHY_WAKE_PIN, HIGH);
    // DelayUs(100);
    // GPIO_SetPin(PHY_WAKE_PIN, LOW);

    // Wait for link to re-establish
    uint32_t timeout = 100000;  // 100ms
    while (timeout--) {
        uint16_t bsr = BRR_MdioRead(phyAddress, PHY_BASIC_STATUS);
        if (bsr & PHY_LINK_STATUS) {
            break;
        }
        DelayUs(1);
    }

    LogInfo("PHY woke from sleep mode");
}
```

### EMC/EMI Configuration
```c
// Configure EMI reduction features
void BRR_ConfigureEMI(uint8_t phyAddress) {
    // Enable spread spectrum clocking for EMI reduction
    uint16_t emiCtrl = BRR_MdioRead(phyAddress, PHY_EMI_CONTROL);

    emiCtrl |= PHY_SSC_ENABLE;           // Spread spectrum enable
    emiCtrl |= PHY_SLEW_RATE_LIMIT;      // Limit slew rate
    emiCtrl |= PHY_COMMON_MODE_FILTER;   // Enable CM filter

    BRR_MdioWrite(phyAddress, PHY_EMI_CONTROL, emiCtrl);

    // Configure output driver strength (reduce overshoot)
    uint16_t driverCfg = BRR_MdioRead(phyAddress, PHY_DRIVER_CONTROL);
    driverCfg &= ~PHY_DRIVER_STRENGTH_MASK;
    driverCfg |= PHY_DRIVER_STRENGTH_MEDIUM;  // Medium strength
    BRR_MdioWrite(phyAddress, PHY_DRIVER_CONTROL, driverCfg);
}
```

### Power over Data Line (PoDL) Configuration
```c
// Configure PoDL for powered devices (e.g., cameras)
typedef struct {
    bool enable;
    uint8_t powerClass;        // 0-8 (IEEE 802.3bu)
    uint16_t maxPowerMw;       // Maximum power in mW
} BRR_PoDL_Config_t;

void BRR_ConfigurePoDL(uint8_t phyAddress, const BRR_PoDL_Config_t* cfg) {
    if (!cfg->enable) {
        // Disable PoDL
        BRR_MdioWrite(phyAddress, PHY_PODL_CONTROL, 0);
        return;
    }

    // Configure PoDL PSE (Power Sourcing Equipment)
    uint16_t podlCtrl = 0;
    podlCtrl |= PHY_PODL_ENABLE;
    podlCtrl |= (cfg->powerClass << 8) & PHY_PODL_CLASS_MASK;

    BRR_MdioWrite(phyAddress, PHY_PODL_CONTROL, podlCtrl);

    // Set power limit
    BRR_MdioWrite(phyAddress, PHY_PODL_POWER_LIMIT, cfg->maxPowerMw);

    LogInfo("PoDL configured: Class %d, Max %d mW",
            cfg->powerClass, cfg->maxPowerMw);
}
```

## Use Case: Surround View Camera System

### Network Architecture
```
Central Camera ECU (Master)
  |
  +-- Front Camera (PD, Slave) - 5m cable
  +-- Rear Camera (PD, Slave) - 8m cable
  +-- Left Camera (PD, Slave) - 12m cable
  +-- Right Camera (PD, Slave) - 12m cable
```

### Cable Installation Guidelines
- Route away from high-power lines (>50cm separation)
- Avoid sharp bends (<50mm radius)
- Use cable ties every 15cm
- Ground shielding at one point only
- Install common-mode chokes near PHY

### PHY Configuration for Cameras
- Master mode at ECU
- Slave mode at cameras
- PoDL Class 3 (1-3.6W per camera)
- Auto-negotiation enabled
- Sleep mode for power saving when idle

## Deliverables

- PHY selection and configuration guide
- Cable routing diagram
- EMC test plan and results
- TDR cable verification reports
- Driver implementation (MDIO/PHY)
- Power budget analysis (PoDL)
- Integration test specifications

## Common Issues and Solutions

### Link Instability
- Check cable quality and length (<15m)
- Verify impedance matching (100 ohms)
- Test with TDR for cable faults
- Ensure proper master/slave configuration

### EMI Emissions Failures
- Enable spread spectrum clocking
- Add/relocate common-mode chokes
- Improve cable shielding and grounding
- Reduce driver output strength

### Auto-Negotiation Failures
- Verify both PHYs support ANEG
- Check for forced speed/duplex settings
- Monitor MDIO communication errors
- Validate PHY firmware version

### PoDL Power Issues
- Check cable resistance (<2 ohms for AWG24)
- Verify power class compatibility
- Monitor voltage drop along cable
- Ensure adequate PSE power budget

## Ethernet AVB/TSN Protocol

## Core Competencies

Expert in Automotive Ethernet with AVB/TSN for deterministic, low-latency networking.

### Physical Layer (100BASE-T1 / 1000BASE-T1)
- Single twisted pair (BroadR-Reach PHY)
- 100 Mbps or 1 Gbps data rate
- Cable length up to 15m (100BASE-T1) or 40m (1000BASE-T1)
- Point-to-point topology (switched network)
- PoE support for camera power

### TSN Technology Stack
- IEEE 802.1AS (Time Synchronization - gPTP)
- IEEE 802.1Qbv (Time-Aware Shaper - TAS)
- IEEE 802.1Qav (Credit-Based Shaper - CBS)
- IEEE 802.1Qcc (Stream Reservation Protocol - SRP)
- IEEE 802.1CB (Frame Replication and Elimination)

### Protocol Layers
```
Application (SOME/IP, DoIP, AVTP)
         |
Transport (UDP/TCP)
         |
Network (IPv4/IPv6)
         |
Data Link (AVB/TSN + VLAN)
         |
Physical (100BASE-T1 / 1000BASE-T1)
```

### Time-Sensitive Traffic Classes
- **Class A (CDT)**: Critical Data Traffic (e.g., ADAS sensor data)
  - Max latency: 2ms
  - Priority: Highest (PCP 6-7)
- **Class B**: Audio/Video streaming
  - Max latency: 50ms
  - Priority: High (PCP 4-5)
- **Best Effort**: Non-critical data
  - No latency guarantee
  - Priority: Normal (PCP 0-3)

## Design Approach

1. Network Architecture Design
   - Define topology (star, daisy-chain, hybrid)
   - Calculate bandwidth requirements
   - Plan VLAN and QoS strategy
   - Design fault tolerance (redundancy)

2. TSN Configuration
   - Configure gPTP domains
   - Design Time-Aware Shaper schedules
   - Allocate bandwidth per traffic class
   - Configure stream reservation

3. SOME/IP Service Design
   - Define service interfaces (FIDL)
   - Implement service discovery
   - Design event/method communication
   - Configure serialization

4. Validation and Testing
   - Timing verification (end-to-end latency)
   - Bandwidth utilization monitoring
   - Fault injection testing
   - TSN schedule validation

## Implementation Examples

### gPTP Time Synchronization (IEEE 802.1AS)
```c
// Initialize gPTP for time synchronization
typedef struct {
    uint8_t domainNumber;      // gPTP domain (0-127)
    uint8_t priority1;         // Grandmaster priority
    uint8_t priority2;
    uint8_t logSyncInterval;   // Sync message interval (log2)
    uint8_t logAnnounceInterval;
} gPTP_Config_t;

void gPTP_Init(const gPTP_Config_t* config) {
    // Configure as grandmaster or slave
    gPTP_SetDomain(config->domainNumber);
    gPTP_SetPriority(config->priority1, config->priority2);

    // Set sync interval (e.g., -3 = 125us, 0 = 1s)
    gPTP_SetSyncInterval(config->logSyncInterval);

    // Enable time synchronization
    gPTP_Enable();
}

// Get synchronized network time
uint64_t gPTP_GetNetworkTime(void) {
    uint64_t seconds;
    uint32_t nanoseconds;

    gPTP_GetTime(&seconds, &nanoseconds);

    return (seconds * 1000000000ULL) + nanoseconds;
}
```

### Time-Aware Shaper Configuration (IEEE 802.1Qbv)
```c
// TAS gate control list for deterministic scheduling
typedef struct {
    uint8_t gateStates;        // Bitmap of open gates (per TC)
    uint32_t timeIntervalNs;   // Interval duration
} TAS_GateEntry_t;

typedef struct {
    uint64_t basetime;         // Schedule start time (gPTP)
    uint32_t cycleTime;        // Total cycle duration
    TAS_GateEntry_t entries[8];
    uint8_t entryCount;
} TAS_Schedule_t;

// Example: 1ms cycle with dedicated slots for each traffic class
const TAS_Schedule_t adasSchedule = {
    .basetime = 0,             // Align to gPTP epoch
    .cycleTime = 1000000,      // 1ms cycle
    .entryCount = 4,
    .entries = {
        // Time slot 1: Critical ADAS data (300us)
        {.gateStates = 0b11000000, .timeIntervalNs = 300000},

        // Time slot 2: Audio/Video (400us)
        {.gateStates = 0b00110000, .timeIntervalNs = 400000},

        // Time slot 3: Best effort (200us)
        {.gateStates = 0b00001111, .timeIntervalNs = 200000},

        // Time slot 4: Guard band (100us)
        {.gateStates = 0b00000000, .timeIntervalNs = 100000}
    }
};

void TAS_ConfigureSchedule(uint8_t port, const TAS_Schedule_t* schedule) {
    // Program TAS registers on switch/endpoint
    TAS_SetBaseTime(port, schedule->basetime);
    TAS_SetCycleTime(port, schedule->cycleTime);

    for (uint8_t i = 0; i < schedule->entryCount; i++) {
        TAS_SetGateEntry(
            port,
            i,
            schedule->entries[i].gateStates,
            schedule->entries[i].timeIntervalNs
        );
    }

    // Enable TAS
    TAS_Enable(port);
}
```

### AVTP Camera Streaming (IEEE 1722)
```c
// AVTP stream for camera video
typedef struct {
    uint64_t streamId;         // Unique stream identifier
    uint8_t  destMac[6];       // Multicast MAC address
    uint16_t vlanId;
    uint8_t  priority;         // PCP value
    uint32_t maxFrameSize;     // Maximum video frame size
    uint16_t maxIntervalFrames;// Frames per interval
} AVTP_StreamConfig_t;

// Configure AVTP stream
void AVTP_ConfigureStream(const AVTP_StreamConfig_t* config) {
    // Register stream with SRP
    SRP_RegisterStream(
        config->streamId,
        config->destMac,
        config->vlanId,
        config->priority,
        config->maxFrameSize,
        config->maxIntervalFrames
    );

    // Configure talker
    AVTP_SetStreamId(config->streamId);
    AVTP_SetFormat(AVTP_FORMAT_H264);
}

// Send video frame via AVTP
void AVTP_SendVideoFrame(
    uint64_t streamId,
    uint8_t* frameData,
    uint32_t frameSize,
    uint64_t timestamp
) {
    // Build AVTP header
    AVTP_Header_t header;
    header.subtype = AVTP_SUBTYPE_CVF;  // Compressed Video Format
    header.streamId = streamId;
    header.timestamp = timestamp;       // gPTP timestamp
    header.streamDataLength = frameSize;
    header.sequenceNum = avtpSeqNum++;

    // Transmit with high priority
    ETH_SendPacket(
        &header,
        sizeof(header),
        frameData,
        frameSize,
        PRIORITY_HIGH
    );
}
```

### SOME/IP Service Implementation
```cpp
// SOME/IP service definition (Franca IDL)
/*
interface SensorFusion {
    version { major 1 minor 0 }

    method GetObjectList {
        out {
            ObjectList objects
        }
    }

    broadcast ObjectDetected {
        out {
            Object detectedObject
        }
    }
}
*/

// Service implementation
class SensorFusionService : public SomeIpService {
public:
    SensorFusionService() : SomeIpService(SERVICE_ID, INSTANCE_ID) {
        // Register methods
        RegisterMethod(METHOD_GET_OBJECT_LIST,
                      &SensorFusionService::HandleGetObjectList);

        // Offer service
        OfferService();
    }

    void HandleGetObjectList(const Message& request, Message& response) {
        // Gather object list from sensors
        ObjectList objects = GetTrackedObjects();

        // Serialize response
        Serializer serializer;
        serializer << objects;

        // Send response
        response.SetPayload(serializer.GetData());
        SendResponse(response);
    }

    void NotifyObjectDetected(const Object& obj) {
        // Broadcast event
        Message event(SERVICE_ID, INSTANCE_ID, EVENT_OBJECT_DETECTED);

        Serializer serializer;
        serializer << obj;

        event.SetPayload(serializer.GetData());
        BroadcastEvent(event);
    }

private:
    static const uint16_t SERVICE_ID = 0x1234;
    static const uint16_t INSTANCE_ID = 0x0001;
    static const uint16_t METHOD_GET_OBJECT_LIST = 0x0100;
    static const uint16_t EVENT_OBJECT_DETECTED = 0x8000;
};
```

### Stream Reservation Protocol (SRP)
```c
// Reserve bandwidth for AVB/TSN stream
typedef struct {
    uint64_t streamId;
    uint8_t  destMac[6];
    uint16_t vlanId;
    uint8_t  priority;
    uint32_t maxFrameSize;
    uint16_t maxIntervalFrames;
    uint32_t accumulatedLatency;  // Max end-to-end latency
} SRP_TalkerAdvertise_t;

SRP_Status_t SRP_AdvertiseStream(const SRP_TalkerAdvertise_t* talker) {
    // Calculate required bandwidth
    uint32_t bandwidth = (talker->maxFrameSize * 8 *
                         talker->maxIntervalFrames) / 125000;  // Mbps

    // Send MSRP Talker Advertise
    MSRP_SendTalkerAdvertise(
        talker->streamId,
        talker->destMac,
        talker->vlanId,
        talker->priority,
        talker->maxFrameSize,
        talker->maxIntervalFrames,
        talker->accumulatedLatency
    );

    // Wait for listener ready
    return SRP_WaitForListenerReady(talker->streamId, 1000);
}
```

## Use Case: ADAS Sensor Fusion System

### Network Architecture
```
Central ADAS ECU (Switch + Compute)
  |
  +-- Front Camera (1920x1080@30fps, H.264)
  +-- Rear Camera (1920x1080@30fps, H.264)
  +-- Left Camera (1280x720@30fps, H.264)
  +-- Right Camera (1280x720@30fps, H.264)
  +-- Front Radar (Object list @ 50Hz)
  +-- Lidar (Point cloud @ 10Hz)
  +-- Gateway ECU (CAN/FlexRay bridge)
```

### Bandwidth Requirements (1000BASE-T1)
- Front Camera: ~8 Mbps (H.264)
- Rear Camera: ~8 Mbps
- Left Camera: ~4 Mbps
- Right Camera: ~4 Mbps
- Radar: ~1 Mbps
- Lidar: ~20 Mbps
- Control/diagnostics: ~5 Mbps
- **Total**: ~50 Mbps (5% of 1 Gbps)

### TSN Configuration
- gPTP domain 0 for time sync (125us sync interval)
- TAS cycle: 1ms
- Critical traffic (radar, control): 300us window
- Video traffic: 600us window
- Best effort: 100us window

## Deliverables

- Network topology diagram
- TSN schedule configuration
- SOME/IP service definitions (FIDL)
- Bandwidth allocation spreadsheet
- gPTP configuration
- Driver/middleware implementation
- Integration test specifications
- Timing analysis report

## Common Issues and Solutions

### Time Sync Failures
- Verify gPTP domain configuration
- Check grandmaster selection algorithm
- Monitor path delay measurements
- Validate switch support for gPTP

### Packet Loss in Critical Traffic
- Check TAS gate schedule alignment
- Verify bandwidth reservation via SRP
- Monitor queue depths and drops
- Validate switch buffer configuration

### High Latency
- Optimize TAS schedule (reduce guard bands)
- Check for best-effort traffic starvation
- Verify priority tag configuration
- Analyze per-hop latency in switches

### SOME/IP Discovery Issues
- Check multicast routing configuration
- Verify service offer/find timing
- Monitor UDP port conflicts
- Validate firewall/VLAN settings

## FlexRay Protocol

## Core Competencies

Expert in FlexRay protocol for deterministic, fault-tolerant automotive communication.

### Physical Layer
- Dual-channel redundant communication (Channel A/B)
- Differential signaling at 10 Mbps
- Bus Guardian for fault isolation
- Star, bus, or hybrid topologies
- Cable length up to 24m per segment

### Data Link Layer
- Static and dynamic segments
- Time Division Multiple Access (TDMA)
- Cycle time: 1-16 ms (configurable)
- Frame size: 0-254 bytes payload
- CRC and frame checksums

### Communication Cycle Structure
```
|<------- Communication Cycle ------->|
| Static | Dynamic | Symbol | NIT     |
| Segment| Segment | Window | (Idle)  |
```

- Static Segment: Guaranteed deterministic slots
- Dynamic Segment: Flexible priority-based transmission
- Symbol Window: Network management
- Network Idle Time (NIT): Clock synchronization

### Timing and Synchronization
- Global time synchronization across all nodes
- Offset and rate correction
- Maximum drift tolerance: 1500 ppm
- Startup and wakeup procedures
- Coldstart vs. non-coldstart nodes

### Configuration Parameters
- Slot assignment (static/dynamic)
- Payload length per slot
- Base cycle multiplier
- Action point offsets
- Bus Guardian parameters

## Design Approach

1. Network Planning
   - Define communication matrix
   - Calculate bandwidth requirements
   - Assign static/dynamic slots
   - Configure redundancy strategy

2. Cluster Configuration
   - Set global cycle parameters
   - Configure clock synchronization
   - Define startup sequence
   - Set Bus Guardian parameters

3. Node Implementation
   - Configure Communication Controller (CC)
   - Implement AUTOSAR FlexRay Driver
   - Define frame triggering
   - Implement error handling

4. Validation and Testing
   - Timing verification (WCET analysis)
   - Fault injection testing
   - Startup sequence validation
   - Load and stress testing

## Implementation Examples

### Static Slot Configuration (AUTOSAR)
```c
// FlexRay static slot transmission
const Fr_LPduType staticPdu = {
    .FrameId = 10,              // Static slot ID
    .Channel = FR_CHANNEL_AB,   // Both channels
    .CycleRepetition = 1,       // Every cycle
    .CycleOffset = 0,
    .Payload = 16,              // 16 bytes (8 words)
    .HeaderCRC = 0x1A3          // Calculated CRC
};

// Transmit in static slot
Std_ReturnType result = Fr_TransmitTxLPdu(
    0,                          // Controller ID
    10,                         // Frame ID
    txData,                     // Payload pointer
    16                          // Length
);
```

### Dynamic Slot Usage
```c
// Dynamic segment configuration
const Fr_DynamicSlotConfig_t dynConfig = {
    .SlotId = 50,               // Dynamic slot start
    .PayloadLength = 32,
    .MinislotCount = 20,        // Number of minislots
    .Priority = 5               // Transmission priority
};

// Conditional transmission in dynamic segment
if (Fr_CheckTxLPduStatus(0, 50) == FR_TRANSMITTED) {
    Fr_TransmitTxLPdu(0, 50, dynamicData, 32);
}
```

### Startup Sequence
```c
// FlexRay startup procedure
void FlexRay_Startup(void) {
    // Initialize Communication Controller
    Fr_Init(&Fr_Config);

    // Configure cluster parameters
    Fr_ControllerInit(0);

    // Start communication (coldstart node)
    Fr_StartCommunication(0);

    // Wait for normal active state
    Fr_PocStateType pocState;
    do {
        Fr_GetPOCStatus(0, &pocState);
    } while (pocState != FR_POCSTATE_NORMAL_ACTIVE);
}
```

### Bus Guardian Configuration
```c
// Bus Guardian prevents babbling idiot
const Fr_BusGuardianConfig_t bgConfig = {
    .GuardianEnable = TRUE,
    .ActionPointOffset = 5,     // Macroticks before slot start
    .MaxTxDuration = 50,        // Maximum transmission time
    .MinislotDuration = 2       // Minislot size (macroticks)
};
```

## Use Case: Steer-by-Wire System

### Network Architecture
```
Steering ECU (Coldstart) <--Channel A/B--> Actuator ECU 1
                        <--Channel A/B--> Actuator ECU 2
                        <--Channel A/B--> Sensor ECU
```

### Communication Matrix
| Slot | Sender       | Data             | Cycle | Size |
|------|--------------|------------------|-------|------|
| 1    | Steering ECU | Steering Angle   | 5ms   | 16B  |
| 2    | Sensor ECU   | Torque Sensor    | 5ms   | 8B   |
| 3    | Actuator 1   | Position Status  | 5ms   | 12B  |
| 4    | Actuator 2   | Position Status  | 5ms   | 12B  |
| 50+  | All          | Diagnostics      | 20ms  | 32B  |

### Safety Considerations
- ASIL-D rated communication
- Dual-channel redundancy with voting
- Sequence counter for frame freshness
- CRC calculation for data integrity
- Timeout supervision on critical signals

## Deliverables

- FlexRay cluster specification (FIBEX XML)
- Node configuration files (AUTOSAR)
- Communication matrix documentation
- Driver implementation (C/C++)
- Timing analysis report (WCET)
- Integration test specifications
- Safety documentation (ISO 26262)

## Common Issues and Solutions

### Startup Failures
- Check coldstart node configuration
- Verify sync frame offsets
- Ensure clock tolerance within spec
- Validate Bus Guardian timing

### Communication Errors
- Monitor slot boundary violations
- Check CRC errors in frames
- Verify payload length configuration
- Analyze bus load in dynamic segment

### Timing Violations
- Reduce static segment load
- Optimize dynamic slot allocation
- Adjust action point offsets
- Verify interrupt latencies

## LIN Protocol

## Core Competencies

Expert in LIN protocol for cost-effective automotive sub-networks.

### Physical Layer
- Single-wire bidirectional bus
- Baud rates: 1 kbps to 20 kbps (typical: 9.6/19.2 kbps)
- Master-slave architecture (1 master, up to 16 slaves)
- Dominant (0V) and recessive (12V battery voltage)
- Bus length up to 40 meters
- No termination resistors required

### Protocol Architecture
- Master schedules all communication
- Slaves respond only when addressed
- Time-triggered schedule tables
- Event-triggered frames for efficiency
- Diagnostic services (ISO 14229 subset)

### Frame Structure
```
|<---------- LIN Frame ---------->|
| Header (Master)  | Response      |
| Break | Sync | ID| Data | CRC   |
```

- Break field: 13 dominant bits minimum
- Sync byte: 0x55 for baud rate sync
- Protected ID: 6-bit ID + 2 parity bits
- Data: 1-8 bytes
- Checksum: Classic or Enhanced

### LIN Frame Types
- Unconditional frames (standard data)
- Event-triggered frames (slave polling)
- Sporadic frames (conditional master transmission)
- Diagnostic frames (node configuration)

### Schedule Table Concept
```c
// Schedule table defines communication pattern
LIN_ScheduleTable_t SeatControlSchedule[] = {
    {FRAME_SeatPosition,    10},  // Every 10ms
    {FRAME_SeatMemory,      50},  // Every 50ms
    {FRAME_EventTrigger,   100},  // Slave event polling
    {FRAME_DiagRequest,    200},  // Diagnostic window
};
```

## Design Approach

1. Network Planning
   - Define master and slave nodes
   - Create signal database (LDF file)
   - Design schedule tables
   - Assign frame IDs (0x00-0x3F)

2. Master Node Implementation
   - Configure UART for LIN
   - Implement schedule table execution
   - Handle slave responses
   - Provide diagnostic services

3. Slave Node Implementation
   - Configure frame filters (ID match)
   - Implement response generation
   - Handle sleep/wakeup commands
   - Support node configuration

4. Validation and Testing
   - Bus timing verification
   - Frame error injection
   - Sleep/wakeup testing
   - EMC compliance testing

## Implementation Examples

### Master Frame Transmission (AUTOSAR)
```c
// LIN master sends unconditional frame
void Lin_MasterSendFrame(uint8 channel, Lin_PduType* pdu) {
    // Send break field (13-26 dominant bits)
    Lin_SendBreak(channel);

    // Send sync byte (0x55)
    Lin_SendByte(channel, LIN_SYNC_BYTE);

    // Calculate protected ID (ID + parity)
    uint8 protectedId = Lin_CalculateProtectedId(pdu->Id);
    Lin_SendByte(channel, protectedId);

    // Send data bytes
    for (uint8 i = 0; i < pdu->DataLength; i++) {
        Lin_SendByte(channel, pdu->Data[i]);
    }

    // Send checksum (enhanced)
    uint8 checksum = Lin_CalculateChecksum(
        protectedId,
        pdu->Data,
        pdu->DataLength,
        LIN_ENHANCED_CRC
    );
    Lin_SendByte(channel, checksum);
}
```

### Slave Response Handling
```c
// LIN slave responds to master request
void Lin_SlaveProcessFrame(uint8 id, uint8* data, uint8 len) {
    Lin_FrameResponseType response;

    // Check if this frame is for us
    if (Lin_GetFrameResponse(id, &response) == E_OK) {
        switch (response.Type) {
            case LIN_UNCONDITIONAL:
                // Provide response data
                Lin_PrepareResponse(
                    response.Data,
                    response.Length
                );
                break;

            case LIN_EVENT_TRIGGERED:
                // Check if we have data to send
                if (Lin_HasEventData()) {
                    Lin_PrepareResponse(
                        eventData,
                        eventLength
                    );
                }
                break;

            case LIN_DIAGNOSTIC:
                // Handle diagnostic request
                Lin_ProcessDiagnostic(data, len);
                break;
        }
    }
}
```

### Schedule Table Execution
```c
// Master executes schedule table
typedef struct {
    uint8 frameId;
    uint16 delayMs;
} Lin_ScheduleEntry_t;

const Lin_ScheduleEntry_t seatSchedule[] = {
    {0x10, 10},   // Seat position every 10ms
    {0x11, 20},   // Seat tilt every 20ms
    {0x12, 50},   // Memory recall every 50ms
    {0x3C, 100},  // Event-triggered every 100ms
    {0x3D, 200}   // Diagnostic every 200ms
};

void Lin_ExecuteSchedule(uint8 channel) {
    static uint8 scheduleIndex = 0;
    static uint32 lastTime = 0;

    uint32 currentTime = GetTickCount();
    const Lin_ScheduleEntry_t* entry = &seatSchedule[scheduleIndex];

    if (currentTime - lastTime >= entry->delayMs) {
        Lin_SendFrame(channel, entry->frameId);

        scheduleIndex = (scheduleIndex + 1) %
                        ARRAY_SIZE(seatSchedule);
        lastTime = currentTime;
    }
}
```

### Sleep/Wakeup Implementation
```c
// Sleep command (diagnostic frame 0x3C)
void Lin_GoToSleep(uint8 channel) {
    uint8 sleepCmd[] = {0x00, 0xFF, 0xFF, 0xFF,
                        0xFF, 0xFF, 0xFF, 0xFF};
    Lin_SendDiagnosticFrame(channel, 0x3C, sleepCmd, 8);

    // Enter sleep mode after frame transmission
    Lin_SetState(channel, LIN_STATE_SLEEP);
}

// Wakeup pulse (dominant signal 250-5000us)
void Lin_Wakeup(uint8 channel) {
    // Send dominant pulse (typically 500us)
    Lin_SendWakeupPulse(channel, 500);

    // Wait for bus recovery
    DelayUs(150);

    // Resume normal operation
    Lin_SetState(channel, LIN_STATE_OPERATIONAL);
}
```

### Node Configuration (LIN 2.x)
```c
// Assign NAD (Node Address for Diagnostics)
void Lin_AssignNAD(uint8 supplierId, uint16 functionId, uint8 newNAD) {
    uint8 configData[] = {
        0x06,                      // Service: Assign NAD
        (supplierId >> 8) & 0xFF,  // Supplier ID MSB
        supplierId & 0xFF,         // Supplier ID LSB
        (functionId >> 8) & 0xFF,  // Function ID MSB
        functionId & 0xFF,         // Function ID LSB
        newNAD,                    // New NAD
        0xFF, 0xFF
    };

    Lin_SendDiagnosticFrame(0, 0x3C, configData, 8);
}
```

## Use Case: Power Seat Control

### Network Architecture
```
Master (Body Control Module)
  |
  +-- Slave 1: Seat Position Sensor (NAD 0x01)
  +-- Slave 2: Lumbar Actuator (NAD 0x02)
  +-- Slave 3: Recline Motor (NAD 0x03)
  +-- Slave 4: Height Adjustment (NAD 0x04)
```

### Signal Database (LDF excerpt)
```ldf
Signals {
    SeatPositionFB: 8, 0, RightSeatSensor, AllNodes;
    LumbarPosition: 8, 0, LumbarActuator, AllNodes;
    ReclineAngle: 16, 0, ReclineMotor, AllNodes;
    SeatHeight: 8, 0, HeightActuator, AllNodes;
    MemoryRecall: 2, 0, BodyControlModule, AllNodes;
}

Frames {
    SeatStatus: 0x10, BodyControlModule, 4 {
        SeatPositionFB, 0;
        LumbarPosition, 8;
        ReclineAngle, 16;
    }

    SeatCommand: 0x11, BodyControlModule, 2 {
        MemoryRecall, 0;
        TargetPosition, 8;
    }
}

Schedule_tables {
    NormalOperation {
        SeatStatus delay 10 ms;
        SeatCommand delay 20 ms;
        EventTriggered delay 50 ms;
    }
}
```

### Timing Considerations
- Frame time: ~10ms at 9.6 kbps for 8-byte frame
- Schedule cycle: 100-200ms typical
- Response timeout: 14ms maximum (LIN spec)
- Sleep transition: within 4 seconds

## Deliverables

- LIN network description file (LDF)
- Node capability files (NCF)
- Master schedule tables
- Slave driver implementation
- Diagnostic database (ODX)
- Integration test specifications
- EMC test report

## Common Issues and Solutions

### Sync Byte Errors
- Check baud rate tolerance (<1.5%)
- Verify UART clock source stability
- Adjust slave sync detection

### Checksum Failures
- Verify classic vs. enhanced CRC mode
- Check endianness of multi-byte signals
- Validate checksum calculation algorithm

### Sleep/Wakeup Problems
- Check wakeup pulse duration (250-5000us)
- Verify bus pullup resistor (1k typical)
- Ensure all nodes support sleep mode

### Bus Contention
- Verify schedule table timing
- Check for rogue slave transmissions
- Monitor bus idle time between frames

## LVDS Protocol

## Core Competencies

Expert in LVDS for high-speed differential signaling in automotive applications.

### Physical Layer Characteristics
- Differential voltage: 247-454 mV (nominal 350 mV)
- Common-mode voltage: 1.2V typical
- Data rates: 155 Mbps to 1.2 Gbps per lane
- Low power consumption: ~3.5mW per driver
- Excellent EMI performance (differential cancellation)
- Point-to-point or multi-drop topologies

### Signal Characteristics
- Differential impedance: 100 ohms ±10%
- Rise/fall time: <500ps (typical 200ps)
- Propagation delay: ~50ps/inch on PCB
- Maximum cable length: 10m (shielded twisted pair)
- Skew tolerance: ±350ps between lanes

### LVDS Applications in Automotive
1. **Camera Interfaces**
   - Raw Bayer sensor data (MIPI CSI-2)
   - YUV422/RGB888 video formats
   - 1-4 data lanes + clock lane
   - Typical: 720p@30fps = 1 lane, 1080p@60fps = 4 lanes

2. **Display Interfaces**
   - FPD-Link (Texas Instruments)
   - OpenLDI for LCD panels
   - Instrument cluster displays
   - Head-up display (HUD) units

3. **Sensor Data**
   - Radar digital interface
   - Lidar point cloud transmission
   - High-speed ADC data

## Design Approach

1. Signal Integrity Design
   - Differential pair routing (100 ohm impedance)
   - Length matching between pairs (±5 mils)
   - Controlled impedance PCB stackup
   - Minimize vias and stubs

2. Serializer/Deserializer Selection
   - Choose appropriate SerDes chipset
   - Calculate required bandwidth
   - Plan for FEC (Forward Error Correction)
   - Consider diagnostic features

3. EMC/EMI Mitigation
   - Common-mode choke on cable
   - Proper grounding and shielding
   - Spread spectrum clocking
   - PCB layer stackup optimization

4. Validation and Testing
   - Eye diagram analysis
   - Jitter and skew measurement
   - BER (Bit Error Rate) testing
   - EMI radiated emissions testing

## Implementation Examples

### LVDS Driver Configuration
```c
// LVDS transmitter initialization
typedef struct {
    uint8_t laneCount;         // 1-4 lanes
    uint32_t bitRate;          // Mbps per lane
    bool spreadSpectrum;       // SSC for EMI reduction
    uint8_t outputSwing;       // 250mV, 300mV, 350mV, 400mV
    bool termination;          // 100 ohm termination
} LVDS_TxConfig_t;

void LVDS_InitTransmitter(const LVDS_TxConfig_t* config) {
    // Configure PLL for desired bit rate
    uint32_t pllFreq = config->bitRate * config->laneCount;
    LVDS_SetPLLFrequency(pllFreq);

    // Enable spread spectrum if requested
    if (config->spreadSpectrum) {
        LVDS_EnableSSC(SSC_CENTER_SPREAD, SSC_MODULATION_0_5_PERCENT);
    }

    // Configure output swing
    LVDS_SetOutputSwing(config->outputSwing);

    // Enable differential termination
    if (config->termination) {
        LVDS_EnableTermination(TERMINATION_100_OHM);
    }

    // Configure lane mapping
    for (uint8_t lane = 0; lane < config->laneCount; lane++) {
        LVDS_MapLane(lane, LANE_ENABLED);
    }

    // Enable transmitter
    LVDS_Enable(LVDS_TX);
}
```

### MIPI CSI-2 over LVDS (Camera Interface)
```c
// MIPI CSI-2 camera configuration
typedef struct {
    uint8_t dataLanes;         // 1-4 data lanes
    uint32_t pixelClock;       // MHz
    uint16_t width;            // Pixels
    uint16_t height;           // Lines
    uint8_t bitsPerPixel;      // 8, 10, 12, 16
    uint8_t virtualChannel;    // 0-3
} CSI2_CameraConfig_t;

void CSI2_ConfigureCamera(const CSI2_CameraConfig_t* config) {
    // Calculate required lane data rate
    // rate = (width * height * bpp * fps) / lanes
    uint32_t bytesPerFrame = config->width * config->height *
                             config->bitsPerPixel / 8;
    uint32_t laneDataRate = (bytesPerFrame * 30) / config->dataLanes;

    // Configure D-PHY (LVDS physical layer)
    CSI2_ConfigureDPhy(config->dataLanes, laneDataRate);

    // Configure CSI-2 receiver
    CSI2_SetVirtualChannel(config->virtualChannel);
    CSI2_SetDataType(CSI2_DT_RAW10);  // For 10-bit Bayer
    CSI2_SetImageSize(config->width, config->height);

    // Enable lanes
    for (uint8_t lane = 0; lane < config->dataLanes; lane++) {
        CSI2_EnableLane(lane);
    }

    // Start receiving
    CSI2_StartReceive();
}

// CSI-2 packet reception handler
void CSI2_ReceiveFrame(uint8_t* frameBuffer, uint32_t bufferSize) {
    // Wait for frame start (FS) packet
    CSI2_Packet_t packet;
    while (1) {
        if (CSI2_ReceivePacket(&packet) == CSI2_OK) {
            if (packet.dataType == CSI2_DT_FRAME_START) {
                break;
            }
        }
    }

    // Receive line packets
    uint32_t offset = 0;
    uint16_t linesReceived = 0;

    while (linesReceived < imageHeight) {
        if (CSI2_ReceivePacket(&packet) == CSI2_OK) {
            if (packet.dataType == CSI2_DT_RAW10) {
                // Copy pixel data
                memcpy(&frameBuffer[offset],
                       packet.payload,
                       packet.wordCount);
                offset += packet.wordCount;
                linesReceived++;
            } else if (packet.dataType == CSI2_DT_FRAME_END) {
                break;
            }
        }
    }

    // Signal frame complete
    CSI2_FrameComplete(frameBuffer, offset);
}
```

### FPD-Link Display Interface
```c
// FPD-Link III serializer configuration
typedef struct {
    uint16_t displayWidth;
    uint16_t displayHeight;
    uint8_t colorDepth;        // 18 or 24 bits
    uint32_t pixelClock;       // MHz
    bool backChannel;          // Enable I2C/control back channel
} FPDLink_DisplayConfig_t;

void FPDLink_ConfigureDisplay(const FPDLink_DisplayConfig_t* config) {
    // Calculate serialized data rate
    uint32_t dataRate = config->pixelClock * config->colorDepth;

    // Configure serializer (DS90UB913A-Q1 or similar)
    FPDLink_SerializerInit();

    // Set pixel format
    if (config->colorDepth == 18) {
        FPDLink_SetPixelFormat(FPDLINK_RGB666);
    } else {
        FPDLink_SetPixelFormat(FPDLINK_RGB888);
    }

    // Configure timing
    FPDLink_SetDisplayTiming(
        config->displayWidth,
        config->displayHeight,
        config->pixelClock
    );

    // Enable back channel for touchscreen/I2C
    if (config->backChannel) {
        FPDLink_EnableBackChannel(BACK_CHANNEL_I2C);
    }

    // Enable serializer output
    FPDLink_EnableOutput();
}

// FPD-Link deserializer (at display side)
void FPDLink_DeserializerInit(void) {
    // Configure deserializer (DS90UB914A-Q1 or similar)
    FPDLink_DeserInit();

    // Auto-detect incoming signal
    FPDLink_AutoDetectFormat();

    // Configure LCD output interface
    FPDLink_SetOutputInterface(OUTPUT_PARALLEL_RGB);

    // Enable pattern generation for testing
    FPDLink_EnableTestPattern(PATTERN_COLORBAR);

    // Wait for lock
    while (!FPDLink_IsLocked()) {
        DelayMs(10);
    }

    // Disable test pattern
    FPDLink_DisableTestPattern();
}
```

### LVDS Receiver with Error Detection
```c
// LVDS receiver with link monitoring
typedef struct {
    bool locked;
    uint32_t bitErrors;
    uint32_t frameErrors;
    int8_t signalStrength;     // dBm
    uint32_t jitterPs;         // Picoseconds
} LVDS_RxStatus_t;

LVDS_RxStatus_t LVDS_GetReceiverStatus(void) {
    LVDS_RxStatus_t status = {0};

    // Check clock/data lock
    status.locked = LVDS_IsClockLocked() && LVDS_IsDataLocked();

    // Read error counters
    status.bitErrors = LVDS_ReadRegister(REG_BIT_ERROR_COUNT);
    status.frameErrors = LVDS_ReadRegister(REG_FRAME_ERROR_COUNT);

    // Measure signal strength
    status.signalStrength = LVDS_MeasureSignalStrength();

    // Measure jitter
    status.jitterPs = LVDS_MeasureJitter();

    return status;
}

// Automatic link recovery
void LVDS_MonitorLink(void) {
    static uint32_t lastErrorCount = 0;
    LVDS_RxStatus_t status = LVDS_GetReceiverStatus();

    if (!status.locked) {
        LogError("LVDS link lost - attempting recovery");
        LVDS_ResetReceiver();
        return;
    }

    // Check for increasing error rate
    if (status.bitErrors > lastErrorCount + 100) {
        LogWarning("LVDS bit errors detected: %d", status.bitErrors);

        // Attempt equalization adjustment
        LVDS_AdjustEqualization();
    }

    lastErrorCount = status.bitErrors;
}
```

### Signal Integrity Verification
```c
// Built-in self-test (BIST) pattern generation
typedef enum {
    BIST_PRBS7,      // Pseudo-random 2^7-1
    BIST_PRBS23,     // Pseudo-random 2^23-1
    BIST_PRBS31,     // Pseudo-random 2^31-1
    BIST_FIXED_0,    // All zeros
    BIST_FIXED_1,    // All ones
    BIST_ALTERNATE   // 10101010...
} LVDS_BIST_Pattern_t;

void LVDS_RunBIST(LVDS_BIST_Pattern_t pattern, uint32_t durationMs) {
    // Enable BIST pattern generator
    LVDS_EnableBIST(pattern);

    // Wait for test duration
    DelayMs(durationMs);

    // Disable BIST
    LVDS_DisableBIST();

    // Read results
    uint32_t bitErrors = LVDS_GetBISTErrors();
    uint32_t totalBits = LVDS_GetBISTBitCount();

    float ber = (float)bitErrors / (float)totalBits;

    LogInfo("BIST complete: BER = %e (%d errors in %d bits)",
            ber, bitErrors, totalBits);

    // BER should be < 1e-12 for reliable operation
    if (ber > 1e-9) {
        LogError("BIST failed: BER too high");
    }
}
```

## Use Case: Surround View Camera System

### System Architecture
```
Central ECU (SoC with 4x CSI-2 inputs)
  |
  +-- Front Camera (LVDS 4-lane) - 1920x1080@30fps
  +-- Rear Camera (LVDS 4-lane) - 1920x1080@30fps
  +-- Left Camera (LVDS 2-lane) - 1280x720@30fps
  +-- Right Camera (LVDS 2-lane) - 1280x720@30fps
```

### Camera Configuration
- Front/Rear: 4 data lanes @ 800 Mbps/lane
- Left/Right: 2 data lanes @ 800 Mbps/lane
- RAW10 Bayer format (10 bits/pixel)
- Virtual channels 0-3 for each camera

### PCB Design Considerations
- Differential pair routing: 5 mil trace/5 mil space
- Length matching: ±5 mils within pair, ±50 mils between pairs
- Reference plane: Solid ground plane under LVDS traces
- Via minimization: Use layer transitions sparingly
- Impedance control: 100 ohms differential ±10%

### Cable Specifications
- Micro-coaxial cable (e.g., I-PEX CABLINE)
- Impedance: 100 ohms differential
- Length: <30cm typical
- Shielding: Aluminum-mylar wrap + drain wire
- Connectors: High-speed mating (>1 Gbps rated)

## Deliverables

- LVDS link design specification
- PCB layout guidelines and stackup
- SerDes configuration code
- Signal integrity simulation results
- Eye diagram test reports
- EMI test results
- Integration test specifications

## Common Issues and Solutions

### Poor Eye Diagram Quality
- Check PCB trace impedance (should be 100Ω ±10%)
- Verify length matching between differential pairs
- Reduce via count and stubs
- Check termination resistors (100Ω, 1%)

### Clock/Data Lock Failures
- Verify PLL lock at transmitter
- Check for cable discontinuities
- Ensure common-mode voltage within spec
- Validate spread spectrum settings match

### High Bit Error Rate
- Improve cable shielding/grounding
- Adjust receiver equalization
- Reduce crosstalk between lanes
- Check for power supply noise

### EMI Emissions Failures
- Add common-mode choke on cable
- Enable spread spectrum clocking
- Improve PCB ground plane integrity
- Use shielded cables with proper grounding

## MOST Protocol

## Core Competencies

Expert in MOST protocol for high-bandwidth multimedia automotive networks.

### Physical Layer Options
- MOST150: 150 Mbps over optical fiber or UTP
- MOST25/50: Legacy 25/50 Mbps variants
- Ring topology with star topology support
- Optical (POF) or electrical (UTP Cat5) media
- Maximum 64 devices per ring

### Protocol Stack Architecture
```
Application Layer
------------------
Function Blocks (MOST High Protocol)
------------------
Transport Layer (MHP/MEP/MAP)
------------------
Network Layer (Message Router)
------------------
Data Link Layer (MOST Network Services)
------------------
Physical Layer (MOST150 Transceiver)
```

### Channel Types
- Synchronous: Streaming data (audio/video) - isochronous
- Asynchronous: Packet data (control messages)
- Control: Network management and addressing
- Ethernet: IP packet encapsulation (MOST150 only)

### Addressing Scheme
- Physical Address: 16-bit node position on ring
- Logical Address: Function-based addressing
- Group Address: Multicast to multiple nodes
- Broadcast Address: All nodes on network

### Network Topology
```
Head Unit (Master) --> Amplifier --> Display
      ^                                  |
      |                                  v
  USB Hub <-- Rear Seat Controller <-- Camera
```

## Design Approach

1. Network Planning
   - Define device roles (master, slave, source, sink)
   - Calculate bandwidth allocation
   - Plan ring topology and bypass options
   - Design function catalog

2. Synchronous Channel Allocation
   - Audio streaming (stereo/multichannel)
   - Video channels (camera feeds)
   - Clock synchronization
   - Bandwidth reservation

3. Function Block Implementation
   - Define MOST Function Catalog (XML)
   - Implement function interfaces
   - Register with network master
   - Handle events and properties

4. Validation and Testing
   - Ring integrity verification
   - Bandwidth utilization analysis
   - Timing and synchronization tests
   - Fault recovery testing

## Implementation Examples

### Network Services Layer
```c
// MOST network initialization
typedef struct {
    uint16_t nodeAddress;
    uint8_t  deviceRole;      // Master/Slave
    uint16_t syncBandwidth;   // Bytes per frame
    uint16_t asyncBandwidth;  // Bytes per frame
} MOST_NetworkConfig_t;

void MOST_Init(const MOST_NetworkConfig_t* config) {
    // Initialize INIC (Intelligent Network Interface Controller)
    MOST_INIC_Init();

    // Configure network parameters
    MOST_SetNodeAddress(config->nodeAddress);
    MOST_SetDeviceRole(config->deviceRole);

    // Allocate bandwidth
    MOST_AllocateSyncBandwidth(config->syncBandwidth);
    MOST_AllocateAsyncBandwidth(config->asyncBandwidth);

    // Start network services
    MOST_NetworkStartup();
}
```

### Synchronous Audio Streaming
```c
// Configure synchronous connection for audio
typedef struct {
    uint16_t sourceAddress;
    uint16_t sinkAddress;
    uint16_t connectionLabel;
    uint8_t  channelCount;    // Stereo = 2, 5.1 = 6
    uint16_t sampleRate;      // 44.1kHz, 48kHz
    uint8_t  bitDepth;        // 16, 24 bits
} MOST_SyncConnection_t;

MOST_Status_t MOST_CreateAudioStream(
    const MOST_SyncConnection_t* conn
) {
    // Calculate required bandwidth
    // BW = channels * (sampleRate / 48kHz) * (bitDepth / 8)
    uint16_t bandwidth = conn->channelCount *
                        (conn->sampleRate / 48000) *
                        (conn->bitDepth / 8);

    // Allocate synchronous channel
    uint16_t channelId = MOST_AllocateSyncChannel(
        conn->sourceAddress,
        conn->sinkAddress,
        bandwidth
    );

    // Configure audio parameters
    MOST_ConfigureAudioStream(
        channelId,
        conn->channelCount,
        conn->sampleRate,
        conn->bitDepth
    );

    // Start streaming
    return MOST_StartSyncConnection(channelId);
}
```

### Function Block Interface
```c
// MOST Function Block for audio amplifier
typedef struct {
    uint8_t  volume;          // 0-100
    int8_t   balance;         // -50 to +50
    int8_t   fader;           // -50 to +50
    uint8_t  bass;            // 0-100
    uint8_t  treble;          // 0-100
    bool     mute;
} AudioAmp_FBlock_t;

// Function IDs
#define FBLOCK_AUDIO_AMP    0x22
#define FUNC_SET_VOLUME     0x100
#define FUNC_SET_BALANCE    0x101
#define FUNC_SET_MUTE       0x102

// Handle function block message
void AudioAmp_ProcessMessage(
    uint16_t functionId,
    uint8_t* data,
    uint16_t length
) {
    switch (functionId) {
        case FUNC_SET_VOLUME:
            if (length >= 1) {
                audioAmp.volume = data[0];
                DSP_SetVolume(audioAmp.volume);
                AudioAmp_SendStatus(FUNC_SET_VOLUME, STATUS_OK);
            }
            break;

        case FUNC_SET_BALANCE:
            if (length >= 1) {
                audioAmp.balance = (int8_t)data[0];
                DSP_SetBalance(audioAmp.balance);
                AudioAmp_SendStatus(FUNC_SET_BALANCE, STATUS_OK);
            }
            break;

        case FUNC_SET_MUTE:
            if (length >= 1) {
                audioAmp.mute = data[0];
                DSP_SetMute(audioAmp.mute);
                AudioAmp_SendStatus(FUNC_SET_MUTE, STATUS_OK);
            }
            break;
    }
}
```

### Asynchronous Message Handling
```c
// Send control message
typedef struct {
    uint16_t targetAddress;
    uint16_t functionBlockId;
    uint16_t functionId;
    uint8_t  opType;          // Set/Get/Status/Error
    uint8_t  data[MAX_PAYLOAD];
    uint16_t dataLength;
} MOST_ControlMessage_t;

MOST_Status_t MOST_SendControlMessage(
    const MOST_ControlMessage_t* msg
) {
    // Build MOST control message
    uint8_t msgBuffer[256];
    uint16_t idx = 0;

    // Addressing
    msgBuffer[idx++] = (msg->targetAddress >> 8) & 0xFF;
    msgBuffer[idx++] = msg->targetAddress & 0xFF;

    // Function Block and Instance
    msgBuffer[idx++] = (msg->functionBlockId >> 8) & 0xFF;
    msgBuffer[idx++] = msg->functionBlockId & 0xFF;

    // Function ID
    msgBuffer[idx++] = (msg->functionId >> 8) & 0xFF;
    msgBuffer[idx++] = (msg->functionId >> 4) & 0xFF;
    msgBuffer[idx++] = (msg->functionId & 0x0F) | (msg->opType << 4);

    // Payload
    memcpy(&msgBuffer[idx], msg->data, msg->dataLength);
    idx += msg->dataLength;

    // Send via asynchronous channel
    return MOST_TransmitAsync(msgBuffer, idx);
}
```

### Network Management
```c
// MOST network master responsibilities
void MOST_MasterTasks(void) {
    static uint32_t lastCheck = 0;
    uint32_t currentTime = GetTickCount();

    // Periodic tasks (every 100ms)
    if (currentTime - lastCheck >= 100) {
        // Check ring stability
        if (!MOST_IsRingLocked()) {
            MOST_ReconfigureRing();
        }

        // Monitor bandwidth utilization
        uint16_t syncUsage = MOST_GetSyncBandwidthUsage();
        uint16_t asyncUsage = MOST_GetAsyncBandwidthUsage();

        if (syncUsage > 90) {
            LogWarning("Sync bandwidth near capacity");
        }

        // Update network topology
        MOST_UpdateNodeList();

        lastCheck = currentTime;
    }
}
```

## Use Case: Premium Infotainment System

### Network Components
```
[Head Unit - Master]
  |
  +-- [Amplifier] (8-channel audio sink)
  +-- [Front Display] (video + control)
  +-- [Rear Display 1] (video + control)
  +-- [Rear Display 2] (video + control)
  +-- [Surround View Camera Hub] (4x video sources)
  +-- [Navigation ECU] (data + control)
  +-- [USB Media Hub]
```

### Bandwidth Allocation (MOST150)
- Synchronous (Audio):
  - 8ch x 48kHz x 24-bit = 1.152 Mbps
- Synchronous (Video):
  - 4x cameras 720p30 H.264 = ~16 Mbps
  - 2x rear displays 1080p60 = ~20 Mbps
- Asynchronous (Control): ~5 Mbps
- Ethernet (Navigation): ~10 Mbps
- **Total**: ~52 Mbps (34% utilization)

### Function Catalog Example
```xml
<FunctionCatalog>
  <Device Name="Amplifier" Address="0x0101">
    <FunctionBlock ID="0x22" Name="AudioAmplifier">
      <Function ID="0x100" Name="SetVolume">
        <Parameter Name="Volume" Type="uint8" Range="0-100"/>
      </Function>
      <Function ID="0x101" Name="SetBalance">
        <Parameter Name="Balance" Type="int8" Range="-50,50"/>
      </Function>
      <Property ID="0x200" Name="CurrentVolume" Type="uint8"/>
      <Property ID="0x201" Name="ChannelStatus" Type="bitfield"/>
    </FunctionBlock>
  </Device>
</FunctionCatalog>
```

## Deliverables

- MOST network design document
- Function catalog (XML)
- Bandwidth allocation spreadsheet
- Node configuration files
- Driver/middleware implementation
- Streaming protocol handlers
- Test specifications
- Timing analysis report

## Common Issues and Solutions

### Ring Instability
- Check optical fiber quality and connectors
- Verify bypass activation in case of node failure
- Monitor light power levels
- Ensure proper grounding for electrical MOST

### Synchronous Streaming Glitches
- Verify clock synchronization
- Check bandwidth oversubscription
- Monitor buffer underruns/overruns
- Validate sample rate conversion

### Control Message Timeouts
- Check asynchronous channel congestion
- Verify message routing tables
- Monitor retry mechanisms
- Validate function block registration

### Audio Quality Issues
- Check for clock drift between source/sink
- Verify bit depth and sample rate matching
- Monitor jitter on synchronous channel
- Validate DSP configuration

## PSI5 Protocol

## Core Competencies

Expert in PSI5 protocol for safety-critical sensor communication in automotive applications.

### Protocol Characteristics
- Bidirectional communication over 2-wire interface
- Current-mode signaling (more robust than voltage)
- Sensor powered via same 2-wire interface
- Synchronous data transmission (time-slot based)
- Built-in sensor diagnostics and monitoring
- Designed for ASIL-D safety applications

### Physical Layer
- 2-wire interface: Power/Data+ and Ground/Data-
- Voltage: 8-18V (nominal 12V)
- Current mode: 5-13 mA for logic levels
- Data rate: 125 kbps or 189 kbps
- Up to 3 sensors per bus
- Cable length: Up to 10 meters

### Communication Modes
- **Mode 1**: Asynchronous sensor data (continuous streaming)
- **Mode 2**: Synchronous time-slot based (typical for airbag)
- **Mode 3**: Bidirectional with ECU command capability

### PSI5 Frame Structure (Mode 2)
```
Sync Pulse (from ECU) triggers sensor transmission
  |
  v
|<-------- Time Slot 1 ------->|<-------- Time Slot 2 ------->|
| Sensor 1 Data | Sensor 2 Data | Sensor 3 Data | ...         |
| Start | Payload | CRC | Stop  | Start | Payload | CRC | Stop |
```

### Data Encoding
- Manchester encoding for clock recovery
- 10-bit or 16-bit data frames
- 2-bit or 3-bit CRC
- Start and stop bits for frame synchronization

## Design Approach

1. Network Planning
   - Define sensor types and count
   - Select PSI5 mode (1, 2, or 3)
   - Calculate time slots and bandwidth
   - Plan power budget

2. ECU Interface Implementation
   - Configure PSI5 transceiver
   - Generate sync pulses
   - Implement time-slot management
   - Decode Manchester-encoded data

3. Safety Mechanisms
   - CRC verification on every frame
   - Timeout monitoring per sensor
   - Plausibility checks on sensor data
   - Diagnostic counter management

4. Validation and Testing
   - Frame timing verification
   - Fault injection testing
   - Power supply variation testing
   - EMC immunity testing

## Implementation Examples

### PSI5 ECU Interface Initialization
```c
// PSI5 configuration
typedef struct {
    uint8_t mode;              // PSI5 mode (1, 2, or 3)
    uint32_t dataRate;         // 125000 or 189000 bps
    uint8_t sensorCount;       // Number of sensors (1-3)
    uint16_t syncPeriodUs;     // Sync pulse period (μs)
    uint16_t timeSlotUs;       // Time slot duration (μs)
    bool diagnosticEnable;     // Enable sensor diagnostics
} PSI5_Config_t;

void PSI5_Init(const PSI5_Config_t* config) {
    // Initialize PSI5 transceiver
    PSI5_TransceiverInit();

    // Configure operating mode
    PSI5_SetMode(config->mode);

    // Set data rate
    PSI5_SetDataRate(config->dataRate);

    // Configure sync pulse generation
    PSI5_ConfigureSyncPulse(config->syncPeriodUs);

    // Configure time slots for Mode 2
    if (config->mode == PSI5_MODE2) {
        for (uint8_t i = 0; i < config->sensorCount; i++) {
            PSI5_ConfigureTimeSlot(
                i,
                i * config->timeSlotUs,
                config->timeSlotUs
            );
        }
    }

    // Enable receiver
    PSI5_EnableReceiver();

    // Start sync pulse generation
    PSI5_StartSyncPulse();
}
```

### Sync Pulse Generation (Mode 2)
```c
// Generate sync pulse to trigger sensor transmissions
void PSI5_GenerateSyncPulse(void) {
    // Sync pulse characteristics:
    // - Current drop from 7mA to 2mA
    // - Duration: ~10 μs
    // - Triggers all sensors to transmit

    // Set low current (sync pulse start)
    PSI5_SetBusCurrent(PSI5_CURRENT_SYNC_LOW);

    // Sync pulse duration (10 μs typical)
    DelayUs(10);

    // Return to normal current
    PSI5_SetBusCurrent(PSI5_CURRENT_NORMAL);

    // Sensors will now transmit in their time slots
    PSI5_StartReception();
}
```

### Manchester Decoder
```c
// Manchester decoder for PSI5 data
typedef struct {
    uint8_t state;             // Decoder state
    uint32_t bitStream;        // Accumulated bits
    uint8_t bitCount;          // Bits decoded
    uint32_t lastEdgeTime;     // Timestamp of last edge
} Manchester_Decoder_t;

static Manchester_Decoder_t decoder = {0};

void PSI5_ProcessEdge(bool rising) {
    uint32_t currentTime = GetMicroseconds();
    uint32_t edgeDelta = currentTime - decoder.lastEdgeTime;

    // Bit period = 1 / dataRate
    // For 125 kbps: 8 μs per bit
    uint32_t bitPeriod = 1000000 / psi5Config.dataRate;
    uint32_t halfBit = bitPeriod / 2;

    // Manchester decoding:
    // Rising edge in middle of bit period = '1'
    // Falling edge in middle of bit period = '0'

    if (edgeDelta > halfBit - 1 && edgeDelta < halfBit + 1) {
        // Edge at half-bit time (mid-bit transition)
        decoder.bitStream <<= 1;

        if (rising) {
            decoder.bitStream |= 1;  // Rising = logic '1'
        }
        // Falling = logic '0' (already shifted in 0)

        decoder.bitCount++;

        // Complete frame? (10 or 16 bits + start/stop)
        if (decoder.bitCount >= 12) {
            PSI5_ProcessFrame(decoder.bitStream, decoder.bitCount);
            decoder.bitCount = 0;
            decoder.bitStream = 0;
        }
    }

    decoder.lastEdgeTime = currentTime;
}
```

### Frame Decoding and CRC Verification
```c
// PSI5 data frame structure
typedef struct {
    bool valid;
    uint8_t sensorId;          // Which sensor (0-2)
    uint16_t data;             // 10 or 16 bits
    uint8_t crc;               // 2 or 3 bits
    bool crcValid;
    uint8_t errorCode;         // Sensor diagnostic code
} PSI5_Frame_t;

void PSI5_ProcessFrame(uint32_t rawFrame, uint8_t bitCount) {
    PSI5_Frame_t frame = {0};

    // Extract start bit
    if (!(rawFrame & (1 << (bitCount - 1)))) {
        LogError("PSI5 missing start bit");
        return;
    }

    // Extract data (10 or 16 bits)
    uint8_t dataLen = (bitCount == 12) ? 10 : 16;
    frame.data = (rawFrame >> 3) & ((1 << dataLen) - 1);

    // Extract CRC (2 or 3 bits)
    uint8_t crcLen = (bitCount == 12) ? 2 : 3;
    frame.crc = (rawFrame >> 1) & ((1 << crcLen) - 1);

    // Extract stop bit
    if (rawFrame & 0x01) {
        LogError("PSI5 missing stop bit");
        return;
    }

    // Verify CRC
    frame.crcValid = PSI5_VerifyCRC(frame.data, dataLen, frame.crc);

    if (frame.crcValid) {
        frame.valid = true;

        // Determine which sensor sent this frame (by time slot)
        frame.sensorId = PSI5_IdentifySensor();

        // Process sensor data
        PSI5_ProcessSensorData(&frame);
    } else {
        LogWarning("PSI5 CRC error");
        PSI5_IncrementErrorCounter(frame.sensorId);
    }
}

// PSI5 CRC calculation (2-bit or 3-bit)
bool PSI5_VerifyCRC(uint16_t data, uint8_t dataLen, uint8_t receivedCRC) {
    uint8_t calculatedCRC;

    if (dataLen == 10) {
        // 2-bit CRC: XOR of bit pairs
        calculatedCRC = 0;
        for (uint8_t i = 0; i < 10; i += 2) {
            calculatedCRC ^= ((data >> i) & 0x03);
        }
        calculatedCRC &= 0x03;
    } else {
        // 3-bit CRC polynomial: x^3 + x + 1
        calculatedCRC = 0;
        for (int8_t i = dataLen - 1; i >= 0; i--) {
            uint8_t bit = (data >> i) & 0x01;
            uint8_t msb = (calculatedCRC >> 2) & 0x01;

            calculatedCRC = ((calculatedCRC << 1) | bit) & 0x07;

            if (msb) {
                calculatedCRC ^= 0x03;  // Polynomial x + 1
            }
        }
    }

    return (calculatedCRC == receivedCRC);
}
```

### Airbag Sensor Data Processing
```c
// Airbag sensor specific processing
typedef struct {
    int16_t acceleration_mg;   // Acceleration in milli-g
    uint8_t temperature;       // Temperature in °C
    uint8_t statusFlags;       // Diagnostic status
    bool sensorOK;
} Airbag_SensorData_t;

void PSI5_ProcessAirbagSensor(const PSI5_Frame_t* frame) {
    Airbag_SensorData_t sensorData = {0};

    // 16-bit data format for airbag sensor:
    // [15:14] - Status flags (2 bits)
    // [13:2]  - Acceleration data (12 bits, signed)
    // [1:0]   - Temperature (2 MSBs)

    // Extract status flags
    sensorData.statusFlags = (frame->data >> 14) & 0x03;

    // Extract acceleration (12-bit signed)
    int16_t rawAccel = (frame->data >> 2) & 0xFFF;

    // Convert to signed (two's complement)
    if (rawAccel & 0x800) {
        rawAccel |= 0xF000;  // Sign extend
    }

    // Convert to milli-g (range: -100g to +100g)
    sensorData.acceleration_mg = (rawAccel * 200000) / 4096;

    // Extract temperature (full value via slow channel)
    sensorData.temperature = (frame->data & 0x03) << 6;

    // Check sensor health
    sensorData.sensorOK = (sensorData.statusFlags == 0);

    // Trigger airbag algorithm
    if (!sensorData.sensorOK) {
        LogError("Airbag sensor %d fault: 0x%02X",
                 frame->sensorId, sensorData.statusFlags);
    }

    Airbag_ProcessAcceleration(
        frame->sensorId,
        sensorData.acceleration_mg
    );
}
```

### Sensor Power Management
```c
// PSI5 provides power to sensors via same 2-wire interface
typedef struct {
    uint16_t voltageSupply_mV; // 8000-18000 mV
    uint16_t currentDraw_mA;   // Per sensor
    uint8_t sensorCount;
    uint16_t totalPower_mW;
} PSI5_PowerBudget_t;

bool PSI5_CheckPowerBudget(PSI5_PowerBudget_t* budget) {
    // Calculate total current
    uint16_t totalCurrent = budget->currentDraw_mA * budget->sensorCount;

    // Add overhead for communication
    totalCurrent += 5;  // 5mA overhead

    // Calculate total power
    budget->totalPower_mW =
        (budget->voltageSupply_mV * totalCurrent) / 1000;

    // Check against ECU capability (typically 200mW per channel)
    if (budget->totalPower_mW > 200) {
        LogError("PSI5 power budget exceeded: %d mW",
                 budget->totalPower_mW);
        return false;
    }

    return true;
}
```

### Diagnostics and Error Handling
```c
// PSI5 sensor diagnostics
typedef struct {
    uint32_t frameCount;       // Total frames received
    uint32_t crcErrors;        // CRC failures
    uint32_t timeoutErrors;    // Missing frames
    uint32_t plausibilityErrors;
    float errorRate;
    bool sensorConnected;
} PSI5_SensorDiag_t;

static PSI5_SensorDiag_t sensorDiag[3] = {0};

void PSI5_MonitorSensor(uint8_t sensorId) {
    PSI5_SensorDiag_t* diag = &sensorDiag[sensorId];

    // Check for timeout (no frame in last 10ms)
    uint32_t timeSinceFrame = GetMicroseconds() - lastFrameTime[sensorId];

    if (timeSinceFrame > 10000) {
        diag->timeoutErrors++;
        diag->sensorConnected = false;
        LogError("PSI5 sensor %d timeout", sensorId);
    } else {
        diag->sensorConnected = true;
    }

    // Calculate error rate
    if (diag->frameCount > 0) {
        diag->errorRate =
            (float)(diag->crcErrors + diag->plausibilityErrors) /
            (float)diag->frameCount;
    }

    // Report diagnostics to safety monitor
    if (diag->errorRate > 0.01) {  // 1% threshold
        Airbag_ReportSensorFault(
            sensorId,
            AIRBAG_FAULT_HIGH_ERROR_RATE
        );
    }

    if (!diag->sensorConnected) {
        Airbag_ReportSensorFault(
            sensorId,
            AIRBAG_FAULT_SENSOR_DISCONNECTED
        );
    }
}
```

## Use Case: Multi-Sensor Airbag System

### System Architecture
```
Airbag ECU (PSI5 Master)
  |
  +-- Front Left Sensor (Acceleration + Pressure)
  +-- Front Right Sensor (Acceleration + Pressure)
  +-- Side Impact Sensor (Acceleration)
```

### Configuration
- Mode: PSI5 Mode 2 (synchronous time slots)
- Data rate: 189 kbps
- Sync period: 1 ms (1000 Hz update rate)
- Time slot: 250 μs per sensor
- Frame format: 16-bit data + 3-bit CRC

### Time Slot Allocation
| Time (μs) | Sensor       | Data Content                    |
|-----------|--------------|----------------------------------|
| 0-10      | Sync Pulse   | Triggers all sensors            |
| 10-260    | Sensor 1     | Front left acceleration/pressure|
| 260-510   | Sensor 2     | Front right accel/pressure      |
| 510-760   | Sensor 3     | Side impact acceleration        |
| 760-1000  | Idle         | Processing time                 |

### Safety Requirements (ASIL-D)
- CRC verification on every frame
- Timeout detection (<2ms)
- Dual-sensor voting for critical decisions
- Continuous self-test of communication
- Diagnostic counters reported to safety manager

## Deliverables

- PSI5 network design specification
- ECU interface implementation (C code)
- Sensor calibration data
- Safety analysis (FMEA)
- Integration test specifications
- Timing verification report
- EMC test results

## Common Issues and Solutions

### Frame Synchronization Loss
- Verify sync pulse timing and amplitude
- Check current mode signaling levels
- Ensure proper Manchester encoding
- Validate time slot configuration

### CRC Errors
- Check for EMI on sensor wiring
- Verify power supply stability
- Improve cable shielding/routing
- Validate CRC algorithm implementation

### Sensor Timeout
- Check sensor power supply voltage
- Verify 2-wire connection integrity
- Monitor current consumption
- Test sensor at temperature extremes

### Data Plausibility Issues
- Validate sensor calibration
- Check for mechanical mounting issues
- Verify sign bit interpretation
- Compare with other sensors (voting)

## SENT Protocol

## Core Competencies

Expert in SENT protocol for cost-effective digital sensor communication.

### Protocol Characteristics
- Single-wire unidirectional communication (sensor to ECU)
- No clock signal required (self-clocking)
- Built-in CRC for error detection
- Support for slow channel (configuration/diagnostics)
- Low electromagnetic emissions
- Typical tick time: 3 μs (333 kHz)

### Physical Layer
- Voltage levels: 0V (low) / 5V (high)
- Current mode: 0-20 mA or voltage mode
- Single wire + ground reference
- Operating temperature: -40°C to +150°C
- Low power consumption: <10 mW typical

### Frame Structure
```
|<----------- SENT Frame ------------>|
| Sync | Status | Data1-6 | CRC | Pause |
| 56T  | 4b+4b  | 6x12b   | 4b  | ≥12T  |
```

- Sync pulse: 56 nominal tick periods (±25%)
- Status nibble: 4 bits (sensor status/diagnostic)
- Data nibbles: Up to 6 nibbles (12-24 bits total data)
- CRC: 4-bit checksum
- Pause period: Variable (min 12 ticks)

### SENT Frame Types
- **Fast Channel**: Main sensor data (every frame)
- **Slow Channel**: Configuration/diagnostic data (transmitted over multiple frames)
- **Short Serial Message (SSM)**: Enhanced diagnostic data

### Tick Encoding
- Each nibble encoded as pulse width (12-27 ticks)
- Nibble value 0: 12 ticks
- Nibble value 1: 13 ticks
- ...
- Nibble value 15: 27 ticks

## Design Approach

1. Sensor Integration
   - Select appropriate SENT-capable sensor
   - Configure tick frequency
   - Define data format (12/16/24 bit)
   - Plan slow channel usage

2. ECU Receiver Implementation
   - Configure input capture timer
   - Implement edge detection
   - Decode nibbles from pulse widths
   - Verify CRC and status

3. Data Processing
   - Apply sensor calibration
   - Handle error conditions
   - Monitor diagnostic data
   - Implement plausibility checks

4. Validation and Testing
   - Verify tick timing accuracy
   - Inject bit errors for CRC validation
   - Test temperature extremes
   - Validate EMC immunity

## Implementation Examples

### SENT Receiver Initialization
```c
// SENT receiver configuration
typedef struct {
    uint32_t tickTimeNs;       // Nominal tick time (ns)
    uint8_t tickTolerance;     // Tolerance percentage (±25%)
    uint8_t dataNibbles;       // Number of data nibbles (1-6)
    bool slowChannelEnable;    // Enable slow channel decode
    bool pauseValidation;      // Validate pause pulse
} SENT_Config_t;

void SENT_Init(const SENT_Config_t* config) {
    // Configure input capture timer
    // Timer resolution should be <100ns for accurate tick measurement
    TIM_SetPrescaler(config->tickTimeNs / 100);  // 100ns resolution

    // Configure edge detection (falling edge)
    TIM_SetCaptureEdge(TIM_CAPTURE_FALLING);

    // Enable input capture interrupt
    TIM_EnableCaptureInterrupt();

    // Store configuration
    sentConfig = *config;

    // Reset decoder state
    SENT_ResetDecoder();
}
```

### SENT Frame Decoding
```c
// SENT frame structure
typedef struct {
    bool valid;
    uint8_t status;            // Status nibble
    uint32_t data;             // Combined data nibbles
    uint8_t crc;
    bool crcValid;
    uint16_t errorCount;
} SENT_Frame_t;

// State machine for SENT decoding
typedef enum {
    SENT_STATE_WAIT_SYNC,
    SENT_STATE_STATUS,
    SENT_STATE_DATA,
    SENT_STATE_CRC,
    SENT_STATE_PAUSE
} SENT_State_t;

static SENT_State_t sentState = SENT_STATE_WAIT_SYNC;
static uint32_t lastEdgeTime = 0;
static uint8_t nibbleIndex = 0;
static SENT_Frame_t currentFrame;

// Input capture interrupt handler
void TIM_CaptureInterrupt(void) {
    uint32_t currentTime = TIM_GetCaptureValue();
    uint32_t pulseTicks = (currentTime - lastEdgeTime) / sentConfig.tickTimeNs;
    lastEdgeTime = currentTime;

    switch (sentState) {
        case SENT_STATE_WAIT_SYNC:
            // Sync pulse is 56 ticks ±25%
            if (pulseTicks >= 42 && pulseTicks <= 70) {
                // Sync detected, calibrate tick time
                uint32_t measuredTickTime =
                    (currentTime - lastEdgeTime) / 56;
                SENT_UpdateTickTime(measuredTickTime);

                sentState = SENT_STATE_STATUS;
                nibbleIndex = 0;
                currentFrame.valid = false;
                currentFrame.errorCount = 0;
            }
            break;

        case SENT_STATE_STATUS:
            // Decode status nibble
            currentFrame.status = SENT_DecodeNibble(pulseTicks);
            sentState = SENT_STATE_DATA;
            nibbleIndex = 0;
            break;

        case SENT_STATE_DATA:
            // Decode data nibbles
            uint8_t nibble = SENT_DecodeNibble(pulseTicks);

            if (nibble == 0xFF) {  // Invalid nibble
                currentFrame.errorCount++;
                sentState = SENT_STATE_WAIT_SYNC;
                break;
            }

            // Accumulate data nibbles
            currentFrame.data |= ((uint32_t)nibble << (nibbleIndex * 4));
            nibbleIndex++;

            // All data nibbles received?
            if (nibbleIndex >= sentConfig.dataNibbles) {
                sentState = SENT_STATE_CRC;
            }
            break;

        case SENT_STATE_CRC:
            // Decode and verify CRC
            currentFrame.crc = SENT_DecodeNibble(pulseTicks);
            currentFrame.crcValid = SENT_VerifyCRC(&currentFrame);

            if (currentFrame.crcValid) {
                currentFrame.valid = true;
                SENT_ProcessFrame(&currentFrame);
            } else {
                currentFrame.errorCount++;
            }

            sentState = SENT_STATE_PAUSE;
            break;

        case SENT_STATE_PAUSE:
            // Wait for pause period (≥12 ticks)
            if (pulseTicks >= 12) {
                sentState = SENT_STATE_WAIT_SYNC;
            }
            break;
    }
}

// Decode nibble from pulse width
uint8_t SENT_DecodeNibble(uint32_t pulseTicks) {
    // Nibble value = pulseTicks - 12
    if (pulseTicks >= 12 && pulseTicks <= 27) {
        return pulseTicks - 12;
    }
    return 0xFF;  // Invalid
}
```

### CRC Calculation (SAE J2716)
```c
// SENT CRC-4 calculation (recommended checksum)
uint8_t SENT_CalculateCRC(const SENT_Frame_t* frame) {
    uint8_t nibbles[8];
    nibbles[0] = frame->status & 0x0F;

    // Extract data nibbles
    for (uint8_t i = 0; i < sentConfig.dataNibbles; i++) {
        nibbles[i + 1] = (frame->data >> (i * 4)) & 0x0F;
    }

    // CRC-4 with seed value 5
    uint8_t crc = 5;

    for (uint8_t i = 0; i < sentConfig.dataNibbles + 1; i++) {
        crc ^= nibbles[i];

        for (uint8_t bit = 0; bit < 4; bit++) {
            if (crc & 0x08) {
                crc = ((crc << 1) ^ 0x13) & 0x0F;
            } else {
                crc = (crc << 1) & 0x0F;
            }
        }
    }

    return crc;
}

bool SENT_VerifyCRC(const SENT_Frame_t* frame) {
    uint8_t calculatedCRC = SENT_CalculateCRC(frame);
    return (calculatedCRC == frame->crc);
}
```

### Slow Channel Decoding
```c
// Slow channel transmitted over multiple frames
typedef struct {
    uint8_t messageId;         // 8-bit message identifier
    uint16_t data;             // 12-bit data value
    bool valid;
} SENT_SlowChannel_t;

static uint8_t slowChannelNibbles[6];
static uint8_t slowChannelIndex = 0;

void SENT_DecodeSlowChannel(uint8_t statusNibble) {
    // Slow channel data is in status nibble bits
    uint8_t slowNibble = (statusNibble >> 2) & 0x03;  // 2 bits per frame

    slowChannelNibbles[slowChannelIndex++] = slowNibble;

    // Complete slow channel message after 16 frames
    if (slowChannelIndex >= 16) {
        SENT_SlowChannel_t slowMsg;

        // Reconstruct 8-bit message ID
        slowMsg.messageId = 0;
        for (uint8_t i = 0; i < 4; i++) {
            slowMsg.messageId |= (slowChannelNibbles[i] << (i * 2));
        }

        // Reconstruct 12-bit data
        slowMsg.data = 0;
        for (uint8_t i = 0; i < 6; i++) {
            slowMsg.data |= (slowChannelNibbles[i + 4] << (i * 2));
        }

        // Validate slow channel CRC
        slowMsg.valid = SENT_VerifySlowChannelCRC(&slowMsg);

        if (slowMsg.valid) {
            SENT_ProcessSlowChannel(&slowMsg);
        }

        slowChannelIndex = 0;
    }
}
```

### Sensor Data Conversion
```c
// Convert raw SENT data to physical value
typedef struct {
    float gain;                // Scaling factor
    float offset;              // Offset value
    uint8_t resolution;        // Bits (12, 16, 24)
    const char* unit;          // Unit string
} SENT_Calibration_t;

float SENT_ConvertToPhysical(
    uint32_t rawData,
    const SENT_Calibration_t* cal
) {
    // Calculate maximum raw value based on resolution
    uint32_t maxRaw = (1 << cal->resolution) - 1;

    // Linear conversion: Physical = (Raw / MaxRaw) * Gain + Offset
    float normalized = (float)rawData / (float)maxRaw;
    float physical = (normalized * cal->gain) + cal->offset;

    return physical;
}

// Example: Temperature sensor
void SENT_ProcessTemperatureSensor(const SENT_Frame_t* frame) {
    static const SENT_Calibration_t tempCal = {
        .gain = 200.0,         // -40°C to +160°C range
        .offset = -40.0,
        .resolution = 12,
        .unit = "°C"
    };

    // Extract 12-bit data (first 3 nibbles)
    uint32_t rawTemp = frame->data & 0xFFF;

    // Convert to physical value
    float temperature = SENT_ConvertToPhysical(rawTemp, &tempCal);

    // Check status nibble for sensor faults
    if (frame->status & 0x08) {
        LogWarning("Temperature sensor fault detected");
    }

    LogInfo("Temperature: %.1f %s", temperature, tempCal.unit);
}
```

### Error Detection and Handling
```c
// SENT error statistics
typedef struct {
    uint32_t totalFrames;
    uint32_t crcErrors;
    uint32_t timingErrors;
    uint32_t statusWarnings;
    float errorRate;
} SENT_Statistics_t;

static SENT_Statistics_t sentStats = {0};

void SENT_ProcessFrame(const SENT_Frame_t* frame) {
    sentStats.totalFrames++;

    // Check CRC
    if (!frame->crcValid) {
        sentStats.crcErrors++;
        LogWarning("SENT CRC error");
        return;
    }

    // Check status nibble for sensor warnings
    if (frame->status & 0x08) {
        sentStats.statusWarnings++;
        // Handle specific error codes
        switch (frame->status & 0x07) {
            case 0x1: LogWarning("Sensor temperature out of range"); break;
            case 0x2: LogWarning("Sensor calibration error"); break;
            case 0x3: LogWarning("Sensor hardware fault"); break;
            default:  LogWarning("Unknown sensor status"); break;
        }
    }

    // Calculate error rate
    sentStats.errorRate = (float)(sentStats.crcErrors + sentStats.timingErrors) /
                         (float)sentStats.totalFrames;

    // Trigger diagnostic if error rate too high
    if (sentStats.errorRate > 0.01) {  // 1% threshold
        LogError("SENT error rate too high: %.2f%%", sentStats.errorRate * 100);
    }
}
```

## Use Case: Throttle Position Sensor

### Sensor Configuration
- Tick frequency: 333 kHz (3 μs tick time)
- Data format: 12-bit position (0-4095)
- Range: 0° to 90° throttle angle
- Update rate: 1 kHz (1000 frames/sec)
- Slow channel: Temperature and diagnostics

### Data Frame Format
```
Status nibble: [Error | Reserved | SlowBit1 | SlowBit0]
Data nibbles:  [Position[11:8] | Position[7:4] | Position[3:0]]
```

### Safety Features
- CRC-4 checksum on every frame
- Status nibble indicates sensor health
- Plausibility check against expected range
- Timeout detection (missing frames)
- Slow channel for temperature monitoring

### Example Application Code
```c
// Throttle position sensor handler
void Application_ProcessThrottle(const SENT_Frame_t* frame) {
    if (!frame->valid) return;

    // Extract 12-bit position
    uint16_t rawPosition = frame->data & 0xFFF;

    // Convert to angle (0-90°)
    float angle = (float)rawPosition / 4095.0 * 90.0;

    // Plausibility check
    if (angle > 95.0) {
        LogError("Throttle position implausible: %.1f°", angle);
        return;
    }

    // Update throttle position
    SetThrottlePosition(angle);

    // Process slow channel (every 16 frames)
    SENT_DecodeSlowChannel(frame->status);
}
```

## Deliverables

- SENT sensor selection guide
- Receiver implementation (C code)
- Calibration data format
- Error handling strategy
- Integration test specifications
- Signal timing verification
- EMC test results

## Common Issues and Solutions

### Tick Time Drift
- Monitor sync pulse for tick calibration
- Compensate for temperature effects
- Verify sensor clock stability
- Use adaptive tick time measurement

### CRC Failures
- Check for EMI/noise on signal line
- Verify ground connection quality
- Add low-pass filter on input
- Shield sensor cable if necessary

### Missing Frames
- Check sensor power supply stability
- Verify interrupt priority and latency
- Monitor for software blocking
- Validate pause period handling

### Incorrect Data Values
- Verify nibble decoding algorithm
- Check data byte order/endianness
- Validate calibration parameters
- Test with known sensor inputs
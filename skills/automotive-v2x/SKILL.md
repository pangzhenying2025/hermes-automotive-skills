---
name: automotive-v2x
description: >
  Automotive V2X expertise. Covers 6 topics: Cv2X 5G Integration, V2I Infrastructure, V2V Safety Applications, V2X Protocols Standards, V2X Security Certificates.
tags: [automotive, automotive-v2x]
---

# Automotive V2X

## Cv2X 5G Integration

# C-V2X and 5G Integration

## Overview
C-V2X (Cellular V2X) integration with 5G networks including PC5 sidelink communication modes, network slicing, Multi-access Edge Computing (MEC), Ultra-Reliable Low-Latency Communication (URLLC), and 5G NR V2X features.

## C-V2X Communication Modes

### Mode 3 vs Mode 4 Comparison

| Feature | Mode 3 (Network Scheduled) | Mode 4 (Autonomous/D2D) |
|---------|---------------------------|------------------------|
| Infrastructure Required | Yes (eNodeB/gNodeB) | No (direct sidelink) |
| Resource Allocation | Network-scheduled (centralized) | Distributed sensing |
| Coverage Dependency | Requires cellular coverage | Works without network |
| Typical Latency | 20-50 ms (via network) | 10-20 ms (direct) |
| QoS Guarantee | Network-enforced QoS | Best-effort coordination |
| Ideal Use Case | Urban with good coverage | Rural, tunnels, emergencies |
| Handover | Network-managed | Autonomous |
| Power Consumption | Higher (constant network sync) | Lower (periodic only) |

### 5G NR-V2X Physical Layer

**Frequency Bands:**
```
5.9 GHz ITS Band:
- 5.855-5.925 GHz (US, EU, Asia harmonized)
- Channel bandwidth: 10/20 MHz
- Supports both DSRC coexistence and C-V2X

Licensed Spectrum:
- Band n78 (3.5 GHz): High capacity urban
- Band n79 (4.7 GHz): Regional deployments
- Mmwave (28/39 GHz): Ultra-high data rate applications
```

**Numerology:**
```
Subcarrier spacing: 15/30/60 kHz
- 15 kHz: Long range, low mobility
- 30 kHz: Standard V2X (recommended)
- 60 kHz: High mobility scenarios

Symbol duration: 66.7/33.3/16.7 μs
Cyclic prefix: 4.7/2.3/1.2 μs
```

## Network Slicing for V2X

### Slice Configuration

```python
# network_slicing.py
"""
5G Network slicing for differentiated V2X services.
"""

from dataclasses import dataclass
from enum import Enum
from typing import List

class SliceServiceType(Enum):
    """Service and Slice Differentiator (SST)"""
    URLLC = 1  # Ultra-reliable low-latency
    EMBB = 2   # Enhanced mobile broadband
    MMTC = 3   # Massive machine-type communications

@dataclass
class NetworkSliceDescriptor:
    """5G Network Slice Selection Assistance Information (NSSAI)"""
    sst: SliceServiceType  # Slice/Service Type
    sd: int  # Slice Differentiator (24 bits)

    # Performance KPIs
    target_latency_ms: int
    reliability_percent: float
    max_data_rate_mbps: int
    connection_density_per_km2: int

    # Resource allocation
    guaranteed_bit_rate_mbps: int
    priority_level: int  # 1 (highest) to 15 (lowest)

# V2V Safety Communications Slice
SLICE_V2V_SAFETY = NetworkSliceDescriptor(
    sst=SliceServiceType.URLLC,
    sd=0x000001,  # V2V safety specific
    target_latency_ms=5,
    reliability_percent=99.9999,  # Six nines
    max_data_rate_mbps=10,
    connection_density_per_km2=10000,
    guaranteed_bit_rate_mbps=2,
    priority_level=1
)

# V2I Traffic Management Slice
SLICE_V2I_TRAFFIC = NetworkSliceDescriptor(
    sst=SliceServiceType.URLLC,
    sd=0x000002,
    target_latency_ms=20,
    reliability_percent=99.99,
    max_data_rate_mbps=5,
    connection_density_per_km2=5000,
    guaranteed_bit_rate_mbps=1,
    priority_level=3
)

# V2N Infotainment Slice
SLICE_V2N_INFOTAINMENT = NetworkSliceDescriptor(
    sst=SliceServiceType.EMBB,
    sd=0x000003,
    target_latency_ms=100,
    reliability_percent=99.0,
    max_data_rate_mbps=100,
    connection_density_per_km2=1000,
    guaranteed_bit_rate_mbps=10,
    priority_level=10
)

class NetworkSliceManager:
    """Manage network slice selection for V2X traffic."""

    def __init__(self):
        self.available_slices = [
            SLICE_V2V_SAFETY,
            SLICE_V2I_TRAFFIC,
            SLICE_V2N_INFOTAINMENT
        ]
        self.current_slice = None

    def select_slice_for_message(self, message_type: str, qos_requirement: str) -> NetworkSliceDescriptor:
        """
        Select appropriate network slice based on message type and QoS.

        Args:
            message_type: "BSM", "DENM", "CAM", "SPaT", "MAP", etc.
            qos_requirement: "critical", "high", "medium", "low"

        Returns:
            NetworkSliceDescriptor
        """
        # Safety-critical messages
        if message_type in ["BSM", "CAM", "DENM", "EEBL"] or qos_requirement == "critical":
            return SLICE_V2V_SAFETY

        # Infrastructure messages
        elif message_type in ["SPaT", "MAP", "TIM"] or qos_requirement == "high":
            return SLICE_V2I_TRAFFIC

        # Non-critical services
        else:
            return SLICE_V2N_INFOTAINMENT

    def request_slice_activation(self, nssai: NetworkSliceDescriptor) -> bool:
        """
        Request slice activation from 5G core.

        In production: NGAP signaling to AMF (Access and Mobility Management Function)
        """
        print(f"Requesting slice activation:")
        print(f"  SST: {nssai.sst.name}")
        print(f"  SD: {nssai.sd:#08x}")
        print(f"  Latency: {nssai.target_latency_ms} ms")
        print(f"  Reliability: {nssai.reliability_percent}%")

        # Simulate AMF response
        self.current_slice = nssai
        return True
```

## Multi-access Edge Computing (MEC)

### MEC Architecture for V2X

```
┌─────────────────────────────────────────────────────┐
│              5G Core Network (5GC)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │   AMF    │  │   SMF    │  │      UPF         │  │
│  │ (Access) │  │ (Session)│  │ (User Plane)     │  │
│  └──────────┘  └──────────┘  └────────┬─────────┘  │
└──────────────────────────────────────────┼──────────┘
                                          │
        ┌─────────────────────────────────┼───────────────┐
        │          MEC Platform           │               │
        │  ┌──────────────────────────────▼────────────┐ │
        │  │  MEC Host (Co-located with gNodeB)        │ │
        │  │                                            │ │
        │  │  ┌────────────┐    ┌─────────────────┐   │ │
        │  │  │ V2X Server │    │ CPM Fusion      │   │ │
        │  │  │ (SPaT/MAP) │    │ Service         │   │ │
        │  │  └────────────┘    └─────────────────┘   │ │
        │  │                                            │ │
        │  │  ┌────────────┐    ┌─────────────────┐   │ │
        │  │  │ GLOSA      │    │ Misbehavior     │   │ │
        │  │  │ Calculator │    │ Detection       │   │ │
        │  │  └────────────┘    └─────────────────┘   │ │
        │  └────────────────────────────────────────── │ │
        └──────────────────────────────────────────────┘ │
                            │
        ┌───────────────────┼───────────────────────┐
        │                   ▼                       │
        │         ┌──────────────────┐              │
        │         │    gNodeB 5G     │              │
        │         │   Base Station   │              │
        │         └────────┬─────────┘              │
        │                  │                        │
        │    ┌─────────────┼─────────────┐          │
        │    │             │             │          │
        │    ▼             ▼             ▼          │
        │  Vehicle      Vehicle      Vehicle        │
        │  (UE)         (UE)         (UE)          │
        └──────────────────────────────────────────┘
```

### MEC Application: Collective Perception Fusion

```python
# mec_cpm_fusion.py
"""
MEC-based Collective Perception Message fusion service.
Aggregates CPMs from multiple vehicles for enhanced situational awareness.
"""

import time
from dataclasses import dataclass
from typing import List, Dict, Set
import math

@dataclass
class PerceivedObject:
    """Object detected by vehicle sensor."""
    object_id: int
    object_type: str  # "vehicle", "pedestrian", "cyclist"
    x_position_m: float
    y_position_m: float
    velocity_x_mps: float
    velocity_y_mps: float
    confidence: float
    source_vehicle_id: int
    timestamp_ms: int

@dataclass
class FusedObject:
    """Fused object from multiple vehicle observations."""
    fused_id: int
    object_type: str
    x_position_m: float
    y_position_m: float
    velocity_x_mps: float
    velocity_y_mps: float
    confidence: float
    contributing_vehicles: Set[int]
    last_update_ms: int

class MECCPMFusionService:
    """
    MEC service for fusing Collective Perception Messages.
    Runs at edge computing node near base station.
    """

    def __init__(self, fusion_radius_m: float = 500.0):
        self.fusion_radius = fusion_radius_m
        self.perceived_objects: Dict[int, PerceivedObject] = {}
        self.fused_objects: Dict[int, FusedObject] = {}
        self.next_fused_id = 1

    def ingest_cpm(self, vehicle_id: int, objects: List[PerceivedObject]):
        """
        Ingest CPM from vehicle.

        Args:
            vehicle_id: Source vehicle ID
            objects: List of perceived objects
        """
        current_time = int(time.time() * 1000)

        for obj in objects:
            obj.source_vehicle_id = vehicle_id
            obj.timestamp_ms = current_time

            # Store in perceived objects
            key = (vehicle_id, obj.object_id)
            self.perceived_objects[key] = obj

        # Trigger fusion
        self.fuse_perceptions()

    def fuse_perceptions(self):
        """
        Fuse perceived objects from multiple vehicles.
        Uses spatial clustering and Kalman filter fusion.
        """
        current_time = int(time.time() * 1000)

        # Remove stale observations (> 1 second old)
        stale_keys = [k for k, v in self.perceived_objects.items()
                     if current_time - v.timestamp_ms > 1000]
        for key in stale_keys:
            del self.perceived_objects[key]

        # Group objects by proximity
        ungrouped = list(self.perceived_objects.values())
        fused_groups = []

        while ungrouped:
            seed = ungrouped.pop(0)
            group = [seed]

            # Find nearby objects
            i = 0
            while i < len(ungrouped):
                obj = ungrouped[i]
                if self._are_same_object(seed, obj):
                    group.append(ungrouped.pop(i))
                else:
                    i += 1

            fused_groups.append(group)

        # Create fused objects
        self.fused_objects.clear()
        for group in fused_groups:
            fused = self._fuse_group(group)
            self.fused_objects[fused.fused_id] = fused

    def _are_same_object(self, obj1: PerceivedObject, obj2: PerceivedObject) -> bool:
        """Determine if two perceived objects are the same physical object."""
        # Distance threshold (3 meters)
        distance = math.sqrt(
            (obj1.x_position_m - obj2.x_position_m)**2 +
            (obj1.y_position_m - obj2.y_position_m)**2
        )

        if distance > 3.0:
            return False

        # Type must match
        if obj1.object_type != obj2.object_type:
            return False

        # Velocity similarity (5 m/s threshold)
        vel_diff = math.sqrt(
            (obj1.velocity_x_mps - obj2.velocity_x_mps)**2 +
            (obj1.velocity_y_mps - obj2.velocity_y_mps)**2
        )

        if vel_diff > 5.0:
            return False

        return True

    def _fuse_group(self, group: List[PerceivedObject]) -> FusedObject:
        """Fuse group of observations into single object."""
        # Weighted average by confidence
        total_weight = sum(obj.confidence for obj in group)

        x_fused = sum(obj.x_position_m * obj.confidence for obj in group) / total_weight
        y_fused = sum(obj.y_position_m * obj.confidence for obj in group) / total_weight
        vx_fused = sum(obj.velocity_x_mps * obj.confidence for obj in group) / total_weight
        vy_fused = sum(obj.velocity_y_mps * obj.confidence for obj in group) / total_weight

        # Confidence increases with multiple observations
        confidence_fused = min(1.0, sum(obj.confidence for obj in group) / len(group) * 1.2)

        fused = FusedObject(
            fused_id=self.next_fused_id,
            object_type=group[0].object_type,
            x_position_m=x_fused,
            y_position_m=y_fused,
            velocity_x_mps=vx_fused,
            velocity_y_mps=vy_fused,
            confidence=confidence_fused,
            contributing_vehicles={obj.source_vehicle_id for obj in group},
            last_update_ms=max(obj.timestamp_ms for obj in group)
        )

        self.next_fused_id += 1
        return fused

    def get_fused_objects_for_region(self, center_x: float, center_y: float,
                                    radius_m: float) -> List[FusedObject]:
        """
        Get fused objects within a region.
        Used to send enhanced CPM to vehicles in area.
        """
        result = []
        for fused in self.fused_objects.values():
            distance = math.sqrt(
                (fused.x_position_m - center_x)**2 +
                (fused.y_position_m - center_y)**2
            )
            if distance <= radius_m:
                result.append(fused)

        return result


# Example usage
if __name__ == "__main__":
    mec_service = MECCPMFusionService()

    # Vehicle 1 reports object
    obj1 = PerceivedObject(
        object_id=1,
        object_type="vehicle",
        x_position_m=100.0,
        y_position_m=50.0,
        velocity_x_mps=15.0,
        velocity_y_mps=0.0,
        confidence=0.85,
        source_vehicle_id=1,
        timestamp_ms=0
    )

    # Vehicle 2 reports same object (slightly different position)
    obj2 = PerceivedObject(
        object_id=1,
        object_type="vehicle",
        x_position_m=101.5,
        y_position_m=50.5,
        velocity_x_mps=14.8,
        velocity_y_mps=0.2,
        confidence=0.80,
        source_vehicle_id=2,
        timestamp_ms=0
    )

    # Ingest CPMs
    mec_service.ingest_cpm(1, [obj1])
    mec_service.ingest_cpm(2, [obj2])

    # Get fused result
    fused_objects = mec_service.get_fused_objects_for_region(100.0, 50.0, 200.0)

    print(f"Fused {len(fused_objects)} objects:")
    for obj in fused_objects:
        print(f"  ID={obj.fused_id}, Type={obj.object_type}, "
              f"Pos=({obj.x_position_m:.1f}, {obj.y_position_m:.1f}), "
              f"Confidence={obj.confidence:.2f}, "
              f"Sources={obj.contributing_vehicles}")
```

## URLLC (Ultra-Reliable Low-Latency Communication)

### URLLC Techniques for V2X

```
Packet Duplication (PDCP):
- Transmit same packet on multiple paths
- Diversity: PC5 + Uu interface
- Latency reduction: 20-30%

Mini-slot Scheduling:
- Sub-millisecond TTI (Transmission Time Interval)
- Reduced latency: 2-4 ms vs 14 ms (LTE)

Grant-free Transmission:
- Pre-configured resources for V2X
- No scheduling request overhead
- Latency: < 10 ms

Edge Computing (MEC):
- Process data locally at base station
- Avoid core network round-trip
- Latency reduction: 40-50 ms
```

## C-V2X Coexistence with DSRC

```python
# cv2x_dsrc_coexistence.py
"""
C-V2X and DSRC coexistence strategies.
"""

class CoexistenceMode(Enum):
    DSRC_ONLY = 1
    CV2X_ONLY = 2
    DUAL_MODE = 3  # Both technologies
    HYBRID_MODE = 4  # Adaptive selection

class V2XRadioManager:
    """Manage dual-mode V2X radio (DSRC + C-V2X)."""

    def __init__(self, mode: CoexistenceMode):
        self.mode = mode
        self.dsrc_active = False
        self.cv2x_active = False

    def select_technology(self, message_type: str, network_available: bool) -> str:
        """
        Select appropriate V2X technology.

        Strategy:
        - Safety messages: DSRC (if dual-mode) for low latency
        - Network services: C-V2X Mode 3
        - No network: DSRC or C-V2X Mode 4
        """
        if self.mode == CoexistenceMode.DSRC_ONLY:
            return "DSRC"
        elif self.mode == CoexistenceMode.CV2X_ONLY:
            return "C-V2X"
        elif self.mode == CoexistenceMode.DUAL_MODE:
            # Broadcast on both for safety messages
            if message_type in ["BSM", "DENM", "EEBL"]:
                return "BOTH"
            elif network_available:
                return "C-V2X"
            else:
                return "DSRC"
        else:  # HYBRID_MODE
            if network_available and message_type not in ["BSM", "CAM"]:
                return "C-V2X"
            else:
                return "DSRC"
```

## References

1. **3GPP TS 22.186**: Enhancement of 3GPP support for V2X scenarios
2. **3GPP TS 23.287**: Architecture enhancements for 5G System (5GS) to support Vehicle-to-Everything (V2X) services
3. **5GAA**: C-V2X Use Cases and Service Level Requirements
4. **ETSI EN 303 613**: LTE-V2X; User Equipment (UE) radio transmission and reception

---

## V2I Infrastructure

# V2I Infrastructure

## Overview
Comprehensive guide to Vehicle-to-Infrastructure (V2I) communication including Roadside Unit (RSU) deployment, Signal Phase and Timing (SPaT), MAP messages, traffic light optimization, parking availability, and work zone warnings.

## Roadside Unit (RSU) Architecture

### RSU Hardware Components

```
┌─────────────────────────────────────────────────────────┐
│                  Roadside Unit (RSU)                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌────────────────┐         ┌─────────────────────┐    │
│  │  DSRC/C-V2X    │         │   GPS/GNSS          │    │
│  │  Radio Module  │         │   Receiver          │    │
│  │  (5.9 GHz)     │         │                     │    │
│  └────────┬───────┘         └──────────┬──────────┘    │
│           │                            │                │
│           └──────────┬─────────────────┘                │
│                      │                                  │
│           ┌──────────▼────────────┐                     │
│           │   Main Processor      │                     │
│           │   (ARM / x86)         │                     │
│           │   - Message encoding  │                     │
│           │   - Security (1609.2) │                     │
│           │   - Application logic │                     │
│           └──────────┬────────────┘                     │
│                      │                                  │
│      ┌───────────────┼───────────────┐                  │
│      │               │               │                  │
│      ▼               ▼               ▼                  │
│  ┌────────┐    ┌─────────┐    ┌──────────┐            │
│  │Ethernet│    │  CAN    │    │ Serial   │            │
│  │  Port  │    │  Bus    │    │  Port    │            │
│  └───┬────┘    └────┬────┘    └────┬─────┘            │
│      │              │              │                    │
└──────┼──────────────┼──────────────┼────────────────────┘
       │              │              │
       ▼              ▼              ▼
┌──────────┐   ┌───────────┐  ┌──────────────┐
│ Traffic  │   │ Traffic   │  │ Other Sensors│
│ Control  │   │ Camera    │  │ (radar, etc.)│
│ Cabinet  │   │           │  │              │
└──────────┘   └───────────┘  └──────────────┘
```

### RSU Specifications

| Parameter | DSRC RSU | C-V2X RSU |
|-----------|----------|-----------|
| Transmit power | 20-33 dBm | 23 dBm |
| Range | 300-1000 m | 500-1500 m |
| Antenna gain | 5-9 dBi | 8 dBi |
| Operating temp | -40°C to +75°C | -40°C to +85°C |
| Message rate | 10 Hz (BSM), 1 Hz (MAP) | Configurable |
| Latency | < 50 ms | < 100 ms |
| Power consumption | 20-40 W | 30-50 W |

## Signal Phase and Timing (SPaT)

### SPaT Message Format (SAE J2735)

```asn1
-- SAE J2735 SPaT Message
SPAT ::= SEQUENCE {
    timeStamp MinuteOfTheYear OPTIONAL,
    name DescriptiveName OPTIONAL,
    intersections IntersectionStateList,
    regional SEQUENCE (SIZE(1..4)) OF RegionalExtension OPTIONAL
}

IntersectionStateList ::= SEQUENCE (SIZE(1..32)) OF IntersectionState

IntersectionState ::= SEQUENCE {
    name DescriptiveName OPTIONAL,
    id IntersectionReferenceID,
    revision MsgCount,
    status IntersectionStatusObject,
    moy MinuteOfTheYear OPTIONAL,
    timeStamp DSecond OPTIONAL,
    enabledLanes LaneList OPTIONAL,
    states MovementList,
    maneuverAssistList ManeuverAssistList OPTIONAL,
    regional SEQUENCE (SIZE(1..4)) OF RegionalExtension OPTIONAL
}

MovementList ::= SEQUENCE (SIZE(1..255)) OF MovementState

MovementState ::= SEQUENCE {
    movementName DescriptiveName OPTIONAL,
    signalGroup SignalGroupID,
    state-time-speed MovementEventList,
    maneuverAssistList ManeuverAssistList OPTIONAL
}

MovementEventList ::= SEQUENCE (SIZE(1..16)) OF MovementEvent

MovementEvent ::= SEQUENCE {
    eventState MovementPhaseState,
    timing TimeChangeDetails OPTIONAL,
    speeds AdvisorySpeedList OPTIONAL,
    regional SEQUENCE (SIZE(1..4)) OF RegionalExtension OPTIONAL
}

MovementPhaseState ::= ENUMERATED {
    unavailable (0),
    dark (1),
    stop-Then-Proceed (2),  -- Flashing red
    stop-And-Remain (3),    -- Red
    pre-Movement (4),       -- Yellow
    permissive-Movement-Allowed (5),  -- Green
    protected-Movement-Allowed (6),   -- Protected green arrow
    permissive-clearance (7),
    protected-clearance (8),
    caution-Conflicting-Traffic (9)  -- Flashing yellow
}
```

### C++ SPaT Implementation

```cpp
// spat_manager.hpp
#pragma once

#include <cstdint>
#include <vector>
#include <map>
#include <string>

namespace v2i {
namespace spat {

enum class MovementPhaseState : uint8_t {
    UNAVAILABLE = 0,
    DARK = 1,
    STOP_THEN_PROCEED = 2,  // Flashing red
    STOP_AND_REMAIN = 3,    // Solid red
    PRE_MOVEMENT = 4,       // Yellow
    PERMISSIVE_GREEN = 5,   // Green ball
    PROTECTED_GREEN = 6,    // Green arrow
    PERMISSIVE_CLEARANCE = 7,
    PROTECTED_CLEARANCE = 8,
    CAUTION = 9  // Flashing yellow
};

struct TimeChangeDetails {
    uint16_t minEndTime;  // Deciseconds (0.1s) until phase ends (min)
    uint16_t maxEndTime;  // Deciseconds until phase ends (max)
    uint16_t likelyTime;  // Deciseconds until phase ends (most likely)
    uint8_t confidence;   // 0-100%
    uint16_t nextTime;    // Time to next phase (optional)
};

struct MovementEvent {
    MovementPhaseState eventState;
    TimeChangeDetails timing;
    uint16_t speedAdvisory_mps;  // Optional: recommended speed (0.02 m/s units)
};

struct MovementState {
    uint8_t signalGroup;  // Lane/movement ID
    std::string movementName;  // e.g., "NB Left Turn"
    std::vector<MovementEvent> stateTimeSpeed;
};

struct IntersectionState {
    uint16_t intersectionID;
    std::string name;
    uint8_t revision;  // Message counter
    uint16_t minuteOfYear;
    uint16_t msOfMinute;
    std::vector<MovementState> movements;
    uint16_t status;  // Bit field: timing valid, manual control, etc.
};

struct SPaTMessage {
    uint32_t timestamp_ms;
    std::vector<IntersectionState> intersections;
};

class SPaTManager {
public:
    SPaTManager(uint16_t intersectionID);

    // Update phase state from traffic controller
    void updateMovementState(
        uint8_t signalGroup,
        MovementPhaseState newState,
        uint16_t timeToChange_ds  // Deciseconds
    );

    // Generate SPaT message for broadcast
    SPaTMessage generateSPaTMessage();

    // Encode SPaT to wire format (UPER)
    std::vector<uint8_t> encodeSPaT(const SPaTMessage& spat);

    // Decode received SPaT
    static bool decodeSPaT(const std::vector<uint8_t>& data, SPaTMessage& spat);

    // Get time remaining for specific movement
    uint16_t getTimeRemaining(uint8_t signalGroup) const;

    // Get current phase state
    MovementPhaseState getCurrentState(uint8_t signalGroup) const;

    // Predict phase change time with confidence
    TimeChangeDetails predictPhaseChange(uint8_t signalGroup) const;

private:
    uint16_t intersectionID_;
    IntersectionState currentState_;
    std::map<uint8_t, MovementState> movementStates_;

    uint8_t messageRevision_;
    uint32_t lastUpdateTime_ms_;

    // Helper to encode timing information
    void encodeTimeChangeDetails(
        std::vector<uint8_t>& buffer,
        const TimeChangeDetails& timing
    );
};

} // namespace spat
} // namespace v2i
```

```cpp
// spat_manager.cpp
#include "spat_manager.hpp"
#include <chrono>
#include <algorithm>

namespace v2i {
namespace spat {

SPaTManager::SPaTManager(uint16_t intersectionID)
    : intersectionID_(intersectionID),
      messageRevision_(0),
      lastUpdateTime_ms_(0) {

    currentState_.intersectionID = intersectionID;
    currentState_.name = "Intersection_" + std::to_string(intersectionID);
    currentState_.revision = 0;
}

void SPaTManager::updateMovementState(
    uint8_t signalGroup,
    MovementPhaseState newState,
    uint16_t timeToChange_ds
) {
    auto now = std::chrono::system_clock::now();
    auto now_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        now.time_since_epoch()).count();

    // Find or create movement state
    if (movementStates_.find(signalGroup) == movementStates_.end()) {
        MovementState movement;
        movement.signalGroup = signalGroup;
        movement.movementName = "Movement_" + std::to_string(signalGroup);
        movementStates_[signalGroup] = movement;
    }

    auto& movement = movementStates_[signalGroup];

    // Create new event
    MovementEvent event;
    event.eventState = newState;
    event.timing.minEndTime = timeToChange_ds;
    event.timing.maxEndTime = timeToChange_ds + 10;  // +1 second tolerance
    event.timing.likelyTime = timeToChange_ds;
    event.timing.confidence = 95;  // High confidence from controller

    // Update movement state
    movement.stateTimeSpeed.clear();
    movement.stateTimeSpeed.push_back(event);

    lastUpdateTime_ms_ = now_ms;
    messageRevision_++;
}

SPaTMessage SPaTManager::generateSPaTMessage() {
    SPaTMessage spat;

    auto now = std::chrono::system_clock::now();
    auto now_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        now.time_since_epoch()).count();

    spat.timestamp_ms = now_ms;

    // Build intersection state
    currentState_.revision = messageRevision_;

    // Calculate minute of year and ms of minute for timestamp
    auto now_time_t = std::chrono::system_clock::to_time_t(now);
    struct tm* tm_info = gmtime(&now_time_t);

    // Simplified calculation (should use proper day-of-year)
    currentState_.minuteOfYear = (tm_info->tm_yday * 24 * 60) +
                                 (tm_info->tm_hour * 60) +
                                 tm_info->tm_min;
    currentState_.msOfMinute = (tm_info->tm_sec * 1000) +
                               (now_ms % 1000);

    // Copy movement states
    currentState_.movements.clear();
    for (const auto& pair : movementStates_) {
        currentState_.movements.push_back(pair.second);
    }

    spat.intersections.push_back(currentState_);

    return spat;
}

std::vector<uint8_t> SPaTManager::encodeSPaT(const SPaTMessage& spat) {
    std::vector<uint8_t> buffer;
    buffer.reserve(512);

    // Message ID (0x13 for SPaT)
    buffer.push_back(0x00);
    buffer.push_back(0x13);

    // Timestamp (optional, 4 bytes)
    uint32_t ts = spat.timestamp_ms;
    buffer.push_back((ts >> 24) & 0xFF);
    buffer.push_back((ts >> 16) & 0xFF);
    buffer.push_back((ts >> 8) & 0xFF);
    buffer.push_back(ts & 0xFF);

    // Number of intersections (typically 1)
    buffer.push_back(static_cast<uint8_t>(spat.intersections.size()));

    for (const auto& intersection : spat.intersections) {
        // Intersection ID (2 bytes)
        buffer.push_back((intersection.intersectionID >> 8) & 0xFF);
        buffer.push_back(intersection.intersectionID & 0xFF);

        // Revision (1 byte)
        buffer.push_back(intersection.revision);

        // Status (2 bytes)
        buffer.push_back((intersection.status >> 8) & 0xFF);
        buffer.push_back(intersection.status & 0xFF);

        // Minute of year (2 bytes)
        buffer.push_back((intersection.minuteOfYear >> 8) & 0xFF);
        buffer.push_back(intersection.minuteOfYear & 0xFF);

        // Ms of minute (2 bytes)
        buffer.push_back((intersection.msOfMinute >> 8) & 0xFF);
        buffer.push_back(intersection.msOfMinute & 0xFF);

        // Number of movements
        buffer.push_back(static_cast<uint8_t>(intersection.movements.size()));

        for (const auto& movement : intersection.movements) {
            // Signal group ID
            buffer.push_back(movement.signalGroup);

            // Number of events (typically 1-2)
            buffer.push_back(static_cast<uint8_t>(movement.stateTimeSpeed.size()));

            for (const auto& event : movement.stateTimeSpeed) {
                // Event state (1 byte)
                buffer.push_back(static_cast<uint8_t>(event.eventState));

                // Timing
                encodeTimeChangeDetails(buffer, event.timing);
            }
        }
    }

    return buffer;
}

void SPaTManager::encodeTimeChangeDetails(
    std::vector<uint8_t>& buffer,
    const TimeChangeDetails& timing
) {
    // Min end time (2 bytes, deciseconds)
    buffer.push_back((timing.minEndTime >> 8) & 0xFF);
    buffer.push_back(timing.minEndTime & 0xFF);

    // Max end time (2 bytes)
    buffer.push_back((timing.maxEndTime >> 8) & 0xFF);
    buffer.push_back(timing.maxEndTime & 0xFF);

    // Likely time (2 bytes)
    buffer.push_back((timing.likelyTime >> 8) & 0xFF);
    buffer.push_back(timing.likelyTime & 0xFF);

    // Confidence (1 byte, 0-100)
    buffer.push_back(timing.confidence);
}

uint16_t SPaTManager::getTimeRemaining(uint8_t signalGroup) const {
    auto it = movementStates_.find(signalGroup);
    if (it == movementStates_.end() || it->second.stateTimeSpeed.empty()) {
        return 0;
    }

    return it->second.stateTimeSpeed[0].timing.likelyTime;
}

MovementPhaseState SPaTManager::getCurrentState(uint8_t signalGroup) const {
    auto it = movementStates_.find(signalGroup);
    if (it == movementStates_.end() || it->second.stateTimeSpeed.empty()) {
        return MovementPhaseState::UNAVAILABLE;
    }

    return it->second.stateTimeSpeed[0].eventState;
}

TimeChangeDetails SPaTManager::predictPhaseChange(uint8_t signalGroup) const {
    auto it = movementStates_.find(signalGroup);
    if (it == movementStates_.end() || it->second.stateTimeSpeed.empty()) {
        return TimeChangeDetails{0, 0, 0, 0, 0};
    }

    return it->second.stateTimeSpeed[0].timing;
}

} // namespace spat
} // namespace v2i
```

## MAP (Geographic Intersection Description) Message

### MAP Message Format

```asn1
-- SAE J2735 MAP Message
MapData ::= SEQUENCE {
    timeStamp MinuteOfTheYear OPTIONAL,
    msgIssueRevision MsgCount,
    layerType LayerType OPTIONAL,
    layerID LayerID OPTIONAL,
    intersections IntersectionGeometryList OPTIONAL,
    roadSegments RoadSegmentList OPTIONAL,
    dataParameters DataParameters OPTIONAL,
    restrictionList RestrictionClassList OPTIONAL,
    regional SEQUENCE (SIZE(1..4)) OF RegionalExtension OPTIONAL
}

IntersectionGeometry ::= SEQUENCE {
    name DescriptiveName OPTIONAL,
    id IntersectionReferenceID,
    revision MsgCount,
    refPoint Position3D,
    laneWidth LaneWidth OPTIONAL,
    speedLimits SpeedLimitList OPTIONAL,
    laneSet LaneList,
    preemptPriorityData PreemptPriorityList OPTIONAL,
    regional SEQUENCE (SIZE(1..4)) OF RegionalExtension OPTIONAL
}
```

### Python MAP Generator

```python
# map_generator.py
"""
Generate MAP (Geographic Intersection Description) messages.
"""

from dataclasses import dataclass
from typing import List, Tuple, Optional
import json
import math

@dataclass
class Position3D:
    latitude: float   # Degrees
    longitude: float  # Degrees
    elevation: float  # Meters (optional)

@dataclass
class LaneNode:
    """Node point in lane geometry."""
    offset_x_cm: int  # Offset from reference point
    offset_y_cm: int
    offset_z_cm: int = 0

@dataclass
class ConnectsTo:
    """Lane connection information."""
    connecting_lane_id: int
    signal_group: int  # Associated signal group
    maneuver: str  # "straight", "left", "right", "uturn"

@dataclass
class Lane:
    lane_id: int
    lane_type: str  # "vehicle", "bike", "pedestrian", "parking"
    lane_attributes: int  # Bit field
    lane_width_cm: int
    nodes: List[LaneNode]
    connects_to: List[ConnectsTo]
    speed_limit_mps: Optional[float] = None

@dataclass
class IntersectionGeometry:
    intersection_id: int
    name: str
    reference_point: Position3D
    lanes: List[Lane]
    revision: int = 1

class MAPGenerator:
    """
    Generate MAP messages for intersections.
    """

    def __init__(self):
        self.intersections: List[IntersectionGeometry] = []

    def create_four_way_intersection(
        self,
        intersection_id: int,
        center_lat: float,
        center_lon: float,
        lane_width_m: float = 3.5
    ) -> IntersectionGeometry:
        """
        Create a standard 4-way intersection geometry.

        Args:
            intersection_id: Unique intersection ID
            center_lat: Latitude of intersection center
            center_lon: Longitude of intersection center
            lane_width_m: Standard lane width in meters

        Returns:
            IntersectionGeometry object
        """
        ref_point = Position3D(center_lat, center_lon, 0.0)
        lanes = []

        # Approach distances
        approach_distance_m = 100.0

        # Create 4 approaches (North, East, South, West)
        # Each approach has 3 lanes: left turn, straight, right turn

        lane_id = 1

        # North approach (lanes coming from south, heading north)
        for lane_offset in [-1, 0, 1]:  # Left, straight, right lanes
            lane = self._create_approach_lane(
                lane_id=lane_id,
                approach_direction=0,  # North
                lateral_offset=lane_offset,
                approach_distance_m=approach_distance_m,
                lane_width_m=lane_width_m,
                ref_point=ref_point
            )

            # Add connection information
            if lane_offset == -1:  # Left turn lane
                lane.connects_to.append(
                    ConnectsTo(connecting_lane_id=21, signal_group=1, maneuver="left")
                )
            elif lane_offset == 0:  # Straight lane
                lane.connects_to.append(
                    ConnectsTo(connecting_lane_id=20, signal_group=2, maneuver="straight")
                )
            else:  # Right turn lane
                lane.connects_to.append(
                    ConnectsTo(connecting_lane_id=22, signal_group=2, maneuver="right")
                )

            lanes.append(lane)
            lane_id += 1

        # East approach
        for lane_offset in [-1, 0, 1]:
            lane = self._create_approach_lane(
                lane_id=lane_id,
                approach_direction=90,  # East
                lateral_offset=lane_offset,
                approach_distance_m=approach_distance_m,
                lane_width_m=lane_width_m,
                ref_point=ref_point
            )

            if lane_offset == -1:
                lane.connects_to.append(
                    ConnectsTo(connecting_lane_id=11, signal_group=3, maneuver="left")
                )
            elif lane_offset == 0:
                lane.connects_to.append(
                    ConnectsTo(connecting_lane_id=10, signal_group=4, maneuver="straight")
                )
            else:
                lane.connects_to.append(
                    ConnectsTo(connecting_lane_id=12, signal_group=4, maneuver="right")
                )

            lanes.append(lane)
            lane_id += 1

        # South and West approaches (similar pattern)
        # ... (code structure similar to above)

        intersection = IntersectionGeometry(
            intersection_id=intersection_id,
            name=f"Intersection_{intersection_id}",
            reference_point=ref_point,
            lanes=lanes,
            revision=1
        )

        self.intersections.append(intersection)
        return intersection

    def _create_approach_lane(
        self,
        lane_id: int,
        approach_direction: float,  # 0=North, 90=East, etc.
        lateral_offset: int,  # -1, 0, 1 for left, center, right
        approach_distance_m: float,
        lane_width_m: float,
        ref_point: Position3D
    ) -> Lane:
        """Create a single approach lane geometry."""

        lane_width_cm = int(lane_width_m * 100)

        # Calculate lane centerline nodes
        nodes = []

        # Start point (far from intersection)
        angle_rad = math.radians(approach_direction + 180)  # Coming from opposite direction
        lateral_angle_rad = math.radians(approach_direction + 90)

        for distance in [approach_distance_m, approach_distance_m / 2, 10.0, 2.0]:
            x = distance * math.cos(angle_rad) + lateral_offset * lane_width_m * math.cos(lateral_angle_rad)
            y = distance * math.sin(angle_rad) + lateral_offset * lane_width_m * math.sin(lateral_angle_rad)

            node = LaneNode(
                offset_x_cm=int(x * 100),
                offset_y_cm=int(y * 100)
            )
            nodes.append(node)

        lane = Lane(
            lane_id=lane_id,
            lane_type="vehicle",
            lane_attributes=0x0001,  # Vehicle traffic allowed
            lane_width_cm=lane_width_cm,
            nodes=nodes,
            connects_to=[],
            speed_limit_mps=13.9  # ~30 mph
        )

        return lane

    def encode_map_message(self, intersection: IntersectionGeometry) -> dict:
        """
        Encode intersection geometry to MAP message format.

        Returns:
            Dictionary representing MAP message (can be converted to JSON/UPER)
        """
        map_msg = {
            "MessageFrame": {
                "messageId": 18,  # MAP message
                "value": {
                    "MapData": {
                        "msgIssueRevision": intersection.revision,
                        "intersections": {
                            "IntersectionGeometry": [{
                                "id": {
                                    "id": intersection.intersection_id
                                },
                                "revision": intersection.revision,
                                "refPoint": {
                                    "lat": int(intersection.reference_point.latitude * 10000000),
                                    "long": int(intersection.reference_point.longitude * 10000000),
                                    "elevation": int(intersection.reference_point.elevation * 10)
                                },
                                "laneWidth": int(3.5 * 100),  # Default 3.5m
                                "laneSet": {
                                    "GenericLane": [
                                        self._encode_lane(lane) for lane in intersection.lanes
                                    ]
                                }
                            }]
                        }
                    }
                }
            }
        }

        return map_msg

    def _encode_lane(self, lane: Lane) -> dict:
        """Encode a single lane to MAP format."""
        return {
            "laneID": lane.lane_id,
            "laneAttributes": {
                "directionalUse": "11",  # Both directions (bit string)
                "sharedWith": "0000000000",
                "laneType": {
                    "vehicle": {}
                }
            },
            "laneWidth": lane.lane_width_cm,
            "nodeList": {
                "nodes": {
                    "NodeXY": [
                        {
                            "delta": {
                                "node-XY1": {
                                    "x": node.offset_x_cm,
                                    "y": node.offset_y_cm
                                }
                            }
                        }
                        for node in lane.nodes
                    ]
                }
            },
            "connectsTo": {
                "Connection": [
                    {
                        "connectingLane": {
                            "lane": conn.connecting_lane_id
                        },
                        "signalGroup": conn.signal_group,
                        "maneuver": self._encode_maneuver(conn.maneuver)
                    }
                    for conn in lane.connects_to
                ]
            }
        }

    @staticmethod
    def _encode_maneuver(maneuver: str) -> str:
        """Encode maneuver as bit string."""
        maneuver_bits = {
            "straight": "100000000000",
            "left": "010000000000",
            "right": "001000000000",
            "uturn": "000100000000"
        }
        return maneuver_bits.get(maneuver, "000000000000")

    def export_to_json(self, filename: str):
        """Export all intersections to JSON file."""
        map_messages = [
            self.encode_map_message(intersection)
            for intersection in self.intersections
        ]

        with open(filename, 'w') as f:
            json.dump(map_messages, f, indent=2)

        print(f"Exported {len(map_messages)} MAP messages to {filename}")


# Example usage
if __name__ == "__main__":
    generator = MAPGenerator()

    # Create intersection
    intersection = generator.create_four_way_intersection(
        intersection_id=1001,
        center_lat=37.7749,
        center_lon=-122.4194,
        lane_width_m=3.5
    )

    print(f"Created intersection with {len(intersection.lanes)} lanes")

    # Export to JSON
    generator.export_to_json("intersection_map.json")
```

## Traffic Light Optimization with V2I

### Green Light Optimal Speed Advisory (GLOSA)

```python
# glosa_calculator.py
"""
Green Light Optimal Speed Advisory (GLOSA) calculator.
Recommends optimal speed to reach green light.
"""

from dataclasses import dataclass
from typing import Optional
import math

@dataclass
class SPaTData:
    current_phase: str  # "red", "green", "yellow"
    time_to_change_s: float
    next_phase: str
    time_to_next_change_s: float

@dataclass
class GLOSARecommendation:
    recommended_speed_mps: float
    can_make_green: bool
    time_savings_s: float
    confidence: float  # 0.0-1.0
    recommendation_type: str  # "speed_up", "slow_down", "maintain", "stop"

class GLOSACalculator:
    """
    Calculate optimal speed to reach green light.
    """

    def __init__(self,
                 min_speed_mps: float = 5.0,   # ~10 mph
                 max_speed_mps: float = 22.2,  # ~50 mph
                 comfort_accel_mps2: float = 1.5,
                 comfort_decel_mps2: float = 2.0):
        self.min_speed = min_speed_mps
        self.max_speed = max_speed_mps
        self.comfort_accel = comfort_accel_mps2
        self.comfort_decel = comfort_decel_mps2

    def calculate_glosa(
        self,
        distance_to_intersection_m: float,
        current_speed_mps: float,
        speed_limit_mps: float,
        spat: SPaTData
    ) -> GLOSARecommendation:
        """
        Calculate GLOSA recommendation.

        Args:
            distance_to_intersection_m: Distance to stop line
            current_speed_mps: Current vehicle speed
            speed_limit_mps: Posted speed limit
            spat: Signal phase and timing data

        Returns:
            GLOSARecommendation with optimal speed
        """

        # If already at intersection or very close
        if distance_to_intersection_m < 5.0:
            return GLOSARecommendation(
                recommended_speed_mps=current_speed_mps,
                can_make_green=(spat.current_phase == "green"),
                time_savings_s=0.0,
                confidence=1.0,
                recommendation_type="maintain"
            )

        # Calculate time to reach intersection at current speed
        if current_speed_mps > 0.5:
            tta_current = distance_to_intersection_m / current_speed_mps
        else:
            tta_current = 999.0

        # Current phase is green
        if spat.current_phase == "green":
            return self._handle_green_phase(
                distance_to_intersection_m,
                current_speed_mps,
                speed_limit_mps,
                spat.time_to_change_s
            )

        # Current phase is red
        elif spat.current_phase == "red":
            return self._handle_red_phase(
                distance_to_intersection_m,
                current_speed_mps,
                speed_limit_mps,
                spat.time_to_change_s,
                spat.time_to_next_change_s
            )

        # Yellow phase - treat as red (stop if safe)
        else:
            return GLOSARecommendation(
                recommended_speed_mps=0.0,
                can_make_green=False,
                time_savings_s=0.0,
                confidence=0.9,
                recommendation_type="stop"
            )

    def _handle_green_phase(
        self,
        distance_m: float,
        current_speed_mps: float,
        speed_limit_mps: float,
        time_to_yellow_s: float
    ) -> GLOSARecommendation:
        """Handle green phase scenario."""

        # Can we make it through at current speed?
        tta_current = distance_m / max(current_speed_mps, 1.0)

        # Add buffer for yellow and clearance (3 seconds typical)
        safe_time = time_to_yellow_s - 3.0

        if tta_current < safe_time:
            # Can make it comfortably
            return GLOSARecommendation(
                recommended_speed_mps=current_speed_mps,
                can_make_green=True,
                time_savings_s=0.0,
                confidence=0.95,
                recommendation_type="maintain"
            )
        else:
            # Need to speed up (within limits)
            required_speed = distance_m / safe_time
            recommended_speed = min(required_speed, speed_limit_mps, self.max_speed)

            # Check if acceleration is comfortable
            speed_change = recommended_speed - current_speed_mps
            accel_required = speed_change / max(safe_time, 1.0)

            if accel_required <= self.comfort_accel:
                return GLOSARecommendation(
                    recommended_speed_mps=recommended_speed,
                    can_make_green=True,
                    time_savings_s=safe_time - tta_current,
                    confidence=0.85,
                    recommendation_type="speed_up"
                )
            else:
                # Can't make it comfortably, prepare to stop
                return GLOSARecommendation(
                    recommended_speed_mps=current_speed_mps * 0.7,
                    can_make_green=False,
                    time_savings_s=0.0,
                    confidence=0.8,
                    recommendation_type="slow_down"
                )

    def _handle_red_phase(
        self,
        distance_m: float,
        current_speed_mps: float,
        speed_limit_mps: float,
        time_to_green_s: float,
        green_duration_s: float
    ) -> GLOSARecommendation:
        """Handle red phase scenario."""

        # Calculate speed needed to arrive at green
        if time_to_green_s > 0:
            optimal_speed = distance_m / time_to_green_s
        else:
            optimal_speed = 0.0

        # Check if optimal speed is within bounds
        if self.min_speed <= optimal_speed <= min(speed_limit_mps, self.max_speed):
            # Can time arrival for green light
            speed_change = optimal_speed - current_speed_mps
            time_to_adjust = max(time_to_green_s - 5.0, 1.0)  # Leave buffer
            accel_required = speed_change / time_to_adjust

            # Check if comfortable
            if abs(accel_required) <= self.comfort_accel:
                # Calculate time savings vs. stopping
                stop_time = time_to_green_s + 3.0  # Restart delay
                tta_optimal = distance_m / optimal_speed
                time_savings = stop_time - tta_optimal

                return GLOSARecommendation(
                    recommended_speed_mps=optimal_speed,
                    can_make_green=True,
                    time_savings_s=time_savings,
                    confidence=0.9,
                    recommendation_type="slow_down" if speed_change < 0 else "speed_up"
                )

        # Can't time it well, prepare to stop
        # Calculate comfortable deceleration distance
        stopping_distance = (current_speed_mps ** 2) / (2 * self.comfort_decel)

        if distance_m > stopping_distance * 1.2:  # Have room to slow comfortably
            return GLOSARecommendation(
                recommended_speed_mps=current_speed_mps * 0.5,
                can_make_green=False,
                time_savings_s=0.0,
                confidence=0.85,
                recommendation_type="slow_down"
            )
        else:
            # Must stop more urgently
            return GLOSARecommendation(
                recommended_speed_mps=0.0,
                can_make_green=False,
                time_savings_s=0.0,
                confidence=0.95,
                recommendation_type="stop"
            )


# Example usage
if __name__ == "__main__":
    calculator = GLOSACalculator()

    # Scenario: Approaching red light that will turn green
    spat_data = SPaTData(
        current_phase="red",
        time_to_change_s=15.0,  # 15 seconds until green
        next_phase="green",
        time_to_next_change_s=30.0  # 30 seconds of green
    )

    recommendation = calculator.calculate_glosa(
        distance_to_intersection_m=200.0,  # 200m away
        current_speed_mps=16.7,  # ~60 km/h
        speed_limit_mps=16.7,
        spat=spat_data
    )

    print(f"Recommendation: {recommendation.recommendation_type}")
    print(f"Optimal speed: {recommendation.recommended_speed_mps * 3.6:.1f} km/h")
    print(f"Can make green: {recommendation.can_make_green}")
    print(f"Time savings: {recommendation.time_savings_s:.1f} seconds")
    print(f"Confidence: {recommendation.confidence*100:.0f}%")
```

## RSU Deployment Strategy

### Coverage Analysis

```python
# rsu_deployment_optimizer.py
"""
Optimize RSU deployment for coverage and cost.
"""

import math
from dataclasses import dataclass
from typing import List, Tuple
import matplotlib.pyplot as plt

@dataclass
class RSU:
    id: int
    latitude: float
    longitude: float
    range_m: float
    cost_usd: float

@dataclass
class Intersection:
    id: int
    latitude: float
    longitude: float
    traffic_volume_vpd: int  # Vehicles per day
    priority: int  # 1-5, 5=highest

class RSUDeploymentOptimizer:
    """
    Optimize RSU placement for V2I coverage.
    """

    def __init__(self, budget_usd: float, rsu_cost_usd: float = 15000):
        self.budget = budget_usd
        self.rsu_cost = rsu_cost_usd
        self.rsu_range_m = 300.0  # Conservative urban range

    def optimize_deployment(
        self,
        intersections: List[Intersection],
        road_segments: List[Tuple[float, float, float, float]]  # lat1,lon1,lat2,lon2
    ) -> List[RSU]:
        """
        Determine optimal RSU placement.

        Strategy:
        1. Prioritize high-traffic intersections
        2. Ensure coverage of critical road segments
        3. Minimize overlap
        4. Stay within budget

        Returns:
            List of RSU positions
        """
        max_rsus = int(self.budget / self.rsu_cost)
        print(f"Budget allows for {max_rsus} RSUs")

        # Sort intersections by priority and traffic
        sorted_intersections = sorted(
            intersections,
            key=lambda x: (x.priority, x.traffic_volume_vpd),
            reverse=True
        )

        deployed_rsus = []
        covered_intersections = set()

        rsu_id = 1

        for intersection in sorted_intersections:
            if len(deployed_rsus) >= max_rsus:
                break

            # Check if already covered by existing RSU
            if self._is_covered(intersection, deployed_rsus):
                covered_intersections.add(intersection.id)
                continue

            # Deploy new RSU at this intersection
            rsu = RSU(
                id=rsu_id,
                latitude=intersection.latitude,
                longitude=intersection.longitude,
                range_m=self.rsu_range_m,
                cost_usd=self.rsu_cost
            )

            deployed_rsus.append(rsu)
            covered_intersections.add(intersection.id)
            rsu_id += 1

            print(f"Deployed RSU {rsu.id} at intersection {intersection.id} "
                  f"(Priority {intersection.priority}, "
                  f"Traffic {intersection.traffic_volume_vpd} vpd)")

        # Calculate coverage statistics
        coverage_pct = (len(covered_intersections) / len(intersections)) * 100
        total_cost = len(deployed_rsus) * self.rsu_cost

        print(f"\nDeployment Summary:")
        print(f"  RSUs deployed: {len(deployed_rsus)}")
        print(f"  Intersections covered: {len(covered_intersections)}/{len(intersections)} "
              f"({coverage_pct:.1f}%)")
        print(f"  Total cost: ${total_cost:,}")
        print(f"  Remaining budget: ${self.budget - total_cost:,}")

        return deployed_rsus

    def _is_covered(self, intersection: Intersection, rsus: List[RSU]) -> bool:
        """Check if intersection is within range of any RSU."""
        for rsu in rsus:
            distance = self._calculate_distance(
                intersection.latitude, intersection.longitude,
                rsu.latitude, rsu.longitude
            )
            if distance <= rsu.range_m:
                return True
        return False

    @staticmethod
    def _calculate_distance(lat1: float, lon1: float,
                           lat2: float, lon2: float) -> float:
        """Calculate distance between two GPS coordinates (Haversine)."""
        R = 6371000  # Earth radius in meters

        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = (math.sin(delta_phi / 2) ** 2 +
             math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c

    def visualize_deployment(self, rsus: List[RSU],
                           intersections: List[Intersection]):
        """Visualize RSU coverage map."""
        fig, ax = plt.subplots(figsize=(12, 10))

        # Plot intersections
        for intersection in intersections:
            color = 'red' if intersection.priority >= 4 else 'orange'
            size = intersection.traffic_volume_vpd / 100
            ax.scatter(intersection.longitude, intersection.latitude,
                      c=color, s=size, alpha=0.5, label='Intersection')

        # Plot RSUs with coverage circles
        for rsu in rsus:
            ax.scatter(rsu.longitude, rsu.latitude,
                      c='blue', s=200, marker='^', label='RSU')

            # Coverage circle
            circle = plt.Circle(
                (rsu.longitude, rsu.latitude),
                rsu.range_m / 111000,  # Approximate degrees
                color='blue',
                fill=False,
                linestyle='--',
                alpha=0.3
            )
            ax.add_patch(circle)

            # RSU ID label
            ax.text(rsu.longitude, rsu.latitude + 0.001,
                   f"RSU {rsu.id}",
                   fontsize=8,
                   ha='center')

        ax.set_xlabel('Longitude')
        ax.set_ylabel('Latitude')
        ax.set_title('RSU Deployment Map')
        ax.grid(True, alpha=0.3)

        # Remove duplicate labels
        handles, labels = ax.get_legend_handles_labels()
        by_label = dict(zip(labels, handles))
        ax.legend(by_label.values(), by_label.keys())

        plt.savefig('rsu_deployment_map.png', dpi=150, bbox_inches='tight')
        print("Saved deployment map to rsu_deployment_map.png")


# Example usage
if __name__ == "__main__":
    # Define intersections in a city
    intersections = [
        Intersection(1, 37.7749, -122.4194, 25000, 5),  # High priority
        Intersection(2, 37.7750, -122.4180, 18000, 4),
        Intersection(3, 37.7760, -122.4200, 15000, 3),
        Intersection(4, 37.7740, -122.4210, 12000, 3),
        Intersection(5, 37.7755, -122.4175, 20000, 5),
        Intersection(6, 37.7735, -122.4185, 8000, 2),
    ]

    # Deployment optimizer
    optimizer = RSUDeploymentOptimizer(budget_usd=100000)

    # Optimize deployment
    rsus = optimizer.optimize_deployment(intersections, [])

    # Visualize (requires matplotlib)
    # optimizer.visualize_deployment(rsus, intersections)
```

## Work Zone Warnings and Parking Management

### Work Zone Warning System

```cpp
// work_zone_warning.hpp
#pragma once

#include <string>
#include <vector>
#include <cstdint>

namespace v2i {

enum class WorkZoneType {
    CONSTRUCTION,
    MAINTENANCE,
    UTILITY_WORK,
    EMERGENCY_RESPONSE
};

enum class LaneClosureType {
    NONE,
    RIGHT_LANE,
    LEFT_LANE,
    CENTER_LANE,
    MULTIPLE_LANES,
    ROAD_CLOSED
};

struct WorkZoneInfo {
    uint32_t zone_id;
    WorkZoneType type;
    LaneClosureType lane_closure;
    double start_latitude;
    double start_longitude;
    double end_latitude;
    double end_longitude;
    uint16_t length_meters;
    uint8_t reduced_speed_limit_mph;
    uint32_t start_time_epoch;
    uint32_t end_time_epoch;
    bool workers_present;
    std::string description;
};

struct TravelerInformationMessage {
    uint8_t message_id;  // TIM = 0x1F
    uint16_t msg_count;
    std::vector<WorkZoneInfo> work_zones;
    uint32_t timestamp_ms;
};

class WorkZoneWarningSystem {
public:
    WorkZoneWarningSystem();

    // Add work zone
    void addWorkZone(const WorkZoneInfo& zone);

    // Remove work zone
    void removeWorkZone(uint32_t zone_id);

    // Generate TIM message for broadcast
    TravelerInformationMessage generateTIM();

    // Check if vehicle is approaching work zone
    bool isApproachingWorkZone(
        double vehicle_lat,
        double vehicle_lon,
        double vehicle_heading_deg,
        double& distance_to_zone_m
    );

    // Get recommended speed for work zone
    uint8_t getRecommendedSpeed(uint32_t zone_id);

private:
    std::vector<WorkZoneInfo> active_zones_;
    uint16_t message_counter_;
};

} // namespace v2i
```

## References

1. **SAE J2735**: Dedicated Short Range Communications (DSRC) Message Set Dictionary
2. **SAE J2945**: On-Board System Requirements for V2V Safety Communications
3. **USDOT**: Connected Vehicle Pilot Deployment Program
4. **FHWA**: V2I Deployment Coalition guidance documents
5. **ITE**: Traffic Signal Timing Manual (GLOSA algorithms)

---

## V2V Safety Applications

# V2V Safety Applications

## Overview
Comprehensive guide to Vehicle-to-Vehicle (V2V) safety applications including Cooperative Adaptive Cruise Control (CACC), Emergency Electronic Brake Light (EEBL), Intersection Movement Assist (IMA), Forward Collision Warning (FCW), and platooning algorithms.

## Safety Application Categories

### Priority Levels

| Application | Safety Impact | Latency Requirement | Message Rate | Range |
|------------|---------------|---------------------|--------------|-------|
| EEBL | Critical | < 50 ms | Event-triggered | 300 m |
| FCW | Critical | < 100 ms | 10 Hz | 200 m |
| IMA | Critical | < 100 ms | 10 Hz | 300 m |
| CACC | High | < 100 ms | 10 Hz | 150 m |
| LCW (Lane Change) | High | < 100 ms | 10 Hz | 100 m |
| BSW (Blind Spot) | Medium | < 200 ms | 5 Hz | 50 m |

## Emergency Electronic Brake Light (EEBL)

### Concept
Warns following vehicles when lead vehicle applies hard braking, providing early warning beyond visual brake lights.

### Triggering Conditions

```cpp
// eebl_detector.hpp
#pragma once

#include <cstdint>
#include <chrono>

namespace v2v {
namespace safety {

struct VehicleDynamics {
    double speed_mps;
    double acceleration_mps2;
    double deceleration_mps2;  // Positive value for braking
    bool brake_active;
    uint32_t timestamp_ms;
};

struct EEBLEvent {
    bool is_active;
    double severity;  // 0.0 - 1.0
    double deceleration_mps2;
    uint32_t duration_ms;
    double initial_speed_mps;
};

class EEBLDetector {
public:
    EEBLDetector(
        double hard_brake_threshold_mps2 = 4.0,  // ~ 0.4g
        double emergency_brake_threshold_mps2 = 6.0,  // ~ 0.6g
        uint32_t min_duration_ms = 200
    );

    // Process vehicle dynamics and detect EEBL condition
    EEBLEvent processVehicleDynamics(const VehicleDynamics& dynamics);

    // Check if received BSM from another vehicle triggers EEBL warning
    bool shouldWarnDriver(
        const EEBLEvent& remote_event,
        double distance_m,
        double own_speed_mps,
        double time_to_collision_s
    );

    // Calculate threat level
    double calculateThreatLevel(
        double distance_m,
        double relative_speed_mps,
        double remote_deceleration_mps2
    );

private:
    double hard_brake_threshold_;
    double emergency_brake_threshold_;
    uint32_t min_duration_;

    // State tracking
    EEBLEvent current_event_;
    uint32_t brake_start_time_;
    bool brake_in_progress_;
};

} // namespace safety
} // namespace v2v
```

```cpp
// eebl_detector.cpp
#include "eebl_detector.hpp"
#include <algorithm>
#include <cmath>

namespace v2v {
namespace safety {

EEBLDetector::EEBLDetector(
    double hard_brake_threshold_mps2,
    double emergency_brake_threshold_mps2,
    uint32_t min_duration_ms
) : hard_brake_threshold_(hard_brake_threshold_mps2),
    emergency_brake_threshold_(emergency_brake_threshold_mps2),
    min_duration_(min_duration_ms),
    brake_start_time_(0),
    brake_in_progress_(false) {

    current_event_.is_active = false;
}

EEBLEvent EEBLDetector::processVehicleDynamics(const VehicleDynamics& dynamics) {
    EEBLEvent event;
    event.is_active = false;

    // Check if hard braking is occurring
    if (dynamics.brake_active &&
        dynamics.deceleration_mps2 >= hard_brake_threshold_) {

        if (!brake_in_progress_) {
            // New braking event started
            brake_start_time_ = dynamics.timestamp_ms;
            brake_in_progress_ = true;
            current_event_.initial_speed_mps = dynamics.speed_mps;
        }

        uint32_t brake_duration = dynamics.timestamp_ms - brake_start_time_;

        if (brake_duration >= min_duration_) {
            // EEBL condition met
            event.is_active = true;
            event.deceleration_mps2 = dynamics.deceleration_mps2;
            event.duration_ms = brake_duration;
            event.initial_speed_mps = current_event_.initial_speed_mps;

            // Calculate severity (0.0 - 1.0)
            if (dynamics.deceleration_mps2 >= emergency_brake_threshold_) {
                event.severity = 1.0;
            } else {
                event.severity = (dynamics.deceleration_mps2 - hard_brake_threshold_) /
                               (emergency_brake_threshold_ - hard_brake_threshold_);
            }

            current_event_ = event;
        }
    } else {
        // Braking ended or not hard enough
        brake_in_progress_ = false;
    }

    return event;
}

bool EEBLDetector::shouldWarnDriver(
    const EEBLEvent& remote_event,
    double distance_m,
    double own_speed_mps,
    double time_to_collision_s
) {
    if (!remote_event.is_active) {
        return false;
    }

    // Warn if TTC is less than critical threshold
    const double TTC_WARNING_THRESHOLD = 4.0;  // seconds
    if (time_to_collision_s < TTC_WARNING_THRESHOLD) {
        return true;
    }

    // Warn if distance is close and severity is high
    const double CLOSE_DISTANCE = 50.0;  // meters
    if (distance_m < CLOSE_DISTANCE && remote_event.severity > 0.7) {
        return true;
    }

    return false;
}

double EEBLDetector::calculateThreatLevel(
    double distance_m,
    double relative_speed_mps,
    double remote_deceleration_mps2
) {
    // Calculate time to collision
    double ttc = (relative_speed_mps > 0.1) ?
                 (distance_m / relative_speed_mps) : 999.0;

    // Threat increases with: shorter TTC, higher relative speed, harder braking
    double ttc_factor = std::max(0.0, 1.0 - ttc / 5.0);  // 5 sec threshold
    double speed_factor = std::min(1.0, relative_speed_mps / 20.0);  // 20 m/s threshold
    double decel_factor = std::min(1.0, remote_deceleration_mps2 / 8.0);  // 8 m/s^2 threshold

    return (ttc_factor * 0.5 + speed_factor * 0.3 + decel_factor * 0.2);
}

} // namespace safety
} // namespace v2v
```

### EEBL Warning Message Format

```cpp
// eebl_message.hpp
#pragma once

#include <cstdint>
#include <vector>

namespace v2v {
namespace safety {

struct EEBLMessage {
    // Header
    uint8_t message_type;  // 0x01 for EEBL
    uint32_t sender_id;
    uint32_t timestamp_ms;

    // Location
    int32_t latitude;   // 1/10 micro-degree
    int32_t longitude;

    // Vehicle dynamics at brake event
    uint16_t speed_at_brake_mps;  // 0.01 m/s resolution
    uint16_t deceleration_mps2;   // 0.01 m/s^2 resolution
    uint8_t brake_severity;       // 0-100

    // Event information
    uint16_t event_duration_ms;
    uint8_t event_flags;  // Bit 0: ABS active, Bit 1: Stability control active

    // Encode to byte array for transmission
    std::vector<uint8_t> encode() const;

    // Decode from received byte array
    static bool decode(const std::vector<uint8_t>& data, EEBLMessage& msg);
};

} // namespace safety
} // namespace v2v
```

## Forward Collision Warning (FCW)

### Algorithm

```cpp
// fcw_calculator.hpp
#pragma once

#include <cstdint>
#include <cmath>

namespace v2v {
namespace safety {

struct FCWResult {
    bool warning_required;
    double time_to_collision_s;
    double collision_probability;
    uint8_t warning_level;  // 0: None, 1: Advisory, 2: Caution, 3: Imminent
};

class FCWCalculator {
public:
    FCWCalculator();

    // Calculate FCW based on own vehicle and lead vehicle states
    FCWResult calculateFCW(
        // Own vehicle
        double own_speed_mps,
        double own_acceleration_mps2,

        // Lead vehicle (from V2V)
        double lead_speed_mps,
        double lead_acceleration_mps2,
        double distance_m,

        // Road conditions
        double road_friction = 0.8,  // 0.0 - 1.0
        double driver_reaction_time_s = 1.5
    );

    // Time to collision calculation
    double calculateTTC(
        double distance_m,
        double own_speed_mps,
        double lead_speed_mps
    );

    // Required Safe Distance (RSD)
    double calculateRSD(
        double own_speed_mps,
        double lead_speed_mps,
        double own_decel_capability_mps2,
        double lead_decel_capability_mps2,
        double reaction_time_s
    );

private:
    // Thresholds
    double ttc_caution_threshold_;   // 2.5 seconds
    double ttc_warning_threshold_;   // 1.5 seconds
    double ttc_imminent_threshold_;  // 0.8 seconds

    // Vehicle parameters
    double max_deceleration_;  // 8.0 m/s^2 (emergency)
    double comfort_deceleration_;  // 4.0 m/s^2
};

} // namespace safety
} // namespace v2v
```

```cpp
// fcw_calculator.cpp
#include "fcw_calculator.hpp"
#include <algorithm>

namespace v2v {
namespace safety {

FCWCalculator::FCWCalculator()
    : ttc_caution_threshold_(2.5),
      ttc_warning_threshold_(1.5),
      ttc_imminent_threshold_(0.8),
      max_deceleration_(8.0),
      comfort_deceleration_(4.0) {}

FCWResult FCWCalculator::calculateFCW(
    double own_speed_mps,
    double own_acceleration_mps2,
    double lead_speed_mps,
    double lead_acceleration_mps2,
    double distance_m,
    double road_friction,
    double driver_reaction_time_s
) {
    FCWResult result;
    result.warning_required = false;
    result.warning_level = 0;

    // Calculate relative speed
    double relative_speed_mps = own_speed_mps - lead_speed_mps;

    // No warning if not closing in
    if (relative_speed_mps <= 0.0) {
        result.time_to_collision_s = 999.0;
        result.collision_probability = 0.0;
        return result;
    }

    // Calculate Time to Collision
    result.time_to_collision_s = calculateTTC(
        distance_m, own_speed_mps, lead_speed_mps
    );

    // Adjust max deceleration for road friction
    double available_decel = max_deceleration_ * road_friction;

    // Calculate Required Safe Distance
    double rsd = calculateRSD(
        own_speed_mps,
        lead_speed_mps,
        available_decel,
        max_deceleration_,  // Assume lead can brake harder
        driver_reaction_time_s
    );

    // Determine warning level
    if (result.time_to_collision_s < ttc_imminent_threshold_ ||
        distance_m < rsd * 0.5) {
        result.warning_level = 3;  // Imminent
        result.warning_required = true;
        result.collision_probability = 0.9;
    }
    else if (result.time_to_collision_s < ttc_warning_threshold_ ||
             distance_m < rsd * 0.7) {
        result.warning_level = 2;  // Warning
        result.warning_required = true;
        result.collision_probability = 0.6;
    }
    else if (result.time_to_collision_s < ttc_caution_threshold_ ||
             distance_m < rsd * 0.9) {
        result.warning_level = 1;  // Caution
        result.warning_required = true;
        result.collision_probability = 0.3;
    }

    return result;
}

double FCWCalculator::calculateTTC(
    double distance_m,
    double own_speed_mps,
    double lead_speed_mps
) {
    double relative_speed = own_speed_mps - lead_speed_mps;

    if (relative_speed <= 0.1) {
        return 999.0;  // Not closing in
    }

    return distance_m / relative_speed;
}

double FCWCalculator::calculateRSD(
    double own_speed_mps,
    double lead_speed_mps,
    double own_decel_capability_mps2,
    double lead_decel_capability_mps2,
    double reaction_time_s
) {
    // Distance traveled during reaction time
    double reaction_distance = own_speed_mps * reaction_time_s;

    // Braking distance for own vehicle
    double own_brake_distance = (own_speed_mps * own_speed_mps) /
                                (2.0 * own_decel_capability_mps2);

    // Braking distance for lead vehicle (could be braking too)
    double lead_brake_distance = (lead_speed_mps * lead_speed_mps) /
                                 (2.0 * lead_decel_capability_mps2);

    // Required safe distance
    double rsd = reaction_distance + own_brake_distance - lead_brake_distance;

    // Add safety margin (2 seconds at current speed)
    rsd += 2.0 * own_speed_mps;

    return std::max(5.0, rsd);  // Minimum 5 meters
}

} // namespace safety
} // namespace v2v
```

## Intersection Movement Assist (IMA)

### Concept
Warns drivers of potential collisions at intersections using V2V communication with crossing/turning vehicles.

### Implementation

```python
# ima_module.py
"""
Intersection Movement Assist (IMA) implementation.
Detects potential intersection collisions using V2V data.
"""

import math
from dataclasses import dataclass
from typing import List, Tuple, Optional
from enum import Enum

class IntersectionApproach(Enum):
    NORTH = 0
    EAST = 1
    SOUTH = 2
    WEST = 3

class TurnIntent(Enum):
    STRAIGHT = 0
    LEFT = 1
    RIGHT = 2
    U_TURN = 3

@dataclass
class VehicleState:
    vehicle_id: int
    latitude: float
    longitude: float
    speed_mps: float
    heading_deg: float  # 0=North, 90=East, 180=South, 270=West
    acceleration_mps2: float
    turn_signal: TurnIntent
    distance_to_intersection_m: float

@dataclass
class IntersectionGeometry:
    center_lat: float
    center_lon: float
    radius_m: float  # Intersection zone radius
    approach_lanes: int

class IMAModule:
    """
    Intersection Movement Assist module.
    """

    def __init__(self, intersection_geometry: IntersectionGeometry):
        self.intersection = intersection_geometry
        self.ttc_warning_threshold_s = 3.0
        self.ttc_critical_threshold_s = 1.5

    def assess_collision_risk(
        self,
        own_vehicle: VehicleState,
        remote_vehicles: List[VehicleState]
    ) -> List[Tuple[int, float, str]]:
        """
        Assess collision risk at intersection.

        Returns:
            List of (vehicle_id, collision_probability, warning_message)
        """
        warnings = []

        for remote in remote_vehicles:
            # Check if both vehicles are approaching intersection
            if not self._is_approaching_intersection(own_vehicle):
                continue
            if not self._is_approaching_intersection(remote):
                continue

            # Calculate time to intersection for both vehicles
            own_tti = self._time_to_intersection(own_vehicle)
            remote_tti = self._time_to_intersection(remote)

            if own_tti is None or remote_tti is None:
                continue

            # Check if paths will conflict
            conflict = self._check_path_conflict(
                own_vehicle, remote, own_tti, remote_tti
            )

            if conflict:
                time_diff = abs(own_tti - remote_tti)

                if time_diff < self.ttc_critical_threshold_s:
                    prob = 0.9
                    msg = f"CRITICAL: Collision imminent with vehicle {remote.vehicle_id}"
                    warnings.append((remote.vehicle_id, prob, msg))
                elif time_diff < self.ttc_warning_threshold_s:
                    prob = 0.6
                    msg = f"WARNING: Potential collision with vehicle {remote.vehicle_id}"
                    warnings.append((remote.vehicle_id, prob, msg))

        return warnings

    def _is_approaching_intersection(self, vehicle: VehicleState) -> bool:
        """Check if vehicle is approaching the intersection."""
        # Within approach zone (100m) and moving toward intersection
        if vehicle.distance_to_intersection_m > 100.0:
            return False
        if vehicle.speed_mps < 1.0:  # Essentially stopped
            return False
        return True

    def _time_to_intersection(self, vehicle: VehicleState) -> Optional[float]:
        """
        Calculate time for vehicle to reach intersection center.

        Returns:
            Time in seconds, or None if not approaching
        """
        if vehicle.speed_mps < 0.5:
            return None

        # Simple calculation assuming constant speed
        # In reality, should account for acceleration and traffic signals
        tti = vehicle.distance_to_intersection_m / vehicle.speed_mps

        # If decelerating significantly, may not reach intersection
        if vehicle.acceleration_mps2 < -2.0:
            # Check if vehicle will stop before intersection
            stop_distance = (vehicle.speed_mps ** 2) / (2 * abs(vehicle.acceleration_mps2))
            if stop_distance < vehicle.distance_to_intersection_m:
                return None  # Will stop before intersection

        return tti

    def _check_path_conflict(
        self,
        own: VehicleState,
        remote: VehicleState,
        own_tti: float,
        remote_tti: float
    ) -> bool:
        """
        Determine if vehicle paths will conflict in intersection.

        Simplified conflict detection based on approach directions and turn intents.
        """
        own_approach = self._get_approach_direction(own.heading_deg)
        remote_approach = self._get_approach_direction(remote.heading_deg)

        # Opposite approaches
        if abs(own_approach.value - remote_approach.value) == 2:
            # Straight vs straight: no conflict
            if own.turn_signal == TurnIntent.STRAIGHT and \
               remote.turn_signal == TurnIntent.STRAIGHT:
                return False
            # Left turn conflicts with opposite straight or left
            if own.turn_signal == TurnIntent.LEFT or \
               remote.turn_signal == TurnIntent.LEFT:
                return True

        # Perpendicular approaches
        elif abs(own_approach.value - remote_approach.value) % 2 == 1:
            # Always potential conflict for perpendicular
            return True

        # Same approach (following)
        else:
            # Usually no conflict unless one is turning
            return False

        return False

    @staticmethod
    def _get_approach_direction(heading_deg: float) -> IntersectionApproach:
        """Determine which approach direction based on heading."""
        heading_normalized = heading_deg % 360

        if 315 <= heading_normalized or heading_normalized < 45:
            return IntersectionApproach.NORTH
        elif 45 <= heading_normalized < 135:
            return IntersectionApproach.EAST
        elif 135 <= heading_normalized < 225:
            return IntersectionApproach.SOUTH
        else:
            return IntersectionApproach.WEST

    def calculate_stopping_distance(
        self,
        speed_mps: float,
        decel_mps2: float = 5.0,
        reaction_time_s: float = 1.0
    ) -> float:
        """Calculate total stopping distance."""
        reaction_distance = speed_mps * reaction_time_s
        brake_distance = (speed_mps ** 2) / (2 * decel_mps2)
        return reaction_distance + brake_distance


# Example usage
if __name__ == "__main__":
    # Define intersection
    intersection = IntersectionGeometry(
        center_lat=37.7749,
        center_lon=-122.4194,
        radius_m=20.0,
        approach_lanes=4
    )

    ima = IMAModule(intersection)

    # Own vehicle approaching from south
    own = VehicleState(
        vehicle_id=1,
        latitude=37.7745,
        longitude=-122.4194,
        speed_mps=15.0,  # ~33 mph
        heading_deg=0.0,  # North
        acceleration_mps2=0.0,
        turn_signal=TurnIntent.STRAIGHT,
        distance_to_intersection_m=40.0
    )

    # Remote vehicle approaching from east
    remote = VehicleState(
        vehicle_id=2,
        latitude=37.7749,
        longitude=-122.4190,
        speed_mps=12.0,  # ~27 mph
        heading_deg=270.0,  # West
        acceleration_mps2=0.0,
        turn_signal=TurnIntent.STRAIGHT,
        distance_to_intersection_m=35.0
    )

    warnings = ima.assess_collision_risk(own, [remote])

    for vehicle_id, prob, msg in warnings:
        print(f"Vehicle {vehicle_id}: Probability={prob:.2f}, Message={msg}")
```

## Cooperative Adaptive Cruise Control (CACC)

### Control Architecture

```
┌──────────────────────────────────────────────────────┐
│              CACC Controller Architecture             │
└──────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌─────────────┐
│  V2V Input   │  │ Radar/Camera │  │ Vehicle CAN │
│   (BSM)      │  │    Input     │  │   Bus Data  │
└──────┬───────┘  └──────┬───────┘  └──────┬──────┘
       │                 │                  │
       └────────┬────────┴──────────────────┘
                ▼
        ┌──────────────────┐
        │  Sensor Fusion   │
        │  & Estimation    │
        └────────┬─────────┘
                 ▼
        ┌──────────────────┐
        │  CACC Controller │
        │  (PID + Feedfwd) │
        └────────┬─────────┘
                 ▼
        ┌──────────────────┐
        │ Actuator Command │
        │ (Throttle/Brake) │
        └──────────────────┘
```

### CACC Controller Implementation

```cpp
// cacc_controller.hpp
#pragma once

#include <cstdint>
#include <deque>

namespace v2v {
namespace cacc {

struct LeadVehicleState {
    double position_m;      // Longitudinal position
    double velocity_mps;
    double acceleration_mps2;
    uint32_t timestamp_ms;
    bool v2v_available;     // True if from V2V, false if from radar
};

struct CACCConfig {
    double desired_time_gap_s;          // 0.6 - 2.0 seconds typical
    double min_following_distance_m;    // 5.0 meters minimum
    double max_acceleration_mps2;       // 2.0 m/s^2 comfort limit
    double max_deceleration_mps2;       // -4.0 m/s^2 comfort limit
    double max_jerk_mps3;              // 3.0 m/s^3 comfort limit

    // Controller gains
    double kp_spacing;                  // Proportional gain for spacing error
    double kd_spacing;                  // Derivative gain
    double kp_velocity;                 // Proportional gain for velocity error
    double feedforward_gain;            // Feedforward from lead acceleration
};

struct CACCOutput {
    double desired_acceleration_mps2;
    double desired_speed_mps;
    bool emergency_brake_required;
    double spacing_error_m;
};

class CACCController {
public:
    explicit CACCController(const CACCConfig& config);

    // Main control loop
    CACCOutput computeControl(
        const LeadVehicleState& lead,
        double own_velocity_mps,
        double own_acceleration_mps2,
        double measured_distance_m
    );

    // Update configuration (e.g., time gap adjustment)
    void updateConfig(const CACCConfig& config);

    // Reset controller state
    void reset();

    // Enable/disable string stability mode
    void setStringStabilityMode(bool enable);

private:
    CACCConfig config_;
    bool string_stability_mode_;

    // State history for derivative calculation
    std::deque<double> spacing_error_history_;
    std::deque<uint32_t> timestamp_history_;

    // Calculate desired spacing
    double calculateDesiredSpacing(double own_velocity_mps);

    // PID control
    double computePIDControl(
        double spacing_error,
        double velocity_error,
        uint32_t dt_ms
    );

    // String stability filter (Harmonic method)
    double applyStringStabilityFilter(
        double desired_accel,
        double lead_accel
    );

    // Safety bounds
    double applySafetyLimits(double accel_command);
};

} // namespace cacc
} // namespace v2v
```

```cpp
// cacc_controller.cpp
#include "cacc_controller.hpp"
#include <algorithm>
#include <cmath>

namespace v2v {
namespace cacc {

CACCController::CACCController(const CACCConfig& config)
    : config_(config), string_stability_mode_(true) {}

CACCOutput CACCController::computeControl(
    const LeadVehicleState& lead,
    double own_velocity_mps,
    double own_acceleration_mps2,
    double measured_distance_m
) {
    CACCOutput output;

    // Calculate desired spacing based on time gap policy
    double desired_spacing = calculateDesiredSpacing(own_velocity_mps);

    // Spacing error (positive = too far, negative = too close)
    double spacing_error = measured_distance_m - desired_spacing;
    output.spacing_error_m = spacing_error;

    // Velocity error (positive = lead is faster)
    double velocity_error = lead.velocity_mps - own_velocity_mps;

    // PID control
    double pid_accel = computePIDControl(
        spacing_error,
        velocity_error,
        100  // Assume 100ms update rate
    );

    // Feedforward from lead vehicle acceleration (if V2V available)
    double feedforward_accel = 0.0;
    if (lead.v2v_available) {
        feedforward_accel = config_.feedforward_gain * lead.acceleration_mps2;
    }

    // Combined control
    double desired_accel = pid_accel + feedforward_accel;

    // String stability filter
    if (string_stability_mode_) {
        desired_accel = applyStringStabilityFilter(desired_accel, lead.acceleration_mps2);
    }

    // Apply safety limits
    desired_accel = applySafetyLimits(desired_accel);

    output.desired_acceleration_mps2 = desired_accel;
    output.desired_speed_mps = own_velocity_mps + desired_accel * 0.1;  // Next step estimate

    // Emergency brake if critical spacing
    double critical_spacing = config_.min_following_distance_m;
    output.emergency_brake_required = (measured_distance_m < critical_spacing) &&
                                     (velocity_error < -2.0);  // Closing fast

    return output;
}

double CACCController::calculateDesiredSpacing(double own_velocity_mps) {
    // Constant time gap policy: d_des = d_min + h * v
    double spacing = config_.min_following_distance_m +
                    config_.desired_time_gap_s * own_velocity_mps;

    return std::max(spacing, config_.min_following_distance_m);
}

double CACCController::computePIDControl(
    double spacing_error,
    double velocity_error,
    uint32_t dt_ms
) {
    // Proportional term on spacing
    double p_term = config_.kp_spacing * spacing_error;

    // Derivative term on spacing (rate of change of error)
    double d_term = 0.0;
    if (spacing_error_history_.size() >= 2) {
        double error_rate = (spacing_error - spacing_error_history_.back()) /
                           (dt_ms / 1000.0);
        d_term = config_.kd_spacing * error_rate;
    }

    // Proportional term on velocity error
    double v_term = config_.kp_velocity * velocity_error;

    // Update history
    spacing_error_history_.push_back(spacing_error);
    if (spacing_error_history_.size() > 10) {
        spacing_error_history_.pop_front();
    }

    return p_term + d_term + v_term;
}

double CACCController::applyStringStabilityFilter(
    double desired_accel,
    double lead_accel
) {
    // Ensure acceleration doesn't amplify upstream
    // Simple low-pass filter for string stability
    const double alpha = 0.3;  // Filter coefficient
    double filtered_accel = alpha * desired_accel + (1.0 - alpha) * lead_accel;

    // Additional constraint: don't accelerate harder than lead
    if (desired_accel > lead_accel) {
        filtered_accel = std::min(filtered_accel, lead_accel * 1.1);
    }

    return filtered_accel;
}

double CACCController::applySafetyLimits(double accel_command) {
    // Clamp to comfort limits
    accel_command = std::clamp(
        accel_command,
        config_.max_deceleration_mps2,
        config_.max_acceleration_mps2
    );

    return accel_command;
}

void CACCController::updateConfig(const CACCConfig& config) {
    config_ = config;
}

void CACCController::reset() {
    spacing_error_history_.clear();
    timestamp_history_.clear();
}

void CACCController::setStringStabilityMode(bool enable) {
    string_stability_mode_ = enable;
}

} // namespace cacc
} // namespace v2v
```

## Platooning Algorithms

### String Stability Analysis

**Objective:** Ensure disturbances don't amplify upstream in a platoon.

**Transfer Function (Frequency Domain):**
```
H(jω) = |x_i(jω) / x_{i-1}(jω)|

String stable if: |H(jω)| ≤ 1 for all ω
```

### Platoon Formation Protocol

```python
# platoon_manager.py
"""
Cooperative vehicle platooning manager.
Handles platoon formation, maintenance, and dissolution.
"""

from enum import Enum
from dataclasses import dataclass
from typing import List, Optional
import time

class PlatoonRole(Enum):
    LEADER = 1
    FOLLOWER = 2
    JOINING = 3
    LEAVING = 4

class PlatoonState(Enum):
    FORMING = 1
    STABLE = 2
    SPLITTING = 3
    MERGING = 4

@dataclass
class PlatoonMember:
    vehicle_id: int
    position_in_platoon: int  # 0=leader, 1=first follower, etc.
    role: PlatoonRole
    spacing_m: float
    time_gap_s: float
    communication_quality: float  # 0.0-1.0

@dataclass
class PlatoonConfig:
    max_platoon_size: int = 8
    min_spacing_m: float = 5.0
    target_time_gap_s: float = 0.6
    max_join_speed_diff_mps: float = 2.0
    communication_timeout_s: float = 1.0

class PlatoonManager:
    """
    Manages cooperative platoon operations.
    """

    def __init__(self, vehicle_id: int, config: PlatoonConfig):
        self.vehicle_id = vehicle_id
        self.config = config
        self.platoon_id: Optional[int] = None
        self.role = PlatoonRole.LEADER  # Default until joining platoon
        self.members: List[PlatoonMember] = []
        self.state = PlatoonState.STABLE

    def request_join_platoon(self, platoon_id: int, leader_speed_mps: float,
                            own_speed_mps: float) -> bool:
        """
        Request to join an existing platoon.

        Returns:
            True if join request is feasible, False otherwise
        """
        # Check speed compatibility
        speed_diff = abs(leader_speed_mps - own_speed_mps)
        if speed_diff > self.config.max_join_speed_diff_mps:
            print(f"Speed difference {speed_diff:.1f} m/s too large")
            return False

        # Check platoon size
        if len(self.members) >= self.config.max_platoon_size:
            print("Platoon full")
            return False

        # Initiate join sequence
        self.role = PlatoonRole.JOINING
        self.platoon_id = platoon_id
        self.state = PlatoonState.MERGING

        print(f"Vehicle {self.vehicle_id} joining platoon {platoon_id}")
        return True

    def execute_join_maneuver(self, target_position: int,
                             current_speed_mps: float) -> dict:
        """
        Execute the join maneuver.

        Returns:
            Control commands dict with 'target_speed', 'target_spacing'
        """
        # Calculate target spacing for join maneuver
        # Use larger spacing initially, then tighten
        join_spacing = self.config.min_spacing_m * 2.0
        target_time_gap = self.config.target_time_gap_s * 1.5

        return {
            'target_speed_mps': current_speed_mps,
            'target_spacing_m': join_spacing,
            'target_time_gap_s': target_time_gap,
            'approach_rate_mps': 0.5  # Gentle approach
        }

    def confirm_join_complete(self) -> bool:
        """
        Confirm that join maneuver is complete and stable.
        """
        if self.role != PlatoonRole.JOINING:
            return False

        # Check if spacing is within tolerance
        # Check if V2V communication is stable
        # (Simplified for example)

        self.role = PlatoonRole.FOLLOWER
        self.state = PlatoonState.STABLE
        print(f"Vehicle {self.vehicle_id} successfully joined platoon")
        return True

    def request_leave_platoon(self, reason: str = "") -> bool:
        """
        Request to leave the platoon.
        """
        if self.role == PlatoonRole.LEADER:
            # Leader leaving requires handoff or dissolution
            return self._initiate_leader_handoff()
        else:
            self.role = PlatoonRole.LEAVING
            self.state = PlatoonState.SPLITTING
            print(f"Vehicle {self.vehicle_id} leaving platoon: {reason}")
            return True

    def execute_leave_maneuver(self) -> dict:
        """
        Execute the leave maneuver.

        Returns:
            Control commands for safe departure
        """
        # Gradually increase spacing
        # Move to adjacent lane when safe
        return {
            'target_spacing_m': self.config.min_spacing_m * 3.0,
            'lane_change_direction': 'right',
            'deceleration_mps2': -1.0  # Gentle deceleration
        }

    def confirm_leave_complete(self) -> bool:
        """
        Confirm that leave maneuver is complete.
        """
        self.role = PlatoonRole.LEADER  # Back to independent
        self.platoon_id = None
        self.members.clear()
        self.state = PlatoonState.STABLE
        print(f"Vehicle {self.vehicle_id} left platoon")
        return True

    def _initiate_leader_handoff(self) -> bool:
        """
        Hand off leadership to next vehicle in platoon.
        """
        if len(self.members) < 2:
            # No successor, just dissolve
            return self._dissolve_platoon()

        # Designate first follower as new leader
        next_leader = self.members[1]  # Position 1 is first follower
        print(f"Handing off leadership to vehicle {next_leader.vehicle_id}")

        # Send handoff command (via V2V)
        # ...

        self.role = PlatoonRole.LEAVING
        return True

    def _dissolve_platoon(self) -> bool:
        """
        Dissolve the platoon.
        """
        print(f"Dissolving platoon {self.platoon_id}")
        for member in self.members:
            # Send dissolution message to all members
            pass

        self.platoon_id = None
        self.members.clear()
        return True

    def calculate_fuel_savings(self, platoon_size: int, spacing_m: float) -> float:
        """
        Estimate fuel savings from platooning.

        Based on research: 5-15% savings for followers depending on spacing.
        """
        if platoon_size < 2:
            return 0.0

        # Leader: minimal savings
        if self.role == PlatoonRole.LEADER:
            return 0.02  # 2%

        # Followers: savings increase with closer spacing
        base_savings = 0.10  # 10% at 10m spacing
        spacing_factor = max(0.5, 1.0 - (spacing_m - 5.0) / 20.0)
        position_factor = 1.0 / (self.members[0].position_in_platoon + 1)

        return base_savings * spacing_factor * position_factor

# Example usage
if __name__ == "__main__":
    config = PlatoonConfig()
    vehicle = PlatoonManager(vehicle_id=42, config=config)

    # Request to join platoon
    can_join = vehicle.request_join_platoon(
        platoon_id=100,
        leader_speed_mps=25.0,
        own_speed_mps=24.0
    )

    if can_join:
        # Execute join maneuver
        commands = vehicle.execute_join_maneuver(
            target_position=3,
            current_speed_mps=24.5
        )
        print(f"Join commands: {commands}")

        # Simulate joining
        time.sleep(5)
        vehicle.confirm_join_complete()

        # Estimate fuel savings
        savings = vehicle.calculate_fuel_savings(platoon_size=4, spacing_m=8.0)
        print(f"Estimated fuel savings: {savings*100:.1f}%")
```

## Safety Application Integration

### Multi-Application Coordinator

```cpp
// v2v_app_coordinator.hpp
#pragma once

#include "eebl_detector.hpp"
#include "fcw_calculator.hpp"
#include "ima_module.hpp"
#include "cacc_controller.hpp"

namespace v2v {
namespace safety {

enum class WarningPriority {
    NONE = 0,
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    CRITICAL = 4
};

struct ApplicationWarning {
    std::string app_name;
    WarningPriority priority;
    std::string message;
    uint32_t timestamp_ms;
};

class V2VApplicationCoordinator {
public:
    V2VApplicationCoordinator();

    // Process all V2V applications
    void processApplications(
        const VehicleDynamics& own_dynamics,
        const std::vector<RemoteVehicle>& remote_vehicles
    );

    // Get highest priority warning for HMI
    ApplicationWarning getActiveWarning();

    // Enable/disable specific applications
    void setAppEnabled(const std::string& app_name, bool enabled);

private:
    EEBLDetector eebl_;
    FCWCalculator fcw_;
    // IMAModule ima_;
    // CACCController cacc_;

    std::vector<ApplicationWarning> active_warnings_;

    void processEEBL(const VehicleDynamics& dynamics);
    void processFCW(const VehicleDynamics& own, const RemoteVehicle& lead);

    ApplicationWarning selectHighestPriority();
};

} // namespace safety
} // namespace v2v
```

## Testing and Validation

### Hardware-in-Loop (HIL) Test Scenarios

```yaml
# v2v_hil_test_scenarios.yaml
scenarios:
  - name: EEBL_Hard_Braking
    description: Lead vehicle applies emergency brakes
    duration_s: 10
    steps:
      - time: 0
        action: Set lead vehicle speed to 25 m/s
        action: Set following vehicle speed to 25 m/s
        action: Set spacing to 30 m
      - time: 5
        action: Lead vehicle emergency brake at -8 m/s^2
      - time: 5.05
        expected: EEBL message transmitted
      - time: 5.15
        expected: Following vehicle receives warning
        expected: Following vehicle initiates braking

  - name: FCW_Closing_Speed
    description: Follower closing on slower lead vehicle
    duration_s: 15
    steps:
      - time: 0
        action: Set lead vehicle speed to 15 m/s
        action: Set following vehicle speed to 25 m/s
        action: Set spacing to 100 m
      - time: 5
        expected: FCW caution warning (TTC < 2.5s)
      - time: 8
        expected: FCW critical warning (TTC < 1.5s)
      - time: 10
        expected: Automatic emergency braking engaged

  - name: IMA_Crossing_Path
    description: Two vehicles on collision course at intersection
    duration_s: 8
    steps:
      - time: 0
        action: Vehicle A approaches from south at 15 m/s
        action: Vehicle B approaches from east at 12 m/s
      - time: 3
        expected: IMA warning issued to both vehicles
      - time: 5
        expected: One vehicle yields (protocol dependent)
```

## References

1. **SAE J2945/1**: On-Board System Requirements for V2V Safety Communications
2. **NHTSA**: Vehicle-to-Vehicle Communication Technology for Light Vehicles
3. **Shladover, S. et al.**: "Cooperative Adaptive Cruise Control: Testing Drivers' Choices and Reactions"
4. **Ploeg, J. et al.**: "Design and Experimental Evaluation of Cooperative Adaptive Cruise Control"
5. **Rajamani, R.**: "Vehicle Dynamics and Control" (Chapter on ACC/CACC)

---

## V2X Protocols Standards

# V2X Protocols and Standards

## Overview
Comprehensive guide to V2X (Vehicle-to-Everything) communication protocols, comparing DSRC/802.11p and C-V2X technologies, covering SAE J2735, ETSI ITS-G5, 5GAA specifications, and cooperative perception messages.

## Technology Comparison: DSRC vs C-V2X

### DSRC (Dedicated Short-Range Communications)

**Physical Layer:**
- **IEEE 802.11p**: Modified Wi-Fi for vehicular environments
- **Frequency**: 5.9 GHz band (5.855-5.925 GHz)
- **Channel bandwidth**: 10 MHz (half of 802.11a)
- **Data rates**: 3, 4.5, 6, 9, 12, 18, 24, 27 Mbps
- **Range**: 300-1000 meters (depending on power and environment)
- **Latency**: < 50ms (target), typically 20-100ms measured

**Key Characteristics:**
```
Advantages:
- No network infrastructure required (ad-hoc)
- Low latency for safety messages
- Proven technology with field deployments
- Direct vehicle-to-vehicle communication
- Works in areas without cellular coverage

Disadvantages:
- Limited range compared to cellular
- No network-level QoS guarantees
- Congestion issues in high vehicle density
- Limited penetration through obstacles
```

### C-V2X (Cellular Vehicle-to-Everything)

**Physical Layer:**
- **3GPP Release 14**: LTE-V2X (initial version)
- **3GPP Release 16/17**: 5G NR V2X (advanced features)
- **Frequency**: 5.9 GHz (same as DSRC) + cellular bands
- **Communication modes**:
  - **Mode 3**: Network-scheduled (infrastructure)
  - **Mode 4**: Direct D2D/sidelink (no infrastructure)

**Key Characteristics:**
```
Advantages:
- Better non-line-of-sight (NLOS) performance
- Longer range (up to 2-3 km with cellular)
- Evolution path to 5G (forward compatibility)
- Network slicing and QoS support
- Integration with MEC (Multi-access Edge Computing)

Disadvantages:
- Requires cellular network for Mode 3
- Higher complexity and cost
- Newer technology (less deployment history)
- Potential latency issues with network routing
```

## SAE J2735: Message Set for V2X Communications

### Core Message Types

**BSM (Basic Safety Message)**
```asn1
-- SAE J2735 BSM Definition (ASN.1)
BasicSafetyMessage ::= SEQUENCE {
    coreData BSMcoreData,
    partII SEQUENCE (SIZE(1..8)) OF PartIIcontent OPTIONAL,
    regional SEQUENCE (SIZE(1..4)) OF RegionalExtension OPTIONAL
}

BSMcoreData ::= SEQUENCE {
    msgCnt MsgCount,
    id TemporaryID,
    secMark DSecond,
    lat Latitude,
    long Longitude,
    elev Elevation,
    accuracy PositionalAccuracy,
    transmission TransmissionState,
    speed Speed,
    heading Heading,
    angle SteeringWheelAngle,
    accelSet AccelerationSet4Way,
    brakes BrakeSystemStatus,
    size VehicleSize
}
```

**BSM Transmission Requirements:**
- **Frequency**: 10 Hz (every 100ms) for moving vehicles
- **Frequency**: 1-2 Hz for stationary vehicles
- **Message size**: ~100-300 bytes (depending on Part II content)
- **Priority**: Highest (safety-critical)
- **Latency requirement**: < 100ms end-to-end

### C++ Implementation: BSM Encoder

```cpp
// bsm_encoder.hpp
#pragma once

#include <cstdint>
#include <vector>
#include <array>

namespace v2x {
namespace j2735 {

// Core data structures
struct PositionalAccuracy {
    uint8_t semiMajor;  // 0-255 (0.05m resolution)
    uint8_t semiMinor;
    uint16_t orientation;  // 0-65535 (0.0054 deg resolution)
};

struct AccelerationSet4Way {
    int16_t longitudinal;  // -2000 to 2001 (0.01 m/s^2)
    int16_t lateral;
    int16_t vertical;
    int16_t yawRate;  // -32767 to 32767 (0.01 deg/s)
};

struct BrakeSystemStatus {
    uint8_t wheelBrakes;  // Bit field: left/right front/rear
    uint8_t traction;  // 0=unavailable, 1=off, 2=on, 3=engaged
    uint8_t abs;
    uint8_t scs;  // Stability control
    uint8_t brakeBoost;
    uint8_t auxBrakes;
};

struct BSMcoreData {
    uint8_t msgCnt;  // 0-127, wraps
    uint32_t temporaryID;  // Random ID, changed periodically
    uint16_t secMark;  // Milliseconds within minute
    int32_t latitude;  // 1/10 micro-degree
    int32_t longitude;  // 1/10 micro-degree
    int32_t elevation;  // 10 cm resolution
    PositionalAccuracy accuracy;
    uint8_t transmission;  // Neutral, park, forward gears, reverse
    uint16_t speed;  // 0.02 m/s resolution
    uint16_t heading;  // 0.0125 deg resolution
    int8_t steeringAngle;  // 1.5 deg resolution
    AccelerationSet4Way accelSet;
    BrakeSystemStatus brakes;
    uint8_t vehicleWidth;  // cm
    uint8_t vehicleLength;  // cm
};

class BSMEncoder {
public:
    BSMEncoder();

    // Encode BSM to UPER (Unaligned Packed Encoding Rules)
    std::vector<uint8_t> encodeBSM(const BSMcoreData& coreData);

    // Decode BSM from UPER
    bool decodeBSM(const std::vector<uint8_t>& data, BSMcoreData& coreData);

    // Update BSM from vehicle state
    void updateFromVehicleState(
        BSMcoreData& bsm,
        double lat, double lon, double elevation,
        double speed_mps, double heading_deg,
        double accel_long, double accel_lat,
        double yaw_rate_degps,
        uint8_t brake_status
    );

private:
    uint8_t msgCounter_;

    // Helper functions for encoding
    void encodeLat(std::vector<uint8_t>& buffer, int32_t lat);
    void encodeLon(std::vector<uint8_t>& buffer, int32_t lon);
    void encodeSpeed(std::vector<uint8_t>& buffer, uint16_t speed);
};

} // namespace j2735
} // namespace v2x
```

```cpp
// bsm_encoder.cpp
#include "bsm_encoder.hpp"
#include <cmath>
#include <cstring>

namespace v2x {
namespace j2735 {

BSMEncoder::BSMEncoder() : msgCounter_(0) {}

void BSMEncoder::updateFromVehicleState(
    BSMcoreData& bsm,
    double lat, double lon, double elevation,
    double speed_mps, double heading_deg,
    double accel_long, double accel_lat,
    double yaw_rate_degps,
    uint8_t brake_status
) {
    bsm.msgCnt = msgCounter_++;
    if (msgCounter_ > 127) msgCounter_ = 0;

    // Convert to J2735 units
    bsm.latitude = static_cast<int32_t>(lat * 10000000.0);  // 1/10 micro-degree
    bsm.longitude = static_cast<int32_t>(lon * 10000000.0);
    bsm.elevation = static_cast<int32_t>(elevation * 10.0);  // 10 cm

    // Speed: 0.02 m/s resolution
    bsm.speed = static_cast<uint16_t>(speed_mps / 0.02);
    if (bsm.speed > 8191) bsm.speed = 8191;  // Max value

    // Heading: 0.0125 deg resolution
    bsm.heading = static_cast<uint16_t>(heading_deg / 0.0125);
    bsm.heading %= 28800;  // Wrap at 360 degrees

    // Acceleration: 0.01 m/s^2 resolution
    bsm.accelSet.longitudinal = static_cast<int16_t>(accel_long / 0.01);
    bsm.accelSet.lateral = static_cast<int16_t>(accel_lat / 0.01);
    bsm.accelSet.yawRate = static_cast<int16_t>(yaw_rate_degps / 0.01);

    // Brake status (simplified)
    bsm.brakes.wheelBrakes = brake_status;
}

std::vector<uint8_t> BSMEncoder::encodeBSM(const BSMcoreData& coreData) {
    std::vector<uint8_t> buffer;
    buffer.reserve(200);  // Typical BSM size

    // Message ID (0x14 for BSM)
    buffer.push_back(0x00);
    buffer.push_back(0x14);

    // Message count (7 bits)
    buffer.push_back(coreData.msgCnt & 0x7F);

    // Temporary ID (4 bytes)
    buffer.push_back((coreData.temporaryID >> 24) & 0xFF);
    buffer.push_back((coreData.temporaryID >> 16) & 0xFF);
    buffer.push_back((coreData.temporaryID >> 8) & 0xFF);
    buffer.push_back(coreData.temporaryID & 0xFF);

    // DSecond (milliseconds within minute, 16 bits)
    buffer.push_back((coreData.secMark >> 8) & 0xFF);
    buffer.push_back(coreData.secMark & 0xFF);

    // Latitude (32 bits, signed)
    encodeLat(buffer, coreData.latitude);

    // Longitude (32 bits, signed)
    encodeLon(buffer, coreData.longitude);

    // Elevation (16 bits)
    buffer.push_back((coreData.elevation >> 8) & 0xFF);
    buffer.push_back(coreData.elevation & 0xFF);

    // Positional accuracy
    buffer.push_back(coreData.accuracy.semiMajor);
    buffer.push_back(coreData.accuracy.semiMinor);
    buffer.push_back((coreData.accuracy.orientation >> 8) & 0xFF);
    buffer.push_back(coreData.accuracy.orientation & 0xFF);

    // Transmission state (3 bits) + padding
    buffer.push_back((coreData.transmission & 0x07) << 5);

    // Speed (13 bits)
    encodeSpeed(buffer, coreData.speed);

    // Heading (16 bits)
    buffer.push_back((coreData.heading >> 8) & 0xFF);
    buffer.push_back(coreData.heading & 0xFF);

    // Steering angle (8 bits, signed)
    buffer.push_back(static_cast<uint8_t>(coreData.steeringAngle));

    // Acceleration set (4 x 16 bits)
    buffer.push_back((coreData.accelSet.longitudinal >> 8) & 0xFF);
    buffer.push_back(coreData.accelSet.longitudinal & 0xFF);
    buffer.push_back((coreData.accelSet.lateral >> 8) & 0xFF);
    buffer.push_back(coreData.accelSet.lateral & 0xFF);
    buffer.push_back((coreData.accelSet.vertical >> 8) & 0xFF);
    buffer.push_back(coreData.accelSet.vertical & 0xFF);
    buffer.push_back((coreData.accelSet.yawRate >> 8) & 0xFF);
    buffer.push_back(coreData.accelSet.yawRate & 0xFF);

    // Brake system status (5 bytes)
    buffer.push_back(coreData.brakes.wheelBrakes);
    buffer.push_back(coreData.brakes.traction);
    buffer.push_back(coreData.brakes.abs);
    buffer.push_back(coreData.brakes.scs);
    buffer.push_back(coreData.brakes.brakeBoost);

    // Vehicle size
    buffer.push_back(coreData.vehicleWidth);
    buffer.push_back(coreData.vehicleLength);

    return buffer;
}

void BSMEncoder::encodeLat(std::vector<uint8_t>& buffer, int32_t lat) {
    buffer.push_back((lat >> 24) & 0xFF);
    buffer.push_back((lat >> 16) & 0xFF);
    buffer.push_back((lat >> 8) & 0xFF);
    buffer.push_back(lat & 0xFF);
}

void BSMEncoder::encodeLon(std::vector<uint8_t>& buffer, int32_t lon) {
    buffer.push_back((lon >> 24) & 0xFF);
    buffer.push_back((lon >> 16) & 0xFF);
    buffer.push_back((lon >> 8) & 0xFF);
    buffer.push_back(lon & 0xFF);
}

void BSMEncoder::encodeSpeed(std::vector<uint8_t>& buffer, uint16_t speed) {
    // 13-bit encoding
    buffer.push_back((speed >> 5) & 0xFF);
    buffer.push_back((speed & 0x1F) << 3);
}

} // namespace j2735
} // namespace v2x
```

## ETSI ITS-G5 Standards

### CAM (Cooperative Awareness Message)

**ETSI EN 302 637-2 CAM Format:**
```asn1
CAM ::= SEQUENCE {
    header ItsPduHeader,
    cam CoopAwareness
}

CoopAwareness ::= SEQUENCE {
    generationDeltaTime GenerationDeltaTime,
    camParameters CamParameters
}

CamParameters ::= SEQUENCE {
    basicContainer BasicContainer,
    highFrequencyContainer HighFrequencyContainer,
    lowFrequencyContainer LowFrequencyContainer OPTIONAL,
    specialVehicleContainer SpecialVehicleContainer OPTIONAL
}

BasicContainer ::= SEQUENCE {
    stationType StationType,
    referencePosition ReferencePosition
}

HighFrequencyContainer ::= CHOICE {
    basicVehicleContainerHighFrequency BasicVehicleContainerHighFrequency,
    rsuContainerHighFrequency RSUContainerHighFrequency
}
```

**CAM Generation Rules:**
- **Frequency**: 1-10 Hz (adaptive based on vehicle dynamics)
- **Triggering conditions**:
  - Position change > 4 meters
  - Speed change > 0.5 m/s
  - Heading change > 4 degrees
  - Maximum interval: 1 second

### DENM (Decentralized Environmental Notification Message)

**Use cases:**
- Emergency brake warning
- Road hazard notification
- Accident notification
- Weather warnings

## 5GAA Specifications

### Message Flow Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                     │
│  (V2V Safety Apps, V2I Traffic Apps, V2N Cloud Apps)   │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│              Facilities Layer (5GAA)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │   CAM    │  │   DENM   │  │  CPM (Collective     │  │
│  │ Manager  │  │ Manager  │  │  Perception Message) │  │
│  └──────────┘  └──────────┘  └──────────────────────┘  │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│              Transport & Network Layer                   │
│  ┌────────────────────┐  ┌───────────────────────────┐  │
│  │  GeoNetworking     │  │   IPv6 / UDP / TCP        │  │
│  │  (ETSI EN 302 636) │  │   (for C-V2X)             │  │
│  └────────────────────┘  └───────────────────────────┘  │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│              Access Layer (PHY/MAC)                      │
│  ┌────────────────────┐  ┌───────────────────────────┐  │
│  │  ITS-G5 (802.11p)  │  │   C-V2X PC5 (Mode 4)      │  │
│  │  DSRC              │  │   LTE-V / 5G NR-V         │  │
│  └────────────────────┘  └───────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Cooperative Perception Messages (CPM)

### CPM Structure (ETSI TR 103 324)

```cpp
// cpm.hpp - Collective Perception Message
#pragma once

#include <vector>
#include <cstdint>

namespace v2x {
namespace etsi {

enum class ObjectType : uint8_t {
    UNKNOWN = 0,
    VEHICLE = 1,
    PEDESTRIAN = 2,
    CYCLIST = 3,
    MOTORCYCLE = 4,
    ANIMAL = 5,
    ROAD_HAZARD = 6
};

struct PerceivedObject {
    uint16_t objectID;  // Unique ID within CPM
    uint16_t timeOfMeasurement;  // Delta time in ms

    // Position relative to reference point
    int16_t xDistance;  // cm
    int16_t yDistance;  // cm
    int16_t zDistance;  // cm (optional)

    // Object dimensions
    uint16_t objectLength;  // cm
    uint16_t objectWidth;   // cm
    uint16_t objectHeight;  // cm

    // Dynamics
    int16_t xSpeed;  // cm/s
    int16_t ySpeed;  // cm/s
    int16_t xAcceleration;  // cm/s^2 (optional)
    int16_t yAcceleration;  // cm/s^2 (optional)

    // Classification
    ObjectType objectType;
    uint8_t objectConfidence;  // 0-100%

    // Sensor that detected this object
    uint8_t sensorID;
};

struct SensorInformation {
    uint8_t sensorID;
    uint8_t sensorType;  // 0=camera, 1=radar, 2=lidar, 3=fusion
    int16_t xOffset;  // cm from reference point
    int16_t yOffset;  // cm
    uint16_t detectionRange;  // cm
    uint16_t horizontalOpeningAngle;  // 0.1 degree
};

struct CPM {
    uint8_t protocolVersion;
    uint16_t stationID;
    uint16_t generationDeltaTime;  // ms since last UTC second

    // Reference position (same as CAM)
    int32_t latitude;   // 1/10 micro-degree
    int32_t longitude;  // 1/10 micro-degree

    // Management container
    uint8_t messageRateHz;
    uint16_t perceptionRegionRadius;  // meters

    // Sensor information
    std::vector<SensorInformation> sensors;

    // Perceived objects
    std::vector<PerceivedObject> perceivedObjects;

    // Optional: Free space areas
    // std::vector<FreeSpaceArea> freeSpaceAreas;
};

class CPMManager {
public:
    CPMManager(uint16_t stationID);

    // Add perceived object from sensor
    void addPerceivedObject(const PerceivedObject& obj);

    // Generate CPM message
    CPM generateCPM();

    // Encode CPM to wire format
    std::vector<uint8_t> encodeCPM(const CPM& cpm);

    // Decode received CPM
    bool decodeCPM(const std::vector<uint8_t>& data, CPM& cpm);

    // Fusion: merge perceived objects from multiple sensors
    void fuseObjects(const std::vector<PerceivedObject>& objects);

    // Age out old objects
    void cleanupStaleObjects(uint32_t maxAge_ms);

private:
    uint16_t stationID_;
    std::vector<PerceivedObject> objectList_;
    std::vector<SensorInformation> sensorList_;

    // Object tracking and ID management
    uint16_t nextObjectID_;

    // Helper: match objects across time steps
    bool matchObjects(const PerceivedObject& obj1,
                     const PerceivedObject& obj2,
                     float threshold_m);
};

} // namespace etsi
} // namespace v2x
```

## Latency Requirements and QoS

### Message Priority Classes

| Message Type | Latency Requirement | Frequency | Range | Priority |
|-------------|---------------------|-----------|-------|----------|
| BSM/CAM | < 100 ms | 10 Hz | 300 m | Highest |
| DENM (Emergency) | < 50 ms | Event-triggered | 1000 m | Highest |
| CPM | < 100 ms | 1-4 Hz | 300 m | High |
| SPaT (Traffic signal) | < 100 ms | 10 Hz | 300 m | High |
| MAP | < 1 s | 1 Hz or static | 300 m | Medium |
| TIM (Traveler info) | < 1 s | Event-triggered | Variable | Low |

### DSRC Channel Allocation (US)

```
Channel 172 (5.860 GHz): Control channel (CCH)
  - BSM broadcast
  - Service announcements
  - Safety-critical messages

Channel 174 (5.870 GHz): Service channel (SCH)
  - Non-safety applications

Channel 176 (5.880 GHz): Service channel (SCH)
  - High-power long-range

Channel 178 (5.890 GHz): Service channel (SCH)
  - Public safety

Channel 180 (5.900 GHz): Service channel (SCH)
  - General purpose

Channel 182 (5.910 GHz): Service channel (SCH)
  - High availability

Channel 184 (5.920 GHz): Service channel (SCH)
  - Reserved
```

## Python: Message Rate Adapter

```python
# message_rate_adapter.py
"""
Adaptive message rate controller for V2X communications.
Adjusts BSM/CAM rate based on vehicle dynamics to optimize bandwidth.
"""

import time
import math
from dataclasses import dataclass
from typing import Optional

@dataclass
class VehicleState:
    latitude: float
    longitude: float
    speed_mps: float
    heading_deg: float
    timestamp: float

class MessageRateAdapter:
    """
    Adaptive message generation rate controller.

    ETSI EN 302 637-2 rules:
    - Position change > 4 meters
    - Speed change > 0.5 m/s
    - Heading change > 4 degrees
    - Maximum interval: 1 second
    - Minimum interval: 100 ms (10 Hz)
    """

    def __init__(self,
                 min_interval_s: float = 0.1,
                 max_interval_s: float = 1.0,
                 position_threshold_m: float = 4.0,
                 speed_threshold_mps: float = 0.5,
                 heading_threshold_deg: float = 4.0):
        self.min_interval = min_interval_s
        self.max_interval = max_interval_s
        self.position_threshold = position_threshold_m
        self.speed_threshold = speed_threshold_mps
        self.heading_threshold = heading_threshold_deg

        self.last_transmitted_state: Optional[VehicleState] = None
        self.last_transmission_time: float = 0.0

    def should_transmit(self, current_state: VehicleState) -> bool:
        """
        Determine if a message should be transmitted based on current vehicle state.

        Returns:
            True if message should be sent, False otherwise
        """
        current_time = current_state.timestamp

        # First message
        if self.last_transmitted_state is None:
            return True

        # Check maximum interval
        time_since_last = current_time - self.last_transmission_time
        if time_since_last >= self.max_interval:
            return True

        # Don't transmit faster than min interval
        if time_since_last < self.min_interval:
            return False

        # Check position change
        distance = self._calculate_distance(
            self.last_transmitted_state.latitude,
            self.last_transmitted_state.longitude,
            current_state.latitude,
            current_state.longitude
        )

        if distance >= self.position_threshold:
            return True

        # Check speed change
        speed_change = abs(current_state.speed_mps -
                          self.last_transmitted_state.speed_mps)
        if speed_change >= self.speed_threshold:
            return True

        # Check heading change
        heading_change = self._angle_difference(
            current_state.heading_deg,
            self.last_transmitted_state.heading_deg
        )

        if heading_change >= self.heading_threshold:
            return True

        return False

    def mark_transmitted(self, state: VehicleState):
        """Record that a message was transmitted with this state."""
        self.last_transmitted_state = state
        self.last_transmission_time = state.timestamp

    @staticmethod
    def _calculate_distance(lat1: float, lon1: float,
                           lat2: float, lon2: float) -> float:
        """
        Calculate distance between two GPS coordinates using Haversine formula.

        Returns:
            Distance in meters
        """
        R = 6371000  # Earth radius in meters

        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = (math.sin(delta_phi / 2) ** 2 +
             math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return R * c

    @staticmethod
    def _angle_difference(angle1: float, angle2: float) -> float:
        """
        Calculate minimum angular difference between two angles.

        Returns:
            Difference in degrees [0, 180]
        """
        diff = abs(angle1 - angle2) % 360
        if diff > 180:
            diff = 360 - diff
        return diff

# Example usage
if __name__ == "__main__":
    adapter = MessageRateAdapter()

    # Simulate vehicle states
    states = [
        VehicleState(37.7749, -122.4194, 15.0, 90.0, 0.0),
        VehicleState(37.7749, -122.4193, 15.0, 90.0, 0.1),  # Small change
        VehicleState(37.7750, -122.4190, 15.0, 90.0, 0.2),  # Position change
        VehicleState(37.7750, -122.4190, 20.0, 90.0, 0.3),  # Speed change
        VehicleState(37.7750, -122.4190, 20.0, 95.0, 0.4),  # Heading change
    ]

    for state in states:
        if adapter.should_transmit(state):
            print(f"TRANSMIT at t={state.timestamp:.1f}s: "
                  f"pos=({state.latitude:.6f},{state.longitude:.6f}), "
                  f"speed={state.speed_mps:.1f} m/s, "
                  f"heading={state.heading_deg:.1f}°")
            adapter.mark_transmitted(state)
        else:
            print(f"SKIP at t={state.timestamp:.1f}s")
```

## Standards Compliance Checklist

### SAE J2735 Compliance
- [ ] BSM generation at 10 Hz for moving vehicles
- [ ] Temporary ID rotation every 5 minutes
- [ ] Message counter wrapping at 127
- [ ] Proper coordinate system (WGS-84)
- [ ] Elevation relative to WGS-84 ellipsoid
- [ ] Speed, acceleration, and heading encodings per spec

### ETSI ITS-G5 Compliance
- [ ] CAM generation with adaptive rate
- [ ] DENM event-triggered transmission
- [ ] GeoNetworking header compliance
- [ ] Security header (if required)
- [ ] ITS PDU header format

### IEEE 1609 Family Compliance
- [ ] 1609.2: Security services
- [ ] 1609.3: Networking services (WSMP)
- [ ] 1609.4: Multi-channel operation
- [ ] 1609.12: Provider Service Identifier (PSID)

## References

1. **SAE J2735**: Dedicated Short Range Communications (DSRC) Message Set Dictionary
2. **ETSI EN 302 637-2**: Intelligent Transport Systems (ITS); Vehicular Communications; Basic Set of Applications; Part 2: Specification of Cooperative Awareness Basic Service
3. **ETSI EN 302 637-3**: Specification of Decentralized Environmental Notification Basic Service
4. **ETSI TR 103 324**: Collective Perception Service
5. **IEEE 802.11p**: Wireless LAN in Vehicular Environments
6. **3GPP TS 22.185**: Service requirements for V2X services
7. **5GAA**: Automotive Association specifications and white papers

---

## V2X Security Certificates

# V2X Security and Certificates

## Overview
Comprehensive guide to V2X security including IEEE 1609.2 security services, SCMS (Security Credential Management System), certificate enrollment, pseudonym certificates, misbehavior detection, and revocation mechanisms.

## IEEE 1609.2 Security Standard

### Security Services

**Core Security Goals:**
```
1. Authentication: Verify message sender identity
2. Integrity: Detect message tampering
3. Non-repudiation: Sender cannot deny transmission
4. Privacy: Protect sender identity (pseudonymity)
5. Confidentiality: Encrypt sensitive data (optional for V2V)
```

### Certificate Types

| Certificate Type | Purpose | Lifetime | Usage |
|-----------------|---------|----------|-------|
| Root CA | Trust anchor | 10-20 years | Signs intermediate CAs |
| Intermediate CA | Issue enrollment certs | 3-5 years | Signs PCAs and enrollment certs |
| PCA (Pseudonym CA) | Issue pseudonym certs | 3-5 years | Signs pseudonym certificates |
| Enrollment Certificate | Device identity | 3 years | Request pseudonym certificates |
| Pseudonym Certificate | Message signing | 1 week | Sign BSMs, CAMs, etc. |
| Application Certificate | Specific app | Variable | Application-specific signing |

### IEEE 1609.2 Message Structure

```cpp
// ieee1609dot2_message.hpp
#pragma once

#include <vector>
#include <cstdint>
#include <array>

namespace v2x {
namespace security {

// ECDSA-256 with NIST P-256 curve
constexpr size_t SIGNATURE_SIZE = 64;  // r || s (32 bytes each)
constexpr size_t PUBLIC_KEY_SIZE = 64;  // x || y coordinates
constexpr size_t CERT_ID_SIZE = 8;     // HashedId8

enum class SecurityProfileIdentifier : uint8_t {
    NO_SECURITY = 0,
    BSM_SIGN = 1,
    DENM_SIGN = 2,
    CAM_SIGN = 3
};

// Hashed certificate identifier
using HashedId8 = std::array<uint8_t, CERT_ID_SIZE>;

// ECDSA signature
struct ECDSASignature {
    std::array<uint8_t, 32> r;
    std::array<uint8_t, 32> s;
};

// Public key (ECC Point)
struct ECCPoint {
    uint8_t compression;  // 0x04 for uncompressed
    std::array<uint8_t, 32> x;
    std::array<uint8_t, 32> y;
};

// Certificate structure (simplified IEEE 1609.2)
struct Certificate {
    uint8_t version;  // v3 = 3
    uint8_t type;     // explicit = 0, implicit = 1
    HashedId8 issuer; // Hashed ID of issuing CA

    // Subject info
    uint8_t subject_type;  // enrollment_credential = 0, pseudonym = 1

    // Validity period
    uint32_t start_time;  // Seconds since 2004-01-01 00:00:00 UTC
    uint32_t end_time;

    // Public key
    ECCPoint public_key;

    // Permissions (application permissions)
    std::vector<uint8_t> app_permissions;

    // Issuer signature
    ECDSASignature signature;
};

// Secured message structure
struct SecuredMessage {
    uint8_t protocol_version;  // 3 for IEEE 1609.2-2016

    // Header
    uint8_t security_profile;
    uint32_t generation_time;  // Microseconds since 2004-01-01
    uint64_t generation_location;  // 3D location (lat, lon, elev)

    // Signer info
    enum SignerType : uint8_t {
        CERTIFICATE = 0,
        CERTIFICATE_DIGEST = 1,
        CERTIFICATE_CHAIN = 2
    } signer_type;

    union {
        Certificate certificate;
        HashedId8 cert_digest;
        std::vector<Certificate> cert_chain;
    } signer_info;

    // Payload
    std::vector<uint8_t> payload;  // Actual message (BSM, CAM, etc.)

    // Signature
    ECDSASignature signature;
};

class IEEE1609Dot2Security {
public:
    IEEE1609Dot2Security();

    // Sign a message with pseudonym certificate
    SecuredMessage signMessage(
        const std::vector<uint8_t>& payload,
        const Certificate& signing_cert,
        const std::array<uint8_t, 32>& private_key,
        SecurityProfileIdentifier profile
    );

    // Verify received secured message
    bool verifyMessage(
        const SecuredMessage& secured_msg,
        const std::vector<Certificate>& trusted_certs
    );

    // Extract payload from secured message
    std::vector<uint8_t> extractPayload(const SecuredMessage& secured_msg);

private:
    // ECDSA sign with NIST P-256
    ECDSASignature ecdsaSign(
        const std::vector<uint8_t>& data,
        const std::array<uint8_t, 32>& private_key
    );

    // ECDSA verify
    bool ecdsaVerify(
        const std::vector<uint8_t>& data,
        const ECDSASignature& signature,
        const ECCPoint& public_key
    );

    // SHA-256 hash
    std::array<uint8_t, 32> sha256(const std::vector<uint8_t>& data);

    // Generate HashedId8 from certificate
    HashedId8 hashCertificate(const Certificate& cert);
};

} // namespace security
} // namespace v2x
```

## Security Credential Management System (SCMS)

### SCMS Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    SCMS Root CA                              │
│  (Offline, air-gapped, generates root certificate)          │
└────────────────────────┬─────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Intermediate │  │ Intermediate │  │ Intermediate │
│   CA (ICA)   │  │   CA (ICA)   │  │   CA (ICA)   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └────────┬────────┴─────────────────┘
                │
        ┌───────┴────────┐
        │                │
        ▼                ▼
┌──────────────┐  ┌──────────────┐
│ Enrollment   │  │  Pseudonym   │
│ Certificate  │  │   CA (PCA)   │
│ Authority    │  │              │
│   (ECA)      │  │              │
└──────┬───────┘  └──────┬───────┘
       │                 │
       │                 │
       │    ┌────────────┼────────────┐
       │    │            │            │
       ▼    ▼            ▼            ▼
    ┌─────────────────────────────────────┐
    │           OBU (Vehicle)             │
    │  - Enrollment Certificate           │
    │  - Pseudonym Certificate Pool       │
    │    (100-300 certificates)           │
    │  - Certificate change strategy      │
    └─────────────────────────────────────┘
```

### Certificate Enrollment Process

```python
# scms_enrollment.py
"""
SCMS certificate enrollment and pseudonym management.
"""

import hashlib
import secrets
import time
from dataclasses import dataclass
from typing import List, Optional
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.backends import default_backend

@dataclass
class CertificateRequest:
    """Certificate Signing Request (CSR)"""
    subject_type: str  # "enrollment" or "pseudonym"
    public_key: bytes  # DER encoded public key
    validity_period_days: int
    permissions: List[str]  # ["bsm", "denm", "cam"]
    request_time: int
    nonce: bytes

@dataclass
class Certificate:
    """V2X Certificate"""
    version: int
    cert_id: bytes  # HashedId8
    issuer_id: bytes  # HashedId8
    subject_type: str
    public_key: bytes
    start_time: int  # Epoch
    end_time: int
    permissions: List[str]
    signature: bytes

    def is_valid(self, current_time: int) -> bool:
        """Check if certificate is currently valid."""
        return self.start_time <= current_time <= self.end_time

    def is_expired(self, current_time: int) -> bool:
        """Check if certificate has expired."""
        return current_time > self.end_time

class SCMSEnrollment:
    """
    SCMS certificate enrollment and management.
    """

    def __init__(self, device_id: str):
        self.device_id = device_id

        # Generate enrollment key pair (long-term)
        self.enrollment_private_key = ec.generate_private_key(
            ec.SECP256R1(), default_backend()
        )
        self.enrollment_public_key = self.enrollment_private_key.public_key()

        # Certificate storage
        self.enrollment_cert: Optional[Certificate] = None
        self.pseudonym_cert_pool: List[Certificate] = []
        self.current_pseudonym_index: int = 0

        # Revocation list
        self.revoked_cert_ids: set = set()

    def enroll(self, eca_url: str) -> bool:
        """
        Enroll with SCMS Enrollment Certificate Authority.

        Args:
            eca_url: URL of ECA service

        Returns:
            True if enrollment successful
        """
        print(f"Enrolling device {self.device_id} with ECA...")

        # Create enrollment certificate request
        csr = CertificateRequest(
            subject_type="enrollment",
            public_key=self.enrollment_public_key.public_bytes(
                encoding=serialization.Encoding.DER,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            ),
            validity_period_days=1095,  # 3 years
            permissions=["request_pseudonym_certs"],
            request_time=int(time.time()),
            nonce=secrets.token_bytes(16)
        )

        # Sign CSR with enrollment private key
        csr_signature = self._sign_request(csr)

        # Send to ECA (simulated)
        enrollment_cert = self._request_enrollment_cert(eca_url, csr, csr_signature)

        if enrollment_cert:
            self.enrollment_cert = enrollment_cert
            print(f"Enrollment successful. Certificate ID: {enrollment_cert.cert_id.hex()}")
            return True
        else:
            print("Enrollment failed")
            return False

    def request_pseudonym_certificates(
        self,
        pca_url: str,
        count: int = 20,
        duration_days: int = 7
    ) -> int:
        """
        Request batch of pseudonym certificates from PCA.

        Args:
            pca_url: URL of PCA service
            count: Number of pseudonym certificates to request
            duration_days: Validity period for each certificate

        Returns:
            Number of certificates received
        """
        if not self.enrollment_cert:
            print("ERROR: Must enroll first")
            return 0

        print(f"Requesting {count} pseudonym certificates from PCA...")

        # Generate key pairs for pseudonym certificates
        pseudonym_keys = []
        for i in range(count):
            private_key = ec.generate_private_key(ec.SECP256R1(), default_backend())
            public_key = private_key.public_key()
            pseudonym_keys.append((private_key, public_key))

        # Create batch request
        public_keys_der = [
            pk.public_bytes(
                encoding=serialization.Encoding.DER,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            )
            for _, pk in pseudonym_keys
        ]

        # Request pseudonym certificates (simulated)
        pseudonym_certs = self._request_pseudonym_certs(
            pca_url,
            public_keys_der,
            duration_days
        )

        if pseudonym_certs:
            self.pseudonym_cert_pool.extend(pseudonym_certs)
            print(f"Received {len(pseudonym_certs)} pseudonym certificates")
            print(f"Certificate pool size: {len(self.pseudonym_cert_pool)}")
            return len(pseudonym_certs)

        return 0

    def get_current_pseudonym_cert(self) -> Optional[Certificate]:
        """Get current pseudonym certificate for message signing."""
        if not self.pseudonym_cert_pool:
            return None

        # Check if current cert is still valid
        current_time = int(time.time())
        current_cert = self.pseudonym_cert_pool[self.current_pseudonym_index]

        if current_cert.is_expired(current_time):
            # Move to next certificate
            self.rotate_pseudonym_cert()
            current_cert = self.pseudonym_cert_pool[self.current_pseudonym_index]

        return current_cert

    def rotate_pseudonym_cert(self):
        """
        Rotate to next pseudonym certificate.

        Certificate change strategy:
        - Time-based: Every 5 minutes
        - Location-based: When crossing region boundaries
        - Random: Add unpredictability
        """
        if not self.pseudonym_cert_pool:
            return

        # Move to next certificate in pool
        self.current_pseudonym_index = (self.current_pseudonym_index + 1) % len(self.pseudonym_cert_pool)

        new_cert = self.pseudonym_cert_pool[self.current_pseudonym_index]
        print(f"Rotated to pseudonym certificate: {new_cert.cert_id.hex()[:16]}...")

        # Check pool health
        current_time = int(time.time())
        valid_certs = sum(1 for cert in self.pseudonym_cert_pool if cert.is_valid(current_time))

        if valid_certs < 10:
            print(f"WARNING: Only {valid_certs} valid certificates remaining")
            print("Consider requesting new batch")

    def check_revocation(self, cert_id: bytes, crl_url: str) -> bool:
        """
        Check if certificate has been revoked.

        Args:
            cert_id: Certificate ID to check
            crl_url: URL of Certificate Revocation List

        Returns:
            True if revoked, False otherwise
        """
        # Check local cache
        if cert_id in self.revoked_cert_ids:
            return True

        # Query CRL (simulated)
        # In production, download and verify CRL signature
        is_revoked = self._query_crl(crl_url, cert_id)

        if is_revoked:
            self.revoked_cert_ids.add(cert_id)

        return is_revoked

    def _sign_request(self, csr: CertificateRequest) -> bytes:
        """Sign certificate request with enrollment private key."""
        # Serialize CSR
        csr_bytes = self._serialize_csr(csr)

        # Sign with ECDSA
        signature = self.enrollment_private_key.sign(
            csr_bytes,
            ec.ECDSA(hashes.SHA256())
        )

        return signature

    def _serialize_csr(self, csr: CertificateRequest) -> bytes:
        """Serialize CSR to bytes."""
        # Simplified serialization
        data = b''
        data += csr.subject_type.encode()
        data += csr.public_key
        data += str(csr.validity_period_days).encode()
        data += ','.join(csr.permissions).encode()
        data += str(csr.request_time).encode()
        data += csr.nonce
        return data

    def _request_enrollment_cert(
        self,
        eca_url: str,
        csr: CertificateRequest,
        signature: bytes
    ) -> Optional[Certificate]:
        """
        Request enrollment certificate from ECA.
        (Simulated - in production, this would be HTTPS POST)
        """
        # Simulate ECA processing
        print(f"Connecting to ECA at {eca_url}")
        print("Verifying device identity...")
        print("Issuing enrollment certificate...")

        # Generate cert ID
        cert_id = hashlib.sha256(csr.public_key).digest()[:8]

        # Simulate issued certificate
        cert = Certificate(
            version=3,
            cert_id=cert_id,
            issuer_id=b'\x00' * 8,  # ECA ID
            subject_type="enrollment",
            public_key=csr.public_key,
            start_time=int(time.time()),
            end_time=int(time.time()) + (csr.validity_period_days * 86400),
            permissions=csr.permissions,
            signature=b'\x00' * 64  # Simulated signature
        )

        return cert

    def _request_pseudonym_certs(
        self,
        pca_url: str,
        public_keys: List[bytes],
        duration_days: int
    ) -> List[Certificate]:
        """
        Request pseudonym certificates from PCA.
        (Simulated)
        """
        print(f"Connecting to PCA at {pca_url}")
        print(f"Requesting {len(public_keys)} pseudonym certificates...")

        certs = []
        current_time = int(time.time())

        for i, pub_key in enumerate(public_keys):
            # Stagger validity periods to avoid all expiring at once
            start_time = current_time + (i * 3600)  # Start 1 hour apart
            end_time = start_time + (duration_days * 86400)

            cert_id = hashlib.sha256(pub_key + str(i).encode()).digest()[:8]

            cert = Certificate(
                version=3,
                cert_id=cert_id,
                issuer_id=b'\xFF' * 8,  # PCA ID
                subject_type="pseudonym",
                public_key=pub_key,
                start_time=start_time,
                end_time=end_time,
                permissions=["bsm", "cam", "denm"],
                signature=b'\x00' * 64
            )
            certs.append(cert)

        return certs

    def _query_crl(self, crl_url: str, cert_id: bytes) -> bool:
        """
        Query Certificate Revocation List.
        (Simulated)
        """
        # In production: Download CRL, verify signature, check cert_id
        return False  # Assume not revoked for simulation


# Example usage
if __name__ == "__main__":
    # Initialize SCMS enrollment
    enrollment = SCMSEnrollment(device_id="OBU-12345678")

    # Step 1: Enroll with ECA
    if enrollment.enroll(eca_url="https://eca.scms.example.com"):
        # Step 2: Request pseudonym certificates
        cert_count = enrollment.request_pseudonym_certificates(
            pca_url="https://pca.scms.example.com",
            count=20,
            duration_days=7
        )

        if cert_count > 0:
            # Step 3: Use pseudonym certificates
            for i in range(5):
                current_cert = enrollment.get_current_pseudonym_cert()
                if current_cert:
                    print(f"\nUsing certificate: {current_cert.cert_id.hex()[:16]}...")
                    print(f"  Valid until: {time.ctime(current_cert.end_time)}")

                    # Simulate certificate usage
                    time.sleep(1)

                    # Rotate after some time/messages
                    if i % 2 == 1:
                        enrollment.rotate_pseudonym_cert()
```

## Misbehavior Detection

### Misbehavior Types

| Misbehavior Category | Description | Detection Method |
|---------------------|-------------|------------------|
| Position Consistency | Impossible position jumps | Plausibility check |
| Speed Consistency | Unrealistic speed values | Physical limits check |
| Acceleration Consistency | Impossible acceleration | Physical limits check |
| Heading Consistency | Erratic heading changes | Temporal consistency |
| Duplicate Messages | Message replay attacks | Sequence number check |
| Invalid Signatures | Forged messages | Cryptographic verification |
| Revoked Certificates | Using revoked certs | CRL lookup |

### Misbehavior Detection Implementation

```cpp
// misbehavior_detector.hpp
#pragma once

#include <cstdint>
#include <map>
#include <deque>
#include <vector>

namespace v2x {
namespace security {

enum class MisbehaviorType {
    POSITION_JUMP,
    SPEED_EXCEEDED,
    ACCEL_EXCEEDED,
    HEADING_INCONSISTENT,
    DUPLICATE_MESSAGE,
    INVALID_SIGNATURE,
    REVOKED_CERTIFICATE,
    TIMEOUT,
    FREQUENCY_VIOLATION
};

struct VehicleStateHistory {
    uint32_t vehicle_id;
    double latitude;
    double longitude;
    double speed_mps;
    double heading_deg;
    uint32_t timestamp_ms;
    uint16_t message_count;
};

struct MisbehaviorReport {
    uint32_t sender_id;
    MisbehaviorType type;
    uint32_t detection_time;
    double confidence;  // 0.0-1.0
    std::string details;
};

class MisbehaviorDetector {
public:
    MisbehaviorDetector();

    // Process received V2V message
    std::vector<MisbehaviorReport> checkMessage(
        uint32_t sender_id,
        double latitude,
        double longitude,
        double speed_mps,
        double heading_deg,
        uint16_t msg_count,
        uint32_t timestamp_ms
    );

    // Check position plausibility
    bool checkPositionPlausibility(
        uint32_t sender_id,
        double lat,
        double lon,
        uint32_t timestamp_ms
    );

    // Check speed plausibility
    bool checkSpeedPlausibility(double speed_mps);

    // Check acceleration plausibility
    bool checkAccelerationPlausibility(
        uint32_t sender_id,
        double current_speed,
        uint32_t timestamp_ms
    );

    // Report misbehavior to misbehavior authority
    void reportMisbehavior(const MisbehaviorReport& report);

    // Get misbehavior score for sender
    double getMisbehaviorScore(uint32_t sender_id);

private:
    // Vehicle state history (last N messages per vehicle)
    std::map<uint32_t, std::deque<VehicleStateHistory>> history_;

    // Misbehavior scores
    std::map<uint32_t, double> misbehavior_scores_;

    // Physical limits
    const double MAX_SPEED_MPS = 70.0;  // 252 km/h
    const double MAX_ACCEL_MPS2 = 10.0;  // ~1g
    const double MAX_POSITION_JUMP_M = 200.0;  // 200m in 100ms
    const double MAX_HEADING_CHANGE_DEG = 45.0;  // per 100ms

    // History size
    const size_t HISTORY_SIZE = 10;

    // Calculate distance between two points
    double calculateDistance(double lat1, double lon1, double lat2, double lon2);

    // Update misbehavior score
    void updateMisbehaviorScore(uint32_t sender_id, double penalty);
};

} // namespace security
} // namespace v2x
```

## Certificate Revocation

### Certificate Revocation List (CRL)

```python
# certificate_revocation.py
"""
Certificate Revocation List (CRL) management.
"""

from dataclasses import dataclass
from typing import List, Set
import time
import hashlib

@dataclass
class CRLEntry:
    """Single entry in CRL."""
    cert_id: bytes  # HashedId8
    revocation_time: int  # Epoch timestamp
    reason: str  # "compromised", "misbehavior", "expired"

@dataclass
class CRL:
    """Certificate Revocation List."""
    version: int
    issuer_id: bytes  # CRL issuer (MA)
    this_update: int  # Epoch timestamp
    next_update: int  # Epoch timestamp
    revoked_certs: List[CRLEntry]
    signature: bytes  # MA signature

class CRLManager:
    """
    Manage Certificate Revocation Lists.
    """

    def __init__(self):
        self.current_crl: CRL = None
        self.revoked_cert_cache: Set[bytes] = set()
        self.last_update_time: int = 0

    def update_crl(self, new_crl: CRL) -> bool:
        """
        Update to new CRL version.

        Args:
            new_crl: New CRL from Misbehavior Authority

        Returns:
            True if CRL validated and updated
        """
        # Verify CRL signature (simplified)
        if not self._verify_crl_signature(new_crl):
            print("ERROR: CRL signature verification failed")
            return False

        # Check that CRL is newer
        if self.current_crl and new_crl.this_update <= self.current_crl.this_update:
            print("WARNING: CRL is not newer than current version")
            return False

        # Update revoked certificate cache
        self.revoked_cert_cache.clear()
        for entry in new_crl.revoked_certs:
            self.revoked_cert_cache.add(entry.cert_id)

        self.current_crl = new_crl
        self.last_update_time = int(time.time())

        print(f"CRL updated: {len(new_crl.revoked_certs)} revoked certificates")
        return True

    def is_revoked(self, cert_id: bytes) -> bool:
        """
        Check if certificate is revoked.

        Args:
            cert_id: Certificate ID (HashedId8)

        Returns:
            True if revoked
        """
        return cert_id in self.revoked_cert_cache

    def get_revocation_reason(self, cert_id: bytes) -> str:
        """Get revocation reason for certificate."""
        if not self.current_crl:
            return "unknown"

        for entry in self.current_crl.revoked_certs:
            if entry.cert_id == cert_id:
                return entry.reason

        return "not_revoked"

    def download_crl(self, crl_url: str) -> bool:
        """
        Download CRL from Misbehavior Authority.
        (Simulated)
        """
        print(f"Downloading CRL from {crl_url}")

        # Simulate CRL download
        # In production: HTTPS GET, verify signature

        new_crl = CRL(
            version=1,
            issuer_id=b'\xAA' * 8,
            this_update=int(time.time()),
            next_update=int(time.time()) + 86400,  # 24 hours
            revoked_certs=[],
            signature=b'\x00' * 64
        )

        return self.update_crl(new_crl)

    def _verify_crl_signature(self, crl: CRL) -> bool:
        """Verify CRL signature from Misbehavior Authority."""
        # In production: ECDSA verify with MA public key
        return True  # Simplified


# Example usage
if __name__ == "__main__":
    crl_mgr = CRLManager()

    # Download CRL
    crl_mgr.download_crl("https://ma.scms.example.com/crl")

    # Check if certificate is revoked
    test_cert_id = hashlib.sha256(b"test_certificate").digest()[:8]

    if crl_mgr.is_revoked(test_cert_id):
        reason = crl_mgr.get_revocation_reason(test_cert_id)
        print(f"Certificate revoked: {reason}")
    else:
        print("Certificate is valid (not revoked)")
```

## Security Performance Metrics

| Operation | Latency Target | Typical Implementation |
|-----------|---------------|----------------------|
| ECDSA Sign | < 2 ms | Hardware crypto accelerator |
| ECDSA Verify | < 5 ms | Hardware crypto accelerator |
| Certificate validation | < 10 ms | Local cache + CRL check |
| Message overhead | ~200-300 bytes | Certificate digest mode |
| Certificate change | < 1 ms | Pre-loaded cert pool |

## References

1. **IEEE 1609.2-2016**: Security Services for Applications and Management Messages
2. **SCMS Proof of Concept**: US Department of Transportation
3. **CAMP VSC3**: Vehicle Safety Communications 3 Consortium
4. **ETSI TS 103 097**: Security header and certificate formats
5. **C2C-CC**: Car 2 Car Communication Consortium Security Specifications

---

## V2X Testing Simulation

# V2X Testing and Simulation

## Overview
Comprehensive V2X testing methodologies including CARLA, SUMO, NS-3 simulation environments, RF chamber testing, field trials, message validation, interoperability testing, and conformance test suites.

## Simulation Tool Comparison

| Tool | Domain | Strengths | Integration | License |
|------|--------|-----------|-------------|---------|
| CARLA | 3D vehicle & sensor sim | Realistic sensors, Unreal Engine graphics | Python/C++ API, ROS | MIT |
| SUMO | Traffic simulation | Large-scale traffic patterns, fast | Python TraCI API | EPL-2.0 |
| NS-3 | Network simulation | Detailed protocol modeling, validated models | C++, Python bindings | GPL |
| OMNeT++ | Discrete event sim | Modular, extensive libraries | C++, Veins for V2X | Academic free |
| VTD | Professional driving sim | Industry-grade, HIL ready | Commercial APIs | Commercial |

## CARLA V2X Integration

### CARLA Setup for V2X Testing

```python
# carla_v2x_test.py
"""
CARLA-based V2X scenario testing.
Simulates BSM broadcast, FCW, and EEBL scenarios.
"""

import carla
import time
import math
import random
from typing import List, Dict, Tuple

class V2XMessage:
    """Base V2X message."""
    def __init__(self, sender_id: int, timestamp: float):
        self.sender_id = sender_id
        self.timestamp = timestamp

class BSM(V2XMessage):
    """Basic Safety Message."""
    def __init__(self, sender_id: int, timestamp: float,
                 lat: float, lon: float, speed: float, heading: float,
                 accel_long: float, accel_lat: float):
        super().__init__(sender_id, timestamp)
        self.latitude = lat
        self.longitude = lon
        self.speed_mps = speed
        self.heading_deg = heading
        self.accel_long_mps2 = accel_long
        self.accel_lat_mps2 = accel_lat

class V2XVehicle:
    """Vehicle with V2X OBU in CARLA."""

    def __init__(self, carla_vehicle: carla.Vehicle, vehicle_id: int):
        self.vehicle = carla_vehicle
        self.id = vehicle_id
        self.message_history: List[BSM] = []
        self.received_messages: List[BSM] = []

        # V2X parameters
        self.transmission_range_m = 300.0
        self.message_rate_hz = 10.0
        self.last_transmission_time = 0.0

    def generate_bsm(self) -> BSM:
        """Generate BSM from current vehicle state."""
        transform = self.vehicle.get_transform()
        velocity = self.vehicle.get_velocity()
        accel = self.vehicle.get_acceleration()

        # Calculate speed
        speed = math.sqrt(velocity.x**2 + velocity.y**2 + velocity.z**2)

        # Calculate heading (yaw in degrees)
        heading = transform.rotation.yaw

        bsm = BSM(
            sender_id=self.id,
            timestamp=time.time(),
            lat=transform.location.x,
            lon=transform.location.y,
            speed=speed,
            heading=heading,
            accel_long=accel.x,
            accel_lat=accel.y
        )

        self.message_history.append(bsm)
        return bsm

    def should_transmit_bsm(self, current_time: float) -> bool:
        """Check if BSM should be transmitted based on message rate."""
        interval = 1.0 / self.message_rate_hz
        if current_time - self.last_transmission_time >= interval:
            self.last_transmission_time = current_time
            return True
        return False

    def receive_bsm(self, bsm: BSM, sender_position: Tuple[float, float]):
        """Receive BSM from another vehicle if in range."""
        my_pos = self.vehicle.get_transform().location
        distance = math.sqrt(
            (my_pos.x - sender_position[0])**2 +
            (my_pos.y - sender_position[1])**2
        )

        if distance <= self.transmission_range_m:
            self.received_messages.append(bsm)
            return True
        return False

class V2XTestScenario:
    """CARLA V2X test scenario framework."""

    def __init__(self, host='localhost', port=2000):
        self.client = carla.Client(host, port)
        self.client.set_timeout(10.0)
        self.world = self.client.get_world()
        self.blueprint_library = self.world.get_blueprint_library()

        self.vehicles: List[V2XVehicle] = []
        self.test_results = {
            'messages_sent': 0,
            'messages_received': 0,
            'packet_loss_rate': 0.0,
            'average_latency_ms': 0.0,
            'collision_warnings': 0
        }

    def spawn_v2x_vehicle(self, vehicle_type: str = 'vehicle.tesla.model3',
                         spawn_point: carla.Transform = None) -> V2XVehicle:
        """Spawn a vehicle with V2X capability."""
        if spawn_point is None:
            spawn_points = self.world.get_map().get_spawn_points()
            spawn_point = random.choice(spawn_points)

        blueprint = self.blueprint_library.filter(vehicle_type)[0]
        actor = self.world.spawn_actor(blueprint, spawn_point)

        # Enable autopilot
        actor.set_autopilot(True)

        v2x_vehicle = V2XVehicle(actor, len(self.vehicles))
        self.vehicles.append(v2x_vehicle)

        print(f"Spawned V2X vehicle {v2x_vehicle.id} at {spawn_point.location}")
        return v2x_vehicle

    def test_bsm_broadcast(self, duration_s: int = 60):
        """
        Test BSM broadcast functionality.

        Metrics:
        - Message delivery ratio
        - Latency distribution
        - Range verification
        """
        print(f"\n=== BSM Broadcast Test ({duration_s}s) ===")

        start_time = time.time()
        sent_messages = {}  # {msg_id: (timestamp, sender_id)}
        received_messages = {}  # {msg_id: [(receiver_id, timestamp)]}

        msg_id_counter = 0

        while time.time() - start_time < duration_s:
            current_time = time.time()

            # Each vehicle transmits BSM
            for sender in self.vehicles:
                if sender.should_transmit_bsm(current_time):
                    bsm = sender.generate_bsm()
                    msg_id = f"{sender.id}_{msg_id_counter}"
                    sent_messages[msg_id] = (current_time, sender.id)
                    msg_id_counter += 1

                    self.test_results['messages_sent'] += 1

                    # Broadcast to other vehicles in range
                    sender_pos = (bsm.latitude, bsm.longitude)
                    for receiver in self.vehicles:
                        if receiver.id != sender.id:
                            if receiver.receive_bsm(bsm, sender_pos):
                                self.test_results['messages_received'] += 1

                                if msg_id not in received_messages:
                                    received_messages[msg_id] = []
                                received_messages[msg_id].append((receiver.id, current_time))

            time.sleep(0.01)  # 10ms tick

        # Calculate metrics
        total_expected_receptions = 0
        total_actual_receptions = 0

        for msg_id, (send_time, sender_id) in sent_messages.items():
            # Expected: all vehicles except sender
            expected = len(self.vehicles) - 1
            total_expected_receptions += expected

            if msg_id in received_messages:
                actual = len(received_messages[msg_id])
                total_actual_receptions += actual

        if total_expected_receptions > 0:
            delivery_ratio = total_actual_receptions / total_expected_receptions
        else:
            delivery_ratio = 0.0

        packet_loss = 1.0 - delivery_ratio

        print(f"\nBSM Test Results:")
        print(f"  Messages sent: {self.test_results['messages_sent']}")
        print(f"  Expected receptions: {total_expected_receptions}")
        print(f"  Actual receptions: {total_actual_receptions}")
        print(f"  Delivery ratio: {delivery_ratio*100:.2f}%")
        print(f"  Packet loss rate: {packet_loss*100:.2f}%")

        self.test_results['packet_loss_rate'] = packet_loss

    def test_fcw_scenario(self):
        """
        Test Forward Collision Warning scenario.

        Scenario: Lead vehicle suddenly brakes, following vehicle receives warning.
        """
        print("\n=== FCW Scenario Test ===")

        # Spawn lead vehicle
        spawn_points = self.world.get_map().get_spawn_points()
        lead_spawn = spawn_points[0]
        lead = self.spawn_v2x_vehicle('vehicle.tesla.model3', lead_spawn)

        # Spawn following vehicle 30m behind
        following_spawn = carla.Transform(
            location=carla.Location(
                x=lead_spawn.location.x - 30,
                y=lead_spawn.location.y,
                z=lead_spawn.location.z
            ),
            rotation=lead_spawn.rotation
        )
        following = self.spawn_v2x_vehicle('vehicle.audi.a2', following_spawn)

        # Run scenario
        for i in range(100):  # 10 seconds at 10 Hz
            current_time = time.time()

            # Generate and broadcast BSMs
            lead_bsm = lead.generate_bsm()
            following_bsm = following.generate_bsm()

            # Simulate reception
            following.receive_bsm(lead_bsm, (lead_bsm.latitude, lead_bsm.longitude))
            lead.receive_bsm(following_bsm, (following_bsm.latitude, following_bsm.longitude))

            # Calculate relative parameters
            distance = math.sqrt(
                (lead_bsm.latitude - following_bsm.latitude)**2 +
                (lead_bsm.longitude - following_bsm.longitude)**2
            )

            relative_speed = following_bsm.speed_mps - lead_bsm.speed_mps

            # FCW logic
            if relative_speed > 0 and distance > 0:
                ttc = distance / relative_speed

                if ttc < 2.5:
                    print(f"[{i/10:.1f}s] FCW WARNING! TTC={ttc:.2f}s, Distance={distance:.1f}m, "
                          f"RelSpeed={relative_speed:.1f}m/s")
                    self.test_results['collision_warnings'] += 1

            # Emergency brake at t=5s
            if i == 50:
                print(f"[5.0s] Lead vehicle emergency braking!")
                lead.vehicle.apply_control(carla.VehicleControl(brake=1.0))

            time.sleep(0.1)

        print(f"\nFCW Test Results:")
        print(f"  Collision warnings issued: {self.test_results['collision_warnings']}")

    def cleanup(self):
        """Clean up spawned vehicles."""
        for v2x_vehicle in self.vehicles:
            v2x_vehicle.vehicle.destroy()
        self.vehicles.clear()
        print("\nCleaned up all vehicles")


# Example test execution
if __name__ == "__main__":
    try:
        # Initialize test scenario
        test = V2XTestScenario(host='localhost', port=2000)

        # Spawn test vehicles
        for i in range(5):
            test.spawn_v2x_vehicle()

        # Run BSM broadcast test
        test.test_bsm_broadcast(duration_s=30)

        # Run FCW scenario test
        test.cleanup()  # Clean previous vehicles
        test.test_fcw_scenario()

    except KeyboardInterrupt:
        print("\nTest interrupted by user")
    finally:
        test.cleanup()
```

## SUMO Integration for Traffic Simulation

```python
# sumo_v2x_integration.py
"""
SUMO traffic simulation with V2X message exchange.
"""

import traci
import sumolib
import time
from typing import Dict, List

class SUMOV2XSimulation:
    """SUMO simulation with V2X communication."""

    def __init__(self, sumo_cfg_file: str):
        self.sumo_cfg = sumo_cfg_file
        self.vehicle_states: Dict[str, dict] = {}

    def start_simulation(self, gui: bool = False):
        """Start SUMO simulation."""
        sumo_binary = "sumo-gui" if gui else "sumo"
        sumo_cmd = [sumo_binary, "-c", self.sumo_cfg]
        traci.start(sumo_cmd)

    def run_v2x_simulation(self, steps: int = 1000):
        """Run SUMO simulation with V2X message exchange."""
        for step in range(steps):
            traci.simulationStep()

            # Get all vehicle IDs
            vehicle_ids = traci.vehicle.getIDList()

            # Generate BSM for each vehicle
            for veh_id in vehicle_ids:
                position = traci.vehicle.getPosition(veh_id)
                speed = traci.vehicle.getSpeed(veh_id)
                angle = traci.vehicle.getAngle(veh_id)
                accel = traci.vehicle.getAcceleration(veh_id)

                bsm = {
                    'vehicle_id': veh_id,
                    'x': position[0],
                    'y': position[1],
                    'speed': speed,
                    'heading': angle,
                    'accel': accel,
                    'step': step
                }

                self.vehicle_states[veh_id] = bsm

                # V2V communication simulation
                self.process_v2v_messages(veh_id, bsm)

            time.sleep(0.1)  # Real-time factor

        traci.close()

    def process_v2v_messages(self, veh_id: str, bsm: dict):
        """Process V2V messages for vehicle."""
        # Find vehicles in communication range (300m)
        comm_range = 300.0

        for other_id, other_bsm in self.vehicle_states.items():
            if other_id == veh_id:
                continue

            distance = ((bsm['x'] - other_bsm['x'])**2 +
                       (bsm['y'] - other_bsm['y'])**2)**0.5

            if distance <= comm_range:
                # Vehicles can communicate
                # Check for FCW condition
                rel_speed = bsm['speed'] - other_bsm['speed']
                if rel_speed > 0 and distance < 50:
                    ttc = distance / rel_speed if rel_speed > 0.1 else 999
                    if ttc < 3.0:
                        print(f"Step {bsm['step']}: FCW for {veh_id}, "
                              f"TTC={ttc:.2f}s to {other_id}")


# Example SUMO configuration file (save as v2x_test.sumocfg)
SUMO_CONFIG = """<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <input>
        <net-file value="network.net.xml"/>
        <route-files value="routes.rou.xml"/>
    </input>
    <time>
        <begin value="0"/>
        <end value="1000"/>
    </time>
</configuration>
"""
```

## NS-3 Network Simulation

### NS-3 V2X Module

```cpp
// ns3_v2x_scenario.cc
/**
 * NS-3 V2X communication scenario.
 * Simulates DSRC/802.11p communication with channel model.
 */

#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/mobility-module.h"
#include "ns3/wifi-module.h"
#include "ns3/wave-module.h"
#include "ns3/internet-module.h"

using namespace ns3;

NS_LOG_COMPONENT_DEFINE("V2XScenario");

class V2XApplication : public Application {
public:
    V2XApplication();
    virtual ~V2XApplication();

    void Setup(Ptr<Socket> socket, uint32_t packetSize, uint32_t nPackets,
               DataRate dataRate);

private:
    virtual void StartApplication(void);
    virtual void StopApplication(void);

    void ScheduleTransmit(Time dt);
    void SendPacket(void);

    Ptr<Socket> m_socket;
    uint32_t m_packetSize;
    uint32_t m_nPackets;
    DataRate m_dataRate;
    EventId m_sendEvent;
    bool m_running;
    uint32_t m_packetsSent;
};

V2XApplication::V2XApplication()
    : m_socket(0),
      m_packetSize(0),
      m_nPackets(0),
      m_dataRate(0),
      m_running(false),
      m_packetsSent(0) {}

V2XApplication::~V2XApplication() {
    m_socket = 0;
}

void V2XApplication::Setup(Ptr<Socket> socket, uint32_t packetSize,
                          uint32_t nPackets, DataRate dataRate) {
    m_socket = socket;
    m_packetSize = packetSize;
    m_nPackets = nPackets;
    m_dataRate = dataRate;
}

void V2XApplication::StartApplication(void) {
    m_running = true;
    m_packetsSent = 0;
    m_socket->Bind();
    m_socket->Connect(InetSocketAddress(Ipv4Address("255.255.255.255"), 80));
    SendPacket();
}

void V2XApplication::StopApplication(void) {
    m_running = false;
    if (m_sendEvent.IsRunning()) {
        Simulator::Cancel(m_sendEvent);
    }
    if (m_socket) {
        m_socket->Close();
    }
}

void V2XApplication::SendPacket(void) {
    Ptr<Packet> packet = Create<Packet>(m_packetSize);
    m_socket->Send(packet);

    NS_LOG_INFO("Sent packet " << m_packetsSent << " at time "
                << Simulator::Now().GetSeconds());

    if (++m_packetsSent < m_nPackets) {
        ScheduleTransmit(Seconds(m_packetSize * 8 /
                        static_cast<double>(m_dataRate.GetBitRate())));
    }
}

void V2XApplication::ScheduleTransmit(Time dt) {
    if (m_running) {
        m_sendEvent = Simulator::Schedule(dt, &V2XApplication::SendPacket, this);
    }
}

// Main simulation
int main(int argc, char *argv[]) {
    uint32_t nVehicles = 10;
    double simTime = 100.0;  // seconds
    double distance = 300.0;  // meters

    CommandLine cmd;
    cmd.AddValue("nVehicles", "Number of vehicles", nVehicles);
    cmd.AddValue("simTime", "Simulation time", simTime);
    cmd.Parse(argc, argv);

    // Create nodes
    NodeContainer vehicles;
    vehicles.Create(nVehicles);

    // Configure WAVE/DSRC
    YansWifiChannelHelper waveChannel = YansWifiChannelHelper::Default();
    YansWavePhyHelper wavePhy = YansWavePhyHelper::Default();
    wavePhy.SetChannel(waveChannel.Create());

    QosWaveMacHelper waveMac = QosWaveMacHelper::Default();
    WaveHelper waveHelper = WaveHelper::Default();

    NetDeviceContainer devices = waveHelper.Install(wavePhy, waveMac, vehicles);

    // Mobility model
    MobilityHelper mobility;
    mobility.SetPositionAllocator("ns3::GridPositionAllocator",
                                 "MinX", DoubleValue(0.0),
                                 "MinY", DoubleValue(0.0),
                                 "DeltaX", DoubleValue(distance),
                                 "DeltaY", DoubleValue(0.0),
                                 "GridWidth", UintegerValue(nVehicles),
                                 "LayoutType", StringValue("RowFirst"));

    mobility.SetMobilityModel("ns3::ConstantVelocityMobilityModel");
    mobility.Install(vehicles);

    // Set velocities
    for (uint32_t i = 0; i < vehicles.GetN(); ++i) {
        Ptr<ConstantVelocityMobilityModel> mob =
            vehicles.Get(i)->GetObject<ConstantVelocityMobilityModel>();
        mob->SetVelocity(Vector(20.0, 0.0, 0.0));  // 20 m/s
    }

    // Internet stack
    InternetStackHelper internet;
    internet.Install(vehicles);

    Ipv4AddressHelper ipv4;
    ipv4.SetBase("10.1.1.0", "255.255.255.0");
    ipv4.Assign(devices);

    // V2X applications
    TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
    for (uint32_t i = 0; i < vehicles.GetN(); ++i) {
        Ptr<Socket> sink = Socket::CreateSocket(vehicles.Get(i), tid);

        Ptr<V2XApplication> app = CreateObject<V2XApplication>();
        app->Setup(sink, 200, 1000, DataRate("6Mbps"));  // BSM: 200 bytes @ 10 Hz
        vehicles.Get(i)->AddApplication(app);
        app->SetStartTime(Seconds(1.0));
        app->SetStopTime(Seconds(simTime));
    }

    // Run simulation
    Simulator::Stop(Seconds(simTime));
    Simulator::Run();
    Simulator::Destroy();

    return 0;
}
```

## RF Chamber Testing

### Conducted RF Test Setup

```
Test Equipment:
- Vector Spectrum Analyzer (VSA)
- Signal Generator (V2X signal source)
- OBU/RSU under test
- RF cables and attenuators
- Shielded chamber

Test Metrics:
1. Transmit power (-33 to +33 dBm)
2. Receiver sensitivity (< -85 dBm for 6 Mbps)
3. Adjacent channel rejection (> 23 dB)
4. Spectrum mask compliance
5. EVM (Error Vector Magnitude) < 17.5%
6. Packet error rate vs SNR
```

### Test Procedure

```python
# rf_chamber_test.py
"""
Automated RF chamber test control.
"""

class RFChamberTest:
    """Control RF chamber testing equipment."""

    def __init__(self, vsa_address: str, sig_gen_address: str):
        # SCPI connection to test equipment
        self.vsa_address = vsa_address
        self.sig_gen_address = sig_gen_address

    def test_transmit_power(self, obu_id: str) -> dict:
        """
        Measure transmit power compliance.

        Returns:
            dict with power levels per channel
        """
        results = {}

        # Test each DSRC channel
        for channel in [172, 174, 176, 178, 180, 182, 184]:
            freq_ghz = 5.860 + (channel - 172) * 0.005

            # Configure OBU to transmit on channel
            # Measure power with VSA
            measured_power_dbm = self._measure_power(freq_ghz)

            results[channel] = {
                'frequency_ghz': freq_ghz,
                'power_dbm': measured_power_dbm,
                'spec_min_dbm': 0,
                'spec_max_dbm': 33,
                'pass': 0 <= measured_power_dbm <= 33
            }

        return results

    def test_receiver_sensitivity(self, obu_id: str) -> float:
        """
        Measure receiver sensitivity (minimum detectable signal).

        Returns:
            Sensitivity in dBm
        """
        # Start at high power
        power_dbm = -50
        step_db = -1
        per_threshold = 0.1  # 10% PER

        while power_dbm > -95:
            # Set signal generator power
            per = self._measure_per(power_dbm)

            if per > per_threshold:
                # Exceeded threshold, sensitivity found
                return power_dbm + abs(step_db)

            power_dbm += step_db

        return power_dbm
```

## Field Trial Protocol

### Multi-Site Field Testing

```yaml
# field_trial_protocol.yaml
trial_name: "V2X Safety Applications Field Trial"
duration_days: 30
test_sites:
  - name: "Urban Intersection"
    location: "Main St & 5th Ave"
    scenarios:
      - BSM broadcast (continuous)
      - SPaT/MAP reception
      - IMA collision warnings
    metrics:
      - Message delivery ratio
      - Latency (95th percentile)
      - False positive rate

  - name: "Highway Segment"
    location: "I-405 Mile 15-20"
    scenarios:
      - FCW testing
      - CACC platooning
      - EEBL warnings
    metrics:
      - TTC distribution
      - Warning timing accuracy
      - Driver response time

test_vehicles:
  - vehicle_id: V001
    obu_type: "Cohda MK5"
    instrumentation:
      - GPS (RTK, <10cm accuracy)
      - CAN bus logger
      - Video cameras (forward/rear)
      - Driver HMI recorder

data_collection:
  - V2X message logs (PCAP format)
  - GPS traces (1 Hz)
  - CAN bus data (all messages)
  - Driver interactions (button presses, warnings)
  - Video synchronized with messages
```

## Conformance Testing

### SAE J2945/1 Test Cases

```python
# conformance_tests.py
"""
SAE J2945/1 conformance test suite.
"""

class ConformanceTestSuite:
    """SAE J2945/1 OBU conformance tests."""

    def test_bsm_generation_rate(self, obu):
        """
        Test: BSM generation rate (10 Hz for moving vehicles).
        Requirement: SAE J2945/1 Section 5.2
        """
        messages = obu.collect_bsm_messages(duration_s=10)
        rate_hz = len(messages) / 10.0

        assert 9.5 <= rate_hz <= 10.5, f"BSM rate {rate_hz} Hz out of spec"

    def test_bsm_content_validity(self, obu):
        """
        Test: BSM content validity.
        Requirement: SAE J2735
        """
        bsm = obu.get_latest_bsm()

        # Check mandatory fields
        assert bsm.has_field('latitude'), "Missing latitude"
        assert bsm.has_field('longitude'), "Missing longitude"
        assert bsm.has_field('speed'), "Missing speed"
        assert bsm.has_field('heading'), "Missing heading"

        # Check value ranges
        assert -90 <= bsm.latitude <= 90, "Invalid latitude"
        assert -180 <= bsm.longitude <= 180, "Invalid longitude"
        assert 0 <= bsm.speed <= 163.8, "Invalid speed (max 163.8 m/s)"

    def test_security_certificate_attached(self, obu):
        """
        Test: Security certificate attachment.
        Requirement: IEEE 1609.2
        """
        secured_msg = obu.get_secured_message()

        assert secured_msg.has_certificate(), "No certificate attached"
        assert secured_msg.verify_signature(), "Invalid signature"
```

## References

1. **CARLA Documentation**: https://carla.readthedocs.io
2. **SUMO Documentation**: https://sumo.dlr.de/docs
3. **NS-3 WAVE Module**: https://www.nsnam.org/docs/models/html/wave.html
4. **OMNeT++ Veins**: https://veins.car2x.org
5. **SAE J2945/1**: On-Board System Requirements for V2V Safety Communications

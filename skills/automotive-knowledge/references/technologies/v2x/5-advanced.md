# V2X Communication - Level 5: Advanced Topics

> Audience: SMEs and researchers pushing V2X boundaries
> Purpose: Advanced V2X patterns, 5G NR-V2X, collective perception, and future directions

## 5G NR-V2X (Release 16+)

### Key Improvements Over LTE-V2X

| Feature | LTE-V2X (Rel-14/15) | NR-V2X (Rel-16+) |
|---------|---------------------|-------------------|
| Peak throughput | ~50 Mbps | ~1 Gbps |
| Latency | ~20 ms | ~3 ms |
| Reliability | 90-95% | 99.999% |
| Positioning | ~10 m | ~0.1 m |
| Sidelink feedback | No HARQ feedback | HARQ + CSI feedback |
| Unicast/groupcast | Broadcast only | Unicast + groupcast + broadcast |
| QoS management | Limited | Full QoS differentiation |

### NR-V2X Sidelink Resource Allocation

NR-V2X introduces Mode 1 (network-assisted) and Mode 2 (autonomous) resource
allocation with significant improvements:

**Mode 2 Enhancements**:
- Partial sensing: reduces power consumption by 50-70%
- Inter-UE coordination: vehicles negotiate resource reservations
- Pre-emption: high-priority messages can pre-empt lower priority
- Resource re-evaluation: continuous optimization of selected resources

**QoS-Aware Scheduling**:
```
Priority Level    Use Case                   Latency Target
1 (highest)       Pre-crash warning           3 ms
2                 Cooperative maneuver         10 ms
3                 Platooning control           25 ms
4                 BSM/CAM broadcast            100 ms
5 (lowest)        Sensor sharing (CPM)         100 ms
```

## Collective Perception (CPM)

### Concept

Vehicles share their sensor perception (objects detected by cameras, radar,
lidar) with neighbors via Collective Perception Messages. This creates a
"shared perception" that extends beyond any single vehicle's sensor range.

### CPM Architecture

```
Vehicle A sensors       Vehicle B sensors
  |                       |
  v                       v
Local Object List      Local Object List
  |                       |
  v                       v
Object Selection       Object Selection
(what to share)        (what to share)
  |                       |
  v                       v
CPM Encoding           CPM Encoding
  |                       |
  v                       v
  +------- V2V --------+
  |                       |
  v                       v
CPM Fusion             CPM Fusion
(merge with own)       (merge with own)
  |                       |
  v                       v
Enhanced               Enhanced
Perception             Perception
```

### Object Selection Algorithm

Not all detected objects should be shared (channel capacity is limited).
Selection criteria:

```c
/* CPM object selection: prioritize high-value information */
typedef struct {
    uint32_t object_id;
    float distance_m;
    float relevance_score;
    bool is_new;              /* First detection */
    bool is_changed;          /* Significant state change */
    float novelty_score;      /* How much this adds to collective knowledge */
    uint32_t last_shared_ms;  /* When last included in CPM */
} CpmCandidate_t;

float compute_cpm_relevance(const DetectedObject_t* obj,
                              const RemotePerception_t* known_objects) {
    float score = 0.0f;

    /* Higher score for objects not seen by others */
    if (!is_known_by_neighbors(obj, known_objects)) {
        score += 10.0f;
    }

    /* Higher score for vulnerable road users */
    if (obj->classification == OBJ_PEDESTRIAN ||
        obj->classification == OBJ_CYCLIST) {
        score += 5.0f;
    }

    /* Higher score for objects in conflict zones */
    if (is_in_intersection(obj->position)) {
        score += 3.0f;
    }

    /* Decay score for recently shared objects */
    uint32_t time_since_shared = get_time_ms() - obj->last_shared_ms;
    if (time_since_shared < 500) {
        score *= 0.1f;
    }

    return score;
}
```

## Cooperative Driving (Maneuver Coordination)

### Maneuver Coordination Messages (MCM)

Emerging standard for vehicles to negotiate driving maneuvers:

```
Vehicle A: "I want to change to left lane at position X in 5 seconds"
Vehicle B: "I acknowledge and will create gap"
Vehicle C: "I will slow down to accommodate"
```

### Platooning Protocol

```
+--------+   +--------+   +--------+   +--------+
| Leader |-->| Follower|-->| Follower|-->| Follower|
|  v=80  |   |  v=80  |   |  v=80  |   |  v=80  |
| gap=0  |   | gap=8m |   | gap=8m |   | gap=8m |
+--------+   +--------+   +--------+   +--------+
     |            ^             ^             ^
     |            |             |             |
     +--- CAM + Platoon Control Messages -----+
     (Speed, acceleration, brake commands via PC5)

Control loop: 20 Hz (50 ms cycle)
Communication: V2V via PC5 sidelink
Gap accuracy: +/- 0.5 m at highway speed
String stability: Each follower adds max 0.1 m/s2 overshoot
```

## V2X-Enabled Autonomous Driving

### Infrastructure-Supported Autonomy

V2X extends the Operational Design Domain (ODD) for autonomous vehicles:

| Scenario | Without V2X | With V2X |
|----------|------------|---------|
| Blind intersection | Stop and creep | Proceed with V2I clearance |
| Emergency vehicle | Audio detection only | Precise location/route via V2V |
| Construction zone | Camera detection | DENM with precise boundaries |
| Signal timing | Camera-based recognition | SPAT data, 100% reliable |
| Hidden pedestrian | Cannot detect | V2P warning from their phone |

### Cooperative Automated Driving System Design

```
Perception Layer:
  Onboard Sensors (camera, radar, lidar)
    +
  V2X Received Data (CAM, CPM, DENM, SPAT/MAP)
    =
  Fused World Model (environment representation)

Planning Layer:
  Local Planning (path, trajectory)
    +
  Cooperative Planning (MCM negotiation)
    =
  Coordinated Trajectory

Control Layer:
  Vehicle Dynamics Control
    +
  Platoon Formation Control
    =
  Actuator Commands (steering, throttle, brake)
```

## Channel Modeling and Propagation

### V2V Channel Characteristics

| Environment | Path Loss Model | Typical Range | Multipath |
|-------------|----------------|---------------|-----------|
| Highway LOS | Free-space + 2-ray | 400-800 m | Low |
| Urban LOS | Log-distance, n=2.0 | 200-400 m | Medium |
| Urban NLOS | Log-distance, n=3.5 | 50-150 m | High |
| Intersection | Diffraction model | 100-200 m | Very High |
| Tunnel | Waveguide model | 200-500 m | Extreme |

### Packet Reception Ratio (PRR) Analysis

```python
# Monte Carlo simulation for V2V reliability analysis
import numpy as np

def simulate_prr(num_vehicles: int, tx_power_dbm: float,
                  distance_m: float, num_trials: int = 10000) -> float:
    """Simulate packet reception ratio for V2V communication."""
    received = 0

    for _ in range(num_trials):
        # Path loss (simplified log-distance model)
        path_loss_db = 63.3 + 17.7 * np.log10(distance_m)

        # Shadowing (log-normal, sigma = 5.9 dB for highway)
        shadow_db = np.random.normal(0, 5.9)

        # Fading (Nakagami-m, m=1 for highway, m=3 for urban)
        fading_linear = np.random.gamma(1, 1)
        fading_db = 10 * np.log10(fading_linear)

        # Interference from other vehicles (simplified)
        interference_db = 10 * np.log10(num_vehicles - 1) - 20

        # Received power
        rx_power_dbm = tx_power_dbm - path_loss_db + shadow_db + fading_db

        # SINR
        noise_dbm = -95  # Thermal noise at 10 MHz bandwidth
        sinr_db = rx_power_dbm - max(noise_dbm, interference_db)

        # Reception threshold (MCS 0 at 10 MHz)
        if sinr_db > -1.0:  # QPSK, R=1/2
            received += 1

    return received / num_trials
```

## Future Directions

### V2X Evolution Roadmap

```
2024-2025: LTE-V2X deployment (China, EU pilots)
2025-2026: NR-V2X initial deployments (Rel-16)
2026-2027: Cooperative perception standardized (CPM)
2027-2028: Maneuver coordination (MCM/Rel-17)
2028-2030: Full cooperative automated driving
2030+:     6G V2X (terahertz, sub-ms latency, holographic maps)
```

### Research Areas

- **Federated learning over V2X**: Collaborative model training across vehicles
  without sharing raw data, preserving privacy
- **Digital twin integration**: V2X data feeding real-time digital twin of
  traffic environment for predictive control
- **Quantum-safe cryptography**: Post-quantum algorithms for V2X certificates
  as quantum computing threatens ECDSA
- **AI-based misbehavior detection**: ML models replacing rule-based
  plausibility checks for more sophisticated attack detection
- **Multi-access edge computing (MEC)**: V2X message processing at network
  edge for ultra-low latency services

## Summary

Advanced V2X extends beyond basic safety messaging into cooperative
perception (CPM), maneuver coordination (MCM), and platooning. 5G NR-V2X
provides the throughput and latency needed for these use cases. Channel
modeling and reliability analysis are essential for system design. The
technology is evolving toward full cooperative automated driving with
AI-enhanced security and privacy.

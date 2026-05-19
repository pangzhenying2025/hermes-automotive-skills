# V2X Communication - Level 2: Conceptual Architecture

> Audience: System architects, senior engineers, technical leads
> Purpose: Understand V2X system architecture, protocol stacks, and design patterns

## V2X System Architecture

### In-Vehicle V2X Stack

```
+---------------------------------------------------------------+
|                    Application Layer                          |
|  Safety Apps | Traffic Apps | Infotainment | Fleet Management |
+---------------------------------------------------------------+
|                    Facilities Layer                            |
|  Message Management | Position Service | Time Service         |
|  Security (PKI) | Congestion Control | GeoNetworking          |
+---------------------------------------------------------------+
|                    Networking / Transport Layer                |
|  GeoNetworking (ETSI) | WSMP (US) | TCP/UDP/IP (V2N)        |
+---------------------------------------------------------------+
|                    Access Layer                                |
|  ITS-G5 / DSRC (802.11p) | C-V2X PC5 | Cellular (Uu)        |
+---------------------------------------------------------------+
|                    Hardware                                    |
|  V2X Radio Module | GNSS | HSM | Antenna                     |
+---------------------------------------------------------------+
```

### C-V2X Communication Modes

**PC5 Interface (Direct Communication)**:
- Sidelink: device-to-device without base station
- Used for V2V, V2I, V2P safety messages
- Low latency (~5 ms), operates even without cellular coverage
- Mode 4: Autonomous resource selection (no network assistance)

**Uu Interface (Network Communication)**:
- Standard cellular uplink/downlink via base station
- Used for V2N cloud services, traffic management
- Higher latency (~20-100 ms), requires cellular coverage
- Supports data-rich applications (HD maps, OTA updates)

## Protocol Architecture

### ETSI ITS Protocol Stack (European)

```
Application:  CAM, DENM, SPAT/MAP, CPM, IVIM
Facilities:   BTP (Basic Transport Protocol)
Network:      GeoNetworking (geographic routing)
Access:       ITS-G5 (802.11p) or C-V2X PC5
```

### SAE/US Protocol Stack

```
Application:  BSM, PSM, TIM, SPAT/MAP
Transport:    WSMP (WAVE Short Message Protocol)
Network:      IEEE 1609.3
Access:       DSRC (802.11p) or C-V2X PC5
```

## Key Message Types

### Cooperative Awareness Messages (CAM) / Basic Safety Messages (BSM)

| Field | Description | Update Rate |
|-------|-------------|-------------|
| Position | Latitude, longitude, altitude | 1-10 Hz |
| Velocity | Speed, heading, acceleration | 1-10 Hz |
| Vehicle size | Length, width, height | Static |
| Yaw rate | Rotational velocity | 1-10 Hz |
| Brake status | Brake pedal, ABS, stability | Event-driven |
| Path history | Recent trajectory points | 1-10 Hz |
| Vehicle type | Car, truck, motorcycle, emergency | Static |

Broadcast by every vehicle, 10 times per second, to all neighbors.

### Decentralized Environmental Notification Messages (DENM)

Triggered by specific events:
- Hazardous location (accident, road works, weather)
- Stationary vehicle (breakdown, emergency)
- Traffic condition (congestion, slow traffic)
- Signal violation (red light, stop sign)

Event-driven: sent when hazard detected, updated while active, terminated
when hazard cleared.

### Signal Phase and Timing (SPAT) / MAP

- SPAT: Current traffic signal phases and countdown timers
- MAP: Geometric description of intersection layout
- Together enable: green wave optimization, speed advisory, collision
  avoidance at intersections

## Security Architecture

### V2X Public Key Infrastructure (PKI)

```
Root Certificate Authority
  |
  +-- Enrollment CA (vehicle identity)
  |     +-- Enrollment Certificates (long-term, per vehicle)
  |
  +-- Authorization CA (message signing)
  |     +-- Pseudonym Certificates (short-term, rotating)
  |     +-- Application Certificates (per-use-case)
  |
  +-- Certificate Revocation (misbehavior authority)
        +-- Certificate Revocation Lists
        +-- Misbehavior Detection
```

### Privacy Protection

- **Pseudonym certificates**: Vehicles use rotating short-lived certificates
  (e.g., 5-minute validity) to prevent tracking
- **Certificate pools**: Vehicle loads a pool of certificates and rotates
  at random intervals
- **Linkage values**: Technical mechanism to revoke all certificates of a
  misbehaving vehicle without linking to identity during normal operation

## Congestion Control

V2X radio channel has limited capacity. Congestion control algorithms
manage channel load:

- **DCC (Decentralized Congestion Control)**: ETSI approach
  - Reactive: measure channel busy ratio (CBR)
  - Adaptive: adjust transmit power, rate, and sensitivity
  - States: Relaxed (CBR < 40%), Active (40-60%), Restrictive (> 60%)

- **SPS (Semi-Persistent Scheduling)**: C-V2X approach
  - Resource reservation for periodic messages (BSM/CAM)
  - Sensing-based mechanism to avoid collisions

## Positioning Requirements

V2X applications require high-accuracy positioning:

| Application | Accuracy Required | Solution |
|-------------|------------------|----------|
| Hazard warning | 5-10 m | Standard GNSS |
| Lane-level | 0.5-1.5 m | RTK/DGNSS corrections |
| Platooning | 0.1-0.5 m | RTK + INS fusion |
| Automated driving | < 0.2 m | RTK + INS + HD maps |

GNSS alone provides ~3-5 m accuracy. V2X-based cooperative positioning
can improve this by exchanging position observations between vehicles.

## Design Patterns

### Message Processing Pipeline

```
Receive -> Validate -> Decrypt -> Parse -> Plausibility -> Application
  |           |           |         |           |              |
  v           v           v         v           v              v
Radio     Signature    PKI      Protocol    Position      Decision
driver    verify      check    decode      consistency   & action
```

### Misbehavior Detection

Validate received messages against physical plausibility:
- Is the reported position consistent with signal propagation?
- Is the reported speed consistent with previous messages?
- Is the reported heading consistent with the trajectory?
- Is the vehicle type consistent with the dynamic behavior?

## Integration Considerations

| Aspect | Consideration |
|--------|-------------|
| Antenna placement | Roof-mounted for best range, ground plane needed |
| Timing | GPS-synchronized, sub-microsecond accuracy |
| Processing | Dedicated V2X processor or integrated in domain controller |
| Security | HSM required for certificate storage and signing |
| Testing | Requires specialized V2X simulation and test tools |
| Regulation | Region-specific message sets and frequency bands |

## Summary

V2X architecture is built on layered protocol stacks with strong security
(PKI) and privacy (pseudonym certificates) foundations. The two main
protocol families (ETSI/SAE) share similar concepts but differ in
specifics. System design must account for real-time message processing,
congestion management, and integration with vehicle perception systems.

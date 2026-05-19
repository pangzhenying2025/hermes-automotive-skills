# ISO 21448 (SOTIF) - Conceptual Architecture

> **Target Audience**: System architects, senior safety engineers, ADAS/AD technical leads

## SOTIF Lifecycle Process

SOTIF follows an iterative process of hazard identification, scenario analysis, risk evaluation, and validation to systematically reduce unknown hazardous scenarios.

```
1. Specification &        2. Identification of
   Design of Intended        Hazardous Behavior
   Functionality                    |
        |                           v
        v                  3. Triggering Condition
   Functional              Analysis & Functional
   Specification              Insufficiency
        |                           |
        v                           v
4. System Modification     5. Risk Evaluation
   & Improvement              (Severity, Exposure,
        ^                      Controllability)
        |                           |
        |                           v
        +---- 6. Verification & Validation
                       |
                       v
              7. Residual Risk
                 Acceptance
                       |
                       v
              8. Release Decision
```

## Scenario Quadrant Model

The SOTIF scenario model is the conceptual foundation for understanding and managing SOTIF risk.

### Quadrant Dynamics

```
         Known                    Unknown
    +------------------+------------------+
    |                  |                  |
    |    Area 1        |    Area 3        |
K   |  Known Safe      |  Unknown Safe    |
n   |  (Validated)     |  (Undiscovered   |
o   |                  |   safe behavior) |
w   +------------------+------------------+
n   |                  |                  |
    |    Area 2        |    Area 4        |
H   |  Known Hazardous |  Unknown         |
a   |  (Mitigated or   |   Hazardous      |
z   |   accepted)      |  (The target)    |
    +------------------+------------------+
```

**Goal**: Systematically move scenarios from Area 4 (unknown hazardous) to Area 2 (known hazardous), then mitigate them to Area 1 (known safe).

### Area Transitions

| Transition | Method | Example |
|------------|--------|---------|
| Area 4 to Area 2 | Discovery (testing, analysis, field data) | Simulation reveals AEB false positive on overpass shadow |
| Area 2 to Area 1 | Mitigation (design change, restriction) | Add shadow rejection algorithm, revalidate |
| Area 3 to Area 1 | Validation (testing confirms safety) | Prove lane keeping safe in light rain via track tests |
| Area 4 to Area 3 | Partial discovery (scenario found, not yet hazardous) | New road marking style identified but no safety concern |

## Triggering Condition Framework

Triggering conditions are specific circumstances that activate functional insufficiencies and lead to hazardous behavior.

### Taxonomy of Triggering Conditions

```
Triggering Conditions
|
+-- Environmental
|   +-- Weather (rain, fog, snow, ice, dust)
|   +-- Lighting (glare, low sun, tunnel transition, night)
|   +-- Road geometry (curvature, grade, banking)
|   +-- Road surface (wet, icy, gravel, markings)
|   +-- Infrastructure (signs, barriers, construction zones)
|   +-- Traffic objects (vehicles, pedestrians, cyclists, animals)
|
+-- Operational
|   +-- Vehicle dynamics (speed, yaw rate, lateral acceleration)
|   +-- Driver behavior (steering input, pedal usage, attention)
|   +-- System mode (active, standby, degraded, transitioning)
|
+-- System Internal
    +-- Sensor state (calibration drift, degradation, occlusion)
    +-- Algorithm state (confidence level, mode transitions)
    +-- Resource state (CPU load, memory, thermal)
```

### Triggering Condition Combination

Hazardous behavior often requires multiple triggering conditions occurring simultaneously.

**Example: AEB False Positive on Bridge**:
```
TC-1: Environmental - Metal bridge structure overhead (radar reflector)
TC-2: Environmental - Clear weather, no vehicles ahead
TC-3: Operational - Vehicle speed 80 km/h on highway
TC-4: System Internal - Radar returns strong reflection from bridge

Combined Effect: AEB interprets bridge as stationary obstacle,
initiates emergency braking on open highway.

Severity: S3 (rear-end collision from following vehicle)
Exposure: E3 (bridges encountered regularly)
Controllability: C3 (sudden braking, minimal driver reaction time)
```

## Functional Insufficiency Analysis

### Categories of Functional Insufficiency

| Category | Subcategory | Description | Example |
|----------|-------------|-------------|---------|
| **Sensor** | Limited FoV | Sensor cannot perceive all relevant space | Camera blind to object below bumper |
| **Sensor** | Resolution | Insufficient detail to classify object | Radar cannot distinguish pedestrian from pole |
| **Sensor** | Environmental sensitivity | Degraded by weather or lighting | Lidar rain reflections create ghost objects |
| **Algorithm** | Classification error | Incorrect object type assignment | Neural net classifies motorcycle as bicycle |
| **Algorithm** | Tracking failure | Lost track of known object | Object re-identification fails after occlusion |
| **Algorithm** | Prediction error | Incorrect trajectory prediction | Assumes merging vehicle will yield |
| **Actuator** | Response limitation | Physical limits of actuation | Brake distance exceeds available space |
| **Actuator** | Authority limit | System cannot achieve required output | Steering torque insufficient for evasion |

### Insufficiency-Triggering Condition Mapping

For each identified functional insufficiency, map the triggering conditions that activate it:

```
Insufficiency: Camera lane detection fails on wet road
|
+-- Triggering Condition 1: Heavy rain (>10mm/h)
|   +-- Rain droplets on lens reduce contrast
|   +-- Water film on road obscures lane markings
|
+-- Triggering Condition 2: Night + wet road
|   +-- Headlight reflections create glare on wet surface
|   +-- Reduced contrast between marking and road
|
+-- Triggering Condition 3: Worn lane markings + overcast
    +-- Low ambient light reduces marking visibility
    +-- Worn markings have insufficient retro-reflectivity
```

## SOTIF Safety Concept Architecture

### Layered Safety Approach

```
Layer 4: Residual Risk Acceptance
         (Statistical validation, field monitoring)
              |
Layer 3: System-Level Mitigation
         (Warnings, limitations, graceful degradation)
              |
Layer 2: Algorithm & Sensor Improvement
         (Better models, sensor fusion, redundancy)
              |
Layer 1: Specification Completeness
         (ODD definition, performance requirements)
```

### Operational Design Domain (ODD)

The ODD defines the boundary conditions under which the system is designed to operate safely.

**ODD Parameters**:

| Parameter | Range | Restriction Example |
|-----------|-------|---------------------|
| Speed | 0-130 km/h | LKA limited to 60-180 km/h |
| Road type | Highway, urban | Highway Pilot: highway only |
| Weather | Clear, rain, fog | AEB disabled in dense fog |
| Lighting | Day, night, tunnel | Parking assist: not in darkness |
| Road markings | Present, visible | LKA requires both lane markings |
| Traffic density | Free flow to congestion | ACC operates all densities |

**ODD Exit Management**:
```
Within ODD: System active, full functionality
    |
    v
Approaching ODD boundary: Warn driver, prepare transition
    |
    v
ODD exit detected: Request driver takeover (HMI alert)
    |
    v
No driver response: Execute minimal risk condition (MRC)
    |
    v
MRC achieved: System deactivated, vehicle in safe state
```

## Sensor Fusion for SOTIF

### Complementary Sensor Architecture

```
Camera (ASIL B)          Radar (ASIL B)          Lidar (ASIL B)
  |                        |                        |
  v                        v                        v
Object Detection        Object Detection        Object Detection
(Classification,        (Range, velocity,       (3D point cloud,
 lane detection)         all weather)            precise geometry)
  |                        |                        |
  +------------------------+------------------------+
                           |
                           v
                    Sensor Fusion
                (Multi-hypothesis tracking,
                 conflict resolution,
                 confidence estimation)
                           |
                           v
                    Fused World Model
                (High-confidence object list
                 with uncertainty bounds)
```

### Fusion Strategies for SOTIF

| Strategy | Description | SOTIF Benefit |
|----------|-------------|---------------|
| Redundant sensing | Multiple sensors cover same region | Detect single-sensor insufficiency |
| Diverse sensing | Different physical principles | Uncorrelated failure modes |
| Temporal fusion | Track objects across frames | Filter transient false positives |
| Spatial fusion | Cross-validate object position | Reduce localization uncertainty |
| Confidence voting | Require multi-sensor agreement | Reject low-confidence detections |

## Human-Machine Interface (HMI) for SOTIF

### Driver Interaction Model

SOTIF places significant emphasis on HMI design because driver controllability directly affects residual risk.

**HMI Requirements**:
- System status clearly communicated (active, standby, degraded)
- Takeover requests unambiguous and timely
- Warning escalation strategy defined (visual, audible, haptic)
- Prevent reasonably foreseeable misuse through design

**Misuse Prevention**:

| Misuse Scenario | Mitigation |
|-----------------|------------|
| Driver ignores takeover request | Escalating warnings, then MRC |
| Driver uses system outside ODD | ODD monitoring, automatic deactivation |
| Driver over-trusts system capability | Clear capability communication at activation |
| Driver distracted during handover | Driver monitoring system (DMS) integration |

## Verification vs. Validation in SOTIF

### Distinction

| Aspect | Verification | Validation |
|--------|-------------|------------|
| Question | "Did we build it right?" | "Did we build the right thing?" |
| Focus | Correct implementation of requirements | System achieves intended safety |
| Methods | Review, analysis, testing against spec | Scenario-based testing, field data |
| Scope | Individual requirements | Overall system behavior |
| SOTIF role | Confirm mitigations work | Discover unknown hazardous scenarios |

### Validation Hierarchy

```
Level 1: Simulation (widest coverage, lowest fidelity)
  - Millions of scenario variations
  - Sensor models, traffic simulation
  - Edge case generation

Level 2: Hardware-in-Loop (medium coverage, medium fidelity)
  - Real ECU, simulated sensors
  - Timing verification
  - Fault injection

Level 3: Proving Ground (targeted coverage, high fidelity)
  - Real vehicle, controlled conditions
  - NCAP scenarios
  - Repeatability

Level 4: Public Road (discovery, highest fidelity)
  - Real traffic, real weather
  - Data collection for unknown scenarios
  - Statistical validation of residual risk
```

## Next Steps

- **Level 3**: Detailed scenario database construction, simulation setup, acceptance criteria derivation
- **Level 4**: Quick reference tables for triggering conditions, ODD parameters, validation metrics
- **Level 5**: Advanced ML-specific SOTIF, continuous validation, OTA safety assurance

## References

- ISO 21448:2022 Clauses 5-7 (Specification, Hazard Identification, Triggering Conditions)
- ISO 21448:2022 Clauses 8-10 (Risk Evaluation, Verification, Validation)
- SAE J3016:2021 Levels of Driving Automation
- ISO 26262:2018 (complementary standard for functional safety)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: System architects, senior safety engineers, ADAS/AD technical leads

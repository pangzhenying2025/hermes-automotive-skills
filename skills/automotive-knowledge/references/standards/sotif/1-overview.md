# ISO 21448 (SOTIF) - Overview

## What is ISO 21448 SOTIF?

ISO 21448 "Safety Of The Intended Functionality" (SOTIF) addresses safety risks arising from functional insufficiencies and reasonably foreseeable misuse of advanced driver assistance systems (ADAS) and automated driving (AD) functions.

Published in 2022, SOTIF complements ISO 26262 (functional safety) by covering scenarios where the system works as designed, but the design itself is insufficient for the scenario encountered.

## Key Characteristics

- **Scenario-based**: Focuses on operating scenarios, not random hardware failures
- **Performance limitations**: Addresses sensor, algorithm, and actuator insufficiencies
- **Unknown unknowns**: Systematic approach to discovering hazardous scenarios
- **Validation-centric**: Extensive testing and simulation required

## Relationship to Other Standards

```
┌───────────────────────────────────────┐
│  ISO 26262 (Functional Safety)        │
│  - Random hardware faults             │
│  - Systematic software faults         │
└───────────────────────────────────────┘
           ↕ Complementary
┌───────────────────────────────────────┐
│  ISO 21448 (SOTIF)                    │
│  - Functional insufficiencies         │
│  - Unknown hazardous scenarios        │
└───────────────────────────────────────┘
           ↕ Security interface
┌───────────────────────────────────────┐
│  ISO 21434 (Cybersecurity)            │
│  - Intentional attacks                │
└───────────────────────────────────────┘
```

## Scope

SOTIF applies to:
- SAE Level 1-5 automated driving functions
- ADAS (lane keeping, adaptive cruise control, emergency braking)
- Sensor fusion systems (camera, radar, lidar)
- Perception and decision algorithms
- Human-machine interface (HMI) for automation

**Not in Scope**:
- Random hardware failures (covered by ISO 26262)
- Intentional misuse beyond reasonably foreseeable

## Four Scenario Areas

SOTIF categorizes scenarios into four quadrants:

```
                  Known Hazardous    Unknown Hazardous
                      Scenarios         Scenarios
                  ┌─────────────┬─────────────────────┐
Known Safe        │             │                     │
Scenarios         │      S1     │         S3          │
                  │   (Safe)    │  (Discovery needed) │
                  ├─────────────┼─────────────────────┤
Unknown Scenarios │             │                     │
(to be discovered)│      S2     │         S4          │
                  │ (Validation │  (The unknown       │
                  │   needed)   │   unknowns)         │
                  └─────────────┴─────────────────────┘
```

### S1: Known Safe Scenarios
Scenarios where system performance is verified as safe.

**Example**: Lane keeping on clear highway in daylight with visible lane markings.

### S2: Known Unsafe Scenarios
Scenarios identified as unsafe, requiring risk reduction.

**Example**: Lane keeping on unmarked rural road - known limitation, must be mitigated.

### S3: Unknown Safe Scenarios
Scenarios not yet validated but potentially safe.

**Example**: Lane keeping in light rain - needs testing to move to S1 or S2.

### S4: Unknown Unsafe Scenarios
Scenarios not yet discovered that could be hazardous.

**Example**: Lane keeping confused by unusual road painting (e.g., construction arrows) - discovered through field testing or incident.

**SOTIF Goal**: Minimize S3 and S4 by systematic discovery and validation.

## Triggering Conditions and Functional Insufficiency

### Triggering Conditions

Specific combinations of environmental, operational, and internal states that activate a hazardous behavior.

**Components**:
1. **Environmental**: Weather, lighting, road geometry, traffic
2. **Operational**: Vehicle speed, steering angle, driver input
3. **System Internal**: Sensor state, algorithm confidence, degraded mode

**Example Triggering Condition**:
```
Lane Departure Warning False Alarm:
  - Environment: Low sun angle (glare)
  - Environment: High-contrast shadows on road
  - Operational: Vehicle speed > 60 km/h
  - Operational: Steering wheel centered
  - System: Camera auto-gain adjusting
  → Result: Lane marking detection intermittent
  → Hazard: False warning causes driver distraction
```

### Functional Insufficiency

Limitation in intended functionality causing insufficient performance.

**Types**:
1. **Sensor limitations**: Range, resolution, field-of-view, weather sensitivity
2. **Algorithm limitations**: False positives/negatives, slow processing, edge cases
3. **Actuation limitations**: Response time, authority limits

**Example**:
- **Sensor**: Radar cannot distinguish pedestrian from shopping cart
- **Algorithm**: Object classifier trained only on upright pedestrians, fails on crouching child
- **Actuation**: Emergency braking insufficient stopping distance at high speed

## SOTIF Safety Concept

Similar to ISO 26262 safety concept, but scenario-focused.

### Acceptance Criteria

Define acceptable residual risk levels.

**Example for Emergency Braking**:
```
Acceptance Criteria:
- Detection rate: ≥99.9% for pedestrians in nominal conditions
- False positive rate: ≤0.01 per hour of driving
- Unknown hazardous scenarios: <1×10^-9 per hour (validated via 10^9 km testing)
```

### Scenario Database

Comprehensive catalog of scenarios covering:
- Nominal (expected) scenarios
- Edge case scenarios (rare but known)
- Abusive scenarios (reasonably foreseeable misuse)

**Scenario Parameters**:
- Road type (highway, urban, rural)
- Weather (clear, rain, fog, snow)
- Lighting (daylight, dusk, night, backlight)
- Traffic density (empty, light, heavy)
- Target objects (vehicles, pedestrians, cyclists, animals)

## Validation Strategy

### Simulation-Based Validation

Use virtual testing to cover vast scenario space efficiently.

**Coverage Levels**:
1. **Logical scenarios**: Abstract parameter ranges (e.g., "rain + night + highway")
2. **Concrete scenarios**: Specific instances (e.g., "3mm/h rain at 22:00 on A1 highway")
3. **Test scenarios**: Executable in simulation (specific sensor models, traffic agents)

**Tools**: CarMaker, CARLA, VTD, PreScan

### Proving Ground Testing

Real-world testing under controlled conditions.

**Test Types**:
- Track testing (NCAP scenarios, edge cases)
- Controlled public road testing (with safety driver)
- Hardware-in-loop (HIL) with real sensors

### Field Operational Tests (FOT)

Public road testing to discover unknown scenarios.

**Mileage Targets**:
- SAE Level 2: 10^7 to 10^8 km
- SAE Level 3: 10^9 km
- SAE Level 4+: 10^10 to 10^11 km (validated via accelerated testing)

**Data Collection**:
- Sensor data (camera, radar, lidar logs)
- System state (perception outputs, decisions)
- Driver interventions (takeovers, emergency braking)
- Near-miss events (automated flagging)

## SOTIF Process Overview

```
1. Hazard Identification ──→ 2. Triggering Condition Analysis
        ↓                               ↓
4. Residual Risk ←────── 3. Risk Evaluation & Mitigation
   Evaluation                           ↓
        ↓                      Verification & Validation
5. Release for                          ↓
   Production         ←──────── Coverage & Acceptance
```

### Key Activities

**Hazard Identification**: Analyze intended functionality for potential hazards

**Triggering Condition Analysis**: Identify scenarios causing hazardous behavior

**Risk Evaluation**: Assess severity, exposure, controllability

**Mitigation**: Design changes, warnings, limitations, HMI improvements

**Validation**: Systematic testing to discover unknown scenarios

**Acceptance**: Demonstrate residual risk below acceptance criteria

## Use Cases

SOTIF is essential for:
- **Adaptive Cruise Control (ACC)**: Cut-in scenarios, sensor occlusion
- **Lane Keeping Assist (LKA)**: Faded markings, construction zones
- **Automated Emergency Braking (AEB)**: False positives (bridges, shadows), stationary vehicles
- **Automated Lane Change**: Blind spot detection limitations, fast-approaching vehicles
- **Parking Assist**: Curb detection, low obstacles (e.g., parking blocks)
- **Highway Pilot (Level 3)**: Handover scenarios, construction zones, adverse weather

## ISO 26262 vs. SOTIF Comparison

| Aspect | ISO 26262 | SOTIF |
|--------|----------|-------|
| **Focus** | Random/systematic faults | Functional limitations |
| **Hazard Source** | Component failures | Insufficient performance |
| **Analysis** | FMEA, FTA | Scenario analysis, triggering conditions |
| **Validation** | Fault injection, ASIL-dependent | Exhaustive scenario coverage |
| **Metrics** | PMHF, SPFM, LFM | Detection rate, false positive rate, mileage |
| **Unknown risks** | Assumed addressed by process | Explicitly identified and reduced (S4 → S2) |

## Getting Started with SOTIF

1. **Define Intended Functionality**: Clear description of ADAS/AD feature, including limitations
2. **Identify Hazards**: What can go wrong when system performs as intended?
3. **Build Scenario Database**: Catalog known scenarios (nominal + edge cases)
4. **Analyze Triggering Conditions**: When does functional insufficiency lead to hazard?
5. **Validate Performance**: Test coverage across scenario space
6. **Monitor Field Performance**: Collect real-world data, update scenario database

## Next Steps

- **Level 2**: Conceptual understanding of triggering conditions and scenario analysis
- **Level 3**: Detailed implementation including scenario database construction
- **Level 4**: Quick reference for scenario parameters and validation metrics
- **Level 5**: Advanced topics including ML-specific SOTIF, OTA updates, continuous monitoring

## References

- ISO 21448:2022 Road vehicles - Safety of the intended functionality
- SAE J3016: Levels of Driving Automation
- UNECE WP.29 FRAV: Framework Document on Automated Vehicles
- ISO/PAS 21448:2019 (predecessor standard)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: ADAS/AD engineers, safety managers, validation engineers

# FMEA - Conceptual Methodology

## FMEA Overview

Failure Mode and Effects Analysis (FMEA) is a systematic, proactive method for evaluating a process, product, or service to identify where and how it might fail and assess the relative impact of different failures.

## FMEA Types in Automotive

### Design FMEA (DFMEA)

**Purpose**: Analyze potential failures in product design before production.

**Scope**:
- System architecture
- Component selection
- Interface design
- Safety mechanisms

**Conducted by**: Design engineers, system architects

**Timing**: Concept and design phases

**Example Application**: ECU hardware design, sensor selection

### Process FMEA (PFMEA)

**Purpose**: Analyze potential failures in manufacturing and assembly processes.

**Scope**:
- Manufacturing steps
- Assembly operations
- Testing procedures
- Quality control

**Conducted by**: Manufacturing engineers, quality engineers

**Timing**: Production planning phase

**Example Application**: PCB soldering process, final assembly

### Software FMEA (SW-FMEA)

**Purpose**: Analyze potential software failures and their effects.

**Scope**:
- Software functions
- Algorithms
- Data flows
- Error handling

**Conducted by**: Software architects, safety engineers

**Timing**: Software architecture and detailed design phases

**Example Application**: Control algorithm failures, communication errors

## AIAG-VDA FMEA Methodology (7 Steps)

The harmonized AIAG-VDA FMEA Handbook (2019) defines a standardized 7-step approach.

```
Step 1: Planning & Preparation
    ↓
Step 2: Structure Analysis
    ↓
Step 3: Function Analysis
    ↓
Step 4: Failure Analysis
    ↓
Step 5: Risk Analysis
    ↓
Step 6: Optimization
    ↓
Step 7: Results Documentation
```

### Step 1: Planning and Preparation

**Objectives**:
- Define FMEA scope
- Assemble cross-functional team
- Schedule FMEA sessions
- Gather reference documents

**Key Activities**:
- Define analysis boundaries (what's in/out of scope)
- Identify team members (design, manufacturing, quality, safety)
- Set timelines and milestones
- Collect inputs (requirements, drawings, BOM)

**Deliverables**:
- FMEA project plan
- Team roster with roles
- Scope definition document

**Example Scope**:
```
FMEA Scope: Electronic Stability Control (ESC) System

In Scope:
- ESC ECU (hardware and software)
- Wheel speed sensors (4x)
- Steering angle sensor
- Yaw rate sensor
- Hydraulic modulator

Out of Scope:
- Base braking system (separate FMEA)
- ABS system (referenced, not analyzed)
- Vehicle dynamics (black box)

Interfaces:
- CAN bus to body ECU
- Power supply from battery
- Driver warning indicators
```

### Step 2: Structure Analysis

**Objective**: Create hierarchical breakdown of system.

**Activities**:
- Develop system structure tree
- Identify components and subcomponents
- Define interfaces and boundaries

**Visualization**: Block diagram, tree structure

**Example Structure**:
```
ESC System
├── ECU
│   ├── Microcontroller (ASIL D)
│   ├── Power supply module
│   ├── CAN transceiver
│   └── Output drivers (4x solenoids)
├── Sensors
│   ├── Wheel speed sensors (4x)
│   ├── Steering angle sensor
│   └── Yaw rate + lateral accel sensor
├── Hydraulic Modulator
│   ├── Pump motor
│   ├── Solenoid valves (12x)
│   └── Pressure sensors (2x)
└── Software
    ├── Sensor signal processing
    ├── Vehicle dynamics estimation
    ├── ESC control algorithm
    └── Diagnostic manager
```

### Step 3: Function Analysis

**Objective**: Identify functions of each element in the structure.

**Function Definition**:
- What the element does
- Inputs and outputs
- Performance parameters

**Function Types**:
- Primary functions (main purpose)
- Secondary functions (supporting)
- Unintended functions (potential hazards)

**Example Functions**:
```
Element: Wheel Speed Sensor (Front-Left)

Primary Function:
- Measure rotational speed of wheel
- Output: Frequency signal proportional to speed
- Range: 0-300 km/h
- Accuracy: ±0.5 km/h

Secondary Functions:
- Provide diagnostic feedback (voltage within range)
- Withstand environmental conditions (-40°C to +125°C)

Unintended Functions:
- Generate electromagnetic interference (EMI)
```

### Step 4: Failure Analysis

**Objective**: Identify potential failure modes for each function.

**Failure Mode**: Manner in which a function can fail to be performed.

**Common Failure Modes**:
- No function (complete loss)
- Degraded function (reduced performance)
- Intermittent function (unreliable)
- Unintended function (operates when shouldn't)
- Incorrect timing (too slow, too fast)
- Incorrect magnitude (output out of range)

**Example Failure Modes**:
```
Function: Measure wheel speed

Failure Modes:
FM-1: No signal output (sensor failed, wiring open)
FM-2: Stuck signal (constant output, not responding to rotation)
FM-3: Erratic signal (noise, intermittent dropouts)
FM-4: Offset error (signal present but incorrect calibration)
FM-5: Out-of-range signal (short circuit, overvoltage)
```

### Step 5: Risk Analysis

**Objective**: Assess risk for each failure mode using Severity, Occurrence, Detection.

#### Severity (S)

**Definition**: Seriousness of the effect of the failure on the customer/system.

**AIAG-VDA Severity Scale (1-10)**:

| Rating | Effect | Description |
|--------|--------|-------------|
| 1-2 | No effect / Very slight | No impact on system performance, customer may not notice |
| 3-4 | Slight / Minor | Minor degradation, customer notices but no safety impact |
| 5-6 | Moderate / Significant | Significant performance loss, customer dissatisfied |
| 7-8 | Major / Severe | Severe performance loss, system may fail, customer very dissatisfied |
| 9-10 | Hazardous / Safety | Safety risk, regulatory non-compliance, potential injury |

**Automotive Safety Mapping**:
- S = 9-10: Maps to ISO 26262 ASIL C/D
- S = 7-8: Maps to ASIL B
- S = 5-6: Maps to ASIL A
- S = 1-4: Maps to QM (Quality Management)

**Example Severity Assignment**:
```
Failure Mode: Wheel speed sensor - No signal

Effect Chain:
Local Effect (Sensor): No signal to ECU
System Effect (ESC): ESC cannot calculate wheel slip
Vehicle Effect (Driver): ESC function unavailable during emergency maneuver
End Effect (Safety): Increased risk of loss of control, potential accident

Severity: 9 (Safety hazard - ESC is critical safety function)
```

#### Occurrence (O)

**Definition**: Likelihood that the failure cause will occur during product lifetime.

**AIAG-VDA Occurrence Scale (1-10)**:

| Rating | Probability | Failure Rate (per vehicle lifetime) |
|--------|-------------|--------------------------------------|
| 1-2 | Remote / Very slight | < 1 in 1,000,000 |
| 3-4 | Low / Slight | 1 in 100,000 to 1 in 10,000 |
| 5-6 | Moderate | 1 in 10,000 to 1 in 1,000 |
| 7-8 | High / Frequent | 1 in 1,000 to 1 in 100 |
| 9-10 | Very high / Certain | > 1 in 100 |

**Estimation Methods**:
- Historical field data (warranty claims, field returns)
- Reliability databases (IEC 61709, MIL-HDBK-217)
- Accelerated life testing
- Supplier quality data

**Example Occurrence Assignment**:
```
Failure Cause: Wheel speed sensor wiring open (vibration-induced)

Analysis:
- Sensor wiring routed near wheel well (high vibration)
- Connector IP67 rated but exposed to road debris
- Historical data: 5 failures per 10,000 vehicles over 10 years
- Failure rate: 5/10,000 = 0.05% = 1 in 2,000

Occurrence: 6 (Moderate probability)
```

#### Detection (D)

**Definition**: Likelihood that current controls will detect the failure cause or mode before it reaches the customer.

**AIAG-VDA Detection Scale (1-10)**:

| Rating | Detection Capability | Description |
|--------|---------------------|-------------|
| 1-2 | Very high / High | Failure detected with certainty by design controls |
| 3-4 | Moderately high / Moderate | High probability of detection by process controls |
| 5-6 | Low / Very low | Low probability of detection |
| 7-8 | Remote / Very remote | Very low probability of detection |
| 9-10 | Absolute uncertainty / Cannot detect | No known detection method |

**Detection Methods**:
- Design controls: Built-in diagnostics, plausibility checks, watchdogs
- Process controls: End-of-line testing, quality inspections
- Pre-delivery controls: Vehicle acceptance testing

**Example Detection Assignment**:
```
Failure Mode: Wheel speed sensor - No signal
Detection Methods:
1. ECU diagnostic: Timeout detection (signal missing > 100ms)
2. Plausibility check: Compare with opposite wheel sensor
3. End-of-line test: Functional test on dynamometer
4. Driver warning: ESC warning lamp illuminates

Detection: 2 (Very high - multiple independent detection methods)
```

### Action Priority (AP)

**AIAG-VDA Approach**: Replaces RPN (Risk Priority Number) with qualitative Action Priority.

**Action Priority Determination**:

```
High Priority (H):
- Severity = 9-10 (safety hazard) regardless of O/D
- Severity = 7-8 AND (Occurrence = 7-10 OR Detection = 7-10)

Medium Priority (M):
- Severity = 5-6 AND (Occurrence = 5-10 OR Detection = 5-10)
- Severity = 7-8 AND Occurrence/Detection moderate

Low Priority (L):
- Severity = 1-4
- Severity = 5-6 AND Occurrence/Detection low
```

**RPN (Traditional Approach)**:
```
RPN = Severity × Occurrence × Detection
Range: 1 to 1000

Thresholds (company-specific):
- RPN > 200: High priority, action required
- RPN 100-200: Medium priority, consider action
- RPN < 100: Low priority, monitor
```

### Step 6: Optimization

**Objective**: Reduce risk through corrective actions.

**Action Hierarchy**:
1. **Eliminate**: Remove failure cause (design change)
2. **Reduce Severity**: Mitigate effects (safety mechanisms)
3. **Reduce Occurrence**: Prevent failure (redundancy, robustness)
4. **Improve Detection**: Detect earlier (diagnostics, testing)

**Example Actions**:
```
Failure Mode: Wheel speed sensor - No signal (S=9, O=6, D=2, AP=High)

Action 1: Reduce Occurrence
- Improve wiring harness routing (away from vibration sources)
- Use reinforced connector (IP69K rating)
- Expected: O = 6 → 3

Action 2: Reduce Severity (ASIL decomposition)
- Add redundant sensor on same wheel (diverse technology - Hall effect)
- ESC continues to operate with single sensor failure
- Expected: S = 9 → 5 (degraded function, not complete loss)

Responsibility: Hardware Engineer (J. Smith)
Target Date: 2026-06-30
Status: In progress
```

### Step 7: Results Documentation

**Deliverables**:
- Completed FMEA worksheet
- Action tracking log
- Lessons learned

**FMEA Maintenance**:
- Update after design changes
- Update after field failures
- Review annually

## Team Composition

**Required Roles**:
- **FMEA Moderator**: Facilitates sessions, ensures methodology followed
- **Design Engineer**: Technical expertise on design
- **Manufacturing Engineer**: Production feasibility
- **Quality Engineer**: Testing and inspection
- **Safety Engineer**: ISO 26262 compliance
- **Supplier Representative**: Component-level expertise (if applicable)

**Team Size**: 4-8 people (optimal for effective collaboration)

## FMEA Session Process

**Preparation** (1 week before):
- Moderator prepares structure and function analysis
- Distributes material to team

**Session** (2-4 hours):
- Review structure and functions (30 min)
- Brainstorm failure modes (60 min)
- Assess risk (S/O/D) (60 min)
- Define actions (30 min)

**Follow-up**:
- Assign action owners
- Track action completion
- Update FMEA with results

## Timing in V-Model

```
Concept Phase:
├── System FMEA (initial)
│   └── Identify critical functions
│
Design Phase:
├── DFMEA (detailed)
│   ├── Component-level analysis
│   └── Interface analysis
│
Production Planning:
├── PFMEA
│   └── Manufacturing process analysis
│
Post-Production:
├── FMEA Update
│   └── Incorporate field data
└── Lessons Learned
```

## FMEA vs Other Analyses

| Analysis | Approach | Focus | Timing |
|----------|----------|-------|--------|
| FMEA | Bottom-up (component → system) | Single failures | Design phase |
| FTA | Top-down (hazard → causes) | Combinations | Safety analysis |
| HAZOP | Guided brainstorming | Process deviations | Process design |
| HARA | Risk-based | Hazards and ASIL | Concept phase |

**Complementary Use**:
- HARA identifies safety goals → FMEA analyzes how to achieve
- FMEA identifies critical failures → FTA analyzes combinations
- FMEA output feeds into safety case (ISO 26262)

## Relationship to ISO 26262

**ISO 26262 Requirements**:
- Part 5 (Hardware): FMEA required for hardware development
- Part 6 (Software): Software FMEA recommended for safety-critical functions
- Part 9: FMEA used for dependent failure analysis (DFA)

**FMEA Work Products**:
- Input to hardware safety analysis (Clause 8)
- Input to verification and validation (Clause 9, 10)
- Evidence for safety case

**Safety Mechanism Identification**:
```
FMEA Failure Mode → Safety Mechanism

Example:
FM: Microcontroller RAM corruption
Effect: Incorrect control calculations (S=9)
Safety Mechanism: RAM test at startup + periodic memory check
Detection: D = 2 (high detection capability)
→ Documented in Technical Safety Concept
```

## Next Steps

- **Level 3**: Detailed FMEA execution (historically covered in other docs)
- **Level 4**: FMEA worksheet templates and risk assessment tables
- **Level 5**: Advanced topics (software FMEA, FMEA-MSR integration)

## References

- AIAG-VDA FMEA Handbook (1st Edition, June 2019)
- ISO 26262-5:2018 Hardware development (Clause 8: Safety analyses)
- SAE J1739:2021 Potential Failure Mode and Effects Analysis (FMEA)
- VDA Volume 4 Part 2: FMEA for Process Optimization

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Design engineers, quality engineers, safety engineers

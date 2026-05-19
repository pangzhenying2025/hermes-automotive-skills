# ISO 26262 - Conceptual Architecture

## The V-Model Lifecycle

ISO 26262 follows a V-model development process where the left side represents decomposition and specification, and the right side represents integration and verification.

```
Concept Phase
    |
    v
Item Definition → System Design → SW/HW Design → Implementation
                                                        |
                                                        v
Production & Operation ← Integration & Test ← Unit Test
```

## Concept Phase

The concept phase establishes the safety foundation for the entire development lifecycle.

### Item Definition

**Purpose**: Define the system boundaries and operational environment.

**Key Activities**:
- Define the item (system or array of systems)
- Identify functional and non-functional requirements
- Document preliminary architecture
- Establish safety lifecycle framework

**Work Products**:
- Item definition document
- Functional specification
- Preliminary architecture
- Safety plan

### Hazard Analysis and Risk Assessment (HARA)

**Purpose**: Systematically identify hazards and determine Automotive Safety Integrity Levels (ASILs).

**Process**:
1. Identify operational situations
2. Identify hazards for each situation
3. Classify hazards using severity, exposure, controllability
4. Determine ASIL (QM, A, B, C, D)
5. Define safety goals

**HARA Parameters**:

| Parameter | Definition | Classes |
|-----------|------------|---------|
| Severity (S) | Degree of harm | S0, S1, S2, S3 |
| Exposure (E) | Probability of operational situation | E0, E1, E2, E3, E4 |
| Controllability (C) | Ability to avoid harm | C0, C1, C2, C3 |

### Functional Safety Concept

**Purpose**: Derive top-level safety requirements from safety goals.

**Content**:
- Functional safety requirements
- Allocation to architectural elements
- External measures (warnings, safe states)
- Emergency operation intervals
- Fault tolerant time intervals

**Example Safety Goal → FSR**:
```
Safety Goal (ASIL D):
"The vehicle shall prevent unintended acceleration"

Functional Safety Requirements:
FSR-1: Monitor accelerator pedal position sensor (ASIL D)
FSR-2: Implement plausibility checks on sensor values (ASIL D)
FSR-3: Activate fail-safe mode on detection of fault (ASIL D)
FSR-4: Warn driver of detected fault (ASIL B - decomposed)
```

## System Development Phase

### Technical Safety Concept

**Purpose**: Refine functional safety concept into technical requirements allocated to system elements.

**Key Activities**:
- Derive technical safety requirements
- Allocate to hardware and software
- Specify safety mechanisms
- Define diagnostic coverage requirements
- Establish warning and degradation strategies

**Safety Mechanisms Categories**:
- Detection mechanisms (monitors, plausibility checks)
- Control mechanisms (voting, redundancy)
- Mitigation mechanisms (safe states, limitation)

### System Design

**Purpose**: Develop detailed system architecture.

**Architectural Patterns**:
- Redundancy (homogeneous, diverse)
- Monitoring (watchdog, plausibility, range checks)
- Fail-operational vs fail-safe strategies
- Partitioning and freedom from interference

**Hardware-Software Interface (HSI)**:
- Define communication protocols
- Specify timing constraints
- Document failure modes
- Establish diagnostic interfaces

## Hardware Development Phase

### Hardware Safety Requirements

**Derived From**:
- Technical safety requirements allocated to hardware
- Hardware architectural assumptions
- Safety mechanisms requiring hardware support

### Hardware Design

**Design Techniques by ASIL**:
- Analysis of dependent failures
- FMEA (Failure Mode and Effects Analysis)
- FTA (Fault Tree Analysis)
- ESD and EMC considerations

### Hardware Metrics

**Random Hardware Failures**:
- Single Point Fault Metric (SPFM)
- Latent Fault Metric (LFM)
- Probabilistic Metric for Hardware Failures (PMHF)

**Target Values**:
| ASIL | PMHF Target | SPFM | LFM |
|------|-------------|------|-----|
| QM   | N/A         | N/A  | N/A |
| A    | < 10^-7/h   | ≥ 90% | ≥ 60% |
| B    | < 10^-7/h   | ≥ 90% | ≥ 60% |
| C    | < 10^-8/h   | ≥ 97% | ≥ 80% |
| D    | < 10^-8/h   | ≥ 99% | ≥ 90% |

## Software Development Phase

### Software Safety Requirements

**Characteristics**:
- Traceable to technical safety requirements
- Verifiable
- Unambiguous
- Feasible
- Includes safety mechanisms

### Software Architectural Design

**Design Principles**:
- Hierarchical structure
- Information hiding
- Restricted size and complexity
- Appropriate scheduling and timing
- Defensive programming

**Freedom from Interference**:
- Spatial (memory protection)
- Temporal (timing protection)
- Communication (data integrity)

### Software Unit Design and Implementation

**Coding Guidelines by ASIL**:
- MISRA C/C++ compliance
- Static code analysis
- Coding standards enforcement
- Metrics collection (complexity, nesting depth)

**ASIL-Specific Techniques**:

| ASIL | Required Techniques |
|------|---------------------|
| A    | One from Table 1 (e.g., semi-formal verification) |
| B    | One from Table 1 |
| C    | One from Table 1 + one from Table 2 |
| D    | One from Table 1 + Table 2 + semi-formal verification |

## Verification and Validation

### Verification Strategy

**Objective**: Confirm work products meet requirements.

**Methods by Development Phase**:
- Requirements review (inspection, walkthrough)
- Design verification (simulation, prototyping)
- Code review (manual, tool-supported)
- Unit testing (statement, branch, MC/DC coverage)
- Integration testing (interface, sequence testing)

### Validation Strategy

**Objective**: Confirm item meets safety goals under operational conditions.

**Validation Methods**:
- Test on target hardware
- Field tests in representative conditions
- Fault injection testing
- Environmental stress testing
- Long-term testing for latent faults

### Coverage Metrics by ASIL

**Code Coverage Requirements**:
| ASIL | Statement | Branch | MC/DC |
|------|-----------|--------|-------|
| A    | ++        | +      | o     |
| B    | ++        | ++     | o     |
| C    | ++        | ++     | +     |
| D    | ++        | ++     | ++    |

Legend: ++ highly recommended, + recommended, o optional

## Safety Analyses

### Deductive Analysis (FTA)

**Purpose**: Identify combinations of failures leading to hazardous events.

**Process**:
1. Define top event (hazard)
2. Identify immediate causes
3. Expand causes using logic gates (AND, OR)
4. Continue to basic events
5. Calculate probability

### Inductive Analysis (FMEA)

**Purpose**: Systematically examine failure modes of components.

**FMEA Worksheet Columns**:
- Component/Function
- Failure mode
- Effects (local, system, vehicle)
- Detection methods
- Safety mechanisms
- Severity rating
- Detection rating

### Dependent Failure Analysis (DFA)

**Purpose**: Ensure independence of redundant elements.

**Common Cause Categories**:
- Design errors (specification, implementation)
- Manufacturing defects
- Environmental stress (EMC, temperature)
- External events (power supply, ground bounce)

## Production and Operation

### Production Control

**Quality Management**:
- Change control for safety-related items
- Confirmed functional safety achievement
- Production release approval

**Manufacturing Tests**:
- End-of-line testing
- Functional verification
- Diagnostic trouble code (DTC) verification

### Operation and Service

**Field Monitoring**:
- Monitor safety goal violations
- Collect field data on failures
- Analyze trends

**Updates and Modifications**:
- Impact analysis on safety
- Regression testing
- Re-validation if required

## Supporting Processes

### Configuration Management

**Baselines**:
- Requirements baseline
- Design baseline
- Implementation baseline
- Verification baseline

### Change Management

**Change Impact Analysis**:
- Affected work products
- Impact on safety
- Required verification
- ASIL implications

### Documentation Management

**Required Documents**:
- Safety plan
- Safety case
- Hazard analysis and risk assessment
- Functional safety concept
- Technical safety concept
- Verification and validation reports
- Safety assessment report

## Work Product Flow

```
Item Definition
    ↓
HARA → Safety Goals
    ↓
Functional Safety Concept → Functional Safety Requirements
    ↓
Technical Safety Concept → Technical Safety Requirements
    ↓
System Design → System Safety Requirements
    ↓         ↓
HW Design  SW Design
    ↓         ↓
HW Impl    SW Impl
    ↓         ↓
HW Test    SW Test
    ↓         ↓
System Integration Test
    ↓
Vehicle Integration Test
    ↓
Safety Validation
```

## Next Steps

- **Level 3**: Detailed HARA execution, FMEA worksheets, PMHF calculations
- **Level 4**: Quick reference tables, checklists, templates
- **Level 5**: Advanced topics including ASIL decomposition, DFA, ML qualification

## References

- ISO 26262-3:2018 Concept phase
- ISO 26262-4:2018 Product development at the system level
- ISO 26262-5:2018 Product development at the hardware level
- ISO 26262-6:2018 Product development at the software level
- ISO 26262-8:2018 Supporting processes

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Safety engineers, system architects, project managers

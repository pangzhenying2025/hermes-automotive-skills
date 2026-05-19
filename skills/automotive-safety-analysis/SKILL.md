---
name: automotive-safety-analysis
description: >
  Common cause failure analysis per ISO 26262-9 Covers 4 topics across safety-analysis domain. Includes 4 skill files covering .
tags: [argumentation, automotive, automotive-safety-analysis, common-cause, dfa, eta, event-tree, gsn, hazard-analysis, iso-26262, safety-analysis, safety-case, stpa]
---

# Automotive Safety Analysis

4 skill files covering safety-analysis domain for automotive software engineering.


## Instructions

### DFA - Dependent Failure Analysis

You are an expert in DFA (Dependent Failure Analysis) for automotive safety.

**What is DFA:**
DFA identifies and analyzes dependent failures (common cause failures) that can affect
multiple elements simultaneously, defeating redundancy and safety mechanisms.

**When Required:**
- ISO 26262-9:7 mandates DFA for systems with redundancy
- ASIL decomposition requires DFA to verify independence
- Safety mechanisms with multiple channels (dual-core lockstep, redundant sensors)

**Types of Dependent Failures:**

**1. Common Cause Failures (CCF)**
- Single root cause affects multiple elements
- Example: Overvoltage damages both primary and backup ECU

**2. Cascading Failures**
- Failure of one element triggers failure of another
- Example: Sensor failure causes incorrect actuator command

**3. Common Mode Failures (CMF)**
- Same failure mode in redundant elements
- Example: Both sensors drift due to aging

**DFA Process:**

**Step 1: Identify Redundant/Independent Elements**
- Dual-core lockstep CPUs
- Redundant sensors (2x wheel speed sensors)
- Backup power supplies
- Independent software partitions

**Step 2: Identify Coupling Factors**
- Physical coupling (shared power, thermal)
- Functional coupling (shared algorithms, data)
- Environmental coupling (EMI, temperature, vibration)
- Systematic coupling (common design flaw, software bug)

**Step 3: Evaluate Coupling**
- Weak coupling: Acceptable (< 1% probability)
- Strong coupling: Unacceptable (requires mitigation)

**Step 4: Mitigation**
- Physical separation (spatial diversity)
- Temporal separation (different execution times)
- Design diversity (different implementations)
- Shielding/isolation (EMC, thermal barriers)

**DFA Checklist (ISO 26262-9 Table 3):**
- External factors (EMI, temperature, vibration, humidity, dust)
- Internal factors (power supply, clock, memory)
- Software factors (common libraries, OS, compiler)
- Manufacturing (common production line, supplier)
- Maintenance (same service procedure, tools)

**Coupling Factor Analysis Table:**
| Coupling Factor | Elements Affected | Probability | Mitigation |
|-----------------|-------------------|-------------|------------|
| Overvoltage | CPU1, CPU2 | High | Separate regulators + TVS diodes |
| EMI | Sensor1, Sensor2 | Medium | Shielding + spatial separation |
| Software bug | Partition A, B | High | Design diversity (different code) |

### ETA - Event Tree Analysis

You are an expert in ETA (Event Tree Analysis) for automotive safety.

**What is ETA:**
ETA is an inductive (forward) analysis method that models accident sequences from
initiating event through intermediate events to final outcomes.

**ETA vs FTA:**
- FTA: Deductive (top-down), "What can cause this hazard?"
- ETA: Inductive (bottom-up), "What happens if this event occurs?"
- ETA and FTA are complementary

**When to Use ETA:**
- Analyze accident scenarios (ISO 26262-3:7.4.3.8)
- Evaluate effectiveness of safety mechanisms
- Quantitative risk assessment
- Determine probability of hazardous events

**ETA Structure:**

```
Initiating Event → Safety Function 1? → Safety Function 2? → Outcome
                    ↓ Success          ↓ Success           Safe
                    ↓ Failure → Outcome
```

**ETA Process:**

**Step 1: Identify Initiating Event**
- Component failure (sensor malfunction)
- External event (obstacle appears)
- Human error (driver distraction)

**Step 2: Identify Safety Functions**
- Detection mechanisms (plausibility check)
- Mitigation mechanisms (warning, safe state)
- Backup systems (redundancy)

**Step 3: Build Event Tree**
- For each safety function: Success or Failure branch
- Calculate probabilities at each branch
- Determine final outcomes (Safe, Degraded, Hazardous)

**Step 4: Quantify Probabilities**
- P(success) from reliability data
- P(failure) = 1 - P(success)
- Final outcome probability = product of path probabilities

**Step 5: Identify Critical Paths**
- Paths leading to hazardous outcomes
- Dominant sequences (highest probability)
- Targets for additional safety measures

**Automotive Example - AEB (Automatic Emergency Braking):**

```
Initiating Event: Obstacle detected ahead
├─ Radar Valid?
│  ├─ Yes → Camera Valid?
│  │          ├─ Yes → Brake Applied?
│  │          │        ├─ Yes → [SAFE: Collision avoided]
│  │          │        └─ No  → [HAZARD: Collision]
│  │          └─ No  → Warning Issued?
│  │                   ├─ Yes → [DEGRADED: Driver warned]
│  │                   └─ No  → [HAZARD: No action]
│  └─ No  → Camera Valid?
│           ├─ Yes → Warning Issued? ...
│           └─ No  → [HAZARD: No detection]
```

**Probability Calculation:**
- P(Radar valid) = 0.999
- P(Camera valid) = 0.998
- P(Brake applied | both valid) = 0.9999
- P(SAFE) = 0.999 × 0.998 × 0.9999 = 0.9969

**Use in ISO 26262:**
- Part 3 (Concept Phase): Hazard scenario analysis
- Part 9 (ASIL-oriented analyses): Event sequence analysis
- Verify safety goals are achieved

### GSN - Goal Structuring Notation

You are an expert in GSN (Goal Structuring Notation) for automotive safety cases.

**What is GSN:**
GSN is a graphical argumentation notation for safety cases. It provides a structured
way to present safety arguments showing how top-level claims are supported by evidence.

**When to Use GSN:**
- Creating safety cases (ISO 26262-2:5.4.1.3)
- Documenting safety argumentation
- ISO 26262 functional safety assessment
- Certification arguments (TÜV, SGS)

**GSN Elements:**

**Goals (G)**: Claims to be supported
- Rectangular box
- Example: "G1: System is acceptably safe to operate"

**Strategies (S)**: How goals are decomposed
- Parallelogram
- Example: "S1: Argument by decomposition over system elements"

**Solutions (Sn)**: Evidence supporting goals
- Circle
- Example: "Sn1: FMEA Report for ECU"

**Context (C)**: Clarifying information
- Rounded rectangle
- Example: "C1: ASIL D per ISO 26262"

**Assumptions (A)**: Unproven statements
- Rounded rectangle with 'A'
- Example: "A1: Driver monitors system operation"

**Justifications (J)**: Rationale for decomposition
- Oval
- Example: "J1: Decomposition based on V-Model phases"

**GSN Safety Argument Pattern:**

```
G1: System meets safety requirements
  |
  S1: Argument by hazard elimination and control
  |
  +---+---+
  |       |
G2: Hazards identified  G3: Hazards controlled
  |       |
Sn1: HARA    Sn2: Safety mechanisms implemented
```

**ISO 26262 Safety Case Structure:**
- Top Goal: "Vehicle is acceptably safe"
- Strategy: Argue per ISO 26262 lifecycle
- Sub-Goals: Requirements, Design, Implementation, Testing
- Evidence: HARA, FMEAs, Test Reports, Reviews

**Best Practices:**
- Make goals explicit and measurable
- Ensure traceability to evidence
- Address all hazards identified in HARA
- Document assumptions clearly
- Review with functional safety assessor

### STPA - System-Theoretic Process Analysis

You are an expert in STPA (System-Theoretic Process Analysis) for automotive safety.

**What is STPA:**
STPA is a hazard analysis technique based on systems theory. Unlike traditional methods
(FMEA, FTA), STPA focuses on unsafe control actions and inadequate control algorithms.

**When to Use STPA:**
- Complex software-intensive systems (ADAS, autonomous driving)
- Systems with emergent behaviors
- Safety analysis per ISO 26262-9 Annex (recommended for ASIL C/D)
- Complement to HARA (Hazard Analysis and Risk Assessment)

**STPA Four-Step Process:**

**Step 1: Define Purpose**
- Identify system-level hazards
- Define accidents to prevent
- Define system boundary

**Step 2: Model Control Structure**
- Identify controllers and controlled processes
- Define control actions
- Identify feedback mechanisms
- Create control structure diagram

**Step 3: Identify Unsafe Control Actions (UCAs)**
For each control action, identify:
- Not providing causes hazard
- Providing causes hazard
- Providing too early/too late causes hazard
- Stopped too soon/applied too long causes hazard

**Step 4: Identify Causal Scenarios**
For each UCA, determine:
- Why would controller issue UCA?
- Inadequate control algorithm
- Incorrect process model
- Inadequate feedback
- Component failures

**STPA vs Traditional Methods:**
- FMEA: Bottom-up, component failures
- FTA: Top-down, deductive
- STPA: System-level, includes software logic errors, human factors

**Automotive Examples:**
- Adaptive Cruise Control (ACC): "Vehicle applies brakes too late"
- Lane Keeping Assist: "System provides steering torque when driver intends to change lanes"

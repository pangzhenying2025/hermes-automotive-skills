# Safety Analysis Rules: FMEA, FTA, and HARA Execution

> Rules for conducting hazard analysis and risk assessment (HARA),
> failure mode and effects analysis (FMEA), and fault tree analysis (FTA)
> in automotive software and system development per ISO 26262.

## Scope

These rules govern the execution of safety analyses throughout the
automotive V-model lifecycle, from concept phase HARA through detailed
design FMEA/FTA to verification-phase confirmation.

---

## Hazard Analysis and Risk Assessment (HARA)

### HARA Process

```
Step 1: Define the item and its functions
Step 2: Identify operational situations and operating modes
Step 3: Identify hazardous events (malfunction + situation)
Step 4: Classify each hazardous event (Severity, Exposure, Controllability)
Step 5: Determine ASIL for each hazardous event
Step 6: Define safety goals
Step 7: Review and approve
```

### Operational Situations

Every HARA must consider these situation categories:

```yaml
operational_situations:
  driving:
    - highway_cruising:    { speed: "100-130 km/h", traffic: "moderate" }
    - city_driving:        { speed: "0-50 km/h", traffic: "dense" }
    - rural_road:          { speed: "60-90 km/h", traffic: "light" }
    - parking_maneuvering: { speed: "0-10 km/h", traffic: "pedestrians" }
    - mountain_road:       { speed: "30-80 km/h", gradient: "steep" }

  environmental:
    - dry_road_clear:      { friction: "high", visibility: "good" }
    - wet_road_rain:       { friction: "medium", visibility: "reduced" }
    - icy_road:            { friction: "low", visibility: "variable" }
    - night_driving:       { friction: "variable", visibility: "limited" }

  vehicle_states:
    - normal_driving:      { engine: "on", systems: "nominal" }
    - towing:              { load: "increased", braking: "reduced" }
    - low_battery_soc:     { power: "limited", regen: "unavailable" }
    - thermal_limit:       { derating: "active", power: "reduced" }
```

### Severity Classification (S)

| Class | Description | Example |
|-------|-------------|---------|
| S0 | No injuries | Instrument cluster flicker |
| S1 | Light to moderate injuries | Low-speed contact, minor whiplash |
| S2 | Severe and life-threatening injuries (survival probable) | Medium-speed collision |
| S3 | Life-threatening injuries (survival uncertain), fatal | High-speed collision, fire |

### Exposure Classification (E)

| Class | Description | Probability |
|-------|-------------|-------------|
| E0 | Incredibly unlikely | < 1% of operating time |
| E1 | Very low probability | 1-2% of operating time |
| E2 | Low probability | 2-10% of operating time |
| E3 | Medium probability | 10-50% of operating time |
| E4 | High probability | > 50% of operating time |

### Controllability Classification (C)

| Class | Description | Driver Action |
|-------|-------------|--------------|
| C0 | Controllable in general | Simple, intuitive reaction |
| C1 | Simply controllable | > 99% of drivers can manage |
| C2 | Normally controllable | > 90% of drivers can manage |
| C3 | Difficult to control or uncontrollable | < 90% of drivers |

### ASIL Determination Matrix

```
+----+----+------+------+------+------+
|    |    | C1   | C2   | C3   |      |
+----+----+------+------+------+------+
| S1 | E1 | QM   | QM   | QM   |      |
| S1 | E2 | QM   | QM   | QM   |      |
| S1 | E3 | QM   | QM   | A    |      |
| S1 | E4 | QM   | A    | B    |      |
+----+----+------+------+------+------+
| S2 | E1 | QM   | QM   | QM   |      |
| S2 | E2 | QM   | QM   | A    |      |
| S2 | E3 | QM   | A    | B    |      |
| S2 | E4 | A    | B    | C    |      |
+----+----+------+------+------+------+
| S3 | E1 | QM   | QM   | A    |      |
| S3 | E2 | QM   | A    | B    |      |
| S3 | E3 | A    | B    | C    |      |
| S3 | E4 | B    | C    | D    |      |
+----+----+------+------+------+------+
```

### HARA Entry Template

```yaml
hara_entry:
  id: HE-BMS-001
  item: "Battery Management System"
  function: "Cell voltage monitoring and protection"

  malfunction: "BMS fails to detect cell over-voltage condition"
  operational_situation: "Highway cruising during regenerative braking"
  hazardous_event: "Cell thermal runaway leading to battery fire"

  severity: S3       # Life-threatening / fatal (fire risk)
  exposure: E3       # Medium - regenerative braking is common
  controllability: C3 # Difficult - fire propagation is fast

  asil: C            # From S3/E3/C3 lookup

  safety_goal:
    id: SG-BMS-001
    text: "The BMS shall prevent cell voltage from exceeding the maximum
           safe cell voltage under all operating conditions"
    asil: C
    safe_state: "Open main contactor, isolate battery pack"
    fault_tolerant_time: "100 ms"
```

---

## Failure Mode and Effects Analysis (FMEA)

### FMEA Hierarchy

```
System FMEA (concept phase)
  |
  +-- Hardware FMEA (system/HW design)
  |     |
  |     +-- Component-level failure modes
  |     +-- Interface failure modes
  |
  +-- Software FMEA (SW design)
        |
        +-- Function-level failure modes
        +-- Data flow failure modes
        +-- Interface failure modes
```

### Software FMEA Failure Mode Categories

| Category | Failure Mode | Description |
|----------|-------------|-------------|
| Value | Incorrect output | Wrong computation result |
| Value | Out of range | Output exceeds valid bounds |
| Value | Stuck-at | Output frozen at last valid value |
| Timing | Too early | Output produced before expected |
| Timing | Too late | Output produced after deadline |
| Timing | Never | Output never produced |
| Sequence | Wrong order | Operations executed out of sequence |
| Sequence | Repeated | Same operation executed multiple times |
| Sequence | Skipped | Required operation not executed |
| Communication | Lost message | CAN/Ethernet frame not received |
| Communication | Corrupted message | Data integrity compromised |
| Communication | Delayed message | Frame arrives after deadline |

### FMEA Entry Template

```yaml
fmea_entry:
  id: FMEA-BMS-SW-001
  component: "Cell Voltage Monitor Module"
  function: "Read ADC and compute cell voltages for all 96 cells"

  failure_mode: "Incorrect cell voltage computation"
  failure_cause:
    - "ADC calibration data corrupted in NVM"
    - "Integer overflow in scaling calculation"
    - "Wrong ADC channel mapping after hardware revision"

  local_effect: "Reported cell voltage differs from actual by > 50 mV"
  system_effect: "Over-voltage protection threshold not triggered"
  vehicle_effect: "Cell may exceed safe voltage, risk of thermal event"

  severity: 9        # 1-10 scale (9 = safety-critical)
  occurrence: 4      # 1-10 scale (4 = occasional)
  detection: 3       # 1-10 scale (3 = high detection probability)
  rpn: 108           # S * O * D (Risk Priority Number)

  current_controls:
    prevention:
      - "NVM CRC check on calibration data at startup"
      - "Static analysis (MISRA) catches overflow patterns"
      - "ADC channel mapping validated against HW spec in unit test"
    detection:
      - "Runtime plausibility check (cross-check adjacent cells)"
      - "Range check on computed voltage (2.5V - 4.3V per cell)"
      - "Periodic self-test comparing known reference voltage"

  recommended_actions:
    - action: "Add redundant voltage measurement via balancing IC"
      responsible: "HW Team"
      due_date: "2025-06-01"
    - action: "Implement diversity in voltage calculation algorithm"
      responsible: "SW Team"
      due_date: "2025-04-15"

  safety_mechanism: "SM-BMS-003 (Plausibility check with 50 mV threshold)"
  safety_goal_ref: "SG-BMS-001"
```

### FMEA Review Rules

- FMEA must be reviewed at every design change affecting the analyzed function
- RPN above 100 requires mandatory action plan with deadline
- Severity 9-10 items require safety mechanism regardless of RPN
- All failure modes must trace to at least one test case
- FMEA must be updated with field return data quarterly

---

## Fault Tree Analysis (FTA)

### FTA Construction Rules

```
Top Event: "Battery thermal runaway"
(Undesired system-level event linked to safety goal)
           |
     +-----+-----+
     |   OR Gate  |
     +-----+-----+
           |
     +-----+----------+
     |                 |
Cell Over-Voltage   Cell Over-Temperature
     |                 |
+----+----+      +----+----+
| OR Gate |      | OR Gate |
+----+----+      +----+----+
     |                 |
+----+----+      +----+-------+
|         |      |            |
BMS       Charger Cooling    BMS Temp
Failure   Fault  Failure     Mismatch
|                |
+---+---+  +----+----+
|AND Gate|  | OR Gate |
+---+---+  +----+----+
    |           |
+---+---+  +---+-------+
|       |  |           |
SW Mon  HW Pump       Fan
Fail    Fail Fail      Fail
```

### FTA Quantitative Analysis

```yaml
fault_tree:
  top_event:
    id: FT-BMS-001
    description: "Battery thermal runaway"
    target_probability: 1e-8  # per operating hour

  gates:
    - id: G1
      type: OR
      inputs: [BE-001, BE-002]
      description: "Cell over-voltage OR cell over-temperature"

    - id: G2
      type: AND
      inputs: [BE-003, BE-004]
      description: "SW monitor failure AND HW monitor failure"

  basic_events:
    - id: BE-001
      description: "BMS software fails to detect over-voltage"
      failure_rate: 1e-5  # per hour (before safety mechanism)
      safety_mechanism: "SM-BMS-003"
      diagnostic_coverage: 0.99
      residual_rate: 1e-7  # after safety mechanism

    - id: BE-003
      description: "Software overcurrent monitor failure"
      failure_rate: 1e-4
      safety_mechanism: "SM-BMS-005"
      diagnostic_coverage: 0.95
      residual_rate: 5e-6

    - id: BE-004
      description: "Hardware overcurrent limiter failure"
      failure_rate: 1e-6  # hardware random failure rate
      diagnostic_coverage: 0.90
      residual_rate: 1e-7

  calculations:
    G2_probability: "BE-003_residual * BE-004_residual = 5e-6 * 1e-7 = 5e-13"
    top_event: "Sum of all paths through OR gates"
```

### FTA Rules

- Top event must link directly to a safety goal violation
- Minimum cut sets must be identified and documented
- Common cause failures must be modeled as shared basic events
- Quantitative analysis required for ASIL C and D
- FTA must be consistent with FMEA (same failure modes)
- Updated whenever architecture changes

---

## Safety Mechanism Coverage

### Diagnostic Coverage Targets

| ASIL | Single-Point Fault Metric | Latent Fault Metric |
|------|--------------------------|---------------------|
| ASIL A | No target | No target |
| ASIL B | >= 90% | >= 60% |
| ASIL C | >= 97% | >= 80% |
| ASIL D | >= 99% | >= 90% |

### Safety Mechanism Documentation

```yaml
safety_mechanism:
  id: SM-BMS-003
  name: "Cell voltage plausibility check"
  type: "Online monitoring (runtime diagnostic)"

  description: >
    Cross-checks adjacent cell voltages for plausibility.
    Flags an error if any cell differs from its neighbor by
    more than 200 mV (configurable threshold).

  detects:
    - "ADC stuck-at fault (single channel)"
    - "Voltage scaling error (single cell)"
    - "Wiring fault (open sense wire)"

  does_not_detect:
    - "Systematic calibration error affecting all cells equally"
    - "Gradual drift within tolerance"

  diagnostic_coverage: 0.95
  fault_reaction_time_ms: 20
  safe_state: "Set cell voltage to maximum safe value, trigger warning"

  fmea_refs: [FMEA-BMS-SW-001, FMEA-BMS-SW-003]
  fta_refs: [BE-001]
  test_refs: [TC-SM-003-01, TC-SM-003-02, TC-SM-003-03]
```

---

## Traceability Requirements

```
Safety Goal (HARA)
    |
    +-- Functional Safety Requirement
    |       |
    |       +-- Technical Safety Requirement
    |       |       |
    |       |       +-- Software Safety Requirement
    |       |       |       |
    |       |       |       +-- Implementation (code)
    |       |       |       +-- Unit Test
    |       |       |
    |       |       +-- Hardware Safety Requirement
    |       |
    |       +-- Safety Mechanism
    |               |
    |               +-- FMEA entry (failure mode detected by SM)
    |               +-- FTA basic event (covered by SM)
    |               +-- Verification test case
    |
    +-- HARA hazardous event
            |
            +-- FMEA system effect
            +-- FTA top event
```

**Rule**: Every safety analysis artifact must be bidirectionally traceable:
- HARA -> Safety Goals -> Safety Requirements
- FMEA failure modes -> Safety Mechanisms -> Test Cases
- FTA basic events -> Safety Mechanisms -> Design elements
- Safety Mechanisms -> Diagnostic coverage evidence

---

## Review and Maintenance

### Analysis Review Triggers

| Trigger | Required Action |
|---------|----------------|
| New feature added | Extend HARA, update FMEA |
| Architecture change | Review FTA, update FMEA |
| Field incident report | Review HARA severity/exposure, update FMEA |
| Supplier component change | Update hardware FMEA |
| Safety audit finding | Address in next FMEA review |
| Every major release | Full FMEA review |

---

## Review Checklist

- [ ] HARA covers all functions and operational situations
- [ ] S/E/C classifications are justified and documented
- [ ] Safety goals defined for all hazardous events with ASIL >= A
- [ ] FMEA covers all software functions and interfaces
- [ ] All failure modes have prevention and detection controls
- [ ] RPN > 100 items have action plans with deadlines
- [ ] FTA constructed for all ASIL C/D safety goals
- [ ] FTA minimum cut sets identified
- [ ] Safety mechanisms documented with diagnostic coverage
- [ ] Fault metrics meet ASIL targets
- [ ] Full bidirectional traceability established
- [ ] Analysis artifacts reviewed and approved by safety team

# ISO 26262 - Detailed Implementation Guide

## HARA Execution Guide

### Step 1: Define Operational Situations

Operational situations describe the vehicle's usage context.

**Examples**:
- Highway driving at high speed
- Urban driving at low speed
- Parking maneuvers
- Emergency braking
- Towing a trailer
- Driving in adverse weather

**Documentation Template**:
```
Operational Situation ID: OS-001
Description: Highway driving at speeds > 80 km/h
Environmental Conditions: Dry road, daylight
Driver State: Attentive
Traffic Density: Medium
```

### Step 2: Identify Hazardous Events

For each function, identify malfunctions and their effects in operational situations.

**Example for Electronic Stability Control (ESC)**:
- Loss of ESC function during cornering
- Unintended ESC activation on straight road
- Delayed ESC response
- Incorrect ESC intervention magnitude

### Step 3: Severity Classification

**S0 - No injuries**: No effect on safety.

**S1 - Light and moderate injuries**:
- Minor whiplash
- Bruises
- Cuts

**S2 - Severe and life-threatening injuries**:
- Broken bones
- Severe whiplash
- Internal injuries

**S3 - Life-threatening/fatal injuries**:
- Probable fatality
- Multiple severe injuries
- Head trauma

**Classification Decision Tree**:
```
Does malfunction lead to collision or loss of control?
  ├─ No → S0 or S1
  └─ Yes
      ├─ Low speed (<30 km/h) → S1 or S2
      └─ High speed (>30 km/h) → S2 or S3
```

### Step 4: Exposure Classification

**E0 - Incredible**: Exposure is virtually impossible (< 0.001% of operating time)

**E1 - Very low probability**: < 1% of operating time
- Example: Towing trailer (for passenger car)

**E2 - Low probability**: 1-5% of operating time
- Example: Parking maneuvers

**E3 - Medium probability**: 5-50% of operating time
- Example: Urban driving

**E4 - High probability**: > 50% of operating time
- Example: Normal highway driving

**Exposure Estimation Formula**:
```
E = (T_situation / T_total) × 100%

where:
T_situation = Annual time in specific operational situation
T_total = Total annual operating time
```

**Example Calculation**:
```
Highway driving exposure:
T_highway = 3000 km/year ÷ 100 km/h = 30 hours/year
T_total = 15,000 km/year ÷ 40 km/h avg = 375 hours/year
E = 30/375 = 8% → E3 (Medium probability)
```

### Step 5: Controllability Classification

**C0 - Controllable in general**: More than 99% of drivers can avoid harm

**C1 - Simply controllable**: More than 90% of drivers can avoid harm
- Warning in time for simple avoidance maneuver
- Example: Loss of cruise control with immediate warning

**C2 - Normally controllable**: More than 60% of drivers can avoid harm
- Avoidance requires attention and skill
- Example: Single wheel brake failure at moderate speed

**C3 - Difficult to control or uncontrollable**: Less than 60% of drivers can avoid harm
- Sudden, unexpected event
- Complex avoidance maneuver required
- Example: Sudden unintended acceleration

**Controllability Factors**:
- Time available for driver reaction
- Complexity of avoidance maneuver
- Predictability of malfunction
- Driver warning/notification
- Residual vehicle capability

### Step 6: ASIL Determination

**ASIL Determination Matrix**:

```
S3  | QM(a) | A    | B    | C    | D    |
S2  | QM(a) | QM(a)| A    | B    | C    |
S1  | QM(a) | QM(a)| QM(a)| A    | B    |
----|-------|------|------|------|------|
    | C0,C1 | C2   | C2   | C3   | C3   |
         E1      E2     E3     E4
```

(a) QM requires quality management per ISO 9001

**Example HARA Entry**:
```
Hazardous Event: Unintended full braking on highway
Operational Situation: Highway driving > 100 km/h
Severity: S3 (rear-end collision, fatal injuries)
Exposure: E4 (highway driving common)
Controllability: C3 (sudden, unexpected, difficult to avoid)
ASIL: D
```

### Step 7: Define Safety Goals

**Safety Goal Template**:
```
Safety Goal ID: SG-ESC-001
Hazardous Event: Loss of ESC function during emergency maneuver
Safe State: ESC degraded mode with driver warning
ASIL: D
Fault Tolerant Time Interval: 100 ms
Emergency Operation Interval: Remainder of driving cycle
Verification Criteria: ESC intervention within 100ms of skid detection
```

## FMEA Execution Guide

### FMEA Worksheet Template

| Component | Function | Failure Mode | Local Effect | System Effect | Vehicle Effect | S | Detection Method | D | Safety Mechanism | Remarks |
|-----------|----------|--------------|--------------|---------------|----------------|---|------------------|---|------------------|---------|
| Wheel speed sensor | Provide wheel speed | No signal | ECU receives invalid data | ESC unavailable | Loss of stability control | 9 | Plausibility check, timeout | 3 | Redundant sensor on same wheel | ASIL D |

**Column Definitions**:

**S (Severity)**: 1-10 scale
- 1-3: Minor, no safety impact
- 4-6: Moderate, degraded function
- 7-8: Severe, safety function lost
- 9-10: Critical, hazardous event

**D (Detection)**: 1-10 scale
- 1-2: Almost certain detection before customer
- 3-4: High detection probability
- 5-6: Medium detection probability
- 7-8: Low detection probability
- 9-10: Undetectable

### DFMEA Process

**Step 1: Component Decomposition**
```
Electronic Stability Control System
├── Wheel Speed Sensors (4x)
├── Steering Angle Sensor
├── Yaw Rate Sensor
├── Lateral Acceleration Sensor
├── ESC ECU
│   ├── Microcontroller
│   ├── Power supply
│   ├── CAN transceiver
│   └── Output drivers
└── Hydraulic Modulator
    ├── Pump motor
    ├── Solenoid valves (12x)
    └── Pressure sensors (2x)
```

**Step 2: Identify Failure Modes**

For each component, systematically identify:
- No function (complete loss)
- Degraded function (partial performance)
- Intermittent function
- Unintended function
- Incorrect magnitude
- Incorrect timing

**Example for Wheel Speed Sensor**:
```
Failure Modes:
FM-1: No signal (sensor failure, wiring open)
FM-2: Stuck signal (frozen value)
FM-3: Noisy signal (intermittent drops)
FM-4: Offset error (calibration drift)
FM-5: Out-of-range signal (short circuit)
```

**Step 3: Analyze Effects**

Trace failure mode through system levels:
```
Local Effect (Sensor):
  No signal detected by ECU

System Effect (ESC):
  ESC cannot calculate vehicle dynamics
  ESC function degraded or disabled

Vehicle Effect (Safety):
  Loss of stability assistance during emergency maneuver
  Increased risk of loss of control
```

**Step 4: Identify Safety Mechanisms**

For each critical failure mode:
- Detection mechanism
- Diagnostic coverage
- Reaction (safe state, warning, degradation)

**Example Safety Mechanisms**:
```
Detection:
- Plausibility check (wheel speed vs vehicle speed)
- Signal range check (0-255 km/h valid range)
- Signal timeout (100ms max interval)
- Comparison with opposite wheel (max 20% difference)

Reaction:
- Set DTC P0500 (vehicle speed sensor malfunction)
- Illuminate ESC warning lamp
- Disable ESC function, retain base braking
- Fall back to accelerometer-based estimation
```

## Fault Tree Analysis (FTA)

### FTA Construction Process

**Top Event**: Define hazardous event from HARA

**Example FTA for "Unintended Braking"**:

```
                  Unintended Full Braking
                           |
                   +-------+-------+
                   |               |
            False Activation   Cannot Deactivate
                   |               |
           +-------+-------+       +-------+-------+
           |       |       |       |       |       |
        SW Bug  HW Fault Sensor   Brake   ECU    CAN
                          Error   Stuck   Hang   Fault
```

**Logic Gates**:
- OR gate: Event occurs if any input occurs
- AND gate: Event occurs only if all inputs occur
- NOT gate: Event occurs if input does not occur

**FTA Symbols**:
```
┌─────────┐
│  Event  │  Rectangle: Intermediate event (output of logic gate)
└─────────┘

    ◇        Diamond: Undeveloped event (not analyzed further)

    ○        Circle: Basic event (leaf node, failure rate known)
```

### Quantitative FTA

**Calculate Top Event Probability**:

**OR gate**: P(A OR B) = P(A) + P(B) - P(A) × P(B)
- For small probabilities: P(A OR B) ≈ P(A) + P(B)

**AND gate**: P(A AND B) = P(A) × P(B)

**Example Calculation**:
```
Top Event: Unintended Braking
  OR gate
    ├─ False Activation (λ = 10 FIT)
    └─ Cannot Deactivate (AND gate)
         ├─ Brake Stuck (λ = 50 FIT)
         └─ ECU Cannot Command Release (λ = 100 FIT)

FIT = Failures in 10^9 hours

P(Cannot Deactivate) = (50 × 10^-9) × (100 × 10^-9) = 5 × 10^-15 /h
P(Top Event) = 10×10^-9 + 5×10^-15 ≈ 10×10^-9 = 10 FIT
```

## Safety Requirement Derivation

### From Safety Goal to FSR

**Safety Goal**: "Vehicle shall prevent unintended acceleration"
**ASIL**: D

**Functional Safety Requirements**:
```
FSR-UA-001 (ASIL D):
The system shall monitor accelerator pedal position sensor
for plausibility.

Verification:
- Static: Review sensor monitoring logic
- Dynamic: Inject sensor faults, verify detection within 100ms

FSR-UA-002 (ASIL D):
Upon detection of implausible accelerator pedal position,
the system shall limit engine torque to idle.

Verification:
- Dynamic: Inject sensor faults during acceleration
- Criteria: Torque reduction to <50 Nm within 200ms

FSR-UA-003 (ASIL B - decomposed from D):
The system shall warn the driver of accelerator pedal sensor fault.

Verification:
- Dynamic: Verify warning lamp activation
- Criteria: Warning within 500ms of fault detection
```

### ASIL Decomposition Example

**Original Requirement** (ASIL D):
"Prevent unintended acceleration"

**Decomposition Strategy**:
```
FSR-UA-001 (ASIL D → ASIL B(D) + ASIL B(D)):

Component A (ASIL B):
- Monitor APP sensor 1
- Independent diagnostic on sensor 1
- Torque reduction on fault

Component B (ASIL B):
- Monitor APP sensor 2
- Independent diagnostic on sensor 2
- Torque reduction on fault

Both components must fail for hazard to occur (AND gate)
```

**Validation**: ASIL B(D) + ASIL B(D) achieves ASIL D when:
- Components are sufficiently independent
- No common cause failures
- Each component meets ASIL B requirements

## PMHF Calculation

### Single Point Fault Metric (SPFM)

**Formula**:
```
SPFM = 1 - (Σ λ_SPF / Σ λ)

where:
λ_SPF = Failure rate of single point faults
λ = Total failure rate of safety element
```

**Example**:
```
Wheel Speed Sensor:
λ_total = 100 FIT
λ_detected = 70 FIT (detected by plausibility checks)
λ_safe = 20 FIT (safe failure, no effect)
λ_SPF = 10 FIT (undetected, leads directly to violation)

SPFM = 1 - (10/100) = 0.90 = 90%

Target for ASIL D: ≥ 99% → Need improved diagnostics
```

### Latent Fault Metric (LFM)

**Formula**:
```
LFM = 1 - (Σ λ_latent / Σ λ_multi-point)

where:
λ_latent = Latent faults not detected within test interval
λ_multi-point = All multi-point faults
```

**Example**:
```
Redundant sensor system:
λ_multi-point = 50 FIT (failures not directly hazardous)
λ_detected_online = 40 FIT (detected by online diagnostics)
λ_latent = 10 FIT (detected only by periodic test)

LFM = 1 - (10/50) = 0.80 = 80%

Target for ASIL D: ≥ 90% → Need more frequent testing
```

### Probabilistic Metric for Hardware Failures (PMHF)

**Simplified Formula for Single Element**:
```
PMHF = λ_SPF + λ_RF × Σ λ_latent × T_lifetime / 2

where:
λ_SPF = Single point fault rate
λ_RF = Residual fault rate (detected but not safe)
λ_latent = Latent fault rate
T_lifetime = Vehicle lifetime (typically 15 years)
```

**Example for ASIL D ECU**:
```
Given:
λ_SPF = 2 FIT
λ_RF = 1 FIT
λ_latent = 5 FIT (for redundant element)
T_lifetime = 15 years = 131,400 hours

PMHF = 2×10^-9 + 1×10^-9 × 5×10^-9 × 131,400/2
     = 2×10^-9 + 3.3×10^-13
     ≈ 2×10^-9 /h
     = 2 FIT

Target for ASIL D: < 10 FIT → PASS
```

## Next Steps

- **Level 4**: Quick reference tables, ASIL matrices, metric targets
- **Level 5**: Advanced DFA, freedom from interference, ML safety

## References

- ISO 26262-3:2018 Concept phase (HARA)
- ISO 26262-5:2018 Hardware development (Metrics)
- ISO 26262-9:2018 ASIL-oriented analysis

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Safety engineers, system developers, V&V engineers

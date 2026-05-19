# FMEA - Advanced Techniques

## FMEA and Fault Tree Analysis (FTA) Integration

FMEA is bottom-up (component → system), FTA is top-down (hazard → causes). Combining them provides comprehensive risk analysis.

### Complementary Relationship

```
Top-Down: FTA                    Bottom-Up: FMEA
────────────────                 ────────────────
Hazard: Vehicle Fire             Component: HV Battery
    ↓                                ↓
  Thermal Runaway                 Failure Mode: Cell overvoltage
    ↓                                ↓
  Cell Overvoltage                Effect: Thermal runaway → Fire
    ↓                                ↓
  BMS Failure                     Cause: Charge control failure
    ↓                                ↑
 ┌───┴───┬────────┐                  │
AND  OR  Condition              FMEA feeds FTA basic events
 │
FMEA identifies
basic events
```

### Integration Workflow

**Step 1: Perform FMEA**
Identify failure modes, effects, and causes for all components.

**Step 2: Identify Top Events for FTA**
Select high-severity FMEA effects (S≥9) as FTA top events.

**Example**:
- FMEA Effect: "Cell thermal runaway causing vehicle fire" (S=10)
- FTA Top Event: "Vehicle Fire"

**Step 3: Build Fault Tree**
Use FMEA causes as basic events in FTA.

```
                    Vehicle Fire (Top Event)
                          │
                    ┌─────┴─────┐
                   OR
         ┌──────────┴──────────┐
    Thermal        Fuel System    Electrical
    Runaway         Leak           Short
         │
    ┌────┴────┐
   AND
┌──────┴──────┐
Cell        No Fire
Overvoltage  Suppression
│               │
├─ (from FMEA: Charge control failure)
├─ (from FMEA: Voltage sensor failure)
└─ (from FMEA: BMS software fault)
```

**Step 4: Quantify FTA**
Use FMEA Occurrence ratings to assign probabilities to basic events.

**Example**:
- FMEA: Charge control failure, O=4 → 100 PPM → P=10^-4
- FTA: Cell overvoltage probability = P(Charge failure AND No suppression)

**Step 5: Validate FMEA Severity**
FTA cut-sets confirm which failure combinations lead to top event.

If FTA shows multiple paths to hazard, verify FMEA captured all combinations.

### FMEA-FTA Cross-Reference Table

| FMEA Failure Mode | FMEA Effect (S) | FMEA Cause (O) | FTA Top Event | FTA Basic Event | FTA Probability |
|------------------|----------------|---------------|--------------|----------------|----------------|
| Cell overvoltage | Thermal runaway (10) | Charge control failure (4) | Vehicle Fire | E1: Charge control failure | 1×10^-4 |
| Voltage sensor stuck high | Cell overcharge (10) | Sensor failure (3) | Vehicle Fire | E2: Sensor failure | 2×10^-5 |
| Cooling pump failure | Cell overtemperature (9) | Bearing wear (5) | Thermal Runaway | E3: Pump failure | 5×10^-4 |

## Model-Based FMEA

Use system models (SysML, Simulink, MBSE) to semi-automate FMEA generation.

### Model-Based Systems Engineering (MBSE) + FMEA

**Traditional FMEA**: Manual creation from block diagrams and schematics.

**Model-Based FMEA**: Derive FMEA from system architecture model.

#### SysML Model Elements

```
┌──────────────────────────────────────┐
│  Block: BatteryManagementSystem      │
├──────────────────────────────────────┤
│  Parts:                              │
│    - CellMonitoringCircuit           │
│    - ChargeControl                   │
│    - ContactorDriver                 │
│  Ports:                              │
│    - CellVoltage[in]: Real[96]       │
│    - ChargeCommand[out]: Boolean     │
│  Requirements:                       │
│    - REQ-001: Measure voltage ±10mV  │
│    - REQ-002: Prevent overvoltage    │
└──────────────────────────────────────┘
```

#### Automatic FMEA Generation

**Model Annotations**:
```sysml
Block CellMonitoringCircuit {
    Constraint: VoltageAccuracy ±10mV
    FailureMode: "Reading 10% high" {
        Severity: 10  // leads to overvoltage
        Cause: "ADC drift"
        Detection: "Self-test vs reference"
    }
}
```

**FMEA Tool** (e.g., Medini Analyze, APIS IQ-FMEA):
- Parses model
- Extracts components, functions, interfaces
- Generates FMEA skeleton
- Analyst fills in Occurrence, Detection ratings

**Benefits**:
1. Traceability: FMEA linked to requirements and design
2. Consistency: Failure modes propagate through architecture
3. Reusability: Library of component failure modes
4. Change management: Model updates trigger FMEA review

### Simulink Fault Injection

Inject faults into Simulink models to simulate FMEA failure modes.

```matlab
% Normal model
CellVoltage = ADC_Read();
if CellVoltage > VoltageLimit
    OpenContactor();
end

% Fault injection (ADC stuck high)
if FaultActive == 1
    CellVoltage = 4.5;  % Inject fault
else
    CellVoltage = ADC_Read();
end
```

**Use Cases**:
- Verify FMEA Effect predictions (does stuck-high ADC really cause overvoltage?)
- Test detection mechanisms (does self-test catch the fault?)
- Quantify Occurrence via Monte Carlo (how often do parameter variations cause failure?)

## Bayesian Networks for Dynamic FMEA

Traditional FMEA uses static Occurrence ratings. Bayesian networks model dynamic dependencies.

### Bayesian FMEA Workflow

**Step 1: Build Bayesian Network**

Nodes represent failure events; edges represent causal relationships.

```
      Component Aging
            │
            ↓
       ADC Drift ────→ Overvoltage Event
            ↑              ↑
            │              │
      Temperature     Charge Control
       Stress            Failure
```

**Step 2: Assign Conditional Probability Tables (CPTs)**

| Aging | Temp Stress | P(ADC Drift) |
|-------|------------|-------------|
| Low   | Low        | 0.0001      |
| Low   | High       | 0.001       |
| High  | Low        | 0.005       |
| High  | High       | 0.02        |

**Step 3: Inference**

Given evidence (e.g., "Vehicle operates in hot climate"), compute updated probabilities.

```python
# Bayesian inference (pseudocode)
P(Overvoltage | HotClimate) = ?

# Update:
P(ADC_Drift | HotClimate) increases
→ P(Overvoltage | HotClimate) increases
→ Update FMEA Occurrence rating dynamically
```

**Benefits**:
- Accounts for multiple causes contributing to failure
- Updates Occurrence based on operating conditions
- Propagates uncertainty through system

**Tools**: BayesiaLab, Hugin, GeNIe

## Real-Time FMEA Updates with Field Data

Traditional FMEA is static (created during design). Dynamic FMEA updates ratings based on field data.

### Fleet Data Integration

**Data Sources**:
1. Diagnostic Trouble Codes (DTCs) from connected vehicles
2. Warranty claims and field failures
3. Software error logs uploaded via OTA

**Workflow**:

```
Fleet Data ──→ Analytics ──→ Updated O/D ──→ FMEA Re-evaluation ──→ OTA Fix
  (DTCs)        (ML model)    (dynamic)      (trigger actions)      (deploy)
```

**Example**:

**Original FMEA**:
- Failure Mode: "CAN timeout due to EMI"
- Occurrence: O=3 (based on bench testing)
- RPN: 180

**Field Data (6 months)**:
- DTC B1234 (CAN timeout) observed in 0.5% of fleet → 5,000 PPM → O=5

**Updated FMEA**:
- Occurrence: O=5 (updated from field data)
- RPN: 300 → Triggers action

**Action**: Deploy OTA update with improved CAN error handling.

### Predictive FMEA

Use machine learning to predict future Occurrence rates.

**ML Model Inputs**:
- Component age (mileage, time in service)
- Operating conditions (temperature cycles, charge/discharge cycles)
- Maintenance history

**ML Model Output**:
- Predicted time-to-failure distribution
- Updated Occurrence rating as function of time

**Example**:
```
Component: HV Battery Pack
Initial O=2 (new vehicle)
After 100k miles: O=4 (degradation increases failure rate)
Predictive maintenance triggered when O reaches threshold
```

## FMEA for Software (SW-FMEA)

Software FMEA analyzes failure modes in software architecture and algorithms.

### Software Failure Mode Categories

1. **Algorithmic**: Wrong calculation, logic error
2. **Timing**: Deadline miss, race condition
3. **Data**: Corruption, wrong value, loss
4. **Interface**: Wrong message, timeout, sequence error
5. **Resource**: Memory leak, stack overflow, CPU overload
6. **State**: Stuck state, invalid transition

### SW-FMEA Example

| Software Function | Failure Mode | Effect | S | Cause | O | Detection | D | RPN | Action |
|------------------|--------------|--------|---|-------|---|-----------|---|-----|--------|
| SOC Calculation (Coulomb Counting) | Accumulated error >5% | Inaccurate range estimate | 6 | Current sensor offset drift | 4 | None (累 error) | 8 | 192 | Add periodic SOC recalibration via OCV |
| CAN Receive Task | Message timeout | Lost communication with charger | 8 | Bus-off condition | 3 | CAN error counter | 4 | 96 | Add automatic bus-off recovery |
| Battery State Machine | Stuck in "Charging" state | Cannot discharge (vehicle won't drive) | 8 | Missing state exit condition | 2 | Watchdog timeout | 3 | 48 | Add state timeout transitions |

### FMEA-Driven Software Testing

Map FMEA failure modes to test cases.

| SW Failure Mode | Test Case | Test Method | Expected Result |
|----------------|-----------|-------------|-----------------|
| SOC error >5% | TC-SOC-015 | Inject current sensor offset +5A for 1hr | SOC error detected, OCV recalibration triggered |
| CAN timeout | TC-COM-008 | Disconnect CAN bus for 1s | DTC set, safe mode entered |
| Race condition | TC-SYNC-003 | Stress test with rapid state changes | No deadlock, all transitions valid |

## FMEA in Agile/DevOps Environment

Traditional FMEA is waterfall (upfront, infrequent updates). Agile FMEA is iterative.

### Continuous FMEA

**Sprint-Level FMEA**:
- Each sprint updates FMEA for new features
- FMEA becomes part of Definition of Done

**Example Sprint FMEA**:
```
Sprint 15: Add regenerative braking control

New Failure Modes:
- Regen current exceeds battery limit → S=8, O=4, D=5, RPN=160
  Action: Add current limiting in regen algorithm (Story REGEN-45)

Updated Failure Modes:
- Battery overcharge (now possible via regen) → S=10, O=3→4 (increased), D=4
  Action: Enhance SOC upper limit protection (Story SOC-67)
```

**FMEA Automation**:
- Store FMEA in version control (JSON, YAML)
- Auto-generate FMEA report from structured data
- Link FMEA items to Jira stories/issues

```yaml
# fmea.yaml
failure_modes:
  - id: FM-001
    function: "Regenerative braking control"
    failure_mode: "Regen current exceeds limit"
    effect: "Battery overvoltage"
    severity: 8
    cause: "Inverter current control error"
    occurrence: 4
    detection: "Real-time current monitoring"
    detection_rating: 5
    rpn: 160
    actions:
      - id: REGEN-45
        description: "Add 2% margin to current limit"
        owner: "John Smith"
        status: "In Progress"
```

### FMEA-Driven Security Testing (STRIDE + FMEA)

Combine cybersecurity threat modeling (STRIDE) with FMEA.

**STRIDE Threats**:
- **S**poofing
- **T**ampering
- **R**epudiation
- **I**nformation Disclosure
- **D**enial of Service
- **E**levation of Privilege

**Security FMEA Example**:

| Asset | Threat (Failure Mode) | Effect | S | Attack Vector (Cause) | O | Detection | D | RPN | Mitigation |
|-------|---------------------|--------|---|--------------------|---|-----------|---|-----|------------|
| OTA Update | Tampered firmware (T) | Malicious code execution | 10 | Man-in-middle attack | 3 | Signature verification | 2 | 60 | Use TLS + code signing |
| CAN Bus | Spoofed messages (S) | False BMS commands | 9 | Physical CAN access | 4 | Message authentication (MAC) | 6 | 216 | Implement CAN message authentication |
| Diagnostic Port | Elevation of privilege (E) | Unauthorized calibration change | 8 | Stolen service tool | 5 | Challenge-response auth | 4 | 160 | Add HSM-based authentication |

## FMEA for Autonomous Vehicles (SOTIF Integration)

ISO 21448 (SOTIF) addresses functional insufficiencies and unknown scenarios. Integrate with FMEA.

### SOTIF-FMEA Hybrid

**Traditional FMEA**: Hardware/software faults
**SOTIF**: Functional limitations + unknown scenarios

**Combined Approach**:

| Item | Failure Mode | SOTIF Triggering Condition | Effect | S | Cause | O | Detection | D | RPN |
|------|--------------|--------------------------|--------|---|-------|---|-----------|---|-----|
| Camera Object Detection | False negative (miss pedestrian) | Low contrast (dark clothing at night) | Collision with pedestrian | 10 | Insufficient sensor range | 6 | None (unknown scenario) | 9 | 540 |
| Lidar | False positive (ghost object) | Rain/fog reflection | Unnecessary emergency brake | 7 | Environmental limitation | 5 | Multi-sensor fusion cross-check | 4 | 140 |

**Actions**:
- FMEA Action: Add radar sensor for redundancy
- SOTIF Action: Expand scenario database with edge cases, increase test mileage

## Advanced FMEA Metrics

### FMEA Effectiveness Metrics

**1. FMEA Completeness**:
```
Completeness = (Failure modes identified) / (Total possible failure modes)
```
Benchmark: >90% for critical systems

**2. Action Closure Rate**:
```
Closure Rate = (Actions completed) / (Actions recommended)
```
Target: 100% before production release

**3. RPN Reduction**:
```
RPN Improvement = ((Initial RPN - Revised RPN) / Initial RPN) × 100%
```
Industry average: 60-80% reduction

**4. Defect Escape Rate**:
```
Escape Rate = (Field failures not in FMEA) / (Total field failures)
```
Target: <10% (90% of field issues predicted by FMEA)

### FMEA Maturity Model

| Level | Maturity | Characteristics |
|-------|----------|----------------|
| 1 | Initial | FMEA done only when required; inconsistent format |
| 2 | Managed | FMEA templates standardized; basic training |
| 3 | Defined | FMEA integrated into design process; lessons learned captured |
| 4 | Quantitatively Managed | FMEA metrics tracked; data-driven Occurrence ratings |
| 5 | Optimizing | Continuous FMEA updates; model-based automation; field data integration |

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Advanced FMEA practitioners, reliability engineers, system safety engineers

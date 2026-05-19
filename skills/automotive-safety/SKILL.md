---
name: automotive-safety
description: >
  Automotive Safety expertise. Covers 6 topics: Fmea Fta Analysis, Hazard Analysis Risk Assessment, Iso 26262 Overview, Safety Mechanisms Patterns, Safety Verification Validation.
tags: [automotive, automotive-safety]
---

# Automotive Safety

## Fmea Fta Analysis

# FMEA/FTA/FMEDA Analysis for ISO 26262

Comprehensive guidance on Failure Mode and Effects Analysis (FMEA), Fault Tree Analysis (FTA), and Failure Modes, Effects, and Diagnostic Analysis (FMEDA) for automotive functional safety, including templates, calculation methods, and production-ready examples.

## Overview

### Analysis Types

**FMEA (Failure Mode and Effects Analysis)**
- Bottom-up analysis: component failure → system effect
- Identifies single-point and latent faults
- Calculates diagnostic coverage
- Required for all ASIL levels

**FTA (Fault Tree Analysis)**
- Top-down analysis: hazardous event → contributing faults
- Quantifies failure probability
- Validates ASIL decomposition
- Mandatory for ASIL C/D

**FMEDA (Failure Modes, Effects, and Diagnostic Analysis)**
- Extension of FMEA with quantitative metrics
- Calculates PMHF (Probabilistic Metric for random Hardware Failures)
- Determines SPFM and LFM
- Required for ASIL B/C/D hardware

## FMEA Methodology

### FMEA Process Flow

```
┌──────────────────────────┐
│ 1. Define System         │
│    Boundaries            │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ 2. Identify Components   │
│    and Functions         │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ 3. Identify Failure      │
│    Modes                 │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ 4. Analyze Effects       │
│    (Local/System/End)    │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ 5. Classify Faults       │
│    (SPF/RF/LF)           │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ 6. Define Safety         │
│    Mechanisms            │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ 7. Calculate Diagnostic  │
│    Coverage (DC)         │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ 8. Verify Metrics        │
│    (SPFM/LFM/PMHF)       │
└──────────────────────────┘
```

### Fault Classifications

**Single-Point Fault (SPF)**
- Fault that directly leads to violation of safety goal
- No safety mechanism provides detection
- Must be minimized (SPFM > 99% for ASIL-D)

**Residual Fault (RF)**
- Fault detected by safety mechanism but coverage < 100%
- Contributes to PMHF calculation
- Example: CRC detects 99.998% of errors → 0.002% residual

**Latent Fault (LF)**
- Multi-point fault: not detected immediately
- Only becomes hazardous in combination with another fault
- Must be detected before second fault occurs (LFM > 90% for ASIL-D)

**Safe Fault (SF)**
- Fault detected with high coverage (> 99%)
- Transition to safe state within FTTI
- Does not contribute to PMHF

### FMEA Worksheet Template

```yaml
fmea_id: "FMEA-ESC-HW-001"
system: "Electronic Stability Control"
subsystem: "ESC ECU Hardware"
asil: "ASIL-D"
analyst: "HW Safety Engineer"
date: "2024-03-19"
version: "1.2"

components:
  - component_id: "C001"
    component_name: "Microcontroller (MCU)"
    part_number: "TMS570LC4357"
    function: "Main processing unit for ESC algorithms"

    failure_modes:
      - fm_id: "FM-C001-001"
        failure_mode: "MCU Core 0 stuck-at-high output"
        failure_rate_fit: 50  # Failures in 10^9 hours
        failure_cause: "Transistor latch-up, ESD damage"

        effects:
          local_effect: "Core 0 outputs invalid high logic"
          subsystem_effect: "Incorrect PWM output to brake modulator"
          system_effect: "Unintended brake actuation on one wheel"
          end_effect: "Vehicle instability, potential loss of control"

        severity: "S3"  # Life-threatening
        detection_method: "Dual-core lockstep comparison"
        detection_coverage_pct: 99.9

        fault_classification:
          before_sm: "SPF"  # Single-point fault without safety mechanism
          after_sm: "SF"    # Safe fault with lockstep detection
          diagnostic_coverage: 99.9  # DC = 99.9%

        safety_mechanism:
          sm_id: "SM-ESC-001"
          description: "Dual-core lockstep with cycle-by-cycle comparison"
          detection_time_ms: 0.1  # Detection within 100 μs
          reaction: "Immediate transition to safe state"
          ftti_ms: 150

        residual_failure_rate_fit: 0.05  # 50 * (1 - 0.999) = 0.05
        lambda_spf_fit: 0.05
        lambda_rf_fit: 0.05

      - fm_id: "FM-C001-002"
        failure_mode: "MCU RAM single-bit flip (SEU)"
        failure_rate_fit: 100
        failure_cause: "Cosmic ray, alpha particle"

        effects:
          local_effect: "Corrupted data in RAM"
          subsystem_effect: "Incorrect calculation results"
          system_effect: "Wrong ESC intervention decision"
          end_effect: "Delayed or incorrect stability control"

        severity: "S2"
        detection_method: "ECC (Error Correcting Code) on RAM"
        detection_coverage_pct: 99.99

        fault_classification:
          before_sm: "SPF"
          after_sm: "SF"
          diagnostic_coverage: 99.99

        safety_mechanism:
          sm_id: "SM-ESC-002"
          description: "ECC on safety-critical RAM sections"
          detection_time_ms: 0.01
          reaction: "Correct single-bit errors, flag multi-bit errors"

        residual_failure_rate_fit: 0.01
        lambda_spf_fit: 0.01
        lambda_rf_fit: 0.01

      - fm_id: "FM-C001-003"
        failure_mode: "MCU clock frequency drift"
        failure_rate_fit: 20
        failure_cause: "Oscillator aging, temperature stress"

        effects:
          local_effect: "Incorrect timing of operations"
          subsystem_effect: "ESC algorithm timing violated"
          system_effect: "Delayed ESC response (> 100 ms)"
          end_effect: "Reduced effectiveness of stability control"

        severity: "S2"
        detection_method: "External watchdog with window timing"
        detection_coverage_pct: 95.0

        fault_classification:
          before_sm: "SPF"
          after_sm: "RF"  # Residual fault (95% coverage)
          diagnostic_coverage: 95.0

        safety_mechanism:
          sm_id: "SM-ESC-003"
          description: "Window watchdog monitors timing"
          detection_time_ms: 50
          reaction: "Safe state transition if timing violated"

        residual_failure_rate_fit: 1.0  # 20 * (1 - 0.95) = 1.0
        lambda_spf_fit: 0
        lambda_rf_fit: 1.0

  - component_id: "C002"
    component_name: "Wheel Speed Sensor (Front Left)"
    part_number: "ABS-SENSOR-FL"
    function: "Measure front-left wheel rotational speed"

    failure_modes:
      - fm_id: "FM-C002-001"
        failure_mode: "Sensor output stuck-at-zero"
        failure_rate_fit: 150
        failure_cause: "Wiring short-to-ground, sensor damage"

        effects:
          local_effect: "Constant zero speed output"
          subsystem_effect: "ESC detects wheel as stationary"
          system_effect: "Incorrect vehicle dynamics calculation"
          end_effect: "ESC may fail to intervene when needed"

        severity: "S3"
        detection_method: "Plausibility check vs other wheel speeds"
        detection_coverage_pct: 90.0

        fault_classification:
          before_sm: "LF"  # Latent fault (multi-point failure)
          after_sm: "LF"   # Still latent but detected
          diagnostic_coverage: 90.0

        safety_mechanism:
          sm_id: "SM-ESC-004"
          description: "Cross-check wheel speeds for consistency"
          detection_time_ms: 200
          reaction: "Flag sensor as faulty, use 3-wheel calculation"

        residual_failure_rate_fit: 15.0  # 150 * (1 - 0.90) = 15.0
        lambda_lf_fit: 135.0  # 150 * 0.90 (detected latent)
        lambda_rf_fit: 15.0

metrics:
  total_failure_rate_fit: 320  # Sum of all component failure rates

  spf_metric:
    lambda_spf_total: 0.06  # Sum of all SPF contributions after SM
    lambda_total: 320
    spfm_percent: 99.98  # (1 - 0.06/320) * 100 = 99.98%
    target_asil_d: 99.0
    status: "PASS"

  lf_metric:
    lambda_lf_detected: 135.0
    lambda_lf_total: 150.0
    lfm_percent: 90.0  # (135/150) * 100 = 90.0%
    target_asil_d: 90.0
    status: "PASS"

  pmhf:
    lambda_spf: 0.06
    lambda_rf: 16.06
    pmhf_fit: 16.12  # SPF + RF = 0.06 + 16.06
    target_asil_d_fit: 10.0
    status: "FAIL - Requires design improvement"

conclusions:
  - SPFM meets ASIL-D target (99.98% > 99%)
  - LFM meets ASIL-D target (90.0% >= 90%)
  - PMHF exceeds ASIL-D target (16.12 > 10 FIT)
  - Recommendation: Improve sensor redundancy or diagnostic coverage

actions:
  - action_id: "ACT-001"
    description: "Add redundant wheel speed sensor (1oo2 configuration)"
    responsible: "HW Design Team"
    due_date: "2024-04-30"
    expected_pmhf_reduction: "50%"
```

## FTA Methodology

### Fault Tree Symbols

```
┌─────────────────────────────────────────┐
│ Event Symbols                           │
├─────────────────────────────────────────┤
│  ◯  Basic Event (failure)               │
│  □  Intermediate Event                  │
│  ◇  Undeveloped Event                   │
│  ⬡  External Event                      │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Gate Symbols                            │
├─────────────────────────────────────────┤
│  ∧  AND Gate (all inputs required)      │
│  ∨  OR Gate (any input sufficient)      │
│  ⊕  XOR Gate (exclusive-or)             │
│  ≥K  K-out-of-N Gate                    │
└─────────────────────────────────────────┘
```

### FTA Example - Unintended ESC Activation

```
Top Event: Unintended ESC Activation (ASIL-D)
│
├─ OR ────────────────────────────────────┐
│                                          │
▼                                          ▼
[Spurious Brake Command]              [Sensor False Positive]
│                                          │
├─ OR ─────────────────┐                  ├─ OR ──────────────┐
│                      │                  │                   │
▼                      ▼                  ▼                   ▼
[MCU Fault]     [CAN Corruption]    [Yaw Sensor]      [Lateral Accel]
│                      │              Stuck-High       Sensor Stuck
├─ AND ───────┐        │
│             │        │
▼             ▼        ▼
[Core Fault] [Lockstep] [EMI]
◯ 50 FIT      Fails     ◯ 10 FIT
              ◯ 0.5 FIT
```

### Quantitative FTA

**Calculate Top Event Probability:**

```python
# FTA calculations
import math

# Basic event failure rates (FIT = failures in 10^9 hours)
failure_rates = {
    'mcu_core_fault': 50,
    'lockstep_failure': 0.5,
    'can_emi': 10,
    'yaw_sensor_stuck': 100,
    'lateral_accel_stuck': 80
}

# Mission time (hours)
mission_time = 10000  # 10,000 hours (typical vehicle lifetime)

# Convert FIT to probability
def fit_to_probability(fit, hours):
    """Convert FIT to probability over given hours"""
    lambda_per_hour = fit / 1e9
    return 1 - math.exp(-lambda_per_hour * hours)

# Calculate probabilities
prob = {}
for event, fit in failure_rates.items():
    prob[event] = fit_to_probability(fit, mission_time)
    print(f"{event}: {prob[event]:.6e}")

# AND gate: P(A AND B) = P(A) * P(B)
prob_mcu_undetected = prob['mcu_core_fault'] * prob['lockstep_failure']
print(f"\nMCU undetected fault: {prob_mcu_undetected:.6e}")

# OR gate: P(A OR B) = P(A) + P(B) - P(A)*P(B)
def or_gate(p1, p2):
    return p1 + p2 - (p1 * p2)

# Spurious brake command path
prob_spurious_brake = or_gate(prob_mcu_undetected, prob['can_emi'])
print(f"Spurious brake command: {prob_spurious_brake:.6e}")

# Sensor false positive path
prob_sensor_false = or_gate(prob['yaw_sensor_stuck'], prob['lateral_accel_stuck'])
print(f"Sensor false positive: {prob_sensor_false:.6e}")

# Top event
prob_top_event = or_gate(prob_spurious_brake, prob_sensor_false)
print(f"\nTop Event (Unintended ESC): {prob_top_event:.6e}")

# ASIL-D target: < 10 FIT = 1e-4 probability over 10,000 hours
asil_d_target = fit_to_probability(10, mission_time)
print(f"ASIL-D target (< 10 FIT): {asil_d_target:.6e}")

if prob_top_event < asil_d_target:
    print("✓ FTA meets ASIL-D requirement")
else:
    print("✗ FTA fails ASIL-D requirement")
    print(f"Risk reduction factor needed: {prob_top_event / asil_d_target:.1f}x")
```

### Cut Set Analysis

**Minimal Cut Sets:**

Cut sets are combinations of basic events that cause the top event.

```python
# Minimal cut sets for FTA
cut_sets = [
    ['mcu_core_fault', 'lockstep_failure'],  # AND gate
    ['can_emi'],                              # Single point
    ['yaw_sensor_stuck'],                     # Single point
    ['lateral_accel_stuck']                   # Single point
]

# Calculate cut set probabilities
print("Minimal Cut Sets:")
for i, cut_set in enumerate(cut_sets, 1):
    if len(cut_set) == 1:
        # Single-point fault
        prob_cut = prob[cut_set[0]]
        print(f"  Cut Set {i} (SPF): {cut_set} = {prob_cut:.6e}")
    else:
        # Multi-point fault (AND)
        prob_cut = 1.0
        for event in cut_set:
            prob_cut *= prob[event]
        print(f"  Cut Set {i} (AND): {cut_set} = {prob_cut:.6e}")

# Importance analysis - which events contribute most?
print("\nImportance Analysis:")
event_contributions = {}
for event in failure_rates:
    # Calculate top event probability with this event probability = 1
    test_prob = prob.copy()
    test_prob[event] = 1.0

    # Recalculate (simplified)
    if event in ['mcu_core_fault', 'lockstep_failure']:
        test_spurious = or_gate(test_prob['mcu_core_fault'] * test_prob['lockstep_failure'],
                                test_prob['can_emi'])
    else:
        test_spurious = prob_spurious_brake

    if event in ['yaw_sensor_stuck', 'lateral_accel_stuck']:
        test_sensor = or_gate(test_prob['yaw_sensor_stuck'], test_prob['lateral_accel_stuck'])
    else:
        test_sensor = prob_sensor_false

    test_top = or_gate(test_spurious, test_sensor)

    importance = test_top - prob_top_event
    event_contributions[event] = importance

# Sort by importance
sorted_events = sorted(event_contributions.items(), key=lambda x: x[1], reverse=True)
for event, importance in sorted_events:
    print(f"  {event}: {importance:.6e}")

print("\nRecommendation: Focus safety mechanisms on:", sorted_events[0][0])
```

## FMEDA Calculations

### Hardware Metrics Formulas

**1. Single-Point Fault Metric (SPFM)**

```
SPFM = (1 - (ΣλSPF / Σλ)) × 100%

Where:
  λSPF = failure rate of single-point faults (FIT)
  λ = total failure rate (FIT)

ASIL Targets:
  ASIL B: SPFM > 90%
  ASIL C: SPFM > 97%
  ASIL D: SPFM > 99%
```

**2. Latent Fault Metric (LFM)**

```
LFM = (1 - (ΣλLF,undetected / ΣλLF)) × 100%

Where:
  λLF,undetected = latent faults not detected (FIT)
  λLF = total latent fault rate (FIT)

ASIL Targets:
  ASIL B: LFM > 60%
  ASIL C: LFM > 80%
  ASIL D: LFM > 90%
```

**3. Probabilistic Metric for random Hardware Failures (PMHF)**

```
PMHF = ΣλSPF + ΣλRF

Where:
  λSPF = single-point fault rate (FIT)
  λRF = residual fault rate (FIT)

ASIL Targets (per safety goal):
  ASIL B: PMHF < 100 FIT
  ASIL C: PMHF < 100 FIT
  ASIL D: PMHF < 10 FIT

Note: 1 FIT = 1 failure in 10^9 hours
      10 FIT ≈ 1 failure per 11,400 years of operation
```

### Diagnostic Coverage Classes

| DC Class | Coverage Range | Examples |
|----------|---------------|----------|
| DC 0 | None (0%) | No diagnostic |
| DC 1 | Low (60-90%) | Plausibility checks |
| DC 2 | Medium (90-99%) | Watchdog, CRC |
| DC 3 | High (99-100%) | Dual-core lockstep, ECC |

### FMEDA Spreadsheet

```
Component: ESC ECU Microcontroller
Part Number: TMS570LC4357
ASIL: D

┌─────┬──────────────────┬──────┬──────┬──────┬────┬────┬────┬────┐
│ ID  │ Failure Mode     │  λ   │ DC%  │Class │SPF │ RF │ LF │ SF │
├─────┼──────────────────┼──────┼──────┼──────┼────┼────┼────┼────┤
│ FM1 │ Core stuck-at    │  50  │ 99.9 │ DC3  │ 0  │0.05│ 0  │49.95│
│ FM2 │ RAM bit-flip     │ 100  │ 99.99│ DC3  │ 0  │0.01│ 0  │99.99│
│ FM3 │ Clock drift      │  20  │ 95.0 │ DC2  │ 0  │ 1.0│ 0  │ 19.0│
│ FM4 │ Flash ECC fail   │  10  │ 100  │ DC3  │ 0  │ 0  │ 0  │ 10.0│
│ FM5 │ Watchdog fail    │   5  │  0   │ DC0  │ 5  │ 0  │ 0  │  0  │
│ FM6 │ ADC stuck        │  30  │ 85.0 │ DC1  │ 0  │ 4.5│ 0  │25.5 │
│ FM7 │ Power supply OV  │  15  │ 99.0 │ DC3  │ 0  │0.15│ 0  │14.85│
│ FM8 │ Temp sensor drift│  25  │ 90.0 │ DC2  │ 0  │ 2.5│ 0  │22.5 │
├─────┼──────────────────┼──────┼──────┼──────┼────┼────┼────┼────┤
│ SUM │                  │ 255  │      │      │ 5  │8.21│ 0  │241.79│
└─────┴──────────────────┴──────┴──────┴──────┴────┴────┴────┴────┘

Calculations:
  SPFM = (1 - 5/255) × 100% = 98.04%  ← FAIL (target: >99%)
  LFM = N/A (no latent faults)
  PMHF = 5 + 8.21 = 13.21 FIT  ← FAIL (target: <10 FIT)

Required Actions:
  1. Eliminate watchdog SPF (add redundant watchdog)
  2. Improve ADC diagnostic coverage (add cross-checks)
  3. Target: SPFM > 99%, PMHF < 10 FIT
```

## FMEA/FTA Integration

### Bidirectional Validation

**FMEA → FTA Validation:**

1. Each SPF in FMEA should appear as single basic event in FTA
2. Each latent fault should appear in AND gate (multi-point)
3. Safety mechanisms should reduce FTA cut set probabilities

**FTA → FMEA Validation:**

1. Each FTA basic event should have corresponding FMEA failure mode
2. FTA cut sets reveal dependent failures for DFA
3. FTA probability calculation validates PMHF

### Example Cross-Check

```python
# Validate FMEA and FTA consistency
fmea_failure_modes = {
    'mcu_core_fault': {'lambda': 50, 'dc': 99.9, 'spf': 0.05},
    'ram_bit_flip': {'lambda': 100, 'dc': 99.99, 'spf': 0.01},
    'sensor_stuck': {'lambda': 150, 'dc': 90.0, 'spf': 0}
}

fta_basic_events = {
    'mcu_core_fault': 50,
    'ram_bit_flip': 100,
    'sensor_stuck': 150
}

# Check consistency
print("FMEA/FTA Cross-Validation:")
for event in fmea_failure_modes:
    if event in fta_basic_events:
        fmea_lambda = fmea_failure_modes[event]['lambda']
        fta_lambda = fta_basic_events[event]

        if fmea_lambda == fta_lambda:
            print(f"✓ {event}: Consistent ({fmea_lambda} FIT)")
        else:
            print(f"✗ {event}: Mismatch (FMEA: {fmea_lambda}, FTA: {fta_lambda})")
    else:
        print(f"⚠ {event}: Missing in FTA")

for event in fta_basic_events:
    if event not in fmea_failure_modes:
        print(f"⚠ {event}: Missing in FMEA")
```

## Production-Ready Tools

### FMEA Database Schema (SQL)

```sql
CREATE TABLE Components (
    component_id VARCHAR(50) PRIMARY KEY,
    component_name VARCHAR(200),
    part_number VARCHAR(100),
    function TEXT,
    asil VARCHAR(10)
);

CREATE TABLE FailureModes (
    fm_id VARCHAR(50) PRIMARY KEY,
    component_id VARCHAR(50) REFERENCES Components(component_id),
    failure_mode TEXT,
    failure_rate_fit DECIMAL(10,2),
    failure_cause TEXT,
    local_effect TEXT,
    system_effect TEXT,
    end_effect TEXT,
    severity VARCHAR(2)
);

CREATE TABLE SafetyMechanisms (
    sm_id VARCHAR(50) PRIMARY KEY,
    fm_id VARCHAR(50) REFERENCES FailureModes(fm_id),
    description TEXT,
    detection_coverage_pct DECIMAL(5,2),
    detection_time_ms DECIMAL(10,2),
    reaction TEXT,
    ftti_ms DECIMAL(10,2)
);

CREATE TABLE FaultClassification (
    fc_id SERIAL PRIMARY KEY,
    fm_id VARCHAR(50) REFERENCES FailureModes(fm_id),
    before_sm VARCHAR(10),  -- SPF, RF, LF, SF
    after_sm VARCHAR(10),
    diagnostic_coverage DECIMAL(5,2),
    lambda_spf_fit DECIMAL(10,2),
    lambda_rf_fit DECIMAL(10,2),
    lambda_lf_fit DECIMAL(10,2),
    lambda_sf_fit DECIMAL(10,2)
);

-- Query: Calculate SPFM for a system
SELECT
    SUM(fc.lambda_spf_fit) AS total_spf,
    SUM(fm.failure_rate_fit) AS total_lambda,
    (1 - SUM(fc.lambda_spf_fit) / SUM(fm.failure_rate_fit)) * 100 AS spfm_percent
FROM FailureModes fm
JOIN FaultClassification fc ON fm.fm_id = fc.fm_id
WHERE fm.component_id IN (SELECT component_id FROM Components WHERE asil = 'ASIL-D');
```

### Python FMEDA Calculator

```python
#!/usr/bin/env python3
"""
ISO 26262 FMEDA Calculator
Calculates SPFM, LFM, and PMHF metrics
"""

class FMEDACalculator:
    def __init__(self, asil_level):
        self.asil_level = asil_level
        self.failure_modes = []
        self.targets = self._get_targets(asil_level)

    def _get_targets(self, asil):
        targets = {
            'ASIL-A': {'spfm': 0, 'lfm': 0, 'pmhf': 1000},
            'ASIL-B': {'spfm': 90, 'lfm': 60, 'pmhf': 100},
            'ASIL-C': {'spfm': 97, 'lfm': 80, 'pmhf': 100},
            'ASIL-D': {'spfm': 99, 'lfm': 90, 'pmhf': 10}
        }
        return targets.get(asil, targets['ASIL-D'])

    def add_failure_mode(self, name, lambda_fit, dc_percent):
        """
        Add a failure mode with diagnostic coverage
        """
        fm = {
            'name': name,
            'lambda': lambda_fit,
            'dc': dc_percent / 100.0,
            'lambda_detected': lambda_fit * (dc_percent / 100.0),
            'lambda_residual': lambda_fit * (1 - dc_percent / 100.0)
        }
        self.failure_modes.append(fm)

    def calculate_metrics(self):
        """
        Calculate SPFM, LFM, PMHF
        """
        lambda_total = sum(fm['lambda'] for fm in self.failure_modes)
        lambda_spf = sum(fm['lambda_residual'] for fm in self.failure_modes if fm['dc'] == 0)
        lambda_rf = sum(fm['lambda_residual'] for fm in self.failure_modes if 0 < fm['dc'] < 1)
        lambda_lf_detected = sum(fm['lambda_detected'] for fm in self.failure_modes)
        lambda_lf_total = lambda_total  # Simplified

        spfm = (1 - lambda_spf / lambda_total) * 100 if lambda_total > 0 else 0
        lfm = (lambda_lf_detected / lambda_lf_total) * 100 if lambda_lf_total > 0 else 0
        pmhf = lambda_spf + lambda_rf

        return {
            'spfm': spfm,
            'lfm': lfm,
            'pmhf': pmhf,
            'lambda_total': lambda_total,
            'lambda_spf': lambda_spf,
            'lambda_rf': lambda_rf
        }

    def check_compliance(self):
        """
        Check if metrics meet ASIL targets
        """
        metrics = self.calculate_metrics()

        compliance = {
            'spfm': metrics['spfm'] >= self.targets['spfm'],
            'lfm': metrics['lfm'] >= self.targets['lfm'],
            'pmhf': metrics['pmhf'] <= self.targets['pmhf']
        }

        return metrics, compliance

    def generate_report(self):
        """
        Generate compliance report
        """
        metrics, compliance = self.check_compliance()

        print(f"\n{'='*60}")
        print(f"FMEDA Report - {self.asil_level}")
        print(f"{'='*60}\n")

        print(f"{'Metric':<20} {'Value':<15} {'Target':<15} {'Status':<10}")
        print(f"{'-'*60}")

        print(f"{'SPFM':<20} {metrics['spfm']:>8.2f}% "
              f"{self.targets['spfm']:>8}% "
              f"{'PASS' if compliance['spfm'] else 'FAIL':<10}")

        print(f"{'LFM':<20} {metrics['lfm']:>8.2f}% "
              f"{self.targets['lfm']:>8}% "
              f"{'PASS' if compliance['lfm'] else 'FAIL':<10}")

        print(f"{'PMHF':<20} {metrics['pmhf']:>8.2f} FIT "
              f"{'<':>2}{self.targets['pmhf']:>5} FIT "
              f"{'PASS' if compliance['pmhf'] else 'FAIL':<10}")

        print(f"\n{'Detail':<20} {'Value':<15}")
        print(f"{'-'*35}")
        print(f"{'Total λ':<20} {metrics['lambda_total']:>8.2f} FIT")
        print(f"{'λ SPF':<20} {metrics['lambda_spf']:>8.2f} FIT")
        print(f"{'λ RF':<20} {metrics['lambda_rf']:>8.2f} FIT")

        overall = all(compliance.values())
        print(f"\n{'Overall Compliance:':<20} {'PASS' if overall else 'FAIL'}")

        return overall


# Example usage
if __name__ == "__main__":
    calc = FMEDACalculator('ASIL-D')

    # Add failure modes
    calc.add_failure_mode('MCU Core Fault', lambda_fit=50, dc_percent=99.9)
    calc.add_failure_mode('RAM Bit Flip', lambda_fit=100, dc_percent=99.99)
    calc.add_failure_mode('Clock Drift', lambda_fit=20, dc_percent=95.0)
    calc.add_failure_mode('Watchdog Fail', lambda_fit=5, dc_percent=0.0)  # SPF!
    calc.add_failure_mode('ADC Stuck', lambda_fit=30, dc_percent=85.0)

    # Generate report
    calc.generate_report()
```

## Production Checklist

- [ ] FMEA completed for all hardware/software components
- [ ] Failure modes identified at appropriate level (component/function)
- [ ] Effects analyzed at local/system/end level
- [ ] Safety mechanisms defined for all SPF/LF
- [ ] Diagnostic coverage calculated and validated
- [ ] SPFM/LFM/PMHF metrics calculated
- [ ] FTA performed for all ASIL C/D safety goals
- [ ] Cut sets identified and analyzed
- [ ] FMEA and FTA cross-validated
- [ ] Independent review completed
- [ ] Metrics meet ASIL targets

## References

- ISO 26262-5:2018 Annex D - FMEDA Method
- ISO 26262-9:2018 - ASIL-Oriented Analyses
- IEC 61025 - Fault Tree Analysis
- SAE J1739 - Potential Failure Mode and Effects Analysis (FMEA)
- AIAG/VDA FMEA Handbook

## Related Skills

- ISO 26262 Overview
- Safety Mechanisms and Patterns
- Hardware Safety Requirements
- Software Safety Requirements
- Dependent Failure Analysis (DFA)

---

## Hazard Analysis Risk Assessment

# Hazard Analysis and Risk Assessment (HARA)

Comprehensive guidance on performing ISO 26262-compliant Hazard Analysis and Risk Assessment (HARA) for automotive E/E systems, including hazard identification, situation analysis, severity/exposure/controllability classification, and ASIL determination.

## HARA Overview

### Purpose and Scope

**Objectives:**
- Identify potential hazards from malfunctioning behavior
- Assess risk level of each hazardous event
- Determine Automotive Safety Integrity Level (ASIL)
- Define safety goals to mitigate unacceptable risks

**When to Perform HARA:**
- Concept phase (Part 3 of ISO 26262)
- New vehicle/system development
- Major system modifications
- Changes to operational context
- New use cases or operational scenarios

### HARA Process Flow

```
┌────────────────────────────────┐
│   1. Item Definition           │
│   • Boundaries                 │
│   • Functions                  │
│   • Interfaces                 │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│   2. Hazard Identification     │
│   • Malfunctioning behavior    │
│   • Hazard types               │
│   • Brainstorming sessions     │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│   3. Situation Analysis        │
│   • Operating scenarios        │
│   • Driving conditions         │
│   • Vehicle states             │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│   4. Risk Classification       │
│   • Severity (S0-S3)           │
│   • Exposure (E0-E4)           │
│   • Controllability (C0-C3)    │
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│   5. ASIL Determination        │
│   • Apply ASIL table           │
│   • Document rationale         │
│   • Define safety goals        │
└────────────────────────────────┘
```

## Severity Classification (S)

### S0: No Injuries

**Definition:** No injuries occur

**Examples:**
- Infotainment system freeze (no impact on driving)
- Interior courtesy light failure
- Seat warmer malfunction
- Radio reception loss
- USB charging port failure

**Typical Systems:**
- Entertainment systems
- Comfort features (non-critical)
- Aesthetic lighting

### S1: Light and Moderate Injuries

**Definition:** Light and moderate injuries including at least one person with moderate injuries

**Injury Examples:**
- Whiplash
- Minor bone fractures
- Mild concussion
- Bruises and contusions
- Soft tissue injuries

**Hazard Examples:**
- Cruise control failure to disengage immediately (delay < 2s)
- Parking sensor false negative at very low speed (< 5 km/h)
- Window regulator unexpected movement during adjustment
- Seat adjuster unintended movement while parked
- HVAC blower maximum speed in hot conditions

**Typical ASIL:** QM or ASIL A (depending on E and C)

### S2: Severe and Life-Threatening Injuries

**Definition:** Severe and life-threatening injuries (survival probable) to at least one person

**Injury Examples:**
- Severe bone fractures
- Internal injuries
- Severe head trauma (but survivable)
- Multiple rib fractures
- Spinal injuries (non-fatal)

**Hazard Examples:**
- Unintended acceleration (< 50 km/h, short duration)
- Steering system increased friction/resistance
- Active suspension failure causing vehicle instability
- Lane keeping assist unintended steering intervention
- Automatic emergency braking false activation at moderate speed
- Airbag non-deployment in moderate-speed collision

**Typical ASIL:** ASIL B or C (depending on E and C)

### S3: Life-Threatening and Fatal Injuries

**Definition:** Life-threatening injuries (survival uncertain) or fatal injuries to at least one person

**Injury Examples:**
- Severe head trauma (likely fatal)
- Multiple severe internal injuries
- Severe burns
- Fatal collision impact
- Ejection from vehicle

**Hazard Examples:**
- Total brake system failure at highway speed
- Unintended full acceleration at highway speed
- Complete steering loss
- Airbag inadvertent deployment while driving
- Electronic stability control (ESC) unintended strong intervention
- Electric vehicle high-voltage shock to occupants
- Autonomous emergency steering wrong direction into oncoming traffic

**Typical ASIL:** ASIL C or D (depending on E and C)

## Exposure Classification (E)

### E0: Incredibly Unlikely

**Definition:** Operational situation occurs less than 0.1% of average operating time

**Examples:**
- Manufacturing test mode only
- Service/diagnostic mode (dealer access)
- Valet parking mode with specific conditions
- Trailer tow mode on vehicles rarely towing
- Extreme weather mode (desert/arctic) for temperate regions

**Annual Occurrence:** Less than 1 hour per year

### E1: Very Low Probability

**Definition:** 0.1% to 1% of average operating time

**Examples:**
- Parallel parking maneuvers
- Reverse gear operation
- Hill start scenarios
- Car wash mode
- Off-road driving (for on-road vehicles)
- Mountain driving with steep grades

**Annual Occurrence:** 10 to 100 hours per year

### E2: Low Probability

**Definition:** 1% to 10% of average operating time

**Examples:**
- City/urban driving
- Stop-and-go traffic
- Residential area driving
- Parking lot navigation
- School zone driving
- Weather: rain/snow conditions

**Annual Occurrence:** 100 to 1000 hours per year

### E3: Medium Probability

**Definition:** 10% to 50% of average operating time

**Examples:**
- Rural road driving
- Suburban driving
- Two-lane highways
- Curved roads
- Night driving
- Mixed traffic conditions

**Annual Occurrence:** 1000 to 5000 hours per year

### E4: High Probability

**Definition:** More than 50% of average operating time

**Examples:**
- Highway/motorway cruising
- Straight road driving
- High-speed driving (> 100 km/h)
- Daytime driving
- Normal weather conditions
- Multiple occupants in vehicle

**Annual Occurrence:** More than 5000 hours per year

**Note:** Average vehicle operation ~10,000 hours over 10-year life

## Controllability Classification (C)

### C0: Controllable in General

**Definition:** More than 99% of all drivers can act to prevent harm in at least 99% of situations

**Characteristics:**
- Very obvious to driver
- Ample time to react
- Simple corrective action
- Multiple sensory cues
- Minimal skill required

**Examples:**
- Single windshield wiper stops (one still works)
- Headlight intensity reduction (not complete failure)
- Fuel gauge inaccuracy (range warning still works)
- Seat heater temperature slightly off target
- Radio volume sudden change

**Driver Action Required:** Simple compensation, obvious detection

### C1: Simply Controllable

**Definition:** At least 99% of all drivers can act to prevent harm in at least 99% of situations

**Characteristics:**
- Easily noticeable
- Adequate time to react (> 5 seconds)
- Straightforward corrective action
- Clear sensory feedback
- Average driver skill sufficient

**Examples:**
- ABS degradation (single wheel)
- Power steering assist reduction (not loss)
- Cruise control requiring multiple attempts to cancel
- Automatic transmission delayed shift (< 2s)
- Tire pressure monitoring false warning
- Parking brake electronic release delay

**Driver Action Required:** Simple reaction, average skill level

### C2: Normally Controllable

**Definition:** At least 90% of all drivers can act to prevent harm in at least 90% of situations

**Characteristics:**
- Noticeable with attention
- Limited time to react (1-5 seconds)
- Requires skilled driver response
- May need trained reaction
- Familiar driving maneuver needed

**Examples:**
- Power steering complete loss (at speed)
- ABS complete failure (manual braking only)
- ESC degraded performance (reduced intervention)
- Traction control sporadic operation
- Engine power reduction (not total loss)
- Automatic transmission stuck in gear
- Regenerative braking unexpected increase

**Driver Action Required:** Skilled driving, immediate attention

### C3: Difficult to Control or Uncontrollable

**Definition:** Less than 90% of all drivers can act to prevent harm in less than 90% of situations

**Characteristics:**
- May not be noticeable immediately
- Very short reaction time (< 1 second)
- Requires expert driver skill
- Counterintuitive response needed
- Physical limitations (strength/reflex)
- Multiple simultaneous failures

**Examples:**
- Total brake failure (all systems)
- Steering complete lockup at highway speed
- Unintended full acceleration at highway speed
- ESC unintended strong braking intervention in curve
- Airbag inadvertent deployment while driving
- All-wheel drive unintended torque split causing spin
- Autonomous steering wrong direction at highway speed
- Suspension sudden complete collapse

**Driver Action Required:** Expert skill, may be uncontrollable

## ASIL Determination Matrix

### Complete ASIL Table

```
┌─────────┬──────────────────────────────────────────────────────────────┐
│         │                    Controllability                           │
│Severity │     C0                  C1                  C2        C3     │
├─────────┼──────────────────────────────────────────────────────────────┤
│   S1    │                                                              │
│  E4     │     QM                  QM                  QM        A      │
│  E3     │     QM                  QM                  QM        A      │
│  E2     │     QM                  QM                  QM        QM     │
│  E1     │     QM                  QM                  QM        QM     │
├─────────┼──────────────────────────────────────────────────────────────┤
│   S2    │                                                              │
│  E4     │     QM                  A                   B         C      │
│  E3     │     QM                  A                   B         C      │
│  E2     │     QM                  QM                  A         B      │
│  E1     │     QM                  QM                  QM        A      │
├─────────┼──────────────────────────────────────────────────────────────┤
│   S3    │                                                              │
│  E4     │     A                   B                   C         D      │
│  E3     │     A                   B                   C         D      │
│  E2     │     QM                  A                   B         C      │
│  E1     │     QM                  QM                  A         B      │
└─────────┴──────────────────────────────────────────────────────────────┘
```

## HARA Worksheet Template

### Electronic Stability Control (ESC) Example

```yaml
hara_id: "HARA-ESC-001"
item: "Electronic Stability Control System"
date: "2024-03-19"
version: "1.0"
analyst: "Functional Safety Team"

item_definition:
  description: "Electronic Stability Control (ESC) system that stabilizes the vehicle by applying individual wheel braking and reducing engine torque during oversteer/understeer conditions"
  boundaries:
    - ESC_ECU
    - Wheel_speed_sensors (4x)
    - Yaw_rate_sensor
    - Lateral_acceleration_sensor
    - Steering_angle_sensor
    - Hydraulic_modulator_unit
  operating_modes:
    - ESC_active_mode
    - ESC_off_mode (driver disabled)
    - ABS_only_mode (ESC degraded)
  assumptions:
    - Driver_input_available
    - Vehicle_in_motion
    - Tire_grip_conditions_normal

hazards:
  - hazard_id: "H-ESC-001"
    malfunctioning_behavior: "Unintended ESC activation"
    description: "ESC applies asymmetric braking when not needed"

    hazardous_events:
      - event_id: "HE-ESC-001-A"
        situation: "Highway driving in straight line at high speed"
        operational_situation:
          - Vehicle_speed: "> 100 km/h"
          - Road_condition: "Dry, straight highway"
          - Traffic: "Dense traffic, nearby vehicles"
          - Driver_activity: "Cruising, minimal steering input"

        severity: "S3"
        severity_rationale: |
          Unintended braking at one wheel at highway speed causes sudden
          vehicle rotation. Driver and passengers face life-threatening
          injuries from:
          - Loss of control leading to collision with barriers
          - Vehicle rollover potential
          - Rear-end collision from following vehicles

        exposure: "E4"
        exposure_rationale: |
          Highway driving accounts for > 50% of vehicle operating time for
          typical usage. Straight-line cruising is the primary highway mode.
          Estimated exposure: 60% of total driving time.

        controllability: "C3"
        controllability_rationale: |
          At high speed (> 100 km/h), sudden asymmetric braking creates:
          - Immediate yaw rotation (< 500ms to loss of control)
          - Counterintuitive response needed (accelerate to regain control)
          - Physical limitation (steering correction requires high torque)
          - < 90% of drivers can successfully recover
          - Professional driver training required for recovery

        asil: "ASIL-D"

        safety_goal:
          sg_id: "SG-ESC-001"
          description: "Prevent unintended ESC activation"
          safe_state: "ESC disabled, manual control"
          ftti: "150 ms"
          verification:
            - Fault_injection_testing
            - Vehicle_dynamics_simulation
            - Proving_ground_testing

      - event_id: "HE-ESC-001-B"
        situation: "Low-speed parking maneuver"
        operational_situation:
          - Vehicle_speed: "< 10 km/h"
          - Location: "Parking lot"
          - Maneuver: "Tight turn, sharp steering"

        severity: "S1"
        severity_rationale: |
          At low speed, unintended braking causes minor vehicle movement.
          Potential for light injuries from sudden stop (whiplash).
          Low collision energy.

        exposure: "E1"
        exposure_rationale: |
          Parking maneuvers occur < 1% of operating time.
          Estimated: 50 hours per year.

        controllability: "C1"
        controllability_rationale: |
          Low speed provides ample reaction time.
          Simple corrective action: release accelerator, re-apply carefully.
          99% of drivers can handle this situation.

        asil: "QM"

        safety_goal:
          sg_id: "None (QM)"
          description: "Managed through quality management"

  - hazard_id: "H-ESC-002"
    malfunctioning_behavior: "ESC failure to activate"
    description: "ESC does not intervene when vehicle is losing stability"

    hazardous_events:
      - event_id: "HE-ESC-002-A"
        situation: "Cornering on wet highway exit ramp"
        operational_situation:
          - Vehicle_speed: "70 km/h"
          - Road_condition: "Wet, curved ramp (radius 50m)"
          - Weather: "Rain, reduced tire grip"
          - Lateral_acceleration: "> 0.7g"

        severity: "S3"
        severity_rationale: |
          Without ESC intervention, vehicle enters uncontrolled oversteer:
          - Spin into barrier or oncoming traffic
          - Rollover potential for SUVs
          - Life-threatening collision likely

        exposure: "E3"
        exposure_rationale: |
          Highway exit ramps used in 10-50% of trips.
          Wet conditions occur 15-20% of driving time.
          Combined exposure: ~20% of operating time.

        controllability: "C2"
        controllability_rationale: |
          Skilled driver can recover from initial oversteer:
          - Counter-steer + throttle modulation
          - Requires advanced car control knowledge
          - 90% of drivers can recover if trained
          - However, typical driver (no training) success rate < 70%
          - Conservative assessment: C2

        asil: "ASIL-C"

        safety_goal:
          sg_id: "SG-ESC-002"
          description: "ESC shall activate when vehicle stability is compromised"
          safe_state: "N/A (function must remain available)"
          ftti: "50 ms"
          verification:
            - Skidpad_testing
            - Wet_handling_course
            - Professional_driver_evaluation

  - hazard_id: "H-ESC-003"
    malfunctioning_behavior: "Delayed ESC response"
    description: "ESC intervention delayed by > 500ms"

    hazardous_events:
      - event_id: "HE-ESC-003-A"
        situation: "Emergency lane change at highway speed"
        operational_situation:
          - Vehicle_speed: "120 km/h"
          - Maneuver: "Double lane change (obstacle avoidance)"
          - Road_condition: "Dry highway"

        severity: "S2"
        severity_rationale: |
          Delayed ESC allows vehicle to exceed stability limits before
          intervention. Results in:
          - Severe over-rotation
          - Adjacent lane encroachment
          - Severe injuries probable, but typically survivable

        exposure: "E2"
        exposure_rationale: |
          Emergency maneuvers occur infrequently: 1-10% of operating time.
          Estimate: 200 hours per year across all driving.

        controllability: "C2"
        controllability_rationale: |
          Delayed ESC reduces effectiveness but some correction provided.
          Skilled driver can compensate with reduced ESC authority.
          ~85% success rate with trained drivers.

        asil: "ASIL-B"

        safety_goal:
          sg_id: "SG-ESC-003"
          description: "ESC response time shall be < 100ms from instability detection"
          safe_state: "Graceful degradation to ABS-only"
          ftti: "100 ms"
          verification:
            - Real-time_latency_measurement
            - HIL_testing_with_vehicle_dynamics_model

summary:
  total_hazards: 3
  total_hazardous_events: 5
  asil_distribution:
    asil_d: 1
    asil_c: 1
    asil_b: 1
    asil_a: 0
    qm: 2
  highest_asil: "ASIL-D"
  safety_goals_required: 3
```

## Advanced HARA Techniques

### Situation Analysis Matrix

**Multi-Dimensional Situation Space:**

```
Dimension 1: Vehicle Speed
├── 0-10 km/h (parking)
├── 10-50 km/h (urban)
├── 50-100 km/h (rural)
└── > 100 km/h (highway)

Dimension 2: Road Conditions
├── Dry
├── Wet
├── Snow/Ice
└── Off-road

Dimension 3: Traffic Density
├── No traffic
├── Light traffic
├── Dense traffic
└── Traffic jam

Dimension 4: Driver State
├── Attentive
├── Distracted
├── Drowsy
└── Impaired (medical emergency)

Dimension 5: Time of Day
├── Day (good visibility)
├── Dusk/dawn (reduced visibility)
└── Night (limited visibility)
```

**Coverage Matrix Example:**
```
Speed vs Road Conditions:

         │ Dry │ Wet │Snow │ Ice │
─────────┼─────┼─────┼─────┼─────┤
0-10km/h │  ✓  │  ✓  │  ✓  │  ✓  │
10-50    │  ✓  │  ✓  │  ✓  │  ✓  │
50-100   │  ✓  │  ✓  │  ✓  │  -  │
>100km/h │  ✓  │  ✓  │  -  │  -  │

✓ = Situation analyzed
- = Situation not applicable (speed limits)
```

### Controllability Assessment Methods

**Method 1: Expert Judgment**
- Panel of experienced drivers
- Simulator testing with representative population
- Statistical analysis of crash avoidance rates

**Method 2: Accident Statistics**
- Historical crash data analysis
- Similar malfunction scenarios
- Injury severity correlation

**Method 3: Simulator Studies**
```python
# Controllability test protocol
test_setup = {
    'participants': 100,  # Diverse driver population
    'age_range': (18, 75),
    'experience_range': (1, 50),  # years driving
    'scenarios': 20,  # per hazardous event
    'success_criteria': 'No collision AND vehicle stable'
}

# Classification
if success_rate > 0.99:
    controllability = "C0"
elif success_rate >= 0.99:
    controllability = "C1"
elif success_rate >= 0.90:
    controllability = "C2"
else:
    controllability = "C3"
```

### Exposure Data Collection

**Data Sources:**
1. **Naturalistic Driving Studies**
   - Real-world driving data
   - GPS logging
   - CAN bus data collection
   - 100+ vehicles over 1+ years

2. **Fleet Telemetry**
   - Connected vehicle data
   - Aggregate usage patterns
   - Scenario frequency statistics

3. **Statistical Databases**
   - NHTSA (US)
   - GIDAS (Germany)
   - STATS19 (UK)

**Exposure Calculation Example:**
```python
# Calculate exposure for "highway driving > 100 km/h"
def calculate_exposure(telemetry_data):
    total_hours = sum(trip.duration for trip in telemetry_data)
    highway_hours = sum(
        trip.duration
        for trip in telemetry_data
        if trip.speed > 100 and trip.road_type == 'highway'
    )

    exposure_percentage = (highway_hours / total_hours) * 100

    # Map to E-class
    if exposure_percentage < 0.1:
        return "E0"
    elif exposure_percentage < 1:
        return "E1"
    elif exposure_percentage < 10:
        return "E2"
    elif exposure_percentage < 50:
        return "E3"
    else:
        return "E4"

# Example data
telemetry = [
    {'duration': 120, 'speed': 110, 'road_type': 'highway'},  # 2 hours
    {'duration': 30, 'speed': 40, 'road_type': 'urban'},      # 0.5 hours
    {'duration': 50, 'speed': 80, 'road_type': 'rural'},      # 0.83 hours
    # ... 1000s more trips
]

exposure_class = calculate_exposure(telemetry)
```

## HARA Documentation

### Safety Case Integration

```markdown
# Safety Case Section: HARA Evidence

## 1. Completeness Argument

**Claim:** All relevant hazards have been identified for the ESC system.

**Evidence:**
- E1: HARA workshop with cross-functional team (attendees: safety engineer,
      system engineer, test engineer, domain expert)
- E2: Review of similar system hazards from database (23 ESC systems analyzed)
- E3: Historical accident data review (GIDAS database, 1000+ ESC-related incidents)
- E4: FMEA results cross-checked with HARA hazard list
- E5: Independent safety assessment review confirmation

**Sub-Claim 1.1:** Malfunction types cover all failure modes
**Sub-Claim 1.2:** Operating situations cover representative vehicle usage

## 2. Classification Accuracy Argument

**Claim:** Severity, Exposure, and Controllability classifications are justified.

**Evidence:**
- E6: Severity based on MAIS (Maximum Abbreviated Injury Scale) correlation
- E7: Exposure derived from 500-vehicle naturalistic driving study (12 months)
- E8: Controllability validated through driving simulator study (N=120 drivers)
- E9: Expert panel review of all classifications (unanimous agreement)

## 3. ASIL Determination Argument

**Claim:** ASIL assignments correctly follow ISO 26262-3 table.

**Evidence:**
- E10: ASIL determination matrix applied consistently to all hazardous events
- E11: Independent verification of ASIL assignments (0 discrepancies)
- E12: Traceability from S/E/C to ASIL documented in HARA database
```

### Review Checklist

**HARA Quality Review:**

- [ ] Item definition complete and approved
- [ ] All operating modes considered
- [ ] Hazards derived from malfunctioning behavior (not internal faults)
- [ ] Operational situations representative and complete
- [ ] Severity classification justified with injury mechanism
- [ ] Exposure based on quantitative data (not assumptions)
- [ ] Controllability assessed with driver population consideration
- [ ] ASIL determination traceable to S/E/C
- [ ] Safety goals defined for all ASIL hazards
- [ ] Safe state specified for each safety goal
- [ ] FTTI specified and justified
- [ ] Cross-check with FMEA/FTA performed
- [ ] Independent review completed
- [ ] All findings from reviews addressed
- [ ] HARA approved by functional safety manager

## Production-Ready Templates

### HARA Database Schema (SQL)

```sql
-- Items table
CREATE TABLE Items (
    item_id VARCHAR(50) PRIMARY KEY,
    item_name VARCHAR(200),
    description TEXT,
    version VARCHAR(20),
    status VARCHAR(20),
    created_date DATE,
    updated_date DATE
);

-- Hazards table
CREATE TABLE Hazards (
    hazard_id VARCHAR(50) PRIMARY KEY,
    item_id VARCHAR(50) REFERENCES Items(item_id),
    malfunctioning_behavior TEXT,
    description TEXT,
    identified_by VARCHAR(100),
    identified_date DATE
);

-- Hazardous Events table
CREATE TABLE HazardousEvents (
    event_id VARCHAR(50) PRIMARY KEY,
    hazard_id VARCHAR(50) REFERENCES Hazards(hazard_id),
    situation_description TEXT,
    operational_situation JSONB,
    severity VARCHAR(2),
    severity_rationale TEXT,
    exposure VARCHAR(2),
    exposure_rationale TEXT,
    controllability VARCHAR(2),
    controllability_rationale TEXT,
    asil VARCHAR(6),
    review_status VARCHAR(20),
    reviewer VARCHAR(100),
    review_date DATE
);

-- Safety Goals table
CREATE TABLE SafetyGoals (
    sg_id VARCHAR(50) PRIMARY KEY,
    event_id VARCHAR(50) REFERENCES HazardousEvents(event_id),
    description TEXT,
    safe_state TEXT,
    ftti_ms INT,
    asil VARCHAR(6),
    status VARCHAR(20),
    approved_by VARCHAR(100),
    approved_date DATE
);

-- Exposure Data table (for evidence)
CREATE TABLE ExposureData (
    data_id SERIAL PRIMARY KEY,
    event_id VARCHAR(50) REFERENCES HazardousEvents(event_id),
    data_source VARCHAR(200),
    measurement_value DECIMAL,
    measurement_unit VARCHAR(50),
    collection_date DATE,
    sample_size INT,
    notes TEXT
);

-- Query: Generate HARA report for ASIL-D events
SELECT
    h.hazard_id,
    h.malfunctioning_behavior,
    he.event_id,
    he.situation_description,
    he.severity,
    he.exposure,
    he.controllability,
    he.asil,
    sg.description AS safety_goal,
    sg.ftti_ms
FROM Hazards h
JOIN HazardousEvents he ON h.hazard_id = he.hazard_id
JOIN SafetyGoals sg ON he.event_id = sg.event_id
WHERE he.asil = 'ASIL-D'
ORDER BY h.hazard_id;
```

### Excel HARA Template

```
Sheet 1: Item Definition
├── A: Item ID
├── B: Item Name
├── C: Description
├── D: Boundaries
├── E: Operating Modes
└── F: Assumptions

Sheet 2: HARA Worksheet
├── A: Hazard ID
├── B: Malfunctioning Behavior
├── C: Hazardous Event ID
├── D: Operational Situation
├── E: Severity (dropdown: S0-S3)
├── F: Severity Rationale
├── G: Exposure (dropdown: E0-E4)
├── H: Exposure Rationale
├── I: Controllability (dropdown: C0-C3)
├── J: Controllability Rationale
├── K: ASIL (formula: =VLOOKUP(...))
└── L: Safety Goal ID

Sheet 3: ASIL Lookup Table
└── Automated ASIL determination matrix

Sheet 4: Safety Goals
├── A: Safety Goal ID
├── B: Safety Goal Description
├── C: Safe State
├── D: FTTI (ms)
└── E: Verification Methods

Sheet 5: Evidence
├── A: Event ID
├── B: Evidence Type (S/E/C)
├── C: Data Source
├── D: Reference Document
└── E: Attachment
```

## References

- ISO 26262-3:2018 - Concept Phase
- SAE J2980 - Considerations for ISO 26262 ASIL Hazard Classification
- ISO/TR 4804 - Safety and cybersecurity for automated driving systems
- GIDAS (German In-Depth Accident Study)
- NHTSA CIREN (Crash Injury Research Engineering Network)

## Related Skills

- ISO 26262 Overview
- Safety Mechanisms and Patterns
- FMEA/FTA Analysis
- Safety Verification and Validation
- Functional Safety Concept Development

---

## Iso 26262 Overview

# ISO 26262 Overview - Functional Safety in Automotive

Comprehensive guidance on ISO 26262 standard for functional safety of electrical/electronic (E/E) systems in road vehicles, covering all 12 parts, V-model lifecycle, ASIL determination, and safety concept development.

## ISO 26262 Standard Structure

### 12 Parts Overview

**Part 1: Vocabulary**
- Defines 200+ terms used throughout the standard
- Key terms: ASIL, safety goal, fault, failure, safe state, FTTI, PMHF

**Part 2: Management of Functional Safety**
- Safety lifecycle management
- Safety culture and organizational structure
- Competence management and training
- Quality management integration

**Part 3: Concept Phase**
- Item definition
- Hazard Analysis and Risk Assessment (HARA)
- Functional safety concept
- Safety goals and ASIL determination

**Part 4: Product Development at System Level**
- Technical safety concept
- System design and architecture
- Verification and validation planning
- Safety requirements allocation

**Part 5: Product Development at Hardware Level**
- Hardware safety requirements
- Hardware design and implementation
- Hardware architectural metrics
- Random hardware failures (PMHF calculation)

**Part 6: Product Development at Software Level**
- Software safety requirements
- Software architectural design
- Software unit design and implementation
- Software testing (unit, integration, system)

**Part 7: Production, Operation, Service, Decommissioning**
- Production planning and control
- Field monitoring and customer support
- Safety-related maintenance
- Decommissioning procedures

**Part 8: Supporting Processes**
- Configuration management
- Change management
- Verification methods
- Documentation standards
- Confidence in use (reuse of components)

**Part 9: ASIL-Oriented and Safety-Oriented Analyses**
- Dependent failure analysis (DFA)
- FMEA/FMEDA methodologies
- FTA (Fault Tree Analysis)
- Safety analysis methods

**Part 10: Guidelines**
- Informative guidance on applying the standard
- Examples and best practices
- Interpretation clarifications

**Part 11: Semiconductors**
- Safety requirements for semiconductor components
- Random hardware failures in ICs
- Systematic capability
- Safety manual requirements

**Part 12: Motorcycles**
- Adaptation of standard for motorcycles
- Specific hazard scenarios
- Controllability considerations for two-wheeled vehicles

## V-Model Safety Lifecycle

### Left Side (Decomposition)

```
┌─────────────────────────────────────────────┐
│         Concept Phase (Part 3)              │
│  • Item Definition                          │
│  • HARA → Safety Goals → ASIL               │
│  • Functional Safety Concept                │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│    System Design (Part 4)                   │
│  • Technical Safety Concept                 │
│  • System Architecture                      │
│  • Safety Requirements Allocation           │
└────────┬──────────────────┬─────────────────┘
         │                  │
         ▼                  ▼
┌──────────────────┐  ┌──────────────────────┐
│  HW Design       │  │  SW Design           │
│  (Part 5)        │  │  (Part 6)            │
│  • HW Safety Req │  │  • SW Safety Req     │
│  • HW Arch       │  │  • SW Arch           │
│  • HW Design     │  │  • SW Unit Design    │
└────────┬─────────┘  └──────────┬───────────┘
         │                       │
         ▼                       ▼
┌──────────────────┐  ┌──────────────────────┐
│  HW Implement    │  │  SW Implement        │
│  • PCB Design    │  │  • Coding            │
│  • Component     │  │  • Unit Testing      │
└────────┬─────────┘  └──────────┬───────────┘
         │                       │
         └───────────┬───────────┘
                     │
```

### Right Side (Integration & Verification)

```
                     │
                     ▼
┌─────────────────────────────────────────────┐
│    HW/SW Integration (Part 6)               │
│  • Integration Testing                      │
│  • Interface Verification                   │
│  • Safety Mechanism Testing                 │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│    System Integration (Part 4)              │
│  • System Testing                           │
│  • Safety Validation                        │
│  • FTTI Verification                        │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│    Vehicle Integration (Part 4)             │
│  • Vehicle-level Testing                    │
│  • Safety Goal Verification                 │
│  • Release for Production                   │
└─────────────────────────────────────────────┘
```

## ASIL Determination

### Hazard Classification Parameters

**Severity (S) - Impact of hazardous event**

| Class | Description | Example |
|-------|-------------|---------|
| S0 | No injuries | Minor annoyance (wiper malfunction) |
| S1 | Light/moderate injuries | Airbag non-deployment in low-speed collision |
| S2 | Severe/life-threatening injuries | Unintended braking at highway speed |
| S3 | Life-threatening/fatal injuries | Total brake failure at highway speed |

**Exposure (E) - Probability of operational situation**

| Class | Description | Probability | Example |
|-------|-------------|-------------|---------|
| E0 | Incredibly unlikely | < 0.1% of operating time | Test mode only |
| E1 | Very low probability | 0.1% to 1% | Parking maneuvers |
| E2 | Low probability | 1% to 10% | City driving |
| E3 | Medium probability | 10% to 50% | Rural roads |
| E4 | High probability | > 50% | Highway cruising |

**Controllability (C) - Driver's ability to avoid harm**

| Class | Description | Driver Action | Example |
|-------|-------------|---------------|---------|
| C0 | Controllable in general | Simple avoidance | Single wiper inoperative |
| C1 | Simply controllable | 99% can avoid | ABS degradation (one wheel) |
| C2 | Normally controllable | 90% can avoid | Power steering assist loss |
| C3 | Difficult/uncontrollable | < 90% can avoid | Total brake failure |

### ASIL Determination Table

```
Severity │  Exposure    Controllability
    S    │  E4 E3 E2 E1 │  C1    C2    C3
─────────┼──────────────┼────────────────────
   S1    │  A  A  QM QM │  QM    QM    A
   S2    │  B  B  A  A  │  A     B     C
   S3    │  C  C  B  B  │  B     C     D
```

Legend:
- **QM**: Quality Management only (no ASIL required)
- **ASIL A**: Lowest safety integrity
- **ASIL B**: Medium-low safety integrity
- **ASIL C**: Medium-high safety integrity
- **ASIL D**: Highest safety integrity

### ASIL Requirements Summary

| Aspect | ASIL QM | ASIL A | ASIL B | ASIL C | ASIL D |
|--------|---------|--------|--------|--------|--------|
| Software Unit Testing | Recommended | + (some coverage) | ++ (branch coverage) | +++ (MC/DC) | +++ (MC/DC + boundary) |
| Static Code Analysis | Optional | + | ++ | +++ | +++ |
| Code Reviews | Basic | + | ++ | +++ | +++ |
| FMEA | Optional | + | ++ | +++ | +++ |
| FTA | Not required | Optional | + | ++ | +++ |
| Hardware Diagnostic Coverage | None | > 60% | > 80% | > 90% | > 99% |
| PMHF Target | N/A | < 1000 FIT | < 100 FIT | < 100 FIT | < 10 FIT |

## Safety Goal Development

### Item Definition Template

```yaml
item_name: "Electronic Stability Control (ESC)"
item_id: "ESC-001"
boundaries:
  physical:
    - ECU_ESC_main
    - Wheel_speed_sensors x4
    - Steering_angle_sensor
    - Yaw_rate_sensor
    - Lateral_acceleration_sensor
    - Hydraulic_modulator
  functional:
    - Vehicle_dynamics_control
    - Brake_pressure_modulation
    - Engine_torque_reduction
  interfaces:
    - CAN_powertrain (500 kbps)
    - CAN_chassis (500 kbps)
    - LIN_sensors (19.2 kbps)
    - Brake_pressure_lines (hydraulic)
assumptions:
  - Tire_grip_coefficient > 0.3
  - Sensor_supply_voltage: 5V ± 0.25V
  - Operating_temperature: -40°C to +85°C
  - Vehicle_speed: 0 to 200 km/h
dependencies:
  - ABS_system (provides wheel speed data)
  - Engine_control (accepts torque reduction commands)
  - Brake_system (hydraulic pressure supply)
```

### Safety Goal Template

```yaml
safety_goal_id: "SG-ESC-001"
item: "ESC-001"
hazard: "Unintended ESC activation causing loss of vehicle control"
hazardous_event: "ESC applies asymmetric braking while cornering at highway speed"
asil: "ASIL-D"
asil_derivation:
  severity: "S3"  # Life-threatening
  exposure: "E4"  # Highway driving > 50% of time
  controllability: "C3"  # Difficult to control at high speed
safety_state: "ESC_disabled_safe_mode"
ftti: "150 ms"  # Fault Tolerant Time Interval
safe_state_description: |
  ESC system transitions to disabled state where:
  - No brake pressure modulation occurs
  - Driver has full manual braking control
  - Warning lamp illuminated
  - DTC stored for service
  - Base ABS functionality maintained
verification_criteria:
  - No_unintended_ESC_activation_in_1000_test_runs
  - FTTI_verified_through_fault_injection
  - Safe_state_reached_within_150ms
  - Warning_lamp_activation_confirmed
```

## Functional Safety Concept

### Safety Requirements Allocation

**Functional Safety Requirement (FSR) Example:**

```yaml
fsr_id: "FSR-ESC-001.1"
safety_goal: "SG-ESC-001"
description: "Detect yaw rate sensor plausibility failure"
rationale: "Invalid yaw rate data can cause false ESC activation"
allocation: "System-level (ESC ECU)"
asil: "ASIL-D"
verification_method:
  - Software_unit_test
  - Hardware-in-loop (HIL) test
  - Fault_injection_test
safety_mechanism: "SM-ESC-YAW-001 (Yaw rate plausibility check)"
```

**Safety Mechanism Types:**

1. **Detection**: Identify faults
   - Range checks
   - Plausibility checks
   - Watchdogs
   - CRC/checksum

2. **Control**: Transition to safe state
   - Redundant channels
   - Voting mechanisms
   - Graceful degradation
   - Fail-silent/fail-operational

3. **Warning**: Alert driver/system
   - Warning lamps
   - Acoustic signals
   - Haptic feedback
   - DTC logging

## Technical Safety Concept

### Safety Architecture Patterns

**1. Homogeneous Redundancy (1oo2)**
```
Sensor A ──┐
           ├──> Voter ──> Actuator
Sensor B ──┘
```
- Identical sensors
- ASIL-B each → ASIL-D combined
- Common cause failure analysis required

**2. Heterogeneous Redundancy**
```
Radar ────┐
          ├──> Fusion ──> Decision
Camera ───┘
```
- Different physical principles
- Better independence
- ASIL decomposition possible

**3. Monitoring Architecture (1oo1D)**
```
Main Channel ────────> Actuator
                        ^
                        │
                    Monitor
```
- Main channel + diagnostic coverage
- ASIL decomposition: ASIL-D(D) → ASIL-B(D) + ASIL-A(D)

## ASIL Decomposition

### Decomposition Rules

**Valid ASIL-D Decomposition:**
- ASIL-D(D) = ASIL-C(D) + ASIL-A(D)
- ASIL-D(D) = ASIL-B(D) + ASIL-B(D)
- ASIL-D(D) = ASIL-B(D) + ASIL-A(D) [with additional safety mechanisms]

**Requirements:**
1. Elements must be sufficiently independent
2. Both elements monitored for failures
3. Dependent failures analyzed (DFA)
4. Common cause failures addressed
5. No single point of failure

**Example - Brake-by-Wire ASIL-D Decomposition:**

```yaml
safety_requirement: "Brake_command_processing"
original_asil: "ASIL-D(D)"
decomposition:
  element_1:
    function: "Primary_brake_command_path"
    asil: "ASIL-B(D)"
    implementation: "Microcontroller_core_0"
    safety_mechanisms:
      - Program_flow_monitoring
      - RAM_test
      - CRC_on_commands
  element_2:
    function: "Secondary_brake_command_path"
    asil: "ASIL-B(D)"
    implementation: "Microcontroller_core_1"
    safety_mechanisms:
      - Dual_core_lockstep
      - Cross_comparison
      - Watchdog
independence_measures:
  - Separate_memory_partitions
  - Separate_power_supplies
  - Different_code_implementations
  - Independent_watchdogs
dependent_failure_analysis:
  - EMI_susceptibility_analyzed
  - Common_power_rail_protected
  - Temperature_effects_mitigated
```

## Safety Validation

### Validation Methods by ASIL

| Method | ASIL A | ASIL B | ASIL C | ASIL D |
|--------|--------|--------|--------|--------|
| Requirements review | + | ++ | ++ | +++ |
| Design review | + | ++ | +++ | +++ |
| Simulation testing | + | ++ | +++ | +++ |
| Prototype testing | ++ | +++ | +++ | +++ |
| Field testing | ++ | +++ | +++ | +++ |
| Fault injection | Optional | + | ++ | +++ |
| Back-to-back comparison | Optional | + | ++ | +++ |

### Safety Case Structure

```
Safety Case Document
├── 1. Item Definition
│   ├── System boundaries
│   ├── Assumptions
│   └── Dependencies
├── 2. Hazard Analysis (HARA)
│   ├── Hazard identification
│   ├── Risk assessment (S, E, C)
│   └── ASIL determination
├── 3. Safety Goals
│   ├── Safety goal definition
│   ├── Safe state definition
│   └── FTTI specification
├── 4. Functional Safety Concept
│   ├── Functional safety requirements
│   ├── Safety mechanisms
│   └── Requirement allocation
├── 5. Technical Safety Concept
│   ├── Safety architecture
│   ├── Technical safety requirements
│   └── HW/SW allocation
├── 6. Safety Analysis
│   ├── FMEA/FMEDA results
│   ├── FTA results
│   ├── DFA results
│   └── PMHF calculation
├── 7. Verification Evidence
│   ├── Test results
│   ├── Review records
│   └── Analysis reports
├── 8. Validation Evidence
│   ├── Safety goal verification
│   ├── FTTI verification
│   └── Field data
└── 9. Confirmation Measures
    ├── Functional safety audit
    ├── Independent assessment
    └── Confirmation review
```

## Key Metrics and Targets

### Hardware Metrics

**Single-Point Fault Metric (SPFM)**
```
SPFM = (1 - ΣλSPF / ΣλTotal) × 100%

Target:
- ASIL B: > 90%
- ASIL C: > 97%
- ASIL D: > 99%
```

**Latent Fault Metric (LFM)**
```
LFM = (1 - ΣλLF / (ΣλLF + ΣλRF + ΣλDet)) × 100%

Target:
- ASIL B: > 60%
- ASIL C: > 80%
- ASIL D: > 90%
```

**Probabilistic Metric for random Hardware Failures (PMHF)**
```
PMHF = Σ(λi × failure_rate) FIT

Target:
- ASIL B: < 100 FIT
- ASIL C: < 100 FIT
- ASIL D: < 10 FIT

FIT = Failures In Time (1 FIT = 1 failure in 10⁹ hours)
```

### Software Metrics

**MC/DC Coverage (Modified Condition/Decision Coverage)**
- ASIL D requirement: 100% MC/DC coverage
- Critical software units only
- Tool qualification required

**Cyclomatic Complexity**
- ASIL D recommendation: < 10 per function
- Rationale: Testability and maintainability

## ISO 26262:2018 Updates

### Changes from 2011 Edition

1. **Semicond uctors** (New Part 11)
   - Specific requirements for IC suppliers
   - Safety Element out of Context (SEooC)
   - Systematic capability determination

2. **Motorcycles** (New Part 12)
   - Adapted controllability classes
   - Motorcycle-specific hazards
   - Two-wheeler dynamics considerations

3. **SOTIF Integration** (ISO 21448)
   - Performance limitations
   - Reasonably foreseeable misuse
   - Validation of non-fault scenarios

4. **Cybersecurity** (ISO 21434)
   - Security interface with safety
   - Threat analysis
   - Secure development lifecycle

5. **Agile Development**
   - Guidance on iterative methods
   - Sprint-based V-model
   - Continuous integration considerations

## Production Checklist

### Phase Gate Criteria

**Concept Phase Exit:**
- [ ] Item definition approved
- [ ] HARA completed and reviewed
- [ ] Safety goals confirmed with ASIL
- [ ] Functional safety concept defined
- [ ] Safety plan approved

**System Development Exit:**
- [ ] Technical safety concept complete
- [ ] System architecture defined
- [ ] Safety requirements allocated to HW/SW
- [ ] Verification plan approved
- [ ] Preliminary FMEA conducted

**HW/SW Development Exit:**
- [ ] Detailed design complete
- [ ] Implementation verified (unit tests)
- [ ] Integration testing passed
- [ ] Safety mechanisms validated
- [ ] Code/design reviews complete

**Integration Exit:**
- [ ] System integration testing complete
- [ ] Safety validation performed
- [ ] FTTI verified through testing
- [ ] Hardware metrics achieved (SPFM, LFM, PMHF)
- [ ] Functional safety assessment passed

**Production Release:**
- [ ] Safety case complete
- [ ] Independent safety assessment passed
- [ ] Safety manual released
- [ ] Production quality procedures established
- [ ] Field monitoring plan in place

## Tools and Compliance

### Tool Qualification (ISO 26262-8)

**Tool Confidence Levels (TCL)**

| TCL | Tool Impact | Examples |
|-----|-------------|----------|
| TCL1 | No impact on safety | Documentation editors |
| TCL2 | Can introduce errors | Compilers without verification |
| TCL3 | High risk of undetected errors | Code generators, static analyzers |

**Qualification Methods:**
1. Increased confidence from use
2. Validation of tool outputs
3. Development per recognized standard
4. Evaluation of tool development process

### Recommended Tools

**ASIL-D Qualified:**
- MATLAB/Simulink (with IEC Certification Kit)
- SCADE Suite (qualified per ISO 26262)
- TargetLink (qualified code generator)
- Polyspace (static analyzer)
- LDRA (unit test + coverage)
- Vector CANoe/CANalyzer (HIL testing)

## References

- ISO 26262-1:2018 to ISO 26262-12:2018 (full standard)
- ISO/PAS 21448:2019 (SOTIF - Safety of the Intended Functionality)
- ISO/SAE 21434:2021 (Cybersecurity for road vehicles)
- ASPICE 3.1 (Automotive SPICE)
- MISRA C:2012 / MISRA C++:2008 (coding guidelines)
- SEooC (Safety Element out of Context) guidelines

## Related Skills

- Hazard Analysis and Risk Assessment (HARA)
- Safety Mechanisms and Patterns
- FMEA/FTA Analysis
- Software Safety Requirements
- Safety Verification and Validation

---

## Safety Mechanisms Patterns

# Safety Mechanisms and Patterns for ISO 26262

Comprehensive catalog of safety mechanisms for ASIL-D automotive systems, including redundancy patterns, diagnostic coverage techniques, watchdogs, memory protection, CRC/checksums, plausibility checks, and safe state management.

## Safety Mechanism Categories

### Detection Mechanisms
- Identify faults before they cause failures
- Achieve diagnostic coverage targets
- Enable transition to safe state within FTTI

### Control Mechanisms
- Manage system behavior during faults
- Implement redundancy and voting
- Provide graceful degradation paths

### Warning Mechanisms
- Alert driver/system to faults
- Trigger DTC storage
- Activate warning lamps/signals

## Redundancy Patterns

### 1. Homogeneous Redundancy (1oo2)

**One-out-of-Two Configuration:**

```
┌──────────┐
│ Sensor A │─────┐
└──────────┘     │      ┌────────┐     ┌──────────┐
                 ├─────>│ Voter  │────>│ Actuator │
┌──────────┐     │      └────────┘     └──────────┘
│ Sensor B │─────┘
└──────────┘
```

**Characteristics:**
- Two identical channels (same design, same component)
- Any one channel can drive the system
- ASIL decomposition: ASIL-D(D) = ASIL-B(D) + ASIL-B(D)
- Requires dependent failure analysis (common cause)

**C Implementation:**
```c
// 1oo2 redundant sensor processing
typedef struct {
    float sensor_a_value;
    float sensor_b_value;
    bool sensor_a_valid;
    bool sensor_b_valid;
    uint32_t fault_counter_a;
    uint32_t fault_counter_b;
} RedundantSensor_t;

typedef enum {
    VOTER_OUTPUT_VALID,
    VOTER_OUTPUT_DEGRADED,
    VOTER_OUTPUT_FAULT
} VoterStatus_t;

VoterStatus_t ProcessRedundantSensors(
    RedundantSensor_t *sensors,
    float *output_value
) {
    const float TOLERANCE = 0.05f;  // 5% agreement tolerance
    const uint32_t FAULT_THRESHOLD = 3;

    // Range check both sensors
    if (!RangeCheck(sensors->sensor_a_value, 0.0f, 100.0f)) {
        sensors->sensor_a_valid = false;
        sensors->fault_counter_a++;
    } else {
        sensors->sensor_a_valid = true;
    }

    if (!RangeCheck(sensors->sensor_b_value, 0.0f, 100.0f)) {
        sensors->sensor_b_valid = false;
        sensors->fault_counter_b++;
    } else {
        sensors->sensor_b_valid = true;
    }

    // Both sensors valid - check agreement
    if (sensors->sensor_a_valid && sensors->sensor_b_valid) {
        float difference = fabsf(sensors->sensor_a_value - sensors->sensor_b_value);
        float average = (sensors->sensor_a_value + sensors->sensor_b_value) / 2.0f;

        if (difference / average < TOLERANCE) {
            // Sensors agree - use average
            *output_value = average;
            return VOTER_OUTPUT_VALID;
        } else {
            // Sensors disagree - both might be faulty
            // Use most conservative value
            *output_value = fmaxf(sensors->sensor_a_value, sensors->sensor_b_value);
            return VOTER_OUTPUT_DEGRADED;
        }
    }

    // Only sensor A valid
    if (sensors->sensor_a_valid && !sensors->sensor_b_valid) {
        if (sensors->fault_counter_b < FAULT_THRESHOLD) {
            *output_value = sensors->sensor_a_value;
            return VOTER_OUTPUT_DEGRADED;
        } else {
            return VOTER_OUTPUT_FAULT;
        }
    }

    // Only sensor B valid
    if (!sensors->sensor_a_valid && sensors->sensor_b_valid) {
        if (sensors->fault_counter_a < FAULT_THRESHOLD) {
            *output_value = sensors->sensor_b_value;
            return VOTER_OUTPUT_DEGRADED;
        } else {
            return VOTER_OUTPUT_FAULT;
        }
    }

    // Both sensors invalid
    return VOTER_OUTPUT_FAULT;
}
```

### 2. Heterogeneous Redundancy

**Different Physical Principles:**

```
┌────────────┐
│   Radar    │────┐
└────────────┘    │     ┌─────────┐      ┌──────────┐
                  ├────>│ Fusion  │─────>│ Decision │
┌────────────┐    │     └─────────┘      └──────────┘
│   Camera   │────┘
└────────────┘
```

**Benefits:**
- Better independence (different failure modes)
- Common cause failures less likely
- Easier ASIL decomposition justification

**Example - Vehicle Speed Estimation:**
```c
// Heterogeneous speed measurement
typedef struct {
    float wheel_speed_fl;      // Front-left wheel speed sensor
    float wheel_speed_fr;      // Front-right wheel speed sensor
    float accelerometer_speed; // Integrated from accelerometer
    float gps_speed;           // GPS-based speed
} SpeedSources_t;

float FuseSpeedMeasurements(SpeedSources_t *sources) {
    const float WHEEL_WEIGHT = 0.7f;
    const float ACCEL_WEIGHT = 0.2f;
    const float GPS_WEIGHT = 0.1f;

    // Primary: Average of wheel speeds
    float wheel_speed_avg = (sources->wheel_speed_fl + sources->wheel_speed_fr) / 2.0f;

    // Plausibility check: compare wheel speed to accelerometer
    float speed_delta = fabsf(wheel_speed_avg - sources->accelerometer_speed);

    if (speed_delta < 5.0f) {  // Within 5 km/h
        // All sources agree - weighted fusion
        float fused_speed = (wheel_speed_avg * WHEEL_WEIGHT) +
                            (sources->accelerometer_speed * ACCEL_WEIGHT) +
                            (sources->gps_speed * GPS_WEIGHT);
        return fused_speed;
    } else {
        // Potential wheel slip - rely more on accelerometer
        return sources->accelerometer_speed;
    }
}
```

### 3. Dual-Core Lockstep

**Hardware-Level Redundancy:**

```
┌──────────────┐
│   Core 0     │──┐
│ (Leading)    │  │   ┌───────────────┐
└──────────────┘  ├──>│   Comparator  │──> Fault Signal
                  │   └───────────────┘
┌──────────────┐  │
│   Core 1     │──┘
│ (Trailing)   │
└──────────────┘
```

**Characteristics:**
- Two CPU cores execute identical instructions
- Outputs compared cycle-by-cycle
- Any mismatch triggers fault reaction
- ASIL-D without software redundancy

**Lockstep Monitor (Conceptual):**
```c
// This is typically implemented in hardware, but shown for understanding
typedef struct {
    uint32_t core0_output;
    uint32_t core1_output;
    uint32_t mismatch_counter;
    bool lockstep_fault;
} LockstepMonitor_t;

void CheckLockstep(LockstepMonitor_t *monitor) {
    const uint32_t MISMATCH_THRESHOLD = 1;  // Zero tolerance for lockstep

    if (monitor->core0_output != monitor->core1_output) {
        monitor->mismatch_counter++;

        if (monitor->mismatch_counter >= MISMATCH_THRESHOLD) {
            monitor->lockstep_fault = true;
            // Trigger immediate safe state
            EnterSafeState();
            // Generate DTC
            SetDTC(DTC_LOCKSTEP_FAULT);
            // Activate warning lamp
            ActivateWarningLamp(WARNING_LAMP_ENGINE);
        }
    } else {
        // Reset counter if outputs match
        monitor->mismatch_counter = 0;
    }
}
```

### 4. 2oo3 Voting (Two-out-of-Three)

**Triple Modular Redundancy:**

```
┌──────────┐
│ Channel A│───┐
└──────────┘   │
               │    ┌────────────┐      ┌──────────┐
┌──────────┐   ├───>│ 2oo3 Voter │─────>│ Actuator │
│ Channel B│───┤    └────────────┘      └──────────┘
└──────────┘   │
               │
┌──────────┐   │
│ Channel C│───┘
└──────────┘
```

**Voter Logic:**
```c
// 2oo3 voting for critical safety function
typedef struct {
    float channel_a;
    float channel_b;
    float channel_c;
    bool channel_a_fault;
    bool channel_b_fault;
    bool channel_c_fault;
} TripleChannels_t;

bool Vote2oo3(TripleChannels_t *channels, float *output) {
    const float VOTE_TOLERANCE = 0.02f;  // 2% agreement

    int valid_count = 0;
    if (!channels->channel_a_fault) valid_count++;
    if (!channels->channel_b_fault) valid_count++;
    if (!channels->channel_c_fault) valid_count++;

    // Need at least 2 valid channels
    if (valid_count < 2) {
        return false;
    }

    // Check agreement between pairs
    bool ab_agree = fabsf(channels->channel_a - channels->channel_b) /
                    channels->channel_a < VOTE_TOLERANCE;
    bool ac_agree = fabsf(channels->channel_a - channels->channel_c) /
                    channels->channel_a < VOTE_TOLERANCE;
    bool bc_agree = fabsf(channels->channel_b - channels->channel_c) /
                    channels->channel_b < VOTE_TOLERANCE;

    // A and B agree
    if (ab_agree && !channels->channel_a_fault && !channels->channel_b_fault) {
        *output = (channels->channel_a + channels->channel_b) / 2.0f;
        if (!ac_agree && !channels->channel_c_fault) {
            // C is outlier - mark as faulty
            channels->channel_c_fault = true;
        }
        return true;
    }

    // A and C agree
    if (ac_agree && !channels->channel_a_fault && !channels->channel_c_fault) {
        *output = (channels->channel_a + channels->channel_c) / 2.0f;
        if (!ab_agree && !channels->channel_b_fault) {
            channels->channel_b_fault = true;
        }
        return true;
    }

    // B and C agree
    if (bc_agree && !channels->channel_b_fault && !channels->channel_c_fault) {
        *output = (channels->channel_b + channels->channel_c) / 2.0f;
        if (!ab_agree && !channels->channel_a_fault) {
            channels->channel_a_fault = true;
        }
        return true;
    }

    // No agreement among any pair
    return false;
}
```

## Watchdog Mechanisms

### 1. Window Watchdog

**Timing Constraints:**
```c
// Window watchdog - must refresh within time window
typedef struct {
    uint32_t window_min_ms;  // Minimum time before refresh allowed
    uint32_t window_max_ms;  // Maximum time before timeout
    uint32_t last_refresh_time;
    bool watchdog_fault;
} WindowWatchdog_t;

void InitWindowWatchdog(WindowWatchdog_t *wdt, uint32_t min_ms, uint32_t max_ms) {
    wdt->window_min_ms = min_ms;
    wdt->window_max_ms = max_ms;
    wdt->last_refresh_time = GetSystemTimeMs();
    wdt->watchdog_fault = false;
}

void RefreshWindowWatchdog(WindowWatchdog_t *wdt) {
    uint32_t current_time = GetSystemTimeMs();
    uint32_t elapsed = current_time - wdt->last_refresh_time;

    // Check if refresh is too early
    if (elapsed < wdt->window_min_ms) {
        wdt->watchdog_fault = true;
        SetDTC(DTC_WATCHDOG_EARLY_REFRESH);
        EnterSafeState();
        return;
    }

    // Check if refresh is too late
    if (elapsed > wdt->window_max_ms) {
        wdt->watchdog_fault = true;
        SetDTC(DTC_WATCHDOG_TIMEOUT);
        EnterSafeState();
        return;
    }

    // Valid refresh - update timestamp
    wdt->last_refresh_time = current_time;
    wdt->watchdog_fault = false;

    // Refresh hardware watchdog
    HW_WDT_Refresh();
}

// Monitor task - checks watchdog status
void WatchdogMonitorTask(void) {
    WindowWatchdog_t *wdt = GetSystemWatchdog();

    uint32_t current_time = GetSystemTimeMs();
    uint32_t elapsed = current_time - wdt->last_refresh_time;

    if (elapsed > wdt->window_max_ms) {
        // Watchdog expired - enter safe state
        wdt->watchdog_fault = true;
        EnterSafeState();
    }
}
```

### 2. Logical Program Flow Monitoring

**Checkpoints and Sequence Validation:**

```c
// Program flow monitor - detects unexpected execution paths
typedef enum {
    CHECKPOINT_INIT = 0x01,
    CHECKPOINT_SENSOR_READ = 0x02,
    CHECKPOINT_CALCULATION = 0x04,
    CHECKPOINT_OUTPUT = 0x08,
    CHECKPOINT_END = 0x10
} Checkpoint_t;

typedef struct {
    uint32_t expected_sequence;
    uint32_t actual_sequence;
    uint32_t sequence_errors;
} ProgramFlowMonitor_t;

static ProgramFlowMonitor_t flow_monitor;

void InitProgramFlowMonitor(void) {
    flow_monitor.expected_sequence = CHECKPOINT_INIT |
                                     CHECKPOINT_SENSOR_READ |
                                     CHECKPOINT_CALCULATION |
                                     CHECKPOINT_OUTPUT |
                                     CHECKPOINT_END;
    flow_monitor.actual_sequence = 0;
    flow_monitor.sequence_errors = 0;
}

void RecordCheckpoint(Checkpoint_t checkpoint) {
    flow_monitor.actual_sequence |= checkpoint;
}

void ValidateProgramFlow(void) {
    if (flow_monitor.actual_sequence != flow_monitor.expected_sequence) {
        flow_monitor.sequence_errors++;

        if (flow_monitor.sequence_errors > 3) {
            SetDTC(DTC_PROGRAM_FLOW_ERROR);
            EnterSafeState();
        }
    } else {
        // Reset error counter on successful execution
        flow_monitor.sequence_errors = 0;
    }

    // Reset for next cycle
    flow_monitor.actual_sequence = 0;
}

// Critical function with flow monitoring
void SafetyFunction_Example(void) {
    RecordCheckpoint(CHECKPOINT_INIT);

    // Initialize
    InitializeInputs();

    RecordCheckpoint(CHECKPOINT_SENSOR_READ);

    // Read sensors
    float sensor_value = ReadSensor();

    RecordCheckpoint(CHECKPOINT_CALCULATION);

    // Perform calculation
    float result = ProcessSensorData(sensor_value);

    RecordCheckpoint(CHECKPOINT_OUTPUT);

    // Output result
    WriteActuator(result);

    RecordCheckpoint(CHECKPOINT_END);

    // Validate execution path
    ValidateProgramFlow();
}
```

## CRC and Checksum Mechanisms

### 1. CRC-16 for Message Integrity

```c
// CRC-16-CCITT (polynomial 0x1021)
uint16_t CalculateCRC16(const uint8_t *data, uint16_t length) {
    uint16_t crc = 0xFFFF;  // Initial value
    const uint16_t polynomial = 0x1021;

    for (uint16_t i = 0; i < length; i++) {
        crc ^= (uint16_t)(data[i] << 8);

        for (uint8_t bit = 0; bit < 8; bit++) {
            if (crc & 0x8000) {
                crc = (crc << 1) ^ polynomial;
            } else {
                crc <<= 1;
            }
        }
    }

    return crc;
}

// CAN message with E2E protection
typedef struct {
    uint32_t message_id;
    uint8_t data[8];
    uint8_t data_length;
    uint16_t crc;
    uint8_t alive_counter;
} SafetyMessage_t;

bool ValidateSafetyMessage(SafetyMessage_t *msg) {
    // Calculate expected CRC (exclude CRC field itself)
    uint16_t calculated_crc = CalculateCRC16(msg->data, msg->data_length);

    // Verify CRC
    if (calculated_crc != msg->crc) {
        SetDTC(DTC_CRC_MISMATCH);
        return false;
    }

    // Verify alive counter (detects message loss/repetition)
    static uint8_t last_counter[256] = {0};  // Per message ID
    uint8_t expected_counter = (last_counter[msg->message_id] + 1) & 0x0F;

    if (msg->alive_counter != expected_counter) {
        SetDTC(DTC_ALIVE_COUNTER_ERROR);
        return false;
    }

    last_counter[msg->message_id] = msg->alive_counter;
    return true;
}
```

### 2. AUTOSAR E2E Protection

```c
// AUTOSAR E2E Profile 1 (for 8-byte CAN messages)
typedef struct {
    uint8_t Counter;    // 4-bit alive counter
    uint8_t DataID;     // Data identifier
    uint16_t CRC;       // 16-bit CRC
} E2E_P01_Header_t;

typedef enum {
    E2E_P01STATUS_OK,
    E2E_P01STATUS_NONEWDATA,
    E2E_P01STATUS_WRONGCRC,
    E2E_P01STATUS_REPEATED,
    E2E_P01STATUS_WRONGSEQUENCE
} E2E_P01Status_t;

E2E_P01Status_t E2E_P01Check(
    const uint8_t *data,
    uint8_t length,
    uint8_t *last_counter
) {
    E2E_P01_Header_t *header = (E2E_P01_Header_t *)data;

    // 1. Verify CRC
    uint16_t calculated_crc = CalculateCRC16(data + 2, length - 2);
    if (calculated_crc != header->CRC) {
        return E2E_P01STATUS_WRONGCRC;
    }

    // 2. Check counter sequence
    uint8_t expected_counter = (*last_counter + 1) & 0x0F;
    if (header->Counter == *last_counter) {
        return E2E_P01STATUS_REPEATED;
    } else if (header->Counter != expected_counter) {
        return E2E_P01STATUS_WRONGSEQUENCE;
    }

    // 3. Update counter
    *last_counter = header->Counter;

    return E2E_P01STATUS_OK;
}
```

## Memory Protection

### 1. RAM Test Patterns

```c
// March test for RAM integrity
typedef enum {
    MARCH_TEST_PASS,
    MARCH_TEST_FAIL_WRITE,
    MARCH_TEST_FAIL_READ
} MarchTestResult_t;

MarchTestResult_t MarchTest(volatile uint32_t *ram_start, uint32_t size_words) {
    uint32_t i;

    // Phase 1: Write 0 (ascending)
    for (i = 0; i < size_words; i++) {
        ram_start[i] = 0x00000000;
    }

    // Phase 2: Read 0, Write 1 (ascending)
    for (i = 0; i < size_words; i++) {
        if (ram_start[i] != 0x00000000) {
            return MARCH_TEST_FAIL_READ;
        }
        ram_start[i] = 0xFFFFFFFF;
    }

    // Phase 3: Read 1, Write 0 (descending)
    for (i = size_words; i > 0; i--) {
        if (ram_start[i-1] != 0xFFFFFFFF) {
            return MARCH_TEST_FAIL_READ;
        }
        ram_start[i-1] = 0x00000000;
    }

    // Phase 4: Read 0 (descending)
    for (i = size_words; i > 0; i--) {
        if (ram_start[i-1] != 0x00000000) {
            return MARCH_TEST_FAIL_READ;
        }
    }

    return MARCH_TEST_PASS;
}

// Background RAM test (runs incrementally)
typedef struct {
    uint32_t *ram_start;
    uint32_t ram_size_words;
    uint32_t current_block;
    uint32_t blocks_per_cycle;
} BackgroundRAMTest_t;

void InitBackgroundRAMTest(
    BackgroundRAMTest_t *test,
    uint32_t *ram_start,
    uint32_t size_words,
    uint32_t blocks_per_cycle
) {
    test->ram_start = ram_start;
    test->ram_size_words = size_words;
    test->current_block = 0;
    test->blocks_per_cycle = blocks_per_cycle;
}

void RunBackgroundRAMTestCycle(BackgroundRAMTest_t *test) {
    uint32_t words_per_block = test->ram_size_words / test->blocks_per_cycle;
    uint32_t start_offset = test->current_block * words_per_block;

    MarchTestResult_t result = MarchTest(
        &test->ram_start[start_offset],
        words_per_block
    );

    if (result != MARCH_TEST_PASS) {
        SetDTC(DTC_RAM_TEST_FAILURE);
        EnterSafeState();
    }

    // Move to next block
    test->current_block = (test->current_block + 1) % test->blocks_per_cycle;
}
```

### 2. Stack Overflow Detection

```c
// Stack canary pattern
#define STACK_CANARY_PATTERN 0xDEADBEEF

typedef struct {
    uint32_t *stack_start;
    uint32_t *stack_end;
    uint32_t canary_value;
} StackMonitor_t;

void InitStackMonitor(
    StackMonitor_t *monitor,
    uint32_t *stack_start,
    uint32_t *stack_end
) {
    monitor->stack_start = stack_start;
    monitor->stack_end = stack_end;
    monitor->canary_value = STACK_CANARY_PATTERN;

    // Place canary at stack boundary
    *stack_end = STACK_CANARY_PATTERN;
}

bool CheckStackOverflow(StackMonitor_t *monitor) {
    if (*monitor->stack_end != STACK_CANARY_PATTERN) {
        SetDTC(DTC_STACK_OVERFLOW);
        return true;
    }
    return false;
}

// Call in task or periodic interrupt
void StackMonitorTask(void) {
    StackMonitor_t *monitor = GetStackMonitor();

    if (CheckStackOverflow(monitor)) {
        EnterSafeState();
    }
}
```

## Plausibility Checks

### 1. Sensor Range Checks

```c
// Multi-level range checking with hysteresis
typedef struct {
    float min_physical;     // Physical sensor limit
    float max_physical;
    float min_operational;  // Normal operating range
    float max_operational;
    float hysteresis;       // Debounce tolerance
    uint32_t fault_counter;
    uint32_t fault_threshold;
} RangeLimits_t;

typedef enum {
    RANGE_VALID,
    RANGE_WARNING,
    RANGE_FAULT
} RangeStatus_t;

RangeStatus_t CheckSensorRange(float value, RangeLimits_t *limits) {
    // Check physical limits (hard fault)
    if (value < limits->min_physical || value > limits->max_physical) {
        limits->fault_counter++;

        if (limits->fault_counter >= limits->fault_threshold) {
            SetDTC(DTC_SENSOR_RANGE_PHYSICAL);
            return RANGE_FAULT;
        }
    }

    // Check operational limits with hysteresis
    if (value < (limits->min_operational - limits->hysteresis) ||
        value > (limits->max_operational + limits->hysteresis)) {

        limits->fault_counter++;

        if (limits->fault_counter >= limits->fault_threshold) {
            SetDTC(DTC_SENSOR_RANGE_OPERATIONAL);
            return RANGE_WARNING;
        }
    } else {
        // Value in range - reset counter
        if (limits->fault_counter > 0) {
            limits->fault_counter--;
        }
    }

    return RANGE_VALID;
}

// Example: Battery temperature sensor
RangeLimits_t battery_temp_limits = {
    .min_physical = -40.0f,      // Physical sensor limit
    .max_physical = 125.0f,
    .min_operational = -20.0f,   // Normal operating range
    .max_operational = 60.0f,
    .hysteresis = 2.0f,          // 2°C hysteresis
    .fault_counter = 0,
    .fault_threshold = 3         // 3 consecutive faults
};
```

### 2. Signal Gradient Checks

```c
// Detect unrealistic rate of change
typedef struct {
    float last_value;
    uint32_t last_timestamp_ms;
    float max_gradient;  // Maximum rate of change per second
    uint32_t fault_counter;
} GradientMonitor_t;

bool CheckSignalGradient(
    float current_value,
    uint32_t current_timestamp_ms,
    GradientMonitor_t *monitor
) {
    uint32_t delta_time_ms = current_timestamp_ms - monitor->last_timestamp_ms;

    if (delta_time_ms > 0) {
        float delta_value = current_value - monitor->last_value;
        float gradient = (delta_value * 1000.0f) / (float)delta_time_ms;  // per second

        if (fabsf(gradient) > monitor->max_gradient) {
            monitor->fault_counter++;

            if (monitor->fault_counter >= 3) {
                SetDTC(DTC_SIGNAL_GRADIENT_FAULT);
                return false;
            }
        } else {
            monitor->fault_counter = 0;
        }
    }

    // Update history
    monitor->last_value = current_value;
    monitor->last_timestamp_ms = current_timestamp_ms;

    return true;
}

// Example: Vehicle speed gradient check
GradientMonitor_t speed_gradient = {
    .last_value = 0.0f,
    .last_timestamp_ms = 0,
    .max_gradient = 10.0f,  // 10 m/s² max acceleration/deceleration
    .fault_counter = 0
};
```

### 3. Cross-Signal Plausibility

```c
// Verify consistency between related signals
typedef struct {
    float wheel_speed_fl;
    float wheel_speed_fr;
    float wheel_speed_rl;
    float wheel_speed_rr;
    float vehicle_speed;
    float accelerometer_speed;
} SpeedPlausibility_t;

bool CheckSpeedPlausibility(SpeedPlausibility_t *speeds) {
    const float MAX_WHEEL_DELTA = 20.0f;  // km/h max difference between wheels
    const float MAX_ACCEL_DELTA = 10.0f;  // km/h max difference with accelerometer

    // Check consistency between front wheels
    float fl_fr_delta = fabsf(speeds->wheel_speed_fl - speeds->wheel_speed_fr);
    if (fl_fr_delta > MAX_WHEEL_DELTA) {
        SetDTC(DTC_WHEEL_SPEED_IMPLAUSIBLE);
        return false;
    }

    // Check consistency between rear wheels
    float rl_rr_delta = fabsf(speeds->wheel_speed_rl - speeds->wheel_speed_rr);
    if (rl_rr_delta > MAX_WHEEL_DELTA) {
        SetDTC(DTC_WHEEL_SPEED_IMPLAUSIBLE);
        return false;
    }

    // Check vehicle speed vs accelerometer integration
    float accel_delta = fabsf(speeds->vehicle_speed - speeds->accelerometer_speed);
    if (accel_delta > MAX_ACCEL_DELTA) {
        SetDTC(DTC_SPEED_ACCEL_MISMATCH);
        return false;
    }

    return true;
}
```

## Safe State Management

### 1. Safe State Transition

```c
// Safe state state machine
typedef enum {
    STATE_NORMAL_OPERATION,
    STATE_DEGRADED_MODE,
    STATE_SAFE_STATE,
    STATE_EMERGENCY_SHUTDOWN
} SystemState_t;

typedef struct {
    SystemState_t current_state;
    uint32_t fault_mask;
    uint32_t warning_mask;
    uint32_t transition_timestamp;
    bool safe_state_locked;
} SafeStateManager_t;

void TransitionToSafeState(
    SafeStateManager_t *manager,
    uint32_t fault_code
) {
    // Record fault
    manager->fault_mask |= fault_code;
    manager->transition_timestamp = GetSystemTimeMs();

    switch (manager->current_state) {
        case STATE_NORMAL_OPERATION:
            // Evaluate severity
            if (IsCriticalFault(fault_code)) {
                manager->current_state = STATE_SAFE_STATE;
                EnterSafeStateActions();
            } else {
                manager->current_state = STATE_DEGRADED_MODE;
                EnterDegradedModeActions();
            }
            break;

        case STATE_DEGRADED_MODE:
            // Any additional fault → safe state
            manager->current_state = STATE_SAFE_STATE;
            EnterSafeStateActions();
            break;

        case STATE_SAFE_STATE:
            // Check if emergency shutdown required
            if (IsEmergencyCondition(fault_code)) {
                manager->current_state = STATE_EMERGENCY_SHUTDOWN;
                EmergencyShutdownActions();
            }
            break;

        case STATE_EMERGENCY_SHUTDOWN:
            // Terminal state - stay here
            break;
    }

    // Log state transition
    LogStateTransition(manager->current_state, fault_code);

    // Activate warning lamp
    UpdateWarningLamp(manager->current_state);

    // Store DTC
    SetDTC(fault_code);
}

void EnterSafeStateActions(void) {
    // Disable safety-critical outputs
    DisableActuators();

    // Switch to fail-safe values
    SetFailSafeOutputs();

    // Maintain basic functions (e.g., manual braking)
    EnableManualControl();

    // Activate warning indicators
    ActivateWarningLamp(WARNING_LAMP_SYSTEM_FAULT);

    // Log event in NVM
    StoreEventInNonVolatileMemory();

    // Notify other ECUs via CAN
    SendSafeStateNotification();
}
```

### 2. Graceful Degradation

```c
// Multi-level degradation strategy
typedef enum {
    PERFORMANCE_FULL,        // 100% capability
    PERFORMANCE_REDUCED_1,   // 80% capability
    PERFORMANCE_REDUCED_2,   // 50% capability
    PERFORMANCE_MINIMAL,     // 20% capability (safety only)
    PERFORMANCE_DISABLED     // 0% (safe state)
} PerformanceLevel_t;

typedef struct {
    PerformanceLevel_t current_level;
    uint32_t redundancy_available;
    uint32_t faults_detected;
} DegradationManager_t;

void UpdatePerformanceLevel(DegradationManager_t *manager) {
    // Determine performance level based on fault state
    if (manager->faults_detected == 0) {
        manager->current_level = PERFORMANCE_FULL;
    } else if (manager->redundancy_available >= 2) {
        manager->current_level = PERFORMANCE_REDUCED_1;
    } else if (manager->redundancy_available == 1) {
        manager->current_level = PERFORMANCE_REDUCED_2;
    } else if (manager->redundancy_available == 0 && manager->faults_detected == 1) {
        manager->current_level = PERFORMANCE_MINIMAL;
    } else {
        manager->current_level = PERFORMANCE_DISABLED;
    }

    // Apply performance limits
    ApplyPerformanceLimits(manager->current_level);

    // Notify driver
    UpdateDriverDisplay(manager->current_level);
}

void ApplyPerformanceLimits(PerformanceLevel_t level) {
    switch (level) {
        case PERFORMANCE_FULL:
            SetMaxTorque(100.0f);  // 100% torque
            SetMaxSpeed(200.0f);   // 200 km/h
            break;

        case PERFORMANCE_REDUCED_1:
            SetMaxTorque(80.0f);   // 80% torque
            SetMaxSpeed(160.0f);   // 160 km/h
            break;

        case PERFORMANCE_REDUCED_2:
            SetMaxTorque(50.0f);   // 50% torque
            SetMaxSpeed(100.0f);   // 100 km/h
            break;

        case PERFORMANCE_MINIMAL:
            SetMaxTorque(20.0f);   // 20% torque (limp home)
            SetMaxSpeed(50.0f);    // 50 km/h
            break;

        case PERFORMANCE_DISABLED:
            SetMaxTorque(0.0f);
            SetMaxSpeed(0.0f);
            EnterSafeState();
            break;
    }
}
```

## Diagnostic Coverage Metrics

### ASIL-D Target Coverage

```c
// Diagnostic coverage calculation
typedef struct {
    uint32_t total_failure_modes;
    uint32_t detected_single_point_faults;
    uint32_t detected_latent_faults;
    uint32_t detected_residual_faults;
} DiagnosticCoverage_t;

float CalculateSPFM(DiagnosticCoverage_t *coverage) {
    // Single-Point Fault Metric
    // ASIL-D target: > 99%
    return ((float)coverage->detected_single_point_faults /
            (float)coverage->total_failure_modes) * 100.0f;
}

float CalculateLFM(DiagnosticCoverage_t *coverage) {
    // Latent Fault Metric
    // ASIL-D target: > 90%
    return ((float)coverage->detected_latent_faults /
            (float)coverage->total_failure_modes) * 100.0f;
}
```

## Production Checklist

- [ ] Redundancy pattern selected and justified
- [ ] Diagnostic coverage calculated (SPFM > 99%, LFM > 90% for ASIL-D)
- [ ] Watchdog configuration verified
- [ ] CRC/checksum implementation validated
- [ ] Memory protection tested
- [ ] Plausibility checks defined for all sensors
- [ ] Safe state defined and tested
- [ ] FTTI verified through fault injection
- [ ] Warning lamp activation tested
- [ ] DTC storage verified
- [ ] Independent safety assessment completed

## References

- ISO 26262-5:2018 - Hardware Development
- ISO 26262-6:2018 - Software Development
- ISO 26262-9:2018 - ASIL-Oriented Analyses
- IEC 61508 - Functional Safety (general industry)
- AUTOSAR E2E Protocol Specification

## Related Skills

- ISO 26262 Overview
- FMEA/FTA Analysis
- Hardware Safety Requirements
- Software Safety Requirements
- Safety Verification and Validation

---

## Safety Verification Validation

# Safety Verification and Validation - ISO 26262

Comprehensive guidance on verification and validation per ISO 26262-4, including verification methods, validation test strategies, HIL testing, fault injection, back-to-back testing, traceability matrices, and functional safety assessment.

## Verification vs Validation

### Key Differences

**Verification:** *"Are we building the product right?"*
- Check implementation against requirements
- Performed at each development level
- Methods: review, analysis, test
- Answers: Does code match specification?

**Validation:** *"Are we building the right product?"*
- Check product meets safety goals
- Performed on integrated system
- Methods: testing in target environment
- Answers: Does system prevent hazards?

```
Requirements → [Verification] → Implementation
      ↓
Safety Goals → [Validation] → Final Product
```

## Verification Methods by ASIL

### ISO 26262-8 Table 4 - Verification Methods

| Method | ASIL A | ASIL B | ASIL C | ASIL D |
|--------|--------|--------|--------|--------|
| Walkthrough | + | + | ++ | ++ |
| Inspection | + | ++ | ++ | +++ |
| Semi-formal verification | O | + | ++ | ++ |
| Formal verification | O | O | + | ++ |
| Control flow analysis | + | ++ | ++ | +++ |
| Data flow analysis | + | ++ | ++ | +++ |
| Simulation/prototyping | ++ | ++ | +++ | +++ |
| Requirements-based test | ++ | +++ | +++ | +++ |
| Interface test | ++ | +++ | +++ | +++ |
| Fault injection test | O | + | ++ | +++ |
| Resource usage analysis | + | ++ | +++ | +++ |
| Back-to-back comparison | O | + | ++ | +++ |

Legend: +++ Highly recommended, ++ Recommended, + Optional, O Not recommended

## Requirements Review

### Review Checklist Template

```yaml
review_id: "REV-SWR-ESC-001"
document: "Software Safety Requirements v2.5"
review_type: "Inspection"
asil: "ASIL-D"
date: "2024-03-19"
participants:
  - role: "Moderator"
    name: "J. Smith"
  - role: "Safety Engineer"
    name: "M. Johnson"
  - role: "Software Architect"
    name: "K. Williams"
  - role: "Test Engineer"
    name: "R. Davis"

requirements_quality:
  - criterion: "Unambiguous"
    check: "Each requirement has single interpretation"
    status: "PASS"
    findings: []

  - criterion: "Testable"
    check: "Verification method defined for each requirement"
    status: "PASS"
    findings: []

  - criterion: "Complete"
    check: "All safety goals covered by requirements"
    status: "FAIL"
    findings:
      - finding_id: "F001"
        description: "SG-ESC-003 (response time) not covered by SWR"
        severity: "Critical"
        action: "Add SWR-ESC-045 for timing requirement"
        responsible: "Software Architect"
        due_date: "2024-03-25"

  - criterion: "Consistent"
    check: "No conflicting requirements"
    status: "PASS"
    findings: []

  - criterion: "Traceable"
    check: "Links to TSR and safety goals present"
    status: "PASS"
    findings: []

  - criterion: "Feasible"
    check: "Technically achievable with available resources"
    status: "PASS"
    findings: []

verification_criteria:
  - requirement: "SWR-ESC-001"
    method: "Requirements-based test"
    coverage: "MC/DC"
    status: "Defined"

  - requirement: "SWR-ESC-002"
    method: "Fault injection test"
    coverage: "All fault modes"
    status: "Defined"

summary:
  total_requirements: 44
  passed: 43
  failed: 1
  open_findings: 1
  approval_status: "CONDITIONAL (pending F001 closure)"

next_review: "After F001 resolved (estimated 2024-03-26)"
```

## Static Analysis

### Control Flow Analysis

```c
// Example function for control flow analysis
uint8_t ESC_CalculateControl(float yaw_rate, float lateral_accel) {
    uint8_t control_level = 0;

    // Control flow graph:
    //     Entry
    //       |
    //   Check yaw_rate
    //     /   \
    //   Yes    No
    //    |      |
    // Check    Check
    // lat_acc  lat_acc
    //    |      |
    //   Set    Set
    //   level  level
    //     \   /
    //     Exit

    if (yaw_rate > YAW_THRESHOLD) {
        if (lateral_accel > ACCEL_THRESHOLD) {
            control_level = 3;  // High intervention
        } else {
            control_level = 2;  // Medium intervention
        }
    } else {
        if (lateral_accel > ACCEL_THRESHOLD) {
            control_level = 1;  // Low intervention
        } else {
            control_level = 0;  // No intervention
        }
    }

    return control_level;  // Single exit point (MISRA compliant)
}

// Static analysis checks:
// ✓ No unreachable code
// ✓ Single entry, single exit
// ✓ All paths return a value
// ✓ Cyclomatic complexity: 3 (acceptable for ASIL-D)
// ✓ No recursion
```

### Data Flow Analysis

```c
// Data flow analysis example
typedef struct {
    float wheel_speed_fl;      // Defined at line 5
    float wheel_speed_fr;      // Defined at line 6
    bool valid_fl;             // Defined at line 7
    bool valid_fr;             // Defined at line 8
} SensorData_t;

void ESC_ProcessSensors(SensorData_t *data) {
    float average_speed;  // Declared at line 12

    // Read sensors (define values)
    data->wheel_speed_fl = ReadSensor(SENSOR_FL);  // Line 15: Define wheel_speed_fl
    data->wheel_speed_fr = ReadSensor(SENSOR_FR);  // Line 16: Define wheel_speed_fr

    // Validate sensors (define valid flags)
    data->valid_fl = ValidateSensor(data->wheel_speed_fl);  // Line 19: Use wheel_speed_fl
    data->valid_fr = ValidateSensor(data->wheel_speed_fr);  // Line 20: Use wheel_speed_fr

    // Calculate average (use values)
    if (data->valid_fl && data->valid_fr) {  // Line 23: Use valid_fl, valid_fr
        average_speed = (data->wheel_speed_fl + data->wheel_speed_fr) / 2.0f;
        // Line 24: Use wheel_speed_fl, wheel_speed_fr, Define average_speed
    }

    // Use average (line 28: Use average_speed)
    if (data->valid_fl && data->valid_fr) {  // Condition ensures average_speed is defined
        UseAverageSpeed(average_speed);
    }
}

// Data flow analysis results:
// ✓ No use before definition (all variables initialized before use)
// ✓ No unused variables
// ✓ No redundant assignments
// ✓ Proper initialization of average_speed before use
```

## Requirements-Based Testing

### Test Case Template

```yaml
test_case_id: "TC-SWR-ESC-001-001"
requirement: "SWR-ESC-001.1"
requirement_text: "Software SHALL reject wheel speed < 0 km/h"
test_type: "Unit Test"
asil: "ASIL-D"
test_level: "Software Unit Testing"

preconditions:
  - ESC module initialized
  - Wheel speed sensor interface configured
  - No prior faults

test_inputs:
  - name: "wheel_speed_fl"
    value: -10.0
    unit: "km/h"
  - name: "sensor_status"
    value: "VALID"

expected_outputs:
  - name: "validation_result"
    value: false
    description: "Validation should fail for negative speed"
  - name: "fault_flag"
    value: true
    description: "Fault flag should be set"
  - name: "dtc_code"
    value: "DTC_WHEEL_SPEED_INVALID"

test_procedure:
  - step: 1
    action: "Call ESC_ValidateWheelSpeed(-10.0)"
    expected: "Function returns false"
  - step: 2
    action: "Check fault flag"
    expected: "Fault flag is set"
  - step: 3
    action: "Read DTC buffer"
    expected: "DTC_WHEEL_SPEED_INVALID present"

pass_criteria:
  - All expected outputs match actual outputs
  - No unexpected side effects
  - Function executes within timing budget (< 50 μs)

execution:
  date: "2024-03-19"
  tester: "R. Davis"
  environment: "Unit test framework (Unity)"
  result: "PASS"
  actual_outputs:
    validation_result: false
    fault_flag: true
    dtc_code: "DTC_WHEEL_SPEED_INVALID"
  execution_time_us: 12
  notes: "Test passed on first attempt"

coverage:
  line_coverage: 100%
  branch_coverage: 100%
  mcdc_coverage: 100%
```

## Fault Injection Testing

### Hardware Fault Injection

```c
// Fault injection framework
typedef enum {
    FAULT_NONE,
    FAULT_SENSOR_STUCK_HIGH,
    FAULT_SENSOR_STUCK_LOW,
    FAULT_SENSOR_NOISE,
    FAULT_SENSOR_DROPOUT,
    FAULT_BIT_FLIP,
    FAULT_TIMING_VIOLATION
} FaultType_t;

typedef struct {
    FaultType_t fault_type;
    uint32_t injection_time_ms;
    uint32_t duration_ms;
    void *target_address;
    uint32_t fault_mask;
} FaultInjectionConfig_t;

// Inject sensor stuck-high fault
void InjectFault_SensorStuckHigh(void) {
    FaultInjectionConfig_t config = {
        .fault_type = FAULT_SENSOR_STUCK_HIGH,
        .injection_time_ms = 1000,  // Inject after 1 second
        .duration_ms = 500,          // Fault persists for 500ms
        .target_address = &wheel_speed_fl_raw,
        .fault_mask = 0xFFFFFFFF     // Maximum value
    };

    // Configure fault injection hardware (e.g., FPGA, fault injection tool)
    ConfigureFaultInjection(&config);
}

// Test: Verify safe state transition on persistent sensor fault
void Test_SafeState_PersistentSensorFault(void) {
    // 1. Initialize system
    ESC_Init();
    assert(ESC_GetMode() == ESC_MODE_NORMAL);

    // 2. Inject stuck-high fault on wheel speed sensor
    InjectFault_SensorStuckHigh();

    // 3. Run for fault duration
    for (uint32_t t = 0; t < 600; t += 10) {  // 600ms
        ESC_MainFunction();  // 10ms periodic task
        Delay_ms(10);
    }

    // 4. Verify safe state entered
    assert(ESC_GetMode() == ESC_MODE_SAFE_STATE);

    // 5. Verify warning lamp activated
    assert(GetWarningLampStatus() == WARNING_LAMP_ON);

    // 6. Verify DTC stored
    assert(IsDTCStored(DTC_WHEEL_SPEED_FAULT));

    // 7. Verify transition time within FTTI
    uint32_t transition_time = GetSafeStateTransitionTime_ms();
    assert(transition_time <= 150);  // FTTI requirement

    printf("✓ Safe state test PASS (transition time: %u ms)\n", transition_time);
}
```

### Software Fault Injection (Mutation Testing)

```python
# Mutation testing for safety mechanisms
import subprocess
import re

class MutationTester:
    def __init__(self, source_file, test_executable):
        self.source_file = source_file
        self.test_executable = test_executable
        self.mutations = []

    def generate_mutations(self):
        """Generate mutations of source code"""
        with open(self.source_file, 'r') as f:
            original_code = f.read()

        # Mutation 1: Change comparison operators
        mutations = [
            (r'>', '>='),    # > to >=
            (r'<', '<='),    # < to <=
            (r'==', '!='),   # == to !=
            (r'&&', '||'),   # && to ||
        ]

        for i, (pattern, replacement) in enumerate(mutations):
            mutated_code = re.sub(pattern, replacement, original_code, count=1)
            self.mutations.append({
                'id': f'MUT-{i+1}',
                'description': f'Change {pattern} to {replacement}',
                'code': mutated_code
            })

    def run_mutation_test(self, mutation):
        """Run tests against mutated code"""
        # Write mutated code to file
        with open(self.source_file, 'w') as f:
            f.write(mutation['code'])

        # Recompile
        compile_result = subprocess.run(['make', 'clean', 'all'],
                                       capture_output=True)

        # Run tests
        test_result = subprocess.run([self.test_executable],
                                     capture_output=True)

        # Mutation killed if tests fail
        killed = (test_result.returncode != 0)

        return killed

    def analyze_coverage(self):
        """Analyze mutation test coverage"""
        total = len(self.mutations)
        killed = sum(1 for m in self.mutations if self.run_mutation_test(m))

        mutation_score = (killed / total) * 100
        print(f"Mutation Score: {mutation_score:.1f}%")
        print(f"Mutations Killed: {killed}/{total}")

        # ASIL-D target: > 95% mutation score
        if mutation_score > 95:
            print("✓ Mutation testing PASS")
        else:
            print("✗ Mutation testing FAIL (target: > 95%)")

        return mutation_score

# Example usage
tester = MutationTester('esc_safety.c', './test_esc')
tester.generate_mutations()
tester.analyze_coverage()
```

## HIL (Hardware-in-Loop) Testing

### HIL Test Setup

```
┌─────────────────────────────────────────────────────────┐
│                   HIL Test System                       │
│                                                         │
│  ┌──────────────┐         ┌──────────────┐            │
│  │   Real-Time  │         │  Vehicle     │            │
│  │   Simulator  │◄───────►│  Dynamics    │            │
│  │   (dSPACE)   │         │  Model       │            │
│  └──────┬───────┘         └──────────────┘            │
│         │                                              │
│         │ CAN/LIN/Ethernet                             │
│         │                                              │
│  ┌──────▼───────┐         ┌──────────────┐            │
│  │   ESC ECU    │◄───────►│  Fault       │            │
│  │   (Real HW)  │         │  Injection   │            │
│  └──────┬───────┘         └──────────────┘            │
│         │                                              │
│         │ Actuator Outputs                             │
│         │                                              │
│  ┌──────▼───────┐         ┌──────────────┐            │
│  │   Brake      │         │  Test        │            │
│  │   Simulator  │◄───────►│  Automation  │            │
│  └──────────────┘         └──────────────┘            │
└─────────────────────────────────────────────────────────┘
```

### HIL Test Script (Python + dSPACE)

```python
#!/usr/bin/env python3
"""
HIL Test: ESC Safety Goal Verification
Test: SG-ESC-001 - Prevent unintended ESC activation
"""

import dspace
import time
import numpy as np

class HILTest_ESC:
    def __init__(self):
        self.ds = dspace.HILSystem('10.0.0.100')  # dSPACE IP
        self.test_results = []

    def setup(self):
        """Initialize HIL system"""
        # Load vehicle dynamics model
        self.ds.load_model('vehicle_dynamics_sedan_2024.sdf')

        # Configure CAN interface
        self.ds.configure_can(channel=1, baudrate=500000)

        # Reset ECU
        self.ds.reset_ecu()
        time.sleep(1)

        # Set initial conditions
        self.ds.set_variable('VehicleSpeed', 100.0)  # km/h
        self.ds.set_variable('RoadFriction', 0.8)    # Dry road
        self.ds.set_variable('SteeringAngle', 0.0)   # Straight

    def test_no_intervention_straight_driving(self):
        """Verify ESC does not activate during normal straight driving"""
        print("Test: No intervention during straight driving...")

        # Run simulation for 30 seconds
        self.ds.start_simulation()

        for t in np.arange(0, 30, 0.01):  # 10ms steps
            # Maintain steady state
            self.ds.set_variable('SteeringAngle', 0.0)
            self.ds.set_variable('VehicleSpeed', 100.0)

            # Read ESC status
            esc_active = self.ds.get_can_signal('ESC_Status', 'ESC_Active')

            # Verify ESC not active
            if esc_active:
                print(f"✗ FAIL: Unintended ESC activation at t={t:.2f}s")
                self.test_results.append({
                    'test': 'No_Intervention_Straight',
                    'result': 'FAIL',
                    'time': t
                })
                self.ds.stop_simulation()
                return False

            time.sleep(0.01)

        self.ds.stop_simulation()
        print("✓ PASS: No unintended activation")
        self.test_results.append({
            'test': 'No_Intervention_Straight',
            'result': 'PASS'
        })
        return True

    def test_intervention_oversteer(self):
        """Verify ESC activates during oversteer condition"""
        print("Test: ESC activation during oversteer...")

        self.ds.start_simulation()

        # Create oversteer condition
        self.ds.set_variable('VehicleSpeed', 100.0)
        self.ds.set_variable('RoadFriction', 0.3)  # Wet road

        # Sudden steering input
        for t in np.arange(0, 2, 0.01):
            self.ds.set_variable('SteeringAngle', 45.0)  # Sharp turn

            # Monitor vehicle dynamics
            yaw_rate = self.ds.get_variable('YawRate')
            lateral_accel = self.ds.get_variable('LateralAccel')
            esc_active = self.ds.get_can_signal('ESC_Status', 'ESC_Active')

            # Check if ESC activates
            if yaw_rate > 15.0 and not esc_active:
                # Vehicle is oversteering but ESC not active
                if t > 0.15:  # Allow for FTTI (150ms)
                    print(f"✗ FAIL: ESC did not activate (t={t:.2f}s, yaw={yaw_rate:.1f}°/s)")
                    self.test_results.append({
                        'test': 'Intervention_Oversteer',
                        'result': 'FAIL',
                        'reason': 'No activation during oversteer'
                    })
                    self.ds.stop_simulation()
                    return False

            if esc_active:
                print(f"✓ PASS: ESC activated at t={t:.2f}s")
                self.test_results.append({
                    'test': 'Intervention_Oversteer',
                    'result': 'PASS',
                    'activation_time': t
                })
                self.ds.stop_simulation()
                return True

            time.sleep(0.01)

        print("✗ FAIL: ESC never activated")
        self.test_results.append({
            'test': 'Intervention_Oversteer',
            'result': 'FAIL',
            'reason': 'No activation'
        })
        self.ds.stop_simulation()
        return False

    def test_safe_state_sensor_fault(self):
        """Verify safe state transition on sensor fault"""
        print("Test: Safe state on sensor fault...")

        self.ds.start_simulation()

        # Inject sensor fault
        self.ds.inject_fault('WheelSpeed_FL', fault_type='stuck_high')

        start_time = time.time()
        safe_state_entered = False

        for t in np.arange(0, 1, 0.01):
            # Read ECU status
            operating_mode = self.ds.get_can_signal('ESC_Status', 'OperatingMode')

            if operating_mode == 3:  # Safe state
                transition_time = (time.time() - start_time) * 1000  # ms
                print(f"✓ PASS: Safe state entered in {transition_time:.1f}ms")

                # Verify FTTI requirement
                if transition_time <= 150:
                    print(f"✓ PASS: FTTI requirement met ({transition_time:.1f}ms <= 150ms)")
                    self.test_results.append({
                        'test': 'Safe_State_Sensor_Fault',
                        'result': 'PASS',
                        'ftti_ms': transition_time
                    })
                else:
                    print(f"✗ FAIL: FTTI exceeded ({transition_time:.1f}ms > 150ms)")
                    self.test_results.append({
                        'test': 'Safe_State_Sensor_Fault',
                        'result': 'FAIL',
                        'reason': 'FTTI exceeded'
                    })

                safe_state_entered = True
                break

            time.sleep(0.01)

        self.ds.stop_simulation()
        self.ds.clear_faults()

        if not safe_state_entered:
            print("✗ FAIL: Safe state not entered")
            self.test_results.append({
                'test': 'Safe_State_Sensor_Fault',
                'result': 'FAIL',
                'reason': 'No safe state transition'
            })
            return False

        return True

    def generate_report(self):
        """Generate test report"""
        print("\n" + "="*60)
        print("HIL Test Report - ESC Safety Verification")
        print("="*60)

        total = len(self.test_results)
        passed = sum(1 for r in self.test_results if r['result'] == 'PASS')

        print(f"\nTotal Tests: {total}")
        print(f"Passed: {passed}")
        print(f"Failed: {total - passed}")
        print(f"Pass Rate: {(passed/total)*100:.1f}%\n")

        for result in self.test_results:
            status = "✓" if result['result'] == 'PASS' else "✗"
            print(f"{status} {result['test']}: {result['result']}")

        return passed == total

    def run_all_tests(self):
        """Execute all HIL tests"""
        self.setup()

        tests = [
            self.test_no_intervention_straight_driving,
            self.test_intervention_oversteer,
            self.test_safe_state_sensor_fault
        ]

        for test in tests:
            test()
            time.sleep(2)  # Delay between tests

        return self.generate_report()


if __name__ == "__main__":
    hil_test = HILTest_ESC()
    all_passed = hil_test.run_all_tests()

    if all_passed:
        print("\n✓ All HIL tests PASSED")
        exit(0)
    else:
        print("\n✗ Some HIL tests FAILED")
        exit(1)
```

## Back-to-Back Testing

### Model-Code Comparison

```matlab
% MATLAB/Simulink reference model
% ESC_ReferenceModel.m

function [control_level] = ESC_ReferenceModel(yaw_rate, lateral_accel)
    % Reference implementation in MATLAB
    YAW_THRESHOLD = 15.0;      % deg/s
    ACCEL_THRESHOLD = 0.4;     % g

    if yaw_rate > YAW_THRESHOLD
        if lateral_accel > ACCEL_THRESHOLD
            control_level = 3;
        else
            control_level = 2;
        end
    else
        if lateral_accel > ACCEL_THRESHOLD
            control_level = 1;
        else
            control_level = 0;
        end
    end
end

% Back-to-back test vectors
test_vectors = [
    % yaw_rate, lateral_accel, expected_output
    0.0, 0.0, 0;     % No intervention
    20.0, 0.2, 2;    % High yaw, low accel
    10.0, 0.5, 1;    % Low yaw, high accel
    20.0, 0.5, 3;    % High yaw, high accel
    15.0, 0.4, 2;    % Boundary values
];

% Run reference model
fprintf('Back-to-Back Test Results:\n');
fprintf('%-10s %-15s %-10s %-10s %-10s\n', 'Test', 'Inputs', 'Model', 'Code', 'Status');

for i = 1:size(test_vectors, 1)
    yaw = test_vectors(i, 1);
    accel = test_vectors(i, 2);
    expected = test_vectors(i, 3);

    % Run MATLAB model
    model_output = ESC_ReferenceModel(yaw, accel);

    % Run C code (via MEX or external call)
    code_output = ESC_CalculateControl_C(yaw, accel);

    % Compare outputs
    if model_output == code_output && model_output == expected
        status = 'PASS';
    else
        status = 'FAIL';
    end

    fprintf('TC-%d     (%.1f, %.1f)    %d          %d         %s\n', ...
            i, yaw, accel, model_output, code_output, status);
end
```

## Traceability Matrix

### Requirements Traceability

```sql
-- Traceability database schema
CREATE TABLE SafetyGoals (
    sg_id VARCHAR(50) PRIMARY KEY,
    description TEXT,
    asil VARCHAR(10),
    ftti_ms INT
);

CREATE TABLE FunctionalSafetyRequirements (
    fsr_id VARCHAR(50) PRIMARY KEY,
    sg_id VARCHAR(50) REFERENCES SafetyGoals(sg_id),
    description TEXT
);

CREATE TABLE TechnicalSafetyRequirements (
    tsr_id VARCHAR(50) PRIMARY KEY,
    fsr_id VARCHAR(50) REFERENCES FunctionalSafetyRequirements(fsr_id),
    description TEXT
);

CREATE TABLE SoftwareSafetyRequirements (
    swr_id VARCHAR(50) PRIMARY KEY,
    tsr_id VARCHAR(50) REFERENCES TechnicalSafetyRequirements(tsr_id),
    description TEXT,
    verification_method VARCHAR(100)
);

CREATE TABLE TestCases (
    tc_id VARCHAR(50) PRIMARY KEY,
    swr_id VARCHAR(50) REFERENCES SoftwareSafetyRequirements(swr_id),
    test_type VARCHAR(50),
    status VARCHAR(20),
    result VARCHAR(20)
);

-- Query: Generate traceability matrix
SELECT
    sg.sg_id,
    sg.description AS safety_goal,
    fsr.fsr_id,
    tsr.tsr_id,
    swr.swr_id,
    tc.tc_id,
    tc.result
FROM SafetyGoals sg
LEFT JOIN FunctionalSafetyRequirements fsr ON sg.sg_id = fsr.sg_id
LEFT JOIN TechnicalSafetyRequirements tsr ON fsr.fsr_id = tsr.fsr_id
LEFT JOIN SoftwareSafetyRequirements swr ON tsr.tsr_id = swr.tsr_id
LEFT JOIN TestCases tc ON swr.swr_id = tc.swr_id
WHERE sg.sg_id = 'SG-ESC-001'
ORDER BY sg.sg_id, fsr.fsr_id, tsr.tsr_id, swr.swr_id;
```

## Functional Safety Assessment

### Assessment Checklist

```yaml
assessment_id: "FSA-ESC-ECU-001"
item: "ESC Electronic Control Unit"
asil: "ASIL-D"
assessment_type: "Independent Safety Assessment"
assessor: "TÜV SÜD"
date: "2024-03-19"

part_2_management:
  - criterion: "Safety lifecycle defined"
    status: "COMPLIANT"
    evidence: "SAF-001: Safety Plan v1.5"

  - criterion: "Safety manager appointed"
    status: "COMPLIANT"
    evidence: "Org chart, training records"

  - criterion: "Safety culture established"
    status: "COMPLIANT"
    evidence: "Safety culture assessment report"

part_3_concept:
  - criterion: "Item definition complete"
    status: "COMPLIANT"
    evidence: "ITEM-ESC-001: Item Definition v2.0"

  - criterion: "HARA performed"
    status: "COMPLIANT"
    evidence: "HARA-ESC-001: 15 hazardous events analyzed"

  - criterion: "Safety goals defined"
    status: "COMPLIANT"
    evidence: "3 safety goals (ASIL-D, C, B)"

part_4_system:
  - criterion: "Technical safety concept"
    status: "COMPLIANT"
    evidence: "TSC-ESC-001: TSC v1.8"

  - criterion: "System architecture"
    status: "COMPLIANT"
    evidence: "ARCH-ESC-001: Architecture spec"

  - criterion: "Safety analysis (FMEA)"
    status: "COMPLIANT"
    evidence: "FMEA-ESC-HW-001, FMEA-ESC-SW-001"

part_5_hardware:
  - criterion: "Hardware safety requirements"
    status: "COMPLIANT"
    evidence: "HSR-ESC-001: 25 requirements"

  - criterion: "SPFM/LFM/PMHF calculated"
    status: "COMPLIANT"
    evidence: "FMEDA-ESC-001: SPFM=99.2%, LFM=92.5%, PMHF=8.5 FIT"

  - criterion: "Hardware metrics meet targets"
    status: "COMPLIANT"
    evidence: "All metrics within ASIL-D targets"

part_6_software:
  - criterion: "Software safety requirements"
    status: "COMPLIANT"
    evidence: "SWR-ESC-001: 44 requirements"

  - criterion: "MISRA compliance"
    status: "COMPLIANT"
    evidence: "Static analysis: 0 violations"

  - criterion: "Unit test MC/DC coverage"
    status: "COMPLIANT"
    evidence: "Coverage report: 100% MC/DC"

  - criterion: "Software safety manual"
    status: "COMPLIANT"
    evidence: "SSM-ESC-001: SW Safety Manual v1.0"

part_8_supporting:
  - criterion: "Configuration management"
    status: "COMPLIANT"
    evidence: "Git repository, version control procedures"

  - criterion: "Tool qualification"
    status: "COMPLIANT"
    evidence: "Compiler (GCC-ARM), Static analyzer (PC-Lint) qualified"

  - criterion: "Documentation"
    status: "COMPLIANT"
    evidence: "All work products present and reviewed"

verification_validation:
  - criterion: "Verification plan executed"
    status: "COMPLIANT"
    evidence: "VER-PLAN-ESC-001: All activities complete"

  - criterion: "Validation testing performed"
    status: "COMPLIANT"
    evidence: "VAL-REPORT-ESC-001: HIL testing 1000 hours"

  - criterion: "Safety goals validated"
    status: "COMPLIANT"
    evidence: "All 3 safety goals verified in target environment"

findings:
  - finding_id: "FSA-001"
    category: "Observation"
    description: "Traceability links between TSR and SWR could be improved"
    severity: "Minor"
    recommendation: "Add automated traceability tool"
    status: "Open"

  - finding_id: "FSA-002"
    category: "Observation"
    description: "Field monitoring process not fully defined"
    severity: "Minor"
    recommendation: "Document field data collection procedures"
    status: "Open"

conclusion:
  overall_assessment: "POSITIVE"
  recommendation: "Release for production"
  conditions:
    - "Address findings FSA-001 and FSA-002 before SOP"
    - "Maintain configuration management during production"
  next_assessment: "After 1 year of production (field monitoring review)"
```

## Production Checklist

### Verification & Validation Sign-Off

- [ ] Requirements reviews completed (all levels)
- [ ] Design reviews completed (all levels)
- [ ] Static analysis performed (0 critical violations)
- [ ] Unit testing completed (100% MC/DC for ASIL-D)
- [ ] Integration testing completed (all interfaces)
- [ ] System testing completed (all requirements)
- [ ] HIL testing completed (> 1000 hours for ASIL-D)
- [ ] Fault injection testing completed
- [ ] Back-to-back testing completed (model vs code)
- [ ] Traceability matrix complete (SG → TC)
- [ ] Safety analysis verified (FMEA/FTA)
- [ ] Hardware metrics verified (SPFM/LFM/PMHF)
- [ ] Safety manual reviewed and approved
- [ ] Independent safety assessment passed
- [ ] Release for production authorized

## References

- ISO 26262-4:2018 - Product Development at System Level
- ISO 26262-8:2018 - Supporting Processes (Verification)
- ISO 26262-11:2018 - Semiconductors (Validation)
- dSPACE HIL Testing Guide
- AUTOSAR Methodology
- Mutation Testing Handbook

## Related Skills

- ISO 26262 Overview
- FMEA/FTA Analysis
- Software Safety Requirements
- Safety Mechanisms and Patterns
- Hardware Safety Requirements

---

## Software Safety Requirements

# Software Safety Requirements - ISO 26262 Part 6

Comprehensive guidance on ASIL-D software development per ISO 26262-6, including safety requirements specification, architectural design, unit implementation, MISRA C/C++ compliance, MC/DC testing, and software safety manual creation.

## Software Development V-Model

```
┌────────────────────────────────────────────────────────────┐
│         Software Safety Requirements (Part 6-6)            │
│  • Derived from Technical Safety Concept                   │
│  • ASIL classification                                     │
│  • Verification criteria                                   │
└───────────────┬────────────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│         Software Architectural Design (Part 6-7)           │
│  • Hierarchical structure                                  │
│  • Component interfaces                                    │
│  • Resource constraints                                    │
└───────────────┬────────────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│         Software Unit Design (Part 6-8)                    │
│  • Detailed design per unit                                │
│  • Algorithms and data structures                          │
│  • Static analysis                                         │
└───────────────┬────────────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│         Software Unit Implementation (Part 6-9)            │
│  • Coding per MISRA guidelines                             │
│  • Code reviews                                            │
│  • Static analysis                                         │
└───────────────┬────────────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│         Software Unit Testing (Part 6-10)                  │
│  • MC/DC coverage (ASIL-D)                                 │
│  • Requirements-based tests                                │
│  • Back-to-back testing                                    │
└───────────────┬────────────────────────────────────────────┘
                │
                ▼
┌────────────────────────────────────────────────────────────┐
│         Software Integration Testing (Part 6-11)           │
│  • Interface testing                                       │
│  • Resource usage verification                             │
│  • Fault injection                                         │
└────────────────────────────────────────────────────────────┘
```

## Software Safety Requirements

### Requirement Structure

**Good Safety Requirement (SMART):**
- **Specific**: Unambiguous, single interpretation
- **Measurable**: Testable/verifiable
- **Achievable**: Technically feasible
- **Relevant**: Traceable to safety goal
- **Time-bound**: Response time specified

**Example Requirements:**

```yaml
swr_id: "SWR-ESC-001"
title: "Wheel Speed Sensor Range Check"
derived_from: "TSR-ESC-001"  # Technical Safety Requirement
asil: "ASIL-D"
safety_goal: "SG-ESC-001 (Prevent unintended ESC activation)"

description: |
  The software shall validate that each wheel speed sensor value is within
  the physically possible range before using it in vehicle dynamics calculations.

precondition: "Wheel speed sensor data received via CAN"

requirements:
  - id: "SWR-ESC-001.1"
    text: "The software SHALL reject wheel speed values < 0 km/h"
    rationale: "Negative speed is physically impossible"
    verification: "Unit test with negative input"

  - id: "SWR-ESC-001.2"
    text: "The software SHALL reject wheel speed values > 350 km/h"
    rationale: "Exceeds maximum vehicle speed by 50% margin"
    verification: "Unit test with excessive input"

  - id: "SWR-ESC-001.3"
    text: "The software SHALL set a fault flag if invalid speed detected"
    rationale: "Enable diagnostic monitoring"
    verification: "Verify flag state after invalid input"

  - id: "SWR-ESC-001.4"
    text: "The software SHALL use last valid speed value if current invalid"
    rationale: "Maintain functionality while rejecting invalid data"
    verification: "Integration test with fault injection"

  - id: "SWR-ESC-001.5"
    text: "The software SHALL transition to safe state if > 3 consecutive invalid readings"
    rationale: "Persistent fault indicates sensor failure"
    verification: "System test with sustained fault"

timing:
  execution_time_max_us: 50
  deadline_ms: 10
  period_ms: 10

safety_mechanism: "SM-ESC-004 (Range Check)"
interfaces:
  input: "CAN message ESC_WheelSpeeds (ID 0x200)"
  output: "Internal variable wheel_speed_fl_valid"

verification_methods:
  - Requirements-based test
  - Boundary value analysis
  - Fault injection test
  - MC/DC coverage

acceptance_criteria:
  - All requirements verified with tests
  - MC/DC coverage >= 100%
  - Static analysis: 0 violations
  - Code review: approved
```

### Requirements Traceability

```
Safety Goal (SG)
    │
    ├─> Functional Safety Requirement (FSR)
    │       │
    │       ├─> Technical Safety Requirement (TSR)
    │       │       │
    │       │       ├─> Software Safety Requirement (SWR)
    │       │       │       │
    │       │       │       ├─> Software Unit (SW-U)
    │       │       │       │       │
    │       │       │       │       └─> Unit Test Case (UTC)
    │       │       │       │
    │       │       │       └─> Integration Test Case (ITC)
    │       │       │
    │       │       └─> System Test Case (STC)
    │       │
    │       └─> Validation Test Case (VTC)
```

## Software Architecture

### ASIL-D Architecture Patterns

**1. Freedom from Interference**

```c
// Memory partitioning for ASIL-D
typedef struct {
    // ASIL-D partition (protected)
    uint8_t safety_data[1024] __attribute__((section(".safety_ram")));

    // QM partition (separate)
    uint8_t qm_data[4096] __attribute__((section(".qm_ram")));
} MemoryPartitions_t;

// MPU configuration (ARM Cortex-M)
void ConfigureMemoryProtection(void) {
    // Region 0: Safety-critical code (read-only, execute)
    MPU->RBAR = SAFETY_CODE_BASE | MPU_REGION_VALID | 0;
    MPU->RASR = MPU_RASR_ENABLE | MPU_RASR_XN_DISABLE |
                MPU_RASR_AP_RO | MPU_SIZE_64KB;

    // Region 1: Safety-critical data (read-write, no execute)
    MPU->RBAR = SAFETY_DATA_BASE | MPU_REGION_VALID | 1;
    MPU->RASR = MPU_RASR_ENABLE | MPU_RASR_XN_ENABLE |
                MPU_RASR_AP_RW | MPU_SIZE_16KB;

    // Region 2: QM code (separate partition)
    MPU->RBAR = QM_CODE_BASE | MPU_REGION_VALID | 2;
    MPU->RASR = MPU_RASR_ENABLE | MPU_RASR_XN_DISABLE |
                MPU_RASR_AP_RO | MPU_SIZE_128KB;

    // Enable MPU
    MPU->CTRL = MPU_CTRL_ENABLE | MPU_CTRL_PRIVDEFENA;
}
```

**2. Timing and Scheduling**

```c
// ASIL-D task configuration (AUTOSAR OS)
TASK(SafetyCriticalTask) {
    const uint32_t WCET_US = 500;  // Worst-Case Execution Time
    const uint32_t DEADLINE_MS = 10;

    uint32_t start_time = GetTimestamp_us();

    // Execute safety-critical function
    ESC_SafetyFunction();

    uint32_t execution_time = GetTimestamp_us() - start_time;

    // Verify timing constraints
    if (execution_time > WCET_US) {
        SetDTC(DTC_TIMING_VIOLATION);
        EnterSafeState();
    }

    TerminateTask();
}

// Task scheduling configuration
const TaskConfigType SafetyCriticalTaskConfig = {
    .priority = 255,  // Highest priority
    .activation = PERIODIC,
    .period_ms = 10,
    .deadline_ms = 10,
    .stack_size = 2048,
    .partition = SAFETY_PARTITION
};
```

**3. Software Component Structure**

```c
// Software component interface (AUTOSAR SWC)
typedef struct {
    // Inputs (ports)
    float wheel_speed_fl;
    float wheel_speed_fr;
    float wheel_speed_rl;
    float wheel_speed_rr;
    float yaw_rate;
    float lateral_accel;

    // Outputs (ports)
    float brake_pressure_fl;
    float brake_pressure_fr;
    float brake_pressure_rl;
    float brake_pressure_rr;
    bool esc_active;

    // Mode management
    ESC_ModeType operating_mode;

    // Fault status
    uint32_t fault_flags;
} ESC_Component_t;

// Runnable function
void ESC_MainFunction(void) {
    ESC_Component_t *component = GetESCComponent();

    // 1. Input validation
    if (!ValidateInputs(component)) {
        component->operating_mode = ESC_MODE_SAFE_STATE;
        SetSafeOutputs(component);
        return;
    }

    // 2. Mode management
    switch (component->operating_mode) {
        case ESC_MODE_NORMAL:
            ESC_NormalOperation(component);
            break;

        case ESC_MODE_DEGRADED:
            ESC_DegradedOperation(component);
            break;

        case ESC_MODE_SAFE_STATE:
            ESC_SafeState(component);
            break;

        default:
            // Invalid mode - enter safe state
            component->operating_mode = ESC_MODE_SAFE_STATE;
            SetDTC(DTC_INVALID_MODE);
            break;
    }

    // 3. Output validation
    ValidateOutputs(component);
}
```

## MISRA C/C++ Compliance

### MISRA C:2012 Critical Rules for ASIL-D

**Mandatory Rules (Must follow):**

```c
// Rule 1.3: No undefined behavior
// BAD: Integer overflow undefined
int32_t bad_add(int32_t a, int32_t b) {
    return a + b;  // ✗ May overflow
}

// GOOD: Check for overflow
int32_t safe_add(int32_t a, int32_t b, bool *overflow) {
    if ((b > 0) && (a > (INT32_MAX - b))) {
        *overflow = true;
        return INT32_MAX;
    }
    if ((b < 0) && (a < (INT32_MIN - b))) {
        *overflow = true;
        return INT32_MIN;
    }
    *overflow = false;
    return a + b;
}

// Rule 2.2: Dead code shall be removed
// BAD: Unreachable code
void bad_function(bool condition) {
    if (condition) {
        return;
    }
    DoSomething();  // ✗ Dead code if condition always true
    return;
}

// GOOD: No dead code
void good_function(bool condition) {
    if (!condition) {
        DoSomething();
    }
}

// Rule 8.13: Pointer should be const if not modified
// BAD: Missing const
void bad_process(uint8_t *data) {  // ✗ data not modified but not const
    uint8_t value = data[0];
    UseValue(value);
}

// GOOD: Const pointer
void good_process(const uint8_t *data) {
    uint8_t value = data[0];
    UseValue(value);
}

// Rule 9.1: Use before initialization
// BAD: Uninitialized variable
void bad_init(void) {
    uint32_t value;
    if (SomeCondition()) {
        value = 42;
    }
    UseValue(value);  // ✗ May be uninitialized
}

// GOOD: Always initialized
void good_init(void) {
    uint32_t value = 0;  // Default initialization
    if (SomeCondition()) {
        value = 42;
    }
    UseValue(value);
}

// Rule 21.3: malloc/free shall not be used
// BAD: Dynamic memory
void bad_alloc(void) {
    uint8_t *buffer = (uint8_t *)malloc(100);  // ✗ Not allowed
    free(buffer);
}

// GOOD: Static allocation
#define BUFFER_SIZE 100
void good_alloc(void) {
    uint8_t buffer[BUFFER_SIZE];  // Static allocation
    ProcessBuffer(buffer, BUFFER_SIZE);
}
```

### MISRA C++ Specific Rules

```cpp
// Rule A5-1-2: Use nullptr instead of NULL
// BAD: NULL macro
void bad_pointer(void) {
    int *ptr = NULL;  // ✗ Old C style
}

// GOOD: nullptr
void good_pointer(void) {
    int *ptr = nullptr;  // ✓ C++11 style
}

// Rule A10-0-2: Virtual destructor for base class
// BAD: Missing virtual destructor
class BadBase {  // ✗ No virtual destructor
public:
    void DoSomething();
};

// GOOD: Virtual destructor
class GoodBase {
public:
    virtual ~GoodBase() = default;  // ✓ Virtual destructor
    virtual void DoSomething();
};

// Rule A15-5-1: Exception specifications
// BAD: Throwing exceptions in safety code
void bad_exception(void) {
    throw std::runtime_error("Error");  // ✗ Exceptions not allowed ASIL-D
}

// GOOD: Error codes
enum class ErrorCode {
    SUCCESS,
    INVALID_INPUT,
    TIMEOUT
};

ErrorCode good_error_handling(void) {
    if (InvalidInput()) {
        return ErrorCode::INVALID_INPUT;
    }
    return ErrorCode::SUCCESS;
}
```

### Static Analysis Configuration

**.misra_config.txt (for PC-Lint/Flexelint):**
```
// MISRA C:2012 rules for ASIL-D
+misra(2012)

// Mandatory rules
-strong(AXJ)  // All rules from Advisory to Required to Mandatory

// Specific rule configuration
-esym(960, 1.3)   // Enable: No undefined behavior
-esym(960, 2.2)   // Enable: No dead code
-esym(960, 8.13)  // Enable: Pointer to const
-esym(960, 9.1)   // Enable: No uninitialized variables
-esym(960, 21.3)  // Enable: No dynamic memory

// Project-specific deviations (requires justification)
-elib(960)        // Suppress for library code
```

## Unit Testing - MC/DC Coverage

### Modified Condition/Decision Coverage (MC/DC)

**Definition:** Every condition in a decision independently affects the outcome.

**Example:**

```c
// Function to test
bool ESC_ShouldActivate(float yaw_rate, float lateral_accel, bool driver_input) {
    // Decision with 3 conditions (A, B, C)
    if ((yaw_rate > THRESHOLD_YAW) &&        // Condition A
        (lateral_accel > THRESHOLD_ACCEL) && // Condition B
        (!driver_input))                     // Condition C
    {
        return true;
    }
    return false;
}

// MC/DC Test Cases
void test_mcdc_coverage(void) {
    // Truth table with MC/DC coverage
    // TC | A | B | C | Result | Covers
    // ---+---+---+---+--------+--------
    //  1 | F | F | F |   F    | -
    //  2 | T | F | F |   F    | A (vs TC4)
    //  3 | F | T | F |   F    | B (vs TC4)
    //  4 | T | T | F |   T    | baseline
    //  5 | T | T | T |   F    | C (vs TC4)

    // Test Case 1: All false
    assert(ESC_ShouldActivate(0.0, 0.0, false) == false);

    // Test Case 2: Only A true (tests A independence)
    assert(ESC_ShouldActivate(10.0, 0.0, false) == false);

    // Test Case 3: Only B true (tests B independence)
    assert(ESC_ShouldActivate(0.0, 10.0, false) == false);

    // Test Case 4: A and B true, C false (baseline true)
    assert(ESC_ShouldActivate(10.0, 10.0, false) == true);

    // Test Case 5: All true but C negated (tests C independence)
    assert(ESC_ShouldActivate(10.0, 10.0, true) == false);

    // MC/DC coverage: 100% ✓
}
```

### Unit Test Framework (Unity)

```c
// test_esc_range_check.c
#include "unity.h"
#include "esc_sensor.h"

void setUp(void) {
    // Called before each test
    ESC_Init();
}

void tearDown(void) {
    // Called after each test
    ESC_Deinit();
}

// Test: Valid speed accepted
void test_valid_speed_accepted(void) {
    float speed = 100.0f;  // Valid: 0-350 km/h
    bool result = ESC_ValidateWheelSpeed(speed);
    TEST_ASSERT_TRUE(result);
}

// Test: Negative speed rejected
void test_negative_speed_rejected(void) {
    float speed = -10.0f;  // Invalid: < 0
    bool result = ESC_ValidateWheelSpeed(speed);
    TEST_ASSERT_FALSE(result);
}

// Test: Excessive speed rejected
void test_excessive_speed_rejected(void) {
    float speed = 400.0f;  // Invalid: > 350
    bool result = ESC_ValidateWheelSpeed(speed);
    TEST_ASSERT_FALSE(result);
}

// Test: Boundary value (low)
void test_boundary_low(void) {
    float speed = 0.0f;  // Boundary: exactly 0
    bool result = ESC_ValidateWheelSpeed(speed);
    TEST_ASSERT_TRUE(result);
}

// Test: Boundary value (high)
void test_boundary_high(void) {
    float speed = 350.0f;  // Boundary: exactly max
    bool result = ESC_ValidateWheelSpeed(speed);
    TEST_ASSERT_TRUE(result);
}

// Test: Fault flag set on invalid input
void test_fault_flag_on_invalid(void) {
    float speed = -10.0f;
    ESC_ValidateWheelSpeed(speed);
    TEST_ASSERT_TRUE(ESC_IsFaultFlagSet(FAULT_WHEEL_SPEED_INVALID));
}

// Test: Safe state after persistent faults
void test_safe_state_persistent_fault(void) {
    // Inject 4 consecutive invalid readings
    for (int i = 0; i < 4; i++) {
        ESC_ValidateWheelSpeed(-10.0f);
    }
    TEST_ASSERT_EQUAL(ESC_MODE_SAFE_STATE, ESC_GetMode());
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_valid_speed_accepted);
    RUN_TEST(test_negative_speed_rejected);
    RUN_TEST(test_excessive_speed_rejected);
    RUN_TEST(test_boundary_low);
    RUN_TEST(test_boundary_high);
    RUN_TEST(test_fault_flag_on_invalid);
    RUN_TEST(test_safe_state_persistent_fault);
    return UNITY_END();
}
```

### Coverage Report

```bash
# Run tests with coverage (gcov/lcov)
gcc -fprofile-arcs -ftest-coverage -o test_esc test_esc.c esc_sensor.c
./test_esc
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_html

# Coverage report:
# File: esc_sensor.c
# Lines: 98.5% (65/66)
# Functions: 100% (8/8)
# Branches: 100% (24/24)  ← MC/DC coverage
# MC/DC: 100% ✓ (ASIL-D requirement met)
```

## Software Safety Manual

### Template

```markdown
# Software Safety Manual
# ESC Electronic Control Unit
# Version 1.0
# ASIL-D

## 1. Introduction

### 1.1 Scope
This Software Safety Manual describes the safety-related aspects of the
ESC (Electronic Stability Control) ECU software version 2.5.0, developed
in accordance with ISO 26262-6:2018 for ASIL-D integrity level.

### 1.2 Intended Use
The software is designed for use in passenger vehicles (M1 category) with:
- Maximum gross weight: 3500 kg
- Maximum speed: 200 km/h
- Operating temperature: -40°C to +85°C

## 2. Safety Concept

### 2.1 Safety Goals
- SG-ESC-001: Prevent unintended ESC activation (ASIL-D)
- SG-ESC-002: ESC shall activate when stability compromised (ASIL-C)
- SG-ESC-003: ESC response time < 100ms (ASIL-B)

### 2.2 Software Safety Requirements
See Section 5 for complete list (45 requirements, all verified).

## 3. Assumptions and Dependencies

### 3.1 Hardware Assumptions
- Dual-core lockstep microcontroller (TMS570LC4357)
- ECC-protected RAM (SECDED capable)
- Watchdog timer with window monitoring
- CAN controller with error detection

### 3.2 Integration Assumptions
- CAN bus operates at 500 kbps
- Wheel speed sensors provide updates every 10ms
- Supply voltage: 9V to 16V nominal

### 3.3 Environmental Assumptions
- Road surface friction coefficient: 0.1 to 1.0
- Vehicle speed: 0 to 200 km/h
- Tire pressure: 1.8 to 3.0 bar

## 4. Safety Mechanisms

### 4.1 Implemented Safety Mechanisms
| ID | Description | Coverage |
|----|-------------|----------|
| SM-ESC-001 | Dual-core lockstep | 99.9% |
| SM-ESC-002 | ECC on RAM | 99.99% |
| SM-ESC-003 | Window watchdog | 95.0% |
| SM-ESC-004 | Range checks | 90.0% |
| SM-ESC-005 | CRC on CAN | 99.998% |

### 4.2 Diagnostic Coverage
- SPFM: 99.2% (target: > 99%) ✓
- LFM: 92.5% (target: > 90%) ✓
- PMHF: 8.5 FIT (target: < 10 FIT) ✓

## 5. Known Limitations

### 5.1 Functional Limitations
- ESC disabled when vehicle speed < 10 km/h
- ESC functionality reduced with 1 failed wheel speed sensor
- ESC deactivated in reverse gear

### 5.2 Performance Limitations
- Maximum yaw rate: ±100°/s
- Maximum lateral acceleration: ±1.5g
- Response time: 50-100ms (depends on sensor update rate)

## 6. Safe States

### 6.1 Safe State Definition
- All brake modulation disabled
- Manual brake control available
- Warning lamp activated
- DTC stored in non-volatile memory

### 6.2 Transition Conditions
- Lockstep mismatch detected
- Persistent sensor failure (> 3 consecutive)
- Watchdog timeout
- Critical software error detected

## 7. Integration Guidelines

### 7.1 Configuration Parameters
```c
#define ESC_YAW_THRESHOLD_DEG_S     (15.0f)
#define ESC_LATERAL_ACCEL_THRESHOLD_G (0.4f)
#define ESC_FTTI_MS                 (150)
#define ESC_SENSOR_TIMEOUT_MS       (100)
```

### 7.2 Calibration Requirements
- Parameters must be calibrated for specific vehicle platform
- Validation testing required after calibration changes
- Safety-critical parameters protected by CRC

## 8. Verification Evidence

### 8.1 Testing Summary
- Unit tests: 487 test cases, 100% MC/DC coverage
- Integration tests: 125 test cases, all passed
- System tests: 45 test cases, all passed
- HIL testing: 1000 hours, 0 safety-critical failures

### 8.2 Static Analysis
- MISRA C:2012 compliance: 100% (0 deviations)
- Cyclomatic complexity: Max 8 (target: < 10)
- Code review: All modules approved

## 9. Maintenance and Support

### 9.1 Software Updates
- Updates require full regression testing
- Safety assessment required for any safety-critical change
- Version control: Git with signed commits

### 9.2 Field Monitoring
- DTC monitoring via diagnostic interface
- Software version readable via OBD-II
- Field failure data collection mandatory

## 10. References
- ISO 26262-6:2018 - Software Development
- MISRA C:2012 - Guidelines for C
- ESC_SWR_v2.5.pdf - Software Safety Requirements
- ESC_TestReport_v2.5.pdf - Verification Report
```

## Production Checklist

### ASIL-D Software Development

- [ ] Software safety requirements defined and reviewed
- [ ] Architecture designed with freedom from interference
- [ ] MISRA C/C++ compliance verified (100%)
- [ ] Static analysis performed (0 critical violations)
- [ ] Unit tests achieve MC/DC coverage (100%)
- [ ] Integration tests cover all interfaces
- [ ] Timing analysis performed (WCET verified)
- [ ] Memory usage analyzed (stack/heap within limits)
- [ ] Code reviews completed (all units)
- [ ] Back-to-back testing (model vs code) performed
- [ ] Software safety manual completed
- [ ] Tool qualification performed (compiler, static analyzer)
- [ ] Configuration management in place
- [ ] Independent software assessment passed

## References

- ISO 26262-6:2018 - Product Development at Software Level
- ISO 26262-8:2018 - Supporting Processes
- MISRA C:2012 - Guidelines for the Use of C
- MISRA C++:2008 - Guidelines for C++
- AUTOSAR Coding Guidelines
- DO-178C - Software Considerations in Airborne Systems (reference)

## Related Skills

- ISO 26262 Overview
- Safety Mechanisms and Patterns
- FMEA/FTA Analysis
- Safety Verification and Validation
- MISRA C Coding Guidelines

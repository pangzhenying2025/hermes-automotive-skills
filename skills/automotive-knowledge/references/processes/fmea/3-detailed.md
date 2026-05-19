# FMEA - Detailed Execution Guide

## DFMEA Worksheet Walkthrough

### Complete FMEA Form Structure

```
┌──────────────────────────────────────────────────────────────────────┐
│ DESIGN FMEA (DFMEA)                                                  │
├──────────────────────────────────────────────────────────────────────┤
│ System: Battery Management System ECU        FMEA Date: 2026-03-15  │
│ Subsystem: Cell Monitoring Circuit           Team: Hardware Design   │
│ FMEA ID: DFMEA-BMS-001                       Revision: 1.2          │
└──────────────────────────────────────────────────────────────────────┘
```

| Item/Function | Potential Failure Mode | Potential Effects | S | Potential Causes | O | Current Controls | D | RPN | Recommended Actions | Actions Taken | S' | O' | D' | RPN' |
|--------------|----------------------|------------------|---|----------------|---|-----------------|---|-----|-------------------|--------------|----|----|----|----- |
| Cell voltage sensing | Incorrect voltage reading | Cell overcharge leading to thermal runaway | 10 | ADC calibration drift | 4 | Annual calibration check | 6 | 240 | Add runtime ADC self-test | Implemented self-test every 10s | 10 | 2 | 3 | 60 |

### Column Definitions

#### Item/Function
The component or function being analyzed.

**Best Practices**:
- Use functional decomposition (system → subsystem → component → function)
- One row per failure mode, not per item
- Be specific: "Cell voltage sensing" not "ADC"

**Examples**:
- "Battery contactor control circuit"
- "Charge current calculation algorithm"
- "CAN communication interface"
- "Temperature sensor input conditioning"

#### Potential Failure Mode
How the function could fail to perform its intended purpose.

**Failure Mode Types**:
1. **Total failure**: Component ceases to function
2. **Partial/degraded failure**: Function operates outside specification
3. **Intermittent failure**: Function fails sporadically
4. **Unintended function**: Function operates when it shouldn't

**Examples**:
- "Contactor stuck closed"
- "Current measurement offset by +5A"
- "CAN message timeout"
- "Temperature reading freezes at last value"

**Avoid Vague Descriptions**:
- Bad: "Failure"
- Good: "Output voltage exceeds 5.2V"

- Bad: "Doesn't work"
- Good: "No response to shutdown command"

#### Potential Effects (of Failure)
Consequences of the failure mode on the end user, vehicle, or system.

**Effect Hierarchy**:
1. **Local effect**: Impact on immediate component/function
2. **Next-level effect**: Impact on subsystem
3. **End effect**: Impact on vehicle/user (use this for Severity rating)

**Example Chain**:
```
Failure Mode: Cell voltage sensor reads 10% high
  ↓ Local Effect
Cell appears healthier than actual
  ↓ Next-Level Effect
BMS does not trigger cell balancing
  ↓ End Effect (use for Severity)
Cell capacity degrades, reduced vehicle range
```

**Writing Effective Effects**:
- Focus on what the user/operator experiences
- Include safety, compliance, and operational impacts
- Quantify where possible: "Range reduced by 15%" vs. "Reduced range"

#### Severity (S)
Seriousness of the effect on the end user. Scale: 1-10.

**AIAG FMEA Severity Criteria**:

| Rating | Effect | Criteria |
|--------|--------|----------|
| 10 | Hazardous without warning | Safety critical failure without warning, violates regulations |
| 9 | Hazardous with warning | Safety critical failure with warning |
| 8 | Very high | Vehicle inoperable, loss of primary function |
| 7 | High | Vehicle operable but significantly degraded performance |
| 6 | Moderate | Moderate degradation of performance |
| 5 | Low | Low degradation of performance |
| 4 | Very low | Minor inconvenience |
| 3 | Minor | Noticeable but minimal impact |
| 2 | Very minor | Most customers won't notice |
| 1 | None | No discernible effect |

**Examples**:

**S=10**: Cell thermal runaway causing fire (safety hazard, no warning)
**S=9**: Cell thermal runaway with prior warning alarm (safety hazard with warning)
**S=8**: Battery system shutdown preventing vehicle operation
**S=7**: 50% power reduction, vehicle limps home
**S=6**: 20% range reduction
**S=4**: Delayed response to charge start command (2-second delay)
**S=2**: Minor GUI display glitch on battery icon

**Key Rule**: Severity cannot be reduced by design changes in current FMEA; only by fundamental redesign creating new FMEA.

#### Potential Causes
Root causes that lead to the failure mode.

**Cause Categories**:
1. **Design deficiency**: Inadequate specification, analysis error
2. **Manufacturing variation**: Tolerance stack-up, process capability
3. **Environmental stress**: Temperature, vibration, humidity
4. **Degradation over time**: Wear-out, aging, corrosion
5. **Usage/abuse**: Incorrect operation, overload

**Examples**:
- "ADC reference voltage drift due to component aging"
- "Solder joint crack from thermal cycling"
- "Software race condition in interrupt handler"
- "Electromagnetic interference from ignition system"

**Be Specific**:
- Bad: "Component failure"
- Good: "MOSFET gate oxide breakdown from ESD event"

**Root Cause Analysis**:
Use 5 Whys technique:
```
Failure Mode: CAN message timeout
  Why? CAN controller stopped transmitting
    Why? Software entered infinite loop
      Why? Watchdog timer not configured
        Why? Configuration step missing from init sequence
          Why? Design review did not catch missing step
            → Root Cause: Inadequate design review checklist
```

#### Occurrence (O)
Frequency of the cause occurring. Scale: 1-10.

**AIAG FMEA Occurrence Criteria**:

| Rating | Probability | Failure Rate (ppm) | Cpk |
|--------|------------|-------------------|-----|
| 10 | Very high: Failure almost inevitable | ≥ 100,000 (≥10%) | < 0.55 |
| 9 | | 50,000 (5%) | 0.55 |
| 8 | High: Repeated failures | 20,000 (2%) | 0.78 |
| 7 | | 10,000 (1%) | 0.86 |
| 6 | Moderate: Occasional failures | 2,000 (0.2%) | 1.00 |
| 5 | | 500 (0.05%) | 1.10 |
| 4 | Low: Relatively few failures | 100 (0.01%) | 1.20 |
| 3 | | 20 (0.002%) | 1.30 |
| 2 | Remote: Failure unlikely | 2 (0.0002%) | 1.67 |
| 1 | Nearly impossible | < 0.01 (< 1 in 10M) | > 1.67 |

**Estimation Methods**:

**Historical Data**:
"In previous BMS design, ADC calibration drift occurred in 3 of 5,000 units over 5 years" → 600 ppm → O=5

**Supplier Data**:
"Capacitor manufacturer specifies 0.1% annual drift rate" → 1,000 ppm → O=6

**Accelerated Testing**:
"Thermal cycling test: 2 failures in 1,000 cycles" → 2,000 ppm → O=6

**Engineering Judgment** (when no data available):
Use experience and physics of failure analysis, but document assumptions.

**Key Point**: Occurrence rates the likelihood of the **cause**, not the failure mode itself.

#### Current Design Controls
Existing measures to prevent the cause or detect the failure mode.

**Control Types**:

**Prevention Controls** (reduce Occurrence):
- Design margins (derating, safety factors)
- Design verification tests (DVT)
- Design rules and standards compliance
- Supplier quality requirements
- Redundancy, fault tolerance

**Detection Controls** (reduce Detection):
- Built-in self-test (BIST)
- Diagnostic Trouble Codes (DTCs)
- Production end-of-line testing
- In-use monitoring and warnings
- Design validation tests

**Examples**:
- **Prevention**: "ADC uses 0.1% tolerance voltage reference with 2× margin"
- **Detection**: "Self-test compares ADC reading to known reference every 10s"
- **Both**: "Dual redundant sensors with cross-check voting algorithm"

**Document Current State Only**:
List only controls already implemented or committed for current design. Do not list planned future actions here (those go in Recommended Actions).

#### Detection (D)
Likelihood that current controls will detect the cause or failure mode before it reaches the customer. Scale: 1-10.

**AIAG FMEA Detection Criteria**:

| Rating | Detection | Criteria | Examples |
|--------|-----------|----------|----------|
| 10 | Absolute uncertainty | No known detection method | No test, inherently undetectable |
| 9 | Very remote | Very remote chance of detection | Random inspection |
| 8 | Remote | Remote chance of detection | Manual inspection, subjective |
| 7 | Very low | Very low chance of detection | Manual inspection with go/no-go gauge |
| 6 | Low | Low chance of detection | 100% manual inspection |
| 5 | Moderate | Moderate chance of detection | Statistical sampling (SPC) |
| 4 | Moderately high | Automated detection with manual backup | Error-proofing with override |
| 3 | High | Automated detection | 100% automated in-station testing |
| 2 | Very high | Automated detection with fail-safe | Self-diagnostic with lockout |
| 1 | Almost certain | Defect physically cannot reach customer | Design prevents failure mode |

**Examples**:

**D=1**: Cell voltage out-of-range physically impossible (clamping diodes)
**D=2**: Real-time self-test detects ADC error, system enters safe mode
**D=3**: End-of-line test validates every ADC channel against reference
**D=5**: Periodic calibration check during service intervals
**D=7**: Visual inspection of solder joints during manufacturing
**D=9**: No validation of algorithm under all operating conditions
**D=10**: Intermittent software race condition, no test coverage

**Key Principle**: Detection rating decreases (better) as detection becomes earlier in the lifecycle and more certain.

### Risk Priority Number (RPN)

**Calculation**:
```
RPN = Severity (S) × Occurrence (O) × Detection (D)
```

**Range**: 1 to 1,000

**RPN Thresholds** (guidelines vary by organization):
- **RPN ≥ 500**: Immediate action required
- **RPN 200-499**: Action should be prioritized
- **RPN 100-199**: Action should be considered
- **RPN < 100**: Monitor, action optional

**Example**:
```
Failure Mode: Cell overvoltage due to charge control failure
S = 10 (thermal runaway risk)
O = 4  (rare, based on field data)
D = 6  (detected by periodic functional test)
RPN = 10 × 4 × 6 = 240 → Action recommended
```

**Important**: High Severity (S=9 or 10) items require action **regardless of RPN**.

## Action Priority

**Decision Matrix**:

| Severity | Action Required |
|----------|----------------|
| S = 10 | Always require actions to reduce S, O, or D |
| S = 9 | Always require actions to reduce S, O, or D |
| S = 7-8 | Require actions if RPN ≥ 100 or O ≥ 6 |
| S ≤ 6 | Require actions if RPN ≥ 200 |

**Alternative: Action Priority (AP) Table** (newer AIAG FMEA):

Uses (S, O, D) lookup table instead of multiplying:

| S | O | D | AP |
|---|---|---|-----|
| 10 | Any | Any | High |
| 9 | ≥6 | Any | High |
| 7-8 | ≥6 | ≥6 | Medium |
| ≤6 | ≥6 | ≥8 | Low |

AP replaces RPN in newer FMEA standards.

## Recommended Actions

Actions to reduce Severity, Occurrence, or Detection.

### Reducing Severity

**Approaches**:
1. Design out hazardous condition (e.g., intrinsically safe design)
2. Add containment (e.g., fusing, pressure relief)
3. Warnings and fail-safes

**Examples**:
- "Add hardware overvoltage clamp to prevent cell voltage > 4.3V"
- "Implement current limiting in contactor control to prevent welding"

**Note**: Severity reduction often requires fundamental design change, may create new FMEA.

### Reducing Occurrence

**Approaches**:
1. Eliminate cause (e.g., better component selection)
2. Reduce cause frequency (e.g., environmental protection)
3. Add prevention controls (e.g., design margin)

**Examples**:
- "Replace aluminum electrolytic capacitor with ceramic (eliminates drift)"
- "Add conformal coating to prevent moisture-induced corrosion"
- "Increase voltage reference tolerance from 1% to 0.1%"

### Reducing Detection

**Approaches**:
1. Add automated detection (e.g., BIST)
2. Improve test coverage (e.g., extended DVT)
3. Earlier detection (e.g., move from service to run-time)

**Examples**:
- "Implement ADC self-test by sampling known reference voltage"
- "Add boundary scan (JTAG) testing to detect solder opens"
- "Enhance EOL test to include thermal stress cycle"

### Action Item Template

For each recommended action, document:

```
Action ID: FMEA-BMS-001-A01
Failure Mode: Incorrect cell voltage reading
Recommended Action: Implement runtime ADC self-test
Responsibility: John Smith (Firmware Team)
Target Date: 2026-04-30
Status: In Progress
Success Criteria: Self-test coverage >95%, fault detection <10s
```

## After Actions: Revised Ratings

After implementing recommended actions, reassess S', O', D', and RPN'.

**Example**:

**Before**:
- S=10, O=4, D=6, RPN=240

**Action Taken**:
"Implemented runtime self-test comparing ADC reading to precision reference every 10s. Self-test failure triggers safe mode shutdown."

**After**:
- S'=10 (unchanged - thermal runaway still possible)
- O'=2 (reduced - self-test detects drift before it causes overvoltage)
- D'=2 (reduced - automated detection with fail-safe)
- RPN'=40 (significantly reduced)

**Validation**:
Document evidence that revised ratings are accurate:
- "Self-test functional verification completed 2026-04-25"
- "DVT testing: 100% fault detection in 500 test runs"

## PFMEA: Process FMEA Differences

PFMEA analyzes manufacturing processes instead of design.

**Column Differences**:

| DFMEA | PFMEA |
|-------|-------|
| Item/Function | Process Step |
| Failure Mode | Process Failure Mode |
| Cause | Process Cause |
| Current Controls (design) | Current Process Controls |

**PFMEA Example**:

| Process Step | Failure Mode | Effects | S | Causes | O | Current Controls | D | RPN |
|-------------|--------------|---------|---|--------|---|------------------|---|-----|
| Solder reflow | Insufficient solder | Open circuit on cell sense line | 9 | Solder paste volume too low | 4 | Automated solder paste inspection (SPI) | 3 | 108 |

**Process Controls**:
- **Prevention**: Solder paste printer with closed-loop volume control
- **Detection**: Automated optical inspection (AOI) post-reflow

## Common FMEA Mistakes

### Mistake 1: Confusing Failure Mode and Cause

**Wrong**:
- Failure Mode: "Component tolerance too wide"
- Cause: "Voltage out of specification"

**Correct**:
- Failure Mode: "Output voltage exceeds specification"
- Cause: "Component tolerance too wide"

### Mistake 2: Focusing on Local Effects for Severity

**Wrong**:
- Effect: "ADC reports incorrect value" → S=3

**Correct**:
- Effect: "Cell overcharge leading to thermal runaway" → S=10

### Mistake 3: Rating Detection Based on Cause Frequency

**Wrong**:
"Cause is rare, so D=2"

**Correct**:
"Cause is rare" → affects **Occurrence (O)**, not Detection
"Detection is automated with fail-safe" → D=2

### Mistake 4: Listing Planned Actions as Current Controls

**Wrong**:
Current Controls: "Will add self-test in next revision"

**Correct**:
Current Controls: "None" (if not yet implemented)
Recommended Actions: "Add self-test"

### Mistake 5: Not Reassessing After Actions

**Wrong**:
Implement action, never update FMEA with S'/O'/D'/RPN'

**Correct**:
Document actions taken, validate effectiveness, update ratings, close action item

## FMEA Templates and Checklists

### Pre-FMEA Checklist

- [ ] FMEA scope clearly defined (system boundary, lifecycle phase)
- [ ] Cross-functional team identified (design, test, quality, manufacturing)
- [ ] Block diagram and functional analysis complete
- [ ] Previous FMEA and lessons learned reviewed
- [ ] Severity criteria aligned with safety standards (ISO 26262 ASIL mapping)

### During FMEA Checklist

- [ ] All functions systematically analyzed (use P-diagram for completeness)
- [ ] Failure modes at appropriate abstraction level
- [ ] Effects traced to end user impact
- [ ] Causes are root causes, not symptoms
- [ ] S, O, D ratings justified with data or rationale
- [ ] All S=9 or 10 items have recommended actions
- [ ] Action responsibility and target dates assigned

### Post-FMEA Checklist

- [ ] Actions tracked in project management system
- [ ] Completed actions validated (testing, analysis)
- [ ] FMEA updated with revised ratings
- [ ] FMEA findings integrated into DVP (Design Verification Plan)
- [ ] Lessons learned documented for future FMEAs

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: FMEA facilitators, design engineers, quality engineers

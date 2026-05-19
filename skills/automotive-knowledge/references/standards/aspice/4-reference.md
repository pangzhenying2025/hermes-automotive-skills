# Automotive SPICE - Quick Reference

## Work Product Templates

### Software Requirements Specification (17-11)

```markdown
# Software Requirements Specification
**Project**: [Project Name]
**Component**: [Component Name]
**Version**: [X.Y]
**Date**: [YYYY-MM-DD]
**Author**: [Name]
**Approved by**: [Name, Date]

## 1. Introduction
### 1.1 Purpose
[Purpose of this SRS]

### 1.2 Scope
[What is included/excluded]

### 1.3 Definitions and Acronyms
| Term | Definition |
|------|------------|
| ESC  | Electronic Stability Control |
| ASIL | Automotive Safety Integrity Level |

### 1.4 References
- [SYS-SPEC-001] System Requirements Specification v2.3
- [IF-SPEC-CAN] CAN Interface Specification v1.5

## 2. System Overview
[Brief description of system context]

## 3. Functional Requirements
### 3.1 [Feature Name]
**SWE-REQ-001**: The software shall [requirement text]
- **Source**: SYS-REQ-042
- **Type**: Functional
- **Priority**: High
- **ASIL**: D
- **Verification**: Integration test
- **Rationale**: [Why this requirement exists]

## 4. Non-Functional Requirements
### 4.1 Performance
**SWE-REQ-100**: Wheel speed calculation shall complete within 2ms
- **Source**: SYS-REQ-PERF-05
- **Verification**: Timing analysis, profiling

### 4.2 Safety
**SWE-REQ-200**: Software shall detect sensor faults within 200ms
- **Source**: ISO 26262 ASIL D diagnostic coverage
- **ASIL**: D
- **Verification**: Fault injection test

### 4.3 Resource Constraints
**SWE-REQ-300**: RAM usage shall not exceed 512 KB
**SWE-REQ-301**: Flash usage shall not exceed 2 MB

## 5. Interface Requirements
### 5.1 Input Interfaces
**SWE-REQ-400**: Software shall receive wheel speed via CAN (500 kbps)
- **Message**: WheelSpeed_Data (CAN ID 0x120)
- **Period**: 10ms
- **Format**: See [IF-SPEC-CAN] Section 3.2

### 5.2 Output Interfaces
**SWE-REQ-410**: Software shall transmit brake commands via PWM
- **Signal**: Brake_PWM_FL/FR/RL/RR
- **Frequency**: 1 kHz
- **Duty cycle**: 0-100%

## 6. Traceability Matrix
| System Req | Software Req | Verification |
|------------|--------------|--------------|
| SYS-042    | SWE-001, SWE-002 | TC-INT-042 |
| SYS-043    | SWE-003      | TC-INT-043 |

## 7. Appendices
### Appendix A: Open Issues
[List of TBD items]

---
**Review Record**:
| Reviewer | Role | Date | Status |
|----------|------|------|--------|
| J. Smith | System Arch | 2026-03-15 | Approved |
| M. Jones | Safety Eng  | 2026-03-16 | Approved with comments |
```

### Software Architecture Specification (17-01)

```markdown
# Software Architectural Design Specification
**Project**: [Project Name]
**Version**: [X.Y]

## 1. Architectural Overview
### 1.1 Component Diagram
```
[ASCII diagram or reference to external tool]
```

### 1.2 Design Principles
- Layered architecture (Application, Services, BSW)
- AUTOSAR Adaptive compliance
- Separation of ASIL D from QM components

## 2. Component Descriptions
### 2.1 Component: ESC_Control
**Purpose**: Main ESC control algorithm
**Allocated Requirements**: SWE-001, SWE-002, SWE-003
**ASIL**: D
**Dependencies**: SensorDiag, VehicleDynamics, ActuatorDriver
**Resources**:
- RAM: 128 KB
- Flash: 512 KB
- CPU: Core 0 (dedicated)

**Interfaces**:
| Interface | Direction | Type | Period |
|-----------|-----------|------|--------|
| I_WheelSpeed | Consumer | Function call | 10ms |
| I_BrakeCmd | Provider | Function call | 10ms |

## 3. Interface Specifications
### 3.1 I_WheelSpeed
```c
typedef struct {
    float speed_FL_mps;
    float speed_FR_mps;
    float speed_RL_mps;
    float speed_RR_mps;
    uint8_t validityMask;
} WheelSpeedData_t;

const WheelSpeedData_t* GetWheelSpeedData(void);
```

## 4. Dynamic Behavior
### 4.1 Sequence Diagram: ESC Intervention
[Sequence diagram showing component interactions]

### 4.2 State Machine: ESC States
[State diagram with transitions]

## 5. Safety Architecture
### 5.1 ASIL Decomposition
- ESC_Control: ASIL D
- SensorDiag: ASIL D
- HMI_Warning: ASIL B(D) - decomposed from D

### 5.2 Freedom from Interference
- Memory protection: MPU regions for ASIL D components
- Temporal protection: Time partitioning (AUTOSAR OS)

## 6. Traceability
| Software Req | Allocated Component | Interface |
|--------------|---------------------|-----------|
| SWE-001      | SensorDiag          | I_WheelSpeed |
| SWE-002      | ESC_Control         | I_BrakeCmd |

---
**Review Record**: [Same format as SRS]
```

### Test Specification Template (17-13 Unit, 17-07 Integration)

```markdown
# Software Unit Test Specification
**Component**: [Component Name]
**Version**: [X.Y]

## 1. Test Scope
### 1.1 Units Under Test
- WheelSpeedPlausibility.c
- BrakeControl.c

### 1.2 Test Objectives
- Verify functional correctness per SWE requirements
- Achieve MC/DC coverage (ASIL D requirement)

## 2. Test Environment
### 2.1 Hardware
- Host PC: x86_64 Linux
- Cross-compiler: arm-none-eabi-gcc 11.2

### 2.2 Software
- Test framework: Google Test 1.12
- Coverage tool: gcov/lcov
- Build system: CMake 3.22

### 2.3 Test Harness
- Mock: CAN driver, PWM driver
- Stub: AUTOSAR OS API

## 3. Test Cases
### TC-SWE-001-UT-01: Nominal Wheel Speed Processing
**Objective**: Verify correct calculation of wheel speed from sensor pulses
**Requirement**: SWE-001
**Preconditions**: Module initialized, pulse counter = 0
**Input**:
  - Pulse count: 100
  - Time interval: 100ms
  - Wheel circumference: 2.0m
**Expected Output**:
  - Wheel speed: 20.0 m/s
**Test Procedure**:
```c
TEST(WheelSpeed, NominalCalculation) {
    InitModule();
    SetPulseCount(100);
    SetTimeInterval(100); // ms
    float speed = CalculateWheelSpeed();
    EXPECT_FLOAT_EQ(speed, 20.0f);
}
```
**Pass Criteria**: Calculated speed within ±0.1 m/s

### TC-SWE-001-UT-02: Division by Zero Protection
**Objective**: Verify handling when time interval = 0
**Input**: Pulse count = 50, Time interval = 0ms
**Expected Output**: Speed = 0.0 m/s (safe default)
**Pass Criteria**: No crash, speed = 0.0

## 4. Coverage Requirements
### 4.1 Structural Coverage (ASIL D)
- Statement coverage: 100% required
- Branch coverage: 100% required
- MC/DC coverage: 100% required

### 4.2 Traceability
| Requirement | Test Case | Coverage |
|-------------|-----------|----------|
| SWE-001     | UT-01, UT-02 | 100% |
| SWE-002     | UT-03, UT-04 | 100% |

## 5. Test Results Summary
[To be filled after execution]
- Total test cases: [N]
- Passed: [N]
- Failed: [N]
- Coverage: [X]%

---
**Executed by**: [Name, Date]
**Reviewed by**: [Name, Date]
```

## Naming Conventions

### Work Product Naming

| Work Product Type | Naming Pattern | Example |
|-------------------|----------------|---------|
| Requirements spec | `[PROJ]-SWE-REQ-[Component]-v[X.Y].md` | PROJ-ESC-SWE-REQ-Control-v1.2.md |
| Architecture spec | `[PROJ]-SWE-ARCH-[Component]-v[X.Y].md` | PROJ-ESC-SWE-ARCH-Control-v2.0.md |
| Detailed design | `[PROJ]-SWE-DES-[Module]-v[X.Y].md` | PROJ-ESC-SWE-DES-Plausibility-v1.0.md |
| Test spec | `[PROJ]-SWE-TEST-[Level]-[Component]-v[X.Y].md` | PROJ-ESC-SWE-TEST-UT-Control-v1.1.md |
| Test report | `[PROJ]-SWE-TESTREP-[Level]-[Component]-[Date].pdf` | PROJ-ESC-SWE-TESTREP-UT-Control-20260315.pdf |

### Requirement ID Conventions

```
Format: [Type]-REQ-[Component]-[Number]

Examples:
SYS-REQ-ESC-042     (System requirement for ESC, number 42)
SWE-REQ-ESC-001     (Software requirement for ESC, number 1)
HW-REQ-SENSOR-015   (Hardware requirement for sensor)

Numbering:
- Use leading zeros for sortability (001, 002, ..., 099, 100)
- Reserve ranges for subsystems (ESC: 001-099, ABS: 100-199)
```

### Test Case ID Conventions

```
Format: TC-[Req]-[Level]-[Number]

Levels:
- UT: Unit Test
- IT: Integration Test
- QT: Qualification Test
- ST: System Test

Examples:
TC-SWE-001-UT-01    (Unit test #1 for SWE-REQ-001)
TC-SWE-042-IT-03    (Integration test #3 for SWE-REQ-042)
TC-SYS-100-ST-01    (System test #1 for SYS-REQ-100)
```

## Traceability Matrix Format

### Forward Traceability (Requirements → Tests)

```markdown
| Req ID | Requirement | ASIL | Design | Implementation | Unit Test | Int Test | Status |
|--------|-------------|------|--------|----------------|-----------|----------|--------|
| SWE-001 | Wheel speed calc | D | COMP-SD | WheelSpeed.c:45 | TC-UT-01 | TC-IT-05 | Verified |
| SWE-002 | Plausibility chk | D | COMP-SD | Plausibility.c:78 | TC-UT-02 | TC-IT-06 | In progress |
```

### Backward Traceability (Tests → Requirements)

```markdown
| Test ID | Test Description | Verifies Req | Pass/Fail | Date |
|---------|------------------|--------------|-----------|------|
| TC-UT-01 | Nominal speed calc | SWE-001 | Pass | 2026-03-15 |
| TC-UT-02 | Deviation detect | SWE-002 | Pass | 2026-03-15 |
| TC-IT-05 | ESC integration | SWE-001, SWE-003 | Pass | 2026-03-18 |
```

### Impact Analysis Matrix

```markdown
| Req ID | Impacted Design | Impacted Code | Impacted Tests | Change Effort |
|--------|----------------|---------------|----------------|---------------|
| SWE-001 | COMP-SD | WheelSpeed.c | TC-UT-01, TC-IT-05 | 4h |
| SWE-002 | COMP-SD, COMP-ESC | Plausibility.c, ESC_Ctrl.c | TC-UT-02, TC-IT-06, TC-QT-01 | 16h |
```

## Assessment Checklists

### SWE.1 Assessment Checklist

**BP1: Specify software requirements**
- ☐ Requirements documented in SRS
- ☐ Each requirement has unique ID
- ☐ Functional and non-functional requirements specified
- ☐ Interface requirements specified
- ☐ Safety requirements (ASIL) specified
- ☐ Requirements use "shall" language
- ☐ Requirements are unambiguous (single interpretation)

**BP2: Analyze software requirements**
- ☐ Requirements reviewed for correctness
- ☐ Requirements reviewed for completeness
- ☐ Requirements reviewed for consistency
- ☐ Requirements reviewed for testability
- ☐ Analysis findings documented
- ☐ Defects tracked and resolved

**BP5: Bidirectional traceability**
- ☐ Traceability matrix exists (system req → software req)
- ☐ All system requirements traced to software requirements
- ☐ All software requirements traced to system requirements
- ☐ Orphan requirements identified and justified
- ☐ Traceability maintained in tool or document

**BP6: Communicate requirements**
- ☐ SRS reviewed and approved
- ☐ SRS distributed to stakeholders
- ☐ Changes to requirements communicated

**Evidence**:
- 17-11: Software requirements specification (SRS)
- 13-19: Verification criteria
- 13-22: Traceability record
- 13-16: Review records

### SWE.2 Assessment Checklist

**BP1: Develop software architectural design**
- ☐ Architecture document exists
- ☐ Components identified and described
- ☐ Component responsibilities defined
- ☐ Architecture reviewed and approved

**BP2: Allocate requirements to components**
- ☐ All software requirements allocated
- ☐ Allocation documented in traceability matrix
- ☐ No component overloaded with requirements

**BP3: Define interfaces**
- ☐ All interfaces documented (function signatures, data structures)
- ☐ Interface timing specified
- ☐ Interface error handling specified

**Evidence**:
- 17-01: Software architectural design specification
- 17-02: Software interface specification
- 13-22: Traceability record (req → component)

### Generic Practice GP 2.1 Checklist (Performance Management)

- ☐ Process performance objectives defined
- ☐ Performance monitored (schedule, effort, defects)
- ☐ Status reported regularly (weekly/bi-weekly)
- ☐ Deviations identified
- ☐ Corrective actions defined and tracked

**Evidence**:
- 15-20: Project plan (with objectives)
- 15-21: Project status reports
- 14-04: Schedule (Gantt chart)
- Meeting minutes with action items

### Generic Practice GP 2.2 Checklist (Work Product Management)

- ☐ Work product requirements defined (templates, standards)
- ☐ Work products reviewed before use
- ☐ Review criteria defined (checklists)
- ☐ Review findings documented
- ☐ Work products under version control

**Evidence**:
- Document templates (SRS, architecture, test spec)
- Review checklists
- 13-16: Review records (sign-offs)
- 15-05: Configuration management records

## Process Performance Metrics

### Typical Metrics for Level 2/3

| Metric | Purpose | Collection Method | Target |
|--------|---------|-------------------|--------|
| Requirements stability | Track requirement changes | Count changes per baseline | < 10% change after freeze |
| Defect density | Code quality | Defects / KLOC | < 5 defects/KLOC |
| Review efficiency | Review effectiveness | Defects found in review / total | > 60% found in review |
| Test coverage | Verification completeness | Coverage tool | 100% MC/DC for ASIL D |
| Schedule variance | Project control | Actual vs planned | ±10% |
| Effort variance | Estimation accuracy | Actual vs estimated | ±15% |

## Common Pitfalls

### SWE.1 Pitfalls
- ❌ Requirements too high-level ("software shall provide ESC function")
- ❌ No verification method specified
- ❌ Missing traceability to system requirements
- ❌ Requirements not reviewed

### SWE.2 Pitfalls
- ❌ Architecture diagram without component descriptions
- ❌ Interfaces not specified (just "via CAN")
- ❌ No allocation of requirements to components
- ❌ No dynamic behavior (sequence, state machine)

### SWE.3 Pitfalls
- ❌ Detailed design in code comments only (not separate document)
- ❌ No traceability from code to design
- ❌ Algorithm not described (just implementation)

### Generic Practice Pitfalls
- ❌ Process plan exists but not followed
- ❌ Reviews performed but not documented
- ❌ Configuration management tool used but no baselines
- ❌ Project plan not updated (stale)

## Quick Reference Tables

### Process-Work Product Matrix

| Process | Key Work Products |
|---------|-------------------|
| SWE.1 | 17-11 SRS, 13-19 Verification criteria, 13-22 Traceability |
| SWE.2 | 17-01 Architecture, 17-02 Interfaces, 13-22 Traceability |
| SWE.3 | 17-03 Detailed design, 17-04 Software unit, 13-22 Traceability |
| SWE.4 | 17-12 Unit test strategy, 17-13 Unit test spec, 17-14 Unit test report |
| SWE.5 | 17-06 Integration strategy, 17-07 Integration test spec, 17-08 Integration test report |
| SWE.6 | 17-09 Qualification test strategy, 17-10 Qualification test spec, 17-15 Qualification test report |
| SUP.1 | 08-50 QA strategy, 08-52 Quality criteria, 13-16 Quality record |
| SUP.8 | 15-01 CM strategy, 15-03 Configuration items, 15-04 Baseline |
| MAN.3 | 15-20 Project plan, 15-21 Status report, 14-04 Schedule, 14-06 Risk plan |

### Rating Quick Guide

| Rating | % Achieved | Characteristics |
|--------|-----------|-----------------|
| F | >85% | Complete, systematic, documented, consistent |
| L | >50-85% | Minor gaps, generally systematic, mostly documented |
| P | >15-50% | Significant gaps, ad-hoc in places, incomplete docs |
| N | 0-15% | Not implemented, no systematic approach, docs missing |

## References

- Automotive SPICE PAM v3.1 Work Product Characteristics
- VDA Guideline: Work Product Templates
- ISO/IEC 15289:2019 Content of life-cycle information items

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All project team members, assessors

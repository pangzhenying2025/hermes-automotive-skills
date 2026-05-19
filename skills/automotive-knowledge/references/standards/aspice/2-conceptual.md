# Automotive SPICE - Conceptual Architecture

## Process Reference Model (PRM)

The PRM defines the universe of processes relevant to automotive software development, organized into three categories.

```
Automotive SPICE Process Landscape

Primary Processes (ACQ, SPL, SYS, SWE)
    ↓ Work products
Supporting Processes (SUP)
    ↓ Quality & control
Management Processes (MAN)
    ↓ Planning & oversight
```

## Primary Process Groups

### Acquisition Process Group (ACQ)

**Purpose**: Acquire products or services from suppliers.

**Key Processes**:
- ACQ.3: Contract Agreement
- ACQ.4: Supplier Monitoring
- ACQ.11: Technical Requirements
- ACQ.13: Project Requirements

**Typical Work Products**:
- Supplier contracts
- Supplier quality agreements
- Supplier performance reports

### Supply Process Group (SPL)

**Purpose**: Supply products or services to customers.

**Key Processes**:
- SPL.2: Product Release

**Typical Work Products**:
- Release notes
- Product quality reports
- Delivery documentation

### System Engineering Process Group (SYS)

Critical for projects with hardware-software integration.

#### SYS.1: Requirements Elicitation

**Purpose**: Gather and analyze stakeholder requirements.

**Base Practices**:
- BP1: Obtain customer requirements and requests
- BP2: Understand stakeholder needs
- BP3: Define functional and non-functional requirements

**Work Products**:
- Stakeholder requirements specification
- Customer requirement analysis

#### SYS.2: System Requirements Analysis

**Purpose**: Transform stakeholder requirements into technical system requirements.

**Base Practices**:
- BP1: Specify system requirements (functional, non-functional)
- BP2: Analyze system requirements for correctness and testability
- BP3: Evaluate impact on operating environment
- BP4: Develop verification criteria
- BP5: Ensure consistency and bidirectional traceability
- BP6: Communicate system requirements to stakeholders

**Work Products**:
- 13-04: System requirements specification
- 13-19: Verification criteria
- 13-22: Traceability record (stakeholder → system requirements)

**Example Traceability**:
```
Stakeholder Requirement SR-001:
"The vehicle shall detect obstacles during parking"

System Requirements:
SYS-REQ-001: Ultrasonic sensor system shall detect objects 0.3-2.5m
SYS-REQ-002: System shall update distance readings at 10 Hz
SYS-REQ-003: System shall provide audible warning when object < 0.5m
SYS-REQ-004: System shall provide visual distance indication on display

Trace: SR-001 → SYS-REQ-001, SYS-REQ-002, SYS-REQ-003, SYS-REQ-004
```

#### SYS.3: System Architectural Design

**Purpose**: Define system architecture allocating requirements to elements.

**Base Practices**:
- BP1: Develop system architectural design
- BP2: Allocate system requirements to elements
- BP3: Define interfaces (internal and external)
- BP4: Describe dynamic behavior
- BP5: Define evaluation criteria for architecture
- BP6: Ensure consistency and bidirectional traceability

**Work Products**:
- 13-01: System architectural design specification
- 13-02: Interface specification
- 13-22: Traceability record (system req → architecture)

**Architecture Documentation**:
```
System Architecture: Parking Assistance System

Hardware Elements:
- ECU-PAS: Parking assistance ECU (SWE responsibility)
- US-SENSOR-FL/FR/RL/RR: Ultrasonic sensors (4x)
- SPEAKER: Audible warning device
- DISPLAY-CTRL: Display controller (existing)

Software Elements:
- SW-PAS-CTRL: Main control software (runs on ECU-PAS)
- SW-PAS-HMI: HMI interface software

Interfaces:
- IF-001: ECU-PAS ↔ US-SENSOR (analog voltage 0-5V)
- IF-002: ECU-PAS ↔ SPEAKER (PWM signal)
- IF-003: ECU-PAS ↔ DISPLAY-CTRL (CAN 500 kbps)
```

#### SYS.4: System Integration and Integration Test

**Purpose**: Integrate system elements and demonstrate interface compliance.

**Base Practices**:
- BP1: Develop system integration strategy
- BP2: Develop system integration test specification
- BP3: Integrate system elements
- BP4: Test integrated system elements
- BP5: Establish bidirectional traceability
- BP6: Ensure consistency with system design
- BP7: Summarize and communicate results

**Work Products**:
- 13-12: System integration strategy
- 13-23: System integration test specification
- 13-24: System integration test report

#### SYS.5: System Qualification Test

**Purpose**: Ensure system meets requirements.

**Base Practices**:
- BP1: Develop system qualification test strategy
- BP2: Develop system qualification test specification
- BP3: Test integrated system
- BP4: Establish bidirectional traceability
- BP5: Ensure consistency with requirements
- BP6: Summarize and communicate results

**Work Products**:
- 13-25: System qualification test strategy
- 13-26: System qualification test specification
- 13-27: System qualification test report

### Software Engineering Process Group (SWE)

Core processes for software development.

#### SWE.1: Software Requirements Analysis

**Purpose**: Establish software requirements from system requirements.

**Base Practices**:
- BP1: Specify software requirements (functional, non-functional)
- BP2: Analyze software requirements
- BP3: Assess impact on operating environment
- BP4: Develop verification criteria
- BP5: Ensure consistency and bidirectional traceability
- BP6: Communicate software requirements

**Work Products**:
- 17-11: Software requirements specification (SRS)
- 13-19: Verification criteria
- 13-22: Traceability record (system req → software req)

**Example SRS Entry**:
```
Software Requirement: SWE-REQ-PAS-001
Derived from: SYS-REQ-001
Description:
The parking assistance software shall read analog voltage from
ultrasonic sensors and convert to distance using formula:
  Distance [cm] = (Voltage [V] / 5.0) × 250

Range: 30-250 cm
Accuracy: ±5 cm
Update rate: 10 Hz (100ms cycle time)

Verification Criteria:
- Test with known distances 50, 100, 150, 200 cm
- Verify accuracy within ±5 cm
- Verify update rate 10 Hz ±1 Hz
```

#### SWE.2: Software Architectural Design

**Purpose**: Establish software architecture.

**Base Practices**:
- BP1: Develop software architectural design
- BP2: Allocate requirements to software components
- BP3: Define interfaces (internal and external)
- BP4: Describe dynamic behavior
- BP5: Define evaluation criteria
- BP6: Ensure consistency and bidirectional traceability

**Work Products**:
- 17-01: Software architectural design specification
- 17-02: Software interface specification
- 13-22: Traceability record

#### SWE.3: Software Detailed Design and Unit Construction

**Purpose**: Provide detailed design for units and implement them.

**Base Practices**:
- BP1: Develop detailed design for units
- BP2: Define interfaces for units
- BP3: Describe dynamic behavior of units
- BP4: Evaluate detailed design
- BP5: Ensure bidirectional traceability to architectural design
- BP6: Construct software units
- BP7: Ensure consistency with detailed design

**Work Products**:
- 17-03: Software detailed design specification
- 17-04: Software unit
- 13-22: Traceability record

#### SWE.4: Software Unit Verification

**Purpose**: Verify software units meet design requirements.

**Base Practices**:
- BP1: Develop unit verification strategy
- BP2: Develop unit test specification
- BP3: Test software units
- BP4: Establish bidirectional traceability
- BP5: Ensure consistency
- BP6: Summarize and communicate results

**Work Products**:
- 17-12: Software unit verification strategy
- 17-13: Software unit test specification
- 17-14: Software unit test report

#### SWE.5: Software Integration and Integration Test

**Purpose**: Integrate units and verify interfaces.

**Base Practices**:
- BP1: Develop integration strategy
- BP2: Develop integration test specification
- BP3: Integrate software units
- BP4: Test integrated units
- BP5: Establish bidirectional traceability
- BP6: Ensure consistency
- BP7: Summarize and communicate results

**Work Products**:
- 17-06: Software integration strategy
- 17-07: Software integration test specification
- 17-08: Software integration test report

#### SWE.6: Software Qualification Test

**Purpose**: Ensure software meets requirements.

**Base Practices**:
- BP1: Develop qualification test strategy
- BP2: Develop qualification test specification
- BP3: Test integrated software
- BP4: Establish bidirectional traceability
- BP5: Ensure consistency
- BP6: Summarize and communicate results

**Work Products**:
- 17-09: Software qualification test strategy
- 17-10: Software qualification test specification
- 17-15: Software qualification test report

## Supporting Process Group (SUP)

### SUP.1: Quality Assurance

**Purpose**: Provide independent assurance of process and work product quality.

**Base Practices**:
- BP1: Develop quality assurance strategy
- BP2: Assure quality of work products
- BP3: Assure quality of process activities
- BP4: Summarize and communicate quality assurance activities

**Work Products**:
- 08-50: Quality assurance strategy
- 08-52: Quality criteria
- 13-16: Quality record (audit reports, review records)

### SUP.8: Configuration Management

**Purpose**: Establish and maintain integrity of work products.

**Base Practices**:
- BP1: Develop configuration management strategy
- BP2: Identify configuration items
- BP3: Control modifications
- BP4: Establish baselines
- BP5: Make available status and configuration data

**Work Products**:
- 15-01: Configuration management strategy
- 15-03: Configuration item
- 15-04: Baseline
- 15-05: Configuration status account

### SUP.9: Problem Resolution Management

**Purpose**: Ensure problems are recorded, analyzed, and resolved.

**Base Practices**:
- BP1: Develop problem resolution management strategy
- BP2: Record problems
- BP3: Record status of problems
- BP4: Diagnose cause and determine solution
- BP5: Resolve problems
- BP6: Initiate change requests
- BP7: Track problems to closure

**Work Products**:
- 15-12: Problem resolution management strategy
- 15-13: Problem record

### SUP.10: Change Request Management

**Purpose**: Ensure change requests are managed, tracked, and controlled.

**Base Practices**:
- BP1: Develop change request management strategy
- BP2: Record change requests
- BP3: Record status of change requests
- BP4: Analyze and assess change requests
- BP5: Approve change requests before implementation
- BP6: Review implementation
- BP7: Track change requests to closure

**Work Products**:
- 15-14: Change request management strategy
- 15-15: Change request

## Management Process Group (MAN)

### MAN.3: Project Management

**Purpose**: Identify, establish, and control project activities.

**Base Practices**:
- BP1: Define scope of work
- BP2: Define project lifecycle
- BP3: Evaluate feasibility
- BP4: Define and maintain estimates (effort, resources)
- BP5: Define project activities and schedule
- BP6: Identify and monitor project interfaces
- BP7: Identify, monitor, and adjust project risks
- BP8: Monitor and report project status
- BP9: Establish corrective actions

**Work Products**:
- 15-20: Project plan
- 15-21: Project status report
- 14-04: Schedule
- 14-06: Risk mitigation plan

## Generic Practices for Level 2 (Managed)

### GP 2.1: Performance Management

**Purpose**: Define objectives and monitor process performance.

**Indicators**:
- Process performance objectives defined
- Performance monitored against objectives
- Corrective actions taken when objectives not met

**Example Evidence**:
- Project plan with schedule and effort estimates
- Bi-weekly status reports comparing actual to planned
- Action items from status meetings

### GP 2.2: Work Product Management

**Purpose**: Define requirements for work products and control them.

**Indicators**:
- Requirements for work products defined (templates, standards)
- Work products reviewed according to criteria
- Work products maintained and controlled

**Example Evidence**:
- Document templates (SRS, SDD, test spec)
- Review checklists and sign-off records
- Configuration management records (baseline identification)

### GP 2.3: Resource and Responsibility Management

**Purpose**: Ensure adequate resources and clear responsibilities.

**Indicators**:
- Necessary resources identified and made available
- Responsibilities and authorities assigned and communicated

**Example Evidence**:
- Project plan with resource allocation
- RACI matrix (Responsible, Accountable, Consulted, Informed)
- Training records for specialized tools/methods

### GP 2.4: Role-Based Training

**Purpose**: Ensure personnel have necessary competence.

**Indicators**:
- Required skills and knowledge identified
- Personnel have competence based on education, training, experience
- Training records maintained

**Example Evidence**:
- Competence matrix (skills vs. team members)
- Training plans and completion records
- Onboarding documentation

## Generic Practices for Level 3 (Established)

### GP 3.1: Process Definition

**Purpose**: Deploy a defined process derived from organizational standard.

**Indicators**:
- Organizational standard process exists
- Project process tailored from standard
- Tailoring documented and approved

**Example Evidence**:
- Organizational process asset library
- Project-specific process description (tailored from standard)
- Tailoring rationale document

### GP 3.2: Process Deployment

**Purpose**: Ensure personnel understand and can implement the process.

**Indicators**:
- Process communicated to personnel
- Training provided on process
- Process assets available (templates, checklists, tools)

**Example Evidence**:
- Process training materials
- Intranet/wiki with process documentation
- Tool access and configuration

## Rating Scale Details

### Fully Achieved (F): >85-100%

**Characteristics**:
- Complete evidence across all projects/instances
- Systematic approach
- Well-documented
- Consistent application

### Largely Achieved (L): >50-85%

**Characteristics**:
- Evidence for most projects/instances
- Minor gaps or inconsistencies
- Generally systematic approach
- Most work products adequate

### Partially Achieved (P): >15-50%

**Characteristics**:
- Evidence for some projects/instances
- Significant gaps
- Ad-hoc approach in many cases
- Work products incomplete

### Not Achieved (N): 0-15%

**Characteristics**:
- Little or no evidence
- No systematic approach
- Work products missing or inadequate
- Practice not implemented

## Next Steps

- **Level 3**: Detailed base practice implementation with examples
- **Level 4**: Work product templates and assessment checklists
- **Level 5**: Achieving Level 3 capability and continuous improvement

## References

- Automotive SPICE PAM v3.1 Process Capability Levels
- Automotive SPICE PAM v3.1 Generic Practices
- VDA Guideline for process descriptions

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Process engineers, project managers, ASPICE coordinators

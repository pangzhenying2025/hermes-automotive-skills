# Technical Documentation Standards for Automotive Projects

> Rules for creating, maintaining, and reviewing technical documentation
> in automotive software development, ensuring compliance with ISO 26262
> work product requirements and enabling effective knowledge transfer.

## Scope

These rules apply to all technical documentation produced in automotive
software projects, including design documents, safety analyses, test
specifications, user guides, API documentation, and process descriptions.

---

## Document Hierarchy

### Required Work Products by Phase

| Phase | Document | ISO 26262 Ref | Audience |
|-------|----------|--------------|----------|
| Concept | HARA Report | Part 3 | Safety team, management |
| Concept | Safety Plan | Part 2 | All teams |
| System Design | System Architecture | Part 4 | System engineers |
| System Design | HSI Specification | Part 4 | HW + SW teams |
| System Design | Safety Requirements | Part 4 | All teams |
| SW Design | SW Architecture | Part 6 | SW developers |
| SW Design | SW Detailed Design | Part 6 | SW developers |
| SW Design | SW Safety Manual | Part 6 | Integrators |
| Implementation | Coding Guidelines | Part 6 | SW developers |
| Testing | Test Plan | Part 4,6 | Test team |
| Testing | Test Specification | Part 4,6 | Test team |
| Testing | Test Report | Part 4,6 | All teams |
| Validation | Safety Case | Part 4 | Assessors |

---

## Document Quality Rules

### Structure Requirements

Every technical document must contain:

```yaml
document_structure:
  front_matter:
    - title_page:
        document_id: "Required (e.g., DOC-BMS-ARCH-001)"
        version: "Required (semantic versioning)"
        date: "Required (ISO 8601)"
        status: "Required (Draft/Review/Approved/Obsolete)"
        classification: "Required (Public/Internal/Confidential)"
    - revision_history:
        columns: [version, date, author, changes]
    - approval_signatures:
        roles: [author, reviewer, approver]
    - table_of_contents: "Auto-generated"

  body:
    - scope: "What this document covers and does not cover"
    - references: "All referenced documents and standards"
    - definitions: "Acronyms, abbreviations, and terms"
    - content: "Main technical content (structured by topic)"

  appendices:
    - traceability: "Links to requirements and other documents"
    - open_issues: "Known gaps and planned updates"
```

### Writing Style Rules

| Rule | Example Good | Example Bad |
|------|-------------|-------------|
| Use active voice | "The BMS monitors cell voltages" | "Cell voltages are monitored" |
| Be specific | "Response time < 100 ms" | "Response time is fast" |
| Use consistent terms | Always "contactor" (not "relay/switch") | Mixed terminology |
| Define before use | "SOC (State of Charge) represents..." | "The SOC value is..." |
| One idea per sentence | Split compound sentences | "The system does X and Y and Z" |
| Use numbered requirements | "REQ-BMS-042: The BMS shall..." | "The BMS should try to..." |

### Requirement Writing Rules

```yaml
requirement_rules:
  format: "{ID}: {Subject} shall {verb} {object} {condition} {constraint}"

  good_examples:
    - id: SSR-BMS-012
      text: >
        The BMS shall detect pack current exceeding 500A within 10ms
        of the overcurrent condition occurring.
      attributes:
        verifiable: true
        atomic: true
        unambiguous: true

    - id: SSR-BMS-013
      text: >
        The BMS shall command the main contactor to open within 100ms
        of detecting an overcurrent condition per SSR-BMS-012.

  bad_examples:
    - text: "The BMS should handle overcurrent well"
      problems: ["vague", "not measurable", "weak 'should'"]
    - text: "The BMS shall detect and handle all faults quickly"
      problems: ["compound", "undefined 'all faults'", "undefined 'quickly'"]
    - text: "The system shall be reliable"
      problems: ["not testable", "subjective"]

  mandatory_attributes:
    - id: "Unique identifier"
    - text: "Requirement statement"
    - asil: "ASIL classification"
    - rationale: "Why this requirement exists"
    - verification_method: "Test/Analysis/Review/Inspection"
    - parent_requirement: "Traceability to higher-level requirement"
    - status: "Draft/Approved/Implemented/Verified"
```

---

## Software Architecture Document

### Required Content

```yaml
sw_architecture_document:
  sections:
    1_overview:
      content:
        - "System context diagram"
        - "High-level component diagram"
        - "Key design decisions and rationale"
      format: "Architecture Decision Records (ADR)"

    2_component_design:
      per_component:
        - "Responsibility description"
        - "Interface definition (APIs, messages)"
        - "Internal structure (classes, modules)"
        - "State machine diagrams (if stateful)"
        - "Sequence diagrams (key interactions)"
        - "ASIL classification"

    3_data_design:
      content:
        - "Data flow diagrams"
        - "Message catalog (CAN, Ethernet)"
        - "Configuration parameter list"
        - "Calibration parameter list"

    4_dynamic_behavior:
      content:
        - "Task/thread architecture"
        - "Interrupt handling design"
        - "Startup/shutdown sequence"
        - "Error handling strategy"

    5_safety_architecture:
      content:
        - "Safety mechanism descriptions"
        - "Freedom from interference analysis"
        - "ASIL decomposition rationale"
        - "Fault detection and reaction strategy"

    6_resource_usage:
      content:
        - "Memory budget (ROM, RAM, NVM)"
        - "CPU budget (per task)"
        - "Communication bandwidth budget"
        - "Stack size analysis"
```

### Architecture Decision Record (ADR) Template

```markdown
# ADR-003: Use Fixed-Point Arithmetic for SOC Calculation

## Status
Accepted

## Context
The SOC estimation algorithm requires mathematical computations running
at 1ms cycle time on the target MCU (Infineon TC397). The MCU has a
single-precision FPU but ASIL D requirements demand deterministic
execution time.

## Decision
Use Q16.16 fixed-point arithmetic for all SOC-related calculations.

## Rationale
- Fixed-point provides deterministic execution time (no FPU pipeline stalls)
- WCET is bounded and analyzable by static analysis tools
- Precision (16-bit fractional) is sufficient for SOC (0.001% resolution)
- MISRA compliance: avoids floating-point comparison issues

## Consequences
- Developers must use fixed-point math library functions
- Overflow protection required on all multiply/divide operations
- Calibration parameters must be converted to fixed-point at build time
- Back-to-back testing against float reference model needed

## Alternatives Considered
1. Single-precision float: Better developer ergonomics but WCET varies
2. Double-precision float: No hardware support, too slow
3. Mixed: Float for offline, fixed for real-time: complexity overhead
```

---

## API Documentation

### Code Documentation Standards

```c
/**
 * @brief Compute State of Charge using extended Kalman filter.
 *
 * Combines coulomb counting with voltage-based correction using an
 * EKF to estimate battery SOC. The filter state is maintained between
 * calls and updated each cycle.
 *
 * @param[in]  voltage_v     Terminal voltage in Volts [2.5, 4.3]
 * @param[in]  current_a     Pack current in Amperes [-500, +500]
 *                           (positive = charging)
 * @param[in]  temperature_c Cell temperature in Celsius [-20, 55]
 * @param[in]  dt_s          Time step in seconds (nominally 0.001)
 * @param[in,out] state      EKF state vector (persistent between calls)
 *
 * @return Estimated SOC in percent [0.0, 100.0]
 *
 * @pre voltage_v is within valid ADC range (caller must validate)
 * @pre state has been initialized via soc_ekf_init()
 * @post state is updated with new estimate
 *
 * @safety ASIL C - Part of BMS safety function
 * @req SSR-BMS-020, SSR-BMS-021
 * @testref TC-BMS-SOC-001 through TC-BMS-SOC-042
 *
 * @note WCET: 85 us on TC397 at 300 MHz (measured)
 * @note Called from Task_BmsMain_1ms
 */
float soc_ekf_update(float voltage_v, float current_a,
                      float temperature_c, float dt_s,
                      SocEkfState_t* state);
```

### Doxygen Configuration

```yaml
# Required Doxygen tags for automotive code
doxygen_requirements:
  every_public_function:
    - "@brief"         # One-line summary
    - "@param"         # All parameters with direction [in/out/in,out]
    - "@return"        # Return value description
    - "@pre"           # Preconditions
    - "@safety"        # ASIL classification
    - "@req"           # Requirement traceability

  every_public_class:
    - "@brief"         # Purpose of the class
    - "@safety"        # ASIL classification
    - "@invariant"     # Class invariants

  every_file:
    - "@file"          # Filename
    - "@brief"         # Module purpose
    - "@copyright"     # License information

  optional_but_recommended:
    - "@post"          # Postconditions
    - "@note"          # WCET, calling context, special considerations
    - "@testref"       # Test case references
    - "@warning"       # Usage warnings
```

---

## Diagram Standards

### Required Diagram Types

| Diagram Type | Notation | Tool | When Required |
|-------------|----------|------|--------------|
| Context | Custom/SysML | Enterprise Architect | System design |
| Component | UML/SysML | Enterprise Architect | Architecture |
| Sequence | UML | PlantUML / EA | Key interactions |
| State Machine | UML/Stateflow | PlantUML / EA | Stateful components |
| Data Flow | Custom | Draw.io / EA | Data design |
| Deployment | UML | PlantUML / EA | Multi-ECU systems |

### Diagram Quality Rules

```yaml
diagram_rules:
  - "Every diagram has a title, unique ID, and version"
  - "Every diagram has a legend explaining symbols"
  - "Maximum 15 elements per diagram (split if more)"
  - "Consistent color coding across all diagrams"
  - "Source files version-controlled (not just images)"
  - "PlantUML preferred for text-based diagrams"

  color_coding:
    safety_critical: "#FF6B6B"   # Red - ASIL C/D
    safety_relevant: "#FFD93D"   # Yellow - ASIL A/B
    non_safety: "#6BCB77"        # Green - QM
    external: "#4D96FF"          # Blue - External interfaces
    deprecated: "#C0C0C0"        # Gray - To be removed
```

---

## Review Process

### Document Review Types

| Review Type | When | Participants | Duration |
|-------------|------|-------------|----------|
| Self-review | Before submission | Author | 30 min |
| Peer review | Before formal review | 1-2 peers | 1-2 hours |
| Formal review | Design milestones | Review board | 2-4 hours |
| Safety review | Safety work products | Safety assessor | Half day |
| Customer review | Deliverables | Customer team | Variable |

### Review Checklist

```yaml
review_checklist:
  completeness:
    - "All required sections present"
    - "All referenced documents available"
    - "All TBD items tracked with resolution plan"
    - "All diagrams present and legible"

  correctness:
    - "Technical content accurate"
    - "Consistent with referenced documents"
    - "No contradictions within document"
    - "Requirements testable and unambiguous"

  traceability:
    - "Requirements traced to parent requirements"
    - "Design decisions traced to requirements"
    - "Test cases traced to requirements"
    - "No orphan requirements or test cases"

  safety:
    - "ASIL classifications correct and consistent"
    - "Safety mechanisms documented"
    - "Assumptions and constraints explicitly stated"
    - "Safe states defined and achievable"

  quality:
    - "Active voice, concise sentences"
    - "Consistent terminology throughout"
    - "Spelling and grammar correct"
    - "Formatting follows template"
```

---

## Version Control for Documents

### Document Lifecycle

```
Draft v0.1 -> Review v0.9 -> Approved v1.0 -> Updated v1.1 -> ...
    |              |              |                |
    v              v              v                v
 Working       Review         Released         Released
 (editable)    (frozen)       (baseline)       (baseline)
```

### Document Storage Rules

```yaml
storage_rules:
  format: "Markdown preferred; Word/PDF for external delivery"
  location: "Same repository as source code (docs/ directory)"
  naming: "{DOC-ID}_{title}_{version}.{ext}"
  images: "Stored in docs/images/ with source files"

  branching:
    - "Documentation changes follow same branch/PR workflow as code"
    - "Safety documents require safety engineer review"
    - "Architecture documents require architect review"
    - "API docs auto-generated from code comments"
```

---

## Review Checklist

- [ ] All required work products identified in safety plan
- [ ] Document template used with all mandatory sections
- [ ] Requirements follow EARS/structured format
- [ ] All public APIs documented with Doxygen comments
- [ ] Architecture decisions recorded as ADRs
- [ ] Diagrams version-controlled with source files
- [ ] Review process followed with documented outcomes
- [ ] Traceability complete (requirements <-> design <-> test)
- [ ] ASIL classifications consistent across documents
- [ ] Documents versioned and baselined at milestones
- [ ] Terminology consistent (glossary maintained)
- [ ] All TBD items tracked with resolution timeline

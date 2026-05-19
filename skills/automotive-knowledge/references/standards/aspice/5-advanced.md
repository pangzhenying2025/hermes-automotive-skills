# Automotive SPICE - Advanced Topics

## Achieving Capability Level 3: Established Process

### Prerequisites for Level 3

**Level 2 Achievement**:
- All processes in scope rated L or F at Level 1
- All GP 2.x practices rated L or F
- Processes managed on project basis
- Work products controlled and reviewed

**Organizational Readiness**:
- Management commitment to process standardization
- Resources allocated for process engineering
- Process improvement culture established

### GP 3.1: Process Definition

**Objective**: Deploy a defined standard process tailored for the project.

**Organizational Standard Process (OSP)**:

```
OSP Components:

1. Process Description
   - Purpose and outcomes
   - Entry criteria
   - Activities and tasks
   - Exit criteria
   - Roles and responsibilities

2. Activity Sequences
   - Process flow diagrams
   - Decision points
   - Iteration loops

3. Templates
   - Work product templates
   - Checklists
   - Forms

4. Guidelines
   - When to apply activities
   - How to perform tasks
   - Tool usage instructions

5. Metrics
   - Process performance indicators
   - Collection methods
   - Analysis procedures
```

**Example OSP for SWE.1**:

```markdown
# Standard Process: Software Requirements Analysis (SWE.1)

## Purpose
Transform system requirements into verifiable software requirements.

## Entry Criteria
- System requirements specification approved
- Project plan approved
- Requirements management tool configured

## Activities

### Activity 1: Collect and Analyze Source Requirements
**Responsible**: Software Architect
**Duration**: 2-4 weeks (depending on project size)
**Tasks**:
1.1 Identify system requirements allocated to software
1.2 Identify customer-specific requirements
1.3 Identify safety requirements from HARA
1.4 Identify interface requirements (ICD)
**Deliverable**: Source requirements list
**Tool**: DOORS, Polarion, or Jama

### Activity 2: Specify Software Requirements
**Responsible**: Software Architect + Domain Expert
**Duration**: 4-8 weeks
**Tasks**:
2.1 Apply requirement template (see Template_SWE_Req_v2.1.docx)
2.2 Specify functional requirements
2.3 Specify non-functional requirements (performance, safety, resource)
2.4 Specify interface requirements
2.5 Define verification criteria for each requirement
**Deliverable**: Software Requirements Specification (SRS) draft
**Tool**: DOORS + Microsoft Word export

### Activity 3: Review Requirements
**Responsible**: QA + System Architect + Safety Engineer
**Duration**: 1 week
**Tasks**:
3.1 Prepare review package (SRS + checklist)
3.2 Conduct review meeting
3.3 Document findings (see Template_Review_Record_v1.3.xlsx)
3.4 Assign corrective actions
**Deliverable**: Review record with action items
**Exit condition**: All major findings closed

### Activity 4: Establish Traceability
**Responsible**: Software Architect
**Duration**: 1 week
**Tasks**:
4.1 Create traceability links (system req → software req)
4.2 Verify all system requirements traced
4.3 Identify orphan requirements (no source)
4.4 Export traceability matrix
**Deliverable**: Traceability matrix (Excel or DOORS report)

### Activity 5: Baseline SRS
**Responsible**: Configuration Manager
**Duration**: 1 day
**Tasks**:
5.1 Update version number (following SemVer)
5.2 Tag in version control (Git tag: SRS-v1.0)
5.3 Publish to project repository
5.4 Notify stakeholders
**Deliverable**: Baselined SRS v1.0

## Exit Criteria
- SRS approved by customer/system architect
- All requirements have verification criteria
- Bidirectional traceability established
- Review completed with no open major findings
- SRS under configuration management

## Roles
- **Software Architect**: Owns requirements, coordinates activities
- **Domain Expert**: Provides technical expertise
- **QA Engineer**: Performs independent review
- **Safety Engineer**: Reviews safety requirements
- **Configuration Manager**: Manages baselines

## Metrics
- Requirements count (total, functional, non-functional)
- Requirements stability (% changed per review cycle)
- Review defect density (defects per page)
- Traceability coverage (% system req traced)

## Tailoring Guidelines
- For ASIL C/D projects: Add safety engineer to all reviews
- For projects < 100 requirements: Combine activities 2 and 4
- For agile projects: Perform activities iteratively per sprint

## References
- Template_SWE_Req_v2.1.docx
- Checklist_SRS_Review_v1.5.pdf
- DOORS_User_Guide_v3.0.pdf
```

**Project Tailoring**:

```markdown
# Project XYZ: Tailored SWE.1 Process

## Tailoring Decisions

| OSP Element | Tailoring | Rationale |
|-------------|-----------|-----------|
| Activity 2 duration | 4 weeks (OSP: 4-8 weeks) | Project has only 80 requirements |
| Review participants | Add customer representative | Customer contract requires participation |
| Tool | Use Polarion instead of DOORS | Existing tool in organization |
| Metric: Stability | Skip (new development) | No baseline to compare against |

## Adapted Process
[Process description with tailoring applied]

## Approval
- Process Owner: J. Smith, 2026-02-15
- Project Manager: M. Jones, 2026-02-16
```

### GP 3.2: Process Deployment

**Objective**: Ensure defined process is understood and applied by the project.

**Deployment Activities**:

1. **Process Communication**:
   - Kickoff meeting presenting process
   - Process intranet page with documentation
   - Quick reference cards for daily use

2. **Process Training**:
   ```
   Training Program: SWE.1 Process

   Duration: 4 hours
   Target Audience: Software architects, developers
   Prerequisites: Basic ASPICE awareness

   Modules:
   1. SWE.1 purpose and activities (30 min)
   2. Hands-on: Writing a good requirement (60 min)
   3. Tool training: DOORS basics (90 min)
   4. Review process and checklist walkthrough (30 min)
   5. Q&A and case studies (30 min)

   Assessment: Quiz (pass score 80%)
   Certificate: Valid 2 years
   ```

3. **Process Assets Availability**:
   ```
   Process Asset Library (Intranet):

   /processes/swe1/
   ├── OSP_SWE1_v3.2.pdf           (Standard process)
   ├── templates/
   │   ├── Template_SRS_v2.1.docx
   │   ├── Template_Review_Record_v1.3.xlsx
   │   └── Template_Trace_Matrix_v1.0.xlsx
   ├── checklists/
   │   ├── Checklist_SRS_Review_v1.5.pdf
   │   └── Checklist_Req_Quality_v2.0.pdf
   ├── examples/
   │   ├── Example_SRS_ABS_v1.2.pdf
   │   └── Example_Trace_ESC_v1.0.xlsx
   ├── tools/
   │   ├── DOORS_User_Guide_v3.0.pdf
   │   └── DOORS_Config_SWE1.dpa
   └── training/
       ├── SWE1_Training_Slides_v2.1.pptx
       └── SWE1_Quiz_v1.0.pdf
   ```

4. **Process Monitoring**:
   - Process compliance audits (quarterly)
   - Metrics review (bi-weekly in project meetings)
   - Lessons learned sessions (post-milestone)

## Organizational Process Assets

### Process Asset Library (PAL)

**Structure**:

```
/OrganizationalProcessAssets/
├── StandardProcesses/
│   ├── SWE/
│   │   ├── SWE.1_v3.2.pdf
│   │   ├── SWE.2_v3.1.pdf
│   │   ├── SWE.3_v3.0.pdf
│   │   └── ...
│   ├── SUP/
│   │   ├── SUP.1_v2.5.pdf
│   │   ├── SUP.8_v2.3.pdf
│   │   └── ...
│   └── MAN/
│       └── MAN.3_v3.0.pdf
├── Templates/
│   ├── Requirements/
│   ├── Design/
│   ├── Test/
│   └── Management/
├── Checklists/
├── Guidelines/
│   ├── Coding_Standards_C_v2.1.pdf
│   ├── Coding_Standards_CPP_v2.0.pdf
│   └── Git_Workflow_v1.5.pdf
├── ExampleWorkProducts/
├── Metrics/
│   ├── MetricDefinitions_v1.0.xlsx
│   └── MetricAnalysisDashboard_v2.0.xlsx
└── LessonsLearned/
    ├── 2025_Q4_Retrospective.pdf
    └── 2026_Q1_Retrospective.pdf
```

### Metrics Framework

**Process Performance Metrics**:

```yaml
Metric: Requirements Stability
  Definition: Percentage of requirements changed after baseline
  Formula: (Req_changed / Req_total) × 100%
  Collection_Point: At each requirements review
  Frequency: Per review cycle (typically 2-week sprints)
  Target: < 10% change after SRS baseline
  Responsible: Software Architect
  Tool: DOORS change report

Metric: Review Defect Density
  Definition: Defects found per page of reviewed document
  Formula: Defects_found / Pages_reviewed
  Collection_Point: Review meeting
  Frequency: Per review
  Target: 0.5 - 2.0 defects/page (healthy range)
  Interpretation:
    - < 0.5: Document high quality OR review not thorough
    - 0.5 - 2.0: Normal
    - > 2.0: Document low quality OR reviewers inexperienced
  Responsible: QA Engineer
  Tool: Excel template

Metric: Test Coverage
  Definition: Percentage of code covered by tests
  Formula: (Lines_executed / Lines_total) × 100%
  Collection_Point: After unit test execution
  Frequency: Daily (CI/CD pipeline)
  Target:
    - ASIL A/B: 80% branch coverage
    - ASIL C/D: 100% MC/DC coverage
  Responsible: Test Engineer
  Tool: gcov, Bullseye, VectorCAST

Metric: Schedule Variance
  Definition: Difference between planned and actual completion
  Formula: (Actual_date - Planned_date) / Planned_duration
  Collection_Point: Milestone completion
  Frequency: Per milestone (typically monthly)
  Target: ±10%
  Responsible: Project Manager
  Tool: MS Project, Jira

Metric: Effort Variance
  Definition: Difference between estimated and actual effort
  Formula: (Actual_hours - Estimated_hours) / Estimated_hours × 100%
  Collection_Point: Task completion
  Frequency: Weekly
  Target: ±15%
  Use: Improve future estimation
  Responsible: Project Manager
  Tool: Jira time tracking
```

**Metrics Dashboard Example**:

```
Project ESC-2026 - Metrics Dashboard (Week 12)

Requirements Stability:
  Baseline: 150 requirements
  Changed: 12 requirements (8%)
  Status: ✓ Within target (< 10%)

Review Effectiveness:
  Defects found in review: 45
  Defects found in test: 20
  Review efficiency: 69% (target > 60%) ✓

Test Coverage:
  Statement: 98% ✓
  Branch: 95% ✓
  MC/DC: 92% (target 100%) ⚠
  Action: Focus on state machine logic

Schedule:
  Milestone: SWE.2 Completion
  Planned: Week 12
  Actual: Week 13
  Variance: +8% (within ±10%) ✓

Defect Trends:
  Week 10: 15 defects
  Week 11: 12 defects
  Week 12: 8 defects
  Trend: ↓ Decreasing (good)
```

## Process Improvement (Level 5 Preview)

### Continuous Improvement Cycle

```
Plan-Do-Check-Act (PDCA):

Plan:
  - Identify improvement opportunity (from metrics, retrospectives)
  - Define improvement goal (SMART: Specific, Measurable, Achievable, Relevant, Time-bound)
  - Design improved process

Do:
  - Pilot improved process on one project
  - Train team on changes
  - Collect data during pilot

Check:
  - Analyze pilot results
  - Compare metrics to baseline
  - Gather team feedback

Act:
  - If successful: Roll out to organization, update OSP
  - If not successful: Revise and re-pilot
  - Document lessons learned
```

**Example Improvement**:

```markdown
# Process Improvement Proposal: PI-2026-003

## Problem Statement
Review defect density varies widely across projects (0.2 - 5.0 defects/page),
indicating inconsistent review quality.

## Root Cause Analysis
- Reviewers not trained on review techniques
- Checklists too generic, not tailored to work product type
- Review meetings too long (> 2 hours), reviewers fatigued

## Improvement Proposal
1. Develop role-based review training (4-hour course)
2. Create specific checklists per work product type (SRS, architecture, etc.)
3. Limit review meetings to 90 minutes, focus on critical findings only

## Success Criteria
- Defect density variation reduced to 1.0 - 2.5 defects/page
- 90% of reviewers trained within 6 months
- Review meeting duration < 90 minutes

## Pilot Plan
- Pilot on Project XYZ (next SRS review in 4 weeks)
- Measure: defect density, meeting duration, reviewer satisfaction
- Duration: 3 months (3 review cycles)

## Budget
- Training development: 40 hours (process engineer)
- Checklist development: 20 hours
- Training delivery: 4 hours × 20 people = 80 hours

## Approval
- Process Owner: J. Smith, 2026-03-10
- QA Manager: M. Brown, 2026-03-11
```

## Multi-Site and Supplier Management

### Distributed Development Challenges

**Common Issues**:
- Inconsistent process application across sites
- Communication gaps
- Traceability across organizational boundaries
- Different tool environments

**Solutions**:

1. **Unified Process Asset Library**:
   - Cloud-based repository (SharePoint, Confluence)
   - Single source of truth for all sites
   - Version-controlled process descriptions

2. **Interface Agreements**:
   ```markdown
   # Interface Agreement: Site A (Germany) ↔ Site B (India)

   ## Scope
   - Site A: System requirements, architecture
   - Site B: Detailed design, implementation, unit test

   ## Work Products Exchanged
   | From A to B | From B to A |
   |-------------|-------------|
   | SRS v1.0 | Detailed design spec |
   | Architecture v1.0 | Source code |
   | Test strategy | Unit test report |

   ## Handoff Criteria
   - Site A completes SRS review before handoff
   - Site B acknowledges receipt within 2 business days
   - Questions resolved via weekly call (Tue 14:00 CET)

   ## Tools
   - Requirements: Polarion (shared instance)
   - Code: GitLab (shared repository)
   - Communication: MS Teams, Jira

   ## Metrics
   - Handoff delay: Target < 1 day
   - Clarification requests: Target < 5 per handoff
   ```

3. **Supplier Quality Assurance**:
   ```
   Supplier Assessment Checklist (MAN.3, SUP.1):

   ☐ Supplier has documented software development process
   ☐ Process aligned with ASPICE (Level 2 minimum)
   ☐ Supplier provides evidence (sample SRS, test report)
   ☐ Supplier has configuration management (Git, SVN)
   ☐ Supplier has change management process
   ☐ Supplier commits to regular status reporting (weekly)
   ☐ Supplier agrees to accept audits (quarterly)
   ☐ Escalation path defined (technical and management)
   ☐ Contract includes ASPICE capability requirements
   ☐ Supplier provides training records (ASPICE, tools, domain)
   ```

## Tool Qualification for Safety Projects

**ISO 26262 Tool Classification**:

| Tool Impact | Tool Confidence Level | Qualification Required |
|-------------|----------------------|------------------------|
| TI1: Can introduce errors | TCL3: High confidence | No qualification |
| TI1: Can introduce errors | TCL2: Medium confidence | Qualification recommended |
| TI1: Can introduce errors | TCL1: Low confidence | Qualification required |
| TI2: Can fail to detect errors | TCL3: High confidence | No qualification |
| TI2: Can fail to detect errors | TCL2: Medium confidence | Qualification recommended |
| TI2: Can fail to detect errors | TCL1: Low confidence | Qualification required |

**Example: Compiler Qualification**:

```markdown
# Tool Qualification: GCC ARM Compiler v11.2

## Tool Information
- Tool: GNU Compiler Collection (GCC) for ARM
- Version: 11.2.0
- Supplier: Free Software Foundation
- Use: Compile C/C++ code for ARM Cortex-R52 ECU

## Classification
- Tool Impact: TI1 (can introduce errors via miscompilation)
- Tool Confidence Level: TCL2 (widely used, some validation evidence)
- Conclusion: Qualification recommended

## Qualification Method
Selected method: Validation by comparison (ISO 26262-8:2018, Table 3)

## Validation Approach
1. Develop 100 test cases covering:
   - Data types (int8/16/32, float, struct)
   - Control flow (if, switch, loops)
   - Optimizations (-O0, -O2, -O3)
   - Safety-critical patterns (overflow, array bounds)

2. Compile test cases with GCC 11.2
3. Execute on target hardware
4. Compare output with reference compiler (IAR EWARM 9.20)
5. Acceptance: 100% match with reference compiler

## Validation Results
- Test cases: 100
- Passed: 100
- Failed: 0
- Conclusion: Tool qualified for project use

## Tool Usage Constraints
- Allowed optimization levels: -O0, -O1, -O2
- Forbidden: -O3 (aggressive optimizations not validated)
- Required compiler flags: -Wall -Wextra -Werror
- MISRA C compliance: Checked with separate tool (PC-lint)

## Maintenance
- Re-qualify upon compiler version change
- Monitor GCC bug database for relevant issues
- Document any workarounds in project wiki
```

## Assessment Preparation

### Pre-Assessment Activities (6-8 weeks before)

**Week -8: Initial Readiness Check**
- Internal gap assessment (use ASPICE checklists)
- Identify weak areas
- Assign improvement owners

**Week -6: Evidence Preparation**
- Collect work products for all processes in scope
- Organize evidence repository (one folder per process)
- Prepare traceability demonstrations

**Week -4: Mock Assessment**
- Invite external consultant or peer team
- Perform mock interviews
- Identify gaps in evidence or knowledge

**Week -2: Final Preparation**
- Confirm evidence completeness
- Brief team on assessment process
- Prepare interview schedule with assessor

### Evidence Organization

```
Assessment Evidence Repository/
├── SWE.1/
│   ├── 17-11_SRS_ESC_v1.2.pdf
│   ├── 13-19_Verification_Criteria_v1.0.xlsx
│   ├── 13-22_Trace_Matrix_System_to_SW_v1.0.xlsx
│   ├── 13-16_Review_Record_SRS_20260215.pdf
│   └── README.md (index of evidence)
├── SWE.2/
│   ├── 17-01_Architecture_ESC_v2.0.pdf
│   ├── 17-02_Interfaces_ESC_v1.5.pdf
│   └── ...
├── SUP.1/
│   ├── 08-50_QA_Strategy_v1.0.pdf
│   ├── 08-52_Quality_Criteria_Checklist_v1.3.xlsx
│   ├── Audit_Report_20260120.pdf
│   └── Audit_Report_20260220.pdf
├── SUP.8/
│   ├── 15-01_CM_Strategy_v1.0.pdf
│   ├── Git_Log_Baseline_SWE_v1.0.txt
│   └── Baseline_Report_v1.0_20260301.pdf
└── MAN.3/
    ├── 15-20_Project_Plan_ESC_v2.1.pdf
    ├── 15-21_Status_Report_Week10.pdf
    ├── 15-21_Status_Report_Week11.pdf
    ├── 14-04_Schedule_Gantt_v3.0.xlsx
    └── 14-06_Risk_Register_v2.0.xlsx
```

## Next Steps

For practical application:
- Develop organizational standard processes (OSP)
- Establish process asset library
- Implement metrics collection
- Plan ASPICE assessment

## References

- Automotive SPICE PAM v3.1 Capability Levels 3-5
- ISO/IEC 33020:2015 Process measurement framework
- VDA Guideline: ASPICE Assessment Preparation
- ISO 26262-8:2018 Tool qualification

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Process engineers, quality managers, senior management

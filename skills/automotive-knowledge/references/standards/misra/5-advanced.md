# MISRA C/C++ - Advanced Topics

> **Target Audience**: CI/CD engineers, tool qualification specialists, safety assessors

## MISRA in CI/CD Pipelines

### Pipeline Architecture

```
Developer Workstation          CI/CD Pipeline               Release Gate
|                              |                            |
|  IDE Plugin                  |  Stage 1: Pre-merge        |  Stage 3: Release
|  (QAC, Polyspace)            |  - Incremental analysis    |  - Full codebase analysis
|  Real-time feedback          |  - Changed files only      |  - Zero violations
|  on current file             |  - Block merge on          |  - Compliance report
|                              |    mandatory/required       |  - Deviation audit
|                              |    violation                |
|                              |                            |
|                              |  Stage 2: Nightly          |
|                              |  - Full codebase analysis  |
|                              |  - Trend tracking          |
|                              |  - New violation alerts    |
```

### Jenkins Pipeline Example

```groovy
pipeline {
    agent { label 'static-analysis' }

    stages {
        stage('MISRA Incremental Check') {
            when { changeRequest() }
            steps {
                script {
                    def changedFiles = sh(
                        script: "git diff --name-only origin/main...HEAD -- '*.c' '*.h'",
                        returnStdout: true
                    ).trim().split('\n')

                    sh """
                        qacli analyze \
                            --project ${WORKSPACE}/qac_project.prj \
                            --files ${changedFiles.join(' ')} \
                            --ruleset misra_c_2012_mandatory_required
                    """
                }
            }
        }

        stage('MISRA Report') {
            steps {
                sh """
                    qacli report \
                        --project ${WORKSPACE}/qac_project.prj \
                        --format sarif \
                        --output ${WORKSPACE}/misra_report.sarif
                """
                recordIssues(
                    tools: [sarif(pattern: 'misra_report.sarif')],
                    qualityGates: [
                        [threshold: 0, type: 'TOTAL_ERROR', criticality: 'FAILURE']
                    ]
                )
            }
        }

        stage('MISRA Full Analysis') {
            when { branch 'main' }
            steps {
                sh """
                    qacli analyze \
                        --project ${WORKSPACE}/qac_project.prj \
                        --full \
                        --ruleset misra_c_2012_all
                """
                sh """
                    qacli report \
                        --project ${WORKSPACE}/qac_project.prj \
                        --format compliance \
                        --output ${WORKSPACE}/compliance_matrix.html
                """
                archiveArtifacts artifacts: 'compliance_matrix.html'
            }
        }
    }

    post {
        always {
            sh """
                qacli metrics \
                    --project ${WORKSPACE}/qac_project.prj \
                    --format json \
                    --output ${WORKSPACE}/misra_metrics.json
            """
            // Push metrics to dashboard
        }
    }
}
```

### GitLab CI Example

```yaml
misra-check:
  stage: analyze
  image: registry.example.com/polyspace:2024a
  script:
    - polyspace-bug-finder-server
        -sources src/
        -I include/
        -misra-c-2012-mandatory enable-all
        -misra-c-2012-required enable-all
        -misra-c-2012-advisory enable-all
        -results-dir $CI_PROJECT_DIR/results
        -report $CI_PROJECT_DIR/misra_report.pdf
  artifacts:
    reports:
      codequality: results/codequality.json
    paths:
      - misra_report.pdf
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

misra-compliance-gate:
  stage: gate
  script:
    - python3 scripts/check_misra_compliance.py
        --report results/misra_results.json
        --max-mandatory 0
        --max-required 0
        --max-advisory 50
        --deviation-db deviations/approved.json
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

### Baseline Management

**Problem**: Legacy codebase has thousands of existing violations. Cannot fix all at once.

**Solution**: Baseline approach - track only new violations.

```
Baseline Strategy:
1. Run full analysis, record all violations as "baseline"
2. In CI, only fail on violations NOT in baseline
3. Progressively reduce baseline by fixing violations
4. Track baseline reduction as a KPI

Implementation:
  $ qacli analyze --full --output baseline_v1.json          # Create baseline
  $ qacli analyze --full --baseline baseline_v1.json        # Check new only
  $ qacli diff baseline_v1.json current.json --new-only     # Show new violations
```

**Baseline Reduction Plan**:

| Quarter | Mandatory Baseline | Required Baseline | Advisory Baseline |
|---------|-------------------|-------------------|-------------------|
| Q1 2026 | 0 (must be zero) | 450 | 1,200 |
| Q2 2026 | 0 | 300 (-33%) | 1,000 (-17%) |
| Q3 2026 | 0 | 150 (-50%) | 800 (-20%) |
| Q4 2026 | 0 | 0 (target) | 600 (-25%) |

## Tool Qualification per ISO 26262

### Tool Confidence Level (TCL)

ISO 26262 Part 8 requires classification of development tools.

**MISRA Static Analysis Tool Classification**:

```
Tool Impact (TI):
  TI1 - Tool can introduce errors that go undetected
  TI2 - Tool cannot introduce errors (or errors are detected)

  MISRA checker: TI2
  (It detects issues but does not modify code; missed violations
   could lead to undetected issues -> some argue TI1)

Tool Error Detection (TD):
  TD1 - High degree of confidence in preventing erroneous output
  TD2 - Medium confidence
  TD3 - Low confidence

  Certified tool (Polyspace, QAC): TD1
  Uncertified tool (cppcheck): TD3

Tool Confidence Level:
  TCL = f(TI, TD)
  |     | TD1 | TD2 | TD3 |
  |-----|-----|-----|-----|
  | TI1 | TCL2| TCL2| TCL3|
  | TI2 | TCL1| TCL1| TCL2|

  Certified MISRA tool: TI2 + TD1 -> TCL1 (no qualification needed)
  Uncertified MISRA tool: TI2 + TD3 -> TCL2 (qualification required)
```

### Qualification Methods for TCL2 Tools

If using an uncertified tool (e.g., cppcheck, clang-tidy for MISRA):

**Method 1: Increased Confidence from Use**
```
Requirements:
1. Document tool version and configuration
2. Collect use history (>12 months in similar projects)
3. Document known limitations and false negative analysis
4. Track tool bugs discovered during use
5. Demonstrate that tool limitations do not impact safety
```

**Method 2: Tool Validation**
```
Requirements:
1. Define tool operational requirements (what rules, what language features)
2. Create test suite covering each claimed MISRA rule
3. For each rule: positive test (violation present, tool detects)
4. For each rule: negative test (no violation, tool silent)
5. Document false positive rate and false negative rate
6. Achieve target detection rate per ASIL:
   ASIL A/B: >90% detection rate
   ASIL C/D: >95% detection rate
```

### Tool Validation Test Suite Structure

```
test_suite/
|
+-- rule_10_1/
|   +-- positive/
|   |   +-- test_signed_unsigned_add.c      # Should flag violation
|   |   +-- test_bool_in_arithmetic.c       # Should flag violation
|   |   +-- test_enum_in_shift.c            # Should flag violation
|   +-- negative/
|       +-- test_same_type_add.c            # Should not flag
|       +-- test_explicit_cast.c            # Should not flag
|
+-- rule_10_3/
|   +-- positive/
|   |   +-- test_narrow_assignment.c
|   +-- negative/
|       +-- test_widen_assignment.c
|
+-- results/
    +-- detection_matrix.csv
    +-- false_positive_log.csv
    +-- false_negative_log.csv
```

**Detection Matrix Format**:

| Rule | Positive Tests | Detected | Missed | Detection Rate | FP Tests | False Positives | FP Rate |
|------|---------------|----------|--------|---------------|----------|----------------|---------|
| 10.1 | 15 | 14 | 1 | 93.3% | 10 | 2 | 20% |
| 10.3 | 12 | 12 | 0 | 100% | 8 | 1 | 12.5% |
| 11.3 | 8 | 7 | 1 | 87.5% | 6 | 0 | 0% |

## MISRA C++:2023 Migration Strategy

### From MISRA C++:2008

**Phase 1: Assessment (2-4 weeks)**
```
1. Map existing C++:2008 rule compliance to C++:2023 equivalents
2. Identify rules removed (relaxations)
3. Identify new rules (additional restrictions)
4. Assess C++17 feature adoption readiness
5. Evaluate tool support for C++:2023
```

**Phase 2: Tool Update (2-4 weeks)**
```
1. Update static analysis tool to C++:2023-capable version
2. Configure new rule set
3. Run baseline analysis with C++:2023 rules
4. Compare with C++:2008 baseline (identify delta)
5. Update deviation records for new rule numbers
```

**Phase 3: Code Migration (ongoing)**
```
Priority 1: Address new mandatory/required rule violations
Priority 2: Adopt modern C++ features for safety benefit
  - Replace raw pointers with smart pointers
  - Replace C-style casts with C++ casts
  - Replace #define constants with constexpr
  - Replace NULL with nullptr
  - Adopt fixed-width integer types
Priority 3: Reduce advisory violations
```

### Key C++:2023 Additions

| New Rule Area | Rationale | Example |
|---------------|-----------|---------|
| Lambda safety | Capture semantics can cause dangling references | No capture by reference of local variables |
| Move semantics | Use-after-move is undefined behavior | Check moved-from state before use |
| constexpr | Compile-time evaluation is safer | Prefer constexpr for constants |
| Smart pointers | Automatic memory management | Replace raw new/delete |
| std::optional | Explicit absence handling | Replace null pointer patterns |
| Structured bindings | Clearer intent | Use for multi-value returns |
| Concepts (partial) | Better template error messages | Constrain template parameters |

## Multi-Tool Analysis Strategy

### Defense in Depth

No single tool catches all violations. Use multiple tools in combination:

```
Layer 1: IDE Plugin (Developer Desktop)
  Tool: QAC IDE plugin or Polyspace Access
  Speed: Real-time (per-file)
  Coverage: ~80% of rules
  Purpose: Immediate feedback during coding

Layer 2: Pre-commit Hook
  Tool: cppcheck + clang-tidy (fast, open source)
  Speed: <30 seconds for changed files
  Coverage: ~40% of rules (critical subset)
  Purpose: Catch obvious violations before commit

Layer 3: CI Pipeline (Per-merge-request)
  Tool: QAC or Polyspace (certified, thorough)
  Speed: 5-30 minutes for changed files
  Coverage: ~95% of decidable rules
  Purpose: Gating check for merge approval

Layer 4: Nightly Full Analysis
  Tool: Polyspace Code Prover (abstract interpretation)
  Speed: Hours for full codebase
  Coverage: Undecidable rules (runtime errors, overflows)
  Purpose: Deep analysis, trend tracking
```

### False Positive Management

| Strategy | Description | When to Use |
|----------|-------------|-------------|
| Suppression comment | In-code annotation marking false positive | When tool incorrectly flags compliant code |
| Configuration tuning | Adjust tool parameters | When tool sensitivity too high for project |
| Deviation record | Formal deviation for true positive accepted | When rule genuinely cannot be followed |
| Tool-specific filter | Suppress in tool configuration | When pattern is known false positive |

**Suppression Comment Standard**:
```c
/* polyspace<MISRA-C:2012:11.3:Not a defect:Justify with text>
   Hardware register access per HAL specification.
   See DEV-MISRA-001 */
volatile uint32_t *reg = (volatile uint32_t *)HW_REG_ADDR;
```

## MISRA Compliance Metrics and Reporting

### Key Performance Indicators

| KPI | Formula | Target |
|-----|---------|--------|
| Compliance rate | (Rules compliant / Rules applicable) x 100% | >98% |
| Violation density | Violations / KLOC | <2.0 |
| Deviation density | Deviations / KLOC | <0.5 |
| Baseline reduction rate | (Previous - Current) / Previous x 100% | >25% per quarter |
| False positive rate | False positives / Total findings x 100% | <15% |
| Time to resolve | Average days from detection to fix | <5 days |

### Compliance Dashboard

```
MISRA Compliance Report - Project: ECU-Brake v3.2
Date: 2026-03-19
Tool: QAC v2024.1 (TUV SUD Certified)
Codebase: 85,000 LOC across 342 files

Summary:
  Mandatory rules: 10/10 compliant (100%)
  Required rules:  119/121 compliant (98.3%)
  Advisory rules:  10/12 adopted (83.3%)

  Total violations: 47
    Mandatory: 0
    Required:  12 (all with approved deviations)
    Advisory:  35 (17 with deviations, 18 under review)

  Deviation summary:
    Approved: 29
    Pending review: 18
    Expired (need renewal): 0

  Trend (vs. last quarter):
    Required violations: -8 (was 20, now 12)
    Advisory violations: -15 (was 50, now 35)
    New deviations: +3
    Closed deviations: +11
```

## Advanced: MISRA and AUTOSAR C++14 Guidelines Coexistence

### Overlap and Conflicts

For AUTOSAR Adaptive Platform development, both MISRA C++:2023 and AUTOSAR C++14 Guidelines may apply.

| Area | MISRA C++:2023 | AUTOSAR C++14 | Resolution |
|------|---------------|---------------|------------|
| Exceptions | Context-dependent | Allowed with constraints | Follow AUTOSAR (platform uses exceptions) |
| Dynamic memory | Restricted | Allowed in application code | Follow AUTOSAR (Adaptive uses dynamic allocation) |
| RTTI | Restricted | Allowed for service discovery | Follow AUTOSAR (ara::com uses RTTI) |
| Templates | Allowed with constraints | Heavily used | Union of both rule sets |
| Naming | Not specified | Specified per component type | Follow AUTOSAR naming |

### Unified Configuration

```
# Combined rule set for AUTOSAR Adaptive project
# Base: MISRA C++:2023
# Override: AUTOSAR C++14 where conflict exists

enable misra_cpp_2023 all
enable autosar_cpp14 all

# Resolve conflicts: AUTOSAR takes precedence for platform code
suppress misra_cpp_2023 15.5.1  # Exceptions allowed in AUTOSAR
suppress misra_cpp_2023 15.1.3  # Dynamic memory allowed for ara::
suppress misra_cpp_2023 18.5.1  # RTTI allowed for service discovery

# MISRA takes precedence for safety-critical application code
# (applied via file-scope configuration)
scope "src/safety/*" {
    enforce misra_cpp_2023 15.5.1  # No exceptions in safety code
    enforce misra_cpp_2023 15.1.3  # No dynamic memory in safety code
}
```

## Next Steps

For practical application of advanced MISRA topics:
- Set up CI/CD pipeline with MISRA gating (see Jenkins/GitLab examples above)
- Qualify your static analysis tool per ISO 26262 Part 8
- Plan MISRA C++:2023 migration if currently on C++:2008
- Establish baseline management for legacy codebases
- Implement multi-tool analysis strategy for defense in depth

## References

- MISRA Compliance:2020 (Compliance framework)
- ISO 26262-8:2018 Clause 11 (Tool qualification)
- ISO 26262-6:2018 Tables 1-13 (Software development methods)
- AUTOSAR C++14 Coding Guidelines (Release 19-03)
- MISRA C++:2023 (Complete guideline document)
- IEC 61508-3:2010 Annex C (Coding standards for SIL)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: CI/CD engineers, tool qualification specialists, safety assessors

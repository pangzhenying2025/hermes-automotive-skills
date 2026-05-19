# CI/CD for Automotive Software - Level 2: Conceptual Architecture

> Audience: System architects, senior engineers, technical leads
> Purpose: Understand CI/CD pipeline architecture and design patterns

## Pipeline Architecture

### Multi-Stage Pipeline Design

```
+------------------------------------------------------------------+
|                        Developer Workstation                      |
|  Pre-commit hooks: formatting, linting, secret scan              |
+------------------------------------------------------------------+
          |
          v (git push)
+------------------------------------------------------------------+
|                     Stage 1: Build Gate                           |
|  Cross-compile (ARM/x86) | Dependency resolution | Artifact gen  |
|  Time: 5-15 min | Trigger: every push                           |
+------------------------------------------------------------------+
          |
          v (on success)
+------------------------------------------------------------------+
|                  Stage 2: Static Analysis Gate                    |
|  MISRA C/C++ | Polyspace | Coverity | Complexity metrics         |
|  Time: 10-30 min | Trigger: every push                          |
+------------------------------------------------------------------+
          |
          v (on success)
+------------------------------------------------------------------+
|                  Stage 3: Unit Test Gate                          |
|  GoogleTest/JUnit | Coverage (MC/DC for ASIL) | Mutation testing |
|  Time: 5-20 min | Trigger: every push                           |
+------------------------------------------------------------------+
          |
          v (on success)
+------------------------------------------------------------------+
|                  Stage 4: Integration Test Gate                   |
|  SIL simulation | API contract tests | Service integration       |
|  Time: 30-60 min | Trigger: merge to develop                    |
+------------------------------------------------------------------+
          |
          v (on success)
+------------------------------------------------------------------+
|                  Stage 5: HIL Test Gate                           |
|  Hardware-in-the-loop | Real ECU targets | Timing validation     |
|  Time: 1-4 hours | Trigger: release candidate                   |
+------------------------------------------------------------------+
          |
          v (on success)
+------------------------------------------------------------------+
|                  Stage 6: Release Gate                            |
|  Package signing | OTA bundle creation | Approval workflow       |
|  Time: 15-30 min | Trigger: manual approval                     |
+------------------------------------------------------------------+
```

### Build Infrastructure

```
+-------------------+     +-------------------+
| Jenkins Master    |     | GitLab CI Server  |
| (orchestration)   |     | (alternative)     |
+-------------------+     +-------------------+
         |
         +------------------------------------------+
         |                    |                      |
+--------v-------+   +-------v--------+   +---------v------+
| Build Agents   |   | Analysis Agents|   | HIL Agents     |
| - ARM cross-   |   | - MISRA tools  |   | - dSPACE HIL   |
|   compiler     |   | - Polyspace    |   | - Vector VT    |
| - x86 native   |   | - Coverity     |   | - NI teststand |
| - QEMU targets |   | - SonarQube    |   | - Custom rigs  |
+----------------+   +----------------+   +----------------+
```

## Build System Patterns

### Reproducible Builds

Every build must produce identical output given the same inputs:

| Component | Strategy |
|-----------|---------|
| Compiler version | Docker container with pinned toolchain |
| Dependencies | Lock files, vendored or cached artifacts |
| Build timestamp | Normalized or excluded from binary |
| Source code | Git commit SHA as build identifier |
| Environment | Containerized build agents |

### Cross-Compilation Strategy

```
Source Code
    |
    +-- Host Build (x86_64-linux)
    |     Used for: unit tests, SIL simulation, static analysis
    |
    +-- Target Build (aarch64-poky-linux / arm-none-eabi)
    |     Used for: ECU deployment, HIL testing
    |
    +-- SDK Build (populate_sdk)
          Used for: developer workstation cross-compilation
```

## Quality Gates

### Gate Configuration Pattern

| Gate | Metric | Threshold | Action on Fail |
|------|--------|-----------|---------------|
| Build | Compilation | Zero errors, zero warnings | Block merge |
| MISRA | Rule violations | Zero mandatory, <5 advisory | Block merge |
| Coverage | Line coverage | >= 80% overall | Block merge |
| Coverage | MC/DC (ASIL code) | >= 100% | Block merge |
| Complexity | Cyclomatic | <= 15 per function | Warning |
| Security | CVE scan | Zero critical/high | Block merge |
| Integration | Test pass rate | 100% | Block merge |
| Performance | Timing budget | Within WCET budget | Block release |

### Branch Protection Model

```
feature/* ---(PR + gates)--> develop ---(gates + approval)--> release/*
                                                                  |
                                                            (tag + sign)
                                                                  |
                                                                  v
                                                               main
```

## Artifact Management

### Artifact Types

| Type | Format | Storage | Retention |
|------|--------|---------|-----------|
| Build binaries | .elf, .hex, .bin | Artifactory/Nexus | 2 years |
| Test reports | JUnit XML, HTML | CI server + archive | 5 years |
| Coverage data | Cobertura XML, LCOV | CI server + archive | 5 years |
| MISRA reports | CSV, HTML | Compliance archive | 10 years |
| Signed packages | .swu, .raucb | OTA server | Permanent |
| SBOM | SPDX, CycloneDX | Compliance archive | 10 years |

### Traceability

Every release artifact must trace back to:
- Source code commit (Git SHA)
- Build configuration (CMake options, compiler flags)
- Test results (pass/fail for every test case)
- Static analysis results (clean report)
- Requirements coverage (which requirements tested)
- Approval records (who approved the release)

## Environment Strategy

| Environment | Purpose | Infrastructure |
|-------------|---------|---------------|
| Dev | Developer testing | Local Docker + QEMU |
| CI | Automated pipeline | Jenkins agents + containers |
| SIL | Software simulation | Virtual ECU clusters |
| HIL | Hardware testing | dSPACE/Vector test benches |
| Staging | Pre-production validation | Fleet test vehicles |
| Production | Live deployment | Customer vehicles via OTA |

## Notification and Feedback

- **Build failure**: Immediate Slack/Teams notification to committer
- **Gate failure**: Detailed report with fix suggestions
- **Release ready**: Notification to release manager and safety team
- **Deployment status**: Real-time dashboard for fleet rollout

## Summary

Automotive CI/CD architecture requires multi-stage pipelines with strict
quality gates for safety compliance. Reproducible builds, cross-compilation
support, and HIL integration are essential. The pipeline must generate
and preserve compliance evidence (test results, coverage, MISRA reports)
for the lifetime of the vehicle. Artifact traceability from source to
deployed binary is non-negotiable for ISO 26262 compliance.

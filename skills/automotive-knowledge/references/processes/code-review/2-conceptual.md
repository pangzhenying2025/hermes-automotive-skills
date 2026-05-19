# Code Review for Automotive Software - Level 2: Conceptual Architecture

> Audience: System architects, senior engineers, technical leads
> Purpose: Design effective code review processes and workflows

## Review Process Architecture

### Review Workflow

```
Developer submits PR
        |
        v
+-------------------+
| Automated Checks  |  <-- CI pipeline (build, test, MISRA, coverage)
| (pre-review gate) |
+-------------------+
        |
        v (all checks pass)
+-------------------+
| Reviewer Assignment|  <-- Based on code ownership, expertise, availability
+-------------------+
        |
        v
+-------------------+
| Peer Review       |  <-- Technical correctness, style, maintainability
| (1-2 reviewers)   |
+-------------------+
        |
        v (for safety-critical code)
+-------------------+
| Safety Review     |  <-- ASIL compliance, safety mechanisms, fault handling
| (safety engineer) |
+-------------------+
        |
        v (for security-sensitive code)
+-------------------+
| Security Review   |  <-- Vulnerability assessment, threat modeling check
| (security expert) |
+-------------------+
        |
        v (all approvals obtained)
+-------------------+
| Merge             |  <-- Squash merge to main branch
+-------------------+
```

### Review Roles

| Role | Responsibility | Required For |
|------|---------------|-------------|
| Author | Write clear PR description, respond to feedback | All PRs |
| Peer Reviewer | Technical correctness, code quality, tests | All PRs |
| Safety Reviewer | ASIL compliance, safety mechanisms | ASIL B/C/D code |
| Security Reviewer | Vulnerability assessment | Network, crypto, auth code |
| Architecture Reviewer | Design consistency, system impact | Cross-module changes |
| Domain Expert | Domain-specific correctness | Algorithm changes |

## Review Scope by ASIL Level

| ASIL | Min Reviewers | Safety Reviewer | Formal Inspection | Checklist |
|------|--------------|----------------|-------------------|-----------|
| QM | 1 | No | No | Basic |
| ASIL A | 1 | Recommended | No | Standard |
| ASIL B | 1 | Required | No | Standard + Safety |
| ASIL C | 2 | Required | Recommended | Full Safety |
| ASIL D | 2 | Required | Required | Full Safety |

## Review Checklists

### General Checklist

- [ ] Code compiles without warnings
- [ ] All tests pass, new tests added for new functionality
- [ ] No commented-out code or debug prints
- [ ] Error handling is complete and appropriate
- [ ] Constants are named, no magic numbers
- [ ] Functions are < 50 lines, files < 500 lines
- [ ] Public APIs have documentation
- [ ] No TODOs without ticket references

### Safety Checklist (ASIL B+)

- [ ] Safety requirements traced to implementation
- [ ] Defensive programming: bounds checks, null checks
- [ ] No dynamic memory allocation after initialization
- [ ] Fault detection mechanisms present and tested
- [ ] Safe state transitions documented and implemented
- [ ] Watchdog interaction correct
- [ ] MISRA deviations documented with justification
- [ ] No single point of failure in safety path

### Security Checklist

- [ ] Input validation at trust boundaries
- [ ] No hardcoded credentials or keys
- [ ] Cryptographic operations use approved algorithms
- [ ] Buffer overflow prevention (bounds checking)
- [ ] Integer overflow protection
- [ ] Secure communication channels used
- [ ] Least privilege principle applied
- [ ] Error messages do not leak internal details

## Code Ownership Model

```
Repository
  |
  +-- CODEOWNERS file
  |     src/safety/*          @safety-team @team-lead
  |     src/crypto/*          @security-team
  |     src/drivers/*         @platform-team
  |     src/app/*             @app-team
  |     *.proto               @architecture-team
  |     CMakeLists.txt        @build-team
  |
  +-- Automatic reviewer assignment based on changed files
```

## Review Metrics and Quality

### Healthy Review Culture Indicators

| Metric | Healthy | Unhealthy |
|--------|---------|-----------|
| Avg review time | 4-8 hours | > 48 hours |
| Lines per review | 200-400 | > 1000 |
| Comments per review | 3-8 | 0 or > 20 |
| Approval without comments | < 30% | > 70% |
| Review iterations | 1-2 | > 4 |
| Defects found in review | Regular | Never |

### Anti-Patterns to Avoid

- **Rubber stamping**: Approving without reading
- **Nitpicking**: Focusing only on style, ignoring logic
- **Gatekeeping**: One reviewer blocking all merges
- **Drive-by reviews**: Approving to clear queue
- **Hero reviewer**: One person reviews everything
- **Marathon reviews**: Reviewing 1000+ lines at once

## Integration with CI/CD

```
PR Created --> CI Pipeline Runs --> Automated Checks Pass
                                          |
                                          v
                                    Human Review Begins
                                          |
                                          v
                              Review Comments Addressed
                                          |
                                          v
                              CI Re-runs on Updated Code
                                          |
                                          v
                              Approval + Merge
```

Automated checks that must pass before human review:
- Build succeeds (zero warnings)
- All existing tests pass
- New tests present for new code
- Coverage thresholds met
- MISRA analysis clean
- No security vulnerabilities detected

## Summary

Effective automotive code review requires role-based review assignment,
ASIL-appropriate rigor levels, structured checklists for safety and
security, and integration with CI/CD automation. Code ownership models
ensure the right experts review the right code. Metrics help maintain
review quality and prevent anti-patterns.

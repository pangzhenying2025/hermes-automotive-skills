# Code Review for Automotive Software - Level 4: Reference

> Audience: Developers needing quick lookup for review guidelines
> Purpose: Rapid reference for review checklists, criteria, and processes

## Review Type Selection

| Change Type | Review Type | Reviewers | Turnaround |
|-------------|-----------|-----------|-----------|
| Bug fix (QM) | PR review | 1 peer | 24 hours |
| Feature (QM) | PR review | 1 peer | 24 hours |
| Bug fix (ASIL A/B) | PR review + safety | 1 peer + 1 safety | 24 hours |
| Feature (ASIL A/B) | PR review + safety | 1 peer + 1 safety | 48 hours |
| Any (ASIL C/D) | Formal inspection | 2 peers + 1 safety | 72 hours |
| Security change | PR + security review | 1 peer + 1 security | 48 hours |
| Architecture change | PR + arch review | 1 peer + 1 architect | 48 hours |
| Hotfix (production) | Expedited PR | 1 senior + 1 safety | 4 hours |

## MISRA C:2012 Common Review Findings

| Rule | Description | Severity |
|------|-------------|----------|
| 1.3 | Undefined behavior | Mandatory |
| 10.3 | Implicit type conversion | Required |
| 11.3 | Cast between pointer and integer | Required |
| 12.2 | Shift operator range | Required |
| 14.3 | Controlling expression is invariant | Required |
| 17.7 | Return value of non-void function unused | Required |
| 18.1 | Pointer arithmetic out of bounds | Mandatory |
| 21.3 | Memory allocation (malloc/free) | Required |
| 21.6 | Standard I/O (printf) | Required |

## PR Size Guidelines

| Size (lines changed) | Category | Expected Review Time |
|---------------------|----------|---------------------|
| 1-50 | Small | 15-30 minutes |
| 51-200 | Medium | 30-60 minutes |
| 201-400 | Large | 1-2 hours |
| 401-800 | Too Large | Split recommended |
| 800+ | Unacceptable | Must split |

## Review Comment Severity

| Level | Prefix | Meaning | Action Required |
|-------|--------|---------|----------------|
| Blocker | [BLOCKER] | Defect, safety issue, or vulnerability | Must fix before merge |
| Major | [MAJOR] | Significant quality issue | Must fix before merge |
| Minor | [MINOR] | Style, naming, minor improvement | Should fix, can defer |
| Suggestion | [SUGGESTION] | Alternative approach | Optional, discuss |
| Question | [QUESTION] | Clarification needed | Author must respond |
| Praise | [PRAISE] | Good work acknowledgment | No action needed |

## Common Review Defect Categories

| Category | Examples | ASIL Impact |
|----------|---------|-------------|
| Null pointer | Missing null check before dereference | High |
| Buffer overflow | Array access without bounds check | Critical |
| Integer overflow | Arithmetic without range check | High |
| Resource leak | Missing close/free in error path | Medium |
| Race condition | Shared data without synchronization | High |
| Dead code | Unreachable branches, unused variables | Low |
| Magic numbers | Hardcoded values without names | Low |
| Missing error handling | Ignored return values | Medium |
| Copy-paste errors | Duplicated code with wrong variable | High |

## CODEOWNERS File Template

```
# Default reviewers
*                           @team-lead

# Safety-critical code
src/safety/                 @safety-team @team-lead
src/fault/                  @safety-team
src/watchdog/               @safety-team

# Security
src/crypto/                 @security-team
src/auth/                   @security-team
src/secoc/                  @security-team

# Platform/drivers
src/drivers/                @platform-team
src/hal/                    @platform-team
src/bsp/                    @platform-team

# Build system
CMakeLists.txt              @build-team
cmake/                      @build-team
Dockerfile                  @devops-team

# Configuration
*.proto                     @architecture-team
*.dbc                       @can-team
*.yaml                      @team-lead

# Tests
tests/                      @qa-team
```

## Review Metrics Dashboard

| Metric | Formula | Target |
|--------|---------|--------|
| Review turnaround | Median(PR created to first review) | < 8 hours |
| Review cycle time | Median(PR created to merged) | < 48 hours |
| Review thoroughness | Defects found / PR count | > 0.5 |
| Review load balance | StdDev(reviews per person) | Low |
| Rework rate | PRs with > 2 review rounds / total PRs | < 20% |
| Approval rate | Approved on first review / total | > 40% |

## Keyboard Shortcuts (GitHub)

| Action | Shortcut |
|--------|----------|
| Navigate to files changed | t |
| Add comment on line | Click line number |
| Start review | Click "Start a review" |
| Submit review | Ctrl+Enter in review summary |
| View file tree | Click file tree icon |
| Collapse file | Click file header |
| Next/previous file | n / p |

## Summary

This reference provides quick lookup for review type selection based on
change characteristics and ASIL level, common MISRA findings, PR sizing
guidelines, comment severity levels, defect categories, CODEOWNERS
templates, and review metrics.

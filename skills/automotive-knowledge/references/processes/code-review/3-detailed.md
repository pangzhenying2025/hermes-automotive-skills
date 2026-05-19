# Code Review for Automotive Software - Level 3: Detailed Implementation

> Audience: Developers and team leads implementing review processes
> Purpose: Practical templates, automation scripts, and review guidance

## Pull Request Template

```markdown
## Description
<!-- What does this PR do? Why is it needed? -->

## Related Items
- Jira: ECUBE-XXXX
- Requirements: REQ-SW-XXXX
- Safety concept: SC-XXXX (if ASIL)

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that changes existing behavior)
- [ ] Safety-critical change (affects ASIL-rated functionality)
- [ ] Security change (affects authentication, crypto, or network)

## ASIL Classification
- [ ] QM (quality managed, no safety relevance)
- [ ] ASIL A
- [ ] ASIL B
- [ ] ASIL C
- [ ] ASIL D

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed (describe below)
- [ ] HIL testing required (attach results)

## Checklist
- [ ] Code follows project coding standards
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No warnings introduced
- [ ] MISRA analysis clean (or deviations documented)
```

## Automated Review Assignment

```python
#!/usr/bin/env python3
"""Assign reviewers based on changed files and CODEOWNERS."""

import re
import subprocess
from pathlib import Path
from typing import Optional


def get_changed_files(base_branch: str = "develop") -> list[str]:
    """Get list of files changed in current branch."""
    result = subprocess.run(
        ["git", "diff", "--name-only", f"origin/{base_branch}...HEAD"],
        capture_output=True, text=True, check=True)
    return [f.strip() for f in result.stdout.strip().split("\n") if f.strip()]


def parse_codeowners(codeowners_path: str = "CODEOWNERS") -> list[tuple[str, list[str]]]:
    """Parse CODEOWNERS file into pattern-owner pairs."""
    rules = []
    with open(codeowners_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            pattern = parts[0]
            owners = [p.lstrip("@") for p in parts[1:]]
            rules.append((pattern, owners))
    return rules


def match_owners(filepath: str,
                 rules: list[tuple[str, list[str]]]) -> list[str]:
    """Find owners for a given file path."""
    matched_owners: list[str] = []
    for pattern, owners in rules:
        # Convert CODEOWNERS glob to regex
        regex = pattern.replace("*", "[^/]*").replace("**", ".*")
        if re.match(regex, filepath):
            matched_owners = owners  # Last match wins
    return matched_owners


def determine_review_level(changed_files: list[str]) -> dict:
    """Determine required review level based on changed files."""
    result = {
        "safety_review": False,
        "security_review": False,
        "architecture_review": False,
        "min_reviewers": 1,
    }

    safety_patterns = ["src/safety/", "src/fault/", "src/watchdog/"]
    security_patterns = ["src/crypto/", "src/auth/", "src/tls/", "src/secoc/"]
    arch_patterns = ["*.proto", "api/", "include/public/"]

    for f in changed_files:
        if any(f.startswith(p) or f.endswith(p.lstrip("*")) for p in safety_patterns):
            result["safety_review"] = True
            result["min_reviewers"] = max(result["min_reviewers"], 2)
        if any(f.startswith(p) or f.endswith(p.lstrip("*")) for p in security_patterns):
            result["security_review"] = True
        if any(f.startswith(p) or f.endswith(p.lstrip("*")) for p in arch_patterns):
            result["architecture_review"] = True

    return result


def assign_reviewers(pr_author: str) -> dict:
    """Main function to assign reviewers for a PR."""
    changed_files = get_changed_files()
    rules = parse_codeowners()
    review_level = determine_review_level(changed_files)

    all_owners: set[str] = set()
    for f in changed_files:
        owners = match_owners(f, rules)
        all_owners.update(owners)

    # Remove PR author from reviewers
    all_owners.discard(pr_author)

    return {
        "reviewers": list(all_owners),
        "review_level": review_level,
        "changed_files": changed_files,
    }
```

## Review Comment Templates

### Defect Found

```
**[DEFECT]** Potential null pointer dereference

The pointer `sensor_data` is used at line 45 without null check.
If `get_sensor_data()` returns NULL (e.g., sensor offline), this
will cause undefined behavior.

**Suggestion:**
```c
SensorData_t* sensor_data = get_sensor_data();
if (sensor_data == NULL) {
    log_error("Sensor data unavailable");
    return SENSOR_ERROR;
}
```

**Severity:** High (safety-relevant path)
**Standard:** MISRA C:2012 Rule 1.3 (undefined behavior)
```

### Safety Concern

```
**[SAFETY]** Missing bounds check on array access

`cell_voltages[cell_index]` at line 78 does not validate that
`cell_index < MAX_CELLS`. This is in the ASIL-D rated battery
monitoring path.

**Required:** Add bounds check per ISO 26262-6 Table 1 (1a):
```c
if (cell_index >= MAX_CELLS) {
    trigger_safety_fault(FAULT_ARRAY_BOUNDS);
    return SAFE_STATE_VOLTAGE;
}
```

**Safety Req:** REQ-SAF-042 (bounded array access)
```

### Design Suggestion

```
**[SUGGESTION]** Consider extracting state machine

This function handles 5 different states with nested switch/if.
Consider extracting to a state machine pattern for:
- Clearer state transitions
- Easier testing of individual states
- Better compliance with complexity limits (current: CCN=18, max: 15)

Not blocking, but recommend for a follow-up PR.
```

## Formal Inspection Process (ASIL C/D)

### Inspection Phases

```
1. Planning (Moderator)
   - Schedule inspection meeting
   - Distribute materials 3+ days in advance
   - Assign roles: moderator, author, inspector(s), recorder

2. Individual Preparation (All Inspectors)
   - Review code against checklist
   - Log findings in inspection form
   - Estimate: 150-200 LOC per hour

3. Inspection Meeting (All)
   - Duration: max 2 hours
   - Walk through code systematically
   - Classify findings: Major / Minor / Question
   - Record all findings

4. Rework (Author)
   - Address all major findings
   - Document rationale for deferred items
   - Update code and re-run CI

5. Follow-up (Moderator)
   - Verify all major findings addressed
   - Close inspection record
   - Archive for compliance evidence
```

### Inspection Record Template

```yaml
inspection_id: INS-2024-042
date: 2024-11-15
duration_minutes: 90

artifact:
  name: battery_monitor.c
  version: commit abc1234
  asil: D
  lines_reviewed: 280

participants:
  moderator: jane.doe
  author: john.smith
  inspectors: [alice.wong, bob.chen]
  recorder: jane.doe

findings:
  - id: F001
    severity: major
    category: safety
    line: 45
    description: "Missing watchdog refresh in error handling path"
    resolution: "Added wdg_refresh() call in error handler"
    status: closed

  - id: F002
    severity: minor
    category: style
    line: 112
    description: "Magic number 4096 should be named constant"
    resolution: "Extracted to BUFFER_SIZE_BYTES"
    status: closed

metrics:
  total_findings: 8
  major: 2
  minor: 5
  questions: 1
  defect_density: 2.86  # findings per 100 LOC
  preparation_time_hours: 4.5
```

## GitHub Actions for Review Automation

```yaml
# .github/workflows/review-checks.yml
name: Review Automation

on:
  pull_request:
    types: [opened, synchronize, ready_for_review]

jobs:
  review-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check PR size
        run: |
          ADDITIONS=$(gh pr view ${{ github.event.number }} --json additions -q '.additions')
          if [ "$ADDITIONS" -gt 400 ]; then
            gh pr comment ${{ github.event.number }} --body \
              "This PR has $ADDITIONS additions. Please consider splitting into smaller PRs (target: <400 lines)."
          fi
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Verify safety review assigned
        run: |
          SAFETY_FILES=$(git diff --name-only origin/develop...HEAD | grep -E '^src/safety/' || true)
          if [ -n "$SAFETY_FILES" ]; then
            echo "Safety-critical files changed. Verifying safety reviewer..."
            python3 scripts/check_safety_reviewer.py ${{ github.event.number }}
          fi

      - name: Check test coverage delta
        run: |
          python3 scripts/check_coverage_delta.py \
            --baseline origin/develop \
            --threshold-decrease 2.0
```

## Summary

Effective automotive code review combines structured PR templates, automated
reviewer assignment based on code ownership and ASIL classification,
standardized comment templates for defects and safety concerns, formal
inspection processes for ASIL C/D code, and CI automation that enforces
review requirements before merge.

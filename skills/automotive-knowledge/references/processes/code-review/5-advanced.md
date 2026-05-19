# Code Review for Automotive Software - Level 5: Advanced Topics

> Audience: Engineering leaders and process improvement specialists
> Purpose: Advanced review patterns, metrics analysis, and organizational optimization

## Review Effectiveness Analysis

### Defect Detection Efficiency

```python
"""Analyze code review effectiveness across the organization."""

from dataclasses import dataclass
from typing import Optional
import statistics


@dataclass
class ReviewMetric:
    pr_id: str
    author: str
    reviewer: str
    lines_changed: int
    review_duration_hours: float
    comments_count: int
    defects_found: int
    defect_severity: list[str]
    asil_level: str
    rework_rounds: int


def compute_review_effectiveness(metrics: list[ReviewMetric]) -> dict:
    """Compute review effectiveness metrics."""
    total_defects = sum(m.defects_found for m in metrics)
    total_lines = sum(m.lines_changed for m in metrics)
    total_hours = sum(m.review_duration_hours for m in metrics)

    # Defect density: defects per 1000 lines reviewed
    defect_density = (total_defects / max(total_lines, 1)) * 1000

    # Review efficiency: defects per review hour
    review_efficiency = total_defects / max(total_hours, 0.1)

    # Optimal review rate: lines per hour for best defect detection
    # Research shows 200-400 LOC/hour is optimal
    review_rates = [
        m.lines_changed / max(m.review_duration_hours, 0.1)
        for m in metrics
    ]

    # Cost of review vs cost of escaped defect
    review_cost_hours = total_hours
    escaped_defect_cost = sum(
        1 for m in metrics
        if m.defects_found == 0 and m.lines_changed > 100
    ) * 40  # Estimated 40 hours to fix field defect

    return {
        "defect_density_per_kloc": round(defect_density, 2),
        "review_efficiency_defects_per_hour": round(review_efficiency, 2),
        "median_review_rate_loc_per_hour": round(statistics.median(review_rates), 0),
        "total_review_hours": round(total_hours, 1),
        "estimated_saved_hours": round(escaped_defect_cost, 1),
        "roi_ratio": round(escaped_defect_cost / max(review_cost_hours, 1), 2),
    }
```

### Review Quality Scoring

```python
def score_review_quality(metric: ReviewMetric) -> dict:
    """Score the quality of a code review on multiple dimensions."""
    scores = {}

    # Thoroughness: ratio of comments to lines changed
    comment_density = metric.comments_count / max(metric.lines_changed / 100, 1)
    scores["thoroughness"] = min(comment_density / 5.0, 1.0)  # 5 per 100 LOC = perfect

    # Speed: review completed within SLA
    sla_hours = {"QM": 24, "A": 24, "B": 48, "C": 72, "D": 72}
    target = sla_hours.get(metric.asil_level, 24)
    scores["timeliness"] = max(1.0 - (metric.review_duration_hours / target), 0)

    # Depth: defects found relative to change size
    expected_defect_rate = 0.01  # 1 defect per 100 LOC baseline
    expected = metric.lines_changed * expected_defect_rate
    scores["depth"] = min(metric.defects_found / max(expected, 0.5), 1.0)

    # Efficiency: low rework rounds
    scores["efficiency"] = max(1.0 - (metric.rework_rounds - 1) * 0.25, 0)

    scores["overall"] = sum(scores.values()) / len(scores)
    return scores
```

## Risk-Based Review Prioritization

### Automated Risk Scoring

```python
def compute_pr_risk_score(pr_data: dict) -> float:
    """Compute risk score for a PR to prioritize review effort."""
    score = 0.0

    # File risk factors
    safety_file_count = sum(
        1 for f in pr_data["changed_files"]
        if any(p in f for p in ["safety/", "fault/", "watchdog/"])
    )
    score += safety_file_count * 20

    security_file_count = sum(
        1 for f in pr_data["changed_files"]
        if any(p in f for p in ["crypto/", "auth/", "tls/"])
    )
    score += security_file_count * 15

    # Size risk
    if pr_data["lines_changed"] > 400:
        score += 15
    elif pr_data["lines_changed"] > 200:
        score += 5

    # Author experience
    if pr_data["author_commit_count"] < 50:
        score += 10  # Junior developer
    elif pr_data["author_commit_count"] < 200:
        score += 5   # Mid-level

    # Historical defect rate for this module
    score += pr_data.get("module_defect_rate", 0) * 10

    # Complexity of changes
    score += pr_data.get("max_cyclomatic_complexity", 0)

    return min(score, 100.0)
```

## Cross-Team Review Patterns

### Architecture Decision Review Board

For changes that affect multiple teams or system architecture:

```
1. Author creates Architecture Decision Record (ADR)
2. ADR posted to #architecture channel for async review (3 days)
3. If contested, synchronous review meeting scheduled
4. Board members: 1 per affected team + chief architect
5. Decision recorded with rationale and dissenting opinions
6. Implementation PR references approved ADR
```

### Safety Review Board

For ASIL C/D changes requiring formal inspection:

```
Roles:
  - Moderator: Senior safety engineer (not the author)
  - Author: Presents code, answers questions
  - Inspectors: 2+ safety-qualified engineers
  - Recorder: Documents all findings

Process:
  1. Author distributes code + safety concept (3 days before)
  2. Inspectors prepare independently (1-2 hours)
  3. Meeting: systematic walkthrough (max 2 hours)
  4. Findings classified: Critical / Major / Minor
  5. Author addresses all Critical/Major findings
  6. Moderator verifies resolution
  7. Record archived for ISO 26262 compliance
```

## Scaling Review Processes

### For Large Teams (20+ developers)

| Challenge | Solution |
|-----------|---------|
| Review bottlenecks | Rotating reviewer schedule |
| Knowledge silos | Cross-team review pairing |
| Inconsistent standards | Shared checklist + automated checks |
| Long queue times | PR size limits + priority queue |
| Reviewer fatigue | Max 4 reviews per day per person |

### Review Load Balancing

```python
def assign_reviewer_balanced(
    pr_author: str,
    eligible_reviewers: list[str],
    recent_review_counts: dict[str, int],
    expertise_match: dict[str, float]
) -> str:
    """Assign reviewer balancing load and expertise."""
    candidates = [r for r in eligible_reviewers if r != pr_author]

    scores = {}
    for reviewer in candidates:
        # Lower review count = higher score (load balancing)
        load_score = 1.0 / (recent_review_counts.get(reviewer, 0) + 1)

        # Higher expertise = higher score
        expertise_score = expertise_match.get(reviewer, 0.5)

        scores[reviewer] = load_score * 0.4 + expertise_score * 0.6

    return max(scores, key=scores.get)
```

## Continuous Improvement

### Review Retrospectives

Monthly review of code review metrics:
- Defect escape rate trend (are we catching more?)
- Review turnaround time trend (are we getting faster?)
- Common defect categories (what training is needed?)
- Reviewer satisfaction survey results
- Process improvement proposals

### Training Program

| Level | Training | Frequency |
|-------|---------|-----------|
| New developer | Review guidelines workshop | Onboarding |
| All developers | MISRA awareness training | Quarterly |
| Safety reviewers | ISO 26262 Part 6 review | Annually |
| Security reviewers | OWASP/ISO 21434 review | Annually |
| Moderators | Formal inspection techniques | Annually |

## Future Directions

- **AI-assisted review**: LLM models providing initial review feedback
  on coding standards, common patterns, and potential defects
- **Predictive defect models**: ML models identifying high-risk code
  sections that need extra review attention
- **Automated safety analysis**: Tools verifying safety properties
  (no dynamic allocation, bounded loops) as part of CI
- **Review knowledge graphs**: Capturing review decisions and rationale
  for organizational learning

## Summary

Advanced code review optimizes effectiveness through metrics analysis,
risk-based prioritization, and load-balanced reviewer assignment.
Cross-team review boards handle architecture and safety decisions.
Scaling strategies address large-team challenges. Continuous improvement
through retrospectives and training ensures review quality improves
over time.

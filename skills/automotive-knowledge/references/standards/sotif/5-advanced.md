# ISO 21448 (SOTIF) - Advanced Topics

> **Target Audience**: SOTIF subject matter experts, researchers, safety assessors

## ML/AI-Specific SOTIF Challenges

### The Specification Problem

Traditional software can be verified against a specification. Machine learning models learn behavior from data, creating unique SOTIF challenges:

**Specification Gap**:
```
Traditional SW:     Specification -> Implementation -> Verification
                    (explicit rules   (code)          (test against spec)

ML-Based SW:        Training Data -> Model -> Validation
                    (implicit rules   (learned    (test against what?)
                     in data)          behavior)
```

**Key Challenges**:
- No explicit decision boundary specification exists
- Performance degrades gracefully (no binary pass/fail)
- Behavior changes with retraining (non-deterministic lifecycle)
- Explanation of individual decisions is difficult

### ML-Specific Triggering Conditions

| TC Category | Description | Example |
|-------------|-------------|---------|
| Distribution shift | Input differs from training data | Snow-covered road never in training set |
| Adversarial input | Deliberately crafted misleading input | Sticker on stop sign causes misclassification |
| Domain gap | Sim-to-real or region-to-region transfer | Model trained in Europe, deployed in Asia |
| Long-tail events | Extremely rare but safety-relevant | Wheelchair user in dark clothing at night |
| Concept drift | World changes after training freeze | New vehicle model not in training data |
| Sensor degradation | Gradual performance loss | Lidar calibration drift over vehicle lifetime |

### ML Safety Assurance Framework

```
Phase 1: Data Assurance
  +-- Training data coverage analysis
  |   +-- ODD parameter coverage (geographic, weather, demographics)
  |   +-- Edge case representation (min samples per category)
  |   +-- Bias analysis (demographic, environmental)
  +-- Data quality
  |   +-- Labeling accuracy (>99% for safety-critical classes)
  |   +-- Annotation consistency (inter-annotator agreement >95%)
  +-- Data independence
      +-- Training / validation / test set separation
      +-- Temporal separation (different recording campaigns)

Phase 2: Model Assurance
  +-- Architecture justification
  |   +-- Proven architecture family (peer-reviewed, field-proven)
  |   +-- Complexity appropriate for task
  +-- Training process
  |   +-- Reproducible training pipeline
  |   +-- Hyperparameter sensitivity analysis
  +-- Robustness testing
      +-- Adversarial robustness evaluation
      +-- Out-of-distribution detection capability
      +-- Graceful degradation under domain shift

Phase 3: Integration Assurance
  +-- Runtime monitoring
  |   +-- Confidence thresholding
  |   +-- Input validity checking
  |   +-- Output plausibility checking
  +-- Fallback strategy
  |   +-- Non-ML fallback available (classical algorithm or safe stop)
  |   +-- Degradation path defined
  +-- Sensor fusion
      +-- ML output cross-validated with other sensors
      +-- Disagreement handling strategy defined

Phase 4: Operational Assurance
  +-- Continuous monitoring
  |   +-- Performance KPIs tracked in field
  |   +-- Anomaly detection on logged predictions
  +-- Update management
      +-- Retraining triggers defined
      +-- Re-validation requirements for model updates
      +-- OTA safety assurance process
```

## Continuous Validation and OTA Updates

### The Continuous SOTIF Loop

Traditional validation is a one-time gate before production release. Advanced SOTIF requires continuous validation throughout the product lifecycle.

```
Production Release
    |
    v
Field Operation -----> Data Collection
    ^                       |
    |                       v
    |                  Scenario Mining
    |                  (discover new TCs,
    |                   new edge cases)
    |                       |
    |                       v
    |                  Risk Re-evaluation
    |                  (new Area 4 -> Area 2)
    |                       |
    |                       v
    |                  Update Development
    |                  (algorithm fix,
    |                   model retrain)
    |                       |
    |                       v
    |                  Regression Validation
    |                  (no new hazards
    |                   introduced)
    |                       |
    |                       v
    +---------- OTA Deployment
```

### OTA Update Safety Assurance

**SOTIF Implications of OTA Updates**:

| Update Type | SOTIF Impact | Required Validation |
|-------------|-------------|---------------------|
| Calibration parameter change | Low - behavior within design envelope | Regression on affected scenarios |
| Algorithm logic change | Medium - new behavior possible | Full scenario regression + edge case expansion |
| ML model retrain | High - behavior changes unpredictably | Complete ML assurance cycle |
| New feature activation | Very High - new functionality | Full SOTIF process for new feature |
| ODD expansion | Very High - new operating conditions | Extended validation in new ODD |

**OTA Validation Requirements**:
```
Pre-deployment validation:
  1. Shadow mode testing (new algorithm runs parallel, not controlling)
     - Duration: minimum 100,000 km equivalent
     - Criteria: No degradation vs. current production

  2. A/B testing (limited fleet deployment)
     - Fleet: 1-5% of vehicles
     - Duration: 2-4 weeks
     - Monitoring: Real-time KPI dashboard

  3. Staged rollout
     - Phase 1: Internal fleet (100 vehicles)
     - Phase 2: Early adopter fleet (1,000 vehicles)
     - Phase 3: Full fleet
     - Rollback capability at each phase
```

## Scenario-Based Testing at Scale

### Importance Sampling for Rare Events

Standard Monte Carlo simulation is insufficient for validating rare hazardous events. Importance sampling concentrates testing effort on high-risk scenarios.

**Method**:
```
Standard Monte Carlo:
  P(hazard) estimated from N random samples
  For P(hazard) = 1e-9, need N > 1e10 samples (infeasible)

Importance Sampling:
  1. Define proposal distribution q(x) that oversamples dangerous regions
  2. Run N scenarios sampled from q(x)
  3. Weight results by likelihood ratio: w(x) = p(x) / q(x)
  4. Estimate: P(hazard) = (1/N) * Sum(w(xi) * I(hazard(xi)))

  For well-chosen q(x), need N ~ 1e4 to 1e6 samples

Example:
  Target: Validate AEB false negative rate < 1e-8 per encounter
  Proposal: Oversample dark pedestrians, night, rain, occluded scenarios
  Weight correction: Account for oversampling in final estimate
```

### Falsification-Based Testing

Instead of randomly sampling scenarios, actively search for failure modes:

**Optimization-Based Approach**:
```
Objective: Find scenario parameters that maximize hazard severity

Algorithm:
  1. Define scenario parameter space X
  2. Define fitness function f(x) = measure of hazardous behavior
     (e.g., min TTC, max lateral deviation, collision probability)
  3. Use optimization to find x* = argmax f(x)
     Methods: Genetic algorithms, Bayesian optimization,
              reinforcement learning
  4. If f(x*) > safety threshold, scenario is hazardous -> Area 2
  5. Expand search around x* to characterize boundary

Benefits:
  - Finds worst-case scenarios efficiently
  - Identifies safety boundary in parameter space
  - Provides concrete failure examples for developers
```

### Coverage Metrics for Scenario Space

| Metric | Definition | Target |
|--------|-----------|--------|
| Scenario parameter coverage | % of parameter combinations tested | >95% for critical parameters |
| ODD boundary coverage | % of ODD boundaries with boundary tests | 100% |
| Triggering condition coverage | % of known TCs with test scenarios | 100% |
| Functional insufficiency coverage | % of known FIs with test scenarios | 100% |
| Novelty coverage | % of field scenarios within tested space | >99% (measured retrospectively) |

## Multi-System SOTIF Interactions

### Feature Interaction Hazards

When multiple ADAS/AD functions operate simultaneously, their interactions create SOTIF-relevant hazards not present in individual function analysis.

**Example Interactions**:
```
Interaction 1: AEB + ACC
  Scenario: ACC following vehicle at 1.0s gap, lead vehicle brakes hard
  AEB: Detects imminent collision, activates emergency braking
  ACC: Still commanding gentle braking based on distance control
  Hazard: Conflicting braking commands create jerk or delayed response
  Mitigation: Priority arbitration - AEB overrides ACC

Interaction 2: LKA + ESC
  Scenario: LKA correcting lane departure on wet road
  LKA: Applies steering torque toward lane center
  ESC: Detects yaw rate deviation, applies counter-correction
  Hazard: Oscillating corrections, driver confusion
  Mitigation: Coordinated control with shared vehicle state model

Interaction 3: Parking Assist + AEB Low Speed
  Scenario: Automated parking, target space next to wall
  Parking: Commands approach to wall at low speed
  AEB: Detects wall as obstacle, brakes
  Hazard: System cannot park, or AEB suppressed and collision occurs
  Mitigation: Context-aware AEB suppression with reduced speed limit
```

### System-Level SOTIF Analysis

```
Step 1: Identify all active function combinations
        (n functions -> 2^n combinations, prune infeasible)

Step 2: For each combination, analyze:
  - Command conflicts (actuator arbitration)
  - Information conflicts (different perception interpretations)
  - Mode transitions (one function affects another's state)
  - Shared resource conflicts (sensor bandwidth, CPU)

Step 3: Derive interaction-specific triggering conditions
  - These TCs only manifest when functions are co-active

Step 4: Add interaction scenarios to scenario database
  - Label with involved functions
  - Test both individual and combined behavior
```

## Regulatory Landscape and SOTIF

### Current Regulations Referencing SOTIF

| Regulation | Region | SOTIF Relevance |
|------------|--------|-----------------|
| UN R157 (ALKS) | Global (UNECE) | Mandatory for L3 highway systems, references performance criteria |
| UN R79 (Steering) | Global (UNECE) | ACSF Category B/C requires SOTIF-like validation |
| EU AI Act | European Union | High-risk AI classification applies to AD systems |
| FMVSS (proposed ADS rule) | United States | Expected to reference SOTIF concepts |
| GB/T (AD standards) | China | National standards incorporating SOTIF principles |
| AIS 184/189 | India | ADAS safety requirements with SOTIF alignment |

### UN R157 ALKS Requirements (SOTIF-Relevant)

```
Performance Requirements:
  - System shall not cause any collision in normal operation
  - System shall be able to deal with:
    - Cut-in by other vehicles
    - Decelerating lead vehicle
    - Stationary or slow vehicles in lane
    - Lane markings (including construction zones)

Validation Requirements:
  - Simulation: Defined scenario catalog (thousands of variations)
  - Track testing: Specific test scenarios (ALKS test protocol)
  - Real-world: Audit trail of field testing
  - Manufacturer declaration of ODD

SOTIF Connection:
  - Each R157 scenario maps to SOTIF scenario database
  - Functional insufficiencies must be identified for each scenario
  - Triggering conditions must be analyzed
  - Residual risk must be demonstrated below threshold
```

## SOTIF Safety Case Construction

### Argumentation Structure

```
Top Claim: Residual SOTIF risk is acceptably low for [function] in [ODD]
|
+-- Sub-Claim 1: All reasonably foreseeable hazardous behaviors identified
|   +-- Evidence: Systematic hazard analysis (Clause 6)
|   +-- Evidence: Expert review of triggering conditions
|   +-- Evidence: Comparison with field incident databases
|
+-- Sub-Claim 2: Known hazardous scenarios adequately mitigated
|   +-- Evidence: Mitigation measures implemented and verified
|   +-- Evidence: Scenario-based test results (pass/fail)
|   +-- Evidence: Residual risk calculation per scenario
|
+-- Sub-Claim 3: Unknown hazardous scenarios sufficiently unlikely
|   +-- Evidence: Simulation coverage report (10^8+ scenarios)
|   +-- Evidence: Falsification testing results
|   +-- Evidence: FOT data analysis (no undiscovered hazards in X km)
|   +-- Evidence: Statistical confidence calculation
|
+-- Sub-Claim 4: System robust against reasonably foreseeable misuse
|   +-- Evidence: HMI design review
|   +-- Evidence: Driver monitoring system effectiveness
|   +-- Evidence: Misuse scenario testing
|
+-- Sub-Claim 5: Operational monitoring will detect emerging risks
    +-- Evidence: Field monitoring plan
    +-- Evidence: Incident analysis process
    +-- Evidence: Update and re-validation capability
```

### Safety Case Maturity Levels

| Level | Description | Evidence Required |
|-------|-------------|-------------------|
| Initial | Concept-level hazard identification complete | Hazard analysis document, preliminary TC list |
| Developing | Mitigations designed, simulation started | Mitigation specs, simulation plan, initial results |
| Defined | Verification complete, validation underway | Test reports, coverage metrics, FOT data collection |
| Managed | Validation data supports acceptance criteria | Statistical analysis, residual risk calculation |
| Optimizing | Field data confirms safety, continuous improvement | Field monitoring reports, update history |

## Research Frontiers in SOTIF

### Open Problems

| Problem | Current State | Research Direction |
|---------|--------------|-------------------|
| Completeness of scenario space | No method guarantees all scenarios found | Formal ODD coverage proofs, generative AI |
| Statistical validation cost | Billions of km needed | Better importance sampling, transfer learning |
| ML explainability for safety | Post-hoc explanations insufficient | Inherently interpretable architectures |
| Multi-agent interaction | Difficult to model all road user behaviors | Game-theoretic planning, social force models |
| Sim-to-real gap | Simulation results may not transfer | Domain randomization, reality-gap metrics |
| Continuous assurance | No established process for live updates | Runtime verification, safety envelopes |

### Emerging Standards and Guidelines

| Document | Status | Relevance |
|----------|--------|-----------|
| ISO/TR 4804 | Published 2020 | Safety and cybersecurity for AD design |
| ISO/AWI 8800 | Under development | Safety of AI in road vehicles |
| UL 4600 | Published 2020 | Safety evaluation of autonomous products |
| ANSI/UL 4600 Ed. 2 | Under development | Updated autonomous safety evaluation |
| ISO/CD 34502 | Under development | Test scenarios for AD |
| ISO/CD 34503 | Under development | ODD taxonomy |

## Next Steps

For practical application of advanced SOTIF:
- Implement ML safety assurance framework in your development process
- Establish continuous validation pipeline with field data feedback
- Build importance sampling infrastructure for simulation-based validation
- Develop SOTIF safety case using the argumentation structure above
- Monitor regulatory developments and align validation with upcoming requirements

## References

- ISO 21448:2022 (complete standard, all clauses)
- ISO/PAS 21448:2019 (predecessor, for historical context)
- UN R157 (ALKS regulation)
- UL 4600 (Safety evaluation of autonomous products)
- ISO/TR 4804:2020 (Safety and cybersecurity for AD)
- NHTSA AV Policy (US regulatory framework)
- Koopman & Wagner, "Challenges in Autonomous Vehicle Testing and Validation" (SAE 2016)
- Zhao et al., "Accelerated Evaluation of Automated Vehicles Safety" (IEEE 2017)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: SOTIF subject matter experts, safety assessors, researchers

---
name: automotive-dfm-benchmarking
description: >
  Automotive Dfm Benchmarking expertise. Covers 1 topics: Dfm Benchmarking.
tags: [automotive, automotive-dfm-benchmarking]
---

# Automotive Dfm Benchmarking

## Dfm Benchmarking

# DFM Benchmarking — Driver Foundation Model Framework for AD Evaluation

## Overview

Benchmarking framework based on the Driver Foundation Model (DFM) concept for evaluating autonomous driving systems. DFM uses large-scale naturalistic driving data (NDD) to model human driver behavior distributions, providing a human-performance baseline for AD system evaluation. This skill supports scenario generation, performance benchmarking, and safety argument construction using NDD-derived metrics.

## DFM Concept

```
驾驶员基础模型 (Driver Foundation Model) 概念
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Core Idea:
  Human drivers provide a safety baseline:
  - Average driver: ~1 fatality per 10^8 km (developed countries)
  - Good driver: ~10x safer than average
  - AD must be at least as safe as good human driver

DFM Approach:
  1. Collect large-scale NDD (7.5M+ aerial trajectories)
  2. Model human driving behavior distributions
  3. Extract scenario-specific performance baselines
  4. Benchmark AD systems against human baselines
  5. Quantify relative safety improvement

DFM as Foundation Model:
  ├── Pre-trained on massive NDD
  ├── Captures diverse driving styles and conditions
  ├── Fine-tunable for specific scenarios/regions
  ├── Provides probabilistic behavior predictions
  └── Serves as benchmark generator and evaluator
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Data Foundation

### NDD Collection & Processing

```python
# NDD Processing Pipeline for DFM
class NDDProcessor:
    """
    Process Naturalistic Driving Data for DFM benchmarking.
    Supports aerial trajectory data (drone-based) and fleet data.
    """

    def __init__(self, data_source: str):
        """
        data_source options:
        - "aerial": Drone-based trajectory extraction (7.5M+ trajectories)
        - "fleet": Vehicle-mounted sensor data
        - "hybrid": Combined aerial + fleet data
        """
        self.source = data_source

    def extract_driving_primitives(self, trajectories):
        """
        Extract fundamental driving behaviors from trajectory data.

        Driving primitives:
        - Car-following (跟车)
        - Lane-changing (换道)
        - Merging (汇入)
        - Diverging (分流)
        - Crossing (交叉)
        - Free-driving (自由行驶)
        """
        primitives = {
            "car_following": self.extract_car_following(trajectories),
            "lane_change": self.extract_lane_changes(trajectories),
            "merge": self.extract_merges(trajectories),
            "diverge": self.extract_diverges(trajectories),
            "crossing": self.extract_crossings(trajectories),
            "free_driving": self.extract_free_driving(trajectories),
        }
        return primitives

    def build_behavior_distributions(self, primitives):
        """
        Build statistical distributions of driving behaviors.

        For car-following:
        - Time headway distribution: P(THW)
        - TTC distribution: P(TTC)
        - Speed distribution: P(v | context)
        - Acceleration distribution: P(a | context)
        - Lane offset distribution: P(offset | context)
        """
        distributions = {}
        for primitive_type, data in primitives.items():
            distributions[primitive_type] = {
                "thw": fit_distribution(data.thw_values),
                "ttc": fit_distribution(data.ttc_values),
                "speed": conditional_distribution(data.speeds, data.contexts),
                "acceleration": conditional_distribution(data.accels, data.contexts),
                "lateral_offset": fit_distribution(data.offsets),
                "jerk": fit_distribution(data.jerks),
            }
        return distributions

    def generate_benchmark_scenarios(self, distributions, n_scenarios=1000):
        """
        Generate benchmark scenarios by sampling from behavior distributions.

        Importance sampling: over-sample from tail (critical) regions
        """
        scenarios = []
        for i in range(n_scenarios):
            # Sample scenario type based on exposure
            scenario_type = sample_weighted(distributions.keys(),
                                           weights=exposure_weights)
            # Sample parameters from distribution
            params = sample_from_distribution(
                distributions[scenario_type],
                sampling="importance",  # over-sample tails
                criticality_weight=2.0
            )
            scenarios.append(BenchmarkScenario(
                type=scenario_type,
                parameters=params,
                human_baseline=distributions[scenario_type],
            ))
        return scenarios
```

## Benchmarking Methodology

### Performance Metrics

```
DFM基准评测指标体系
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Safety Metrics (安全性指标):
├── Collision rate vs. human baseline
├── Near-miss rate (TTC < 1.5s events)
├── Safety-critical event rate
├── Minimum TTC distribution comparison
└── Emergency braking frequency

Comfort Metrics (舒适性指标):
├── Acceleration distribution vs. human
├── Jerk distribution vs. human
├── Lateral offset smoothness
├── Speed profile consistency
└── Ride quality index

Efficiency Metrics (效率指标):
├── Travel time vs. human baseline
├── Throughput at bottlenecks
├── Speed utilization (actual/limit ratio)
└── Lane utilization efficiency

Human-Likeness Metrics (类人性指标):
├── Trajectory similarity (Fréchet distance)
├── Decision timing similarity
├── Speed profile similarity (DTW distance)
├── Gap acceptance distribution similarity
└── Lane change timing similarity

Overall DFM Score:
  DFM_score = w_s × Safety + w_c × Comfort + w_e × Efficiency + w_h × HumanLikeness
  where: w_s > w_c > w_e > w_h (safety weighted highest)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Benchmark Protocol

```python
# DFM Benchmarking Protocol
class DFMBenchmark:
    """
    Benchmark AD system against human driver baseline using DFM.
    """

    def __init__(self, dfm_model, ad_system):
        self.dfm = dfm_model      # Trained DFM with human baselines
        self.ad = ad_system        # AD system under test

    def run_benchmark(self, scenario_suite):
        """
        Run complete benchmark suite.

        Returns:
        - Per-scenario comparison (AD vs. human)
        - Aggregate safety/comfort/efficiency scores
        - Failure mode analysis
        - Improvement recommendations
        """
        results = []
        for scenario in scenario_suite:
            # Get human baseline for this scenario
            human_baseline = self.dfm.predict_behavior(scenario)

            # Run AD system in same scenario
            ad_behavior = self.ad.simulate(scenario)

            # Compare
            comparison = self.compare_behaviors(
                human=human_baseline,
                ad=ad_behavior,
                scenario=scenario
            )
            results.append(comparison)

        return self.aggregate_results(results)

    def compare_behaviors(self, human, ad, scenario):
        """Compare AD behavior with human baseline"""
        return {
            "scenario_id": scenario.id,
            "safety": {
                "ad_min_ttc": ad.min_ttc,
                "human_min_ttc_percentile": human.ttc_percentile(ad.min_ttc),
                "collision": ad.collision_occurred,
                "safety_score": self.compute_safety_score(ad, human),
            },
            "comfort": {
                "ad_max_accel": ad.max_acceleration,
                "human_accel_percentile": human.accel_percentile(ad.max_acceleration),
                "ad_max_jerk": ad.max_jerk,
                "comfort_score": self.compute_comfort_score(ad, human),
            },
            "human_likeness": {
                "trajectory_distance": frechet_distance(ad.trajectory, human.mean_trajectory),
                "speed_profile_dtw": dtw_distance(ad.speed_profile, human.mean_speed),
                "decision_timing_diff": abs(ad.decision_time - human.mean_decision_time),
            },
        }

    def generate_report(self, results):
        """Generate benchmark report with visualizations"""
        report = {
            "overall_dfm_score": self.compute_overall_score(results),
            "safety_rating": self.rate_safety(results),
            "scenarios_worse_than_human": self.find_deficiencies(results),
            "scenarios_better_than_human": self.find_strengths(results),
            "improvement_priorities": self.prioritize_improvements(results),
        }
        return report
```

## Application Scenarios

### 1. AD System Version Comparison

```
版本对比评测
├── Input: AD System v1.0, v2.0
├── Benchmark: Same DFM scenario suite
├── Output:
│   ├── Per-scenario performance delta
│   ├── Regression identification (v2 worse than v1)
│   ├── Improvement quantification
│   └── Overall DFM score trend
└── Use case: Release gate decision
```

### 2. Cross-Platform Benchmarking

```
跨平台评测
├── Input: Multiple AD systems (OEM A vs. B vs. C)
├── Benchmark: Standardized DFM scenario suite
├── Output:
│   ├── Comparative safety ranking
│   ├── Comfort comparison
│   ├── Scenario-specific strengths/weaknesses
│   └── Industry positioning
└── Use case: C-NCAP, IIHS, consumer testing
```

### 3. SOTIF Evidence Generation

```
SOTIF证据生成
├── Input: AD system + DFM human baselines
├── Analysis: Per-scenario risk comparison
├── Output:
│   ├── Scenarios where AD safer than human → evidence
│   ├── Scenarios where AD less safe → risk
│   ├── Statistical safety argument
│   └── Residual risk quantification
└── Use case: ISO 21448 compliance, type approval
```

## Deliverables

1. **DFM Benchmark Report**: Complete AD vs. human baseline comparison
2. **Scenario Suite**: NDD-derived benchmark scenarios with human baselines
3. **Safety Argument**: Statistical evidence using DFM-based risk quantification
4. **Version Comparison**: Regression analysis between AD system versions
5. **Improvement Roadmap**: Data-driven prioritization of system improvements

## References

- Zhang et al., "Benchmarking Autonomous Vehicles: A Driver Foundation Model Framework" (CARS 2026)
- DRIVEResearch dataset: https://www.driveresearch.tech/

## Related Skills

- `automotive-scenario-driven-testing` — Scenario-based V&V methodology
- `automotive-sotif-hazard-scenario` — SOTIF scenario construction
- `automotive-e2e-safety-analysis` — E2E AD safety analysis
- `automotive-china-l3-ads-compliance` — L3 validation requirements

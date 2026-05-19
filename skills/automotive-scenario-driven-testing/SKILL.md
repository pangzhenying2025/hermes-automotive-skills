---
name: automotive-scenario-driven-testing
description: >
  Automotive Scenario Driven Testing expertise. Covers 1 topics: Scenario Driven Testing.
tags: [automotive, automotive-scenario-driven-testing]
---

# Automotive Scenario Driven Testing

## Scenario Driven Testing

# Scenario-Driven Testing & Evaluation — Methodology for ADAS/ADS V&V

## Overview

Comprehensive methodology for scenario-driven testing and evaluation of ADAS/ADS systems. Integrates naturalistic driving data analysis, scenario extraction, simulation-track-road combined testing, and statistical evidence generation. This approach bridges the gap between traditional mileage-based testing and systematic scenario-based validation.

## The Scenario-Driven V&V Paradigm

```
场景驱动测试评价范式
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Traditional Approach (传统方法):
  Drive millions of km → Count incidents → Statistically argue safety
  Problem: 10^8 km needed for L3, impractical

Scenario-Driven Approach (场景驱动方法):
  1. Extract scenarios from NDD/accidents/standards
  2. Parameterize and generate variations
  3. Test systematically across parameter space
  4. Quantify risk per scenario type
  5. Aggregate to overall safety argument

  Advantage: 10^3 scenarios × 10^3 variations = comprehensive coverage
             with 10^4 - 10^5 km equivalent testing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Scenario Sources & Extraction

### Source 1: Naturalistic Driving Data (NDD)

```python
# NDD-based scenario extraction pipeline
class NaturalisticDrivingScenarioExtractor:
    """
    Extract test scenarios from naturalistic driving data.
    Based on DRIVEResearch methodology with 7.5M+ aerial trajectories.
    """

    def __init__(self, dataset_path: str):
        self.dataset = load_trajectory_dataset(dataset_path)

    def extract_critical_events(self,
                                 ttc_threshold: float = 3.0,
                                 thw_threshold: float = 1.5,
                                 decel_threshold: float = -4.0):
        """
        Extract safety-critical events from trajectory data.

        Criticality indicators:
        - TTC (Time-to-Collision) < threshold
        - THW (Time Headway) < threshold
        - Hard braking (deceleration < threshold)
        - Near-miss events
        """
        critical_events = []
        for trajectory in self.dataset:
            for timestep in trajectory:
                if (timestep.ttc < ttc_threshold or
                    timestep.thw < thw_threshold or
                    timestep.acceleration < decel_threshold):
                    critical_events.append(
                        self.extract_scenario_context(trajectory, timestep)
                    )
        return critical_events

    def cluster_scenarios(self, events, method="spectral"):
        """
        Cluster similar events into scenario types.
        Methods: k-means, DBSCAN, spectral, GMM
        """
        features = self.extract_features(events)
        clusters = cluster_algorithm(features, method)
        return self.create_scenario_templates(clusters)

    def parameterize_scenario(self, template):
        """
        Create parameterized scenario from template.
        Output: OpenSCENARIO 2.0 compatible definition
        """
        return {
            "scenario_type": template.type,
            "parameters": {
                "ego_speed": Distribution(template.ego_speed_stats),
                "target_speed": Distribution(template.target_speed_stats),
                "relative_distance": Distribution(template.distance_stats),
                "lateral_offset": Distribution(template.offset_stats),
            },
            "criticality_distribution": template.criticality_dist,
            "exposure_frequency": template.occurrence_rate,
        }
```

### Source 2: Accident Data Analysis

```
事故数据场景提取
├── 数据来源
│   ├── 中国道路交通事故深入研究（CIDAS）
│   ├── 国家事故深度调查体系（NAIS）
│   ├── 交通事故统计年报
│   └── 特定企业事故/Near-miss数据
├── 提取方法
│   ├── 事故重建（PC-Crash, MADYMO）
│   ├── 事故类型编码（GIDAS/CIDAS分类）
│   ├── 因果链分析（Driving Reliability and Error Analysis Method）
│   └── 场景参数统计分析
└── 输出
    ├── 高频事故场景类型
    ├── 参数化场景描述
    ├── 暴露频率估算
    └── 严重度分布
```

### Source 3: Standards & Regulations

```
标准法规场景来源
├── ISO 34502 — Test scenarios for ADS
├── Euro NCAP — AEB/LSS/Speed Assist scenarios
├── C-NCAP — AEB/LKA/ACC test protocols
├── ALKS R157 — Cut-in/cut-out/deceleration scenarios
├── China GB — L2/L3 mandatory test scenarios
├── ASAM OpenSCENARIO — Standard scenario formats
└── PEGASUS/VVM — German scenario-based V&V projects
```

## Combined Testing Strategy: Sim-Track-Road

```
仿真-场地-道路联合测试策略
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Simulation (仿真测试) — Breadth
  ├── Purpose: Maximum scenario coverage
  ├── Scale: >10,000 scenario variations
  ├── Tools: CARLA, VTD, 51Sim, PanoSim
  ├── Focus: Parameter space exploration, corner cases
  ├── Output: Pass/fail per scenario, coverage metrics
  └── Gate: >99% pass rate on known scenarios

Phase 2: Track Testing (场地测试) — Depth
  ├── Purpose: Physical validation of critical scenarios
  ├── Scale: >100 scenario configurations
  ├── Facility: National ICV test site
  ├── Focus: Real sensor performance, system timing
  ├── Output: Quantitative KPIs, sensor performance data
  └── Gate: 100% pass on safety-critical scenarios

Phase 3: Public Road (道路测试) — Exposure
  ├── Purpose: Real-world validation + unknown scenario discovery
  ├── Scale: >100,000 km
  ├── Routes: Representative highways + urban expressways
  ├── Focus: Long-tail events, driver interaction
  ├── Output: Disengagement rate, near-miss analysis
  └── Gate: <0.1 disengagement per 1000 km (capability-related)

Phase 4: Fleet Data (运营数据) — Continuous
  ├── Purpose: Post-market surveillance
  ├── Scale: Fleet-level data collection
  ├── Focus: Unknown-unknown scenario discovery
  ├── Output: Emerging risk identification, OTA trigger
  └── Gate: Continuous monitoring KPIs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Statistical Safety Argument

### Evidence Framework

```python
# Statistical evidence for safety claim
import scipy.stats as stats

def calculate_required_test_km(
    target_failure_rate: float,  # failures per km
    confidence_level: float,    # e.g., 0.95
    observed_failures: int = 0  # number of failures observed
) -> float:
    """
    Calculate required test kilometers for safety demonstration.
    Based on binomial test / Poisson approximation.

    Example:
    - Target: <1 fatality per 10^8 km (human benchmark)
    - Confidence: 95%
    - No failures observed
    - Required: ~3 × 10^8 km (impractical for real driving)

    Scenario-based approach reduces this by:
    - Focusing on critical scenarios (higher exposure)
    - Using importance sampling
    - Combining sim + track + road evidence
    """
    if observed_failures == 0:
        # Upper confidence bound with zero failures
        required_km = -np.log(1 - confidence_level) / target_failure_rate
    else:
        # Chi-squared approximation
        chi2_val = stats.chi2.ppf(confidence_level, 2 * (observed_failures + 1))
        required_km = chi2_val / (2 * target_failure_rate)

    return required_km

def scenario_based_evidence(
    scenario_test_results: dict,
    scenario_exposure_rates: dict,
    target_overall_risk: float
) -> dict:
    """
    Aggregate scenario-level evidence to overall safety claim.

    Overall_risk = Σ (scenario_failure_rate × scenario_exposure_rate)

    If Overall_risk < target_overall_risk → safety claim supported
    """
    total_risk = 0
    scenario_risks = {}

    for scenario_id, results in scenario_test_results.items():
        failure_rate = results["failures"] / results["total_tests"]
        exposure = scenario_exposure_rates[scenario_id]
        risk = failure_rate * exposure
        scenario_risks[scenario_id] = risk
        total_risk += risk

    return {
        "total_risk": total_risk,
        "target": target_overall_risk,
        "safety_claim_supported": total_risk < target_overall_risk,
        "scenario_contributions": scenario_risks,
        "dominant_scenarios": sorted(
            scenario_risks.items(), key=lambda x: x[1], reverse=True
        )[:10],
    }
```

## Deliverables

1. **Scenario Library**: Parameterized scenario database (OpenSCENARIO compatible)
2. **Test Plan**: Combined sim-track-road test plan with coverage targets
3. **Test Report**: Results with statistical analysis and coverage metrics
4. **Safety Argument**: Evidence-based safety claim with confidence levels
5. **Gap Analysis**: Uncovered scenario space and recommended additional testing

## Related Skills

- `automotive-sotif-hazard-scenario` — SOTIF scenario construction
- `automotive-sotif-highway-testing` — Highway-specific testing
- `automotive-sotif-audit` — SOTIF process audit
- `automotive-dfm-benchmarking` — DFM-based scenario benchmarking

---
name: automotive-sotif-hazard-scenario
description: >
  Automotive Sotif Hazard Scenario expertise. Covers 1 topics: Sotif Hazard Scenario.
tags: [automotive, automotive-sotif-hazard-scenario]
---

# Automotive Sotif Hazard Scenario

## Sotif Hazard Scenario

# SOTIF Hazard Scenario Construction — Systematic Identification and Analysis

## Overview

Deep methodology for SOTIF (Safety Of The Intended Functionality, ISO 21448) hazard scenario identification, construction, and analysis. This skill goes beyond basic SOTIF overview to provide actionable frameworks for identifying triggering conditions, constructing hazardous scenarios, and systematically reducing the unknown unsafe area.

## The Four-Quadrant Framework (Deep Dive)

```
ISO 21448 Four-Quadrant Model
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              Known                Unknown
         ┌─────────────────┬─────────────────┐
         │   Area 1        │   Area 3        │
  Safe   │   Known Safe    │   Unknown Safe  │
         │   已知安全        │   未知安全       │
         │                 │                 │
         │ ✓ Normal ops    │ ? Safe but      │
         │ ✓ Validated     │   undiscovered  │
         ├─────────────────┼─────────────────┤
         │   Area 2        │   Area 4        │
 Unsafe  │   Known Unsafe  │   Unknown       │
         │   已知不安全      │   Unsafe        │
         │                 │   未知不安全      │
         │ ⚠ Identified    │ ✗ Greatest risk │
         │ ⚠ Mitigated     │ ✗ Must minimize │
         └─────────────────┴─────────────────┘
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SOTIF Goal: Minimize Area 4 (unknown unsafe)
            by moving scenarios to Area 2 (known unsafe → mitigated)
            or Area 1 (known safe → validated)
```

## Triggering Condition Taxonomy

### Systematic Identification Method

```python
# Triggering Condition Identification Framework
triggering_conditions = {
    "sensing_limitations": {
        "camera": {
            "illumination": [
                "Direct sunlight / sun glare (太阳眩光)",
                "Low sun angle (5°-15° elevation)",
                "Tunnel entry/exit (dark-bright transition)",
                "Night without street lights",
                "LED traffic light flicker (PWM)",
                "Headlight reflection on wet road",
            ],
            "weather": [
                "Heavy rain (>25mm/h)",
                "Fog (visibility <200m)",
                "Snow (lens covered / white-out)",
                "Haze/smog (PM2.5 >200 in China)",
                "Sandstorm (Northern China specific)",
            ],
            "occlusion": [
                "Lens contamination (mud, insects, water drops)",
                "Partial blockage by adjacent objects",
                "Wiper interference during rain",
                "Ice/frost on lens",
            ],
            "perception_failures": [
                "White vehicle against white sky",
                "Black vehicle in shadow",
                "Motorcycle/bicycle thin profile",
                "Unusual vehicle shapes (overloaded truck)",
                "Road debris vs. road texture confusion",
                "Lane marking worn/faded/absent",
                "Temporary vs. permanent lane markings",
            ],
        },
        "radar": {
            "interference": [
                "Multi-path reflection (guardrails, tunnels)",
                "Adjacent vehicle radar interference",
                "Metallic bridge overhead reflection",
                "Rain clutter (heavy precipitation)",
            ],
            "missed_detection": [
                "Stationary objects (bridge pillars, barriers)",
                "Low-RCS targets (motorcycle, pedestrian)",
                "Crossing targets at extreme angles",
                "Speed-ambiguity (relative speed near zero)",
            ],
            "false_detection": [
                "Manhole covers (strong radar return)",
                "Metal debris on road",
                "Overhead signs/structures (elevated targets)",
                "Guardrail reflections as ghost targets",
            ],
        },
        "lidar": {
            "limitations": [
                "Black/dark surfaces (low reflectivity)",
                "Transparent objects (glass barriers)",
                "Rain/fog scattering",
                "Direct sunlight saturation",
                "Dust/dirt on sensor window",
            ],
        },
        "gnss_localization": {
            "degradation": [
                "Urban canyon (tall buildings)",
                "Tunnel (no GNSS signal)",
                "Dense tree canopy",
                "Multi-path interference (bridges)",
                "Jamming/spoofing",
            ],
        },
    },
    "algorithm_limitations": {
        "perception": [
            "Out-of-distribution objects (rare objects)",
            "Adversarial patterns (adversarial patches)",
            "Domain shift (training vs. deployment environment)",
            "Class confusion (truck rear vs. wall)",
            "Tracking ID switch (occluded targets)",
        ],
        "prediction": [
            "Unpredictable human behavior (jaywalker)",
            "Unusual vehicle maneuvers (illegal U-turn)",
            "Group behavior (crowd crossing)",
            "Intention ambiguity (vehicle drifting in lane)",
        ],
        "planning": [
            "Conflicting objectives (comfort vs. safety)",
            "Rare road geometry (unusual intersection)",
            "Construction zone navigation",
            "Emergency vehicle response",
        ],
    },
    "human_factors": {
        "misuse": [
            "Overreliance on automation (complacency)",
            "Distracted driving during L2",
            "Intentional abuse (hands-off driving)",
            "Misunderstanding of ODD boundaries",
        ],
        "takeover_failures": [
            "Slow response after long automation use",
            "Mode confusion (manual vs. automated)",
            "Incorrect takeover action (wrong pedal)",
            "Physical impairment (drowsy, intoxicated)",
        ],
    },
    "infrastructure": [
        "Missing/contradictory road signs",
        "Temporary construction zone",
        "Road surface irregularities (potholes)",
        "Non-standard intersection layout",
        "Toll station / service area transitions",
    ],
}
```

### Triggering Condition → Hazard → Scenario Mapping

```
Triggering Condition → Functional Insufficiency → Hazardous Behavior → Scenario
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Example Chain 1:
  TC: Sun glare at low angle (5° elevation)
  → FI: Camera saturation, lane marking invisible
  → HB: LCC fails to detect lane → vehicle drifts out of lane
  → Scenario: Highway driving at 100km/h, sun glare from front-left,
              vehicle drifts into adjacent lane occupied by truck

Example Chain 2:
  TC: Preceding vehicle cut-out reveals stationary vehicle
  → FI: Radar filters stationary objects, camera detection delayed
  → HB: ACC does not brake for stationary vehicle ahead
  → Scenario: Highway at 120km/h, lead vehicle changes lane,
              exposing stopped vehicle 80m ahead, TTC < 2.4s

Example Chain 3:
  TC: E-bike enters from blind spot (China-specific)
  → FI: Thin profile below detection threshold
  → HB: No braking or avoidance initiated
  → Scenario: Urban expressway at 60km/h, e-bike merges from
              non-motorized lane without signal, lateral distance < 0.5m
```

## Scenario Construction Methodology

### 6-Layer Scenario Model

```
场景六层模型 (ISO 34502 / OpenSCENARIO aligned)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Layer 1: Road Network (道路网络)
  ├── Road type, geometry, topology
  ├── Lane configuration, marking types
  ├── Junctions, ramps, merge areas
  └── Surface condition, slope, curvature

Layer 2: Traffic Infrastructure (交通设施)
  ├── Traffic signs, signals
  ├── Road markings, barriers
  ├── Construction zones
  └── Toll stations, service areas

Layer 3: Temporary Modifications (临时变更)
  ├── Construction work zones
  ├── Accident scenes
  ├── Temporary speed limits
  └── Detour routes

Layer 4: Dynamic Objects (动态对象)
  ├── Vehicles (cars, trucks, motorcycles, e-bikes)
  ├── Pedestrians (adults, children, wheelchair users)
  ├── Animals
  └── Object behaviors (trajectories, intentions)

Layer 5: Environment (环境条件)
  ├── Weather (rain, fog, snow, sandstorm)
  ├── Illumination (day, night, dawn/dusk, tunnel)
  ├── Visibility range
  └── Road surface (dry, wet, icy, flooded)

Layer 6: Digital Information (数字信息)
  ├── HD map accuracy/freshness
  ├── V2X communication status
  ├── GNSS signal quality
  └── Cloud connectivity
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Scenario Parameterization

```python
# Scenario Parameter Space Definition
from dataclasses import dataclass
from typing import List, Tuple

@dataclass
class SOTIFScenario:
    """SOTIF hazard scenario definition"""
    id: str
    name: str
    description: str

    # Layer 1: Road
    road_type: str              # highway, urban_expressway, urban
    lane_count: int
    curvature_radius: float     # meters, 0 for straight
    slope: float                # percent

    # Layer 4: Dynamic objects
    ego_speed: float            # km/h
    target_type: str            # car, truck, motorcycle, e-bike, pedestrian
    target_speed: float         # km/h
    target_behavior: str        # cut_in, cut_out, stationary, crossing
    relative_position: str      # ahead, adjacent, crossing
    initial_distance: float     # meters

    # Layer 5: Environment
    weather: str                # clear, rain, fog, snow, haze
    illumination: str           # day, night, dawn, dusk, tunnel
    visibility: float           # meters

    # SOTIF-specific
    triggering_condition: str
    functional_insufficiency: str
    hazardous_behavior: str
    severity: str               # S0-S3
    exposure: str               # E0-E4
    controllability: str        # C0-C3

    # Validation
    test_method: str            # simulation, track, public_road
    pass_criteria: str

# Example scenario instantiation
scenario_acc_stationary = SOTIFScenario(
    id="SOTIF-HW-001",
    name="ACC前方静止车辆未制动",
    description="Lead vehicle cut-out exposing stationary vehicle on highway",
    road_type="highway",
    lane_count=3,
    curvature_radius=0,      # straight road
    slope=0,
    ego_speed=120,
    target_type="car",
    target_speed=0,           # stationary
    target_behavior="stationary",
    relative_position="ahead",
    initial_distance=80,
    weather="clear",
    illumination="day",
    visibility=1000,
    triggering_condition="Lead vehicle cut-out revealing stationary target",
    functional_insufficiency="Radar filters stationary clutter; camera late detection",
    hazardous_behavior="No deceleration or late deceleration",
    severity="S3",
    exposure="E3",
    controllability="C2",
    test_method="simulation + track",
    pass_criteria="System brakes or warns driver with TTC > 2.0s",
)
```

## Scenario Coverage Analysis

### Coverage Metric Framework

```
场景覆盖度评估框架
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dimension 1: Functional coverage
  └── % of system functions with identified scenarios

Dimension 2: Triggering condition coverage
  └── % of known triggering conditions with test scenarios

Dimension 3: Parameter space coverage
  └── Coverage of parameter combinations (corner cases)

Dimension 4: Scenario type coverage
  └── Normal / edge case / corner case / abuse case

Dimension 5: ODD boundary coverage
  └── All ODD boundaries tested (entry, exit, edge)

Coverage Metric:
  C_total = w1*C_func + w2*C_trigger + w3*C_param + w4*C_type + w5*C_odd
  Target: C_total > 95% for known unsafe area
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Deliverables

When invoked, this skill provides:
1. **Triggering Condition Catalog**: Systematic list per sensor/algorithm/human
2. **Hazard Scenario Database**: Parameterized scenario definitions
3. **Scenario Chain Analysis**: TC → FI → HB → Scenario mapping
4. **Coverage Analysis**: Scenario coverage assessment
5. **Mitigation Recommendations**: Per-scenario risk reduction strategies
6. **Test Plan**: Simulation + track + public road test design

## Related Skills

- `automotive-sotif-audit` — SOTIF process audit and maturity assessment
- `automotive-sotif-highway-testing` — Highway-specific SOTIF testing
- `automotive-scenario-driven-testing` — Scenario-based V&V methodology
- `automotive-china-l2-adas-compliance` — China L2 SOTIF requirements

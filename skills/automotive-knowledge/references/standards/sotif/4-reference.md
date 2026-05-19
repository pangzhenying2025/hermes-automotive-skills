# ISO 21448 (SOTIF) - Quick Reference

> **Target Audience**: All project team members (quick lookup)

## SOTIF Clause Structure

| Clause | Title | Purpose |
|--------|-------|---------|
| 1 | Scope | Applicability to ADAS/AD systems |
| 2 | Normative references | Referenced standards |
| 3 | Terms and definitions | SOTIF-specific vocabulary |
| 4 | General | Overview of SOTIF approach |
| 5 | Specification and design | Intended functionality and known limitations |
| 6 | Identification of hazardous behavior | Hazard analysis for SOTIF |
| 7 | Triggering conditions and functional insufficiencies | Systematic analysis |
| 8 | Risk evaluation | Assess residual risk |
| 9 | Verification | Confirm mitigations work |
| 10 | Validation | Demonstrate acceptable residual risk |
| 11 | Operational phase | Field monitoring and updates |

## Scenario Quadrant Quick Reference

```
         Known                    Unknown
    +------------------+------------------+
    |  Area 1: SAFE    |  Area 3: SAFE    |
    |  Keep here       |  Validate to     |
    |  (validated)     |  move to Area 1  |
    +------------------+------------------+
    |  Area 2: UNSAFE  |  Area 4: UNSAFE  |
    |  Mitigate to     |  Discover via    |
    |  move to Area 1  |  testing/analysis|
    +------------------+------------------+

GOAL: Minimize Area 3 + Area 4
```

## Triggering Condition Checklist by Sensor

### Camera

| Category | Triggering Condition | Severity Potential |
|----------|---------------------|-------------------|
| Glare | Direct sunlight in FoV | High |
| Glare | Reflection from wet road | Medium |
| Glare | Oncoming headlights at night | Medium |
| Contrast | Fog (visibility < 200m) | High |
| Contrast | Snow-covered road (white-on-white) | High |
| Contrast | Night without illumination | High |
| Contrast | Worn/faded lane markings | Medium |
| Occlusion | Rain drops on lens | Medium |
| Occlusion | Dirt/mud/insect residue | Medium |
| Occlusion | Ice on lens/windshield | High |
| Confusion | Construction zone markings | High |
| Confusion | Shadows resembling lane markings | Medium |
| Confusion | Road patches/repairs | Low |

### Radar

| Category | Triggering Condition | Severity Potential |
|----------|---------------------|-------------------|
| False target | Metal bridge/overpass | High |
| False target | Guardrail on curve | Medium |
| False target | Manhole cover / road plate | Medium |
| Missed target | Pedestrian (small RCS) | High |
| Missed target | Stationary object (clutter filter) | High |
| Missed target | Object at sensor FoV edge | Medium |
| Multi-path | Tunnel wall reflections | Medium |
| Multi-path | Adjacent large vehicle | Medium |
| Interference | Adjacent vehicle radar | Low |

### Lidar

| Category | Triggering Condition | Severity Potential |
|----------|---------------------|-------------------|
| Attenuation | Heavy rain (>25 mm/h) | High |
| Attenuation | Dense fog | High |
| Attenuation | Spray from lead vehicle | Medium |
| Reflectivity | Dark clothing (pedestrian) | Medium |
| Reflectivity | Black vehicle | Medium |
| Saturation | Retroreflective signs/vests | Low |
| Transparency | Glass surfaces | Medium |
| Contamination | Dirty optical window | High |

## ODD Parameter Reference

### Common ODD Dimensions

| Dimension | Parameters | Typical Range |
|-----------|-----------|---------------|
| **Speed** | Min/max ego speed | 0-250 km/h (function dependent) |
| **Road type** | Highway, urban, rural, parking | Function dependent |
| **Road geometry** | Curvature, gradient, banking | R>125m, grade<12%, bank<8% |
| **Lane config** | Number of lanes, width, markings | 2+ lanes, >2.5m width |
| **Weather** | Rain rate, visibility, temperature | Clear to moderate rain |
| **Lighting** | Ambient lux, sun position | 1-100,000 lux |
| **Traffic** | Density, types, behavior | Free flow to congestion |
| **Infrastructure** | Signs, signals, barriers | Country-specific |

### ODD by SAE Level

| SAE Level | ODD Breadth | ODD Definition Responsibility |
|-----------|-------------|-------------------------------|
| L1 | Wide (driver always in loop) | OEM recommendation |
| L2 | Wide (driver must monitor) | OEM specification |
| L3 | Restricted (system monitors, driver fallback) | OEM specification, regulatory |
| L4 | Defined (system handles all in ODD) | OEM specification, regulatory |
| L5 | Unrestricted | N/A (all conditions) |

## Functional Insufficiency Categories

| Category | Type | Example | Typical Mitigation |
|----------|------|---------|-------------------|
| Sensor | Limited range | Radar max 200m | Multi-sensor fusion, speed limitation |
| Sensor | Limited FoV | Camera 50 deg horizontal | Additional sensors, wider lens |
| Sensor | Weather sensitivity | Camera in fog | Radar/lidar backup |
| Sensor | Resolution | Radar angular 3 deg | Fusion with camera for classification |
| Algorithm | False positive | AEB on bridge shadow | Multi-sensor confirmation |
| Algorithm | False negative | Miss dark pedestrian | Lidar + radar supplement |
| Algorithm | Latency | 200ms processing delay | Hardware upgrade, algorithm optimization |
| Algorithm | Classification error | Motorcycle as bicycle | Training data expansion |
| Actuator | Response time | Brake build-up 300ms | Pre-fill, predictive braking |
| Actuator | Authority | Max decel 0.8g | Warn earlier, increase authority |

## Validation Metrics

### Detection Performance

| Metric | Formula | Target (typical) |
|--------|---------|-------------------|
| True Positive Rate (Recall) | TP / (TP + FN) | > 99.5% for AEB |
| Precision | TP / (TP + FP) | > 99.9% for AEB |
| False Positive Rate | FP / (FP + TN) | < 1e-5 per hour |
| False Negative Rate | FN / (FN + TP) | < 0.5% |
| Mean detection range | Avg range at first detection | > 80m at 100 km/h |
| Min detection range | Worst-case first detection | > 50m at 100 km/h |

### System Performance

| Metric | Description | Target (typical) |
|--------|-------------|-------------------|
| Collision avoidance rate | % of collisions prevented | > 90% at <60 km/h |
| Speed reduction | Impact speed reduction when unavoidable | > 40% |
| False activation rate | Activations per km without threat | < 1 per 100,000 km |
| Availability | % of driving time function active | > 95% in ODD |
| ODD coverage | % of driving scenarios within ODD | Function dependent |

### Validation Coverage

| Validation Method | Typical Volume | Purpose |
|-------------------|---------------|---------|
| Simulation | 10^8 - 10^10 scenarios | Broad coverage, edge cases |
| HIL testing | 10^4 - 10^6 scenarios | Timing, real ECU behavior |
| Proving ground | 10^2 - 10^4 runs | Controlled, repeatable, regulatory |
| Public road (FOT) | 10^6 - 10^9 km | Discovery, statistical confidence |

## SOTIF vs. ISO 26262 Quick Comparison

| Aspect | ISO 26262 | ISO 21448 (SOTIF) |
|--------|-----------|-------------------|
| Addresses | Component failures | Performance limitations |
| Hazard source | Random HW fault, systematic SW bug | Functional insufficiency |
| Risk parameters | S, E, C -> ASIL | S, E, C -> residual risk |
| Analysis method | FMEA, FTA | Scenario analysis, TC analysis |
| Verification | Fault injection, coverage | Scenario replay, edge case testing |
| Validation | ASIL-dependent testing | Mileage-based statistical evidence |
| Metrics | PMHF, SPFM, LFM | Detection rate, FP rate, coverage |
| Lifecycle | V-model phases | Iterative discovery-mitigation loop |
| Documentation | Safety case with ASIL evidence | SOTIF validation report |

## SOTIF Work Products Checklist

### Specification Phase (Clause 5)

- [ ] Intended functionality description
- [ ] Known limitations documentation
- [ ] ODD specification
- [ ] Sensor specification with performance limits
- [ ] Algorithm specification with known weaknesses

### Hazard Identification (Clause 6)

- [ ] SOTIF-related hazardous behaviors identified
- [ ] Severity, exposure, controllability assessed
- [ ] Acceptance criteria defined

### Triggering Condition Analysis (Clause 7)

- [ ] Triggering conditions systematically identified
- [ ] Functional insufficiencies cataloged
- [ ] Insufficiency-TC mapping completed
- [ ] Scenario database constructed

### Verification (Clause 9)

- [ ] Mitigation measures implemented
- [ ] Scenario-based test results documented
- [ ] Triggering condition coverage achieved
- [ ] Known hazardous scenarios (Area 2) adequately mitigated

### Validation (Clause 10)

- [ ] Simulation validation completed
- [ ] Proving ground tests passed
- [ ] Field operational test data analyzed
- [ ] Residual risk below acceptance criteria
- [ ] Unknown hazardous scenarios (Area 4) sufficiently reduced

### Operational Phase (Clause 11)

- [ ] Field monitoring plan established
- [ ] Incident analysis process defined
- [ ] Update and re-validation process defined

## Key Terminology

| Term | Definition |
|------|-----------|
| Intended Functionality | Behavior specification of the function under nominal and foreseeable conditions |
| Functional Insufficiency | Limitation of the intended functionality causing insufficient performance |
| Triggering Condition | Specific condition that activates a functional insufficiency |
| Hazardous Behavior | System behavior that can lead to a hazardous event |
| ODD | Operational Design Domain - conditions under which system is designed to function |
| MRC | Minimal Risk Condition - safe fallback state when system cannot continue |
| Known Safe Scenario | Validated scenario where system performance is confirmed safe |
| Unknown Hazardous Scenario | Not-yet-discovered scenario that could be hazardous |

## References

- ISO 21448:2022 (complete standard)
- ISO 26262:2018 (complementary functional safety)
- SAE J3016:2021 (automation levels)
- ASAM OpenSCENARIO (scenario format)
- Euro NCAP Assessment Protocol

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All project team members

# ISO 21448 (SOTIF) - Detailed Implementation Guide

> **Target Audience**: ADAS/AD developers, validation engineers, scenario engineers

## Scenario Database Construction

### Step 1: Define Logical Scenarios

Logical scenarios describe abstract parameter ranges without specific values.

**Template**:
```
Logical Scenario ID: LS-AEB-001
Function: Automated Emergency Braking
Description: Lead vehicle braking on highway
Parameters:
  - Road type: Highway (straight, curve R>500m)
  - Speed: 60-130 km/h
  - Weather: Any
  - Lighting: Any
  - Lead vehicle: Passenger car, truck, motorcycle
  - Lead vehicle action: Braking (0.2g to 1.0g)
  - Following distance: 0.5s to 3.0s time gap
  - Lane position: Same lane
```

### Step 2: Derive Concrete Scenarios

Concrete scenarios assign specific values to parameters.

**Example from LS-AEB-001**:
```
Concrete Scenario ID: CS-AEB-001-042
Derived from: LS-AEB-001
Parameters:
  - Road: Highway, straight, dry asphalt
  - Ego speed: 100 km/h
  - Weather: Clear
  - Lighting: Daylight, no glare
  - Lead vehicle: Sedan, white
  - Lead vehicle deceleration: 0.6g
  - Time gap at trigger: 1.2s
  - Ego lane position: Center of lane
  - Expected outcome: AEB activates, collision avoided
  - Pass criteria: TTC > 0.5s at closest approach
```

### Step 3: Create Test Scenarios

Test scenarios are executable in simulation or on proving ground.

**OpenSCENARIO Example**:
```xml
<Scenario name="AEB_Highway_Lead_Braking">
  <ParameterDeclarations>
    <ParameterDeclaration name="EgoSpeed" parameterType="double" value="27.8"/>
    <ParameterDeclaration name="LeadDecel" parameterType="double" value="5.88"/>
    <ParameterDeclaration name="TimeGap" parameterType="double" value="1.2"/>
  </ParameterDeclarations>
  <Storyboard>
    <Init>
      <Actions>
        <Private entityRef="Ego">
          <TeleportAction>
            <Position><LanePosition roadId="1" laneId="-1" s="100"/></Position>
          </TeleportAction>
          <SpeedAction><AbsoluteTargetSpeed value="$EgoSpeed"/></SpeedAction>
        </Private>
        <Private entityRef="LeadVehicle">
          <TeleportAction>
            <Position><LanePosition roadId="1" laneId="-1" s="133.4"/></Position>
          </TeleportAction>
          <SpeedAction><AbsoluteTargetSpeed value="$EgoSpeed"/></SpeedAction>
        </Private>
      </Actions>
    </Init>
    <Story name="LeadBraking">
      <Act name="BrakingAct">
        <ManeuverGroup name="BrakeGroup">
          <Maneuver name="BrakeManeuver">
            <Event name="BrakeEvent">
              <Action name="Brake">
                <Private entityRef="LeadVehicle">
                  <LongitudinalAction>
                    <SpeedAction>
                      <SpeedActionTarget>
                        <AbsoluteTargetSpeed value="0"/>
                      </SpeedActionTarget>
                      <TransitionDynamics shape="linear" value="$LeadDecel"/>
                    </SpeedAction>
                  </LongitudinalAction>
                </Private>
              </Action>
              <StartTrigger>
                <ConditionGroup>
                  <Condition name="TimeGapReached">
                    <ByEntity>
                      <TriggeringEntities>
                        <EntityRef entityRef="Ego"/>
                      </TriggeringEntities>
                      <EntityCondition>
                        <TimeHeadwayCondition entityRef="LeadVehicle"
                          value="$TimeGap" rule="lessThan"/>
                      </EntityCondition>
                    </ByEntity>
                  </Condition>
                </ConditionGroup>
              </StartTrigger>
            </Event>
          </Maneuver>
        </ManeuverGroup>
      </Act>
    </Story>
  </Storyboard>
</Scenario>
```

### Step 4: Scenario Coverage Matrix

Track coverage across parameter dimensions:

| Parameter | Values Tested | Coverage |
|-----------|--------------|----------|
| Ego speed | 60, 80, 100, 120, 130 km/h | 5/5 |
| Lead decel | 0.2, 0.4, 0.6, 0.8, 1.0 g | 5/5 |
| Time gap | 0.5, 0.8, 1.0, 1.2, 1.5, 2.0, 3.0 s | 7/7 |
| Weather | Clear, light rain, heavy rain, fog | 4/6 |
| Lighting | Day, dusk, night, tunnel entry | 4/5 |
| Lead vehicle | Car, truck, motorcycle | 3/4 |
| Road surface | Dry, wet, icy | 3/3 |
| **Total combinations** | | **8,820 / 12,600** |

## Triggering Condition Analysis Process

### Step 1: Systematic Identification

Use a structured checklist for each sensor modality:

**Camera Triggering Conditions**:
```
1. Direct sunlight / glare
   - Sun within 30 deg of camera axis
   - Low sun angle (sunrise/sunset)
   - Reflection from wet road or vehicles

2. Low contrast conditions
   - Fog (visibility < 200m)
   - Heavy rain on lens
   - Snow-covered road (white on white)
   - Night without street lighting

3. Confusing visual patterns
   - Road construction markings (conflicting lines)
   - Shadows creating false edges
   - Lane markings on adjacent surface (parking lot edge)
   - Tire marks resembling lane markings

4. Lens degradation
   - Dirt, mud, insect residue
   - Ice formation
   - Scratches, stone chips
   - Condensation (internal/external)
```

**Radar Triggering Conditions**:
```
1. False targets (clutter)
   - Metal bridges and overpasses
   - Guardrails on curves
   - Manhole covers
   - Large signs

2. Missed targets
   - Stationary objects (filtered by design)
   - Small cross-section (pedestrian, bicycle)
   - Objects at extreme angles

3. Multi-path reflections
   - Tunnel walls
   - Adjacent large vehicles
   - Metal barriers

4. Interference
   - Adjacent vehicle radar
   - Radio frequency interference
```

**Lidar Triggering Conditions**:
```
1. Environmental
   - Heavy rain (scattering)
   - Fog (absorption)
   - Dust, spray from lead vehicle
   - Direct sunlight saturation

2. Target properties
   - Dark/absorbing surfaces (low reflectivity)
   - Retroreflective surfaces (saturation)
   - Transparent objects (glass walls)

3. Mechanical
   - Vibration affecting alignment
   - Thermal drift
   - Contamination of optical window
```

### Step 2: Severity Analysis per Triggering Condition

For each triggering condition, assess the resulting hazardous behavior:

```
TC ID: TC-CAM-001
Triggering Condition: Direct sunlight glare
Affected Function: Lane Keeping Assist

Hazardous Behavior:
  HB-1: Lane detection lost -> LKA deactivation without warning
  HB-2: False lane boundary detected -> steering toward wrong lane
  HB-3: Intermittent detection -> oscillating steering corrections

Severity Assessment per Hazardous Behavior:
  HB-1: S2 (lane departure at highway speed)
  HB-2: S3 (steering into oncoming traffic)
  HB-3: S1 (uncomfortable driving, minor swerving)

Exposure: E3 (glare during sunrise/sunset commutes)
Controllability: C2 (driver can override steering)
```

### Step 3: Risk Reduction Measures

For each identified risk, define mitigation:

```
Risk: AEB false activation on bridge overpass
Root Cause: Radar cannot distinguish overhead structure from road obstacle

Mitigation Options:
M1: Sensor fusion (require camera confirmation for stationary objects)
    - Effectiveness: High (camera can see open road)
    - Side effect: Reduced detection of stationary obstacles without camera
    - Residual risk: Camera also fails (night, dirty lens)

M2: Map-based filtering (suppress braking near known bridges)
    - Effectiveness: Medium (requires HD map, GPS accuracy)
    - Side effect: May suppress valid braking near bridges
    - Residual risk: Unmapped bridges, GPS error

M3: Height estimation (reject objects above road plane)
    - Effectiveness: Medium-High (radar elevation resolution limited)
    - Side effect: May reject valid tall obstacles
    - Residual risk: Bridge at unusual height

Selected: M1 + M3 (defense in depth)
Verification: Replay 500 bridge scenarios, confirm zero false positives
Validation: Field test over 10,000 bridge crossings
```

## Acceptance Criteria Derivation

### Quantitative Criteria

**Residual Risk Target**:
```
SOTIF residual risk must be below societal acceptance threshold.

For AEB (preventing fatalities):
  Target: System must not cause more harm than it prevents
  Metric: Net lives saved = Lives saved by AEB - Lives lost by AEB false activation

  Quantitative target:
  P(false activation causing fatality) < 1e-9 per hour of driving
  P(true positive detection) > 99.5% for relevant scenarios
```

**Derivation Method**:
```
Step 1: Determine exposure-weighted risk
  Risk = Sum over all scenarios: P(scenario) x P(hazardous behavior | scenario) x Severity

Step 2: Set acceptance threshold
  Threshold based on:
  - Comparable manual driving risk
  - Societal expectations
  - Regulatory requirements (e.g., Euro NCAP)

Step 3: Calculate required scenario coverage
  Coverage needed = -ln(1 - Confidence) / Target_failure_rate

  Example for 95% confidence that failure rate < 1e-9/h:
  Required test hours = -ln(0.05) / 1e-9 = 3e9 hours
  At 50 km/h average: 1.5e11 km of driving

  -> Infeasible with real driving alone
  -> Must use simulation + accelerated testing
```

### Qualitative Criteria

| Criterion | Metric | Target |
|-----------|--------|--------|
| Known hazardous scenarios mitigated | % of Area 2 scenarios with mitigation | 100% |
| Triggering conditions analyzed | % of identified TCs with risk evaluation | 100% |
| Sensor insufficiencies documented | Completeness of insufficiency catalog | Complete per sensor |
| ODD boundaries validated | % of ODD boundaries with test evidence | 100% |
| Field operational test duration | Kilometers driven without SOTIF incident | Per function target |

## Simulation-Based Validation

### Simulation Environment Requirements

**Sensor Models**:
```
Camera Model Requirements:
  - Lens distortion (barrel, pincushion)
  - Motion blur at vehicle speed
  - Auto-exposure response time
  - Noise model (ISO, temperature dependent)
  - Rain droplet rendering on lens
  - Sun glare / bloom effects
  - Resolution matching real sensor

Radar Model Requirements:
  - Range-dependent SNR
  - Angular resolution (azimuth, elevation)
  - Doppler velocity measurement
  - Multi-path reflection model
  - Clutter model (road surface, guardrails)
  - Cross-section model per object type
  - Interference model

Lidar Model Requirements:
  - Beam pattern (mechanical / solid-state)
  - Range-dependent intensity
  - Weather attenuation model
  - Material reflectivity model
  - Motion compensation artifacts
```

### Scenario Variation Strategy

**Combinatorial Testing**:
```python
# Example: Parameter space sampling for AEB validation
import itertools

ego_speeds = [60, 80, 100, 120, 130]  # km/h
target_types = ["car", "truck", "motorcycle", "pedestrian", "cyclist"]
weather = ["clear", "light_rain", "heavy_rain", "fog", "snow"]
lighting = ["day", "dusk", "night", "tunnel_entry", "tunnel_exit"]
road_surface = ["dry", "wet", "icy"]
time_gaps = [0.5, 0.8, 1.0, 1.2, 1.5, 2.0, 3.0]

# Full factorial: 5 x 5 x 5 x 5 x 3 x 7 = 13,125 scenarios
full_factorial = list(itertools.product(
    ego_speeds, target_types, weather, lighting, road_surface, time_gaps
))

# Latin Hypercube Sampling for continuous parameters
# Adaptive sampling: increase density near boundary conditions
```

**Corner Case Generation**:
```
Adversarial scenario generation techniques:
1. Parameter boundary testing (min/max of each dimension)
2. Sensor failure injection (degraded mode combinations)
3. Object appearance variation (unusual colors, shapes, occlusions)
4. Traffic behavior variation (aggressive, erratic, rule-breaking)
5. Infrastructure variation (missing signs, faded markings, construction)
6. Multi-fault scenarios (rain + night + dirty lens + faded markings)
```

## Proving Ground Test Procedures

### Euro NCAP AEB Test Protocol (Reference)

```
Test Setup: Car-to-Car Rear Stationary (CCRs)
  - Ego vehicle approaches stationary target
  - Target: Global Vehicle Target (GVT)
  - Speeds: 10, 20, 30, 40, 50 km/h
  - Offset: 0% (centered), 25%, 50%, 75%
  - Pass criteria: Collision avoided or speed reduced by X%

Test Setup: Car-to-Pedestrian (CPFA)
  - Pedestrian crosses from far side
  - Adult target, 5 km/h crossing speed
  - Ego speed: 20-60 km/h in 5 km/h steps
  - Obstruction: 50% occluded by parked vehicle
  - Pass criteria: Collision avoided or speed reduced by X%
```

### SOTIF-Specific Proving Ground Tests

```
Test Category: Sensor Limitation Scenarios

Test SL-001: Camera glare immunity
  Setup: Drive toward sun (±10 deg of camera axis)
  Speed: 50, 80, 100 km/h
  Scenario: Pedestrian crossing during glare
  Pass: Detection within specification, no false lane departure

Test SL-002: Radar false positive rejection
  Setup: Drive under metal bridge at various heights (4m, 5m, 6m)
  Speed: 80, 100, 120 km/h
  Scenario: No obstacles present
  Pass: No AEB activation, no false FCW

Test SL-003: Lidar rain performance
  Setup: Rain machine (10, 25, 50 mm/h simulated rainfall)
  Speed: 50, 80 km/h
  Scenario: Static obstacle (Euro NCAP target) at 50m
  Pass: Detection at minimum 40m, correct classification
```

## Field Operational Test (FOT) Design

### Data Collection Architecture

```
Vehicle Data Logger
|
+-- Raw Sensor Data (optional, high bandwidth)
|   +-- Camera: H.265 compressed, triggered recording
|   +-- Radar: Object list + raw detections
|   +-- Lidar: Point cloud, triggered recording
|
+-- Perception Output (always recorded)
|   +-- Object list (ID, class, position, velocity, confidence)
|   +-- Lane detection (coefficients, confidence, marking type)
|   +-- Free space boundary
|
+-- System State (always recorded)
|   +-- Active functions (AEB, LKA, ACC state machines)
|   +-- Warnings issued
|   +-- Driver interventions (brake, steering override)
|   +-- ODD monitoring status
|
+-- Event Triggers (flag for detailed review)
    +-- AEB activation (true positive or false positive)
    +-- Driver override of active function
    +-- Low confidence detection in safety-critical zone
    +-- Near-miss event (TTC < threshold without system action)
    +-- ODD exit events
```

### Statistical Validation

**Confidence Interval Calculation**:
```
For demonstrating failure rate lambda < target:

Required observation time T = chi2(2, 1-alpha) / (2 * target)

Example: Demonstrate AEB false activation < 1e-7 per hour
  alpha = 0.05 (95% confidence)
  chi2(2, 0.95) = 5.99
  T = 5.99 / (2 * 1e-7) = 29,950,000 hours
  At 50 km/h: ~1.5 billion km

With accelerated testing factor k = 100:
  T_real = 299,500 hours = ~15 million km
```

## SOTIF Process Integration with V-Model

```
ISO 26262 V-Model              SOTIF Activities
===================            ================

Concept Phase                  SOTIF Specification
  Item Definition       <-->   Intended Functionality Definition
  HARA                  <-->   SOTIF Hazard Identification
  Safety Concept        <-->   SOTIF Safety Concept + ODD

System Design                  Triggering Condition Analysis
  Technical Safety      <-->   Functional Insufficiency ID
  System Architecture   <-->   Sensor Fusion Strategy
  HSI Specification     <-->   HMI Design for SOTIF

SW/HW Development              Implementation of Mitigations
  SW Architecture       <-->   Algorithm Improvement
  HW Design             <-->   Sensor Selection & Placement

Integration & Test             SOTIF Verification
  Integration Test      <-->   Scenario-Based Testing
  System Test           <-->   Proving Ground Tests

Validation                     SOTIF Validation
  Safety Validation     <-->   Field Operational Tests
  Release Decision      <-->   Residual Risk Acceptance
```

## Next Steps

- **Level 4**: Quick reference tables for triggering conditions, scenario parameters, and acceptance metrics
- **Level 5**: Advanced topics: ML-specific SOTIF, continuous validation, OTA safety assurance, regulatory landscape

## References

- ISO 21448:2022 Clauses 6-7 (Hazard identification, triggering conditions)
- ISO 21448:2022 Clauses 8-10 (Risk evaluation, verification, validation)
- ISO 21448:2022 Annex B (Functional insufficiency examples)
- ISO 21448:2022 Annex C (Triggering condition examples)
- ASAM OpenSCENARIO 1.x (Scenario description format)
- Euro NCAP 2025 Assessment Protocol

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: ADAS/AD developers, validation engineers, scenario engineers

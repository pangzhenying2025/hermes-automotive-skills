# SOTIF Development Rules (ISO 21448)

> Safety of the Intended Functionality - coding and development rules
> to address hazards arising from functional insufficiencies and
> reasonably foreseeable misuse, distinct from systematic faults
> covered by ISO 26262.

## Scope

These rules apply to all software implementing sensor processing,
perception, decision-making, and control functions where hazardous
behavior can arise from:
- Functional limitations of sensors or algorithms
- Reasonably foreseeable misuse by drivers or operators
- Performance limitations under specific operating conditions
- Triggering conditions not anticipated during design

Primarily targets ADAS (L1-L2) and automated driving (L3+) functions,
but also applies to BMS algorithms, predictive maintenance, and any
system where sensor interpretation drives safety-relevant decisions.

---

## SOTIF vs ISO 26262

| Aspect | ISO 26262 | ISO 21448 (SOTIF) |
|--------|-----------|-------------------|
| Addresses | Systematic/random HW faults | Functional insufficiencies |
| Root cause | Design errors, HW failures | Correct design but limited capability |
| Example | Software bug in brake calc | Radar fails to detect pedestrian in rain |
| Goal | Freedom from unreasonable risk due to faults | Absence of unreasonable risk due to intended functionality |
| Key activity | FMEA, FTA, code review | Triggering condition analysis, validation |

---

## Triggering Condition Analysis

### Rule 1: Identify All Triggering Conditions

Every sensor-based function must document its triggering conditions -
specific scenarios where the function may produce incorrect output
despite being implemented correctly.

```yaml
# Triggering Condition Registry - AEB (Automatic Emergency Braking)
function: automatic_emergency_braking
sensors: [front_radar, front_camera, lidar]

triggering_conditions:
  - id: TC-AEB-001
    category: environmental
    description: "Heavy rain reduces radar return signal below detection threshold"
    affected_sensor: front_radar
    severity: high
    mitigation: "Fuse with camera and lidar; reduce confidence when rain detected"
    validation_method: "Rain chamber testing at 50-150 mm/h"

  - id: TC-AEB-002
    category: sensor_limitation
    description: "Camera saturated by direct low-angle sunlight"
    affected_sensor: front_camera
    severity: high
    mitigation: "Sun position awareness; weight other sensors higher during glare"
    validation_method: "Dawn/dusk driving campaigns, SIL with glare injection"

  - id: TC-AEB-003
    category: target_properties
    description: "Low-reflectivity pedestrian clothing at night"
    affected_sensor: front_camera
    severity: critical
    mitigation: "IR illumination; radar-primary mode in low-light"
    validation_method: "Night testing with mannequins in dark clothing"

  - id: TC-AEB-004
    category: misuse
    description: "Driver ignores forward collision warning and does not brake"
    affected_sensor: N/A
    severity: medium
    mitigation: "Escalating warnings; autonomous braking if no response"
    validation_method: "Driver behavior study; HIL testing"
```

### Rule 2: Triggering Condition Coverage

All identified triggering conditions must be:
1. Documented in the SOTIF triggering condition registry
2. Analyzed for hazard potential (HARA linkage)
3. Assigned at least one mitigation strategy
4. Covered by at least one validation test case
5. Reviewed quarterly as field data becomes available

---

## Sensor Fusion Rules

### Rule 3: Multi-Sensor Independence

Safety-relevant perception must not depend on a single sensor modality.

```c
/* Sensor fusion architecture - minimum two independent paths */
typedef struct {
    ObjectDetection_t radar_detections[MAX_RADAR_OBJECTS];
    ObjectDetection_t camera_detections[MAX_CAMERA_OBJECTS];
    ObjectDetection_t lidar_detections[MAX_LIDAR_OBJECTS];
    uint8_t radar_count;
    uint8_t camera_count;
    uint8_t lidar_count;
    float radar_confidence;    /* 0.0 to 1.0 */
    float camera_confidence;   /* 0.0 to 1.0 */
    float lidar_confidence;    /* 0.0 to 1.0 */
} SensorFusionInput_t;

/* Confidence-weighted fusion */
FusedObject_t fuse_detections(const SensorFusionInput_t* input) {
    /* Rule: Never trust a single sensor at 100% */
    const float total_confidence =
        input->radar_confidence +
        input->camera_confidence +
        input->lidar_confidence;

    /* Rule: Require minimum 2 sensors agreeing for high-confidence output */
    uint8_t confirming_sensors = 0U;
    if (input->radar_confidence > SENSOR_VALID_THRESHOLD) confirming_sensors++;
    if (input->camera_confidence > SENSOR_VALID_THRESHOLD) confirming_sensors++;
    if (input->lidar_confidence > SENSOR_VALID_THRESHOLD) confirming_sensors++;

    FusedObject_t result;
    if (confirming_sensors >= 2U) {
        result.confidence = CONFIDENCE_HIGH;
    } else if (confirming_sensors == 1U) {
        result.confidence = CONFIDENCE_MEDIUM;
    } else {
        result.confidence = CONFIDENCE_LOW;
    }
    /* ... weighted position/velocity fusion ... */
    return result;
}
```

### Rule 4: Sensor Degradation Awareness

```c
/* Each sensor must report its current capability level */
typedef enum {
    SENSOR_CAPABILITY_FULL,        /* Normal operation */
    SENSOR_CAPABILITY_DEGRADED,    /* Reduced range or accuracy */
    SENSOR_CAPABILITY_MINIMAL,     /* Severely limited */
    SENSOR_CAPABILITY_UNAVAILABLE  /* No usable data */
} SensorCapability_t;

/* Function must adapt behavior based on available sensor capability */
typedef struct {
    SensorCapability_t radar;
    SensorCapability_t camera;
    SensorCapability_t lidar;
    float combined_capability_percent;  /* 0-100 */
} PerceptionCapability_t;

/* Determine safe operating envelope based on current capability */
OperatingEnvelope_t compute_safe_envelope(
    const PerceptionCapability_t* capability) {

    OperatingEnvelope_t envelope;

    if (capability->combined_capability_percent < 30.0f) {
        /* Severely degraded - request driver takeover */
        envelope.max_speed_kmh = 0.0f;
        envelope.driver_takeover_required = true;
    } else if (capability->combined_capability_percent < 60.0f) {
        /* Degraded - reduce speed and increase following distance */
        envelope.max_speed_kmh = 60.0f;
        envelope.min_following_distance_m = 50.0f;
        envelope.driver_takeover_required = false;
    } else {
        /* Normal capability */
        envelope.max_speed_kmh = 130.0f;
        envelope.min_following_distance_m = 20.0f;
        envelope.driver_takeover_required = false;
    }
    return envelope;
}
```

---

## Algorithm Robustness Rules

### Rule 5: Input Validation and Plausibility

```c
/* Every sensor input must pass plausibility checks before use */
typedef struct {
    bool range_valid;        /* Within physical limits */
    bool rate_valid;         /* Rate of change plausible */
    bool cross_check_valid;  /* Consistent with other sensors */
    bool temporal_valid;     /* Not stale */
} PlausibilityResult_t;

PlausibilityResult_t check_radar_range(
    float current_range_m,
    float previous_range_m,
    float vehicle_speed_ms,
    float dt_s,
    float ultrasonic_range_m) {

    PlausibilityResult_t result = {0};

    /* Range check: physical limits */
    result.range_valid =
        (current_range_m >= RADAR_MIN_RANGE_M) &&
        (current_range_m <= RADAR_MAX_RANGE_M);

    /* Rate check: object cannot move faster than physically possible */
    const float max_delta_m = (vehicle_speed_ms + MAX_RELATIVE_SPEED_MS) * dt_s;
    const float actual_delta_m = fabsf(current_range_m - previous_range_m);
    result.rate_valid = (actual_delta_m <= max_delta_m);

    /* Cross-check: radar and ultrasonic must agree at close range */
    if (current_range_m < ULTRASONIC_MAX_RANGE_M) {
        const float discrepancy_m =
            fabsf(current_range_m - ultrasonic_range_m);
        result.cross_check_valid =
            (discrepancy_m < CROSS_CHECK_TOLERANCE_M);
    } else {
        result.cross_check_valid = true;  /* Out of US range */
    }

    return result;
}
```

### Rule 6: Graceful Degradation Under Uncertainty

```c
/* Decision confidence thresholds */
#define CONFIDENCE_THRESHOLD_FULL_ACTION     0.95f
#define CONFIDENCE_THRESHOLD_REDUCED_ACTION  0.80f
#define CONFIDENCE_THRESHOLD_WARNING_ONLY    0.60f
#define CONFIDENCE_THRESHOLD_NO_ACTION       0.40f

/* Scale action authority based on confidence */
ActionAuthority_t determine_action_authority(float confidence) {
    if (confidence >= CONFIDENCE_THRESHOLD_FULL_ACTION) {
        return (ActionAuthority_t){
            .brake_authority = 1.0f,
            .steer_authority = 1.0f,
            .action = ACTION_AUTONOMOUS
        };
    } else if (confidence >= CONFIDENCE_THRESHOLD_REDUCED_ACTION) {
        return (ActionAuthority_t){
            .brake_authority = 0.7f,
            .steer_authority = 0.5f,
            .action = ACTION_ASSISTED
        };
    } else if (confidence >= CONFIDENCE_THRESHOLD_WARNING_ONLY) {
        return (ActionAuthority_t){
            .brake_authority = 0.0f,
            .steer_authority = 0.0f,
            .action = ACTION_WARN_DRIVER
        };
    } else {
        return (ActionAuthority_t){
            .brake_authority = 0.0f,
            .steer_authority = 0.0f,
            .action = ACTION_NONE
        };
    }
}
```

---

## Known Limitation Documentation

### Rule 7: Operational Design Domain (ODD)

Every SOTIF-relevant function must define its ODD explicitly:

```yaml
function: lane_keeping_assist
odd:
  speed_range:
    min_kmh: 60
    max_kmh: 180
  road_types: [highway, expressway]
  lane_markings: [solid, dashed, double]
  weather_conditions: [clear, light_rain, overcast]
  lighting_conditions: [daylight, dusk, artificial_lighting]
  excluded_conditions:
    - heavy_rain
    - snow_on_road
    - construction_zones
    - unpainted_roads
    - tunnels_without_lighting
  sensor_requirements:
    camera: FULL
    radar: DEGRADED_OK
    lidar: OPTIONAL
```

### Rule 8: Known Limitation Registry

```yaml
# Every known limitation must be registered
limitations:
  - id: LIM-LKA-001
    function: lane_keeping_assist
    description: "Cannot detect lane markings under standing water"
    root_cause: "Camera reflection from water surface"
    risk_level: medium
    mitigation: "Disable LKA when rain sensor reports heavy precipitation"
    residual_risk: "Brief pooling without heavy rain detection"
    validation: "Wet road testing, SIL rain injection"

  - id: LIM-LKA-002
    function: lane_keeping_assist
    description: "Reduced accuracy on tight curves (radius < 250m)"
    root_cause: "Camera FOV limitation on sharp curves"
    risk_level: low
    mitigation: "Reduce steering authority on curves below threshold"
    residual_risk: "Acceptable with driver monitoring"
    validation: "Curvy road testing campaign"
```

---

## Misuse Analysis

### Rule 9: Foreseeable Misuse Scenarios

```yaml
misuse_scenarios:
  - id: MIS-001
    function: adaptive_cruise_control
    misuse: "Driver relies on ACC in stop-and-go traffic while distracted"
    category: over_reliance
    mitigation:
      - Driver attention monitoring via camera
      - Escalating warnings if inattention detected
      - System disengagement after N seconds of inattention
    test_method: "Driver monitoring HIL test with distraction injection"

  - id: MIS-002
    function: park_assist
    misuse: "Driver exits vehicle during automated parking maneuver"
    category: abandonment
    mitigation:
      - Seatbelt sensor check
      - Door open detection -> immediate stop
      - Maximum unattended distance limit
    test_method: "Integration test with door/seatbelt signal simulation"
```

---

## Validation Strategy

### Rule 10: SOTIF Validation Matrix

| Validation Method | TC Coverage | Confidence | Cost |
|------------------|-------------|------------|------|
| Simulation (SIL) | Broad exploration | Medium | Low |
| HIL testing | Specific scenarios | High | Medium |
| Proving ground | Critical scenarios | Very High | High |
| Public road testing | Real-world exposure | Highest | Very High |
| Field monitoring | Post-release | Continuous | Ongoing |

**Rule**: Each triggering condition must be validated by at least two
different methods, with at least one being a physical test (HIL, proving
ground, or public road).

### Residual Risk Acceptance

```
Area 1: Known Safe      - Validated, no hazard identified
Area 2: Known Unsafe    - Identified hazard, mitigated
Area 3: Unknown Unsafe  - Not yet identified -> SOTIF goal: minimize this
Area 4: Unknown Safe    - No hazard but not validated

SOTIF target: Reduce Area 3 (unknown unsafe) to acceptable level
through systematic triggering condition analysis and validation.
```

---

## Review Checklist

- [ ] Triggering condition registry maintained and current
- [ ] All triggering conditions linked to hazards and mitigations
- [ ] Sensor fusion requires minimum 2 independent confirmations
- [ ] Sensor degradation detection and graceful degradation implemented
- [ ] Input plausibility checks on all sensor data
- [ ] Action authority scaled by confidence level
- [ ] ODD explicitly defined for every SOTIF function
- [ ] Known limitations registered with mitigations
- [ ] Foreseeable misuse scenarios analyzed and mitigated
- [ ] Validation matrix covers all triggering conditions
- [ ] Field monitoring plan defined for post-release
- [ ] Quarterly review of triggering conditions with field data

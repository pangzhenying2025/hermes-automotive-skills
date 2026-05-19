# V2X Communication - Level 3: Detailed Implementation

> Audience: Developers and testers implementing V2X functionality
> Purpose: Code examples, message encoding, and implementation patterns

## CAM Message Encoding (ASN.1/UPER)

### CAM Structure

```asn1
CAM ::= SEQUENCE {
    header    ItsPduHeader,
    cam       CoopAwareness
}

CoopAwareness ::= SEQUENCE {
    generationDeltaTime   GenerationDeltaTime,
    camParameters         CamParameters
}

CamParameters ::= SEQUENCE {
    basicContainer        BasicContainer,
    highFrequencyContainer HighFrequencyContainer,
    lowFrequencyContainer  LowFrequencyContainer OPTIONAL,
    specialVehicleContainer SpecialVehicleContainer OPTIONAL
}

BasicContainer ::= SEQUENCE {
    stationType    StationType,
    referencePosition ReferencePosition
}
```

### C Implementation: CAM Generation

```c
#include "cam_api.h"
#include "gnss_api.h"
#include "vehicle_dynamics.h"

#define CAM_MIN_INTERVAL_MS    100   /* 10 Hz maximum */
#define CAM_MAX_INTERVAL_MS    1000  /* 1 Hz minimum */
#define CAM_HEADING_CHANGE_DEG 4.0f  /* Trigger on heading change */
#define CAM_POSITION_CHANGE_M  4.0f  /* Trigger on position change */
#define CAM_SPEED_CHANGE_MPS   0.5f  /* Trigger on speed change */

typedef struct {
    uint32_t last_cam_time_ms;
    GnssPosition_t last_cam_position;
    float last_cam_heading_deg;
    float last_cam_speed_mps;
    uint16_t generation_delta_time;
} CamGeneratorState_t;

static CamGeneratorState_t s_cam_state;

/* Determine if a new CAM should be generated */
bool cam_should_generate(const GnssPosition_t* current_pos,
                          float current_heading_deg,
                          float current_speed_mps,
                          uint32_t current_time_ms) {
    uint32_t elapsed = current_time_ms - s_cam_state.last_cam_time_ms;

    /* Always generate at minimum rate */
    if (elapsed >= CAM_MAX_INTERVAL_MS) {
        return true;
    }

    /* Don't exceed maximum rate */
    if (elapsed < CAM_MIN_INTERVAL_MS) {
        return false;
    }

    /* Generate on significant heading change */
    float heading_delta = fabsf(current_heading_deg -
                                 s_cam_state.last_cam_heading_deg);
    if (heading_delta > 180.0f) heading_delta = 360.0f - heading_delta;
    if (heading_delta >= CAM_HEADING_CHANGE_DEG) {
        return true;
    }

    /* Generate on significant position change */
    float distance = compute_distance_m(&s_cam_state.last_cam_position,
                                         current_pos);
    if (distance >= CAM_POSITION_CHANGE_M) {
        return true;
    }

    /* Generate on significant speed change */
    if (fabsf(current_speed_mps - s_cam_state.last_cam_speed_mps)
            >= CAM_SPEED_CHANGE_MPS) {
        return true;
    }

    return false;
}

/* Build and encode a CAM message */
int cam_generate(uint8_t* buffer, size_t buffer_size,
                  size_t* encoded_length) {
    GnssPosition_t position;
    VehicleDynamics_t dynamics;

    gnss_get_position(&position);
    vehicle_get_dynamics(&dynamics);

    CAM_t cam = {0};

    /* ITS PDU Header */
    cam.header.protocolVersion = 2;
    cam.header.messageID = MESSAGE_ID_CAM;
    cam.header.stationID = get_station_id();

    /* Generation delta time (ms since 2004-01-01T00:00:00Z mod 65536) */
    cam.cam.generationDeltaTime =
        compute_generation_delta_time(get_its_timestamp());

    /* Basic container */
    cam.cam.camParameters.basicContainer.stationType = STATION_TYPE_PASSENGER_CAR;
    cam.cam.camParameters.basicContainer.referencePosition.latitude =
        (int32_t)(position.latitude_deg * 1e7);
    cam.cam.camParameters.basicContainer.referencePosition.longitude =
        (int32_t)(position.longitude_deg * 1e7);
    cam.cam.camParameters.basicContainer.referencePosition.positionConfidenceEllipse
        .semiMajorConfidence = position.horizontal_accuracy_cm;

    /* High frequency container */
    HighFrequencyContainer_t* hfc =
        &cam.cam.camParameters.highFrequencyContainer;
    hfc->present = HighFrequencyContainer_PR_basicVehicleContainerHighFrequency;
    hfc->choice.basicVehicleContainerHighFrequency.heading.headingValue =
        (uint16_t)(dynamics.heading_deg * 10.0f);  /* 0.1 degree units */
    hfc->choice.basicVehicleContainerHighFrequency.speed.speedValue =
        (uint16_t)(dynamics.speed_mps * 100.0f);   /* 0.01 m/s units */
    hfc->choice.basicVehicleContainerHighFrequency.longitudinalAcceleration
        .longitudinalAccelerationValue =
        (int16_t)(dynamics.acceleration_mps2 * 10.0f); /* 0.1 m/s2 */
    hfc->choice.basicVehicleContainerHighFrequency.yawRate.yawRateValue =
        (int16_t)(dynamics.yaw_rate_dps * 100.0f);  /* 0.01 deg/s */

    /* Encode to UPER (Unaligned Packed Encoding Rules) */
    asn_enc_rval_t enc_result = uper_encode_to_buffer(
        &asn_DEF_CAM, NULL, &cam, buffer, buffer_size);

    if (enc_result.encoded < 0) {
        return -1;
    }

    *encoded_length = (enc_result.encoded + 7) / 8;  /* bits to bytes */
    return 0;
}
```

### DENM Event Handling

```c
/* DENM event detection and message generation */
typedef struct {
    uint32_t event_id;
    DenmCause_t cause;
    DenmSubCause_t sub_cause;
    GnssPosition_t event_position;
    float event_speed_mps;
    uint32_t detection_time_ms;
    uint32_t validity_duration_s;
    bool is_active;
} DenmEvent_t;

DenmEvent_t detect_hazard_events(const VehicleState_t* state) {
    DenmEvent_t event = {0};

    /* Emergency Electronic Brake Light */
    if (state->deceleration_mps2 < -4.0f && state->brake_active) {
        event.cause = CAUSE_EMERGENCY_VEHICLE_APPROACHING;
        event.sub_cause = SUBCAUSE_EMERGENCY_BRAKE;
        event.is_active = true;
        event.validity_duration_s = 10;
    }

    /* Stationary vehicle detection */
    if (state->speed_mps < 0.5f && state->hazard_lights_on &&
        state->time_stationary_s > 30) {
        event.cause = CAUSE_STATIONARY_VEHICLE;
        event.sub_cause = SUBCAUSE_VEHICLE_BREAKDOWN;
        event.is_active = true;
        event.validity_duration_s = 600;  /* 10 minutes */
    }

    /* Adverse weather detection */
    if (state->wiper_speed == WIPER_FAST &&
        state->visibility_m < 100.0f) {
        event.cause = CAUSE_ADVERSE_WEATHER;
        event.sub_cause = SUBCAUSE_HEAVY_RAIN;
        event.is_active = true;
        event.validity_duration_s = 300;
    }

    return event;
}
```

## Message Signing and Verification

```c
/* Sign outgoing V2X message with pseudonym certificate */
int v2x_sign_message(const uint8_t* payload, size_t payload_len,
                      uint8_t* signed_message, size_t* signed_len) {
    /* Get current pseudonym certificate from pool */
    PseudonymCert_t* cert = pseudonym_pool_get_current();
    if (cert == NULL || pseudonym_is_expired(cert)) {
        cert = pseudonym_pool_rotate();
        if (cert == NULL) {
            return V2X_ERR_NO_CERTIFICATE;
        }
    }

    /* Build IEEE 1609.2 Secured Message */
    SecuredMessage_t secured = {0};
    secured.protocol_version = 3;
    secured.content.type = CONTENT_SIGNED_DATA;
    secured.content.signed_data.hash_id = HASH_SHA256;
    secured.content.signed_data.tbs_data.payload = payload;
    secured.content.signed_data.tbs_data.payload_len = payload_len;
    secured.content.signed_data.signer.type = SIGNER_CERTIFICATE;
    memcpy(&secured.content.signed_data.signer.certificate,
           cert, sizeof(PseudonymCert_t));

    /* Compute signature via HSM */
    uint8_t tbs_hash[SHA256_SIZE];
    sha256_compute((uint8_t*)&secured.content.signed_data.tbs_data,
                   sizeof(secured.content.signed_data.tbs_data),
                   tbs_hash);

    if (!hsm_ecdsa_sign(V2X_SIGNING_KEY_SLOT, tbs_hash,
                         secured.content.signed_data.signature)) {
        return V2X_ERR_SIGNING_FAILED;
    }

    /* Encode secured message */
    return encode_secured_message(&secured, signed_message, signed_len);
}

/* Verify incoming V2X message */
V2xVerifyResult_t v2x_verify_message(const uint8_t* signed_message,
                                       size_t signed_len,
                                       uint8_t* payload,
                                       size_t* payload_len) {
    SecuredMessage_t secured;
    if (decode_secured_message(signed_message, signed_len, &secured) != 0) {
        return V2X_VERIFY_DECODE_ERROR;
    }

    /* Check certificate validity */
    if (!certificate_is_valid(&secured.content.signed_data.signer.certificate)) {
        return V2X_VERIFY_CERT_INVALID;
    }

    /* Check certificate revocation */
    if (crl_is_revoked(&secured.content.signed_data.signer.certificate)) {
        return V2X_VERIFY_CERT_REVOKED;
    }

    /* Verify ECDSA signature */
    uint8_t tbs_hash[SHA256_SIZE];
    sha256_compute((uint8_t*)&secured.content.signed_data.tbs_data,
                   sizeof(secured.content.signed_data.tbs_data),
                   tbs_hash);

    if (!ecdsa_p256_verify(
            secured.content.signed_data.signer.certificate.public_key,
            tbs_hash,
            secured.content.signed_data.signature)) {
        return V2X_VERIFY_SIGNATURE_INVALID;
    }

    /* Extract payload */
    memcpy(payload, secured.content.signed_data.tbs_data.payload,
           secured.content.signed_data.tbs_data.payload_len);
    *payload_len = secured.content.signed_data.tbs_data.payload_len;

    return V2X_VERIFY_OK;
}
```

## Misbehavior Detection Implementation

```c
/* Plausibility checks for received CAM messages */
typedef struct {
    uint32_t station_id;
    GnssPosition_t last_position;
    float last_speed_mps;
    float last_heading_deg;
    uint32_t last_timestamp_ms;
    uint8_t plausibility_score;  /* 0=untrusted, 255=fully trusted */
    uint8_t misbehavior_count;
} RemoteVehicleTracker_t;

MisbehaviorResult_t check_cam_plausibility(
    const CAM_t* cam,
    RemoteVehicleTracker_t* tracker) {

    MisbehaviorResult_t result = {.is_plausible = true};

    /* Check 1: Position consistency with speed */
    float dt_s = (cam_get_time(cam) - tracker->last_timestamp_ms) / 1000.0f;
    if (dt_s > 0.0f && dt_s < 10.0f) {
        float reported_distance = compute_distance_m(
            &tracker->last_position, &cam_get_position(cam));
        float max_possible_distance = (cam_get_speed(cam) + 5.0f) * dt_s;
        if (reported_distance > max_possible_distance * 1.5f) {
            result.is_plausible = false;
            result.reason = MISBEHAVIOR_POSITION_JUMP;
        }
    }

    /* Check 2: Speed consistency with acceleration */
    float reported_speed_change = fabsf(cam_get_speed(cam) - tracker->last_speed_mps);
    float max_speed_change = 15.0f * dt_s;  /* 15 m/s2 max plausible accel */
    if (reported_speed_change > max_speed_change) {
        result.is_plausible = false;
        result.reason = MISBEHAVIOR_SPEED_JUMP;
    }

    /* Check 3: Position is on or near a road */
    if (!map_is_near_road(cam_get_position(cam), 50.0f)) {
        result.is_plausible = false;
        result.reason = MISBEHAVIOR_OFF_ROAD;
    }

    /* Update tracker */
    tracker->last_position = cam_get_position(cam);
    tracker->last_speed_mps = cam_get_speed(cam);
    tracker->last_heading_deg = cam_get_heading(cam);
    tracker->last_timestamp_ms = cam_get_time(cam);

    if (!result.is_plausible) {
        tracker->misbehavior_count++;
        if (tracker->misbehavior_count > 3) {
            report_misbehavior(tracker->station_id, result.reason);
        }
    } else {
        if (tracker->misbehavior_count > 0) {
            tracker->misbehavior_count--;
        }
    }

    return result;
}
```

## Testing V2X Applications

```python
# V2X simulation test using Python
import pytest
from v2x_simulator import V2xSimulator, Vehicle, TrafficLight

class TestEmergencyBrakeWarning:
    def setup_method(self):
        self.sim = V2xSimulator(frequency_hz=10)

    def test_eebl_transmitted_on_hard_braking(self):
        """Vehicle broadcasts DENM when hard braking detected."""
        ego = self.sim.add_vehicle("ego", position=(0, 0), speed_mps=30)

        # Simulate hard braking
        ego.set_deceleration(-6.0)  # > 4.0 m/s2 threshold
        self.sim.step(10)  # 1 second

        denm_messages = self.sim.get_transmitted_denms("ego")
        assert len(denm_messages) > 0
        assert denm_messages[0].cause == "EMERGENCY_BRAKE"

    def test_eebl_received_triggers_warning(self):
        """Receiving vehicle displays warning when EEBL DENM received."""
        ego = self.sim.add_vehicle("ego", position=(0, 0), speed_mps=25)
        ahead = self.sim.add_vehicle("ahead", position=(100, 0), speed_mps=30)

        ahead.set_deceleration(-7.0)
        self.sim.step(20)

        warnings = ego.get_active_warnings()
        assert any(w.type == "EMERGENCY_BRAKE_AHEAD" for w in warnings)

    def test_cam_rate_increases_during_maneuver(self):
        """CAM generation rate increases during sharp turn."""
        ego = self.sim.add_vehicle("ego", position=(0, 0), speed_mps=15)

        # Drive straight for 2 seconds
        self.sim.step(20)
        cam_count_straight = len(self.sim.get_transmitted_cams("ego"))

        # Sharp right turn
        ego.set_yaw_rate(30.0)  # 30 deg/s
        self.sim.step(20)
        cam_count_turn = len(self.sim.get_transmitted_cams("ego")) - cam_count_straight

        # Should generate more CAMs during turn
        assert cam_count_turn > cam_count_straight
```

## Summary

V2X implementation requires careful attention to message encoding (ASN.1/UPER),
real-time cryptographic operations (ECDSA signing/verification), dynamic
message generation rates, and misbehavior detection. Testing requires
simulation environments that model radio propagation, multi-vehicle
scenarios, and security certificate management.

---
name: automotive-adas
description: >
  Automotive Adas expertise. Covers 7 topics: Adas Features Implementation, Autosar Adas Integration, Camera Processing Vision, Hd Maps Localization, Path Planning Control.
tags: [automotive, automotive-adas]
---

# Automotive Adas

## Adas Features Implementation

# ADAS Features Implementation

## Overview

Concrete implementations of ADAS features: Adaptive Cruise Control (ACC), Lane Keep Assist (LKA), Automatic Emergency Braking (AEB), Blind Spot Detection (BSD), Park Assist, and Traffic Sign Recognition (TSR). Production-ready code for L0-L2+ systems.

## Adaptive Cruise Control (ACC)

### Full ACC Implementation

```cpp
#include <Eigen/Dense>
#include <algorithm>
#include <cmath>

class AdaptiveCruiseControl {
public:
    struct ACCParams {
        double time_gap = 2.0;              // seconds (ISO 22179)
        double min_distance = 5.0;          // meters
        double max_acceleration = 2.0;      // m/s²
        double max_deceleration = -3.0;     // m/s²
        double comfort_decel = -2.0;        // m/s²
        double set_speed = 30.0;            // m/s (108 km/h)
        double speed_tolerance = 2.0;       // m/s
    };

    enum class ACCMode {
        OFF,
        STANDBY,
        ACTIVE_CRUISE,
        ACTIVE_FOLLOWING,
        EMERGENCY_BRAKE
    };

    AdaptiveCruiseControl(const ACCParams& params) : params_(params), mode_(ACCMode::STANDBY) {}

    struct ACCOutput {
        double acceleration;        // Commanded acceleration (m/s²)
        ACCMode mode;
        double target_speed;
        double target_distance;
        bool warning_issued;
    };

    ACCOutput compute(double ego_velocity, double ego_acceleration,
                     const std::vector<DetectedObject>& objects) {
        ACCOutput output;
        output.mode = mode_;
        output.warning_issued = false;

        // Find lead vehicle
        auto lead_vehicle = find_lead_vehicle(objects, ego_velocity);

        if (!lead_vehicle.has_value()) {
            // No lead vehicle - cruise control mode
            output.acceleration = cruise_control(ego_velocity);
            output.target_speed = params_.set_speed;
            output.target_distance = 0.0;
            mode_ = ACCMode::ACTIVE_CRUISE;
        } else {
            // Following mode
            double relative_velocity = ego_velocity - lead_vehicle->velocity;
            double distance = lead_vehicle->distance;
            double desired_distance = calculate_desired_distance(ego_velocity);

            // Calculate acceleration using Intelligent Driver Model (IDM)
            output.acceleration = intelligent_driver_model(
                ego_velocity, distance, relative_velocity, desired_distance
            );

            output.target_speed = lead_vehicle->velocity;
            output.target_distance = desired_distance;

            // Check for emergency
            double ttc = time_to_collision(distance, relative_velocity);
            if (ttc > 0 && ttc < 2.0 && relative_velocity > 0) {
                output.acceleration = params_.max_deceleration;
                output.warning_issued = true;
                mode_ = ACCMode::EMERGENCY_BRAKE;
            } else {
                mode_ = ACCMode::ACTIVE_FOLLOWING;
            }
        }

        // Clamp acceleration
        output.acceleration = std::clamp(output.acceleration,
                                        params_.max_deceleration,
                                        params_.max_acceleration);

        return output;
    }

private:
    ACCParams params_;
    ACCMode mode_;

    struct DetectedObject {
        double distance;   // meters (longitudinal)
        double velocity;   // m/s
        double lateral_offset;  // meters
        std::string object_class;
    };

    std::optional<DetectedObject> find_lead_vehicle(
        const std::vector<DetectedObject>& objects, double ego_velocity)
    {
        std::optional<DetectedObject> lead;
        double min_distance = std::numeric_limits<double>::max();

        for (const auto& obj : objects) {
            // Filter: only consider vehicles in same lane
            if (std::abs(obj.lateral_offset) > 1.5) continue;

            // Filter: only vehicles ahead
            if (obj.distance < 0) continue;

            // Find closest
            if (obj.distance < min_distance) {
                min_distance = obj.distance;
                lead = obj;
            }
        }

        return lead;
    }

    double cruise_control(double ego_velocity) {
        // Simple P controller to reach set speed
        double error = params_.set_speed - ego_velocity;
        double kp = 0.5;
        return std::clamp(kp * error, params_.max_deceleration, params_.max_acceleration);
    }

    double calculate_desired_distance(double ego_velocity) {
        // Time gap policy: d = d_min + v * T
        return params_.min_distance + ego_velocity * params_.time_gap;
    }

    double intelligent_driver_model(double velocity, double distance,
                                    double relative_velocity, double desired_distance) {
        // IDM parameters
        const double a_max = params_.max_acceleration;
        const double b_comfortable = -params_.comfort_decel;
        const double delta = 4.0;  // Acceleration exponent

        // Desired dynamical distance
        double v_approach_term = velocity * relative_velocity / (2 * std::sqrt(a_max * b_comfortable));
        double s_star = params_.min_distance + std::max(0.0, velocity * params_.time_gap + v_approach_term);

        // IDM acceleration
        double accel = a_max * (1.0 - std::pow(velocity / params_.set_speed, delta) -
                               std::pow(s_star / distance, 2.0));

        return accel;
    }

    double time_to_collision(double distance, double relative_velocity) {
        if (relative_velocity <= 0) return -1.0;  // No collision
        return distance / relative_velocity;
    }
};
```

### AUTOSAR ACC Component

```xml
<!-- ACC_SWC.arxml -->
<AUTOSAR>
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>ACC_Application</SHORT-NAME>
      <ELEMENTS>
        <APPLICATION-SW-COMPONENT-TYPE>
          <SHORT-NAME>ACC_SWC</SHORT-NAME>
          <PORTS>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>EgoSpeed</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF>/Interfaces/SpeedInterface</REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>RadarObjects</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF>/Interfaces/ObjectListInterface</REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <P-PORT-PROTOTYPE>
              <SHORT-NAME>AccelRequest</SHORT-NAME>
              <PROVIDED-INTERFACE-TREF>/Interfaces/AccelerationInterface</PROVIDED-INTERFACE-TREF>
            </P-PORT-PROTOTYPE>
            <P-PORT-PROTOTYPE>
              <SHORT-NAME>ACCStatus</SHORT-NAME>
              <PROVIDED-INTERFACE-TREF>/Interfaces/ACCStatusInterface</PROVIDED-INTERFACE-TREF>
            </P-PORT-PROTOTYPE>
          </PORTS>
          <INTERNAL-BEHAVIORS>
            <SWC-INTERNAL-BEHAVIOR>
              <SHORT-NAME>ACC_InternalBehavior</SHORT-NAME>
              <RUNNABLES>
                <RUNNABLE-ENTITY>
                  <SHORT-NAME>ACC_MainFunction</SHORT-NAME>
                  <MINIMUM-START-INTERVAL>0.05</MINIMUM-START-INTERVAL>
                  <CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>
                  <SYMBOL>ACC_MainFunction</SYMBOL>
                </RUNNABLE-ENTITY>
              </RUNNABLES>
            </SWC-INTERNAL-BEHAVIOR>
          </INTERNAL-BEHAVIORS>
        </APPLICATION-SW-COMPONENT-TYPE>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
```

## Lane Keep Assist (LKA)

```cpp
#include <Eigen/Dense>
#include <vector>
#include <cmath>

class LaneKeepAssist {
public:
    struct LKAParams {
        double lookahead_time = 2.0;        // seconds
        double kp_lateral = 0.5;            // Proportional gain
        double ki_lateral = 0.05;           // Integral gain
        double kd_lateral = 0.1;            // Derivative gain
        double max_steering_angle = 0.1;    // radians (~6 degrees)
        double lane_departure_threshold = 0.3;  // meters
    };

    enum class LKAState {
        OFF,
        STANDBY,
        ACTIVE,
        WARNING
    };

    LaneKeepAssist(const LKAParams& params) : params_(params), state_(LKAState::STANDBY) {
        integral_error_ = 0.0;
        previous_error_ = 0.0;
    }

    struct LaneMarkings {
        // Polynomial coefficients: lateral_offset = c0 + c1*x + c2*x^2 + c3*x^3
        Eigen::Vector4d left_lane;
        Eigen::Vector4d right_lane;
        bool left_detected;
        bool right_detected;
        double lane_width;
    };

    struct LKAOutput {
        double steering_torque;  // N⋅m
        LKAState state;
        bool warning_active;
        double lateral_offset;
    };

    LKAOutput compute(const LaneMarkings& lanes, double velocity, double dt) {
        LKAOutput output;
        output.state = state_;
        output.warning_active = false;

        // Check if lanes are detected
        if (!lanes.left_detected && !lanes.right_detected) {
            state_ = LKAState::STANDBY;
            output.steering_torque = 0.0;
            integral_error_ = 0.0;
            return output;
        }

        // Calculate lateral offset from lane center
        double lateral_offset = calculate_lateral_offset(lanes);
        output.lateral_offset = lateral_offset;

        // Calculate lateral error at lookahead distance
        double lookahead_distance = velocity * params_.lookahead_time;
        double lateral_error = calculate_lateral_error(lanes, lookahead_distance);

        // Check for lane departure
        if (std::abs(lateral_offset) > params_.lane_departure_threshold) {
            state_ = LKAState::WARNING;
            output.warning_active = true;
        } else {
            state_ = LKAState::ACTIVE;
        }

        // PID control for steering torque
        integral_error_ += lateral_error * dt;
        double derivative_error = (lateral_error - previous_error_) / dt;

        double steering_correction = params_.kp_lateral * lateral_error +
                                    params_.ki_lateral * integral_error_ +
                                    params_.kd_lateral * derivative_error;

        previous_error_ = lateral_error;

        // Convert to steering torque (simplified model)
        double steering_torque = steering_correction * 10.0;  // N⋅m

        // Limit torque
        const double max_torque = 3.0;  // N⋅m
        steering_torque = std::clamp(steering_torque, -max_torque, max_torque);

        output.steering_torque = steering_torque;

        return output;
    }

private:
    LKAParams params_;
    LKAState state_;
    double integral_error_;
    double previous_error_;

    double calculate_lateral_offset(const LaneMarkings& lanes) {
        // Calculate offset from lane center
        double left_offset = 0.0, right_offset = 0.0;
        int count = 0;

        if (lanes.left_detected) {
            left_offset = lanes.left_lane(0);  // c0 at x=0 (vehicle position)
            count++;
        }

        if (lanes.right_detected) {
            right_offset = lanes.right_lane(0);
            count++;
        }

        if (count == 2) {
            // Both lanes detected - offset from center
            return (left_offset + right_offset) / 2.0;
        } else if (lanes.left_detected) {
            // Only left lane - assume lane width
            return left_offset - lanes.lane_width / 2.0;
        } else {
            // Only right lane
            return right_offset + lanes.lane_width / 2.0;
        }
    }

    double calculate_lateral_error(const LaneMarkings& lanes, double lookahead_distance) {
        // Evaluate polynomial at lookahead distance
        double x = lookahead_distance;
        double left_lateral = 0.0, right_lateral = 0.0;
        int count = 0;

        if (lanes.left_detected) {
            left_lateral = lanes.left_lane(0) + lanes.left_lane(1) * x +
                          lanes.left_lane(2) * x * x + lanes.left_lane(3) * x * x * x;
            count++;
        }

        if (lanes.right_detected) {
            right_lateral = lanes.right_lane(0) + lanes.right_lane(1) * x +
                           lanes.right_lane(2) * x * x + lanes.right_lane(3) * x * x * x;
            count++;
        }

        if (count == 2) {
            return (left_lateral + right_lateral) / 2.0;
        } else if (lanes.left_detected) {
            return left_lateral - lanes.lane_width / 2.0;
        } else {
            return right_lateral + lanes.lane_width / 2.0;
        }
    }
};
```

## Automatic Emergency Braking (AEB)

```cpp
class AutomaticEmergencyBraking {
public:
    struct AEBParams {
        double warning_ttc = 2.5;       // Time to collision for warning (seconds)
        double brake_ttc = 1.5;         // TTC for partial braking
        double emergency_ttc = 0.8;     // TTC for full emergency braking
        double max_brake_pressure = 100.0;  // bar
        double partial_brake_pressure = 30.0;  // bar
    };

    enum class AEBState {
        MONITORING,
        WARNING,
        PARTIAL_BRAKE,
        EMERGENCY_BRAKE
    };

    AutomaticEmergencyBraking(const AEBParams& params) : params_(params) {}

    struct AEBOutput {
        double brake_pressure;  // bar
        AEBState state;
        bool warning_active;
        bool brake_active;
        double ttc;
    };

    AEBOutput compute(const DetectedObject& closest_object, double ego_velocity) {
        AEBOutput output;
        output.brake_pressure = 0.0;
        output.state = AEBState::MONITORING;
        output.warning_active = false;
        output.brake_active = false;
        output.ttc = -1.0;

        if (!closest_object.valid) {
            return output;
        }

        // Calculate time to collision
        double relative_velocity = ego_velocity - closest_object.velocity;
        double ttc = calculate_ttc(closest_object.distance, relative_velocity);
        output.ttc = ttc;

        if (ttc < 0) {
            return output;  // No collision imminent
        }

        // State machine
        if (ttc < params_.emergency_ttc) {
            // Emergency braking
            output.state = AEBState::EMERGENCY_BRAKE;
            output.brake_pressure = params_.max_brake_pressure;
            output.brake_active = true;
            output.warning_active = true;
        } else if (ttc < params_.brake_ttc) {
            // Partial braking
            output.state = AEBState::PARTIAL_BRAKE;
            output.brake_pressure = params_.partial_brake_pressure;
            output.brake_active = true;
            output.warning_active = true;
        } else if (ttc < params_.warning_ttc) {
            // Warning only
            output.state = AEBState::WARNING;
            output.warning_active = true;
        }

        return output;
    }

private:
    AEBParams params_;

    struct DetectedObject {
        double distance;
        double velocity;
        bool valid;
    };

    double calculate_ttc(double distance, double relative_velocity) {
        if (relative_velocity <= 0) return -1.0;
        return distance / relative_velocity;
    }
};
```

## Blind Spot Detection (BSD)

```cpp
class BlindSpotDetection {
public:
    struct BSDParams {
        double blind_spot_min_x = -1.0;     // meters (rear)
        double blind_spot_max_x = 1.0;      // meters (front)
        double blind_spot_min_y = 1.5;      // meters (lateral)
        double blind_spot_max_y = 3.5;      // meters (lateral)
        double warning_velocity_threshold = 2.0;  // m/s (approaching)
    };

    enum class BSDZone {
        NO_DETECTION,
        LEFT_BLIND_SPOT,
        RIGHT_BLIND_SPOT,
        BOTH_BLIND_SPOTS
    };

    BlindSpotDetection(const BSDParams& params) : params_(params) {}

    struct BSDOutput {
        BSDZone zone;
        bool left_warning;
        bool right_warning;
        bool left_approaching;
        bool right_approaching;
    };

    BSDOutput compute(const std::vector<DetectedObject>& objects) {
        BSDOutput output;
        output.zone = BSDZone::NO_DETECTION;
        output.left_warning = false;
        output.right_warning = false;
        output.left_approaching = false;
        output.right_approaching = false;

        for (const auto& obj : objects) {
            // Check if object is in blind spot region
            bool in_longitudinal_range = (obj.x >= params_.blind_spot_min_x &&
                                         obj.x <= params_.blind_spot_max_x);

            bool in_left_blind_spot = (in_longitudinal_range &&
                                      obj.y >= params_.blind_spot_min_y &&
                                      obj.y <= params_.blind_spot_max_y);

            bool in_right_blind_spot = (in_longitudinal_range &&
                                       obj.y >= -params_.blind_spot_max_y &&
                                       obj.y <= -params_.blind_spot_min_y);

            if (in_left_blind_spot) {
                output.left_warning = true;

                // Check if approaching
                if (obj.vx > params_.warning_velocity_threshold) {
                    output.left_approaching = true;
                }
            }

            if (in_right_blind_spot) {
                output.right_warning = true;

                if (obj.vx > params_.warning_velocity_threshold) {
                    output.right_approaching = true;
                }
            }
        }

        // Determine zone
        if (output.left_warning && output.right_warning) {
            output.zone = BSDZone::BOTH_BLIND_SPOTS;
        } else if (output.left_warning) {
            output.zone = BSDZone::LEFT_BLIND_SPOT;
        } else if (output.right_warning) {
            output.zone = BSDZone::RIGHT_BLIND_SPOT;
        }

        return output;
    }

private:
    BSDParams params_;

    struct DetectedObject {
        double x, y;      // Position relative to ego vehicle (meters)
        double vx, vy;    // Velocity relative to ego vehicle (m/s)
    };
};
```

## Parking Assist

```python
import numpy as np
from enum import Enum

class ParkingAssistant:
    """
    Automated parking system for parallel and perpendicular parking
    """

    class ParkingMode(Enum):
        SEARCH = 1
        PLANNING = 2
        EXECUTING = 3
        COMPLETED = 4

    def __init__(self, vehicle_length=4.5, vehicle_width=1.8, wheelbase=2.7):
        self.vehicle_length = vehicle_length
        self.vehicle_width = vehicle_width
        self.wheelbase = wheelbase
        self.mode = self.ParkingMode.SEARCH

        # Minimum parking space dimensions
        self.min_parallel_length = vehicle_length + 1.0  # meters
        self.min_perpendicular_width = vehicle_width + 0.6  # meters

    def detect_parking_space(self, ultrasonic_measurements):
        """
        Detect available parking spaces using ultrasonic sensors

        Args:
            ultrasonic_measurements: List of distances from 12 ultrasonic sensors

        Returns:
            parking_space: Dictionary with space dimensions and type
        """
        # Left side measurements (4 sensors)
        left_front = ultrasonic_measurements[0]
        left_mid_front = ultrasonic_measurements[1]
        left_mid_rear = ultrasonic_measurements[2]
        left_rear = ultrasonic_measurements[3]

        # Detect parallel parking space
        if (left_front > 2.0 and left_mid_front > 2.0 and
            left_mid_rear > 2.0 and left_rear > 2.0):

            # Measure space length
            space_length = self.measure_space_length(ultrasonic_measurements)

            if space_length >= self.min_parallel_length:
                return {
                    'type': 'parallel',
                    'length': space_length,
                    'valid': True
                }

        return {'valid': False}

    def plan_parallel_parking(self, space_length, space_lateral_offset):
        """
        Plan trajectory for parallel parking

        Returns:
            List of waypoints with (x, y, theta, steering_angle)
        """
        waypoints = []

        # Phase 1: Align with parking space
        waypoints.append({
            'x': 0.0,
            'y': 0.0,
            'theta': 0.0,
            'steering': 0.0,
            'velocity': 0.5  # m/s
        })

        # Phase 2: Reverse into space with maximum steering
        max_steering = 0.6  # radians
        reverse_distance = 3.0  # meters

        for i in range(10):
            progress = i / 10.0
            waypoints.append({
                'x': -progress * reverse_distance * np.cos(max_steering),
                'y': space_lateral_offset - progress * reverse_distance * np.sin(max_steering),
                'theta': -progress * max_steering,
                'steering': max_steering,
                'velocity': -0.3  # Reverse slowly
            })

        # Phase 3: Straighten wheels and center in space
        for i in range(5):
            progress = (i + 1) / 5.0
            waypoints.append({
                'x': waypoints[-1]['x'] - 0.3,
                'y': waypoints[-1]['y'],
                'theta': -(1.0 - progress * 0.5) * max_steering,
                'steering': -progress * max_steering,
                'velocity': -0.2
            })

        return waypoints

    def execute_parking(self, current_pose, target_waypoint, dt=0.1):
        """
        Execute parking maneuver using path following controller

        Args:
            current_pose: (x, y, theta) current vehicle pose
            target_waypoint: Dictionary with target pose and steering
            dt: Time step

        Returns:
            control_output: (steering_angle, velocity)
        """
        # Pure pursuit controller for waypoint following
        dx = target_waypoint['x'] - current_pose[0]
        dy = target_waypoint['y'] - current_pose[1]

        # Calculate steering angle
        lookahead_distance = 1.0  # meters
        alpha = np.arctan2(dy, dx) - current_pose[2]

        steering_angle = np.arctan2(2.0 * self.wheelbase * np.sin(alpha),
                                    lookahead_distance)

        # Limit steering angle
        steering_angle = np.clip(steering_angle, -0.6, 0.6)

        velocity = target_waypoint['velocity']

        return (steering_angle, velocity)

    def measure_space_length(self, ultrasonic_measurements):
        """Estimate parking space length from ultrasonic measurements"""
        # Simplified: integrate measurements along vehicle path
        # In production, use more sophisticated SLAM-based approach
        return 5.5  # meters (placeholder)
```

## Traffic Sign Recognition (TSR)

```python
import torch
import torchvision.transforms as transforms
from PIL import Image

class TrafficSignRecognition:
    """
    Traffic sign detection and classification
    """

    def __init__(self, model_path, device='cuda'):
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')

        # Load pretrained model (YOLO + classifier)
        self.detector = torch.hub.load('ultralytics/yolov5', 'custom',
                                      path=model_path, force_reload=False)

        # Sign classes (GTSDB/GTSRB dataset)
        self.sign_classes = {
            0: 'speed_limit_20',
            1: 'speed_limit_30',
            2: 'speed_limit_50',
            3: 'speed_limit_60',
            4: 'speed_limit_70',
            5: 'speed_limit_80',
            6: 'speed_limit_100',
            7: 'speed_limit_120',
            8: 'no_overtaking',
            9: 'no_overtaking_trucks',
            10: 'priority_road',
            11: 'yield',
            12: 'stop',
            13: 'no_entry',
            # ... (43 classes total)
        }

    def detect_and_classify(self, image):
        """
        Detect traffic signs and classify them

        Args:
            image: RGB image (H, W, 3)

        Returns:
            List of detected signs with class, confidence, bbox
        """
        # Run detection
        results = self.detector(image)

        detected_signs = []

        for *box, conf, cls in results.xyxy[0].cpu().numpy():
            sign_id = int(cls)

            if sign_id in self.sign_classes:
                sign = {
                    'class': self.sign_classes[sign_id],
                    'confidence': float(conf),
                    'bbox': box,  # [x1, y1, x2, y2]
                    'sign_id': sign_id
                }

                detected_signs.append(sign)

        return detected_signs

    def extract_speed_limit(self, detected_signs):
        """Extract current speed limit from detected signs"""
        speed_limits = []

        for sign in detected_signs:
            if 'speed_limit' in sign['class']:
                # Extract speed value from class name
                speed_value = int(sign['class'].split('_')[-1])
                speed_limits.append((speed_value, sign['confidence']))

        if speed_limits:
            # Return most confident speed limit
            return max(speed_limits, key=lambda x: x[1])[0]

        return None
```

## HIL Testing Configuration

```python
# Hardware-in-Loop test setup for ADAS features
import can

class ADASHILTester:
    """
    HIL test environment for ADAS features
    """

    def __init__(self, can_interface='can0'):
        self.bus = can.interface.Bus(channel=can_interface, bustype='socketcan')

    def simulate_radar_objects(self, objects):
        """Send simulated radar objects over CAN"""
        for obj in objects:
            # CAN message for radar object (example format)
            data = [
                int(obj['distance'] * 10) & 0xFF,
                (int(obj['distance'] * 10) >> 8) & 0xFF,
                int(obj['velocity'] * 10 + 128) & 0xFF,
                int(obj['lateral_offset'] * 10 + 128) & 0xFF,
                obj['object_id'] & 0xFF,
                0, 0, 0  # Reserved
            ]

            msg = can.Message(arbitration_id=0x500 + obj['object_id'],
                            data=data,
                            is_extended_id=False)

            self.bus.send(msg)

    def read_acc_output(self):
        """Read ACC output from ECU"""
        msg = self.bus.recv(timeout=1.0)

        if msg and msg.arbitration_id == 0x400:
            # Parse ACC command
            accel_request = (msg.data[0] | (msg.data[1] << 8)) / 100.0 - 10.0
            acc_active = bool(msg.data[2] & 0x01)

            return {
                'acceleration': accel_request,
                'active': acc_active
            }

        return None

    def test_acc_scenario(self, scenario_name, test_duration=10.0):
        """Run ACC test scenario"""
        print(f"Running ACC test: {scenario_name}")

        # Load scenario (lead vehicle trajectory)
        scenario = self.load_scenario(scenario_name)

        start_time = time.time()

        while (time.time() - start_time) < test_duration:
            # Simulate radar detections
            timestamp = time.time() - start_time
            objects = scenario.get_objects_at_time(timestamp)

            self.simulate_radar_objects(objects)

            # Read ACC response
            acc_output = self.read_acc_output()

            if acc_output:
                print(f"T={timestamp:.2f}s: ACC accel={acc_output['acceleration']:.2f} m/s²")

            time.sleep(0.05)  # 20 Hz

        print(f"Test {scenario_name} completed")
```

## Performance Metrics

| Feature | Latency | Accuracy | ASIL |
|---------|---------|----------|------|
| **ACC** | < 100ms | TTC error < 5% | ASIL B |
| **LKA** | < 50ms | Lateral error < 10cm | ASIL B |
| **AEB** | < 50ms | False positive < 1% | ASIL D |
| **BSD** | < 100ms | Detection rate > 99% | ASIL A |
| **Parking** | < 200ms | Position error < 5cm | ASIL A |
| **TSR** | < 200ms | Recognition > 95% | QM |

## Standards

- **ISO 22179**: Full-speed ACC
- **ISO 11270**: Lane departure warning
- **Euro NCAP**: AEB testing protocols
- **UN R79**: Steering system requirements (LKA)

## Related Skills

- sensor-fusion-perception.md
- camera-processing-vision.md
- path-planning-control.md

---

## Autosar Adas Integration

# AUTOSAR ADAS Integration

## Overview

AUTOSAR Classic and Adaptive Platform for ADAS, RTE configuration, sensor abstraction, ara::com for distributed ADAS, resource partitioning, timing constraints, and ASIL-D compliance.

## AUTOSAR Classic Platform for ADAS

### Software Component Architecture

```xml
<!-- ADAS_ECU_Extract.arxml -->
<?xml version="1.0" encoding="UTF-8"?>
<AUTOSAR xmlns="http://autosar.org/schema/r4.0">
  <AR-PACKAGES>
    <!-- Application Layer -->
    <AR-PACKAGE>
      <SHORT-NAME>ADAS_Application</SHORT-NAME>
      <ELEMENTS>
        <!-- Sensor Fusion SWC -->
        <APPLICATION-SW-COMPONENT-TYPE>
          <SHORT-NAME>SensorFusion_SWC</SHORT-NAME>
          <PORTS>
            <!-- Input Ports -->
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>CameraData</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/CameraImageInterface
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>RadarData</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/RadarObjectListInterface
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>LidarData</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/LidarPointCloudInterface
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>

            <!-- Output Ports -->
            <P-PORT-PROTOTYPE>
              <SHORT-NAME>FusedObjectList</SHORT-NAME>
              <PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/FusedObjectListInterface
              </PROVIDED-INTERFACE-TREF>
            </P-PORT-PROTOTYPE>
          </PORTS>

          <!-- Internal Behavior -->
          <INTERNAL-BEHAVIORS>
            <SWC-INTERNAL-BEHAVIOR>
              <SHORT-NAME>SensorFusion_InternalBehavior</SHORT-NAME>

              <!-- Runnables -->
              <RUNNABLES>
                <RUNNABLE-ENTITY>
                  <SHORT-NAME>SensorFusion_Init</SHORT-NAME>
                  <MINIMUM-START-INTERVAL>0</MINIMUM-START-INTERVAL>
                  <CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>
                  <SYMBOL>SensorFusion_Init</SYMBOL>
                </RUNNABLE-ENTITY>

                <RUNNABLE-ENTITY>
                  <SHORT-NAME>SensorFusion_MainFunction</SHORT-NAME>
                  <MINIMUM-START-INTERVAL>0.02</MINIMUM-START-INTERVAL>  <!-- 50 Hz -->
                  <CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>
                  <SYMBOL>SensorFusion_MainFunction</SYMBOL>

                  <!-- Data Read Access -->
                  <DATA-RECEIVE-POINT-BY-ARGUMENTS>
                    <VARIABLE-ACCESS>
                      <SHORT-NAME>Read_CameraData</SHORT-NAME>
                      <ACCESSED-VARIABLE>
                        <AUTOSAR-VARIABLE-IREF>
                          <PORT-PROTOTYPE-REF DEST="R-PORT-PROTOTYPE">
                            /ADAS_Application/SensorFusion_SWC/CameraData
                          </PORT-PROTOTYPE-REF>
                          <TARGET-DATA-PROTOTYPE-REF>
                            /Interfaces/CameraImageInterface/ImageData
                          </TARGET-DATA-PROTOTYPE-REF>
                        </AUTOSAR-VARIABLE-IREF>
                      </ACCESSED-VARIABLE>
                    </VARIABLE-ACCESS>
                  </DATA-RECEIVE-POINT-BY-ARGUMENTS>

                  <!-- Data Write Access -->
                  <DATA-SEND-POINTS>
                    <VARIABLE-ACCESS>
                      <SHORT-NAME>Write_FusedObjects</SHORT-NAME>
                      <ACCESSED-VARIABLE>
                        <AUTOSAR-VARIABLE-IREF>
                          <PORT-PROTOTYPE-REF DEST="P-PORT-PROTOTYPE">
                            /ADAS_Application/SensorFusion_SWC/FusedObjectList
                          </PORT-PROTOTYPE-REF>
                          <TARGET-DATA-PROTOTYPE-REF>
                            /Interfaces/FusedObjectListInterface/Objects
                          </TARGET-DATA-PROTOTYPE-REF>
                        </AUTOSAR-VARIABLE-IREF>
                      </ACCESSED-VARIABLE>
                    </VARIABLE-ACCESS>
                  </DATA-SEND-POINTS>
                </RUNNABLE-ENTITY>
              </RUNNABLES>

              <!-- Events -->
              <EVENTS>
                <INIT-EVENT>
                  <SHORT-NAME>InitEvent</SHORT-NAME>
                  <START-ON-EVENT-REF DEST="RUNNABLE-ENTITY">
                    /ADAS_Application/SensorFusion_SWC/SensorFusion_InternalBehavior/SensorFusion_Init
                  </START-ON-EVENT-REF>
                </INIT-EVENT>

                <TIMING-EVENT>
                  <SHORT-NAME>MainFunction_TimingEvent</SHORT-NAME>
                  <START-ON-EVENT-REF DEST="RUNNABLE-ENTITY">
                    /ADAS_Application/SensorFusion_SWC/SensorFusion_InternalBehavior/SensorFusion_MainFunction
                  </START-ON-EVENT-REF>
                  <PERIOD>0.02</PERIOD>  <!-- 50 Hz -->
                </TIMING-EVENT>
              </EVENTS>

            </SWC-INTERNAL-BEHAVIOR>
          </INTERNAL-BEHAVIORS>
        </APPLICATION-SW-COMPONENT-TYPE>

        <!-- Path Planning SWC -->
        <APPLICATION-SW-COMPONENT-TYPE>
          <SHORT-NAME>PathPlanning_SWC</SHORT-NAME>
          <PORTS>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>FusedObjectList</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/FusedObjectListInterface
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>VehicleState</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/VehicleStateInterface
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <P-PORT-PROTOTYPE>
              <SHORT-NAME>TrajectoryOutput</SHORT-NAME>
              <PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/TrajectoryInterface
              </PROVIDED-INTERFACE-TREF>
            </P-PORT-PROTOTYPE>
          </PORTS>
        </APPLICATION-SW-COMPONENT-TYPE>

      </ELEMENTS>
    </AR-PACKAGE>

    <!-- Interface Definitions -->
    <AR-PACKAGE>
      <SHORT-NAME>Interfaces</SHORT-NAME>
      <ELEMENTS>
        <SENDER-RECEIVER-INTERFACE>
          <SHORT-NAME>FusedObjectListInterface</SHORT-NAME>
          <IS-SERVICE>false</IS-SERVICE>
          <DATA-ELEMENTS>
            <VARIABLE-DATA-PROTOTYPE>
              <SHORT-NAME>Objects</SHORT-NAME>
              <TYPE-TREF DEST="IMPLEMENTATION-DATA-TYPE">
                /DataTypes/FusedObjectArray
              </TYPE-TREF>
            </VARIABLE-DATA-PROTOTYPE>
          </DATA-ELEMENTS>
        </SENDER-RECEIVER-INTERFACE>
      </ELEMENTS>
    </AR-PACKAGE>

    <!-- Data Type Definitions -->
    <AR-PACKAGE>
      <SHORT-NAME>DataTypes</SHORT-NAME>
      <ELEMENTS>
        <IMPLEMENTATION-DATA-TYPE>
          <SHORT-NAME>FusedObjectArray</SHORT-NAME>
          <CATEGORY>ARRAY</CATEGORY>
          <SUB-ELEMENTS>
            <IMPLEMENTATION-DATA-TYPE-ELEMENT>
              <SHORT-NAME>Object</SHORT-NAME>
              <CATEGORY>TYPE_REFERENCE</CATEGORY>
              <ARRAY-SIZE>50</ARRAY-SIZE>
              <ARRAY-SIZE-SEMANTICS>FIXED-SIZE</ARRAY-SIZE-SEMANTICS>
              <SW-DATA-DEF-PROPS>
                <SW-DATA-DEF-PROPS-VARIANTS>
                  <SW-DATA-DEF-PROPS-CONDITIONAL>
                    <IMPLEMENTATION-DATA-TYPE-REF DEST="IMPLEMENTATION-DATA-TYPE">
                      /DataTypes/FusedObject
                    </IMPLEMENTATION-DATA-TYPE-REF>
                  </SW-DATA-DEF-PROPS-CONDITIONAL>
                </SW-DATA-DEF-PROPS-VARIANTS>
              </SW-DATA-DEF-PROPS>
            </IMPLEMENTATION-DATA-TYPE-ELEMENT>
          </SUB-ELEMENTS>
        </IMPLEMENTATION-DATA-TYPE>

        <IMPLEMENTATION-DATA-TYPE>
          <SHORT-NAME>FusedObject</SHORT-NAME>
          <CATEGORY>STRUCTURE</CATEGORY>
          <SUB-ELEMENTS>
            <IMPLEMENTATION-DATA-TYPE-ELEMENT>
              <SHORT-NAME>id</SHORT-NAME>
              <CATEGORY>VALUE</CATEGORY>
              <SW-DATA-DEF-PROPS>
                <SW-DATA-DEF-PROPS-VARIANTS>
                  <SW-DATA-DEF-PROPS-CONDITIONAL>
                    <BASE-TYPE-REF DEST="SW-BASE-TYPE">/BaseTypes/uint32</BASE-TYPE-REF>
                  </SW-DATA-DEF-PROPS-CONDITIONAL>
                </SW-DATA-DEF-PROPS-VARIANTS>
              </SW-DATA-DEF-PROPS>
            </IMPLEMENTATION-DATA-TYPE-ELEMENT>
            <IMPLEMENTATION-DATA-TYPE-ELEMENT>
              <SHORT-NAME>position_x</SHORT-NAME>
              <CATEGORY>VALUE</CATEGORY>
              <SW-DATA-DEF-PROPS>
                <SW-DATA-DEF-PROPS-VARIANTS>
                  <SW-DATA-DEF-PROPS-CONDITIONAL>
                    <BASE-TYPE-REF DEST="SW-BASE-TYPE">/BaseTypes/float32</BASE-TYPE-REF>
                  </SW-DATA-DEF-PROPS-CONDITIONAL>
                </SW-DATA-DEF-PROPS-VARIANTS>
              </SW-DATA-DEF-PROPS>
            </IMPLEMENTATION-DATA-TYPE-ELEMENT>
            <IMPLEMENTATION-DATA-TYPE-ELEMENT>
              <SHORT-NAME>position_y</SHORT-NAME>
              <CATEGORY>VALUE</CATEGORY>
            </IMPLEMENTATION-DATA-TYPE-ELEMENT>
            <IMPLEMENTATION-DATA-TYPE-ELEMENT>
              <SHORT-NAME>velocity_x</SHORT-NAME>
              <CATEGORY>VALUE</CATEGORY>
            </IMPLEMENTATION-DATA-TYPE-ELEMENT>
            <IMPLEMENTATION-DATA-TYPE-ELEMENT>
              <SHORT-NAME>velocity_y</SHORT-NAME>
              <CATEGORY>VALUE</CATEGORY>
            </IMPLEMENTATION-DATA-TYPE-ELEMENT>
            <IMPLEMENTATION-DATA-TYPE-ELEMENT>
              <SHORT-NAME>object_class</SHORT-NAME>
              <CATEGORY>VALUE</CATEGORY>
              <SW-DATA-DEF-PROPS>
                <SW-DATA-DEF-PROPS-VARIANTS>
                  <SW-DATA-DEF-PROPS-CONDITIONAL>
                    <BASE-TYPE-REF DEST="SW-BASE-TYPE">/BaseTypes/uint8</BASE-TYPE-REF>
                  </SW-DATA-DEF-PROPS-CONDITIONAL>
                </SW-DATA-DEF-PROPS-VARIANTS>
              </SW-DATA-DEF-PROPS>
            </IMPLEMENTATION-DATA-TYPE-ELEMENT>
          </SUB-ELEMENTS>
        </IMPLEMENTATION-DATA-TYPE>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
```

### RTE Generated Code

```c
/* Rte_SensorFusion.h - Generated by RTE Generator */

#ifndef RTE_SENSORFUSION_H
#define RTE_SENSORFUSION_H

#include "Rte_Type.h"

/* API Functions */
FUNC(Std_ReturnType, RTE_CODE) Rte_Read_SensorFusion_CameraData_ImageData(
    P2VAR(CameraImage_Type, AUTOMATIC, RTE_APPL_DATA) data
);

FUNC(Std_ReturnType, RTE_CODE) Rte_Read_SensorFusion_RadarData_Objects(
    P2VAR(RadarObjectList_Type, AUTOMATIC, RTE_APPL_DATA) data
);

FUNC(Std_ReturnType, RTE_CODE) Rte_Write_SensorFusion_FusedObjectList_Objects(
    P2CONST(FusedObjectArray_Type, AUTOMATIC, RTE_APPL_CONST) data
);

/* Runnable Entity Prototypes */
FUNC(void, RTE_CODE) SensorFusion_Init(void);
FUNC(void, RTE_CODE) SensorFusion_MainFunction(void);

#endif /* RTE_SENSORFUSION_H */
```

### Application Implementation

```c
/* SensorFusion.c - Application Implementation */

#include "Rte_SensorFusion.h"
#include "SensorFusion_Internal.h"

static FusionState_Type fusionState;

void SensorFusion_Init(void) {
    /* Initialize fusion algorithms */
    InitKalmanFilters(&fusionState);
    InitDataAssociation(&fusionState);
}

void SensorFusion_MainFunction(void) {
    CameraImage_Type cameraData;
    RadarObjectList_Type radarData;
    LidarPointCloud_Type lidarData;
    FusedObjectArray_Type fusedObjects;

    /* Read sensor inputs via RTE */
    Std_ReturnType ret_camera = Rte_Read_SensorFusion_CameraData_ImageData(&cameraData);
    Std_ReturnType ret_radar = Rte_Read_SensorFusion_RadarData_Objects(&radarData);
    Std_ReturnType ret_lidar = Rte_Read_SensorFusion_LidarData_PointCloud(&lidarData);

    if ((ret_camera == RTE_E_OK) && (ret_radar == RTE_E_OK) && (ret_lidar == RTE_E_OK)) {
        /* Perform sensor fusion */
        ProcessCameraDetections(&cameraData, &fusionState);
        ProcessRadarDetections(&radarData, &fusionState);
        ProcessLidarDetections(&lidarData, &fusionState);

        /* Run fusion algorithm (EKF) */
        UpdateKalmanFilters(&fusionState);

        /* Data association */
        PerformDataAssociation(&fusionState);

        /* Generate fused object list */
        GenerateFusedObjectList(&fusionState, &fusedObjects);

        /* Write output via RTE */
        Rte_Write_SensorFusion_FusedObjectList_Objects(&fusedObjects);
    }
}
```

## AUTOSAR Adaptive Platform for ADAS

### Service-Oriented Architecture

```cpp
// ara::com service interface definition
// SensorFusion.arxml service interface

#include <ara/com/types.h>
#include <ara/core/future.h>
#include <ara/core/result.h>

namespace adas {
namespace sensorfusion {

struct FusedObject {
    uint32_t id;
    float position_x;
    float position_y;
    float velocity_x;
    float velocity_y;
    uint8_t object_class;
    float confidence;
};

using FusedObjectList = std::vector<FusedObject>;

class SensorFusionServiceInterface {
public:
    virtual ~SensorFusionServiceInterface() = default;

    // Events (publisher-subscriber)
    virtual ara::com::EventPtr<FusedObjectList> GetFusedObjectListEvent() = 0;

    // Methods (request-response)
    virtual ara::core::Future<ara::core::Result<bool>> StartFusion() = 0;
    virtual ara::core::Future<ara::core::Result<bool>> StopFusion() = 0;

    // Fields (getter/setter with notification)
    virtual ara::com::FieldPtr<uint32_t> GetFusionStatusField() = 0;
};

}} // namespace adas::sensorfusion
```

### Service Implementation (Provider)

```cpp
// SensorFusionServiceImpl.cpp

#include "SensorFusionServiceInterface.h"
#include <ara/com/instance_identifier.h>
#include <ara/core/instance_specifier.h>

namespace adas {
namespace sensorfusion {

class SensorFusionServiceImpl : public SensorFusionServiceInterface {
public:
    SensorFusionServiceImpl() {
        // Initialize service skeleton
        ara::core::InstanceSpecifier instance("ADAS/SensorFusion/Instance1");
        skeleton_ = std::make_unique<SensorFusionSkeleton>(instance);

        // Offer service
        skeleton_->OfferService();
    }

    ~SensorFusionServiceImpl() {
        skeleton_->StopOfferService();
    }

    ara::com::EventPtr<FusedObjectList> GetFusedObjectListEvent() override {
        return skeleton_->fusedObjectList;
    }

    ara::core::Future<ara::core::Result<bool>> StartFusion() override {
        // Start fusion processing
        fusion_active_ = true;
        return ara::core::MakeReadyFuture<ara::core::Result<bool>>(true);
    }

    ara::core::Future<ara::core::Result<bool>> StopFusion() override {
        fusion_active_ = false;
        return ara::core::MakeReadyFuture<ara::core::Result<bool>>(true);
    }

    ara::com::FieldPtr<uint32_t> GetFusionStatusField() override {
        return skeleton_->fusionStatus;
    }

    // Main processing function
    void ProcessSensorData() {
        if (!fusion_active_) return;

        // Perform fusion
        FusedObjectList fusedObjects = PerformFusion();

        // Publish event
        skeleton_->fusedObjectList.Send(fusedObjects);

        // Update status field
        skeleton_->fusionStatus.Set(1);  // 1 = Active
    }

private:
    std::unique_ptr<SensorFusionSkeleton> skeleton_;
    bool fusion_active_ = false;

    FusedObjectList PerformFusion() {
        // Fusion logic here
        FusedObjectList objects;
        // ...
        return objects;
    }
};

}} // namespace adas::sensorfusion
```

### Service Consumer (Proxy)

```cpp
// PathPlanningApp.cpp - Consumer of SensorFusion service

#include "SensorFusionServiceInterface.h"
#include <ara/com/service_proxy_factory.h>
#include <ara/core/instance_specifier.h>

class PathPlanningApp {
public:
    PathPlanningApp() {
        // Find and connect to service
        ara::core::InstanceSpecifier instance("ADAS/SensorFusion/Instance1");

        auto handles = SensorFusionProxy::FindService(instance);

        if (!handles.empty()) {
            proxy_ = std::make_unique<SensorFusionProxy>(handles[0]);

            // Subscribe to fused object list
            proxy_->GetFusedObjectListEvent().Subscribe(1);  // Queue size = 1
            proxy_->GetFusedObjectListEvent().SetReceiveHandler(
                [this](const FusedObjectList& objects) {
                    HandleFusedObjects(objects);
                }
            );
        }
    }

    void HandleFusedObjects(const FusedObjectList& objects) {
        // Use fused objects for path planning
        PlanPath(objects);
    }

    void PlanPath(const FusedObjectList& objects) {
        // Path planning logic
    }

private:
    std::unique_ptr<SensorFusionProxy> proxy_;
};
```

## Resource Partitioning & Timing

### Timing Configuration

```xml
<!-- Timing_Config.arxml -->
<AUTOSAR>
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>Timing</SHORT-NAME>
      <ELEMENTS>
        <!-- Task Configuration -->
        <OS-TASK>
          <SHORT-NAME>SensorFusion_Task</SHORT-NAME>
          <PRIORITY>10</PRIORITY>  <!-- High priority -->
          <SCHEDULE>FULL</SCHEDULE>
          <ACTIVATION>1</ACTIVATION>
          <AUTOSTART>true</AUTOSTART>
          <TIMING-PROTECTION>
            <EXECUTION-TIME>
              <VALUE>0.015</VALUE>  <!-- 15ms WCET -->
            </EXECUTION-TIME>
            <TIME-FRAME>
              <VALUE>0.020</VALUE>  <!-- 20ms period -->
            </TIME-FRAME>
          </TIMING-PROTECTION>
        </OS-TASK>

        <OS-TASK>
          <SHORT-NAME>PathPlanning_Task</SHORT-NAME>
          <PRIORITY>8</PRIORITY>
          <SCHEDULE>FULL</SCHEDULE>
          <TIMING-PROTECTION>
            <EXECUTION-TIME>
              <VALUE>0.045</VALUE>  <!-- 45ms WCET -->
            </EXECUTION-TIME>
            <TIME-FRAME>
              <VALUE>0.050</VALUE>  <!-- 50ms period -->
            </TIME-FRAME>
          </TIMING-PROTECTION>
        </OS-TASK>

        <!-- Alarm for periodic activation -->
        <OS-ALARM>
          <SHORT-NAME>SensorFusion_Alarm</SHORT-NAME>
          <COUNTER-REF DEST="OS-COUNTER">/Timing/SystemCounter</COUNTER-REF>
          <ALARM-ACTION>
            <OS-ALARM-ACTIVATE-TASK-ACTION>
              <TASK-REF DEST="OS-TASK">/Timing/SensorFusion_Task</TASK-REF>
            </OS-ALARM-ACTIVATE-TASK-ACTION>
          </ALARM-ACTION>
          <AUTOSTART-ALARM>
            <AUTOSTART-ALARM-REF DEST="AUTOSTART">/Timing/Autostart</AUTOSTART-ALARM-REF>
            <ALARM-TIME>20</ALARM-TIME>  <!-- 20ms -->
            <CYCLE-TIME>20</CYCLE-TIME>
          </AUTOSTART-ALARM>
        </OS-ALARM>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
```

### Memory Protection

```xml
<!-- Memory_Partition.arxml -->
<AUTOSAR>
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>MemoryPartitioning</SHORT-NAME>
      <ELEMENTS>
        <OS-APPLICATION>
          <SHORT-NAME>ADAS_Application</SHORT-NAME>
          <TRUSTED>true</TRUSTED>
          <MEMORY-SECTIONS>
            <OS-APPLICATION-MEMORY-SECTION>
              <SHORT-NAME>ADAS_RAM</SHORT-NAME>
              <SIZE>0x100000</SIZE>  <!-- 1MB -->
              <ALIGNMENT>4</ALIGNMENT>
              <BASE-ADDRESS>0x40000000</BASE-ADDRESS>
            </OS-APPLICATION-MEMORY-SECTION>
          </MEMORY-SECTIONS>
        </OS-APPLICATION>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
```

## Safety (ASIL-D) Configuration

### Safety Mechanisms

```c
/* Safety Monitor for ADAS Functions */

#define ADAS_SAFETY_TIMEOUT_MS 100
#define ADAS_PLAUSIBILITY_THRESHOLD 0.5

typedef enum {
    SAFETY_STATE_NORMAL,
    SAFETY_STATE_DEGRADED,
    SAFETY_STATE_SAFE_STOP
} SafetyState_Type;

typedef struct {
    uint32_t timestamp_ms;
    boolean sensor_fusion_alive;
    boolean path_planning_alive;
    boolean control_alive;
    SafetyState_Type state;
} SafetyMonitor_Type;

void SafetyMonitor_Check(SafetyMonitor_Type* monitor) {
    uint32_t current_time = GetSystemTime_ms();

    /* Check aliveness */
    if ((current_time - monitor->timestamp_ms) > ADAS_SAFETY_TIMEOUT_MS) {
        monitor->state = SAFETY_STATE_SAFE_STOP;
        TriggerSafeMechanism();
    }

    /* Plausibility checks */
    if (!CheckSensorFusionPlausibility()) {
        monitor->state = SAFETY_STATE_DEGRADED;
    }
}

void SafetyMonitor_UpdateAlive(SafetyMonitor_Type* monitor, ADASComponent_Type component) {
    switch (component) {
        case COMPONENT_SENSOR_FUSION:
            monitor->sensor_fusion_alive = TRUE;
            break;
        case COMPONENT_PATH_PLANNING:
            monitor->path_planning_alive = TRUE;
            break;
        case COMPONENT_CONTROL:
            monitor->control_alive = TRUE;
            break;
    }

    monitor->timestamp_ms = GetSystemTime_ms();
}
```

## Performance Requirements

| Component | WCET | Period | Latency | ASIL |
|-----------|------|--------|---------|------|
| **Sensor Fusion** | 15ms | 20ms | < 50ms | ASIL D |
| **Path Planning** | 45ms | 50ms | < 100ms | ASIL D |
| **Control** | 5ms | 10ms | < 20ms | ASIL D |
| **Diagnostics** | 20ms | 100ms | N/A | ASIL B |

## Standards

- **AUTOSAR Classic R4.x**: Foundation for ADAS ECUs
- **AUTOSAR Adaptive R19-11**: High-performance computing platforms
- **ISO 26262**: ASIL D for safety-critical functions
- **ISO 17356 (AUTOSAR)**: Integration standard

## Related Skills

- sensor-fusion-perception.md
- adas-features-implementation.md
- path-planning-control.md

---

## Camera Processing Vision

# Camera Processing & Computer Vision for ADAS

## Overview

Camera-based perception for ADAS including lane detection, object detection, semantic segmentation, depth estimation, and ISP tuning. Covers classical computer vision (Hough transform, edge detection) and deep learning approaches (YOLO, SSD, Faster R-CNN, semantic segmentation networks).

## Camera Hardware Architecture

### Typical ADAS Camera Setup

```
Multi-Camera System (ADAS L2-L5)
────────────────────────────────────────

Front View:
  - Wide FOV (120°): Pedestrian detection, lane keeping
  - Tele FOV (30°): Long-range object detection (up to 200m)
  - Fisheye (180°+): Parking assistance

Surround View (360°):
  - Front fisheye: 190° FOV
  - Rear fisheye: 190° FOV
  - Left/Right fisheye: 190° FOV each

Specifications:
  - Resolution: 1280x960 to 3840x2160 (1-8MP)
  - Frame Rate: 30-60 FPS
  - Dynamic Range: 100-120 dB HDR
  - Interface: MIPI CSI-2, GMSL2, FPD-Link III
  - ISP: Hardware accelerated (denoise, HDR, lens correction)
```

## Lane Detection

### Classical Approach: Hough Transform

```python
import cv2
import numpy as np

class LaneDetector:
    """
    Classical lane detection using edge detection and Hough transform
    """

    def __init__(self):
        # Canny edge detection parameters
        self.canny_low = 50
        self.canny_high = 150

        # Hough transform parameters
        self.rho = 1              # Distance resolution (pixels)
        self.theta = np.pi/180    # Angular resolution (radians)
        self.threshold = 50       # Min intersections to detect line
        self.min_line_length = 100
        self.max_line_gap = 50

        # ROI vertices (trapezoid)
        self.roi_vertices = None

    def detect_lanes(self, image):
        """
        Detect lane lines in image

        Args:
            image: RGB image (H, W, 3)

        Returns:
            lane_image: Image with detected lanes drawn
            lane_lines: List of detected lane line parameters
        """
        # 1. Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)

        # 2. Apply Gaussian blur
        blur = cv2.GaussianBlur(gray, (5, 5), 0)

        # 3. Edge detection
        edges = cv2.Canny(blur, self.canny_low, self.canny_high)

        # 4. Apply ROI mask
        masked_edges = self.apply_roi(edges, image.shape)

        # 5. Hough line detection
        lines = cv2.HoughLinesP(
            masked_edges,
            self.rho,
            self.theta,
            self.threshold,
            minLineLength=self.min_line_length,
            maxLineGap=self.max_line_gap
        )

        # 6. Filter and cluster lines into left/right lanes
        left_lane, right_lane = self.separate_lanes(lines, image.shape)

        # 7. Fit polynomial to lane points
        lane_lines = self.fit_lane_polynomials(left_lane, right_lane)

        # 8. Draw lanes on image
        lane_image = self.draw_lanes(image, lane_lines)

        return lane_image, lane_lines

    def apply_roi(self, edges, image_shape):
        """Apply region of interest mask"""
        height, width = image_shape[:2]

        # Define trapezoid ROI
        vertices = np.array([[
            (width * 0.1, height),
            (width * 0.4, height * 0.6),
            (width * 0.6, height * 0.6),
            (width * 0.9, height)
        ]], dtype=np.int32)

        mask = np.zeros_like(edges)
        cv2.fillPoly(mask, vertices, 255)

        masked = cv2.bitwise_and(edges, mask)
        return masked

    def separate_lanes(self, lines, image_shape):
        """Separate left and right lane lines based on slope"""
        if lines is None:
            return [], []

        height, width = image_shape[:2]
        left_lines = []
        right_lines = []

        for line in lines:
            x1, y1, x2, y2 = line[0]

            # Calculate slope
            if x2 - x1 == 0:
                continue
            slope = (y2 - y1) / (x2 - x1)

            # Filter by slope
            if slope < -0.5:  # Left lane (negative slope)
                left_lines.append(line[0])
            elif slope > 0.5:  # Right lane (positive slope)
                right_lines.append(line[0])

        return left_lines, right_lines

    def fit_lane_polynomials(self, left_lines, right_lines):
        """Fit polynomial curves to lane line points"""
        def fit_poly(lines):
            if not lines:
                return None

            # Extract all points
            points = []
            for x1, y1, x2, y2 in lines:
                points.extend([(x1, y1), (x2, y2)])

            if len(points) < 2:
                return None

            # Convert to numpy arrays
            points = np.array(points)
            x = points[:, 0]
            y = points[:, 1]

            # Fit 2nd order polynomial
            poly_coeffs = np.polyfit(y, x, 2)
            return poly_coeffs

        left_poly = fit_poly(left_lines)
        right_poly = fit_poly(right_lines)

        return {"left": left_poly, "right": right_poly}

    def draw_lanes(self, image, lane_lines):
        """Draw detected lanes on image"""
        lane_image = np.copy(image)
        height = image.shape[0]

        # Y coordinates for drawing
        y_vals = np.linspace(height * 0.6, height, 100)

        # Draw left lane
        if lane_lines["left"] is not None:
            left_poly = lane_lines["left"]
            left_x = np.polyval(left_poly, y_vals).astype(int)
            left_points = np.array([np.column_stack((left_x, y_vals.astype(int)))])
            cv2.polylines(lane_image, left_points, False, (255, 0, 0), 5)

        # Draw right lane
        if lane_lines["right"] is not None:
            right_poly = lane_lines["right"]
            right_x = np.polyval(right_poly, y_vals).astype(int)
            right_points = np.array([np.column_stack((right_x, y_vals.astype(int)))])
            cv2.polylines(lane_image, right_points, False, (0, 0, 255), 5)

        return lane_image
```

### Deep Learning Approach: Lane Segmentation

```python
import torch
import torch.nn as nn
import torchvision.transforms as transforms

class LaneSegmentationNet(nn.Module):
    """
    U-Net style architecture for lane segmentation
    """

    def __init__(self, in_channels=3, num_classes=2):
        super(LaneSegmentationNet, self).__init__()

        # Encoder (downsampling)
        self.enc1 = self.conv_block(in_channels, 64)
        self.enc2 = self.conv_block(64, 128)
        self.enc3 = self.conv_block(128, 256)
        self.enc4 = self.conv_block(256, 512)

        # Bottleneck
        self.bottleneck = self.conv_block(512, 1024)

        # Decoder (upsampling)
        self.upconv4 = nn.ConvTranspose2d(1024, 512, 2, stride=2)
        self.dec4 = self.conv_block(1024, 512)

        self.upconv3 = nn.ConvTranspose2d(512, 256, 2, stride=2)
        self.dec3 = self.conv_block(512, 256)

        self.upconv2 = nn.ConvTranspose2d(256, 128, 2, stride=2)
        self.dec2 = self.conv_block(256, 128)

        self.upconv1 = nn.ConvTranspose2d(128, 64, 2, stride=2)
        self.dec1 = self.conv_block(128, 64)

        # Output
        self.out = nn.Conv2d(64, num_classes, 1)

        self.pool = nn.MaxPool2d(2, 2)

    def conv_block(self, in_ch, out_ch):
        return nn.Sequential(
            nn.Conv2d(in_ch, out_ch, 3, padding=1),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_ch, out_ch, 3, padding=1),
            nn.BatchNorm2d(out_ch),
            nn.ReLU(inplace=True)
        )

    def forward(self, x):
        # Encoder
        enc1 = self.enc1(x)
        enc2 = self.enc2(self.pool(enc1))
        enc3 = self.enc3(self.pool(enc2))
        enc4 = self.enc4(self.pool(enc3))

        # Bottleneck
        bottleneck = self.bottleneck(self.pool(enc4))

        # Decoder with skip connections
        dec4 = self.upconv4(bottleneck)
        dec4 = torch.cat([dec4, enc4], dim=1)
        dec4 = self.dec4(dec4)

        dec3 = self.upconv3(dec4)
        dec3 = torch.cat([dec3, enc3], dim=1)
        dec3 = self.dec3(dec3)

        dec2 = self.upconv2(dec3)
        dec2 = torch.cat([dec2, enc2], dim=1)
        dec2 = self.dec2(dec2)

        dec1 = self.upconv1(dec2)
        dec1 = torch.cat([dec1, enc1], dim=1)
        dec1 = self.dec1(dec1)

        return self.out(dec1)


class DeepLaneDetector:
    """
    Deep learning-based lane detection
    """

    def __init__(self, model_path, device='cuda'):
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        self.model = LaneSegmentationNet().to(self.device)
        self.model.load_state_dict(torch.load(model_path, map_location=self.device))
        self.model.eval()

        self.transform = transforms.Compose([
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406],
                               std=[0.229, 0.224, 0.225])
        ])

    def detect(self, image):
        """
        Detect lanes using deep learning

        Args:
            image: RGB image (H, W, 3) numpy array

        Returns:
            lane_mask: Binary mask (H, W) with lane pixels
            lane_lines: Fitted polynomial lane lines
        """
        # Preprocess
        input_tensor = self.transform(image).unsqueeze(0).to(self.device)

        # Inference
        with torch.no_grad():
            output = self.model(input_tensor)
            pred = torch.argmax(output, dim=1).squeeze().cpu().numpy()

        # Post-process: fit polynomials to predicted lane pixels
        lane_lines = self.fit_lanes_from_mask(pred)

        return pred, lane_lines

    def fit_lanes_from_mask(self, lane_mask):
        """Fit polynomial curves to segmented lane mask"""
        height, width = lane_mask.shape

        # Find lane pixels
        lane_pixels = np.where(lane_mask > 0)
        y_coords = lane_pixels[0]
        x_coords = lane_pixels[1]

        if len(y_coords) < 10:
            return {"left": None, "right": None}

        # Separate left and right lanes based on x position
        midpoint = width // 2
        left_mask = x_coords < midpoint
        right_mask = x_coords >= midpoint

        left_x = x_coords[left_mask]
        left_y = y_coords[left_mask]
        right_x = x_coords[right_mask]
        right_y = y_coords[right_mask]

        # Fit polynomials
        left_poly = np.polyfit(left_y, left_x, 2) if len(left_y) > 10 else None
        right_poly = np.polyfit(right_y, right_x, 2) if len(right_y) > 10 else None

        return {"left": left_poly, "right": right_poly}
```

## Object Detection

### YOLO v5 for Real-Time Object Detection

```python
import torch
import cv2
import numpy as np

class YOLOv5Detector:
    """
    YOLO v5 object detector optimized for automotive applications
    """

    def __init__(self, model_path='yolov5s.pt', conf_thresh=0.5, iou_thresh=0.45):
        self.model = torch.hub.load('ultralytics/yolov5', 'custom',
                                    path=model_path, force_reload=False)
        self.model.conf = conf_thresh
        self.model.iou = iou_thresh

        # COCO class names relevant for ADAS
        self.classes_of_interest = [
            'person', 'bicycle', 'car', 'motorcycle', 'bus', 'truck',
            'traffic light', 'stop sign'
        ]

    def detect(self, image):
        """
        Detect objects in image

        Args:
            image: RGB image (H, W, 3)

        Returns:
            detections: List of Detection objects
        """
        # Run inference
        results = self.model(image)

        # Parse results
        detections = []
        for *box, conf, cls in results.xyxy[0].cpu().numpy():
            class_name = self.model.names[int(cls)]

            # Filter for ADAS-relevant objects
            if class_name in self.classes_of_interest:
                detection = {
                    'bbox': box,  # [x1, y1, x2, y2]
                    'confidence': conf,
                    'class': class_name,
                    'class_id': int(cls)
                }
                detections.append(detection)

        return detections

    def detect_with_tracking(self, image, prev_detections=None):
        """
        Detect and track objects using simple IOU matching
        """
        current_detections = self.detect(image)

        if prev_detections is None:
            # Initialize track IDs
            for i, det in enumerate(current_detections):
                det['track_id'] = i
            return current_detections

        # Match current detections with previous using IOU
        matched, unmatched_current, unmatched_prev = self.match_detections(
            current_detections, prev_detections
        )

        # Update track IDs
        next_track_id = max([d['track_id'] for d in prev_detections]) + 1

        for curr_idx, prev_idx in matched:
            current_detections[curr_idx]['track_id'] = \
                prev_detections[prev_idx]['track_id']

        for curr_idx in unmatched_current:
            current_detections[curr_idx]['track_id'] = next_track_id
            next_track_id += 1

        return current_detections

    def match_detections(self, current, previous, iou_thresh=0.3):
        """Match detections using IOU"""
        if not current or not previous:
            return [], list(range(len(current))), list(range(len(previous)))

        # Compute IOU matrix
        iou_matrix = np.zeros((len(current), len(previous)))
        for i, curr_det in enumerate(current):
            for j, prev_det in enumerate(previous):
                if curr_det['class'] == prev_det['class']:
                    iou_matrix[i, j] = self.compute_iou(
                        curr_det['bbox'], prev_det['bbox']
                    )

        # Hungarian algorithm for matching (greedy approximation)
        matched = []
        unmatched_current = list(range(len(current)))
        unmatched_prev = list(range(len(previous)))

        while iou_matrix.size > 0:
            max_iou = iou_matrix.max()
            if max_iou < iou_thresh:
                break

            curr_idx, prev_idx = np.unravel_index(iou_matrix.argmax(),
                                                  iou_matrix.shape)
            matched.append((curr_idx, prev_idx))

            unmatched_current.remove(curr_idx)
            unmatched_prev.remove(prev_idx)

            # Remove matched from matrix
            iou_matrix[curr_idx, :] = 0
            iou_matrix[:, prev_idx] = 0

        return matched, unmatched_current, unmatched_prev

    def compute_iou(self, box1, box2):
        """Compute IOU between two bounding boxes"""
        x1_min, y1_min, x1_max, y1_max = box1
        x2_min, y2_min, x2_max, y2_max = box2

        # Intersection area
        inter_xmin = max(x1_min, x2_min)
        inter_ymin = max(y1_min, y2_min)
        inter_xmax = min(x1_max, x2_max)
        inter_ymax = min(y1_max, y2_max)

        inter_area = max(0, inter_xmax - inter_xmin) * \
                    max(0, inter_ymax - inter_ymin)

        # Union area
        box1_area = (x1_max - x1_min) * (y1_max - y1_min)
        box2_area = (x2_max - x2_min) * (y2_max - y2_min)
        union_area = box1_area + box2_area - inter_area

        return inter_area / union_area if union_area > 0 else 0
```

## Semantic Segmentation

```python
import torch
import torch.nn as nn
from torchvision.models.segmentation import deeplabv3_resnet50

class SemanticSegmentor:
    """
    Semantic segmentation for ADAS scene understanding
    """

    def __init__(self, model_path=None, num_classes=19, device='cuda'):
        """
        Args:
            num_classes: Number of classes (Cityscapes: 19 classes)
                0: road, 1: sidewalk, 2: building, 3: wall, 4: fence,
                5: pole, 6: traffic light, 7: traffic sign, 8: vegetation,
                9: terrain, 10: sky, 11: person, 12: rider, 13: car,
                14: truck, 15: bus, 16: train, 17: motorcycle, 18: bicycle
        """
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        self.num_classes = num_classes

        # Load pretrained DeepLabV3
        self.model = deeplabv3_resnet50(pretrained=True)
        self.model.classifier[4] = nn.Conv2d(256, num_classes, kernel_size=1)

        if model_path:
            self.model.load_state_dict(torch.load(model_path,
                                                  map_location=self.device))

        self.model.to(self.device)
        self.model.eval()

        # Class color map (Cityscapes colors)
        self.color_map = self.create_cityscapes_colormap()

    def create_cityscapes_colormap(self):
        """Create color map for visualization"""
        colors = [
            [128, 64, 128],   # road
            [244, 35, 232],   # sidewalk
            [70, 70, 70],     # building
            [102, 102, 156],  # wall
            [190, 153, 153],  # fence
            [153, 153, 153],  # pole
            [250, 170, 30],   # traffic light
            [220, 220, 0],    # traffic sign
            [107, 142, 35],   # vegetation
            [152, 251, 152],  # terrain
            [70, 130, 180],   # sky
            [220, 20, 60],    # person
            [255, 0, 0],      # rider
            [0, 0, 142],      # car
            [0, 0, 70],       # truck
            [0, 60, 100],     # bus
            [0, 80, 100],     # train
            [0, 0, 230],      # motorcycle
            [119, 11, 32],    # bicycle
        ]
        return np.array(colors, dtype=np.uint8)

    def segment(self, image):
        """
        Perform semantic segmentation

        Args:
            image: RGB image (H, W, 3)

        Returns:
            segmentation_mask: (H, W) class labels
            colored_mask: (H, W, 3) RGB colored segmentation
        """
        # Preprocess
        input_tensor = self.preprocess(image)

        # Inference
        with torch.no_grad():
            output = self.model(input_tensor)['out']
            pred = torch.argmax(output, dim=1).squeeze().cpu().numpy()

        # Colorize for visualization
        colored_mask = self.color_map[pred]

        return pred, colored_mask

    def preprocess(self, image):
        """Preprocess image for model input"""
        # Normalize using ImageNet statistics
        mean = np.array([0.485, 0.456, 0.406])
        std = np.array([0.229, 0.224, 0.225])

        # Convert to tensor and normalize
        img = image.astype(np.float32) / 255.0
        img = (img - mean) / std
        img = torch.from_numpy(img).permute(2, 0, 1).unsqueeze(0)

        return img.to(self.device)

    def get_drivable_area(self, segmentation_mask):
        """Extract drivable area from segmentation"""
        # Drivable classes: road (0), sidewalk (1)
        drivable_mask = np.isin(segmentation_mask, [0, 1])
        return drivable_mask.astype(np.uint8)
```

## Depth Estimation

### Stereo Depth Estimation

```cpp
#include <opencv2/opencv.hpp>
#include <opencv2/calib3d.hpp>

class StereoDepthEstimator {
public:
    StereoDepthEstimator(const cv::Mat& K_left, const cv::Mat& K_right,
                        const cv::Mat& R, const cv::Mat& T, float baseline)
        : K_left_(K_left), K_right_(K_right), R_(R), T_(T), baseline_(baseline)
    {
        // Create stereo matcher
        stereo_ = cv::StereoSGBM::create(
            0,                      // minDisparity
            16 * 10,                // numDisparities (must be divisible by 16)
            5,                      // blockSize
            8 * 5 * 5,              // P1
            32 * 5 * 5,             // P2
            1,                      // disp12MaxDiff
            0,                      // preFilterCap
            10,                     // uniquenessRatio
            100,                    // speckleWindowSize
            32,                     // speckleRange
            cv::StereoSGBM::MODE_SGBM_3WAY
        );

        // Compute rectification maps
        cv::Size img_size(1280, 720);  // Adjust to your camera
        cv::stereoRectify(K_left_, cv::Mat(), K_right_, cv::Mat(),
                         img_size, R_, T_, R1_, R2_, P1_, P2_, Q_);

        cv::initUndistortRectifyMap(K_left_, cv::Mat(), R1_, P1_,
                                   img_size, CV_32FC1, map_left_x_, map_left_y_);
        cv::initUndistortRectifyMap(K_right_, cv::Mat(), R2_, P2_,
                                   img_size, CV_32FC1, map_right_x_, map_right_y_);
    }

    cv::Mat compute_disparity(const cv::Mat& left_img, const cv::Mat& right_img) {
        // Rectify images
        cv::Mat left_rect, right_rect;
        cv::remap(left_img, left_rect, map_left_x_, map_left_y_, cv::INTER_LINEAR);
        cv::remap(right_img, right_rect, map_right_x_, map_right_y_, cv::INTER_LINEAR);

        // Convert to grayscale
        cv::Mat left_gray, right_gray;
        cv::cvtColor(left_rect, left_gray, cv::COLOR_BGR2GRAY);
        cv::cvtColor(right_rect, right_gray, cv::COLOR_BGR2GRAY);

        // Compute disparity
        cv::Mat disparity;
        stereo_->compute(left_gray, right_gray, disparity);

        // Convert to float and normalize
        disparity.convertTo(disparity, CV_32F, 1.0 / 16.0);

        return disparity;
    }

    cv::Mat disparity_to_depth(const cv::Mat& disparity) {
        // depth = (focal_length * baseline) / disparity
        cv::Mat depth;
        float focal_length = K_left_.at<double>(0, 0);

        depth = (focal_length * baseline_) / disparity;

        // Clip unrealistic depths
        cv::threshold(depth, depth, 0.1, 100.0, cv::THRESH_TOZERO);
        cv::threshold(depth, depth, 100.0, 100.0, cv::THRESH_TRUNC);

        return depth;
    }

    cv::Mat compute_point_cloud(const cv::Mat& disparity) {
        // Reproject to 3D using Q matrix
        cv::Mat points_3d;
        cv::reprojectImageTo3D(disparity, points_3d, Q_, true);

        return points_3d;
    }

private:
    cv::Mat K_left_, K_right_;  // Intrinsic matrices
    cv::Mat R_, T_;              // Extrinsic: rotation and translation
    cv::Mat R1_, R2_, P1_, P2_, Q_;  // Rectification matrices
    cv::Mat map_left_x_, map_left_y_, map_right_x_, map_right_y_;
    float baseline_;
    cv::Ptr<cv::StereoSGBM> stereo_;
};
```

### Monocular Depth Estimation (Deep Learning)

```python
import torch
import torch.nn as nn

class MonoDepthNet(nn.Module):
    """
    Monocular depth estimation network based on encoder-decoder architecture
    """

    def __init__(self, encoder='resnet50'):
        super(MonoDepthNet, self).__init__()

        # Encoder (pretrained ResNet)
        if encoder == 'resnet50':
            resnet = torch.hub.load('pytorch/vision:v0.10.0', 'resnet50',
                                   pretrained=True)
            self.encoder = nn.ModuleList([
                nn.Sequential(resnet.conv1, resnet.bn1, resnet.relu, resnet.maxpool),
                resnet.layer1,
                resnet.layer2,
                resnet.layer3,
                resnet.layer4
            ])
            encoder_channels = [64, 256, 512, 1024, 2048]

        # Decoder
        self.decoder = nn.ModuleList([
            self.upconv_block(2048, 1024),
            self.upconv_block(1024 + 1024, 512),
            self.upconv_block(512 + 512, 256),
            self.upconv_block(256 + 256, 128),
            self.upconv_block(128 + 64, 64)
        ])

        # Output layer
        self.output_conv = nn.Sequential(
            nn.Conv2d(64, 32, 3, padding=1),
            nn.ReLU(inplace=True),
            nn.Conv2d(32, 1, 1),
            nn.Sigmoid()  # Output in range [0, 1]
        )

    def upconv_block(self, in_channels, out_channels):
        return nn.Sequential(
            nn.ConvTranspose2d(in_channels, out_channels, 3, stride=2, padding=1,
                             output_padding=1),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_channels, out_channels, 3, padding=1),
            nn.BatchNorm2d(out_channels),
            nn.ReLU(inplace=True)
        )

    def forward(self, x):
        # Encoder with skip connections
        skip_connections = []
        for layer in self.encoder:
            x = layer(x)
            skip_connections.append(x)

        # Decoder
        x = skip_connections[-1]
        for i, decoder_layer in enumerate(self.decoder):
            x = decoder_layer(x)
            if i < len(skip_connections) - 1:
                # Concatenate with skip connection
                x = torch.cat([x, skip_connections[-(i + 2)]], dim=1)

        # Output depth map
        depth = self.output_conv(x)

        return depth
```

## ISP Tuning

### HDR and Low-Light Enhancement

```cpp
#include <opencv2/opencv.hpp>

class ISPProcessor {
public:
    cv::Mat process_hdr(const std::vector<cv::Mat>& exposures) {
        // Multi-exposure HDR fusion
        cv::Ptr<cv::MergeDebevec> merge = cv::createMergeDebevec();

        std::vector<float> exposure_times;
        for (size_t i = 0; i < exposures.size(); ++i) {
            exposure_times.push_back(std::pow(2.0f, i - 1));  // -1, 0, +1 EV
        }

        cv::Mat hdr;
        merge->process(exposures, hdr, exposure_times, cv::Mat());

        // Tone mapping
        cv::Ptr<cv::TonemapDrago> tonemap = cv::createTonemapDrago(2.2f);
        cv::Mat ldr;
        tonemap->process(hdr, ldr);

        // Convert to 8-bit
        ldr = ldr * 255.0;
        ldr.convertTo(ldr, CV_8UC3);

        return ldr;
    }

    cv::Mat enhance_low_light(const cv::Mat& image) {
        // CLAHE (Contrast Limited Adaptive Histogram Equalization)
        cv::Mat lab;
        cv::cvtColor(image, lab, cv::COLOR_BGR2Lab);

        std::vector<cv::Mat> lab_planes;
        cv::split(lab, lab_planes);

        // Apply CLAHE to L channel
        cv::Ptr<cv::CLAHE> clahe = cv::createCLAHE(3.0, cv::Size(8, 8));
        clahe->apply(lab_planes[0], lab_planes[0]);

        cv::merge(lab_planes, lab);
        cv::Mat enhanced;
        cv::cvtColor(lab, enhanced, cv::COLOR_Lab2BGR);

        return enhanced;
    }

    cv::Mat denoise(const cv::Mat& image) {
        // Fast non-local means denoising
        cv::Mat denoised;
        cv::fastNlMeansDenoisingColored(image, denoised, 10, 10, 7, 21);
        return denoised;
    }
};
```

## Performance Optimization

### TensorRT Optimization for NVIDIA Platforms

```python
import tensorrt as trt
import pycuda.driver as cuda
import numpy as np

class TensorRTInference:
    """
    Optimize and run deep learning models with TensorRT
    """

    def __init__(self, onnx_path, fp16_mode=True):
        self.logger = trt.Logger(trt.Logger.WARNING)
        self.engine = self.build_engine(onnx_path, fp16_mode)
        self.context = self.engine.create_execution_context()

        # Allocate buffers
        self.inputs, self.outputs, self.bindings = self.allocate_buffers()

    def build_engine(self, onnx_path, fp16_mode):
        """Build TensorRT engine from ONNX model"""
        builder = trt.Builder(self.logger)
        network = builder.create_network(
            1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH)
        )
        parser = trt.OnnxParser(network, self.logger)

        # Parse ONNX
        with open(onnx_path, 'rb') as model:
            parser.parse(model.read())

        # Builder config
        config = builder.create_builder_config()
        config.max_workspace_size = 1 << 30  # 1GB

        if fp16_mode:
            config.set_flag(trt.BuilderFlag.FP16)

        # Build engine
        engine = builder.build_engine(network, config)
        return engine

    def allocate_buffers(self):
        inputs = []
        outputs = []
        bindings = []

        for binding in self.engine:
            size = trt.volume(self.engine.get_binding_shape(binding))
            dtype = trt.nptype(self.engine.get_binding_dtype(binding))

            # Allocate host and device buffers
            host_mem = cuda.pagelocked_empty(size, dtype)
            device_mem = cuda.mem_alloc(host_mem.nbytes)

            bindings.append(int(device_mem))

            if self.engine.binding_is_input(binding):
                inputs.append({'host': host_mem, 'device': device_mem})
            else:
                outputs.append({'host': host_mem, 'device': device_mem})

        return inputs, outputs, bindings

    def infer(self, input_data):
        """Run inference"""
        # Copy input to device
        np.copyto(self.inputs[0]['host'], input_data.ravel())
        cuda.memcpy_htod(self.inputs[0]['device'], self.inputs[0]['host'])

        # Run inference
        self.context.execute_v2(bindings=self.bindings)

        # Copy output to host
        cuda.memcpy_dtoh(self.outputs[0]['host'], self.outputs[0]['device'])

        return self.outputs[0]['host']
```

## Standards & Safety

- **ISO 26262**: ASIL B-D depending on function (lane keeping: ASIL B, AEB: ASIL D)
- **ISO 21448 (SOTIF)**: Validation for lighting conditions, occlusions
- **MISRA C++**: Code quality for production deployment

## Performance Targets

- **Lane Detection**: 30 FPS @ 1280x720
- **Object Detection**: 30 FPS @ 1920x1080 (YOLOv5s on GPU)
- **Semantic Segmentation**: 20 FPS @ 1280x720 (DeepLabV3)
- **Latency**: < 50ms camera-to-decision

## Related Skills

- sensor-fusion-perception.md
- radar-lidar-processing.md
- adas-features-implementation.md

---

## Hd Maps Localization

# HD Maps & Localization for ADAS

## Overview

High-definition map formats (Lanelet2, OpenDRIVE, NDS), map-based localization, GNSS/IMU fusion, visual odometry, SLAM (ORB-SLAM, Cartographer), and achieving <10cm localization accuracy for L3+ autonomy.

## HD Map Formats

### Lanelet2 Format

```xml
<!-- Example Lanelet2 map -->
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6">
  <!-- Points (nodes) -->
  <node id="1" lat="48.778000" lon="9.180000"/>
  <node id="2" lat="48.778100" lon="9.180100"/>
  <node id="3" lat="48.778200" lon="9.180200"/>

  <!-- Left lane boundary -->
  <way id="100">
    <nd ref="1"/>
    <nd ref="2"/>
    <nd ref="3"/>
    <tag k="type" v="line_thin"/>
    <tag k="subtype" v="dashed"/>
  </way>

  <!-- Right lane boundary -->
  <way id="101">
    <nd ref="4"/>
    <nd ref="5"/>
    <nd ref="6"/>
    <tag k="type" v="line_thin"/>
    <tag k="subtype" v="solid"/>
  </way>

  <!-- Lanelet (lane) -->
  <relation id="1000">
    <member type="way" ref="100" role="left"/>
    <member type="way" ref="101" role="right"/>
    <tag k="type" v="lanelet"/>
    <tag k="subtype" v="road"/>
    <tag k="location" v="urban"/>
    <tag k="speed_limit" v="50"/>
    <tag k="participant:vehicle" v="yes"/>
  </relation>
</osm>
```

### Lanelet2 C++ API

```cpp
#include <lanelet2_core/LaneletMap.h>
#include <lanelet2_io/Io.h>
#include <lanelet2_projection/UTM.h>
#include <lanelet2_routing/RoutingGraph.h>
#include <lanelet2_traffic_rules/TrafficRulesFactory.h>

class HDMapManager {
public:
    HDMapManager(const std::string& map_file) {
        // Load map with UTM projection
        std::string projector_type = "utm";
        lanelet::projection::UtmProjector projector(
            lanelet::Origin({48.778, 9.180})  // Origin lat/lon
        );

        map_ = lanelet::load(map_file, projector);

        // Create traffic rules
        traffic_rules_ = lanelet::traffic_rules::TrafficRulesFactory::create(
            lanelet::Locations::Germany,
            lanelet::Participants::Vehicle
        );

        // Build routing graph
        routing_graph_ = lanelet::routing::RoutingGraph::build(*map_, *traffic_rules_);
    }

    struct LocalizationResult {
        lanelet::ConstLanelet current_lanelet;
        double lateral_offset;        // meters (negative = left of centerline)
        double longitudinal_position;  // meters along lanelet
        double heading_error;         // radians
        bool valid;
    };

    LocalizationResult localize(const Eigen::Vector2d& position, double heading) {
        LocalizationResult result;
        result.valid = false;

        // Find nearest lanelet
        lanelet::Point3d query_point(lanelet::utils::getId(), position.x(), position.y(), 0.0);

        auto nearest_lanelets = lanelet::geometry::findNearest(
            map_->laneletLayer, query_point, 1
        );

        if (nearest_lanelets.empty()) {
            return result;
        }

        result.current_lanelet = nearest_lanelets.front();

        // Calculate lateral offset
        result.lateral_offset = calculate_lateral_offset(position, result.current_lanelet);

        // Calculate longitudinal position
        result.longitudinal_position = calculate_arc_length(position, result.current_lanelet);

        // Calculate heading error
        double lanelet_heading = calculate_lanelet_heading(position, result.current_lanelet);
        result.heading_error = normalize_angle(heading - lanelet_heading);

        result.valid = true;
        return result;
    }

    lanelet::routing::Route plan_route(const lanelet::ConstLanelet& start,
                                      const lanelet::ConstLanelet& goal) {
        auto optional_route = routing_graph_->getRoute(start, goal, 0);

        if (optional_route) {
            return optional_route.get();
        }

        return lanelet::routing::Route();
    }

    double get_speed_limit(const lanelet::ConstLanelet& lanelet) {
        lanelet::SpeedLimitInformation speed_limit = traffic_rules_->speedLimit(lanelet);
        return speed_limit.speedLimit.value();  // m/s
    }

private:
    lanelet::LaneletMapPtr map_;
    lanelet::traffic_rules::TrafficRulesPtr traffic_rules_;
    lanelet::routing::RoutingGraphUPtr routing_graph_;

    double calculate_lateral_offset(const Eigen::Vector2d& position,
                                    const lanelet::ConstLanelet& lanelet) {
        // Project position onto lanelet centerline
        auto centerline = lanelet.centerline();

        double min_dist = std::numeric_limits<double>::max();
        Eigen::Vector2d closest_point;

        for (size_t i = 0; i < centerline.size() - 1; ++i) {
            Eigen::Vector2d p1(centerline[i].x(), centerline[i].y());
            Eigen::Vector2d p2(centerline[i+1].x(), centerline[i+1].y());

            Eigen::Vector2d segment = p2 - p1;
            Eigen::Vector2d to_pos = position - p1;

            double t = std::clamp(to_pos.dot(segment) / segment.squaredNorm(), 0.0, 1.0);
            Eigen::Vector2d projection = p1 + t * segment;

            double dist = (position - projection).norm();
            if (dist < min_dist) {
                min_dist = dist;
                closest_point = projection;
            }
        }

        // Determine sign (left/right of centerline)
        // Use cross product
        Eigen::Vector2d p1(centerline[0].x(), centerline[0].y());
        Eigen::Vector2d p2(centerline[1].x(), centerline[1].y());
        Eigen::Vector2d segment = p2 - p1;
        Eigen::Vector2d to_pos = position - p1;

        double cross = segment.x() * to_pos.y() - segment.y() * to_pos.x();
        double sign = (cross > 0) ? -1.0 : 1.0;

        return sign * min_dist;
    }

    double calculate_arc_length(const Eigen::Vector2d& position,
                                const lanelet::ConstLanelet& lanelet) {
        auto centerline = lanelet.centerline();
        double arc_length = 0.0;

        // Find closest segment and accumulate distance
        for (size_t i = 0; i < centerline.size() - 1; ++i) {
            Eigen::Vector2d p1(centerline[i].x(), centerline[i].y());
            Eigen::Vector2d p2(centerline[i+1].x(), centerline[i+1].y());

            // Check if position projects onto this segment
            Eigen::Vector2d segment = p2 - p1;
            Eigen::Vector2d to_pos = position - p1;

            double t = std::clamp(to_pos.dot(segment) / segment.squaredNorm(), 0.0, 1.0);

            if (t < 1.0) {
                // Position projects onto this segment
                arc_length += t * segment.norm();
                break;
            } else {
                arc_length += segment.norm();
            }
        }

        return arc_length;
    }

    double calculate_lanelet_heading(const Eigen::Vector2d& position,
                                     const lanelet::ConstLanelet& lanelet) {
        auto centerline = lanelet.centerline();

        // Find closest segment
        size_t closest_segment = 0;
        double min_dist = std::numeric_limits<double>::max();

        for (size_t i = 0; i < centerline.size() - 1; ++i) {
            Eigen::Vector2d p1(centerline[i].x(), centerline[i].y());
            Eigen::Vector2d p2(centerline[i+1].x(), centerline[i+1].y());

            Eigen::Vector2d segment = p2 - p1;
            Eigen::Vector2d to_pos = position - p1;

            double t = std::clamp(to_pos.dot(segment) / segment.squaredNorm(), 0.0, 1.0);
            Eigen::Vector2d projection = p1 + t * segment;

            double dist = (position - projection).norm();
            if (dist < min_dist) {
                min_dist = dist;
                closest_segment = i;
            }
        }

        // Calculate heading of closest segment
        Eigen::Vector2d p1(centerline[closest_segment].x(), centerline[closest_segment].y());
        Eigen::Vector2d p2(centerline[closest_segment+1].x(), centerline[closest_segment+1].y());

        return std::atan2(p2.y() - p1.y(), p2.x() - p1.x());
    }

    double normalize_angle(double angle) {
        while (angle > M_PI) angle -= 2 * M_PI;
        while (angle < -M_PI) angle += 2 * M_PI;
        return angle;
    }
};
```

### OpenDRIVE Format

```xml
<!-- OpenDRIVE HD map example -->
<?xml version="1.0" encoding="UTF-8"?>
<OpenDRIVE>
  <header revMajor="1" revMinor="4" name="HighwayMap" version="1.0"/>

  <road name="Highway_A9" length="1000.0" id="1" junction="-1">
    <link>
      <predecessor elementType="road" elementId="0"/>
      <successor elementType="road" elementId="2"/>
    </link>

    <!-- Road geometry -->
    <planView>
      <geometry s="0.0" x="0.0" y="0.0" hdg="0.0" length="500.0">
        <line/>
      </geometry>
      <geometry s="500.0" x="500.0" y="0.0" hdg="0.0" length="500.0">
        <arc curvature="0.002"/>  <!-- R = 500m curve -->
      </geometry>
    </planView>

    <!-- Lane sections -->
    <lanes>
      <laneSection s="0.0">
        <center>
          <lane id="0" type="driving" level="0"/>
        </center>
        <right>
          <lane id="-1" type="driving" level="0">
            <width sOffset="0.0" a="3.75" b="0.0" c="0.0" d="0.0"/>
            <roadMark sOffset="0.0" type="solid" weight="standard" color="white"/>
            <speed sOffset="0.0" max="33.33"/>  <!-- 120 km/h -->
          </lane>
          <lane id="-2" type="driving" level="0">
            <width sOffset="0.0" a="3.75" b="0.0" c="0.0" d="0.0"/>
            <roadMark sOffset="0.0" type="broken" weight="standard" color="white"/>
          </lane>
        </right>
      </laneSection>
    </lanes>
  </road>
</OpenDRIVE>
```

## GNSS/IMU Sensor Fusion

### Extended Kalman Filter for GNSS/IMU

```cpp
#include <Eigen/Dense>

class GNSSIMUFusion {
public:
    GNSSIMUFusion() {
        // State: [x, y, z, vx, vy, vz, roll, pitch, yaw]
        state_ = Eigen::VectorXd::Zero(9);
        covariance_ = Eigen::MatrixXd::Identity(9, 9) * 100.0;

        // Process noise
        Q_ = Eigen::MatrixXd::Identity(9, 9);
        Q_.block<3,3>(0,0) *= 0.1;   // Position
        Q_.block<3,3>(3,3) *= 1.0;   // Velocity
        Q_.block<3,3>(6,6) *= 0.01;  // Orientation

        // GNSS measurement noise
        R_gnss_ = Eigen::Matrix3d::Identity() * 1.0;  // 1m std dev

        // IMU measurement noise
        R_imu_ = Eigen::MatrixXd::Identity(6, 6);
        R_imu_.block<3,3>(0,0) *= 0.1;   // Acceleration (m/s²)
        R_imu_.block<3,3>(3,3) *= 0.01;  // Gyroscope (rad/s)
    }

    struct IMUMeasurement {
        Eigen::Vector3d acceleration;
        Eigen::Vector3d angular_velocity;
        double timestamp;
    };

    struct GNSSMeasurement {
        double latitude;
        double longitude;
        double altitude;
        Eigen::Vector3d position_enu;  // East-North-Up frame
        double timestamp;
        double horizontal_accuracy;
        double vertical_accuracy;
    };

    void predict_imu(const IMUMeasurement& imu, double dt) {
        // IMU-based prediction (high-rate, ~100Hz)

        // Gravity compensation
        Eigen::Vector3d gravity(0, 0, -9.81);

        // Rotate acceleration to world frame
        Eigen::Matrix3d R = rotation_matrix(state_(6), state_(7), state_(8));
        Eigen::Vector3d accel_world = R * imu.acceleration + gravity;

        // Update velocity
        state_.segment<3>(3) += accel_world * dt;

        // Update position
        state_.segment<3>(0) += state_.segment<3>(3) * dt + 0.5 * accel_world * dt * dt;

        // Update orientation (integrate gyroscope)
        state_.segment<3>(6) += imu.angular_velocity * dt;

        // Normalize angles
        state_(6) = normalize_angle(state_(6));
        state_(7) = normalize_angle(state_(7));
        state_(8) = normalize_angle(state_(8));

        // Predict covariance
        Eigen::MatrixXd F = compute_state_jacobian(imu, dt);
        covariance_ = F * covariance_ * F.transpose() + Q_;
    }

    void update_gnss(const GNSSMeasurement& gnss) {
        // GNSS measurement update (low-rate, ~10Hz)

        // Measurement matrix (GNSS observes position only)
        Eigen::MatrixXd H = Eigen::MatrixXd::Zero(3, 9);
        H.block<3,3>(0,0) = Eigen::Matrix3d::Identity();

        // Innovation
        Eigen::Vector3d z = gnss.position_enu;
        Eigen::Vector3d z_pred = state_.segment<3>(0);
        Eigen::Vector3d y = z - z_pred;

        // Measurement noise (from GNSS accuracy)
        Eigen::Matrix3d R = Eigen::Matrix3d::Identity();
        R(0,0) = gnss.horizontal_accuracy * gnss.horizontal_accuracy;
        R(1,1) = gnss.horizontal_accuracy * gnss.horizontal_accuracy;
        R(2,2) = gnss.vertical_accuracy * gnss.vertical_accuracy;

        // Innovation covariance
        Eigen::Matrix3d S = H * covariance_ * H.transpose() + R;

        // Kalman gain
        Eigen::MatrixXd K = covariance_ * H.transpose() * S.inverse();

        // Update state
        state_ = state_ + K * y;

        // Update covariance
        Eigen::MatrixXd I = Eigen::MatrixXd::Identity(9, 9);
        covariance_ = (I - K * H) * covariance_;
    }

    Eigen::VectorXd get_state() const { return state_; }
    Eigen::MatrixXd get_covariance() const { return covariance_; }

    struct LocalizationOutput {
        Eigen::Vector3d position;
        Eigen::Vector3d velocity;
        Eigen::Vector3d orientation;  // roll, pitch, yaw
        Eigen::Matrix3d position_covariance;
        double horizontal_accuracy() const {
            return std::sqrt(position_covariance(0,0) + position_covariance(1,1));
        }
    };

    LocalizationOutput get_localization() const {
        LocalizationOutput output;
        output.position = state_.segment<3>(0);
        output.velocity = state_.segment<3>(3);
        output.orientation = state_.segment<3>(6);
        output.position_covariance = covariance_.block<3,3>(0,0);
        return output;
    }

private:
    Eigen::VectorXd state_;       // [x, y, z, vx, vy, vz, roll, pitch, yaw]
    Eigen::MatrixXd covariance_;
    Eigen::MatrixXd Q_;           // Process noise
    Eigen::Matrix3d R_gnss_;      // GNSS measurement noise
    Eigen::MatrixXd R_imu_;       // IMU measurement noise

    Eigen::Matrix3d rotation_matrix(double roll, double pitch, double yaw) {
        Eigen::Matrix3d R;

        double cr = std::cos(roll);
        double sr = std::sin(roll);
        double cp = std::cos(pitch);
        double sp = std::sin(pitch);
        double cy = std::cos(yaw);
        double sy = std::sin(yaw);

        R << cy*cp, cy*sp*sr - sy*cr, cy*sp*cr + sy*sr,
             sy*cp, sy*sp*sr + cy*cr, sy*sp*cr - cy*sr,
             -sp,   cp*sr,            cp*cr;

        return R;
    }

    Eigen::MatrixXd compute_state_jacobian(const IMUMeasurement& imu, double dt) {
        // Simplified: assume linear dynamics
        Eigen::MatrixXd F = Eigen::MatrixXd::Identity(9, 9);

        // Position depends on velocity
        F.block<3,3>(0,3) = Eigen::Matrix3d::Identity() * dt;

        return F;
    }

    double normalize_angle(double angle) {
        while (angle > M_PI) angle -= 2 * M_PI;
        while (angle < -M_PI) angle += 2 * M_PI;
        return angle;
    }
};
```

## Visual Odometry

### ORB-SLAM3 Integration

```cpp
#include <System.h>
#include <opencv2/core.hpp>

class VisualOdometry {
public:
    VisualOdometry(const std::string& vocab_file, const std::string& settings_file) {
        // Initialize ORB-SLAM3
        slam_system_ = new ORB_SLAM3::System(
            vocab_file,
            settings_file,
            ORB_SLAM3::System::MONOCULAR,
            true  // Use viewer
        );
    }

    ~VisualOdometry() {
        slam_system_->Shutdown();
        delete slam_system_;
    }

    struct VOOutput {
        Eigen::Matrix4f pose;      // 4x4 transformation matrix
        bool tracking_good;
        int num_features;
        double scale_drift;
    };

    VOOutput process_frame(const cv::Mat& image, double timestamp) {
        VOOutput output;

        // Track frame
        cv::Mat Tcw = slam_system_->TrackMonocular(image, timestamp);

        if (Tcw.empty()) {
            output.tracking_good = false;
            return output;
        }

        // Convert to Eigen
        output.pose = Eigen::Matrix4f::Identity();
        for (int i = 0; i < 4; ++i) {
            for (int j = 0; j < 4; ++j) {
                output.pose(i, j) = Tcw.at<float>(i, j);
            }
        }

        output.tracking_good = true;
        output.num_features = slam_system_->GetTrackedMapPoints().size();

        return output;
    }

private:
    ORB_SLAM3::System* slam_system_;
};
```

## Map Matching for Lane-Level Localization

```python
import numpy as np
from scipy.spatial import KDTree

class MapMatcher:
    """
    Match GNSS/IMU pose to HD map for lane-level localization
    """

    def __init__(self, hd_map):
        """
        Args:
            hd_map: Dictionary with 'lanelets', 'centerlines', etc.
        """
        self.hd_map = hd_map

        # Build spatial index for efficient matching
        self.build_spatial_index()

    def build_spatial_index(self):
        """Build KD-tree for fast nearest neighbor search"""
        all_points = []

        for lanelet_id, centerline in self.hd_map['centerlines'].items():
            for point in centerline:
                all_points.append(point[:2])  # x, y only

        self.kdtree = KDTree(np.array(all_points))

    def match_to_map(self, pose, heading, search_radius=10.0):
        """
        Match vehicle pose to HD map

        Args:
            pose: (x, y) vehicle position
            heading: vehicle heading (radians)
            search_radius: search radius in meters

        Returns:
            matched_lanelet: Lanelet ID
            lateral_offset: Offset from centerline (meters)
            heading_error: Heading error (radians)
        """
        # Find candidate lanelets within search radius
        candidates = self.find_candidate_lanelets(pose, search_radius)

        if not candidates:
            return None, None, None

        # Score candidates based on position and heading
        best_match = None
        best_score = float('inf')

        for lanelet_id in candidates:
            score, lateral_offset, heading_error = self.score_lanelet_match(
                lanelet_id, pose, heading
            )

            if score < best_score:
                best_score = score
                best_match = lanelet_id
                best_lateral_offset = lateral_offset
                best_heading_error = heading_error

        return best_match, best_lateral_offset, best_heading_error

    def find_candidate_lanelets(self, pose, search_radius):
        """Find lanelets within search radius"""
        # Query KD-tree
        indices = self.kdtree.query_ball_point(pose, search_radius)

        # Map indices back to lanelet IDs
        candidate_lanelets = set()
        # ... (implementation to map point indices to lanelet IDs)

        return list(candidate_lanelets)

    def score_lanelet_match(self, lanelet_id, pose, heading):
        """
        Score how well pose matches lanelet

        Returns:
            score: Lower is better
            lateral_offset: Distance from centerline
            heading_error: Heading difference
        """
        centerline = self.hd_map['centerlines'][lanelet_id]

        # Find closest point on centerline
        min_dist = float('inf')
        closest_segment_idx = 0

        for i in range(len(centerline) - 1):
            p1 = np.array(centerline[i][:2])
            p2 = np.array(centerline[i+1][:2])

            # Project pose onto segment
            segment = p2 - p1
            to_pose = pose - p1

            t = np.clip(np.dot(to_pose, segment) / np.dot(segment, segment), 0, 1)
            projection = p1 + t * segment

            dist = np.linalg.norm(pose - projection)

            if dist < min_dist:
                min_dist = dist
                closest_segment_idx = i

        lateral_offset = min_dist

        # Calculate heading error
        p1 = np.array(centerline[closest_segment_idx][:2])
        p2 = np.array(centerline[closest_segment_idx + 1][:2])
        segment_heading = np.arctan2(p2[1] - p1[1], p2[0] - p1[0])

        heading_error = self.normalize_angle(heading - segment_heading)

        # Combined score
        score = lateral_offset + abs(heading_error) * 2.0

        return score, lateral_offset, heading_error

    def normalize_angle(self, angle):
        """Normalize angle to [-pi, pi]"""
        while angle > np.pi:
            angle -= 2 * np.pi
        while angle < -np.pi:
            angle += 2 * np.pi
        return angle
```

## Localization Accuracy Requirements

| Autonomy Level | Lateral Accuracy | Longitudinal Accuracy | Update Rate |
|----------------|------------------|------------------------|-------------|
| **L2 (ADAS)** | < 0.5m | < 2m | 10 Hz |
| **L3** | < 0.3m | < 1m | 20 Hz |
| **L4** | < 0.1m | < 0.5m | 50 Hz |
| **L5** | < 0.05m | < 0.2m | 50-100 Hz |

## Related Skills

- sensor-fusion-perception.md
- path-planning-control.md
- adas-features-implementation.md

---

## Path Planning Control

# Path Planning & Control for ADAS

## Overview

Path planning algorithms (A*, RRT, Hybrid A*), trajectory optimization, Model Predictive Control (MPC), Pure Pursuit, Stanley controller, and behavior planning for L2-L5 autonomy.

## Path Planning Algorithms

### A* for Grid-Based Planning

```python
import numpy as np
import heapq
from dataclasses import dataclass, field
from typing import List, Tuple

@dataclass(order=True)
class Node:
    f_score: float
    position: Tuple[int, int] = field(compare=False)
    g_score: float = field(compare=False)
    parent: 'Node' = field(default=None, compare=False)

class AStarPlanner:
    """
    A* path planning on occupancy grid
    """

    def __init__(self, occupancy_grid, resolution=0.5):
        """
        Args:
            occupancy_grid: 2D numpy array (0=free, 1=occupied)
            resolution: meters per grid cell
        """
        self.grid = occupancy_grid
        self.resolution = resolution
        self.height, self.width = occupancy_grid.shape

    def plan(self, start, goal):
        """
        Find path from start to goal

        Args:
            start: (x, y) in meters
            goal: (x, y) in meters

        Returns:
            path: List of (x, y) waypoints in meters
        """
        start_cell = self.world_to_grid(start)
        goal_cell = self.world_to_grid(goal)

        if not self.is_valid(start_cell) or not self.is_valid(goal_cell):
            return []

        # Initialize
        open_set = []
        closed_set = set()

        start_node = Node(
            f_score=self.heuristic(start_cell, goal_cell),
            position=start_cell,
            g_score=0.0
        )

        heapq.heappush(open_set, start_node)

        while open_set:
            current = heapq.heappop(open_set)

            if current.position == goal_cell:
                return self.reconstruct_path(current)

            closed_set.add(current.position)

            # Explore neighbors (8-connected)
            for neighbor_pos in self.get_neighbors(current.position):
                if neighbor_pos in closed_set:
                    continue

                if not self.is_free(neighbor_pos):
                    continue

                # Calculate g_score
                move_cost = self.distance(current.position, neighbor_pos)
                tentative_g = current.g_score + move_cost

                # Check if better path
                neighbor_node = Node(
                    f_score=tentative_g + self.heuristic(neighbor_pos, goal_cell),
                    position=neighbor_pos,
                    g_score=tentative_g,
                    parent=current
                )

                heapq.heappush(open_set, neighbor_node)

        return []  # No path found

    def reconstruct_path(self, node):
        """Reconstruct path from goal to start"""
        path = []
        current = node

        while current:
            path.append(self.grid_to_world(current.position))
            current = current.parent

        return list(reversed(path))

    def get_neighbors(self, pos):
        """Get 8-connected neighbors"""
        x, y = pos
        neighbors = []

        for dx in [-1, 0, 1]:
            for dy in [-1, 0, 1]:
                if dx == 0 and dy == 0:
                    continue

                nx, ny = x + dx, y + dy
                if self.is_valid((nx, ny)):
                    neighbors.append((nx, ny))

        return neighbors

    def is_valid(self, pos):
        """Check if position is within grid bounds"""
        x, y = pos
        return 0 <= x < self.width and 0 <= y < self.height

    def is_free(self, pos):
        """Check if cell is free"""
        x, y = pos
        return self.grid[y, x] < 0.5  # Occupancy threshold

    def heuristic(self, pos1, pos2):
        """Euclidean distance heuristic"""
        return np.sqrt((pos1[0] - pos2[0])**2 + (pos1[1] - pos2[1])**2)

    def distance(self, pos1, pos2):
        """Actual distance between adjacent cells"""
        dx = abs(pos1[0] - pos2[0])
        dy = abs(pos1[1] - pos2[1])

        if dx + dy == 2:  # Diagonal
            return np.sqrt(2)
        else:  # Straight
            return 1.0

    def world_to_grid(self, pos):
        """Convert world coordinates to grid indices"""
        x = int(pos[0] / self.resolution)
        y = int(pos[1] / self.resolution)
        return (x, y)

    def grid_to_world(self, pos):
        """Convert grid indices to world coordinates"""
        x = (pos[0] + 0.5) * self.resolution
        y = (pos[1] + 0.5) * self.resolution
        return (x, y)
```

### RRT (Rapidly-Exploring Random Trees)

```python
import numpy as np
import matplotlib.pyplot as plt

class RRTPlanner:
    """
    RRT path planning for continuous space
    """

    def __init__(self, start, goal, obstacle_list, rand_area,
                 max_iter=500, expand_dis=0.5, goal_sample_rate=5):
        """
        Args:
            start: (x, y) start position
            goal: (x, y) goal position
            obstacle_list: List of (x, y, radius) obstacles
            rand_area: [x_min, x_max, y_min, y_max] sampling area
            max_iter: Maximum iterations
            expand_dis: Step size for tree expansion
            goal_sample_rate: Percentage to sample goal directly
        """
        self.start = Node(start[0], start[1])
        self.goal = Node(goal[0], goal[1])
        self.obstacle_list = obstacle_list
        self.rand_area = rand_area
        self.max_iter = max_iter
        self.expand_dis = expand_dis
        self.goal_sample_rate = goal_sample_rate

        self.node_list = [self.start]

    class Node:
        def __init__(self, x, y):
            self.x = x
            self.y = y
            self.path_x = []
            self.path_y = []
            self.parent = None

    def plan(self):
        """Execute RRT planning"""
        for i in range(self.max_iter):
            # Sample random point (or goal with probability)
            if np.random.rand() < self.goal_sample_rate / 100:
                rnd_node = self.Node(self.goal.x, self.goal.y)
            else:
                rnd_node = self.sample_random_node()

            # Find nearest node in tree
            nearest_node = self.get_nearest_node(rnd_node)

            # Extend tree towards random node
            new_node = self.steer(nearest_node, rnd_node)

            # Check for collisions
            if not self.check_collision(new_node):
                self.node_list.append(new_node)

                # Check if goal reached
                if self.distance_to_goal(new_node) <= self.expand_dis:
                    final_node = self.steer(new_node, self.goal)
                    if not self.check_collision(final_node):
                        return self.generate_final_path(len(self.node_list) - 1)

        return None  # No path found

    def sample_random_node(self):
        """Sample random point in free space"""
        x = np.random.uniform(self.rand_area[0], self.rand_area[1])
        y = np.random.uniform(self.rand_area[2], self.rand_area[3])
        return self.Node(x, y)

    def get_nearest_node(self, rnd_node):
        """Find nearest node in tree to random node"""
        distances = [(node.x - rnd_node.x)**2 + (node.y - rnd_node.y)**2
                    for node in self.node_list]
        nearest_idx = np.argmin(distances)
        return self.node_list[nearest_idx]

    def steer(self, from_node, to_node):
        """Steer from from_node towards to_node by expand_dis"""
        new_node = self.Node(from_node.x, from_node.y)
        new_node.parent = from_node

        # Calculate direction
        dx = to_node.x - from_node.x
        dy = to_node.y - from_node.y
        dist = np.hypot(dx, dy)

        # Extend by expand_dis or reach to_node
        if dist <= self.expand_dis:
            new_node.x = to_node.x
            new_node.y = to_node.y
        else:
            new_node.x = from_node.x + self.expand_dis * dx / dist
            new_node.y = from_node.y + self.expand_dis * dy / dist

        new_node.path_x = [from_node.x, new_node.x]
        new_node.path_y = [from_node.y, new_node.y]

        return new_node

    def check_collision(self, node):
        """Check if node collides with obstacles"""
        for (ox, oy, radius) in self.obstacle_list:
            dx = node.x - ox
            dy = node.y - oy
            dist = np.hypot(dx, dy)

            if dist <= radius:
                return True  # Collision

        return False

    def distance_to_goal(self, node):
        """Distance from node to goal"""
        return np.hypot(node.x - self.goal.x, node.y - self.goal.y)

    def generate_final_path(self, goal_idx):
        """Generate final path from start to goal"""
        path = [[self.goal.x, self.goal.y]]
        node = self.node_list[goal_idx]

        while node.parent:
            path.append([node.x, node.y])
            node = node.parent

        path.append([node.x, node.y])

        return list(reversed(path))
```

### Hybrid A* for Car-Like Vehicles

```cpp
#include <vector>
#include <queue>
#include <cmath>
#include <Eigen/Dense>

class HybridAStarPlanner {
public:
    struct VehicleParams {
        double wheelbase = 2.7;       // meters
        double max_steering_angle = 0.6;  // radians (~35 degrees)
        double min_turning_radius = wheelbase / std::tan(max_steering_angle);
    };

    struct State {
        double x, y, theta;  // Position and heading
        double g_cost, h_cost;
        std::vector<State> path;

        double f_cost() const { return g_cost + h_cost; }

        bool operator>(const State& other) const {
            return f_cost() > other.f_cost();
        }
    };

    HybridAStarPlanner(const VehicleParams& params) : params_(params) {}

    std::vector<State> plan(const State& start, const State& goal,
                           const std::vector<std::vector<double>>& obstacle_map) {
        std::priority_queue<State, std::vector<State>, std::greater<State>> open_set;

        State start_state = start;
        start_state.g_cost = 0.0;
        start_state.h_cost = heuristic(start, goal);

        open_set.push(start_state);

        while (!open_set.empty()) {
            State current = open_set.top();
            open_set.pop();

            // Check if goal reached
            if (distance(current, goal) < 0.5 &&
                std::abs(current.theta - goal.theta) < 0.1) {
                return current.path;
            }

            // Expand with motion primitives
            for (const auto& next_state : generate_successors(current)) {
                if (!is_collision_free(next_state, obstacle_map)) {
                    continue;
                }

                // Calculate costs
                double tentative_g = current.g_cost + distance(current, next_state);

                State new_state = next_state;
                new_state.g_cost = tentative_g;
                new_state.h_cost = heuristic(next_state, goal);
                new_state.path = current.path;
                new_state.path.push_back(current);

                open_set.push(new_state);
            }
        }

        return {};  // No path found
    }

private:
    VehicleParams params_;

    std::vector<State> generate_successors(const State& current) {
        std::vector<State> successors;

        // Motion primitives: different steering angles
        std::vector<double> steering_angles = {
            -params_.max_steering_angle,
            -params_.max_steering_angle / 2,
            0.0,
            params_.max_steering_angle / 2,
            params_.max_steering_angle
        };

        double dt = 0.5;  // Time step
        double v = 5.0;   // Velocity (m/s)

        for (double delta : steering_angles) {
            State next;

            // Bicycle model kinematics
            next.x = current.x + v * std::cos(current.theta) * dt;
            next.y = current.y + v * std::sin(current.theta) * dt;
            next.theta = current.theta + (v / params_.wheelbase) * std::tan(delta) * dt;

            // Normalize angle
            next.theta = std::atan2(std::sin(next.theta), std::cos(next.theta));

            successors.push_back(next);
        }

        return successors;
    }

    double heuristic(const State& state, const State& goal) {
        // Non-holonomic heuristic (Reeds-Shepp distance approximation)
        double dx = goal.x - state.x;
        double dy = goal.y - state.y;
        return std::sqrt(dx*dx + dy*dy);
    }

    double distance(const State& s1, const State& s2) {
        double dx = s2.x - s1.x;
        double dy = s2.y - s1.y;
        return std::sqrt(dx*dx + dy*dy);
    }

    bool is_collision_free(const State& state,
                          const std::vector<std::vector<double>>& obstacle_map) {
        // Check collision with obstacle map
        // Simplified: check if state position is in free space
        int x_idx = static_cast<int>(state.x);
        int y_idx = static_cast<int>(state.y);

        if (x_idx < 0 || x_idx >= obstacle_map.size() ||
            y_idx < 0 || y_idx >= obstacle_map[0].size()) {
            return false;
        }

        return obstacle_map[x_idx][y_idx] < 0.5;
    }
};
```

## Model Predictive Control (MPC)

```cpp
#include <Eigen/Dense>
#include <vector>
#include <qpOASES.hpp>

class MPCController {
public:
    struct MPCParams {
        int horizon = 20;           // Prediction horizon
        double dt = 0.1;            // Time step (100ms)
        double wheelbase = 2.7;     // meters

        // Cost weights
        double q_cte = 100.0;       // Cross-track error
        double q_epsi = 100.0;      // Heading error
        double q_v = 1.0;           // Velocity error
        double r_delta = 100.0;     // Steering input
        double r_a = 10.0;          // Acceleration input
        double r_delta_d = 1000.0;  // Steering rate
        double r_a_d = 10.0;        // Acceleration rate
    };

    MPCController(const MPCParams& params) : params_(params) {}

    struct ControlOutput {
        double steering_angle;
        double acceleration;
        std::vector<double> predicted_x;
        std::vector<double> predicted_y;
    };

    ControlOutput solve(const Eigen::VectorXd& state,
                       const std::vector<double>& ref_x,
                       const std::vector<double>& ref_y,
                       const std::vector<double>& ref_psi,
                       const std::vector<double>& ref_v) {
        // State: [x, y, psi, v, cte, epsi]
        // Inputs: [delta, a]

        int n_states = 6;
        int n_inputs = 2;
        int N = params_.horizon;

        int n_vars = n_states * N + n_inputs * (N - 1);
        int n_constraints = n_states * N;

        // Setup QP problem: min 0.5 * x^T * H * x + g^T * x
        //                   s.t. lbA <= A * x <= ubA
        //                        lb <= x <= ub

        Eigen::MatrixXd H = Eigen::MatrixXd::Zero(n_vars, n_vars);
        Eigen::VectorXd g = Eigen::VectorXd::Zero(n_vars);

        // Build cost function
        for (int t = 0; t < N; ++t) {
            // State costs
            H(t * n_states + 4, t * n_states + 4) = params_.q_cte;  // cte
            H(t * n_states + 5, t * n_states + 5) = params_.q_epsi; // epsi
            H(t * n_states + 3, t * n_states + 3) = params_.q_v;    // v

            if (t < N - 1) {
                // Input costs
                int delta_idx = N * n_states + t * n_inputs;
                int a_idx = delta_idx + 1;

                H(delta_idx, delta_idx) = params_.r_delta;
                H(a_idx, a_idx) = params_.r_a;

                // Input rate costs
                if (t < N - 2) {
                    int next_delta_idx = N * n_states + (t + 1) * n_inputs;
                    int next_a_idx = next_delta_idx + 1;

                    H(delta_idx, delta_idx) += params_.r_delta_d;
                    H(delta_idx, next_delta_idx) = -params_.r_delta_d;
                    H(next_delta_idx, delta_idx) = -params_.r_delta_d;
                    H(next_delta_idx, next_delta_idx) += params_.r_delta_d;

                    H(a_idx, a_idx) += params_.r_a_d;
                    H(a_idx, next_a_idx) = -params_.r_a_d;
                    H(next_a_idx, a_idx) = -params_.r_a_d;
                    H(next_a_idx, next_a_idx) += params_.r_a_d;
                }
            }
        }

        // Setup constraints (vehicle dynamics)
        Eigen::MatrixXd A = Eigen::MatrixXd::Zero(n_constraints, n_vars);
        Eigen::VectorXd lbA = Eigen::VectorXd::Zero(n_constraints);
        Eigen::VectorXd ubA = Eigen::VectorXd::Zero(n_constraints);

        // Initial state constraint
        for (int i = 0; i < n_states; ++i) {
            A(i, i) = 1.0;
            lbA(i) = state(i);
            ubA(i) = state(i);
        }

        // Dynamics constraints
        for (int t = 1; t < N; ++t) {
            // x_{t+1} = x_t + v_t * cos(psi_t) * dt
            A(t * n_states + 0, (t-1) * n_states + 0) = 1.0;  // x_t
            A(t * n_states + 0, t * n_states + 0) = -1.0;      // x_{t+1}
            // ... (complete dynamics implementation)
        }

        // Variable bounds
        Eigen::VectorXd lb = Eigen::VectorXd::Constant(n_vars, -1e9);
        Eigen::VectorXd ub = Eigen::VectorXd::Constant(n_vars, 1e9);

        // Steering angle limits
        for (int t = 0; t < N - 1; ++t) {
            int delta_idx = N * n_states + t * n_inputs;
            lb(delta_idx) = -0.6;  // -35 degrees
            ub(delta_idx) = 0.6;   // +35 degrees
        }

        // Acceleration limits
        for (int t = 0; t < N - 1; ++t) {
            int a_idx = N * n_states + t * n_inputs + 1;
            lb(a_idx) = -3.0;  // -3 m/s²
            ub(a_idx) = 2.0;   // +2 m/s²
        }

        // Solve QP using qpOASES
        qpOASES::QProblem qp(n_vars, n_constraints);
        qpOASES::Options options;
        options.printLevel = qpOASES::PL_NONE;
        qp.setOptions(options);

        int nWSR = 100;  // Max working set recalculations
        qp.init(H.data(), g.data(), A.data(), lb.data(), ub.data(),
               lbA.data(), ubA.data(), nWSR);

        Eigen::VectorXd solution(n_vars);
        qp.getPrimalSolution(solution.data());

        // Extract control inputs
        ControlOutput output;
        output.steering_angle = solution(N * n_states);
        output.acceleration = solution(N * n_states + 1);

        // Extract predicted trajectory
        for (int t = 0; t < N; ++t) {
            output.predicted_x.push_back(solution(t * n_states + 0));
            output.predicted_y.push_back(solution(t * n_states + 1));
        }

        return output;
    }

private:
    MPCParams params_;
};
```

## Pure Pursuit Controller

```cpp
#include <Eigen/Dense>
#include <vector>
#include <cmath>

class PurePursuitController {
public:
    PurePursuitController(double wheelbase, double lookahead_distance)
        : wheelbase_(wheelbase), lookahead_distance_(lookahead_distance) {}

    double compute_steering_angle(const Eigen::Vector3d& vehicle_state,
                                  const std::vector<Eigen::Vector2d>& path) {
        // vehicle_state: [x, y, heading]

        // Find lookahead point on path
        Eigen::Vector2d lookahead_point = find_lookahead_point(vehicle_state, path);

        // Transform lookahead point to vehicle frame
        double dx = lookahead_point.x() - vehicle_state.x();
        double dy = lookahead_point.y() - vehicle_state.y();

        double alpha = std::atan2(dy, dx) - vehicle_state.z();

        // Pure pursuit formula
        double steering_angle = std::atan2(2.0 * wheelbase_ * std::sin(alpha),
                                          lookahead_distance_);

        return steering_angle;
    }

private:
    double wheelbase_;
    double lookahead_distance_;

    Eigen::Vector2d find_lookahead_point(const Eigen::Vector3d& vehicle_state,
                                        const std::vector<Eigen::Vector2d>& path) {
        Eigen::Vector2d vehicle_pos(vehicle_state.x(), vehicle_state.y());

        // Find closest point on path
        double min_dist = std::numeric_limits<double>::max();
        size_t closest_idx = 0;

        for (size_t i = 0; i < path.size(); ++i) {
            double dist = (path[i] - vehicle_pos).norm();
            if (dist < min_dist) {
                min_dist = dist;
                closest_idx = i;
            }
        }

        // Search ahead for lookahead point
        for (size_t i = closest_idx; i < path.size(); ++i) {
            double dist = (path[i] - vehicle_pos).norm();
            if (dist >= lookahead_distance_) {
                return path[i];
            }
        }

        // Return last point if lookahead not found
        return path.back();
    }
};
```

## Stanley Controller

```cpp
class StanleyController {
public:
    StanleyController(double wheelbase, double k_e = 0.5, double k_v = 1.0)
        : wheelbase_(wheelbase), k_e_(k_e), k_v_(k_v) {}

    double compute_steering_angle(const Eigen::Vector3d& vehicle_state,
                                  double velocity,
                                  const std::vector<Eigen::Vector2d>& path) {
        // Find closest point on path
        auto [cte, heading_error] = compute_errors(vehicle_state, path);

        // Stanley law
        double steering_angle = heading_error +
                              std::atan2(k_e_ * cte, k_v_ + velocity);

        return steering_angle;
    }

private:
    double wheelbase_;
    double k_e_;  // Cross-track error gain
    double k_v_;  // Velocity gain

    std::pair<double, double> compute_errors(const Eigen::Vector3d& vehicle_state,
                                            const std::vector<Eigen::Vector2d>& path) {
        // Find closest point and compute cross-track error
        Eigen::Vector2d vehicle_pos(vehicle_state.x(), vehicle_state.y());

        double min_dist = std::numeric_limits<double>::max();
        size_t closest_idx = 0;

        for (size_t i = 0; i < path.size() - 1; ++i) {
            Eigen::Vector2d segment = path[i+1] - path[i];
            Eigen::Vector2d to_vehicle = vehicle_pos - path[i];

            double t = std::clamp(to_vehicle.dot(segment) / segment.squaredNorm(), 0.0, 1.0);
            Eigen::Vector2d closest_pt = path[i] + t * segment;

            double dist = (vehicle_pos - closest_pt).norm();
            if (dist < min_dist) {
                min_dist = dist;
                closest_idx = i;
            }
        }

        // Cross-track error (signed)
        Eigen::Vector2d segment = path[closest_idx + 1] - path[closest_idx];
        Eigen::Vector2d to_vehicle = vehicle_pos - path[closest_idx];

        double cross = segment.x() * to_vehicle.y() - segment.y() * to_vehicle.x();
        double cte = (cross > 0) ? min_dist : -min_dist;

        // Heading error
        double path_heading = std::atan2(segment.y(), segment.x());
        double heading_error = path_heading - vehicle_state.z();

        // Normalize to [-π, π]
        while (heading_error > M_PI) heading_error -= 2 * M_PI;
        while (heading_error < -M_PI) heading_error += 2 * M_PI;

        return {cte, heading_error};
    }
};
```

## Behavior Planning (Finite State Machine)

```cpp
#include <string>
#include <map>
#include <functional>

class BehaviorPlanner {
public:
    enum class State {
        LANE_KEEPING,
        LANE_CHANGE_LEFT,
        LANE_CHANGE_RIGHT,
        ADAPTIVE_CRUISE,
        EMERGENCY_BRAKE
    };

    BehaviorPlanner() : current_state_(State::LANE_KEEPING) {}

    State update(const SceneContext& context) {
        // State transition logic
        switch (current_state_) {
            case State::LANE_KEEPING:
                if (context.left_lane_clear && context.should_overtake) {
                    current_state_ = State::LANE_CHANGE_LEFT;
                } else if (context.leading_vehicle_distance < 50.0) {
                    current_state_ = State::ADAPTIVE_CRUISE;
                }
                break;

            case State::ADAPTIVE_CRUISE:
                if (context.leading_vehicle_distance < 10.0 &&
                    context.leading_vehicle_velocity < context.ego_velocity * 0.5) {
                    current_state_ = State::EMERGENCY_BRAKE;
                } else if (context.leading_vehicle_distance > 70.0) {
                    current_state_ = State::LANE_KEEPING;
                }
                break;

            case State::LANE_CHANGE_LEFT:
                if (context.lane_change_complete) {
                    current_state_ = State::LANE_KEEPING;
                }
                break;

            // ... other transitions
        }

        return current_state_;
    }

    struct SceneContext {
        double ego_velocity;
        double leading_vehicle_distance;
        double leading_vehicle_velocity;
        bool left_lane_clear;
        bool right_lane_clear;
        bool should_overtake;
        bool lane_change_complete;
        bool emergency_detected;
    };

private:
    State current_state_;
};
```

## Performance Targets

- **Path Planning**: < 100ms for 100m horizon
- **MPC**: < 50ms solve time (20-step horizon)
- **Control Loop**: 10-50 Hz (AUTOSAR compliant)
- **Trajectory Smoothness**: Jerk < 2 m/s³

## Standards

- **ISO 26262**: ASIL D for planning/control
- **ISO 22179**: Full-speed ACC requirements
- **SAE J3016**: L2-L5 automation levels

## Related Skills

- sensor-fusion-perception.md
- adas-features-implementation.md
- hd-maps-localization.md

---

## Radar Lidar Processing

# Radar & Lidar Processing for ADAS

## Overview

Radar signal processing (FMCW, chirp, range-Doppler), lidar point cloud processing, SLAM, occupancy grids, and clustering algorithms for ADAS perception.

## Radar Processing

### FMCW Radar Signal Processing

```matlab
% FMCW Radar Parameter Setup
c = 3e8;                    % Speed of light (m/s)
fc = 77e9;                  % Carrier frequency (77 GHz)
B = 150e6;                  % Bandwidth (150 MHz)
T_chirp = 40e-6;            % Chirp duration (40 μs)
slope = B / T_chirp;        % Chirp slope (Hz/s)

% Range resolution
range_res = c / (2 * B);    % ~1 meter

% Maximum range
max_range = c * T_chirp / (4 * B);  % ~40 meters (unambiguous)

% Doppler resolution
num_chirps = 256;
doppler_res = c / (2 * fc * T_chirp * num_chirps);

fprintf('Range Resolution: %.2f m\n', range_res);
fprintf('Velocity Resolution: %.2f m/s\n', doppler_res);
```

```cpp
#include <vector>
#include <complex>
#include <Eigen/Dense>
#include <fftw3.h>

class FMCWRadarProcessor {
public:
    struct RadarConfig {
        double carrier_freq = 77e9;     // 77 GHz
        double bandwidth = 150e6;       // 150 MHz
        double chirp_duration = 40e-6;  // 40 μs
        int num_samples = 256;
        int num_chirps = 256;
        int num_rx_antennas = 4;
        double sample_rate = 10e6;      // 10 MHz ADC
    };

    struct Detection {
        double range;           // meters
        double velocity;        // m/s
        double angle;           // radians
        double rcs;             // radar cross section (dBsm)
        double snr;             // signal-to-noise ratio (dB)
    };

    FMCWRadarProcessor(const RadarConfig& config) : config_(config) {
        range_res_ = SPEED_OF_LIGHT / (2 * config_.bandwidth);
        max_range_ = SPEED_OF_LIGHT * config_.chirp_duration / (4 * config_.bandwidth);
        vel_res_ = SPEED_OF_LIGHT / (2 * config_.carrier_freq *
                                     config_.chirp_duration * config_.num_chirps);

        // Allocate FFTW plans
        setup_fft_plans();
    }

    std::vector<Detection> process_frame(const std::vector<std::vector<std::complex<double>>>& raw_data) {
        // raw_data: [num_chirps][num_samples] complex samples from ADC

        // Step 1: Range FFT (per chirp)
        auto range_fft = compute_range_fft(raw_data);

        // Step 2: Doppler FFT (across chirps)
        auto range_doppler = compute_doppler_fft(range_fft);

        // Step 3: CFAR detection (Constant False Alarm Rate)
        auto detections_2d = cfar_detection(range_doppler);

        // Step 4: Angle estimation (using multiple RX antennas)
        auto detections_3d = estimate_angles(detections_2d, raw_data);

        return detections_3d;
    }

private:
    RadarConfig config_;
    double range_res_;
    double max_range_;
    double vel_res_;
    static constexpr double SPEED_OF_LIGHT = 3e8;

    fftw_plan fft_plan_range_;
    fftw_plan fft_plan_doppler_;

    void setup_fft_plans() {
        // Allocate and plan FFTs for efficiency
        fftw_complex *in = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * config_.num_samples);
        fftw_complex *out = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * config_.num_samples);

        fft_plan_range_ = fftw_plan_dft_1d(config_.num_samples, in, out,
                                          FFTW_FORWARD, FFTW_ESTIMATE);

        fftw_complex *in_doppler = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * config_.num_chirps);
        fftw_complex *out_doppler = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * config_.num_chirps);

        fft_plan_doppler_ = fftw_plan_dft_1d(config_.num_chirps, in_doppler, out_doppler,
                                            FFTW_FORWARD, FFTW_ESTIMATE);
    }

    Eigen::MatrixXcd compute_range_fft(const std::vector<std::vector<std::complex<double>>>& data) {
        int num_chirps = data.size();
        int num_samples = data[0].size();

        Eigen::MatrixXcd range_fft(num_chirps, num_samples);

        for (int chirp = 0; chirp < num_chirps; ++chirp) {
            // Apply window (Hanning)
            std::vector<std::complex<double>> windowed(num_samples);
            for (int i = 0; i < num_samples; ++i) {
                double window = 0.5 * (1 - std::cos(2 * M_PI * i / num_samples));
                windowed[i] = data[chirp][i] * window;
            }

            // Compute FFT
            fftw_complex *in = reinterpret_cast<fftw_complex*>(windowed.data());
            fftw_complex *out = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * num_samples);

            fftw_execute_dft(fft_plan_range_, in, out);

            for (int i = 0; i < num_samples; ++i) {
                range_fft(chirp, i) = std::complex<double>(out[i][0], out[i][1]);
            }

            fftw_free(out);
        }

        return range_fft;
    }

    Eigen::MatrixXcd compute_doppler_fft(const Eigen::MatrixXcd& range_fft) {
        int num_chirps = range_fft.rows();
        int num_range_bins = range_fft.cols();

        Eigen::MatrixXcd range_doppler(num_chirps, num_range_bins);

        for (int range_bin = 0; range_bin < num_range_bins; ++range_bin) {
            // Extract column (doppler dimension)
            std::vector<std::complex<double>> doppler_data(num_chirps);
            for (int chirp = 0; chirp < num_chirps; ++chirp) {
                doppler_data[chirp] = range_fft(chirp, range_bin);
            }

            // Apply window
            for (int i = 0; i < num_chirps; ++i) {
                double window = 0.5 * (1 - std::cos(2 * M_PI * i / num_chirps));
                doppler_data[i] *= window;
            }

            // Compute FFT
            fftw_complex *in = reinterpret_cast<fftw_complex*>(doppler_data.data());
            fftw_complex *out = (fftw_complex*)fftw_malloc(sizeof(fftw_complex) * num_chirps);

            fftw_execute_dft(fft_plan_doppler_, in, out);

            for (int i = 0; i < num_chirps; ++i) {
                range_doppler(i, range_bin) = std::complex<double>(out[i][0], out[i][1]);
            }

            fftw_free(out);
        }

        return range_doppler;
    }

    std::vector<Detection> cfar_detection(const Eigen::MatrixXcd& range_doppler) {
        // CA-CFAR (Cell Averaging - Constant False Alarm Rate)
        const int guard_cells = 4;
        const int training_cells = 12;
        const double pfa = 1e-6;  // Probability of false alarm

        // CFAR threshold factor
        double alpha = training_cells * (std::pow(pfa, -1.0 / training_cells) - 1);

        std::vector<Detection> detections;

        int num_doppler = range_doppler.rows();
        int num_range = range_doppler.cols();

        // Compute magnitude squared (power)
        Eigen::MatrixXd power(num_doppler, num_range);
        for (int i = 0; i < num_doppler; ++i) {
            for (int j = 0; j < num_range; ++j) {
                power(i, j) = std::norm(range_doppler(i, j));
            }
        }

        // 2D CFAR detection
        for (int d = guard_cells + training_cells; d < num_doppler - guard_cells - training_cells; ++d) {
            for (int r = guard_cells + training_cells; r < num_range - guard_cells - training_cells; ++r) {
                // Compute noise estimate (average of training cells)
                double noise_sum = 0.0;
                int count = 0;

                for (int dd = -training_cells - guard_cells; dd <= training_cells + guard_cells; ++dd) {
                    for (int rr = -training_cells - guard_cells; rr <= training_cells + guard_cells; ++rr) {
                        if (std::abs(dd) > guard_cells || std::abs(rr) > guard_cells) {
                            noise_sum += power(d + dd, r + rr);
                            count++;
                        }
                    }
                }

                double noise_level = noise_sum / count;
                double threshold = alpha * noise_level;

                // Detection
                if (power(d, r) > threshold) {
                    Detection det;
                    det.range = r * range_res_;
                    det.velocity = (d - num_doppler / 2) * vel_res_;
                    det.snr = 10 * std::log10(power(d, r) / noise_level);

                    // Estimate RCS
                    det.rcs = compute_rcs(power(d, r), det.range);

                    detections.push_back(det);
                }
            }
        }

        return detections;
    }

    std::vector<Detection> estimate_angles(const std::vector<Detection>& detections_2d,
                                          const std::vector<std::vector<std::complex<double>>>& raw_data) {
        // Use MUSIC or beamforming for angle estimation with multiple RX antennas
        std::vector<Detection> detections_3d = detections_2d;

        // For each detection, estimate angle of arrival
        for (auto& det : detections_3d) {
            det.angle = estimate_aoa_music(det, raw_data);
        }

        return detections_3d;
    }

    double estimate_aoa_music(const Detection& det,
                             const std::vector<std::vector<std::complex<double>>>& raw_data) {
        // MUSIC algorithm for angle estimation
        // Simplified: assume uniform linear array

        // Extract signals from all RX antennas for this detection
        // [Implementation of MUSIC algorithm]

        // Placeholder: return 0 angle
        return 0.0;
    }

    double compute_rcs(double power, double range) {
        // Radar equation: RCS estimation
        // RCS = (Power_rx * (4π)^3 * R^4) / (Power_tx * G_tx * G_rx * λ^2)

        // Simplified model
        double lambda = SPEED_OF_LIGHT / config_.carrier_freq;
        double rcs_linear = power * std::pow(range, 4) / std::pow(lambda, 2);
        double rcs_dbsm = 10 * std::log10(rcs_linear);

        return rcs_dbsm;
    }
};
```

## Lidar Point Cloud Processing

### Point Cloud Preprocessing

```cpp
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <pcl/filters/voxel_grid.h>
#include <pcl/filters/passthrough.h>
#include <pcl/segmentation/extract_clusters.h>
#include <pcl/segmentation/sac_segmentation.h>
#include <pcl/filters/extract_indices.h>

class LidarProcessor {
public:
    using PointT = pcl::PointXYZI;
    using PointCloudT = pcl::PointCloud<PointT>;

    LidarProcessor() {
        // Voxel grid filter for downsampling
        voxel_filter_.setLeafSize(0.1f, 0.1f, 0.1f);  // 10cm voxels

        // PassThrough filter for ROI
        pass_filter_x_.setFilterFieldName("x");
        pass_filter_x_.setFilterLimits(0.0, 100.0);  // 0-100m forward

        pass_filter_y_.setFilterFieldName("y");
        pass_filter_y_.setFilterLimits(-25.0, 25.0);  // ±25m lateral

        pass_filter_z_.setFilterFieldName("z");
        pass_filter_z_.setFilterLimits(-2.0, 5.0);    // -2m to 5m height

        // Ground plane segmentation
        ground_segmenter_.setOptimizeCoefficients(true);
        ground_segmenter_.setModelType(pcl::SACMODEL_PLANE);
        ground_segmenter_.setMethodType(pcl::SAC_RANSAC);
        ground_segmenter_.setMaxIterations(100);
        ground_segmenter_.setDistanceThreshold(0.1);  // 10cm

        // Euclidean clustering
        cluster_extractor_.setClusterTolerance(0.5);  // 50cm
        cluster_extractor_.setMinClusterSize(10);
        cluster_extractor_.setMaxClusterSize(10000);
    }

    struct ProcessedCloud {
        PointCloudT::Ptr ground;
        PointCloudT::Ptr obstacles;
        std::vector<PointCloudT::Ptr> clusters;
    };

    ProcessedCloud process(const PointCloudT::Ptr& input_cloud) {
        ProcessedCloud result;

        // Step 1: Downsample
        PointCloudT::Ptr cloud_filtered(new PointCloudT);
        voxel_filter_.setInputCloud(input_cloud);
        voxel_filter_.filter(*cloud_filtered);

        // Step 2: ROI filtering
        pass_filter_x_.setInputCloud(cloud_filtered);
        pass_filter_x_.filter(*cloud_filtered);

        pass_filter_y_.setInputCloud(cloud_filtered);
        pass_filter_y_.filter(*cloud_filtered);

        pass_filter_z_.setInputCloud(cloud_filtered);
        pass_filter_z_.filter(*cloud_filtered);

        // Step 3: Ground plane removal
        auto [ground, obstacles] = remove_ground_plane(cloud_filtered);
        result.ground = ground;
        result.obstacles = obstacles;

        // Step 4: Clustering
        result.clusters = cluster_obstacles(obstacles);

        return result;
    }

private:
    pcl::VoxelGrid<PointT> voxel_filter_;
    pcl::PassThrough<PointT> pass_filter_x_, pass_filter_y_, pass_filter_z_;
    pcl::SACSegmentation<PointT> ground_segmenter_;
    pcl::EuclideanClusterExtraction<PointT> cluster_extractor_;

    std::pair<PointCloudT::Ptr, PointCloudT::Ptr> remove_ground_plane(
        const PointCloudT::Ptr& cloud)
    {
        pcl::ModelCoefficients::Ptr coefficients(new pcl::ModelCoefficients);
        pcl::PointIndices::Ptr inliers(new pcl::PointIndices);

        ground_segmenter_.setInputCloud(cloud);
        ground_segmenter_.segment(*inliers, *coefficients);

        // Extract ground points
        PointCloudT::Ptr ground(new PointCloudT);
        pcl::ExtractIndices<PointT> extract;
        extract.setInputCloud(cloud);
        extract.setIndices(inliers);
        extract.setNegative(false);
        extract.filter(*ground);

        // Extract obstacle points (non-ground)
        PointCloudT::Ptr obstacles(new PointCloudT);
        extract.setNegative(true);
        extract.filter(*obstacles);

        return {ground, obstacles};
    }

    std::vector<PointCloudT::Ptr> cluster_obstacles(const PointCloudT::Ptr& obstacles) {
        // Create KD-tree for efficient nearest neighbor search
        pcl::search::KdTree<PointT>::Ptr tree(new pcl::search::KdTree<PointT>);
        tree->setInputCloud(obstacles);

        std::vector<pcl::PointIndices> cluster_indices;
        cluster_extractor_.setSearchMethod(tree);
        cluster_extractor_.setInputCloud(obstacles);
        cluster_extractor_.extract(cluster_indices);

        // Extract individual clusters
        std::vector<PointCloudT::Ptr> clusters;
        for (const auto& indices : cluster_indices) {
            PointCloudT::Ptr cluster(new PointCloudT);
            for (int idx : indices.indices) {
                cluster->points.push_back(obstacles->points[idx]);
            }
            cluster->width = cluster->points.size();
            cluster->height = 1;
            cluster->is_dense = true;

            clusters.push_back(cluster);
        }

        return clusters;
    }
};
```

### Object Detection from Point Clouds

```python
import numpy as np
import open3d as o3d

class PointCloudObjectDetector:
    """
    Detect and classify objects from lidar point clouds
    """

    def __init__(self):
        self.min_points = 10
        self.max_points = 10000

    def detect_objects(self, point_cloud):
        """
        Detect bounding boxes for objects

        Args:
            point_cloud: open3d.geometry.PointCloud

        Returns:
            List of detected objects with bounding boxes
        """
        # Ground removal
        ground_plane, obstacles = self.remove_ground(point_cloud)

        # Clustering
        clusters = self.cluster_dbscan(obstacles)

        # Bounding box extraction
        objects = []
        for cluster in clusters:
            if len(cluster.points) < self.min_points:
                continue

            # Compute oriented bounding box
            obb = cluster.get_oriented_bounding_box()
            obb.color = (1, 0, 0)  # Red

            # Compute axis-aligned bounding box
            aabb = cluster.get_axis_aligned_bounding_box()

            # Extract features
            centroid = np.mean(np.asarray(cluster.points), axis=0)
            dimensions = obb.extent  # [length, width, height]

            # Classify based on dimensions
            obj_class = self.classify_object(dimensions)

            obj = {
                'point_cloud': cluster,
                'obb': obb,
                'aabb': aabb,
                'centroid': centroid,
                'dimensions': dimensions,
                'class': obj_class,
                'num_points': len(cluster.points)
            }

            objects.append(obj)

        return objects

    def remove_ground(self, pcd, distance_threshold=0.1):
        """Remove ground plane using RANSAC"""
        plane_model, inliers = pcd.segment_plane(
            distance_threshold=distance_threshold,
            ransac_n=3,
            num_iterations=1000
        )

        ground = pcd.select_by_index(inliers)
        obstacles = pcd.select_by_index(inliers, invert=True)

        return ground, obstacles

    def cluster_dbscan(self, pcd, eps=0.5, min_points=10):
        """Cluster points using DBSCAN"""
        labels = np.array(pcd.cluster_dbscan(eps=eps, min_points=min_points))

        max_label = labels.max()
        clusters = []

        for label in range(max_label + 1):
            cluster_indices = np.where(labels == label)[0]
            cluster = pcd.select_by_index(cluster_indices)

            if len(cluster.points) >= self.min_points and \
               len(cluster.points) <= self.max_points:
                clusters.append(cluster)

        return clusters

    def classify_object(self, dimensions):
        """
        Classify object based on bounding box dimensions

        Args:
            dimensions: [length, width, height] in meters

        Returns:
            Object class string
        """
        length, width, height = dimensions

        # Heuristic classification
        if height < 0.5:
            return "ground_object"
        elif height < 1.0 and length < 1.5:
            return "small_obstacle"
        elif height > 1.2 and length > 3.0 and width > 1.5:
            return "vehicle"
        elif height > 1.5 and length < 1.0:
            return "pedestrian"
        elif height > 1.0 and length < 2.0:
            return "bicycle"
        else:
            return "unknown"
```

### Lidar SLAM

```cpp
#include <pcl/registration/icp.h>
#include <pcl/registration/ndt.h>
#include <Eigen/Dense>

class LidarSLAM {
public:
    LidarSLAM() {
        // Initialize NDT (Normal Distributions Transform)
        ndt_.setTransformationEpsilon(0.01);
        ndt_.setStepSize(0.1);
        ndt_.setResolution(1.0);
        ndt_.setMaximumIterations(35);

        current_pose_ = Eigen::Matrix4f::Identity();
    }

    using PointT = pcl::PointXYZI;
    using PointCloudT = pcl::PointCloud<PointT>;

    struct SLAMResult {
        Eigen::Matrix4f pose;
        double fitness_score;
        bool converged;
    };

    SLAMResult process_scan(const PointCloudT::Ptr& scan) {
        SLAMResult result;

        if (!previous_scan_) {
            // First scan - initialize
            previous_scan_ = scan;
            result.pose = current_pose_;
            result.converged = true;
            result.fitness_score = 0.0;
            return result;
        }

        // Scan matching using NDT
        ndt_.setInputSource(scan);
        ndt_.setInputTarget(previous_scan_);

        PointCloudT::Ptr aligned(new PointCloudT);
        ndt_.align(*aligned, current_pose_);

        result.converged = ndt_.hasConverged();
        result.fitness_score = ndt_.getFitnessScore();

        if (result.converged) {
            // Update pose
            Eigen::Matrix4f transformation = ndt_.getFinalTransformation();
            current_pose_ = transformation * current_pose_;

            result.pose = current_pose_;

            // Update previous scan
            previous_scan_ = scan;
        } else {
            result.pose = current_pose_;
        }

        return result;
    }

    Eigen::Matrix4f get_current_pose() const {
        return current_pose_;
    }

private:
    pcl::NormalDistributionsTransform<PointT, PointT> ndt_;
    PointCloudT::Ptr previous_scan_;
    Eigen::Matrix4f current_pose_;
};
```

## Occupancy Grid Mapping

```cpp
#include <vector>
#include <cmath>

class OccupancyGrid {
public:
    OccupancyGrid(double resolution, double width, double height)
        : resolution_(resolution),
          width_(static_cast<int>(width / resolution)),
          height_(static_cast<int>(height / resolution))
    {
        grid_.resize(width_ * height_, 0.5);  // Initialize to unknown (0.5)
    }

    void update_with_pointcloud(const std::vector<Eigen::Vector2d>& points,
                               const Eigen::Vector2d& sensor_origin) {
        for (const auto& point : points) {
            // Ray trace from sensor to point
            auto cells = bresenham(sensor_origin, point);

            // Mark cells along ray as free
            for (size_t i = 0; i < cells.size() - 1; ++i) {
                update_cell(cells[i], -0.1);  // Free space
            }

            // Mark endpoint as occupied
            if (!cells.empty()) {
                update_cell(cells.back(), 0.3);  // Occupied
            }
        }
    }

    double get_occupancy(int x, int y) const {
        if (x < 0 || x >= width_ || y < 0 || y >= height_) {
            return 0.5;  // Unknown
        }
        return grid_[y * width_ + x];
    }

    std::vector<uint8_t> to_image() const {
        // Convert to grayscale image (0-255)
        std::vector<uint8_t> image(grid_.size());
        for (size_t i = 0; i < grid_.size(); ++i) {
            image[i] = static_cast<uint8_t>((1.0 - grid_[i]) * 255);
        }
        return image;
    }

private:
    double resolution_;  // meters per cell
    int width_, height_;  // cells
    std::vector<double> grid_;  // Occupancy probabilities [0, 1]

    void update_cell(const Eigen::Vector2i& cell, double log_odds) {
        int idx = cell.y() * width_ + cell.x();
        if (idx >= 0 && idx < static_cast<int>(grid_.size())) {
            // Log-odds update
            double current = grid_[idx];
            double current_log_odds = std::log(current / (1.0 - current));
            double new_log_odds = current_log_odds + log_odds;

            // Convert back to probability
            grid_[idx] = 1.0 / (1.0 + std::exp(-new_log_odds));

            // Clamp
            grid_[idx] = std::max(0.01, std::min(0.99, grid_[idx]));
        }
    }

    std::vector<Eigen::Vector2i> bresenham(const Eigen::Vector2d& start,
                                          const Eigen::Vector2d& end) {
        // Bresenham's line algorithm
        Eigen::Vector2i start_cell = world_to_grid(start);
        Eigen::Vector2i end_cell = world_to_grid(end);

        std::vector<Eigen::Vector2i> cells;

        int x0 = start_cell.x(), y0 = start_cell.y();
        int x1 = end_cell.x(), y1 = end_cell.y();

        int dx = std::abs(x1 - x0);
        int dy = std::abs(y1 - y0);
        int sx = (x0 < x1) ? 1 : -1;
        int sy = (y0 < y1) ? 1 : -1;
        int err = dx - dy;

        while (true) {
            cells.push_back(Eigen::Vector2i(x0, y0));

            if (x0 == x1 && y0 == y1) break;

            int e2 = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                x0 += sx;
            }
            if (e2 < dx) {
                err += dx;
                y0 += sy;
            }
        }

        return cells;
    }

    Eigen::Vector2i world_to_grid(const Eigen::Vector2d& world_pos) const {
        int x = static_cast<int>(world_pos.x() / resolution_ + width_ / 2);
        int y = static_cast<int>(world_pos.y() / resolution_ + height_ / 2);
        return Eigen::Vector2i(x, y);
    }
};
```

## ROS2 Integration

```python
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import PointCloud2, PointField
from geometry_msgs.msg import PoseStamped
import numpy as np

class RadarLidarFusionNode(Node):
    def __init__(self):
        super().__init__('radar_lidar_fusion')

        # Subscribers
        self.radar_sub = self.create_subscription(
            PointCloud2,
            '/radar/points',
            self.radar_callback,
            10
        )

        self.lidar_sub = self.create_subscription(
            PointCloud2,
            '/lidar/points',
            self.lidar_callback,
            10
        )

        # Publishers
        self.fused_pub = self.create_publisher(
            PointCloud2,
            '/fused/points',
            10
        )

        self.pose_pub = self.create_publisher(
            PoseStamped,
            '/slam/pose',
            10
        )

        self.get_logger().info('Radar-Lidar Fusion Node started')

    def radar_callback(self, msg):
        # Process radar data
        radar_points = self.pointcloud2_to_array(msg)
        # ... processing logic
        pass

    def lidar_callback(self, msg):
        # Process lidar data
        lidar_points = self.pointcloud2_to_array(msg)
        # ... processing logic
        pass

    def pointcloud2_to_array(self, cloud_msg):
        # Convert ROS PointCloud2 to numpy array
        # Implementation details...
        pass

def main(args=None):
    rclpy.init(args=args)
    node = RadarLidarFusionNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

## Performance Targets

- **Radar Processing**: 50ms per frame (77 GHz FMCW)
- **Lidar Processing**: 100ms per scan (128-channel, 10Hz)
- **SLAM Update**: < 200ms per scan
- **Occupancy Grid**: 10Hz update rate

## Standards

- **ISO 26262**: ASIL B-D for sensor processing
- **ISO 11898**: CAN communication for sensor data
- **AUTOSAR**: Radar/Lidar driver integration

## Related Skills

- sensor-fusion-perception.md
- camera-processing-vision.md
- hd-maps-localization.md

---

## Sensor Fusion Perception

# Sensor Fusion & Perception

## Overview

Multi-sensor fusion combining camera, radar, lidar, and ultrasonic sensors for robust environmental perception in ADAS and autonomous driving. Covers Kalman filters (EKF, UKF), particle filters, coordinate transformations, time synchronization, and early/late fusion strategies.

## Sensor Suite Architecture

### Typical L2-L5 Sensor Configuration

```
Vehicle Coordinate System (ISO 8855)
──────────────────────────────────────────
                  Front (X+)
                     ▲
        Camera ──────┼────── Camera
      (Wide FOV)     │     (Tele FOV)
                     │
    Radar ───────────┼─────────── Radar
   (77GHz)           │            (77GHz)
   Long Range        │         Long Range
                     │
        Lidar ───────┼─────── Lidar
       (128 Ch)      │        (128 Ch)
                     │
    Ultrasonic array (12-16 sensors)
   ──────────────────┼────────────────────
                     │
                Left (Y+)
```

### Sensor Characteristics Table

| Sensor | Range | FOV | Resolution | Weather | Velocity | Cost |
|--------|-------|-----|------------|---------|----------|------|
| **Camera** | 150m | 120° H | 0.1° | Poor | No | $ |
| **Radar** | 250m | 30° H | 1-2° | Excellent | Yes (Doppler) | $$ |
| **Lidar** | 200m | 360° | 0.1-0.2° | Poor-Medium | No | $$$$ |
| **Ultrasonic** | 5m | 120° | N/A | Excellent | No | $ |

## Fusion Architectures

### 1. Early Fusion (Raw Data Level)

```python
import numpy as np
from scipy.ndimage import convolve

class EarlyFusion:
    """
    Fuse raw sensor data before object detection
    Used for complementary sensors (camera + lidar for depth)
    """

    def fuse_camera_lidar(self, camera_image, lidar_pointcloud, calibration):
        """
        Project lidar points onto camera image to create RGB-D

        Args:
            camera_image: (H, W, 3) RGB image
            lidar_pointcloud: (N, 4) [x, y, z, intensity]
            calibration: Camera-Lidar extrinsic calibration

        Returns:
            rgbd_image: (H, W, 4) RGB + Depth
        """
        H, W = camera_image.shape[:2]
        depth_map = np.zeros((H, W), dtype=np.float32)

        # Project lidar points to camera coordinates
        points_cam = self.transform_to_camera(lidar_pointcloud[:, :3], calibration)

        # Filter points in front of camera
        mask = points_cam[:, 2] > 0
        points_cam = points_cam[mask]

        # Project to image plane
        pixels = self.project_to_image(points_cam, calibration.K)

        # Valid pixels
        valid = (pixels[:, 0] >= 0) & (pixels[:, 0] < W) & \
                (pixels[:, 1] >= 0) & (pixels[:, 1] < H)

        pixels = pixels[valid].astype(int)
        depths = points_cam[valid, 2]

        # Fill depth map (handle occlusions by keeping closest)
        for (u, v), d in zip(pixels, depths):
            if depth_map[v, u] == 0 or d < depth_map[v, u]:
                depth_map[v, u] = d

        # Inpaint missing depth values
        depth_map = self.inpaint_depth(depth_map)

        # Combine RGB + D
        rgbd = np.dstack([camera_image, depth_map])

        return rgbd

    def transform_to_camera(self, points, calibration):
        """Transform lidar points to camera coordinate system"""
        # Homogeneous coordinates
        ones = np.ones((points.shape[0], 1))
        points_h = np.hstack([points, ones])

        # Apply extrinsic transformation
        points_cam = (calibration.T_cam_lidar @ points_h.T).T

        return points_cam[:, :3]

    def project_to_image(self, points_cam, K):
        """Project 3D camera points to 2D image pixels"""
        # K is intrinsic matrix [3x3]
        pixels_h = (K @ points_cam.T).T
        pixels = pixels_h[:, :2] / pixels_h[:, 2:3]
        return pixels

    def inpaint_depth(self, depth_map, kernel_size=5):
        """Inpaint missing depth values using convolution"""
        mask = depth_map > 0
        kernel = np.ones((kernel_size, kernel_size)) / (kernel_size ** 2)

        # Iterative inpainting
        inpainted = depth_map.copy()
        for _ in range(3):
            inpainted = convolve(inpainted, kernel, mode='constant')
            inpainted[mask] = depth_map[mask]  # Keep original valid values

        return inpainted
```

### 2. Mid-Level Fusion (Feature Level)

```cpp
// Feature-level fusion: combine object detections from different sensors
#include <Eigen/Dense>
#include <vector>
#include <algorithm>

struct Detection {
    Eigen::Vector3d position;      // [x, y, z] in vehicle frame
    Eigen::Vector3d velocity;      // [vx, vy, vz]
    Eigen::Vector3d dimensions;    // [length, width, height]
    std::string object_class;      // "car", "pedestrian", etc.
    double confidence;             // 0-1
    std::string sensor_source;     // "camera", "radar", "lidar"
    Eigen::Matrix3d covariance;    // Position uncertainty
};

class MidLevelFusion {
public:
    std::vector<Detection> fuse_detections(
        const std::vector<Detection>& camera_detections,
        const std::vector<Detection>& radar_detections,
        const std::vector<Detection>& lidar_detections)
    {
        // Combine all detections
        std::vector<Detection> all_detections;
        all_detections.insert(all_detections.end(),
                            camera_detections.begin(), camera_detections.end());
        all_detections.insert(all_detections.end(),
                            radar_detections.begin(), radar_detections.end());
        all_detections.insert(all_detections.end(),
                            lidar_detections.begin(), lidar_detections.end());

        // Cluster detections that refer to same object
        std::vector<std::vector<Detection>> clusters = cluster_detections(all_detections);

        // Fuse each cluster into single detection
        std::vector<Detection> fused_detections;
        for (const auto& cluster : clusters) {
            if (!cluster.empty()) {
                fused_detections.push_back(fuse_cluster(cluster));
            }
        }

        return fused_detections;
    }

private:
    std::vector<std::vector<Detection>> cluster_detections(
        const std::vector<Detection>& detections)
    {
        const double DISTANCE_THRESHOLD = 2.0;  // 2 meters

        std::vector<std::vector<Detection>> clusters;
        std::vector<bool> assigned(detections.size(), false);

        for (size_t i = 0; i < detections.size(); ++i) {
            if (assigned[i]) continue;

            std::vector<Detection> cluster;
            cluster.push_back(detections[i]);
            assigned[i] = true;

            // Find nearby detections
            for (size_t j = i + 1; j < detections.size(); ++j) {
                if (assigned[j]) continue;

                double dist = (detections[i].position - detections[j].position).norm();

                if (dist < DISTANCE_THRESHOLD) {
                    // Check if same object type
                    if (is_compatible_class(detections[i].object_class,
                                          detections[j].object_class)) {
                        cluster.push_back(detections[j]);
                        assigned[j] = true;
                    }
                }
            }

            clusters.push_back(cluster);
        }

        return clusters;
    }

    Detection fuse_cluster(const std::vector<Detection>& cluster) {
        Detection fused;

        // Calculate weighted average based on confidence
        double total_weight = 0.0;
        Eigen::Vector3d weighted_position = Eigen::Vector3d::Zero();
        Eigen::Vector3d weighted_velocity = Eigen::Vector3d::Zero();

        for (const auto& det : cluster) {
            // Weight by confidence and sensor reliability
            double weight = det.confidence * get_sensor_weight(det.sensor_source);
            total_weight += weight;

            weighted_position += weight * det.position;
            weighted_velocity += weight * det.velocity;
        }

        fused.position = weighted_position / total_weight;
        fused.velocity = weighted_velocity / total_weight;

        // Take highest confidence classification
        double max_conf = 0.0;
        for (const auto& det : cluster) {
            if (det.confidence > max_conf) {
                max_conf = det.confidence;
                fused.object_class = det.object_class;
                fused.dimensions = det.dimensions;
            }
        }

        fused.confidence = std::min(1.0, max_conf * 1.2);  // Boost confidence for fused

        // Covariance intersection for combined uncertainty
        fused.covariance = covariance_intersection(cluster);

        return fused;
    }

    double get_sensor_weight(const std::string& sensor) {
        // Sensor reliability weights (can be adaptive based on conditions)
        if (sensor == "lidar") return 1.0;
        if (sensor == "radar") return 0.8;
        if (sensor == "camera") return 0.7;
        return 0.5;
    }

    bool is_compatible_class(const std::string& class1, const std::string& class2) {
        // Check if two classifications are compatible
        if (class1 == class2) return true;

        // Allow some flexibility (e.g., "car" and "vehicle")
        std::vector<std::string> vehicle_types = {"car", "truck", "van", "vehicle"};

        bool is_vehicle1 = std::find(vehicle_types.begin(), vehicle_types.end(), class1)
                          != vehicle_types.end();
        bool is_vehicle2 = std::find(vehicle_types.begin(), vehicle_types.end(), class2)
                          != vehicle_types.end();

        return is_vehicle1 && is_vehicle2;
    }

    Eigen::Matrix3d covariance_intersection(const std::vector<Detection>& cluster) {
        // Covariance intersection for combining uncertain estimates
        Eigen::Matrix3d P_inv = Eigen::Matrix3d::Zero();

        for (const auto& det : cluster) {
            P_inv += det.covariance.inverse();
        }

        return P_inv.inverse();
    }
};
```

### 3. Late Fusion (Track-to-Track)

```cpp
#include <Eigen/Dense>
#include <vector>

struct Track {
    int id;
    Eigen::Vector4d state;         // [x, y, vx, vy]
    Eigen::Matrix4d covariance;
    std::string object_class;
    double confidence;
    std::string source_sensor;
    uint64_t timestamp_us;
};

class LateFusion {
public:
    std::vector<Track> fuse_tracks(
        const std::vector<Track>& camera_tracks,
        const std::vector<Track>& radar_tracks,
        const std::vector<Track>& lidar_tracks)
    {
        std::vector<Track> all_tracks;
        all_tracks.insert(all_tracks.end(), camera_tracks.begin(), camera_tracks.end());
        all_tracks.insert(all_tracks.end(), radar_tracks.begin(), radar_tracks.end());
        all_tracks.insert(all_tracks.end(), lidar_tracks.begin(), lidar_tracks.end());

        // Track-to-track association
        auto associations = associate_tracks(all_tracks);

        // Fuse associated tracks
        std::vector<Track> fused_tracks;
        for (const auto& group : associations) {
            fused_tracks.push_back(fuse_track_group(group));
        }

        return fused_tracks;
    }

private:
    std::vector<std::vector<Track>> associate_tracks(const std::vector<Track>& tracks) {
        const double MAHALANOBIS_THRESHOLD = 9.21;  // Chi-square 99% @ 4D

        std::vector<std::vector<Track>> groups;
        std::vector<bool> assigned(tracks.size(), false);

        for (size_t i = 0; i < tracks.size(); ++i) {
            if (assigned[i]) continue;

            std::vector<Track> group;
            group.push_back(tracks[i]);
            assigned[i] = true;

            for (size_t j = i + 1; j < tracks.size(); ++j) {
                if (assigned[j]) continue;

                // Mahalanobis distance between tracks
                double dist = mahalanobis_distance(tracks[i], tracks[j]);

                if (dist < MAHALANOBIS_THRESHOLD) {
                    group.push_back(tracks[j]);
                    assigned[j] = true;
                }
            }

            groups.push_back(group);
        }

        return groups;
    }

    double mahalanobis_distance(const Track& t1, const Track& t2) {
        Eigen::Vector4d diff = t1.state - t2.state;
        Eigen::Matrix4d S = t1.covariance + t2.covariance;

        return std::sqrt(diff.transpose() * S.inverse() * diff);
    }

    Track fuse_track_group(const std::vector<Track>& group) {
        // Covariance intersection for track fusion
        Track fused;

        Eigen::Matrix4d P_inv = Eigen::Matrix4d::Zero();
        Eigen::Vector4d weighted_state = Eigen::Vector4d::Zero();

        for (const auto& track : group) {
            Eigen::Matrix4d P_inv_i = track.covariance.inverse();
            P_inv += P_inv_i;
            weighted_state += P_inv_i * track.state;
        }

        fused.covariance = P_inv.inverse();
        fused.state = fused.covariance * weighted_state;

        // Take highest confidence classification
        double max_conf = 0.0;
        for (const auto& track : group) {
            if (track.confidence > max_conf) {
                max_conf = track.confidence;
                fused.object_class = track.object_class;
                fused.source_sensor = track.source_sensor;
            }
        }

        fused.confidence = max_conf;
        fused.id = group[0].id;  // Use first track ID

        return fused;
    }
};
```

## Extended Kalman Filter (EKF)

### Complete EKF Implementation for Multi-Sensor Tracking

```cpp
#include <Eigen/Dense>
#include <cmath>

class ExtendedKalmanFilter {
public:
    ExtendedKalmanFilter() {
        // Initialize state: [x, y, vx, vy, ax, ay]
        state_ = Eigen::VectorXd::Zero(6);

        // Initialize covariance
        covariance_ = Eigen::MatrixXd::Identity(6, 6) * 1000.0;

        // Process noise
        Q_ = Eigen::MatrixXd::Identity(6, 6);
        Q_(0, 0) = 0.1;  // Position noise
        Q_(1, 1) = 0.1;
        Q_(2, 2) = 1.0;  // Velocity noise
        Q_(3, 3) = 1.0;
        Q_(4, 4) = 2.0;  // Acceleration noise
        Q_(5, 5) = 2.0;

        // Measurement noise covariances
        R_camera_ = Eigen::Matrix2d::Identity() * 0.5;      // 0.5m position uncertainty
        R_radar_ = Eigen::Matrix3d::Identity();
        R_radar_(0, 0) = 0.3;  // Range: 0.3m
        R_radar_(1, 1) = 0.5;  // Range rate: 0.5 m/s
        R_radar_(2, 2) = 0.02; // Azimuth: 0.02 rad

        R_lidar_ = Eigen::Matrix3d::Identity() * 0.2;       // 0.2m 3D position
    }

    void predict(double dt) {
        // State transition matrix F (constant acceleration model)
        Eigen::MatrixXd F = Eigen::MatrixXd::Identity(6, 6);
        F(0, 2) = dt;
        F(0, 4) = 0.5 * dt * dt;
        F(1, 3) = dt;
        F(1, 5) = 0.5 * dt * dt;
        F(2, 4) = dt;
        F(3, 5) = dt;

        // Predict state
        state_ = F * state_;

        // Predict covariance
        covariance_ = F * covariance_ * F.transpose() + Q_;
    }

    void update_camera(const Eigen::Vector2d& z_cam) {
        // Camera measurement model: H = [1 0 0 0 0 0]
        //                               [0 1 0 0 0 0]
        Eigen::MatrixXd H = Eigen::MatrixXd::Zero(2, 6);
        H(0, 0) = 1.0;
        H(1, 1) = 1.0;

        // Predicted measurement
        Eigen::Vector2d z_pred = H * state_;

        // Innovation
        Eigen::Vector2d y = z_cam - z_pred;

        // Innovation covariance
        Eigen::Matrix2d S = H * covariance_ * H.transpose() + R_camera_;

        // Kalman gain
        Eigen::MatrixXd K = covariance_ * H.transpose() * S.inverse();

        // Update state
        state_ = state_ + K * y;

        // Update covariance
        Eigen::MatrixXd I = Eigen::MatrixXd::Identity(6, 6);
        covariance_ = (I - K * H) * covariance_;
    }

    void update_radar(const Eigen::Vector3d& z_radar) {
        // Radar measurement: [range, range_rate, azimuth]
        // Non-linear measurement model - need Jacobian

        double px = state_(0);
        double py = state_(1);
        double vx = state_(2);
        double vy = state_(3);

        // Predicted measurement h(x)
        double rho = std::sqrt(px*px + py*py);
        double phi = std::atan2(py, px);
        double rho_dot = (px*vx + py*vy) / rho;

        Eigen::Vector3d z_pred;
        z_pred << rho, rho_dot, phi;

        // Measurement Jacobian H
        Eigen::MatrixXd H = Eigen::MatrixXd::Zero(3, 6);

        if (rho > 0.001) {  // Avoid division by zero
            H(0, 0) = px / rho;
            H(0, 1) = py / rho;

            H(1, 0) = vx / rho - (px * (px*vx + py*vy)) / (rho*rho*rho);
            H(1, 1) = vy / rho - (py * (px*vx + py*vy)) / (rho*rho*rho);
            H(1, 2) = px / rho;
            H(1, 3) = py / rho;

            H(2, 0) = -py / (rho*rho);
            H(2, 1) = px / (rho*rho);
        }

        // Innovation
        Eigen::Vector3d y = z_radar - z_pred;

        // Normalize angle to [-π, π]
        while (y(2) > M_PI) y(2) -= 2.0 * M_PI;
        while (y(2) < -M_PI) y(2) += 2.0 * M_PI;

        // Innovation covariance
        Eigen::Matrix3d S = H * covariance_ * H.transpose() + R_radar_;

        // Kalman gain
        Eigen::MatrixXd K = covariance_ * H.transpose() * S.inverse();

        // Update
        state_ = state_ + K * y;

        Eigen::MatrixXd I = Eigen::MatrixXd::Identity(6, 6);
        covariance_ = (I - K * H) * covariance_;
    }

    void update_lidar(const Eigen::Vector3d& z_lidar) {
        // Lidar measurement: [x, y, z] (3D position)
        Eigen::MatrixXd H = Eigen::MatrixXd::Zero(3, 6);
        H(0, 0) = 1.0;
        H(1, 1) = 1.0;
        // Assume z is observed but not in state (could extend state if needed)

        // For 2D tracking, only use x, y
        Eigen::Vector2d z_lidar_2d = z_lidar.head(2);
        Eigen::MatrixXd H_2d = H.topRows(2);

        Eigen::Vector2d z_pred = H_2d * state_;
        Eigen::Vector2d y = z_lidar_2d - z_pred;

        Eigen::Matrix2d S = H_2d * covariance_ * H_2d.transpose()
                          + R_lidar_.topLeftCorner(2, 2);

        Eigen::MatrixXd K = covariance_ * H_2d.transpose() * S.inverse();

        state_ = state_ + K * y;

        Eigen::MatrixXd I = Eigen::MatrixXd::Identity(6, 6);
        covariance_ = (I - K * H_2d) * covariance_;
    }

    Eigen::VectorXd get_state() const { return state_; }
    Eigen::MatrixXd get_covariance() const { return covariance_; }

private:
    Eigen::VectorXd state_;         // State vector [x, y, vx, vy, ax, ay]
    Eigen::MatrixXd covariance_;    // State covariance
    Eigen::MatrixXd Q_;             // Process noise covariance
    Eigen::Matrix2d R_camera_;      // Camera measurement noise
    Eigen::Matrix3d R_radar_;       // Radar measurement noise
    Eigen::Matrix3d R_lidar_;       // Lidar measurement noise
};
```

## Unscented Kalman Filter (UKF)

```cpp
#include <Eigen/Dense>
#include <vector>

class UnscentedKalmanFilter {
public:
    UnscentedKalmanFilter(int n_states, int n_aug)
        : n_x_(n_states), n_aug_(n_aug)
    {
        lambda_ = 3 - n_aug_;
        n_sigma_ = 2 * n_aug_ + 1;

        // Weights for sigma points
        weights_ = Eigen::VectorXd(n_sigma_);
        weights_(0) = lambda_ / (lambda_ + n_aug_);
        for (int i = 1; i < n_sigma_; ++i) {
            weights_(i) = 0.5 / (lambda_ + n_aug_);
        }

        // Initialize state and covariance
        x_ = Eigen::VectorXd::Zero(n_x_);
        P_ = Eigen::MatrixXd::Identity(n_x_, n_x_);
    }

    void predict(double dt) {
        // Create augmented sigma points
        Eigen::VectorXd x_aug = Eigen::VectorXd::Zero(n_aug_);
        x_aug.head(n_x_) = x_;

        Eigen::MatrixXd P_aug = Eigen::MatrixXd::Zero(n_aug_, n_aug_);
        P_aug.topLeftCorner(n_x_, n_x_) = P_;
        P_aug(n_x_, n_x_) = 1.0;  // Process noise variance
        P_aug(n_x_ + 1, n_x_ + 1) = 1.0;

        Eigen::MatrixXd Xsig_aug = generate_sigma_points(x_aug, P_aug);

        // Predict sigma points
        Eigen::MatrixXd Xsig_pred = Eigen::MatrixXd::Zero(n_x_, n_sigma_);
        for (int i = 0; i < n_sigma_; ++i) {
            Xsig_pred.col(i) = process_model(Xsig_aug.col(i), dt);
        }

        // Predict mean and covariance
        x_ = Xsig_pred * weights_;

        P_.setZero();
        for (int i = 0; i < n_sigma_; ++i) {
            Eigen::VectorXd x_diff = Xsig_pred.col(i) - x_;
            P_ += weights_(i) * x_diff * x_diff.transpose();
        }

        Xsig_pred_ = Xsig_pred;  // Store for update
    }

    void update_radar(const Eigen::Vector3d& z) {
        int n_z = 3;  // Radar measurement dimension

        // Transform sigma points to measurement space
        Eigen::MatrixXd Zsig = Eigen::MatrixXd::Zero(n_z, n_sigma_);
        for (int i = 0; i < n_sigma_; ++i) {
            Zsig.col(i) = measurement_model_radar(Xsig_pred_.col(i));
        }

        // Predicted measurement mean
        Eigen::Vector3d z_pred = Zsig * weights_;

        // Measurement covariance S
        Eigen::Matrix3d S = Eigen::Matrix3d::Zero();
        for (int i = 0; i < n_sigma_; ++i) {
            Eigen::Vector3d z_diff = Zsig.col(i) - z_pred;
            S += weights_(i) * z_diff * z_diff.transpose();
        }

        // Add measurement noise
        Eigen::Matrix3d R = Eigen::Matrix3d::Identity();
        R(0, 0) = 0.3;  // Range
        R(1, 1) = 0.5;  // Range rate
        R(2, 2) = 0.02; // Azimuth
        S += R;

        // Cross-correlation matrix
        Eigen::MatrixXd Tc = Eigen::MatrixXd::Zero(n_x_, n_z);
        for (int i = 0; i < n_sigma_; ++i) {
            Eigen::VectorXd x_diff = Xsig_pred_.col(i) - x_;
            Eigen::Vector3d z_diff = Zsig.col(i) - z_pred;
            Tc += weights_(i) * x_diff * z_diff.transpose();
        }

        // Kalman gain
        Eigen::MatrixXd K = Tc * S.inverse();

        // Update state
        Eigen::Vector3d z_diff = z - z_pred;
        x_ = x_ + K * z_diff;

        // Update covariance
        P_ = P_ - K * S * K.transpose();
    }

private:
    int n_x_;                       // State dimension
    int n_aug_;                     // Augmented dimension
    int n_sigma_;                   // Number of sigma points
    double lambda_;                 // Sigma point spreading parameter
    Eigen::VectorXd weights_;       // Weights for sigma points
    Eigen::VectorXd x_;             // State vector
    Eigen::MatrixXd P_;             // State covariance
    Eigen::MatrixXd Xsig_pred_;     // Predicted sigma points

    Eigen::MatrixXd generate_sigma_points(const Eigen::VectorXd& x,
                                         const Eigen::MatrixXd& P) {
        int n = x.size();
        Eigen::MatrixXd Xsig = Eigen::MatrixXd::Zero(n, 2 * n + 1);

        // Cholesky decomposition
        Eigen::MatrixXd L = P.llt().matrixL();

        // Central sigma point
        Xsig.col(0) = x;

        // Other sigma points
        double coef = std::sqrt(lambda_ + n);
        for (int i = 0; i < n; ++i) {
            Xsig.col(i + 1) = x + coef * L.col(i);
            Xsig.col(i + 1 + n) = x - coef * L.col(i);
        }

        return Xsig;
    }

    Eigen::VectorXd process_model(const Eigen::VectorXd& x_aug, double dt) {
        // Constant turn rate and velocity (CTRV) model
        double px = x_aug(0);
        double py = x_aug(1);
        double v = x_aug(2);
        double yaw = x_aug(3);
        double yawd = x_aug(4);
        double nu_a = x_aug(5);  // Process noise acceleration
        double nu_yawdd = x_aug(6);  // Process noise yaw acceleration

        Eigen::VectorXd x_pred = Eigen::VectorXd::Zero(n_x_);

        // Avoid division by zero
        if (std::abs(yawd) > 0.001) {
            x_pred(0) = px + v/yawd * (std::sin(yaw + yawd*dt) - std::sin(yaw));
            x_pred(1) = py + v/yawd * (-std::cos(yaw + yawd*dt) + std::cos(yaw));
        } else {
            x_pred(0) = px + v * std::cos(yaw) * dt;
            x_pred(1) = py + v * std::sin(yaw) * dt;
        }

        x_pred(2) = v;
        x_pred(3) = yaw + yawd * dt;
        x_pred(4) = yawd;

        // Add process noise
        x_pred(0) += 0.5 * dt * dt * std::cos(yaw) * nu_a;
        x_pred(1) += 0.5 * dt * dt * std::sin(yaw) * nu_a;
        x_pred(2) += dt * nu_a;
        x_pred(3) += 0.5 * dt * dt * nu_yawdd;
        x_pred(4) += dt * nu_yawdd;

        return x_pred;
    }

    Eigen::Vector3d measurement_model_radar(const Eigen::VectorXd& x) {
        double px = x(0);
        double py = x(1);
        double v = x(2);
        double yaw = x(3);

        double rho = std::sqrt(px*px + py*py);
        double phi = std::atan2(py, px);
        double rho_dot = (px * std::cos(yaw) * v + py * std::sin(yaw) * v) / rho;

        Eigen::Vector3d z;
        z << rho, rho_dot, phi;
        return z;
    }
};
```

## Time Synchronization

```cpp
#include <chrono>
#include <map>
#include <queue>

class SensorTimeSynchronizer {
public:
    struct SensorData {
        uint64_t timestamp_us;
        std::string sensor_id;
        // ... sensor-specific data
    };

    SensorTimeSynchronizer(uint64_t sync_window_us = 10000)  // 10ms window
        : sync_window_us_(sync_window_us) {}

    void add_measurement(const SensorData& data) {
        sensor_buffers_[data.sensor_id].push(data);
    }

    std::map<std::string, SensorData> get_synchronized_frame() {
        std::map<std::string, SensorData> synced_frame;

        if (sensor_buffers_.empty()) return synced_frame;

        // Find reference timestamp (usually camera frame time)
        uint64_t ref_time = get_reference_timestamp();

        // Extract measurements closest to reference time
        for (auto& [sensor_id, buffer] : sensor_buffers_) {
            while (!buffer.empty()) {
                auto& data = buffer.front();

                // Check if within sync window
                int64_t time_diff = std::abs(
                    static_cast<int64_t>(data.timestamp_us) -
                    static_cast<int64_t>(ref_time)
                );

                if (time_diff < sync_window_us_) {
                    synced_frame[sensor_id] = data;
                    buffer.pop();
                    break;
                }

                // Too old, discard
                if (data.timestamp_us < ref_time - sync_window_us_) {
                    buffer.pop();
                } else {
                    break;  // Future measurement, wait
                }
            }
        }

        return synced_frame;
    }

private:
    uint64_t sync_window_us_;
    std::map<std::string, std::queue<SensorData>> sensor_buffers_;

    uint64_t get_reference_timestamp() {
        // Use camera timestamp as reference (usually most accurate)
        if (sensor_buffers_.count("camera") &&
            !sensor_buffers_["camera"].empty()) {
            return sensor_buffers_["camera"].front().timestamp_us;
        }

        // Fallback to first available sensor
        for (const auto& [id, buffer] : sensor_buffers_) {
            if (!buffer.empty()) {
                return buffer.front().timestamp_us;
            }
        }

        return 0;
    }
};
```

## Performance Metrics

### Key Performance Indicators

- **Fusion Latency**: < 50ms end-to-end
- **Position Accuracy**: < 0.3m (95th percentile)
- **Velocity Accuracy**: < 0.5 m/s (95th percentile)
- **False Positive Rate**: < 0.01 per km
- **Miss Rate**: < 0.001 for safety-critical objects

## Standards Compliance

- **ISO 26262**: ASIL-D for safety-critical fusion
- **ISO 21448 (SOTIF)**: Scenario-based validation
- **ISO 23150**: Augmented reality coordination
- **SAE J3016**: Levels of automation (L0-L5)

## Related Skills

- camera-processing-vision.md
- radar-lidar-processing.md
- path-planning-control.md
- hd-maps-localization.md

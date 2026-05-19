# Autonomous Driving - Conceptual Architecture

## Modular vs End-to-End Approaches

The fundamental architectural decision in autonomous driving is whether to use a modular pipeline or an end-to-end learned system.

### Modular Pipeline Architecture

Decompose driving into independent modules with well-defined interfaces.

```
Sensors → Perception → Prediction → Planning → Control → Actuation
```

**Key Characteristics:**
- Each module is independently developed and tested
- Intermediate representations (object lists, trajectories) are human-interpretable
- Modules can be swapped or upgraded independently
- Clear failure attribution when things go wrong

**Advantages:**
- Mature engineering practices from robotics
- Easier to debug (inspect intermediate outputs)
- Leverages domain expertise (e.g., control theory for controller)
- Regulatory acceptance (explainable decisions)

**Disadvantages:**
- Information loss at module boundaries
- Cascading errors (mistakes propagate downstream)
- Sub-optimal end-to-end performance (local optimization)
- Manual interface design between modules

**Example Implementation:**
```python
class ModularADStack:
    def __init__(self):
        self.perception = PerceptionModule()      # Detects objects
        self.prediction = PredictionModule()      # Forecasts trajectories
        self.planning = PlanningModule()          # Plans ego trajectory
        self.control = ControlModule()            # Executes trajectory

    def step(self, sensor_data):
        # Perception
        objects = self.perception.process(sensor_data)

        # Prediction
        future_trajectories = self.prediction.predict(objects)

        # Planning
        ego_trajectory = self.planning.plan(objects, future_trajectories)

        # Control
        control_commands = self.control.execute(ego_trajectory)

        return control_commands
```

### End-to-End Learning Architecture

Single neural network maps directly from sensors to control commands.

```
Sensors → Deep Neural Network → Control Commands
```

**Key Characteristics:**
- Single model trained with imitation learning or reinforcement learning
- No intermediate representations (black box)
- Jointly optimizes all components for driving objective

**Advantages:**
- No information bottleneck (all sensor data available)
- Implicit learning of complex dependencies
- Potential for superhuman performance
- Simpler architecture (fewer moving parts)

**Disadvantages:**
- Requires massive amounts of training data
- Difficult to debug when failures occur
- Opaque decision-making (certification challenges)
- Catastrophic failures on out-of-distribution inputs

**Example Implementation:**
```python
class EndToEndADModel(nn.Module):
    def __init__(self):
        super().__init__()
        # Multi-camera encoding
        self.image_encoder = ResNet50(pretrained=True)

        # Temporal fusion
        self.temporal_model = nn.LSTM(2048, 512, num_layers=2)

        # Control decoder
        self.control_head = nn.Sequential(
            nn.Linear(512, 256),
            nn.ReLU(),
            nn.Linear(256, 3)  # [steering, throttle, brake]
        )

    def forward(self, image_sequence):
        """
        image_sequence: [B, T, C, H, W] - Batch of temporal image sequences
        """
        B, T = image_sequence.shape[:2]

        # Encode each frame
        features = []
        for t in range(T):
            feat = self.image_encoder(image_sequence[:, t])
            features.append(feat)
        features = torch.stack(features, dim=1)  # [B, T, 2048]

        # Temporal modeling
        lstm_out, _ = self.temporal_model(features)

        # Control prediction
        controls = self.control_head(lstm_out[:, -1])  # Use last timestep

        return controls  # [steering, throttle, brake]
```

### Hybrid Approaches

Most production systems use hybrid architectures combining learned and classical components.

**Pattern 1: Learned Perception + Classical Planning**
```
Sensors → [Neural Network Perception] → [Rule-Based Planner] → Control
```
- Leverages DL for perception (proven to work)
- Retains interpretable planning (safety critical)

**Pattern 2: Modular with Learned Components**
```
Sensors → [Learned Detector] → [Learned Predictor] → [MPC Planner] → [PID Control]
```
- Each module internally uses learning
- Maintains modular decomposition

**Pattern 3: End-to-End with Safety Layer**
```
Sensors → [E2E Neural Network] → [Safety Verifier] → Control
           ↓ (if unsafe)
       [Fallback Planner]
```
- Learned policy proposes actions
- Rule-based verifier ensures safety

## Perception-Prediction-Planning Interfaces

The information flow between modules defines the system architecture.

### Perception Output Format

Perception typically outputs a tracked object list:

```cpp
struct PerceivedObject {
    uint32_t track_id;              // Unique identifier
    ObjectClass classification;     // CAR, PEDESTRIAN, CYCLIST, etc.
    Eigen::Vector3d position;       // [x, y, z] in vehicle frame
    Eigen::Vector3d velocity;       // [vx, vy, vz] in vehicle frame
    Eigen::Vector3d dimensions;     // [length, width, height]
    Eigen::Quaterniond orientation; // 3D rotation
    Eigen::Matrix3d position_cov;   // Position uncertainty
    float classification_confidence;
    uint64_t timestamp_us;
};

struct PerceptionOutput {
    std::vector<PerceivedObject> objects;
    LaneGraph lane_network;         // Drivable area
    Pose vehicle_pose;              // Localization result
    OccupancyGrid free_space;       // Unoccupied regions
};
```

### Prediction Output Format

Prediction outputs multi-modal future trajectories:

```cpp
struct TrajectoryMode {
    std::vector<Eigen::Vector3d> waypoints;  // Future positions
    std::vector<double> timestamps;          // Time at each waypoint
    float probability;                       // Mode likelihood
    ManeuverType maneuver;                   // LANE_FOLLOW, LANE_CHANGE, TURN
};

struct PredictedObject {
    uint32_t track_id;                       // Matches perception track_id
    std::vector<TrajectoryMode> modes;       // Multiple possible futures
    Eigen::Vector3d current_position;
    Eigen::Vector3d current_velocity;
};

struct PredictionOutput {
    std::vector<PredictedObject> predictions;
    double prediction_horizon_s;             // How far into future
};
```

### Planning Output Format

Planning outputs the ego vehicle's intended trajectory:

```cpp
struct TrajectoryPoint {
    Eigen::Vector3d position;     // [x, y, z]
    Eigen::Vector3d velocity;     // [vx, vy, vz]
    Eigen::Vector3d acceleration; // [ax, ay, az]
    double curvature;             // For steering
    double timestamp_s;           // Time from now
};

struct PlannedTrajectory {
    std::vector<TrajectoryPoint> trajectory;
    ManeuverType maneuver;        // What we're doing
    float comfort_cost;           // Jerk, lateral accel
    float progress_cost;          // Distance to goal
    float safety_margin;          // Clearance to obstacles
};
```

## Operational Design Domain (ODD) Definition

The ODD specifies where the AD system can safely operate.

### ODD Specification Template

```yaml
geographic_constraints:
  regions: ["San Francisco, CA", "Phoenix, AZ"]
  road_types: ["urban_streets", "residential"]
  excluded_roads: ["highways", "unpaved"]
  map_version: "2026-Q1"

environmental_conditions:
  weather:
    allowed: ["clear", "light_rain"]
    prohibited: ["heavy_rain", "snow", "fog"]
  lighting:
    allowed: ["daylight", "civil_twilight", "well_lit_night"]
    min_illuminance_lux: 10
  visibility_range_m: ">100"

operational_constraints:
  speed_range_mph: [0, 35]
  traffic_density: ["low", "moderate"]
  time_of_day: "24/7"
  construction_zones: "prohibited"

vehicle_constraints:
  passenger_count: [0, 4]
  cargo_secured: true
  tire_condition: "good"
  sensor_health: "all_nominal"

fallback_conditions:
  min_safe_stop_distance_m: 50
  emergency_pull_over_lanes: ["right_shoulder", "parking_lane"]
  remote_assistance_available: true
```

### ODD Monitoring

Runtime monitoring ensures the vehicle stays within ODD:

```python
class ODDMonitor:
    def __init__(self, odd_spec):
        self.spec = odd_spec
        self.violations = []

    def check_compliance(self, vehicle_state, environment):
        compliant = True

        # Check speed
        if not self._in_range(vehicle_state.speed_mph, self.spec.speed_range):
            compliant = False
            self.violations.append("Speed out of ODD range")

        # Check weather
        if environment.weather not in self.spec.weather.allowed:
            compliant = False
            self.violations.append(f"Weather {environment.weather} not allowed")

        # Check sensor health
        for sensor in vehicle_state.sensors:
            if sensor.status != SensorStatus.NOMINAL:
                compliant = False
                self.violations.append(f"{sensor.name} degraded")

        # Check geographic boundary
        if not self._in_geofence(vehicle_state.position):
            compliant = False
            self.violations.append("Outside geofenced area")

        return compliant

    def request_transition_to_fallback(self):
        """Initiate minimal risk condition maneuver"""
        return FallbackRequest(
            reason=self.violations,
            target_state="SAFE_STOP",
            urgency="IMMEDIATE" if self._is_critical() else "GRADUAL"
        )
```

## Safety Envelope Concepts

The safety envelope defines the set of safe states and transitions.

### Responsibility-Sensitive Safety (RSS)

Intel/Mobileye's RSS model defines safe distances based on physical constraints.

**Longitudinal Safe Distance:**
```
d_safe = v_rear * t_react +
         (v_rear^2) / (2 * a_brake_rear) -
         (v_front^2) / (2 * a_brake_front) +
         buffer

Where:
  v_rear: Ego vehicle velocity
  v_front: Lead vehicle velocity
  t_react: Reaction time (1-2 seconds)
  a_brake_rear: Ego max braking (4 m/s^2)
  a_brake_front: Lead max braking (6 m/s^2, conservative)
  buffer: Additional margin (1-2 meters)
```

**Implementation:**
```python
class RSSChecker:
    def __init__(self):
        self.t_react = 1.0  # seconds
        self.a_brake_max_rear = 4.0  # m/s^2
        self.a_brake_max_front = 6.0  # m/s^2
        self.buffer = 2.0  # meters

    def longitudinal_safe_distance(self, v_ego, v_lead):
        """Compute minimum safe following distance"""
        d_react = v_ego * self.t_react
        d_brake_ego = (v_ego ** 2) / (2 * self.a_brake_max_rear)
        d_brake_lead = (v_lead ** 2) / (2 * self.a_brake_max_front)

        d_safe = d_react + d_brake_ego - d_brake_lead + self.buffer
        return max(d_safe, 0.0)  # Never negative

    def is_longitudinally_safe(self, ego_state, lead_state):
        """Check if current following distance is safe"""
        distance = lead_state.position - ego_state.position
        safe_distance = self.longitudinal_safe_distance(
            ego_state.velocity, lead_state.velocity
        )
        return distance >= safe_distance
```

### Reachability Analysis

Compute the set of states reachable by the ego vehicle and other agents.

```python
class ReachabilityAnalyzer:
    def __init__(self, time_horizon=5.0, dt=0.1):
        self.time_horizon = time_horizon
        self.dt = dt

    def compute_reachable_set(self, initial_state, constraints):
        """Forward reachable set using polytope propagation"""
        states = [initial_state]

        for t in np.arange(0, self.time_horizon, self.dt):
            # Propagate state with all possible control inputs
            next_states = []
            for state in states:
                for control in self._sample_controls(constraints):
                    next_state = self._dynamics(state, control, self.dt)
                    if self._is_feasible(next_state, constraints):
                        next_states.append(next_state)

            # Simplify state set (overapproximate with polytope)
            states = self._convex_hull(next_states)

        return states

    def check_collision_free(self, ego_reachable, object_reachable):
        """Check if reachable sets intersect (collision possible)"""
        return not self._polytopes_intersect(ego_reachable, object_reachable)
```

### Minimal Risk Condition (MRC)

When ODD is violated or a fault occurs, transition to MRC.

**MRC Strategies:**
1. **Continue in current lane** (if safe to do so temporarily)
2. **Pull over to shoulder** (preferred if available)
3. **Emergency stop** (last resort, high risk of rear-end collision)

```cpp
enum class MRCStrategy {
    CONTINUE_CURRENT_LANE,
    PULL_OVER_RIGHT,
    PULL_OVER_LEFT,
    EMERGENCY_STOP
};

class MRCPlanner {
public:
    MRCStrategy selectStrategy(const SceneContext& scene) {
        // Priority: Pull over if shoulder available
        if (scene.has_right_shoulder && scene.right_shoulder_clear) {
            return MRCStrategy::PULL_OVER_RIGHT;
        }

        // If in leftmost lane and left shoulder exists
        if (scene.in_leftmost_lane && scene.has_left_shoulder) {
            return MRCStrategy::PULL_OVER_LEFT;
        }

        // If safe to continue briefly (e.g., waiting for remote takeover)
        if (scene.current_lane_safe && scene.time_to_hazard > 10.0) {
            return MRCStrategy::CONTINUE_CURRENT_LANE;
        }

        // Last resort: emergency stop
        return MRCStrategy::EMERGENCY_STOP;
    }

    Trajectory planMRC(MRCStrategy strategy, const VehicleState& state) {
        switch (strategy) {
            case MRCStrategy::PULL_OVER_RIGHT:
                return planPullOver(state, LaneDirection::RIGHT);
            case MRCStrategy::EMERGENCY_STOP:
                return planEmergencyStop(state);
            // ... other cases
        }
    }
};
```

## Behavior Planning State Machine

High-level decision-making for tactical maneuvers.

```
┌──────────────┐
│ LANE_FOLLOW  │───────┐
└──────┬───────┘       │
       │               │
   lane change    goal reached
   beneficial          │
       │               ↓
       ↓         ┌──────────┐
┌──────────────┐ │  ARRIVED │
│ LANE_CHANGE  │ └──────────┘
└──────┬───────┘
       │
   complete
       │
       └──────────> LANE_FOLLOW
```

**Implementation:**
```python
class BehaviorPlanner:
    def __init__(self):
        self.state = BehaviorState.LANE_FOLLOW
        self.route = None

    def update(self, perception, prediction, localization):
        if self.state == BehaviorState.LANE_FOLLOW:
            # Check if lane change is beneficial
            if self._should_change_lane(perception, prediction):
                self.state = BehaviorState.LANE_CHANGE
                return LaneChangeManeuver(target_lane=self._select_target_lane())

            # Check if arrived at goal
            if self._reached_goal(localization):
                self.state = BehaviorState.ARRIVED
                return ParkingManeuver()

            return LaneFollowManeuver()

        elif self.state == BehaviorState.LANE_CHANGE:
            if self._lane_change_complete(localization):
                self.state = BehaviorState.LANE_FOLLOW

            return ContinueLaneChangeManeuver()

        elif self.state == BehaviorState.ARRIVED:
            return IdleManeuver()

    def _should_change_lane(self, perception, prediction):
        # Reasons to change lanes:
        # 1. Slower vehicle ahead
        # 2. Route requires lane change
        # 3. Obstacle blocking current lane
        pass
```

## Next Steps

- **Level 3**: Detailed implementation of object detection, path planning, MPC controller
- **Level 4**: ROS2 message types, dataset formats, evaluation metrics
- **Level 5**: End-to-end learning (UniAD, MILE), world models, neural planners

## References

- Paden et al., "A Survey of Motion Planning and Control Techniques for Self-Driving Urban Vehicles", T-IV 2016
- Shalev-Shwartz et al., "On a Formal Model of Safe and Scalable Self-driving Cars", arXiv 2017 (RSS)
- ISO 21448: Safety of the Intended Functionality (SOTIF)
- SAE J3016: Taxonomy and Definitions for Terms Related to Driving Automation

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: System architects, AD software engineers, planning/behavior engineers

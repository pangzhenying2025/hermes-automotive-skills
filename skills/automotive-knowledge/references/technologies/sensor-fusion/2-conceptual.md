# Sensor Fusion - Conceptual Architecture

## Fusion Architecture Paradigms

Sensor fusion combines data from multiple sensors (camera, radar, LiDAR, ultrasonic) to achieve better perception performance than any single sensor alone. Three primary architectural approaches exist, each with distinct tradeoffs.

### Centralized Fusion Architecture

All raw sensor data flows to a single fusion node that performs unified processing.

```
Camera ──┐
Radar  ──┼──> Central Fusion ECU ──> Object List
LiDAR  ──┤       (HPC/ADAS ECU)
USS    ──┘
```

**Advantages:**
- Optimal information utilization (all raw data available)
- Consistent object tracking across modalities
- Simplified sensor calibration (single reference frame)
- Best theoretical performance

**Challenges:**
- High computational requirements (single point of processing)
- High bandwidth demands (raw data transmission)
- Single point of failure
- Difficult to scale as sensor count increases

**Typical Use Cases:**
- Level 3+ autonomous driving systems
- Centralized HPC architectures
- Research platforms with compute headroom

### Distributed Fusion Architecture

Each sensor has dedicated processing, producing independent object lists that are later fused.

```
Camera ──> Camera ECU ──> Object List ─┐
Radar  ──> Radar ECU  ──> Object List ─┼──> Track Fusion ──> Fused Tracks
LiDAR  ──> LiDAR ECU  ──> Object List ─┘
```

**Advantages:**
- Lower bandwidth (transmit object lists, not raw data)
- Parallel processing (distributed compute load)
- Easier incremental development (add sensors independently)
- Resilience to single sensor failure

**Challenges:**
- Information loss during pre-processing
- Association uncertainty between object lists
- Harder to resolve conflicts between sensors
- Requires track-to-track fusion algorithms

**Typical Use Cases:**
- ADAS features (AEB, ACC, LKA) on domain controllers
- Distributed E/E architectures
- Retrofittable sensor suites

### Hybrid Fusion Architecture

Combines both approaches: low-level fusion for tightly coupled sensors, high-level fusion across domains.

```
Camera ──┐                                      ┌──> Fused Environment Model
Radar  ──┼──> Front Fusion ──> Object List ────┤
         │     (Low-level)                      │
USS    ──┘                                      ├──> Track Fusion
                                                │    (High-level)
LiDAR  ────> LiDAR Processing ──> Object List ─┘
```

**Advantages:**
- Balances performance and scalability
- Exploits complementary sensor properties
- Flexible resource allocation
- Supports heterogeneous sensor types

**Challenges:**
- Complex architecture definition
- Requires careful interface design
- Potential for redundant processing
- Integration complexity

**Typical Use Cases:**
- Modern Level 2+ systems
- Transitional architectures from ADAS to AD
- Multi-domain ECU platforms

## Fusion Level Taxonomy

### Early Fusion (Data-Level Fusion)

Fusion operates directly on raw sensor measurements before feature extraction.

```
Raw Data → Fusion → Feature Extraction → Object Detection
```

**Characteristics:**
- Preserves maximum information
- Requires sensor synchronization
- Common coordinate frame mandatory
- Computationally intensive

**Example: Camera-LiDAR Early Fusion**
```python
# Project LiDAR points onto camera image
def project_lidar_to_image(lidar_points, camera_K, lidar_to_cam):
    """Early fusion: colorize LiDAR with camera intensity"""
    points_cam = lidar_to_cam @ lidar_points  # Transform to camera frame
    points_img = camera_K @ points_cam[:3]     # Project to image plane
    u = points_img[0] / points_img[2]
    v = points_img[1] / points_img[2]
    # Augment LiDAR with RGB from camera
    augmented_points = concatenate([lidar_points, rgb_at(u, v)])
    return augmented_points
```

**Best For:**
- Research platforms
- Offline processing with compute headroom
- Deep learning fusion networks (BEVFusion, PointPainting)

### Mid-Level Fusion (Feature-Level Fusion)

Fusion operates on extracted features (edges, corners, clusters) before object classification.

```
Raw Data → Feature Extraction → Fusion → Object Detection
```

**Characteristics:**
- Moderate information preservation
- Reduced bandwidth requirements
- Allows sensor-specific feature extraction
- Balance of performance and efficiency

**Example: Radar Cluster + Camera ROI Fusion**
```python
# Associate radar clusters with camera detections
def associate_radar_camera(radar_clusters, camera_rois):
    """Mid-level: match radar points to camera bounding boxes"""
    associations = []
    for cluster in radar_clusters:
        # Project radar cluster to image
        cluster_img = project_to_image(cluster.centroid)
        for roi in camera_rois:
            if roi.contains(cluster_img):
                # Combine features
                fused_object = {
                    'bbox': roi.bbox,
                    'range': cluster.range,
                    'velocity': cluster.doppler_vel,
                    'class': roi.class_prob * cluster.rcs_confidence
                }
                associations.append(fused_object)
    return associations
```

**Best For:**
- ADAS domain controllers
- Real-time embedded systems
- Hybrid architectures

### Late Fusion (Decision-Level Fusion)

Fusion operates on independent object detections from each sensor.

```
Raw Data → Feature Extraction → Object Detection → Fusion
```

**Characteristics:**
- Minimal bandwidth (transmit object lists only)
- Maximum modularity
- Most information loss
- Requires data association (track-to-track)

**Example: Track-to-Track Association**
```cpp
// Associate objects from camera and radar using Mahalanobis distance
struct Object {
    Eigen::Vector2d position;  // [x, y] in vehicle coordinates
    Eigen::Vector2d velocity;
    Eigen::Matrix2d covariance;
    SensorType source;
};

double mahalanobis_distance(const Object& obj1, const Object& obj2) {
    Eigen::Vector2d delta = obj1.position - obj2.position;
    Eigen::Matrix2d S = obj1.covariance + obj2.covariance;
    return sqrt(delta.transpose() * S.inverse() * delta);
}

std::vector<FusedObject> track_to_track_fusion(
    const std::vector<Object>& camera_objects,
    const std::vector<Object>& radar_objects) {

    std::vector<FusedObject> fused;
    for (const auto& cam_obj : camera_objects) {
        double min_distance = DBL_MAX;
        const Object* best_match = nullptr;

        for (const auto& rad_obj : radar_objects) {
            double dist = mahalanobis_distance(cam_obj, rad_obj);
            if (dist < min_distance && dist < ASSOCIATION_THRESHOLD) {
                min_distance = dist;
                best_match = &rad_obj;
            }
        }

        if (best_match) {
            // Fuse matched objects using Kalman filter equations
            fused.push_back(kalman_fuse(cam_obj, *best_match));
        } else {
            // Camera-only detection
            fused.push_back(FusedObject(cam_obj));
        }
    }
    return fused;
}
```

**Best For:**
- Production ADAS systems
- Distributed E/E architectures
- Legacy integration scenarios

## Sensor Placement Optimization

Optimal sensor placement maximizes coverage while minimizing cost and complexity.

### Coverage Zones

Different sensors excel in different operational domains:

| Zone | Camera | Radar | LiDAR | Ultrasonic |
|------|--------|-------|-------|------------|
| Near field (0-5m) | Poor | Limited | Excellent | Excellent |
| Mid field (5-50m) | Excellent | Good | Excellent | - |
| Far field (50-200m) | Good | Excellent | Limited | - |
| Lateral coverage | Wide | Narrow | Medium | Narrow |
| Vertical FOV | High | Low | High | Low |

### Placement Strategies

**360° Perception (L3+ AV):**
```
         Front LiDAR (120° FOV)
               ↓
    Front Camera (60° FOV)
               ↓
    ←─── Vehicle ───→
    ↓                ↓
Corner Radar    Corner Radar
    ↑                ↑
    Rear Camera
         ↑
    Rear Radar
```

**ADAS Front-Focused (L2):**
```
    Long-Range Radar (±15°, 200m)
              ↓
    Mono Camera (±30°, 120m)
              ↓
         Vehicle
    ↙           ↘
Corner Radar  Corner Radar
(±45°, 80m)   (±45°, 80m)
```

### Coordinate Frame Management

All sensors must reference a common vehicle coordinate system (typically defined at rear axle center).

```
Vehicle Frame (ISO 8855):
  X-axis: Forward (driving direction)
  Y-axis: Left (driver's left)
  Z-axis: Up (perpendicular to ground)
  Origin: Rear axle center, ground plane
```

Sensor mounting parameters:
- **Translation**: [tx, ty, tz] from vehicle origin to sensor origin
- **Rotation**: Euler angles [roll, pitch, yaw] or rotation matrix
- **Intrinsics**: Sensor-specific parameters (focal length, distortion)

## Measurement-Level vs Track-to-Track Fusion

### Measurement-Level Fusion

Fuse raw sensor measurements in a unified tracking filter.

```python
class CentralizedKalmanFilter:
    def __init__(self):
        self.state = np.zeros(6)  # [x, y, z, vx, vy, vz]
        self.covariance = np.eye(6) * 10.0

    def predict(self, dt):
        # Motion model
        F = np.array([
            [1, 0, 0, dt, 0,  0],
            [0, 1, 0, 0,  dt, 0],
            [0, 0, 1, 0,  0,  dt],
            [0, 0, 0, 1,  0,  0],
            [0, 0, 0, 0,  1,  0],
            [0, 0, 0, 0,  0,  1]
        ])
        self.state = F @ self.state
        self.covariance = F @ self.covariance @ F.T + self.process_noise

    def update_camera(self, measurement):
        # Camera measures [x, y] in image plane
        H = self.camera_measurement_model()
        self._kalman_update(measurement, H, self.camera_noise)

    def update_radar(self, measurement):
        # Radar measures [range, azimuth, doppler]
        H = self.radar_measurement_model()
        self._kalman_update(measurement, H, self.radar_noise)
```

**Advantages:** Optimal filtering, handles asynchronous measurements naturally
**Challenges:** Requires detailed sensor models, higher computational cost

### Track-to-Track Fusion

Fuse independent track estimates from each sensor.

```python
class TrackToTrackFusion:
    def covariance_intersection(self, track1, track2):
        """CI fusion avoids overconfident estimates from correlated tracks"""
        P1_inv = np.linalg.inv(track1.covariance)
        P2_inv = np.linalg.inv(track2.covariance)

        # Optimal mixing parameter (can be pre-computed)
        omega = self._optimal_omega(P1_inv, P2_inv)

        # Fused covariance
        P_fused_inv = omega * P1_inv + (1 - omega) * P2_inv
        P_fused = np.linalg.inv(P_fused_inv)

        # Fused state
        state_fused = P_fused @ (omega * P1_inv @ track1.state +
                                 (1 - omega) * P2_inv @ track2.state)

        return FusedTrack(state_fused, P_fused)
```

**Advantages:** Modular, lower bandwidth, resilient to sensor failure
**Challenges:** Sub-optimal (discards correlation info), association errors

## Temporal Synchronization

Sensors rarely capture data at the exact same timestamp. Fusion must handle asynchronous measurements.

### Timestamp Alignment Strategies

1. **Buffering and Interpolation**: Store measurements, interpolate to common time
2. **Prediction to Common Time**: Predict each track to fusion timestamp
3. **Event-Driven Fusion**: Fuse whenever any measurement arrives

```cpp
class AsynchronousFusion {
    struct TimestampedMeasurement {
        uint64_t timestamp_us;
        SensorType sensor;
        Measurement data;
    };

    void process_measurement(const TimestampedMeasurement& meas) {
        // Predict state to measurement time
        double dt = (meas.timestamp_us - last_update_us_) / 1e6;
        predict(dt);

        // Update with measurement
        switch (meas.sensor) {
            case CAMERA:
                update_camera(meas.data);
                break;
            case RADAR:
                update_radar(meas.data);
                break;
        }

        last_update_us_ = meas.timestamp_us;
    }
};
```

## Next Steps

- **Level 3**: Detailed implementation of Extended Kalman Filter for radar+camera fusion
- **Level 4**: Quick reference tables for sensor specifications and coordinate transforms
- **Level 5**: Advanced deep learning fusion architectures (BEVFusion, TransFusion)

## References

- David Hall, James Llinas, "Handbook of Multisensor Data Fusion"
- Thrun et al., "Probabilistic Robotics" (sensor fusion chapters)
- AUTOSAR Adaptive Platform Sensor Fusion Interface Specification
- ISO 23150 Road vehicles — Data communication between sensors and data fusion unit

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Sensor fusion architects, perception engineers, ADAS system designers

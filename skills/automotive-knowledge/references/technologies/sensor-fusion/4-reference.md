# Sensor Fusion - Quick Reference

## Sensor Comparison Table

| Characteristic | Camera | Radar | LiDAR | Ultrasonic |
|----------------|--------|-------|-------|------------|
| **Range** | 2-200m | 0.5-250m | 0.1-200m | 0.15-5m |
| **Accuracy** | ±0.5m @ 50m | ±0.1m (range) | ±0.02m | ±0.01m |
| **Angular resolution** | 0.05° (HD) | 1-2° | 0.1-0.4° | 10-15° |
| **Update rate** | 30-120 Hz | 10-20 Hz | 10-20 Hz | 5-20 Hz |
| **Weather sensitivity** | High | Low | Medium | Low |
| **Cost (2026)** | $50-500 | $100-800 | $500-8000 | $10-50 |
| **Power consumption** | 2-15W | 5-20W | 10-100W | 1-3W |
| **FOV (typical)** | 30-120° | 20-150° | 30-360° | 30-120° |
| **Velocity measurement** | No (indirect) | Yes (Doppler) | Yes (optional) | No |
| **Classification** | Excellent | Poor | Good | Poor |
| **Texture/color** | Yes | No | No | No |
| **Weather impact** | Rain/fog/glare | Minimal | Rain/fog | Minimal |
| **Direct sunlight** | Saturates | Immune | Immune | Immune |
| **Darkness** | Requires lighting | Immune | Immune | Immune |

## Coordinate Frames

### Vehicle Frame (ISO 8855)

```
      Z (up)
      ↑
      |
      +---→ X (forward)
     /
    ↙ Y (left)

Origin: Rear axle center, ground plane
```

Conventions:
- X-axis: Longitudinal, forward positive
- Y-axis: Lateral, left positive (driver's left)
- Z-axis: Vertical, up positive
- Rotation: Right-hand rule (counterclockwise positive)

### Sensor Frame Conventions

**Camera Frame:**
```
Z (optical axis, forward)
↑
|
+---→ X (right in image)
 \
  ↘ Y (down in image)
```

**LiDAR Frame:**
```
Same as vehicle frame, but origin at LiDAR sensor
```

**Radar Frame:**
```
X (forward, boresight)
Y (lateral)
Z (elevation)
```

## Rotation Matrices

### Euler Angle Rotations (Radians)

**Yaw (Z-axis rotation):**
```
Rz(ψ) = [cos(ψ)  -sin(ψ)   0]
        [sin(ψ)   cos(ψ)   0]
        [  0        0      1]
```

**Pitch (Y-axis rotation):**
```
Ry(θ) = [ cos(θ)   0   sin(θ)]
        [   0      1     0   ]
        [-sin(θ)   0   cos(θ)]
```

**Roll (X-axis rotation):**
```
Rx(φ) = [1    0       0    ]
        [0  cos(φ)  -sin(φ)]
        [0  sin(φ)   cos(φ)]
```

### Combined Rotation (ZYX Order)

```
R = Rz(yaw) * Ry(pitch) * Rx(roll)
```

### Quaternion to Rotation Matrix

```
Given q = [qw, qx, qy, qz]:

R = [1-2(qy²+qz²)   2(qxqy-qwqz)   2(qxqz+qwqy)]
    [2(qxqy+qwqz)   1-2(qx²+qz²)   2(qyqz-qwqx)]
    [2(qxqz-qwqy)   2(qyqz+qwqx)   1-2(qx²+qy²)]
```

## Homogeneous Transformation

4x4 matrix combining rotation and translation:

```
T = [R11  R12  R13  tx]
    [R21  R22  R23  ty]
    [R31  R32  R33  tz]
    [ 0    0    0   1 ]

Transform point: p' = T * p  (where p = [x, y, z, 1]^T)
```

**Inverse transformation:**
```
T^-1 = [R^T   -R^T * t]
       [ 0       1    ]
```

## Measurement Noise Covariances

### Typical Sensor Noise (Diagonal R Matrices)

**Camera (pixels):**
```
R_camera = diag([σu², σv²])
σu = σv = 2-5 pixels (depends on detection quality)
```

**Radar (range/azimuth/doppler):**
```
R_radar = diag([σr², σθ², σvr²])
σr = 0.1-0.5 m
σθ = 0.01-0.05 rad
σvr = 0.3-0.8 m/s
```

**LiDAR (3D point):**
```
R_lidar = diag([σx², σy², σz²])
σx = σy = 0.01-0.05 m
σz = 0.02-0.08 m (worse in Z)
```

**Ultrasonic (range):**
```
R_uss = σr²
σr = 0.01-0.03 m
```

## Process Noise Covariances

### Constant Velocity Model (2D)

State: [px, py, vx, vy]

```
Q = q * [dt⁴/4    0     dt³/2    0   ]
        [  0    dt⁴/4    0     dt³/2 ]
        [dt³/2    0      dt²     0   ]
        [  0    dt³/2    0      dt²  ]

Typical q values:
- Low process noise (highway): q = 0.5 m²/s⁴
- Medium (urban): q = 1.5 m²/s⁴
- High (pedestrian): q = 3.0 m²/s⁴
```

### Constant Acceleration Model (2D)

State: [px, py, vx, vy, ax, ay]

```
Q = diag([q_pos, q_pos, q_vel, q_vel, q_acc, q_acc])

Typical values:
q_pos = 0.01 m²
q_vel = 0.5 m²/s²
q_acc = 2.0 m²/s⁴
```

## Association Thresholds

### Mahalanobis Distance Gates

Chi-squared distribution thresholds for different confidence levels:

| Confidence | 2D Threshold | 3D Threshold | 4D Threshold |
|------------|--------------|--------------|--------------|
| 90% | 4.61 | 6.25 | 7.78 |
| 95% | 5.99 | 7.81 | 9.49 |
| 99% | 9.21 | 11.34 | 13.28 |

**Usage:**
```python
if mahalanobis_distance < threshold:
    # Associate measurement to track
```

### Euclidean Distance Fallbacks

When Mahalanobis is not available (e.g., track initialization):

| Sensor Pair | Position Gate | Velocity Gate |
|-------------|---------------|---------------|
| Camera-Radar | 5.0 m | 3.0 m/s |
| LiDAR-Radar | 2.0 m | 2.0 m/s |
| Camera-LiDAR | 3.0 m | - |

## Common Pitfalls

### 1. Angle Wrapping
```cpp
// WRONG: Direct subtraction
double angle_diff = measured_angle - predicted_angle;

// CORRECT: Normalize to [-π, π]
double angle_diff = measured_angle - predicted_angle;
while (angle_diff > M_PI) angle_diff -= 2*M_PI;
while (angle_diff < -M_PI) angle_diff += 2*M_PI;
```

### 2. Covariance Matrix Symmetry
```cpp
// After Kalman update, force symmetry to avoid numerical drift
P = (P + P.transpose()) / 2.0;
```

### 3. Positive Definiteness
```cpp
// Check if covariance is positive definite
Eigen::LLT<Eigen::MatrixXd> llt(P);
if (llt.info() == Eigen::NumericalIssue) {
    // Add small positive diagonal to stabilize
    P += Eigen::MatrixXd::Identity(P.rows(), P.cols()) * 1e-6;
}
```

### 4. Division by Zero in Radar Model
```cpp
// WRONG: Direct division
double radial_vel = (px*vx + py*vy) / range;

// CORRECT: Check for zero range
double radial_vel = 0.0;
if (range > 1e-3) {
    radial_vel = (px*vx + py*vy) / range;
}
```

### 5. Jacobian Numerical Stability
```python
# Use numerical Jacobian for complex models
def numerical_jacobian(func, x, epsilon=1e-5):
    n = len(x)
    m = len(func(x))
    J = np.zeros((m, n))
    for i in range(n):
        x_plus = x.copy()
        x_plus[i] += epsilon
        J[:, i] = (func(x_plus) - func(x)) / epsilon
    return J
```

## API Patterns

### Measurement Structure

```cpp
struct Measurement {
    uint64_t timestamp_us;
    SensorType sensor_type;
    Eigen::VectorXd value;
    Eigen::MatrixXd covariance;
    uint32_t object_id;  // For track association
};

enum SensorType {
    CAMERA,
    RADAR,
    LIDAR,
    ULTRASONIC
};
```

### Track Structure

```cpp
struct Track {
    uint32_t track_id;
    Eigen::VectorXd state;
    Eigen::MatrixXd covariance;
    uint64_t last_update_us;
    uint32_t consecutive_misses;
    TrackStatus status;
};

enum TrackStatus {
    TENTATIVE,   // New track, not yet confirmed
    CONFIRMED,   // Stable track
    COASTED      // No recent measurement
};
```

### Fusion Interface

```cpp
class SensorFusion {
public:
    void predict(double dt);
    void update(const Measurement& meas);
    std::vector<Track> get_tracks() const;
    void set_process_noise(double q);
};
```

## Debugging Checklist

- [ ] All angles in radians (not degrees)
- [ ] Timestamps in consistent units (prefer microseconds)
- [ ] Coordinate frames match (vehicle frame for all outputs)
- [ ] Covariance matrices symmetric and positive definite
- [ ] Innovation normalized for angles ([-π, π])
- [ ] Association gates appropriate for sensor accuracy
- [ ] Division by zero checks in measurement models
- [ ] Numerical stability for small values (< 1e-6)
- [ ] Process noise tuned for object dynamics
- [ ] Sensor noise matches datasheet specifications

## Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| Latency (end-to-end) | < 100 ms | < 200 ms |
| Update rate | > 10 Hz | > 5 Hz |
| Position accuracy | < 0.5 m | < 1.0 m |
| Velocity accuracy | < 0.5 m/s | < 1.0 m/s |
| False positive rate | < 0.1 per km | < 0.5 per km |
| Missed detection rate | < 5% | < 10% |
| CPU utilization | < 50% | < 80% |
| Memory usage | < 500 MB | < 1 GB |

## Next Steps

- **Level 5**: Advanced deep learning fusion architectures
- **Related**: Multi-object tracking (JPDA, MHT), occupancy grids
- **Standards**: ISO 23150 (sensor-to-fusion communication)

## References

- ISO 8855: Road vehicles - Vehicle dynamics and road-holding ability
- ISO 23150: Data communication between sensors and data fusion unit
- SAE J3016: Taxonomy and Definitions for Terms Related to Driving Automation

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All sensor fusion practitioners (quick reference during development)

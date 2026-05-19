# Sensor Fusion - Detailed Implementation

## Extended Kalman Filter for Radar-Camera Fusion

The Extended Kalman Filter (EKF) is the workhorse algorithm for fusing nonlinear sensor measurements. This section provides a complete implementation for tracking objects using radar (range, azimuth, doppler) and camera (image coordinates).

### State Vector Definition

We track objects in 2D vehicle coordinates with velocity:

```
State vector x: [px, py, vx, vy]^T
  px, py: Position in vehicle frame (meters)
  vx, vy: Velocity in vehicle frame (m/s)
```

This is a 4-dimensional state space. For 3D tracking (including LiDAR), extend to `[px, py, pz, vx, vy, vz]`.

### Motion Model (Prediction)

Assuming constant velocity motion between measurements:

```
x(k+1) = F * x(k) + w(k)

F = [1  0  dt  0 ]  # State transition matrix
    [0  1  0   dt]
    [0  0  1   0 ]
    [0  0  0   1 ]

Q = [q*dt^4/4  0        q*dt^3/2  0       ]  # Process noise covariance
    [0         q*dt^4/4  0         q*dt^3/2]
    [q*dt^3/2  0        q*dt^2    0       ]
    [0         q*dt^3/2  0         q*dt^2  ]
```

where `q` is the process noise intensity (typically 0.5-2.0 m/s²).

### Radar Measurement Model

Radar provides spherical coordinates: range (r), azimuth (θ), and radial velocity (v_r).

```
z_radar = h_radar(x) + v
        = [sqrt(px^2 + py^2)           ]  # range
          [atan2(py, px)                ]  # azimuth
          [(px*vx + py*vy) / sqrt(px^2+py^2)]  # radial velocity

Measurement noise R_radar = diag([σ_r^2, σ_θ^2, σ_vr^2])
  Typical values: σ_r = 0.2m, σ_θ = 0.02rad, σ_vr = 0.5m/s
```

### Camera Measurement Model

Camera provides 2D image coordinates (u, v) via perspective projection:

```
z_camera = h_camera(x) + v
         = [fx * px / py + cx]  # u (horizontal pixel)
           [fy * pz / py + cy]  # v (vertical pixel, requires 3D)

For 2D tracking, use homography to ground plane:
z_camera = K * [px]
               [py]

Measurement noise R_camera = diag([σ_u^2, σ_v^2])
  Typical values: σ_u = σ_v = 2-5 pixels
```

### EKF Prediction Step

```cpp
#include <Eigen/Dense>
#include <cmath>

class RadarCameraEKF {
public:
    RadarCameraEKF(double process_noise_intensity = 1.0)
        : q_(process_noise_intensity) {
        // Initialize state [px, py, vx, vy]
        x_ = Eigen::Vector4d::Zero();

        // Initialize covariance (large uncertainty initially)
        P_ = Eigen::Matrix4d::Identity() * 100.0;
    }

    void predict(double dt) {
        // State transition matrix
        Eigen::Matrix4d F;
        F << 1, 0, dt, 0,
             0, 1, 0,  dt,
             0, 0, 1,  0,
             0, 0, 0,  1;

        // Process noise covariance
        Eigen::Matrix4d Q;
        double dt2 = dt * dt;
        double dt3 = dt2 * dt;
        double dt4 = dt3 * dt;

        Q << q_*dt4/4, 0,         q_*dt3/2, 0,
             0,        q_*dt4/4,  0,        q_*dt3/2,
             q_*dt3/2, 0,         q_*dt2,   0,
             0,        q_*dt3/2,  0,        q_*dt2;

        // Predict state
        x_ = F * x_;

        // Predict covariance
        P_ = F * P_ * F.transpose() + Q;
    }

private:
    Eigen::Vector4d x_;     // State [px, py, vx, vy]
    Eigen::Matrix4d P_;     // State covariance
    double q_;              // Process noise intensity
};
```

### EKF Update with Radar Measurement

```cpp
void update_radar(const Eigen::Vector3d& z_radar,
                  const Eigen::Matrix3d& R_radar) {
    double px = x_(0);
    double py = x_(1);
    double vx = x_(2);
    double vy = x_(3);

    // Predicted measurement
    double range = std::sqrt(px*px + py*py);
    double azimuth = std::atan2(py, px);
    double radial_vel = (px*vx + py*vy) / range;

    Eigen::Vector3d h;
    h << range, azimuth, radial_vel;

    // Measurement Jacobian
    Eigen::Matrix<double, 3, 4> H;
    double range_inv = 1.0 / range;
    double range_sq = range * range;

    // dh/d[px, py, vx, vy]
    H << px * range_inv,         py * range_inv,         0,                     0,
         -py / range_sq,         px / range_sq,          0,                     0,
         vx/range - px*(px*vx+py*vy)/range_sq/range,
         vy/range - py*(px*vx+py*vy)/range_sq/range,
         px * range_inv,         py * range_inv;

    // Innovation
    Eigen::Vector3d y = z_radar - h;

    // Normalize azimuth innovation to [-pi, pi]
    while (y(1) > M_PI) y(1) -= 2*M_PI;
    while (y(1) < -M_PI) y(1) += 2*M_PI;

    // Innovation covariance
    Eigen::Matrix3d S = H * P_ * H.transpose() + R_radar;

    // Kalman gain
    Eigen::Matrix<double, 4, 3> K = P_ * H.transpose() * S.inverse();

    // Update state
    x_ = x_ + K * y;

    // Update covariance
    Eigen::Matrix4d I = Eigen::Matrix4d::Identity();
    P_ = (I - K * H) * P_;
}
```

### EKF Update with Camera Measurement

```cpp
void update_camera(const Eigen::Vector2d& z_camera,
                   const Eigen::Matrix2d& R_camera,
                   const Eigen::Matrix3d& K_camera,  // Camera intrinsics
                   const Eigen::Matrix4d& T_cam_to_veh) {  // Extrinsics
    double px = x_(0);
    double py = x_(1);

    // Transform to camera frame
    Eigen::Vector4d pos_veh(px, py, 0, 1);  // Assume ground plane (z=0)
    Eigen::Vector4d pos_cam = T_cam_to_veh.inverse() * pos_veh;

    // Predicted measurement (perspective projection)
    double fx = K_camera(0, 0);
    double fy = K_camera(1, 1);
    double cx = K_camera(0, 2);
    double cy = K_camera(1, 2);

    double x_cam = pos_cam(0);
    double y_cam = pos_cam(1);
    double z_cam = pos_cam(2);

    Eigen::Vector2d h;
    h << fx * x_cam / z_cam + cx,
         fy * y_cam / z_cam + cy;

    // Measurement Jacobian (simplified for ground plane)
    Eigen::Matrix<double, 2, 4> H;
    // Numerical Jacobian (preferred for complex transforms)
    double epsilon = 1e-4;
    for (int i = 0; i < 4; ++i) {
        Eigen::Vector4d x_plus = x_;
        x_plus(i) += epsilon;
        Eigen::Vector2d h_plus = compute_camera_measurement(x_plus, K_camera, T_cam_to_veh);
        H.col(i) = (h_plus - h) / epsilon;
    }

    // Innovation
    Eigen::Vector2d y = z_camera - h;

    // Innovation covariance
    Eigen::Matrix2d S = H * P_ * H.transpose() + R_camera;

    // Kalman gain
    Eigen::Matrix<double, 4, 2> K = P_ * H.transpose() * S.inverse();

    // Update state
    x_ = x_ + K * y;

    // Update covariance
    Eigen::Matrix4d I = Eigen::Matrix4d::Identity();
    P_ = (I - K * H) * P_;
}
```

### Complete Python Implementation

```python
import numpy as np
from scipy.linalg import inv

class RadarCameraEKF:
    def __init__(self, process_noise=1.0):
        self.x = np.zeros(4)  # [px, py, vx, vy]
        self.P = np.eye(4) * 100.0
        self.q = process_noise

    def predict(self, dt):
        # State transition
        F = np.array([
            [1, 0, dt, 0],
            [0, 1, 0, dt],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ])

        # Process noise
        dt2, dt3, dt4 = dt**2, dt**3, dt**4
        Q = self.q * np.array([
            [dt4/4, 0,     dt3/2, 0],
            [0,     dt4/4, 0,     dt3/2],
            [dt3/2, 0,     dt2,   0],
            [0,     dt3/2, 0,     dt2]
        ])

        self.x = F @ self.x
        self.P = F @ self.P @ F.T + Q

    def update_radar(self, z, R):
        """Update with radar measurement [range, azimuth, radial_velocity]"""
        px, py, vx, vy = self.x

        # Predicted measurement
        r = np.sqrt(px**2 + py**2)
        theta = np.arctan2(py, px)
        v_r = (px*vx + py*vy) / r

        h = np.array([r, theta, v_r])

        # Jacobian
        H = np.array([
            [px/r, py/r, 0, 0],
            [-py/r**2, px/r**2, 0, 0],
            [vx/r - px*(px*vx+py*vy)/r**3,
             vy/r - py*(px*vx+py*vy)/r**3,
             px/r, py/r]
        ])

        # Update
        y = z - h
        y[1] = self._normalize_angle(y[1])  # Wrap azimuth to [-pi, pi]

        S = H @ self.P @ H.T + R
        K = self.P @ H.T @ inv(S)

        self.x = self.x + K @ y
        self.P = (np.eye(4) - K @ H) @ self.P

    def update_camera(self, z, R, K_cam, T_cam_veh):
        """Update with camera measurement [u, v] (pixels)"""
        # Project state to camera image
        px, py = self.x[0], self.x[1]
        pos_veh = np.array([px, py, 0, 1])
        pos_cam = inv(T_cam_veh) @ pos_veh

        fx, fy = K_cam[0, 0], K_cam[1, 1]
        cx, cy = K_cam[0, 2], K_cam[1, 2]

        x_c, y_c, z_c = pos_cam[0], pos_cam[1], pos_cam[2]
        h = np.array([
            fx * x_c / z_c + cx,
            fy * y_c / z_c + cy
        ])

        # Numerical Jacobian
        H = self._numerical_jacobian_camera(K_cam, T_cam_veh)

        # Update
        y = z - h
        S = H @ self.P @ H.T + R
        K = self.P @ H.T @ inv(S)

        self.x = self.x + K @ y
        self.P = (np.eye(4) - K @ H) @ self.P

    def _normalize_angle(self, angle):
        while angle > np.pi:
            angle -= 2*np.pi
        while angle < -np.pi:
            angle += 2*np.pi
        return angle

    def _numerical_jacobian_camera(self, K_cam, T_cam_veh, eps=1e-4):
        H = np.zeros((2, 4))
        h0 = self._project_to_camera(self.x, K_cam, T_cam_veh)

        for i in range(4):
            x_plus = self.x.copy()
            x_plus[i] += eps
            h_plus = self._project_to_camera(x_plus, K_cam, T_cam_veh)
            H[:, i] = (h_plus - h0) / eps

        return H

    def _project_to_camera(self, state, K_cam, T_cam_veh):
        px, py = state[0], state[1]
        pos_veh = np.array([px, py, 0, 1])
        pos_cam = inv(T_cam_veh) @ pos_veh

        fx, fy = K_cam[0, 0], K_cam[1, 1]
        cx, cy = K_cam[0, 2], K_cam[1, 2]

        x_c, y_c, z_c = pos_cam[0], pos_cam[1], pos_cam[2]
        return np.array([
            fx * x_c / z_c + cx,
            fy * y_c / z_c + cy
        ])
```

## Coordinate Frame Transformations

All sensors must reference a common vehicle coordinate frame. Transformation matrices convert between frames.

### Rotation Matrices

```python
def rotation_matrix_z(yaw):
    """Rotation about Z-axis (yaw angle in radians)"""
    c, s = np.cos(yaw), np.sin(yaw)
    return np.array([
        [c, -s, 0],
        [s,  c, 0],
        [0,  0, 1]
    ])

def rotation_matrix_y(pitch):
    """Rotation about Y-axis (pitch angle)"""
    c, s = np.cos(pitch), np.sin(pitch)
    return np.array([
        [ c, 0, s],
        [ 0, 1, 0],
        [-s, 0, c]
    ])

def rotation_matrix_x(roll):
    """Rotation about X-axis (roll angle)"""
    c, s = np.cos(roll), np.sin(roll)
    return np.array([
        [1,  0, 0],
        [0,  c, -s],
        [0,  s,  c]
    ])

def euler_to_rotation_matrix(roll, pitch, yaw):
    """Combine roll-pitch-yaw into single rotation matrix (ZYX order)"""
    Rz = rotation_matrix_z(yaw)
    Ry = rotation_matrix_y(pitch)
    Rx = rotation_matrix_x(roll)
    return Rz @ Ry @ Rx
```

### Homogeneous Transformation

```python
def make_transform(translation, rotation_matrix):
    """Create 4x4 homogeneous transformation matrix"""
    T = np.eye(4)
    T[:3, :3] = rotation_matrix
    T[:3, 3] = translation
    return T

# Example: Camera mounted 1.2m forward, 0.5m up, pitched down 5°
t_cam = np.array([1.2, 0, 0.5])
R_cam = euler_to_rotation_matrix(0, -5*np.pi/180, 0)
T_cam_to_veh = make_transform(t_cam, R_cam)

# Transform point from camera frame to vehicle frame
point_cam = np.array([2.0, 0.5, 1.0, 1.0])  # [x, y, z, 1]
point_veh = T_cam_to_veh @ point_cam
```

## Data Association

Before fusion, measurements must be associated with existing tracks.

### Nearest Neighbor Association

```python
from scipy.spatial.distance import mahalanobis

def associate_measurements(tracks, measurements, gate_threshold=9.21):
    """Associate measurements to tracks using Mahalanobis distance

    gate_threshold: Chi-squared threshold (9.21 for 99% confidence, 2D)
    """
    associations = []
    unassociated_measurements = []

    for meas in measurements:
        best_track = None
        min_distance = float('inf')

        for track in tracks:
            # Predicted measurement
            z_pred = track.measurement_prediction()
            innovation = meas.value - z_pred

            # Innovation covariance
            S = track.innovation_covariance()

            # Mahalanobis distance
            dist = mahalanobis(innovation, np.zeros_like(innovation), np.linalg.inv(S))

            if dist < min_distance and dist < gate_threshold:
                min_distance = dist
                best_track = track

        if best_track is not None:
            associations.append((best_track, meas))
        else:
            unassociated_measurements.append(meas)

    return associations, unassociated_measurements
```

### Global Nearest Neighbor (GNN)

```python
from scipy.optimize import linear_sum_assignment

def global_nearest_neighbor(tracks, measurements):
    """Optimal assignment using Hungarian algorithm"""
    n_tracks = len(tracks)
    n_meas = len(measurements)

    # Build cost matrix (Mahalanobis distances)
    cost_matrix = np.full((n_tracks, n_meas), 1e9)

    for i, track in enumerate(tracks):
        z_pred = track.measurement_prediction()
        S = track.innovation_covariance()
        S_inv = np.linalg.inv(S)

        for j, meas in enumerate(measurements):
            innovation = meas.value - z_pred
            dist = innovation.T @ S_inv @ innovation
            cost_matrix[i, j] = dist

    # Solve assignment problem
    track_indices, meas_indices = linear_sum_assignment(cost_matrix)

    associations = []
    for i, j in zip(track_indices, meas_indices):
        if cost_matrix[i, j] < 9.21:  # Gating threshold
            associations.append((tracks[i], measurements[j]))

    return associations
```

## Next Steps

- **Level 4**: Quick reference for sensor specs, coordinate transforms, common pitfalls
- **Level 5**: Deep learning fusion (PointPainting, BEVFusion), attention mechanisms
- **Related Topics**: Multi-object tracking (JPDA, MHT), uncertainty quantification

## References

- Thrun, Burgard, Fox: "Probabilistic Robotics", MIT Press
- Bar-Shalom, Li, Kirubarajan: "Estimation with Applications to Tracking and Navigation"
- Eigen library documentation: https://eigen.tuxfamily.org
- AUTOSAR Sensor Fusion Interface Specification

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Perception engineers, embedded software developers, sensor fusion implementers

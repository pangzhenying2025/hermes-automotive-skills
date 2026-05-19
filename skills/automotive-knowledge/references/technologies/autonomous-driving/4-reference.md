# Autonomous Driving - Quick Reference

## ROS2 Message Types

### Sensor Messages

```python
# sensor_msgs/Image
header:
  stamp: {sec: 1234567890, nanosec: 123456789}
  frame_id: "camera_front"
height: 1080
width: 1920
encoding: "rgb8"  # or "bgr8", "mono8"
is_bigendian: 0
step: 5760  # width * bytes_per_pixel
data: [...]  # Raw pixel data

# sensor_msgs/PointCloud2
header:
  stamp: {sec: 1234567890, nanosec: 123456789}
  frame_id: "lidar"
height: 1  # Unorganized cloud
width: 100000  # Number of points
fields:
  - {name: "x", offset: 0, datatype: 7, count: 1}  # FLOAT32
  - {name: "y", offset: 4, datatype: 7, count: 1}
  - {name: "z", offset: 8, datatype: 7, count: 1}
  - {name: "intensity", offset: 12, datatype: 7, count: 1}
is_bigendian: false
point_step: 16  # Bytes per point
row_step: 1600000
is_dense: true
data: [...]

# sensor_msgs/NavSatFix (GPS)
header:
  stamp: {sec: 1234567890, nanosec: 123456789}
  frame_id: "gps"
status:
  status: 0  # STATUS_FIX
  service: 1  # SERVICE_GPS
latitude: 37.7749
longitude: -122.4194
altitude: 50.0
position_covariance: [1.0, 0, 0, 0, 1.0, 0, 0, 0, 4.0]
position_covariance_type: 2  # DIAGONAL_KNOWN
```

### Perception Messages

```python
# vision_msgs/Detection3D
header:
  stamp: {sec: 1234567890, nanosec: 123456789}
  frame_id: "base_link"
results:
  - hypothesis:
      class_id: "car"
      score: 0.95
    bbox:
      center:
        position: {x: 10.0, y: 2.0, z: 0.0}
        orientation: {x: 0, y: 0, z: 0, w: 1}
      size: {x: 4.5, y: 2.0, z: 1.5}  # length, width, height

# autoware_auto_msgs/TrackedObjects
header:
  stamp: {sec: 1234567890, nanosec: 123456789}
  frame_id: "map"
objects:
  - object_id: {uuid: [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]}
    existence_probability: 0.98
    classification:
      - label: 2  # CAR
        probability: 0.95
    kinematics:
      pose_with_covariance:
        pose:
          position: {x: 10.0, y: 2.0, z: 0.0}
          orientation: {x: 0, y: 0, z: 0.1, w: 0.995}
        covariance: [0.1, 0, ..., 0.05]  # 6x6 covariance
      twist_with_covariance:
        twist:
          linear: {x: 5.0, y: 0.0, z: 0.0}
          angular: {x: 0, y: 0, z: 0.05}
    shape:
      type: 1  # BOUNDING_BOX
      dimensions: {x: 4.5, y: 2.0, z: 1.5}
```

### Planning Messages

```python
# autoware_auto_msgs/Trajectory
header:
  stamp: {sec: 1234567890, nanosec: 123456789}
  frame_id: "map"
points:
  - time_from_start: {sec: 0, nanosec: 0}
    pose:
      position: {x: 0.0, y: 0.0, z: 0.0}
      orientation: {x: 0, y: 0, z: 0, w: 1}
    longitudinal_velocity_mps: 5.0
    lateral_velocity_mps: 0.0
    acceleration_mps2: 0.0
    heading_rate_rps: 0.0
    front_wheel_angle_rad: 0.0
  - time_from_start: {sec: 0, nanosec: 100000000}  # 0.1s later
    pose:
      position: {x: 0.5, y: 0.0, z: 0.0}
      orientation: {x: 0, y: 0, z: 0, w: 1}
    longitudinal_velocity_mps: 5.0
    # ... more points

# nav_msgs/Path
header:
  stamp: {sec: 1234567890, nanosec: 123456789}
  frame_id: "map"
poses:
  - header:
      stamp: {sec: 1234567890, nanosec: 123456789}
      frame_id: "map"
    pose:
      position: {x: 0.0, y: 0.0, z: 0.0}
      orientation: {x: 0, y: 0, z: 0, w: 1}
  - header:
      stamp: {sec: 1234567891, nanosec: 0}
      frame_id: "map"
    pose:
      position: {x: 10.0, y: 0.0, z: 0.0}
      orientation: {x: 0, y: 0, z: 0, w: 1}
```

## Dataset Formats

### KITTI Dataset

```
# 3D Object Detection Format (label files)
# Format: type truncated occluded alpha bbox_2d dimensions location rotation_y [score]
Car 0.00 0 -1.58 614.24 181.78 727.31 284.77 1.57 1.73 4.15 1.65 1.67 46.04 -1.59
Pedestrian 0.00 0 -0.39 555.12 172.43 570.89 213.77 1.76 0.47 0.67 2.31 1.72 47.12 -0.40

# Fields:
# - type: Object class (Car, Pedestrian, Cyclist, etc.)
# - truncated: Float [0,1] indicating truncation
# - occluded: Integer (0=fully visible, 1=partly, 2=largely, 3=unknown)
# - alpha: Observation angle [-pi, pi]
# - bbox_2d: 2D bounding box [left, top, right, bottom] in pixels
# - dimensions: 3D object dimensions [height, width, length] in meters
# - location: 3D object location [x, y, z] in camera coordinates (meters)
# - rotation_y: Rotation around Y-axis in camera coordinates [-pi, pi]

# Calibration Format (calib files)
P0: 7.215377e+02 0.000000e+00 6.095593e+02 0.000000e+00 ...
P1: 7.215377e+02 0.000000e+00 6.095593e+02 -3.875744e+02 ...
P2: 7.215377e+02 0.000000e+00 6.095593e+02 4.485728e+01 ...
P3: 7.215377e+02 0.000000e+00 6.095593e+02 -3.395242e+02 ...
R0_rect: 9.999239e-01 9.837760e-03 -7.445048e-03 ...
Tr_velo_to_cam: 7.533745e-03 -9.999714e-01 -6.166020e-04 ...
Tr_imu_to_velo: 9.999976e-01 7.553071e-04 -2.035826e-03 ...
```

### nuScenes Format

```json
{
  "sample": {
    "token": "ca9a282c9e77460f8360f564131a8af5",
    "timestamp": 1532402927814384,
    "scene_token": "cc8c0bf57f984915a77078b10eb33198",
    "data": {
      "CAM_FRONT": "e3d495d4ac534d54b321f50006683844",
      "LIDAR_TOP": "9d9bf11fb0e144c8b446d54a8a00a822",
      "RADAR_FRONT": "37091c75b9704e0daa829ba56dfa0906"
    },
    "anns": [
      "ef63a697930c4b20a6b9791f423351da",
      "6b89da9bf1f84fd6a5fbe1c3b236f809"
    ]
  },
  "sample_annotation": {
    "token": "ef63a697930c4b20a6b9791f423351da",
    "sample_token": "ca9a282c9e77460f8360f564131a8af5",
    "instance_token": "bc38961ca0ac4b14ab90e547ba79fbb6",
    "category_name": "vehicle.car",
    "attribute_tokens": ["cb5118da1ab342aa947717dc53544259"],
    "translation": [410.87, 1156.35, 0.78],
    "size": [1.796, 4.607, 1.558],
    "rotation": [0.9381, 0.0, 0.0, -0.3464],
    "num_lidar_pts": 34,
    "num_radar_pts": 0,
    "visibility_token": "4"
  }
}
```

### Waymo Open Dataset

```python
# TensorFlow records with protobuf serialization
import tensorflow as tf
from waymo_open_dataset import dataset_pb2

dataset = tf.data.TFRecordDataset('segment-xxx.tfrecord')
for data in dataset:
    frame = dataset_pb2.Frame()
    frame.ParseFromString(bytearray(data.numpy()))

    # Camera images
    for image in frame.images:
        img = tf.io.decode_jpeg(image.image)
        camera_name = image.name  # FRONT, FRONT_LEFT, etc.

    # LiDAR points
    for laser in frame.lasers:
        range_image = laser.ri_return1
        points = convert_range_image_to_point_cloud(range_image)

    # Labels
    for label in frame.laser_labels:
        bbox = label.box  # center_x, center_y, center_z, length, width, height, heading
        obj_type = label.type  # TYPE_VEHICLE, TYPE_PEDESTRIAN, etc.
```

## Evaluation Metrics

### Object Detection Metrics

**Average Precision (AP):**
```
AP = ∫[0,1] Precision(Recall) dRecall

Precision = TP / (TP + FP)
Recall = TP / (TP + FN)

IoU Thresholds:
- KITTI: IoU > 0.7 (cars), 0.5 (pedestrians)
- COCO: IoU ∈ [0.5, 0.95] (step 0.05)
```

**3D Object Detection (nuScenes):**
```
mAP = (1/N) Σ AP_class

Distance bins: [0-5m, 5-10m, 10-20m, 20-30m, 30-40m, 40-50m]
Attributes: Translation error, Scale error, Orientation error, Velocity error, IoU
```

### Tracking Metrics

**CLEAR MOT Metrics:**
```
MOTA = 1 - (FN + FP + IDSW) / GT
  FN: False negatives (missed detections)
  FP: False positives
  IDSW: ID switches
  GT: Total ground truth objects

MOTP = Σ IoU_matches / Σ matches
  Average IoU of matched detections
```

**HOTA (Higher Order Tracking Accuracy):**
```
HOTA = √(DetA × AssA)
  DetA: Detection accuracy
  AssA: Association accuracy
```

### Planning Metrics

**Trajectory Error:**
```
ADE (Average Displacement Error) = (1/T) Σ ||pred_t - gt_t||
FDE (Final Displacement Error) = ||pred_T - gt_T||

Typical targets:
- ADE < 0.5 m (3 second horizon)
- FDE < 1.0 m
```

**Collision Rate:**
```
Collision Rate = (# simulated collisions) / (# test scenarios)

Target: < 0.01 (1%) for L4 systems
```

## Common Coordinate Frames

```
# Vehicle Frame (ISO 8855)
X: Forward
Y: Left
Z: Up
Origin: Rear axle center

# Camera Frame (OpenCV)
X: Right
Y: Down
Z: Forward (optical axis)
Origin: Camera optical center

# LiDAR Frame
X: Forward
Y: Left
Z: Up
Origin: LiDAR sensor center

# Map Frame (Global)
X: East
Y: North
Z: Up
Origin: Arbitrary (e.g., first pose)
```

## Sensor Specifications

| Sensor | Range | FOV | Resolution | Frame Rate | Weather |
|--------|-------|-----|------------|------------|---------|
| Camera (mono) | 2-200m | 60-120° | 1920x1080 | 30-60 Hz | Poor |
| Camera (stereo) | 2-80m | 60-90° | 1920x1080 | 30 Hz | Poor |
| LiDAR (mech) | 0.5-200m | 360° | 0.1-0.2° | 10-20 Hz | Medium |
| LiDAR (solid) | 0.5-120m | 120° | 0.2-0.5° | 10-30 Hz | Medium |
| Radar (long) | 1-250m | ±15° | 1-2° | 10-20 Hz | Good |
| Radar (corner) | 0.5-80m | ±75° | 2-5° | 10-20 Hz | Good |
| Ultrasonic | 0.15-5m | 60-120° | N/A | 5-20 Hz | Good |
| GNSS/RTK | Global | N/A | 0.01-2m | 10 Hz | Open sky |
| IMU | N/A | N/A | 0.01°/s | 100-1000 Hz | Excellent |

## Performance Benchmarks

| Task | Model | Dataset | Metric | Score |
|------|-------|---------|--------|-------|
| 3D Detection | PointPillars | KITTI | AP (Car, Moderate) | 88.35 |
| 3D Detection | CenterPoint | nuScenes | mAP | 65.5 |
| Tracking | SORT | MOT17 | MOTA | 47.3 |
| Tracking | ByteTrack | MOT20 | MOTA | 77.8 |
| Prediction | Trajectron++ | nuScenes | minADE | 1.51 |
| Planning | Hybrid A* | Custom | Success Rate | 95% |
| E2E Driving | UniAD | nuScenes | Planning L2 (m) | 0.31 |

## Safety Metrics

```
# Disengagement Rate (California DMV)
Disengagements per 1000 miles:
- Waymo (2023): 0.06
- Cruise (2023): 2.5
- Tesla (not reported): N/A

# Critical Event Rate
Events per million miles:
- Human baseline: ~2.5 fatal crashes
- L4 target: < 0.25 (10x safer)

# Time to Collision (TTC)
TTC = distance / relative_velocity

Warning threshold: TTC < 2.0s
Emergency braking: TTC < 1.0s
```

## Next Steps

- **Level 5**: End-to-end learning (UniAD, MILE), world models, diffusion planning
- **Standards**: ISO 21448 (SOTIF), ISO 26262 (functional safety)
- **Tools**: Autoware, Apollo, CARLA simulator

## References

- ROS2 Documentation: https://docs.ros.org/
- KITTI Benchmark: http://www.cvlibs.net/datasets/kitti/
- nuScenes Dataset: https://www.nuscenes.org/
- Waymo Open Dataset: https://waymo.com/open/

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All AD engineers (quick lookup during development)

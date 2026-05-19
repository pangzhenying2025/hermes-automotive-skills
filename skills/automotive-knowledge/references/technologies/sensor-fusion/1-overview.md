# Sensor Fusion - Overview

## What is Sensor Fusion?

Sensor fusion is the process of combining data from multiple sensors to produce more accurate, complete, and reliable information about the vehicle's environment than any single sensor could provide. It is fundamental to Advanced Driver Assistance Systems (ADAS) and autonomous driving (AD).

## Why Sensor Fusion is Critical

Modern vehicles use diverse sensors:
- **Camera**: Rich visual data, color, textures
- **Radar**: Velocity measurements, works in fog/rain
- **LiDAR**: Precise 3D geometry, range accuracy
- **Ultrasonic**: Close-range obstacle detection (parking)
- **GNSS/IMU**: Global position and vehicle dynamics

Each sensor has limitations. Fusion overcomes individual weaknesses.

### Example: Pedestrian Detection

| Sensor | Strengths | Weaknesses | Confidence in Rain |
|--------|-----------|------------|-------------------|
| **Camera** | Shape, color, classification | Poor in darkness, rain | Low |
| **Radar** | Velocity, works in weather | Low resolution, no classification | High |
| **LiDAR** | Precise 3D shape | Expensive, affected by heavy rain | Medium |
| **Fused** | **All strengths combined** | **Minimized weaknesses** | **High** |

## Fusion Levels

### Low-Level Fusion (Early Fusion)
Combines raw sensor data before processing.

**Example**: Merge camera pixels + LiDAR point cloud → unified perception

**Advantages**: Maximum information retention
**Challenges**: High computational cost, synchronization critical

### Mid-Level Fusion (Feature Fusion)
Combines extracted features from each sensor.

**Example**: Camera detects object bounding box + Radar provides velocity → tracked object

**Advantages**: Balanced performance and cost
**Challenges**: Feature representation compatibility

### High-Level Fusion (Late Fusion)
Combines independent object detections from each sensor.

**Example**: Camera detects "car at 50m" + Radar detects "object at 51m moving 30 km/h" → fused as single car

**Advantages**: Modular, sensor-independent algorithms
**Challenges**: Information loss, redundant computation

## Key Fusion Algorithms

### Kalman Filter

Linear optimal estimator for fusing noisy measurements.

**Use Cases**:
- Object tracking (position, velocity estimation)
- Sensor calibration
- Vehicle state estimation (GPS + IMU fusion)

**Limitations**: Assumes linear system dynamics and Gaussian noise

### Extended Kalman Filter (EKF)

Nonlinear extension of Kalman Filter using linearization.

**Use Cases**:
- Nonlinear motion models (turning vehicles)
- Camera-LiDAR calibration
- Simultaneous Localization and Mapping (SLAM)

### Unscented Kalman Filter (UKF)

Better nonlinear handling using sigma points instead of linearization.

**Advantages over EKF**:
- More accurate for highly nonlinear systems
- No need to compute Jacobians

**Disadvantages**:
- Higher computational cost

### Particle Filter

Monte Carlo method using weighted particles.

**Use Cases**:
- Non-Gaussian noise distributions
- Multi-modal distributions (ambiguous situations)
- SLAM in complex environments

**Trade-off**: Very flexible but computationally expensive

### Deep Learning Fusion

Neural networks learn optimal fusion strategy from data.

**Approaches**:
- Multi-modal transformers (ViT + PointNet++)
- Attention-based fusion (cross-sensor attention)
- End-to-end learned fusion (raw data → decision)

**Advantages**: Can discover non-obvious patterns
**Challenges**: Requires large datasets, explainability

## Sensor Synchronization

Accurate fusion requires time-aligned data.

### Time Synchronization Challenges

| Sensor | Typical Latency | Frame Rate | Synchronization Method |
|--------|----------------|------------|------------------------|
| Camera | 30-50 ms | 30-60 Hz | Hardware trigger + timestamp |
| LiDAR | 50-100 ms | 10-20 Hz | PTP (Precision Time Protocol) |
| Radar | 40-80 ms | 10-25 Hz | CAN timestamp + offset correction |
| GNSS | 100-200 ms | 1-10 Hz | GNSS time + interpolation |

**Solution**: Use high-precision time source (IEEE 1588 PTP) + software interpolation.

## Coordinate Frame Transformations

Sensors have different coordinate frames. Fusion requires transformation to common frame.

```
Vehicle Frame (ISO 8855):
  X: Forward
  Y: Left
  Z: Up

Camera Frame:
  X: Right
  Y: Down
  Z: Forward (optical axis)

LiDAR Frame:
  X: Forward
  Y: Left
  Z: Up (usually aligned with vehicle)
```

**Calibration**: Determine extrinsic parameters (rotation, translation) between sensors.

## Sensor Fusion Pipeline

```
┌────────────────────────────────────────────────┐
│  Sensor Data Acquisition                       │
│  - Camera: 1920x1080 @ 30Hz                   │
│  - LiDAR: 64-layer @ 10Hz                     │
│  - Radar: 77GHz @ 20Hz                        │
└───────────────────┬────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  Time Synchronization & Buffering              │
│  - Align to common timestamp                   │
│  - Buffer for multi-rate fusion                │
└───────────────────┬────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  Coordinate Transformation                     │
│  - Transform to vehicle coordinate frame       │
│  - Apply calibration parameters                │
└───────────────────┬────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  Feature Extraction (per sensor)               │
│  - Camera: Object detection (YOLO, etc.)       │
│  - LiDAR: Clustering, segmentation             │
│  - Radar: Target list                          │
└───────────────────┬────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  Data Association                              │
│  - Match detections across sensors             │
│  - Hungarian algorithm, GNN                    │
└───────────────────┬────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  State Estimation (Kalman Filter)              │
│  - Fuse measurements                           │
│  - Predict object state (position, velocity)   │
└───────────────────┬────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  Object Tracking                               │
│  - Track objects over time                     │
│  - Handle occlusions, splits, merges           │
└───────────────────┬────────────────────────────┘
                    ↓
┌────────────────────────────────────────────────┐
│  Output: Fused Object List                     │
│  - ID, position, velocity, class, confidence   │
└────────────────────────────────────────────────┘
```

## Industry Standards

### ISO 26262 Functional Safety
Sensor fusion for ADAS/AD must meet safety requirements.

**Safety Considerations**:
- Sensor failure detection (plausibility checks)
- Graceful degradation (continue with fewer sensors)
- ASIL decomposition (distribute safety requirements across sensors)

### ISO 21448 SOTIF
Safety Of The Intended Functionality addresses performance limitations.

**SOTIF for Fusion**:
- Define known unsafe scenarios (e.g., radar ghost targets)
- Validation in edge cases (heavy rain, sun glare)
- Continuous monitoring for unknown unsafe scenarios

## Use Cases by Autonomy Level

### L2 (Partial Automation)
- **Adaptive Cruise Control**: Radar + camera fusion for lead vehicle tracking
- **Lane Keep Assist**: Camera lane detection + GPS localization
- **Automatic Emergency Braking**: Camera + radar for pedestrian/vehicle detection

### L3 (Conditional Automation)
- **Traffic Jam Pilot**: Camera + radar + ultrasonic for stop-and-go driving
- **Highway Pilot**: + LiDAR for better lane boundary detection

### L4/L5 (High/Full Automation)
- **Urban Autonomous Driving**: Camera + LiDAR + Radar + HD maps + V2X
- **Robotaxi**: Multi-sensor redundancy for safety

## Performance Metrics

### Detection Metrics
- **Precision**: True Positives / (True Positives + False Positives)
- **Recall**: True Positives / (True Positives + False Negatives)
- **F1 Score**: Harmonic mean of precision and recall

### Tracking Metrics
- **MOTA** (Multiple Object Tracking Accuracy): Overall tracking quality
- **MOTP** (Multiple Object Tracking Precision): Position accuracy
- **ID Switches**: Number of track identity changes (lower is better)

### Latency
- **End-to-end latency**: Sensor acquisition → fused output
- **Target**: <100ms for ADAS, <50ms for L4+ AD

## Next Steps

- **Level 2**: Conceptual understanding of fusion architectures
- **Level 3**: Detailed Kalman filter implementation guide
- **Level 4**: Reference tables for sensor specifications
- **Level 5**: Advanced deep learning fusion and transformer models

## References

- ISO 26262: Road vehicles - Functional safety
- ISO 21448: Road vehicles - Safety of the intended functionality (SOTIF)
- SAE J3016: Taxonomy of driving automation levels
- IEEE 1588: Precision Time Protocol (PTP)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: ADAS/AD engineers, perception engineers, fusion algorithm developers

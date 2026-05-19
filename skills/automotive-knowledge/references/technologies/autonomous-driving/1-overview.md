# Autonomous Driving - Overview

## What is Autonomous Driving?

Autonomous driving (AD) refers to vehicles capable of sensing their environment and operating without human intervention. Systems range from simple driver assistance features to fully self-driving vehicles that require no human oversight.

## SAE Automation Levels

The Society of Automotive Engineers (SAE J3016) defines six levels of driving automation:

### Level 0: No Automation
- Human driver performs all driving tasks
- May have warnings or momentary intervention (e.g., forward collision warning)

### Level 1: Driver Assistance
- Vehicle assists with either steering OR acceleration/braking
- Human driver monitors environment and performs all other tasks
- **Examples**: Adaptive cruise control (ACC), lane centering assist

### Level 2: Partial Automation
- Vehicle controls both steering AND acceleration/braking simultaneously
- Human driver must monitor environment and be ready to intervene
- **Examples**: Tesla Autopilot, GM Super Cruise, Mercedes Drive Pilot (in certain conditions)

### Level 3: Conditional Automation
- Vehicle performs all driving tasks under specific conditions
- Human driver must be available to take over when requested
- **Examples**: Mercedes Drive Pilot (traffic jam pilot), Honda Legend (traffic jam pilot in Japan)

### Level 4: High Automation
- Vehicle performs all driving tasks in defined operational design domain (ODD)
- No human intervention required within ODD
- **Examples**: Waymo One (geofenced robotaxi), Cruise Origin, delivery robots

### Level 5: Full Automation
- Vehicle performs all driving tasks in all conditions
- No human driver needed
- **Status**: Not yet commercially available (research only)

## AD Stack Architecture

A typical autonomous driving system consists of five major subsystems:

```
┌─────────────────────────────────────────────────────────┐
│                    SENSORS                              │
│  Camera  │  LiDAR  │  Radar  │  GNSS/IMU  │  Ultrasonic│
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│                  PERCEPTION                             │
│  Object Detection │ Tracking │ Segmentation │ Localization
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│                  PREDICTION                             │
│  Trajectory Prediction │ Intention Recognition │ Risk Assessment
└────────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│                   PLANNING                              │
│  Route Planning │ Behavior Planning │ Motion Planning   │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│                   CONTROL                               │
│  Longitudinal Control │ Lateral Control │ Actuation     │
└─────────────────────────────────────────────────────────┘
                     ↓
                 VEHICLE
```

### Perception
Interprets raw sensor data to understand the environment:
- **Object Detection**: Identify vehicles, pedestrians, cyclists, static objects
- **Tracking**: Maintain object identity over time
- **Segmentation**: Classify road, lane markings, drivable area
- **Localization**: Determine vehicle position on HD map

### Prediction
Forecasts future behavior of detected objects:
- **Trajectory Prediction**: Where will other vehicles/pedestrians move?
- **Intention Recognition**: Is that vehicle changing lanes? Is the pedestrian crossing?
- **Risk Assessment**: Which objects pose collision risk?

### Planning
Determines the vehicle's intended motion:
- **Route Planning**: High-level path from origin to destination (A* on road graph)
- **Behavior Planning**: Tactical decisions (lane change, yield, merge)
- **Motion Planning**: Low-level trajectory (position, velocity, acceleration over time)

### Control
Executes the planned trajectory:
- **Longitudinal Control**: Throttle and brake commands
- **Lateral Control**: Steering commands
- **Actuation**: Low-level vehicle control (ESC, EPS integration)

## Key Challenges

### Safety Validation
- **Long-tail scenarios**: Rare edge cases dominate safety metrics
- **Validation burden**: Billions of miles needed to prove safety
- **Simulation gap**: Sim-to-real transfer remains imperfect

### Perception Robustness
- **Adverse weather**: Rain, fog, snow degrade sensor performance
- **Lighting conditions**: Glare, darkness, shadows affect cameras
- **Occlusion**: Objects hidden behind others or infrastructure

### Prediction Uncertainty
- **Multi-modal futures**: Many plausible futures for each agent
- **Human irrationality**: Pedestrians and drivers don't always follow rules
- **Interaction modeling**: How do other agents react to ego vehicle?

### Planning Complexity
- **Combinatorial explosion**: Exponential growth in possible maneuvers
- **Comfort vs efficiency**: Balancing passenger comfort with progress
- **Norm compliance**: Following unwritten driving customs

### Regulatory and Liability
- **Unclear regulations**: L3+ regulations still evolving in most regions
- **Liability assignment**: Who is responsible in an accident?
- **Data privacy**: Sensor data contains sensitive information

## Industry Landscape

### Robotaxi Operators
- **Waymo**: Operating in Phoenix, San Francisco, Los Angeles (L4)
- **Cruise**: Suspended operations after incidents (2023), rebuilding trust
- **Baidu Apollo**: Operating in Beijing, Shanghai, Wuhan (L4)
- **AutoX, WeRide, Pony.ai**: China-based L4 deployments

### OEM Programs
- **Mercedes-Benz**: Drive Pilot (L3) certified in Germany/Nevada
- **Tesla**: FSD Beta (L2+), camera-only approach
- **GM**: Super Cruise (L2), hands-free highway driving
- **Ford**: BlueCruise (L2), hands-free on pre-mapped highways
- **BMW, Audi, Volvo**: L2+ systems under development

### Technology Providers
- **Mobileye**: Camera-centric ADAS and SuperVision (L2+)
- **NVIDIA**: DRIVE platform (compute, sim, validation)
- **Aurora**: Self-driving stack for trucking
- **Argo AI**: Shut down (2022), talent absorbed by Ford/VW

### Sensor Suppliers
- **Luminar, Ouster, Velodyne**: LiDAR
- **Aptiv, Continental, Bosch**: Radar
- **Sony, ON Semi, Omnivision**: Cameras

## Operational Design Domain (ODD)

The ODD defines where and when an AD system is designed to operate safely.

### Geographic Constraints
- **Geofenced area**: Specific city blocks, neighborhoods
- **Road types**: Highways only, urban streets, residential areas
- **Country/region**: Regulatory approval, map coverage

### Environmental Conditions
- **Weather**: Clear weather only, light rain acceptable, no snow
- **Lighting**: Daytime only, well-lit roads at night
- **Road surface**: Paved roads only, no construction zones

### Operational Constraints
- **Speed range**: 0-35 mph (urban), 0-70 mph (highway)
- **Traffic density**: Low traffic only, moderate traffic acceptable
- **Time of day**: Daylight hours only, 24/7 operation

**Example ODDs:**
- **Waymo One**: Geofenced urban areas, 0-45 mph, clear weather, 24/7
- **Mercedes Drive Pilot**: Highway, heavy traffic, daytime, <40 mph
- **Tesla FSD Beta**: All roads (driver supervision required), L2 only

## Technology Approaches

### Modular Pipeline
Traditional approach with separate modules for each function.

**Advantages:**
- Interpretable intermediate outputs
- Easier debugging and validation
- Established engineering practices

**Challenges:**
- Information loss between modules
- Error propagation and compounding
- Manual interface design

### End-to-End Learning
Neural networks learn directly from sensors to controls.

**Advantages:**
- Implicit optimization of full stack
- No hand-crafted features
- Potentially superhuman performance

**Challenges:**
- Black-box interpretability
- Massive data requirements
- Difficult safety certification

### Hybrid Approaches
Combine learned components with rule-based safety layers.

**Examples:**
- Learned perception + classical planning
- Learned prediction + MPC control
- Learned planner with rule-based verification

## Getting Started

To develop AD systems:

1. **Understand the ODD**: Define operational constraints
2. **Acquire sensor suite**: Camera, radar, LiDAR based on needs
3. **Build perception**: Detection, tracking, localization
4. **Implement planning**: Behavior and motion planning
5. **Validate safety**: Simulation, closed-course, public road testing

## Comparison: ADAS vs Autonomous Driving

| Aspect | ADAS (L0-L2) | Autonomous Driving (L3-L5) |
|--------|--------------|---------------------------|
| **Driver role** | Always in control | Fallback (L3) or none (L4+) |
| **Responsibility** | Driver liable | System (L3+) or no driver (L4+) |
| **Sensor suite** | Camera + radar | + LiDAR + HD maps |
| **Compute** | 10-100 TOPS | 100-1000+ TOPS |
| **Software complexity** | 1-10M LOC | 10-100M+ LOC |
| **Development cost** | $10-100M | $1-10B+ |
| **Safety target** | No regression | 10x safer than human |
| **Validation** | NCAP, IIHS tests | Billions of miles |

## Metrics and KPIs

### Safety Metrics
- **Miles per disengagement**: Higher is better (Waymo: ~17,000 miles/disengagement in CA)
- **Critical event rate**: Incidents per million miles
- **Accident rate**: Compared to human baseline

### Performance Metrics
- **Object detection recall/precision**: >95% recall, <5% false positive
- **Localization accuracy**: <10 cm lateral error
- **Latency**: <100 ms end-to-end (perception to control)

### Comfort Metrics
- **Lateral acceleration**: <2 m/s² for comfort
- **Longitudinal acceleration**: <2 m/s² accel, <3 m/s² braking
- **Jerk**: <2 m/s³ (rate of acceleration change)

## Next Steps

- **Level 2**: Conceptual understanding of modular vs end-to-end architectures
- **Level 3**: Detailed implementation of perception, planning, and control
- **Level 4**: API reference for ROS2, sensor formats, evaluation metrics
- **Level 5**: Advanced topics including end-to-end learning and world models

## References

- SAE J3016: Taxonomy and Definitions for Terms Related to Driving Automation
- NHTSA Automated Vehicles Framework
- ISO 21448 (SOTIF): Safety of the Intended Functionality
- Waymo Safety Report: https://waymo.com/safety/

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Automotive engineers, product managers, system architects entering AD domain

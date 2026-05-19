# 🤖 Automotive Robotics Demo Projects

**Three impressive, production-quality demos showcasing the automotive-claude-code-agents platform**

---

## 📦 Available Demos

### 1. Line Following Robot 🚗
**Difficulty**: ⭐⭐ Intermediate
**Time**: 4-6 hours
**Tech Stack**: ROS 2, OpenCV, Python, Gazebo

A complete autonomous line-following robot using computer vision and PID control.

**Features**:
- Real-time camera-based line detection
- Adaptive PID controller
- Gazebo simulation + real hardware support
- Works with TurtleBot3 or custom robots

**[📁 View Project](./line-following-robot/)**

---

### 2. Autonomous Parking Demo 🅿️
**Difficulty**: ⭐⭐⭐ Advanced
**Time**: 8-10 hours
**Tech Stack**: CARLA, YOLOv8, Python, Hybrid A*

Advanced parking automation with perception, planning, and control.

**Features**:
- YOLOv8 parking spot detection
- Hybrid A* path planning
- Multiple parking scenarios (parallel, perpendicular, angled)
- CARLA simulator integration
- State machine implementation

**[📁 View Project](./autonomous-parking/)**

---

### 3. Multi-Robot Fleet Coordination 🤖🤖🤖
**Difficulty**: ⭐⭐⭐ Advanced
**Time**: 6-8 hours
**Tech Stack**: ROS 2, Gazebo, Python, Nav2

Warehouse automation with multiple coordinated robots.

**Features**:
- Centralized fleet management
- Collision avoidance (DWA planner)
- Task allocation algorithm
- 3 TurtleBot3 robots in Gazebo
- RViz2 visualization

**[📁 View Project](./multi-robot-fleet/)**

---

## 🎯 Quick Start (All Demos)

### Prerequisites

```bash
# ROS 2 Humble (Ubuntu 22.04)
sudo apt update
sudo apt install ros-humble-desktop-full

# CARLA Simulator (for parking demo)
# Download from: https://github.com/carla-simulator/carla/releases

# Python dependencies
pip install opencv-python numpy scipy ultralytics
```

### Running Line Following Robot

```bash
cd examples/demos/line-following-robot

# Build ROS 2 workspace
colcon build
source install/setup.bash

# Launch simulation
ros2 launch line_following line_following.launch.py

# For real hardware (TurtleBot3)
export TURTLEBOT3_MODEL=burger
ros2 launch line_following hardware.launch.py
```

### Running Autonomous Parking

```bash
cd examples/demos/autonomous-parking

# Start CARLA server (in separate terminal)
cd /path/to/CARLA
./CarlaUE4.sh

# Run parking demo
python src/parking_manager.py --scenario parallel
```

### Running Multi-Robot Fleet

```bash
cd examples/demos/multi-robot-fleet

# Build
colcon build
source install/setup.bash

# Launch multi-robot simulation
ros2 launch multi_robot_fleet warehouse.launch.py

# View in RViz2
rviz2 -d config/fleet_view.rviz
```

---

## 📊 Demo Comparison

| Feature | Line Following | Autonomous Parking | Multi-Robot Fleet |
|---------|---------------|-------------------|-------------------|
| **Complexity** | Medium | High | High |
| **Hardware Needed** | Raspberry Pi + Camera | None (sim) | None (sim) |
| **Real Robot** | ✅ TurtleBot3 | ✅ CARLA vehicle | ✅ TurtleBot3 x3 |
| **Computer Vision** | ✅ Line detection | ✅ YOLO spot detection | ❌ |
| **Path Planning** | ❌ (PID only) | ✅ Hybrid A* | ✅ Nav2 |
| **State Machine** | Simple | Advanced | Medium |
| **Multi-Agent** | ❌ | ❌ | ✅ |
| **Learning Value** | Computer vision, control | Full autonomy stack | Coordination |

---

## 🎓 Learning Objectives

### Line Following Robot
- Computer vision basics (OpenCV)
- PID controller tuning
- ROS 2 publisher/subscriber pattern
- Camera calibration
- Real-time image processing

### Autonomous Parking
- Object detection with YOLO
- Path planning algorithms
- State machine design
- CARLA simulator API
- Sensor fusion concepts

### Multi-Robot Fleet
- Multi-agent coordination
- Centralized vs distributed control
- Collision avoidance
- Task allocation algorithms
- ROS 2 namespaces and tf2

---

## 🏆 Challenges & Extensions

### Beginner Challenges
1. **Line Following**: Add obstacle detection
2. **Parking**: Implement reverse parking
3. **Fleet**: Add 4th robot

### Intermediate Challenges
1. **Line Following**: Implement lane switching
2. **Parking**: Add valet parking mode
3. **Fleet**: Implement distributed task allocation

### Advanced Challenges
1. **Line Following**: Add traffic sign detection
2. **Parking**: Full autonomous valet (find spot + park)
3. **Fleet**: Implement formation control

---

## 🎥 Video Tutorials

Coming soon:
- YouTube walkthrough for each demo
- Hardware setup guides
- Troubleshooting videos

---

## 🐛 Troubleshooting

### Common Issues

**Q: ROS 2 nodes not finding each other**
```bash
# Check ROS_DOMAIN_ID
export ROS_DOMAIN_ID=0

# Restart daemon
ros2 daemon stop
ros2 daemon start
```

**Q: CARLA won't connect**
```bash
# Check CARLA is running
ps aux | grep Carla

# Try different port
python src/parking_manager.py --carla-port 2001
```

**Q: Gazebo crashes**
```bash
# Increase memory
export GAZEBO_RESOURCE_PATH=/usr/share/gazebo-11
killall gzserver gzclient
```

---

## 📚 Additional Resources

- [ROS 2 Documentation](https://docs.ros.org/en/humble/)
- [CARLA Documentation](https://carla.readthedocs.io/)
- [OpenCV Tutorials](https://docs.opencv.org/4.x/d9/df8/tutorial_root.html)
- [Nav2 Documentation](https://navigation.ros.org/)

---

## 🤝 Contributing

Want to add your own demo?

1. Create a new directory: `examples/demos/your-demo/`
2. Follow the structure of existing demos
3. Include complete README with:
   - Requirements
   - Installation
   - Usage
   - Learning objectives
4. Add to this master README
5. Submit PR!

---

## 📄 License

MIT License - See LICENSE file in repository root

---

## ✨ Acknowledgments

- ROS 2 Community
- CARLA Team
- OpenCV Foundation
- TurtleBot3 (ROBOTIS)

---

**Ready to build autonomous systems? Pick a demo and start coding!** 🚀

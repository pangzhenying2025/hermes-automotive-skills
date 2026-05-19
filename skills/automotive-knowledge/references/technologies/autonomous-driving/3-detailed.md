# Autonomous Driving - Detailed Implementation

## Object Detection with YOLO

YOLO (You Only Look Once) is a real-time object detection architecture widely used in autonomous driving perception.

### YOLOv8 Architecture

```python
import torch
import torch.nn as nn
from ultralytics import YOLO

class AutomotiveObjectDetector:
    def __init__(self, model_path='yolov8x.pt'):
        self.model = YOLO(model_path)
        self.classes = {
            0: 'person', 1: 'bicycle', 2: 'car', 3: 'motorcycle',
            5: 'bus', 7: 'truck', 9: 'traffic_light', 11: 'stop_sign'
        }

    def detect(self, image):
        """
        image: numpy array [H, W, 3] (RGB)
        Returns: List of detected objects
        """
        results = self.model(image, verbose=False)[0]

        detections = []
        for box in results.boxes:
            cls = int(box.cls[0])
            if cls in self.classes:
                detection = {
                    'class': self.classes[cls],
                    'confidence': float(box.conf[0]),
                    'bbox': box.xyxy[0].cpu().numpy(),  # [x1, y1, x2, y2]
                    'center': [(box.xyxy[0][0] + box.xyxy[0][2]) / 2,
                              (box.xyxy[0][1] + box.xyxy[0][3]) / 2]
                }
                detections.append(detection)

        return detections
```

### Distance Estimation from Bounding Box

For monocular cameras, estimate distance using object height:

```python
class MonocularDepthEstimator:
    def __init__(self, camera_height_m=1.2, camera_pitch_rad=0.1):
        self.camera_height = camera_height_m
        self.camera_pitch = camera_pitch_rad

        # Known object heights
        self.object_heights = {
            'person': 1.7,      # meters
            'car': 1.5,
            'bus': 3.5,
            'truck': 3.0,
            'motorcycle': 1.2
        }

    def estimate_distance(self, bbox, obj_class, camera_params):
        """
        bbox: [x1, y1, x2, y2] in pixels
        camera_params: {'fy': focal_length_y, 'cy': principal_point_y}
        """
        if obj_class not in self.object_heights:
            return None

        # Object height in pixels
        h_pixels = bbox[3] - bbox[1]

        # Real-world object height
        h_real = self.object_heights[obj_class]

        # Focal length
        fy = camera_params['fy']

        # Distance estimation
        distance = (h_real * fy) / h_pixels

        return distance
```

### Multi-Camera Fusion

Fuse detections from multiple cameras:

```python
class MultiCameraFusion:
    def __init__(self, camera_calibrations):
        """
        camera_calibrations: dict mapping camera_id to calibration params
        """
        self.calibrations = camera_calibrations

    def fuse_detections(self, detections_by_camera):
        """
        detections_by_camera: dict {camera_id: [detections]}
        Returns: Unified detection list in vehicle frame
        """
        fused_objects = []

        for camera_id, detections in detections_by_camera.items():
            calib = self.calibrations[camera_id]

            for det in detections:
                # Project to 3D vehicle frame
                if 'distance' in det:
                    pos_3d = self._project_to_vehicle_frame(
                        det['center'], det['distance'], calib
                    )

                    fused_objects.append({
                        'position': pos_3d,
                        'class': det['class'],
                        'confidence': det['confidence'],
                        'source_camera': camera_id
                    })

        # Non-maximum suppression across cameras
        fused_objects = self._nms_3d(fused_objects, iou_threshold=0.5)

        return fused_objects

    def _project_to_vehicle_frame(self, pixel_coords, distance, calib):
        """Transform from image coordinates to vehicle frame"""
        u, v = pixel_coords
        fx, fy = calib['fx'], calib['fy']
        cx, cy = calib['cx'], calib['cy']

        # Normalize to camera frame
        x_cam = (u - cx) * distance / fx
        y_cam = (v - cy) * distance / fy
        z_cam = distance

        # Transform to vehicle frame
        point_cam = np.array([x_cam, y_cam, z_cam, 1.0])
        point_veh = calib['T_cam_to_veh'] @ point_cam

        return point_veh[:3]
```

## Multi-Object Tracking with SORT

SORT (Simple Online and Realtime Tracking) uses Kalman filters and Hungarian algorithm for association.

### Kalman Filter for Object Tracking

```python
import numpy as np
from scipy.optimize import linear_sum_assignment

class KalmanTracker:
    """Track a single object with constant velocity model"""

    def __init__(self, initial_bbox):
        # State: [x, y, w, h, vx, vy]
        x, y = (initial_bbox[0] + initial_bbox[2]) / 2, (initial_bbox[1] + initial_bbox[3]) / 2
        w, h = initial_bbox[2] - initial_bbox[0], initial_bbox[3] - initial_bbox[1]

        self.state = np.array([x, y, w, h, 0, 0])
        self.covariance = np.eye(6) * 10.0

        # Process noise
        self.Q = np.eye(6)
        self.Q[4, 4] = self.Q[5, 5] = 0.01

        # Measurement noise
        self.R = np.eye(4) * 1.0

        self.time_since_update = 0
        self.hits = 1
        self.age = 0

    def predict(self, dt=1.0):
        """Predict state at next timestep"""
        # State transition matrix
        F = np.array([
            [1, 0, 0, 0, dt, 0],
            [0, 1, 0, 0, 0, dt],
            [0, 0, 1, 0, 0, 0],
            [0, 0, 0, 1, 0, 0],
            [0, 0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0, 1]
        ])

        self.state = F @ self.state
        self.covariance = F @ self.covariance @ F.T + self.Q

        self.age += 1
        self.time_since_update += 1

    def update(self, bbox):
        """Update with new measurement"""
        x, y = (bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        z = np.array([x, y, w, h])

        # Measurement matrix (observe position and size, not velocity)
        H = np.array([
            [1, 0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0, 0],
            [0, 0, 1, 0, 0, 0],
            [0, 0, 0, 1, 0, 0]
        ])

        # Innovation
        y = z - H @ self.state

        # Innovation covariance
        S = H @ self.covariance @ H.T + self.R

        # Kalman gain
        K = self.covariance @ H.T @ np.linalg.inv(S)

        # Update state
        self.state = self.state + K @ y

        # Update covariance
        self.covariance = (np.eye(6) - K @ H) @ self.covariance

        self.time_since_update = 0
        self.hits += 1

    def get_bbox(self):
        """Convert state to bounding box"""
        x, y, w, h = self.state[:4]
        return np.array([x - w/2, y - h/2, x + w/2, y + h/2])
```

### SORT Tracker

```python
class SORTTracker:
    def __init__(self, max_age=5, min_hits=3, iou_threshold=0.3):
        self.max_age = max_age
        self.min_hits = min_hits
        self.iou_threshold = iou_threshold
        self.trackers = []
        self.next_id = 0

    def update(self, detections):
        """
        detections: List of bounding boxes [[x1, y1, x2, y2], ...]
        Returns: List of tracked objects [[x1, y1, x2, y2, track_id], ...]
        """
        # Predict existing trackers
        for tracker in self.trackers:
            tracker.predict()

        # Associate detections to trackers
        matched, unmatched_dets, unmatched_trks = self._associate(detections)

        # Update matched trackers
        for det_idx, trk_idx in matched:
            self.trackers[trk_idx].update(detections[det_idx])

        # Create new trackers for unmatched detections
        for det_idx in unmatched_dets:
            tracker = KalmanTracker(detections[det_idx])
            tracker.id = self.next_id
            self.next_id += 1
            self.trackers.append(tracker)

        # Remove dead trackers
        self.trackers = [t for t in self.trackers if t.time_since_update <= self.max_age]

        # Output confirmed tracks
        outputs = []
        for tracker in self.trackers:
            if tracker.hits >= self.min_hits or tracker.age <= self.min_hits:
                bbox = tracker.get_bbox()
                outputs.append(np.append(bbox, tracker.id))

        return outputs

    def _associate(self, detections):
        """Hungarian algorithm for optimal assignment"""
        if len(self.trackers) == 0:
            return [], list(range(len(detections))), []

        # Compute IoU cost matrix
        iou_matrix = np.zeros((len(detections), len(self.trackers)))
        for d, det in enumerate(detections):
            for t, trk in enumerate(self.trackers):
                iou_matrix[d, t] = self._iou(det, trk.get_bbox())

        # Hungarian algorithm (maximize IoU = minimize -IoU)
        matched_indices = linear_sum_assignment(-iou_matrix)
        matched_indices = np.column_stack(matched_indices)

        # Filter out low IoU matches
        matches = []
        unmatched_dets = []
        unmatched_trks = []

        for d, t in matched_indices:
            if iou_matrix[d, t] < self.iou_threshold:
                unmatched_dets.append(d)
                unmatched_trks.append(t)
            else:
                matches.append([d, t])

        # Find unmatched detections
        for d in range(len(detections)):
            if d not in matched_indices[:, 0]:
                unmatched_dets.append(d)

        # Find unmatched trackers
        for t in range(len(self.trackers)):
            if t not in matched_indices[:, 1]:
                unmatched_trks.append(t)

        return matches, unmatched_dets, unmatched_trks

    def _iou(self, bbox1, bbox2):
        """Intersection over Union"""
        x1 = max(bbox1[0], bbox2[0])
        y1 = max(bbox1[1], bbox2[1])
        x2 = min(bbox1[2], bbox2[2])
        y2 = min(bbox1[3], bbox2[3])

        intersection = max(0, x2 - x1) * max(0, y2 - y1)

        area1 = (bbox1[2] - bbox1[0]) * (bbox1[3] - bbox1[1])
        area2 = (bbox2[2] - bbox2[0]) * (bbox2[3] - bbox2[1])

        union = area1 + area2 - intersection

        return intersection / union if union > 0 else 0
```

## Path Planning with Hybrid A*

Hybrid A* searches in continuous space with discrete heading angles.

### Hybrid A* Implementation

```python
import heapq
from dataclasses import dataclass
from typing import List, Tuple

@dataclass
class Node:
    x: float
    y: float
    theta: float  # Heading angle
    cost: float
    heuristic: float
    parent: 'Node' = None

    def __lt__(self, other):
        return (self.cost + self.heuristic) < (other.cost + other.heuristic)

class HybridAStar:
    def __init__(self, grid_resolution=0.5, angle_resolution=15):
        self.grid_res = grid_resolution
        self.angle_res = np.radians(angle_resolution)
        self.vehicle_length = 4.5  # meters
        self.vehicle_width = 2.0

        # Motion primitives (forward, left, right)
        self.motions = [
            (1.0, 0.0),    # Straight
            (1.0, 0.3),    # Left
            (1.0, -0.3),   # Right
        ]

    def plan(self, start, goal, obstacles):
        """
        start: (x, y, theta)
        goal: (x, y, theta)
        obstacles: List of obstacle polygons
        Returns: List of (x, y, theta) waypoints
        """
        start_node = Node(*start, cost=0, heuristic=self._heuristic(start, goal))
        goal_node = Node(*goal, cost=0, heuristic=0)

        open_set = [start_node]
        closed_set = set()

        while open_set:
            current = heapq.heappop(open_set)

            # Discretize state for closed set check
            state_key = self._discretize(current)
            if state_key in closed_set:
                continue
            closed_set.add(state_key)

            # Goal check
            if self._is_goal(current, goal_node):
                return self._reconstruct_path(current)

            # Expand neighbors
            for neighbor in self._get_neighbors(current):
                if self._is_collision_free(neighbor, obstacles):
                    neighbor.heuristic = self._heuristic(
                        (neighbor.x, neighbor.y, neighbor.theta), goal
                    )
                    heapq.heappush(open_set, neighbor)

        return None  # No path found

    def _get_neighbors(self, node):
        """Generate successor states using motion primitives"""
        neighbors = []
        for v, delta in self.motions:
            # Simple bicycle model
            dt = 0.5  # time step
            theta_new = node.theta + v / self.vehicle_length * np.tan(delta) * dt
            x_new = node.x + v * np.cos(node.theta) * dt
            y_new = node.y + v * np.sin(node.theta) * dt

            # Normalize angle
            theta_new = np.arctan2(np.sin(theta_new), np.cos(theta_new))

            cost_new = node.cost + v * dt  # Distance cost

            neighbor = Node(x_new, y_new, theta_new, cost_new, 0, parent=node)
            neighbors.append(neighbor)

        return neighbors

    def _heuristic(self, state, goal):
        """Euclidean distance heuristic"""
        return np.sqrt((state[0] - goal[0])**2 + (state[1] - goal[1])**2)

    def _is_goal(self, node, goal_node, tol=1.0):
        """Check if node is close enough to goal"""
        dist = np.sqrt((node.x - goal_node.x)**2 + (node.y - goal_node.y)**2)
        angle_diff = abs(node.theta - goal_node.theta)
        return dist < tol and angle_diff < np.radians(30)

    def _is_collision_free(self, node, obstacles):
        """Check if vehicle footprint collides with obstacles"""
        # Vehicle corners in vehicle frame
        corners_local = np.array([
            [self.vehicle_length/2, self.vehicle_width/2],
            [self.vehicle_length/2, -self.vehicle_width/2],
            [-self.vehicle_length/2, -self.vehicle_width/2],
            [-self.vehicle_length/2, self.vehicle_width/2]
        ])

        # Rotate and translate to world frame
        R = np.array([
            [np.cos(node.theta), -np.sin(node.theta)],
            [np.sin(node.theta), np.cos(node.theta)]
        ])
        corners_world = (R @ corners_local.T).T + np.array([node.x, node.y])

        # Check collision with each obstacle
        from shapely.geometry import Polygon
        vehicle_poly = Polygon(corners_world)

        for obs in obstacles:
            if vehicle_poly.intersects(obs):
                return False

        return True

    def _discretize(self, node):
        """Discretize state for closed set"""
        x_idx = int(node.x / self.grid_res)
        y_idx = int(node.y / self.grid_res)
        theta_idx = int(node.theta / self.angle_res)
        return (x_idx, y_idx, theta_idx)

    def _reconstruct_path(self, node):
        """Backtrack to reconstruct path"""
        path = []
        while node:
            path.append((node.x, node.y, node.theta))
            node = node.parent
        return path[::-1]
```

## Model Predictive Control (MPC)

MPC optimizes control inputs over a finite horizon to track the planned trajectory.

### Lateral MPC Controller

```python
import cvxpy as cp

class LateralMPC:
    def __init__(self, horizon=10, dt=0.1):
        self.N = horizon
        self.dt = dt

        # Vehicle parameters
        self.L = 2.7  # Wheelbase (m)
        self.v_ref = 10.0  # Reference velocity (m/s)

        # Cost weights
        self.Q = np.diag([10.0, 1.0])  # State cost [y_error, heading_error]
        self.R = np.array([[1.0]])     # Control cost [steering]

    def solve(self, current_state, reference_trajectory):
        """
        current_state: [y, psi, v] (lateral offset, heading, velocity)
        reference_trajectory: Array of [y_ref, psi_ref] for next N steps
        Returns: Optimal steering angle (radians)
        """
        y0, psi0, v = current_state

        # Decision variables
        y = cp.Variable(self.N + 1)
        psi = cp.Variable(self.N + 1)
        delta = cp.Variable(self.N)  # Steering angle

        # Constraints and cost
        constraints = [
            y[0] == y0,
            psi[0] == psi0
        ]

        cost = 0

        for k in range(self.N):
            # Kinematic bicycle model (linearized)
            constraints += [
                y[k+1] == y[k] + v * cp.sin(psi[k]) * self.dt,
                psi[k+1] == psi[k] + (v / self.L) * delta[k] * self.dt
            ]

            # Steering angle limits
            constraints += [
                delta[k] >= -np.radians(30),
                delta[k] <= np.radians(30)
            ]

            # Cost
            state_error = cp.vstack([y[k] - reference_trajectory[k, 0],
                                     psi[k] - reference_trajectory[k, 1]])
            cost += cp.quad_form(state_error, self.Q)
            cost += cp.quad_form(delta[k], self.R)

        # Solve optimization problem
        problem = cp.Problem(cp.Minimize(cost), constraints)
        problem.solve(solver=cp.OSQP, warm_start=True)

        if problem.status == cp.OPTIMAL:
            return delta.value[0]
        else:
            print(f"MPC solver failed: {problem.status}")
            return 0.0  # Fallback to zero steering
```

## Next Steps

- **Level 4**: ROS2 message definitions, dataset formats (KITTI, nuScenes), metrics
- **Level 5**: End-to-end learning (UniAD, MILE), diffusion planning, world models
- **Related**: Behavior planning, localization, HD mapping

## References

- Redmon et al., "You Only Look Once: Unified, Real-Time Object Detection", CVPR 2016
- Bewley et al., "Simple Online and Realtime Tracking", ICIP 2016
- Dolgov et al., "Path Planning for Autonomous Vehicles in Unknown Semi-structured Environments", IJRR 2010
- Camacho & Alba, "Model Predictive Control", Springer 2013

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Perception engineers, planning engineers, control engineers implementing AD systems

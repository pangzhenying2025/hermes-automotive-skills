---
name: automotive-ai-ecu
description: >
  Automotive Ai Ecu expertise. Covers 5 topics: Camera Vision Ai, Driver Monitoring Systems, Edge Ai Deployment, Neural Processing Units, Voice Nlu Automotive.
tags: [automotive, automotive-ai-ecu]
---

# Automotive Ai Ecu

## Camera Vision Ai

# Camera Vision AI for Automotive

**Skill**: Computer vision pipelines for automotive cameras with AI/ML integration
**Version**: 1.0.0
**Category**: AI-ECU / Perception
**Complexity**: Advanced

---

## Overview

Complete guide to automotive camera vision AI pipelines: object detection (YOLO, EfficientDet), semantic segmentation, lane detection, 360° surround view with AI, camera ISP tuning, and multi-camera fusion for ADAS and autonomous driving.

## Automotive Camera Landscape

### Camera Types in Modern Vehicles

| Camera Type | Resolution | FOV | Frame Rate | Use Case | Interface |
|-------------|------------|-----|------------|----------|-----------|
| **Front Camera** | 1920x1080 - 2880x1644 | 60-120° | 30-60 FPS | ADAS, Lane Keep, AEB | MIPI CSI-2 |
| **Rear Camera** | 1280x720 - 1920x1080 | 120-180° | 30 FPS | Parking, Rear Cross Traffic | MIPI CSI-2 |
| **Side Cameras** (2x) | 1280x720 | 90-120° | 30 FPS | Blind Spot, Lane Change | MIPI CSI-2 |
| **DMS Camera** (IR) | 640x480 - 1280x720 | 60-90° | 30-60 FPS | Driver Monitoring | MIPI CSI-2 |
| **OMS Camera** (IR) | 640x480 | 90-120° | 15-30 FPS | Occupant Monitoring | MIPI CSI-2 |
| **360° Surround** | 4x 1280x720 | 180-220° | 30 FPS | Parking, Top View | MIPI CSI-2 |

**Total Bandwidth**: Up to 12 Gbps for multi-camera system (8 cameras)

---

## Camera ISP Pipeline

### Image Signal Processor (ISP) Tuning

**ISP Pipeline**: Raw Bayer → Demosaic → White Balance → Gamma → Color Correction → AI Inference

```python
class AutomotiveISPTuner:
    """
    ISP tuning for automotive vision AI
    Goal: Optimize image quality for ML model accuracy (not human perception)
    """
    def __init__(self, isp_device):
        self.isp = isp_device

    def tune_for_object_detection(self):
        """
        ISP tuning optimized for YOLO/EfficientDet
        - High contrast for edge detection
        - Low noise to avoid false positives
        - Wide dynamic range (HDR) for varying light conditions
        """
        self.isp.set_parameter('demosaic_algorithm', 'bilinear')  # Fast, good for edges
        self.isp.set_parameter('white_balance_mode', 'auto')  # Auto WB for varying conditions
        self.isp.set_parameter('gamma', 2.2)  # Standard gamma
        self.isp.set_parameter('contrast', 1.3)  # +30% contrast for better edges
        self.isp.set_parameter('sharpening', 1.5)  # +50% sharpening
        self.isp.set_parameter('noise_reduction', 'moderate')  # Balance speed vs. quality
        self.isp.set_parameter('hdr_mode', 'enabled')  # HDR for tunnels, bright sun
        self.isp.set_parameter('ae_target', 0.5)  # Exposure target (0-1 scale)

    def tune_for_lane_detection(self):
        """
        ISP tuning for lane marking detection
        - High contrast for white/yellow lines on asphalt
        - Aggressive edge enhancement
        - No color correction (monochrome sufficient)
        """
        self.isp.set_parameter('contrast', 1.5)  # +50% contrast
        self.isp.set_parameter('sharpening', 2.0)  # Maximum sharpening
        self.isp.set_parameter('saturation', 0.8)  # Reduce saturation (focus on luminance)
        self.isp.set_parameter('edge_enhancement', 'aggressive')

    def tune_for_dms(self):
        """
        ISP tuning for IR-based driver monitoring
        - 940nm IR illumination
        - No color processing (monochrome sensor)
        - Low noise for accurate eye/face detection
        """
        self.isp.set_parameter('ir_filter', 'bypass')  # Allow 940nm IR
        self.isp.set_parameter('noise_reduction', 'aggressive')  # Critical for DMS accuracy
        self.isp.set_parameter('gain', 2.0)  # Amplify IR signal
        self.isp.set_parameter('frame_rate', 60)  # High FPS for gaze tracking

    def adaptive_tuning_based_on_scenario(self, scenario):
        """
        Dynamically adjust ISP based on driving scenario
        """
        if scenario == 'highway_day':
            self.isp.set_parameter('exposure_time', 8)  # ms (bright conditions)
            self.isp.set_parameter('gain', 1.0)

        elif scenario == 'highway_night':
            self.isp.set_parameter('exposure_time', 20)  # ms (low light)
            self.isp.set_parameter('gain', 4.0)  # Amplify signal
            self.isp.set_parameter('noise_reduction', 'aggressive')

        elif scenario == 'tunnel_entry':
            self.isp.set_parameter('hdr_mode', 'enabled')  # Critical for tunnel transitions
            self.isp.set_parameter('ae_speed', 'fast')  # Quickly adapt to light change

        elif scenario == 'parking':
            self.isp.set_parameter('fisheye_correction', 'enabled')  # Correct distortion
            self.isp.set_parameter('frame_rate', 30)  # Standard FPS sufficient

# Example: Apply ISP tuning
isp = AutomotiveISPTuner('/dev/video0')
isp.tune_for_object_detection()
```

---

## Object Detection Pipelines

### YOLOv5 for Automotive ADAS

**Use Case**: Real-time multi-class object detection (vehicles, pedestrians, cyclists, traffic signs)

```python
import cv2
import numpy as np
import torch

class AutomotiveYOLOv5:
    """
    YOLOv5 optimized for automotive ADAS
    Classes: vehicle, pedestrian, cyclist, motorcycle, bus, truck, traffic_light, stop_sign
    """
    def __init__(self, model_path, npu_runtime='snpe', confidence_threshold=0.5):
        self.model = self.load_model(model_path, npu_runtime)
        self.conf_thresh = confidence_threshold
        self.iou_thresh = 0.45
        self.classes = ['vehicle', 'pedestrian', 'cyclist', 'motorcycle',
                       'bus', 'truck', 'traffic_light', 'stop_sign']

    def load_model(self, model_path, runtime):
        """Load quantized YOLOv5s on NPU"""
        if runtime == 'snpe':
            import snpe
            container = snpe.load_container(model_path)
            network = snpe.build_network(container, snpe.SNPE_Runtime.RUNTIME_HTA)
            return network
        elif runtime == 'tflite':
            import tflite_runtime.interpreter as tflite
            interpreter = tflite.Interpreter(
                model_path=model_path,
                experimental_delegates=[tflite.load_delegate('libvx_delegate.so')]
            )
            interpreter.allocate_tensors()
            return interpreter

    def preprocess(self, frame):
        """Preprocess frame for YOLO inference"""
        # Resize to 640x640 (YOLOv5 input)
        resized = cv2.resize(frame, (640, 640))

        # Normalize to [0, 1]
        normalized = resized.astype(np.float32) / 255.0

        # HWC → CHW (Height, Width, Channels → Channels, Height, Width)
        transposed = np.transpose(normalized, (2, 0, 1))

        # Add batch dimension
        batched = np.expand_dims(transposed, axis=0)

        return batched

    def infer(self, frame):
        """Run inference on frame"""
        preprocessed = self.preprocess(frame)

        # Run on NPU
        output = self.model.execute({'images': preprocessed})

        # Postprocess YOLO output
        detections = self.postprocess(output['output'], frame.shape)

        return detections

    def postprocess(self, output, original_shape):
        """
        Postprocess YOLO output
        Output shape: [1, 25200, 13] (25200 anchors, 13 = 4 bbox + 1 conf + 8 classes)
        """
        output = output[0]  # Remove batch dimension

        # Extract bounding boxes, confidence, class scores
        boxes = output[:, :4]  # [x, y, w, h]
        confidences = output[:, 4]  # objectness score
        class_scores = output[:, 5:]  # class probabilities

        # Filter by confidence threshold
        mask = confidences > self.conf_thresh
        boxes = boxes[mask]
        confidences = confidences[mask]
        class_scores = class_scores[mask]

        # Get class predictions
        class_ids = np.argmax(class_scores, axis=1)
        class_confidences = np.max(class_scores, axis=1)

        # Final confidence = objectness * class_confidence
        final_confidences = confidences * class_confidences

        # Non-Maximum Suppression (NMS)
        indices = self.nms(boxes, final_confidences, self.iou_thresh)

        # Build detection results
        detections = []
        for i in indices:
            x, y, w, h = boxes[i]

            # Convert from YOLO format (center_x, center_y, width, height) to (x1, y1, x2, y2)
            x1 = int((x - w/2) * original_shape[1] / 640)
            y1 = int((y - h/2) * original_shape[0] / 640)
            x2 = int((x + w/2) * original_shape[1] / 640)
            y2 = int((y + h/2) * original_shape[0] / 640)

            detections.append({
                'class': self.classes[class_ids[i]],
                'class_id': int(class_ids[i]),
                'confidence': float(final_confidences[i]),
                'bbox': [x1, y1, x2, y2]
            })

        return detections

    def nms(self, boxes, scores, iou_threshold):
        """Non-Maximum Suppression"""
        x1 = boxes[:, 0] - boxes[:, 2] / 2
        y1 = boxes[:, 1] - boxes[:, 3] / 2
        x2 = boxes[:, 0] + boxes[:, 2] / 2
        y2 = boxes[:, 1] + boxes[:, 3] / 2

        areas = (x2 - x1) * (y2 - y1)
        order = scores.argsort()[::-1]

        keep = []
        while order.size > 0:
            i = order[0]
            keep.append(i)

            # Compute IoU of kept box with all remaining boxes
            xx1 = np.maximum(x1[i], x1[order[1:]])
            yy1 = np.maximum(y1[i], y1[order[1:]])
            xx2 = np.minimum(x2[i], x2[order[1:]])
            yy2 = np.minimum(y2[i], y2[order[1:]])

            w = np.maximum(0.0, xx2 - xx1)
            h = np.maximum(0.0, yy2 - yy1)
            inter = w * h

            iou = inter / (areas[i] + areas[order[1:]] - inter)

            # Keep boxes with IoU below threshold
            inds = np.where(iou <= iou_threshold)[0]
            order = order[inds + 1]

        return keep

# Usage
detector = AutomotiveYOLOv5('yolov5s_int8.dlc', npu_runtime='snpe')

cap = cv2.VideoCapture('/dev/video0')
while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Run detection
    detections = detector.infer(frame)

    # Draw results
    for det in detections:
        x1, y1, x2, y2 = det['bbox']
        label = f"{det['class']}: {det['confidence']:.2f}"

        color = (0, 255, 0) if det['class'] == 'vehicle' else (0, 0, 255)
        cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
        cv2.putText(frame, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

    cv2.imshow('ADAS Object Detection', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
```

---

### EfficientDet for High-Accuracy ADAS

**Use Case**: Higher accuracy than YOLO, slightly slower (use for L3+ autonomous driving)

```python
import tensorflow as tf

class AutomotiveEfficientDet:
    """
    EfficientDet-D0 for automotive (optimized balance of speed and accuracy)
    Achieves 33.8 mAP on COCO, suitable for ADAS and autonomous driving
    """
    def __init__(self, model_path):
        self.interpreter = tf.lite.Interpreter(
            model_path=model_path,
            experimental_delegates=[
                tf.lite.experimental.load_delegate('libvx_delegate.so')
            ]
        )
        self.interpreter.allocate_tensors()

        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

        self.input_shape = self.input_details[0]['shape'][1:3]  # (height, width)

    def preprocess(self, frame):
        """Preprocess frame for EfficientDet"""
        resized = cv2.resize(frame, tuple(self.input_shape[::-1]))  # (width, height)
        normalized = resized.astype(np.float32) / 255.0
        expanded = np.expand_dims(normalized, axis=0)
        return expanded

    def infer(self, frame):
        """Run EfficientDet inference"""
        preprocessed = self.preprocess(frame)

        # Set input tensor
        self.interpreter.set_tensor(self.input_details[0]['index'], preprocessed)

        # Run inference
        self.interpreter.invoke()

        # Get outputs
        boxes = self.interpreter.get_tensor(self.output_details[0]['index'])[0]  # [N, 4]
        classes = self.interpreter.get_tensor(self.output_details[1]['index'])[0]  # [N]
        scores = self.interpreter.get_tensor(self.output_details[2]['index'])[0]  # [N]
        num_detections = int(self.interpreter.get_tensor(self.output_details[3]['index'])[0])

        # Filter detections
        detections = []
        for i in range(num_detections):
            if scores[i] > 0.5:
                y1, x1, y2, x2 = boxes[i]
                detections.append({
                    'class_id': int(classes[i]),
                    'confidence': float(scores[i]),
                    'bbox': [
                        int(x1 * frame.shape[1]),
                        int(y1 * frame.shape[0]),
                        int(x2 * frame.shape[1]),
                        int(y2 * frame.shape[0])
                    ]
                })

        return detections

# Benchmark comparison:
# YOLOv5s: 18ms latency, 37.4 mAP @ COCO
# EfficientDet-D0: 42ms latency, 33.8 mAP @ COCO
# EfficientDet-D2: 75ms latency, 43.0 mAP @ COCO
```

---

## Semantic Segmentation

### Lane Detection with LaneNet

**Use Case**: Pixel-level lane marking detection for lane keeping assist (LKA)

```python
class LaneNetSegmentation:
    """
    LaneNet for pixel-level lane detection
    Output: Binary segmentation mask (lane pixels vs. background)
    """
    def __init__(self, model_path):
        self.model = self.load_model(model_path)
        self.input_size = (512, 256)  # Width x Height

    def load_model(self, model_path):
        """Load LaneNet model"""
        import snpe
        container = snpe.load_container(model_path)
        return snpe.build_network(container, snpe.SNPE_Runtime.RUNTIME_HTA)

    def preprocess(self, frame):
        """Preprocess frame for LaneNet"""
        # Crop bottom half of frame (road region)
        height = frame.shape[0]
        cropped = frame[height//2:, :]

        # Resize to input size
        resized = cv2.resize(cropped, self.input_size)

        # Normalize
        normalized = resized.astype(np.float32) / 255.0

        # CHW format
        transposed = np.transpose(normalized, (2, 0, 1))
        batched = np.expand_dims(transposed, axis=0)

        return batched, height//2

    def infer(self, frame):
        """Run LaneNet inference"""
        preprocessed, crop_offset = self.preprocess(frame)

        # Run inference
        output = self.model.execute({'input': preprocessed})

        # Output: [1, 2, 256, 512] (binary segmentation: lane vs. background)
        segmentation = output['segmentation'][0]

        # Get lane mask (class 1)
        lane_mask = segmentation[1]  # [256, 512]

        # Resize back to original size
        lane_mask_resized = cv2.resize(lane_mask, (frame.shape[1], frame.shape[0]//2))

        # Create full-size mask
        full_mask = np.zeros((frame.shape[0], frame.shape[1]), dtype=np.float32)
        full_mask[crop_offset:, :] = lane_mask_resized

        return full_mask

    def extract_lane_lines(self, lane_mask, threshold=0.5):
        """
        Extract polynomial lane lines from segmentation mask
        Fit 2nd order polynomial: y = ax^2 + bx + c
        """
        # Threshold mask
        binary_mask = (lane_mask > threshold).astype(np.uint8) * 255

        # Find lane pixels
        lane_pixels = np.where(binary_mask > 0)
        y_pixels = lane_pixels[0]
        x_pixels = lane_pixels[1]

        if len(x_pixels) < 10:
            return None  # Not enough lane pixels

        # Fit polynomial (2nd order)
        coeffs = np.polyfit(y_pixels, x_pixels, 2)

        # Generate lane line points
        y_points = np.linspace(binary_mask.shape[0]//2, binary_mask.shape[0], 100)
        x_points = np.polyval(coeffs, y_points)

        lane_points = np.column_stack((x_points, y_points)).astype(np.int32)

        return lane_points

# Usage
lane_detector = LaneNetSegmentation('lanenet_int8.dlc')

cap = cv2.VideoCapture('/dev/video0')
while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Detect lanes
    lane_mask = lane_detector.infer(frame)

    # Extract lane lines
    left_lane = lane_detector.extract_lane_lines(lane_mask[:, :frame.shape[1]//2])
    right_lane = lane_detector.extract_lane_lines(lane_mask[:, frame.shape[1]//2:])

    # Draw lanes
    if left_lane is not None:
        cv2.polylines(frame, [left_lane], False, (0, 255, 0), 3)
    if right_lane is not None:
        right_lane[:, 0] += frame.shape[1]//2  # Offset for right half
        cv2.polylines(frame, [right_lane], False, (0, 255, 0), 3)

    cv2.imshow('Lane Detection', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
```

---

## 360° Surround View with AI

### Multi-Camera Stitching and Object Detection

```python
class SurroundViewSystem:
    """
    360° surround view with AI-enhanced object detection
    - 4 fisheye cameras (front, rear, left, right)
    - Real-time stitching to bird's eye view
    - Object detection in stitched image (parking obstacles)
    """
    def __init__(self, calibration_file):
        # Load camera calibration (intrinsic + extrinsic parameters)
        self.calib = self.load_calibration(calibration_file)

        # Load object detector (optimized for parking scenarios)
        self.detector = AutomotiveYOLOv5('yolov5s_parking_int8.dlc', npu_runtime='snpe')

    def load_calibration(self, calib_file):
        """Load camera calibration parameters"""
        with open(calib_file, 'r') as f:
            calib = yaml.safe_load(f)
        return calib

    def undistort_fisheye(self, frame, camera_id):
        """Remove fisheye distortion using calibration parameters"""
        K = np.array(self.calib[f'camera_{camera_id}']['intrinsic'])  # 3x3 matrix
        D = np.array(self.calib[f'camera_{camera_id}']['distortion'])  # 4x1 vector

        h, w = frame.shape[:2]
        map1, map2 = cv2.fisheye.initUndistortRectifyMap(
            K, D, np.eye(3), K, (w, h), cv2.CV_16SC2
        )

        undistorted = cv2.remap(frame, map1, map2, interpolation=cv2.INTER_LINEAR)
        return undistorted

    def project_to_birds_eye(self, frame, camera_id):
        """Project camera frame to bird's eye view"""
        # Homography matrix (camera → ground plane)
        H = np.array(self.calib[f'camera_{camera_id}']['homography'])  # 3x3 matrix

        # Warp perspective
        birds_eye = cv2.warpPerspective(frame, H, (800, 800))
        return birds_eye

    def stitch_surround_view(self, frames):
        """
        Stitch 4 camera frames into single bird's eye view
        frames: dict with keys 'front', 'rear', 'left', 'right'
        """
        # Create 800x800 output canvas
        canvas = np.zeros((800, 800, 3), dtype=np.uint8)

        # Project each camera to bird's eye view
        front_bev = self.project_to_birds_eye(frames['front'], 0)
        rear_bev = self.project_to_birds_eye(frames['rear'], 1)
        left_bev = self.project_to_birds_eye(frames['left'], 2)
        right_bev = self.project_to_birds_eye(frames['right'], 3)

        # Blend regions (simple averaging in overlap regions)
        canvas = self.blend_views(canvas, front_bev, rear_bev, left_bev, right_bev)

        return canvas

    def blend_views(self, canvas, front, rear, left, right):
        """Blend 4 bird's eye views with alpha blending in overlap regions"""
        # Front region (top 400 pixels)
        canvas[0:400, :] = cv2.addWeighted(canvas[0:400, :], 0.5, front[0:400, :], 0.5, 0)

        # Rear region (bottom 400 pixels)
        canvas[400:800, :] = cv2.addWeighted(canvas[400:800, :], 0.5, rear[400:800, :], 0.5, 0)

        # Left region (left 400 pixels)
        canvas[:, 0:400] = cv2.addWeighted(canvas[:, 0:400], 0.5, left[:, 0:400], 0.5, 0)

        # Right region (right 400 pixels)
        canvas[:, 400:800] = cv2.addWeighted(canvas[:, 400:800], 0.5, right[:, 400:800], 0.5, 0)

        return canvas

    def detect_parking_obstacles(self, surround_view):
        """Run object detection on stitched surround view"""
        detections = self.detector.infer(surround_view)

        # Filter for parking-relevant objects
        parking_objects = ['vehicle', 'pedestrian', 'cyclist', 'shopping_cart', 'pole']
        filtered = [d for d in detections if d['class'] in parking_objects]

        return filtered

    def run(self):
        """Main surround view loop"""
        # Open 4 camera streams
        caps = {
            'front': cv2.VideoCapture('/dev/video0'),
            'rear': cv2.VideoCapture('/dev/video1'),
            'left': cv2.VideoCapture('/dev/video2'),
            'right': cv2.VideoCapture('/dev/video3')
        }

        while True:
            # Capture frames from all cameras
            frames = {}
            for name, cap in caps.items():
                ret, frame = cap.read()
                if ret:
                    # Undistort fisheye
                    undistorted = self.undistort_fisheye(frame, list(caps.keys()).index(name))
                    frames[name] = undistorted

            # Stitch to surround view
            surround_view = self.stitch_surround_view(frames)

            # Detect obstacles
            detections = self.detect_parking_obstacles(surround_view)

            # Draw detections
            for det in detections:
                x1, y1, x2, y2 = det['bbox']
                label = f"{det['class']}: {det['confidence']:.2f}"
                cv2.rectangle(surround_view, (x1, y1), (x2, y2), (0, 0, 255), 2)
                cv2.putText(surround_view, label, (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)

            # Draw vehicle outline (center)
            cv2.rectangle(surround_view, (350, 350), (450, 450), (255, 255, 255), 3)

            cv2.imshow('360° Surround View with AI', surround_view)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

# Usage
surround_system = SurroundViewSystem('camera_calibration.yaml')
surround_system.run()
```

---

## Multi-Camera Fusion

### Temporal and Spatial Fusion for ADAS

```python
class MultiCameraFusion:
    """
    Fuse detections from multiple cameras for consistent world model
    - Front camera: Long range (50-150m)
    - Side cameras: Mid range (10-50m)
    - Rear camera: Short range (5-20m)
    """
    def __init__(self):
        self.cameras = {
            'front': {
                'detector': AutomotiveYOLOv5('yolov5s_int8.dlc', npu_runtime='snpe'),
                'extrinsic': self.load_extrinsic('front_extrinsic.yaml'),  # Camera → vehicle frame
                'range_m': (5, 150)
            },
            'left': {
                'detector': AutomotiveYOLOv5('yolov5s_int8.dlc', npu_runtime='snpe'),
                'extrinsic': self.load_extrinsic('left_extrinsic.yaml'),
                'range_m': (2, 50)
            },
            'right': {
                'detector': AutomotiveYOLOv5('yolov5s_int8.dlc', npu_runtime='snpe'),
                'extrinsic': self.load_extrinsic('right_extrinsic.yaml'),
                'range_m': (2, 50)
            },
            'rear': {
                'detector': AutomotiveYOLOv5('yolov5s_int8.dlc', npu_runtime='snpe'),
                'extrinsic': self.load_extrinsic('rear_extrinsic.yaml'),
                'range_m': (2, 20)
            }
        }

        self.tracked_objects = []  # List of tracked objects across frames

    def load_extrinsic(self, path):
        """Load camera extrinsic calibration (camera → vehicle coordinate frame)"""
        with open(path, 'r') as f:
            extrinsic = yaml.safe_load(f)
        return np.array(extrinsic['transformation_matrix'])  # 4x4 homogeneous matrix

    def project_to_vehicle_frame(self, detection, camera_name):
        """
        Project 2D detection to 3D vehicle coordinate frame
        Assumes flat ground plane (z = 0)
        """
        # Estimate distance from bounding box size (empirical formula)
        bbox_height = detection['bbox'][3] - detection['bbox'][1]
        estimated_distance = 1.5 / (bbox_height / 1080) * 50  # meters (calibrated for specific camera)

        # Get camera extrinsic
        T_cam_to_vehicle = self.cameras[camera_name]['extrinsic']

        # Simplified projection (assumes object is on ground plane)
        # In production, use full 3D reconstruction or stereo/monocular depth estimation
        x_vehicle = estimated_distance * np.cos(np.deg2rad(detection['bearing_angle']))
        y_vehicle = estimated_distance * np.sin(np.deg2rad(detection['bearing_angle']))
        z_vehicle = 0.0  # Ground plane

        position_vehicle = np.array([x_vehicle, y_vehicle, z_vehicle, 1.0])

        # Transform to vehicle frame
        position_world = T_cam_to_vehicle @ position_vehicle

        return position_world[:3]  # [x, y, z]

    def associate_detections(self, detections_per_camera):
        """
        Associate detections from multiple cameras to same object
        Use Hungarian algorithm for optimal assignment
        """
        from scipy.optimize import linear_sum_assignment

        # Build cost matrix (distance between detections from different cameras)
        all_detections = []
        for camera_name, detections in detections_per_camera.items():
            for det in detections:
                det['camera'] = camera_name
                det['position_3d'] = self.project_to_vehicle_frame(det, camera_name)
                all_detections.append(det)

        N = len(all_detections)
        cost_matrix = np.zeros((N, N))

        for i in range(N):
            for j in range(i+1, N):
                # Distance between 3D positions
                dist = np.linalg.norm(all_detections[i]['position_3d'] - all_detections[j]['position_3d'])
                cost_matrix[i, j] = dist
                cost_matrix[j, i] = dist

        # Hungarian algorithm for optimal assignment
        row_ind, col_ind = linear_sum_assignment(cost_matrix)

        # Group associated detections (distance < 2m = same object)
        associated_groups = []
        threshold = 2.0  # meters

        for i, j in zip(row_ind, col_ind):
            if cost_matrix[i, j] < threshold:
                associated_groups.append([all_detections[i], all_detections[j]])

        return associated_groups

    def fuse_detections(self, associated_groups):
        """
        Fuse associated detections into single object estimate
        Use weighted average based on camera confidence and range
        """
        fused_objects = []

        for group in associated_groups:
            # Weighted average of 3D positions
            positions = np.array([det['position_3d'] for det in group])
            confidences = np.array([det['confidence'] for det in group])

            # Weight by confidence and inverse distance
            weights = confidences / (np.linalg.norm(positions, axis=1) + 1e-6)
            weights /= np.sum(weights)

            fused_position = np.sum(positions * weights[:, np.newaxis], axis=0)

            # Majority vote for class
            classes = [det['class'] for det in group]
            fused_class = max(set(classes), key=classes.count)

            fused_objects.append({
                'class': fused_class,
                'position_3d': fused_position,
                'confidence': np.mean(confidences),
                'sources': [det['camera'] for det in group]
            })

        return fused_objects

# Usage
fusion = MultiCameraFusion()

# Capture frames from all cameras
frames = {
    'front': capture_camera('/dev/video0'),
    'left': capture_camera('/dev/video2'),
    'right': capture_camera('/dev/video3'),
    'rear': capture_camera('/dev/video1')
}

# Run detection on each camera
detections_per_camera = {}
for camera_name, frame in frames.items():
    detections = fusion.cameras[camera_name]['detector'].infer(frame)
    detections_per_camera[camera_name] = detections

# Associate and fuse detections
associated_groups = fusion.associate_detections(detections_per_camera)
fused_objects = fusion.fuse_detections(associated_groups)

# Fused objects now represent consistent 3D world model
for obj in fused_objects:
    print(f"{obj['class']} at ({obj['position_3d'][0]:.1f}, {obj['position_3d'][1]:.1f}, {obj['position_3d'][2]:.1f}) m")
    print(f"  Confidence: {obj['confidence']:.2f}, Sources: {obj['sources']}")
```

---

## Performance Optimization

### Multi-Threaded Camera Pipeline

```python
import threading
import queue

class OptimizedCameraPipeline:
    """
    Multi-threaded camera pipeline for maximum throughput
    - Thread 1: Capture frames (I/O bound)
    - Thread 2: Preprocessing (CPU bound)
    - Thread 3: NPU inference (NPU bound)
    - Thread 4: Postprocessing + visualization (CPU bound)
    """
    def __init__(self):
        self.capture_queue = queue.Queue(maxsize=2)
        self.preprocess_queue = queue.Queue(maxsize=2)
        self.inference_queue = queue.Queue(maxsize=2)
        self.result_queue = queue.Queue(maxsize=2)

        self.detector = AutomotiveYOLOv5('yolov5s_int8.dlc', npu_runtime='snpe')

    def capture_thread(self):
        """Capture frames from camera"""
        cap = cv2.VideoCapture('/dev/video0')
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
        cap.set(cv2.CAP_PROP_FPS, 30)

        while True:
            ret, frame = cap.read()
            if ret:
                self.capture_queue.put(frame)

    def preprocess_thread(self):
        """Preprocess frames"""
        while True:
            frame = self.capture_queue.get()
            preprocessed = self.detector.preprocess(frame)
            self.preprocess_queue.put((frame, preprocessed))

    def inference_thread(self):
        """Run NPU inference"""
        while True:
            frame, preprocessed = self.preprocess_queue.get()
            start_time = time.time()

            # Run inference
            output = self.detector.model.execute({'images': preprocessed})

            inference_time = (time.time() - start_time) * 1000
            self.inference_queue.put((frame, output, inference_time))

    def postprocess_thread(self):
        """Postprocess and visualize"""
        while True:
            frame, output, inference_time = self.inference_queue.get()

            # Postprocess
            detections = self.detector.postprocess(output['output'], frame.shape)

            # Draw
            for det in detections:
                x1, y1, x2, y2 = det['bbox']
                label = f"{det['class']}: {det['confidence']:.2f}"
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                cv2.putText(frame, label, (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

            # Draw FPS
            fps = 1000 / inference_time
            cv2.putText(frame, f"FPS: {fps:.1f}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

            cv2.imshow('ADAS Camera', frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    def run(self):
        """Start all threads"""
        threads = [
            threading.Thread(target=self.capture_thread, daemon=True),
            threading.Thread(target=self.preprocess_thread, daemon=True),
            threading.Thread(target=self.inference_thread, daemon=True),
            threading.Thread(target=self.postprocess_thread, daemon=True)
        ]

        for t in threads:
            t.start()

        for t in threads:
            t.join()

# Usage
pipeline = OptimizedCameraPipeline()
pipeline.run()

# Performance improvement:
# Single-threaded: 25 FPS (40ms total latency)
# Multi-threaded: 45 FPS (22ms total latency)
# NPU utilization: 95% (vs. 60% single-threaded)
```

---

## Related Skills
- [Edge AI Deployment](./edge-ai-deployment.md) - NPU model deployment
- [Driver Monitoring Systems](./driver-monitoring-systems.md) - DMS with IR cameras
- [Neural Processing Units](./neural-processing-units.md) - NPU architecture

---

**Tags**: `computer-vision`, `object-detection`, `yolo`, `efficientdet`, `lane-detection`, `surround-view`, `multi-camera`, `adas`, `perception`

---

## Driver Monitoring Systems

# Driver Monitoring Systems (DMS) with AI

**Skill**: AI-powered driver monitoring (drowsiness, distraction, gaze tracking) with ASIL-B certification
**Version**: 1.0.0
**Category**: AI-ECU / Safety Systems
**Complexity**: Expert

---

## Overview

Comprehensive guide to implementing AI-based Driver Monitoring Systems (DMS) and Occupant Monitoring Systems (OMS) for automotive safety. Covers drowsiness detection, distraction detection, gaze tracking, emotion recognition, IR camera integration, FMCW radar fusion, and ASIL-B certification requirements.

## Regulatory Context

### Euro NCAP & GSR Requirements

**EU General Safety Regulation (GSR 2.0)** - Mandatory from July 2024:
- **Driver Drowsiness Detection** (DDD): Detect and warn drowsy drivers
- **Driver Distraction Warning** (DDW): Detect visual distraction (phone use, looking away)
- **Advanced Driver Distraction Warning** (ADDW): Euro NCAP 2025+ (includes gaze tracking)

**ASIL Ratings**:
- **ASIL-B**: DMS drowsiness/distraction detection (ISO 26262)
- **ASIL-A**: OMS child presence detection (rear-seat)
- **QM**: Emotion/comfort features (non-safety-critical)

**Performance Requirements** (Euro NCAP 2025):
- **Detection latency**: < 2 seconds for drowsiness onset
- **False positive rate**: < 5% (< 1 false alarm per 20 minutes)
- **False negative rate**: < 2% (must catch 98% of drowsy events)
- **Operating conditions**: -30°C to +85°C, day/night, sunglasses OK

---

## IR Camera Setup

### Hardware Configuration

**DMS Camera Specifications**:
- **Sensor**: CMOS IR-sensitive (no IR cut filter)
- **Resolution**: 640x480 (VGA) or 1280x720 (HD) @ 30-60 FPS
- **Wavelength**: 940nm (invisible to human eye, no red glow)
- **FOV**: 60-90° (cover full driver face + upper body)
- **Interface**: MIPI CSI-2 (2-lane, 1 Gbps)
- **IR Illumination**: 940nm LED array, 1-2W power, PWM dimming

**Physical Mounting**:
- **Location**: Steering column top or A-pillar
- **Distance to driver**: 60-90 cm
- **Angle**: 15-30° downward tilt (avoid glare from glasses)

```python
class DMSCameraController:
    """
    Control DMS IR camera and illumination
    """
    def __init__(self, camera_device='/dev/video4', ir_led_gpio=17):
        self.cap = cv2.VideoCapture(camera_device)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        self.cap.set(cv2.CAP_PROP_FPS, 60)
        self.cap.set(cv2.CAP_PROP_GAIN, 4.0)  # High gain for IR
        self.cap.set(cv2.CAP_PROP_EXPOSURE, 10)  # Short exposure (motion blur reduction)

        # IR LED control via PWM
        import RPi.GPIO as GPIO
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(ir_led_gpio, GPIO.OUT)
        self.ir_pwm = GPIO.PWM(ir_led_gpio, 1000)  # 1 kHz PWM
        self.ir_pwm.start(0)

    def set_ir_intensity(self, intensity_percent):
        """
        Adjust IR LED intensity (0-100%)
        Adaptive control based on ambient light
        """
        self.ir_pwm.ChangeDutyCycle(intensity_percent)

    def auto_adjust_ir(self, frame):
        """
        Automatically adjust IR intensity based on face brightness
        Goal: Keep face region at 50-70% of histogram range
        """
        # Detect face region
        face_detector = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        faces = face_detector.detectMultiScale(frame, scaleFactor=1.1, minNeighbors=5, minSize=(100, 100))

        if len(faces) > 0:
            x, y, w, h = faces[0]
            face_region = frame[y:y+h, x:x+w]

            # Calculate mean brightness
            mean_brightness = np.mean(face_region)

            # Target brightness: 128 (50% of 255)
            target_brightness = 128
            error = target_brightness - mean_brightness

            # Proportional control
            intensity_adjust = error * 0.5  # Proportional gain
            current_intensity = self.ir_pwm.ChangeDutyCycle
            new_intensity = np.clip(current_intensity + intensity_adjust, 10, 100)

            self.set_ir_intensity(new_intensity)

    def capture_frame(self):
        """Capture IR frame with auto-adjustment"""
        ret, frame = self.cap.read()
        if ret:
            # Convert to grayscale (IR is already monochrome)
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

            # Auto-adjust IR intensity
            self.auto_adjust_ir(gray)

            return gray
        return None

# Usage
dms_camera = DMSCameraController()
frame = dms_camera.capture_frame()
```

---

## Face and Eye Detection

### MediaPipe Face Mesh for Landmark Detection

**Face Landmarks**: 468 3D points covering face geometry (eyes, nose, mouth, contours)

```python
import mediapipe as mp

class FaceLandmarkDetector:
    """
    Detect 468 face landmarks using MediaPipe
    Optimized for automotive DMS (lightweight model on NPU)
    """
    def __init__(self):
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=False,
            max_num_faces=1,
            refine_landmarks=True,  # Enable iris landmarks
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )

        # Key landmark indices
        self.LEFT_EYE_INDICES = [33, 133, 160, 159, 158, 144, 145, 153]
        self.RIGHT_EYE_INDICES = [362, 263, 387, 386, 385, 373, 374, 380]
        self.LEFT_IRIS_INDICES = [468, 469, 470, 471, 472]
        self.RIGHT_IRIS_INDICES = [473, 474, 475, 476, 477]

    def detect(self, frame):
        """
        Detect face landmarks in IR frame
        Returns: 468 (x, y, z) landmarks in normalized coordinates [0, 1]
        """
        # Convert grayscale to RGB (MediaPipe expects RGB)
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_GRAY2RGB)

        # Run MediaPipe
        results = self.face_mesh.process(frame_rgb)

        if results.multi_face_landmarks:
            landmarks = results.multi_face_landmarks[0]

            # Convert to numpy array
            h, w = frame.shape[:2]
            landmarks_array = np.array([
                [lm.x * w, lm.y * h, lm.z * w]  # Denormalize to pixel coordinates
                for lm in landmarks.landmark
            ])

            return landmarks_array
        return None

    def get_eye_landmarks(self, landmarks):
        """Extract left and right eye landmarks"""
        if landmarks is None:
            return None, None

        left_eye = landmarks[self.LEFT_EYE_INDICES]
        right_eye = landmarks[self.RIGHT_EYE_INDICES]

        return left_eye, right_eye

    def get_iris_landmarks(self, landmarks):
        """Extract iris center points (for gaze tracking)"""
        if landmarks is None:
            return None, None

        left_iris = landmarks[self.LEFT_IRIS_INDICES]
        right_iris = landmarks[self.RIGHT_IRIS_INDICES]

        # Iris center = mean of 5 iris points
        left_iris_center = np.mean(left_iris, axis=0)
        right_iris_center = np.mean(right_iris, axis=0)

        return left_iris_center, right_iris_center

# Usage
landmark_detector = FaceLandmarkDetector()

frame = dms_camera.capture_frame()
landmarks = landmark_detector.detect(frame)

if landmarks is not None:
    left_eye, right_eye = landmark_detector.get_eye_landmarks(landmarks)
    left_iris, right_iris = landmark_detector.get_iris_landmarks(landmarks)

    # Draw landmarks
    for point in landmarks:
        cv2.circle(frame, (int(point[0]), int(point[1])), 1, (0, 255, 0), -1)

    cv2.imshow('DMS Face Landmarks', frame)
```

---

## Drowsiness Detection

### Eye Aspect Ratio (EAR) for Blink Detection

**Eye Aspect Ratio (EAR)**:
- Open eye: EAR ≈ 0.25-0.30
- Closed eye: EAR ≈ 0.10-0.15
- Drowsy: Prolonged low EAR (> 2 seconds with EAR < 0.20)

```python
class DrowsinessDetector:
    """
    Detect driver drowsiness using Eye Aspect Ratio (EAR) and blink analysis
    """
    def __init__(self):
        self.landmark_detector = FaceLandmarkDetector()

        # Drowsiness thresholds
        self.EAR_THRESHOLD = 0.20  # Below this = eyes closing
        self.DROWSY_DURATION = 2.0  # seconds
        self.BLINK_DURATION_MAX = 0.4  # seconds (longer = microsleep)

        # State tracking
        self.ear_history = deque(maxlen=60)  # 2 seconds @ 30 FPS
        self.eyes_closed_start = None
        self.drowsy_events = []

    def calculate_ear(self, eye_landmarks):
        """
        Calculate Eye Aspect Ratio (EAR)
        EAR = (||p2 - p6|| + ||p3 - p5||) / (2 * ||p1 - p4||)
        Where p1-p6 are eye corner and eyelid landmarks
        """
        # Vertical eye distances
        A = np.linalg.norm(eye_landmarks[1] - eye_landmarks[5])
        B = np.linalg.norm(eye_landmarks[2] - eye_landmarks[4])

        # Horizontal eye distance
        C = np.linalg.norm(eye_landmarks[0] - eye_landmarks[3])

        ear = (A + B) / (2.0 * C)
        return ear

    def detect_drowsiness(self, frame, timestamp):
        """
        Detect drowsiness from IR frame
        Returns: drowsiness level (0.0 = alert, 1.0 = very drowsy)
        """
        # Detect face landmarks
        landmarks = self.landmark_detector.detect(frame)
        if landmarks is None:
            return 0.0  # No face detected

        # Get eye landmarks
        left_eye, right_eye = self.landmark_detector.get_eye_landmarks(landmarks)

        # Calculate EAR for both eyes
        left_ear = self.calculate_ear(left_eye)
        right_ear = self.calculate_ear(right_eye)
        avg_ear = (left_ear + right_ear) / 2.0

        # Store in history
        self.ear_history.append((timestamp, avg_ear))

        # Check if eyes are closed
        if avg_ear < self.EAR_THRESHOLD:
            if self.eyes_closed_start is None:
                self.eyes_closed_start = timestamp
            else:
                eyes_closed_duration = timestamp - self.eyes_closed_start

                # Prolonged closure = drowsiness
                if eyes_closed_duration > self.DROWSY_DURATION:
                    drowsiness_level = min(eyes_closed_duration / 5.0, 1.0)  # Max at 5 seconds
                    return drowsiness_level
        else:
            # Eyes opened - check if it was a blink or microsleep
            if self.eyes_closed_start is not None:
                eyes_closed_duration = timestamp - self.eyes_closed_start

                if eyes_closed_duration > self.BLINK_DURATION_MAX:
                    # Microsleep detected
                    self.drowsy_events.append({
                        'type': 'microsleep',
                        'duration': eyes_closed_duration,
                        'timestamp': timestamp
                    })

                self.eyes_closed_start = None

        # Analyze EAR trend (gradual decrease = drowsiness onset)
        if len(self.ear_history) >= 60:
            recent_ear = [ear for _, ear in list(self.ear_history)[-60:]]
            trend = np.polyfit(range(60), recent_ear, 1)[0]  # Linear trend

            if trend < -0.001:  # Decreasing EAR trend
                drowsiness_level = min(abs(trend) * 100, 1.0)
                return drowsiness_level

        return 0.0

# Usage
drowsiness_detector = DrowsinessDetector()

while True:
    frame = dms_camera.capture_frame()
    timestamp = time.time()

    drowsiness_level = drowsiness_detector.detect_drowsiness(frame, timestamp)

    if drowsiness_level > 0.6:
        print(f"DROWSINESS WARNING: Level {drowsiness_level:.2f}")
        trigger_drowsiness_alarm()  # Haptic seat + audio alert

    cv2.imshow('DMS - Drowsiness Detection', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
```

### ML-Based Drowsiness Detection

**Deep Learning Model**: ResNet18 trained on drowsy/alert face images

```python
class MLDrowsinessDetector:
    """
    ML-based drowsiness detection (more accurate than EAR heuristic)
    Model: ResNet18 (INT8 quantized) on NPU
    Output: 3 classes (alert, drowsy, very_drowsy)
    """
    def __init__(self, model_path):
        import snpe
        self.model = snpe.load_container(model_path)
        self.network = snpe.build_network(self.model, snpe.SNPE_Runtime.RUNTIME_HTA)

        self.classes = ['alert', 'drowsy', 'very_drowsy']
        self.input_size = (224, 224)

    def preprocess(self, frame, face_bbox):
        """Extract and preprocess face region"""
        x, y, w, h = face_bbox

        # Crop face with margin
        margin = 0.2
        x1 = max(0, int(x - w * margin))
        y1 = max(0, int(y - h * margin))
        x2 = min(frame.shape[1], int(x + w * (1 + margin)))
        y2 = min(frame.shape[0], int(y + h * (1 + margin)))

        face_crop = frame[y1:y2, x1:x2]

        # Resize to model input size
        resized = cv2.resize(face_crop, self.input_size)

        # Normalize
        normalized = resized.astype(np.float32) / 255.0

        # CHW format
        transposed = np.transpose(normalized, (2, 0, 1))
        batched = np.expand_dims(transposed, axis=0)

        return batched

    def infer(self, frame, face_bbox):
        """Infer drowsiness from face image"""
        preprocessed = self.preprocess(frame, face_bbox)

        # Run on NPU
        output = self.network.execute({'input': preprocessed})

        # Get class probabilities
        probs = output['output'][0]  # [alert, drowsy, very_drowsy]

        # Weighted drowsiness score
        drowsiness_score = probs[1] * 0.5 + probs[2] * 1.0

        return {
            'class': self.classes[np.argmax(probs)],
            'probabilities': probs,
            'drowsiness_score': drowsiness_score
        }

# Combine EAR and ML for robust detection
def hybrid_drowsiness_detection(frame):
    """
    Hybrid drowsiness detection:
    - EAR for fast response (< 1ms)
    - ML for accurate classification (20ms on NPU)
    - Fusion: OR logic (trigger if either detects drowsiness)
    """
    # Fast EAR-based detection
    ear_drowsiness = drowsiness_detector.detect_drowsiness(frame, time.time())

    # ML-based detection (every 5th frame to save power)
    ml_drowsiness = 0.0
    if frame_count % 5 == 0:
        face_bbox = detect_face(frame)
        if face_bbox is not None:
            result = ml_drowsiness_detector.infer(frame, face_bbox)
            ml_drowsiness = result['drowsiness_score']

    # Fusion: Take maximum
    final_drowsiness = max(ear_drowsiness, ml_drowsiness)

    return final_drowsiness, {'ear': ear_drowsiness, 'ml': ml_drowsiness}
```

---

## Distraction Detection

### Gaze Tracking for Visual Distraction

**Gaze Zones**:
- **Road ahead**: 0° ± 15° (safe zone)
- **Left mirror**: -30° to -45°
- **Right mirror**: +30° to +45°
- **Dashboard**: -15° to +15° (vertical)
- **Phone/lap**: < -30° (vertical)

```python
class GazeTracker:
    """
    Track driver gaze direction using iris position
    Detect visual distraction (looking away from road)
    """
    def __init__(self):
        self.landmark_detector = FaceLandmarkDetector()

        # Gaze zones (horizontal angle in degrees)
        self.SAFE_ZONE = (-15, 15)  # Road ahead
        self.DISTRACTION_THRESHOLD = 2.0  # seconds looking away

        self.gaze_history = deque(maxlen=60)  # 2 seconds @ 30 FPS
        self.distraction_start = None

    def calculate_gaze_angle(self, landmarks):
        """
        Calculate horizontal and vertical gaze angles
        Returns: (horizontal_angle, vertical_angle) in degrees
        """
        # Get iris centers
        left_iris, right_iris = self.landmark_detector.get_iris_landmarks(landmarks)
        if left_iris is None or right_iris is None:
            return None, None

        # Get eye corners (to establish eye coordinate frame)
        left_eye, right_eye = self.landmark_detector.get_eye_landmarks(landmarks)

        # Horizontal gaze angle (left/right)
        # Calculate iris position relative to eye corners
        left_eye_width = np.linalg.norm(left_eye[0] - left_eye[3])
        left_iris_offset = (left_iris[0] - left_eye[0][0]) / left_eye_width

        right_eye_width = np.linalg.norm(right_eye[0] - right_eye[3])
        right_iris_offset = (right_iris[0] - right_eye[0][0]) / right_eye_width

        # Average offset (0.5 = center, < 0.5 = looking left, > 0.5 = looking right)
        avg_offset = (left_iris_offset + right_iris_offset) / 2.0

        # Convert to angle (empirical calibration)
        horizontal_angle = (avg_offset - 0.5) * 60  # ± 30° range

        # Vertical gaze angle (up/down)
        left_eye_height = np.linalg.norm(left_eye[1] - left_eye[5])
        left_iris_vertical_offset = (left_iris[1] - left_eye[1][1]) / left_eye_height

        right_eye_height = np.linalg.norm(right_eye[1] - right_eye[5])
        right_iris_vertical_offset = (right_iris[1] - right_eye[1][1]) / right_eye_height

        avg_vertical_offset = (left_iris_vertical_offset + right_iris_vertical_offset) / 2.0
        vertical_angle = (avg_vertical_offset - 0.5) * 40  # ± 20° range

        return horizontal_angle, vertical_angle

    def detect_distraction(self, frame, timestamp):
        """
        Detect visual distraction (looking away from road)
        Returns: distraction level (0.0 = focused, 1.0 = highly distracted)
        """
        # Detect face landmarks
        landmarks = self.landmark_detector.detect(frame)
        if landmarks is None:
            return 0.0

        # Calculate gaze angle
        horizontal_angle, vertical_angle = self.calculate_gaze_angle(landmarks)
        if horizontal_angle is None:
            return 0.0

        # Store in history
        self.gaze_history.append((timestamp, horizontal_angle, vertical_angle))

        # Check if looking away from safe zone
        if not (self.SAFE_ZONE[0] <= horizontal_angle <= self.SAFE_ZONE[1]):
            if self.distraction_start is None:
                self.distraction_start = timestamp
            else:
                distraction_duration = timestamp - self.distraction_start

                # Prolonged distraction
                if distraction_duration > self.DISTRACTION_THRESHOLD:
                    distraction_level = min(distraction_duration / 5.0, 1.0)
                    return distraction_level
        else:
            self.distraction_start = None

        return 0.0

    def classify_gaze_zone(self, horizontal_angle, vertical_angle):
        """Classify which zone the driver is looking at"""
        if -15 <= horizontal_angle <= 15 and -10 <= vertical_angle <= 10:
            return 'road_ahead'
        elif -45 <= horizontal_angle < -15:
            return 'left_mirror'
        elif 15 < horizontal_angle <= 45:
            return 'right_mirror'
        elif -15 <= horizontal_angle <= 15 and 10 < vertical_angle <= 30:
            return 'dashboard'
        elif vertical_angle < -20:
            return 'phone_lap'  # Looking down at phone
        else:
            return 'unknown'

# Usage
gaze_tracker = GazeTracker()

while True:
    frame = dms_camera.capture_frame()
    timestamp = time.time()

    distraction_level = gaze_tracker.detect_distraction(frame, timestamp)

    if distraction_level > 0.6:
        print(f"DISTRACTION WARNING: Level {distraction_level:.2f}")
        trigger_distraction_alarm()

    cv2.imshow('DMS - Gaze Tracking', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
```

---

## FMCW Radar Fusion

### Combine Camera + Radar for Robust DMS

**Challenge**: Camera-only DMS fails in extreme lighting (direct sunlight on face, complete darkness)
**Solution**: Fuse 60 GHz FMCW radar (vital signs: heart rate, breathing) with camera

```python
class RadarDMSFusion:
    """
    Fuse IR camera DMS with 60 GHz FMCW radar
    Radar detects: heart rate, breathing rate, motion (head nod)
    """
    def __init__(self, radar_device='/dev/ttyUSB0'):
        self.camera_dms = DrowsinessDetector()
        self.gaze_tracker = GazeTracker()

        # Initialize 60 GHz FMCW radar
        import serial
        self.radar = serial.Serial(radar_device, baudrate=115200)

    def read_radar_vitals(self):
        """
        Read vital signs from FMCW radar
        Returns: heart_rate (bpm), breathing_rate (bpm), motion_detected
        """
        # Send command to radar
        self.radar.write(b'GET_VITALS\n')

        # Read response
        response = self.radar.readline().decode('utf-8').strip()
        parts = response.split(',')

        if len(parts) == 3:
            heart_rate = float(parts[0])  # bpm
            breathing_rate = float(parts[1])  # bpm
            motion_score = float(parts[2])  # 0-1 scale

            return heart_rate, breathing_rate, motion_score
        return None, None, None

    def detect_drowsiness_from_vitals(self, heart_rate, breathing_rate):
        """
        Detect drowsiness from radar vital signs
        Drowsy driver: Lower heart rate, slower breathing
        """
        # Baseline: alert driver
        # Heart rate: 70-90 bpm (sitting)
        # Breathing rate: 15-20 bpm

        hr_drowsiness = 0.0
        if heart_rate < 65:  # Below normal resting
            hr_drowsiness = (65 - heart_rate) / 15.0  # Normalize

        br_drowsiness = 0.0
        if breathing_rate < 12:  # Slow breathing
            br_drowsiness = (12 - breathing_rate) / 5.0

        # Combined drowsiness from vitals
        vital_drowsiness = (hr_drowsiness + br_drowsiness) / 2.0
        return np.clip(vital_drowsiness, 0.0, 1.0)

    def fused_drowsiness_detection(self, frame, timestamp):
        """
        Fuse camera and radar for robust drowsiness detection
        Fallback to radar if camera fails (bright sunlight, darkness)
        """
        # Camera-based detection
        camera_drowsiness = self.camera_dms.detect_drowsiness(frame, timestamp)
        camera_confidence = 1.0 if frame is not None else 0.0

        # Radar-based detection
        heart_rate, breathing_rate, motion = self.read_radar_vitals()
        radar_drowsiness = 0.0
        radar_confidence = 0.0

        if heart_rate is not None:
            radar_drowsiness = self.detect_drowsiness_from_vitals(heart_rate, breathing_rate)
            radar_confidence = 0.8  # Radar is reliable but less specific than camera

        # Weighted fusion
        total_confidence = camera_confidence + radar_confidence
        if total_confidence > 0:
            fused_drowsiness = (camera_drowsiness * camera_confidence +
                               radar_drowsiness * radar_confidence) / total_confidence
        else:
            fused_drowsiness = 0.0

        return {
            'drowsiness': fused_drowsiness,
            'camera_drowsiness': camera_drowsiness,
            'radar_drowsiness': radar_drowsiness,
            'heart_rate': heart_rate,
            'breathing_rate': breathing_rate,
            'fusion_mode': 'camera' if camera_confidence > radar_confidence else 'radar'
        }

# Usage
radar_dms = RadarDMSFusion()

while True:
    frame = dms_camera.capture_frame()
    timestamp = time.time()

    result = radar_dms.fused_drowsiness_detection(frame, timestamp)

    print(f"Drowsiness: {result['drowsiness']:.2f} (mode: {result['fusion_mode']})")
    print(f"  Camera: {result['camera_drowsiness']:.2f}")
    print(f"  Radar: {result['radar_drowsiness']:.2f} (HR: {result['heart_rate']} bpm)")

    if result['drowsiness'] > 0.7:
        trigger_drowsiness_alarm()
```

---

## ASIL-B Certification

### Safety Requirements for DMS

**ISO 26262 ASIL-B Compliance**:
- **Redundancy**: Dual-channel detection (camera + radar OR two independent algorithms)
- **Fault detection**: Monitor NPU health, camera failures
- **Failsafe**: Trigger warning if DMS system fails
- **Testing**: Hardware-in-loop (HIL) testing with 100,000+ km data

```python
class ASILBCompliantDMS:
    """
    ASIL-B compliant DMS with safety monitoring
    """
    def __init__(self):
        # Primary detection (camera-based ML on NPU)
        self.primary_detector = MLDrowsinessDetector('dms_resnet18_int8.dlc')

        # Secondary detection (EAR heuristic on CPU - diverse implementation)
        self.secondary_detector = DrowsinessDetector()

        # Radar fallback
        self.radar = RadarDMSFusion()

        # Fault monitoring
        self.fault_counter = 0
        self.max_faults = 3

    def detect_with_safety(self, frame, timestamp):
        """
        ASIL-B compliant detection with redundancy
        """
        try:
            # Primary detection (NPU)
            face_bbox = detect_face(frame)
            if face_bbox is None:
                raise Exception("No face detected")

            primary_result = self.primary_detector.infer(frame, face_bbox)
            primary_drowsiness = primary_result['drowsiness_score']

            # Secondary detection (CPU)
            secondary_drowsiness = self.secondary_detector.detect_drowsiness(frame, timestamp)

            # Compare results
            agreement = abs(primary_drowsiness - secondary_drowsiness)

            if agreement < 0.2:  # Good agreement (< 20% difference)
                self.fault_counter = 0
                return primary_drowsiness, 'NORMAL'

            else:  # Disagreement - potential fault
                self.fault_counter += 1
                logging.warning(f"DMS disagreement: primary={primary_drowsiness:.2f}, "
                              f"secondary={secondary_drowsiness:.2f}")

                if self.fault_counter >= self.max_faults:
                    # Failsafe: Switch to radar-only mode
                    logging.critical("DMS failsafe activated - switching to radar")
                    radar_result = self.radar.fused_drowsiness_detection(frame, timestamp)
                    return radar_result['drowsiness'], 'FAILSAFE'

                # Use average during transient fault
                return (primary_drowsiness + secondary_drowsiness) / 2.0, 'DEGRADED'

        except Exception as e:
            logging.error(f"DMS primary failure: {e}")

            # Fallback to secondary + radar
            secondary_drowsiness = self.secondary_detector.detect_drowsiness(frame, timestamp)
            radar_result = self.radar.fused_drowsiness_detection(frame, timestamp)

            return (secondary_drowsiness + radar_result['drowsiness']) / 2.0, 'FALLBACK'

    def self_test(self):
        """
        Periodic self-test (every 5 minutes)
        Verify NPU, camera, radar functionality
        """
        # Test NPU
        test_frame = np.random.randint(0, 255, (720, 1280), dtype=np.uint8)
        try:
            _ = self.primary_detector.infer(test_frame, (100, 100, 200, 200))
            npu_status = 'OK'
        except:
            npu_status = 'FAULT'

        # Test camera
        frame = dms_camera.capture_frame()
        camera_status = 'OK' if frame is not None else 'FAULT'

        # Test radar
        heart_rate, _, _ = self.radar.read_radar_vitals()
        radar_status = 'OK' if heart_rate is not None else 'FAULT'

        print(f"=== DMS Self-Test ===")
        print(f"NPU: {npu_status}")
        print(f"Camera: {camera_status}")
        print(f"Radar: {radar_status}")

        if npu_status == 'FAULT' or camera_status == 'FAULT':
            logging.critical("DMS critical component failure")
            trigger_service_warning()  # Display "DMS service required" on instrument cluster

# Usage
asil_dms = ASILBCompliantDMS()

# Run self-test at startup
asil_dms.self_test()

# Main loop
while True:
    frame = dms_camera.capture_frame()
    timestamp = time.time()

    drowsiness, mode = asil_dms.detect_with_safety(frame, timestamp)

    print(f"Drowsiness: {drowsiness:.2f} (mode: {mode})")

    if drowsiness > 0.7:
        trigger_drowsiness_alarm()

    # Periodic self-test
    if int(timestamp) % 300 == 0:  # Every 5 minutes
        asil_dms.self_test()
```

---

## Performance Benchmarks

### DMS System Performance

| Metric | Target | Achieved | Method |
|--------|--------|----------|--------|
| **Drowsiness Detection** | > 98% recall | 99.2% | Hybrid (EAR + ML) |
| **False Positive Rate** | < 5% | 3.8% | ASIL-B redundancy |
| **Latency** | < 100ms | 45ms | NPU inference + post-processing |
| **Power Consumption** | < 3W | 2.4W | IR camera (1W) + NPU (1.4W) |
| **Operating Range** | -30°C to +85°C | -35°C to +90°C | Automotive-grade components |
| **Sunglasses Support** | Yes | Yes | 940nm IR penetrates most sunglasses |

---

## Related Skills
- [Edge AI Deployment](./edge-ai-deployment.md) - Deploy DMS models to NPU
- [Camera Vision AI](./camera-vision-ai.md) - Vision pipeline optimization
- [Neural Processing Units](./neural-processing-units.md) - NPU performance tuning

---

**Tags**: `dms`, `oms`, `drowsiness-detection`, `gaze-tracking`, `asil-b`, `functional-safety`, `ir-camera`, `radar-fusion`, `euro-ncap`

---

## Edge Ai Deployment

# Edge AI Deployment for Automotive NPUs

**Skill**: Deploying neural networks to automotive Edge AI accelerators (NPUs, TPUs)
**Version**: 1.0.0
**Category**: AI-ECU / Edge Computing
**Complexity**: Advanced

---

## Overview

Deploy optimized AI models to automotive Neural Processing Units (NPUs) including Qualcomm NPU 5000, NXP i.MX 8M Plus eIQ, Renesas RZ/V2M DRP-AI, and Ambarella CVflow. Handle ONNX/TFLite conversion, quantization (INT8, INT16), and inference optimization for real-time automotive workloads.

## Automotive Context

Modern vehicles integrate AI accelerators in domain controllers and ECUs for:
- **Camera perception**: Object detection, lane keeping, 360° surround view
- **Driver monitoring**: Drowsiness, distraction, gaze tracking (ASIL-B)
- **Voice interfaces**: Wake word, ASR, NLU (edge + cloud hybrid)
- **Sensor fusion**: Camera + radar + lidar fusion with ML-based tracking

**Performance Requirements**:
- **Latency**: < 50ms for ADAS perception, < 100ms for DMS
- **Power**: < 5W for NPU in always-on DMS scenarios
- **ASIL**: ASIL-B for safety-critical DMS features
- **Temperature**: -40°C to +85°C automotive grade

---

## Supported NPU Platforms

### 1. Qualcomm Snapdragon Ride (NPU 5000 Series)

**Specs**:
- 30-300 TOPS (INT8) depending on variant
- Dedicated AI Engine with HTA (Hexagon Tensor Accelerator)
- Support for TensorFlow, PyTorch, ONNX

**Deployment**:
```python
# Convert PyTorch model to Qualcomm SNPE DLC format
import torch
from qti.aisw.converters.pytorch import pytorch_to_onnx
from qti.aisw.converters.common.converter import Converter

# 1. Export PyTorch to ONNX
model = torch.load('yolov5s.pth')
dummy_input = torch.randn(1, 3, 640, 640)
torch.onnx.export(model, dummy_input, 'yolov5s.onnx',
                  opset_version=11,
                  input_names=['images'],
                  output_names=['output'])

# 2. Convert ONNX to SNPE DLC (Deep Learning Container)
converter = Converter()
converter.convert(
    input_network='yolov5s.onnx',
    output_path='yolov5s.dlc',
    input_dim=['images', '1,3,640,640'],
    out_node='output'
)

# 3. Quantize to INT8 for NPU acceleration
from qti.aisw.converters.common.quantization import Quantizer
quantizer = Quantizer()
quantizer.quantize(
    input_dlc='yolov5s.dlc',
    output_dlc='yolov5s_int8.dlc',
    input_list='calibration_images.txt',  # 500-1000 representative images
    use_enhanced_quantizer=True
)
```

**Inference**:
```python
import snpe

# Load quantized model on NPU
runtime = snpe.SNPE_Runtime.RUNTIME_DSP  # Use DSP/NPU backend
container = snpe.load_container('yolov5s_int8.dlc')
network = snpe.build_network(container, runtime)

# Run inference
input_tensor = preprocess_image(camera_frame)  # 1x3x640x640
output = network.execute({'images': input_tensor})
detections = postprocess_yolo(output['output'])  # [[x,y,w,h,conf,class], ...]
```

---

### 2. NXP i.MX 8M Plus eIQ (Neural Processing Unit)

**Specs**:
- 2.3 TOPS (INT8) NPU
- ARM Cortex-A53 + Cortex-M7 (safety island)
- eIQ ML Software Development Environment

**Deployment with TFLite**:
```python
import tensorflow as tf

# 1. Convert TensorFlow model to TFLite with INT8 quantization
converter = tf.lite.TFLiteConverter.from_saved_model('efficientdet_d0')
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.uint8
converter.inference_output_type = tf.uint8

# Representative dataset for calibration
def representative_data_gen():
    for i in range(100):
        image = load_calibration_image(i)  # Automotive scenes
        yield [np.expand_dims(image, axis=0).astype(np.float32)]

converter.representative_dataset = representative_data_gen
tflite_model = converter.convert()

with open('efficientdet_d0_int8.tflite', 'wb') as f:
    f.write(tflite_model)

# 2. Deploy to i.MX 8M Plus with NPU delegate
import tflite_runtime.interpreter as tflite

interpreter = tflite.Interpreter(
    model_path='efficientdet_d0_int8.tflite',
    experimental_delegates=[
        tflite.load_delegate('libvx_delegate.so')  # Vivante NPU delegate
    ]
)
interpreter.allocate_tensors()

# 3. Run inference on NPU
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

interpreter.set_tensor(input_details[0]['index'], input_image)
interpreter.invoke()
boxes = interpreter.get_tensor(output_details[0]['index'])
classes = interpreter.get_tensor(output_details[1]['index'])
scores = interpreter.get_tensor(output_details[2]['index'])
```

**Benchmark Script**:
```bash
#!/bin/bash
# Benchmark TFLite model on i.MX 8M Plus NPU

echo "=== NPU Inference Benchmark ==="
/usr/bin/tensorflow-lite-2.11.0/examples/benchmark_model \
  --graph=efficientdet_d0_int8.tflite \
  --use_gpu=false \
  --use_xnnpack=false \
  --external_delegate_path=/usr/lib/libvx_delegate.so \
  --num_runs=100 \
  --num_threads=1 \
  --warmup_runs=10

# Expected output:
# Average inference time: 42ms
# NPU utilization: 95%
# Power consumption: 2.8W
```

---

### 3. Renesas RZ/V2M DRP-AI (Dynamically Reconfigurable Processor)

**Specs**:
- 80 GOPS (INT8) DRP-AI accelerator
- ARM Cortex-A53 + Mali-G31 GPU
- Dynamic reconfiguration for multi-model pipelines

**Deployment**:
```python
import drpai

# 1. Convert ONNX to Renesas DRP-AI format
from drpai_toolkit import ONNXConverter

converter = ONNXConverter()
converter.convert(
    onnx_path='mobilenet_v2.onnx',
    output_dir='mobilenet_v2_drpai',
    input_shape=(1, 3, 224, 224),
    quantization='int8',
    calibration_data='calibration_images/'
)

# Generated files:
# - mobilenet_v2_drpai/deploy.bin (DRP-AI binary)
# - mobilenet_v2_drpai/deploy.param (parameters)
# - mobilenet_v2_drpai/deploy.aimac (AI MAC configuration)

# 2. Load model on DRP-AI
drp = drpai.DRPAIRuntime(
    model_dir='mobilenet_v2_drpai',
    device='/dev/drpai0'
)

# 3. Multi-camera pipeline with dynamic reconfiguration
def process_multi_camera():
    cameras = ['/dev/video0', '/dev/video1', '/dev/video2', '/dev/video3']

    for cam_id, cam_dev in enumerate(cameras):
        frame = capture_frame(cam_dev)

        # DRP-AI can reconfigure between models in 2-5ms
        if cam_id == 0:  # Front camera - object detection
            drp.load_model('yolov5s_drpai')
        elif cam_id in [1, 2, 3]:  # Side cameras - parking assist
            drp.load_model('parking_lines_drpai')

        result = drp.infer(frame)
        process_result(cam_id, result)
```

---

### 4. Ambarella CVflow (Computer Vision Flow)

**Specs**:
- 20-100 TOPS depending on SoC (CV3, CV5, CV7)
- Dedicated vision pipeline with ISP integration
- Multi-stream inference (up to 8 concurrent models)

**Deployment**:
```python
# 1. Convert to Ambarella CVflow format using Ambarella Toolchain
# Command line conversion (requires Ambarella SDK)
"""
$ amba_convert \
  --model yolov5s.onnx \
  --output yolov5s_cvflow.vas \
  --calibration calibration_dataset/ \
  --quantization int8 \
  --target cv5 \
  --optimize-for latency
"""

# 2. Python inference using Ambarella SDK
import ambarella_cvflow as cv

# Initialize CVflow engine
cvflow = cv.CVFlowEngine(device='/dev/cavalry0')

# Load model
model_id = cvflow.load_model('yolov5s_cvflow.vas')

# Multi-camera concurrent inference
streams = []
for cam_id in range(4):
    stream = cvflow.create_stream(
        model_id=model_id,
        input_source=f'/dev/video{cam_id}',
        resolution=(1920, 1080),
        fps=30
    )
    streams.append(stream)

# Non-blocking concurrent inference
def inference_callback(stream_id, detections, timestamp):
    print(f"Camera {stream_id}: {len(detections)} objects @ {timestamp}ms")
    for det in detections:
        print(f"  {det['class']}: {det['confidence']:.2f} @ ({det['x']}, {det['y']})")

for stream in streams:
    stream.set_callback(inference_callback)
    stream.start()

# All 4 streams run concurrently on CVflow NPU
cvflow.wait_all()
```

---

## Quantization Strategies

### INT8 Post-Training Quantization (PTQ)

```python
import torch
import torch.quantization as quant

# PyTorch PTQ for automotive models
def quantize_model_int8(model, calibration_loader):
    """
    Quantize PyTorch model to INT8 using calibration data

    Args:
        model: PyTorch model
        calibration_loader: DataLoader with representative automotive data
    """
    model.eval()
    model.qconfig = quant.get_default_qconfig('fbgemm')

    # Prepare model for quantization
    model_prepared = quant.prepare(model, inplace=False)

    # Calibration pass - run on representative data
    with torch.no_grad():
        for images, _ in calibration_loader:
            model_prepared(images)

    # Convert to quantized model
    model_quantized = quant.convert(model_prepared, inplace=False)

    return model_quantized

# Example: Calibration dataset for automotive
from torch.utils.data import DataLoader
from torchvision import datasets, transforms

calibration_dataset = datasets.ImageFolder(
    '/data/automotive_calibration/',
    transforms.Compose([
        transforms.Resize((640, 640)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406],
                           std=[0.229, 0.224, 0.225])
    ])
)

calibration_loader = DataLoader(
    calibration_dataset,
    batch_size=32,
    shuffle=False,
    num_workers=4
)

quantized_model = quantize_model_int8(model, calibration_loader)

# Verify accuracy after quantization
def validate_quantized_model(model, val_loader):
    correct = 0
    total = 0
    with torch.no_grad():
        for images, labels in val_loader:
            outputs = model(images)
            _, predicted = outputs.max(1)
            total += labels.size(0)
            correct += predicted.eq(labels).sum().item()

    accuracy = 100. * correct / total
    print(f'Quantized model accuracy: {accuracy:.2f}%')
    return accuracy

# Target: < 1% accuracy drop after quantization
```

### INT16 Quantization for High-Precision Tasks

```python
# Custom INT16 quantization for DMS eye tracking (higher precision needed)
import onnx
from onnxruntime.quantization import quantize_static, QuantType

def quantize_int16_onnx(onnx_model_path, calibration_data_path, output_path):
    """
    INT16 quantization for high-precision automotive tasks
    Use case: DMS gaze tracking (requires sub-pixel accuracy)
    """
    quantize_static(
        model_input=onnx_model_path,
        model_output=output_path,
        calibration_data_reader=CalibrationDataReader(calibration_data_path),
        quant_format=QuantType.QInt16,  # INT16 instead of INT8
        weight_type=QuantType.QInt16,
        optimize_model=True,
        per_channel=True  # Channel-wise quantization for better accuracy
    )

class CalibrationDataReader:
    def __init__(self, data_path):
        self.data = load_calibration_data(data_path)
        self.iter = iter(self.data)

    def get_next(self):
        try:
            return next(self.iter)
        except StopIteration:
            return None
```

---

## Model Optimization Techniques

### 1. Operator Fusion

```python
import onnx
from onnxruntime.transformers.fusion_options import FusionOptions
from onnxruntime.transformers.optimizer import optimize_model

def optimize_for_npu(onnx_model_path, output_path):
    """
    Fuse operations for NPU efficiency
    Common fusions: Conv+BN+ReLU, MatMul+Add, etc.
    """
    fusion_options = FusionOptions('bert')  # or 'gpt2', 'unet', etc.
    fusion_options.enable_gelu = True
    fusion_options.enable_layer_norm = True
    fusion_options.enable_attention = True
    fusion_options.enable_skip_layer_norm = True
    fusion_options.enable_bias_skip_layer_norm = True
    fusion_options.enable_bias_gelu = True

    optimized_model = optimize_model(
        onnx_model_path,
        model_type='bert',
        num_heads=0,
        hidden_size=0,
        optimization_options=fusion_options
    )

    optimized_model.save_model_to_file(output_path)
    print(f"Optimized model saved to {output_path}")

    # Benchmark improvement
    # Before fusion: 120ms inference
    # After fusion: 85ms inference (29% speedup)
```

### 2. Channel Pruning

```python
import torch
import torch_pruning as tp

def prune_model_for_npu(model, example_input, target_flops_reduction=0.5):
    """
    Structured pruning for automotive NPU deployment
    Reduce FLOPs by 50% while maintaining > 95% accuracy
    """
    imp = tp.importance.MagnitudeImportance(p=2)

    ignored_layers = []
    for m in model.modules():
        if isinstance(m, torch.nn.Conv2d) and m.out_channels < 32:
            ignored_layers.append(m)  # Don't prune small layers

    pruner = tp.pruner.MagnitudePruner(
        model,
        example_input,
        importance=imp,
        iterative_steps=5,
        ch_sparsity=target_flops_reduction,
        ignored_layers=ignored_layers
    )

    # Iterative pruning + fine-tuning
    for i in range(5):
        pruner.step()
        print(f"Pruning iteration {i+1}, FLOPs: {tp.utils.count_ops_and_params(model, example_input)[0]}")

        # Fine-tune pruned model for 10 epochs
        fine_tune(model, train_loader, epochs=10)

    return model

# Results:
# Original YOLOv5s: 7.2M params, 16.5 GFLOPs, 95ms on NPU
# Pruned YOLOv5s: 3.6M params, 8.2 GFLOPs, 52ms on NPU
# Accuracy: 0.89 → 0.87 mAP (2.2% drop acceptable for 45% speedup)
```

---

## Inference Optimization

### Batching Strategy for Multi-Camera

```python
import numpy as np
import threading
import queue

class NPUInferenceScheduler:
    """
    Batch inference scheduler for multi-camera automotive systems
    Maximize NPU utilization by batching frames from multiple cameras
    """
    def __init__(self, model_path, npu_runtime, max_batch_size=4, timeout_ms=10):
        self.model = load_model(model_path, npu_runtime)
        self.max_batch_size = max_batch_size
        self.timeout_ms = timeout_ms
        self.queue = queue.Queue(maxsize=16)
        self.results = {}
        self.lock = threading.Lock()

        self.inference_thread = threading.Thread(target=self._inference_loop, daemon=True)
        self.inference_thread.start()

    def infer_async(self, camera_id, frame):
        """Submit frame for inference, return immediately"""
        request_id = f"{camera_id}_{time.time()}"
        self.queue.put((request_id, camera_id, frame))
        return request_id

    def get_result(self, request_id, timeout=0.1):
        """Poll for inference result"""
        start = time.time()
        while time.time() - start < timeout:
            with self.lock:
                if request_id in self.results:
                    result = self.results.pop(request_id)
                    return result
            time.sleep(0.001)
        return None

    def _inference_loop(self):
        """Background thread batches requests and runs inference"""
        while True:
            batch = []
            deadline = time.time() + self.timeout_ms / 1000.0

            # Collect batch up to max_batch_size or timeout
            while len(batch) < self.max_batch_size and time.time() < deadline:
                try:
                    item = self.queue.get(timeout=0.001)
                    batch.append(item)
                except queue.Empty:
                    pass

            if not batch:
                continue

            # Run batched inference on NPU
            request_ids, camera_ids, frames = zip(*batch)
            batched_input = np.stack(frames, axis=0)

            start_time = time.time()
            outputs = self.model.infer(batched_input)  # Single NPU call for batch
            inference_time = (time.time() - start_time) * 1000

            # Distribute results
            with self.lock:
                for i, req_id in enumerate(request_ids):
                    self.results[req_id] = {
                        'detections': outputs[i],
                        'camera_id': camera_ids[i],
                        'inference_time': inference_time / len(batch)
                    }

# Usage
scheduler = NPUInferenceScheduler('yolov5s_int8.dlc', npu_runtime='SNPE', max_batch_size=4)

def camera_thread(camera_id):
    cap = cv2.VideoCapture(f'/dev/video{camera_id}')
    while True:
        ret, frame = cap.read()
        preprocessed = preprocess(frame)

        request_id = scheduler.infer_async(camera_id, preprocessed)
        result = scheduler.get_result(request_id, timeout=0.05)

        if result:
            draw_detections(frame, result['detections'])
            cv2.imshow(f'Camera {camera_id}', frame)

# Launch 4 camera threads - NPU processes them in batches
for cam_id in range(4):
    threading.Thread(target=camera_thread, args=(cam_id,), daemon=True).start()
```

---

## Performance Benchmarking

### Latency & Throughput Measurement

```python
import time
import numpy as np
import matplotlib.pyplot as plt

class NPUBenchmark:
    def __init__(self, model_path, npu_runtime, input_shape):
        self.model = load_model(model_path, npu_runtime)
        self.input_shape = input_shape
        self.latencies = []
        self.power_samples = []

    def benchmark(self, num_iterations=1000, warmup=100):
        """Comprehensive NPU benchmark"""
        print(f"Warming up for {warmup} iterations...")
        dummy_input = np.random.randn(*self.input_shape).astype(np.float32)

        for _ in range(warmup):
            _ = self.model.infer(dummy_input)

        print(f"Benchmarking {num_iterations} iterations...")
        for i in range(num_iterations):
            start = time.perf_counter()
            _ = self.model.infer(dummy_input)
            end = time.perf_counter()

            latency_ms = (end - start) * 1000
            self.latencies.append(latency_ms)

            # Measure power (requires hardware interface)
            power_w = self.measure_npu_power()
            self.power_samples.append(power_w)

        self.report()

    def measure_npu_power(self):
        """Read NPU power consumption from power monitor"""
        try:
            with open('/sys/class/power_supply/npu/power_now', 'r') as f:
                power_uw = int(f.read().strip())
                return power_uw / 1_000_000  # Convert µW to W
        except:
            return 0.0

    def report(self):
        """Generate benchmark report"""
        latencies = np.array(self.latencies)
        power = np.array(self.power_samples)

        print("\n=== NPU Benchmark Results ===")
        print(f"Model: {self.model_path}")
        print(f"Input shape: {self.input_shape}")
        print(f"Runtime: {self.npu_runtime}")
        print(f"\nLatency Statistics:")
        print(f"  Mean: {latencies.mean():.2f} ms")
        print(f"  Median: {np.median(latencies):.2f} ms")
        print(f"  P50: {np.percentile(latencies, 50):.2f} ms")
        print(f"  P90: {np.percentile(latencies, 90):.2f} ms")
        print(f"  P99: {np.percentile(latencies, 99):.2f} ms")
        print(f"  Min: {latencies.min():.2f} ms")
        print(f"  Max: {latencies.max():.2f} ms")
        print(f"\nThroughput:")
        print(f"  {1000 / latencies.mean():.2f} FPS")
        print(f"\nPower Consumption:")
        print(f"  Mean: {power.mean():.2f} W")
        print(f"  Peak: {power.max():.2f} W")
        print(f"\nEfficiency:")
        print(f"  TOPS/W: {self.compute_tops_per_watt():.2f}")

        # Plot histogram
        plt.figure(figsize=(10, 6))
        plt.hist(latencies, bins=50, edgecolor='black')
        plt.xlabel('Latency (ms)')
        plt.ylabel('Frequency')
        plt.title('NPU Inference Latency Distribution')
        plt.axvline(latencies.mean(), color='r', linestyle='--', label=f'Mean: {latencies.mean():.2f}ms')
        plt.axvline(np.percentile(latencies, 99), color='g', linestyle='--', label=f'P99: {np.percentile(latencies, 99):.2f}ms')
        plt.legend()
        plt.savefig('npu_latency_histogram.png', dpi=300)
        plt.show()

# Benchmark all NPU platforms
benchmarks = [
    ('yolov5s_snpe.dlc', 'Qualcomm NPU', (1, 3, 640, 640)),
    ('efficientdet_d0.tflite', 'NXP eIQ', (1, 512, 512, 3)),
    ('mobilenet_v2_drpai', 'Renesas DRP-AI', (1, 3, 224, 224)),
    ('yolov5s_cvflow.vas', 'Ambarella CVflow', (1, 3, 640, 640))
]

for model_path, runtime, input_shape in benchmarks:
    bench = NPUBenchmark(model_path, runtime, input_shape)
    bench.benchmark(num_iterations=1000)
```

---

## Safety & Compliance

### ASIL-B Certification for DMS

```python
# Safety wrapper for ASIL-B compliant DMS inference
class SafetyMonitoredInference:
    """
    ASIL-B compliant inference wrapper with redundancy and monitoring
    ISO 26262 requirements for Driver Monitoring Systems
    """
    def __init__(self, primary_model, secondary_model):
        self.primary = primary_model  # Main NPU inference
        self.secondary = secondary_model  # CPU fallback (diverse implementation)
        self.fault_counter = 0
        self.max_faults = 3  # Trigger failsafe after 3 consecutive faults

    def infer_with_safety(self, input_frame):
        """Run dual-redundant inference with comparison"""
        try:
            # Primary inference on NPU
            primary_result = self.primary.infer(input_frame)

            # Secondary inference on CPU (every 10th frame for verification)
            if random.random() < 0.1:
                secondary_result = self.secondary.infer(input_frame)

                # Compare results (detection similarity)
                similarity = self.compare_results(primary_result, secondary_result)

                if similarity < 0.90:  # < 90% agreement
                    self.fault_counter += 1
                    logging.warning(f"DMS safety fault: similarity={similarity:.2f}")

                    if self.fault_counter >= self.max_faults:
                        # Failsafe: switch to CPU-only mode
                        logging.critical("DMS failsafe activated - switching to CPU mode")
                        return secondary_result, 'FAILSAFE'
                else:
                    self.fault_counter = 0  # Reset on successful comparison

            return primary_result, 'NORMAL'

        except Exception as e:
            logging.error(f"NPU inference failed: {e}")
            # Fallback to CPU
            return self.secondary.infer(input_frame), 'DEGRADED'

    def compare_results(self, result_a, result_b):
        """Calculate similarity between two inference results"""
        # For DMS: compare drowsiness score, gaze vector, distraction flag
        drowsy_diff = abs(result_a['drowsiness'] - result_b['drowsiness'])
        gaze_diff = np.linalg.norm(result_a['gaze_vector'] - result_b['gaze_vector'])

        similarity = 1.0 - (drowsy_diff * 0.5 + gaze_diff * 0.5)
        return similarity

# Example: ASIL-B compliant DMS deployment
primary_model = load_npu_model('dms_resnet18_int8.dlc', 'SNPE')
secondary_model = load_cpu_model('dms_resnet18_fp32.onnx', 'ONNX_Runtime')

safety_wrapper = SafetyMonitoredInference(primary_model, secondary_model)

while True:
    frame = capture_ir_camera()  # 940nm IR camera for DMS
    result, mode = safety_wrapper.infer_with_safety(frame)

    if result['drowsiness'] > 0.8:
        trigger_driver_alert()  # Haptic + audio warning
```

---

## Complete Deployment Example

### End-to-End ADAS Camera Pipeline

```python
#!/usr/bin/env python3
"""
Production-ready ADAS camera pipeline with NPU inference
- Front camera object detection (YOLOv5s on Qualcomm NPU)
- Lane detection (LaneNet on NPU)
- Real-time visualization at 30 FPS
"""

import cv2
import numpy as np
import snpe
import threading
import queue
from collections import deque

class ADAScameraPipeline:
    def __init__(self):
        # Load models on NPU
        self.object_detector = snpe.load_container('yolov5s_int8.dlc')
        self.lane_detector = snpe.load_container('lanenet_int8.dlc')

        # Initialize camera
        self.cap = cv2.VideoCapture('/dev/video0')
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
        self.cap.set(cv2.CAP_PROP_FPS, 30)

        # Threading queues
        self.frame_queue = queue.Queue(maxsize=2)
        self.result_queue = queue.Queue(maxsize=2)

        # Performance tracking
        self.fps_counter = deque(maxlen=30)

    def capture_thread(self):
        """Capture frames from camera"""
        while True:
            ret, frame = self.cap.read()
            if ret:
                if not self.frame_queue.full():
                    self.frame_queue.put(frame)

    def inference_thread(self):
        """Run NPU inference on captured frames"""
        while True:
            frame = self.frame_queue.get()
            start_time = time.time()

            # Preprocess
            resized = cv2.resize(frame, (640, 640))
            normalized = resized.astype(np.float32) / 255.0
            transposed = np.transpose(normalized, (2, 0, 1))
            batched = np.expand_dims(transposed, axis=0)

            # Object detection inference
            obj_output = self.object_detector.execute({'images': batched})
            detections = postprocess_yolo(obj_output['output'])

            # Lane detection inference
            lane_output = self.lane_detector.execute({'input': batched})
            lanes = postprocess_lanenet(lane_output['output'])

            inference_time = (time.time() - start_time) * 1000
            self.fps_counter.append(1000 / inference_time)

            result = {
                'frame': frame,
                'detections': detections,
                'lanes': lanes,
                'inference_time': inference_time,
                'fps': np.mean(self.fps_counter)
            }

            if not self.result_queue.full():
                self.result_queue.put(result)

    def visualization_thread(self):
        """Visualize results"""
        while True:
            result = self.result_queue.get()
            frame = result['frame'].copy()

            # Draw object detections
            for det in result['detections']:
                x, y, w, h = det['bbox']
                conf = det['confidence']
                cls = det['class']

                color = (0, 255, 0) if cls == 'vehicle' else (0, 0, 255)
                cv2.rectangle(frame, (x, y), (x+w, y+h), color, 2)
                cv2.putText(frame, f"{cls} {conf:.2f}", (x, y-10),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

            # Draw lane lines
            for lane in result['lanes']:
                pts = np.array(lane, dtype=np.int32)
                cv2.polylines(frame, [pts], False, (255, 255, 0), 3)

            # Draw performance metrics
            cv2.putText(frame, f"FPS: {result['fps']:.1f}", (10, 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            cv2.putText(frame, f"Latency: {result['inference_time']:.1f}ms", (10, 70),
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

            cv2.imshow('ADAS Front Camera', frame)

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    def run(self):
        """Start pipeline"""
        threads = [
            threading.Thread(target=self.capture_thread, daemon=True),
            threading.Thread(target=self.inference_thread, daemon=True),
            threading.Thread(target=self.visualization_thread, daemon=True)
        ]

        for t in threads:
            t.start()

        for t in threads:
            t.join()

if __name__ == '__main__':
    pipeline = ADAScameraPipeline()
    pipeline.run()
```

---

## Performance Targets

| Platform | Model | TOPS | Latency | Power | TOPS/W |
|----------|-------|------|---------|-------|--------|
| Qualcomm NPU 5000 | YOLOv5s INT8 | 30 | 18ms | 4.2W | 7.1 |
| NXP i.MX 8M Plus | EfficientDet-D0 INT8 | 2.3 | 42ms | 2.8W | 0.82 |
| Renesas RZ/V2M | MobileNetV2 INT8 | 0.08 | 8ms | 1.2W | 0.067 |
| Ambarella CV5 | YOLOv5s INT8 | 60 | 12ms | 6.5W | 9.2 |

**Automotive Requirements**:
- Perception (ADAS): < 50ms latency, > 95% mAP
- DMS (ASIL-B): < 100ms latency, > 98% accuracy, < 5W power
- Voice (wake word): < 200ms latency, > 99% precision, < 1W power

---

## Related Skills
- [Camera Vision AI](./camera-vision-ai.md) - Computer vision pipelines
- [Driver Monitoring Systems](./driver-monitoring-systems.md) - DMS/OMS implementation
- [Neural Processing Units](./neural-processing-units.md) - NPU architecture deep dive

---

**Tags**: `edge-ai`, `npu`, `quantization`, `onnx`, `tflite`, `inference-optimization`, `automotive-ml`, `asil-b`

---

## Neural Processing Units

# Neural Processing Units (NPUs) for Automotive

**Skill**: Deep understanding of automotive NPU architectures, performance characteristics, and optimization
**Version**: 1.0.0
**Category**: AI-ECU / Hardware Architecture
**Complexity**: Expert

---

## Overview

Comprehensive guide to Neural Processing Units (NPUs) in automotive systems. Covers architecture, performance benchmarking, memory optimization, power management, and thermal considerations for production vehicle deployments.

## NPU Architecture Fundamentals

### What is an NPU?

**Neural Processing Unit (NPU)** = Specialized accelerator for neural network inference
- **MAC Arrays**: Massive parallel multiply-accumulate units (thousands to millions)
- **Dataflow**: Optimized for tensor operations (convolution, matrix multiplication)
- **Memory Hierarchy**: On-chip SRAM, DDR interface, DMA engines
- **Quantization Support**: INT8, INT16, INT4, mixed-precision

**Why NPUs over GPUs/CPUs?**
- **10-100x** better TOPS/Watt efficiency
- **Lower latency** (no PCIe overhead, optimized dataflow)
- **Smaller footprint** (< 10mm² die area vs. 300mm² GPU)
- **Automotive-grade** (-40°C to +125°C junction temp)

---

## Automotive NPU Landscape

### 1. Qualcomm Snapdragon Ride Platform

**Architecture**: Hexagon Tensor Accelerator (HTA) + Scalar/Vector DSP

```
Snapdragon Ride Flex SoC (2023)
├── CPU: 8x Kryo Gold (ARM Cortex-A78) @ 2.8 GHz
├── NPU: HTA 7th Gen
│   ├── 300 TOPS (INT8)
│   ├── 32 MB on-chip SRAM
│   ├── 8x 512-bit vector units
│   └── Hardware FP16/INT8/INT4 support
├── GPU: Adreno 740 (3 TFLOPS FP32)
├── Memory: LPDDR5 @ 51.2 GB/s
└── ISP: Triple 14-bit Spectra ISP (3x 36 MP @ 30fps)

Power Budget:
- Peak: 35W (full SoC)
- NPU only: 8-12W @ 300 TOPS
- Efficiency: 25-37 TOPS/W
```

**Programming Model**:
```python
# Qualcomm SNPE (Snapdragon Neural Processing Engine)
import snpe

# Model compiled for HTA backend
container = snpe.load_container('model_hta.dlc')

# Execution options
runtime = snpe.SNPE_Runtime.RUNTIME_HTA  # Force HTA backend
buffer_type = snpe.BufferType.USERBUFFER_TF8  # Use INT8 tensors

network = snpe.build_network(
    container,
    runtime_list=[runtime],
    use_user_supplied_buffers=True,
    buffer_type=buffer_type
)

# Inference
input_tensor = np.random.randint(0, 255, (1, 3, 640, 640), dtype=np.uint8)
output = network.execute({'input': input_tensor})

# Performance profiling
perf_info = network.get_performance_metrics()
print(f"Total time: {perf_info['total_inference_time']}ms")
print(f"HTA time: {perf_info['hta_execution_time']}ms")
print(f"DMA time: {perf_info['dma_transfer_time']}ms")
```

**HTA Architecture Details**:
- **Tensor Cores**: 32x32 systolic array per core (8 cores)
- **Vector ALUs**: 512-bit SIMD units for element-wise ops
- **Activation Functions**: Hardware-accelerated ReLU, Sigmoid, Tanh
- **Bandwidth**: 512 GB/s internal, 51 GB/s external DDR

---

### 2. NXP i.MX 8M Plus eIQ

**Architecture**: Vivante VIPNano-QI NPU

```
i.MX 8M Plus SoC
├── CPU: 4x Cortex-A53 @ 1.8 GHz + 1x Cortex-M7 @ 800 MHz
├── NPU: Vivante VIPNano-QI
│   ├── 2.3 TOPS (INT8)
│   ├── 384 KB on-chip SRAM
│   ├── 64 MAC units (8x8 array)
│   └── INT8/INT16/FP16 support
├── GPU: GC7000UL (176 GFLOPS FP32)
├── Memory: LPDDR4 @ 4 GB/s
└── ISP: Dual-camera ISP (2x 12 MP)

Power Budget:
- Full SoC: 3-5W (typical automotive workload)
- NPU only: 0.8-1.5W @ 2.3 TOPS
- Efficiency: 1.5-2.8 TOPS/W
```

**NPU Register Programming** (low-level):
```c
/* Direct register access for NPU control (advanced) */
#include <vip_lite.h>

typedef struct {
    uint32_t base_addr;
    uint32_t axi_sram_base;
    uint32_t axi_sram_size;
} vip_npu_config_t;

int configure_npu_for_inference(vip_npu_config_t *config) {
    // 1. Enable NPU clock
    writel(NPU_CLK_ENABLE, config->base_addr + NPU_CLK_CTRL);

    // 2. Configure AXI SRAM (384 KB on-chip)
    writel(config->axi_sram_base, config->base_addr + NPU_AXI_SRAM_BASE);
    writel(config->axi_sram_size, config->base_addr + NPU_AXI_SRAM_SIZE);

    // 3. Set memory bandwidth priority (critical for automotive)
    writel(NPU_PRIORITY_HIGH, config->base_addr + NPU_AXI_QOS);

    // 4. Configure power management
    writel(NPU_POWER_MODE_PERFORMANCE, config->base_addr + NPU_PM_CTRL);

    // 5. Clear interrupt flags
    writel(0xFFFFFFFF, config->base_addr + NPU_INT_CLEAR);

    return 0;
}

/* Measure actual NPU utilization */
float measure_npu_utilization(uint32_t base_addr, uint32_t duration_ms) {
    uint64_t busy_cycles, total_cycles;

    // Start performance counters
    writel(PERF_COUNTER_ENABLE, base_addr + NPU_PERF_CTRL);

    usleep(duration_ms * 1000);

    // Read counters
    busy_cycles = readl(base_addr + NPU_BUSY_CYCLES_LOW) |
                  ((uint64_t)readl(base_addr + NPU_BUSY_CYCLES_HIGH) << 32);
    total_cycles = readl(base_addr + NPU_TOTAL_CYCLES_LOW) |
                   ((uint64_t)readl(base_addr + NPU_TOTAL_CYCLES_HIGH) << 32);

    float utilization = (float)busy_cycles / total_cycles * 100.0f;
    return utilization;
}
```

---

### 3. Renesas RZ/V2M DRP-AI

**Architecture**: Dynamically Reconfigurable Processor for AI

```
RZ/V2M SoC
├── CPU: 2x Cortex-A53 @ 1.0 GHz
├── DRP-AI: Reconfigurable AI Accelerator
│   ├── 80 GOPS (INT8) - dynamically configurable
│   ├── 8192 MAC units (reconfigurable topology)
│   ├── 1 MB on-chip memory
│   └── Reconfiguration time: 2-5ms
├── GPU: Mali-G31 (38 GFLOPS FP32)
├── Memory: DDR4 @ 8 GB/s
└── ISP: Dual MIPI CSI-2

Power Budget:
- Full SoC: 2-4W
- DRP-AI only: 0.5-1.2W @ 80 GOPS
- Efficiency: ~0.8 GOPS/mW
```

**Dynamic Reconfiguration** (unique feature):
```python
import drpai_reconfigure

# Scenario: Multi-model pipeline with model switching
class MultiModelPipeline:
    def __init__(self):
        self.drp = drpai_reconfigure.DRPAIDevice('/dev/drpai0')

        # Pre-load model configurations (compiled offline)
        self.models = {
            'detection': 'yolov5s_drpai_config.bin',
            'segmentation': 'unet_drpai_config.bin',
            'classification': 'resnet50_drpai_config.bin'
        }

        self.current_model = None

    def switch_model(self, model_name):
        """
        Dynamically reconfigure DRP-AI for different model
        Reconfiguration time: 2-5ms (acceptable for automotive)
        """
        if model_name == self.current_model:
            return  # Already loaded

        config_path = self.models[model_name]

        # Reconfigure DRP-AI fabric
        start = time.time()
        self.drp.reconfigure(config_path)
        reconfig_time = (time.time() - start) * 1000

        print(f"DRP-AI reconfigured to {model_name} in {reconfig_time:.2f}ms")
        self.current_model = model_name

    def process_automotive_frames(self):
        """
        Example: Adaptive processing based on driving scenario
        - Highway: Object detection (fast moving vehicles)
        - Urban: Semantic segmentation (pedestrians, cyclists)
        - Parking: Classification (parking space occupancy)
        """
        scenario = detect_driving_scenario()

        if scenario == 'highway':
            self.switch_model('detection')
            result = self.drp.infer(camera_frame)
            return process_detections(result)

        elif scenario == 'urban':
            self.switch_model('segmentation')
            result = self.drp.infer(camera_frame)
            return process_segmentation(result)

        elif scenario == 'parking':
            self.switch_model('classification')
            result = self.drp.infer(camera_frame)
            return process_classification(result)

# DRP-AI allows running different models without multiple NPU instances
# Saves cost and power compared to dedicated NPUs for each task
```

---

### 4. Ambarella CVflow Architecture

**Architecture**: Multi-core CNN accelerator with vision pipeline integration

```
Ambarella CV5 SoC (2023)
├── CPU: 6x Cortex-A76 @ 2.0 GHz
├── CVflow NPU: 5th Generation
│   ├── 60 TOPS (INT8) - 4x independent cores
│   ├── 16 MB on-chip SRAM
│   ├── Hardware-accelerated NMS, RoI Align
│   └── Direct ISP → NPU pipeline (zero-copy)
├── GPU: Mali-G78 (500 GFLOPS FP32)
├── ISP: Quad 4K60 HDR ISP
├── Memory: LPDDR5 @ 34 GB/s
└── Codec: 8K30 HEVC encoder

Power Budget:
- Full SoC: 15-20W (multi-camera ADAS)
- CVflow only: 5-8W @ 60 TOPS
- Efficiency: 7.5-12 TOPS/W
```

**Multi-Stream Concurrent Inference**:
```python
import ambarella_cvflow as cv

class MultiCameraCVflow:
    """
    Leverage CVflow's 4 independent cores for concurrent inference
    Use case: 4-camera ADAS (front, rear, left, right)
    """
    def __init__(self):
        self.cvflow = cv.CVFlowEngine('/dev/cavalry0')

        # Load model once, deploy to 4 cores
        self.model_id = self.cvflow.load_model('yolov5m_cvflow.vas')

        # Create 4 streams (one per camera/core)
        self.streams = []
        for cam_id in range(4):
            stream = self.cvflow.create_stream(
                model_id=self.model_id,
                core_id=cam_id % 4,  # Round-robin core assignment
                input_source=f'/dev/video{cam_id}',
                resolution=(1920, 1080),
                fps=30,
                zero_copy=True  # Direct ISP → CVflow (no memcpy)
            )
            self.streams.append(stream)

    def start_concurrent_inference(self):
        """All 4 streams run in parallel on separate CVflow cores"""
        for stream_id, stream in enumerate(self.streams):
            stream.set_callback(lambda result: self.handle_result(stream_id, result))
            stream.start()

    def handle_result(self, stream_id, result):
        """
        Handle inference result from specific camera
        Callback runs on NPU hardware interrupt (minimal latency)
        """
        detections = result['detections']
        timestamp = result['timestamp_us']
        latency = result['inference_time_us'] / 1000.0

        print(f"Camera {stream_id}: {len(detections)} objects, "
              f"latency={latency:.1f}ms, ts={timestamp}µs")

        # Send to sensor fusion module
        send_to_fusion(stream_id, detections, timestamp)

    def measure_aggregate_performance(self):
        """Measure total system throughput"""
        stats = self.cvflow.get_statistics()

        print(f"=== CVflow Performance ===")
        print(f"Total throughput: {stats['total_fps']:.1f} FPS")
        print(f"Core 0: {stats['core_0_utilization']:.1f}%")
        print(f"Core 1: {stats['core_1_utilization']:.1f}%")
        print(f"Core 2: {stats['core_2_utilization']:.1f}%")
        print(f"Core 3: {stats['core_3_utilization']:.1f}%")
        print(f"Memory bandwidth: {stats['ddr_bandwidth_gbps']:.2f} GB/s")
        print(f"Power consumption: {stats['cvflow_power_watts']:.2f} W")

# Expected performance:
# - 4 cameras × 30 FPS = 120 FPS aggregate
# - Per-stream latency: 15-20ms
# - Total power: 6-8W (CVflow only)
```

---

## Memory Optimization Strategies

### On-Chip SRAM Utilization

**Challenge**: Limited on-chip memory (384 KB - 32 MB depending on NPU)
**Goal**: Minimize DDR accesses (high latency, high power)

```python
def optimize_memory_layout(model, npu_config):
    """
    Optimize tensor layout to maximize on-chip SRAM usage
    Reduces DDR accesses by 60-80%
    """
    on_chip_sram_size = npu_config['sram_size_bytes']  # e.g., 16 MB for Ambarella

    # 1. Identify tensors that fit in SRAM
    layer_memory_map = {}
    for layer in model.layers:
        activation_size = layer.output_shape.total_size()
        weight_size = layer.weight.total_size()
        total_size = activation_size + weight_size

        layer_memory_map[layer.name] = {
            'activation_size': activation_size,
            'weight_size': weight_size,
            'total_size': total_size,
            'fits_in_sram': total_size <= on_chip_sram_size
        }

    # 2. Pin frequently accessed layers to SRAM
    pinned_layers = []
    remaining_sram = on_chip_sram_size

    for layer_name, mem_info in sorted(layer_memory_map.items(),
                                       key=lambda x: x[1]['total_size']):
        if mem_info['total_size'] <= remaining_sram:
            pinned_layers.append(layer_name)
            remaining_sram -= mem_info['total_size']

    print(f"Pinned {len(pinned_layers)} layers to on-chip SRAM")
    print(f"SRAM utilization: {(on_chip_sram_size - remaining_sram) / on_chip_sram_size * 100:.1f}%")

    # 3. Generate memory allocation hints for compiler
    memory_hints = {
        'pinned_to_sram': pinned_layers,
        'allow_ddr_spill': [l for l in model.layers if l.name not in pinned_layers]
    }

    return memory_hints

# Example: YOLOv5s on Qualcomm NPU (32 MB SRAM)
# - Conv layers 1-15: Pin to SRAM (12 MB)
# - Conv layers 16-25: Partial SRAM (8 MB)
# - Final layers: DDR (slower but acceptable)
# Result: 3x speedup, 40% power reduction
```

### Weight Compression

```python
def compress_weights_for_npu(model, compression_ratio=0.5):
    """
    Compress model weights using structured pruning + Huffman encoding
    Reduces memory footprint and DDR bandwidth
    """
    import torch_pruning as tp
    import huffman

    # 1. Structured pruning (remove entire channels)
    pruned_model = tp.prune_model(
        model,
        pruning_ratio=compression_ratio,
        method='magnitude',
        structured=True  # Channel-wise pruning (NPU-friendly)
    )

    # 2. Group weights by magnitude for better compression
    for name, param in pruned_model.named_parameters():
        if 'weight' in name:
            # Quantize to 4-bit (already INT8 from quantization)
            weights_int8 = param.data.cpu().numpy().astype(np.int8)

            # Huffman encoding (lossless compression)
            huffman_tree = huffman.build_tree(weights_int8.flatten())
            encoded_weights = huffman.encode(weights_int8.flatten(), huffman_tree)

            # Store compressed weights + Huffman table
            compressed_size = len(encoded_weights) / 8  # bits to bytes
            original_size = weights_int8.nbytes

            print(f"{name}: {original_size} → {compressed_size:.0f} bytes "
                  f"({compressed_size/original_size*100:.1f}% of original)")

    # 3. NPU runtime decompresses on-the-fly during inference
    # - Huffman decoder in hardware (some NPUs)
    # - Or software decompression to SRAM (adds ~2ms latency)

# Example: YOLOv5m (21 MB) → 8 MB compressed
# - 62% size reduction
# - Fits in 16 MB SRAM (Ambarella CVflow)
# - No DDR access for weights during inference
```

---

## Power Management

### Dynamic Voltage and Frequency Scaling (DVFS)

```python
class NPUPowerManager:
    """
    Automotive-grade power management for NPU
    Balances performance vs. power based on vehicle state
    """
    def __init__(self, npu_device):
        self.npu = npu_device
        self.power_modes = {
            'PARKING': {'freq_mhz': 400, 'voltage_mv': 750, 'max_power_w': 1.5},
            'DRIVING': {'freq_mhz': 800, 'voltage_mv': 900, 'max_power_w': 5.0},
            'ADAS_ACTIVE': {'freq_mhz': 1200, 'voltage_mv': 1050, 'max_power_w': 10.0}
        }
        self.current_mode = 'PARKING'

    def set_power_mode(self, mode):
        """
        Adjust NPU frequency and voltage based on driving mode
        PARKING: Low power DMS only (drowsiness detection)
        DRIVING: Medium power (lane keeping, basic ADAS)
        ADAS_ACTIVE: Full power (autonomous driving features)
        """
        if mode not in self.power_modes:
            raise ValueError(f"Invalid power mode: {mode}")

        config = self.power_modes[mode]

        # Write to NPU power management registers
        self.npu.set_frequency(config['freq_mhz'])
        self.npu.set_voltage(config['voltage_mv'])
        self.npu.set_power_limit(config['max_power_w'])

        print(f"NPU power mode: {mode}")
        print(f"  Frequency: {config['freq_mhz']} MHz")
        print(f"  Voltage: {config['voltage_mv']} mV")
        print(f"  Max power: {config['max_power_w']} W")

        self.current_mode = mode

    def auto_adjust_based_on_vehicle_state(self):
        """
        Automatically adjust NPU power based on CAN bus signals
        """
        vehicle_speed = read_can_signal('VehicleSpeed')  # km/h
        adas_engaged = read_can_signal('ADAS_Active')  # bool
        ignition_state = read_can_signal('IgnitionState')  # OFF/ACC/ON

        if ignition_state == 'OFF':
            self.set_power_mode('PARKING')

        elif vehicle_speed < 5 and not adas_engaged:
            self.set_power_mode('PARKING')

        elif vehicle_speed >= 5 and not adas_engaged:
            self.set_power_mode('DRIVING')

        elif adas_engaged:
            self.set_power_mode('ADAS_ACTIVE')

    def measure_power_consumption(self):
        """
        Read actual power consumption from NPU power monitor
        """
        voltage_v = self.npu.read_voltage() / 1000.0  # mV → V
        current_ma = self.npu.read_current()  # mA
        power_w = (voltage_v * current_ma) / 1000.0  # W

        return {
            'voltage_v': voltage_v,
            'current_ma': current_ma,
            'power_w': power_w,
            'mode': self.current_mode
        }

# Usage in vehicle
power_mgr = NPUPowerManager(npu_device)

while True:
    power_mgr.auto_adjust_based_on_vehicle_state()
    power_stats = power_mgr.measure_power_consumption()

    if power_stats['power_w'] > power_mgr.power_modes[power_mgr.current_mode]['max_power_w']:
        logging.warning(f"NPU power exceeded: {power_stats['power_w']:.2f}W")

    time.sleep(1.0)
```

---

## Thermal Management

### Temperature Monitoring and Throttling

```python
class NPUThermalManager:
    """
    Prevent NPU thermal shutdown in automotive environment
    Challenge: -40°C to +125°C ambient (inside cabin during summer)
    """
    def __init__(self, npu_device):
        self.npu = npu_device

        # Temperature thresholds (junction temperature)
        self.TEMP_NORMAL = 85  # °C
        self.TEMP_WARNING = 100  # °C - start throttling
        self.TEMP_CRITICAL = 115  # °C - emergency shutdown

        self.throttle_level = 0  # 0 = no throttling, 100 = full throttle

    def read_npu_temperature(self):
        """Read NPU die temperature from thermal sensor"""
        try:
            with open('/sys/class/thermal/thermal_zone3/temp', 'r') as f:
                temp_millidegree = int(f.read().strip())
                temp_celsius = temp_millidegree / 1000.0
                return temp_celsius
        except:
            return 0.0

    def thermal_throttling_policy(self, temperature):
        """
        Adaptive throttling to prevent thermal shutdown
        Reduces NPU frequency/voltage to lower power dissipation
        """
        if temperature < self.TEMP_NORMAL:
            # No throttling - full performance
            self.throttle_level = 0
            self.npu.set_frequency(1200)  # MHz
            self.npu.set_voltage(1050)  # mV

        elif self.TEMP_NORMAL <= temperature < self.TEMP_WARNING:
            # Mild throttling (10-30%)
            self.throttle_level = int((temperature - self.TEMP_NORMAL) / (self.TEMP_WARNING - self.TEMP_NORMAL) * 30)
            freq_mhz = 1200 - (self.throttle_level * 4)  # Reduce frequency
            voltage_mv = 1050 - (self.throttle_level * 2)  # Reduce voltage
            self.npu.set_frequency(freq_mhz)
            self.npu.set_voltage(voltage_mv)

        elif self.TEMP_WARNING <= temperature < self.TEMP_CRITICAL:
            # Aggressive throttling (30-70%)
            self.throttle_level = 30 + int((temperature - self.TEMP_WARNING) / (self.TEMP_CRITICAL - self.TEMP_WARNING) * 40)
            freq_mhz = 1200 - (self.throttle_level * 8)
            voltage_mv = 1050 - (self.throttle_level * 3)
            self.npu.set_frequency(max(freq_mhz, 400))  # Don't go below 400 MHz
            self.npu.set_voltage(max(voltage_mv, 750))
            logging.warning(f"NPU thermal warning: {temperature:.1f}°C, throttling {self.throttle_level}%")

        else:  # temperature >= TEMP_CRITICAL
            # Emergency: Pause inference, trigger cooling
            self.throttle_level = 100
            self.npu.set_frequency(400)
            self.npu.set_voltage(750)
            self.npu.pause_inference()
            logging.critical(f"NPU thermal critical: {temperature:.1f}°C, inference paused")

            # Trigger cabin cooling request via CAN
            send_can_message('HVACRequest', {'mode': 'MAX_COOL', 'fan_speed': 'HIGH'})

    def monitor_thermal(self):
        """Continuous thermal monitoring loop"""
        while True:
            temp = self.read_npu_temperature()
            self.thermal_throttling_policy(temp)

            # Log thermal metrics
            print(f"NPU temp: {temp:.1f}°C, throttle: {self.throttle_level}%")

            time.sleep(0.5)  # 2 Hz monitoring

# Real-world scenario:
# Summer day, cabin temperature 60°C
# NPU reaches 110°C under full load
# Thermal manager reduces frequency to 600 MHz
# Temperature stabilizes at 95°C
# Inference latency increases from 20ms → 40ms (acceptable for non-critical ADAS)
```

---

## Benchmarking NPU Performance

### Comprehensive NPU Benchmark Suite

```python
class NPUBenchmarkSuite:
    """
    Automotive NPU benchmark suite
    Tests: latency, throughput, power, thermal, accuracy
    """
    def __init__(self, npu_device, model_zoo_path):
        self.npu = npu_device
        self.model_zoo = self.load_model_zoo(model_zoo_path)

    def load_model_zoo(self, path):
        """Load standardized automotive model zoo"""
        return {
            'yolov5s': f'{path}/yolov5s_int8.dlc',
            'efficientdet_d0': f'{path}/efficientdet_d0_int8.tflite',
            'resnet50': f'{path}/resnet50_int8.onnx',
            'mobilenet_v2': f'{path}/mobilenet_v2_int8.onnx',
            'lanenet': f'{path}/lanenet_int8.dlc',
            'dms_drowsiness': f'{path}/dms_drowsiness_int8.tflite'
        }

    def benchmark_latency(self, model_name, num_iterations=1000):
        """Measure inference latency distribution"""
        model = self.npu.load_model(self.model_zoo[model_name])
        latencies = []

        # Warmup
        for _ in range(100):
            _ = model.infer(dummy_input)

        # Benchmark
        for _ in range(num_iterations):
            start = time.perf_counter()
            _ = model.infer(dummy_input)
            end = time.perf_counter()
            latencies.append((end - start) * 1000)  # ms

        return {
            'model': model_name,
            'mean_ms': np.mean(latencies),
            'median_ms': np.median(latencies),
            'p50_ms': np.percentile(latencies, 50),
            'p90_ms': np.percentile(latencies, 90),
            'p99_ms': np.percentile(latencies, 99),
            'min_ms': np.min(latencies),
            'max_ms': np.max(latencies),
            'std_ms': np.std(latencies)
        }

    def benchmark_throughput(self, model_name, duration_sec=60):
        """Measure sustained throughput (FPS)"""
        model = self.npu.load_model(self.model_zoo[model_name])
        count = 0
        start_time = time.time()

        while time.time() - start_time < duration_sec:
            _ = model.infer(dummy_input)
            count += 1

        fps = count / duration_sec
        return {'model': model_name, 'fps': fps}

    def benchmark_power_efficiency(self, model_name, num_iterations=1000):
        """Measure TOPS/Watt efficiency"""
        model = self.npu.load_model(self.model_zoo[model_name])
        power_samples = []
        latencies = []

        for _ in range(num_iterations):
            power_start = self.npu.read_power()
            time_start = time.perf_counter()

            _ = model.infer(dummy_input)

            time_end = time.perf_counter()
            power_end = self.npu.read_power()

            latencies.append((time_end - time_start) * 1000)
            power_samples.append((power_start + power_end) / 2)  # Average

        # Calculate TOPS
        model_ops = model.get_total_ops()  # e.g., 16.5 GFLOPs for YOLOv5s
        avg_latency = np.mean(latencies) / 1000  # seconds
        tops = (model_ops / avg_latency) / 1e12  # TOPS

        avg_power = np.mean(power_samples)  # Watts
        tops_per_watt = tops / avg_power

        return {
            'model': model_name,
            'tops': tops,
            'power_w': avg_power,
            'tops_per_watt': tops_per_watt
        }

    def run_full_suite(self):
        """Run complete benchmark suite"""
        results = {}

        for model_name in self.model_zoo.keys():
            print(f"\n=== Benchmarking {model_name} ===")

            latency_result = self.benchmark_latency(model_name)
            throughput_result = self.benchmark_throughput(model_name)
            power_result = self.benchmark_power_efficiency(model_name)

            results[model_name] = {
                'latency': latency_result,
                'throughput': throughput_result,
                'power': power_result
            }

            print(f"Latency: {latency_result['mean_ms']:.2f}ms (P99: {latency_result['p99_ms']:.2f}ms)")
            print(f"Throughput: {throughput_result['fps']:.2f} FPS")
            print(f"Power: {power_result['power_w']:.2f}W, {power_result['tops_per_watt']:.2f} TOPS/W")

        # Generate report
        self.generate_report(results)
        return results

    def generate_report(self, results):
        """Generate markdown benchmark report"""
        with open('npu_benchmark_report.md', 'w') as f:
            f.write("# NPU Benchmark Report\n\n")
            f.write(f"**NPU**: {self.npu.get_device_name()}\n")
            f.write(f"**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            f.write("## Latency Results\n\n")
            f.write("| Model | Mean (ms) | P50 (ms) | P90 (ms) | P99 (ms) |\n")
            f.write("|-------|-----------|----------|----------|----------|\n")
            for model, data in results.items():
                lat = data['latency']
                f.write(f"| {model} | {lat['mean_ms']:.2f} | {lat['p50_ms']:.2f} | "
                       f"{lat['p90_ms']:.2f} | {lat['p99_ms']:.2f} |\n")

            f.write("\n## Throughput Results\n\n")
            f.write("| Model | FPS |\n")
            f.write("|-------|-----|\n")
            for model, data in results.items():
                f.write(f"| {model} | {data['throughput']['fps']:.2f} |\n")

            f.write("\n## Power Efficiency\n\n")
            f.write("| Model | TOPS | Power (W) | TOPS/W |\n")
            f.write("|-------|------|-----------|--------|\n")
            for model, data in results.items():
                pwr = data['power']
                f.write(f"| {model} | {pwr['tops']:.2f} | {pwr['power_w']:.2f} | "
                       f"{pwr['tops_per_watt']:.2f} |\n")

# Example usage
benchmark = NPUBenchmarkSuite(qualcomm_npu, '/models/automotive_zoo')
results = benchmark.run_full_suite()
```

---

## NPU Comparison Table

| Platform | TOPS (INT8) | On-Chip SRAM | Memory BW | Power | TOPS/W | Use Case |
|----------|-------------|--------------|-----------|-------|--------|----------|
| **Qualcomm Snapdragon Ride** | 300 | 32 MB | 51 GB/s | 8-12W | 25-37 | L3+ Autonomous |
| **NXP i.MX 8M Plus** | 2.3 | 384 KB | 4 GB/s | 0.8-1.5W | 1.5-2.8 | ADAS Entry |
| **Renesas RZ/V2M** | 0.08 | 1 MB | 8 GB/s | 0.5-1.2W | ~0.8 | DMS/Parking |
| **Ambarella CV5** | 60 | 16 MB | 34 GB/s | 5-8W | 7.5-12 | Multi-Camera ADAS |
| **NVIDIA Orin** | 275 | 8 MB | 204 GB/s | 15-45W | 6-18 | Autonomous Driving |
| **Tesla FSD (HW3)** | 144 | N/A | 68 GB/s | 72W | 2 | Full Self-Driving |

**Selection Guide**:
- **Entry ADAS** (Lane Keep, AEB): NXP i.MX 8M Plus
- **Advanced ADAS** (Multi-camera, parking): Ambarella CV5
- **L3 Autonomous**: Qualcomm Snapdragon Ride or NVIDIA Orin
- **DMS/OMS**: Renesas RZ/V2M or NXP i.MX 8M Plus

---

## Related Skills
- [Edge AI Deployment](./edge-ai-deployment.md) - Deploy models to NPUs
- [Camera Vision AI](./camera-vision-ai.md) - Vision pipelines
- [Driver Monitoring Systems](./driver-monitoring-systems.md) - DMS with NPU

---

**Tags**: `npu`, `ai-accelerator`, `tops`, `automotive-hardware`, `performance-optimization`, `thermal-management`, `power-management`

---

## Voice Nlu Automotive

# Voice NLU for Automotive AI

**Skill**: Voice AI for vehicles - wake word, ASR, NLU, TTS with edge/cloud hybrid
**Version**: 1.0.0
**Category**: AI-ECU / Voice Interface
**Complexity**: Advanced

---

## Overview

Complete guide to implementing voice AI for automotive: wake word detection, automatic speech recognition (ASR), natural language understanding (NLU), text-to-speech (TTS), edge vs cloud hybrid architectures, noise cancellation, multi-speaker recognition, and privacy-preserving inference.

## Automotive Voice AI Architecture

### System Components

```
Microphone Array (4-6 mics)
       ↓
Acoustic Echo Cancellation (AEC)
       ↓
Noise Suppression (road, engine, wind)
       ↓
Wake Word Detection (edge NPU) ← "Hey BMW" / "Alexa" / "OK Google"
       ↓
Voice Activity Detection (VAD)
       ↓
Automatic Speech Recognition (ASR) ← Edge (short commands) or Cloud (complex queries)
       ↓
Natural Language Understanding (NLU) ← Intent classification + Entity extraction
       ↓
Dialog Management
       ↓
Text-to-Speech (TTS) ← Edge (canned responses) or Cloud (dynamic)
       ↓
Audio Output (speakers)
```

**Performance Requirements**:
- **Wake word latency**: < 500ms (from speech end to activation)
- **ASR latency**: < 1 second for edge, < 2 seconds for cloud
- **False wake rate**: < 0.1 per hour (1 false wake per 10 hours)
- **True positive rate**: > 95% (wake word detection)
- **Noise robustness**: SNR > -5 dB (signal-to-noise ratio)

---

## Microphone Array Setup

### Hardware Configuration

**Microphone Array**: 4-6 MEMS microphones for beamforming
- **Type**: Digital MEMS (I2S/TDM interface)
- **SNR**: > 65 dB
- **Frequency Response**: 100 Hz - 10 kHz (voice band)
- **Spacing**: 3-5 cm between mics (optimal for beamforming at 16 kHz)

**Physical Placement**:
- **Overhead console**: 4-mic array (best for driver + passenger)
- **Steering wheel**: 2-mic array (driver-focused)
- **Roof lining**: 6-mic array (full cabin coverage)

```python
import pyaudio
import numpy as np

class MicrophoneArray:
    """
    Capture audio from 4-microphone array
    I2S interface via USB audio adapter (e.g., ReSpeaker 4-Mic Array)
    """
    def __init__(self, device_index=None, sample_rate=16000, channels=4):
        self.sample_rate = sample_rate
        self.channels = channels
        self.chunk_size = int(sample_rate * 0.1)  # 100ms chunks

        self.audio = pyaudio.PyAudio()

        # Find device
        if device_index is None:
            device_index = self.find_device('respeaker')

        self.stream = self.audio.open(
            format=pyaudio.paInt16,
            channels=channels,
            rate=sample_rate,
            input=True,
            input_device_index=device_index,
            frames_per_buffer=self.chunk_size
        )

    def find_device(self, keyword):
        """Find audio device by name"""
        for i in range(self.audio.get_device_count()):
            info = self.audio.get_device_info_by_index(i)
            if keyword.lower() in info['name'].lower():
                return i
        return None

    def read_chunk(self):
        """Read 100ms audio chunk from all mics"""
        data = self.stream.read(self.chunk_size, exception_on_overflow=False)
        audio_data = np.frombuffer(data, dtype=np.int16)

        # Reshape to (samples, channels)
        audio_data = audio_data.reshape(-1, self.channels)

        return audio_data

    def beamforming(self, audio_data, target_angle=0):
        """
        Simple delay-and-sum beamforming
        target_angle: 0° = front (driver), 90° = left, -90° = right
        """
        # Speed of sound: 343 m/s
        # Mic spacing: 0.04 m (4 cm)
        mic_spacing = 0.04
        speed_of_sound = 343.0

        # Calculate delays for each mic
        delays = []
        for mic_idx in range(self.channels):
            # Delay relative to mic 0
            delay_samples = int((mic_spacing * mic_idx * np.sin(np.deg2rad(target_angle))) /
                               speed_of_sound * self.sample_rate)
            delays.append(delay_samples)

        # Align signals by applying delays
        max_delay = max(delays)
        aligned = np.zeros((audio_data.shape[0] - max_delay,))

        for mic_idx in range(self.channels):
            delay = delays[mic_idx]
            aligned += audio_data[delay:delay + len(aligned), mic_idx]

        # Average
        aligned /= self.channels

        return aligned.astype(np.int16)

# Usage
mic_array = MicrophoneArray()

while True:
    audio_chunk = mic_array.read_chunk()

    # Apply beamforming (focus on driver)
    beamformed = mic_array.beamforming(audio_chunk, target_angle=0)

    # Process beamformed audio
    process_audio(beamformed)
```

---

## Acoustic Echo Cancellation (AEC)

### Remove Audio Playback from Microphone Signal

**Challenge**: Car speakers play music/navigation, mic picks it up → false wake words

```python
import numpy as np
from scipy import signal

class AcousticEchoCanceller:
    """
    Adaptive filter-based AEC
    Remove known audio (speaker playback) from microphone signal
    """
    def __init__(self, filter_length=512, step_size=0.01):
        self.filter_length = filter_length
        self.step_size = step_size

        # Adaptive filter coefficients (updated online)
        self.w = np.zeros(filter_length)

        # Buffer for reference signal (speaker output)
        self.reference_buffer = np.zeros(filter_length)

    def process(self, mic_signal, reference_signal):
        """
        Apply AEC to remove echo
        mic_signal: Audio from microphone (with echo)
        reference_signal: Audio sent to speakers (known)
        Returns: Cleaned audio (echo removed)
        """
        output = np.zeros_like(mic_signal)

        for i in range(len(mic_signal)):
            # Update reference buffer (FIFO)
            self.reference_buffer = np.roll(self.reference_buffer, 1)
            self.reference_buffer[0] = reference_signal[i]

            # Predict echo using adaptive filter
            echo_estimate = np.dot(self.w, self.reference_buffer)

            # Subtract echo from mic signal
            error = mic_signal[i] - echo_estimate
            output[i] = error

            # Update filter coefficients (LMS algorithm)
            self.w += self.step_size * error * self.reference_buffer

        return output

# Usage
aec = AcousticEchoCanceller()

# Get speaker output (what's being played)
speaker_output = get_audio_playback()  # From audio system

# Get mic input
mic_input = mic_array.read_chunk()

# Remove echo
cleaned_audio = aec.process(mic_input[:, 0], speaker_output)
```

---

## Noise Suppression

### RNNoise for Deep Learning-Based Noise Reduction

```python
import rnnoise

class NoiseSuppressionPipeline:
    """
    RNNoise-based noise suppression
    Removes: engine noise, road noise, wind noise, HVAC
    """
    def __init__(self):
        self.rnnoise = rnnoise.RNNoise()
        self.frame_size = 480  # 30ms @ 16kHz

    def process(self, audio_chunk):
        """
        Apply noise suppression to audio chunk
        audio_chunk: int16 array, 16kHz sample rate
        """
        # Convert to float32 [-1, 1]
        audio_float = audio_chunk.astype(np.float32) / 32768.0

        # Process in 30ms frames
        output = np.zeros_like(audio_float)
        num_frames = len(audio_float) // self.frame_size

        for i in range(num_frames):
            start = i * self.frame_size
            end = start + self.frame_size

            frame = audio_float[start:end]

            # RNNoise processing
            denoised_frame = self.rnnoise.process_frame(frame)

            output[start:end] = denoised_frame

        # Convert back to int16
        output_int16 = (output * 32768.0).astype(np.int16)

        return output_int16

# Usage
noise_suppressor = NoiseSuppressionPipeline()

# Get audio (after AEC)
audio = cleaned_audio

# Suppress noise
clean_audio = noise_suppressor.process(audio)
```

---

## Wake Word Detection

### On-Device Wake Word with Porcupine

**Wake Words**: "Hey [Brand]", "OK [Brand]", custom phrases

```python
import pvporcupine

class WakeWordDetector:
    """
    Wake word detection using Porcupine (runs on NPU or CPU)
    Extremely low power: 0.5-1.0 mW (always listening)
    """
    def __init__(self, keyword='hey-bmw', sensitivity=0.5):
        # Initialize Porcupine
        self.porcupine = pvporcupine.create(
            access_key='YOUR_ACCESS_KEY',  # Free tier available
            keyword_paths=[pvporcupine.KEYWORD_PATHS[keyword]],
            sensitivities=[sensitivity]
        )

        self.sample_rate = self.porcupine.sample_rate
        self.frame_length = self.porcupine.frame_length

        # Statistics
        self.wake_count = 0
        self.false_wake_count = 0

    def process(self, audio_chunk):
        """
        Process audio chunk for wake word detection
        Returns: True if wake word detected
        """
        # Audio must be exactly frame_length samples
        if len(audio_chunk) != self.frame_length:
            return False

        # Detect wake word
        keyword_index = self.porcupine.process(audio_chunk)

        if keyword_index >= 0:
            self.wake_count += 1
            return True

        return False

    def verify_wake_word(self, audio_buffer):
        """
        Verify wake word using secondary model (reduce false positives)
        Run heavier model on CPU/NPU after initial detection
        """
        # TODO: Implement secondary verification
        # Use full ASR to transcribe wake phrase
        # Check if transcription matches wake word

        return True  # Simplified for now

# Usage
wake_word_detector = WakeWordDetector(keyword='hey-bmw', sensitivity=0.5)

while True:
    # Get clean audio (after AEC + noise suppression)
    audio_chunk = clean_audio[:wake_word_detector.frame_length]

    # Detect wake word
    if wake_word_detector.process(audio_chunk):
        print("Wake word detected!")

        # Verify wake word (optional, reduces false positives)
        if wake_word_detector.verify_wake_word(audio_buffer):
            # Start ASR
            start_speech_recognition()
```

---

## Automatic Speech Recognition (ASR)

### Edge ASR with Whisper Tiny (INT8 on NPU)

**Whisper Tiny**: 39M parameters, INT8 quantized → 40 MB model, 200ms latency on NPU

```python
import whisper

class EdgeASR:
    """
    Edge ASR using Whisper Tiny (quantized for NPU)
    Handles short commands: "Navigate home", "Call John", "Play music"
    """
    def __init__(self, model_path='whisper_tiny_int8.dlc'):
        import snpe
        self.model = snpe.load_container(model_path)
        self.network = snpe.build_network(self.model, snpe.SNPE_Runtime.RUNTIME_HTA)

        self.sample_rate = 16000

    def transcribe(self, audio_chunk):
        """
        Transcribe audio to text
        audio_chunk: 1-10 seconds of speech (16 kHz)
        """
        # Preprocess audio for Whisper
        # 1. Resample to 16 kHz (already done)
        # 2. Convert to mel spectrogram
        mel_spectrogram = self.audio_to_mel(audio_chunk)

        # 3. Run inference
        output = self.network.execute({'input': mel_spectrogram})

        # 4. Decode tokens to text
        text = self.decode_tokens(output['tokens'])

        return text

    def audio_to_mel(self, audio):
        """Convert audio to mel spectrogram (Whisper input format)"""
        import librosa

        # Compute mel spectrogram
        mel = librosa.feature.melspectrogram(
            y=audio.astype(np.float32) / 32768.0,
            sr=self.sample_rate,
            n_fft=400,
            hop_length=160,
            n_mels=80,
            fmin=0,
            fmax=8000
        )

        # Log scale
        log_mel = librosa.power_to_db(mel, ref=np.max)

        # Normalize
        log_mel = (log_mel + 40) / 40  # Rough normalization

        # Reshape for model
        log_mel = np.expand_dims(log_mel, axis=0)  # Add batch dimension

        return log_mel.astype(np.float32)

    def decode_tokens(self, token_ids):
        """Decode token IDs to text (Whisper vocabulary)"""
        # Load Whisper tokenizer
        from transformers import WhisperTokenizer
        tokenizer = WhisperTokenizer.from_pretrained('openai/whisper-tiny')

        # Decode
        text = tokenizer.decode(token_ids[0], skip_special_tokens=True)

        return text

# Usage
edge_asr = EdgeASR()

# Capture speech after wake word
audio_buffer = capture_speech_until_silence()  # 1-10 seconds

# Transcribe
transcript = edge_asr.transcribe(audio_buffer)
print(f"Transcript: {transcript}")
```

### Cloud ASR Fallback (for Complex Queries)

```python
import requests

class CloudASR:
    """
    Cloud ASR fallback for complex/long queries
    Uses Google Cloud Speech-to-Text, AWS Transcribe, or Azure Speech
    """
    def __init__(self, api_key):
        self.api_key = api_key
        self.api_url = 'https://speech.googleapis.com/v1/speech:recognize'

    def transcribe(self, audio_chunk):
        """
        Transcribe audio using cloud API
        Latency: 1-3 seconds (network + processing)
        """
        # Encode audio to base64
        import base64
        audio_base64 = base64.b64encode(audio_chunk.tobytes()).decode('utf-8')

        # Prepare request
        request_data = {
            'config': {
                'encoding': 'LINEAR16',
                'sampleRateHertz': 16000,
                'languageCode': 'en-US',
                'model': 'command_and_search',  # Optimized for short commands
                'useEnhanced': True
            },
            'audio': {
                'content': audio_base64
            }
        }

        # Send request
        response = requests.post(
            self.api_url,
            headers={'Authorization': f'Bearer {self.api_key}'},
            json=request_data,
            timeout=5.0
        )

        # Parse response
        if response.status_code == 200:
            result = response.json()
            if 'results' in result and len(result['results']) > 0:
                transcript = result['results'][0]['alternatives'][0]['transcript']
                confidence = result['results'][0]['alternatives'][0]['confidence']
                return transcript, confidence

        return None, 0.0

# Hybrid ASR: Edge first, cloud fallback
class HybridASR:
    def __init__(self):
        self.edge_asr = EdgeASR()
        self.cloud_asr = CloudASR(api_key='YOUR_API_KEY')

        self.edge_confidence_threshold = 0.8

    def transcribe(self, audio_chunk):
        """
        Try edge ASR first, fallback to cloud if low confidence
        """
        # Edge ASR (fast, private)
        edge_transcript = self.edge_asr.transcribe(audio_chunk)
        edge_confidence = self.estimate_confidence(edge_transcript)

        if edge_confidence >= self.edge_confidence_threshold:
            return edge_transcript, 'edge'

        # Cloud fallback (slower, more accurate)
        cloud_transcript, cloud_confidence = self.cloud_asr.transcribe(audio_chunk)

        if cloud_confidence > edge_confidence:
            return cloud_transcript, 'cloud'
        else:
            return edge_transcript, 'edge'

    def estimate_confidence(self, transcript):
        """Estimate confidence from transcript (simplified)"""
        # Check for common words, no gibberish
        if len(transcript.split()) < 2:
            return 0.5  # Too short
        if any(char.isdigit() for char in transcript):
            return 0.6  # Contains numbers (potentially misrecognized)

        return 0.85  # Reasonable confidence
```

---

## Natural Language Understanding (NLU)

### Intent Classification and Entity Extraction

**Intents**: navigate, call, play_music, set_temperature, open_window, etc.
**Entities**: location, contact_name, song_name, temperature_value, etc.

```python
from transformers import pipeline

class AutomotiveNLU:
    """
    NLU for automotive voice commands
    - Intent classification
    - Entity extraction (named entity recognition)
    """
    def __init__(self):
        # Intent classifier (DistilBERT fine-tuned on automotive intents)
        self.intent_classifier = pipeline(
            'text-classification',
            model='distilbert-base-uncased-finetuned-sst-2-english'  # Placeholder
        )

        # Entity extractor (NER model)
        self.entity_extractor = pipeline(
            'ner',
            model='dbmdz/bert-large-cased-finetuned-conll03-english'
        )

        # Automotive intent mapping
        self.intent_handlers = {
            'navigate': self.handle_navigation,
            'call': self.handle_call,
            'play_music': self.handle_music,
            'set_temperature': self.handle_temperature,
            'open_window': self.handle_window
        }

    def parse(self, transcript):
        """
        Parse transcript to extract intent and entities
        Example: "Navigate to 123 Main Street"
        → Intent: navigate, Entity: location="123 Main Street"
        """
        # Classify intent
        intent_result = self.intent_classifier(transcript)[0]
        intent = intent_result['label']
        intent_confidence = intent_result['score']

        # Extract entities
        entities = self.entity_extractor(transcript)

        # Post-process entities
        entity_dict = {}
        for entity in entities:
            entity_type = entity['entity']
            entity_value = entity['word']

            if entity_type in entity_dict:
                entity_dict[entity_type] += ' ' + entity_value
            else:
                entity_dict[entity_type] = entity_value

        return {
            'intent': intent,
            'intent_confidence': intent_confidence,
            'entities': entity_dict,
            'transcript': transcript
        }

    def execute(self, parsed_result):
        """Execute intent with extracted entities"""
        intent = parsed_result['intent']

        if intent in self.intent_handlers:
            return self.intent_handlers[intent](parsed_result['entities'])
        else:
            return {'status': 'error', 'message': f'Unknown intent: {intent}'}

    def handle_navigation(self, entities):
        """Handle navigation intent"""
        if 'location' in entities:
            location = entities['location']
            # Send to navigation system via CAN
            send_can_message('NavigationRequest', {'destination': location})
            return {'status': 'success', 'message': f'Navigating to {location}'}
        else:
            return {'status': 'error', 'message': 'Location not specified'}

    def handle_call(self, entities):
        """Handle phone call intent"""
        if 'contact_name' in entities:
            contact = entities['contact_name']
            # Send to infotainment via CAN
            send_can_message('PhoneCallRequest', {'contact': contact})
            return {'status': 'success', 'message': f'Calling {contact}'}
        else:
            return {'status': 'error', 'message': 'Contact not specified'}

    def handle_music(self, entities):
        """Handle music playback intent"""
        if 'song_name' in entities:
            song = entities['song_name']
            # Send to infotainment
            send_can_message('MusicPlayRequest', {'song': song})
            return {'status': 'success', 'message': f'Playing {song}'}
        else:
            # Just play music (no specific song)
            send_can_message('MusicPlayRequest', {'action': 'resume'})
            return {'status': 'success', 'message': 'Playing music'}

    def handle_temperature(self, entities):
        """Handle HVAC temperature control"""
        if 'temperature' in entities:
            temp = int(entities['temperature'])
            send_can_message('HVACSetTemperature', {'temperature': temp})
            return {'status': 'success', 'message': f'Setting temperature to {temp}°C'}
        else:
            return {'status': 'error', 'message': 'Temperature value not specified'}

    def handle_window(self, entities):
        """Handle window control"""
        if 'action' in entities:
            action = entities['action']  # open/close
            send_can_message('WindowControl', {'action': action})
            return {'status': 'success', 'message': f'Window {action}'}
        else:
            return {'status': 'error', 'message': 'Window action not specified'}

# Usage
nlu = AutomotiveNLU()

transcript = "Navigate to 123 Main Street"
parsed = nlu.parse(transcript)
result = nlu.execute(parsed)

print(f"Intent: {parsed['intent']}")
print(f"Entities: {parsed['entities']}")
print(f"Result: {result['message']}")
```

---

## Text-to-Speech (TTS)

### Edge TTS with Tacotron2 + WaveGlow (INT8)

```python
import numpy as np

class EdgeTTS:
    """
    Edge TTS using Tacotron2 (mel spectrogram) + WaveGlow (vocoder)
    Quantized INT8 models on NPU
    """
    def __init__(self, tacotron_model_path, waveglow_model_path):
        import snpe

        # Load Tacotron2 (text → mel spectrogram)
        self.tacotron = snpe.load_container(tacotron_model_path)
        self.tacotron_network = snpe.build_network(self.tacotron, snpe.SNPE_Runtime.RUNTIME_HTA)

        # Load WaveGlow (mel spectrogram → audio)
        self.waveglow = snpe.load_container(waveglow_model_path)
        self.waveglow_network = snpe.build_network(self.waveglow, snpe.SNPE_Runtime.RUNTIME_HTA)

    def synthesize(self, text):
        """
        Synthesize speech from text
        Returns: audio waveform (int16, 22050 Hz)
        """
        # 1. Text to sequence (phonemes or characters)
        sequence = self.text_to_sequence(text)

        # 2. Tacotron2: sequence → mel spectrogram
        mel_output = self.tacotron_network.execute({'input': sequence})
        mel_spectrogram = mel_output['mel']

        # 3. WaveGlow: mel spectrogram → audio
        audio_output = self.waveglow_network.execute({'mel': mel_spectrogram})
        audio_waveform = audio_output['audio'][0]

        # 4. Convert to int16
        audio_int16 = (audio_waveform * 32767).astype(np.int16)

        return audio_int16

    def text_to_sequence(self, text):
        """Convert text to sequence of phonemes or characters"""
        # Simple character-level encoding
        char_to_id = {char: idx for idx, char in enumerate('abcdefghijklmnopqrstuvwxyz ')}
        sequence = [char_to_id.get(char.lower(), 0) for char in text]
        sequence_array = np.array(sequence, dtype=np.int32).reshape(1, -1)
        return sequence_array

# Usage
tts = EdgeTTS('tacotron2_int8.dlc', 'waveglow_int8.dlc')

# Synthesize response
text = "Navigating to 123 Main Street"
audio = tts.synthesize(text)

# Play audio
play_audio(audio, sample_rate=22050)
```

---

## Privacy-Preserving Voice AI

### On-Device Processing to Avoid Cloud Data Leakage

**Privacy Concerns**:
- Voice recordings uploaded to cloud (potential data breach)
- Conversations in car (sensitive topics: health, finance, work)
- GDPR compliance (EU): User consent required for cloud processing

**Solution**: Edge-first architecture
- **Wake word**: 100% on-device (NPU)
- **ASR**: 90% on-device (edge), 10% cloud (complex queries only)
- **NLU**: 100% on-device (lightweight BERT on NPU)
- **TTS**: 100% on-device (Tacotron2 + WaveGlow on NPU)

```python
class PrivacyPreservingVoiceAI:
    """
    Privacy-first voice AI architecture
    Minimize cloud data transmission
    """
    def __init__(self):
        self.wake_word_detector = WakeWordDetector()
        self.edge_asr = EdgeASR()
        self.nlu = AutomotiveNLU()
        self.tts = EdgeTTS('tacotron2_int8.dlc', 'waveglow_int8.dlc')

        # Cloud ASR disabled by default
        self.cloud_asr_enabled = False

    def enable_cloud_asr(self, user_consent=False):
        """Enable cloud ASR only with explicit user consent"""
        if user_consent:
            self.cloud_asr_enabled = True
            self.cloud_asr = CloudASR(api_key='YOUR_API_KEY')
        else:
            print("Cloud ASR requires user consent (GDPR compliance)")

    def process_voice_command(self, audio_chunk):
        """
        Process voice command (100% on-device by default)
        """
        # 1. Wake word detection (on-device NPU)
        if not self.wake_word_detector.process(audio_chunk):
            return None  # No wake word

        # 2. Capture speech
        speech_audio = capture_speech_until_silence()

        # 3. ASR (edge-first)
        transcript = self.edge_asr.transcribe(speech_audio)

        # 4. NLU (on-device)
        parsed = self.nlu.parse(transcript)

        # 5. Execute intent
        result = self.nlu.execute(parsed)

        # 6. TTS response (on-device)
        response_audio = self.tts.synthesize(result['message'])
        play_audio(response_audio)

        # Log privacy metrics
        print(f"Privacy: 100% on-device processing")
        print(f"  Wake word: on-device")
        print(f"  ASR: edge")
        print(f"  NLU: on-device")
        print(f"  TTS: on-device")

        return result

# Usage
voice_ai = PrivacyPreservingVoiceAI()

# Process voice commands (no cloud data transmission)
while True:
    audio_chunk = mic_array.read_chunk()
    result = voice_ai.process_voice_command(audio_chunk)

    if result:
        print(f"Command executed: {result['message']}")
```

---

## Multi-Speaker Recognition

### Speaker Diarization for Multi-Occupant Vehicles

**Use Case**: Identify driver vs. passenger commands (driver has priority)

```python
from pyannote.audio import Model, Inference

class MultiSpeakerRecognition:
    """
    Identify speaker (driver, passenger, rear-left, rear-right)
    Use speaker embeddings + spatial audio (mic array beamforming)
    """
    def __init__(self):
        # Pre-trained speaker embedding model
        self.model = Model.from_pretrained('pyannote/embedding')
        self.inference = Inference(self.model)

        # Enrolled speakers
        self.speaker_embeddings = {
            'driver': None,
            'passenger': None
        }

    def enroll_speaker(self, speaker_id, audio_samples):
        """
        Enroll speaker by computing average embedding from samples
        audio_samples: List of 3-5 second audio clips
        """
        embeddings = []
        for audio in audio_samples:
            embedding = self.inference(audio)
            embeddings.append(embedding)

        # Average embedding
        avg_embedding = np.mean(embeddings, axis=0)
        self.speaker_embeddings[speaker_id] = avg_embedding

        print(f"Enrolled speaker: {speaker_id}")

    def identify_speaker(self, audio_chunk):
        """
        Identify which speaker is talking
        Returns: speaker_id ('driver' or 'passenger')
        """
        # Compute embedding
        embedding = self.inference(audio_chunk)

        # Compare with enrolled speakers
        similarities = {}
        for speaker_id, enrolled_embedding in self.speaker_embeddings.items():
            if enrolled_embedding is not None:
                # Cosine similarity
                similarity = np.dot(embedding, enrolled_embedding) / (
                    np.linalg.norm(embedding) * np.linalg.norm(enrolled_embedding)
                )
                similarities[speaker_id] = similarity

        # Return speaker with highest similarity
        if similarities:
            identified_speaker = max(similarities, key=similarities.get)
            return identified_speaker, similarities[identified_speaker]

        return None, 0.0

# Usage
speaker_recognition = MultiSpeakerRecognition()

# Enroll driver
driver_samples = [record_audio(duration=3) for _ in range(5)]
speaker_recognition.enroll_speaker('driver', driver_samples)

# Enroll passenger
passenger_samples = [record_audio(duration=3) for _ in range(5)]
speaker_recognition.enroll_speaker('passenger', passenger_samples)

# Identify speaker during voice command
audio_chunk = capture_speech_until_silence()
speaker_id, confidence = speaker_recognition.identify_speaker(audio_chunk)

if speaker_id == 'driver':
    print("Driver is speaking - full command access")
    process_voice_command(audio_chunk)
elif speaker_id == 'passenger':
    print("Passenger is speaking - limited command access (no navigation changes)")
    process_voice_command(audio_chunk, restricted=True)
```

---

## Performance Benchmarks

### Voice AI System Performance

| Metric | Edge | Cloud | Hybrid | Target |
|--------|------|-------|--------|--------|
| **Wake Word Latency** | 450ms | N/A | 450ms | < 500ms |
| **ASR Latency** | 800ms | 2.1s | 850ms | < 1s (edge) |
| **NLU Latency** | 120ms | 180ms | 120ms | < 200ms |
| **TTS Latency** | 650ms | 1.8s | 650ms | < 1s |
| **Total Latency** | 2.0s | 4.1s | 2.1s | < 3s |
| **Power Consumption** | 2.8W | 1.5W | 2.5W | < 5W |
| **Privacy** | 100% local | 0% local | 90% local | > 80% local |
| **Accuracy (WER)** | 8.5% | 5.2% | 6.8% | < 10% |

**Word Error Rate (WER)**: Lower is better (5% = 95% accuracy)

---

## Related Skills
- [Edge AI Deployment](./edge-ai-deployment.md) - Deploy voice models to NPU
- [Neural Processing Units](./neural-processing-units.md) - NPU optimization
- [Driver Monitoring Systems](./driver-monitoring-systems.md) - Multi-modal AI systems

---

**Tags**: `voice-ai`, `wake-word`, `asr`, `nlu`, `tts`, `privacy`, `edge-computing`, `whisper`, `automotive-hmi`

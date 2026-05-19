"""
Camera Object Detection using YOLO v8
Author: Automotive Agents Team
Date: 2026-03-19
"""

import cv2
import numpy as np
from typing import List, Dict, Optional
from pathlib import Path


class CameraDetector:
    """
    Camera-based object detection using YOLO v8.
    """

    # COCO class names relevant for ADAS
    ADAS_CLASSES = {
        0: 'person',
        1: 'bicycle',
        2: 'car',
        3: 'motorcycle',
        5: 'bus',
        7: 'truck',
        9: 'traffic_light',
        11: 'stop_sign'
    }

    def __init__(
        self,
        model_path: str,
        confidence_threshold: float = 0.5,
        nms_threshold: float = 0.4,
        input_size: tuple = (640, 640),
        device: str = 'cuda'
    ):
        """
        Initialize camera detector.

        Args:
            model_path: Path to YOLO model weights
            confidence_threshold: Minimum confidence for detections
            nms_threshold: NMS IoU threshold
            input_size: Model input size (width, height)
            device: 'cuda' or 'cpu'
        """
        self.model_path = model_path
        self.confidence_threshold = confidence_threshold
        self.nms_threshold = nms_threshold
        self.input_size = input_size
        self.device = device

        print(f"[CameraDetector] Initializing YOLO detector...")
        self._load_model()

    def _load_model(self):
        """Load YOLO model."""
        try:
            from ultralytics import YOLO
            self.model = YOLO(self.model_path)
            self.model.to(self.device)
            print(f"[CameraDetector] Model loaded successfully from {self.model_path}")
        except ImportError:
            print("[CameraDetector] WARNING: ultralytics not installed. Using dummy detector.")
            self.model = None
        except Exception as e:
            print(f"[CameraDetector] WARNING: Failed to load model: {e}")
            self.model = None

    def detect(
        self,
        image: np.ndarray,
        return_crops: bool = False
    ) -> List[Dict]:
        """
        Detect objects in image.

        Args:
            image: Input image (H, W, 3) BGR format
            return_crops: Whether to return cropped detections

        Returns:
            List of detections, each containing:
                - bbox: [x1, y1, x2, y2] in pixel coordinates
                - class: Object class name
                - class_id: Object class ID
                - confidence: Detection confidence (0-1)
                - bbox_norm: Normalized bbox [x1, y1, x2, y2] (0-1)
                - crop: Cropped image (if return_crops=True)
        """
        if self.model is None:
            # Return dummy detections for testing
            return self._dummy_detections(image)

        # Run inference
        results = self.model.predict(
            image,
            conf=self.confidence_threshold,
            iou=self.nms_threshold,
            imgsz=self.input_size,
            verbose=False
        )

        # Parse results
        detections = []
        h, w = image.shape[:2]

        for result in results:
            boxes = result.boxes

            for i in range(len(boxes)):
                # Get box coordinates
                xyxy = boxes.xyxy[i].cpu().numpy()
                x1, y1, x2, y2 = xyxy

                # Get class and confidence
                class_id = int(boxes.cls[i].cpu().numpy())
                confidence = float(boxes.conf[i].cpu().numpy())

                # Filter for ADAS-relevant classes
                if class_id not in self.ADAS_CLASSES:
                    continue

                class_name = self.ADAS_CLASSES[class_id]

                # Create detection dictionary
                detection = {
                    'bbox': [float(x1), float(y1), float(x2), float(y2)],
                    'bbox_norm': [x1/w, y1/h, x2/w, y2/h],
                    'class': class_name,
                    'class_id': class_id,
                    'confidence': confidence
                }

                # Add crop if requested
                if return_crops:
                    x1_int, y1_int = int(x1), int(y1)
                    x2_int, y2_int = int(x2), int(y2)
                    crop = image[y1_int:y2_int, x1_int:x2_int]
                    detection['crop'] = crop

                detections.append(detection)

        return detections

    def _dummy_detections(self, image: np.ndarray) -> List[Dict]:
        """
        Generate dummy detections for testing without model.
        """
        h, w = image.shape[:2]

        return [
            {
                'bbox': [w*0.3, h*0.4, w*0.5, h*0.8],
                'bbox_norm': [0.3, 0.4, 0.5, 0.8],
                'class': 'car',
                'class_id': 2,
                'confidence': 0.85
            },
            {
                'bbox': [w*0.6, h*0.5, w*0.75, h*0.9],
                'bbox_norm': [0.6, 0.5, 0.75, 0.9],
                'class': 'person',
                'class_id': 0,
                'confidence': 0.75
            }
        ]

    def preprocess_image(
        self,
        image: np.ndarray,
        enhancement: Optional[str] = None
    ) -> np.ndarray:
        """
        Preprocess image before detection.

        Args:
            image: Input image
            enhancement: Enhancement method ('clahe', 'gamma', None)

        Returns:
            Preprocessed image
        """
        if enhancement == 'clahe':
            # CLAHE for low-light enhancement
            lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            lab[:, :, 0] = clahe.apply(lab[:, :, 0])
            return cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)

        elif enhancement == 'gamma':
            # Gamma correction
            gamma = 1.5
            inv_gamma = 1.0 / gamma
            table = np.array([((i / 255.0) ** inv_gamma) * 255
                            for i in np.arange(0, 256)]).astype("uint8")
            return cv2.LUT(image, table)

        return image

    def get_detection_statistics(self, detections: List[Dict]) -> Dict:
        """
        Get statistics about detections.

        Args:
            detections: List of detections

        Returns:
            Dictionary with statistics
        """
        if not detections:
            return {
                'total_count': 0,
                'class_counts': {},
                'avg_confidence': 0.0
            }

        class_counts = {}
        confidences = []

        for det in detections:
            class_name = det['class']
            class_counts[class_name] = class_counts.get(class_name, 0) + 1
            confidences.append(det['confidence'])

        return {
            'total_count': len(detections),
            'class_counts': class_counts,
            'avg_confidence': np.mean(confidences),
            'min_confidence': np.min(confidences),
            'max_confidence': np.max(confidences)
        }

    def visualize_detections(
        self,
        image: np.ndarray,
        detections: List[Dict],
        show_confidence: bool = True
    ) -> np.ndarray:
        """
        Visualize detections on image.

        Args:
            image: Input image
            detections: List of detections
            show_confidence: Whether to show confidence scores

        Returns:
            Image with visualized detections
        """
        vis_image = image.copy()

        # Color map for classes
        color_map = {
            'car': (0, 255, 0),
            'truck': (0, 255, 255),
            'bus': (0, 128, 255),
            'person': (255, 0, 0),
            'bicycle': (255, 255, 0),
            'motorcycle': (255, 128, 0),
            'traffic_light': (0, 0, 255),
            'stop_sign': (128, 0, 255)
        }

        for det in detections:
            x1, y1, x2, y2 = map(int, det['bbox'])
            class_name = det['class']
            confidence = det['confidence']

            # Get color
            color = color_map.get(class_name, (255, 255, 255))

            # Draw bounding box
            cv2.rectangle(vis_image, (x1, y1), (x2, y2), color, 2)

            # Draw label
            if show_confidence:
                label = f"{class_name} {confidence:.2f}"
            else:
                label = class_name

            # Draw label background
            (text_w, text_h), _ = cv2.getTextSize(
                label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1
            )
            cv2.rectangle(
                vis_image,
                (x1, y1 - text_h - 10),
                (x1 + text_w, y1),
                color,
                -1
            )

            # Draw label text
            cv2.putText(
                vis_image,
                label,
                (x1, y1 - 5),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                (0, 0, 0),
                1
            )

        return vis_image


if __name__ == '__main__':
    # Test detector
    detector = CameraDetector(
        model_path='models/yolov8n.pt',
        confidence_threshold=0.5
    )

    # Load test image
    image = cv2.imread('test_image.jpg')
    if image is None:
        # Create dummy image
        image = np.random.randint(0, 255, (720, 1280, 3), dtype=np.uint8)

    # Detect objects
    detections = detector.detect(image)

    print(f"Detected {len(detections)} objects:")
    for det in detections:
        print(f"  - {det['class']}: {det['confidence']:.2f}")

    # Visualize
    vis_image = detector.visualize_detections(image, detections)
    cv2.imwrite('detection_result.jpg', vis_image)
    print("Visualization saved to detection_result.jpg")

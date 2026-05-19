#!/usr/bin/env python3
"""
ADAS Perception Pipeline - Main Entry Point
Author: Automotive Agents Team
Date: 2026-03-19

Complete perception pipeline integrating camera and LiDAR sensors.
"""

import argparse
import time
import yaml
import cv2
import numpy as np
from pathlib import Path
from typing import Dict, List, Optional

from camera.detector import CameraDetector
from lidar.segmentation import LidarSegmentor
from fusion.late_fusion import LateFusion
from tracking.track_manager import TrackManager


class PerceptionPipeline:
    """
    Main perception pipeline orchestrating all components.
    """

    def __init__(self, config_path: str):
        """
        Initialize perception pipeline.

        Args:
            config_path: Path to configuration YAML file
        """
        # Load configuration
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)

        print("[Pipeline] Initializing perception pipeline...")

        # Initialize components
        self.camera_detector = CameraDetector(
            model_path=self.config['camera']['model_path'],
            confidence_threshold=self.config['camera']['confidence_threshold']
        )

        self.lidar_segmentor = LidarSegmentor(
            model_path=self.config['lidar']['model_path'],
            point_cloud_range=self.config['lidar']['point_cloud_range']
        )

        self.sensor_fusion = LateFusion(
            config=self.config['fusion']
        )

        self.tracker = TrackManager(
            max_age=self.config['tracking']['max_age'],
            min_hits=self.config['tracking']['min_hits']
        )

        self.frame_count = 0
        self.total_latency = 0.0

        print("[Pipeline] Initialization complete")

    def process_frame(
        self,
        camera_image: np.ndarray,
        lidar_points: np.ndarray,
        transform_matrix: Optional[np.ndarray] = None
    ) -> Dict:
        """
        Process a single frame from camera and LiDAR.

        Args:
            camera_image: RGB image (H, W, 3)
            lidar_points: Point cloud (N, 4) [x, y, z, intensity]
            transform_matrix: LiDAR-to-camera transformation (4x4)

        Returns:
            Dictionary containing:
                - tracked_objects: List of tracked objects
                - camera_detections: Raw camera detections
                - lidar_detections: Raw LiDAR detections
                - latency_ms: Processing time
        """
        start_time = time.time()

        # Step 1: Camera Detection
        t0 = time.time()
        camera_detections = self.camera_detector.detect(camera_image)
        camera_latency = (time.time() - t0) * 1000

        # Step 2: LiDAR Segmentation
        t0 = time.time()
        lidar_detections = self.lidar_segmentor.segment(lidar_points)
        lidar_latency = (time.time() - t0) * 1000

        # Step 3: Sensor Fusion
        t0 = time.time()
        fused_objects = self.sensor_fusion.fuse(
            camera_detections,
            lidar_detections,
            transform_matrix
        )
        fusion_latency = (time.time() - t0) * 1000

        # Step 4: Multi-Object Tracking
        t0 = time.time()
        tracked_objects = self.tracker.update(fused_objects)
        tracking_latency = (time.time() - t0) * 1000

        # Calculate total latency
        total_latency = (time.time() - start_time) * 1000

        self.frame_count += 1
        self.total_latency += total_latency

        # Log performance
        if self.frame_count % 10 == 0:
            avg_latency = self.total_latency / self.frame_count
            fps = 1000.0 / avg_latency if avg_latency > 0 else 0
            print(f"[Pipeline] Frame {self.frame_count}: "
                  f"Camera: {camera_latency:.1f}ms, "
                  f"LiDAR: {lidar_latency:.1f}ms, "
                  f"Fusion: {fusion_latency:.1f}ms, "
                  f"Tracking: {tracking_latency:.1f}ms, "
                  f"Total: {total_latency:.1f}ms ({fps:.1f} FPS)")

        return {
            'tracked_objects': tracked_objects,
            'camera_detections': camera_detections,
            'lidar_detections': lidar_detections,
            'latency_ms': total_latency,
            'fps': 1000.0 / total_latency if total_latency > 0 else 0
        }

    def process_video(
        self,
        video_path: str,
        lidar_path: Optional[str] = None,
        output_path: Optional[str] = None
    ) -> None:
        """
        Process video file with optional LiDAR data.

        Args:
            video_path: Path to input video
            lidar_path: Path to LiDAR data directory (optional)
            output_path: Path to save results (optional)
        """
        print(f"[Pipeline] Processing video: {video_path}")

        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Cannot open video: {video_path}")

        frame_idx = 0
        results = []

        while True:
            ret, frame = cap.read()
            if not ret:
                break

            # Load LiDAR data if available
            lidar_points = None
            if lidar_path:
                lidar_file = Path(lidar_path) / f"frame_{frame_idx:06d}.npy"
                if lidar_file.exists():
                    lidar_points = np.load(lidar_file)
                else:
                    # Generate dummy LiDAR if not available
                    lidar_points = self._generate_dummy_lidar()

            # Process frame
            result = self.process_frame(frame, lidar_points)
            results.append(result)

            # Visualize (optional)
            if output_path:
                vis_frame = self._visualize_results(frame, result)
                cv2.imshow("Perception Pipeline", vis_frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break

            frame_idx += 1

        cap.release()
        cv2.destroyAllWindows()

        # Save results
        if output_path:
            self._save_results(results, output_path)

        print(f"[Pipeline] Processed {frame_idx} frames")
        avg_latency = self.total_latency / self.frame_count if self.frame_count > 0 else 0
        print(f"[Pipeline] Average latency: {avg_latency:.1f}ms ({1000.0/avg_latency:.1f} FPS)")

    def _generate_dummy_lidar(self) -> np.ndarray:
        """Generate dummy LiDAR points for testing."""
        # Create random point cloud
        num_points = 10000
        points = np.random.randn(num_points, 4)
        points[:, 0] *= 20  # x: -20 to 20m
        points[:, 1] *= 20  # y: -20 to 20m
        points[:, 2] = np.abs(points[:, 2])  # z: 0 to 3m
        points[:, 3] = np.random.rand(num_points)  # intensity
        return points

    def _visualize_results(self, frame: np.ndarray, result: Dict) -> np.ndarray:
        """Visualize detection results on frame."""
        vis_frame = frame.copy()

        # Draw tracked objects
        for obj in result['tracked_objects']:
            bbox = obj.get('bbox_2d')
            if bbox is not None:
                x1, y1, x2, y2 = map(int, bbox)
                cv2.rectangle(vis_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

                # Add label
                label = f"ID:{obj['track_id']} {obj['class']} {obj['confidence']:.2f}"
                cv2.putText(vis_frame, label, (x1, y1 - 10),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

        # Add FPS counter
        fps_text = f"FPS: {result['fps']:.1f}"
        cv2.putText(vis_frame, fps_text, (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

        return vis_frame

    def _save_results(self, results: List[Dict], output_path: str) -> None:
        """Save results to file."""
        import json

        output_file = Path(output_path) / "detections.json"
        output_file.parent.mkdir(parents=True, exist_ok=True)

        # Convert results to JSON-serializable format
        json_results = []
        for result in results:
            json_result = {
                'tracked_objects': [
                    {k: v.tolist() if isinstance(v, np.ndarray) else v
                     for k, v in obj.items()}
                    for obj in result['tracked_objects']
                ],
                'latency_ms': result['latency_ms'],
                'fps': result['fps']
            }
            json_results.append(json_result)

        with open(output_file, 'w') as f:
            json.dump(json_results, f, indent=2)

        print(f"[Pipeline] Results saved to {output_file}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="ADAS Perception Pipeline")
    parser.add_argument('--config', type=str, default='config/pipeline_config.yaml',
                       help='Path to configuration file')
    parser.add_argument('--input-video', type=str, required=True,
                       help='Path to input video file')
    parser.add_argument('--input-lidar', type=str, default=None,
                       help='Path to LiDAR data directory')
    parser.add_argument('--output', type=str, default='results/',
                       help='Path to save results')
    parser.add_argument('--visualize', action='store_true',
                       help='Enable visualization')

    args = parser.parse_args()

    # Initialize pipeline
    pipeline = PerceptionPipeline(args.config)

    # Process video
    pipeline.process_video(
        video_path=args.input_video,
        lidar_path=args.input_lidar,
        output_path=args.output if args.visualize else None
    )


if __name__ == '__main__':
    main()

"""
Unit tests for Camera Detector
Author: Automotive Agents Team
Date: 2026-03-19
"""

import pytest
import numpy as np
import cv2
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from camera.detector import CameraDetector


@pytest.fixture
def dummy_image():
    """Create a dummy test image."""
    return np.random.randint(0, 255, (720, 1280, 3), dtype=np.uint8)


@pytest.fixture
def detector():
    """Create a camera detector instance."""
    return CameraDetector(
        model_path="models/yolov8n.pt",
        confidence_threshold=0.5,
        nms_threshold=0.4
    )


class TestCameraDetector:
    """Test suite for CameraDetector."""

    def test_initialization(self, detector):
        """Test detector initialization."""
        assert detector is not None
        assert detector.confidence_threshold == 0.5
        assert detector.nms_threshold == 0.4
        assert detector.input_size == (640, 640)

    def test_detect_returns_list(self, detector, dummy_image):
        """Test that detect returns a list."""
        detections = detector.detect(dummy_image)
        assert isinstance(detections, list)

    def test_detection_format(self, detector, dummy_image):
        """Test detection dictionary format."""
        detections = detector.detect(dummy_image)

        if len(detections) > 0:
            det = detections[0]

            # Check required fields
            assert 'bbox' in det
            assert 'bbox_norm' in det
            assert 'class' in det
            assert 'class_id' in det
            assert 'confidence' in det

            # Check data types
            assert isinstance(det['bbox'], list)
            assert len(det['bbox']) == 4
            assert isinstance(det['class'], str)
            assert isinstance(det['confidence'], float)

    def test_bbox_coordinates(self, detector, dummy_image):
        """Test bounding box coordinates are valid."""
        detections = detector.detect(dummy_image)

        h, w = dummy_image.shape[:2]

        for det in detections:
            x1, y1, x2, y2 = det['bbox']

            # Check bounds
            assert 0 <= x1 < w
            assert 0 <= y1 < h
            assert 0 <= x2 <= w
            assert 0 <= y2 <= h

            # Check x1 < x2, y1 < y2
            assert x1 < x2
            assert y1 < y2

    def test_normalized_bbox(self, detector, dummy_image):
        """Test normalized bounding box coordinates."""
        detections = detector.detect(dummy_image)

        for det in detections:
            x1_norm, y1_norm, x2_norm, y2_norm = det['bbox_norm']

            # Check all coordinates are in [0, 1]
            assert 0 <= x1_norm <= 1
            assert 0 <= y1_norm <= 1
            assert 0 <= x2_norm <= 1
            assert 0 <= y2_norm <= 1

            # Check x1 < x2, y1 < y2
            assert x1_norm < x2_norm
            assert y1_norm < y2_norm

    def test_confidence_range(self, detector, dummy_image):
        """Test confidence scores are in valid range."""
        detections = detector.detect(dummy_image)

        for det in detections:
            confidence = det['confidence']
            assert 0.0 <= confidence <= 1.0
            assert confidence >= detector.confidence_threshold

    def test_class_filtering(self, detector, dummy_image):
        """Test only ADAS-relevant classes are returned."""
        detections = detector.detect(dummy_image)

        valid_classes = set(CameraDetector.ADAS_CLASSES.values())

        for det in detections:
            assert det['class'] in valid_classes

    def test_detect_with_crops(self, detector, dummy_image):
        """Test detection with crop extraction."""
        detections = detector.detect(dummy_image, return_crops=True)

        for det in detections:
            if 'crop' in det:
                crop = det['crop']
                assert isinstance(crop, np.ndarray)
                assert crop.ndim == 3  # (H, W, C)
                assert crop.shape[2] == 3  # RGB

    def test_preprocess_none(self, detector, dummy_image):
        """Test preprocessing with method=none."""
        preprocessed = detector.preprocess_image(dummy_image, enhancement=None)
        np.testing.assert_array_equal(preprocessed, dummy_image)

    def test_preprocess_clahe(self, detector, dummy_image):
        """Test CLAHE preprocessing."""
        preprocessed = detector.preprocess_image(dummy_image, enhancement='clahe')
        assert preprocessed.shape == dummy_image.shape
        assert preprocessed.dtype == dummy_image.dtype

    def test_preprocess_gamma(self, detector, dummy_image):
        """Test gamma correction preprocessing."""
        preprocessed = detector.preprocess_image(dummy_image, enhancement='gamma')
        assert preprocessed.shape == dummy_image.shape
        assert preprocessed.dtype == dummy_image.dtype

    def test_statistics_empty(self, detector):
        """Test statistics with empty detections."""
        stats = detector.get_detection_statistics([])

        assert stats['total_count'] == 0
        assert stats['class_counts'] == {}
        assert stats['avg_confidence'] == 0.0

    def test_statistics_non_empty(self, detector, dummy_image):
        """Test statistics with detections."""
        detections = detector.detect(dummy_image)

        if len(detections) > 0:
            stats = detector.get_detection_statistics(detections)

            assert stats['total_count'] == len(detections)
            assert isinstance(stats['class_counts'], dict)
            assert 0.0 <= stats['avg_confidence'] <= 1.0

    def test_visualize_detections(self, detector, dummy_image):
        """Test visualization function."""
        detections = detector.detect(dummy_image)
        vis_image = detector.visualize_detections(dummy_image, detections)

        assert vis_image.shape == dummy_image.shape
        assert vis_image.dtype == dummy_image.dtype

    def test_visualize_with_confidence(self, detector, dummy_image):
        """Test visualization with confidence scores."""
        detections = detector.detect(dummy_image)
        vis_image = detector.visualize_detections(
            dummy_image, detections, show_confidence=True
        )

        assert vis_image.shape == dummy_image.shape

    def test_visualize_without_confidence(self, detector, dummy_image):
        """Test visualization without confidence scores."""
        detections = detector.detect(dummy_image)
        vis_image = detector.visualize_detections(
            dummy_image, detections, show_confidence=False
        )

        assert vis_image.shape == dummy_image.shape

    def test_different_image_sizes(self, detector):
        """Test detection on different image sizes."""
        sizes = [(480, 640), (720, 1280), (1080, 1920)]

        for h, w in sizes:
            image = np.random.randint(0, 255, (h, w, 3), dtype=np.uint8)
            detections = detector.detect(image)
            assert isinstance(detections, list)

    def test_grayscale_image(self, detector):
        """Test detection on grayscale image (should convert to RGB)."""
        gray_image = np.random.randint(0, 255, (720, 1280), dtype=np.uint8)

        # Convert to RGB
        rgb_image = cv2.cvtColor(gray_image, cv2.COLOR_GRAY2BGR)

        detections = detector.detect(rgb_image)
        assert isinstance(detections, list)

    def test_consecutive_detections(self, detector, dummy_image):
        """Test running detection multiple times."""
        for _ in range(5):
            detections = detector.detect(dummy_image)
            assert isinstance(detections, list)

    def test_memory_cleanup(self, detector, dummy_image):
        """Test that detector doesn't leak memory."""
        import gc

        initial_objects = len(gc.get_objects())

        # Run detection multiple times
        for _ in range(10):
            _ = detector.detect(dummy_image)

        gc.collect()
        final_objects = len(gc.get_objects())

        # Allow some tolerance for object creation
        assert final_objects < initial_objects * 1.5


class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_empty_image(self, detector):
        """Test with empty image."""
        empty_image = np.zeros((720, 1280, 3), dtype=np.uint8)
        detections = detector.detect(empty_image)
        assert isinstance(detections, list)

    def test_white_image(self, detector):
        """Test with all-white image."""
        white_image = np.ones((720, 1280, 3), dtype=np.uint8) * 255
        detections = detector.detect(white_image)
        assert isinstance(detections, list)

    def test_small_image(self, detector):
        """Test with very small image."""
        small_image = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
        detections = detector.detect(small_image)
        assert isinstance(detections, list)

    def test_invalid_confidence_threshold(self):
        """Test initialization with invalid confidence threshold."""
        # Should still initialize, but might clip values
        detector = CameraDetector(
            model_path="models/yolov8n.pt",
            confidence_threshold=1.5  # Invalid: > 1.0
        )
        assert detector is not None

    def test_zero_confidence_threshold(self):
        """Test with zero confidence threshold."""
        detector = CameraDetector(
            model_path="models/yolov8n.pt",
            confidence_threshold=0.0
        )
        dummy_image = np.random.randint(0, 255, (720, 1280, 3), dtype=np.uint8)
        detections = detector.detect(dummy_image)
        # Should return more detections with lower threshold
        assert isinstance(detections, list)


class TestPerformance:
    """Performance and benchmarking tests."""

    def test_detection_latency(self, detector, dummy_image, benchmark):
        """Benchmark detection latency."""
        def detect():
            return detector.detect(dummy_image)

        result = benchmark(detect)
        assert isinstance(result, list)

    def test_preprocessing_latency(self, detector, dummy_image, benchmark):
        """Benchmark preprocessing latency."""
        def preprocess():
            return detector.preprocess_image(dummy_image, enhancement='clahe')

        result = benchmark(preprocess)
        assert isinstance(result, np.ndarray)

    @pytest.mark.slow
    def test_batch_detection(self, detector):
        """Test detection on multiple images."""
        import time

        images = [
            np.random.randint(0, 255, (720, 1280, 3), dtype=np.uint8)
            for _ in range(10)
        ]

        start_time = time.time()

        for image in images:
            _ = detector.detect(image)

        end_time = time.time()
        total_time = end_time - start_time
        avg_time = total_time / len(images)

        print(f"\nBatch detection: {len(images)} images in {total_time:.2f}s")
        print(f"Average: {avg_time*1000:.1f}ms per image ({1/avg_time:.1f} FPS)")

        # Assert reasonable performance (adjust based on hardware)
        assert avg_time < 1.0  # Less than 1 second per image


if __name__ == '__main__':
    # Run tests
    pytest.main([__file__, '-v', '--tb=short'])

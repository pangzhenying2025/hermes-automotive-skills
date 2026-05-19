#!/usr/bin/env python3
"""
DLT Adapter Examples.

Comprehensive examples demonstrating DLT logging for automotive applications.

Run: python3 examples.py
"""

import time
import sys
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from tools.adapters.logging import (
    DLTAdapter,
    DLTLogLevel,
    DLTLoggingHandler,
    DLTViewerAdapter,
    DLTFilter
)
import logging


def example_1_basic_logging():
    """Example 1: Basic DLT logging."""
    print("\n" + "="*60)
    print("Example 1: Basic DLT Logging")
    print("="*60)

    # Initialize DLT adapter
    dlt = DLTAdapter(
        app_id="ADAS",
        context_id="CTRL",
        ecu_id="ECU1",
        use_network=False,  # File only for this example
        log_file="/tmp/dlt_example_basic.dlt"
    )

    # Log at different levels
    dlt.log_fatal("Critical system failure - emergency shutdown required")
    dlt.log_error("Sensor communication timeout", sensor_id=3, timeout_ms=500)
    dlt.log_warn("Degraded performance mode activated", reason="low_voltage")
    dlt.log_info("Vehicle speed changed", speed_kmh=65.5)
    dlt.log_debug("Processing cycle completed", cycle_time_ms=12.3)
    dlt.log_verbose("Raw sensor data", adc_value=2047, raw_bytes="AA BB CC DD")

    dlt.close()
    print(f"Logs written to: /tmp/dlt_example_basic.dlt")


def example_2_structured_logging():
    """Example 2: Structured logging with rich context."""
    print("\n" + "="*60)
    print("Example 2: Structured Logging")
    print("="*60)

    dlt = DLTAdapter(
        app_id="ADAS",
        context_id="DATA",
        use_network=False,
        log_file="/tmp/dlt_example_structured.dlt"
    )

    # Log vehicle telemetry with structured data
    dlt.log_info(
        "Vehicle telemetry update",
        timestamp=time.time(),
        speed_kmh=65.5,
        rpm=2400,
        throttle_percent=45.2,
        brake_pressure_bar=0.0,
        steering_angle_deg=-5.2,
        gear=5,
        fuel_level_percent=78.5
    )

    # Log sensor fusion data
    dlt.log_debug(
        "Sensor fusion output",
        object_id=123,
        object_type="vehicle",
        distance_m=45.2,
        velocity_mps=12.5,
        angle_deg=15.0,
        confidence=0.95
    )

    # Log error with full context
    dlt.log_error(
        "Camera frame processing failed",
        frame_id=12345,
        timestamp=time.time(),
        error_code=0x1001,
        error_msg="Timeout waiting for frame",
        camera_id=2,
        expected_fps=30.0,
        actual_fps=18.5
    )

    dlt.close()
    print(f"Logs written to: /tmp/dlt_example_structured.dlt")


def example_3_multi_context():
    """Example 3: Multiple contexts in one application."""
    print("\n" + "="*60)
    print("Example 3: Multi-Context Logging")
    print("="*60)

    # Different contexts for different subsystems
    main_logger = DLTAdapter(
        app_id="ADAS",
        context_id="MAIN",
        use_network=False,
        log_file="/tmp/dlt_example_multi.dlt"
    )

    sensor_logger = DLTAdapter(
        app_id="ADAS",
        context_id="SENS",
        use_network=False,
        log_file="/tmp/dlt_example_multi.dlt"
    )

    control_logger = DLTAdapter(
        app_id="ADAS",
        context_id="CTRL",
        use_network=False,
        log_file="/tmp/dlt_example_multi.dlt"
    )

    comm_logger = DLTAdapter(
        app_id="ADAS",
        context_id="COMM",
        use_network=False,
        log_file="/tmp/dlt_example_multi.dlt"
    )

    # Simulate application lifecycle
    main_logger.log_info("ADAS application starting")
    sensor_logger.log_info("Initializing sensors")
    sensor_logger.log_debug("Camera 1 initialized", camera_id=1, resolution="1920x1080")
    sensor_logger.log_debug("Camera 2 initialized", camera_id=2, resolution="1280x720")
    sensor_logger.log_info("All sensors initialized successfully")

    control_logger.log_info("Starting control loops")
    control_logger.log_debug("Lateral control initialized", Kp=1.2, Ki=0.3, Kd=0.1)
    control_logger.log_debug("Longitudinal control initialized", max_accel=2.5)

    comm_logger.log_info("CAN communication started")
    comm_logger.log_debug("Subscribed to CAN ID 0x123")
    comm_logger.log_debug("Subscribed to CAN ID 0x456")

    main_logger.log_info("ADAS application ready")

    # Cleanup
    for logger in [main_logger, sensor_logger, control_logger, comm_logger]:
        logger.close()

    print(f"Logs written to: /tmp/dlt_example_multi.dlt")


def example_4_python_logging_integration():
    """Example 4: Integration with Python standard logging."""
    print("\n" + "="*60)
    print("Example 4: Python Logging Integration")
    print("="*60)

    # Setup Python logger
    logger = logging.getLogger("adas_controller")
    logger.setLevel(logging.DEBUG)

    # Add DLT handler
    dlt_handler = DLTLoggingHandler(
        app_id="ADAS",
        context_id="PYTH",
        log_file="/tmp/dlt_example_python.dlt"
    )

    # Optional: Add formatter
    formatter = logging.Formatter(
        '%(name)s - %(levelname)s - %(message)s'
    )
    dlt_handler.setFormatter(formatter)

    logger.addHandler(dlt_handler)

    # Use standard Python logging
    logger.info("Starting ADAS controller")
    logger.debug("Configuration loaded from /etc/adas/config.yaml")
    logger.warning("High CPU usage detected: 87%")

    try:
        # Simulate an error
        raise ValueError("Invalid sensor configuration")
    except Exception as e:
        logger.error("Failed to initialize sensor", exc_info=True)

    logger.info("ADAS controller shutdown complete")

    # Cleanup
    dlt_handler.close()
    print(f"Logs written to: /tmp/dlt_example_python.dlt")


def example_5_parse_and_filter():
    """Example 5: Parse and filter DLT logs."""
    print("\n" + "="*60)
    print("Example 5: Parse and Filter DLT Logs")
    print("="*60)

    # First, create some test logs
    dlt = DLTAdapter(
        app_id="TEST",
        context_id="FILT",
        use_network=False,
        log_file="/tmp/dlt_example_filter.dlt"
    )

    # Generate various log messages
    dlt.log_info("System started")
    dlt.log_debug("Debug message 1")
    dlt.log_debug("Debug message 2")
    dlt.log_warn("Warning: temperature high", temp_c=85.5)
    dlt.log_error("Error: sensor timeout", sensor_id=3)
    dlt.log_error("Error: communication failure", interface="CAN1")
    dlt.log_fatal("Fatal: system crash imminent")
    dlt.log_info("System stopped")

    dlt.close()

    # Now parse and filter
    viewer = DLTViewerAdapter("/tmp/dlt_example_filter.dlt")

    print("\n--- All Entries ---")
    all_entries = viewer.get_entries(limit=20)
    for entry in all_entries[:5]:
        print(entry)

    print(f"\n--- Filter: Errors Only ---")
    error_filter = DLTFilter(min_level=DLTLogLevel.ERROR)
    errors = viewer.get_entries(error_filter)
    for entry in errors:
        print(entry)

    print(f"\n--- Filter: Text Search 'timeout' ---")
    timeout_filter = DLTFilter(text_search="timeout", case_sensitive=False)
    timeouts = viewer.get_entries(timeout_filter)
    for entry in timeouts:
        print(entry)

    print(f"\n--- Statistics ---")
    stats = viewer.get_statistics()
    print(f"Total entries: {stats['total_entries']}")
    print(f"Time range: {stats['time_range']}")
    print(f"Log levels: {stats['log_levels']}")

    # Export to CSV
    viewer.export_csv("/tmp/dlt_filtered.csv", error_filter)
    print(f"\nErrors exported to: /tmp/dlt_filtered.csv")

    # Export to JSON
    viewer.export_json("/tmp/dlt_all.json", pretty=True)
    print(f"All logs exported to: /tmp/dlt_all.json")


def example_6_performance_logging():
    """Example 6: Performance and timing logging."""
    print("\n" + "="*60)
    print("Example 6: Performance Logging")
    print("="*60)

    dlt = DLTAdapter(
        app_id="PERF",
        context_id="METR",
        use_network=False,
        log_file="/tmp/dlt_example_perf.dlt"
    )

    # Simulate performance monitoring
    for i in range(5):
        start = time.perf_counter()

        # Simulate work
        time.sleep(0.01)

        end = time.perf_counter()
        duration_ms = (end - start) * 1000

        dlt.log_debug(
            "Frame processing completed",
            frame_id=i,
            duration_ms=round(duration_ms, 3),
            fps=round(1000.0 / duration_ms, 1),
            cpu_percent=45.2 + i * 2,
            memory_mb=234 + i * 10
        )

    # Log aggregated statistics
    dlt.log_info(
        "Performance summary",
        total_frames=5,
        avg_duration_ms=10.5,
        min_duration_ms=9.8,
        max_duration_ms=11.2,
        avg_fps=95.2
    )

    dlt.close()
    print(f"Logs written to: /tmp/dlt_example_perf.dlt")


def example_7_diagnostic_trace():
    """Example 7: Diagnostic sequence tracing."""
    print("\n" + "="*60)
    print("Example 7: Diagnostic Trace Logging")
    print("="*60)

    dlt = DLTAdapter(
        app_id="DIAG",
        context_id="TRAC",
        use_network=False,
        log_file="/tmp/dlt_example_diag.dlt"
    )

    def perform_diagnostic_read(service: int, did: int):
        """Perform UDS diagnostic read with tracing."""
        dlt.log_info(
            "Starting diagnostic read",
            service=hex(service),
            did=hex(did)
        )

        # Step 1: Send request
        dlt.log_debug(
            "Sending diagnostic request",
            service_id=hex(service),
            data_id=hex(did),
            raw_bytes=f"{service:02X} {did:04X}".replace('0X', '')
        )

        # Simulate processing time
        time.sleep(0.05)

        # Step 2: Receive response
        response_data = [0x62, (did >> 8) & 0xFF, did & 0xFF, 0xAA, 0xBB, 0xCC, 0xDD]
        dlt.log_debug(
            "Received diagnostic response",
            response_code=hex(response_data[0]),
            data_length=len(response_data) - 3,
            raw_bytes=' '.join(f"{b:02X}" for b in response_data)
        )

        # Step 3: Validate
        is_valid = response_data[0] == (service + 0x40)
        dlt.log_debug(
            "Response validation",
            expected_code=hex(service + 0x40),
            actual_code=hex(response_data[0]),
            valid=is_valid
        )

        if is_valid:
            dlt.log_info("Diagnostic read completed successfully", did=hex(did))
        else:
            dlt.log_error("Diagnostic read failed", did=hex(did), error="Invalid response")

    # Perform multiple diagnostic reads
    perform_diagnostic_read(0x22, 0x1234)
    perform_diagnostic_read(0x22, 0x5678)
    perform_diagnostic_read(0x22, 0xABCD)

    dlt.close()
    print(f"Logs written to: /tmp/dlt_example_diag.dlt")


def example_8_error_recovery():
    """Example 8: Error handling and recovery logging."""
    print("\n" + "="*60)
    print("Example 8: Error Recovery Logging")
    print("="*60)

    dlt = DLTAdapter(
        app_id="ADAS",
        context_id="SAFE",
        use_network=False,
        log_file="/tmp/dlt_example_recovery.dlt"
    )

    def handle_sensor_failure(sensor_id: int, sensor_type: str):
        """Handle sensor failure with logging."""
        # Log the failure
        dlt.log_error(
            "Sensor failure detected",
            sensor_id=sensor_id,
            sensor_type=sensor_type,
            error_code=0x1001,
            timestamp=time.time()
        )

        # Attempt recovery
        dlt.log_info("Attempting sensor recovery", sensor_id=sensor_id, attempt=1)

        # Simulate recovery attempt
        time.sleep(0.1)
        recovery_success = True  # Simplified

        if recovery_success:
            dlt.log_info(
                "Sensor recovery successful",
                sensor_id=sensor_id,
                recovery_time_ms=100,
                status="operational"
            )
        else:
            dlt.log_fatal(
                "Sensor recovery failed - entering safe mode",
                sensor_id=sensor_id,
                safe_mode=True,
                limited_functionality=True
            )

    def handle_communication_error(interface: str, error_code: int):
        """Handle communication error with logging."""
        dlt.log_error(
            "Communication error",
            interface=interface,
            error_code=hex(error_code),
            description="Bus off state detected"
        )

        # Automatic recovery
        dlt.log_warn("Initiating bus recovery", interface=interface)
        time.sleep(0.05)
        dlt.log_info("Communication restored", interface=interface)

    # Simulate various error scenarios
    handle_sensor_failure(3, "LIDAR")
    handle_communication_error("CAN1", 0x2001)

    dlt.close()
    print(f"Logs written to: /tmp/dlt_example_recovery.dlt")


def main():
    """Run all examples."""
    print("\nDLT Adapter Examples")
    print("=" * 60)

    examples = [
        example_1_basic_logging,
        example_2_structured_logging,
        example_3_multi_context,
        example_4_python_logging_integration,
        example_5_parse_and_filter,
        example_6_performance_logging,
        example_7_diagnostic_trace,
        example_8_error_recovery
    ]

    for example_func in examples:
        try:
            example_func()
        except Exception as e:
            print(f"Error running {example_func.__name__}: {e}")

    print("\n" + "="*60)
    print("All examples completed!")
    print("="*60)
    print("\nGenerated DLT files in /tmp/:")
    print("  - dlt_example_basic.dlt")
    print("  - dlt_example_structured.dlt")
    print("  - dlt_example_multi.dlt")
    print("  - dlt_example_python.dlt")
    print("  - dlt_example_filter.dlt")
    print("  - dlt_example_perf.dlt")
    print("  - dlt_example_diag.dlt")
    print("  - dlt_example_recovery.dlt")
    print("\nView with: python3 -c \"from tools.adapters.logging import DLTViewerAdapter; "
          "v = DLTViewerAdapter('/tmp/dlt_example_basic.dlt'); v.print_entries()\"")


if __name__ == "__main__":
    main()

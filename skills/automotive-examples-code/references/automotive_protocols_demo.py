#!/usr/bin/env python3
"""
Automotive Protocols Integration Demo
Demonstrates usage of all 8 automotive protocol adapters
"""

import sys
import time
import logging
from pathlib import Path

# Add tools to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from tools.adapters.protocols import (
    FlexRayAdapter,
    FlexRayChannel,
    LINAdapter,
    MOSTAdapter,
    EthernetAVBAdapter,
    BroadRReachAdapter,
    LVDSAdapter,
    SENTAdapter,
    PSI5Adapter,
    PSI5Mode
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def demo_flexray():
    """Demonstrate FlexRay X-by-wire communication"""
    logger.info("=" * 60)
    logger.info("FlexRay Demo: Steer-by-Wire System")
    logger.info("=" * 60)

    # Initialize FlexRay adapter
    fr = FlexRayAdapter(device="vFlexRay1", simulation_mode=True)

    # Configure cluster (5ms cycle)
    fr.configure_cluster(cycle_time_ms=5.0, static_slots=50, dynamic_slots=20)

    # Configure static slots for critical steering data
    fr.configure_slot(
        slot_id=1,
        channel=FlexRayChannel.CHANNEL_AB,  # Redundant channels
        payload_length=16,
        is_static=True
    )

    # Start communication as coldstart node
    fr.start_communication(coldstart=True)

    # Transmit steering angle data
    steering_angle = 45.0  # degrees
    torque = 12.5  # Nm

    # Pack data (simplified)
    import struct
    payload = struct.pack('>ff', steering_angle, torque)
    payload += b'\x00' * (16 - len(payload))  # Pad to 16 bytes

    for cycle in range(5):
        fr.transmit_frame(slot_id=1, payload=payload)
        logger.info(f"  Cycle {cycle}: Transmitted steering angle={steering_angle}°, "
                   f"torque={torque}Nm")
        time.sleep(0.005)  # 5ms cycle

    fr.stop_communication()
    logger.info("FlexRay demo completed\n")


def demo_lin():
    """Demonstrate LIN body control communication"""
    logger.info("=" * 60)
    logger.info("LIN Demo: Power Seat Control")
    logger.info("=" * 60)

    # Initialize LIN master
    lin = LINAdapter(port="/dev/ttyUSB0", baudrate=19200, is_master=True,
                    simulation_mode=True)

    # Configure frames
    lin.configure_frame(frame_id=0x10, data_length=4)  # Seat position
    lin.configure_frame(frame_id=0x11, data_length=2)  # Seat command

    # Set schedule table
    from tools.adapters.protocols.lin_adapter import LINScheduleEntry
    schedule = [
        LINScheduleEntry(frame_id=0x10, delay_ms=10),
        LINScheduleEntry(frame_id=0x11, delay_ms=20),
    ]
    lin.set_schedule_table(schedule)

    # Send seat position command
    seat_position = bytes([50, 75, 30, 0])  # Position, lumbar, recline, reserved
    lin.send_frame(frame_id=0x10, data=seat_position)
    logger.info(f"  Sent seat position: {seat_position.hex()}")

    # Execute schedule
    logger.info("  Executing schedule table...")
    lin.execute_schedule(iterations=3)

    logger.info("LIN demo completed\n")


def demo_most():
    """Demonstrate MOST multimedia streaming"""
    logger.info("=" * 60)
    logger.info("MOST Demo: Premium Audio Streaming")
    logger.info("=" * 60)

    # Initialize MOST adapter
    most = MOSTAdapter(node_address=0x0100, is_master=True, simulation_mode=True)

    # Allocate synchronous channel for 8-channel audio (48kHz, 24-bit)
    # Bandwidth = 8 channels * 3 bytes/sample * 48 samples/frame = 1152 bytes/frame
    channel_id = most.allocate_sync_channel(
        source_addr=0x0100,  # Head unit
        sink_addr=0x0200,    # Amplifier
        bandwidth=1152
    )

    if channel_id:
        # Start streaming
        most.start_sync_connection(channel_id)
        logger.info(f"  Started audio streaming on channel {channel_id}")

        # Simulate streaming audio frames
        for frame in range(3):
            audio_data = b'\x00' * 1152  # Simulated audio samples
            most.stream_audio(channel_id, audio_data)
            logger.info(f"  Streamed audio frame {frame + 1}")
            time.sleep(0.001)  # 1ms frame interval

    # Send control message to set volume
    from tools.adapters.protocols.most_adapter import MOSTMessage
    msg = MOSTMessage(
        target_address=0x0200,
        source_address=0x0100,
        function_block_id=0x22,  # AudioAmplifier
        function_id=0x100,       # SetVolume
        op_type=0,               # Set
        payload=bytes([75]),     # Volume 75%
        timestamp=time.time()
    )
    most.send_control_message(msg)
    logger.info("  Sent volume control message: 75%")

    logger.info("MOST demo completed\n")


def demo_ethernet_avb():
    """Demonstrate Ethernet AVB camera streaming"""
    logger.info("=" * 60)
    logger.info("Ethernet AVB Demo: ADAS Camera Streaming")
    logger.info("=" * 60)

    # Initialize Ethernet AVB adapter
    avb = EthernetAVBAdapter(interface="eth0", simulation_mode=True)

    # Configure AVTP stream for camera
    from tools.adapters.protocols.ethernet_avb_adapter import AVTPStream
    camera_stream = AVTPStream(
        stream_id=0x0001020304050607,
        dest_mac="01:00:5E:00:00:01",  # Multicast MAC
        max_frame_size=1500,
        frames_per_interval=30  # 30 fps
    )

    avb.configure_stream(camera_stream)

    # Get synchronized time
    gptp_time = avb.get_gptp_time()
    logger.info(f"  gPTP synchronized time: {gptp_time} ns")

    # Stream video frames
    for frame in range(3):
        frame_data = b'\xFF\xD8\xFF\xE0' + b'\x00' * 1496  # JPEG header + data
        avb.send_avtp_frame(camera_stream.stream_id, frame_data)
        logger.info(f"  Sent camera frame {frame + 1} (1500 bytes)")
        time.sleep(1.0 / 30)  # 30 fps

    logger.info("Ethernet AVB demo completed\n")


def demo_broadr_reach():
    """Demonstrate BroadR-Reach PHY configuration"""
    logger.info("=" * 60)
    logger.info("BroadR-Reach Demo: Camera PHY Configuration")
    logger.info("=" * 60)

    # Initialize BroadR-Reach adapter
    brr = BroadRReachAdapter(phy_address=0, simulation_mode=True)

    # Configure as master
    brr.configure_phy(master_mode=True, auto_neg=True)
    logger.info("  PHY configured as MASTER")

    # Get link status
    status = brr.get_link_status()
    logger.info(f"  Link status: {'UP' if status.link_up else 'DOWN'}")
    logger.info(f"  Speed: {status.speed_mbps} Mbps")
    logger.info(f"  Estimated cable length: {status.cable_length_m}m")

    # Run cable diagnostics
    cable_status = brr.run_cable_diagnostics()
    logger.info(f"  Cable diagnostics: {cable_status}")

    logger.info("BroadR-Reach demo completed\n")


def demo_lvds():
    """Demonstrate LVDS camera interface"""
    logger.info("=" * 60)
    logger.info("LVDS Demo: MIPI CSI-2 Camera Interface")
    logger.info("=" * 60)

    # Initialize LVDS adapter
    lvds = LVDSAdapter(device="lvds0", simulation_mode=True)

    # Configure transmitter (camera side)
    from tools.adapters.protocols.lvds_adapter import LVDSConfig
    tx_config = LVDSConfig(
        lane_count=4,
        bit_rate_mbps=800,
        output_swing_mv=350
    )
    lvds.configure_transmitter(tx_config)
    logger.info("  LVDS TX configured: 4 lanes @ 800 Mbps/lane")

    # Configure receiver (SoC side)
    lvds.configure_receiver(lane_count=4)
    logger.info("  LVDS RX configured: 4 lanes")

    # Get status
    status = lvds.get_status()
    logger.info(f"  Link locked: {status['locked']}")
    logger.info(f"  Bit errors: {status['bit_errors']}")
    logger.info(f"  Signal strength: {status['signal_strength_dbm']} dBm")

    logger.info("LVDS demo completed\n")


def demo_sent():
    """Demonstrate SENT sensor interface"""
    logger.info("=" * 60)
    logger.info("SENT Demo: Temperature Sensor")
    logger.info("=" * 60)

    # Initialize SENT adapter
    sent = SENTAdapter(tick_time_us=3, simulation_mode=True)

    # Configure receiver
    sent.configure_receiver(data_nibbles=3, slow_channel=True)
    logger.info("  SENT receiver configured: 3 nibbles (12-bit data)")

    # Receive frames
    for i in range(5):
        frame = sent.receive_frame(timeout_ms=10)

        if frame and frame.valid:
            # Convert to temperature (-40°C to +160°C range)
            temperature = sent.convert_to_physical(
                raw_data=frame.data,
                gain=200.0,
                offset=-40.0
            )
            logger.info(f"  Frame {i + 1}: Temperature = {temperature:.1f}°C "
                       f"(raw=0x{frame.data:03X}, status=0x{frame.status:X})")
        time.sleep(0.001)  # 1ms between frames

    # Get statistics
    stats = sent.get_statistics()
    logger.info(f"  Statistics: {stats['total_frames']} frames, "
               f"{stats['errors']} errors ({stats['error_rate']:.2%})")

    logger.info("SENT demo completed\n")


def demo_psi5():
    """Demonstrate PSI5 airbag sensor interface"""
    logger.info("=" * 60)
    logger.info("PSI5 Demo: Airbag Sensor System")
    logger.info("=" * 60)

    # Initialize PSI5 adapter
    psi5 = PSI5Adapter(mode=PSI5Mode.MODE2, data_rate=125000, simulation_mode=True)

    # Configure for 3 airbag sensors
    psi5.configure(
        sensor_count=3,
        sync_period_us=1000,  # 1ms (1 kHz)
        time_slot_us=250
    )
    logger.info("  PSI5 configured: 3 sensors, 1ms sync period")

    # Simulate sensor reading cycle
    for cycle in range(3):
        logger.info(f"  Cycle {cycle + 1}:")

        # Generate sync pulse
        psi5.generate_sync_pulse()

        # Read from each sensor
        for sensor_id in range(3):
            frame = psi5.receive_frame(sensor_id)

            if frame and frame.valid:
                # Process airbag sensor data
                data = psi5.process_airbag_sensor(frame)

                logger.info(f"    Sensor {sensor_id}: "
                           f"Acceleration = {data['acceleration_mg']:.1f} mg, "
                           f"Status = {'OK' if data['sensor_ok'] else 'FAULT'}")

        time.sleep(0.001)  # 1ms cycle

    logger.info("PSI5 demo completed\n")


def main():
    """Run all protocol demonstrations"""
    logger.info("\n" + "=" * 60)
    logger.info("AUTOMOTIVE PROTOCOLS DEMONSTRATION")
    logger.info("=" * 60 + "\n")

    try:
        # Run each protocol demo
        demo_flexray()
        demo_lin()
        demo_most()
        demo_ethernet_avb()
        demo_broadr_reach()
        demo_lvds()
        demo_sent()
        demo_psi5()

        logger.info("=" * 60)
        logger.info("ALL DEMONSTRATIONS COMPLETED SUCCESSFULLY")
        logger.info("=" * 60)

    except Exception as e:
        logger.error(f"Demo failed: {e}", exc_info=True)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
FlexRay Protocol Adapter
Provides Python interface for FlexRay deterministic automotive bus communication
"""

import time
import struct
import logging
from typing import Dict, List, Optional, Tuple, Callable
from dataclasses import dataclass
from enum import Enum
import threading

logger = logging.getLogger(__name__)


class FlexRayChannel(Enum):
    """FlexRay channel selection"""
    CHANNEL_A = 0
    CHANNEL_B = 1
    CHANNEL_AB = 2  # Both channels


class FlexRayPOCState(Enum):
    """FlexRay Protocol Operation Control states"""
    DEFAULT_CONFIG = 0
    CONFIG = 1
    READY = 2
    WAKEUP = 3
    STARTUP = 4
    NORMAL_ACTIVE = 5
    NORMAL_PASSIVE = 6
    HALT = 7


@dataclass
class FlexRaySlot:
    """FlexRay communication slot configuration"""
    slot_id: int                    # Slot ID (1-2047)
    channel: FlexRayChannel
    cycle_repetition: int           # Cycle multiplier
    payload_length: int             # Bytes (0-254)
    is_static: bool = True
    base_cycle: int = 0


@dataclass
class FlexRayFrame:
    """FlexRay frame structure"""
    slot_id: int
    cycle: int
    channel: FlexRayChannel
    payload: bytes
    timestamp: float
    header_crc: Optional[int] = None
    frame_crc: Optional[int] = None


class FlexRayAdapter:
    """
    Adapter for FlexRay protocol communication
    Supports deterministic time-triggered and event-triggered communication
    """

    def __init__(self, device: str = "vFlexRay1", simulation_mode: bool = True):
        """
        Initialize FlexRay adapter

        Args:
            device: FlexRay device identifier
            simulation_mode: Run in simulation mode without hardware
        """
        self.device = device
        self.simulation_mode = simulation_mode
        self.poc_state = FlexRayPOCState.DEFAULT_CONFIG
        self.cycle_counter = 0
        self.static_slots: Dict[int, FlexRaySlot] = {}
        self.dynamic_slots: Dict[int, FlexRaySlot] = {}
        self.receive_callbacks: Dict[int, List[Callable]] = {}
        self.running = False
        self.cycle_thread = None

        # Cluster parameters
        self.cycle_time_ms = 5.0  # 5ms default cycle
        self.static_slot_count = 50
        self.dynamic_slot_count = 20
        self.macrotick_duration_ns = 25000  # 25us (40kHz)

        logger.info(f"FlexRay adapter initialized: {device} "
                   f"(simulation={'ON' if simulation_mode else 'OFF'})")

    def configure_cluster(
        self,
        cycle_time_ms: float = 5.0,
        static_slots: int = 50,
        dynamic_slots: int = 20,
        macrotick_ns: int = 25000
    ) -> bool:
        """
        Configure FlexRay cluster parameters

        Args:
            cycle_time_ms: Communication cycle time in milliseconds
            static_slots: Number of static slots
            dynamic_slots: Number of dynamic slots
            macrotick_ns: Macrotick duration in nanoseconds

        Returns:
            True if configuration successful
        """
        try:
            self.cycle_time_ms = cycle_time_ms
            self.static_slot_count = static_slots
            self.dynamic_slot_count = dynamic_slots
            self.macrotick_duration_ns = macrotick_ns

            logger.info(
                f"FlexRay cluster configured: cycle={cycle_time_ms}ms, "
                f"static_slots={static_slots}, dynamic_slots={dynamic_slots}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to configure FlexRay cluster: {e}")
            return False

    def configure_slot(
        self,
        slot_id: int,
        channel: FlexRayChannel,
        payload_length: int,
        is_static: bool = True,
        cycle_repetition: int = 1,
        base_cycle: int = 0
    ) -> bool:
        """
        Configure communication slot

        Args:
            slot_id: Slot identifier (1-2047)
            channel: FlexRay channel(s)
            payload_length: Payload size in bytes (0-254)
            is_static: Static or dynamic slot
            cycle_repetition: Transmission cycle repetition
            base_cycle: Base cycle offset

        Returns:
            True if configuration successful
        """
        try:
            slot = FlexRaySlot(
                slot_id=slot_id,
                channel=channel,
                cycle_repetition=cycle_repetition,
                payload_length=payload_length,
                is_static=is_static,
                base_cycle=base_cycle
            )

            if is_static:
                self.static_slots[slot_id] = slot
                logger.info(f"Configured static slot {slot_id}: "
                          f"{payload_length}B on {channel.name}")
            else:
                self.dynamic_slots[slot_id] = slot
                logger.info(f"Configured dynamic slot {slot_id}: "
                          f"{payload_length}B on {channel.name}")

            return True

        except Exception as e:
            logger.error(f"Failed to configure slot {slot_id}: {e}")
            return False

    def start_communication(self, coldstart: bool = True) -> bool:
        """
        Start FlexRay communication

        Args:
            coldstart: Start as coldstart node

        Returns:
            True if startup successful
        """
        try:
            if self.running:
                logger.warning("FlexRay already running")
                return True

            self.poc_state = FlexRayPOCState.STARTUP
            logger.info(f"Starting FlexRay communication "
                       f"({'COLDSTART' if coldstart else 'NON-COLDSTART'})")

            # Simulate startup sequence
            if self.simulation_mode:
                time.sleep(0.1)  # Simulated startup time

            self.poc_state = FlexRayPOCState.NORMAL_ACTIVE
            self.running = True
            self.cycle_counter = 0

            # Start cycle thread
            self.cycle_thread = threading.Thread(
                target=self._cycle_worker,
                daemon=True
            )
            self.cycle_thread.start()

            logger.info("FlexRay communication started (NORMAL_ACTIVE)")
            return True

        except Exception as e:
            logger.error(f"Failed to start FlexRay communication: {e}")
            self.poc_state = FlexRayPOCState.HALT
            return False

    def stop_communication(self) -> bool:
        """
        Stop FlexRay communication

        Returns:
            True if stopped successfully
        """
        try:
            if not self.running:
                return True

            self.running = False
            if self.cycle_thread:
                self.cycle_thread.join(timeout=1.0)

            self.poc_state = FlexRayPOCState.READY
            logger.info("FlexRay communication stopped")
            return True

        except Exception as e:
            logger.error(f"Failed to stop FlexRay communication: {e}")
            return False

    def transmit_frame(
        self,
        slot_id: int,
        payload: bytes,
        channel: Optional[FlexRayChannel] = None
    ) -> bool:
        """
        Transmit FlexRay frame in specified slot

        Args:
            slot_id: Slot ID for transmission
            payload: Data payload (max 254 bytes)
            channel: Override channel selection

        Returns:
            True if transmitted successfully
        """
        try:
            # Find slot configuration
            slot = self.static_slots.get(slot_id) or self.dynamic_slots.get(slot_id)
            if not slot:
                logger.error(f"Slot {slot_id} not configured")
                return False

            # Validate payload length
            if len(payload) > slot.payload_length:
                logger.error(
                    f"Payload too large for slot {slot_id}: "
                    f"{len(payload)} > {slot.payload_length}"
                )
                return False

            # Pad payload to configured length
            padded_payload = payload + b'\x00' * (slot.payload_length - len(payload))

            # Use slot channel if not overridden
            tx_channel = channel or slot.channel

            # Calculate CRCs
            header_crc = self._calculate_header_crc(slot_id, slot.payload_length)
            frame_crc = self._calculate_frame_crc(padded_payload)

            frame = FlexRayFrame(
                slot_id=slot_id,
                cycle=self.cycle_counter,
                channel=tx_channel,
                payload=padded_payload,
                timestamp=time.time(),
                header_crc=header_crc,
                frame_crc=frame_crc
            )

            if self.simulation_mode:
                logger.debug(
                    f"TX FlexRay slot {slot_id} cycle {self.cycle_counter}: "
                    f"{len(payload)}B on {tx_channel.name}"
                )

            # Trigger local receive callbacks for loopback
            self._trigger_callbacks(frame)

            return True

        except Exception as e:
            logger.error(f"Failed to transmit FlexRay frame: {e}")
            return False

    def register_receive_callback(
        self,
        slot_id: int,
        callback: Callable[[FlexRayFrame], None]
    ) -> None:
        """
        Register callback for received frames

        Args:
            slot_id: Slot ID to monitor
            callback: Function to call with received frame
        """
        if slot_id not in self.receive_callbacks:
            self.receive_callbacks[slot_id] = []

        self.receive_callbacks[slot_id].append(callback)
        logger.info(f"Registered receive callback for slot {slot_id}")

    def get_poc_state(self) -> FlexRayPOCState:
        """
        Get Protocol Operation Control state

        Returns:
            Current POC state
        """
        return self.poc_state

    def get_cycle_counter(self) -> int:
        """
        Get current communication cycle counter

        Returns:
            Cycle counter value (0-63)
        """
        return self.cycle_counter

    def _cycle_worker(self) -> None:
        """Background thread for cycle management"""
        while self.running:
            cycle_start = time.time()

            # Increment cycle counter (0-63)
            self.cycle_counter = (self.cycle_counter + 1) % 64

            # Sleep for cycle time
            elapsed = time.time() - cycle_start
            sleep_time = (self.cycle_time_ms / 1000.0) - elapsed

            if sleep_time > 0:
                time.sleep(sleep_time)

    def _trigger_callbacks(self, frame: FlexRayFrame) -> None:
        """Trigger registered callbacks for received frame"""
        callbacks = self.receive_callbacks.get(frame.slot_id, [])
        for callback in callbacks:
            try:
                callback(frame)
            except Exception as e:
                logger.error(f"Callback error for slot {frame.slot_id}: {e}")

    def _calculate_header_crc(self, slot_id: int, payload_length: int) -> int:
        """Calculate FlexRay header CRC"""
        # Simplified CRC-11 calculation
        data = (slot_id << 7) | (payload_length & 0x7F)
        crc = 0x1A
        for _ in range(18):
            if crc & 0x400:
                crc = ((crc << 1) ^ 0x385) & 0x7FF
            else:
                crc = (crc << 1) & 0x7FF
            if data & 0x20000:
                crc ^= 1
            data <<= 1
        return crc

    def _calculate_frame_crc(self, payload: bytes) -> int:
        """Calculate FlexRay frame CRC"""
        # Simplified CRC-24 calculation
        crc = 0xFEDCBA
        for byte in payload:
            crc ^= byte << 16
            for _ in range(8):
                if crc & 0x800000:
                    crc = ((crc << 1) ^ 0x5D6DCB) & 0xFFFFFF
                else:
                    crc = (crc << 1) & 0xFFFFFF
        return crc

    def __del__(self):
        """Cleanup on destruction"""
        self.stop_communication()

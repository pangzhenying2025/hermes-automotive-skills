#!/usr/bin/env python3
"""
LIN Protocol Adapter
Provides Python interface for LIN (Local Interconnect Network) communication
"""

import time
import serial
import logging
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


class LINFrameType(Enum):
    """LIN frame types"""
    UNCONDITIONAL = 0
    EVENT_TRIGGERED = 1
    SPORADIC = 2
    DIAGNOSTIC = 3


class LINChecksumType(Enum):
    """LIN checksum calculation types"""
    CLASSIC = 0      # LIN 1.x
    ENHANCED = 1     # LIN 2.x


@dataclass
class LINFrame:
    """LIN frame structure"""
    frame_id: int               # Protected ID (0x00-0x3F)
    data: bytes                 # Data bytes (1-8)
    checksum: int
    frame_type: LINFrameType
    timestamp: float


@dataclass
class LINScheduleEntry:
    """LIN schedule table entry"""
    frame_id: int
    delay_ms: int


class LINAdapter:
    """
    Adapter for LIN protocol communication
    Supports both master and slave operation modes
    """

    def __init__(
        self,
        port: str = "/dev/ttyUSB0",
        baudrate: int = 19200,
        is_master: bool = True,
        simulation_mode: bool = True
    ):
        """
        Initialize LIN adapter

        Args:
            port: Serial port for LIN interface
            baudrate: LIN baud rate (1200, 9600, 19200)
            is_master: Master or slave mode
            simulation_mode: Run without hardware
        """
        self.port = port
        self.baudrate = baudrate
        self.is_master = is_master
        self.simulation_mode = simulation_mode
        self.serial = None
        self.running = False

        # Frame database
        self.frame_database: Dict[int, LINFrame] = {}
        self.receive_callbacks: Dict[int, List[Callable]] = {}

        # Schedule table
        self.schedule_table: List[LINScheduleEntry] = []
        self.schedule_index = 0

        # LIN constants
        self.SYNC_BYTE = 0x55
        self.BREAK_DURATION_US = 750  # 13 bits minimum at 19200 baud

        if not simulation_mode:
            self._init_serial()

        logger.info(
            f"LIN adapter initialized: {port} @ {baudrate} baud "
            f"({'MASTER' if is_master else 'SLAVE'})"
        )

    def _init_serial(self) -> bool:
        """Initialize serial port"""
        try:
            self.serial = serial.Serial(
                port=self.port,
                baudrate=self.baudrate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=0.1
            )
            logger.info(f"Serial port opened: {self.port}")
            return True
        except Exception as e:
            logger.error(f"Failed to open serial port: {e}")
            return False

    def configure_frame(
        self,
        frame_id: int,
        data_length: int,
        frame_type: LINFrameType = LINFrameType.UNCONDITIONAL,
        initial_data: Optional[bytes] = None
    ) -> bool:
        """
        Configure LIN frame in database

        Args:
            frame_id: Frame ID (0x00-0x3F)
            data_length: Number of data bytes (1-8)
            frame_type: Frame type
            initial_data: Initial data values

        Returns:
            True if configured successfully
        """
        try:
            if frame_id > 0x3F:
                logger.error(f"Invalid frame ID: 0x{frame_id:02X}")
                return False

            if data_length < 1 or data_length > 8:
                logger.error(f"Invalid data length: {data_length}")
                return False

            data = initial_data or b'\x00' * data_length

            frame = LINFrame(
                frame_id=frame_id,
                data=data[:data_length],
                checksum=0,
                frame_type=frame_type,
                timestamp=0.0
            )

            self.frame_database[frame_id] = frame
            logger.info(
                f"Configured LIN frame 0x{frame_id:02X}: "
                f"{data_length}B {frame_type.name}"
            )
            return True

        except Exception as e:
            logger.error(f"Failed to configure frame: {e}")
            return False

    def set_schedule_table(self, schedule: List[LINScheduleEntry]) -> bool:
        """
        Set LIN schedule table

        Args:
            schedule: List of schedule entries

        Returns:
            True if set successfully
        """
        try:
            self.schedule_table = schedule
            self.schedule_index = 0
            logger.info(f"Schedule table set: {len(schedule)} entries")
            return True
        except Exception as e:
            logger.error(f"Failed to set schedule table: {e}")
            return False

    def send_frame(
        self,
        frame_id: int,
        data: Optional[bytes] = None,
        checksum_type: LINChecksumType = LINChecksumType.ENHANCED
    ) -> bool:
        """
        Send LIN frame (master mode)

        Args:
            frame_id: Frame ID to send
            data: Data bytes (or use configured data)
            checksum_type: Checksum calculation type

        Returns:
            True if sent successfully
        """
        try:
            if not self.is_master:
                logger.error("Only master can send frames")
                return False

            # Get frame configuration
            frame = self.frame_database.get(frame_id)
            if not frame:
                logger.error(f"Frame 0x{frame_id:02X} not configured")
                return False

            # Use provided data or configured data
            tx_data = data or frame.data

            # Calculate protected ID
            protected_id = self._calculate_protected_id(frame_id)

            # Send break field
            self._send_break()

            # Send sync byte
            self._send_byte(self.SYNC_BYTE)

            # Send protected ID
            self._send_byte(protected_id)

            # Send data bytes
            for byte in tx_data:
                self._send_byte(byte)

            # Calculate and send checksum
            checksum = self._calculate_checksum(
                protected_id if checksum_type == LINChecksumType.ENHANCED else 0,
                tx_data
            )
            self._send_byte(checksum)

            if self.simulation_mode:
                logger.debug(
                    f"TX LIN 0x{frame_id:02X}: {tx_data.hex()} "
                    f"CRC=0x{checksum:02X}"
                )

            return True

        except Exception as e:
            logger.error(f"Failed to send LIN frame: {e}")
            return False

    def receive_frame(self, timeout_ms: int = 100) -> Optional[LINFrame]:
        """
        Receive LIN frame (slave mode)

        Args:
            timeout_ms: Reception timeout

        Returns:
            Received frame or None
        """
        try:
            if self.is_master:
                logger.warning("Master should use schedule execution")
                return None

            if self.simulation_mode:
                # Simulate frame reception
                time.sleep(timeout_ms / 1000.0)
                return None

            # Wait for break/sync/ID
            # (Implementation depends on hardware interface)

            return None

        except Exception as e:
            logger.error(f"Failed to receive LIN frame: {e}")
            return None

    def execute_schedule(self, iterations: int = 1) -> bool:
        """
        Execute schedule table

        Args:
            iterations: Number of schedule iterations

        Returns:
            True if executed successfully
        """
        try:
            if not self.is_master:
                logger.error("Only master can execute schedule")
                return False

            for _ in range(iterations):
                for entry in self.schedule_table:
                    # Send frame
                    self.send_frame(entry.frame_id)

                    # Wait for schedule delay
                    time.sleep(entry.delay_ms / 1000.0)

            return True

        except Exception as e:
            logger.error(f"Failed to execute schedule: {e}")
            return False

    def go_to_sleep(self) -> bool:
        """
        Send go-to-sleep command (diagnostic frame 0x3C)

        Returns:
            True if sent successfully
        """
        try:
            sleep_data = bytes([0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
            return self.send_frame(0x3C, sleep_data)
        except Exception as e:
            logger.error(f"Failed to send sleep command: {e}")
            return False

    def wakeup(self) -> bool:
        """
        Send wakeup pulse

        Returns:
            True if sent successfully
        """
        try:
            # Send dominant pulse (250-5000 us)
            if self.serial:
                self.serial.break_condition = True
                time.sleep(0.0005)  # 500 us
                self.serial.break_condition = False

            time.sleep(0.00015)  # 150 us recovery

            logger.info("Wakeup pulse sent")
            return True

        except Exception as e:
            logger.error(f"Failed to send wakeup: {e}")
            return False

    def register_receive_callback(
        self,
        frame_id: int,
        callback: Callable[[LINFrame], None]
    ) -> None:
        """Register callback for frame reception"""
        if frame_id not in self.receive_callbacks:
            self.receive_callbacks[frame_id] = []
        self.receive_callbacks[frame_id].append(callback)

    def _send_break(self) -> None:
        """Send LIN break field"""
        if self.serial:
            self.serial.break_condition = True
            time.sleep(self.BREAK_DURATION_US / 1000000.0)
            self.serial.break_condition = False

    def _send_byte(self, byte: int) -> None:
        """Send single byte"""
        if self.serial:
            self.serial.write(bytes([byte]))

    def _calculate_protected_id(self, frame_id: int) -> int:
        """
        Calculate protected ID with parity bits

        Args:
            frame_id: 6-bit frame ID

        Returns:
            8-bit protected ID
        """
        # P0 = ID0 ⊕ ID1 ⊕ ID2 ⊕ ID4
        p0 = (
            ((frame_id >> 0) & 1) ^
            ((frame_id >> 1) & 1) ^
            ((frame_id >> 2) & 1) ^
            ((frame_id >> 4) & 1)
        )

        # P1 = ¬(ID1 ⊕ ID3 ⊕ ID4 ⊕ ID5)
        p1 = (
            1 ^ ((frame_id >> 1) & 1) ^
            ((frame_id >> 3) & 1) ^
            ((frame_id >> 4) & 1) ^
            ((frame_id >> 5) & 1)
        )

        protected_id = frame_id | (p0 << 6) | (p1 << 7)
        return protected_id

    def _calculate_checksum(self, protected_id: int, data: bytes) -> int:
        """
        Calculate LIN checksum

        Args:
            protected_id: Protected ID (0 for classic checksum)
            data: Data bytes

        Returns:
            8-bit checksum
        """
        checksum = protected_id

        for byte in data:
            checksum += byte
            if checksum > 0xFF:
                checksum = (checksum & 0xFF) + 1

        checksum = 0xFF - (checksum & 0xFF)
        return checksum

    def __del__(self):
        """Cleanup"""
        if self.serial:
            self.serial.close()

#!/usr/bin/env python3
"""
SENT Protocol Adapter
Provides Python interface for SENT (Single Edge Nibble Transmission)
"""

import time
import logging
from typing import Optional, Callable
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class SENTFrame:
    """SENT frame structure"""
    valid: bool
    status: int
    data: int
    crc: int
    crc_valid: bool
    timestamp: float


class SENTAdapter:
    """Adapter for SENT protocol reception"""

    def __init__(self, tick_time_us: int = 3, simulation_mode: bool = True):
        """Initialize SENT adapter"""
        self.tick_time_us = tick_time_us
        self.simulation_mode = simulation_mode
        self.frame_count = 0
        self.error_count = 0

        logger.info(f"SENT adapter initialized: tick={tick_time_us}us")

    def configure_receiver(
        self,
        data_nibbles: int = 3,
        slow_channel: bool = False
    ) -> bool:
        """Configure SENT receiver"""
        try:
            self.data_nibbles = data_nibbles
            self.slow_channel = slow_channel
            logger.info(f"SENT RX configured: {data_nibbles} nibbles")
            return True
        except Exception as e:
            logger.error(f"Failed to configure SENT RX: {e}")
            return False

    def receive_frame(self, timeout_ms: int = 100) -> Optional[SENTFrame]:
        """Receive SENT frame"""
        if self.simulation_mode:
            time.sleep(0.001)  # 1ms frame time
            self.frame_count += 1

            # Simulate sensor data
            return SENTFrame(
                valid=True,
                status=0,
                data=2048,  # Mid-range value
                crc=0x5,
                crc_valid=True,
                timestamp=time.time()
            )
        return None

    def convert_to_physical(self, raw_data: int, gain: float, offset: float) -> float:
        """Convert raw SENT data to physical value"""
        max_raw = (1 << (self.data_nibbles * 4)) - 1
        normalized = raw_data / max_raw
        return normalized * gain + offset

    def get_statistics(self) -> Dict:
        """Get reception statistics"""
        return {
            'total_frames': self.frame_count,
            'errors': self.error_count,
            'error_rate': self.error_count / max(self.frame_count, 1)
        }

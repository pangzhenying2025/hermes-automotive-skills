#!/usr/bin/env python3
"""
PSI5 Protocol Adapter
Provides Python interface for PSI5 (Peripheral Sensor Interface 5)
"""

import time
import logging
from typing import Optional, Dict
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


class PSI5Mode(Enum):
    """PSI5 operating modes"""
    MODE1 = 1  # Asynchronous
    MODE2 = 2  # Synchronous time-slot
    MODE3 = 3  # Bidirectional


@dataclass
class PSI5Frame:
    """PSI5 frame structure"""
    valid: bool
    sensor_id: int
    data: int
    crc: int
    crc_valid: bool
    error_code: int


class PSI5Adapter:
    """Adapter for PSI5 protocol communication"""

    def __init__(
        self,
        mode: PSI5Mode = PSI5Mode.MODE2,
        data_rate: int = 125000,
        simulation_mode: bool = True
    ):
        """Initialize PSI5 adapter"""
        self.mode = mode
        self.data_rate = data_rate
        self.simulation_mode = simulation_mode
        self.sensor_count = 0

        logger.info(f"PSI5 adapter initialized: {mode.name} @ {data_rate} bps")

    def configure(
        self,
        sensor_count: int,
        sync_period_us: int = 1000,
        time_slot_us: int = 250
    ) -> bool:
        """Configure PSI5 interface"""
        try:
            self.sensor_count = sensor_count
            self.sync_period_us = sync_period_us
            self.time_slot_us = time_slot_us

            logger.info(f"PSI5 configured: {sensor_count} sensors, "
                       f"sync={sync_period_us}us")
            return True

        except Exception as e:
            logger.error(f"Failed to configure PSI5: {e}")
            return False

    def generate_sync_pulse(self) -> bool:
        """Generate sync pulse to trigger sensors"""
        if self.simulation_mode:
            logger.debug("PSI5 sync pulse generated")
            return True
        return False

    def receive_frame(self, sensor_id: int) -> Optional[PSI5Frame]:
        """Receive frame from specific sensor"""
        if self.simulation_mode:
            time.sleep(self.time_slot_us / 1e6)

            # Simulate airbag sensor data
            return PSI5Frame(
                valid=True,
                sensor_id=sensor_id,
                data=0x0800,  # 0g acceleration
                crc=0x5,
                crc_valid=True,
                error_code=0
            )
        return None

    def process_airbag_sensor(self, frame: PSI5Frame) -> Dict:
        """Process airbag sensor data"""
        if not frame.valid or not frame.crc_valid:
            return {'error': 'Invalid frame'}

        # Extract 12-bit acceleration (-100g to +100g)
        raw_accel = (frame.data >> 2) & 0xFFF
        if raw_accel & 0x800:
            raw_accel |= 0xF000  # Sign extend

        acceleration_mg = (raw_accel * 200000) / 4096

        return {
            'sensor_id': frame.sensor_id,
            'acceleration_mg': acceleration_mg,
            'status': frame.error_code,
            'sensor_ok': (frame.error_code == 0)
        }

#!/usr/bin/env python3
"""
Vector vFlash Adapter - Integration with Vector vFlash flash programming tool
Provides Python interface to vFlash COM API for ECU flash programming
"""

import os
import sys
import time
import json
import logging
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path

# Attempt to import win32com for Vector vFlash COM interface (Windows only)
try:
    import win32com.client
    VFLASH_AVAILABLE = True
except ImportError:
    VFLASH_AVAILABLE = False
    logging.warning("win32com not available - vFlash adapter will use simulation mode")


class FlashJobStatus(IntEnum):
    """vFlash job status codes"""
    NOT_STARTED = 0
    RUNNING = 1
    COMPLETED = 2
    FAILED = 3
    ABORTED = 4


class VFlashError(Exception):
    """vFlash-specific errors"""
    pass


@dataclass
class FlashProgress:
    """Flash programming progress information"""
    total_bytes: int
    bytes_transferred: int
    percentage: float
    current_block: int
    total_blocks: int
    transfer_rate: float  # bytes/second
    time_elapsed: float
    time_remaining: float
    current_operation: str


@dataclass
class FlashResult:
    """Flash programming result"""
    success: bool
    status: FlashJobStatus
    message: str
    duration: float
    bytes_programmed: int
    log_file: Optional[str] = None
    error_code: Optional[int] = None


class VFlashAdapter:
    """
    Adapter for Vector vFlash flash programming tool

    Provides high-level interface to vFlash COM API for ECU flash programming
    with support for progress monitoring, error handling, and logging.
    """

    def __init__(self, vflash_path: Optional[str] = None, simulation_mode: bool = False):
        """
        Initialize vFlash adapter

        Args:
            vflash_path: Path to vFlash installation (auto-detected if None)
            simulation_mode: Enable simulation mode for testing without vFlash
        """
        self.logger = logging.getLogger(__name__)
        self.simulation_mode = simulation_mode or not VFLASH_AVAILABLE
        self.vflash_path = vflash_path or self._detect_vflash_path()
        self.vflash = None
        self.progress_callback: Optional[Callable[[FlashProgress], None]] = None

        if not self.simulation_mode:
            self._initialize_vflash()
        else:
            self.logger.warning("Running in simulation mode - no actual flash programming")

    def _detect_vflash_path(self) -> Optional[str]:
        """Auto-detect vFlash installation path"""
        common_paths = [
            r"C:\Program Files\Vector vFlash",
            r"C:\Program Files (x86)\Vector vFlash",
            r"C:\Vector\vFlash",
        ]

        for path in common_paths:
            if os.path.exists(path):
                self.logger.info(f"Detected vFlash at {path}")
                return path

        return None

    def _initialize_vflash(self):
        """Initialize vFlash COM interface"""
        try:
            self.vflash = win32com.client.Dispatch("VFlash.Application")
            self.logger.info(f"vFlash initialized: {self.vflash.Version}")
        except Exception as e:
            raise VFlashError(f"Failed to initialize vFlash COM interface: {e}")

    def load_project(self, vflash_project: str) -> bool:
        """
        Load vFlash project file (.vflash)

        Args:
            vflash_project: Path to .vflash project file

        Returns:
            True if project loaded successfully
        """
        if not os.path.exists(vflash_project):
            raise VFlashError(f"vFlash project not found: {vflash_project}")

        if self.simulation_mode:
            self.logger.info(f"[SIMULATION] Loading project: {vflash_project}")
            return True

        try:
            self.vflash.LoadProject(vflash_project)
            self.logger.info(f"vFlash project loaded: {vflash_project}")
            return True
        except Exception as e:
            raise VFlashError(f"Failed to load vFlash project: {e}")

    def configure_interface(self, interface_type: str, interface_config: Dict[str, Any]):
        """
        Configure CAN/Ethernet interface for flash programming

        Args:
            interface_type: 'CAN', 'DoIP', 'FlexRay'
            interface_config: Interface-specific configuration
                For CAN: {'channel': 1, 'baudrate': 500000}
                For DoIP: {'ip': '192.168.1.10', 'port': 13400}
        """
        if self.simulation_mode:
            self.logger.info(f"[SIMULATION] Configuring {interface_type}: {interface_config}")
            return

        try:
            if interface_type.upper() == 'CAN':
                self.vflash.SetCANChannel(interface_config.get('channel', 1))
                self.vflash.SetCANBaudrate(interface_config.get('baudrate', 500000))
            elif interface_type.upper() == 'DOIP':
                self.vflash.SetDoIPTargetAddress(interface_config.get('ip'))
                self.vflash.SetDoIPPort(interface_config.get('port', 13400))

            self.logger.info(f"Interface configured: {interface_type}")
        except Exception as e:
            raise VFlashError(f"Failed to configure interface: {e}")

    def set_flash_parameters(self, params: Dict[str, Any]):
        """
        Set flash programming parameters

        Args:
            params: Flash parameters
                {
                    'voltage_min': 11.5,  # Minimum voltage (V)
                    'voltage_max': 14.5,  # Maximum voltage (V)
                    'verify_flash': True,  # Verify after programming
                    'erase_first': True,   # Erase before programming
                }
        """
        if self.simulation_mode:
            self.logger.info(f"[SIMULATION] Flash parameters: {params}")
            return

        try:
            if 'voltage_min' in params:
                self.vflash.SetVoltageMin(params['voltage_min'])
            if 'voltage_max' in params:
                self.vflash.SetVoltageMax(params['voltage_max'])

            self.logger.info(f"Flash parameters configured: {params}")
        except Exception as e:
            raise VFlashError(f"Failed to set flash parameters: {e}")

    def register_progress_callback(self, callback: Callable[[FlashProgress], None]):
        """
        Register callback for flash progress updates

        Args:
            callback: Function to call with FlashProgress updates
        """
        self.progress_callback = callback
        self.logger.debug("Progress callback registered")

    def flash_ecu(self, timeout: int = 600) -> FlashResult:
        """
        Execute ECU flash programming

        Args:
            timeout: Maximum time to wait for flash completion (seconds)

        Returns:
            FlashResult with programming outcome
        """
        start_time = time.time()

        if self.simulation_mode:
            return self._simulate_flash(timeout)

        try:
            # Start flash job
            self.vflash.StartFlashJob()
            self.logger.info("Flash job started")

            # Monitor progress
            last_progress = 0
            while True:
                status = self.vflash.GetJobStatus()

                if status == FlashJobStatus.COMPLETED:
                    duration = time.time() - start_time
                    result = FlashResult(
                        success=True,
                        status=FlashJobStatus.COMPLETED,
                        message="Flash programming completed successfully",
                        duration=duration,
                        bytes_programmed=self.vflash.GetBytesTransferred(),
                        log_file=self.vflash.GetLogFile()
                    )
                    self.logger.info(f"Flash completed in {duration:.1f}s")
                    return result

                elif status in [FlashJobStatus.FAILED, FlashJobStatus.ABORTED]:
                    error_msg = self.vflash.GetLastError()
                    raise VFlashError(f"Flash job {status.name}: {error_msg}")

                # Update progress
                progress_pct = self.vflash.GetProgress()
                if progress_pct != last_progress and self.progress_callback:
                    elapsed = time.time() - start_time
                    progress = FlashProgress(
                        total_bytes=self.vflash.GetTotalBytes(),
                        bytes_transferred=self.vflash.GetBytesTransferred(),
                        percentage=progress_pct,
                        current_block=self.vflash.GetCurrentBlock(),
                        total_blocks=self.vflash.GetTotalBlocks(),
                        transfer_rate=self.vflash.GetBytesTransferred() / elapsed if elapsed > 0 else 0,
                        time_elapsed=elapsed,
                        time_remaining=(elapsed / (progress_pct / 100)) - elapsed if progress_pct > 0 else 0,
                        current_operation=self.vflash.GetCurrentOperation()
                    )
                    self.progress_callback(progress)
                    last_progress = progress_pct

                # Check timeout
                if time.time() - start_time > timeout:
                    self.vflash.AbortFlashJob()
                    raise VFlashError(f"Flash job timeout after {timeout}s")

                time.sleep(0.1)  # Poll interval

        except Exception as e:
            duration = time.time() - start_time
            return FlashResult(
                success=False,
                status=FlashJobStatus.FAILED,
                message=str(e),
                duration=duration,
                bytes_programmed=0,
                error_code=getattr(e, 'error_code', None)
            )

    def _simulate_flash(self, timeout: int) -> FlashResult:
        """Simulate flash programming for testing"""
        self.logger.info("[SIMULATION] Starting flash simulation")

        total_bytes = 2 * 1024 * 1024  # Simulate 2MB flash
        total_blocks = 256

        start_time = time.time()

        for block in range(total_blocks):
            if self.progress_callback:
                elapsed = time.time() - start_time
                bytes_transferred = int((block / total_blocks) * total_bytes)
                progress_pct = (block / total_blocks) * 100

                progress = FlashProgress(
                    total_bytes=total_bytes,
                    bytes_transferred=bytes_transferred,
                    percentage=progress_pct,
                    current_block=block,
                    total_blocks=total_blocks,
                    transfer_rate=bytes_transferred / elapsed if elapsed > 0 else 0,
                    time_elapsed=elapsed,
                    time_remaining=(elapsed / (progress_pct / 100)) - elapsed if progress_pct > 0 else 0,
                    current_operation=f"Programming block {block}/{total_blocks}"
                )
                self.progress_callback(progress)

            time.sleep(0.01)  # Simulate 10ms per block

        duration = time.time() - start_time

        return FlashResult(
            success=True,
            status=FlashJobStatus.COMPLETED,
            message="[SIMULATION] Flash completed successfully",
            duration=duration,
            bytes_programmed=total_bytes,
            log_file="/tmp/vflash_simulation.log"
        )

    def get_ecu_info(self) -> Dict[str, str]:
        """
        Read ECU identification information

        Returns:
            Dictionary with ECU info (VIN, HW version, SW version, etc.)
        """
        if self.simulation_mode:
            return {
                'vin': 'SIMULATION17CHARS01',
                'hw_version': 'HW1.0_SIM',
                'sw_version': 'SW2.3.4_SIM',
                'serial': 'SIM123456789',
                'ecu_name': 'Simulation ECU'
            }

        try:
            return {
                'vin': self.vflash.ReadDID(0xF190),
                'hw_version': self.vflash.ReadDID(0xF191),
                'sw_version': self.vflash.ReadDID(0xF195),
                'serial': self.vflash.ReadDID(0xF18C),
                'ecu_name': self.vflash.ReadDID(0xF197)
            }
        except Exception as e:
            raise VFlashError(f"Failed to read ECU info: {e}")

    def close(self):
        """Close vFlash connection and cleanup"""
        if not self.simulation_mode and self.vflash:
            try:
                self.vflash.Close()
                self.logger.info("vFlash connection closed")
            except Exception as e:
                self.logger.error(f"Error closing vFlash: {e}")


def main():
    """Example usage of VFlashAdapter"""
    logging.basicConfig(level=logging.INFO)

    # Create adapter in simulation mode
    adapter = VFlashAdapter(simulation_mode=True)

    # Progress callback
    def on_progress(progress: FlashProgress):
        print(f"Progress: {progress.percentage:.1f}% - {progress.current_operation}")
        print(f"  Rate: {progress.transfer_rate/1024:.1f} KB/s, ETA: {progress.time_remaining:.1f}s")

    adapter.register_progress_callback(on_progress)

    # Configure and flash
    adapter.load_project("/path/to/project.vflash")
    adapter.configure_interface('CAN', {'channel': 1, 'baudrate': 500000})
    adapter.set_flash_parameters({'voltage_min': 11.5, 'voltage_max': 14.5})

    result = adapter.flash_ecu(timeout=600)

    print(f"\nFlash Result:")
    print(f"  Success: {result.success}")
    print(f"  Duration: {result.duration:.1f}s")
    print(f"  Bytes: {result.bytes_programmed / 1024 / 1024:.2f} MB")
    print(f"  Message: {result.message}")

    adapter.close()


if __name__ == '__main__':
    main()

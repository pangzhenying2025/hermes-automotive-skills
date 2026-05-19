#!/usr/bin/env python3
"""
OpenOCD Adapter
Open On-Chip Debugger interface for embedded debugging and programming
"""

import subprocess
import socket
import time
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import logging
from dataclasses import dataclass
from enum import Enum
import struct

logger = logging.getLogger(__name__)


class DebugInterface(Enum):
    """Debug interface types"""
    STLINK = "stlink"
    JLINK = "jlink"
    CMSIS_DAP = "cmsis-dap"
    FTDI = "ftdi"


class TargetState(Enum):
    """Target CPU states"""
    RUNNING = "running"
    HALTED = "halted"
    RESET = "reset"
    UNKNOWN = "unknown"


@dataclass
class OpenOCDConfig:
    """OpenOCD configuration"""
    interface: DebugInterface
    target: str
    transport: str = "swd"
    adapter_speed: int = 4000


@dataclass
class BreakpointInfo:
    """Breakpoint information"""
    number: int
    address: int
    enabled: bool
    hit_count: int = 0


class OpenOCDAdapter:
    """
    Adapter for OpenOCD debugging and flash programming
    Provides high-level interface for embedded development workflows
    """

    def __init__(
        self,
        openocd_path: Optional[str] = None,
        telnet_port: int = 4444,
        gdb_port: int = 3333
    ):
        """
        Initialize OpenOCD adapter

        Args:
            openocd_path: Path to openocd executable
            telnet_port: Telnet port for commands
            gdb_port: GDB server port
        """
        self.openocd_path = openocd_path or "openocd"
        self.telnet_port = telnet_port
        self.gdb_port = gdb_port
        self.process: Optional[subprocess.Popen] = None
        self.telnet_socket: Optional[socket.socket] = None
        self.config: Optional[OpenOCDConfig] = None

    def start_server(
        self,
        config: OpenOCDConfig,
        config_files: Optional[List[Path]] = None
    ) -> bool:
        """
        Start OpenOCD server

        Args:
            config: OpenOCD configuration
            config_files: Additional config files

        Returns:
            True if started successfully
        """
        self.config = config

        cmd = [
            self.openocd_path,
            "-f", f"interface/{config.interface.value}.cfg",
            "-f", f"target/{config.target}.cfg",
            "-c", f"adapter speed {config.adapter_speed}",
            "-c", f"transport select {config.transport}"
        ]

        if config_files:
            for cfg_file in config_files:
                cmd.extend(["-f", str(cfg_file)])

        logger.info(f"Starting OpenOCD server: {' '.join(cmd)}")

        try:
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            time.sleep(2)

            if self.process.poll() is not None:
                stdout, stderr = self.process.communicate()
                logger.error(f"OpenOCD failed to start: {stderr}")
                return False

            if self._connect_telnet():
                logger.info("OpenOCD server started successfully")
                return True
            else:
                logger.error("Failed to connect to telnet interface")
                self.stop_server()
                return False

        except Exception as e:
            logger.error(f"Failed to start OpenOCD: {e}")
            return False

    def stop_server(self) -> None:
        """Stop OpenOCD server"""
        if self.telnet_socket:
            try:
                self.telnet_socket.close()
            except:
                pass
            self.telnet_socket = None

        if self.process:
            try:
                self.process.terminate()
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
            self.process = None

        logger.info("OpenOCD server stopped")

    def _connect_telnet(self, timeout: float = 5.0) -> bool:
        """Connect to OpenOCD telnet interface"""
        try:
            self.telnet_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.telnet_socket.settimeout(timeout)
            self.telnet_socket.connect(("localhost", self.telnet_port))

            self.telnet_socket.recv(4096)

            return True

        except Exception as e:
            logger.error(f"Telnet connection failed: {e}")
            return False

    def send_command(self, command: str) -> str:
        """
        Send command to OpenOCD

        Args:
            command: OpenOCD command

        Returns:
            Command output
        """
        if not self.telnet_socket:
            raise RuntimeError("Not connected to OpenOCD")

        try:
            self.telnet_socket.send(f"{command}\n".encode())
            time.sleep(0.1)

            response = self.telnet_socket.recv(4096).decode()

            response = response.replace("> ", "").strip()

            logger.debug(f"Command: {command} -> {response[:100]}")
            return response

        except Exception as e:
            logger.error(f"Command failed: {e}")
            return ""

    def reset_target(self, halt: bool = True) -> bool:
        """
        Reset target CPU

        Args:
            halt: Halt after reset

        Returns:
            True if successful
        """
        try:
            if halt:
                response = self.send_command("reset halt")
            else:
                response = self.send_command("reset run")

            return "error" not in response.lower()

        except Exception as e:
            logger.error(f"Reset failed: {e}")
            return False

    def halt_target(self) -> bool:
        """Halt target CPU"""
        try:
            response = self.send_command("halt")
            return "error" not in response.lower()
        except Exception as e:
            logger.error(f"Halt failed: {e}")
            return False

    def resume_target(self) -> bool:
        """Resume target CPU"""
        try:
            response = self.send_command("resume")
            return "error" not in response.lower()
        except Exception as e:
            logger.error(f"Resume failed: {e}")
            return False

    def get_target_state(self) -> TargetState:
        """Get current target state"""
        try:
            response = self.send_command("capture \"poll\"")

            if "running" in response.lower():
                return TargetState.RUNNING
            elif "halted" in response.lower():
                return TargetState.HALTED
            elif "reset" in response.lower():
                return TargetState.RESET
            else:
                return TargetState.UNKNOWN

        except Exception as e:
            logger.error(f"Failed to get target state: {e}")
            return TargetState.UNKNOWN

    def flash_firmware(
        self,
        firmware_file: Path,
        address: int = 0x08000000,
        verify: bool = True
    ) -> bool:
        """
        Flash firmware to target

        Args:
            firmware_file: Firmware file (bin, hex, elf)
            address: Flash address
            verify: Verify after programming

        Returns:
            True if successful
        """
        if not firmware_file.exists():
            raise FileNotFoundError(f"Firmware file not found: {firmware_file}")

        logger.info(f"Flashing {firmware_file} to 0x{address:08X}")

        try:
            self.send_command("halt")

            suffix = firmware_file.suffix.lower()

            if suffix == ".bin":
                cmd = f"program {firmware_file} 0x{address:08X} verify reset"
            else:
                cmd = f"program {firmware_file} verify reset"

            response = self.send_command(cmd)

            if "error" in response.lower() or "failed" in response.lower():
                logger.error(f"Flash failed: {response}")
                return False

            logger.info("Flash completed successfully")
            return True

        except Exception as e:
            logger.error(f"Flash operation failed: {e}")
            return False

    def read_memory(
        self,
        address: int,
        size: int,
        width: int = 32
    ) -> Optional[bytes]:
        """
        Read memory from target

        Args:
            address: Memory address
            size: Number of bytes to read
            width: Access width (8, 16, 32)

        Returns:
            Memory content or None
        """
        try:
            if width == 8:
                cmd = f"mdb"
            elif width == 16:
                cmd = f"mdh"
            elif width == 32:
                cmd = f"mdw"
            else:
                raise ValueError(f"Invalid width: {width}")

            count = size // (width // 8)
            response = self.send_command(f"{cmd} 0x{address:08X} {count}")

            data = bytearray()
            for line in response.split("\n"):
                if "0x" in line:
                    values = line.split(":")[1].strip().split()
                    for val in values:
                        val_int = int(val, 16)
                        data.extend(val_int.to_bytes(width // 8, byteorder="little"))

            return bytes(data[:size])

        except Exception as e:
            logger.error(f"Memory read failed: {e}")
            return None

    def write_memory(
        self,
        address: int,
        data: bytes,
        width: int = 32
    ) -> bool:
        """
        Write memory to target

        Args:
            address: Memory address
            data: Data to write
            width: Access width (8, 16, 32)

        Returns:
            True if successful
        """
        try:
            if width == 8:
                cmd_prefix = "mwb"
            elif width == 16:
                cmd_prefix = "mwh"
            elif width == 32:
                cmd_prefix = "mww"
            else:
                raise ValueError(f"Invalid width: {width}")

            bytes_per_word = width // 8
            current_addr = address

            for i in range(0, len(data), bytes_per_word):
                word_bytes = data[i:i+bytes_per_word]

                while len(word_bytes) < bytes_per_word:
                    word_bytes += b'\x00'

                value = int.from_bytes(word_bytes, byteorder="little")

                cmd = f"{cmd_prefix} 0x{current_addr:08X} 0x{value:0{width//4}X}"
                response = self.send_command(cmd)

                if "error" in response.lower():
                    logger.error(f"Write failed at 0x{current_addr:08X}")
                    return False

                current_addr += bytes_per_word

            logger.info(f"Written {len(data)} bytes to 0x{address:08X}")
            return True

        except Exception as e:
            logger.error(f"Memory write failed: {e}")
            return False

    def set_breakpoint(self, address: int) -> Optional[int]:
        """
        Set breakpoint

        Args:
            address: Breakpoint address

        Returns:
            Breakpoint number or None
        """
        try:
            response = self.send_command(f"bp 0x{address:08X} 2 hw")

            if "error" not in response.lower():
                logger.info(f"Breakpoint set at 0x{address:08X}")
                return 0
            else:
                logger.error(f"Failed to set breakpoint: {response}")
                return None

        except Exception as e:
            logger.error(f"Breakpoint setting failed: {e}")
            return None

    def remove_breakpoint(self, address: int) -> bool:
        """Remove breakpoint"""
        try:
            response = self.send_command(f"rbp 0x{address:08X}")
            return "error" not in response.lower()

        except Exception as e:
            logger.error(f"Breakpoint removal failed: {e}")
            return False

    def step_instruction(self) -> bool:
        """Execute single instruction"""
        try:
            response = self.send_command("step")
            return "error" not in response.lower()
        except Exception as e:
            logger.error(f"Step failed: {e}")
            return False

    def read_register(self, register: str) -> Optional[int]:
        """
        Read CPU register

        Args:
            register: Register name (r0-r15, pc, sp, etc.)

        Returns:
            Register value or None
        """
        try:
            response = self.send_command(f"reg {register}")

            match = re.search(r"0x([0-9a-fA-F]+)", response)
            if match:
                return int(match.group(1), 16)

            return None

        except Exception as e:
            logger.error(f"Register read failed: {e}")
            return None

    def write_register(self, register: str, value: int) -> bool:
        """
        Write CPU register

        Args:
            register: Register name
            value: New value

        Returns:
            True if successful
        """
        try:
            response = self.send_command(f"reg {register} 0x{value:08X}")
            return "error" not in response.lower()

        except Exception as e:
            logger.error(f"Register write failed: {e}")
            return False

    def __del__(self):
        """Cleanup on destruction"""
        self.stop_server()

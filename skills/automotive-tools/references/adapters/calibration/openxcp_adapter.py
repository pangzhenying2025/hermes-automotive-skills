#!/usr/bin/env python3
"""
OpenXCP Adapter
Opensource XCP (Universal Measurement and Calibration Protocol) implementation
"""

import socket
import struct
import threading
import time
from pathlib import Path
from typing import Dict, List, Optional, Any, Callable
from enum import Enum
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)


class XCPCommand(Enum):
    """XCP command codes"""
    CONNECT = 0xFF
    DISCONNECT = 0xFE
    GET_STATUS = 0xFD
    SYNCH = 0xFC
    GET_ID = 0xFA
    SET_MTA = 0xF6
    UPLOAD = 0xF5
    SHORT_UPLOAD = 0xF4
    DOWNLOAD = 0xF0
    SHORT_DOWNLOAD = 0xED
    GET_DAQ_RESOLUTION_INFO = 0xD9
    GET_DAQ_PROCESSOR_INFO = 0xDA
    ALLOC_DAQ = 0xD5
    ALLOC_ODT = 0xD4
    ALLOC_ODT_ENTRY = 0xD3
    SET_DAQ_PTR = 0xE2
    WRITE_DAQ = 0xE1
    SET_DAQ_LIST_MODE = 0xE0
    START_STOP_DAQ_LIST = 0xDE
    START_STOP_SYNCH = 0xDD


class XCPResponseCode(Enum):
    """XCP response codes"""
    OK = 0xFF
    ERROR = 0xFE
    EVENT = 0xFD
    SERVICE = 0xFC


@dataclass
class XCPConnection:
    """XCP connection configuration"""
    host: str
    port: int
    protocol: str = "TCP"
    max_cto: int = 8
    max_dto: int = 8


@dataclass
class DAQList:
    """DAQ list configuration"""
    daq_number: int
    event_channel: int
    priority: int
    signals: List[Dict[str, Any]]


class OpenXCPAdapter:
    """
    Opensource XCP protocol implementation
    Supports calibration and measurement over Ethernet
    """

    def __init__(self):
        """Initialize OpenXCP adapter"""
        self.connection: Optional[XCPConnection] = None
        self.socket: Optional[socket.socket] = None
        self.connected = False
        self.session_status = 0
        self.resource_protection = 0
        self.lock = threading.Lock()
        self.daq_lists: Dict[int, DAQList] = {}

    def connect(
        self,
        host: str,
        port: int = 5555,
        protocol: str = "TCP",
        timeout: float = 5.0
    ) -> bool:
        """
        Connect to XCP slave

        Args:
            host: Slave host address
            port: Slave port
            protocol: Transport protocol
            timeout: Connection timeout

        Returns:
            True if connected
        """
        self.connection = XCPConnection(
            host=host,
            port=port,
            protocol=protocol
        )

        try:
            if protocol == "TCP":
                self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            elif protocol == "UDP":
                self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            else:
                raise ValueError(f"Unsupported protocol: {protocol}")

            self.socket.settimeout(timeout)
            self.socket.connect((host, port))

            response = self._send_command(XCPCommand.CONNECT, [0x00])

            if response[0] == XCPResponseCode.OK.value:
                self.connected = True
                self.connection.max_cto = response[3]
                self.connection.max_dto = response[4]
                logger.info(
                    f"Connected to XCP slave at {host}:{port} "
                    f"(MAX_CTO={self.connection.max_cto}, "
                    f"MAX_DTO={self.connection.max_dto})"
                )
                return True
            else:
                logger.error("XCP connect failed")
                return False

        except Exception as e:
            logger.error(f"Connection error: {e}")
            return False

    def disconnect(self) -> bool:
        """Disconnect from XCP slave"""
        if not self.connected:
            return True

        try:
            response = self._send_command(XCPCommand.DISCONNECT)

            if self.socket:
                self.socket.close()
                self.socket = None

            self.connected = False
            logger.info("Disconnected from XCP slave")
            return True

        except Exception as e:
            logger.error(f"Disconnect error: {e}")
            return False

    def _send_command(
        self,
        command: XCPCommand,
        data: Optional[List[int]] = None
    ) -> bytes:
        """
        Send XCP command and receive response

        Args:
            command: XCP command
            data: Command data bytes

        Returns:
            Response bytes
        """
        if not self.socket:
            raise RuntimeError("Not connected")

        data = data or []
        packet = bytes([command.value] + data)

        with self.lock:
            self.socket.send(packet)
            response = self.socket.recv(1024)

        return response

    def read_memory(
        self,
        address: int,
        length: int
    ) -> bytes:
        """
        Read memory from slave

        Args:
            address: Memory address
            length: Number of bytes to read

        Returns:
            Memory content
        """
        if not self.connected:
            raise RuntimeError("Not connected")

        self._set_mta(address)

        response = self._send_command(XCPCommand.UPLOAD, [length])

        if response[0] != XCPResponseCode.OK.value:
            raise RuntimeError(f"Upload failed: {response[1]}")

        return response[1:1+length]

    def write_memory(
        self,
        address: int,
        data: bytes
    ) -> bool:
        """
        Write memory to slave

        Args:
            address: Memory address
            data: Data to write

        Returns:
            True if successful
        """
        if not self.connected:
            raise RuntimeError("Not connected")

        self._set_mta(address)

        chunk_size = self.connection.max_cto - 2
        for i in range(0, len(data), chunk_size):
            chunk = data[i:i+chunk_size]
            response = self._send_command(
                XCPCommand.DOWNLOAD,
                [len(chunk)] + list(chunk)
            )

            if response[0] != XCPResponseCode.OK.value:
                logger.error(f"Download failed at offset {i}")
                return False

        logger.info(f"Written {len(data)} bytes to 0x{address:08X}")
        return True

    def _set_mta(self, address: int) -> None:
        """Set Memory Transfer Address"""
        addr_bytes = struct.pack(">I", address)
        response = self._send_command(
            XCPCommand.SET_MTA,
            [0, 0] + list(addr_bytes)
        )

        if response[0] != XCPResponseCode.OK.value:
            raise RuntimeError(f"SET_MTA failed for address 0x{address:08X}")

    def read_parameter(
        self,
        address: int,
        data_type: str
    ) -> Any:
        """
        Read calibration parameter

        Args:
            address: Parameter address
            data_type: Data type (UBYTE, UWORD, ULONG, FLOAT32, etc.)

        Returns:
            Parameter value
        """
        type_sizes = {
            "UBYTE": 1, "SBYTE": 1,
            "UWORD": 2, "SWORD": 2,
            "ULONG": 4, "SLONG": 4,
            "FLOAT32": 4, "FLOAT64": 8
        }

        size = type_sizes.get(data_type, 4)
        data = self.read_memory(address, size)

        type_formats = {
            "UBYTE": "B", "SBYTE": "b",
            "UWORD": "H", "SWORD": "h",
            "ULONG": "I", "SLONG": "i",
            "FLOAT32": "f", "FLOAT64": "d"
        }

        fmt = type_formats.get(data_type, "I")
        value = struct.unpack(f">{fmt}", data)[0]

        logger.debug(f"Read parameter at 0x{address:08X}: {value} ({data_type})")
        return value

    def write_parameter(
        self,
        address: int,
        value: Any,
        data_type: str
    ) -> bool:
        """
        Write calibration parameter

        Args:
            address: Parameter address
            value: New value
            data_type: Data type

        Returns:
            True if successful
        """
        type_formats = {
            "UBYTE": "B", "SBYTE": "b",
            "UWORD": "H", "SWORD": "h",
            "ULONG": "I", "SLONG": "i",
            "FLOAT32": "f", "FLOAT64": "d"
        }

        fmt = type_formats.get(data_type, "I")
        data = struct.pack(f">{fmt}", value)

        success = self.write_memory(address, data)

        if success:
            logger.info(
                f"Written parameter at 0x{address:08X}: {value} ({data_type})"
            )

        return success

    def setup_daq(
        self,
        daq_number: int,
        signals: List[Dict[str, Any]],
        event_channel: int = 0,
        priority: int = 0
    ) -> bool:
        """
        Setup DAQ list for measurement

        Args:
            daq_number: DAQ list number
            signals: List of signals to measure
            event_channel: Event channel number
            priority: DAQ priority

        Returns:
            True if successful
        """
        if not self.connected:
            raise RuntimeError("Not connected")

        response = self._send_command(
            XCPCommand.ALLOC_DAQ,
            [0, len(signals)]
        )

        if response[0] != XCPResponseCode.OK.value:
            logger.error("Failed to allocate DAQ")
            return False

        for odt_num in range(len(signals)):
            response = self._send_command(
                XCPCommand.ALLOC_ODT,
                [daq_number, odt_num, 1]
            )

            if response[0] != XCPResponseCode.OK.value:
                logger.error(f"Failed to allocate ODT {odt_num}")
                return False

        for idx, signal in enumerate(signals):
            self._add_daq_entry(daq_number, idx, signal)

        daq_list = DAQList(
            daq_number=daq_number,
            event_channel=event_channel,
            priority=priority,
            signals=signals
        )

        self.daq_lists[daq_number] = daq_list

        logger.info(f"DAQ list {daq_number} configured with {len(signals)} signals")
        return True

    def _add_daq_entry(
        self,
        daq_number: int,
        odt_number: int,
        signal: Dict[str, Any]
    ) -> None:
        """Add signal to DAQ list"""
        address = signal.get("address", 0)
        size = signal.get("size", 4)

        response = self._send_command(
            XCPCommand.SET_DAQ_PTR,
            [daq_number, odt_number, 0]
        )

        if response[0] != XCPResponseCode.OK.value:
            raise RuntimeError("Failed to set DAQ pointer")

        addr_bytes = struct.pack(">I", address)
        response = self._send_command(
            XCPCommand.WRITE_DAQ,
            [0xFF, size, 0] + list(addr_bytes)
        )

        if response[0] != XCPResponseCode.OK.value:
            raise RuntimeError("Failed to write DAQ")

    def start_daq(self, daq_number: int) -> bool:
        """Start DAQ measurement"""
        if not self.connected:
            raise RuntimeError("Not connected")

        response = self._send_command(
            XCPCommand.SET_DAQ_LIST_MODE,
            [0x10, daq_number, 0, 0, 0]
        )

        if response[0] != XCPResponseCode.OK.value:
            logger.error("Failed to set DAQ list mode")
            return False

        response = self._send_command(
            XCPCommand.START_STOP_DAQ_LIST,
            [0x02, daq_number]
        )

        if response[0] != XCPResponseCode.OK.value:
            logger.error("Failed to start DAQ list")
            return False

        logger.info(f"Started DAQ list {daq_number}")
        return True

    def stop_daq(self, daq_number: int) -> bool:
        """Stop DAQ measurement"""
        if not self.connected:
            raise RuntimeError("Not connected")

        response = self._send_command(
            XCPCommand.START_STOP_DAQ_LIST,
            [0x00, daq_number]
        )

        if response[0] == XCPResponseCode.OK.value:
            logger.info(f"Stopped DAQ list {daq_number}")
            return True
        else:
            logger.error("Failed to stop DAQ list")
            return False

    def get_status(self) -> Dict[str, Any]:
        """Get XCP slave status"""
        if not self.connected:
            return {"connected": False}

        response = self._send_command(XCPCommand.GET_STATUS)

        if response[0] == XCPResponseCode.OK.value:
            return {
                "connected": True,
                "session_status": response[1],
                "resource_protection": response[2],
                "session_config_id": response[3]
            }

        return {"connected": False}

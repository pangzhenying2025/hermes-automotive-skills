"""
DLT (Diagnostic Log and Trace) Adapter for Automotive Logging.

This module implements the AUTOSAR DLT protocol for distributed automotive logging,
enabling communication with DLT daemon and DLT Viewer tools.

Compliance: AUTOSAR DLT Protocol v1.0

Author: Automotive Claude Code Agents
License: MIT
"""

import socket
import struct
import time
import logging
import threading
from enum import IntEnum
from typing import Optional, Dict, Any, List, Callable
from pathlib import Path
from datetime import datetime
import json


class DLTLogLevel(IntEnum):
    """DLT log levels according to AUTOSAR spec."""
    FATAL = 0x01
    ERROR = 0x02
    WARN = 0x03
    INFO = 0x04
    DEBUG = 0x05
    VERBOSE = 0x06


class DLTMessageType(IntEnum):
    """DLT message types."""
    LOG = 0x00
    APP_TRACE = 0x01
    NW_TRACE = 0x02
    CONTROL = 0x03


class DLTMode(IntEnum):
    """DLT transmission modes."""
    NON_VERBOSE = 0
    VERBOSE = 1


class DLTStorageHeader:
    """DLT storage header (when logging to file)."""

    PATTERN = b'DLT\x01'
    SIZE = 16

    def __init__(self, timestamp: Optional[float] = None, ecu_id: str = "ECU1"):
        """
        Initialize storage header.

        Args:
            timestamp: Unix timestamp (seconds since epoch)
            ecu_id: ECU identifier (max 4 chars)
        """
        self.timestamp = timestamp or time.time()
        self.ecu_id = ecu_id[:4].ljust(4, '\x00')

    def encode(self) -> bytes:
        """
        Encode storage header to bytes.

        Returns:
            16-byte storage header
        """
        seconds = int(self.timestamp)
        microseconds = int((self.timestamp - seconds) * 1_000_000)

        ecu_bytes = self.ecu_id.encode('ascii')[:4].ljust(4, b'\x00')

        return struct.pack(
            '4sII4s',
            self.PATTERN,
            seconds,
            microseconds,
            ecu_bytes
        )


class DLTStandardHeader:
    """DLT standard header (mandatory)."""

    def __init__(
        self,
        use_ecu_id: bool = True,
        use_session_id: bool = False,
        use_timestamp: bool = True,
        message_counter: int = 0,
        ecu_id: str = "ECU1"
    ):
        """
        Initialize standard header.

        Args:
            use_ecu_id: Include ECU ID in header
            use_session_id: Include session ID in header
            use_timestamp: Include timestamp in header
            message_counter: Message counter (0-255)
            ecu_id: ECU identifier (max 4 chars)
        """
        self.use_ecu_id = use_ecu_id
        self.use_session_id = use_session_id
        self.use_timestamp = use_timestamp
        self.message_counter = message_counter & 0xFF
        self.ecu_id = ecu_id[:4].ljust(4, '\x00')
        self.session_id = 0
        # Timestamp in 0.1ms resolution, must be 32-bit unsigned
        self.timestamp = int((time.time() % 4294967) * 10000) & 0xFFFFFFFF

    def encode(self) -> bytes:
        """
        Encode standard header to bytes.

        Returns:
            Variable-length standard header
        """
        # Header type (HTYP)
        htyp = 0x20  # Use standard header
        if self.use_ecu_id:
            htyp |= 0x04
        if self.use_session_id:
            htyp |= 0x08
        if self.use_timestamp:
            htyp |= 0x10
        htyp |= 0x01  # Version number 1

        # Build header
        header = struct.pack('BB', htyp, self.message_counter)

        # Length will be filled by message encoder
        header += b'\x00\x00'

        if self.use_ecu_id:
            header += self.ecu_id.encode('ascii')[:4].ljust(4, b'\x00')

        if self.use_session_id:
            header += struct.pack('I', self.session_id)

        if self.use_timestamp:
            header += struct.pack('I', self.timestamp)

        return header


class DLTExtendedHeader:
    """DLT extended header (optional, for verbose mode)."""

    def __init__(
        self,
        message_info: int,
        app_id: str,
        context_id: str,
        verbose: bool = True
    ):
        """
        Initialize extended header.

        Args:
            message_info: Message info byte (type, subtype, mode)
            app_id: Application ID (max 4 chars)
            context_id: Context ID (max 4 chars)
            verbose: Use verbose mode
        """
        self.message_info = message_info
        self.app_id = app_id[:4].ljust(4, '\x00')
        self.context_id = context_id[:4].ljust(4, '\x00')
        self.verbose = verbose

    def encode(self) -> bytes:
        """
        Encode extended header to bytes.

        Returns:
            10-byte extended header
        """
        # MSIN (Message Info)
        msin = self.message_info
        if self.verbose:
            msin |= 0x01  # Verbose mode

        return struct.pack(
            'B',
            msin
        ) + b'\x00' + self.app_id.encode('ascii')[:4].ljust(4, b'\x00') + \
            self.context_id.encode('ascii')[:4].ljust(4, b'\x00')


class DLTMessage:
    """Complete DLT message with headers and payload."""

    def __init__(
        self,
        app_id: str,
        context_id: str,
        log_level: DLTLogLevel,
        payload: str,
        ecu_id: str = "ECU1",
        message_counter: int = 0,
        verbose: bool = True
    ):
        """
        Initialize DLT message.

        Args:
            app_id: Application ID (max 4 chars)
            context_id: Context ID (max 4 chars)
            log_level: Log level
            payload: Log message text
            ecu_id: ECU identifier
            message_counter: Message counter
            verbose: Use verbose mode
        """
        self.app_id = app_id
        self.context_id = context_id
        self.log_level = log_level
        self.payload = payload
        self.ecu_id = ecu_id
        self.message_counter = message_counter
        self.verbose = verbose

    def encode(self, include_storage_header: bool = False) -> bytes:
        """
        Encode complete DLT message.

        Args:
            include_storage_header: Include storage header for file logging

        Returns:
            Complete DLT message as bytes
        """
        message = b''

        # Storage header (for file logging)
        if include_storage_header:
            storage_header = DLTStorageHeader(ecu_id=self.ecu_id)
            message += storage_header.encode()

        # Standard header
        std_header = DLTStandardHeader(
            use_ecu_id=True,
            use_session_id=False,
            use_timestamp=True,
            message_counter=self.message_counter,
            ecu_id=self.ecu_id
        )
        std_header_bytes = std_header.encode()

        # Extended header
        message_info = (DLTMessageType.LOG << 4) | (self.log_level & 0x0F)
        ext_header = DLTExtendedHeader(
            message_info=message_info,
            app_id=self.app_id,
            context_id=self.context_id,
            verbose=self.verbose
        )
        ext_header_bytes = ext_header.encode()

        # Payload
        if self.verbose:
            # Verbose mode: type info + data
            payload_bytes = self._encode_verbose_payload()
        else:
            # Non-verbose mode: raw data
            payload_bytes = self.payload.encode('utf-8')

        # Calculate total length (standard header + extended header + payload)
        total_length = len(std_header_bytes) + len(ext_header_bytes) + len(payload_bytes)

        # Update length field in standard header
        std_header_bytes = std_header_bytes[:2] + struct.pack('>H', total_length) + std_header_bytes[4:]

        # Combine all parts
        message += std_header_bytes + ext_header_bytes + payload_bytes

        return message

    def _encode_verbose_payload(self) -> bytes:
        """
        Encode payload in verbose mode with type information.

        Returns:
            Encoded payload
        """
        # Type info for string: 0x00 (string) | 0x00 (ASCII) | length
        payload_str = self.payload.encode('utf-8')

        # Number of arguments
        num_args = struct.pack('B', 1)

        # Type info: 32-bit for type + string length
        type_info = struct.pack('I', 0x00000200 | (len(payload_str) << 16))

        return num_args + type_info + payload_str


class DLTAdapter:
    """
    Main DLT adapter for automotive logging.

    Features:
    - AUTOSAR DLT protocol implementation
    - Network transmission (TCP/UDP)
    - File logging in DLT format
    - Integration with Python logging
    - Context and application ID management
    """

    def __init__(
        self,
        app_id: str,
        context_id: str,
        ecu_id: str = "ECU1",
        daemon_host: str = "localhost",
        daemon_port: int = 3490,
        verbose_mode: bool = True,
        use_network: bool = True,
        log_file: Optional[str] = None
    ):
        """
        Initialize DLT adapter.

        Args:
            app_id: Application ID (max 4 chars, e.g., "ADAS")
            context_id: Context ID (max 4 chars, e.g., "CTRL")
            ecu_id: ECU identifier (max 4 chars)
            daemon_host: DLT daemon hostname
            daemon_port: DLT daemon port (default: 3490)
            verbose_mode: Use verbose mode
            use_network: Enable network transmission
            log_file: Optional file path for DLT file logging
        """
        self.app_id = app_id[:4].upper()
        self.context_id = context_id[:4].upper()
        self.ecu_id = ecu_id[:4].upper()
        self.daemon_host = daemon_host
        self.daemon_port = daemon_port
        self.verbose_mode = verbose_mode
        self.use_network = use_network
        self.log_file = log_file

        self.message_counter = 0
        self.socket: Optional[socket.socket] = None
        self.file_handle: Optional[Any] = None
        self.lock = threading.Lock()
        self.logger = logging.getLogger(f"DLT.{app_id}.{context_id}")

        # Initialize connections
        if self.use_network:
            self._connect_daemon()

        if self.log_file:
            self._open_log_file()

    def _connect_daemon(self):
        """Connect to DLT daemon via TCP."""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.daemon_host, self.daemon_port))
            self.logger.info(f"Connected to DLT daemon at {self.daemon_host}:{self.daemon_port}")
        except Exception as e:
            self.logger.warning(f"Failed to connect to DLT daemon: {e}")
            self.socket = None

    def _open_log_file(self):
        """Open DLT log file for writing."""
        try:
            log_path = Path(self.log_file)
            log_path.parent.mkdir(parents=True, exist_ok=True)
            self.file_handle = open(log_path, 'ab')
            self.logger.info(f"Opened DLT log file: {self.log_file}")
        except Exception as e:
            self.logger.error(f"Failed to open log file: {e}")
            self.file_handle = None

    def _send_message(self, message: DLTMessage):
        """
        Send DLT message to daemon and/or file.

        Args:
            message: DLT message to send
        """
        with self.lock:
            # Send to network
            if self.use_network and self.socket:
                try:
                    data = message.encode(include_storage_header=False)
                    self.socket.sendall(data)
                except Exception as e:
                    self.logger.error(f"Failed to send to DLT daemon: {e}")
                    # Try to reconnect
                    self._connect_daemon()

            # Write to file
            if self.file_handle:
                try:
                    data = message.encode(include_storage_header=True)
                    self.file_handle.write(data)
                    self.file_handle.flush()
                except Exception as e:
                    self.logger.error(f"Failed to write to log file: {e}")

            # Increment message counter
            self.message_counter = (self.message_counter + 1) % 256

    def log(self, level: DLTLogLevel, message: str, **kwargs):
        """
        Send log message with specified level.

        Args:
            level: DLT log level
            message: Log message text
            **kwargs: Additional context (added to message)
        """
        # Add kwargs to message
        if kwargs:
            message = f"{message} | {json.dumps(kwargs)}"

        dlt_message = DLTMessage(
            app_id=self.app_id,
            context_id=self.context_id,
            log_level=level,
            payload=message,
            ecu_id=self.ecu_id,
            message_counter=self.message_counter,
            verbose=self.verbose_mode
        )

        self._send_message(dlt_message)

    def log_fatal(self, message: str, **kwargs):
        """Log FATAL level message."""
        self.log(DLTLogLevel.FATAL, message, **kwargs)

    def log_error(self, message: str, **kwargs):
        """Log ERROR level message."""
        self.log(DLTLogLevel.ERROR, message, **kwargs)

    def log_warn(self, message: str, **kwargs):
        """Log WARN level message."""
        self.log(DLTLogLevel.WARN, message, **kwargs)

    def log_info(self, message: str, **kwargs):
        """Log INFO level message."""
        self.log(DLTLogLevel.INFO, message, **kwargs)

    def log_debug(self, message: str, **kwargs):
        """Log DEBUG level message."""
        self.log(DLTLogLevel.DEBUG, message, **kwargs)

    def log_verbose(self, message: str, **kwargs):
        """Log VERBOSE level message."""
        self.log(DLTLogLevel.VERBOSE, message, **kwargs)

    def close(self):
        """Close all connections and file handles."""
        if self.socket:
            try:
                self.socket.close()
                self.logger.info("Closed DLT daemon connection")
            except Exception as e:
                self.logger.error(f"Error closing socket: {e}")

        if self.file_handle:
            try:
                self.file_handle.close()
                self.logger.info("Closed DLT log file")
            except Exception as e:
                self.logger.error(f"Error closing file: {e}")

    def __enter__(self):
        """Context manager entry."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()


class DLTLoggingHandler(logging.Handler):
    """
    Python logging handler that forwards to DLT.

    Usage:
        handler = DLTLoggingHandler(app_id="MYAPP", context_id="MAIN")
        logger = logging.getLogger("my_module")
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)
    """

    LEVEL_MAPPING = {
        logging.CRITICAL: DLTLogLevel.FATAL,
        logging.ERROR: DLTLogLevel.ERROR,
        logging.WARNING: DLTLogLevel.WARN,
        logging.INFO: DLTLogLevel.INFO,
        logging.DEBUG: DLTLogLevel.DEBUG,
        logging.NOTSET: DLTLogLevel.VERBOSE
    }

    def __init__(
        self,
        app_id: str,
        context_id: str,
        ecu_id: str = "ECU1",
        daemon_host: str = "localhost",
        daemon_port: int = 3490,
        log_file: Optional[str] = None
    ):
        """
        Initialize DLT logging handler.

        Args:
            app_id: Application ID
            context_id: Context ID
            ecu_id: ECU identifier
            daemon_host: DLT daemon hostname
            daemon_port: DLT daemon port
            log_file: Optional file path for DLT file logging
        """
        super().__init__()
        self.dlt_adapter = DLTAdapter(
            app_id=app_id,
            context_id=context_id,
            ecu_id=ecu_id,
            daemon_host=daemon_host,
            daemon_port=daemon_port,
            log_file=log_file
        )

    def emit(self, record: logging.LogRecord):
        """
        Emit a log record to DLT.

        Args:
            record: Python logging record
        """
        try:
            dlt_level = self.LEVEL_MAPPING.get(record.levelno, DLTLogLevel.INFO)
            message = self.format(record)

            # Extract additional context
            kwargs = {}
            if hasattr(record, 'funcName'):
                kwargs['function'] = record.funcName
            if hasattr(record, 'lineno'):
                kwargs['line'] = record.lineno

            self.dlt_adapter.log(dlt_level, message, **kwargs)
        except Exception:
            self.handleError(record)

    def close(self):
        """Close DLT adapter."""
        self.dlt_adapter.close()
        super().close()

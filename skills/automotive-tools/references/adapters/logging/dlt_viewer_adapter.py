"""
DLT Viewer Adapter for Parsing and Analyzing DLT Log Files.

This module provides tools to read, filter, and export DLT log files,
compatible with COVESA DLT Viewer format.

Author: Automotive Claude Code Agents
License: MIT
"""

import struct
from dataclasses import dataclass
from typing import List, Optional, Dict, Any, BinaryIO, Iterator
from pathlib import Path
from datetime import datetime
import json
import csv
from enum import IntEnum


class DLTLogLevel(IntEnum):
    """DLT log levels."""
    FATAL = 0x01
    ERROR = 0x02
    WARN = 0x03
    INFO = 0x04
    DEBUG = 0x05
    VERBOSE = 0x06


@dataclass
class DLTLogEntry:
    """Parsed DLT log entry."""
    timestamp: float
    ecu_id: str
    app_id: str
    context_id: str
    log_level: DLTLogLevel
    message: str
    message_counter: int
    session_id: Optional[int] = None
    raw_data: Optional[bytes] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            'timestamp': self.timestamp,
            'datetime': datetime.fromtimestamp(self.timestamp).isoformat(),
            'ecu_id': self.ecu_id,
            'app_id': self.app_id,
            'context_id': self.context_id,
            'log_level': self.log_level.name,
            'message': self.message,
            'message_counter': self.message_counter,
            'session_id': self.session_id
        }

    def __str__(self) -> str:
        """String representation."""
        dt = datetime.fromtimestamp(self.timestamp)
        return f"[{dt.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]}] {self.ecu_id} {self.app_id}.{self.context_id} {self.log_level.name:8s} {self.message}"


class DLTParser:
    """
    Parser for DLT log files.

    Reads DLT files created by DLT daemon or DLTAdapter with storage headers.
    """

    STORAGE_PATTERN = b'DLT\x01'

    def __init__(self, file_path: str):
        """
        Initialize DLT parser.

        Args:
            file_path: Path to DLT log file
        """
        self.file_path = Path(file_path)
        if not self.file_path.exists():
            raise FileNotFoundError(f"DLT file not found: {file_path}")

    def parse(self) -> Iterator[DLTLogEntry]:
        """
        Parse DLT file and yield log entries.

        Yields:
            DLTLogEntry objects
        """
        with open(self.file_path, 'rb') as f:
            while True:
                try:
                    entry = self._parse_message(f)
                    if entry:
                        yield entry
                    else:
                        break
                except Exception as e:
                    # Skip corrupted messages
                    print(f"Warning: Skipping corrupted message: {e}")
                    continue

    def _parse_message(self, f: BinaryIO) -> Optional[DLTLogEntry]:
        """
        Parse single DLT message from file.

        Args:
            f: File handle

        Returns:
            Parsed log entry or None if EOF
        """
        # Read storage header (16 bytes)
        storage_header = f.read(16)
        if len(storage_header) < 16:
            return None

        pattern = storage_header[:4]
        if pattern != self.STORAGE_PATTERN:
            # Try to find next valid message
            return None

        seconds, microseconds, ecu_id_bytes = struct.unpack('II4s', storage_header[4:])
        timestamp = seconds + microseconds / 1_000_000
        ecu_id = ecu_id_bytes.decode('ascii').rstrip('\x00')

        # Read standard header (at least 4 bytes)
        std_header = f.read(4)
        if len(std_header) < 4:
            return None

        htyp, message_counter, length_bytes = struct.unpack('BBH', std_header)
        length = struct.unpack('>H', length_bytes.to_bytes(2, 'big'))[0]

        # Parse header flags
        use_ecu_id = bool(htyp & 0x04)
        use_session_id = bool(htyp & 0x08)
        use_timestamp = bool(htyp & 0x10)

        # Read optional fields
        session_id = None
        header_timestamp = None

        if use_ecu_id:
            ecu_id_bytes = f.read(4)
            if len(ecu_id_bytes) == 4:
                ecu_id = ecu_id_bytes.decode('ascii').rstrip('\x00')

        if use_session_id:
            session_bytes = f.read(4)
            if len(session_bytes) == 4:
                session_id = struct.unpack('I', session_bytes)[0]

        if use_timestamp:
            ts_bytes = f.read(4)
            if len(ts_bytes) == 4:
                header_timestamp = struct.unpack('I', ts_bytes)[0]

        # Calculate remaining payload length
        std_header_size = 4
        if use_ecu_id:
            std_header_size += 4
        if use_session_id:
            std_header_size += 4
        if use_timestamp:
            std_header_size += 4

        payload_length = length - std_header_size
        if payload_length < 0:
            return None

        # Read payload (extended header + data)
        payload = f.read(payload_length)
        if len(payload) < payload_length:
            return None

        # Parse extended header (10 bytes minimum)
        if len(payload) < 10:
            return None

        msin = payload[0]
        app_id = payload[2:6].decode('ascii').rstrip('\x00')
        context_id = payload[6:10].decode('ascii').rstrip('\x00')

        # Extract log level from MSIN
        log_level = DLTLogLevel(msin & 0x0F)

        # Parse message data
        verbose = bool(msin & 0x01)
        message_data = payload[10:]

        if verbose:
            message = self._parse_verbose_payload(message_data)
        else:
            message = message_data.decode('utf-8', errors='replace')

        return DLTLogEntry(
            timestamp=timestamp,
            ecu_id=ecu_id,
            app_id=app_id,
            context_id=context_id,
            log_level=log_level,
            message=message,
            message_counter=message_counter,
            session_id=session_id,
            raw_data=payload
        )

    def _parse_verbose_payload(self, data: bytes) -> str:
        """
        Parse verbose mode payload.

        Args:
            data: Payload bytes

        Returns:
            Decoded message string
        """
        if len(data) < 5:
            return ""

        try:
            num_args = data[0]
            offset = 1

            messages = []
            for _ in range(num_args):
                if offset + 4 > len(data):
                    break

                type_info = struct.unpack('I', data[offset:offset+4])[0]
                offset += 4

                # Extract string length from type info
                string_length = (type_info >> 16) & 0xFFFF

                if offset + string_length > len(data):
                    break

                string_data = data[offset:offset+string_length]
                messages.append(string_data.decode('utf-8', errors='replace'))
                offset += string_length

            return ' '.join(messages)
        except Exception:
            return data.decode('utf-8', errors='replace')


class DLTFilter:
    """
    Filter for DLT log entries.

    Supports filtering by app ID, context ID, log level, timestamp range, and text search.
    """

    def __init__(
        self,
        app_ids: Optional[List[str]] = None,
        context_ids: Optional[List[str]] = None,
        ecu_ids: Optional[List[str]] = None,
        log_levels: Optional[List[DLTLogLevel]] = None,
        min_level: Optional[DLTLogLevel] = None,
        start_time: Optional[float] = None,
        end_time: Optional[float] = None,
        text_search: Optional[str] = None,
        case_sensitive: bool = False
    ):
        """
        Initialize DLT filter.

        Args:
            app_ids: List of application IDs to include
            context_ids: List of context IDs to include
            ecu_ids: List of ECU IDs to include
            log_levels: Specific log levels to include
            min_level: Minimum log level (includes this and higher severity)
            start_time: Start timestamp (Unix time)
            end_time: End timestamp (Unix time)
            text_search: Text to search in messages
            case_sensitive: Case-sensitive text search
        """
        self.app_ids = [aid.upper() for aid in app_ids] if app_ids else None
        self.context_ids = [cid.upper() for cid in context_ids] if context_ids else None
        self.ecu_ids = [eid.upper() for eid in ecu_ids] if ecu_ids else None
        self.log_levels = log_levels
        self.min_level = min_level
        self.start_time = start_time
        self.end_time = end_time
        self.text_search = text_search
        self.case_sensitive = case_sensitive

    def matches(self, entry: DLTLogEntry) -> bool:
        """
        Check if log entry matches filter criteria.

        Args:
            entry: DLT log entry

        Returns:
            True if entry matches all criteria
        """
        # App ID filter
        if self.app_ids and entry.app_id.upper() not in self.app_ids:
            return False

        # Context ID filter
        if self.context_ids and entry.context_id.upper() not in self.context_ids:
            return False

        # ECU ID filter
        if self.ecu_ids and entry.ecu_id.upper() not in self.ecu_ids:
            return False

        # Log level filter
        if self.log_levels and entry.log_level not in self.log_levels:
            return False

        # Minimum level filter (lower value = higher severity)
        if self.min_level and entry.log_level > self.min_level:
            return False

        # Time range filter
        if self.start_time and entry.timestamp < self.start_time:
            return False
        if self.end_time and entry.timestamp > self.end_time:
            return False

        # Text search
        if self.text_search:
            search_text = self.text_search if self.case_sensitive else self.text_search.lower()
            message_text = entry.message if self.case_sensitive else entry.message.lower()
            if search_text not in message_text:
                return False

        return True


class DLTViewerAdapter:
    """
    Main adapter for viewing and analyzing DLT log files.

    Provides high-level interface for parsing, filtering, and exporting DLT logs.
    """

    def __init__(self, file_path: str):
        """
        Initialize DLT viewer adapter.

        Args:
            file_path: Path to DLT log file
        """
        self.file_path = file_path
        self.parser = DLTParser(file_path)

    def get_entries(
        self,
        filter_obj: Optional[DLTFilter] = None,
        limit: Optional[int] = None
    ) -> List[DLTLogEntry]:
        """
        Get log entries with optional filtering.

        Args:
            filter_obj: Optional filter to apply
            limit: Maximum number of entries to return

        Returns:
            List of log entries
        """
        entries = []
        count = 0

        for entry in self.parser.parse():
            if filter_obj and not filter_obj.matches(entry):
                continue

            entries.append(entry)
            count += 1

            if limit and count >= limit:
                break

        return entries

    def export_csv(
        self,
        output_path: str,
        filter_obj: Optional[DLTFilter] = None
    ):
        """
        Export logs to CSV format.

        Args:
            output_path: Output CSV file path
            filter_obj: Optional filter to apply
        """
        entries = self.get_entries(filter_obj)

        with open(output_path, 'w', newline='') as csvfile:
            fieldnames = ['timestamp', 'datetime', 'ecu_id', 'app_id', 'context_id',
                          'log_level', 'message_counter', 'session_id', 'message']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

            writer.writeheader()
            for entry in entries:
                writer.writerow(entry.to_dict())

    def export_json(
        self,
        output_path: str,
        filter_obj: Optional[DLTFilter] = None,
        pretty: bool = True
    ):
        """
        Export logs to JSON format.

        Args:
            output_path: Output JSON file path
            filter_obj: Optional filter to apply
            pretty: Pretty-print JSON
        """
        entries = self.get_entries(filter_obj)
        data = [entry.to_dict() for entry in entries]

        with open(output_path, 'w') as jsonfile:
            if pretty:
                json.dump(data, jsonfile, indent=2)
            else:
                json.dump(data, jsonfile)

    def get_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about the log file.

        Returns:
            Dictionary with statistics
        """
        entries = self.get_entries()

        if not entries:
            return {
                'total_entries': 0,
                'time_range': None,
                'app_ids': [],
                'context_ids': [],
                'ecu_ids': [],
                'log_levels': {}
            }

        # Collect statistics
        app_ids = set()
        context_ids = set()
        ecu_ids = set()
        log_levels = {}
        timestamps = []

        for entry in entries:
            app_ids.add(entry.app_id)
            context_ids.add(entry.context_id)
            ecu_ids.add(entry.ecu_id)
            timestamps.append(entry.timestamp)

            level_name = entry.log_level.name
            log_levels[level_name] = log_levels.get(level_name, 0) + 1

        return {
            'total_entries': len(entries),
            'time_range': {
                'start': datetime.fromtimestamp(min(timestamps)).isoformat(),
                'end': datetime.fromtimestamp(max(timestamps)).isoformat(),
                'duration_seconds': max(timestamps) - min(timestamps)
            },
            'app_ids': sorted(list(app_ids)),
            'context_ids': sorted(list(context_ids)),
            'ecu_ids': sorted(list(ecu_ids)),
            'log_levels': log_levels
        }

    def print_entries(
        self,
        filter_obj: Optional[DLTFilter] = None,
        limit: Optional[int] = 100
    ):
        """
        Print log entries to stdout.

        Args:
            filter_obj: Optional filter to apply
            limit: Maximum number of entries to print
        """
        entries = self.get_entries(filter_obj, limit)

        for entry in entries:
            print(entry)

        if limit and len(entries) >= limit:
            print(f"\n... (showing first {limit} entries)")

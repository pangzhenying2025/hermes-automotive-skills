#!/usr/bin/env python3
"""
SavvyCAN Adapter
Opensource CAN bus analyzer and DBC editor interface
"""

import subprocess
import csv
import json
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import struct
import time
import logging
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


@dataclass
class CANMessage:
    """CAN message representation"""
    timestamp: float
    can_id: int
    extended: bool
    data: bytes
    bus: str = "CAN1"


@dataclass
class DBCSignal:
    """DBC signal definition"""
    name: str
    start_bit: int
    length: int
    byte_order: str
    value_type: str
    factor: float
    offset: float
    minimum: float
    maximum: float
    unit: str
    receivers: List[str]


@dataclass
class DBCMessage:
    """DBC message definition"""
    message_id: int
    name: str
    dlc: int
    sender: str
    signals: List[DBCSignal]


class SavvyCANAdapter:
    """
    Adapter for SavvyCAN opensource CAN analyzer
    Provides DBC parsing, CAN logging, and replay capabilities
    """

    def __init__(self, savvycan_path: Optional[Path] = None):
        """
        Initialize SavvyCAN adapter

        Args:
            savvycan_path: Path to SavvyCAN installation
        """
        self.savvycan_path = savvycan_path or self._find_savvycan()
        self.dbc_databases: Dict[str, List[DBCMessage]] = {}
        self.simulation_mode = False

        if not self.savvycan_path.exists():
            logger.warning("SavvyCAN not found, using simulation mode")
            self.simulation_mode = True

    def _find_savvycan(self) -> Path:
        """Find SavvyCAN installation"""
        import os

        if "SAVVYCAN_PATH" in os.environ:
            return Path(os.environ["SAVVYCAN_PATH"])

        common_paths = [
            Path("/usr/local/bin/SavvyCAN"),
            Path("/usr/bin/SavvyCAN"),
            Path.home() / "SavvyCAN",
            Path("C:/Program Files/SavvyCAN")
        ]

        for path in common_paths:
            if path.exists():
                return path

        return Path.cwd() / "savvycan_mock"

    def parse_dbc(
        self,
        dbc_file: Path,
        database_name: Optional[str] = None
    ) -> List[DBCMessage]:
        """
        Parse DBC database file

        Args:
            dbc_file: Path to DBC file
            database_name: Database identifier

        Returns:
            List of parsed messages
        """
        if not dbc_file.exists():
            raise FileNotFoundError(f"DBC file not found: {dbc_file}")

        database_name = database_name or dbc_file.stem

        messages = []
        current_message = None
        current_signals = []

        with open(dbc_file, 'r') as f:
            for line in f:
                line = line.strip()

                if line.startswith("BO_"):
                    if current_message:
                        current_message.signals = current_signals
                        messages.append(current_message)
                        current_signals = []

                    parts = line.split()
                    msg_id = int(parts[1])
                    msg_name = parts[2].rstrip(":")
                    dlc = int(parts[3])
                    sender = parts[4] if len(parts) > 4 else "Unknown"

                    current_message = DBCMessage(
                        message_id=msg_id,
                        name=msg_name,
                        dlc=dlc,
                        sender=sender,
                        signals=[]
                    )

                elif line.startswith("SG_") and current_message:
                    signal = self._parse_dbc_signal(line)
                    if signal:
                        current_signals.append(signal)

        if current_message:
            current_message.signals = current_signals
            messages.append(current_message)

        self.dbc_databases[database_name] = messages
        logger.info(f"Parsed DBC: {len(messages)} messages from {dbc_file}")

        return messages

    def _parse_dbc_signal(self, line: str) -> Optional[DBCSignal]:
        """Parse DBC signal definition line"""
        try:
            parts = line.split()
            signal_name = parts[1]

            bit_info = parts[3].split("|")
            start_bit = int(bit_info[0])

            length_byte = bit_info[1].split("@")
            length = int(length_byte[0])
            byte_order = "little_endian" if length_byte[1].startswith("1") else "big_endian"
            value_type = "signed" if "-" in length_byte[1] else "unsigned"

            scaling_info = parts[4].strip("()").split(",")
            factor = float(scaling_info[0])
            offset = float(scaling_info[1])

            range_info = parts[5].strip("[]").split("|")
            minimum = float(range_info[0])
            maximum = float(range_info[1])

            unit = parts[6].strip('"') if len(parts) > 6 else ""
            receivers = parts[7].split(",") if len(parts) > 7 else []

            return DBCSignal(
                name=signal_name,
                start_bit=start_bit,
                length=length,
                byte_order=byte_order,
                value_type=value_type,
                factor=factor,
                offset=offset,
                minimum=minimum,
                maximum=maximum,
                unit=unit,
                receivers=receivers
            )

        except Exception as e:
            logger.warning(f"Failed to parse signal: {line} - {e}")
            return None

    def decode_message(
        self,
        can_message: CANMessage,
        database_name: str
    ) -> Dict[str, Any]:
        """
        Decode CAN message using DBC database

        Args:
            can_message: CAN message to decode
            database_name: DBC database to use

        Returns:
            Dictionary of signal values
        """
        if database_name not in self.dbc_databases:
            raise ValueError(f"Database not loaded: {database_name}")

        messages = self.dbc_databases[database_name]
        message_def = None

        for msg in messages:
            if msg.message_id == can_message.can_id:
                message_def = msg
                break

        if not message_def:
            logger.warning(f"Message ID 0x{can_message.can_id:X} not in database")
            return {}

        decoded_signals = {}

        for signal in message_def.signals:
            raw_value = self._extract_signal_value(
                can_message.data,
                signal.start_bit,
                signal.length,
                signal.byte_order,
                signal.value_type
            )

            physical_value = raw_value * signal.factor + signal.offset

            decoded_signals[signal.name] = {
                "value": physical_value,
                "raw": raw_value,
                "unit": signal.unit,
                "min": signal.minimum,
                "max": signal.maximum
            }

        return decoded_signals

    def _extract_signal_value(
        self,
        data: bytes,
        start_bit: int,
        length: int,
        byte_order: str,
        value_type: str
    ) -> int:
        """Extract signal value from CAN data"""
        data_int = int.from_bytes(data, byteorder="little")

        mask = (1 << length) - 1
        value = (data_int >> start_bit) & mask

        if value_type == "signed" and (value & (1 << (length - 1))):
            value -= (1 << length)

        return value

    def encode_message(
        self,
        message_name: str,
        signal_values: Dict[str, float],
        database_name: str
    ) -> CANMessage:
        """
        Encode CAN message from signal values

        Args:
            message_name: Message name
            signal_values: Dictionary of signal values
            database_name: DBC database to use

        Returns:
            Encoded CAN message
        """
        if database_name not in self.dbc_databases:
            raise ValueError(f"Database not loaded: {database_name}")

        messages = self.dbc_databases[database_name]
        message_def = None

        for msg in messages:
            if msg.name == message_name:
                message_def = msg
                break

        if not message_def:
            raise ValueError(f"Message not found: {message_name}")

        data = bytearray(message_def.dlc)

        for signal in message_def.signals:
            if signal.name in signal_values:
                physical_value = signal_values[signal.name]
                raw_value = int((physical_value - signal.offset) / signal.factor)

                self._insert_signal_value(
                    data,
                    raw_value,
                    signal.start_bit,
                    signal.length,
                    signal.byte_order
                )

        return CANMessage(
            timestamp=time.time(),
            can_id=message_def.message_id,
            extended=False,
            data=bytes(data)
        )

    def _insert_signal_value(
        self,
        data: bytearray,
        value: int,
        start_bit: int,
        length: int,
        byte_order: str
    ) -> None:
        """Insert signal value into CAN data"""
        mask = (1 << length) - 1
        value &= mask

        data_int = int.from_bytes(data, byteorder="little")
        data_int &= ~(mask << start_bit)
        data_int |= (value << start_bit)

        new_data = data_int.to_bytes(len(data), byteorder="little")
        data[:] = new_data

    def read_log_file(
        self,
        log_file: Path,
        file_format: str = "csv"
    ) -> List[CANMessage]:
        """
        Read CAN log file

        Args:
            log_file: Path to log file
            file_format: File format (csv, asc, blf)

        Returns:
            List of CAN messages
        """
        if not log_file.exists():
            raise FileNotFoundError(f"Log file not found: {log_file}")

        if file_format == "csv":
            return self._read_csv_log(log_file)
        elif file_format == "asc":
            return self._read_asc_log(log_file)
        else:
            raise ValueError(f"Unsupported format: {file_format}")

    def _read_csv_log(self, log_file: Path) -> List[CANMessage]:
        """Read CSV format CAN log"""
        messages = []

        with open(log_file, 'r') as f:
            reader = csv.DictReader(f)

            for row in reader:
                timestamp = float(row.get("Time", 0))
                can_id = int(row.get("ID", "0"), 16)
                data_str = row.get("Data", "")
                data = bytes.fromhex(data_str.replace(" ", ""))

                message = CANMessage(
                    timestamp=timestamp,
                    can_id=can_id,
                    extended=False,
                    data=data
                )

                messages.append(message)

        logger.info(f"Read {len(messages)} messages from {log_file}")
        return messages

    def _read_asc_log(self, log_file: Path) -> List[CANMessage]:
        """Read ASC format CAN log"""
        messages = []

        with open(log_file, 'r') as f:
            for line in f:
                line = line.strip()

                if not line or line.startswith("date"):
                    continue

                parts = line.split()

                if len(parts) < 4:
                    continue

                try:
                    timestamp = float(parts[0])
                    can_id = int(parts[2], 16)
                    data = bytes.fromhex("".join(parts[4:]))

                    message = CANMessage(
                        timestamp=timestamp,
                        can_id=can_id,
                        extended=False,
                        data=data
                    )

                    messages.append(message)

                except Exception as e:
                    logger.debug(f"Skipping line: {line} - {e}")
                    continue

        logger.info(f"Read {len(messages)} messages from {log_file}")
        return messages

    def write_log_file(
        self,
        messages: List[CANMessage],
        output_file: Path,
        file_format: str = "csv"
    ) -> Path:
        """
        Write CAN messages to log file

        Args:
            messages: List of messages to write
            output_file: Output file path
            file_format: File format

        Returns:
            Path to written file
        """
        if file_format == "csv":
            self._write_csv_log(messages, output_file)
        else:
            raise ValueError(f"Unsupported format: {file_format}")

        logger.info(f"Written {len(messages)} messages to {output_file}")
        return output_file

    def _write_csv_log(
        self,
        messages: List[CANMessage],
        output_file: Path
    ) -> None:
        """Write CSV format CAN log"""
        with open(output_file, 'w', newline='') as f:
            writer = csv.writer(f)
            writer.writerow(["Time", "Bus", "ID", "Extended", "DLC", "Data"])

            for msg in messages:
                writer.writerow([
                    f"{msg.timestamp:.6f}",
                    msg.bus,
                    f"0x{msg.can_id:X}",
                    "1" if msg.extended else "0",
                    len(msg.data),
                    msg.data.hex().upper()
                ])

    def filter_messages(
        self,
        messages: List[CANMessage],
        message_ids: Optional[List[int]] = None,
        time_range: Optional[Tuple[float, float]] = None
    ) -> List[CANMessage]:
        """
        Filter CAN messages

        Args:
            messages: Messages to filter
            message_ids: List of message IDs to keep
            time_range: (start_time, end_time) tuple

        Returns:
            Filtered messages
        """
        filtered = messages

        if message_ids:
            filtered = [m for m in filtered if m.can_id in message_ids]

        if time_range:
            start_time, end_time = time_range
            filtered = [
                m for m in filtered
                if start_time <= m.timestamp <= end_time
            ]

        logger.info(f"Filtered {len(messages)} -> {len(filtered)} messages")
        return filtered

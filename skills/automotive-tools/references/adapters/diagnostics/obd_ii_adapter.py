#!/usr/bin/env python3
"""
OBD-II Adapter - Automotive emissions and powertrain diagnostics
Implements SAE J1979 OBD-II protocol for passenger vehicles
"""

import time
import logging
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from enum import IntEnum

# Attempt to import obd library (python-OBD)
try:
    import obd
    OBD_AVAILABLE = True
except ImportError:
    OBD_AVAILABLE = False
    logging.warning("python-OBD not available - using simulation mode")


class ObdMode(IntEnum):
    """OBD-II Mode identifiers"""
    CURRENT_DATA = 0x01
    FREEZE_FRAME = 0x02
    SHOW_DTCS = 0x03
    CLEAR_DTCS = 0x04
    TEST_RESULTS_O2 = 0x05
    TEST_RESULTS = 0x06
    SHOW_PENDING_DTCS = 0x07
    CONTROL_OPERATION = 0x08
    VEHICLE_INFO = 0x09
    PERMANENT_DTCS = 0x0A


@dataclass
class ObdPidData:
    """OBD PID data with value and unit"""
    pid: int
    name: str
    value: Any
    unit: str
    raw_value: bytes


@dataclass
class ObdDtc:
    """OBD Diagnostic Trouble Code"""
    code: str
    description: str
    category: str  # P=Powertrain, C=Chassis, B=Body, U=Network


class ObdIIAdapter:
    """
    OBD-II Adapter for emissions and powertrain diagnostics

    Supports SAE J1979 protocol over multiple physical layers:
    - ISO 15765-4 (CAN)
    - ISO 14230-4 (KWP2000)
    - ISO 9141-2
    - SAE J1850 PWM/VPW
    """

    # Common PID definitions
    PIDS = {
        0x00: ("PIDs supported [01-20]", lambda x: x, "bitmap"),
        0x01: ("Monitor status", lambda x: x, "bitmap"),
        0x03: ("Fuel system status", lambda x: x, "bitmap"),
        0x04: ("Calculated engine load", lambda x: x[0] * 100 / 255, "%"),
        0x05: ("Engine coolant temperature", lambda x: x[0] - 40, "°C"),
        0x06: ("Short term fuel trim - Bank 1", lambda x: (x[0] - 128) * 100 / 128, "%"),
        0x07: ("Long term fuel trim - Bank 1", lambda x: (x[0] - 128) * 100 / 128, "%"),
        0x0C: ("Engine RPM", lambda x: ((x[0] * 256) + x[1]) / 4, "RPM"),
        0x0D: ("Vehicle speed", lambda x: x[0], "km/h"),
        0x0F: ("Intake air temperature", lambda x: x[0] - 40, "°C"),
        0x10: ("MAF air flow rate", lambda x: ((x[0] * 256) + x[1]) / 100, "g/s"),
        0x11: ("Throttle position", lambda x: x[0] * 100 / 255, "%"),
        0x1F: ("Run time since engine start", lambda x: (x[0] * 256) + x[1], "s"),
        0x21: ("Distance traveled with MIL on", lambda x: (x[0] * 256) + x[1], "km"),
        0x2F: ("Fuel tank level input", lambda x: x[0] * 100 / 255, "%"),
        0x33: ("Absolute barometric pressure", lambda x: x[0], "kPa"),
        0x42: ("Control module voltage", lambda x: ((x[0] * 256) + x[1]) / 1000, "V"),
        0x46: ("Ambient air temperature", lambda x: x[0] - 40, "°C"),
        0x49: ("Accelerator pedal position D", lambda x: x[0] * 100 / 255, "%"),
        0x4C: ("Commanded throttle actuator", lambda x: x[0] * 100 / 255, "%"),
        0x51: ("Fuel type", lambda x: x[0], "type"),
        0x5C: ("Engine oil temperature", lambda x: x[0] - 40, "°C"),
        0x5E: ("Engine fuel rate", lambda x: ((x[0] * 256) + x[1]) / 20, "L/h"),
    }

    # DTC database (sample - expand as needed)
    DTC_DATABASE = {
        "P0100": "Mass or Volume Air Flow Circuit Malfunction",
        "P0101": "Mass or Volume Air Flow Circuit Range/Performance Problem",
        "P0102": "Mass or Volume Air Flow Circuit Low Input",
        "P0103": "Mass or Volume Air Flow Circuit High Input",
        "P0171": "System Too Lean (Bank 1)",
        "P0172": "System Too Rich (Bank 1)",
        "P0300": "Random/Multiple Cylinder Misfire Detected",
        "P0301": "Cylinder 1 Misfire Detected",
        "P0302": "Cylinder 2 Misfire Detected",
        "P0303": "Cylinder 3 Misfire Detected",
        "P0304": "Cylinder 4 Misfire Detected",
        "P0420": "Catalyst System Efficiency Below Threshold (Bank 1)",
        "P0442": "Evaporative Emission Control System Leak Detected (Small Leak)",
        "P0456": "Evaporative Emission Control System Leak Detected (Very Small Leak)",
        "P0500": "Vehicle Speed Sensor Malfunction",
    }

    def __init__(self, port: Optional[str] = None, baudrate: int = 38400, simulation_mode: bool = False):
        """
        Initialize OBD-II adapter

        Args:
            port: Serial port (e.g., '/dev/ttyUSB0', 'COM3') or None for auto-detect
            baudrate: Serial baudrate (usually auto-detected)
            simulation_mode: Enable simulation mode for testing
        """
        self.logger = logging.getLogger(__name__)
        self.simulation_mode = simulation_mode or not OBD_AVAILABLE
        self.port = port
        self.baudrate = baudrate
        self.connection = None
        self.supported_pids = set()

        if not self.simulation_mode:
            self._initialize_connection()
        else:
            self.logger.warning("Running in simulation mode - no actual OBD communication")
            self._simulate_supported_pids()

    def _initialize_connection(self):
        """Initialize OBD connection"""
        try:
            if self.port:
                self.connection = obd.OBD(portstr=self.port, baudrate=self.baudrate)
            else:
                self.connection = obd.OBD()  # Auto-detect port

            if not self.connection.is_connected():
                raise Exception("Failed to connect to vehicle")

            self.logger.info(f"OBD connected: {self.connection.port_name()}")
            self._query_supported_pids()

        except Exception as e:
            raise Exception(f"Failed to initialize OBD connection: {e}")

    def _query_supported_pids(self):
        """Query which PIDs are supported by the vehicle"""
        # Query PID support bitmaps
        for support_pid in [0x00, 0x20, 0x40, 0x60, 0x80, 0xA0, 0xC0, 0xE0]:
            try:
                response = self.connection.query(obd.commands[support_pid])
                if response.value:
                    bitmap = int.from_bytes(response.value, 'big')
                    for bit in range(32):
                        if bitmap & (1 << (31 - bit)):
                            self.supported_pids.add(support_pid + bit + 1)
            except:
                break

        self.logger.info(f"Supported PIDs: {len(self.supported_pids)}")

    def _simulate_supported_pids(self):
        """Simulate supported PIDs for testing"""
        # Simulate common PIDs
        self.supported_pids = {0x01, 0x03, 0x04, 0x05, 0x0C, 0x0D, 0x0F, 0x10, 0x11, 0x1F, 0x21, 0x2F, 0x33, 0x42, 0x5E}

    def read_pid(self, pid: int, mode: int = ObdMode.CURRENT_DATA) -> Optional[ObdPidData]:
        """
        Read OBD PID value

        Args:
            pid: PID identifier (0x00-0xFF)
            mode: OBD mode (default: Mode 01 - Current Data)

        Returns:
            ObdPidData or None if PID not supported
        """
        if self.simulation_mode:
            return self._simulate_pid(pid)

        try:
            command = obd.commands[pid]
            response = self.connection.query(command)

            if response.is_null():
                return None

            pid_info = self.PIDS.get(pid, (f"PID_{pid:02X}", lambda x: x, "unknown"))

            return ObdPidData(
                pid=pid,
                name=pid_info[0],
                value=response.value.magnitude if hasattr(response.value, 'magnitude') else response.value,
                unit=str(response.value.units) if hasattr(response.value, 'units') else pid_info[2],
                raw_value=response.messages[0].data if response.messages else b''
            )

        except Exception as e:
            self.logger.error(f"Failed to read PID 0x{pid:02X}: {e}")
            return None

    def _simulate_pid(self, pid: int) -> Optional[ObdPidData]:
        """Simulate PID reading for testing"""
        if pid not in self.supported_pids:
            return None

        # Simulate realistic values
        simulated_values = {
            0x04: 45.5,  # Engine load %
            0x05: 85,    # Coolant temp °C
            0x0C: 2150,  # RPM
            0x0D: 65,    # Speed km/h
            0x0F: 25,    # Intake air temp °C
            0x10: 15.2,  # MAF g/s
            0x11: 32.5,  # Throttle position %
            0x1F: 1234,  # Run time s
            0x2F: 62.3,  # Fuel level %
            0x42: 14.2,  # Control module voltage V
            0x5E: 8.5,   # Fuel rate L/h
        }

        pid_info = self.PIDS.get(pid, (f"PID_{pid:02X}", lambda x: x, "unknown"))

        return ObdPidData(
            pid=pid,
            name=pid_info[0],
            value=simulated_values.get(pid, 0.0),
            unit=pid_info[2],
            raw_value=b'\x00\x00\x00\x00'
        )

    def read_dtcs(self) -> List[ObdDtc]:
        """
        Read emission-related DTCs (Mode 03)

        Returns:
            List of diagnostic trouble codes
        """
        if self.simulation_mode:
            return self._simulate_dtcs()

        try:
            response = self.connection.query(obd.commands.GET_DTC)

            if response.is_null():
                return []

            dtcs = []
            for code, description in response.value:
                category = code[0] if code else 'U'
                dtcs.append(ObdDtc(
                    code=code,
                    description=self.DTC_DATABASE.get(code, description),
                    category=category
                ))

            self.logger.info(f"Read {len(dtcs)} DTCs")
            return dtcs

        except Exception as e:
            self.logger.error(f"Failed to read DTCs: {e}")
            return []

    def _simulate_dtcs(self) -> List[ObdDtc]:
        """Simulate DTCs for testing"""
        return [
            ObdDtc("P0301", "Cylinder 1 Misfire Detected", "P"),
            ObdDtc("P0420", "Catalyst System Efficiency Below Threshold (Bank 1)", "P"),
        ]

    def clear_dtcs(self) -> bool:
        """
        Clear DTCs and reset MIL (Mode 04)

        Returns:
            True if DTCs cleared successfully
        """
        if self.simulation_mode:
            self.logger.info("[SIMULATION] DTCs cleared")
            return True

        try:
            response = self.connection.query(obd.commands.CLEAR_DTC)
            success = not response.is_null()

            if success:
                self.logger.info("DTCs cleared successfully")

            return success

        except Exception as e:
            self.logger.error(f"Failed to clear DTCs: {e}")
            return False

    def read_vin(self) -> Optional[str]:
        """
        Read Vehicle Identification Number (Mode 09, PID 02)

        Returns:
            17-character VIN or None
        """
        if self.simulation_mode:
            return "SIMULATION17CHAR0"

        try:
            response = self.connection.query(obd.commands.VIN)

            if response.is_null():
                return None

            return response.value

        except Exception as e:
            self.logger.error(f"Failed to read VIN: {e}")
            return None

    def read_readiness_monitors(self) -> Dict[str, Any]:
        """
        Read readiness monitor status (PID 01)

        Returns:
            Dictionary with MIL status and monitor readiness
        """
        if self.simulation_mode:
            return self._simulate_readiness()

        try:
            response = self.connection.query(obd.commands.STATUS)

            if response.is_null():
                return {}

            # Parse monitor status
            monitors = {
                'mil_on': bool(response.value.MIL),
                'dtc_count': response.value.DTC_count,
                'monitors': {}
            }

            # Add readiness monitors
            for monitor in response.value.tests:
                monitors['monitors'][monitor.name] = {
                    'available': monitor.available,
                    'complete': monitor.complete
                }

            return monitors

        except Exception as e:
            self.logger.error(f"Failed to read readiness monitors: {e}")
            return {}

    def _simulate_readiness(self) -> Dict[str, Any]:
        """Simulate readiness monitor status"""
        return {
            'mil_on': False,
            'dtc_count': 0,
            'monitors': {
                'Misfire': {'available': True, 'complete': True},
                'Fuel System': {'available': True, 'complete': True},
                'Components': {'available': True, 'complete': True},
                'Catalyst': {'available': True, 'complete': True},
                'Heated Catalyst': {'available': True, 'complete': False},
                'Evaporative System': {'available': True, 'complete': True},
                'Secondary Air System': {'available': False, 'complete': False},
                'A/C Refrigerant': {'available': False, 'complete': False},
                'Oxygen Sensor': {'available': True, 'complete': True},
                'Oxygen Sensor Heater': {'available': True, 'complete': True},
                'EGR System': {'available': True, 'complete': True}
            }
        }

    def stream_data(self, pids: List[int], interval: float = 0.1) -> None:
        """
        Stream real-time OBD data (generator)

        Args:
            pids: List of PIDs to monitor
            interval: Polling interval in seconds

        Yields:
            Dictionary of PID data
        """
        while True:
            data = {}
            for pid in pids:
                pid_data = self.read_pid(pid)
                if pid_data:
                    data[pid] = pid_data

            yield data
            time.sleep(interval)

    def close(self):
        """Close OBD connection"""
        if not self.simulation_mode and self.connection:
            self.connection.close()
            self.logger.info("OBD connection closed")


def main():
    """Example usage of ObdIIAdapter"""
    logging.basicConfig(level=logging.INFO)

    # Create adapter in simulation mode
    adapter = ObdIIAdapter(simulation_mode=True)

    # Read VIN
    vin = adapter.read_vin()
    print(f"VIN: {vin}")

    # Read some PIDs
    pids_to_read = [0x0C, 0x0D, 0x05, 0x11]
    print("\nCurrent Data:")
    for pid in pids_to_read:
        data = adapter.read_pid(pid)
        if data:
            print(f"  {data.name}: {data.value} {data.unit}")

    # Read DTCs
    dtcs = adapter.read_dtcs()
    print(f"\nDTCs ({len(dtcs)}):")
    for dtc in dtcs:
        print(f"  {dtc.code}: {dtc.description}")

    # Read readiness monitors
    readiness = adapter.read_readiness_monitors()
    print(f"\nMIL Status: {'ON' if readiness['mil_on'] else 'OFF'}")
    print(f"DTC Count: {readiness['dtc_count']}")

    adapter.close()


if __name__ == '__main__':
    main()

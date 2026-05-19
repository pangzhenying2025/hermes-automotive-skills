#!/usr/bin/env python3
"""
ODXTools Adapter - ODX/PDX database parsing for diagnostic data
Provides interface to parse and query ODX (Open Diagnostic Data Exchange) files
"""

import os
import logging
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass
from pathlib import Path

# Attempt to import odxtools
try:
    from odxtools import load_pdx_file, load_odx_d_file
    from odxtools.diaglayer import DiagLayer
    from odxtools.service import DiagService
    from odxtools.parameters import Parameter
    ODXTOOLS_AVAILABLE = True
except ImportError:
    ODXTOOLS_AVAILABLE = False
    logging.warning("odxtools not available - using simulation mode")


@dataclass
class DtcInfo:
    """DTC information from ODX"""
    code: str
    code_hex: str
    short_name: str
    long_name: str
    severity: Optional[str] = None
    possible_causes: Optional[List[str]] = None
    remedies: Optional[List[str]] = None


@dataclass
class DidInfo:
    """DID metadata from ODX"""
    did: int
    did_hex: str
    short_name: str
    long_name: str
    data_type: str
    byte_length: int
    scaling: Optional[Dict[str, Any]] = None
    unit: Optional[str] = None
    min_value: Optional[float] = None
    max_value: Optional[float] = None


@dataclass
class ServiceInfo:
    """UDS service information from ODX"""
    service_id: int
    service_hex: str
    short_name: str
    long_name: str
    sub_functions: List[Dict[str, Any]]
    parameters: List[str]
    security_level: Optional[int] = None
    session_required: Optional[str] = None


class OdxToolsAdapter:
    """
    Adapter for odxtools library - ODX/PDX database parser

    Provides high-level interface to parse ODX diagnostic databases
    and extract DTC, DID, and service information.
    """

    def __init__(self, odx_path: str, simulation_mode: bool = False):
        """
        Initialize ODX adapter

        Args:
            odx_path: Path to ODX-D file or PDX container
            simulation_mode: Enable simulation mode for testing
        """
        self.logger = logging.getLogger(__name__)
        self.simulation_mode = simulation_mode or not ODXTOOLS_AVAILABLE
        self.odx_path = odx_path
        self.database = None
        self.diag_layers: Dict[str, Any] = {}

        if not self.simulation_mode:
            self._load_odx_database()
        else:
            self.logger.warning("Running in simulation mode - using mock ODX data")
            self._create_simulation_data()

    def _load_odx_database(self):
        """Load and parse ODX database"""
        if not os.path.exists(self.odx_path):
            raise FileNotFoundError(f"ODX file not found: {self.odx_path}")

        try:
            if self.odx_path.endswith('.pdx'):
                self.database = load_pdx_file(self.odx_path)
            elif self.odx_path.endswith('.odx-d'):
                self.database = load_odx_d_file(self.odx_path)
            else:
                raise ValueError(f"Unsupported file format: {self.odx_path}")

            # Extract diagnostic layers (ECU variants)
            for diag_layer in self.database.diag_layers:
                self.diag_layers[diag_layer.short_name] = diag_layer

            self.logger.info(f"ODX database loaded: {len(self.diag_layers)} diagnostic layers")

        except Exception as e:
            raise Exception(f"Failed to load ODX database: {e}")

    def _create_simulation_data(self):
        """Create simulated ODX data for testing"""
        self.diag_layers = {
            'ECU_SIMULATION': {
                'short_name': 'ECU_SIMULATION',
                'variant': 'SIM_V1.0',
                'diag_address': 0x10
            }
        }

    def get_ecu_variants(self) -> List[str]:
        """
        Get list of ECU variants defined in ODX

        Returns:
            List of ECU variant names
        """
        return list(self.diag_layers.keys())

    def get_dtc_info(self, dtc_code: Union[int, str], ecu_variant: Optional[str] = None) -> Optional[DtcInfo]:
        """
        Get DTC information from ODX

        Args:
            dtc_code: DTC code (0x123456 or "P0301")
            ecu_variant: ECU variant name (uses first if None)

        Returns:
            DtcInfo or None if not found
        """
        if self.simulation_mode:
            return self._simulate_dtc_info(dtc_code)

        try:
            # Get diagnostic layer
            layer_name = ecu_variant or list(self.diag_layers.keys())[0]
            layer = self.diag_layers[layer_name]

            # Convert DTC format if needed
            if isinstance(dtc_code, str):
                dtc_code = self._parse_dtc_string(dtc_code)

            # Search for DTC in layer
            for dtc in layer.diag_trouble_codes:
                if dtc.trouble_code == dtc_code:
                    return DtcInfo(
                        code=self._format_dtc_string(dtc.trouble_code),
                        code_hex=f"0x{dtc.trouble_code:06X}",
                        short_name=dtc.short_name,
                        long_name=dtc.long_name or dtc.short_name,
                        severity=getattr(dtc, 'severity', None),
                        possible_causes=getattr(dtc, 'possible_causes', None),
                        remedies=getattr(dtc, 'remedies', None)
                    )

            return None

        except Exception as e:
            self.logger.error(f"Failed to get DTC info: {e}")
            return None

    def _simulate_dtc_info(self, dtc_code: Union[int, str]) -> DtcInfo:
        """Simulate DTC information"""
        if isinstance(dtc_code, str):
            code = dtc_code
            code_hex = f"0x{self._parse_dtc_string(dtc_code):06X}"
        else:
            code = self._format_dtc_string(dtc_code)
            code_hex = f"0x{dtc_code:06X}"

        return DtcInfo(
            code=code,
            code_hex=code_hex,
            short_name=f"DTC_{code}",
            long_name=f"Simulated DTC {code}",
            severity="B",
            possible_causes=["Sensor malfunction", "Wiring issue"],
            remedies=["Check sensor connections", "Replace sensor if faulty"]
        )

    def get_did_info(self, did: int, ecu_variant: Optional[str] = None) -> Optional[DidInfo]:
        """
        Get DID metadata from ODX

        Args:
            did: Data identifier (e.g., 0xF190)
            ecu_variant: ECU variant name

        Returns:
            DidInfo or None if not found
        """
        if self.simulation_mode:
            return self._simulate_did_info(did)

        try:
            layer_name = ecu_variant or list(self.diag_layers.keys())[0]
            layer = self.diag_layers[layer_name]

            # Search for DID in layer
            for data_object in layer.data_object_properties:
                if data_object.id == did:
                    # Extract scaling information
                    scaling = None
                    if hasattr(data_object, 'physical_type'):
                        scaling = {
                            'offset': getattr(data_object.physical_type, 'offset', 0),
                            'factor': getattr(data_object.physical_type, 'factor', 1),
                        }

                    return DidInfo(
                        did=did,
                        did_hex=f"0x{did:04X}",
                        short_name=data_object.short_name,
                        long_name=data_object.long_name or data_object.short_name,
                        data_type=str(data_object.diag_coded_type),
                        byte_length=data_object.diag_coded_type.bit_length // 8,
                        scaling=scaling,
                        unit=getattr(data_object.physical_type, 'display_unit', None) if hasattr(data_object, 'physical_type') else None,
                        min_value=getattr(data_object, 'lower_limit', None),
                        max_value=getattr(data_object, 'upper_limit', None)
                    )

            return None

        except Exception as e:
            self.logger.error(f"Failed to get DID info: {e}")
            return None

    def _simulate_did_info(self, did: int) -> DidInfo:
        """Simulate DID information"""
        did_database = {
            0xF190: ("VIN", "Vehicle Identification Number", "ascii", 17, None, None),
            0xF191: ("HW_Version", "Hardware Version", "ascii", 8, None, None),
            0xF195: ("SW_Version", "Software Version", "ascii", 12, None, None),
            0xF18C: ("ECU_Serial", "ECU Serial Number", "ascii", 10, None, None),
            0x010C: ("Engine_RPM", "Engine RPM", "uint16", 2, {'offset': 0, 'factor': 0.25}, "RPM"),
        }

        if did in did_database:
            info = did_database[did]
            return DidInfo(
                did=did,
                did_hex=f"0x{did:04X}",
                short_name=info[0],
                long_name=info[1],
                data_type=info[2],
                byte_length=info[3],
                scaling=info[4],
                unit=info[5],
                min_value=0,
                max_value=65535 if info[2] == "uint16" else None
            )

        return DidInfo(
            did=did,
            did_hex=f"0x{did:04X}",
            short_name=f"DID_{did:04X}",
            long_name=f"Simulated DID 0x{did:04X}",
            data_type="uint8",
            byte_length=4,
            scaling=None,
            unit=None
        )

    def get_service_info(self, service_id: int, ecu_variant: Optional[str] = None) -> Optional[ServiceInfo]:
        """
        Get UDS service information from ODX

        Args:
            service_id: Service ID (e.g., 0x22)
            ecu_variant: ECU variant name

        Returns:
            ServiceInfo or None if not found
        """
        if self.simulation_mode:
            return self._simulate_service_info(service_id)

        try:
            layer_name = ecu_variant or list(self.diag_layers.keys())[0]
            layer = self.diag_layers[layer_name]

            for service in layer.services:
                if service.request_id == service_id:
                    # Extract sub-functions
                    sub_funcs = []
                    for param in service.request_params:
                        if hasattr(param, 'coded_values'):
                            for coded_val in param.coded_values:
                                sub_funcs.append({
                                    'value': coded_val.coded_value,
                                    'name': coded_val.short_name
                                })

                    return ServiceInfo(
                        service_id=service_id,
                        service_hex=f"0x{service_id:02X}",
                        short_name=service.short_name,
                        long_name=service.long_name or service.short_name,
                        sub_functions=sub_funcs,
                        parameters=[p.short_name for p in service.request_params],
                        security_level=getattr(service, 'security_level', None),
                        session_required=getattr(service, 'diagnostic_class', None)
                    )

            return None

        except Exception as e:
            self.logger.error(f"Failed to get service info: {e}")
            return None

    def _simulate_service_info(self, service_id: int) -> ServiceInfo:
        """Simulate service information"""
        service_database = {
            0x10: ("DiagSessionControl", "Diagnostic Session Control", [
                {'value': 0x01, 'name': 'defaultSession'},
                {'value': 0x02, 'name': 'programmingSession'},
                {'value': 0x03, 'name': 'extendedSession'}
            ]),
            0x22: ("ReadDataById", "Read Data By Identifier", []),
            0x2E: ("WriteDataById", "Write Data By Identifier", []),
        }

        if service_id in service_database:
            info = service_database[service_id]
            return ServiceInfo(
                service_id=service_id,
                service_hex=f"0x{service_id:02X}",
                short_name=info[0],
                long_name=info[1],
                sub_functions=info[2],
                parameters=[],
                security_level=None,
                session_required="default"
            )

        return ServiceInfo(
            service_id=service_id,
            service_hex=f"0x{service_id:02X}",
            short_name=f"Service_{service_id:02X}",
            long_name=f"Simulated Service 0x{service_id:02X}",
            sub_functions=[],
            parameters=[],
            security_level=None
        )

    def apply_scaling(self, raw_value: Union[int, bytes], did: int, ecu_variant: Optional[str] = None) -> float:
        """
        Apply ODX scaling to raw DID value

        Args:
            raw_value: Raw value (int or bytes)
            did: Data identifier
            ecu_variant: ECU variant name

        Returns:
            Scaled physical value
        """
        did_info = self.get_did_info(did, ecu_variant)

        if not did_info or not did_info.scaling:
            # No scaling, return raw value
            if isinstance(raw_value, bytes):
                return int.from_bytes(raw_value, 'big')
            return float(raw_value)

        # Convert bytes to int if needed
        if isinstance(raw_value, bytes):
            raw_value = int.from_bytes(raw_value, 'big')

        # Apply scaling: physical = (raw * factor) + offset
        offset = did_info.scaling.get('offset', 0)
        factor = did_info.scaling.get('factor', 1)

        return (raw_value * factor) + offset

    @staticmethod
    def _parse_dtc_string(dtc_str: str) -> int:
        """Convert DTC string (P0301) to integer"""
        if dtc_str.startswith('0x'):
            return int(dtc_str, 16)

        # Parse standard DTC format (e.g., P0301)
        prefix_map = {'P': 0, 'C': 1, 'B': 2, 'U': 3}
        prefix = dtc_str[0].upper()
        digits = dtc_str[1:]

        first_byte = (prefix_map.get(prefix, 0) << 6) | (int(digits[0], 16) << 4) | int(digits[1], 16)
        second_byte = int(digits[2:4], 16)

        return (first_byte << 8) | second_byte

    @staticmethod
    def _format_dtc_string(dtc_int: int) -> str:
        """Convert DTC integer to string (0x010123 -> P0123)"""
        prefix_map = {0: 'P', 1: 'C', 2: 'B', 3: 'U'}

        first_byte = (dtc_int >> 8) & 0xFF
        second_byte = dtc_int & 0xFF

        prefix_code = (first_byte >> 6) & 0x03
        digit1 = (first_byte >> 4) & 0x03
        digit2 = first_byte & 0x0F
        digit3 = (second_byte >> 4) & 0x0F
        digit4 = second_byte & 0x0F

        return f"{prefix_map.get(prefix_code, 'U')}{digit1:01X}{digit2:01X}{digit3:01X}{digit4:01X}"


def main():
    """Example usage of OdxToolsAdapter"""
    logging.basicConfig(level=logging.INFO)

    # Create adapter in simulation mode
    adapter = OdxToolsAdapter("/path/to/database.odx-d", simulation_mode=True)

    # Get ECU variants
    variants = adapter.get_ecu_variants()
    print(f"ECU Variants: {variants}")

    # Get DTC info
    dtc_info = adapter.get_dtc_info("P0301")
    if dtc_info:
        print(f"\nDTC: {dtc_info.code} ({dtc_info.code_hex})")
        print(f"  Description: {dtc_info.long_name}")
        print(f"  Severity: {dtc_info.severity}")

    # Get DID info
    did_info = adapter.get_did_info(0xF190)
    if did_info:
        print(f"\nDID: {did_info.did_hex}")
        print(f"  Name: {did_info.long_name}")
        print(f"  Type: {did_info.data_type}, Length: {did_info.byte_length} bytes")

    # Apply scaling
    raw_rpm = 8600  # Raw value for 2150 RPM
    scaled_rpm = adapter.apply_scaling(raw_rpm, 0x010C)
    print(f"\nScaling example: raw={raw_rpm} -> scaled={scaled_rpm} RPM")


if __name__ == '__main__':
    main()

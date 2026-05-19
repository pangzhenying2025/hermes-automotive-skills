#!/usr/bin/env python3
"""
Python-UDS Adapter - Opensource UDS protocol implementation
Provides comprehensive UDS ISO 14229 diagnostic services
"""

import time
import logging
from typing import Dict, List, Optional, Tuple, Any, Union
from dataclasses import dataclass
from enum import IntEnum

# Attempt to import python-uds (opensource UDS library)
try:
    from uds import Uds
    from uds.uds_communications import UdsCommunications
    from uds.uds_config_tool import UdsConfigTool
    UDS_AVAILABLE = True
except ImportError:
    UDS_AVAILABLE = False
    logging.warning("python-uds not available - using simulation mode")


class UdsService(IntEnum):
    """UDS Service Identifiers (SID)"""
    DIAGNOSTIC_SESSION_CONTROL = 0x10
    ECU_RESET = 0x11
    CLEAR_DTC = 0x14
    READ_DTC = 0x19
    READ_DATA_BY_ID = 0x22
    READ_MEMORY_BY_ADDRESS = 0x23
    SECURITY_ACCESS = 0x27
    COMMUNICATION_CONTROL = 0x28
    READ_DATA_BY_PERIODIC_ID = 0x2A
    DYNAMICALLY_DEFINE_DID = 0x2C
    WRITE_DATA_BY_ID = 0x2E
    IO_CONTROL = 0x2F
    ROUTINE_CONTROL = 0x31
    REQUEST_DOWNLOAD = 0x34
    REQUEST_UPLOAD = 0x35
    TRANSFER_DATA = 0x36
    REQUEST_TRANSFER_EXIT = 0x37
    WRITE_MEMORY_BY_ADDRESS = 0x3D
    TESTER_PRESENT = 0x3E
    ACCESS_TIMING_PARAMETER = 0x83
    SECURED_DATA_TRANSMISSION = 0x84
    CONTROL_DTC_SETTING = 0x85
    RESPONSE_ON_EVENT = 0x86
    LINK_CONTROL = 0x87


class NegativeResponseCode(IntEnum):
    """UDS Negative Response Codes (NRC)"""
    GENERAL_REJECT = 0x10
    SERVICE_NOT_SUPPORTED = 0x11
    SUB_FUNCTION_NOT_SUPPORTED = 0x12
    INCORRECT_MESSAGE_LENGTH = 0x13
    RESPONSE_TOO_LONG = 0x14
    BUSY_REPEAT_REQUEST = 0x21
    CONDITIONS_NOT_CORRECT = 0x22
    REQUEST_SEQUENCE_ERROR = 0x24
    REQUEST_OUT_OF_RANGE = 0x31
    SECURITY_ACCESS_DENIED = 0x33
    INVALID_KEY = 0x35
    EXCEED_NUMBER_OF_ATTEMPTS = 0x36
    REQUIRED_TIME_DELAY_NOT_EXPIRED = 0x37
    REQUEST_CORRECTLY_RECEIVED_RESPONSE_PENDING = 0x78


@dataclass
class UdsResponse:
    """UDS Response data"""
    service: int
    data: bytes
    is_positive: bool
    nrc: Optional[int] = None
    nrc_description: Optional[str] = None


class UdsException(Exception):
    """UDS-specific exceptions"""
    pass


class PythonUdsAdapter:
    """
    Adapter for opensource python-uds library

    Provides high-level interface to UDS diagnostic services with support
    for multiple transport layers (CAN, DoIP, etc.)
    """

    def __init__(self, transport_config: Dict[str, Any], simulation_mode: bool = False):
        """
        Initialize UDS adapter

        Args:
            transport_config: Transport configuration
                For CAN: {'type': 'can', 'interface': 'socketcan', 'channel': 'can0', 'bitrate': 500000}
                For DoIP: {'type': 'doip', 'ip': '192.168.1.10', 'port': 13400}
            simulation_mode: Enable simulation mode for testing
        """
        self.logger = logging.getLogger(__name__)
        self.simulation_mode = simulation_mode or not UDS_AVAILABLE
        self.transport_config = transport_config
        self.connection = None
        self.current_session = 0x01  # Default session
        self.security_level = 0x00  # Locked
        self.dtc_setting_enabled = True

        if not self.simulation_mode:
            self._initialize_connection()
        else:
            self.logger.warning("Running in simulation mode - no actual ECU communication")

    def _initialize_connection(self):
        """Initialize UDS connection based on transport config"""
        try:
            transport_type = self.transport_config.get('type', 'can').lower()

            if transport_type == 'can':
                from uds.can_transport import CanTransport
                self.connection = CanTransport(
                    interface=self.transport_config.get('interface', 'socketcan'),
                    channel=self.transport_config.get('channel', 'can0'),
                    bitrate=self.transport_config.get('bitrate', 500000),
                    rx_id=self.transport_config.get('rx_id', 0x7E8),
                    tx_id=self.transport_config.get('tx_id', 0x7E0)
                )
            elif transport_type == 'doip':
                from uds.doip_transport import DoipTransport
                self.connection = DoipTransport(
                    ip=self.transport_config.get('ip'),
                    port=self.transport_config.get('port', 13400),
                    source_address=self.transport_config.get('source_address', 0x0E00),
                    target_address=self.transport_config.get('target_address', 0x1000)
                )

            self.logger.info(f"UDS connection initialized: {transport_type}")
        except Exception as e:
            raise UdsException(f"Failed to initialize UDS connection: {e}")

    def send_request(self, service: int, data: bytes = b'', timeout: float = 2.0) -> UdsResponse:
        """
        Send UDS request and receive response

        Args:
            service: UDS service identifier
            data: Additional data bytes
            timeout: Response timeout in seconds

        Returns:
            UdsResponse object
        """
        request = bytes([service]) + data

        if self.simulation_mode:
            return self._simulate_response(service, data)

        try:
            self.logger.debug(f"TX: {request.hex()}")
            response_data = self.connection.send_and_receive(request, timeout)
            self.logger.debug(f"RX: {response_data.hex()}")

            return self._parse_response(service, response_data)

        except TimeoutError:
            raise UdsException(f"UDS request timeout for service 0x{service:02X}")
        except Exception as e:
            raise UdsException(f"UDS communication error: {e}")

    def _parse_response(self, service: int, response_data: bytes) -> UdsResponse:
        """Parse UDS response"""
        if len(response_data) < 1:
            raise UdsException("Empty response received")

        response_sid = response_data[0]

        # Check for negative response
        if response_sid == 0x7F:
            if len(response_data) < 3:
                raise UdsException("Invalid negative response format")

            nrc = response_data[2]
            nrc_desc = self._get_nrc_description(nrc)

            return UdsResponse(
                service=service,
                data=response_data[3:],
                is_positive=False,
                nrc=nrc,
                nrc_description=nrc_desc
            )

        # Positive response
        expected_response_sid = service + 0x40
        if response_sid != expected_response_sid:
            raise UdsException(f"Unexpected response SID: 0x{response_sid:02X}")

        return UdsResponse(
            service=service,
            data=response_data[1:],
            is_positive=True
        )

    def _get_nrc_description(self, nrc: int) -> str:
        """Get description for negative response code"""
        try:
            return NegativeResponseCode(nrc).name.replace('_', ' ').title()
        except ValueError:
            return f"Unknown NRC: 0x{nrc:02X}"

    # === UDS Service Implementations ===

    def diagnostic_session_control(self, session_type: int) -> Dict[str, Any]:
        """
        0x10 - DiagnosticSessionControl

        Args:
            session_type: 0x01=default, 0x02=programming, 0x03=extended

        Returns:
            Session timing parameters
        """
        response = self.send_request(UdsService.DIAGNOSTIC_SESSION_CONTROL, bytes([session_type]))

        if not response.is_positive:
            raise UdsException(f"Session control failed: {response.nrc_description}")

        self.current_session = session_type

        # Parse timing parameters (if present)
        timing = {}
        if len(response.data) >= 5:
            timing['p2_server_max'] = int.from_bytes(response.data[1:3], 'big')  # ms
            timing['p2_star_server_max'] = int.from_bytes(response.data[3:5], 'big') * 10  # ms

        self.logger.info(f"Session changed to 0x{session_type:02X}")
        return timing

    def ecu_reset(self, reset_type: int) -> bool:
        """
        0x11 - ECUReset

        Args:
            reset_type: 0x01=hard, 0x02=keyOffOn, 0x03=soft

        Returns:
            True if reset successful
        """
        response = self.send_request(UdsService.ECU_RESET, bytes([reset_type]))

        if not response.is_positive:
            raise UdsException(f"ECU reset failed: {response.nrc_description}")

        self.logger.info(f"ECU reset executed: type 0x{reset_type:02X}")
        return True

    def clear_dtc(self, dtc_group: int = 0xFFFFFF) -> bool:
        """
        0x14 - ClearDiagnosticInformation

        Args:
            dtc_group: DTC group to clear (0xFFFFFF = all)

        Returns:
            True if DTCs cleared
        """
        data = dtc_group.to_bytes(3, 'big')
        response = self.send_request(UdsService.CLEAR_DTC, data)

        if not response.is_positive:
            raise UdsException(f"Clear DTC failed: {response.nrc_description}")

        self.logger.info(f"DTCs cleared: group 0x{dtc_group:06X}")
        return True

    def read_dtc_by_status_mask(self, status_mask: int = 0xFF) -> List[Dict[str, Any]]:
        """
        0x19 0x02 - ReadDTCInformation (reportDTCByStatusMask)

        Args:
            status_mask: Status mask filter

        Returns:
            List of DTCs with status
        """
        data = bytes([0x02, status_mask])  # Sub-function 0x02
        response = self.send_request(UdsService.READ_DTC, data)

        if not response.is_positive:
            raise UdsException(f"Read DTC failed: {response.nrc_description}")

        # Parse DTCs (3 bytes DTC + 1 byte status)
        dtcs = []
        data_offset = 1  # Skip sub-function echo

        while data_offset + 4 <= len(response.data):
            dtc_bytes = response.data[data_offset:data_offset+3]
            status = response.data[data_offset+3]

            dtc = int.from_bytes(dtc_bytes, 'big')
            dtcs.append({
                'dtc': dtc,
                'dtc_hex': f"0x{dtc:06X}",
                'status': status,
                'test_failed': bool(status & 0x01),
                'pending': bool(status & 0x04),
                'confirmed': bool(status & 0x08),
                'test_failed_since_last_clear': bool(status & 0x20)
            })

            data_offset += 4

        self.logger.info(f"Read {len(dtcs)} DTCs")
        return dtcs

    def read_data_by_identifier(self, did: int) -> bytes:
        """
        0x22 - ReadDataByIdentifier

        Args:
            did: Data identifier (e.g., 0xF190 for VIN)

        Returns:
            Raw data bytes
        """
        data = did.to_bytes(2, 'big')
        response = self.send_request(UdsService.READ_DATA_BY_ID, data)

        if not response.is_positive:
            raise UdsException(f"Read DID 0x{did:04X} failed: {response.nrc_description}")

        # Skip echoed DID in response
        return response.data[2:]

    def write_data_by_identifier(self, did: int, data: bytes) -> bool:
        """
        0x2E - WriteDataByIdentifier

        Args:
            did: Data identifier
            data: Data to write

        Returns:
            True if write successful
        """
        request_data = did.to_bytes(2, 'big') + data
        response = self.send_request(UdsService.WRITE_DATA_BY_ID, request_data)

        if not response.is_positive:
            raise UdsException(f"Write DID 0x{did:04X} failed: {response.nrc_description}")

        self.logger.info(f"DID 0x{did:04X} written successfully")
        return True

    def security_access_request_seed(self, level: int) -> bytes:
        """
        0x27 - SecurityAccess (RequestSeed)

        Args:
            level: Security level (odd number)

        Returns:
            Seed bytes from ECU
        """
        response = self.send_request(UdsService.SECURITY_ACCESS, bytes([level]))

        if not response.is_positive:
            raise UdsException(f"Security request seed failed: {response.nrc_description}")

        seed = response.data[1:]  # Skip sub-function echo
        self.logger.info(f"Seed received for level {level}: {seed.hex()}")
        return seed

    def security_access_send_key(self, level: int, key: bytes) -> bool:
        """
        0x27 - SecurityAccess (SendKey)

        Args:
            level: Security level (even number, level+1 from seed request)
            key: Calculated key bytes

        Returns:
            True if access granted
        """
        data = bytes([level]) + key
        response = self.send_request(UdsService.SECURITY_ACCESS, data)

        if not response.is_positive:
            raise UdsException(f"Security send key failed: {response.nrc_description}")

        self.security_level = level - 1
        self.logger.info(f"Security access granted: level {self.security_level}")
        return True

    def tester_present(self, suppress_response: bool = True) -> bool:
        """
        0x3E - TesterPresent

        Args:
            suppress_response: Set to suppress positive response

        Returns:
            True if tester present acknowledged
        """
        sub_func = 0x80 if suppress_response else 0x00
        response = self.send_request(UdsService.TESTER_PRESENT, bytes([sub_func]))

        if not suppress_response and not response.is_positive:
            raise UdsException(f"Tester present failed: {response.nrc_description}")

        return True

    def _simulate_response(self, service: int, data: bytes) -> UdsResponse:
        """Simulate UDS responses for testing"""
        self.logger.debug(f"[SIMULATION] Service 0x{service:02X}, data: {data.hex()}")

        # Simulate successful responses
        if service == UdsService.DIAGNOSTIC_SESSION_CONTROL:
            return UdsResponse(service, bytes([data[0], 0x00, 0x32, 0x01, 0xF4]), True)
        elif service == UdsService.READ_DATA_BY_ID:
            # Simulate VIN for DID 0xF190
            if data == b'\xF1\x90':
                return UdsResponse(service, b'\xF1\x90SIMULATION17CHAR', True)
            return UdsResponse(service, b'\x00\x00' + b'\xAA' * 4, True)
        elif service == UdsService.READ_DTC:
            # Simulate 2 DTCs
            return UdsResponse(service, b'\x02\x01\x23\x45\x28\x06\x78\x9A\x0C', True)
        else:
            return UdsResponse(service, data, True)


def main():
    """Example usage of PythonUdsAdapter"""
    logging.basicConfig(level=logging.INFO)

    # Create adapter in simulation mode
    config = {
        'type': 'can',
        'interface': 'socketcan',
        'channel': 'can0',
        'bitrate': 500000,
        'rx_id': 0x7E8,
        'tx_id': 0x7E0
    }

    adapter = PythonUdsAdapter(config, simulation_mode=True)

    # Read VIN
    vin_data = adapter.read_data_by_identifier(0xF190)
    print(f"VIN: {vin_data.decode('ascii', errors='ignore')}")

    # Read DTCs
    dtcs = adapter.read_dtc_by_status_mask()
    print(f"\nDTCs ({len(dtcs)}):")
    for dtc in dtcs:
        print(f"  {dtc['dtc_hex']}: confirmed={dtc['confirmed']}, pending={dtc['pending']}")


if __name__ == '__main__':
    main()

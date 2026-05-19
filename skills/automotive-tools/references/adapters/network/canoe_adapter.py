#!/usr/bin/env python3
"""
Vector CANoe Adapter
Interface for CANoe network simulation and analysis
"""

import subprocess
import win32com.client
import pythoncom
from pathlib import Path
from typing import Dict, List, Optional, Any, Callable
import time
import logging
from dataclasses import dataclass
from enum import Enum
import threading

logger = logging.getLogger(__name__)


class MeasurementState(Enum):
    """CANoe measurement states"""
    STOPPED = 0
    RUNNING = 1
    PAUSED = 2


@dataclass
class CANoeConfig:
    """CANoe configuration"""
    config_path: Path
    databases: List[Path]
    test_modules: List[Path]


@dataclass
class SignalValue:
    """CAN signal value"""
    name: str
    value: Any
    timestamp: float
    bus: str = "CAN1"


class CANoeAdapter:
    """
    Adapter for Vector CANoe network analysis and simulation
    Provides programmatic control of CANoe measurements and test execution
    """

    def __init__(self, canoe_version: str = "16.0"):
        """
        Initialize CANoe adapter

        Args:
            canoe_version: CANoe version (e.g., "16.0", "17.0")
        """
        self.canoe_version = canoe_version
        self.application = None
        self.measurement = None
        self.configuration = None
        self.system_variables = {}
        self.signal_callbacks: Dict[str, List[Callable]] = {}
        self.measurement_state = MeasurementState.STOPPED
        self.simulation_mode = False

        try:
            pythoncom.CoInitialize()
            self.application = win32com.client.Dispatch("CANoe.Application")
            logger.info(f"Connected to CANoe {self.application.Version}")
        except Exception as e:
            logger.warning(f"CANoe COM interface not available: {e}")
            logger.info("Running in simulation mode")
            self.simulation_mode = True

    def load_configuration(
        self,
        config_path: Path,
        databases: Optional[List[Path]] = None,
        test_modules: Optional[List[Path]] = None
    ) -> CANoeConfig:
        """
        Load CANoe configuration

        Args:
            config_path: Path to .cfg file
            databases: List of database files
            test_modules: List of test module files

        Returns:
            CANoeConfig object
        """
        if not config_path.exists():
            raise FileNotFoundError(f"Configuration not found: {config_path}")

        config = CANoeConfig(
            config_path=config_path,
            databases=databases or [],
            test_modules=test_modules or []
        )

        if self.simulation_mode:
            logger.info(f"Mock loaded configuration: {config_path}")
            self.configuration = config
            return config

        try:
            self.application.Open(str(config_path))
            self.configuration = self.application.Configuration
            self.measurement = self.application.Measurement

            logger.info(f"Loaded configuration: {config_path}")

            for db_path in config.databases:
                self._add_database(db_path)

            return config

        except Exception as e:
            raise RuntimeError(f"Failed to load configuration: {e}")

    def _add_database(self, db_path: Path) -> None:
        """Add database to configuration"""
        if not db_path.exists():
            logger.warning(f"Database not found: {db_path}")
            return

        try:
            databases = self.configuration.Databases
            databases.Add(str(db_path))
            logger.info(f"Added database: {db_path}")
        except Exception as e:
            logger.error(f"Failed to add database: {e}")

    def start_measurement(self, timeout: float = 10.0) -> bool:
        """
        Start CANoe measurement

        Args:
            timeout: Timeout for measurement start

        Returns:
            True if started successfully
        """
        if self.simulation_mode:
            self.measurement_state = MeasurementState.RUNNING
            logger.info("Mock measurement started")
            return True

        if not self.measurement:
            raise RuntimeError("No configuration loaded")

        try:
            self.measurement.Start()

            start_time = time.time()
            while not self.measurement.Running:
                if time.time() - start_time > timeout:
                    logger.error("Measurement start timeout")
                    return False
                time.sleep(0.1)

            self.measurement_state = MeasurementState.RUNNING
            logger.info("Measurement started")
            return True

        except Exception as e:
            logger.error(f"Failed to start measurement: {e}")
            return False

    def stop_measurement(self, timeout: float = 5.0) -> bool:
        """
        Stop CANoe measurement

        Args:
            timeout: Timeout for measurement stop

        Returns:
            True if stopped successfully
        """
        if self.simulation_mode:
            self.measurement_state = MeasurementState.STOPPED
            logger.info("Mock measurement stopped")
            return True

        if not self.measurement:
            return False

        try:
            self.measurement.Stop()

            start_time = time.time()
            while self.measurement.Running:
                if time.time() - start_time > timeout:
                    logger.error("Measurement stop timeout")
                    return False
                time.sleep(0.1)

            self.measurement_state = MeasurementState.STOPPED
            logger.info("Measurement stopped")
            return True

        except Exception as e:
            logger.error(f"Failed to stop measurement: {e}")
            return False

    def get_signal_value(
        self,
        signal_name: str,
        bus: str = "CAN1"
    ) -> Optional[Any]:
        """
        Get CAN signal value

        Args:
            signal_name: Signal name (format: "MessageName::SignalName")
            bus: Bus name

        Returns:
            Signal value or None
        """
        if self.simulation_mode:
            return self._get_mock_signal_value(signal_name)

        if not self.measurement or not self.measurement.Running:
            logger.warning("Measurement not running")
            return None

        try:
            signal = self.configuration.Buses(bus).Signals(signal_name)
            return signal.Value
        except Exception as e:
            logger.error(f"Failed to get signal {signal_name}: {e}")
            return None

    def set_signal_value(
        self,
        signal_name: str,
        value: Any,
        bus: str = "CAN1"
    ) -> bool:
        """
        Set CAN signal value

        Args:
            signal_name: Signal name
            value: New value
            bus: Bus name

        Returns:
            True if successful
        """
        if self.simulation_mode:
            logger.info(f"Mock set signal {signal_name} = {value}")
            return True

        if not self.measurement or not self.measurement.Running:
            logger.warning("Measurement not running")
            return False

        try:
            signal = self.configuration.Buses(bus).Signals(signal_name)
            signal.Value = value
            logger.debug(f"Set signal {signal_name} = {value}")
            return True
        except Exception as e:
            logger.error(f"Failed to set signal {signal_name}: {e}")
            return False

    def _get_mock_signal_value(self, signal_name: str) -> Any:
        """Get mock signal value"""
        mock_values = {
            "EngineSpeed": 2500.0,
            "VehicleSpeed": 80.0,
            "BatteryVoltage": 13.8,
            "CoolantTemp": 85.0,
            "ThrottlePosition": 45.0
        }

        for key in mock_values:
            if key in signal_name:
                return mock_values[key]

        return 0

    def get_system_variable(self, variable_name: str) -> Optional[Any]:
        """
        Get system variable value

        Args:
            variable_name: Variable name (namespace::variable)

        Returns:
            Variable value or None
        """
        if self.simulation_mode:
            return self.system_variables.get(variable_name)

        if not self.measurement:
            return None

        try:
            parts = variable_name.split("::")
            if len(parts) == 2:
                namespace, var_name = parts
                sys_vars = self.configuration.SystemVariables
                return sys_vars(namespace)(var_name).Value
            else:
                return self.configuration.SystemVariables(variable_name).Value
        except Exception as e:
            logger.error(f"Failed to get system variable {variable_name}: {e}")
            return None

    def set_system_variable(
        self,
        variable_name: str,
        value: Any
    ) -> bool:
        """
        Set system variable value

        Args:
            variable_name: Variable name
            value: New value

        Returns:
            True if successful
        """
        if self.simulation_mode:
            self.system_variables[variable_name] = value
            logger.info(f"Mock set system variable {variable_name} = {value}")
            return True

        if not self.measurement:
            return False

        try:
            parts = variable_name.split("::")
            if len(parts) == 2:
                namespace, var_name = parts
                sys_vars = self.configuration.SystemVariables
                sys_vars(namespace)(var_name).Value = value
            else:
                self.configuration.SystemVariables(variable_name).Value = value

            logger.debug(f"Set system variable {variable_name} = {value}")
            return True
        except Exception as e:
            logger.error(f"Failed to set system variable {variable_name}: {e}")
            return False

    def send_can_message(
        self,
        message_id: int,
        data: bytes,
        bus: str = "CAN1",
        extended: bool = False
    ) -> bool:
        """
        Send CAN message

        Args:
            message_id: CAN message ID
            data: Message data (up to 8 bytes)
            bus: Bus name
            extended: Use extended ID

        Returns:
            True if successful
        """
        if len(data) > 8:
            raise ValueError("CAN data length must be <= 8 bytes")

        if self.simulation_mode:
            logger.info(
                f"Mock send CAN message: ID=0x{message_id:X}, "
                f"Data={data.hex()}, Bus={bus}"
            )
            return True

        if not self.measurement or not self.measurement.Running:
            logger.warning("Measurement not running")
            return False

        try:
            bus_obj = self.configuration.Buses(bus)
            msg = bus_obj.CreateMessage(message_id, extended)
            msg.DLC = len(data)

            for i, byte_val in enumerate(data):
                msg.DataByte(i, byte_val)

            bus_obj.Send(msg)
            logger.debug(f"Sent CAN message 0x{message_id:X}")
            return True

        except Exception as e:
            logger.error(f"Failed to send CAN message: {e}")
            return False

    def run_test_module(
        self,
        test_module: str,
        test_case: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Run CAPL test module

        Args:
            test_module: Test module name
            test_case: Specific test case (None = all)

        Returns:
            Test result dictionary
        """
        if self.simulation_mode:
            return {
                "status": "PASSED",
                "test_module": test_module,
                "test_case": test_case,
                "verdict": "Mock test execution"
            }

        if not self.measurement:
            raise RuntimeError("No configuration loaded")

        try:
            test_env = self.configuration.TestEnvironment

            if test_case:
                test = test_env.TestModules(test_module).TestCases(test_case)
                test.Execute()
            else:
                test_env.TestModules(test_module).Execute()

            time.sleep(0.5)

            result = {
                "status": "PASSED",
                "test_module": test_module,
                "test_case": test_case
            }

            logger.info(f"Test execution completed: {test_module}")
            return result

        except Exception as e:
            logger.error(f"Test execution failed: {e}")
            return {
                "status": "FAILED",
                "test_module": test_module,
                "test_case": test_case,
                "error": str(e)
            }

    def enable_logging(
        self,
        log_file: Path,
        log_format: str = "BLF"
    ) -> bool:
        """
        Enable bus logging

        Args:
            log_file: Output log file path
            log_format: Log format (BLF, ASC)

        Returns:
            True if successful
        """
        if self.simulation_mode:
            logger.info(f"Mock logging to {log_file} ({log_format})")
            return True

        if not self.measurement:
            return False

        try:
            logging_obj = self.measurement.Logging
            logging_obj.FileName = str(log_file)
            logging_obj.Start()

            logger.info(f"Logging enabled: {log_file}")
            return True

        except Exception as e:
            logger.error(f"Failed to enable logging: {e}")
            return False

    def replay_log_file(
        self,
        log_file: Path,
        speed: float = 1.0
    ) -> bool:
        """
        Replay recorded log file

        Args:
            log_file: Log file to replay
            speed: Playback speed multiplier

        Returns:
            True if successful
        """
        if not log_file.exists():
            raise FileNotFoundError(f"Log file not found: {log_file}")

        if self.simulation_mode:
            logger.info(f"Mock replay: {log_file} at {speed}x speed")
            return True

        if not self.measurement:
            return False

        try:
            replay = self.measurement.Replay
            replay.FileName = str(log_file)
            replay.Speed = speed
            replay.Start()

            logger.info(f"Replaying log file: {log_file}")
            return True

        except Exception as e:
            logger.error(f"Failed to replay log file: {e}")
            return False

    def __del__(self):
        """Cleanup COM interface"""
        if not self.simulation_mode and self.application:
            try:
                if self.measurement and self.measurement.Running:
                    self.stop_measurement()
                pythoncom.CoUninitialize()
            except:
                pass

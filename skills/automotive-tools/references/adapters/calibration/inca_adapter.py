#!/usr/bin/env python3
"""
ETAS INCA Adapter
Interface for INCA calibration and measurement software
"""

import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import struct
import logging
from dataclasses import dataclass
from enum import Enum
import time

logger = logging.getLogger(__name__)


class DataType(Enum):
    """INCA data types"""
    UBYTE = "UBYTE"
    SBYTE = "SBYTE"
    UWORD = "UWORD"
    SWORD = "SWORD"
    ULONG = "ULONG"
    SLONG = "SLONG"
    FLOAT32 = "FLOAT32_IEEE"
    FLOAT64 = "FLOAT64_IEEE"


@dataclass
class CalibrationParameter:
    """Calibration parameter definition"""
    name: str
    address: int
    data_type: DataType
    min_value: float
    max_value: float
    unit: str
    description: str = ""


@dataclass
class MeasurementSignal:
    """Measurement signal definition"""
    name: str
    address: int
    data_type: DataType
    conversion: str
    unit: str
    sample_rate: float = 100.0


@dataclass
class IncaWorkspace:
    """INCA workspace configuration"""
    path: Path
    database: str
    device: str
    protocol: str = "XCP"


class IncaAdapter:
    """
    Adapter for ETAS INCA calibration tool
    Provides programmatic access to calibration and measurement
    """

    def __init__(self, inca_path: Optional[Path] = None):
        """
        Initialize INCA adapter

        Args:
            inca_path: Path to INCA installation
        """
        self.inca_path = inca_path or self._find_inca()
        self.inca_exe = self.inca_path / "Exe64" / "INCA.exe"
        self.current_workspace: Optional[IncaWorkspace] = None

        if not self.inca_exe.exists():
            logger.warning(f"INCA not found at {self.inca_exe}")
            logger.info("Running in simulation mode")
            self.simulation_mode = True
        else:
            self.simulation_mode = False

    def _find_inca(self) -> Path:
        """Find INCA installation directory"""
        import os

        if "INCA_PATH" in os.environ:
            return Path(os.environ["INCA_PATH"])

        common_paths = [
            Path("C:/Program Files/ETAS/INCA7.3"),
            Path("C:/Program Files/ETAS/INCA7.4"),
            Path("C:/ETAS/INCA"),
            Path.home() / "ETAS" / "INCA"
        ]

        for path in common_paths:
            if path.exists():
                return path

        logger.warning("INCA installation not found")
        return Path.cwd() / "inca_mock"

    def create_workspace(
        self,
        workspace_name: str,
        database_path: Path,
        device_name: str,
        protocol: str = "XCP_on_ETH",
        output_dir: Optional[Path] = None
    ) -> IncaWorkspace:
        """
        Create INCA workspace

        Args:
            workspace_name: Workspace name
            database_path: Path to A2L database
            device_name: Target device name
            protocol: Communication protocol
            output_dir: Output directory

        Returns:
            IncaWorkspace object
        """
        output_dir = output_dir or Path.cwd() / "inca_workspaces"
        workspace_dir = output_dir / workspace_name
        workspace_dir.mkdir(parents=True, exist_ok=True)

        workspace = IncaWorkspace(
            path=workspace_dir,
            database=str(database_path),
            device=device_name,
            protocol=protocol
        )

        if self.simulation_mode:
            self._create_mock_workspace(workspace)
        else:
            self._create_real_workspace(workspace)

        self.current_workspace = workspace
        logger.info(f"Created workspace: {workspace_name}")

        return workspace

    def _create_mock_workspace(self, workspace: IncaWorkspace) -> None:
        """Create mock workspace configuration"""
        config_file = workspace.path / "workspace.xml"
        config_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<INCA-WORKSPACE>
  <DATABASE>{workspace.database}</DATABASE>
  <DEVICE>{workspace.device}</DEVICE>
  <PROTOCOL>{workspace.protocol}</PROTOCOL>
</INCA-WORKSPACE>
"""
        config_file.write_text(config_content)

    def _create_real_workspace(self, workspace: IncaWorkspace) -> None:
        """Create actual INCA workspace"""
        cmd = [
            str(self.inca_exe),
            "-CreateWorkspace",
            f"-Name={workspace.path.name}",
            f"-Database={workspace.database}",
            f"-Device={workspace.device}",
            f"-Protocol={workspace.protocol}",
            f"-Path={workspace.path}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Failed to create workspace: {result.stderr}")

    def connect_device(
        self,
        workspace: Optional[IncaWorkspace] = None,
        connection_params: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Connect to target device

        Args:
            workspace: Workspace to use (defaults to current)
            connection_params: Connection parameters

        Returns:
            True if connected successfully
        """
        workspace = workspace or self.current_workspace

        if not workspace:
            raise ValueError("No workspace specified")

        connection_params = connection_params or {}

        if self.simulation_mode:
            logger.info(f"Mock connection to {workspace.device}")
            return True

        cmd = [
            str(self.inca_exe),
            "-Connect",
            f"-Workspace={workspace.path}",
            f"-Device={workspace.device}"
        ]

        for key, value in connection_params.items():
            cmd.append(f"-{key}={value}")

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            logger.info(f"Connected to {workspace.device}")
            return True
        else:
            logger.error(f"Connection failed: {result.stderr}")
            return False

    def disconnect_device(self) -> bool:
        """Disconnect from target device"""
        if self.simulation_mode:
            logger.info("Mock disconnect")
            return True

        if not self.current_workspace:
            return False

        cmd = [
            str(self.inca_exe),
            "-Disconnect",
            f"-Workspace={self.current_workspace.path}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.returncode == 0

    def read_parameter(
        self,
        parameter: CalibrationParameter
    ) -> Any:
        """
        Read calibration parameter value

        Args:
            parameter: Parameter to read

        Returns:
            Parameter value
        """
        if self.simulation_mode:
            return self._get_mock_parameter_value(parameter)

        if not self.current_workspace:
            raise RuntimeError("Not connected to workspace")

        cmd = [
            str(self.inca_exe),
            "-ReadParameter",
            f"-Name={parameter.name}",
            f"-Workspace={self.current_workspace.path}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Failed to read parameter: {result.stderr}")

        return self._parse_parameter_value(result.stdout, parameter.data_type)

    def write_parameter(
        self,
        parameter: CalibrationParameter,
        value: Any
    ) -> bool:
        """
        Write calibration parameter value

        Args:
            parameter: Parameter to write
            value: New value

        Returns:
            True if successful
        """
        if not self._validate_parameter_value(parameter, value):
            raise ValueError(
                f"Value {value} out of range [{parameter.min_value}, "
                f"{parameter.max_value}]"
            )

        if self.simulation_mode:
            logger.info(f"Mock write: {parameter.name} = {value}")
            return True

        if not self.current_workspace:
            raise RuntimeError("Not connected to workspace")

        cmd = [
            str(self.inca_exe),
            "-WriteParameter",
            f"-Name={parameter.name}",
            f"-Value={value}",
            f"-Workspace={self.current_workspace.path}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            logger.info(f"Written {parameter.name} = {value}")
            return True
        else:
            logger.error(f"Write failed: {result.stderr}")
            return False

    def _validate_parameter_value(
        self,
        parameter: CalibrationParameter,
        value: Any
    ) -> bool:
        """Validate parameter value against min/max"""
        try:
            numeric_value = float(value)
            return parameter.min_value <= numeric_value <= parameter.max_value
        except (TypeError, ValueError):
            return False

    def _get_mock_parameter_value(
        self,
        parameter: CalibrationParameter
    ) -> Any:
        """Get mock parameter value"""
        mock_values = {
            DataType.UBYTE: 128,
            DataType.SBYTE: 0,
            DataType.UWORD: 32768,
            DataType.SWORD: 0,
            DataType.ULONG: 2147483648,
            DataType.SLONG: 0,
            DataType.FLOAT32: 1.5,
            DataType.FLOAT64: 2.5
        }
        return mock_values.get(parameter.data_type, 0)

    def _parse_parameter_value(
        self,
        output: str,
        data_type: DataType
    ) -> Any:
        """Parse parameter value from INCA output"""
        value_str = output.strip().split()[-1]

        type_parsers = {
            DataType.UBYTE: lambda x: int(x),
            DataType.SBYTE: lambda x: int(x),
            DataType.UWORD: lambda x: int(x),
            DataType.SWORD: lambda x: int(x),
            DataType.ULONG: lambda x: int(x),
            DataType.SLONG: lambda x: int(x),
            DataType.FLOAT32: lambda x: float(x),
            DataType.FLOAT64: lambda x: float(x)
        }

        parser = type_parsers.get(data_type, str)
        return parser(value_str)

    def start_measurement(
        self,
        signals: List[MeasurementSignal],
        duration: Optional[float] = None
    ) -> str:
        """
        Start measurement recording

        Args:
            signals: List of signals to measure
            duration: Recording duration in seconds (None = continuous)

        Returns:
            Measurement ID
        """
        if self.simulation_mode:
            measurement_id = f"mock_measurement_{int(time.time())}"
            logger.info(f"Mock measurement started: {measurement_id}")
            return measurement_id

        if not self.current_workspace:
            raise RuntimeError("Not connected to workspace")

        measurement_file = (
            self.current_workspace.path /
            f"measurement_{int(time.time())}.mdf"
        )

        cmd = [
            str(self.inca_exe),
            "-StartMeasurement",
            f"-Workspace={self.current_workspace.path}",
            f"-Output={measurement_file}",
            f"-Signals={','.join([s.name for s in signals])}"
        ]

        if duration:
            cmd.append(f"-Duration={duration}")

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Failed to start measurement: {result.stderr}")

        logger.info(f"Measurement started: {measurement_file}")
        return str(measurement_file)

    def stop_measurement(self, measurement_id: str) -> Path:
        """
        Stop measurement recording

        Args:
            measurement_id: Measurement ID from start_measurement

        Returns:
            Path to measurement file
        """
        if self.simulation_mode:
            mock_file = Path(f"/tmp/{measurement_id}.mdf")
            mock_file.touch()
            logger.info(f"Mock measurement stopped: {mock_file}")
            return mock_file

        cmd = [
            str(self.inca_exe),
            "-StopMeasurement",
            f"-Workspace={self.current_workspace.path}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            logger.error(f"Failed to stop measurement: {result.stderr}")

        return Path(measurement_id)

    def export_calibration(
        self,
        output_file: Path,
        format_type: str = "HEX"
    ) -> Path:
        """
        Export calibration data

        Args:
            output_file: Output file path
            format_type: Export format (HEX, S19, BIN)

        Returns:
            Path to exported file
        """
        if self.simulation_mode:
            output_file.write_text(f"Mock calibration export ({format_type})")
            logger.info(f"Mock export: {output_file}")
            return output_file

        if not self.current_workspace:
            raise RuntimeError("Not connected to workspace")

        cmd = [
            str(self.inca_exe),
            "-ExportCalibration",
            f"-Workspace={self.current_workspace.path}",
            f"-Output={output_file}",
            f"-Format={format_type}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Export failed: {result.stderr}")

        logger.info(f"Calibration exported: {output_file}")
        return output_file

    def import_calibration(
        self,
        calibration_file: Path
    ) -> bool:
        """
        Import calibration data

        Args:
            calibration_file: Calibration file to import

        Returns:
            True if successful
        """
        if not calibration_file.exists():
            raise FileNotFoundError(f"Calibration file not found: {calibration_file}")

        if self.simulation_mode:
            logger.info(f"Mock import: {calibration_file}")
            return True

        if not self.current_workspace:
            raise RuntimeError("Not connected to workspace")

        cmd = [
            str(self.inca_exe),
            "-ImportCalibration",
            f"-Workspace={self.current_workspace.path}",
            f"-Input={calibration_file}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            logger.info(f"Calibration imported: {calibration_file}")
            return True
        else:
            logger.error(f"Import failed: {result.stderr}")
            return False

    def flash_calibration(self, sector: Optional[str] = None) -> bool:
        """
        Flash calibration to ECU

        Args:
            sector: Target flash sector (None = all)

        Returns:
            True if successful
        """
        if self.simulation_mode:
            logger.info(f"Mock flash to sector: {sector or 'all'}")
            return True

        if not self.current_workspace:
            raise RuntimeError("Not connected to workspace")

        cmd = [
            str(self.inca_exe),
            "-FlashCalibration",
            f"-Workspace={self.current_workspace.path}"
        ]

        if sector:
            cmd.append(f"-Sector={sector}")

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            logger.info("Calibration flashed successfully")
            return True
        else:
            logger.error(f"Flash failed: {result.stderr}")
            return False

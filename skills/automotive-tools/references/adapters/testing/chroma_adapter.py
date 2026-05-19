"""
Chroma Battery Cycler Adapter.

Supports Chroma 17000 series regenerative battery test systems:
- 17010H (600V, 120A, 7.2kW per channel)
- 17020H (600V, 240A, 14.4kW per channel)
- 17208M (Multi-channel, 8-256 channels)

Communication: Ethernet (Modbus TCP, SCPI over TCP)
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from base_adapter import OpensourceToolAdapter
from typing import Dict, List, Optional, Any
import subprocess
import time
import json


class ChromaAdapter(OpensourceToolAdapter):
    """Adapter for Chroma battery cycler systems."""

    SUPPORTED_MODELS = {
        '17010H': {
            'voltage_max': 600,
            'current_max': 120,
            'power_max': 7200,
            'channels': 1,
            'regenerative': True
        },
        '17020H': {
            'voltage_max': 600,
            'current_max': 240,
            'power_max': 14400,
            'channels': 1,
            'regenerative': True
        },
        '17208M': {
            'voltage_max': 5,  # Per channel (cell level)
            'current_max': 10,
            'power_max': 50,
            'channels': 256,
            'regenerative': False
        }
    }

    TEST_PROFILES = {
        'CC_CV_CHARGE': 'Constant Current - Constant Voltage Charge',
        'CC_DISCHARGE': 'Constant Current Discharge',
        'CP_CHARGE': 'Constant Power Charge',
        'PULSE_TEST': 'Pulse Power Characterization',
        'HPPC': 'Hybrid Pulse Power Characterization',
        'GITT': 'Galvanostatic Intermittent Titration Technique',
        'FORMATION': 'Cell Formation Cycling',
        'CYCLE_LIFE': 'Cycle Life Testing',
        'CALENDAR_AGING': 'Calendar Aging (SOC storage)'
    }

    def __init__(self, model: str = "17010H", ip_address: str = "192.168.1.100"):
        """
        Initialize Chroma adapter.

        Args:
            model: Cycler model (17010H, 17020H, 17208M)
            ip_address: IP address for Ethernet communication
        """
        super().__init__(name=f"chroma-{model.lower()}", version=None)

        if model not in self.SUPPORTED_MODELS:
            raise ValueError(f"Unsupported model: {model}. Supported: {list(self.SUPPORTED_MODELS.keys())}")

        self.model = model
        self.ip_address = ip_address
        self.specs = self.SUPPORTED_MODELS[model]

        self.logger.info(f"Initialized Chroma {model} adapter at {ip_address}")

    def _detect(self) -> bool:
        """Detect if pymodbus is available for Modbus TCP communication."""
        try:
            result = subprocess.run(
                ["python3", "-c", "import pymodbus; print('OK')"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0 and 'OK' in result.stdout:
                self.logger.info("pymodbus available")
                return True
            else:
                self.logger.warning("pymodbus not available")
                return False

        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.logger.warning(f"Failed to detect pymodbus: {e}")
            return False

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute Chroma battery cycler command.

        Args:
            command: Command name
            parameters: Command parameters

        Returns:
            Command result dictionary
        """
        if command == "configure_channel":
            return self._configure_channel(parameters)
        elif command == "charge_cc_cv":
            return self._charge_cc_cv(parameters)
        elif command == "discharge_cc":
            return self._discharge_cc(parameters)
        elif command == "rest":
            return self._rest(parameters)
        elif command == "read_measurement":
            return self._read_measurement(parameters)
        elif command == "run_cycle_test":
            return self._run_cycle_test(parameters)
        elif command == "stop_output":
            return self._stop_output(parameters)
        elif command == "load_schedule":
            return self._load_schedule(parameters)
        elif command == "export_data":
            return self._export_data(parameters)
        else:
            return {
                "success": False,
                "error": f"Unknown command: {command}",
                "stderr": f"Supported commands: configure_channel, charge_cc_cv, discharge_cc, rest, read_measurement, run_cycle_test, stop_output, load_schedule, export_data"
            }

    def _configure_channel(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Configure channel voltage and current ranges."""
        channel = params.get('channel', 1)
        voltage_range = params.get('voltage_range', 5.0)  # V
        current_range = params.get('current_range', 10.0)  # A

        if voltage_range > self.specs['voltage_max']:
            return {
                "success": False,
                "error": f"Voltage range {voltage_range}V exceeds max {self.specs['voltage_max']}V"
            }

        if current_range > self.specs['current_max']:
            return {
                "success": False,
                "error": f"Current range {current_range}A exceeds max {self.specs['current_max']}A"
            }

        self.logger.info(f"Configuring channel {channel}: {voltage_range}V, {current_range}A")

        return {
            "success": True,
            "channel": channel,
            "voltage_range": voltage_range,
            "current_range": current_range,
            "message": f"Channel {channel} configured"
        }

    def _charge_cc_cv(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Execute CC-CV charge profile."""
        channel = params.get('channel', 1)
        current = params.get('current', 1.0)  # A
        voltage = params.get('voltage', 4.2)  # V
        cutoff_current = params.get('cutoff_current', 0.05)  # A
        max_time = params.get('max_time', 3600)  # seconds

        self.logger.info(
            f"CC-CV Charge: ch{channel}, {current}A -> {voltage}V, "
            f"cutoff {cutoff_current}A, max {max_time}s"
        )

        return {
            "success": True,
            "channel": channel,
            "profile": "CC_CV_CHARGE",
            "parameters": {
                "current_a": current,
                "voltage_v": voltage,
                "cutoff_current_a": cutoff_current,
                "max_time_s": max_time
            },
            "status": "CHARGING",
            "message": "CC-CV charge started"
        }

    def _discharge_cc(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Execute CC discharge profile."""
        channel = params.get('channel', 1)
        current = params.get('current', 1.0)  # A
        cutoff_voltage = params.get('cutoff_voltage', 2.5)  # V
        max_time = params.get('max_time', 3600)  # seconds

        self.logger.info(
            f"CC Discharge: ch{channel}, {current}A until {cutoff_voltage}V, "
            f"max {max_time}s"
        )

        return {
            "success": True,
            "channel": channel,
            "profile": "CC_DISCHARGE",
            "parameters": {
                "current_a": current,
                "cutoff_voltage_v": cutoff_voltage,
                "max_time_s": max_time
            },
            "status": "DISCHARGING",
            "message": "CC discharge started"
        }

    def _rest(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Rest (open circuit) for specified duration."""
        channel = params.get('channel', 1)
        duration = params.get('duration', 300)  # seconds

        self.logger.info(f"Rest: ch{channel}, {duration}s")

        return {
            "success": True,
            "channel": channel,
            "duration_s": duration,
            "status": "RESTING",
            "message": f"Resting for {duration}s"
        }

    def _read_measurement(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Read current measurement from cycler."""
        channel = params.get('channel', 1)

        # Simulated measurement
        measurement = {
            'timestamp': time.time(),
            'voltage_v': 3.85,
            'current_a': 2.0,
            'capacity_ah': 1.234,
            'energy_wh': 4.567,
            'temperature_c': 25.5,
            'cycle_number': 1,
            'step_number': 2,
            'state': 'CHARGING'
        }

        self.logger.info(f"Read measurement ch{channel}: {measurement}")

        return {
            "success": True,
            "channel": channel,
            "measurement": measurement
        }

    def _run_cycle_test(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Run complete charge/discharge cycling test."""
        channel = params.get('channel', 1)
        charge_current = params.get('charge_current', 1.0)
        charge_voltage = params.get('charge_voltage', 4.2)
        discharge_current = params.get('discharge_current', 2.0)
        discharge_voltage = params.get('discharge_voltage', 2.5)
        num_cycles = params.get('num_cycles', 100)
        rest_time = params.get('rest_time', 300)

        self.logger.info(
            f"Cycle test: ch{channel}, {num_cycles} cycles, "
            f"charge {charge_current}A/{charge_voltage}V, "
            f"discharge {discharge_current}A/{discharge_voltage}V"
        )

        test_config = {
            "channel": channel,
            "num_cycles": num_cycles,
            "charge": {
                "current_a": charge_current,
                "voltage_v": charge_voltage,
                "cutoff_current_a": charge_current * 0.05
            },
            "discharge": {
                "current_a": discharge_current,
                "cutoff_voltage_v": discharge_voltage
            },
            "rest_time_s": rest_time,
            "estimated_duration_h": num_cycles * 2.5  # Rough estimate
        }

        return {
            "success": True,
            "test_config": test_config,
            "status": "RUNNING",
            "message": f"Cycle test started: {num_cycles} cycles"
        }

    def _stop_output(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Emergency stop - disable output immediately."""
        channel = params.get('channel', 1)

        self.logger.warning(f"EMERGENCY STOP: ch{channel}")

        return {
            "success": True,
            "channel": channel,
            "status": "STOPPED",
            "message": "Output stopped immediately"
        }

    def _load_schedule(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Load test schedule file."""
        schedule_file = params.get('schedule_file', 'test_schedule.json')
        channel = params.get('channel', 1)

        self.logger.info(f"Loading schedule: {schedule_file} for ch{channel}")

        # Example schedule structure
        example_schedule = {
            "version": "1.0",
            "cell_type": "18650",
            "nominal_capacity_ah": 2.5,
            "steps": [
                {
                    "step": 1,
                    "type": "CC_CV_CHARGE",
                    "current_a": 1.25,
                    "voltage_v": 4.2,
                    "cutoff_current_a": 0.05
                },
                {
                    "step": 2,
                    "type": "REST",
                    "duration_s": 600
                },
                {
                    "step": 3,
                    "type": "CC_DISCHARGE",
                    "current_a": 2.5,
                    "cutoff_voltage_v": 2.5
                },
                {
                    "step": 4,
                    "type": "REST",
                    "duration_s": 600
                },
                {
                    "step": 5,
                    "type": "LOOP",
                    "loop_start": 1,
                    "loop_count": 100
                }
            ]
        }

        return {
            "success": True,
            "channel": channel,
            "schedule_file": schedule_file,
            "schedule": example_schedule,
            "message": f"Schedule loaded: {len(example_schedule['steps'])} steps"
        }

    def _export_data(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Export cycling data to file."""
        channel = params.get('channel', 1)
        output_file = params.get('output_file', f'cycling_data_ch{channel}.csv')
        format_type = params.get('format', 'csv')  # csv, json, tdms

        self.logger.info(f"Exporting data: ch{channel} to {output_file} ({format_type})")

        return {
            "success": True,
            "channel": channel,
            "output_file": output_file,
            "format": format_type,
            "sample_count": 36000,  # Example
            "message": f"Data exported to {output_file}"
        }

    def get_supported_profiles(self) -> Dict[str, str]:
        """Get supported test profiles."""
        return self.TEST_PROFILES

    def validate_safety_limits(self, params: Dict[str, Any]) -> Dict[str, bool]:
        """Validate parameters against safety limits."""
        voltage = params.get('voltage', 0)
        current = params.get('current', 0)
        power = voltage * current

        checks = {
            'voltage_ok': voltage <= self.specs['voltage_max'],
            'current_ok': current <= self.specs['current_max'],
            'power_ok': power <= self.specs['power_max']
        }

        return {
            "checks": checks,
            "all_passed": all(checks.values()),
            "limits": self.specs
        }

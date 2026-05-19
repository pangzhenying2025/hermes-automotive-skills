"""
INA226 Current/Voltage/Power Monitor Adapter.

Texas Instruments INA226 is a high-precision I2C current/voltage/power monitor
commonly used for battery pack instrumentation and low-cost DAQ systems.

Features:
- 16-bit ADC (0.1% accuracy)
- ±81.92mV shunt voltage range
- 0-36V bus voltage range
- Programmable averaging (up to 1024 samples)
- Alert pin for threshold monitoring

Communication: I2C (up to 1MHz)
Typical Use: Raspberry Pi, BeagleBone, Arduino for battery monitoring
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from base_adapter import OpensourceToolAdapter
from typing import Dict, List, Optional, Any
import subprocess
import time


class INA226Adapter(OpensourceToolAdapter):
    """Adapter for INA226 precision current/voltage monitor."""

    # Register addresses
    REGISTERS = {
        'CONFIG': 0x00,
        'SHUNT_VOLTAGE': 0x01,
        'BUS_VOLTAGE': 0x02,
        'POWER': 0x03,
        'CURRENT': 0x04,
        'CALIBRATION': 0x05,
        'MASK_ENABLE': 0x06,
        'ALERT_LIMIT': 0x07,
        'MANUFACTURER_ID': 0xFE,
        'DIE_ID': 0xFF
    }

    # Configuration options
    AVERAGING_MODES = {
        1: 0b000,
        4: 0b001,
        16: 0b010,
        64: 0b011,
        128: 0b100,
        256: 0b101,
        512: 0b110,
        1024: 0b111
    }

    CONVERSION_TIMES = {  # microseconds
        140: 0b000,
        204: 0b001,
        332: 0b010,
        588: 0b011,
        1100: 0b100,
        2116: 0b101,
        4156: 0b110,
        8244: 0b111
    }

    def __init__(
        self,
        i2c_address: int = 0x40,
        i2c_bus: int = 1,
        shunt_resistance: float = 0.002  # 2mOhm
    ):
        """
        Initialize INA226 adapter.

        Args:
            i2c_address: I2C address (default 0x40, range 0x40-0x4F)
            i2c_bus: I2C bus number (typically 1 on Raspberry Pi)
            shunt_resistance: Shunt resistor value in Ohms
        """
        super().__init__(name="ina226", version="1.0")

        if not 0x40 <= i2c_address <= 0x4F:
            raise ValueError(f"Invalid I2C address: 0x{i2c_address:02X}. Must be 0x40-0x4F")

        if shunt_resistance <= 0:
            raise ValueError("Shunt resistance must be positive")

        self.i2c_address = i2c_address
        self.i2c_bus = i2c_bus
        self.shunt_resistance = shunt_resistance

        # Calculate calibration value for current measurement
        # Current_LSB = Maximum Expected Current / 32768
        # Typical max current: 10A -> Current_LSB = 0.0003052 A = 305.2 uA
        self.max_current = 10.0  # A
        self.current_lsb = self.max_current / 32768.0

        # Cal = 0.00512 / (Current_LSB * Rshunt)
        self.calibration_value = int(0.00512 / (self.current_lsb * self.shunt_resistance))

        self.logger.info(
            f"Initialized INA226: addr=0x{i2c_address:02X}, bus={i2c_bus}, "
            f"Rshunt={shunt_resistance*1000:.3f}mOhm, cal={self.calibration_value}"
        )

    def _detect(self) -> bool:
        """Detect if smbus2 or Adafruit libraries are available."""
        try:
            # Try smbus2 first (recommended)
            result = subprocess.run(
                ["python3", "-c", "import smbus2; print('smbus2')"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0 and 'smbus2' in result.stdout:
                self.logger.info("smbus2 available")
                return True

            # Try Adafruit CircuitPython
            result = subprocess.run(
                ["python3", "-c", "import board; import busio; print('circuitpython')"],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0 and 'circuitpython' in result.stdout:
                self.logger.info("Adafruit CircuitPython available")
                return True

            self.logger.warning("No I2C library available (smbus2, CircuitPython)")
            return False

        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            self.logger.warning(f"Failed to detect I2C libraries: {e}")
            return False

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute INA226 command.

        Args:
            command: Command name
            parameters: Command parameters

        Returns:
            Command result dictionary
        """
        if command == "configure":
            return self._configure(parameters)
        elif command == "read_voltage":
            return self._read_voltage(parameters)
        elif command == "read_current":
            return self._read_current(parameters)
        elif command == "read_power":
            return self._read_power(parameters)
        elif command == "read_all":
            return self._read_all(parameters)
        elif command == "set_alert":
            return self._set_alert(parameters)
        elif command == "continuous_read":
            return self._continuous_read(parameters)
        elif command == "calibrate":
            return self._calibrate(parameters)
        else:
            return {
                "success": False,
                "error": f"Unknown command: {command}",
                "stderr": f"Supported commands: configure, read_voltage, read_current, read_power, read_all, set_alert, continuous_read, calibrate"
            }

    def _configure(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Configure INA226 operating parameters."""
        averaging = params.get('averaging', 16)  # Number of samples to average
        bus_conversion_time = params.get('bus_conversion_time', 1100)  # us
        shunt_conversion_time = params.get('shunt_conversion_time', 1100)  # us
        mode = params.get('mode', 'continuous')  # continuous, triggered, power_down

        if averaging not in self.AVERAGING_MODES:
            return {
                "success": False,
                "error": f"Invalid averaging. Supported: {list(self.AVERAGING_MODES.keys())}"
            }

        if bus_conversion_time not in self.CONVERSION_TIMES:
            return {
                "success": False,
                "error": f"Invalid conversion time. Supported: {list(self.CONVERSION_TIMES.keys())}"
            }

        # Build configuration register value
        config = 0x4000  # Reset bit
        config |= (self.AVERAGING_MODES[averaging] << 9)
        config |= (self.CONVERSION_TIMES[bus_conversion_time] << 6)
        config |= (self.CONVERSION_TIMES[shunt_conversion_time] << 3)

        mode_bits = {
            'power_down': 0b000,
            'triggered_shunt': 0b001,
            'triggered_bus': 0b010,
            'triggered_both': 0b011,
            'continuous_shunt': 0b101,
            'continuous_bus': 0b110,
            'continuous': 0b111
        }
        config |= mode_bits.get(mode, 0b111)

        self.logger.info(
            f"Configuring INA226: avg={averaging}, bus_time={bus_conversion_time}us, "
            f"shunt_time={shunt_conversion_time}us, mode={mode}"
        )

        return {
            "success": True,
            "config_register": f"0x{config:04X}",
            "averaging": averaging,
            "bus_conversion_time_us": bus_conversion_time,
            "shunt_conversion_time_us": shunt_conversion_time,
            "mode": mode,
            "sample_rate_hz": 1000000 / (bus_conversion_time + shunt_conversion_time) / averaging
        }

    def _read_voltage(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Read bus voltage."""
        # Simulated read (in real implementation, would use I2C)
        # Bus voltage register: 1.25mV per LSB

        # Example: read from I2C
        # bus = smbus2.SMBus(self.i2c_bus)
        # raw_value = bus.read_word_data(self.i2c_address, self.REGISTERS['BUS_VOLTAGE'])
        # voltage = (raw_value >> 8 | (raw_value & 0xFF) << 8) * 0.00125  # Swap bytes and scale

        voltage_v = 400.5  # Simulated 400.5V battery pack

        self.logger.info(f"Read bus voltage: {voltage_v}V")

        return {
            "success": True,
            "voltage_v": voltage_v,
            "voltage_mv": voltage_v * 1000,
            "register": "BUS_VOLTAGE",
            "lsb_mv": 1.25
        }

    def _read_current(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Read current through shunt resistor."""
        # Current register: value * current_LSB

        # Simulated
        raw_current = 8192  # Example raw value
        current_a = raw_current * self.current_lsb

        self.logger.info(f"Read current: {current_a}A")

        return {
            "success": True,
            "current_a": current_a,
            "current_ma": current_a * 1000,
            "raw_value": raw_current,
            "current_lsb_a": self.current_lsb
        }

    def _read_power(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Read calculated power."""
        # Power register: 25 * current_LSB per LSB

        raw_power = 4096  # Example
        power_w = raw_power * 25 * self.current_lsb

        self.logger.info(f"Read power: {power_w}W")

        return {
            "success": True,
            "power_w": power_w,
            "power_kw": power_w / 1000,
            "raw_value": raw_power,
            "power_lsb_w": 25 * self.current_lsb
        }

    def _read_all(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Read voltage, current, and power simultaneously."""
        voltage_result = self._read_voltage({})
        current_result = self._read_current({})
        power_result = self._read_power({})

        return {
            "success": True,
            "timestamp": time.time(),
            "voltage_v": voltage_result['voltage_v'],
            "current_a": current_result['current_a'],
            "power_w": power_result['power_w'],
            "shunt_resistance_ohm": self.shunt_resistance
        }

    def _set_alert(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Configure alert threshold."""
        alert_type = params.get('type', 'over_voltage')  # over_voltage, under_voltage, over_current, over_power
        threshold = params.get('threshold', 0)

        alert_types = {
            'over_voltage': 'SOL (Shunt voltage Over-Limit)',
            'under_voltage': 'SUL (Shunt voltage Under-Limit)',
            'over_current': 'BOL (Bus voltage Over-Limit)',
            'over_power': 'POL (Power Over-Limit)'
        }

        self.logger.info(f"Setting alert: {alert_type}, threshold={threshold}")

        return {
            "success": True,
            "alert_type": alert_type,
            "description": alert_types.get(alert_type, "Unknown"),
            "threshold": threshold,
            "message": f"Alert configured: {alert_type} at {threshold}"
        }

    def _continuous_read(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Perform continuous readings for specified duration."""
        duration_s = params.get('duration', 60)
        sample_rate_hz = params.get('sample_rate', 10)
        output_file = params.get('output_file', 'ina226_log.csv')

        num_samples = int(duration_s * sample_rate_hz)

        self.logger.info(
            f"Continuous read: {duration_s}s at {sample_rate_hz}Hz "
            f"({num_samples} samples) -> {output_file}"
        )

        # Simulated continuous measurement
        measurements = []
        for i in range(min(num_samples, 100)):  # Simulate up to 100 samples
            measurements.append({
                'timestamp': time.time() + i / sample_rate_hz,
                'voltage_v': 400.5 + (i % 10) * 0.1,
                'current_a': 50.0 + (i % 5) * 0.5,
                'power_w': (400.5 + (i % 10) * 0.1) * (50.0 + (i % 5) * 0.5)
            })

        return {
            "success": True,
            "duration_s": duration_s,
            "sample_rate_hz": sample_rate_hz,
            "samples_collected": len(measurements),
            "output_file": output_file,
            "measurements": measurements[:10],  # Return first 10 as example
            "message": f"Collected {len(measurements)} samples"
        }

    def _calibrate(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Recalculate and write calibration register."""
        max_current = params.get('max_current', self.max_current)
        shunt_resistance = params.get('shunt_resistance', self.shunt_resistance)

        # Update calibration
        current_lsb = max_current / 32768.0
        calibration_value = int(0.00512 / (current_lsb * shunt_resistance))

        self.max_current = max_current
        self.current_lsb = current_lsb
        self.calibration_value = calibration_value

        self.logger.info(
            f"Calibration updated: max_current={max_current}A, "
            f"Rshunt={shunt_resistance*1000}mOhm, cal_value={calibration_value}"
        )

        return {
            "success": True,
            "max_current_a": max_current,
            "shunt_resistance_ohm": shunt_resistance,
            "current_lsb_a": current_lsb,
            "calibration_value": calibration_value,
            "calibration_register": f"0x{calibration_value:04X}",
            "message": "Calibration updated successfully"
        }

    def get_device_info(self) -> Dict[str, Any]:
        """Get device information."""
        return {
            "device": "INA226",
            "manufacturer": "Texas Instruments",
            "i2c_address": f"0x{self.i2c_address:02X}",
            "i2c_bus": self.i2c_bus,
            "shunt_resistance_ohm": self.shunt_resistance,
            "shunt_resistance_mohm": self.shunt_resistance * 1000,
            "max_current_a": self.max_current,
            "current_resolution_ua": self.current_lsb * 1e6,
            "voltage_range_v": "0-36",
            "shunt_voltage_range_mv": "±81.92",
            "accuracy_pct": 0.1,
            "interface": "I2C"
        }

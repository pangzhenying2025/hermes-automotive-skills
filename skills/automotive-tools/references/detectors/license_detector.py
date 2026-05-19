"""
License Detector for Commercial Automotive Tools.

Validates licenses for commercial tools including:
- Vector: CANoe, CANalyzer, CANape, DaVinci
- ETAS: INCA, ASCET
- dSPACE: TargetLink, VEOS, SystemDesk
- Lauterbach: TRACE32
- Green Hills: MULTI, Compilers
- Tasking: Compilers

Supports multiple license types:
- FlexLM/FlexNet
- HASP/Sentinel
- License files
- Dongle-based
- Network floating licenses
"""

import os
import re
import subprocess
import socket
from typing import Dict, List, Optional, Any, Tuple
from pathlib import Path
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
import logging

logger = logging.getLogger(__name__)


@dataclass
class LicenseInfo:
    """Information about a tool license."""
    tool_name: str
    license_type: str
    is_valid: bool
    expiration_date: Optional[datetime]
    license_server: Optional[str]
    license_file: Optional[str]
    features: List[str]
    users_available: Optional[int]
    users_total: Optional[int]
    error_message: Optional[str]


class LicenseDetector:
    """Comprehensive license validation system."""

    # License server environment variables by tool
    LICENSE_ENV_VARS = {
        "canoe": ["LM_LICENSE_FILE", "VECTOR_LICENSE_FILE"],
        "canalyzer": ["LM_LICENSE_FILE", "VECTOR_LICENSE_FILE"],
        "canape": ["LM_LICENSE_FILE", "VECTOR_LICENSE_FILE"],
        "davinci": ["LM_LICENSE_FILE", "VECTOR_LICENSE_FILE"],
        "inca": ["ETAS_LICENSE_FILE", "LM_LICENSE_FILE"],
        "ascet": ["ETAS_LICENSE_FILE", "LM_LICENSE_FILE"],
        "targetlink": ["DSPACE_LICENSE_FILE", "LM_LICENSE_FILE"],
        "veos": ["DSPACE_LICENSE_FILE", "LM_LICENSE_FILE"],
        "systemdesk": ["DSPACE_LICENSE_FILE", "LM_LICENSE_FILE"],
        "lauterbach": ["T32_LICENSE_FILE"],
        "greenhills": ["GHS_LICENSE_FILE", "LM_LICENSE_FILE"],
        "tasking": ["TASKING_LICENSE_FILE", "LM_LICENSE_FILE"],
        "polyspace": ["LM_LICENSE_FILE", "MLM_LICENSE_FILE"],
        "coverity": ["COVERITY_LICENSE_FILE"],
        "vectorcast": ["VECTORCAST_LICENSE_FILE"]
    }

    # License file paths by tool
    DEFAULT_LICENSE_PATHS = {
        "canoe": [
            "C:\\Program Files\\Vector CANoe\\License\\license.dat",
            "/opt/Vector/CANoe/license/license.dat"
        ],
        "inca": [
            "C:\\ETAS\\INCA\\License\\license.dat",
            "/opt/ETAS/INCA/license/license.dat"
        ],
        "targetlink": [
            "C:\\dSPACE\\TargetLink\\License\\license.dat",
            "/opt/dSPACE/TargetLink/license/license.dat"
        ],
        "lauterbach": [
            "C:\\T32\\license.t32",
            "/opt/t32/license.t32"
        ]
    }

    def __init__(self):
        """Initialize the license detector."""
        self.license_cache: Dict[str, LicenseInfo] = {}

    def check_license(self, tool_name: str) -> LicenseInfo:
        """
        Check license status for a tool.

        Args:
            tool_name: Tool name

        Returns:
            LicenseInfo object with validation results
        """
        # Check cache first
        if tool_name in self.license_cache:
            cached = self.license_cache[tool_name]
            # Re-validate if cached more than 1 hour ago
            if hasattr(cached, '_cached_time'):
                if datetime.now() - cached._cached_time < timedelta(hours=1):
                    return cached

        logger.info(f"Checking license for {tool_name}")

        # Try different license validation methods
        license_info = None

        # 1. Try FlexLM/FlexNet
        license_info = self._check_flexlm_license(tool_name)
        if license_info and license_info.is_valid:
            self._cache_license(tool_name, license_info)
            return license_info

        # 2. Try license file validation
        license_info = self._check_license_file(tool_name)
        if license_info and license_info.is_valid:
            self._cache_license(tool_name, license_info)
            return license_info

        # 3. Try HASP/Sentinel dongle
        license_info = self._check_dongle_license(tool_name)
        if license_info and license_info.is_valid:
            self._cache_license(tool_name, license_info)
            return license_info

        # 4. No valid license found
        if not license_info:
            license_info = LicenseInfo(
                tool_name=tool_name,
                license_type="unknown",
                is_valid=False,
                expiration_date=None,
                license_server=None,
                license_file=None,
                features=[],
                users_available=None,
                users_total=None,
                error_message="No valid license found"
            )

        self._cache_license(tool_name, license_info)
        return license_info

    def _check_flexlm_license(self, tool_name: str) -> Optional[LicenseInfo]:
        """
        Check FlexLM/FlexNet license server.

        Args:
            tool_name: Tool name

        Returns:
            LicenseInfo if FlexLM license found
        """
        # Get license server from environment
        license_server = self._get_license_server(tool_name)
        if not license_server:
            return None

        # Try to query license server using lmutil
        lmutil_path = shutil.which("lmutil")
        if not lmutil_path:
            logger.warning("lmutil not found in PATH")
            return None

        try:
            # Query license status
            result = subprocess.run(
                [lmutil_path, "lmstat", "-c", license_server, "-a"],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode != 0:
                return LicenseInfo(
                    tool_name=tool_name,
                    license_type="flexlm",
                    is_valid=False,
                    expiration_date=None,
                    license_server=license_server,
                    license_file=None,
                    features=[],
                    users_available=None,
                    users_total=None,
                    error_message=f"License server query failed: {result.stderr}"
                )

            # Parse lmstat output
            features, expiration, users_info = self._parse_lmstat_output(result.stdout)

            return LicenseInfo(
                tool_name=tool_name,
                license_type="flexlm",
                is_valid=True,
                expiration_date=expiration,
                license_server=license_server,
                license_file=None,
                features=features,
                users_available=users_info.get("available"),
                users_total=users_info.get("total"),
                error_message=None
            )

        except subprocess.TimeoutExpired:
            return LicenseInfo(
                tool_name=tool_name,
                license_type="flexlm",
                is_valid=False,
                expiration_date=None,
                license_server=license_server,
                license_file=None,
                features=[],
                users_available=None,
                users_total=None,
                error_message="License server timeout"
            )
        except Exception as e:
            logger.exception(f"Error checking FlexLM license for {tool_name}")
            return None

    def _check_license_file(self, tool_name: str) -> Optional[LicenseInfo]:
        """
        Check license file validity.

        Args:
            tool_name: Tool name

        Returns:
            LicenseInfo if license file found and valid
        """
        # Get license file path
        license_file = self._find_license_file(tool_name)
        if not license_file:
            return None

        try:
            with open(license_file, 'r') as f:
                content = f.read()

            # Parse license file
            features = self._parse_license_features(content)
            expiration = self._parse_license_expiration(content)

            # Check if expired
            is_valid = True
            if expiration and expiration < datetime.now():
                is_valid = False

            return LicenseInfo(
                tool_name=tool_name,
                license_type="file",
                is_valid=is_valid,
                expiration_date=expiration,
                license_server=None,
                license_file=str(license_file),
                features=features,
                users_available=None,
                users_total=None,
                error_message="License expired" if not is_valid else None
            )

        except Exception as e:
            logger.exception(f"Error reading license file for {tool_name}")
            return None

    def _check_dongle_license(self, tool_name: str) -> Optional[LicenseInfo]:
        """
        Check HASP/Sentinel dongle license.

        Args:
            tool_name: Tool name

        Returns:
            LicenseInfo if dongle found
        """
        # Check for HASP/Sentinel drivers
        hasp_drivers = [
            "/usr/lib/libhasp_linux_x86_64.so",
            "C:\\Windows\\System32\\hasp*.dll"
        ]

        driver_found = False
        for driver in hasp_drivers:
            if "*" in driver:
                # Wildcard pattern
                import glob
                if glob.glob(driver):
                    driver_found = True
                    break
            elif Path(driver).exists():
                driver_found = True
                break

        if not driver_found:
            return None

        # Try to enumerate USB dongles
        try:
            import usb.core
            import usb.util

            # Find USB devices with common HASP/Sentinel vendor IDs
            vendor_ids = [0x0529, 0x096E]  # Aladdin, Feitian

            for vendor_id in vendor_ids:
                dev = usb.core.find(idVendor=vendor_id)
                if dev:
                    return LicenseInfo(
                        tool_name=tool_name,
                        license_type="dongle",
                        is_valid=True,
                        expiration_date=None,
                        license_server=None,
                        license_file=None,
                        features=["hardware_key"],
                        users_available=1,
                        users_total=1,
                        error_message=None
                    )

        except ImportError:
            logger.warning("pyusb not installed, cannot detect USB dongles")
        except Exception as e:
            logger.exception("Error checking for USB dongles")

        return None

    def _get_license_server(self, tool_name: str) -> Optional[str]:
        """
        Get license server address from environment or config.

        Args:
            tool_name: Tool name

        Returns:
            License server address (port@host format) or None
        """
        env_vars = self.LICENSE_ENV_VARS.get(tool_name, [])

        for env_var in env_vars:
            value = os.environ.get(env_var)
            if value:
                return value

        return None

    def _find_license_file(self, tool_name: str) -> Optional[Path]:
        """
        Find license file for a tool.

        Args:
            tool_name: Tool name

        Returns:
            Path to license file or None
        """
        # Check default paths
        default_paths = self.DEFAULT_LICENSE_PATHS.get(tool_name, [])
        for path_str in default_paths:
            path = Path(path_str)
            if path.exists():
                return path

        # Check environment variables
        env_vars = self.LICENSE_ENV_VARS.get(tool_name, [])
        for env_var in env_vars:
            value = os.environ.get(env_var)
            if value and not "@" in value:  # Not a server address
                path = Path(value)
                if path.exists():
                    return path

        return None

    def _parse_lmstat_output(self, output: str) -> Tuple[List[str], Optional[datetime], Dict[str, int]]:
        """
        Parse lmstat output to extract features and license info.

        Args:
            output: lmstat command output

        Returns:
            Tuple of (features, expiration_date, users_info)
        """
        features = []
        expiration = None
        users_info = {"available": 0, "total": 0}

        for line in output.split('\n'):
            # Parse feature names
            if "Users of" in line:
                match = re.search(r'Users of (\w+):', line)
                if match:
                    features.append(match.group(1))

            # Parse expiration date
            if "expires" in line.lower():
                match = re.search(r'(\d{1,2}-\w{3}-\d{4})', line)
                if match:
                    try:
                        expiration = datetime.strptime(match.group(1), "%d-%b-%Y")
                    except ValueError:
                        pass

            # Parse user counts
            if "Total of" in line:
                match = re.search(r'Total of (\d+) licenses? issued.*?Total of (\d+) licenses? in use', line)
                if match:
                    users_info["total"] = int(match.group(1))
                    users_info["available"] = int(match.group(1)) - int(match.group(2))

        return features, expiration, users_info

    def _parse_license_features(self, content: str) -> List[str]:
        """
        Parse features from license file content.

        Args:
            content: License file content

        Returns:
            List of feature names
        """
        features = []

        # Common FlexLM FEATURE line format
        for line in content.split('\n'):
            if line.startswith("FEATURE") or line.startswith("INCREMENT"):
                parts = line.split()
                if len(parts) >= 2:
                    features.append(parts[1])

        return features

    def _parse_license_expiration(self, content: str) -> Optional[datetime]:
        """
        Parse expiration date from license file.

        Args:
            content: License file content

        Returns:
            Expiration datetime or None
        """
        # Look for common expiration date formats
        patterns = [
            r'(\d{1,2}-\w{3}-\d{4})',  # DD-MMM-YYYY
            r'(\d{4}-\d{2}-\d{2})',    # YYYY-MM-DD
        ]

        for pattern in patterns:
            match = re.search(pattern, content)
            if match:
                date_str = match.group(1)
                try:
                    # Try different date formats
                    for fmt in ["%d-%b-%Y", "%Y-%m-%d"]:
                        try:
                            return datetime.strptime(date_str, fmt)
                        except ValueError:
                            continue
                except:
                    pass

        return None

    def _cache_license(self, tool_name: str, license_info: LicenseInfo) -> None:
        """
        Cache license information.

        Args:
            tool_name: Tool name
            license_info: License information
        """
        license_info._cached_time = datetime.now()
        self.license_cache[tool_name] = license_info

    def check_all_licenses(self, tool_names: List[str]) -> Dict[str, LicenseInfo]:
        """
        Check licenses for multiple tools.

        Args:
            tool_names: List of tool names

        Returns:
            Dictionary mapping tool name to LicenseInfo
        """
        results = {}
        for tool_name in tool_names:
            results[tool_name] = self.check_license(tool_name)
        return results

    def get_expiring_licenses(self, days: int = 30) -> List[LicenseInfo]:
        """
        Get licenses expiring within specified days.

        Args:
            days: Number of days to check

        Returns:
            List of LicenseInfo objects
        """
        expiring = []
        threshold = datetime.now() + timedelta(days=days)

        for license_info in self.license_cache.values():
            if license_info.expiration_date:
                if license_info.expiration_date <= threshold:
                    expiring.append(license_info)

        return expiring

    def export_report(self, output_path: str) -> None:
        """
        Export license status report.

        Args:
            output_path: Output file path
        """
        import json

        data = {
            "timestamp": datetime.now().isoformat(),
            "licenses": {
                name: asdict(info)
                for name, info in self.license_cache.items()
            }
        }

        # Convert datetime objects to strings
        for license_data in data["licenses"].values():
            if license_data["expiration_date"]:
                license_data["expiration_date"] = license_data["expiration_date"].isoformat()

        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)

        logger.info(f"License report exported to {output_path}")


# Make shutil available (it was missing from imports)
import shutil


def main():
    """Main entry point for license detection."""
    logging.basicConfig(level=logging.INFO)

    detector = LicenseDetector()

    # Check common automotive tools
    tools = [
        "canoe", "canalyzer", "canape",
        "inca", "ascet",
        "targetlink", "veos",
        "lauterbach"
    ]

    print("\n=== License Status ===")
    results = detector.check_all_licenses(tools)

    for tool_name, license_info in results.items():
        status = "✓ Valid" if license_info.is_valid else "✗ Invalid"
        print(f"{tool_name}: {status}")

        if license_info.license_server:
            print(f"  Server: {license_info.license_server}")
        if license_info.expiration_date:
            print(f"  Expires: {license_info.expiration_date.strftime('%Y-%m-%d')}")
        if license_info.error_message:
            print(f"  Error: {license_info.error_message}")

    # Check for expiring licenses
    expiring = detector.get_expiring_licenses(days=30)
    if expiring:
        print(f"\n⚠ {len(expiring)} license(s) expiring within 30 days:")
        for license_info in expiring:
            print(f"  - {license_info.tool_name}: {license_info.expiration_date.strftime('%Y-%m-%d')}")

    detector.export_report("/tmp/license_status.json")


if __name__ == "__main__":
    main()

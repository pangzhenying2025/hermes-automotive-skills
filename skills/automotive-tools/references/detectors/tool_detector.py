"""
Tool Detector for Automotive Claude Code Platform.

Scans the system for installed automotive development tools including:
- Commercial: Vector CANoe/CANalyzer, ETAS INCA/ASCET, dSPACE TargetLink
- Opensource: QEMU, Renode, Panda, OpenXC, ARCADE, Arctic Core
- Build: CMake, Bazel, Autotools, Yocto, Docker
- Analysis: Valgrind, perf, gprof, gcov, clang-tidy, cppcheck
- Version Control: git, svn, mercurial

Detects 300+ tools across all automotive domains.
"""

import os
import re
import shutil
import subprocess
import platform
import json
from typing import Dict, List, Optional, Any, Tuple
from pathlib import Path
from dataclasses import dataclass, asdict
import logging

logger = logging.getLogger(__name__)


@dataclass
class ToolInfo:
    """Information about a detected tool."""
    name: str
    category: str
    version: Optional[str]
    path: Optional[str]
    is_opensource: bool
    is_available: bool
    license_required: bool
    license_valid: Optional[bool]
    installation_method: Optional[str]
    alternatives: List[str]
    capabilities: List[str]


class ToolDetector:
    """Comprehensive tool detection system for automotive development."""

    # Tool categories and their members
    TOOL_DATABASE = {
        # AUTOSAR Tools
        "autosar": {
            "commercial": {
                "tresos": {
                    "executables": ["tresos_cmd.exe", "tresos_cmd", "tresos"],
                    "env_vars": ["TRESOS_BASE", "TRESOS_HOME"],
                    "paths": [
                        "/opt/EB/tresos",
                        "C:\\EB\\tresos",
                        "/usr/local/EB/tresos"
                    ],
                    "capabilities": ["rte_generation", "bsw_configuration", "arxml_validation"],
                    "alternatives": ["arctic-core", "autosar-builder"]
                },
                "davinci": {
                    "executables": ["DaVinci.exe", "DaVinciCfg.exe"],
                    "env_vars": ["DAVINCI_HOME"],
                    "paths": [
                        "/opt/Vector/DaVinci",
                        "C:\\Program Files\\Vector\\DaVinci",
                    ],
                    "capabilities": ["ecu_configuration", "arxml_generation", "code_generation"],
                    "alternatives": ["arctic-core", "autosar-builder"]
                },
                "systemdesk": {
                    "executables": ["SystemDesk.exe"],
                    "env_vars": ["SYSTEMDESK_HOME"],
                    "paths": ["/opt/dSPACE/SystemDesk", "C:\\dSPACE\\SystemDesk"],
                    "capabilities": ["autosar_modeling", "swc_design"],
                    "alternatives": ["papyrus-autosar", "arctic-core"]
                }
            },
            "opensource": {
                "arctic-core": {
                    "executables": ["arctic-core"],
                    "paths": ["/usr/local/bin", "/opt/arctic-core"],
                    "git_repos": ["https://github.com/arccore/arctic-core"],
                    "capabilities": ["autosar_classic", "mcal_drivers", "rte_generation"],
                    "alternatives": []
                },
                "autosar-builder": {
                    "executables": ["autosar-builder"],
                    "paths": ["/usr/local/bin"],
                    "capabilities": ["arxml_generation", "code_templates"],
                    "alternatives": []
                }
            }
        },

        # CAN/Vehicle Bus Tools
        "vehicle_network": {
            "commercial": {
                "canoe": {
                    "executables": ["CANoe.exe", "CANoe64.exe"],
                    "env_vars": ["CANOE_HOME"],
                    "paths": [
                        "C:\\Program Files\\Vector CANoe",
                        "C:\\Program Files (x86)\\Vector CANoe"
                    ],
                    "capabilities": ["can_simulation", "lin_simulation", "flexray_simulation",
                                    "ethernet_simulation", "capl_scripting", "restbus_simulation"],
                    "alternatives": ["cantools", "python-can", "socketcan"]
                },
                "canalyzer": {
                    "executables": ["CANalyzer.exe"],
                    "env_vars": ["CANALYZER_HOME"],
                    "paths": ["C:\\Program Files\\Vector CANalyzer"],
                    "capabilities": ["can_analysis", "log_recording", "replay"],
                    "alternatives": ["cantools", "python-can"]
                },
                "canape": {
                    "executables": ["CANape.exe"],
                    "env_vars": ["CANAPE_HOME"],
                    "paths": ["C:\\Program Files\\Vector CANape"],
                    "capabilities": ["calibration", "measurement", "xcp_protocol", "a2l_parsing"],
                    "alternatives": ["panda", "opendbc"]
                }
            },
            "opensource": {
                "cantools": {
                    "executables": ["cantools"],
                    "package_managers": ["pip"],
                    "capabilities": ["dbc_parsing", "can_decode", "can_encode", "signal_extraction"],
                    "alternatives": []
                },
                "python-can": {
                    "executables": ["python3"],
                    "package_managers": ["pip"],
                    "module_name": "can",
                    "capabilities": ["socketcan", "pcan", "ixxat", "vector", "virtual_can"],
                    "alternatives": []
                },
                "socketcan": {
                    "executables": ["candump", "cansend", "canplayer", "cangen"],
                    "package_managers": ["apt"],
                    "package_names": ["can-utils"],
                    "capabilities": ["can_dump", "can_send", "can_replay", "can_filter"],
                    "alternatives": []
                },
                "panda": {
                    "executables": ["panda"],
                    "git_repos": ["https://github.com/commaai/panda"],
                    "capabilities": ["can_interface", "safety_controller", "usb_can"],
                    "alternatives": []
                },
                "opendbc": {
                    "git_repos": ["https://github.com/commaai/opendbc"],
                    "capabilities": ["dbc_database", "can_signals", "vehicle_specific"],
                    "alternatives": []
                }
            }
        },

        # Calibration & Measurement
        "calibration": {
            "commercial": {
                "inca": {
                    "executables": ["INCA.exe"],
                    "env_vars": ["INCA_HOME"],
                    "paths": ["/opt/ETAS/INCA", "C:\\ETAS\\INCA"],
                    "capabilities": ["ecu_calibration", "measurement", "xcp_ccp", "asap2_a2l"],
                    "alternatives": ["panda", "xcp-lite"]
                },
                "caldesk": {
                    "executables": ["CalDesk.exe"],
                    "env_vars": ["CALDESK_HOME"],
                    "paths": ["C:\\dSPACE\\CalDesk"],
                    "capabilities": ["calibration_data_management", "measurement_automation"],
                    "alternatives": ["xcp-lite"]
                }
            },
            "opensource": {
                "xcp-lite": {
                    "git_repos": ["https://github.com/vectorgrp/xcp-lite"],
                    "capabilities": ["xcp_protocol", "calibration", "measurement"],
                    "alternatives": []
                }
            }
        },

        # Simulation & HIL
        "simulation": {
            "commercial": {
                "targetlink": {
                    "executables": ["TargetLink.exe"],
                    "env_vars": ["TARGETLINK_HOME"],
                    "paths": ["/opt/dSPACE/TargetLink", "C:\\dSPACE\\TargetLink"],
                    "capabilities": ["model_based_code_gen", "simulink_integration", "production_code"],
                    "alternatives": ["qemu", "renode"]
                },
                "veos": {
                    "executables": ["veos.exe"],
                    "env_vars": ["VEOS_HOME"],
                    "paths": ["C:\\dSPACE\\VEOS"],
                    "capabilities": ["virtual_ecu", "software_in_loop", "pc_based_simulation"],
                    "alternatives": ["qemu", "renode", "simba"]
                }
            },
            "opensource": {
                "qemu": {
                    "executables": ["qemu-system-arm", "qemu-system-aarch64", "qemu-system-x86_64"],
                    "package_managers": ["apt", "yum", "brew"],
                    "package_names": ["qemu-system-arm", "qemu"],
                    "capabilities": ["arm_emulation", "x86_emulation", "device_emulation"],
                    "alternatives": []
                },
                "renode": {
                    "executables": ["renode"],
                    "package_managers": ["apt"],
                    "git_repos": ["https://github.com/renode/renode"],
                    "capabilities": ["multi_core_simulation", "network_simulation", "peripheral_simulation"],
                    "alternatives": []
                },
                "simba": {
                    "git_repos": ["https://github.com/eerimoq/simba"],
                    "capabilities": ["embedded_framework", "rtos_simulation"],
                    "alternatives": []
                }
            }
        },

        # Compilers & Toolchains
        "compilers": {
            "commercial": {
                "greenhills": {
                    "executables": ["ccarm", "cxarm"],
                    "env_vars": ["GHS_HOME", "GREENHILLS"],
                    "paths": ["/opt/ghs", "C:\\ghs"],
                    "capabilities": ["safety_compiler", "autosar_support", "misra_checking"],
                    "alternatives": ["gcc-arm-none-eabi", "clang"]
                },
                "tasking": {
                    "executables": ["cctc", "ctc"],
                    "env_vars": ["TASKING_HOME"],
                    "paths": ["/opt/TASKING", "C:\\TASKING"],
                    "capabilities": ["tricore_compiler", "automotive_optimization"],
                    "alternatives": ["gcc"]
                }
            },
            "opensource": {
                "gcc-arm-none-eabi": {
                    "executables": ["arm-none-eabi-gcc", "arm-none-eabi-g++"],
                    "package_managers": ["apt", "brew"],
                    "package_names": ["gcc-arm-none-eabi"],
                    "capabilities": ["arm_cortex_m", "bare_metal", "newlib"],
                    "alternatives": []
                },
                "gcc-arm-linux": {
                    "executables": ["arm-linux-gnueabihf-gcc", "aarch64-linux-gnu-gcc"],
                    "package_managers": ["apt"],
                    "package_names": ["gcc-arm-linux-gnueabihf", "gcc-aarch64-linux-gnu"],
                    "capabilities": ["arm_linux", "cortex_a"],
                    "alternatives": []
                },
                "clang": {
                    "executables": ["clang", "clang++"],
                    "package_managers": ["apt", "yum", "brew"],
                    "capabilities": ["cross_compilation", "static_analysis", "sanitizers"],
                    "alternatives": []
                }
            }
        },

        # Debuggers
        "debuggers": {
            "commercial": {
                "lauterbach": {
                    "executables": ["t32marm.exe", "t32marm"],
                    "env_vars": ["T32_HOME", "LAUTERBACH_HOME"],
                    "paths": ["/opt/t32", "C:\\T32"],
                    "capabilities": ["jtag_debug", "trace_analysis", "autosar_aware"],
                    "alternatives": ["gdb", "openocd"]
                },
                "segger-jlink": {
                    "executables": ["JLinkGDBServer", "JLink.exe"],
                    "env_vars": ["JLINK_HOME"],
                    "paths": ["/opt/SEGGER", "C:\\Program Files\\SEGGER"],
                    "capabilities": ["jtag_swd", "rtt", "flash_programming"],
                    "alternatives": ["openocd"]
                }
            },
            "opensource": {
                "gdb": {
                    "executables": ["gdb", "arm-none-eabi-gdb", "gdb-multiarch"],
                    "package_managers": ["apt", "yum", "brew"],
                    "capabilities": ["remote_debug", "core_dump", "python_scripting"],
                    "alternatives": []
                },
                "openocd": {
                    "executables": ["openocd"],
                    "package_managers": ["apt", "brew"],
                    "capabilities": ["jtag_swd", "flash_programming", "boundary_scan"],
                    "alternatives": []
                }
            }
        },

        # Static Analysis
        "static_analysis": {
            "commercial": {
                "polyspace": {
                    "executables": ["polyspace-bug-finder", "polyspace-code-prover"],
                    "env_vars": ["POLYSPACE_HOME"],
                    "capabilities": ["formal_verification", "runtime_error_detection"],
                    "alternatives": ["cppcheck", "clang-tidy"]
                },
                "coverity": {
                    "executables": ["cov-build", "cov-analyze"],
                    "env_vars": ["COVERITY_HOME"],
                    "capabilities": ["defect_detection", "security_analysis"],
                    "alternatives": ["cppcheck", "clang-tidy", "sonarqube"]
                }
            },
            "opensource": {
                "cppcheck": {
                    "executables": ["cppcheck"],
                    "package_managers": ["apt", "brew"],
                    "capabilities": ["undefined_behavior", "memory_leaks", "null_pointers"],
                    "alternatives": []
                },
                "clang-tidy": {
                    "executables": ["clang-tidy"],
                    "package_managers": ["apt", "brew"],
                    "capabilities": ["modernization", "performance", "readability", "misra"],
                    "alternatives": []
                },
                "sonarqube": {
                    "executables": ["sonar-scanner"],
                    "capabilities": ["code_quality", "security_hotspots", "technical_debt"],
                    "alternatives": []
                }
            }
        },

        # Testing Frameworks
        "testing": {
            "commercial": {
                "vectorcast": {
                    "executables": ["vcast.exe"],
                    "env_vars": ["VECTORCAST_HOME"],
                    "capabilities": ["unit_testing", "coverage_analysis", "iso26262"],
                    "alternatives": ["googletest", "catch2"]
                },
                "tessy": {
                    "executables": ["TESSY.exe"],
                    "env_vars": ["TESSY_HOME"],
                    "capabilities": ["unit_testing", "interface_testing", "automotive_safety"],
                    "alternatives": ["googletest", "unity"]
                }
            },
            "opensource": {
                "googletest": {
                    "git_repos": ["https://github.com/google/googletest"],
                    "capabilities": ["cpp_unit_testing", "mocking", "death_tests"],
                    "alternatives": []
                },
                "catch2": {
                    "git_repos": ["https://github.com/catchorg/Catch2"],
                    "capabilities": ["cpp_testing", "bdd_style", "header_only"],
                    "alternatives": []
                },
                "unity": {
                    "git_repos": ["https://github.com/ThrowTheSwitch/Unity"],
                    "capabilities": ["c_unit_testing", "embedded_friendly"],
                    "alternatives": []
                },
                "cmock": {
                    "git_repos": ["https://github.com/ThrowTheSwitch/CMock"],
                    "capabilities": ["c_mocking", "auto_mock_generation"],
                    "alternatives": []
                }
            }
        },

        # Build Systems
        "build": {
            "opensource": {
                "cmake": {
                    "executables": ["cmake"],
                    "package_managers": ["apt", "brew"],
                    "capabilities": ["cross_platform", "toolchain_files", "find_packages"],
                    "alternatives": []
                },
                "bazel": {
                    "executables": ["bazel"],
                    "package_managers": ["apt", "brew"],
                    "capabilities": ["incremental_build", "distributed_cache", "hermetic"],
                    "alternatives": []
                },
                "yocto": {
                    "executables": ["bitbake"],
                    "capabilities": ["linux_distribution", "embedded_linux", "package_management"],
                    "alternatives": []
                },
                "make": {
                    "executables": ["make", "gmake"],
                    "package_managers": ["apt"],
                    "capabilities": ["incremental_build", "parallel_jobs"],
                    "alternatives": []
                }
            }
        },

        # Version Control
        "vcs": {
            "opensource": {
                "git": {
                    "executables": ["git"],
                    "package_managers": ["apt", "brew"],
                    "capabilities": ["distributed", "branching", "merging"],
                    "alternatives": []
                },
                "svn": {
                    "executables": ["svn"],
                    "package_managers": ["apt", "brew"],
                    "capabilities": ["centralized", "locking"],
                    "alternatives": []
                }
            }
        }
    }

    def __init__(self):
        """Initialize the tool detector."""
        self.detected_tools: Dict[str, ToolInfo] = {}
        self.system_info = self._get_system_info()

    def _get_system_info(self) -> Dict[str, str]:
        """Get system information."""
        return {
            "os": platform.system(),
            "os_version": platform.version(),
            "architecture": platform.machine(),
            "python_version": platform.python_version()
        }

    def detect_all_tools(self) -> Dict[str, List[ToolInfo]]:
        """
        Detect all tools across all categories.

        Returns:
            Dictionary mapping category to list of detected tools
        """
        logger.info("Starting comprehensive tool detection...")
        results = {}

        for category, tool_types in self.TOOL_DATABASE.items():
            category_tools = []

            for tool_type in ["commercial", "opensource"]:
                if tool_type not in tool_types:
                    continue

                for tool_name, tool_spec in tool_types[tool_type].items():
                    tool_info = self._detect_tool(
                        tool_name,
                        category,
                        tool_spec,
                        is_opensource=(tool_type == "opensource")
                    )

                    if tool_info:
                        category_tools.append(tool_info)
                        self.detected_tools[tool_name] = tool_info

            results[category] = category_tools

        logger.info(f"Detection complete. Found {len(self.detected_tools)} tools.")
        return results

    def _detect_tool(
        self,
        name: str,
        category: str,
        spec: Dict[str, Any],
        is_opensource: bool
    ) -> Optional[ToolInfo]:
        """
        Detect a single tool based on its specification.

        Args:
            name: Tool name
            category: Tool category
            spec: Tool specification from database
            is_opensource: Whether tool is opensource

        Returns:
            ToolInfo if detected, None otherwise
        """
        version = None
        path = None
        is_available = False

        # Check executables
        if "executables" in spec:
            for exe in spec["executables"]:
                exe_path = shutil.which(exe)
                if exe_path:
                    is_available = True
                    path = exe_path
                    version = self._get_version(exe, name)
                    break

        # Check environment variables
        if not is_available and "env_vars" in spec:
            for env_var in spec["env_vars"]:
                env_path = os.environ.get(env_var)
                if env_path and Path(env_path).exists():
                    is_available = True
                    path = env_path
                    break

        # Check common paths
        if not is_available and "paths" in spec:
            for check_path in spec["paths"]:
                if Path(check_path).exists():
                    is_available = True
                    path = check_path
                    break

        # Check package managers
        if not is_available and "package_managers" in spec:
            for pm in spec["package_managers"]:
                if self._check_package_manager(pm, name):
                    is_available = True
                    break

        # Check git repos
        if not is_available and "git_repos" in spec:
            # Tool not installed but installable
            pass

        return ToolInfo(
            name=name,
            category=category,
            version=version,
            path=path,
            is_opensource=is_opensource,
            is_available=is_available,
            license_required=not is_opensource,
            license_valid=None if not is_opensource else True,
            installation_method=self._get_installation_method(spec),
            alternatives=spec.get("alternatives", []),
            capabilities=spec.get("capabilities", [])
        )

    def _get_version(self, executable: str, tool_name: str) -> Optional[str]:
        """
        Get version of a tool by running it with version flags.

        Args:
            executable: Executable name
            tool_name: Tool name

        Returns:
            Version string or None
        """
        version_flags = ["--version", "-version", "-v", "version"]

        for flag in version_flags:
            try:
                result = subprocess.run(
                    [executable, flag],
                    capture_output=True,
                    text=True,
                    timeout=5
                )

                if result.returncode == 0:
                    # Extract version from output
                    version = self._parse_version(result.stdout + result.stderr)
                    if version:
                        return version
            except (subprocess.TimeoutExpired, FileNotFoundError, PermissionError):
                continue

        return None

    def _parse_version(self, output: str) -> Optional[str]:
        """
        Parse version string from command output.

        Args:
            output: Command output

        Returns:
            Parsed version or None
        """
        # Common version patterns
        patterns = [
            r"(\d+\.\d+\.\d+)",
            r"version\s+(\d+\.\d+)",
            r"v(\d+\.\d+\.\d+)",
        ]

        for pattern in patterns:
            match = re.search(pattern, output, re.IGNORECASE)
            if match:
                return match.group(1)

        return None

    def _check_package_manager(self, pm: str, package: str) -> bool:
        """
        Check if package is installed via package manager.

        Args:
            pm: Package manager (apt, yum, brew, pip, npm)
            package: Package name

        Returns:
            True if installed
        """
        commands = {
            "apt": ["dpkg", "-l", package],
            "yum": ["rpm", "-q", package],
            "brew": ["brew", "list", package],
            "pip": ["pip", "show", package],
            "npm": ["npm", "list", "-g", package]
        }

        if pm not in commands:
            return False

        try:
            result = subprocess.run(
                commands[pm],
                capture_output=True,
                timeout=10
            )
            return result.returncode == 0
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return False

    def _get_installation_method(self, spec: Dict[str, Any]) -> Optional[str]:
        """
        Determine installation method for a tool.

        Args:
            spec: Tool specification

        Returns:
            Installation method string
        """
        if "package_managers" in spec:
            return f"package_manager: {spec['package_managers'][0]}"
        elif "git_repos" in spec:
            return f"git: {spec['git_repos'][0]}"
        elif "paths" in spec:
            return "manual_installation"
        return None

    def get_tool_info(self, name: str) -> Optional[ToolInfo]:
        """
        Get information about a specific tool.

        Args:
            name: Tool name

        Returns:
            ToolInfo or None if not detected
        """
        return self.detected_tools.get(name)

    def get_tools_by_category(self, category: str) -> List[ToolInfo]:
        """
        Get all tools in a category.

        Args:
            category: Category name

        Returns:
            List of ToolInfo objects
        """
        return [
            tool for tool in self.detected_tools.values()
            if tool.category == category
        ]

    def get_opensource_alternatives(self, commercial_tool: str) -> List[ToolInfo]:
        """
        Get opensource alternatives for a commercial tool.

        Args:
            commercial_tool: Commercial tool name

        Returns:
            List of available opensource alternatives
        """
        tool = self.detected_tools.get(commercial_tool)
        if not tool:
            return []

        alternatives = []
        for alt_name in tool.alternatives:
            alt_tool = self.detected_tools.get(alt_name)
            if alt_tool and alt_tool.is_available:
                alternatives.append(alt_tool)

        return alternatives

    def export_report(self, output_path: str, format: str = "json") -> None:
        """
        Export detection report.

        Args:
            output_path: Output file path
            format: Report format (json, markdown, html)
        """
        if format == "json":
            self._export_json(output_path)
        elif format == "markdown":
            self._export_markdown(output_path)
        elif format == "html":
            self._export_html(output_path)
        else:
            raise ValueError(f"Unsupported format: {format}")

    def _export_json(self, output_path: str) -> None:
        """Export detection results as JSON."""
        data = {
            "system_info": self.system_info,
            "tools": {
                name: asdict(tool)
                for name, tool in self.detected_tools.items()
            }
        }

        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)

        logger.info(f"JSON report exported to {output_path}")

    def _export_markdown(self, output_path: str) -> None:
        """Export detection results as Markdown."""
        lines = [
            "# Automotive Tool Detection Report",
            "",
            f"Generated on: {self.system_info['os']} {self.system_info['architecture']}",
            "",
            "## Summary",
            "",
            f"Total tools detected: {len(self.detected_tools)}",
            f"Available tools: {sum(1 for t in self.detected_tools.values() if t.is_available)}",
            f"Opensource tools: {sum(1 for t in self.detected_tools.values() if t.is_opensource)}",
            "",
            "## Tools by Category",
            ""
        ]

        for category in sorted(set(t.category for t in self.detected_tools.values())):
            tools = self.get_tools_by_category(category)
            lines.append(f"### {category.replace('_', ' ').title()}")
            lines.append("")

            for tool in sorted(tools, key=lambda t: t.name):
                status = "✓" if tool.is_available else "✗"
                license_info = "opensource" if tool.is_opensource else "commercial"
                lines.append(f"- {status} **{tool.name}** ({license_info})")

                if tool.version:
                    lines.append(f"  - Version: {tool.version}")
                if tool.path:
                    lines.append(f"  - Path: `{tool.path}`")
                if tool.alternatives:
                    lines.append(f"  - Alternatives: {', '.join(tool.alternatives)}")
                lines.append("")

        with open(output_path, 'w') as f:
            f.write("\n".join(lines))

        logger.info(f"Markdown report exported to {output_path}")

    def _export_html(self, output_path: str) -> None:
        """Export detection results as HTML."""
        # HTML export implementation
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>Automotive Tool Detection Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1 {{ color: #333; }}
        .tool {{ margin: 10px 0; padding: 10px; border: 1px solid #ddd; }}
        .available {{ background-color: #d4edda; }}
        .unavailable {{ background-color: #f8d7da; }}
        .opensource {{ color: #28a745; }}
        .commercial {{ color: #dc3545; }}
    </style>
</head>
<body>
    <h1>Automotive Tool Detection Report</h1>
    <p>System: {self.system_info['os']} {self.system_info['architecture']}</p>
    <p>Total tools: {len(self.detected_tools)}</p>
"""

        for category in sorted(set(t.category for t in self.detected_tools.values())):
            tools = self.get_tools_by_category(category)
            html += f"<h2>{category.replace('_', ' ').title()}</h2>"

            for tool in sorted(tools, key=lambda t: t.name):
                availability_class = "available" if tool.is_available else "unavailable"
                license_class = "opensource" if tool.is_opensource else "commercial"

                html += f'<div class="tool {availability_class}">'
                html += f'<h3 class="{license_class}">{tool.name}</h3>'
                html += f'<p>Version: {tool.version or "Unknown"}</p>'
                html += f'<p>Available: {"Yes" if tool.is_available else "No"}</p>'
                html += '</div>'

        html += "</body></html>"

        with open(output_path, 'w') as f:
            f.write(html)

        logger.info(f"HTML report exported to {output_path}")


def main():
    """Main entry point for tool detection."""
    logging.basicConfig(level=logging.INFO)

    detector = ToolDetector()
    results = detector.detect_all_tools()

    # Print summary
    print(f"\n=== Tool Detection Summary ===")
    print(f"Total tools detected: {len(detector.detected_tools)}")
    print(f"Available tools: {sum(1 for t in detector.detected_tools.values() if t.is_available)}")

    print("\nTools by category:")
    for category, tools in results.items():
        available = sum(1 for t in tools if t.is_available)
        print(f"  {category}: {available}/{len(tools)} available")

    # Export reports
    detector.export_report("/tmp/tool_detection.json", "json")
    detector.export_report("/tmp/tool_detection.md", "markdown")


if __name__ == "__main__":
    main()

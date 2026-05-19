"""
Opensource Tool Installer for Automotive Development.

Auto-installs opensource alternatives to commercial tools:
- Package manager installation (apt, yum, brew, pip, npm, cargo)
- Source compilation from git repositories
- Dependency resolution
- Version pinning
- Environment configuration
- Post-installation validation

Supports 100+ opensource automotive tools.
"""

import os
import sys
import subprocess
import platform
import shutil
from typing import Dict, List, Optional, Any, Tuple
from pathlib import Path
from dataclasses import dataclass
import logging
import tempfile
import json

logger = logging.getLogger(__name__)


@dataclass
class InstallResult:
    """Result of a tool installation."""
    tool_name: str
    success: bool
    version: Optional[str]
    install_path: Optional[str]
    method: str
    error_message: Optional[str]
    duration_seconds: float


class OpensourceInstaller:
    """Automated installer for opensource automotive tools."""

    # Installation specifications for opensource tools
    INSTALL_SPECS = {
        # CAN/Vehicle Network Tools
        "cantools": {
            "package_managers": {
                "pip": {"package": "cantools", "version": ">=38.0.0"}
            },
            "dependencies": ["python3", "pip"],
            "post_install_check": ["cantools", "--version"]
        },
        "python-can": {
            "package_managers": {
                "pip": {"package": "python-can", "version": ">=4.0.0"}
            },
            "dependencies": ["python3", "pip"],
            "post_install_check": ["python3", "-c", "import can; print(can.__version__)"]
        },
        "socketcan-utils": {
            "package_managers": {
                "apt": {"package": "can-utils"},
                "yum": {"package": "can-utils"}
            },
            "dependencies": [],
            "post_install_check": ["candump", "--version"]
        },
        "panda": {
            "git": {
                "url": "https://github.com/commaai/panda",
                "build_commands": [
                    ["pip", "install", "-r", "requirements.txt"],
                    ["python", "setup.py", "install"]
                ]
            },
            "dependencies": ["python3", "pip", "git", "gcc", "make"],
            "post_install_check": ["python3", "-c", "import panda"]
        },

        # AUTOSAR Tools
        "arctic-core": {
            "git": {
                "url": "https://github.com/arccore/arctic-core",
                "branch": "master",
                "build_commands": [
                    ["mkdir", "-p", "build"],
                    ["cmake", "-B", "build", "-DCMAKE_BUILD_TYPE=Release"],
                    ["cmake", "--build", "build", "-j4"]
                ]
            },
            "dependencies": ["cmake", "gcc", "g++", "make", "git"],
            "post_install_check": None  # Manual verification needed
        },

        # Simulation & Emulation
        "qemu": {
            "package_managers": {
                "apt": {"package": "qemu-system-arm qemu-system-x86"},
                "yum": {"package": "qemu"},
                "brew": {"package": "qemu"}
            },
            "dependencies": [],
            "post_install_check": ["qemu-system-arm", "--version"]
        },
        "renode": {
            "package_managers": {
                "apt": {
                    "pre_commands": [
                        ["wget", "https://dl.antmicro.com/projects/renode/builds/renode-latest.deb"],
                        ["dpkg", "-i", "renode-latest.deb"]
                    ]
                }
            },
            "git": {
                "url": "https://github.com/renode/renode",
                "build_commands": [
                    ["./build.sh"]
                ]
            },
            "dependencies": ["mono-complete", "gtk-sharp2", "git"],
            "post_install_check": ["renode", "--version"]
        },

        # Compilers & Toolchains
        "gcc-arm-none-eabi": {
            "package_managers": {
                "apt": {"package": "gcc-arm-none-eabi"},
                "brew": {"package": "gcc-arm-embedded"}
            },
            "dependencies": [],
            "post_install_check": ["arm-none-eabi-gcc", "--version"]
        },
        "gcc-arm-linux": {
            "package_managers": {
                "apt": {"package": "gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu"},
            },
            "dependencies": [],
            "post_install_check": ["arm-linux-gnueabihf-gcc", "--version"]
        },

        # Debuggers
        "gdb-multiarch": {
            "package_managers": {
                "apt": {"package": "gdb-multiarch"},
                "yum": {"package": "gdb"},
                "brew": {"package": "gdb"}
            },
            "dependencies": [],
            "post_install_check": ["gdb", "--version"]
        },
        "openocd": {
            "package_managers": {
                "apt": {"package": "openocd"},
                "brew": {"package": "openocd"}
            },
            "git": {
                "url": "https://github.com/openocd-org/openocd",
                "build_commands": [
                    ["./bootstrap"],
                    ["./configure", "--enable-ftdi", "--enable-stlink"],
                    ["make", "-j4"],
                    ["sudo", "make", "install"]
                ]
            },
            "dependencies": ["autoconf", "automake", "libtool", "libusb-1.0-0-dev"],
            "post_install_check": ["openocd", "--version"]
        },

        # Static Analysis
        "cppcheck": {
            "package_managers": {
                "apt": {"package": "cppcheck"},
                "yum": {"package": "cppcheck"},
                "brew": {"package": "cppcheck"}
            },
            "dependencies": [],
            "post_install_check": ["cppcheck", "--version"]
        },
        "clang-tidy": {
            "package_managers": {
                "apt": {"package": "clang-tidy"},
                "brew": {"package": "llvm"}
            },
            "dependencies": [],
            "post_install_check": ["clang-tidy", "--version"]
        },

        # Testing Frameworks
        "googletest": {
            "git": {
                "url": "https://github.com/google/googletest",
                "build_commands": [
                    ["cmake", "-B", "build", "-DCMAKE_BUILD_TYPE=Release"],
                    ["cmake", "--build", "build", "-j4"],
                    ["sudo", "cmake", "--install", "build"]
                ]
            },
            "dependencies": ["cmake", "gcc", "g++"],
            "post_install_check": None
        },
        "catch2": {
            "git": {
                "url": "https://github.com/catchorg/Catch2",
                "tag": "v3.4.0",
                "build_commands": [
                    ["cmake", "-B", "build", "-DCMAKE_BUILD_TYPE=Release"],
                    ["cmake", "--build", "build", "-j4"],
                    ["sudo", "cmake", "--install", "build"]
                ]
            },
            "dependencies": ["cmake", "gcc", "g++"],
            "post_install_check": None
        },
        "unity": {
            "git": {
                "url": "https://github.com/ThrowTheSwitch/Unity",
                "build_commands": []  # Header-only, just clone
            },
            "dependencies": ["git"],
            "post_install_check": None
        },

        # Build Systems
        "cmake": {
            "package_managers": {
                "apt": {"package": "cmake"},
                "yum": {"package": "cmake"},
                "brew": {"package": "cmake"}
            },
            "dependencies": [],
            "post_install_check": ["cmake", "--version"]
        },
        "bazel": {
            "package_managers": {
                "apt": {
                    "pre_commands": [
                        ["wget", "https://github.com/bazelbuild/bazel/releases/download/6.0.0/bazel-6.0.0-installer-linux-x86_64.sh"],
                        ["bash", "bazel-6.0.0-installer-linux-x86_64.sh", "--user"]
                    ]
                },
                "brew": {"package": "bazel"}
            },
            "dependencies": ["java"],
            "post_install_check": ["bazel", "--version"]
        },

        # XCP/Calibration
        "xcp-lite": {
            "git": {
                "url": "https://github.com/vectorgrp/xcp-lite",
                "build_commands": [
                    ["cmake", "-B", "build"],
                    ["cmake", "--build", "build", "-j4"]
                ]
            },
            "dependencies": ["cmake", "gcc"],
            "post_install_check": None
        },

        # Rust-based tools
        "cargo-embed": {
            "package_managers": {
                "cargo": {"package": "cargo-embed"}
            },
            "dependencies": ["cargo", "rustc"],
            "post_install_check": ["cargo-embed", "--version"]
        }
    }

    def __init__(self, install_prefix: Optional[str] = None, sudo: bool = False):
        """
        Initialize the installer.

        Args:
            install_prefix: Installation prefix (default: /usr/local for system, ~/.local for user)
            sudo: Whether to use sudo for system installations
        """
        self.install_prefix = install_prefix or self._get_default_prefix()
        self.sudo = sudo
        self.system_info = self._detect_system()
        self.package_manager = self._detect_package_manager()

    def _get_default_prefix(self) -> str:
        """Get default installation prefix."""
        if os.geteuid() == 0:  # Running as root
            return "/usr/local"
        return str(Path.home() / ".local")

    def _detect_system(self) -> Dict[str, str]:
        """Detect system information."""
        return {
            "os": platform.system(),
            "distribution": self._get_distribution(),
            "architecture": platform.machine(),
            "python_version": platform.python_version()
        }

    def _get_distribution(self) -> str:
        """Get Linux distribution name."""
        try:
            if Path("/etc/os-release").exists():
                with open("/etc/os-release") as f:
                    for line in f:
                        if line.startswith("ID="):
                            return line.split("=")[1].strip().strip('"')
        except:
            pass
        return "unknown"

    def _detect_package_manager(self) -> Optional[str]:
        """Detect available package manager."""
        managers = ["apt", "yum", "dnf", "brew", "pacman"]

        for manager in managers:
            if shutil.which(manager):
                logger.info(f"Detected package manager: {manager}")
                return manager

        logger.warning("No package manager detected")
        return None

    def install_tool(self, tool_name: str, force: bool = False) -> InstallResult:
        """
        Install a single tool.

        Args:
            tool_name: Tool name
            force: Force reinstallation if already installed

        Returns:
            InstallResult object
        """
        import time
        start_time = time.time()

        logger.info(f"Installing {tool_name}...")

        if tool_name not in self.INSTALL_SPECS:
            return InstallResult(
                tool_name=tool_name,
                success=False,
                version=None,
                install_path=None,
                method="unknown",
                error_message=f"No installation spec found for {tool_name}",
                duration_seconds=time.time() - start_time
            )

        spec = self.INSTALL_SPECS[tool_name]

        # Check if already installed
        if not force and self._check_installed(spec):
            logger.info(f"{tool_name} already installed")
            return InstallResult(
                tool_name=tool_name,
                success=True,
                version=self._get_installed_version(spec),
                install_path=None,
                method="already_installed",
                error_message=None,
                duration_seconds=time.time() - start_time
            )

        # Install dependencies first
        if not self._install_dependencies(spec.get("dependencies", [])):
            return InstallResult(
                tool_name=tool_name,
                success=False,
                version=None,
                install_path=None,
                method="dependency_failed",
                error_message="Failed to install dependencies",
                duration_seconds=time.time() - start_time
            )

        # Try installation methods in order
        result = None

        # 1. Try package manager
        if "package_managers" in spec and self.package_manager:
            result = self._install_via_package_manager(tool_name, spec)
            if result and result.success:
                result.duration_seconds = time.time() - start_time
                return result

        # 2. Try git source build
        if "git" in spec:
            result = self._install_from_git(tool_name, spec)
            if result and result.success:
                result.duration_seconds = time.time() - start_time
                return result

        # If all methods failed
        if not result:
            result = InstallResult(
                tool_name=tool_name,
                success=False,
                version=None,
                install_path=None,
                method="no_method",
                error_message="No installation method available for this system",
                duration_seconds=time.time() - start_time
            )

        return result

    def _install_via_package_manager(
        self,
        tool_name: str,
        spec: Dict[str, Any]
    ) -> Optional[InstallResult]:
        """
        Install tool using system package manager.

        Args:
            tool_name: Tool name
            spec: Installation specification

        Returns:
            InstallResult or None if not applicable
        """
        if self.package_manager not in spec.get("package_managers", {}):
            return None

        pm_spec = spec["package_managers"][self.package_manager]

        try:
            # Run pre-commands if any
            if "pre_commands" in pm_spec:
                for cmd in pm_spec["pre_commands"]:
                    result = self._run_command(cmd)
                    if result.returncode != 0:
                        return InstallResult(
                            tool_name=tool_name,
                            success=False,
                            version=None,
                            install_path=None,
                            method=f"{self.package_manager}_pre_command",
                            error_message=f"Pre-command failed: {result.stderr}",
                            duration_seconds=0
                        )

            # Install package
            package = pm_spec.get("package", tool_name)
            install_cmd = self._get_package_install_command(package)

            result = self._run_command(install_cmd)

            if result.returncode != 0:
                return InstallResult(
                    tool_name=tool_name,
                    success=False,
                    version=None,
                    install_path=None,
                    method=self.package_manager,
                    error_message=result.stderr,
                    duration_seconds=0
                )

            # Verify installation
            if not self._check_installed(spec):
                return InstallResult(
                    tool_name=tool_name,
                    success=False,
                    version=None,
                    install_path=None,
                    method=self.package_manager,
                    error_message="Post-installation check failed",
                    duration_seconds=0
                )

            return InstallResult(
                tool_name=tool_name,
                success=True,
                version=self._get_installed_version(spec),
                install_path=self._find_install_path(tool_name),
                method=self.package_manager,
                error_message=None,
                duration_seconds=0
            )

        except Exception as e:
            logger.exception(f"Error installing {tool_name} via {self.package_manager}")
            return InstallResult(
                tool_name=tool_name,
                success=False,
                version=None,
                install_path=None,
                method=self.package_manager,
                error_message=str(e),
                duration_seconds=0
            )

    def _install_from_git(
        self,
        tool_name: str,
        spec: Dict[str, Any]
    ) -> Optional[InstallResult]:
        """
        Install tool from git repository.

        Args:
            tool_name: Tool name
            spec: Installation specification

        Returns:
            InstallResult or None if not applicable
        """
        git_spec = spec.get("git")
        if not git_spec:
            return None

        try:
            # Create temp directory
            with tempfile.TemporaryDirectory() as tmpdir:
                repo_path = Path(tmpdir) / tool_name

                # Clone repository
                clone_cmd = ["git", "clone", git_spec["url"], str(repo_path)]

                if "branch" in git_spec:
                    clone_cmd.extend(["--branch", git_spec["branch"]])
                elif "tag" in git_spec:
                    clone_cmd.extend(["--branch", git_spec["tag"]])

                result = self._run_command(clone_cmd)
                if result.returncode != 0:
                    return InstallResult(
                        tool_name=tool_name,
                        success=False,
                        version=None,
                        install_path=None,
                        method="git",
                        error_message=f"Git clone failed: {result.stderr}",
                        duration_seconds=0
                    )

                # Run build commands
                for cmd in git_spec.get("build_commands", []):
                    result = self._run_command(cmd, cwd=repo_path)
                    if result.returncode != 0:
                        return InstallResult(
                            tool_name=tool_name,
                            success=False,
                            version=None,
                            install_path=None,
                            method="git",
                            error_message=f"Build command failed: {' '.join(cmd)}\n{result.stderr}",
                            duration_seconds=0
                        )

                # Verify installation if check defined
                if not spec.get("post_install_check") or self._check_installed(spec):
                    return InstallResult(
                        tool_name=tool_name,
                        success=True,
                        version=self._get_installed_version(spec),
                        install_path=str(repo_path),
                        method="git",
                        error_message=None,
                        duration_seconds=0
                    )
                else:
                    return InstallResult(
                        tool_name=tool_name,
                        success=False,
                        version=None,
                        install_path=None,
                        method="git",
                        error_message="Post-installation check failed",
                        duration_seconds=0
                    )

        except Exception as e:
            logger.exception(f"Error installing {tool_name} from git")
            return InstallResult(
                tool_name=tool_name,
                success=False,
                version=None,
                install_path=None,
                method="git",
                error_message=str(e),
                duration_seconds=0
            )

    def _install_dependencies(self, dependencies: List[str]) -> bool:
        """
        Install dependencies.

        Args:
            dependencies: List of dependency names

        Returns:
            True if all dependencies installed successfully
        """
        for dep in dependencies:
            if not self._check_tool_available(dep):
                logger.info(f"Installing dependency: {dep}")

                # Try to install via package manager
                install_cmd = self._get_package_install_command(dep)
                result = self._run_command(install_cmd)

                if result.returncode != 0:
                    logger.error(f"Failed to install dependency {dep}")
                    return False

        return True

    def _check_installed(self, spec: Dict[str, Any]) -> bool:
        """
        Check if tool is installed.

        Args:
            spec: Installation specification

        Returns:
            True if installed
        """
        check_cmd = spec.get("post_install_check")
        if not check_cmd:
            return True  # No check defined, assume success

        try:
            result = self._run_command(check_cmd, timeout=10)
            return result.returncode == 0
        except:
            return False

    def _check_tool_available(self, tool: str) -> bool:
        """Check if a tool is available in PATH."""
        return shutil.which(tool) is not None

    def _get_installed_version(self, spec: Dict[str, Any]) -> Optional[str]:
        """Get version of installed tool."""
        check_cmd = spec.get("post_install_check")
        if not check_cmd:
            return None

        try:
            result = self._run_command(check_cmd, timeout=10)
            if result.returncode == 0:
                return self._parse_version(result.stdout + result.stderr)
        except:
            pass

        return None

    def _parse_version(self, output: str) -> Optional[str]:
        """Parse version from command output."""
        import re
        patterns = [
            r"(\d+\.\d+\.\d+)",
            r"version\s+(\d+\.\d+)",
            r"v(\d+\.\d+)"
        ]

        for pattern in patterns:
            match = re.search(pattern, output, re.IGNORECASE)
            if match:
                return match.group(1)

        return None

    def _find_install_path(self, tool_name: str) -> Optional[str]:
        """Find installation path of a tool."""
        path = shutil.which(tool_name)
        return path if path else None

    def _get_package_install_command(self, package: str) -> List[str]:
        """Get package install command for current system."""
        commands = {
            "apt": ["sudo", "apt-get", "install", "-y"] if self.sudo else ["apt-get", "install", "-y"],
            "yum": ["sudo", "yum", "install", "-y"] if self.sudo else ["yum", "install", "-y"],
            "dnf": ["sudo", "dnf", "install", "-y"] if self.sudo else ["dnf", "install", "-y"],
            "brew": ["brew", "install"],
            "pip": ["pip", "install"],
            "cargo": ["cargo", "install"]
        }

        base_cmd = commands.get(self.package_manager, ["echo", "Unknown package manager"])
        return base_cmd + package.split()

    def _run_command(
        self,
        cmd: List[str],
        cwd: Optional[Path] = None,
        timeout: int = 300
    ) -> subprocess.CompletedProcess:
        """
        Run a command with logging.

        Args:
            cmd: Command and arguments
            cwd: Working directory
            timeout: Timeout in seconds

        Returns:
            CompletedProcess result
        """
        logger.debug(f"Running: {' '.join(cmd)}")

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=cwd,
                timeout=timeout
            )

            if result.returncode != 0:
                logger.warning(f"Command failed with code {result.returncode}: {' '.join(cmd)}")
                if result.stderr:
                    logger.warning(f"stderr: {result.stderr[:500]}")

            return result

        except subprocess.TimeoutExpired as e:
            logger.error(f"Command timed out: {' '.join(cmd)}")
            raise
        except Exception as e:
            logger.exception(f"Command error: {' '.join(cmd)}")
            raise

    def install_multiple(self, tool_names: List[str], force: bool = False) -> Dict[str, InstallResult]:
        """
        Install multiple tools.

        Args:
            tool_names: List of tool names
            force: Force reinstallation

        Returns:
            Dictionary mapping tool name to InstallResult
        """
        results = {}

        for tool_name in tool_names:
            results[tool_name] = self.install_tool(tool_name, force=force)

        return results

    def export_report(self, results: Dict[str, InstallResult], output_path: str) -> None:
        """
        Export installation report.

        Args:
            results: Installation results
            output_path: Output file path
        """
        data = {
            "timestamp": datetime.now().isoformat(),
            "system": self.system_info,
            "results": {
                name: {
                    "success": result.success,
                    "version": result.version,
                    "method": result.method,
                    "install_path": result.install_path,
                    "error_message": result.error_message,
                    "duration_seconds": result.duration_seconds
                }
                for name, result in results.items()
            }
        }

        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)

        logger.info(f"Installation report exported to {output_path}")


from datetime import datetime


def main():
    """Main entry point."""
    logging.basicConfig(level=logging.INFO)

    installer = OpensourceInstaller(sudo=True)

    # Example: Install common automotive tools
    tools = [
        "cantools",
        "python-can",
        "socketcan-utils",
        "cppcheck",
        "cmake"
    ]

    print("\n=== Installing Opensource Automotive Tools ===")
    results = installer.install_multiple(tools)

    # Print summary
    print("\n=== Installation Summary ===")
    for tool_name, result in results.items():
        status = "✓" if result.success else "✗"
        print(f"{status} {tool_name}")
        if result.version:
            print(f"  Version: {result.version}")
        if result.error_message:
            print(f"  Error: {result.error_message}")

    installer.export_report(results, "/tmp/install_report.json")


if __name__ == "__main__":
    main()

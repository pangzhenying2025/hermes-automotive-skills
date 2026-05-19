"""
QNX Software Development Platform (SDP) Adapter

Manages QNX SDP operations including package management, BSP installation,
boot image creation, and target filesystem management.

Supports QNX 7.0, 7.1, and 8.0
"""

import os
import subprocess
import json
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Any, Set
from dataclasses import dataclass
from enum import Enum

from ..base_adapter import OpensourceToolAdapter


class QnxVersion(Enum):
    """Supported QNX SDP versions"""
    QNX_700 = "7.0.0"
    QNX_710 = "7.1.0"
    QNX_800 = "8.0.0"


class FilesystemType(Enum):
    """QNX filesystem types"""
    QNX6 = "qnx6"
    QNX6_POWER_SAFE = "qnx6_power_safe"
    EXT2 = "ext2"
    DOS = "dos"


@dataclass
class BspConfig:
    """Board Support Package configuration"""
    name: str
    architecture: str
    board: str
    version: str
    install_path: str


@dataclass
class IfsConfig:
    """Image Filesystem (boot image) configuration"""
    output_file: str
    boot_script: str
    programs: List[str]
    libraries: List[str]
    drivers: List[str]
    size_limit: Optional[int] = None


class QnxSdpAdapter(OpensourceToolAdapter):
    """
    QNX Software Development Platform utilities adapter.

    Provides tools for:
    - Package management (qnxpackage, qnxinstall)
    - BSP installation and configuration
    - Boot image creation (mkifs)
    - Target filesystem creation
    - QNX system utilities

    Example:
        sdp = QnxSdpAdapter(qnx_version=QnxVersion.QNX_710)

        # Create boot image
        sdp.create_boot_image(
            output_file="ifs-my-system.bin",
            boot_script="my-build.build",
            programs=["devc-ser8250", "io-pkt-v6-hc"],
            drivers=["devb-sdmmc-am65x"]
        )

        # Deploy to target
        sdp.deploy_to_target(
            binary="my_app",
            target_ip="192.168.1.100",
            target_path="/usr/local/bin/"
        )
    """

    def __init__(
        self,
        qnx_version: QnxVersion = QnxVersion.QNX_710,
        qnx_host: Optional[str] = None,
        qnx_target: Optional[str] = None,
        bsp_root: Optional[str] = None
    ):
        """
        Initialize QNX SDP adapter.

        Args:
            qnx_version: QNX SDP version
            qnx_host: QNX_HOST path (auto-detected if not provided)
            qnx_target: QNX_TARGET path (auto-detected if not provided)
            bsp_root: BSP installation root directory
        """
        super().__init__(name="qnx-sdp", version=qnx_version.value)

        self.qnx_version = qnx_version
        self.qnx_host = Path(qnx_host or os.getenv('QNX_HOST', f'/opt/qnx{qnx_version.value[:3].replace(".", "")}/host/linux/x86_64'))
        self.qnx_target = Path(qnx_target or os.getenv('QNX_TARGET', f'/opt/qnx{qnx_version.value[:3].replace(".", "")}/target/qnx7'))
        self.bsp_root = Path(bsp_root or self.qnx_target.parent / "bsp")

        # Verify QNX environment
        if not self.qnx_host.exists():
            raise ValueError(f"QNX_HOST not found: {self.qnx_host}")
        if not self.qnx_target.exists():
            raise ValueError(f"QNX_TARGET not found: {self.qnx_target}")

        # Tool paths
        self.mkifs = self.qnx_host / "usr/bin/mkifs"
        self.mkxfs = self.qnx_host / "usr/bin/mkxfs"
        self.qnxpackage = self.qnx_host / "usr/bin/qnxpackage"
        self.qconn = self.qnx_host / "usr/bin/qconn"

    def _success(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Return success result"""
        return {"success": True, "data": data}

    def _error(self, message: str, details: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Return error result"""
        result = {"success": False, "error": message}
        if details:
            result["details"] = details
        return result

    def _detect(self) -> bool:
        """Detect if QNX SDP is installed"""
        return self.mkifs.exists() if hasattr(self, 'mkifs') else False

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute QNX SDP command"""
        if command == "create_boot_image":
            return self.create_boot_image(**parameters)
        elif command == "deploy_to_target":
            return self.deploy_to_target(**parameters)
        else:
            return {"success": False, "error": f"Unknown command: {command}"}

    def create_boot_image(
        self,
        output_file: str,
        boot_script: Optional[str] = None,
        programs: Optional[List[str]] = None,
        libraries: Optional[List[str]] = None,
        drivers: Optional[List[str]] = None,
        search_paths: Optional[List[str]] = None,
        size_limit: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Create QNX Image Filesystem (IFS) boot image using mkifs.

        Args:
            output_file: Output IFS binary filename
            boot_script: Build file path (.build file)
            programs: List of programs to include
            libraries: List of shared libraries to include
            drivers: List of drivers to include
            search_paths: Additional search paths for binaries
            size_limit: Maximum image size in bytes

        Returns:
            Boot image creation result with file info
        """
        if not boot_script:
            # Generate default build script
            boot_script = self._generate_build_script(
                programs or [],
                libraries or [],
                drivers or []
            )

        build_file = Path(boot_script)
        if not build_file.exists():
            return self._error(f"Build script not found: {boot_script}")

        # Prepare mkifs command
        mkifs_cmd = [str(self.mkifs)]

        # Add search paths
        paths = search_paths or []
        paths.extend([
            str(self.qnx_target / "aarch64le/boot/sys"),
            str(self.qnx_target / "aarch64le/lib"),
            str(self.qnx_target / "aarch64le/usr/lib"),
            str(self.qnx_target / "aarch64le/sbin"),
            str(self.qnx_target / "aarch64le/usr/sbin"),
            str(self.qnx_target / "aarch64le/bin"),
            str(self.qnx_target / "aarch64le/usr/bin")
        ])

        for path in paths:
            mkifs_cmd.extend(["-r", path])

        # Add size limit if specified
        if size_limit:
            mkifs_cmd.extend(["-s", str(size_limit)])

        # Add build file and output
        mkifs_cmd.extend([str(build_file), str(output_file)])

        # Execute mkifs
        result = subprocess.run(
            mkifs_cmd,
            capture_output=True,
            text=True,
            env={**os.environ, "QNX_TARGET": str(self.qnx_target)}
        )

        if result.returncode != 0:
            return self._error(
                f"mkifs failed: {result.stderr}",
                details={"stdout": result.stdout, "stderr": result.stderr}
            )

        output_path = Path(output_file)
        if not output_path.exists():
            return self._error("Boot image file not created")

        return self._success({
            "boot_image": str(output_path.absolute()),
            "size_bytes": output_path.stat().st_size,
            "build_script": str(build_file),
            "mkifs_output": result.stdout
        })

    def _generate_build_script(
        self,
        programs: List[str],
        libraries: List[str],
        drivers: List[str]
    ) -> str:
        """Generate default IFS build script"""
        build_content = """[virtual=aarch64le,binary] boot = {
    startup-generic -v

    PATH=/proc/boot:/sbin:/usr/sbin:/bin:/usr/bin LD_LIBRARY_PATH=/proc/boot:/lib:/usr/lib:/lib/dll procnto-smp-instr -v
}

[+script] startup-script = {
    # System startup commands
    display_msg "Starting QNX Neutrino..."

    # Start drivers
"""

        # Add drivers
        for driver in drivers:
            build_content += f"    {driver} &\n"

        build_content += "\n    # Start services\n"

        # Add programs
        for program in programs:
            build_content += f"    {program} &\n"

        build_content += """
    # System ready
    display_msg "System initialization complete"
}

[type=link] /tmp=/dev/shmem
[type=link] /dev/console=/dev/ser1

# Include libraries
"""

        # Add libraries
        for lib in libraries:
            build_content += f"[type=link] /lib/{lib}=/proc/boot/{lib}\n"

        build_content += "\n# Include binaries\n"

        # Add programs
        for program in programs:
            build_content += f"[type=link] /sbin/{program}=/proc/boot/{program}\n"

        # Write to temporary file
        build_file = Path("/tmp/qnx_build_script.build")
        build_file.write_text(build_content)

        return str(build_file)

    def create_filesystem(
        self,
        output_file: str,
        fs_type: FilesystemType = FilesystemType.QNX6,
        size_mb: int = 512,
        source_dir: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create QNX filesystem image using mkxfs.

        Args:
            output_file: Output filesystem image filename
            fs_type: Filesystem type
            size_mb: Filesystem size in megabytes
            source_dir: Source directory to populate filesystem

        Returns:
            Filesystem creation result
        """
        mkxfs_cmd = [
            str(self.mkxfs),
            "-t", fs_type.value,
            "-s", f"{size_mb}M",
            "-o", output_file
        ]

        if source_dir:
            mkxfs_cmd.extend(["-d", source_dir])

        result = subprocess.run(
            mkxfs_cmd,
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            return self._error(
                f"mkxfs failed: {result.stderr}",
                details={"stdout": result.stdout, "stderr": result.stderr}
            )

        return self._success({
            "filesystem_image": output_file,
            "type": fs_type.value,
            "size_mb": size_mb,
            "source_dir": source_dir
        })

    def install_package(
        self,
        package_path: str,
        install_location: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Install QNX package using qnxpackage tool.

        Args:
            package_path: Path to .qpk package file
            install_location: Installation directory (defaults to QNX_TARGET)

        Returns:
            Package installation result
        """
        if not Path(package_path).exists():
            return self._error(f"Package not found: {package_path}")

        install_dir = install_location or str(self.qnx_target)

        qnxpackage_cmd = [
            str(self.qnxpackage),
            "install",
            "--location", install_dir,
            package_path
        ]

        result = subprocess.run(
            qnxpackage_cmd,
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            return self._error(
                f"Package installation failed: {result.stderr}",
                details={"stdout": result.stdout, "stderr": result.stderr}
            )

        return self._success({
            "package": package_path,
            "install_location": install_dir,
            "output": result.stdout
        })

    def install_bsp(
        self,
        bsp_path: str,
        board_name: str,
        architecture: str = "aarch64le"
    ) -> Dict[str, Any]:
        """
        Install Board Support Package.

        Args:
            bsp_path: Path to BSP archive or directory
            board_name: Target board name
            architecture: Target architecture

        Returns:
            BSP installation result
        """
        bsp_source = Path(bsp_path)
        if not bsp_source.exists():
            return self._error(f"BSP not found: {bsp_path}")

        bsp_install_dir = self.bsp_root / board_name / architecture
        bsp_install_dir.mkdir(parents=True, exist_ok=True)

        # Extract or copy BSP
        if bsp_source.is_file():
            # Assume archive, extract it
            shutil.unpack_archive(bsp_source, bsp_install_dir)
        else:
            # Copy directory
            shutil.copytree(bsp_source, bsp_install_dir, dirs_exist_ok=True)

        return self._success({
            "bsp_name": board_name,
            "architecture": architecture,
            "install_path": str(bsp_install_dir),
            "installed": True
        })

    def deploy_to_target(
        self,
        binary: str,
        target_ip: str,
        target_path: str = "/tmp/",
        target_port: int = 8000,
        username: str = "root",
        password: str = ""
    ) -> Dict[str, Any]:
        """
        Deploy binary to QNX target via qconn.

        Args:
            binary: Local binary path
            target_ip: Target IP address
            target_path: Destination path on target
            target_port: qconn port (default 8000)
            username: Target username
            password: Target password

        Returns:
            Deployment result
        """
        binary_path = Path(binary)
        if not binary_path.exists():
            return self._error(f"Binary not found: {binary}")

        # Use scp for file transfer (qconn-based transfer)
        scp_cmd = [
            "scp",
            "-P", str(target_port),
            str(binary_path),
            f"{username}@{target_ip}:{target_path}"
        ]

        result = subprocess.run(
            scp_cmd,
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            return self._error(
                f"Deployment failed: {result.stderr}",
                details={"stdout": result.stdout, "stderr": result.stderr}
            )

        return self._success({
            "binary": str(binary_path),
            "target": f"{target_ip}:{target_port}",
            "destination": target_path,
            "deployed": True
        })

    def query_system_info(
        self,
        target_ip: str,
        target_port: int = 8000
    ) -> Dict[str, Any]:
        """
        Query QNX target system information.

        Args:
            target_ip: Target IP address
            target_port: qconn port

        Returns:
            System information from target
        """
        # Use pidin command remotely via ssh
        ssh_cmd = [
            "ssh",
            "-p", str(target_port),
            f"root@{target_ip}",
            "pidin info"
        ]

        result = subprocess.run(
            ssh_cmd,
            capture_output=True,
            text=True,
            timeout=10
        )

        if result.returncode != 0:
            return self._error(f"Failed to query system: {result.stderr}")

        # Parse pidin output
        system_info = {
            "raw_output": result.stdout,
            "target": f"{target_ip}:{target_port}"
        }

        return self._success(system_info)

    def list_installed_packages(self) -> Dict[str, Any]:
        """
        List installed QNX packages.

        Returns:
            List of installed packages
        """
        qnxpackage_cmd = [
            str(self.qnxpackage),
            "list",
            "--location", str(self.qnx_target)
        ]

        result = subprocess.run(
            qnxpackage_cmd,
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            return self._error(f"Failed to list packages: {result.stderr}")

        packages = []
        for line in result.stdout.splitlines():
            if line.strip():
                packages.append(line.strip())

        return self._success({
            "packages": packages,
            "count": len(packages)
        })

    def build_automotive_image(
        self,
        output_file: str,
        include_can: bool = True,
        include_lin: bool = False,
        include_ethernet: bool = True,
        custom_drivers: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Build automotive-specific QNX boot image with standard drivers.

        Args:
            output_file: Output IFS filename
            include_can: Include CAN drivers
            include_lin: Include LIN drivers
            include_ethernet: Include Ethernet drivers
            custom_drivers: Additional custom drivers

        Returns:
            Automotive image creation result
        """
        programs = [
            "devc-ser8250",  # Serial driver
            "io-pkt-v6-hc",  # Network stack
            "dhclient",      # DHCP client
            "random",        # Random number generator
            "pipe"           # Pipe manager
        ]

        drivers = []

        if include_can:
            drivers.extend([
                "dev-can-mcp2515",  # Example CAN driver
            ])

        if include_lin:
            drivers.extend([
                "dev-lin-generic"  # Example LIN driver
            ])

        if include_ethernet:
            drivers.extend([
                "devnp-e1000",     # Intel Ethernet
                "devnp-tigon3"     # Broadcom Ethernet
            ])

        if custom_drivers:
            drivers.extend(custom_drivers)

        libraries = [
            "libc.so",
            "libm.so",
            "libsocket.so"
        ]

        return self.create_boot_image(
            output_file=output_file,
            programs=programs,
            libraries=libraries,
            drivers=drivers
        )

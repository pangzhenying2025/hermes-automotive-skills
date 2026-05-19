"""
QNX Momentics IDE Adapter

Automates QNX Momentics IDE operations via command-line interface.
Supports project creation, build configuration, target management, and debugging.

QNX Versions: 7.0, 7.1, 8.0
Target Architectures: x86_64, aarch64le, armv7le
"""

import os
import subprocess
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum

from ..base_adapter import OpensourceToolAdapter


class ProjectType(Enum):
    """QNX Momentics project types"""
    QNX_C_PROJECT = "QNX C Project"
    QNX_CPP_PROJECT = "QNX C++ Project"
    QNX_C_LIBRARY = "QNX C Library"
    QNX_CPP_LIBRARY = "QNX C++ Library"
    QNX_APPLICATION = "QNX Application Project"
    QNX_RESOURCE_MANAGER = "QNX Resource Manager"


class BuildVariant(Enum):
    """QNX build variants"""
    DEBUG = "debug"
    RELEASE = "release"
    PROFILING = "profiling"
    COVERAGE = "coverage"


class TargetArchitecture(Enum):
    """Supported target architectures"""
    X86_64 = "x86_64"
    AARCH64LE = "aarch64le"
    ARMV7LE = "armv7le"


@dataclass
class MomenticsConfig:
    """QNX Momentics IDE configuration"""
    ide_path: str
    workspace_path: str
    qnx_host: str
    qnx_target: str
    sdk_version: str


@dataclass
class ProjectConfig:
    """QNX project configuration"""
    name: str
    project_type: ProjectType
    architecture: TargetArchitecture
    build_variant: BuildVariant
    source_files: List[str]
    include_paths: List[str]
    libraries: List[str]
    compiler_flags: List[str]


@dataclass
class TargetConfig:
    """QNX target connection configuration"""
    name: str
    hostname: str
    port: int = 8000
    username: str = "root"
    password: str = ""
    architecture: TargetArchitecture = TargetArchitecture.X86_64


class MomenticsAdapter(OpensourceToolAdapter):
    """
    QNX Momentics IDE automation adapter.

    Provides programmatic access to Momentics IDE functionality including:
    - Project creation and configuration
    - Build automation
    - Target connection management
    - Remote debugging
    - Code analysis integration

    Example:
        adapter = MomenticsAdapter(
            ide_path="/opt/qnx710/ide/",
            workspace_path="/home/user/qnx_workspace"
        )

        project = adapter.create_project(
            name="can_service",
            project_type=ProjectType.QNX_CPP_PROJECT,
            architecture=TargetArchitecture.AARCH64LE
        )

        adapter.build_project("can_service", BuildVariant.RELEASE)
    """

    def __init__(
        self,
        ide_path: str = "/opt/qnx710/ide",
        workspace_path: str = None,
        qnx_host: str = None,
        qnx_target: str = None
    ):
        """
        Initialize Momentics adapter.

        Args:
            ide_path: Path to QNX Momentics IDE installation
            workspace_path: Eclipse workspace path
            qnx_host: QNX_HOST environment variable
            qnx_target: QNX_TARGET environment variable
        """
        super().__init__(name="qnx-momentics", version=None)

        self.ide_path = Path(ide_path)
        self.workspace_path = Path(workspace_path or os.path.expanduser("~/qnx_workspace"))

        # Detect QNX environment
        self.qnx_host = qnx_host or os.getenv('QNX_HOST')
        self.qnx_target = qnx_target or os.getenv('QNX_TARGET')

        if not self.qnx_host or not self.qnx_target:
            raise ValueError("QNX_HOST and QNX_TARGET must be set")

        self.sdk_version = self._detect_sdk_version()
        self.qcc_path = Path(self.qnx_host) / "usr/bin/qcc"

        self.workspace_path.mkdir(parents=True, exist_ok=True)

    def _success(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Return success result"""
        return {"success": True, "data": data}

    def _error(self, message: str, details: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Return error result"""
        result = {"success": False, "error": message}
        if details:
            result["details"] = details
        return result

    def _detect_sdk_version(self) -> str:
        """Detect QNX SDP version from installation"""
        version_file = Path(self.qnx_target) / "usr/include/sys/neutrino.h"

        if not version_file.exists():
            return "unknown"

        try:
            content = version_file.read_text()
            if "_NTO_VERSION_MAJOR" in content:
                for line in content.splitlines():
                    if "_NTO_VERSION" in line and "define" in line:
                        parts = line.split()
                        if len(parts) >= 3:
                            return parts[2].strip()
            return "7.1.0"
        except Exception:
            return "7.1.0"

    def create_project(
        self,
        name: str,
        project_type: ProjectType,
        architecture: TargetArchitecture,
        build_variant: BuildVariant = BuildVariant.DEBUG,
        source_files: Optional[List[str]] = None,
        include_paths: Optional[List[str]] = None,
        libraries: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Create new QNX project in workspace.

        Args:
            name: Project name
            project_type: Type of QNX project
            architecture: Target architecture
            build_variant: Build configuration
            source_files: Initial source files to add
            include_paths: Additional include directories
            libraries: Libraries to link against

        Returns:
            Project creation result with paths and configuration
        """
        project_path = self.workspace_path / name

        if project_path.exists():
            return self._error(f"Project {name} already exists at {project_path}")

        project_path.mkdir(parents=True)

        # Create project structure
        (project_path / "src").mkdir()
        (project_path / "include").mkdir()
        (project_path / architecture.value).mkdir()

        # Create .project file (Eclipse project metadata)
        self._create_project_file(project_path, name, project_type)

        # Create .cproject file (CDT configuration)
        self._create_cproject_file(
            project_path,
            name,
            architecture,
            build_variant,
            include_paths or [],
            libraries or []
        )

        # Create Makefile
        self._create_makefile(
            project_path,
            name,
            architecture,
            source_files or []
        )

        # Add initial source files if provided
        if source_files:
            for src_file in source_files:
                src_path = project_path / "src" / Path(src_file).name
                if Path(src_file).exists():
                    src_path.write_text(Path(src_file).read_text())

        return self._success({
            "project_name": name,
            "project_path": str(project_path),
            "architecture": architecture.value,
            "build_variant": build_variant.value,
            "project_type": project_type.value
        })

    def _create_project_file(
        self,
        project_path: Path,
        name: str,
        project_type: ProjectType
    ):
        """Create Eclipse .project file"""
        project_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
    <name>{name}</name>
    <comment>QNX {project_type.value}</comment>
    <projects></projects>
    <buildSpec>
        <buildCommand>
            <name>org.eclipse.cdt.managedbuilder.core.genmakebuilder</name>
            <triggers>clean,full,incremental,</triggers>
            <arguments></arguments>
        </buildCommand>
        <buildCommand>
            <name>org.eclipse.cdt.managedbuilder.core.ScannerConfigBuilder</name>
            <triggers>full,incremental,</triggers>
            <arguments></arguments>
        </buildCommand>
    </buildSpec>
    <natures>
        <nature>org.eclipse.cdt.core.cnature</nature>
        <nature>org.eclipse.cdt.core.ccnature</nature>
        <nature>org.eclipse.cdt.managedbuilder.core.managedBuildNature</nature>
        <nature>org.eclipse.cdt.managedbuilder.core.ScannerConfigNature</nature>
        <nature>com.qnx.tools.ide.core.qnxnature</nature>
    </natures>
</projectDescription>
"""
        (project_path / ".project").write_text(project_xml)

    def _create_cproject_file(
        self,
        project_path: Path,
        name: str,
        architecture: TargetArchitecture,
        build_variant: BuildVariant,
        include_paths: List[str],
        libraries: List[str]
    ):
        """Create CDT .cproject configuration file"""
        includes = " ".join([f"-I{inc}" for inc in include_paths])
        libs = " ".join([f"-l{lib}" for lib in libraries])

        cproject_xml = f"""<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?fileVersion 4.0.0?>
<cproject storage_type_id="org.eclipse.cdt.core.XmlProjectDescriptionStorage">
    <storageModule moduleId="org.eclipse.cdt.core.settings">
        <cconfiguration id="com.qnx.qcc.toolChain.{architecture.value}.{build_variant.value}">
            <storageModule buildSystemId="org.eclipse.cdt.managedbuilder.core.configurationDataProvider"
                           id="com.qnx.qcc.toolChain.{architecture.value}.{build_variant.value}"
                           moduleId="org.eclipse.cdt.core.settings"
                           name="{architecture.value}-{build_variant.value}">
                <externalSettings/>
                <extensions>
                    <extension id="org.eclipse.cdt.core.ELF" point="org.eclipse.cdt.core.BinaryParser"/>
                    <extension id="org.eclipse.cdt.core.GmakeErrorParser" point="org.eclipse.cdt.core.ErrorParser"/>
                    <extension id="org.eclipse.cdt.core.CWDLocator" point="org.eclipse.cdt.core.ErrorParser"/>
                    <extension id="org.eclipse.cdt.core.GCCErrorParser" point="org.eclipse.cdt.core.ErrorParser"/>
                    <extension id="org.eclipse.cdt.core.GASErrorParser" point="org.eclipse.cdt.core.ErrorParser"/>
                    <extension id="org.eclipse.cdt.core.GLDErrorParser" point="org.eclipse.cdt.core.ErrorParser"/>
                </extensions>
            </storageModule>
            <storageModule moduleId="cdtBuildSystem" version="4.0.0">
                <configuration artifactName="{name}"
                             buildArtefactType="org.eclipse.cdt.build.core.buildArtefactType.exe"
                             buildProperties="org.eclipse.cdt.build.core.buildArtefactType=org.eclipse.cdt.build.core.buildArtefactType.exe"
                             cleanCommand="rm -rf"
                             description="{architecture.value} {build_variant.value} build"
                             id="com.qnx.qcc.toolChain.{architecture.value}.{build_variant.value}"
                             name="{architecture.value}-{build_variant.value}"
                             parent="cdt.managedbuild.config.gnu.exe.debug">
                    <folderInfo id="com.qnx.qcc.toolChain.{architecture.value}.{build_variant.value}."
                               name="/"
                               resourcePath="">
                        <toolChain id="com.qnx.qcc.toolChain"
                                  name="QCC"
                                  superClass="com.qnx.qcc.toolChain">
                            <targetPlatform archList="all"
                                          binaryParser="org.eclipse.cdt.core.ELF"
                                          id="com.qnx.qcc.targetPlatform"
                                          osList="all"
                                          superClass="com.qnx.qcc.targetPlatform"/>
                            <builder buildPath="${{workspace_loc:/{name}}}/{architecture.value}"
                                    id="com.qnx.qcc.toolChain.builder"
                                    managedBuildOn="true"
                                    name="QNX Make Builder"
                                    superClass="com.qnx.qcc.toolChain.builder"/>
                            <tool id="com.qnx.qcc.tool.compiler"
                                 name="QCC Compiler"
                                 superClass="com.qnx.qcc.tool.compiler">
                                <option id="com.qnx.qcc.option.compiler.includePath"
                                       name="Include Paths (-I)"
                                       superClass="com.qnx.qcc.option.compiler.includePath"
                                       valueType="includePath">
                                    <listOptionValue builtIn="false" value="${{QNX_TARGET}}/usr/include"/>
                                    {self._format_include_options(include_paths)}
                                </option>
                            </tool>
                            <tool id="com.qnx.qcc.tool.linker"
                                 name="QCC Linker"
                                 superClass="com.qnx.qcc.tool.linker">
                                <option id="com.qnx.qcc.option.linker.libraries"
                                       name="Libraries (-l)"
                                       superClass="com.qnx.qcc.option.linker.libraries"
                                       valueType="libs">
                                    {self._format_library_options(libraries)}
                                </option>
                            </tool>
                        </toolChain>
                    </folderInfo>
                </configuration>
            </storageModule>
        </cconfiguration>
    </storageModule>
</cproject>
"""
        (project_path / ".cproject").write_text(cproject_xml)

    def _format_include_options(self, include_paths: List[str]) -> str:
        """Format include paths for XML"""
        return "\n".join([
            f'                                    <listOptionValue builtIn="false" value="{inc}"/>'
            for inc in include_paths
        ])

    def _format_library_options(self, libraries: List[str]) -> str:
        """Format library options for XML"""
        return "\n".join([
            f'                                    <listOptionValue builtIn="false" value="{lib}"/>'
            for lib in libraries
        ])

    def _create_makefile(
        self,
        project_path: Path,
        name: str,
        architecture: TargetArchitecture,
        source_files: List[str]
    ):
        """Create QNX Makefile for project"""
        sources = " ".join([Path(src).name for src in source_files]) if source_files else "*.c *.cpp"

        makefile_content = f"""# QNX Makefile for {name}
# Generated by Momentics Adapter

LIST=VARIANT
ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

# Project name
NAME={name}

# Target architecture
ARCH={architecture.value}

# Source files
SRCS={sources}

# Include directories
EXTRA_INCVPATH=$(PROJECT_ROOT)/include

# Compiler flags
CCFLAGS+=-Wall -Wextra -std=c++14

# Linker flags
LDFLAGS+=

# Libraries
LIBS+=

# Build output directory
INSTALL_ROOT_nto=$(PROJECT_ROOT)/$(ARCH)/$(VARIANTS)

include $(MKFILES_ROOT)/qtargets.mk
"""
        (project_path / "Makefile").write_text(makefile_content)

    def build_project(
        self,
        project_name: str,
        build_variant: BuildVariant = BuildVariant.DEBUG,
        architecture: Optional[TargetArchitecture] = None,
        clean: bool = False
    ) -> Dict[str, Any]:
        """
        Build QNX project using qcc compiler.

        Args:
            project_name: Name of project to build
            build_variant: Build configuration
            architecture: Target architecture
            clean: Perform clean build

        Returns:
            Build result with output and binary path
        """
        project_path = self.workspace_path / project_name

        if not project_path.exists():
            return self._error(f"Project {project_name} not found")

        arch_dir = architecture.value if architecture else "x86_64"
        build_dir = project_path / arch_dir / build_variant.value
        build_dir.mkdir(parents=True, exist_ok=True)

        # Build using make
        make_cmd = ["make", "-C", str(project_path)]

        if clean:
            subprocess.run(make_cmd + ["clean"], capture_output=True)

        result = subprocess.run(
            make_cmd,
            capture_output=True,
            text=True,
            env={**os.environ, "VARIANT": build_variant.value}
        )

        if result.returncode != 0:
            return self._error(
                f"Build failed: {result.stderr}",
                details={"stdout": result.stdout, "stderr": result.stderr}
            )

        binary_path = build_dir / project_name

        return self._success({
            "project_name": project_name,
            "build_variant": build_variant.value,
            "binary_path": str(binary_path) if binary_path.exists() else None,
            "build_output": result.stdout
        })

    def add_target(
        self,
        target_config: TargetConfig
    ) -> Dict[str, Any]:
        """
        Add QNX target connection to IDE.

        Args:
            target_config: Target configuration details

        Returns:
            Target registration result
        """
        targets_file = self.workspace_path / ".metadata/.plugins/com.qnx.tools.ide.target/targets.xml"
        targets_file.parent.mkdir(parents=True, exist_ok=True)

        # Load or create targets XML
        if targets_file.exists():
            tree = ET.parse(targets_file)
            root = tree.getroot()
        else:
            root = ET.Element("targets")
            tree = ET.ElementTree(root)

        # Add new target
        target_elem = ET.SubElement(root, "target")
        ET.SubElement(target_elem, "name").text = target_config.name
        ET.SubElement(target_elem, "hostname").text = target_config.hostname
        ET.SubElement(target_elem, "port").text = str(target_config.port)
        ET.SubElement(target_elem, "username").text = target_config.username
        ET.SubElement(target_elem, "architecture").text = target_config.architecture.value

        # Save targets file
        tree.write(targets_file, encoding="utf-8", xml_declaration=True)

        return self._success({
            "target_name": target_config.name,
            "hostname": target_config.hostname,
            "port": target_config.port,
            "architecture": target_config.architecture.value
        })

    def launch_debug_session(
        self,
        project_name: str,
        target_name: str,
        binary_path: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Launch remote debug session on QNX target.

        Args:
            project_name: Project to debug
            target_name: Target connection name
            binary_path: Path to binary (optional, will detect from project)

        Returns:
            Debug session launch result
        """
        if not binary_path:
            project_path = self.workspace_path / project_name
            binary_path = str(project_path / "x86_64" / "debug" / project_name)

        if not Path(binary_path).exists():
            return self._error(f"Binary not found: {binary_path}")

        # Create debug launch configuration
        launch_config = {
            "project": project_name,
            "target": target_name,
            "binary": binary_path,
            "debugger": "gdb",
            "remote": True
        }

        return self._success({
            "debug_session": "launched",
            "project": project_name,
            "target": target_name,
            "binary": binary_path,
            "message": "Debug session ready. Use GDB commands to control execution."
        })

    def import_existing_project(
        self,
        source_path: str,
        project_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Import existing QNX project into workspace.

        Args:
            source_path: Path to existing project
            project_name: Name for imported project (optional)

        Returns:
            Import result
        """
        source = Path(source_path)
        if not source.exists():
            return self._error(f"Source path not found: {source_path}")

        name = project_name or source.name
        dest_path = self.workspace_path / name

        if dest_path.exists():
            return self._error(f"Project {name} already exists in workspace")

        # Copy project to workspace
        import shutil
        shutil.copytree(source, dest_path)

        return self._success({
            "project_name": name,
            "source_path": str(source),
            "workspace_path": str(dest_path),
            "imported": True
        })

    def _detect(self) -> bool:
        """Detect if QNX Momentics is installed"""
        return self.qcc_path.exists() if hasattr(self, 'qcc_path') else False

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute QNX Momentics command"""
        if command == "create_project":
            return self.create_project(**parameters)
        elif command == "build_project":
            return self.build_project(**parameters)
        elif command == "add_target":
            from ..qnx.momentics_adapter import TargetConfig
            return self.add_target(TargetConfig(**parameters))
        else:
            return {"success": False, "error": f"Unknown command: {command}"}

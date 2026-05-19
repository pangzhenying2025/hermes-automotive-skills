"""
QNX Build Adapter

Comprehensive QNX cross-compilation and build system integration.
Supports qcc compiler, multi-architecture builds, and Makefile generation.
"""

import os
import subprocess
import json
from pathlib import Path
from typing import Dict, List, Optional, Any, Set
from dataclasses import dataclass, field
from enum import Enum

from ..base_adapter import OpensourceToolAdapter


class Architecture(Enum):
    """QNX target architectures"""
    X86_64 = "x86_64"
    AARCH64LE = "aarch64le"
    ARMV7LE = "armv7le"


class OptimizationLevel(Enum):
    """Compiler optimization levels"""
    O0 = "0"  # No optimization
    O1 = "1"  # Basic optimization
    O2 = "2"  # Standard optimization
    O3 = "3"  # Aggressive optimization
    OS = "s"  # Optimize for size


class StandardVersion(Enum):
    """C/C++ standard versions"""
    C99 = "c99"
    C11 = "c11"
    CPP11 = "c++11"
    CPP14 = "c++14"
    CPP17 = "c++17"
    CPP20 = "c++20"


@dataclass
class CompilerFlags:
    """QNX compiler flags configuration"""
    optimization: OptimizationLevel = OptimizationLevel.O2
    debug: bool = False
    warnings: List[str] = field(default_factory=lambda: ["-Wall", "-Wextra"])
    standard: Optional[StandardVersion] = None
    defines: List[str] = field(default_factory=list)
    include_paths: List[str] = field(default_factory=list)
    extra_flags: List[str] = field(default_factory=list)


@dataclass
class LinkerFlags:
    """QNX linker flags configuration"""
    libraries: List[str] = field(default_factory=list)
    library_paths: List[str] = field(default_factory=list)
    static: bool = False
    strip: bool = False
    extra_flags: List[str] = field(default_factory=list)


@dataclass
class BuildConfig:
    """Complete build configuration"""
    project_name: str
    architecture: Architecture
    source_files: List[str]
    output_file: str
    compiler_flags: CompilerFlags = field(default_factory=CompilerFlags)
    linker_flags: LinkerFlags = field(default_factory=LinkerFlags)
    parallel_jobs: int = 4


class QnxBuildAdapter(OpensourceToolAdapter):
    """
    QNX build system and qcc compiler adapter.

    Provides comprehensive build automation:
    - qcc compiler wrapper with all flags
    - Multi-architecture cross-compilation
    - Makefile generation
    - Dependency tracking
    - Build output parsing

    Example:
        builder = QnxBuildAdapter()

        # Simple compilation
        result = builder.compile(
            sources=["main.c", "can_driver.c"],
            output="can_service",
            architecture=Architecture.AARCH64LE,
            libraries=["socket", "can"]
        )

        # Advanced build with custom flags
        config = BuildConfig(
            project_name="advanced_app",
            architecture=Architecture.ARMV7LE,
            source_files=["src/main.cpp", "src/module.cpp"],
            output_file="advanced_app",
            compiler_flags=CompilerFlags(
                optimization=OptimizationLevel.O3,
                debug=False,
                standard=StandardVersion.CPP14,
                defines=["NDEBUG", "AUTOMOTIVE_MODE"]
            )
        )

        result = builder.build(config)
    """

    def __init__(
        self,
        qnx_host: Optional[str] = None,
        qnx_target: Optional[str] = None,
        default_architecture: Architecture = Architecture.X86_64
    ):
        """
        Initialize QNX build adapter.

        Args:
            qnx_host: QNX_HOST path (auto-detected if not provided)
            qnx_target: QNX_TARGET path (auto-detected if not provided)
            default_architecture: Default target architecture
        """
        super().__init__(name="qnx-build", version=None)

        self.qnx_host = Path(qnx_host or os.getenv('QNX_HOST', '/opt/qnx710/host/linux/x86_64'))
        self.qnx_target = Path(qnx_target or os.getenv('QNX_TARGET', '/opt/qnx710/target/qnx7'))
        self.default_architecture = default_architecture

        # Verify QNX environment
        if not self.qnx_host.exists():
            raise ValueError(f"QNX_HOST not found: {self.qnx_host}")
        if not self.qnx_target.exists():
            raise ValueError(f"QNX_TARGET not found: {self.qnx_target}")

        # Tool paths
        self.qcc = self.qnx_host / "usr/bin/qcc"
        self.qcc_cpp = self.qnx_host / "usr/bin/q++"
        self.make = self.qnx_host / "usr/bin/make"

        if not self.qcc.exists():
            raise ValueError(f"qcc compiler not found: {self.qcc}")

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
        """Detect if QNX compiler is installed"""
        return self.qcc.exists() if hasattr(self, 'qcc') else False

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute build command"""
        if command == "compile":
            return self.compile(**parameters)
        elif command == "build":
            return self.build(parameters.get("config"))
        else:
            return {"success": False, "error": f"Unknown command: {command}"}

    def compile(
        self,
        sources: List[str],
        output: str,
        architecture: Optional[Architecture] = None,
        optimization: OptimizationLevel = OptimizationLevel.O2,
        debug: bool = False,
        standard: Optional[StandardVersion] = None,
        defines: Optional[List[str]] = None,
        include_paths: Optional[List[str]] = None,
        libraries: Optional[List[str]] = None,
        library_paths: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Compile source files using qcc.

        Args:
            sources: List of source files
            output: Output binary name
            architecture: Target architecture
            optimization: Optimization level
            debug: Include debug symbols
            standard: C/C++ standard version
            defines: Preprocessor defines
            include_paths: Include directories
            libraries: Libraries to link
            library_paths: Library search paths

        Returns:
            Compilation result with binary path
        """
        arch = architecture or self.default_architecture

        # Build compiler command
        compiler = self._get_compiler(sources)
        cmd = [str(compiler)]

        # Architecture
        cmd.extend(["-V", f"gcc_nto{arch.value}"])

        # Optimization
        cmd.append(f"-O{optimization.value}")

        # Debug symbols
        if debug:
            cmd.append("-g")

        # Standard version
        if standard:
            cmd.append(f"-std={standard.value}")

        # Defines
        for define in (defines or []):
            cmd.append(f"-D{define}")

        # Include paths
        for include in (include_paths or []):
            cmd.append(f"-I{include}")

        # Libraries
        for lib in (libraries or []):
            cmd.append(f"-l{lib}")

        # Library paths
        for lib_path in (library_paths or []):
            cmd.append(f"-L{lib_path}")

        # Output file
        cmd.extend(["-o", output])

        # Source files
        cmd.extend(sources)

        # Execute compilation
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "QNX_HOST": str(self.qnx_host),
                "QNX_TARGET": str(self.qnx_target)
            }
        )

        if result.returncode != 0:
            return self._error(
                f"Compilation failed: {result.stderr}",
                details={
                    "command": " ".join(cmd),
                    "stdout": result.stdout,
                    "stderr": result.stderr,
                    "returncode": result.returncode
                }
            )

        output_path = Path(output)
        if not output_path.exists():
            return self._error("Binary not created")

        return self._success({
            "binary": str(output_path.absolute()),
            "size_bytes": output_path.stat().st_size,
            "architecture": arch.value,
            "optimization": optimization.value,
            "compiler_output": result.stdout
        })

    def _get_compiler(self, sources: List[str]) -> Path:
        """Determine compiler based on source file extensions"""
        for src in sources:
            if src.endswith(('.cpp', '.cc', '.cxx', '.C')):
                return self.qcc_cpp
        return self.qcc

    def build(
        self,
        config: BuildConfig
    ) -> Dict[str, Any]:
        """
        Build project with full configuration.

        Args:
            config: Complete build configuration

        Returns:
            Build result
        """
        # Prepare compiler flags
        compiler = self._get_compiler(config.source_files)
        cmd = [str(compiler)]

        # Architecture
        cmd.extend(["-V", f"gcc_nto{config.architecture.value}"])

        # Optimization
        cmd.append(f"-O{config.compiler_flags.optimization.value}")

        # Debug
        if config.compiler_flags.debug:
            cmd.append("-g")

        # Standard
        if config.compiler_flags.standard:
            cmd.append(f"-std={config.compiler_flags.standard.value}")

        # Warnings
        cmd.extend(config.compiler_flags.warnings)

        # Defines
        for define in config.compiler_flags.defines:
            cmd.append(f"-D{define}")

        # Include paths
        for include in config.compiler_flags.include_paths:
            cmd.append(f"-I{include}")

        # Extra compiler flags
        cmd.extend(config.compiler_flags.extra_flags)

        # Libraries
        for lib in config.linker_flags.libraries:
            cmd.append(f"-l{lib}")

        # Library paths
        for lib_path in config.linker_flags.library_paths:
            cmd.append(f"-L{lib_path}")

        # Static linking
        if config.linker_flags.static:
            cmd.append("-static")

        # Strip symbols
        if config.linker_flags.strip:
            cmd.append("-s")

        # Extra linker flags
        cmd.extend(config.linker_flags.extra_flags)

        # Output
        cmd.extend(["-o", config.output_file])

        # Sources
        cmd.extend(config.source_files)

        # Execute build
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "QNX_HOST": str(self.qnx_host),
                "QNX_TARGET": str(self.qnx_target)
            }
        )

        if result.returncode != 0:
            return self._error(
                f"Build failed: {result.stderr}",
                details={
                    "command": " ".join(cmd),
                    "stdout": result.stdout,
                    "stderr": result.stderr
                }
            )

        output_path = Path(config.output_file)

        return self._success({
            "project_name": config.project_name,
            "binary": str(output_path.absolute()),
            "size_bytes": output_path.stat().st_size,
            "architecture": config.architecture.value,
            "build_output": result.stdout
        })

    def generate_makefile(
        self,
        config: BuildConfig,
        output_path: str = "Makefile"
    ) -> Dict[str, Any]:
        """
        Generate QNX Makefile for project.

        Args:
            config: Build configuration
            output_path: Makefile output path

        Returns:
            Makefile generation result
        """
        makefile_content = f"""# QNX Makefile for {config.project_name}
# Auto-generated by QnxBuildAdapter

# QNX Configuration
LIST=VARIANT
ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

# Project Configuration
NAME={config.project_name}
ARCH={config.architecture.value}

# Source Files
SRCS={" ".join(config.source_files)}

# Compiler Flags
CCFLAGS+={" ".join(config.compiler_flags.warnings)}
CCFLAGS+=-O{config.compiler_flags.optimization.value}
"""

        if config.compiler_flags.debug:
            makefile_content += "CCFLAGS+=-g\n"

        if config.compiler_flags.standard:
            makefile_content += f"CCFLAGS+=-std={config.compiler_flags.standard.value}\n"

        # Defines
        if config.compiler_flags.defines:
            defines_str = " ".join([f"-D{d}" for d in config.compiler_flags.defines])
            makefile_content += f"CCFLAGS+={defines_str}\n"

        # Include paths
        if config.compiler_flags.include_paths:
            makefile_content += f"\n# Include Paths\n"
            for inc in config.compiler_flags.include_paths:
                makefile_content += f"EXTRA_INCVPATH+={inc}\n"

        # Libraries
        if config.linker_flags.libraries:
            libs_str = " ".join(config.linker_flags.libraries)
            makefile_content += f"\n# Libraries\nLIBS+={libs_str}\n"

        # Library paths
        if config.linker_flags.library_paths:
            makefile_content += f"\n# Library Paths\n"
            for lib_path in config.linker_flags.library_paths:
                makefile_content += f"EXTRA_LIBVPATH+={lib_path}\n"

        makefile_content += """
# Build Rules
INSTALL_ROOT_nto=$(PROJECT_ROOT)/$(ARCH)/$(VARIANTS)

include $(MKFILES_ROOT)/qtargets.mk

# Custom targets
.PHONY: clean install

clean:
\t$(RM) -rf $(ARCH)

install:
\t$(CP) $(INSTALL_ROOT_nto)/$(NAME) /tmp/
"""

        # Write Makefile
        makefile_path = Path(output_path)
        makefile_path.write_text(makefile_content)

        return self._success({
            "makefile": str(makefile_path.absolute()),
            "project_name": config.project_name,
            "architecture": config.architecture.value
        })

    def build_with_makefile(
        self,
        makefile_dir: str,
        target: Optional[str] = None,
        variant: str = "release",
        jobs: int = 4
    ) -> Dict[str, Any]:
        """
        Build project using existing Makefile.

        Args:
            makefile_dir: Directory containing Makefile
            target: Make target (None for default)
            variant: Build variant (debug/release)
            jobs: Number of parallel jobs

        Returns:
            Build result
        """
        make_cmd = [str(self.make), "-C", makefile_dir]

        # Parallel jobs
        make_cmd.extend(["-j", str(jobs)])

        # Target
        if target:
            make_cmd.append(target)

        # Execute make
        result = subprocess.run(
            make_cmd,
            capture_output=True,
            text=True,
            env={
                **os.environ,
                "QNX_HOST": str(self.qnx_host),
                "QNX_TARGET": str(self.qnx_target),
                "VARIANT": variant
            }
        )

        if result.returncode != 0:
            return self._error(
                f"Make failed: {result.stderr}",
                details={
                    "command": " ".join(make_cmd),
                    "stdout": result.stdout,
                    "stderr": result.stderr
                }
            )

        return self._success({
            "makefile_dir": makefile_dir,
            "target": target or "default",
            "variant": variant,
            "build_output": result.stdout
        })

    def clean_build(
        self,
        makefile_dir: str
    ) -> Dict[str, Any]:
        """
        Clean build artifacts.

        Args:
            makefile_dir: Directory containing Makefile

        Returns:
            Clean result
        """
        return self.build_with_makefile(
            makefile_dir=makefile_dir,
            target="clean"
        )

    def get_compiler_version(self) -> Dict[str, Any]:
        """
        Get qcc compiler version information.

        Returns:
            Compiler version details
        """
        cmd = [str(self.qcc), "-V"]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True
        )

        return self._success({
            "compiler": "qcc",
            "version_output": result.stdout,
            "qnx_host": str(self.qnx_host),
            "qnx_target": str(self.qnx_target)
        })

    def compile_automotive_project(
        self,
        sources: List[str],
        output: str,
        architecture: Architecture = Architecture.AARCH64LE,
        include_can: bool = True,
        include_lin: bool = False,
        realtime_priority: bool = True
    ) -> Dict[str, Any]:
        """
        Compile automotive project with standard configuration.

        Args:
            sources: Source files
            output: Output binary
            architecture: Target architecture
            include_can: Include CAN support
            include_lin: Include LIN support
            realtime_priority: Enable real-time features

        Returns:
            Compilation result
        """
        defines = ["AUTOMOTIVE_BUILD"]
        libraries = ["socket", "m"]

        if include_can:
            libraries.append("can")
            defines.append("ENABLE_CAN")

        if include_lin:
            libraries.append("lin")
            defines.append("ENABLE_LIN")

        if realtime_priority:
            defines.append("REALTIME_PRIORITY")

        return self.compile(
            sources=sources,
            output=output,
            architecture=architecture,
            optimization=OptimizationLevel.O2,
            debug=False,
            standard=StandardVersion.CPP14,
            defines=defines,
            libraries=libraries
        )

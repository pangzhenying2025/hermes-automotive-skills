#!/usr/bin/env python3
"""
GCC ARM Toolchain Adapter
Cross-compilation interface for ARM Cortex microcontrollers
"""

import subprocess
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Any
import re
import logging
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


class OptimizationLevel(Enum):
    """GCC optimization levels"""
    O0 = "-O0"
    O1 = "-O1"
    O2 = "-O2"
    O3 = "-O3"
    Os = "-Os"
    Ofast = "-Ofast"


class ARMArchitecture(Enum):
    """ARM architecture variants"""
    CORTEX_M0 = "cortex-m0"
    CORTEX_M0PLUS = "cortex-m0plus"
    CORTEX_M3 = "cortex-m3"
    CORTEX_M4 = "cortex-m4"
    CORTEX_M7 = "cortex-m7"
    CORTEX_R5 = "cortex-r5"
    CORTEX_A9 = "cortex-a9"


@dataclass
class BuildConfig:
    """Build configuration"""
    target: ARMArchitecture
    optimization: OptimizationLevel
    use_fpu: bool
    debug_symbols: bool
    warnings_as_errors: bool
    defines: List[str]
    include_paths: List[Path]
    library_paths: List[Path]
    libraries: List[str]


@dataclass
class CompileResult:
    """Compilation result"""
    success: bool
    output_file: Optional[Path]
    stdout: str
    stderr: str
    warnings: List[str]
    errors: List[str]


class GCCArmAdapter:
    """
    Adapter for GCC ARM cross-compiler toolchain
    Handles compilation, linking, and binary generation for ARM targets
    """

    def __init__(self, toolchain_prefix: str = "arm-none-eabi"):
        """
        Initialize GCC ARM adapter

        Args:
            toolchain_prefix: Toolchain prefix (e.g., arm-none-eabi, arm-linux-gnueabihf)
        """
        self.toolchain_prefix = toolchain_prefix
        self.gcc = f"{toolchain_prefix}-gcc"
        self.gxx = f"{toolchain_prefix}-g++"
        self.objcopy = f"{toolchain_prefix}-objcopy"
        self.objdump = f"{toolchain_prefix}-objdump"
        self.size = f"{toolchain_prefix}-size"
        self.ar = f"{toolchain_prefix}-ar"

        self._verify_toolchain()

    def _verify_toolchain(self) -> None:
        """Verify toolchain installation"""
        if not shutil.which(self.gcc):
            logger.warning(f"Toolchain not found: {self.gcc}")
            logger.info("Please install ARM GCC toolchain")

    def compile_source(
        self,
        source_file: Path,
        config: BuildConfig,
        output_file: Optional[Path] = None
    ) -> CompileResult:
        """
        Compile source file to object file

        Args:
            source_file: Source file to compile
            config: Build configuration
            output_file: Output object file path

        Returns:
            CompileResult object
        """
        if not source_file.exists():
            raise FileNotFoundError(f"Source file not found: {source_file}")

        output_file = output_file or source_file.with_suffix(".o")

        compiler = self.gxx if source_file.suffix in [".cpp", ".cc", ".cxx"] else self.gcc

        cmd = [
            compiler,
            "-c",
            str(source_file),
            "-o", str(output_file),
            f"-mcpu={config.target.value}",
            "-mthumb",
            config.optimization.value
        ]

        if config.use_fpu and "m4" in config.target.value:
            cmd.extend(["-mfpu=fpv4-sp-d16", "-mfloat-abi=hard"])

        if config.debug_symbols:
            cmd.append("-g")

        if config.warnings_as_errors:
            cmd.append("-Werror")

        cmd.extend(["-Wall", "-Wextra", "-Wpedantic"])

        for define in config.defines:
            cmd.append(f"-D{define}")

        for include_path in config.include_paths:
            cmd.append(f"-I{include_path}")

        logger.info(f"Compiling {source_file}")
        result = subprocess.run(cmd, capture_output=True, text=True)

        warnings = self._extract_warnings(result.stderr)
        errors = self._extract_errors(result.stderr)

        return CompileResult(
            success=result.returncode == 0,
            output_file=output_file if result.returncode == 0 else None,
            stdout=result.stdout,
            stderr=result.stderr,
            warnings=warnings,
            errors=errors
        )

    def link_objects(
        self,
        object_files: List[Path],
        config: BuildConfig,
        linker_script: Optional[Path] = None,
        output_file: Optional[Path] = None
    ) -> CompileResult:
        """
        Link object files into executable

        Args:
            object_files: List of object files to link
            config: Build configuration
            linker_script: Linker script file
            output_file: Output executable path

        Returns:
            CompileResult object
        """
        output_file = output_file or Path("firmware.elf")

        cmd = [
            self.gcc,
            f"-mcpu={config.target.value}",
            "-mthumb",
            "-specs=nosys.specs",
            "-specs=nano.specs"
        ]

        if config.use_fpu and "m4" in config.target.value:
            cmd.extend(["-mfpu=fpv4-sp-d16", "-mfloat-abi=hard"])

        if linker_script:
            cmd.append(f"-T{linker_script}")

        for lib_path in config.library_paths:
            cmd.append(f"-L{lib_path}")

        for lib in config.libraries:
            cmd.append(f"-l{lib}")

        cmd.extend([str(obj) for obj in object_files])
        cmd.extend(["-o", str(output_file)])

        logger.info(f"Linking {len(object_files)} object files")
        result = subprocess.run(cmd, capture_output=True, text=True)

        return CompileResult(
            success=result.returncode == 0,
            output_file=output_file if result.returncode == 0 else None,
            stdout=result.stdout,
            stderr=result.stderr,
            warnings=self._extract_warnings(result.stderr),
            errors=self._extract_errors(result.stderr)
        )

    def build_project(
        self,
        source_files: List[Path],
        config: BuildConfig,
        linker_script: Optional[Path] = None,
        output_dir: Optional[Path] = None
    ) -> CompileResult:
        """
        Build complete project

        Args:
            source_files: List of source files
            config: Build configuration
            linker_script: Linker script
            output_dir: Output directory

        Returns:
            CompileResult object
        """
        output_dir = output_dir or Path("build")
        output_dir.mkdir(parents=True, exist_ok=True)

        object_files = []
        all_warnings = []
        all_errors = []

        for source_file in source_files:
            obj_file = output_dir / source_file.with_suffix(".o").name
            result = self.compile_source(source_file, config, obj_file)

            if not result.success:
                logger.error(f"Compilation failed: {source_file}")
                all_errors.extend(result.errors)
                return CompileResult(
                    success=False,
                    output_file=None,
                    stdout="",
                    stderr="\n".join(all_errors),
                    warnings=all_warnings,
                    errors=all_errors
                )

            object_files.append(obj_file)
            all_warnings.extend(result.warnings)

        elf_file = output_dir / "firmware.elf"
        link_result = self.link_objects(
            object_files,
            config,
            linker_script,
            elf_file
        )

        if link_result.success:
            logger.info(f"Build completed: {elf_file}")

        return CompileResult(
            success=link_result.success,
            output_file=elf_file if link_result.success else None,
            stdout=link_result.stdout,
            stderr=link_result.stderr,
            warnings=all_warnings + link_result.warnings,
            errors=link_result.errors
        )

    def generate_binary(
        self,
        elf_file: Path,
        output_format: str = "bin"
    ) -> Path:
        """
        Generate binary from ELF file

        Args:
            elf_file: Input ELF file
            output_format: Output format (bin, hex, srec)

        Returns:
            Path to generated binary
        """
        if not elf_file.exists():
            raise FileNotFoundError(f"ELF file not found: {elf_file}")

        format_extensions = {
            "bin": ".bin",
            "hex": ".hex",
            "ihex": ".hex",
            "srec": ".srec"
        }

        extension = format_extensions.get(output_format, ".bin")
        output_file = elf_file.with_suffix(extension)

        cmd = [
            self.objcopy,
            "-O", output_format,
            str(elf_file),
            str(output_file)
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Binary generation failed: {result.stderr}")

        logger.info(f"Generated binary: {output_file}")
        return output_file

    def analyze_size(self, elf_file: Path) -> Dict[str, int]:
        """
        Analyze memory usage

        Args:
            elf_file: ELF file to analyze

        Returns:
            Dictionary with section sizes
        """
        if not elf_file.exists():
            raise FileNotFoundError(f"ELF file not found: {elf_file}")

        cmd = [self.size, "-A", str(elf_file)]
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Size analysis failed: {result.stderr}")

        sizes = {}
        for line in result.stdout.split("\n"):
            match = re.match(r"(\.\w+)\s+(\d+)", line)
            if match:
                section, size = match.groups()
                sizes[section] = int(size)

        logger.info(f"Memory usage: {sizes}")
        return sizes

    def disassemble(
        self,
        elf_file: Path,
        output_file: Optional[Path] = None
    ) -> Path:
        """
        Generate disassembly listing

        Args:
            elf_file: ELF file to disassemble
            output_file: Output disassembly file

        Returns:
            Path to disassembly file
        """
        if not elf_file.exists():
            raise FileNotFoundError(f"ELF file not found: {elf_file}")

        output_file = output_file or elf_file.with_suffix(".lst")

        cmd = [
            self.objdump,
            "-d",
            "-S",
            str(elf_file)
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Disassembly failed: {result.stderr}")

        output_file.write_text(result.stdout)
        logger.info(f"Generated disassembly: {output_file}")

        return output_file

    def create_library(
        self,
        object_files: List[Path],
        library_name: str,
        output_dir: Optional[Path] = None
    ) -> Path:
        """
        Create static library

        Args:
            object_files: Object files to include
            library_name: Library name (without lib prefix and .a suffix)
            output_dir: Output directory

        Returns:
            Path to created library
        """
        output_dir = output_dir or Path.cwd()
        output_dir.mkdir(parents=True, exist_ok=True)

        library_file = output_dir / f"lib{library_name}.a"

        cmd = [self.ar, "rcs", str(library_file)]
        cmd.extend([str(obj) for obj in object_files])

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Library creation failed: {result.stderr}")

        logger.info(f"Created library: {library_file}")
        return library_file

    def _extract_warnings(self, stderr: str) -> List[str]:
        """Extract warning messages from compiler output"""
        warnings = []
        for line in stderr.split("\n"):
            if "warning:" in line.lower():
                warnings.append(line.strip())
        return warnings

    def _extract_errors(self, stderr: str) -> List[str]:
        """Extract error messages from compiler output"""
        errors = []
        for line in stderr.split("\n"):
            if "error:" in line.lower():
                errors.append(line.strip())
        return errors

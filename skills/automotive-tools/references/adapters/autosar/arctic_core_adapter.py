#!/usr/bin/env python3
"""
Arctic Core AUTOSAR Adapter
Opensource AUTOSAR implementation - build and configuration interface
"""

import subprocess
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Any
import yaml
import logging
from dataclasses import dataclass
import re

logger = logging.getLogger(__name__)


@dataclass
class ArcticCoreConfig:
    """Arctic Core project configuration"""
    board: str
    mcu: str
    modules: List[str]
    compiler: str = "gcc"
    build_type: str = "Debug"


class ArcticCoreAdapter:
    """
    Adapter for Arctic Core opensource AUTOSAR implementation
    Handles project generation, building, and configuration
    """

    def __init__(self, arctic_core_path: Optional[Path] = None):
        """
        Initialize Arctic Core adapter

        Args:
            arctic_core_path: Path to Arctic Core installation
        """
        self.arctic_core_path = arctic_core_path or self._find_arctic_core()
        self.boards_path = self.arctic_core_path / "boards"
        self.arch_path = self.arctic_core_path / "arch"
        self.scripts_path = self.arctic_core_path / "scripts"

        if not self.arctic_core_path.exists():
            logger.warning(f"Arctic Core not found at {self.arctic_core_path}")
            logger.info("Running in simulation mode")
            self.simulation_mode = True
        else:
            self.simulation_mode = False

    def _find_arctic_core(self) -> Path:
        """Find Arctic Core installation"""
        import os

        if "ARCTIC_CORE_PATH" in os.environ:
            return Path(os.environ["ARCTIC_CORE_PATH"])

        common_paths = [
            Path.cwd() / "arctic-core",
            Path.home() / "arctic-core",
            Path("/opt/arctic-core"),
            Path("/usr/local/arctic-core")
        ]

        for path in common_paths:
            if path.exists() and (path / "boards").exists():
                return path

        logger.warning("Arctic Core not found, using simulation mode")
        return Path.cwd() / "arctic_core_mock"

    def list_supported_boards(self) -> List[str]:
        """List all supported boards"""
        if self.simulation_mode:
            return [
                "rpi_pico", "stm32f4_discovery", "arduino_due",
                "mpc5748g_devkit", "tc397_adas", "zynq_zc702"
            ]

        if not self.boards_path.exists():
            return []

        boards = []
        for board_dir in self.boards_path.iterdir():
            if board_dir.is_dir() and (board_dir / "board_info.txt").exists():
                boards.append(board_dir.name)

        return sorted(boards)

    def list_supported_mcus(self) -> Dict[str, List[str]]:
        """List supported MCUs by architecture"""
        if self.simulation_mode:
            return {
                "arm": ["cortex-m4", "cortex-m7", "cortex-r5"],
                "ppc": ["mpc5748g", "mpc5777c"],
                "tricore": ["tc397", "tc387"]
            }

        if not self.arch_path.exists():
            return {}

        mcus = {}
        for arch_dir in self.arch_path.iterdir():
            if arch_dir.is_dir():
                arch_name = arch_dir.name
                mcu_dirs = [d.name for d in arch_dir.iterdir() if d.is_dir()]
                if mcu_dirs:
                    mcus[arch_name] = sorted(mcu_dirs)

        return mcus

    def create_project(
        self,
        project_name: str,
        board: str,
        modules: List[str],
        output_dir: Optional[Path] = None
    ) -> Path:
        """
        Create new Arctic Core project

        Args:
            project_name: Project name
            board: Target board
            modules: List of AUTOSAR modules to include
            output_dir: Output directory

        Returns:
            Path to created project
        """
        output_dir = output_dir or Path.cwd() / project_name
        output_dir.mkdir(parents=True, exist_ok=True)

        if self.simulation_mode:
            return self._create_mock_project(
                project_name, board, modules, output_dir
            )

        config = ArcticCoreConfig(
            board=board,
            mcu=self._get_board_mcu(board),
            modules=modules
        )

        self._copy_board_template(board, output_dir)
        self._generate_makefile(output_dir, config)
        self._generate_module_configs(output_dir, modules)

        logger.info(f"Arctic Core project created: {output_dir}")
        return output_dir

    def _get_board_mcu(self, board: str) -> str:
        """Get MCU for board"""
        board_info = self.boards_path / board / "board_info.txt"

        if not board_info.exists():
            return "unknown"

        content = board_info.read_text()
        match = re.search(r'MCU:\s*(\S+)', content)
        return match.group(1) if match else "unknown"

    def _copy_board_template(self, board: str, output_dir: Path) -> None:
        """Copy board template files"""
        board_path = self.boards_path / board

        if not board_path.exists():
            logger.warning(f"Board template not found: {board}")
            return

        config_files = ["board_config.h", "linker.ld", "startup.s"]

        for file_name in config_files:
            src = board_path / file_name
            if src.exists():
                dst = output_dir / file_name
                shutil.copy2(src, dst)
                logger.debug(f"Copied {file_name}")

    def _generate_makefile(
        self,
        output_dir: Path,
        config: ArcticCoreConfig
    ) -> None:
        """Generate project Makefile"""
        makefile_content = f"""# Arctic Core AUTOSAR Project Makefile
# Generated by Arctic Core Adapter

BOARD = {config.board}
MCU = {config.mcu}
COMPILER = {config.compiler}

# Arctic Core paths
ARCTIC_CORE_PATH ?= {self.arctic_core_path}
BOARD_PATH = $(ARCTIC_CORE_PATH)/boards/$(BOARD)
ARCH_PATH = $(ARCTIC_CORE_PATH)/arch/$(MCU)

# Module selection
MODULES = {' '.join(config.modules)}

# Include paths
INCLUDES = -I. \\
           -I$(ARCTIC_CORE_PATH)/include \\
           -I$(BOARD_PATH) \\
           -I$(ARCH_PATH)/include

# Source files
SRCS = $(wildcard *.c) \\
       $(foreach mod,$(MODULES),$(wildcard $(ARCTIC_CORE_PATH)/$(mod)/*.c))

OBJS = $(SRCS:.c=.o)

# Compiler flags
CFLAGS = $(INCLUDES) -Wall -Wextra -O2

# Linker flags
LDFLAGS = -T linker.ld

# Target
TARGET = autosar_app.elf

all: $(TARGET)

$(TARGET): $(OBJS)
\t$(COMPILER)-gcc $(LDFLAGS) -o $@ $^

%.o: %.c
\t$(COMPILER)-gcc $(CFLAGS) -c -o $@ $<

clean:
\trm -f $(OBJS) $(TARGET)

flash: $(TARGET)
\t$(ARCTIC_CORE_PATH)/scripts/flash.sh $(BOARD) $(TARGET)

.PHONY: all clean flash
"""

        makefile = output_dir / "Makefile"
        makefile.write_text(makefile_content)
        logger.info("Generated Makefile")

    def _generate_module_configs(
        self,
        output_dir: Path,
        modules: List[str]
    ) -> None:
        """Generate module configuration files"""
        config_dir = output_dir / "config"
        config_dir.mkdir(exist_ok=True)

        for module in modules:
            config_file = config_dir / f"{module}_Cfg.h"
            config_content = f"""#ifndef {module.upper()}_CFG_H
#define {module.upper()}_CFG_H

/* {module} Configuration - Generated by Arctic Core Adapter */

#define {module.upper()}_DEV_ERROR_DETECT    STD_ON
#define {module.upper()}_VERSION_INFO_API     STD_ON

#endif /* {module.upper()}_CFG_H */
"""
            config_file.write_text(config_content)

        logger.info(f"Generated configs for {len(modules)} modules")

    def _create_mock_project(
        self,
        project_name: str,
        board: str,
        modules: List[str],
        output_dir: Path
    ) -> Path:
        """Create mock project for simulation mode"""
        (output_dir / "config").mkdir(exist_ok=True)
        (output_dir / "src").mkdir(exist_ok=True)

        main_c = output_dir / "src" / "main.c"
        main_c.write_text(f"""/* Arctic Core AUTOSAR Project: {project_name} */
#include "Std_Types.h"

int main(void) {{
    /* Board: {board} */
    /* Modules: {', '.join(modules)} */

    while(1) {{
        /* Main loop */
    }}

    return 0;
}}
""")

        config = ArcticCoreConfig(board=board, mcu="mock_mcu", modules=modules)
        self._generate_makefile(output_dir, config)
        self._generate_module_configs(output_dir, modules)

        logger.info(f"Created mock project at {output_dir}")
        return output_dir

    def build_project(
        self,
        project_dir: Path,
        build_type: str = "Debug",
        jobs: int = 4
    ) -> Dict[str, Any]:
        """
        Build Arctic Core project

        Args:
            project_dir: Project directory
            build_type: Debug or Release
            jobs: Number of parallel jobs

        Returns:
            Build result dictionary
        """
        makefile = project_dir / "Makefile"

        if not makefile.exists():
            raise FileNotFoundError(f"Makefile not found in {project_dir}")

        cmd = ["make", f"-j{jobs}", f"BUILD_TYPE={build_type}"]

        logger.info(f"Building project in {project_dir}")
        result = subprocess.run(
            cmd,
            cwd=project_dir,
            capture_output=True,
            text=True
        )

        build_result = {
            "success": result.returncode == 0,
            "output": result.stdout,
            "errors": result.stderr,
            "build_type": build_type
        }

        if build_result["success"]:
            logger.info("Build completed successfully")
        else:
            logger.error(f"Build failed: {result.stderr}")

        return build_result

    def flash_target(
        self,
        project_dir: Path,
        interface: str = "openocd"
    ) -> bool:
        """
        Flash built firmware to target

        Args:
            project_dir: Project directory
            interface: Flash interface (openocd, jlink, etc.)

        Returns:
            True if successful
        """
        makefile = project_dir / "Makefile"

        if not makefile.exists():
            raise FileNotFoundError(f"Makefile not found in {project_dir}")

        cmd = ["make", "flash", f"FLASH_INTERFACE={interface}"]

        logger.info(f"Flashing target via {interface}")
        result = subprocess.run(
            cmd,
            cwd=project_dir,
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            logger.info("Flash completed successfully")
            return True
        else:
            logger.error(f"Flash failed: {result.stderr}")
            return False

    def generate_rte(
        self,
        project_dir: Path,
        swc_configs: List[Dict[str, Any]]
    ) -> Path:
        """
        Generate RTE (Runtime Environment) code

        Args:
            project_dir: Project directory
            swc_configs: List of SWC configurations

        Returns:
            Path to generated RTE code
        """
        rte_dir = project_dir / "rte"
        rte_dir.mkdir(exist_ok=True)

        rte_h = rte_dir / "Rte.h"
        rte_h.write_text("""#ifndef RTE_H
#define RTE_H

#include "Std_Types.h"

/* RTE Generated by Arctic Core Adapter */

#endif /* RTE_H */
""")

        for swc_config in swc_configs:
            swc_name = swc_config.get("name", "UnknownSWC")
            rte_swc_h = rte_dir / f"Rte_{swc_name}.h"

            rte_swc_h.write_text(f"""#ifndef RTE_{swc_name.upper()}_H
#define RTE_{swc_name.upper()}_H

#include "Rte.h"

/* RTE interface for {swc_name} */

#endif /* RTE_{swc_name.upper()}_H */
""")

        logger.info(f"Generated RTE for {len(swc_configs)} SWCs")
        return rte_dir

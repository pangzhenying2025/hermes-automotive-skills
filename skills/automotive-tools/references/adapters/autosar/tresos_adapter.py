#!/usr/bin/env python3
"""
EB tresos Studio Adapter
Provides programmatic interface to Elektrobit tresos Studio for AUTOSAR Classic configuration
"""

import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Optional, Any
import json
import logging
from dataclasses import dataclass
import shutil

logger = logging.getLogger(__name__)


@dataclass
class TresosProject:
    """Represents a tresos project configuration"""
    path: Path
    name: str
    autosar_version: str
    modules: List[str]


@dataclass
class TresosModule:
    """Represents an AUTOSAR BSW module configuration"""
    name: str
    vendor: str
    version: str
    parameters: Dict[str, Any]


class TresosAdapter:
    """
    Adapter for EB tresos Studio automation
    Supports project creation, module configuration, and code generation
    """

    def __init__(self, tresos_home: Optional[str] = None):
        """
        Initialize tresos adapter

        Args:
            tresos_home: Path to tresos installation (defaults to TRESOS_HOME env var)
        """
        self.tresos_home = Path(tresos_home or self._find_tresos_home())
        self.tresos_cli = self.tresos_home / "bin" / "tresos_cmd.sh"
        self.workspace = Path.cwd() / "tresos_workspace"

        if not self.tresos_cli.exists():
            logger.warning(f"tresos CLI not found at {self.tresos_cli}")
            logger.info("Running in simulation mode - will generate mock outputs")
            self.simulation_mode = True
        else:
            self.simulation_mode = False

    def _find_tresos_home(self) -> str:
        """Find tresos installation directory"""
        import os
        if "TRESOS_HOME" in os.environ:
            return os.environ["TRESOS_HOME"]

        common_paths = [
            "/opt/Elektrobit/tresos",
            "/opt/EB/tresos",
            "C:/Program Files/Elektrobit/tresos",
            Path.home() / "EB" / "tresos"
        ]

        for path in common_paths:
            if Path(path).exists():
                return str(path)

        logger.warning("tresos installation not found, using simulation mode")
        return str(Path.cwd() / "tresos_mock")

    def create_project(
        self,
        project_name: str,
        autosar_version: str = "4.2.2",
        derivative: str = "TC38XQ",
        output_dir: Optional[Path] = None
    ) -> TresosProject:
        """
        Create new tresos project

        Args:
            project_name: Name of the project
            autosar_version: AUTOSAR version (4.0.3, 4.2.2, etc.)
            derivative: Target microcontroller derivative
            output_dir: Output directory for project

        Returns:
            TresosProject object
        """
        output_dir = output_dir or self.workspace / project_name
        output_dir.mkdir(parents=True, exist_ok=True)

        if self.simulation_mode:
            return self._create_mock_project(project_name, autosar_version, output_dir)

        cmd = [
            str(self.tresos_cli),
            "createProject",
            f"-projectName={project_name}",
            f"-autosarVersion={autosar_version}",
            f"-derivative={derivative}",
            f"-workspace={self.workspace}"
        ]

        logger.info(f"Creating tresos project: {project_name}")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Failed to create project: {result.stderr}")

        logger.info(f"Project created successfully: {output_dir}")

        return TresosProject(
            path=output_dir,
            name=project_name,
            autosar_version=autosar_version,
            modules=[]
        )

    def _create_mock_project(
        self,
        project_name: str,
        autosar_version: str,
        output_dir: Path
    ) -> TresosProject:
        """Create mock project structure for simulation mode"""
        (output_dir / "config").mkdir(exist_ok=True)
        (output_dir / "generated").mkdir(exist_ok=True)

        project_file = output_dir / f"{project_name}.tresos"
        project_file.write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<AUTOSAR xsi:schemaLocation="http://autosar.org/schema/r{autosar_version} AUTOSAR_{autosar_version.replace('.', '')}.xsd"
         xmlns="http://autosar.org/schema/r{autosar_version}"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>{project_name}</SHORT-NAME>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
""")

        logger.info(f"Created mock project at {output_dir}")
        return TresosProject(
            path=output_dir,
            name=project_name,
            autosar_version=autosar_version,
            modules=[]
        )

    def import_bsw_module(
        self,
        project: TresosProject,
        module_name: str,
        module_path: Optional[Path] = None
    ) -> TresosModule:
        """
        Import BSW module into project

        Args:
            project: Target project
            module_name: Name of module (e.g., Can, CanIf, Com)
            module_path: Path to module plugin (optional)

        Returns:
            TresosModule object
        """
        if self.simulation_mode:
            return self._import_mock_module(project, module_name)

        cmd = [
            str(self.tresos_cli),
            "importBswModule",
            f"-projectName={project.name}",
            f"-moduleName={module_name}",
            f"-workspace={self.workspace}"
        ]

        if module_path:
            cmd.append(f"-modulePath={module_path}")

        logger.info(f"Importing module {module_name} into {project.name}")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Failed to import module: {result.stderr}")

        project.modules.append(module_name)

        return TresosModule(
            name=module_name,
            vendor="Elektrobit",
            version="1.0.0",
            parameters={}
        )

    def _import_mock_module(
        self,
        project: TresosProject,
        module_name: str
    ) -> TresosModule:
        """Import mock module for simulation mode"""
        config_file = project.path / "config" / f"{module_name}_Cfg.xdm"
        config_file.write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<AUTOSAR-MODULE name="{module_name}">
  <MODULE-CONFIGURATION>
    <SHORT-NAME>{module_name}</SHORT-NAME>
  </MODULE-CONFIGURATION>
</AUTOSAR-MODULE>
""")

        project.modules.append(module_name)
        logger.info(f"Imported mock module {module_name}")

        return TresosModule(
            name=module_name,
            vendor="Mock",
            version="1.0.0",
            parameters={}
        )

    def configure_module(
        self,
        project: TresosProject,
        module_name: str,
        parameters: Dict[str, Any]
    ) -> None:
        """
        Configure BSW module parameters

        Args:
            project: Target project
            module_name: Module to configure
            parameters: Parameter dictionary
        """
        config_file = project.path / "config" / f"{module_name}_Cfg.xdm"

        if self.simulation_mode or not config_file.exists():
            self._configure_mock_module(project, module_name, parameters)
            return

        tree = ET.parse(config_file)
        root = tree.getroot()

        for param_path, value in parameters.items():
            self._set_parameter(root, param_path, value)

        tree.write(config_file, encoding="UTF-8", xml_declaration=True)
        logger.info(f"Configured {module_name} with {len(parameters)} parameters")

    def _configure_mock_module(
        self,
        project: TresosProject,
        module_name: str,
        parameters: Dict[str, Any]
    ) -> None:
        """Configure mock module parameters"""
        config_file = project.path / "config" / f"{module_name}_Cfg.json"
        config_file.write_text(json.dumps(parameters, indent=2))
        logger.info(f"Configured mock module {module_name}")

    def _set_parameter(
        self,
        root: ET.Element,
        param_path: str,
        value: Any
    ) -> None:
        """Set parameter value in XML configuration"""
        path_parts = param_path.split("/")
        current = root

        for part in path_parts[:-1]:
            found = current.find(f".//{part}")
            if found is None:
                new_elem = ET.SubElement(current, part)
                current = new_elem
            else:
                current = found

        param_name = path_parts[-1]
        param_elem = current.find(f".//{param_name}")

        if param_elem is None:
            param_elem = ET.SubElement(current, param_name)

        param_elem.text = str(value)

    def generate_code(
        self,
        project: TresosProject,
        output_dir: Optional[Path] = None
    ) -> Path:
        """
        Generate BSW code from configuration

        Args:
            project: Source project
            output_dir: Output directory for generated code

        Returns:
            Path to generated code
        """
        output_dir = output_dir or project.path / "generated"
        output_dir.mkdir(parents=True, exist_ok=True)

        if self.simulation_mode:
            return self._generate_mock_code(project, output_dir)

        cmd = [
            str(self.tresos_cli),
            "generate",
            f"-projectName={project.name}",
            f"-workspace={self.workspace}",
            f"-output={output_dir}"
        ]

        logger.info(f"Generating code for {project.name}")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Code generation failed: {result.stderr}")

        logger.info(f"Code generated successfully: {output_dir}")
        return output_dir

    def _generate_mock_code(
        self,
        project: TresosProject,
        output_dir: Path
    ) -> Path:
        """Generate mock BSW code"""
        for module in project.modules:
            header_file = output_dir / f"{module}.h"
            source_file = output_dir / f"{module}.c"

            header_file.write_text(f"""#ifndef {module.upper()}_H
#define {module.upper()}_H

#include "Std_Types.h"

void {module}_Init(void);
void {module}_MainFunction(void);

#endif /* {module.upper()}_H */
""")

            source_file.write_text(f"""#include "{module}.h"

void {module}_Init(void) {{
    /* Generated by tresos */
}}

void {module}_MainFunction(void) {{
    /* Generated by tresos */
}}
""")

        logger.info(f"Generated mock code for {len(project.modules)} modules")
        return output_dir

    def validate_configuration(self, project: TresosProject) -> Dict[str, Any]:
        """
        Validate project configuration

        Args:
            project: Project to validate

        Returns:
            Validation report
        """
        if self.simulation_mode:
            return {
                "valid": True,
                "errors": [],
                "warnings": [],
                "info": ["Simulation mode - validation skipped"]
            }

        cmd = [
            str(self.tresos_cli),
            "validate",
            f"-projectName={project.name}",
            f"-workspace={self.workspace}"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        return {
            "valid": result.returncode == 0,
            "errors": self._parse_validation_output(result.stderr, "ERROR"),
            "warnings": self._parse_validation_output(result.stderr, "WARNING"),
            "info": self._parse_validation_output(result.stdout, "INFO")
        }

    def _parse_validation_output(
        self,
        output: str,
        level: str
    ) -> List[str]:
        """Parse validation output for specific level"""
        lines = output.split("\n")
        return [line for line in lines if level in line]

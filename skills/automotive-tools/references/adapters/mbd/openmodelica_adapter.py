"""
OpenModelica Adapter for opensource Model-Based Development.

Supports:
- Modelica model compilation and simulation
- FMU export (FMI 2.0/3.0)
- OMPython scripting interface
- Model checking and validation
- Result visualization
"""

import os
import subprocess
import json
import shutil
from typing import Dict, List, Optional, Any
from pathlib import Path
import logging

from ..base_adapter import OpensourceToolAdapter


class OpenModelicaAdapter(OpensourceToolAdapter):
    """Adapter for OpenModelica simulation environment."""

    def __init__(self, version: Optional[str] = None):
        """
        Initialize OpenModelica adapter.

        Args:
            version: OpenModelica version (auto-detect if None)
        """
        self.omc_bin = None
        self.ompython_available = False
        super().__init__(name='openmodelica', version=version)

    def _detect(self) -> bool:
        """Detect if OpenModelica is installed."""
        # Check for omc (OpenModelica Compiler)
        omc_path = shutil.which('omc')

        if omc_path:
            self.omc_bin = omc_path
            self.logger.info(f"Found OpenModelica at: {omc_path}")

            # Get version
            try:
                result = subprocess.run(
                    [self.omc_bin, '--version'],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                if result.returncode == 0:
                    # Extract version from output
                    version_line = result.stdout.strip().split('\n')[0]
                    if 'v' in version_line:
                        self.version = version_line.split('v')[1].split()[0]
                    self.logger.info(f"OpenModelica version: {self.version}")
            except Exception as e:
                self.logger.warning(f"Could not determine OpenModelica version: {e}")

            # Check for OMPython
            try:
                import OMPython
                self.ompython_available = True
                self.logger.info("OMPython available")
            except ImportError:
                self.logger.warning("OMPython not available - install with: pip install OMPython")

            return True

        self.logger.warning("OpenModelica not found - install from https://openmodelica.org")
        return False

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute OpenModelica command.

        Commands:
        - compile: Compile Modelica model
        - simulate: Simulate Modelica model
        - check_model: Check model syntax
        - export_fmu: Export model as FMU
        - linearize: Linearize model
        - optimize: Run optimization

        Args:
            command: Command name
            parameters: Command parameters

        Returns:
            Dictionary with execution results
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'OpenModelica not available'
            }

        command_map = {
            'compile': self._compile,
            'simulate': self._simulate,
            'check_model': self._check_model,
            'export_fmu': self._export_fmu,
            'linearize': self._linearize,
            'optimize': self._optimize
        }

        if command not in command_map:
            return {
                'success': False,
                'error': f'Unknown command: {command}'
            }

        try:
            return command_map[command](parameters)
        except Exception as e:
            self.logger.exception(f"Command '{command}' failed")
            return {
                'success': False,
                'error': str(e)
            }

    def _compile(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Compile Modelica model.

        Parameters:
        - model_file: Path to .mo file
        - model_name: Name of model to compile (optional)
        - output_dir: Output directory (optional)
        """
        model_file = self.validate_path(params['model_file'], must_exist=True)
        model_name = params.get('model_name', model_file.stem)
        output_dir = params.get('output_dir', Path.cwd())

        # Create OMC script
        script = f"""
        loadFile("{model_file}");
        loadModel(Modelica);
        checkModel({model_name});
        getErrorString();
        """

        script_file = Path('/tmp/omc_compile.mos')
        script_file.write_text(script)

        # Execute OMC
        self.logger.info(f"Compiling model: {model_name}")
        result = self.run_subprocess(
            [self.omc_bin, str(script_file)],
            cwd=str(output_dir),
            timeout=120
        )

        # Check for errors
        success = result.returncode == 0 and 'Error' not in result.stdout

        return {
            'success': success,
            'model_name': model_name,
            'model_file': str(model_file),
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _simulate(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Simulate Modelica model.

        Parameters:
        - model_file: Path to .mo file
        - model_name: Name of model to simulate
        - start_time: Start time (default: 0)
        - stop_time: Stop time (default: 1)
        - step_size: Step size (optional)
        - solver: Solver method ('dassl', 'euler', 'rungekutta')
        - output_format: 'csv', 'mat', 'plt'
        """
        model_file = self.validate_path(params['model_file'], must_exist=True)
        model_name = params['model_name']
        start_time = params.get('start_time', 0)
        stop_time = params.get('stop_time', 1)
        step_size = params.get('step_size', (stop_time - start_time) / 500)
        solver = params.get('solver', 'dassl')
        output_format = params.get('output_format', 'csv')
        output_dir = self.ensure_dir(params.get('output_dir', Path.cwd()))

        # Create simulation script
        script = f"""
        loadFile("{model_file}");
        loadModel(Modelica);

        simulate({model_name},
            startTime={start_time},
            stopTime={stop_time},
            numberOfIntervals={int((stop_time-start_time)/step_size)},
            method="{solver}",
            outputFormat="{output_format}"
        );

        getErrorString();
        """

        script_file = output_dir / 'simulate.mos'
        script_file.write_text(script)

        # Execute simulation
        self.logger.info(f"Simulating model: {model_name}")
        result = self.run_subprocess(
            [self.omc_bin, str(script_file)],
            cwd=str(output_dir),
            timeout=600
        )

        success = result.returncode == 0 and 'Error' not in result.stdout

        # Find result file
        result_file = None
        if success:
            result_patterns = [
                output_dir / f'{model_name}_res.{output_format}',
                output_dir / f'{model_name}_res.mat',
                output_dir / f'{model_name}_res.csv'
            ]
            for pattern in result_patterns:
                if pattern.exists():
                    result_file = str(pattern)
                    break

        return {
            'success': success,
            'model_name': model_name,
            'result_file': result_file,
            'solver': solver,
            'start_time': start_time,
            'stop_time': stop_time,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _check_model(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Check model syntax and consistency.

        Parameters:
        - model_file: Path to .mo file
        - model_name: Name of model to check
        """
        model_file = self.validate_path(params['model_file'], must_exist=True)
        model_name = params['model_name']

        script = f"""
        loadFile("{model_file}");
        loadModel(Modelica);
        checkModel({model_name});
        getErrorString();
        """

        script_file = Path('/tmp/check_model.mos')
        script_file.write_text(script)

        result = self.run_subprocess(
            [self.omc_bin, str(script_file)],
            timeout=60
        )

        # Parse output for check results
        success = 'successfully' in result.stdout.lower() and 'Error' not in result.stdout

        return {
            'success': success,
            'model_name': model_name,
            'check_output': result.stdout,
            'errors': result.stderr
        }

    def _export_fmu(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Export Modelica model as FMU.

        Parameters:
        - model_file: Path to .mo file
        - model_name: Name of model to export
        - fmi_version: '2.0' or '3.0'
        - fmu_type: 'me' (Model Exchange) or 'cs' (Co-Simulation)
        - output_dir: Output directory
        """
        model_file = self.validate_path(params['model_file'], must_exist=True)
        model_name = params['model_name']
        fmi_version = params.get('fmi_version', '2.0')
        fmu_type = params.get('fmu_type', 'cs')
        output_dir = self.ensure_dir(params.get('output_dir', 'fmu_export'))

        script = f"""
        loadFile("{model_file}");
        loadModel(Modelica);

        buildModelFMU({model_name},
            version="{fmi_version}",
            fmuType="{fmu_type}",
            platforms={{"dynamic"}}
        );

        getErrorString();
        """

        script_file = output_dir / 'export_fmu.mos'
        script_file.write_text(script)

        self.logger.info(f"Exporting FMU: {model_name}")
        result = self.run_subprocess(
            [self.omc_bin, str(script_file)],
            cwd=str(output_dir),
            timeout=300
        )

        success = result.returncode == 0 and 'Error' not in result.stdout

        # Find generated FMU
        fmu_path = None
        if success:
            fmu_file = output_dir / f'{model_name}.fmu'
            if fmu_file.exists():
                fmu_path = str(fmu_file)

        return {
            'success': success,
            'model_name': model_name,
            'fmu_path': fmu_path,
            'fmi_version': fmi_version,
            'fmu_type': fmu_type,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _linearize(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Linearize Modelica model.

        Parameters:
        - model_file: Path to .mo file
        - model_name: Name of model to linearize
        - linearize_time: Time point for linearization
        """
        model_file = self.validate_path(params['model_file'], must_exist=True)
        model_name = params['model_name']
        linearize_time = params.get('linearize_time', 0.0)

        script = f"""
        loadFile("{model_file}");
        loadModel(Modelica);

        linearize({model_name}, startTime={linearize_time}, stopTime={linearize_time});

        getErrorString();
        """

        script_file = Path('/tmp/linearize.mos')
        script_file.write_text(script)

        result = self.run_subprocess(
            [self.omc_bin, str(script_file)],
            timeout=120
        )

        success = result.returncode == 0 and 'Error' not in result.stdout

        return {
            'success': success,
            'model_name': model_name,
            'linearize_time': linearize_time,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _optimize(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run optimization on Modelica model.

        Parameters:
        - model_file: Path to .mo file
        - model_name: Name of model to optimize
        - objective: Objective function
        """
        return {
            'success': False,
            'error': 'Optimization requires OpenModelica Optimization extension'
        }

    def simulate_with_ompython(self, model_file: str, model_name: str, **sim_params) -> Dict[str, Any]:
        """
        Simulate using OMPython interface (if available).

        Args:
            model_file: Path to .mo file
            model_name: Model name
            **sim_params: Simulation parameters

        Returns:
            Simulation results
        """
        if not self.ompython_available:
            return {
                'success': False,
                'error': 'OMPython not available'
            }

        try:
            from OMPython import OMCSessionZMQ

            omc = OMCSessionZMQ()

            # Load model
            omc.sendExpression(f"loadFile('{model_file}')")
            omc.sendExpression("loadModel(Modelica)")

            # Simulate
            start_time = sim_params.get('start_time', 0)
            stop_time = sim_params.get('stop_time', 1)
            num_intervals = sim_params.get('num_intervals', 500)

            sim_cmd = f"""
            simulate({model_name},
                startTime={start_time},
                stopTime={stop_time},
                numberOfIntervals={num_intervals})
            """

            result = omc.sendExpression(sim_cmd)

            return {
                'success': True,
                'model_name': model_name,
                'result': result
            }

        except Exception as e:
            self.logger.exception("OMPython simulation failed")
            return {
                'success': False,
                'error': str(e)
            }

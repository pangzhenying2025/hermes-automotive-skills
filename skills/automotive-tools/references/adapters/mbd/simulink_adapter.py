"""
MATLAB/Simulink Adapter for Model-Based Development.

Supports:
- Simulink model manipulation
- Embedded Coder code generation
- Model validation and verification
- FMU export
- Requirements traceability
"""

import os
import subprocess
import json
from typing import Dict, List, Optional, Any
from pathlib import Path
import logging

from ..base_adapter import CommercialToolAdapter


class SimulinkAdapter(CommercialToolAdapter):
    """Adapter for MATLAB/Simulink Embedded Coder."""

    def __init__(self, matlab_root: Optional[str] = None, version: Optional[str] = None):
        """
        Initialize Simulink adapter.

        Args:
            matlab_root: Path to MATLAB installation (auto-detect if None)
            version: MATLAB version (auto-detect if None)
        """
        self.matlab_root = matlab_root or os.environ.get('MATLAB_ROOT', '/usr/local/MATLAB')
        self.matlab_bin = None
        super().__init__(name='simulink', version=version)

    def _detect(self) -> bool:
        """Detect if MATLAB/Simulink is installed."""
        # Check for matlab executable
        matlab_paths = [
            os.path.join(self.matlab_root, 'bin', 'matlab'),
            '/usr/local/bin/matlab',
            '/opt/MATLAB/bin/matlab'
        ]

        for matlab_path in matlab_paths:
            if os.path.exists(matlab_path):
                self.matlab_bin = matlab_path
                self.logger.info(f"Found MATLAB at: {matlab_path}")
                return True

        self.logger.warning("MATLAB/Simulink not found")
        return False

    def _check_license(self) -> bool:
        """Check if MATLAB license is valid."""
        if not self.is_available:
            return False

        try:
            # Run matlab -r ver to check license
            result = self.run_subprocess(
                [self.matlab_bin, '-batch', 'ver; exit'],
                timeout=30
            )

            if result.returncode == 0:
                self.logger.info("MATLAB license valid")
                # Try to extract version
                if 'R20' in result.stdout:
                    import re
                    match = re.search(r'R(\d{4}[ab])', result.stdout)
                    if match:
                        self.version = match.group(0)
                return True
            else:
                self.logger.error("MATLAB license check failed")
                return False

        except Exception as e:
            self.logger.error(f"License check error: {e}")
            return False

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute Simulink command.

        Commands:
        - build_model: Generate code from Simulink model
        - validate_model: Run Model Advisor checks
        - export_fmu: Export model as FMU
        - simulate: Run simulation
        - generate_report: Create code generation report

        Args:
            command: Command name
            parameters: Command parameters

        Returns:
            Dictionary with execution results
        """
        if not self.is_available or not self.license_valid:
            return {
                'success': False,
                'error': 'MATLAB/Simulink not available or license invalid'
            }

        command_map = {
            'build_model': self._build_model,
            'validate_model': self._validate_model,
            'export_fmu': self._export_fmu,
            'simulate': self._simulate,
            'generate_report': self._generate_report
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

    def _build_model(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build Simulink model and generate code.

        Parameters:
        - model_path: Path to .slx model file
        - output_dir: Output directory for generated code
        - target: 'ert' (default), 'grt', 'autosar'
        - optimization: 'speed', 'rom', 'ram', 'balanced'
        - generate_report: Generate code generation report (bool)
        """
        model_path = self.validate_path(params['model_path'], must_exist=True)
        model_name = model_path.stem
        output_dir = self.ensure_dir(params.get('output_dir', f'{model_name}_build'))
        target = params.get('target', 'ert')
        optimization = params.get('optimization', 'balanced')
        generate_report = params.get('generate_report', True)

        # Create MATLAB script
        script = f"""
        % Auto-generated build script
        modelName = '{model_name}';
        modelPath = '{model_path}';

        % Load model
        load_system(modelPath);

        % Configure for code generation
        set_param(modelName, 'SystemTargetFile', '{target}.tlc');
        set_param(modelName, 'TargetLang', 'C');

        % Optimization
        optimization = '{optimization}';
        if strcmp(optimization, 'speed')
            set_param(modelName, 'OptimizationPriority', 'Speed');
            set_param(modelName, 'OptimizationLevel', 'level2');
        elseif strcmp(optimization, 'rom')
            set_param(modelName, 'OptimizationPriority', 'ROM');
            set_param(modelName, 'OptimizationLevel', 'level2');
        elseif strcmp(optimization, 'ram')
            set_param(modelName, 'OptimizationPriority', 'RAM');
            set_param(modelName, 'LocalBlockOutputs', 'on');
            set_param(modelName, 'BufferReuse', 'on');
        end

        % Report generation
        set_param(modelName, 'GenerateReport', '{'on' if generate_report else 'off'}');
        set_param(modelName, 'LaunchReport', 'off');
        set_param(modelName, 'GenerateCodeMetricsReport', 'on');

        % Build
        try
            slbuild(modelName);
            fprintf('BUILD_SUCCESS\\n');

            % Get metrics
            if exist('slprj/{target}/_sharedutils', 'dir')
                fprintf('Generated code: slprj/{target}\\n');
            end

            exit(0);
        catch ME
            fprintf('BUILD_FAILED: %s\\n', ME.message);
            exit(1);
        end
        """

        script_file = output_dir / 'build_script.m'
        script_file.write_text(script)

        # Execute MATLAB
        self.logger.info(f"Building model: {model_name}")
        result = self.run_subprocess(
            [self.matlab_bin, '-batch', f"run('{script_file}')"],
            cwd=str(output_dir),
            timeout=600  # 10 minutes
        )

        success = 'BUILD_SUCCESS' in result.stdout
        output_code_dir = output_dir / 'slprj' / target

        return {
            'success': success,
            'model_name': model_name,
            'output_dir': str(output_code_dir) if success else None,
            'stdout': result.stdout,
            'stderr': result.stderr,
            'target': target,
            'optimization': optimization
        }

    def _validate_model(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run Model Advisor validation checks.

        Parameters:
        - model_path: Path to .slx model file
        - checks: List of check IDs or 'all'
        - report_path: Path for validation report
        """
        model_path = self.validate_path(params['model_path'], must_exist=True)
        model_name = model_path.stem
        checks = params.get('checks', 'all')
        report_path = params.get('report_path', f'{model_name}_validation_report.html')

        check_config = 'mathworks.design' if checks == 'all' else checks

        script = f"""
        modelName = '{model_name}';
        load_system('{model_path}');

        % Run Model Advisor
        mdladvObj = Simulink.ModelAdvisor.getModelAdvisor(modelName);

        % Configure checks
        mdladvObj.addCheckConfig('{check_config}');

        % Run
        try
            mdladvObj.run();
            mdladvObj.displayReport();

            % Save report
            reportFile = '{report_path}';
            % Copy report to specified location

            fprintf('VALIDATION_SUCCESS\\n');
            exit(0);
        catch ME
            fprintf('VALIDATION_FAILED: %s\\n', ME.message);
            exit(1);
        end
        """

        script_file = Path(f'/tmp/{model_name}_validate.m')
        script_file.write_text(script)

        result = self.run_subprocess(
            [self.matlab_bin, '-batch', f"run('{script_file}')"],
            timeout=300
        )

        success = 'VALIDATION_SUCCESS' in result.stdout

        return {
            'success': success,
            'model_name': model_name,
            'report_path': report_path if success else None,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _export_fmu(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Export Simulink model as FMU.

        Parameters:
        - model_path: Path to .slx model file
        - fmu_type: 'CoSimulation' or 'ModelExchange'
        - fmi_version: '2.0' or '3.0'
        - output_dir: Output directory for FMU
        """
        model_path = self.validate_path(params['model_path'], must_exist=True)
        model_name = model_path.stem
        fmu_type = params.get('fmu_type', 'CoSimulation')
        fmi_version = params.get('fmi_version', '2.0')
        output_dir = self.ensure_dir(params.get('output_dir', 'fmu_export'))

        script = f"""
        modelName = '{model_name}';
        load_system('{model_path}');

        % Configure for FMU export
        set_param(modelName, 'GenerateCoSimulationFMU', 'on');
        set_param(modelName, 'FMUVersion', '{fmi_version}');
        set_param(modelName, 'FMUType', '{fmu_type}');
        set_param(modelName, 'IncludeSourceCode', 'on');

        % Build
        try
            slbuild(modelName);

            % Find generated FMU
            fmuFile = [modelName '.fmu'];
            if exist(fmuFile, 'file')
                copyfile(fmuFile, '{output_dir}');
                fprintf('FMU_EXPORT_SUCCESS\\n');
                fprintf('FMU: %s\\n', fmuFile);
            else
                fprintf('FMU_EXPORT_FAILED: FMU file not found\\n');
            end

            exit(0);
        catch ME
            fprintf('FMU_EXPORT_FAILED: %s\\n', ME.message);
            exit(1);
        end
        """

        script_file = Path(f'/tmp/{model_name}_export_fmu.m')
        script_file.write_text(script)

        result = self.run_subprocess(
            [self.matlab_bin, '-batch', f"run('{script_file}')"],
            timeout=600
        )

        success = 'FMU_EXPORT_SUCCESS' in result.stdout
        fmu_path = output_dir / f'{model_name}.fmu'

        return {
            'success': success,
            'model_name': model_name,
            'fmu_path': str(fmu_path) if success and fmu_path.exists() else None,
            'fmu_type': fmu_type,
            'fmi_version': fmi_version,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _simulate(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run Simulink simulation.

        Parameters:
        - model_path: Path to .slx model file
        - stop_time: Simulation stop time
        - save_output: Save output to MAT file (bool)
        """
        model_path = self.validate_path(params['model_path'], must_exist=True)
        model_name = model_path.stem
        stop_time = params.get('stop_time', 10.0)
        save_output = params.get('save_output', True)

        script = f"""
        modelName = '{model_name}';
        load_system('{model_path}');

        % Configure simulation
        set_param(modelName, 'StopTime', '{stop_time}');

        % Simulate
        try
            simOut = sim(modelName);

            {'save([modelName "_simout.mat"], "simOut");' if save_output else ''}

            fprintf('SIMULATION_SUCCESS\\n');
            exit(0);
        catch ME
            fprintf('SIMULATION_FAILED: %s\\n', ME.message);
            exit(1);
        end
        """

        script_file = Path(f'/tmp/{model_name}_simulate.m')
        script_file.write_text(script)

        result = self.run_subprocess(
            [self.matlab_bin, '-batch', f"run('{script_file}')"],
            timeout=300
        )

        success = 'SIMULATION_SUCCESS' in result.stdout

        return {
            'success': success,
            'model_name': model_name,
            'stop_time': stop_time,
            'output_file': f'{model_name}_simout.mat' if save_output and success else None,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _generate_report(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate code generation report."""
        # Placeholder - report is generated during build
        return {
            'success': True,
            'message': 'Report generation handled by build_model command'
        }

    def get_toolbox_info(self) -> Dict[str, bool]:
        """Check which toolboxes are installed."""
        if not self.is_available or not self.license_valid:
            return {}

        script = """
        toolboxes = ver;
        for i = 1:length(toolboxes)
            fprintf('%s\\n', toolboxes(i).Name);
        end
        exit(0);
        """

        script_file = Path('/tmp/check_toolboxes.m')
        script_file.write_text(script)

        result = self.run_subprocess(
            [self.matlab_bin, '-batch', f"run('{script_file}')"],
            timeout=30
        )

        toolbox_names = result.stdout.strip().split('\n')

        return {
            'Simulink': 'Simulink' in ' '.join(toolbox_names),
            'Embedded Coder': 'Embedded Coder' in ' '.join(toolbox_names),
            'Fixed-Point Designer': 'Fixed-Point Designer' in ' '.join(toolbox_names),
            'Stateflow': 'Stateflow' in ' '.join(toolbox_names),
            'Simulink Coverage': 'Simulink Coverage' in ' '.join(toolbox_names)
        }

"""
Ansys SCADE Adapter for safety-critical Model-Based Development.

Supports:
- SCADE Suite model building
- Qualified code generation (KCG)
- Design verification
- Model coverage analysis
- Certification artifact generation
"""

import os
import subprocess
import json
import shutil
from typing import Dict, List, Optional, Any
from pathlib import Path
import logging

from ..base_adapter import CommercialToolAdapter


class ScadeAdapter(CommercialToolAdapter):
    """Adapter for Ansys SCADE Suite."""

    def __init__(self, scade_root: Optional[str] = None, version: Optional[str] = None):
        """
        Initialize SCADE adapter.

        Args:
            scade_root: Path to SCADE installation (auto-detect if None)
            version: SCADE version (auto-detect if None)
        """
        self.scade_root = scade_root or os.environ.get('SCADE_ROOT', '/opt/ANSYS/SCADE')
        self.scade_bin = None
        super().__init__(name='scade', version=version)

    def _detect(self) -> bool:
        """Detect if SCADE is installed."""
        # Check for scade executable
        scade_paths = [
            os.path.join(self.scade_root, 'bin', 'scade'),
            '/opt/ANSYS/SCADE/bin/scade',
            shutil.which('scade')
        ]

        for scade_path in scade_paths:
            if scade_path and os.path.exists(scade_path):
                self.scade_bin = scade_path
                self.logger.info(f"Found SCADE at: {scade_path}")

                # Try to get version
                try:
                    result = subprocess.run(
                        [self.scade_bin, '-version'],
                        capture_output=True,
                        text=True,
                        timeout=10
                    )
                    if result.returncode == 0:
                        version_line = result.stdout.strip()
                        if 'SCADE' in version_line:
                            parts = version_line.split()
                            if len(parts) > 1:
                                self.version = parts[1]
                            self.logger.info(f"SCADE version: {self.version}")
                except Exception as e:
                    self.logger.warning(f"Could not determine SCADE version: {e}")

                return True

        self.logger.warning("SCADE not found")
        return False

    def _check_license(self) -> bool:
        """Check if SCADE license is valid."""
        if not self.is_available:
            return False

        try:
            # Try to run scade with license check
            result = self.run_subprocess(
                [self.scade_bin, '-check_license'],
                timeout=30
            )

            if result.returncode == 0:
                self.logger.info("SCADE license valid")
                return True
            else:
                self.logger.error("SCADE license check failed")
                return False

        except Exception as e:
            # If license check command doesn't exist, assume available if SCADE found
            self.logger.warning(f"License check inconclusive: {e}")
            return True  # Assume valid if SCADE is installed

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute SCADE command.

        Commands:
        - build_model: Build SCADE model
        - generate_code: Generate qualified code with KCG
        - verify: Run SCADE Design Verifier
        - test_coverage: Analyze model coverage
        - generate_cert: Generate certification artifacts

        Args:
            command: Command name
            parameters: Command parameters

        Returns:
            Dictionary with execution results
        """
        if not self.is_available:
            return {
                'success': False,
                'error': 'SCADE not available'
            }

        if not self.license_valid:
            return {
                'success': False,
                'error': 'SCADE license invalid'
            }

        command_map = {
            'build_model': self._build_model,
            'generate_code': self._generate_code,
            'verify': self._verify,
            'test_coverage': self._test_coverage,
            'generate_cert': self._generate_cert
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
        Build SCADE model.

        Parameters:
        - project_file: Path to .etp project file
        - configuration: Build configuration
        """
        project_file = self.validate_path(params['project_file'], must_exist=True)
        configuration = params.get('configuration', 'Debug')

        self.logger.info(f"Building SCADE project: {project_file}")
        result = self.run_subprocess(
            [
                self.scade_bin,
                '-build',
                str(project_file),
                '-conf', configuration
            ],
            timeout=600
        )

        success = result.returncode == 0

        return {
            'success': success,
            'project': str(project_file),
            'configuration': configuration,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _generate_code(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate qualified code with SCADE KCG.

        Parameters:
        - project_file: Path to .etp project file
        - node: Root node name
        - target: Target language ('C', 'Ada')
        - standard: Safety standard ('ISO26262', 'DO178C')
        - asil_level: ASIL level ('ASIL_A', 'ASIL_B', 'ASIL_C', 'ASIL_D')
        - optimization: Optimization goal ('none', 'speed', 'rom', 'ram')
        - output_dir: Output directory for generated code
        """
        project_file = self.validate_path(params['project_file'], must_exist=True)
        node = params['node']
        target = params.get('target', 'C')
        standard = params.get('standard', 'ISO26262')
        asil_level = params.get('asil_level', 'ASIL_D')
        optimization = params.get('optimization', 'none')
        output_dir = self.ensure_dir(params.get('output_dir', 'scade_code_gen'))

        self.logger.info(f"Generating qualified code for: {node}")

        # Build command
        cmd = [
            self.scade_bin,
            '-code',
            str(project_file),
            '-node', node,
            '-outdir', str(output_dir),
            '-target', target,
            '-qual', standard,
            '-opt', optimization,
            '-metrics',
            '-traceability'
        ]

        if standard == 'ISO26262':
            cmd.extend(['-asil', asil_level])

        result = self.run_subprocess(cmd, timeout=600)

        success = result.returncode == 0

        # Find generated files
        generated_files = []
        if success:
            generated_files = list(output_dir.glob(f'*.{target.lower()}'))

        return {
            'success': success,
            'node': node,
            'target': target,
            'standard': standard,
            'asil_level': asil_level,
            'output_dir': str(output_dir),
            'generated_files': [str(f) for f in generated_files],
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _verify(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run SCADE Design Verifier (formal verification).

        Parameters:
        - project_file: Path to .etp project file
        - node: Node to verify
        - proof_level: Proof level ('auto', 'manual')
        - report_path: Path for verification report
        """
        project_file = self.validate_path(params['project_file'], must_exist=True)
        node = params['node']
        proof_level = params.get('proof_level', 'auto')
        report_path = params.get('report_path', 'verification_report.html')

        self.logger.info(f"Running Design Verifier for: {node}")

        result = self.run_subprocess(
            [
                self.scade_bin,
                '-verif',
                str(project_file),
                '-node', node,
                '-proof', proof_level,
                '-report', report_path
            ],
            timeout=1800  # 30 minutes
        )

        success = result.returncode == 0

        # Parse verification results
        verified_properties = 0
        failed_properties = 0

        if success and os.path.exists(report_path):
            # Parse report (simplified - actual parsing would be more complex)
            with open(report_path, 'r') as f:
                content = f.read()
                verified_properties = content.count('VERIFIED')
                failed_properties = content.count('FAILED')

        return {
            'success': success,
            'node': node,
            'verified_properties': verified_properties,
            'failed_properties': failed_properties,
            'report_path': report_path if success else None,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _test_coverage(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze model coverage.

        Parameters:
        - project_file: Path to .etp project file
        - node: Node to analyze
        - coverage_type: 'mcdc', 'decision', 'statement'
        - output_dir: Output directory for test procedures
        """
        project_file = self.validate_path(params['project_file'], must_exist=True)
        node = params['node']
        coverage_type = params.get('coverage_type', 'mcdc')
        output_dir = self.ensure_dir(params.get('output_dir', 'test_procedures'))

        self.logger.info(f"Generating {coverage_type.upper()} coverage for: {node}")

        result = self.run_subprocess(
            [
                self.scade_bin,
                '-test',
                str(project_file),
                '-node', node,
                '-coverage', coverage_type,
                '-outdir', str(output_dir)
            ],
            timeout=600
        )

        success = result.returncode == 0

        return {
            'success': success,
            'node': node,
            'coverage_type': coverage_type,
            'output_dir': str(output_dir),
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def _generate_cert(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Generate certification artifacts (qualification kit).

        Parameters:
        - project_file: Path to .etp project file
        - standard: Safety standard ('ISO26262', 'DO178C')
        - asil_level: ASIL level or DAL level
        - output_dir: Output directory for certification docs
        """
        project_file = self.validate_path(params['project_file'], must_exist=True)
        standard = params['standard']
        asil_level = params.get('asil_level', 'ASIL_D')
        output_dir = self.ensure_dir(params.get('output_dir', 'certification_artifacts'))

        self.logger.info(f"Generating {standard} certification artifacts")

        result = self.run_subprocess(
            [
                self.scade_bin,
                '-qualkit',
                '-standard', standard,
                '-asil', asil_level,
                '-output', str(output_dir)
            ],
            timeout=300
        )

        success = result.returncode == 0

        # List generated artifacts
        artifacts = []
        if success:
            artifacts = [str(f) for f in output_dir.glob('**/*') if f.is_file()]

        return {
            'success': success,
            'standard': standard,
            'asil_level': asil_level,
            'output_dir': str(output_dir),
            'artifacts': artifacts,
            'stdout': result.stdout,
            'stderr': result.stderr
        }

    def check_misra_compliance(self, code_dir: str) -> Dict[str, Any]:
        """
        Check generated code for MISRA compliance.

        Args:
            code_dir: Directory containing generated C code

        Returns:
            MISRA compliance results
        """
        code_path = self.validate_path(code_dir, must_exist=True)

        # Use SCADE built-in MISRA checker if available
        result = self.run_subprocess(
            [
                self.scade_bin,
                '-misra',
                str(code_path),
                '-report', 'misra_report.xml'
            ],
            timeout=300
        )

        success = result.returncode == 0

        violations = 0
        if success and os.path.exists('misra_report.xml'):
            # Parse XML for violation count (simplified)
            with open('misra_report.xml', 'r') as f:
                content = f.read()
                violations = content.count('<violation>')

        return {
            'success': success,
            'violations': violations,
            'compliant': violations == 0,
            'report': 'misra_report.xml' if success else None
        }

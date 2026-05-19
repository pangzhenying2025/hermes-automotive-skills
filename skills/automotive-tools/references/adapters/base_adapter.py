"""
Base Tool Adapter for Automotive Claude Code Platform.

This module provides the abstract base class for all tool adapters,
enabling unified interface across 300+ commercial and opensource tools.
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
import subprocess
import os
import logging
from pathlib import Path


class BaseToolAdapter(ABC):
    """Abstract base class for all automotive tool adapters."""

    def __init__(self, name: str, version: Optional[str] = None):
        """
        Initialize the tool adapter.

        Args:
            name: Tool name (e.g., 'tresos', 'arctic-core', 'gcc-arm')
            version: Tool version (auto-detected if None)
        """
        self.name = name
        self.version = version
        self.logger = logging.getLogger(f"adapter.{name}")
        self.is_available = self._detect()
        self.license_valid = self._check_license() if self.is_available else False

    @abstractmethod
    def _detect(self) -> bool:
        """
        Detect if the tool is installed on the system.

        Returns:
            True if tool is available, False otherwise
        """
        pass

    @abstractmethod
    def _check_license(self) -> bool:
        """
        Check if commercial license is valid.

        For opensource tools, this should always return True.

        Returns:
            True if license is valid or tool is opensource
        """
        pass

    @abstractmethod
    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a tool command with parameters.

        Args:
            command: Command name (e.g., 'generate_swc', 'calibrate')
            parameters: Command parameters

        Returns:
            Dictionary containing:
                - success: bool
                - output_dir: Optional[str]
                - stdout: str
                - stderr: str
                - additional tool-specific results
        """
        pass

    def get_info(self) -> Dict[str, Any]:
        """
        Get tool information.

        Returns:
            Dictionary with tool metadata
        """
        return {
            "name": self.name,
            "version": self.version or "unknown",
            "available": self.is_available,
            "license_valid": self.license_valid,
            "type": "opensource" if self.is_opensource else "commercial"
        }

    @property
    @abstractmethod
    def is_opensource(self) -> bool:
        """
        Check if this is an opensource tool.

        Returns:
            True if opensource, False if commercial
        """
        pass

    def run_subprocess(
        self,
        cmd: List[str],
        cwd: Optional[str] = None,
        timeout: Optional[int] = 300,
        **kwargs
    ) -> subprocess.CompletedProcess:
        """
        Run subprocess with common error handling.

        Args:
            cmd: Command and arguments as list
            cwd: Working directory
            timeout: Timeout in seconds (default: 300)
            **kwargs: Additional subprocess.run parameters

        Returns:
            CompletedProcess instance

        Raises:
            subprocess.TimeoutExpired: If command exceeds timeout
            subprocess.CalledProcessError: If command fails
        """
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=cwd,
                timeout=timeout,
                **kwargs
            )

            if result.returncode != 0:
                self.logger.error(f"Command failed: {' '.join(cmd)}")
                self.logger.error(f"Return code: {result.returncode}")
                self.logger.error(f"stderr: {result.stderr}")
            else:
                self.logger.info(f"Command succeeded: {' '.join(cmd)}")

            return result

        except subprocess.TimeoutExpired as e:
            self.logger.error(f"Command timed out after {timeout}s: {' '.join(cmd)}")
            raise
        except Exception as e:
            self.logger.exception(f"Exception running command: {' '.join(cmd)}")
            raise

    def validate_path(self, path: str, must_exist: bool = False) -> Path:
        """
        Validate and convert path string to Path object.

        Args:
            path: Path string
            must_exist: If True, raise error if path doesn't exist

        Returns:
            Path object

        Raises:
            FileNotFoundError: If must_exist=True and path doesn't exist
            ValueError: If path is invalid
        """
        try:
            p = Path(path).resolve()
            if must_exist and not p.exists():
                raise FileNotFoundError(f"Path does not exist: {path}")
            return p
        except Exception as e:
            raise ValueError(f"Invalid path: {path}") from e

    def ensure_dir(self, path: str) -> Path:
        """
        Ensure directory exists, create if necessary.

        Args:
            path: Directory path

        Returns:
            Path object
        """
        p = Path(path)
        p.mkdir(parents=True, exist_ok=True)
        return p


class OpensourceToolAdapter(BaseToolAdapter):
    """Base class for opensource tool adapters."""

    @property
    def is_opensource(self) -> bool:
        return True

    def _check_license(self) -> bool:
        """Opensource tools always have valid license."""
        return True


class CommercialToolAdapter(BaseToolAdapter):
    """Base class for commercial tool adapters."""

    @property
    def is_opensource(self) -> bool:
        return False

    @abstractmethod
    def _check_license(self) -> bool:
        """Must implement license checking for commercial tools."""
        pass

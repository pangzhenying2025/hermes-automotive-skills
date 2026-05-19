"""
Tool Installation Module.

Automated installation of opensource automotive tools with dependency resolution.
"""

from .opensource_installer import OpensourceInstaller, InstallResult
from .dependency_resolver import DependencyResolver, ResolvedDependency, Dependency

__all__ = [
    'OpensourceInstaller',
    'InstallResult',
    'DependencyResolver',
    'ResolvedDependency',
    'Dependency',
]

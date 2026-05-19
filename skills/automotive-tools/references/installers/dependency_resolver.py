"""
Dependency Resolver for Automotive Tool Installation.

Resolves and installs dependencies for automotive development tools:
- System package dependencies
- Python package dependencies
- Compiler/toolchain dependencies
- Library dependencies
- Circular dependency detection
- Version conflict resolution
- Topological sorting for install order
"""

import os
import sys
import subprocess
from typing import Dict, List, Optional, Set, Tuple, Any
from dataclasses import dataclass, field
from collections import defaultdict, deque
import logging
import json

logger = logging.getLogger(__name__)


@dataclass
class Dependency:
    """Represents a tool dependency."""
    name: str
    version_spec: Optional[str] = None
    package_manager: Optional[str] = None
    optional: bool = False
    alternatives: List[str] = field(default_factory=list)


@dataclass
class ResolvedDependency:
    """Resolved dependency with installation info."""
    name: str
    version: Optional[str]
    satisfied: bool
    install_method: Optional[str]
    install_command: Optional[List[str]]
    error: Optional[str]


class DependencyResolver:
    """Resolves dependencies for tool installation."""

    # Dependency database
    DEPENDENCY_DB = {
        # Build tools
        "cmake": {
            "system_deps": [],
            "min_version": "3.10"
        },
        "make": {
            "system_deps": [],
            "alternatives": ["gmake", "ninja"]
        },
        "gcc": {
            "system_deps": ["binutils"],
            "alternatives": ["clang"]
        },
        "g++": {
            "system_deps": ["gcc", "binutils"],
            "alternatives": ["clang++"]
        },
        "clang": {
            "system_deps": ["llvm"],
            "alternatives": ["gcc"]
        },

        # Python tools
        "python3": {
            "system_deps": [],
            "min_version": "3.8",
            "package_names": {
                "apt": "python3",
                "yum": "python3",
                "brew": "python@3"
            }
        },
        "pip": {
            "system_deps": ["python3"],
            "package_names": {
                "apt": "python3-pip",
                "yum": "python3-pip",
                "brew": "pip"
            }
        },

        # Version control
        "git": {
            "system_deps": [],
            "min_version": "2.0"
        },
        "svn": {
            "system_deps": [],
            "alternatives": ["git"]
        },

        # Libraries
        "libusb": {
            "system_deps": [],
            "package_names": {
                "apt": "libusb-1.0-0-dev",
                "yum": "libusb-devel",
                "brew": "libusb"
            }
        },
        "libssl": {
            "system_deps": [],
            "package_names": {
                "apt": "libssl-dev",
                "yum": "openssl-devel",
                "brew": "openssl"
            }
        },

        # Automotive specific
        "can-utils": {
            "system_deps": [],
            "package_names": {
                "apt": "can-utils",
                "yum": "can-utils"
            }
        },

        # Java
        "java": {
            "system_deps": [],
            "min_version": "11",
            "package_names": {
                "apt": "openjdk-11-jdk",
                "yum": "java-11-openjdk-devel",
                "brew": "openjdk@11"
            }
        },

        # Rust
        "cargo": {
            "system_deps": ["rustc"],
            "install_script": "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        },
        "rustc": {
            "system_deps": [],
            "install_script": "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        },

        # Debugging
        "gdb": {
            "system_deps": [],
            "alternatives": ["lldb"]
        },
        "valgrind": {
            "system_deps": []
        },

        # Documentation
        "doxygen": {
            "system_deps": []
        },
        "graphviz": {
            "system_deps": []
        }
    }

    def __init__(self, package_manager: Optional[str] = None):
        """
        Initialize dependency resolver.

        Args:
            package_manager: System package manager (auto-detected if None)
        """
        self.package_manager = package_manager or self._detect_package_manager()
        self.installed_cache: Dict[str, bool] = {}
        self.version_cache: Dict[str, Optional[str]] = {}

    def _detect_package_manager(self) -> Optional[str]:
        """Detect system package manager."""
        import shutil

        managers = ["apt", "yum", "dnf", "brew", "pacman", "zypper"]

        for manager in managers:
            if shutil.which(manager):
                logger.info(f"Detected package manager: {manager}")
                return manager

        logger.warning("No package manager detected")
        return None

    def resolve_dependencies(
        self,
        tool_name: str,
        dependencies: List[str]
    ) -> Tuple[List[ResolvedDependency], List[str]]:
        """
        Resolve all dependencies for a tool.

        Args:
            tool_name: Tool requiring dependencies
            dependencies: List of dependency names

        Returns:
            Tuple of (resolved_dependencies, install_order)
        """
        logger.info(f"Resolving dependencies for {tool_name}")

        # Build dependency graph
        dep_graph = self._build_dependency_graph(dependencies)

        # Check for circular dependencies
        if self._has_circular_dependencies(dep_graph):
            logger.error("Circular dependencies detected")
            raise ValueError("Circular dependencies detected")

        # Get installation order via topological sort
        install_order = self._topological_sort(dep_graph)

        # Resolve each dependency
        resolved = []
        for dep_name in install_order:
            resolved_dep = self._resolve_dependency(dep_name)
            resolved.append(resolved_dep)

        return resolved, install_order

    def _build_dependency_graph(
        self,
        dependencies: List[str]
    ) -> Dict[str, List[str]]:
        """
        Build dependency graph.

        Args:
            dependencies: Initial dependencies

        Returns:
            Graph mapping dependency to its dependencies
        """
        graph: Dict[str, List[str]] = defaultdict(list)
        visited: Set[str] = set()

        def visit(dep: str):
            if dep in visited:
                return
            visited.add(dep)

            # Get dependency info from database
            dep_info = self.DEPENDENCY_DB.get(dep, {})
            system_deps = dep_info.get("system_deps", [])

            graph[dep] = system_deps

            # Recursively visit dependencies
            for system_dep in system_deps:
                visit(system_dep)

        # Visit all initial dependencies
        for dep in dependencies:
            visit(dep)

        return dict(graph)

    def _has_circular_dependencies(
        self,
        graph: Dict[str, List[str]]
    ) -> bool:
        """
        Check for circular dependencies using DFS.

        Args:
            graph: Dependency graph

        Returns:
            True if circular dependencies exist
        """
        WHITE, GRAY, BLACK = 0, 1, 2
        colors: Dict[str, int] = {node: WHITE for node in graph}

        def visit(node: str) -> bool:
            colors[node] = GRAY

            for neighbor in graph.get(node, []):
                if colors.get(neighbor, WHITE) == GRAY:
                    return True  # Back edge = cycle
                if colors.get(neighbor, WHITE) == WHITE:
                    if visit(neighbor):
                        return True

            colors[node] = BLACK
            return False

        for node in graph:
            if colors[node] == WHITE:
                if visit(node):
                    return True

        return False

    def _topological_sort(
        self,
        graph: Dict[str, List[str]]
    ) -> List[str]:
        """
        Topological sort for installation order.

        Args:
            graph: Dependency graph

        Returns:
            List of dependencies in installation order
        """
        in_degree: Dict[str, int] = defaultdict(int)
        adj_list: Dict[str, List[str]] = defaultdict(list)

        # Build adjacency list and in-degree counts
        for node, deps in graph.items():
            if node not in in_degree:
                in_degree[node] = 0
            for dep in deps:
                adj_list[dep].append(node)
                in_degree[node] += 1

        # Find all nodes with in-degree 0
        queue = deque([node for node in graph if in_degree[node] == 0])
        result = []

        while queue:
            node = queue.popleft()
            result.append(node)

            # Reduce in-degree for neighbors
            for neighbor in adj_list[node]:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)

        return result

    def _resolve_dependency(self, dep_name: str) -> ResolvedDependency:
        """
        Resolve a single dependency.

        Args:
            dep_name: Dependency name

        Returns:
            ResolvedDependency object
        """
        # Check if already installed
        if self._is_installed(dep_name):
            version = self._get_version(dep_name)
            return ResolvedDependency(
                name=dep_name,
                version=version,
                satisfied=True,
                install_method="already_installed",
                install_command=None,
                error=None
            )

        # Get dependency info
        dep_info = self.DEPENDENCY_DB.get(dep_name, {})

        # Check for install script
        if "install_script" in dep_info:
            return ResolvedDependency(
                name=dep_name,
                version=None,
                satisfied=False,
                install_method="script",
                install_command=["bash", "-c", dep_info["install_script"]],
                error=None
            )

        # Get package name for current package manager
        package_names = dep_info.get("package_names", {})
        package_name = package_names.get(self.package_manager, dep_name)

        # Build install command
        install_cmd = self._build_install_command(package_name)

        return ResolvedDependency(
            name=dep_name,
            version=None,
            satisfied=False,
            install_method=self.package_manager,
            install_command=install_cmd,
            error=None
        )

    def _is_installed(self, tool: str) -> bool:
        """
        Check if a tool is installed.

        Args:
            tool: Tool name

        Returns:
            True if installed
        """
        # Check cache
        if tool in self.installed_cache:
            return self.installed_cache[tool]

        import shutil

        # Check if in PATH
        result = shutil.which(tool) is not None

        # Check package manager
        if not result and self.package_manager:
            result = self._check_package_installed(tool)

        self.installed_cache[tool] = result
        return result

    def _check_package_installed(self, package: str) -> bool:
        """Check if package is installed via package manager."""
        commands = {
            "apt": ["dpkg", "-l", package],
            "yum": ["rpm", "-q", package],
            "dnf": ["rpm", "-q", package],
            "brew": ["brew", "list", package],
            "pacman": ["pacman", "-Q", package]
        }

        if self.package_manager not in commands:
            return False

        try:
            result = subprocess.run(
                commands[self.package_manager],
                capture_output=True,
                timeout=10
            )
            return result.returncode == 0
        except:
            return False

    def _get_version(self, tool: str) -> Optional[str]:
        """
        Get version of installed tool.

        Args:
            tool: Tool name

        Returns:
            Version string or None
        """
        # Check cache
        if tool in self.version_cache:
            return self.version_cache[tool]

        version_flags = ["--version", "-version", "version", "-v"]

        for flag in version_flags:
            try:
                result = subprocess.run(
                    [tool, flag],
                    capture_output=True,
                    text=True,
                    timeout=5
                )

                if result.returncode == 0:
                    version = self._parse_version(result.stdout + result.stderr)
                    self.version_cache[tool] = version
                    return version
            except:
                continue

        self.version_cache[tool] = None
        return None

    def _parse_version(self, output: str) -> Optional[str]:
        """Parse version from command output."""
        import re
        patterns = [
            r"(\d+\.\d+\.\d+)",
            r"version\s+(\d+\.\d+)",
            r"v(\d+\.\d+)"
        ]

        for pattern in patterns:
            match = re.search(pattern, output, re.IGNORECASE)
            if match:
                return match.group(1)

        return None

    def _build_install_command(self, package: str) -> List[str]:
        """Build installation command for package."""
        commands = {
            "apt": ["sudo", "apt-get", "install", "-y", package],
            "yum": ["sudo", "yum", "install", "-y", package],
            "dnf": ["sudo", "dnf", "install", "-y", package],
            "brew": ["brew", "install", package],
            "pacman": ["sudo", "pacman", "-S", "--noconfirm", package]
        }

        return commands.get(
            self.package_manager,
            ["echo", f"Cannot install {package}: unknown package manager"]
        )

    def install_dependencies(
        self,
        resolved_deps: List[ResolvedDependency]
    ) -> Dict[str, bool]:
        """
        Install all resolved dependencies.

        Args:
            resolved_deps: List of resolved dependencies

        Returns:
            Dictionary mapping dependency name to success status
        """
        results = {}

        for dep in resolved_deps:
            if dep.satisfied:
                logger.info(f"{dep.name} already satisfied")
                results[dep.name] = True
                continue

            if not dep.install_command:
                logger.warning(f"No install command for {dep.name}")
                results[dep.name] = False
                continue

            logger.info(f"Installing {dep.name} via {dep.install_method}")

            try:
                result = subprocess.run(
                    dep.install_command,
                    capture_output=True,
                    text=True,
                    timeout=300
                )

                success = result.returncode == 0
                results[dep.name] = success

                if not success:
                    logger.error(f"Failed to install {dep.name}: {result.stderr}")
                else:
                    logger.info(f"Successfully installed {dep.name}")

            except subprocess.TimeoutExpired:
                logger.error(f"Timeout installing {dep.name}")
                results[dep.name] = False
            except Exception as e:
                logger.exception(f"Error installing {dep.name}")
                results[dep.name] = False

        return results

    def check_version_compatibility(
        self,
        tool: str,
        min_version: str
    ) -> bool:
        """
        Check if installed version meets minimum requirement.

        Args:
            tool: Tool name
            min_version: Minimum version required

        Returns:
            True if compatible
        """
        installed_version = self._get_version(tool)
        if not installed_version:
            return False

        return self._compare_versions(installed_version, min_version) >= 0

    def _compare_versions(self, version1: str, version2: str) -> int:
        """
        Compare two version strings.

        Args:
            version1: First version
            version2: Second version

        Returns:
            -1 if version1 < version2, 0 if equal, 1 if version1 > version2
        """
        def normalize(v):
            return [int(x) for x in v.split('.')]

        v1_parts = normalize(version1)
        v2_parts = normalize(version2)

        # Pad shorter version with zeros
        max_len = max(len(v1_parts), len(v2_parts))
        v1_parts += [0] * (max_len - len(v1_parts))
        v2_parts += [0] * (max_len - len(v2_parts))

        for v1, v2 in zip(v1_parts, v2_parts):
            if v1 < v2:
                return -1
            elif v1 > v2:
                return 1

        return 0

    def export_dependency_report(
        self,
        tool_name: str,
        resolved_deps: List[ResolvedDependency],
        install_order: List[str],
        output_path: str
    ) -> None:
        """
        Export dependency resolution report.

        Args:
            tool_name: Tool name
            resolved_deps: Resolved dependencies
            install_order: Installation order
            output_path: Output file path
        """
        data = {
            "tool": tool_name,
            "install_order": install_order,
            "dependencies": [
                {
                    "name": dep.name,
                    "version": dep.version,
                    "satisfied": dep.satisfied,
                    "install_method": dep.install_method,
                    "install_command": dep.install_command,
                    "error": dep.error
                }
                for dep in resolved_deps
            ]
        }

        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)

        logger.info(f"Dependency report exported to {output_path}")


def main():
    """Main entry point."""
    logging.basicConfig(level=logging.INFO)

    resolver = DependencyResolver()

    # Example: Resolve dependencies for Arctic Core
    dependencies = ["cmake", "gcc", "g++", "make", "git"]

    print(f"\n=== Resolving Dependencies ===")
    resolved, install_order = resolver.resolve_dependencies("arctic-core", dependencies)

    print(f"\nInstallation order: {' -> '.join(install_order)}")

    print("\nDependency status:")
    for dep in resolved:
        status = "✓" if dep.satisfied else "✗"
        print(f"{status} {dep.name}")
        if dep.version:
            print(f"  Version: {dep.version}")
        if not dep.satisfied and dep.install_command:
            print(f"  Install: {' '.join(dep.install_command)}")

    # Install unsatisfied dependencies
    unsatisfied = [dep for dep in resolved if not dep.satisfied]
    if unsatisfied:
        print(f"\n=== Installing {len(unsatisfied)} Dependencies ===")
        results = resolver.install_dependencies(unsatisfied)

        for name, success in results.items():
            status = "✓" if success else "✗"
            print(f"{status} {name}")


if __name__ == "__main__":
    main()

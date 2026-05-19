"""
Helm adapter for Kubernetes package management.

Provides programmatic access to Helm for automotive application deployment.
"""

import subprocess
import json
import yaml
from typing import Dict, List, Optional, Any
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class HelmAdapter:
    """Adapter for Helm CLI operations."""

    def __init__(
        self,
        kubeconfig: Optional[str] = None,
        namespace: str = "default",
        helm_binary: str = "helm"
    ):
        """
        Initialize Helm adapter.

        Args:
            kubeconfig: Path to kubeconfig file
            namespace: Default namespace
            helm_binary: Path to helm binary
        """
        self.kubeconfig = kubeconfig
        self.namespace = namespace
        self.helm_binary = helm_binary

    def _build_command(self, *args: str, namespace: Optional[str] = None) -> List[str]:
        """Build helm command with common options."""
        cmd = [self.helm_binary]

        if self.kubeconfig:
            cmd.extend(["--kubeconfig", self.kubeconfig])

        ns = namespace or self.namespace
        if ns:
            cmd.extend(["-n", ns])

        cmd.extend(args)
        return cmd

    def _execute(
        self,
        *args: str,
        capture_output: bool = True,
        check: bool = True,
        **kwargs
    ) -> subprocess.CompletedProcess:
        """Execute helm command."""
        cmd = self._build_command(*args, **kwargs)
        logger.debug(f"Executing: {' '.join(cmd)}")

        result = subprocess.run(
            cmd,
            capture_output=capture_output,
            text=True,
            check=check
        )

        return result

    def install(
        self,
        release_name: str,
        chart: str,
        namespace: Optional[str] = None,
        values: Optional[Dict[str, Any]] = None,
        values_file: Optional[str] = None,
        version: Optional[str] = None,
        create_namespace: bool = True,
        wait: bool = True,
        timeout: str = "5m",
        dry_run: bool = False
    ) -> Dict[str, Any]:
        """
        Install Helm chart.

        Args:
            release_name: Name for the release
            chart: Chart reference
            namespace: Target namespace
            values: Values dict
            values_file: Path to values file
            version: Chart version
            create_namespace: Create namespace if not exists
            wait: Wait for completion
            timeout: Timeout duration
            dry_run: Perform dry run

        Returns:
            Release information
        """
        args = ["install", release_name, chart, "-o", "json"]

        if version:
            args.extend(["--version", version])

        if values_file:
            args.extend(["-f", values_file])

        if values:
            # Write values to temporary file
            import tempfile
            with tempfile.NamedTemporaryFile(
                mode='w',
                suffix='.yaml',
                delete=False
            ) as f:
                yaml.dump(values, f)
                args.extend(["-f", f.name])

        if create_namespace:
            args.append("--create-namespace")

        if wait:
            args.extend(["--wait", f"--timeout={timeout}"])

        if dry_run:
            args.append("--dry-run")

        result = self._execute(*args, namespace=namespace)
        return json.loads(result.stdout) if result.stdout else {}

    def upgrade(
        self,
        release_name: str,
        chart: str,
        namespace: Optional[str] = None,
        values: Optional[Dict[str, Any]] = None,
        values_file: Optional[str] = None,
        version: Optional[str] = None,
        install: bool = True,
        wait: bool = True,
        timeout: str = "5m",
        atomic: bool = False,
        force: bool = False
    ) -> Dict[str, Any]:
        """
        Upgrade Helm release.

        Args:
            release_name: Release name
            chart: Chart reference
            namespace: Namespace
            values: Values dict
            values_file: Values file path
            version: Chart version
            install: Install if not exists
            wait: Wait for completion
            timeout: Timeout duration
            atomic: Rollback on failure
            force: Force resource updates

        Returns:
            Release information
        """
        args = ["upgrade", release_name, chart, "-o", "json"]

        if version:
            args.extend(["--version", version])

        if values_file:
            args.extend(["-f", values_file])

        if values:
            import tempfile
            with tempfile.NamedTemporaryFile(
                mode='w',
                suffix='.yaml',
                delete=False
            ) as f:
                yaml.dump(values, f)
                args.extend(["-f", f.name])

        if install:
            args.append("--install")

        if wait:
            args.extend(["--wait", f"--timeout={timeout}"])

        if atomic:
            args.append("--atomic")

        if force:
            args.append("--force")

        result = self._execute(*args, namespace=namespace)
        return json.loads(result.stdout) if result.stdout else {}

    def uninstall(
        self,
        release_name: str,
        namespace: Optional[str] = None,
        wait: bool = True,
        timeout: str = "5m",
        keep_history: bool = False
    ) -> bool:
        """
        Uninstall Helm release.

        Args:
            release_name: Release name
            namespace: Namespace
            wait: Wait for completion
            timeout: Timeout duration
            keep_history: Keep release history

        Returns:
            True if successful
        """
        args = ["uninstall", release_name]

        if wait:
            args.extend(["--wait", f"--timeout={timeout}"])

        if keep_history:
            args.append("--keep-history")

        self._execute(*args, namespace=namespace)
        return True

    def list(
        self,
        namespace: Optional[str] = None,
        all_namespaces: bool = False,
        filter_status: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        List Helm releases.

        Args:
            namespace: Namespace
            all_namespaces: List across all namespaces
            filter_status: Filter by status (deployed, failed, pending, etc.)

        Returns:
            List of releases
        """
        args = ["list", "-o", "json"]

        if all_namespaces:
            args.append("-A")

        if filter_status:
            args.extend(["--filter", filter_status])

        result = self._execute(*args, namespace=namespace)
        return json.loads(result.stdout) if result.stdout else []

    def status(
        self,
        release_name: str,
        namespace: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get release status.

        Args:
            release_name: Release name
            namespace: Namespace

        Returns:
            Status information
        """
        result = self._execute(
            "status",
            release_name,
            "-o",
            "json",
            namespace=namespace
        )
        return json.loads(result.stdout) if result.stdout else {}

    def rollback(
        self,
        release_name: str,
        revision: Optional[int] = None,
        namespace: Optional[str] = None,
        wait: bool = True,
        timeout: str = "5m"
    ) -> bool:
        """
        Rollback release.

        Args:
            release_name: Release name
            revision: Target revision (0 for previous)
            namespace: Namespace
            wait: Wait for completion
            timeout: Timeout duration

        Returns:
            True if successful
        """
        args = ["rollback", release_name]

        if revision:
            args.append(str(revision))

        if wait:
            args.extend(["--wait", f"--timeout={timeout}"])

        self._execute(*args, namespace=namespace)
        return True

    def test(
        self,
        release_name: str,
        namespace: Optional[str] = None,
        timeout: str = "5m"
    ) -> str:
        """
        Run release tests.

        Args:
            release_name: Release name
            namespace: Namespace
            timeout: Timeout duration

        Returns:
            Test output
        """
        result = self._execute(
            "test",
            release_name,
            f"--timeout={timeout}",
            namespace=namespace
        )
        return result.stdout

    def get_values(
        self,
        release_name: str,
        namespace: Optional[str] = None,
        all_values: bool = False
    ) -> Dict[str, Any]:
        """
        Get release values.

        Args:
            release_name: Release name
            namespace: Namespace
            all_values: Include computed values

        Returns:
            Values dict
        """
        args = ["get", "values", release_name, "-o", "json"]

        if all_values:
            args.append("--all")

        result = self._execute(*args, namespace=namespace)
        return json.loads(result.stdout) if result.stdout else {}

    def template(
        self,
        chart: str,
        release_name: Optional[str] = None,
        namespace: Optional[str] = None,
        values: Optional[Dict[str, Any]] = None,
        values_file: Optional[str] = None,
        show_only: Optional[List[str]] = None
    ) -> str:
        """
        Render chart templates locally.

        Args:
            chart: Chart reference
            release_name: Release name
            namespace: Namespace
            values: Values dict
            values_file: Values file path
            show_only: Only show specific templates

        Returns:
            Rendered manifests
        """
        args = ["template"]

        if release_name:
            args.append(release_name)

        args.append(chart)

        if values_file:
            args.extend(["-f", values_file])

        if values:
            import tempfile
            with tempfile.NamedTemporaryFile(
                mode='w',
                suffix='.yaml',
                delete=False
            ) as f:
                yaml.dump(values, f)
                args.extend(["-f", f.name])

        if show_only:
            for template in show_only:
                args.extend(["-s", template])

        result = self._execute(*args, namespace=namespace)
        return result.stdout

    def create_chart(
        self,
        name: str,
        output_dir: str = "."
    ) -> Path:
        """
        Create new chart.

        Args:
            name: Chart name
            output_dir: Output directory

        Returns:
            Path to created chart
        """
        self._execute("create", name, "--starter", output_dir)
        return Path(output_dir) / name

    def package_chart(
        self,
        chart_path: str,
        destination: str = ".",
        version: Optional[str] = None
    ) -> str:
        """
        Package chart.

        Args:
            chart_path: Path to chart
            destination: Destination directory
            version: Chart version override

        Returns:
            Path to packaged chart
        """
        args = ["package", chart_path, "-d", destination]

        if version:
            args.extend(["--version", version])

        result = self._execute(*args)

        # Extract package name from output
        output = result.stdout.strip()
        return output.split(": ")[-1] if ": " in output else ""

    def lint(
        self,
        chart_path: str,
        values_file: Optional[str] = None,
        strict: bool = False
    ) -> bool:
        """
        Lint chart.

        Args:
            chart_path: Path to chart
            values_file: Values file for linting
            strict: Fail on warnings

        Returns:
            True if lint passes
        """
        args = ["lint", chart_path]

        if values_file:
            args.extend(["-f", values_file])

        if strict:
            args.append("--strict")

        try:
            self._execute(*args)
            return True
        except subprocess.CalledProcessError:
            return False

    def repo_add(
        self,
        name: str,
        url: str,
        username: Optional[str] = None,
        password: Optional[str] = None
    ) -> bool:
        """
        Add chart repository.

        Args:
            name: Repository name
            url: Repository URL
            username: Username for authentication
            password: Password for authentication

        Returns:
            True if successful
        """
        args = ["repo", "add", name, url]

        if username:
            args.extend(["--username", username])

        if password:
            args.extend(["--password", password])

        self._execute(*args)
        return True

    def repo_update(self) -> bool:
        """Update repository index."""
        self._execute("repo", "update")
        return True

    def repo_list(self) -> List[Dict[str, str]]:
        """List repositories."""
        result = self._execute("repo", "list", "-o", "json")
        return json.loads(result.stdout) if result.stdout else []


# Automotive-specific helper functions

def deploy_automotive_fleet(
    adapter: HelmAdapter,
    chart_name: str,
    environments: List[str],
    base_values: Dict[str, Any],
    repo_url: str
) -> Dict[str, Any]:
    """
    Deploy automotive application across fleet environments.

    Args:
        adapter: Helm adapter instance
        chart_name: Chart name
        environments: Target environments (dev, staging, production)
        base_values: Base values for all environments
        repo_url: Chart repository URL

    Returns:
        Deployment results per environment
    """
    results = {}

    # Add repository
    adapter.repo_add("automotive", repo_url)
    adapter.repo_update()

    for env in environments:
        try:
            # Merge environment-specific values
            env_values = {**base_values, "environment": env}

            # Install or upgrade
            release_name = f"{chart_name}-{env}"
            result = adapter.upgrade(
                release_name=release_name,
                chart=f"automotive/{chart_name}",
                namespace=f"automotive-{env}",
                values=env_values,
                install=True,
                wait=True,
                atomic=True
            )

            results[env] = {
                "status": "success",
                "release": result
            }

        except Exception as e:
            logger.error(f"Failed to deploy to {env}: {e}")
            results[env] = {
                "status": "failed",
                "error": str(e)
            }

    return results

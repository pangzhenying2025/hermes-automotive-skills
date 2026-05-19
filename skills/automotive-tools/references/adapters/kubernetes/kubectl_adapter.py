"""
Kubectl adapter for Kubernetes cluster operations.

Provides programmatic access to kubectl commands for automotive Kubernetes management.
"""

import subprocess
import json
import yaml
from typing import Dict, List, Optional, Any, Union
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class KubectlAdapter:
    """Adapter for kubectl CLI operations."""

    def __init__(
        self,
        kubeconfig: Optional[str] = None,
        context: Optional[str] = None,
        namespace: str = "default"
    ):
        """
        Initialize kubectl adapter.

        Args:
            kubeconfig: Path to kubeconfig file
            context: Kubernetes context to use
            namespace: Default namespace
        """
        self.kubeconfig = kubeconfig
        self.context = context
        self.namespace = namespace

    def _build_command(self, *args: str, namespace: Optional[str] = None) -> List[str]:
        """
        Build kubectl command with common options.

        Args:
            *args: kubectl command arguments
            namespace: Override default namespace

        Returns:
            Complete command as list
        """
        cmd = ["kubectl"]

        if self.kubeconfig:
            cmd.extend(["--kubeconfig", self.kubeconfig])

        if self.context:
            cmd.extend(["--context", self.context])

        ns = namespace or self.namespace
        if ns and "--all-namespaces" not in args and "-A" not in args:
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
        """
        Execute kubectl command.

        Args:
            *args: Command arguments
            capture_output: Capture stdout/stderr
            check: Raise exception on non-zero exit
            **kwargs: Additional subprocess.run arguments

        Returns:
            CompletedProcess instance

        Raises:
            subprocess.CalledProcessError: If command fails and check=True
        """
        cmd = self._build_command(*args, **kwargs)
        logger.debug(f"Executing: {' '.join(cmd)}")

        result = subprocess.run(
            cmd,
            capture_output=capture_output,
            text=True,
            check=check
        )

        return result

    def apply(
        self,
        filename: Optional[str] = None,
        manifest: Optional[Union[Dict, str]] = None,
        namespace: Optional[str] = None,
        dry_run: bool = False
    ) -> Dict[str, Any]:
        """
        Apply Kubernetes resources.

        Args:
            filename: Path to manifest file
            manifest: Manifest as dict or YAML string
            namespace: Namespace to apply to
            dry_run: Perform dry run

        Returns:
            Result information
        """
        args = ["apply"]

        if filename:
            args.extend(["-f", filename])
        elif manifest:
            args.extend(["-f", "-"])
        else:
            raise ValueError("Either filename or manifest must be provided")

        if dry_run:
            args.append("--dry-run=client")

        args.extend(["-o", "json"])

        input_data = None
        if manifest:
            if isinstance(manifest, dict):
                input_data = yaml.dump(manifest)
            else:
                input_data = manifest

        result = self._execute(
            *args,
            namespace=namespace,
            input=input_data.encode() if input_data else None
        )

        return json.loads(result.stdout) if result.stdout else {}

    def delete(
        self,
        resource_type: str,
        name: Optional[str] = None,
        namespace: Optional[str] = None,
        labels: Optional[Dict[str, str]] = None,
        force: bool = False
    ) -> bool:
        """
        Delete Kubernetes resources.

        Args:
            resource_type: Type of resource (e.g., pod, deployment)
            name: Resource name (optional if using labels)
            namespace: Namespace
            labels: Label selector
            force: Force deletion

        Returns:
            True if successful
        """
        args = ["delete", resource_type]

        if name:
            args.append(name)
        elif labels:
            label_selector = ",".join(f"{k}={v}" for k, v in labels.items())
            args.extend(["-l", label_selector])

        if force:
            args.extend(["--force", "--grace-period=0"])

        self._execute(*args, namespace=namespace)
        return True

    def get(
        self,
        resource_type: str,
        name: Optional[str] = None,
        namespace: Optional[str] = None,
        labels: Optional[Dict[str, str]] = None,
        all_namespaces: bool = False,
        output_format: str = "json"
    ) -> Union[Dict, List[Dict]]:
        """
        Get Kubernetes resources.

        Args:
            resource_type: Type of resource
            name: Resource name (optional)
            namespace: Namespace
            labels: Label selector
            all_namespaces: Search all namespaces
            output_format: Output format (json, yaml, wide, etc.)

        Returns:
            Resource data
        """
        args = ["get", resource_type]

        if name:
            args.append(name)

        if labels:
            label_selector = ",".join(f"{k}={v}" for k, v in labels.items())
            args.extend(["-l", label_selector])

        if all_namespaces:
            args.append("-A")

        args.extend(["-o", output_format])

        result = self._execute(*args, namespace=namespace)

        if output_format == "json":
            data = json.loads(result.stdout)
            if data.get("kind") == "List":
                return data.get("items", [])
            return data
        elif output_format == "yaml":
            return yaml.safe_load(result.stdout)
        else:
            return {"output": result.stdout}

    def describe(
        self,
        resource_type: str,
        name: str,
        namespace: Optional[str] = None
    ) -> str:
        """
        Describe Kubernetes resource.

        Args:
            resource_type: Type of resource
            name: Resource name
            namespace: Namespace

        Returns:
            Description text
        """
        result = self._execute("describe", resource_type, name, namespace=namespace)
        return result.stdout

    def logs(
        self,
        pod_name: str,
        namespace: Optional[str] = None,
        container: Optional[str] = None,
        follow: bool = False,
        tail: Optional[int] = None,
        since: Optional[str] = None
    ) -> str:
        """
        Get pod logs.

        Args:
            pod_name: Pod name
            namespace: Namespace
            container: Container name (for multi-container pods)
            follow: Follow logs
            tail: Number of lines from end
            since: Show logs since duration (e.g., "5m", "1h")

        Returns:
            Log output
        """
        args = ["logs", pod_name]

        if container:
            args.extend(["-c", container])

        if follow:
            args.append("-f")

        if tail:
            args.extend(["--tail", str(tail)])

        if since:
            args.extend(["--since", since])

        result = self._execute(*args, namespace=namespace)
        return result.stdout

    def exec(
        self,
        pod_name: str,
        command: List[str],
        namespace: Optional[str] = None,
        container: Optional[str] = None,
        stdin: bool = False,
        tty: bool = False
    ) -> str:
        """
        Execute command in pod.

        Args:
            pod_name: Pod name
            command: Command to execute
            namespace: Namespace
            container: Container name
            stdin: Enable stdin
            tty: Allocate TTY

        Returns:
            Command output
        """
        args = ["exec", pod_name]

        if container:
            args.extend(["-c", container])

        if stdin:
            args.append("-i")

        if tty:
            args.append("-t")

        args.append("--")
        args.extend(command)

        result = self._execute(*args, namespace=namespace)
        return result.stdout

    def scale(
        self,
        resource_type: str,
        name: str,
        replicas: int,
        namespace: Optional[str] = None
    ) -> bool:
        """
        Scale resource replicas.

        Args:
            resource_type: Type of resource (deployment, statefulset, etc.)
            name: Resource name
            replicas: Target replica count
            namespace: Namespace

        Returns:
            True if successful
        """
        self._execute(
            "scale",
            resource_type,
            name,
            f"--replicas={replicas}",
            namespace=namespace
        )
        return True

    def rollout_status(
        self,
        resource_type: str,
        name: str,
        namespace: Optional[str] = None,
        watch: bool = False,
        timeout: str = "5m"
    ) -> str:
        """
        Check rollout status.

        Args:
            resource_type: Type of resource
            name: Resource name
            namespace: Namespace
            watch: Watch until completion
            timeout: Timeout duration

        Returns:
            Status message
        """
        args = ["rollout", "status", resource_type, name]

        if watch:
            args.append("--watch=true")

        args.extend(["--timeout", timeout])

        result = self._execute(*args, namespace=namespace)
        return result.stdout

    def rollout_undo(
        self,
        resource_type: str,
        name: str,
        namespace: Optional[str] = None,
        to_revision: Optional[int] = None
    ) -> bool:
        """
        Rollback deployment.

        Args:
            resource_type: Type of resource
            name: Resource name
            namespace: Namespace
            to_revision: Target revision number

        Returns:
            True if successful
        """
        args = ["rollout", "undo", resource_type, name]

        if to_revision:
            args.extend(["--to-revision", str(to_revision)])

        self._execute(*args, namespace=namespace)
        return True

    def port_forward(
        self,
        resource: str,
        ports: str,
        namespace: Optional[str] = None,
        address: str = "localhost"
    ) -> subprocess.Popen:
        """
        Forward port from resource.

        Args:
            resource: Resource identifier (pod/name, svc/name)
            ports: Port mapping (e.g., "8080:80")
            namespace: Namespace
            address: Bind address

        Returns:
            Popen instance (must be managed by caller)
        """
        cmd = self._build_command(
            "port-forward",
            resource,
            ports,
            f"--address={address}",
            namespace=namespace
        )

        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        logger.info(f"Port forwarding started: {ports}")
        return proc

    def wait_for_condition(
        self,
        resource_type: str,
        name: str,
        condition: str,
        namespace: Optional[str] = None,
        timeout: str = "300s"
    ) -> bool:
        """
        Wait for resource condition.

        Args:
            resource_type: Type of resource
            name: Resource name
            condition: Condition to wait for (e.g., "Ready", "Available")
            namespace: Namespace
            timeout: Timeout duration

        Returns:
            True if condition met, False if timeout
        """
        try:
            self._execute(
                "wait",
                f"--for=condition={condition}",
                resource_type,
                name,
                f"--timeout={timeout}",
                namespace=namespace
            )
            return True
        except subprocess.CalledProcessError:
            return False

    def create_namespace(self, name: str, labels: Optional[Dict[str, str]] = None) -> bool:
        """
        Create namespace.

        Args:
            name: Namespace name
            labels: Labels to apply

        Returns:
            True if successful
        """
        manifest = {
            "apiVersion": "v1",
            "kind": "Namespace",
            "metadata": {
                "name": name
            }
        }

        if labels:
            manifest["metadata"]["labels"] = labels

        self.apply(manifest=manifest)
        return True

    def get_cluster_info(self) -> Dict[str, Any]:
        """
        Get cluster information.

        Returns:
            Cluster info dict
        """
        result = self._execute("cluster-info", "dump", "-o", "json")
        return json.loads(result.stdout)

    def get_nodes(self) -> List[Dict[str, Any]]:
        """
        Get cluster nodes.

        Returns:
            List of node information
        """
        return self.get("nodes", all_namespaces=True)

    def get_events(
        self,
        namespace: Optional[str] = None,
        field_selector: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get events.

        Args:
            namespace: Namespace (or all)
            field_selector: Field selector filter

        Returns:
            List of events
        """
        args = ["get", "events", "-o", "json"]

        if field_selector:
            args.extend(["--field-selector", field_selector])

        result = self._execute(*args, namespace=namespace)
        data = json.loads(result.stdout)
        return data.get("items", [])

    def top_nodes(self) -> List[Dict[str, Any]]:
        """
        Get node resource usage.

        Returns:
            List of node metrics
        """
        result = self._execute("top", "nodes", "--no-headers")
        return self._parse_top_output(result.stdout)

    def top_pods(
        self,
        namespace: Optional[str] = None,
        all_namespaces: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Get pod resource usage.

        Args:
            namespace: Namespace
            all_namespaces: All namespaces

        Returns:
            List of pod metrics
        """
        args = ["top", "pods", "--no-headers"]

        if all_namespaces:
            args.append("-A")

        result = self._execute(*args, namespace=namespace)
        return self._parse_top_output(result.stdout)

    def _parse_top_output(self, output: str) -> List[Dict[str, Any]]:
        """Parse kubectl top command output."""
        lines = output.strip().split("\n")
        metrics = []

        for line in lines:
            parts = line.split()
            if len(parts) >= 3:
                metrics.append({
                    "name": parts[0],
                    "cpu": parts[1],
                    "memory": parts[2]
                })

        return metrics


# Automotive-specific helper functions

def deploy_automotive_workload(
    adapter: KubectlAdapter,
    workload_type: str,
    manifests_dir: Path,
    environment: str = "production"
) -> Dict[str, Any]:
    """
    Deploy automotive workload with environment-specific configuration.

    Args:
        adapter: Kubectl adapter instance
        workload_type: Type of workload (adas, battery, connectivity, etc.)
        manifests_dir: Directory containing manifests
        environment: Target environment

    Returns:
        Deployment results
    """
    results = {
        "workload_type": workload_type,
        "environment": environment,
        "deployed_resources": []
    }

    # Apply base manifests
    base_dir = manifests_dir / "base"
    if base_dir.exists():
        for manifest_file in base_dir.glob("*.yaml"):
            result = adapter.apply(filename=str(manifest_file))
            results["deployed_resources"].append(result)

    # Apply environment overlay
    overlay_dir = manifests_dir / "overlays" / environment
    if overlay_dir.exists():
        for manifest_file in overlay_dir.glob("*.yaml"):
            result = adapter.apply(filename=str(manifest_file))
            results["deployed_resources"].append(result)

    return results


def check_automotive_compliance(
    adapter: KubectlAdapter,
    namespace: str
) -> Dict[str, Any]:
    """
    Check automotive compliance (ISO 26262, ASPICE) for deployments.

    Args:
        adapter: Kubectl adapter instance
        namespace: Namespace to check

    Returns:
        Compliance check results
    """
    compliance_results = {
        "namespace": namespace,
        "compliant": True,
        "issues": []
    }

    # Check all deployments in namespace
    deployments = adapter.get("deployments", namespace=namespace)

    for deployment in deployments:
        metadata = deployment.get("metadata", {})
        labels = metadata.get("labels", {})

        # Check for required automotive labels
        required_labels = [
            "automotive.io/component",
            "automotive.io/safety-level",
            "automotive.io/aspice-level"
        ]

        missing_labels = [
            label for label in required_labels
            if label not in labels
        ]

        if missing_labels:
            compliance_results["compliant"] = False
            compliance_results["issues"].append({
                "deployment": metadata.get("name"),
                "type": "missing_labels",
                "missing": missing_labels
            })

        # Check security context
        spec = deployment.get("spec", {}).get("template", {}).get("spec", {})
        security_context = spec.get("securityContext", {})

        if not security_context.get("runAsNonRoot"):
            compliance_results["compliant"] = False
            compliance_results["issues"].append({
                "deployment": metadata.get("name"),
                "type": "security",
                "issue": "Must run as non-root for ISO 26262 compliance"
            })

    return compliance_results

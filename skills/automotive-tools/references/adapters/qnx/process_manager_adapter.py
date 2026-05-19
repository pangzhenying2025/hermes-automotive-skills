"""
QNX Process Manager Adapter

Remote process control and monitoring via qconn protocol.
Provides wrappers for pidin, slay, on, and other QNX process management utilities.
"""

import subprocess
import re
import time
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum

from ..base_adapter import OpensourceToolAdapter


class ProcessState(Enum):
    """QNX process states"""
    RUNNING = "RUN"
    READY = "READY"
    BLOCKED = "BLOCKED"
    STOPPED = "STOPPED"
    ZOMBIE = "ZOMBIE"
    DEAD = "DEAD"


class ProcessPriority(Enum):
    """QNX process priority classes"""
    REALTIME = "realtime"
    ADAPTIVE = "adaptive"
    IDLE = "idle"


@dataclass
class ProcessInfo:
    """QNX process information"""
    pid: int
    name: str
    state: str
    priority: int
    threads: int
    memory_kb: int
    cpu_percent: float
    parent_pid: int


@dataclass
class MemoryInfo:
    """Process memory usage information"""
    pid: int
    total_kb: int
    code_kb: int
    data_kb: int
    stack_kb: int
    heap_kb: int


class ProcessManagerAdapter(OpensourceToolAdapter):
    """
    QNX Process Manager control adapter.

    Provides remote process management capabilities:
    - Process listing and monitoring (pidin)
    - Process termination (slay)
    - Process launching (on)
    - Priority management
    - Memory profiling
    - CPU usage tracking

    Example:
        pm = ProcessManagerAdapter(
            target_ip="192.168.1.100",
            target_port=8000
        )

        # List all processes
        processes = pm.list_processes()

        # Launch process with priority
        pm.launch_process(
            command="/usr/local/bin/can_service",
            priority=50,
            background=True
        )

        # Monitor CPU usage
        stats = pm.get_process_stats("can_service")

        # Kill process
        pm.kill_process("can_service", force=True)
    """

    def __init__(
        self,
        target_ip: str,
        target_port: int = 8000,
        username: str = "root",
        password: str = "",
        qnx_host: Optional[str] = None
    ):
        """
        Initialize Process Manager adapter.

        Args:
            target_ip: QNX target IP address
            target_port: qconn port (default 8000)
            username: Target username
            password: Target password
            qnx_host: QNX_HOST path
        """
        super().__init__(name="qnx-process-manager", version=None)

        self.target_ip = target_ip
        self.target_port = target_port
        self.username = username
        self.password = password

        self.target_url = f"{username}@{target_ip}"

    def _success(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Return success result"""
        return {"success": True, "data": data}

    def _error(self, message: str, details: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Return error result"""
        result = {"success": False, "error": message}
        if details:
            result["details"] = details
        return result

    def _detect(self) -> bool:
        """Detect if target is reachable"""
        return True  # Always available, detection happens at runtime

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute process manager command"""
        if command == "list_processes":
            return self.list_processes(**parameters)
        elif command == "launch_process":
            return self.launch_process(**parameters)
        elif command == "kill_process":
            return self.kill_process(**parameters)
        else:
            return {"success": False, "error": f"Unknown command: {command}"}

    def _execute_remote(
        self,
        command: str,
        timeout: int = 30
    ) -> Tuple[int, str, str]:
        """
        Execute command on remote QNX target via SSH.

        Args:
            command: Command to execute
            timeout: Command timeout in seconds

        Returns:
            Tuple of (return_code, stdout, stderr)
        """
        ssh_cmd = [
            "ssh",
            "-p", str(self.target_port),
            "-o", "StrictHostKeyChecking=no",
            "-o", "ConnectTimeout=10",
            self.target_url,
            command
        ]

        try:
            result = subprocess.run(
                ssh_cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Command timeout"
        except Exception as e:
            return -1, "", str(e)

    def list_processes(
        self,
        filter_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        List all running processes using pidin.

        Args:
            filter_name: Filter processes by name (optional)

        Returns:
            List of process information
        """
        cmd = "pidin info"

        returncode, stdout, stderr = self._execute_remote(cmd)

        if returncode != 0:
            return self._error(
                f"Failed to list processes: {stderr}",
                details={"returncode": returncode}
            )

        processes = self._parse_pidin_output(stdout)

        if filter_name:
            processes = [p for p in processes if filter_name.lower() in p.name.lower()]

        return self._success({
            "processes": [vars(p) for p in processes],
            "count": len(processes)
        })

    def _parse_pidin_output(self, output: str) -> List[ProcessInfo]:
        """Parse pidin command output"""
        processes = []

        # Skip header lines
        lines = output.splitlines()
        for line in lines[2:]:  # Skip header
            if not line.strip():
                continue

            parts = line.split()
            if len(parts) < 8:
                continue

            try:
                process = ProcessInfo(
                    pid=int(parts[0]),
                    name=parts[1],
                    state=parts[2],
                    priority=int(parts[3]),
                    threads=int(parts[4]),
                    memory_kb=self._parse_memory(parts[5]),
                    cpu_percent=float(parts[6].rstrip('%')),
                    parent_pid=int(parts[7]) if len(parts) > 7 else 0
                )
                processes.append(process)
            except (ValueError, IndexError):
                continue

        return processes

    def _parse_memory(self, mem_str: str) -> int:
        """Parse memory string (e.g., '4096K', '2M') to KB"""
        mem_str = mem_str.upper()
        if 'M' in mem_str:
            return int(float(mem_str.rstrip('M')) * 1024)
        elif 'K' in mem_str:
            return int(float(mem_str.rstrip('K')))
        else:
            return int(mem_str) // 1024

    def get_process_info(
        self,
        process_name: str
    ) -> Dict[str, Any]:
        """
        Get detailed information about specific process.

        Args:
            process_name: Process name to query

        Returns:
            Detailed process information
        """
        cmd = f"pidin -p {process_name} info"

        returncode, stdout, stderr = self._execute_remote(cmd)

        if returncode != 0:
            return self._error(
                f"Process not found: {process_name}",
                details={"stderr": stderr}
            )

        processes = self._parse_pidin_output(stdout)

        if not processes:
            return self._error(f"No information found for process: {process_name}")

        process = processes[0]

        return self._success({
            "pid": process.pid,
            "name": process.name,
            "state": process.state,
            "priority": process.priority,
            "threads": process.threads,
            "memory_kb": process.memory_kb,
            "cpu_percent": process.cpu_percent,
            "parent_pid": process.parent_pid
        })

    def get_process_stats(
        self,
        process_name: str,
        interval_seconds: int = 1,
        samples: int = 5
    ) -> Dict[str, Any]:
        """
        Monitor process CPU and memory usage over time.

        Args:
            process_name: Process to monitor
            interval_seconds: Sampling interval
            samples: Number of samples to collect

        Returns:
            Process statistics over time
        """
        stats = []

        for i in range(samples):
            result = self.get_process_info(process_name)

            if result.get("success"):
                data = result.get("data", {})
                stats.append({
                    "sample": i + 1,
                    "timestamp": time.time(),
                    "cpu_percent": data.get("cpu_percent", 0.0),
                    "memory_kb": data.get("memory_kb", 0),
                    "threads": data.get("threads", 0)
                })

            if i < samples - 1:
                time.sleep(interval_seconds)

        if not stats:
            return self._error(f"Failed to collect stats for {process_name}")

        # Calculate averages
        avg_cpu = sum(s["cpu_percent"] for s in stats) / len(stats)
        avg_memory = sum(s["memory_kb"] for s in stats) / len(stats)

        return self._success({
            "process_name": process_name,
            "samples": stats,
            "average_cpu_percent": avg_cpu,
            "average_memory_kb": avg_memory
        })

    def kill_process(
        self,
        process_name: str,
        signal: str = "TERM",
        force: bool = False
    ) -> Dict[str, Any]:
        """
        Terminate process using slay command.

        Args:
            process_name: Process name to kill
            signal: Signal to send (TERM, KILL, etc.)
            force: Force kill with SIGKILL

        Returns:
            Process termination result
        """
        if force:
            signal = "KILL"

        cmd = f"slay -{signal} {process_name}"

        returncode, stdout, stderr = self._execute_remote(cmd)

        if returncode != 0:
            return self._error(
                f"Failed to kill process {process_name}: {stderr}",
                details={"returncode": returncode}
            )

        # Verify process is terminated
        time.sleep(0.5)
        check_result = self.get_process_info(process_name)

        if check_result.get("success"):
            return self._error(
                f"Process {process_name} still running after kill attempt"
            )

        return self._success({
            "process_name": process_name,
            "signal": signal,
            "terminated": True
        })

    def launch_process(
        self,
        command: str,
        priority: Optional[int] = None,
        background: bool = False,
        env_vars: Optional[Dict[str, str]] = None,
        working_dir: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Launch process on QNX target using 'on' command.

        Args:
            command: Command to execute
            priority: Process priority (0-255, or None for default)
            background: Run in background
            env_vars: Environment variables to set
            working_dir: Working directory for process

        Returns:
            Process launch result with PID
        """
        # Build 'on' command
        on_cmd = "on"

        # Add priority if specified
        if priority is not None:
            on_cmd += f" -p {priority}"

        # Add working directory
        if working_dir:
            on_cmd += f" -d {working_dir}"

        # Add environment variables
        if env_vars:
            for key, value in env_vars.items():
                on_cmd += f" -e {key}={value}"

        # Add command
        on_cmd += f" {command}"

        # Background execution
        if background:
            on_cmd += " &"

        returncode, stdout, stderr = self._execute_remote(on_cmd)

        if returncode != 0:
            return self._error(
                f"Failed to launch process: {stderr}",
                details={"command": command, "returncode": returncode}
            )

        # Extract PID from output if available
        pid = None
        pid_match = re.search(r'pid (\d+)', stdout)
        if pid_match:
            pid = int(pid_match.group(1))

        return self._success({
            "command": command,
            "pid": pid,
            "priority": priority,
            "background": background,
            "launched": True
        })

    def set_process_priority(
        self,
        process_name: str,
        priority: int
    ) -> Dict[str, Any]:
        """
        Change process priority.

        Args:
            process_name: Process name
            priority: New priority (0-255)

        Returns:
            Priority change result
        """
        if not 0 <= priority <= 255:
            return self._error("Priority must be between 0 and 255")

        # Get process PID first
        info_result = self.get_process_info(process_name)
        if not info_result.get("success"):
            return self._error(f"Process not found: {process_name}")

        pid = info_result["data"]["pid"]

        # Use nice command to change priority
        cmd = f"nice -n {priority} -p {pid}"

        returncode, stdout, stderr = self._execute_remote(cmd)

        if returncode != 0:
            return self._error(
                f"Failed to set priority: {stderr}",
                details={"pid": pid, "priority": priority}
            )

        return self._success({
            "process_name": process_name,
            "pid": pid,
            "new_priority": priority,
            "changed": True
        })

    def get_memory_usage(
        self,
        process_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Get detailed memory usage using pidin memory.

        Args:
            process_name: Specific process (None for all)

        Returns:
            Memory usage information
        """
        cmd = "pidin memory"
        if process_name:
            cmd += f" -p {process_name}"

        returncode, stdout, stderr = self._execute_remote(cmd)

        if returncode != 0:
            return self._error(
                f"Failed to get memory usage: {stderr}",
                details={"returncode": returncode}
            )

        memory_info = self._parse_memory_output(stdout)

        return self._success({
            "memory_usage": memory_info,
            "process_name": process_name
        })

    def _parse_memory_output(self, output: str) -> List[Dict[str, Any]]:
        """Parse pidin memory output"""
        memory_data = []

        lines = output.splitlines()
        for line in lines[2:]:  # Skip headers
            if not line.strip():
                continue

            parts = line.split()
            if len(parts) < 6:
                continue

            try:
                mem_info = {
                    "pid": int(parts[0]),
                    "name": parts[1],
                    "total_kb": self._parse_memory(parts[2]),
                    "code_kb": self._parse_memory(parts[3]),
                    "data_kb": self._parse_memory(parts[4]),
                    "stack_kb": self._parse_memory(parts[5])
                }
                memory_data.append(mem_info)
            except (ValueError, IndexError):
                continue

        return memory_data

    def monitor_realtime_processes(self) -> Dict[str, Any]:
        """
        Monitor all real-time processes and their priorities.

        Returns:
            List of real-time processes
        """
        cmd = "pidin -F \"%a %n %B %r %t\""

        returncode, stdout, stderr = self._execute_remote(cmd)

        if returncode != 0:
            return self._error(f"Failed to monitor processes: {stderr}")

        rt_processes = []
        for line in stdout.splitlines():
            if "RUN" in line or "READY" in line:
                parts = line.split()
                if len(parts) >= 5:
                    rt_processes.append({
                        "pid": parts[0],
                        "name": parts[1],
                        "state": parts[2],
                        "priority": parts[3],
                        "threads": parts[4]
                    })

        return self._success({
            "realtime_processes": rt_processes,
            "count": len(rt_processes)
        })

    def restart_process(
        self,
        process_name: str,
        command: str,
        priority: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Restart process by killing and relaunching.

        Args:
            process_name: Process to restart
            command: Command to relaunch
            priority: Priority for new process

        Returns:
            Restart result
        """
        # Kill existing process
        kill_result = self.kill_process(process_name, force=True)

        if not kill_result.get("success"):
            return self._error(
                f"Failed to kill process: {process_name}",
                details=kill_result
            )

        # Wait for process to fully terminate
        time.sleep(1)

        # Launch new process
        launch_result = self.launch_process(
            command=command,
            priority=priority,
            background=True
        )

        if not launch_result.get("success"):
            return self._error(
                f"Failed to relaunch process: {process_name}",
                details=launch_result
            )

        return self._success({
            "process_name": process_name,
            "restarted": True,
            "new_pid": launch_result.get("data", {}).get("pid")
        })

    def get_system_resources(self) -> Dict[str, Any]:
        """
        Get overall system resource usage.

        Returns:
            System resource information
        """
        cmd = "pidin syspage=system"

        returncode, stdout, stderr = self._execute_remote(cmd)

        if returncode != 0:
            return self._error(f"Failed to get system info: {stderr}")

        return self._success({
            "system_info": stdout,
            "target": self.target_ip
        })

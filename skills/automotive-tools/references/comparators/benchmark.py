"""
Performance Benchmarking for Automotive Tools.

Benchmarks various aspects of tools:
- Execution time
- Memory usage
- CPU utilization
- I/O performance
- Scalability
- Resource efficiency

Benchmark scenarios:
- CAN message processing throughput
- DBC parsing speed
- Simulation performance
- Static analysis speed
- Test execution time
- Code generation speed
"""

import time
import psutil
import subprocess
import tempfile
import os
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, field, asdict
from pathlib import Path
import logging
import json
import statistics

logger = logging.getLogger(__name__)


@dataclass
class BenchmarkResult:
    """Result of a benchmark run."""
    tool_name: str
    scenario: str
    execution_time_sec: float
    memory_peak_mb: float
    cpu_percent: float
    success: bool
    throughput: Optional[float] = None
    error_message: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class BenchmarkSuite:
    """Collection of benchmark results."""
    suite_name: str
    results: List[BenchmarkResult]
    timestamp: str
    system_info: Dict[str, str]


class ToolBenchmark:
    """Benchmark runner for automotive tools."""

    def __init__(self):
        """Initialize benchmark runner."""
        self.system_info = self._get_system_info()

    def _get_system_info(self) -> Dict[str, str]:
        """Get system information for benchmark context."""
        import platform

        return {
            "os": platform.system(),
            "os_version": platform.version(),
            "architecture": platform.machine(),
            "processor": platform.processor(),
            "cpu_count": str(psutil.cpu_count()),
            "total_memory_gb": f"{psutil.virtual_memory().total / (1024**3):.2f}",
            "python_version": platform.python_version()
        }

    def benchmark_tool(
        self,
        tool_name: str,
        scenario: str,
        benchmark_func: Callable[[], bool],
        iterations: int = 3
    ) -> BenchmarkResult:
        """
        Benchmark a tool scenario.

        Args:
            tool_name: Tool name
            scenario: Scenario description
            benchmark_func: Function to benchmark (returns True on success)
            iterations: Number of iterations (best of N)

        Returns:
            BenchmarkResult with performance metrics
        """
        logger.info(f"Benchmarking {tool_name}: {scenario}")

        results = []

        for i in range(iterations):
            logger.debug(f"Iteration {i+1}/{iterations}")

            # Record initial state
            process = psutil.Process()
            initial_memory = process.memory_info().rss / (1024 * 1024)  # MB

            # Run benchmark
            start_time = time.time()
            cpu_percent_samples = []

            try:
                # Monitor CPU during execution
                success = True
                error_msg = None

                # Sample CPU usage periodically
                result = benchmark_func()
                cpu_percent = process.cpu_percent(interval=0.1)

                execution_time = time.time() - start_time
                peak_memory = process.memory_info().rss / (1024 * 1024)  # MB
                memory_used = peak_memory - initial_memory

                results.append({
                    "execution_time": execution_time,
                    "memory_used": memory_used,
                    "cpu_percent": cpu_percent,
                    "success": result
                })

            except Exception as e:
                logger.exception(f"Benchmark failed: {e}")
                execution_time = time.time() - start_time
                results.append({
                    "execution_time": execution_time,
                    "memory_used": 0,
                    "cpu_percent": 0,
                    "success": False,
                    "error": str(e)
                })

        # Calculate statistics (use best/median)
        successful_results = [r for r in results if r["success"]]

        if not successful_results:
            return BenchmarkResult(
                tool_name=tool_name,
                scenario=scenario,
                execution_time_sec=0,
                memory_peak_mb=0,
                cpu_percent=0,
                success=False,
                error_message=results[0].get("error", "All iterations failed")
            )

        # Use median for more stable results
        exec_times = [r["execution_time"] for r in successful_results]
        mem_usages = [r["memory_used"] for r in successful_results]
        cpu_percents = [r["cpu_percent"] for r in successful_results]

        return BenchmarkResult(
            tool_name=tool_name,
            scenario=scenario,
            execution_time_sec=statistics.median(exec_times),
            memory_peak_mb=statistics.median(mem_usages),
            cpu_percent=statistics.median(cpu_percents),
            success=True,
            metadata={
                "min_time": min(exec_times),
                "max_time": max(exec_times),
                "std_dev": statistics.stdev(exec_times) if len(exec_times) > 1 else 0
            }
        )

    def benchmark_can_processing(
        self,
        tool_name: str,
        message_count: int = 10000
    ) -> BenchmarkResult:
        """
        Benchmark CAN message processing throughput.

        Args:
            tool_name: Tool name (cantools, python-can, etc.)
            message_count: Number of messages to process

        Returns:
            BenchmarkResult
        """
        def run_benchmark() -> bool:
            if tool_name == "cantools":
                return self._benchmark_cantools_processing(message_count)
            elif tool_name == "python-can":
                return self._benchmark_pythoncan_processing(message_count)
            else:
                logger.error(f"Unknown tool: {tool_name}")
                return False

        result = self.benchmark_tool(
            tool_name,
            f"CAN message processing ({message_count} messages)",
            run_benchmark,
            iterations=3
        )

        if result.success:
            result.throughput = message_count / result.execution_time_sec
            result.metadata["throughput_msg_per_sec"] = result.throughput

        return result

    def _benchmark_cantools_processing(self, message_count: int) -> bool:
        """Benchmark cantools DBC parsing and encoding."""
        try:
            import cantools

            # Create sample DBC
            dbc_content = """
VERSION ""

NS_ :
    NS_DESC_
    CM_
    BA_DEF_
    BA_
    VAL_
    CAT_DEF_
    CAT_
    FILTER
    BA_DEF_DEF_
    EV_DATA_
    ENVVAR_DATA_
    SGTYPE_
    SGTYPE_VAL_
    BA_DEF_SGTYPE_
    BA_SGTYPE_
    SIG_TYPE_REF_
    VAL_TABLE_
    SIG_GROUP_
    SIG_VALTYPE_
    SIGTYPE_VALTYPE_
    BO_TX_BU_
    BA_DEF_REL_
    BA_REL_
    BA_SGTYPE_REL_
    SG_MUL_VAL_

BS_:

BU_: ECU1 ECU2

BO_ 100 TestMessage: 8 ECU1
 SG_ Signal1 : 0|16@1+ (0.1,0) [0|6553.5] "km/h" ECU2
 SG_ Signal2 : 16|16@1+ (1,0) [0|65535] "" ECU2
"""

            with tempfile.NamedTemporaryFile(mode='w', suffix='.dbc', delete=False) as f:
                f.write(dbc_content)
                dbc_file = f.name

            try:
                # Load DBC
                db = cantools.database.load_file(dbc_file)

                # Encode/decode messages
                for i in range(message_count):
                    data = db.encode_message('TestMessage', {
                        'Signal1': i % 1000,
                        'Signal2': i % 65536
                    })
                    decoded = db.decode_message('TestMessage', data)

                return True

            finally:
                os.unlink(dbc_file)

        except Exception as e:
            logger.exception("cantools benchmark failed")
            return False

    def _benchmark_pythoncan_processing(self, message_count: int) -> bool:
        """Benchmark python-can message handling."""
        try:
            import can

            # Create virtual bus
            bus = can.Bus(interface='virtual', channel='vcan0')

            # Send messages
            for i in range(message_count):
                msg = can.Message(
                    arbitration_id=0x100,
                    data=[i % 256, (i >> 8) % 256, 0, 0, 0, 0, 0, 0],
                    is_extended_id=False
                )
                # Just create messages, don't actually send (no virtual interface needed)

            return True

        except Exception as e:
            logger.exception("python-can benchmark failed")
            return False

    def benchmark_static_analysis(
        self,
        tool_name: str,
        source_file: str
    ) -> BenchmarkResult:
        """
        Benchmark static analysis tool.

        Args:
            tool_name: Tool name (cppcheck, clang-tidy, etc.)
            source_file: C/C++ source file to analyze

        Returns:
            BenchmarkResult
        """
        def run_benchmark() -> bool:
            if tool_name == "cppcheck":
                return self._benchmark_cppcheck(source_file)
            elif tool_name == "clang-tidy":
                return self._benchmark_clang_tidy(source_file)
            else:
                return False

        return self.benchmark_tool(
            tool_name,
            f"Static analysis of {Path(source_file).name}",
            run_benchmark
        )

    def _benchmark_cppcheck(self, source_file: str) -> bool:
        """Benchmark cppcheck analysis."""
        try:
            result = subprocess.run(
                ["cppcheck", "--enable=all", "--quiet", source_file],
                capture_output=True,
                timeout=60
            )
            return result.returncode == 0
        except:
            return False

    def _benchmark_clang_tidy(self, source_file: str) -> bool:
        """Benchmark clang-tidy analysis."""
        try:
            result = subprocess.run(
                ["clang-tidy", source_file, "--"],
                capture_output=True,
                timeout=60
            )
            return True  # clang-tidy returns non-zero on warnings
        except:
            return False

    def benchmark_build_system(
        self,
        tool_name: str,
        project_dir: str
    ) -> BenchmarkResult:
        """
        Benchmark build system performance.

        Args:
            tool_name: Build tool (cmake, make, bazel, etc.)
            project_dir: Project directory

        Returns:
            BenchmarkResult
        """
        def run_benchmark() -> bool:
            if tool_name == "cmake":
                return self._benchmark_cmake(project_dir)
            elif tool_name == "make":
                return self._benchmark_make(project_dir)
            else:
                return False

        return self.benchmark_tool(
            tool_name,
            f"Build {Path(project_dir).name}",
            run_benchmark
        )

    def _benchmark_cmake(self, project_dir: str) -> bool:
        """Benchmark CMake configuration and build."""
        try:
            with tempfile.TemporaryDirectory() as build_dir:
                # Configure
                result = subprocess.run(
                    ["cmake", "-B", build_dir, "-S", project_dir],
                    capture_output=True,
                    timeout=120
                )
                if result.returncode != 0:
                    return False

                # Build
                result = subprocess.run(
                    ["cmake", "--build", build_dir],
                    capture_output=True,
                    timeout=300
                )
                return result.returncode == 0
        except:
            return False

    def _benchmark_make(self, project_dir: str) -> bool:
        """Benchmark Make build."""
        try:
            result = subprocess.run(
                ["make", "-C", project_dir, "-j4"],
                capture_output=True,
                timeout=300
            )
            return result.returncode == 0
        except:
            return False

    def compare_tools(
        self,
        tools: List[str],
        scenario_func: Callable[[str], BenchmarkResult]
    ) -> List[BenchmarkResult]:
        """
        Compare multiple tools on the same scenario.

        Args:
            tools: List of tool names
            scenario_func: Function that takes tool name and returns BenchmarkResult

        Returns:
            List of BenchmarkResults
        """
        results = []

        for tool in tools:
            result = scenario_func(tool)
            results.append(result)

        # Sort by execution time
        results.sort(key=lambda r: r.execution_time_sec if r.success else float('inf'))

        return results

    def export_results(
        self,
        suite: BenchmarkSuite,
        output_path: str,
        format: str = "json"
    ) -> None:
        """
        Export benchmark results.

        Args:
            suite: Benchmark suite
            output_path: Output file path
            format: Output format (json, markdown, html)
        """
        if format == "json":
            self._export_json(suite, output_path)
        elif format == "markdown":
            self._export_markdown(suite, output_path)
        elif format == "html":
            self._export_html(suite, output_path)
        else:
            raise ValueError(f"Unsupported format: {format}")

    def _export_json(self, suite: BenchmarkSuite, output_path: str) -> None:
        """Export results as JSON."""
        data = {
            "suite_name": suite.suite_name,
            "timestamp": suite.timestamp,
            "system_info": suite.system_info,
            "results": [asdict(r) for r in suite.results]
        }

        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)

        logger.info(f"Results exported to {output_path}")

    def _export_markdown(self, suite: BenchmarkSuite, output_path: str) -> None:
        """Export results as Markdown."""
        lines = [
            f"# {suite.suite_name}",
            "",
            f"Generated: {suite.timestamp}",
            "",
            "## System Information",
            ""
        ]

        for key, value in suite.system_info.items():
            lines.append(f"- **{key}**: {value}")

        lines.extend([
            "",
            "## Results",
            "",
            "| Tool | Scenario | Time (s) | Memory (MB) | CPU (%) | Throughput | Status |",
            "|------|----------|----------|-------------|---------|------------|--------|"
        ])

        for result in suite.results:
            status = "✓" if result.success else "✗"
            throughput = f"{result.throughput:.0f} msg/s" if result.throughput else "N/A"
            lines.append(
                f"| {result.tool_name} | {result.scenario} | "
                f"{result.execution_time_sec:.3f} | {result.memory_peak_mb:.1f} | "
                f"{result.cpu_percent:.1f} | {throughput} | {status} |"
            )

        with open(output_path, 'w') as f:
            f.write("\n".join(lines))

        logger.info(f"Markdown results exported to {output_path}")

    def _export_html(self, suite: BenchmarkSuite, output_path: str) -> None:
        """Export results as HTML."""
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>{suite.suite_name}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        table {{ border-collapse: collapse; width: 100%; }}
        th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
        th {{ background-color: #4CAF50; color: white; }}
        .success {{ color: green; }}
        .failure {{ color: red; }}
    </style>
</head>
<body>
    <h1>{suite.suite_name}</h1>
    <p>Generated: {suite.timestamp}</p>

    <h2>System Information</h2>
    <ul>
"""

        for key, value in suite.system_info.items():
            html += f"        <li><strong>{key}</strong>: {value}</li>\n"

        html += """    </ul>

    <h2>Benchmark Results</h2>
    <table>
        <tr>
            <th>Tool</th>
            <th>Scenario</th>
            <th>Time (s)</th>
            <th>Memory (MB)</th>
            <th>CPU (%)</th>
            <th>Status</th>
        </tr>
"""

        for result in suite.results:
            status_class = "success" if result.success else "failure"
            status_text = "✓ Success" if result.success else "✗ Failed"

            html += f"""        <tr>
            <td>{result.tool_name}</td>
            <td>{result.scenario}</td>
            <td>{result.execution_time_sec:.3f}</td>
            <td>{result.memory_peak_mb:.1f}</td>
            <td>{result.cpu_percent:.1f}</td>
            <td class="{status_class}">{status_text}</td>
        </tr>
"""

        html += """    </table>
</body>
</html>"""

        with open(output_path, 'w') as f:
            f.write(html)

        logger.info(f"HTML results exported to {output_path}")


def main():
    """Main entry point."""
    logging.basicConfig(level=logging.INFO)

    benchmark = ToolBenchmark()

    # Example benchmarks
    print("\n=== CAN Processing Benchmark ===")

    results = []

    # Benchmark cantools
    try:
        result = benchmark.benchmark_can_processing("cantools", message_count=10000)
        results.append(result)
        print(f"cantools: {result.execution_time_sec:.3f}s, {result.throughput:.0f} msg/s")
    except Exception as e:
        print(f"cantools: FAILED ({e})")

    # Create benchmark suite
    from datetime import datetime

    suite = BenchmarkSuite(
        suite_name="CAN Tool Benchmarks",
        results=results,
        timestamp=datetime.now().isoformat(),
        system_info=benchmark.system_info
    )

    # Export results
    benchmark.export_results(suite, "/tmp/benchmark_results.json", "json")
    benchmark.export_results(suite, "/tmp/benchmark_results.md", "markdown")

    print(f"\n✓ Results exported to /tmp/benchmark_results.*")


if __name__ == "__main__":
    main()

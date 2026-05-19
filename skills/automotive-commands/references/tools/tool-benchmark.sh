#!/usr/bin/env bash
#
# Tool Benchmark Command
#
# Benchmarks performance of automotive development tools.
#
# Usage:
#   tool-benchmark [options] <scenario> [tool1] [tool2] ...
#
# Scenarios:
#   can-processing        CAN message encoding/decoding throughput
#   static-analysis       Static analysis speed
#   build                 Build system performance
#
# Options:
#   --iterations N         Number of benchmark iterations (default: 3)
#   --messages N           Number of CAN messages to process (default: 10000)
#   --format FORMAT        Output format: json|markdown|html (default: markdown)
#   --output FILE          Output file path
#   --compare              Compare multiple tools
#   --verbose              Show detailed benchmark info
#
# Examples:
#   tool-benchmark can-processing cantools                  # Benchmark cantools
#   tool-benchmark can-processing --compare cantools python-can
#   tool-benchmark static-analysis cppcheck --iterations 5
#   tool-benchmark build cmake --output build_bench.json

set -euo pipefail

# Default configuration
SCENARIO=""
TOOLS=()
ITERATIONS=3
MESSAGES=10000
FORMAT="markdown"
OUTPUT=""
COMPARE=false
VERBOSE=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        --messages)
            MESSAGES="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --compare)
            COMPARE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            grep '^#' "$0" | grep -v '#!/usr/bin/env' | sed 's/^# //'
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            if [[ -z "$SCENARIO" ]]; then
                SCENARIO="$1"
            else
                TOOLS+=("$1")
            fi
            shift
            ;;
    esac
done

# Validate inputs
if [[ -z "$SCENARIO" ]]; then
    echo "Error: Scenario required"
    echo "Use --help for usage information"
    exit 1
fi

if [[ ${#TOOLS[@]} -eq 0 ]]; then
    echo "Error: At least one tool required"
    exit 1
fi

# Set output file
if [[ -z "$OUTPUT" ]]; then
    OUTPUT="/tmp/benchmark_${SCENARIO}_$(date +%Y%m%d_%H%M%S).$FORMAT"
fi

# Create Python benchmark script
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" <<'PYTHON_EOF'
import sys
import os
import logging
from datetime import datetime

sys.path.insert(0, os.environ.get('PROJECT_ROOT'))

from tools.comparators.benchmark import ToolBenchmark, BenchmarkSuite

# Configure logging
log_level = logging.DEBUG if os.environ.get('VERBOSE') == 'true' else logging.INFO
logging.basicConfig(level=log_level, format='%(levelname)s: %(message)s')

def main():
    scenario = os.environ.get('SCENARIO')
    tools = os.environ.get('TOOLS', '').split(',')
    iterations = int(os.environ.get('ITERATIONS', '3'))
    messages = int(os.environ.get('MESSAGES', '10000'))
    output_file = os.environ.get('OUTPUT')
    output_format = os.environ.get('FORMAT', 'markdown')
    compare = os.environ.get('COMPARE') == 'true'

    benchmark = ToolBenchmark()
    results = []

    print(f"\n=== Benchmarking {scenario} ===\n")

    # Run benchmarks for each tool
    for tool in tools:
        print(f"Benchmarking {tool}...")

        try:
            if scenario == 'can-processing':
                result = benchmark.benchmark_can_processing(tool, message_count=messages)
            elif scenario == 'static-analysis':
                # Need source file for analysis
                print(f"  Skipping {tool}: static-analysis requires source file")
                continue
            elif scenario == 'build':
                # Need project directory
                print(f"  Skipping {tool}: build requires project directory")
                continue
            else:
                print(f"  Error: Unknown scenario '{scenario}'")
                continue

            results.append(result)

            # Print result
            if result.success:
                print(f"  ✓ Time: {result.execution_time_sec:.3f}s")
                print(f"  ✓ Memory: {result.memory_peak_mb:.1f} MB")
                print(f"  ✓ CPU: {result.cpu_percent:.1f}%")
                if result.throughput:
                    print(f"  ✓ Throughput: {result.throughput:.0f} msg/s")
            else:
                print(f"  ✗ Failed: {result.error_message}")

        except Exception as e:
            print(f"  ✗ Error: {e}")

    if not results:
        print("\nNo successful benchmarks")
        sys.exit(1)

    # Create benchmark suite
    suite = BenchmarkSuite(
        suite_name=f"{scenario.replace('-', ' ').title()} Benchmarks",
        results=results,
        timestamp=datetime.now().isoformat(),
        system_info=benchmark.system_info
    )

    # Print comparison if multiple tools
    if compare and len(results) > 1:
        print(f"\n=== Comparison ===\n")

        # Sort by execution time
        sorted_results = sorted(results, key=lambda r: r.execution_time_sec if r.success else float('inf'))

        fastest = sorted_results[0]
        print(f"Fastest: {fastest.tool_name} ({fastest.execution_time_sec:.3f}s)")

        for result in sorted_results[1:]:
            if result.success:
                speedup = result.execution_time_sec / fastest.execution_time_sec
                print(f"  {result.tool_name}: {speedup:.2f}x slower")

    # Export results
    benchmark.export_results(suite, output_file, output_format)
    print(f"\n✓ Benchmark report saved to: {output_file}")

if __name__ == '__main__':
    main()
PYTHON_EOF

# Export environment variables
export PROJECT_ROOT
export SCENARIO
export TOOLS="${TOOLS[@]}"
TOOLS="${TOOLS// /,}"  # Convert to comma-separated
export TOOLS
export ITERATIONS
export MESSAGES
export OUTPUT
export FORMAT
export COMPARE
export VERBOSE

# Run benchmark
echo ""
echo "=== Tool Performance Benchmark ==="
echo ""

python3 "$TMP_SCRIPT"
EXIT_CODE=$?

# Cleanup
rm -f "$TMP_SCRIPT"

# Show preview for markdown files
if [[ $EXIT_CODE -eq 0 ]] && [[ "$FORMAT" == "markdown" ]] && [[ -f "$OUTPUT" ]]; then
    echo ""
    echo "=== Report Preview ==="
    echo ""
    cat "$OUTPUT"
fi

exit $EXIT_CODE

#!/usr/bin/env bash
#
# Tool Detection Command
#
# Scans system for installed automotive development tools including:
# - Commercial: Vector, ETAS, dSPACE, Lauterbach
# - Opensource: cantools, QEMU, Renode, Arctic Core
# - Build tools: CMake, GCC, Bazel
# - Analysis: cppcheck, clang-tidy
#
# Usage:
#   tool-detect [options]
#
# Options:
#   --category CATEGORY    Detect tools in specific category
#   --format FORMAT        Output format: json|markdown|html (default: markdown)
#   --output FILE          Output file path (default: stdout)
#   --commercial           Detect only commercial tools
#   --opensource           Detect only opensource tools
#   --available            Show only available tools
#   --check-licenses       Validate commercial licenses
#   --verbose              Show detailed detection info
#
# Examples:
#   tool-detect                                    # Detect all tools
#   tool-detect --category vehicle_network        # CAN/network tools only
#   tool-detect --opensource --available          # Available OSS tools
#   tool-detect --format json --output report.json
#   tool-detect --check-licenses                  # Validate licenses

set -euo pipefail

# Default configuration
CATEGORY=""
FORMAT="markdown"
OUTPUT=""
COMMERCIAL=false
OPENSOURCE=false
AVAILABLE_ONLY=false
CHECK_LICENSES=false
VERBOSE=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --category)
            CATEGORY="$2"
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
        --commercial)
            COMMERCIAL=true
            shift
            ;;
        --opensource)
            OPENSOURCE=true
            shift
            ;;
        --available)
            AVAILABLE_ONLY=true
            shift
            ;;
        --check-licenses)
            CHECK_LICENSES=true
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
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set output file
if [[ -z "$OUTPUT" ]]; then
    OUTPUT="/tmp/tool_detection_$(date +%Y%m%d_%H%M%S).$FORMAT"
fi

# Build Python command
PYTHON_CMD="python3 $PROJECT_ROOT/tools/detectors/tool_detector.py"

# Create temporary Python script to run detection
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" <<'PYTHON_EOF'
import sys
import os
import json
import logging

# Add project root to path
sys.path.insert(0, os.environ.get('PROJECT_ROOT'))

from tools.detectors.tool_detector import ToolDetector

# Configure logging
log_level = logging.DEBUG if os.environ.get('VERBOSE') == 'true' else logging.INFO
logging.basicConfig(level=log_level, format='%(levelname)s: %(message)s')

def main():
    detector = ToolDetector()

    # Detect all tools
    print("Scanning system for automotive tools...")
    results = detector.detect_all_tools()

    # Filter by category if specified
    category = os.environ.get('CATEGORY', '')
    if category:
        if category not in results:
            print(f"Error: Unknown category '{category}'", file=sys.stderr)
            print(f"Available categories: {', '.join(results.keys())}", file=sys.stderr)
            sys.exit(1)
        results = {category: results[category]}

    # Filter by commercial/opensource
    if os.environ.get('COMMERCIAL') == 'true':
        for cat in results:
            results[cat] = [t for t in results[cat] if not t.is_opensource]
    elif os.environ.get('OPENSOURCE') == 'true':
        for cat in results:
            results[cat] = [t for t in results[cat] if t.is_opensource]

    # Filter by availability
    if os.environ.get('AVAILABLE_ONLY') == 'true':
        for cat in results:
            results[cat] = [t for t in results[cat] if t.is_available]

    # Print summary
    total_tools = sum(len(tools) for tools in results.values())
    available_tools = sum(len([t for t in tools if t.is_available]) for tools in results.values())

    print(f"\nDetected {available_tools}/{total_tools} available tools")
    print(f"Categories: {', '.join(results.keys())}")

    # Check licenses if requested
    if os.environ.get('CHECK_LICENSES') == 'true':
        print("\nValidating commercial licenses...")
        from tools.detectors.license_detector import LicenseDetector

        license_detector = LicenseDetector()
        commercial_tools = []

        for cat_tools in results.values():
            commercial_tools.extend([t.name for t in cat_tools if not t.is_opensource and t.is_available])

        if commercial_tools:
            license_results = license_detector.check_all_licenses(commercial_tools)

            valid_count = sum(1 for info in license_results.values() if info.is_valid)
            print(f"License validation: {valid_count}/{len(commercial_tools)} valid")

            for tool_name, license_info in license_results.items():
                status = "✓" if license_info.is_valid else "✗"
                print(f"  {status} {tool_name}: {license_info.license_type}")

    # Export report
    output_file = os.environ.get('OUTPUT')
    output_format = os.environ.get('FORMAT', 'markdown')

    print(f"\nGenerating {output_format} report...")
    detector.export_report(output_file, output_format)
    print(f"✓ Report saved to: {output_file}")

if __name__ == '__main__':
    main()
PYTHON_EOF

# Export environment variables for Python script
export PROJECT_ROOT
export CATEGORY
export FORMAT
export OUTPUT
export COMMERCIAL
export OPENSOURCE
export AVAILABLE_ONLY
export CHECK_LICENSES
export VERBOSE

# Run detection
python3 "$TMP_SCRIPT"

# Cleanup
rm -f "$TMP_SCRIPT"

# Display output if stdout
if [[ "$FORMAT" == "markdown" ]] && [[ -f "$OUTPUT" ]]; then
    echo ""
    echo "=== Tool Detection Report ==="
    echo ""
    head -50 "$OUTPUT"

    # Count total lines
    TOTAL_LINES=$(wc -l < "$OUTPUT")
    if [[ $TOTAL_LINES -gt 50 ]]; then
        echo ""
        echo "... (showing first 50 lines of $TOTAL_LINES)"
        echo "Full report: $OUTPUT"
    fi
fi

exit 0

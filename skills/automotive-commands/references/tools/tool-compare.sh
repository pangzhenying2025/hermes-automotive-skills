#!/usr/bin/env bash
#
# Tool Comparison Command
#
# Generates feature comparison matrices between commercial and opensource
# automotive development tools.
#
# Usage:
#   tool-compare [options] <category|commercial_tool>
#
# Options:
#   --format FORMAT        Output format: markdown|json|html (default: markdown)
#   --output FILE          Output file path
#   --all                  Compare all categories
#   --show-costs           Include cost savings estimates
#   --migration            Include migration difficulty assessment
#   --use-cases            Show recommended use cases
#   --verbose              Show detailed information
#
# Categories:
#   vehicle_network        CAN/LIN/FlexRay tools (CANoe vs cantools)
#   autosar                AUTOSAR tools (DaVinci vs Arctic Core)
#   simulation             ECU simulators (VEOS vs QEMU/Renode)
#   calibration            Calibration tools (INCA vs Panda)
#   testing                Test frameworks (VectorCAST vs GoogleTest)
#   static_analysis        Static analyzers (Polyspace vs cppcheck)
#
# Examples:
#   tool-compare vehicle_network              # CAN tool comparison
#   tool-compare --all --format html          # All categories to HTML
#   tool-compare canoe --show-costs           # CANoe alternatives with costs
#   tool-compare simulation --migration       # Migration assessment

set -euo pipefail

# Default configuration
CATEGORY=""
FORMAT="markdown"
OUTPUT=""
ALL=false
SHOW_COSTS=false
MIGRATION=false
USE_CASES=false
VERBOSE=false

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --all)
            ALL=true
            shift
            ;;
        --show-costs)
            SHOW_COSTS=true
            shift
            ;;
        --migration)
            MIGRATION=true
            shift
            ;;
        --use-cases)
            USE_CASES=true
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
            if [[ -z "$CATEGORY" ]]; then
                CATEGORY="$1"
            else
                echo "Error: Multiple categories specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate input
if [[ -z "$CATEGORY" ]] && [[ "$ALL" != "true" ]]; then
    echo "Error: Category required (or use --all)"
    echo "Use --help for usage information"
    exit 1
fi

# Set output directory
if [[ -z "$OUTPUT" ]]; then
    if [[ "$ALL" == "true" ]]; then
        OUTPUT="/tmp/tool_comparisons"
        mkdir -p "$OUTPUT"
    else
        OUTPUT="/tmp/comparison_${CATEGORY}_$(date +%Y%m%d_%H%M%S).$FORMAT"
    fi
fi

# Create Python comparison script
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" <<'PYTHON_EOF'
import sys
import os
import logging

sys.path.insert(0, os.environ.get('PROJECT_ROOT'))

from tools.comparators.tool_comparator import ToolComparator

# Configure logging
log_level = logging.DEBUG if os.environ.get('VERBOSE') == 'true' else logging.INFO
logging.basicConfig(level=log_level, format='%(levelname)s: %(message)s')

def print_comparison_summary(matrix):
    """Print comparison summary to console."""
    print(f"\n=== {matrix.category.replace('_', ' ').title()} Comparison ===\n")

    print(f"Commercial: {matrix.commercial_tool.name} ({matrix.commercial_tool.vendor})")
    print(f"Opensource: {', '.join(t.name for t in matrix.opensource_tools)}")

    if os.environ.get('SHOW_COSTS') == 'true':
        print(f"\nCost Savings: {matrix.cost_savings_estimate}")

    if os.environ.get('MIGRATION') == 'true':
        print(f"Migration Difficulty: {matrix.migration_difficulty}")

    if os.environ.get('USE_CASES') == 'true':
        print("\nRecommended Use Cases:")
        for use_case, tool in matrix.use_cases.items():
            print(f"  - {use_case}: {tool}")

    # Feature summary
    full_support = sum(1 for f in matrix.feature_comparisons
                      if f.opensource_support.value == 'full')
    total_features = len(matrix.feature_comparisons)

    print(f"\nFeature Coverage: {full_support}/{total_features} fully supported")
    print(f"Recommendation: {matrix.recommendation}")

def main():
    category = os.environ.get('CATEGORY')
    all_categories = os.environ.get('ALL') == 'true'
    output = os.environ.get('OUTPUT')
    output_format = os.environ.get('FORMAT', 'markdown')

    comparator = ToolComparator()

    if all_categories:
        print("Generating comparisons for all categories...")
        comparator.export_all_comparisons(output, output_format)
        print(f"\n✓ All comparisons exported to: {output}")

        # Print summary
        print("\nCategories compared:")
        for cat in comparator.get_all_categories():
            matrix = comparator.compare_category(cat)
            if matrix:
                oss_names = ', '.join(t.name for t in matrix.opensource_tools)
                print(f"  - {cat}: {matrix.commercial_tool.name} vs {oss_names}")

    else:
        # Single category comparison
        print(f"Comparing {category} tools...")

        # Try as category first
        matrix = comparator.compare_category(category)

        if not matrix:
            # Try as commercial tool name
            print(f"'{category}' not found as category, treating as tool name...")
            # Find tool and its category
            tool_found = False
            for tool_name, tool_info in comparator.tool_db.items():
                if tool_name.lower() == category.lower():
                    matrix = comparator.compare_category(tool_info.category)
                    tool_found = True
                    break

            if not tool_found:
                print(f"Error: Unknown category or tool '{category}'")
                print(f"\nAvailable categories:")
                for cat in comparator.get_all_categories():
                    print(f"  - {cat}")
                sys.exit(1)

        # Print summary
        print_comparison_summary(matrix)

        # Export detailed report
        comparator.export_comparison_matrix(matrix, output, output_format)
        print(f"\n✓ Detailed comparison exported to: {output}")

if __name__ == '__main__':
    main()
PYTHON_EOF

# Export environment variables
export PROJECT_ROOT
export CATEGORY
export FORMAT
export OUTPUT
export ALL
export SHOW_COSTS
export MIGRATION
export USE_CASES
export VERBOSE

# Run comparison
echo ""
echo "=== Tool Comparison System ==="
echo ""

python3 "$TMP_SCRIPT"
EXIT_CODE=$?

# Cleanup
rm -f "$TMP_SCRIPT"

# Show preview for markdown files
if [[ $EXIT_CODE -eq 0 ]] && [[ "$FORMAT" == "markdown" ]] && [[ -f "$OUTPUT" ]] && [[ "$ALL" != "true" ]]; then
    echo ""
    echo "=== Report Preview ==="
    echo ""
    head -30 "$OUTPUT"
    echo ""
    echo "... (Full report in $OUTPUT)"
fi

exit $EXIT_CODE

#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Cyclomatic Complexity Checker Hook
################################################################################
# Purpose: Check cyclomatic complexity of functions in staged C/C++ files
# Limit: Max complexity 15 per function (configurable)
# Uses lizard if available, grep heuristic otherwise
################################################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

readonly MAX_COMPLEXITY=15
violations_found=0

echo -e "${YELLOW}Checking cyclomatic complexity (max: $MAX_COMPLEXITY)...${NC}"

# Get staged C/C++ files
mapfile -t staged_files < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(c|cpp|cc|cxx)$' || true)

if [ ${#staged_files[@]} -eq 0 ]; then
    echo -e "${GREEN}No C/C++ files staged for complexity check${NC}"
    exit 0
fi

################################################################################
# Function: Calculate complexity using lizard
################################################################################
check_with_lizard() {
    local file="$1"
    
    if ! command -v lizard &> /dev/null; then
        return 1
    fi
    
    echo "  Using lizard for complexity analysis..."
    
    # Run lizard and check for functions exceeding threshold
    lizard -l c "$file" -C $MAX_COMPLEXITY --warning-only 2>&1 | grep -E "(NLOC|warning)" || true
    
    # Check if any warnings found
    if lizard -l c "$file" -C $MAX_COMPLEXITY --warning-only 2>&1 | grep -q "warning"; then
        return 1
    fi
    
    return 0
}

################################################################################
# Function: Estimate complexity using grep heuristic
################################################################################
estimate_complexity_heuristic() {
    local file="$1"
    local file_violations=0
    
    echo "  Using heuristic complexity estimation..."
    
    # Extract function names and count decision points
    while IFS= read -r func_start; do
        local line_num=$(echo "$func_start" | cut -d: -f1)
        local func_name=$(echo "$func_start" | sed -E 's/.*\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(.*/\1/')
        
        # Find function body (from { to matching })
        local func_end=$(awk -v start=$line_num '
            NR >= start {
                if ($0 ~ /{/) brace_count++
                if ($0 ~ /}/) brace_count--
                if (brace_count == 0 && NR > start) { print NR; exit }
            }
        ' "$file")
        
        if [ -z "$func_end" ]; then
            continue
        fi
        
        # Count decision points (if, while, for, case, &&, ||, ?)
        local complexity=1  # Base complexity
        complexity=$((complexity + $(sed -n "${line_num},${func_end}p" "$file" | grep -oE '\b(if|while|for|case)\b' | wc -l)))
        complexity=$((complexity + $(sed -n "${line_num},${func_end}p" "$file" | grep -oE '(&&|\|\|)' | wc -l)))
        complexity=$((complexity + $(sed -n "${line_num},${func_end}p" "$file" | grep -oE '\?' | wc -l)))
        
        if [ $complexity -gt $MAX_COMPLEXITY ]; then
            echo -e "${RED}High complexity in $file:${NC}"
            echo "  Function '$func_name' at line $line_num has estimated complexity $complexity (max: $MAX_COMPLEXITY)"
            file_violations=1
        fi
    done < <(grep -nE '^[A-Za-z_][A-Za-z0-9_*\s]+[A-Za-z_][A-Za-z0-9_]*\s*\([^;]*\)\s*\{' "$file" | grep -v 'static inline' || true)
    
    return $file_violations
}

################################################################################
# Main check logic
################################################################################
for file in "${staged_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    echo "Checking complexity: $file"
    
    # Try lizard first, fall back to heuristic
    if ! check_with_lizard "$file"; then
        # Lizard not available or found violations
        if ! command -v lizard &> /dev/null; then
            estimate_complexity_heuristic "$file" || violations_found=1
        else
            violations_found=1
        fi
    fi
done

################################################################################
# Summary
################################################################################
echo ""
echo "========================================"
if [ $violations_found -eq 0 ]; then
    echo -e "${GREEN}Complexity check PASSED${NC}"
    echo "All functions have complexity <= $MAX_COMPLEXITY"
    exit 0
else
    echo -e "${RED}Complexity violations found${NC}"
    echo "Refactor functions to reduce complexity:"
    echo "  - Extract helper functions"
    echo "  - Simplify conditional logic"
    echo "  - Use lookup tables instead of nested if/else"
    echo ""
    echo "Install lizard for accurate analysis: pip install lizard"
    echo ""
    echo "To bypass (NOT RECOMMENDED): git commit --no-verify"
    exit 1
fi

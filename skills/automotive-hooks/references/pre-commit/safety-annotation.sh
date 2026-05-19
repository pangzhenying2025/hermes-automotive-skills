#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ISO 26262 Safety Annotation Validator Hook
################################################################################
# Purpose: Ensure safety-relevant code has proper ASIL annotations
# Checks:
#   - Functions with @safety_relevant tag must have @asil_level annotation
#   - ASIL level must be valid: QM, A, B, C, or D
#   - ASIL-D functions must reference unit tests
#   - Safety code must not use prohibited patterns (malloc, setjmp, signals)
# Exit codes:
#   0 - All safety annotations valid
#   1 - Missing or invalid annotations found
################################################################################

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Track violations
violations_found=0
warnings_found=0

echo -e "${YELLOW}Running ISO 26262 safety annotation check...${NC}"

# Get staged C/C++ files
mapfile -t staged_files < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(c|cpp|cc|cxx|h|hpp|hxx)$' || true)

if [ ${#staged_files[@]} -eq 0 ]; then
    echo -e "${GREEN}No C/C++ files staged, skipping safety annotation check${NC}"
    exit 0
fi

echo "Checking ${#staged_files[@]} C/C++ file(s) for safety annotations..."

################################################################################
# Function: Check safety annotations in a file
################################################################################
check_safety_annotations() {
    local file="$1"
    local line_num=0
    local in_function=false
    local function_name=""
    local is_safety_relevant=false
    local has_asil_level=false
    local asil_level=""
    local has_test_ref=false
    local function_start_line=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for safety_relevant tag
        if [[ "$line" =~ @safety_relevant ]]; then
            is_safety_relevant=true
            function_start_line=$line_num
        fi

        # Check for asil_level tag
        if [[ "$line" =~ @asil_level[[:space:]]*([A-D]|QM) ]]; then
            has_asil_level=true
            asil_level="${BASH_REMATCH[1]}"
        fi

        # Check for test reference
        if [[ "$line" =~ @test[[:space:]]*[A-Za-z0-9_]+ ]]; then
            has_test_ref=true
        fi

        # Detect function definition
        if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_:]*[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\( ]]; then
            function_name="${BASH_REMATCH[1]}"

            # Validate safety-relevant function
            if [ "$is_safety_relevant" = true ]; then
                if [ "$has_asil_level" = false ]; then
                    echo -e "${RED}$file:$function_start_line: Error: Function '$function_name' has @safety_relevant but missing @asil_level${NC}"
                    violations_found=1
                else
                    echo -e "${BLUE}$file:$line_num: Info: Safety function '$function_name' (ASIL $asil_level)${NC}"

                    # ASIL-D functions must have test references
                    if [ "$asil_level" = "D" ] && [ "$has_test_ref" = false ]; then
                        echo -e "${RED}$file:$line_num: Error: ASIL-D function '$function_name' must have @test reference${NC}"
                        violations_found=1
                    fi
                fi
            fi

            # Reset for next function
            is_safety_relevant=false
            has_asil_level=false
            has_test_ref=false
            asil_level=""
        fi

        # Check for invalid ASIL levels
        if [[ "$line" =~ @asil_level[[:space:]]*([^A-DQM]) ]]; then
            echo -e "${RED}$file:$line_num: Error: Invalid ASIL level '${BASH_REMATCH[1]}'. Must be QM, A, B, C, or D${NC}"
            violations_found=1
        fi

    done < "$file"
}

################################################################################
# Function: Check prohibited patterns in safety code
################################################################################
check_prohibited_patterns() {
    local file="$1"
    local in_safety_function=false
    local function_name=""
    local violations=0

    # Check if file has any safety annotations
    if ! grep -q "@safety_relevant" "$file" 2>/dev/null; then
        return 0
    fi

    echo ""
    echo "Checking prohibited patterns in safety code: $file"

    # Prohibited: malloc/free family
    if grep -n "@safety_relevant" "$file" -A 50 | grep -E "\b(malloc|calloc|realloc|free)\s*\(" 2>/dev/null; then
        echo -e "${RED}$file: Error: Dynamic memory allocation (malloc/free) prohibited in safety-relevant code${NC}"
        violations=1
    fi

    # Prohibited: setjmp/longjmp
    if grep -n "@safety_relevant" "$file" -A 50 | grep -E "\b(setjmp|longjmp)\s*\(" 2>/dev/null; then
        echo -e "${RED}$file: Error: setjmp/longjmp prohibited in safety-relevant code${NC}"
        violations=1
    fi

    # Prohibited: signal handlers
    if grep -n "@safety_relevant" "$file" -A 50 | grep -E "\b(signal|raise|abort)\s*\(" 2>/dev/null; then
        echo -e "${RED}$file: Error: Signal handlers prohibited in safety-relevant code${NC}"
        violations=1
    fi

    # Prohibited: recursion (simplified check - looks for function calling itself)
    local func_names
    func_names=$(grep -A 1 "@safety_relevant" "$file" | grep -oE "^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)" | awk '{print $2}' || true)

    for func in $func_names; do
        if grep -A 50 "^.*$func\s*(" "$file" | grep -E "\b$func\s*\(" | grep -v "^.*$func\s*(" | head -1 2>/dev/null; then
            echo -e "${YELLOW}$file: Warning: Potential recursion in safety function '$func' (ISO 26262 discourages recursion)${NC}"
            warnings_found=1
        fi
    done

    # Warning: printf/fprintf in safety code (should use safe logging)
    if grep -n "@safety_relevant" "$file" -A 50 | grep -E "\b(printf|fprintf|sprintf)\s*\(" 2>/dev/null; then
        echo -e "${YELLOW}$file: Warning: Consider using safe logging instead of printf family in safety code${NC}"
        warnings_found=1
    fi

    return $violations
}

################################################################################
# Function: Verify ASIL consistency
################################################################################
verify_asil_consistency() {
    local file="$1"

    # Check if higher ASIL functions call lower ASIL functions (should warn)
    local high_asil_funcs
    high_asil_funcs=$(grep -B 5 "@asil_level[[:space:]]*[CD]" "$file" | grep -oE "^[a-zA-Z_][a-zA-Z0-9_]*" | head -10 || true)

    if [ -n "$high_asil_funcs" ]; then
        echo -e "${BLUE}Info: File contains ASIL C/D functions, verify call graph integrity${NC}"
    fi
}

################################################################################
# Main check logic
################################################################################
for file in "${staged_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    echo ""
    echo "Analyzing: $file"

    # Check annotations
    check_safety_annotations "$file"

    # Check prohibited patterns
    check_prohibited_patterns "$file" || violations_found=1

    # Verify ASIL consistency
    verify_asil_consistency "$file"
done

################################################################################
# Summary
################################################################################
echo ""
echo "========================================"
if [ $violations_found -eq 0 ]; then
    echo -e "${GREEN}Safety annotation check PASSED${NC}"
    if [ $warnings_found -gt 0 ]; then
        echo -e "${YELLOW}$warnings_found warning(s) found - review recommended${NC}"
    fi
    echo "All safety-relevant code properly annotated"
    exit 0
else
    echo -e "${RED}Safety annotation check FAILED${NC}"
    echo "$violations_found violation(s) detected"
    echo ""
    echo "Safety annotation requirements:"
    echo "  - @safety_relevant functions MUST have @asil_level (QM/A/B/C/D)"
    echo "  - ASIL-D functions MUST have @test reference"
    echo "  - No malloc/free, setjmp/longjmp, or signal handlers in safety code"
    echo ""
    echo "To bypass (NOT RECOMMENDED for safety-critical code):"
    echo "  git commit --no-verify"
    exit 1
fi

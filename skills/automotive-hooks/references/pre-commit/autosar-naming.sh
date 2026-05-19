#!/usr/bin/env bash
set -euo pipefail

################################################################################
# AUTOSAR Naming Convention Checker Hook
################################################################################
# Purpose: Verify AUTOSAR naming conventions in staged C/C++ files
# Checks:
#   - Module_Function naming for AUTOSAR APIs
#   - PascalCase for types without _t suffix
#   - Correct file naming (Module_Cfg.h, Module.c pattern)
################################################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

violations_found=0

echo -e "${YELLOW}Checking AUTOSAR naming conventions...${NC}"

# Get staged C/C++ files
mapfile -t staged_files < <(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(c|h)$' || true)

if [ ${#staged_files[@]} -eq 0 ]; then
    echo -e "${GREEN}No C/C++ files staged for AUTOSAR naming check${NC}"
    exit 0
fi

################################################################################
# Function: Check AUTOSAR API naming (Module_Function)
################################################################################
check_autosar_api_naming() {
    local file="$1"
    local file_violations=0
    
    # Check for function definitions that should follow Module_Function pattern
    # Look for public function definitions (not static)
    while IFS= read -r line; do
        # Check for function definitions like: ReturnType FunctionName(...)
        if echo "$line" | grep -qE '^[A-Za-z_][A-Za-z0-9_]*\s+[A-Za-z][A-Za-z0-9_]*\s*\('; then
            func_name=$(echo "$line" | sed -E 's/^[A-Za-z_][A-Za-z0-9_]*\s+([A-Za-z][A-Za-z0-9_]*)\s*\(.*/\1/')
            
            # Check if it follows Module_Function pattern (PascalCase_PascalCase)
            if ! echo "$func_name" | grep -qE '^[A-Z][a-z0-9]+_[A-Z][a-zA-Z0-9]*$'; then
                echo -e "${RED}AUTOSAR naming violation in $file:${NC}"
                echo "  Function '$func_name' should follow Module_Function pattern (e.g., Can_Write, Adc_StartConversion)"
                file_violations=1
            fi
        fi
    done < <(grep -nE '^[A-Za-z_][A-Za-z0-9_]*\s+[A-Za-z][A-Za-z0-9_]*\s*\(' "$file" | grep -v 'static' || true)
    
    return $file_violations
}

################################################################################
# Function: Check AUTOSAR type naming (no _t suffix)
################################################################################
check_autosar_type_naming() {
    local file="$1"
    local file_violations=0
    
    # Check for typedef with _t suffix (AUTOSAR doesn't use _t)
    if grep -nE 'typedef\s+.*\s+[A-Za-z][A-Za-z0-9_]*_t\s*;' "$file"; then
        echo -e "${YELLOW}Warning in $file: AUTOSAR types should not have _t suffix${NC}"
        echo "  Example: 'typedef uint8 CanChannelType;' not 'CanChannelType_t'"
        # Don't fail on this, just warn
    fi
    
    return $file_violations
}

################################################################################
# Function: Check AUTOSAR file naming
################################################################################
check_autosar_file_naming() {
    local file="$1"
    local filename=$(basename "$file")
    local file_violations=0
    
    # AUTOSAR file pattern: Module_Component.ext or Module.ext
    # Examples: Can_Cfg.h, Adc.c, Port_Cfg.c
    if [[ "$filename" =~ ^[A-Z][a-z]+ ]]; then
        if ! echo "$filename" | grep -qE '^[A-Z][a-z]+(_[A-Z][a-z]+)?\.(c|h)$'; then
            echo -e "${YELLOW}Info: $filename might not follow AUTOSAR naming${NC}"
            echo "  Expected pattern: Module_Component.ext (e.g., Can_Cfg.h, Adc.c)"
            # Don't fail, just inform
        fi
    fi
    
    return $file_violations
}

################################################################################
# Main check logic
################################################################################
for file in "${staged_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # Skip files not in AUTOSAR-style directories
    if [[ ! "$file" =~ (autosar|AUTOSAR|mcal|MCAL|rte|RTE) ]]; then
        continue
    fi
    
    echo "Checking AUTOSAR naming: $file"
    
    check_autosar_api_naming "$file" || violations_found=1
    check_autosar_type_naming "$file" || violations_found=1
    check_autosar_file_naming "$file" || violations_found=1
done

################################################################################
# Summary
################################################################################
echo ""
echo "========================================"
if [ $violations_found -eq 0 ]; then
    echo -e "${GREEN}AUTOSAR naming check PASSED${NC}"
    exit 0
else
    echo -e "${RED}AUTOSAR naming violations found${NC}"
    echo "Please fix naming to follow AUTOSAR conventions:"
    echo "  - API functions: Module_Function (e.g., Can_Write)"
    echo "  - Types: PascalCase without _t suffix (e.g., CanChannelType)"
    echo "  - Files: Module_Component.ext (e.g., Can_Cfg.h)"
    echo ""
    echo "To bypass (NOT RECOMMENDED): git commit --no-verify"
    exit 1
fi

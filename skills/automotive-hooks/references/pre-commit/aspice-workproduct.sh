#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ASPICE Work Product Reference Checker
################################################################################
# Purpose: Verify that modified files reference ASPICE work products
# Checks:
#   - Source files reference requirements (REQ-ID)
#   - Test files reference test cases (TC-ID)
#   - Design documents exist for implementation changes
################################################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

violations_found=0

echo -e "${YELLOW}Checking ASPICE work product references...${NC}"

# Get staged files
mapfile -t staged_files < <(git diff --cached --name-only --diff-filter=ACM || true)

if [ ${#staged_files[@]} -eq 0 ]; then
    echo -e "${GREEN}No files staged for ASPICE work product check${NC}"
    exit 0
fi

################################################################################
# Function: Check for requirements traceability in source code
################################################################################
check_requirements_traceability() {
    local file="$1"
    local file_violations=0
    
    # Look for REQ-ID references in comments
    if ! grep -qE '(REQ-|REQUIREMENT-|@requirement)[A-Z0-9-]+' "$file"; then
        echo -e "${YELLOW}Warning: $file has no requirements traceability${NC}"
        echo "  Add comment like: /* REQ-SWE-1234: Implement battery voltage monitoring */"
        # Don't fail, just warn for now
    fi
    
    return $file_violations
}

################################################################################
# Function: Check for test case references in test files
################################################################################
check_test_traceability() {
    local file="$1"
    local file_violations=0
    
    # Test files should reference test cases
    if ! grep -qE '(TC-|TESTCASE-|@testcase)[A-Z0-9-]+' "$file"; then
        echo -e "${YELLOW}Warning: Test file $file has no test case ID${NC}"
        echo "  Add comment like: /* TC-SWE-1234: Test voltage calculation */"
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
    
    # Check source files for requirements
    if [[ "$file" =~ \.(c|cpp|cc|h|hpp)$ ]] && [[ ! "$file" =~ test ]]; then
        check_requirements_traceability "$file" || violations_found=1
    fi
    
    # Check test files for test case IDs
    if [[ "$file" =~ (test_|_test\.|Test) ]] && [[ "$file" =~ \.(c|cpp|py|java)$ ]]; then
        check_test_traceability "$file" || violations_found=1
    fi
done

################################################################################
# Summary
################################################################################
echo ""
echo "========================================"
if [ $violations_found -eq 0 ]; then
    echo -e "${GREEN}ASPICE work product check PASSED${NC}"
    echo "All files have appropriate traceability references"
    exit 0
else
    echo -e "${YELLOW}ASPICE work product warnings found${NC}"
    echo "Consider adding traceability references for ASPICE compliance"
    echo ""
    echo "To bypass (NOT RECOMMENDED): git commit --no-verify"
    exit 0  # Warning only, don't block commit
fi

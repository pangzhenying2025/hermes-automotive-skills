#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Integration Test Hook (Pre-Merge)
################################################################################
# Purpose: Run integration tests before merging to main/master
# Prevents broken code from entering main branch
################################################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

echo -e "${YELLOW}Running integration tests before merge...${NC}"

# Detect test framework and run appropriate tests
run_integration_tests() {
    # Check for CMake/CTest
    if [ -f "CMakeLists.txt" ] && [ -d "build" ]; then
        echo "Running CTest integration tests..."
        cd build
        ctest --output-on-failure -L integration || return 1
        cd ..
        return 0
    fi
    
    # Check for Python pytest
    if [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
        echo "Running pytest integration tests..."
        pytest tests/ -v -m integration || return 1
        return 0
    fi
    
    # Check for Maven (Java)
    if [ -f "pom.xml" ]; then
        echo "Running Maven integration tests..."
        mvn verify -DskipUnitTests || return 1
        return 0
    fi
    
    # Check for Gradle (Java)
    if [ -f "build.gradle" ]; then
        echo "Running Gradle integration tests..."
        ./gradlew integrationTest || return 1
        return 0
    fi
    
    echo -e "${YELLOW}No integration test framework detected${NC}"
    echo "Configure one of: CTest, pytest, Maven, or Gradle"
    return 0  # Don't block if no tests configured
}

# Run tests
if run_integration_tests; then
    echo ""
    echo -e "${GREEN}Integration tests PASSED${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Integration tests FAILED${NC}"
    echo "Fix failing tests before merging to main branch"
    exit 1
fi

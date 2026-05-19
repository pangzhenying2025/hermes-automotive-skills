#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Test Runner Pre-Push Hook
################################################################################
# Purpose: Run tests before pushing to remote repository
# Features:
#   - Auto-detects project type (Python/C++/Java)
#   - Runs pytest, ctest, or mvn test as appropriate
#   - Executes custom test scripts if present
#   - Reports test summary (passed/failed/skipped)
#   - Can be skipped via SKIP_TESTS=1 environment variable
# Exit codes:
#   0 - All tests passed
#   1 - Test failures detected
################################################################################

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Check for skip flag
if [ "${SKIP_TESTS:-0}" = "1" ]; then
    echo -e "${YELLOW}SKIP_TESTS=1 set, skipping test execution${NC}"
    exit 0
fi

echo -e "${YELLOW}Running tests before push...${NC}"

# Track test results
tests_run=false
tests_passed=false
tests_failed=false

################################################################################
# Function: Detect project type
################################################################################
detect_project_type() {
    local types=""

    # Check for Python
    if [ -f "pytest.ini" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ] || [ -d "tests" ]; then
        if ls tests/*.py &>/dev/null || ls test_*.py &>/dev/null; then
            types="$types python"
        fi
    fi

    # Check for C++
    if [ -f "CMakeLists.txt" ] || [ -d "build" ]; then
        if [ -d "build" ] && [ -f "build/Makefile" ]; then
            types="$types cpp"
        fi
    fi

    # Check for Java
    if [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        types="$types java"
    fi

    echo "$types"
}

################################################################################
# Function: Run Python tests
################################################################################
run_python_tests() {
    echo ""
    echo -e "${BLUE}=== Running Python tests ===${NC}"

    if ! command -v pytest &> /dev/null; then
        echo -e "${YELLOW}pytest not found, skipping Python tests${NC}"
        return 0
    fi

    # Run pytest with coverage if available
    local pytest_args="--verbose"
    if pytest --co -q &>/dev/null | grep -q "test session starts"; then
        pytest_args="$pytest_args --tb=short"
    fi

    echo "Running: pytest $pytest_args"

    if pytest $pytest_args 2>&1 | tee /tmp/pytest_output.txt; then
        echo -e "${GREEN}Python tests PASSED${NC}"
        tests_passed=true
    else
        echo -e "${RED}Python tests FAILED${NC}"
        tests_failed=true
        return 1
    fi

    # Extract summary
    if [ -f /tmp/pytest_output.txt ]; then
        local summary
        summary=$(grep -E "passed|failed|skipped|error" /tmp/pytest_output.txt | tail -1 || true)
        if [ -n "$summary" ]; then
            echo "Summary: $summary"
        fi
        rm -f /tmp/pytest_output.txt
    fi

    tests_run=true
    return 0
}

################################################################################
# Function: Run C++ tests
################################################################################
run_cpp_tests() {
    echo ""
    echo -e "${BLUE}=== Running C++ tests ===${NC}"

    if [ ! -d "build" ]; then
        echo -e "${YELLOW}build/ directory not found, skipping C++ tests${NC}"
        echo "Run 'cmake -B build && cmake --build build' to build tests"
        return 0
    fi

    cd build

    if ! command -v ctest &> /dev/null; then
        echo -e "${YELLOW}ctest not found, skipping C++ tests${NC}"
        cd ..
        return 0
    fi

    # Check if tests are built
    if ! ctest -N &>/dev/null; then
        echo -e "${YELLOW}No CTest tests found, skipping${NC}"
        cd ..
        return 0
    fi

    echo "Running: ctest --output-on-failure"

    if ctest --output-on-failure 2>&1 | tee /tmp/ctest_output.txt; then
        echo -e "${GREEN}C++ tests PASSED${NC}"
        tests_passed=true
    else
        echo -e "${RED}C++ tests FAILED${NC}"
        tests_failed=true
        cd ..
        return 1
    fi

    # Extract summary
    if [ -f /tmp/ctest_output.txt ]; then
        local summary
        summary=$(grep -E "tests passed|tests failed" /tmp/ctest_output.txt | tail -1 || true)
        if [ -n "$summary" ]; then
            echo "Summary: $summary"
        fi
        rm -f /tmp/ctest_output.txt
    fi

    cd ..
    tests_run=true
    return 0
}

################################################################################
# Function: Run Java tests
################################################################################
run_java_tests() {
    echo ""
    echo -e "${BLUE}=== Running Java tests ===${NC}"

    # Maven tests
    if [ -f "pom.xml" ]; then
        if ! command -v mvn &> /dev/null; then
            echo -e "${YELLOW}Maven not found, skipping Java tests${NC}"
            return 0
        fi

        echo "Running: mvn test"

        if mvn test -B 2>&1 | tee /tmp/mvn_output.txt; then
            echo -e "${GREEN}Java tests PASSED${NC}"
            tests_passed=true
        else
            echo -e "${RED}Java tests FAILED${NC}"
            tests_failed=true
            return 1
        fi

        # Extract summary
        if [ -f /tmp/mvn_output.txt ]; then
            local summary
            summary=$(grep -E "Tests run:|BUILD SUCCESS|BUILD FAILURE" /tmp/mvn_output.txt | tail -3 || true)
            if [ -n "$summary" ]; then
                echo "Summary:"
                echo "$summary"
            fi
            rm -f /tmp/mvn_output.txt
        fi

        tests_run=true
        return 0
    fi

    # Gradle tests
    if [ -f "build.gradle" ]; then
        if ! command -v gradle &> /dev/null; then
            echo -e "${YELLOW}Gradle not found, skipping Java tests${NC}"
            return 0
        fi

        echo "Running: gradle test"

        if gradle test 2>&1 | tee /tmp/gradle_output.txt; then
            echo -e "${GREEN}Java tests PASSED${NC}"
            tests_passed=true
        else
            echo -e "${RED}Java tests FAILED${NC}"
            tests_failed=true
            return 1
        fi

        tests_run=true
        return 0
    fi

    return 0
}

################################################################################
# Function: Run custom test script
################################################################################
run_custom_tests() {
    if [ -f "scripts/run-tests.sh" ]; then
        echo ""
        echo -e "${BLUE}=== Running custom test script ===${NC}"
        echo "Running: scripts/run-tests.sh"

        if bash scripts/run-tests.sh; then
            echo -e "${GREEN}Custom tests PASSED${NC}"
            tests_passed=true
        else
            echo -e "${RED}Custom tests FAILED${NC}"
            tests_failed=true
            return 1
        fi

        tests_run=true
    fi

    return 0
}

################################################################################
# Main test execution
################################################################################
project_types=$(detect_project_type)

if [ -z "$project_types" ]; then
    echo -e "${YELLOW}No test framework detected${NC}"
    echo "Checked for: pytest, CMake/CTest, Maven, Gradle"
    echo ""
    echo "To skip this check:"
    echo "  SKIP_TESTS=1 git push"
    exit 0
fi

echo "Detected project types:$project_types"

# Run tests for each detected type
test_failures=0

if [[ "$project_types" =~ python ]]; then
    run_python_tests || ((test_failures++))
fi

if [[ "$project_types" =~ cpp ]]; then
    run_cpp_tests || ((test_failures++))
fi

if [[ "$project_types" =~ java ]]; then
    run_java_tests || ((test_failures++))
fi

# Always check for custom test script
run_custom_tests || ((test_failures++))

################################################################################
# Summary
################################################################################
echo ""
echo "========================================"

if [ "$tests_run" = false ]; then
    echo -e "${YELLOW}No tests executed${NC}"
    echo "Test frameworks detected but no tests found or runnable"
    echo ""
    echo "To skip this check:"
    echo "  SKIP_TESTS=1 git push"
    exit 0
fi

if [ $test_failures -eq 0 ]; then
    echo -e "${GREEN}All tests PASSED${NC}"
    echo "Safe to push to remote repository"
    exit 0
else
    echo -e "${RED}Tests FAILED${NC}"
    echo "$test_failures test suite(s) failed"
    echo ""
    echo "Please fix failing tests before pushing"
    echo ""
    echo "To skip this check (NOT RECOMMENDED):"
    echo "  SKIP_TESTS=1 git push"
    echo "  # or"
    echo "  git push --no-verify"
    exit 1
fi

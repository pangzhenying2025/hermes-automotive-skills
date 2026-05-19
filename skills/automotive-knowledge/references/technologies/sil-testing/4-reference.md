# SIL Testing - Quick Reference

## Coverage Tool Comparison

| Tool | Type | MC/DC | Cost | Safety Cert | Integration |
|------|------|-------|------|-------------|-------------|
| gcov/lcov | Open-source | No | Free | No | CLI, Jenkins |
| BullseyeCoverage | Commercial | Yes | €5k | No | Visual Studio, Eclipse |
| Testwell CTC++ | Commercial | Yes | €8k | Yes (TÜV) | CLI, Jenkins |
| VectorCAST | Commercial | Yes | €20k | Yes (DO-178C) | CLI, Jenkins, IDE |
| Squish Coco | Commercial | Yes | €3k | No | CLI, Jenkins |

## Coverage Commands Quick Reference

### gcov (GCC Coverage)

```bash
# Compile with coverage instrumentation
gcc -fprofile-arcs -ftest-coverage -o prog.o -c prog.c

# Link
gcc -o test_prog test_prog.o prog.o --coverage

# Run test
./test_prog

# Generate coverage report
gcov prog.c

# View annotated source
cat prog.c.gcov

# Example output:
#         -:    0:Source:prog.c
#         1:    1:int add(int a, int b) {
#         5:    2:    return a + b;
#         -:    3:}
# Column 1: Execution count (5 times executed)
# Column 2: Line number
```

### lcov (HTML Report)

```bash
# Capture coverage data
lcov --capture --directory . --output-file coverage.info

# Filter out system headers
lcov --remove coverage.info '/usr/*' --output-file coverage_filtered.info

# Generate HTML report
genhtml coverage_filtered.info --output-directory coverage_html

# View in browser
firefox coverage_html/index.html
```

### BullseyeCoverage

```bash
# Enable instrumentation
cov01 -1

# Compile (instrumented)
gcc -o prog prog.c

# Disable instrumentation
cov01 -0

# Run test (coverage data collected automatically)
./prog

# Generate HTML report
covhtml --file prog.cov

# View MC/DC coverage
covbr --file prog.cov --show-mcdc
```

### VectorCAST

```bash
# Create VectorCAST project
vcast environment create -e ENV_NAME -c compiler_config.cfg

# Add source file
vcast environment add file prog.c

# Generate test cases
vcast test case add TC_001

# Execute tests
vcast execute

# Generate coverage report
vcast report coverage --format html --output coverage.html
```

## Test Case Template

### Google Test Template

```cpp
// test_template.cpp
#include <gtest/gtest.h>
extern "C" {
    #include "module_under_test.h"
}

class ModuleTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Initialize module before each test
        module_init();
    }

    void TearDown() override {
        // Cleanup after each test
        module_reset();
    }
};

// Nominal test case
TEST_F(ModuleTest, NominalBehavior) {
    // Given: Initial conditions
    int input = 10;
    
    // When: Execute function under test
    int result = module_function(input);
    
    // Then: Verify expected behavior
    EXPECT_EQ(result, 20);
}

// Boundary test case
TEST_F(ModuleTest, BoundaryMinimum) {
    int result = module_function(0);
    EXPECT_EQ(result, 0);
}

TEST_F(ModuleTest, BoundaryMaximum) {
    int result = module_function(INT_MAX);
    EXPECT_EQ(result, INT_MAX * 2);
}

// Error handling test
TEST_F(ModuleTest, InvalidInput) {
    int result = module_function(-1);
    EXPECT_EQ(result, ERROR_CODE);
}
```

### Python unittest Template

```python
import unittest
import ctypes

class TestPIDController(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        """Load shared library once for all tests"""
        cls.lib = ctypes.CDLL('./pid_controller.so')
        cls.lib.pid_init.argtypes = [ctypes.c_double] * 3
        cls.lib.pid_step.argtypes = [ctypes.c_double] * 2
        cls.lib.pid_step.restype = ctypes.c_double

    def setUp(self):
        """Initialize before each test"""
        self.lib.pid_init(1.0, 0.1, 0.01)

    def test_step_response(self):
        """Verify PID reaches setpoint"""
        setpoint = 100.0
        measurement = 0.0
        
        for _ in range(200):
            output = self.lib.pid_step(setpoint, measurement)
            measurement += output * 0.01
        
        self.assertAlmostEqual(measurement, setpoint, delta=1.0)

    def test_zero_setpoint(self):
        """Verify zero setpoint handling"""
        output = self.lib.pid_step(0.0, 0.0)
        self.assertEqual(output, 0.0)

if __name__ == '__main__':
    unittest.main()
```

## CI/CD Integration Examples

### Jenkins Declarative Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/company/ecu_software.git'
            }
        }
        
        stage('Build SIL') {
            steps {
                sh '''
                    mkdir -p build
                    cd build
                    cmake .. -DCOVERAGE=ON
                    make
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                sh '''
                    cd build
                    ./test/sil_test --gtest_output=xml:test_results.xml
                '''
            }
        }
        
        stage('Coverage') {
            steps {
                sh '''
                    cd build
                    lcov --capture --directory . --output-file coverage.info
                    lcov --remove coverage.info '/usr/*' --output-file coverage_filtered.info
                    genhtml coverage_filtered.info --output-directory coverage_html
                '''
            }
        }
        
        stage('Publish') {
            steps {
                junit 'build/test_results.xml'
                publishHTML(target: [
                    reportDir: 'build/coverage_html',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'build/**/*.gcov', allowEmptyArchive: true
        }
        failure {
            mail to: 'team@example.com',
                 subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                 body: "Something is wrong with ${env.BUILD_URL}"
        }
    }
}
```

### GitLab CI Complete Example

```yaml
image: gcc:11

variables:
  GIT_SUBMODULE_STRATEGY: recursive

stages:
  - build
  - test
  - coverage
  - deploy

build_sil:
  stage: build
  script:
    - apt-get update && apt-get install -y cmake lcov
    - mkdir build && cd build
    - cmake .. -DCMAKE_BUILD_TYPE=Debug -DCOVERAGE=ON
    - make -j$(nproc)
  artifacts:
    paths:
      - build/
    expire_in: 1 hour

unit_tests:
  stage: test
  dependencies:
    - build_sil
  script:
    - cd build
    - ./test/sil_test --gtest_output=xml:../test_results.xml
  artifacts:
    reports:
      junit: test_results.xml

coverage_analysis:
  stage: coverage
  dependencies:
    - build_sil
    - unit_tests
  script:
    - cd build
    - gcov CMakeFiles/sil_test.dir/src/*.gcda
    - lcov --capture --directory . --output-file coverage.info
    - lcov --remove coverage.info '/usr/*' 'test/*' --output-file coverage_filtered.info
    - genhtml coverage_filtered.info --output-directory ../coverage_html
    - lcov --summary coverage_filtered.info
  coverage: '/lines......: \d+\.\d+%/'
  artifacts:
    paths:
      - coverage_html/
    expire_in: 30 days

pages:
  stage: deploy
  dependencies:
    - coverage_analysis
  script:
    - mv coverage_html public
  artifacts:
    paths:
      - public
  only:
    - main
```

### GitHub Actions

```yaml
name: SIL Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y cmake lcov
    
    - name: Build
      run: |
        mkdir build && cd build
        cmake .. -DCOVERAGE=ON
        make -j$(nproc)
    
    - name: Run tests
      run: |
        cd build
        ./test/sil_test --gtest_output=xml:test_results.xml
    
    - name: Generate coverage
      run: |
        cd build
        lcov --capture --directory . --output-file coverage.info
        lcov --remove coverage.info '/usr/*' --output-file coverage_filtered.info
        genhtml coverage_filtered.info --output-directory coverage_html
    
    - name: Publish test results
      uses: EnricoMi/publish-unit-test-result-action@v2
      if: always()
      with:
        files: build/test_results.xml
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: build/coverage_filtered.info
        fail_ci_if_error: true
```

## Coverage Interpretation

### Statement Coverage Thresholds

```
Coverage Level | Interpretation | Action Required
---------------|----------------|------------------
100%           | Excellent      | Maintain
95-99%         | Good           | Identify uncovered lines, add tests
85-94%         | Acceptable     | Improve coverage for critical modules
70-84%         | Poor           | Significant testing gaps, review
< 70%          | Unacceptable   | Major rework needed
```

### Branch Coverage Analysis

```c
// Example: Uncovered branch
int process_sensor(int value) {
    if (value < 0) {           // Branch 1
        return ERROR;          // Covered
    } else if (value > 100) {  // Branch 2
        return ERROR;          // NOT COVERED (missing test)
    }
    return value * 2;          // Covered
}

// Required test cases:
// TC1: value = -1  → covers Branch 1 (value < 0)
// TC2: value = 50  → covers normal path
// TC3: value = 101 → covers Branch 2 (value > 100) ← MISSING
```

### MC/DC Requirement Matrix

```
Decision: if ((A && B) || C)

Test Cases for MC/DC:
 TC  | A | B | C | Outcome | Condition Shown Independent
-----|---|---|---|---------|---------------------------
  1  | F | F | F |    F    | Baseline
  2  | T | F | F |    F    | A independent (A changes, outcome same)
  3  | F | T | F |    F    | B independent (B changes, outcome same)
  4  | F | F | T |    T    | C independent (C changes, outcome changes)
  5  | T | T | F |    T    | A independent (vs TC3, A changes → outcome changes)

Minimal MC/DC set: TC1, TC4, TC5 (covers all conditions independently)
```

## Troubleshooting

### gcov Shows 0% Coverage

**Problem**: No .gcda files generated

**Solution**:
```bash
# Check compilation flags
gcc -v prog.c  # Look for -fprofile-arcs -ftest-coverage

# Ensure program exits normally (not killed)
./test_prog  # Must complete without SIGKILL

# Check for .gcda files
ls -la *.gcda  # Should exist after running program
```

### Coverage Report Incorrect

**Problem**: Old coverage data mixed with new

**Solution**:
```bash
# Clean old coverage files
find . -name "*.gcda" -delete
find . -name "*.gcno" -delete

# Rebuild and retest
make clean
make
./test_prog
gcov prog.c
```

### Link Error with --coverage

**Problem**: `undefined reference to __gcov_init`

**Solution**:
```bash
# Add --coverage to linker flags (not just compiler)
gcc -fprofile-arcs -ftest-coverage -c prog.c
gcc --coverage -o test_prog test_prog.o prog.o  # ← Add here
```

## References

- gcov Manual: https://gcc.gnu.org/onlinedocs/gcc/Gcov.html
- Google Test Documentation: https://google.github.io/googletest/
- ISO 26262-6:2018 Table 13 (Software unit testing methods)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All SIL users

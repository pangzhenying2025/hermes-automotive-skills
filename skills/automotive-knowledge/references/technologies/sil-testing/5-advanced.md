# SIL Testing - Advanced Topics

## Continuous SIL in CI/CD

### Shift-Left Testing Strategy

**Traditional Waterfall**:
```
Design → Code → Unit Test → Integration → System → Vehicle
                  ↑ Testing starts late (weeks/months after coding)
```

**Continuous SIL (Shift-Left)**:
```
Design + Code → SIL (< 1 hour) → Integration → System → Vehicle
          ↑ Testing starts immediately (minutes after coding)
```

**Benefits**:
- Bugs found in hours, not weeks
- 10x reduction in bug fix cost
- Continuous feedback to developers

### Git Pre-Commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit
# Run SIL tests before allowing commit

echo "Running SIL tests..."

# Build and test
mkdir -p build && cd build
cmake .. -DCOVERAGE=ON > /dev/null
make -j$(nproc) > /dev/null

if ! ./test/sil_test; then
    echo "COMMIT REJECTED: SIL tests failed"
    exit 1
fi

# Check coverage threshold (90%)
coverage=$(lcov --summary coverage.info 2>&1 | grep lines | awk '{print $2}' | cut -d'%' -f1)
if (( $(echo "$coverage < 90" | bc -l) )); then
    echo "COMMIT REJECTED: Coverage $coverage% < 90%"
    exit 1
fi

echo "SIL tests passed, coverage $coverage%"
exit 0
```

## Fuzzing for Robustness Testing

### What is Fuzzing?

Automated generation of random/invalid inputs to find crashes and undefined behavior.

**Example: Fuzz Test for Parser**:
```c
// parser.c
int parse_command(const char* cmd) {
    if (cmd[0] == 'S' && cmd[1] == 'T') {
        int value = atoi(&cmd[2]);  // Potential crash if cmd too short
        return value;
    }
    return -1;
}

// Fuzz test (AFL - American Fuzzy Lop)
// Compile with:
// afl-gcc -o parser_fuzz parser.c
// Run fuzzer:
// afl-fuzz -i inputs/ -o findings/ ./parser_fuzz @@

// libFuzzer example:
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (size < 3) return 0;
    
    char cmd[256];
    memcpy(cmd, data, std::min(size, sizeof(cmd)-1));
    cmd[size] = '\0';
    
    parse_command(cmd);  // Fuzzer will try to crash this
    return 0;
}
```

**Typical Findings**:
- Buffer overflows (input longer than expected)
- Null pointer dereferences
- Integer overflows
- Unhandled exceptions

**Tools**:
- AFL (American Fuzzy Lop) - free, coverage-guided
- libFuzzer (LLVM) - free, in-process fuzzing
- Peach Fuzzer - commercial, protocol-aware

## Mutation Testing

### Concept

Introduce artificial bugs (mutations) in code, verify tests catch them.

**Example**:
```c
// Original code
int max(int a, int b) {
    if (a > b) {   // Line to mutate
        return a;
    }
    return b;
}

// Mutation 1: Change > to >=
int max(int a, int b) {
    if (a >= b) {  // Mutated
        return a;
    }
    return b;
}

// If tests still pass, mutation "survived" → weak test suite
```

**Mutation Operators**:
- Relational: `>` → `>=`, `<`, `==`
- Arithmetic: `+` → `-`, `*`, `/`
- Logical: `&&` → `||`, `!`
- Constant: `0` → `1`, `NULL` → valid pointer

**Mutation Score**:
```
Mutation Score = (Killed Mutations / Total Mutations) × 100%

Target: > 80% for critical code
```

**Tools**:
- mutmut (Python) - free
- Stryker (JavaScript/C#) - free
- PITest (Java) - free
- MuCPP (C++) - research tool

**Example (mutmut)**:
```bash
# Install
pip install mutmut

# Run mutation testing
mutmut run --paths-to-mutate src/

# View results
mutmut results

# Show survived mutants (weak tests)
mutmut show --status=survived
```

## Formal Verification Integration

### Static Analysis Tools

**Polyspace (MathWorks)**:
- Prove absence of runtime errors (division by zero, overflow, null pointer)
- Color-coded: Green (proven safe), Orange (unproven), Red (proven unsafe)

**Example**:
```c
int divide(int a, int b) {
    return a / b;  // Polyspace: RED (division by zero if b==0)
}

int divide_safe(int a, int b) {
    if (b == 0) return 0;
    return a / b;  // Polyspace: GREEN (proven safe)
}
```

**Coverity (Synopsys)**:
- Static analysis for C/C++
- Detects 100+ defect types (memory leaks, concurrency bugs)

**CBMC (C Bounded Model Checker)**:
- Formally verify properties (assertions)

**Example (CBMC)**:
```c
#include <assert.h>

int abs(int x) {
    if (x < 0) return -x;
    return x;
}

int main() {
    int x;  // Symbolic variable (all possible values)
    int result = abs(x);
    assert(result >= 0);  // Property to verify
    return 0;
}

// Run CBMC:
// cbmc abs.c
// Output: VERIFICATION SUCCESSFUL (property holds for ALL inputs)
```

### SIL + Formal Verification Workflow

```
1. Write code (C/C++)
2. Run formal verification (Polyspace, CBMC) → Prove properties
3. Run SIL tests → Verify behavior
4. Measure coverage → Ensure test completeness
5. If property violated: Fix code → Re-verify
6. If test fails: Fix code or test → Rerun
```

## Continuous SIL Architecture

### Parallel Test Execution

**Example (pytest-xdist)**:
```bash
# Run tests on 8 CPU cores in parallel
pytest -n 8 test_suite/

# Speedup: 8x (if tests independent)
# Before: 800 tests × 1 sec = 800 sec (13 min)
# After: 800 tests / 8 cores = 100 sec (1.6 min)
```

**Example (Google Test)**:
```bash
# Run specific test shard (for distributed execution)
./sil_test --gtest_filter=*:* --gtest_shard_index=0 --gtest_total_shards=10
```

### Cloud-Based SIL

**AWS CodeBuild Example**:
```yaml
# buildspec.yml
version: 0.2

phases:
  install:
    commands:
      - apt-get update
      - apt-get install -y cmake lcov
  
  build:
    commands:
      - mkdir build && cd build
      - cmake .. -DCOVERAGE=ON
      - make -j$(nproc)
  
  post_build:
    commands:
      - cd build
      - ./test/sil_test --gtest_output=xml:test_results.xml
      - lcov --capture --directory . --output-file coverage.info
      - genhtml coverage.info --output-directory coverage_html

artifacts:
  files:
    - build/test_results.xml
    - coverage_html/**/*

reports:
  junit:
    files:
      - build/test_results.xml
```

**Benefits**:
- Elastic scaling (spin up 100 instances for release testing)
- No local infrastructure (pay-per-use)
- Faster feedback (parallel execution)

## Next Steps

**Explore Cutting-Edge Topics**:
- AI-based test generation (using GPT-4 to generate test cases)
- Symbolic execution (KLEE tool for automatic test generation)
- Concolic testing (concrete + symbolic execution)
- Continuous fuzzing (OSS-Fuzz for open-source projects)

**Integration with Safety Processes**:
- ISO 26262 tool qualification (qualify SIL tools per ISO 26262-8)
- Traceability automation (link SIL tests to requirements via tools)
- Safety case generation (auto-generate evidence from SIL results)

## References

- AFL Fuzzer: https://github.com/google/AFL
- mutmut Mutation Testing: https://github.com/boxed/mutmut
- CBMC Model Checker: https://www.cprover.org/cbmc/
- ISO 26262-6:2018 Software verification methods
- DO-178C (Avionics software verification, similar principles)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Senior test engineers, researchers, safety architects

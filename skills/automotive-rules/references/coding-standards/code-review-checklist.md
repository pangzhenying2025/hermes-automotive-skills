# Code Review Checklist for Automotive Software

Comprehensive code review checklist covering correctness, security, performance, maintainability, test coverage, and automotive-specific requirements.

## Purpose

- Ensure code quality and consistency across automotive projects
- Catch defects early before they reach production
- Share knowledge and improve team skills
- Enforce compliance with safety and security standards

## Pre-Review Checklist (Author)

- [ ] Code compiles without errors or warnings
- [ ] All tests pass locally
- [ ] Static analysis clean (cppcheck, clang-tidy, SonarQube)
- [ ] Code formatted per project style guide
- [ ] Self-review completed
- [ ] Commit messages follow convention
- [ ] PR description includes context and testing notes

## Correctness

### Logic and Functionality

- [ ] Code implements requirements correctly
- [ ] Edge cases handled (min/max values, null pointers, empty lists)
- [ ] Error conditions handled appropriately
- [ ] No hardcoded magic numbers (use named constants with units)
- [ ] Loops have proper termination conditions
- [ ] Recursion has base case and bounded depth
- [ ] State machines have all transitions defined

### Data Types and Conversions

- [ ] Integer types sized appropriately (uint8_t, uint16_t, uint32_t)
- [ ] No implicit type conversions that lose precision
- [ ] Signed/unsigned comparisons handled correctly
- [ ] Floating-point comparisons use epsilon tolerance
- [ ] Pointer arithmetic checked for bounds
- [ ] Enums used instead of magic numbers

### Memory Management

- [ ] All allocated memory freed (no leaks)
- [ ] No use-after-free or double-free
- [ ] Buffer sizes validated to prevent overflow
- [ ] Pointers checked for NULL before dereference
- [ ] Stack usage reasonable (no large local arrays)
- [ ] Dynamic memory avoided in safety-critical code (ASIL C/D)

## Security

### Input Validation

- [ ] All external inputs validated (CAN messages, sensor data, user input)
- [ ] Range checks for physical quantities
- [ ] Plausibility checks for redundant sensors
- [ ] CRC/checksum verification for critical messages
- [ ] Authentication required for privileged operations

### Cryptography and Secrets

- [ ] No hardcoded keys, passwords, or secrets
- [ ] Strong cryptographic algorithms used (AES-256, RSA-2048+, SHA-256)
- [ ] Random number generation uses crypto-grade RNG
- [ ] Secrets stored in secure storage (HSM, secure enclave)
- [ ] Secure boot chain verified

### Attack Surface

- [ ] No SQL/command injection vulnerabilities
- [ ] No buffer overflows (bounds checked)
- [ ] No integer overflows (checked or saturating arithmetic)
- [ ] Diagnostic interfaces protected with authentication
- [ ] Debug code removed or disabled in production builds

## Performance

### Real-Time Constraints

- [ ] Worst-case execution time (WCET) analyzed and acceptable
- [ ] No unbounded loops in interrupt context
- [ ] CPU usage within budget (<80% typical)
- [ ] Memory usage within budget (RAM, flash)
- [ ] No busy-waiting (use interrupts or RTOS delays)

### Communication Efficiency

- [ ] CAN bus load acceptable (<70% utilization)
- [ ] Message prioritization correct (critical messages high priority)
- [ ] No excessive polling (use event-driven design)
- [ ] Network bandwidth usage optimized

### Algorithmic Efficiency

- [ ] Algorithm complexity reasonable (O(n log n) or better for large datasets)
- [ ] Lookup tables used for expensive calculations
- [ ] Caching used for repeated computations
- [ ] No premature optimization (profile first)

## Maintainability

### Code Structure

- [ ] Functions single-purpose and cohesive
- [ ] Function length reasonable (<50 lines)
- [ ] File length reasonable (<500 lines)
- [ ] Cyclomatic complexity low (<15 per function)
- [ ] Proper separation of concerns (business logic vs I/O)
- [ ] No deeply nested code (max 4 levels)

### Readability

- [ ] Naming clear and descriptive
- [ ] Comments explain "why", not "what"
- [ ] Complex logic documented
- [ ] Units included in variable names
- [ ] Consistent formatting
- [ ] No commented-out code

### Dependencies

- [ ] Minimal coupling between modules
- [ ] No circular dependencies
- [ ] Third-party libraries justified and approved
- [ ] Dependencies up-to-date with security patches

## Test Coverage

### Unit Tests

- [ ] Unit tests written for new code
- [ ] Statement coverage >95%
- [ ] Branch coverage >90%
- [ ] MC/DC coverage >95% for ASIL C/D functions
- [ ] Tests independent and repeatable

### Integration Tests

- [ ] Integration tests cover module interactions
- [ ] CAN communication tested (message send/receive)
- [ ] State machine transitions tested
- [ ] Error injection tested (fault tolerance)

### Test Quality

- [ ] Tests have clear pass/fail criteria
- [ ] Test names descriptive (test_what_when_expected)
- [ ] No flaky tests (deterministic, no race conditions)
- [ ] Tests fast (<5 minutes total for unit tests)

## Automotive-Specific Checks

### Safety (ISO 26262)

- [ ] Safety requirements traced to implementation
- [ ] ASIL level documented for safety functions
- [ ] Safety mechanisms implemented (E2E protection, range checks, plausibility)
- [ ] Fail-safe behavior defined and tested
- [ ] Watchdog monitoring active
- [ ] Diagnostic coverage adequate (>90% for ASIL C/D)

### MISRA Compliance

- [ ] MISRA C:2012 violations documented
- [ ] Mandatory rules: 100% compliance
- [ ] Required rules: compliance or justified deviation
- [ ] Advisory rules: compliance recommended

### AUTOSAR Compliance

- [ ] AUTOSAR naming conventions followed (if applicable)
- [ ] RTE interfaces used correctly
- [ ] Runnable timing requirements met
- [ ] Inter-ECU communication via standardized interfaces

### Diagnostics (UDS/OBD)

- [ ] DTCs (Diagnostic Trouble Codes) defined for faults
- [ ] Diagnostic services implemented correctly (0x10, 0x22, 0x27, 0x2E, 0x31)
- [ ] Security access for protected services
- [ ] Freeze frame data captured on fault

### Calibration and Variant Coding

- [ ] Calibration parameters in dedicated section (not hardcoded)
- [ ] Variant coding supported (hardware/software variants)
- [ ] Default values sensible and safe

## Documentation

- [ ] Public API documented (Doxygen/Javadoc comments)
- [ ] Complex algorithms explained
- [ ] Assumptions and limitations documented
- [ ] Requirements traceability comments (REQ-ID)
- [ ] Change log updated

## Review Process

### Reviewer Actions

1. Understand context (read PR description, linked requirements)
2. Check code against checklist
3. Test locally if possible
4. Provide constructive feedback
5. Approve only when all concerns addressed

### Feedback Guidelines

- Be specific and actionable
- Explain rationale for requested changes
- Distinguish critical issues from nitpicks
- Praise good code
- Use "we" instead of "you" to encourage collaboration

### Approval Criteria

- All critical issues resolved
- No unaddressed security vulnerabilities
- Test coverage adequate
- Code meets quality standards
- Safety requirements verified (for safety-critical code)

## Tools Integration

- Static analysis: cppcheck, clang-tidy, SonarQube
- Security scanning: Snyk, Bandit (Python)
- Coverage: gcov, lcov, JaCoCo (Java)
- MISRA checker: PC-Lint, QAC, Polyspace
- Formatting: clang-format, black (Python)

## References

- MISRA C:2012
- ISO 26262-6 (Software development)
- ISO 21434 (Cybersecurity)
- CERT C Secure Coding Standard
- ASPICE SWE.2 (Software design)

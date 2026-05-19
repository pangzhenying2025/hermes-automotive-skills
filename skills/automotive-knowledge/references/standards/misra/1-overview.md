# MISRA C/C++ - Coding Standards for Safety-Critical Software - Overview

> **Target Audience**: Project managers, safety engineers, developers new to MISRA

## What is MISRA?

MISRA (Motor Industry Software Reliability Association) publishes coding guidelines for developing safety-critical software in C and C++. Originally created for the automotive industry, MISRA guidelines are now used across aerospace, medical devices, rail, and industrial automation.

The guidelines restrict the use of language features that are undefined, implementation-defined, or error-prone, promoting predictable, analyzable, and maintainable code.

## MISRA Standards Family

| Standard | Language | Latest Edition | Rules | Directives |
|----------|----------|---------------|-------|------------|
| MISRA C:2012 | C90/C99 | 2012 (AMD 2, 2020) | 143 | 16 |
| MISRA C:2023 | C90/C99/C11/C18 | 2023 | 175 | 18 |
| MISRA C++:2008 | C++03 | 2008 | 228 | 0 |
| MISRA C++:2023 | C++17 | 2023 | 179 | 0 |

**Note**: MISRA C:2023 supersedes MISRA C:2012. MISRA C++:2023 supersedes MISRA C++:2008.

## Why MISRA Matters

### Safety Standards Mandate MISRA

| Safety Standard | MISRA Reference |
|----------------|-----------------|
| ISO 26262 (Automotive) | Table 1 of Part 6 recommends MISRA for all ASILs |
| DO-178C (Aerospace) | MISRA used as coding standard for Level A-D |
| IEC 62304 (Medical) | MISRA recommended for Class B and C software |
| EN 50128 (Rail) | MISRA referenced for SIL 1-4 |
| IEC 61508 (General) | MISRA recommended for SIL 1-4 |

### Key Benefits

- **Predictable behavior**: Avoids undefined and unspecified behavior in C/C++
- **Tool analyzability**: Rules designed for automated static analysis enforcement
- **Reduced defect density**: Studies show 30-70% fewer defects in MISRA-compliant code
- **Regulatory compliance**: Satisfies coding standard requirements in ISO 26262, DO-178C
- **Portability**: Code behaves consistently across compilers and platforms

## Rule Classification

### By Category

| Category | Description | Example |
|----------|-------------|---------|
| **Mandatory** | Must always be followed, no deviation permitted | No undefined behavior |
| **Required** | Must be followed unless formal deviation raised | No implicit type conversions |
| **Advisory** | Recommended best practice, deviation acceptable | Use of enum for related constants |

### By Decidability

| Decidability | Description | Tool Impact |
|-------------|-------------|-------------|
| **Decidable** | Tool can definitively determine compliance | Fully automatable |
| **Undecidable** | Tool cannot always determine compliance | Requires manual review |

### Rules vs. Directives

| Type | Scope | Enforcement |
|------|-------|-------------|
| **Rules** | Specific, testable requirements on source code | Static analysis tools |
| **Directives** | Broader guidance on development practices | Manual review, process |

## MISRA C:2012 Rule Groups

| Group | Topic | Rule Count | Focus |
|-------|-------|-----------|-------|
| 1 | Standard C environment | 3 | Compiler conformance |
| 2 | Unused code | 7 | Dead code elimination |
| 3 | Comments | 2 | Nested comments |
| 4 | Character sets and lexical conventions | 2 | Character encoding |
| 5 | Identifiers | 9 | Naming uniqueness |
| 6 | Types | 2 | Type usage |
| 7 | Literals and constants | 4 | Literal representation |
| 8 | Declarations and definitions | 14 | Declaration rules |
| 9 | Initialization | 5 | Variable initialization |
| 10 | Essential type model | 8 | Type safety |
| 11 | Pointer type conversions | 9 | Pointer safety |
| 12 | Expressions | 4 | Expression side effects |
| 13 | Side effects | 6 | Evaluation order |
| 14 | Control statement expressions | 4 | Control flow clarity |
| 15 | Control flow | 7 | Structured programming |
| 16 | Switch statements | 7 | Switch completeness |
| 17 | Functions | 8 | Function interfaces |
| 18 | Pointers and arrays | 8 | Memory safety |
| 19 | Overlapping storage | 2 | Union/aliasing safety |
| 20 | Preprocessing directives | 14 | Macro safety |
| 21 | Standard libraries | 21 | Safe library usage |
| 22 | Resources | 10 | Resource management |

## Compliance and Deviations

### Compliance Categories

A project claiming MISRA compliance must:

1. **Adopt a compliance matrix**: Document which rules are enforced
2. **Use static analysis**: Employ at least one MISRA-compliant checker
3. **Document deviations**: Formal deviation process for any non-compliance
4. **Review deviations**: Independent review and approval of each deviation
5. **Maintain records**: Traceability from rules to code to deviations

### Deviation Process

```
1. Developer identifies need for deviation
   |
   v
2. Document deviation request:
   - Rule number and category
   - Reason deviation is needed
   - Risk assessment
   - Mitigation measures
   |
   v
3. Independent reviewer evaluates:
   - Safety impact
   - Alternative approaches
   - Scope limitation
   |
   v
4. Approved deviation recorded in compliance matrix
```

## Tool Ecosystem

### Primary Static Analysis Tools

| Tool | Vendor | MISRA Coverage | Certification |
|------|--------|---------------|---------------|
| Polyspace | MathWorks | C:2012, C++:2023 | TUV SUD certified |
| QAC/Helix | Perforce | C:2012, C++:2023 | TUV SUD certified |
| Coverity | Synopsys | C:2012, C++:2008 | Partial |
| PC-lint Plus | Gimpel | C:2012, C++:2023 | Self-validated |
| Parasoft C/C++test | Parasoft | C:2012, C++:2023 | TUV SUD certified |
| Klocwork | Perforce | C:2012, C++:2008 | Partial |
| cppcheck | Open source | C:2012 subset | Community validated |
| clang-tidy | LLVM | C:2012 subset | Community validated |

## Next Steps

- **Level 2**: Conceptual understanding of rule categories, decidability, and deviation management
- **Level 3**: Detailed rule-by-rule guide with code examples
- **Level 4**: Quick reference tables, rule lookup, tool comparison
- **Level 5**: Advanced topics: MISRA in CI/CD, tool qualification, MISRA C++:2023 migration

## References

- MISRA C:2012 Guidelines for the Use of the C Language in Critical Systems (3rd Edition)
- MISRA C:2012 Amendment 2 (2020)
- MISRA C:2023 Guidelines for the Use of the C Language in Critical Systems
- MISRA C++:2023 Guidelines for the Use of C++17 in Critical Systems
- MISRA Compliance:2020 Achieving Compliance with MISRA Coding Guidelines
- ISO 26262-6:2018 Table 1 (Coding guidelines recommendation)

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Project managers, safety engineers, developers new to MISRA

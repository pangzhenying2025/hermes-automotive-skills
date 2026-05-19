# MISRA C/C++ - Conceptual Architecture

> **Target Audience**: Software architects, senior developers, safety engineers

## The Essential Type Model (MISRA C:2012)

The essential type model is MISRA's approach to preventing implicit type conversion errors, one of the most common sources of bugs in C.

### Essential Type Categories

```
Essential Type Categories
|
+-- Boolean
|   (true/false, _Bool, typedef to bool)
|
+-- Character
|   (plain char used for character data)
|
+-- Signed
|   (signed char, short, int, long, long long)
|
+-- Unsigned
|   (unsigned char, unsigned short, unsigned int, ...)
|
+-- Floating
|   (float, double, long double)
|
+-- Enum
|   (named enumeration type)
```

### Type Conversion Rules

| From / To | Boolean | Character | Signed | Unsigned | Floating | Enum |
|-----------|---------|-----------|--------|----------|----------|------|
| **Boolean** | OK | -- | -- | -- | -- | -- |
| **Character** | -- | OK | Explicit | Explicit | -- | -- |
| **Signed** | -- | Explicit | Wider OK | Explicit | Explicit | -- |
| **Unsigned** | -- | Explicit | Explicit | Wider OK | Explicit | -- |
| **Floating** | -- | -- | Explicit | Explicit | Wider OK | -- |
| **Enum** | -- | -- | -- | -- | -- | Same OK |

**Key Principle**: Implicit conversions are only allowed to a wider type within the same essential type category. All other conversions require explicit casts.

## Undefined, Unspecified, and Implementation-Defined Behavior

MISRA rules are fundamentally organized around preventing these three categories of unpredictable behavior in C/C++.

### Categories

| Category | Definition | MISRA Approach | Example |
|----------|-----------|----------------|---------|
| **Undefined** | Standard imposes no requirements | Must be avoided entirely | Signed integer overflow |
| **Unspecified** | Standard provides options, compiler chooses | Must be avoided or documented | Function argument evaluation order |
| **Implementation-defined** | Compiler must document behavior | Document and verify | Size of int |

### Impact on Safety

```
Undefined Behavior:
  - Compiler may optimize assuming it cannot happen
  - Program may crash, produce wrong results, or appear to work
  - Particularly dangerous: appears to work in test, fails in field

  Example: Signed overflow
  int x = INT_MAX;
  x = x + 1;  // Undefined: compiler may optimize entire block away

Unspecified Behavior:
  - Program behaves differently on different compilers
  - Results are unpredictable but within defined bounds

  Example: Evaluation order
  int a = 1;
  f(a++, a++);  // Which argument is evaluated first?

Implementation-Defined:
  - Behavior is consistent per compiler but not portable
  - Must be documented for the target platform

  Example: Right shift of signed negative
  int x = -1;
  int y = x >> 1;  // Arithmetic or logical shift? Compiler decides
```

## Rule Decidability Framework

### Decidable Rules

A rule is decidable if a tool can always determine compliance or non-compliance from the source code alone.

**Characteristics**:
- Can be fully automated
- No false negatives possible (with correct tool)
- False positives possible but bounded
- Suitable for CI/CD gate enforcement

**Example** (Rule 10.1 - Operands shall not be of inappropriate essential type):
```c
/* Decidable: Tool can check types of all operands */
uint32_t a = 10u;
uint32_t b = 20u;
uint32_t c = a + b;  /* Compliant: both unsigned, result unsigned */

int32_t d = 10;
uint32_t e = a + d;  /* Non-compliant: mixed signed/unsigned */
```

### Undecidable Rules

A rule is undecidable if no tool can always determine compliance. These require human judgment or approximation.

**Characteristics**:
- Tools use heuristics (may have false positives or false negatives)
- Manual review required for tool findings
- Often involve runtime behavior or semantic intent

**Example** (Rule 1.3 - There shall be no undefined behavior):
```c
/* Undecidable in general: requires value analysis */
void divide(int32_t numerator, int32_t denominator) {
    int32_t result = numerator / denominator;
    /* Is denominator ever 0? Tool cannot always determine */
}
```

### Decidability by Rule Category

| Category | Decidable | Undecidable | Total |
|----------|-----------|-------------|-------|
| Mandatory | 8 | 2 | 10 |
| Required | 89 | 32 | 121 |
| Advisory | 10 | 2 | 12 |
| **Total** | **107** | **36** | **143** |

## Deviation Management

### When Deviations Are Appropriate

**Legitimate Reasons**:
- Hardware register access requires specific casting (Rule 11.x)
- Performance-critical code requires specific constructs
- Third-party library interface requires deviation
- Legacy code integration with bounded risk

**Illegitimate Reasons**:
- Developer preference or convenience
- "It works on our compiler"
- Too many violations to fix
- Lack of understanding of the rule

### Deviation Documentation Template

```
Deviation ID: DEV-MISRA-001
Rule: 11.3 (Required)
Rule Text: A cast shall not be performed between a pointer to
           object type and a pointer to a different object type
Category: Required

Project: ECU-Brake-Controller
File(s): hw_register.c, lines 45-67

Justification:
  Hardware memory-mapped registers require pointer casting from
  uint32_t* to volatile register_t*. Register structure is defined
  in hardware specification document HW-SPEC-v2.3, Section 4.2.

Risk Assessment:
  LOW - Register layout is verified against hardware datasheet.
  Pointer alignment is guaranteed by linker script.
  Access is restricted to dedicated hardware abstraction layer.

Mitigation:
  - All register accesses confined to HAL module (hw_register.c)
  - Static analysis confirms no other pointer casts in codebase
  - Unit tests verify correct register read/write values
  - Code review mandatory for any HAL changes

Scope: Limited to hw_register.c HAL functions only

Approved By: [Safety Manager], [Date]
Review Date: [Date of next review]
```

### Deviation Tracking

| Metric | Target | Purpose |
|--------|--------|---------|
| Total deviations | < 50 per project | Limit overall exposure |
| Deviations per KLOC | < 2 | Density indicator |
| Mandatory rule deviations | 0 | Never deviate mandatory rules |
| Open deviation reviews | 0 | All deviations reviewed |
| Deviation age | < 6 months | Periodic re-evaluation |

## MISRA Compliance Levels

### MISRA Compliance:2020 Framework

The MISRA Compliance:2020 document defines how to claim compliance:

```
Compliance Claim Requirements:
1. Enforcement: All rules checked by static analysis tool
2. Categorization: Each rule categorized (adopted, disapplied, advisory)
3. Deviations: Formal process for all non-compliances
4. Guideline Re-categorization Plan (GRP): Document any re-categorization
5. Tool validation: Static analysis tool validated against MISRA rules
```

### Guideline Re-categorization Plan (GRP)

Projects may adjust rule categories within defined bounds:

| Original Category | Allowed Re-categorization |
|-------------------|--------------------------|
| Mandatory | Cannot be re-categorized |
| Required | Can be downgraded to Advisory (with justification) |
| Advisory | Can be downgraded to Disapplied (with justification) |
| Any | Cannot be upgraded (Advisory cannot become Required) |

### Compliance Matrix Example

| Rule | Category | Adopted | Tool Check | Deviations | Notes |
|------|----------|---------|------------|------------|-------|
| 1.1 | Required | Yes | QAC 5020 | 0 | |
| 1.2 | Advisory | Yes | QAC 5021 | 0 | |
| 1.3 | Required | Yes | Polyspace | 3 | See DEV-001,002,003 |
| 2.1 | Required | Yes | QAC 5030 | 0 | |
| ... | ... | ... | ... | ... | ... |
| 11.3 | Required | Yes | QAC 5087 | 12 | HAL only, see GRP |

## MISRA C++:2023 vs. MISRA C++:2008

### Key Differences

| Aspect | MISRA C++:2008 | MISRA C++:2023 |
|--------|---------------|----------------|
| Language version | C++03 | C++17 |
| Number of rules | 228 | 179 |
| Rule numbering | By topic group | By topic group (renumbered) |
| Smart pointers | Not addressed | Recommended over raw pointers |
| Lambdas | Not in C++03 | Allowed with restrictions |
| constexpr | Not in C++03 | Recommended for compile-time evaluation |
| auto | Not in C++03 | Allowed with restrictions |
| Range-for | Not in C++03 | Recommended over index loops |
| Exceptions | Discouraged | Context-dependent guidance |

### Migration Considerations

```
Migration from MISRA C++:2008 to MISRA C++:2023:
1. Map existing rule compliance to new rule numbers
2. Identify new rules not in 2008 edition
3. Identify removed rules (may relax restrictions)
4. Update static analysis tool configuration
5. Re-run analysis, address new findings
6. Update deviation records with new rule references
7. Update compliance matrix and GRP
```

## Next Steps

- **Level 3**: Detailed rule guide with compliant and non-compliant code examples
- **Level 4**: Quick reference tables for rule lookup and tool configuration
- **Level 5**: Advanced topics: CI/CD integration, tool qualification, MISRA C++:2023 deep dive

## References

- MISRA C:2012 Guidelines (3rd Edition, including AMD 2)
- MISRA C:2023 Guidelines
- MISRA C++:2023 Guidelines
- MISRA Compliance:2020
- ISO 26262-6:2018 Table 1

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Software architects, senior developers, safety engineers

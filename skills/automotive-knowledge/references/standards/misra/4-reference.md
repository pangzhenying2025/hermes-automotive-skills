# MISRA C/C++ - Quick Reference

> **Target Audience**: All project team members (quick lookup)

## MISRA C:2012 Most Violated Rules

### Top 20 Rules by Violation Frequency

| Rule | Category | Topic | Common Cause |
|------|----------|-------|-------------|
| 10.1 | Required | Inappropriate essential type | Mixing signed/unsigned |
| 10.3 | Required | Narrowing conversion | Assigning wider to narrower type |
| 10.4 | Required | Mixed essential types in operator | Arithmetic on mixed types |
| 14.4 | Required | Non-boolean controlling expression | `if (ptr)` instead of `if (ptr != NULL)` |
| 15.6 | Required | Missing compound statement braces | Single-line if/for without braces |
| 15.7 | Required | Missing else in if-else-if | Incomplete else-if chains |
| 16.4 | Required | Missing default in switch | Switch without default case |
| 17.7 | Required | Unused return value | Ignoring function return |
| 11.3 | Required | Pointer type cast | Type punning via pointer |
| 2.2 | Required | Dead code | Unreachable statements |
| 8.4 | Required | Missing compatible declaration | Function declared without prototype |
| 12.2 | Required | Shift range | Shift amount >= type width |
| 20.7 | Required | Macro parameter not in parentheses | Macro expansion errors |
| 1.3 | Required | Undefined behavior | Various UB instances |
| 5.1 | Required | Identifier uniqueness (ext) | Long identifier collision at 31 chars |
| 8.13 | Advisory | Missing const qualifier | Pointer parameter could be const |
| 11.9 | Required | NULL vs integer 0 for pointer | Using 0 instead of NULL |
| 21.3 | Required | stdlib memory functions | Use of malloc/free |
| 21.6 | Required | stdio input/output | Use of printf/scanf |
| 4.1 | Required | Octal/hex escape sequences | Non-standard escape usage |

## Rule Quick Lookup by Topic

### Type Safety

| Rule | Cat. | Summary | Fix Pattern |
|------|------|---------|-------------|
| 10.1 | Req | No inappropriate essential type for operand | Match types in expressions |
| 10.2 | Req | No inappropriate essential type for + and - | Use same type for addends |
| 10.3 | Req | No narrowing assignment | Explicit cast or widen target |
| 10.4 | Req | Both operands same essential type | Cast one operand |
| 10.5 | Adv | No inappropriate cast of essential type | Use correct type from start |
| 10.6 | Req | Composite expression assigned to wider type | Assign to matching width |
| 10.7 | Req | Composite expression with wider operand | Widen before operation |
| 10.8 | Req | Composite expression cast to wider type | Cast operands, not result |

### Pointer Safety

| Rule | Cat. | Summary | Fix Pattern |
|------|------|---------|-------------|
| 11.1 | Req | No function/object pointer conversion | Separate function and data pointers |
| 11.2 | Req | No incomplete type pointer conversion | Complete type before conversion |
| 11.3 | Req | No object type pointer conversion | Use memcpy for type punning |
| 11.4 | Adv | No pointer to integer conversion | Use uintptr_t if needed |
| 11.5 | Adv | No void pointer to object pointer | Use typed pointers |
| 11.6 | Req | No void pointer to integer conversion | Use uintptr_t |
| 11.8 | Req | No cast removing const/volatile | Maintain qualifiers |
| 11.9 | Req | Use NULL macro for null pointer | Replace 0 with NULL |
| 18.1 | Req | No pointer beyond array bounds | Bounds check before access |
| 18.4 | Adv | No pointer arithmetic except +/- integer | Prefer array indexing |

### Control Flow

| Rule | Cat. | Summary | Fix Pattern |
|------|------|---------|-------------|
| 14.1 | Req | Loop counter is essentially float | Use integer counters |
| 14.2 | Req | For loop well-formed | Standard for-loop pattern |
| 14.3 | Req | No invariant controlling expression | Remove always-true/false |
| 14.4 | Req | Controlling expression is boolean | Explicit comparison |
| 15.1 | Adv | No goto | Restructure control flow |
| 15.2 | Req | goto target in same or enclosing block | Restructure if needed |
| 15.3 | Req | goto target after goto | Forward-only goto |
| 15.4 | Adv | At most one break/goto per loop | Restructure logic |
| 15.5 | Adv | Single function exit point | Single return pattern |
| 15.6 | Req | Always use compound statements | Add braces |
| 15.7 | Req | Else in if-else-if | Add final else |

### Memory and Resources

| Rule | Cat. | Summary | Fix Pattern |
|------|------|---------|-------------|
| Dir 4.12 | Req | No dynamic memory after init | Static allocation |
| 21.3 | Req | No malloc/calloc/realloc/free | Static buffers, pools |
| 22.1 | Req | Resources obtained are released | RAII pattern, cleanup |
| 22.2 | Mand | Resources released only once | Track ownership |
| 22.3 | Req | Same file not open simultaneously | File handle management |
| 22.4 | Mand | No write to read-only file | Check mode before write |
| 22.5 | Mand | File pointer not used after close | Nullify after close |
| 22.6 | Mand | Close return value checked | Handle close failure |

## MISRA C++:2023 Key Rules Quick Lookup

### Modern C++ Specific Rules

| Rule | Cat. | Summary | C++ Feature |
|------|------|---------|-------------|
| 0.1.2 | Req | No undefined behavior | General |
| 6.2.1 | Req | Use fixed-width integer types | `<cstdint>` |
| 6.7.1 | Req | No implicit narrowing in initialization | Brace initialization |
| 8.2.5 | Req | No implicit lossy conversion | `static_cast` |
| 11.3.1 | Req | Use range-for when possible | Range-based for |
| 15.1.3 | Req | No raw new/delete | Smart pointers |
| 18.3.2 | Req | No reinterpret_cast (mostly) | `std::bit_cast` |
| 21.6.1 | Req | Use RAII for resources | Constructors/destructors |
| 23.11.1 | Req | No implicit conversion operators | `explicit` keyword |

### Deprecated C Constructs in C++

| C Construct | MISRA C++ Replacement | Rule |
|-------------|----------------------|------|
| `#define CONST 42` | `constexpr int CONST = 42;` | 6.4.1 |
| `#define MAX(a,b)` | `template<class T> T max(T,T)` | 19.0.1 |
| C-style cast `(int)x` | `static_cast<int>(x)` | 8.2.2 |
| `NULL` | `nullptr` | 7.11.1 |
| `malloc`/`free` | `std::make_unique` | 15.1.3 |
| C arrays `int a[10]` | `std::array<int, 10>` | 11.3.2 |
| `printf` | `std::format` or streams | 26.3.1 |

## Tool Comparison Matrix

### MISRA C:2012 Coverage

| Rule Group | Polyspace | QAC/Helix | PC-lint Plus | cppcheck | clang-tidy |
|------------|-----------|-----------|-------------|----------|------------|
| Mandatory (10) | 10/10 | 10/10 | 10/10 | 6/10 | 5/10 |
| Required (121) | 121/121 | 121/121 | 118/121 | 72/121 | 45/121 |
| Advisory (12) | 12/12 | 12/12 | 11/12 | 5/12 | 3/12 |
| **Total** | **143/143** | **143/143** | **139/143** | **83/143** | **53/143** |
| Certified | TUV SUD | TUV SUD | No | No | No |

### MISRA C++:2023 Coverage

| Aspect | Polyspace | QAC/Helix | Parasoft | PC-lint Plus |
|--------|-----------|-----------|----------|-------------|
| Rule coverage | ~95% | ~95% | ~90% | ~85% |
| C++17 support | Full | Full | Full | Full |
| Certified | TUV SUD | TUV SUD | TUV SUD | No |
| IDE integration | MATLAB, Eclipse | Eclipse, VS | Eclipse, VS, IntelliJ | IDE neutral |
| CI/CD integration | Jenkins, GitLab | Jenkins, GitLab | Jenkins, GitLab | Script-based |

## Deviation Quick Reference

### Deviation Categories

| Category | When to Use | Approval Required |
|----------|-------------|-------------------|
| Project-wide | Applies to all files (e.g., compiler intrinsic) | Safety manager + assessor |
| Module-wide | Applies to specific module (e.g., HAL) | Safety manager |
| Instance | Applies to specific code line | Lead developer + reviewer |

### Common Justified Deviations

| Rule | Deviation Reason | Typical Scope |
|------|-----------------|---------------|
| 11.3 | Hardware register access | HAL module only |
| 11.4 | Memory-mapped I/O address | HAL module only |
| 21.3 | Memory pool allocator (init only) | Startup code only |
| 21.6 | Debug logging (non-safety) | Debug build only |
| Dir 4.12 | Pool allocation at startup | Init phase only |
| 20.10 | Token pasting in test framework | Test code only |

## ASIL to MISRA Mapping

### ISO 26262-6 Table 1 Requirements

| ASIL | Coding Standard | Static Analysis | Defensive Programming |
|------|----------------|-----------------|----------------------|
| A | MISRA (recommended) | Recommended | Recommended |
| B | MISRA (recommended) | Recommended | Highly recommended |
| C | MISRA (highly recommended) | Highly recommended | Highly recommended |
| D | MISRA (highly recommended) | Highly recommended | Highly recommended |

### Minimum MISRA Compliance per ASIL

| ASIL | Mandatory Rules | Required Rules | Advisory Rules |
|------|----------------|----------------|----------------|
| QM | Not required | Not required | Not required |
| A | All enforced | Best effort | Optional |
| B | All enforced | All enforced | Best effort |
| C | All enforced | All enforced | Recommended |
| D | All enforced | All enforced, zero deviations goal | All enforced |

## Compliance Checklist

- [ ] Static analysis tool selected and configured for MISRA edition
- [ ] All mandatory rules enabled and enforced
- [ ] All required rules enabled and enforced
- [ ] Advisory rules enabled (enforced or documented as disapplied)
- [ ] Guideline Re-categorization Plan (GRP) documented
- [ ] Deviation process established and documented
- [ ] All deviations have formal deviation records
- [ ] All deviations reviewed and approved
- [ ] Compliance matrix maintained and current
- [ ] Tool validation summary available
- [ ] Baseline established (zero new violations policy)

## References

- MISRA C:2012 (3rd Edition, AMD 2)
- MISRA C:2023
- MISRA C++:2023
- MISRA Compliance:2020
- ISO 26262-6:2018 Tables 1-13

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: All project team members

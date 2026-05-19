# ISO 26262 Functional Safety - Quick Start Guide

## What You Have

### 6 Production-Ready Skills
1. **ISO 26262 Overview** - Standard structure, V-model, ASIL determination
2. **HARA** - Hazard analysis, S/E/C classification, ASIL tables
3. **Safety Mechanisms** - 1500+ lines C code (redundancy, watchdogs, CRC, memory protection)
4. **FMEA/FTA** - Complete analysis methodology + Python calculators
5. **Software Safety** - ASIL-D development, MISRA, MC/DC, safety manual
6. **V&V** - Verification/validation methods, HIL testing, assessment

### 2 Expert Agents
1. **Safety Engineer** - HARA execution, FMEA/FTA, safety concept, metrics
2. **Safety Assessor** - Independent assessment, V&V review, certification support

### 25+ Templates
- HARA worksheets (YAML, Excel, SQL)
- FMEA/FMEDA spreadsheets
- FTA diagrams and calculators
- Software Safety Manual (10 sections)
- Assessment reports
- Test specifications

### 2500+ Lines of Code
- C/C++: Redundancy, watchdogs, CRC, memory protection
- Python: FMEDA calculator, FTA analyzer, HIL tests
- SQL: Traceability databases

## 5-Minute Start

### For New ASIL-D Project

**Day 1: Learn Basics**
```bash
Read: skills/automotive-safety/iso-26262-overview.md
Focus: ASIL determination table (S/E/C → ASIL)
Time: 30 minutes
```

**Week 1: HARA**
```bash
Read: skills/automotive-safety/hazard-analysis-risk-assessment.md
Use: HARA worksheet template (YAML)
Output: 10-15 hazardous events with ASIL ratings
Time: 2-3 days (with team workshop)
```

**Week 2-4: Safety Concept**
```bash
Read: skills/automotive-safety/safety-mechanisms-patterns.md
Select: Architecture pattern (1oo2, lockstep, 2oo3)
Output: Technical Safety Concept
Time: 2 weeks
```

**Week 5-8: Analysis**
```bash
Read: skills/automotive-safety/fmea-fta-analysis.md
Use: Python FMEDA calculator
Target: SPFM > 99%, LFM > 90%, PMHF < 10 FIT
Time: 3-4 weeks
```

### For Assessment Preparation

**3 Weeks Before**
```bash
Read: skills/automotive-safety/safety-verification-validation.md
Agent: safety-assessor.md (readiness check)
Action: Close critical gaps
```

**1 Week Before**
```bash
Action: Prepare evidence package
Tool: Traceability database
Output: Complete documentation set
```

## Critical ASIL-D Requirements

### Must-Have (Cannot Skip)

✓ **HARA:** All hazardous events analyzed (S/E/C → ASIL)
✓ **Safety Goals:** Defined for all ASIL-rated events
✓ **FMEA:** All components, failure modes identified
✓ **FTA:** Performed for all ASIL C/D safety goals
✓ **Metrics:** SPFM > 99%, LFM > 90%, PMHF < 10 FIT
✓ **MC/DC:** 100% coverage for safety-critical software
✓ **MISRA:** 0 critical violations
✓ **Traceability:** 100% from safety goals to tests
✓ **Independent Assessment:** Positive recommendation

### Common Mistakes to Avoid

✗ **HARA too high-level:** Analyze specific malfunctions, not "system fails"
✗ **ASIL guessing:** Use S/E/C table, provide evidence
✗ **FMEA missing failure modes:** Review at component level
✗ **Ignoring PMHF:** Calculate early, iterate design if > target
✗ **MC/DC shortcuts:** Tool-qualified coverage required
✗ **Late assessment:** Engage assessor at concept phase

## File Locations

```
automotive-claude-code-agents/
├── skills/automotive-safety/
│   ├── iso-26262-overview.md (20 KB)
│   ├── hazard-analysis-risk-assessment.md (29 KB)
│   ├── safety-mechanisms-patterns.md (30 KB)
│   ├── fmea-fta-analysis.md (28 KB)
│   ├── software-safety-requirements.md (24 KB)
│   ├── safety-verification-validation.md (30 KB)
│   └── README.md (8 KB)
│
├── agents/functional-safety/
│   ├── safety-engineer.md (21 KB)
│   └── safety-assessor.md (34 KB)
│
├── FUNCTIONAL_SAFETY_DELIVERABLES.md (32 KB - MASTER DOCUMENT)
└── FUNCTIONAL_SAFETY_QUICK_START.md (this file)
```

## Next Steps

**1. Read Overview (30 min)**
→ `/skills/automotive-safety/iso-26262-overview.md`

**2. Execute HARA (1 week)**
→ `/skills/automotive-safety/hazard-analysis-risk-assessment.md`
→ Use HARA worksheet template

**3. Design Safety Architecture (2 weeks)**
→ `/skills/automotive-safety/safety-mechanisms-patterns.md`
→ Select redundancy pattern, implement safety mechanisms

**4. Perform Analysis (3 weeks)**
→ `/skills/automotive-safety/fmea-fta-analysis.md`
→ Calculate SPFM/LFM/PMHF, verify targets

**5. Develop Software (12+ weeks)**
→ `/skills/automotive-safety/software-safety-requirements.md`
→ MISRA compliance, MC/DC testing

**6. Verify & Validate (8+ weeks)**
→ `/skills/automotive-safety/safety-verification-validation.md`
→ HIL testing, fault injection, assessment

## Get Help

**For Technical Questions:**
→ Use agent: `/agents/functional-safety/safety-engineer.md`

**For Assessment Questions:**
→ Use agent: `/agents/functional-safety/safety-assessor.md`

**For Complete Reference:**
→ Read: `/FUNCTIONAL_SAFETY_DELIVERABLES.md`

## Metrics Cheat Sheet

| ASIL | SPFM | LFM | PMHF | Coverage |
|------|------|-----|------|----------|
| A | - | - | < 1000 FIT | Statement |
| B | > 90% | > 60% | < 100 FIT | Branch |
| C | > 97% | > 80% | < 100 FIT | MC/DC (rec) |
| D | > 99% | > 90% | < 10 FIT | MC/DC (req) |

**FIT = Failures In Time (1 FIT = 1 failure in 10^9 hours)**

## Ready to Start?

```bash
# Start with the overview
cd /home/rpi/Opensource/automotive-claude-code-agents
cat skills/automotive-safety/iso-26262-overview.md

# Then read the complete deliverables summary
cat FUNCTIONAL_SAFETY_DELIVERABLES.md

# Use agents for interactive help
# (engage via your Claude Code interface)
```

**All content is authentication-free and production-ready!**

---
*Last Updated: 2024-03-19*
*Version: 1.0*

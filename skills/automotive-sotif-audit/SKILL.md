---
name: automotive-sotif-audit
description: >
  Automotive Sotif Audit expertise. Covers 1 topics: Sotif Audit.
tags: [automotive, automotive-sotif-audit]
---

# Automotive Sotif Audit

## Sotif Audit

# SOTIF Audit & Assessment — Process Maturity and Compliance Evaluation

## Overview

Systematic audit and assessment framework for evaluating SOTIF (ISO 21448) implementation maturity across the product development lifecycle. Provides audit checklists, maturity models, and gap assessment tools for ADAS/ADS projects.

## SOTIF Maturity Model

```
SOTIF实施成熟度模型（5级）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Level 1: Initial (初始级)
  ├── 无系统性SOTIF流程
  ├── 依赖个人经验识别风险
  ├── 测试以功能验证为主
  └── 无SOTIF专项文档

Level 2: Managed (管理级)
  ├── 基本SOTIF分析流程建立
  ├── 触发条件清单初步建立
  ├── 部分场景覆盖仿真
  ├── SOTIF角色分配
  └── 基础文档体系

Level 3: Defined (定义级)
  ├── 完整SOTIF流程贯穿V模型
  ├── 系统化触发条件识别方法
  ├── 场景库建立（>500场景）
  ├── 量化覆盖度指标
  ├── 跨部门协作机制
  └── 与功能安全/网络安全集成

Level 4: Quantitatively Managed (量化管理级)
  ├── 基于数据的残余风险量化
  ├── 自然驾驶数据驱动场景扩展
  ├── 持续监控与闭环反馈
  ├── 仿真-实车-运营数据链路
  └── 预测性风险评估

Level 5: Optimizing (优化级)
  ├── AI辅助场景发现
  ├── 持续学习与自适应安全
  ├── 行业基准对标
  ├── 前瞻性标准影响
  └── 跨OEM经验共享
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Audit Checklist

### Phase 1: Specification & Design (ISO 21448 Clause 5-7)

```markdown
## SOTIF Specification & Design Audit

### 5. Functional and System Specification
- [ ] System functions clearly defined with intended behavior
- [ ] ODD boundaries explicitly specified
- [ ] Performance limitations documented per sensor/algorithm
- [ ] Known functional insufficiencies identified
- [ ] System architecture supports SOTIF analysis

### 6. Identification of Triggering Conditions & Hazardous Behaviors
- [ ] Systematic method for triggering condition identification (STPA/HAZOP/brainstorming)
- [ ] Triggering conditions categorized by source (sensor/algorithm/human/infrastructure)
- [ ] Functional insufficiency chain analysis (TC → FI → HB → Harm)
- [ ] Severity/Exposure/Controllability assessment per hazardous behavior
- [ ] Coverage of China-specific triggering conditions (if applicable)
- [ ] Triggering condition catalog maintained and version-controlled

### 7. Evaluation of Known Hazardous Scenarios
- [ ] Hazardous scenario catalog established
- [ ] Risk assessment performed (S/E/C or similar)
- [ ] Acceptance criteria defined for residual risk
- [ ] Scenarios prioritized for V&V
- [ ] Traceability from TC to test cases
```

### Phase 2: Design Measures (ISO 21448 Clause 8-9)

```markdown
## SOTIF Design Measures Audit

### 8. Functional Modifications to Reduce Risk
- [ ] Design measures identified for each known hazardous scenario
- [ ] Sensor fusion strategy addresses individual sensor limitations
- [ ] Algorithm robustness measures (redundancy, plausibility checks)
- [ ] ODD monitoring and graceful degradation implemented
- [ ] DMS integration for human factor mitigation
- [ ] Effectiveness of measures verified (before/after risk comparison)

### 9. Risk Evaluation of Residual Scenarios
- [ ] Residual risk quantification method defined
- [ ] Acceptance criteria for residual risk established
- [ ] Comparison with societal acceptance levels
- [ ] Statistical evidence for residual risk claims
- [ ] Gap between required and achieved evidence documented
```

### Phase 3: Verification & Validation (ISO 21448 Clause 10-11)

```markdown
## SOTIF V&V Audit

### 10. Verification of Known Scenarios
- [ ] Simulation test plan for known hazardous scenarios
- [ ] Simulation platform qualified (model validation)
- [ ] Track test plan with scenario coverage mapping
- [ ] Public road test plan with exposure tracking
- [ ] Pass/fail criteria defined per scenario
- [ ] Test coverage metrics tracked and reported
- [ ] Failed scenarios → design iteration loop documented

### 11. Validation of Unknown Scenarios
- [ ] Strategy for discovering unknown unsafe scenarios
- [ ] Naturalistic driving data analysis methodology
- [ ] Exploratory testing methods (fuzzing, adversarial testing)
- [ ] Field monitoring and incident analysis process
- [ ] Statistical argument for absence of unreasonable risk
- [ ] Confidence level in residual risk assessment
```

### Phase 4: Operations & Post-Market (ISO 21448 Clause 12)

```markdown
## SOTIF Operations Audit

### 12. Post-Development Activities
- [ ] Field monitoring system deployed
- [ ] Incident reporting and analysis process
- [ ] Near-miss detection capability
- [ ] OTA update process for SOTIF improvements
- [ ] Customer complaint analysis for SOTIF issues
- [ ] Periodic SOTIF reassessment trigger criteria
- [ ] Regulatory reporting compliance (if applicable)
```

## Assessment Scoring Framework

```python
# SOTIF Audit Scoring
audit_categories = {
    "specification": {
        "weight": 0.20,
        "items": [
            ("Function specification completeness", 10),
            ("ODD definition clarity", 10),
            ("Performance limitation documentation", 10),
        ],
    },
    "hazard_identification": {
        "weight": 0.25,
        "items": [
            ("Triggering condition identification method", 10),
            ("TC catalog completeness", 10),
            ("Hazardous behavior analysis depth", 10),
            ("Risk assessment quality", 10),
        ],
    },
    "design_measures": {
        "weight": 0.20,
        "items": [
            ("Measure effectiveness", 10),
            ("Residual risk quantification", 10),
            ("Acceptance criteria appropriateness", 10),
        ],
    },
    "verification_validation": {
        "weight": 0.25,
        "items": [
            ("Simulation test coverage", 10),
            ("Track test execution", 10),
            ("Public road evidence", 10),
            ("Unknown scenario exploration", 10),
        ],
    },
    "operations": {
        "weight": 0.10,
        "items": [
            ("Field monitoring", 10),
            ("Incident analysis process", 10),
            ("Continuous improvement", 10),
        ],
    },
}

def calculate_sotif_score(scores: dict) -> dict:
    """Calculate weighted SOTIF audit score"""
    category_scores = {}
    total = 0
    for cat, config in audit_categories.items():
        max_points = sum(item[1] for item in config["items"])
        actual = sum(scores.get(cat, {}).get(item[0], 0) for item in config["items"])
        pct = actual / max_points * 100
        category_scores[cat] = pct
        total += pct * config["weight"]

    return {
        "category_scores": category_scores,
        "total_score": total,
        "maturity_level": (
            5 if total >= 90 else
            4 if total >= 75 else
            3 if total >= 60 else
            2 if total >= 40 else
            1
        ),
    }
```

## Common Audit Findings

```
常见SOTIF审核发现
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Finding 1: ODD定义不充分
  ├── 问题：ODD仅列出道路类型，未定义环境/天气/基础设施边界
  └── 建议：使用6层场景模型系统定义ODD

Finding 2: 触发条件识别不系统
  ├── 问题：依赖头脑风暴，缺少系统方法
  └── 建议：采用STPA+HAZOP+历史事故分析组合方法

Finding 3: 仿真与实车测试脱节
  ├── 问题：仿真场景与实车测试场景不对应
  └── 建议：建立统一场景库，仿真-实车-数据三位一体

Finding 4: 残余风险论证不足
  ├── 问题：缺少定量证据支撑"风险可接受"结论
  └── 建议：基于自然驾驶暴露数据量化残余风险

Finding 5: 未知不安全场景探索缺失
  ├── 问题：仅测试已知场景，未探索未知风险
  └── 建议：引入NDD分析、对抗测试、随机化测试
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Deliverables

1. **Audit Report**: Structured findings with severity and recommendations
2. **Maturity Assessment**: Current level and improvement roadmap
3. **Gap Analysis**: Requirements vs. implementation status
4. **Improvement Plan**: Prioritized actions with timeline
5. **Benchmark Report**: Comparison with industry best practices

## Related Skills

- `automotive-sotif-hazard-scenario` — Scenario identification methodology
- `automotive-sotif-highway-testing` — Highway SOTIF testing specifics
- `iso-26262-overview` — Functional safety baseline

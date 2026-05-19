---
name: china-scenario-safety
description: >
  China standard: Scenario Safety. # 场景安全评估框架 — ISO 34501/34502 + ISO 34503/34504/34505
tags: [automotive, china-standards, scenario-safety]
---

# Scenario Safety — China Standard

# 场景安全评估框架 — ISO 34501/34502 + ISO 34503/34504/34505

## 标准集一览

| 标准编号 | 名称 | 状态 | 推荐等级 |
|---------|------|------|---------|
| ISO 34501:2022 | 自动驾驶系统测试场景 术语 | 已发布 | P1 |
| ISO 34502:2022 | 基于场景的安全评估框架 | 已发布 | P1 |
| ISO 34502 GB征求意见稿 | 基于场景的安全评估框架(中国版) | 征求意见稿 | P3 |
| ISO 34503/34504/34505 | 场景描述/分类/生成方法 | DIS阶段 | P3 |

---

## ISO 34502:2022 基于场景的安全评估工程框架

### 核心概念

```
场景安全评估三层模型
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Functional Scenario (功能场景)
  └── 自然语言描述的抽象场景
  └── 例："高速公路上前车突然变道，暴露前方静止车辆"

Logical Scenario (逻辑场景)
  └── 参数化描述，参数取值为范围/分布
  └── 例：ego_speed ∈ [100,120] km/h,
          target_speed = 0 km/h,
          cut_out_ttc ∈ [2.0, 5.0] s

Concrete Scenario (具体场景)
  └── 所有参数赋具体值的可执行场景
  └── 例：ego_speed = 110 km/h,
          target_speed = 0 km/h,
          cut_out_ttc = 3.2 s
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 安全评估流程

```
ISO 34502 安全评估流程
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase 1: 场景识别
  ├── 从标准/法规提取
  ├── 从事故数据提取
  ├── 从自然驾驶数据提取
  └── 专家知识补充

Phase 2: 场景描述与参数化
  ├── 功能场景定义
  ├── 逻辑场景参数化
  └── 参数空间定义

Phase 3: 场景选择
  ├── 基于风险的优先级排序
  ├── 覆盖度分析
  └── 测试资源分配

Phase 4: 场景执行
  ├── 仿真测试（批量执行）
  ├── 封闭场地测试（关键场景）
  └── 开放道路测试（真实环境）

Phase 5: 安全论证
  ├── 通过率统计
  ├── 覆盖度论证
  ├── 残余风险评估
  └── 安全案例构建
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 与DFM框架的关联

```
ISO 34502 ↔ DFM关联
├── ISO 34502定义了场景安全评估的工程框架
├── DFM（驾驶员基础模型）提供：
│   ├── 人类驾驶行为基线（作为安全参考）
│   ├── 场景暴露频率（基于大规模NDD）
│   ├── 场景参数分布（基于7.5M+轨迹数据）
│   └── 场景批评性量化指标
└── 组合使用：DFM为ISO 34502提供数据驱动的场景选择和安全论证
```

## ISO 34503/34504/34505 场景标准族（P3）

```
ISO 3450x 场景标准族
├── ISO 34503: Specification of Operational Design Domain
│   └── ODD描述方法和分类框架
├── ISO 34504: Scenario Categorization
│   └── 场景分类方法（基于抽象层次）
└── ISO 34505: Scenario Generation and Selection
    └── 场景生成和选择方法
```

## 相关技能

- `skills/china-standards/sotif/` — SOTIF标准集
- `skills/china-standards/odd/` — ODD标准
- `skills/automotive-scenario-driven-testing/` — 场景驱动测试方法
- `skills/automotive-dfm-benchmarking/` — DFM基准评测

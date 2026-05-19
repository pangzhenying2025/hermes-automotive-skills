---
name: china-functional-safety
description: >
  China standard: Functional Safety. # GB/T 34590-2022 道路车辆 功能安全（12部分）
tags: [automotive, china-standards, functional-safety]
---

# Functional Safety — China Standard

# GB/T 34590-2022 道路车辆 功能安全（12部分）

## 标准信息

| 属性 | 值 |
|------|-----|
| **标准编号** | GB/T 34590-2022 |
| **中文名称** | 道路车辆 功能安全 |
| **英文名称** | Road vehicles — Functional safety |
| **类别** | 国家推荐性标准 |
| **状态** | 已发布（2022年） |
| **等同标准** | ISO 26262:2018（IDT） |
| **推荐等级** | P1-强烈推荐 |
| **适用范围** | 乘用车及商用车电子电气系统功能安全全生命周期 |

## 标准结构（12部分）

```
GB/T 34590-2022 道路车辆 功能安全
├── 第1部分：术语 (Vocabulary)
├── 第2部分：功能安全管理 (Management of functional safety)
├── 第3部分：概念阶段 (Concept phase)
│   ├── 项目定义
│   ├── 危害分析和风险评估 (HARA)
│   └── 功能安全概念 (FSC)
├── 第4部分：产品开发：系统层面 (System level)
│   ├── 技术安全概念 (TSC)
│   ├── 系统设计
│   └── 安全验证与安全确认
├── 第5部分：产品开发：硬件层面 (Hardware level)
│   ├── 硬件安全度量
│   ├── 单点故障度量 (SPFM)
│   ├── 潜伏故障度量 (LFM)
│   └── 硬件架构度量 (PMHF)
├── 第6部分：产品开发：软件层面 (Software level)
│   ├── 软件安全需求
│   ├── 软件架构设计
│   ├── 软件单元设计与实现
│   └── 软件验证
├── 第7部分：生产、运行、服务和退役 (Production, operation, service, decommissioning)
├── 第8部分：支持过程 (Supporting processes)
│   ├── 配置管理
│   ├── 变更管理
│   ├── 验证
│   └── 文档管理
├── 第9部分：以汽车安全完整性等级为导向和以安全为导向的分析
│   ├── ASIL 分解
│   ├── 相关失效分析 (DFA)
│   ├── 安全分析方法 (FMEA, FTA, ETA)
│   └── 共因分析
├── 第10部分：GB/T 34590 指南 (Guideline)
├── 第11部分：半导体应用指南 (Semiconductor guideline)
└── 第12部分：摩托车适配 (Adaptation for motorcycles)
```

## ASIL 等级体系

### HARA 三维度评估

```
危害分析与风险评估 (HARA)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

严重度 (Severity):
  S0: 无伤害
  S1: 轻度伤害（可能生存）
  S2: 重度伤害（可能生存，高风险治疗）
  S3: 致命伤害（危及生命/致命）

暴露率 (Exposure):
  E0: 不可能
  E1: 极低概率
  E2: 低概率
  E3: 中等概率
  E4: 高概率（几乎在所有运行条件下）

可控性 (Controllability):
  C0: 一般可控
  C1: 简单可控（>99%驾驶员可控）
  C2: 正常可控（>90%驾驶员可控）
  C3: 难以控制或不可控（<90%驾驶员可控）

ASIL 确定矩阵:
  S1+E2+C2 = QM
  S1+E3+C3 = ASIL A
  S2+E3+C2 = ASIL A
  S2+E4+C3 = ASIL C
  S3+E3+C3 = ASIL C
  S3+E4+C2 = ASIL C
  S3+E4+C3 = ASIL D
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ASIL 分解规则（第9部分）

```
ASIL 分解原则（冗余元素独立性）:
  ASIL D = ASIL D(D) + QM(D)          [单一元素]
  ASIL D = ASIL C(D) + ASIL A(D)      [两元素分解]
  ASIL D = ASIL B(D) + ASIL B(D)      [两元素分解]
  ASIL C = ASIL B(C) + ASIL A(C)      [两元素分解]
  ASIL C = ASIL A(C) + ASIL A(C) + QM(C) [三元素分解]

注：(D)/(C)表示分解来源的ASIL等级
要求：分解后的元素必须满足独立性要求（共因分析）
```

## 中国本地化实践要点

```
GB/T 34590 与 ISO 26262 差异与实践
├── 技术内容等同（IDT），无实质差异
├── 中国实践特殊考虑：
│   ├── HARA暴露率：需使用中国道路交通数据
│   │   ├── 高速公路比例/城市道路比例
│   │   ├── 中国特有交通参与者（电动自行车、三轮车）
│   │   └── 中国交通事故类型分布
│   ├── 安全目标：需覆盖中国特有工况
│   │   ├── 团雾（局部浓雾）
│   │   ├── 施工区域（频率高于欧洲）
│   │   └── 混合交通（非机动车混行）
│   ├── 供应链：中国Tier1安全文化差异
│   │   ├── DIA/SEooC合规程度参差不齐
│   │   └── 需要加强安全管理培训
│   └── 认证：中国暂无强制FuSa认证
│       ├── CATARC提供ISO 26262评估服务
│       ├── TÜV SÜD/SGS等在华机构
│       └── 未来可能与准入挂钩
```

## 与其他标准的关系

| 标准 | 关系 | 说明 |
|------|------|------|
| GB/T 43267 (SOTIF) | 互补 | FuSa处理系统故障，SOTIF处理功能不足 |
| ISO PAS 8800 (AI Safety) | 扩展 | AI系统的FuSa适配 |
| ISO PAS 8926 | 补充 | 已有软件架构元素的安全使用 |
| GB/T 40857 (Cybersecurity) | 协同 | 网络安全与功能安全的交互分析 |

## 相关技能

- `skills/china-standards/sotif/` — 预期功能安全
- `skills/china-standards/l3-fusa-sotif/` — L3系统FuSa+SOTIF联合要求
- `skills/china-standards/ai-safety/` — AI安全标准

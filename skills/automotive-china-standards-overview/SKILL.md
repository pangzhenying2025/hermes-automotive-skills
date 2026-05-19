---
name: automotive-china-standards-overview
description: >
  Automotive China Standards Overview expertise. Covers 1 topics: China Standards Overview.
tags: [automotive, automotive-china-standards-overview]
---

# Automotive China Standards Overview

## China Standards Overview

# China Automotive Standards Overview — Intelligent Connected Vehicle Standard System

## Overview

Comprehensive reference for China's intelligent connected vehicle (ICV) standard system, covering all major standards related to ADAS, automated driving, functional safety, cybersecurity, V2X, and EV systems. This skill provides the landscape view for navigating the Chinese regulatory framework.

## Standard System Architecture

```
中国智能网联汽车标准体系架构（2023-2025版）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────────────────────────────────────┐
│            基础类标准 (Foundation)                 │
│  术语定义 │ 分类分级 │ 符号标识 │ 测试场景库       │
└─────────────────────────────────────────────────┘
┌──────────────────────┬──────────────────────────┐
│    通用规范类标准      │      产品与技术应用类标准    │
│  (General Standards)  │  (Product & Technology)   │
├──────────────────────┤──────────────────────────┤
│ ■ 功能安全            │ ■ 信息感知                │
│ ■ 预期功能安全         │ ■ 决策预警                │
│ ■ 网络安全            │ ■ 控制执行                │
│ ■ 软件升级            │ ■ 信息交互（V2X）          │
│ ■ 数据安全            │ ■ 基础设施                │
│ ■ 模拟仿真            │ ■ 自动驾驶系统             │
│ ■ 测试评价            │   ├ L2组合驾驶辅助          │
│                      │   ├ L3有条件自动驾驶         │
│                      │   └ L4高度自动驾驶           │
│                      │ ■ 泊车系统                 │
│                      │ ■ 智能座舱                 │
└──────────────────────┴──────────────────────────┘
┌─────────────────────────────────────────────────┐
│           相关标准与法规 (Related)                  │
│  道路交通法 │ 产品准入 │ 保险责任 │ 地图测绘        │
└─────────────────────────────────────────────────┘
```

## Key Standards Quick Reference

### Mandatory National Standards (GB) — 强制性国标

| Standard No. | Name (CN) | Name (EN) | Status | Enforcement |
|-------------|-----------|-----------|--------|-------------|
| GB XXXX | 组合驾驶辅助系统安全要求 | L2 Combined Driving Assist Safety | Published | 2026 |
| GB XXXX | 自动驾驶系统安全要求 | L3 ADS Safety Requirements | Drafting | TBD |
| GB 39732 | 汽车事件数据记录系统 | Vehicle EDR | Published | 2022 |
| GB XXXX | 汽车整车信息安全技术要求 | Vehicle Cybersecurity | Drafting | TBD |
| GB XXXX | 汽车软件升级通用技术要求 | Vehicle Software Update | Drafting | TBD |

### Recommended National Standards (GB/T) — 推荐性国标

| Standard No. | Name (CN) | Domain |
|-------------|-----------|--------|
| GB/T 39263 | 道路车辆先进驾驶辅助系统术语及定义 | Terminology |
| GB/T 40429 | 汽车驾驶自动化分级 | Classification (SAE J3016 aligned) |
| GB/T 41798 | 智能网联汽车自动驾驶功能场景分类 | Scenario taxonomy |
| GB/T 41799 | 自动驾驶系统设计运行条件 | ODD definition |
| GB/T 40857 | 汽车网络安全管理体系 | Cybersecurity (ISO 21434 aligned) |
| GB/T 38186 | 商用车辆AEBS性能要求和试验方法 | Commercial vehicle AEBS |
| GB/T 39901 | 乘用车自动紧急制动系统（AEBS）性能要求 | Passenger car AEBS |
| GB/T XXXX | 泊车辅助系统性能要求 | Parking assist |
| GB/T XXXX | 泊车功能安全要求 | Parking functional safety |
| GB/T XXXX | 泊车预期功能安全要求 | Parking SOTIF |

### International Standard Alignment

```
中国标准 ←→ 国际标准对照
─────────────────────────────────────────────
GB/T 34590  ←→  ISO 26262   功能安全
GB/T XXXX   ←→  ISO 21448   预期功能安全
GB/T 40857  ←→  ISO 21434   网络安全
GB/T XXXX   ←→  ISO 24089   软件升级
GB/T 40429  ←→  SAE J3016   自动化分级
GB XXXX     ←→  UN R157     L3 ALKS
GB/T XXXX   ←→  UN R79      转向（ACSF）
GB/T XXXX   ←→  UN R131     AEBS
GB XXXX     ←→  UN R155     网络安全
GB XXXX     ←→  UN R156     软件更新
GB 39732    ←→  UN R160     EDR
─────────────────────────────────────────────
```

## Regulatory Bodies & Their Roles

```
标准制定与监管机构
├── 工业和信息化部（MIIT）
│   ├── 车辆产品准入管理
│   ├── 智能网联汽车产品公告
│   └── 软件升级备案管理
├── 国家标准化管理委员会（SAC）
│   ├── 国家标准立项与发布
│   └── TC114 全国汽车标准化技术委员会
│       ├── SC34 智能网联汽车分标委
│       ├── SC29 电动车辆分标委
│       └── 其他分标委
├── 公安部交通管理局
│   ├── 道路交通安全法修订
│   ├── 自动驾驶通行规则
│   └── 事故责任认定
├── 交通运输部
│   ├── 自动驾驶运营管理
│   └── 车路协同基础设施标准
├── 中国汽车技术研究中心（CATARC）
│   ├── 标准研究与起草
│   ├── 型式检验与认证
│   └── C-NCAP管理
├── 中国智能网联汽车产业创新联盟（CAICV）
│   ├── 团体标准制定
│   └── 产业生态协调
└── 地方主管部门
    ├── 测试牌照发放
    ├── 测试区域管理
    └── 商业化运营审批
```

## Standard Development Participation Guide

### How to Participate in Chinese Standard Development

```
参与标准制定流程
1. 加入标准化技术委员会（TC114/SC34）
   └── 成员单位资格：OEM/Tier1/研究机构/高校

2. 标准制定流程
   ├── 立项阶段 → 提交立项建议书
   ├── 起草阶段 → 参与工作组、提供技术输入
   ├── 征求意见稿 → 提交书面意见
   ├── 审查会议 → 参与投票表决
   ├── 报批阶段 → 最终审查
   └── 发布实施 → 宣贯培训

3. 参与方式
   ├── 正式成员：全程参与投票权
   ├── 观察员：会议旁听建议权
   └── 意见征集：公开征求意见阶段人人可参与
```

## Compliance Roadmap for OEMs/Tier1s

```
合规路线图（2024-2027）
─────────────────────────────────────────────────
2024 H1: 标准跟踪与差距分析
  ├── 建立标准监控机制
  ├── 现有产品合规差距评估
  └── 合规整改计划制定

2024 H2: 核心能力建设
  ├── 功能安全体系（ISO 26262/GB/T 34590）
  ├── SOTIF流程导入
  ├── 网络安全管理体系
  └── 测试能力建设

2025 H1: 产品合规开发
  ├── L2产品按GB强标要求开发
  ├── 泊车产品合规整改
  ├── DSSAD系统开发
  └── DMS系统升级

2025 H2: 验证与认证
  ├── 内部验证测试
  ├── 第三方测试（CATARC等）
  ├── 认证申请
  └── 型式批准

2026: L2强标执行
  ├── 新车型必须合规
  ├── 在售车型过渡期
  └── 后市场监管启动

2027+: L3准入推进
  ├── L3型式批准试行
  ├── 商业化运营许可
  └── 标准持续更新
─────────────────────────────────────────────────
```

## Deliverables

When invoked, this skill provides:
1. **Standards Landscape Map**: Visual overview of applicable standards
2. **Gap Analysis Template**: Current status vs. standard requirements
3. **Compliance Timeline**: Key milestones and deadlines
4. **Regulatory Body Contacts**: Relevant committees and organizations
5. **Standard Cross-Reference**: Mapping between Chinese and international standards

## Related Skills

- `automotive-china-l2-adas-compliance` — L2 mandatory standard details
- `automotive-china-l3-ads-compliance` — L3 standard details
- `automotive-china-parking-compliance` — Parking standard details
- `iso-26262-overview` — ISO 26262 functional safety

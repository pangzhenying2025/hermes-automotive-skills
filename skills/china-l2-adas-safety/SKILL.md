---
name: china-l2-adas-safety
description: >
  China standard: L2 Adas Safety. # L2 组合驾驶辅助系统安全要求（强制性国标草案）
tags: [automotive, china-standards, l2-adas-safety]
---

# L2 Adas Safety — China Standard

# L2 组合驾驶辅助系统安全要求（强制性国标草案）

## 标准信息

| 属性 | 值 |
|------|-----|
| **标准编号** | 待定（GB 强标） |
| **名称** | 智能网联汽车 组合驾驶辅助系统安全要求 |
| **状态** | 项目组草案 v2.1 |
| **推荐等级** | P2-推荐入选 |
| **性质** | 强制性国标，量产合规核心 |
| **核心内容** | L2 ADAS组合功能（ACC+LKA/LCC/TJA/ICA）安全要求 |

## 标准范围

适用于具有组合驾驶辅助功能的M类和N类车辆，要求同时具备纵向和横向控制的L2级功能。

### 覆盖功能

```
组合驾驶辅助功能分类
├── 基础组合：ACC + LKA
├── 进阶组合：ACC + LCC (车道居中)
├── 高级组合：ICA (集成巡航辅助 = ACC + LCC)
├── 拥堵辅助：TJA (交通拥堵辅助)
├── 高速辅助：HWA (高速公路辅助 = ICA + 换道辅助)
└── 相关独立功能：AEB, LDW, BSD, FCTA, RCTA
```

## 核心要求框架

```
L2强标安全要求架构
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. ODD定义要求
   ├── 道路类型/速度范围/天气条件
   └── ODD退出策略

2. 系统安全要求
   ├── 功能安全（基于GB/T 34590）
   ├── 预期功能安全（基于GB/T 43267）
   └── 网络安全

3. DMS强制要求
   ├── 注意力监测
   ├── 脱手检测
   ├── 疲劳检测
   └── 防滥用机制

4. HMI要求
   ├── 系统状态显示
   ├── 接管提醒分级
   └── 功能边界提示

5. 测试验证
   ├── 封闭场地测试
   ├── 开放道路测试
   └── 仿真测试
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

详细技术内容参见 `skills/automotive-china-l2-adas-compliance/china-l2-adas-compliance.md`

## 相关技能

- `skills/china-standards/ads-safety/` — ADS强制安全要求
- `skills/china-standards/l2-adas/` — L2 ADAS功能要求（16项）
- `skills/automotive-china-l2-adas-compliance/` — L2合规详细指南

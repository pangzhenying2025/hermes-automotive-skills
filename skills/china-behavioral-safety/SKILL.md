---
name: china-behavioral-safety
description: >
  China standard: Behavioral Safety. # IEEE 2846-2022 自动驾驶系统安全假设
tags: [automotive, china-standards, behavioral-safety]
---

# Behavioral Safety — China Standard

# IEEE 2846-2022 自动驾驶系统安全假设

## 标准信息

| 属性 | 值 |
|------|-----|
| **标准编号** | IEEE 2846-2022 |
| **名称** | A Framework for ADS Safety Assumptions |
| **状态** | 已发布（2022年） |
| **推荐等级** | P1-强烈推荐 |
| **核心内容** | 定义ADS行为安全模型，含RSS（Responsibility-Sensitive Safety）框架 |

## 核心概念

### 安全假设框架

```
IEEE 2846 安全假设体系
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. 合理预见行为 (Reasonably Foreseeable Behavior)
   └── 其他道路参与者的预期行为范围

2. 安全响应规则 (Safety Response Rules)
   └── ADS在各场景下的安全行为要求

3. 事故责任判定 (Blame Attribution)
   └── 当碰撞不可避免时的责任归属

4. 安全距离模型 (Safe Distance Model)
   ├── 纵向安全距离 = f(v_ego, v_front, a_max_brake, reaction_time)
   ├── 横向安全距离 = f(v_lateral, lane_width)
   └── 交叉路口安全模型
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### RSS安全距离模型

```python
# RSS纵向安全距离计算
def rss_longitudinal_safe_distance(
    v_ego: float,        # 自车速度 (m/s)
    v_front: float,      # 前车速度 (m/s)
    rho: float,          # 反应时间 (s), 通常取0.5-1.0s
    a_max_accel: float,  # 最大加速度 (m/s²)
    a_max_brake: float,  # 最大制动减速度 (m/s²)
    a_min_brake: float,  # 前车最小制动减速度 (m/s²)
) -> float:
    """
    d_safe = v_ego * rho + 0.5 * a_max_accel * rho²
             + (v_ego + rho * a_max_accel)² / (2 * a_max_brake)
             - v_front² / (2 * a_min_brake)
    """
    v_ego_after_reaction = v_ego + rho * a_max_accel
    d_ego_reaction = v_ego * rho + 0.5 * a_max_accel * rho**2
    d_ego_brake = v_ego_after_reaction**2 / (2 * a_max_brake)
    d_front_brake = v_front**2 / (2 * a_min_brake)
    return max(0, d_ego_reaction + d_ego_brake - d_front_brake)
```

### 中国场景适配

```
IEEE 2846 中国场景适配考虑
├── 反应时间参数：需考虑中国交通密度
├── 行为假设：电动自行车/三轮车行为模型
├── 交叉路口：中国特有交通规则（右转不停车等）
├── 高速公路：匝道合流行为差异
└── 责任判定：与中国交通法规对齐
```

## 相关技能

- `skills/china-standards/ads-safety/` — ADS安全要求
- `skills/china-standards/ai-safety/` — AI安全标准
- `skills/automotive-e2e-safety-analysis/` — 端到端安全分析

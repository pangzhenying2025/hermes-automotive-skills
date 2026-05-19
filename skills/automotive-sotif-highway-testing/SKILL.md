---
name: automotive-sotif-highway-testing
description: >
  Automotive Sotif Highway Testing expertise. Covers 1 topics: Sotif Highway Testing.
tags: [automotive, automotive-sotif-highway-testing]
---

# Automotive Sotif Highway Testing

## Sotif Highway Testing

# SOTIF Highway Testing & Evaluation — Structured Test Framework for Highway ADAS/ADS

## Overview

Specialized SOTIF testing framework for highway scenarios including ACC, LCC, ICA, HWA, and L3 highway pilot. Covers scenario design, test execution, performance evaluation, and evidence generation for ISO 21448 compliance on highway applications.

## Highway SOTIF Test Architecture

```
高速公路SOTIF测试架构
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ┌─────────────┐
            │  场景库       │
            │ Scenario DB  │
            └──────┬──────┘
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
┌─────────┐ ┌──────────┐ ┌──────────┐
│ 仿真测试  │ │ 场地测试  │ │ 道路测试  │
│   SiL    │ │  Track   │ │ Public   │
│  >10M km │ │  >1K km  │ │ >100K km │
└────┬────┘ └────┬─────┘ └────┬─────┘
     │           │            │
     └─────────┬─┴────────────┘
               ▼
        ┌──────────────┐
        │ 综合评估       │
        │ Assessment    │
        └──────────────┘
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Highway Critical Scenario Catalog

### Category 1: Longitudinal Scenarios

```python
longitudinal_scenarios = {
    "L-001_前车正常跟车": {
        "description": "Normal car-following on highway",
        "ego_speed_range": [60, 120],  # km/h
        "target_speed_range": [60, 120],
        "thw_range": [1.0, 3.0],  # time headway (s)
        "criticality": "low",
        "sotif_relevance": "baseline performance",
    },
    "L-002_前车紧急制动": {
        "description": "Lead vehicle emergency braking",
        "ego_speed": 120,
        "target_decel": [-6, -9.8],  # m/s²
        "initial_thw": [1.5, 2.5],
        "criticality": "high",
        "sotif_relevance": "perception delay + system response",
    },
    "L-003_前车切出暴露静止车辆": {
        "description": "Lead vehicle cut-out revealing stationary vehicle",
        "ego_speed": [100, 120],
        "target_speed": 0,
        "cut_out_ttc": [2.0, 5.0],  # s before collision
        "criticality": "critical",
        "sotif_relevance": "radar static filter + camera late detection",
        "known_accidents": "Tesla Autopilot incidents, NIO NOP incidents",
    },
    "L-004_旁车切入": {
        "description": "Adjacent vehicle cut-in",
        "ego_speed": [80, 120],
        "cut_in_speed": [60, 100],
        "overlap_rate": [0.5, 1.0],
        "cut_in_ttc": [1.0, 3.0],
        "criticality": "high",
        "sotif_relevance": "prediction + planning response",
    },
    "L-005_慢速车辆逼近": {
        "description": "Approaching slow vehicle (speed differential >40km/h)",
        "ego_speed": 120,
        "target_speed": [20, 60],
        "detection_distance_required": ">150m",
        "criticality": "high",
        "sotif_relevance": "long-range detection capability",
    },
}
```

### Category 2: Lateral Scenarios

```python
lateral_scenarios = {
    "LT-001_直道车道保持": {
        "description": "Lane keeping on straight highway",
        "ego_speed_range": [60, 120],
        "lane_width": [3.5, 3.75],  # m
        "marking_type": ["solid", "dashed"],
        "max_lateral_offset": 0.2,  # m, pass criteria
    },
    "LT-002_弯道车道保持": {
        "description": "Lane keeping in highway curves",
        "radius_range": [250, 2000],  # m
        "ego_speed_range": [60, 100],
        "max_lateral_offset": 0.35,  # m
        "sotif_relevance": "lane detection at curve entry/exit",
    },
    "LT-003_车道标线变化": {
        "description": "Lane marking type transition",
        "transitions": [
            "solid → dashed",
            "dashed → solid",
            "single → double",
            "white → yellow",
            "marking disappears",
            "temporary markings overlay",
        ],
        "criticality": "medium",
    },
    "LT-004_施工区域车道偏移": {
        "description": "Lane shift in construction zone",
        "offset": [0.5, 2.0],  # m lateral shift
        "transition_length": [50, 200],  # m
        "speed_limit": [60, 80],
        "sotif_relevance": "temporary marking detection, map deviation",
    },
}
```

### Category 3: Combined & Complex Scenarios

```python
combined_scenarios = {
    "C-001_弯道跟车+标线消失": {
        "description": "Car following in curve with lane marking loss",
        "layers": ["curvature", "lead_vehicle", "marking_loss"],
        "criticality": "critical",
        "triggering_conditions": [
            "Camera cannot detect worn markings in curve",
            "Lidar point cloud sparse in curve",
        ],
    },
    "C-002_隧道出入口+前车切出": {
        "description": "Tunnel entry/exit with lead vehicle cut-out",
        "layers": ["illumination_change", "lead_cut_out", "stationary_target"],
        "criticality": "critical",
        "triggering_conditions": [
            "Camera saturation at tunnel exit",
            "Radar multi-path in tunnel",
        ],
    },
    "C-003_团雾区域进入": {
        "description": "Entering localized fog patch on highway",
        "layers": ["sudden_visibility_drop", "preceding_traffic"],
        "visibility_drop": "from >1000m to <50m in <5s",
        "criticality": "critical",
        "china_specific": True,
        "sotif_relevance": "ODD exit detection speed",
    },
    "C-004_收费站接近": {
        "description": "Approaching highway toll station",
        "layers": ["lane_expansion", "speed_reduction", "infrastructure_change"],
        "criticality": "high",
        "china_specific": True,
        "sotif_relevance": "ODD boundary recognition, graceful exit",
    },
}
```

## Test Execution Framework

### Simulation Testing Protocol

```
仿真测试规程
├── 场景数量：>10,000 variation scenarios
├── 等效里程：>1,000万km
├── 平台要求
│   ├── 传感器模型精度：符合实车标定数据（±10%）
│   ├── 车辆动力学：经过验证的14DOF模型
│   ├── 环境模型：天气/光照/路面物理仿真
│   └── 交通模型：基于自然驾驶数据的交通流
├── 自动化执行
│   ├── 参数化场景批量生成
│   ├── 自动判定通过/失败
│   ├── 失败场景自动聚类分析
│   └── 覆盖度自动计算
└── 结果分析
    ├── 通过率统计
    ├── 失败模式分类
    ├── 边界条件识别
    └── 回归测试基线
```

### Track Testing Protocol

```
场地测试规程
├── 测试场地：国家智能网联汽车测试场
├── 目标设备
│   ├── 软目标车（GST/SST）
│   ├── 行人假人（Euro NCAP型）
│   ├── 二轮车假人
│   └── 低矮障碍物（锥桶/轮挡）
├── 测试矩阵
│   ├── 速度：每10km/h步进（40-120km/h）
│   ├── 重复次数：每条件>=5次
│   ├── 环境：晴天/雨天/夜间
│   └── 传感器状态：正常/降级
├── 数据采集
│   ├── DGPS定位（RTK精度）
│   ├── 高速相机（360°环视）
│   ├── CAN总线完整记录
│   └── 传感器原始数据
└── 判定标准
    ├── 定量指标（距离/时间/偏移量）
    ├── 定性评估（系统行为合理性）
    └── 安全边界（碰撞=失败）
```

## Performance Evaluation Metrics

```python
# Highway SOTIF Performance KPIs
performance_kpis = {
    "safety": {
        "collision_rate": {"target": 0, "unit": "per test"},
        "ttc_minimum": {"target": ">1.5s", "unit": "seconds"},
        "false_negative_rate": {"target": "<0.001", "unit": "per scenario"},
    },
    "availability": {
        "system_uptime_in_odd": {"target": ">99.5%", "unit": "percent"},
        "graceful_degradation_success": {"target": "100%", "unit": "percent"},
        "odd_exit_detection_time": {"target": "<2s", "unit": "seconds"},
    },
    "comfort": {
        "max_lateral_acceleration": {"target": "<2.5 m/s²", "unit": "m/s²"},
        "max_longitudinal_jerk": {"target": "<5 m/s³", "unit": "m/s³"},
        "lane_keeping_smoothness": {"target": "σ<0.1m", "unit": "meters"},
    },
    "false_activation": {
        "false_braking_rate": {"target": "<0.1/100km", "unit": "per 100km"},
        "false_steering_rate": {"target": "<0.05/100km", "unit": "per 100km"},
        "false_warning_rate": {"target": "<0.5/100km", "unit": "per 100km"},
    },
}
```

## Deliverables

1. **Test Plan**: Scenario-based highway SOTIF test plan
2. **Scenario Matrix**: Parameterized scenario definitions with pass criteria
3. **Test Report**: Results with coverage analysis and gap identification
4. **Evidence Package**: Statistical evidence for ISO 21448 compliance
5. **Improvement Recommendations**: Per-scenario failure analysis and fixes

## Related Skills

- `automotive-sotif-hazard-scenario` — Scenario construction methodology
- `automotive-sotif-audit` — SOTIF process audit
- `automotive-scenario-driven-testing` — General scenario-driven V&V
- `automotive-china-l2-adas-compliance` — China L2 testing requirements

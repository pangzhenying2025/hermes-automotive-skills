---
name: automotive-china-l3-ads-compliance
description: >
  Automotive China L3 Ads Compliance expertise. Covers 1 topics: China L3 Ads Compliance.
tags: [automotive, automotive-china-l3-ads-compliance]
---

# Automotive China L3 Ads Compliance

## China L3 Ads Compliance

# China L3 Automated Driving System Compliance — Safety Requirements for Conditional Automation

## Overview

Expert guidance for compliance with China's national standard for L3 Conditional Automated Driving Systems (有条件自动驾驶系统). This standard is currently under development and addresses safety requirements for vehicles where the system performs the entire DDT within defined ODD, with the expectation that the human driver responds to intervention requests.

## Regulatory Context

### Standard Status & Timeline

```
中国L3标准进程
├── 2023: 征求意见稿发布
├── 2024: 标准修订与行业反馈
├── 2025: 报批稿与试行
├── 2026+: 正式实施（预计）
└── 试点城市：
    ├── 北京（亦庄）
    ├── 上海（嘉定/临港）
    ├── 深圳（经济特区立法）
    ├── 广州
    ├── 重庆
    └── 武汉
```

### Regulatory Framework

```
中国L3法规体系
├── 国家层面
│   ├── GB — L3自动驾驶系统安全要求（制定中）
│   ├── 工信部 — 智能网联汽车产品准入管理
│   ├── 公安部 — 自动驾驶道路通行管理
│   └── 交通运输部 — 自动驾驶运营管理
├── 地方层面
│   ├── 深圳 — 智能网联汽车管理条例（2022年8月施行）
│   ├── 北京 — 自动驾驶测试管理实施细则
│   └── 上海 — 智能网联汽车测试与示范实施办法
└── 国际对标
    ├── UN R157 — ALKS (Automated Lane Keeping System)
    ├── UN R79 Rev.4 — Steering equipment (ACSF)
    └── ISO 34502 — Test scenarios for ADS
```

## L3 System Architecture Requirements

### System Boundary Definition

```
L3自动驾驶系统边界
┌─────────────────────────────────────────────────────┐
│                    L3 ADS System                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ 感知系统  │  │ 决策系统  │  │  执行系统         │  │
│  │ Cameras  │→│ Planning │→│  Steering        │  │
│  │ Radars   │  │ Decision │  │  Braking         │  │
│  │ Lidars   │  │ Path Gen │  │  Acceleration    │  │
│  │ USS      │  │          │  │                  │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ 定位系统  │  │ DMS监控  │  │  HMI系统         │  │
│  │ GNSS/IMU │  │ Driver   │  │  Visual/Audio/   │  │
│  │ HD Map   │  │ Monitor  │  │  Haptic          │  │
│  │ V2X      │  │ System   │  │                  │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
│  ┌──────────────────────────────────────────────┐   │
│  │              安全冗余系统                       │   │
│  │  Redundant Sensing | MRC Controller | E-Stop  │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### ODD Definition Requirements

```python
# L3 ODD Definition Template (China)
l3_odd_definition = {
    "道路类型": {
        "高速公路": {
            "车道数": ">=2",
            "中央分隔带": "有物理隔离",
            "速度范围": "0-120 km/h",
            "曲率半径": ">500m",
        },
        "城市快速路": {
            "车道数": ">=2",
            "中央分隔带": "有隔离",
            "速度范围": "0-80 km/h",
        },
    },
    "天气条件": {
        "可运行": ["晴天", "多云", "小雨"],
        "降级运行": ["中雨", "轻雾（能见度>200m）"],
        "不可运行": ["大雨", "暴雨", "大雾（能见度<200m）", "冰雪路面", "沙尘暴"],
    },
    "交通条件": {
        "可运行": ["正常交通流", "拥堵（Stop&Go）"],
        "不可运行": ["施工区域", "事故现场", "交警指挥"],
    },
    "基础设施": {
        "车道标线": "清晰可见（反射率>150mcd/lx/m²）",
        "高精地图": "覆盖且时效性<3个月",
        "通信": "4G/5G信号可用（如需V2X）",
    },
    "时间条件": {
        "昼间": "可运行",
        "夜间": "可运行（有路灯照明）",
        "黎明/黄昏": "降级运行",
    },
}
```

## Core Compliance Requirements

### 1. Dynamic Driving Task (DDT) Performance

```
动态驾驶任务要求
├── 纵向控制
│   ├── 速度控制精度：±3 km/h
│   ├── 跟车时距：1.0s-2.5s可配置
│   ├── 最大制动减速度：-6 m/s²（舒适），-9.8 m/s²（紧急）
│   ├── 加速度限制：+3 m/s²（舒适）
│   └── 停车精度：±0.5m
├── 横向控制
│   ├── 车道居中偏差：<0.15m（直道），<0.3m（弯道）
│   ├── 最大横向加速度：<3 m/s²
│   ├── 转向速率限制：<500°/s
│   └── 车道变换执行时间：3-6s
├── 目标和事件检测与响应（OEDR）
│   ├── 检测范围：前方>200m，侧方>50m，后方>100m
│   ├── 检测延迟：<200ms
│   ├── 分类准确率：>99.5%（车辆），>99%（行人），>98%（二轮车）
│   └── 虚警率：<0.01次/km
└── DDT Fallback
    ├── 系统自主最小风险操作（MRM）
    ├── MRM执行时间：<10s
    ├── MRM安全停车位置选择
    └── MRM期间的危险警示
```

### 2. Takeover Request (TOR) Strategy

```
接管请求策略（L3核心要求）
├── 接管时间预算
│   ├── 正常接管：>10s（建议15s）
│   ├── 紧急接管：>4s
│   └── 极端紧急：系统自主MRM，不依赖驾驶员
├── 接管提醒分级
│   ├── Level 1 — 提示：ODD即将退出（>30s前）
│   │   └── 视觉：仪表盘提示 + HUD显示
│   ├── Level 2 — 请求：请准备接管（>10s前）
│   │   └── 视觉 + 听觉：语音提示 + 警示音
│   ├── Level 3 — 警告：立即接管（>4s前）
│   │   └── 视觉 + 听觉 + 触觉：座椅振动/安全带收紧
│   └── Level 4 — MRM：驾驶员未响应
│       └── 系统自主执行最小风险操作
├── 驾驶员状态评估
│   ├── 接管能力判定（清醒/注意力集中/手在方向盘附近）
│   ├── 接管质量评估（接管后驾驶行为稳定性）
│   └── 再次激活条件（接管后>30s正常驾驶）
└── 接管失败处理
    ├── 自动开启双闪
    ├── 逐步减速至停车
    ├── 选择安全停车位置（应急车道/路肩优先）
    └── 自动拨打紧急救援电话（eCall）
```

### 3. Minimum Risk Maneuver (MRM)

```python
# MRM Strategy Definition
mrm_strategies = {
    "scenario_1_odd_exit_planned": {
        "trigger": "ODD边界即将到达（如高速出口）",
        "time_budget": "30s+",
        "action": [
            "提前提醒驾驶员",
            "逐步降速至安全速度",
            "引导至最右车道",
            "等待驾驶员接管",
        ],
        "fallback": "减速至停车在应急车道",
    },
    "scenario_2_sensor_degradation": {
        "trigger": "传感器性能下降（大雨/浓雾）",
        "time_budget": "15s",
        "action": [
            "降低速度至60km/h",
            "增大跟车距离至3s",
            "请求驾驶员接管",
        ],
        "fallback": "安全停车在当前车道/应急车道",
    },
    "scenario_3_system_fault": {
        "trigger": "关键系统故障",
        "time_budget": "4s",
        "action": [
            "紧急接管请求",
            "维持当前车道减速",
        ],
        "fallback": "紧急制动至停车",
    },
    "scenario_4_driver_unresponsive": {
        "trigger": "驾驶员持续无响应（>30s）",
        "time_budget": "N/A",
        "action": [
            "开启双闪警示灯",
            "逐步减速（-1m/s²）",
            "移至应急车道/路肩",
            "停车并驻车",
            "解锁车门",
            "触发eCall紧急呼叫",
        ],
    },
}
```

### 4. Data Recording (EDR/DSSAD)

```
数据记录要求
├── DSSAD (Data Storage System for Automated Driving)
│   ├── 记录内容
│   │   ├── 自动驾驶系统激活/退出时间戳
│   │   ├── 接管请求发出时间与驾驶员响应时间
│   │   ├── 系统故障类型与时间
│   │   ├── ODD状态变化
│   │   ├── MRM触发与执行过程
│   │   └── 事故前30s至事故后5s的完整数据
│   ├── 记录频率
│   │   ├── 系统状态：10Hz
│   │   ├── 车辆动力学：100Hz
│   │   └── 传感器数据：按传感器帧率
│   ├── 存储要求
│   │   ├── 事故相关数据：不可删除，保存>=6个月
│   │   ├── 常规运行数据：滚动覆盖，保存>=72小时
│   │   └── 数据完整性：防篡改机制
│   └── 数据读取
│       ├── 标准化读取接口
│       ├── 执法机构可访问
│       └── 数据隐私合规（个人信息保护法）
├── EDR (Event Data Recorder)
│   ├── 符合GB 39732-2020
│   └── 与DSSAD协同但独立
└── 视频记录（如适用）
    ├── 前方道路场景
    ├── 驾驶员状态
    └── 保存时长>=72小时
```

### 5. Type Approval & Access Management

```
型式批准与准入管理
├── 准入前提条件
│   ├── 功能安全：ISO 26262 ASIL B+认证
│   ├── 预期功能安全：SOTIF分析完成
│   ├── 网络安全：ISO 21434/GB/T 40857合规
│   ├── 软件更新：OTA管理体系建立
│   └── 数据记录：DSSAD系统就绪
├── 测试验证要求
│   ├── 封闭场地测试
│   │   ├── 指定测试场（国家智能网联汽车测试区）
│   │   ├── 标准测试场景集（>100个场景）
│   │   └── 极端工况测试
│   ├── 开放道路测试
│   │   ├── 测试牌照申请
│   │   ├── 安全员配备要求
│   │   ├── 最低测试里程要求
│   │   └── 测试区域限制
│   └── 仿真测试
│       ├── 场景覆盖要求（>1000万km等效）
│       ├── 关键场景通过率100%
│       └── 仿真平台认可
├── 审查流程
│   ├── 技术文件审查
│   ├── 实车检验（含第三方测试）
│   ├── 专家评审
│   └── 准入批准（分车型、分ODD）
└── 后市场监管
    ├── OTA更新备案
    ├── 事故报告义务
    ├── 召回管理
    └── 定期安全评估
```

## Compliance Checklist

```markdown
## China L3 ADS Compliance Checklist

### 系统设计
- [ ] ODD精确定义与边界条件
- [ ] DDT性能指标定义
- [ ] TOR策略设计与验证
- [ ] MRM策略设计与验证
- [ ] 冗余架构设计（感知/计算/执行）
- [ ] DSSAD系统设计
- [ ] 系统降级策略

### 安全分析
- [ ] 功能安全分析（HARA/FMEA/FTA）
- [ ] 预期功能安全分析（SOTIF）
- [ ] 网络安全威胁分析（TARA）
- [ ] 人因分析（接管能力/时间）
- [ ] 系统性安全论证

### 测试验证
- [ ] 仿真测试（>1000万km等效场景）
- [ ] 封闭场地测试（国家测试区）
- [ ] 开放道路测试（指定区域）
- [ ] 极端工况测试
- [ ] 长期耐久性测试

### 准入申报
- [ ] 技术文件准备
- [ ] 第三方检测机构测试
- [ ] 专家评审材料
- [ ] ODD使用说明书
- [ ] 用户手册（含L3功能说明）
- [ ] 售后服务方案
```

## Key Differences: China L3 vs. UN R157 ALKS

| Aspect | UN R157 ALKS | China L3 GB |
|--------|-------------|-------------|
| Speed range | 0-60 km/h (v1), 0-130 km/h (v2) | 0-120 km/h (expected) |
| Road type | Motorway only | Highway + urban expressway |
| Lane change | Not in v1 | Expected to include |
| TOR time | 10s minimum | 10s (normal), 4s (emergency) |
| MRM | Slow down + stop in lane | Stop in emergency lane preferred |
| Data recording | DSSAD required | DSSAD + EDR + video |
| Cybersecurity | UN R155 reference | GB/T 40857 alignment |
| Type approval | UNECE contracting parties | MIIT national approval |

## Related Skills

- `automotive-china-l2-adas-compliance` — L2 combined driving assistance compliance
- `automotive-china-parking-compliance` — Automated parking compliance
- `automotive-sotif-hazard-scenario` — SOTIF scenario methodology
- `automotive-e2e-safety-analysis` — End-to-end AD safety analysis

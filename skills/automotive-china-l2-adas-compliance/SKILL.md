---
name: automotive-china-l2-adas-compliance
description: >
  Automotive China L2 Adas Compliance expertise. Covers 1 topics: China L2 Adas Compliance.
tags: [automotive, automotive-china-l2-adas-compliance]
---

# Automotive China L2 Adas Compliance

## China L2 Adas Compliance

# China L2 ADAS Compliance — Combined Driving Assistance System Safety Requirements

## Overview

Expert guidance for compliance with China's mandatory national standard (GB) for L2 Combined Driving Assistance Systems (组合驾驶辅助系统). This standard covers safety requirements for vehicles equipped with L2 functions including ACC, LKA, LCC, TJA, ICA, and their combinations. Enforcement begins in 2026.

## Regulatory Context

### Standard Hierarchy

```
中国L2标准体系
├── GB XXXX — 组合驾驶辅助系统安全要求（强制性国标，2026年执行）
│   ├── 系统安全通用要求
│   ├── 功能安全要求（基于ISO 26262）
│   ├── 预期功能安全要求（基于ISO 21448）
│   ├── 人机交互要求
│   ├── 网络安全要求
│   └── 测试方法与评价规程
├── GB/T — 组合驾驶辅助性能要求与试验方法（推荐性国标）
└── 行业标准/团体标准
    ├── C-NCAP 2024 ADAS评分规程
    └── 中国智能网联汽车产品准入规范
```

### Key Regulatory Bodies

- **MIIT (工信部)**: Vehicle type approval and access management
- **SAC/TC114 (全国汽车标准化技术委员会)**: Standard development
- **CATARC (中汽中心)**: Testing and certification
- **C-NCAP**: Safety rating with ADAS scoring

## Covered L2 Functions

### Function Definitions

| Function | Chinese Name | Description |
|----------|-------------|-------------|
| **ACC** | 自适应巡航控制 | Adaptive Cruise Control with stop & go |
| **LKA** | 车道保持辅助 | Lane Keeping Assistance |
| **LCC** | 车道居中控制 | Lane Centering Control |
| **TJA** | 交通拥堵辅助 | Traffic Jam Assist |
| **ICA** | 集成巡航辅助 | Integrated Cruise Assist (ACC + LCC) |
| **AEB** | 自动紧急制动 | Autonomous Emergency Braking |
| **LDW** | 车道偏离预警 | Lane Departure Warning |
| **BSD** | 盲区监测 | Blind Spot Detection |
| **FCTA** | 前方交叉交通预警 | Front Cross Traffic Alert |
| **RCTA** | 后方交叉交通预警 | Rear Cross Traffic Alert |

### Function Combination Matrix

```
组合驾驶辅助系统功能组合
─────────────────────────────────────────
纵向控制        ×    横向控制    =    组合功能
─────────────────────────────────────────
ACC            +    LKA/LCC    =    ICA/TJA
ACC (Stop&Go)  +    LCC        =    HWA (Highway Assist)
ACC + AEB      +    LKA + LDW  =    Full L2 Package
─────────────────────────────────────────
```

## Core Compliance Requirements

### 1. System Safety General Requirements

```
系统安全通用要求
├── 运行设计域（ODD）定义
│   ├── 道路类型：高速公路、城市快速路、城市道路
│   ├── 速度范围：0-130 km/h（ACC）, 0-120 km/h（LCC）
│   ├── 天气条件：晴天、雨天（中雨以下）、雾天（能见度>100m）
│   └── 时间条件：昼夜均可
├── 系统状态管理
│   ├── 正常运行状态
│   ├── 功能降级状态
│   ├── 最小风险状态（MRC）
│   └── 安全停车状态
├── 故障检测与响应
│   ├── 传感器故障检测时间 < 200ms
│   ├── 系统故障响应时间 < 500ms
│   └── 安全状态切换时间 < 1s
└── 系统可用性要求
    ├── 系统可用率 > 99.5%
    └── 虚警率 < 0.1次/100km
```

### 2. Functional Safety Requirements (ISO 26262 Alignment)

```python
# ASIL Classification for L2 Functions
asil_classification = {
    "ACC_acceleration": "ASIL_B",
    "ACC_deceleration": "ASIL_C",
    "AEB": "ASIL_D",
    "LKA_steering_torque": "ASIL_B",
    "LCC_lateral_control": "ASIL_B",
    "driver_monitoring": "ASIL_B",
    "system_override": "ASIL_C",
    "safe_state_transition": "ASIL_C",
}

# Safety Goals Example
safety_goals = [
    {
        "id": "SG-01",
        "description": "防止非预期加速导致碰撞",
        "asil": "ASIL_C",
        "safe_state": "取消ACC，驾驶员接管",
        "ftti": "300ms"
    },
    {
        "id": "SG-02",
        "description": "防止非预期转向导致偏离车道",
        "asil": "ASIL_B",
        "safe_state": "LKA/LCC退出，驾驶员接管",
        "ftti": "500ms"
    },
    {
        "id": "SG-03",
        "description": "确保AEB在需要时正确触发",
        "asil": "ASIL_D",
        "safe_state": "执行最大制动",
        "ftti": "150ms"
    },
]
```

### 3. SOTIF Requirements (ISO 21448 Alignment)

```
预期功能安全要求
├── 已知安全场景识别
│   ├── 正常交通流中跟车
│   ├── 车道标线清晰的弯道
│   └── 前方车辆正常切入
├── 已知不安全场景识别与缓解
│   ├── 前方静止车辆（ACC不响应）
│   ├── 弯道中车道标线消失
│   ├── 隧道出入口光线突变
│   ├── 雨雪天气传感器性能下降
│   ├── 前方摩托车/电动车误识别
│   └── 施工区域锥桶/临时标线
├── 未知不安全场景探索
│   ├── 基于自然驾驶数据的场景挖掘
│   ├── 仿真测试覆盖（>1000万km）
│   └── 实车测试里程（>100万km）
└── 残余风险评估
    ├── 可接受风险水平定义
    └── 持续监控与OTA更新策略
```

### 4. Human-Machine Interaction (HMI) Requirements

```
人机交互要求
├── 驾驶员监控系统（DMS）
│   ├── 注意力监测（视线方向）
│   ├── 疲劳检测（眼睛闭合）
│   ├── 手离方向盘检测
│   │   ├── 提醒阈值：15秒
│   │   ├── 警告阈值：30秒
│   │   └── 退出阈值：60秒
│   └── 驾驶员响应确认
├── 系统状态显示
│   ├── 功能激活/待机/不可用状态
│   ├── 目标车辆/车道线识别状态
│   ├── 系统控制权限指示
│   └── 接管请求（TOR）显示
├── 接管请求（TOR）策略
│   ├── 视觉 + 听觉 + 触觉三通道提醒
│   ├── 分级提醒：信息→警告→紧急
│   ├── 提醒时间预算：>4秒（常规），>1秒（紧急）
│   └── 驾驶员无响应时安全停车
└── 防滥用设计
    ├── 禁止驾驶员完全脱手
    ├── 功能边界清晰提示
    └── 市场宣传与实际能力一致
```

### 5. Cybersecurity Requirements

```
网络安全要求（对齐GB/T 40857）
├── ADAS ECU安全启动
├── 传感器数据完整性校验
├── V2X通信安全（如适用）
├── OTA更新安全机制
├── 诊断接口访问控制
└── 数据记录与隐私保护
```

## Testing & Validation Methods

### Test Scenario Categories

```python
# China L2 ADAS Test Scenarios
test_scenarios = {
    "纵向控制测试": [
        "前车匀速跟车（40-120km/h）",
        "前车减速（-3m/s² ~ -8m/s²）",
        "前车切出（暴露静止车辆）",
        "旁车切入（50%-100%重叠率）",
        "隧道内跟车",
        "上下坡跟车（±6%坡度）",
    ],
    "横向控制测试": [
        "直道车道保持（偏移量<0.2m）",
        "弯道车道保持（R>250m）",
        "车道标线类型变化",
        "双车道标线过渡",
        "施工区域临时标线",
    ],
    "组合功能测试": [
        "ICA弯道跟车",
        "TJA低速跟车启停",
        "前车切出+静止目标",
        "连续弯道+车道变化",
    ],
    "故障注入测试": [
        "摄像头遮挡/污染",
        "雷达干扰",
        "GPS信号丢失",
        "CAN通信故障",
        "传感器数据延迟",
    ],
    "环境适应性测试": [
        "强光/逆光条件",
        "雨天（轻雨/中雨）",
        "夜间（有路灯/无路灯）",
        "隧道出入口",
        "地面反光/积水",
    ],
}
```

### Performance Metrics

| Metric | Requirement | Test Method |
|--------|-------------|-------------|
| ACC speed accuracy | ±2 km/h | Track test |
| ACC following distance | 1.0s - 2.5s TTC configurable | Track test |
| LCC lateral offset | < 0.2m (straight), < 0.35m (curve R>500m) | Track test |
| AEB response time | < 400ms (from detection to braking) | Euro NCAP protocol adapted |
| System activation time | < 2s from driver request | HMI test |
| TOR response time budget | > 4s (normal), > 1s (emergency) | Simulator + track |
| False activation rate | < 0.1 per 100km | Public road test |
| System availability | > 99.5% in ODD | Statistical analysis |

## Compliance Checklist

```markdown
## China L2 ADAS Compliance Checklist

### 文档要求
- [ ] 运行设计域（ODD）定义文档
- [ ] 系统架构设计文档
- [ ] 功能安全概念（FSC）
- [ ] 技术安全概念（TSC）
- [ ] SOTIF分析报告
- [ ] HARA（危害分析与风险评估）
- [ ] FMEA/FTA分析报告
- [ ] HMI设计规范
- [ ] 网络安全分析报告
- [ ] 测试验证报告

### 功能安全
- [ ] ASIL等级确定与分解
- [ ] 安全目标定义
- [ ] 安全机制设计与验证
- [ ] 故障检测覆盖率满足要求
- [ ] 安全状态转换验证

### 预期功能安全
- [ ] 触发条件识别与分类
- [ ] 已知不安全场景清单与缓解措施
- [ ] 仿真测试覆盖（场景数量/里程）
- [ ] 实车测试验证
- [ ] 残余风险可接受性论证

### 人机交互
- [ ] DMS功能验证
- [ ] 接管请求策略验证
- [ ] 防滥用机制验证
- [ ] 系统状态指示清晰性评估

### 网络安全
- [ ] 安全启动验证
- [ ] 通信安全验证
- [ ] OTA安全机制验证
- [ ] 数据隐私保护

### 型式检验/认证
- [ ] CATARC测试通过
- [ ] 工信部公告目录申报
- [ ] C-NCAP评分（如适用）
```

## Integration with Existing Standards

### Mapping to ISO 26262

| China GB Requirement | ISO 26262 Part | Clause |
|---------------------|----------------|--------|
| 功能安全通用要求 | Part 3 | Concept phase |
| ASIL分类 | Part 3 | HARA |
| 安全机制设计 | Part 4/5 | System/HW/SW design |
| 安全验证 | Part 4/5 | Verification & Validation |
| 安全确认 | Part 4 | Safety validation |

### Mapping to ISO 21448

| China GB Requirement | ISO 21448 | Clause |
|---------------------|-----------|--------|
| 预期功能安全分析 | Clause 5-7 | SOTIF analysis |
| 触发条件识别 | Clause 8 | Triggering conditions |
| 场景验证 | Clause 10-11 | Verification & validation |
| 残余风险评估 | Clause 12 | Residual risk |

## Tools & Frameworks

- **Simulation**: CARLA, VTD, 51Sim, PanoSim, DYNA4
- **Testing**: Vector CANoe, dSpace, NI HIL
- **Safety Analysis**: medini analyze, APIS IQ-FMEA, Ansys medini
- **Scenario**: OpenSCENARIO 2.0, GBT Scene Library
- **Compliance Management**: Polarion, DOORS, Jama Connect

## Deliverables

When invoked, this skill provides:
1. **Compliance Gap Analysis**: Current system vs. GB requirements
2. **ODD Definition Document**: Structured ODD per Chinese standard format
3. **HARA Report**: Adapted for Chinese regulatory framework
4. **Test Plan**: Scenario-based test plan aligned with CATARC protocols
5. **Compliance Evidence Package**: Documentation for type approval
6. **HMI Assessment**: DMS and TOR strategy evaluation

## Limitations

- Standard text is based on published draft/consultation versions; final published version may differ
- Enforcement timeline subject to regulatory updates
- Testing protocols may be updated by CATARC
- User should verify against latest published standard text

## Related Skills

- `automotive-china-l3-ads-compliance` — L3 automated driving compliance
- `automotive-china-parking-compliance` — Parking system compliance
- `automotive-china-standards-overview` — Full China automotive standards landscape
- `automotive-sotif-hazard-scenario` — SOTIF scenario analysis methodology
- `iso-26262-overview` — ISO 26262 functional safety fundamentals

---
name: automotive-china-parking-compliance
description: >
  Automotive China Parking Compliance expertise. Covers 1 topics: China Parking Compliance.
tags: [automotive, automotive-china-parking-compliance]
---

# Automotive China Parking Compliance

## China Parking Compliance

# China Parking System Compliance — Parking Assistance & Automated Parking Standards

## Overview

Expert guidance for compliance with China's standards for parking assistance and automated parking systems, including APA (Automatic Parking Assist), RPA (Remote Parking Assist), AVP (Automated Valet Parking), and HPA (Home-zone Parking Assist). Covers both mandatory and recommended national standards.

## Standard Hierarchy

```
中国泊车标准体系
├── 强制性国标
│   ├── GB — 泊车辅助系统性能要求与试验方法
│   └── GB — 遥控泊车辅助系统技术要求
├── 推荐性国标
│   ├── GB/T — 自动泊车系统性能要求与试验方法
│   ├── GB/T — 自动代客泊车系统技术要求
│   ├── GB/T — 泊车功能安全要求
│   └── GB/T — 泊车预期功能安全要求
├── 行业标准
│   ├── QC/T — 泊车辅助超声波传感器技术要求
│   └── QC/T — 全景影像系统技术要求
└── 团体标准
    ├── T/CSAE — 智能泊车系统分级
    └── T/CSAE — 记忆泊车系统技术要求
```

## Parking Function Classification

### Function Levels

```
泊车功能分级（参考T/CSAE标准）
─────────────────────────────────────────────────────
Level 0: 泊车预警
  └── 超声波/摄像头障碍物提醒（无自动控制）

Level 1: 半自动泊车辅助（APA-S）
  └── 系统控制转向，驾驶员控制油门/制动/换挡

Level 2: 自动泊车辅助（APA）
  └── 系统控制转向+制动+油门，驾驶员监控
  └── 驾驶员在车内，脚在制动踏板附近

Level 3: 遥控泊车辅助（RPA）
  └── 驾驶员在车外，通过手机/钥匙遥控
  └── 低速（<5km/h），短距离（<6m通常）

Level 4: 记忆泊车（HPA）
  └── 学习固定路线，自动泊入/泊出
  └── 驾驶员可在车外，通过App监控

Level 5: 自动代客泊车（AVP）
  └── 车辆自主寻找车位并泊车
  └── 需要场端基础设施配合（L4级别）
─────────────────────────────────────────────────────
```

### Parking Scenario Types

```python
parking_scenarios = {
    "平行泊车（侧方位）": {
        "车位尺寸": "车长+1.2m × 车宽+0.8m (最小)",
        "速度限制": "<10 km/h",
        "检测距离": ">15m前方探测",
    },
    "垂直泊车": {
        "车位尺寸": "车宽+0.8m × 5.0m (最小)",
        "速度限制": "<5 km/h",
        "接近角度": "90° ± 15°",
    },
    "斜向泊车": {
        "车位尺寸": "按角度计算",
        "角度": "30°/45°/60°",
        "速度限制": "<5 km/h",
    },
    "遥控泊车": {
        "遥控距离": "<6m",
        "速度限制": "<5 km/h (前进), <3 km/h (倒车)",
        "紧急制动": "松开遥控按键即停",
    },
    "记忆泊车（HPA）": {
        "学习路径长度": "<500m",
        "速度限制": "<15 km/h",
        "路径偏差容忍": "<0.3m",
    },
    "代客泊车（AVP）": {
        "运行范围": "指定停车场/区域",
        "速度限制": "<20 km/h",
        "场端配合": "需要V2X/高精地图",
    },
}
```

## Core Compliance Requirements

### 1. Sensor & Perception Requirements

```
泊车感知系统要求
├── 超声波传感器（USS）
│   ├── 数量：>=12个（推荐16个）
│   ├── 检测范围：0.15m - 5.0m
│   ├── 精度：±2cm
│   ├── 角度覆盖：360°环绕
│   └── 响应时间：<100ms
├── 环视摄像头（AVM）
│   ├── 数量：4个（前/后/左/右）
│   ├── FOV：>=190°（鱼眼）
│   ├── 分辨率：>=1280×960
│   ├── 帧率：>=25fps
│   └── 拼接精度：<5cm
├── 补充传感器（高级功能）
│   ├── 角雷达：用于动态障碍物检测
│   ├── 激光雷达：用于AVP精确建图
│   └── V2X：用于AVP场端通信
└── 感知性能要求
    ├── 车位检测成功率：>95%（标准车位）
    ├── 障碍物检测率：>99.5%
    ├── 行人检测率：>99.9%
    ├── 最小可检测障碍物：高度>30cm, 直径>5cm
    └── 检测延迟：<200ms
```

### 2. Safety Requirements

```
泊车系统安全要求
├── 碰撞避免
│   ├── 安全距离：障碍物>=20cm时减速，>=10cm时停车
│   ├── 紧急制动减速度：>3 m/s²（低速足够）
│   ├── 制动响应时间：<300ms
│   └── 行人保护：检测到行人立即停车
├── 速度限制
│   ├── APA最大速度：10 km/h
│   ├── RPA最大速度：5 km/h（前进），3 km/h（倒车）
│   ├── HPA最大速度：15 km/h
│   └── AVP最大速度：20 km/h
├── 功能安全等级
│   ├── APA转向控制：ASIL A/B
│   ├── APA制动控制：ASIL B
│   ├── RPA无人驾驶：ASIL B/C
│   ├── AVP无人驾驶：ASIL C/D
│   └── 紧急制动：ASIL C
├── 遥控泊车特殊要求
│   ├── 持续按压操作（死人开关）
│   ├── 松开即停（<300ms响应）
│   ├── 通信中断即停
│   ├── 遥控范围限制（<6m）
│   └── 视线内操作要求
└── 故障响应
    ├── 传感器故障：立即停车
    ├── 通信中断（RPA）：立即停车
    ├── 路径偏差超限：停车报警
    └── 异常工况：退出泊车功能
```

### 3. Performance Test Methods

```python
# Parking System Test Scenarios
test_scenarios = {
    "车位识别测试": {
        "标准平行车位": {"length": "6.0m", "width": "2.5m", "pass_rate": ">95%"},
        "最小平行车位": {"length": "L+1.2m", "width": "W+0.8m", "pass_rate": ">80%"},
        "标准垂直车位": {"width": "2.5m", "depth": "5.0m", "pass_rate": ">95%"},
        "最小垂直车位": {"width": "W+0.6m", "depth": "5.0m", "pass_rate": ">85%"},
    },
    "泊车执行测试": {
        "平行泊入": {
            "最大尝试次数": 3,
            "最大用时": "120s",
            "最终位置精度": "纵向±30cm, 横向±20cm",
            "与边界距离": ">10cm",
        },
        "垂直泊入": {
            "最大尝试次数": 2,
            "最大用时": "90s",
            "最终位置精度": "纵向±20cm, 横向±15cm",
        },
        "泊出": {
            "最大用时": "60s",
            "安全距离": ">20cm",
        },
    },
    "障碍物测试": {
        "静态障碍物": ["锥桶", "立柱", "墙壁", "低矮障碍物（轮挡）"],
        "动态障碍物": ["行人横穿", "自行车通过", "其他车辆移动"],
        "特殊障碍物": ["购物车", "儿童", "宠物", "深色衣物行人"],
    },
    "环境测试": {
        "光照": ["强光", "阴影", "地下车库暗光", "LED灯频闪"],
        "地面": ["干燥", "湿滑", "积水反光", "坡道（±5%）"],
        "天气": ["晴天", "雨天", "雾天"],
    },
}
```

### 4. HMI Requirements for Parking

```
泊车HMI要求
├── APA
│   ├── 车位推荐显示（3D/2D鸟瞰图）
│   ├── 泊车路径预览
│   ├── 实时泊车进度显示
│   ├── 周围障碍物距离显示（数值+颜色）
│   ├── 驾驶员确认启动
│   └── 随时可通过制动/转向/按键取消
├── RPA
│   ├── 手机/钥匙端实时画面
│   ├── 车辆位置与朝向显示
│   ├── 障碍物距离提醒（振动）
│   ├── 操作确认与状态反馈
│   └── 紧急停车按钮（显著位置）
└── AVP
    ├── 泊车任务发起与确认
    ├── 泊车进度实时推送
    ├── 取车请求与等待时间
    ├── 异常情况通知
    └── 费用结算（如适用）
```

## Compliance Checklist

```markdown
## China Parking System Compliance Checklist

### 功能设计
- [ ] 支持的泊车场景类型定义
- [ ] 车位检测算法与性能指标
- [ ] 路径规划算法与碰撞检测
- [ ] 速度控制策略
- [ ] HMI设计规范

### 安全设计
- [ ] 功能安全分析（HARA/FMEA）
- [ ] SOTIF分析（泊车场景特有触发条件）
- [ ] 紧急制动策略
- [ ] 故障检测与安全响应
- [ ] 遥控泊车死人开关设计

### 测试验证
- [ ] 车位识别成功率测试
- [ ] 泊车执行精度测试
- [ ] 障碍物检测与制动测试
- [ ] 遥控距离/通信可靠性测试
- [ ] 环境适应性测试
- [ ] 耐久性/疲劳测试

### 文档
- [ ] 系统设计规范
- [ ] 安全分析报告
- [ ] 测试验证报告
- [ ] 用户操作手册
```

## Related Skills

- `automotive-china-l2-adas-compliance` — L2 ADAS compliance (APA as L2 function)
- `automotive-china-standards-overview` — Full China automotive standards landscape
- `automotive-sotif-hazard-scenario` — SOTIF scenarios for parking

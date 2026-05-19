---
name: automotive-powertrain-chassis
description: >
  Automotive Powertrain Chassis expertise. Covers 7 topics: Abs Brake Systems, Ecm Engine Control, Eps Steering Systems, Esc Stability Control, Suspension Control.
tags: [automotive, automotive-powertrain-chassis]
---

# Automotive Powertrain Chassis

## Abs Brake Systems

# ABS/EBD Anti-lock Braking System Skill

## Overview
Expert skill in Anti-lock Braking System (ABS) and Electronic Brake-force Distribution (EBD) development. Covers wheel slip control, pressure modulation, EBD algorithms, brake-by-wire, regenerative braking coordination, and brake fade compensation.

## Core Competencies

### 1. Wheel Slip Control
- **Target Slip Ratio**: 10-20% for optimal braking (peak μ on most surfaces)
- **Slip Calculation**: λ = (vwheel - vvehicle) / vvehicle
- **Control Modes**: Build-up, Hold, Release phases
- **Surface Adaptation**: Adjust control aggressiveness for dry/wet/ice

### 2. Pressure Modulation
- **Hydraulic Valve Control**: Inlet/outlet solenoids, return pump
- **PWM Frequency**: 10-20 Hz typical ABS cycling
- **Pressure Estimation**: No direct sensor, estimate from valve timing
- **Pedal Feel**: Minimize pulsation feedback to driver

### 3. Electronic Brake-force Distribution (EBD)
- **Dynamic Load Transfer**: Front/rear brake bias based on deceleration
- **Proportioning**: Prevent rear wheel lockup (stability)
- **Empty vs Loaded**: Adjust distribution based on vehicle weight
- **Trailer Detection**: Modify EBD for towing conditions

### 4. Regenerative Braking Coordination
- **Blending Control**: Seamless transition hydraulic ↔ regenerative
- **Regen Priority**: Max energy recovery while meeting brake demand
- **Pedal Feel**: Maintain consistent deceleration feel
- **Safety Backup**: Full hydraulic if electric system fails

### 5. Brake-by-Wire (BBW)
- **Electro-Mechanical Brakes (EMB)**: Electric caliper actuators
- **Decoupled Pedal**: Pedal feel simulator, no direct hydraulic link
- **Redundancy**: Dual ECUs, backup hydraulic circuit
- **Latency**: <100ms brake request to force application

## Control Algorithms

### ABS Slip Control (Bang-Bang with Hysteresis)
```c
typedef enum {
    ABS_BUILD,      // Increase pressure
    ABS_HOLD,       // Maintain pressure
    ABS_RELEASE     // Decrease pressure
} ABS_Phase_t;

typedef struct {
    float wheel_speed_mps;
    float vehicle_speed_mps;
    float slip_ratio;
    ABS_Phase_t phase;
    uint16_t cycle_count;
} ABS_WheelController_t;

void ABS_WheelControl(ABS_WheelController_t *abs, float dt) {
    // Calculate slip ratio
    if (abs->vehicle_speed_mps > 0.1f) {
        abs->slip_ratio = (abs->vehicle_speed_mps - abs->wheel_speed_mps) / abs->vehicle_speed_mps;
    } else {
        abs->slip_ratio = 0.0f;
    }

    // State machine for pressure modulation
    switch (abs->phase) {
    case ABS_BUILD:
        // Normal braking: increase pressure
        Hydraulic_OpenInletValve();
        Hydraulic_CloseOutletValve();

        // Transition to HOLD if slip exceeds threshold
        if (abs->slip_ratio > SLIP_THRESHOLD_HIGH) {  // 20%
            abs->phase = ABS_HOLD;
        }
        break;

    case ABS_HOLD:
        // Hold current pressure
        Hydraulic_CloseInletValve();
        Hydraulic_CloseOutletValve();

        // Transition to RELEASE if slip still increasing
        if (abs->slip_ratio > SLIP_THRESHOLD_CRITICAL) {  // 25%
            abs->phase = ABS_RELEASE;
        } else if (abs->slip_ratio < SLIP_THRESHOLD_LOW) {  // 15%
            abs->phase = ABS_BUILD;
        }
        break;

    case ABS_RELEASE:
        // Decrease pressure to reduce slip
        Hydraulic_CloseInletValve();
        Hydraulic_OpenOutletValve();
        Hydraulic_ActivateReturnPump();

        abs->cycle_count++;

        // Transition to BUILD when slip decreases
        if (abs->slip_ratio < SLIP_THRESHOLD_LOW) {
            abs->phase = ABS_BUILD;
        }
        break;
    }
}
```

### EBD Front/Rear Distribution
```c
float EBD_CalculateRearBrakeBias(float deceleration, float vehicle_mass, float cg_height) {
    // Dynamic load transfer: Front axle load increases during braking
    const float WHEELBASE = 2.7f;         // m
    const float STATIC_FRONT_LOAD = 0.60f; // 60% front static

    // Load transfer to front axle
    float dynamic_front_load = STATIC_FRONT_LOAD + (deceleration * cg_height / (GRAVITY * WHEELBASE));
    dynamic_front_load = CLAMP(dynamic_front_load, 0.55f, 0.75f);

    // Rear brake bias (inverse of front load)
    float rear_bias = 1.0f - dynamic_front_load;

    // Additional safety margin to prevent rear lockup
    rear_bias *= 0.85f;

    return CLAMP(rear_bias, 0.20f, 0.40f);
}

void EBD_ApplyDistribution(float total_brake_force, float deceleration) {
    float rear_bias = EBD_CalculateRearBrakeBias(deceleration, VEHICLE_MASS, CG_HEIGHT);

    float front_force = total_brake_force * (1.0f - rear_bias);
    float rear_force = total_brake_force * rear_bias;

    // Apply to each wheel (split left/right equally)
    Hydraulic_SetPressure(WHEEL_FL, front_force / 2.0f);
    Hydraulic_SetPressure(WHEEL_FR, front_force / 2.0f);
    Hydraulic_SetPressure(WHEEL_RL, rear_force / 2.0f);
    Hydraulic_SetPressure(WHEEL_RR, rear_force / 2.0f);
}
```

### Regenerative Braking Blending
```c
typedef struct {
    float brake_pedal_force;      // Driver demand (N)
    float total_decel_target;     // Target deceleration (m/s²)
    float regen_decel_available;  // Max regen from motor (m/s²)
    float hydraulic_decel;        // Hydraulic brake component
    float regen_decel;            // Regen brake component
} RegenBlending_t;

void RegenBraking_Blend(RegenBlending_t *regen) {
    // Convert pedal force to deceleration demand
    regen->total_decel_target = regen->brake_pedal_force / 50.0f;  // N → m/s²

    // Prioritize regen for energy recovery
    regen->regen_decel = fmin(regen->total_decel_target, regen->regen_decel_available);

    // Hydraulic makes up the difference
    regen->hydraulic_decel = regen->total_decel_target - regen->regen_decel;

    // Seamless transition: ramp regen, compensate with hydraulic
    static float regen_prev = 0.0f;
    float regen_rate = (regen->regen_decel - regen_prev) / DT;

    if (fabs(regen_rate) > MAX_REGEN_RATE) {
        // Regen changing too fast, compensate with hydraulic
        regen->hydraulic_decel += regen_rate * 0.5f;
    }

    regen_prev = regen->regen_decel;

    // Send commands
    CAN_Send_RegenTorqueRequest(regen->regen_decel * VEHICLE_MASS * TIRE_RADIUS);
    Hydraulic_SetDeceleration(regen->hydraulic_decel);
}
```

### Brake Fade Compensation
```c
// Compensate for brake pad temperature effects
float BrakeFade_Compensation(float brake_temp_celsius) {
    // Friction coefficient drops at high temperature
    // Typical: μ = 0.40 at 20°C, μ = 0.30 at 500°C
    float mu_baseline = 0.40f;
    float mu_degraded = 0.30f;
    float temp_threshold = 300.0f;  // °C
    float temp_critical = 600.0f;

    if (brake_temp_celsius < temp_threshold) {
        return 1.0f;  // No compensation needed
    }

    // Linear fade model between threshold and critical
    float fade_factor = 1.0f - ((brake_temp_celsius - temp_threshold) / (temp_critical - temp_threshold)) * (1.0f - mu_degraded / mu_baseline);

    fade_factor = CLAMP(fade_factor, 0.6f, 1.0f);

    // Increase pedal pressure to maintain braking force
    float compensation = 1.0f / fade_factor;

    // Warning if severe fade detected
    if (fade_factor < 0.75f) {
        HMI_SetBrakeFadeWarning(true);
    }

    return compensation;
}
```

## HIL Test Scenarios

### Test Case 1: ABS on Ice (Low-μ Surface)
```yaml
test_id: ABS_001_ICE_BRAKING
objective: Prevent wheel lockup on slippery surface
preconditions:
  - Vehicle speed: 60 kph
  - Surface: Ice (μ = 0.15)
  - Full brake pedal application

test_steps:
  1. Apply 100% brake pressure
  2. Monitor wheel speeds vs vehicle speed
  3. Verify ABS cycling (10-15 Hz)
  4. Measure stopping distance

pass_criteria:
  - No wheel lockup (slip ratio <30%)
  - Steering control maintained
  - Stopping distance: <80 meters
  - ABS activation within 100ms of slip detection
```

### Test Case 2: Split-μ Braking Stability
```yaml
test_id: ABS_002_SPLIT_MU
objective: Maintain directional stability on asymmetric friction
preconditions:
  - Vehicle speed: 80 kph
  - Left wheels: Dry asphalt (μ = 0.9)
  - Right wheels: Wet asphalt (μ = 0.5)

test_steps:
  1. Apply full braking
  2. Monitor yaw rate (ESC coordinated)
  3. Verify individual wheel ABS control

pass_criteria:
  - Yaw rate: <3 deg/s deviation
  - Vehicle tracks straight (±0.5m lateral deviation)
  - Left wheels: Higher brake force than right
  - No driver steering input required
```

### Test Case 3: Regenerative Braking Blend
```yaml
test_id: ABS_003_REGEN_BLEND
objective: Seamless hydraulic-regen coordination
preconditions:
  - EV with regen capability
  - Vehicle speed: 50 kph
  - Battery SOC: 70% (regen available)

test_steps:
  1. Apply 50% brake pedal
  2. Monitor regen torque vs hydraulic pressure
  3. Verify deceleration consistency
  4. Simulate regen unavailable (low SOC)

pass_criteria:
  - Regen prioritized: 80% of braking from electric motor
  - Hydraulic makeup: Smooth transition if regen saturates
  - Pedal feel: Consistent throughout (no jerk)
  - Regen→hydraulic transition: <50ms
```

## ISO 26262 Safety (ASIL-D)

### Safety Mechanisms
- **Redundant Wheel Speed Sensors**: Dual-channel Hall sensors per wheel
- **Plausibility Checks**: Compare wheel speeds, detect sensor faults
- **Failsafe Brake**: Revert to manual hydraulic on ECU failure
- **Watchdog**: Independent external monitor, reset on timeout

## CAN Signals (DBC)

```dbc
BO_ 290 ABS_Status: 8 ABS
 SG_ ABS_Active : 0|1@1+ (1,0) [0|1] "" ESC,HMI
 SG_ WheelSpeed_FL : 8|16@1+ (0.01,0) [0|655.35] "m/s" ESC,PCM
 SG_ WheelSpeed_FR : 24|16@1+ (0.01,0) [0|655.35] "m/s" ESC,PCM
 SG_ WheelSpeed_RL : 40|16@1+ (0.01,0) [0|655.35] "m/s" ESC,PCM
 SG_ WheelSpeed_RR : 56|16@1+ (0.01,0) [0|655.35] "m/s" ESC,PCM
```

## References
- UN ECE R13-H (ABS regulation)
- ISO 26262 (Functional Safety)
- SAE J2909 (ABS test procedures)

---

## Ecm Engine Control

# ECM/PCM Engine Control Module Skill

## Overview
Expert skill in Engine Control Module (ECM) / Powertrain Control Module (PCM) development for internal combustion engines. Covers fuel injection timing, ignition control, air-fuel ratio optimization, turbo boost control, variable valve timing (VVT), emissions control, and OBD-II diagnostics.

## Core Competencies

### 1. Fuel Injection Control
- **Multi-point Fuel Injection (MPFI)**: Sequential, batch, simultaneous injection strategies
- **Direct Injection (GDI/TFSI)**: High-pressure rail control, split injection, stratified/homogeneous modes
- **Injection Timing**: Crank angle-based timing, compensation for temperature, altitude
- **Pulse Width Modulation**: Injector driver control with dead-time compensation

### 2. Ignition System Control
- **Spark Timing Optimization**: MBT (Minimum advance for Best Torque) vs knock limit
- **Knock Detection**: Piezoelectric sensor processing, frequency domain analysis
- **Coil-on-Plug (COP)**: Individual coil dwell time control, energy optimization
- **Misfire Detection**: Crankshaft acceleration monitoring, OBD-II readiness

### 3. Air-Fuel Ratio (AFR) Management
- **Lambda Control**: Closed-loop with wideband O2 sensor (LSU 4.9 Bosch)
- **Stoichiometric Operation**: λ=1.0 for three-way catalyst efficiency
- **Lean Burn**: λ=1.3-1.5 for fuel economy (requires NOx aftertreatment)
- **Rich Operation**: λ=0.85-0.95 for maximum power, component protection

### 4. Turbocharger/Supercharger Control
- **Wastegate Control**: Electronic wastegate actuator, boost pressure regulation
- **Overboost Protection**: Pressure limiting, fuel cut-off, ignition retard
- **Compressor Surge Prevention**: Anti-surge valve control
- **Turbo Lag Mitigation**: Launch control, anti-lag systems

### 5. Variable Valve Timing (VVT)
- **Cam Phasing**: Hydraulic/electric cam phasers, intake/exhaust timing
- **Valve Lift Control**: Discrete multi-step or continuous variable lift
- **Optimization**: Torque curve shaping, emissions reduction, fuel economy
- **Cylinder Deactivation**: Selective cylinder shut-off for light load

### 6. Emissions Control Systems
- **Exhaust Gas Recirculation (EGR)**: Cooled/uncooled EGR valve control, NOx reduction
- **Three-Way Catalyst (TWC)**: Light-off temperature management, oxygen storage
- **Secondary Air Injection**: Cold-start emissions reduction
- **Evaporative Emissions (EVAP)**: Purge control, leak detection

### 7. OBD-II Diagnostics
- **Readiness Monitors**: Catalyst, EGR, EVAP, O2 sensor, misfire, fuel system
- **Freeze Frame Data**: Snapshot at DTC trigger
- **Malfunction Indicator Lamp (MIL)**: Illumination logic, two-trip detection
- **In-Use Performance Ratio (IUPR)**: Denominator/numerator tracking per SAE J1979

## Control Algorithms

### Fuel Injection Pulse Width Calculation
```c
// Fuel injection pulse width calculation
typedef struct {
    float base_pulse_ms;      // Base pulse from VE table
    float lambda_target;      // Target AFR (1.0 = stoich)
    float lambda_actual;      // Measured AFR from O2 sensor
    float temp_correction;    // Coolant/intake temp correction
    float transient_comp;     // Wall-wetting compensation
    float battery_correction; // Voltage compensation
} FuelCalc_t;

float ECM_CalculateInjectionPulse(FuelCalc_t *calc, float maf_gs, float rpm) {
    // Volumetric efficiency lookup (3D map: RPM x MAP)
    float ve = VE_Table_Lookup(rpm, manifold_pressure);

    // Stoichiometric fuel mass required (14.7:1 for gasoline)
    float fuel_mass_mg = (maf_gs * 1000.0f) / (14.7f * calc->lambda_target);

    // Convert to pulse width (injector flow rate)
    float pulse_width = (fuel_mass_mg / injector_flow_rate_cc) + injector_dead_time;

    // Apply corrections
    pulse_width *= calc->temp_correction;
    pulse_width *= calc->battery_correction;
    pulse_width += calc->transient_comp;  // Wall-wetting

    // Lambda closed-loop correction
    float lambda_error = calc->lambda_target - calc->lambda_actual;
    static float lambda_integral = 0.0f;
    lambda_integral += lambda_error * KI_LAMBDA * DT;
    lambda_integral = CLAMP(lambda_integral, -0.2f, 0.2f);

    float lambda_correction = 1.0f + (KP_LAMBDA * lambda_error) + lambda_integral;
    pulse_width *= lambda_correction;

    return CLAMP(pulse_width, 0.5f, 20.0f);  // Pulse limits in ms
}
```

### Ignition Timing with Knock Control
```c
// Spark advance calculation with knock detection
typedef struct {
    float base_advance_deg;   // Base timing from map
    float knock_retard_deg;   // Accumulated knock retard
    float coolant_adv_deg;    // Coolant temp advance
    float altitude_adv_deg;   // Barometric compensation
} IgnitionTiming_t;

float ECM_CalculateSparkAdvance(IgnitionTiming_t *ign, float rpm, float load) {
    // Base timing from 3D map (RPM x Load)
    float spark_adv = SparkMap_Lookup(rpm, load);

    // Knock detection and retard
    if (Knock_Detected()) {
        ign->knock_retard_deg += KNOCK_RETARD_STEP_DEG;  // 2-3° per event
        ign->knock_retard_deg = CLAMP(ign->knock_retard_deg, 0.0f, 15.0f);
    } else {
        // Slowly recover advance (0.5°/second)
        ign->knock_retard_deg -= KNOCK_RECOVERY_RATE * DT;
        ign->knock_retard_deg = MAX(ign->knock_retard_deg, 0.0f);
    }

    // Apply corrections
    spark_adv += ign->coolant_adv_deg;    // Cold engine needs more advance
    spark_adv += ign->altitude_adv_deg;   // High altitude needs more advance
    spark_adv -= ign->knock_retard_deg;   // Subtract knock retard

    // Safety limits
    return CLAMP(spark_adv, -10.0f, 45.0f);
}

// Knock detection using FFT on sensor signal
bool Knock_Detected(void) {
    // Read knock sensor (piezoelectric accelerometer)
    float knock_signal[128];
    ADC_ReadKnockSensor(knock_signal, 128);

    // Bandpass filter (5-15 kHz typical knock frequency)
    BandpassFilter(knock_signal, 128, 5000, 15000);

    // FFT magnitude at knock frequency
    float knock_magnitude = FFT_Magnitude(knock_signal, 128, KNOCK_FREQ_HZ);

    // Compare against calibrated threshold
    return (knock_magnitude > KNOCK_THRESHOLD);
}
```

### Turbo Boost Control (PID)
```c
// Electronic wastegate control for boost pressure
typedef struct {
    float kp;           // Proportional gain
    float ki;           // Integral gain
    float kd;           // Derivative gain
    float integral;     // Integral accumulator
    float prev_error;   // Previous error for derivative
} PID_Controller_t;

float Turbo_BoostControl(float target_boost_kPa, float actual_boost_kPa,
                          PID_Controller_t *pid, float dt) {
    float error = target_boost_kPa - actual_boost_kPa;

    // PID terms
    float p_term = pid->kp * error;

    pid->integral += error * dt;
    pid->integral = CLAMP(pid->integral, -50.0f, 50.0f);  // Anti-windup
    float i_term = pid->ki * pid->integral;

    float derivative = (error - pid->prev_error) / dt;
    float d_term = pid->kd * derivative;
    pid->prev_error = error;

    // Wastegate duty cycle (0-100%)
    float wastegate_duty = p_term + i_term + d_term;
    wastegate_duty = CLAMP(wastegate_duty, 0.0f, 100.0f);

    // Overboost protection
    if (actual_boost_kPa > OVERBOOST_LIMIT_KPA) {
        wastegate_duty = 100.0f;  // Fully open wastegate
        Fault_SetDTC(DTC_OVERBOOST);
    }

    return wastegate_duty;
}
```

### EGR Control
```c
// Exhaust Gas Recirculation control for NOx reduction
float EGR_CalculatePosition(float rpm, float load, float coolant_temp) {
    // EGR disabled during cold start
    if (coolant_temp < EGR_MIN_TEMP_CELSIUS) {
        return 0.0f;
    }

    // Lookup desired EGR rate from map (RPM x Load)
    float egr_target_percent = EGR_Map_Lookup(rpm, load);

    // EGR valve position to achieve target dilution
    // Uses MAF sensor feedback to measure actual EGR flow
    float maf_no_egr = VE_Table_Lookup(rpm, manifold_pressure) * rpm;
    float maf_actual = MAF_ReadFlowRate();
    float egr_actual_percent = (1.0f - (maf_actual / maf_no_egr)) * 100.0f;

    // PI controller for EGR valve
    static float egr_integral = 0.0f;
    float egr_error = egr_target_percent - egr_actual_percent;
    egr_integral += egr_error * KI_EGR * DT;

    float egr_position = (KP_EGR * egr_error) + egr_integral;
    return CLAMP(egr_position, 0.0f, 100.0f);
}
```

## State Machine: Cold Start Sequence

```c
typedef enum {
    COLD_START_CRANK,
    COLD_START_PRIME,
    COLD_START_FIRST_FIRE,
    COLD_START_WARMUP,
    COLD_START_CATALYST_HEAT,
    COLD_START_NORMAL
} ColdStartState_t;

void ECM_ColdStartStateMachine(void) {
    static ColdStartState_t state = COLD_START_CRANK;

    switch (state) {
    case COLD_START_CRANK:
        // Fuel prime pulse (3x normal)
        FuelPulse_Multiplier = 3.0f;
        SparkAdvance_Offset = 5.0f;  // Extra advance when cold

        if (RPM_Get() > 400) {
            state = COLD_START_FIRST_FIRE;
        }
        break;

    case COLD_START_FIRST_FIRE:
        // Rich mixture for first combustion cycles
        Lambda_Target = 0.90f;

        if (Combustion_Stable() && RPM_Get() > 600) {
            state = COLD_START_WARMUP;
        }
        break;

    case COLD_START_WARMUP:
        // Elevated idle for faster warmup
        IdleSpeed_Target = 1200;

        // Secondary air injection for catalyst heating
        SecondaryAir_Enable();

        if (Coolant_Temp > 40.0f) {
            state = COLD_START_CATALYST_HEAT;
        }
        break;

    case COLD_START_CATALYST_HEAT:
        // Retard spark to increase exhaust temp
        SparkAdvance_Offset = -5.0f;
        Lambda_Target = 0.95f;  // Slightly rich

        if (Catalyst_Temp > 300.0f) {  // Light-off temp
            state = COLD_START_NORMAL;
            OBD_SetReadiness(CATALYST_MONITOR, READY);
        }
        break;

    case COLD_START_NORMAL:
        // Normal operation
        IdleSpeed_Target = 750;
        Lambda_Target = 1.00f;
        SparkAdvance_Offset = 0.0f;
        SecondaryAir_Disable();
        break;
    }
}
```

## Calibration Tables

### Volumetric Efficiency (VE) Map
```c
// 16x16 VE map: RPM (rows) x MAP (columns)
const float VE_Table[16][16] = {
    // MAP:  20   30   40   50   60   70   80   90  100  110  120  130  140  150  160  170 kPa
    /*  500*/ {20, 25, 30, 35, 40, 45, 50, 55, 60, 62, 63, 64, 65, 65, 65, 65},
    /* 1000*/ {30, 35, 40, 50, 60, 70, 75, 78, 80, 81, 82, 83, 83, 83, 83, 83},
    /* 1500*/ {35, 42, 52, 62, 72, 80, 85, 88, 90, 91, 92, 92, 92, 92, 92, 92},
    /* 2000*/ {40, 50, 60, 70, 80, 88, 92, 94, 95, 96, 96, 96, 96, 96, 96, 96},
    /* 2500*/ {42, 53, 64, 75, 85, 92, 96, 98, 99, 99, 99, 99, 99, 99, 99, 99},
    /* 3000*/ {44, 55, 66, 77, 87, 94, 97, 99,100,100,100,100,100,100,100,100},
    /* 3500*/ {45, 56, 67, 78, 88, 95, 98,100,101,101,101,100,100,100,100,100},
    /* 4000*/ {45, 56, 67, 78, 88, 95, 98,100,101,101,100, 99, 99, 98, 98, 98},
    /* 4500*/ {44, 55, 66, 77, 87, 94, 97, 99,100,100, 99, 98, 97, 96, 95, 95},
    /* 5000*/ {43, 54, 65, 76, 86, 93, 96, 98, 99, 98, 97, 96, 95, 94, 93, 92},
    /* 5500*/ {42, 53, 64, 75, 85, 92, 95, 97, 97, 96, 95, 94, 92, 91, 90, 89},
    /* 6000*/ {40, 51, 62, 73, 83, 90, 93, 95, 95, 94, 92, 91, 89, 88, 86, 85},
    /* 6500*/ {38, 49, 60, 71, 81, 88, 91, 92, 92, 91, 89, 87, 85, 83, 81, 80},
    /* 7000*/ {35, 46, 57, 68, 78, 85, 88, 89, 88, 87, 85, 83, 80, 78, 76, 74},
    /* 7500*/ {32, 43, 54, 65, 75, 82, 84, 85, 84, 82, 80, 78, 75, 72, 70, 68},
    /* 8000*/ {28, 39, 50, 61, 71, 78, 80, 80, 79, 77, 75, 72, 69, 66, 63, 61}
};
```

### Spark Timing Map (Base Advance)
```c
// 16x16 Spark map: RPM (rows) x Load (columns)
// Values in degrees BTDC (Before Top Dead Center)
const float SparkMap[16][16] = {
    // Load:  10   20   30   40   50   60   70   80   90  100  110  120  130  140  150  160 %
    /*  500*/ {15, 18, 20, 22, 24, 25, 26, 26, 26, 25, 24, 23, 22, 21, 20, 19},
    /* 1000*/ {18, 22, 25, 28, 30, 32, 33, 33, 32, 31, 30, 28, 27, 26, 25, 24},
    /* 1500*/ {20, 25, 28, 32, 35, 37, 38, 38, 37, 36, 34, 32, 30, 29, 28, 27},
    /* 2000*/ {22, 27, 31, 35, 38, 40, 41, 41, 40, 38, 36, 34, 32, 31, 30, 29},
    /* 2500*/ {24, 29, 33, 37, 40, 42, 43, 42, 41, 39, 37, 35, 33, 32, 31, 30},
    /* 3000*/ {25, 30, 34, 38, 41, 43, 43, 42, 41, 39, 37, 35, 33, 32, 31, 30},
    /* 3500*/ {26, 31, 35, 39, 41, 42, 42, 41, 40, 38, 36, 34, 32, 31, 30, 29},
    /* 4000*/ {27, 31, 35, 38, 40, 41, 41, 40, 39, 37, 35, 33, 31, 30, 29, 28},
    /* 4500*/ {27, 31, 34, 37, 39, 40, 40, 39, 37, 35, 33, 31, 29, 28, 27, 26},
    /* 5000*/ {26, 30, 33, 36, 38, 39, 38, 37, 35, 33, 31, 29, 27, 26, 25, 24},
    /* 5500*/ {25, 29, 32, 35, 36, 37, 36, 35, 33, 31, 29, 27, 25, 24, 23, 22},
    /* 6000*/ {24, 28, 31, 33, 34, 35, 34, 33, 31, 29, 27, 25, 23, 22, 21, 20},
    /* 6500*/ {23, 27, 29, 31, 32, 32, 31, 30, 28, 26, 24, 22, 20, 19, 18, 17},
    /* 7000*/ {22, 25, 27, 29, 29, 29, 28, 27, 25, 23, 21, 19, 17, 16, 15, 14},
    /* 7500*/ {20, 23, 25, 26, 26, 26, 25, 24, 22, 20, 18, 16, 14, 13, 12, 11},
    /* 8000*/ {18, 21, 22, 23, 23, 23, 22, 21, 19, 17, 15, 13, 11, 10,  9,  8}
};
```

## OBD-II Readiness Monitors

```c
// OBD-II Monitor Status
typedef struct {
    bool misfire_monitor_complete;
    bool fuel_system_monitor_complete;
    bool components_monitor_complete;
    bool catalyst_monitor_complete;
    bool heated_catalyst_monitor_complete;
    bool evap_system_monitor_complete;
    bool secondary_air_monitor_complete;
    bool oxygen_sensor_monitor_complete;
    bool oxygen_sensor_heater_monitor_complete;
    bool egr_system_monitor_complete;
} OBD_MonitorStatus_t;

void OBD_UpdateReadinessMonitors(void) {
    // Misfire Monitor (continuous)
    if (Misfire_TestComplete() && Drive_Cycle_Conditions_Met()) {
        monitors.misfire_monitor_complete = true;
    }

    // Catalyst Monitor (requires closed-loop, specific load/speed)
    if (Catalyst_Test_Entry_Conditions()) {
        float lambda_switch_count = O2_Downstream_SwitchCount();
        float catalyst_efficiency = lambda_switch_count / lambda_upstream_switches;

        if (catalyst_efficiency < CATALYST_EFFICIENCY_THRESHOLD) {
            Fault_SetDTC(DTC_P0420_CATALYST_EFFICIENCY);
        } else {
            monitors.catalyst_monitor_complete = true;
        }
    }

    // EVAP Monitor (fuel tank pressure decay test)
    if (EVAP_Test_Entry_Conditions()) {
        float pressure_decay_rate = EVAP_RunPressureTest();

        if (pressure_decay_rate > EVAP_LEAK_THRESHOLD) {
            Fault_SetDTC(DTC_P0442_EVAP_LEAK_SMALL);
        } else {
            monitors.evap_system_monitor_complete = true;
        }
    }

    // EGR Monitor (position sensor vs expected flow)
    if (EGR_Test_Entry_Conditions()) {
        float egr_expected_flow = EGR_Map_Lookup(rpm, load);
        float egr_actual_flow = MAF_MeasureEGR();

        if (fabs(egr_expected_flow - egr_actual_flow) > EGR_TOLERANCE) {
            Fault_SetDTC(DTC_P0401_EGR_INSUFFICIENT_FLOW);
        } else {
            monitors.egr_system_monitor_complete = true;
        }
    }
}

// MIL Illumination Logic (Two-trip fault detection)
void OBD_MIL_Logic(uint16_t dtc) {
    static uint8_t fault_count[256] = {0};

    if (DTC_IsPending(dtc)) {
        fault_count[dtc]++;

        if (fault_count[dtc] >= 2) {  // Two consecutive trips
            MIL_Illuminate();
            DTC_StoreConfirmed(dtc);
            DTC_StoreFreezeFrame(dtc);
        }
    } else {
        fault_count[dtc] = 0;  // Reset if fault not present
    }
}
```

## AUTOSAR Integration

```c
// AUTOSAR Runnable for ECM main control (10ms cyclic)
FUNC(void, ECM_CODE) ECM_MainFunction(void) {
    // Read sensors via AUTOSAR RTE
    Rte_Read_SensorCluster_EngineSpeed(&rpm);
    Rte_Read_SensorCluster_ThrottlePosition(&throttle_pos);
    Rte_Read_SensorCluster_MAP(&manifold_pressure);
    Rte_Read_SensorCluster_CoolantTemp(&coolant_temp);
    Rte_Read_SensorCluster_IntakeAirTemp(&iat);
    Rte_Read_SensorCluster_LambdaSensor(&lambda_actual);

    // Calculate fuel injection pulse
    FuelCalc_t fuel_calc = {
        .lambda_target = 1.0f,
        .lambda_actual = lambda_actual,
        .temp_correction = Temp_Correction(coolant_temp, iat),
        .transient_comp = WallWetting_Compensation(throttle_rate),
        .battery_correction = Battery_Compensation(battery_voltage)
    };

    float injection_pulse_ms = ECM_CalculateInjectionPulse(&fuel_calc, maf_gs, rpm);

    // Calculate spark timing
    IgnitionTiming_t ign_timing = {
        .coolant_adv_deg = Coolant_AdvanceCurve(coolant_temp),
        .altitude_adv_deg = Altitude_Compensation(barometric_pressure)
    };

    float spark_advance_deg = ECM_CalculateSparkAdvance(&ign_timing, rpm, load);

    // Calculate turbo boost (if equipped)
    float boost_target_kPa = BoostMap_Lookup(rpm, throttle_pos);
    float wastegate_duty = Turbo_BoostControl(boost_target_kPa, boost_actual_kPa,
                                               &boost_pid, 0.01f);

    // Calculate EGR position
    float egr_position = EGR_CalculatePosition(rpm, load, coolant_temp);

    // Write actuators via AUTOSAR RTE
    Rte_Write_ActuatorCluster_InjectionPulse(injection_pulse_ms);
    Rte_Write_ActuatorCluster_SparkAdvance(spark_advance_deg);
    Rte_Write_ActuatorCluster_WastegatePosition(wastegate_duty);
    Rte_Write_ActuatorCluster_EGR_Position(egr_position);

    // Update OBD-II monitors
    OBD_UpdateReadinessMonitors();
}
```

## HIL Test Scenarios

### Test Case 1: Cold Start Emissions
```yaml
test_id: ECM_001_COLD_START
objective: Validate cold start emissions and catalyst light-off time
preconditions:
  - Coolant temperature: -7°C (EPA cold start spec)
  - Fuel tank: 50% full
  - Battery voltage: 12.6V

test_steps:
  1. Crank engine (starter engaged)
  2. Monitor time to first fire (<1.0 seconds)
  3. Monitor idle speed stabilization (<5 seconds to 1200 RPM)
  4. Monitor catalyst light-off time (<60 seconds to 300°C)
  5. Measure HC/CO/NOx emissions during first 120 seconds

pass_criteria:
  - Time to first fire: <1.0s
  - Idle stabilization: <5s
  - Catalyst light-off: <60s
  - HC emissions: <1.5 g/km (FTP-75 cycle)
  - CO emissions: <4.2 g/km
  - NOx emissions: <0.06 g/km (Tier 3 Bin 30)
```

### Test Case 2: Wide Open Throttle (WOT) Performance
```yaml
test_id: ECM_002_WOT_PERFORMANCE
objective: Validate max power delivery and knock control
preconditions:
  - Engine at operating temperature (90°C)
  - Fuel: 91 AKI (octane rating)
  - Ambient: 25°C, 1013 mbar

test_steps:
  1. Start at 1500 RPM, light load
  2. Apply 100% throttle
  3. Monitor power curve from 1500-7000 RPM
  4. Monitor for knock events
  5. Verify boost control (turbo engines)

pass_criteria:
  - Peak power: Within 5% of calibration target
  - Peak torque: Within 5% of calibration target
  - No sustained knock events (transient knock OK)
  - Boost pressure: ±5 kPa of target throughout RPM range
  - AFR: 0.85-0.90 lambda during WOT
```

### Test Case 3: Emissions Durability (OBD-II)
```yaml
test_id: ECM_003_OBD_READINESS
objective: Verify OBD-II monitors complete within EPA drive cycle
preconditions:
  - Clear all DTCs
  - Perform key-off/key-on cycle

test_steps:
  1. Execute FTP-75 drive cycle
  2. Monitor readiness status for all monitors
  3. Verify no false DTCs triggered

pass_criteria:
  - Misfire monitor: Complete
  - Fuel system monitor: Complete
  - Catalyst monitor: Complete
  - EVAP monitor: Complete (requires tank temp conditions)
  - EGR monitor: Complete
  - O2 sensor monitors: Complete
  - No false DTCs stored
```

## ISO 26262 Safety Concept

### ASIL Decomposition for ECM

| Function | ASIL | Decomposition | Rationale |
|----------|------|---------------|-----------|
| Fuel injection | ASIL-D | ASIL-B(B) + ASIL-B(B) | Split into pulse calculation (B) and driver control (B) |
| Ignition timing | ASIL-D | ASIL-C(C) + ASIL-A(A) | Knock control (C), base timing (A) |
| Throttle monitoring | ASIL-D | ASIL-C(C) + ASIL-B(B) | Dual-channel position sensors |
| Boost control | ASIL-C | No decomposition | Overspeed protection via mechanical wastegate |

### Safety Mechanisms

1. **Plausibility Checks**: Cross-check TPS vs MAP (should correlate at steady-state)
2. **Limp-Home Mode**: Fixed ignition timing, reduced power if critical sensor fails
3. **Cylinder Cutoff**: Disable fuel to cylinder if misfire detected (prevents catalyst damage)
4. **Independent Watchdog**: External watchdog monitors ECM task execution
5. **RAM/ROM Tests**: Periodic memory checks (ISO 26262 Part 5)

## CAN Signal Definitions (DBC)

```dbc
BO_ 256 ECM_Status: 8 ECM
 SG_ EngineSpeed : 0|16@1+ (0.25,0) [0|16383.75] "rpm" PCM,TCM,ESC
 SG_ EngineTorque : 16|16@1+ (0.5,-500) [-500|32267.5] "Nm" PCM,TCM
 SG_ ThrottlePosition : 32|8@1+ (0.4,0) [0|102] "%" PCM,TCM,ESC
 SG_ CoolantTemp : 40|8@1- (1,-40) [-40|215] "degC" PCM,HMI
 SG_ Lambda : 48|8@1+ (0.01,0) [0|2.55] "lambda" PCM
 SG_ BoostPressure : 56|8@1+ (2,0) [0|510] "kPa" PCM,HMI

BO_ 257 ECM_Faults: 8 ECM
 SG_ MIL_Status : 0|2@1+ (1,0) [0|3] "" PCM,HMI
 SG_ DTC_Count : 2|6@1+ (1,0) [0|63] "" PCM,HMI
 SG_ Misfire_Cylinder1 : 8|1@1+ (1,0) [0|1] "" PCM
 SG_ Misfire_Cylinder2 : 9|1@1+ (1,0) [0|1] "" PCM
 SG_ Misfire_Cylinder3 : 10|1@1+ (1,0) [0|1] "" PCM
 SG_ Misfire_Cylinder4 : 11|1@1+ (1,0) [0|1] "" PCM
 SG_ Knock_Detected : 12|1@1+ (1,0) [0|1] "" PCM
 SG_ Catalyst_Efficiency : 13|1@1+ (1,0) [0|1] "" PCM
```

## Tools and Calibration

- **INCA/CANape**: A2L-based calibration, live tuning on dyno
- **ATI Vision**: ECU flashing, bootloader programming
- **MATLAB/Simulink**: Model-based development, automatic code generation
- **TargetLink**: Production code generation with ISO 26262 certificate
- **Polyspace**: Static analysis for MISRA-C compliance
- **Vector CANoe**: Virtual ECU testing, residual bus simulation

## References
- ISO 15031 (OBD-II Communication)
- SAE J1979 (E/E Diagnostic Test Modes)
- ISO 26262 (Functional Safety)
- SAE J2534 (Pass-Thru Programming)
- EPA Tier 3 Emissions Standards
- CARB LEV III Standards

---

## Eps Steering Systems

# EPS Electric Power Steering Systems Skill

## Overview
Expert skill in Electric Power Steering (EPS) system development. Covers assist torque calculation, returnability, damping control, steering feel tuning, park assist integration, lane centering assist, driver hands-on detection, and ISO 26262 ASIL-D safety requirements.

## Core Competencies

### 1. Assist Torque Calculation
- **Speed-Dependent Assist**: High assist at low speed (parking), minimal assist at high speed (stability)
- **Torque Sensor Fusion**: Dual-sensor redundancy for ASIL-D compliance
- **Motor Control**: BLDC/PMSM field-oriented control (FOC), current mode control
- **Compensation**: Friction compensation, inertia compensation, KPI tuning

### 2. Returnability and Damping
- **Self-Centering**: Automatic steering wheel return to center after cornering
- **Damping Control**: Velocity-dependent damping to prevent oscillations
- **Hysteresis Compensation**: Eliminate mechanical friction dead-zone
- **Tuning**: Balance returnability (too strong = jerky) vs stability (too weak = wander)

### 3. Steering Feel Optimization
- **On-Center Feel**: Tight on-center for highway stability, wider for city comfort
- **Build-Up Gradient**: Torque vs angle relationship (linear, progressive, degressive)
- **Road Feedback**: Transmit road surface feel (driver preference: sporty vs comfort)
- **Driver Intent Recognition**: Detect parking vs highway vs emergency maneuver

### 4. Park Assist Integration
- **Automated Steering**: Follow path controller for parallel/perpendicular parking
- **Speed Limit**: Max 7 kph for park assist actuation
- **Driver Override**: Instant deactivation on driver torque >3 Nm
- **Fail-Safe**: Return control to driver on sensor fault

### 5. Lane Centering Assist (LCA)
- **Camera-Based Control**: Follow lane markings, gentle steering corrections
- **Hands-On Detection**: Capacitive steering wheel, torque threshold monitoring
- **Comfort Tuning**: Smooth intervention, avoid "ping-pong" effect
- **Takeover Request**: Escalating warnings if driver inattentive

### 6. ISO 26262 ASIL-D Safety
- **Redundant Torque Sensors**: Dual sensors with plausibility check
- **Motor Position Sensors**: Dual resolver/encoder with voting logic
- **Safe Torque Off (STO)**: Hardware safety switch to disable motor
- **End-of-Line Test**: Automated safety function verification

## Control Algorithms

### Assist Torque Calculation
```c
typedef struct {
    float driver_torque_nm;        // From torque sensor
    float vehicle_speed_kph;       // From CAN
    float motor_angle_deg;         // Steering column angle
    float motor_velocity_dps;      // Steering rate
} EPS_Input_t;

typedef struct {
    float base_assist_factor;      // Speed-dependent assist curve
    float damping_coefficient;     // Velocity damping
    float returnability_gain;      // Self-centering strength
    float friction_compensation;   // Static friction offset
} EPS_Parameters_t;

float EPS_CalculateAssistTorque(EPS_Input_t *input, EPS_Parameters_t *params) {
    // Speed-dependent assist curve (lookup table)
    // Low speed: 100% assist, High speed: 20% assist
    float assist_curve[8] = {1.0f, 0.95f, 0.80f, 0.60f, 0.40f, 0.30f, 0.25f, 0.20f};
    uint8_t speed_index = CLAMP((int)(input->vehicle_speed_kph / 20.0f), 0, 7);
    params->base_assist_factor = assist_curve[speed_index];

    // Base assist torque (proportional to driver input)
    float assist_torque = input->driver_torque_nm * params->base_assist_factor * 8.0f;

    // Friction compensation (overcome column friction)
    float friction_sign = (input->motor_velocity_dps > 0) ? 1.0f : -1.0f;
    assist_torque += friction_sign * params->friction_compensation;

    // Damping (velocity-dependent, prevent oscillation)
    float damping_torque = -params->damping_coefficient * input->motor_velocity_dps;
    assist_torque += damping_torque;

    // Returnability (self-centering spring)
    float return_torque = -params->returnability_gain * input->motor_angle_deg;
    assist_torque += return_torque;

    // Torque limits (motor capability)
    return CLAMP(assist_torque, -6.0f, 6.0f);  // Nm
}
```

### Motor Current Control (FOC)
```c
// Field-Oriented Control for BLDC motor
typedef struct {
    float id_target;      // d-axis current (field weakening)
    float iq_target;      // q-axis current (torque generation)
    float id_actual;
    float iq_actual;
    float motor_angle;    // Electrical angle (from resolver)
} FOC_Controller_t;

void EPS_FOC_CurrentControl(FOC_Controller_t *foc, float dt) {
    // Clarke transform: 3-phase ABC → 2-phase αβ
    float i_alpha = foc->ia;
    float i_beta = (foc->ia + 2.0f * foc->ib) / sqrtf(3.0f);

    // Park transform: αβ → dq (rotor-aligned frame)
    float cos_theta = cosf(foc->motor_angle);
    float sin_theta = sinf(foc->motor_angle);

    foc->id_actual = i_alpha * cos_theta + i_beta * sin_theta;
    foc->iq_actual = -i_alpha * sin_theta + i_beta * cos_theta;

    // PI controllers for d and q axis
    static float id_integral = 0.0f, iq_integral = 0.0f;

    float id_error = foc->id_target - foc->id_actual;
    id_integral += id_error * dt;
    float vd = KP_D * id_error + KI_D * id_integral;

    float iq_error = foc->iq_target - foc->iq_actual;
    iq_integral += iq_error * dt;
    float vq = KP_Q * iq_error + KI_Q * iq_integral;

    // Inverse Park: dq → αβ
    float v_alpha = vd * cos_theta - vq * sin_theta;
    float v_beta = vd * sin_theta + vq * cos_theta;

    // Inverse Clarke: αβ → ABC
    float va = v_alpha;
    float vb = -0.5f * v_alpha + (sqrtf(3.0f) / 2.0f) * v_beta;
    float vc = -0.5f * v_alpha - (sqrtf(3.0f) / 2.0f) * v_beta;

    // PWM modulation
    PWM_SetDutyCycle(PHASE_A, va);
    PWM_SetDutyCycle(PHASE_B, vb);
    PWM_SetDutyCycle(PHASE_C, vc);
}
```

### Lane Centering Assist
```c
typedef struct {
    float lane_offset_m;          // Distance from lane center
    float lane_heading_deg;       // Angle to lane center
    float kp_lateral;             // Proportional gain
    float kd_lateral;             // Derivative gain
    bool hands_on;                // Driver hands detected
    float intervention_torque;    // LCA torque overlay
} LCA_Controller_t;

float LCA_CalculateTorque(LCA_Controller_t *lca, float vehicle_speed, float dt) {
    // Disable if driver not holding wheel
    if (!lca->hands_on) {
        return 0.0f;
    }

    // PD controller for lane centering
    float lateral_error = lca->lane_offset_m;
    float heading_error = lca->lane_heading_deg * DEG_TO_RAD;

    // Predict future lateral error (preview control)
    float preview_time = 0.5f;  // seconds
    float predicted_error = lateral_error + vehicle_speed * sinf(heading_error) * preview_time;

    // PD control law
    float p_term = lca->kp_lateral * predicted_error;
    float d_term = lca->kd_lateral * heading_error;

    lca->intervention_torque = p_term + d_term;

    // Gentle intervention limits (comfort)
    lca->intervention_torque = CLAMP(lca->intervention_torque, -1.5f, 1.5f);  // Nm

    return lca->intervention_torque;
}

// Hands-on detection (capacitive + torque threshold)
bool LCA_HandsOnDetection(float driver_torque, float capacitive_level) {
    // Capacitive sensor detects hand contact
    if (capacitive_level > CAPACITIVE_THRESHOLD) {
        return true;
    }

    // Torque threshold as backup (driver applying force)
    if (fabs(driver_torque) > 1.0f) {  // 1 Nm
        return true;
    }

    return false;
}
```

### Fail-Safe State Machine
```c
typedef enum {
    EPS_NORMAL,
    EPS_DEGRADED,
    EPS_SAFE_TORQUE_OFF,
    EPS_FAULT
} EPS_SafetyState_t;

void EPS_SafetyStateMachine(void) {
    static EPS_SafetyState_t state = EPS_NORMAL;

    // Read dual torque sensors
    float torque_sensor_1 = ADC_ReadTorqueSensor1();
    float torque_sensor_2 = ADC_ReadTorqueSensor2();

    // Plausibility check (ASIL-D requirement)
    float torque_diff = fabs(torque_sensor_1 - torque_sensor_2);

    switch (state) {
    case EPS_NORMAL:
        // Full EPS functionality
        if (torque_diff > TORQUE_PLAUSIBILITY_THRESHOLD) {
            state = EPS_DEGRADED;
            Fault_SetDTC(DTC_EPS_TORQUE_SENSOR_MISMATCH);
        }
        break;

    case EPS_DEGRADED:
        // Use single sensor, reduce assist torque by 50%
        Assist_Multiplier = 0.5f;
        HMI_SetEPS_Warning(true);

        // Recovery: if both sensors agree again for 5 seconds
        if (torque_diff < TORQUE_PLAUSIBILITY_THRESHOLD * 0.5f) {
            static uint16_t recovery_count = 0;
            recovery_count++;
            if (recovery_count > 250) {  // 5 sec at 50Hz
                state = EPS_NORMAL;
                recovery_count = 0;
            }
        }

        // Escalate if motor position sensor fails
        if (Resolver_Fault_Detected()) {
            state = EPS_SAFE_TORQUE_OFF;
        }
        break;

    case EPS_SAFE_TORQUE_OFF:
        // Disable motor immediately (hardware safety switch)
        STO_ActivateSafetySwitch();
        HMI_SetEPS_Fault(true);
        state = EPS_FAULT;
        break;

    case EPS_FAULT:
        // Manual steering only (no EPS assist)
        // Requires vehicle restart to clear
        break;
    }
}
```

## Calibration Parameters

```c
// Speed-dependent assist curve (lookup table)
const float Assist_Curve_LUT[16] = {
    // Speed:   0   10   20   30   40   50   60   70   80   90  100  110  120  130  140  150 kph
    /*Assist*/ 1.0, 0.98, 0.92, 0.82, 0.68, 0.54, 0.42, 0.34, 0.28, 0.24, 0.22, 0.20, 0.20, 0.20, 0.20, 0.20
};

// Damping coefficient (Nm/(deg/s))
const float Damping_Curve_LUT[8] = {
    // Speed:   0   20   40   60   80  100  120  140 kph
    /*Damping*/ 0.01, 0.015, 0.020, 0.025, 0.030, 0.035, 0.040, 0.045
};

// Returnability gain (self-centering)
const float Returnability_LUT[8] = {
    // Speed:   0   20   40   60   80  100  120  140 kph
    /*Return*/  0.02, 0.025, 0.030, 0.032, 0.033, 0.034, 0.035, 0.035
};
```

## AUTOSAR Integration

```c
FUNC(void, EPS_CODE) EPS_MainFunction(void) {
    // Read inputs (1 kHz task for safety-critical control)
    Rte_Read_TorqueSensor_Primary(&driver_torque_1);
    Rte_Read_TorqueSensor_Secondary(&driver_torque_2);
    Rte_Read_ResolverPosition(&motor_angle);
    Rte_Read_ResolverVelocity(&motor_velocity);
    Rte_Read_CAN_VehicleSpeed(&vehicle_speed);

    // Plausibility check (ASIL-D)
    if (fabs(driver_torque_1 - driver_torque_2) < TORQUE_PLAUSIBILITY_THRESHOLD) {
        driver_torque = (driver_torque_1 + driver_torque_2) / 2.0f;
    } else {
        EPS_SafetyStateMachine();
    }

    // Calculate assist torque
    EPS_Input_t input = {driver_torque, vehicle_speed, motor_angle, motor_velocity};
    EPS_Parameters_t params;
    float assist_torque = EPS_CalculateAssistTorque(&input, &params);

    // Lane centering overlay (if active)
    if (ADAS_LCA_Active()) {
        LCA_Controller_t lca;
        Rte_Read_Camera_LaneOffset(&lca.lane_offset_m);
        Rte_Read_Camera_LaneHeading(&lca.lane_heading_deg);
        lca.hands_on = LCA_HandsOnDetection(driver_torque, Capacitive_Sensor_Read());

        float lca_torque = LCA_CalculateTorque(&lca, vehicle_speed, 0.001f);
        assist_torque += lca_torque;
    }

    // Motor current control (FOC)
    FOC_Controller_t foc = {.iq_target = assist_torque / MOTOR_TORQUE_CONSTANT};
    EPS_FOC_CurrentControl(&foc, 0.001f);

    // Write outputs
    Rte_Write_CAN_EPS_AssistTorque(assist_torque);
    Rte_Write_CAN_EPS_MotorCurrent(foc.iq_actual);
}
```

## HIL Test Scenarios

### Test Case 1: Park Assist Torque (ASIL-D)
```yaml
test_id: EPS_001_PARK_ASSIST
objective: Validate high assist torque at low speed
preconditions:
  - Vehicle speed: 5 kph
  - Driver torque: 5 Nm (parking maneuver)

test_steps:
  1. Apply driver torque sensor input
  2. Monitor motor assist torque
  3. Verify torque sensor redundancy

pass_criteria:
  - Assist torque: 35-45 Nm (8-9x amplification)
  - Dual torque sensors agree within ±0.5 Nm
  - Motor current: <100 A peak
  - Response time: <50 ms
```

### Test Case 2: Highway Stability (High Speed)
```yaml
test_id: EPS_002_HIGHWAY_STABILITY
objective: Minimal assist at high speed for stability
preconditions:
  - Vehicle speed: 120 kph
  - Driver torque: 2 Nm (lane change)

test_steps:
  1. Apply small steering input
  2. Verify low assist ratio
  3. Check damping prevents oscillation

pass_criteria:
  - Assist torque: 3-5 Nm (1.5-2.5x amplification)
  - No steering oscillation after lane change
  - Returnability: Wheel returns to center within 1.5 seconds
```

### Test Case 3: Sensor Fault Handling (ASIL-D)
```yaml
test_id: EPS_003_SENSOR_FAULT
objective: Graceful degradation on torque sensor failure
preconditions:
  - EPS in normal mode
  - Vehicle speed: 60 kph

test_steps:
  1. Inject fault: Torque sensor 1 reads +3 Nm, sensor 2 reads -2 Nm
  2. Monitor plausibility check
  3. Verify degraded mode activation
  4. Confirm driver warning

pass_criteria:
  - Plausibility fault detected within 10ms
  - Degraded mode: Use single sensor, 50% assist reduction
  - EPS warning lamp illuminated within 100ms
  - No loss of steering (fail-operational)
```

## ISO 26262 Safety Concept

### ASIL-D Requirements
- **Dual Torque Sensors**: Independent measurement chains, cross-check every 1ms
- **Dual Position Sensors**: Resolver + Hall sensor with voting logic
- **Safe Torque Off (STO)**: Hardware-enforced motor disable on critical fault
- **Diagnostic Coverage**: >99% for ASIL-D, watchdog, RAM/ROM test, sensor range checks

## CAN Signals (DBC)

```dbc
BO_ 280 EPS_Status: 8 EPS
 SG_ DriverTorque : 0|16@1- (0.01,-327.68) [-327.68|327.67] "Nm" ADAS,ESC
 SG_ AssistTorque : 16|16@1- (0.01,-327.68) [-327.68|327.67] "Nm" ADAS
 SG_ MotorAngle : 32|16@1- (0.1,-3276.8) [-3276.8|3276.7] "deg" ESC
 SG_ EPS_State : 48|2@1+ (1,0) [0|3] "" HMI
 SG_ HandsOn : 50|1@1+ (1,0) [0|1] "" ADAS
```

## References
- ISO 26262-6 (EPS software safety)
- ISO 26262-8 (EPS hardware safety)
- UN ECE R79 (Steering equipment)
- SAE J2874 (EPS test procedures)

---

## Esc Stability Control

# ESC Electronic Stability Control Skill

## Overview
Expert skill in Electronic Stability Control (ESC) system development for vehicle stability management. Covers yaw rate control, slip angle estimation, selective brake intervention, understeer/oversteer detection, traction control (TCS), hill hold assist, and integration with ABS/EPS systems.

## Core Competencies

### 1. Yaw Rate Control
- **Reference Model**: Ideal yaw rate based on steering angle, vehicle speed, tire characteristics
- **Feedback Control**: PI/PID controller to minimize yaw rate error
- **Brake Intervention**: Selective brake force distribution to generate corrective yaw moment
- **Torque Reduction**: Coordinated engine torque cut for stability

### 2. Slip Angle Estimation
- **Kinematic Observer**: Estimate vehicle sideslip angle β from lateral acceleration, yaw rate
- **Kalman Filter**: Fuse IMU sensors (gyro, accelerometer) with wheel speed sensors
- **GPS/INS Integration**: High-accuracy β estimation for ADAS/autonomous vehicles
- **Cornering Stiffness Adaptation**: Real-time tire model parameter identification

### 3. Brake Intervention Strategy
- **Understeer Correction**: Brake inner rear wheel to induce yaw-in moment
- **Oversteer Correction**: Brake outer front wheel to induce yaw-out moment
- **Pressure Modulation**: Rapid hydraulic pressure cycling (10-20 Hz) via ABS valves
- **Coordination with ABS**: Brake force limited by wheel slip constraints

### 4. Understeer/Oversteer Detection
- **Understeer**: Actual yaw rate < desired yaw rate (vehicle turns less than intended)
- **Oversteer**: Actual yaw rate > desired yaw rate (vehicle turns more than intended)
- **Neutral Steer**: Actual ≈ desired (stable cornering)
- **Threshold Tuning**: Speed-dependent thresholds to avoid false triggers

### 5. Traction Control (TCS)
- **Drive Wheel Slip Control**: Limit slip ratio to 10-15% for maximum traction
- **Engine Torque Reduction**: Spark retard, fuel cut, throttle close
- **Brake-Based TCS**: Apply brake to spinning wheel (open differential vehicles)
- **Torque Vectoring**: Differential brake force for enhanced cornering (EBD)

### 6. Hill Hold Assist (HHA)
- **Gradient Detection**: Estimate road slope from longitudinal accelerometer
- **Brake Pressure Hold**: Maintain brake pressure for 2 seconds after brake release
- **Smooth Release**: Gradual pressure reduction as driver applies throttle
- **Rollback Prevention**: <1% grade rollback allowed on 15% slope

## Control Algorithms

### Reference Yaw Rate Calculation (Bicycle Model)
```c
// Calculate desired yaw rate based on driver input and vehicle dynamics
typedef struct {
    float steering_angle_deg;   // Steering wheel angle
    float vehicle_speed_mps;    // Longitudinal velocity
    float wheelbase_m;          // Distance between front and rear axles
    float understeer_gradient;  // Characteristic understeer gradient (K)
} VehicleModel_t;

float ESC_CalculateReferenceYawRate(VehicleModel_t *model) {
    // Convert steering wheel angle to road wheel angle
    float road_wheel_angle = model->steering_angle_deg / STEERING_RATIO;
    float delta_rad = road_wheel_angle * DEG_TO_RAD;

    // Understeer gradient (rad/g)
    float K = model->understeer_gradient;  // Typical: 0.002-0.005 for understeer

    // Lateral acceleration at current speed and steering
    float lat_accel = (model->vehicle_speed_mps * model->vehicle_speed_mps * delta_rad) / model->wheelbase_m;

    // Reference yaw rate (rad/s) with understeer compensation
    float yaw_rate_ref = model->vehicle_speed_mps * delta_rad / (model->wheelbase_m * (1.0f + K * lat_accel / GRAVITY));

    // Saturation limits (vehicle physical limits)
    float yaw_rate_max = 0.85f * GRAVITY / model->vehicle_speed_mps;  // ~0.85g lateral limit
    return CLAMP(yaw_rate_ref, -yaw_rate_max, yaw_rate_max);
}
```

### Slip Angle Estimation (Kinematic Observer)
```c
// Estimate vehicle sideslip angle β using sensor fusion
typedef struct {
    float yaw_rate;           // Measured from gyro (rad/s)
    float lat_accel;          // Measured from accelerometer (m/s²)
    float longitudinal_vel;   // From wheel speeds (m/s)
    float beta_estimate;      // Estimated sideslip angle (rad)
} SlipAngleEstimator_t;

void ESC_EstimateSideslipAngle(SlipAngleEstimator_t *est, float dt) {
    // Kinematic relationship: dβ/dt = ay/vx - ψ̇
    // where β = sideslip angle, ay = lateral accel, vx = longitudinal vel, ψ̇ = yaw rate

    float beta_dot = (est->lat_accel / est->longitudinal_vel) - est->yaw_rate;

    // Integrate to get sideslip angle
    est->beta_estimate += beta_dot * dt;

    // Low-pass filter to remove noise (cutoff 1 Hz)
    static float beta_filtered = 0.0f;
    float alpha = dt / (dt + 1.0f / (2.0f * PI * 1.0f));  // RC filter
    beta_filtered = alpha * est->beta_estimate + (1.0f - alpha) * beta_filtered;
    est->beta_estimate = beta_filtered;

    // Clamp to physical limits (±15 degrees)
    est->beta_estimate = CLAMP(est->beta_estimate, -0.26f, 0.26f);  // radians
}
```

### Yaw Stability Controller
```c
typedef enum {
    ESC_STABLE,
    ESC_UNDERSTEER,
    ESC_OVERSTEER,
    ESC_CRITICAL
} ESC_State_t;

typedef struct {
    float kp_yaw;             // Proportional gain for yaw rate error
    float ki_yaw;             // Integral gain
    float yaw_rate_error;     // Reference - actual yaw rate
    float integral_yaw;       // Integral accumulator
    ESC_State_t state;        // Current stability state
} ESC_Controller_t;

float ESC_YawController(ESC_Controller_t *ctrl, float yaw_ref, float yaw_actual, float dt) {
    ctrl->yaw_rate_error = yaw_ref - yaw_actual;

    // Dead-zone to prevent unnecessary intervention (±0.05 rad/s)
    if (fabs(ctrl->yaw_rate_error) < 0.05f) {
        ctrl->integral_yaw = 0.0f;
        ctrl->state = ESC_STABLE;
        return 0.0f;  // No intervention needed
    }

    // PI controller for corrective yaw moment
    float p_term = ctrl->kp_yaw * ctrl->yaw_rate_error;

    ctrl->integral_yaw += ctrl->yaw_rate_error * dt;
    ctrl->integral_yaw = CLAMP(ctrl->integral_yaw, -2.0f, 2.0f);  // Anti-windup
    float i_term = ctrl->ki_yaw * ctrl->integral_yaw;

    // Desired corrective yaw moment (N⋅m)
    float yaw_moment = p_term + i_term;

    // Classify state based on error magnitude
    if (ctrl->yaw_rate_error > 0.1f) {
        ctrl->state = ESC_UNDERSTEER;
    } else if (ctrl->yaw_rate_error < -0.1f) {
        ctrl->state = ESC_OVERSTEER;
    } else {
        ctrl->state = ESC_STABLE;
    }

    return yaw_moment;
}
```

### Brake Force Distribution (Understeer/Oversteer Correction)
```c
typedef struct {
    float FL_brake_force;  // Front-left brake force (N)
    float FR_brake_force;  // Front-right
    float RL_brake_force;  // Rear-left
    float RR_brake_force;  // Rear-right
} BrakeForces_t;

void ESC_CalculateBrakeForces(ESC_Controller_t *ctrl, float yaw_moment_desired,
                               BrakeForces_t *brakes, float vehicle_speed) {
    // Track width (distance between left and right wheels)
    const float TRACK_WIDTH_M = 1.6f;

    // Required brake force to generate yaw moment: F = M / (track_width / 2)
    float brake_force_single_wheel = fabs(yaw_moment_desired) / (TRACK_WIDTH_M / 2.0f);

    // Limit brake force based on vehicle speed (lower at high speed for comfort)
    float max_brake_force = 8000.0f - (vehicle_speed * 50.0f);  // N
    brake_force_single_wheel = CLAMP(brake_force_single_wheel, 0.0f, max_brake_force);

    // Initialize all brakes to zero
    memset(brakes, 0, sizeof(BrakeForces_t));

    switch (ctrl->state) {
    case ESC_UNDERSTEER:
        // Vehicle understeers (yaw rate too low, not turning enough)
        // Brake INNER REAR wheel to create yaw-in moment
        if (ctrl->yaw_rate_error > 0) {
            brakes->RL_brake_force = brake_force_single_wheel;  // Turning right, brake left rear
        } else {
            brakes->RR_brake_force = brake_force_single_wheel;  // Turning left, brake right rear
        }
        break;

    case ESC_OVERSTEER:
        // Vehicle oversteers (yaw rate too high, turning too much, tail sliding out)
        // Brake OUTER FRONT wheel to create yaw-out moment
        if (ctrl->yaw_rate_error < 0) {
            brakes->FL_brake_force = brake_force_single_wheel;  // Turning right, brake left front
        } else {
            brakes->FR_brake_force = brake_force_single_wheel;  // Turning left, brake right front
        }
        break;

    case ESC_STABLE:
        // No intervention
        break;

    case ESC_CRITICAL:
        // Extreme instability: brake all wheels and reduce throttle aggressively
        float panic_brake = max_brake_force * 0.6f;
        brakes->FL_brake_force = panic_brake;
        brakes->FR_brake_force = panic_brake;
        brakes->RL_brake_force = panic_brake * 0.8f;  // Rear lighter for rotation control
        brakes->RR_brake_force = panic_brake * 0.8f;

        // Request full engine torque cut
        CAN_Send_TorqueReduction(100.0f);
        break;
    }
}
```

### Traction Control System (TCS)
```c
// Limit drive wheel slip for maximum traction
typedef struct {
    float target_slip_ratio;  // Optimal slip ratio (10-15%)
    float kp_tcs;             // Proportional gain
    float ki_tcs;             // Integral gain
    float integral_tcs[4];    // Per-wheel integral term
} TCS_Controller_t;

void TCS_Control(TCS_Controller_t *tcs, float wheel_speeds[4], float vehicle_speed, float dt) {
    // Drive wheels (assume rear-wheel drive, indices 2 and 3)
    const uint8_t RL = 2;
    const uint8_t RR = 3;

    for (uint8_t i = RL; i <= RR; i++) {
        // Calculate slip ratio: λ = (vwheel - vvehicle) / vvehicle
        float slip_ratio = (wheel_speeds[i] - vehicle_speed) / vehicle_speed;

        // Slip ratio error
        float slip_error = slip_ratio - tcs->target_slip_ratio;

        // Only intervene if slip exceeds target (wheel spinning)
        if (slip_error > 0.02f) {  // 2% dead-zone
            // PI controller
            float p_term = tcs->kp_tcs * slip_error;

            tcs->integral_tcs[i] += slip_error * dt;
            tcs->integral_tcs[i] = CLAMP(tcs->integral_tcs[i], 0.0f, 5.0f);
            float i_term = tcs->ki_tcs * tcs->integral_tcs[i];

            // Torque reduction request (0-100%)
            float torque_reduction = p_term + i_term;
            torque_reduction = CLAMP(torque_reduction, 0.0f, 100.0f);

            // Send torque reduction to ECM
            CAN_Send_TorqueReduction(torque_reduction);

            // Optional: Brake-based TCS (apply brake to spinning wheel)
            if (slip_error > 0.3f) {  // Excessive slip (>30%)
                float brake_pressure = CLAMP(slip_error * 5000.0f, 0.0f, 8000.0f);  // N
                ABS_ApplyBrake(i, brake_pressure);
            }

            // Activate TCS indicator lamp
            HMI_SetTCS_Active(true);
        } else {
            tcs->integral_tcs[i] = 0.0f;  // Reset integral
        }
    }
}
```

### Hill Hold Assist
```c
typedef enum {
    HHA_IDLE,
    HHA_ACTIVE,
    HHA_RELEASING
} HHA_State_t;

typedef struct {
    HHA_State_t state;
    float hold_pressure_bar;
    float hold_timer;
    float gradient_percent;
} HillHoldAssist_t;

void HHA_Control(HillHoldAssist_t *hha, float brake_pedal, float throttle_pedal,
                 float longitudinal_accel, float dt) {
    // Estimate road gradient from accelerometer (when stationary)
    if (Vehicle_Speed < 0.5f) {
        hha->gradient_percent = longitudinal_accel / GRAVITY * 100.0f;
    }

    switch (hha->state) {
    case HHA_IDLE:
        // Activation: driver releases brake on slope >3%
        if (brake_pedal < 10.0f && fabs(hha->gradient_percent) > 3.0f && Vehicle_Speed < 0.5f) {
            // Capture current brake pressure
            hha->hold_pressure_bar = Hydraulic_GetBrakePressure();
            hha->hold_timer = 0.0f;
            hha->state = HHA_ACTIVE;
        }
        break;

    case HHA_ACTIVE:
        // Hold brake pressure to prevent rollback
        Hydraulic_SetBrakePressure(hha->hold_pressure_bar);

        // Increment timer
        hha->hold_timer += dt;

        // Release conditions: throttle applied or timeout (2 seconds)
        if (throttle_pedal > 10.0f || hha->hold_timer > 2.0f) {
            hha->state = HHA_RELEASING;
        }
        break;

    case HHA_RELEASING:
        // Gradually release brake pressure (linear ramp over 0.5 seconds)
        static float release_timer = 0.0f;
        release_timer += dt;

        float release_fraction = release_timer / 0.5f;
        float pressure = hha->hold_pressure_bar * (1.0f - release_fraction);
        Hydraulic_SetBrakePressure(pressure);

        if (release_fraction >= 1.0f || Vehicle_Speed > 2.0f) {
            hha->state = HHA_IDLE;
            release_timer = 0.0f;
        }
        break;
    }
}
```

## State Machine: ESC Intervention Levels

```c
typedef enum {
    ESC_OFF,
    ESC_MONITORING,
    ESC_INTERVENTION_LIGHT,
    ESC_INTERVENTION_HEAVY,
    ESC_PANIC_MODE
} ESC_InterventionLevel_t;

void ESC_StateMachine(void) {
    static ESC_InterventionLevel_t level = ESC_MONITORING;

    float yaw_error = fabs(yaw_ref - yaw_actual);
    float beta = Slip_Angle_Estimate;
    float lateral_accel = IMU_Read_LateralAccel();

    switch (level) {
    case ESC_OFF:
        // ESC disabled by driver (button press)
        // TCS remains active for safety
        if (ESC_Button_Pressed()) {
            level = ESC_MONITORING;
        }
        break;

    case ESC_MONITORING:
        // Normal driving: monitor but don't intervene
        if (yaw_error > 0.05f && fabs(beta) > 0.05f) {
            level = ESC_INTERVENTION_LIGHT;
        }
        break;

    case ESC_INTERVENTION_LIGHT:
        // Small yaw error: gentle brake intervention
        ESC_Controller_t ctrl = {.kp_yaw = 5000.0f, .ki_yaw = 1000.0f};
        float yaw_moment = ESC_YawController(&ctrl, yaw_ref, yaw_actual, DT);

        BrakeForces_t brakes;
        ESC_CalculateBrakeForces(&ctrl, yaw_moment, &brakes, Vehicle_Speed);

        // Apply brakes
        ABS_ApplyBrake(FL, brakes.FL_brake_force);
        ABS_ApplyBrake(FR, brakes.FR_brake_force);
        ABS_ApplyBrake(RL, brakes.RL_brake_force);
        ABS_ApplyBrake(RR, brakes.RR_brake_force);

        // Escalate if error grows
        if (yaw_error > 0.15f || fabs(beta) > 0.15f) {
            level = ESC_INTERVENTION_HEAVY;
        } else if (yaw_error < 0.03f) {
            level = ESC_MONITORING;
        }
        break;

    case ESC_INTERVENTION_HEAVY:
        // Large yaw error: aggressive brake + torque reduction
        ctrl.kp_yaw = 8000.0f;
        ctrl.ki_yaw = 2000.0f;
        yaw_moment = ESC_YawController(&ctrl, yaw_ref, yaw_actual, DT);

        ESC_CalculateBrakeForces(&ctrl, yaw_moment, &brakes, Vehicle_Speed);

        // Request engine torque reduction (30-50%)
        CAN_Send_TorqueReduction(50.0f);

        // Activate ESC warning lamp (flashing)
        HMI_SetESC_Lamp(LAMP_FLASHING);

        // Escalate to panic if critical
        if (fabs(lateral_accel) > 0.9f * GRAVITY || fabs(beta) > 0.22f) {
            level = ESC_PANIC_MODE;
        } else if (yaw_error < 0.08f) {
            level = ESC_INTERVENTION_LIGHT;
        }
        break;

    case ESC_PANIC_MODE:
        // Critical instability: maximum intervention
        ctrl.state = ESC_CRITICAL;
        ESC_CalculateBrakeForces(&ctrl, yaw_moment, &brakes, Vehicle_Speed);

        // Full torque cut
        CAN_Send_TorqueReduction(100.0f);

        // ESC lamp solid on
        HMI_SetESC_Lamp(LAMP_ON);

        // Return to monitoring after stabilization
        if (yaw_error < 0.05f && Vehicle_Speed < 10.0f) {
            level = ESC_MONITORING;
            HMI_SetESC_Lamp(LAMP_OFF);
        }
        break;
    }
}
```

## AUTOSAR Integration

```c
// AUTOSAR Runnable for ESC main control (10ms cyclic, high priority)
FUNC(void, ESC_CODE) ESC_MainFunction(void) {
    // Read sensors via AUTOSAR RTE
    Rte_Read_IMU_YawRate(&yaw_rate_actual);
    Rte_Read_IMU_LateralAccel(&lateral_accel);
    Rte_Read_IMU_LongitudinalAccel(&longitudinal_accel);
    Rte_Read_SensorCluster_SteeringAngle(&steering_angle);
    Rte_Read_SensorCluster_VehicleSpeed(&vehicle_speed);
    Rte_Read_WheelSpeedSensors_FL(&wheel_speed_fl);
    Rte_Read_WheelSpeedSensors_FR(&wheel_speed_fr);
    Rte_Read_WheelSpeedSensors_RL(&wheel_speed_rl);
    Rte_Read_WheelSpeedSensors_RR(&wheel_speed_rr);

    // Calculate reference yaw rate (ideal response)
    VehicleModel_t model = {
        .steering_angle_deg = steering_angle,
        .vehicle_speed_mps = vehicle_speed / 3.6f,
        .wheelbase_m = 2.7f,
        .understeer_gradient = 0.003f
    };
    float yaw_ref = ESC_CalculateReferenceYawRate(&model);

    // Estimate sideslip angle
    SlipAngleEstimator_t slip_est = {
        .yaw_rate = yaw_rate_actual,
        .lat_accel = lateral_accel,
        .longitudinal_vel = model.vehicle_speed_mps,
        .beta_estimate = beta_previous
    };
    ESC_EstimateSideslipAngle(&slip_est, 0.01f);

    // Yaw stability control
    ESC_Controller_t esc_ctrl = {.kp_yaw = 5000.0f, .ki_yaw = 1000.0f};
    float yaw_moment = ESC_YawController(&esc_ctrl, yaw_ref, yaw_rate_actual, 0.01f);

    // Calculate brake forces
    BrakeForces_t brake_forces;
    ESC_CalculateBrakeForces(&esc_ctrl, yaw_moment, &brake_forces, vehicle_speed);

    // Traction control
    float wheel_speeds[4] = {wheel_speed_fl, wheel_speed_fr, wheel_speed_rl, wheel_speed_rr};
    TCS_Controller_t tcs_ctrl = {.target_slip_ratio = 0.12f, .kp_tcs = 50.0f, .ki_tcs = 10.0f};
    TCS_Control(&tcs_ctrl, wheel_speeds, vehicle_speed, 0.01f);

    // Write outputs via AUTOSAR RTE
    Rte_Write_BrakeActuator_FL_Force(brake_forces.FL_brake_force);
    Rte_Write_BrakeActuator_FR_Force(brake_forces.FR_brake_force);
    Rte_Write_BrakeActuator_RL_Force(brake_forces.RL_brake_force);
    Rte_Write_BrakeActuator_RR_Force(brake_forces.RR_brake_force);
    Rte_Write_CAN_ESC_Active(esc_ctrl.state != ESC_STABLE);
    Rte_Write_CAN_TCS_Active(tcs_active);
}
```

## HIL Test Scenarios

### Test Case 1: Sine-with-Dwell Stability Test (FMVSS 126)
```yaml
test_id: ESC_001_SINE_DWELL
objective: Validate ESC performance per FMVSS 126 standard
preconditions:
  - Vehicle speed: 80 kph (50 mph)
  - Road surface: Dry asphalt (μ = 0.9)
  - Tire pressure: Nominal

test_steps:
  1. Apply sinusoidal steering input (0.7 Hz, ±270° amplitude)
  2. Dwell at maximum steering for 0.5 seconds
  3. Monitor yaw rate response
  4. Measure lateral displacement

pass_criteria:
  - Yaw rate overshoot: <35% of steady-state value
  - Vehicle remains stable (no spin-out)
  - Lateral displacement: <1.83 meters from lane center
  - ESC intervention time: <100ms from instability detection
```

### Test Case 2: Split-μ Braking
```yaml
test_id: ESC_002_SPLIT_MU_BRAKING
objective: Validate directional stability during braking on split friction surface
preconditions:
  - Vehicle speed: 100 kph
  - Left wheels on dry asphalt (μ = 0.9)
  - Right wheels on ice (μ = 0.2)

test_steps:
  1. Apply full brake pressure (ABS active)
  2. Monitor yaw rate and lateral deviation
  3. ESC should counter yaw moment from asymmetric braking

pass_criteria:
  - Yaw rate: <5 deg/s deviation from straight line
  - Lateral deviation: <1 meter over 50 meter braking distance
  - Vehicle remains in lane without driver steering correction
```

### Test Case 3: Traction Control on Loose Gravel
```yaml
test_id: ESC_003_TCS_GRAVEL
objective: Validate TCS prevents wheel spin on low-friction surface
preconditions:
  - Vehicle stationary on gravel (μ = 0.4)
  - Rear-wheel drive configuration

test_steps:
  1. Driver applies 100% throttle
  2. Monitor rear wheel speeds vs vehicle speed
  3. TCS should limit slip to 10-15%

pass_criteria:
  - Slip ratio: 10-15% maintained
  - 0-30 kph acceleration time: <6 seconds
  - No sustained wheel spin (>30% slip)
  - Engine torque reduction active during intervention
```

## ISO 26262 Safety Concept

### ASIL Decomposition for ESC

| Function | ASIL | Decomposition | Rationale |
|----------|------|---------------|-----------|
| Yaw rate sensing | ASIL-D | ASIL-C(C) + ASIL-B(B) | Dual IMU sensors with plausibility check |
| Brake intervention | ASIL-D | ASIL-C(C) + ASIL-B(B) | ESC ECU + ABS ECU redundancy |
| Stability control | ASIL-D | No decomposition | Single ESC ECU with internal diagnostics |
| TCS | ASIL-B | N/A | Lower safety criticality than ESC |

### Safety Mechanisms

1. **Sensor Plausibility**: Cross-check yaw rate gyro vs lateral accelerometer (kinematic consistency)
2. **Actuator Monitoring**: Pressure sensors verify commanded vs actual brake force
3. **Fail-Operational**: ESC degrades to ABS-only mode if yaw sensor fails
4. **Manual Override**: Driver can disable ESC (warning lamp), but TCS remains active
5. **Self-Test**: Power-on diagnostics, periodic runtime checks (watchdog, CRC)

## CAN Signal Definitions (DBC)

```dbc
BO_ 270 ESC_Status: 8 ESC
 SG_ ESC_Active : 0|1@1+ (1,0) [0|1] "" PCM,TCM,HMI
 SG_ TCS_Active : 1|1@1+ (1,0) [0|1] "" PCM,HMI
 SG_ HHA_Active : 2|1@1+ (1,0) [0|1] "" HMI
 SG_ YawRate : 8|16@1- (0.01,-327.68) [-327.68|327.67] "deg/s" ADAS,HMI
 SG_ LateralAccel : 24|16@1- (0.001,-32.768) [-32.768|32.767] "m/s2" ADAS,HMI
 SG_ SideslipAngle : 40|16@1- (0.001,-32.768) [-32.768|32.767] "rad" ADAS

BO_ 271 ESC_BrakeRequest: 8 ESC
 SG_ BrakeForce_FL : 0|16@1+ (1,0) [0|65535] "N" ABS
 SG_ BrakeForce_FR : 16|16@1+ (1,0) [0|65535] "N" ABS
 SG_ BrakeForce_RL : 32|16@1+ (1,0) [0|65535] "N" ABS
 SG_ BrakeForce_RR : 48|16@1+ (1,0) [0|65535] "N" ABS
```

## Tools and Calibration

- **IPG CarMaker**: Vehicle dynamics simulation, ESC algorithm validation
- **MATLAB/Simulink**: Model-based development, Kalman filter design
- **dSPACE ASM**: Vehicle dynamics testbed, ESC HIL testing
- **VI-grade**: Driving simulator for ESC tuning
- **Vector CANoe**: ESC CAN message verification

## References
- ISO 26262 (Functional Safety)
- FMVSS 126 (ESC regulation)
- UN ECE R13-H (ESC requirements)
- SAE J2564 (ESC test procedures)

---

## Suspension Control

# Active Suspension Control Skill

## Overview
Expert skill in active and semi-active suspension systems. Covers adaptive damping, air suspension control, ride height adjustment, active roll/pitch control, road preview systems, and comfort/sport mode tuning.

## Core Competencies

### 1. Adaptive Damping (Semi-Active)
- **Magnetorheological (MR) Dampers**: Variable damping via magnetic field
- **Continuously Variable Damping (CVD)**: Adjustable orifice valves
- **Skyhook Control**: Minimize body motion by damping to virtual sky reference
- **Mode Selection**: Comfort (soft), Normal, Sport (stiff)

### 2. Air Suspension Control
- **Ride Height Adjustment**: Lower at highway speed, raise for off-road
- **Load Leveling**: Maintain constant height regardless of passenger/cargo load
- **Compressor Management**: On-demand air supply, pressure reservoir
- **Leak Detection**: Monitor air loss, warn driver

### 3. Active Roll/Pitch Control
- **Anti-Roll Bars**: Active stabilizers with electric/hydraulic actuators
- **Roll Angle Limitation**: <3° body roll in 0.8g lateral acceleration
- **Pitch Suppression**: Reduce dive/squat during braking/acceleration
- **Actuator Bandwidth**: 10-20 Hz for responsive control

### 4. Road Preview (Camera/Lidar)
- **Surface Detection**: Identify potholes, speed bumps ahead
- **Predictive Damping**: Pre-adjust suspension before impact
- **Preview Distance**: 10-30 meters at highway speed
- **Vertical Velocity Compensation**: Minimize wheel displacement

### 5. Comfort vs Sport Tuning
- **Comfort**: Soft damping, maximize isolation, minimize body acceleration
- **Sport**: Stiff damping, minimize body roll, maximize grip
- **Adaptive**: Dynamic tuning based on road surface, driver input

## Control Algorithms

### Skyhook Damping Control
```c
// Minimize body motion by damping to virtual inertial reference
typedef struct {
    float body_velocity;       // Vertical velocity of sprung mass (m/s)
    float wheel_velocity;      // Vertical velocity of unsprung mass (m/s)
    float damping_coeff_max;   // Maximum damping (N·s/m)
    float damping_coeff_min;   // Minimum damping (N·s/m)
} Skyhook_Controller_t;

float Skyhook_CalculateDamping(Skyhook_Controller_t *sky) {
    // Relative velocity (suspension deflection rate)
    float rel_velocity = sky->body_velocity - sky->wheel_velocity;

    // Skyhook control law
    // If body moving up and suspension compressing: high damping
    // If body moving down and suspension extending: high damping
    // Otherwise: low damping (for ride comfort)

    float damping_force;

    if ((sky->body_velocity * rel_velocity) > 0) {
        // Body and relative velocity same sign: high damping
        damping_force = sky->damping_coeff_max * sky->body_velocity;
    } else {
        // Opposite signs: minimal damping
        damping_force = sky->damping_coeff_min * rel_velocity;
    }

    return damping_force;
}

// Convert damping force to MR damper current
float MR_Damper_Current(float damping_force_target) {
    // Magnetorheological damper: current controls viscosity
    // Typical: 0-2A for damping range 500-3000 N·s/m

    float current = (damping_force_target - 500.0f) / 1250.0f;  // N·s/m → A
    return CLAMP(current, 0.0f, 2.0f);
}
```

### Air Suspension Load Leveling
```c
typedef struct {
    float target_height_mm;
    float current_height_mm;
    float load_mass_kg;
    float air_pressure_bar[4];  // Per corner
} AirSuspension_t;

void AirSuspension_LoadLeveling(AirSuspension_t *air, float dt) {
    // Measure current ride height
    air->current_height_mm = Ultrasonic_ReadHeight();

    // Estimate load from suspension deflection
    float height_error = air->target_height_mm - air->current_height_mm;

    // PI controller for height
    static float height_integral = 0.0f;
    height_integral += height_error * dt;
    height_integral = CLAMP(height_integral, -50.0f, 50.0f);

    float pressure_adjust = (KP_HEIGHT * height_error) + (KI_HEIGHT * height_integral);

    // Distribute pressure to all four corners (equal distribution)
    for (int i = 0; i < 4; i++) {
        air->air_pressure_bar[i] += pressure_adjust;
        air->air_pressure_bar[i] = CLAMP(air->air_pressure_bar[i], 3.0f, 12.0f);

        // Command air valves
        if (air->air_pressure_bar[i] > Sensor_ReadPressure(i)) {
            AirValve_Inflate(i);
        } else {
            AirValve_Deflate(i);
        }
    }

    // Activate compressor if reservoir low
    if (Reservoir_Pressure < 10.0f) {
        Compressor_Enable();
    }
}

// Speed-dependent ride height
float AirSuspension_SpeedDependentHeight(float vehicle_speed_kph) {
    // Lower vehicle at high speed for aerodynamics and stability
    if (vehicle_speed_kph > 120.0f) {
        return TARGET_HEIGHT_SPORT;  // -20mm
    } else if (vehicle_speed_kph > 80.0f) {
        return TARGET_HEIGHT_NORMAL; // 0mm
    } else {
        return TARGET_HEIGHT_COMFORT; // +10mm
    }
}
```

### Active Anti-Roll Control
```c
// Electric/hydraulic active stabilizer bars
typedef struct {
    float lateral_accel;
    float roll_angle_deg;
    float target_roll_angle_deg;
    float actuator_torque_nm[2];  // Front and rear
} ActiveRoll_Controller_t;

void ActiveRoll_Control(ActiveRoll_Controller_t *roll, float dt) {
    // Target roll angle based on lateral acceleration
    // Allow some roll for driver feedback, but limit excessive lean
    roll->target_roll_angle_deg = roll->lateral_accel / GRAVITY * 1.5f;  // degrees
    roll->target_roll_angle_deg = CLAMP(roll->target_roll_angle_deg, -3.0f, 3.0f);

    // PID controller for roll angle
    float roll_error = roll->target_roll_angle_deg - roll->roll_angle_deg;

    static float roll_integral = 0.0f, roll_prev_error = 0.0f;
    roll_integral += roll_error * dt;
    float roll_derivative = (roll_error - roll_prev_error) / dt;
    roll_prev_error = roll_error;

    float roll_torque = (KP_ROLL * roll_error) + (KI_ROLL * roll_integral) + (KD_ROLL * roll_derivative);

    // Distribute torque front/rear (60/40 split typical)
    roll->actuator_torque_nm[FRONT] = roll_torque * 0.60f;
    roll->actuator_torque_nm[REAR] = roll_torque * 0.40f;

    // Command actuators
    ActiveStabilizer_SetTorque(FRONT, roll->actuator_torque_nm[FRONT]);
    ActiveStabilizer_SetTorque(REAR, roll->actuator_torque_nm[REAR]);
}
```

### Road Preview with Camera
```c
typedef struct {
    float preview_distance_m;
    float obstacle_height_mm;
    float time_to_impact_s;
    bool pothole_detected;
} RoadPreview_t;

void RoadPreview_PredictiveDamping(RoadPreview_t *preview, float vehicle_speed) {
    // Camera/lidar detects road surface ahead
    preview->pothole_detected = Camera_DetectPothole(&preview->obstacle_height_mm);

    if (preview->pothole_detected) {
        preview->time_to_impact_s = preview->preview_distance_m / vehicle_speed;

        // Pre-adjust damping before impact
        if (preview->time_to_impact_s < 1.0f) {
            // Soften damping to absorb impact
            for (int wheel = 0; wheel < 4; wheel++) {
                MR_Damper_SetCurrent(wheel, DAMPING_SOFT);
            }

            // After impact (100ms delay), return to normal
            static float post_impact_timer = 0.0f;
            post_impact_timer += DT;

            if (post_impact_timer > 0.1f) {
                for (int wheel = 0; wheel < 4; wheel++) {
                    MR_Damper_SetCurrent(wheel, DAMPING_NORMAL);
                }
                post_impact_timer = 0.0f;
                preview->pothole_detected = false;
            }
        }
    }
}
```

## Mode Selection State Machine

```c
typedef enum {
    SUSP_MODE_COMFORT,
    SUSP_MODE_NORMAL,
    SUSP_MODE_SPORT,
    SUSP_MODE_OFFROAD
} SuspensionMode_t;

void Suspension_ModeSelection(SuspensionMode_t mode) {
    switch (mode) {
    case SUSP_MODE_COMFORT:
        // Soft damping, high ride height, minimal body control
        MR_Damper_SetCoefficient(1000.0f);   // N·s/m (soft)
        AirSuspension_SetHeight(TARGET_HEIGHT_COMFORT);
        ActiveRoll_SetGain(0.5f);  // Allow some roll
        break;

    case SUSP_MODE_NORMAL:
        // Balanced damping, standard height
        MR_Damper_SetCoefficient(2000.0f);   // N·s/m (medium)
        AirSuspension_SetHeight(TARGET_HEIGHT_NORMAL);
        ActiveRoll_SetGain(1.0f);
        break;

    case SUSP_MODE_SPORT:
        // Stiff damping, low height, maximum body control
        MR_Damper_SetCoefficient(3000.0f);   // N·s/m (stiff)
        AirSuspension_SetHeight(TARGET_HEIGHT_SPORT);
        ActiveRoll_SetGain(1.5f);  // Minimize roll aggressively
        break;

    case SUSP_MODE_OFFROAD:
        // Soft damping, maximum height, long travel
        MR_Damper_SetCoefficient(800.0f);    // N·s/m (very soft)
        AirSuspension_SetHeight(TARGET_HEIGHT_OFFROAD);  // +40mm
        ActiveRoll_Disable();  // Allow articulation
        break;
    }
}
```

## AUTOSAR Integration

```c
FUNC(void, SUSP_CODE) Suspension_MainFunction(void) {
    // Read sensors (100Hz task)
    Rte_Read_IMU_RollAngle(&roll_angle);
    Rte_Read_IMU_PitchAngle(&pitch_angle);
    Rte_Read_IMU_VerticalAccel(&vertical_accel);
    Rte_Read_HeightSensors_FL(&height_fl);
    Rte_Read_HMI_SuspensionMode(&mode);

    // Estimate body/wheel velocities
    static float body_pos_prev = 0.0f;
    float body_pos = (height_fl + height_fr + height_rl + height_rr) / 4.0f;
    float body_velocity = (body_pos - body_pos_prev) / DT;
    body_pos_prev = body_pos;

    // Skyhook damping control
    Skyhook_Controller_t sky = {.body_velocity = body_velocity};
    float damping_force = Skyhook_CalculateDamping(&sky);

    // Mode-dependent gain
    switch (mode) {
    case SUSP_MODE_COMFORT: damping_force *= 0.6f; break;
    case SUSP_MODE_SPORT: damping_force *= 1.2f; break;
    }

    // Apply to dampers
    for (int i = 0; i < 4; i++) {
        float current = MR_Damper_Current(damping_force);
        Rte_Write_MR_Damper_Current(i, current);
    }

    // Air suspension load leveling
    AirSuspension_t air;
    air.target_height_mm = AirSuspension_SpeedDependentHeight(vehicle_speed);
    AirSuspension_LoadLeveling(&air, DT);

    // Active roll control
    ActiveRoll_Controller_t roll_ctrl = {.lateral_accel = lateral_accel, .roll_angle_deg = roll_angle};
    ActiveRoll_Control(&roll_ctrl, DT);
}
```

## HIL Test Scenarios

### Test Case 1: Comfort Mode on Rough Road
```yaml
test_id: SUSP_001_COMFORT_ROUGH
objective: Maximize isolation in comfort mode
preconditions:
  - Suspension mode: Comfort
  - Road: Belgian paving (high frequency bumps)
  - Vehicle speed: 60 kph

pass_criteria:
  - Body vertical acceleration: <0.5 g RMS
  - Damping force: 500-1200 N (soft)
  - Passenger comfort rating: >7/10
```

### Test Case 2: Sport Mode Cornering
```yaml
test_id: SUSP_002_SPORT_CORNERING
objective: Minimize body roll in sport mode
preconditions:
  - Suspension mode: Sport
  - Skidpad cornering: 0.9g lateral
  - Vehicle speed: 80 kph

pass_criteria:
  - Body roll angle: <2.5 degrees
  - Active roll actuator torque: 1500-2500 Nm
  - Damping force: 2500-3500 N (stiff)
```

## References
- ISO 26262 (Safety for active systems)
- SAE J2877 (Suspension test procedures)

---

## Tcm Transmission Control

# TCM Transmission Control Module Skill

## Overview
Expert skill in Transmission Control Module (TCM) development for automatic transmissions (AT), dual-clutch transmissions (DCT), and continuously variable transmissions (CVT). Covers gear shift strategy, shift quality optimization, torque converter lockup, adaptive learning, clutch control, and AUTOSAR integration.

## Core Competencies

### 1. Gear Shift Strategy
- **Shift Points**: Upshift/downshift based on throttle position, vehicle speed, driver intent
- **Kickdown**: Forced downshift for overtaking (throttle >80% pressed rapidly)
- **Skip Shifts**: Direct shift (e.g., 3rd→5th) for fuel economy
- **Grade Logic**: Hold lower gear on uphill, prevent hunting on downhill
- **Manual Mode**: Driver-selected gear hold, upshift/downshift on paddle command

### 2. Shift Quality Optimization
- **Shift Time**: Target 200-400ms for smooth shift, <200ms for performance mode
- **Torque Phase**: Reduce engine torque during clutch handover to minimize jerk
- **Inertia Phase**: Synchronize clutch engagement with gear ratio change
- **Fill Time Compensation**: Hydraulic delay compensation for temperature, wear
- **Shift Jerk Metric**: <10 m/s³ for comfort, <15 m/s³ for sport mode

### 3. Torque Converter Lockup (AT)
- **Partial Lockup**: Slip control (50-100 RPM slip) for vibration isolation
- **Full Lockup**: 100% mechanical coupling for efficiency (highway cruise)
- **Unlock Conditions**: Deceleration, gear shift, torque demand change
- **Shudder Mitigation**: Dither control to break stick-slip friction

### 4. Adaptive Shift Learning
- **Clutch Fill Learning**: Adapt hydraulic pressure for consistent shift timing
- **Clutch Wear Compensation**: Increase pressure as friction material wears
- **Driver Style Recognition**: Aggressive (sport shifts) vs economy (smooth shifts)
- **Altitude Adaptation**: Adjust for engine power loss at high altitude

### 5. Dual-Clutch Control (DCT)
- **Odd/Even Clutch Management**: Pre-select next gear before shift
- **Clutch Slip Control**: Modulate pressure for smooth engagement
- **Launch Control**: High-RPM clutch slip for maximum acceleration
- **Creep Mode**: Low-speed clutch modulation for stop-and-go traffic

### 6. CVT Control
- **Ratio Control**: Continuously variable primary/secondary pulley hydraulics
- **Belt Slip Prevention**: Clamp force management to prevent belt slippage
- **Simulated Gears**: Fixed ratio steps for driver feedback (virtual gears)
- **Manual Mode**: Hold fixed ratios mimicking 6-8 speed transmission

## Control Algorithms

### Shift Decision Logic (State Machine)
```c
typedef enum {
    GEAR_PARK,
    GEAR_REVERSE,
    GEAR_NEUTRAL,
    GEAR_DRIVE_1,
    GEAR_DRIVE_2,
    GEAR_DRIVE_3,
    GEAR_DRIVE_4,
    GEAR_DRIVE_5,
    GEAR_DRIVE_6,
    GEAR_MANUAL_MODE
} TransmissionGear_t;

typedef struct {
    float throttle_percent;
    float vehicle_speed_kph;
    float engine_rpm;
    float engine_torque_nm;
    bool kickdown_switch;
    bool manual_mode_active;
    uint8_t manual_gear_request;
} TCM_Input_t;

TransmissionGear_t TCM_ShiftLogic(TCM_Input_t *input, TransmissionGear_t current_gear) {
    // Manual mode: honor driver gear request
    if (input->manual_mode_active) {
        // Prevent over-rev: deny downshift if RPM would exceed limit
        float predicted_rpm = input->vehicle_speed_kph * GearRatio[input->manual_gear_request] * 60.0f / (TIRE_DIAMETER_M * PI * 3.6f);
        if (predicted_rpm > RPM_REDLINE) {
            return current_gear;  // Deny shift
        }
        return input->manual_gear_request;
    }

    // Kickdown: immediate downshift for max acceleration
    if (input->kickdown_switch && current_gear > GEAR_DRIVE_2) {
        return current_gear - 1;  // Drop one gear
    }

    // Lookup shift points from 3D map (Vehicle Speed x Throttle)
    uint8_t upshift_speed = ShiftMap_Upshift[current_gear][input->throttle_percent];
    uint8_t downshift_speed = ShiftMap_Downshift[current_gear][input->throttle_percent];

    // Upshift decision
    if (input->vehicle_speed_kph > upshift_speed && current_gear < GEAR_DRIVE_6) {
        // Check if skip-shift conditions met (light throttle, fuel economy mode)
        if (input->throttle_percent < 30.0f && Eco_Mode_Active) {
            if (current_gear == GEAR_DRIVE_3) {
                return GEAR_DRIVE_5;  // Skip 4th gear
            }
        }
        return current_gear + 1;
    }

    // Downshift decision
    if (input->vehicle_speed_kph < downshift_speed && current_gear > GEAR_DRIVE_1) {
        return current_gear - 1;
    }

    // Hold current gear
    return current_gear;
}
```

### Shift Execution Control
```c
typedef enum {
    SHIFT_IDLE,
    SHIFT_TORQUE_PHASE,
    SHIFT_INERTIA_PHASE,
    SHIFT_COMPLETE
} ShiftPhase_t;

typedef struct {
    uint16_t fill_time_ms;           // Pre-charge hydraulic clutch
    float torque_reduction_percent;  // Engine torque cut during shift
    float oncoming_clutch_pressure;  // Engaging clutch
    float offgoing_clutch_pressure;  // Releasing clutch
} ShiftControl_t;

void TCM_ExecuteShift(uint8_t target_gear, ShiftControl_t *ctrl, float dt) {
    static ShiftPhase_t phase = SHIFT_IDLE;
    static float phase_timer = 0.0f;

    switch (phase) {
    case SHIFT_IDLE:
        // Request torque reduction from ECM
        CAN_Send_TorqueReduction(ctrl->torque_reduction_percent);

        // Pre-fill oncoming clutch (rapid pressure rise, no engagement yet)
        Hydraulic_SetPressure(ONCOMING_CLUTCH, FILL_PRESSURE_BAR);

        phase_timer = ctrl->fill_time_ms / 1000.0f;  // Convert to seconds
        phase = SHIFT_TORQUE_PHASE;
        break;

    case SHIFT_TORQUE_PHASE:
        // Transfer torque from offgoing to oncoming clutch
        phase_timer -= dt;

        // Ramp up oncoming clutch pressure
        ctrl->oncoming_clutch_pressure += (TORQUE_PHASE_PRESSURE_RATE * dt);

        // Ramp down offgoing clutch pressure
        ctrl->offgoing_clutch_pressure -= (TORQUE_PHASE_PRESSURE_RATE * dt);

        Hydraulic_SetPressure(ONCOMING_CLUTCH, ctrl->oncoming_clutch_pressure);
        Hydraulic_SetPressure(OFFGOING_CLUTCH, ctrl->offgoing_clutch_pressure);

        // Torque phase complete when clutch slip speed crosses zero
        if (Clutch_SlipSpeed() < 10.0f) {  // RPM
            phase = SHIFT_INERTIA_PHASE;
        }
        break;

    case SHIFT_INERTIA_PHASE:
        // Synchronize transmission shaft speed to new gear ratio
        float target_shaft_speed = Input_Speed * GearRatio[target_gear];
        float actual_shaft_speed = Output_Speed;

        // PI controller for smooth synchronization
        static float inertia_integral = 0.0f;
        float speed_error = target_shaft_speed - actual_shaft_speed;
        inertia_integral += speed_error * KI_INERTIA * dt;

        float pressure_adjust = (KP_INERTIA * speed_error) + inertia_integral;
        ctrl->oncoming_clutch_pressure += pressure_adjust;

        Hydraulic_SetPressure(ONCOMING_CLUTCH, ctrl->oncoming_clutch_pressure);

        // Inertia phase complete when speed error <5 RPM
        if (fabs(speed_error) < 5.0f) {
            phase = SHIFT_COMPLETE;
        }
        break;

    case SHIFT_COMPLETE:
        // Full lockup of oncoming clutch
        Hydraulic_SetPressure(ONCOMING_CLUTCH, MAX_LINE_PRESSURE);
        Hydraulic_SetPressure(OFFGOING_CLUTCH, 0.0f);

        // Restore full engine torque
        CAN_Send_TorqueReduction(0.0f);

        // Update adaptive shift learning
        Adaptive_UpdateShiftQuality(target_gear, phase_timer);

        // Reset to idle
        phase = SHIFT_IDLE;
        break;
    }
}
```

### Torque Converter Lockup Control
```c
typedef enum {
    TC_UNLOCKED,
    TC_PARTIAL_LOCKUP,
    TC_FULL_LOCKUP
} TorqueConverter_State_t;

TorqueConverter_State_t TCM_TorqueConverterControl(float vehicle_speed_kph, float throttle_percent,
                                                     TransmissionGear_t gear, float coolant_temp) {
    // No lockup in 1st gear or during warmup
    if (gear == GEAR_DRIVE_1 || coolant_temp < 50.0f) {
        return TC_UNLOCKED;
    }

    // Unlock during heavy acceleration (torque multiplication benefit)
    if (throttle_percent > 70.0f) {
        return TC_UNLOCKED;
    }

    // Full lockup at highway cruise (>60 kph, light throttle)
    if (vehicle_speed_kph > 60.0f && throttle_percent < 40.0f) {
        return TC_FULL_LOCKUP;
    }

    // Partial lockup for efficiency while maintaining comfort
    if (vehicle_speed_kph > 30.0f && gear >= GEAR_DRIVE_2) {
        return TC_PARTIAL_LOCKUP;
    }

    return TC_UNLOCKED;
}

// Slip control for partial lockup (target 50 RPM slip)
void TCM_TorqueConverterSlipControl(float target_slip_rpm, float dt) {
    float engine_rpm = CAN_Read_EngineRPM();
    float turbine_rpm = Sensor_Read_TurbineSpeed();
    float actual_slip_rpm = engine_rpm - turbine_rpm;

    // PI controller
    static float slip_integral = 0.0f;
    float slip_error = target_slip_rpm - actual_slip_rpm;
    slip_integral += slip_error * KI_SLIP * dt;
    slip_integral = CLAMP(slip_integral, -5.0f, 5.0f);

    float clutch_pressure = LOCKUP_BASE_PRESSURE + (KP_SLIP * slip_error) + slip_integral;
    clutch_pressure = CLAMP(clutch_pressure, 2.0f, 15.0f);  // bar

    Hydraulic_SetPressure(TC_LOCKUP_CLUTCH, clutch_pressure);

    // Shudder mitigation: dither pressure ±0.5 bar at 10 Hz
    if (Shudder_Detected()) {
        float dither = 0.5f * sin(2.0f * PI * 10.0f * System_Time);
        Hydraulic_SetPressure(TC_LOCKUP_CLUTCH, clutch_pressure + dither);
    }
}
```

### Adaptive Shift Learning
```c
typedef struct {
    float fill_time_learned_ms[6];      // Learned fill time per gear
    float pressure_offset_bar[6];       // Clutch pressure offset per gear
    uint16_t shift_count[6];            // Number of shifts per gear
    float avg_shift_quality[6];         // Running average shift jerk
} AdaptiveData_t;

void Adaptive_UpdateShiftQuality(uint8_t gear, float shift_duration_s) {
    static AdaptiveData_t adapt = {0};

    // Measure shift jerk (longitudinal acceleration derivative)
    float accel_before = IMU_Read_LongitudinalAccel();
    Delay_ms(100);
    float accel_after = IMU_Read_LongitudinalAccel();
    float shift_jerk = fabs(accel_after - accel_before) / 0.1f;  // m/s³

    // Update running average
    adapt.avg_shift_quality[gear] = (adapt.avg_shift_quality[gear] * adapt.shift_count[gear] + shift_jerk) / (adapt.shift_count[gear] + 1);
    adapt.shift_count[gear]++;

    // If shift quality poor (jerk > 12 m/s³), adjust parameters
    if (shift_jerk > 12.0f) {
        // Too harsh: shift was too fast, increase fill time or reduce pressure
        if (shift_duration_s < 0.3f) {
            adapt.fill_time_learned_ms[gear] += 5;  // Add 5ms fill time
        } else {
            adapt.pressure_offset_bar[gear] -= 0.5f;  // Reduce pressure
        }
    } else if (shift_jerk < 5.0f && shift_duration_s > 0.5f) {
        // Too slow: shift was sluggish, decrease fill time or increase pressure
        adapt.fill_time_learned_ms[gear] -= 3;
        adapt.pressure_offset_bar[gear] += 0.3f;
    }

    // Clamp adaptive values to reasonable limits
    adapt.fill_time_learned_ms[gear] = CLAMP(adapt.fill_time_learned_ms[gear], 50, 300);
    adapt.pressure_offset_bar[gear] = CLAMP(adapt.pressure_offset_bar[gear], -3.0f, 3.0f);

    // Save to EEPROM every 50 shifts
    if (adapt.shift_count[gear] % 50 == 0) {
        EEPROM_Write_AdaptiveData(&adapt);
    }
}
```

### DCT Launch Control
```c
// Dual-Clutch Transmission launch control for max acceleration
typedef struct {
    float target_rpm;         // Launch RPM (e.g., 4000 RPM)
    float clutch_slip_rate;   // Target slip rate for smooth engagement
    bool launch_active;
} LaunchControl_t;

void DCT_LaunchControl(LaunchControl_t *launch, float brake_pedal, float throttle_pedal) {
    // Activation: brake + throttle pressed, vehicle stopped
    if (brake_pedal > 90.0f && throttle_pedal > 90.0f && Vehicle_Speed < 2.0f) {
        launch->launch_active = true;

        // Hold engine RPM at target by modulating clutch 1 (odd gears, 1st gear)
        float engine_rpm = CAN_Read_EngineRPM();
        float rpm_error = launch->target_rpm - engine_rpm;

        // PD controller for clutch pressure
        static float prev_error = 0.0f;
        float derivative = (rpm_error - prev_error) / DT;
        prev_error = rpm_error;

        float clutch_pressure = LAUNCH_BASE_PRESSURE + (KP_LAUNCH * rpm_error) + (KD_LAUNCH * derivative);
        clutch_pressure = CLAMP(clutch_pressure, 5.0f, 20.0f);

        Hydraulic_SetPressure(DCT_CLUTCH_1, clutch_pressure);

        // Pre-select 1st gear
        DCT_SelectGear(GEAR_DRIVE_1);
    }

    // Launch: brake released, control clutch slip rate
    if (launch->launch_active && brake_pedal < 10.0f) {
        float wheel_speed = Sensor_Read_WheelSpeed();
        float engine_speed = CAN_Read_EngineRPM() / GearRatio[GEAR_DRIVE_1];
        float slip_speed = engine_speed - wheel_speed;

        // Target slip decreases over time (500 RPM → 0 over 1 second)
        static float launch_timer = 0.0f;
        launch_timer += DT;
        float target_slip = 500.0f * (1.0f - launch_timer);

        if (target_slip < 0.0f) {
            target_slip = 0.0f;
            launch->launch_active = false;  // Launch complete
            launch_timer = 0.0f;
        }

        // Control clutch to achieve target slip
        float slip_error = target_slip - slip_speed;
        static float slip_integral = 0.0f;
        slip_integral += slip_error * KI_LAUNCH_SLIP * DT;

        float clutch_pressure = LAUNCH_BASE_PRESSURE + (KP_LAUNCH_SLIP * slip_error) + slip_integral;
        Hydraulic_SetPressure(DCT_CLUTCH_1, clutch_pressure);

        // Pre-select 2nd gear on even clutch for seamless 1→2 shift
        if (engine_rpm > 5000 || vehicle_speed > 30.0f) {
            DCT_SelectGear_Clutch2(GEAR_DRIVE_2);
        }
    }
}
```

## Calibration Tables

### Upshift Map (Vehicle Speed x Throttle)
```c
// Upshift speeds in kph (rows = current gear, cols = throttle %)
const uint8_t ShiftMap_Upshift[6][11] = {
    // Throttle:   0%  10%  20%  30%  40%  50%  60%  70%  80%  90% 100%
    /* 1st→2nd */ {15,  20,  25,  30,  35,  40,  45,  50,  55,  60,  65},
    /* 2nd→3rd */ {30,  35,  40,  45,  50,  55,  60,  65,  70,  75,  85},
    /* 3rd→4th */ {50,  55,  60,  65,  70,  75,  80,  85,  95, 105, 120},
    /* 4th→5th */ {70,  75,  80,  85,  90,  95, 100, 110, 120, 135, 150},
    /* 5th→6th */ {90, 100, 110, 115, 120, 125, 130, 140, 155, 170, 190},
    /* 6th      */ { 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0}  // No upshift from 6th
};

// Downshift speeds in kph
const uint8_t ShiftMap_Downshift[6][11] = {
    // Throttle:   0%  10%  20%  30%  40%  50%  60%  70%  80%  90% 100%
    /* 1st      */ { 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0},  // No downshift from 1st
    /* 2nd→1st */ {10,  12,  15,  18,  20,  22,  25,  28,  30,  32,  35},
    /* 3rd→2nd */ {25,  28,  32,  36,  40,  42,  45,  48,  50,  55,  60},
    /* 4th→3rd */ {45,  48,  52,  56,  60,  63,  66,  70,  75,  80,  90},
    /* 5th→4th */ {65,  68,  72,  76,  80,  83,  86,  92,  98, 105, 115},
    /* 6th→5th */ {85,  90,  95, 100, 105, 108, 112, 118, 125, 135, 145}
};
```

### Clutch Fill Time Map (Temperature Compensation)
```c
// Fill time in milliseconds (rows = gear, cols = ATF temp °C)
const uint16_t FillTimeMap[6][7] = {
    // ATF Temp:  -10°C  0°C  20°C  40°C  60°C  80°C  100°C
    /* 1st gear */ {250, 220, 180, 150, 130, 120, 110},
    /* 2nd gear */ {240, 210, 175, 145, 125, 115, 105},
    /* 3rd gear */ {230, 200, 170, 140, 120, 110, 100},
    /* 4th gear */ {225, 195, 165, 135, 118, 108,  98},
    /* 5th gear */ {220, 190, 160, 132, 115, 105,  95},
    /* 6th gear */ {215, 185, 158, 130, 112, 102,  93}
};
```

## State Machine: Transmission Mode Selection

```c
typedef enum {
    TRANS_MODE_PARK,
    TRANS_MODE_REVERSE,
    TRANS_MODE_NEUTRAL,
    TRANS_MODE_DRIVE_ECO,
    TRANS_MODE_DRIVE_NORMAL,
    TRANS_MODE_DRIVE_SPORT,
    TRANS_MODE_MANUAL
} TransmissionMode_t;

void TCM_ModeStateMachine(void) {
    static TransmissionMode_t mode = TRANS_MODE_PARK;

    // Gear selector input
    GearSelector_t selector = Read_GearSelector();

    switch (mode) {
    case TRANS_MODE_PARK:
        // Lock output shaft mechanically
        Engage_ParkingPawl();
        Allow_EngineStart = true;

        if (selector == SEL_REVERSE && Brake_Pressed()) {
            mode = TRANS_MODE_REVERSE;
        } else if (selector == SEL_NEUTRAL) {
            mode = TRANS_MODE_NEUTRAL;
        }
        break;

    case TRANS_MODE_REVERSE:
        Disengage_ParkingPawl();
        Engage_ReverseGear();
        Allow_EngineStart = false;

        if (selector == SEL_PARK && Vehicle_Speed < 2.0f) {
            mode = TRANS_MODE_PARK;
        }
        break;

    case TRANS_MODE_NEUTRAL:
        Disengage_AllGears();
        Allow_EngineStart = true;

        if (selector == SEL_DRIVE) {
            // Select drive mode based on driver preference
            if (EcoMode_Button_Pressed) {
                mode = TRANS_MODE_DRIVE_ECO;
            } else if (SportMode_Button_Pressed) {
                mode = TRANS_MODE_DRIVE_SPORT;
            } else {
                mode = TRANS_MODE_DRIVE_NORMAL;
            }
        }
        break;

    case TRANS_MODE_DRIVE_ECO:
        // Early upshifts, torque converter lockup, skip shifts
        Shift_Aggressiveness = 0.3f;
        Torque_Converter_Lockup_Threshold = 30.0f;  // kph
        Enable_SkipShifts = true;

        if (SportMode_Button_Pressed) {
            mode = TRANS_MODE_DRIVE_SPORT;
        }
        break;

    case TRANS_MODE_DRIVE_SPORT:
        // Late upshifts, hold gears longer, no lockup in low gears
        Shift_Aggressiveness = 0.8f;
        Torque_Converter_Lockup_Threshold = 60.0f;
        Enable_SkipShifts = false;

        if (EcoMode_Button_Pressed) {
            mode = TRANS_MODE_DRIVE_ECO;
        } else if (Manual_Paddle_Shift) {
            mode = TRANS_MODE_MANUAL;
        }
        break;

    case TRANS_MODE_MANUAL:
        // Driver controls shifts via paddle shifters
        Disable_AutomaticShifts();

        if (Upshift_Paddle_Pressed && Current_Gear < GEAR_DRIVE_6) {
            Request_Shift(Current_Gear + 1);
        } else if (Downshift_Paddle_Pressed && Current_Gear > GEAR_DRIVE_1) {
            Request_Shift(Current_Gear - 1);
        }

        // Timeout after 10 seconds with no paddle input → return to auto
        if (Paddle_Idle_Time > 10.0f) {
            mode = TRANS_MODE_DRIVE_NORMAL;
        }
        break;
    }
}
```

## AUTOSAR Integration

```c
// AUTOSAR Runnable for TCM main control (20ms cyclic)
FUNC(void, TCM_CODE) TCM_MainFunction(void) {
    // Read inputs via AUTOSAR RTE
    Rte_Read_SensorCluster_VehicleSpeed(&vehicle_speed_kph);
    Rte_Read_SensorCluster_ThrottlePosition(&throttle_percent);
    Rte_Read_SensorCluster_BrakePedal(&brake_pedal);
    Rte_Read_CAN_EngineSpeed(&engine_rpm);
    Rte_Read_CAN_EngineTorque(&engine_torque_nm);
    Rte_Read_SensorCluster_InputShaftSpeed(&input_shaft_rpm);
    Rte_Read_SensorCluster_OutputShaftSpeed(&output_shaft_rpm);
    Rte_Read_SensorCluster_ATF_Temperature(&atf_temp);
    Rte_Read_HMI_GearSelector(&gear_selector);
    Rte_Read_HMI_DriveMode(&drive_mode);

    // Shift decision logic
    TCM_Input_t input = {
        .throttle_percent = throttle_percent,
        .vehicle_speed_kph = vehicle_speed_kph,
        .engine_rpm = engine_rpm,
        .engine_torque_nm = engine_torque_nm,
        .kickdown_switch = (throttle_percent > 85.0f),
        .manual_mode_active = (drive_mode == DRIVE_MODE_MANUAL)
    };

    TransmissionGear_t target_gear = TCM_ShiftLogic(&input, current_gear);

    // Execute shift if target gear differs
    if (target_gear != current_gear) {
        ShiftControl_t shift_ctrl = {
            .fill_time_ms = FillTimeMap[target_gear][ATF_TempIndex(atf_temp)],
            .torque_reduction_percent = 30.0f
        };
        TCM_ExecuteShift(target_gear, &shift_ctrl, 0.02f);
    }

    // Torque converter lockup control
    TorqueConverter_State_t tc_state = TCM_TorqueConverterControl(vehicle_speed_kph, throttle_percent, current_gear, atf_temp);

    // Write outputs via AUTOSAR RTE
    Rte_Write_ActuatorCluster_CurrentGear(current_gear);
    Rte_Write_ActuatorCluster_TorqueConverterState(tc_state);
    Rte_Write_CAN_TorqueReductionRequest(shift_in_progress ? 30.0f : 0.0f);
}
```

## HIL Test Scenarios

### Test Case 1: Upshift Quality (2nd→3rd)
```yaml
test_id: TCM_001_UPSHIFT_QUALITY
objective: Validate shift smoothness and duration
preconditions:
  - ATF temperature: 80°C
  - Current gear: 2nd
  - Vehicle speed: 55 kph
  - Throttle: 40%

test_steps:
  1. Trigger upshift condition (speed exceeds upshift threshold)
  2. Monitor longitudinal acceleration during shift
  3. Measure shift duration (torque phase + inertia phase)
  4. Calculate shift jerk (derivative of acceleration)

pass_criteria:
  - Shift duration: 250-400 ms
  - Peak jerk: <10 m/s³
  - No audible clunk or harshness
  - Output shaft speed synchronized within 5 RPM
```

### Test Case 2: Launch Control (DCT)
```yaml
test_id: TCM_002_LAUNCH_CONTROL
objective: Validate launch control for 0-100 kph acceleration
preconditions:
  - Vehicle stationary
  - Engine warmed up
  - Sport mode active

test_steps:
  1. Driver presses brake + throttle 100%
  2. Monitor engine RPM held at target (4000 RPM)
  3. Driver releases brake
  4. Monitor clutch slip rate during launch
  5. Measure 0-100 kph time

pass_criteria:
  - Engine RPM held at 4000 ±50 RPM during launch prep
  - Clutch slip rate: 500→0 RPM over 1.0 second
  - No wheel spin (traction control coordinated)
  - 0-100 kph: <6.5 seconds (performance target)
  - 1→2 shift seamless (pre-selected on clutch 2)
```

### Test Case 3: Adaptive Learning Validation
```yaml
test_id: TCM_003_ADAPTIVE_LEARNING
objective: Verify adaptive shift quality improvement over drive cycles
preconditions:
  - Clear adaptive memory (factory reset)
  - ATF temperature: 60°C

test_steps:
  1. Perform 100 upshifts (2nd→3rd) at consistent conditions
  2. Record shift jerk for first 10 shifts (baseline)
  3. Record shift jerk for last 10 shifts (adapted)
  4. Compare learned fill time vs initial value

pass_criteria:
  - Shift jerk improvement: >20% reduction baseline→adapted
  - Fill time convergence: Within ±10ms of optimal
  - No false adaptations (stable parameters after convergence)
  - Adaptive data saved to EEPROM after 50 shifts
```

## ISO 26262 Safety Concept

### ASIL Decomposition for TCM

| Function | ASIL | Decomposition | Rationale |
|----------|------|---------------|-----------|
| Gear selection | ASIL-D | ASIL-C(C) + ASIL-B(B) | Position sensor redundancy (dual Hall sensors) |
| Clutch pressure control | ASIL-C | ASIL-B(B) + ASIL-A(A) | Hydraulic valve dual-coil design |
| Park lock | ASIL-D | No decomposition | Mechanical pawl failsafe (unpowered lock) |
| Launch control | QM | N/A | Performance feature, not safety-critical |

### Safety Mechanisms

1. **Gear Sensor Plausibility**: Compare input shaft speed vs vehicle speed for each gear (detect false neutral)
2. **Hydraulic Pressure Monitoring**: Pressure sensors on each clutch pack to verify commanded vs actual
3. **Park Lock Verification**: Microswitch confirms pawl engagement before allowing engine start
4. **Neutral Safety Switch**: Prevent engine start unless Park or Neutral selected
5. **Limp-Home Mode**: Default to 3rd gear if shift solenoids fail (mechanical valving)

## CAN Signal Definitions (DBC)

```dbc
BO_ 260 TCM_Status: 8 TCM
 SG_ CurrentGear : 0|4@1+ (1,0) [0|15] "" PCM,ESC,HMI
 SG_ TargetGear : 4|4@1+ (1,0) [0|15] "" PCM,ESC
 SG_ ShiftInProgress : 8|1@1+ (1,0) [0|1] "" PCM,ESC
 SG_ TorqueConverterLocked : 9|1@1+ (1,0) [0|1] "" PCM,HMI
 SG_ ManualModeActive : 10|1@1+ (1,0) [0|1] "" PCM,HMI
 SG_ ATF_Temperature : 16|8@1- (1,-40) [-40|215] "degC" PCM,HMI
 SG_ TransmissionTorque : 24|16@1+ (0.5,-500) [-500|32267.5] "Nm" PCM,ESC

BO_ 261 TCM_TorqueRequest: 4 TCM
 SG_ TorqueReduction : 0|8@1+ (0.5,0) [0|127.5] "%" PCM
 SG_ TorqueHoldRequest : 8|1@1+ (1,0) [0|1] "" PCM
 SG_ LaunchControlActive : 9|1@1+ (1,0) [0|1] "" PCM,ESC
```

## Tools and Calibration

- **INCA/CANape**: Transmission calibration, shift point tuning, hydraulic pressure optimization
- **dSPACE MicroAutoBox**: Rapid control prototyping, shift algorithm development
- **AVL InMotion**: Powertrain testbed, transmission dynamometer testing
- **Vector CANoe**: TCM simulation, CAN database management
- **ATI Vision**: TCM flashing, diagnostic trouble code management

## References
- SAE J2807 (Transmission Performance Standards)
- ISO 26262 (Functional Safety for TCM)
- AUTOSAR Transmission Manager specification
- SAE J1979 (OBD-II for TCM diagnostics)

---

## Vehicle Dynamics Integration

# Vehicle Dynamics Integration Skill

## Overview
Expert skill in integrated chassis control systems coordinating ESC, ABS, EPS, suspension, torque vectoring, and all-wheel drive (AWD). Covers vehicle motion control, lateral/longitudinal dynamics models, torque distribution strategies, and multi-domain coordination.

## Core Competencies

### 1. Integrated Chassis Controller (ICC)
- **Central Coordination**: Single ECU arbitrates ESC, ABS, EPS, suspension requests
- **Priority Management**: Safety systems (ESC) override comfort systems (suspension)
- **Torque Budget**: Distribute available propulsion/braking torque optimally
- **State Estimation**: Fuse sensors for accurate vehicle state (β, ax, ay, ψ̇)

### 2. Torque Vectoring
- **Left-Right Distribution**: Differential brake force or motor torque for yaw control
- **Understeer Mitigation**: Send more torque to outside wheel in corner
- **Oversteer Correction**: Reduce inside wheel torque, increase outside
- **Performance Enhancement**: Faster corner entry/exit via active yaw moment

### 3. All-Wheel Drive (AWD) Control
- **Torque Split**: Front/rear distribution (50/50 default, dynamic adjustment)
- **Predictive Engagement**: Pre-engage rear axle before slip detected
- **Coupling Control**: Electro-mechanical clutch or active differential
- **Efficiency Mode**: Disconnect rear axle for FWD-only cruising (fuel economy)

### 4. Vehicle Motion Controller (VMC)
- **Reference Model**: Ideal vehicle response (bicycle model, single-track)
- **MIMO Control**: Multi-input (steering, throttle, brake) multi-output (ax, ay, ψ̇)
- **MPC (Model Predictive Control)**: Optimal control over prediction horizon
- **Cascaded Control**: High-level (trajectory) → mid-level (motion) → low-level (actuators)

### 5. Lateral/Longitudinal Dynamics
- **Bicycle Model**: 2-DOF model for lateral dynamics (yaw + sideslip)
- **Tire Models**: Pacejka Magic Formula, linear approximation for control
- **Load Transfer**: Vertical load changes affect lateral force capacity
- **Combined Slip**: Friction ellipse for simultaneous braking + cornering

## Control Algorithms

### Bicycle Model (Reference Yaw Rate)
```c
// 2-DOF bicycle model for vehicle lateral dynamics
typedef struct {
    float mass;              // Vehicle mass (kg)
    float yaw_inertia;       // Yaw moment of inertia (kg⋅m²)
    float wheelbase;         // Front to rear axle distance (m)
    float a, b;              // CG to front/rear axle (m)
    float cf, cr;            // Front/rear cornering stiffness (N/rad)
} BicycleModel_t;

void BicycleModel_Update(BicycleModel_t *model, float delta, float vx, float dt) {
    // State: [beta, psi_dot] (sideslip angle, yaw rate)
    static float beta = 0.0f, psi_dot = 0.0f;

    // Tire slip angles
    float alpha_f = delta - (beta + model->a * psi_dot / vx);
    float alpha_r = -(beta - model->b * psi_dot / vx);

    // Lateral tire forces (linear approximation)
    float Fyf = model->cf * alpha_f;
    float Fyr = model->cr * alpha_r;

    // Equations of motion
    float beta_dot = (Fyf + Fyr) / (model->mass * vx) - psi_dot;
    float psi_ddot = (model->a * Fyf - model->b * Fyr) / model->yaw_inertia;

    // Integrate
    beta += beta_dot * dt;
    psi_dot += psi_ddot * dt;

    // Output reference yaw rate
    ref_yaw_rate = psi_dot;
}
```

### Torque Vectoring Distribution
```c
typedef struct {
    float yaw_moment_desired;  // From ESC or driver intent (N⋅m)
    float total_torque;        // Available propulsion torque (N⋅m)
    float left_torque;         // Left wheels
    float right_torque;        // Right wheels
    float track_width;         // Left-right wheel distance (m)
} TorqueVectoring_t;

void TorqueVectoring_Distribute(TorqueVectoring_t *tv) {
    // Base torque split (50/50)
    float base_torque_per_side = tv->total_torque / 2.0f;

    // Additional torque difference to create yaw moment
    // Yaw moment = (T_right - T_left) * track_width / 2
    float torque_diff = tv->yaw_moment_desired / (tv->track_width / 2.0f);

    // Apply differential
    tv->left_torque = base_torque_per_side - torque_diff / 2.0f;
    tv->right_torque = base_torque_per_side + torque_diff / 2.0f;

    // Limit torque per side (motor/brake capability)
    tv->left_torque = CLAMP(tv->left_torque, -5000.0f, 5000.0f);
    tv->right_torque = CLAMP(tv->right_torque, -5000.0f, 5000.0f);

    // Send to drivetrain
    CAN_Send_LeftWheelTorque(tv->left_torque);
    CAN_Send_RightWheelTorque(tv->right_torque);
}
```

### AWD Torque Split Control
```c
typedef struct {
    float front_torque_percent;   // 0-100%
    float rear_torque_percent;    // 0-100%
    float front_slip;             // Front axle slip ratio
    float rear_slip;              // Rear axle slip ratio
    bool efficiency_mode;         // Disconnect rear for FWD
} AWD_Controller_t;

void AWD_TorqueSplit(AWD_Controller_t *awd, float total_torque) {
    // Default: 50/50 split for balanced traction
    awd->front_torque_percent = 50.0f;
    awd->rear_torque_percent = 50.0f;

    // Efficiency mode: FWD only (highway cruising)
    if (awd->efficiency_mode && total_torque < 500.0f) {
        awd->front_torque_percent = 100.0f;
        awd->rear_torque_percent = 0.0f;
        Clutch_DisconnectRear();
        return;
    } else {
        Clutch_EngageRear();
    }

    // Dynamic adjustment based on slip
    if (awd->front_slip > 0.15f) {
        // Front slipping: send more torque to rear
        awd->rear_torque_percent += 10.0f;
        awd->front_torque_percent -= 10.0f;
    } else if (awd->rear_slip > 0.15f) {
        // Rear slipping: send more torque to front
        awd->front_torque_percent += 10.0f;
        awd->rear_torque_percent -= 10.0f;
    }

    // Clamp percentages
    awd->front_torque_percent = CLAMP(awd->front_torque_percent, 0.0f, 100.0f);
    awd->rear_torque_percent = 100.0f - awd->front_torque_percent;

    // Apply torque split
    float front_torque = total_torque * awd->front_torque_percent / 100.0f;
    float rear_torque = total_torque * awd->rear_torque_percent / 100.0f;

    CAN_Send_FrontAxleTorque(front_torque);
    CAN_Send_RearAxleTorque(rear_torque);
}
```

### Integrated Chassis Controller (Priority Arbitration)
```c
typedef enum {
    ICC_PRIORITY_CRITICAL,   // ESC, ABS (safety)
    ICC_PRIORITY_HIGH,       // TCS, AWD
    ICC_PRIORITY_MEDIUM,     // Torque vectoring, EPS assist
    ICC_PRIORITY_LOW         // Suspension comfort
} ICC_Priority_t;

typedef struct {
    ICC_Priority_t priority;
    float torque_request;
    float brake_request;
    bool active;
} ICC_Request_t;

void ICC_Arbitrate(ICC_Request_t requests[], uint8_t count) {
    // Sort requests by priority
    qsort(requests, count, sizeof(ICC_Request_t), priority_comparator);

    // Highest priority request wins
    ICC_Request_t active_request = {0};

    for (int i = 0; i < count; i++) {
        if (requests[i].active && requests[i].priority >= active_request.priority) {
            active_request = requests[i];
        }
    }

    // Apply winning request
    switch (active_request.priority) {
    case ICC_PRIORITY_CRITICAL:
        // ESC/ABS: full control, override driver
        CAN_Send_TorqueRequest(active_request.torque_request);
        Brake_ApplyForce(active_request.brake_request);
        break;

    case ICC_PRIORITY_HIGH:
        // TCS/AWD: blend with driver input
        float blended_torque = (active_request.torque_request + driver_torque) / 2.0f;
        CAN_Send_TorqueRequest(blended_torque);
        break;

    case ICC_PRIORITY_MEDIUM:
    case ICC_PRIORITY_LOW:
        // Comfort systems: only if no higher priority active
        if (no_critical_systems_active) {
            Apply_ComfortFeatures();
        }
        break;
    }
}
```

### Vehicle State Estimator (Extended Kalman Filter)
```c
// Estimate vehicle state: [vx, vy, psi_dot, beta]
typedef struct {
    float state[4];         // State vector
    float P[4][4];          // Covariance matrix
    float Q[4][4];          // Process noise
    float R[4][4];          // Measurement noise
} EKF_StateEstimator_t;

void EKF_Update(EKF_StateEstimator_t *ekf, float measurements[4], float dt) {
    // Prediction step
    // State transition: x_k+1 = f(x_k, u_k)
    ekf->state[0] += ekf->state[1] * cosf(ekf->state[3]) * dt;  // vx
    ekf->state[1] += ekf->state[2] * ekf->state[0] * dt;        // vy
    ekf->state[2] = ekf->state[2];                               // psi_dot (measured)
    ekf->state[3] = atanf(ekf->state[1] / ekf->state[0]);       // beta

    // Jacobian of state transition
    float F[4][4] = {/* ... compute Jacobian ... */};

    // Predict covariance: P = F*P*F' + Q
    MatrixMultiply(F, ekf->P, 4, 4);
    MatrixAdd(ekf->P, ekf->Q, 4, 4);

    // Correction step
    // Innovation: y = z - h(x)
    float innovation[4];
    for (int i = 0; i < 4; i++) {
        innovation[i] = measurements[i] - ekf->state[i];
    }

    // Kalman gain: K = P*H' / (H*P*H' + R)
    float K[4][4] = {/* ... compute gain ... */};

    // Update state: x = x + K*y
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            ekf->state[i] += K[i][j] * innovation[j];
        }
    }

    // Update covariance: P = (I - K*H)*P
    // ... (simplified for brevity)
}
```

## AUTOSAR Integration

```c
// 10ms high-priority task for integrated chassis control
FUNC(void, ICC_CODE) ICC_MainFunction(void) {
    // Read all chassis sensor inputs
    Rte_Read_IMU_YawRate(&yaw_rate);
    Rte_Read_IMU_LateralAccel(&lat_accel);
    Rte_Read_SteeringAngle(&steering_angle);
    Rte_Read_WheelSpeeds(&wheel_speeds);
    Rte_Read_ECM_EngineTorque(&engine_torque);

    // State estimation (EKF)
    EKF_StateEstimator_t ekf;
    float measurements[4] = {wheel_speed_avg, lat_accel, yaw_rate, 0.0f};
    EKF_Update(&ekf, measurements, 0.01f);

    // Reference model (ideal vehicle response)
    BicycleModel_t model = {/* vehicle parameters */};
    BicycleModel_Update(&model, steering_angle, ekf.state[0], 0.01f);

    // Collect subsystem requests
    ICC_Request_t requests[5];
    requests[0] = ESC_GetRequest();
    requests[1] = ABS_GetRequest();
    requests[2] = TCS_GetRequest();
    requests[3] = TorqueVectoring_GetRequest();
    requests[4] = Suspension_GetRequest();

    // Arbitrate and apply
    ICC_Arbitrate(requests, 5);

    // AWD torque split
    AWD_Controller_t awd;
    AWD_TorqueSplit(&awd, engine_torque);

    // Torque vectoring
    TorqueVectoring_t tv = {.yaw_moment_desired = ref_yaw_rate - yaw_rate};
    TorqueVectoring_Distribute(&tv);
}
```

## HIL Test Scenarios

### Test Case 1: ESC + Torque Vectoring Coordination
```yaml
test_id: ICC_001_ESC_TV_COORD
objective: Coordinated yaw control via ESC braking and torque vectoring
preconditions:
  - Vehicle speed: 80 kph
  - Cornering: 0.7g lateral
  - Oversteer condition (yaw rate error >0.1 rad/s)

test_steps:
  1. Trigger oversteer via steering input
  2. ESC applies outer front brake
  3. Torque vectoring reduces inner wheel torque
  4. Monitor combined yaw moment

pass_criteria:
  - ESC and TV act simultaneously (no conflict)
  - Total yaw moment: ESC 60%, TV 40% contribution
  - Vehicle stabilized within 0.5 seconds
```

### Test Case 2: AWD Slip-Based Torque Transfer
```yaml
test_id: ICC_002_AWD_SLIP_TRANSFER
objective: Dynamic front/rear split based on wheel slip
preconditions:
  - Low-μ surface (μ = 0.3)
  - Acceleration from standstill
  - AWD 50/50 initial split

test_steps:
  1. Apply full throttle
  2. Monitor front/rear wheel slip
  3. AWD adjusts torque split
  4. Measure 0-60 kph time

pass_criteria:
  - Front slip detected: Rear torque increases to 70%
  - Rear slip detected: Front torque increases to 70%
  - 0-60 kph time: <8 seconds on ice
  - No sustained wheel spin (>20% slip)
```

## References
- Rajamani, "Vehicle Dynamics and Control" (bicycle model)
- ISO 26262 (Safety for integrated systems)
- SAE J2564 (ESC test procedures)
- Pacejka, "Tire and Vehicle Dynamics" (Magic Formula)

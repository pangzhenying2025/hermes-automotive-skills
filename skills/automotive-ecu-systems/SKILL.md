---
name: automotive-ecu-systems
description: >
  Automotive Ecu Systems expertise. Covers 8 topics: Bcm Body Control, Bms Battery Management, Domain Controller Integration, Ivi Infotainment Systems, Pdu Power Distribution.
tags: [automotive, automotive-ecu-systems]
---

# Automotive Ecu Systems

## Bcm Body Control

# BCM (Body Control Module) - Comfort and Convenience Systems

## Overview
The Body Control Unit (BCM) manages exterior/interior lighting, HVAC integration, door locks, windows, wipers, keyless entry, anti-theft systems, and power distribution across body electronics. This skill covers production-ready BCM development with LIN bus mastering.

## Core Responsibilities

### 1. Exterior/Interior Lighting Control
```c
/* bcm_lighting_control.c - Comprehensive lighting management */
#include "bcm_lighting_control.h"
#include <stdint.h>
#include <stdbool.h>

#define PWM_FREQUENCY_HZ 1000
#define DIM_STEP_PERCENT 5
#define AUTO_HEADLIGHT_THRESHOLD_LUX 100

typedef enum {
    LIGHT_MODE_OFF = 0,
    LIGHT_MODE_PARKING,
    LIGHT_MODE_DAYTIME_RUNNING,
    LIGHT_MODE_LOW_BEAM,
    LIGHT_MODE_HIGH_BEAM,
    LIGHT_MODE_AUTO
} HeadlightMode_t;

typedef struct {
    bool left_turn_signal_active;
    bool right_turn_signal_active;
    bool hazard_active;
    uint8_t turn_signal_phase;  /* 0-100% for flashing */
    uint32_t last_toggle_ms;
} TurnSignalState_t;

typedef struct {
    HeadlightMode_t mode;
    uint8_t brightness_percent;
    bool high_beam_assist_active;
    bool adaptive_lighting_active;
} HeadlightState_t;

static TurnSignalState_t g_turn_signals = {0};
static HeadlightState_t g_headlights = {0};

void BCM_Lighting_Init(void) {
    /* Initialize PWM channels for LED control */
    PWM_Init(PWM_CHANNEL_LEFT_HEADLIGHT, PWM_FREQUENCY_HZ);
    PWM_Init(PWM_CHANNEL_RIGHT_HEADLIGHT, PWM_FREQUENCY_HZ);
    PWM_Init(PWM_CHANNEL_DOME_LIGHT, PWM_FREQUENCY_HZ);
    PWM_Init(PWM_CHANNEL_AMBIENT_LIGHT, PWM_FREQUENCY_HZ);

    /* Set initial state */
    g_headlights.mode = LIGHT_MODE_OFF;
    g_headlights.brightness_percent = 100;

    /* Load saved settings from EEPROM */
    NvM_ReadBlock(NVM_BLOCK_LIGHTING_SETTINGS, &g_headlights);
}

void BCM_TurnSignals_Update(void) {
    uint32_t current_time = GetSystemTime_ms();

    /* Flash at 1 Hz (500ms on, 500ms off) */
    if ((current_time - g_turn_signals.last_toggle_ms) > 500) {
        g_turn_signals.turn_signal_phase = (g_turn_signals.turn_signal_phase == 0) ? 100 : 0;
        g_turn_signals.last_toggle_ms = current_time;
    }

    /* Left turn signal */
    if (g_turn_signals.left_turn_signal_active || g_turn_signals.hazard_active) {
        PWM_SetDutyCycle(PWM_CHANNEL_LEFT_TURN_FRONT, g_turn_signals.turn_signal_phase);
        PWM_SetDutyCycle(PWM_CHANNEL_LEFT_TURN_REAR, g_turn_signals.turn_signal_phase);
    } else {
        PWM_SetDutyCycle(PWM_CHANNEL_LEFT_TURN_FRONT, 0);
        PWM_SetDutyCycle(PWM_CHANNEL_LEFT_TURN_REAR, 0);
    }

    /* Right turn signal */
    if (g_turn_signals.right_turn_signal_active || g_turn_signals.hazard_active) {
        PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_TURN_FRONT, g_turn_signals.turn_signal_phase);
        PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_TURN_REAR, g_turn_signals.turn_signal_phase);
    } else {
        PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_TURN_FRONT, 0);
        PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_TURN_REAR, 0);
    }
}

void BCM_Headlights_Update(void) {
    uint16_t ambient_light_lux = BCM_LightSensor_Read();

    switch (g_headlights.mode) {
        case LIGHT_MODE_OFF:
            PWM_SetDutyCycle(PWM_CHANNEL_LEFT_HEADLIGHT, 0);
            PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_HEADLIGHT, 0);
            break;

        case LIGHT_MODE_PARKING:
            /* 20% brightness for parking lights */
            PWM_SetDutyCycle(PWM_CHANNEL_LEFT_HEADLIGHT, 20);
            PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_HEADLIGHT, 20);
            break;

        case LIGHT_MODE_DAYTIME_RUNNING:
            /* 50% brightness for DRL */
            PWM_SetDutyCycle(PWM_CHANNEL_LEFT_HEADLIGHT, 50);
            PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_HEADLIGHT, 50);
            break;

        case LIGHT_MODE_LOW_BEAM:
            PWM_SetDutyCycle(PWM_CHANNEL_LEFT_HEADLIGHT, g_headlights.brightness_percent);
            PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_HEADLIGHT, g_headlights.brightness_percent);
            break;

        case LIGHT_MODE_HIGH_BEAM:
            /* Full brightness for high beam */
            PWM_SetDutyCycle(PWM_CHANNEL_LEFT_HEADLIGHT, 100);
            PWM_SetDutyCycle(PWM_CHANNEL_RIGHT_HEADLIGHT, 100);
            PWM_SetDutyCycle(PWM_CHANNEL_HIGH_BEAM, 100);
            break;

        case LIGHT_MODE_AUTO:
            /* Automatic headlight control based on ambient light */
            if (ambient_light_lux < AUTO_HEADLIGHT_THRESHOLD_LUX) {
                /* Dark: enable low beams */
                g_headlights.mode = LIGHT_MODE_LOW_BEAM;
            } else {
                /* Bright: enable DRL only */
                g_headlights.mode = LIGHT_MODE_DAYTIME_RUNNING;
            }
            break;
    }

    /* High beam assist: automatically switch to low beam when oncoming traffic detected */
    if (g_headlights.high_beam_assist_active && g_headlights.mode == LIGHT_MODE_HIGH_BEAM) {
        bool oncoming_detected = ADAS_Camera_DetectOncomingVehicle();
        if (oncoming_detected) {
            g_headlights.mode = LIGHT_MODE_LOW_BEAM;
        }
    }
}

/* Interior dome light with fade-in/fade-out */
void BCM_DomeLight_SetState(bool on, bool fade) {
    static uint8_t current_brightness = 0;
    uint8_t target_brightness = on ? 100 : 0;

    if (fade) {
        /* Fade gradually */
        while (current_brightness != target_brightness) {
            if (current_brightness < target_brightness) {
                current_brightness += DIM_STEP_PERCENT;
            } else {
                current_brightness -= DIM_STEP_PERCENT;
            }

            PWM_SetDutyCycle(PWM_CHANNEL_DOME_LIGHT, current_brightness);
            OsTask_Sleep(50);  /* 50ms steps for smooth fade */
        }
    } else {
        /* Immediate switch */
        current_brightness = target_brightness;
        PWM_SetDutyCycle(PWM_CHANNEL_DOME_LIGHT, current_brightness);
    }
}
```

### 2. Door Lock/Unlock and Keyless Entry
```c
/* bcm_door_control.c - Central locking and keyless entry */
#include "bcm_door_control.h"

#define KEYFOB_UNLOCK_TIMEOUT_MS 3000
#define AUTO_LOCK_SPEED_THRESHOLD_KPH 10
#define PASSIVE_ENTRY_RANGE_M 2.0

typedef enum {
    DOOR_FL = 0,
    DOOR_FR,
    DOOR_RL,
    DOOR_RR,
    DOOR_TRUNK,
    DOOR_COUNT
} DoorID_t;

typedef struct {
    bool locked;
    bool open;
    uint32_t last_lock_timestamp_ms;
} DoorState_t;

typedef struct {
    uint32_t keyfob_id;
    int8_t rssi_dbm;
    float distance_m;  /* Estimated from RSSI */
    bool authenticated;
} KeyFobState_t;

static DoorState_t g_doors[DOOR_COUNT] = {0};
static KeyFobState_t g_active_keyfob = {0};

void BCM_DoorControl_Init(void) {
    /* Initialize door lock actuators */
    for (int i = 0; i < DOOR_COUNT; i++) {
        GPIO_ConfigOutput(DOOR_LOCK_PINS[i]);
        g_doors[i].locked = true;
    }

    /* Initialize door open sensors (switches) */
    for (int i = 0; i < DOOR_COUNT; i++) {
        GPIO_ConfigInput(DOOR_SWITCH_PINS[i], GPIO_PULL_UP);
    }

    /* Initialize BLE for passive keyless entry */
    BLE_Init();
    BLE_StartAdvertising("VehicleKey");
}

void BCM_DoorControl_LockAll(void) {
    for (int i = 0; i < DOOR_COUNT; i++) {
        if (!g_doors[i].locked) {
            /* Activate lock actuator (pulse for 500ms) */
            GPIO_Set(DOOR_LOCK_PINS[i], true);
            OsTask_Sleep(500);
            GPIO_Set(DOOR_LOCK_PINS[i], false);

            g_doors[i].locked = true;
            g_doors[i].last_lock_timestamp_ms = GetSystemTime_ms();
        }
    }

    /* Chirp horn once to confirm lock */
    BCM_Horn_Chirp(1);

    /* Flash turn signals once */
    BCM_TurnSignals_Flash(1);
}

void BCM_DoorControl_UnlockAll(void) {
    /* Unlock driver door first (common in luxury vehicles) */
    BCM_DoorControl_UnlockSingle(DOOR_FL);

    /* Wait 2 seconds, then unlock all if button pressed again */
    uint32_t start_time = GetSystemTime_ms();
    while ((GetSystemTime_ms() - start_time) < 2000) {
        if (KeyFob_ButtonPressed(KEYFOB_BUTTON_UNLOCK)) {
            /* Second press: unlock all doors */
            for (int i = 0; i < DOOR_COUNT; i++) {
                BCM_DoorControl_UnlockSingle((DoorID_t)i);
            }
            break;
        }
        OsTask_Sleep(10);
    }

    /* Flash turn signals twice */
    BCM_TurnSignals_Flash(2);
}

void BCM_DoorControl_UnlockSingle(DoorID_t door) {
    if (g_doors[door].locked) {
        /* Activate unlock actuator */
        GPIO_Set(DOOR_UNLOCK_PINS[door], true);
        OsTask_Sleep(500);
        GPIO_Set(DOOR_UNLOCK_PINS[door], false);

        g_doors[door].locked = false;
    }
}

/* Passive keyless entry: unlock when approaching with authenticated key */
void BCM_PassiveEntry_Update(void) {
    /* Scan for BLE key fobs */
    if (BLE_ScanForDevice(g_active_keyfob.keyfob_id)) {
        g_active_keyfob.rssi_dbm = BLE_GetRSSI();

        /* Estimate distance from RSSI (simplified model) */
        g_active_keyfob.distance_m = pow(10, (-59 - g_active_keyfob.rssi_dbm) / (10 * 2.0));

        /* Authenticate key fob */
        if (!g_active_keyfob.authenticated) {
            uint8_t challenge[16];
            uint8_t response[16];

            BCM_Crypto_GenerateChallenge(challenge);
            BLE_SendChallenge(challenge);

            if (BLE_ReceiveResponse(response) &&
                BCM_Crypto_VerifyResponse(challenge, response)) {
                g_active_keyfob.authenticated = true;
            }
        }

        /* Unlock if authenticated and within range */
        if (g_active_keyfob.authenticated &&
            g_active_keyfob.distance_m < PASSIVE_ENTRY_RANGE_M) {
            /* Check if door handle touched (capacitive sensor) */
            if (GPIO_Read(DOOR_HANDLE_SENSOR_FL)) {
                BCM_DoorControl_UnlockSingle(DOOR_FL);
            }
        }
    }
}

/* Auto-lock when driving */
void BCM_AutoLock_Update(void) {
    uint16_t vehicle_speed = VCU_GetVehicleSpeed_kph();

    if (vehicle_speed > AUTO_LOCK_SPEED_THRESHOLD_KPH) {
        /* Vehicle is moving: auto-lock all doors */
        bool any_unlocked = false;
        for (int i = 0; i < DOOR_COUNT; i++) {
            if (!g_doors[i].locked) {
                any_unlocked = true;
                break;
            }
        }

        if (any_unlocked) {
            BCM_DoorControl_LockAll();
        }
    }
}
```

### 3. Window Control with Anti-Pinch
```c
/* bcm_window_control.c - Power window management with anti-pinch */
#include "bcm_window_control.h"

#define WINDOW_FL 0
#define WINDOW_FR 1
#define WINDOW_RL 2
#define WINDOW_RR 3
#define WINDOW_COUNT 4

#define ANTI_PINCH_FORCE_THRESHOLD_N 100
#define WINDOW_POSITION_SAMPLES 10

typedef enum {
    WINDOW_STATE_STOPPED = 0,
    WINDOW_STATE_MOVING_UP,
    WINDOW_STATE_MOVING_DOWN,
    WINDOW_STATE_PINCH_DETECTED
} WindowState_t;

typedef struct {
    WindowState_t state;
    uint8_t position_percent;  /* 0=closed, 100=fully open */
    uint16_t motor_current_ma;
    bool one_touch_up_active;
    bool one_touch_down_active;
} WindowControl_t;

static WindowControl_t g_windows[WINDOW_COUNT] = {0};

void BCM_WindowControl_Init(void) {
    /* Initialize window motor drivers (H-bridge) */
    for (int i = 0; i < WINDOW_COUNT; i++) {
        GPIO_ConfigOutput(WINDOW_MOTOR_UP_PINS[i]);
        GPIO_ConfigOutput(WINDOW_MOTOR_DOWN_PINS[i]);
    }

    /* Initialize window position sensors (Hall effect) */
    for (int i = 0; i < WINDOW_COUNT; i++) {
        ADC_ConfigChannel(WINDOW_POSITION_ADC_CHANNELS[i]);
    }

    /* Initialize current sensing for anti-pinch */
    for (int i = 0; i < WINDOW_COUNT; i++) {
        ADC_ConfigChannel(WINDOW_CURRENT_ADC_CHANNELS[i]);
    }
}

void BCM_Window_MoveUp(uint8_t window_id) {
    if (window_id >= WINDOW_COUNT) return;

    WindowControl_t* window = &g_windows[window_id];

    if (window->position_percent == 0) {
        return;  /* Already fully closed */
    }

    /* Activate motor upward */
    GPIO_Set(WINDOW_MOTOR_UP_PINS[window_id], true);
    GPIO_Set(WINDOW_MOTOR_DOWN_PINS[window_id], false);

    window->state = WINDOW_STATE_MOVING_UP;
}

void BCM_Window_MoveDown(uint8_t window_id) {
    if (window_id >= WINDOW_COUNT) return;

    WindowControl_t* window = &g_windows[window_id];

    if (window->position_percent == 100) {
        return;  /* Already fully open */
    }

    /* Activate motor downward */
    GPIO_Set(WINDOW_MOTOR_UP_PINS[window_id], false);
    GPIO_Set(WINDOW_MOTOR_DOWN_PINS[window_id], true);

    window->state = WINDOW_STATE_MOVING_DOWN;
}

void BCM_Window_Stop(uint8_t window_id) {
    if (window_id >= WINDOW_COUNT) return;

    /* Stop motor */
    GPIO_Set(WINDOW_MOTOR_UP_PINS[window_id], false);
    GPIO_Set(WINDOW_MOTOR_DOWN_PINS[window_id], false);

    g_windows[window_id].state = WINDOW_STATE_STOPPED;
}

/* Anti-pinch detection: monitor motor current during closing */
void BCM_Window_AntiPinchUpdate(uint8_t window_id) {
    WindowControl_t* window = &g_windows[window_id];

    if (window->state != WINDOW_STATE_MOVING_UP) {
        return;  /* Only check during closing */
    }

    /* Read motor current */
    uint16_t adc_value = ADC_Read(WINDOW_CURRENT_ADC_CHANNELS[window_id]);
    window->motor_current_ma = (adc_value * 5000) / 4096;  /* 12-bit ADC, 0-5A range */

    /* Detect excessive current (indicates obstruction) */
    if (window->motor_current_ma > ANTI_PINCH_FORCE_THRESHOLD_N) {
        /* Pinch detected: reverse window */
        window->state = WINDOW_STATE_PINCH_DETECTED;

        BCM_Window_Stop(window_id);
        OsTask_Sleep(100);

        /* Move down slightly to release obstruction */
        GPIO_Set(WINDOW_MOTOR_DOWN_PINS[window_id], true);
        OsTask_Sleep(500);
        GPIO_Set(WINDOW_MOTOR_DOWN_PINS[window_id], false);

        window->state = WINDOW_STATE_STOPPED;

        /* Log event */
        DTC_SetFault(DTC_WINDOW_ANTI_PINCH_TRIGGERED + window_id);
    }
}

/* One-touch up/down */
void BCM_Window_OneTouchUp(uint8_t window_id) {
    g_windows[window_id].one_touch_up_active = true;

    while (g_windows[window_id].position_percent > 0 &&
           g_windows[window_id].state != WINDOW_STATE_PINCH_DETECTED) {
        BCM_Window_MoveUp(window_id);
        BCM_Window_UpdatePosition(window_id);
        BCM_Window_AntiPinchUpdate(window_id);
        OsTask_Sleep(10);
    }

    BCM_Window_Stop(window_id);
    g_windows[window_id].one_touch_up_active = false;
}
```

### 4. LIN Bus Mastering (Door Modules)
```c
/* bcm_lin_master.c - LIN bus control for door modules */
#include "bcm_lin_master.h"

#define LIN_BAUDRATE 19200
#define LIN_BREAK_DURATION_US 750
#define LIN_FRAME_TIMEOUT_MS 50

typedef struct {
    uint8_t frame_id;
    uint8_t data[8];
    uint8_t length;
    uint8_t checksum;
} LINFrame_t;

/* Door module addresses */
#define LIN_DOOR_FL_ID 0x01
#define LIN_DOOR_FR_ID 0x02
#define LIN_DOOR_RL_ID 0x03
#define LIN_DOOR_RR_ID 0x04

void BCM_LIN_Init(void) {
    /* Configure UART for LIN */
    UART_Init(LIN_UART_PORT, LIN_BAUDRATE);
    UART_SetMode(LIN_UART_PORT, UART_MODE_LIN);
}

void BCM_LIN_SendBreak(void) {
    /* Generate LIN break field (dominant for 750µs) */
    GPIO_Set(LIN_TX_PIN, false);
    usleep(LIN_BREAK_DURATION_US);
    GPIO_Set(LIN_TX_PIN, true);
}

bool BCM_LIN_SendFrame(const LINFrame_t* frame) {
    /* Send break + sync byte + frame ID */
    BCM_LIN_SendBreak();
    UART_WriteByte(LIN_UART_PORT, 0x55);  /* Sync byte */
    UART_WriteByte(LIN_UART_PORT, frame->frame_id);

    /* Send data */
    for (int i = 0; i < frame->length; i++) {
        UART_WriteByte(LIN_UART_PORT, frame->data[i]);
    }

    /* Send checksum */
    UART_WriteByte(LIN_UART_PORT, frame->checksum);

    return true;
}

/* Command door module to lock/unlock */
void BCM_LIN_DoorLockCommand(uint8_t door_module_id, bool lock) {
    LINFrame_t frame;
    frame.frame_id = door_module_id;
    frame.length = 2;
    frame.data[0] = lock ? 0x01 : 0x02;  /* 0x01=lock, 0x02=unlock */
    frame.data[1] = 0x00;
    frame.checksum = BCM_LIN_CalculateChecksum(&frame);

    BCM_LIN_SendFrame(&frame);
}

/* Read door status from LIN module */
bool BCM_LIN_ReadDoorStatus(uint8_t door_module_id, bool* door_open, bool* window_position) {
    LINFrame_t request;
    request.frame_id = door_module_id | 0x40;  /* Read request */
    request.length = 0;
    request.checksum = BCM_LIN_CalculateChecksum(&request);

    BCM_LIN_SendFrame(&request);

    /* Wait for response */
    LINFrame_t response;
    if (BCM_LIN_ReceiveFrame(&response, LIN_FRAME_TIMEOUT_MS)) {
        *door_open = (response.data[0] & 0x01) != 0;
        *window_position = response.data[1];
        return true;
    }

    return false;
}
```

## BCM CAN Database (DBC)
```
VERSION ""

NS_ :

BS_:

BU_: BCM VCU IVI

/* BCM Lighting Status */
BO_ 512 BCM_LightingStatus: 8 BCM
 SG_ BCM_HeadlightMode : 0|8@1+ (0,0) [0|5] ""  IVI
 SG_ BCM_LeftTurnSignal : 8|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ BCM_RightTurnSignal : 9|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ BCM_HazardActive : 10|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ BCM_HighBeamActive : 11|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ BCM_BrakeLight : 12|1@1+ (0,0) [0|1] ""  VCU

/* BCM Door Status */
BO_ 513 BCM_DoorStatus: 8 BCM
 SG_ BCM_DoorLocked_FL : 0|1@1+ (0,0) [0|1] ""  IVI
 SG_ BCM_DoorLocked_FR : 1|1@1+ (0,0) [0|1] ""  IVI
 SG_ BCM_DoorLocked_RL : 2|1@1+ (0,0) [0|1] ""  IVI
 SG_ BCM_DoorLocked_RR : 3|1@1+ (0,0) [0|1] ""  IVI
 SG_ BCM_DoorOpen_FL : 8|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ BCM_DoorOpen_FR : 9|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ BCM_DoorOpen_RL : 10|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ BCM_DoorOpen_RR : 11|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ BCM_TrunkOpen : 12|1@1+ (0,0) [0|1] ""  VCU,IVI

VAL_ 512 BCM_HeadlightMode 0 "Off" 1 "Parking" 2 "DRL" 3 "LowBeam" 4 "HighBeam" 5 "Auto";
```

## References
- SAE J1850: Class B Data Communication Network Interface
- ISO 17987: Local Interconnect Network (LIN) Protocol
- IEC 60529: IP Rating (Ingress Protection)
- ECE R48: Installation of lighting devices

## Common Issues
- LIN bus communication errors due to incorrect timing
- Anti-pinch false triggers from motor current spikes
- Keyless entry authentication failures
- Door lock actuators jamming in cold weather
- PWM flicker at low brightness levels

---

## Bms Battery Management

# BMS (Battery Management System) for EVs/HEVs

## Overview
The Battery Management System (BMS) monitors cell voltages, estimates SOC/SOH, performs cell balancing, manages thermal systems, controls contactors, and ensures ISO 26262 ASIL-D safety compliance for high-voltage battery packs.

## Core Responsibilities

### 1. Cell Voltage Monitoring
```c
/* bms_cell_monitoring.c - Multi-cell voltage acquisition */
#include "bms_cell_monitoring.h"

#define MAX_CELLS_PER_MODULE 12
#define MAX_MODULES 10
#define TOTAL_CELLS (MAX_CELLS_PER_MODULE * MAX_MODULES)

#define CELL_OVERVOLTAGE_MV 4200
#define CELL_UNDERVOLTAGE_MV 2500

typedef struct {
    uint16_t voltage_mv;
    int16_t temperature_c_x10;  /* 0.1°C resolution */
    bool balancing_active;
} CellData_t;

typedef struct {
    CellData_t cells[MAX_CELLS_PER_MODULE];
    uint8_t module_id;
    int16_t module_temperature_c_x10;
    bool communication_ok;
} ModuleData_t;

static ModuleData_t g_modules[MAX_MODULES];

/* LTC6811 Battery Monitor IC interface */
void BMS_CellMonitoring_Init(void) {
    /* Initialize SPI for LTC6811 daisy chain */
    SPI_Init(SPI_BMS, 1000000);  /* 1 MHz */

    /* Wake up all LTC6811 ICs */
    BMS_LTC6811_Wakeup();

    /* Configure cell measurement mode */
    uint8_t config[6] = {
        0xF8,  /* GPIO pull-downs off, REFON=1 */
        0x00,  /* Discharge switches off */
        0x00, 0x00, 0x00, 0x00
    };
    BMS_LTC6811_WriteConfig(config);
}

void BMS_CellMonitoring_Update(void) {
    /* Start cell voltage conversion (all cells, all modules) */
    BMS_LTC6811_StartCellConversion(ADC_MODE_NORMAL, ADC_FILTER_7KHZ);

    /* Wait for conversion (2.3ms for normal mode) */
    OsTask_Sleep(3);

    /* Read cell voltages from all modules */
    for (uint8_t module = 0; module < MAX_MODULES; module++) {
        uint16_t cell_voltages[MAX_CELLS_PER_MODULE];

        if (BMS_LTC6811_ReadCellVoltages(module, cell_voltages)) {
            for (uint8_t cell = 0; cell < MAX_CELLS_PER_MODULE; cell++) {
                g_modules[module].cells[cell].voltage_mv = cell_voltages[cell] / 10;  /* 100µV resolution */

                /* Check overvoltage/undervoltage */
                if (cell_voltages[cell] > CELL_OVERVOLTAGE_MV) {
                    BMS_Fault_SetOvervoltage(module, cell);
                }
                if (cell_voltages[cell] < CELL_UNDERVOLTAGE_MV) {
                    BMS_Fault_SetUndervoltage(module, cell);
                }
            }
            g_modules[module].communication_ok = true;
        } else {
            g_modules[module].communication_ok = false;
            BMS_Fault_SetCommunicationLoss(module);
        }
    }

    /* Read temperatures via GPIO (NTC thermistors) */
    BMS_LTC6811_ReadGPIO();
}

uint16_t BMS_GetMinCellVoltage_mV(void) {
    uint16_t min_voltage = 0xFFFF;

    for (uint8_t mod = 0; mod < MAX_MODULES; mod++) {
        for (uint8_t cell = 0; cell < MAX_CELLS_PER_MODULE; cell++) {
            if (g_modules[mod].cells[cell].voltage_mv < min_voltage) {
                min_voltage = g_modules[mod].cells[cell].voltage_mv;
            }
        }
    }

    return min_voltage;
}

uint16_t BMS_GetMaxCellVoltage_mV(void) {
    uint16_t max_voltage = 0;

    for (uint8_t mod = 0; mod < MAX_MODULES; mod++) {
        for (uint8_t cell = 0; cell < MAX_CELLS_PER_MODULE; cell++) {
            if (g_modules[mod].cells[cell].voltage_mv > max_voltage) {
                max_voltage = g_modules[mod].cells[cell].voltage_mv;
            }
        }
    }

    return max_voltage;
}
```

### 2. SOC/SOH Estimation (Coulomb Counting + Kalman Filter)
```c
/* bms_soc_estimation.c - State of Charge / State of Health algorithms */
#include "bms_soc_estimation.h"
#include <math.h>

#define BATTERY_CAPACITY_AH 75.0
#define COULOMB_EFFICIENCY 0.98  /* Charge efficiency */

typedef struct {
    float soc_percent;           /* 0-100% */
    float soh_percent;           /* 0-100%, degrades over time */
    float coulomb_count_ah;      /* Accumulated amp-hours */
    float ocv_voltage_v;         /* Open circuit voltage */
    uint32_t cycle_count;        /* Full charge/discharge cycles */
    float remaining_capacity_ah;
} SOCState_t;

static SOCState_t g_soc_state = {
    .soc_percent = 50.0,
    .soh_percent = 100.0,
    .coulomb_count_ah = BATTERY_CAPACITY_AH / 2.0,
    .remaining_capacity_ah = BATTERY_CAPACITY_AH
};

/* OCV-SOC lookup table (Open Circuit Voltage to SOC mapping) */
static const struct {
    float voltage_v;
    float soc_percent;
} OCV_SOC_TABLE[] = {
    {3.27, 0.0},
    {3.61, 10.0},
    {3.69, 20.0},
    {3.71, 30.0},
    {3.73, 40.0},
    {3.77, 50.0},
    {3.83, 60.0},
    {3.92, 70.0},
    {4.01, 80.0},
    {4.08, 90.0},
    {4.20, 100.0}
};

void BMS_SOC_Init(void) {
    /* Load last known SOC from EEPROM */
    NvM_ReadBlock(NVM_BLOCK_SOC_STATE, &g_soc_state);

    /* Initialize Kalman filter for SOC estimation */
    BMS_KalmanFilter_Init();
}

void BMS_SOC_Update(float current_a, uint32_t delta_time_ms) {
    /* Coulomb counting: integrate current over time */
    float delta_time_h = delta_time_ms / 3600000.0;
    float delta_ah = current_a * delta_time_h;

    /* Positive current = discharge, negative = charge */
    if (current_a > 0) {
        g_soc_state.coulomb_count_ah -= delta_ah;
    } else {
        g_soc_state.coulomb_count_ah -= delta_ah * COULOMB_EFFICIENCY;
    }

    /* Clamp to capacity limits */
    if (g_soc_state.coulomb_count_ah < 0) {
        g_soc_state.coulomb_count_ah = 0;
    }
    if (g_soc_state.coulomb_count_ah > g_soc_state.remaining_capacity_ah) {
        g_soc_state.coulomb_count_ah = g_soc_state.remaining_capacity_ah;
    }

    /* Calculate SOC from coulomb count */
    g_soc_state.soc_percent = (g_soc_state.coulomb_count_ah /
                                g_soc_state.remaining_capacity_ah) * 100.0;

    /* Kalman filter fusion with OCV-based SOC (when current near zero) */
    if (fabs(current_a) < 1.0) {  /* Low current: use OCV */
        float pack_voltage_v = BMS_GetPackVoltage() / 1000.0;
        float avg_cell_voltage_v = pack_voltage_v / TOTAL_CELLS;

        float ocv_soc = BMS_SOC_LookupOCV(avg_cell_voltage_v);

        /* Kalman filter update */
        g_soc_state.soc_percent = BMS_KalmanFilter_Update(
            g_soc_state.soc_percent,
            ocv_soc);
    }

    /* Persist SOC every 1% change */
    static float last_saved_soc = 0;
    if (fabs(g_soc_state.soc_percent - last_saved_soc) > 1.0) {
        NvM_WriteBlock(NVM_BLOCK_SOC_STATE, &g_soc_state);
        last_saved_soc = g_soc_state.soc_percent;
    }
}

float BMS_SOC_LookupOCV(float voltage_v) {
    /* Linear interpolation in OCV-SOC table */
    for (int i = 0; i < (sizeof(OCV_SOC_TABLE) / sizeof(OCV_SOC_TABLE[0])) - 1; i++) {
        if (voltage_v >= OCV_SOC_TABLE[i].voltage_v &&
            voltage_v <= OCV_SOC_TABLE[i+1].voltage_v) {

            float v_range = OCV_SOC_TABLE[i+1].voltage_v - OCV_SOC_TABLE[i].voltage_v;
            float soc_range = OCV_SOC_TABLE[i+1].soc_percent - OCV_SOC_TABLE[i].soc_percent;
            float v_delta = voltage_v - OCV_SOC_TABLE[i].voltage_v;

            return OCV_SOC_TABLE[i].soc_percent + (v_delta / v_range) * soc_range;
        }
    }

    return 50.0;  /* Default fallback */
}

/* SOH estimation based on capacity fade */
void BMS_SOH_Update(void) {
    /* Detect full charge cycle: SOC goes 100% -> 0% -> 100% */
    static bool charging = false;
    static bool discharged = false;

    if (g_soc_state.soc_percent > 99.0 && !charging) {
        charging = true;

        if (discharged) {
            /* Full cycle completed */
            g_soc_state.cycle_count++;

            /* Estimate capacity fade: 80% at 1000 cycles (linear model) */
            g_soc_state.remaining_capacity_ah =
                BATTERY_CAPACITY_AH * (1.0 - (g_soc_state.cycle_count / 5000.0));

            g_soc_state.soh_percent = (g_soc_state.remaining_capacity_ah /
                                       BATTERY_CAPACITY_AH) * 100.0;

            discharged = false;
        }
    }

    if (g_soc_state.soc_percent < 5.0) {
        discharged = true;
        charging = false;
    }
}
```

### 3. Cell Balancing (Active/Passive)
```c
/* bms_cell_balancing.c - Cell voltage equalization */
#include "bms_cell_balancing.h"

#define BALANCE_THRESHOLD_MV 10  /* Start balancing if cell delta > 10mV */
#define BALANCE_TARGET_MV 5      /* Stop when delta < 5mV */
#define MAX_BALANCE_CURRENT_MA 200

void BMS_CellBalancing_Update(void) {
    uint16_t min_voltage = BMS_GetMinCellVoltage_mV();
    uint16_t max_voltage = BMS_GetMaxCellVoltage_mV();

    if ((max_voltage - min_voltage) < BALANCE_THRESHOLD_MV) {
        /* Cells well balanced: disable all balancing */
        BMS_CellBalancing_DisableAll();
        return;
    }

    /* Passive balancing: discharge high cells through resistors */
    for (uint8_t mod = 0; mod < MAX_MODULES; mod++) {
        uint16_t balance_mask = 0;

        for (uint8_t cell = 0; cell < MAX_CELLS_PER_MODULE; cell++) {
            uint16_t cell_voltage = g_modules[mod].cells[cell].voltage_mv;

            /* Balance if above minimum + threshold */
            if (cell_voltage > (min_voltage + BALANCE_TARGET_MV)) {
                balance_mask |= (1 << cell);
                g_modules[mod].cells[cell].balancing_active = true;
            } else {
                g_modules[mod].cells[cell].balancing_active = false;
            }
        }

        /* Write balance control register to LTC6811 */
        BMS_LTC6811_SetBalancing(mod, balance_mask);
    }
}
```

### 4. Contactor Control (Safety-Critical)
```c
/* bms_contactor_control.c - High-voltage contactor sequencing */
#include "bms_contactor_control.h"

#define PRECHARGE_TIMEOUT_MS 5000
#define PRECHARGE_THRESHOLD_PERCENT 95

typedef enum {
    CONTACTOR_STATE_OPEN = 0,
    CONTACTOR_STATE_PRECHARGING,
    CONTACTOR_STATE_CLOSED,
    CONTACTOR_STATE_FAULT
} ContactorState_t;

static ContactorState_t g_contactor_state = CONTACTOR_STATE_OPEN;

void BMS_Contactor_Close(void) {
    /* Safety checks before closing */
    if (!BMS_Safety_PreCloseCheck()) {
        g_contactor_state = CONTACTOR_STATE_FAULT;
        return;
    }

    /* Step 1: Close negative contactor */
    GPIO_Set(GPIO_CONTACTOR_NEGATIVE, true);
    OsTask_Sleep(50);

    /* Step 2: Precharge positive side through resistor */
    g_contactor_state = CONTACTOR_STATE_PRECHARGING;
    GPIO_Set(GPIO_PRECHARGE_RELAY, true);

    uint32_t start_time = GetSystemTime_ms();
    uint16_t pack_voltage_v = BMS_GetPackVoltage();
    uint16_t link_voltage_v = ADC_ReadHVLinkVoltage();

    /* Wait for DC link to charge to 95% of pack voltage */
    while ((GetSystemTime_ms() - start_time) < PRECHARGE_TIMEOUT_MS) {
        link_voltage_v = ADC_ReadHVLinkVoltage();

        if (link_voltage_v > (pack_voltage_v * PRECHARGE_THRESHOLD_PERCENT / 100)) {
            break;  /* Precharge complete */
        }

        OsTask_Sleep(10);
    }

    if (link_voltage_v < (pack_voltage_v * PRECHARGE_THRESHOLD_PERCENT / 100)) {
        /* Precharge timeout: fault */
        GPIO_Set(GPIO_PRECHARGE_RELAY, false);
        GPIO_Set(GPIO_CONTACTOR_NEGATIVE, false);
        g_contactor_state = CONTACTOR_STATE_FAULT;
        DTC_SetFault(DTC_PRECHARGE_TIMEOUT);
        return;
    }

    /* Step 3: Close positive contactor */
    GPIO_Set(GPIO_CONTACTOR_POSITIVE, true);
    OsTask_Sleep(50);

    /* Step 4: Open precharge relay */
    GPIO_Set(GPIO_PRECHARGE_RELAY, false);

    g_contactor_state = CONTACTOR_STATE_CLOSED;
}

void BMS_Contactor_Open(void) {
    /* Open positive first, then negative */
    GPIO_Set(GPIO_CONTACTOR_POSITIVE, false);
    OsTask_Sleep(50);
    GPIO_Set(GPIO_CONTACTOR_NEGATIVE, false);

    g_contactor_state = CONTACTOR_STATE_OPEN;
}
```

## BMS CAN Database (DBC)
```
VERSION ""

NS_ :

BS_:

BU_: BMS VCU MCU

/* BMS Battery Status */
BO_ 768 BMS_BatteryStatus: 8 BMS
 SG_ BMS_PackVoltage_V : 0|16@1+ (0.1,0) [0|600] "V"  VCU,MCU
 SG_ BMS_PackCurrent_A : 16|16@1- (0.1,-320) [-320|320] "A"  VCU,MCU
 SG_ BMS_SOC_percent : 32|8@1+ (0.5,0) [0|100] "%"  VCU,MCU
 SG_ BMS_SOH_percent : 40|8@1+ (0.5,0) [0|100] "%"  VCU
 SG_ BMS_MaxCellTemp_C : 48|8@1+ (1,-40) [-40|100] "C"  VCU,MCU
 SG_ BMS_ContactorState : 56|8@1+ (0,0) [0|3] ""  VCU,MCU

VAL_ 768 BMS_ContactorState 0 "Open" 1 "Precharging" 2 "Closed" 3 "Fault";
```

## ISO 26262 ASIL-D Safety Mechanisms
- Dual voltage measurement paths with cross-checking
- Watchdog timer for contactor control
- Cell voltage plausibility checks
- Safe state transition on fault detection

## References
- ISO 26262: Functional Safety for Road Vehicles
- UL 2580: Batteries for Use in Electric Vehicles
- IEC 62133: Safety Requirements for Portable Sealed Secondary Cells
- SAE J2464: EV Battery Systems Crashworthiness

## Common Issues
- SOC drift from coulomb counting errors
- Cell balancing inefficiency at low SOC
- Precharge relay welding from inrush current
- Temperature sensor failures affecting thermal management

---

## Domain Controller Integration

# Domain Controller Architecture - Next-Gen Vehicle E/E Architecture

## Overview
Domain Controller architecture centralizes ECU functions into fewer, more powerful computing platforms: Chassis Domain, Powertrain Domain, Body/Comfort Domain, ADAS Domain, with cross-domain communication via service-oriented architecture (SOA) and resource sharing.

## Domain Controller Concepts

### 1. Chassis Domain Controller
```c
/* chassis_domain_controller.c - Integrated chassis functions */
#include "chassis_domain.h"

/* Consolidated functions: ESC, ABS, TCS, EPS, ADAS braking */
typedef struct {
    /* Electronic Stability Control */
    bool esc_active;
    float yaw_rate_deg_s;
    float lateral_acceleration_g;

    /* Anti-lock Braking System */
    uint8_t wheel_speeds_kph[4];
    bool abs_active[4];

    /* Traction Control System */
    bool tcs_active;
    uint16_t tcs_torque_reduction_nm;

    /* Electric Power Steering */
    float steering_angle_deg;
    float steering_torque_nm;

    /* ADAS Braking Interface */
    bool adas_brake_request;
    float adas_decel_mps2;
} ChassisDomain_t;

static ChassisDomain_t g_chassis = {0};

void ChassisDomain_Main_10ms(void) {
    /* Read sensors from CAN/FlexRay */
    ChassisDomain_ReadSensors();

    /* ESC control loop */
    ChassisDomain_ESC_Update();

    /* ABS control per wheel */
    for (int i = 0; i < 4; i++) {
        ChassisDomain_ABS_UpdateWheel(i);
    }

    /* TCS integration with powertrain domain */
    if (g_chassis.tcs_active) {
        /* Send torque reduction request to powertrain domain */
        SOMEIP_SendRequest(POWERTRAIN_DOMAIN_SERVICE_ID,
                           METHOD_REDUCE_TORQUE,
                           &g_chassis.tcs_torque_reduction_nm,
                           sizeof(uint16_t));
    }

    /* ADAS brake arbitration */
    if (g_chassis.adas_brake_request) {
        ChassisDomain_ADAS_BrakeControl();
    }

    /* Publish chassis status to Ethernet backbone */
    ChassisDomain_PublishStatus();
}

void ChassisDomain_ESC_Update(void) {
    /* Read IMU (gyroscope + accelerometer) */
    float yaw_rate = IMU_GetYawRate();
    float lat_accel = IMU_GetLateralAcceleration();

    /* Calculate desired yaw rate from steering angle */
    float desired_yaw = (g_chassis.steering_angle_deg * VCU_GetVehicleSpeed_kph()) / 15.0;

    /* ESC intervention if yaw error exceeds threshold */
    float yaw_error = desired_yaw - yaw_rate;

    if (fabs(yaw_error) > 5.0) {
        g_chassis.esc_active = true;

        /* Apply differential braking to correct yaw */
        if (yaw_error > 0) {
            /* Understeer: brake inside rear wheel */
            ChassisDomain_ApplyBrake(WHEEL_RL, 30);
        } else {
            /* Oversteer: brake outside front wheel */
            ChassisDomain_ApplyBrake(WHEEL_FL, 30);
        }

        /* Reduce engine torque */
        SOMEIP_SendRequest(POWERTRAIN_DOMAIN_SERVICE_ID,
                           METHOD_REDUCE_TORQUE,
                           &(uint16_t){100}, 2);
    } else {
        g_chassis.esc_active = false;
    }
}
```

### 2. Powertrain Domain Controller
```c
/* powertrain_domain_controller.c - EV powertrain integration */
#include "powertrain_domain.h"

/* Consolidated: VCU, BMS, MCU functions */
typedef struct {
    /* Motor control */
    int16_t motor_torque_cmd_nm;
    uint16_t motor_speed_rpm;
    float motor_temperature_c;

    /* Battery management */
    float battery_soc_percent;
    uint16_t battery_voltage_v;
    float battery_current_a;

    /* Thermal management */
    bool cooling_pump_active;
    uint8_t radiator_fan_speed_percent;
} PowertrainDomain_t;

static PowertrainDomain_t g_powertrain = {0};

void PowertrainDomain_Main_10ms(void) {
    /* Motor control */
    PowertrainDomain_MotorControl();

    /* Battery management */
    PowertrainDomain_BMS_Update();

    /* Thermal management */
    PowertrainDomain_ThermalControl();

    /* Service-oriented communication */
    PowertrainDomain_HandleSOARequests();
}

void PowertrainDomain_HandleSOARequests(void) {
    /* Handle SOME/IP service requests from other domains */
    SOMEIP_Request_t req;

    if (SOMEIP_ReceiveRequest(&req)) {
        switch (req.method_id) {
            case METHOD_REDUCE_TORQUE: {
                uint16_t reduction_nm = *(uint16_t*)req.payload;
                g_powertrain.motor_torque_cmd_nm -= reduction_nm;

                /* Send response */
                SOMEIP_SendResponse(&req, RESPONSE_OK, NULL, 0);
                break;
            }

            case METHOD_GET_SOC: {
                uint8_t soc = (uint8_t)g_powertrain.battery_soc_percent;
                SOMEIP_SendResponse(&req, RESPONSE_OK, &soc, 1);
                break;
            }

            case METHOD_SET_CHARGING_LIMIT: {
                uint8_t limit_percent = *(uint8_t*)req.payload;
                PowertrainDomain_SetChargingLimit(limit_percent);
                SOMEIP_SendResponse(&req, RESPONSE_OK, NULL, 0);
                break;
            }
        }
    }
}
```

### 3. Body/Comfort Domain Controller
```c
/* body_domain_controller.c - Comfort and convenience functions */
#include "body_domain.h"

/* Consolidated: BCM, HVAC, seats, ambient lighting */
typedef struct {
    /* Climate control */
    float cabin_temperature_c;
    uint8_t hvac_fan_speed;
    bool ac_compressor_active;

    /* Lighting */
    HeadlightMode_t headlight_mode;
    uint8_t ambient_light_brightness;

    /* Seats */
    uint8_t driver_seat_heating_level;
    uint8_t passenger_seat_heating_level;
} BodyDomain_t;

static BodyDomain_t g_body = {0};

void BodyDomain_Main_50ms(void) {
    /* Climate control */
    BodyDomain_HVAC_Update();

    /* Lighting control */
    BodyDomain_Lighting_Update();

    /* Seat control */
    BodyDomain_Seats_Update();

    /* User preference synchronization (cloud) */
    BodyDomain_SyncUserPreferences();
}

void BodyDomain_SyncUserPreferences(void) {
    /* Load user profile from cloud (via TCU) */
    UserProfile_t profile;

    if (Cloud_GetUserProfile(g_authenticated_user_id, &profile)) {
        /* Apply preferences */
        g_body.driver_seat_heating_level = profile.seat_heat_pref;
        g_body.ambient_light_brightness = profile.ambient_light_pref;
        g_body.headlight_mode = profile.headlight_mode_pref;

        /* Adjust seat position (via LIN to seat ECU) */
        LIN_SendSeatPosition(profile.seat_position);
    }
}
```

### 4. ADAS Domain Controller
```c
/* adas_domain_controller.c - Perception, planning, control */
#include "adas_domain.h"

/* Consolidated: camera, radar, lidar fusion, path planning */
typedef struct {
    /* Perception */
    Object_t detected_objects[32];
    uint8_t object_count;

    /* Localization */
    float ego_position_x;
    float ego_position_y;
    float ego_heading_deg;

    /* Path planning */
    Trajectory_t planned_path;

    /* Control */
    float target_acceleration_mps2;
    float target_steering_angle_deg;
} ADASDomain_t;

static ADASDomain_t g_adas = {0};

void ADASDomain_Main_20ms(void) {
    /* Sensor fusion */
    ADASDomain_SensorFusion();

    /* Object detection and tracking */
    ADASDomain_ObjectTracking();

    /* Path planning */
    ADASDomain_PathPlanning();

    /* Send control commands to chassis/powertrain domains */
    ADASDomain_SendControlCommands();
}

void ADASDomain_SendControlCommands(void) {
    /* Request steering via chassis domain */
    SOMEIP_SendRequest(CHASSIS_DOMAIN_SERVICE_ID,
                       METHOD_SET_STEERING_ANGLE,
                       &g_adas.target_steering_angle_deg,
                       sizeof(float));

    /* Request acceleration via powertrain domain */
    if (g_adas.target_acceleration_mps2 > 0) {
        /* Acceleration */
        int16_t torque_nm = (int16_t)(g_adas.target_acceleration_mps2 * 50);
        SOMEIP_SendRequest(POWERTRAIN_DOMAIN_SERVICE_ID,
                           METHOD_SET_TORQUE,
                           &torque_nm,
                           sizeof(int16_t));
    } else {
        /* Braking */
        float decel_mps2 = -g_adas.target_acceleration_mps2;
        SOMEIP_SendRequest(CHASSIS_DOMAIN_SERVICE_ID,
                           METHOD_APPLY_BRAKE,
                           &decel_mps2,
                           sizeof(float));
    }
}
```

## Service-Oriented Architecture (SOME/IP)

### SOME/IP Service Definition (ARXML)
```xml
<!-- adas_services.arxml -->
<AUTOSAR>
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>ADAS_Services</SHORT-NAME>
      <ELEMENTS>
        <SOMEIP-SERVICE-INTERFACE>
          <SHORT-NAME>ADAS_Control_Service</SHORT-NAME>
          <SERVICE-INTERFACE-ID>0x1234</SERVICE-INTERFACE-ID>
          <MAJOR-VERSION>1</MAJOR-VERSION>
          <MINOR-VERSION>0</MINOR-VERSION>

          <METHODS>
            <SOMEIP-METHOD>
              <SHORT-NAME>SetSteeringAngle</SHORT-NAME>
              <METHOD-ID>0x0001</METHOD-ID>
              <CALL-SEMANTIC>REQUEST-RESPONSE</CALL-SEMANTIC>
            </SOMEIP-METHOD>
            <SOMEIP-METHOD>
              <SHORT-NAME>ApplyBrake</SHORT-NAME>
              <METHOD-ID>0x0002</METHOD-ID>
              <CALL-SEMANTIC>REQUEST-RESPONSE</CALL-SEMANTIC>
            </SOMEIP-METHOD>
          </METHODS>

          <EVENTS>
            <SOMEIP-EVENT>
              <SHORT-NAME>ObjectDetected</SHORT-NAME>
              <EVENT-ID>0x8001</EVENT-ID>
            </SOMEIP-EVENT>
          </EVENTS>
        </SOMEIP-SERVICE-INTERFACE>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
```

### Cross-Domain Communication Example
```c
/* domain_communication.c - SOME/IP client/server example */
#include "someip.h"

/* Client: ADAS domain requests torque from powertrain domain */
void ADAS_RequestTorque(int16_t torque_nm) {
    SOMEIP_Message_t msg;
    msg.service_id = POWERTRAIN_SERVICE_ID;
    msg.method_id = METHOD_SET_TORQUE;
    msg.client_id = ADAS_DOMAIN_CLIENT_ID;
    msg.session_id = GetNextSessionID();
    msg.payload_length = sizeof(int16_t);
    memcpy(msg.payload, &torque_nm, sizeof(int16_t));

    SOMEIP_Send(&msg);

    /* Wait for response */
    SOMEIP_Message_t response;
    if (SOMEIP_WaitForResponse(&response, 100)) {
        if (response.return_code == SOMEIP_RETURN_OK) {
            /* Request acknowledged */
        }
    }
}

/* Server: Powertrain domain handles torque request */
void Powertrain_SOMEIP_Handler(const SOMEIP_Message_t* request) {
    if (request->method_id == METHOD_SET_TORQUE) {
        int16_t requested_torque = *(int16_t*)request->payload;

        /* Apply safety limits */
        if (requested_torque > MAX_TORQUE_NM) {
            requested_torque = MAX_TORQUE_NM;
        }

        /* Set motor torque */
        VCU_SetMotorTorque(requested_torque);

        /* Send response */
        SOMEIP_Message_t response;
        response.service_id = request->service_id;
        response.method_id = request->method_id;
        response.client_id = request->client_id;
        response.session_id = request->session_id;
        response.return_code = SOMEIP_RETURN_OK;
        response.payload_length = 0;

        SOMEIP_Send(&response);
    }
}
```

## Resource Sharing and Timing

### Hypervisor-Based Domain Isolation
```c
/* hypervisor_config.h - QNX Hypervisor partition configuration */

/* Chassis Domain - Guest VM #1 */
#define CHASSIS_DOMAIN_RAM_BASE 0x80000000
#define CHASSIS_DOMAIN_RAM_SIZE 512MB
#define CHASSIS_DOMAIN_CPU_MASK 0x03  /* CPU 0-1 */
#define CHASSIS_DOMAIN_PRIORITY CRITICAL

/* Powertrain Domain - Guest VM #2 */
#define POWERTRAIN_DOMAIN_RAM_BASE 0xA0000000
#define POWERTRAIN_DOMAIN_RAM_SIZE 512MB
#define POWERTRAIN_DOMAIN_CPU_MASK 0x0C  /* CPU 2-3 */
#define POWERTRAIN_DOMAIN_PRIORITY CRITICAL

/* Body Domain - Guest VM #3 */
#define BODY_DOMAIN_RAM_BASE 0xC0000000
#define BODY_DOMAIN_RAM_SIZE 256MB
#define BODY_DOMAIN_CPU_MASK 0x10  /* CPU 4 */
#define BODY_DOMAIN_PRIORITY NORMAL

/* ADAS Domain - Guest VM #4 (highest compute) */
#define ADAS_DOMAIN_RAM_BASE 0xD0000000
#define ADAS_DOMAIN_RAM_SIZE 2GB
#define ADAS_DOMAIN_CPU_MASK 0xE0  /* CPU 5-7 */
#define ADAS_DOMAIN_PRIORITY HIGH
```

## Benefits of Domain Controller Architecture
- **Reduced wiring harness complexity**: Fewer ECUs = less copper
- **Centralized computing**: More powerful processors, better performance
- **OTA update efficiency**: Update entire domain instead of individual ECUs
- **Cost reduction**: Consolidation reduces hardware costs
- **Scalability**: Easier to add features without new ECUs

## References
- AUTOSAR Adaptive Platform R22-11
- SOME/IP Protocol Specification v1.3
- QNX Hypervisor for Automotive
- ISO 21434: Road Vehicles - Cybersecurity Engineering
- ASAM OpenX: Service-Oriented Communication

## Common Issues
- Inter-domain latency exceeding real-time requirements
- Resource contention between domains on shared CPU cores
- SOME/IP service discovery failures
- Hypervisor overhead impacting deterministic timing
- Cross-domain debugging complexity

---

## Ivi Infotainment Systems

# IVI (In-Vehicle Infotainment) Systems

## Overview
The In-Vehicle Infotainment (IVI) system manages navigation, multimedia, connectivity (CarPlay/Android Auto), voice assistant, HMI frameworks (Qt/Flutter), and runs on Android Automotive OS, QNX, or Linux platforms.

## Platform Architectures

### 1. Android Automotive OS (AAOS)
```java
// VehicleHalService.java - Android Automotive HAL integration
package com.example.ivi;

import android.car.Car;
import android.car.VehiclePropertyIds;
import android.car.hardware.CarPropertyValue;
import android.car.hardware.property.CarPropertyManager;

public class VehicleHalService {
    private CarPropertyManager mCarPropertyManager;

    public void init(Context context) {
        Car car = Car.createCar(context);
        mCarPropertyManager = (CarPropertyManager) car.getCarManager(Car.PROPERTY_SERVICE);

        // Subscribe to vehicle speed updates
        mCarPropertyManager.registerCallback(
            new CarPropertyManager.CarPropertyEventCallback() {
                @Override
                public void onChangeEvent(CarPropertyValue value) {
                    if (value.getPropertyId() == VehiclePropertyIds.PERF_VEHICLE_SPEED) {
                        float speedMs = (Float) value.getValue();
                        updateSpeedUI(speedMs * 3.6f);  // Convert to km/h
                    }
                }

                @Override
                public void onErrorEvent(int propId, int zone) {
                    Log.e("VehicleHal", "Property error: " + propId);
                }
            },
            VehiclePropertyIds.PERF_VEHICLE_SPEED,
            CarPropertyManager.SENSOR_RATE_NORMAL);
    }

    public void setHvacTemperature(float tempCelsius) {
        mCarPropertyManager.setFloatProperty(
            VehiclePropertyIds.HVAC_TEMPERATURE_SET,
            VehicleAreaType.VEHICLE_AREA_TYPE_SEAT,
            tempCelsius);
    }
}
```

### 2. QNX-Based IVI
```c
/* qnx_ivi_service.c - QNX CAR platform integration */
#include <qnxcar/carcontrol.h>
#include <screen/screen.h>

void IVI_QNX_Init(void) {
    /* Initialize QNX CAR framework */
    car_control_t *control = car_control_create();

    /* Register for CAN message callbacks */
    car_control_set_can_callback(control, IVI_CAN_MessageHandler);

    /* Initialize Screen Graphics Subsystem */
    screen_context_t screen_ctx;
    screen_create_context(&screen_ctx, SCREEN_APPLICATION_CONTEXT);

    /* Create display window */
    screen_window_t window;
    screen_create_window(&window, screen_ctx);
    screen_set_window_property_iv(window, SCREEN_PROPERTY_SIZE, (int[]){1920, 1080});
}

void IVI_CAN_MessageHandler(car_can_message_t *msg) {
    if (msg->id == 0x100) {  /* VCU Motor Command */
        uint16_t torque = (msg->data[0] << 8) | msg->data[1];
        IVI_UpdatePowerMeter(torque);
    }
}
```

### 3. Navigation Integration (HERE/TomTom)
```kotlin
// NavigationService.kt - HERE SDK integration
package com.example.ivi.navigation

import com.here.sdk.core.GeoCoordinates
import com.here.sdk.routing.CalculateRouteCallback
import com.here.sdk.routing.Route
import com.here.sdk.routing.RoutingEngine

class NavigationService {
    private lateinit var routingEngine: RoutingEngine

    fun initialize() {
        routingEngine = RoutingEngine()
    }

    fun calculateRoute(
        origin: GeoCoordinates,
        destination: GeoCoordinates,
        callback: (Route?) -> Unit
    ) {
        val waypoints = listOf(
            Waypoint(origin),
            Waypoint(destination)
        )

        val carOptions = CarOptions().apply {
            routeOptions.alternatives = 3
            avoidanceOptions.avoidTollRoads = false
            optimizationMode = OptimizationMode.FASTEST
        }

        routingEngine.calculateRoute(waypoints, carOptions) { routingError, routes ->
            if (routingError == null && routes?.isNotEmpty() == true) {
                callback(routes[0])
            } else {
                callback(null)
            }
        }
    }
}
```

### 4. CarPlay/Android Auto Integration
```java
// AndroidAutoService.java - Android Auto projection
package com.example.ivi.projection;

import android.content.Intent;
import com.google.android.apps.auto.sdk.CarActivity;

public class AndroidAutoService extends CarActivity {
    @Override
    public void onCreate() {
        super.onCreate();

        // Start Android Auto projection
        Intent intent = new Intent("com.google.android.gms.car.PROJECTION_SERVICE");
        startService(intent);
    }

    @Override
    public void onCarConnectionStateChanged(int state) {
        if (state == CarConnection.STATE_CONNECTED) {
            // Phone connected: mirror Android Auto UI
            enableProjectionMode();
        }
    }
}
```

### 5. Voice Assistant Integration (Alexa/Google Assistant)
```python
# voice_assistant.py - Voice command handler
import speech_recognition as sr
import pyttsx3

class VoiceAssistant:
    def __init__(self):
        self.recognizer = sr.Recognizer()
        self.tts = pyttsx3.init()

    def listen_for_command(self):
        with sr.Microphone() as source:
            print("Listening...")
            audio = self.recognizer.listen(source)

        try:
            command = self.recognizer.recognize_google(audio)
            self.process_command(command)
        except sr.UnknownValueError:
            self.speak("Sorry, I didn't understand that.")

    def process_command(self, command):
        if "navigate to" in command.lower():
            destination = command.lower().replace("navigate to", "").strip()
            self.navigate(destination)
        elif "set temperature" in command.lower():
            temp = int(command.split()[-1])
            self.set_hvac_temperature(temp)

    def speak(self, text):
        self.tts.say(text)
        self.tts.runAndWait()
```

## HMI Framework (Qt QML)
```qml
/* DashboardView.qml - Main instrument cluster */
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 1920
    height: 720

    // Speedometer
    Item {
        id: speedometer
        x: 100
        y: 100

        Canvas {
            id: speedArc
            width: 400
            height: 400

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                // Draw arc for speed (0-240 km/h)
                ctx.beginPath();
                ctx.arc(200, 200, 150, 0.75 * Math.PI, (0.75 + 1.5 * (vehicleSpeed / 240)) * Math.PI);
                ctx.lineWidth = 20;
                ctx.strokeStyle = "#00FF00";
                ctx.stroke();
            }

            Connections {
                target: vehicleData
                onSpeedChanged: speedArc.requestPaint()
            }
        }

        Text {
            text: vehicleData.speed + " km/h"
            font.pixelSize: 48
            color: "white"
            anchors.centerIn: parent
        }
    }

    // Battery SOC gauge
    Rectangle {
        x: 600
        y: 100
        width: 300
        height: 50
        color: "transparent"
        border.color: "white"

        Rectangle {
            width: parent.width * (vehicleData.batterySOC / 100)
            height: parent.height
            color: vehicleData.batterySOC > 20 ? "#00FF00" : "#FF0000"
        }

        Text {
            text: vehicleData.batterySOC + "%"
            color: "white"
            anchors.centerIn: parent
        }
    }
}
```

## IVI CAN Interface (DBC)
```
VERSION ""

NS_ :

BS_:

BU_: IVI VCU BCM BMS

/* IVI User Commands */
BO_ 1024 IVI_UserCommand: 8 IVI
 SG_ IVI_DriveMode : 0|8@1+ (0,0) [0|3] ""  VCU
 SG_ IVI_ACTempSet : 8|8@1+ (0.5,10) [10|35] "C"  BCM
 SG_ IVI_ACFanSpeed : 16|8@1+ (0,0) [0|7] ""  BCM

VAL_ 1024 IVI_DriveMode 0 "Eco" 1 "Normal" 2 "Sport" 3 "Custom";
```

## References
- Android Automotive OS Developer Guide
- QNX CAR Platform API Reference
- HERE SDK for Automotive
- CarPlay App Programming Guide
- W3C Automotive Web Platform Specification

## Common Issues
- High CPU usage from rendering complex 3D gauges
- CarPlay/Android Auto disconnection during navigation
- Voice recognition accuracy in noisy cabin
- Slow boot time (> 10 seconds)

---

## Pdu Power Distribution

# PDU (Power Distribution Unit) - High/Low Voltage Power Management

## Overview
The Power Distribution Unit (PDU) manages high-voltage DC/DC converters, low-voltage power distribution, fuse/relay control, load shedding, power budgeting, battery voltage monitoring, and wake-up source management.

## Core Responsibilities

### 1. High-Voltage DC/DC Converter
```c
/* pdu_hv_dcdc.c - High-voltage to 12V DC/DC conversion */
#include "pdu_hv_dcdc.h"

#define HV_INPUT_MIN_V 200
#define HV_INPUT_MAX_V 450
#define LV_OUTPUT_TARGET_V 14.0
#define MAX_OUTPUT_CURRENT_A 150

typedef struct {
    uint16_t hv_input_voltage_v;
    float lv_output_voltage_v;
    float output_current_a;
    float efficiency_percent;
    bool enabled;
    bool fault_active;
} DCDC_State_t;

static DCDC_State_t g_dcdc = {0};

void PDU_DCDC_Init(void) {
    /* Configure PWM for DC/DC converter control */
    PWM_Init(PWM_CHANNEL_DCDC, 100000);  /* 100 kHz switching */

    /* Set initial duty cycle to 0 */
    PWM_SetDutyCycle(PWM_CHANNEL_DCDC, 0);

    g_dcdc.enabled = false;
}

void PDU_DCDC_Enable(void) {
    /* Safety checks */
    g_dcdc.hv_input_voltage_v = ADC_ReadHVInput();

    if (g_dcdc.hv_input_voltage_v < HV_INPUT_MIN_V ||
        g_dcdc.hv_input_voltage_v > HV_INPUT_MAX_V) {
        g_dcdc.fault_active = true;
        return;
    }

    /* Enable DC/DC converter */
    GPIO_Set(GPIO_DCDC_ENABLE, true);
    g_dcdc.enabled = true;

    /* Start voltage regulation loop */
    PDU_DCDC_RegulationLoop();
}

void PDU_DCDC_RegulationLoop(void) {
    /* PI controller for output voltage regulation */
    static float integral = 0;
    const float Kp = 0.5;
    const float Ki = 0.1;

    while (g_dcdc.enabled) {
        /* Read output voltage and current */
        g_dcdc.lv_output_voltage_v = ADC_ReadLVOutput();
        g_dcdc.output_current_a = ADC_ReadOutputCurrent();

        /* Calculate error */
        float error = LV_OUTPUT_TARGET_V - g_dcdc.lv_output_voltage_v;

        /* PI control */
        integral += error * 0.01;  /* 10ms loop time */
        float duty_cycle = (Kp * error) + (Ki * integral);

        /* Clamp duty cycle */
        if (duty_cycle > 95) duty_cycle = 95;
        if (duty_cycle < 5) duty_cycle = 5;

        PWM_SetDutyCycle(PWM_CHANNEL_DCDC, duty_cycle);

        /* Overcurrent protection */
        if (g_dcdc.output_current_a > MAX_OUTPUT_CURRENT_A) {
            PDU_DCDC_Disable();
            g_dcdc.fault_active = true;
            DTC_SetFault(DTC_DCDC_OVERCURRENT);
            break;
        }

        OsTask_Sleep(10);
    }
}

void PDU_DCDC_Disable(void) {
    PWM_SetDutyCycle(PWM_CHANNEL_DCDC, 0);
    GPIO_Set(GPIO_DCDC_ENABLE, false);
    g_dcdc.enabled = false;
}
```

### 2. Low-Voltage Power Distribution (Fuse/Relay Control)
```c
/* pdu_lv_distribution.c - 12V power distribution and load management */
#include "pdu_lv_distribution.h"

#define MAX_POWER_CHANNELS 16

typedef enum {
    LOAD_PRIORITY_CRITICAL = 0,    /* Safety: always on */
    LOAD_PRIORITY_HIGH,             /* Powertrain */
    LOAD_PRIORITY_MEDIUM,           /* Comfort */
    LOAD_PRIORITY_LOW               /* Infotainment */
} LoadPriority_t;

typedef struct {
    const char* name;
    uint8_t relay_pin;
    uint8_t current_sense_adc;
    float max_current_a;
    LoadPriority_t priority;
    bool enabled;
    float measured_current_a;
} PowerChannel_t;

static PowerChannel_t g_power_channels[MAX_POWER_CHANNELS] = {
    {"BCM", GPIO_RELAY_BCM, ADC_CH_BCM_CURRENT, 15.0, LOAD_PRIORITY_CRITICAL, true, 0},
    {"VCU", GPIO_RELAY_VCU, ADC_CH_VCU_CURRENT, 10.0, LOAD_PRIORITY_CRITICAL, true, 0},
    {"BMS", GPIO_RELAY_BMS, ADC_CH_BMS_CURRENT, 8.0, LOAD_PRIORITY_CRITICAL, true, 0},
    {"MCU", GPIO_RELAY_MCU, ADC_CH_MCU_CURRENT, 12.0, LOAD_PRIORITY_HIGH, true, 0},
    {"IVI", GPIO_RELAY_IVI, ADC_CH_IVI_CURRENT, 20.0, LOAD_PRIORITY_LOW, true, 0},
    {"HVAC", GPIO_RELAY_HVAC, ADC_CH_HVAC_CURRENT, 25.0, LOAD_PRIORITY_MEDIUM, true, 0},
    {"Headlights", GPIO_RELAY_LIGHTS, ADC_CH_LIGHTS_CURRENT, 10.0, LOAD_PRIORITY_HIGH, false, 0},
    {"USB_Ports", GPIO_RELAY_USB, ADC_CH_USB_CURRENT, 5.0, LOAD_PRIORITY_LOW, false, 0}
};

void PDU_LV_Init(void) {
    /* Initialize all relay control pins */
    for (int i = 0; i < MAX_POWER_CHANNELS; i++) {
        GPIO_ConfigOutput(g_power_channels[i].relay_pin);

        /* Enable critical and high priority loads by default */
        if (g_power_channels[i].priority <= LOAD_PRIORITY_HIGH) {
            PDU_LV_EnableChannel(i);
        }
    }
}

void PDU_LV_EnableChannel(uint8_t channel_id) {
    if (channel_id >= MAX_POWER_CHANNELS) return;

    GPIO_Set(g_power_channels[channel_id].relay_pin, true);
    g_power_channels[channel_id].enabled = true;
}

void PDU_LV_DisableChannel(uint8_t channel_id) {
    if (channel_id >= MAX_POWER_CHANNELS) return;

    GPIO_Set(g_power_channels[channel_id].relay_pin, false);
    g_power_channels[channel_id].enabled = false;
}

/* Monitor current and detect overcurrent faults */
void PDU_LV_MonitorCurrents(void) {
    for (int i = 0; i < MAX_POWER_CHANNELS; i++) {
        if (!g_power_channels[i].enabled) continue;

        /* Read current sensor (Hall effect sensor, 185mV/A) */
        uint16_t adc_value = ADC_Read(g_power_channels[i].current_sense_adc);
        float voltage_mv = (adc_value * 5000.0) / 4096.0;

        g_power_channels[i].measured_current_a = (voltage_mv - 2500.0) / 185.0;

        /* Check for overcurrent */
        if (g_power_channels[i].measured_current_a > g_power_channels[i].max_current_a) {
            /* Overcurrent detected: disable channel */
            PDU_LV_DisableChannel(i);
            DTC_SetFault(DTC_OVERCURRENT_BASE + i);

            /* Log event */
            Log("Overcurrent on %s: %.2f A (max %.2f A)",
                g_power_channels[i].name,
                g_power_channels[i].measured_current_a,
                g_power_channels[i].max_current_a);
        }
    }
}
```

### 3. Load Shedding (Power Budget Management)
```c
/* pdu_load_shedding.c - Intelligent load management under power constraints */
#include "pdu_load_shedding.h"

#define BATTERY_CRITICAL_VOLTAGE_V 11.0
#define BATTERY_LOW_VOLTAGE_V 11.5

void PDU_LoadShedding_Update(void) {
    float battery_voltage = ADC_ReadBatteryVoltage();
    float total_current = 0;

    /* Calculate total current draw */
    for (int i = 0; i < MAX_POWER_CHANNELS; i++) {
        if (g_power_channels[i].enabled) {
            total_current += g_power_channels[i].measured_current_a;
        }
    }

    /* Check if battery voltage is low */
    if (battery_voltage < BATTERY_CRITICAL_VOLTAGE_V) {
        /* Critical: shed all non-critical loads */
        for (int i = 0; i < MAX_POWER_CHANNELS; i++) {
            if (g_power_channels[i].priority > LOAD_PRIORITY_CRITICAL) {
                PDU_LV_DisableChannel(i);
            }
        }

        Log("Critical battery voltage: %.2f V - load shedding active", battery_voltage);

    } else if (battery_voltage < BATTERY_LOW_VOLTAGE_V) {
        /* Low: shed low-priority loads */
        for (int i = 0; i < MAX_POWER_CHANNELS; i++) {
            if (g_power_channels[i].priority >= LOAD_PRIORITY_LOW) {
                PDU_LV_DisableChannel(i);
            }
        }

        Log("Low battery voltage: %.2f V - reducing load", battery_voltage);
    }

    /* Check DC/DC converter output current limit */
    if (total_current > (MAX_OUTPUT_CURRENT_A * 0.9)) {
        /* Approaching limit: shed lowest priority loads */
        for (int i = MAX_POWER_CHANNELS - 1; i >= 0; i--) {
            if (g_power_channels[i].priority == LOAD_PRIORITY_LOW &&
                g_power_channels[i].enabled) {
                PDU_LV_DisableChannel(i);

                /* Recalculate total current */
                total_current -= g_power_channels[i].measured_current_a;

                if (total_current < (MAX_OUTPUT_CURRENT_A * 0.85)) {
                    break;  /* Sufficient headroom */
                }
            }
        }
    }
}
```

### 4. Wake-Up Source Management
```c
/* pdu_wakeup_sources.c - Network wake-up coordination */
#include "pdu_wakeup_sources.h"

#define WAKEUP_CAN_TIMEOUT_MS 100
#define SLEEP_DELAY_MS 5000

typedef enum {
    WAKEUP_SOURCE_CAN = 0,
    WAKEUP_SOURCE_LIN,
    WAKEUP_SOURCE_IGNITION,
    WAKEUP_SOURCE_DOOR,
    WAKEUP_SOURCE_TIMER,
    WAKEUP_SOURCE_COUNT
} WakeupSource_t;

static bool g_wakeup_pending[WAKEUP_SOURCE_COUNT] = {false};

void PDU_Wakeup_OnCANActivity(void) {
    g_wakeup_pending[WAKEUP_SOURCE_CAN] = true;

    /* Power up CAN transceivers */
    GPIO_Set(GPIO_CAN_POWERTRAIN_ENABLE, true);
    GPIO_Set(GPIO_CAN_CHASSIS_ENABLE, true);

    /* Notify ECUs of wake-up */
    CAN_SendWakeupNotification();
}

void PDU_Sleep_Prepare(void) {
    /* Wait for all ECUs to enter sleep */
    uint32_t start_time = GetSystemTime_ms();

    while ((GetSystemTime_ms() - start_time) < SLEEP_DELAY_MS) {
        /* Check for wake-up requests */
        for (int i = 0; i < WAKEUP_SOURCE_COUNT; i++) {
            if (g_wakeup_pending[i]) {
                /* Wake-up requested: abort sleep */
                return;
            }
        }
        OsTask_Sleep(10);
    }

    /* Enter sleep mode */
    PDU_EnterSleep();
}

void PDU_EnterSleep(void) {
    /* Disable non-critical power channels */
    for (int i = 0; i < MAX_POWER_CHANNELS; i++) {
        if (g_power_channels[i].priority > LOAD_PRIORITY_CRITICAL) {
            PDU_LV_DisableChannel(i);
        }
    }

    /* Configure wake-up sources */
    CAN_ConfigureWakeup(CAN_WAKEUP_ENABLED);
    GPIO_ConfigureWakeup(GPIO_IGNITION, GPIO_WAKEUP_RISING_EDGE);

    /* Enter low-power mode */
    Mcu_SetMode(MCU_MODE_SLEEP);
}
```

## PDU CAN Database (DBC)
```
VERSION ""

NS_ :

BS_:

BU_: PDU VCU BMS BCM

/* PDU Power Status */
BO_ 896 PDU_PowerStatus: 8 PDU
 SG_ PDU_BatteryVoltage_V : 0|16@1+ (0.01,0) [0|16] "V"  VCU,BMS
 SG_ PDU_DCDCOutputCurrent_A : 16|16@1+ (0.1,0) [0|200] "A"  VCU
 SG_ PDU_LoadSheddingActive : 32|1@1+ (0,0) [0|1] ""  VCU,BCM
 SG_ PDU_PowerChannelStatus : 40|16@1+ (0,0) [0|65535] ""  VCU

/* Each bit in PowerChannelStatus represents one load (0=off, 1=on) */
```

## References
- LTC3780: High-Voltage Buck-Boost DC/DC Controller
- ISO 16750: Road vehicles - Environmental conditions and testing for electrical and electronic equipment
- SAE J1455: Recommended Environmental Practices for Electronic Equipment Design
- IEC 61000-4-2: EMC Immunity to Electrostatic Discharge

## Common Issues
- DC/DC converter instability at high loads
- Relay contact welding from inrush current
- False overcurrent detection from current sensor noise
- Wake-up failures due to CAN transceiver not powered

---

## Tcu Telematics Connectivity

# TCU (Telematics Control Unit) - Connectivity and Remote Services

## Overview
The Telematics Control Unit (TCU) provides 4G/5G cellular connectivity, GNSS positioning, remote diagnostics, OTA updates, eCall/bCall emergency services, and fleet management integration. This skill covers production-ready TCU development with modem integration.

## Core Responsibilities

### 1. 4G/5G Modem Integration
```c
/* tcu_modem_manager.c - Cellular modem control (Quectel/Sierra Wireless) */
#include "tcu_modem_manager.h"
#include <string.h>
#include <stdio.h>

#define MODEM_UART_PORT "/dev/ttyUSB2"
#define MODEM_BAUD_RATE 115200
#define AT_COMMAND_TIMEOUT_MS 5000
#define MAX_AT_RESPONSE_LENGTH 512

typedef enum {
    MODEM_STATE_OFF = 0,
    MODEM_STATE_INITIALIZING,
    MODEM_STATE_REGISTERING,
    MODEM_STATE_CONNECTED,
    MODEM_STATE_ERROR
} ModemState_t;

typedef struct {
    int uart_fd;
    ModemState_t state;
    char imei[16];
    char iccid[21];
    int signal_strength_dbm;
    char network_operator[32];
    char ip_address[16];
    bool data_session_active;
} ModemContext_t;

static ModemContext_t g_modem = {0};

/* AT command send/receive */
bool TCU_Modem_SendATCommand(const char* cmd, char* response, uint16_t response_size) {
    /* Send AT command */
    char cmd_buffer[128];
    snprintf(cmd_buffer, sizeof(cmd_buffer), "%s\r\n", cmd);

    int bytes_written = write(g_modem.uart_fd, cmd_buffer, strlen(cmd_buffer));
    if (bytes_written < 0) {
        return false;
    }

    /* Wait for response */
    uint32_t start_time = GetSystemTime_ms();
    int total_bytes = 0;

    while ((GetSystemTime_ms() - start_time) < AT_COMMAND_TIMEOUT_MS) {
        int bytes_available = 0;
        ioctl(g_modem.uart_fd, FIONREAD, &bytes_available);

        if (bytes_available > 0) {
            int bytes_read = read(g_modem.uart_fd,
                                   &response[total_bytes],
                                   response_size - total_bytes - 1);
            if (bytes_read > 0) {
                total_bytes += bytes_read;
                response[total_bytes] = '\0';

                /* Check for "OK" or "ERROR" */
                if (strstr(response, "OK\r\n") != NULL) {
                    return true;
                }
                if (strstr(response, "ERROR\r\n") != NULL) {
                    return false;
                }
            }
        }

        usleep(10000);  /* 10ms polling interval */
    }

    return false;  /* Timeout */
}

void TCU_Modem_Init(void) {
    /* Open UART port */
    g_modem.uart_fd = open(MODEM_UART_PORT, O_RDWR | O_NOCTTY);
    if (g_modem.uart_fd < 0) {
        g_modem.state = MODEM_STATE_ERROR;
        return;
    }

    /* Configure UART: 115200 8N1 */
    struct termios tty;
    tcgetattr(g_modem.uart_fd, &tty);
    cfsetospeed(&tty, B115200);
    cfsetispeed(&tty, B115200);
    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
    tty.c_cflag &= ~PARENB;
    tty.c_cflag &= ~CSTOPB;
    tcsetattr(g_modem.uart_fd, TCSANOW, &tty);

    g_modem.state = MODEM_STATE_INITIALIZING;

    char response[MAX_AT_RESPONSE_LENGTH];

    /* Basic AT command check */
    if (!TCU_Modem_SendATCommand("AT", response, sizeof(response))) {
        g_modem.state = MODEM_STATE_ERROR;
        return;
    }

    /* Disable echo */
    TCU_Modem_SendATCommand("ATE0", response, sizeof(response));

    /* Get IMEI */
    if (TCU_Modem_SendATCommand("AT+GSN", response, sizeof(response))) {
        sscanf(response, "%15s", g_modem.imei);
    }

    /* Get ICCID (SIM card ID) */
    if (TCU_Modem_SendATCommand("AT+CCID", response, sizeof(response))) {
        sscanf(response, "+CCID: %20s", g_modem.iccid);
    }

    /* Check SIM status */
    if (!TCU_Modem_SendATCommand("AT+CPIN?", response, sizeof(response))) {
        g_modem.state = MODEM_STATE_ERROR;
        return;
    }

    /* Start network registration */
    TCU_Modem_StartNetworkRegistration();
}

void TCU_Modem_StartNetworkRegistration(void) {
    char response[MAX_AT_RESPONSE_LENGTH];

    /* Set network mode: LTE only for 4G, NR+LTE for 5G */
    TCU_Modem_SendATCommand("AT+QCFG=\"nwscanmode\",3", response, sizeof(response));

    /* Enable network registration URC */
    TCU_Modem_SendATCommand("AT+CREG=2", response, sizeof(response));

    /* Check registration status */
    if (TCU_Modem_SendATCommand("AT+CREG?", response, sizeof(response))) {
        int n, stat;
        if (sscanf(response, "+CREG: %d,%d", &n, &stat) == 2) {
            if (stat == 1 || stat == 5) {  /* Registered (home or roaming) */
                g_modem.state = MODEM_STATE_REGISTERED;
                TCU_Modem_GetNetworkInfo();
            } else {
                g_modem.state = MODEM_STATE_REGISTERING;
            }
        }
    }
}

void TCU_Modem_GetNetworkInfo(void) {
    char response[MAX_AT_RESPONSE_LENGTH];

    /* Get signal strength */
    if (TCU_Modem_SendATCommand("AT+CSQ", response, sizeof(response))) {
        int rssi, ber;
        if (sscanf(response, "+CSQ: %d,%d", &rssi, &ber) == 2) {
            /* Convert RSSI to dBm: dBm = -113 + 2*rssi */
            g_modem.signal_strength_dbm = -113 + (2 * rssi);
        }
    }

    /* Get operator name */
    if (TCU_Modem_SendATCommand("AT+COPS?", response, sizeof(response))) {
        char operator_name[32];
        if (sscanf(response, "+COPS: 0,0,\"%31[^\"]\"", operator_name) == 1) {
            strncpy(g_modem.network_operator, operator_name, sizeof(g_modem.network_operator));
        }
    }
}

bool TCU_Modem_StartDataSession(const char* apn) {
    char response[MAX_AT_RESPONSE_LENGTH];
    char cmd[128];

    /* Configure PDP context */
    snprintf(cmd, sizeof(cmd), "AT+QICSGP=1,1,\"%s\",\"\",\"\",1", apn);
    if (!TCU_Modem_SendATCommand(cmd, response, sizeof(response))) {
        return false;
    }

    /* Activate PDP context */
    if (!TCU_Modem_SendATCommand("AT+QIACT=1", response, sizeof(response))) {
        return false;
    }

    /* Get IP address */
    if (TCU_Modem_SendATCommand("AT+QIACT?", response, sizeof(response))) {
        char ip_addr[16];
        if (sscanf(response, "+QIACT: 1,1,1,\"%15[^\"]\"", ip_addr) == 1) {
            strncpy(g_modem.ip_address, ip_addr, sizeof(g_modem.ip_address));
            g_modem.data_session_active = true;
            g_modem.state = MODEM_STATE_CONNECTED;
            return true;
        }
    }

    return false;
}

/* HTTP client for cloud connectivity */
bool TCU_Modem_HTTPPost(const char* url, const char* json_payload, char* response) {
    char cmd[256];
    char at_response[MAX_AT_RESPONSE_LENGTH];

    /* Configure HTTP context */
    snprintf(cmd, sizeof(cmd), "AT+QHTTPCFG=\"contextid\",1");
    TCU_Modem_SendATCommand(cmd, at_response, sizeof(at_response));

    /* Set URL */
    snprintf(cmd, sizeof(cmd), "AT+QHTTPURL=%zu,80", strlen(url));
    TCU_Modem_SendATCommand(cmd, at_response, sizeof(at_response));

    /* Send URL */
    write(g_modem.uart_fd, url, strlen(url));
    usleep(100000);

    /* POST data */
    snprintf(cmd, sizeof(cmd), "AT+QHTTPPOST=%zu,80,80", strlen(json_payload));
    TCU_Modem_SendATCommand(cmd, at_response, sizeof(at_response));

    /* Send payload */
    write(g_modem.uart_fd, json_payload, strlen(json_payload));

    /* Wait for response */
    sleep(2);

    /* Read response */
    TCU_Modem_SendATCommand("AT+QHTTPREAD=80", response, MAX_AT_RESPONSE_LENGTH);

    return true;
}
```

### 2. GNSS/GPS Position Tracking
```c
/* tcu_gnss_manager.c - GPS/GLONASS/BeiDou positioning */
#include "tcu_gnss_manager.h"
#include <math.h>

#define EARTH_RADIUS_KM 6371.0

typedef struct {
    double latitude;
    double longitude;
    float altitude_m;
    float speed_kph;
    float heading_deg;
    uint8_t satellites_used;
    float hdop;  /* Horizontal dilution of precision */
    bool fix_valid;
    uint32_t timestamp_ms;
} GNSSPosition_t;

static GNSSPosition_t g_gnss_position = {0};

void TCU_GNSS_Init(void) {
    char response[MAX_AT_RESPONSE_LENGTH];

    /* Enable GNSS */
    TCU_Modem_SendATCommand("AT+QGPS=1", response, sizeof(response));

    /* Configure GNSS to use GPS+GLONASS+BeiDou */
    TCU_Modem_SendATCommand("AT+QGPSCFG=\"gnssconfig\",7", response, sizeof(response));
}

bool TCU_GNSS_GetPosition(GNSSPosition_t* position) {
    char response[MAX_AT_RESPONSE_LENGTH];

    /* Query GNSS position */
    if (!TCU_Modem_SendATCommand("AT+QGPSLOC=2", response, sizeof(response))) {
        return false;
    }

    /* Parse NMEA-like response: +QGPSLOC: <time>,<lat>,<lon>,<hdop>,<alt>,<fix>,<cog>,<spkm>,<spkn>,<date>,<nsat> */
    char time_str[16], date_str[16];
    int fix_type, nsat;

    int parsed = sscanf(response,
                        "+QGPSLOC: %15[^,],%lf,%lf,%f,%f,%d,%f,%f,%*f,%15[^,],%d",
                        time_str,
                        &position->latitude,
                        &position->longitude,
                        &position->hdop,
                        &position->altitude_m,
                        &fix_type,
                        &position->heading_deg,
                        &position->speed_kph,
                        date_str,
                        &nsat);

    if (parsed >= 9) {
        position->satellites_used = nsat;
        position->fix_valid = (fix_type >= 2);  /* 2D or 3D fix */
        position->timestamp_ms = GetSystemTime_ms();

        /* Update global position */
        memcpy(&g_gnss_position, position, sizeof(GNSSPosition_t));

        return true;
    }

    return false;
}

/* Calculate distance between two GPS coordinates (Haversine formula) */
float TCU_GNSS_CalculateDistance_km(double lat1, double lon1, double lat2, double lon2) {
    double dLat = (lat2 - lat1) * M_PI / 180.0;
    double dLon = (lon2 - lon1) * M_PI / 180.0;

    lat1 = lat1 * M_PI / 180.0;
    lat2 = lat2 * M_PI / 180.0;

    double a = sin(dLat / 2) * sin(dLat / 2) +
               sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return EARTH_RADIUS_KM * c;
}

/* Geofencing: check if vehicle is inside defined boundary */
bool TCU_GNSS_IsInsideGeofence(double center_lat, double center_lon, float radius_km) {
    if (!g_gnss_position.fix_valid) {
        return false;
    }

    float distance = TCU_GNSS_CalculateDistance_km(
        g_gnss_position.latitude,
        g_gnss_position.longitude,
        center_lat,
        center_lon);

    return (distance <= radius_km);
}
```

### 3. Remote Diagnostics (UDS over HTTP)
```c
/* tcu_remote_diagnostics.c - Cloud-based diagnostic services */
#include "tcu_remote_diagnostics.h"
#include "json.h"

#define CLOUD_DIAGNOSTICS_URL "https://telemetry.example.com/api/v1/diagnostics"

typedef struct {
    uint32_t dtc_code;
    uint8_t status;
    uint32_t occurrence_count;
    uint32_t first_occurrence_timestamp;
} DTC_Entry_t;

void TCU_RemoteDiagnostics_SendDTCs(void) {
    /* Read DTCs from all ECUs via CAN */
    DTC_Entry_t dtc_list[32];
    uint8_t dtc_count = 0;

    /* Query VCU for DTCs */
    uint8_t uds_request[] = {0x19, 0x02, 0xFF};  /* ReadDTCByStatusMask */
    uint8_t uds_response[256];
    uint16_t response_length;

    if (UDS_SendRequest(VCU_DIAGNOSTIC_ADDR, uds_request, 3,
                        uds_response, &response_length)) {
        /* Parse DTC response */
        for (int i = 3; i < response_length; i += 4) {
            dtc_list[dtc_count].dtc_code = (uds_response[i] << 16) |
                                            (uds_response[i+1] << 8) |
                                            uds_response[i+2];
            dtc_list[dtc_count].status = uds_response[i+3];
            dtc_count++;
        }
    }

    /* Build JSON payload */
    char json_payload[1024];
    snprintf(json_payload, sizeof(json_payload),
             "{"
             "\"vin\":\"%s\","
             "\"timestamp\":%u,"
             "\"dtcs\":[",
             g_vehicle_vin,
             GetSystemTime_ms());

    for (int i = 0; i < dtc_count; i++) {
        char dtc_entry[128];
        snprintf(dtc_entry, sizeof(dtc_entry),
                 "{\"code\":\"0x%06X\",\"status\":0x%02X}%s",
                 dtc_list[i].dtc_code,
                 dtc_list[i].status,
                 (i < dtc_count - 1) ? "," : "");
        strcat(json_payload, dtc_entry);
    }

    strcat(json_payload, "]}");

    /* Send to cloud via HTTPS */
    char response[512];
    TCU_Modem_HTTPPost(CLOUD_DIAGNOSTICS_URL, json_payload, response);
}

void TCU_RemoteDiagnostics_ExecuteCommand(const char* command_json) {
    /* Parse remote diagnostic command */
    json_object* root = json_tokener_parse(command_json);
    json_object* cmd_type_obj = json_object_object_get(root, "command");

    const char* cmd_type = json_object_get_string(cmd_type_obj);

    if (strcmp(cmd_type, "READ_DTC") == 0) {
        TCU_RemoteDiagnostics_SendDTCs();
    } else if (strcmp(cmd_type, "CLEAR_DTC") == 0) {
        /* Send UDS ClearDiagnosticInformation */
        uint8_t uds_clear_dtc[] = {0x14, 0xFF, 0xFF, 0xFF};
        uint8_t response[8];
        uint16_t response_length;
        UDS_SendRequest(VCU_DIAGNOSTIC_ADDR, uds_clear_dtc, 4, response, &response_length);
    } else if (strcmp(cmd_type, "READ_DATA") == 0) {
        /* Read live data via UDS ReadDataByIdentifier */
        json_object* did_obj = json_object_object_get(root, "did");
        uint16_t did = json_object_get_int(did_obj);

        uint8_t uds_read_data[] = {0x22, (did >> 8) & 0xFF, did & 0xFF};
        uint8_t response[256];
        uint16_t response_length;

        if (UDS_SendRequest(VCU_DIAGNOSTIC_ADDR, uds_read_data, 3,
                            response, &response_length)) {
            /* Send response back to cloud */
            char response_json[512];
            snprintf(response_json, sizeof(response_json),
                     "{\"vin\":\"%s\",\"did\":\"0x%04X\",\"data\":\"",
                     g_vehicle_vin, did);

            for (int i = 0; i < response_length; i++) {
                char hex[4];
                snprintf(hex, sizeof(hex), "%02X", response[i]);
                strcat(response_json, hex);
            }

            strcat(response_json, "\"}");
            TCU_Modem_HTTPPost(CLOUD_DIAGNOSTICS_URL, response_json, NULL);
        }
    }

    json_object_put(root);
}
```

### 4. eCall / bCall Emergency Services
```c
/* tcu_ecall.c - Automatic emergency call (eCall) - EU regulation */
#include "tcu_ecall.h"

#define ECALL_EMERGENCY_NUMBER "112"
#define BCALL_ROADSIDE_NUMBER "1234567890"

typedef struct {
    uint8_t msd_format_version;
    uint8_t message_identifier;
    uint32_t timestamp;
    double latitude;
    double longitude;
    uint8_t vehicle_class;
    char vin[18];
    uint8_t propulsion_storage_type;
    bool recent_engine_status;
} MSD_t;  /* Minimum Set of Data for eCall */

void TCU_eCall_Trigger(bool automatic) {
    /* Build MSD (Minimum Set of Data) */
    MSD_t msd = {0};
    msd.msd_format_version = 1;
    msd.message_identifier = automatic ? 1 : 2;  /* 1=automatic, 2=manual */
    msd.timestamp = GetSystemTime_ms() / 1000;

    /* Get current GPS position */
    GNSSPosition_t position;
    if (TCU_GNSS_GetPosition(&position)) {
        msd.latitude = position.latitude;
        msd.longitude = position.longitude;
    }

    msd.vehicle_class = 1;  /* M1 (passenger car) */
    strncpy(msd.vin, g_vehicle_vin, sizeof(msd.vin));
    msd.propulsion_storage_type = 0x05;  /* Electric */
    msd.recent_engine_status = VCU_IsVehicleOn();

    /* Encode MSD to ASN.1 format */
    uint8_t msd_encoded[140];  /* Max 140 bytes for MSD */
    uint16_t msd_length = TCU_eCall_EncodeMSD(&msd, msd_encoded);

    /* Initiate voice call to emergency services */
    char at_cmd[64];
    char response[MAX_AT_RESPONSE_LENGTH];

    snprintf(at_cmd, sizeof(at_cmd), "ATD%s;", ECALL_EMERGENCY_NUMBER);
    TCU_Modem_SendATCommand(at_cmd, response, sizeof(response));

    /* Wait for call connection */
    sleep(3);

    /* Send MSD over in-band modem (IVS - In-Vehicle System) */
    TCU_eCall_SendMSDInBand(msd_encoded, msd_length);

    /* Keep call active for voice communication */
    /* Operator will speak with occupants if possible */
}

void TCU_bCall_Trigger(void) {
    /* Breakdown call: non-emergency roadside assistance */
    char at_cmd[64];
    char response[MAX_AT_RESPONSE_LENGTH];

    snprintf(at_cmd, sizeof(at_cmd), "ATD%s;", BCALL_ROADSIDE_NUMBER);
    TCU_Modem_SendATCommand(at_cmd, response, sizeof(response));

    /* Send vehicle data to roadside assistance */
    char json_payload[512];
    GNSSPosition_t position;
    TCU_GNSS_GetPosition(&position);

    snprintf(json_payload, sizeof(json_payload),
             "{"
             "\"vin\":\"%s\","
             "\"latitude\":%.6f,"
             "\"longitude\":%.6f,"
             "\"issue\":\"Breakdown assistance requested\""
             "}",
             g_vehicle_vin,
             position.latitude,
             position.longitude);

    TCU_Modem_HTTPPost("https://roadside.example.com/api/assist", json_payload, NULL);
}
```

### 5. OTA Download Manager
```c
/* tcu_ota_manager.c - Over-the-Air software updates */
#include "tcu_ota_manager.h"

#define OTA_SERVER_URL "https://ota.example.com/api/v1/updates"
#define OTA_CHUNK_SIZE 4096

typedef struct {
    char version[16];
    char ecu_target[32];
    uint32_t file_size;
    char download_url[256];
    uint8_t sha256_hash[32];
} OTAPackage_t;

typedef struct {
    bool update_available;
    OTAPackage_t package;
    uint32_t bytes_downloaded;
    uint8_t download_progress_percent;
    bool download_complete;
} OTAState_t;

static OTAState_t g_ota_state = {0};

bool TCU_OTA_CheckForUpdates(void) {
    /* Query OTA server for available updates */
    char json_request[256];
    snprintf(json_request, sizeof(json_request),
             "{\"vin\":\"%s\",\"current_versions\":{"
             "\"vcu\":\"1.2.3\",\"bms\":\"2.0.1\",\"mcu\":\"3.1.0\""
             "}}",
             g_vehicle_vin);

    char response[1024];
    if (!TCU_Modem_HTTPPost(OTA_SERVER_URL, json_request, response)) {
        return false;
    }

    /* Parse JSON response */
    json_object* root = json_tokener_parse(response);
    json_object* update_available_obj = json_object_object_get(root, "update_available");

    if (json_object_get_boolean(update_available_obj)) {
        json_object* package_obj = json_object_object_get(root, "package");

        /* Extract package info */
        json_object* version_obj = json_object_object_get(package_obj, "version");
        json_object* ecu_obj = json_object_object_get(package_obj, "ecu");
        json_object* size_obj = json_object_object_get(package_obj, "size");
        json_object* url_obj = json_object_object_get(package_obj, "url");

        strncpy(g_ota_state.package.version,
                json_object_get_string(version_obj),
                sizeof(g_ota_state.package.version));

        strncpy(g_ota_state.package.ecu_target,
                json_object_get_string(ecu_obj),
                sizeof(g_ota_state.package.ecu_target));

        g_ota_state.package.file_size = json_object_get_int(size_obj);

        strncpy(g_ota_state.package.download_url,
                json_object_get_string(url_obj),
                sizeof(g_ota_state.package.download_url));

        g_ota_state.update_available = true;

        json_object_put(root);
        return true;
    }

    json_object_put(root);
    return false;
}

bool TCU_OTA_DownloadPackage(void) {
    if (!g_ota_state.update_available) {
        return false;
    }

    /* Open file for writing */
    int fd = open("/data/ota/update.bin", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd < 0) {
        return false;
    }

    /* Download in chunks */
    uint32_t offset = 0;
    uint8_t buffer[OTA_CHUNK_SIZE];

    while (offset < g_ota_state.package.file_size) {
        uint32_t chunk_size = (g_ota_state.package.file_size - offset) > OTA_CHUNK_SIZE ?
                               OTA_CHUNK_SIZE : (g_ota_state.package.file_size - offset);

        /* HTTP range request */
        char range_header[64];
        snprintf(range_header, sizeof(range_header),
                 "Range: bytes=%u-%u", offset, offset + chunk_size - 1);

        /* Download chunk (simplified - use libcurl in production) */
        if (!TCU_HTTP_DownloadChunk(g_ota_state.package.download_url,
                                      range_header, buffer, chunk_size)) {
            close(fd);
            return false;
        }

        /* Write to file */
        write(fd, buffer, chunk_size);

        offset += chunk_size;
        g_ota_state.bytes_downloaded = offset;
        g_ota_state.download_progress_percent =
            (offset * 100) / g_ota_state.package.file_size;

        /* Notify user via CAN */
        CAN_SendOTAProgress(g_ota_state.download_progress_percent);
    }

    close(fd);
    g_ota_state.download_complete = true;

    /* Verify SHA256 hash */
    uint8_t calculated_hash[32];
    TCU_OTA_CalculateSHA256("/data/ota/update.bin", calculated_hash);

    if (memcmp(calculated_hash, g_ota_state.package.sha256_hash, 32) != 0) {
        /* Hash mismatch: corrupted download */
        unlink("/data/ota/update.bin");
        return false;
    }

    return true;
}

void TCU_OTA_InstallPackage(void) {
    /* Flash update to target ECU */
    if (strcmp(g_ota_state.package.ecu_target, "VCU") == 0) {
        /* Flash VCU via UDS RequestDownload / TransferData / RequestTransferExit */
        TCU_OTA_FlashECU(VCU_DIAGNOSTIC_ADDR, "/data/ota/update.bin");
    } else if (strcmp(g_ota_state.package.ecu_target, "BMS") == 0) {
        TCU_OTA_FlashECU(BMS_DIAGNOSTIC_ADDR, "/data/ota/update.bin");
    }

    /* Cleanup */
    unlink("/data/ota/update.bin");
    memset(&g_ota_state, 0, sizeof(OTAState_t));
}
```

## TCU CAN Database (DBC)
```
VERSION ""

NS_ :

BS_:

BU_: TCU VCU BCM IVI

/* TCU Status */
BO_ 768 TCU_Status: 8 TCU
 SG_ TCU_ModemState : 0|8@1+ (0,0) [0|4] ""  VCU,IVI
 SG_ TCU_SignalStrength_dBm : 8|8@1- (-113,0) [-113|0] "dBm"  IVI
 SG_ TCU_DataSessionActive : 16|1@1+ (0,0) [0|1] ""  IVI
 SG_ TCU_GNSSFixValid : 17|1@1+ (0,0) [0|1] ""  VCU,IVI
 SG_ TCU_SatellitesUsed : 24|8@1+ (0,0) [0|32] ""  IVI
 SG_ TCU_OTAUpdateAvailable : 32|1@1+ (0,0) [0|1] ""  IVI
 SG_ TCU_OTADownloadProgress : 40|8@1+ (0,0) [0|100] "%"  IVI

/* TCU GPS Position */
BO_ 769 TCU_Position: 8 TCU
 SG_ TCU_Latitude : 0|32@1+ (0.0000001,-90) [-90|90] "deg"  VCU,IVI
 SG_ TCU_Longitude : 32|32@1+ (0.0000001,-180) [-180|180] "deg"  VCU,IVI

/* TCU Speed and Heading */
BO_ 770 TCU_Navigation: 8 TCU
 SG_ TCU_GPSSpeed_kph : 0|16@1+ (0.01,0) [0|300] "km/h"  VCU,IVI
 SG_ TCU_Heading_deg : 16|16@1+ (0.01,0) [0|360] "deg"  VCU,IVI
 SG_ TCU_Altitude_m : 32|16@1+ (0.1,-500) [-500|9000] "m"  IVI
 SG_ TCU_HDOP : 48|8@1+ (0.1,0) [0|25] ""  IVI

VAL_ 768 TCU_ModemState 0 "Off" 1 "Initializing" 2 "Registering" 3 "Connected" 4 "Error";
```

## References
- 3GPP TS 24.008: Mobile radio interface Layer 3 specification
- ETSI EN 16072: eCall Minimum Set of Data (MSD)
- ISO 17987: Local Interconnect Network (LIN)
- MQTT Protocol Specification v5.0
- AWS IoT Core: Fleet Provisioning

## Common Issues
- Modem not responding to AT commands (baud rate mismatch)
- GPS fix lost in urban canyons or underground parking
- OTA download interrupted due to poor signal strength
- eCall MSD encoding errors
- Data session dropped during handover between cell towers

---

## Vcu Vehicle Control

# VCU (Vehicle Control Unit) for Electric Vehicles

## Overview
The Vehicle Control Unit (VCU) is the central brain for electric vehicles, managing torque arbitration, drive modes, power distribution, regenerative braking, and traction control. This skill covers production-ready VCU development with AUTOSAR BSW integration.

## Core Responsibilities

### 1. Torque Arbitration
```c
/* vcu_torque_arbiter.c - Multi-source torque request arbitration */
#include "vcu_torque_arbiter.h"
#include "autosar_rte.h"
#include <stdint.h>
#include <stdbool.h>

#define MAX_TORQUE_NM 400
#define MIN_REGEN_TORQUE_NM -200
#define TORQUE_RATE_LIMIT_NM_PER_100MS 50

typedef enum {
    TORQUE_SOURCE_DRIVER = 0,
    TORQUE_SOURCE_CRUISE_CONTROL,
    TORQUE_SOURCE_TRACTION_CONTROL,
    TORQUE_SOURCE_STABILITY_CONTROL,
    TORQUE_SOURCE_POWER_LIMIT,
    TORQUE_SOURCE_THERMAL_LIMIT,
    TORQUE_SOURCE_COUNT
} TorqueSource_t;

typedef struct {
    int16_t requested_torque_nm;
    uint8_t priority;
    bool active;
    uint32_t timestamp_ms;
} TorqueRequest_t;

typedef struct {
    TorqueRequest_t requests[TORQUE_SOURCE_COUNT];
    int16_t arbitrated_torque_nm;
    int16_t previous_torque_nm;
    TorqueSource_t active_source;
} TorqueArbiter_t;

static TorqueArbiter_t g_torque_arbiter = {0};

/* Priority levels (higher number = higher priority) */
static const uint8_t TORQUE_PRIORITIES[TORQUE_SOURCE_COUNT] = {
    [TORQUE_SOURCE_DRIVER] = 1,
    [TORQUE_SOURCE_CRUISE_CONTROL] = 2,
    [TORQUE_SOURCE_TRACTION_CONTROL] = 5,  /* Safety critical */
    [TORQUE_SOURCE_STABILITY_CONTROL] = 6, /* Highest priority */
    [TORQUE_SOURCE_POWER_LIMIT] = 4,
    [TORQUE_SOURCE_THERMAL_LIMIT] = 3
};

void VCU_TorqueArbiter_Init(void) {
    memset(&g_torque_arbiter, 0, sizeof(TorqueArbiter_t));

    /* Initialize priorities */
    for (int i = 0; i < TORQUE_SOURCE_COUNT; i++) {
        g_torque_arbiter.requests[i].priority = TORQUE_PRIORITIES[i];
    }
}

void VCU_TorqueArbiter_SetRequest(TorqueSource_t source, int16_t torque_nm, bool active) {
    if (source >= TORQUE_SOURCE_COUNT) return;

    /* Clamp torque to physical limits */
    if (torque_nm > MAX_TORQUE_NM) torque_nm = MAX_TORQUE_NM;
    if (torque_nm < MIN_REGEN_TORQUE_NM) torque_nm = MIN_REGEN_TORQUE_NM;

    g_torque_arbiter.requests[source].requested_torque_nm = torque_nm;
    g_torque_arbiter.requests[source].active = active;
    g_torque_arbiter.requests[source].timestamp_ms = GetSystemTime_ms();
}

int16_t VCU_TorqueArbiter_Arbitrate(void) {
    int16_t result_torque = 0;
    uint8_t highest_priority = 0;
    TorqueSource_t active_source = TORQUE_SOURCE_DRIVER;

    /* Find highest priority active request */
    for (int i = 0; i < TORQUE_SOURCE_COUNT; i++) {
        if (g_torque_arbiter.requests[i].active &&
            g_torque_arbiter.requests[i].priority > highest_priority) {
            highest_priority = g_torque_arbiter.requests[i].priority;
            result_torque = g_torque_arbiter.requests[i].requested_torque_nm;
            active_source = (TorqueSource_t)i;
        }
    }

    /* Apply rate limiter for smoothness */
    int16_t delta = result_torque - g_torque_arbiter.previous_torque_nm;
    if (delta > TORQUE_RATE_LIMIT_NM_PER_100MS) {
        result_torque = g_torque_arbiter.previous_torque_nm + TORQUE_RATE_LIMIT_NM_PER_100MS;
    } else if (delta < -TORQUE_RATE_LIMIT_NM_PER_100MS) {
        result_torque = g_torque_arbiter.previous_torque_nm - TORQUE_RATE_LIMIT_NM_PER_100MS;
    }

    g_torque_arbiter.arbitrated_torque_nm = result_torque;
    g_torque_arbiter.previous_torque_nm = result_torque;
    g_torque_arbiter.active_source = active_source;

    /* Send to motor controller via CAN */
    Rte_Write_MotorTorqueCmd_torque(result_torque);

    return result_torque;
}
```

### 2. Drive Modes (Eco/Sport/Custom)
```c
/* vcu_drive_modes.c - Drive mode management */
#include "vcu_drive_modes.h"

typedef enum {
    DRIVE_MODE_ECO = 0,
    DRIVE_MODE_NORMAL,
    DRIVE_MODE_SPORT,
    DRIVE_MODE_CUSTOM
} DriveMode_t;

typedef struct {
    uint8_t max_power_percent;       /* 0-100% */
    uint8_t throttle_response;       /* 0-100%, sensitivity */
    uint8_t regen_strength;          /* 0-100%, aggressive regen */
    uint8_t ac_power_limit_percent;  /* HVAC power limit */
} DriveModeProfile_t;

static const DriveModeProfile_t DRIVE_MODE_PROFILES[] = {
    [DRIVE_MODE_ECO] = {
        .max_power_percent = 70,
        .throttle_response = 50,
        .regen_strength = 80,
        .ac_power_limit_percent = 50
    },
    [DRIVE_MODE_NORMAL] = {
        .max_power_percent = 90,
        .throttle_response = 70,
        .regen_strength = 60,
        .ac_power_limit_percent = 80
    },
    [DRIVE_MODE_SPORT] = {
        .max_power_percent = 100,
        .throttle_response = 100,
        .regen_strength = 40,
        .ac_power_limit_percent = 100
    },
    [DRIVE_MODE_CUSTOM] = {
        .max_power_percent = 85,
        .throttle_response = 75,
        .regen_strength = 65,
        .ac_power_limit_percent = 75
    }
};

static DriveMode_t g_active_mode = DRIVE_MODE_NORMAL;
static DriveModeProfile_t g_custom_profile;

void VCU_DriveMode_Set(DriveMode_t mode) {
    if (mode >= DRIVE_MODE_CUSTOM) return;
    g_active_mode = mode;

    /* Apply profile to power management */
    const DriveModeProfile_t* profile = &DRIVE_MODE_PROFILES[mode];

    VCU_PowerManagement_SetMaxPower(profile->max_power_percent);
    VCU_ThrottleMap_SetResponse(profile->throttle_response);
    VCU_RegenBraking_SetStrength(profile->regen_strength);
    VCU_HVAC_SetPowerLimit(profile->ac_power_limit_percent);

    /* Persist to EEPROM */
    NvM_WriteBlock(NVM_BLOCK_DRIVE_MODE, &mode);
}

DriveMode_t VCU_DriveMode_Get(void) {
    return g_active_mode;
}

/* Throttle pedal mapping with drive mode response curve */
int16_t VCU_ThrottleMap_ApplyResponse(uint8_t pedal_position_percent) {
    const DriveModeProfile_t* profile = &DRIVE_MODE_PROFILES[g_active_mode];

    /* Non-linear response curve: torque = (pedal^2) * response_factor */
    float normalized_pedal = pedal_position_percent / 100.0f;
    float response_factor = profile->throttle_response / 100.0f;

    /* Sport mode: more aggressive curve (pedal^1.5) */
    /* Eco mode: gentler curve (pedal^2.5) */
    float exponent = 2.0f;
    if (g_active_mode == DRIVE_MODE_SPORT) {
        exponent = 1.5f;
    } else if (g_active_mode == DRIVE_MODE_ECO) {
        exponent = 2.5f;
    }

    float torque_factor = powf(normalized_pedal, exponent) * response_factor;
    int16_t max_torque = (MAX_TORQUE_NM * profile->max_power_percent) / 100;

    return (int16_t)(torque_factor * max_torque);
}
```

### 3. Regenerative Braking Control
```c
/* vcu_regen_braking.c - Regenerative braking with blending */
#include "vcu_regen_braking.h"

#define MIN_VEHICLE_SPEED_KPH 5      /* Below this, friction only */
#define MAX_REGEN_POWER_KW 80
#define BATTERY_HIGH_SOC_LIMIT 95    /* Reduce regen above 95% SOC */
#define REGEN_BLEND_THRESHOLD_MS 200 /* Blend window for smooth transition */

typedef struct {
    uint8_t regen_strength_percent;
    int16_t regen_torque_nm;
    int16_t friction_brake_request_nm;
    bool regen_available;
    uint32_t last_blend_timestamp_ms;
} RegenBraking_t;

static RegenBraking_t g_regen_state = {0};

bool VCU_Regen_IsAvailable(void) {
    /* Check conditions for regen availability */
    uint8_t battery_soc = BMS_GetSOC_percent();
    uint8_t battery_temp_c = BMS_GetTemperature_C();
    uint16_t vehicle_speed_kph = VCU_GetVehicleSpeed_kph();

    /* No regen if: SOC too high, battery too cold, vehicle too slow */
    if (battery_soc > BATTERY_HIGH_SOC_LIMIT) return false;
    if (battery_temp_c < 0) return false;  /* Below 0°C, limit regen */
    if (vehicle_speed_kph < MIN_VEHICLE_SPEED_KPH) return false;

    /* Check motor controller readiness */
    if (!MCU_IsRegenReady()) return false;

    return true;
}

void VCU_Regen_CalculateBlending(uint8_t brake_pedal_percent,
                                  int16_t* regen_torque_out,
                                  int16_t* friction_brake_out) {
    *regen_torque_out = 0;
    *friction_brake_out = 0;

    if (!VCU_Regen_IsAvailable()) {
        /* Full friction braking */
        *friction_brake_out = (brake_pedal_percent * MAX_BRAKE_TORQUE_NM) / 100;
        return;
    }

    /* Calculate maximum regen torque based on battery limits */
    uint8_t battery_soc = BMS_GetSOC_percent();
    float soc_factor = 1.0f;
    if (battery_soc > 90) {
        soc_factor = (100.0f - battery_soc) / 10.0f;  /* Linear reduction 90-100% */
    }

    int16_t max_regen_torque = (MIN_REGEN_TORQUE_NM * g_regen_state.regen_strength_percent) / 100;
    max_regen_torque = (int16_t)(max_regen_torque * soc_factor);

    /* Apply regen based on brake pedal position */
    int16_t requested_brake_torque = (brake_pedal_percent * MAX_BRAKE_TORQUE_NM) / 100;

    if (abs(requested_brake_torque) <= abs(max_regen_torque)) {
        /* Regen can handle it all */
        *regen_torque_out = -requested_brake_torque;  /* Negative = regen */
        *friction_brake_out = 0;
    } else {
        /* Blend regen + friction */
        *regen_torque_out = max_regen_torque;
        *friction_brake_out = requested_brake_torque - abs(max_regen_torque);
    }

    g_regen_state.regen_torque_nm = *regen_torque_out;
    g_regen_state.friction_brake_request_nm = *friction_brake_out;
}

/* One-pedal driving mode (aggressive regen on throttle release) */
void VCU_Regen_OnePedalMode(uint8_t throttle_percent) {
    if (throttle_percent > 5) {
        g_regen_state.regen_torque_nm = 0;
        return;
    }

    /* Throttle released: apply regen proportional to vehicle speed */
    uint16_t speed_kph = VCU_GetVehicleSpeed_kph();
    float speed_factor = (speed_kph > 100) ? 1.0f : (speed_kph / 100.0f);

    int16_t one_pedal_regen = (int16_t)(MIN_REGEN_TORQUE_NM * 0.7f * speed_factor);

    VCU_TorqueArbiter_SetRequest(TORQUE_SOURCE_DRIVER, one_pedal_regen, true);
}
```

### 4. Traction Control Integration
```c
/* vcu_traction_control.c - Wheel slip detection and mitigation */
#include "vcu_traction_control.h"

#define WHEEL_SLIP_THRESHOLD_PERCENT 15  /* 15% slip triggers intervention */
#define TC_TORQUE_REDUCTION_STEP_NM 20
#define TC_RECOVERY_RATE_NM_PER_100MS 10

typedef struct {
    float wheel_speeds_kph[4];  /* FL, FR, RL, RR */
    float wheel_slip_percent[4];
    bool tc_active;
    int16_t torque_reduction_nm;
} TractionControl_t;

static TractionControl_t g_tc_state = {0};

void VCU_TractionControl_Update(void) {
    /* Read wheel speeds from ABS sensors via CAN */
    g_tc_state.wheel_speeds_kph[0] = ABS_GetWheelSpeed_kph(WHEEL_FL);
    g_tc_state.wheel_speeds_kph[1] = ABS_GetWheelSpeed_kph(WHEEL_FR);
    g_tc_state.wheel_speeds_kph[2] = ABS_GetWheelSpeed_kph(WHEEL_RL);
    g_tc_state.wheel_speeds_kph[3] = ABS_GetWheelSpeed_kph(WHEEL_RR);

    /* Calculate average driven wheel speed (RWD: rear wheels) */
    float driven_avg = (g_tc_state.wheel_speeds_kph[2] +
                        g_tc_state.wheel_speeds_kph[3]) / 2.0f;

    /* Calculate average non-driven wheel speed (reference) */
    float reference_avg = (g_tc_state.wheel_speeds_kph[0] +
                           g_tc_state.wheel_speeds_kph[1]) / 2.0f;

    if (reference_avg < 5.0f) {
        g_tc_state.tc_active = false;
        return;  /* Vehicle stopped */
    }

    /* Calculate slip percentage */
    float slip_percent = ((driven_avg - reference_avg) / reference_avg) * 100.0f;

    if (slip_percent > WHEEL_SLIP_THRESHOLD_PERCENT) {
        /* Excessive slip detected: reduce torque */
        g_tc_state.tc_active = true;
        g_tc_state.torque_reduction_nm += TC_TORQUE_REDUCTION_STEP_NM;

        /* Cap reduction at 80% of requested torque */
        int16_t driver_torque = VCU_TorqueArbiter_GetRequest(TORQUE_SOURCE_DRIVER);
        if (g_tc_state.torque_reduction_nm > driver_torque * 0.8f) {
            g_tc_state.torque_reduction_nm = (int16_t)(driver_torque * 0.8f);
        }

        /* Override driver request */
        int16_t limited_torque = driver_torque - g_tc_state.torque_reduction_nm;
        VCU_TorqueArbiter_SetRequest(TORQUE_SOURCE_TRACTION_CONTROL,
                                      limited_torque, true);
    } else {
        /* No slip: gradually restore torque */
        if (g_tc_state.torque_reduction_nm > 0) {
            g_tc_state.torque_reduction_nm -= TC_RECOVERY_RATE_NM_PER_100MS;
            if (g_tc_state.torque_reduction_nm < 0) {
                g_tc_state.torque_reduction_nm = 0;
                g_tc_state.tc_active = false;
                VCU_TorqueArbiter_SetRequest(TORQUE_SOURCE_TRACTION_CONTROL, 0, false);
            }
        }
    }
}
```

## AUTOSAR BSW Configuration

### VCU RTE Configuration (ARXML)
```xml
<!-- vcu_rte_configuration.arxml -->
<AUTOSAR xmlns="http://autosar.org/schema/r4.0">
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>VCU_ComponentTypes</SHORT-NAME>
      <ELEMENTS>
        <APPLICATION-SW-COMPONENT-TYPE>
          <SHORT-NAME>VCU_Controller</SHORT-NAME>
          <PORTS>
            <!-- Required Ports (inputs) -->
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>ThrottlePedal</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/ThrottlePedal_IF
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>BrakePedal</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/BrakePedal_IF
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>BatteryStatus</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/BatteryStatus_IF
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>
            <R-PORT-PROTOTYPE>
              <SHORT-NAME>WheelSpeeds</SHORT-NAME>
              <REQUIRED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/WheelSpeeds_IF
              </REQUIRED-INTERFACE-TREF>
            </R-PORT-PROTOTYPE>

            <!-- Provided Ports (outputs) -->
            <P-PORT-PROTOTYPE>
              <SHORT-NAME>MotorTorqueCmd</SHORT-NAME>
              <PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/MotorTorqueCmd_IF
              </PROVIDED-INTERFACE-TREF>
            </P-PORT-PROTOTYPE>
            <P-PORT-PROTOTYPE>
              <SHORT-NAME>BrakeRequest</SHORT-NAME>
              <PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/BrakeRequest_IF
              </PROVIDED-INTERFACE-TREF>
            </P-PORT-PROTOTYPE>
            <P-PORT-PROTOTYPE>
              <SHORT-NAME>VehicleStatus</SHORT-NAME>
              <PROVIDED-INTERFACE-TREF DEST="SENDER-RECEIVER-INTERFACE">
                /Interfaces/VehicleStatus_IF
              </PROVIDED-INTERFACE-TREF>
            </P-PORT-PROTOTYPE>
          </PORTS>

          <INTERNAL-BEHAVIORS>
            <SWC-INTERNAL-BEHAVIOR>
              <SHORT-NAME>VCU_InternalBehavior</SHORT-NAME>
              <RUNNABLES>
                <RUNNABLE-ENTITY>
                  <SHORT-NAME>VCU_Main_10ms</SHORT-NAME>
                  <MINIMUM-START-INTERVAL>0.01</MINIMUM-START-INTERVAL>
                  <CAN-BE-INVOKED-CONCURRENTLY>false</CAN-BE-INVOKED-CONCURRENTLY>
                  <SYMBOL>VCU_Main_Runnable</SYMBOL>
                </RUNNABLE-ENTITY>
              </RUNNABLES>
              <EVENTS>
                <TIMING-EVENT>
                  <SHORT-NAME>TimingEvent_10ms</SHORT-NAME>
                  <START-ON-EVENT-REF DEST="RUNNABLE-ENTITY">
                    /VCU_ComponentTypes/VCU_Controller/VCU_InternalBehavior/VCU_Main_10ms
                  </START-ON-EVENT-REF>
                  <PERIOD>0.01</PERIOD>
                </TIMING-EVENT>
              </EVENTS>
            </SWC-INTERNAL-BEHAVIOR>
          </INTERNAL-BEHAVIORS>
        </APPLICATION-SW-COMPONENT-TYPE>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
```

## VCU CAN Database (DBC)
```
VERSION ""

NS_ :
    NS_DESC_
    CM_
    BA_DEF_
    BA_
    VAL_
    CAT_DEF_
    CAT_
    FILTER
    BA_DEF_DEF_
    EV_DATA_
    ENVVAR_DATA_
    SGTYPE_
    SGTYPE_VAL_
    BA_DEF_SGTYPE_
    BA_SGTYPE_
    SIG_TYPE_REF_
    VAL_TABLE_
    SIG_GROUP_
    SIG_VALTYPE_
    SIGTYPE_VALTYPE_
    BO_TX_BU_
    BA_DEF_REL_
    BA_REL_
    BA_SGTYPE_REL_
    SG_MUL_VAL_

BS_:

BU_: VCU MCU BMS BCM

/* VCU -> MCU: Motor Torque Command */
BO_ 256 VCU_MotorCmd: 8 VCU
 SG_ VCU_TorqueRequest : 0|16@1+ (-2000,0) [-2000|4000] "0.1Nm"  MCU
 SG_ VCU_SpeedLimit : 16|16@1+ (0,0) [0|18000] "0.1rpm"  MCU
 SG_ VCU_ControlMode : 32|8@1+ (0,0) [0|3] ""  MCU
 SG_ VCU_TorqueValid : 40|1@1+ (0,0) [0|1] ""  MCU
 SG_ VCU_TorqueSource : 41|3@1+ (0,0) [0|7] ""  MCU
 SG_ VCU_ChecksumTorque : 56|8@1+ (0,0) [0|255] ""  MCU

/* VCU -> BCM: Brake Request */
BO_ 257 VCU_BrakeCmd: 8 VCU
 SG_ VCU_FrictionBrake_FL : 0|16@1+ (0,0) [0|3000] "0.1Nm"  BCM
 SG_ VCU_FrictionBrake_FR : 16|16@1+ (0,0) [0|3000] "0.1Nm"  BCM
 SG_ VCU_FrictionBrake_RL : 32|16@1+ (0,0) [0|3000] "0.1Nm"  BCM
 SG_ VCU_FrictionBrake_RR : 48|16@1+ (0,0) [0|3000] "0.1Nm"  BCM

/* VCU -> CAN Bus: Vehicle Status */
BO_ 258 VCU_VehicleStatus: 8 VCU
 SG_ VCU_DriveMode : 0|8@1+ (0,0) [0|3] ""  BCM,MCU,BMS
 SG_ VCU_TractionControlActive : 8|1@1+ (0,0) [0|1] ""  BCM
 SG_ VCU_RegenAvailable : 9|1@1+ (0,0) [0|1] ""  BCM
 SG_ VCU_PowerLimitActive : 10|1@1+ (0,0) [0|1] ""  BCM
 SG_ VCU_VehicleReady : 11|1@1+ (0,0) [0|1] ""  BCM,MCU
 SG_ VCU_EstimatedRange_km : 16|16@1+ (0,0) [0|1000] "km"  BCM

VAL_ 256 VCU_ControlMode 0 "Torque_Mode" 1 "Speed_Mode" 2 "Power_Mode" 3 "Disabled";
VAL_ 256 VCU_TorqueSource 0 "Driver" 1 "CruiseControl" 2 "TractionControl" 3 "StabilityControl" 4 "PowerLimit" 5 "ThermalLimit";
VAL_ 258 VCU_DriveMode 0 "Eco" 1 "Normal" 2 "Sport" 3 "Custom";
```

## Power Distribution Strategy
```c
/* vcu_power_distribution.c - Energy management and power budgeting */
#include "vcu_power_management.h"

#define BATTERY_MAX_POWER_KW 150
#define HVAC_MAX_POWER_KW 6
#define DCDC_MAX_POWER_KW 3
#define AUXILIARY_MAX_POWER_KW 2

typedef struct {
    float available_battery_power_kw;
    float allocated_propulsion_kw;
    float allocated_hvac_kw;
    float allocated_auxiliary_kw;
    bool power_limit_active;
} PowerBudget_t;

static PowerBudget_t g_power_budget = {0};

void VCU_PowerManagement_Update(void) {
    /* Get battery discharge limit from BMS */
    g_power_budget.available_battery_power_kw = BMS_GetMaxDischargePower_kW();

    /* Propulsion has first priority */
    float requested_propulsion_kw = VCU_GetRequestedPropulsionPower_kW();

    /* HVAC second priority (can be reduced in power-limited situations) */
    float requested_hvac_kw = HVAC_GetRequestedPower_kW();

    /* Allocate power with priorities */
    float total_requested = requested_propulsion_kw + requested_hvac_kw +
                            DCDC_MAX_POWER_KW + AUXILIARY_MAX_POWER_KW;

    if (total_requested <= g_power_budget.available_battery_power_kw) {
        /* No power limiting needed */
        g_power_budget.allocated_propulsion_kw = requested_propulsion_kw;
        g_power_budget.allocated_hvac_kw = requested_hvac_kw;
        g_power_budget.power_limit_active = false;
    } else {
        /* Power limiting: reduce HVAC first, then propulsion */
        g_power_budget.power_limit_active = true;

        float available_for_hvac = g_power_budget.available_battery_power_kw -
                                    requested_propulsion_kw - DCDC_MAX_POWER_KW -
                                    AUXILIARY_MAX_POWER_KW;

        if (available_for_hvac >= requested_hvac_kw) {
            /* Can still power HVAC fully, limit propulsion */
            g_power_budget.allocated_hvac_kw = requested_hvac_kw;
            g_power_budget.allocated_propulsion_kw = g_power_budget.available_battery_power_kw -
                                                      requested_hvac_kw - DCDC_MAX_POWER_KW -
                                                      AUXILIARY_MAX_POWER_KW;
        } else {
            /* Limit HVAC */
            g_power_budget.allocated_hvac_kw = available_for_hvac > 0 ? available_for_hvac : 0;
            g_power_budget.allocated_propulsion_kw = requested_propulsion_kw;
        }

        /* Apply power limit to torque command */
        int16_t limited_torque = VCU_CalculateTorqueFromPower(
            g_power_budget.allocated_propulsion_kw);
        VCU_TorqueArbiter_SetRequest(TORQUE_SOURCE_POWER_LIMIT, limited_torque, true);
    }
}
```

## ISO 26262 Safety Mechanisms

### Torque Plausibility Check
```c
/* Safety monitor for torque command plausibility */
void VCU_Safety_TorquePlausibilityCheck(void) {
    int16_t commanded_torque = VCU_TorqueArbiter_GetArbitratedTorque();
    int16_t measured_torque = MCU_GetActualTorque();

    int16_t torque_error = abs(commanded_torque - measured_torque);

    if (torque_error > TORQUE_PLAUSIBILITY_THRESHOLD_NM) {
        /* Torque mismatch detected */
        g_safety_fault_counter++;

        if (g_safety_fault_counter > SAFETY_FAULT_THRESHOLD) {
            /* Enter safe state: zero torque request */
            VCU_EnterSafeState();
            DTC_SetFault(DTC_TORQUE_PLAUSIBILITY_FAULT);
        }
    } else {
        if (g_safety_fault_counter > 0) {
            g_safety_fault_counter--;
        }
    }
}
```

## Testing Requirements

### HIL Test Cases
```python
# vcu_hil_test.py - Hardware-in-the-Loop test suite
import can
import pytest
import time

class TestVCUTorqueArbiter:
    def test_driver_torque_request_normal(self, vcu_hil):
        """Verify driver torque request in normal conditions"""
        # Set throttle pedal to 50%
        vcu_hil.set_analog_input("ThrottlePedal", 2.5)  # 0-5V
        time.sleep(0.05)

        # Read CAN message VCU_MotorCmd
        msg = vcu_hil.can_bus.recv(timeout=0.1)
        assert msg.arbitration_id == 0x100  # 256 decimal

        torque_request = int.from_bytes(msg.data[0:2], 'little', signed=True) * 0.1
        assert 150 < torque_request < 250  # Expected range for 50% throttle in Normal mode

    def test_traction_control_intervention(self, vcu_hil):
        """Verify traction control reduces torque on wheel slip"""
        # Simulate wheel slip: driven wheels faster than reference
        vcu_hil.inject_can_message(0x220, [0x64, 0x00, 0x64, 0x00, 0xC8, 0x00, 0xC8, 0x00])
        # Front wheels: 100 kph, Rear wheels: 200 kph (100% slip)

        time.sleep(0.2)

        # Verify VCU_VehicleStatus shows TC active
        status_msg = vcu_hil.read_can_message(0x102)
        tc_active = (status_msg.data[1] & 0x01) == 0x01
        assert tc_active

        # Verify torque reduction
        torque_msg = vcu_hil.read_can_message(0x100)
        torque_source = (torque_msg.data[5] >> 1) & 0x07
        assert torque_source == 2  # TractionControl source
```

## References
- ISO 26262-6: Product development at the software level
- AUTOSAR Classic Platform R20-11: RTE Specification
- SAE J2735: Dedicated Short Range Communications (DSRC) Message Set Dictionary
- ECE R13: Uniform provisions concerning the approval of vehicles of categories M, N and O with regard to braking

## Common Issues
- Torque command jitter due to insufficient rate limiting
- Regen braking not blending smoothly with friction brakes
- Traction control oscillation from aggressive intervention
- Drive mode changes causing torque steps
- Power limiting not respecting HVAC comfort requirements

---

## Vgu Gateway Architecture

# VGU (Vehicle Gateway Unit) - Network Routing and Security

## Overview
The Vehicle Gateway Unit (VGU) acts as the central network hub, routing messages between different vehicle networks (CAN-to-Ethernet, CAN-to-CAN), implementing security firewalls, handling diagnostic access (DoIP), and managing network wake-up. This skill covers production-ready gateway development with AUTOSAR COM stack.

## Core Responsibilities

### 1. Network Routing (CAN-to-Ethernet, CAN-to-CAN)
```c
/* vgu_routing_engine.c - Multi-network message routing */
#include "vgu_routing_engine.h"
#include "Com.h"
#include "PduR.h"
#include <stdint.h>
#include <stdbool.h>

#define MAX_ROUTING_ENTRIES 256
#define MAX_NETWORKS 8

typedef enum {
    NETWORK_CAN_POWERTRAIN = 0,
    NETWORK_CAN_CHASSIS,
    NETWORK_CAN_BODY,
    NETWORK_CAN_INFOTAINMENT,
    NETWORK_ETH_BACKBONE,
    NETWORK_LIN_DOOR,
    NETWORK_FLEXRAY_ADAS,
    NETWORK_INVALID
} NetworkID_t;

typedef enum {
    ROUTING_MODE_UNCONDITIONAL,  /* Always route */
    ROUTING_MODE_CONDITIONAL,    /* Route based on vehicle mode */
    ROUTING_MODE_FILTERED,       /* Apply gateway filter */
    ROUTING_MODE_BLOCKED         /* Never route (security) */
} RoutingMode_t;

typedef struct {
    uint32_t source_pdu_id;
    NetworkID_t source_network;
    uint32_t dest_pdu_id;
    NetworkID_t dest_network;
    RoutingMode_t routing_mode;
    uint16_t cycle_time_ms;       /* For cyclic routing */
    bool transform_required;      /* Endianness/scaling conversion */
    uint32_t route_count;         /* Statistics */
} RoutingEntry_t;

static RoutingEntry_t g_routing_table[MAX_ROUTING_ENTRIES];
static uint16_t g_routing_table_size = 0;

/* Example routing table configuration */
static const RoutingEntry_t DEFAULT_ROUTING_TABLE[] = {
    /* VCU Motor Command: CAN Powertrain -> Ethernet Backbone */
    {
        .source_pdu_id = 0x100,
        .source_network = NETWORK_CAN_POWERTRAIN,
        .dest_pdu_id = 0x100,
        .dest_network = NETWORK_ETH_BACKBONE,
        .routing_mode = ROUTING_MODE_UNCONDITIONAL,
        .cycle_time_ms = 10,
        .transform_required = false
    },
    /* BMS Battery Status: CAN Powertrain -> CAN Infotainment (for display) */
    {
        .source_pdu_id = 0x300,
        .source_network = NETWORK_CAN_POWERTRAIN,
        .dest_pdu_id = 0x300,
        .dest_network = NETWORK_CAN_INFOTAINMENT,
        .routing_mode = ROUTING_MODE_FILTERED,
        .cycle_time_ms = 100,
        .transform_required = false
    },
    /* IVI User Input: CAN Infotainment -> Ethernet Backbone (blocked in drive) */
    {
        .source_pdu_id = 0x400,
        .source_network = NETWORK_CAN_INFOTAINMENT,
        .dest_pdu_id = 0x400,
        .dest_network = NETWORK_ETH_BACKBONE,
        .routing_mode = ROUTING_MODE_CONDITIONAL,
        .cycle_time_ms = 50,
        .transform_required = false
    },
    /* ADAS Camera: Ethernet -> CAN Chassis (lane keeping) */
    {
        .source_pdu_id = 0x500,
        .source_network = NETWORK_ETH_BACKBONE,
        .dest_pdu_id = 0x500,
        .dest_network = NETWORK_CAN_CHASSIS,
        .routing_mode = ROUTING_MODE_UNCONDITIONAL,
        .cycle_time_ms = 20,
        .transform_required = true  /* SOME/IP to CAN conversion */
    }
};

void VGU_RoutingEngine_Init(void) {
    /* Load default routing table */
    g_routing_table_size = sizeof(DEFAULT_ROUTING_TABLE) / sizeof(RoutingEntry_t);
    memcpy(g_routing_table, DEFAULT_ROUTING_TABLE, sizeof(DEFAULT_ROUTING_TABLE));

    /* Initialize network interfaces */
    for (int i = 0; i < MAX_NETWORKS; i++) {
        VGU_Network_Init((NetworkID_t)i);
    }

    /* Load routing table from NVM if available */
    NvM_ReadBlock(NVM_BLOCK_ROUTING_TABLE, g_routing_table);
}

Std_ReturnType VGU_RouteMessage(uint32_t source_pdu_id,
                                 NetworkID_t source_network,
                                 const uint8_t* data,
                                 uint8_t length) {
    /* Find routing entry */
    for (uint16_t i = 0; i < g_routing_table_size; i++) {
        RoutingEntry_t* entry = &g_routing_table[i];

        if (entry->source_pdu_id == source_pdu_id &&
            entry->source_network == source_network) {

            /* Check routing mode */
            if (!VGU_RoutingAllowed(entry)) {
                return E_NOT_OK;
            }

            /* Apply security filter */
            if (!VGU_SecurityFilter_Check(entry, data, length)) {
                VGU_SecurityEvent_Log(SECURITY_EVENT_FILTER_REJECT, source_pdu_id);
                return E_NOT_OK;
            }

            /* Transform if required */
            uint8_t transformed_data[64];
            uint8_t transformed_length = length;

            if (entry->transform_required) {
                VGU_DataTransform(data, length, transformed_data,
                                   &transformed_length, entry);
            } else {
                memcpy(transformed_data, data, length);
            }

            /* Route to destination network */
            Std_ReturnType result = VGU_Network_Transmit(
                entry->dest_network,
                entry->dest_pdu_id,
                transformed_data,
                transformed_length);

            if (result == E_OK) {
                entry->route_count++;
            }

            return result;
        }
    }

    /* No routing entry found */
    return E_NOT_OK;
}

bool VGU_RoutingAllowed(const RoutingEntry_t* entry) {
    switch (entry->routing_mode) {
        case ROUTING_MODE_UNCONDITIONAL:
            return true;

        case ROUTING_MODE_CONDITIONAL:
            /* Example: block IVI messages when vehicle is driving */
            if (entry->source_network == NETWORK_CAN_INFOTAINMENT) {
                uint16_t vehicle_speed = VCU_GetVehicleSpeed_kph();
                return (vehicle_speed < 5);  /* Only allow when stopped */
            }
            return true;

        case ROUTING_MODE_FILTERED:
            /* Additional filtering logic */
            return true;

        case ROUTING_MODE_BLOCKED:
            return false;

        default:
            return false;
    }
}

/* CAN-to-Ethernet transformation (CAN frame -> SOME/IP) */
void VGU_DataTransform_CANtoETH(const uint8_t* can_data, uint8_t can_length,
                                 uint8_t* eth_data, uint8_t* eth_length) {
    /* SOME/IP header: Service ID, Method ID, Length, Client ID, Session ID, ... */
    uint16_t service_id = 0x1234;
    uint16_t method_id = 0x0001;

    /* Build SOME/IP message */
    eth_data[0] = (service_id >> 8) & 0xFF;
    eth_data[1] = service_id & 0xFF;
    eth_data[2] = (method_id >> 8) & 0xFF;
    eth_data[3] = method_id & 0xFF;

    /* Length field */
    uint32_t payload_length = can_length + 8;  /* Payload + SOME/IP overhead */
    eth_data[4] = (payload_length >> 24) & 0xFF;
    eth_data[5] = (payload_length >> 16) & 0xFF;
    eth_data[6] = (payload_length >> 8) & 0xFF;
    eth_data[7] = payload_length & 0xFF;

    /* Copy CAN payload */
    memcpy(&eth_data[16], can_data, can_length);

    *eth_length = 16 + can_length;
}
```

### 2. Security Firewall
```c
/* vgu_security_firewall.c - Message filtering and intrusion detection */
#include "vgu_security_firewall.h"

#define MAX_FIREWALL_RULES 128
#define MAX_ALLOWED_CAN_IDS 512
#define ANOMALY_THRESHOLD 10

typedef enum {
    FIREWALL_ACTION_ALLOW = 0,
    FIREWALL_ACTION_BLOCK,
    FIREWALL_ACTION_LOG,
    FIREWALL_ACTION_ALERT
} FirewallAction_t;

typedef struct {
    uint32_t can_id;
    NetworkID_t network;
    FirewallAction_t action;
    uint32_t min_cycle_time_ms;  /* Minimum expected cycle time */
    uint32_t max_cycle_time_ms;  /* Maximum expected cycle time */
    uint8_t expected_dlc;
    bool require_authentication;
} FirewallRule_t;

typedef struct {
    uint32_t can_id;
    uint32_t last_rx_timestamp_ms;
    uint32_t rx_count;
    uint32_t anomaly_count;
} MessageMonitor_t;

static FirewallRule_t g_firewall_rules[MAX_FIREWALL_RULES];
static MessageMonitor_t g_message_monitors[MAX_ALLOWED_CAN_IDS];

/* Example firewall rules */
static const FirewallRule_t DEFAULT_FIREWALL_RULES[] = {
    /* VCU Motor Command: strict timing, authenticated */
    {
        .can_id = 0x100,
        .network = NETWORK_CAN_POWERTRAIN,
        .action = FIREWALL_ACTION_ALLOW,
        .min_cycle_time_ms = 8,
        .max_cycle_time_ms = 12,
        .expected_dlc = 8,
        .require_authentication = true
    },
    /* BMS Battery Status: allow with timing check */
    {
        .can_id = 0x300,
        .network = NETWORK_CAN_POWERTRAIN,
        .action = FIREWALL_ACTION_ALLOW,
        .min_cycle_time_ms = 90,
        .max_cycle_time_ms = 110,
        .expected_dlc = 8,
        .require_authentication = false
    },
    /* Diagnostic request: block unless diagnostic session active */
    {
        .can_id = 0x7DF,  /* OBD-II diagnostic request */
        .network = NETWORK_CAN_POWERTRAIN,
        .action = FIREWALL_ACTION_LOG,
        .min_cycle_time_ms = 0,
        .max_cycle_time_ms = 0xFFFFFFFF,
        .expected_dlc = 8,
        .require_authentication = true
    },
    /* Unknown high-priority CAN ID: block and alert */
    {
        .can_id = 0x000,  /* High priority range 0x000-0x0FF */
        .network = NETWORK_CAN_POWERTRAIN,
        .action = FIREWALL_ACTION_BLOCK,
        .min_cycle_time_ms = 0,
        .max_cycle_time_ms = 0xFFFFFFFF,
        .expected_dlc = 0,
        .require_authentication = false
    }
};

void VGU_SecurityFirewall_Init(void) {
    memcpy(g_firewall_rules, DEFAULT_FIREWALL_RULES, sizeof(DEFAULT_FIREWALL_RULES));
    memset(g_message_monitors, 0, sizeof(g_message_monitors));
}

bool VGU_SecurityFilter_Check(const RoutingEntry_t* route,
                               const uint8_t* data,
                               uint8_t length) {
    uint32_t can_id = route->source_pdu_id;
    uint32_t current_time_ms = GetSystemTime_ms();

    /* Find firewall rule */
    FirewallRule_t* rule = NULL;
    for (int i = 0; i < MAX_FIREWALL_RULES; i++) {
        if (g_firewall_rules[i].can_id == can_id &&
            g_firewall_rules[i].network == route->source_network) {
            rule = &g_firewall_rules[i];
            break;
        }
    }

    if (rule == NULL) {
        /* No rule defined: default deny */
        return false;
    }

    /* Check DLC */
    if (rule->expected_dlc > 0 && length != rule->expected_dlc) {
        VGU_SecurityEvent_Log(SECURITY_EVENT_DLC_MISMATCH, can_id);
        return false;
    }

    /* Find message monitor entry */
    MessageMonitor_t* monitor = NULL;
    for (int i = 0; i < MAX_ALLOWED_CAN_IDS; i++) {
        if (g_message_monitors[i].can_id == can_id) {
            monitor = &g_message_monitors[i];
            break;
        } else if (g_message_monitors[i].can_id == 0) {
            /* Create new monitor entry */
            monitor = &g_message_monitors[i];
            monitor->can_id = can_id;
            break;
        }
    }

    if (monitor != NULL) {
        /* Check cycle time */
        if (monitor->last_rx_timestamp_ms > 0) {
            uint32_t delta_ms = current_time_ms - monitor->last_rx_timestamp_ms;

            if (delta_ms < rule->min_cycle_time_ms ||
                delta_ms > rule->max_cycle_time_ms) {
                monitor->anomaly_count++;

                if (monitor->anomaly_count > ANOMALY_THRESHOLD) {
                    VGU_SecurityEvent_Log(SECURITY_EVENT_TIMING_VIOLATION, can_id);
                    /* Don't block, but alert */
                }
            } else {
                /* Reset anomaly counter on valid timing */
                if (monitor->anomaly_count > 0) {
                    monitor->anomaly_count--;
                }
            }
        }

        monitor->last_rx_timestamp_ms = current_time_ms;
        monitor->rx_count++;
    }

    /* Check authentication if required */
    if (rule->require_authentication) {
        if (!VGU_Security_VerifyMAC(data, length)) {
            VGU_SecurityEvent_Log(SECURITY_EVENT_AUTH_FAIL, can_id);
            return false;
        }
    }

    /* Apply firewall action */
    switch (rule->action) {
        case FIREWALL_ACTION_ALLOW:
            return true;

        case FIREWALL_ACTION_BLOCK:
            VGU_SecurityEvent_Log(SECURITY_EVENT_BLOCKED, can_id);
            return false;

        case FIREWALL_ACTION_LOG:
            VGU_SecurityEvent_Log(SECURITY_EVENT_LOGGED, can_id);
            return true;

        case FIREWALL_ACTION_ALERT:
            VGU_SecurityEvent_Log(SECURITY_EVENT_ALERT, can_id);
            return true;

        default:
            return false;
    }
}

/* SecOC (Secure Onboard Communication) - MAC verification */
bool VGU_Security_VerifyMAC(const uint8_t* data, uint8_t length) {
    /* Extract MAC from last 8 bytes */
    uint64_t received_mac = 0;
    for (int i = 0; i < 8; i++) {
        received_mac = (received_mac << 8) | data[length - 8 + i];
    }

    /* Calculate expected MAC using CMAC-AES */
    uint64_t calculated_mac = VGU_Crypto_CalculateMAC(data, length - 8);

    return (received_mac == calculated_mac);
}
```

### 3. Diagnostic Gateway (DoIP - Diagnostics over IP)
```c
/* vgu_doip_gateway.c - ISO 13400 Diagnostic over IP */
#include "vgu_doip_gateway.h"

#define DOIP_UDP_PORT 13400
#define DOIP_TCP_PORT 13400
#define MAX_DOIP_CONNECTIONS 4

typedef enum {
    DOIP_VEHICLE_ANNOUNCEMENT = 0x0004,
    DOIP_ROUTING_ACTIVATION_REQUEST = 0x0005,
    DOIP_ROUTING_ACTIVATION_RESPONSE = 0x0006,
    DOIP_DIAGNOSTIC_MESSAGE = 0x8001,
    DOIP_DIAGNOSTIC_MESSAGE_ACK = 0x8002,
    DOIP_DIAGNOSTIC_MESSAGE_NACK = 0x8003
} DoIPMessageType_t;

typedef struct {
    uint8_t protocol_version;
    uint8_t inverse_protocol_version;
    uint16_t payload_type;
    uint32_t payload_length;
} DoIPHeader_t;

typedef struct {
    int socket_fd;
    bool active;
    uint16_t source_address;
    uint16_t target_address;
    uint8_t activation_type;
    uint32_t last_activity_ms;
} DoIPConnection_t;

static DoIPConnection_t g_doip_connections[MAX_DOIP_CONNECTIONS];

void VGU_DoIP_Init(void) {
    /* Create UDP socket for vehicle announcement */
    int udp_socket = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in addr = {
        .sin_family = AF_INET,
        .sin_port = htons(DOIP_UDP_PORT),
        .sin_addr.s_addr = INADDR_ANY
    };
    bind(udp_socket, (struct sockaddr*)&addr, sizeof(addr));

    /* Create TCP socket for diagnostic communication */
    int tcp_socket = socket(AF_INET, SOCK_STREAM, 0);
    bind(tcp_socket, (struct sockaddr*)&addr, sizeof(addr));
    listen(tcp_socket, MAX_DOIP_CONNECTIONS);

    /* Send periodic vehicle announcement */
    VGU_DoIP_SendVehicleAnnouncement(udp_socket);
}

void VGU_DoIP_SendVehicleAnnouncement(int udp_socket) {
    uint8_t announcement[32];
    DoIPHeader_t* header = (DoIPHeader_t*)announcement;

    header->protocol_version = 0x02;  /* ISO 13400-2:2012 */
    header->inverse_protocol_version = 0xFD;
    header->payload_type = htons(DOIP_VEHICLE_ANNOUNCEMENT);
    header->payload_length = htonl(14);

    /* Payload: VIN (17 bytes) + Logical Address (2 bytes) + EID (6 bytes) + GID (6 bytes) */
    const char* vin = "1HGBH41JXMN109186";
    memcpy(&announcement[8], vin, 17);

    uint16_t logical_address = 0x0001;  /* Gateway address */
    memcpy(&announcement[25], &logical_address, 2);

    /* Broadcast announcement */
    struct sockaddr_in broadcast_addr = {
        .sin_family = AF_INET,
        .sin_port = htons(DOIP_UDP_PORT),
        .sin_addr.s_addr = htonl(INADDR_BROADCAST)
    };
    sendto(udp_socket, announcement, 32, 0,
           (struct sockaddr*)&broadcast_addr, sizeof(broadcast_addr));
}

void VGU_DoIP_HandleRoutingActivation(int tcp_socket,
                                       const uint8_t* request,
                                       uint16_t length) {
    /* Parse routing activation request */
    uint16_t source_address = (request[8] << 8) | request[9];
    uint8_t activation_type = request[10];

    /* Find available connection slot */
    DoIPConnection_t* conn = NULL;
    for (int i = 0; i < MAX_DOIP_CONNECTIONS; i++) {
        if (!g_doip_connections[i].active) {
            conn = &g_doip_connections[i];
            break;
        }
    }

    uint8_t response_code;
    if (conn != NULL) {
        conn->socket_fd = tcp_socket;
        conn->active = true;
        conn->source_address = source_address;
        conn->activation_type = activation_type;
        conn->last_activity_ms = GetSystemTime_ms();

        response_code = 0x10;  /* Routing successfully activated */
    } else {
        response_code = 0x02;  /* All sockets in use */
    }

    /* Send routing activation response */
    uint8_t response[13];
    DoIPHeader_t* header = (DoIPHeader_t*)response;
    header->protocol_version = 0x02;
    header->inverse_protocol_version = 0xFD;
    header->payload_type = htons(DOIP_ROUTING_ACTIVATION_RESPONSE);
    header->payload_length = htonl(5);

    response[8] = (source_address >> 8) & 0xFF;
    response[9] = source_address & 0xFF;
    response[10] = 0x00;  /* Logical address of gateway */
    response[11] = 0x01;
    response[12] = response_code;

    send(tcp_socket, response, 13, 0);
}

void VGU_DoIP_RouteDiagnosticMessage(const uint8_t* doip_message, uint16_t length) {
    /* Extract source and target addresses */
    uint16_t source_addr = (doip_message[8] << 8) | doip_message[9];
    uint16_t target_addr = (doip_message[10] << 8) | doip_message[11];

    /* Extract UDS payload */
    const uint8_t* uds_payload = &doip_message[12];
    uint16_t uds_length = length - 12;

    /* Route to target ECU based on logical address */
    NetworkID_t target_network;
    uint32_t target_can_id;

    switch (target_addr) {
        case 0x0010:  /* VCU */
            target_network = NETWORK_CAN_POWERTRAIN;
            target_can_id = 0x7E0;  /* VCU diagnostic address */
            break;
        case 0x0020:  /* BMS */
            target_network = NETWORK_CAN_POWERTRAIN;
            target_can_id = 0x7E1;
            break;
        case 0x0030:  /* MCU */
            target_network = NETWORK_CAN_POWERTRAIN;
            target_can_id = 0x7E2;
            break;
        default:
            /* Unknown target */
            return;
    }

    /* Send diagnostic request over CAN */
    VGU_Network_Transmit(target_network, target_can_id, uds_payload, uds_length);
}
```

### 4. Gateway Wake-Up Management
```c
/* vgu_wakeup_management.c - Network wake-up and power management */
#include "vgu_wakeup_management.h"

typedef enum {
    WAKEUP_SOURCE_CAN_POWERTRAIN = 0,
    WAKEUP_SOURCE_CAN_CHASSIS,
    WAKEUP_SOURCE_LIN_DOOR,
    WAKEUP_SOURCE_ETHERNET,
    WAKEUP_SOURCE_TIMER,
    WAKEUP_SOURCE_IGNITION,
    WAKEUP_SOURCE_COUNT
} WakeupSource_t;

typedef struct {
    bool wakeup_enabled[WAKEUP_SOURCE_COUNT];
    WakeupSource_t last_wakeup_source;
    uint32_t wakeup_timestamp_ms;
} WakeupState_t;

static WakeupState_t g_wakeup_state = {0};

void VGU_WakeupManagement_Init(void) {
    /* Enable relevant wakeup sources */
    g_wakeup_state.wakeup_enabled[WAKEUP_SOURCE_CAN_POWERTRAIN] = true;
    g_wakeup_state.wakeup_enabled[WAKEUP_SOURCE_LIN_DOOR] = true;
    g_wakeup_state.wakeup_enabled[WAKEUP_SOURCE_IGNITION] = true;

    /* Configure CAN transceivers for selective wake-up */
    CanTrcv_SetOpMode(CAN_POWERTRAIN, CANTRCV_WUMODE_ENABLE);
    CanTrcv_SetOpMode(CAN_CHASSIS, CANTRCV_WUMODE_ENABLE);
}

void VGU_WakeupManagement_OnWakeup(WakeupSource_t source) {
    g_wakeup_state.last_wakeup_source = source;
    g_wakeup_state.wakeup_timestamp_ms = GetSystemTime_ms();

    /* Notify EcuM of wakeup event */
    EcuM_SetWakeupEvent((EcuM_WakeupSourceType)(1 << source));

    /* Start network initialization sequence based on wakeup source */
    switch (source) {
        case WAKEUP_SOURCE_CAN_POWERTRAIN:
            /* High-priority startup: VCU, BMS, MCU needed */
            VGU_Network_Start(NETWORK_CAN_POWERTRAIN);
            VGU_Network_Start(NETWORK_CAN_CHASSIS);
            break;

        case WAKEUP_SOURCE_LIN_DOOR:
            /* Body network startup: BCM, door modules */
            VGU_Network_Start(NETWORK_CAN_BODY);
            VGU_Network_Start(NETWORK_LIN_DOOR);
            break;

        case WAKEUP_SOURCE_IGNITION:
            /* Full network startup */
            for (NetworkID_t net = 0; net < NETWORK_INVALID; net++) {
                VGU_Network_Start(net);
            }
            break;

        default:
            break;
    }
}

void VGU_WakeupManagement_EnterSleep(void) {
    /* Shutdown sequence: least critical networks first */
    VGU_Network_Stop(NETWORK_CAN_INFOTAINMENT);
    VGU_Network_Stop(NETWORK_CAN_BODY);

    /* Wait for pending transmissions */
    while (VGU_Network_HasPendingTx(NETWORK_CAN_CHASSIS)) {
        OsTask_Sleep(10);
    }

    VGU_Network_Stop(NETWORK_CAN_CHASSIS);

    /* Powertrain network last (safety-critical) */
    VGU_Network_Stop(NETWORK_CAN_POWERTRAIN);

    /* Configure transceivers for wake-up */
    CanTrcv_SetOpMode(CAN_POWERTRAIN, CANTRCV_WUMODE_ENABLE);

    /* Enter low-power mode */
    Mcu_SetMode(MCU_MODE_SLEEP);
}
```

## AUTOSAR COM Stack Configuration

### Gateway PDU Router (ARXML)
```xml
<!-- vgu_pdur_configuration.arxml -->
<AUTOSAR xmlns="http://autosar.org/schema/r4.0">
  <AR-PACKAGES>
    <AR-PACKAGE>
      <SHORT-NAME>PduR_RoutingTables</SHORT-NAME>
      <ELEMENTS>
        <PDU-R-ROUTING-TABLE>
          <SHORT-NAME>VGU_RoutingTable</SHORT-NAME>
          <ROUTING-PATHS>
            <!-- CAN Powertrain -> Ethernet Backbone -->
            <PDU-R-ROUTING-PATH>
              <SHORT-NAME>VCU_MotorCmd_CANtoETH</SHORT-NAME>
              <PDU-R-SOURCE-PDU-REF DEST="I-PDU">
                /CAN_Powertrain/VCU_MotorCmd
              </PDU-R-SOURCE-PDU-REF>
              <PDU-R-DESTINATION-PDU-REF DEST="I-PDU">
                /ETH_Backbone/VCU_MotorCmd_ETH
              </PDU-R-DESTINATION-PDU-REF>
              <PDU-R-DEFAULT-VALUE>0</PDU-R-DEFAULT-VALUE>
            </PDU-R-ROUTING-PATH>

            <!-- Ethernet -> CAN Chassis (ADAS commands) -->
            <PDU-R-ROUTING-PATH>
              <SHORT-NAME>ADAS_SteeringCmd_ETHtoGAN</SHORT-NAME>
              <PDU-R-SOURCE-PDU-REF DEST="I-PDU">
                /ETH_Backbone/ADAS_SteeringCmd
              </PDU-R-SOURCE-PDU-REF>
              <PDU-R-DESTINATION-PDU-REF DEST="I-PDU">
                /CAN_Chassis/ADAS_SteeringCmd_CAN
              </PDU-R-DESTINATION-PDU-REF>
              <PDU-R-DEFAULT-VALUE>0</PDU-R-DEFAULT-VALUE>
            </PDU-R-ROUTING-PATH>
          </ROUTING-PATHS>
        </PDU-R-ROUTING-TABLE>
      </ELEMENTS>
    </AR-PACKAGE>
  </AR-PACKAGES>
</AUTOSAR>
```

## VGU Network Configuration (DBC)
```
VERSION ""

NS_ :

BS_:

BU_: VGU VCU BMS MCU BCM IVI

/* Gateway Status Message */
BO_ 1024 VGU_Status: 8 VGU
 SG_ VGU_NetworkStatus_Powertrain : 0|2@1+ (0,0) [0|3] ""  VCU,BMS,MCU
 SG_ VGU_NetworkStatus_Chassis : 2|2@1+ (0,0) [0|3] ""  BCM
 SG_ VGU_NetworkStatus_Body : 4|2@1+ (0,0) [0|3] ""  BCM
 SG_ VGU_NetworkStatus_Infotainment : 6|2@1+ (0,0) [0|3] ""  IVI
 SG_ VGU_NetworkStatus_Ethernet : 8|2@1+ (0,0) [0|3] ""  VCU,IVI
 SG_ VGU_RoutingActive : 10|1@1+ (0,0) [0|1] ""  ALL
 SG_ VGU_FirewallActive : 11|1@1+ (0,0) [0|1] ""  ALL
 SG_ VGU_DiagnosticSessionActive : 12|1@1+ (0,0) [0|1] ""  ALL
 SG_ VGU_SecurityAnomalyCount : 16|16@1+ (0,0) [0|65535] ""  ALL
 SG_ VGU_RoutedMessageCount : 32|32@1+ (0,0) [0|4294967295] ""  ALL

VAL_ 1024 VGU_NetworkStatus_Powertrain 0 "Offline" 1 "Initializing" 2 "Active" 3 "Error";
VAL_ 1024 VGU_NetworkStatus_Chassis 0 "Offline" 1 "Initializing" 2 "Active" 3 "Error";
VAL_ 1024 VGU_NetworkStatus_Body 0 "Offline" 1 "Initializing" 2 "Active" 3 "Error";
VAL_ 1024 VGU_NetworkStatus_Infotainment 0 "Offline" 1 "Initializing" 2 "Active" 3 "Error";
VAL_ 1024 VGU_NetworkStatus_Ethernet 0 "Offline" 1 "Initializing" 2 "Active" 3 "Error";
```

## Testing Requirements

### Gateway HIL Test
```python
# vgu_hil_test.py - Hardware-in-the-Loop testing for VGU
import can
import socket
import pytest

class TestVGURouting:
    def test_can_to_ethernet_routing(self, vgu_hil):
        """Verify CAN message is routed to Ethernet"""
        # Send VCU_MotorCmd on CAN Powertrain
        can_msg = can.Message(arbitration_id=0x100,
                               data=[0x64, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0xAB],
                               is_extended_id=False)
        vgu_hil.can_powertrain.send(can_msg)

        # Verify message appears on Ethernet backbone (SOME/IP)
        eth_packet = vgu_hil.eth_backbone.recv(timeout=0.1)
        assert eth_packet is not None
        assert eth_packet[0:2] == b'\x12\x34'  # Service ID

    def test_security_firewall_blocks_invalid_dlc(self, vgu_hil):
        """Verify firewall blocks message with wrong DLC"""
        # Send message with incorrect DLC
        invalid_msg = can.Message(arbitration_id=0x100,
                                   data=[0x64, 0x00],  # DLC=2, expected=8
                                   is_extended_id=False)
        vgu_hil.can_powertrain.send(invalid_msg)

        # Verify VGU logs security event
        security_log = vgu_hil.read_can_message(0x400, timeout=0.1)
        assert security_log.data[0] == 0x01  # DLC_MISMATCH event

        # Verify message NOT routed to Ethernet
        eth_packet = vgu_hil.eth_backbone.recv(timeout=0.1)
        assert eth_packet is None

    def test_doip_routing_activation(self, vgu_hil):
        """Verify DoIP routing activation over TCP"""
        # Connect to DoIP port
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(("192.168.1.100", 13400))

        # Send routing activation request
        activation_request = bytes([
            0x02, 0xFD,  # Protocol version
            0x00, 0x05,  # Payload type: Routing Activation Request
            0x00, 0x00, 0x00, 0x07,  # Payload length
            0x0E, 0x80,  # Source address (tester)
            0x00,        # Activation type
            0x00, 0x00, 0x00, 0x00  # Reserved
        ])
        sock.send(activation_request)

        # Receive routing activation response
        response = sock.recv(13)
        assert len(response) == 13
        assert response[2:4] == b'\x00\x06'  # Routing Activation Response
        assert response[12] == 0x10  # Response code: Successfully activated

        sock.close()
```

## References
- ISO 13400: Diagnostic communication over Internet Protocol (DoIP)
- AUTOSAR Classic Platform R20-11: PDU Router Specification
- SAE J1939: Serial Control and Communications Heavy Duty Vehicle Network
- IEEE 802.1Q: Virtual LANs and Network Segmentation
- ISO 14229-1: Unified Diagnostic Services (UDS)

## Common Issues
- Message routing latency causing control delays
- Firewall false positives blocking legitimate messages
- DoIP connection timeout during long diagnostic sessions
- Wake-up signal not propagating across networks
- Ethernet packet loss during high CAN traffic bursts

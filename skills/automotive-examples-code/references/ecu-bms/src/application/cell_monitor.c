/**
 * @file cell_monitor.c
 * @brief Cell Voltage Monitoring Software Component
 * @author Automotive Agents Team
 * @date 2026-03-19
 *
 * AUTOSAR SWC for monitoring individual cell voltages in a battery pack.
 * Implements ISO 26262 ASIL-C safety requirements for overvoltage/undervoltage detection.
 *
 * Configuration: 96 cells (3S32P), LiFePO4 chemistry
 * Monitoring IC: LTC6811 (12-bit ADC, SPI interface)
 */

#include "cell_monitor.h"
#include "Rte_BMS.h"
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

/* ======================== Calibration Parameters ======================== */

/**
 * Calibration parameters are accessible via XCP for runtime tuning.
 * These are stored in Flash and can be modified using calibration tools.
 */
#ifdef CAL
    #undef CAL
#endif
#define CAL __attribute__((section(".calibration")))

CAL uint16_t CAL_CellOVThreshold_mV = 3650;     /**< Overvoltage threshold (mV) */
CAL uint16_t CAL_CellUVThreshold_mV = 2500;     /**< Undervoltage threshold (mV) */
CAL uint16_t CAL_CellImbalanceThreshold_mV = 100; /**< Imbalance threshold (mV) */
CAL uint16_t CAL_CellNominalVoltage_mV = 3200;  /**< Nominal cell voltage (mV) */
CAL uint16_t CAL_AdcOffset_mV = 0;              /**< ADC offset correction (mV) */
CAL int16_t CAL_AdcGain_ppm = 1000000;          /**< ADC gain correction (ppm) */

/* ======================== Constants ======================== */

#define NUM_CELLS 96U                /**< Total number of cells */
#define NUM_STRINGS 3U               /**< Number of parallel strings */
#define CELLS_PER_STRING 32U         /**< Cells per string */
#define NUM_LTC6811 12U              /**< Number of LTC6811 ICs (8 cells each) */

#define CELL_VOLTAGE_MIN_MV 2000U    /**< Absolute minimum voltage (mV) */
#define CELL_VOLTAGE_MAX_MV 4000U    /**< Absolute maximum voltage (mV) */
#define ADC_RESOLUTION_MV 0.5f       /**< ADC resolution (mV per bit) */

#define SAMPLE_PERIOD_MS 100U        /**< Sampling period (ms) */
#define FAULT_DEBOUNCE_COUNT 3U      /**< Fault debounce counter */

/* ======================== Type Definitions ======================== */

/**
 * Cell monitoring state machine states
 */
typedef enum {
    CELL_MON_INIT,           /**< Initialization */
    CELL_MON_IDLE,           /**< Idle state */
    CELL_MON_SAMPLING,       /**< Sampling in progress */
    CELL_MON_PROCESSING,     /**< Processing results */
    CELL_MON_FAULT,          /**< Fault detected */
} CellMonState_t;

/**
 * Cell fault flags
 */
typedef enum {
    CELL_FAULT_NONE = 0x00,
    CELL_FAULT_OVERVOLTAGE = 0x01,
    CELL_FAULT_UNDERVOLTAGE = 0x02,
    CELL_FAULT_IMBALANCE = 0x04,
    CELL_FAULT_COMMUNICATION = 0x08,
    CELL_FAULT_SENSOR = 0x10,
} CellFaultFlags_t;

/**
 * Cell monitoring data structure
 */
typedef struct {
    uint16_t voltages_mV[NUM_CELLS];    /**< Individual cell voltages (mV) */
    uint16_t min_voltage_mV;             /**< Minimum cell voltage (mV) */
    uint16_t max_voltage_mV;             /**< Maximum cell voltage (mV) */
    uint16_t avg_voltage_mV;             /**< Average cell voltage (mV) */
    uint16_t delta_voltage_mV;           /**< Voltage spread (max - min) */
    uint8_t min_voltage_cell_id;         /**< Cell ID with minimum voltage */
    uint8_t max_voltage_cell_id;         /**< Cell ID with maximum voltage */
    CellFaultFlags_t fault_flags;        /**< Active fault flags */
    uint8_t fault_debounce_counter;      /**< Debounce counter */
    CellMonState_t state;                /**< State machine state */
    uint32_t sample_count;               /**< Total samples acquired */
    uint32_t last_sample_timestamp_ms;   /**< Timestamp of last sample */
} CellMonitorData_t;

/* ======================== Module Variables ======================== */

static CellMonitorData_t g_cellMonData = {0};

/* ======================== Private Function Prototypes ======================== */

static void CellMon_InitHardware(void);
static void CellMon_SampleCellVoltages(void);
static void CellMon_ProcessVoltages(void);
static void CellMon_DetectFaults(void);
static void CellMon_UpdateStatistics(void);
static uint16_t CellMon_ReadLTC6811(uint8_t ic_index, uint8_t cell_index);
static bool CellMon_ValidateVoltage(uint16_t voltage_mV);

/* ======================== Public Functions ======================== */

/**
 * @brief Initialize Cell Monitoring component
 * @return Status code (0 = success)
 */
Std_ReturnType CellMon_Init(void) {
    // Initialize data structure
    memset(&g_cellMonData, 0, sizeof(CellMonitorData_t));
    g_cellMonData.state = CELL_MON_INIT;

    // Initialize LTC6811 hardware
    CellMon_InitHardware();

    // Initial sampling
    CellMon_SampleCellVoltages();
    CellMon_ProcessVoltages();

    g_cellMonData.state = CELL_MON_IDLE;

    return E_OK;
}

/**
 * @brief Main cell monitoring task (called every 100ms)
 */
void CellMon_MainFunction(void) {
    switch (g_cellMonData.state) {
        case CELL_MON_IDLE:
            // Trigger new sampling
            g_cellMonData.state = CELL_MON_SAMPLING;
            break;

        case CELL_MON_SAMPLING:
            // Read cell voltages from LTC6811
            CellMon_SampleCellVoltages();
            g_cellMonData.state = CELL_MON_PROCESSING;
            break;

        case CELL_MON_PROCESSING:
            // Process and analyze voltages
            CellMon_ProcessVoltages();
            CellMon_UpdateStatistics();
            CellMon_DetectFaults();

            // Check for faults
            if (g_cellMonData.fault_flags != CELL_FAULT_NONE) {
                g_cellMonData.state = CELL_MON_FAULT;
            } else {
                g_cellMonData.state = CELL_MON_IDLE;
            }
            break;

        case CELL_MON_FAULT:
            // Fault handling - still monitor voltages
            CellMon_SampleCellVoltages();
            CellMon_ProcessVoltages();
            CellMon_DetectFaults();

            // Clear fault if condition resolved
            if (g_cellMonData.fault_flags == CELL_FAULT_NONE) {
                g_cellMonData.fault_debounce_counter = 0;
                g_cellMonData.state = CELL_MON_IDLE;
            }
            break;

        default:
            g_cellMonData.state = CELL_MON_INIT;
            break;
    }

    // Update RTE outputs
    Rte_Write_CellVoltages(&g_cellMonData);
}

/**
 * @brief Get cell voltages
 * @param[out] voltages Pointer to voltage array
 * @return Status code
 */
Std_ReturnType CellMon_GetCellVoltages(uint16_t* voltages) {
    if (voltages == NULL) {
        return E_NOT_OK;
    }

    memcpy(voltages, g_cellMonData.voltages_mV, sizeof(g_cellMonData.voltages_mV));
    return E_OK;
}

/**
 * @brief Get minimum cell voltage
 * @param[out] min_voltage Minimum voltage (mV)
 * @param[out] cell_id Cell ID with minimum voltage
 * @return Status code
 */
Std_ReturnType CellMon_GetMinVoltage(uint16_t* min_voltage, uint8_t* cell_id) {
    if (min_voltage == NULL || cell_id == NULL) {
        return E_NOT_OK;
    }

    *min_voltage = g_cellMonData.min_voltage_mV;
    *cell_id = g_cellMonData.min_voltage_cell_id;
    return E_OK;
}

/**
 * @brief Get maximum cell voltage
 * @param[out] max_voltage Maximum voltage (mV)
 * @param[out] cell_id Cell ID with maximum voltage
 * @return Status code
 */
Std_ReturnType CellMon_GetMaxVoltage(uint16_t* max_voltage, uint8_t* cell_id) {
    if (max_voltage == NULL || cell_id == NULL) {
        return E_NOT_OK;
    }

    *max_voltage = g_cellMonData.max_voltage_mV;
    *cell_id = g_cellMonData.max_voltage_cell_id;
    return E_OK;
}

/**
 * @brief Get voltage statistics
 * @param[out] avg_voltage Average voltage (mV)
 * @param[out] delta_voltage Voltage spread (mV)
 * @return Status code
 */
Std_ReturnType CellMon_GetVoltageStats(uint16_t* avg_voltage, uint16_t* delta_voltage) {
    if (avg_voltage == NULL || delta_voltage == NULL) {
        return E_NOT_OK;
    }

    *avg_voltage = g_cellMonData.avg_voltage_mV;
    *delta_voltage = g_cellMonData.delta_voltage_mV;
    return E_OK;
}

/**
 * @brief Get fault status
 * @return Fault flags
 */
CellFaultFlags_t CellMon_GetFaultStatus(void) {
    return g_cellMonData.fault_flags;
}

/* ======================== Private Functions ======================== */

/**
 * @brief Initialize LTC6811 hardware
 */
static void CellMon_InitHardware(void) {
    // In real implementation:
    // 1. Initialize SPI peripheral
    // 2. Configure LTC6811 registers
    // 3. Set ADC mode and filters
    // 4. Enable cell measurement

    // For this example, we simulate initialization
    for (uint8_t i = 0; i < NUM_CELLS; i++) {
        g_cellMonData.voltages_mV[i] = CAL_CellNominalVoltage_mV;
    }
}

/**
 * @brief Sample all cell voltages from LTC6811
 */
static void CellMon_SampleCellVoltages(void) {
    uint32_t timestamp = Rte_GetTimeMs();

    for (uint8_t cell = 0; cell < NUM_CELLS; cell++) {
        uint8_t ic_index = cell / 8;  // 8 cells per LTC6811
        uint8_t cell_index = cell % 8;

        uint16_t raw_voltage = CellMon_ReadLTC6811(ic_index, cell_index);

        // Apply calibration
        int32_t voltage_mV = (int32_t)raw_voltage;
        voltage_mV = voltage_mV * CAL_AdcGain_ppm / 1000000;
        voltage_mV += CAL_AdcOffset_mV;

        // Validate and store
        if (CellMon_ValidateVoltage((uint16_t)voltage_mV)) {
            g_cellMonData.voltages_mV[cell] = (uint16_t)voltage_mV;
        } else {
            // Sensor fault
            g_cellMonData.fault_flags |= CELL_FAULT_SENSOR;
        }
    }

    g_cellMonData.last_sample_timestamp_ms = timestamp;
    g_cellMonData.sample_count++;
}

/**
 * @brief Process voltage measurements
 */
static void CellMon_ProcessVoltages(void) {
    uint16_t min_v = 0xFFFF;
    uint16_t max_v = 0;
    uint32_t sum_v = 0;
    uint8_t min_id = 0;
    uint8_t max_id = 0;

    // Find min, max, and calculate average
    for (uint8_t i = 0; i < NUM_CELLS; i++) {
        uint16_t voltage = g_cellMonData.voltages_mV[i];

        if (voltage < min_v) {
            min_v = voltage;
            min_id = i;
        }

        if (voltage > max_v) {
            max_v = voltage;
            max_id = i;
        }

        sum_v += voltage;
    }

    g_cellMonData.min_voltage_mV = min_v;
    g_cellMonData.max_voltage_mV = max_v;
    g_cellMonData.min_voltage_cell_id = min_id;
    g_cellMonData.max_voltage_cell_id = max_id;
    g_cellMonData.avg_voltage_mV = (uint16_t)(sum_v / NUM_CELLS);
    g_cellMonData.delta_voltage_mV = max_v - min_v;
}

/**
 * @brief Detect voltage-related faults
 */
static void CellMon_DetectFaults(void) {
    CellFaultFlags_t new_faults = CELL_FAULT_NONE;

    // Check overvoltage
    if (g_cellMonData.max_voltage_mV > CAL_CellOVThreshold_mV) {
        new_faults |= CELL_FAULT_OVERVOLTAGE;
    }

    // Check undervoltage
    if (g_cellMonData.min_voltage_mV < CAL_CellUVThreshold_mV) {
        new_faults |= CELL_FAULT_UNDERVOLTAGE;
    }

    // Check imbalance
    if (g_cellMonData.delta_voltage_mV > CAL_CellImbalanceThreshold_mV) {
        new_faults |= CELL_FAULT_IMBALANCE;
    }

    // Debounce fault detection
    if (new_faults != CELL_FAULT_NONE) {
        if (g_cellMonData.fault_debounce_counter < FAULT_DEBOUNCE_COUNT) {
            g_cellMonData.fault_debounce_counter++;
        } else {
            // Fault confirmed
            g_cellMonData.fault_flags = new_faults;

            // Trigger DTC reporting via RTE
            if (new_faults & CELL_FAULT_OVERVOLTAGE) {
                Rte_TriggerFault(DTC_CELL_OVERVOLTAGE, g_cellMonData.max_voltage_cell_id);
            }
            if (new_faults & CELL_FAULT_UNDERVOLTAGE) {
                Rte_TriggerFault(DTC_CELL_UNDERVOLTAGE, g_cellMonData.min_voltage_cell_id);
            }
            if (new_faults & CELL_FAULT_IMBALANCE) {
                Rte_TriggerFault(DTC_CELL_IMBALANCE, 0);
            }
        }
    } else {
        // No faults - reset counter
        g_cellMonData.fault_debounce_counter = 0;
        g_cellMonData.fault_flags = CELL_FAULT_NONE;
    }
}

/**
 * @brief Update voltage statistics
 */
static void CellMon_UpdateStatistics(void) {
    // Calculate pack voltage (sum of all cells)
    uint32_t pack_voltage_mV = 0;
    for (uint8_t i = 0; i < NUM_CELLS; i++) {
        pack_voltage_mV += g_cellMonData.voltages_mV[i];
    }

    // Write to RTE
    Rte_Write_PackVoltage((uint16_t)(pack_voltage_mV / 100)); // Convert to 0.1V
}

/**
 * @brief Read cell voltage from LTC6811
 * @param ic_index LTC6811 IC index (0-11)
 * @param cell_index Cell index within IC (0-7)
 * @return Raw voltage in mV
 */
static uint16_t CellMon_ReadLTC6811(uint8_t ic_index, uint8_t cell_index) {
    // In real implementation:
    // 1. Send ADCV command to start conversion
    // 2. Wait for conversion complete
    // 3. Read cell voltage registers via SPI
    // 4. Verify PEC (Packet Error Code)
    // 5. Convert raw ADC value to mV

    // For simulation, return nominal voltage with small variation
    uint16_t base_voltage = CAL_CellNominalVoltage_mV;
    int16_t variation = (int16_t)((ic_index * 10 + cell_index * 5) % 50) - 25;

    return (uint16_t)(base_voltage + variation);
}

/**
 * @brief Validate voltage reading
 * @param voltage_mV Voltage to validate
 * @return true if valid, false otherwise
 */
static bool CellMon_ValidateVoltage(uint16_t voltage_mV) {
    return (voltage_mV >= CELL_VOLTAGE_MIN_MV) && (voltage_mV <= CELL_VOLTAGE_MAX_MV);
}

/* ======================== Diagnostic Functions ======================== */

/**
 * @brief Get diagnostic data for cell monitoring
 * @param[out] diag_data Diagnostic data structure
 * @return Status code
 */
Std_ReturnType CellMon_GetDiagnosticData(CellMonDiagData_t* diag_data) {
    if (diag_data == NULL) {
        return E_NOT_OK;
    }

    diag_data->sample_count = g_cellMonData.sample_count;
    diag_data->last_sample_timestamp = g_cellMonData.last_sample_timestamp_ms;
    diag_data->state = g_cellMonData.state;
    diag_data->fault_flags = g_cellMonData.fault_flags;

    return E_OK;
}

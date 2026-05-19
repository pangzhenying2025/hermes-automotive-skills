/**
 * @file cell_monitor.h
 * @brief Cell Voltage Monitoring Software Component Header
 * @author Automotive Agents Team
 * @date 2026-03-19
 */

#ifndef CELL_MONITOR_H
#define CELL_MONITOR_H

#include <stdint.h>
#include <stdbool.h>

/* ======================== AUTOSAR Standard Types ======================== */

typedef uint8_t Std_ReturnType;
#define E_OK     0x00
#define E_NOT_OK 0x01

/* ======================== DTC Definitions ======================== */

#define DTC_CELL_OVERVOLTAGE   0x100
#define DTC_CELL_UNDERVOLTAGE  0x101
#define DTC_CELL_IMBALANCE     0x102
#define DTC_CELL_SENSOR_FAULT  0x103

/* ======================== Type Definitions ======================== */

/**
 * Diagnostic data structure
 */
typedef struct {
    uint32_t sample_count;
    uint32_t last_sample_timestamp;
    uint8_t state;
    uint8_t fault_flags;
} CellMonDiagData_t;

/* ======================== Public Function Prototypes ======================== */

/**
 * @brief Initialize Cell Monitoring component
 * @return Status code (0 = success)
 */
Std_ReturnType CellMon_Init(void);

/**
 * @brief Main cell monitoring task (called every 100ms)
 */
void CellMon_MainFunction(void);

/**
 * @brief Get cell voltages
 * @param[out] voltages Pointer to voltage array (96 elements)
 * @return Status code
 */
Std_ReturnType CellMon_GetCellVoltages(uint16_t* voltages);

/**
 * @brief Get minimum cell voltage
 * @param[out] min_voltage Minimum voltage (mV)
 * @param[out] cell_id Cell ID with minimum voltage
 * @return Status code
 */
Std_ReturnType CellMon_GetMinVoltage(uint16_t* min_voltage, uint8_t* cell_id);

/**
 * @brief Get maximum cell voltage
 * @param[out] max_voltage Maximum voltage (mV)
 * @param[out] cell_id Cell ID with maximum voltage
 * @return Status code
 */
Std_ReturnType CellMon_GetMaxVoltage(uint16_t* max_voltage, uint8_t* cell_id);

/**
 * @brief Get voltage statistics
 * @param[out] avg_voltage Average voltage (mV)
 * @param[out] delta_voltage Voltage spread (mV)
 * @return Status code
 */
Std_ReturnType CellMon_GetVoltageStats(uint16_t* avg_voltage, uint16_t* delta_voltage);

/**
 * @brief Get fault status
 * @return Fault flags (bitfield)
 */
uint8_t CellMon_GetFaultStatus(void);

/**
 * @brief Get diagnostic data for cell monitoring
 * @param[out] diag_data Diagnostic data structure
 * @return Status code
 */
Std_ReturnType CellMon_GetDiagnosticData(CellMonDiagData_t* diag_data);

#endif /* CELL_MONITOR_H */

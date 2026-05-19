/**
 * @file soc_estimator.h
 * @brief State of Charge Estimation Header
 * @author Automotive Agents Team
 * @date 2026-03-19
 */

#ifndef SOC_ESTIMATOR_H
#define SOC_ESTIMATOR_H

#include <stdint.h>
#include <stdbool.h>

/* ======================== AUTOSAR Standard Types ======================== */

typedef uint8_t Std_ReturnType;
#define E_OK     0x00
#define E_NOT_OK 0x01

/* ======================== Type Definitions ======================== */

/**
 * SOC diagnostic data
 */
typedef struct {
    uint8_t soc_percent;        /**< Current SOC (%) */
    float ekf_P;                /**< EKF error covariance */
    float ekf_K;                /**< EKF Kalman gain */
    int32_t coulomb_count_mAs;  /**< Coulomb counter (mA·s) */
    uint32_t capacity_mAh;      /**< Battery capacity (mAh) */
} SOC_DiagData_t;

/* ======================== Public Function Prototypes ======================== */

/**
 * @brief Initialize SOC estimator
 * @param initial_soc_percent Initial SOC estimate (%)
 * @return Status code
 */
Std_ReturnType SOC_Init(uint8_t initial_soc_percent);

/**
 * @brief Main SOC estimation task (called every 1 second)
 * @param current_A Current measurement (A, positive = discharge)
 * @param voltage_V Pack voltage (V)
 * @param temperature_C Battery temperature (°C)
 */
void SOC_MainFunction(int16_t current_A, uint16_t voltage_V, int16_t temperature_C);

/**
 * @brief Get current SOC estimate
 * @return SOC in percent (0-100)
 */
uint8_t SOC_GetSOC(void);

/**
 * @brief Get remaining capacity
 * @return Remaining capacity (mAh)
 */
uint32_t SOC_GetRemainingCapacity(void);

/**
 * @brief Reset SOC to known value (e.g., after full charge)
 * @param soc_percent New SOC value (%)
 * @return Status code
 */
Std_ReturnType SOC_Reset(uint8_t soc_percent);

/**
 * @brief Get SOC diagnostic data
 * @param[out] diag_data Diagnostic data structure
 * @return Status code
 */
Std_ReturnType SOC_GetDiagnosticData(SOC_DiagData_t* diag_data);

#endif /* SOC_ESTIMATOR_H */

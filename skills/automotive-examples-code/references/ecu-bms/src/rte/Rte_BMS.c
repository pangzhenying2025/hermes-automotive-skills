/**
 * @file Rte_BMS.c
 * @brief AUTOSAR Runtime Environment Implementation
 * @author Automotive Agents Team
 * @date 2026-03-19
 */

#include "Rte_BMS.h"
#include <stdio.h>

#ifdef NATIVE_BUILD
    #include <time.h>
#else
    // On embedded target, use hardware timer
    extern uint32_t HAL_GetTick(void);
#endif

/* ======================== RTE Function Implementations ======================== */

void Rte_Write_CellVoltages(const void* data) {
    // In real implementation, this would:
    // - Copy data to RTE buffer
    // - Trigger inter-runnable communication
    // - Update CAN signals
    (void)data; // Suppress warning
}

void Rte_Write_PackVoltage(uint16_t voltage) {
    // Write to RTE buffer
    (void)voltage;
}

void Rte_Write_SOC(uint8_t soc) {
    // Write to RTE buffer
    (void)soc;
}

void Rte_TriggerFault(uint16_t dtc_code, uint8_t data) {
    // Trigger DTC logging
#ifdef UNIT_TEST
    printf("FAULT: DTC 0x%04X, Data: %d\n", dtc_code, data);
#endif
    (void)dtc_code;
    (void)data;
}

uint32_t Rte_GetTimeMs(void) {
#ifdef NATIVE_BUILD
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint32_t)(ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
#else
    return HAL_GetTick();
#endif
}

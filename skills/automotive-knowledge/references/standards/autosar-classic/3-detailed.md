# AUTOSAR Classic Platform - Detailed Technical Guide

## Complete BSW Module Specifications

This section provides detailed technical documentation for all major AUTOSAR Classic modules.

## 1. Operating System (AUTOSAR OS)

### 1.1 Task Management

#### Task States

```
┌─────────┐  StartTask()   ┌─────────┐
│ SUSPENDED│──────────────→│ READY   │
└─────────┘                └────┬────┘
                                │ Schedule()
                                ↓
                           ┌─────────┐
                           │ RUNNING │
                           └────┬────┘
                                │ TerminateTask()
                                ↓
                           ┌─────────┐
                    ┌─────→│ WAITING │──────┐
                    │      └─────────┘      │
                    │ WaitEvent()  SetEvent()│
                    └────────────────────────┘
```

#### Task Configuration

```c
/* OIL Configuration */
TASK Task_10ms {
    PRIORITY = 10;
    SCHEDULE = FULL;        /* Preemptive */
    ACTIVATION = 1;         /* Single activation */
    AUTOSTART = TRUE {
        APPMODE = AppMode1;
    };
    EVENT = Event_DataReceived;
    RESOURCE = ResourceCAN;
};

/* Task Implementation */
TASK(Task_10ms)
{
    EventMaskType EventMask;

    /* Wait for event */
    WaitEvent(Event_DataReceived);
    GetEvent(Task_10ms, &EventMask);
    ClearEvent(EventMask);

    /* Process data */
    if (EventMask & Event_DataReceived) {
        ProcessCANData();
    }

    TerminateTask();
}
```

#### API Reference

```c
/* Task Control */
StatusType ActivateTask(TaskType TaskID);
StatusType TerminateTask(void);
StatusType ChainTask(TaskType TaskID);
StatusType Schedule(void);
StatusType GetTaskID(TaskRefType TaskID);
StatusType GetTaskState(TaskType TaskID, TaskStateRefType State);

/* Event Control */
StatusType SetEvent(TaskType TaskID, EventMaskType Mask);
StatusType ClearEvent(EventMaskType Mask);
StatusType GetEvent(TaskType TaskID, EventMaskRefType Event);
StatusType WaitEvent(EventMaskType Mask);

/* Resource Management */
StatusType GetResource(ResourceType ResID);
StatusType ReleaseResource(ResourceType ResID);

/* Alarm Management */
StatusType GetAlarmBase(AlarmType AlarmID, AlarmBaseRefType Info);
StatusType GetAlarm(AlarmType AlarmID, TickRefType Tick);
StatusType SetRelAlarm(AlarmType AlarmID, TickType increment, TickType cycle);
StatusType SetAbsAlarm(AlarmType AlarmID, TickType start, TickType cycle);
StatusType CancelAlarm(AlarmType AlarmID);

/* Counter Management */
StatusType IncrementCounter(CounterType CounterID);
StatusType GetCounterValue(CounterType CounterID, TickRefType Value);
StatusType GetElapsedValue(CounterType CounterID, TickRefType Value, TickRefType ElapsedValue);

/* Interrupt Control */
void EnableAllInterrupts(void);
void DisableAllInterrupts(void);
void ResumeAllInterrupts(void);
void SuspendAllInterrupts(void);
void ResumeOSInterrupts(void);
void SuspendOSInterrupts(void);

/* Scheduling Table */
StatusType StartScheduleTableRel(ScheduleTableType ScheduleTableID, TickType Offset);
StatusType StartScheduleTableAbs(ScheduleTableType ScheduleTableID, TickType Start);
StatusType StopScheduleTable(ScheduleTableType ScheduleTableID);
StatusType NextScheduleTable(ScheduleTableType ScheduleTableID_From, ScheduleTableType ScheduleTableID_To);
StatusType GetScheduleTableStatus(ScheduleTableType ScheduleTableID, ScheduleTableStatusRefType ScheduleStatus);
```

### 1.2 Multi-Core Support

#### Core Configuration

```c
/* Core 0 - Safety critical tasks */
OS_CORE Core0 {
    CORE_ID = 0;
    AUTOSTART = TRUE;
    TASKS = {Task_PowertrainControl, Task_BrakingControl};
    ISRS = {ISR_CANReceive};
};

/* Core 1 - Body functions */
OS_CORE Core1 {
    CORE_ID = 1;
    AUTOSTART = TRUE;
    TASKS = {Task_LightControl, Task_ClimateControl};
    ISRS = {ISR_LINReceive};
};
```

#### Inter-Core Communication

```c
/* IOC (Inter-OS-Application Communication) */
StatusType IocSend_Speed(uint16 speed);
StatusType IocReceive_Speed(uint16* speed);

/* Spinlock for shared resource protection */
StatusType GetSpinlock(SpinlockIdType SpinlockId);
StatusType ReleaseSpinlock(SpinlockIdType SpinlockId);
StatusType TryToGetSpinlock(SpinlockIdType SpinlockId, TryToGetSpinlockType* Success);
```

### 1.3 Timing Protection

Prevents tasks from exceeding time budgets:

```c
TASK Task_CriticalControl {
    PRIORITY = 20;
    SCHEDULE = FULL;
    TIMING_PROTECTION = TRUE;
    EXECUTIONBUDGET = 5000;      /* 5ms max execution */
    TIMEFRAME = 10000;           /* Within 10ms window */
    RESOURCELOCK = 1000;         /* Max 1ms resource lock */
};
```

## 2. Communication Stack

### 2.1 COM Module (Communication Manager)

#### Signal Configuration

```c
/* ARXML Configuration */
<I-SIGNAL>
    <SHORT-NAME>VehicleSpeed</SHORT-NAME>
    <I-SIGNAL-TYPE>PRIMITIVE</I-SIGNAL-TYPE>
    <LENGTH>16</LENGTH>
    <INIT-VALUE>0</INIT-VALUE>
</I-SIGNAL>

<I-PDU>
    <SHORT-NAME>Powertrain_PDU</SHORT-NAME>
    <LENGTH>8</LENGTH>
    <I-PDU-TIMING-SPECIFICATION>
        <CYCLIC-TIMING>
            <TX-MODE>
                <TRANSMISSION-MODE-TRUE-TIMING>
                    <CYCLIC-TRANSMISSION>
                        <TIME-PERIOD>0.010</TIME-PERIOD> <!-- 10ms -->
                    </CYCLIC-TRANSMISSION>
                </TRANSMISSION-MODE-TRUE-TIMING>
            </TX-MODE>
        </CYCLIC-TIMING>
    </I-PDU-TIMING-SPECIFICATION>
</I-PDU>
```

#### COM API

```c
/* Signal Transmission */
uint8 Com_SendSignal(Com_SignalIdType SignalId, const void* SignalDataPtr);
uint8 Com_SendSignalGroup(Com_SignalGroupIdType SignalGroupId);
uint8 Com_SendSignalGroupArray(Com_SignalGroupIdType SignalGroupId, const uint8* SignalGroupArrayPtr);

/* Signal Reception */
uint8 Com_ReceiveSignal(Com_SignalIdType SignalId, void* SignalDataPtr);
uint8 Com_ReceiveSignalGroup(Com_SignalGroupIdType SignalGroupId);
uint8 Com_ReceiveSignalGroupArray(Com_SignalGroupIdType SignalGroupId, uint8* SignalGroupArrayPtr);

/* I-PDU Control */
void Com_IpduGroupControl(Com_IpduGroupIdType IpduGroupId, boolean Initialize);
void Com_TxConfirmation(PduIdType TxPduId);
void Com_RxIndication(PduIdType RxPduId, const PduInfoType* PduInfoPtr);

/* Transmission Mode */
void Com_TriggerIPDUSend(PduIdType PduId);
void Com_SwitchIpduTxMode(PduIdType PduId, boolean Mode);
```

#### Signal Filtering

```c
/* Filter Types */
typedef enum {
    COM_FILTER_ALWAYS,
    COM_FILTER_NEVER,
    COM_FILTER_MASKED_NEW_EQUALS_X,
    COM_FILTER_MASKED_NEW_DIFFERS_X,
    COM_FILTER_NEW_IS_OUTSIDE,
    COM_FILTER_NEW_IS_WITHIN,
    COM_FILTER_ONE_EVERY_N
} Com_FilterAlgorithmType;

/* Filter Configuration Example */
<COM-SIGNAL>
    <FILTER>
        <FILTER-ALGORITHM>NEW_IS_OUTSIDE</FILTER-ALGORITHM>
        <FILTER-MIN>100</FILTER-MIN>
        <FILTER-MAX>200</FILTER-MAX>
    </FILTER>
</COM-SIGNAL>
```

### 2.2 PduR (PDU Router)

#### Routing Configuration

```c
/* ARXML Routing Paths */
<PDU-ROUTER>
    <ROUTING-PATHS>
        <ROUTING-PATH>
            <SHORT-NAME>Route_CAN_to_COM</SHORT-NAME>
            <SOURCE-PDU>CanIf_RxPdu_0x123</SOURCE-PDU>
            <DESTINATION-PDU>Com_RxPdu_Speed</DESTINATION-PDU>
        </ROUTING-PATH>
        <ROUTING-PATH>
            <SHORT-NAME>Route_COM_to_CAN</SHORT-NAME>
            <SOURCE-PDU>Com_TxPdu_Torque</SOURCE-PDU>
            <DESTINATION-PDU>CanIf_TxPdu_0x456</DESTINATION-PDU>
        </ROUTING-PATH>
    </ROUTING-PATHS>
</PDU-ROUTER>
```

#### PduR API

```c
/* Transmission */
Std_ReturnType PduR_ComTransmit(PduIdType TxPduId, const PduInfoType* PduInfoPtr);
Std_ReturnType PduR_DcmTransmit(PduIdType TxPduId, const PduInfoType* PduInfoPtr);

/* Reception */
void PduR_CanIfRxIndication(PduIdType RxPduId, const PduInfoType* PduInfoPtr);
void PduR_CanTpRxIndication(PduIdType id, Std_ReturnType result);

/* Transmission Confirmation */
void PduR_CanIfTxConfirmation(PduIdType TxPduId);
void PduR_CanTpTxConfirmation(PduIdType id, Std_ReturnType result);

/* Gateway - Multi-destination routing */
void PduR_CanIfRxIndication(PduIdType RxPduId, const PduInfoType* PduInfoPtr);
/* Routes to: COM + Gateway destination CAN/LIN/FlexRay */
```

### 2.3 CAN Stack

#### CanIf (CAN Interface)

```c
/* Configuration */
<CAN-IF-INIT-CONFIGURATION>
    <CAN-IF-RX-PDU-CONFIG>
        <SHORT-NAME>RxPdu_VehicleSpeed</SHORT-NAME>
        <CAN-ID>0x123</CAN-ID>
        <CAN-ID-TYPE>STANDARD</CAN-ID-TYPE>
        <DLC>8</DLC>
        <UPPER-LAYER-PDU-ID>ComRxPdu_Speed</UPPER-LAYER-PDU-ID>
    </CAN-IF-RX-PDU-CONFIG>
    <CAN-IF-TX-PDU-CONFIG>
        <SHORT-NAME>TxPdu_EngTorque</SHORT-NAME>
        <CAN-ID>0x456</CAN-ID>
        <HTH-REF>/Can/CanConfigSet/HTH_0</HTH-REF>
    </CAN-IF-TX-PDU-CONFIG>
</CAN-IF-INIT-CONFIGURATION>

/* CanIf API */
Std_ReturnType CanIf_Transmit(PduIdType TxPduId, const PduInfoType* PduInfoPtr);
Std_ReturnType CanIf_SetControllerMode(uint8 ControllerId, CanIf_ControllerModeType ControllerMode);
Std_ReturnType CanIf_GetControllerMode(uint8 ControllerId, CanIf_ControllerModeType* ControllerModePtr);
void CanIf_RxIndication(const Can_HwType* Mailbox, const PduInfoType* PduInfoPtr);
void CanIf_TxConfirmation(PduIdType CanTxPduId);
```

#### CanTp (CAN Transport Protocol)

ISO 15765-2 implementation for multi-frame messages:

```c
/* Frame Types */
typedef enum {
    CANTP_SF,  /* Single Frame (<=7 bytes) */
    CANTP_FF,  /* First Frame (>7 bytes) */
    CANTP_CF,  /* Consecutive Frame */
    CANTP_FC   /* Flow Control */
} CanTp_FrameType;

/* Configuration */
<CAN-TP-CONFIG>
    <CAN-TP-CHANNEL>
        <SHORT-NAME>DiagChannel</SHORT-NAME>
        <BS>8</BS>              <!-- Block Size -->
        <STMIN>10</STMIN>       <!-- Separation Time Min (ms) -->
        <N_As>1000</N_As>       <!-- Timeout for sender -->
        <N_Bs>1000</N_Bs>       <!-- Timeout for receiver -->
        <N_Cr>1000</N_Cr>       <!-- Timeout for consecutive frame -->
    </CAN-TP-CHANNEL>
</CAN-TP-CONFIG>

/* CanTp API */
Std_ReturnType CanTp_Transmit(PduIdType TxPduId, const PduInfoType* PduInfoPtr);
Std_ReturnType CanTp_CancelTransmit(PduIdType TxPduId);
Std_ReturnType CanTp_CancelReceive(PduIdType RxPduId);
```

#### Can Driver

```c
/* MCAL Can Driver API */
Std_ReturnType Can_SetControllerMode(uint8 Controller, Can_StateTransitionType Transition);
Std_ReturnType Can_Write(Can_HwHandleType Hth, const Can_PduType* PduInfo);
void Can_MainFunction_Write(void);
void Can_MainFunction_Read(void);
void Can_MainFunction_BusOff(void);
void Can_MainFunction_Wakeup(void);
void Can_MainFunction_Mode(void);

/* Hardware Object Configuration */
<CAN-HARDWARE-OBJECT>
    <SHORT-NAME>HTH_0</SHORT-NAME>
    <CAN-OBJECT-TYPE>TRANSMIT</CAN-OBJECT-TYPE>
    <CAN-ID-TYPE>STANDARD</CAN-ID-TYPE>
    <CAN-HW-OBJECT-COUNT>32</CAN-HW-OBJECT-COUNT>
</CAN-HARDWARE-OBJECT>

<CAN-CONTROLLER>
    <SHORT-NAME>CanController_0</SHORT-NAME>
    <CAN-CONTROLLER-BAUDRATE>500</CAN-CONTROLLER-BAUDRATE> <!-- kbps -->
    <CAN-CONTROLLER-FD-BAUDRATE>2000</CAN-CONTROLLER-FD-BAUDRATE> <!-- CAN-FD data phase -->
</CAN-CONTROLLER>
```

## 3. Diagnostic Services

### 3.1 Dcm (Diagnostic Communication Manager)

#### UDS Service Implementation

```c
/* Service Handler Function Prototype */
typedef Std_ReturnType (*Dcm_ServiceHandler)(
    Dcm_OpStatusType OpStatus,
    Dcm_MsgContextType *pMsgContext,
    Dcm_NegativeResponseCodeType *ErrorCode
);

/* Service 0x10: Diagnostic Session Control */
Std_ReturnType Dcm_DiagnosticSessionControl(
    Dcm_OpStatusType OpStatus,
    Dcm_MsgContextType *pMsgContext,
    Dcm_NegativeResponseCodeType *ErrorCode)
{
    uint8 sessionType = pMsgContext->reqData[0];

    switch(sessionType) {
        case DCM_DEFAULT_SESSION:
        case DCM_PROGRAMMING_SESSION:
        case DCM_EXTENDED_DIAGNOSTIC_SESSION:
            /* Change session */
            Dcm_SetSesCtrlType(sessionType);
            /* Prepare positive response */
            pMsgContext->resData[0] = sessionType;
            pMsgContext->resDataLen = 1;
            return E_OK;
        default:
            *ErrorCode = DCM_E_SUBFUNCTIONNOTSUPPORTED;
            return E_NOT_OK;
    }
}

/* Service 0x22: Read Data By Identifier */
Std_ReturnType Dcm_ReadDataByIdentifier(
    Dcm_OpStatusType OpStatus,
    Dcm_MsgContextType *pMsgContext,
    Dcm_NegativeResponseCodeType *ErrorCode)
{
    uint16 dataId = (pMsgContext->reqData[0] << 8) | pMsgContext->reqData[1];

    /* Call configured read function */
    return Dcm_ReadDidData(dataId, &pMsgContext->resData[2], ErrorCode);
}

/* Service 0x2E: Write Data By Identifier */
Std_ReturnType Dcm_WriteDataByIdentifier(
    Dcm_OpStatusType OpStatus,
    Dcm_MsgContextType *pMsgContext,
    Dcm_NegativeResponseCodeType *ErrorCode)
{
    uint16 dataId = (pMsgContext->reqData[0] << 8) | pMsgContext->reqData[1];
    uint8 *data = &pMsgContext->reqData[2];
    uint16 dataLen = pMsgContext->reqDataLen - 2;

    /* Check security access */
    if (!Dcm_GetSecurityLevel()) {
        *ErrorCode = DCM_E_SECURITYACCESSDENIED;
        return E_NOT_OK;
    }

    return Dcm_WriteDidData(dataId, data, dataLen, ErrorCode);
}

/* Service 0x27: Security Access */
Std_ReturnType Dcm_SecurityAccess(
    Dcm_OpStatusType OpStatus,
    Dcm_MsgContextType *pMsgContext,
    Dcm_NegativeResponseCodeType *ErrorCode)
{
    uint8 subFunction = pMsgContext->reqData[0];

    if (subFunction % 2 == 1) {
        /* Request Seed */
        Dcm_GetSecuritySeed(pMsgContext->resData, pMsgContext->resDataLen);
    } else {
        /* Send Key */
        uint8 *key = &pMsgContext->reqData[1];
        if (Dcm_CompareKey(key)) {
            Dcm_UnlockSecurity();
            return E_OK;
        } else {
            *ErrorCode = DCM_E_INVALIDKEY;
            return E_NOT_OK;
        }
    }
    return E_OK;
}
```

#### Dcm Configuration

```c
<DCM-CONFIG-SET>
    <DCM-DSP>
        <DCM-DSP-SESSION>
            <DCM-DSP-SESSION-ROW>
                <SHORT-NAME>DefaultSession</SHORT-NAME>
                <DCM-DSP-SESSION-LEVEL>1</DCM-DSP-SESSION-LEVEL>
                <DCM-DSP-SESSION-P2-SERVER-MAX>50</DCM-DSP-SESSION-P2-SERVER-MAX>
                <DCM-DSP-SESSION-P2-STAR-SERVER-MAX>5000</DCM-DSP-SESSION-P2-STAR-SERVER-MAX>
            </DCM-DSP-SESSION-ROW>
        </DCM-DSP-SESSION>

        <DCM-DSP-DID>
            <DCM-DSP-DID-INFO>
                <SHORT-NAME>VehicleSpeed_DID</SHORT-NAME>
                <DCM-DSP-DID-IDENTIFIER>0xF190</DCM-DSP-DID-IDENTIFIER>
                <DCM-DSP-DID-READ>
                    <DCM-DSP-DID-READ-FNC>App_ReadVehicleSpeed</DCM-DSP-DID-READ-FNC>
                </DCM-DSP-DID-READ>
            </DCM-DSP-DID-INFO>
        </DCM-DSP-DID>
    </DCM-DSP>
</DCM-CONFIG-SET>
```

### 3.2 Dem (Diagnostic Event Manager)

#### Event Configuration

```c
<DEM-EVENT-PARAMETER>
    <SHORT-NAME>DTC_EngineOverheat</SHORT-NAME>
    <DEM-DTC-REF>/DTC/P0118</DEM-DTC-REF>
    <DEM-EVENT-KIND>DEM_EVENT_KIND_BSW</DEM-EVENT-KIND>
    <DEM-OPERATION-CYCLE-REF>/Cycles/PowerCycle</DEM-OPERATION-CYCLE-REF>
    <DEM-ENABLE-CONDITION-GROUP-REF>/Conditions/EngineRunning</DEM-ENABLE-CONDITION-GROUP-REF>
    <DEM-DEBOUNCE-COUNTER-BASED>
        <DEM-DEBOUNCE-COUNTER-INCREMENT-STEP-SIZE>1</DEM-DEBOUNCE-COUNTER-INCREMENT-STEP-SIZE>
        <DEM-DEBOUNCE-COUNTER-DECREMENT-STEP-SIZE>1</DEM-DEBOUNCE-COUNTER-DECREMENT-STEP-SIZE>
        <DEM-DEBOUNCE-COUNTER-PASSED-THRESHOLD>5</DEM-DEBOUNCE-COUNTER-PASSED-THRESHOLD>
        <DEM-DEBOUNCE-COUNTER-FAILED-THRESHOLD>5</DEM-DEBOUNCE-COUNTER-FAILED-THRESHOLD>
    </DEM-DEBOUNCE-COUNTER-BASED>
</DEM-EVENT-PARAMETER>
```

#### Dem API

```c
/* Event Reporting */
Std_ReturnType Dem_SetEventStatus(Dem_EventIdType EventId, Dem_EventStatusType EventStatus);
Std_ReturnType Dem_ResetEventStatus(Dem_EventIdType EventId);
Std_ReturnType Dem_ResetEventDebounceStatus(Dem_EventIdType EventId, Dem_DebounceResetStatusType DebounceResetStatus);

/* Event Status */
typedef enum {
    DEM_EVENT_STATUS_PASSED = 0x00,
    DEM_EVENT_STATUS_FAILED = 0x01,
    DEM_EVENT_STATUS_PREPASSED = 0x02,
    DEM_EVENT_STATUS_PREFAILED = 0x03
} Dem_EventStatusType;

/* DTC Storage */
Std_ReturnType Dem_GetEventFailed(Dem_EventIdType EventId, boolean* EventFailed);
Std_ReturnType Dem_GetEventTested(Dem_EventIdType EventId, boolean* EventTested);
Std_ReturnType Dem_GetDTCOfEvent(Dem_EventIdType EventId, Dem_DTCFormatType DTCFormat, uint32* DTCOfEvent);

/* Freeze Frame (Snapshot) */
Std_ReturnType Dem_GetEventFreezeFrameData(
    Dem_EventIdType EventId,
    uint8 RecordNumber,
    uint16 DataId,
    uint8* DestBuffer,
    uint16* BufSize
);

/* Extended Data Record */
Std_ReturnType Dem_GetEventExtendedDataRecord(
    Dem_EventIdType EventId,
    uint8 RecordNumber,
    uint8* DestBuffer,
    uint16* BufSize
);

/* Usage Example */
void CheckEngineTemperature(void)
{
    uint16 temperature = ReadEngineTemp();

    if (temperature > THRESHOLD_OVERHEAT) {
        Dem_SetEventStatus(DemEventId_EngineOverheat, DEM_EVENT_STATUS_FAILED);
    } else {
        Dem_SetEventStatus(DemEventId_EngineOverheat, DEM_EVENT_STATUS_PASSED);
    }
}
```

#### DTC Status Byte

```
Bit 7: WarningIndicatorRequested
Bit 6: Reserved
Bit 5: ConfirmedDTC
Bit 4: TestNotCompletedSinceLastClear
Bit 3: TestFailedSinceLastClear
Bit 2: PendingDTC
Bit 1: TestNotCompletedThisOperationCycle
Bit 0: TestFailed
```

## 4. Memory Management

### 4.1 NvM (Non-Volatile Memory Manager)

#### Block Configuration

```c
<NVM-BLOCK-DESCRIPTOR>
    <SHORT-NAME>NvM_Block_Calibration</SHORT-NAME>
    <NVM-BLOCK-ID>1</NVM-BLOCK-ID>
    <NVM-BLOCK-LENGTH>256</NVM-BLOCK-LENGTH>
    <NVM-BLOCK-USE-CRC>TRUE</NVM-BLOCK-USE-CRC>
    <NVM-BLOCK-CRC-TYPE>CRC_16</NVM-BLOCK-CRC-TYPE>
    <NVM-RESISTANCE-TO-CHANGED-SW>TRUE</NVM-RESISTANCE-TO-CHANGED-SW>
    <NVM-REDUNDANT-BLOCK>TRUE</NVM-REDUNDANT-BLOCK>
    <NVM-WRITE-VERIFICATION>TRUE</NVM-WRITE-VERIFICATION>
</NVM-BLOCK-DESCRIPTOR>
```

#### NvM API

```c
/* Block Operations */
Std_ReturnType NvM_ReadBlock(NvM_BlockIdType BlockId, void* NvM_DstPtr);
Std_ReturnType NvM_WriteBlock(NvM_BlockIdType BlockId, const void* NvM_SrcPtr);
Std_ReturnType NvM_RestoreBlockDefaults(NvM_BlockIdType BlockId, void* NvM_DestPtr);
Std_ReturnType NvM_EraseNvBlock(NvM_BlockIdType BlockId);
Std_ReturnType NvM_InvalidateNvBlock(NvM_BlockIdType BlockId);

/* Status */
Std_ReturnType NvM_GetErrorStatus(NvM_BlockIdType BlockId, NvM_RequestResultType* RequestResultPtr);

/* Usage Example */
typedef struct {
    uint32 VehicleMileage;
    uint16 ServiceInterval;
    uint8 CalibrationVersion;
} CalibrationData_t;

CalibrationData_t g_CalData;

void InitCalibration(void)
{
    NvM_RequestResultType result;

    /* Read from NV memory */
    if (NvM_ReadBlock(NvMBlockId_Calibration, &g_CalData) == E_OK) {
        /* Wait for completion */
        do {
            NvM_GetErrorStatus(NvMBlockId_Calibration, &result);
        } while (result == NVM_REQ_PENDING);

        if (result != NVM_REQ_OK) {
            /* Load defaults */
            NvM_RestoreBlockDefaults(NvMBlockId_Calibration, &g_CalData);
        }
    }
}

void UpdateMileage(uint32 newMileage)
{
    g_CalData.VehicleMileage = newMileage;
    NvM_WriteBlock(NvMBlockId_Calibration, &g_CalData);
}
```

### 4.2 Memory Stack Architecture

```
Application
     ↓↑
   NvM (NV Memory Manager)
     ↓↑
   MemIf (Memory Abstraction Interface)
     ↓↑                    ↓↑
   Fee (Flash EEPROM)     Ea (EEPROM Abstraction)
     ↓↑                    ↓↑
   Fls (Flash Driver)    Eep (EEPROM Driver)
     ↓↑                    ↓↑
  Flash Hardware        EEPROM Hardware
```

## 5. ECU State Management

### 5.1 EcuM (ECU State Manager)

#### Startup Sequence

```c
/* Phase 0: Pre-OS Initialization */
void EcuM_Init(void)
{
    /* Initialize MCU */
    Mcu_Init(&McuConfig);
    Mcu_InitClock(McuClockSettingConfig);
    Mcu_SetMode(MCU_MODE_NORMAL);

    /* Initialize drivers */
    Port_Init(&PortConfig);
    Dio_Init(&DioConfig);
    Can_Init(&CanConfig);

    /* Initialize OS but don't start */
    EcuM_AL_DriverInitZero();
}

/* Phase 1: OS Started, Basic Init */
void EcuM_StartupTwo(void)
{
    /* Initialize BSW modules */
    CanIf_Init(&CanIfConfig);
    Com_Init(&ComConfig);
    PduR_Init(&PduRConfig);

    /* Initialize services */
    Dem_Init(&DemConfig);
    NvM_Init();

    EcuM_AL_DriverInitOne();
}

/* Phase 2: Run Requests */
void EcuM_AL_DriverInitThree(void)
{
    /* Initialize application-level services */
    Dcm_Init(&DcmConfig);

    /* Start communication */
    CanSM_Init(&CanSMConfig);
    ComM_Init(&ComMConfig);

    /* Indicate ready */
    BswM_Init(&BswMConfig);
    EcuM_SetState(ECUM_STATE_APP_RUN);
}
```

#### Shutdown Sequence

```c
void EcuM_GoDown(void)
{
    /* Phase 1: Stop application */
    EcuM_OnGoOffOne();

    /* Phase 2: Stop communication */
    ComM_DeInit();
    CanIf_SetControllerMode(0, CANIF_CS_STOPPED);

    /* Phase 3: Store NV data */
    NvM_WriteAll();

    /* Phase 4: Prepare for sleep/off */
    EcuM_OnGoOffTwo();

    /* Enter sleep or off mode */
    if (wakeupPending) {
        Mcu_SetMode(MCU_MODE_SLEEP);
    } else {
        Mcu_SetMode(MCU_MODE_OFF);
    }
}
```

### 5.2 BswM (BSW Mode Manager)

#### Mode Rules

```c
<BSWM-RULE>
    <SHORT-NAME>Rule_StartCommunication</SHORT-NAME>
    <BSWM-RULE-EXPRESSION>
        <BSWM-AND>
            <BSWM-MODE-CONDITION>
                <BSWM-MODE-REQUEST-SOURCE>EcuM</BSWM-MODE-REQUEST-SOURCE>
                <BSWM-REQUESTED-MODE>RUN</BSWM-REQUESTED-MODE>
            </BSWM-MODE-CONDITION>
            <BSWM-MODE-CONDITION>
                <BSWM-MODE-REQUEST-SOURCE>ComM</BSWM-MODE-REQUEST-SOURCE>
                <BSWM-REQUESTED-MODE>FULL_COMMUNICATION</BSWM-REQUESTED-MODE>
            </BSWM-MODE-CONDITION>
        </BSWM-AND>
    </BSWM-RULE-EXPRESSION>
    <BSWM-ACTION-LIST-REF>ActionList_EnableCAN</BSWM-ACTION-LIST-REF>
</BSWM-RULE>
```

## 6. Security (SecOC)

### 6.1 Message Authentication

```c
<SEC-OC-TX-SECURE-PDU>
    <SHORT-NAME>SecPdu_EngTorque</SHORT-NAME>
    <SEC-OC-AUTH-ALGORITHM>CMAC_AES128</SEC-OC-AUTH-ALGORITHM>
    <SEC-OC-AUTH-TX-LENGTH>4</SEC-OC-AUTH-TX-LENGTH>
    <SEC-OC-FRESHNESS-VALUE-LENGTH>4</SEC-OC-FRESHNESS-VALUE-LENGTH>
    <SEC-OC-DATA-ID>0x1234</SEC-OC-DATA-ID>
</SEC-OC-TX-SECURE-PDU>

/* Secured Message Format */
/*
| Payload (n bytes) | Freshness Value (4 bytes) | MAC (4 bytes) |
*/

/* SecOC API */
Std_ReturnType SecOC_VerifyStatusOverride(
    uint16 freshnessValueID,
    uint8 overrideStatus,
    uint8 numberOfMessagesToOverride
);
```

## 7. Complex Device Drivers (CDD)

Used for time-critical functions bypassing RTE:

```c
/* CDD Example: High-speed PWM Control */
void CDD_PwmControl_MainFunction(void)
{
    uint16 torqueRequest;

    /* Direct hardware access */
    torqueRequest = *((volatile uint16*)TORQUE_REGISTER);

    /* Calculate PWM duty cycle */
    uint16 dutyCycle = (torqueRequest * PWM_MAX) / TORQUE_MAX;

    /* Direct PWM update */
    PWM_HARDWARE_REG = dutyCycle;
}
```

## Summary

This detailed guide covers:
- Complete OS API with multi-core and timing protection
- Full communication stack (COM, PduR, CAN, CanTp)
- Diagnostic services (Dcm, Dem) with UDS implementation
- Memory management (NvM) with redundancy and CRC
- ECU state management (EcuM, BswM)
- Security features (SecOC)
- Complex device drivers

## Next Steps

- **Level 4**: Complete API reference, all modules, configuration parameters
- **Level 5**: Advanced optimization, certification artifacts, real-world examples

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Page Count**: 45 pages
**Target Audience**: Experienced AUTOSAR developers implementing systems

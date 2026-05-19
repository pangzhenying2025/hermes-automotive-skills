# AUTOSAR Classic Platform - Complete Reference Manual

## Document Scope

This reference provides comprehensive API documentation, configuration parameters, and specifications for all AUTOSAR Classic Platform modules (R22-11).

**Total Content**: 100+ pages covering 80+ BSW modules

## Part I: Operating System Reference

### AUTOSAR OS API Complete Reference

#### Data Types

```c
/* Task Types */
typedef uint8 TaskType;
typedef TaskType *TaskRefType;
typedef uint8 TaskStateType;
typedef TaskStateType *TaskStateRefType;
typedef uint32 EventMaskType;
typedef EventMaskType *EventMaskRefType;

/* Resource Types */
typedef uint8 ResourceType;

/* Alarm Types */
typedef uint8 AlarmType;
typedef struct {
    TickType maxallowedvalue;
    TickType ticksperbase;
    TickType mincycle;
} AlarmBaseType;
typedef AlarmBaseType *AlarmBaseRefType;

/* Counter Types */
typedef uint32 TickType;
typedef TickType *TickRefType;
typedef uint8 CounterType;

/* Schedule Table Types */
typedef uint8 ScheduleTableType;
typedef enum {
    SCHEDULETABLE_STOPPED,
    SCHEDULETABLE_NEXT,
    SCHEDULETABLE_WAITING,
    SCHEDULETABLE_RUNNING,
    SCHEDULETABLE_RUNNING_AND_SYNCHRONOUS
} ScheduleTableStatusType;
typedef ScheduleTableStatusType *ScheduleTableStatusRefType;

/* Application Types */
typedef uint8 ApplicationType;
typedef enum {
    APPLICATION,
    TASK,
    ISR2,
    SCHEDULETABLE
} ObjectTypeType;

/* Memory Protection */
typedef uint32 MemoryStartAddressType;
typedef uint32 MemorySizeType;
typedef enum {
    NO_ACCESS,
    ACCESS
} AccessType;

/* Multicore Types */
typedef uint8 CoreIdType;
typedef uint32 SpinlockIdType;
typedef enum {
    TRYTOGETSPINLOCK_NOSUCCESS = 0,
    TRYTOGETSPINLOCK_SUCCESS = 1
} TryToGetSpinlockType;

/* Status Types */
typedef uint8 StatusType;
#define E_OK                    ((StatusType)0)
#define E_OS_ACCESS             ((StatusType)1)
#define E_OS_CALLEVEL           ((StatusType)2)
#define E_OS_ID                 ((StatusType)3)
#define E_OS_LIMIT              ((StatusType)4)
#define E_OS_NOFUNC             ((StatusType)5)
#define E_OS_RESOURCE           ((StatusType)6)
#define E_OS_STATE              ((StatusType)7)
#define E_OS_VALUE              ((StatusType)8)
#define E_OS_SERVICEID          ((StatusType)9)
#define E_OS_ILLEGAL_ADDRESS    ((StatusType)10)
#define E_OS_MISSINGEND         ((StatusType)11)
#define E_OS_DISABLEDINT        ((StatusType)12)
#define E_OS_STACKFAULT         ((StatusType)13)
#define E_OS_PROTECTION_MEMORY  ((StatusType)14)
#define E_OS_PROTECTION_TIME    ((StatusType)15)
#define E_OS_PROTECTION_ARRIVAL ((StatusType)16)
#define E_OS_PROTECTION_LOCKED  ((StatusType)17)
#define E_OS_PROTECTION_EXCEPTION ((StatusType)18)
#define E_OS_CORE               ((StatusType)19)
#define E_OS_SPINLOCK           ((StatusType)20)
#define E_OS_INTERFERENCE_DEADLOCK ((StatusType)21)
#define E_OS_NESTING_DEADLOCK   ((StatusType)22)

/* Application Modes */
typedef uint8 AppModeType;
#define OSDEFAULTAPPMODE        ((AppModeType)0)

/* Protection Hook */
typedef enum {
    PRO_IGNORE,
    PRO_TERMINATETASKISR,
    PRO_TERMINATEAPPL,
    PRO_TERMINATEAPPL_RESTART,
    PRO_SHUTDOWN
} ProtectionReturnType;

/* Service IDs for error hooks */
#define OSServiceId_ActivateTask               ((OSServiceIdType)0)
#define OSServiceId_TerminateTask              ((OSServiceIdType)1)
#define OSServiceId_ChainTask                  ((OSServiceIdType)2)
#define OSServiceId_Schedule                   ((OSServiceIdType)3)
#define OSServiceId_GetTaskID                  ((OSServiceIdType)4)
#define OSServiceId_GetTaskState               ((OSServiceIdType)5)
#define OSServiceId_EnableAllInterrupts        ((OSServiceIdType)6)
#define OSServiceId_DisableAllInterrupts       ((OSServiceIdType)7)
#define OSServiceId_ResumeAllInterrupts        ((OSServiceIdType)8)
#define OSServiceId_SuspendAllInterrupts       ((OSServiceIdType)9)
#define OSServiceId_ResumeOSInterrupts         ((OSServiceIdType)10)
#define OSServiceId_SuspendOSInterrupts        ((OSServiceIdType)11)
#define OSServiceId_GetResource                ((OSServiceIdType)12)
#define OSServiceId_ReleaseResource            ((OSServiceIdType)13)
#define OSServiceId_SetEvent                   ((OSServiceIdType)14)
#define OSServiceId_ClearEvent                 ((OSServiceIdType)15)
#define OSServiceId_GetEvent                   ((OSServiceIdType)16)
#define OSServiceId_WaitEvent                  ((OSServiceIdType)17)
#define OSServiceId_GetAlarmBase               ((OSServiceIdType)18)
#define OSServiceId_GetAlarm                   ((OSServiceIdType)19)
#define OSServiceId_SetRelAlarm                ((OSServiceIdType)20)
#define OSServiceId_SetAbsAlarm                ((OSServiceIdType)21)
#define OSServiceId_CancelAlarm                ((OSServiceIdType)22)
```

#### Complete API Functions

```c
/**
 * @brief Activates a task
 * @param[in] TaskID Task identifier
 * @return E_OK: No error
 *         E_OS_ID: TaskID is invalid
 *         E_OS_LIMIT: Too many task activations
 */
StatusType ActivateTask(TaskType TaskID);

/**
 * @brief Terminates the calling task
 * @return E_OK: No error (never returned)
 *         E_OS_RESOURCE: Task still occupies resources
 *         E_OS_CALLEVEL: Call at interrupt level
 */
StatusType TerminateTask(void);

/**
 * @brief Terminates calling task and activates successor task
 * @param[in] TaskID Task identifier of successor
 * @return E_OK: No error (never returned)
 *         E_OS_ID: TaskID invalid
 *         E_OS_LIMIT: Too many activations
 *         E_OS_RESOURCE: Task still occupies resources
 */
StatusType ChainTask(TaskType TaskID);

/**
 * @brief Forces rescheduling
 * @return E_OK: No error
 *         E_OS_CALLEVEL: Call at interrupt level
 *         E_OS_RESOURCE: Task occupies resource
 */
StatusType Schedule(void);

/**
 * @brief Returns the currently running task ID
 * @param[out] TaskID Pointer to store task ID
 * @return E_OK: No error
 */
StatusType GetTaskID(TaskRefType TaskID);

/**
 * @brief Returns task state
 * @param[in] TaskID Task identifier
 * @param[out] State Pointer to store state
 * @return E_OK: No error
 *         E_OS_ID: TaskID invalid
 */
StatusType GetTaskState(TaskType TaskID, TaskStateRefType State);

/**
 * @brief Sets event for extended task
 * @param[in] TaskID Task identifier
 * @param[in] Mask Event mask to set
 * @return E_OK: No error
 *         E_OS_ID: TaskID invalid
 *         E_OS_ACCESS: Task is not extended
 *         E_OS_STATE: Task is suspended
 */
StatusType SetEvent(TaskType TaskID, EventMaskType Mask);

/**
 * @brief Clears events of calling task
 * @param[in] Mask Event mask to clear
 * @return E_OK: No error
 *         E_OS_ACCESS: Task is not extended
 *         E_OS_CALLEVEL: Call at interrupt level
 */
StatusType ClearEvent(EventMaskType Mask);

/**
 * @brief Returns current event state
 * @param[in] TaskID Task identifier
 * @param[out] Event Pointer to store event mask
 * @return E_OK: No error
 *         E_OS_ID: TaskID invalid
 *         E_OS_ACCESS: Task is not extended
 *         E_OS_STATE: Task is suspended
 */
StatusType GetEvent(TaskType TaskID, EventMaskRefType Event);

/**
 * @brief Waits for events
 * @param[in] Mask Event mask to wait for
 * @return E_OK: No error
 *         E_OS_ACCESS: Task is not extended
 *         E_OS_RESOURCE: Task occupies resource
 *         E_OS_CALLEVEL: Call at interrupt level
 */
StatusType WaitEvent(EventMaskType Mask);

/**
 * @brief Occupies a resource
 * @param[in] ResID Resource identifier
 * @return E_OK: No error
 *         E_OS_ID: ResID invalid
 *         E_OS_ACCESS: Resource cannot be accessed
 */
StatusType GetResource(ResourceType ResID);

/**
 * @brief Releases a resource
 * @param[in] ResID Resource identifier
 * @return E_OK: No error
 *         E_OS_ID: ResID invalid
 *         E_OS_NOFUNC: Resource not occupied
 *         E_OS_ACCESS: Wrong order of release
 */
StatusType ReleaseResource(ResourceType ResID);

/**
 * @brief Starts schedule table (relative)
 * @param[in] ScheduleTableID Schedule table identifier
 * @param[in] Offset Relative offset in ticks
 * @return E_OK: No error
 *         E_OS_ID: ScheduleTableID invalid
 *         E_OS_VALUE: Offset is greater than OsCounterMaxAllowedValue
 *         E_OS_STATE: Schedule table already started
 */
StatusType StartScheduleTableRel(ScheduleTableType ScheduleTableID, TickType Offset);

/**
 * @brief Starts schedule table (absolute)
 * @param[in] ScheduleTableID Schedule table identifier
 * @param[in] Start Absolute tick value
 * @return E_OK: No error
 *         E_OS_ID: ScheduleTableID invalid
 *         E_OS_VALUE: Start is greater than OsCounterMaxAllowedValue
 *         E_OS_STATE: Schedule table already started
 */
StatusType StartScheduleTableAbs(ScheduleTableType ScheduleTableID, TickType Start);

/**
 * @brief Stops schedule table
 * @param[in] ScheduleTableID Schedule table identifier
 * @return E_OK: No error
 *         E_OS_ID: ScheduleTableID invalid
 *         E_OS_NOFUNC: Schedule table not started
 */
StatusType StopScheduleTable(ScheduleTableType ScheduleTableID);

/**
 * @brief Switches to next schedule table
 * @param[in] ScheduleTableID_From Current schedule table
 * @param[in] ScheduleTableID_To Next schedule table
 * @return E_OK: No error
 *         E_OS_ID: ScheduleTableID invalid
 *         E_OS_NOFUNC: ScheduleTableID_From not started
 *         E_OS_STATE: ScheduleTableID_To already started
 */
StatusType NextScheduleTable(
    ScheduleTableType ScheduleTableID_From,
    ScheduleTableType ScheduleTableID_To
);

/**
 * @brief Gets current ID of application
 * @return Application ID or INVALID_OSAPPLICATION
 */
ApplicationType GetApplicationID(void);

/**
 * @brief Gets ID of calling ISR
 * @return ISR ID or INVALID_ISR
 */
ISRType GetISRID(void);

/**
 * @brief Terminates application
 * @param[in] Application Application ID
 * @param[in] RestartOption Restart option
 * @return E_OK: No error
 *         E_OS_ID: Application invalid
 *         E_OS_VALUE: RestartOption invalid
 *         E_OS_ACCESS: Caller not allowed to terminate application
 *         E_OS_STATE: Application not in correct state
 */
StatusType TerminateApplication(ApplicationType Application, RestartType RestartOption);

/**
 * @brief Gets spinlock
 * @param[in] SpinlockId Spinlock identifier
 * @return E_OK: Spinlock successfully obtained
 *         E_OS_ID: SpinlockId invalid
 *         E_OS_INTERFERENCE_DEADLOCK: Deadlock detected
 *         E_OS_NESTING_DEADLOCK: Nesting order violation
 */
StatusType GetSpinlock(SpinlockIdType SpinlockId);

/**
 * @brief Releases spinlock
 * @param[in] SpinlockId Spinlock identifier
 * @return E_OK: Spinlock successfully released
 *         E_OS_ID: SpinlockId invalid
 *         E_OS_NOFUNC: Spinlock not occupied
 *         E_OS_ACCESS: Wrong order of release
 */
StatusType ReleaseSpinlock(SpinlockIdType SpinlockId);

/**
 * @brief Tries to get spinlock non-blocking
 * @param[in] SpinlockId Spinlock identifier
 * @param[out] Success Success status
 * @return E_OK: Function executed successfully
 *         E_OS_ID: SpinlockId invalid
 *         E_OS_INTERFERENCE_DEADLOCK: Deadlock detected
 *         E_OS_NESTING_DEADLOCK: Nesting order violation
 */
StatusType TryToGetSpinlock(SpinlockIdType SpinlockId, TryToGetSpinlockType* Success);

/**
 * @brief Shuts down operating system
 * @param[in] Error Error code
 */
void ShutdownOS(StatusType Error);

/**
 * @brief Starts operating system
 * @param[in] Mode Application mode
 */
void StartOS(AppModeType Mode);

/**
 * @brief Gets active application mode
 * @return Application mode
 */
AppModeType GetActiveApplicationMode(void);

/**
 * @brief Gets ID of core
 * @return Core ID
 */
CoreIdType GetCoreID(void);

/**
 * @brief Starts non-autostart core
 * @param[in] CoreID Core identifier
 * @param[out] Status Return status
 * @return E_OK: No error
 *         E_OS_ID: CoreID invalid
 *         E_OS_STATE: Core already started
 */
void StartNonAutosarCore(CoreIdType CoreID, StatusType* Status);

/**
 * @brief Gets number of configured cores
 * @return Number of cores
 */
uint32 GetNumberOfActivatedCores(void);
```

### Configuration Parameters (OIL)

```oil
/* Complete OS Configuration Example */
CPU ExampleCPU {

    OS ExampleOS {
        STATUS = EXTENDED;              /* STANDARD or EXTENDED */
        STARTUPHOOK = TRUE;
        ERRORHOOK = TRUE;
        SHUTDOWNHOOK = TRUE;
        PRETASKHOOK = FALSE;
        POSTTASKHOOK = FALSE;
        USEGETSERVICEID = TRUE;
        USEPARAMETERACCESS = TRUE;
        USERESSCHEDULER = TRUE;

        /* Scalability Classes */
        CC = ECC2;                      /* BCC1, BCC2, ECC1, ECC2 */

        /* Multi-core */
        MICROCONTROLLER = Tricore {
            CORENUMBER = 3;
        };

        /* Timing Protection */
        PROTECTIONHOOK = TRUE;
        SCALABILITYCLASS = SC3;         /* SC1, SC2, SC3, SC4 */
    };

    /* Application Mode */
    APPMODE AppMode1 {};
    APPMODE AppMode2 {};

    /* Task Definitions */
    TASK Task_Init {
        PRIORITY = 1;
        SCHEDULE = FULL;
        ACTIVATION = 1;
        AUTOSTART = TRUE {
            APPMODE = AppMode1;
            APPMODE = AppMode2;
        };
        STACKSIZE = 512;
        TYPE = BASIC;
        EVENT = Event_Startup;
    };

    TASK Task_10ms {
        PRIORITY = 10;
        SCHEDULE = FULL;
        ACTIVATION = 1;
        AUTOSTART = FALSE;
        STACKSIZE = 1024;
        TYPE = EXTENDED;
        EVENT = Event_DataReady;
        RESOURCE = ResourceCAN;
        TIMING_PROTECTION = TRUE {
            EXECUTIONBUDGET = 5.0;      /* ms */
            TIMELIMIT = 10.0;           /* ms */
            RESOURCELOCKLIMIT = 1.0;    /* ms */
        };
    };

    TASK Task_100ms {
        PRIORITY = 5;
        SCHEDULE = NON;                 /* Non-preemptive */
        ACTIVATION = 2;                 /* Queue depth */
        AUTOSTART = TRUE {
            APPMODE = AppMode1;
        };
        STACKSIZE = 2048;
        TYPE = BASIC;
    };

    /* Event Definitions */
    EVENT Event_Startup {
        MASK = AUTO;
    };

    EVENT Event_DataReady {
        MASK = 0x01;
    };

    EVENT Event_DiagRequest {
        MASK = 0x02;
    };

    /* Resource Definitions */
    RESOURCE ResourceCAN {
        RESOURCEPROPERTY = STANDARD;
    };

    RESOURCE RES_SCHEDULER {
        RESOURCEPROPERTY = INTERNAL;
    };

    /* Counter Definitions */
    COUNTER SystemCounter {
        MINCYCLE = 1;
        MAXALLOWEDVALUE = 65535;
        TICKSPERBASE = 1;
        TYPE = HARDWARE;
        UNIT = TICKS;
        SOURCE = GPT_CHANNEL_0;
    };

    COUNTER MsCounter {
        MINCYCLE = 1;
        MAXALLOWEDVALUE = 1000;
        TICKSPERBASE = 1;
        TYPE = SOFTWARE;
        UNIT = MILLISECONDS;
    };

    /* Alarm Definitions */
    ALARM Alarm_10ms {
        COUNTER = SystemCounter;
        ACTION = ACTIVATETASK {
            TASK = Task_10ms;
        };
        AUTOSTART = TRUE {
            APPMODE = AppMode1;
            ALARMTIME = 10;
            CYCLETIME = 10;
        };
    };

    ALARM Alarm_100ms {
        COUNTER = SystemCounter;
        ACTION = SETEVENT {
            TASK = Task_10ms;
            EVENT = Event_DataReady;
        };
        AUTOSTART = FALSE;
    };

    /* Schedule Table Definitions */
    SCHEDULETABLE ScheduleTable_Cyclic {
        COUNTER = SystemCounter;
        DURATION = 100;
        REPEATING = TRUE;
        AUTOSTART = ABSOLUTE {
            APPMODE = AppMode1;
            START_VALUE = 0;
        };

        EXPIRY_POINT {
            OFFSET = 10;
            ACTION = ACTIVATETASK {
                TASK = Task_10ms;
            };
        };

        EXPIRY_POINT {
            OFFSET = 50;
            ACTION = SETEVENT {
                TASK = Task_10ms;
                EVENT = Event_DataReady;
            };
        };
    };

    /* ISR Definitions */
    ISR ISR_CANReceive {
        CATEGORY = 2;
        PRIORITY = 15;
        RESOURCE = ResourceCAN;
        STACKSIZE = 256;
    };

    ISR ISR_TimerOverflow {
        CATEGORY = 2;
        PRIORITY = 20;
    };

    /* OS Application Definitions */
    APPLICATION App_Powertrain {
        TRUSTED = TRUE;                 /* TRUE or FALSE */
        STARTUPHOOK = TRUE;
        SHUTDOWNHOOK = TRUE;
        ERRORHOOK = TRUE;
        HAS_RESTARTTASK = TRUE;

        TASK = Task_10ms;
        TASK = Task_100ms;
        ISR = ISR_CANReceive;
        COUNTER = SystemCounter;
        ALARM = Alarm_10ms;
        RESOURCE = ResourceCAN;

        TIMING_PROTECTION = TRUE;
    };

    APPLICATION App_Body {
        TRUSTED = FALSE;
        STARTUPHOOK = FALSE;
        SHUTDOWNHOOK = FALSE;
        ERRORHOOK = FALSE;
        HAS_RESTARTTASK = FALSE;
    };

    /* Multi-core Definitions */
    CORE Core0 {
        CORE_ID = 0;
        APPLICATION = App_Powertrain;
        TASK = Task_Init;
        TASK = Task_10ms;
        ISR = ISR_CANReceive;
    };

    CORE Core1 {
        CORE_ID = 1;
        APPLICATION = App_Body;
        TASK = Task_100ms;
    };

    /* Spinlock Definitions */
    SPINLOCK SpinlockCAN {
        NEXT_SPINLOCK = SpinlockUART;
    };

    SPINLOCK SpinlockUART {
        NEXT_SPINLOCK = NONE;
    };
};
```

## Part II: Communication Modules Reference

### COM Module Complete API

```c
/* Initialization */
void Com_Init(const Com_ConfigType* config);
void Com_DeInit(void);
void Com_IpduGroupControl(Com_IpduGroupIdType ipduGroupId, boolean initialize);
void Com_ReceptionDMControl(Com_IpduGroupIdType ipduGroupId, boolean initialize);

/* Transmission */
uint8 Com_SendSignal(Com_SignalIdType signalId, const void* signalDataPtr);
uint8 Com_SendDynSignal(Com_SignalIdType signalId, const void* signalDataPtr, uint16 length);
uint8 Com_SendSignalGroup(Com_SignalGroupIdType signalGroupId);
uint8 Com_SendSignalGroupArray(Com_SignalGroupIdType signalGroupId, const uint8* signalGroupArrayPtr);
Std_ReturnType Com_TriggerIPDUSend(PduIdType pduId);
Std_ReturnType Com_TriggerIPDUSendWithMetaData(PduIdType pduId, const uint8* metaData);

/* Reception */
uint8 Com_ReceiveSignal(Com_SignalIdType signalId, void* signalDataPtr);
uint8 Com_ReceiveDynSignal(Com_SignalIdType signalId, void* signalDataPtr, uint16* lengthPtr);
uint8 Com_ReceiveSignalGroup(Com_SignalGroupIdType signalGroupId);
uint8 Com_ReceiveSignalGroupArray(Com_SignalGroupIdType signalGroupId, uint8* signalGroupArrayPtr);

/* Signal Group Buffer Access */
void Com_UpdateShadowSignal(Com_SignalIdType signalId, const void* signalDataPtr);
void Com_ReceiveShadowSignal(Com_SignalIdType signalId, void* signalDataPtr);

/* I-PDU Management */
void Com_TxConfirmation(PduIdType txPduId);
void Com_RxIndication(PduIdType rxPduId, const PduInfoType* pduInfoPtr);
void Com_TpRxIndication(PduIdType id, Std_ReturnType result);
void Com_TpTxConfirmation(PduIdType id, Std_ReturnType result);
BufReq_ReturnType Com_CopyRxData(PduIdType id, const PduInfoType* info, PduLengthType* bufferSizePtr);
BufReq_ReturnType Com_CopyTxData(PduIdType id, const PduInfoType* info, const RetryInfoType* retry, PduLengthType* availableDataPtr);
BufReq_ReturnType Com_StartOfReception(PduIdType id, const PduInfoType* info, PduLengthType tpSduLength, PduLengthType* bufferSizePtr);

/* Main Functions */
void Com_MainFunctionRx(void);
void Com_MainFunctionTx(void);
void Com_MainFunctionRouteSignals(void);

/* Status */
Com_StatusType Com_GetStatus(void);
Std_ReturnType Com_GetVersionInfo(Std_VersionInfoType* versioninfo);
```

### COM Configuration Parameters (ARXML)

Complete parameter reference available in level 5 documentation.

---

**Document Status**: Complete reference for all modules
**Page Count**: 100+ pages
**Last Updated**: 2026-03-19

## Next: Level 5 - Advanced Topics


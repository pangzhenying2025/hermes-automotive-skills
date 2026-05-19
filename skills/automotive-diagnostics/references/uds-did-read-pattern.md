# UDS ReadDataByIdentifier (0x22) — AUTOSAR Implementation Pattern

Full code at: `E:\hermes\autosar-did-read\`

## Architecture

```
PDUR (CAN/DoIP) → DCM → Dcm_DidRead.c → App_DidProviders.c (SWC)
                         │
                         ├─ Dcm_Cfg.h        DID table (sorted, binary search)
                         ├─ Dcm_DidRead.h    API + NRC definitions
                         └─ Dcm_DidRead.c    0x22 handler (session/sec checks)
```

## DID Table Design

| Field | Purpose |
|-------|---------|
| uDid | 16-bit Data Identifier (per ISO 14229-1 Table A.1) |
| uLength | Expected data length in bytes |
| uSessions | Bitmask of allowed diagnostic sessions |
| uSecLevel | SecurityAccess level required (0=L1=L2) |
| pfnReadProvider | Callback to application SWC |
| pszDesc | Human-readable description |

## Processing Order (SWS_Dcm_00300)

1. Length check → NRC 0x13
2. DID lookup (binary search) → NRC 0x31
3. Session permission → NRC 0x33
4. Security level → NRC 0x33
5. Service enabled → NRC 0x7F
6. Invoke provider → NRC 0x22
7. Build response (0x62 + DID + data)

## Example DID Configuration

```c
{ 0xF180u, 17u, DCM_SESSION_ALL, DCM_SECLVL_NONE, Dcm_ReadVin, "VIN" },
{ 0xF1D0u,  4u, DCM_SESSION_ALL, DCM_SECLVL_NONE, Dcm_ReadOdometer, "Odometer" },
{ 0xF1D1u,  2u, DCM_SESSION_EXTENDED, DCM_SECLVL_NONE, Dcm_ReadSupplyVoltage, "Voltage" },
```

## Provider Pattern

```c
Std_ReturnType Dcm_ReadVin(uint8 * puData, uint16 uLen)
{
    // In production: NvM_ReadBlock(NVM_BLOCK_VIN, puData);
    (void)memcpy(puData, APP_VIN_STRING, (uLen < 17u) ? uLen : 17u);
    return E_OK;
}
```

Return `E_NOT_OK` when data unavailable → generates NRC 0x22 (conditionNotCorrect).

## Key NRCs

| Code | Meaning | Trigger |
|------|---------|---------|
| 0x13 | incorrectMessageLength | Request < 2 bytes |
| 0x22 | conditionNotCorrect | Provider returned E_NOT_OK |
| 0x31 | requestOutOfRange | DID not in config table |
| 0x33 | securityAccessDenied | Wrong session or security level |

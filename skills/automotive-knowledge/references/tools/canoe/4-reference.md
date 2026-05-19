# Vector CANoe - Level 4: Reference

> Audience: Developers needing quick lookup for CANoe features
> Purpose: Rapid reference for CAPL functions, shortcuts, and configuration

## CAPL Function Reference

### Message Handling

| Function | Description | Example |
|----------|-------------|---------|
| output(msg) | Send CAN message | output(myMsg) |
| write(fmt, ...) | Print to Write window | write("Value: %d", val) |
| setTimer(t, ms) | Start timer | setTimer(myTimer, 100) |
| cancelTimer(t) | Stop timer | cancelTimer(myTimer) |
| getLocalTime(t) | Get system time | getLocalTime(sysTime) |
| timeNow() | Current time in 10us units | long t = timeNow() |

### Signal Access

| Function | Description | Example |
|----------|-------------|---------|
| $signalName | Read signal value | float v = $BMS_SOC |
| setSignal(sig, val) | Set signal value | setSignal(BMS_SOC, 80) |
| getSignal(sig) | Get signal value | float v = getSignal(BMS_SOC) |
| @sysvar::ns::name | System variable access | @sysvar::BMS::SOC = 50 |

### Test Functions

| Function | Description |
|----------|-------------|
| testCaseTitle(id, title) | Set test case identifier |
| testCaseDescription(desc) | Set test description |
| testStep(desc) | Begin a test step |
| testStepPass(fmt, ...) | Mark step as passed |
| testStepFail(fmt, ...) | Mark step as failed |
| testWaitForMessage(msg, timeout) | Wait for message |
| testWaitForSignalInRange(sig, min, max, timeout) | Wait for signal value |
| testWaitForTimeout(ms) | Wait specified time |
| testGetVerdictLastTestCase() | Get last test verdict |

### File I/O

| Function | Description |
|----------|-------------|
| fileOpen(path, mode) | Open file (0=read, 1=write) |
| fileClose(handle) | Close file |
| fileWriteLine(h, fmt, ...) | Write line to file |
| fileReadLine(h, buf, size) | Read line from file |
| filePutString(str, h) | Write string to file |

## CAPL Event Handlers

| Handler | Trigger |
|---------|---------|
| on start | Measurement starts |
| on stop | Measurement stops |
| on message MSG_NAME | CAN message received |
| on message * | Any CAN message received |
| on signal SIG_NAME | Signal value changes |
| on timer TIMER_NAME | Timer expires |
| on key 'x' | Keyboard key pressed |
| on sysvar SV_NAME | System variable changes |
| on envVar ENV_NAME | Environment variable changes |
| on preStart | Before measurement (config phase) |
| on busOff | CAN bus-off detected |
| on errorFrame | CAN error frame detected |

## CAPL Data Types

| Type | Size | Range |
|------|------|-------|
| byte | 8 bit | 0 to 255 |
| word | 16 bit | 0 to 65535 |
| dword | 32 bit | 0 to 4294967295 |
| int | 16 bit | -32768 to 32767 |
| long | 32 bit | -2147483648 to 2147483647 |
| int64 | 64 bit | Full 64-bit range |
| float | 64 bit | IEEE 754 double |
| char | 8 bit | ASCII character |

## CANoe Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| F9 | Start measurement |
| F11 | Stop measurement |
| Ctrl+F9 | Start + logging |
| F5 | Start simulation |
| Ctrl+O | Open configuration |
| Ctrl+L | Open CAPL browser |
| Ctrl+T | Open Trace window |
| Ctrl+G | Open Graphics window |
| Ctrl+W | Open Write window |

## Message Timing Reference

| Message Type | Typical Cycle | Tolerance |
|-------------|--------------|-----------|
| Powertrain status | 10 ms | +/- 1 ms |
| Chassis control | 20 ms | +/- 2 ms |
| Body control | 50-100 ms | +/- 10 ms |
| Diagnostic | Event-driven | Response < 50 ms |
| NM messages | 500-1000 ms | +/- 100 ms |
| Climate control | 200-500 ms | +/- 50 ms |

## UDS Service IDs (Common)

| Service | ID | Response ID | Description |
|---------|-----|------------|-------------|
| DiagSessionControl | 0x10 | 0x50 | Change diagnostic session |
| ECUReset | 0x11 | 0x51 | Reset ECU |
| ReadDataByIdentifier | 0x22 | 0x62 | Read DID value |
| WriteDataByIdentifier | 0x2E | 0x6E | Write DID value |
| RoutineControl | 0x31 | 0x71 | Execute routine |
| RequestDownload | 0x34 | 0x74 | Start download |
| TransferData | 0x36 | 0x76 | Transfer block |
| RequestTransferExit | 0x37 | 0x77 | End transfer |
| TesterPresent | 0x3E | 0x7E | Keep session alive |
| SecurityAccess | 0x27 | 0x67 | Authentication |
| ReadDTCInformation | 0x19 | 0x59 | Read fault codes |
| ClearDiagnosticInfo | 0x14 | 0x54 | Clear fault codes |
| CommunicationControl | 0x28 | 0x68 | Enable/disable comm |

## Negative Response Codes

| NRC | Name | Meaning |
|-----|------|---------|
| 0x12 | subFunctionNotSupported | Sub-function not available |
| 0x13 | incorrectMessageLength | Wrong request length |
| 0x14 | responseTooLong | Response exceeds buffer |
| 0x22 | conditionsNotCorrect | Preconditions not met |
| 0x24 | requestSequenceError | Wrong order of services |
| 0x31 | requestOutOfRange | Parameter out of range |
| 0x33 | securityAccessDenied | Not authenticated |
| 0x35 | invalidKey | Wrong security key |
| 0x72 | generalProgrammingFailure | Flash write failed |
| 0x78 | requestCorrectlyReceivedResponsePending | Processing, wait |

## Vector Hardware Reference

| Hardware | Channels | Bus Types | Use Case |
|----------|---------|-----------|----------|
| VN1610 | 2 CAN | CAN, CAN FD | Desktop development |
| VN1630 | 2 CAN + 2 LIN | CAN, LIN | Body electronics |
| VN5610 | 2 Ethernet | Ethernet, SOME/IP | ADAS, backbone |
| VN5640 | 4 Ethernet | Ethernet | Multi-ECU Ethernet |
| VN8900 | Modular | All | HIL integration |
| VT System | I/O | Analog, digital, PWM | Stimulation/measurement |

## Summary

This reference covers CAPL functions for message handling, signal access,
testing, and file I/O; event handlers; data types; keyboard shortcuts;
UDS service IDs with response codes; and Vector hardware specifications.

# Vector CANoe - Level 3: Detailed Implementation

> Audience: Developers and testers writing CAPL programs and test cases
> Purpose: Practical code examples, test patterns, and configuration

## CAPL: ECU Simulation

### Battery Management System Simulation

```c
/*
 * BMS ECU Simulation
 * Simulates battery pack messages for integration testing
 */

variables {
    /* Battery state */
    float gCellVoltages[96];        /* 96 cells */
    float gCellTemperatures[32];    /* 32 temp sensors */
    float gPackVoltage_V = 400.0;
    float gPackCurrent_A = 0.0;
    float gSoc_pct = 80.0;
    int   gBmsState = 0;           /* 0=init, 1=normal, 2=charging, 3=fault */

    /* Timers */
    msTimer tCellVoltageMsg;        /* 100 ms cycle */
    msTimer tCellTempMsg;           /* 1000 ms cycle */
    msTimer tBmsStatusMsg;          /* 50 ms cycle */

    /* Fault injection */
    int gFaultInjectionActive = 0;
    int gFaultType = 0;            /* 0=none, 1=overvoltage, 2=undervoltage, 3=overtemp */
}

on start {
    /* Initialize cell voltages to nominal */
    int i;
    for (i = 0; i < 96; i++) {
        gCellVoltages[i] = 3.7;   /* Nominal voltage */
    }
    for (i = 0; i < 32; i++) {
        gCellTemperatures[i] = 25.0;  /* Ambient temperature */
    }

    /* Start periodic message timers */
    setTimer(tCellVoltageMsg, 100);
    setTimer(tCellTempMsg, 1000);
    setTimer(tBmsStatusMsg, 50);

    write("BMS Simulation started");
}

on timer tBmsStatusMsg {
    message BMS_Status msg;

    msg.BMS_PackVoltage = gPackVoltage_V * 10;     /* 0.1V resolution */
    msg.BMS_PackCurrent = (gPackCurrent_A + 500) * 10; /* 0.1A, offset 500 */
    msg.BMS_SOC = gSoc_pct * 10;                   /* 0.1% resolution */
    msg.BMS_State = gBmsState;

    /* Apply fault injection if active */
    if (gFaultInjectionActive && gFaultType == 1) {
        msg.BMS_PackVoltage = 4500;  /* Overvoltage: 450V */
    }

    output(msg);
    setTimer(tBmsStatusMsg, 50);
}

on timer tCellVoltageMsg {
    message BMS_CellVoltages_1 msg1;
    message BMS_CellVoltages_2 msg2;
    int i;

    /* Pack first 8 cells into message 1 */
    for (i = 0; i < 8; i++) {
        float voltage = gCellVoltages[i];

        /* Apply fault injection */
        if (gFaultInjectionActive && gFaultType == 2 && i == 0) {
            voltage = 2.0;  /* Undervoltage on cell 0 */
        }

        /* Encode: 0.001V resolution, 16-bit unsigned */
        msg1.byte(i * 2) = (int)(voltage * 1000) & 0xFF;
        msg1.byte(i * 2 + 1) = ((int)(voltage * 1000) >> 8) & 0xFF;
    }
    output(msg1);

    setTimer(tCellVoltageMsg, 100);
}

/* Respond to diagnostic requests */
on message DiagRequest {
    message DiagResponse resp;

    switch (this.byte(0)) {  /* Service ID */
        case 0x22:  /* Read Data By Identifier */
        {
            int did = (this.byte(1) << 8) | this.byte(2);
            resp.byte(0) = 0x62;  /* Positive response */
            resp.byte(1) = this.byte(1);
            resp.byte(2) = this.byte(2);

            switch (did) {
                case 0xF190:  /* VIN */
                    resp.dlc = 20;
                    /* Fill VIN bytes */
                    break;
                case 0x0100:  /* Battery SOC */
                    resp.byte(3) = (int)(gSoc_pct * 10) & 0xFF;
                    resp.byte(4) = ((int)(gSoc_pct * 10) >> 8) & 0xFF;
                    resp.dlc = 5;
                    break;
                default:
                    resp.byte(0) = 0x7F;  /* Negative response */
                    resp.byte(1) = 0x22;
                    resp.byte(2) = 0x31;  /* Request out of range */
                    resp.dlc = 3;
            }
            output(resp);
            break;
        }
    }
}

/* Panel interaction: fault injection toggle */
on sysvar sysvar::BMS::FaultInjection::Active {
    gFaultInjectionActive = @this;
    write("Fault injection: %s", gFaultInjectionActive ? "ON" : "OFF");
}

on sysvar sysvar::BMS::FaultInjection::Type {
    gFaultType = @this;
    write("Fault type set to: %d", gFaultType);
}
```

## CAPL: Test Module

### BMS Communication Test

```c
/*
 * Test Module: BMS Communication Verification
 */

includes {
    /* Include test utility functions */
}

variables {
    const int TIMEOUT_MS = 1000;
}

testcase TC_BMS_001_StatusMessageCycleTime() {
    /* Verify BMS_Status message is sent every 50ms +/- 10% */
    testCaseTitle("TC_BMS_001", "BMS Status Message Cycle Time");
    testCaseDescription("Verify BMS_Status periodic transmission at 50ms");

    long timestamps[20];
    int count = 0;

    testStep("Wait for 20 consecutive BMS_Status messages");

    testWaitForMessage(BMS_Status, TIMEOUT_MS);
    timestamps[0] = messageTimeNS(BMS_Status) / 1000000;  /* ns to ms */
    count = 1;

    while (count < 20) {
        testWaitForMessage(BMS_Status, TIMEOUT_MS);
        timestamps[count] = messageTimeNS(BMS_Status) / 1000000;
        count++;
    }

    testStep("Verify cycle time within 45-55ms tolerance");

    int pass = 1;
    int i;
    for (i = 1; i < 20; i++) {
        long delta = timestamps[i] - timestamps[i-1];
        if (delta < 45 || delta > 55) {
            testStepFail("Cycle %d: %dms (expected 45-55ms)", i, delta);
            pass = 0;
        }
    }

    if (pass) {
        testStepPass("All cycle times within tolerance");
    }
}

testcase TC_BMS_002_SOCRange() {
    /* Verify SOC signal range 0-100% */
    testCaseTitle("TC_BMS_002", "BMS SOC Signal Range");

    testStep("Set SOC to 0% and verify");
    @sysvar::BMS::Simulation::SOC = 0.0;
    testWaitForTimeout(200);
    testWaitForMessage(BMS_Status, TIMEOUT_MS);

    float soc = BMS_Status.BMS_SOC / 10.0;
    if (soc >= 0.0 && soc <= 1.0) {
        testStepPass("SOC at minimum: %.1f%%", soc);
    } else {
        testStepFail("SOC at minimum: %.1f%% (expected 0.0%%)", soc);
    }

    testStep("Set SOC to 100% and verify");
    @sysvar::BMS::Simulation::SOC = 100.0;
    testWaitForTimeout(200);
    testWaitForMessage(BMS_Status, TIMEOUT_MS);

    soc = BMS_Status.BMS_SOC / 10.0;
    if (soc >= 99.0 && soc <= 100.0) {
        testStepPass("SOC at maximum: %.1f%%", soc);
    } else {
        testStepFail("SOC at maximum: %.1f%% (expected 100.0%%)", soc);
    }
}

testcase TC_BMS_003_OvervoltageDetection() {
    /* Verify BMS detects overvoltage and transitions to fault state */
    testCaseTitle("TC_BMS_003", "Overvoltage Detection");

    testStep("Verify BMS in normal state");
    testWaitForMessage(BMS_Status, TIMEOUT_MS);
    if (BMS_Status.BMS_State != 1) {
        testStepFail("BMS not in normal state: %d", BMS_Status.BMS_State);
        return;
    }
    testStepPass("BMS in normal state");

    testStep("Inject overvoltage fault");
    @sysvar::BMS::FaultInjection::Type = 1;
    @sysvar::BMS::FaultInjection::Active = 1;

    testStep("Verify BMS transitions to fault state within 500ms");
    long startTime = timeNow();
    int faultDetected = 0;

    while ((timeNow() - startTime) < 500) {
        testWaitForMessage(BMS_Status, 100);
        if (BMS_Status.BMS_State == 3) {
            faultDetected = 1;
            break;
        }
    }

    if (faultDetected) {
        long reactionTime = timeNow() - startTime;
        testStepPass("Fault detected in %dms", reactionTime);
    } else {
        testStepFail("Fault not detected within 500ms");
    }

    /* Cleanup */
    @sysvar::BMS::FaultInjection::Active = 0;
}

testcase TC_BMS_004_DiagReadSOC() {
    /* Verify UDS Read Data By Identifier for SOC */
    testCaseTitle("TC_BMS_004", "Diagnostic Read SOC");

    testStep("Send ReadDataByIdentifier for SOC (DID 0x0100)");

    message DiagRequest req;
    req.byte(0) = 0x22;  /* Service: ReadDataByIdentifier */
    req.byte(1) = 0x01;  /* DID high byte */
    req.byte(2) = 0x00;  /* DID low byte */
    req.dlc = 3;
    output(req);

    testStep("Verify positive response");
    testWaitForMessage(DiagResponse, TIMEOUT_MS);

    if (DiagResponse.byte(0) == 0x62) {
        int soc_raw = DiagResponse.byte(3) | (DiagResponse.byte(4) << 8);
        float soc = soc_raw / 10.0;
        testStepPass("SOC via UDS: %.1f%%", soc);
    } else if (DiagResponse.byte(0) == 0x7F) {
        testStepFail("Negative response: NRC=0x%02X", DiagResponse.byte(2));
    } else {
        testStepFail("Unexpected response: 0x%02X", DiagResponse.byte(0));
    }
}
```

## Command Line Execution

```bash
# Start CANoe measurement from command line
"C:\Program Files\Vector CANoe 17\Exec64\CANoe64.exe" \
    -cfg "C:\Projects\BMS\BMS_Test.cfg" \
    -autostart \
    -autoexit \
    -testmodule "BMS_CommTest" \
    -reportdir "C:\Results"

# Using CANoe COM automation (PowerShell)
$canoe = New-Object -ComObject CANoe.Application
$canoe.Open("C:\Projects\BMS\BMS_Test.cfg")
$measurement = $canoe.Measurement
$measurement.Start()
Start-Sleep -Seconds 5
$measurement.Stop()
$canoe.Quit()
```

## DBC Database Example

```
VERSION ""

NS_ :

BS_:

BU_: BMS VCU MCU

BO_ 256 BMS_Status: 8 BMS
 SG_ BMS_PackVoltage : 0|16@1+ (0.1,0) [0|600] "V" VCU,MCU
 SG_ BMS_PackCurrent : 16|16@1+ (0.1,-500) [-500|500] "A" VCU,MCU
 SG_ BMS_SOC : 32|16@1+ (0.1,0) [0|100] "%" VCU,MCU
 SG_ BMS_State : 48|4@1+ (1,0) [0|15] "" VCU,MCU

BO_ 257 BMS_CellVoltages_1: 8 BMS
 SG_ BMS_Cell01_V : 0|16@1+ (0.001,0) [0|5] "V" VCU
 SG_ BMS_Cell02_V : 16|16@1+ (0.001,0) [0|5] "V" VCU
 SG_ BMS_Cell03_V : 32|16@1+ (0.001,0) [0|5] "V" VCU
 SG_ BMS_Cell04_V : 48|16@1+ (0.001,0) [0|5] "V" VCU

CM_ BO_ 256 "BMS pack status, 50ms cycle";
CM_ SG_ 256 BMS_State "0=Init, 1=Normal, 2=Charging, 3=Fault";

BA_DEF_ BO_ "GenMsgCycleTime" INT 0 10000;
BA_ "GenMsgCycleTime" BO_ 256 50;
BA_ "GenMsgCycleTime" BO_ 257 100;
```

## Summary

CANoe implementation involves CAPL programming for ECU simulation (periodic
message transmission, diagnostic handling, fault injection), test modules
with structured test cases (cycle time, range, fault detection, diagnostics),
DBC database definitions for signal encoding, and command-line automation
for CI/CD integration.

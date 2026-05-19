# Vector CANoe - Level 5: Advanced Topics

> Audience: Expert CANoe users and test automation architects
> Purpose: Advanced simulation, automation, and integration patterns

## COM Automation (Python)

### CANoe Remote Control via COM

```python
"""Control CANoe programmatically via COM automation."""

import time
import win32com.client
from typing import Optional


class CANoeController:
    """Python wrapper for CANoe COM automation interface."""

    def __init__(self) -> None:
        self.app: Optional[object] = None
        self.measurement: Optional[object] = None
        self.configuration: Optional[object] = None

    def open(self, config_path: str) -> None:
        """Open a CANoe configuration."""
        self.app = win32com.client.Dispatch("CANoe.Application")
        self.app.Open(config_path)
        self.measurement = self.app.Measurement
        self.configuration = self.app.Configuration

    def start_measurement(self) -> None:
        """Start the measurement."""
        if not self.measurement.Running:
            self.measurement.Start()
            # Wait for measurement to be running
            timeout = 10.0
            start = time.time()
            while not self.measurement.Running:
                if time.time() - start > timeout:
                    raise TimeoutError("Measurement did not start")
                time.sleep(0.1)

    def stop_measurement(self) -> None:
        """Stop the measurement."""
        if self.measurement.Running:
            self.measurement.Stop()
            while self.measurement.Running:
                time.sleep(0.1)

    def get_signal_value(self, bus: str, channel: int,
                          message: str, signal: str) -> float:
        """Read a signal value from the bus."""
        sig = self.app.GetBus(bus).GetSignal(channel, message, signal)
        return sig.Value

    def set_system_variable(self, namespace: str,
                             name: str, value: float) -> None:
        """Set a system variable value."""
        sv = self.app.System.Namespaces(namespace).Variables(name)
        sv.Value = value

    def run_test_module(self, test_module_name: str) -> dict:
        """Execute a test module and return results."""
        test_setup = self.app.Configuration.TestSetup
        test_env = test_setup.TestEnvironments.Item(1)

        # Find and start test module
        for i in range(1, test_env.Items.Count + 1):
            item = test_env.Items.Item(i)
            if item.Name == test_module_name:
                item.Start()
                # Wait for completion
                while item.Running:
                    time.sleep(1)
                return {
                    "verdict": item.Verdict,
                    "passed": item.PassedCount,
                    "failed": item.FailedCount,
                    "report_path": item.ReportFilePath,
                }

        raise ValueError(f"Test module '{test_module_name}' not found")

    def close(self) -> None:
        """Close CANoe."""
        if self.app:
            self.app.Quit()
            self.app = None


# Usage in CI/CD pipeline
def run_canoe_tests(config: str, test_module: str) -> int:
    """Run CANoe tests and return exit code."""
    controller = CANoeController()
    try:
        controller.open(config)
        controller.start_measurement()
        time.sleep(2)  # Allow initialization

        results = controller.run_test_module(test_module)

        controller.stop_measurement()

        print(f"Results: {results['passed']} passed, "
              f"{results['failed']} failed")

        return 0 if results['failed'] == 0 else 1
    except Exception as e:
        print(f"Error: {e}")
        return 2
    finally:
        controller.close()
```

## Advanced Simulation Patterns

### Remaining Bus Simulation with Fault Models

```c
/*
 * Advanced remaining bus simulation with configurable fault injection
 * Supports: message dropout, delay, corruption, bus-off
 */

variables {
    /* Fault configuration per message */
    struct FaultConfig {
        int enabled;
        int type;           /* 0=none, 1=dropout, 2=delay, 3=corrupt, 4=stuck */
        float probability;  /* 0.0 to 1.0 */
        int delay_ms;
        int stuck_value;
    };

    struct FaultConfig gFaults[100];  /* Indexed by message ID % 100 */

    /* Statistics */
    long gMsgSent = 0;
    long gMsgDropped = 0;
    long gMsgCorrupted = 0;
    long gMsgDelayed = 0;
}

/* Generic message relay with fault injection */
on message * {
    int idx = this.id % 100;
    message * relayMsg;

    /* Copy original message */
    relayMsg = this;
    relayMsg.id = this.id;

    /* Apply fault model if configured */
    if (gFaults[idx].enabled) {
        float roll = random(1000) / 1000.0;

        if (roll < gFaults[idx].probability) {
            switch (gFaults[idx].type) {
                case 1:  /* Dropout - don't send */
                    gMsgDropped++;
                    return;

                case 2:  /* Delay */
                {
                    msTimer delayTimer;
                    /* Note: simplified - real implementation needs
                       message queue for delayed send */
                    gMsgDelayed++;
                    break;
                }

                case 3:  /* Corrupt - flip random bit */
                {
                    int byteIdx = random(this.dlc);
                    int bitIdx = random(8);
                    relayMsg.byte(byteIdx) = relayMsg.byte(byteIdx) ^ (1 << bitIdx);
                    gMsgCorrupted++;
                    break;
                }

                case 4:  /* Stuck at value */
                {
                    int i;
                    for (i = 0; i < this.dlc; i++) {
                        relayMsg.byte(i) = gFaults[idx].stuck_value;
                    }
                    break;
                }
            }
        }
    }

    output(relayMsg);
    gMsgSent++;
}
```

### Network Management Simulation

```c
/*
 * AUTOSAR NM (Network Management) simulation
 * Simulates sleep/wake transitions for testing
 */

variables {
    int gNmState = 0;  /* 0=sleep, 1=normal, 2=ready_sleep, 3=prepare_sleep */
    msTimer tNmMessage;
    msTimer tNmTimeout;
    const int NM_CYCLE_MS = 500;
    const int NM_TIMEOUT_MS = 3000;
    byte gNmUserData[6] = {0};
}

on start {
    gNmState = 1;  /* Start in normal operation */
    setTimer(tNmMessage, NM_CYCLE_MS);
    setTimer(tNmTimeout, NM_TIMEOUT_MS);
}

on timer tNmMessage {
    if (gNmState == 1 || gNmState == 2) {
        message NM_BMS nmMsg;
        nmMsg.byte(0) = 0x10;  /* Source node ID */
        nmMsg.byte(1) = gNmState == 1 ? 0x01 : 0x00;  /* CBV: active/passive */

        int i;
        for (i = 0; i < 6; i++) {
            nmMsg.byte(2 + i) = gNmUserData[i];
        }

        output(nmMsg);
        setTimer(tNmMessage, NM_CYCLE_MS);
    }
}

on message NM_* {
    /* Received NM from another node - reset timeout */
    cancelTimer(tNmTimeout);
    setTimer(tNmTimeout, NM_TIMEOUT_MS);

    if (gNmState == 0) {
        /* Wake up from sleep */
        gNmState = 1;
        setTimer(tNmMessage, NM_CYCLE_MS);
        write("NM: Wakeup - received NM from node 0x%02X", this.byte(0));
    }
}

on timer tNmTimeout {
    /* No NM received - transition to sleep */
    write("NM: Timeout - transitioning to sleep");
    gNmState = 3;  /* Prepare sleep */

    /* Allow 1 second for prepare sleep actions */
    setTimer(tNmTimeout, 1000);
}
```

## vTESTstudio Integration

### XML Test Specification

```xml
<?xml version="1.0" encoding="UTF-8"?>
<TestSpecification>
    <TestGroup name="BMS_Integration" description="BMS Integration Tests">

        <TestCase id="TC_INT_001" name="Normal_Operation_Sequence">
            <Description>Verify complete BMS startup and normal operation</Description>
            <Preconditions>
                <Condition>CANoe measurement running</Condition>
                <Condition>BMS simulation in init state</Condition>
            </Preconditions>
            <TestSteps>
                <Step id="1" action="Wait for BMS_Status.BMS_State == 1"
                      expected="BMS enters normal state within 5s"
                      timeout="5000"/>
                <Step id="2" action="Verify BMS_Status.BMS_SOC in range [0, 100]"
                      expected="SOC value is valid"/>
                <Step id="3" action="Verify BMS_Status cycle time == 50ms +/- 10%"
                      expected="Cycle time within tolerance"
                      duration="2000"/>
                <Step id="4" action="Verify cell voltage messages present"
                      expected="BMS_CellVoltages_1 received at 100ms"/>
            </TestSteps>
            <Requirements>
                <Requirement id="REQ-BMS-001">BMS shall enter normal state within 5s</Requirement>
                <Requirement id="REQ-BMS-010">SOC shall be reported in 0-100% range</Requirement>
            </Requirements>
        </TestCase>

        <TestCase id="TC_INT_002" name="Fault_Recovery">
            <Description>Verify BMS recovers from transient overvoltage</Description>
            <TestSteps>
                <Step id="1" action="Set normal operating conditions"/>
                <Step id="2" action="Inject overvoltage for 100ms"/>
                <Step id="3" action="Remove overvoltage condition"/>
                <Step id="4" action="Verify BMS returns to normal within 2s"
                      expected="BMS_State transitions: 1 -> 3 -> 1"/>
            </TestSteps>
        </TestCase>

    </TestGroup>
</TestSpecification>
```

## Multi-Bus Gateway Simulation

```c
/*
 * Gateway simulation: route messages between CAN buses
 * Powertrain CAN <-> Body CAN <-> Diagnostic CAN
 */

variables {
    /* Routing table: source_id -> destination_id, destination_channel */
    struct RouteEntry {
        long src_id;
        long dst_id;
        int src_channel;
        int dst_channel;
        int enabled;
    };

    struct RouteEntry gRouteTable[50];
    int gRouteCount = 0;
}

on preStart {
    /* Define routing table */
    /* Powertrain (CH1) -> Body (CH2) */
    gRouteTable[0] = { 0x100, 0x100, 1, 2, 1 };  /* BMS_Status */
    gRouteTable[1] = { 0x101, 0x101, 1, 2, 1 };  /* BMS_CellVoltages */

    /* Body (CH2) -> Powertrain (CH1) */
    gRouteTable[2] = { 0x200, 0x200, 2, 1, 1 };  /* VCU_Command */

    /* Diagnostic (CH3) -> Both */
    gRouteTable[3] = { 0x7DF, 0x7DF, 3, 1, 1 };  /* Functional diag request */
    gRouteTable[4] = { 0x7DF, 0x7DF, 3, 2, 1 };

    gRouteCount = 5;
}

on message CAN1.* {
    routeMessage(this, 1);
}

on message CAN2.* {
    routeMessage(this, 2);
}

on message CAN3.* {
    routeMessage(this, 3);
}

void routeMessage(message * msg, int srcChannel) {
    int i;
    for (i = 0; i < gRouteCount; i++) {
        if (gRouteTable[i].enabled &&
            gRouteTable[i].src_id == msg.id &&
            gRouteTable[i].src_channel == srcChannel) {

            message * routedMsg;
            routedMsg = msg;
            routedMsg.id = gRouteTable[i].dst_id;

            /* Output on destination channel */
            switch (gRouteTable[i].dst_channel) {
                case 1: output(CAN1, routedMsg); break;
                case 2: output(CAN2, routedMsg); break;
                case 3: output(CAN3, routedMsg); break;
            }
        }
    }
}
```

## Future Directions

- **Cloud-based simulation**: CANoe running in cloud for scalable CI/CD testing
- **Digital twin integration**: CANoe connected to vehicle digital twin models
- **AI-driven test generation**: ML models generating test scenarios from
  specification documents
- **Automotive Ethernet scaling**: SOME/IP and DDS protocol simulation for
  zonal architecture testing
- **Containerized test environments**: Docker-based CANoe instances for
  parallel test execution

## Summary

Advanced CANoe usage includes COM automation for CI/CD integration (Python),
sophisticated fault injection models for remaining bus simulation, network
management simulation, vTESTstudio test specification, and multi-bus gateway
simulation. These patterns enable comprehensive automated testing of complex
automotive networks at scale.

# Vector CANoe - Level 2: Conceptual Architecture

> Audience: System architects, senior engineers, technical leads
> Purpose: Understand CANoe architecture, components, and design patterns

## CANoe System Architecture

```
+---------------------------------------------------------------+
|                      CANoe Application                         |
+---------------------------------------------------------------+
|  Measurement  | Simulation | Test Module | Diagnostic |  CAPL  |
|   Setup       | Setup      | (TFS/XML)  | Console    | Browser|
+---------------------------------------------------------------+
|                    Runtime Kernel                               |
|  Message Router | Signal Server | Timer Service | Event Queue  |
+---------------------------------------------------------------+
|                    Bus Interface Layer                          |
|  CAN Driver | LIN Driver | FlexRay Driver | Ethernet Driver   |
+---------------------------------------------------------------+
|                    Hardware Interface                           |
|  VN1600 | VN5600 | VN8900 | VT System | Virtual Bus          |
+---------------------------------------------------------------+
```

## Configuration Components

### Network Databases

| Database Type | Format | Contains |
|--------------|--------|---------|
| CAN database | .dbc | Messages, signals, nodes |
| LIN database | .ldf | Schedule tables, signals |
| FlexRay database | .fibex | Frames, PDUs, clusters |
| SOME/IP | .arxml | Services, methods, events |
| Ethernet | .arxml | PDU routing, VLANs |
| Diagnostic | .odx/.cdd | Services, parameters, DTCs |

### Simulation Nodes

```
                    CANoe Configuration
                          |
          +---------------+---------------+
          |               |               |
    ECU Simulation   Remaining Bus    Test Node
    (CAPL/C#/.NET)   Simulation      (Test Module)
          |               |               |
     +----+----+     +----+----+     +----+----+
     | CAN Tx  |     | CAN Tx  |     | CAN Rx  |
     | CAN Rx  |     | CAN Rx  |     | Analyze |
     | Timers  |     | Default |     | Verify  |
     | Panels  |     | Values  |     | Report  |
     +---------+     +---------+     +---------+
```

### Node Types

| Type | Purpose | Implementation |
|------|---------|---------------|
| Simulated ECU | Replace real ECU | CAPL program |
| Remaining bus | Simulate network traffic | Auto-generated from DB |
| Test node | Execute test cases | CAPL Test Module or XML |
| Gateway node | Route messages between buses | CAPL with routing logic |
| Diagnostic tester | Send UDS requests | Diagnostic console |

## CAPL (Communication Access Programming Language)

CAPL is CANoe's event-driven programming language:

```
Event-Driven Model:
  on message CAN_MSG_ID     --> Process received message
  on signal SIGNAL_NAME     --> React to signal value change
  on timer TIMER_NAME       --> Handle timer expiration
  on key KEY_CHAR           --> Handle keyboard input
  on start                  --> Initialize on measurement start
  on stop                   --> Cleanup on measurement stop
  on sysvar SYSVAR_NAME     --> React to system variable change
```

### CAPL Execution Model

```
CAN Bus Activity
      |
      v
Message Filter (acceptance filtering)
      |
      v
CAPL Handler Queue (priority-ordered)
      |
      v
Handler Execution (single-threaded, run-to-completion)
      |
      v
Output Actions (send messages, set signals, write variables)
```

## Test Architecture

### Test Feature Set (TFS)

```
Test Configuration
  |
  +-- Test Environment
  |     +-- Test Setup (preconditions)
  |     +-- Test Teardown (cleanup)
  |
  +-- Test Groups
  |     +-- Test Case 1
  |     |     +-- Test Steps
  |     |     +-- Expected Results
  |     |     +-- Verdict (pass/fail)
  |     |
  |     +-- Test Case 2
  |           +-- ...
  |
  +-- Test Report
        +-- XML report
        +-- HTML report
```

### Test Layers

| Layer | What is Tested | How |
|-------|---------------|-----|
| Signal level | Individual signal values | Read signal, compare expected |
| Message level | CAN frame content | Check raw bytes, timing |
| Diagnostic level | UDS responses | Send request, verify response |
| Function level | ECU behavior | Stimulate input, check output |
| Network level | Multi-ECU interaction | Simulate scenario, verify system |

## Integration Patterns

### CANoe with CI/CD

```
Jenkins/GitLab CI
      |
      v
vTESTstudio (test management)
      |
      v
CANoe command line (measurement control)
      |
      v
Test execution + logging
      |
      v
XML test reports --> CI artifact storage
```

### CANoe with HIL

```
HIL System (dSPACE, NI)
      |
      +-- Plant model (vehicle physics)
      +-- I/O interface (analog, digital, PWM)
      |
      v
Real ECU (device under test)
      |
      v
CAN/LIN/Ethernet bus
      |
      v
CANoe (via Vector hardware interface)
      |
      +-- Bus monitoring
      +-- Test execution
      +-- Diagnostic testing
```

## Configuration Best Practices

| Aspect | Recommendation |
|--------|---------------|
| Database version | Pin to specific release, track in VCS |
| CAPL organization | One file per simulated ECU |
| Test structure | Group by feature, not by message |
| Logging | Always log to .blf format for replay |
| Panel design | Use standard layouts, document controls |
| System variables | Namespace by module: sv::BMS::CellVoltage |
| Signal naming | Follow DBC naming convention consistently |

## Summary

CANoe architecture consists of simulation nodes (CAPL programs), network
databases (DBC/ARXML), test modules, and hardware interfaces. The
event-driven CAPL language handles message and signal processing. Test
architecture supports multi-layer validation from signal to system level.
Integration with CI/CD and HIL systems enables automated testing at scale.

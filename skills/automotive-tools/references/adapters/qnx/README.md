# QNX Neutrino RTOS Tool Adapters

Complete QNX development tooling integration for automotive real-time applications.

## Overview

This package provides comprehensive Python adapters for QNX Neutrino RTOS development, supporting:

- **QNX Versions**: 7.0, 7.1, 8.0
- **Target Architectures**: x86_64, aarch64le, armv7le
- **Development Tools**: Momentics IDE, qcc compiler, GDB debugger
- **Deployment**: Remote target management via qconn/SSH

## Adapters

### 1. MomenticsAdapter

Automates QNX Momentics IDE operations via command-line.

**Features:**
- Project creation (C, C++, libraries, resource managers)
- Build configuration management
- Target connection setup
- Remote debugging sessions
- Project import/export

**Usage:**

```python
from tools.adapters.qnx import MomenticsAdapter, ProjectType, TargetArchitecture, BuildVariant

# Initialize adapter
adapter = MomenticsAdapter(
    ide_path="/opt/qnx710/ide",
    workspace_path="/home/user/qnx_workspace"
)

# Create new project
result = adapter.create_project(
    name="can_service",
    project_type=ProjectType.QNX_CPP_PROJECT,
    architecture=TargetArchitecture.AARCH64LE,
    build_variant=BuildVariant.RELEASE,
    libraries=["socket", "can"]
)

# Build project
build_result = adapter.build_project(
    project_name="can_service",
    build_variant=BuildVariant.RELEASE,
    clean=True
)

print(f"Binary: {build_result['data']['binary_path']}")
```

### 2. QnxSdpAdapter

Manages QNX Software Development Platform operations.

**Features:**
- Boot image creation (mkifs)
- Filesystem image creation (mkxfs)
- Package management (qnxpackage)
- BSP installation
- Target deployment
- Automotive-specific image templates

**Usage:**

```python
from tools.adapters.qnx import QnxSdpAdapter, QnxVersion, FilesystemType

# Initialize adapter
sdp = QnxSdpAdapter(qnx_version=QnxVersion.QNX_710)

# Create boot image
boot_result = sdp.create_boot_image(
    output_file="ifs-automotive.bin",
    programs=["devc-ser8250", "io-pkt-v6-hc", "dhclient"],
    drivers=["dev-can-mcp2515", "devnp-e1000"],
    libraries=["libc.so", "libsocket.so"]
)

# Create automotive image with CAN support
auto_result = sdp.build_automotive_image(
    output_file="ifs-vehicle-ecu.bin",
    include_can=True,
    include_ethernet=True,
    custom_drivers=["dev-can-flexcan"]
)

# Deploy to target
deploy_result = sdp.deploy_to_target(
    binary="can_service",
    target_ip="192.168.1.100",
    target_path="/usr/local/bin/"
)
```

### 3. ProcessManagerAdapter

Remote process control and monitoring via qconn.

**Features:**
- Process listing (pidin)
- Process termination (slay)
- Process launching (on)
- Priority management
- Memory profiling
- CPU usage tracking
- Real-time monitoring

**Usage:**

```python
from tools.adapters.qnx import ProcessManagerAdapter

# Initialize adapter
pm = ProcessManagerAdapter(
    target_ip="192.168.1.100",
    target_port=8000
)

# List all processes
processes = pm.list_processes()
for proc in processes['data']['processes']:
    print(f"{proc['name']}: PID={proc['pid']}, CPU={proc['cpu_percent']}%")

# Launch process with priority
launch_result = pm.launch_process(
    command="/usr/local/bin/can_service",
    priority=50,  # High priority
    background=True,
    env_vars={"CAN_INTERFACE": "can0"}
)

# Monitor process stats
stats = pm.get_process_stats(
    process_name="can_service",
    interval_seconds=1,
    samples=10
)

print(f"Average CPU: {stats['data']['average_cpu_percent']}%")
print(f"Average Memory: {stats['data']['average_memory_kb']} KB")

# Kill process
kill_result = pm.kill_process("can_service", force=True)
```

### 4. QnxBuildAdapter

QNX cross-compilation and build system integration.

**Features:**
- qcc compiler wrapper
- Multi-architecture builds
- Makefile generation
- Optimization levels
- Debug/release builds
- Automotive project templates

**Usage:**

```python
from tools.adapters.qnx import (
    QnxBuildAdapter,
    Architecture,
    OptimizationLevel,
    StandardVersion,
    BuildConfig,
    CompilerFlags,
    LinkerFlags
)

# Initialize adapter
builder = QnxBuildAdapter()

# Simple compilation
result = builder.compile(
    sources=["main.c", "can_driver.c"],
    output="can_service",
    architecture=Architecture.AARCH64LE,
    optimization=OptimizationLevel.O2,
    libraries=["socket", "can"]
)

# Advanced build with full configuration
config = BuildConfig(
    project_name="advanced_app",
    architecture=Architecture.ARMV7LE,
    source_files=["src/main.cpp", "src/module.cpp"],
    output_file="advanced_app",
    compiler_flags=CompilerFlags(
        optimization=OptimizationLevel.O3,
        debug=False,
        standard=StandardVersion.CPP14,
        defines=["NDEBUG", "AUTOMOTIVE_MODE"],
        warnings=["-Wall", "-Wextra", "-Werror"]
    ),
    linker_flags=LinkerFlags(
        libraries=["can", "socket", "pthread"],
        static=False
    )
)

build_result = builder.build(config)

# Generate Makefile
makefile_result = builder.generate_makefile(
    config=config,
    output_path="Makefile"
)

# Build using Makefile
make_result = builder.build_with_makefile(
    makefile_dir=".",
    variant="release",
    jobs=4
)
```

## Complete Workflow Example

```python
from tools.adapters.qnx import (
    MomenticsAdapter,
    QnxSdpAdapter,
    ProcessManagerAdapter,
    QnxBuildAdapter,
    ProjectType,
    Architecture,
    BuildVariant,
    TargetArchitecture
)

# 1. Create project
momentics = MomenticsAdapter()
project = momentics.create_project(
    name="vehicle_can_gateway",
    project_type=ProjectType.QNX_CPP_PROJECT,
    architecture=TargetArchitecture.AARCH64LE,
    libraries=["socket", "can", "pthread"]
)

# 2. Build project
builder = QnxBuildAdapter()
build = builder.compile_automotive_project(
    sources=["src/main.cpp", "src/can_handler.cpp"],
    output="vehicle_can_gateway",
    architecture=Architecture.AARCH64LE,
    include_can=True,
    realtime_priority=True
)

# 3. Create boot image
sdp = QnxSdpAdapter()
boot_image = sdp.build_automotive_image(
    output_file="ifs-gateway.bin",
    include_can=True,
    include_ethernet=True
)

# 4. Deploy to target
deploy = sdp.deploy_to_target(
    binary=build['data']['binary'],
    target_ip="192.168.1.100",
    target_path="/usr/local/bin/"
)

# 5. Launch and monitor
pm = ProcessManagerAdapter(target_ip="192.168.1.100")
launch = pm.launch_process(
    command="/usr/local/bin/vehicle_can_gateway",
    priority=50,
    background=True
)

# Monitor for 30 seconds
stats = pm.get_process_stats(
    process_name="vehicle_can_gateway",
    interval_seconds=3,
    samples=10
)

print(f"Application running: PID={launch['data']['pid']}")
print(f"Average CPU: {stats['data']['average_cpu_percent']}%")
```

## Command-Line Tools

### qnx-build.sh

Build QNX projects from command line.

```bash
# Build for ARM64
./commands/qnx/qnx-build.sh --name can_service --arch aarch64le --type release

# Debug build with verbose output
./commands/qnx/qnx-build.sh -n my_app -t debug -v
```

### qnx-deploy.sh

Deploy binaries to QNX target.

```bash
# Deploy to target
./commands/qnx/qnx-deploy.sh --binary build/aarch64le/release/can_service --ip 192.168.1.100

# Deploy and auto-start
./commands/qnx/qnx-deploy.sh -b my_app -i 192.168.1.100 -d /usr/local/bin -s
```

### qnx-debug.sh

Launch remote debugging session.

```bash
# Debug new process
./commands/qnx/qnx-debug.sh --binary build/aarch64le/debug/can_service --ip 192.168.1.100

# Attach to running process
./commands/qnx/qnx-debug.sh -b my_app -i 192.168.1.100 -n my_app
```

## QNX Skills

Advanced QNX development patterns available in `/skills/qnx/qnx-advanced.yaml`:

- **Message Passing**: Client-server IPC patterns
- **Pulses and Events**: Asynchronous notifications
- **Shared Memory**: High-speed data sharing
- **Atomic Operations**: Lock-free programming
- **Interrupt Handling**: ISR implementation
- **Resource Managers**: Custom device drivers
- **Priority Scheduling**: Real-time thread management

## QNX Developer Agent

Expert agent configuration in `/agents/qnx/qnx-developer.yaml`:

**Capabilities:**
- Design QNX system architecture
- Implement message passing IPC
- Develop device drivers
- Optimize real-time performance
- Debug multi-threaded applications
- Create boot images

**Use the agent:**
```
@qnx-developer Create a CAN gateway service with message passing IPC
```

## Environment Setup

### Prerequisites

```bash
# Install QNX SDP 7.1
# Download from QNX Software Center
# https://www.qnx.com/

# Extract to /opt/qnx710
sudo tar -xzf qnx710-sdp.tar.gz -C /opt/

# Set environment variables
export QNX_HOST=/opt/qnx710/host/linux/x86_64
export QNX_TARGET=/opt/qnx710/target/qnx7
export PATH=$QNX_HOST/usr/bin:$PATH
```

### Verify Installation

```python
from tools.adapters.qnx import QnxBuildAdapter

builder = QnxBuildAdapter()
version = builder.get_compiler_version()
print(version['data']['version_output'])
```

## Architecture Support

| Architecture | QCC Target | Description |
|--------------|------------|-------------|
| x86_64 | gcc_ntox86_64 | 64-bit x86 (simulation) |
| aarch64le | gcc_ntoaarch64le | 64-bit ARM (Cortex-A) |
| armv7le | gcc_ntoarmv7le | 32-bit ARM (Cortex-A) |

## Target Deployment

### Via SSH

```bash
# Configure SSH access
ssh-copy-id root@192.168.1.100

# Deploy binary
scp my_app root@192.168.1.100:/tmp/
ssh root@192.168.1.100 "chmod +x /tmp/my_app && /tmp/my_app &"
```

### Via qconn

```bash
# Start qconn on target
qconn port=8000

# From host
qcc -o my_app main.c
deploy my_app 192.168.1.100:/tmp/
```

## Automotive Use Cases

### CAN Service

```python
# Build CAN message handler
builder.compile_automotive_project(
    sources=["can_service.cpp"],
    output="can_service",
    include_can=True,
    realtime_priority=True
)
```

### Data Logger

```python
# High-speed sensor data logging
config = BuildConfig(
    project_name="data_logger",
    architecture=Architecture.AARCH64LE,
    source_files=["logger.cpp"],
    compiler_flags=CompilerFlags(
        optimization=OptimizationLevel.O3,
        defines=["HIGH_SPEED_LOGGING"]
    )
)
```

### ECU Gateway

```python
# Multi-protocol gateway
sdp.build_automotive_image(
    output_file="ifs-gateway.bin",
    include_can=True,
    include_lin=True,
    include_ethernet=True,
    custom_drivers=["dev-can-flexcan", "dev-lin-uart"]
)
```

## Troubleshooting

### QNX Environment Not Found

```bash
# Check environment variables
echo $QNX_HOST
echo $QNX_TARGET

# Source QNX environment
source /opt/qnx710/qnxsdp-env.sh
```

### Compilation Errors

```python
# Check compiler version
builder = QnxBuildAdapter()
version = builder.get_compiler_version()
print(version)
```

### Target Not Reachable

```python
# Test connectivity
pm = ProcessManagerAdapter(target_ip="192.168.1.100")
info = pm.get_system_resources()
print(info)
```

## Best Practices

1. **Real-Time Threads**: Use SCHED_FIFO with appropriate priorities
2. **IPC**: Prefer message passing over shared memory for control
3. **Error Handling**: Always check return codes from QNX APIs
4. **Memory Locking**: Use mlockall() for time-critical processes
5. **Resource Cleanup**: Always destroy channels and detach connections
6. **Interrupt Latency**: Measure and optimize with tracelogger
7. **Safety Critical**: Follow MISRA C/C++ guidelines

## References

- [QNX Neutrino RTOS Documentation](https://www.qnx.com/developers/docs/)
- [QNX Momentics IDE Guide](https://www.qnx.com/developers/docs/7.1/index.html#com.qnx.doc.ide.userguide/)
- [QNX System Architecture](https://www.qnx.com/developers/docs/7.1/index.html#com.qnx.doc.neutrino.sys_arch/)

## License

Part of Automotive Claude Code Agents framework.

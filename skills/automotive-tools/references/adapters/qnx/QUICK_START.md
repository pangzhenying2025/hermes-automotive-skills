# QNX Quick Start Guide

Get started with QNX development in 5 minutes.

## Prerequisites

1. **QNX SDP Installation**
   ```bash
   # Download QNX SDP 7.1 from https://www.qnx.com/
   # Install to /opt/qnx710

   # Set environment
   export QNX_HOST=/opt/qnx710/host/linux/x86_64
   export QNX_TARGET=/opt/qnx710/target/qnx7
   export PATH=$QNX_HOST/usr/bin:$PATH
   ```

2. **Python Requirements**
   ```bash
   pip install -r requirements.txt
   ```

## 5-Minute Tutorial

### Step 1: Build a Simple Application

```python
from tools.adapters.qnx import QnxBuildAdapter, Architecture

builder = QnxBuildAdapter()

# Compile
result = builder.compile(
    sources=["main.c"],
    output="hello_qnx",
    architecture=Architecture.AARCH64LE
)

print(f"Binary: {result['data']['binary']}")
```

### Step 2: Create Boot Image

```python
from tools.adapters.qnx import QnxSdpAdapter

sdp = QnxSdpAdapter()

# Create automotive boot image
image = sdp.build_automotive_image(
    output_file="ifs-automotive.bin",
    include_can=True,
    include_ethernet=True
)

print(f"Boot image: {image['data']['boot_image']}")
```

### Step 3: Deploy to Target

```bash
# Using command-line tool
./commands/qnx/qnx-deploy.sh \
    --binary hello_qnx \
    --ip 192.168.1.100 \
    --start
```

### Step 4: Monitor Process

```python
from tools.adapters.qnx import ProcessManagerAdapter

pm = ProcessManagerAdapter(target_ip="192.168.1.100")

# Get stats
stats = pm.get_process_stats("hello_qnx", samples=5)
print(f"CPU: {stats['data']['average_cpu_percent']}%")
```

## Common Use Cases

### CAN Service Development

```python
builder = QnxBuildAdapter()

result = builder.compile_automotive_project(
    sources=["can_service.cpp"],
    output="can_service",
    include_can=True,
    realtime_priority=True
)
```

### Multi-Core Application

```python
from tools.adapters.qnx import ProcessManagerAdapter

pm = ProcessManagerAdapter(target_ip="192.168.1.100")

# Launch with high priority
pm.launch_process(
    command="/usr/local/bin/my_app",
    priority=50,
    env_vars={"CPU_AFFINITY": "1"}
)
```

### Remote Debugging

```bash
./commands/qnx/qnx-debug.sh \
    --binary build/aarch64le/debug/my_app \
    --ip 192.168.1.100
```

## Architecture Quick Reference

| Target | Architecture | Example ECU |
|--------|--------------|-------------|
| x86_64 | gcc_ntox86_64 | Simulation |
| aarch64le | gcc_ntoaarch64le | NXP S32G, Renesas R-Car |
| armv7le | gcc_ntoarmv7le | NXP i.MX, TI Sitara |

## Troubleshooting

### QNX Environment Not Set

```bash
# Add to ~/.bashrc
export QNX_HOST=/opt/qnx710/host/linux/x86_64
export QNX_TARGET=/opt/qnx710/target/qnx7
export PATH=$QNX_HOST/usr/bin:$PATH
```

### Target Not Reachable

```bash
# Test connectivity
ping 192.168.1.100

# Check SSH
ssh root@192.168.1.100 "uname -a"
```

### Compiler Not Found

```python
from tools.adapters.qnx import QnxBuildAdapter

builder = QnxBuildAdapter()
version = builder.get_compiler_version()
print(version)
```

## Next Steps

- Read [complete README](README.md) for full API reference
- Check [examples](../../../examples/qnx/) for working code
- Review [QNX skills](../../../skills/qnx/qnx-advanced.yaml) for advanced patterns
- Use [QNX Developer Agent](../../../agents/qnx/qnx-developer.yaml) for expert guidance

## Resources

- [QNX Documentation](https://www.qnx.com/developers/docs/)
- [QNX Community](https://www.qnx.com/community/)
- [Automotive Examples](../../../examples/qnx/)

---

**Ready to build automotive QNX applications!** 🚀

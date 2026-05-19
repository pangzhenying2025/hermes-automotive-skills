# Installation Guide - Automotive Claude Code Agents

## System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 20.04+, Debian 11+), macOS 12+, Windows 10+ with WSL2
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disk**: 20 GB free space
- **Python**: 3.8 or higher
- **Node.js**: 16.x or higher (for web interfaces)

### Recommended Requirements
- **OS**: Ubuntu 22.04 LTS or Debian 12
- **CPU**: 8+ cores
- **RAM**: 16 GB
- **Disk**: 50 GB SSD
- **Python**: 3.11
- **GPU**: Optional, for ML-based code analysis

## Installation Methods

### Method 1: Quick Install (Recommended)

```bash
# Clone repository
git clone https://github.com/yourusername/automotive-claude-code-agents.git
cd automotive-claude-code-agents

# Run installation script
./scripts/install.sh

# Activate environment
source .venv/bin/activate

# Verify installation
make verify
```

### Method 2: Manual Installation

#### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/automotive-claude-code-agents.git
cd automotive-claude-code-agents
```

#### Step 2: Create Virtual Environment

```bash
# Using venv
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# OR using conda
conda create -n auto-agents python=3.11
conda activate auto-agents
```

#### Step 3: Install Dependencies

```bash
# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Install development dependencies (optional)
pip install -r requirements-dev.txt
```

#### Step 4: Install Optional Components

```bash
# AUTOSAR tools (if working with AUTOSAR)
pip install autosar>=0.5.0

# CAN tools
pip install python-can cantools

# Automotive protocols
pip install udsoncan j1939

# Static analysis tools
pip install pylint mypy bandit

# Testing tools
pip install pytest pytest-cov pytest-asyncio
```

#### Step 5: Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit configuration
nano .env
```

**Required Environment Variables**:

```bash
# Claude API Configuration
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Agent Configuration
AGENT_WORKSPACE=/path/to/your/workspace
AGENT_LOG_LEVEL=INFO

# Optional: Tool Paths
AUTOSAR_TOOLS_PATH=/opt/autosar-tools
CAN_INTERFACE=can0
```

#### Step 6: Initialize Knowledge Base

```bash
# Index knowledge base for fast search
make index-knowledge-base

# Verify knowledge base
make verify-kb
```

#### Step 7: Run Tests

```bash
# Run all tests
make test

# Run specific test suites
pytest tests/agents/
pytest tests/skills/
pytest tests/tools/
```

## Tool-Specific Installation

### AUTOSAR Development Tools

#### ARCTIC CORE (Open-Source AUTOSAR)

```bash
# Clone ARCTIC CORE
cd ~/workspace
git clone https://github.com/ARCTIC-CORE/ARCTIC-CORE.git
cd ARCTIC-CORE

# Add to environment
echo "export ARCTIC_CORE_PATH=~/workspace/ARCTIC-CORE" >> ~/.bashrc
source ~/.bashrc
```

#### Vector DaVinci Developer (Commercial)

If using commercial tools, ensure:
```bash
# Add to PATH
export PATH=/opt/vector/DaVinci/bin:$PATH

# License server
export VECTOR_LICENSE_SERVER=27000@license-server
```

### CAN/Automotive Bus Tools

#### SocketCAN (Linux)

```bash
# Install can-utils
sudo apt-get install can-utils

# Load kernel modules
sudo modprobe can
sudo modprobe can_raw
sudo modprobe vcan

# Create virtual CAN interface for testing
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

#### Peak CAN Drivers (for PEAK hardware)

```bash
# Download from https://www.peak-system.com/
wget https://www.peak-system.com/fileadmin/media/linux/files/peak-linux-driver-8.15.2.tar.gz
tar -xzf peak-linux-driver-8.15.2.tar.gz
cd peak-linux-driver-8.15.2
make
sudo make install
```

### Diagnostic Tools

#### OBD-II / UDS Tools

```bash
# Install udsoncan
pip install udsoncan

# Install python-can
pip install python-can

# Install can-isotp (for UDS over CAN)
pip install can-isotp
```

### Simulation & HIL Tools

#### CARLA Simulator

```bash
# Download CARLA
wget https://carla-releases.s3.eu-west-3.amazonaws.com/Linux/CARLA_0.9.14.tar.gz
tar -xzf CARLA_0.9.14.tar.gz -C ~/carla

# Install Python API
pip install carla==0.9.14

# Run simulator
cd ~/carla
./CarlaUE4.sh
```

## IDE Configuration

### Visual Studio Code

#### Install Extensions

```bash
# Install VS Code extensions
code --install-extension ms-python.python
code --install-extension ms-vscode.cpptools
code --install-extension twxs.cmake
code --install-extension ms-vscode.cmake-tools
code --install-extension vector.vector-cfg
```

#### Configure Settings

Create `.vscode/settings.json`:

```json
{
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.formatting.provider": "black",
  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,
  "C_Cpp.default.compilerPath": "/usr/bin/gcc",
  "C_Cpp.default.cppStandard": "c++14",
  "C_Cpp.default.cStandard": "c11",
  "cmake.configureOnOpen": true,
  "files.associations": {
    "*.arxml": "xml",
    "*.oil": "c",
    "*.dbc": "plaintext"
  }
}
```

### CLion / IntelliJ IDEA

```bash
# Import project as CMake project
# Configure toolchain: File → Settings → Build, Execution, Deployment → Toolchains

# Add AUTOSAR file associations
# File → Settings → Editor → File Types
```

## Docker Installation (Alternative)

### Pull Pre-Built Image

```bash
# Pull image
docker pull yourusername/automotive-agents:latest

# Run container
docker run -it --rm \
  -v $(pwd):/workspace \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  yourusername/automotive-agents:latest
```

### Build from Dockerfile

```bash
# Build image
docker build -t automotive-agents .

# Run container with GPU support (for ML)
docker run --gpus all -it --rm \
  -v $(pwd):/workspace \
  automotive-agents
```

### Docker Compose (Full Stack)

```yaml
# docker-compose.yml
version: '3.8'

services:
  agent:
    build: .
    volumes:
      - .:/workspace
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    command: python -m agents.cli

  web-ui:
    build: ./web-ui
    ports:
      - "8080:8080"
    depends_on:
      - agent

  database:
    image: postgres:15
    environment:
      - POSTGRES_DB=automotive_agents
      - POSTGRES_USER=agent
      - POSTGRES_PASSWORD=secret
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  db-data:
```

Run with:
```bash
docker-compose up
```

## Verification

### Verify Installation

```bash
# Run verification script
make verify

# Expected output:
# ✓ Python version: 3.11.x
# ✓ Dependencies installed
# ✓ Knowledge base indexed
# ✓ Agents available: 41
# ✓ Skills available: 123
# ✓ Commands available: 54
# ✓ Tools configured
```

### Test Agent Functionality

```bash
# Test code-reviewer agent
./agents/code-reviewer/test.sh

# Test AUTOSAR skill
python -m skills.autosar.test

# Test CAN communication
python -m tools.can.test_socketcan
```

## Troubleshooting

### Common Issues

#### Issue: Import Error for Anthropic SDK

```bash
# Solution: Install Anthropic SDK
pip install anthropic>=0.18.0
```

#### Issue: CAN Interface Not Found

```bash
# Solution: Load kernel module
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Verify
ifconfig vcan0
```

#### Issue: AUTOSAR Tools Not Found

```bash
# Solution: Set AUTOSAR_TOOLS_PATH
export AUTOSAR_TOOLS_PATH=/path/to/autosar/tools
echo "export AUTOSAR_TOOLS_PATH=/path/to/autosar/tools" >> ~/.bashrc
```

#### Issue: Permission Denied for /dev/ttyUSB0

```bash
# Solution: Add user to dialout group
sudo usermod -a -G dialout $USER
# Logout and login again
```

### Getting Help

- **Documentation**: `docs/` directory
- **GitHub Issues**: https://github.com/yourusername/automotive-claude-code-agents/issues
- **Community Forum**: TBD
- **Email Support**: support@yourdomain.com

## Next Steps

After installation:

1. **Quick Start**: Read [quick-start.md](quick-start.md)
2. **Tool Setup**: Configure automotive tools [tool-setup.md](tool-setup.md)
3. **Tutorials**: Follow AUTOSAR tutorial [../tutorials/autosar-swc-tutorial.md](../tutorials/autosar-swc-tutorial.md)
4. **API Reference**: Explore API docs [../api/](../api/)

## Updating

```bash
# Pull latest changes
git pull origin main

# Update dependencies
pip install --upgrade -r requirements.txt

# Re-index knowledge base
make index-knowledge-base

# Run tests
make test
```

## Uninstallation

```bash
# Deactivate virtual environment
deactivate

# Remove installation
rm -rf ~/automotive-claude-code-agents

# Remove virtual environment
rm -rf ~/.venv/automotive-agents

# Remove configuration
rm ~/.config/automotive-agents/
```

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Maintained By**: Automotive Claude Code Agents Team

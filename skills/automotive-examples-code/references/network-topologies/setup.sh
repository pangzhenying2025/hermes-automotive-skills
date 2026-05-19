#!/bin/bash
#
# Setup script for multi-ECU network topology
# Prepares host system and starts Docker containers

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Multi-ECU Network Topology Setup ===${NC}"
echo ""

# Check if running as root for vcan setup
if [[ $EUID -ne 0 ]] && [[ ! $(groups | grep docker) ]]; then
    echo -e "${RED}Error: This script requires sudo or docker group membership${NC}"
    echo "Run: sudo usermod -aG docker $USER && newgrp docker"
    exit 1
fi

# Check Docker
echo -e "${BLUE}Checking Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    echo "Install: sudo apt-get install docker.io docker-compose"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    echo "Install: sudo apt-get install docker-compose"
    exit 1
fi

echo -e "${GREEN}Docker: OK${NC}"

# Setup vcan interfaces
echo -e "${BLUE}Setting up vcan interfaces...${NC}"

# Load vcan module
sudo modprobe vcan || true

# Create vcan0
if ! ip link show vcan0 &> /dev/null; then
    sudo ip link add dev vcan0 type vcan
    sudo ip link set up vcan0
    echo -e "${GREEN}vcan0 created${NC}"
else
    echo -e "${YELLOW}vcan0 already exists${NC}"
fi

# Create vcan1
if ! ip link show vcan1 &> /dev/null; then
    sudo ip link add dev vcan1 type vcan
    sudo ip link set up vcan1
    echo -e "${GREEN}vcan1 created${NC}"
else
    echo -e "${YELLOW}vcan1 already exists${NC}"
fi

# Create ecu-scripts directory if not exists
mkdir -p ecu-scripts

# Create test script
cat > ecu-scripts/test-connectivity.sh << 'EOF'
#!/bin/sh
# Test connectivity from ECU

HOSTNAME=$(hostname)
echo "Testing connectivity from $HOSTNAME..."

# Test gateway connectivity
if ping -c 2 172.20.0.10 > /dev/null 2>&1; then
    echo "✓ CAN Gateway (172.20.0.10): OK"
else
    echo "✗ CAN Gateway (172.20.0.10): FAILED"
fi

if ping -c 2 192.168.100.10 > /dev/null 2>&1; then
    echo "✓ ETH Gateway (192.168.100.10): OK"
else
    echo "✗ ETH Gateway (192.168.100.10): FAILED"
fi

# Test cross-domain connectivity
if ping -c 2 172.20.0.20 > /dev/null 2>&1; then
    echo "✓ Powertrain ECU (172.20.0.20): OK"
else
    echo "✗ Powertrain ECU (172.20.0.20): Not reachable"
fi

if ping -c 2 192.168.100.20 > /dev/null 2>&1; then
    echo "✓ ADAS ECU (192.168.100.20): OK"
else
    echo "✗ ADAS ECU (192.168.100.20): Not reachable"
fi
EOF

chmod +x ecu-scripts/test-connectivity.sh

# Start Docker Compose
echo ""
echo -e "${BLUE}Starting Docker containers...${NC}"
docker-compose up -d

# Wait for containers to be ready
echo -e "${BLUE}Waiting for containers to start...${NC}"
sleep 3

# Check container status
echo ""
echo -e "${BLUE}Container Status:${NC}"
docker-compose ps

# Test connectivity
echo ""
echo -e "${BLUE}Testing connectivity...${NC}"
sleep 2

# Test CAN domain
echo -e "\n${YELLOW}Testing CAN Domain:${NC}"
docker exec powertrain-ecu ping -c 2 172.20.0.10 > /dev/null 2>&1 && \
    echo -e "${GREEN}✓ Powertrain ECU -> Gateway${NC}" || \
    echo -e "${RED}✗ Powertrain ECU -> Gateway${NC}"

docker exec body-ecu ping -c 2 172.20.0.10 > /dev/null 2>&1 && \
    echo -e "${GREEN}✓ Body ECU -> Gateway${NC}" || \
    echo -e "${RED}✗ Body ECU -> Gateway${NC}"

# Test Ethernet domain
echo -e "\n${YELLOW}Testing Ethernet Domain:${NC}"
docker exec adas-ecu ping -c 2 192.168.100.10 > /dev/null 2>&1 && \
    echo -e "${GREEN}✓ ADAS ECU -> Gateway${NC}" || \
    echo -e "${RED}✗ ADAS ECU -> Gateway${NC}"

docker exec infotainment-ecu ping -c 2 192.168.100.10 > /dev/null 2>&1 && \
    echo -e "${GREEN}✓ Infotainment ECU -> Gateway${NC}" || \
    echo -e "${RED}✗ Infotainment ECU -> Gateway${NC}"

# Test cross-domain routing
echo -e "\n${YELLOW}Testing Cross-Domain Routing:${NC}"
docker exec powertrain-ecu ping -c 2 192.168.100.20 > /dev/null 2>&1 && \
    echo -e "${GREEN}✓ Powertrain ECU -> ADAS ECU (via Gateway)${NC}" || \
    echo -e "${RED}✗ Powertrain ECU -> ADAS ECU${NC}"

docker exec adas-ecu ping -c 2 172.20.0.20 > /dev/null 2>&1 && \
    echo -e "${GREEN}✓ ADAS ECU -> Powertrain ECU (via Gateway)${NC}" || \
    echo -e "${RED}✗ ADAS ECU -> Powertrain ECU${NC}"

# Summary
echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Network Topology:"
echo "  CAN Domain (172.20.0.0/16):"
echo "    - Gateway ECU:    172.20.0.10"
echo "    - Powertrain ECU: 172.20.0.20"
echo "    - Body ECU:       172.20.0.30"
echo ""
echo "  Ethernet Domain (192.168.100.0/24):"
echo "    - Gateway ECU:      192.168.100.10"
echo "    - ADAS ECU:         192.168.100.20"
echo "    - Infotainment ECU: 192.168.100.30"
echo ""
echo "CAN Interfaces:"
echo "  - vcan0 (mounted in powertrain-ecu, gateway-ecu)"
echo "  - vcan1 (mounted in body-ecu)"
echo ""
echo "Useful commands:"
echo "  docker-compose ps                              # View container status"
echo "  docker-compose logs -f                         # View logs"
echo "  docker exec -it gateway-ecu sh                 # Enter gateway ECU"
echo "  docker exec powertrain-ecu /scripts/test-connectivity.sh"
echo "  docker-compose down                            # Stop all containers"
echo ""
echo "Monitor traffic:"
echo "  sudo tcpdump -i br-can -n                      # Monitor CAN domain"
echo "  sudo tcpdump -i br-eth -n                      # Monitor Ethernet domain"
echo "  docker exec gateway-ecu tcpdump -i eth0 -n     # Monitor from gateway"
echo ""

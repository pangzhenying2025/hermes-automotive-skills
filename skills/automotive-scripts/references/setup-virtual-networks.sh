#!/bin/bash
#
# Virtual Network Setup Script for Automotive HIL/SIL Testing
# Creates veth pairs, vcan interfaces, TAP devices, and network namespaces
# for multi-ECU simulation and testing
#
# Usage:
#   ./setup-virtual-networks.sh create [topology]
#   ./setup-virtual-networks.sh destroy
#   ./setup-virtual-networks.sh status
#
# Topologies:
#   basic      - Simple 2-ECU setup
#   gateway    - 3-ECU gateway topology (CAN + Ethernet)
#   multi      - 5-ECU complex topology
#   docker     - Docker container integration

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/virtual-networks-setup.log"

# Network configuration
CAN_DOMAIN_SUBNET="172.20.0.0/16"
ETH_DOMAIN_SUBNET="192.168.100.0/24"
GATEWAY_SUBNET="10.0.0.0/24"
BRIDGE_NAME="br-automotive"

# Function to log messages
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        INFO)
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        DEBUG)
            echo -e "${BLUE}[DEBUG]${NC} $message"
            ;;
    esac

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log ERROR "This script must be run as root or with sudo"
        exit 1
    fi
}

# Function to check required tools
check_dependencies() {
    log INFO "Checking dependencies..."

    local deps=("ip" "tc" "iptables" "tcpdump")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log ERROR "Missing dependencies: ${missing[*]}"
        log INFO "Install with: sudo apt-get install iproute2 iptables tcpdump"
        exit 1
    fi

    log INFO "All dependencies satisfied"
}

# Function to enable IP forwarding
enable_ip_forwarding() {
    log INFO "Enabling IP forwarding..."
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null
    log INFO "IP forwarding enabled"
}

# Function to create veth pair
create_veth_pair() {
    local name1=$1
    local name2=$2
    local ip1=$3
    local ip2=$4

    log INFO "Creating veth pair: $name1 <-> $name2"

    # Check if already exists
    if ip link show "$name1" &> /dev/null; then
        log WARN "Interface $name1 already exists, skipping"
        return 0
    fi

    # Create pair
    ip link add "$name1" type veth peer name "$name2"

    # Configure IPs if provided
    if [ -n "$ip1" ]; then
        ip addr add "$ip1" dev "$name1"
    fi
    if [ -n "$ip2" ]; then
        ip addr add "$ip2" dev "$name2"
    fi

    # Bring up
    ip link set "$name1" up
    ip link set "$name2" up

    log INFO "veth pair created successfully"
}

# Function to create network namespace
create_namespace() {
    local ns_name=$1

    log INFO "Creating network namespace: $ns_name"

    if ip netns list | grep -q "^$ns_name"; then
        log WARN "Namespace $ns_name already exists, skipping"
        return 0
    fi

    ip netns add "$ns_name"

    # Enable loopback
    ip netns exec "$ns_name" ip link set lo up

    log INFO "Namespace $ns_name created"
}

# Function to move interface to namespace
move_to_namespace() {
    local iface=$1
    local ns_name=$2
    local ip_addr=$3

    log INFO "Moving $iface to namespace $ns_name"

    ip link set "$iface" netns "$ns_name"
    ip netns exec "$ns_name" ip addr add "$ip_addr" dev "$iface"
    ip netns exec "$ns_name" ip link set "$iface" up

    log INFO "Interface $iface configured in namespace $ns_name"
}

# Function to create bridge
create_bridge() {
    local br_name=$1
    local ip_addr=$2

    log INFO "Creating bridge: $br_name"

    if ip link show "$br_name" &> /dev/null; then
        log WARN "Bridge $br_name already exists, skipping"
        return 0
    fi

    ip link add "$br_name" type bridge
    ip link set "$br_name" up

    if [ -n "$ip_addr" ]; then
        ip addr add "$ip_addr" dev "$br_name"
    fi

    # Enable multicast for SOME/IP
    ip link set "$br_name" multicast on
    echo 1 > /sys/class/net/"$br_name"/bridge/multicast_snooping || true

    log INFO "Bridge $br_name created"
}

# Function to add interface to bridge
add_to_bridge() {
    local iface=$1
    local br_name=$2

    log INFO "Adding $iface to bridge $br_name"

    ip link set "$iface" master "$br_name"
    ip link set "$iface" up

    log INFO "Interface $iface added to bridge $br_name"
}

# Function to create vcan interface
create_vcan() {
    local vcan_name=$1

    log INFO "Creating vcan interface: $vcan_name"

    if ip link show "$vcan_name" &> /dev/null; then
        log WARN "vcan interface $vcan_name already exists, skipping"
        return 0
    fi

    # Load vcan module if not loaded
    modprobe vcan || true

    ip link add dev "$vcan_name" type vcan
    ip link set "$vcan_name" up

    log INFO "vcan interface $vcan_name created"
}

# Function to create TAP interface
create_tap() {
    local tap_name=$1
    local ip_addr=$2
    local user=${3:-$SUDO_USER}

    log INFO "Creating TAP interface: $tap_name"

    if ip link show "$tap_name" &> /dev/null; then
        log WARN "TAP interface $tap_name already exists, skipping"
        return 0
    fi

    if [ -n "$user" ] && [ "$user" != "root" ]; then
        ip tuntap add dev "$tap_name" mode tap user "$user"
    else
        ip tuntap add dev "$tap_name" mode tap
    fi

    ip link set "$tap_name" up

    if [ -n "$ip_addr" ]; then
        ip addr add "$ip_addr" dev "$tap_name"
    fi

    log INFO "TAP interface $tap_name created"
}

# Function to apply traffic shaping
apply_traffic_shaping() {
    local iface=$1
    local delay=${2:-1ms}
    local loss=${3:-0.1%}
    local rate=${4:-100mbit}

    log INFO "Applying traffic shaping to $iface (delay=$delay, loss=$loss, rate=$rate)"

    # Remove existing qdisc if any
    tc qdisc del dev "$iface" root 2>/dev/null || true

    # Apply netem
    tc qdisc add dev "$iface" root netem \
        delay "$delay" \
        loss "$loss" \
        rate "$rate" \
        limit 1000

    log INFO "Traffic shaping applied to $iface"
}

# Function to setup basic topology (2 ECUs)
setup_basic_topology() {
    log INFO "Setting up basic 2-ECU topology..."

    # Create bridge
    create_bridge "$BRIDGE_NAME" "192.168.100.1/24"

    # Create veth pairs for each ECU
    for i in 1 2; do
        local ecu_veth="veth-ecu$i"
        local br_veth="veth-br$i"

        create_veth_pair "$ecu_veth" "$br_veth" "" ""
        add_to_bridge "$br_veth" "$BRIDGE_NAME"

        # Configure ECU interface
        ip addr add "192.168.100.$((10+i))/24" dev "$ecu_veth"

        # Apply light traffic shaping
        apply_traffic_shaping "$ecu_veth" "1ms" "0.05%" "100mbit"
    done

    # Create vcan interface
    create_vcan "vcan0"

    log INFO "Basic topology setup complete"
    log INFO "ECU1: 192.168.100.11 (veth-ecu1)"
    log INFO "ECU2: 192.168.100.12 (veth-ecu2)"
    log INFO "Bridge: 192.168.100.1 ($BRIDGE_NAME)"
    log INFO "CAN: vcan0"
}

# Function to setup gateway topology (3 ECUs with gateway)
setup_gateway_topology() {
    log INFO "Setting up 3-ECU gateway topology..."

    # Create namespaces
    create_namespace "can-domain"
    create_namespace "eth-domain"
    create_namespace "gateway"

    # Enable IP forwarding in gateway namespace
    ip netns exec gateway sysctl -w net.ipv4.ip_forward=1 > /dev/null

    # Create veth pairs for CAN domain
    create_veth_pair "veth-can-ecu1" "veth-can-host" "" ""
    create_veth_pair "veth-can-gw" "veth-can-gw-host" "" ""

    # Create veth pairs for Ethernet domain
    create_veth_pair "veth-eth-ecu2" "veth-eth-host" "" ""
    create_veth_pair "veth-eth-gw" "veth-eth-gw-host" "" ""

    # Move interfaces to namespaces
    move_to_namespace "veth-can-ecu1" "can-domain" "172.20.0.20/16"
    move_to_namespace "veth-can-gw" "gateway" "172.20.0.1/16"

    move_to_namespace "veth-eth-ecu2" "eth-domain" "192.168.100.20/24"
    move_to_namespace "veth-eth-gw" "gateway" "192.168.100.1/24"

    # Configure host-side bridges
    create_bridge "br-can" "172.20.0.5/16"
    add_to_bridge "veth-can-host" "br-can"
    add_to_bridge "veth-can-gw-host" "br-can"

    create_bridge "br-eth" "192.168.100.5/24"
    add_to_bridge "veth-eth-host" "br-eth"
    add_to_bridge "veth-eth-gw-host" "br-eth"

    # Add default routes in ECU namespaces
    ip netns exec can-domain ip route add default via 172.20.0.1
    ip netns exec eth-domain ip route add default via 192.168.100.1

    # Create vcan in CAN domain namespace
    ip netns exec can-domain ip link add dev vcan0 type vcan
    ip netns exec can-domain ip link set vcan0 up

    # Apply traffic shaping
    apply_traffic_shaping "veth-can-host" "2ms" "0.1%" "1000mbit"
    apply_traffic_shaping "veth-eth-host" "1ms" "0.05%" "100mbit"

    log INFO "Gateway topology setup complete"
    log INFO "CAN Domain: 172.20.0.20 (namespace: can-domain)"
    log INFO "Eth Domain: 192.168.100.20 (namespace: eth-domain)"
    log INFO "Gateway: 172.20.0.1 / 192.168.100.1 (namespace: gateway)"
    log INFO ""
    log INFO "Test commands:"
    log INFO "  sudo ip netns exec can-domain ping 172.20.0.1"
    log INFO "  sudo ip netns exec eth-domain ping 192.168.100.1"
    log INFO "  sudo ip netns exec can-domain ping 192.168.100.20"
}

# Function to setup multi-ECU topology (5 ECUs)
setup_multi_topology() {
    log INFO "Setting up multi-ECU topology (5 ECUs)..."

    # Create main bridge
    create_bridge "$BRIDGE_NAME" "192.168.100.1/24"

    # Create 5 ECU setups
    local ecu_names=("gateway" "powertrain" "adas" "body" "infotainment")

    for i in "${!ecu_names[@]}"; do
        local idx=$((i + 1))
        local name="${ecu_names[$i]}"
        local ns="ecu-$name"
        local veth_ecu="veth-$name"
        local veth_br="veth-br-$name"
        local ip="192.168.100.$((10 + idx))"

        log INFO "Setting up ECU: $name ($ip)"

        # Create namespace
        create_namespace "$ns"

        # Create veth pair
        create_veth_pair "$veth_ecu" "$veth_br" "" ""

        # Move to namespace and configure
        move_to_namespace "$veth_ecu" "$ns" "$ip/24"

        # Add host side to bridge
        add_to_bridge "$veth_br" "$BRIDGE_NAME"

        # Add default route
        ip netns exec "$ns" ip route add default via 192.168.100.1

        # Apply different traffic shaping based on ECU type
        case $name in
            gateway)
                apply_traffic_shaping "$veth_br" "0.5ms" "0.01%" "1000mbit"
                ;;
            powertrain|adas)
                apply_traffic_shaping "$veth_br" "1ms" "0.05%" "100mbit"
                ;;
            body|infotainment)
                apply_traffic_shaping "$veth_br" "2ms" "0.1%" "100mbit"
                ;;
        esac
    done

    # Create multiple vcan interfaces
    for i in 0 1 2; do
        create_vcan "vcan$i"
    done

    # Create TAP interface for QEMU
    create_tap "tap-qemu0" "192.168.100.50/24"
    add_to_bridge "tap-qemu0" "$BRIDGE_NAME"

    log INFO "Multi-ECU topology setup complete"
    log INFO ""
    log INFO "ECUs:"
    for i in "${!ecu_names[@]}"; do
        local idx=$((i + 1))
        local name="${ecu_names[$i]}"
        local ip="192.168.100.$((10 + idx))"
        log INFO "  $name: $ip (namespace: ecu-$name)"
    done
    log INFO ""
    log INFO "CAN interfaces: vcan0, vcan1, vcan2"
    log INFO "TAP interface: tap-qemu0 (192.168.100.50)"
}

# Function to setup Docker integration
setup_docker_topology() {
    log INFO "Setting up Docker container integration..."

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        log ERROR "Docker is not installed"
        exit 1
    fi

    # Create Docker networks
    log INFO "Creating Docker networks..."

    # CAN domain network
    if ! docker network ls | grep -q can-domain; then
        docker network create \
            --driver bridge \
            --subnet "$CAN_DOMAIN_SUBNET" \
            --gateway 172.20.0.1 \
            can-domain
        log INFO "Created can-domain network"
    else
        log WARN "can-domain network already exists"
    fi

    # Ethernet domain network
    if ! docker network ls | grep -q eth-domain; then
        docker network create \
            --driver bridge \
            --subnet "$ETH_DOMAIN_SUBNET" \
            --gateway 192.168.100.1 \
            eth-domain
        log INFO "Created eth-domain network"
    else
        log WARN "eth-domain network already exists"
    fi

    # Create vcan interfaces on host
    for i in 0 1; do
        create_vcan "vcan$i"
    done

    log INFO "Docker topology setup complete"
    log INFO ""
    log INFO "Docker networks created:"
    log INFO "  can-domain: $CAN_DOMAIN_SUBNET"
    log INFO "  eth-domain: $ETH_DOMAIN_SUBNET"
    log INFO ""
    log INFO "Example Docker run commands:"
    log INFO "  docker run -d --name gateway-ecu --network can-domain --ip 172.20.0.10 automotive-ecu:gateway"
    log INFO "  docker run -d --name adas-ecu --network eth-domain --ip 192.168.100.20 automotive-ecu:adas"
}

# Function to destroy all virtual networks
destroy_networks() {
    log INFO "Destroying all virtual networks..."

    # Stop all Docker containers using our networks
    if command -v docker &> /dev/null; then
        log INFO "Stopping Docker containers..."
        docker ps -q --filter "network=can-domain" | xargs -r docker stop 2>/dev/null || true
        docker ps -q --filter "network=eth-domain" | xargs -r docker stop 2>/dev/null || true

        log INFO "Removing Docker networks..."
        docker network rm can-domain 2>/dev/null || true
        docker network rm eth-domain 2>/dev/null || true
    fi

    # Delete all veth interfaces
    log INFO "Removing veth interfaces..."
    for veth in $(ip link show type veth | grep -o 'veth[^:@]*' | sort -u); do
        log DEBUG "Deleting $veth"
        ip link delete "$veth" 2>/dev/null || true
    done

    # Delete all network namespaces
    log INFO "Removing network namespaces..."
    for ns in $(ip netns list | awk '{print $1}'); do
        log DEBUG "Deleting namespace $ns"
        ip netns delete "$ns" 2>/dev/null || true
    done

    # Delete all bridges
    log INFO "Removing bridges..."
    for br in $(ip link show type bridge | grep -o 'br-[^:@]*' | sort -u); do
        log DEBUG "Deleting bridge $br"
        ip link delete "$br" 2>/dev/null || true
    done

    # Delete vcan interfaces
    log INFO "Removing vcan interfaces..."
    for vcan in $(ip link show type vcan | grep -o 'vcan[0-9]*' | sort -u); do
        log DEBUG "Deleting $vcan"
        ip link delete "$vcan" 2>/dev/null || true
    done

    # Delete TAP interfaces
    log INFO "Removing TAP interfaces..."
    for tap in $(ip link show type tun | grep -o 'tap[^:@]*' | sort -u); do
        log DEBUG "Deleting $tap"
        ip tuntap del dev "$tap" mode tap 2>/dev/null || true
    done

    log INFO "All virtual networks destroyed"
}

# Function to show status
show_status() {
    log INFO "Virtual Network Status"
    log INFO "======================"
    echo ""

    # veth interfaces
    echo -e "${BLUE}=== veth Interfaces ===${NC}"
    ip link show type veth | grep -E '^[0-9]+:' || echo "None"
    echo ""

    # Bridges
    echo -e "${BLUE}=== Bridge Interfaces ===${NC}"
    ip link show type bridge | grep -E '^[0-9]+:' || echo "None"
    echo ""

    # Network namespaces
    echo -e "${BLUE}=== Network Namespaces ===${NC}"
    ip netns list || echo "None"
    echo ""

    # vcan interfaces
    echo -e "${BLUE}=== vcan Interfaces ===${NC}"
    ip link show type vcan | grep -E '^[0-9]+:' || echo "None"
    echo ""

    # TAP interfaces
    echo -e "${BLUE}=== TAP Interfaces ===${NC}"
    ip link show type tun | grep -E '^[0-9]+:' || echo "None"
    echo ""

    # Docker networks
    if command -v docker &> /dev/null; then
        echo -e "${BLUE}=== Docker Networks ===${NC}"
        docker network ls --filter "name=can-domain" --filter "name=eth-domain" || echo "None"
        echo ""
    fi

    # IP forwarding status
    echo -e "${BLUE}=== IP Forwarding ===${NC}"
    echo "IPv4: $(cat /proc/sys/net/ipv4/ip_forward)"
    echo "IPv6: $(cat /proc/sys/net/ipv6/conf/all/forwarding)"
}

# Main script
main() {
    local command=${1:-help}
    local topology=${2:-basic}

    case $command in
        create)
            check_root
            check_dependencies
            enable_ip_forwarding

            case $topology in
                basic)
                    setup_basic_topology
                    ;;
                gateway)
                    setup_gateway_topology
                    ;;
                multi)
                    setup_multi_topology
                    ;;
                docker)
                    setup_docker_topology
                    ;;
                *)
                    log ERROR "Unknown topology: $topology"
                    log INFO "Available topologies: basic, gateway, multi, docker"
                    exit 1
                    ;;
            esac
            ;;

        destroy)
            check_root
            destroy_networks
            ;;

        status)
            show_status
            ;;

        help|--help|-h)
            cat << EOF
Virtual Network Setup Script for Automotive HIL/SIL Testing

Usage:
    $0 create [topology]    Create virtual network topology
    $0 destroy             Destroy all virtual networks
    $0 status              Show current network status
    $0 help                Show this help message

Topologies:
    basic       Simple 2-ECU setup with bridge and vcan
    gateway     3-ECU gateway topology with namespaces (CAN + Ethernet domains)
    multi       5-ECU complex topology with namespaces
    docker      Docker container integration with custom networks

Examples:
    sudo $0 create basic
    sudo $0 create gateway
    sudo $0 status
    sudo $0 destroy

Log file: $LOG_FILE
EOF
            ;;

        *)
            log ERROR "Unknown command: $command"
            log INFO "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

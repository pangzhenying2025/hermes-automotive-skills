#!/usr/bin/env python3
"""
Test script for virtual network adapter
Demonstrates creating and testing virtual network topologies
"""

import sys
import time
import logging
from pathlib import Path

# Add parent directory to path to import adapter
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from tools.adapters.network.virtual_network_adapter import (
    VirtualNetworkAdapter,
    VethPair,
    TrafficShapingConfig,
    LinkState
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def test_basic_topology():
    """Test basic 2-ECU topology"""
    logger.info("=" * 60)
    logger.info("Testing Basic 2-ECU Topology")
    logger.info("=" * 60)

    adapter = VirtualNetworkAdapter()

    try:
        # Create bridge
        logger.info("Creating bridge...")
        adapter.create_bridge("br-automotive", "192.168.100.1/24")

        # Create veth pairs for ECUs
        for i in range(1, 3):
            logger.info(f"Creating ECU {i}...")

            veth_config = VethPair(
                end1=f"veth-ecu{i}",
                end2=f"veth-br{i}",
                ip1=f"192.168.100.{10+i}/24",
                ip2=None
            )
            adapter.create_veth_pair(veth_config)
            adapter.add_to_bridge(f"veth-br{i}", "br-automotive")

            # Apply traffic shaping
            tc_config = TrafficShapingConfig(
                delay="1ms",
                loss="0.05%",
                rate="100mbit"
            )
            adapter.apply_traffic_shaping(f"veth-ecu{i}", tc_config)

        # Create vcan
        logger.info("Creating vcan interface...")
        adapter.create_vcan("vcan0")

        logger.info("")
        logger.info("Topology created successfully!")
        logger.info("ECU1: 192.168.100.11 (veth-ecu1)")
        logger.info("ECU2: 192.168.100.12 (veth-ecu2)")
        logger.info("Bridge: 192.168.100.1 (br-automotive)")
        logger.info("CAN: vcan0")

        # Show statistics
        logger.info("")
        logger.info("Interface Statistics:")
        for i in range(1, 3):
            stats = adapter.get_interface_stats(f"veth-ecu{i}")
            if stats:
                logger.info(
                    f"  {stats.interface}: "
                    f"RX {stats.rx_packets} packets ({stats.rx_bytes} bytes), "
                    f"TX {stats.tx_packets} packets ({stats.tx_bytes} bytes)"
                )

        # Wait before cleanup
        logger.info("")
        logger.info("Topology will be cleaned up in 5 seconds...")
        time.sleep(5)

    finally:
        logger.info("Cleaning up...")
        adapter.cleanup()
        logger.info("Cleanup complete")


def test_namespace_topology():
    """Test multi-ECU topology with namespaces"""
    logger.info("")
    logger.info("=" * 60)
    logger.info("Testing Multi-ECU Topology with Namespaces")
    logger.info("=" * 60)

    adapter = VirtualNetworkAdapter()

    try:
        # Create namespaces for ECUs
        logger.info("Creating namespaces...")
        for i in range(1, 4):
            adapter.create_namespace(f"ecu{i}")

        # Create bridge
        logger.info("Creating bridge...")
        adapter.create_bridge("br-automotive", "192.168.100.1/24")

        # Create veth pairs and connect to namespaces
        for i in range(1, 4):
            logger.info(f"Configuring ECU {i} in namespace...")

            veth_config = VethPair(
                end1=f"veth-ecu{i}",
                end2=f"veth-br{i}",
                ip1=f"192.168.100.{10+i}/24",
                namespace1=f"ecu{i}",
                ip2=None
            )
            adapter.create_veth_pair(veth_config)
            adapter.add_to_bridge(f"veth-br{i}", "br-automotive")

        # Create vcan in each namespace
        for i in range(1, 4):
            logger.info(f"Creating vcan in ecu{i} namespace...")
            adapter.create_vcan(f"vcan{i}", namespace=f"ecu{i}")

        logger.info("")
        logger.info("Namespace topology created successfully!")
        logger.info("ECU1: 192.168.100.11 (namespace: ecu1)")
        logger.info("ECU2: 192.168.100.12 (namespace: ecu2)")
        logger.info("ECU3: 192.168.100.13 (namespace: ecu3)")
        logger.info("Bridge: 192.168.100.1 (default namespace)")

        # Wait before cleanup
        logger.info("")
        logger.info("Topology will be cleaned up in 5 seconds...")
        time.sleep(5)

    finally:
        logger.info("Cleaning up...")
        adapter.cleanup()
        logger.info("Cleanup complete")


def test_traffic_shaping():
    """Test various traffic shaping configurations"""
    logger.info("")
    logger.info("=" * 60)
    logger.info("Testing Traffic Shaping")
    logger.info("=" * 60)

    adapter = VirtualNetworkAdapter()

    try:
        # Create simple veth pair
        logger.info("Creating veth pair for traffic shaping test...")
        veth_config = VethPair(
            end1="veth-test0",
            end2="veth-test1",
            ip1="10.0.0.1/24",
            ip2="10.0.0.2/24"
        )
        adapter.create_veth_pair(veth_config)

        # Test different traffic shaping scenarios
        scenarios = [
            {
                "name": "Good Conditions",
                "config": TrafficShapingConfig(
                    delay="1ms",
                    loss="0.01%",
                    rate="1000mbit"
                )
            },
            {
                "name": "Medium Conditions",
                "config": TrafficShapingConfig(
                    delay="5ms",
                    jitter="2ms",
                    loss="0.5%",
                    rate="100mbit"
                )
            },
            {
                "name": "Poor Conditions (EMI)",
                "config": TrafficShapingConfig(
                    delay="20ms",
                    jitter="10ms",
                    loss="5%",
                    duplicate="1%",
                    rate="10mbit"
                )
            }
        ]

        for scenario in scenarios:
            logger.info(f"\nApplying: {scenario['name']}")
            adapter.apply_traffic_shaping("veth-test0", scenario['config'])
            logger.info(f"  Delay: {scenario['config'].delay}")
            if scenario['config'].jitter:
                logger.info(f"  Jitter: {scenario['config'].jitter}")
            logger.info(f"  Loss: {scenario['config'].loss}")
            logger.info(f"  Rate: {scenario['config'].rate}")
            time.sleep(1)

        # Wait before cleanup
        logger.info("")
        logger.info("Test will be cleaned up in 3 seconds...")
        time.sleep(3)

    finally:
        logger.info("Cleaning up...")
        adapter.cleanup()
        logger.info("Cleanup complete")


def test_gateway_topology():
    """Test gateway topology with CAN and Ethernet domains"""
    logger.info("")
    logger.info("=" * 60)
    logger.info("Testing Gateway Topology (CAN + Ethernet)")
    logger.info("=" * 60)

    adapter = VirtualNetworkAdapter()

    try:
        # Create namespaces
        logger.info("Creating namespaces...")
        adapter.create_namespace("can-domain")
        adapter.create_namespace("eth-domain")
        adapter.create_namespace("gateway")

        # Create veth pairs for CAN domain
        logger.info("Setting up CAN domain...")
        can_veth = VethPair(
            end1="veth-can-ecu",
            end2="veth-can-gw",
            ip1="172.20.0.20/16",
            namespace1="can-domain",
            ip2="172.20.0.1/16",
            namespace2="gateway"
        )
        adapter.create_veth_pair(can_veth)

        # Create veth pairs for Ethernet domain
        logger.info("Setting up Ethernet domain...")
        eth_veth = VethPair(
            end1="veth-eth-ecu",
            end2="veth-eth-gw",
            ip1="192.168.100.20/24",
            namespace1="eth-domain",
            ip2="192.168.100.1/24",
            namespace2="gateway"
        )
        adapter.create_veth_pair(eth_veth)

        # Create vcan in CAN domain
        logger.info("Creating vcan in CAN domain...")
        adapter.create_vcan("vcan0", namespace="can-domain")

        logger.info("")
        logger.info("Gateway topology created successfully!")
        logger.info("CAN Domain: 172.20.0.20 (namespace: can-domain)")
        logger.info("Eth Domain: 192.168.100.20 (namespace: eth-domain)")
        logger.info("Gateway: 172.20.0.1 / 192.168.100.1 (namespace: gateway)")
        logger.info("")
        logger.info("Note: Enable IP forwarding in gateway namespace for routing:")
        logger.info("  sudo ip netns exec gateway sysctl -w net.ipv4.ip_forward=1")

        # Wait before cleanup
        logger.info("")
        logger.info("Topology will be cleaned up in 5 seconds...")
        time.sleep(5)

    finally:
        logger.info("Cleaning up...")
        adapter.cleanup()
        logger.info("Cleanup complete")


def main():
    """Run all tests"""
    print("\n" + "=" * 60)
    print("Virtual Network Adapter Test Suite")
    print("=" * 60)
    print("\nThis script will create and test various network topologies.")
    print("Each topology will be cleaned up automatically.\n")

    input("Press Enter to start tests...")

    try:
        # Run tests
        test_basic_topology()
        test_namespace_topology()
        test_traffic_shaping()
        test_gateway_topology()

        logger.info("")
        logger.info("=" * 60)
        logger.info("All tests completed successfully!")
        logger.info("=" * 60)

    except KeyboardInterrupt:
        logger.info("\n\nTests interrupted by user")
    except Exception as e:
        logger.error(f"\n\nTest failed with error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()

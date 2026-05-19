#!/usr/bin/env python3
"""
Virtual Network Adapter
Python API for managing virtual network interfaces for automotive HIL/SIL testing
Provides programmatic control of veth pairs, namespaces, bridges, and traffic shaping
"""

import subprocess
import json
import logging
import time
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
import re

logger = logging.getLogger(__name__)


class InterfaceType(Enum):
    """Network interface types"""
    VETH = "veth"
    BRIDGE = "bridge"
    VCAN = "vcan"
    TAP = "tap"
    TUN = "tun"
    VLAN = "vlan"
    MACVLAN = "macvlan"


class LinkState(Enum):
    """Interface link states"""
    UP = "up"
    DOWN = "down"
    UNKNOWN = "unknown"


@dataclass
class InterfaceConfig:
    """Network interface configuration"""
    name: str
    type: InterfaceType
    ip_address: Optional[str] = None
    mtu: int = 1500
    mac_address: Optional[str] = None
    namespace: Optional[str] = None
    state: LinkState = LinkState.DOWN


@dataclass
class VethPair:
    """Virtual Ethernet pair configuration"""
    end1: str
    end2: str
    ip1: Optional[str] = None
    ip2: Optional[str] = None
    namespace1: Optional[str] = None
    namespace2: Optional[str] = None


@dataclass
class TrafficShapingConfig:
    """Traffic shaping configuration using tc netem"""
    delay: Optional[str] = None  # e.g., "10ms"
    jitter: Optional[str] = None  # e.g., "2ms"
    loss: Optional[str] = None  # e.g., "0.1%"
    duplicate: Optional[str] = None  # e.g., "0.01%"
    corrupt: Optional[str] = None  # e.g., "0.001%"
    rate: Optional[str] = None  # e.g., "100mbit"
    limit: int = 1000


@dataclass
class NetworkStats:
    """Network interface statistics"""
    interface: str
    rx_bytes: int = 0
    tx_bytes: int = 0
    rx_packets: int = 0
    tx_packets: int = 0
    rx_errors: int = 0
    tx_errors: int = 0
    rx_dropped: int = 0
    tx_dropped: int = 0


class VirtualNetworkAdapter:
    """
    Adapter for managing virtual network interfaces
    Provides high-level Python API for automotive network testing
    """

    def __init__(self, sudo: bool = True, dry_run: bool = False):
        """
        Initialize virtual network adapter

        Args:
            sudo: Whether to use sudo for commands
            dry_run: If True, print commands without executing
        """
        self.sudo = sudo
        self.dry_run = dry_run
        self.created_interfaces: List[str] = []
        self.created_namespaces: List[str] = []

    def _run_command(self, cmd: List[str], check: bool = True) -> subprocess.CompletedProcess:
        """
        Execute shell command

        Args:
            cmd: Command as list of arguments
            check: Whether to check return code

        Returns:
            CompletedProcess with stdout, stderr, returncode

        Raises:
            subprocess.CalledProcessError: If check=True and command fails
        """
        if self.sudo and cmd[0] not in ['docker']:
            cmd = ['sudo'] + cmd

        logger.debug(f"Executing: {' '.join(cmd)}")

        if self.dry_run:
            print(f"[DRY RUN] {' '.join(cmd)}")
            return subprocess.CompletedProcess(cmd, 0, stdout='', stderr='')

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=check
            )
            return result
        except subprocess.CalledProcessError as e:
            logger.error(f"Command failed: {' '.join(cmd)}")
            logger.error(f"Error: {e.stderr}")
            raise

    def create_veth_pair(self, config: VethPair) -> bool:
        """
        Create virtual Ethernet pair

        Args:
            config: VethPair configuration

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Creating veth pair: {config.end1} <-> {config.end2}")

            # Check if already exists
            if self._interface_exists(config.end1):
                logger.warning(f"Interface {config.end1} already exists")
                return False

            # Create pair
            cmd = ['ip', 'link', 'add', config.end1, 'type', 'veth', 'peer', 'name', config.end2]
            self._run_command(cmd)

            self.created_interfaces.extend([config.end1, config.end2])

            # Move to namespaces if specified
            if config.namespace1:
                self.move_to_namespace(config.end1, config.namespace1)

            if config.namespace2:
                self.move_to_namespace(config.end2, config.namespace2)

            # Configure IP addresses
            if config.ip1:
                self.set_ip_address(config.end1, config.ip1, config.namespace1)

            if config.ip2:
                self.set_ip_address(config.end2, config.ip2, config.namespace2)

            # Bring up interfaces
            self.set_link_state(config.end1, LinkState.UP, config.namespace1)
            self.set_link_state(config.end2, LinkState.UP, config.namespace2)

            logger.info(f"veth pair created successfully")
            return True

        except Exception as e:
            logger.error(f"Failed to create veth pair: {e}")
            return False

    def create_namespace(self, name: str) -> bool:
        """
        Create network namespace

        Args:
            name: Namespace name

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Creating network namespace: {name}")

            # Check if already exists
            if self._namespace_exists(name):
                logger.warning(f"Namespace {name} already exists")
                return False

            cmd = ['ip', 'netns', 'add', name]
            self._run_command(cmd)

            self.created_namespaces.append(name)

            # Enable loopback
            self._run_command(['ip', 'netns', 'exec', name, 'ip', 'link', 'set', 'lo', 'up'])

            logger.info(f"Namespace {name} created")
            return True

        except Exception as e:
            logger.error(f"Failed to create namespace: {e}")
            return False

    def move_to_namespace(self, interface: str, namespace: str) -> bool:
        """
        Move interface to network namespace

        Args:
            interface: Interface name
            namespace: Target namespace

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Moving {interface} to namespace {namespace}")

            # Ensure namespace exists
            if not self._namespace_exists(namespace):
                self.create_namespace(namespace)

            cmd = ['ip', 'link', 'set', interface, 'netns', namespace]
            self._run_command(cmd)

            logger.info(f"Interface {interface} moved to namespace {namespace}")
            return True

        except Exception as e:
            logger.error(f"Failed to move interface to namespace: {e}")
            return False

    def create_bridge(self, name: str, ip_address: Optional[str] = None) -> bool:
        """
        Create bridge interface

        Args:
            name: Bridge name
            ip_address: IP address with CIDR (e.g., "192.168.1.1/24")

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Creating bridge: {name}")

            if self._interface_exists(name):
                logger.warning(f"Bridge {name} already exists")
                return False

            cmd = ['ip', 'link', 'add', name, 'type', 'bridge']
            self._run_command(cmd)

            self.created_interfaces.append(name)

            # Enable multicast for SOME/IP
            self.set_link_state(name, LinkState.UP)
            self._run_command(['ip', 'link', 'set', name, 'multicast', 'on'])

            # Enable IGMP snooping
            snooping_path = f"/sys/class/net/{name}/bridge/multicast_snooping"
            try:
                if not self.dry_run:
                    self._run_command(['sh', '-c', f'echo 1 > {snooping_path}'], check=False)
            except:
                pass  # May fail if not supported

            if ip_address:
                self.set_ip_address(name, ip_address)

            logger.info(f"Bridge {name} created")
            return True

        except Exception as e:
            logger.error(f"Failed to create bridge: {e}")
            return False

    def add_to_bridge(self, interface: str, bridge: str) -> bool:
        """
        Add interface to bridge

        Args:
            interface: Interface to add
            bridge: Bridge name

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Adding {interface} to bridge {bridge}")

            cmd = ['ip', 'link', 'set', interface, 'master', bridge]
            self._run_command(cmd)

            self.set_link_state(interface, LinkState.UP)

            logger.info(f"Interface {interface} added to bridge {bridge}")
            return True

        except Exception as e:
            logger.error(f"Failed to add interface to bridge: {e}")
            return False

    def create_vcan(self, name: str, namespace: Optional[str] = None) -> bool:
        """
        Create virtual CAN interface

        Args:
            name: vcan interface name
            namespace: Optional namespace

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Creating vcan interface: {name}")

            # Load vcan module
            try:
                self._run_command(['modprobe', 'vcan'], check=False)
            except:
                pass  # May already be loaded

            if self._interface_exists(name, namespace):
                logger.warning(f"vcan interface {name} already exists")
                return False

            cmd_prefix = ['ip', 'netns', 'exec', namespace] if namespace else []
            cmd = cmd_prefix + ['ip', 'link', 'add', 'dev', name, 'type', 'vcan']
            self._run_command(cmd)

            self.created_interfaces.append(name)

            # Bring up
            cmd = cmd_prefix + ['ip', 'link', 'set', name, 'up']
            self._run_command(cmd)

            logger.info(f"vcan interface {name} created")
            return True

        except Exception as e:
            logger.error(f"Failed to create vcan interface: {e}")
            return False

    def create_tap(self, name: str, ip_address: Optional[str] = None, user: Optional[str] = None) -> bool:
        """
        Create TAP interface

        Args:
            name: TAP interface name
            ip_address: IP address with CIDR
            user: User to own the TAP interface

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Creating TAP interface: {name}")

            if self._interface_exists(name):
                logger.warning(f"TAP interface {name} already exists")
                return False

            cmd = ['ip', 'tuntap', 'add', 'dev', name, 'mode', 'tap']
            if user:
                cmd.extend(['user', user])

            self._run_command(cmd)
            self.created_interfaces.append(name)

            self.set_link_state(name, LinkState.UP)

            if ip_address:
                self.set_ip_address(name, ip_address)

            logger.info(f"TAP interface {name} created")
            return True

        except Exception as e:
            logger.error(f"Failed to create TAP interface: {e}")
            return False

    def set_ip_address(self, interface: str, ip_address: str, namespace: Optional[str] = None) -> bool:
        """
        Set IP address on interface

        Args:
            interface: Interface name
            ip_address: IP address with CIDR (e.g., "192.168.1.1/24")
            namespace: Optional namespace

        Returns:
            True if successful, False otherwise
        """
        try:
            cmd_prefix = ['ip', 'netns', 'exec', namespace] if namespace else []
            cmd = cmd_prefix + ['ip', 'addr', 'add', ip_address, 'dev', interface]
            self._run_command(cmd)

            logger.info(f"IP address {ip_address} set on {interface}")
            return True

        except Exception as e:
            logger.error(f"Failed to set IP address: {e}")
            return False

    def set_link_state(self, interface: str, state: LinkState, namespace: Optional[str] = None) -> bool:
        """
        Set interface link state (up/down)

        Args:
            interface: Interface name
            state: Link state
            namespace: Optional namespace

        Returns:
            True if successful, False otherwise
        """
        try:
            cmd_prefix = ['ip', 'netns', 'exec', namespace] if namespace else []
            cmd = cmd_prefix + ['ip', 'link', 'set', interface, state.value]
            self._run_command(cmd)

            logger.info(f"Interface {interface} set to {state.value}")
            return True

        except Exception as e:
            logger.error(f"Failed to set link state: {e}")
            return False

    def apply_traffic_shaping(self, interface: str, config: TrafficShapingConfig) -> bool:
        """
        Apply traffic shaping using tc netem

        Args:
            interface: Interface name
            config: Traffic shaping configuration

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Applying traffic shaping to {interface}")

            # Remove existing qdisc
            self._run_command(['tc', 'qdisc', 'del', 'dev', interface, 'root'], check=False)

            # Build netem command
            cmd = ['tc', 'qdisc', 'add', 'dev', interface, 'root', 'netem']

            if config.delay:
                cmd.extend(['delay', config.delay])
                if config.jitter:
                    cmd.append(config.jitter)

            if config.loss:
                cmd.extend(['loss', config.loss])

            if config.duplicate:
                cmd.extend(['duplicate', config.duplicate])

            if config.corrupt:
                cmd.extend(['corrupt', config.corrupt])

            if config.rate:
                cmd.extend(['rate', config.rate])

            cmd.extend(['limit', str(config.limit)])

            self._run_command(cmd)

            logger.info(f"Traffic shaping applied to {interface}")
            return True

        except Exception as e:
            logger.error(f"Failed to apply traffic shaping: {e}")
            return False

    def get_interface_stats(self, interface: str, namespace: Optional[str] = None) -> Optional[NetworkStats]:
        """
        Get interface statistics

        Args:
            interface: Interface name
            namespace: Optional namespace

        Returns:
            NetworkStats object or None if failed
        """
        try:
            cmd_prefix = ['ip', 'netns', 'exec', namespace] if namespace else []
            cmd = cmd_prefix + ['ip', '-s', 'link', 'show', interface]
            result = self._run_command(cmd)

            # Parse output
            stats = NetworkStats(interface=interface)
            lines = result.stdout.split('\n')

            for i, line in enumerate(lines):
                if 'RX:' in line and i + 1 < len(lines):
                    rx_line = lines[i + 1].split()
                    if len(rx_line) >= 2:
                        stats.rx_bytes = int(rx_line[0])
                        stats.rx_packets = int(rx_line[1])
                    if len(rx_line) >= 4:
                        stats.rx_errors = int(rx_line[2])
                        stats.rx_dropped = int(rx_line[3])

                if 'TX:' in line and i + 1 < len(lines):
                    tx_line = lines[i + 1].split()
                    if len(tx_line) >= 2:
                        stats.tx_bytes = int(tx_line[0])
                        stats.tx_packets = int(tx_line[1])
                    if len(tx_line) >= 4:
                        stats.tx_errors = int(tx_line[2])
                        stats.tx_dropped = int(tx_line[3])

            return stats

        except Exception as e:
            logger.error(f"Failed to get interface stats: {e}")
            return None

    def delete_interface(self, name: str) -> bool:
        """
        Delete network interface

        Args:
            name: Interface name

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Deleting interface: {name}")

            cmd = ['ip', 'link', 'delete', name]
            self._run_command(cmd)

            if name in self.created_interfaces:
                self.created_interfaces.remove(name)

            logger.info(f"Interface {name} deleted")
            return True

        except Exception as e:
            logger.error(f"Failed to delete interface: {e}")
            return False

    def delete_namespace(self, name: str) -> bool:
        """
        Delete network namespace

        Args:
            name: Namespace name

        Returns:
            True if successful, False otherwise
        """
        try:
            logger.info(f"Deleting namespace: {name}")

            cmd = ['ip', 'netns', 'delete', name]
            self._run_command(cmd)

            if name in self.created_namespaces:
                self.created_namespaces.remove(name)

            logger.info(f"Namespace {name} deleted")
            return True

        except Exception as e:
            logger.error(f"Failed to delete namespace: {e}")
            return False

    def cleanup(self) -> None:
        """Clean up all created interfaces and namespaces"""
        logger.info("Cleaning up virtual networks...")

        # Delete interfaces
        for iface in self.created_interfaces[:]:  # Copy list to avoid modification during iteration
            self.delete_interface(iface)

        # Delete namespaces
        for ns in self.created_namespaces[:]:
            self.delete_namespace(ns)

        logger.info("Cleanup complete")

    def _interface_exists(self, name: str, namespace: Optional[str] = None) -> bool:
        """Check if interface exists"""
        try:
            cmd_prefix = ['ip', 'netns', 'exec', namespace] if namespace else []
            cmd = cmd_prefix + ['ip', 'link', 'show', name]
            self._run_command(cmd, check=True)
            return True
        except:
            return False

    def _namespace_exists(self, name: str) -> bool:
        """Check if namespace exists"""
        try:
            result = self._run_command(['ip', 'netns', 'list'], check=True)
            return name in result.stdout
        except:
            return False


def main():
    """Example usage"""
    import argparse

    parser = argparse.ArgumentParser(description="Virtual Network Adapter")
    parser.add_argument('--dry-run', action='store_true', help='Print commands without executing')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')
    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    adapter = VirtualNetworkAdapter(dry_run=args.dry_run)

    # Example: Create basic 2-ECU topology
    print("Creating basic 2-ECU topology...")

    # Create bridge
    adapter.create_bridge("br-automotive", "192.168.100.1/24")

    # Create veth pairs for ECUs
    for i in range(1, 3):
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
    adapter.create_vcan("vcan0")

    print("\nTopology created successfully!")
    print("ECU1: 192.168.100.11 (veth-ecu1)")
    print("ECU2: 192.168.100.12 (veth-ecu2)")
    print("Bridge: 192.168.100.1 (br-automotive)")
    print("CAN: vcan0")

    # Show stats
    print("\nInterface statistics:")
    for i in range(1, 3):
        stats = adapter.get_interface_stats(f"veth-ecu{i}")
        if stats:
            print(f"  {stats.interface}: RX {stats.rx_packets} packets, TX {stats.tx_packets} packets")

    # Cleanup on exit
    input("\nPress Enter to cleanup...")
    adapter.cleanup()


if __name__ == '__main__':
    main()

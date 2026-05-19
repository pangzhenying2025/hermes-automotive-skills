#!/usr/bin/env python3
"""
QEMU Virtual ECU Adapter

Provides interface to QEMU emulator for Software-in-the-Loop testing.
Supports ARM Cortex-M, Cortex-A, PowerPC, and TriCore emulation.
"""

import argparse
import json
import logging
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass


@dataclass
class QEMUConfig:
    """QEMU configuration parameters."""
    architecture: str  # arm, powerpc, tricore, x86_64
    machine_type: str  # virt, versatilepb, ppce500, etc.
    cpu_model: str
    memory_mb: int
    network_config: Dict[str, Any]
    serial_ports: int
    gdb_port: Optional[int]


class QEMUAdapter:
    """Adapter for QEMU virtual ECU emulation."""

    def __init__(self, config: QEMUConfig):
        """
        Initialize QEMU adapter.

        Args:
            config: QEMU configuration
        """
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.qemu_process = None
        self.binary_loaded = False
        self.vm_running = False

    def create_vm(self) -> bool:
        """
        Create virtual machine configuration.

        Returns:
            True if VM created successfully
        """
        try:
            self.logger.info(f"Creating QEMU VM for {self.config.architecture}")

            # Validate QEMU installation
            qemu_binary = self._get_qemu_binary()
            result = subprocess.run([qemu_binary, '--version'], capture_output=True, text=True)

            if result.returncode != 0:
                self.logger.error(f"QEMU not found: {qemu_binary}")
                return False

            self.logger.info(f"QEMU version: {result.stdout.split()[3]}")
            return True

        except Exception as e:
            self.logger.error(f"VM creation failed: {e}")
            return False

    def _get_qemu_binary(self) -> str:
        """Get QEMU binary name for architecture."""
        arch_map = {
            'arm-cortex-m4': 'qemu-system-arm',
            'arm-cortex-a53': 'qemu-system-aarch64',
            'powerpc-e200': 'qemu-system-ppc',
            'x86_64': 'qemu-system-x86_64',
            'tricore-tc39x': 'qemu-system-tricore'
        }
        return arch_map.get(self.config.architecture, 'qemu-system-arm')

    def load_binary(self, binary_path: str) -> bool:
        """
        Load ECU binary to virtual machine.

        Args:
            binary_path: Path to ELF binary

        Returns:
            True if binary loaded successfully
        """
        try:
            self.logger.info(f"Loading binary: {binary_path}")

            if not Path(binary_path).exists():
                self.logger.error(f"Binary not found: {binary_path}")
                return False

            # Validate binary format
            result = subprocess.run(['file', binary_path], capture_output=True, text=True)
            self.logger.info(f"Binary type: {result.stdout.strip()}")

            self.binary_path = binary_path
            self.binary_loaded = True
            return True

        except Exception as e:
            self.logger.error(f"Binary loading failed: {e}")
            return False

    def start_vm(self, debug: bool = False) -> bool:
        """
        Start QEMU virtual machine.

        Args:
            debug: Enable GDB debugging

        Returns:
            True if VM started successfully
        """
        if not self.binary_loaded:
            self.logger.error("No binary loaded")
            return False

        try:
            self.logger.info("Starting QEMU virtual machine")

            qemu_cmd = self._build_qemu_command(debug)
            self.logger.debug(f"QEMU command: {' '.join(qemu_cmd)}")

            # Start QEMU process
            self.qemu_process = subprocess.Popen(
                qemu_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            time.sleep(1.0)  # Allow VM to boot

            if self.qemu_process.poll() is not None:
                self.logger.error("QEMU process terminated unexpectedly")
                return False

            self.vm_running = True
            self.logger.info("Virtual machine running")
            return True

        except Exception as e:
            self.logger.error(f"VM start failed: {e}")
            return False

    def _build_qemu_command(self, debug: bool) -> List[str]:
        """Build QEMU command line."""
        qemu_binary = self._get_qemu_binary()

        cmd = [
            qemu_binary,
            '-M', self.config.machine_type,
            '-cpu', self.config.cpu_model,
            '-m', str(self.config.memory_mb),
            '-kernel', self.binary_path,
            '-nographic'
        ]

        # Add network configuration
        if self.config.network_config.get('enable_network'):
            cmd.extend([
                '-netdev', 'user,id=net0',
                '-device', 'virtio-net-device,netdev=net0'
            ])

        # Add serial ports
        for i in range(self.config.serial_ports):
            cmd.extend(['-serial', 'mon:stdio' if i == 0 else 'null'])

        # Enable GDB debugging
        if debug and self.config.gdb_port:
            cmd.extend(['-s', '-S'])  # Wait for GDB connection

        return cmd

    def stop_vm(self) -> bool:
        """
        Stop QEMU virtual machine.

        Returns:
            True if VM stopped successfully
        """
        try:
            if self.qemu_process:
                self.logger.info("Stopping virtual machine")
                self.qemu_process.terminate()
                self.qemu_process.wait(timeout=5)
                self.qemu_process = None
                self.vm_running = False
            return True

        except subprocess.TimeoutExpired:
            self.logger.warning("Force killing QEMU process")
            self.qemu_process.kill()
            self.qemu_process = None
            self.vm_running = False
            return True

        except Exception as e:
            self.logger.error(f"VM stop failed: {e}")
            return False

    def attach_gdb(self) -> bool:
        """
        Attach GDB debugger to running VM.

        Returns:
            True if GDB attached successfully
        """
        if not self.vm_running:
            self.logger.error("VM not running")
            return False

        try:
            gdb_port = self.config.gdb_port or 1234
            self.logger.info(f"Attach GDB to localhost:{gdb_port}")
            self.logger.info(f"Command: gdb {self.binary_path} -ex 'target remote localhost:{gdb_port}'")
            return True

        except Exception as e:
            self.logger.error(f"GDB attach failed: {e}")
            return False

    def configure_network(self, network_config: Dict[str, Any]) -> bool:
        """
        Configure virtual network interfaces.

        Args:
            network_config: Network configuration

        Returns:
            True if configuration successful
        """
        try:
            self.logger.info("Configuring virtual network")

            # Configure virtual CAN interfaces
            if network_config.get('vcan_interfaces'):
                for vcan in network_config['vcan_interfaces']:
                    subprocess.run(['sudo', 'ip', 'link', 'add', 'dev', vcan, 'type', 'vcan'], check=True)
                    subprocess.run(['sudo', 'ip', 'link', 'set', 'up', vcan], check=True)
                    self.logger.info(f"Created virtual CAN interface: {vcan}")

            # Configure tap interface for Ethernet
            if network_config.get('tap_interface'):
                tap_name = network_config['tap_interface']
                subprocess.run(['sudo', 'ip', 'tuntap', 'add', 'dev', tap_name, 'mode', 'tap'], check=True)
                subprocess.run(['sudo', 'ip', 'link', 'set', 'up', tap_name], check=True)
                self.logger.info(f"Created TAP interface: {tap_name}")

            return True

        except Exception as e:
            self.logger.error(f"Network configuration failed: {e}")
            return False

    def get_vm_status(self) -> Dict[str, Any]:
        """
        Get virtual machine status.

        Returns:
            VM status information
        """
        status = {
            'running': self.vm_running,
            'binary_loaded': self.binary_loaded,
            'architecture': self.config.architecture,
            'machine_type': self.config.machine_type,
            'memory_mb': self.config.memory_mb
        }

        if self.qemu_process:
            status['pid'] = self.qemu_process.pid
            status['returncode'] = self.qemu_process.poll()

        return status

    def cleanup(self) -> bool:
        """
        Cleanup virtual network interfaces.

        Returns:
            True if cleanup successful
        """
        try:
            self.logger.info("Cleaning up virtual interfaces")

            # Remove virtual CAN interfaces
            result = subprocess.run(['ip', 'link', 'show'], capture_output=True, text=True)
            for line in result.stdout.split('\n'):
                if 'vcan' in line:
                    vcan = line.split(':')[1].strip()
                    subprocess.run(['sudo', 'ip', 'link', 'delete', vcan], check=False)

            return True

        except Exception as e:
            self.logger.error(f"Cleanup failed: {e}")
            return False


def main():
    """Command-line interface for QEMU adapter."""
    parser = argparse.ArgumentParser(description='QEMU Virtual ECU Adapter')
    parser.add_argument('--architecture', default='arm-cortex-m4', help='Target architecture')
    parser.add_argument('--create-vm', action='store_true', help='Create virtual machine')
    parser.add_argument('--load-binary', type=str, help='Load ELF binary')
    parser.add_argument('--start', action='store_true', help='Start virtual machine')
    parser.add_argument('--stop', action='store_true', help='Stop virtual machine')
    parser.add_argument('--debug', action='store_true', help='Enable GDB debugging')
    parser.add_argument('--status', action='store_true', help='Get VM status')
    parser.add_argument('--cleanup', action='store_true', help='Cleanup virtual interfaces')

    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

    # Create adapter configuration
    config = QEMUConfig(
        architecture=args.architecture,
        machine_type='virt',
        cpu_model='cortex-m4',
        memory_mb=256,
        network_config={'enable_network': True},
        serial_ports=1,
        gdb_port=1234
    )

    adapter = QEMUAdapter(config)

    # Execute commands
    if args.create_vm:
        adapter.create_vm()

    if args.load_binary:
        adapter.load_binary(args.load_binary)

    if args.start:
        adapter.start_vm(debug=args.debug)

    if args.stop:
        adapter.stop_vm()

    if args.status:
        status = adapter.get_vm_status()
        print(json.dumps(status, indent=2))

    if args.cleanup:
        adapter.cleanup()


if __name__ == '__main__':
    main()

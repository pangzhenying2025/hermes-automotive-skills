"""
OPC UA (Open Platform Communications Unified Architecture) Adapter.

Supports:
- opcua-asyncio (Python)
- Read/write variables
- Call methods
- Subscribe to data changes
- Security policies
"""

import asyncio
import json
import logging
from typing import Dict, Any, Optional, Callable, List
from dataclasses import dataclass

try:
    from asyncua import Client, Server, ua
    from asyncua.common.node import Node
    OPCUA_AVAILABLE = True
except ImportError:
    OPCUA_AVAILABLE = False

from ..base_adapter import OpensourceToolAdapter


@dataclass
class OPCUAConfig:
    """OPC UA connection configuration."""
    endpoint: str = "opc.tcp://localhost:4840"
    security_policy: str = "None"  # None, Basic256Sha256
    username: Optional[str] = None
    password: Optional[str] = None


class OPCUAAdapter(OpensourceToolAdapter):
    """
    Adapter for OPC UA protocol (industrial automation).

    Features:
    - Read/write OPC UA variables
    - Call methods
    - Subscribe to data changes
    - Browse address space
    - Historical data access

    Example:
        >>> config = OPCUAConfig(endpoint='opc.tcp://plc.factory.local:4840')
        >>> adapter = OPCUAAdapter(config)
        >>> asyncio.run(adapter.read_variable('ns=2;s=Station01.Status'))
    """

    def __init__(self, config: Optional[OPCUAConfig] = None):
        """Initialize OPC UA adapter."""
        super().__init__(name='opcua')
        self.config = config or OPCUAConfig()
        self.client = None

    def _detect(self) -> bool:
        """Detect if asyncua is available."""
        return OPCUA_AVAILABLE

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute OPC UA command.

        Commands:
        - connect: Connect to server
        - disconnect: Disconnect from server
        - read: Read variable
        - write: Write variable
        - call_method: Call OPC UA method
        - subscribe: Subscribe to data changes
        - browse: Browse address space
        """
        if command == 'connect':
            return self._execute_connect(parameters)
        elif command == 'disconnect':
            return self._execute_disconnect(parameters)
        elif command == 'read':
            return self._execute_read(parameters)
        elif command == 'write':
            return self._execute_write(parameters)
        elif command == 'call_method':
            return self._execute_call_method(parameters)
        elif command == 'browse':
            return self._execute_browse(parameters)
        else:
            return {'success': False, 'error': f'Unknown command: {command}'}

    def _execute_connect(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Connect to OPC UA server."""
        try:
            result = asyncio.run(self.connect())
            return {'success': True, 'connected': result}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_disconnect(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Disconnect from OPC UA server."""
        try:
            asyncio.run(self.disconnect())
            return {'success': True}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_read(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Read variable."""
        node_id = params.get('node_id')
        try:
            value = asyncio.run(self.read_variable(node_id))
            return {'success': True, 'value': value}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_write(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Write variable."""
        node_id = params.get('node_id')
        value = params.get('value')
        try:
            asyncio.run(self.write_variable(node_id, value))
            return {'success': True}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_call_method(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Call OPC UA method."""
        object_id = params.get('object_id')
        method_id = params.get('method_id')
        args = params.get('args', [])
        try:
            result = asyncio.run(self.call_method(object_id, method_id, args))
            return {'success': True, 'result': result}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_browse(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Browse address space."""
        node_id = params.get('node_id', 'i=84')  # Root Objects folder
        try:
            children = asyncio.run(self.browse_node(node_id))
            return {'success': True, 'children': children}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    async def connect(self) -> bool:
        """
        Connect to OPC UA server.

        Returns:
            True if connected
        """
        if not OPCUA_AVAILABLE:
            raise RuntimeError("asyncua not installed")

        self.client = Client(self.config.endpoint)

        # Set security
        if self.config.username and self.config.password:
            self.client.set_user(self.config.username)
            self.client.set_password(self.config.password)

        await self.client.connect()
        self.logger.info(f"Connected to OPC UA server: {self.config.endpoint}")
        return True

    async def disconnect(self):
        """Disconnect from OPC UA server."""
        if self.client:
            await self.client.disconnect()
            self.client = None
            self.logger.info("Disconnected from OPC UA server")

    async def read_variable(self, node_id: str) -> Any:
        """
        Read OPC UA variable.

        Args:
            node_id: Node ID (e.g., 'ns=2;s=Station01.Status')

        Returns:
            Variable value

        Example:
            >>> value = await adapter.read_variable('ns=2;s=Station01.CycleTime')
            >>> print(f"Cycle time: {value}s")
        """
        if not self.client:
            raise RuntimeError("Not connected to OPC UA server")

        node = self.client.get_node(node_id)
        value = await node.read_value()
        return value

    async def write_variable(self, node_id: str, value: Any):
        """
        Write OPC UA variable.

        Args:
            node_id: Node ID
            value: Value to write

        Example:
            >>> await adapter.write_variable('ns=2;s=Station01.Status', 'Running')
        """
        if not self.client:
            raise RuntimeError("Not connected to OPC UA server")

        node = self.client.get_node(node_id)
        await node.write_value(value)
        self.logger.debug(f"Wrote {value} to {node_id}")

    async def call_method(
        self,
        object_id: str,
        method_id: str,
        args: List[Any]
    ) -> List[Any]:
        """
        Call OPC UA method.

        Args:
            object_id: Object node ID
            method_id: Method node ID
            args: Method arguments

        Returns:
            Method result

        Example:
            >>> result = await adapter.call_method(
            ...     'ns=2;s=Station01',
            ...     'ns=2;s=Station01.StartCycle',
            ...     []
            ... )
        """
        if not self.client:
            raise RuntimeError("Not connected to OPC UA server")

        object_node = self.client.get_node(object_id)
        method_node = self.client.get_node(method_id)

        result = await object_node.call_method(method_node, *args)
        return result

    async def subscribe_data_change(
        self,
        node_id: str,
        callback: Callable[[Any], None],
        interval_ms: int = 1000
    ):
        """
        Subscribe to variable changes.

        Args:
            node_id: Node ID to monitor
            callback: Called on value change
            interval_ms: Sampling interval

        Example:
            >>> def on_status_change(value):
            ...     print(f"Status changed: {value}")
            >>> await adapter.subscribe_data_change(
            ...     'ns=2;s=Station01.Status',
            ...     on_status_change
            ... )
        """
        if not self.client:
            raise RuntimeError("Not connected to OPC UA server")

        class DataChangeHandler:
            def datachange_notification(self, node, val, data):
                callback(val)

        handler = DataChangeHandler()
        subscription = await self.client.create_subscription(interval_ms, handler)
        node = self.client.get_node(node_id)
        await subscription.subscribe_data_change(node)

        self.logger.info(f"Subscribed to {node_id}")

    async def browse_node(self, node_id: str) -> List[Dict[str, str]]:
        """
        Browse child nodes.

        Args:
            node_id: Parent node ID

        Returns:
            List of child nodes

        Example:
            >>> children = await adapter.browse_node('i=84')  # Objects folder
            >>> for child in children:
            ...     print(f"{child['name']}: {child['node_id']}")
        """
        if not self.client:
            raise RuntimeError("Not connected to OPC UA server")

        node = self.client.get_node(node_id)
        children = await node.get_children()

        result = []
        for child in children:
            browse_name = await child.read_browse_name()
            result.append({
                'name': browse_name.Name,
                'node_id': child.nodeid.to_string()
            })

        return result


# Example: Factory PLC integration
def factory_plc_example():
    """Read battery assembly line status."""

    async def run():
        config = OPCUAConfig(endpoint='opc.tcp://localhost:4840')
        adapter = OPCUAAdapter(config)

        try:
            await adapter.connect()

            # Read station status
            status = await adapter.read_variable('ns=2;s=Station01.Status')
            print(f"Station status: {status}")

            # Read cycle time
            cycle_time = await adapter.read_variable('ns=2;s=Station01.CycleTime')
            print(f"Cycle time: {cycle_time}s")

            # Write battery ID
            await adapter.write_variable('ns=2;s=Station01.BatteryID', 'BAT12345')

            # Call start cycle method
            result = await adapter.call_method(
                'ns=2;s=Station01',
                'ns=2;s=Station01.StartCycle',
                []
            )
            print(f"Start cycle result: {result}")

            # Browse objects
            children = await adapter.browse_node('i=84')
            print(f"Objects: {[c['name'] for c in children]}")

        finally:
            await adapter.disconnect()

    asyncio.run(run())


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    print("OPC UA Adapter - Manufacturing Integration")
    print("=" * 50)

    adapter = OPCUAAdapter()
    print(f"OPC UA Available: {adapter.is_available}")
    print(f"Info: {adapter.get_info()}")

    if adapter.is_available:
        print("\nExample requires OPC UA server running on localhost:4840")
        print("Install: pip install asyncua")
        # factory_plc_example()

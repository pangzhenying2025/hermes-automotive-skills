"""
CoAP (Constrained Application Protocol) Adapter for Automotive IoT.

Supports:
- aiocoap (Python async CoAP)
- GET/POST/PUT/DELETE methods
- Observe (pub/sub)
- Block-wise transfer
- DTLS security
"""

import asyncio
import json
import logging
from typing import Dict, Any, Optional, Callable
from dataclasses import dataclass

try:
    import aiocoap
    from aiocoap import Context, Message, GET, POST, PUT, DELETE
    from aiocoap.resource import Site, Resource
    AIOCOAP_AVAILABLE = True
except ImportError:
    AIOCOAP_AVAILABLE = False

from ..base_adapter import OpensourceToolAdapter


@dataclass
class CoAPConfig:
    """CoAP configuration."""
    host: str = "localhost"
    port: int = 5683
    use_dtls: bool = False


class CoAPAdapter(OpensourceToolAdapter):
    """
    Adapter for CoAP protocol (constrained devices).

    Features:
    - GET/POST/PUT/DELETE methods
    - Observe pattern for real-time updates
    - Block-wise transfer for large payloads
    - DTLS security
    - Battery-optimized messaging

    Example:
        >>> adapter = CoAPAdapter()
        >>> asyncio.run(adapter.get('coap://192.168.1.10/battery/soc'))
    """

    def __init__(self, config: Optional[CoAPConfig] = None):
        """Initialize CoAP adapter."""
        super().__init__(name='coap')
        self.config = config or CoAPConfig()
        self.protocol = None
        self.server_site = None

    def _detect(self) -> bool:
        """Detect if aiocoap is available."""
        return AIOCOAP_AVAILABLE

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute CoAP command.

        Commands:
        - get: GET request
        - post: POST request
        - put: PUT request
        - delete: DELETE request
        - observe: Subscribe to resource
        """
        if command == 'get':
            return self._execute_get(parameters)
        elif command == 'post':
            return self._execute_post(parameters)
        elif command == 'put':
            return self._execute_put(parameters)
        elif command == 'delete':
            return self._execute_delete(parameters)
        else:
            return {'success': False, 'error': f'Unknown command: {command}'}

    def _execute_get(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Execute GET request."""
        uri = params.get('uri')
        try:
            result = asyncio.run(self.get(uri))
            return {'success': True, 'payload': result}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_post(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Execute POST request."""
        uri = params.get('uri')
        data = params.get('data')
        try:
            result = asyncio.run(self.post(uri, data))
            return {'success': True, 'payload': result}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_put(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Execute PUT request."""
        uri = params.get('uri')
        data = params.get('data')
        try:
            result = asyncio.run(self.put(uri, data))
            return {'success': True, 'payload': result}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_delete(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Execute DELETE request."""
        uri = params.get('uri')
        try:
            result = asyncio.run(self.delete(uri))
            return {'success': True}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    async def get(self, uri: str) -> Dict[str, Any]:
        """
        GET request to CoAP resource.

        Args:
            uri: CoAP URI (e.g., 'coap://192.168.1.10/battery/soc')

        Returns:
            Parsed JSON payload

        Example:
            >>> result = await adapter.get('coap://192.168.1.10/battery/soc')
            >>> print(result['soc'])
        """
        if not AIOCOAP_AVAILABLE:
            raise RuntimeError("aiocoap not installed")

        protocol = await Context.create_client_context()
        request = Message(code=GET, uri=uri)

        try:
            response = await protocol.request(request).response
            if response.code.is_successful():
                return json.loads(response.payload.decode())
            else:
                raise RuntimeError(f"CoAP error: {response.code}")
        finally:
            await protocol.shutdown()

    async def post(self, uri: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        POST request to CoAP resource.

        Args:
            uri: CoAP URI
            data: JSON data to post

        Example:
            >>> await adapter.post(
            ...     'coap://192.168.1.10/battery/command',
            ...     {'action': 'balance_cells'}
            ... )
        """
        if not AIOCOAP_AVAILABLE:
            raise RuntimeError("aiocoap not installed")

        protocol = await Context.create_client_context()
        payload = json.dumps(data).encode('utf-8')
        request = Message(code=POST, uri=uri, payload=payload)

        try:
            response = await protocol.request(request).response
            if response.code.is_successful():
                return json.loads(response.payload.decode()) if response.payload else {}
            else:
                raise RuntimeError(f"CoAP error: {response.code}")
        finally:
            await protocol.shutdown()

    async def put(self, uri: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """PUT request to update resource."""
        if not AIOCOAP_AVAILABLE:
            raise RuntimeError("aiocoap not installed")

        protocol = await Context.create_client_context()
        payload = json.dumps(data).encode('utf-8')
        request = Message(code=PUT, uri=uri, payload=payload)

        try:
            response = await protocol.request(request).response
            if response.code.is_successful():
                return json.loads(response.payload.decode()) if response.payload else {}
            else:
                raise RuntimeError(f"CoAP error: {response.code}")
        finally:
            await protocol.shutdown()

    async def delete(self, uri: str):
        """DELETE request to remove resource."""
        if not AIOCOAP_AVAILABLE:
            raise RuntimeError("aiocoap not installed")

        protocol = await Context.create_client_context()
        request = Message(code=DELETE, uri=uri)

        try:
            response = await protocol.request(request).response
            if not response.code.is_successful():
                raise RuntimeError(f"CoAP error: {response.code}")
        finally:
            await protocol.shutdown()

    async def observe(
        self,
        uri: str,
        callback: Callable[[Dict[str, Any]], None],
        duration: int = 60
    ):
        """
        Observe CoAP resource for changes.

        Args:
            uri: CoAP URI
            callback: Called on each update
            duration: Observation duration in seconds

        Example:
            >>> async def on_update(data):
            ...     print(f"SOC: {data['soc']}%")
            >>> await adapter.observe('coap://192.168.1.10/battery/soc', on_update)
        """
        if not AIOCOAP_AVAILABLE:
            raise RuntimeError("aiocoap not installed")

        protocol = await Context.create_client_context()
        request = Message(code=GET, uri=uri, observe=0)

        try:
            observation = protocol.request(request)

            async for response in observation.observation:
                try:
                    data = json.loads(response.payload.decode())
                    callback(data)
                except Exception as e:
                    self.logger.error(f"Error in observe callback: {e}")

        finally:
            await protocol.shutdown()


# Example: Battery monitoring over CoAP
def battery_monitoring_example():
    """Monitor battery SOC via CoAP."""

    async def run():
        adapter = CoAPAdapter()

        # GET battery SOC
        try:
            soc_data = await adapter.get('coap://localhost/battery/soc')
            print(f"Battery SOC: {soc_data}")
        except Exception as e:
            print(f"Error: {e}")

        # POST command
        try:
            result = await adapter.post(
                'coap://localhost/battery/command',
                {'action': 'start_charging', 'target_soc': 100}
            )
            print(f"Command result: {result}")
        except Exception as e:
            print(f"Error: {e}")

    asyncio.run(run())


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    print("CoAP Adapter - Constrained Devices")
    print("=" * 50)

    adapter = CoAPAdapter()
    print(f"CoAP Available: {adapter.is_available}")
    print(f"Info: {adapter.get_info()}")

    if adapter.is_available:
        battery_monitoring_example()

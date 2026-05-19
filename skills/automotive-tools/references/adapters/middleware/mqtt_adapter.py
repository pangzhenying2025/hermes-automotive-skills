"""
MQTT (Message Queuing Telemetry Transport) Adapter for Automotive IoT.

Supports:
- AWS IoT Core
- Azure IoT Hub
- Eclipse Mosquitto
- TLS with client certificates
"""

import json
import logging
import ssl
import time
from pathlib import Path
from typing import Dict, Any, Optional, Callable
from dataclasses import dataclass

try:
    import paho.mqtt.client as mqtt
    MQTT_AVAILABLE = True
except ImportError:
    MQTT_AVAILABLE = False

from ..base_adapter import OpensourceToolAdapter


@dataclass
class MQTTConfig:
    """MQTT connection configuration."""
    host: str = "localhost"
    port: int = 1883
    use_tls: bool = False
    ca_certs: Optional[str] = None
    certfile: Optional[str] = None
    keyfile: Optional[str] = None
    username: Optional[str] = None
    password: Optional[str] = None
    keepalive: int = 60
    clean_session: bool = True


class MQTTAdapter(OpensourceToolAdapter):
    """
    Adapter for MQTT messaging protocol.

    Features:
    - Publish/subscribe with QoS 0/1/2
    - TLS encryption with client certificates
    - Last Will Testament (LWT)
    - Retained messages
    - AWS IoT Core and Azure IoT Hub support

    Example:
        >>> config = MQTTConfig(host='mqtt.example.com', port=8883, use_tls=True)
        >>> adapter = MQTTAdapter('vehicle_12345', config)
        >>> adapter.publish('vehicle/telemetry/battery', {'soc': 85}, qos=1)
    """

    def __init__(
        self,
        client_id: str,
        config: Optional[MQTTConfig] = None,
        protocol: int = mqtt.MQTTv5
    ):
        """
        Initialize MQTT adapter.

        Args:
            client_id: Unique client identifier
            config: MQTT connection configuration
            protocol: MQTT protocol version (MQTTv311 or MQTTv5)
        """
        super().__init__(name='mqtt')
        self.client_id = client_id
        self.config = config or MQTTConfig()
        self.protocol = protocol

        self.client = None
        self.connected = False
        self.subscriptions = {}

        if self.is_available:
            self._init_client()

    def _detect(self) -> bool:
        """Detect if paho-mqtt is available."""
        return MQTT_AVAILABLE

    def _init_client(self):
        """Initialize MQTT client."""
        if not MQTT_AVAILABLE:
            return

        self.client = mqtt.Client(
            client_id=self.client_id,
            protocol=self.protocol,
            transport="tcp"
        )

        # Set callbacks
        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect
        self.client.on_message = self._on_message

        # Configure TLS if enabled
        if self.config.use_tls:
            self.client.tls_set(
                ca_certs=self.config.ca_certs,
                certfile=self.config.certfile,
                keyfile=self.config.keyfile,
                cert_reqs=ssl.CERT_REQUIRED,
                tls_version=ssl.PROTOCOL_TLSv1_2
            )

        # Set username/password if provided
        if self.config.username and self.config.password:
            self.client.username_pw_set(
                self.config.username,
                self.config.password
            )

    def _on_connect(self, client, userdata, flags, rc, properties=None):
        """Callback on successful connection."""
        if rc == 0:
            self.connected = True
            self.logger.info(f"Connected to MQTT broker: {self.config.host}")

            # Resubscribe to all topics
            for topic, qos in self.subscriptions.items():
                client.subscribe(topic, qos)
        else:
            self.logger.error(f"Connection failed: {mqtt.connack_string(rc)}")

    def _on_disconnect(self, client, userdata, rc):
        """Callback on disconnect."""
        self.connected = False
        self.logger.warning(f"Disconnected from MQTT broker (rc={rc})")

    def _on_message(self, client, userdata, msg):
        """Callback when message received."""
        try:
            payload = json.loads(msg.payload.decode())
            self.logger.debug(f"Received on {msg.topic}: {payload}")
        except Exception as e:
            self.logger.error(f"Error processing message: {e}")

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute MQTT command.

        Commands:
        - connect: Connect to broker
        - disconnect: Disconnect from broker
        - publish: Publish message
        - subscribe: Subscribe to topic
        """
        if command == 'connect':
            return self._execute_connect(parameters)
        elif command == 'disconnect':
            return self._execute_disconnect(parameters)
        elif command == 'publish':
            return self._execute_publish(parameters)
        elif command == 'subscribe':
            return self._execute_subscribe(parameters)
        else:
            return {'success': False, 'error': f'Unknown command: {command}'}

    def _execute_connect(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Connect to MQTT broker."""
        try:
            self.connect()
            return {'success': True, 'connected': self.connected}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_disconnect(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Disconnect from MQTT broker."""
        try:
            self.disconnect()
            return {'success': True}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_publish(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Publish message to topic."""
        topic = params.get('topic')
        data = params.get('data')
        qos = params.get('qos', 0)
        retain = params.get('retain', False)

        try:
            result = self.publish(topic, data, qos, retain)
            return {
                'success': True,
                'topic': topic,
                'qos': qos,
                'message_id': result.mid
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_subscribe(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Subscribe to topic."""
        topic = params.get('topic')
        qos = params.get('qos', 0)

        try:
            self.subscribe(topic, qos)
            return {'success': True, 'topic': topic, 'qos': qos}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def connect(self):
        """Connect to MQTT broker."""
        if not self.client:
            raise RuntimeError("MQTT client not initialized")

        self.client.connect(
            self.config.host,
            self.config.port,
            keepalive=self.config.keepalive
        )
        self.client.loop_start()

        # Wait for connection
        timeout = 10
        start = time.time()
        while not self.connected and (time.time() - start) < timeout:
            time.sleep(0.1)

        if not self.connected:
            raise RuntimeError("Connection timeout")

    def disconnect(self):
        """Disconnect from MQTT broker."""
        if self.client:
            self.client.loop_stop()
            self.client.disconnect()
            self.connected = False

    def publish(
        self,
        topic: str,
        data: Dict[str, Any],
        qos: int = 0,
        retain: bool = False
    ) -> mqtt.MQTTMessageInfo:
        """
        Publish message to topic.

        Args:
            topic: Topic name (e.g., 'vehicle/vin123/telemetry/battery')
            data: Data dictionary
            qos: QoS level (0, 1, or 2)
            retain: Retain message on broker

        Returns:
            MQTTMessageInfo with result

        Example:
            >>> adapter.publish(
            ...     'vehicle/ABC123/telemetry/battery',
            ...     {'soc': 85, 'voltage': 400.5},
            ...     qos=1
            ... )
        """
        if not self.connected:
            raise RuntimeError("Not connected to MQTT broker")

        payload = json.dumps(data)
        result = self.client.publish(topic, payload, qos=qos, retain=retain)

        if result.rc != mqtt.MQTT_ERR_SUCCESS:
            raise RuntimeError(f"Publish failed: {mqtt.error_string(result.rc)}")

        return result

    def subscribe(
        self,
        topic: str,
        qos: int = 0,
        callback: Optional[Callable] = None
    ):
        """
        Subscribe to topic.

        Args:
            topic: Topic pattern (e.g., 'vehicle/+/cmd/#')
            qos: QoS level
            callback: Optional callback function

        Example:
            >>> def on_command(data):
            ...     print(f"Command: {data}")
            >>> adapter.subscribe('vehicle/+/cmd/#', qos=1, callback=on_command)
        """
        if not self.connected:
            raise RuntimeError("Not connected to MQTT broker")

        result, mid = self.client.subscribe(topic, qos=qos)
        if result != mqtt.MQTT_ERR_SUCCESS:
            raise RuntimeError(f"Subscribe failed: {mqtt.error_string(result)}")

        self.subscriptions[topic] = qos
        self.logger.info(f"Subscribed to {topic} (QoS {qos})")

    def set_will(self, topic: str, payload: Dict[str, Any], qos: int = 1):
        """
        Set Last Will Testament.

        Args:
            topic: Will topic
            payload: Will message
            qos: QoS level
        """
        if self.client:
            self.client.will_set(
                topic,
                json.dumps(payload),
                qos=qos,
                retain=True
            )

    def loop_forever(self):
        """Block and process MQTT messages."""
        if self.client:
            self.client.loop_forever()


# Example usage for vehicle telemetry
def vehicle_telemetry_example():
    """
    Example: Vehicle telemetry to cloud.

    Publishes battery SOC, voltage, current @ 1Hz.
    """
    config = MQTTConfig(
        host='localhost',
        port=1883,
        use_tls=False
    )

    vin = 'ABC123XYZ'
    adapter = MQTTAdapter(client_id=f'vehicle_{vin}', config=config)

    # Set LWT
    adapter.set_will(
        f'vehicle/{vin}/status/online',
        {'online': False, 'timestamp': None}
    )

    # Connect
    adapter.connect()

    # Publish online status
    adapter.publish(
        f'vehicle/{vin}/status/online',
        {'online': True, 'timestamp': time.time()},
        qos=1,
        retain=True
    )

    # Publish telemetry
    for i in range(10):
        battery_data = {
            'vin': vin,
            'timestamp': time.time(),
            'soc_percent': 85 - i,
            'voltage_v': 400.5,
            'current_a': -50.0,
            'temperature_c': 25.0
        }
        adapter.publish(
            f'vehicle/{vin}/telemetry/battery',
            battery_data,
            qos=0
        )
        time.sleep(1)

    adapter.disconnect()


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)

    print("MQTT Adapter - Automotive IoT")
    print("=" * 50)

    adapter = MQTTAdapter(client_id='test_client')
    print(f"MQTT Available: {adapter.is_available}")
    print(f"Info: {adapter.get_info()}")

    if adapter.is_available:
        vehicle_telemetry_example()

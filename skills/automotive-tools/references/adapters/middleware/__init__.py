"""
Automotive Middleware Adapters.

Provides production-ready adapters for automotive middleware protocols:
- DDS (Data Distribution Service)
- MQTT (Message Queuing Telemetry Transport)
- AMQP (Advanced Message Queuing Protocol)
- ROS 2 DDS
- CoAP (Constrained Application Protocol)
- OPC UA (Open Platform Communications Unified Architecture)
"""

from .dds_adapter import DDSAdapter
from .mqtt_adapter import MQTTAdapter
from .amqp_adapter import AMQPAdapter
from .ros2_adapter import ROS2DDSAdapter
from .coap_adapter import CoAPAdapter
from .opcua_adapter import OPCUAAdapter

__all__ = [
    'DDSAdapter',
    'MQTTAdapter',
    'AMQPAdapter',
    'ROS2DDSAdapter',
    'CoAPAdapter',
    'OPCUAAdapter'
]

__version__ = '1.0.0'

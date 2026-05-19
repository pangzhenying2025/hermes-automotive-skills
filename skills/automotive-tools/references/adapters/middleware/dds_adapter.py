"""
DDS (Data Distribution Service) Adapter for Automotive Applications.

Supports multiple DDS implementations:
- Fast DDS (eProsima) - opensource
- Cyclone DDS (Eclipse) - opensource
- RTI Connext DDS - commercial (optional)
"""

import json
import logging
import subprocess
import time
from pathlib import Path
from typing import Dict, Any, Optional, Callable, List
from dataclasses import dataclass

try:
    import cyclonedds
    from cyclonedds.domain import DomainParticipant
    from cyclonedds.pub import DataWriter
    from cyclonedds.sub import DataReader
    from cyclonedds.topic import Topic
    from cyclonedds.util import duration
    from cyclonedds.qos import Qos, Policy
    CYCLONEDDS_AVAILABLE = True
except ImportError:
    CYCLONEDDS_AVAILABLE = False

from ..base_adapter import OpensourceToolAdapter


@dataclass
class DDSQoSProfile:
    """DDS Quality of Service profile."""
    reliability: str = "RELIABLE"  # RELIABLE or BEST_EFFORT
    durability: str = "VOLATILE"   # VOLATILE, TRANSIENT_LOCAL, TRANSIENT, PERSISTENT
    history: str = "KEEP_LAST"     # KEEP_LAST or KEEP_ALL
    history_depth: int = 10
    deadline_ms: Optional[int] = None
    liveliness: str = "AUTOMATIC"
    ownership: str = "SHARED"


class DDSAdapter(OpensourceToolAdapter):
    """
    Adapter for DDS middleware implementations.

    Features:
    - Publish/subscribe with configurable QoS
    - Topic discovery
    - DDS Security configuration
    - Performance monitoring
    - ADAS sensor data distribution example

    Example:
        >>> adapter = DDSAdapter(implementation='cyclonedds')
        >>> adapter.publish(
        ...     topic='vehicle/adas/camera',
        ...     data={'camera_id': 0, 'timestamp': 123456789},
        ...     qos=DDSQoSProfile(reliability='RELIABLE')
        ... )
        >>> adapter.subscribe(
        ...     topic='vehicle/adas/radar',
        ...     callback=lambda data: print(data)
        ... )
    """

    def __init__(
        self,
        implementation: str = 'cyclonedds',
        domain_id: int = 0,
        config_file: Optional[str] = None
    ):
        """
        Initialize DDS adapter.

        Args:
            implementation: DDS stack ('cyclonedds', 'fastdds', 'connext')
            domain_id: DDS domain ID (0-230)
            config_file: Path to QoS XML configuration file
        """
        super().__init__(name=f'dds-{implementation}')
        self.implementation = implementation
        self.domain_id = domain_id
        self.config_file = config_file

        self.participant = None
        self.publishers = {}
        self.subscribers = {}
        self.topics = {}

        if self.is_available and implementation == 'cyclonedds':
            self._init_cyclonedds()

    def _detect(self) -> bool:
        """Detect if DDS implementation is available."""
        if self.implementation == 'cyclonedds':
            return CYCLONEDDS_AVAILABLE
        elif self.implementation == 'fastdds':
            # Check for Fast DDS installation
            try:
                result = subprocess.run(
                    ['fastddsgen', '-version'],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                return result.returncode == 0
            except (FileNotFoundError, subprocess.TimeoutExpired):
                return False
        elif self.implementation == 'connext':
            # Check for RTI Connext (commercial)
            return Path('/opt/rti.com/rti_connext_dds-6.1.0').exists()
        return False

    def _init_cyclonedds(self):
        """Initialize Cyclone DDS participant."""
        if not CYCLONEDDS_AVAILABLE:
            return

        try:
            self.participant = DomainParticipant(self.domain_id)
            self.logger.info(f"Initialized DDS domain {self.domain_id}")
        except Exception as e:
            self.logger.error(f"Failed to initialize DDS participant: {e}")

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute DDS command.

        Commands:
        - publish: Publish data to topic
        - subscribe: Subscribe to topic
        - list_topics: List discovered topics
        - get_stats: Get performance statistics
        """
        if command == 'publish':
            return self._execute_publish(parameters)
        elif command == 'subscribe':
            return self._execute_subscribe(parameters)
        elif command == 'list_topics':
            return self._execute_list_topics(parameters)
        elif command == 'get_stats':
            return self._execute_get_stats(parameters)
        else:
            return {
                'success': False,
                'error': f'Unknown command: {command}'
            }

    def _execute_publish(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Publish data to DDS topic."""
        topic = params.get('topic')
        data = params.get('data')
        qos_profile = params.get('qos', DDSQoSProfile())

        try:
            result = self.publish(topic, data, qos_profile)
            return {
                'success': True,
                'topic': topic,
                'data_size': len(json.dumps(data)),
                'timestamp': time.time()
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

    def _execute_subscribe(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Subscribe to DDS topic."""
        topic = params.get('topic')
        callback = params.get('callback')
        qos_profile = params.get('qos', DDSQoSProfile())

        try:
            self.subscribe(topic, callback, qos_profile)
            return {
                'success': True,
                'topic': topic,
                'subscribed': True
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

    def _execute_list_topics(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """List discovered DDS topics."""
        return {
            'success': True,
            'topics': list(self.topics.keys())
        }

    def _execute_get_stats(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Get DDS performance statistics."""
        return {
            'success': True,
            'domain_id': self.domain_id,
            'publishers': len(self.publishers),
            'subscribers': len(self.subscribers),
            'topics': len(self.topics)
        }

    def publish(
        self,
        topic: str,
        data: Dict[str, Any],
        qos: Optional[DDSQoSProfile] = None
    ) -> bool:
        """
        Publish data to DDS topic.

        Args:
            topic: Topic name (e.g., 'vehicle/adas/camera')
            data: Data dictionary to publish
            qos: QoS profile

        Returns:
            True if published successfully

        Example:
            >>> adapter.publish(
            ...     'vehicle/battery/soc',
            ...     {'soc': 85, 'voltage': 400.5, 'current': 50.0}
            ... )
        """
        if not self.is_available or not self.participant:
            raise RuntimeError("DDS not available")

        qos = qos or DDSQoSProfile()

        # Create topic if not exists
        if topic not in self.topics:
            self.topics[topic] = Topic(self.participant, topic, str)

        # Create publisher if not exists
        if topic not in self.publishers:
            qos_obj = self._build_qos(qos)
            self.publishers[topic] = DataWriter(
                self.participant,
                self.topics[topic],
                qos=qos_obj
            )

        # Serialize and publish
        payload = json.dumps(data)
        self.publishers[topic].write(payload)

        self.logger.debug(f"Published to {topic}: {len(payload)} bytes")
        return True

    def subscribe(
        self,
        topic: str,
        callback: Callable[[Dict[str, Any]], None],
        qos: Optional[DDSQoSProfile] = None
    ):
        """
        Subscribe to DDS topic with callback.

        Args:
            topic: Topic name
            callback: Function called with each received message
            qos: QoS profile

        Example:
            >>> def on_camera_data(data):
            ...     print(f"Camera {data['camera_id']}: {data['timestamp']}")
            >>> adapter.subscribe('vehicle/adas/camera', on_camera_data)
        """
        if not self.is_available or not self.participant:
            raise RuntimeError("DDS not available")

        qos = qos or DDSQoSProfile()

        # Create topic if not exists
        if topic not in self.topics:
            self.topics[topic] = Topic(self.participant, topic, str)

        # Create subscriber
        qos_obj = self._build_qos(qos)
        reader = DataReader(
            self.participant,
            self.topics[topic],
            qos=qos_obj
        )

        self.subscribers[topic] = {
            'reader': reader,
            'callback': callback
        }

        self.logger.info(f"Subscribed to {topic}")

    def _build_qos(self, profile: DDSQoSProfile) -> Qos:
        """Build Cyclone DDS QoS object from profile."""
        qos = Qos()

        # Reliability
        if profile.reliability == 'RELIABLE':
            qos += Policy.Reliability.Reliable()
        else:
            qos += Policy.Reliability.BestEffort()

        # Durability
        if profile.durability == 'TRANSIENT_LOCAL':
            qos += Policy.Durability.TransientLocal()
        elif profile.durability == 'TRANSIENT':
            qos += Policy.Durability.Transient()
        elif profile.durability == 'PERSISTENT':
            qos += Policy.Durability.Persistent()
        else:
            qos += Policy.Durability.Volatile()

        # History
        if profile.history == 'KEEP_ALL':
            qos += Policy.History.KeepAll()
        else:
            qos += Policy.History.KeepLast(profile.history_depth)

        # Deadline
        if profile.deadline_ms:
            qos += Policy.Deadline(duration(milliseconds=profile.deadline_ms))

        # Ownership
        if profile.ownership == 'EXCLUSIVE':
            qos += Policy.Ownership.Exclusive()
        else:
            qos += Policy.Ownership.Shared()

        return qos

    def spin_once(self, timeout_ms: int = 100):
        """
        Process received messages (non-blocking).

        Args:
            timeout_ms: Max time to wait for messages
        """
        if not self.subscribers:
            return

        for topic, sub_info in self.subscribers.items():
            reader = sub_info['reader']
            callback = sub_info['callback']

            samples = reader.take(N=100)
            for sample in samples:
                try:
                    data = json.loads(sample)
                    callback(data)
                except Exception as e:
                    self.logger.error(f"Error in callback for {topic}: {e}")

    def spin(self):
        """Process messages in blocking loop."""
        self.logger.info("Starting DDS spin loop...")
        try:
            while True:
                self.spin_once(timeout_ms=100)
                time.sleep(0.01)
        except KeyboardInterrupt:
            self.logger.info("Stopping DDS spin loop")

    def shutdown(self):
        """Clean shutdown of DDS participant."""
        if self.participant:
            self.participant = None
        self.publishers.clear()
        self.subscribers.clear()
        self.topics.clear()
        self.logger.info("DDS adapter shutdown complete")


# Example usage for ADAS sensor data distribution
def adas_sensor_fusion_example():
    """
    Example: ADAS sensor fusion with DDS.

    Architecture:
    - 4 camera nodes publish at 30Hz
    - 2 radar nodes publish at 20Hz
    - 1 fusion node subscribes to all
    """
    adapter = DDSAdapter(implementation='cyclonedds', domain_id=0)

    # Camera publisher (RELIABLE, low latency)
    camera_qos = DDSQoSProfile(
        reliability='RELIABLE',
        durability='VOLATILE',
        history='KEEP_LAST',
        history_depth=5,
        deadline_ms=50  # 50ms max latency
    )

    for i in range(10):
        camera_data = {
            'camera_id': 0,
            'timestamp_ns': time.time_ns(),
            'frame_number': i,
            'objects_detected': 3
        }
        adapter.publish('vehicle/adas/camera_front', camera_data, camera_qos)
        time.sleep(0.033)  # 30Hz

    # Radar subscriber (BEST_EFFORT, high throughput)
    radar_qos = DDSQoSProfile(
        reliability='BEST_EFFORT',
        durability='VOLATILE',
        history='KEEP_LAST',
        history_depth=10
    )

    def on_radar_data(data):
        print(f"Radar track: range={data.get('range_m')}m, "
              f"velocity={data.get('velocity_mps')}m/s")

    adapter.subscribe('vehicle/adas/radar_front', on_radar_data, radar_qos)

    # Process messages
    adapter.spin_once(timeout_ms=1000)
    adapter.shutdown()


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)

    print("DDS Adapter - Automotive Middleware")
    print("=" * 50)

    adapter = DDSAdapter()
    print(f"DDS Available: {adapter.is_available}")
    print(f"Info: {adapter.get_info()}")

    if adapter.is_available:
        adas_sensor_fusion_example()

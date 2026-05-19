"""
ROS 2 DDS Adapter for Autonomous Vehicle Development.

Supports:
- Fast DDS (default)
- Cyclone DDS
- Topic publish/subscribe
- Service client/server
- Action client/server
"""

import json
import logging
import subprocess
from typing import Dict, Any, Optional, Callable
from pathlib import Path

from ..base_adapter import OpensourceToolAdapter


class ROS2DDSAdapter(OpensourceToolAdapter):
    """
    Adapter for ROS 2 middleware with DDS backend.

    Features:
    - Publish/subscribe to topics
    - Call services
    - Send action goals
    - Launch files execution
    - ROS bag recording/playback

    Example:
        >>> adapter = ROS2DDSAdapter()
        >>> adapter.publish_topic(
        ...     '/sensor/camera/image_raw',
        ...     'sensor_msgs/Image',
        ...     {'header': {'frame_id': 'camera_front'}}
        ... )
    """

    def __init__(self, rmw_implementation: str = 'rmw_fastrtps_cpp'):
        """
        Initialize ROS 2 adapter.

        Args:
            rmw_implementation: ROS middleware (rmw_fastrtps_cpp, rmw_cyclonedds_cpp)
        """
        super().__init__(name='ros2')
        self.rmw_implementation = rmw_implementation

    def _detect(self) -> bool:
        """Detect if ROS 2 is installed."""
        try:
            result = subprocess.run(
                ['ros2', '--version'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                self.version = result.stdout.strip()
                return True
            return False
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute ROS 2 command.

        Commands:
        - list_topics: List all topics
        - echo_topic: Print messages from topic
        - publish_topic: Publish message to topic
        - call_service: Call ROS 2 service
        - record_bag: Record rosbag
        """
        if command == 'list_topics':
            return self._execute_list_topics(parameters)
        elif command == 'echo_topic':
            return self._execute_echo_topic(parameters)
        elif command == 'publish_topic':
            return self._execute_publish_topic(parameters)
        elif command == 'call_service':
            return self._execute_call_service(parameters)
        elif command == 'record_bag':
            return self._execute_record_bag(parameters)
        else:
            return {'success': False, 'error': f'Unknown command: {command}'}

    def _execute_list_topics(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """List all ROS 2 topics."""
        try:
            result = self.run_subprocess(
                ['ros2', 'topic', 'list'],
                timeout=10
            )
            topics = result.stdout.strip().split('\n')
            return {'success': True, 'topics': topics}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_echo_topic(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Echo messages from topic."""
        topic = params.get('topic')
        count = params.get('count', 1)

        try:
            result = self.run_subprocess(
                ['ros2', 'topic', 'echo', topic, f'--once'],
                timeout=30
            )
            return {'success': True, 'output': result.stdout}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_publish_topic(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Publish message to topic."""
        topic = params.get('topic')
        msg_type = params.get('msg_type')
        data = params.get('data')

        try:
            # Construct YAML message
            yaml_data = json.dumps(data)

            result = self.run_subprocess(
                ['ros2', 'topic', 'pub', '--once', topic, msg_type, yaml_data],
                timeout=10
            )
            return {'success': True, 'output': result.stdout}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_call_service(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Call ROS 2 service."""
        service = params.get('service')
        srv_type = params.get('srv_type')
        request = params.get('request', '{}')

        try:
            result = self.run_subprocess(
                ['ros2', 'service', 'call', service, srv_type, request],
                timeout=30
            )
            return {'success': True, 'response': result.stdout}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_record_bag(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Record rosbag."""
        output_dir = params.get('output_dir', '/tmp')
        topics = params.get('topics', [])
        duration = params.get('duration', 10)

        try:
            cmd = ['ros2', 'bag', 'record', '-o', output_dir]
            cmd.extend(topics)
            cmd.extend(['-d', str(duration)])

            result = self.run_subprocess(cmd, timeout=duration + 10)
            return {'success': True, 'output_dir': output_dir}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def publish_topic(
        self,
        topic: str,
        msg_type: str,
        data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Publish message to ROS 2 topic.

        Args:
            topic: Topic name (e.g., '/sensor/camera/image_raw')
            msg_type: Message type (e.g., 'sensor_msgs/Image')
            data: Message data

        Example:
            >>> adapter.publish_topic(
            ...     '/vehicle/odom',
            ...     'nav_msgs/Odometry',
            ...     {'pose': {'pose': {'position': {'x': 1.0, 'y': 2.0}}}}
            ... )
        """
        return self._execute_publish_topic({
            'topic': topic,
            'msg_type': msg_type,
            'data': data
        })

    def list_topics(self) -> list:
        """List all available topics."""
        result = self._execute_list_topics({})
        return result.get('topics', []) if result['success'] else []

    def call_service(
        self,
        service: str,
        srv_type: str,
        request: str = '{}'
    ) -> Dict[str, Any]:
        """Call ROS 2 service."""
        return self._execute_call_service({
            'service': service,
            'srv_type': srv_type,
            'request': request
        })

    def launch_file(self, package: str, launch_file: str) -> subprocess.Popen:
        """
        Launch ROS 2 launch file.

        Args:
            package: Package name
            launch_file: Launch file name

        Returns:
            Subprocess handle
        """
        cmd = ['ros2', 'launch', package, launch_file]
        return subprocess.Popen(cmd)


# Example: ADAS sensor data
def adas_example():
    """Publish camera and LiDAR data to ROS 2."""
    adapter = ROS2DDSAdapter()

    if not adapter.is_available:
        print("ROS 2 not available")
        return

    # List topics
    topics = adapter.list_topics()
    print(f"Available topics: {topics}")

    # Publish camera data
    camera_msg = {
        'header': {
            'stamp': {'sec': 0, 'nanosec': 0},
            'frame_id': 'camera_front'
        },
        'height': 1080,
        'width': 1920,
        'encoding': 'rgb8'
    }

    adapter.publish_topic(
        '/sensor/camera/image_raw',
        'sensor_msgs/Image',
        camera_msg
    )


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    print("ROS 2 DDS Adapter - Autonomous Driving")
    print("=" * 50)

    adapter = ROS2DDSAdapter()
    print(f"ROS 2 Available: {adapter.is_available}")
    print(f"Info: {adapter.get_info()}")

    if adapter.is_available:
        adas_example()

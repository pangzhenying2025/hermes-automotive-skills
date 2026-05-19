"""
CARLA Simulator Adapter for ADAS HIL/SIL Testing

Provides interface to CARLA autonomous driving simulator for:
- Scenario generation and execution
- Sensor data collection (camera, LiDAR, radar, GPS, IMU)
- Vehicle control and dynamics
- Traffic simulation and NPCs
- Weather and environmental conditions

Supports CARLA 0.9.13+
"""

import numpy as np
import queue
import time
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple, Callable
from enum import Enum

try:
    import carla
    CARLA_AVAILABLE = True
except ImportError:
    CARLA_AVAILABLE = False
    print("Warning: CARLA Python API not available. Install with: pip install carla")


class SensorType(Enum):
    """Supported sensor types"""
    RGB_CAMERA = "sensor.camera.rgb"
    DEPTH_CAMERA = "sensor.camera.depth"
    SEMANTIC_SEGMENTATION = "sensor.camera.semantic_segmentation"
    LIDAR = "sensor.lidar.ray_cast"
    RADAR = "sensor.other.radar"
    GPS = "sensor.other.gnss"
    IMU = "sensor.other.imu"
    COLLISION = "sensor.other.collision"


@dataclass
class VehicleState:
    """Vehicle state representation"""
    timestamp: float
    location: Tuple[float, float, float]  # x, y, z in meters
    rotation: Tuple[float, float, float]  # pitch, yaw, roll in degrees
    velocity: Tuple[float, float, float]  # vx, vy, vz in m/s
    acceleration: Tuple[float, float, float]  # ax, ay, az in m/s²
    angular_velocity: Tuple[float, float, float]  # rad/s

    @property
    def speed_mps(self) -> float:
        """Speed in m/s"""
        return np.linalg.norm(self.velocity)

    @property
    def speed_kmh(self) -> float:
        """Speed in km/h"""
        return self.speed_mps * 3.6


@dataclass
class SensorData:
    """Generic sensor data container"""
    sensor_type: SensorType
    timestamp: float
    frame: int
    data: any  # Sensor-specific data
    transform: Optional[Tuple[float, ...]] = None  # Sensor pose


@dataclass
class ScenarioConfig:
    """Scenario configuration"""
    map_name: str = "Town01"
    weather: str = "ClearNoon"  # ClearNoon, CloudyNoon, WetNoon, HardRainNoon, etc.
    num_vehicles: int = 50
    num_pedestrians: int = 30
    spawn_point_index: int = 0
    seed: int = 42


class CARLAAdapter:
    """
    Main adapter class for CARLA simulator integration
    """

    def __init__(self, host: str = "localhost", port: int = 2000, timeout: float = 10.0):
        """
        Initialize CARLA adapter

        Args:
            host: CARLA server host
            port: CARLA server port
            timeout: Connection timeout in seconds
        """
        if not CARLA_AVAILABLE:
            raise RuntimeError("CARLA Python API not available")

        self.host = host
        self.port = port
        self.timeout = timeout

        # CARLA objects
        self.client: Optional[carla.Client] = None
        self.world: Optional[carla.World] = None
        self.ego_vehicle: Optional[carla.Vehicle] = None
        self.sensors: Dict[str, carla.Sensor] = {}
        self.sensor_queues: Dict[str, queue.Queue] = {}
        self.sensor_callbacks: Dict[str, Callable] = {}

        # NPC actors
        self.npc_vehicles: List[carla.Vehicle] = []
        self.npc_pedestrians: List[carla.Walker] = []

        # State
        self.is_connected = False
        self.is_simulating = False

    def connect(self) -> bool:
        """Connect to CARLA server"""
        try:
            print(f"Connecting to CARLA at {self.host}:{self.port}...")
            self.client = carla.Client(self.host, self.port)
            self.client.set_timeout(self.timeout)

            # Test connection
            version = self.client.get_server_version()
            print(f"Connected to CARLA {version}")

            self.world = self.client.get_world()
            self.is_connected = True
            return True

        except Exception as e:
            print(f"Failed to connect to CARLA: {e}")
            self.is_connected = False
            return False

    def load_scenario(self, config: ScenarioConfig) -> bool:
        """Load and setup scenario"""
        if not self.is_connected:
            print("Not connected to CARLA")
            return False

        try:
            # Load map
            print(f"Loading map: {config.map_name}")
            self.world = self.client.load_world(config.map_name)

            # Set weather
            weather = self._get_weather_preset(config.weather)
            self.world.set_weather(weather)
            print(f"Weather set to: {config.weather}")

            # Spawn ego vehicle
            blueprint_library = self.world.get_blueprint_library()
            vehicle_bp = blueprint_library.filter('vehicle.tesla.model3')[0]

            spawn_points = self.world.get_map().get_spawn_points()
            spawn_point = spawn_points[config.spawn_point_index]

            self.ego_vehicle = self.world.spawn_actor(vehicle_bp, spawn_point)
            print(f"Spawned ego vehicle at {spawn_point.location}")

            # Spawn NPCs
            self._spawn_npcs(config.num_vehicles, config.num_pedestrians, config.seed)

            return True

        except Exception as e:
            print(f"Failed to load scenario: {e}")
            return False

    def attach_sensor(self, sensor_type: SensorType, name: str,
                     transform: Optional[carla.Transform] = None,
                     attributes: Optional[Dict[str, str]] = None,
                     callback: Optional[Callable] = None) -> bool:
        """
        Attach sensor to ego vehicle

        Args:
            sensor_type: Type of sensor to attach
            name: Unique name for the sensor
            transform: Sensor mounting position/orientation
            attributes: Sensor-specific attributes (resolution, FOV, etc.)
            callback: Optional callback function for sensor data
        """
        if not self.ego_vehicle:
            print("No ego vehicle spawned")
            return False

        try:
            blueprint_library = self.world.get_blueprint_library()
            sensor_bp = blueprint_library.find(sensor_type.value)

            # Set attributes
            if attributes:
                for key, value in attributes.items():
                    sensor_bp.set_attribute(key, value)

            # Default transform (on top of vehicle)
            if transform is None:
                transform = carla.Transform(carla.Location(x=0.8, z=1.7))

            # Spawn sensor
            sensor = self.world.spawn_actor(sensor_bp, transform, attach_to=self.ego_vehicle)
            self.sensors[name] = sensor

            # Setup data queue
            sensor_queue = queue.Queue()
            self.sensor_queues[name] = sensor_queue

            # Attach listener
            if callback:
                self.sensor_callbacks[name] = callback
                sensor.listen(lambda data: self._sensor_callback(name, data))
            else:
                sensor.listen(lambda data: sensor_queue.put(data))

            print(f"Attached sensor: {name} ({sensor_type.value})")
            return True

        except Exception as e:
            print(f"Failed to attach sensor {name}: {e}")
            return False

    def get_vehicle_state(self) -> Optional[VehicleState]:
        """Get current ego vehicle state"""
        if not self.ego_vehicle:
            return None

        transform = self.ego_vehicle.get_transform()
        velocity = self.ego_vehicle.get_velocity()
        acceleration = self.ego_vehicle.get_acceleration()
        angular_velocity = self.ego_vehicle.get_angular_velocity()

        return VehicleState(
            timestamp=time.time(),
            location=(transform.location.x, transform.location.y, transform.location.z),
            rotation=(transform.rotation.pitch, transform.rotation.yaw, transform.rotation.roll),
            velocity=(velocity.x, velocity.y, velocity.z),
            acceleration=(acceleration.x, acceleration.y, acceleration.z),
            angular_velocity=(angular_velocity.x, angular_velocity.y, angular_velocity.z)
        )

    def apply_control(self, throttle: float = 0.0, steer: float = 0.0,
                     brake: float = 0.0, hand_brake: bool = False,
                     reverse: bool = False) -> bool:
        """
        Apply control to ego vehicle

        Args:
            throttle: 0.0 to 1.0
            steer: -1.0 to 1.0 (left to right)
            brake: 0.0 to 1.0
            hand_brake: Boolean
            reverse: Boolean
        """
        if not self.ego_vehicle:
            return False

        control = carla.VehicleControl(
            throttle=np.clip(throttle, 0.0, 1.0),
            steer=np.clip(steer, -1.0, 1.0),
            brake=np.clip(brake, 0.0, 1.0),
            hand_brake=hand_brake,
            reverse=reverse
        )

        self.ego_vehicle.apply_control(control)
        return True

    def get_sensor_data(self, sensor_name: str, timeout: float = 1.0) -> Optional[SensorData]:
        """Get latest sensor data (blocking)"""
        if sensor_name not in self.sensor_queues:
            return None

        try:
            data = self.sensor_queues[sensor_name].get(timeout=timeout)
            return self._convert_sensor_data(sensor_name, data)
        except queue.Empty:
            return None

    def tick(self, dt: float = 0.05) -> bool:
        """Advance simulation by one step"""
        if not self.world:
            return False

        settings = self.world.get_settings()
        settings.synchronous_mode = True
        settings.fixed_delta_seconds = dt
        self.world.apply_settings(settings)

        self.world.tick()
        return True

    def cleanup(self):
        """Cleanup and destroy all actors"""
        print("Cleaning up CARLA actors...")

        # Destroy sensors
        for sensor in self.sensors.values():
            sensor.destroy()
        self.sensors.clear()
        self.sensor_queues.clear()

        # Destroy ego vehicle
        if self.ego_vehicle:
            self.ego_vehicle.destroy()
            self.ego_vehicle = None

        # Destroy NPCs
        for vehicle in self.npc_vehicles:
            vehicle.destroy()
        self.npc_vehicles.clear()

        for pedestrian in self.npc_pedestrians:
            pedestrian.destroy()
        self.npc_pedestrians.clear()

        print("Cleanup complete")

    # Private methods

    def _sensor_callback(self, name: str, data):
        """Internal sensor callback router"""
        if name in self.sensor_callbacks:
            sensor_data = self._convert_sensor_data(name, data)
            self.sensor_callbacks[name](sensor_data)
        else:
            self.sensor_queues[name].put(data)

    def _convert_sensor_data(self, name: str, raw_data) -> SensorData:
        """Convert CARLA sensor data to SensorData format"""
        sensor = self.sensors[name]
        sensor_type = self._get_sensor_type(sensor.type_id)

        # Extract data based on sensor type
        if sensor_type == SensorType.RGB_CAMERA:
            # Convert to numpy array
            array = np.frombuffer(raw_data.raw_data, dtype=np.uint8)
            array = array.reshape((raw_data.height, raw_data.width, 4))  # BGRA
            data = array[:, :, :3]  # Drop alpha, convert to RGB

        elif sensor_type == SensorType.LIDAR:
            # Point cloud
            points = np.frombuffer(raw_data.raw_data, dtype=np.float32)
            points = points.reshape((-1, 4))  # x, y, z, intensity
            data = points

        elif sensor_type == SensorType.RADAR:
            # Radar detections
            data = [(det.altitude, det.azimuth, det.depth, det.velocity)
                    for det in raw_data]

        else:
            data = raw_data

        transform = sensor.get_transform()

        return SensorData(
            sensor_type=sensor_type,
            timestamp=raw_data.timestamp,
            frame=raw_data.frame,
            data=data,
            transform=(transform.location.x, transform.location.y, transform.location.z,
                      transform.rotation.pitch, transform.rotation.yaw, transform.rotation.roll)
        )

    def _get_sensor_type(self, type_id: str) -> SensorType:
        """Map CARLA sensor ID to SensorType enum"""
        for sensor_type in SensorType:
            if sensor_type.value == type_id:
                return sensor_type
        return None

    def _get_weather_preset(self, preset_name: str) -> carla.WeatherParameters:
        """Get weather preset by name"""
        presets = {
            "ClearNoon": carla.WeatherParameters.ClearNoon,
            "CloudyNoon": carla.WeatherParameters.CloudyNoon,
            "WetNoon": carla.WeatherParameters.WetNoon,
            "WetCloudyNoon": carla.WeatherParameters.WetCloudyNoon,
            "SoftRainNoon": carla.WeatherParameters.SoftRainNoon,
            "MidRainyNoon": carla.WeatherParameters.MidRainyNoon,
            "HardRainNoon": carla.WeatherParameters.HardRainNoon,
            "ClearSunset": carla.WeatherParameters.ClearSunset,
        }
        return presets.get(preset_name, carla.WeatherParameters.ClearNoon)

    def _spawn_npcs(self, num_vehicles: int, num_pedestrians: int, seed: int):
        """Spawn NPC vehicles and pedestrians"""
        print(f"Spawning {num_vehicles} vehicles and {num_pedestrians} pedestrians...")

        np.random.seed(seed)
        blueprint_library = self.world.get_blueprint_library()
        spawn_points = self.world.get_map().get_spawn_points()

        # Spawn vehicles
        vehicle_bps = blueprint_library.filter('vehicle.*')
        for i in range(min(num_vehicles, len(spawn_points) - 1)):
            bp = np.random.choice(vehicle_bps)
            spawn_point = spawn_points[i + 1]  # Skip ego spawn point

            try:
                vehicle = self.world.spawn_actor(bp, spawn_point)
                vehicle.set_autopilot(True)
                self.npc_vehicles.append(vehicle)
            except:
                pass

        print(f"Spawned {len(self.npc_vehicles)} NPC vehicles")


# Example usage
if __name__ == "__main__":
    # Initialize adapter
    adapter = CARLAAdapter(host="localhost", port=2000)

    if not adapter.connect():
        print("Failed to connect to CARLA")
        exit(1)

    # Load scenario
    scenario = ScenarioConfig(
        map_name="Town01",
        weather="ClearNoon",
        num_vehicles=30,
        num_pedestrians=20
    )

    if not adapter.load_scenario(scenario):
        print("Failed to load scenario")
        adapter.cleanup()
        exit(1)

    # Attach sensors
    adapter.attach_sensor(
        SensorType.RGB_CAMERA,
        "front_camera",
        attributes={"image_size_x": "1920", "image_size_y": "1080", "fov": "110"}
    )

    adapter.attach_sensor(
        SensorType.LIDAR,
        "front_lidar",
        transform=carla.Transform(carla.Location(x=0.0, z=2.5)),
        attributes={"channels": "64", "range": "100", "points_per_second": "1000000"}
    )

    # Simulation loop
    try:
        for step in range(1000):
            # Get vehicle state
            state = adapter.get_vehicle_state()
            print(f"Step {step}: Speed = {state.speed_kmh:.1f} km/h, "
                  f"Location = ({state.location[0]:.1f}, {state.location[1]:.1f})")

            # Simple controller: maintain 30 km/h
            target_speed = 30.0 / 3.6  # m/s
            throttle = 0.5 if state.speed_mps < target_speed else 0.0

            adapter.apply_control(throttle=throttle, steer=0.0)

            # Get sensor data
            camera_data = adapter.get_sensor_data("front_camera", timeout=0.1)
            if camera_data:
                print(f"  Camera frame {camera_data.frame}, shape: {camera_data.data.shape}")

            # Tick simulation
            adapter.tick(dt=0.05)

    except KeyboardInterrupt:
        print("\nInterrupted by user")

    finally:
        adapter.cleanup()
        print("Done")

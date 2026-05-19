#!/usr/bin/env python3
"""
Gazebo/ROS 2 Adapter

Provides interface to Gazebo simulator for Vehicle-in-the-Loop testing.
Supports SDF models, sensor plugins, and ROS 2 bridge integration.
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
class GazeboConfig:
    """Gazebo configuration parameters."""
    version: str  # garden, harmonic, classic-11
    world_file: str
    robot_model: str
    plugins: List[str]
    ros2_bridge: bool
    physics_engine: str
    real_time_factor: float


class GazeboAdapter:
    """Adapter for Gazebo/ROS 2 vehicle simulation."""

    def __init__(self, config: GazeboConfig):
        """
        Initialize Gazebo adapter.

        Args:
            config: Gazebo configuration
        """
        self.config = config
        self.logger = logging.getLogger(__name__)
        self.gazebo_process = None
        self.bridge_process = None
        self.simulation_running = False

    def init(self) -> bool:
        """
        Initialize Gazebo environment.

        Returns:
            True if initialization successful
        """
        try:
            self.logger.info(f"Initializing Gazebo {self.config.version}")

            # Check Gazebo installation
            if self.config.version in ['garden', 'harmonic']:
                result = subprocess.run(['gz', 'sim', '--version'], capture_output=True, text=True)
            else:
                result = subprocess.run(['gazebo', '--version'], capture_output=True, text=True)

            if result.returncode != 0:
                self.logger.error("Gazebo not found")
                return False

            self.logger.info(f"Gazebo version: {result.stdout.strip()}")

            # Check ROS 2 installation
            if self.config.ros2_bridge:
                result = subprocess.run(['ros2', '--version'], capture_output=True, text=True)
                if result.returncode != 0:
                    self.logger.error("ROS 2 not found")
                    return False
                self.logger.info("ROS 2 bridge enabled")

            return True

        except Exception as e:
            self.logger.error(f"Initialization failed: {e}")
            return False

    def load_world(self, world_file: str) -> bool:
        """
        Load Gazebo world file.

        Args:
            world_file: Path to SDF world file

        Returns:
            True if world loaded successfully
        """
        try:
            self.logger.info(f"Loading world: {world_file}")

            if not Path(world_file).exists():
                self.logger.error(f"World file not found: {world_file}")
                return False

            self.config.world_file = world_file
            return True

        except Exception as e:
            self.logger.error(f"World loading failed: {e}")
            return False

    def load_vehicle(self, vehicle_model: str) -> bool:
        """
        Load vehicle model (URDF or SDF).

        Args:
            vehicle_model: Path to vehicle model file

        Returns:
            True if model loaded successfully
        """
        try:
            self.logger.info(f"Loading vehicle model: {vehicle_model}")

            if not Path(vehicle_model).exists():
                self.logger.error(f"Vehicle model not found: {vehicle_model}")
                return False

            self.config.robot_model = vehicle_model
            return True

        except Exception as e:
            self.logger.error(f"Vehicle loading failed: {e}")
            return False

    def start_simulation(self, headless: bool = False) -> bool:
        """
        Start Gazebo simulation.

        Args:
            headless: Run in headless mode (no GUI)

        Returns:
            True if simulation started
        """
        try:
            self.logger.info("Starting Gazebo simulation")

            # Build Gazebo command
            if self.config.version in ['garden', 'harmonic']:
                cmd = ['gz', 'sim', self.config.world_file]
                if headless:
                    cmd.append('-s')  # Server only
                else:
                    cmd.append('-r')  # Run with GUI
            else:
                cmd = ['gazebo', self.config.world_file]
                if headless:
                    cmd.append('--headless')

            # Set physics engine
            if self.config.physics_engine:
                cmd.extend(['--physics', self.config.physics_engine])

            self.logger.debug(f"Gazebo command: {' '.join(cmd)}")

            # Start Gazebo process
            self.gazebo_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            time.sleep(3.0)  # Allow Gazebo to initialize

            if self.gazebo_process.poll() is not None:
                stderr = self.gazebo_process.stderr.read() if self.gazebo_process.stderr else "No error output"
                self.logger.error(f"Gazebo terminated unexpectedly: {stderr}")
                return False

            self.simulation_running = True
            self.logger.info("Gazebo simulation running")
            return True

        except Exception as e:
            self.logger.error(f"Simulation start failed: {e}")
            return False

    def spawn_model(self, model_name: str, model_file: str, pose: Dict[str, float]) -> bool:
        """
        Spawn model in Gazebo world.

        Args:
            model_name: Name for spawned model
            model_file: Path to model file
            pose: Initial pose {x, y, z, roll, pitch, yaw}

        Returns:
            True if model spawned successfully
        """
        if not self.simulation_running:
            self.logger.error("Simulation not running")
            return False

        try:
            self.logger.info(f"Spawning model: {model_name}")

            if self.config.ros2_bridge:
                # Use ROS 2 spawn entity service
                cmd = [
                    'ros2', 'run', 'gazebo_ros', 'spawn_entity.py',
                    '-file', model_file,
                    '-entity', model_name,
                    '-x', str(pose.get('x', 0)),
                    '-y', str(pose.get('y', 0)),
                    '-z', str(pose.get('z', 0)),
                    '-R', str(pose.get('roll', 0)),
                    '-P', str(pose.get('pitch', 0)),
                    '-Y', str(pose.get('yaw', 0))
                ]

                result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

                if result.returncode != 0:
                    self.logger.error(f"Model spawn failed: {result.stderr}")
                    return False

            self.logger.info(f"Model {model_name} spawned successfully")
            return True

        except Exception as e:
            self.logger.error(f"Model spawning failed: {e}")
            return False

    def start_ros2_bridge(self) -> bool:
        """
        Start ROS 2 bridge for Gazebo communication.

        Returns:
            True if bridge started successfully
        """
        if not self.config.ros2_bridge:
            self.logger.info("ROS 2 bridge not enabled")
            return True

        try:
            self.logger.info("Starting ROS 2 bridge")

            cmd = ['ros2', 'launch', 'ros_gz_bridge', 'ros_gz_bridge.launch.py']

            self.bridge_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )

            time.sleep(2.0)

            if self.bridge_process.poll() is not None:
                self.logger.error("ROS 2 bridge terminated unexpectedly")
                return False

            self.logger.info("ROS 2 bridge running")
            return True

        except Exception as e:
            self.logger.error(f"ROS 2 bridge start failed: {e}")
            return False

    def set_physics(self, engine: str) -> bool:
        """
        Set physics engine.

        Args:
            engine: Physics engine name (ode, bullet, dart, simbody)

        Returns:
            True if physics engine set
        """
        try:
            self.logger.info(f"Setting physics engine: {engine}")
            self.config.physics_engine = engine
            # Physics engine is set via command line args at startup
            return True

        except Exception as e:
            self.logger.error(f"Physics configuration failed: {e}")
            return False

    def pause_simulation(self) -> bool:
        """
        Pause Gazebo simulation.

        Returns:
            True if paused successfully
        """
        try:
            if self.config.version in ['garden', 'harmonic']:
                subprocess.run(['gz', 'sim', '-p'], check=True)
            else:
                subprocess.run(['gz', 'world', '-p', '1'], check=True)

            self.logger.info("Simulation paused")
            return True

        except Exception as e:
            self.logger.error(f"Pause failed: {e}")
            return False

    def resume_simulation(self) -> bool:
        """
        Resume Gazebo simulation.

        Returns:
            True if resumed successfully
        """
        try:
            if self.config.version in ['garden', 'harmonic']:
                subprocess.run(['gz', 'sim', '-u'], check=True)
            else:
                subprocess.run(['gz', 'world', '-p', '0'], check=True)

            self.logger.info("Simulation resumed")
            return True

        except Exception as e:
            self.logger.error(f"Resume failed: {e}")
            return False

    def stop_simulation(self) -> bool:
        """
        Stop Gazebo simulation.

        Returns:
            True if stopped successfully
        """
        try:
            self.logger.info("Stopping Gazebo simulation")

            if self.gazebo_process:
                self.gazebo_process.terminate()
                self.gazebo_process.wait(timeout=10)
                self.gazebo_process = None

            if self.bridge_process:
                self.bridge_process.terminate()
                self.bridge_process.wait(timeout=5)
                self.bridge_process = None

            self.simulation_running = False
            self.logger.info("Simulation stopped")
            return True

        except subprocess.TimeoutExpired:
            self.logger.warning("Force killing processes")
            if self.gazebo_process:
                self.gazebo_process.kill()
            if self.bridge_process:
                self.bridge_process.kill()
            self.simulation_running = False
            return True

        except Exception as e:
            self.logger.error(f"Simulation stop failed: {e}")
            return False

    def get_simulation_status(self) -> Dict[str, Any]:
        """
        Get simulation status.

        Returns:
            Simulation status information
        """
        status = {
            'running': self.simulation_running,
            'version': self.config.version,
            'world': self.config.world_file,
            'robot_model': self.config.robot_model,
            'ros2_bridge': self.config.ros2_bridge,
            'physics_engine': self.config.physics_engine
        }

        if self.gazebo_process:
            status['gazebo_pid'] = self.gazebo_process.pid
            status['gazebo_running'] = self.gazebo_process.poll() is None

        if self.bridge_process:
            status['bridge_pid'] = self.bridge_process.pid
            status['bridge_running'] = self.bridge_process.poll() is None

        return status


def main():
    """Command-line interface for Gazebo adapter."""
    parser = argparse.ArgumentParser(description='Gazebo/ROS 2 Adapter')
    parser.add_argument('--version', default='harmonic', help='Gazebo version')
    parser.add_argument('--init', action='store_true', help='Initialize Gazebo')
    parser.add_argument('--load-world', type=str, help='Load world file')
    parser.add_argument('--load-vehicle', type=str, help='Load vehicle model')
    parser.add_argument('--start', action='store_true', help='Start simulation')
    parser.add_argument('--headless', action='store_true', help='Run headless')
    parser.add_argument('--stop', action='store_true', help='Stop simulation')
    parser.add_argument('--status', action='store_true', help='Get status')
    parser.add_argument('--set-physics', type=str, help='Set physics engine')

    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

    # Create adapter configuration
    config = GazeboConfig(
        version=args.version,
        world_file='',
        robot_model='',
        plugins=['diff_drive', 'lidar', 'camera'],
        ros2_bridge=True,
        physics_engine='ode',
        real_time_factor=1.0
    )

    adapter = GazeboAdapter(config)

    # Execute commands
    if args.init:
        adapter.init()

    if args.load_world:
        adapter.load_world(args.load_world)

    if args.load_vehicle:
        adapter.load_vehicle(args.load_vehicle)

    if args.start:
        adapter.start_simulation(headless=args.headless)

    if args.set_physics:
        adapter.set_physics(args.set_physics)

    if args.stop:
        adapter.stop_simulation()

    if args.status:
        status = adapter.get_simulation_status()
        print(json.dumps(status, indent=2))


if __name__ == '__main__':
    main()

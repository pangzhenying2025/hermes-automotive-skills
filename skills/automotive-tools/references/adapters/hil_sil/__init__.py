"""
HIL/SIL/VIL Tool Adapters

Provides adapters for Hardware-in-the-Loop, Software-in-the-Loop,
and Vehicle-in-the-Loop testing platforms.
"""

from .scalexio_adapter import ScalexioAdapter
from .ni_pxi_adapter import NIPXIAdapter
from .gazebo_adapter import GazeboAdapter
from .qemu_adapter import QEMUAdapter
from .carla_adapter import CARLAAdapter

__all__ = [
    'ScalexioAdapter',
    'NIPXIAdapter',
    'GazeboAdapter',
    'QEMUAdapter',
    'CARLAAdapter',
]

#!/usr/bin/env python3
"""
MOST Protocol Adapter
Provides Python interface for MOST (Media Oriented Systems Transport) multimedia network
"""

import time
import logging
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


class MOSTChannelType(Enum):
    """MOST channel types"""
    SYNCHRONOUS = 0    # Streaming (audio/video)
    ASYNCHRONOUS = 1   # Packet data
    CONTROL = 2        # Network management
    ETHERNET = 3       # IP packets (MOST150 only)


@dataclass
class MOSTMessage:
    """MOST control message"""
    target_address: int
    source_address: int
    function_block_id: int
    function_id: int
    op_type: int        # Set/Get/Status/Error
    payload: bytes
    timestamp: float


class MOSTAdapter:
    """Adapter for MOST protocol communication"""

    def __init__(
        self,
        node_address: int = 0x0100,
        is_master: bool = False,
        simulation_mode: bool = True
    ):
        """Initialize MOST adapter"""
        self.node_address = node_address
        self.is_master = is_master
        self.simulation_mode = simulation_mode
        self.running = False
        self.sync_connections: Dict[int, Dict] = {}

        logger.info(f"MOST adapter initialized: address=0x{node_address:04X} "
                   f"({'MASTER' if is_master else 'SLAVE'})")

    def allocate_sync_channel(
        self,
        source_addr: int,
        sink_addr: int,
        bandwidth: int
    ) -> Optional[int]:
        """Allocate synchronous channel for streaming"""
        try:
            channel_id = len(self.sync_connections) + 1

            self.sync_connections[channel_id] = {
                'source': source_addr,
                'sink': sink_addr,
                'bandwidth': bandwidth,
                'active': False
            }

            logger.info(f"Allocated sync channel {channel_id}: "
                       f"0x{source_addr:04X} -> 0x{sink_addr:04X} "
                       f"({bandwidth} bytes/frame)")
            return channel_id

        except Exception as e:
            logger.error(f"Failed to allocate sync channel: {e}")
            return None

    def start_sync_connection(self, channel_id: int) -> bool:
        """Start synchronous streaming"""
        try:
            if channel_id not in self.sync_connections:
                logger.error(f"Channel {channel_id} not found")
                return False

            self.sync_connections[channel_id]['active'] = True
            logger.info(f"Started sync connection {channel_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to start sync connection: {e}")
            return False

    def send_control_message(self, message: MOSTMessage) -> bool:
        """Send MOST control message"""
        try:
            if self.simulation_mode:
                logger.debug(f"TX MOST control: FBlock=0x{message.function_block_id:02X} "
                           f"Func=0x{message.function_id:03X} -> 0x{message.target_address:04X}")

            return True

        except Exception as e:
            logger.error(f"Failed to send control message: {e}")
            return False

    def stream_audio(self, channel_id: int, audio_data: bytes) -> bool:
        """Stream audio data on synchronous channel"""
        try:
            conn = self.sync_connections.get(channel_id)
            if not conn or not conn['active']:
                return False

            # In real implementation, send to MOST INIC
            return True

        except Exception as e:
            logger.error(f"Failed to stream audio: {e}")
            return False

    def __del__(self):
        """Cleanup"""
        for channel_id in list(self.sync_connections.keys()):
            if channel_id in self.sync_connections:
                self.sync_connections[channel_id]['active'] = False

"""
Tool Detection Module.

Detects installed automotive development tools and validates licenses.
"""

from .tool_detector import ToolDetector, ToolInfo
from .license_detector import LicenseDetector, LicenseInfo

__all__ = [
    'ToolDetector',
    'ToolInfo',
    'LicenseDetector',
    'LicenseInfo',
]

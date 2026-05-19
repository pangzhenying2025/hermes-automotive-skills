"""
Intelligent Tool Router for Automotive Claude Code Platform.

Routes commands to appropriate tool adapters with auto-detection,
fallback mechanisms, and unified interface.
"""

from typing import List, Optional, Dict, Any, Type
import logging
from pathlib import Path


class ToolRouter:
    """
    Routes commands to appropriate tool adapter.

    Provides unified interface across 300+ commercial and opensource tools
    with intelligent auto-detection and fallback strategies.
    """

    def __init__(self):
        """Initialize tool router and register all adapters."""
        self.logger = logging.getLogger("tool_router")
        self.adapters: Dict[str, List[Any]] = {}
        self._register_adapters()

    def _register_adapters(self):
        """
        Register all available adapters.

        This method dynamically imports and registers all tool adapters
        from the adapters directory.
        """
        # AUTOSAR adapters
        self.adapters["autosar"] = []
        try:
            from tools.adapters.autosar.tresos_adapter import TresosAdapter
            self.adapters["autosar"].append(TresosAdapter())
        except ImportError:
            pass

        try:
            from tools.adapters.autosar.arctic_core_adapter import ArcticCoreAdapter
            self.adapters["autosar"].append(ArcticCoreAdapter())
        except ImportError:
            pass

        # Calibration adapters
        self.adapters["calibration"] = []
        try:
            from tools.adapters.calibration.inca_adapter import INCAAdapter
            self.adapters["calibration"].append(INCAAdapter())
        except ImportError:
            pass

        try:
            from tools.adapters.calibration.openxcp_adapter import OpenXCPAdapter
            self.adapters["calibration"].append(OpenXCPAdapter())
        except ImportError:
            pass

        # Network adapters
        self.adapters["network"] = []
        try:
            from tools.adapters.network.canoe_adapter import CANoeAdapter
            self.adapters["network"].append(CANoeAdapter())
        except ImportError:
            pass

        try:
            from tools.adapters.network.savvycan_adapter import SavvyCANAdapter
            self.adapters["network"].append(SavvyCANAdapter())
        except ImportError:
            pass

        # Embedded adapters
        self.adapters["embedded"] = []
        try:
            from tools.adapters.embedded.gcc_arm_adapter import GCCARMAdapter
            self.adapters["embedded"].append(GCCARMAdapter())
        except ImportError:
            pass

        try:
            from tools.adapters.embedded.openocd_adapter import OpenOCDAdapter
            self.adapters["embedded"].append(OpenOCDAdapter())
        except ImportError:
            pass

        # HIL/SIL adapters
        self.adapters["hil_sil"] = []
        try:
            from tools.adapters.hil_sil.carla_adapter import CARLAAdapter
            self.adapters["hil_sil"].append(CARLAAdapter())
        except ImportError:
            pass

        # Battery/EV adapters
        self.adapters["battery"] = []
        try:
            from tools.adapters.battery.pybamm_adapter import PyBAMMAdapter
            self.adapters["battery"].append(PyBAMMAdapter())
        except ImportError:
            pass

        self.logger.info(f"Registered adapters for {len(self.adapters)} categories")

    def get_available_tools(self, category: str) -> List[Any]:
        """
        Get all available tools for a category.

        Args:
            category: Tool category (e.g., 'autosar', 'calibration')

        Returns:
            List of available and licensed tool adapters

        Raises:
            ValueError: If category is unknown
        """
        if category not in self.adapters:
            raise ValueError(
                f"Unknown category: {category}. "
                f"Available: {list(self.adapters.keys())}"
            )

        available = [
            adapter for adapter in self.adapters[category]
            if adapter.is_available and adapter.license_valid
        ]

        self.logger.info(
            f"Category '{category}': {len(available)}/{len(self.adapters[category])} "
            f"tools available"
        )

        return available

    def get_best_tool(
        self,
        category: str,
        preference: str = "auto"
    ) -> Optional[Any]:
        """
        Get best available tool for a category.

        Strategy:
        - auto: Prefer commercial if available, else opensource
        - commercial: Only commercial tools
        - opensource: Only opensource tools
        - <tool_name>: Specific tool by name

        Args:
            category: Tool category
            preference: Tool selection preference

        Returns:
            Best matching tool adapter or None if unavailable
        """
        available = self.get_available_tools(category)

        if not available:
            self.logger.warning(f"No available tools for category: {category}")
            return None

        if preference == "auto":
            # Prefer commercial if available, else opensource
            commercial = [a for a in available if not a.is_opensource]
            if commercial:
                selected = commercial[0]
                self.logger.info(
                    f"Auto-selected commercial tool: {selected.name} "
                    f"v{selected.version}"
                )
                return selected

            selected = available[0]
            self.logger.info(
                f"Auto-selected opensource tool: {selected.name} "
                f"v{selected.version}"
            )
            return selected

        elif preference == "commercial":
            commercial = [a for a in available if not a.is_opensource]
            if commercial:
                selected = commercial[0]
                self.logger.info(f"Selected commercial tool: {selected.name}")
                return selected
            self.logger.warning(f"No commercial tools available for: {category}")
            return None

        elif preference == "opensource":
            opensource = [a for a in available if a.is_opensource]
            if opensource:
                selected = opensource[0]
                self.logger.info(f"Selected opensource tool: {selected.name}")
                return selected
            self.logger.warning(f"No opensource tools available for: {category}")
            return None

        else:
            # Specific tool requested
            for adapter in available:
                if adapter.name == preference:
                    self.logger.info(f"Selected specific tool: {preference}")
                    return adapter

            self.logger.error(
                f"Tool '{preference}' not available. "
                f"Available: {[a.name for a in available]}"
            )
            return None

    def execute(
        self,
        category: str,
        command: str,
        parameters: Dict[str, Any],
        tool_preference: str = "auto"
    ) -> Dict[str, Any]:
        """
        Execute command with best available tool.

        Args:
            category: Tool category
            command: Command name
            parameters: Command parameters
            tool_preference: Tool selection preference

        Returns:
            Dictionary containing execution results with tool metadata
        """
        adapter = self.get_best_tool(category, tool_preference)

        if not adapter:
            error_msg = f"No available tool for category: {category}"
            self.logger.error(error_msg)

            # Suggest opensource alternatives
            all_adapters = self.adapters.get(category, [])
            opensource = [a for a in all_adapters if a.is_opensource]
            suggestion = (
                f"Install opensource alternative: {opensource[0].name}"
                if opensource else
                f"No alternatives available for {category}"
            )

            return {
                "success": False,
                "error": error_msg,
                "suggestion": suggestion,
                "tool_used": None
            }

        try:
            self.logger.info(
                f"Executing {command} with {adapter.name} "
                f"(category: {category})"
            )

            result = adapter.execute(command, parameters)
            result["tool_used"] = adapter.name
            result["tool_version"] = adapter.version
            result["tool_type"] = "opensource" if adapter.is_opensource else "commercial"

            if result.get("success"):
                self.logger.info(f"Command succeeded with {adapter.name}")
            else:
                self.logger.warning(f"Command failed with {adapter.name}")

            return result

        except Exception as e:
            error_msg = f"Exception during execution: {str(e)}"
            self.logger.exception(error_msg)
            return {
                "success": False,
                "error": error_msg,
                "tool_used": adapter.name,
                "tool_version": adapter.version
            }

    def list_all_tools(self) -> Dict[str, List[Dict[str, Any]]]:
        """
        List all registered tools with their status.

        Returns:
            Dictionary mapping categories to tool information
        """
        result = {}
        for category, adapters in self.adapters.items():
            result[category] = [adapter.get_info() for adapter in adapters]
        return result

    def get_tool_info(self, tool_name: str) -> Optional[Dict[str, Any]]:
        """
        Get information about a specific tool.

        Args:
            tool_name: Name of the tool

        Returns:
            Tool information dictionary or None if not found
        """
        for category, adapters in self.adapters.items():
            for adapter in adapters:
                if adapter.name == tool_name:
                    return adapter.get_info()
        return None


# Global tool router instance
_router_instance = None


def get_router() -> ToolRouter:
    """Get global ToolRouter instance (singleton pattern)."""
    global _router_instance
    if _router_instance is None:
        _router_instance = ToolRouter()
    return _router_instance

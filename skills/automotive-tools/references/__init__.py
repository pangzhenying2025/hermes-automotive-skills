"""
Automotive Claude Code - Tool Integration Framework.

This package provides unified interfaces for 300+ professional automotive tools,
enabling seamless switching between commercial and opensource alternatives.

Includes the LLM Council multi-model debate system for critical decisions.
"""

__version__ = "0.1.0"

from .tool_router import ToolRouter, get_router
from .adapters.base_adapter import (
    BaseToolAdapter,
    OpensourceToolAdapter,
    CommercialToolAdapter
)
from .llm_council import (
    LLMCouncil,
    DebateResult,
    ConfidenceLevel,
    TaskType,
    ModelConfig
)

__all__ = [
    # Tool Router
    "ToolRouter",
    "get_router",
    # Adapters
    "BaseToolAdapter",
    "OpensourceToolAdapter",
    "CommercialToolAdapter",
    # LLM Council
    "LLMCouncil",
    "DebateResult",
    "ConfidenceLevel",
    "TaskType",
    "ModelConfig",
]

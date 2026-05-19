"""
Tool Comparison Module.

Feature and performance comparisons between commercial and opensource tools.
"""

from .tool_comparator import (
    ToolComparator,
    Tool,
    FeatureComparison,
    ComparisonMatrix,
    FeatureSupport
)
from .benchmark import ToolBenchmark, BenchmarkResult, BenchmarkSuite

__all__ = [
    'ToolComparator',
    'Tool',
    'FeatureComparison',
    'ComparisonMatrix',
    'FeatureSupport',
    'ToolBenchmark',
    'BenchmarkResult',
    'BenchmarkSuite',
]

"""
MBD Tool Adapters for Model-Based Development.

This package provides adapters for:
- MATLAB/Simulink (commercial)
- OpenModelica (opensource)
- Ansys SCADE (commercial)
"""

from .simulink_adapter import SimulinkAdapter
from .openmodelica_adapter import OpenModelicaAdapter
from .scade_adapter import ScadeAdapter

__all__ = ['SimulinkAdapter', 'OpenModelicaAdapter', 'ScadeAdapter']

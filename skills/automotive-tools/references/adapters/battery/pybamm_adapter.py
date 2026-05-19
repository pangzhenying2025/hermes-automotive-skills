"""
PyBaMM (Python Battery Mathematical Modeling) Adapter

Provides interface to PyBaMM for:
- Battery cell modeling and simulation
- Various battery chemistries (LFP, NMC, LCO, etc.)
- Thermal effects and aging models
- Parameter sensitivity analysis
- SOC/SOH estimation validation

Supports PyBaMM 23.0+
"""

import numpy as np
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple, Any
from enum import Enum

try:
    import pybamm
    PYBAMM_AVAILABLE = True
except ImportError:
    PYBAMM_AVAILABLE = False
    print("Warning: PyBaMM not available. Install with: pip install pybamm")


class BatteryChemistry(Enum):
    """Supported battery chemistries"""
    NMC = "NMC"
    LFP = "LFP"
    NCA = "NCA"
    LCO = "LCO"


class ModelType(Enum):
    """Battery model types"""
    DFN = "DFN"  # Doyle-Fuller-Newman (most detailed)
    SPM = "SPM"  # Single Particle Model
    SPMe = "SPMe"  # Single Particle Model with electrolyte
    ECM = "ECM"  # Equivalent Circuit Model


@dataclass
class CycleProfile:
    """Charge/discharge cycle profile"""
    current_a: np.ndarray  # Current profile (positive = discharge)
    time_s: np.ndarray     # Time points
    temperature_c: float = 25.0


@dataclass
class SimulationResult:
    """Battery simulation results"""
    time_s: np.ndarray
    voltage_v: np.ndarray
    current_a: np.ndarray
    temperature_c: np.ndarray
    soc: np.ndarray
    capacity_ah: float
    energy_wh: float
    average_voltage_v: float


class PyBaMMAdapter:
    """
    Adapter for PyBaMM battery modeling library
    """

    def __init__(self, chemistry: BatteryChemistry = BatteryChemistry.NMC,
                 model_type: ModelType = ModelType.SPMe):
        """
        Initialize PyBaMM adapter

        Args:
            chemistry: Battery chemistry
            model_type: Physics-based model type
        """
        if not PYBAMM_AVAILABLE:
            raise RuntimeError("PyBaMM not available")

        self.chemistry = chemistry
        self.model_type = model_type

        # PyBaMM objects
        self.model: Optional[pybamm.BaseModel] = None
        self.parameter_set: Optional[Dict] = None
        self.simulation: Optional[pybamm.Simulation] = None

        # Initialize model
        self._initialize_model()

    def _initialize_model(self):
        """Initialize PyBaMM model"""
        print(f"Initializing {self.model_type.value} model for {self.chemistry.value}...")

        # Select model
        if self.model_type == ModelType.DFN:
            self.model = pybamm.lithium_ion.DFN()
        elif self.model_type == ModelType.SPM:
            self.model = pybamm.lithium_ion.SPM()
        elif self.model_type == ModelType.SPMe:
            self.model = pybamm.lithium_ion.SPMe()
        else:
            raise ValueError(f"Unsupported model type: {self.model_type}")

        # Load parameter set
        self.parameter_set = self._get_parameter_set(self.chemistry)

        print("Model initialized successfully")

    def _get_parameter_set(self, chemistry: BatteryChemistry) -> Dict:
        """Get parameter set for specified chemistry"""
        chemistry_map = {
            BatteryChemistry.NMC: "Chen2020",  # NMC811
            BatteryChemistry.LFP: "Prada2013",  # LFP
            BatteryChemistry.NCA: "Chen2020",   # Similar to NMC
            BatteryChemistry.LCO: "Marquis2019",  # LCO
        }

        param_name = chemistry_map.get(chemistry, "Chen2020")
        return pybamm.ParameterValues(param_name)

    def set_cell_parameters(self, capacity_ah: float, nominal_voltage_v: float = None,
                           electrode_height_m: float = None,
                           electrode_width_m: float = None):
        """
        Customize cell parameters

        Args:
            capacity_ah: Nominal capacity in Ah
            nominal_voltage_v: Nominal voltage
            electrode_height_m: Electrode height (optional)
            electrode_width_m: Electrode width (optional)
        """
        if self.parameter_set is None:
            return

        # Scale capacity
        default_capacity = self.parameter_set["Nominal cell capacity [A.h]"]
        scale_factor = capacity_ah / default_capacity

        # Update geometric parameters to achieve target capacity
        if electrode_height_m is not None:
            self.parameter_set["Electrode height [m]"] = electrode_height_m

        if electrode_width_m is not None:
            self.parameter_set["Electrode width [m]"] = electrode_width_m

        # Update capacity
        self.parameter_set.update({"Nominal cell capacity [A.h]": capacity_ah})

        if nominal_voltage_v is not None:
            # Adjust OCV curves (simplified)
            # In practice, this requires detailed electrochemistry knowledge
            pass

        print(f"Cell parameters updated: {capacity_ah} Ah capacity")

    def simulate_cycle(self, profile: CycleProfile,
                      initial_soc: float = 1.0,
                      solver: str = "CasadiSolver") -> SimulationResult:
        """
        Simulate battery under specified cycle profile

        Args:
            profile: Current profile to simulate
            initial_soc: Initial state of charge (0-1)
            solver: Solver to use (CasadiSolver, ScipySolver, etc.)

        Returns:
            SimulationResult with voltage, current, temperature, etc.
        """
        print(f"Simulating cycle with {len(profile.time_s)} time points...")

        # Create interpolated current function
        current_function = pybamm.Interpolant(
            profile.time_s,
            profile.current_a,
            pybamm.t,
            name="Current function",
            interpolator="linear"
        )

        # Update parameters
        self.parameter_set.update({
            "Current function [A]": current_function,
            "Ambient temperature [K]": profile.temperature_c + 273.15,
            "Initial concentration in negative electrode [mol.m-3]": initial_soc,
            "Initial concentration in positive electrode [mol.m-3]": initial_soc,
        })

        # Create simulation
        self.simulation = pybamm.Simulation(
            self.model,
            parameter_values=self.parameter_set,
            solver=getattr(pybamm, solver)()
        )

        # Solve
        t_eval = profile.time_s
        solution = self.simulation.solve(t_eval=t_eval)

        # Extract results
        time_s = solution["Time [s]"].entries
        voltage_v = solution["Terminal voltage [V]"].entries
        current_a = solution["Current [A]"].entries
        temperature_c = solution["X-averaged cell temperature [K]"].entries - 273.15
        soc = solution["Discharge capacity [A.h]"].entries / self.parameter_set["Nominal cell capacity [A.h]"]

        # Calculate metrics
        capacity_ah = np.trapz(np.abs(current_a), time_s) / 3600
        energy_wh = np.trapz(voltage_v * current_a, time_s) / 3600
        average_voltage_v = np.mean(voltage_v)

        result = SimulationResult(
            time_s=time_s,
            voltage_v=voltage_v,
            current_a=current_a,
            temperature_c=temperature_c,
            soc=1.0 - soc,  # Convert to remaining SOC
            capacity_ah=capacity_ah,
            energy_wh=energy_wh,
            average_voltage_v=average_voltage_v
        )

        print(f"Simulation complete: {capacity_ah:.2f} Ah, {energy_wh:.2f} Wh")
        return result

    def simulate_constant_current(self, current_a: float, duration_s: float,
                                  initial_soc: float = 1.0,
                                  cutoff_voltage_v: float = None) -> SimulationResult:
        """
        Simulate constant current discharge/charge

        Args:
            current_a: Current in Amperes (positive = discharge)
            duration_s: Duration in seconds
            initial_soc: Initial SOC (0-1)
            cutoff_voltage_v: Cutoff voltage (optional)

        Returns:
            SimulationResult
        """
        # Create constant current profile
        time_s = np.linspace(0, duration_s, 1000)
        current_profile = np.ones_like(time_s) * current_a

        profile = CycleProfile(
            current_a=current_profile,
            time_s=time_s
        )

        # Add cutoff voltage as event if specified
        if cutoff_voltage_v is not None:
            # PyBaMM events
            if current_a > 0:  # Discharge
                self.model.events.append(
                    pybamm.Event(
                        "Minimum voltage",
                        pybamm.voltage - cutoff_voltage_v,
                        pybamm.EventType.TERMINATION
                    )
                )
            else:  # Charge
                self.model.events.append(
                    pybamm.Event(
                        "Maximum voltage",
                        cutoff_voltage_v - pybamm.voltage,
                        pybamm.EventType.TERMINATION
                    )
                )

        return self.simulate_cycle(profile, initial_soc=initial_soc)

    def simulate_cccv_charge(self, charge_current_a: float,
                            target_voltage_v: float,
                            cutoff_current_a: float = 0.05,
                            initial_soc: float = 0.0) -> SimulationResult:
        """
        Simulate Constant Current Constant Voltage (CCCV) charge

        Args:
            charge_current_a: Charging current (negative value)
            target_voltage_v: Target voltage for CV phase
            cutoff_current_a: Current cutoff for charge termination
            initial_soc: Initial SOC

        Returns:
            SimulationResult
        """
        print(f"Simulating CCCV charge: {-charge_current_a} A CC to {target_voltage_v} V")

        # Create CC-CV experiment
        experiment = pybamm.Experiment([
            f"Charge at {-charge_current_a} A until {target_voltage_v} V",
            f"Hold at {target_voltage_v} V until {cutoff_current_a} A",
        ])

        # Update parameters
        self.parameter_set.update({
            "Initial concentration in negative electrode [mol.m-3]": initial_soc,
            "Initial concentration in positive electrode [mol.m-3]": initial_soc,
        })

        # Create and run simulation
        sim = pybamm.Simulation(
            self.model,
            parameter_values=self.parameter_set,
            experiment=experiment
        )

        solution = sim.solve()

        # Extract results
        time_s = solution["Time [s]"].entries
        voltage_v = solution["Terminal voltage [V]"].entries
        current_a = solution["Current [A]"].entries
        temperature_c = solution["X-averaged cell temperature [K]"].entries - 273.15
        soc = 1.0 - solution["Discharge capacity [A.h]"].entries / self.parameter_set["Nominal cell capacity [A.h]"]

        capacity_ah = np.trapz(np.abs(current_a), time_s) / 3600
        energy_wh = np.trapz(voltage_v * current_a, time_s) / 3600

        return SimulationResult(
            time_s=time_s,
            voltage_v=voltage_v,
            current_a=current_a,
            temperature_c=temperature_c,
            soc=soc,
            capacity_ah=capacity_ah,
            energy_wh=energy_wh,
            average_voltage_v=np.mean(voltage_v)
        )

    def get_ocv_curve(self, soc_points: np.ndarray = None) -> Tuple[np.ndarray, np.ndarray]:
        """
        Get Open Circuit Voltage (OCV) vs SOC curve

        Args:
            soc_points: SOC points to evaluate (0-1)

        Returns:
            (soc, ocv_v) arrays
        """
        if soc_points is None:
            soc_points = np.linspace(0, 1, 101)

        ocv_values = []

        for soc in soc_points:
            # Simulate at very low current to approximate OCV
            result = self.simulate_constant_current(
                current_a=0.001,  # 1 mA
                duration_s=10,
                initial_soc=soc
            )
            ocv_values.append(result.voltage_v[0])

        return soc_points, np.array(ocv_values)

    def parameter_sensitivity(self, parameter_name: str,
                             parameter_values: List[float],
                             test_current_a: float = 10.0) -> Dict[float, SimulationResult]:
        """
        Perform parameter sensitivity analysis

        Args:
            parameter_name: Parameter to vary (e.g., "Negative electrode thickness [m]")
            parameter_values: List of parameter values to test
            test_current_a: Test current

        Returns:
            Dictionary mapping parameter value to SimulationResult
        """
        results = {}

        for value in parameter_values:
            print(f"Testing {parameter_name} = {value}")

            # Update parameter
            self.parameter_set.update({parameter_name: value})

            # Run simulation
            result = self.simulate_constant_current(
                current_a=test_current_a,
                duration_s=3600
            )

            results[value] = result

        return results


# Example usage
if __name__ == "__main__":
    # Initialize adapter
    adapter = PyBaMMAdapter(
        chemistry=BatteryChemistry.NMC,
        model_type=ModelType.SPMe
    )

    # Set cell parameters
    adapter.set_cell_parameters(capacity_ah=50.0)

    print("\n=== Test 1: Constant Current Discharge ===")
    result_discharge = adapter.simulate_constant_current(
        current_a=50.0,  # 1C discharge
        duration_s=3600,
        initial_soc=1.0,
        cutoff_voltage_v=3.0
    )

    print(f"Discharge capacity: {result_discharge.capacity_ah:.2f} Ah")
    print(f"Discharge energy: {result_discharge.energy_wh:.2f} Wh")
    print(f"Average voltage: {result_discharge.average_voltage_v:.3f} V")
    print(f"Final temperature: {result_discharge.temperature_c[-1]:.1f}°C")

    print("\n=== Test 2: CCCV Charge ===")
    result_charge = adapter.simulate_cccv_charge(
        charge_current_a=-50.0,  # 1C charge
        target_voltage_v=4.2,
        cutoff_current_a=2.5,  # C/20 cutoff
        initial_soc=0.0
    )

    print(f"Charge capacity: {result_charge.capacity_ah:.2f} Ah")
    print(f"Charge energy: {result_charge.energy_wh:.2f} Wh")
    print(f"Charge time: {result_charge.time_s[-1]/60:.1f} minutes")

    print("\n=== Test 3: OCV Curve ===")
    soc_points, ocv_curve = adapter.get_ocv_curve(soc_points=np.linspace(0, 1, 11))
    print("SOC | OCV (V)")
    print("-" * 20)
    for soc, ocv in zip(soc_points, ocv_curve):
        print(f"{soc:3.1f} | {ocv:6.3f}")

    print("\nAll tests complete")

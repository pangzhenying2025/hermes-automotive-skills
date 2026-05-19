# EV Charging - Advanced Topics

## Vehicle-to-Grid (V2G) Grid Services

V2G enables EVs to provide grid stabilization services while parked, generating revenue for owners.

### Frequency Regulation

Grid frequency must stay at 60.00 Hz (50.00 Hz in Europe). V2G responds to deviations:

```python
class V2G_FrequencyRegulation:
    def __init__(self, nominal_freq=60.0, deadband=0.01):
        self.nominal_freq = nominal_freq
        self.deadband = deadband
        self.max_power_kw = 10.0  # Bidirectional OBC rating

    def compute_power_command(self, grid_freq):
        """
        Frequency droop control:
        P = K × (f_nominal - f_measured)

        frequency_error = grid_freq - self.nominal_freq

        # Deadband to avoid excessive switching
        if abs(frequency_error) < self.deadband:
            return 0.0

        # Droop coefficient (typical: 20-50 Hz/MW)
        K_droop = 30.0  # Hz/MW

        # Compute power command (negative = discharge, positive = charge)
        power_kw = -K_droop * 1000 * frequency_error  # Convert MW to kW

        # Clamp to inverter rating
        power_kw = np.clip(power_kw, -self.max_power_kw, self.max_power_kw)

        return power_kw

# Example: Grid frequency drops to 59.95 Hz (underfrequency)
v2g = V2G_FrequencyRegulation()
power = v2g.compute_power_command(59.95)
print(f"Discharge {-power:.2f} kW to support grid")  # Vehicle discharges to add power
```

### Virtual Power Plant (VPP)

Aggregate fleet of EVs to act as distributed energy resource:

```python
class VirtualPowerPlant:
    def __init__(self):
        self.vehicles = []
        self.total_capacity_kwh = 0
        self.total_power_kw = 0

    def register_vehicle(self, vehicle):
        """Add vehicle to VPP"""
        self.vehicles.append(vehicle)
        self.total_capacity_kwh += vehicle.battery_capacity_kwh
        self.total_power_kw += vehicle.max_discharge_kw

    def dispatch_power(self, target_power_kw, duration_hours):
        """
        Dispatch power from fleet to grid

        Optimization objective:
        - Minimize impact on individual vehicle SOC
        - Balance wear across fleet
        - Respect SOC limits (keep above 20%)
        """
        import cvxpy as cp

        N = len(self.vehicles)

        # Decision variable: power from each vehicle
        P = cp.Variable(N, nonneg=True)

        # Objective: minimize variance (fair distribution)
        mean_power = target_power_kw / N
        objective = cp.sum_squares(P - mean_power)

        # Constraints
        constraints = []

        # 1. Total power meets target
        constraints.append(cp.sum(P) == target_power_kw)

        # 2. Each vehicle within power limit
        for i, vehicle in enumerate(self.vehicles):
            constraints.append(P[i] <= vehicle.max_discharge_kw)

        # 3. Each vehicle has enough energy
        for i, vehicle in enumerate(self.vehicles):
            soc = vehicle.get_SOC()
            capacity = vehicle.battery_capacity_kwh
            available_energy = (soc - 20) / 100 * capacity  # Keep above 20% SOC

            # Energy = Power × Time
            constraints.append(P[i] * duration_hours <= available_energy)

        # Solve
        problem = cp.Problem(cp.Minimize(objective), constraints)
        problem.solve()

        # Dispatch commands
        dispatch = {}
        for i, vehicle in enumerate(self.vehicles):
            dispatch[vehicle.id] = P.value[i]

        return dispatch

# Example usage
vpp = VirtualPowerPlant()
vpp.register_vehicle(Vehicle(id=1, capacity_kwh=75, max_discharge_kw=10, soc=80))
vpp.register_vehicle(Vehicle(id=2, capacity_kwh=60, max_discharge_kw=7, soc=90))
# ... 1000+ vehicles

dispatch = vpp.dispatch_power(target_power_kw=5000, duration_hours=2)
print(f"Dispatching {len(dispatch)} vehicles to provide {sum(dispatch.values()):.0f} kW")
```

## Bidirectional Power Flow Control

Seamless transition between charging (G2V) and discharging (V2G):

```python
class BidirectionalCharger:
    def __init__(self):
        self.mode = 'IDLE'  # IDLE, CHARGING, DISCHARGING
        self.target_power = 0.0

    def transition_to_discharge(self, target_power_kw):
        """Switch from charging to discharging"""
        if self.mode == 'CHARGING':
            # Step 1: Ramp down charging current to zero
            self.ramp_power(current=self.target_power, target=0.0, rate=5.0)  # 5 kW/s

            # Step 2: Open charge contactor
            self.open_contactor()

            # Step 3: Reverse inverter operation (DC→AC)
            self.configure_inverter(mode='DISCHARGE')

            # Step 4: Close discharge contactor
            self.close_contactor()

            # Step 5: Ramp up discharge current
            self.ramp_power(current=0.0, target=-target_power_kw, rate=5.0)

        self.mode = 'DISCHARGING'
        self.target_power = -target_power_kw

    def ramp_power(self, current, target, rate):
        """Gradually change power to avoid transients"""
        step = 0.1  # seconds
        while abs(current - target) > 0.1:
            if current < target:
                current = min(current + rate * step, target)
            else:
                current = max(current - rate * step, target)

            self.set_power(current)
            time.sleep(step)
```

## Smart Charging Optimization Algorithms

### Dynamic Programming for Optimal Charging

```python
def dynamic_programming_charging(arrival_time, departure_time, energy_needed,
                                 electricity_prices, max_power):
    """
    Find optimal charging schedule to minimize cost

    State: (time, energy_delivered)
    Decision: power_at_time
    Cost: power × price
    """
    T = departure_time - arrival_time
    E_target = energy_needed
    P_max = max_power

    # DP table: cost[time][energy]
    # Discretize energy (1 kWh steps)
    energy_steps = int(E_target) + 1
    INF = float('inf')
    cost = [[INF] * energy_steps for _ in range(T + 1)]
    policy = [[0] * energy_steps for _ in range(T + 1)]

    # Base case: at time 0, energy delivered = 0, cost = 0
    cost[0][0] = 0

    # Fill DP table
    for t in range(T):
        for e in range(energy_steps):
            if cost[t][e] == INF:
                continue

            # Try different power levels
            for p in np.arange(0, P_max + 0.1, 0.5):  # 0.5 kW steps
                e_new = min(int(e + p), energy_steps - 1)  # Energy delivered
                c_new = cost[t][e] + p * electricity_prices[arrival_time + t]

                if c_new < cost[t + 1][e_new]:
                    cost[t + 1][e_new] = c_new
                    policy[t + 1][e_new] = p

    # Backtrack to find optimal schedule
    schedule = []
    e = energy_steps - 1  # Must deliver full energy
    for t in reversed(range(1, T + 1)):
        p = policy[t][e]
        schedule.append(p)
        e -= int(p)

    schedule.reverse()

    return schedule, cost[T][energy_steps - 1]

# Example
prices = [0.10] * 6 + [0.20] * 12 + [0.12] * 6  # Off-peak, peak, shoulder
schedule, total_cost = dynamic_programming_charging(
    arrival_time=18,
    departure_time=7 + 24,  # Next morning
    energy_needed=50,  # kWh
    electricity_prices=prices,
    max_power=7.2
)

print(f"Optimal cost: ${total_cost:.2f}")
print(f"Charge primarily during: {np.argmax(schedule) + 18}:00")
```

### Reinforcement Learning for Adaptive Charging

```python
import torch
import torch.nn as nn

class ChargingPolicyNetwork(nn.Module):
    def __init__(self, state_dim=5, action_dim=1):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(state_dim, 64),
            nn.ReLU(),
            nn.Linear(64, 64),
            nn.ReLU(),
            nn.Linear(64, action_dim),
            nn.Sigmoid()  # Output power in [0, 1] (scale to max power)
        )

    def forward(self, state):
        return self.net(state)

class RL_ChargingAgent:
    def __init__(self):
        self.policy = ChargingPolicyNetwork()
        self.optimizer = torch.optim.Adam(self.policy.parameters(), lr=0.001)

    def get_action(self, state):
        """
        state: [current_SOC, time_until_departure, electricity_price, grid_load, temperature]
        """
        state_tensor = torch.FloatTensor(state)
        with torch.no_grad():
            power_fraction = self.policy(state_tensor).item()

        max_power = 7.2  # kW
        return power_fraction * max_power

    def train(self, experience_buffer):
        """Update policy using experience"""
        for experience in experience_buffer:
            state, action, reward, next_state = experience

            # Compute loss (policy gradient)
            state_tensor = torch.FloatTensor(state)
            action_pred = self.policy(state_tensor)

            # Reward: negative cost (maximize reward = minimize cost)
            loss = -reward * torch.log(action_pred)

            self.optimizer.zero_grad()
            loss.backward()
            self.optimizer.step()

# Agent learns optimal charging policy from experience
agent = RL_ChargingAgent()
for episode in range(1000):
    state = get_initial_state()
    total_reward = 0

    while not done:
        action = agent.get_action(state)
        next_state, reward, done = step(state, action)
        experience_buffer.append((state, action, reward, next_state))
        total_reward += reward
        state = next_state

    if episode % 100 == 0:
        agent.train(experience_buffer)
        print(f"Episode {episode}, Total reward: {total_reward:.2f}")
```

## Wireless Charging Resonant Coupling

Inductive power transfer for contactless charging.

### Resonant Circuit Design

```
Primary Coil:                  Secondary Coil:
    ┌─ Cp ─┐                      ┌─ Cs ─┐
    │      │                      │      │
AC Source ─ Lp ────(air gap)──── Ls ─── Load (Battery)
    │      │                      │      │
    └──────┘                      └──────┘

Resonant frequency:
f_resonant = 1 / (2π√(L × C))

Typical: 85 kHz (SAE J2954 standard)
```

### Efficiency Optimization

```python
import numpy as np

class WirelessChargingSystem:
    def __init__(self, frequency=85000):
        self.f = frequency
        self.omega = 2 * np.pi * frequency

        # Coil parameters
        self.Lp = 100e-6  # Primary inductance (H)
        self.Ls = 100e-6  # Secondary inductance (H)
        self.M = 20e-6    # Mutual inductance (H), depends on gap/alignment
        self.Rp = 0.1     # Primary resistance (Ω)
        self.Rs = 0.1     # Secondary resistance (Ω)

        # Resonant capacitors
        self.Cp = 1 / (self.omega**2 * self.Lp)
        self.Cs = 1 / (self.omega**2 * self.Ls)

    def compute_efficiency(self, gap_mm, misalignment_mm):
        """
        Efficiency depends on coupling coefficient k = M / √(Lp × Ls)
        """
        # Mutual inductance decreases with gap and misalignment
        M = self.M * (150 / (gap_mm + 150)) * np.exp(-misalignment_mm / 50)

        k = M / np.sqrt(self.Lp * self.Ls)  # Coupling coefficient

        # Quality factors
        Qp = (self.omega * self.Lp) / self.Rp
        Qs = (self.omega * self.Ls) / self.Rs

        # Efficiency (approximate)
        efficiency = (k**2 * Qp * Qs) / (1 + k**2 * Qp * Qs)

        return efficiency

    def simulate_charging_session(self):
        """Simulate wireless charging with varying gap"""
        gaps = np.linspace(100, 200, 100)  # 100-200 mm gap
        efficiencies = [self.compute_efficiency(gap, misalignment_mm=0) for gap in gaps]

        import matplotlib.pyplot as plt
        plt.plot(gaps, np.array(efficiencies) * 100)
        plt.xlabel('Air Gap (mm)')
        plt.ylabel('Efficiency (%)')
        plt.title('Wireless Charging Efficiency vs Gap')
        plt.grid(True)
        plt.show()

# Example
wpt = WirelessChargingSystem()
eff = wpt.compute_efficiency(gap_mm=150, misalignment_mm=0)
print(f"Efficiency at 150mm gap: {eff*100:.1f}%")  # Typical: 90-95%
```

### SAE J2954 Wireless Charging Standard

```
Power levels:
- WPT1: 3.7 kW (Light-duty vehicles)
- WPT2: 7.7 kW (Primary target)
- WPT3: 11.1 kW (Higher power)
- WPT4: 22 kW (Future)

Ground clearance: 100-250 mm
Frequency: 85 kHz ± 2 kHz
Efficiency target: >85% (grid to battery)
Foreign object detection: Required (prevent heating of metal objects)
```

## Grid-Integrated Energy Storage

EVs as distributed storage for renewable integration:

```python
class Grid_EnergyStorage:
    def __init__(self, solar_power_forecast, load_forecast, battery_fleet):
        self.solar = solar_power_forecast  # kW over 24 hours
        self.load = load_forecast
        self.fleet = battery_fleet

    def optimize_storage(self):
        """Optimize charging/discharging to balance solar + load"""
        import cvxpy as cp

        T = 24  # hours

        # Decision variables
        P_charge = cp.Variable(T, nonneg=True)  # Grid → EV
        P_discharge = cp.Variable(T, nonneg=True)  # EV → Grid
        E_stored = cp.Variable(T + 1, nonneg=True)  # Energy in fleet

        # Parameters
        solar = cp.Parameter(T, value=self.solar)
        load = cp.Parameter(T, value=self.load)

        # Objective: minimize grid import
        grid_import = load - solar + P_charge - P_discharge
        objective = cp.sum(cp.pos(grid_import))  # Only count imports

        # Constraints
        constraints = []

        # Energy dynamics
        constraints.append(E_stored[0] == self.fleet.total_energy_kwh * 0.5)  # Start at 50%
        for t in range(T):
            constraints.append(
                E_stored[t + 1] == E_stored[t] + P_charge[t] - P_discharge[t]
            )

        # Fleet capacity limits
        constraints.append(E_stored <= self.fleet.total_capacity_kwh * 0.9)  # Max 90%
        constraints.append(E_stored >= self.fleet.total_capacity_kwh * 0.2)  # Min 20%

        # Power limits
        constraints.append(P_charge <= self.fleet.total_power_kw)
        constraints.append(P_discharge <= self.fleet.total_power_kw)

        # Solve
        problem = cp.Problem(cp.Minimize(objective), constraints)
        problem.solve()

        return P_charge.value, P_discharge.value, E_stored.value

# Example
solar_forecast = np.array([0]*6 + [5,10,15,20,25,30,30,25,20,10,5] + [0]*6)  # kW
load_forecast = np.array([50]*24)  # Constant 50 kW load

optimizer = Grid_EnergyStorage(solar_forecast, load_forecast, fleet)
charge_schedule, discharge_schedule, energy = optimizer.optimize_storage()

print("Peak shaving achieved by EV fleet:")
print(f"Max grid import reduced from {max(load_forecast - solar_forecast):.0f} kW to {max(load_forecast - solar_forecast + charge_schedule - discharge_schedule):.0f} kW")
```

## Next Steps

- **Research**: Ultra-fast charging (>1 MW), extreme fast charging battery chemistry
- **Standards**: ISO 15118-20 (bidirectional), IEC 61980 (wireless power transfer)
- **Deployment**: Megawatt charging system (MCS) for heavy trucks, dynamic wireless charging (in-road)

## References

- SAE J2954: Wireless Power Transfer for Light-Duty Plug-In/Electric Vehicles
- ISO 15118-20: Vehicle to grid communication interface (V2G)
- IEC 61980-1: Electric vehicle wireless power transfer systems
- Li et al., "Vehicle-to-Grid: Architecture, Standards, and Future Directions", IEEE Trans 2019

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: Grid integration engineers, V2G researchers, wireless charging developers

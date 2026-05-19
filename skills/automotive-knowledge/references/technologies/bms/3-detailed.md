# Battery Management System - Detailed Implementation

## Extended Kalman Filter for SOC Estimation

The EKF fuses coulomb counting with voltage measurements to continuously correct SOC estimates.

### State Space Model

```
State vector: x = [SOC, V_RC1, V_RC2]^T

State equation (prediction):
SOC(k+1) = SOC(k) - (η × I × Δt) / Q_nom
V_RC1(k+1) = exp(-Δt/(R1×C1)) × V_RC1(k) + R1 × (1 - exp(-Δt/(R1×C1))) × I(k)
V_RC2(k+1) = exp(-Δt/(R2×C2)) × V_RC2(k) + R2 × (1 - exp(-Δt/(R2×C2))) × I(k)

Measurement equation:
V_terminal = OCV(SOC) - I × R0 - V_RC1 - V_RC2 + v

where:
- η: Coulombic efficiency (0.98-1.0)
- Q_nom: Nominal capacity (Ah)
- v: Measurement noise
```

### Complete Python Implementation

```python
import numpy as np
from scipy.interpolate import interp1d

class SOC_EKF:
    def __init__(self, Q_nom=75.0, ocv_soc_table=None):
        """
        Q_nom: Nominal capacity in Ah
        ocv_soc_table: 2D array [[SOC%, OCV_V], ...] for lookup
        """
        self.Q_nom = Q_nom
        self.eta = 0.99  # Coulombic efficiency

        # ECM parameters (need to be identified from pulse tests)
        self.R0 = 0.005  # Ohms
        self.R1 = 0.002
        self.C1 = 5000.0  # Farads
        self.R2 = 0.003
        self.C2 = 10000.0

        # OCV-SOC curve (interpolation function)
        if ocv_soc_table is not None:
            self.ocv_func = interp1d(ocv_soc_table[:, 0], ocv_soc_table[:, 1],
                                     kind='cubic', fill_value='extrapolate')
        else:
            # Default NMC curve (simplified)
            soc = np.array([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
            ocv = np.array([3.0, 3.4, 3.55, 3.62, 3.68, 3.72, 3.76, 3.82, 3.92, 4.08, 4.2])
            self.ocv_func = interp1d(soc, ocv, kind='cubic', fill_value='extrapolate')

        # State [SOC, V_RC1, V_RC2]
        self.x = np.array([50.0, 0.0, 0.0])  # Initial guess: 50% SOC

        # State covariance
        self.P = np.diag([100.0, 0.01, 0.01])  # High initial SOC uncertainty

        # Process noise covariance
        self.Q = np.diag([0.1, 0.0001, 0.0001])

        # Measurement noise covariance
        self.R = np.array([[0.01]])  # 100mV voltage measurement noise

    def predict(self, current, dt):
        """
        Prediction step
        current: Battery current in A (positive = discharge)
        dt: Time step in seconds
        """
        SOC, V_RC1, V_RC2 = self.x

        # Linearized state transition matrix
        F = np.array([
            [1, 0, 0],
            [0, np.exp(-dt/(self.R1*self.C1)), 0],
            [0, 0, np.exp(-dt/(self.R2*self.C2))]
        ])

        # State update
        SOC_new = SOC - (self.eta * current * dt / 3600) / self.Q_nom * 100  # % change
        V_RC1_new = np.exp(-dt/(self.R1*self.C1)) * V_RC1 + \
                    self.R1 * (1 - np.exp(-dt/(self.R1*self.C1))) * current
        V_RC2_new = np.exp(-dt/(self.R2*self.C2)) * V_RC2 + \
                    self.R2 * (1 - np.exp(-dt/(self.R2*self.C2))) * current

        self.x = np.array([SOC_new, V_RC1_new, V_RC2_new])

        # Covariance update
        self.P = F @ self.P @ F.T + self.Q

        # Clamp SOC to [0, 100]
        self.x[0] = np.clip(self.x[0], 0, 100)

    def update(self, voltage_measured, current):
        """
        Update step with voltage measurement
        voltage_measured: Measured terminal voltage (V)
        current: Battery current (A)
        """
        SOC, V_RC1, V_RC2 = self.x

        # Predicted measurement
        OCV = self.ocv_func(SOC)
        V_predicted = OCV - current * self.R0 - V_RC1 - V_RC2

        # Measurement Jacobian
        # H = ∂h/∂x where h(x) = OCV(SOC) - I*R0 - V_RC1 - V_RC2
        dOCV_dSOC = self._dOCV_dSOC(SOC)
        H = np.array([[dOCV_dSOC, -1.0, -1.0]])

        # Innovation
        y = voltage_measured - V_predicted

        # Innovation covariance
        S = H @ self.P @ H.T + self.R

        # Kalman gain
        K = self.P @ H.T / S

        # State update
        self.x = self.x + K.flatten() * y

        # Covariance update
        I_KH = np.eye(3) - K @ H
        self.P = I_KH @ self.P @ I_KH.T + K @ self.R @ K.T  # Joseph form for numerical stability

        # Clamp SOC
        self.x[0] = np.clip(self.x[0], 0, 100)

    def _dOCV_dSOC(self, SOC):
        """Numerical gradient of OCV curve"""
        epsilon = 0.1
        OCV_plus = self.ocv_func(SOC + epsilon)
        OCV_minus = self.ocv_func(SOC - epsilon)
        return (OCV_plus - OCV_minus) / (2 * epsilon)

    def get_SOC(self):
        """Return current SOC estimate"""
        return self.x[0]

    def get_covariance(self):
        """Return SOC estimation uncertainty (standard deviation)"""
        return np.sqrt(self.P[0, 0])
```

### Usage Example

```python
# Initialize EKF
ekf = SOC_EKF(Q_nom=75.0)

# Simulation loop
dt = 1.0  # 1 second time step
for t in range(3600):  # 1 hour simulation
    # Read sensor data
    current = 20.0  # 20A discharge
    voltage = read_voltage_sensor()

    # Predict step
    ekf.predict(current, dt)

    # Update step (every measurement)
    ekf.update(voltage, current)

    # Get SOC estimate
    soc = ekf.get_SOC()
    uncertainty = ekf.get_covariance()

    print(f"Time: {t}s, SOC: {soc:.2f}%, Uncertainty: ±{uncertainty:.2f}%")
```

## Dual EKF for SOC and SOH Estimation

Estimate both SOC and capacity (SOH) simultaneously.

### Augmented State Vector

```
State: x = [SOC, V_RC1, V_RC2, Q_capacity]^T

SOH is derived from Q_capacity:
SOH = (Q_capacity / Q_nominal) × 100%
```

### Implementation

```python
class Dual_EKF(SOC_EKF):
    def __init__(self, Q_nom=75.0, ocv_soc_table=None):
        super().__init__(Q_nom, ocv_soc_table)

        # Augment state with capacity
        self.x = np.array([50.0, 0.0, 0.0, Q_nom])  # [SOC, V_RC1, V_RC2, Q_actual]

        # Augment covariances
        self.P = np.diag([100.0, 0.01, 0.01, 10.0])  # Capacity uncertainty
        self.Q = np.diag([0.1, 0.0001, 0.0001, 1e-6])  # Capacity evolves slowly

    def predict(self, current, dt):
        """Predict with capacity as state"""
        SOC, V_RC1, V_RC2, Q = self.x

        # State transition matrix (capacity is constant in short term)
        F = np.array([
            [1, 0, 0, -(self.eta * current * dt / 3600) / Q**2 * 100],  # dSOC/dQ
            [0, np.exp(-dt/(self.R1*self.C1)), 0, 0],
            [0, 0, np.exp(-dt/(self.R2*self.C2)), 0],
            [0, 0, 0, 1]  # Capacity unchanged
        ])

        # State update
        SOC_new = SOC - (self.eta * current * dt / 3600) / Q * 100
        V_RC1_new = np.exp(-dt/(self.R1*self.C1)) * V_RC1 + \
                    self.R1 * (1 - np.exp(-dt/(self.R1*self.C1))) * current
        V_RC2_new = np.exp(-dt/(self.R2*self.C2)) * V_RC2 + \
                    self.R2 * (1 - np.exp(-dt/(self.R2*self.C2))) * current
        Q_new = Q  # Capacity evolves slowly (updated via measurements)

        self.x = np.array([SOC_new, V_RC1_new, V_RC2_new, Q_new])

        # Covariance update
        self.P = F @ self.P @ F.T + self.Q

        # Constraints
        self.x[0] = np.clip(self.x[0], 0, 100)  # SOC
        self.x[3] = np.clip(self.x[3], 0.5 * self.Q_nom, 1.1 * self.Q_nom)  # Capacity

    def update(self, voltage_measured, current):
        """Update with augmented Jacobian"""
        SOC, V_RC1, V_RC2, Q = self.x

        # Predicted measurement
        OCV = self.ocv_func(SOC)
        V_predicted = OCV - current * self.R0 - V_RC1 - V_RC2

        # Measurement Jacobian (includes capacity term)
        dOCV_dSOC = self._dOCV_dSOC(SOC)
        H = np.array([[dOCV_dSOC, -1.0, -1.0, 0.0]])  # Voltage doesn't directly depend on Q

        # Innovation
        y = voltage_measured - V_predicted

        # Innovation covariance
        S = H @ self.P @ H.T + self.R

        # Kalman gain
        K = self.P @ H.T / S

        # State update
        self.x = self.x + K.flatten() * y

        # Covariance update (Joseph form)
        I_KH = np.eye(4) - K @ H
        self.P = I_KH @ self.P @ I_KH.T + K @ self.R @ K.T

        # Constraints
        self.x[0] = np.clip(self.x[0], 0, 100)
        self.x[3] = np.clip(self.x[3], 0.5 * self.Q_nom, 1.1 * self.Q_nom)

    def get_SOH(self):
        """Return SOH based on capacity estimate"""
        return (self.x[3] / self.Q_nom) * 100.0
```

## Parameter Identification from Pulse Test

Extract ECM parameters from experimental data.

### Pulse Test Procedure

```
1. Charge battery to 50% SOC, rest for 2 hours
2. Apply 1C discharge pulse for 10 seconds
3. Rest for 40 seconds (observe voltage relaxation)
4. Apply 1C charge pulse for 10 seconds
5. Rest for 40 seconds
6. Repeat at different SOC levels (10%, 30%, 50%, 70%, 90%)
```

### Parameter Extraction

```python
import numpy as np
from scipy.optimize import curve_fit

def extract_ECM_parameters(time, voltage, current, pulse_start, pulse_end):
    """
    Extract R0, R1, C1 from pulse test data
    time: Time array (seconds)
    voltage: Voltage array (V)
    current: Current array (A)
    pulse_start: Index where pulse begins
    pulse_end: Index where pulse ends
    """
    # R0: Instantaneous voltage drop
    V_before_pulse = voltage[pulse_start - 1]
    V_after_pulse = voltage[pulse_start + 1]  # 1 sample after (assume fast sampling)
    I_pulse = current[pulse_start]

    R0 = abs(V_after_pulse - V_before_pulse) / abs(I_pulse)

    # R1, C1: Fit exponential relaxation after pulse
    t_relax = time[pulse_end:pulse_end+40] - time[pulse_end]
    V_relax = voltage[pulse_end:pulse_end+40]
    V_steady = voltage[pulse_end + 40]  # Assume settled

    def exp_decay(t, V0, tau):
        return V_steady + V0 * np.exp(-t / tau)

    # Fit
    popt, _ = curve_fit(exp_decay, t_relax, V_relax, p0=[0.1, 10.0])
    V0, tau = popt

    R1 = abs(V0) / abs(I_pulse)
    C1 = tau / R1

    return R0, R1, C1

# Example usage
R0, R1, C1 = extract_ECM_parameters(time_data, voltage_data, current_data, 100, 200)
print(f"R0: {R0*1000:.2f} mΩ, R1: {R1*1000:.2f} mΩ, C1: {C1:.0f} F")
```

## C++ Implementation for Embedded BMS

```cpp
#include <Eigen/Dense>
#include <cmath>

class SOC_EKF_Embedded {
public:
    SOC_EKF_Embedded(double Q_nom, double R0, double R1, double C1)
        : Q_nom_(Q_nom), R0_(R0), R1_(R1), C1_(C1) {
        // Initialize state [SOC, V_RC1]
        x_ << 50.0, 0.0;

        // Initialize covariance
        P_ << 100.0, 0.0,
              0.0,   0.01;

        // Process noise
        Q_ << 0.1,    0.0,
              0.0,    0.0001;

        // Measurement noise
        R_ << 0.01;  // 100mV
    }

    void predict(double current, double dt) {
        double SOC = x_(0);
        double V_RC1 = x_(1);

        // State transition
        double exp_term = std::exp(-dt / (R1_ * C1_));
        Eigen::Matrix2d F;
        F << 1.0, 0.0,
             0.0, exp_term;

        // State update
        x_(0) = SOC - (eta_ * current * dt / 3600.0) / Q_nom_ * 100.0;
        x_(1) = exp_term * V_RC1 + R1_ * (1.0 - exp_term) * current;

        // Covariance update
        P_ = F * P_ * F.transpose() + Q_;

        // Clamp SOC
        x_(0) = std::max(0.0, std::min(100.0, x_(0)));
    }

    void update(double voltage_measured, double current) {
        double SOC = x_(0);
        double V_RC1 = x_(1);

        // Predicted measurement
        double OCV = getOCV(SOC);
        double V_pred = OCV - current * R0_ - V_RC1;

        // Measurement Jacobian
        Eigen::Matrix<double, 1, 2> H;
        H << dOCV_dSOC(SOC), -1.0;

        // Innovation
        double y = voltage_measured - V_pred;

        // Innovation covariance
        double S = (H * P_ * H.transpose())(0) + R_(0);

        // Kalman gain
        Eigen::Vector2d K = P_ * H.transpose() / S;

        // State update
        x_ = x_ + K * y;

        // Covariance update
        Eigen::Matrix2d I_KH = Eigen::Matrix2d::Identity() - K * H;
        P_ = I_KH * P_ * I_KH.transpose() + K * R_ * K.transpose();

        // Clamp SOC
        x_(0) = std::max(0.0, std::min(100.0, x_(0)));
    }

    double getSOC() const { return x_(0); }

private:
    double Q_nom_, R0_, R1_, C1_;
    double eta_ = 0.99;
    Eigen::Vector2d x_;
    Eigen::Matrix2d P_, Q_;
    Eigen::Matrix<double, 1, 1> R_;

    double getOCV(double SOC) const {
        // Simplified NMC OCV curve (linear interpolation)
        // In production, use lookup table
        return 3.0 + (4.2 - 3.0) * (SOC / 100.0);
    }

    double dOCV_dSOC(double SOC) const {
        // Numerical gradient
        double epsilon = 0.1;
        return (getOCV(SOC + epsilon) - getOCV(SOC - epsilon)) / (2 * epsilon);
    }
};
```

## Next Steps

- **Level 4**: Cell datasheet parameters, voltage curves, protocol specifications
- **Level 5**: Neural network SOC estimation, physics-informed NNs, digital twin BMS

## References

- Plett, G.L. "Battery Management Systems, Volume II: Equivalent-Circuit Methods", Artech House 2015
- Hu, X. et al. "A comparative study of equivalent circuit models for Li-ion batteries", Journal of Power Sources 2012
- Simon, D. "Optimal State Estimation: Kalman, H-Infinity, and Nonlinear Approaches", Wiley 2006

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: BMS software engineers, battery algorithm developers, embedded engineers

# Digital Twin - Level 3: Detailed Implementation

> Audience: Developers and testers implementing digital twin systems
> Purpose: Code examples, data models, and implementation patterns

## Battery Digital Twin Implementation

### Equivalent Circuit Model

```python
import numpy as np
from dataclasses import dataclass

@dataclass
class BatteryParameters:
    capacity_ah: float = 100.0
    r0_ohm: float = 0.01        # Internal resistance
    r1_ohm: float = 0.005       # RC pair 1 resistance
    c1_f: float = 1000.0        # RC pair 1 capacitance
    ocv_soc_table: np.ndarray = None  # OCV vs SOC lookup

class BatteryDigitalTwin:
    def __init__(self, params: BatteryParameters):
        self.params = params
        self.soc = 1.0
        self.v_rc1 = 0.0
        self.temperature_c = 25.0
        self.cycle_count = 0
        self.soh = 1.0
        
    def update(self, current_a: float, dt_s: float) -> dict:
        # Coulomb counting for SOC
        delta_soc = (current_a * dt_s) / (self.params.capacity_ah * 3600)
        self.soc = np.clip(self.soc - delta_soc, 0.0, 1.0)
        
        # RC circuit dynamics
        tau = self.params.r1_ohm * self.params.c1_f
        self.v_rc1 = self.v_rc1 * np.exp(-dt_s / tau) + \
                     self.params.r1_ohm * current_a * (1 - np.exp(-dt_s / tau))
        
        # Terminal voltage
        ocv = np.interp(self.soc, self.params.ocv_soc_table[:, 0],
                        self.params.ocv_soc_table[:, 1])
        v_terminal = ocv - current_a * self.params.r0_ohm - self.v_rc1
        
        return {
            "soc": self.soc,
            "voltage_v": v_terminal,
            "ocv_v": ocv,
            "power_w": v_terminal * current_a,
            "temperature_c": self.temperature_c
        }
    
    def predict_soh(self, future_days: int = 365) -> float:
        # Simplified capacity fade model
        cycles_per_day = 1.2
        future_cycles = future_days * cycles_per_day
        total_cycles = self.cycle_count + future_cycles
        # Empirical capacity fade: C/C0 = 1 - k * sqrt(cycles)
        k = 0.002  # Degradation coefficient
        predicted_soh = 1.0 - k * np.sqrt(total_cycles)
        return max(predicted_soh, 0.0)
```

### Real-Time Data Ingestion

```python
from azure.iot.device import IoTHubDeviceClient
import json

class VehicleTelemetryIngester:
    def __init__(self, connection_string: str):
        self.client = IoTHubDeviceClient.create_from_connection_string(
            connection_string)
        self.twin = BatteryDigitalTwin(BatteryParameters())
        
    def process_telemetry(self, message: dict):
        # Update twin state
        state = self.twin.update(
            current_a=message["pack_current_a"],
            dt_s=message["sample_interval_s"]
        )
        
        # Anomaly detection
        if abs(state["voltage_v"] - message["measured_voltage_v"]) > 0.5:
            self.raise_alert("VOLTAGE_MODEL_DEVIATION", {
                "predicted": state["voltage_v"],
                "measured": message["measured_voltage_v"],
                "delta": abs(state["voltage_v"] - message["measured_voltage_v"])
            })
        
        # Store state
        self.store_twin_state(message["vin"], state)
```

### REST API for Twin Access

```python
from fastapi import FastAPI, HTTPException

app = FastAPI(title="Digital Twin API")

@app.get("/api/v1/vehicles/{vin}/twin")
async def get_vehicle_twin(vin: str):
    twin = await twin_store.get(vin)
    if not twin:
        raise HTTPException(404, f"No twin found for VIN {vin}")
    return {
        "vin": vin,
        "state": twin.current_state,
        "predictions": twin.predictions,
        "last_updated": twin.last_updated
    }

@app.get("/api/v1/vehicles/{vin}/twin/battery/prediction")
async def get_battery_prediction(vin: str, horizon_days: int = 365):
    twin = await twin_store.get(vin)
    prediction = twin.battery_model.predict_soh(horizon_days)
    return {
        "vin": vin,
        "current_soh_percent": twin.battery_model.soh * 100,
        "predicted_soh_percent": prediction * 100,
        "prediction_horizon_days": horizon_days,
        "estimated_eol_date": twin.estimate_eol_date()
    }
```

## Summary

Digital twin implementation combines physics-based models with real-time
data ingestion, anomaly detection, and predictive analytics. The battery
equivalent circuit model provides a foundation for SOC/SOH estimation
that can be enhanced with ML for improved accuracy.

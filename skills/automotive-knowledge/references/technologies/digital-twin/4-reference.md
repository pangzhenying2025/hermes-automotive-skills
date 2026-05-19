# Digital Twin - Level 4: Reference

> Audience: Developers needing quick lookup for digital twin configurations
> Purpose: Rapid reference for data models, APIs, and configuration parameters

## Telemetry Signal Catalog

| Signal Name | Unit | Range | Sample Rate | Priority |
|-------------|------|-------|-------------|----------|
| pack_voltage_v | V | 200-800 | 1 Hz | High |
| pack_current_a | A | -500 to 500 | 10 Hz | High |
| cell_voltage_mv | mV | 2500-4300 | 1 Hz | High |
| cell_temp_c | degC | -20 to 60 | 0.1 Hz | Medium |
| soc_percent | % | 0-100 | 1 Hz | High |
| soh_percent | % | 0-100 | 0.001 Hz | Medium |
| odometer_km | km | 0-999999 | 0.1 Hz | Low |
| vehicle_speed_kmh | km/h | 0-250 | 10 Hz | Medium |
| ambient_temp_c | degC | -40 to 60 | 0.1 Hz | Low |
| charging_status | enum | 0-4 | 1 Hz | High |

## Battery Model Parameters

| Parameter | Symbol | Unit | Typical Range | Source |
|-----------|--------|------|--------------|--------|
| Nominal capacity | Q_nom | Ah | 50-200 | Datasheet |
| Internal resistance | R0 | mOhm | 5-50 | EIS measurement |
| RC resistance 1 | R1 | mOhm | 2-20 | Pulse test |
| RC capacitance 1 | C1 | F | 500-5000 | Pulse test |
| OCV table | OCV(SOC) | V vs % | 2.5-4.3V | Slow discharge |
| Temp coefficient | dR/dT | mOhm/K | -0.1 to 0.5 | Multi-temp test |
| Degradation rate | k_deg | -/sqrt(cyc) | 0.001-0.005 | Aging test |

## Cloud Service Mapping

| Component | Azure | AWS | GCP |
|-----------|-------|-----|-----|
| IoT Ingestion | IoT Hub | IoT Core | Cloud IoT |
| Stream Processing | Stream Analytics | Kinesis | Dataflow |
| Time-Series DB | ADX / Cosmos DB | Timestream | BigTable |
| Object Storage | Blob Storage | S3 | Cloud Storage |
| ML Training | Azure ML | SageMaker | Vertex AI |
| ML Inference | Azure ML Endpoints | SageMaker RT | Vertex |
| API Gateway | API Management | API Gateway | Apigee |
| Event Bus | Event Grid | EventBridge | Pub/Sub |
| Functions | Azure Functions | Lambda | Cloud Functions |

## Data Retention Policy

| Data Type | Hot Storage | Warm Storage | Cold Storage |
|-----------|------------|-------------|-------------|
| Real-time telemetry | 7 days | 90 days | 5 years |
| Aggregated metrics | 30 days | 1 year | 10 years |
| Predictions | 30 days | 1 year | 5 years |
| Alerts/Events | 90 days | 2 years | Vehicle lifetime |
| Raw sensor data | 24 hours | 30 days | 1 year |

## API Endpoints Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| /api/v1/vehicles/{vin}/twin | GET | Get current twin state |
| /api/v1/vehicles/{vin}/twin/history | GET | Historical state |
| /api/v1/vehicles/{vin}/battery/soh | GET | Battery health |
| /api/v1/vehicles/{vin}/battery/prediction | GET | SOH prediction |
| /api/v1/vehicles/{vin}/alerts | GET | Active alerts |
| /api/v1/fleet/{id}/analytics | GET | Fleet analytics |
| /api/v1/fleet/{id}/vehicles | GET | Fleet vehicle list |

## Summary

This reference provides quick access to telemetry catalogs, model
parameters, cloud service mappings, and API endpoints for digital
twin development and operations.

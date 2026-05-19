#!/usr/bin/env bash
# telemetry-ingest.sh - Configure telemetry ingestion pipeline
# Supports time-series databases: InfluxDB, TimescaleDB, Azure Data Explorer

set -euo pipefail

# Default values
BACKEND="influxdb"
CONFIG_FILE="telemetry-ingest.yaml"
DRY_RUN=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Configure telemetry ingestion pipeline for vehicle time-series data.

Options:
    -b, --backend TYPE        Backend: influxdb, timescale, adx (default: influxdb)
    -c, --config FILE         Output config file (default: telemetry-ingest.yaml)
    -n, --dry-run             Generate config without deploying
    -h, --help                Show this help message

Backends:
    influxdb   - InfluxDB 2.x time-series database
    timescale  - TimescaleDB (PostgreSQL extension)
    adx        - Azure Data Explorer (Kusto)

Examples:
    # Generate InfluxDB configuration
    $0 -b influxdb

    # Generate TimescaleDB schema
    $0 -b timescale -c timescale-schema.sql

EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--backend) BACKEND="$2"; shift 2 ;;
        -c|--config) CONFIG_FILE="$2"; shift 2 ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo -e "${RED}Error: Unknown option $1${NC}"; usage ;;
    esac
done

echo -e "${BLUE}=== Telemetry Ingestion Pipeline ===${NC}"
echo "Backend: $BACKEND"
echo ""

case "$BACKEND" in
    influxdb)
        cat > "$CONFIG_FILE" <<'EOF'
# InfluxDB 2.x Telemetry Configuration

influxdb:
  url: "http://localhost:8086"
  org: "automotive"
  bucket: "vehicle-telemetry"
  token: "${INFLUXDB_TOKEN}"

# Data schema
measurements:
  - name: battery
    tags:
      - vin
      - battery_pack_id
    fields:
      - soc (float)
      - voltage (float)
      - current (float)
      - temperature (float)
      - soh (float)

  - name: location
    tags:
      - vin
    fields:
      - latitude (float)
      - longitude (float)
      - altitude (float)
      - speed (float)
      - heading (float)

  - name: drivetrain
    tags:
      - vin
    fields:
      - motor_speed (float)
      - motor_torque (float)
      - inverter_temp (float)
      - gear_position (integer)

  - name: thermal
    tags:
      - vin
      - component
    fields:
      - temperature (float)
      - coolant_flow (float)

# Retention policies
retention:
  - name: raw
    duration: 30d
    shard_duration: 1d

  - name: downsampled
    duration: 365d
    shard_duration: 7d

# Continuous queries for downsampling
continuous_queries:
  - name: cq_battery_1m
    query: |
      SELECT mean(soc) AS soc_mean,
             mean(voltage) AS voltage_mean,
             mean(current) AS current_mean,
             mean(temperature) AS temperature_mean
      INTO vehicle-telemetry.downsampled.battery_1m
      FROM vehicle-telemetry.raw.battery
      GROUP BY time(1m), vin

  - name: cq_location_1m
    query: |
      SELECT mean(speed) AS speed_mean,
             mean(latitude) AS lat_mean,
             mean(longitude) AS lon_mean
      INTO vehicle-telemetry.downsampled.location_1m
      FROM vehicle-telemetry.raw.location
      GROUP BY time(1m), vin
EOF

        echo -e "${GREEN}✓ InfluxDB configuration generated: $CONFIG_FILE${NC}"
        echo ""
        echo "Setup commands:"
        echo "  # Create bucket"
        echo "  influx bucket create -n vehicle-telemetry -r 30d"
        echo ""
        echo "  # Create API token"
        echo "  influx auth create --org automotive --all-access"
        ;;

    timescale)
        CONFIG_FILE="${CONFIG_FILE%.yaml}.sql"
        cat > "$CONFIG_FILE" <<'EOF'
-- TimescaleDB Telemetry Schema

-- Create database
CREATE DATABASE vehicle_telemetry;

\c vehicle_telemetry;

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Battery telemetry
CREATE TABLE battery (
    time TIMESTAMPTZ NOT NULL,
    vin VARCHAR(17) NOT NULL,
    battery_pack_id INTEGER,
    soc REAL,
    voltage REAL,
    current REAL,
    temperature REAL,
    soh REAL
);

SELECT create_hypertable('battery', 'time');

-- Location telemetry
CREATE TABLE location (
    time TIMESTAMPTZ NOT NULL,
    vin VARCHAR(17) NOT NULL,
    latitude REAL,
    longitude REAL,
    altitude REAL,
    speed REAL,
    heading REAL
);

SELECT create_hypertable('location', 'time');

-- Drivetrain telemetry
CREATE TABLE drivetrain (
    time TIMESTAMPTZ NOT NULL,
    vin VARCHAR(17) NOT NULL,
    motor_speed REAL,
    motor_torque REAL,
    inverter_temp REAL,
    gear_position INTEGER
);

SELECT create_hypertable('drivetrain', 'time');

-- Indexes for query performance
CREATE INDEX idx_battery_vin_time ON battery (vin, time DESC);
CREATE INDEX idx_location_vin_time ON location (vin, time DESC);
CREATE INDEX idx_drivetrain_vin_time ON drivetrain (vin, time DESC);

-- Continuous aggregates (1-minute)
CREATE MATERIALIZED VIEW battery_1m
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 minute', time) AS bucket,
    vin,
    AVG(soc) AS soc_avg,
    AVG(voltage) AS voltage_avg,
    AVG(current) AS current_avg,
    AVG(temperature) AS temp_avg
FROM battery
GROUP BY bucket, vin;

-- Retention policy (raw data 30 days, aggregates 1 year)
SELECT add_retention_policy('battery', INTERVAL '30 days');
SELECT add_retention_policy('battery_1m', INTERVAL '365 days');

-- Compression policy (compress after 7 days)
ALTER TABLE battery SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'vin'
);

SELECT add_compression_policy('battery', INTERVAL '7 days');
EOF

        echo -e "${GREEN}✓ TimescaleDB schema generated: $CONFIG_FILE${NC}"
        echo ""
        echo "Setup commands:"
        echo "  psql -U postgres -f $CONFIG_FILE"
        ;;

    adx)
        cat > "$CONFIG_FILE" <<'EOF'
# Azure Data Explorer (Kusto) Configuration

cluster: "https://vehicletelemetry.westus2.kusto.windows.net"
database: "VehicleTelemetry"

# Table schemas
tables:
  - name: Battery
    schema:
      - Timestamp: datetime
      - VIN: string
      - BatteryPackId: int
      - SOC: real
      - Voltage: real
      - Current: real
      - Temperature: real
      - SOH: real

  - name: Location
    schema:
      - Timestamp: datetime
      - VIN: string
      - Latitude: real
      - Longitude: real
      - Altitude: real
      - Speed: real
      - Heading: real

# Data retention
retention:
  softDelete: 30d
  hotCache: 7d

# Ingestion mapping (JSON)
ingestion_mappings:
  - name: BatteryMapping
    kind: Json
    mapping:
      - column: Timestamp
        path: $.timestamp
      - column: VIN
        path: $.vin
      - column: SOC
        path: $.battery.soc

# Update policy (downsampling)
update_policies:
  - name: Battery_1m
    query: |
      Battery
      | summarize
          soc_avg = avg(SOC),
          voltage_avg = avg(Voltage),
          current_avg = avg(Current)
        by VIN, bin(Timestamp, 1m)
EOF

        echo -e "${GREEN}✓ Azure Data Explorer config generated: $CONFIG_FILE${NC}"
        echo ""
        echo "Setup commands:"
        echo "  # Create table"
        echo "  .create table Battery (Timestamp:datetime, VIN:string, ...)"
        echo ""
        echo "  # Create mapping"
        echo "  .create table Battery ingestion json mapping 'BatteryMapping' '[...]'"
        ;;

    *)
        echo -e "${RED}Error: Unsupported backend: $BACKEND${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}Ingestion Pipeline Architecture:${NC}"
echo ""
echo "  Vehicle → MQTT/HTTP → Message Queue → Stream Processor → Time-Series DB"
echo "            (IoT Hub)    (Kafka/EventHub)  (Flink/Stream Analytics)"
echo ""
echo "Recommended ingestion rates:"
echo "  • High-frequency (10 Hz): Battery voltage, current"
echo "  • Medium-frequency (1 Hz): Location, speed"
echo "  • Low-frequency (0.1 Hz): Temperature, diagnostics"

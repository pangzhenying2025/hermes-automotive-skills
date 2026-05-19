---
name: automotive-sdv
description: >
  Automotive Sdv expertise. Covers 6 topics: Cloud Vehicle Integration, Containerized Vehicle Apps, Digital Twin Vehicles, Ota Update Systems, Vehicle App Stores.
tags: [automotive, automotive-sdv]
---

# Automotive Sdv

## Cloud Vehicle Integration

# Cloud-Vehicle Integration — Connected Vehicle Platforms

Expert knowledge of vehicle-to-cloud connectivity (MQTT, AMQP, HTTP/2), telemetry streaming, remote diagnostics, cloud-based fleet management, and API gateways.

## Core Concepts

### Communication Protocols

1. **MQTT**: Lightweight pub/sub for telemetry (Eclipse Mosquitto, AWS IoT Core)
2. **AMQP**: Reliable message queuing (RabbitMQ, Azure Service Bus)
3. **HTTP/2**: RESTful APIs with server push
4. **WebSocket**: Real-time bidirectional communication
5. **gRPC**: High-performance RPC for services

### Architecture Patterns

- **Edge Computing**: Process data locally before cloud
- **Digital Twin**: Virtual representation of vehicle in cloud
- **Command & Control**: Remote vehicle operations
- **Fleet Management**: Aggregate analytics across vehicles
- **OTA Coordination**: Centralized update management

## Production-Ready Implementation

### 1. Vehicle Telemetry Client (Python/MQTT)

```python
#!/usr/bin/env python3
"""
Vehicle telemetry client using MQTT.
Streams vehicle data to cloud platform with offline buffering.
"""

import json
import time
import sqlite3
from dataclasses import dataclass, asdict
from datetime import datetime
from typing import Optional, List
import paho.mqtt.client as mqtt
import can


@dataclass
class TelemetryMessage:
    """Vehicle telemetry data point."""
    vin: str
    timestamp: str
    message_type: str
    data: dict


class VehicleTelemetryClient:
    """
    MQTT-based telemetry client.

    Features:
    - Real-time telemetry streaming
    - Offline buffering with SQLite
    - Automatic reconnection
    - QoS levels for reliability
    - Compression for bandwidth optimization
    """

    def __init__(self, config_path: str = "/etc/vehicle/telemetry-config.json"):
        self.config = self._load_config(config_path)
        self.vin = self._get_vin()
        self.mqtt_client = None
        self.can_bus = None
        self.offline_buffer = OfflineBuffer()
        self.connected = False

    def _load_config(self, path: str) -> dict:
        """Load configuration."""
        with open(path, 'r') as f:
            return json.load(f)

    def _get_vin(self) -> str:
        """Get vehicle VIN."""
        with open('/sys/firmware/devicetree/base/serial-number', 'r') as f:
            return f.read().strip()

    def connect(self):
        """Connect to MQTT broker."""
        self.mqtt_client = mqtt.Client(
            client_id=f"vehicle-{self.vin}",
            clean_session=False,  # Maintain session across reconnects
            protocol=mqtt.MQTTv5
        )

        # Set credentials
        self.mqtt_client.username_pw_set(
            self.config['mqtt_username'],
            self.config['mqtt_password']
        )

        # Configure TLS
        if self.config.get('mqtt_tls', True):
            self.mqtt_client.tls_set(
                ca_certs=self.config['mqtt_ca_cert'],
                certfile=self.config.get('mqtt_client_cert'),
                keyfile=self.config.get('mqtt_client_key')
            )

        # Set callbacks
        self.mqtt_client.on_connect = self._on_connect
        self.mqtt_client.on_disconnect = self._on_disconnect
        self.mqtt_client.on_message = self._on_message
        self.mqtt_client.on_publish = self._on_publish

        # Set last will (notify cloud if vehicle disconnects unexpectedly)
        self.mqtt_client.will_set(
            f"vehicles/{self.vin}/status",
            payload=json.dumps({
                "status": "offline",
                "timestamp": datetime.utcnow().isoformat()
            }),
            qos=1,
            retain=True
        )

        # Connect
        print(f"[Telemetry] Connecting to {self.config['mqtt_broker']}:{self.config['mqtt_port']}")
        self.mqtt_client.connect(
            self.config['mqtt_broker'],
            self.config['mqtt_port'],
            keepalive=60
        )

        # Start network loop in background
        self.mqtt_client.loop_start()

    def _on_connect(self, client, userdata, flags, rc, properties=None):
        """Handle MQTT connection."""
        if rc == 0:
            print("[Telemetry] Connected to MQTT broker")
            self.connected = True

            # Publish online status
            self.mqtt_client.publish(
                f"vehicles/{self.vin}/status",
                payload=json.dumps({
                    "status": "online",
                    "timestamp": datetime.utcnow().isoformat(),
                    "sw_version": self._get_software_version()
                }),
                qos=1,
                retain=True
            )

            # Subscribe to command topics
            self.mqtt_client.subscribe(f"vehicles/{self.vin}/commands/#", qos=1)

            # Send buffered messages
            self._flush_offline_buffer()
        else:
            print(f"[Telemetry] Connection failed: {rc}")
            self.connected = False

    def _on_disconnect(self, client, userdata, rc):
        """Handle MQTT disconnection."""
        print(f"[Telemetry] Disconnected from broker: {rc}")
        self.connected = False

        if rc != 0:
            print("[Telemetry] Unexpected disconnect, will reconnect")

    def _on_message(self, client, userdata, msg):
        """Handle incoming command messages."""
        print(f"[Telemetry] Received command: {msg.topic}")

        try:
            payload = json.loads(msg.payload.decode())
            self._handle_command(msg.topic, payload)
        except Exception as e:
            print(f"[Telemetry] Error processing command: {e}")

    def _on_publish(self, client, userdata, mid):
        """Handle successful publish."""
        # Remove from offline buffer if it was buffered
        pass

    def _handle_command(self, topic: str, payload: dict):
        """Handle remote commands from cloud."""
        command_type = topic.split('/')[-1]

        if command_type == "diagnostics":
            # Trigger diagnostic data collection
            print("[Telemetry] Starting diagnostic data collection")
            self._collect_diagnostics()

        elif command_type == "update":
            # Trigger OTA update check
            print("[Telemetry] Checking for updates")
            # Integration with OTA system

        elif command_type == "lock":
            # Remote lock command
            print("[Telemetry] Remote lock requested")
            self._remote_lock()

        elif command_type == "honk":
            # Remote horn activation
            print("[Telemetry] Remote honk requested")
            self._remote_honk()

    def publish_telemetry(self, message_type: str, data: dict, qos: int = 0):
        """
        Publish telemetry message.

        Args:
            message_type: Type of telemetry (battery, location, speed, etc.)
            data: Telemetry data
            qos: MQTT QoS level (0, 1, or 2)
        """
        msg = TelemetryMessage(
            vin=self.vin,
            timestamp=datetime.utcnow().isoformat(),
            message_type=message_type,
            data=data
        )

        topic = f"vehicles/{self.vin}/telemetry/{message_type}"
        payload = json.dumps(asdict(msg))

        if self.connected:
            result = self.mqtt_client.publish(topic, payload, qos=qos)

            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"[Telemetry] Published {message_type}")
            else:
                print(f"[Telemetry] Publish failed: {result.rc}")
                # Buffer for later
                self.offline_buffer.store(topic, payload, qos)
        else:
            # Store in offline buffer
            self.offline_buffer.store(topic, payload, qos)
            print(f"[Telemetry] Buffered {message_type} (offline)")

    def _flush_offline_buffer(self):
        """Send buffered messages when connection restored."""
        messages = self.offline_buffer.retrieve_all()
        print(f"[Telemetry] Flushing {len(messages)} buffered messages")

        for msg in messages:
            self.mqtt_client.publish(msg['topic'], msg['payload'], qos=msg['qos'])
            self.offline_buffer.delete(msg['id'])

    def start_can_monitoring(self):
        """Start monitoring CAN bus and streaming telemetry."""
        print("[Telemetry] Starting CAN bus monitoring")

        # Connect to CAN bus
        self.can_bus = can.interface.Bus(channel='can0', bustype='socketcan')

        # Define telemetry intervals
        intervals = {
            'battery': 60,  # Every minute
            'location': 300,  # Every 5 minutes
            'speed': 10,  # Every 10 seconds
            'diagnostics': 3600,  # Every hour
        }

        last_publish = {k: 0 for k in intervals.keys()}

        while True:
            # Read CAN messages
            msg = self.can_bus.recv(timeout=1.0)

            if msg is None:
                continue

            current_time = time.time()

            # Process specific CAN IDs
            if msg.arbitration_id == 0x123:  # Battery telemetry
                if current_time - last_publish['battery'] >= intervals['battery']:
                    battery_data = self._parse_battery_can(msg.data)
                    self.publish_telemetry('battery', battery_data, qos=1)
                    last_publish['battery'] = current_time

            elif msg.arbitration_id == 0x456:  # Speed/location
                if current_time - last_publish['speed'] >= intervals['speed']:
                    speed_data = self._parse_speed_can(msg.data)
                    self.publish_telemetry('speed', speed_data, qos=0)
                    last_publish['speed'] = current_time

            # Periodic location publish
            if current_time - last_publish['location'] >= intervals['location']:
                location_data = self._get_gps_location()
                self.publish_telemetry('location', location_data, qos=1)
                last_publish['location'] = current_time

    def _parse_battery_can(self, data: bytes) -> dict:
        """Parse battery telemetry from CAN message."""
        return {
            'soc': int.from_bytes(data[0:2], 'big') / 100,  # State of charge %
            'voltage': int.from_bytes(data[2:4], 'big') / 10,  # Volts
            'current': int.from_bytes(data[4:6], 'big', signed=True) / 10,  # Amps
            'temperature': int.from_bytes(data[6:8], 'big') / 10 - 40,  # Celsius
        }

    def _parse_speed_can(self, data: bytes) -> dict:
        """Parse speed telemetry from CAN message."""
        return {
            'speed': int.from_bytes(data[0:2], 'big') / 100,  # km/h
            'odometer': int.from_bytes(data[2:6], 'big') / 10,  # km
        }

    def _get_gps_location(self) -> dict:
        """Get GPS location from GNSS receiver."""
        # Read from gpsd or similar
        return {
            'latitude': 37.7749,
            'longitude': -122.4194,
            'altitude': 16.0,
            'heading': 270.0,
            'accuracy': 3.5
        }

    def _get_software_version(self) -> str:
        """Get vehicle software version."""
        with open('/etc/vehicle/version', 'r') as f:
            return f.read().strip()

    def _collect_diagnostics(self):
        """Collect comprehensive diagnostic data."""
        diagnostics = {
            'dtcs': [],  # Diagnostic Trouble Codes
            'ecu_status': {},
            'battery_health': {},
            'sensor_status': {},
        }

        # Publish diagnostic report
        self.publish_telemetry('diagnostics', diagnostics, qos=1)

    def _remote_lock(self):
        """Execute remote lock command."""
        # Send CAN command to lock doors
        pass

    def _remote_honk(self):
        """Execute remote horn activation."""
        # Send CAN command to honk
        pass

    def disconnect(self):
        """Disconnect from MQTT broker."""
        if self.mqtt_client:
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()

        if self.can_bus:
            self.can_bus.shutdown()


class OfflineBuffer:
    """SQLite-based offline message buffer."""

    def __init__(self, db_path: str = "/var/lib/vehicle/telemetry-buffer.db"):
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        """Initialize SQLite database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS buffer (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                topic TEXT NOT NULL,
                payload TEXT NOT NULL,
                qos INTEGER NOT NULL,
                timestamp REAL NOT NULL
            )
        ''')

        conn.commit()
        conn.close()

    def store(self, topic: str, payload: str, qos: int):
        """Store message in buffer."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute(
            'INSERT INTO buffer (topic, payload, qos, timestamp) VALUES (?, ?, ?, ?)',
            (topic, payload, qos, time.time())
        )

        conn.commit()
        conn.close()

    def retrieve_all(self) -> List[dict]:
        """Retrieve all buffered messages."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute('SELECT id, topic, payload, qos FROM buffer ORDER BY timestamp')
        rows = cursor.fetchall()

        conn.close()

        return [
            {'id': row[0], 'topic': row[1], 'payload': row[2], 'qos': row[3]}
            for row in rows
        ]

    def delete(self, msg_id: int):
        """Delete message from buffer."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute('DELETE FROM buffer WHERE id = ?', (msg_id,))

        conn.commit()
        conn.close()


def main():
    """Main telemetry client loop."""
    client = VehicleTelemetryClient()

    try:
        client.connect()
        client.start_can_monitoring()
    except KeyboardInterrupt:
        print("\n[Telemetry] Shutting down")
        client.disconnect()


if __name__ == "__main__":
    main()
```

### 2. Cloud Backend (AWS IoT Core Integration)

```python
#!/usr/bin/env python3
"""
Cloud backend for vehicle fleet management using AWS IoT Core.
"""

import json
import boto3
from datetime import datetime
from typing import Dict, List
from aws_iot_device_sdk import mqtt as mqtt5
import redis


class FleetManagementBackend:
    """
    Fleet management backend.

    Services:
    - Receive telemetry from vehicles
    - Store in time-series database
    - Real-time analytics
    - Remote command dispatch
    """

    def __init__(self):
        # AWS IoT Core client
        self.iot_client = boto3.client('iot-data', region_name='us-west-2')

        # DynamoDB for vehicle state
        self.dynamodb = boto3.resource('dynamodb', region_name='us-west-2')
        self.vehicle_table = self.dynamodb.Table('VehicleState')

        # Timestream for telemetry
        self.timestream = boto3.client('timestream-write', region_name='us-west-2')
        self.ts_database = 'VehicleTelemetry'
        self.ts_table = 'TelemetryData'

        # Redis for real-time data
        self.redis = redis.Redis(host='localhost', port=6379, decode_responses=True)

    def process_telemetry(self, vin: str, message_type: str, data: dict):
        """
        Process incoming telemetry message.

        Args:
            vin: Vehicle identification number
            message_type: Type of telemetry
            data: Telemetry data
        """
        print(f"[Fleet] Processing {message_type} from {vin}")

        # Update vehicle state in DynamoDB
        self._update_vehicle_state(vin, message_type, data)

        # Store in Timestream for historical analytics
        self._store_timestream(vin, message_type, data)

        # Cache in Redis for real-time queries
        self._cache_redis(vin, message_type, data)

        # Trigger alerts if necessary
        self._check_alerts(vin, message_type, data)

    def _update_vehicle_state(self, vin: str, message_type: str, data: dict):
        """Update vehicle state in DynamoDB."""
        self.vehicle_table.update_item(
            Key={'vin': vin},
            UpdateExpression=f'SET {message_type} = :data, last_update = :timestamp',
            ExpressionAttributeValues={
                ':data': data,
                ':timestamp': datetime.utcnow().isoformat()
            }
        )

    def _store_timestream(self, vin: str, message_type: str, data: dict):
        """Store telemetry in AWS Timestream."""
        records = []

        for key, value in data.items():
            records.append({
                'Time': str(int(datetime.utcnow().timestamp() * 1000)),
                'TimeUnit': 'MILLISECONDS',
                'Dimensions': [
                    {'Name': 'vin', 'Value': vin},
                    {'Name': 'message_type', 'Value': message_type},
                ],
                'MeasureName': key,
                'MeasureValue': str(value),
                'MeasureValueType': 'DOUBLE' if isinstance(value, float) else 'BIGINT'
            })

        try:
            self.timestream.write_records(
                DatabaseName=self.ts_database,
                TableName=self.ts_table,
                Records=records
            )
        except Exception as e:
            print(f"[Fleet] Timestream write error: {e}")

    def _cache_redis(self, vin: str, message_type: str, data: dict):
        """Cache latest telemetry in Redis."""
        key = f"vehicle:{vin}:{message_type}"
        self.redis.setex(key, 3600, json.dumps(data))  # 1 hour TTL

    def _check_alerts(self, vin: str, message_type: str, data: dict):
        """Check for alert conditions."""
        if message_type == 'battery':
            # Low battery alert
            if data.get('soc', 100) < 20:
                self._send_alert(vin, 'low_battery', f"Battery at {data['soc']}%")

            # High temperature alert
            if data.get('temperature', 0) > 50:
                self._send_alert(vin, 'high_temperature',
                               f"Battery temp: {data['temperature']}°C")

        elif message_type == 'diagnostics':
            # DTC alert
            if data.get('dtcs'):
                self._send_alert(vin, 'diagnostic_codes',
                               f"DTCs: {', '.join(data['dtcs'])}")

    def _send_alert(self, vin: str, alert_type: str, message: str):
        """Send alert to monitoring system."""
        print(f"[Fleet] ALERT - {vin}: {alert_type} - {message}")

        # Send to SNS topic
        sns = boto3.client('sns', region_name='us-west-2')
        sns.publish(
            TopicArn='arn:aws:sns:us-west-2:123456789012:vehicle-alerts',
            Subject=f"Vehicle Alert: {alert_type}",
            Message=f"VIN: {vin}\nType: {alert_type}\nMessage: {message}"
        )

    def send_command(self, vin: str, command: str, params: dict = None):
        """
        Send command to vehicle.

        Args:
            vin: Vehicle identification number
            command: Command type (lock, unlock, honk, update)
            params: Command parameters
        """
        topic = f"vehicles/{vin}/commands/{command}"
        payload = json.dumps(params or {})

        print(f"[Fleet] Sending command to {vin}: {command}")

        try:
            self.iot_client.publish(
                topic=topic,
                qos=1,
                payload=payload
            )

            # Log command
            self._log_command(vin, command, params)

        except Exception as e:
            print(f"[Fleet] Command send error: {e}")

    def _log_command(self, vin: str, command: str, params: dict):
        """Log command to DynamoDB."""
        commands_table = self.dynamodb.Table('VehicleCommands')

        commands_table.put_item(
            Item={
                'vin': vin,
                'timestamp': datetime.utcnow().isoformat(),
                'command': command,
                'params': params or {},
                'status': 'sent'
            }
        )

    def get_vehicle_state(self, vin: str) -> Dict:
        """Get current vehicle state."""
        response = self.vehicle_table.get_item(Key={'vin': vin})
        return response.get('Item', {})

    def get_fleet_status(self) -> List[Dict]:
        """Get status of entire fleet."""
        response = self.vehicle_table.scan()
        return response.get('Items', [])

    def query_telemetry_history(self, vin: str, metric: str,
                                start_time: datetime, end_time: datetime) -> List[Dict]:
        """Query historical telemetry from Timestream."""
        query_client = boto3.client('timestream-query', region_name='us-west-2')

        query = f"""
        SELECT time, measure_value::double as value
        FROM "{self.ts_database}"."{self.ts_table}"
        WHERE vin = '{vin}'
          AND measure_name = '{metric}'
          AND time BETWEEN from_iso8601_timestamp('{start_time.isoformat()}')
                       AND from_iso8601_timestamp('{end_time.isoformat()}')
        ORDER BY time DESC
        """

        try:
            response = query_client.query(QueryString=query)

            results = []
            for row in response['Rows']:
                results.append({
                    'time': row['Data'][0]['ScalarValue'],
                    'value': float(row['Data'][1]['ScalarValue'])
                })

            return results

        except Exception as e:
            print(f"[Fleet] Query error: {e}")
            return []
```

### 3. API Gateway (FastAPI)

```python
#!/usr/bin/env python3
"""
Fleet management API gateway.
RESTful API for vehicle operations and telemetry queries.
"""

from fastapi import FastAPI, HTTPException, Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional


app = FastAPI(title="Fleet Management API", version="2.0.0")
security = HTTPBearer()

# Initialize backend
backend = FleetManagementBackend()


class CommandRequest(BaseModel):
    """Remote command request."""
    command: str
    params: Optional[dict] = None


class TelemetryQuery(BaseModel):
    """Telemetry query parameters."""
    metric: str
    start_time: datetime
    end_time: datetime


@app.get("/api/v1/vehicles")
async def list_vehicles(credentials: HTTPAuthorizationCredentials = Security(security)):
    """List all vehicles in fleet."""
    fleet = backend.get_fleet_status()
    return {"vehicles": fleet, "count": len(fleet)}


@app.get("/api/v1/vehicles/{vin}")
async def get_vehicle(vin: str, credentials: HTTPAuthorizationCredentials = Security(security)):
    """Get vehicle state."""
    state = backend.get_vehicle_state(vin)

    if not state:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    return state


@app.post("/api/v1/vehicles/{vin}/commands")
async def send_command(
    vin: str,
    request: CommandRequest,
    credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Send command to vehicle."""
    backend.send_command(vin, request.command, request.params)
    return {"message": "Command sent", "vin": vin, "command": request.command}


@app.post("/api/v1/vehicles/{vin}/telemetry/query")
async def query_telemetry(
    vin: str,
    query: TelemetryQuery,
    credentials: HTTPAuthorizationCredentials = Security(security)
):
    """Query historical telemetry data."""
    results = backend.query_telemetry_history(
        vin,
        query.metric,
        query.start_time,
        query.end_time
    )

    return {"vin": vin, "metric": query.metric, "data": results}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
```

### 4. Terraform Infrastructure (AWS)

```hcl
# File: terraform/main.tf
# AWS IoT Core infrastructure for vehicle fleet

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# IoT Core Thing Type for Vehicles
resource "aws_iot_thing_type" "vehicle" {
  name = "VehicleType"

  properties {
    description           = "Connected vehicle"
    searchable_attributes = ["vin", "model", "year"]
  }
}

# IoT Policy for Vehicle
resource "aws_iot_policy" "vehicle_policy" {
  name = "VehiclePolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:client/vehicle-*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/vehicles/*/telemetry/*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe"
        ]
        Resource = "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topicfilter/vehicles/*/commands/*"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Receive"
        ]
        Resource = "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/vehicles/*/commands/*"
      }
    ]
  })
}

# DynamoDB Table for Vehicle State
resource "aws_dynamodb_table" "vehicle_state" {
  name           = "VehicleState"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "vin"

  attribute {
    name = "vin"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "vehicle-state"
  }
}

# Timestream Database for Telemetry
resource "aws_timestreamwrite_database" "telemetry" {
  database_name = "VehicleTelemetry"
}

resource "aws_timestreamwrite_table" "telemetry_data" {
  database_name = aws_timestreamwrite_database.telemetry.database_name
  table_name    = "TelemetryData"

  retention_properties {
    memory_store_retention_period_in_hours  = 24
    magnetic_store_retention_period_in_days = 365
  }
}

# SNS Topic for Alerts
resource "aws_sns_topic" "vehicle_alerts" {
  name = "vehicle-alerts"
}

# IoT Rule to Route Telemetry
resource "aws_iot_topic_rule" "telemetry_rule" {
  name        = "VehicleTelemetryRule"
  enabled     = true
  sql         = "SELECT * FROM 'vehicles/+/telemetry/#'"
  sql_version = "2016-03-23"

  timestream {
    database_name = aws_timestreamwrite_database.telemetry.database_name
    table_name    = aws_timestreamwrite_table.telemetry_data.table_name
    role_arn      = aws_iam_role.iot_timestream_role.arn

    dimension {
      name  = "vin"
      value = "${topic(2)}"
    }

    dimension {
      name  = "message_type"
      value = "${topic(4)}"
    }
  }

  dynamodb_v2 {
    role_arn = aws_iam_role.iot_dynamodb_role.arn
    put_item {
      table_name = aws_dynamodb_table.vehicle_state.name
    }
  }
}

# IAM Roles
resource "aws_iam_role" "iot_timestream_role" {
  name = "IoTTimestreamRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_timestream_policy" {
  name = "IoTTimestreamPolicy"
  role = aws_iam_role.iot_timestream_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "timestream:WriteRecords"
        ]
        Resource = aws_timestreamwrite_table.telemetry_data.arn
      },
      {
        Effect = "Allow"
        Action = [
          "timestream:DescribeEndpoints"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

variable "aws_region" {
  default = "us-west-2"
}
```

## Real-World Examples

### Tesla Cloud Architecture
- **Real-time telemetry**: Battery, location, charging status
- **Fleet learning**: Aggregate data for Autopilot improvement
- **Remote commands**: Lock/unlock, climate control, horn/lights
- **OTA coordination**: Staged rollout based on fleet data

### Rivian Cloud Platform
- **Adventure network**: Charging station availability
- **Fleet Services**: Commercial fleet management for R1T
- **Remote diagnostics**: Proactive service scheduling
- **Gear Shop integration**: In-vehicle accessory ordering

### VW.OS Cloud Services
- **We Connect**: Remote vehicle services
- **Charging optimization**: Route planning with charging stations
- **Predictive maintenance**: AI-based service predictions
- **Car-Net**: Emergency services integration

## Best Practices

1. **Use MQTT for telemetry**: Lightweight, efficient, pub/sub
2. **Implement offline buffering**: Handle connectivity loss gracefully
3. **QoS levels**: Critical data (QoS 1), non-critical (QoS 0)
4. **TLS encryption**: Always use TLS 1.2+ for transport security
5. **Rate limiting**: Prevent telemetry storms
6. **Compression**: Reduce bandwidth usage
7. **Edge processing**: Process data locally before cloud
8. **Time-series database**: Use Timestream, InfluxDB, or TimescaleDB
9. **Real-time cache**: Redis for low-latency queries
10. **Command acknowledgment**: Require vehicle ACK for critical commands

## Security Considerations

- **Device authentication**: X.509 certificates per vehicle
- **Message encryption**: TLS 1.2+ for transport
- **Authorization**: Fine-grained permissions per VIN
- **Audit logging**: Log all commands and access
- **API rate limiting**: Prevent abuse
- **Data retention**: GDPR-compliant data lifecycle
- **Secure provisioning**: Certificate injection during manufacturing

## References

- **AWS IoT Core**: https://aws.amazon.com/iot-core/
- **Azure IoT Hub**: https://azure.microsoft.com/en-us/products/iot-hub/
- **Eclipse Paho MQTT**: https://www.eclipse.org/paho/
- **MQTT Specification**: https://mqtt.org/
- **AMQP**: https://www.amqp.org/

---

## Containerized Vehicle Apps

# Containerized Vehicle Apps — Container Runtimes for Automotive

Expert knowledge of container runtimes for automotive (Docker, Podman, containerd), manifest formats, resource limits, inter-container communication, and orchestration (Kubernetes, K3s).

## Core Concepts

### Container Runtimes for Automotive

1. **containerd**: Lightweight, industry-standard container runtime
2. **Docker**: Full container platform (heavier footprint)
3. **Podman**: Daemonless, rootless containers
4. **LXC/LXD**: System containers for full OS isolation
5. **Balena Engine**: IoT-optimized Docker fork

### Why Containers in Vehicles?

- **Isolation**: Apps can't interfere with critical systems
- **Portability**: Same app runs on different vehicle models
- **Updates**: Update apps without full system reflash
- **Third-party apps**: Safe execution of untrusted code
- **Resource control**: CPU, memory, network limits per app

## Production-Ready Implementation

### 1. Vehicle Container Runtime (containerd + systemd)

```bash
#!/bin/bash
# File: setup-vehicle-container-runtime.sh
# Setup containerd for automotive use

set -e

echo "[Setup] Installing containerd for vehicle platform"

# Install containerd
apt-get update
apt-get install -y containerd

# Configure containerd for automotive
mkdir -p /etc/containerd
cat > /etc/containerd/config.toml <<EOF
version = 2

# Root directory for containerd
root = "/var/lib/containerd"
state = "/run/containerd"

# OCI runtime
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true

# Resource limits
[plugins."io.containerd.grpc.v1.cri".containerd]
  default_runtime_name = "runc"

# Registry configuration
[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."vehicle-registry.local:5000"]
      endpoint = ["http://vehicle-registry.local:5000"]

# CNI plugins for networking
[plugins."io.containerd.grpc.v1.cri".cni]
  bin_dir = "/opt/cni/bin"
  conf_dir = "/etc/cni/net.d"
EOF

# Enable and start containerd
systemctl enable containerd
systemctl start containerd

# Install CNI plugins
mkdir -p /opt/cni/bin
curl -L https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-arm64-v1.3.0.tgz | \
  tar -C /opt/cni/bin -xz

# Configure CNI networking
mkdir -p /etc/cni/net.d
cat > /etc/cni/net.d/10-vehicle-bridge.conf <<EOF
{
  "cniVersion": "1.0.0",
  "name": "vehicle-bridge",
  "type": "bridge",
  "bridge": "veh0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.88.0.0/16",
    "routes": [
      { "dst": "0.0.0.0/0" }
    ]
  }
}
EOF

echo "[Setup] Container runtime ready"
```

### 2. App Manifest Format (OCI-compatible)

```yaml
# Vehicle app manifest (OCI-compatible)
# File: spotify-app.yaml

apiVersion: vehicle.io/v1
kind: VehicleApp
metadata:
  name: spotify
  namespace: infotainment
  labels:
    category: media
    vendor: spotify
    safety-critical: "false"

spec:
  # Container specification
  container:
    image: vehicle-registry.local:5000/spotify/automotive:2.1.4
    imagePullPolicy: IfNotPresent

    # Resource limits
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
        storage: "1Gi"
      limits:
        memory: "512Mi"
        cpu: "500m"
        storage: "2Gi"
        network:
          bandwidth: "10Mbps"

    # Security context
    securityContext:
      runAsUser: 1000
      runAsGroup: 1000
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
        add:
          - NET_BIND_SERVICE  # For network access

    # Environment variables
    env:
      - name: API_KEY
        valueFrom:
          secretRef:
            name: spotify-credentials
            key: api-key
      - name: VEHICLE_VIN
        valueFrom:
          fieldRef:
            fieldPath: metadata.vin

    # Volume mounts
    volumeMounts:
      - name: cache
        mountPath: /app/cache
      - name: config
        mountPath: /app/config
        readOnly: true
      - name: dbus-socket
        mountPath: /var/run/dbus

  # Volumes
  volumes:
    - name: cache
      emptyDir:
        sizeLimit: 500Mi
    - name: config
      configMap:
        name: spotify-config
    - name: dbus-socket
      hostPath:
        path: /var/run/dbus
        type: Socket

  # Networking
  networking:
    ports:
      - name: http
        containerPort: 8080
        protocol: TCP
    hostNetwork: false
    dnsPolicy: ClusterFirst

  # Lifecycle hooks
  lifecycle:
    postStart:
      exec:
        command: ["/app/scripts/post-start.sh"]
    preStop:
      exec:
        command: ["/app/scripts/graceful-shutdown.sh"]

  # Health checks
  livenessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 10
    periodSeconds: 30
  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10

  # Service integration
  services:
    - name: media-player
      type: dbus
      interface: org.mpris.MediaPlayer2
    - name: steering-controls
      type: vehicle-bus
      permissions: [read]

  # Safety constraints
  safety:
    disableWhileDriving: false
    touchLimit: true
    requireVoiceControl: false
    criticalityLevel: low

  # Update strategy
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
```

### 3. Container Orchestrator (K3s for Automotive)

```bash
#!/bin/bash
# File: install-k3s-automotive.sh
# Install K3s (lightweight Kubernetes) for vehicle platform

set -e

echo "[K3s] Installing K3s for vehicle platform"

# Install K3s with automotive-specific configuration
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --disable traefik \
  --disable servicelb \
  --disable local-storage \
  --write-kubeconfig-mode 644 \
  --kubelet-arg=max-pods=50 \
  --kubelet-arg=eviction-hard=memory.available<100Mi \
  --kubelet-arg=eviction-soft=memory.available<200Mi \
  --kubelet-arg=eviction-soft-grace-period=memory.available=1m \
  --kube-controller-manager-arg=node-monitor-period=10s \
  --kube-controller-manager-arg=node-monitor-grace-period=30s" sh -

# Wait for K3s to start
sleep 10

# Install vehicle-specific CRDs
cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: vehicleapps.vehicle.io
spec:
  group: vehicle.io
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                container:
                  type: object
                safety:
                  type: object
                services:
                  type: array
  scope: Namespaced
  names:
    plural: vehicleapps
    singular: vehicleapp
    kind: VehicleApp
    shortNames:
      - vapp
EOF

# Create namespaces
kubectl create namespace infotainment
kubectl create namespace adas
kubectl create namespace diagnostics

# Install resource quotas
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: infotainment-quota
  namespace: infotainment
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "4Gi"
    persistentvolumeclaims: "10"
EOF

echo "[K3s] Installation complete"
```

### 4. App Deployment Script (Python)

```python
#!/usr/bin/env python3
"""
Vehicle app deployment tool using containerd API.
"""

import subprocess
import json
import yaml
from pathlib import Path
from typing import Dict


class VehicleAppDeployer:
    """Deploy containerized apps to vehicle platform."""

    def __init__(self, runtime: str = "containerd"):
        self.runtime = runtime
        self.namespace = "vehicle-apps"

    def deploy_app(self, manifest_path: str):
        """
        Deploy app from manifest.

        Args:
            manifest_path: Path to app manifest YAML
        """
        with open(manifest_path, 'r') as f:
            manifest = yaml.safe_load(f)

        app_name = manifest['metadata']['name']
        print(f"[Deploy] Deploying {app_name}")

        # Pull container image
        self._pull_image(manifest['spec']['container']['image'])

        # Create namespace
        self._create_namespace(manifest['metadata']['namespace'])

        # Create container
        container_id = self._create_container(manifest)

        # Start container
        self._start_container(container_id)

        print(f"[Deploy] {app_name} deployed successfully (ID: {container_id})")

    def _pull_image(self, image: str):
        """Pull container image."""
        print(f"[Deploy] Pulling image: {image}")

        cmd = [
            "ctr", "-n", self.namespace,
            "image", "pull", image
        ]

        subprocess.run(cmd, check=True)

    def _create_namespace(self, namespace: str):
        """Create containerd namespace."""
        # Containerd namespaces are created automatically on first use
        pass

    def _create_container(self, manifest: Dict) -> str:
        """Create container from manifest."""
        spec = manifest['spec']
        metadata = manifest['metadata']

        app_name = metadata['name']
        image = spec['container']['image']

        # Build OCI runtime spec
        runtime_spec = self._build_runtime_spec(spec)

        # Write spec to file
        spec_path = f"/tmp/{app_name}-spec.json"
        with open(spec_path, 'w') as f:
            json.dump(runtime_spec, f, indent=2)

        # Create container
        cmd = [
            "ctr", "-n", self.namespace,
            "container", "create",
            "--runtime", "io.containerd.runc.v2",
            "--config", spec_path,
            image,
            app_name
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            raise RuntimeError(f"Container creation failed: {result.stderr}")

        return app_name

    def _build_runtime_spec(self, spec: Dict) -> Dict:
        """Build OCI runtime specification."""
        container = spec['container']
        resources = container.get('resources', {})

        # Parse resource limits
        memory_limit = self._parse_memory(
            resources.get('limits', {}).get('memory', '512Mi')
        )
        cpu_quota = self._parse_cpu(
            resources.get('limits', {}).get('cpu', '500m')
        )

        # Build OCI spec
        oci_spec = {
            "ociVersion": "1.0.2",
            "process": {
                "terminal": False,
                "user": {
                    "uid": container.get('securityContext', {}).get('runAsUser', 1000),
                    "gid": container.get('securityContext', {}).get('runAsGroup', 1000)
                },
                "env": self._build_env(container.get('env', [])),
                "cwd": "/app",
                "capabilities": {
                    "bounding": ["CAP_NET_BIND_SERVICE"],
                    "effective": ["CAP_NET_BIND_SERVICE"],
                    "inheritable": ["CAP_NET_BIND_SERVICE"],
                    "permitted": ["CAP_NET_BIND_SERVICE"]
                },
                "rlimits": [
                    {
                        "type": "RLIMIT_NOFILE",
                        "hard": 1024,
                        "soft": 1024
                    }
                ],
                "noNewPrivileges": True
            },
            "root": {
                "path": "rootfs",
                "readonly": container.get('securityContext', {}).get(
                    'readOnlyRootFilesystem', True
                )
            },
            "mounts": self._build_mounts(spec.get('volumes', [])),
            "linux": {
                "namespaces": [
                    {"type": "pid"},
                    {"type": "network"},
                    {"type": "ipc"},
                    {"type": "uts"},
                    {"type": "mount"}
                ],
                "resources": {
                    "memory": {
                        "limit": memory_limit
                    },
                    "cpu": {
                        "quota": cpu_quota,
                        "period": 100000
                    }
                },
                "cgroupsPath": f"/vehicle-apps/{spec['container']['image'].split('/')[-1]}"
            }
        }

        return oci_spec

    def _build_env(self, env_vars: list) -> list:
        """Build environment variable list."""
        env = ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"]

        for var in env_vars:
            name = var['name']
            value = var.get('value')

            if value:
                env.append(f"{name}={value}")
            elif 'valueFrom' in var:
                # Resolve from secret/configmap
                # Simplified implementation
                env.append(f"{name}=<resolved-value>")

        return env

    def _build_mounts(self, volumes: list) -> list:
        """Build mount list."""
        mounts = [
            {
                "destination": "/proc",
                "type": "proc",
                "source": "proc"
            },
            {
                "destination": "/dev",
                "type": "tmpfs",
                "source": "tmpfs",
                "options": ["nosuid", "strictatime", "mode=755", "size=65536k"]
            },
            {
                "destination": "/dev/pts",
                "type": "devpts",
                "source": "devpts",
                "options": ["nosuid", "noexec", "newinstance", "ptmxmode=0666", "mode=0620"]
            },
            {
                "destination": "/sys",
                "type": "sysfs",
                "source": "sysfs",
                "options": ["nosuid", "noexec", "nodev", "ro"]
            }
        ]

        # Add application-specific mounts
        for volume in volumes:
            if volume.get('emptyDir'):
                mounts.append({
                    "destination": "/app/cache",
                    "type": "tmpfs",
                    "source": "tmpfs",
                    "options": ["nosuid", "nodev"]
                })
            elif volume.get('hostPath'):
                mounts.append({
                    "destination": "/var/run/dbus",
                    "type": "bind",
                    "source": volume['hostPath']['path'],
                    "options": ["rbind", "ro"]
                })

        return mounts

    def _start_container(self, container_id: str):
        """Start container."""
        print(f"[Deploy] Starting container: {container_id}")

        cmd = [
            "ctr", "-n", self.namespace,
            "task", "start", "-d",
            container_id
        ]

        subprocess.run(cmd, check=True)

    def _parse_memory(self, mem_str: str) -> int:
        """Parse memory string to bytes."""
        units = {'Ki': 1024, 'Mi': 1024**2, 'Gi': 1024**3}

        for unit, multiplier in units.items():
            if mem_str.endswith(unit):
                return int(mem_str[:-2]) * multiplier

        return int(mem_str)

    def _parse_cpu(self, cpu_str: str) -> int:
        """Parse CPU string to quota."""
        if cpu_str.endswith('m'):
            millicores = int(cpu_str[:-1])
            return millicores * 100  # quota in microseconds
        else:
            cores = float(cpu_str)
            return int(cores * 100000)

    def list_apps(self):
        """List deployed apps."""
        cmd = [
            "ctr", "-n", self.namespace,
            "container", "ls"
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)
        print(result.stdout)

    def stop_app(self, app_name: str):
        """Stop running app."""
        print(f"[Deploy] Stopping app: {app_name}")

        # Stop task
        cmd = [
            "ctr", "-n", self.namespace,
            "task", "kill", app_name,
            "SIGTERM"
        ]

        subprocess.run(cmd, check=False)

    def remove_app(self, app_name: str):
        """Remove app."""
        print(f"[Deploy] Removing app: {app_name}")

        # Delete container
        cmd = [
            "ctr", "-n", self.namespace,
            "container", "rm", app_name
        ]

        subprocess.run(cmd, check=True)


def main():
    """Main deployment script."""
    deployer = VehicleAppDeployer()

    # Deploy app
    deployer.deploy_app("spotify-app.yaml")

    # List apps
    deployer.list_apps()


if __name__ == "__main__":
    main()
```

### 5. Inter-Container Communication (D-Bus)

```python
#!/usr/bin/env python3
"""
D-Bus service for inter-container communication.
Allows sandboxed apps to communicate with vehicle services.
"""

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


class VehicleServiceBus(dbus.service.Object):
    """
    D-Bus service for vehicle platform.

    Provides APIs for apps to:
    - Get vehicle state
    - Control audio
    - Receive user input (steering controls)
    - Display notifications
    """

    def __init__(self):
        bus_name = dbus.service.BusName('com.vehicle.Platform',
                                       bus=dbus.SystemBus())
        dbus.service.Object.__init__(self, bus_name, '/com/vehicle/Platform')

    @dbus.service.method('com.vehicle.Platform',
                        in_signature='', out_signature='a{sv}')
    def GetVehicleState(self):
        """Get current vehicle state."""
        return {
            'speed': dbus.Double(65.0),  # km/h
            'batterySoc': dbus.Double(75.0),  # %
            'range': dbus.Double(300.0),  # km
            'gear': dbus.String('D'),
            'isMoving': dbus.Boolean(True)
        }

    @dbus.service.method('com.vehicle.Platform',
                        in_signature='s', out_signature='b')
    def PlayAudio(self, url):
        """Play audio from URL."""
        print(f"[D-Bus] Playing audio: {url}")
        # Integrate with vehicle audio system
        return True

    @dbus.service.signal('com.vehicle.Platform', signature='s')
    def SteeringControlEvent(self, action):
        """Signal for steering control events."""
        print(f"[D-Bus] Steering control: {action}")

    @dbus.service.method('com.vehicle.Platform',
                        in_signature='ss', out_signature='b')
    def ShowNotification(self, title, message):
        """Display notification in vehicle cluster."""
        print(f"[D-Bus] Notification: {title} - {message}")
        # Send to instrument cluster
        return True


def main():
    """Start D-Bus service."""
    DBusGMainLoop(set_as_default=True)

    service = VehicleServiceBus()
    print("[D-Bus] Vehicle service bus started")

    # Run main loop
    loop = GLib.MainLoop()
    loop.run()


if __name__ == "__main__":
    main()
```

## Real-World Examples

### Tesla Container Strategy
- **Native apps**: Tesla apps run directly on Linux (no containers yet)
- **Future plans**: Exploring containers for third-party apps
- **Steam integration**: Games run in isolated environment

### GM Ultifi Platform
- **Full container orchestration**: Kubernetes-based
- **App marketplace**: Third-party containerized apps
- **Resource isolation**: CPU/memory limits per app
- **OTA updates**: Update containers independently

### Rivian App Platform
- **Docker-based**: Uses Docker for app isolation
- **Custom runtime**: Modified Docker daemon for automotive
- **Safety constraints**: Apps can't access CAN bus directly
- **Fleet deployment**: Kubernetes for managing app fleet

### Android Automotive
- **Container-like isolation**: APK sandboxing similar to containers
- **Resource limits**: Memory/CPU limits per app
- **Permission model**: Fine-grained permissions
- **Update mechanism**: Individual app updates

## Best Practices

1. **Use containerd**: Lightweight, industry-standard
2. **Resource limits**: Always set CPU/memory limits
3. **Read-only root**: Immutable container filesystem
4. **Drop capabilities**: Minimal Linux capabilities
5. **Network isolation**: Isolate app network traffic
6. **Health checks**: Liveness and readiness probes
7. **Graceful shutdown**: Handle SIGTERM properly
8. **Persistent data**: Use volumes for app data
9. **Image scanning**: Scan images for vulnerabilities
10. **Update strategy**: Rolling updates with rollback

## Security Considerations

- **User namespaces**: Run containers as non-root
- **Seccomp profiles**: Restrict system calls
- **AppArmor/SELinux**: Mandatory access control
- **Image signing**: Verify container image signatures
- **Network policies**: Restrict inter-container communication
- **Audit logging**: Log container lifecycle events
- **Resource quotas**: Prevent resource exhaustion

## References

- **containerd**: https://containerd.io/
- **OCI Runtime Spec**: https://github.com/opencontainers/runtime-spec
- **K3s**: https://k3s.io/
- **Podman**: https://podman.io/
- **Balena Engine**: https://www.balena.io/engine/

---

## Digital Twin Vehicles

# Digital Twin Vehicles — Virtual Vehicle Representations

Expert knowledge of digital twin architecture, real-time synchronization, simulation for testing, predictive maintenance, virtual testing environments, and CI/CD for vehicle software.

## Core Concepts

### Digital Twin Architecture

1. **Physical Twin**: Actual vehicle with sensors and actuators
2. **Digital Twin**: Virtual representation in cloud/edge
3. **Bi-directional Sync**: Real-time data flow both ways
4. **Simulation Engine**: Physics-based vehicle model
5. **Analytics Layer**: ML/AI for predictions

### Use Cases

- **Predictive Maintenance**: Predict failures before they occur
- **Virtual Testing**: Test software without physical vehicle
- **Fleet Optimization**: Optimize routing, charging, maintenance
- **Development**: Rapid prototyping and testing
- **Training**: Train ML models on simulated data

## Production-Ready Implementation

### 1. Digital Twin Engine (Python)

```python
#!/usr/bin/env python3
"""
Digital Twin Engine for vehicle simulation and synchronization.
"""

import json
import time
from dataclasses import dataclass, asdict
from datetime import datetime
from typing import Dict, List, Optional
import numpy as np
from scipy.integrate import odeint
import paho.mqtt.client as mqtt


@dataclass
class VehicleState:
    """Complete vehicle state."""
    vin: str
    timestamp: float

    # Powertrain
    battery_soc: float  # State of charge (%)
    battery_voltage: float  # Volts
    battery_current: float  # Amps
    battery_temperature: float  # Celsius
    motor_speed: float  # RPM
    motor_torque: float  # Nm

    # Dynamics
    speed: float  # km/h
    acceleration: float  # m/s^2
    position: tuple  # (latitude, longitude)
    heading: float  # degrees

    # Environment
    ambient_temperature: float  # Celsius
    road_grade: float  # %

    # Diagnostics
    odometer: float  # km
    energy_consumed: float  # kWh
    regeneration_energy: float  # kWh


class VehiclePhysicsModel:
    """
    Physics-based vehicle simulation model.

    Models:
    - Battery dynamics (charge/discharge, thermal)
    - Electric motor efficiency
    - Vehicle dynamics (acceleration, drag, rolling resistance)
    - Energy consumption
    """

    def __init__(self, vehicle_params: dict):
        self.params = vehicle_params

        # Vehicle parameters
        self.mass = vehicle_params['mass']  # kg
        self.drag_coefficient = vehicle_params['drag_coefficient']  # Cd
        self.frontal_area = vehicle_params['frontal_area']  # m^2
        self.rolling_resistance = vehicle_params['rolling_resistance']  # Crr
        self.wheel_radius = vehicle_params['wheel_radius']  # m

        # Battery parameters
        self.battery_capacity = vehicle_params['battery_capacity']  # kWh
        self.battery_resistance = vehicle_params['battery_resistance']  # Ohms
        self.battery_thermal_mass = vehicle_params['battery_thermal_mass']  # J/K

        # Motor parameters
        self.motor_max_power = vehicle_params['motor_max_power']  # kW
        self.motor_efficiency_map = vehicle_params['motor_efficiency_map']

        # Constants
        self.air_density = 1.225  # kg/m^3
        self.gravity = 9.81  # m/s^2

    def simulate_step(self, state: VehicleState, throttle: float,
                     dt: float) -> VehicleState:
        """
        Simulate one time step.

        Args:
            state: Current vehicle state
            throttle: Throttle input (-1 to 1, negative for regen)
            dt: Time step (seconds)

        Returns:
            Updated vehicle state
        """
        # Convert speed to m/s
        speed_mps = state.speed / 3.6

        # Calculate forces
        drag_force = 0.5 * self.air_density * self.drag_coefficient * \
                     self.frontal_area * speed_mps**2

        rolling_resistance_force = self.rolling_resistance * self.mass * \
                                  self.gravity * np.cos(np.radians(state.road_grade))

        grade_force = self.mass * self.gravity * np.sin(np.radians(state.road_grade))

        # Calculate required power
        if throttle > 0:
            # Acceleration
            motor_torque = throttle * self._calculate_max_torque(state.motor_speed)
            motor_power = motor_torque * state.motor_speed * 2 * np.pi / 60 / 1000  # kW

            # Motor efficiency
            efficiency = self._get_motor_efficiency(motor_power, state.motor_speed)
            battery_power = motor_power / efficiency

        else:
            # Regenerative braking
            regen_power = abs(throttle) * self.motor_max_power * 0.7  # 70% max regen
            battery_power = -regen_power * 0.85  # 85% regen efficiency
            motor_power = -regen_power

        # Battery dynamics
        battery_current = battery_power * 1000 / state.battery_voltage
        voltage_drop = battery_current * self.battery_resistance
        state.battery_voltage = self._calculate_ocv(state.battery_soc) - voltage_drop

        # Energy consumed/regenerated
        energy_delta = battery_power * dt / 3600  # kWh
        state.battery_soc -= (energy_delta / self.battery_capacity) * 100

        if battery_power > 0:
            state.energy_consumed += energy_delta
        else:
            state.regeneration_energy += abs(energy_delta)

        # Battery thermal model
        heat_generation = battery_current**2 * self.battery_resistance  # Watts
        cooling_rate = (state.battery_temperature - state.ambient_temperature) * 50  # W
        temp_delta = (heat_generation - cooling_rate) * dt / self.battery_thermal_mass
        state.battery_temperature += temp_delta

        # Vehicle dynamics
        net_force = (motor_power * 1000 / max(speed_mps, 0.1)) - \
                   drag_force - rolling_resistance_force - grade_force

        acceleration = net_force / self.mass
        speed_mps += acceleration * dt
        speed_mps = max(0, speed_mps)  # Can't go backwards

        state.speed = speed_mps * 3.6  # Convert to km/h
        state.acceleration = acceleration

        # Update position (simplified)
        distance_delta = speed_mps * dt / 1000  # km
        state.odometer += distance_delta

        # Update motor state
        state.motor_speed = speed_mps / (2 * np.pi * self.wheel_radius) * 60  # RPM
        state.motor_torque = motor_power * 1000 / (state.motor_speed * 2 * np.pi / 60) \
                           if state.motor_speed > 0 else 0

        state.battery_current = battery_current
        state.timestamp = time.time()

        return state

    def _calculate_max_torque(self, motor_speed: float) -> float:
        """Calculate maximum available torque at given speed."""
        if motor_speed < 3000:
            return 400  # Nm (constant torque region)
        else:
            # Constant power region
            max_power = self.motor_max_power * 1000  # W
            return max_power / (motor_speed * 2 * np.pi / 60)

    def _get_motor_efficiency(self, power: float, speed: float) -> float:
        """Get motor efficiency from efficiency map."""
        # Simplified efficiency model
        # In production, use lookup table
        if power < 0.1 * self.motor_max_power:
            return 0.85
        elif power < 0.5 * self.motor_max_power:
            return 0.93
        elif power < 0.8 * self.motor_max_power:
            return 0.95
        else:
            return 0.92

    def _calculate_ocv(self, soc: float) -> float:
        """Calculate open-circuit voltage from SOC."""
        # Simplified polynomial fit
        # In production, use actual OCV curve
        return 300 + 100 * (soc / 100)


class DigitalTwin:
    """
    Digital twin of vehicle with bi-directional synchronization.

    Features:
    - Real-time sync with physical vehicle
    - Physics-based simulation
    - Predictive analytics
    - Virtual testing
    """

    def __init__(self, vin: str, vehicle_params: dict, cloud_config: dict):
        self.vin = vin
        self.physics_model = VehiclePhysicsModel(vehicle_params)
        self.cloud_config = cloud_config

        # Initialize state
        self.state = VehicleState(
            vin=vin,
            timestamp=time.time(),
            battery_soc=100.0,
            battery_voltage=400.0,
            battery_current=0.0,
            battery_temperature=25.0,
            motor_speed=0.0,
            motor_torque=0.0,
            speed=0.0,
            acceleration=0.0,
            position=(0.0, 0.0),
            heading=0.0,
            ambient_temperature=25.0,
            road_grade=0.0,
            odometer=0.0,
            energy_consumed=0.0,
            regeneration_energy=0.0
        )

        # MQTT connection
        self.mqtt_client = None
        self.sync_enabled = True
        self.simulation_mode = False

        # Analytics
        self.state_history = []
        self.predictions = {}

    def connect_to_cloud(self):
        """Connect to cloud platform for synchronization."""
        self.mqtt_client = mqtt.Client(client_id=f"twin-{self.vin}")

        self.mqtt_client.username_pw_set(
            self.cloud_config['mqtt_username'],
            self.cloud_config['mqtt_password']
        )

        self.mqtt_client.on_connect = self._on_connect
        self.mqtt_client.on_message = self._on_message

        self.mqtt_client.connect(
            self.cloud_config['mqtt_broker'],
            self.cloud_config['mqtt_port']
        )

        self.mqtt_client.loop_start()

    def _on_connect(self, client, userdata, flags, rc):
        """Handle MQTT connection."""
        print(f"[Twin] Connected to cloud (VIN: {self.vin})")

        # Subscribe to physical vehicle telemetry
        client.subscribe(f"vehicles/{self.vin}/telemetry/#")

        # Subscribe to commands
        client.subscribe(f"twins/{self.vin}/commands/#")

    def _on_message(self, client, userdata, msg):
        """Handle incoming messages."""
        topic_parts = msg.topic.split('/')

        if 'telemetry' in topic_parts:
            # Update from physical vehicle
            self._sync_from_physical(json.loads(msg.payload))

        elif 'commands' in topic_parts:
            # Command from cloud
            command = topic_parts[-1]
            self._handle_command(command, json.loads(msg.payload))

    def _sync_from_physical(self, telemetry: dict):
        """Synchronize state from physical vehicle."""
        if not self.sync_enabled:
            return

        print(f"[Twin] Syncing from physical vehicle")

        # Update state from telemetry
        message_type = telemetry.get('message_type')
        data = telemetry.get('data', {})

        if message_type == 'battery':
            self.state.battery_soc = data.get('soc', self.state.battery_soc)
            self.state.battery_voltage = data.get('voltage', self.state.battery_voltage)
            self.state.battery_current = data.get('current', self.state.battery_current)
            self.state.battery_temperature = data.get('temperature',
                                                     self.state.battery_temperature)

        elif message_type == 'speed':
            self.state.speed = data.get('speed', self.state.speed)
            self.state.odometer = data.get('odometer', self.state.odometer)

        elif message_type == 'location':
            self.state.position = (data.get('latitude', 0), data.get('longitude', 0))
            self.state.heading = data.get('heading', self.state.heading)

        # Publish updated twin state
        self._publish_twin_state()

    def _publish_twin_state(self):
        """Publish digital twin state to cloud."""
        if self.mqtt_client and self.mqtt_client.is_connected():
            topic = f"twins/{self.vin}/state"
            payload = json.dumps(asdict(self.state))
            self.mqtt_client.publish(topic, payload, qos=0)

    def run_simulation(self, drive_cycle: List[dict], dt: float = 0.1):
        """
        Run simulation with given drive cycle.

        Args:
            drive_cycle: List of {'time': t, 'throttle': x, 'grade': y}
            dt: Time step (seconds)
        """
        print(f"[Twin] Starting simulation (duration: {drive_cycle[-1]['time']}s)")

        self.simulation_mode = True
        self.state_history = []

        for i, cycle_point in enumerate(drive_cycle[:-1]):
            next_point = drive_cycle[i + 1]

            # Interpolate throttle
            throttle = cycle_point['throttle']
            self.state.road_grade = cycle_point.get('grade', 0)

            # Simulate
            self.state = self.physics_model.simulate_step(self.state, throttle, dt)

            # Store history
            self.state_history.append(asdict(self.state))

            # Publish periodically
            if i % 10 == 0:
                self._publish_twin_state()

            time.sleep(dt)

        self.simulation_mode = False
        print(f"[Twin] Simulation complete")

        # Analyze results
        self._analyze_simulation()

    def _analyze_simulation(self):
        """Analyze simulation results."""
        if not self.state_history:
            return

        final_state = self.state_history[-1]

        print(f"\n[Twin] Simulation Results:")
        print(f"  Distance: {final_state['odometer']:.2f} km")
        print(f"  Energy consumed: {final_state['energy_consumed']:.2f} kWh")
        print(f"  Regeneration: {final_state['regeneration_energy']:.2f} kWh")
        print(f"  Final SOC: {final_state['battery_soc']:.1f}%")
        print(f"  Efficiency: {final_state['odometer'] / final_state['energy_consumed']:.2f} km/kWh")

    def predict_range(self) -> float:
        """
        Predict remaining range based on current state and driving pattern.

        Returns:
            Predicted range in km
        """
        # Simple model: current SOC * typical efficiency
        # In production, use ML model trained on historical data

        typical_efficiency = 5.0  # km/kWh
        remaining_energy = self.state.battery_soc / 100 * self.physics_model.battery_capacity

        predicted_range = remaining_energy * typical_efficiency

        print(f"[Twin] Predicted range: {predicted_range:.1f} km")
        return predicted_range

    def predict_maintenance(self) -> Dict:
        """
        Predict maintenance needs using anomaly detection.

        Returns:
            Dictionary of predicted maintenance items
        """
        predictions = {
            'battery_health': 95.0,  # %
            'estimated_degradation': 5.0,  # %
            'cycles_remaining': 1500,
            'recommendations': []
        }

        # Check battery temperature trends
        if len(self.state_history) > 100:
            recent_temps = [s['battery_temperature'] for s in self.state_history[-100:]]
            avg_temp = np.mean(recent_temps)

            if avg_temp > 45:
                predictions['recommendations'].append(
                    "Battery running hot. Check cooling system."
                )

        # Check energy consumption anomalies
        if self.state.energy_consumed > 0:
            efficiency = self.state.odometer / self.state.energy_consumed

            if efficiency < 4.0:  # Below expected
                predictions['recommendations'].append(
                    "Low efficiency detected. Check tire pressure and alignment."
                )

        return predictions

    def _handle_command(self, command: str, params: dict):
        """Handle commands from cloud."""
        print(f"[Twin] Received command: {command}")

        if command == 'simulate':
            # Run simulation with provided drive cycle
            drive_cycle = params.get('drive_cycle', [])
            self.run_simulation(drive_cycle)

        elif command == 'predict_range':
            # Predict range
            range_km = self.predict_range()
            self.mqtt_client.publish(
                f"twins/{self.vin}/predictions/range",
                json.dumps({'range_km': range_km})
            )

        elif command == 'predict_maintenance':
            # Predict maintenance
            predictions = self.predict_maintenance()
            self.mqtt_client.publish(
                f"twins/{self.vin}/predictions/maintenance",
                json.dumps(predictions)
            )

    def export_state_history(self, filename: str):
        """Export state history to file for analysis."""
        with open(filename, 'w') as f:
            json.dump(self.state_history, f, indent=2)

        print(f"[Twin] State history exported to {filename}")


# Example usage
def main():
    """Example digital twin usage."""

    # Vehicle parameters (Tesla Model 3 Long Range approximate)
    vehicle_params = {
        'mass': 1847,  # kg
        'drag_coefficient': 0.23,
        'frontal_area': 2.22,  # m^2
        'rolling_resistance': 0.01,
        'wheel_radius': 0.368,  # m (18" wheels)
        'battery_capacity': 82,  # kWh
        'battery_resistance': 0.05,  # Ohms
        'battery_thermal_mass': 50000,  # J/K
        'motor_max_power': 258,  # kW (combined front+rear)
        'motor_efficiency_map': {}
    }

    cloud_config = {
        'mqtt_broker': 'mqtt.example.com',
        'mqtt_port': 8883,
        'mqtt_username': 'twin-client',
        'mqtt_password': 'password'
    }

    # Create digital twin
    twin = DigitalTwin('VIN123456789', vehicle_params, cloud_config)
    twin.connect_to_cloud()

    # Example drive cycle (WLTP-like)
    drive_cycle = []
    for t in range(0, 1800, 10):  # 30 minutes
        if t < 600:
            throttle = 0.3  # City driving
        elif t < 1200:
            throttle = 0.5  # Highway
        else:
            throttle = 0.2  # Slow down

        drive_cycle.append({
            'time': t,
            'throttle': throttle,
            'grade': 0
        })

    # Run simulation
    twin.run_simulation(drive_cycle, dt=10.0)

    # Predictions
    twin.predict_range()
    twin.predict_maintenance()

    # Export data
    twin.export_state_history('twin_history.json')


if __name__ == "__main__":
    main()
```

### 2. Azure Digital Twins Integration

```yaml
# Azure Digital Twins model definition (DTDL)
# File: vehicle-model.json

{
  "@context": "dtmi:dtdl:context;2",
  "@id": "dtmi:com:example:Vehicle;1",
  "@type": "Interface",
  "displayName": "Electric Vehicle",
  "contents": [
    {
      "@type": "Property",
      "name": "vin",
      "schema": "string",
      "description": "Vehicle Identification Number"
    },
    {
      "@type": "Telemetry",
      "name": "battery",
      "schema": {
        "@type": "Object",
        "fields": [
          {
            "name": "soc",
            "schema": "double"
          },
          {
            "name": "voltage",
            "schema": "double"
          },
          {
            "name": "current",
            "schema": "double"
          },
          {
            "name": "temperature",
            "schema": "double"
          }
        ]
      }
    },
    {
      "@type": "Telemetry",
      "name": "location",
      "schema": "geopoint"
    },
    {
      "@type": "Telemetry",
      "name": "speed",
      "schema": "double"
    },
    {
      "@type": "Command",
      "name": "predictRange",
      "response": {
        "name": "rangeResult",
        "schema": "double"
      }
    },
    {
      "@type": "Command",
      "name": "simulateDriveCycle",
      "request": {
        "name": "driveCycleData",
        "schema": "string"
      }
    }
  ]
}
```

### 3. CI/CD Pipeline for Digital Twin

```yaml
# File: .github/workflows/digital-twin-ci.yml

name: Digital Twin CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run unit tests
        run: |
          pytest tests/ --cov=digital_twin --cov-report=xml

      - name: Run physics model validation
        run: |
          python tests/validate_physics.py

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  simulate:
    runs-on: ubuntu-latest
    needs: test

    steps:
      - uses: actions/checkout@v3

      - name: Run simulation tests
        run: |
          python digital_twin.py --mode simulation \
            --drive-cycle tests/wltp_cycle.json \
            --output results/

      - name: Validate results
        run: |
          python tests/validate_simulation.py results/

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: simulation-results
          path: results/

  deploy:
    runs-on: ubuntu-latest
    needs: [test, simulate]
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Deploy to AWS IoT
        run: |
          aws iot create-thing --thing-name digital-twin-${{ github.sha }}
          aws lambda update-function-code \
            --function-name vehicle-digital-twin \
            --zip-file fileb://digital_twin.zip
```

## Real-World Examples

### Tesla Digital Twin
- **Fleet learning**: Aggregate shadow mode data for Autopilot
- **Battery degradation modeling**: Predict range loss over time
- **Virtual testing**: Test new software on digital fleet before OTA
- **Predictive maintenance**: Schedule service based on digital twin analysis

### BMW Digital Twin
- **Production line**: Digital twin during manufacturing
- **Lifetime tracking**: Track vehicle from production to end-of-life
- **Service optimization**: Predict maintenance needs
- **Retrofit planning**: Test compatibility of new features

### Rivian Adventure Network
- **Route optimization**: Simulate range on planned routes
- **Charging strategy**: Optimize charging stops
- **Off-road capability**: Simulate vehicle performance on trails
- **Load planning**: Test vehicle with different cargo/trailer loads

## Best Practices

1. **High-fidelity physics**: Use validated physics models
2. **Real-time sync**: Keep twin synchronized with physical vehicle
3. **Historical data**: Store state history for analytics
4. **Predictive models**: Use ML for maintenance predictions
5. **Virtual testing**: Test software on twins before deployment
6. **CI/CD integration**: Automate testing with digital twins
7. **Fleet-wide insights**: Aggregate data across all twins
8. **Privacy protection**: Anonymize sensitive data
9. **Model validation**: Continuously validate against real-world data
10. **Scalability**: Design for millions of twins

## Security Considerations

- **Authentication**: Secure twin-to-cloud communication
- **Data encryption**: Encrypt state data and telemetry
- **Access control**: Limit who can command twins
- **Audit logging**: Track all twin operations
- **Simulation isolation**: Sandbox simulation environments
- **Model protection**: Protect proprietary physics models

## References

- **Azure Digital Twins**: https://azure.microsoft.com/en-us/products/digital-twins/
- **AWS IoT TwinMaker**: https://aws.amazon.com/iot-twinmaker/
- **Eclipse Ditto**: https://www.eclipse.org/ditto/
- **Digital Twin Consortium**: https://www.digitaltwinconsortium.org/

---

## Ota Update Systems

# OTA Update Systems — Over-The-Air Updates for Vehicles

Expert knowledge of OTA (Over-The-Air) update architecture, A/B partitioning, differential updates, rollback mechanisms, secure boot chain, and update orchestration across ECUs.

## Core Concepts

### Update Architecture Patterns

1. **Full Image Updates**: Complete partition replacement
2. **Differential Updates**: Binary diffs to minimize bandwidth
3. **Component Updates**: Individual ECU/application updates
4. **Atomic Updates**: All-or-nothing update transactions
5. **Staged Rollouts**: Phased deployment across fleet

### Security Requirements

- **Uptane Framework**: Industry standard for secure vehicle updates
- **TUF (The Update Framework)**: Metadata and signature verification
- **Secure Boot Chain**: UEFI/U-Boot signature validation
- **Hardware Root of Trust**: TPM/HSM for key storage
- **Rollback Protection**: Anti-rollback counters

## Production-Ready Implementations

### 1. Uptane-Compliant Update Client (Python)

```python
#!/usr/bin/env python3
"""
Uptane-compliant OTA update client for automotive ECUs.
Implements Director and Image repository verification.
"""

import hashlib
import json
import os
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional
import requests
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.backends import default_backend


@dataclass
class UpdateMetadata:
    """Update metadata from Director repository."""
    version: str
    targets: Dict[str, dict]
    signatures: List[dict]
    expires: str

    @classmethod
    def from_json(cls, data: dict):
        return cls(
            version=data["signed"]["version"],
            targets=data["signed"]["targets"],
            signatures=data["signatures"],
            expires=data["signed"]["expires"]
        )


class UptaneClient:
    """
    Uptane OTA update client.

    Supports:
    - Dual Director/Image repository verification
    - Signature validation with threshold
    - Differential update download
    - A/B partition switching
    - Automatic rollback on boot failure
    """

    def __init__(self, config_path: str = "/etc/ota/uptane-config.json"):
        self.config = self._load_config(config_path)
        self.ecu_serial = self._get_ecu_serial()
        self.current_version = self._get_current_version()
        self.director_url = self.config["director_url"]
        self.image_repo_url = self.config["image_repo_url"]
        self.root_keys = self._load_root_keys()

    def _load_config(self, path: str) -> dict:
        """Load Uptane configuration."""
        with open(path, 'r') as f:
            return json.load(f)

    def _get_ecu_serial(self) -> str:
        """Get unique ECU serial number."""
        # Read from secure storage (TPM, EEPROM, etc.)
        serial_path = Path("/sys/firmware/devicetree/base/serial-number")
        if serial_path.exists():
            return serial_path.read_text().strip()
        return os.uname().nodename  # Fallback

    def _get_current_version(self) -> str:
        """Get currently running software version."""
        version_path = Path("/etc/ota/current-version")
        if version_path.exists():
            return version_path.read_text().strip()
        return "unknown"

    def _load_root_keys(self) -> List[rsa.RSAPublicKey]:
        """Load root public keys for signature verification."""
        keys = []
        for key_file in self.config["root_keys"]:
            with open(key_file, 'rb') as f:
                key = serialization.load_pem_public_key(
                    f.read(),
                    backend=default_backend()
                )
                keys.append(key)
        return keys

    def verify_signature(self, data: bytes, signature: bytes,
                        public_key: rsa.RSAPublicKey) -> bool:
        """Verify RSA signature on data."""
        try:
            public_key.verify(
                signature,
                data,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return True
        except Exception as e:
            print(f"Signature verification failed: {e}")
            return False

    def check_for_updates(self) -> Optional[UpdateMetadata]:
        """
        Check Director repository for available updates.

        Returns:
            UpdateMetadata if update available, None otherwise
        """
        print(f"[OTA] Checking for updates (ECU: {self.ecu_serial}, "
              f"Version: {self.current_version})")

        # Fetch Director metadata
        url = f"{self.director_url}/metadata/{self.ecu_serial}/targets.json"
        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            metadata = UpdateMetadata.from_json(response.json())

            # Verify signatures (threshold: 2/3)
            verified_sigs = 0
            for sig_data in metadata.signatures:
                sig_bytes = bytes.fromhex(sig_data["sig"])
                # Verify against root keys
                for key in self.root_keys:
                    if self.verify_signature(
                        json.dumps(response.json()["signed"]).encode(),
                        sig_bytes,
                        key
                    ):
                        verified_sigs += 1
                        break

            if verified_sigs < self.config.get("signature_threshold", 2):
                raise ValueError(f"Insufficient signatures: {verified_sigs}")

            # Check if update is newer
            for target_name, target_info in metadata.targets.items():
                if target_info["custom"].get("ecu_identifier") == self.ecu_serial:
                    target_version = target_info["custom"]["version"]
                    if target_version != self.current_version:
                        print(f"[OTA] Update available: {target_version}")
                        return metadata

            print("[OTA] No updates available")
            return None

        except Exception as e:
            print(f"[OTA] Error checking for updates: {e}")
            return None

    def download_update(self, metadata: UpdateMetadata) -> Optional[Path]:
        """
        Download update image from Image repository.

        Uses differential updates if available.

        Returns:
            Path to downloaded update file
        """
        for target_name, target_info in metadata.targets.items():
            if target_info["custom"].get("ecu_identifier") != self.ecu_serial:
                continue

            # Check for differential update
            if "delta_from" in target_info["custom"]:
                if target_info["custom"]["delta_from"] == self.current_version:
                    print("[OTA] Downloading differential update...")
                    url = f"{self.image_repo_url}/targets/{target_name}.delta"
                else:
                    print("[OTA] Delta not applicable, downloading full image")
                    url = f"{self.image_repo_url}/targets/{target_name}"
            else:
                print("[OTA] Downloading full update image...")
                url = f"{self.image_repo_url}/targets/{target_name}"

            # Download with progress
            download_path = Path(f"/tmp/ota-update-{target_name}")
            try:
                with requests.get(url, stream=True, timeout=300) as r:
                    r.raise_for_status()
                    total_size = int(r.headers.get('content-length', 0))
                    downloaded = 0

                    with open(download_path, 'wb') as f:
                        for chunk in r.iter_content(chunk_size=8192):
                            f.write(chunk)
                            downloaded += len(chunk)
                            progress = (downloaded / total_size * 100) if total_size else 0
                            print(f"\r[OTA] Download progress: {progress:.1f}%", end='')

                    print()  # New line after progress

                # Verify hash
                expected_hash = target_info["hashes"]["sha256"]
                actual_hash = self._compute_sha256(download_path)

                if actual_hash != expected_hash:
                    raise ValueError(f"Hash mismatch: {actual_hash} != {expected_hash}")

                print(f"[OTA] Download complete: {download_path}")
                return download_path

            except Exception as e:
                print(f"[OTA] Download failed: {e}")
                if download_path.exists():
                    download_path.unlink()
                return None

        return None

    def _compute_sha256(self, file_path: Path) -> str:
        """Compute SHA256 hash of file."""
        sha256 = hashlib.sha256()
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                sha256.update(chunk)
        return sha256.hexdigest()

    def install_update(self, update_path: Path) -> bool:
        """
        Install update to inactive partition.

        Uses A/B partition switching for atomic updates.

        Returns:
            True if installation successful
        """
        print("[OTA] Installing update...")

        try:
            # Determine inactive partition
            current_slot = self._get_current_boot_slot()
            inactive_slot = 'b' if current_slot == 'a' else 'a'
            inactive_partition = f"/dev/mmcblk0p{2 if inactive_slot == 'b' else 1}"

            print(f"[OTA] Current slot: {current_slot}, "
                  f"Installing to: {inactive_slot}")

            # Write update to inactive partition
            cmd = f"dd if={update_path} of={inactive_partition} bs=4M status=progress"
            subprocess.run(cmd, shell=True, check=True)

            # Set boot slot to inactive (will become active on next boot)
            self._set_boot_slot(inactive_slot)

            # Mark for boot attempt counter (rollback if boot fails 3 times)
            self._set_boot_counter(3)

            print(f"[OTA] Update installed to slot {inactive_slot}")
            return True

        except Exception as e:
            print(f"[OTA] Installation failed: {e}")
            return False

    def _get_current_boot_slot(self) -> str:
        """Get currently booted partition slot."""
        # Read from U-Boot environment or kernel command line
        with open("/proc/cmdline", 'r') as f:
            cmdline = f.read()
            if "root=/dev/mmcblk0p1" in cmdline:
                return 'a'
            elif "root=/dev/mmcblk0p2" in cmdline:
                return 'b'
        return 'a'  # Default

    def _set_boot_slot(self, slot: str):
        """Set boot slot for next reboot."""
        # Write to U-Boot environment
        cmd = f"fw_setenv boot_slot {slot}"
        subprocess.run(cmd, shell=True, check=True)

    def _set_boot_counter(self, count: int):
        """Set boot attempt counter for rollback protection."""
        cmd = f"fw_setenv boot_counter {count}"
        subprocess.run(cmd, shell=True, check=True)

    def apply_update(self) -> bool:
        """
        Apply update by rebooting into new partition.

        Returns:
            True if reboot initiated
        """
        print("[OTA] Applying update (rebooting)...")
        try:
            subprocess.run(["reboot"], check=True)
            return True
        except Exception as e:
            print(f"[OTA] Reboot failed: {e}")
            return False

    def verify_boot_success(self):
        """
        Verify successful boot after update.

        Called by systemd service on boot.
        Confirms update success or triggers rollback.
        """
        boot_counter_path = Path("/proc/device-tree/chosen/u-boot,boot-counter")

        if boot_counter_path.exists():
            counter = int(boot_counter_path.read_text().strip())

            if counter > 0:
                # Boot successful, commit update
                print("[OTA] Boot successful, committing update")
                self._set_boot_counter(0)  # Clear counter

                # Update current version
                new_version = self._detect_version()
                Path("/etc/ota/current-version").write_text(new_version)
            else:
                print("[OTA] Already committed")
        else:
            print("[OTA] Boot counter not found (no pending update)")

    def _detect_version(self) -> str:
        """Detect software version from running system."""
        version_files = [
            "/etc/ota/version",
            "/etc/os-release"
        ]

        for path in version_files:
            if Path(path).exists():
                content = Path(path).read_text()
                # Extract version from os-release
                for line in content.split('\n'):
                    if line.startswith("VERSION="):
                        return line.split('=')[1].strip('"')

        return "unknown"


def main():
    """OTA update client main loop."""
    client = UptaneClient()

    # Check on boot
    client.verify_boot_success()

    # Periodic update check
    while True:
        metadata = client.check_for_updates()

        if metadata:
            update_path = client.download_update(metadata)

            if update_path:
                if client.install_update(update_path):
                    print("[OTA] Update ready, will apply on next reboot")
                    # Optionally auto-reboot or wait for user confirmation
                    # client.apply_update()

        # Check every hour
        time.sleep(3600)


if __name__ == "__main__":
    main()
```

### 2. A/B Partition Configuration (U-Boot)

```bash
# U-Boot environment for A/B partitioning
# File: /etc/fw_env.config

# Device              Offset    Size     Erasesize
/dev/mtd1             0x0000    0x1000   0x1000
/dev/mtd2             0x0000    0x1000   0x1000
```

```bash
# U-Boot bootcmd script for A/B boot
# File: boot.cmd

# Read boot slot from environment
setenv bootslot ${boot_slot}
if test -z "${bootslot}"; then
    setenv bootslot a
fi

# Read boot counter
setenv bootcount ${boot_counter}
if test -z "${bootcount}"; then
    setenv bootcount 0
fi

# Check rollback condition
if test ${bootcount} -eq 0; then
    echo "Booting from slot ${bootslot}"
else
    # Decrement boot counter
    setexpr bootcount ${bootcount} - 1
    setenv boot_counter ${bootcount}
    saveenv

    # If counter reaches 0, rollback to other slot
    if test ${bootcount} -eq 0; then
        echo "Boot failed 3 times, rolling back"
        if test "${bootslot}" = "a"; then
            setenv bootslot b
        else
            setenv bootslot a
        fi
        setenv boot_slot ${bootslot}
        saveenv
    fi
fi

# Set root partition
if test "${bootslot}" = "a"; then
    setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p1 rw rootwait
    load mmc 0:1 ${kernel_addr_r} /boot/Image
    load mmc 0:1 ${fdt_addr_r} /boot/dtb
else
    setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rw rootwait
    load mmc 0:2 ${kernel_addr_r} /boot/Image
    load mmc 0:2 ${fdt_addr_r} /boot/dtb
fi

# Boot kernel
booti ${kernel_addr_r} - ${fdt_addr_r}
```

### 3. Differential Update Generator (Python)

```python
#!/usr/bin/env python3
"""
Generate binary differential updates for OTA.
Uses bsdiff algorithm for efficient bandwidth usage.
"""

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path


def generate_delta(old_image: Path, new_image: Path, output: Path):
    """
    Generate binary diff between two images.

    Args:
        old_image: Path to old firmware image
        new_image: Path to new firmware image
        output: Path to output delta file
    """
    print(f"Generating delta: {old_image} -> {new_image}")

    # Use bsdiff for binary diffing
    cmd = ["bsdiff", str(old_image), str(new_image), str(output)]

    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        print("Error: bsdiff not found. Install with: apt-get install bsdiff")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error generating delta: {e}")
        sys.exit(1)

    # Calculate sizes and compression ratio
    old_size = old_image.stat().st_size
    new_size = new_image.stat().st_size
    delta_size = output.stat().st_size

    ratio = (1 - delta_size / new_size) * 100

    print(f"Old image size: {old_size / 1024 / 1024:.2f} MB")
    print(f"New image size: {new_size / 1024 / 1024:.2f} MB")
    print(f"Delta size: {delta_size / 1024 / 1024:.2f} MB")
    print(f"Bandwidth savings: {ratio:.1f}%")

    # Generate metadata
    metadata = {
        "old_version": old_image.stem,
        "new_version": new_image.stem,
        "old_hash": compute_sha256(old_image),
        "new_hash": compute_sha256(new_image),
        "delta_hash": compute_sha256(output),
        "delta_size": delta_size,
        "compression_ratio": ratio
    }

    metadata_path = output.with_suffix('.json')
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    print(f"Metadata written to: {metadata_path}")


def compute_sha256(path: Path) -> str:
    """Compute SHA256 hash of file."""
    sha256 = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return sha256.hexdigest()


def apply_delta(old_image: Path, delta: Path, output: Path):
    """
    Apply delta patch to old image.

    Args:
        old_image: Path to old firmware image
        delta: Path to delta file
        output: Path to output patched image
    """
    print(f"Applying delta: {old_image} + {delta} -> {output}")

    cmd = ["bspatch", str(old_image), str(output), str(delta)]

    try:
        subprocess.run(cmd, check=True)
        print(f"Patched image created: {output}")
    except FileNotFoundError:
        print("Error: bspatch not found. Install with: apt-get install bsdiff")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error applying delta: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="OTA differential update generator")
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    # Generate delta
    gen_parser = subparsers.add_parser('generate', help='Generate delta update')
    gen_parser.add_argument('--old', type=Path, required=True, help='Old image')
    gen_parser.add_argument('--new', type=Path, required=True, help='New image')
    gen_parser.add_argument('--output', type=Path, required=True, help='Output delta file')

    # Apply delta
    apply_parser = subparsers.add_parser('apply', help='Apply delta update')
    apply_parser.add_argument('--old', type=Path, required=True, help='Old image')
    apply_parser.add_argument('--delta', type=Path, required=True, help='Delta file')
    apply_parser.add_argument('--output', type=Path, required=True, help='Output image')

    args = parser.parse_args()

    if args.command == 'generate':
        generate_delta(args.old, args.new, args.output)
    elif args.command == 'apply':
        apply_delta(args.old, args.delta, args.output)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
```

### 4. OTA Update Service (systemd)

```ini
# File: /etc/systemd/system/ota-update.service

[Unit]
Description=OTA Update Client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/uptane-client.py
Restart=always
RestartSec=60
User=ota
Group=ota

# Security hardening
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/tmp /var/lib/ota
NoNewPrivileges=yes
CapabilityBoundingSet=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

```ini
# File: /etc/systemd/system/ota-boot-verify.service

[Unit]
Description=OTA Boot Verification
DefaultDependencies=no
After=local-fs.target
Before=sysinit.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 -c "from uptane_client import UptaneClient; UptaneClient().verify_boot_success()"
RemainAfterExit=yes

[Install]
WantedBy=sysinit.target
```

### 5. Mender Integration (Alternative Framework)

```yaml
# File: /etc/mender/mender.conf
{
  "ServerURL": "https://ota.example.com",
  "TenantToken": "TENANT_TOKEN_HERE",
  "InventoryPollIntervalSeconds": 28800,
  "UpdatePollIntervalSeconds": 1800,
  "RetryPollIntervalSeconds": 300,
  "RootfsPartA": "/dev/mmcblk0p2",
  "RootfsPartB": "/dev/mmcblk0p3",
  "ServerCertificate": "/etc/mender/server.crt",
  "DeviceTypeFile": "/var/lib/mender/device_type"
}
```

```bash
# Mender artifact creation script
#!/bin/bash
# File: create-mender-artifact.sh

set -e

IMAGE_FILE=$1
ARTIFACT_NAME=$2
DEVICE_TYPE=$3

if [ -z "$IMAGE_FILE" ] || [ -z "$ARTIFACT_NAME" ] || [ -z "$DEVICE_TYPE" ]; then
    echo "Usage: $0 <image-file> <artifact-name> <device-type>"
    exit 1
fi

# Create Mender artifact
mender-artifact write rootfs-image \
    --file "$IMAGE_FILE" \
    --artifact-name "$ARTIFACT_NAME" \
    --device-type "$DEVICE_TYPE" \
    --output-path "${ARTIFACT_NAME}.mender"

echo "Mender artifact created: ${ARTIFACT_NAME}.mender"

# Sign artifact (optional)
if [ -f "private.key" ]; then
    mender-artifact sign "${ARTIFACT_NAME}.mender" \
        --key private.key \
        --output-path "${ARTIFACT_NAME}.signed.mender"

    echo "Signed artifact created: ${ARTIFACT_NAME}.signed.mender"
fi
```

## Real-World Examples

### Tesla OTA Architecture

- **Full stack updates**: Entire OS, kernel, applications
- **Dual-bank storage**: 2x storage for A/B switching
- **Cellular + WiFi**: Automatic download scheduling
- **User control**: Schedule updates, defer if driving
- **Rollback**: Automatic if vehicle fails self-test

### VW.OS Update Strategy

- **ECU orchestration**: Update multiple ECUs in sequence
- **Safety constraints**: No updates to critical systems while driving
- **Partial updates**: Update infotainment without touching ADAS
- **Fleet rollout**: Phased deployment by region/model

### GM Ultifi Platform

- **Container-based**: Update individual apps without full reflash
- **Middleware updates**: Update communication layer separately
- **Third-party apps**: App store model with independent update cycle
- **Cloud sync**: Configuration sync across vehicles

## Best Practices

1. **Always use A/B partitioning**: Never update the running system
2. **Implement rollback**: Automatic rollback after 3 boot failures
3. **Verify signatures**: Multi-level signature verification (Uptane)
4. **Use differential updates**: Reduce bandwidth by 70-90%
5. **Stage fleet rollouts**: 1% -> 10% -> 100% deployment
6. **Monitor success rates**: Track update success/failure metrics
7. **Preserve user data**: Never wipe data partitions
8. **Test offline rollback**: Ensure rollback works without network
9. **Schedule updates**: Respect user preferences and vehicle state
10. **Log everything**: Comprehensive telemetry for debugging

## Security Considerations

- **Secure Boot**: Verify every component in boot chain
- **Encrypted updates**: TLS for transport, encryption at rest
- **Anti-rollback**: Prevent downgrade to vulnerable versions
- **Time validity**: Reject updates with expired metadata
- **Threshold signatures**: Require multiple signers (2 of 3)
- **Hardware root of trust**: TPM or secure enclave for keys
- **Audit logging**: Track all update attempts and outcomes

## References

- **Uptane**: https://uptane.github.io/
- **Mender**: https://mender.io/
- **SWUpdate**: https://sbabic.github.io/swupdate/
- **RAUC**: https://rauc.io/
- **TUF Specification**: https://theupdateframework.io/

---

## Vehicle App Stores

# Vehicle App Stores — Automotive Application Platforms

Expert knowledge of automotive app platforms, app lifecycle management, sandboxing, permissions model, revenue sharing, 3rd-party developer SDKs, and app certification.

## Core Concepts

### App Store Architecture

1. **App Marketplace**: Discovery, purchase, installation
2. **Developer Portal**: App submission, certification, analytics
3. **Runtime Environment**: Sandboxed execution environment
4. **Payment Integration**: In-app purchases, subscriptions
5. **Update Management**: Automatic app updates

### App Types

- **Infotainment Apps**: Media, navigation, productivity
- **ADAS Extensions**: Enhanced driver assistance features
- **Telematics Apps**: Fleet management, usage tracking
- **Comfort Apps**: Climate control, seat adjustments
- **Diagnostic Tools**: Vehicle health monitoring

## Production-Ready Implementation

### 1. App Store Backend API (Python/FastAPI)

```python
#!/usr/bin/env python3
"""
Vehicle App Store Backend API.

Handles:
- App catalog management
- User authentication and purchases
- App installation and updates
- Developer portal integration
"""

from datetime import datetime, timedelta
from enum import Enum
from typing import List, Optional
from fastapi import FastAPI, HTTPException, Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, Column, String, Integer, Float, DateTime, Boolean, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import jwt
import hashlib


# Database models
Base = declarative_base()


class AppCategory(str, Enum):
    """App categories."""
    NAVIGATION = "navigation"
    MEDIA = "media"
    PRODUCTIVITY = "productivity"
    GAMES = "games"
    UTILITIES = "utilities"
    ADAS = "adas"
    DIAGNOSTICS = "diagnostics"


class AppStatus(str, Enum):
    """App certification status."""
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    SUSPENDED = "suspended"


class App(Base):
    """Application model."""
    __tablename__ = "apps"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    developer_id = Column(String, nullable=False)
    category = Column(String, nullable=False)
    version = Column(String, nullable=False)
    description = Column(String)
    price = Column(Float, default=0.0)
    rating = Column(Float, default=0.0)
    downloads = Column(Integer, default=0)
    status = Column(String, default=AppStatus.PENDING.value)
    manifest_url = Column(String)
    icon_url = Column(String)
    screenshots = Column(JSON, default=list)
    permissions = Column(JSON, default=list)
    min_platform_version = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class User(Base):
    """User model."""
    __tablename__ = "users"

    id = Column(String, primary_key=True)
    vin = Column(String, unique=True, nullable=False)  # Vehicle VIN
    email = Column(String)
    purchased_apps = Column(JSON, default=list)
    installed_apps = Column(JSON, default=list)
    created_at = Column(DateTime, default=datetime.utcnow)


class Purchase(Base):
    """Purchase transaction model."""
    __tablename__ = "purchases"

    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False)
    app_id = Column(String, nullable=False)
    amount = Column(Float)
    transaction_date = Column(DateTime, default=datetime.utcnow)
    status = Column(String, default="completed")


# Pydantic schemas
class AppCreate(BaseModel):
    """App creation schema."""
    name: str
    developer_id: str
    category: AppCategory
    version: str
    description: str
    price: float = 0.0
    manifest_url: str
    icon_url: str
    screenshots: List[str] = []
    permissions: List[str] = []
    min_platform_version: str = "1.0.0"


class AppResponse(BaseModel):
    """App response schema."""
    id: str
    name: str
    developer_id: str
    category: str
    version: str
    description: str
    price: float
    rating: float
    downloads: int
    status: str
    icon_url: str
    screenshots: List[str]
    permissions: List[str]
    created_at: datetime

    class Config:
        from_attributes = True


class PurchaseRequest(BaseModel):
    """Purchase request schema."""
    app_id: str
    payment_method: str = "credit_card"


class InstallRequest(BaseModel):
    """App installation request."""
    app_id: str


# Initialize FastAPI
app = FastAPI(title="Vehicle App Store API", version="1.0.0")
security = HTTPBearer()

# Database setup
DATABASE_URL = "postgresql://appstore:password@localhost/vehicle_appstore"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# JWT secret
JWT_SECRET = "your-secret-key-change-in-production"


def get_db():
    """Database session dependency."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def verify_token(credentials: HTTPAuthorizationCredentials = Security(security)) -> dict:
    """Verify JWT token and extract user info."""
    try:
        token = credentials.credentials
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


@app.post("/auth/login")
async def login(vin: str, db: Session = Depends(get_db)):
    """
    Authenticate vehicle by VIN.

    In production, this would verify VIN against manufacturer database.
    """
    user = db.query(User).filter(User.vin == vin).first()

    if not user:
        # Create new user
        user = User(id=hashlib.sha256(vin.encode()).hexdigest()[:16], vin=vin)
        db.add(user)
        db.commit()

    # Generate JWT
    token = jwt.encode(
        {
            "user_id": user.id,
            "vin": user.vin,
            "exp": datetime.utcnow() + timedelta(days=30)
        },
        JWT_SECRET,
        algorithm="HS256"
    )

    return {"access_token": token, "token_type": "bearer"}


@app.get("/apps", response_model=List[AppResponse])
async def list_apps(
    category: Optional[AppCategory] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    List available apps.

    Filters by category and search query.
    Only returns approved apps.
    """
    query = db.query(App).filter(App.status == AppStatus.APPROVED.value)

    if category:
        query = query.filter(App.category == category.value)

    if search:
        query = query.filter(App.name.ilike(f"%{search}%"))

    apps = query.order_by(App.rating.desc(), App.downloads.desc()).limit(50).all()
    return apps


@app.get("/apps/{app_id}", response_model=AppResponse)
async def get_app(app_id: str, db: Session = Depends(get_db)):
    """Get app details."""
    app_obj = db.query(App).filter(App.id == app_id).first()

    if not app_obj:
        raise HTTPException(status_code=404, detail="App not found")

    return app_obj


@app.post("/apps", response_model=AppResponse)
async def submit_app(
    app_data: AppCreate,
    user_info: dict = Depends(verify_token),
    db: Session = Depends(get_db)
):
    """
    Submit new app for certification.

    Developer portal endpoint.
    """
    app_id = hashlib.sha256(
        f"{app_data.name}{app_data.developer_id}{datetime.utcnow()}".encode()
    ).hexdigest()[:16]

    app_obj = App(
        id=app_id,
        name=app_data.name,
        developer_id=app_data.developer_id,
        category=app_data.category.value,
        version=app_data.version,
        description=app_data.description,
        price=app_data.price,
        manifest_url=app_data.manifest_url,
        icon_url=app_data.icon_url,
        screenshots=app_data.screenshots,
        permissions=app_data.permissions,
        min_platform_version=app_data.min_platform_version,
        status=AppStatus.PENDING.value
    )

    db.add(app_obj)
    db.commit()
    db.refresh(app_obj)

    return app_obj


@app.post("/apps/{app_id}/purchase")
async def purchase_app(
    app_id: str,
    purchase_data: PurchaseRequest,
    user_info: dict = Depends(verify_token),
    db: Session = Depends(get_db)
):
    """
    Purchase app.

    Handles payment processing and license activation.
    """
    app_obj = db.query(App).filter(App.id == app_id).first()

    if not app_obj:
        raise HTTPException(status_code=404, detail="App not found")

    user = db.query(User).filter(User.id == user_info["user_id"]).first()

    # Check if already purchased
    if app_id in user.purchased_apps:
        return {"message": "App already purchased", "app_id": app_id}

    # Process payment (integrate with payment gateway)
    # For demo purposes, assume payment succeeds
    purchase_id = hashlib.sha256(
        f"{user.id}{app_id}{datetime.utcnow()}".encode()
    ).hexdigest()[:16]

    purchase = Purchase(
        id=purchase_id,
        user_id=user.id,
        app_id=app_id,
        amount=app_obj.price,
        status="completed"
    )

    # Update user purchased apps
    user.purchased_apps.append(app_id)

    # Increment app downloads
    app_obj.downloads += 1

    db.add(purchase)
    db.commit()

    return {
        "message": "Purchase successful",
        "purchase_id": purchase_id,
        "app_id": app_id,
        "amount": app_obj.price
    }


@app.post("/apps/{app_id}/install")
async def install_app(
    app_id: str,
    user_info: dict = Depends(verify_token),
    db: Session = Depends(get_db)
):
    """
    Install app to vehicle.

    Returns manifest URL for vehicle runtime to download.
    """
    user = db.query(User).filter(User.id == user_info["user_id"]).first()

    # Check if purchased
    if app_id not in user.purchased_apps:
        raise HTTPException(status_code=403, detail="App not purchased")

    app_obj = db.query(App).filter(App.id == app_id).first()

    if not app_obj:
        raise HTTPException(status_code=404, detail="App not found")

    # Add to installed apps
    if app_id not in user.installed_apps:
        user.installed_apps.append(app_id)
        db.commit()

    return {
        "message": "Installation initiated",
        "app_id": app_id,
        "manifest_url": app_obj.manifest_url,
        "version": app_obj.version
    }


@app.get("/apps/{app_id}/updates")
async def check_app_updates(
    app_id: str,
    current_version: str,
    user_info: dict = Depends(verify_token),
    db: Session = Depends(get_db)
):
    """
    Check for app updates.

    Returns latest version if newer than current.
    """
    app_obj = db.query(App).filter(App.id == app_id).first()

    if not app_obj:
        raise HTTPException(status_code=404, detail="App not found")

    if app_obj.version != current_version:
        return {
            "update_available": True,
            "latest_version": app_obj.version,
            "manifest_url": app_obj.manifest_url,
            "changelog": f"Updated to version {app_obj.version}"
        }

    return {"update_available": False}


@app.get("/user/apps")
async def get_user_apps(
    user_info: dict = Depends(verify_token),
    db: Session = Depends(get_db)
):
    """Get user's purchased and installed apps."""
    user = db.query(User).filter(User.id == user_info["user_id"]).first()

    purchased = db.query(App).filter(App.id.in_(user.purchased_apps)).all()
    installed = db.query(App).filter(App.id.in_(user.installed_apps)).all()

    return {
        "purchased": [AppResponse.from_orm(app) for app in purchased],
        "installed": [AppResponse.from_orm(app) for app in installed]
    }


@app.post("/apps/{app_id}/rate")
async def rate_app(
    app_id: str,
    rating: float = Field(..., ge=1.0, le=5.0),
    user_info: dict = Depends(verify_token),
    db: Session = Depends(get_db)
):
    """Rate an app (1-5 stars)."""
    user = db.query(User).filter(User.id == user_info["user_id"]).first()

    if app_id not in user.purchased_apps:
        raise HTTPException(status_code=403, detail="Must own app to rate")

    app_obj = db.query(App).filter(App.id == app_id).first()

    # Update rolling average (simplified)
    # In production, store individual ratings
    app_obj.rating = (app_obj.rating + rating) / 2

    db.commit()

    return {"message": "Rating submitted", "new_rating": app_obj.rating}


if __name__ == "__main__":
    import uvicorn
    Base.metadata.create_all(bind=engine)
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### 2. App Manifest Format

```yaml
# App manifest - describes app metadata and requirements
# File: app-manifest.yaml

apiVersion: vehicle.app/v1
kind: VehicleApp
metadata:
  name: spotify-automotive
  version: 2.1.4
  displayName: Spotify for Cars
  developer:
    id: spotify-inc
    name: Spotify AB
    email: automotive@spotify.com
    website: https://www.spotify.com

spec:
  description: |
    Stream millions of songs and podcasts directly in your vehicle.
    Integrates with vehicle audio system and steering wheel controls.

  category: media
  price: 0.0  # Free with subscription
  inAppPurchases: true

  # Platform requirements
  platform:
    minVersion: "2.0.0"
    targetVersion: "3.1.0"
    architecture: ["arm64", "x86_64"]

  # Permissions required
  permissions:
    - AUDIO_PLAYBACK
    - INTERNET
    - BLUETOOTH
    - VEHICLE_SPEED  # For audio ducking when speed > 100mph
    - STEERING_CONTROLS
    - LOCATION  # For personalized recommendations

  # Resource limits
  resources:
    memory: 512Mi
    cpu: 500m
    storage: 2Gi
    bandwidth: 10Mbps

  # Container configuration
  container:
    image: registry.spotify.com/automotive/spotify:2.1.4
    entrypoint: ["/usr/bin/spotify-app"]
    environment:
      - name: API_KEY
        valueFrom:
          secretRef:
            name: spotify-api-credentials
            key: api-key

  # Service exposure
  services:
    - name: media-player
      protocol: dbus
      interface: org.mpris.MediaPlayer2
      path: /org/mpris/MediaPlayer2/spotify

  # UI configuration
  ui:
    icon: https://cdn.spotify.com/automotive/icon-512.png
    screenshots:
      - https://cdn.spotify.com/automotive/screenshot1.png
      - https://cdn.spotify.com/automotive/screenshot2.png
    launchMode: fullscreen
    displayInLauncher: true

  # Integration points
  integrations:
    voiceAssistant:
      enabled: true
      wakeWords: ["play music", "open spotify"]
    steeringControls:
      enabled: true
      actions: [play, pause, next, previous, volume]
    clusterDisplay:
      enabled: true
      showNowPlaying: true

  # Safety constraints
  safety:
    disableWhileDriving: false
    touchInteractionLimit: true  # Limit UI interaction while moving
    voiceControlRequired: false

  # Analytics and telemetry
  telemetry:
    enabled: true
    endpoint: https://telemetry.spotify.com/automotive
    dataTypes:
      - usage_statistics
      - crash_reports
      - performance_metrics

  # Update strategy
  updatePolicy:
    automatic: true
    canRollback: true
    maxDowntime: 30s
```

### 3. App Sandbox Runtime (Golang)

```go
// Vehicle app sandbox runtime using containerd
// File: app-runtime.go

package main

import (
    "context"
    "fmt"
    "log"
    "os"
    "path/filepath"
    "syscall"

    "github.com/containerd/containerd"
    "github.com/containerd/containerd/cio"
    "github.com/containerd/containerd/namespaces"
    "github.com/containerd/containerd/oci"
    "gopkg.in/yaml.v3"
)

// AppManifest represents vehicle app configuration
type AppManifest struct {
    APIVersion string `yaml:"apiVersion"`
    Kind       string `yaml:"kind"`
    Metadata   struct {
        Name        string `yaml:"name"`
        Version     string `yaml:"version"`
        DisplayName string `yaml:"displayName"`
    } `yaml:"metadata"`
    Spec struct {
        Permissions []string `yaml:"permissions"`
        Resources   struct {
            Memory    string `yaml:"memory"`
            CPU       string `yaml:"cpu"`
            Storage   string `yaml:"storage"`
            Bandwidth string `yaml:"bandwidth"`
        } `yaml:"resources"`
        Container struct {
            Image       string   `yaml:"image"`
            Entrypoint  []string `yaml:"entrypoint"`
            Environment []struct {
                Name  string `yaml:"name"`
                Value string `yaml:"value,omitempty"`
            } `yaml:"environment"`
        } `yaml:"container"`
        Safety struct {
            DisableWhileDriving    bool `yaml:"disableWhileDriving"`
            TouchInteractionLimit  bool `yaml:"touchInteractionLimit"`
        } `yaml:"safety"`
    } `yaml:"spec"`
}

// AppRuntime manages vehicle app lifecycle
type AppRuntime struct {
    client    *containerd.Client
    namespace string
}

// NewAppRuntime creates a new app runtime
func NewAppRuntime() (*AppRuntime, error) {
    client, err := containerd.New("/run/containerd/containerd.sock")
    if err != nil {
        return nil, fmt.Errorf("failed to connect to containerd: %w", err)
    }

    return &AppRuntime{
        client:    client,
        namespace: "vehicle-apps",
    }, nil
}

// InstallApp installs an app from manifest
func (r *AppRuntime) InstallApp(manifestPath string) error {
    // Load manifest
    manifest, err := r.loadManifest(manifestPath)
    if err != nil {
        return fmt.Errorf("failed to load manifest: %w", err)
    }

    log.Printf("Installing app: %s v%s", manifest.Metadata.Name, manifest.Metadata.Version)

    ctx := namespaces.WithNamespace(context.Background(), r.namespace)

    // Pull container image
    image, err := r.client.Pull(ctx, manifest.Spec.Container.Image,
        containerd.WithPullUnpack)
    if err != nil {
        return fmt.Errorf("failed to pull image: %w", err)
    }

    log.Printf("Pulled image: %s", image.Name())

    // Create container with security constraints
    container, err := r.createSecureContainer(ctx, manifest, image)
    if err != nil {
        return fmt.Errorf("failed to create container: %w", err)
    }

    log.Printf("App installed successfully: %s", container.ID())
    return nil
}

// createSecureContainer creates a sandboxed container with security policies
func (r *AppRuntime) createSecureContainer(
    ctx context.Context,
    manifest *AppManifest,
    image containerd.Image,
) (containerd.Container, error) {

    appName := manifest.Metadata.Name

    // Define security policies based on permissions
    opts := []oci.SpecOpts{
        oci.WithImageConfig(image),
        oci.WithEnv(r.buildEnvironment(manifest)),

        // Resource limits
        oci.WithMemoryLimit(r.parseMemory(manifest.Spec.Resources.Memory)),
        oci.WithCPUQuota(500000, 100000), // 500m CPU

        // Security constraints
        oci.WithNoNewPrivileges,
        oci.WithPrivileged(false),

        // Read-only root filesystem
        oci.WithRootFSReadonly(),

        // Drop all capabilities by default
        oci.WithCapabilities([]string{}),

        // Add capabilities based on permissions
        oci.WithAddedCapabilities(r.getCapabilities(manifest.Spec.Permissions)),

        // Mount tmpfs for writable directories
        oci.WithMounts([]oci.Mount{
            {
                Type:        "tmpfs",
                Source:      "tmpfs",
                Destination: "/tmp",
                Options:     []string{"nosuid", "noexec", "nodev"},
            },
            {
                Type:        "bind",
                Source:      filepath.Join("/var/lib/vehicle-apps", appName, "data"),
                Destination: "/data",
                Options:     []string{"rbind", "rw"},
            },
        }),

        // Namespace isolation
        oci.WithLinuxNamespace(oci.LinuxNamespace{
            Type: "pid",
        }),
        oci.WithLinuxNamespace(oci.LinuxNamespace{
            Type: "network",
        }),
        oci.WithLinuxNamespace(oci.LinuxNamespace{
            Type: "ipc",
        }),
    }

    // Permission-specific constraints
    if !r.hasPermission(manifest.Spec.Permissions, "INTERNET") {
        // Block network access
        opts = append(opts, oci.WithHostNamespace(oci.NetworkNamespace))
    }

    // Create container
    container, err := r.client.NewContainer(
        ctx,
        appName,
        containerd.WithImage(image),
        containerd.WithNewSnapshot(appName+"-snapshot", image),
        containerd.WithNewSpec(opts...),
    )

    return container, err
}

// StartApp starts an installed app
func (r *AppRuntime) StartApp(appName string, manifest *AppManifest) error {
    ctx := namespaces.WithNamespace(context.Background(), r.namespace)

    container, err := r.client.LoadContainer(ctx, appName)
    if err != nil {
        return fmt.Errorf("failed to load container: %w", err)
    }

    // Check safety constraints
    if manifest.Spec.Safety.DisableWhileDriving {
        if r.isVehicleMoving() {
            return fmt.Errorf("app disabled while driving")
        }
    }

    // Create task
    task, err := container.NewTask(ctx, cio.NewCreator(cio.WithStdio))
    if err != nil {
        return fmt.Errorf("failed to create task: %w", err)
    }

    // Start task
    if err := task.Start(ctx); err != nil {
        return fmt.Errorf("failed to start task: %w", err)
    }

    log.Printf("App started: %s (PID: %d)", appName, task.Pid())
    return nil
}

// StopApp stops a running app
func (r *AppRuntime) StopApp(appName string) error {
    ctx := namespaces.WithNamespace(context.Background(), r.namespace)

    container, err := r.client.LoadContainer(ctx, appName)
    if err != nil {
        return fmt.Errorf("failed to load container: %w", err)
    }

    task, err := container.Task(ctx, nil)
    if err != nil {
        return fmt.Errorf("failed to get task: %w", err)
    }

    // Graceful shutdown
    if err := task.Kill(ctx, syscall.SIGTERM); err != nil {
        return fmt.Errorf("failed to send SIGTERM: %w", err)
    }

    // Wait for exit (with timeout)
    status, err := task.Wait(ctx)
    if err != nil {
        return fmt.Errorf("failed to wait for exit: %w", err)
    }

    <-status

    log.Printf("App stopped: %s", appName)
    return nil
}

// UninstallApp removes an installed app
func (r *AppRuntime) UninstallApp(appName string) error {
    ctx := namespaces.WithNamespace(context.Background(), r.namespace)

    // Stop if running
    _ = r.StopApp(appName)

    // Delete container
    container, err := r.client.LoadContainer(ctx, appName)
    if err != nil {
        return fmt.Errorf("failed to load container: %w", err)
    }

    if err := container.Delete(ctx, containerd.WithSnapshotCleanup); err != nil {
        return fmt.Errorf("failed to delete container: %w", err)
    }

    log.Printf("App uninstalled: %s", appName)
    return nil
}

// Helper functions

func (r *AppRuntime) loadManifest(path string) (*AppManifest, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, err
    }

    var manifest AppManifest
    if err := yaml.Unmarshal(data, &manifest); err != nil {
        return nil, err
    }

    return &manifest, nil
}

func (r *AppRuntime) buildEnvironment(manifest *AppManifest) []string {
    env := []string{}
    for _, e := range manifest.Spec.Container.Environment {
        env = append(env, fmt.Sprintf("%s=%s", e.Name, e.Value))
    }
    return env
}

func (r *AppRuntime) parseMemory(mem string) uint64 {
    // Simple parser for Mi/Gi units
    // In production, use proper parsing
    return 512 * 1024 * 1024 // 512Mi
}

func (r *AppRuntime) getCapabilities(permissions []string) []string {
    caps := []string{}

    for _, perm := range permissions {
        switch perm {
        case "INTERNET":
            caps = append(caps, "CAP_NET_BIND_SERVICE")
        case "BLUETOOTH":
            caps = append(caps, "CAP_NET_ADMIN")
        case "AUDIO_PLAYBACK":
            // Allow access to audio devices
        }
    }

    return caps
}

func (r *AppRuntime) hasPermission(permissions []string, perm string) bool {
    for _, p := range permissions {
        if p == perm {
            return true
        }
    }
    return false
}

func (r *AppRuntime) isVehicleMoving() bool {
    // Check vehicle speed from CAN bus
    // Placeholder implementation
    return false
}

func main() {
    runtime, err := NewAppRuntime()
    if err != nil {
        log.Fatalf("Failed to create runtime: %v", err)
    }

    // Example: Install and start app
    if err := runtime.InstallApp("spotify-manifest.yaml"); err != nil {
        log.Fatalf("Failed to install app: %v", err)
    }

    // Load manifest for safety checks
    manifest, _ := runtime.loadManifest("spotify-manifest.yaml")

    if err := runtime.StartApp("spotify-automotive", manifest); err != nil {
        log.Fatalf("Failed to start app: %v", err)
    }

    log.Println("App runtime running...")
    select {} // Keep running
}
```

### 4. Developer SDK Example (TypeScript)

```typescript
// Vehicle App Developer SDK
// File: vehicle-app-sdk.ts

/**
 * Vehicle App SDK for TypeScript/JavaScript apps
 * Provides APIs for vehicle integration
 */

export enum Permission {
  AUDIO_PLAYBACK = 'AUDIO_PLAYBACK',
  INTERNET = 'INTERNET',
  BLUETOOTH = 'BLUETOOTH',
  VEHICLE_SPEED = 'VEHICLE_SPEED',
  LOCATION = 'LOCATION',
  STEERING_CONTROLS = 'STEERING_CONTROLS',
  CLIMATE_CONTROL = 'CLIMATE_CONTROL',
}

export interface VehicleState {
  speed: number; // km/h
  gear: string;
  isMoving: boolean;
  batteryLevel: number; // percentage
  range: number; // km
}

export class VehicleAppSDK {
  private readonly appId: string;
  private readonly permissions: Permission[];
  private ws: WebSocket | null = null;

  constructor(appId: string, permissions: Permission[]) {
    this.appId = appId;
    this.permissions = permissions;
  }

  /**
   * Initialize SDK connection to vehicle platform
   */
  async initialize(): Promise<void> {
    console.log(`Initializing SDK for app: ${this.appId}`);

    // Connect to vehicle platform via WebSocket
    this.ws = new WebSocket('ws://vehicle-platform:8080/apps/ws');

    return new Promise((resolve, reject) => {
      this.ws!.onopen = () => {
        console.log('Connected to vehicle platform');

        // Send authentication
        this.ws!.send(JSON.stringify({
          type: 'auth',
          appId: this.appId,
          permissions: this.permissions,
        }));

        resolve();
      };

      this.ws!.onerror = (error) => {
        reject(new Error(`WebSocket error: ${error}`));
      };
    });
  }

  /**
   * Get current vehicle state
   */
  async getVehicleState(): Promise<VehicleState> {
    this.checkPermission(Permission.VEHICLE_SPEED);

    return new Promise((resolve, reject) => {
      const requestId = Date.now().toString();

      this.ws!.send(JSON.stringify({
        type: 'request',
        requestId,
        method: 'getVehicleState',
      }));

      const handler = (event: MessageEvent) => {
        const data = JSON.parse(event.data);
        if (data.requestId === requestId) {
          this.ws!.removeEventListener('message', handler);
          resolve(data.result);
        }
      };

      this.ws!.addEventListener('message', handler);

      // Timeout after 5 seconds
      setTimeout(() => {
        this.ws!.removeEventListener('message', handler);
        reject(new Error('Request timeout'));
      }, 5000);
    });
  }

  /**
   * Subscribe to vehicle state changes
   */
  onVehicleStateChange(callback: (state: VehicleState) => void): void {
    this.checkPermission(Permission.VEHICLE_SPEED);

    this.ws!.addEventListener('message', (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'vehicleStateUpdate') {
        callback(data.state);
      }
    });

    // Subscribe
    this.ws!.send(JSON.stringify({
      type: 'subscribe',
      topic: 'vehicleState',
    }));
  }

  /**
   * Control audio playback
   */
  async playAudio(url: string): Promise<void> {
    this.checkPermission(Permission.AUDIO_PLAYBACK);

    await this.sendRequest('playAudio', { url });
  }

  /**
   * Subscribe to steering control events
   */
  onSteeringControl(callback: (action: string) => void): void {
    this.checkPermission(Permission.STEERING_CONTROLS);

    this.ws!.addEventListener('message', (event) => {
      const data = JSON.parse(event.data);
      if (data.type === 'steeringControl') {
        callback(data.action); // 'next', 'previous', 'play', 'pause'
      }
    });

    this.ws!.send(JSON.stringify({
      type: 'subscribe',
      topic: 'steeringControls',
    }));
  }

  /**
   * Display notification in vehicle cluster
   */
  async showNotification(title: string, message: string): Promise<void> {
    await this.sendRequest('showNotification', { title, message });
  }

  /**
   * Get current location
   */
  async getLocation(): Promise<{ latitude: number; longitude: number }> {
    this.checkPermission(Permission.LOCATION);

    const result = await this.sendRequest('getLocation', {});
    return result as { latitude: number; longitude: number };
  }

  private checkPermission(permission: Permission): void {
    if (!this.permissions.includes(permission)) {
      throw new Error(`Permission not granted: ${permission}`);
    }
  }

  private async sendRequest(method: string, params: any): Promise<any> {
    return new Promise((resolve, reject) => {
      const requestId = Date.now().toString();

      this.ws!.send(JSON.stringify({
        type: 'request',
        requestId,
        method,
        params,
      }));

      const handler = (event: MessageEvent) => {
        const data = JSON.parse(event.data);
        if (data.requestId === requestId) {
          this.ws!.removeEventListener('message', handler);

          if (data.error) {
            reject(new Error(data.error));
          } else {
            resolve(data.result);
          }
        }
      };

      this.ws!.addEventListener('message', handler);

      setTimeout(() => {
        this.ws!.removeEventListener('message', handler);
        reject(new Error('Request timeout'));
      }, 5000);
    });
  }
}

// Example app using SDK
async function exampleApp() {
  const sdk = new VehicleAppSDK('spotify-automotive', [
    Permission.AUDIO_PLAYBACK,
    Permission.STEERING_CONTROLS,
    Permission.VEHICLE_SPEED,
  ]);

  await sdk.initialize();

  // Get vehicle state
  const state = await sdk.getVehicleState();
  console.log(`Vehicle speed: ${state.speed} km/h`);

  // Subscribe to steering controls
  sdk.onSteeringControl((action) => {
    console.log(`Steering control: ${action}`);
    if (action === 'play') {
      sdk.playAudio('https://cdn.spotify.com/track/123.mp3');
    }
  });

  // Monitor vehicle state
  sdk.onVehicleStateChange((state) => {
    if (state.speed > 100) {
      // Duck audio volume at high speeds
      console.log('High speed detected, reducing volume');
    }
  });
}
```

## Real-World Examples

### Tesla App Store Strategy
- **Built-in apps**: Native Tesla apps (Netflix, YouTube, Spotify)
- **No third-party yet**: Closed ecosystem for quality control
- **Game integration**: Steam integration announced for Model S/X
- **API access**: Limited fleet API for developers

### GM Ultifi Platform
- **Open developer program**: Third-party app marketplace
- **Revenue sharing**: 70/30 split (developer/GM)
- **SDK availability**: Public SDK with APIs for vehicle data
- **Categories**: Navigation, media, productivity, games

### VW.OS App Store
- **Phased rollout**: Starting with MEB platform (ID. series)
- **Partner apps**: Curated partners initially
- **In-car payment**: Integrated billing system
- **Cross-brand**: Shared across VW Group brands

### Rivian App Shop
- **Adventure focus**: Apps for off-road, camping, outdoor
- **Fleet integration**: Apps for commercial R1T owners
- **OTA updates**: Apps update independently of vehicle software

## Best Practices

1. **Strict permission model**: Request only necessary permissions
2. **Sandboxed execution**: Isolate apps from vehicle systems
3. **Resource limits**: Enforce memory, CPU, bandwidth limits
4. **Safety first**: Disable/limit apps while driving
5. **Certification process**: Manual security review before approval
6. **Privacy protection**: Transparent data collection policies
7. **Offline functionality**: Apps should work without connectivity
8. **Graceful degradation**: Handle missing permissions elegantly
9. **Update mechanism**: Automatic updates for security patches
10. **Rollback support**: Ability to rollback problematic updates

## Security Considerations

- **Code signing**: All apps must be signed by developer
- **Runtime verification**: Verify signatures before execution
- **Capability-based security**: Grant minimal capabilities
- **Network isolation**: Apps cannot access vehicle CAN bus directly
- **Data encryption**: Encrypt app data at rest
- **Audit logging**: Log all permission requests and usage
- **Kill switch**: Remote ability to disable compromised apps

## References

- **Android Automotive**: https://source.android.com/devices/automotive
- **COVESA**: https://covesa.global/
- **GENIVI**: https://www.genivi.org/
- **Eclipse SDV**: https://sdv.eclipse.org/

---

## Vehicle Middleware Platforms

# Vehicle Middleware Platforms — SDV Middleware Stacks

Expert knowledge of SDV middleware stacks (COVESA VSS, Eclipse SDV, AUTOSAR Adaptive), data models (VSS/VISS), pub-sub brokers, and service mesh for vehicles.

## Core Concepts

### Middleware Components

1. **Data Abstraction**: VSS (Vehicle Signal Specification)
2. **Service Communication**: SOME/IP, DDS, MQTT
3. **Service Discovery**: mDNS, service registries
4. **Security**: TLS, authentication, authorization
5. **Orchestration**: Lifecycle management

### Key Standards

- **COVESA VSS**: Standardized vehicle data model
- **COVESA VISS**: Vehicle Information Service Specification (API)
- **Eclipse SDV**: Open-source SDV components
- **AUTOSAR Adaptive**: Service-oriented automotive architecture

## Production-Ready Implementation

### 1. VSS Data Model Implementation

```yaml
# Vehicle Signal Specification (VSS) tree
# File: vehicle-signals.vspec

Vehicle:
  description: Top-level vehicle
  type: branch

Vehicle.Speed:
  datatype: float
  type: sensor
  unit: km/h
  description: Vehicle speed
  min: 0
  max: 300

Vehicle.Powertrain:
  type: branch
  description: Powertrain signals

Vehicle.Powertrain.Battery:
  type: branch
  description: Battery system

Vehicle.Powertrain.Battery.StateOfCharge:
  datatype: float
  type: sensor
  unit: percent
  description: Battery state of charge
  min: 0
  max: 100

Vehicle.Powertrain.Battery.Voltage:
  datatype: float
  type: sensor
  unit: V
  description: Battery voltage
  min: 0
  max: 800

Vehicle.Powertrain.Battery.Current:
  datatype: float
  type: sensor
  unit: A
  description: Battery current (positive = charging)
  min: -400
  max: 400

Vehicle.Powertrain.Battery.Temperature:
  datatype: float
  type: sensor
  unit: celsius
  description: Battery temperature
  min: -40
  max: 80

Vehicle.Cabin:
  type: branch
  description: Cabin signals

Vehicle.Cabin.HVAC:
  type: branch
  description: HVAC system

Vehicle.Cabin.HVAC.IsAirConditioningActive:
  datatype: boolean
  type: actuator
  description: Air conditioning status

Vehicle.Cabin.HVAC.AmbientAirTemperature:
  datatype: float
  type: sensor
  unit: celsius
  description: Ambient temperature

Vehicle.Body:
  type: branch
  description: Body signals

Vehicle.Body.Doors:
  type: branch
  instances:
    - Row1Left
    - Row1Right
    - Row2Left
    - Row2Right

Vehicle.Body.Doors.IsLocked:
  datatype: boolean
  type: actuator
  description: Door lock status

Vehicle.Body.Doors.IsOpen:
  datatype: boolean
  type: sensor
  description: Door open status

Vehicle.ADAS:
  type: branch
  description: ADAS signals

Vehicle.ADAS.CruiseControl:
  type: branch
  description: Cruise control

Vehicle.ADAS.CruiseControl.IsActive:
  datatype: boolean
  type: actuator
  description: Cruise control active

Vehicle.ADAS.CruiseControl.SpeedSet:
  datatype: float
  type: actuator
  unit: km/h
  description: Set cruise control speed
```

### 2. VSS Data Broker (Rust)

```rust
// VSS data broker implementation
// File: vss-broker/src/main.rs

use tokio;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use serde::{Deserialize, Serialize};
use warp::Filter;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct VehicleSignal {
    path: String,
    value: SignalValue,
    timestamp: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
enum SignalValue {
    Float(f64),
    Int(i64),
    Bool(bool),
    String(String),
}

#[derive(Clone)]
struct DataBroker {
    signals: Arc<RwLock<HashMap<String, VehicleSignal>>>,
    subscribers: Arc<RwLock<HashMap<String, Vec<tokio::sync::mpsc::UnboundedSender<VehicleSignal>>>>>,
}

impl DataBroker {
    fn new() -> Self {
        DataBroker {
            signals: Arc::new(RwLock::new(HashMap::new())),
            subscribers: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Get signal value
    fn get(&self, path: &str) -> Option<VehicleSignal> {
        let signals = self.signals.read().unwrap();
        signals.get(path).cloned()
    }

    /// Set signal value
    fn set(&self, signal: VehicleSignal) {
        let path = signal.path.clone();

        // Store signal
        {
            let mut signals = self.signals.write().unwrap();
            signals.insert(path.clone(), signal.clone());
        }

        // Notify subscribers
        self.notify_subscribers(&path, signal);
    }

    /// Subscribe to signal updates
    fn subscribe(&self, path: String) -> tokio::sync::mpsc::UnboundedReceiver<VehicleSignal> {
        let (tx, rx) = tokio::sync::mpsc::unbounded_channel();

        let mut subscribers = self.subscribers.write().unwrap();
        subscribers.entry(path).or_insert_with(Vec::new).push(tx);

        rx
    }

    /// Notify subscribers of signal update
    fn notify_subscribers(&self, path: &str, signal: VehicleSignal) {
        let subscribers = self.subscribers.read().unwrap();

        if let Some(subs) = subscribers.get(path) {
            for tx in subs {
                let _ = tx.send(signal.clone());
            }
        }

        // Also notify wildcard subscribers (path.*)
        let parts: Vec<&str> = path.split('.').collect();
        for i in 0..parts.len() {
            let wildcard_path = format!("{}.*", parts[..i].join("."));
            if let Some(subs) = subscribers.get(&wildcard_path) {
                for tx in subs {
                    let _ = tx.send(signal.clone());
                }
            }
        }
    }

    /// Batch get signals
    fn get_batch(&self, paths: Vec<String>) -> HashMap<String, VehicleSignal> {
        let signals = self.signals.read().unwrap();
        let mut result = HashMap::new();

        for path in paths {
            if let Some(signal) = signals.get(&path) {
                result.insert(path, signal.clone());
            }
        }

        result
    }
}

#[tokio::main]
async fn main() {
    let broker = DataBroker::new();
    let broker = Arc::new(broker);

    // REST API routes
    let broker_filter = warp::any().map(move || broker.clone());

    // GET /api/signals/{path}
    let get_signal = warp::path!("api" / "signals" / String)
        .and(warp::get())
        .and(broker_filter.clone())
        .map(|path: String, broker: Arc<DataBroker>| {
            match broker.get(&path) {
                Some(signal) => warp::reply::json(&signal),
                None => warp::reply::json(&serde_json::json!({
                    "error": "Signal not found"
                })),
            }
        });

    // POST /api/signals
    let set_signal = warp::path!("api" / "signals")
        .and(warp::post())
        .and(warp::body::json())
        .and(broker_filter.clone())
        .map(|signal: VehicleSignal, broker: Arc<DataBroker>| {
            broker.set(signal.clone());
            warp::reply::json(&serde_json::json!({
                "status": "ok",
                "path": signal.path
            }))
        });

    // WebSocket /api/subscribe
    let subscribe = warp::path!("api" / "subscribe")
        .and(warp::ws())
        .and(broker_filter.clone())
        .map(|ws: warp::ws::Ws, broker: Arc<DataBroker>| {
            ws.on_upgrade(move |socket| handle_websocket(socket, broker))
        });

    let routes = get_signal
        .or(set_signal)
        .or(subscribe);

    println!("[VSS Broker] Starting on 0.0.0.0:8080");
    warp::serve(routes)
        .run(([0, 0, 0, 0], 8080))
        .await;
}

async fn handle_websocket(
    websocket: warp::ws::WebSocket,
    broker: Arc<DataBroker>
) {
    use futures::{StreamExt, SinkExt};

    let (mut tx, mut rx) = websocket.split();

    // Handle incoming subscription requests
    while let Some(result) = rx.next().await {
        let msg = match result {
            Ok(msg) => msg,
            Err(e) => {
                eprintln!("WebSocket error: {}", e);
                break;
            }
        };

        if let Ok(text) = msg.to_str() {
            // Parse subscription request
            if let Ok(req) = serde_json::from_str::<serde_json::Value>(text) {
                if let Some(path) = req["path"].as_str() {
                    let path = path.to_string();
                    let mut signal_rx = broker.subscribe(path.clone());

                    // Send updates
                    tokio::spawn(async move {
                        while let Some(signal) = signal_rx.recv().await {
                            let json = serde_json::to_string(&signal).unwrap();
                            if tx.send(warp::ws::Message::text(json)).await.is_err() {
                                break;
                            }
                        }
                    });
                }
            }
        }
    }
}
```

### 3. VISS Server (Python/FastAPI)

```python
#!/usr/bin/env python3
"""
VISS (Vehicle Information Service Specification) server.
RESTful and WebSocket API for VSS data access.
"""

from fastapi import FastAPI, WebSocket, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import asyncio
import json
from datetime import datetime


app = FastAPI(title="VISS Server", version="2.0.0")


class VehicleSignal(BaseModel):
    """Vehicle signal data model."""
    path: str
    value: Any
    timestamp: Optional[int] = None


class GetRequest(BaseModel):
    """VISS GET request."""
    action: str = "get"
    path: str
    requestId: str


class SetRequest(BaseModel):
    """VISS SET request."""
    action: str = "set"
    path: str
    value: Any
    requestId: str


class SubscribeRequest(BaseModel):
    """VISS SUBSCRIBE request."""
    action: str = "subscribe"
    path: str
    subscriptionId: str


# In-memory signal storage (replace with Redis in production)
signals_db: Dict[str, VehicleSignal] = {}

# WebSocket subscriptions
subscriptions: Dict[str, List[WebSocket]] = {}


@app.get("/vss/api/v2/{path:path}")
async def get_signal_rest(path: str):
    """
    Get signal value via REST API.

    Example: GET /vss/api/v2/Vehicle/Speed
    """
    if path not in signals_db:
        raise HTTPException(status_code=404, detail="Signal not found")

    signal = signals_db[path]

    return JSONResponse({
        "action": "get",
        "path": path,
        "value": signal.value,
        "timestamp": signal.timestamp or int(datetime.utcnow().timestamp() * 1000),
        "requestId": "rest-" + str(int(datetime.utcnow().timestamp()))
    })


@app.put("/vss/api/v2/{path:path}")
async def set_signal_rest(path: str, value: Any):
    """
    Set signal value via REST API.

    Example: PUT /vss/api/v2/Vehicle/Cabin/HVAC/IsAirConditioningActive
    Body: {"value": true}
    """
    signal = VehicleSignal(
        path=path,
        value=value,
        timestamp=int(datetime.utcnow().timestamp() * 1000)
    )

    signals_db[path] = signal

    # Notify subscribers
    await notify_subscribers(path, signal)

    return JSONResponse({
        "action": "set",
        "path": path,
        "timestamp": signal.timestamp,
        "requestId": "rest-" + str(int(datetime.utcnow().timestamp()))
    })


@app.websocket("/vss/api/v2")
async def websocket_endpoint(websocket: WebSocket):
    """
    VISS WebSocket endpoint for real-time communication.

    Supports:
    - GET: Get signal value
    - SET: Set signal value
    - SUBSCRIBE: Subscribe to signal updates
    - UNSUBSCRIBE: Unsubscribe from signal
    """
    await websocket.accept()

    try:
        while True:
            # Receive request
            data = await websocket.receive_text()
            request = json.loads(data)

            action = request.get("action")

            if action == "get":
                await handle_get(websocket, request)
            elif action == "set":
                await handle_set(websocket, request)
            elif action == "subscribe":
                await handle_subscribe(websocket, request)
            elif action == "unsubscribe":
                await handle_unsubscribe(websocket, request)
            else:
                await websocket.send_json({
                    "error": {"number": 400, "message": "Invalid action"},
                    "requestId": request.get("requestId", "unknown")
                })

    except Exception as e:
        print(f"[VISS] WebSocket error: {e}")
    finally:
        # Clean up subscriptions
        for path, subs in subscriptions.items():
            if websocket in subs:
                subs.remove(websocket)


async def handle_get(websocket: WebSocket, request: dict):
    """Handle GET request."""
    path = request["path"]

    if path not in signals_db:
        await websocket.send_json({
            "action": "get",
            "error": {"number": 404, "message": "Signal not found"},
            "requestId": request["requestId"]
        })
        return

    signal = signals_db[path]

    await websocket.send_json({
        "action": "get",
        "path": path,
        "value": signal.value,
        "timestamp": signal.timestamp,
        "requestId": request["requestId"]
    })


async def handle_set(websocket: WebSocket, request: dict):
    """Handle SET request."""
    path = request["path"]
    value = request["value"]

    signal = VehicleSignal(
        path=path,
        value=value,
        timestamp=int(datetime.utcnow().timestamp() * 1000)
    )

    signals_db[path] = signal

    # Notify subscribers
    await notify_subscribers(path, signal)

    await websocket.send_json({
        "action": "set",
        "path": path,
        "timestamp": signal.timestamp,
        "requestId": request["requestId"]
    })


async def handle_subscribe(websocket: WebSocket, request: dict):
    """Handle SUBSCRIBE request."""
    path = request["path"]
    subscription_id = request["subscriptionId"]

    # Add to subscriptions
    if path not in subscriptions:
        subscriptions[path] = []

    subscriptions[path].append(websocket)

    # Send confirmation
    await websocket.send_json({
        "action": "subscribe",
        "subscriptionId": subscription_id,
        "timestamp": int(datetime.utcnow().timestamp() * 1000)
    })


async def handle_unsubscribe(websocket: WebSocket, request: dict):
    """Handle UNSUBSCRIBE request."""
    subscription_id = request["subscriptionId"]

    # Remove from subscriptions
    for path, subs in subscriptions.items():
        if websocket in subs:
            subs.remove(websocket)

    await websocket.send_json({
        "action": "unsubscribe",
        "subscriptionId": subscription_id,
        "timestamp": int(datetime.utcnow().timestamp() * 1000)
    })


async def notify_subscribers(path: str, signal: VehicleSignal):
    """Notify all subscribers of signal update."""
    if path in subscriptions:
        notification = {
            "action": "subscription",
            "path": path,
            "value": signal.value,
            "timestamp": signal.timestamp
        }

        # Send to all subscribers
        dead_sockets = []
        for websocket in subscriptions[path]:
            try:
                await websocket.send_json(notification)
            except Exception:
                dead_sockets.append(websocket)

        # Remove dead sockets
        for ws in dead_sockets:
            subscriptions[path].remove(ws)


# Populate some initial data
@app.on_event("startup")
async def populate_initial_data():
    """Populate initial vehicle signals."""
    initial_signals = [
        VehicleSignal(path="Vehicle.Speed", value=0.0),
        VehicleSignal(path="Vehicle.Powertrain.Battery.StateOfCharge", value=80.0),
        VehicleSignal(path="Vehicle.Powertrain.Battery.Voltage", value=400.0),
        VehicleSignal(path="Vehicle.Powertrain.Battery.Current", value=0.0),
        VehicleSignal(path="Vehicle.Cabin.HVAC.IsAirConditioningActive", value=False),
        VehicleSignal(path="Vehicle.Body.Doors.Row1Left.IsLocked", value=True),
        VehicleSignal(path="Vehicle.ADAS.CruiseControl.IsActive", value=False),
    ]

    for signal in initial_signals:
        signal.timestamp = int(datetime.utcnow().timestamp() * 1000)
        signals_db[signal.path] = signal

    print("[VISS] Initial signals populated")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
```

### 4. Service Mesh Configuration (Istio-like for Automotive)

```yaml
# Service mesh configuration for vehicle platform
# File: vehicle-service-mesh.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: service-mesh-config
  namespace: vehicle-platform
data:
  mesh-config.yaml: |
    # Global mesh configuration
    defaultConfig:
      discoveryAddress: mesh-pilot.vehicle-platform.svc:15010
      tracing:
        zipkin:
          address: zipkin.vehicle-platform.svc:9411
      proxyMetadata:
        ISTIO_META_DNS_CAPTURE: "true"
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"

    # Access logging
    accessLogFile: /dev/stdout
    accessLogEncoding: JSON

    # mTLS configuration
    enableAutoMtls: true

    # Trust domain
    trustDomain: vehicle.local

    # Service discovery
    defaultServiceExportTo:
      - "*"

---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: vss-broker
spec:
  hosts:
    - vss-broker.vehicle-platform.svc
  http:
    - match:
        - uri:
            prefix: /api/signals
      route:
        - destination:
            host: vss-broker.vehicle-platform.svc
            port:
              number: 8080
      timeout: 5s
      retries:
        attempts: 3
        perTryTimeout: 2s

---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: vss-broker
spec:
  host: vss-broker.vehicle-platform.svc
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 60s
      maxEjectionPercent: 50

---
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: vehicle-platform
spec:
  mtls:
    mode: STRICT

---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: vss-access-control
  namespace: vehicle-platform
spec:
  selector:
    matchLabels:
      app: vss-broker
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/infotainment/sa/spotify"]
      to:
        - operation:
            methods: ["GET"]
            paths: ["/api/signals/Vehicle/Speed"]
```

### 5. Eclipse Kuksa Integration

```python
#!/usr/bin/env python3
"""
Eclipse Kuksa.VAL integration for VSS data access.
"""

import asyncio
from kuksa_client.grpc import VSSClient
from kuksa_client.grpc.aio import VSSClientAsync


async def main():
    """Example Kuksa.VAL client."""

    # Connect to Kuksa databroker
    async with VSSClientAsync('127.0.0.1', 55555) as client:
        print("[Kuksa] Connected to data broker")

        # Set signal value
        await client.set_current_values({
            'Vehicle.Speed': 65.5,
            'Vehicle.Powertrain.Battery.StateOfCharge': 75.0
        })

        print("[Kuksa] Signals set")

        # Get signal value
        response = await client.get_current_values([
            'Vehicle.Speed',
            'Vehicle.Powertrain.Battery.StateOfCharge'
        ])

        for entry in response.entries:
            print(f"[Kuksa] {entry.path} = {entry.value.double}")

        # Subscribe to signal
        async for updates in client.subscribe_current_values([
            'Vehicle.Speed'
        ]):
            for update in updates.updates:
                print(f"[Kuksa] Update: {update.entry.path} = {update.entry.value.double}")


if __name__ == "__main__":
    asyncio.run(main())
```

## Real-World Examples

### COVESA (Connected Vehicle Systems Alliance)
- **VSS Standard**: De facto vehicle data model
- **VISS API**: RESTful and WebSocket access to VSS
- **Industry adoption**: BMW, Ford, Tesla, VW all exploring VSS

### Eclipse SDV Working Group
- **Kuksa.VAL**: Reference VSS data broker
- **Eclipse Leda**: SDV platform distribution
- **Eclipse Ankaios**: Workload orchestrator
- **Eclipse Zenoh**: Unified communication middleware

### AUTOSAR Adaptive
- **Service-oriented**: Pub/sub and RPC services
- **SOME/IP**: Scalable service-oriented middleware
- **Ara::Com**: Communication management API
- **Service discovery**: Dynamic service registration

### Apex.AI
- **ROS 2 for automotive**: Safe, real-time ROS 2
- **DDS middleware**: OMG Data Distribution Service
- **Apex.OS**: Automotive-grade Linux + ROS 2

## Best Practices

1. **Use VSS**: Standardize on VSS data model
2. **Service mesh**: Use service mesh for inter-service communication
3. **mTLS everywhere**: Mutual TLS for all service communication
4. **API gateway**: Centralized API management
5. **Rate limiting**: Protect services from overload
6. **Circuit breakers**: Handle service failures gracefully
7. **Observability**: Distributed tracing (Zipkin, Jaeger)
8. **Service discovery**: Dynamic service registration
9. **Version management**: API versioning strategy
10. **Documentation**: OpenAPI specs for all services

## Security Considerations

- **mTLS**: Mutual authentication between services
- **RBAC**: Role-based access control for VSS signals
- **API keys**: Authenticate app access to services
- **Rate limiting**: Prevent abuse
- **Audit logging**: Log all signal access
- **Encryption**: Encrypt sensitive signals at rest
- **Network policies**: Restrict service-to-service communication

## References

- **COVESA VSS**: https://covesa.global/
- **Eclipse Kuksa**: https://www.eclipse.org/kuksa/
- **Eclipse SDV**: https://sdv.eclipse.org/
- **AUTOSAR Adaptive**: https://www.autosar.org/standards/adaptive-platform/
- **SOME/IP**: https://some-ip.com/
- **Zenoh**: https://zenoh.io/

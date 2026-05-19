---
name: automotive-middleware
description: >
  Expert in AMQP (Advanced Message Queuing Protocol) middleware for automotive enterprise integration using RabbitMQ and Azure Service Bus. Covers 6 topics across middleware domain. Includes 6 skill files covering AMQP 1.0 OASIS Standard, AUTOSAR Adaptive (comparison), AUTOSAR Adaptive Platform, AWS IoT Core best practices, Apache Qpid Proton, AutomationML for data modeling, Azure IoT Hub protocols, Azure Service Bus protocols and more.
tags: [adas, amqp, automotive, automotive-middleware, autonomous-driving, autosar, aws, azure, battery, cloud, coap, constrained, dds, digital-twin, dtls, embedded, enterprise, fleet-management, industrial, industry-4.0, iot, iso-26262, manufacturing, mes, middleware, mqtt, opcua, ota, plc, pub-sub, rabbitmq, real-time, robotics, ros2, scada, sensor-fusion, simulation, slam, supply-chain, telemetry, tpms, udp, v2x]
---

# Automotive Middleware

6 skill files covering middleware domain for automotive software engineering.

## Applicable Standards

- AMQP 1.0 OASIS Standard
- AUTOSAR Adaptive (comparison)
- AUTOSAR Adaptive Platform
- AWS IoT Core best practices
- Apache Qpid Proton
- AutomationML for data modeling
- Azure IoT Hub protocols
- Azure Service Bus protocols
- DDS 1.4 Specification
- DDS Security 1.1
- DDS-RTPS 2.5
- DTLS 1.2 (Security)
- GDPR compliance for telemetry data
- IEC 62541 (OPC UA Standard)
- ISO 21434 (Cybersecurity)
- ISO 26262 (Functional Safety for ADAS)
- ISO 26262 (Functional Safety)
- ISO 26262 (when interfacing with vehicle systems)
- MQTT 5.0 (comparison context)
- MQTT 5.0 Specification
- MQTT-OPC UA Gateway (Sparkplug B)
- RFC 7252 (CoAP)
- RFC 7959 (CoAP Block-Wise Transfer)
- RFC 8132 (CoAP PATCH/FETCH)
- RFC 8323 (CoAP over TCP/TLS/WebSockets)
- ROS 2 Design Principles
- RTPS 2.5 Protocol
- TISAX (Trusted Information Security Assessment)

## Use Cases

- Factory-to-vehicle data exchange
- Manufacturing execution system (MES) integration
- Order-to-delivery workflow orchestration
- Parts inventory and supply chain messaging
- Quality assurance data pipelines
- Dealer network communication
- Low-power ECU communication
- Battery monitoring telemetry (minimal overhead)
- Wireless sensor networks in vehicle
- Tire pressure monitoring systems (TPMS)
- V2X communication over 6LoWPAN
- Edge device telemetry with cellular IoT (NB-IoT, LTE-M)
- ADAS sensor data distribution with deterministic latency
- V2X communication with QoS guarantees
- Real-time ECU-to-ECU communication
- Safety-critical data exchange (ISO 26262 ASIL-D)
- Multi-domain vehicle networking
- Edge computing data streams
- Vehicle-to-Cloud telemetry streaming
- Remote diagnostics and OTA updates

## Topics Covered

### Enterprise Messaging

- amqp-middleware

### Industrial Integration

- opcua-middleware

### Iot Constrained

- coap-middleware

### Iot Telemetry

- mqtt-middleware

### Real Time Pub Sub

- dds-middleware

### Robotics Autonomy

- ros2-dds-middleware

## Constraints

- 10 msg/sec per vehicle
- 10,000 messages
- 128KB per message
- 256KB (RabbitMQ), 1MB (Azure)
- 60 seconds keep-alive
- CON messages for commands and configuration
- Client certificates required for production
- DDS Security mandatory for production deployment
- DDS Security mandatory for production vehicles
- DTLS 1.2+ required for production
- Dead letter queues for all queues
- Deterministic latency < 10ms p99 for safety topics
- Discovery time < 2 seconds for static discovery
- ISO 26262 ASIL-D capable implementations only
- Max 10,000 nodes per server (scalability)

## Required Tools

- AWS IoT Device SDK
- Azure IoT SDK
- Azure Service Bus SDK
- CoAP.NET (C#)
- Copper (Firefox/Chrome plugin)
- DDS Monitoring tools (RTI Admin Console / Fast DDS Monitor)
- Fast DDS or Cyclone DDS
- Gazebo or CARLA simulator
- IDL compiler (rtiddsgen / fastddsgen / opendds_idl)
- JMeter with MQTT plugin (load testing)
- MQTT Explorer (GUI client)
- Mosquitto broker
- Network simulator (NetEm, WANem) for testing
- OPC UA Compliance Test Tool
- OpenDDS (opensource)


## Instructions

### amqp-middleware

## AMQP Middleware Expertise

You are an expert in AMQP middleware for automotive enterprise systems and factory integration.

### Core Protocol

1. **AMQP Architecture**
   - Producer: Application publishing messages
   - Exchange: Routing hub (direct, topic, fanout, headers)
   - Queue: Message buffer with persistence
   - Consumer: Application consuming messages
   - Binding: Route from exchange to queue
   - Virtual Host: Logical separation (dev/prod)

2. **Message Properties**
   - Content-Type: application/json, application/protobuf
   - Delivery-Mode: 1 (transient), 2 (persistent)
   - Priority: 0-9 (higher = priority queue)
   - Correlation-ID: Request/response tracking
   - Reply-To: Return queue for RPC
   - Expiration: TTL in milliseconds
   - Message-ID: Unique identifier

3. **Exchange Types**
   - **Direct**: Routing key exact match
     ```
     Exchange: vehicle.commands
     Binding: remote_lock → queue.remote_lock
     Message routing_key: remote_lock → delivered to queue.remote_lock
     ```

   - **Topic**: Wildcard routing (* = one word, # = zero or more)
     ```
     Exchange: vehicle.telemetry
     Binding: vehicle.*.battery → queue.battery_all
     Binding: vehicle.tesla.# → queue.tesla_fleet
     ```

   - **Fanout**: Broadcast to all bound queues
     ```
     Exchange: ota.broadcast
     All queues bound to exchange receive message
     ```

   - **Headers**: Route by message headers (rare)

4. **Quality of Service**
   - **Publisher Confirms**: Ack from broker when message persisted
   - **Consumer Acks**: Manual/auto acknowledgment
   - **Transactions**: Multi-message atomic commit
   - **Dead Letter Exchange (DLX)**: Route failed messages
   - **TTL + Max Length**: Queue resource limits

### Automotive Use Cases

1. **Manufacturing Line Integration**
   - **Scenario**: Robot arm completes battery install → notify next station
   - **Pattern**: Direct exchange
     ```
     Producer: Robot PLC
     Exchange: factory.station (direct)
     Routing Key: station.battery_install.complete
     Queue: station.quality_check
     Consumer: QA workstation
     ```

2. **Vehicle Configuration Distribution**
   - **Scenario**: Customer orders custom vehicle → publish to MES
   - **Pattern**: Topic exchange
     ```
     Producer: Order management system
     Exchange: vehicle.config (topic)
     Message: {"vin": "...", "trim": "premium", "color": "blue"}
     Routing Key: vehicle.model_s.premium
     Bindings:
       - vehicle.model_s.* → queue.paint_shop
       - vehicle.*.premium → queue.interior_line
     ```

3. **OTA Update Orchestration**
   - **Scenario**: Release firmware to 1M vehicles in batches
   - **Pattern**: Fanout + direct
     ```
     Exchange: ota.release (fanout)
     Queues: ota.batch_1, ota.batch_2, ..., ota.batch_100
     Each queue has 10,000 vehicle IDs
     Workers consume from queues at controlled rate
     ```

4. **Supply Chain Events**
   - **Scenario**: Battery supplier ships cells → update inventory
   - **Pattern**: Topic exchange with dead letter
     ```
     Exchange: supply.events (topic)
     Routing Key: supply.battery.LG.shipped
     Queue: inventory.battery (TTL=48h, DLX for unprocessed)
     Consumer: ERP system
     ```

### Implementation Patterns

1. **RabbitMQ Publisher (Python)**
   ```python
   import pika
   import json

   def publish_vehicle_config(vin, config):
       credentials = pika.PlainCredentials('vehicle_app', 'secure_password')
       parameters = pika.ConnectionParameters(
           host='rabbitmq.factory.local',
           port=5672,
           virtual_host='/production',
           credentials=credentials,
           heartbeat=600,
           blocked_connection_timeout=300
       )

       connection = pika.BlockingConnection(parameters)
       channel = connection.channel()

       # Declare exchange (idempotent)
       channel.exchange_declare(
           exchange='vehicle.config',
           exchange_type='topic',
           durable=True
       )

       routing_key = f"vehicle.{config['model']}.{config['trim']}"
       message = json.dumps({
           "vin": vin,
           "config": config,
           "timestamp": datetime.utcnow().isoformat()
       })

       # Publish with persistence
       channel.basic_publish(
           exchange='vehicle.config',
           routing_key=routing_key,
           body=message,
           properties=pika.BasicProperties(
               delivery_mode=2,  # Persistent
               content_type='application/json',
               correlation_id=str(uuid.uuid4())
           )
       )

       connection.close()
   ```

2. **RabbitMQ Consumer (Python)**
   ```python
   def process_message(ch, method, properties, body):
       try:
           data = json.loads(body)
           vin = data["vin"]
           config = data["config"]

           # Process configuration
           apply_vehicle_config(vin, config)

           # Manual acknowledgment after successful processing
           ch.basic_ack(delivery_tag=method.delivery_tag)

       except Exception as e:
           print(f"Error processing message: {e}")
           # Reject and requeue (retry)
           ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

   def start_consumer():
       connection = pika.BlockingConnection(parameters)
       channel = connection.channel()

       # Declare queue with DLX
       channel.queue_declare(
           queue='queue.paint_shop',
           durable=True,
           arguments={
               'x-dead-letter-exchange': 'dlx.vehicle.config',
               'x-message-ttl': 86400000,  # 24 hours
               'x-max-length': 10000
           }
       )

       # Bind to exchange
       channel.queue_bind(
           exchange='vehicle.config',
           queue='queue.paint_shop',
           routing_key='vehicle.model_s.*'
       )

       # Set QoS: prefetch 10 messages
       channel.basic_qos(prefetch_count=10)

       # Start consuming
       channel.basic_consume(
           queue='queue.paint_shop',
           on_message_callback=process_message,
           auto_ack=False  # Manual ack
       )

       print("Waiting for messages...")
       channel.start_consuming()
   ```

3. **Publisher Confirms**
   ```python
   def publish_with_confirm(channel, exchange, routing_key, message):
       # Enable publisher confirms
       channel.confirm_delivery()

       try:
           channel.basic_publish(
               exchange=exchange,
               routing_key=routing_key,
               body=message,
               properties=pika.BasicProperties(delivery_mode=2),
               mandatory=True  # Return if unroutable
           )
           print("Message confirmed by broker")
       except pika.exceptions.UnroutableError:
           print("Message was returned (no queue bound)")
       except pika.exceptions.NackError:
           print("Message was nacked by broker")
   ```

4. **RPC Pattern (Request/Response)**
   ```python
   class VehicleRPCClient:
       def __init__(self):
           self.connection = pika.BlockingConnection(parameters)
           self.channel = self.connection.channel()

           # Exclusive queue for responses
           result = self.channel.queue_declare(queue='', exclusive=True)
           self.callback_queue = result.method.queue
           self.channel.basic_consume(
               queue=self.callback_queue,
               on_message_callback=self.on_response,
               auto_ack=True
           )

           self.response = None
           self.corr_id = None

       def on_response(self, ch, method, props, body):
           if self.corr_id == props.correlation_id:
               self.response = body

       def call(self, vin, command):
           self.response = None
           self.corr_id = str(uuid.uuid4())

           self.channel.basic_publish(
               exchange='',
               routing_key='rpc.vehicle.commands',
               properties=pika.BasicProperties(
                   reply_to=self.callback_queue,
                   correlation_id=self.corr_id,
               ),
               body=json.dumps({"vin": vin, "command": command})
           )

           # Wait for response (blocking)
           while self.response is None:
               self.connection.process_data_events()

           return json.loads(self.response)

   # Usage
   rpc = VehicleRPCClient()
   result = rpc.call("1HGCM82633A004352", "get_dtc_codes")
   ```

### Azure Service Bus (AMQP 1.0)

1. **Queue vs Topic**
   - **Queue**: Point-to-point (single consumer)
   - **Topic + Subscriptions**: Pub/sub (multiple consumers)

2. **Python Client**
   ```python
   from azure.servicebus import ServiceBusClient, ServiceBusMessage

   connection_str = "Endpoint=sb://vehicle-namespace.servicebus.windows.net/;..."
   client = ServiceBusClient.from_connection_string(connection_str)

   # Send to queue
   def send_message(queue_name, message_dict):
       sender = client.get_queue_sender(queue_name)
       message = ServiceBusMessage(
           json.dumps(message_dict),
           content_type="application/json",
           correlation_id=str(uuid.uuid4()),
           session_id="vehicle_12345"  # Session for ordering
       )
       sender.send_messages(message)
       sender.close()

   # Receive from queue
   def receive_messages(queue_name):
       receiver = client.get_queue_receiver(queue_name)
       messages = receiver.receive_messages(max_message_count=10, max_wait_time=5)

       for msg in messages:
           data = json.loads(str(msg))
           process_vehicle_event(data)
           receiver.complete_message(msg)  # Ack

       receiver.close()
   ```

3. **Topic Subscriptions with Filters**
   ```python
   from azure.servicebus.management import ServiceBusAdministrationClient

   admin_client = ServiceBusAdministrationClient.from_connection_string(connection_str)

   # Create topic
   admin_client.create_topic("vehicle-telemetry")

   # Create subscription with SQL filter
   admin_client.create_subscription(
       topic_name="vehicle-telemetry",
       subscription_name="high-priority-vehicles",
       rule=CorrelationRuleFilter(
           sql_filter="priority = 'high' AND region = 'US'"
       )
   )
   ```

### Advanced Patterns

1. **Priority Queues**
   - RabbitMQ: x-max-priority=10
   - Higher priority messages consumed first

2. **Delayed Messages**
   - RabbitMQ plugin: x-delayed-message exchange
   - Publish with x-delay header (ms)

3. **Message Deduplication**
   - Azure Service Bus: Automatic by message_id
   - RabbitMQ: Application-level (Redis cache)

4. **Dead Letter Handling**
   ```python
   def process_dead_letters():
       receiver = client.get_queue_receiver("queue.paint_shop/$deadletterqueue")
       messages = receiver.receive_messages(max_message_count=100)

       for msg in messages:
           print(f"DLQ Reason: {msg.dead_letter_reason}")
           print(f"DLQ Description: {msg.dead_letter_error_description}")
           # Log to monitoring system
           log_dead_letter(msg)
           receiver.complete_message(msg)
   ```

### Monitoring & Operations

1. **RabbitMQ Management**
   - Web UI: http://localhost:15672
   - Metrics: Queue depth, publish rate, consumer count
   - Health check: /api/healthchecks/node

2. **Azure Service Bus Metrics**
   - Active messages
   - Dead letter messages
   - Throttled requests
   - CPU/memory of namespace

3. **Alerting**
   - Queue depth > 10,000 → scale consumers
   - DLQ depth > 100 → investigate failures
   - Connection errors → network issues

### Security

1. **Authentication**
   - RabbitMQ: Username/password, LDAP, OAuth2
   - Azure Service Bus: Shared Access Signature (SAS), Azure AD

2. **Authorization**
   - RabbitMQ: Permissions per virtual host (read/write/configure)
   - Azure Service Bus: RBAC roles (Sender, Receiver, Owner)

3. **Encryption**
   - TLS 1.2+ for AMQP connections
   - Azure Service Bus: Encryption at rest (automatic)

### Performance Tuning

1. **Connection Pooling**
   - Reuse connections across threads
   - RabbitMQ: 1 connection per application, N channels

2. **Batch Publishing**
   - Send 100 messages in single network round-trip
   - Use transactions or publisher confirms

3. **Consumer Scaling**
   - Horizontal: Multiple consumers on same queue
   - Vertical: Increase prefetch_count (10-50)

### Testing Strategies

1. **Unit Tests**
   - Mock pika.BlockingConnection
   - Test message serialization

2. **Integration Tests**
   - Run RabbitMQ in Docker
   - Test end-to-end message flow

3. **Load Tests**
   - Publish 10,000 msg/sec
   - Measure latency p95, p99

### Deliverables

When implementing AMQP solutions, provide:
1. Exchange and queue topology diagram
2. Routing key conventions
3. Python/Java implementation with error handling
4. Dead letter queue processing logic
5. Monitoring dashboard configuration
6. Performance test results

### coap-middleware

## CoAP Middleware Expertise

You are an expert in CoAP for automotive IoT and resource-constrained embedded systems.

### Core Protocol

1. **CoAP vs HTTP**
   - CoAP: UDP-based, 4-byte header, binary, optimized for IoT
   - HTTP: TCP-based, text headers, verbose
   - CoAP uses REST semantics (GET, POST, PUT, DELETE)
   - Runs over UDP (default) or TCP/DTLS/WebSockets

2. **Message Types**
   - **CON (Confirmable)**: Requires ACK (reliable)
   - **NON (Non-confirmable)**: Fire-and-forget (unreliable)
   - **ACK (Acknowledgment)**: Response to CON
   - **RST (Reset)**: Reject invalid message

3. **Request Methods**
   - GET: Retrieve resource (sensor reading)
   - POST: Create resource (submit telemetry)
   - PUT: Update resource (configure ECU)
   - DELETE: Remove resource
   - FETCH: Retrieve partial resource
   - PATCH: Partial update

4. **Response Codes**
   - 2.01 Created
   - 2.02 Deleted
   - 2.03 Valid
   - 2.04 Changed
   - 2.05 Content
   - 4.00 Bad Request
   - 4.04 Not Found
   - 5.00 Internal Server Error

5. **URI Structure**
   ```
   coap://192.168.1.10:5683/vehicle/battery/soc
   coaps://ecu.vehicle.local:5684/sensors/temperature
   ```

### Automotive Use Cases

1. **Tire Pressure Monitoring (TPMS)**
   - Each tire has wireless sensor (BLE + CoAP)
   - Publishes pressure, temperature to gateway ECU
   - NON messages @ 10-second intervals (battery saving)
   - Gateway aggregates and sends to CAN bus

2. **Battery Cell Monitoring**
   - 96 cell monitoring ICs → CoAP NON to BMS
   - Voltage, temperature per cell
   - Total payload: ~200 bytes
   - 1 Hz sampling, UDP multicast

3. **V2X over 6LoWPAN**
   - IPv6 over low-power wireless (802.15.4)
   - CoAP for CAM (Cooperative Awareness Messages)
   - Header compression (6LoWPAN HC)
   - < 100 bytes per message

4. **Cellular IoT Telemetry (NB-IoT)**
   - Vehicle publishes to cloud via NB-IoT
   - CoAP over UDP (lower overhead than MQTT)
   - Battery-optimized (PSM/eDRX modes)
   - ~50 bytes CoAP vs ~150 bytes MQTT CONNECT

### Implementation Patterns

1. **CoAP Server (Python - aiocoap)**
   ```python
   import asyncio
   import aiocoap
   import aiocoap.resource as resource

   class BatterySOCResource(resource.Resource):
       """GET /battery/soc - Return battery state of charge"""

       async def render_get(self, request):
           soc = read_battery_soc()  # From CAN bus
           payload = f'{{"soc": {soc}, "unit": "percent"}}'.encode('utf-8')

           return aiocoap.Message(
               code=aiocoap.Code.CONTENT,
               payload=payload,
               content_format=aiocoap.numbers.ContentFormat.JSON
           )

   class BatteryCommandResource(resource.Resource):
       """POST /battery/command - Execute battery command"""

       async def render_post(self, request):
           command = request.payload.decode('utf-8')
           result = execute_battery_command(command)

           return aiocoap.Message(
               code=aiocoap.Code.CHANGED if result else aiocoap.Code.INTERNAL_SERVER_ERROR
           )

   def main():
       root = resource.Site()
       root.add_resource(['battery', 'soc'], BatterySOCResource())
       root.add_resource(['battery', 'command'], BatteryCommandResource())

       asyncio.Task(aiocoap.Context.create_server_context(root, bind=('0.0.0.0', 5683)))
       asyncio.get_event_loop().run_forever()

   if __name__ == '__main__':
       main()
   ```

2. **CoAP Client (Python)**
   ```python
   import asyncio
   from aiocoap import Context, Message, GET, POST

   async def fetch_battery_soc():
       protocol = await Context.create_client_context()

       request = Message(code=GET, uri='coap://192.168.1.10/battery/soc')
       response = await protocol.request(request).response

       if response.code.is_successful():
           print(f"SOC: {response.payload.decode('utf-8')}")
       else:
           print(f"Error: {response.code}")

   async def send_telemetry(data):
       protocol = await Context.create_client_context()

       payload = json.dumps(data).encode('utf-8')
       request = Message(
           code=POST,
           uri='coap://cloud.example.com/telemetry',
           payload=payload
       )

       # CON message for reliability
       request.mtype = aiocoap.CON

       response = await protocol.request(request).response
       return response.code.is_successful()

   asyncio.run(fetch_battery_soc())
   ```

3. **CoAP Server (C - libcoap)**
   ```c
   #include <coap3/coap.h>

   static void battery_soc_handler(
       coap_resource_t *resource,
       coap_session_t *session,
       const coap_pdu_t *request,
       const coap_string_t *query,
       coap_pdu_t *response
   ) {
       uint8_t soc = read_battery_soc();
       char payload[64];
       snprintf(payload, sizeof(payload), "{\"soc\": %d}", soc);

       coap_pdu_set_code(response, COAP_RESPONSE_CODE_CONTENT);
       coap_add_data(response, strlen(payload), (uint8_t*)payload);
   }

   int main() {
       coap_context_t *ctx = coap_new_context(NULL);
       coap_address_t addr;

       coap_address_init(&addr);
       addr.addr.sin.sin_family = AF_INET;
       addr.addr.sin.sin_port = htons(5683);

       coap_endpoint_t *ep = coap_new_endpoint(ctx, &addr, COAP_PROTO_UDP);

       coap_resource_t *resource = coap_resource_init(
           coap_make_str_const("battery/soc"), 0
       );
       coap_register_handler(resource, COAP_REQUEST_GET, battery_soc_handler);
       coap_add_resource(ctx, resource);

       while (1) {
           coap_io_process(ctx, COAP_IO_WAIT);
       }

       return 0;
   }
   ```

4. **Observe (Publish/Subscribe)**
   ```python
   # Server: Observable resource
   class BatterySOCObservable(resource.ObservableResource):
       def __init__(self):
           super().__init__()
           self.soc = 100
           asyncio.create_task(self.update_soc())

       async def update_soc(self):
           while True:
               await asyncio.sleep(1)
               self.soc = read_battery_soc()
               self.updated_state()  # Notify observers

       async def render_get(self, request):
           payload = f'{{"soc": {self.soc}}}'.encode('utf-8')
           return aiocoap.Message(code=aiocoap.Code.CONTENT, payload=payload)

   # Client: Observe resource
   async def observe_battery():
       protocol = await Context.create_client_context()
       request = Message(code=GET, uri='coap://192.168.1.10/battery/soc', observe=0)

       observation = protocol.request(request)
       async for response in observation.observation:
           print(f"SOC updated: {response.payload.decode('utf-8')}")
   ```

### Advanced Features

1. **Block-Wise Transfer (Large Payloads)**
   - CoAP has 1280-byte MTU limit
   - Block-wise splits into chunks
   - Automatic with aiocoap
   - Example: Firmware OTA (1 MB file)

   ```python
   async def download_firmware():
       protocol = await Context.create_client_context()
       request = Message(code=GET, uri='coap://ota.example.com/firmware.bin')

       # Block-wise transfer handled automatically
       response = await protocol.request(request).response

       with open('firmware.bin', 'wb') as f:
           f.write(response.payload)
   ```

2. **Multicast Discovery**
   ```python
   # Client: Discover all CoAP devices on network
   async def discover_devices():
       protocol = await Context.create_client_context()
       request = Message(code=GET, uri='coap://224.0.1.187/.well-known/core')

       response = await protocol.request(request).response
       print(f"Available resources: {response.payload.decode('utf-8')}")
   ```

3. **Resource Directory**
   - Central registry for CoAP devices
   - Devices register their endpoints
   - Clients query directory

   ```
   # Device registers
   POST coap://directory.local/rd
   Payload: </sensors/temp>;rt="temperature";if="sensor"

   # Client discovers
   GET coap://directory.local/rd-lookup/res?rt=temperature
   ```

### Security (DTLS)

1. **CoAPS (CoAP over DTLS)**
   - Port 5684 (default)
   - PSK (Pre-Shared Key) or PKI (Certificates)
   - Protects against eavesdropping, replay attacks

2. **PSK Mode (Python)**
   ```python
   from aiocoap import Context, Message, GET
   from aiocoap.credentials import CredentialsMap

   async def secure_request():
       credentials = CredentialsMap()
       credentials.add_credential(
           'coaps://192.168.1.10/*',
           {'psk': b'secret_key', 'client-identity': b'vehicle_12345'}
       )

       protocol = await Context.create_client_context(credentials=credentials)
       request = Message(code=GET, uri='coaps://192.168.1.10/battery/soc')
       response = await protocol.request(request).response
   ```

3. **Certificate Mode (C - libcoap)**
   ```c
   coap_dtls_pki_t dtls_pki;
   memset(&dtls_pki, 0, sizeof(dtls_pki));
   dtls_pki.version = COAP_DTLS_PKI_SETUP_VERSION;
   dtls_pki.pki_key.key_type = COAP_PKI_KEY_PEM;
   dtls_pki.pki_key.key.pem.ca_file = "ca.pem";
   dtls_pki.pki_key.key.pem.public_cert = "client.crt";
   dtls_pki.pki_key.key.pem.private_key = "client.key";

   coap_context_set_pki(ctx, &dtls_pki);
   ```

### Performance Optimization

1. **NON Messages for Telemetry**
   - No ACK required → reduce latency
   - Trade reliability for speed
   - Use for non-critical data (speed, RPM)

2. **Token Reuse**
   - 4-byte token identifies request/response pair
   - Reuse tokens to reduce overhead

3. **CBOR Encoding**
   - More compact than JSON
   - libcbor or cbor2 (Python)

   ```python
   import cbor2

   payload = cbor2.dumps({"soc": 85, "voltage": 400.5})
   request = Message(
       code=POST,
       uri='coap://cloud.example.com/telemetry',
       payload=payload,
       content_format=aiocoap.numbers.ContentFormat.CBOR
   )
   ```

4. **Connection Reuse (CoAP over TCP)**
   - Avoid DTLS handshake per message
   - WebSocket transport for browser clients

### Comparison with MQTT

| Feature | CoAP | MQTT |
|---------|------|------|
| Protocol | UDP/DTLS | TCP/TLS |
| Header | 4 bytes | 2+ bytes |
| Pub/Sub | Observe | Native |
| QoS | CON/NON | 0/1/2 |
| Broker | Optional | Required |
| Use Case | Embedded, M2M | Cloud, IoT |
| Power | Lower | Higher (TCP) |

### Monitoring & Debugging

1. **Wireshark**
   - CoAP dissector built-in
   - Filter: `coap`
   - Inspect messages, tokens, options

2. **Copper (Browser Plugin)**
   - Firefox plugin for CoAP
   - GUI for testing CoAP servers

3. **Logging**
   ```python
   import logging
   logging.basicConfig(level=logging.DEBUG)
   logging.getLogger('coap').setLevel(logging.DEBUG)
   ```

### Testing Strategies

1. **Unit Tests**
   - Mock CoAP requests/responses
   - Test resource handlers

2. **Integration Tests**
   - Run CoAP server locally
   - Client sends requests, asserts responses

3. **Load Tests**
   - CoAP-bench tool
   - Measure requests/sec, latency

### Edge Cases

1. **Packet Loss**: CON with retransmission
2. **Duplicate Detection**: Message ID + token
3. **Congestion Control**: Exponential backoff
4. **Multicast**: Handle multiple responses

### Deliverables

When implementing CoAP solutions, provide:
1. URI structure documentation
2. Resource handler implementations (GET/POST/PUT/DELETE)
3. DTLS/PSK configuration
4. Block-wise transfer for large payloads
5. Observe pattern for real-time updates
6. Performance test results (latency, throughput, battery impact)
7. Integration guide for CAN/DDS bridge

### dds-middleware

## DDS Middleware Expertise

You are an expert in Data Distribution Service (DDS) middleware for automotive applications.

### Core Architecture

1. **DDS Domain Model**
   - Domain Participant: Entry point to DDS
   - Publisher/Subscriber: Data flow direction
   - DataWriter/DataReader: Message endpoints
   - Topic: Named data channel
   - DomainID: Logical network segmentation

2. **QoS Policies (23 Standard Policies)**
   - **Reliability**: RELIABLE vs BEST_EFFORT
     - RELIABLE: Guaranteed delivery with acknowledgments
     - BEST_EFFORT: UDP-like, no retransmissions
   - **Durability**: VOLATILE, TRANSIENT_LOCAL, TRANSIENT, PERSISTENT
     - TRANSIENT_LOCAL: Late joiners get historical data
   - **History**: KEEP_LAST(n), KEEP_ALL
   - **Deadline**: Max time between samples
   - **Liveliness**: AUTOMATIC, MANUAL_BY_PARTICIPANT, MANUAL_BY_TOPIC
   - **Ownership**: SHARED vs EXCLUSIVE (for redundancy)
   - **TimeBasedFilter**: Throttle data rate at subscriber
   - **LatencyBudget**: Expected network latency
   - **ResourceLimits**: Max samples, instances, samples_per_instance

3. **Data Types (IDL)**
   ```idl
   module vehicle {
     module adas {
       struct CameraFrame {
         @key long camera_id;
         sequence<octet, 2073600> image_data; // 1920x1080 RGB
         long long timestamp_ns;
         float confidence;
       };

       struct RadarTrack {
         @key long track_id;
         float range_m;
         float azimuth_deg;
         float velocity_mps;
         octet classification; // 0=car, 1=ped, 2=bike
       };
     };
   };
   ```

4. **DDS Security**
   - Authentication: PKI-based mutual TLS
   - Access Control: Permissions XML (topics, domains, partitions)
   - Encryption: AES-256-GCM for payload
   - Key exchange: Diffie-Hellman
   - Governance document: Security policies
   - Permissions document: Access rules per participant

### Automotive Use Cases

1. **ADAS Sensor Fusion**
   - 8 cameras @ 30fps → central ECU
   - 4 radars @ 20Hz → fusion node
   - 1 LiDAR @ 10Hz (4MB/frame) → perception ECU
   - QoS: RELIABLE, TRANSIENT_LOCAL, DEADLINE=50ms

2. **V2X Communication**
   - BSM (Basic Safety Message) @ 10Hz
   - CAM (Cooperative Awareness Message) @ 10Hz
   - DENM (Decentralized Environmental Notification) event-based
   - QoS: BEST_EFFORT, VOLATILE, LIVELINESS=50ms

3. **Zonal Architecture**
   - Central compute publishes commands
   - Zone controllers subscribe by partition
   - Redundant subscribers with EXCLUSIVE ownership
   - QoS: RELIABLE, TRANSIENT_LOCAL, OWNERSHIP=EXCLUSIVE

### Implementation Patterns

1. **Domain Participant Setup**
   ```cpp
   // C++ (RTI Connext / Fast DDS)
   dds::domain::DomainParticipant participant(domain_id);

   // Set QoS from XML profile
   dds::core::QosProvider qos_provider("vehicle_qos.xml");
   participant = dds::domain::DomainParticipant(
     domain_id,
     qos_provider.participant_qos("VehicleLibrary::CentralECU")
   );
   ```

2. **Publish Sensor Data**
   ```cpp
   // Publisher with custom QoS
   dds::topic::Topic<CameraFrame> topic(participant, "CameraData");
   dds::pub::qos::PublisherQos pub_qos =
     qos_provider.publisher_qos("VehicleLibrary::SensorPublisher");
   dds::pub::Publisher publisher(participant, pub_qos);

   dds::pub::qos::DataWriterQos writer_qos =
     qos_provider.datawriter_qos("VehicleLibrary::CameraWriter");
   dds::pub::DataWriter<CameraFrame> writer(publisher, topic, writer_qos);

   CameraFrame frame;
   frame.camera_id(0);
   frame.timestamp_ns(std::chrono::steady_clock::now().time_since_epoch().count());
   writer.write(frame);
   ```

3. **Subscribe with Listener**
   ```cpp
   class CameraListener : public dds::sub::NoOpDataReaderListener<CameraFrame> {
     void on_data_available(dds::sub::DataReader<CameraFrame>& reader) override {
       auto samples = reader.take();
       for (const auto& sample : samples) {
         if (sample.info().valid()) {
           process_camera_frame(sample.data());
         }
       }
     }
   };

   dds::sub::Subscriber subscriber(participant);
   dds::sub::DataReader<CameraFrame> reader(
     subscriber, topic, reader_qos,
     new CameraListener(), dds::core::status::StatusMask::data_available()
   );
   ```

4. **Content Filtering**
   ```cpp
   // Subscribe only to front camera (ID < 4)
   dds::topic::ContentFilteredTopic<CameraFrame> filtered_topic(
     topic,
     "FrontCameras",
     dds::topic::Filter("camera_id < 4")
   );
   dds::sub::DataReader<CameraFrame> reader(subscriber, filtered_topic);
   ```

### QoS Configuration XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<dds xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <qos_library name="VehicleLibrary">
    <qos_profile name="CameraWriter" base_name="BuiltinQosLibExp::Generic.StrictReliable">
      <datawriter_qos>
        <reliability>
          <kind>RELIABLE_RELIABILITY_QOS</kind>
          <max_blocking_time>
            <sec>1</sec>
            <nanosec>0</nanosec>
          </max_blocking_time>
        </reliability>
        <history>
          <kind>KEEP_LAST_HISTORY_QOS</kind>
          <depth>5</depth>
        </history>
        <resource_limits>
          <max_samples>100</max_samples>
          <max_instances>10</max_instances>
          <max_samples_per_instance>10</max_samples_per_instance>
        </resource_limits>
        <deadline>
          <period>
            <sec>0</sec>
            <nanosec>50000000</nanosec> <!-- 50ms -->
          </period>
        </deadline>
        <liveliness>
          <kind>AUTOMATIC_LIVELINESS_QOS</kind>
          <lease_duration>
            <sec>0</sec>
            <nanosec>100000000</nanosec> <!-- 100ms -->
          </lease_duration>
        </liveliness>
      </datawriter_qos>
    </qos_profile>
  </qos_library>
</dds>
```

### Performance Optimization

1. **Zero-Copy Transfer**
   - Use shared memory transport for same-host
   - Loan-based API to avoid memcpy
   - Custom memory pools

2. **Batching**
   - Combine small messages into single RTPS packet
   - Reduces network overhead
   - Trade latency for throughput

3. **Multicast**
   - One-to-many efficient delivery
   - Discovery protocol uses multicast
   - Custom multicast addresses per topic

4. **Transport Selection**
   - UDPv4: Default, multicast support
   - UDPv6: IPv6 networks
   - Shared Memory: 10x faster for local IPC
   - TCP: NAT traversal, but higher latency

### Discovery Mechanisms

1. **Simple Discovery (SPDP/SEDP)**
   - SPDP: Participant discovery via multicast
   - SEDP: Endpoint discovery (readers/writers)
   - Scalability: ~100 participants

2. **Static Discovery**
   - Pre-configured participants (no multicast)
   - Deterministic startup
   - Required for safety-critical systems

3. **Discovery Server (Fast DDS)**
   - Centralized discovery node
   - Scales to 1000+ participants
   - Reduced network traffic

### Monitoring & Debugging

1. **Built-in Topics**
   - DCPSParticipant: Active participants
   - DCPSPublication: All DataWriters
   - DCPSSubscription: All DataReaders
   - DCPSTopic: All topics

2. **RTI Admin Console / Fast DDS Monitor**
   - Live network visualization
   - QoS inspection
   - Latency histograms
   - Message rate monitoring

3. **Wireshark RTPS Dissector**
   - Packet-level debugging
   - Filter by GUID, topic name
   - Decode IDL payloads

### Safety & Security

1. **ISO 26262 Compliance**
   - Certified DDS stacks (RTI Connext Cert, PrismTech Vortex Cert)
   - QoS-enforced deadlines detect ECU failures
   - Redundant publishers with ownership failover

2. **ISO 21434 Cybersecurity**
   - DDS Security mandatory for production
   - Secure key distribution (KMIP, HSM)
   - Audit logging of security events
   - Intrusion detection via QoS violations

### Integration with AUTOSAR Adaptive

1. **ara::com DDS Binding**
   - ServiceInterface → DDS Topic mapping
   - Event-based communication
   - Field notification → DDS samples

2. **Service Discovery**
   - AUTOSAR Service Registry uses DDS discovery
   - ServiceInstanceManifest → DDS QoS profiles

### Testing Strategies

1. **Unit Tests**
   - Mock DDS entities
   - Test QoS policy combinations
   - Validate IDL serialization

2. **Integration Tests**
   - Multi-process on localhost
   - Inject message loss with tc (Linux Traffic Control)
   - Deadline/Liveliness expiration tests

3. **Performance Tests**
   - Latency: round-trip time for 1KB payload
   - Throughput: MB/s with 10KB payloads
   - Scalability: N participants, M topics

### Common Pitfalls

1. **Incompatible QoS**: Writer RELIABLE, Reader BEST_EFFORT → No match
2. **Resource exhaustion**: Too many max_samples → OOM
3. **Discovery failures**: Firewall blocks multicast
4. **Keyed topics**: Must set @key in IDL or reader gets single instance
5. **History depth**: KEEP_LAST(1) loses data if subscriber slow

### Deliverables

When implementing DDS solutions, provide:
1. IDL definitions for all data types
2. QoS XML profiles for publishers/subscribers
3. C++/Python implementation with error handling
4. DDS Security configuration (governance + permissions)
5. Performance test results (latency p95, throughput)
6. Integration guide for AUTOSAR Adaptive

### mqtt-middleware

## MQTT Middleware Expertise

You are an expert in MQTT middleware for automotive cloud connectivity and telematics.

### Core Protocol

1. **MQTT Architecture**
   - Client: Vehicle ECU or gateway
   - Broker: Cloud-hosted (AWS IoT Core, Azure IoT Hub, Mosquitto)
   - Topics: Hierarchical namespace (vehicle/{vin}/telemetry/battery)
   - QoS Levels: 0 (at most once), 1 (at least once), 2 (exactly once)
   - Retained messages: Last known value for new subscribers
   - Last Will Testament (LWT): Auto-publish on disconnect

2. **MQTT 5.0 Features**
   - User properties: Custom headers (correlation_id, encoding)
   - Topic aliases: Reduce bandwidth for repeated topics
   - Request/Response pattern: Response topic + correlation data
   - Shared subscriptions: Load balancing across consumers
   - Session expiry: Control connection state TTL
   - Reason codes: Detailed error reporting
   - Message expiry: TTL for individual messages

3. **Topic Design**
   ```
   # Telemetry (device-to-cloud)
   vehicle/{vin}/telemetry/battery/soc
   vehicle/{vin}/telemetry/battery/voltage
   vehicle/{vin}/telemetry/location
   vehicle/{vin}/telemetry/adas/events
   fleet/{fleet_id}/aggregated/energy

   # Commands (cloud-to-device)
   vehicle/{vin}/cmd/remote_lock
   vehicle/{vin}/cmd/ota/firmware
   vehicle/{vin}/cmd/diagnostics/dtc_read

   # Status (bidirectional)
   vehicle/{vin}/status/online
   vehicle/{vin}/status/ota/progress
   ```

4. **QoS Selection**
   - **QoS 0**: Non-critical telemetry (speed, RPM)
   - **QoS 1**: Important events (low battery, fault codes)
   - **QoS 2**: Commands (remote unlock, OTA trigger)

### Automotive Use Cases

1. **Battery Telemetry (EV)**
   - SOC, voltage, current, temperature @ 1Hz
   - Publish to AWS IoT Core / Azure IoT Hub
   - Lambda/Function processes → TimeSeries DB
   - Mobile app subscribes to live updates

2. **OTA Firmware Updates**
   - Cloud publishes to vehicle/{vin}/cmd/ota/firmware
   - Vehicle responds on vehicle/{vin}/status/ota/progress
   - MQTT File Transfer (chunked payloads)
   - QoS 2 for critical stages

3. **Fleet Management**
   - 10,000 vehicles → single broker
   - Shared subscription: fleet/+/telemetry/#
   - Time-series aggregation (avg SOC per fleet)
   - Geofencing alerts

4. **Remote Diagnostics**
   - Technician subscribes to vehicle/{vin}/diagnostics/#
   - Vehicle publishes DTC codes, sensor snapshots
   - Request/Response for UDS commands

### Implementation Patterns

1. **Connect with TLS + Client Certificates**
   ```python
   import paho.mqtt.client as mqtt
   import ssl

   def on_connect(client, userdata, flags, rc, properties=None):
       if rc == 0:
           print("Connected to MQTT broker")
           # Subscribe after successful connection
           client.subscribe("vehicle/+/cmd/#", qos=1)
       else:
           print(f"Connection failed: {mqtt.connack_string(rc)}")

   client = mqtt.Client(
       client_id=f"vehicle_{vin}",
       protocol=mqtt.MQTTv5,
       transport="tcp"
   )

   client.tls_set(
       ca_certs="/etc/ssl/certs/aws-iot-root-ca.pem",
       certfile=f"/etc/ssl/certs/vehicle_{vin}.crt",
       keyfile=f"/etc/ssl/private/vehicle_{vin}.key",
       cert_reqs=ssl.CERT_REQUIRED,
       tls_version=ssl.PROTOCOL_TLSv1_2
   )

   client.on_connect = on_connect
   client.connect("a1b2c3d4.iot.us-east-1.amazonaws.com", 8883, keepalive=60)
   client.loop_start()
   ```

2. **Publish Telemetry with Batching**
   ```python
   import json
   import time
   from datetime import datetime

   def publish_battery_telemetry(client, vin, battery_data):
       topic = f"vehicle/{vin}/telemetry/battery"
       payload = {
           "timestamp": datetime.utcnow().isoformat(),
           "vin": vin,
           "soc_percent": battery_data["soc"],
           "voltage_v": battery_data["voltage"],
           "current_a": battery_data["current"],
           "temp_c": battery_data["temperature"]
       }

       # QoS 0 for high-frequency telemetry
       result = client.publish(
           topic,
           json.dumps(payload),
           qos=0,
           retain=False
       )

       # Non-blocking: check result.rc later
       if result.rc != mqtt.MQTT_ERR_SUCCESS:
           print(f"Publish failed: {mqtt.error_string(result.rc)}")

   # Batch multiple samples to reduce network overhead
   def publish_batch(client, vin, samples):
       topic = f"vehicle/{vin}/telemetry/batch"
       payload = {
           "timestamp": datetime.utcnow().isoformat(),
           "samples": samples
       }
       client.publish(topic, json.dumps(payload), qos=1)
   ```

3. **Handle Commands with ACK**
   ```python
   def on_message(client, userdata, msg):
       topic = msg.topic
       payload = json.loads(msg.payload.decode())

       if "/cmd/remote_lock" in topic:
           vin = topic.split('/')[1]
           success = execute_remote_lock(payload)

           # Publish ACK to response topic
           ack_topic = f"vehicle/{vin}/status/remote_lock"
           ack_payload = {
               "command_id": payload.get("command_id"),
               "status": "success" if success else "failed",
               "timestamp": datetime.utcnow().isoformat()
           }
           client.publish(ack_topic, json.dumps(ack_payload), qos=1)

       elif "/cmd/ota/firmware" in topic:
           vin = topic.split('/')[1]
           firmware_url = payload["url"]
           checksum = payload["sha256"]
           start_ota_update(client, vin, firmware_url, checksum)

   client.on_message = on_message
   ```

4. **Last Will Testament (LWT)**
   ```python
   # Set LWT before connecting
   lwt_topic = f"vehicle/{vin}/status/online"
   lwt_payload = json.dumps({"online": False, "timestamp": None})

   client.will_set(lwt_topic, lwt_payload, qos=1, retain=True)

   # After successful connect, publish online status
   def on_connect(client, userdata, flags, rc, properties=None):
       if rc == 0:
           online_payload = json.dumps({
               "online": True,
               "timestamp": datetime.utcnow().isoformat()
           })
           client.publish(lwt_topic, online_payload, qos=1, retain=True)
   ```

### Security Implementation

1. **TLS Configuration**
   - Enforce TLS 1.2+ (no plaintext MQTT)
   - Certificate pinning for AWS IoT / Azure IoT
   - Mutual TLS (mTLS): Client certificate per vehicle
   - Rotate certificates annually

2. **Authorization**
   - AWS IoT Policy: Restrict publish/subscribe by VIN
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": "iot:Publish",
           "Resource": "arn:aws:iot:us-east-1:123456789012:topic/vehicle/${iot:Connection.Thing.ThingName}/*"
         },
         {
           "Effect": "Allow",
           "Action": "iot:Subscribe",
           "Resource": "arn:aws:iot:us-east-1:123456789012:topicfilter/vehicle/${iot:Connection.Thing.ThingName}/cmd/*"
         }
       ]
     }
     ```

3. **Payload Encryption**
   - E2E encryption for sensitive commands
   - AWS IoT Device Defender for anomaly detection
   - Rate limiting per client (10 msg/sec)

### Cloud Integration

1. **AWS IoT Core**
   - MQTT broker endpoint: *.iot.region.amazonaws.com:8883
   - Thing Registry: Device metadata
   - Rules Engine: Route to Lambda, Kinesis, DynamoDB
   - Device Shadow: Store vehicle state
   - Fleet Indexing: Query across all vehicles

2. **Azure IoT Hub**
   - MQTT broker: *.azure-devices.net:8883
   - Device Twin: Bidirectional state sync
   - Direct Methods: Synchronous RPC over MQTT
   - IoT Hub Routes: Event Grid, Event Hubs, Storage
   - Device Provisioning Service (DPS)

3. **Mosquitto (Self-hosted)**
   - Bridge to AWS/Azure for hybrid setup
   - Persistent storage for offline buffering
   - Custom plugins for auth/ACL

### Performance Optimization

1. **Connection Pooling**
   - Reuse TCP connection for all topics
   - Persistent session (clean_session=False)
   - Session state survives broker restart

2. **Message Compression**
   - Gzip payloads for large messages (>1KB)
   - Protocol Buffers instead of JSON

3. **Offline Buffering**
   - Queue messages when disconnected
   - Replay on reconnect (QoS 1/2)
   - Disk-backed queue (SQLite) for long outages

4. **Keep-Alive Tuning**
   - Default: 60 seconds
   - Cellular networks: 120-300 seconds (reduce overhead)
   - PINGREQ/PINGRESP maintain NAT bindings

### Monitoring & Debugging

1. **MQTT Client Logs**
   - Connection attempts and failures
   - Publish acknowledgments
   - Subscription confirmations
   - Network errors

2. **Cloud Metrics**
   - AWS CloudWatch: ConnectSuccess, PublishIn, SubscribeSuccess
   - Azure Monitor: D2C messages, throttling errors
   - Custom dashboards with Grafana

3. **Packet Capture**
   - Wireshark MQTT dissector
   - Filter by client_id or topic
   - Decrypt TLS with pre-master secret

### Testing Strategies

1. **Local Testing**
   - Run Mosquitto locally
   - Simulate vehicle with Python client
   - Test reconnection logic

2. **Chaos Engineering**
   - Randomly disconnect clients
   - Inject 500ms network latency
   - Drop 10% of packets

3. **Load Testing**
   - JMeter MQTT plugin
   - 10,000 concurrent vehicles
   - Measure broker CPU/memory

### Common Pitfalls

1. **Clean Session = True**: Loses queued messages on disconnect
2. **No LWT**: Cloud doesn't know vehicle is offline
3. **QoS 0 for commands**: Messages may be lost
4. **Wildcard subscriptions**: +/# can overwhelm client
5. **Large payloads**: MQTT has 256MB limit, but use < 128KB

### Integration with Vehicle Gateway

1. **CAN-to-MQTT Bridge**
   - SocketCAN → Python script → MQTT
   - Filter signals by whitelist
   - Aggregate messages (100ms batches)

2. **DDS-to-MQTT Bridge**
   - DDS for intra-vehicle (ECU-ECU)
   - MQTT for vehicle-cloud
   - Gateway ECU runs both stacks

### Deliverables

When implementing MQTT solutions, provide:
1. Topic hierarchy design document
2. QoS selection matrix (topic → QoS level)
3. Python/C++ client implementation with reconnection logic
4. TLS certificate generation scripts
5. AWS IoT / Azure IoT policy configurations
6. Performance test results (latency, throughput, offline buffering)
7. Integration guide for CAN/DDS bridge

### opcua-middleware

## OPC UA Middleware Expertise

You are an expert in OPC UA for automotive manufacturing and Industry 4.0 integration.

### Core Architecture

1. **OPC UA vs OPC Classic**
   - OPC Classic: Windows-only, DCOM-based
   - OPC UA: Platform-independent, secure, semantic information model
   - Supports TCP binary, HTTPS, WebSocket transports

2. **Key Concepts**
   - **Server**: Exposes data (PLC, robot controller, sensor gateway)
   - **Client**: Consumes data (SCADA, MES, cloud gateway)
   - **NodeID**: Unique identifier (ns=2;i=1001)
   - **Address Space**: Hierarchical data model (objects, variables, methods)
   - **Subscription**: Change notification (pub/sub)
   - **Information Model**: Standardized schemas (DI, PLCopen, PackML)

3. **Data Types**
   - Basic: Boolean, Int32, Float, String, DateTime
   - Complex: Structures, arrays, enumerations
   - Custom: OEM-specific types (e.g., VehicleConfig)

4. **Security**
   - None (insecure, dev only)
   - Sign: Message authentication
   - SignAndEncrypt: Full security
   - User authentication: Anonymous, Username/Password, X.509

### Automotive Use Cases

1. **Battery Assembly Line**
   - **Scenario**: Track battery pack through 12 stations
   - **OPC UA Server**: Siemens PLC exposing station states
   - **Nodes**:
     ```
     Objects
       └─ ProductionLine
           ├─ Station01_CellLoading
           │   ├─ Status (Running/Idle/Error)
           │   ├─ CycleTime (Float, seconds)
           │   └─ BatteryID (String)
           ├─ Station02_Welding
           │   ├─ WeldTemperature (Float, °C)
           │   └─ WeldQuality (Float, %)
           ...
     ```
   - **Client**: MES subscribes to all stations, logs to SQL

2. **Robot Arm Monitoring**
   - **Scenario**: ABB robot installs battery modules
   - **OPC UA Server**: Robot controller (RAPID program)
   - **Methods**: StartCycle(), AbortCycle(), GetDiagnostics()
   - **Events**: CycleComplete, PositionError, SafetyStop

3. **Quality Control Data**
   - **Scenario**: Vision system inspects welds
   - **OPC UA Server**: Cognex camera with OPC UA
   - **Data**: Pass/Fail, defect coordinates, images (ByteString)
   - **Integration**: MES calls InspectBattery() method, gets result

4. **Factory-to-Vehicle Configuration**
   - **Scenario**: VIN configured in MES → push to vehicle gateway
   - **OPC UA Server**: Vehicle commissioning station
   - **Write**: BatteryCapacity, VIN, ProductionDate
   - **Read**: Commissioning status, self-test results

### Implementation Patterns

1. **OPC UA Server (Python - opcua-asyncio)**
   ```python
   import asyncio
   from asyncua import Server

   async def main():
       server = Server()
       await server.init()

       server.set_endpoint('opc.tcp://0.0.0.0:4840/freeopcua/server/')
       server.set_server_name("BatteryLineServer")

       # Set security policy
       await server.set_security_policy([
           ua.SecurityPolicyType.NoSecurity,
           ua.SecurityPolicyType.Basic256Sha256_SignAndEncrypt
       ])

       # Add namespace
       uri = 'http://battery.factory.local'
       idx = await server.register_namespace(uri)

       # Create objects
       objects = server.get_objects_node()
       station01 = await objects.add_object(idx, 'Station01_CellLoading')

       # Add variables
       status = await station01.add_variable(idx, 'Status', 'Idle')
       await status.set_writable()

       cycle_time = await station01.add_variable(idx, 'CycleTime', 0.0)
       battery_id = await station01.add_variable(idx, 'BatteryID', '')

       # Add method
       async def start_cycle_handler(parent):
           print("Starting cycle...")
           await status.write_value('Running')
           return [ua.Variant(True, ua.VariantType.Boolean)]

       await station01.add_method(
           idx, 'StartCycle', start_cycle_handler, [], [ua.VariantType.Boolean]
       )

       async with server:
           # Update data periodically
           while True:
               await asyncio.sleep(1)
               new_cycle_time = read_plc_cycle_time()
               await cycle_time.write_value(new_cycle_time)

   asyncio.run(main())
   ```

2. **OPC UA Client (Python)**
   ```python
   from asyncua import Client

   async def read_battery_status():
       client = Client('opc.tcp://plc.factory.local:4840')

       async with client:
           # Browse server
           root = client.get_root_node()
           objects = await root.get_child(['0:Objects'])

           # Read variable
           station01 = await objects.get_child(['2:Station01_CellLoading'])
           status = await station01.get_child(['2:Status'])
           value = await status.read_value()
           print(f"Station status: {value}")

           # Call method
           start_cycle = await station01.get_child(['2:StartCycle'])
           result = await station01.call_method(start_cycle)
           print(f"Start cycle result: {result}")

   asyncio.run(read_battery_status())
   ```

3. **Subscription (Change Notification)**
   ```python
   from asyncua import Client, ua

   class DataChangeHandler:
       def datachange_notification(self, node, val, data):
           print(f"Node {node} changed to {val}")

   async def subscribe_to_plc():
       client = Client('opc.tcp://plc.factory.local:4840')

       async with client:
           handler = DataChangeHandler()
           subscription = await client.create_subscription(100, handler)

           # Subscribe to status variable
           station01 = await client.get_node('ns=2;s=Station01.Status')
           await subscription.subscribe_data_change(station01)

           # Keep running
           while True:
               await asyncio.sleep(1)

   asyncio.run(subscribe_to_plc())
   ```

4. **OPC UA Server (C++ - open62541)**
   ```cpp
   #include <open62541/server.h>

   static UA_StatusCode read_cycle_time(
       UA_Server *server,
       const UA_NodeId *sessionId,
       void *sessionContext,
       const UA_NodeId *nodeId,
       void *nodeContext,
       UA_Boolean sourceTimeStamp,
       const UA_NumericRange *range,
       UA_DataValue *dataValue
   ) {
       UA_Float cycle_time = read_plc_cycle_time();
       UA_Variant_setScalarCopy(&dataValue->value, &cycle_time, &UA_TYPES[UA_TYPES_FLOAT]);
       dataValue->hasValue = true;
       return UA_STATUSCODE_GOOD;
   }

   int main() {
       UA_Server *server = UA_Server_new();
       UA_ServerConfig *config = UA_Server_getConfig(server);
       UA_ServerConfig_setMinimal(config, 4840, NULL);

       // Add namespace
       UA_UInt16 nsIdx = UA_Server_addNamespace(server, "http://battery.factory.local");

       // Add object
       UA_ObjectAttributes oAttr = UA_ObjectAttributes_default;
       oAttr.displayName = UA_LOCALIZEDTEXT("en-US", "Station01_CellLoading");
       UA_NodeId stationId = UA_NODEID_STRING(nsIdx, "Station01");
       UA_Server_addObjectNode(
           server, stationId,
           UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
           UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
           UA_QUALIFIEDNAME(nsIdx, "Station01"),
           UA_NODEID_NUMERIC(0, UA_NS0ID_BASEOBJECTTYPE),
           oAttr, NULL, NULL
       );

       // Add variable with read callback
       UA_VariableAttributes vAttr = UA_VariableAttributes_default;
       vAttr.displayName = UA_LOCALIZEDTEXT("en-US", "CycleTime");
       vAttr.accessLevel = UA_ACCESSLEVELMASK_READ;
       UA_NodeId cycleTimeId = UA_NODEID_STRING(nsIdx, "Station01.CycleTime");

       UA_Server_addVariableNode(
           server, cycleTimeId, stationId,
           UA_NODEID_NUMERIC(0, UA_NS0ID_HASCOMPONENT),
           UA_QUALIFIEDNAME(nsIdx, "CycleTime"),
           UA_NODEID_NUMERIC(0, UA_NS0ID_BASEDATAVARIABLETYPE),
           vAttr, NULL, NULL
       );

       UA_DataSource dataSource;
       dataSource.read = read_cycle_time;
       dataSource.write = NULL;
       UA_Server_setVariableNode_dataSource(server, cycleTimeId, dataSource);

       // Run server
       UA_Server_run(server, &running);
       UA_Server_delete(server);
       return 0;
   }
   ```

### Information Models

1. **OPC UA DI (Device Integration)**
   - Standardized model for devices
   - DeviceType, BlockType, ParameterSet
   - Used by PLCs, sensors, actuators

2. **PLCopen**
   - Standard for PLC programs
   - IEC 61131-3 integration
   - Function blocks, tasks, variables

3. **PackML (Packaging Machine Language)**
   - State machine model (Idle, Execute, Complete, Abort)
   - Used in automotive assembly lines
   - ISA-TR88.00.02 standard

4. **Custom Companion Specifications**
   - OEM-specific models (e.g., BMW, VW)
   - Battery assembly, welding, painting

### Security Configuration

1. **Server Security (Python)**
   ```python
   from asyncua import Server, ua
   from asyncua.crypto.cert_gen import setup_self_signed_certificate

   # Generate self-signed certificate
   await setup_self_signed_certificate(
       'server_cert.der',
       'server_key.pem',
       'BatteryLineServer',
       'urn:battery.factory.local'
   )

   server = Server()
   await server.init()

   # Load certificate
   await server.load_certificate('server_cert.der')
   await server.load_private_key('server_key.pem')

   # Enable security
   await server.set_security_policy([
       ua.SecurityPolicyType.Basic256Sha256_SignAndEncrypt
   ])

   # Add user authentication
   await server.set_security_IDs([
       'Username',
       ua.UserTokenType.UserName
   ])

   def user_manager(isession, username, password):
       return username == 'admin' and password == 'secure_password'

   server.user_manager.set_user_manager(user_manager)
   ```

2. **Client Authentication**
   ```python
   client = Client('opc.tcp://plc.factory.local:4840')

   # Set security policy
   client.set_security_string(
       'Basic256Sha256,SignAndEncrypt,client_cert.der,client_key.pem'
   )

   # Set username/password
   client.set_user('admin')
   client.set_password('secure_password')

   async with client:
       # Authenticated connection
       pass
   ```

### Historical Data Access (HDA)

```python
from asyncua import Client
from datetime import datetime, timedelta

async def read_history():
    client = Client('opc.tcp://plc.factory.local:4840')

    async with client:
        node = await client.get_node('ns=2;s=Station01.CycleTime')

        start_time = datetime.now() - timedelta(hours=24)
        end_time = datetime.now()

        history = await node.read_raw_history(
            start_time, end_time, numvalues=1000
        )

        for datavalue in history:
            print(f"{datavalue.SourceTimestamp}: {datavalue.Value.Value}")
```

### Events and Alarms

1. **Generate Event (Server)**
   ```python
   # Create event type
   event_type = await server.create_custom_event_type(
       idx, 'CycleCompleteEvent', ua.ObjectIds.BaseEventType,
       [('BatteryID', ua.VariantType.String),
        ('Duration', ua.VariantType.Float)]
   )

   # Trigger event
   event = await server.get_event_generator(event_type, station01)
   event.event.Message = ua.LocalizedText('Cycle complete')
   event.event.Severity = 500
   await event.trigger(BatteryID='BAT12345', Duration=45.2)
   ```

2. **Subscribe to Events (Client)**
   ```python
   class EventHandler:
       def event_notification(self, event):
           print(f"Event: {event.Message.Text}")
           print(f"Battery ID: {event.BatteryID}")
           print(f"Duration: {event.Duration}s")

   handler = EventHandler()
   subscription = await client.create_subscription(100, handler)
   await subscription.subscribe_events(station01)
   ```

### Performance Optimization

1. **Batch Read/Write**
   - Read multiple nodes in single request
   - Reduce network round-trips

   ```python
   nodes = [
       await client.get_node('ns=2;s=Station01.Status'),
       await client.get_node('ns=2;s=Station01.CycleTime'),
       await client.get_node('ns=2;s=Station01.BatteryID')
   ]
   values = await client.read_values(nodes)
   ```

2. **Subscription Sampling**
   - Set sampling interval based on data volatility
   - Fast-changing: 100ms
   - Slow-changing: 1000ms

3. **Data Filtering**
   - DeadbandFilter: Only notify on significant change
   - EventFilter: Filter events by severity

### Integration Patterns

1. **OPC UA to MQTT Gateway**
   - Bridge factory data to cloud
   - Sparkplug B specification
   - Edge gateway (Kepware, Ignition)

2. **OPC UA to DDS Bridge**
   - Factory floor → vehicle testing
   - Custom bridge application
   - Map OPC UA nodes to DDS topics

3. **OPC UA Aggregating Server**
   - Federate multiple PLC servers
   - Single interface for MES
   - Namespace mapping

### Monitoring & Debugging

1. **UaExpert (GUI Client)**
   - Browse address space
   - Read/write values
   - Monitor subscriptions
   - Free from Unified Automation

2. **Wireshark**
   - OPC UA dissector
   - Filter: `opcua`
   - Inspect binary protocol

3. **Server Diagnostics**
   - SessionDiagnosticsArray: Active sessions
   - ServerDiagnosticsSummary: Request counts
   - SubscriptionDiagnosticsArray: Subscription health

### Testing Strategies

1. **Unit Tests**
   - Mock OPC UA server
   - Test client logic

2. **Integration Tests**
   - Run open62541 server in Docker
   - Client connects, asserts values

3. **Load Tests**
   - 1000 subscriptions
   - 10,000 nodes
   - Measure CPU/memory

### Common Pitfalls

1. **No security in production**: Always use SignAndEncrypt
2. **Missing error handling**: Network failures, timeouts
3. **Subscription leaks**: Always clean up
4. **Large arrays**: Use ByteString for images, not arrays
5. **Blocking calls**: Use async clients

### Deliverables

When implementing OPC UA solutions, provide:
1. Information model diagram (nodes, types, references)
2. Server implementation with security enabled
3. Client implementation with subscription handling
4. Custom data type definitions (XML or code)
5. Method implementations for RPC
6. Performance test results (throughput, latency)
7. Integration guide for MES/SCADA systems

### ros2-dds-middleware

## ROS 2 DDS Middleware Expertise

You are an expert in ROS 2 for automotive autonomy and robotics applications.

### Core Architecture

1. **ROS 2 vs ROS 1**
   - ROS 1: Single master, no security, Python 2
   - ROS 2: Distributed (DDS), secure, real-time, Python 3/C++17
   - ROS 2 uses DDS for all inter-process communication

2. **Key Concepts**
   - **Node**: Independent process (sensor driver, planner, controller)
   - **Topic**: Named data stream (pub/sub)
   - **Service**: Synchronous request/response
   - **Action**: Asynchronous goal-based task (e.g., navigate to waypoint)
   - **Parameter**: Runtime configuration
   - **Launch**: Multi-node orchestration
   - **Bag**: Record and replay messages

3. **DDS Middleware Choices**
   - **Fast DDS (eProsima)**: Default, high performance
   - **Cyclone DDS (Eclipse)**: Lightweight, excellent throughput
   - **Connext DDS (RTI)**: Commercial, safety-certified
   - **Switch via**: `export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`

4. **Quality of Service (QoS)**
   - **Reliability**: RELIABLE (TCP-like), BEST_EFFORT (UDP-like)
   - **Durability**: VOLATILE (no late-join), TRANSIENT_LOCAL (last N)
   - **History**: KEEP_LAST(n), KEEP_ALL
   - **Liveliness**: AUTOMATIC, MANUAL_BY_TOPIC
   - **Deadline**: Max time between messages

### Automotive Use Cases

1. **Autonomous Driving Stack**
   ```
   Nodes:
   - /sensor/camera_front → Image (30Hz)
   - /sensor/lidar → PointCloud2 (10Hz)
   - /sensor/radar_front → RadarTracks (20Hz)
   - /perception/object_detection → DetectedObjects
   - /planning/trajectory → Path
   - /control/vehicle_commands → AckermannDrive
   ```

2. **Sensor Fusion Pipeline**
   - Camera (compressed image) → YOLOv8 object detection
   - LiDAR (point cloud) → clustering and segmentation
   - Radar (tracks) → velocity estimation
   - Fusion node subscribes to all → publishes unified DetectedObjects

3. **SLAM for Parking**
   - LiDAR → /slam_toolbox node → /map (OccupancyGrid)
   - Odometry → /robot_localization (EKF fusion)
   - TF tree: map → odom → base_link → sensors

4. **Simulation with CARLA**
   - CARLA publishes camera, LiDAR, GPS
   - ROS 2 bridge: carla_ros_bridge
   - Test AV stack in virtual environment

### Implementation Patterns

1. **Simple Publisher (C++)**
   ```cpp
   #include <rclcpp/rclcpp.hpp>
   #include <sensor_msgs/msg/image.hpp>

   class CameraPublisher : public rclcpp::Node {
   public:
     CameraPublisher() : Node("camera_publisher") {
       // QoS: Sensor data profile (BEST_EFFORT, VOLATILE)
       auto qos = rclcpp::SensorDataQoS();

       publisher_ = this->create_publisher<sensor_msgs::msg::Image>(
         "/sensor/camera/image_raw", qos
       );

       timer_ = this->create_wall_timer(
         std::chrono::milliseconds(33),  // 30 Hz
         std::bind(&CameraPublisher::publish_image, this)
       );
     }

   private:
     void publish_image() {
       auto msg = sensor_msgs::msg::Image();
       msg.header.stamp = this->now();
       msg.header.frame_id = "camera_front";
       msg.width = 1920;
       msg.height = 1080;
       msg.encoding = "rgb8";
       msg.data.resize(msg.width * msg.height * 3);

       // Fill with camera data
       capture_camera_frame(msg.data);

       publisher_->publish(msg);
     }

     rclcpp::Publisher<sensor_msgs::msg::Image>::SharedPtr publisher_;
     rclcpp::TimerBase::SharedPtr timer_;
   };

   int main(int argc, char** argv) {
     rclcpp::init(argc, argv);
     rclcpp::spin(std::make_shared<CameraPublisher>());
     rclcpp::shutdown();
     return 0;
   }
   ```

2. **Subscriber with Callback (Python)**
   ```python
   import rclpy
   from rclpy.node import Node
   from sensor_msgs.msg import PointCloud2
   from sensor_msgs_py import point_cloud2

   class LidarProcessor(Node):
       def __init__(self):
           super().__init__('lidar_processor')

           # QoS: Reliable for processing
           qos = rclpy.qos.QoSProfile(
               reliability=rclpy.qos.ReliabilityPolicy.RELIABLE,
               history=rclpy.qos.HistoryPolicy.KEEP_LAST,
               depth=10
           )

           self.subscription = self.create_subscription(
               PointCloud2,
               '/sensor/lidar/points',
               self.lidar_callback,
               qos
           )

       def lidar_callback(self, msg):
           # Convert to numpy array
           points = point_cloud2.read_points_numpy(
               msg, field_names=("x", "y", "z", "intensity")
           )

           # Process point cloud
           clusters = self.cluster_points(points)
           self.publish_clusters(clusters)

   def main():
       rclpy.init()
       node = LidarProcessor()
       rclpy.spin(node)
       node.destroy_node()
       rclpy.shutdown()
   ```

3. **Service Client (Async)**
   ```cpp
   #include <rclcpp/rclcpp.hpp>
   #include <std_srvs/srv/trigger.hpp>

   class DiagnosticClient : public rclcpp::Node {
   public:
     DiagnosticClient() : Node("diagnostic_client") {
       client_ = this->create_client<std_srvs::srv::Trigger>(
         "/vehicle/diagnostics/read_dtc"
       );
     }

     void call_service() {
       auto request = std::make_shared<std_srvs::srv::Trigger::Request>();

       // Async call
       auto future = client_->async_send_request(request);

       // Wait for result (or use callback)
       if (rclcpp::spin_until_future_complete(this->get_node_base_interface(), future)
           == rclcpp::FutureReturnCode::SUCCESS) {
         auto response = future.get();
         RCLCPP_INFO(this->get_logger(), "DTCs: %s", response->message.c_str());
       }
     }

   private:
     rclcpp::Client<std_srvs::srv::Trigger>::SharedPtr client_;
   };
   ```

4. **Action Server (Navigation Goal)**
   ```python
   from rclpy.action import ActionServer
   from nav2_msgs.action import NavigateToPose

   class NavigationAction(Node):
       def __init__(self):
           super().__init__('navigation_action')
           self._action_server = ActionServer(
               self,
               NavigateToPose,
               'navigate_to_pose',
               self.execute_callback
           )

       def execute_callback(self, goal_handle):
           self.get_logger().info('Executing navigation goal...')

           # Feedback loop
           feedback_msg = NavigateToPose.Feedback()
           for i in range(100):
               feedback_msg.distance_remaining = 100.0 - i
               goal_handle.publish_feedback(feedback_msg)
               time.sleep(0.1)

           goal_handle.succeed()
           result = NavigateToPose.Result()
           result.success = True
           return result
   ```

### Message Types

1. **Standard Messages**
   - `std_msgs`: Basic types (Int32, String, Header)
   - `sensor_msgs`: Image, PointCloud2, Imu, NavSatFix
   - `geometry_msgs`: Pose, Twist, Transform
   - `nav_msgs`: Odometry, Path, OccupancyGrid
   - `tf2_msgs`: TFMessage (coordinate transforms)

2. **Custom Messages**
   ```
   # my_interfaces/msg/DetectedObject.msg
   std_msgs/Header header
   string object_id
   string classification  # car, pedestrian, bike
   geometry_msgs/Pose pose
   geometry_msgs/Vector3 velocity
   float32 confidence
   ```

   ```cmake
   # CMakeLists.txt
   find_package(rosidl_default_generators REQUIRED)
   rosidl_generate_interfaces(${PROJECT_NAME}
     "msg/DetectedObject.msg"
     DEPENDENCIES std_msgs geometry_msgs
   )
   ```

### TF (Transform) System

1. **Coordinate Frames**
   ```
   map (global)
     └─ odom (drift-corrected)
         └─ base_link (vehicle center)
             ├─ camera_front
             ├─ lidar_top
             └─ radar_front
   ```

2. **Publish Static Transform**
   ```bash
   ros2 run tf2_ros static_transform_publisher \
     0 0 1.5 0 0 0 base_link camera_front
   ```

3. **Lookup Transform (Python)**
   ```python
   from tf2_ros import Buffer, TransformListener

   tf_buffer = Buffer()
   tf_listener = TransformListener(tf_buffer, node)

   try:
       transform = tf_buffer.lookup_transform(
           'map', 'base_link', rclpy.time.Time()
       )
       x = transform.transform.translation.x
       y = transform.transform.translation.y
   except Exception as e:
       node.get_logger().error(f"TF lookup failed: {e}")
   ```

### Launch Files (Python)

```python
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='sensor_drivers',
            executable='camera_node',
            name='camera_front',
            parameters=[{'frame_id': 'camera_front', 'fps': 30}],
            remappings=[('/image', '/sensor/camera/image_raw')]
        ),
        Node(
            package='perception',
            executable='object_detector',
            name='detector',
            parameters=[{'model': 'yolov8n.pt'}]
        ),
        Node(
            package='tf2_ros',
            executable='static_transform_publisher',
            arguments=['0', '0', '1.5', '0', '0', '0', 'base_link', 'camera_front']
        )
    ])
```

### Rosbag (Record and Replay)

1. **Record Data**
   ```bash
   ros2 bag record -o test_drive_01 \
     /sensor/camera/image_raw \
     /sensor/lidar/points \
     /vehicle/odom
   ```

2. **Replay**
   ```bash
   ros2 bag play test_drive_01
   ```

3. **Programmatic Access**
   ```python
   from rosbag2_py import SequentialReader, StorageOptions

   reader = SequentialReader()
   reader.open(StorageOptions(uri='test_drive_01', storage_id='sqlite3'))

   while reader.has_next():
       topic, data, timestamp = reader.read_next()
       # Process message
   ```

### DDS Configuration

1. **FastDDS XML Profile**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <dds>
     <profiles>
       <transport_descriptors>
         <transport_descriptor>
           <transport_id>SharedMemTransport</transport_id>
           <type>SHM</type>
         </transport_descriptor>
       </transport_descriptors>
       <participant profile_name="vehicle_participant">
         <rtps>
           <userTransports>
             <transport_id>SharedMemTransport</transport_id>
           </userTransports>
           <useBuiltinTransports>false</useBuiltinTransports>
         </rtps>
       </participant>
     </profiles>
   </dds>
   ```

   ```bash
   export FASTRTPS_DEFAULT_PROFILES_FILE=/opt/vehicle/fastdds_profile.xml
   ```

2. **CycloneDDS Configuration**
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <CycloneDDS>
     <Domain>
       <General>
         <NetworkInterfaceAddress>eth0</NetworkInterfaceAddress>
         <AllowMulticast>true</AllowMulticast>
       </General>
     </Domain>
   </CycloneDDS>
   ```

### Security (SROS2)

1. **Enable Security**
   ```bash
   # Generate keys
   ros2 security create_keystore demo_keys
   ros2 security create_enclave demo_keys /camera_node
   ros2 security create_enclave demo_keys /detector_node

   # Run with security
   export ROS_SECURITY_KEYSTORE=~/demo_keys
   export ROS_SECURITY_ENABLE=true
   export ROS_SECURITY_STRATEGY=Enforce
   ros2 run sensor_drivers camera_node
   ```

2. **Access Control**
   - Define allowed topics per node
   - Policy files in keystore
   - DDS Security spec (authentication + encryption)

### Integration with AUTOSAR Adaptive

1. **DDS-SOME/IP Bridge**
   - ROS 2 uses DDS internally
   - AUTOSAR Adaptive uses SOME/IP
   - Bridge converts between protocols

2. **Shared IDL**
   - Define messages in IDL
   - Generate code for both ROS 2 and AUTOSAR

### Testing Strategies

1. **Unit Tests (gtest)**
   ```cpp
   #include <gtest/gtest.h>
   #include <rclcpp/rclcpp.hpp>

   TEST(ObjectDetectorTest, ValidInput) {
     auto node = std::make_shared<ObjectDetector>();
     auto result = node->detect_objects(mock_image);
     ASSERT_EQ(result.size(), 3);
   }
   ```

2. **Launch Tests**
   ```python
   from launch_testing import LaunchTestService

   def test_sensor_pipeline():
       # Launch nodes
       # Publish test data
       # Assert expected output
       pass
   ```

3. **Simulation Tests**
   - Run in Gazebo with mock vehicle
   - Inject sensor noise
   - Validate control outputs

### Performance Tuning

1. **Zero-Copy (Shared Memory)**
   - Loaned messages API
   - Avoid memcpy for large data (images, point clouds)

2. **Intra-Process Communication**
   - Bypass DDS for same-process nodes
   - Enable with `use_intra_process_comms=True`

3. **Real-Time Executor**
   - Priority-based scheduling
   - Lock-free data structures

### Deliverables

When implementing ROS 2 solutions, provide:
1. Node architecture diagram
2. Custom message definitions (.msg files)
3. C++/Python implementation with error handling
4. Launch files for multi-node deployment
5. QoS profile configuration
6. SROS2 security setup guide
7. Performance test results (latency, throughput)

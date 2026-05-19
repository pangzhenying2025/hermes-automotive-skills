# EV Charging - Detailed Implementation

## ISO 15118 Plug & Charge Implementation

Complete implementation of Plug & Charge with PKI certificate-based authentication.

### Certificate Chain

```
V2G Root CA
    └── OEM Sub-CA
            └── Contract Certificate (installed in vehicle)

EVSE Root CA
    └── CPO Sub-CA
            └── SECC Certificate (installed in charging station)
```

### TLS Handshake with Mutual Authentication

```python
import ssl
import socket
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa

class ISO15118_TLS_Client:
    def __init__(self, cert_path, key_path, ca_cert_path):
        self.cert = cert_path
        self.key = key_path
        self.ca_cert = ca_cert_path

    def establish_tls(self, server_address):
        """Establish TLS 1.2 connection with mutual authentication"""
        # Create SSL context
        context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)

        # Load client certificate and private key
        context.load_cert_chain(certfile=self.cert, keyfile=self.key)

        # Load CA certificate for server verification
        context.load_verify_locations(cafile=self.ca_cert)

        # Require server certificate verification
        context.verify_mode = ssl.CERT_REQUIRED
        context.check_hostname = False  # IPv6 link-local address

        # Create socket and wrap with TLS
        sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
        tls_sock = context.wrap_socket(sock)

        # Connect to EVSE
        tls_sock.connect(server_address)

        # Verify server certificate
        server_cert = tls_sock.getpeercert(binary_form=True)
        cert = x509.load_der_x509_certificate(server_cert)

        # Check certificate validity
        if not self.verify_certificate_chain(cert):
            raise Exception("Server certificate verification failed")

        return tls_sock

    def verify_certificate_chain(self, cert):
        """Verify certificate chain to root CA"""
        # Check expiration
        from datetime import datetime, timezone
        now = datetime.now(timezone.utc)
        if not (cert.not_valid_before <= now <= cert.not_valid_after):
            return False

        # Check signature (simplified - use proper OCSP in production)
        # In production: Query OCSP responder for revocation status
        return True
```

### EXI Message Encoding

EXI (Efficient XML Interchange) compresses XML by 10-100x.

```python
import pyexi  # EXI codec library

class EXI_Codec:
    def __init__(self, schema_path):
        self.encoder = pyexi.Encoder(schema_path)
        self.decoder = pyexi.Decoder(schema_path)

    def encode(self, xml_message):
        """Encode XML to EXI binary"""
        return self.encoder.encode(xml_message.encode('utf-8'))

    def decode(self, exi_binary):
        """Decode EXI binary to XML"""
        return self.decoder.decode(exi_binary).decode('utf-8')

# Example message
xml_session_setup = """<?xml version="1.0" encoding="UTF-8"?>
<ns:V2G_Message xmlns:ns="urn:iso:15118:2:2013:MsgDef">
    <ns:Header>
        <ns:SessionID>00112233445566778899AABBCCDDEEFF</ns:SessionID>
    </ns:Header>
    <ns:Body>
        <ns:SessionSetupReq>
            <ns:EVCCID>AABBCCDD11223344</ns:EVCCID>
        </ns:SessionSetupReq>
    </ns:Body>
</ns:V2G_Message>"""

codec = EXI_Codec('ISO15118_V2G.xsd')
exi_bytes = codec.encode(xml_session_setup)
print(f"XML size: {len(xml_session_setup)} bytes")
print(f"EXI size: {len(exi_bytes)} bytes")  # Typically 10-20x smaller
```

### EVCC (EV Communication Controller) State Machine

```python
import socket
import time
from enum import Enum

class EVCCState(Enum):
    UNPLUGGED = 0
    CONNECTED = 1
    SESSION_SETUP = 2
    SERVICE_DISCOVERY = 3
    PAYMENT_SELECTION = 4
    AUTHORIZATION = 5
    CHARGING = 6
    SESSION_STOP = 7

class EVCC:
    def __init__(self, contract_cert, private_key):
        self.state = EVCCState.UNPLUGGED
        self.contract_cert = contract_cert
        self.private_key = private_key
        self.session_id = None
        self.tls_socket = None

    def run(self):
        """Main state machine loop"""
        while True:
            if self.state == EVCCState.UNPLUGGED:
                self.wait_for_plugin()

            elif self.state == EVCCState.CONNECTED:
                self.perform_slac()  # Signal Level Attenuation Characterization
                self.state = EVCCState.SESSION_SETUP

            elif self.state == EVCCState.SESSION_SETUP:
                self.tls_socket = self.establish_tls_connection()
                self.send_session_setup_request()
                response = self.receive_session_setup_response()
                if response['ResponseCode'] == 'OK':
                    self.session_id = response['SessionID']
                    self.state = EVCCState.SERVICE_DISCOVERY
                else:
                    self.handle_error(response)

            elif self.state == EVCCState.SERVICE_DISCOVERY:
                self.send_service_discovery_request()
                response = self.receive_service_discovery_response()
                # Select charge service
                self.state = EVCCState.PAYMENT_SELECTION

            elif self.state == EVCCState.PAYMENT_SELECTION:
                self.send_payment_service_selection(payment_option='Contract')
                response = self.receive_payment_service_selection_response()
                self.state = EVCCState.AUTHORIZATION

            elif self.state == EVCCState.AUTHORIZATION:
                self.send_authorization_request(self.contract_cert)
                response = self.receive_authorization_response()
                if response['ResponseCode'] == 'OK':
                    self.state = EVCCState.CHARGING
                else:
                    self.handle_authorization_failure()

            elif self.state == EVCCState.CHARGING:
                self.send_charge_parameter_discovery()
                self.send_power_delivery_request(start=True)

                # Charging loop
                while self.is_charging():
                    self.send_current_demand()
                    time.sleep(0.1)  # 100 ms update rate

                self.send_power_delivery_request(start=False)
                self.state = EVCCState.SESSION_STOP

            elif self.state == EVCCState.SESSION_STOP:
                self.send_session_stop_request()
                self.tls_socket.close()
                self.state = EVCCState.UNPLUGGED

            time.sleep(0.1)

    def send_current_demand(self):
        """Request charging power during charging session"""
        bms = self.get_bms()  # Interface to BMS

        # Get battery state
        soc = bms.get_SOC()
        voltage = bms.get_voltage()
        max_current = bms.get_max_charge_current()
        target_voltage = bms.get_target_voltage()

        # Build CurrentDemandReq message
        message = {
            'MessageHeader': {
                'SessionID': self.session_id
            },
            'CurrentDemandReq': {
                'DC_EVStatus': {
                    'EVReady': True,
                    'EVErrorCode': 'NO_ERROR',
                    'EVRESSSOC': soc
                },
                'EVTargetCurrent': max_current,
                'EVMaximumVoltageLimit': target_voltage,
                'EVMaximumCurrentLimit': max_current,
                'RemainingTimeToFullSoC': self.estimate_charge_time(soc)
            }
        }

        # Encode and send
        exi_message = self.encode_exi(message)
        self.tls_socket.sendall(exi_message)

        # Receive response
        response = self.tls_socket.recv(4096)
        current_demand_res = self.decode_exi(response)

        # EVSE provides actual delivered power
        evse_voltage = current_demand_res['EVSEPresentVoltage']
        evse_current = current_demand_res['EVSEPresentCurrent']

        print(f"Charging: {evse_voltage:.1f}V @ {evse_current:.1f}A = {evse_voltage*evse_current/1000:.1f} kW")

        return current_demand_res
```

### SECC (Supply Equipment Communication Controller)

```python
class SECC:
    def __init__(self, secc_cert, private_key, max_power_kw=350):
        self.secc_cert = secc_cert
        self.private_key = private_key
        self.max_power_kw = max_power_kw
        self.sessions = {}

    def handle_session_setup(self, request):
        """Handle SessionSetupReq from vehicle"""
        evcc_id = request['EVCCID']
        session_id = self.generate_session_id()

        self.sessions[session_id] = {
            'EVCCID': evcc_id,
            'timestamp': time.time(),
            'state': 'SETUP'
        }

        response = {
            'ResponseCode': 'OK',
            'SessionID': session_id,
            'EVSETimeStamp': int(time.time())
        }

        return response

    def handle_authorization(self, request):
        """Verify vehicle contract certificate"""
        contract_cert_chain = request['ContractCertificateChain']

        # Verify certificate chain to V2G Root CA
        if self.verify_contract_certificate(contract_cert_chain):
            # Check with backend (CPS - Clearing House)
            if self.check_contract_valid(contract_cert_chain):
                return {'ResponseCode': 'OK', 'EVSEProcessing': 'Finished'}
            else:
                return {'ResponseCode': 'FAILED_ContractCancelled'}
        else:
            return {'ResponseCode': 'FAILED_CertificateRevoked'}

    def handle_current_demand(self, request):
        """Respond to charging current request"""
        ev_target_current = request['EVTargetCurrent']
        ev_target_voltage = request['EVTargetVoltage']

        # Limit based on charger capability
        max_current = min(ev_target_current, self.max_power_kw * 1000 / ev_target_voltage)

        # Get actual output from power module
        actual_voltage, actual_current = self.get_power_module_output()

        response = {
            'ResponseCode': 'OK',
            'DC_EVSEStatus': {
                'EVSENotification': 'None',
                'EVSEStatusCode': 'EVSE_Ready'
            },
            'EVSEPresentVoltage': actual_voltage,
            'EVSEPresentCurrent': actual_current,
            'EVSEMaximumCurrentLimit': max_current,
            'EVSEMaximumPowerLimit': self.max_power_kw * 1000,
            'EVSEID': 'US*ABC*123456'
        }

        return response
```

## CAN Communication (CHAdeMO Example)

```python
import can

class CHAdeMo_EV:
    def __init__(self, can_bus='can0', bitrate=500000):
        self.bus = can.interface.Bus(channel=can_bus, bustype='socketcan', bitrate=bitrate)

    def send_status(self, soc, voltage, current_request):
        """Send 0x100: Vehicle status"""
        data = bytearray(8)
        data[0] = 0x01  # Charging enabled
        data[1] = soc  # SOC (0-100%)
        data[2:4] = int(voltage * 10).to_bytes(2, 'big')  # Voltage (0.1V units)
        data[4:6] = int(current_request * 10).to_bytes(2, 'big')  # Current request (0.1A)
        data[6] = 0x00  # Fault flags

        msg = can.Message(arbitration_id=0x100, data=data, is_extended_id=False)
        self.bus.send(msg)

    def receive_charger_status(self):
        """Receive 0x108: Charger status"""
        msg = self.bus.recv(timeout=1.0)

        if msg and msg.arbitration_id == 0x108:
            voltage_output = int.from_bytes(msg.data[0:2], 'big') / 10
            current_output = int.from_bytes(msg.data[2:4], 'big') / 10
            charger_status = msg.data[4]

            return {
                'voltage': voltage_output,
                'current': current_output,
                'status': 'OK' if charger_status == 0 else 'ERROR'
            }

        return None

    def charge_loop(self, target_soc=80):
        """CHAdeMO charging loop"""
        while True:
            # Get battery state
            soc = self.bms.get_SOC()
            voltage = self.bms.get_voltage()
            max_current = self.bms.get_max_charge_current()

            # Send status to charger
            self.send_status(soc, voltage, max_current)

            # Receive charger response
            status = self.receive_charger_status()

            if status:
                print(f"Charging: {status['voltage']}V @ {status['current']}A")

            # Check stop condition
            if soc >= target_soc:
                break

            time.sleep(0.1)  # 100 ms update rate
```

## Smart Charging Optimization

```python
import cvxpy as cp

class SmartChargingOptimizer:
    def __init__(self, num_vehicles=10, time_horizon=24):
        self.num_vehicles = num_vehicles
        self.time_horizon = time_horizon  # hours

    def optimize(self, vehicles, grid_limit_kw, electricity_prices):
        """
        Minimize charging cost while meeting departure deadlines

        vehicles: List of {arrival_time, departure_time, energy_needed_kWh, max_power_kw}
        grid_limit_kw: Maximum power available from grid
        electricity_prices: Array of prices per kWh for each hour
        """
        V = self.num_vehicles
        T = self.time_horizon

        # Decision variable: power for each vehicle at each time
        P = cp.Variable((V, T), nonneg=True)

        # Objective: minimize cost
        cost = 0
        for v in range(V):
            for t in range(T):
                cost += P[v, t] * electricity_prices[t]

        # Constraints
        constraints = []

        # 1. Energy requirement met by departure time
        for v, vehicle in enumerate(vehicles):
            arrival = vehicle['arrival_time']
            departure = vehicle['departure_time']
            energy_needed = vehicle['energy_needed_kWh']

            # Total energy delivered = sum of power over time
            energy_delivered = cp.sum(P[v, arrival:departure])
            constraints.append(energy_delivered >= energy_needed)

        # 2. Vehicle power limit
        for v, vehicle in enumerate(vehicles):
            for t in range(T):
                constraints.append(P[v, t] <= vehicle['max_power_kw'])

        # 3. Grid power limit
        for t in range(T):
            total_power = cp.sum(P[:, t])
            constraints.append(total_power <= grid_limit_kw)

        # 4. Vehicle can only charge when present
        for v, vehicle in enumerate(vehicles):
            arrival = vehicle['arrival_time']
            departure = vehicle['departure_time']

            # Before arrival and after departure: no charging
            if arrival > 0:
                constraints.append(P[v, :arrival] == 0)
            if departure < T:
                constraints.append(P[v, departure:] == 0)

        # Solve
        problem = cp.Problem(cp.Minimize(cost), constraints)
        problem.solve(solver=cp.OSQP)

        # Extract schedule
        schedule = P.value

        return schedule, cost.value

# Example usage
optimizer = SmartChargingOptimizer(num_vehicles=5, time_horizon=24)

vehicles = [
    {'arrival_time': 18, 'departure_time': 7, 'energy_needed_kWh': 40, 'max_power_kw': 7.2},  # Overnight
    {'arrival_time': 9, 'departure_time': 17, 'energy_needed_kWh': 20, 'max_power_kw': 11},  # Workplace
    # ... more vehicles
]

electricity_prices = [0.10] * 6 + [0.15] * 12 + [0.12] * 6  # Off-peak, peak, shoulder

schedule, total_cost = optimizer.optimize(vehicles, grid_limit_kw=50, electricity_prices=electricity_prices)
print(f"Optimal charging schedule computed. Total cost: ${total_cost:.2f}")
```

## Next Steps

- **Level 4**: Connector pinouts, power level tables, protocol message catalog
- **Level 5**: V2G grid services, wireless charging resonant coupling
- **Related**: Battery thermal management during fast charging, grid integration

## References

- ISO 15118-2: Vehicle to Grid Communication Interface
- CHAdeMO Protocol Specification v2.0
- OCPP 2.0.1: Open Charge Point Protocol
- IEC 61851: Electric vehicle conductive charging system

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Intended Audience**: EV charging software developers, protocol implementers, optimization engineers

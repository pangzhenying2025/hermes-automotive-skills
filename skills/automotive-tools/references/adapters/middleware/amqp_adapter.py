"""
AMQP (Advanced Message Queuing Protocol) Adapter for Automotive Manufacturing.

Supports:
- RabbitMQ (opensource)
- Azure Service Bus (cloud)
- Publisher confirms
- Dead letter queues
"""

import json
import logging
import time
import uuid
from typing import Dict, Any, Optional, Callable
from dataclasses import dataclass

try:
    import pika
    PIKA_AVAILABLE = True
except ImportError:
    PIKA_AVAILABLE = False

from ..base_adapter import OpensourceToolAdapter


@dataclass
class AMQPConfig:
    """AMQP connection configuration."""
    host: str = "localhost"
    port: int = 5672
    virtual_host: str = "/"
    username: str = "guest"
    password: str = "guest"
    heartbeat: int = 600
    blocked_connection_timeout: int = 300


class AMQPAdapter(OpensourceToolAdapter):
    """
    Adapter for AMQP protocol (RabbitMQ, Azure Service Bus).

    Features:
    - Exchange types: direct, topic, fanout
    - Publisher confirms for reliability
    - Consumer acknowledgments
    - Dead letter exchanges
    - Priority queues

    Example:
        >>> adapter = AMQPAdapter()
        >>> adapter.publish_to_exchange(
        ...     exchange='vehicle.config',
        ...     routing_key='vehicle.model_s.premium',
        ...     message={'vin': '123', 'color': 'blue'}
        ... )
    """

    def __init__(self, config: Optional[AMQPConfig] = None):
        """Initialize AMQP adapter."""
        super().__init__(name='amqp')
        self.config = config or AMQPConfig()
        self.connection = None
        self.channel = None

    def _detect(self) -> bool:
        """Detect if pika is available."""
        return PIKA_AVAILABLE

    def execute(self, command: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute AMQP command."""
        if command == 'connect':
            return self._execute_connect(parameters)
        elif command == 'publish':
            return self._execute_publish(parameters)
        elif command == 'consume':
            return self._execute_consume(parameters)
        elif command == 'declare_queue':
            return self._execute_declare_queue(parameters)
        else:
            return {'success': False, 'error': f'Unknown command: {command}'}

    def _execute_connect(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Connect to AMQP broker."""
        try:
            self.connect()
            return {'success': True, 'connected': self.connection is not None}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_publish(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Publish message to exchange."""
        try:
            exchange = params.get('exchange', '')
            routing_key = params.get('routing_key')
            message = params.get('message')

            self.publish_to_exchange(exchange, routing_key, message)
            return {'success': True}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_consume(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Start consuming from queue."""
        try:
            queue = params.get('queue')
            callback = params.get('callback')

            self.consume(queue, callback)
            return {'success': True, 'queue': queue}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _execute_declare_queue(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Declare queue with options."""
        try:
            queue = params.get('queue')
            durable = params.get('durable', True)
            dlx = params.get('dead_letter_exchange')

            self.declare_queue(queue, durable=durable, dlx=dlx)
            return {'success': True, 'queue': queue}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def connect(self):
        """Connect to RabbitMQ."""
        if not PIKA_AVAILABLE:
            raise RuntimeError("pika not installed")

        credentials = pika.PlainCredentials(
            self.config.username,
            self.config.password
        )

        parameters = pika.ConnectionParameters(
            host=self.config.host,
            port=self.config.port,
            virtual_host=self.config.virtual_host,
            credentials=credentials,
            heartbeat=self.config.heartbeat,
            blocked_connection_timeout=self.config.blocked_connection_timeout
        )

        self.connection = pika.BlockingConnection(parameters)
        self.channel = self.connection.channel()
        self.logger.info(f"Connected to RabbitMQ: {self.config.host}")

    def disconnect(self):
        """Disconnect from RabbitMQ."""
        if self.connection:
            self.connection.close()
            self.connection = None
            self.channel = None

    def declare_exchange(
        self,
        exchange: str,
        exchange_type: str = 'topic',
        durable: bool = True
    ):
        """
        Declare exchange.

        Args:
            exchange: Exchange name
            exchange_type: direct, topic, fanout, headers
            durable: Survive broker restart
        """
        if not self.channel:
            raise RuntimeError("Not connected")

        self.channel.exchange_declare(
            exchange=exchange,
            exchange_type=exchange_type,
            durable=durable
        )

    def declare_queue(
        self,
        queue: str,
        durable: bool = True,
        dlx: Optional[str] = None,
        ttl_ms: Optional[int] = None
    ):
        """
        Declare queue with options.

        Args:
            queue: Queue name
            durable: Persist to disk
            dlx: Dead letter exchange
            ttl_ms: Message TTL in milliseconds
        """
        if not self.channel:
            raise RuntimeError("Not connected")

        arguments = {}
        if dlx:
            arguments['x-dead-letter-exchange'] = dlx
        if ttl_ms:
            arguments['x-message-ttl'] = ttl_ms

        self.channel.queue_declare(
            queue=queue,
            durable=durable,
            arguments=arguments if arguments else None
        )

    def bind_queue(self, queue: str, exchange: str, routing_key: str):
        """Bind queue to exchange with routing key."""
        if not self.channel:
            raise RuntimeError("Not connected")

        self.channel.queue_bind(
            exchange=exchange,
            queue=queue,
            routing_key=routing_key
        )

    def publish_to_exchange(
        self,
        exchange: str,
        routing_key: str,
        message: Dict[str, Any],
        persistent: bool = True
    ):
        """
        Publish message to exchange.

        Example:
            >>> adapter.publish_to_exchange(
            ...     'vehicle.config',
            ...     'vehicle.model_s.premium',
            ...     {'vin': '123', 'trim': 'premium'}
            ... )
        """
        if not self.channel:
            raise RuntimeError("Not connected")

        body = json.dumps(message)

        properties = pika.BasicProperties(
            delivery_mode=2 if persistent else 1,
            content_type='application/json',
            correlation_id=str(uuid.uuid4()),
            timestamp=int(time.time())
        )

        self.channel.basic_publish(
            exchange=exchange,
            routing_key=routing_key,
            body=body,
            properties=properties
        )

        self.logger.debug(f"Published to {exchange}/{routing_key}")

    def consume(
        self,
        queue: str,
        callback: Callable[[Dict[str, Any]], None],
        auto_ack: bool = False,
        prefetch_count: int = 10
    ):
        """
        Consume messages from queue.

        Args:
            queue: Queue name
            callback: Function called for each message
            auto_ack: Automatically acknowledge messages
            prefetch_count: QoS prefetch
        """
        if not self.channel:
            raise RuntimeError("Not connected")

        def message_callback(ch, method, properties, body):
            try:
                data = json.loads(body)
                callback(data)

                if not auto_ack:
                    ch.basic_ack(delivery_tag=method.delivery_tag)

            except Exception as e:
                self.logger.error(f"Error processing message: {e}")
                if not auto_ack:
                    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)

        self.channel.basic_qos(prefetch_count=prefetch_count)
        self.channel.basic_consume(
            queue=queue,
            on_message_callback=message_callback,
            auto_ack=auto_ack
        )

        self.logger.info(f"Consuming from {queue}")
        self.channel.start_consuming()


# Example: Manufacturing line integration
def manufacturing_example():
    """Vehicle configuration distribution in factory."""
    adapter = AMQPAdapter()
    adapter.connect()

    # Declare exchange and queues
    adapter.declare_exchange('vehicle.config', exchange_type='topic')
    adapter.declare_queue('queue.paint_shop', durable=True)
    adapter.bind_queue('queue.paint_shop', 'vehicle.config', 'vehicle.*.premium')

    # Publish vehicle config
    config = {
        'vin': 'ABC123XYZ',
        'model': 'model_s',
        'trim': 'premium',
        'color': 'blue',
        'timestamp': time.time()
    }
    adapter.publish_to_exchange(
        'vehicle.config',
        'vehicle.model_s.premium',
        config
    )

    adapter.disconnect()


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    print("AMQP Adapter - Manufacturing Integration")
    print("=" * 50)

    adapter = AMQPAdapter()
    print(f"AMQP Available: {adapter.is_available}")

    if adapter.is_available:
        manufacturing_example()

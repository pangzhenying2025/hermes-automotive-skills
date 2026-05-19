# ADAS Service Helm Chart

Production-ready Helm chart for deploying ADAS (Advanced Driver Assistance Systems) processing service on Kubernetes.

## Overview

This Helm chart deploys a highly available, scalable ADAS processing service with comprehensive monitoring, security, and automotive compliance features.

## Features

- **High Availability**: Multi-replica deployment with pod anti-affinity
- **Auto-scaling**: Horizontal Pod Autoscaler based on CPU/memory
- **Security**: Pod security standards, network policies, read-only root filesystem
- **Monitoring**: Prometheus metrics, ServiceMonitor integration
- **Compliance**: ISO 26262 (ASIL-B), ASPICE (AL2), GDPR labels
- **Health Checks**: Liveness, readiness, and startup probes
- **Rolling Updates**: Zero-downtime deployments
- **Resource Management**: Defined limits and requests

## Prerequisites

- Kubernetes 1.25+
- Helm 3.8+
- kubectl configured
- (Optional) Prometheus Operator for monitoring
- (Optional) cert-manager for TLS certificates
- (Optional) Ingress controller (nginx)

## Installation

### Quick Start

```bash
# Add Helm repository
helm repo add automotive https://charts.automotive.example.com
helm repo update

# Install with default values
helm install adas-service automotive/adas-service \
  --namespace automotive-production \
  --create-namespace

# Install with custom values
helm install adas-service automotive/adas-service \
  --namespace automotive-production \
  --values custom-values.yaml
```

### From Source

```bash
# Clone repository
git clone https://github.com/automotive/helm-charts.git
cd helm-charts/adas-service

# Install chart
helm install adas-service . \
  --namespace automotive-production \
  --create-namespace
```

## Configuration

### Common Configurations

#### Development Environment

```bash
helm install adas-service automotive/adas-service \
  --namespace automotive-dev \
  --set environment=development \
  --set replicaCount=1 \
  --set autoscaling.enabled=false \
  --set ingress.hosts[0].host=adas-dev.automotive.local
```

#### Staging Environment

```bash
helm install adas-service automotive/adas-service \
  --namespace automotive-staging \
  --set environment=staging \
  --set replicaCount=2 \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=2Gi
```

#### Production Environment

```bash
helm install adas-service automotive/adas-service \
  --namespace automotive-production \
  --set environment=production \
  --set replicaCount=3 \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=20 \
  --set resources.limits.cpu=2000m \
  --set resources.limits.memory=4Gi
```

### Values File Examples

#### values-production.yaml

```yaml
replicaCount: 3

image:
  tag: "2.5.0"
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 500m
    memory: 1Gi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70

automotive:
  environment: production
  region: us-west-2
  safetyLevel: ASIL-B

ingress:
  enabled: true
  hosts:
    - host: adas.automotive.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Parameters

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `2` |
| `image.repository` | Image repository | `automotive/adas-processing-service` |
| `image.tag` | Image tag | `2.5.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

### Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `8080` |
| `service.metricsPort` | Metrics port | `9090` |
| `service.grpcPort` | gRPC port | `50051` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.hosts[0].host` | Hostname | `adas.automotive.example.com` |

### Resource Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `2000m` |
| `resources.limits.memory` | Memory limit | `4Gi` |
| `resources.requests.cpu` | CPU request | `500m` |
| `resources.requests.memory` | Memory request | `1Gi` |

### Autoscaling Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `20` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `70` |

### Automotive Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `automotive.region` | Deployment region | `us-west-2` |
| `automotive.environment` | Environment | `production` |
| `automotive.safetyLevel` | Safety level (ASIL) | `ASIL-B` |
| `automotive.aspiceLevel` | ASPICE level | `AL2` |

## Upgrading

```bash
# Upgrade with new values
helm upgrade adas-service automotive/adas-service \
  --namespace automotive-production \
  --values new-values.yaml \
  --wait

# Upgrade to specific version
helm upgrade adas-service automotive/adas-service \
  --version 1.1.0 \
  --namespace automotive-production

# Rollback to previous version
helm rollback adas-service 1 \
  --namespace automotive-production
```

## Uninstallation

```bash
helm uninstall adas-service --namespace automotive-production
```

## Monitoring

### Prometheus Metrics

The service exposes Prometheus metrics on port 9090:

- `adas_processing_duration_seconds` - Processing latency histogram
- `adas_processing_queue_depth` - Current queue depth
- `adas_sensor_frame_rate` - Sensor frame rate by type
- `adas_object_detection_count` - Object detection count by class
- `adas_safety_events_total` - Safety event counter

### Grafana Dashboard

Import the provided Grafana dashboard:

```bash
kubectl apply -f dashboards/adas-service-dashboard.json
```

## Security

### Pod Security Standards

This chart enforces restricted pod security standards:
- Runs as non-root user (UID 1000)
- Read-only root filesystem
- Drops all capabilities
- No privilege escalation
- seccomp profile enabled

### Network Policies

Network policies restrict traffic to:
- Ingress: Only from authorized namespaces/pods
- Egress: Only to required services and DNS

### Secrets Management

For sensitive configuration, use Kubernetes secrets:

```bash
kubectl create secret generic adas-service-secrets \
  --from-literal=api-key=your-api-key \
  --namespace automotive-production

# Reference in values:
envFrom:
  - secretRef:
      name: adas-service-secrets
```

## Compliance

### ISO 26262 (ASIL-B)

This deployment includes:
- Safety-critical labels
- Resource guarantees
- Health monitoring
- Audit logging
- Immutable configuration

### ASPICE (AL2)

Requirements addressed:
- Documented configuration
- Version control
- Change traceability
- Testing procedures

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n automotive-production -l app.kubernetes.io/name=adas-service

# View pod logs
kubectl logs -n automotive-production <pod-name>

# Describe pod
kubectl describe pod -n automotive-production <pod-name>
```

### Service Unreachable

```bash
# Check service
kubectl get svc -n automotive-production adas-service

# Test service connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  wget -O- http://adas-service.automotive-production:8080/health
```

### High Resource Usage

```bash
# Check resource usage
kubectl top pods -n automotive-production -l app.kubernetes.io/name=adas-service

# Adjust resource limits
helm upgrade adas-service automotive/adas-service \
  --set resources.limits.cpu=4000m \
  --set resources.limits.memory=8Gi
```

## Support

- **Documentation**: https://docs.automotive.example.com/adas-service
- **Issues**: https://github.com/automotive/adas-service/issues
- **Slack**: #adas-service
- **Email**: support@automotive.example.com

## License

Proprietary - Automotive Platform Team

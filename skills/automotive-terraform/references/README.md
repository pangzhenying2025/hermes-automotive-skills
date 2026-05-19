# Multi-Cloud Infrastructure as Code

**Cloud-agnostic infrastructure supporting AWS, Azure, and GCP with Terraform, Pulumi, and Crossplane.**

## Overview

Production-ready Infrastructure as Code (IaC) framework for deploying vehicle fleet management systems across multiple cloud providers with multi-region scaling, disaster recovery, and cost optimization.

## Quick Links

- **[Quick Start Guide](./QUICKSTART.md)** - Get started in 30 minutes
- **[Multi-Cloud Guide](./MULTI_CLOUD_GUIDE.md)** - Comprehensive cloud comparison
- **[Multi-Region Strategy](./multi-region/MULTI_REGION_STRATEGY.md)** - DR and scaling patterns

## Repository Structure

```
terraform/
├── azure/                          # Azure-specific Terraform modules
│   ├── modules/
│   │   ├── iot-hub/               # IoT Hub + DPS + Event Hub + Stream Analytics
│   │   ├── aks/                   # Azure Kubernetes Service with multiple node pools
│   │   ├── cosmos-db/             # Cosmos DB with MongoDB API (multi-region)
│   │   ├── storage/               # Blob Storage + Data Lake Gen2
│   │   └── networking/            # VNet, NSG, Private Endpoints
│   └── examples/vehicle-fleet/    # Complete vehicle fleet deployment
│
├── gcp/                           # GCP-specific Terraform modules
│   ├── modules/
│   │   ├── iot-core/              # Pub/Sub + Dataflow (IoT Core replacement)
│   │   ├── gke/                   # Google Kubernetes Engine
│   │   ├── bigtable/              # Cloud Bigtable for time-series
│   │   ├── storage/               # Cloud Storage with lifecycle policies
│   │   └── networking/            # VPC, Firewall, Private Service Connect
│   └── examples/vehicle-fleet/
│
├── multi-cloud/                   # Cloud-agnostic frameworks
│   ├── pulumi/                    # Pulumi TypeScript multi-cloud
│   │   ├── aws/
│   │   ├── azure/
│   │   ├── gcp/
│   │   └── hybrid/                # Single codebase → all clouds
│   └── crossplane/                # Kubernetes-native IaC
│       ├── compositions/          # Cloud-agnostic compositions
│       │   └── vehicle-cluster.yaml
│       └── providers/             # AWS, Azure, GCP provider setup
│
├── multi-region/                  # Multi-region orchestration
│   ├── MULTI_REGION_STRATEGY.md   # Active-active, active-passive patterns
│   ├── traffic-manager/           # Global load balancing
│   ├── replication/               # Data replication strategies
│   └── failover/                  # Automated failover
│
├── MULTI_CLOUD_GUIDE.md           # Comprehensive cloud comparison
├── QUICKSTART.md                  # 30-minute deployment guide
└── README.md                      # This file
```

## Deployment Options

### Option 1: Terraform (Native)

**Best for**: Single cloud, production deployments

```bash
cd terraform/azure/examples/vehicle-fleet
terraform init
terraform apply -var-file=environments/prod.tfvars
```

**Features**:
- Cloud-optimized modules
- Mature ecosystem
- HCL configuration
- State management via backend

### Option 2: Pulumi (Multi-Cloud)

**Best for**: Multi-cloud, developers familiar with TypeScript/Python

```bash
cd terraform/multi-cloud/pulumi/hybrid
npm install
pulumi config set cloud aws  # or azure, gcp
pulumi up
```

**Features**:
- Single codebase → all clouds
- TypeScript/Python/Go
- State in Pulumi Cloud/S3/Azure Blob
- Native IDE support

### Option 3: Crossplane (Kubernetes-Native)

**Best for**: Platform engineering, GitOps workflows

```bash
kubectl apply -f terraform/multi-cloud/crossplane/compositions/vehicle-cluster.yaml
kubectl apply -f - <<EOF
apiVersion: automotive.example.com/v1alpha1
kind: VehicleCluster
metadata:
  name: my-cluster
spec:
  parameters:
    region: us-east-1
    nodeSize: medium
  compositionSelector:
    matchLabels:
      provider: aws
EOF
```

**Features**:
- Kubernetes CRDs
- GitOps-native (ArgoCD/Flux)
- State in K8s etcd
- Automatic drift correction

## Cloud Comparison

### IoT Platform

| Feature | AWS IoT Core | Azure IoT Hub | GCP Pub/Sub |
|---------|--------------|---------------|-------------|
| **Protocol** | MQTT, HTTPS, LoRaWAN | MQTT, AMQP, HTTPS | MQTT (via 3rd party) |
| **Device Registry** | Built-in | Built-in | Manual |
| **Provisioning** | Fleet Provisioning | DPS | Custom |
| **Cost (1M msgs/mo)** | $8 | $10 | $5 |

### Kubernetes

| Feature | AWS EKS | Azure AKS | GCP GKE |
|---------|---------|-----------|---------|
| **Control Plane Cost** | $73/mo | Free | Free |
| **Serverless Nodes** | Fargate | Virtual Nodes (ACI) | Autopilot |
| **Multi-Region** | Manual | Traffic Manager | Multi-cluster Ingress |
| **Auto-scaling** | CA + HPA | CA + HPA + KEDA | Node Auto-provisioning |

### Database (Time-Series)

| Feature | AWS Timestream | Azure Cosmos DB | GCP Bigtable |
|---------|---------------|-----------------|--------------|
| **Type** | Serverless | Provisioned/Serverless | Provisioned |
| **Replication** | Multi-AZ | Multi-region write | Multi-cluster |
| **Query** | SQL-like | MongoDB API | HBase API |
| **Cost (1TB)** | $50/mo | $300/mo | $370/mo |

**Recommendation**:
- **AWS**: Best for all-in-one AWS deployments
- **Azure**: Best for enterprise with existing MS investments
- **GCP**: Best for cost optimization and data analytics

## Architecture Patterns

### Active-Active Multi-Region

```
                  ┌─────────────┐
                  │ Global DNS  │
                  └──────┬──────┘
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼─────┐     ┌────▼─────┐    ┌────▼─────┐
   │ US-EAST  │◄───►│ EU-WEST  │◄───►│ AP-SOUTH │
   │ (Active) │     │ (Active) │    │ (Active) │
   └──────────┘     └──────────┘    └──────────┘
```

- **RTO**: < 1 minute
- **RPO**: < 15 seconds
- **Cost**: 3x resources
- **Use Case**: Mission-critical, global applications

### Active-Passive DR

```
                  ┌─────────────┐
                  │ Global DNS  │
                  └──────┬──────┘
                         │
                    ┌────▼─────┐
                    │ US-EAST  │
                    │ (Primary)│
                    └────┬─────┘
                         │ Async Replication
                    ┌────▼─────┐
                    │ EU-WEST  │
                    │(Secondary)│
                    └──────────┘
```

- **RTO**: 5-15 minutes
- **RPO**: 1-5 minutes
- **Cost**: 1.5x resources
- **Use Case**: DR compliance, cost optimization

## Cost Estimates

### Development (10 vehicles)

| Component | AWS | Azure | GCP | Winner |
|-----------|-----|-------|-----|--------|
| IoT | $25/mo | $50/mo | $15/mo | **GCP** |
| Kubernetes | $220/mo | $200/mo | $200/mo | **Azure/GCP** |
| Database | $180/mo | $300/mo | $150/mo | **GCP** |
| Storage | $50/mo | $40/mo | $45/mo | **Azure** |
| **Total** | **$475/mo** | **$590/mo** | **$410/mo** | **GCP** |

### Production (10,000 vehicles)

| Component | AWS | Azure | GCP | Winner |
|-----------|-----|-------|-----|--------|
| IoT | $200/mo | $250/mo | $150/mo | **GCP** |
| Kubernetes | $800/mo | $700/mo | $700/mo | **Azure/GCP** |
| Database | $600/mo | $1,200/mo | $500/mo | **GCP** |
| Storage | $250/mo | $200/mo | $220/mo | **Azure** |
| **Total** | **$1,850/mo** | **$2,350/mo** | **$1,570/mo** | **GCP** |

**Savings Strategies**:
- Reserved instances: 30-65% discount
- Spot/preemptible: 70-90% discount
- Storage tiering: 70% reduction
- Right-sizing: 30-50% savings

## Features

### Azure Modules

- **IoT Hub**: Device connectivity, DPS, Event Hub integration
- **AKS**: Multi-node pools (system, user, spot), autoscaling, RBAC
- **Cosmos DB**: Multi-region write, MongoDB API, automatic failover
- **Storage**: Blob, Data Lake Gen2, lifecycle policies, CDN

### GCP Modules

- **IoT Platform**: Pub/Sub, Dataflow, BigQuery integration
- **GKE**: Autopilot, workload identity, multi-zonal
- **Bigtable**: Time-series optimized, multi-cluster replication
- **Storage**: Intelligent tiering, lifecycle management

### Multi-Cloud

- **Pulumi**: TypeScript/Python, single codebase → all clouds
- **Crossplane**: Kubernetes CRDs, GitOps-ready, drift correction

## Security

### Network Isolation

```hcl
# Private endpoints for all services
enable_private_endpoint = true
public_network_access_enabled = false
```

### Encryption

```hcl
# At-rest: AES-256, in-transit: TLS 1.3
encryption_enabled = true
encryption_key_source = "Microsoft.KeyVault"  # or AWS KMS, GCP KMS
```

### Identity

```hcl
# Managed identities, no hardcoded credentials
identity {
  type = "SystemAssigned"  # or UserAssigned
}
```

### Compliance

- **GDPR**: Data residency enforcement, EU-only replication
- **SOC 2**: Audit logging, access controls
- **ISO 27001**: Encryption, network segmentation

## Monitoring

### Metrics

```bash
# Prometheus + Grafana
helm install prometheus prometheus-community/kube-prometheus-stack

# Cloud-native
# AWS: CloudWatch Container Insights
# Azure: Azure Monitor for containers
# GCP: Cloud Monitoring (native)
```

### Alerting

- **IoT**: Message backlog, dead letters, throttling
- **Kubernetes**: Pod failures, node pressure, OOM
- **Database**: High latency, replication lag, throttling
- **Cost**: Budget alerts, anomaly detection

### Dashboards

- Regional health status
- Traffic distribution
- Replication lag
- Cost per region
- SLA compliance

## CI/CD Integration

### Terraform Cloud

```hcl
terraform {
  backend "remote" {
    organization = "vehicle-fleet"
    workspaces {
      name = "production"
    }
  }
}
```

### GitHub Actions

```yaml
- name: Terraform Apply
  uses: hashicorp/terraform-github-actions@master
  with:
    tf_actions_version: 1.5.0
    tf_actions_subcommand: apply
```

### ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: vehicle-infrastructure
spec:
  source:
    path: terraform/multi-cloud/crossplane/claims
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Migration Guides

### From AWS to Azure

1. Export Terraform state
2. Convert IoT Core → IoT Hub mappings
3. EKS → AKS migration (Velero backups)
4. Timestream → Cosmos DB data migration
5. Route 53 → Traffic Manager DNS cutover

### From Terraform to Crossplane

1. Install Crossplane providers
2. Create compositions matching Terraform modules
3. Import existing resources
4. Test in dev environment
5. Gradual production migration

## Getting Started

1. **Read**: [QUICKSTART.md](./QUICKSTART.md)
2. **Choose**: Terraform vs Pulumi vs Crossplane
3. **Deploy**: Follow path-specific guide
4. **Monitor**: Set up observability
5. **Scale**: Enable multi-region

## Support

- **Documentation**: See guides above
- **Slack**: #devops-multi-cloud
- **Email**: devops@example.com
- **Issues**: File with label `multi-cloud-iac`

## Contributing

1. Fork repository
2. Create feature branch
3. Test in dev environment
4. Submit PR with documentation
5. Code review by DevOps team

## License

MIT License - see LICENSE file

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Google Cloud Architecture Framework](https://cloud.google.com/architecture/framework)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Pulumi Best Practices](https://www.pulumi.com/docs/intro/concepts/programming-model/)
- [Crossplane Documentation](https://crossplane.io/docs/)

---

**Built with ❤️ by the DevOps Engineering Team**

**Version**: 1.0.0
**Last Updated**: 2026-03-19

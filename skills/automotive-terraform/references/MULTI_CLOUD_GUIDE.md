# Multi-Cloud Infrastructure as Code Guide

**Author**: DevOps Engineer
**Created**: 2026-03-19
**Version**: 1.0.0

## Overview

Cloud-agnostic Infrastructure as Code framework supporting AWS, Azure, and GCP with multi-region scaling, disaster recovery, and cost optimization.

## Architecture Decision

This framework provides **three deployment strategies**:

1. **Native Terraform Modules**: Cloud-specific modules optimized per provider
2. **Pulumi Multi-Cloud**: Single codebase deploying across clouds
3. **Crossplane**: Kubernetes-native IaC for cloud-agnostic abstractions

## Directory Structure

```
terraform/
├── aws/                    # AWS-specific Terraform modules
│   ├── modules/
│   └── examples/
├── azure/                  # Azure-specific Terraform modules
│   ├── modules/
│   │   ├── iot-hub/       # Azure IoT Hub + DPS
│   │   ├── aks/           # Azure Kubernetes Service
│   │   ├── cosmos-db/     # Cosmos DB (MongoDB API)
│   │   ├── storage/       # Blob Storage + Data Lake
│   │   └── networking/    # VNet, NSG, Private Endpoints
│   └── examples/vehicle-fleet/
├── gcp/                    # GCP-specific Terraform modules
│   ├── modules/
│   │   ├── iot-core/      # Cloud Pub/Sub + Dataflow
│   │   ├── gke/           # Google Kubernetes Engine
│   │   ├── bigtable/      # Cloud Bigtable
│   │   ├── storage/       # Cloud Storage
│   │   └── networking/    # VPC, Firewall, Private Service
│   └── examples/vehicle-fleet/
├── multi-cloud/            # Cloud-agnostic frameworks
│   ├── pulumi/            # Pulumi TypeScript/Python
│   │   ├── aws/
│   │   ├── azure/
│   │   ├── gcp/
│   │   └── hybrid/        # Hybrid deployments
│   └── crossplane/        # Kubernetes CRDs
│       ├── compositions/
│       └── providers/
└── multi-region/           # Multi-region orchestration
    ├── traffic-manager/   # Global load balancing
    ├── replication/       # Data replication strategies
    └── failover/          # Automated failover
```

## Cloud Comparison Matrix

### IoT Platform

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **IoT Service** | AWS IoT Core | Azure IoT Hub | Cloud Pub/Sub (IoT Core deprecated) |
| **Device Provisioning** | IoT Fleet Provisioning | Device Provisioning Service (DPS) | Manual / Custom |
| **Protocols** | MQTT, HTTPS, LoRaWAN | MQTT, AMQP, HTTPS | MQTT (via 3rd party) |
| **Device Registry** | IoT Thing Registry | IoT Hub Identity Registry | N/A |
| **Rules Engine** | IoT Rules | Azure Stream Analytics | Dataflow |
| **Cost (1M msgs/mo)** | ~$8 | ~$10 | ~$5 (Pub/Sub only) |

### Kubernetes

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **Service** | Amazon EKS | Azure Kubernetes Service (AKS) | Google Kubernetes Engine (GKE) |
| **Control Plane Cost** | $0.10/hr (~$73/mo) | Free | Free |
| **Serverless Nodes** | Fargate | Virtual Nodes (ACI) | Autopilot |
| **Multi-Region** | Manual federation | AKS + Traffic Manager | Multi-cluster Ingress |
| **Monitoring** | CloudWatch Container Insights | Azure Monitor | Cloud Monitoring (GKE native) |
| **Autoscaling** | Cluster Autoscaler + HPA | Cluster Autoscaler + HPA + KEDA | Node Auto-provisioning |

### Time-Series Database

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **Service** | Amazon Timestream | Cosmos DB (MongoDB API) | Cloud Bigtable |
| **Write Model** | Serverless | Provisioned RU/s or Serverless | Provisioned nodes |
| **Replication** | Multi-AZ | Multi-region write | Multi-cluster replication |
| **Query Language** | SQL-like | MongoDB query | HBase API / SQL (via Dataflow) |
| **Cost (1TB storage)** | ~$50/mo | ~$300/mo (10K RU/s) | ~$370/mo (3 nodes) |

### Object Storage

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **Service** | Amazon S3 | Azure Blob Storage | Cloud Storage |
| **Tiers** | Standard, IA, Glacier | Hot, Cool, Archive | Standard, Nearline, Coldline, Archive |
| **CDN** | CloudFront | Azure CDN | Cloud CDN |
| **Lifecycle** | S3 Lifecycle | Blob Lifecycle Management | Object Lifecycle Management |
| **Cost (1TB Standard)** | ~$23/mo | ~$18/mo | ~$20/mo |

## Multi-Region Architecture

### Traffic Distribution

```
                    ┌─────────────────┐
                    │  Global DNS     │
                    │  (Route 53 /    │
                    │  Traffic Mgr /  │
                    │  Cloud DNS)     │
                    └────────┬────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │  us-east-1  │   │  eu-west-1  │   │  ap-south-1 │
    │   (Primary) │   │  (Secondary)│   │   (Tertiary)│
    └──────┬──────┘   └──────┬──────┘   └──────┬──────┘
           │                 │                 │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │  K8s Cluster│   │  K8s Cluster│   │  K8s Cluster│
    │  Database   │◄──┤  Database   │◄──┤  Database   │
    │  Storage    │   │  Storage    │   │  Storage    │
    └─────────────┘   └─────────────┘   └─────────────┘
```

### Replication Strategies

1. **Active-Active**: All regions serve traffic, data replicated bi-directionally
   - Use case: Low latency globally, high availability
   - Cost: High (3x resources)
   - Complexity: Conflict resolution required

2. **Active-Passive**: Primary region serves, secondary standby
   - Use case: Disaster recovery, cost optimization
   - Cost: Medium (1.5x resources)
   - Complexity: Failover automation required

3. **Active-Active-Standby**: Two active regions, one cold standby
   - Use case: Balance of performance and cost
   - Cost: Medium-High (2.2x resources)
   - Complexity: Moderate

## Cost Optimization

### General Strategies

1. **Right-sizing**: Use spot/preemptible instances for non-critical workloads
2. **Reserved Capacity**: 1-3 year commitments for predictable workloads
3. **Tiered Storage**: Hot → Cool → Archive lifecycle policies
4. **Auto-scaling**: Scale down during off-peak hours
5. **Multi-cloud Arbitrage**: Deploy workloads to cheapest cloud per use case

### Cost Comparison (Vehicle Fleet Example)

**Assumptions**: 10,000 vehicles, 1 msg/sec/vehicle, 3-month retention

| Component | AWS | Azure | GCP | Winner |
|-----------|-----|-------|-----|--------|
| **IoT Ingestion** | $200/mo | $250/mo | $150/mo | GCP |
| **Kubernetes (3 nodes)** | $350/mo | $280/mo | $280/mo | Azure/GCP |
| **Time-Series DB** | $450/mo | $800/mo | $370/mo | GCP |
| **Object Storage (5TB)** | $115/mo | $90/mo | $100/mo | Azure |
| **Networking** | $300/mo | $250/mo | $200/mo | GCP |
| **TOTAL** | **$1,415/mo** | **$1,670/mo** | **$1,100/mo** | **GCP** |

**Recommendation**: Use GCP for IoT ingestion + time-series, Azure for storage, AWS for legacy integrations.

## Migration Guides

### AWS to Azure

1. **IoT**: AWS IoT Core → Azure IoT Hub (DPS for provisioning)
2. **Kubernetes**: EKS → AKS (use Azure Migrate for workloads)
3. **Database**: Timestream → Cosmos DB (export/import via JSON)
4. **Storage**: S3 → Blob Storage (use AzCopy or AWS DataSync)

### Azure to GCP

1. **IoT**: IoT Hub → Cloud Pub/Sub + Dataflow
2. **Kubernetes**: AKS → GKE (migrate workloads via Velero)
3. **Database**: Cosmos DB → Bigtable (custom migration script)
4. **Storage**: Blob Storage → Cloud Storage (gsutil rsync)

### Multi-Cloud Deployment

Use Pulumi or Crossplane to deploy same workload across clouds:

```typescript
// Pulumi example
import * as aws from "@pulumi/aws";
import * as azure from "@pulumi/azure-native";
import * as gcp from "@pulumi/gcp";

const config = new pulumi.Config();
const cloud = config.require("cloud"); // aws, azure, or gcp

if (cloud === "aws") {
  const cluster = new aws.eks.Cluster("vehicle-cluster", {...});
} else if (cloud === "azure") {
  const cluster = new azure.containerservice.ManagedCluster("vehicle-cluster", {...});
} else if (cloud === "gcp") {
  const cluster = new gcp.container.Cluster("vehicle-cluster", {...});
}
```

## Disaster Recovery

### RTO/RPO Targets

| Tier | RTO | RPO | Strategy |
|------|-----|-----|----------|
| **Critical** | < 1 hour | < 15 min | Active-Active, sync replication |
| **Important** | < 4 hours | < 1 hour | Active-Passive, async replication |
| **Standard** | < 24 hours | < 4 hours | Backup/Restore |

### Automated Failover

```hcl
# Azure Traffic Manager failover
resource "azurerm_traffic_manager_profile" "vehicle_fleet" {
  traffic_routing_method = "Priority"

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/health"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }
}
```

## Security Best Practices

1. **Network Isolation**: Private endpoints, no public IPs
2. **Encryption**: At-rest (AES-256), in-transit (TLS 1.3)
3. **Identity**: Managed identities, no hardcoded credentials
4. **Secrets**: Key Vault (Azure), Secrets Manager (AWS), Secret Manager (GCP)
5. **Compliance**: SOC 2, ISO 27001, GDPR-ready configurations
6. **Monitoring**: CloudTrail, Azure Monitor, Cloud Audit Logs

## Quick Start

### 1. Deploy Azure Vehicle Fleet

```bash
cd terraform/azure/examples/vehicle-fleet
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply
```

### 2. Deploy GCP Vehicle Fleet

```bash
cd terraform/gcp/examples/vehicle-fleet
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply
```

### 3. Deploy Multi-Cloud with Pulumi

```bash
cd terraform/multi-cloud/pulumi/hybrid
npm install
pulumi stack init dev
pulumi config set cloud aws  # or azure, gcp
pulumi up
```

### 4. Deploy with Crossplane

```bash
kubectl apply -f terraform/multi-cloud/crossplane/compositions/vehicle-cluster.yaml
kubectl apply -f terraform/multi-cloud/crossplane/providers/aws-provider.yaml
```

## Monitoring & Observability

### Unified Metrics

Use Prometheus + Grafana for cloud-agnostic monitoring:

- AWS: CloudWatch → Prometheus exporter
- Azure: Azure Monitor → Prometheus remote write
- GCP: Cloud Monitoring → Prometheus federation

### Distributed Tracing

- **OpenTelemetry**: Cloud-agnostic instrumentation
- **Jaeger/Tempo**: Trace storage and visualization

## Support

For questions or issues:
- Slack: #devops-multi-cloud
- Email: devops@saft.com
- Jira: Create ticket with label `multi-cloud-iac`

## References

- [Terraform Cloud Provider Comparison](https://www.terraform.io/docs/providers)
- [Pulumi Multi-Cloud Guide](https://www.pulumi.com/docs/guides/crosswalk/)
- [Crossplane Documentation](https://crossplane.io/docs/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Google Cloud Architecture Framework](https://cloud.google.com/architecture/framework)

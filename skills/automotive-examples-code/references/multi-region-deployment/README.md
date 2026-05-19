# Multi-Region Deployment Reference Implementation

This directory contains production-ready reference implementations for deploying automotive cloud infrastructure across multiple geographic regions.

## Overview

This reference implementation demonstrates:
- **Active-Active Multi-Region** architecture across AWS regions
- **Global Traffic Management** with Route 53
- **Database Replication** with TimescaleDB and DynamoDB Global Tables
- **Kubernetes Multi-Cluster** setup with Istio service mesh
- **Automated Failover** procedures and DR testing
- **Cost Optimization** strategies
- **Compliance** with GDPR and data residency requirements

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│          Global Traffic Manager (Route 53)              │
│        Geoproximity + Health Check Based Routing        │
└─────────────────────────────────────────────────────────┘
              │                  │                  │
   ┌──────────┴────────┐  ┌─────┴────────┐  ┌─────┴─────────┐
   │  Region: US-EAST  │  │ Region: EU-W  │  │ Region: APAC  │
   │  (North America)  │  │   (Europe)    │  │ (Asia-Pacific)│
   └───────────────────┘  └───────────────┘  └───────────────┘
```

## Directory Structure

```
multi-region-deployment/
├── terraform/                    # Infrastructure as Code
│   ├── global/                  # Global resources (DNS, CDN, IAM)
│   ├── us-east-1/              # North America region
│   ├── eu-west-1/              # Europe region
│   ├── ap-northeast-1/         # Asia-Pacific region
│   └── modules/                # Reusable Terraform modules
├── kubernetes/                  # Kubernetes manifests
│   ├── global/                 # Global resources (cert-manager, Istio)
│   ├── applications/           # Application deployments
│   └── kustomize/             # Environment overlays
├── database/                    # Database setup and replication
├── monitoring/                  # Prometheus, Grafana, alerting
├── scripts/                    # Deployment and operational scripts
├── traffic-management/         # DNS, CDN, load balancing configs
└── dr/                        # Disaster recovery procedures

```

## Prerequisites

- **Terraform** >= 1.5.0
- **kubectl** >= 1.27.0
- **AWS CLI** >= 2.13.0
- **Helm** >= 3.12.0
- **PostgreSQL Client** >= 14.0
- AWS account with admin access to multiple regions

## Quick Start

### 1. Clone and Configure

```bash
cd examples/multi-region-deployment

# Copy and configure environment variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your settings
```

### 2. Deploy Global Resources

```bash
cd terraform/global
terraform init
terraform plan
terraform apply

# Note the outputs (Route 53 Zone ID, CloudFront distribution ID)
```

### 3. Deploy Regional Infrastructure

```bash
# Deploy US-EAST-1
cd ../us-east-1
terraform init
terraform plan -var-file=../terraform.tfvars
terraform apply -var-file=../terraform.tfvars

# Deploy EU-WEST-1
cd ../eu-west-1
terraform init
terraform plan -var-file=../terraform.tfvars
terraform apply -var-file=../terraform.tfvars

# Deploy AP-NORTHEAST-1
cd ../ap-northeast-1
terraform init
terraform plan -var-file=../terraform.tfvars
terraform apply -var-file=../terraform.tfvars
```

### 4. Deploy Kubernetes Applications

```bash
# Configure kubectl contexts
aws eks update-kubeconfig --region us-east-1 --name vehicle-cluster-us-east-1
aws eks update-kubeconfig --region eu-west-1 --name vehicle-cluster-eu-west-1
aws eks update-kubeconfig --region ap-northeast-1 --name vehicle-cluster-ap-northeast-1

# Deploy applications to all regions
./scripts/deploy-all-regions.sh
```

### 5. Configure Database Replication

```bash
# Set up logical replication between regions
./scripts/setup-database-replication.sh
```

### 6. Verify Deployment

```bash
# Run health checks
./scripts/health-check.sh us-east-1
./scripts/health-check.sh eu-west-1
./scripts/health-check.sh ap-northeast-1

# Test failover
./scripts/test-failover.sh
```

## Deployment Phases

### Phase 1: Foundation (Weeks 1-2)
- Deploy global DNS and CDN
- Provision regional VPCs and networking
- Deploy Kubernetes clusters
- Set up basic monitoring

### Phase 2: Data Layer (Weeks 3-4)
- Deploy TimescaleDB clusters
- Configure DynamoDB Global Tables
- Set up S3 replication
- Implement Redis caching

### Phase 3: Applications (Weeks 5-6)
- Deploy microservices to all regions
- Configure Istio service mesh
- Implement API gateway
- Deploy IoT Hub connections

### Phase 4: Observability (Week 7)
- Deploy Prometheus federation
- Configure Grafana dashboards
- Set up alerting rules
- Implement distributed tracing

### Phase 5: DR & Testing (Week 8)
- Implement automated failover
- Conduct DR drills
- Load testing
- Chaos engineering tests

## Configuration

### terraform.tfvars.example

```hcl
# Global settings
project_name = "automotive-platform"
environment  = "production"

# Regions to deploy
regions = ["us-east-1", "eu-west-1", "ap-northeast-1"]

# DNS configuration
domain_name        = "automotive.example.com"
route53_zone_id    = "Z1234567890ABC"

# Database configuration
db_instance_class  = "db.r6g.2xlarge"
db_storage_gb      = 1000
db_backup_retention_days = 30

# Kubernetes configuration
eks_node_instance_type = "t3.xlarge"
eks_min_nodes         = 5
eks_max_nodes         = 20

# Monitoring
prometheus_retention_days = 30
grafana_admin_password    = "CHANGEME"

# Tags
tags = {
  Project     = "automotive-platform"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}
```

## Cost Estimation

Based on the default configuration:

| Component | US-EAST-1 | EU-WEST-1 | AP-NE-1 | Total/Month |
|-----------|-----------|-----------|---------|-------------|
| EKS Cluster | $73 | $73 | $73 | $219 |
| EC2 (t3.xlarge × 10) | $1,200 | $1,350 | $1,500 | $4,050 |
| RDS (db.r6g.2xlarge) | $665 | $750 | $835 | $2,250 |
| S3 Storage (100 TB) | $2,300 | $2,500 | $2,500 | $7,300 |
| Data Transfer | $1,500 | $1,200 | $1,000 | $3,700 |
| Route 53 | - | - | - | $51 |
| CloudFront | - | - | - | $500 |
| **Total** | **$5,738** | **$5,873** | **$5,908** | **$18,070** |

*For 10,000 vehicles = $1.81 per vehicle per month*

## Optimization Strategies

1. **Reserved Instances**: Save 30-40% on EC2 and RDS
2. **Spot Instances**: Use for batch workloads (analytics)
3. **S3 Lifecycle**: Archive old data to Glacier
4. **Data Transfer**: Minimize cross-region traffic with caching
5. **Auto-Scaling**: Scale down during off-peak hours

## Disaster Recovery

### RTO/RPO Targets

| Service | RTO | RPO | Failover Type |
|---------|-----|-----|---------------|
| API Gateway | < 1 min | < 10 sec | Automatic |
| Telemetry Ingestion | < 2 min | < 30 sec | Automatic |
| Database | < 5 min | < 1 min | Manual/Auto |
| Analytics | < 15 min | < 5 min | Manual |

### DR Procedures

```bash
# Automated failover
./scripts/failover-to-region.sh eu-west-1

# Failback to primary
./scripts/failback-to-primary.sh us-east-1

# DR drill (non-disruptive)
./scripts/dr-drill.sh
```

## Monitoring

Access monitoring dashboards:

- **Prometheus**: https://prometheus.automotive.example.com
- **Grafana**: https://grafana.automotive.example.com
- **Kibana**: https://kibana.automotive.example.com

Key metrics monitored:
- API latency (p50, p95, p99) per region
- Database replication lag
- S3 replication delay
- Pod health and resource usage
- Cost per region

## Compliance

### GDPR
- EU data stored in eu-west-1 only
- Data subject rights API implemented
- Audit logging enabled
- Encryption at rest and in transit

### Data Residency
- Regional data storage enforced
- Cross-border transfers logged
- Compliance reports generated monthly

## Troubleshooting

### High Replication Lag

```bash
# Check replication status
./scripts/check-replication-lag.sh

# Restart replication
./scripts/restart-replication.sh eu-west-1
```

### Failed Health Checks

```bash
# Detailed health check
./scripts/health-check.sh us-east-1 --verbose

# Check logs
kubectl --context=us-east-1 logs -l app=vehicle-gateway --tail=100
```

### Cost Overruns

```bash
# Generate cost report
python3 scripts/cost-report.py --region all --days 30

# Identify cost anomalies
python3 scripts/cost-anomaly-detection.py
```

## Security

- **Encryption**: TLS 1.3 for all traffic, AES-256 for data at rest
- **Authentication**: OAuth 2.0 + mTLS for service-to-service
- **Network**: Private subnets, security groups, NACLs
- **Secrets**: AWS Secrets Manager, encrypted at rest
- **IAM**: Least privilege, service-specific roles
- **Audit**: All actions logged to CloudTrail and audit_log table

## Contributing

Improvements and contributions welcome! Please:
1. Test changes in a non-production environment
2. Update documentation
3. Follow Terraform and Kubernetes best practices
4. Submit PR with detailed description

## Support

For issues or questions:
- GitHub Issues: https://github.com/example/automotive-claude-code-agents/issues
- Documentation: ../docs/MULTI_REGION_ARCHITECTURE.md
- Contact: engineering@example.com

## License

MIT License - See LICENSE file for details

---

**Version**: 1.0.0
**Last Updated**: 2026-03-19
**Maintainers**: Cloud Infrastructure Team

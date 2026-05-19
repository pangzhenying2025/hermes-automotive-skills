# Multi-Region Deployment Strategy

**Version**: 1.0.0
**Author**: DevOps Engineer
**Last Updated**: 2026-03-19

## Overview

This document outlines strategies for deploying vehicle fleet infrastructure across multiple geographic regions for high availability, disaster recovery, and global performance optimization.

## Architecture Patterns

### 1. Active-Active (Multi-Master)

**Description**: All regions actively serve traffic with bi-directional data replication.

```
                    ┌─────────────────────┐
                    │   Global Traffic    │
                    │      Manager        │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼──────┐      ┌────────▼──────┐      ┌───────▼──────┐
│  US-EAST-1   │◄────►│   EU-WEST-1   │◄────►│  AP-SOUTH-1  │
│  (Active)    │      │   (Active)    │      │   (Active)   │
│              │      │               │      │              │
│ - K8s Cluster│      │ - K8s Cluster │      │ - K8s Cluster│
│ - Database   │      │ - Database    │      │ - Database   │
│ - Storage    │      │ - Storage     │      │ - Storage    │
└──────────────┘      └───────────────┘      └──────────────┘
```

**Characteristics**:
- **RTO**: < 1 minute (automatic failover)
- **RPO**: < 15 seconds (sync replication)
- **Cost**: High (3x resources)
- **Complexity**: High (conflict resolution required)

**Use Cases**:
- Global applications requiring low latency worldwide
- Mission-critical systems with zero downtime tolerance
- Regulatory requirements for data sovereignty

**Implementation**:

```hcl
# Terraform: Multi-region active-active
module "us_east_1" {
  source = "../modules/region"
  region = "us-east-1"
  active = true
  replicate_to = ["eu-west-1", "ap-south-1"]
}

module "eu_west_1" {
  source = "../modules/region"
  region = "eu-west-1"
  active = true
  replicate_to = ["us-east-1", "ap-south-1"]
}

module "ap_south_1" {
  source = "../modules/region"
  region = "ap-south-1"
  active = true
  replicate_to = ["us-east-1", "eu-west-1"]
}

# Global Traffic Manager (AWS Route 53)
resource "aws_route53_health_check" "us_east_1" {
  fqdn              = module.us_east_1.endpoint
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
}

resource "aws_route53_record" "global" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.vehiclefleet.com"
  type    = "A"

  geolocation_routing_policy {
    continent = "NA"
  }

  alias {
    name                   = module.us_east_1.endpoint
    zone_id                = module.us_east_1.zone_id
    evaluate_target_health = true
  }

  set_identifier = "US-EAST-1"
}
```

**Database Replication**:

```yaml
# Cosmos DB multi-region write
resource "azurerm_cosmosdb_account" "main" {
  enable_multiple_write_locations = true
  enable_automatic_failover        = true

  geo_location {
    location          = "eastus"
    failover_priority = 0
  }

  geo_location {
    location          = "westeurope"
    failover_priority = 1
  }

  geo_location {
    location          = "southeastasia"
    failover_priority = 2
  }

  consistency_policy {
    consistency_level       = "Session"  # Balance between consistency and performance
  }
}
```

### 2. Active-Passive (Primary-Secondary)

**Description**: Primary region serves all traffic; secondary region is hot standby.

```
                    ┌─────────────────────┐
                    │   Global Traffic    │
                    │      Manager        │
                    └──────────┬──────────┘
                               │
                        ┌──────▼───────┐
                        │  US-EAST-1   │
                        │  (Primary)   │
                        │              │
                        │ - K8s Cluster│
                        │ - Database   │
                        │ - Storage    │
                        └──────┬───────┘
                               │ Async Replication
                        ┌──────▼───────┐
                        │  EU-WEST-1   │
                        │  (Secondary) │
                        │              │
                        │ - K8s Cluster│
                        │ - Database   │
                        │ - Storage    │
                        └──────────────┘
```

**Characteristics**:
- **RTO**: 5-15 minutes (manual or automated failover)
- **RPO**: 1-5 minutes (async replication lag)
- **Cost**: Medium (1.5-2x resources)
- **Complexity**: Medium (failover automation)

**Use Cases**:
- Disaster recovery scenarios
- Cost-optimized high availability
- Regional compliance with DR requirements

**Implementation**:

```hcl
# Primary region (full capacity)
module "primary" {
  source = "../modules/region"
  region = "us-east-1"
  active = true
  node_count = 10
  database_replicas = 3
}

# Secondary region (reduced capacity)
module "secondary" {
  source = "../modules/region"
  region = "eu-west-1"
  active = false
  node_count = 3  # Warm standby, scale on failover
  database_replicas = 1
}

# Failover automation with Lambda
resource "aws_lambda_function" "failover" {
  function_name = "vehicle-fleet-failover"
  runtime       = "python3.11"
  handler       = "failover.handler"
  role          = aws_iam_role.failover.arn

  environment {
    variables = {
      PRIMARY_REGION   = "us-east-1"
      SECONDARY_REGION = "eu-west-1"
      ROUTE53_ZONE_ID  = aws_route53_zone.main.zone_id
    }
  }
}

# CloudWatch alarm triggers failover
resource "aws_cloudwatch_metric_alarm" "primary_down" {
  alarm_name          = "vehicle-fleet-primary-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1

  alarm_actions = [aws_sns_topic.failover.arn]
}
```

**Database Replication**:

```yaml
# AWS RDS Cross-Region Read Replica
resource "aws_db_instance" "primary" {
  identifier          = "vehicle-fleet-primary"
  engine              = "postgres"
  instance_class      = "db.r6g.xlarge"
  multi_az            = true
  backup_retention_period = 7
}

resource "aws_db_instance" "secondary" {
  identifier              = "vehicle-fleet-secondary"
  replicate_source_db     = aws_db_instance.primary.arn
  instance_class          = "db.r6g.large"
  auto_minor_version_upgrade = true
}
```

### 3. Active-Active-Standby (Hybrid)

**Description**: Two active regions serve traffic; third region is cold standby for DR.

```
                    ┌─────────────────────┐
                    │   Global Traffic    │
                    │      Manager        │
                    └──────────┬──────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼──────┐      ┌────────▼──────┐      ┌───────▼──────┐
│  US-EAST-1   │◄────►│   EU-WEST-1   │      │  AP-SOUTH-1  │
│  (Active)    │      │   (Active)    │      │  (Standby)   │
│              │      │               │      │              │
│ - K8s Cluster│      │ - K8s Cluster │      │ - Backup     │
│ - Database   │      │ - Database    │      │ - No compute │
│ - Storage    │      │ - Storage     │      │              │
└──────────────┘      └───────────────┘      └──────────────┘
```

**Characteristics**:
- **RTO**: < 5 minutes (active regions), < 30 minutes (standby)
- **RPO**: < 1 minute (active regions), < 15 minutes (standby)
- **Cost**: Medium-High (2.2-2.5x resources)
- **Complexity**: Medium

**Use Cases**:
- Balance between performance and cost
- Geographic distribution with DR protection
- Compliance requiring multi-region presence

## Traffic Distribution Strategies

### 1. Geographic Routing

Route users to nearest region based on location.

```hcl
# AWS Route 53 Geolocation Routing
resource "aws_route53_record" "us" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.vehiclefleet.com"
  type    = "A"

  geolocation_routing_policy {
    continent = "NA"
  }

  alias {
    name                   = module.us_east_1.alb_dns_name
    zone_id                = module.us_east_1.alb_zone_id
    evaluate_target_health = true
  }

  set_identifier = "US"
}

resource "aws_route53_record" "eu" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.vehiclefleet.com"
  type    = "A"

  geolocation_routing_policy {
    continent = "EU"
  }

  alias {
    name                   = module.eu_west_1.alb_dns_name
    zone_id                = module.eu_west_1.alb_zone_id
    evaluate_target_health = true
  }

  set_identifier = "EU"
}
```

### 2. Latency-Based Routing

Route users to region with lowest latency.

```hcl
# AWS Route 53 Latency Routing
resource "aws_route53_record" "us_latency" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.vehiclefleet.com"
  type    = "A"

  latency_routing_policy {
    region = "us-east-1"
  }

  alias {
    name                   = module.us_east_1.alb_dns_name
    zone_id                = module.us_east_1.alb_zone_id
    evaluate_target_health = true
  }

  set_identifier = "US-EAST-1"
}
```

### 3. Weighted Routing

Distribute traffic by percentage (useful for migrations).

```hcl
# AWS Route 53 Weighted Routing
resource "aws_route53_record" "us_weighted" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.vehiclefleet.com"
  type    = "A"

  weighted_routing_policy {
    weight = 70  # 70% of traffic
  }

  alias {
    name                   = module.us_east_1.alb_dns_name
    zone_id                = module.us_east_1.alb_zone_id
    evaluate_target_health = true
  }

  set_identifier = "US-EAST-1-WEIGHTED"
}

resource "aws_route53_record" "eu_weighted" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.vehiclefleet.com"
  type    = "A"

  weighted_routing_policy {
    weight = 30  # 30% of traffic
  }

  alias {
    name                   = module.eu_west_1.alb_dns_name
    zone_id                = module.eu_west_1.alb_zone_id
    evaluate_target_health = true
  }

  set_identifier = "EU-WEST-1-WEIGHTED"
}
```

## Data Replication Strategies

### 1. Synchronous Replication

Data written to all regions before acknowledging write.

**Pros**: Zero data loss (RPO = 0)
**Cons**: Higher latency, requires low inter-region latency

**Use Cases**: Financial transactions, critical safety data

```python
# Application-level synchronous replication
async def write_telemetry(vehicle_id: str, data: dict):
    # Write to all regions in parallel
    tasks = [
        write_to_region("us-east-1", vehicle_id, data),
        write_to_region("eu-west-1", vehicle_id, data),
        write_to_region("ap-south-1", vehicle_id, data),
    ]

    # Wait for all writes to complete
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Fail if any write fails
    if any(isinstance(r, Exception) for r in results):
        raise Exception("Synchronous replication failed")

    return {"status": "success"}
```

### 2. Asynchronous Replication

Data written to primary region, replicated to secondary asynchronously.

**Pros**: Low latency, no impact on write performance
**Cons**: Potential data loss (RPO = replication lag)

**Use Cases**: Non-critical telemetry, logs, analytics data

```yaml
# Cosmos DB async replication
consistency_policy {
  consistency_level = "Eventual"  # Lowest latency
}

# Or Session consistency for better guarantees
consistency_policy {
  consistency_level = "Session"  # Read-your-writes within session
}
```

### 3. Event-Based Replication

Use event streaming (Kafka, Kinesis) for cross-region replication.

```yaml
# AWS Kinesis Cross-Region Replication
resource "aws_kinesis_stream" "us_east_1" {
  provider = aws.us_east_1
  name     = "vehicle-telemetry"
  shard_count = 10
}

resource "aws_kinesis_stream" "eu_west_1" {
  provider = aws.eu_west_1
  name     = "vehicle-telemetry"
  shard_count = 10
}

# Lambda replicates streams across regions
resource "aws_lambda_function" "kinesis_replicator" {
  function_name = "kinesis-cross-region-replicator"
  runtime       = "python3.11"
  handler       = "replicator.handler"

  environment {
    variables = {
      SOURCE_STREAM      = aws_kinesis_stream.us_east_1.name
      DESTINATION_STREAM = aws_kinesis_stream.eu_west_1.name
      DESTINATION_REGION = "eu-west-1"
    }
  }
}
```

## Disaster Recovery Runbook

### Scenario 1: Primary Region Outage

**Detection**: Health checks fail for > 3 minutes

**Automated Response**:
1. CloudWatch alarm triggers SNS notification
2. Lambda function updates Route 53 to point to secondary region
3. Secondary region auto-scales to handle full load
4. PagerDuty alerts on-call engineer

**Manual Steps**:
1. Verify failover completed successfully
2. Check application logs for errors
3. Validate data consistency
4. Communicate status to stakeholders

**Rollback**:
1. Verify primary region is healthy
2. Update Route 53 to route 10% traffic to primary
3. Monitor for errors
4. Gradually increase traffic to primary (10% → 50% → 100%)

### Scenario 2: Database Corruption

**Detection**: Application reports data inconsistencies

**Response**:
1. Immediately stop writes to corrupted database
2. Identify last known good backup
3. Restore from backup to new database instance
4. Validate data integrity
5. Update application to point to restored database
6. Resume writes

**Prevention**:
- Point-in-time recovery enabled
- Automated backups every 6 hours
- Backup retention: 30 days
- Cross-region backup replication

### Scenario 3: Complete Cloud Provider Outage

**Detection**: All regions in one cloud unavailable

**Response**:
1. Trigger multi-cloud failover
2. Update DNS to point to alternate cloud provider
3. Restore latest backup to alternate cloud
4. Scale up alternate cloud resources
5. Validate functionality

**Requirements**:
- Maintain infrastructure in 2+ cloud providers
- Automated backup sync across clouds
- Regular multi-cloud DR drills

## Cost Optimization

### 1. Right-Size Standby Regions

Run standby regions at reduced capacity:

```hcl
# Production region
module "prod" {
  node_count = 10
  node_size  = "xlarge"
}

# Standby region (30% capacity)
module "standby" {
  node_count = 3
  node_size  = "large"

  # Scale up on failover
  autoscaling_enabled = true
  max_node_count     = 10
}
```

**Savings**: ~60% on standby region costs

### 2. Use Spot/Preemptible Instances

For non-critical workloads in standby regions:

```yaml
# Spot instances for batch processing
node_pools:
  - name: spot-batch
    instance_type: t3.xlarge
    spot_instance: true
    spot_max_price: 0.05  # 70% discount vs on-demand
    min_nodes: 0
    max_nodes: 20
```

**Savings**: ~70% on compute costs

### 3. Storage Tiering

Move old data to cheaper storage classes:

```hcl
# S3 lifecycle policies
resource "aws_s3_bucket_lifecycle_configuration" "telemetry" {
  bucket = aws_s3_bucket.telemetry.id

  rule {
    id     = "archive-old-data"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"  # 50% cheaper
    }

    transition {
      days          = 90
      storage_class = "GLACIER"  # 80% cheaper
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"  # 95% cheaper
    }
  }
}
```

**Savings**: ~70% on storage costs

### 4. Reserved Capacity

Commit to 1-3 year reservations for predictable workloads:

| Commitment | AWS Discount | Azure Discount | GCP Discount |
|------------|-------------|---------------|--------------|
| **1 Year** | 30-40% | 30-40% | 25-35% |
| **3 Year** | 60-65% | 60-65% | 55-60% |

## Monitoring & Observability

### Key Metrics

```yaml
# Prometheus metrics
- name: region_availability
  query: up{job="kubernetes-nodes",region=~".*"}
  alert_threshold: < 0.99

- name: cross_region_replication_lag
  query: replication_lag_seconds{source_region="us-east-1",target_region="eu-west-1"}
  alert_threshold: > 300

- name: failover_test_success_rate
  query: rate(failover_test_success[7d])
  alert_threshold: < 0.95
```

### Dashboards

Create Grafana dashboards showing:
- Regional health status
- Traffic distribution by region
- Replication lag (all region pairs)
- Failover readiness score
- Cost per region

## Testing Strategy

### 1. Automated Failover Tests

Run weekly:

```bash
#!/bin/bash
# Automated failover test
# Runs every Sunday at 2 AM

echo "Starting failover test..."

# 1. Simulate primary region failure
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://failover-config.json

# 2. Wait for DNS propagation
sleep 60

# 3. Validate traffic routing to secondary
curl -f https://api.vehiclefleet.com/health || exit 1

# 4. Run smoke tests
pytest tests/smoke_tests.py || exit 1

# 5. Restore primary
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://restore-config.json

echo "Failover test completed successfully"
```

### 2. Chaos Engineering

Use tools like Chaos Monkey to randomly terminate resources:

```yaml
# Chaos Mesh experiment
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: region-partition
spec:
  action: partition
  mode: one
  selector:
    namespaces:
      - production
    labelSelectors:
      region: us-east-1
  direction: both
  duration: 5m
```

### 3. GameDays

Quarterly exercise simulating major outages:
- Complete region failure
- Database corruption
- DDoS attack
- Network partition

**Participants**: Engineering, SRE, Product, Support
**Duration**: 4 hours
**Outcome**: Documented lessons learned, runbook updates

## Compliance & Data Sovereignty

### GDPR Requirements

```hcl
# Keep EU user data in EU regions only
resource "aws_dynamodb_global_table" "users" {
  name = "users"

  replica {
    region_name = "eu-west-1"
  }

  replica {
    region_name = "eu-central-1"
  }

  # Data residency enforcement
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}

# Lambda ensures EU data stays in EU
resource "aws_lambda_function" "data_residency_enforcer" {
  function_name = "data-residency-enforcer"
  runtime       = "python3.11"

  environment {
    variables = {
      ALLOWED_REGIONS = "eu-west-1,eu-central-1"
    }
  }
}
```

### Data Classification

| Classification | Replication | Retention | Regions |
|---------------|-------------|-----------|---------|
| **Critical** | Sync, multi-region | 7 years | All |
| **Sensitive** | Async, in-region | 3 years | GDPR-compliant |
| **Public** | CDN cached | 1 year | All |
| **Ephemeral** | No replication | 30 days | Single region |

## References

- [AWS Multi-Region Architecture](https://aws.amazon.com/solutions/implementations/multi-region-application-architecture/)
- [Azure Multi-Region Design](https://docs.microsoft.com/en-us/azure/architecture/guide/resilience/multi-region)
- [GCP Disaster Recovery Planning](https://cloud.google.com/architecture/dr-scenarios-planning-guide)
- [Cosmos DB Global Distribution](https://docs.microsoft.com/en-us/azure/cosmos-db/distribute-data-globally)

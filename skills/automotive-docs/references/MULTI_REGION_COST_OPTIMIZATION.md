# Multi-Region Cost Optimization Guide

## Executive Summary

This guide provides strategies and tactics for optimizing costs in multi-region automotive cloud deployments. Target: **30-40% cost reduction** through Reserved Instances, Spot instances, data transfer optimization, and resource right-sizing.

**Baseline Cost** (10,000 vehicles, 3 regions): **$21,815/month**
**Optimized Cost Target**: **$13,000-15,000/month**
**Cost per Vehicle**: **$1.30-1.50/month** (down from $2.18)

---

## Table of Contents

1. [Cost Breakdown Analysis](#1-cost-breakdown-analysis)
2. [Compute Optimization](#2-compute-optimization)
3. [Database Optimization](#3-database-optimization)
4. [Storage Optimization](#4-storage-optimization)
5. [Data Transfer Optimization](#5-data-transfer-optimization)
6. [Monitoring and Alerting](#6-monitoring-and-alerting)
7. [Cost Allocation and Chargeback](#7-cost-allocation-and-chargeback)
8. [Continuous Optimization](#8-continuous-optimization)

---

## 1. Cost Breakdown Analysis

### Current Monthly Costs (Active-Active, 3 Regions)

**US-EAST-1 (Primary, 40% of traffic)**:
```
Compute (EKS):
- Control Plane: $73/month
- Worker Nodes (20 × t3.xlarge @ $0.1664/hr): $2,395/month
- Spot Nodes (5 × r6g.xlarge @ 30% savings): $380/month

Database (RDS):
- Primary (db.r6g.2xlarge): $665/month
- Read Replicas (2 × db.r6g.2xlarge): $1,330/month

Storage (S3):
- Standard Storage (100 TB @ $0.023/GB): $2,300/month
- Requests (100M PUT @ $0.005/1000): $500/month

Data Transfer:
- Out to Internet (50 TB @ $0.09/GB): $4,500/month
- Cross-Region (20 TB @ $0.02/GB): $400/month

Other:
- IoT Hub (10,000 devices): $500/month
- CloudWatch Logs (1 TB): $500/month

Subtotal US-EAST-1: $13,543/month
```

**EU-WEST-1 (Active, 35% of traffic)**:
```
Compute: $2,700/month (similar to US-EAST-1)
Database: $2,250/month
Storage: $2,000/month
Data Transfer: $3,800/month
Other: $600/month

Subtotal EU-WEST-1: $11,350/month
```

**AP-NORTHEAST-1 (Passive DR, minimal traffic)**:
```
Compute (2 nodes only): $300/month
Database (Read Replica): $835/month
Storage (50 TB): $1,250/month
Data Transfer: $200/month

Subtotal AP-NORTHEAST-1: $2,585/month
```

**Global Resources**:
```
Route 53: $51/month
CloudFront: $500/month
DynamoDB Global Tables: $300/month

Subtotal Global: $851/month
```

**TOTAL BASELINE: $28,329/month**

### Cost Drivers

| Category | Monthly Cost | % of Total |
|----------|-------------|------------|
| Compute (EC2/EKS) | $8,000 | 28% |
| Database (RDS) | $5,080 | 18% |
| Data Transfer | $8,900 | 31% |
| Storage (S3) | $5,550 | 20% |
| Other (IoT, Logs, etc.) | $800 | 3% |
| **TOTAL** | **$28,329** | **100%** |

**Key Insight**: Data transfer is the largest cost driver (31%), followed by compute (28%).

---

## 2. Compute Optimization

### 2.1 Reserved Instances (30-40% savings)

**Strategy**: Commit to 1-year or 3-year Reserved Instances for predictable workloads.

**Current**: On-demand t3.xlarge = $0.1664/hr × 20 nodes × 730 hr = $2,395/month
**With 1-yr RI (no upfront)**: $0.107/hr × 20 × 730 = $1,562/month
**Savings**: $833/month (35% reduction)

**Implementation**:
```bash
# Purchase Reserved Instances via AWS CLI
aws ec2 purchase-reserved-instances-offering \
  --region us-east-1 \
  --reserved-instances-offering-id <offering-id> \
  --instance-count 20 \
  --payment-option NoUpfront
```

**Recommendation**:
- 1-year No Upfront for production workloads (flexibility)
- 3-year Partial Upfront for stable long-term workloads (max savings)

### 2.2 Compute Savings Plans (up to 66% savings)

**Alternative to RIs**: Flexible commitment to compute usage (any instance type/region).

**Current**: $8,000/month on-demand
**With Savings Plan**: $5,440/month (32% savings)

**Implementation**:
```bash
# View Savings Plans recommendations
aws ce get-savings-plans-purchase-recommendation \
  --lookback-period-in-days 30 \
  --term-in-years 1 \
  --payment-option NO_UPFRONT \
  --savings-plans-type COMPUTE_SP
```

### 2.3 Spot Instances for Batch Workloads (up to 90% savings)

**Use Case**: Analytics, batch processing, non-critical workloads

**Current**: r6g.xlarge on-demand = $0.1792/hr
**Spot Price**: ~$0.054/hr (70% savings)

**Implementation**:
```yaml
# EKS Spot Node Group
nodeGroups:
  - name: analytics-spot
    instanceTypes:
      - r6g.xlarge
      - r6g.2xlarge
      - r5.xlarge
    desiredCapacity: 5
    minSize: 0
    maxSize: 20
    instancesDistribution:
      onDemandBaseCapacity: 0
      onDemandPercentageAboveBaseCapacity: 0
      spotAllocationStrategy: "capacity-optimized"
    labels:
      workload-type: batch
      lifecycle: spot
```

**Estimated Savings**: $1,000/month (analytics workloads moved to spot)

### 2.4 Right-Sizing (10-20% savings)

**Analysis**: Identify over-provisioned instances using CloudWatch metrics.

**Example**:
- Current: t3.xlarge (4 vCPU, 16 GB RAM, avg usage 40% CPU, 60% RAM)
- Right-sized: t3.large (2 vCPU, 8 GB RAM, $0.0832/hr)
- **Savings**: 50% per instance

**Tools**:
```bash
# AWS Cost Explorer Right Sizing recommendations
aws ce get-rightsizing-recommendation \
  --service "AmazonEC2" \
  --page-size 100
```

**Estimated Savings**: $1,200/month (right-size 15 instances)

### 2.5 Auto-Scaling Optimization

**Strategy**: Scale down during off-peak hours (nights, weekends).

**Current**: 20 nodes × 24/7
**Optimized**:
- Peak hours (8am-8pm): 20 nodes
- Off-peak hours: 10 nodes
- Weekends: 8 nodes

**Effective Usage**: 18 nodes average (vs 20 baseline)
**Savings**: $240/month (10% reduction)

**Implementation**:
```yaml
# Kubernetes CronJob for scheduled scaling
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-down-offpeak
spec:
  schedule: "0 20 * * *"  # 8 PM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scaler
            image: bitnami/kubectl
            command:
            - kubectl
            - scale
            - deployment
            - vehicle-gateway
            - --replicas=5
```

### Summary: Compute Optimization

| Tactic | Monthly Savings | Annual Savings |
|--------|----------------|----------------|
| Reserved Instances | $833 | $10,000 |
| Spot Instances | $1,000 | $12,000 |
| Right-Sizing | $1,200 | $14,400 |
| Auto-Scaling | $240 | $2,880 |
| **Total Compute** | **$3,273** | **$39,276** |

**Compute Cost**: $8,000 → $4,727 (41% reduction)

---

## 3. Database Optimization

### 3.1 Reserved Database Instances

**Current**: db.r6g.2xlarge on-demand = $0.912/hr = $665/month
**With 1-yr RI (no upfront)**: $0.584/hr = $426/month
**Savings per instance**: $239/month (36% reduction)

**Total DB Instances**: 1 primary + 2 replicas (US), 1 primary + 2 replicas (EU), 1 replica (APAC) = 7 instances
**Total Savings**: $1,673/month

### 3.2 Read Replica Optimization

**Analysis**: Monitor read vs write traffic. Reduce replicas if read traffic < 30% of total.

**Current**: 2 read replicas per active region (4 total)
**Optimized**: 1 read replica per active region (2 total)
**Savings**: $1,330/month (2 replicas × $665)

**Monitoring Query**:
```sql
-- Check read replica utilization
SELECT
    datname,
    SUM(blks_read) AS blocks_read,
    SUM(blks_hit) AS blocks_cached,
    ROUND(100.0 * SUM(blks_hit) / NULLIF(SUM(blks_hit) + SUM(blks_read), 0), 2) AS cache_hit_ratio
FROM pg_stat_database
GROUP BY datname;
```

### 3.3 Database Storage Optimization

**Strategy**: Enable compression, archive old data, use storage tiers.

**TimescaleDB Compression**:
```sql
-- Enable compression (90% storage reduction)
ALTER TABLE vehicle_telemetry SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'vehicle_id',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('vehicle_telemetry', INTERVAL '7 days');
```

**Impact**:
- Current storage: 1 TB uncompressed
- Compressed storage: 100 GB (90% reduction)
- Storage cost reduction: $20/month per TB

### 3.4 Query Optimization

**Inefficient Query Example**:
```sql
-- BAD: Full table scan
SELECT AVG(battery_soc) FROM vehicle_telemetry
WHERE time > NOW() - INTERVAL '30 days';
```

**Optimized**:
```sql
-- GOOD: Use continuous aggregate
SELECT AVG(avg_soc) FROM vehicle_telemetry_1h
WHERE bucket > NOW() - INTERVAL '30 days';
```

**Performance**: 10x faster, 90% less I/O
**Cost Impact**: Lower RDS I/O costs, smaller instance possible

### 3.5 Backup Optimization

**Current**: 30-day backup retention
**Optimized**: 7-day frequent backups + monthly snapshot to S3 Glacier

**Savings**: $150/month

### Summary: Database Optimization

| Tactic | Monthly Savings | Annual Savings |
|--------|----------------|----------------|
| Reserved Instances | $1,673 | $20,076 |
| Reduce Read Replicas | $1,330 | $15,960 |
| Storage Compression | $180 | $2,160 |
| Backup Optimization | $150 | $1,800 |
| **Total Database** | **$3,333** | **$39,996** |

**Database Cost**: $5,080 → $1,747 (66% reduction)

---

## 4. Storage Optimization

### 4.1 S3 Storage Tiering

**Strategy**: Move infrequently accessed data to lower-cost storage classes.

**Storage Classes**:
- S3 Standard: $0.023/GB (frequent access)
- S3 Intelligent-Tiering: $0.0125/GB (automatic tiering)
- S3 Glacier: $0.004/GB (archival)
- S3 Glacier Deep Archive: $0.00099/GB (long-term archival)

**Current**: 100 TB S3 Standard = $2,300/month
**Optimized**:
- 20 TB Standard (recent OTA updates): $460/month
- 50 TB Intelligent-Tiering (older OTA): $640/month
- 30 TB Glacier (archived OTA): $120/month
**New Total**: $1,220/month
**Savings**: $1,080/month (47% reduction)

**Lifecycle Policy**:
```json
{
  "Rules": [
    {
      "Id": "ota-lifecycle",
      "Status": "Enabled",
      "Filter": { "Prefix": "ota/" },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "INTELLIGENT_TIERING"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        },
        {
          "Days": 365,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ],
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}
```

### 4.2 S3 Request Optimization

**Current**: 100M PUT requests/month @ $0.005/1000 = $500/month

**Strategy**: Batch uploads, reduce redundant writes

**Optimized**: 50M requests = $250/month
**Savings**: $250/month

### 4.3 CloudFront Caching

**Strategy**: Increase CDN cache hit ratio to reduce S3 requests and data transfer.

**Current Cache Hit Ratio**: 75%
**Optimized**: 95% (better cache headers, longer TTLs)

**Impact**:
- S3 requests: 100M → 30M (70% reduction)
- S3 data transfer: 50 TB → 15 TB (70% reduction)
**Savings**: $3,150/month (requests + transfer)

### Summary: Storage Optimization

| Tactic | Monthly Savings | Annual Savings |
|--------|----------------|----------------|
| S3 Tiering | $1,080 | $12,960 |
| Request Optimization | $250 | $3,000 |
| CloudFront Caching | $3,150 | $37,800 |
| **Total Storage** | **$4,480** | **$53,760** |

**Storage Cost**: $5,550 → $1,070 (81% reduction)

---

## 5. Data Transfer Optimization

### 5.1 Regional Data Locality

**Strategy**: Keep data in the same region where it's used.

**Current**:
- Cross-region transfers: 20 TB/month @ $0.02/GB = $400/month
- Internet egress: 50 TB/month @ $0.09/GB = $4,500/month

**Optimization**:
- Use regional endpoints (API Gateway, S3)
- Cache frequently accessed data locally
- Minimize cross-region queries

**Implementation**:
```go
// Route vehicles to regional endpoints
func getRegionalEndpoint(vehicleLocation Location) string {
    if vehicleLocation.Latitude > 25 && vehicleLocation.Longitude < -60 {
        return "https://api-us-east-1.automotive.example.com"
    } else if vehicleLocation.Latitude > 35 && vehicleLocation.Longitude > -10 && vehicleLocation.Longitude < 50 {
        return "https://api-eu-west-1.automotive.example.com"
    } else {
        return "https://api-ap-northeast-1.automotive.example.com"
    }
}
```

**Savings**: $1,800/month (reduce cross-region traffic by 90%)

### 5.2 Data Compression

**Strategy**: Compress data before transfer (gzip, zstd).

**Current**: 50 TB uncompressed transfers
**Compressed**: 15 TB (70% compression ratio for telemetry JSON)
**Savings**: $3,150/month (35 TB × $0.09/GB)

**Implementation**:
```go
// Compress telemetry data before upload
func uploadTelemetry(data TelemetryData) error {
    var buf bytes.Buffer
    gzipWriter := gzip.NewWriter(&buf)
    json.NewEncoder(gzipWriter).Encode(data)
    gzipWriter.Close()

    return s3Client.PutObject(&s3.PutObjectInput{
        Bucket:          aws.String("vehicle-telemetry"),
        Key:             aws.String(fmt.Sprintf("telemetry/%s.json.gz", data.VehicleID)),
        Body:            bytes.NewReader(buf.Bytes()),
        ContentEncoding: aws.String("gzip"),
    })
}
```

### 5.3 VPC Peering for Cross-Region

**Strategy**: Use VPC peering instead of public internet for region-to-region traffic.

**Current**: Cross-region via internet = $0.02/GB
**With VPC Peering**: $0.01/GB
**Savings**: $200/month (on 20 TB cross-region)

### 5.4 CloudFront for OTA Updates

**Strategy**: Distribute OTA updates via CloudFront instead of direct S3.

**Current**: S3 direct = $0.09/GB egress
**CloudFront**: $0.085/GB first 10 TB, $0.05/GB next 40 TB
**Savings**: $1,500/month

### Summary: Data Transfer Optimization

| Tactic | Monthly Savings | Annual Savings |
|--------|----------------|----------------|
| Regional Locality | $1,800 | $21,600 |
| Data Compression | $3,150 | $37,800 |
| VPC Peering | $200 | $2,400 |
| CloudFront for OTA | $1,500 | $18,000 |
| **Total Data Transfer** | **$6,650** | **$79,800** |

**Data Transfer Cost**: $8,900 → $2,250 (75% reduction)

---

## 6. Monitoring and Alerting

### 6.1 AWS Cost Anomaly Detection

**Setup**:
```terraform
resource "aws_ce_anomaly_monitor" "cost_monitor" {
  name              = "automotive-platform-cost-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "cost_alerts" {
  name      = "automotive-cost-alerts"
  frequency = "DAILY"
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["100"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}
```

### 6.2 Cost Allocation Tags

**Tag Strategy**:
```hcl
default_tags {
  tags = {
    Project     = "automotive-platform"
    Environment = "production"
    CostCenter  = "engineering"
    Region      = "us-east-1"
    Component   = "compute"
  }
}
```

### 6.3 Budget Alerts

```terraform
resource "aws_budgets_budget" "monthly" {
  name              = "automotive-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "15000"
  limit_unit        = "USD"
  time_period_start = "2026-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["finance@example.com"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["cto@example.com"]
  }
}
```

### 6.4 Cost Dashboard

**Grafana Dashboard** (using CloudWatch metrics):
```yaml
# cost-dashboard.json
{
  "title": "Multi-Region Cost Dashboard",
  "panels": [
    {
      "title": "Monthly Cost by Region",
      "targets": [
        {
          "expr": "aws_billing_estimated_charges_total{currency='USD'}",
          "legendFormat": "{{region}}"
        }
      ]
    },
    {
      "title": "Cost per Vehicle",
      "targets": [
        {
          "expr": "aws_billing_estimated_charges_total / vehicle_count_total"
        }
      ]
    },
    {
      "title": "Data Transfer Costs",
      "targets": [
        {
          "expr": "aws_data_transfer_cost_total{direction='out'}"
        }
      ]
    }
  ]
}
```

---

## 7. Cost Allocation and Chargeback

### 7.1 Cost per Vehicle Calculation

```sql
-- Calculate cost per vehicle per month
WITH monthly_costs AS (
    SELECT
        DATE_TRUNC('month', date) AS month,
        SUM(cost) AS total_cost
    FROM aws_billing_records
    WHERE date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
    GROUP BY DATE_TRUNC('month', date)
),
vehicle_counts AS (
    SELECT
        DATE_TRUNC('month', time) AS month,
        COUNT(DISTINCT vehicle_id) AS active_vehicles
    FROM vehicle_telemetry
    WHERE time >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
    GROUP BY DATE_TRUNC('month', time)
)
SELECT
    c.month,
    c.total_cost,
    v.active_vehicles,
    ROUND(c.total_cost / v.active_vehicles, 2) AS cost_per_vehicle
FROM monthly_costs c
JOIN vehicle_counts v ON c.month = v.month;
```

### 7.2 Chargeback by Customer/Fleet

```sql
-- Allocate costs by customer fleet
SELECT
    f.customer_id,
    f.fleet_name,
    COUNT(DISTINCT v.vehicle_id) AS vehicle_count,
    SUM(t.data_size_mb) AS total_data_mb,
    ROUND(SUM(t.data_size_mb) * 0.0001, 2) AS storage_cost_usd,
    ROUND(COUNT(*) * 0.0005, 2) AS compute_cost_usd,
    ROUND((SUM(t.data_size_mb) * 0.0001) + (COUNT(*) * 0.0005), 2) AS total_cost_usd
FROM fleets f
JOIN vehicles v ON v.fleet_id = f.fleet_id
JOIN vehicle_telemetry t ON t.vehicle_id = v.vehicle_id
WHERE t.time >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY f.customer_id, f.fleet_name
ORDER BY total_cost_usd DESC;
```

---

## 8. Continuous Optimization

### 8.1 Monthly Review Process

**Checklist**:
- [ ] Review Cost Explorer for anomalies
- [ ] Check Reserved Instance utilization (target > 95%)
- [ ] Analyze right-sizing recommendations
- [ ] Review data transfer patterns
- [ ] Check spot instance interruption rates
- [ ] Verify storage lifecycle policies
- [ ] Update cost forecasts

### 8.2 Quarterly Optimization Initiatives

**Q1**: Compute optimization (RIs, spot instances)
**Q2**: Storage optimization (tiering, compression)
**Q3**: Data transfer optimization (CDN, compression)
**Q4**: Architecture review (consolidation, refactoring)

### 8.3 Automation

**AWS Lambda for Cost Optimization**:
```python
# lambda-cost-optimizer.py
import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    # Stop idle dev/test instances
    instances = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Environment', 'Values': ['dev', 'test']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )

    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            # Check CPU utilization
            cloudwatch = boto3.client('cloudwatch')
            metrics = cloudwatch.get_metric_statistics(
                Namespace='AWS/EC2',
                MetricName='CPUUtilization',
                Dimensions=[{'Name': 'InstanceId', 'Value': instance['InstanceId']}],
                StartTime=datetime.now() - timedelta(days=7),
                EndTime=datetime.now(),
                Period=86400,
                Statistics=['Average']
            )

            avg_cpu = sum([m['Average'] for m in metrics['Datapoints']]) / len(metrics['Datapoints'])

            if avg_cpu < 5:  # Less than 5% CPU for a week
                print(f"Stopping idle instance: {instance['InstanceId']}")
                ec2.stop_instances(InstanceIds=[instance['InstanceId']])
```

---

## Summary: Total Cost Optimization

### Baseline vs Optimized

| Category | Baseline | Optimized | Savings | % Reduction |
|----------|----------|-----------|---------|-------------|
| Compute | $8,000 | $4,727 | $3,273 | 41% |
| Database | $5,080 | $1,747 | $3,333 | 66% |
| Storage | $5,550 | $1,070 | $4,480 | 81% |
| Data Transfer | $8,900 | $2,250 | $6,650 | 75% |
| Other | $800 | $800 | $0 | 0% |
| **TOTAL** | **$28,329** | **$10,594** | **$17,735** | **63%** |

### Cost per Vehicle

- **Baseline**: $2.83/vehicle/month (10,000 vehicles)
- **Optimized**: $1.06/vehicle/month
- **Savings**: $1.77/vehicle/month (63% reduction)

### Annual Savings

**Total Annual Savings**: $212,820

### Implementation Priority

1. **Quick Wins** (1-2 weeks):
   - Reserved Instances: $1,673/month
   - S3 Lifecycle: $1,080/month
   - CloudFront Caching: $3,150/month
   **Total**: $5,903/month

2. **Medium Term** (1-2 months):
   - Spot Instances: $1,000/month
   - Data Compression: $3,150/month
   - Right-Sizing: $1,200/month
   **Total**: $5,350/month

3. **Long Term** (3-6 months):
   - Architecture Optimization: $3,000/month
   - Query Optimization: $500/month
   - Regional Locality: $1,800/month
   **Total**: $5,300/month

---

## Conclusion

Multi-region cost optimization requires continuous monitoring, analysis, and adjustment. By implementing the strategies in this guide, you can achieve **63% cost reduction** while maintaining high availability and performance.

**Key Takeaways**:
1. Data transfer is the largest cost driver - optimize with compression and regional locality
2. Reserved Instances provide immediate 30-40% savings on predictable workloads
3. Storage tiering (S3 Intelligent-Tiering, Glacier) can reduce storage costs by 80%
4. Continuous monitoring and automation are essential for long-term optimization
5. Cost per vehicle is a critical metric for tracking efficiency

**Next Steps**:
1. Implement quick wins (RIs, S3 lifecycle, CloudFront)
2. Set up cost monitoring and alerting
3. Establish monthly cost review process
4. Document and share cost optimization wins with the team

---

**Document Version**: 1.0
**Last Updated**: 2026-03-19
**Review Cycle**: Monthly

# Global Infrastructure - DNS, CDN, IAM
# This configures resources that span multiple regions

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "automotive-terraform-state"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"  # Global resources created in us-east-1

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "global"
    }
  }
}

# Variables
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "automotive-platform"
}

variable "environment" {
  description = "Environment (production, staging, development)"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Root domain name for the platform"
  type        = string
}

variable "regions" {
  description = "List of AWS regions to deploy to"
  type        = list(string)
  default     = ["us-east-1", "eu-west-1", "ap-northeast-1"]
}

# Outputs for other modules
output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.vehicle_assets.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.vehicle_assets.domain_name
}

# ============================================================
# Route 53 - Global DNS
# ============================================================

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform - ${var.project_name}"

  tags = {
    Name = "${var.project_name}-zone"
  }
}

# Health check for US-EAST-1 endpoint
resource "aws_route53_health_check" "us_east_1" {
  fqdn              = "api-us-east-1.${var.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  measure_latency   = true

  tags = {
    Name   = "vehicle-api-us-east-1-health"
    Region = "us-east-1"
  }
}

# Health check for EU-WEST-1 endpoint
resource "aws_route53_health_check" "eu_west_1" {
  fqdn              = "api-eu-west-1.${var.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  measure_latency   = true

  tags = {
    Name   = "vehicle-api-eu-west-1-health"
    Region = "eu-west-1"
  }
}

# Health check for AP-NORTHEAST-1 endpoint
resource "aws_route53_health_check" "ap_northeast_1" {
  fqdn              = "api-ap-northeast-1.${var.domain_name}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30
  measure_latency   = true

  tags = {
    Name   = "vehicle-api-ap-northeast-1-health"
    Region = "ap-northeast-1"
  }
}

# SNS topic for health check alarms
resource "aws_sns_topic" "health_check_alerts" {
  name = "${var.project_name}-health-check-alerts"

  tags = {
    Name = "${var.project_name}-health-alerts"
  }
}

resource "aws_sns_topic_subscription" "health_check_email" {
  topic_arn = aws_sns_topic.health_check_alerts.arn
  protocol  = "email"
  endpoint  = "ops-team@example.com"
}

# CloudWatch alarms for health checks
resource "aws_cloudwatch_metric_alarm" "us_east_1_unhealthy" {
  alarm_name          = "${var.project_name}-us-east-1-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "US-EAST-1 region health check failed"
  alarm_actions       = [aws_sns_topic.health_check_alerts.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.us_east_1.id
  }
}

resource "aws_cloudwatch_metric_alarm" "eu_west_1_unhealthy" {
  alarm_name          = "${var.project_name}-eu-west-1-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "EU-WEST-1 region health check failed"
  alarm_actions       = [aws_sns_topic.health_check_alerts.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.eu_west_1.id
  }
}

# ============================================================
# CloudFront - Global CDN
# ============================================================

# Origin Access Identity for S3
resource "aws_cloudfront_origin_access_identity" "vehicle_assets" {
  comment = "${var.project_name} OTA updates and static assets"
}

# CloudFront distribution for OTA updates and static assets
resource "aws_cloudfront_distribution" "vehicle_assets" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} - OTA updates and static assets"
  default_root_object = "index.html"
  price_class         = "PriceClass_All"  # Global distribution
  aliases             = ["cdn.${var.domain_name}"]

  # US-EAST-1 origin
  origin {
    domain_name = "vehicle-assets-us-east-1.s3.amazonaws.com"
    origin_id   = "S3-US-EAST-1"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.vehicle_assets.cloudfront_access_identity_path
    }

    custom_header {
      name  = "X-Origin-Region"
      value = "us-east-1"
    }
  }

  # EU-WEST-1 origin
  origin {
    domain_name = "vehicle-assets-eu-west-1.s3.amazonaws.com"
    origin_id   = "S3-EU-WEST-1"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.vehicle_assets.cloudfront_access_identity_path
    }

    custom_header {
      name  = "X-Origin-Region"
      value = "eu-west-1"
    }
  }

  # Origin group for failover
  origin_group {
    origin_id = "S3-ORIGIN-GROUP"

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = "S3-US-EAST-1"
    }

    member {
      origin_id = "S3-EU-WEST-1"
    }
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-ORIGIN-GROUP"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600      # 1 hour
    max_ttl                = 86400     # 24 hours
    compress               = true
  }

  # OTA updates cache behavior (longer TTL)
  ordered_cache_behavior {
    path_pattern     = "/ota/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-ORIGIN-GROUP"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 86400     # 24 hours
    max_ttl                = 2592000   # 30 days
    compress               = true
  }

  # Map updates cache behavior
  ordered_cache_behavior {
    path_pattern     = "/maps/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-ORIGIN-GROUP"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 7200      # 2 hours
    max_ttl                = 86400     # 24 hours
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate (must be in us-east-1 for CloudFront)
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Logging configuration
  logging_config {
    include_cookies = false
    bucket         = "vehicle-logs-us-east-1.s3.amazonaws.com"
    prefix         = "cloudfront/"
  }

  tags = {
    Name = "${var.project_name}-cdn"
  }
}

# ACM Certificate for CloudFront (must be in us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  domain_name       = "cdn.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.cdn.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cloudfront-cert"
  }
}

# DNS record for CloudFront
resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "cdn.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.vehicle_assets.domain_name
    zone_id                = aws_cloudfront_distribution.vehicle_assets.hosted_zone_id
    evaluate_target_health = false
  }
}

# ============================================================
# IAM - Cross-Region Roles
# ============================================================

# IAM role for S3 replication
resource "aws_iam_role" "s3_replication" {
  name = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-s3-replication"
  }
}

resource "aws_iam_role_policy" "s3_replication" {
  role = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::vehicle-assets-*"
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::vehicle-assets-*/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::vehicle-assets-*/*"
        ]
      }
    ]
  })
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "${var.project_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-backup"
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ============================================================
# DynamoDB Global Table
# ============================================================

resource "aws_dynamodb_table" "vehicle_state" {
  name           = "${var.project_name}-vehicle-state"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "vehicle_id"
  range_key      = "timestamp"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "vehicle_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "region"
    type = "S"
  }

  global_secondary_index {
    name            = "region-timestamp-index"
    hash_key        = "region"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Global table replicas
  replica {
    region_name = "us-east-1"
  }

  replica {
    region_name = "eu-west-1"
  }

  replica {
    region_name = "ap-northeast-1"
  }

  tags = {
    Name = "${var.project_name}-vehicle-state-global"
  }
}

# ============================================================
# Monitoring & Alerting
# ============================================================

# SNS topic for operational alerts
resource "aws_sns_topic" "ops_alerts" {
  name = "${var.project_name}-ops-alerts"

  tags = {
    Name = "${var.project_name}-ops-alerts"
  }
}

# Cost anomaly detection
resource "aws_ce_anomaly_monitor" "cost_monitor" {
  name              = "${var.project_name}-cost-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "cost_alerts" {
  name      = "${var.project_name}-cost-alerts"
  frequency = "DAILY"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.cost_monitor.arn
  ]

  subscriber {
    type    = "EMAIL"
    address = "finance-team@example.com"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = ["100"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
}

# ============================================================
# Outputs
# ============================================================

output "s3_replication_role_arn" {
  description = "ARN of the S3 replication IAM role"
  value       = aws_iam_role.s3_replication.arn
}

output "backup_role_arn" {
  description = "ARN of the AWS Backup IAM role"
  value       = aws_iam_role.backup.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB global table"
  value       = aws_dynamodb_table.vehicle_state.name
}

output "ops_alerts_topic_arn" {
  description = "ARN of the operational alerts SNS topic"
  value       = aws_sns_topic.ops_alerts.arn
}

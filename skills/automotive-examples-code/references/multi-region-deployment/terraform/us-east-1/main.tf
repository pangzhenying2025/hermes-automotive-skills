# US-EAST-1 Regional Infrastructure
# North America region deployment

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
    key            = "us-east-1/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Region      = "us-east-1"
      ManagedBy   = "terraform"
    }
  }
}

# Variables
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "automotive-platform"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 zone ID from global module"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.2xlarge"
}

variable "db_storage_gb" {
  description = "RDS storage in GB"
  type        = number
  default     = 1000
}

variable "eks_node_instance_type" {
  description = "EKS node instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "eks_min_nodes" {
  description = "Minimum EKS nodes"
  type        = number
  default     = 5
}

variable "eks_max_nodes" {
  description = "Maximum EKS nodes"
  type        = number
  default     = 20
}

# ============================================================
# VPC and Networking
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-us-east-1"
  }
}

# Public subnets (for load balancers, NAT gateways)
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}-us-east-1"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnets (for application workloads)
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}-us-east-1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Database subnets
resource "aws_subnet" "database" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-database-${count.index + 1}-us-east-1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-us-east-1"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}-us-east-1"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}-us-east-1"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-us-east-1"
  }
}

resource "aws_route_table" "private" {
  count  = 3
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}-us-east-1"
  }
}

# Route table associations
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# ============================================================
# EKS Cluster
# ============================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${var.project_name}-cluster-us-east-1"
  cluster_version = "1.27"

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    general = {
      name           = "${var.project_name}-general-nodes"
      instance_types = [var.eks_node_instance_type]

      min_size     = var.eks_min_nodes
      max_size     = var.eks_max_nodes
      desired_size = var.eks_min_nodes

      labels = {
        workload-type = "general"
      }

      tags = {
        Name = "${var.project_name}-general-nodes-us-east-1"
      }
    }

    spot = {
      name           = "${var.project_name}-spot-nodes"
      instance_types = ["r6g.xlarge", "r6g.2xlarge"]

      min_size     = 0
      max_size     = 10
      desired_size = 2

      capacity_type = "SPOT"

      labels = {
        workload-type = "batch"
        lifecycle     = "spot"
      }

      taints = [{
        key    = "workload-type"
        value  = "batch"
        effect = "NoSchedule"
      }]

      tags = {
        Name = "${var.project_name}-spot-nodes-us-east-1"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-eks-us-east-1"
  }
}

# ============================================================
# RDS PostgreSQL/TimescaleDB
# ============================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group-us-east-1"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-us-east-1"
  }
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-database-sg-us-east-1"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EKS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-database-sg-us-east-1"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db-us-east-1"
  engine         = "postgres"
  engine_version = "14.7"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.database.arn

  db_name  = "automotive"
  username = "admin"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  # High availability
  multi_az = true

  # Backups
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.database.arn

  # Deletion protection
  deletion_protection = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project_name}-db-us-east-1-final-snapshot"

  tags = {
    Name   = "${var.project_name}-db-us-east-1"
    Backup = "critical"
  }
}

# Read replicas for load distribution
resource "aws_db_instance" "read_replica" {
  count              = 2
  identifier         = "${var.project_name}-db-us-east-1-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.main.identifier

  instance_class = var.db_instance_class
  storage_type   = "gp3"

  multi_az = false

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true

  tags = {
    Name = "${var.project_name}-db-us-east-1-replica-${count.index + 1}"
  }
}

# KMS key for database encryption
resource "aws_kms_key" "database" {
  description             = "${var.project_name} database encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-db-kms-us-east-1"
  }
}

resource "aws_kms_alias" "database" {
  name          = "alias/${var.project_name}-db-us-east-1"
  target_key_id = aws_kms_key.database.key_id
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.project_name}/db-password-us-east-1"

  tags = {
    Name = "${var.project_name}-db-password-us-east-1"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = aws_db_instance.main.username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = aws_db_instance.main.db_name
  })
}

# IAM role for RDS monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-us-east-1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-us-east-1"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ============================================================
# S3 Storage
# ============================================================

resource "aws_s3_bucket" "vehicle_assets" {
  bucket = "${var.project_name}-vehicle-assets-us-east-1"

  tags = {
    Name = "${var.project_name}-assets-us-east-1"
  }
}

resource "aws_s3_bucket_versioning" "vehicle_assets" {
  bucket = aws_s3_bucket.vehicle_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vehicle_assets" {
  bucket = aws_s3_bucket.vehicle_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_kms_key" "s3" {
  description             = "${var.project_name} S3 encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-s3-kms-us-east-1"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vehicle_assets" {
  bucket = aws_s3_bucket.vehicle_assets.id

  rule {
    id     = "archive-old-ota"
    status = "Enabled"

    filter {
      prefix = "ota/"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# ============================================================
# Application Load Balancer
# ============================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg-us-east-1"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from internet (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg-us-east-1"
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-us-east-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = true
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb-us-east-1"
  }
}

# ============================================================
# Route 53 Regional Records
# ============================================================

resource "aws_route53_record" "regional_api" {
  zone_id = var.route53_zone_id
  name    = "api-us-east-1.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Global API record with geoproximity routing
resource "aws_route53_record" "global_api" {
  zone_id = var.route53_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "US-EAST-1"

  geoproximity_routing_policy {
    aws_region = "us-east-1"
    bias       = 0
  }

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ============================================================
# Outputs
# ============================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "db_instance_endpoint" {
  description = "Database instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_read_replica_endpoints" {
  description = "Database read replica endpoints"
  value       = aws_db_instance.read_replica[*].endpoint
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

# Terraform Modules Quick Start Guide

This guide provides quick examples for using the S3 and RDS Terraform modules in your Airbyte infrastructure.

## Table of Contents

- [S3 Module Quick Start](#s3-module-quick-start)
- [RDS Module Quick Start](#rds-module-quick-start)
- [Complete Integration Example](#complete-integration-example)

## S3 Module Quick Start

### Minimal S3 Bucket

```hcl
module "simple_bucket" {
  source = "../../modules/s3"

  bucket_name = "my-airbyte-bucket"

  tags = {
    Environment = "dev"
  }
}
```

### Production S3 Bucket with Encryption and Lifecycle

```hcl
module "production_bucket" {
  source = "../../modules/s3"

  bucket_name       = "airbyte-production-data"
  enable_versioning = true
  create_kms_key    = true

  lifecycle_rules = [
    {
      id                         = "move-to-glacier"
      enabled                    = true
      filter_prefix              = "archives/"
      transition_days            = 90
      transition_storage_class   = "GLACIER"
      expiration_days            = 365
      noncurrent_version_expiration_days = 30
    }
  ]

  tags = {
    Environment = "production"
    Application = "airbyte"
  }
}
```

### S3 Bucket with CORS for Web Access

```hcl
module "web_accessible_bucket" {
  source = "../../modules/s3"

  bucket_name = "airbyte-web-assets"

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://app.example.com"]
      max_age_seconds = 3000
    }
  ]

  tags = {
    Purpose = "web-assets"
  }
}
```

## RDS Module Quick Start

### Minimal PostgreSQL Database

```hcl
module "simple_db" {
  source = "../../modules/rds"

  identifier        = "my-database"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.small"
  allocated_storage = 20

  username = "admin"
  password = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  allowed_security_groups = [module.eks.cluster_security_group_id]

  tags = {
    Environment = "dev"
  }
}
```

### Production PostgreSQL with High Availability

```hcl
module "production_db" {
  source = "../../modules/rds"

  identifier             = "airbyte-production"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.r6g.large"
  allocated_storage      = 500
  max_allocated_storage  = 2000
  storage_type           = "gp3"
  storage_encrypted      = true
  create_kms_key        = true

  database_name = "airbyte"
  username      = "airbyte_admin"
  password      = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  allowed_security_groups = [module.eks.cluster_security_group_id]

  # Custom parameters
  create_db_parameter_group = true
  parameter_group_family    = "postgres15"
  parameters = [
    {
      name  = "max_connections"
      value = "500"
    },
    {
      name  = "shared_buffers"
      value = "{DBInstanceClassMemory/16384}"
    }
  ]

  # Backup and maintenance
  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"
  skip_final_snapshot    = false

  # Monitoring
  monitoring_interval              = 60
  performance_insights_enabled     = true
  enabled_cloudwatch_logs_exports  = ["postgresql", "upgrade"]

  # High availability
  multi_az            = true
  deletion_protection = true

  tags = {
    Environment = "production"
    Application = "airbyte"
  }
}
```

### MySQL Database

```hcl
module "mysql_db" {
  source = "../../modules/rds"

  identifier        = "airbyte-mysql"
  engine            = "mysql"
  engine_version    = "8.0.35"
  instance_class    = "db.t3.medium"
  allocated_storage = 100

  database_name = "airbyte"
  username      = "admin"
  password      = var.db_password
  port          = 3306

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  allowed_security_groups = [module.eks.cluster_security_group_id]

  create_db_parameter_group = true
  parameter_group_family    = "mysql8.0"
  parameters = [
    {
      name  = "character_set_server"
      value = "utf8mb4"
    },
    {
      name  = "max_connections"
      value = "300"
    }
  ]

  multi_az               = true
  backup_retention_period = 7

  tags = {
    Environment = "production"
    Engine      = "mysql"
  }
}
```

## Complete Integration Example

Here's how to add S3 and RDS to your existing infrastructure:

```hcl
# In your main.tf (e.g., terraform/airbyte-infrastructure/declan/main.tf)

# Existing VPC and EKS modules...

################################################################################
# S3 Resources
################################################################################

module "airbyte_data" {
  source = "../../modules/s3"

  bucket_name       = "${var.cluster_name}-data"
  enable_versioning = true
  create_kms_key    = true

  lifecycle_rules = [
    {
      id                         = "archive"
      enabled                    = true
      transition_days            = 90
      transition_storage_class   = "STANDARD_IA"
      noncurrent_version_expiration_days = 30
    }
  ]

  tags = var.tags
}

module "airbyte_logs" {
  source = "../../modules/s3"

  bucket_name = "${var.cluster_name}-logs"

  lifecycle_rules = [
    {
      id              = "expire"
      enabled         = true
      expiration_days = 90
    }
  ]

  tags = var.tags
}

################################################################################
# RDS Database
################################################################################

module "airbyte_db" {
  source = "../../modules/rds"

  identifier        = "${var.cluster_name}-db"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 100

  database_name = "airbyte"
  username      = "airbyte_admin"
  password      = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  allowed_security_groups = [module.eks.cluster_security_group_id]

  storage_encrypted       = true
  backup_retention_period = 7
  multi_az               = true

  monitoring_interval          = 60
  performance_insights_enabled = true

  tags = var.tags
}

################################################################################
# Additional Outputs
################################################################################

output "s3_data_bucket" {
  value = module.airbyte_data.bucket_id
}

output "s3_logs_bucket" {
  value = module.airbyte_logs.bucket_id
}

output "database_endpoint" {
  value = module.airbyte_db.db_instance_endpoint
}

output "database_name" {
  value = module.airbyte_db.db_instance_name
}
```

### Required Variables

Add these to your `variables.tf`:

```hcl
variable "db_password" {
  description = "Password for the database master user"
  type        = string
  sensitive   = true
}
```

### Apply the Configuration

```bash
# Set the database password
export TF_VAR_db_password="your-secure-password"

# Plan and apply
terraform plan
terraform apply
```

## Using Module Outputs

### Accessing S3 from Airbyte

Configure Airbyte to use the S3 bucket:

```yaml
# In your Airbyte values.yaml
env_vars:
  S3_BUCKET_NAME: "${module.airbyte_data.bucket_id}"
  S3_BUCKET_REGION: "us-east-1"
```

### Connecting to RDS

Use the outputs to configure database connection:

```bash
# Get database endpoint
terraform output database_endpoint

# Connect using psql
psql -h <endpoint> -U airbyte_admin -d airbyte
```

## Best Practices

### Development Environment

```hcl
# Use smaller, cheaper resources
instance_class          = "db.t3.small"
multi_az               = false
deletion_protection    = false
skip_final_snapshot    = true
backup_retention_period = 1
```

### Production Environment

```hcl
# Use larger, more resilient resources
instance_class          = "db.r6g.large"
multi_az               = true
deletion_protection    = true
skip_final_snapshot    = false
backup_retention_period = 14
performance_insights_enabled = true
```

## Common Patterns

### Pattern 1: Separate Buckets by Purpose

```hcl
# Data bucket
module "data" {
  source = "../../modules/s3"
  bucket_name = "airbyte-data"
  # Long retention
}

# Logs bucket
module "logs" {
  source = "../../modules/s3"
  bucket_name = "airbyte-logs"
  # Short retention
}

# State bucket
module "state" {
  source = "../../modules/s3"
  bucket_name = "airbyte-state"
  # Versioning enabled
}
```

### Pattern 2: Primary + Replica Database

```hcl
# Primary
module "db_primary" {
  source = "../../modules/rds"
  identifier = "primary"
  multi_az = true
  # ... other config
}

# Replica
module "db_replica" {
  source = "../../modules/rds"
  identifier = "replica"
  replicate_source_db = module.db_primary.db_instance_id
  # ... other config
}
```

### Pattern 3: Cross-Region Backup Bucket

```hcl
# Primary bucket in us-east-1
module "primary_bucket" {
  source = "../../modules/s3"
  bucket_name = "airbyte-data-us-east-1"
}

# Backup bucket in us-west-2
module "backup_bucket" {
  source = "../../modules/s3"
  bucket_name = "airbyte-data-us-west-2"
  # Configure replication from primary
}
```

## Troubleshooting

### S3 Issues

**Problem:** Bucket already exists
```
Error: creating S3 Bucket: BucketAlreadyExists
```

**Solution:** Choose a globally unique bucket name

### RDS Issues

**Problem:** Cannot delete RDS instance
```
Error: deletion_protection is enabled
```

**Solution:** Set `deletion_protection = false` and apply before destroying

**Problem:** Port not accessible
```
Error: could not connect to server
```

**Solution:** Check security group rules allow traffic from your source

## Additional Resources

- [S3 Module Documentation](modules/s3/README.md)
- [RDS Module Documentation](modules/rds/README.md)
- [Complete Terraform README](README.md)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/best-practices.html)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)


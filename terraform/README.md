# Terraform Infrastructure

This directory contains Terraform configurations and modules for managing Airbyte infrastructure on AWS.

## Directory Structure

```
terraform/
├── modules/                           # Reusable Terraform modules
│   ├── eks/                          # EKS cluster module
│   ├── s3/                           # S3 bucket module
│   └── rds/                          # RDS database module
├── airbyte-infrastructure/           # Infrastructure configurations
│   └── declan/                       # Declan's environment
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── README.md
```

## Available Modules

### EKS Module (`modules/eks/`)

Creates a fully configured Amazon EKS cluster with:
- Managed node groups
- EKS add-ons (VPC CNI, CoreDNS, kube-proxy, EBS CSI driver)
- IRSA (IAM Roles for Service Accounts) support
- Security groups and IAM roles
- CloudWatch logging
- KMS encryption for cluster secrets

**Documentation:** See `modules/eks/README.md`

### S3 Module (`modules/s3/`)

Creates a secure S3 bucket with:
- Server-side encryption (AES256 or KMS)
- Versioning support
- Lifecycle management rules
- Public access blocking
- Access logging
- CORS configuration
- Intelligent tiering
- Optional KMS key creation

**Documentation:** See `modules/s3/README.md`

**Use Cases:**
- Airbyte data storage
- Log archival
- Backup storage
- Terraform state backend

### RDS Module (`modules/rds/`)

Creates an RDS database instance with:
- Support for all RDS engines (PostgreSQL, MySQL, MariaDB, Oracle, SQL Server)
- KMS encryption for storage
- Multi-AZ support
- Automated backups
- Enhanced monitoring
- Performance Insights
- Custom parameter and option groups
- Security group management
- CloudWatch Logs integration

**Documentation:** See `modules/rds/README.md`

**Use Cases:**
- Airbyte metadata database
- Application database
- Analytics database

## Getting Started

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.3
3. **kubectl** for EKS cluster access

### Basic Usage

1. **Initialize Terraform:**
   ```bash
   cd terraform/airbyte-infrastructure/<your-environment>
   terraform init
   ```

2. **Plan changes:**
   ```bash
   terraform plan
   ```

3. **Apply changes:**
   ```bash
   terraform apply
   ```

## Example: Complete Airbyte Infrastructure

Here's an example of using all modules together for an Airbyte deployment:

```hcl
# VPC Configuration
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.0"

  name = "airbyte-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  enable_dns_hostnames = true
}

# EKS Cluster
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "airbyte-cluster"
  kubernetes_version = "1.32"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  enable_ebs_csi_driver_addon = true

  tags = {
    Environment = "production"
    Application = "airbyte"
  }
}

# S3 Bucket for Airbyte Data
module "airbyte_data_bucket" {
  source = "../../modules/s3"

  bucket_name       = "airbyte-data-prod"
  enable_versioning = true
  create_kms_key    = true

  lifecycle_rules = [
    {
      id                         = "archive-old-data"
      enabled                    = true
      filter_prefix              = "data/"
      transition_days            = 90
      transition_storage_class   = "GLACIER"
      noncurrent_version_expiration_days = 30
    }
  ]

  tags = {
    Environment = "production"
    Application = "airbyte"
    Purpose     = "data-storage"
  }
}

# RDS PostgreSQL for Airbyte Metadata
module "airbyte_db" {
  source = "../../modules/rds"

  identifier        = "airbyte-metadata"
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

  # Production settings
  storage_encrypted       = true
  multi_az               = true
  backup_retention_period = 14
  deletion_protection    = true

  # Monitoring
  monitoring_interval          = 60
  performance_insights_enabled = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Environment = "production"
    Application = "airbyte"
    Purpose     = "metadata"
  }
}

# Outputs
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "s3_bucket_name" {
  value = module.airbyte_data_bucket.bucket_id
}

output "rds_endpoint" {
  value = module.airbyte_db.db_instance_endpoint
}
```

## Module Integration Examples

### Using S3 with Airbyte

```hcl
# Create S3 bucket for Airbyte logs
module "airbyte_logs" {
  source = "../../modules/s3"

  bucket_name       = "airbyte-logs-${var.environment}"
  enable_versioning = false

  lifecycle_rules = [
    {
      id              = "expire-old-logs"
      enabled         = true
      expiration_days = 90
    }
  ]

  tags = var.tags
}
```

### Using RDS with Read Replica

```hcl
# Primary database
module "airbyte_db_primary" {
  source = "../../modules/rds"

  identifier             = "airbyte-primary"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.r6g.xlarge"
  allocated_storage      = 500
  max_allocated_storage  = 2000

  database_name = "airbyte"
  username      = "admin"
  password      = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  multi_az               = true
  backup_retention_period = 14
  deletion_protection    = true

  tags = var.tags
}

# Read replica
module "airbyte_db_replica" {
  source = "../../modules/rds"

  identifier          = "airbyte-replica"
  replicate_source_db = module.airbyte_db_primary.db_instance_id

  instance_class = "db.r6g.large"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  skip_final_snapshot = true

  tags = merge(var.tags, { Role = "replica" })
}
```

## Best Practices

### Security

1. **Encryption:** Always enable encryption at rest for S3 and RDS
2. **KMS Keys:** Use customer-managed KMS keys for production workloads
3. **Network Isolation:** Deploy RDS in private subnets
4. **Security Groups:** Use restrictive security group rules
5. **Secrets Management:** Use AWS Secrets Manager or Parameter Store for sensitive data

### High Availability

1. **Multi-AZ:** Enable Multi-AZ for production RDS instances
2. **Backups:** Configure appropriate backup retention periods
3. **Monitoring:** Enable CloudWatch monitoring and alerts
4. **Auto Scaling:** Enable storage auto-scaling for RDS

### Cost Optimization

1. **S3 Lifecycle Rules:** Automatically transition data to cheaper storage classes
2. **S3 Intelligent Tiering:** Enable for unpredictable access patterns
3. **RDS Instance Sizing:** Right-size instances based on actual usage
4. **Reserved Instances:** Consider RIs for production workloads

### Monitoring

1. **CloudWatch Logs:** Enable log exports for RDS
2. **Performance Insights:** Enable for RDS performance monitoring
3. **Enhanced Monitoring:** Enable for detailed RDS metrics
4. **S3 Access Logs:** Enable for audit trails

## Terraform State Management

It's recommended to use remote state storage for team collaboration:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "airbyte/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Common Operations

### Destroy Infrastructure

To destroy infrastructure:

```bash
terraform destroy
```

**Warning:** This will delete all resources. Make sure you have backups!

### Import Existing Resources

To import an existing RDS instance:

```bash
terraform import module.airbyte_db.aws_db_instance.this my-db-instance-id
```

### State Management

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show module.airbyte_db.aws_db_instance.this

# Remove resource from state (doesn't delete the actual resource)
terraform state rm module.airbyte_db.aws_db_instance.this
```

## Troubleshooting

### Common Issues

1. **KMS Key Deletion:**
   - KMS keys have a mandatory waiting period (7-30 days) before deletion
   - Set `kms_key_deletion_window_in_days` appropriately

2. **RDS Final Snapshot:**
   - Set `skip_final_snapshot = true` for development environments
   - For production, ensure you have a snapshot before destroying

3. **S3 Bucket Not Empty:**
   - Set `force_destroy = true` to allow Terraform to delete non-empty buckets
   - Be careful with this in production!

4. **Security Group Rules:**
   - Ensure security groups allow traffic between EKS and RDS
   - Check VPC CIDR ranges are correct

## Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Airbyte on Kubernetes](https://docs.airbyte.com/deploying-airbyte/on-kubernetes)

## Contributing

When adding new modules:

1. Follow the existing module structure
2. Include comprehensive documentation in README.md
3. Add examples of usage
4. Include all standard files: main.tf, variables.tf, outputs.tf, versions.tf
5. Use appropriate tagging

## License

Apache 2.0

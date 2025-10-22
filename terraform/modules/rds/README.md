# RDS Database Terraform Module

This module creates an AWS RDS database instance with security best practices enabled by default.

## Features

- **Encryption**: Storage encryption with KMS support
- **Networking**: VPC-based deployment with security group management
- **High Availability**: Multi-AZ support
- **Backup**: Automated backups with configurable retention
- **Monitoring**: Enhanced monitoring and Performance Insights support
- **Security**: Security group rules, deletion protection
- **Logging**: CloudWatch Logs integration
- **Parameter Groups**: Custom database parameter and option groups
- **Scalability**: Storage autoscaling support

## Usage

### Basic PostgreSQL Example

```hcl
module "postgres_db" {
  source = "../../modules/rds"

  identifier        = "airbyte-postgres"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  storage_encrypted = true

  database_name = "airbyte"
  username      = "airbyte_admin"
  password      = var.db_password  # Use a secure method to manage passwords

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  allowed_security_groups = [module.eks.cluster_security_group_id]

  backup_retention_period = 7
  multi_az               = true
  deletion_protection    = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Environment = "production"
    Application = "airbyte"
  }
}
```

### Advanced Example with Custom Parameters

```hcl
module "postgres_db" {
  source = "../../modules/rds"

  identifier             = "airbyte-postgres"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.r6g.xlarge"
  allocated_storage      = 100
  max_allocated_storage  = 1000
  storage_type           = "gp3"
  storage_throughput     = 200
  storage_encrypted      = true
  create_kms_key        = true

  database_name = "airbyte"
  username      = "airbyte_admin"
  password      = var.db_password

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  allowed_cidr_blocks     = ["10.0.0.0/8"]
  allowed_security_groups = [module.eks.cluster_security_group_id]

  # Custom Parameter Group
  create_db_parameter_group = true
  parameter_group_family    = "postgres15"
  parameters = [
    {
      name  = "max_connections"
      value = "500"
    },
    {
      name  = "shared_buffers"
      value = "{DBInstanceClassMemory/32768}"
    },
    {
      name  = "log_statement"
      value = "all"
    }
  ]

  # Backup Configuration
  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  skip_final_snapshot    = false

  # Maintenance
  maintenance_window         = "Mon:04:00-Mon:05:00"
  auto_minor_version_upgrade = true

  # Monitoring
  monitoring_interval              = 60
  performance_insights_enabled     = true
  performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports  = ["postgresql", "upgrade"]

  # High Availability
  multi_az            = true
  deletion_protection = true

  tags = {
    Environment = "production"
    Application = "airbyte"
  }
}
```

### MySQL Example

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

  # MySQL-specific parameter group
  create_db_parameter_group = true
  parameter_group_family    = "mysql8.0"
  parameters = [
    {
      name  = "character_set_server"
      value = "utf8mb4"
    },
    {
      name  = "collation_server"
      value = "utf8mb4_unicode_ci"
    }
  ]

  backup_retention_period = 7
  multi_az               = true

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Environment = "production"
    Application = "airbyte"
  }
}
```

### Read Replica Example

```hcl
module "postgres_replica" {
  source = "../../modules/rds"

  identifier          = "airbyte-postgres-replica"
  replicate_source_db = module.postgres_db.db_instance_id

  instance_class = "db.t3.medium"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  allowed_security_groups = [module.eks.cluster_security_group_id]

  # Replicas inherit most settings from the source
  multi_az               = false
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Environment = "production"
    Application = "airbyte"
    Role        = "replica"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| identifier | The name of the RDS instance | `string` | n/a | yes |
| engine | The database engine to use | `string` | n/a | yes |
| engine_version | The engine version to use | `string` | n/a | yes |
| instance_class | The instance type of the RDS instance | `string` | n/a | yes |
| allocated_storage | The allocated storage in gibibytes | `number` | n/a | yes |
| username | Username for the master DB user | `string` | n/a | yes |
| password | Password for the master DB user | `string` | n/a | yes |
| vpc_id | VPC ID where the DB instance will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the DB subnet group | `list(string)` | n/a | yes |
| storage_encrypted | Specifies whether the DB instance is encrypted | `bool` | `true` | no |
| multi_az | Specifies if the RDS instance is multi-AZ | `bool` | `false` | no |
| backup_retention_period | The days to retain backups for | `number` | `7` | no |
| deletion_protection | If the DB instance should have deletion protection | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | The RDS instance ID |
| db_instance_arn | The ARN of the RDS instance |
| db_instance_endpoint | The connection endpoint |
| db_instance_address | The hostname of the RDS instance |
| db_instance_port | The database port |
| security_group_id | The security group ID of the RDS instance |

## Security Best Practices

This module implements several security best practices:

1. **Encryption at Rest**: Storage encryption is enabled by default
2. **Network Isolation**: Deployed in private subnets with security groups
3. **Backup & Recovery**: Automated backups with configurable retention
4. **Monitoring**: Support for Enhanced Monitoring and Performance Insights
5. **Deletion Protection**: Can be enabled to prevent accidental deletion
6. **No Public Access**: Public accessibility is disabled by default
7. **KMS Encryption**: Support for customer-managed encryption keys

## Database Engine Support

This module supports all RDS database engines:

- PostgreSQL
- MySQL
- MariaDB
- Oracle (all editions)
- Microsoft SQL Server (all editions)

## Performance Recommendations

For production Airbyte deployments:

1. **Instance Class**: Use at least `db.t3.medium` for development, `db.r6g.xlarge` or larger for production
2. **Storage**: Start with 100GB and enable autoscaling
3. **Multi-AZ**: Enable for production workloads
4. **Backups**: Set retention to at least 7 days
5. **Performance Insights**: Enable for production monitoring
6. **Enhanced Monitoring**: Set interval to 60 seconds for detailed metrics

## License

Apache 2.0


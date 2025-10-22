# RDS Module Outputs

################################################################################
# DB Instance
################################################################################

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_instance_engine" {
  description = "The database engine"
  value       = aws_db_instance.this.engine
}

output "db_instance_engine_version" {
  description = "The running version of the database"
  value       = aws_db_instance.this.engine_version_actual
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = aws_db_instance.this.resource_id
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.this.status
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = aws_db_instance.this.hosted_zone_id
}

################################################################################
# Security Group
################################################################################

output "security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the security group"
  value       = aws_security_group.this.arn
}

################################################################################
# DB Subnet Group
################################################################################

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.this.id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = aws_db_subnet_group.this.arn
}

################################################################################
# DB Parameter Group
################################################################################

output "db_parameter_group_id" {
  description = "The db parameter group name"
  value       = var.create_db_parameter_group ? aws_db_parameter_group.this[0].id : null
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = var.create_db_parameter_group ? aws_db_parameter_group.this[0].arn : null
}

################################################################################
# DB Option Group
################################################################################

output "db_option_group_id" {
  description = "The db option group name"
  value       = var.create_db_option_group ? aws_db_option_group.this[0].id : null
}

output "db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = var.create_db_option_group ? aws_db_option_group.this[0].arn : null
}

################################################################################
# KMS
################################################################################

output "kms_key_id" {
  description = "The ID of the KMS key used for RDS encryption"
  value       = var.create_kms_key ? aws_kms_key.rds[0].key_id : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for RDS encryption"
  value       = var.create_kms_key ? aws_kms_key.rds[0].arn : var.kms_key_id
}

################################################################################
# Enhanced Monitoring
################################################################################

output "enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the monitoring role"
  value       = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? aws_iam_role.enhanced_monitoring[0].arn : null
}

################################################################################
# CloudWatch Log Groups
################################################################################

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created"
  value = {
    for k, v in aws_cloudwatch_log_group.this : k => {
      name = v.name
      arn  = v.arn
    }
  }
}


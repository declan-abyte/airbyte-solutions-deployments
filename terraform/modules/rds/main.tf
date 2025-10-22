# RDS Database Module
# This module creates an RDS instance with security best practices enabled

locals {
  identifier = var.identifier
  
  common_tags = merge(
    var.tags,
    {
      "terraform" = "true"
      "module"    = "rds"
    }
  )
}

################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  name       = "${local.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, { Name = "${local.identifier}-subnet-group" })
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  name_prefix = "${local.identifier}-"
  description = "Security group for RDS instance ${local.identifier}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${local.identifier}-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = { for idx, cidr in var.allowed_cidr_blocks : idx => cidr }

  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.this.id
  description       = "Allow database access from ${each.value}"
}

resource "aws_security_group_rule" "ingress_security_groups" {
  for_each = { for idx, sg in var.allowed_security_groups : idx => sg }

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.this.id
  description              = "Allow database access from security group ${each.value}"
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
}

################################################################################
# DB Parameter Group
################################################################################

resource "aws_db_parameter_group" "this" {
  count = var.create_db_parameter_group ? 1 : 0

  name_prefix = "${local.identifier}-"
  family      = var.parameter_group_family
  description = "Custom parameter group for ${local.identifier}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  tags = merge(local.common_tags, { Name = "${local.identifier}-params" })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# DB Option Group
################################################################################

resource "aws_db_option_group" "this" {
  count = var.create_db_option_group ? 1 : 0

  name_prefix              = "${local.identifier}-"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version
  option_group_description = "Option group for ${local.identifier}"

  dynamic "option" {
    for_each = var.options
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = try(option.value.option_settings, [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(local.common_tags, { Name = "${local.identifier}-options" })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# KMS Key for RDS Encryption
################################################################################

resource "aws_kms_key" "rds" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for RDS instance ${local.identifier}"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_rotation

  tags = merge(local.common_tags, { Name = "${local.identifier}-kms" })
}

resource "aws_kms_alias" "rds" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${local.identifier}"
  target_key_id = aws_kms_key.rds[0].key_id
}

################################################################################
# RDS Instance
################################################################################

resource "aws_db_instance" "this" {
  identifier = local.identifier

  # Engine
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  storage_encrypted    = var.storage_encrypted
  kms_key_id           = var.storage_encrypted ? coalesce(var.kms_key_id, try(aws_kms_key.rds[0].arn, null)) : null
  iops                 = var.iops
  storage_throughput   = var.storage_throughput

  # Database Configuration
  db_name  = var.database_name
  username = var.username
  password = var.password
  port     = var.port

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = var.publicly_accessible

  # Parameter and Option Groups
  parameter_group_name = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.create_db_option_group ? aws_db_option_group.this[0].name : var.option_group_name

  # Backup
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  copy_tags_to_snapshot   = true
  skip_final_snapshot     = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Maintenance
  maintenance_window              = var.maintenance_window
  auto_minor_version_upgrade      = var.auto_minor_version_upgrade
  allow_major_version_upgrade     = var.allow_major_version_upgrade
  apply_immediately               = var.apply_immediately

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? var.monitoring_role_arn != null ? var.monitoring_role_arn : aws_iam_role.enhanced_monitoring[0].arn : null
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? coalesce(var.performance_insights_kms_key_id, try(aws_kms_key.rds[0].arn, null)) : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Multi-AZ & HA
  multi_az = var.multi_az

  # Deletion Protection
  deletion_protection = var.deletion_protection

  # Character Set
  character_set_name = var.character_set_name

  # Timezone
  timezone = var.timezone

  # License Model
  license_model = var.license_model

  # CA Certificate
  ca_cert_identifier = var.ca_cert_identifier

  # Replica
  replicate_source_db = var.replicate_source_db

  tags = merge(local.common_tags, { Name = local.identifier })

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      password,
    ]
  }
}

################################################################################
# Enhanced Monitoring IAM Role
################################################################################

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? 1 : 0

  name_prefix        = "${local.identifier}-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring[0].json

  tags = merge(local.common_tags, { Name = "${local.identifier}-monitoring" })
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 && var.monitoring_role_arn == null ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

################################################################################
# CloudWatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(var.enabled_cloudwatch_logs_exports)

  name              = "/aws/rds/instance/${local.identifier}/${each.value}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = merge(local.common_tags, { Name = "${local.identifier}-${each.value}" })
}


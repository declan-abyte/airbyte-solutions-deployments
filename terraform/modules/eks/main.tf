# EKS Cluster Module
# This module creates an AWS EKS cluster with managed node groups

locals {
  cluster_name = var.cluster_name
  
  common_tags = merge(
    var.tags,
    {
      "terraform"   = "true"
      "cluster"     = local.cluster_name
      # "environment" = var.environment
    }
  )
}

################################################################################
# EKS Cluster
################################################################################

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn         = aws_iam_role.cluster.arn
  version = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = var.cluster_enabled_log_types

  encryption_config {
    provider {
      key_arn = coalesce(var.cluster_encryption_config_kms_key_arn, aws_kms_key.eks[0].arn)
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.vpc_resource_controller,
    aws_cloudwatch_log_group.this
  ]

  tags = local.common_tags
}

################################################################################
# KMS Key for Cluster Encryption (if not provided)
################################################################################

resource "aws_kms_key" "eks" {
  count = var.cluster_encryption_config_kms_key_arn == null ? 1 : 0

  description             = "EKS Secret Encryption Key for ${local.cluster_name}"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation

  tags = merge(local.common_tags, { Name = "${local.cluster_name}-eks-encryption" })
}

resource "aws_kms_alias" "eks" {
  count = var.cluster_encryption_config_kms_key_arn == null ? 1 : 0

  name          = "alias/${local.cluster_name}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = local.common_tags
}

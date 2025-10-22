# EKS Cluster Variables

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = 1.32
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster and node groups"
  type        = list(string)
}

################################################################################
# Cluster Configuration
################################################################################

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

################################################################################
# Encryption Configuration
################################################################################

variable "cluster_encryption_config_kms_key_arn" {
  description = "KMS key ARN for envelope encryption of Kubernetes secrets. If null, a key will be created"
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "The waiting period before deleting the KMS key created for cluster encryption"
  type        = number
  default     = 30
}

variable "kms_key_enable_key_rotation" {
  description = "Enable automatic KMS key rotation for the KMS key created for cluster encryption"
  type        = bool
  default     = true
}

################################################################################
# CloudWatch Log Group
################################################################################

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 90
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = null
}

################################################################################
# Node Groups Configuration
################################################################################

variable "node_groups" {
  description = "Map of EKS managed node group definitions"
  type = map(object({
    desired_size   = optional(number, 2)
    max_size       = optional(number, 4)
    min_size       = optional(number, 1)
    instance_types = optional(list(string), ["t3.medium"])
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 20)
    ami_type       = optional(string, "AL2_x86_64")
    labels         = optional(map(string), {})
    tags           = optional(map(string), {})
    max_unavailable = optional(number, 1)
  }))
  default = {
    default = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.medium"]
    }
  }
}

################################################################################
# EKS Add-ons
################################################################################

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "Version of the VPC CNI addon"
  type        = string
  default     = null
}

variable "vpc_cni_service_account_role_arn" {
  description = "IAM role ARN for VPC CNI service account. If not provided, the module will create one automatically with the required permissions."
  type        = string
  default     = null
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "coredns_addon_version" {
  description = "Version of the CoreDNS addon"
  type        = string
  default     = null
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "kube_proxy_addon_version" {
  description = "Version of the kube-proxy addon"
  type        = string
  default     = null
}

variable "enable_ebs_csi_driver_addon" {
  description = "Enable AWS EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_addon_version" {
  description = "Version of the AWS EBS CSI driver addon"
  type        = string
  default     = null
}

variable "ebs_csi_driver_service_account_role_arn" {
  description = "IAM role ARN for EBS CSI driver service account. If not provided, the module will create one automatically with the required permissions."
  type        = string
  default     = null
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
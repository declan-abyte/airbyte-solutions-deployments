variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "airbyte-eks-declan"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = 1.32
}

################################################################################
# VPC Configuration
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

################################################################################
# Security Configuration
################################################################################

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the cluster API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

################################################################################
# Tags
################################################################################

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Airbyte"
    ManagedBy   = "Terraform"
    Owner       = "Declan"
  }
}


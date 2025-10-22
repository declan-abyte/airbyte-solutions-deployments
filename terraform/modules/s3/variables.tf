# S3 Module Variables

################################################################################
# Bucket Configuration
################################################################################

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket when the bucket is destroyed"
  type        = bool
  default     = false
}

################################################################################
# Versioning
################################################################################

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete for versioned objects"
  type        = bool
  default     = false
}

################################################################################
# Encryption
################################################################################

variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encryption. If null, uses AES256"
  type        = string
  default     = null
}

variable "create_kms_key" {
  description = "Create a new KMS key for bucket encryption"
  type        = bool
  default     = false
}

variable "kms_key_deletion_window_in_days" {
  description = "The waiting period before deleting the KMS key (7-30 days)"
  type        = number
  default     = 30
}

variable "kms_key_enable_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

################################################################################
# Public Access Block
################################################################################

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}

################################################################################
# Lifecycle Rules
################################################################################

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    id                                          = string
    enabled                                     = bool
    filter_prefix                               = optional(string)
    transition_days                             = optional(number)
    transition_storage_class                    = optional(string, "STANDARD_IA")
    expiration_days                             = optional(number)
    noncurrent_version_transition_days          = optional(number)
    noncurrent_version_transition_storage_class = optional(string, "STANDARD_IA")
    noncurrent_version_expiration_days          = optional(number)
  }))
  default = []
}

################################################################################
# Logging
################################################################################

variable "logging_target_bucket" {
  description = "Name of the bucket that will receive the log objects"
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Prefix for all log object keys"
  type        = string
  default     = "logs/"
}

################################################################################
# CORS Configuration
################################################################################

variable "cors_rules" {
  description = "List of CORS rules for the bucket"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default = []
}

################################################################################
# Bucket Policy
################################################################################

variable "bucket_policy" {
  description = "JSON policy document for the bucket"
  type        = string
  default     = null
}

################################################################################
# Intelligent Tiering
################################################################################

variable "enable_intelligent_tiering" {
  description = "Enable S3 Intelligent-Tiering"
  type        = bool
  default     = false
}

variable "intelligent_tiering_archive_days" {
  description = "Number of days before objects are moved to Archive Access tier"
  type        = number
  default     = 90
}

variable "intelligent_tiering_deep_archive_days" {
  description = "Number of days before objects are moved to Deep Archive Access tier"
  type        = number
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


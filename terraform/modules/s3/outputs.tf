# S3 Module Outputs

################################################################################
# Bucket
################################################################################

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.this.region
}

################################################################################
# KMS
################################################################################

output "kms_key_id" {
  description = "The ID of the KMS key used for bucket encryption"
  value       = var.create_kms_key ? aws_kms_key.s3[0].key_id : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used for bucket encryption"
  value       = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_arn
}

output "kms_alias_arn" {
  description = "The ARN of the KMS key alias"
  value       = var.create_kms_key ? aws_kms_alias.s3[0].arn : null
}


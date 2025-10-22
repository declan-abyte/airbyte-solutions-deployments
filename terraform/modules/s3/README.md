# S3 Bucket Terraform Module

This module creates an AWS S3 bucket with security best practices enabled by default.

## Features

- **Encryption**: Server-side encryption with AES256 or KMS
- **Versioning**: Optional versioning with MFA delete support
- **Public Access Block**: Blocks all public access by default
- **Lifecycle Management**: Configurable lifecycle rules for cost optimization
- **Access Logging**: Optional access logging to another S3 bucket
- **CORS Configuration**: Configurable CORS rules
- **Intelligent Tiering**: Optional automatic cost optimization
- **Bucket Policies**: Support for custom bucket policies

## Usage

### Basic Example

```hcl
module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name       = "my-airbyte-bucket"
  enable_versioning = true

  tags = {
    Environment = "production"
    Application = "airbyte"
  }
}
```

### Advanced Example with Lifecycle Rules

```hcl
module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name       = "my-airbyte-bucket"
  enable_versioning = true
  create_kms_key    = true

  lifecycle_rules = [
    {
      id                         = "archive-old-versions"
      enabled                    = true
      filter_prefix              = "data/"
      transition_days            = 30
      transition_storage_class   = "STANDARD_IA"
      noncurrent_version_transition_days = 30
      noncurrent_version_expiration_days = 90
    }
  ]

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://example.com"]
      max_age_seconds = 3000
    }
  ]

  tags = {
    Environment = "production"
    Application = "airbyte"
  }
}
```

### Example with Custom KMS Key

```hcl
resource "aws_kms_key" "bucket" {
  description             = "KMS key for S3 bucket"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name       = "my-airbyte-bucket"
  enable_versioning = true
  kms_key_arn      = aws_kms_key.bucket.arn

  tags = {
    Environment = "production"
    Application = "airbyte"
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
| bucket_name | Name of the S3 bucket (must be globally unique) | `string` | n/a | yes |
| enable_versioning | Enable versioning for the S3 bucket | `bool` | `true` | no |
| create_kms_key | Create a new KMS key for bucket encryption | `bool` | `false` | no |
| kms_key_arn | ARN of the KMS key to use for encryption | `string` | `null` | no |
| lifecycle_rules | List of lifecycle rules for the bucket | `list(object)` | `[]` | no |
| cors_rules | List of CORS rules for the bucket | `list(object)` | `[]` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| kms_key_arn | The ARN of the KMS key used for bucket encryption |

## Security Best Practices

This module implements several security best practices:

1. **Encryption at Rest**: All objects are encrypted by default
2. **Public Access Block**: All public access is blocked by default
3. **Versioning**: Can be enabled to protect against accidental deletions
4. **KMS Encryption**: Supports customer-managed keys for enhanced security
5. **Access Logging**: Can log all access requests for auditing

## License

Apache 2.0


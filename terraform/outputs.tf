output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.app_storage.id
  sensitive   = true
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.app_storage.arn
  sensitive   = true
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.app_storage.bucket_domain_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for the application"
  value       = aws_iam_role.app_role.arn
  sensitive   = true
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.app_audit_trail.arn
  sensitive   = true
}

output "cloudtrail_bucket_id" {
  description = "ID of the CloudTrail S3 bucket"
  value       = aws_s3_bucket.cloudtrail_bucket.id
  sensitive   = true
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# Sensitive outputs (security metadata only)
output "bucket_encryption_status" {
  description = "S3 bucket encryption configuration"
  value = {
    encryption_enabled = true
    sse_algorithm      = var.encryption_algorithm
    bucket_key_enabled = true
  }
}

output "security_features" {
  description = "Security features enabled for compliance reporting"
  value = {
    s3_encryption            = true
    s3_versioning            = true
    s3_public_access_blocked = true
    cloudtrail_enabled       = var.enable_cloudtrail
    iam_least_privilege      = true
  }
}

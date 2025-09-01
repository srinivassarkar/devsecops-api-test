#############################################################
# Terraform Settings & Providers
#############################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Default tags added to all AWS resources
  default_tags {
    tags = {
      Project     = "DevSecOps-Demo"
      Environment = var.environment
      Owner       = "DevSecOps-Team"
      ManagedBy   = "Terraform"
    }
  }
}


#############################################################
# Random Generator for Unique Suffix
#############################################################

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}


#############################################################
# KMS Keys
#############################################################

# KMS Key for CloudTrail logs
resource "aws_kms_key" "cloudtrail_key" {
  description         = "KMS CMK for CloudTrail logs"
  enable_key_rotation = true
}

# KMS Key for Application Storage bucket
resource "aws_kms_key" "app_storage_key" {
  description         = "CMK for Application S3 bucket"
  enable_key_rotation = true
}

# KMS Key for S3 Access Logs
resource "aws_kms_key" "s3_logs_kms" {
  description         = "KMS key for S3 access logs"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_general_policy.json
  tags = {
    Name = "${var.app_name}-s3-logs-kms"
  }
}

resource "aws_kms_alias" "s3_logs_kms_alias" {
  name          = "alias/${var.app_name}-s3-logs"
  target_key_id = aws_kms_key.s3_logs_kms.key_id
}

# KMS Key for CloudWatch Logs
resource "aws_kms_key" "cwl_kms" {
  description         = "KMS key for CloudWatch Logs (CloudTrail)"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_general_policy.json
  tags = {
    Name = "${var.app_name}-cwl-kms"
  }
}

resource "aws_kms_alias" "cwl_kms_alias" {
  name          = "alias/${var.app_name}-cwl"
  target_key_id = aws_kms_key.cwl_kms.key_id
}


#############################################################
# S3 Buckets
#############################################################

# Application Storage Bucket
resource "aws_s3_bucket" "app_storage" {
  bucket = "${var.app_name}-storage-${random_string.bucket_suffix.result}"
  tags = {
    Name       = "DevSecOps Application Storage"
    Purpose    = "Secure storage for application assets"
    Compliance = "SOC2-Type-II"
  }
}

# Application Storage - Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_storage_encryption" {
  bucket = aws_s3_bucket.app_storage.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.app_storage_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Application Storage - Versioning
resource "aws_s3_bucket_versioning" "app_storage_versioning" {
  bucket = aws_s3_bucket.app_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Application Storage - Public Access Block
resource "aws_s3_bucket_public_access_block" "app_storage_pab" {
  bucket                  = aws_s3_bucket.app_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Application Storage - Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "app_storage_lifecycle" {
  bucket = aws_s3_bucket.app_storage.id
  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# CloudTrail Bucket
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = "${var.app_name}-cloudtrail-${random_string.bucket_suffix.result}"
  tags = {
    Name    = "CloudTrail Audit Logs"
    Purpose = "Security audit logging"
  }
}

# CloudTrail Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_encryption" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# CloudTrail Bucket Versioning
resource "aws_s3_bucket_versioning" "cloudtrail_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudTrail Bucket Logging
resource "aws_s3_bucket_logging" "cloudtrail_logging" {
  bucket        = aws_s3_bucket.cloudtrail_bucket.id
  target_bucket = aws_s3_bucket.app_storage.id
  target_prefix = "cloudtrail-access-logs/"
}

# CloudTrail Bucket - Block Public Access
resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_pab" {
  bucket                  = aws_s3_bucket.cloudtrail_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail Bucket Policy
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_bucket.arn}/audit-logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}


# Logs Bucket (for S3 access logs)
resource "aws_s3_bucket" "logs_bucket" {
  bucket = "${var.app_name}-access-logs-${random_string.bucket_suffix.result}"
  tags = {
    Name    = "S3 Access Logs Bucket"
    Purpose = "Access logging target"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_bucket_sse" {
  bucket = aws_s3_bucket.logs_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_logs_kms.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs_bucket_versioning" {
  bucket = aws_s3_bucket.logs_bucket.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "logs_bucket_pab" {
  bucket                  = aws_s3_bucket.logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow AWS to deliver access logs
resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = aws_s3_bucket.logs_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSLogDeliveryWrite",
        Effect    = "Allow",
        Principal = { Service : "logging.s3.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.logs_bucket.arn}/*",
        Condition = { StringEquals : { "s3:x-amz-acl" : "bucket-owner-full-control" } }
      },
      {
        Sid       = "AWSLogDeliveryAclCheck",
        Effect    = "Allow",
        Principal = { Service : "logging.s3.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.logs_bucket.arn
      }
    ]
  })
}

# Enable logging from App Storage → Logs bucket
resource "aws_s3_bucket_logging" "app_storage_logging" {
  bucket        = aws_s3_bucket.app_storage.id
  target_bucket = aws_s3_bucket.logs_bucket.id
  target_prefix = "app-storage/"
}


#############################################################
# CloudWatch Logs for CloudTrail
#############################################################

resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/${var.app_name}"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.cwl_kms.arn
}


#############################################################
# IAM Role & Policy for CloudTrail → CloudWatch
#############################################################

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.app_name}-cloudtrail-cw-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  role = aws_iam_role.cloudtrail_cloudwatch_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"]
      }
    ]
  })
}


#############################################################
# CloudTrail Setup
#############################################################

resource "aws_cloudtrail" "app_audit_trail" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]

  name                          = "${var.app_name}-audit-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  s3_key_prefix                 = "audit-logs"
  kms_key_id                    = aws_kms_key.cloudtrail_key.arn
  enable_log_file_validation    = true
  is_multi_region_trail         = true
  include_global_service_events = true
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail_logs.arn
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_role.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}


#############################################################
# IAM Role & Policy for Application (EC2) → S3
#############################################################

resource "aws_iam_role" "app_role" {
  name = "${var.app_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "app_s3_policy" {
  name = "${var.app_name}-s3-policy"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.app_storage.arn,
          "${aws_s3_bucket.app_storage.arn}/*"
        ]
      }
    ]
  })
}


#############################################################
# Data Sources
#############################################################

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms_general_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

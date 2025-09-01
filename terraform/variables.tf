variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"

  validation {
    # Restrict to US-only for compliance (adjust if needed)
    condition     = contains(["us-east-1", "us-west-1", "us-west-2"], var.aws_region)
    error_message = "AWS region must be one of: us-east-1, us-west-1, us-west-2."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "devsecops-nodejs-api"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.app_name))
    error_message = "App name must start with a letter and contain only letters, numbers, and hyphens."
  }
}

variable "bucket_name" {
  description = "Base name for S3 bucket (random suffix will be added)"
  type        = string
  default     = "devsecops-app-storage"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*$", var.bucket_name))
    error_message = "Bucket name must be lowercase and contain only letters, numbers, and hyphens."
  }
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access resources"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = true
}

variable "retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 90

  validation {
    condition     = var.retention_days >= 30 && var.retention_days <= 365
    error_message = "Retention days must be between 30 and 365."
  }
}

variable "encryption_algorithm" {
  description = "Encryption algorithm for S3 buckets (AES256 or aws:kms)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be AES256 or aws:kms."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default = {
    CreatedBy = "Terraform"
    Purpose   = "DevSecOps-Demo"
  }
}

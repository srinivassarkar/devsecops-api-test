# AWS Configuration
aws_region = "us-west-2"

# Environment Configuration
environment = "dev"
app_name    = "devsecops-nodejs-api"

# S3 Configuration
bucket_name = "devsecops-app-storage"

# Network Security
allowed_cidr_blocks = [
  "10.0.0.0/8",
  "172.16.0.0/12",
  "192.168.0.0/16"
]

# Security Features
enable_cloudtrail = true
retention_days    = 90

# Additional Tags
tags = {
  CreatedBy  = "Terraform"
  Purpose    = "DevSecOps-Demo"
  Owner      = "DevSecOps-Team"
  CostCenter = "Engineering"
  Compliance = "SOC2"
}

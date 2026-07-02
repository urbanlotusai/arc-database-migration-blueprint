variable "namespace" {
  description = "Organization or team namespace"
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "arc-database-migration-blueprint"
  }
}

variable "enable_bucket_force_destroy" {
  description = "Allow destruction of the Terraform state S3 bucket even if it contains objects"
  type        = bool
  default     = false
}

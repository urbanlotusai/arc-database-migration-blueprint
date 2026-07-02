variable "namespace" {
  description = "Organization or team namespace"
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Environment name"
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

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state (used to read 01-kms and 02-network remote state)"
  type        = string
}

variable "target_db_username" {
  description = "Master username for the target Aurora cluster."
  type        = string
  default     = "dbadmin"
}

variable "target_db_engine" {
  description = "Target Aurora engine: aurora-postgresql or aurora-mysql."
  type        = string
  default     = "aurora-postgresql"
}

variable "target_db_engine_version" {
  description = "Target database engine version."
  type        = string
  default     = "15.4"
}

variable "target_db_instance_class" {
  description = "DB instance class for the target Aurora cluster."
  type        = string
  default     = "db.r6g.large"
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups for the target Aurora cluster."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the target Aurora cluster."
  type        = bool
  default     = false
}

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
  description = "S3 bucket name for Terraform state (used to read 01-kms, 02-network, 03-security-group, and 05-db remote state)"
  type        = string
}

variable "source_db_host" {
  description = "Hostname or IP of the source database server."
  type        = string
}

variable "source_db_port" {
  description = "Port of the source database server."
  type        = number
}

variable "source_db_name" {
  description = "Source database name."
  type        = string
}

variable "source_db_username" {
  description = "Source database username."
  type        = string
}

variable "source_db_engine" {
  description = "Source database engine (e.g. mysql, postgres, oracle, sqlserver)."
  type        = string
}

variable "target_db_username" {
  description = "Master username for the target Aurora cluster. Must match 05-db's target_db_username."
  type        = string
  default     = "dbadmin"
}

variable "target_db_engine" {
  description = "Target Aurora engine: aurora-postgresql or aurora-mysql. Must match 05-db's target_db_engine."
  type        = string
  default     = "aurora-postgresql"
}

variable "dms_instance_class" {
  description = "DMS replication instance class."
  type        = string
  default     = "dms.t3.medium"
}

variable "dms_engine_version" {
  description = "DMS replication engine version."
  type        = string
  default     = "3.5.3"
}

variable "dms_multi_az" {
  description = "Deploy the DMS replication instance in Multi-AZ for HA."
  type        = bool
  default     = false
}

variable "migration_type" {
  description = "DMS migration type: full-load, cdc, or full-load-and-cdc."
  type        = string
  default     = "full-load-and-cdc"

  validation {
    condition     = contains(["full-load", "cdc", "full-load-and-cdc"], var.migration_type)
    error_message = "migration_type must be: full-load, cdc, or full-load-and-cdc."
  }
}

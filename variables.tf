# ── Mandatory ─────────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment (e.g. prod, staging, dev)."
  type        = string
}

variable "namespace" {
  description = "Project or team namespace used as a resource name prefix."
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
  description = "Master username for the target Aurora/RDS instance."
  type        = string
  default     = "dbadmin"
}

variable "target_db_password" {
  description = "Master password for the target Aurora/RDS instance. Use Secrets Manager in production."
  type        = string
  sensitive   = true
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the migration VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "target_db_engine" {
  description = "Target Aurora/RDS engine: aurora-postgresql or aurora-mysql."
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

variable "migration_type" {
  description = "DMS migration type: full-load, cdc, or full-load-and-cdc."
  type        = string
  default     = "full-load-and-cdc"

  validation {
    condition     = contains(["full-load", "cdc", "full-load-and-cdc"], var.migration_type)
    error_message = "migration_type must be: full-load, cdc, or full-load-and-cdc."
  }
}

variable "dms_multi_az" {
  description = "Deploy the DMS replication instance in Multi-AZ for HA."
  type        = bool
  default     = false
}

variable "compliance_profile" {
  description = "Compliance overlay: 'general' (default) or 'hipaa'."
  type        = string
  default     = "general"

  validation {
    condition     = contains(["general", "hipaa", "pci_dss"], var.compliance_profile)
    error_message = "compliance_profile must be general, hipaa, or pci_dss."
  }
}

variable "kms_deletion_window" {
  description = "Days before a scheduled KMS key deletion takes effect (7–30)."
  type        = number
  default     = 30
}

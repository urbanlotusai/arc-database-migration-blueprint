# =============================================================================
# Module: 06-dms
# =============================================================================
# Provisions the DMS replication instance, source/target endpoints, and
# replication task that migrates data into the target Aurora cluster.
# State file: modules/06-dms/terraform.tfstate
# Depends on: 01-kms (encryption key), 02-network (vpc_id + private subnets),
#             03-security-group (security group id), 05-db (target cluster
#             endpoint)
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "terraform_remote_state" "kms" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "modules/01-kms/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "modules/02-network/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "security_group" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "modules/03-security-group/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "modules/05-db/terraform.tfstate"
    region = var.region
  }
}

# VPC private subnets (looked up by tag after the 02-network module creates
# them). This stays a native aws_subnets data source (not a remote_state
# read) because subnet discovery-by-tag is a real AWS data source.
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.network.outputs.vpc_id]
  }
  tags = {
    Type = "private"
  }
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  target_db_name = "${var.namespace}-${var.environment}-target-db"

  # Migrate all tables in all schemas. Customize this JSON to restrict which
  # schemas/tables DMS migrates.
  table_mappings = jsonencode({
    rules = [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "migrate-all"
        object-locator = {
          schema-name = "%"
          table-name  = "%"
        }
        rule-action = "include"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# DMS Module
# -----------------------------------------------------------------------------

module "dms" {
  source  = "sourcefuse/arc-dms/aws"
  version = "0.0.5"

  prefix = "${var.namespace}-${var.environment}"

  # ── Replication instance ───────────────────────────────────────────────────
  instance_id             = "${var.namespace}-${var.environment}-dms"
  instance_class          = var.dms_instance_class
  instance_engine_version = var.dms_engine_version
  instance_multi_az       = var.dms_multi_az
  instance_kms_key_arn    = data.terraform_remote_state.kms.outputs.key_arn

  # ── Subnet group (DMS must run in the same VPC as the target DB) ───────────
  create_subnet_group     = true
  subnet_group_id         = "${var.namespace}-${var.environment}-dms-subnet"
  subnet_group_subnet_ids = data.aws_subnets.private.ids

  instance_vpc_security_group_ids = [data.terraform_remote_state.security_group.outputs.id]

  # ── Source endpoint (on-prem or existing DB) ───────────────────────────────
  endpoints = {
    source = {
      endpoint_id   = "${var.namespace}-${var.environment}-source"
      endpoint_type = "source"
      engine_name   = var.source_db_engine
      server_name   = var.source_db_host
      port          = var.source_db_port
      database_name = var.source_db_name
      username      = var.source_db_username
      # Use secrets_manager_arn to avoid embedding the password here:
      # secrets_manager_arn             = aws_secretsmanager_secret.source_db.arn
      # secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
      ssl_mode    = "require"
      kms_key_arn = data.terraform_remote_state.kms.outputs.key_arn
    }

    target = {
      endpoint_id   = "${var.namespace}-${var.environment}-target"
      endpoint_type = "target"
      engine_name   = var.target_db_engine == "aurora-postgresql" ? "aurora-postgresql" : "aurora"
      server_name   = data.terraform_remote_state.db.outputs.cluster_endpoint
      port          = var.target_db_engine == "aurora-postgresql" ? 5432 : 3306
      database_name = local.target_db_name
      username      = var.target_db_username
      ssl_mode      = "require"
      kms_key_arn   = data.terraform_remote_state.kms.outputs.key_arn
    }
  }

  # ── Replication task ────────────────────────────────────────────────────────
  # source_endpoint_arn and target_endpoint_arn are resolved by the module
  # internally from the endpoints map above — do not pass them here.
  replication_tasks = {
    migration = {
      replication_task_id    = "${var.namespace}-${var.environment}-migration-task"
      migration_type         = var.migration_type
      table_mappings         = local.table_mappings
      start_replication_task = false # start manually after validating endpoints

      # Task settings: enable logging, CloudWatch metrics, full-LOB mode
      replication_task_settings = jsonencode({
        Logging = {
          EnableLogging = true
          LogComponents = [
            { Id = "SOURCE_UNLOAD", Severity = "LOGGER_SEVERITY_DEFAULT" },
            { Id = "TARGET_LOAD", Severity = "LOGGER_SEVERITY_DEFAULT" },
            { Id = "TASK_MANAGER", Severity = "LOGGER_SEVERITY_DEFAULT" }
          ]
        }
        TargetMetadata = { TargetSchema = "" }
        FullLoadSettings = {
          TargetTablePrepMode = "DO_NOTHING" # preserve existing data; change to DROP_AND_CREATE for fresh targets
        }
      })
    }
  }

  tags = var.tags
}

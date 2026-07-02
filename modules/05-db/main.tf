# =============================================================================
# Module: 05-db
# =============================================================================
# Provisions the target Aurora cluster (PostgreSQL or MySQL) that receives
# migrated data from DMS.
# State file: modules/05-db/terraform.tfstate
# Depends on: 01-kms (encryption key), 02-network (vpc_id + private subnets)
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
# Target DB Module
# -----------------------------------------------------------------------------

module "db" {
  source  = "sourcefuse/arc-db/aws"
  version = "4.0.4"

  name        = "${var.namespace}-${var.environment}-target-db"
  namespace   = var.namespace
  environment = var.environment

  engine         = var.target_db_engine
  engine_type    = "cluster"
  engine_version = var.target_db_engine_version
  license_model  = "general-public-license"
  port           = var.target_db_engine == "aurora-postgresql" ? 5432 : 3306

  username = var.target_db_username

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  db_subnet_group_data = {
    subnet_ids = data.aws_subnets.private.ids
  }

  storage_encrypted       = true
  kms_key_id              = data.terraform_remote_state.kms.outputs.key_arn
  instance_class          = var.target_db_instance_class
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection

  tags = var.tags
}

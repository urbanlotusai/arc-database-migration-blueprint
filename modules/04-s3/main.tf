# =============================================================================
# Module: 04-s3
# =============================================================================
# Provisions the S3 bucket used for DMS task logs, validation reports, and
# full-load output files.
# State file: modules/04-s3/terraform.tfstate
# Depends on: 01-kms (encryption key)
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

# -----------------------------------------------------------------------------
# S3 Module
# -----------------------------------------------------------------------------

module "s3" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name = "${var.namespace}-${var.environment}-dms-logs"

  server_side_encryption_config_data = {
    bucket_key_enabled = true
    sse_algorithm       = "aws:kms"
    kms_master_key_id   = data.terraform_remote_state.kms.outputs.key_arn
  }

  public_access_config = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  tags = var.tags
}

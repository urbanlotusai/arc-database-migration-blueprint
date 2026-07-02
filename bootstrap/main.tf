# =============================================================================
# Module: bootstrap
# =============================================================================
# Creates the S3 bucket and DynamoDB table used as the Terraform state backend
# for every module in modules/. Uses local state — this must be applied FIRST,
# before any module in modules/ can be initialized.
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

module "bootstrap" {
  source  = "sourcefuse/arc-bootstrap/aws"
  version = "1.1.10"

  bucket_name                   = "${var.namespace}-${var.environment}-terraform-state"
  enable_versioning             = true
  enable_bucket_force_destroy   = var.enable_bucket_force_destroy
  enable_s3_public_access_block = true
  sse_algorithm                 = "AES256"

  dynamodb_name                          = "${var.namespace}-${var.environment}-terraform-locks"
  dynamodb_hash_key                      = "LockID"
  enable_dynamodb_point_in_time_recovery = true

  noncurrent_version_expiration = 365
  noncurrent_version_transitions = [
    {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  ]

  tags = var.tags
}

resource "aws_ssm_parameter" "state_bucket" {
  name      = "/${var.namespace}/${var.environment}/terraform/state-bucket"
  type      = "String"
  value     = module.bootstrap.bucket_name
  overwrite = true

  tags = var.tags
}

resource "aws_ssm_parameter" "lock_table" {
  name      = "/${var.namespace}/${var.environment}/terraform/lock-table"
  type      = "String"
  value     = module.bootstrap.dynamodb_name
  overwrite = true

  tags = var.tags
}

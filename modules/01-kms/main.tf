# =============================================================================
# Module: 01-kms
# =============================================================================
# Provisions the customer-managed KMS key used by S3, the target Aurora
# cluster, and the DMS replication instance in this blueprint.
# State file: modules/01-kms/terraform.tfstate
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

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "AllowAccountRoot"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # DMS requires these to encrypt replication instance storage
  statement {
    sid    = "AllowDMS"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["dms.amazonaws.com"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

# -----------------------------------------------------------------------------
# KMS Module
# -----------------------------------------------------------------------------

module "kms" {
  source  = "sourcefuse/arc-kms/aws"
  version = "1.0.11"

  alias                   = "alias/${var.namespace}-${var.environment}-migration"
  policy                  = data.aws_iam_policy_document.kms.json
  description             = "CMK for ${var.namespace}-${var.environment} database migration"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  tags = var.tags
}

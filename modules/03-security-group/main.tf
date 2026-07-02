# =============================================================================
# Module: 03-security-group
# =============================================================================
# Provisions the security group controlling inbound access to the DMS
# replication instance and target Aurora cluster.
# State file: modules/03-security-group/terraform.tfstate
# Depends on: 02-network (vpc_id)
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

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket_name
    key    = "modules/02-network/terraform.tfstate"
    region = var.region
  }
}

# -----------------------------------------------------------------------------
# Security Group Module
# -----------------------------------------------------------------------------

module "security_group" {
  source  = "sourcefuse/arc-security-group/aws"
  version = "0.0.5"

  name        = "${var.namespace}-${var.environment}-migration"
  description = "Security group for DMS replication instance and target database"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress_rules = [
    {
      # Allow PostgreSQL traffic within the VPC (DMS → target DB)
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "PostgreSQL from within VPC"
    },
    {
      # Allow MySQL/Aurora MySQL within the VPC
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
      description = "MySQL/Aurora from within VPC"
    }
  ]

  egress_rules = [
    {
      # DMS needs outbound to reach source DB (on-prem or peered VPC)
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound (DMS → source DB)"
    }
  ]

  tags = var.tags
}

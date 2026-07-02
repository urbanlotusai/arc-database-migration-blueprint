# ═══════════════════════════════════════════════════════════════════════════════
# 1. KMS — root of the encryption trust chain
#    Outputs consumed by: module.s3, module.db, module.dms
# ═══════════════════════════════════════════════════════════════════════════════
module "kms" {
  source  = "sourcefuse/arc-kms/aws"
  version = "1.0.11"

  alias                   = local.kms_alias
  policy                  = data.aws_iam_policy_document.kms.json
  description             = "CMK for ${local.name_prefix} database migration"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2. Network — VPC + subnets for DMS replication instance and target DB
#    Outputs consumed by: module.security_group, module.db, module.dms
# ═══════════════════════════════════════════════════════════════════════════════
module "network" {
  source  = "sourcefuse/arc-network/aws"
  version = "3.0.14"

  name        = local.name_prefix
  namespace   = var.namespace
  environment = var.environment
  cidr_block  = var.vpc_cidr

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. Security Group — controls inbound access to DMS instance and target DB
#    Outputs consumed by: module.db, module.dms
# ═══════════════════════════════════════════════════════════════════════════════
module "security_group" {
  source  = "sourcefuse/arc-security-group/aws"
  version = "0.0.5"

  name        = "${local.name_prefix}-migration"
  description = "Security group for DMS replication instance and target database"
  vpc_id      = module.network.vpc_id

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

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 4. S3 — DMS task logs, validation reports, and full-load output files
#    Outputs consumed by: module.dms (s3_endpoints)
# ═══════════════════════════════════════════════════════════════════════════════
module "s3" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name = local.log_bucket_name

  server_side_encryption_config_data = {
    bucket_key_enabled = true
    sse_algorithm      = "aws:kms"
    kms_master_key_id  = module.kms.key_arn
  }

  public_access_config = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 5. Target DB — Aurora PostgreSQL (or MySQL) receiving migrated data
#    Outputs consumed by: module.dms (target endpoint)
# ═══════════════════════════════════════════════════════════════════════════════
module "db" {
  source  = "sourcefuse/arc-db/aws"
  version = "4.0.4"

  name        = local.target_db_name
  namespace   = var.namespace
  environment = var.environment

  engine         = var.target_db_engine
  engine_type    = "cluster"
  engine_version = var.target_db_engine_version
  license_model  = "general-public-license"
  port           = var.target_db_engine == "aurora-postgresql" ? 5432 : 3306

  username = var.target_db_username

  # DB subnet group lookup — references the private subnets from module.network
  vpc_id              = module.network.vpc_id
  db_subnet_group_data = {
    subnet_ids = data.aws_subnets.private.ids
  }

  # Encrypt at rest with the CMK
  storage_encrypted = true
  kms_key_id        = module.kms.key_arn

  # Instance sizing
  instance_class = var.target_db_instance_class

  # HIPAA: extended PITR + deletion protection
  backup_retention_period = local.is_strict ? 35 : 7
  deletion_protection     = local.is_strict

  tags = local.tags
}

# ═══════════════════════════════════════════════════════════════════════════════
# 6. DMS — replication instance + source/target endpoints + migration task
#    Orchestrates the actual data movement from source → target Aurora
# ═══════════════════════════════════════════════════════════════════════════════
module "dms" {
  source  = "sourcefuse/arc-dms/aws"
  version = "0.0.5"

  prefix = local.name_prefix

  # ── Replication instance ───────────────────────────────────────────────────
  instance_id             = local.dms_instance_id
  instance_class          = var.dms_instance_class
  instance_engine_version = var.dms_engine_version
  instance_multi_az       = var.dms_multi_az
  instance_kms_key_arn    = module.kms.key_arn

  # ── Subnet group (DMS must run in the same VPC as the target DB) ───────────
  create_subnet_group     = true
  subnet_group_id         = local.dms_subnet_group_id
  subnet_group_subnet_ids = data.aws_subnets.private.ids

  instance_vpc_security_group_ids = [module.security_group.id]

  # ── Source endpoint (on-prem or existing DB) ───────────────────────────────
  endpoints = {
    source = {
      endpoint_id   = local.source_endpoint_id
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
      kms_key_arn = module.kms.key_arn
    }

    target = {
      endpoint_id   = local.target_endpoint_id
      endpoint_type = "target"
      engine_name   = var.target_db_engine == "aurora-postgresql" ? "aurora-postgresql" : "aurora"
      server_name   = module.db.cluster_endpoint
      port          = var.target_db_engine == "aurora-postgresql" ? 5432 : 3306
      database_name = local.target_db_name
      username      = var.target_db_username
      ssl_mode      = "require"
      kms_key_arn   = module.kms.key_arn
    }
  }

  # ── Replication task ────────────────────────────────────────────────────────
  # source_endpoint_arn and target_endpoint_arn are resolved by the module
  # internally from the endpoints map above — do not pass them here.
  replication_tasks = {
    migration = {
      replication_task_id    = local.replication_task_id
      migration_type         = var.migration_type
      table_mappings         = local.table_mappings
      start_replication_task = false  # start manually after validating endpoints

      # Task settings: enable logging, CloudWatch metrics, full-LOB mode
      replication_task_settings = jsonencode({
        Logging = {
          EnableLogging = true
          LogComponents = [
            { Id = "SOURCE_UNLOAD", Severity = "LOGGER_SEVERITY_DEFAULT" },
            { Id = "TARGET_LOAD",   Severity = "LOGGER_SEVERITY_DEFAULT" },
            { Id = "TASK_MANAGER",  Severity = "LOGGER_SEVERITY_DEFAULT" }
          ]
        }
        TargetMetadata = { TargetSchema = "" }
        FullLoadSettings = {
          TargetTablePrepMode = "DO_NOTHING"  # preserve existing data; change to DROP_AND_CREATE for fresh targets
        }
      })
    }
  }

  tags = local.tags
}

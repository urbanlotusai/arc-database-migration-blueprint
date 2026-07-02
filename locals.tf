locals {
  # ── Naming ────────────────────────────────────────────────────────────────────
  name_prefix          = "${var.namespace}-${var.environment}"
  kms_alias            = "alias/${local.name_prefix}-migration"
  log_bucket_name      = "${local.name_prefix}-dms-logs"
  target_db_name       = "${local.name_prefix}-target-db"
  dms_instance_id      = "${local.name_prefix}-dms"
  dms_subnet_group_id  = "${local.name_prefix}-dms-subnet"
  source_endpoint_id   = "${local.name_prefix}-source"
  target_endpoint_id   = "${local.name_prefix}-target"
  replication_task_id  = "${local.name_prefix}-migration-task"

  # ── Compliance overlay ────────────────────────────────────────────────────────
  is_hipaa           = var.compliance_profile == "hipaa"
  is_strict          = local.is_hipaa
  log_retention_days = local.is_strict ? 365 : 90

  # ── Tagging ───────────────────────────────────────────────────────────────────
  tags = {
    Environment       = var.environment
    Namespace         = var.namespace
    ManagedBy         = "terraform"
    Application       = "database-migration"
    ComplianceProfile = var.compliance_profile
  }

  # ── Table mappings — migrate all tables in all schemas ───────────────────────
  # Customize this JSON to restrict which schemas/tables DMS migrates.
  table_mappings = jsonencode({
    rules = [
      {
        rule-type   = "selection"
        rule-id     = "1"
        rule-name   = "migrate-all"
        object-locator = {
          schema-name = "%"
          table-name  = "%"
        }
        rule-action = "include"
      }
    ]
  })
}

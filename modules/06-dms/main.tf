module "dms" {
  source  = "sourcefuse/arc-dms/aws"
  version = "0.0.5"

  prefix = var.prefix

  # ── Replication instance ───────────────────────────────────────────────────
  instance_id             = var.instance_id
  instance_class          = var.instance_class
  instance_engine_version = var.instance_engine_version
  instance_multi_az       = var.instance_multi_az
  instance_kms_key_arn    = var.instance_kms_key_arn

  # ── Subnet group (DMS must run in the same VPC as the target DB) ───────────
  create_subnet_group     = true
  subnet_group_id         = var.subnet_group_id
  subnet_group_subnet_ids = var.subnet_group_subnet_ids

  instance_vpc_security_group_ids = var.instance_vpc_security_group_ids

  # ── Source / target endpoints ───────────────────────────────────────────────
  endpoints = var.endpoints

  # ── Replication task ────────────────────────────────────────────────────────
  # source_endpoint_arn and target_endpoint_arn are resolved by the module
  # internally from the endpoints map above — do not pass them here.
  replication_tasks = var.replication_tasks

  tags = var.tags
}

module "db" {
  source  = "sourcefuse/arc-db/aws"
  version = "4.0.4"

  name        = var.name
  namespace   = var.namespace
  environment = var.environment

  engine         = var.engine
  engine_type    = "cluster"
  engine_version = var.engine_version
  license_model  = "general-public-license"
  port           = var.port

  username = var.username

  vpc_id                = var.vpc_id
  db_subnet_group_data  = var.db_subnet_group_data

  storage_encrypted       = true
  kms_key_id              = var.kms_key_id
  instance_class          = var.instance_class
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection

  tags = var.tags
}

module "kms" {
  source  = "sourcefuse/arc-kms/aws"
  version = "1.0.11"

  alias                   = var.alias
  policy                  = var.policy
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  tags = var.tags
}

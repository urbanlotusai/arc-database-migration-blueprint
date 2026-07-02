module "network" {
  source  = "sourcefuse/arc-network/aws"
  version = "3.0.14"

  name        = var.name
  namespace   = var.namespace
  environment = var.environment
  cidr_block  = var.cidr_block

  tags = var.tags
}

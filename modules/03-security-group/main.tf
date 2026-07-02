module "security_group" {
  source  = "sourcefuse/arc-security-group/aws"
  version = "0.0.5"

  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules

  tags = var.tags
}

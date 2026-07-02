module "s3" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.7"

  name = var.name

  server_side_encryption_config_data = var.server_side_encryption_config_data

  public_access_config = var.public_access_config

  tags = var.tags
}

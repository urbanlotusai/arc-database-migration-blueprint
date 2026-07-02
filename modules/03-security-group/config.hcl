# =============================================================================
# 03-security-group Backend Configuration (static keys only)
# =============================================================================
# bucket, dynamodb_table, and region are supplied at `terraform init` time
# via -backend-config flags in the Makefile / apply-module.sh script.
# =============================================================================

key     = "modules/03-security-group/terraform.tfstate"
encrypt = true

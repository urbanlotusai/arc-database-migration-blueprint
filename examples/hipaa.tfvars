# ── Profile: hipaa ────────────────────────────────────────────────────────────
# Activates the HIPAA overlay:
#   - Aurora PITR extended to 35 days
#   - Aurora deletion_protection = true
#   - S3 log retention extended to 365 days

environment = "prod"
namespace   = "myorg"

compliance_profile = "hipaa"

# Source database (replace with your values)
source_db_host     = "10.0.1.50"
source_db_port     = 5432
source_db_name     = "myapp_db"
source_db_username = "migration_user"
source_db_engine   = "postgres"

# Target Aurora (replace with your values)
target_db_password = "CHANGEME-UseSecretsManagerInProd"
target_db_engine   = "aurora-postgresql"

# Migration — CDC for zero-downtime
migration_type = "full-load-and-cdc"
dms_multi_az   = true

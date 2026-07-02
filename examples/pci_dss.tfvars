# ── Profile: pci_dss ──────────────────────────────────────────────────────────
# Activates the PCI DSS overlay:
#   - Aurora PITR extended to 35 days
#   - Aurora deletion_protection = true
#   - DMS Multi-AZ replication instance
#   - Log retention 365 days

environment = "prod"
namespace   = "myorg"

compliance_profile = "pci_dss"

source_db_host     = "10.0.1.50"
source_db_port     = 5432
source_db_name     = "myapp_db"
source_db_username = "migration_user"
source_db_engine   = "postgres"

target_db_password = "CHANGEME-UseSecretsManagerInProd"
target_db_engine   = "aurora-postgresql"

migration_type = "full-load-and-cdc"
dms_multi_az   = true

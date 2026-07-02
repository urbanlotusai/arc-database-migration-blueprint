# ── Profile: general ──────────────────────────────────────────────────────────
environment        = "prod"
namespace          = "myorg"
source_db_host     = "10.0.1.50"
source_db_port     = 5432
source_db_name     = "myapp_db"
source_db_username = "migration_user"
source_db_engine   = "postgres"
target_db_password = "ChangeMe123!"

migration_type = "full-load-and-cdc"

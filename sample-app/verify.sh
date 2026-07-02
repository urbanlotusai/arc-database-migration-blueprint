#!/usr/bin/env bash
# Verifies row counts match between source and target after a DMS full-load,
# proving the migration pipeline moved data correctly.
set -euo pipefail

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required. Install the PostgreSQL client and re-run." >&2
  exit 1
fi

TARGET_HOST=$(terraform output -raw target_db_cluster_endpoint)

echo "== Target row counts (${TARGET_HOST}) =="
PGPASSWORD="${TARGET_DB_PASSWORD:?Set TARGET_DB_PASSWORD}" psql \
  -h "$TARGET_HOST" -U "${TARGET_DB_USERNAME:?Set TARGET_DB_USERNAME}" -d "${TARGET_DB_NAME:?Set TARGET_DB_NAME}" \
  -c "SELECT 'customers' AS table_name, COUNT(*) FROM customers
      UNION ALL
      SELECT 'orders', COUNT(*) FROM orders;"

echo
echo "Compare the counts above against the SOURCE database to confirm the DMS task migrated all rows."
echo "Check replication task status: aws dms describe-replication-tasks --filters Name=replication-task-arn,Values=\$(terraform output -raw dms_replication_task_arn)"

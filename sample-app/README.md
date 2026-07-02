# Sample App

A **sample schema + verification script** proving the DMS migration pipeline moves real data from source to target end-to-end.

```
schema.sql (source DB) → DMS replication task → target Aurora cluster → verify.sh
```

---

## 1. Seed the source database

Apply `schema.sql` to your **source** database (the one referenced by `source_db_host` in `terraform.tfvars`) before starting replication:

```bash
psql -h <source-db-host> -U <source-db-username> -d <source-db-name> -f sample-app/schema.sql
```

## 2. Deploy and start replication

```bash
terraform apply

# The replication task is created with start_replication_task = false.
# Start it manually after validating both endpoints:
aws dms start-replication-task \
  --replication-task-arn $(terraform output -raw dms_replication_task_arn) \
  --start-replication-task-type start-replication
```

## 3. Verify the migration

```bash
export TARGET_DB_USERNAME=<target-db-username>
export TARGET_DB_PASSWORD=<target-db-password>
export TARGET_DB_NAME=<target-db-name>
./sample-app/verify.sh
```

Confirm the `customers` and `orders` row counts on the target match the source.

## Order of operations

1. Seed the source database with `schema.sql`
2. `terraform apply` — creates KMS, VPC, target Aurora cluster, DMS replication instance + endpoints + task
3. Validate source/target endpoint connectivity in the DMS console
4. Start the replication task
5. Run `verify.sh` to confirm row counts match

---

Built by **[SourceFuse](https://www.sourcefuse.com)**.

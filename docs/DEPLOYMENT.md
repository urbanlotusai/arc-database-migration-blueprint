# Deployment Reference

## Deploy

```bash
cp examples/general.tfvars terraform.tfvars
# Edit mandatory variables
terraform init && terraform plan && terraform apply
```

## Use Secrets Manager for DB credentials (recommended)

Instead of passing `target_db_password` as a variable:

1. Store credentials in Secrets Manager:
   ```bash
   aws secretsmanager create-secret --name myorg/source-db \
     --secret-string '{"username":"migration_user","password":"secret"}'
   ```
2. In `main.tf`, reference via `secrets_manager_arn` + `secrets_manager_access_role_arn`
   on the DMS endpoint (already commented in the module block).

## Start and monitor the migration

```bash
# Test endpoints first
aws dms test-connection \
  --replication-instance-arn $(terraform output -raw dms_replication_instance_arn) \
  --endpoint-arn $(terraform output -raw dms_source_endpoint_arn)

# Start migration
aws dms start-replication-task \
  --replication-task-arn $(terraform output -raw dms_replication_task_arn) \
  --start-replication-task-type start-replication

# Monitor
aws dms describe-replication-tasks \
  --filters Name=replication-task-arn,Values=$(terraform output -raw dms_replication_task_arn)
```

## Tear down

```bash
# Stop replication task first
aws dms stop-replication-task \
  --replication-task-arn $(terraform output -raw dms_replication_task_arn)

terraform destroy
```

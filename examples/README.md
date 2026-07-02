# Examples

| File | Description |
|---|---|
| `general.tfvars` | Standard migration: full-load + CDC, single-AZ DMS |

Copy the file to `../terraform.tfvars` before running `terraform plan`.

**Important:** Replace `source_db_host`, `source_db_name`, `source_db_username`, and `target_db_password`
with your actual values. Never commit passwords — use AWS Secrets Manager in production
(see `docs/DEPLOYMENT.md`).

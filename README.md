<div align="center">

# ARC Database Migration Blueprint

### On-prem or cross-RDS database migration to Aurora — in one `terraform apply`

**A SourceFuse ARC Blueprint**

![Version](https://img.shields.io/badge/version-1.0.0-E8392A)
![License](https://img.shields.io/badge/license-Apache--2.0-1A1A2E)
![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.3-7B42BC)
![AWS Provider](https://img.shields.io/badge/aws--provider-%3E%3D5.0-FF9900)
![ARC Modules](https://img.shields.io/badge/ARC%20modules-6-E8392A)

</div>

---

## What is this?

A **ready-to-deploy Terraform blueprint** that sets up a complete AWS Database Migration Service (DMS)
pipeline by composing **6 [SourceFuse ARC](https://registry.terraform.io/namespaces/modules/sourcefuse)
modules**. One `terraform apply` gives you:

- A dedicated **VPC** and security groups for the migration network
- A **DMS Replication Instance** in private subnets
- **Source endpoint** (on-prem or existing RDS/Aurora)
- **Target Aurora** cluster (PostgreSQL or MySQL) with KMS encryption
- **S3 bucket** for task logs and validation reports
- **KMS CMK** encrypting the DMS instance, target DB, and S3

Supports full-load, CDC (change data capture), and combined `full-load-and-cdc` migrations.

---

## Why use this blueprint?

| Advantage | What it means for you |
|---|---|
| **Minutes, not days** | A secure DMS pipeline with networking, encryption, and endpoints normally takes days to wire; this deploys in one command. |
| **Secure by default** | Single KMS CMK encrypts the DMS replication instance, target Aurora cluster, and S3 log bucket. All data in transit over SSL. |
| **Three migration modes** | `full-load`, `cdc`, or `full-load-and-cdc` — switch with a variable, no rewiring required. |
| **Compliance-ready** | Built-in `general` / `hipaa` / `pci_dss` profiles activate Aurora PITR, deletion protection, and extended log retention. |
| **Start manually** | The replication task is provisioned but not auto-started — test endpoint connectivity first, then trigger with one CLI command. |
| **Portable & auditable** | Pure Terraform. Reproducible across environments. Rollback is `terraform destroy`. |

---

## Architecture

```
  Source Database
  (on-prem / existing RDS)
           │
           │  SSL/TLS
           ▼
  ┌─────────────────────────────┐
  │    Migration VPC            │
  │                             │
  │  DMS Replication Instance   │
  │  (private subnet, KMS enc.) │
  │           │                 │
  │           ▼                 │
  │  Target Aurora Cluster      │
  │  (private subnet, KMS enc.) │
  └─────────────────────────────┘
           │
           ▼
  S3 (task logs, validation reports)
  └── KMS CMK ── DMS · Aurora · S3
```

---

## The 6 ARC modules

| Module | Version | Role |
|---|---|---|
| [arc-kms](https://registry.terraform.io/modules/sourcefuse/arc-kms/aws) | 1.0.11 | Customer Managed Key — encrypts DMS, Aurora, and S3 |
| [arc-network](https://registry.terraform.io/modules/sourcefuse/arc-network/aws) | 3.0.14 | VPC + public/private subnets for migration |
| [arc-security-group](https://registry.terraform.io/modules/sourcefuse/arc-security-group/aws) | 0.0.5 | DB port access control (5432 / 3306) |
| [arc-s3](https://registry.terraform.io/modules/sourcefuse/arc-s3/aws) | 0.0.7 | Task logs and validation reports (encrypted, private) |
| [arc-db](https://registry.terraform.io/modules/sourcefuse/arc-db/aws) | 4.0.4 | Target Aurora cluster (PostgreSQL or MySQL) |
| [arc-dms](https://registry.terraform.io/modules/sourcefuse/arc-dms/aws) | 0.0.5 | DMS instance, source/target endpoints, replication task |

---

## Quick start

### 1. Prerequisites

- **Terraform** `>= 1.3` ([install guide](docs/INSTALL.md))
- **AWS credentials** configured (`aws configure`)
- **Network connectivity** from the migration VPC to the source database (VPN, Direct Connect, or VPC peering)
- **Source DB user** with replication privileges (`REPLICATION CLIENT`, `REPLICATION SLAVE` for MySQL; `rds_superuser` or `rds_replication` for PostgreSQL)

### 2. Configure

```bash
git clone https://github.com/sourcefuse/arc-database-migration-blueprint.git
cd arc-database-migration-blueprint

cp examples/general.tfvars terraform.tfvars
```

Edit the mandatory values in `terraform.tfvars`:

| Variable | Example |
|---|---|
| `environment` | `prod` |
| `namespace` | `myorg` |
| `source_db_host` | `10.0.1.50` |
| `source_db_port` | `5432` |
| `source_db_name` | `myapp_db` |
| `source_db_username` | `migration_user` |
| `source_db_engine` | `postgres` |
| `target_db_password` | `YourSecurePassword` |

### 3. Deploy

| Step | With `make` | Raw Terraform (all OS) |
|---|---|---|
| Validate | `make validate` | `terraform init -backend=false && terraform validate` |
| Preview | `make plan` | `terraform plan` |
| Deploy | `make apply` | `terraform init && terraform apply` |

### 4. Test connectivity, then start the migration

```bash
# Test source endpoint connectivity first
aws dms test-connection \
  --replication-instance-arn $(terraform output -raw dms_replication_instance_arn) \
  --endpoint-arn $(terraform output -raw dms_source_endpoint_arn)

# Start the migration task only after connectivity is confirmed
aws dms start-replication-task \
  --replication-task-arn $(terraform output -raw dms_replication_task_arn) \
  --start-replication-task-type start-replication
```

---

## Migration types

| Type | When to use |
|---|---|
| `full-load` | One-time migration with a maintenance window |
| `cdc` | Ongoing replication from an existing snapshot |
| `full-load-and-cdc` | Zero-downtime migration: copy data then stream changes |

Set `migration_type` in `terraform.tfvars` to switch modes.

---

## Compliance profiles

| Profile | Effect |
|---|---|
| `general` | KMS rotation on, 90-day S3 log retention, 7-day Aurora PITR |
| `hipaa` | Aurora PITR 35 days + deletion protection, 365-day S3 log retention |
| `pci_dss` | Aurora PITR 35 days + deletion protection, 365-day S3 log retention, Multi-AZ DMS instance |

---

## Key outputs

```bash
terraform output dms_replication_instance_arn  # DMS instance
terraform output dms_source_endpoint_arn       # source endpoint
terraform output dms_target_endpoint_arn       # target endpoint
terraform output dms_replication_task_arn      # migration task — start this after connectivity test
terraform output target_db_cluster_endpoint    # Aurora writer endpoint (for app cutover)
terraform output log_bucket_id                 # S3 logs
terraform output kms_key_arn                   # CMK
```

---

## Project structure

```
arc-database-migration-blueprint/
├── main.tf                   # 6 ARC module blocks, in dependency order
├── variables.tf              # all inputs with types & descriptions
├── locals.tf                 # naming, tags, compliance overlays
├── data.tf                   # caller identity, KMS policy, subnet lookups
├── outputs.tf                # DMS ARNs, Aurora endpoint, S3, KMS
├── version.tf                # Terraform + AWS provider pins
├── terraform.tfvars.example  # copy to terraform.tfvars
├── examples/
│   ├── README.md
│   ├── general.tfvars
│   ├── hipaa.tfvars
│   └── pci_dss.tfvars
├── docs/
│   ├── INSTALL.md            # macOS · Linux · Windows setup guide
│   └── DEPLOYMENT.md        # full deployment + cutover + rollback
├── GETTING-STARTED.md        # beginner walkthrough
├── CONTRIBUTING.md
├── CHANGELOG.md · LICENSE · NOTICE · Makefile · VERSION
└── README.md
```

---

## Documentation

- **[GETTING-STARTED.md](GETTING-STARTED.md)** — zero-to-live walkthrough for first-timers
- **[docs/INSTALL.md](docs/INSTALL.md)** — install Terraform & AWS CLI on macOS / Linux / Windows
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** — full deployment guide, connectivity testing, cutover checklist
- **[examples/README.md](examples/README.md)** — compliance-profile example files

---

## Important notes

- **The replication task does NOT auto-start.** `start_replication_task = false` is intentional — always test endpoint connectivity first before starting.
- **Full-load-and-cdc requires binary logging** on the source: `binlog_format = ROW` for MySQL, `wal_level = logical` for PostgreSQL.
- **Two-apply KMS pattern** — if you pre-create the KMS key on the first apply (`terraform apply -target=module.kms`), subsequent applies can reference the key ARN in DMS and Aurora. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).
- **App cutover** — for zero-downtime: run in `full-load-and-cdc` until lag is near zero, then flip your app connection string to `target_db_cluster_endpoint`, then stop the task.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE).

---

<div align="center">

### Built by [SourceFuse](https://www.sourcefuse.com)

Part of the **ARC** (Accelerated Reference Cloud) blueprint family.
Explore all ARC modules on the [Terraform Registry](https://registry.terraform.io/namespaces/modules/sourcefuse).

</div>

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
modules**. Deploying `bootstrap/` then every module in `modules/` gives you:

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
| **Minutes, not days** | A secure DMS pipeline with networking, encryption, and endpoints normally takes days to wire; this deploys with a handful of commands. |
| **Secure by default** | Single KMS CMK encrypts the DMS replication instance, target Aurora cluster, and S3 log bucket. All data in transit over SSL. |
| **Three migration modes** | `full-load`, `cdc`, or `full-load-and-cdc` — switch with a variable, no rewiring required. |
| **Compliance-ready** | Built-in `general` / `hipaa` / `pci` profiles activate Aurora extended backup retention, deletion protection, and extended log retention — no manual edits. |
| **Start manually** | The replication task is provisioned but not auto-started — test endpoint connectivity first, then trigger with one CLI command. |
| **Portable & auditable** | Pure Terraform. Independent per-module state, reproducible across environments. Rollback is a per-module `terraform destroy`. |

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

### 2. Clone

```bash
git clone https://github.com/urbanlotusai/arc-database-migration-blueprint.git
cd arc-database-migration-blueprint
```

This blueprint uses **independent per-module Terraform state** — there is no root `main.tf`. Each `modules/NN-name/` is applied on its own, with cross-module values (like the KMS key ARN, VPC ID, and target Aurora endpoint) resolved via `terraform_remote_state` data sources rather than a parent module.

### 3. Bootstrap the state backend (once per environment)

```bash
make bootstrap ENV=dev REGION=us-east-1 NAMESPACE=myorg
```

Creates the S3 state bucket + DynamoDB lock table every module's backend uses.

### 4. Deploy all modules

```bash
make apply ENV=dev REGION=us-east-1 NAMESPACE=myorg
```

This runs `terraform init` + `apply` across `modules/01-kms` through `modules/06-dms` in order. Source database connection details (`source_db_host`, `source_db_port`, `source_db_name`, `source_db_username`, `source_db_engine` — no defaults) must be supplied — either edit `modules/06-dms/tfvars/general.tfvars` or pass `-var` overrides.

### Deploy a single module with a compliance profile

```bash
./scripts/apply-module.sh 06-dms dev us-east-1 hipaa
```

Copies `modules/06-dms/tfvars/hipaa.tfvars` → `terraform.tfvars` for that module, then inits/plans/applies it alone.

| Step | With `make` (all modules) | Single module |
|---|---|---|
| Validate | `make validate` | `cd modules/<NN-name> && terraform validate` |
| Preview | `make plan` | `./scripts/apply-module.sh <name> <env> <region> <profile>` then inspect the plan |
| Deploy | `make apply` | `./scripts/apply-module.sh <name> <env> <region> <profile>` |

### 5. Test connectivity, then start the migration

```bash
# Test source endpoint connectivity first
aws dms test-connection \
  --replication-instance-arn $(terraform -chdir=modules/06-dms output -raw replication_instance_arn) \
  --endpoint-arn $(terraform -chdir=modules/06-dms output -raw source_endpoint_arn)

# Start the migration task only after connectivity is confirmed
aws dms start-replication-task \
  --replication-task-arn $(terraform -chdir=modules/06-dms output -raw replication_task_arn) \
  --start-replication-task-type start-replication
```

---

## Migration types

| Type | When to use |
|---|---|
| `full-load` | One-time migration with a maintenance window |
| `cdc` | Ongoing replication from an existing snapshot |
| `full-load-and-cdc` | Zero-downtime migration: copy data then stream changes |

Set `migration_type` in `modules/06-dms/tfvars/*.tfvars` (or via `-var`) to switch modes.

---

## Compliance profiles

| Profile | Effect |
|---|---|
| `general` | KMS rotation on, 7-day Aurora backup retention, no deletion protection |
| `hipaa` | Aurora backup retention extended to 35 days + deletion protection |
| `pci` | Aurora backup retention extended to 35 days + deletion protection |

Apply a profile to any module with `./scripts/apply-module.sh <module> <env> <region> <profile>`.

---

## Key outputs

```bash
terraform -chdir=modules/06-dms output replication_instance_arn  # DMS instance
terraform -chdir=modules/06-dms output source_endpoint_arn       # source endpoint
terraform -chdir=modules/06-dms output target_endpoint_arn       # target endpoint
terraform -chdir=modules/06-dms output replication_task_arn      # migration task — start this after connectivity test
terraform -chdir=modules/05-db  output cluster_endpoint          # Aurora writer endpoint (for app cutover)
terraform -chdir=modules/04-s3  output bucket_id                 # S3 logs
terraform -chdir=modules/01-kms output key_arn                   # CMK
```

---

## Project structure

```
arc-database-migration-blueprint/
├── bootstrap/                 # creates the S3 + DynamoDB state backend (apply first)
│   ├── main.tf · variables.tf · outputs.tf
├── modules/                   # each folder is an independent Terraform root
│   ├── 01-kms/
│   │   ├── config.hcl         # static backend key
│   │   ├── main.tf            # own backend "s3" {}, own provider, own module block
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── tfvars/{general,hipaa,pci}.tfvars
│   ├── 02-network/
│   ├── 03-security-group/
│   ├── 04-s3/
│   ├── 05-db/
│   └── 06-dms/
├── scripts/
│   └── apply-module.sh        # apply one module with a chosen compliance profile
├── Makefile                   # bootstrap / init / plan / apply / validate / fmt
├── .terraform-version         # tfenv pin (1.9.8)
├── sample-app/                # SQL schema + verification script proving migration works
├── docs/
│   ├── INSTALL.md             # macOS · Linux · Windows setup guide
│   └── DEPLOYMENT.md          # full deployment guide, connectivity testing, cutover checklist
├── GETTING-STARTED.md         # beginner walkthrough
├── CONTRIBUTING.md
├── CHANGELOG.md · LICENSE · NOTICE · VERSION
└── README.md
```

---

## Documentation

- **[GETTING-STARTED.md](GETTING-STARTED.md)** — zero-to-live walkthrough for first-timers
- **[docs/INSTALL.md](docs/INSTALL.md)** — install Terraform & AWS CLI on macOS / Linux / Windows
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** — full deployment guide, connectivity testing, cutover checklist
- **`modules/*/tfvars/{general,hipaa,pci}.tfvars`** — per-module compliance-profile example files

---

## Important notes

- **The replication task does NOT auto-start.** `start_replication_task = false` is intentional — always test endpoint connectivity first before starting.
- **Full-load-and-cdc requires binary logging** on the source: `binlog_format = ROW` for MySQL, `wal_level = logical` for PostgreSQL.
- **Two-apply KMS pattern** — the KMS key is created by `01-kms` before any module that references its ARN (`04-s3`, `05-db`, `06-dms`) is applied, since each module is applied in order and reads it via `terraform_remote_state`. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).
- **App cutover** — for zero-downtime: run in `full-load-and-cdc` until lag is near zero, then flip your app connection string to the `05-db` module's `cluster_endpoint` output, then stop the task.

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

output "kms_key_arn" {
  description = "ARN of the KMS CMK used by S3, DMS, and the target Aurora cluster."
  value       = module.kms.key_arn
}

output "vpc_id" {
  description = "ID of the migration VPC."
  value       = module.network.vpc_id
}

output "target_db_cluster_endpoint" {
  description = "Writer endpoint of the target Aurora cluster."
  value       = module.db.cluster_endpoint
}

output "target_db_reader_endpoint" {
  description = "Reader endpoint of the target Aurora cluster."
  value       = module.db.cluster_reader_endpoint
}

output "target_db_cluster_arn" {
  description = "ARN of the target Aurora cluster."
  value       = module.db.cluster_arn
}

output "dms_replication_instance_arn" {
  description = "ARN of the DMS replication instance."
  value       = module.dms.replication_instance_arn
}

output "dms_source_endpoint_arn" {
  description = "ARN of the DMS source endpoint."
  value       = module.dms.endpoints["source"].endpoint_arn
}

output "dms_target_endpoint_arn" {
  description = "ARN of the DMS target endpoint."
  value       = module.dms.endpoints["target"].endpoint_arn
}

output "dms_replication_task_arn" {
  description = "ARN of the DMS replication task."
  value       = module.dms.replication_tasks["migration"].replication_task_arn
}

output "log_bucket_id" {
  description = "S3 bucket name for DMS task logs and validation reports."
  value       = module.s3.bucket_id
}

output "security_group_id" {
  description = "ID of the migration security group."
  value       = module.security_group.id
}

output "replication_instance_arn" {
  description = "ARN of the DMS replication instance."
  value       = module.dms.replication_instance_arn
}

output "source_endpoint_arn" {
  description = "ARN of the DMS source endpoint."
  value       = module.dms.endpoints["source"].endpoint_arn
}

output "target_endpoint_arn" {
  description = "ARN of the DMS target endpoint."
  value       = module.dms.endpoints["target"].endpoint_arn
}

output "replication_task_arn" {
  description = "ARN of the DMS replication task."
  value       = module.dms.replication_tasks["migration"].replication_task_arn
}

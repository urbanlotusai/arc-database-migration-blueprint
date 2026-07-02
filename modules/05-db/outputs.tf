output "cluster_endpoint" {
  description = "Writer endpoint of the target Aurora cluster."
  value       = module.db.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint of the target Aurora cluster."
  value       = module.db.cluster_reader_endpoint
}

output "cluster_arn" {
  description = "ARN of the target Aurora cluster."
  value       = module.db.cluster_arn
}

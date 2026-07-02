output "state_bucket_name" {
  description = "S3 bucket name for Terraform state storage"
  value       = module.bootstrap.bucket_name
}

output "state_bucket_arn" {
  description = "S3 bucket ARN for Terraform state storage"
  value       = module.bootstrap.bucket_arn
}

output "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  value       = module.bootstrap.dynamodb_name
}

output "lock_table_arn" {
  description = "DynamoDB table ARN for Terraform state locking"
  value       = module.bootstrap.dynamodb_arn
}

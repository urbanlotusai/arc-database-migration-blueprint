output "bucket_id" {
  description = "S3 bucket name for DMS task logs and validation reports."
  value       = module.s3.bucket_id
}

output "bucket_arn" {
  description = "S3 bucket ARN for DMS task logs and validation reports."
  value       = module.s3.bucket_arn
}
